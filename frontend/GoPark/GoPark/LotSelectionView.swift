import SwiftUI

struct LotSelectionView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var showSideMenu = false
    @State private var showProfile = false
    @State private var showTestPage = false

    var body: some View {
        NavigationView {
            ZStack {
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
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                }
                .sheet(isPresented: $showTestPage) {
                    DanielTestView()
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
