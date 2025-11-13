import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func getLotLayout(lotId: String) async -> [Stall] {
        // For now, return hardcoded data.
        // In the future, this will make a network request.
        return [
            Stall(id: 1, coordinates: [[34.052235, -118.243683], [34.052235, -118.243783], [34.052335, -118.243783], [34.052335, -118.243683]]),
            Stall(id: 2, coordinates: [[34.052435, -118.243683], [34.052435, -118.243783], [34.052535, -118.243783], [34.052535, -118.243683]])
        ]
    }
}
