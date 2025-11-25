import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!

    private init() {}

    func getHealthz() async throws -> HealthStatus {
        let url = baseURL.appendingPathComponent("healthz")
        let (data, _) = try await URLSession.shared.data(from: url)
        let healthStatus = try JSONDecoder().decode(HealthStatus.self, from: data)
        return healthStatus
    }

    func getRecommendations(requestBody: RecommendationRequest) async throws -> [Recommendation] {
        let url = baseURL.appendingPathComponent("recommend")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(RecommendationResponse.self, from: data)
        return response.recommendations
    }

    // This function will be added back later if needed, but for now
    // ParkingLotView loads from local files.
    // func getLotLayout(lotId: String) async throws -> [Stall] {
    //     ...
    // }
}
