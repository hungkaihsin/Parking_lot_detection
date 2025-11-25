import SwiftUI
import Combine

struct ParkingLotView: View {
    let lotName: String
    @State private var stalls: [Stall] = []
    @State private var imageSize: CGSize = .zero
    @State private var stallStatuses: [StallStatus] = []
    
    @StateObject private var recVM = RecommendationViewModel()
    @State private var showChat = false
    
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    private let originalImageSizes: [String: CGSize] = [
        "lot_a": CGSize(width: 96, height: 180), // REAL SIZE
        "lot_b": CGSize(width: 273, height: 175), // REAL SIZE
        "lot_c": CGSize(width: 305, height: 307), // REAL SIZE
        "lot_d": CGSize(width: 619, height: 1100), // REAL SIZE
        "lot_e": CGSize(width: 670, height: 730)  // REAL SIZE
    ]

    var body: some View {
        ZStack {
            Color.white
                .aspectRatio(originalImageSizes[lotName]!.width / originalImageSizes[lotName]!.height, contentMode: .fit)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                self.imageSize = geometry.size
                            }
                    }
                )
            
            StallsOverlayView(
                stalls: stalls,
                imageSize: imageSize,
                originalImageSize: originalImageSizes[lotName] ?? .zero,
                stallStatuses: stallStatuses,
                lotName: lotName, // Pass lotName for the hack fix
                recommendedStallID: recVM.recommendedStallID
            )
            
            if recVM.isLoading {
                ProgressView("Finding spot...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle(lotName.replacingOccurrences(of: "_", with: " ").capitalized)
        .navigationBarItems(trailing: Button(action: {
            showChat = true
        }) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
        })
        .sheet(isPresented: $showChat) {
            AIChatView(lotName: lotName, recommendedStallID: $recVM.recommendedStallID)
        }
        .alert(item: $recVM.errorMessage) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            Task {
                do {
                    self.stalls = try await loadLotData(from: "\(lotName)_data.geojson")
                    await fetchLiveStatus()
                    print("--- DEBUG: Loaded \(self.stalls.count) stalls for \(lotName) ---")
                } catch {
                    print("Error loading lot data: \(error)")
                }
            }
        }
        .onReceive(timer) { _ in
            Task {
                await fetchLiveStatus()
            }
        }
    }
    
    private func fetchLiveStatus() async {
        do {
            // Assuming your NetworkManager is set up correctly. If not, this might fail silently.
             self.stallStatuses = try await NetworkManager.shared.getLiveStallStatus(lotName: self.lotName)
        } catch {
            print("Error fetching live stall status for \(lotName): \(error)")
        }
    }

    private struct StallsOverlayView: View {
        let stalls: [Stall]
        let imageSize: CGSize
        let originalImageSize: CGSize
        let stallStatuses: [StallStatus]
        let lotName: String // Add this to know when to apply the hack
        let recommendedStallID: String?

        var body: some View {
            ForEach(stalls) { stall in
                let isRecommended = stall.id == recommendedStallID
                let strokeColor = isRecommended ? Color.yellow : Color.gray
                let lineWidth = isRecommended ? 5.0 : 1.0

                stallPath(for: stall, lotName: self.lotName)
                    .fill(colorFor(stall: stall).opacity(0.5))
                    .overlay(
                        stallPath(for: stall, lotName: self.lotName)
                            .stroke(strokeColor, lineWidth: lineWidth)
                    )
            }
        }
        
        private func colorFor(stall: Stall) -> Color {
            if let status = stallStatuses.first(where: { $0.id == stall.id }) {
                switch status.status {
                case "occupied":
                    return .red
                case "empty":
                    return .green
                default:
                    return .green
                }
            }
            return .green
        }

        private func stallPath(for stall: Stall, lotName: String) -> Path {
            var path = Path()
            guard originalImageSize != .zero, imageSize != .zero else { return path }

            let imageAspectRatio = originalImageSize.width / originalImageSize.height
            let viewAspectRatio = imageSize.width / imageSize.height
            
            var scale: CGFloat = 1.0
            var offsetX: CGFloat = 0.0
            var offsetY: CGFloat = 0.0

            if imageAspectRatio > viewAspectRatio {
                scale = imageSize.width / originalImageSize.width
                let scaledHeight = originalImageSize.height * scale
                offsetY = (imageSize.height - scaledHeight) / 2.0
            } else {
                scale = imageSize.height / originalImageSize.height
                let scaledWidth = originalImageSize.width * scale
                offsetX = (imageSize.width - scaledWidth) / 2.0
            }
            
            // --- MANUAL SCALE FIX FOR LOT A ---
            var dataScale: CGFloat = 1.0
            
            if lotName == "lot_a" {
                // The JSON coordinates are roughly 2x larger than the image pixels.
                // We shrink them by 50% to fit.
                dataScale = 0.15
            }
            // --- END FIX ---

            let points: [CGPoint] = stall.coordinates.map {
                // Apply dataScale to the coordinates BEFORE scaling to the screen
                let newX = ($0[0] * dataScale * scale) + offsetX
                let newY = ($0[1] * dataScale * scale) + offsetY
                return CGPoint(x: newX, y: newY)
            }

            guard let first = points.first else { return path }
            path.move(to: first)
            for p in points.dropFirst() { path.addLine(to: p) }
            path.closeSubpath()
            return path
        }
    }

    private func loadLotData(from filename: String) async throws -> [Stall] {
        guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".geojson", with: ""), withExtension: "geojson") else {
            throw NSError(domain: "ParkingLotView", code: 1, userInfo: [NSLocalizedDescriptionKey: "GeoJSON file not found: \(filename)"])
        }

        let data = try Data(contentsOf: url)
        let geoJSON = try JSONDecoder().decode(FeatureCollection.self, from: data)

        var loadedStalls: [Stall] = []
        var processedIDs = Set<String>()

        for feature in geoJSON.features {
            guard let properties = feature.properties?.value as? [String: Any],
                  let id = properties["id"] as? String,
                  id != "ENTRANCE",
                  !processedIDs.contains(id) else {
                continue
            }

            // Correctly unpack your enum
            if case .polygon(let coordinateArray) = feature.geometry.coordinates {
                processedIDs.insert(id)
                let stallFeatures = StallFeatures(isEV: (properties["is_ev"] as? Bool) ?? false,
                                                  isADA: (properties["is_ada"] as? Bool) ?? false,
                                                  size: (properties["size"] as? String),
                                                  connectors: nil,
                                                  widthClass: nil,
                                                  distToEntrance: nil)
                
                // coordinateArray is [[[Double]]], so we take the first polygon [0]
                let stall = Stall(id: id, features: stallFeatures, coordinates: coordinateArray[0])
                loadedStalls.append(stall)
            }
        }
        return loadedStalls
    }
}

// MARK: - Helper Structs for GeoJSON Decoding

enum GeometryCoordinates: Decodable {
    case point([Double])
    case polygon([[[Double]]])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let point = try? container.decode([Double].self) {
            self = .point(point)
            return
        }
        if let polygon = try? container.decode([[[Double]]].self) {
            self = .polygon(polygon)
            return
        }
        throw DecodingError.typeMismatch(GeometryCoordinates.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported geometry type"))
    }
}

struct FeatureCollection: Decodable {
    let type: String
    let features: [Feature]
}

struct Feature: Decodable {
    let type: String
    let geometry: Geometry
    let properties: AnyCodable?
}

struct Geometry: Decodable {
    let type: String
    let coordinates: GeometryCoordinates
}

struct AnyCodable: Codable {
    var value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
            return
        }
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type found in JSON properties"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if value is NSNull {
            try container.encodeNil()
            return
        }
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map(AnyCodable.init))
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues(AnyCodable.init))
        } else {
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

struct ParkingLotView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ParkingLotView(lotName: "lot_a")
        }
    }
}
