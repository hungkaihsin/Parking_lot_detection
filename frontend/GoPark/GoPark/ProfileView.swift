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
                VStack(spacing: 20) {
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
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Car Details Section
                    Text("My Car Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
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
                    }

                    Text("Vehicle Type")
                        .font(.headline)
                        .padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Vehicle Type", selection: $vehicleType) {
                        ForEach(vehicleTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle(isOn: $wantsEV) {
                        Text("EV (Electric Vehicle)")
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
                    .padding(.top)
                    
                    Spacer()
                }
                .padding()
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthManager.shared)
    }
}
