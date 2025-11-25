
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool // true for user, false for AI
}

struct AIChatView: View {
    let lotName: String
    @Binding var recommendedStallID: String?

    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                } else {
                                    Image(systemName: "sparkle")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    Text(message.text)
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(15)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }

                HStack {
                    TextField("Type your message...", text: $messageText)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)

                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Initial AI message
                messages.append(ChatMessage(text: "Hello! How can I help you find the perfect parking spot today in \(lotName)?", isUser: false))
            }
        }
    }

    private func sendMessage() {
        let userMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }

        messages.append(ChatMessage(text: userMessage, isUser: true))
        messageText = ""

        Task {
            do {
                let recommendations = try await NetworkManager.shared.getNLPRecommendation(lotName: lotName, query: userMessage)
                if let firstRecommendation = recommendations.first {
                    messages.append(ChatMessage(text: "I recommend stall \(firstRecommendation.stallId) because: \(firstRecommendation.reason)", isUser: false))
                    recommendedStallID = firstRecommendation.stallId
                } else {
                    messages.append(ChatMessage(text: "Sorry, I couldn't find a recommendation for that.", isUser: false))
                }
            } catch {
                messages.append(ChatMessage(text: "Error getting recommendation: \(error.localizedDescription)", isUser: false))
                print("Error getting NLP recommendation: \(error.localizedDescription)")
            }
        }
    }
}

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView(lotName: "lot_a", recommendedStallID: .constant(nil))
    }
}

