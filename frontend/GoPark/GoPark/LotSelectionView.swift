import SwiftUI
import FirebaseAuth

struct LotSelectionView: View {
    @EnvironmentObject var authManager: AuthManager

    // 1. Add the ViewModel for AI Recommendations
    @StateObject private var recVM = RecommendationViewModel()
    
    // 2. Add state for showing the Chat
    @State private var showChat = false
    
    @State private var showSideMenu = false
    @State private var showProfile = false
    // REMOVED: @State private var showTestPage = false
    


    var body: some View {
        NavigationStack(path: $recVM.navigationPath) {
            ZStack {

                List {
                    // Section 1: The AI Tool
                    Section(header: Text("AI Assistant")) {
                        Button(action: { showChat = true }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text("Find a Spot")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Ask AI to search all lots")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Section 2: Global Recommendations
                    Section(header: Text("Recommended for You")) {
                        if recVM.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Finding best spots...")
                                Spacer()
                            }
                        } else if recVM.recommendations.isEmpty {
                            Text("No specific recommendations right now.")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(recVM.recommendations.prefix(3)) { rec in
                                Button(action: {
                                    // Set target and trigger navigation
                                    recVM.recommendedLotID = rec.lotId
                                    recVM.recommendedStallID = rec.stallId
                                    recVM.navigationPath.append(.parkingLot(lotName: rec.lotId))
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Spot \(rec.stallId) (\(rec.lotId.replacingOccurrences(of: "_", with: " ").capitalized))")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            if !rec.reasons.isEmpty {
                                                Text(rec.reasons.joined(separator: " • "))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        // Score Badge
                                        Text("\(Int(rec.score))%")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(6)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                            
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Section 3: The Parking Lots
                    Section(header: Text("Available Parking Lots")) {
                        Button(action: { recVM.navigationPath.append(.parkingLot(lotName: "lot_a")) }) {
                            Text("Parking Lot A").foregroundColor(.primary)
                        }
                        Button(action: { recVM.navigationPath.append(.parkingLot(lotName: "lot_b")) }) {
                            Text("Parking Lot B").foregroundColor(.primary)
                        }
                        Button(action: { recVM.navigationPath.append(.parkingLot(lotName: "lot_c")) }) {
                            Text("Parking Lot C").foregroundColor(.primary)
                        }
                        Button(action: { recVM.navigationPath.append(.parkingLot(lotName: "lot_d")) }) {
                            Text("Parking Lot D").foregroundColor(.primary)
                        }
                        Button(action: { recVM.navigationPath.append(.parkingLot(lotName: "lot_e")) }) {
                            Text("Parking Lot E").foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("GoPark")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showSideMenu.toggle() }) {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
                // Existing Sheets
                .sheet(isPresented: $showProfile, onDismiss: {
                    Task {
                        await recVM.fetchTopRecommendations(uid: authManager.userSession?.uid)
                    }
                }) {
                    ProfileView()
                }
                // REMOVED: .sheet(isPresented: $showTestPage) { ... }
                
                // 3. New Sheet for AI Chat
                .sheet(isPresented: $showChat) {
                    AIChatView(recVM: recVM, isPresented: $showChat)
                }
                // 4. Trigger navigation when the VM's flag is set

                .onAppear {
                    Task {
                        await recVM.fetchTopRecommendations(uid: authManager.userSession?.uid)
                    }
                }
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .parkingLot(let lotName):
                        ParkingLotView(lotName: lotName, recVM: recVM)
                    }
                }
            }
        }
        .overlay(
            Group {
                if showSideMenu {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { showSideMenu = false }

                    // UPDATED: Removed showTestPage argument
                    SideMenuView(showMenu: $showSideMenu, showProfile: $showProfile)
                        .transition(.move(edge: .leading))
                }
            }
        )
        .animation(.easeInOut, value: showSideMenu)
        .environmentObject(authManager)
    }
}

struct LotSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LotSelectionView()
            .environmentObject(AuthManager.shared)
    }
}
