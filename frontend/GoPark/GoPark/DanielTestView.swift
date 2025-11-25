import SwiftUI
import FirebaseAuth

struct DanielTestView: View {
    @StateObject private var recVM = RecommendationViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    // UI State
    @State private var selectedLot: String = "lot_a"
    
    // State for displaying user preferences
    @State private var currentVehicleType: String = "Not Set"
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
                .font(.headline)
            Picker("Select Lot", selection: $selectedLot) {
                Text("Lot A").tag("lot_a")
                Text("Lot B").tag("lot_b")
                Text("Lot C").tag("lot_c")
                Text("Lot D").tag("lot_d")
                Text("Lot E").tag("lot_e")
            }
            .pickerStyle(SegmentedPickerStyle())


            // Search Trigger
            Text("2. Search for Recommendation")
                .font(.headline)
            Button(action: searchRecommendation) {
                Label("Search Based on Saved Preferences", systemImage: "magnifyingglass")
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
                List(recVM.recommendations) { rec in
                    // Filter client-side just in case API returns for all lots
                    if rec.lotId.lowercased() == selectedLot.replacingOccurrences(of: "_", with: "") {
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
                .listStyle(.inset)
            }
        }
        .padding()
        .navigationTitle("Recommendation Test")
    }

    private func searchRecommendation() {
        // First, refresh the displayed preferences
        loadPreferences()

        // Then, call the ViewModel with the explicit preferences
        Task {
            await recVM.getRecommendation(
                lotName: selectedLot,
                vehicleType: currentVehicleType,
                wantsEV: currentWantsEV
            )
        }
    }
    
    private func loadPreferences() {
        guard let uid = authManager.userSession?.uid else {
            currentVehicleType = "Not Logged In"
            currentWantsEV = false
            return
        }
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
