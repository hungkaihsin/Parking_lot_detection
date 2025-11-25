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
