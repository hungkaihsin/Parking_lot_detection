import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var vehicleType: String = ""
    @State private var showSaveAlert = false
    let vehicleTypes = ["Compact", "Sedan", "SUV", "EV"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)

                        VStack(alignment: .leading) {
                            Text(authManager.userSession?.displayName ?? "User")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(authManager.userSession?.email ?? "user@example.com")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 20)

                    Text("My Car Details")
                        .font(.title2)
                        .fontWeight(.bold)

                    TextField("Make", text: $make)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)

                    TextField("Model", text: $model)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)

                    TextField("Year", text: $year)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)

                    Text("Vehicle Type")
                        .font(.headline)
                        .padding(.top)

                    Picker("Vehicle Type", selection: $vehicleType) {
                        ForEach(vehicleTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Button(action: {
                        UserDefaults.standard.set(vehicleType, forKey: "userVehicleType")
                        showSaveAlert = true
                    }) {
                        Text("Save Car Details")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)

                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Payment Methods")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)

                        HStack {
                            Image(systemName: "clock")
                            Text("Parking History")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                    )
                    .padding(.top)
                    
                    Spacer()

                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("My Profile")
            .navigationBarItems(trailing: Button("Edit") {
                // Edit Action
            })
            .onAppear {
                self.vehicleType = UserDefaults.standard.string(forKey: "userVehicleType") ?? ""
            }
            .alert(isPresented: $showSaveAlert) {
                Alert(title: Text("Saved!"), message: Text("Your car details have been updated."), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthManager.shared)
    }
}
