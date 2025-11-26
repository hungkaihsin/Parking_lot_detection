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
    
    // MARK: - Global AI Search (Natural Language)
    func getNLPRecommendation(query: String) async {
        self.isLoading = true
        self.errorMessage = nil
        self.aiResponseReason = nil
        self.recommendedStallID = nil
        self.recommendedLotID = nil
        
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
            
            if fetchedRecommendations.isEmpty {
                self.aiResponseReason = "I'm sorry, I looked through all the lots but couldn't find a spot that matches your criteria."
            } else {
                // 1. Take the Top 3 Recommendations
                let topPicks = fetchedRecommendations.prefix(3)
                
                // 2. Build a Friendly, Structured Response
                var responseString = "I found **\(topPicks.count) available spots** for you:\n"
                
                for rec in topPicks {
                    // Logic to format "lot_b" or "lotb" into "Lot B"
                    var niceLotName = rec.lotId.replacingOccurrences(of: "_", with: " ").capitalized
                    
                    // Specific fix for "Lotb" -> "Lot B"
                    if niceLotName.lowercased().hasPrefix("lot") && !niceLotName.contains(" ") && niceLotName.count > 3 {
                        let index = niceLotName.index(niceLotName.startIndex, offsetBy: 3)
                        niceLotName.insert(" ", at: index)
                    }
                    
                    let shortId = String(rec.stallId.suffix(3)) // Last 3 digits for readability
                    let reasons = rec.reasons.joined(separator: ", ")
                    
                    // Bullet Point Format using Markdown
                    responseString += "\n• **\(niceLotName)** (Spot ...\(shortId))\n   _\(reasons)_"
                }
                
                // 3. Highlight the #1 Best Spot
                if let best = topPicks.first {
                    var bestLotName = best.lotId.replacingOccurrences(of: "_", with: " ").capitalized
                    if bestLotName.lowercased().hasPrefix("lot") && !bestLotName.contains(" ") && bestLotName.count > 3 {
                         bestLotName.insert(" ", at: bestLotName.index(bestLotName.startIndex, offsetBy: 3))
                    }
                    
                    responseString += "\n\nTap close to see the best spot in **\(bestLotName)**!"
                    
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
