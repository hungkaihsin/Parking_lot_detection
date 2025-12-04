import SwiftUI

struct RegistrationView: View {
    @Binding var showRegistration: Bool
    @State private var fullName = ""
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

            Text("Create Your Account")
                .font(.title2)
                .padding(.bottom, 30)

            Button(action: {
                // Google Sign-up Action
            }) {
                HStack {
                    Image(systemName: "g.circle.fill") // Placeholder for Google logo
                        .foregroundColor(.red)
                    Text("Sign up with Google")
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

            Button(action: {
                // Apple Sign-up Action
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .foregroundColor(.white)
                    Text("Sign up with Apple")
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
                Text("OR")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 20)
            .padding(.horizontal)

            TextField("Full Name", text: $fullName)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
                .padding(.horizontal)
                .textInputAutocapitalization(.never)

            TextField("Email", text: $email)
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
                print("RegistrationView: 'Sign Up' button tapped.")
                Task {
                    do {
                        try await authManager.signUp(email: email, password: password, fullName: fullName)
                        print("RegistrationView: Sign up successful.")
                        showRegistration = false // Dismiss the sheet after successful sign-up
                    } catch {
                        authError = error
                        showAlert = true
                        print("RegistrationView: Sign up failed with error: \(error.localizedDescription)")
                    }
                }
            }) {
                Text("Sign Up")
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

            HStack {
                Text("Already have an account?")
                Button(action: {
                    print("RegistrationView: 'Log In' button tapped. Setting showRegistration to false.")
                    showRegistration = false
                }) {
                    Text("Log In")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 20)

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView(showRegistration: .constant(true))
            .environmentObject(AuthManager.shared)
    }
}
