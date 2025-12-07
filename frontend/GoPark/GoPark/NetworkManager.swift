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

    func fetchSpots(lotId: String) async throws -> [APIStall] {
        let url = baseURL.appendingPathComponent("lots/\(lotId)/spots")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([APIStall].self, from: data)
    }

    func triggerPrediction(lotId: String, imageData: Data) async throws -> PredictionResponse {
        let url = baseURL.appendingPathComponent("lots/\(lotId)/predict")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"lot_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PredictionResponse.self, from: data)
    }

    // This function will be added back later if needed, but for now
    // ParkingLotView loads from local files.
    // func getLotLayout(lotId: String) async throws -> [Stall] {
    //     ...
    // }
}
