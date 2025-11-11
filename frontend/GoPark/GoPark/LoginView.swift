
import SwiftUI
import UIKit

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @Binding var showRegistration: Bool
    @Binding var isLoggedIn: Bool

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
                isLoggedIn = true
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

            Button(action: {
                // Forgot Password Action
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
            }
            .padding(.top, 20)

            HStack {
                Text("Don't have an account?")
                Button(action: {
                    showRegistration = true
                }) {
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
        LoginView(showRegistration: .constant(false), isLoggedIn: .constant(false))
    }
}
