import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = URL(string: "http://127.0.0.1:8000/api/v1")!

    private init() {}

    func getHealthz() async throws -> HealthStatus {
        let url = baseURL.appendingPathComponent("healthz")
        let (data, _) = try await URLSession.shared.data(from: url)
        let healthStatus = try JSONDecoder().decode(HealthStatus.self, from: data)
        return healthStatus
    }

    func getLotLayout(lotId: String) async throws -> [Stall] {
        let url = baseURL.appendingPathComponent("lots/\(lotId)/spots")
        let (data, _) = try await URLSession.shared.data(from: url)
        let stalls = try JSONDecoder().decode([Stall].self, from: data)
        return stalls
    }
}