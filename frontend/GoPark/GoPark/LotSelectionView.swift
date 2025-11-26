import SwiftUI

struct LotSelectionView: View {
    @EnvironmentObject var authManager: AuthManager

    // 1. Add the ViewModel for AI Recommendations
    @StateObject private var recVM = RecommendationViewModel()
    
    // 2. Add state for showing the Chat
    @State private var showChat = false
    
    @State private var showSideMenu = false
    @State private var showProfile = false
    @State private var showTestPage = false

    var body: some View {
        NavigationView {
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
                    
                    // Section 2: The Parking Lots
                    Section(header: Text("Available Parking Lots")) {
                        // FIX: We now pass 'recVM' to every ParkingLotView so it knows what to highlight
                        NavigationLink(destination: ParkingLotView(lotName: "lot_a", recVM: recVM)) {
                            Text("Parking Lot A")
                        }
                        NavigationLink(destination: ParkingLotView(lotName: "lot_b", recVM: recVM)) {
                            Text("Parking Lot B")
                        }
                        NavigationLink(destination: ParkingLotView(lotName: "lot_c", recVM: recVM)) {
                            Text("Parking Lot C")
                        }
                        NavigationLink(destination: ParkingLotView(lotName: "lot_d", recVM: recVM)) {
                            Text("Parking Lot D")
                        }
                        NavigationLink(destination: ParkingLotView(lotName: "lot_e", recVM: recVM)) {
                            Text("Parking Lot E")
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
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                }
                .sheet(isPresented: $showTestPage) {
                    DanielTestView()
                }
                // 3. New Sheet for AI Chat
                .sheet(isPresented: $showChat) {
                    AIChatView(recVM: recVM, isPresented: $showChat)
                }
            }
        }
        .overlay(
            Group {
                if showSideMenu {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { showSideMenu = false }

                    SideMenuView(showMenu: $showSideMenu, showProfile: $showProfile, showTestPage: $showTestPage)
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
