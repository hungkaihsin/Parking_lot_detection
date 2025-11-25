import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var vehicleType: String = "Midsize"
    @State private var wantsEV: Bool = false
    @State private var showingSaveConfirmation = false
    
    let vehicleTypes = ["Compact", "Midsize", "Full", "SUV", "Truck"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // User Info Header
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
                        Spacer()
                    }
                    .padding([.horizontal, .top])
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Car Details Section
                    VStack(alignment: .leading, spacing: 15) {
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
                            ForEach(vehicleTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Toggle(isOn: $wantsEV) {
                            Text("I need EV charging")
                        }
                        .padding(.top)

                        // Save Button
                        Button(action: saveUserDetails) {
                            Text("Save Car Details")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                    
                    // Other Links Section
                    VStack(spacing: 15) {
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
                    
                    Spacer()

                    // Log Out Button
                    Button(action: { authManager.signOut() }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("My Profile")
            .onAppear(perform: loadUserDetails)
            .alert("Preferences Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func saveUserDetails() {
        guard let uid = authManager.userSession?.uid else { return }
        let defaults = UserDefaults.standard
        defaults.set(make, forKey: "\(uid)_userVehicleMake")
        defaults.set(model, forKey: "\(uid)_userVehicleModel")
        defaults.set(year, forKey: "\(uid)_userVehicleYear")
        defaults.set(vehicleType, forKey: "\(uid)_userVehicleType")
        defaults.set(wantsEV, forKey: "\(uid)_userWantsEV")
        showingSaveConfirmation = true
    }
    
    private func loadUserDetails() {
        guard let uid = authManager.userSession?.uid else { return }
        let defaults = UserDefaults.standard
        make = defaults.string(forKey: "\(uid)_userVehicleMake") ?? ""
        model = defaults.string(forKey: "\(uid)_userVehicleModel") ?? ""
        year = defaults.string(forKey: "\(uid)_userVehicleYear") ?? ""
        vehicleType = defaults.string(forKey: "\(uid)_userVehicleType") ?? "Midsize"
        wantsEV = defaults.bool(forKey: "\(uid)_userWantsEV")
    }
}
