import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!

    private init() {}

    // DTO to decode the raw API response for a stall
    private struct StallDataDTO: Codable {
        let id: String // This will be the composite ID, e.g., "LotA-..."
        let isOccupied: Bool

        enum CodingKeys: String, CodingKey {
            case id
            case isOccupied = "is_occupied"
        }
    }
    
    private func apiLotId(from internalName: String) -> String {
        // Converts "lot_a" to "LotA"
        if let range = internalName.range(of: "lot_") {
            let letter = internalName[range.upperBound...].uppercased()
            return "Lot\(letter)"
        }
        return internalName // Fallback
    }

    func getHealthz() async throws -> HealthStatus {
        let url = baseURL.appendingPathComponent("healthz")
        let (data, _) = try await URLSession.shared.data(from: url)
        let healthStatus = try JSONDecoder().decode(HealthStatus.self, from: data)
        return healthStatus
    }

    func getLiveStallStatus(lotName: String) async throws -> [StallStatus] {
        let lotId = apiLotId(from: lotName)
        let url = baseURL.appendingPathComponent("lots/\(lotId)/spots")
        print("Requesting URL: \(url)") // DEBUG
        
        let (data, _) = try await URLSession.shared.data(from: url)

        let stallDTOs = try JSONDecoder().decode([StallDataDTO].self, from: data)

        // Map from the DTO to the StallStatus model used by the view.
        // This is where we fix the ID mismatch.
        let stallStatuses = stallDTOs.compactMap { dto -> StallStatus? in
            // The API gives a composite ID "LotA-uuid-goes-here". We need to extract the "uuid-goes-here" part.
            // A UUID contains hyphens, so we must rejoin the parts after splitting.
            let idParts = dto.id.split(separator: "-")
            guard idParts.count > 1 else { return nil }
            let originalId = idParts.dropFirst().joined(separator: "-")
            
            let statusString = dto.isOccupied ? "occupied" : "empty"
            return StallStatus(id: originalId, status: statusString)
        }

        return stallStatuses
    }

    func getStructuredRecommendation(lotName: String, vehicleType: String, wantsEV: Bool) async throws -> [Recommendation] {
        let lotId = apiLotId(from: lotName)
        let url = baseURL.appendingPathComponent("recommend")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let structuredRequest = StructuredRequest(isADA: nil, isEV: wantsEV, connector: nil, size: vehicleType, near: nil, buffered: nil)
        request.httpBody = try JSONEncoder().encode(structuredRequest)

        let (data, _) = try await URLSession.shared.data(for: request)
        let recommendations = try JSONDecoder().decode([Recommendation].self, from: data)
        return recommendations
    }

    func getNLPRecommendation(lotName: String, query: String) async throws -> [Recommendation] {
        let lotId = apiLotId(from: lotName) // Assuming lotId is sent as lot_name
        let url = baseURL.appendingPathComponent("recommend/nl") // Following the prompt for /recommend/nl

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let nlpRequest = NLPRequest(lotName: lotId, query: query)
        request.httpBody = try JSONEncoder().encode(nlpRequest)

        let (data, _) = try await URLSession.shared.data(for: request)
        let recommendations = try JSONDecoder().decode([Recommendation].self, from: data)
        return recommendations
    }
}