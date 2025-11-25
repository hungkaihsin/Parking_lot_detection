import Foundation

struct HealthStatus: Codable {
    let db: String
    let model: String
}

struct StallFeatures: Codable {
    let isEV: Bool
    let isADA: Bool
    let size: String?
    let connectors: String?
    let widthClass: Int?
    let distToEntrance: Double?

    enum CodingKeys: String, CodingKey {
        case isEV = "is_ev"
        case isADA = "is_ada"
        case size
        case connectors
        case widthClass = "width_class"
        case distToEntrance = "dist_to_entrance"
    }
}

struct Stall: Codable, Identifiable {
    let id: String
    let features: StallFeatures
    let coordinates: [[Double]]
}

struct StallStatus: Codable, Identifiable {
    let id: String
    let status: String // e.g., "occupied" or "empty"
}

struct Recommendation: Codable, Identifiable {
    let id: String { stallId } // Conform to Identifiable
    let stallId: String
    let lotId: String
    let score: Double
    let reasons: [String]
    let features: StallFeatures
    let badges: [String]

    enum CodingKeys: String, CodingKey {
        case stallId = "stall_id"
        case lotId = "lot_id"
        case score
        case reasons
        case features
        case badges
    }
}

struct StructuredRequest: Codable {
    let isADA: Bool?
    let isEV: Bool?
    let connector: String?
    let size: String?
    let near: Bool?
    let buffered: Bool?

    enum CodingKeys: String, CodingKey {
        case isADA = "is_ada"
        case isEV = "is_ev"
        case connector
        case size
        case near
        case buffered
    }
}

struct NLPRequest: Codable {
    let lotName: String
    let query: String

    enum CodingKeys: String, CodingKey {
        case lotName = "lot_name"
        case query
    }
}
    
// MARK: - GeoJSON Helper Structs for local parsing

struct FeatureCollection: Decodable {
    let features: [Feature]
}

struct Feature: Decodable {
    let geometry: Geometry
    let properties: StallProperties
}

struct Geometry: Decodable {
    let type: String
    let coordinates: [[[Double]]] // GeoJSON can be complex, this assumes Polygon
}

struct StallProperties: Decodable {
    let id: String
    let isEV: Bool?
    let isADA: Bool?
    let size: String?

    enum CodingKeys: String, CodingKey {
        case id
        case isEV = "is_ev"
        case isADA = "is_ada"
        case size
    }
}

// Custom Codable for handling mixed types or nulls if necessary,
// though not strictly used by the current GeoJSON structure for stall features.
// Keeping it as it was in the original prompt for Week 1, Task 2 (Daniel)
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
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
        } else if container.decodeNil() {
            value = ()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any?] {
            try container.encode(array.map(AnyCodable.init))
        } else if let dictionary = value as? [String: Any?] {
            try container.encode(dictionary.mapValues(AnyCodable.init))
        } else if value is Void {
            try container.encodeNil()
        } else {
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
