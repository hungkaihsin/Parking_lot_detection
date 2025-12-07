import Foundation

struct HealthStatus: Codable {
    let db: String
    let model: String
}

// NOTE: This StallFeatures struct is simplified and intended for use with local GeoJSON file decoding.
struct StallFeatures: Codable {
    let isEV: Bool
    let isADA: Bool
    let size: String?
}

struct Stall: Codable, Identifiable {
    let id: String
    let features: StallFeatures
    let coordinates: [[Double]]
    var isOccupied: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, features, coordinates
        case isOccupied = "is_occupied"
    }
    
    init(id: String, features: StallFeatures, coordinates: [[Double]], isOccupied: Bool = false) {
        self.id = id
        self.features = features
        self.coordinates = coordinates
        self.isOccupied = isOccupied
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        features = try container.decode(StallFeatures.self, forKey: .features)
        coordinates = try container.decode([[Double]].self, forKey: .coordinates)
        isOccupied = try container.decodeIfPresent(Bool.self, forKey: .isOccupied) ?? false
    }
}

struct StallStatus: Codable, Identifiable {
    let id: String
    let status: String
}

// MARK: - Recommendation API Models

/// Matches the `features` object inside a returned recommendation from the API.
struct RecommendationFeatures: Codable {
    let isEV: Bool
    let isADA: Bool
    let connectors: String?
    let widthClass: Int
    let distToEntrance: Double
    let size: String?

    enum CodingKeys: String, CodingKey {
        case isEV = "is_ev"
        case isADA = "is_ada"
        case connectors
        case widthClass = "width_class"
        case distToEntrance = "dist_to_entrance"
        case size
    }
}

/// Matches a single recommendation object in the `recommendations` array from the API.
struct Recommendation: Codable, Identifiable {
    var id: String { stallId } // Conform to Identifiable
    let stallId: String
    let lotId: String
    let score: Double
    let reasons: [String]
    let features: RecommendationFeatures
    let badges: [String]

    enum CodingKeys: String, CodingKey {
        case stallId = "stall_id"
        case lotId = "lot_id"
        case score, reasons, features, badges
    }
}

/// Wraps the entire JSON response from the /recommend endpoint.
struct RecommendationResponse: Codable {
    let recommendations: [Recommendation]
}

/// Used to create the JSON body for a POST request to the /recommend endpoint.
struct RecommendationRequest: Codable {
    let query: String?
    let isAda: Bool?
    let isEv: Bool?
    let connector: String?
    let sizeClass: Int?
    let near: Bool?
    let buffered: Bool?

    enum CodingKeys: String, CodingKey {
        case query
        case isAda = "is_ada"
        case isEv = "is_ev"
        case connector
        case sizeClass = "size_class"
        case near, buffered
    }
}

struct APIStall: Codable {
    let id: String
    let isOccupied: Bool
    let x: Double?
    let y: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isOccupied = "is_occupied"
        case x, y
    }
}

struct Arrival: Codable {
    let stallId: String
    let size: String
    let x: Double?
    let y: Double?
    
    enum CodingKeys: String, CodingKey {
        case stallId = "stall_id"
        case size, x, y
    }
}

struct PredictionResponse: Codable {
    let occupiedCount: Int
    let arrivals: [Arrival]
    let currentDetections: [Arrival]? // Use Arrival struct since it has the same shape
    
    enum CodingKeys: String, CodingKey {
        case occupiedCount = "occupied_stalls_count"
        case arrivals
        case currentDetections = "current_detections"
    }
}
