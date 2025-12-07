import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var authError: Error?
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack {
            Text("GoPark")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)

            Text("Welcome Back!")
                .font(.title2)
                .padding(.bottom, 50)

            TextField("Email", text: $email)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
                .padding(.horizontal)
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $password)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
                .padding(.horizontal)
                .padding(.top, 10)
                .textInputAutocapitalization(.never)

            Button(action: {
                // Google Sign-in Action
            }) {
                HStack {
                    Image(systemName: "g.circle.fill") // Placeholder for Google logo
                        .foregroundColor(.red)
                    Text("Sign in with Google")
                        .foregroundColor(.black)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Button(action: {
                // Apple Sign-in Action
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .foregroundColor(.white)
                    Text("Sign in with Apple")
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Button(action: {
                Task {
                    do {
                        try await authManager.signIn(email: email, password: password)
                    } catch {
                        authError = error
                        showAlert = true
                    }
                }
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(authError?.localizedDescription ?? "An unknown error occurred"), dismissButton: .default(Text("OK")))
            }

            Button(action: {
                // Forgot Password Action
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
            }
            .padding(.top, 20)

            HStack {
                Text("Don't have an account?")
                NavigationLink(destination: RegistrationView(showRegistration: .constant(false))) { // Direct NavigationLink
                    Text("Sign Up")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager.shared)
    }
}
