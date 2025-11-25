
import SwiftUI

struct AIChatView: View {
    @State private var messageText = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        // AI Message
                        HStack(alignment: .top) {
                            Image(systemName: "sparkle")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text("Hello! How can I help you find the perfect parking spot today?")
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(15)
                        }

                        // User Message
                        HStack {
                            Spacer()
                            Text("I'm looking for parking near the city center.")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        // AI Message
                        HStack(alignment: .top) {
                            Image(systemName: "sparkle")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text("Sure, I can help with that. Do you have any specific requirements, like vehicle size or EV charging?")
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(15)
                        }
                    }
                    .padding()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("Parking for SUV") {}
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(20)
                            .foregroundColor(.black)
                        Button("EV Charging") {}
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(20)
                            .foregroundColor(.black)
                        Button("Covered Parking") {}
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(20)
                            .foregroundColor(.black)
                        Button("Cheapest Parking") {}
                            .padding()
                            .background(Color(UIColor.systemGray5))
                            .cornerRadius(20)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)

                HStack {
                    TextField("Type your message...", text: $messageText)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)

                    Button(action: {
                        // Send message action
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
}
