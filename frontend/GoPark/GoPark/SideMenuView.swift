import SwiftUI
import Firebase
import FirebaseAuth

struct SideMenuView: View {
    @Binding var showMenu: Bool
    @Binding var showProfile: Bool
    // REMOVED: @Binding var showTestPage: Bool
    
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(alignment: .leading) {
            // User Info Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text(authManager.userSession?.displayName ?? "User")
                        .font(.headline)
                    Text(authManager.userSession?.email ?? "user@example.com")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 20)

            Divider()
                .padding(.bottom, 20)

            // Menu Options
            Button(action: {
                showProfile = true
                showMenu = false
            }) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("My Profile")
                        .foregroundColor(.black)
                }
            }
            .padding(.bottom, 10)

            Button(action: {
                // Parking History Action
            }) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Parking History")
                        .foregroundColor(.black)
                }
            }
            .padding(.bottom, 10)

            Button(action: {
                // Settings Action
            }) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                    Text("Settings")
                        .foregroundColor(.black)
                }
            }
            .padding(.bottom, 10)

            // REMOVED: The Button for "Daniel's Test Page"

            Spacer()

            // Logout Button
            Button(action: {
                authManager.signOut()
                showMenu = false
            }) {
                Text("Log Out")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.trailing, 80)
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        // Updated Preview to only pass 2 bindings
        SideMenuView(showMenu: .constant(true), showProfile: .constant(false))
            .environmentObject(AuthManager.shared)
    }
}
