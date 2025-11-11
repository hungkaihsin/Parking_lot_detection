
import SwiftUI

struct ProfileView: View {
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var selectedVehicleType = 0
    let vehicleTypes = ["Sedan", "SUV", "EV", "Compact"]

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
                            Text("Huy Nguyen")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("huy.nguyen@example.com")
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

                    Picker("Vehicle Type", selection: $selectedVehicleType) {
                        ForEach(0..<vehicleTypes.count) { index in
                            Text(vehicleTypes[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Button(action: {
                        // Save Car Details Action
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
                        // Log Out Action
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
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
