
import SwiftUI
import Firebase
import FirebaseAuth

struct SideMenuView: View {
    @Binding var showMenu: Bool
    @State private var showProfile = false
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(alignment: .leading) {
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

            Button(action: {
                showProfile = true
            }) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("My Profile")
                        .foregroundColor(.black)
                }
            }
            .padding(.bottom, 10)
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }

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

            Spacer()

            Button(action: {
                authManager.signOut()
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
        .padding(.trailing, 80) // To make it a side menu
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(showMenu: .constant(true))
            .environmentObject(AuthManager.shared)
    }
}
