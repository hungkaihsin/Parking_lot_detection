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
    
    // 3. State for programmatic navigation (isActive pattern)
    @State private var isLotAActive = false
    @State private var isLotBActive = false
    @State private var isLotCActive = false
    @State private var isLotDActive = false
    @State private var isLotEActive = false

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
                        // Updated NavigationLinks to use the 'isActive' pattern for more reliable programmatic navigation
                        NavigationLink(
                            destination: ParkingLotView(lotName: "lot_a", recVM: recVM),
                            isActive: $isLotAActive
                        ) {
                            Text("Parking Lot A")
                        }
                        NavigationLink(
                            destination: ParkingLotView(lotName: "lot_b", recVM: recVM),
                            isActive: $isLotBActive
                        ) {
                            Text("Parking Lot B")
                        }
                        NavigationLink(
                            destination: ParkingLotView(lotName: "lot_c", recVM: recVM),
                            isActive: $isLotCActive
                        ) {
                            Text("Parking Lot C")
                        }
                        NavigationLink(
                            destination: ParkingLotView(lotName: "lot_d", recVM: recVM),
                            isActive: $isLotDActive
                        ) {
                            Text("Parking Lot D")
                        }
                        NavigationLink(
                            destination: ParkingLotView(lotName: "lot_e", recVM: recVM),
                            isActive: $isLotEActive
                        ) {
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
                // 4. Trigger navigation when the VM's flag is set
                .onChange(of: recVM.shouldNavigate) {
                    print("--- DEBUG: LotSelectionView onChange detected ---")
                    print("recVM.shouldNavigate is: \(recVM.shouldNavigate)")
                    print("recVM.recommendedLotID is: \(recVM.recommendedLotID ?? "nil")")
                    
                    if recVM.shouldNavigate, let recommendedLot = recVM.recommendedLotID {
                        // The sheet has been dismissed. Now, trigger the correct NavigationLink.
                        DispatchQueue.main.async {
                            print("Dispatching navigation to \(recommendedLot)")
                            switch recommendedLot {
                            case "lot_a": isLotAActive = true
                            case "lot_b": isLotBActive = true
                            case "lot_c": isLotCActive = true
                            case "lot_d": isLotDActive = true
                            case "lot_e": isLotEActive = true
                            default:
                                print("Error: recommendedLot ID not recognized!")
                                break
                            }
                            // Reset the flag immediately after use.
                            recVM.shouldNavigate = false
                        }
                    }
                    print("---------------------------------------------")
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
