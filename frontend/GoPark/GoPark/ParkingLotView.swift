import SwiftUI

struct ParkingLotView: View {
    let lotName: String
    @State private var stalls: [Stall] = []
    @State private var imageSize: CGSize = .zero
    
    // You MUST get the real image sizes for this to work.
    // Use Finder -> Get Info on your image files to find their "Dimensions".
    private let originalImageSizes: [String: CGSize] = [
        "lot_a": CGSize(width: 234, height: 433),
        "lot_b": CGSize(width: 273, height: 175),
        "lot_c": CGSize(width: 305, height: 307),
        "lot_d": CGSize(width: 619, height: 1100),
        "lot_e": CGSize(width: 670, height: 730)
    ]

    var body: some View {
        ZStack {
            // This loads the image from Assets (e.g., "lot_a")
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
                originalImageSize: originalImageSizes[lotName] ?? .zero
            )
        }
        .navigationTitle(lotName)
        .onAppear {
            Task {
                do {
                    // This now loads all stalls for the lot
                    self.stalls = try await loadLotData(from: "\(lotName)_data.geojson")
                } catch {
                    print("Error loading lot data: \(error)")
                }
            }
        }
    }

    private struct StallsOverlayView: View {
        let stalls: [Stall]
        let imageSize: CGSize
        let originalImageSize: CGSize

        var body: some View {
            ForEach(stalls) { stall in
                
                // --- YOUR TEST IS HERE ---
                // We check if the current stall is your test stall
                let isTestStall = stall.id == "d22d8146-5d35-45d1-aed2-68dc38630612"
                
                // Use a red color for the test stall, and gray for all others
                let fillColor = isTestStall ? Color.red.opacity(0.5) : Color.gray.opacity(0.4)
                let strokeColor = isTestStall ? Color.red : Color.gray
                let lineWidth: CGFloat = isTestStall ? 2.0 : 1.0
                // --- END OF TEST ---
                
                stallPath(for: stall)
                    .fill(fillColor)
                    .overlay(
                        stallPath(for: stall)
                            .stroke(strokeColor, lineWidth: lineWidth)
                    )
            }
        }

        private func stallPath(for stall: Stall) -> Path {
                var path = Path()
                
                // This guard is correct
                guard originalImageSize != .zero, imageSize != .zero else {
                    return path
                }

                // --- THIS IS THE NEW, CORRECT SCALING LOGIC ---
                
                // 1. Calculate the aspect ratios
                let imageAspectRatio = originalImageSize.width / originalImageSize.height
                let viewAspectRatio = imageSize.width / imageSize.height
                
                var scale: CGFloat = 1.0
                var offsetX: CGFloat = 0.0
                var offsetY: CGFloat = 0.0

                // 2. Determine the correct scale factor and offsets
                //    based on whether the image is "letterboxed" (space top/bottom)
                //    or "pillarboxed" (space left/right).
                if imageAspectRatio > viewAspectRatio {
                    // Image is wider than the view (letterboxed)
                    scale = imageSize.width / originalImageSize.width
                    let scaledHeight = originalImageSize.height * scale
                    offsetY = (imageSize.height - scaledHeight) / 2.0 // Centering offset
                } else {
                    // Image is taller than the view (pillarboxed) - THIS IS YOUR CASE for lot_a
                    scale = imageSize.height / originalImageSize.height
                    let scaledWidth = originalImageSize.width * scale
                    offsetX = (imageSize.width - scaledWidth) / 2.0 // Centering offset
                }

                // 3. Apply the single scale factor and offset to each point
                let points: [CGPoint] = stall.coordinates.map {
                    let newX = ($0[0] * scale) + offsetX
                    let newY = ($0[1] * scale) + offsetY
                    return CGPoint(x: newX, y: newY)
                }
                // --- END OF NEW LOGIC ---

                guard let first = points.first else { return path }
                path.move(to: first)
                for p in points.dropFirst() { path.addLine(to: p) }
                path.closeSubpath()
                return path
            }
    }

    // Helper function to load GeoJSON
    private func loadLotData(from filename: String) async throws -> [Stall] {
        guard let url = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".geojson", with: ""), withExtension: "geojson") else {
            throw NSError(domain: "ParkingLotView", code: 1, userInfo: [NSLocalizedDescriptionKey: "GeoJSON file not found: \(filename)"])
        }

        let data = try Data(contentsOf: url)
        let geoJSON = try JSONDecoder().decode(FeatureCollection.self, from: data)

        var loadedStalls: [Stall] = []

        for feature in geoJSON.features {
            if let properties = feature.properties?.value as? [String: Any],
               let id = properties["id"] as? String {
                
                // --- TEST REMOVED ---
                // The guard statement was removed.
                // We will now load ALL stalls.
                // --- END OF TEST ---

                let coordinates = feature.geometry.coordinates
                
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

struct FeatureCollection: Decodable {
    let type: String
    let features: [Feature]
}

struct Feature: Decodable {
    let type: String
    let geometry: Geometry
    let properties: AnyCodable?
}

// This struct is correct
struct Geometry: Decodable {
    let type: String
    let coordinates: [[[Double]]]
}

// This struct is correct (handles null)
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
