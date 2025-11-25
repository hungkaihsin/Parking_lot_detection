import Foundation
import Combine
import SwiftUI // For UserDefaults

class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @MainActor
    func getRecommendation(lotName: String, vehicleType: String, wantsEV: Bool) async {
        self.isLoading = true
        self.errorMessage = nil
        self.recommendations = []

        let sizeClass = vehicleTypeToSizeClass(vehicleType)

        let requestBody = RecommendationRequest(
            query: nil,
            isAda: nil,
            isEv: wantsEV,
            connector: nil,
            sizeClass: sizeClass,
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

    private func vehicleTypeToSizeClass(_ vehicleType: String) -> Int {
        switch vehicleType.lowercased() {
        case "compact":
            return 0
        case "midsize":
            return 1
        case "full":
            return 2
        case "suv":
            return 3
        case "truck":
            return 4
        default:
            return 1 // Default to Midsize
        }
    }
}

import Foundation
import Combine

struct AppError: Identifiable {
    let id = UUID()
    let message: String
}

class RecommendationViewModel: ObservableObject {
    @Published var recommendedStallID: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: AppError? // Changed to AppError?

    func getAutoRecommendation(lotName: String) async {
        isLoading = true
        errorMessage = nil
        recommendedStallID = nil

        let userDefaults = UserDefaults.standard
        let vehicleType = userDefaults.string(forKey: "userVehicleType") ?? "Sedan" // Default to Sedan
        let wantsEV = userDefaults.bool(forKey: "userWantsEV") // Assuming a default of false if not set

        do {
            let recommendations = try await NetworkManager.shared.getStructuredRecommendation(
                lotName: lotName,
                vehicleType: vehicleType,
                wantsEV: wantsEV
            )
            recommendedStallID = recommendations.first?.stallId
        } catch {
            errorMessage = AppError(message: error.localizedDescription) // Wrap error in AppError
            print("Error getting auto recommendation: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
