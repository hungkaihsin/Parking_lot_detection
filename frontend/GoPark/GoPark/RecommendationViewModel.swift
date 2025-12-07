import Foundation
import Combine
import SwiftUI

@MainActor
class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // UI Helpers for Map and Chat
    @Published var recommendedStallID: String?
    @Published var recommendedLotID: String?
    @Published var aiResponseReason: String?
    @Published var shouldNavigate: Bool = false

    func getRecommendation(lotName: String, vehicleType: String, wantsEV: Bool) async {
        // Keeps existing logic for ProfileView compatibility (if used)
        self.isLoading = true
        self.errorMessage = nil
        
        let sizeClass = vehicleTypeToSizeClass(vehicleType)
        let requestBody = RecommendationRequest(
            query: nil, isAda: nil, isEv: wantsEV, connector: nil, sizeClass: sizeClass, near: nil, buffered: nil
        )
        
        do {
            let fetchedRecommendations = try await NetworkManager.shared.getRecommendations(requestBody: requestBody)
            self.recommendations = fetchedRecommendations
        } catch {
            self.errorMessage = error.localizedDescription
        }
        self.isLoading = false
    }
    
    // MARK: - Fetch Top Recommendations (No Query)
    func fetchTopRecommendations(uid: String?) async {
        self.isLoading = true
        self.errorMessage = nil
        
        // 1. Default values
        var sizeClass = 1 // Default to Midsize
        var isEv: Bool? = nil
        
        // 2. Load from Profile if UID is present
        if let uid = uid {
            let defaults = UserDefaults.standard
            let savedType = defaults.string(forKey: "\(uid)_userVehicleType") ?? "Midsize"
            sizeClass = vehicleTypeToSizeClass(savedType)
            
            // Only set isEv to true if the user explicitly wants it. 
            // If false, we pass nil to allow both EV and non-EV spots (unless strict logic dictates otherwise).
            // For now, let's respect the user's "I need EV" flag as a strict filter.
            if defaults.bool(forKey: "\(uid)_userWantsEV") {
                isEv = true
            }
        }
        
        // Default request for "general" recommendations, but respecting Profile
        let requestBody = RecommendationRequest(
            query: nil, isAda: nil, isEv: isEv, connector: nil, sizeClass: sizeClass, near: true, buffered: nil
        )
        
        do {
            let fetchedRecommendations = try await NetworkManager.shared.getRecommendations(requestBody: requestBody)
            self.recommendations = fetchedRecommendations
        } catch {
            print(">>> Fetch Top Recs Error: \(error)")
            // Don't show an error message to the user for background fetches, just log it
        }
        self.isLoading = false
    }
    
    // MARK: - Global AI Search (Natural Language)
    func getNLPRecommendation(query: String) async {
        self.isLoading = true
        self.errorMessage = nil
        self.aiResponseReason = nil
        self.recommendedStallID = nil
        self.recommendedLotID = nil
        self.shouldNavigate = false
        
        let requestBody = RecommendationRequest(
            query: query,
            isAda: nil,
            isEv: nil,
            connector: nil,
            sizeClass: nil,
            near: nil,
            buffered: nil
        )
        
        print(">>> Sending Global NLP Request: \(requestBody)")
        
        do {
            let fetchedRecommendations = try await NetworkManager.shared.getRecommendations(requestBody: requestBody)
            self.recommendations = fetchedRecommendations

            if fetchedRecommendations.isEmpty {
                self.aiResponseReason = "I'm sorry, I looked through all the lots but couldn't find a spot that matches your criteria."
            } else {
                // 1. Take the Top 3 Recommendations
                let topPicks = fetchedRecommendations.prefix(3)
                
                // 2. Build a simple, friendly response string without the list
                let spotCount = topPicks.count
                let spotsNoun = spotCount == 1 ? "spot" : "spots"
                let responseString = "I found **\(spotCount) matching \(spotsNoun)** for you. Here are the best options:"

                // 3. Set the #1 Best Spot for default navigation if user doesn't pick one
                if let best = topPicks.first {
                    self.recommendedStallID = best.stallId
                    self.recommendedLotID = best.lotId
                }
                
                self.aiResponseReason = responseString
            }
            
        } catch {
            print(">>> NLP Error: \(error)")
            self.errorMessage = error.localizedDescription
            self.aiResponseReason = "Sorry, I'm having trouble connecting to the parking server right now."
        }
        
        self.isLoading = false
    }

    private func vehicleTypeToSizeClass(_ vehicleType: String) -> Int {
        switch vehicleType.lowercased() {
        case "compact": return 0
        case "midsize": return 1
        case "full": return 2
        case "suv": return 3
        case "truck": return 4
        default: return 1
        }
    }
}
