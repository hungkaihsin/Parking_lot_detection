import Foundation

struct HealthStatus: Codable {
    let db: String
    let model: String
}

struct StallFeatures: Codable {
    let isEV: Bool
    let isADA: Bool
    let size: String
}

struct Stall: Codable, Identifiable {
    let id: String
    let features: StallFeatures
    let coordinates: [[Double]]
}

struct StallStatus: Codable, Identifiable {
    let id: String
    let status: String
}

struct Recommendation: Codable, Identifiable {
    let id: String
    let rank: Int
    let reason: String
}

struct StructuredRequest: Codable {
    let vehicleType: String
    let wantsEV: Bool
}

struct NLPRequest: Codable {
    let query: String
}