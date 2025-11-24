import SwiftUI
import FirebaseAuth

struct DanielTestView: View {
    @StateObject private var recVM = RecommendationViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    // UI State
    @State private var selectedLot: String = "lot_a"
    
    // State for displaying user preferences
    @State private var currentVehicleType: String = ""
    @State private var currentWantsEV: Bool = false

    var body: some View {
        VStack(spacing: 15) {
            
            // Display Current Preferences
            VStack {
                Text("Current Saved Preferences")
                    .font(.headline)
                Text("Vehicle Size: \(currentVehicleType)")
                Text("Wants EV Charging: \(currentWantsEV ? "Yes" : "No")")
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .onAppear(perform: loadPreferences)

            Divider()

            // Lot Selection
            Text("1. Select a Lot")
            HStack(spacing: 20) {
                Button("Lot A") { selectedLot = "lot_a" }
                    .buttonStyle(.bordered)
                    .tint(selectedLot == "lot_a" ? .blue : .gray)

                Button("Lot B") { selectedLot = "lot_b" }
                    .buttonStyle(.bordered)
                    .tint(selectedLot == "lot_b" ? .blue : .gray)
            }

            // Search Trigger
            Text("2. Search for Recommendation")
            Button(action: searchRecommendation) {
                Label("Search Recommendation", systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)

            // Results
            if recVM.isLoading {
                ProgressView("Finding recommendations...")
                    .padding()
            } else if let errorMessage = recVM.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                List {
                    // Filter recommendations by selected lot before displaying
                    let filteredRecs = recVM.recommendations.filter { $0.lotId.lowercased() == selectedLot.replacingOccurrences(of: "_", with: "") }
                    
                    if filteredRecs.isEmpty && !recVM.recommendations.isEmpty {
                        Text("No recommendations found for \(selectedLot.replacingOccurrences(of: "_", with: " ").capitalized).")
                    }
                    
                    ForEach(filteredRecs) { rec in
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
        guard let uid = authManager.userSession?.uid else { return }
        let defaults = UserDefaults.standard
        let vehicleType = defaults.string(forKey: "\(uid)_userVehicleType") ?? "Midsize"
        let wantsEV = defaults.bool(forKey: "\(uid)_userWantsEV")

        // Update the UI to reflect the preferences being used for this search
        self.currentVehicleType = vehicleType
        self.currentWantsEV = wantsEV
        
        // Call the ViewModel with the explicit preferences
        Task {
            await recVM.getRecommendation(lotName: selectedLot, vehicleType: vehicleType, wantsEV: wantsEV)
        }
    }
    
    private func loadPreferences() {
        guard let uid = authManager.userSession?.uid else { return }
        let defaults = UserDefaults.standard
        currentVehicleType = defaults.string(forKey: "\(uid)_userVehicleType") ?? "Not Set"
        currentWantsEV = defaults.bool(forKey: "\(uid)_userWantsEV")
    }
}

struct DanielTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DanielTestView()
                .environmentObject(AuthManager.shared)
        }
    }
}
