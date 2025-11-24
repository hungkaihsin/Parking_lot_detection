import Foundation
import Combine
import SwiftUI // For UserDefaults

class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @MainActor
    func getRecommendations(query: String) async {
        self.isLoading = true
        self.errorMessage = nil
        self.recommendations = []

        let wantsEV = UserDefaults.standard.bool(forKey: "userWantsEV")
        
        let requestBody = RecommendationRequest(
            query: query,
            isAda: nil,
            isEv: wantsEV,
            connector: nil,
            sizeClass: nil,
            near: nil,
            buffered: nil
        )

        print(">>> Sending Recommendation Request: \(requestBody)")

        do {
            let fetchedRecommendations = try await NetworkManager.shared.getRecommendations(requestBody: requestBody)
            self.recommendations = fetchedRecommendations
        } catch {
            print(">>> Recommendation Error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        self.isLoading = false
    }
}
