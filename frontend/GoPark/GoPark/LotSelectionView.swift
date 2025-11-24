import SwiftUI

struct LotSelectionView: View {
    @EnvironmentObject var authManager: AuthManager // Use EnvironmentObject for AuthManager

    // UI States
    @State private var showSideMenu = false // Only keep showSideMenu here

    var body: some View {
        NavigationView {
            ZStack {
                // The main list of parking lots
                List {
                    NavigationLink(destination: ParkingLotView(lotName: "lot_a")) {
                        Text("Parking Lot A")
                    }
                    NavigationLink(destination: ParkingLotView(lotName: "lot_b")) {
                        Text("Parking Lot B")
                    }
                    NavigationLink(destination: ParkingLotView(lotName: "lot_c")) {
                        Text("Parking Lot C")
                    }
                    NavigationLink(destination: ParkingLotView(lotName: "lot_d")) {
                        Text("Parking Lot D")
                    }
                    NavigationLink(destination: ParkingLotView(lotName: "lot_e")) {
                        Text("Parking Lot E")
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Select a Lot")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showSideMenu.toggle() }) {
                            Image(systemName: "list.bullet")
                        }
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
                    
                    SideMenuView(showMenu: $showSideMenu)
                        .transition(.move(edge: .leading))
                }
            }
        )
        .animation(.easeInOut, value: showSideMenu)
        .environmentObject(authManager) // Pass authManager as EnvironmentObject
    }
}

struct LotSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LotSelectionView()
            .environmentObject(AuthManager.shared) // Provide AuthManager for preview
    }
}
