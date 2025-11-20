import SwiftUI
import Combine

struct ParkingLotView: View {
    let lotName: String
    @State private var stalls: [Stall] = []
    @State private var imageSize: CGSize = .zero
    @State private var stallStatuses: [StallStatus] = []
    
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    private let originalImageSizes: [String: CGSize] = [
        "lot_a": CGSize(width: 234, height: 433),
        "lot_b": CGSize(width: 273, height: 175),
        "lot_c": CGSize(width: 305, height: 307),
        "lot_d": CGSize(width: 619, height: 1100),
        "lot_e": CGSize(width: 670, height: 730)
    ]

    var body: some View {
        ZStack {
            Image(lotName)
                .resizable()
                .aspectRatio(contentMode: .fit)
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
                stallStatuses: stallStatuses
            )
        }
        .navigationTitle(lotName.replacingOccurrences(of: "_", with: " ").capitalized)
        .onAppear {
            Task {
                do {
                    self.stalls = try await loadLotData(from: "\(lotName)_data.geojson")
                    await fetchLiveStatus()
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

        var body: some View {
            ForEach(stalls) { stall in
                stallPath(for: stall)
                    .fill(colorFor(stall: stall).opacity(0.5))
                    .overlay(
                        stallPath(for: stall)
                            .stroke(Color.gray, lineWidth: 1.0)
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

        private func stallPath(for stall: Stall) -> Path {
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

            let points: [CGPoint] = stall.coordinates.map {
                let newX = ($0[0] * scale) + offsetX
                let newY = ($0[1] * scale) + offsetY
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
        var processedIDs = Set<String>() // Keep track of processed IDs

        for feature in geoJSON.features {
            guard let properties = feature.properties?.value as? [String: Any],
                  let id = properties["id"] as? String,
                  id != "ENTRANCE",
                  !processedIDs.contains(id) else { // Check for duplicates
                continue
            }

            if case .polygon(let coordinates) = feature.geometry.coordinates {
                processedIDs.insert(id) // Add new ID to the set
                let stallFeatures = StallFeatures(isEV: (properties["is_ev"] as? Bool) ?? false,
                                                  isADA: (properties["is_ada"] as? Bool) ?? false,
                                                  size: (properties["width_class"] as? Int).map { String($0) } ?? "unknown")
                
                let stall = Stall(id: id, features: stallFeatures, coordinates: coordinates[0])
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