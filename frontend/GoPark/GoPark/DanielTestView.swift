import SwiftUI

struct DanielTestView: View {
    @StateObject private var recVM = RecommendationViewModel()
    @State private var selectedLot: String = "lot_a" // Default to Lot A

    var body: some View {
        VStack {
            Text("Select a Lot to get a recommendation based on your saved preferences.")
                .multilineTextAlignment(.center)
                .padding()

            HStack(spacing: 20) {
                Button("Lot A") {
                    selectedLot = "lot_a"
                }
                .buttonStyle(.bordered)
                .tint(selectedLot == "lot_a" ? .blue : .gray)

                Button("Lot B") {
                    selectedLot = "lot_b"
                }
                .buttonStyle(.bordered)
                .tint(selectedLot == "lot_b" ? .blue : .gray)
            }
            .padding()

            Button(action: searchRecommendation) {
                Label("Search Recommendation", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            if recVM.isLoading {
                ProgressView("Finding recommendations...")
                    .padding()
            } else if let errorMessage = recVM.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(recVM.recommendations) { rec in
                    // Filter recommendations by selected lot before displaying
                    if rec.lotId.lowercased() == selectedLot {
                        VStack(alignment: .leading) {
                            Text("Stall: \(rec.stallId)")
                                .font(.headline)
                            Text("In: \(rec.lotId)")
                                .font(.subheadline)
                            ForEach(rec.reasons, id: \.self) { reason in
                                Text("• \(reason)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Recommendation Test")
    }

    private func searchRecommendation() {
        // Get the user's saved vehicle type from UserDefaults
        let vehicleType = UserDefaults.standard.string(forKey: "userVehicleType") ?? "suv"
        
        // Use the saved vehicle type as the query
        Task {
            await recVM.getRecommendations(query: vehicleType.lowercased())
        }
    }
}

struct DanielTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DanielTestView()
        }
    }
}