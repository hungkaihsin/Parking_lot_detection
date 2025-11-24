import Foundation

// MARK: - Foundational Structs

struct HealthStatus: Codable {
    let db: String
    let model: String
}

// Used for local GeoJSON decoding
struct LocalStallFeatures: Codable {
    let isEV: Bool
    let isADA: Bool
    let size: String?
}

// Used for local GeoJSON decoding
struct Stall: Codable, Identifiable {
    let id: String
    let features: LocalStallFeatures
    let coordinates: [[Double]]
}

// Used for the live status feature (which is currently reverted)
struct StallStatus: Codable, Identifiable {
    let id: String
    let status: String
}


// MARK: - Recommendation API Models

/// Matches the `features` object inside a returned recommendation from the API.
struct ApiStallFeatures: Codable {
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
    let features: ApiStallFeatures
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
