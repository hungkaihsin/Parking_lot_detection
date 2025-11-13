import Foundation

// 1. HealthStatus
struct HealthStatus: Codable {
    let db: String
    let model: String
}

// 2. StallFeatures
struct StallFeatures: Codable {
    let isEV: Bool
    let isADA: Bool
    let size: String
}

// 3. Stall
struct Stall: Codable, Identifiable {
    let id: String
    let features: StallFeatures
    let coordinates: [[Double]]
}

// 4. StallStatus
struct StallStatus: Codable, Identifiable {
    let id: String
    let status: String // e.g., "FREE" or "TAKEN"
}

// 5. Recommendation
struct Recommendation: Codable, Identifiable {
    let id: String
    let rank: Int
    let reason: String
}

// 6. StructuredRequest
struct StructuredRequest: Codable {
    let vehicleType: String
    let wantsEV: Bool
}

// 7. NLPRequest
struct NLPRequest: Codable {
    let query: String
}
