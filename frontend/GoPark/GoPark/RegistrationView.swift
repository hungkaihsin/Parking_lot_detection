
import SwiftUI
import UIKit

struct RegistrationView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @Binding var showRegistration: Bool

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
                // Sign Up Action
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

            HStack {
                Text("Already have an account?")
                Button(action: {
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
    }
}
