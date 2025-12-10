import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        Group {
            if authManager.userSession == nil {
                NavigationStack {
                    LoginView()
                }
            } else {
                LotSelectionView()
            }
        }
        .environmentObject(authManager)
    }
}
