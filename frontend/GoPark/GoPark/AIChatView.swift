import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct AIChatView: View {
    @ObservedObject var recVM: RecommendationViewModel
    @Binding var isPresented: Bool
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hello! Tell me what you need (e.g., 'EV spot', 'Wide spot'). I'll search all lots for you.", isUser: false)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(messages) { msg in
                                ChatBubble(message: msg)
                            }
                            
                            if recVM.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Searching all parking lots...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.leading)
                            }
                        }
                        .padding()
                    }
                    // Fix: iOS 17+ compatible onChange
                    .onChange(of: messages.count) { oldValue, newValue in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                HStack {
                    TextField("Type your request...", text: $messageText)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                        .disabled(recVM.isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(recVM.isLoading ? .gray : .blue)
                    }
                    .disabled(recVM.isLoading || messageText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("AI Parking Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }
    
    func sendMessage() {
        let query = messageText
        messageText = ""
        
        messages.append(ChatMessage(text: query, isUser: true))
        
        Task {
            await recVM.getNLPRecommendation(query: query)
            
            if let response = recVM.aiResponseReason {
                messages.append(ChatMessage(text: response, isUser: false))
            }
        }
    }
}

// MARK: - Helper Views

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            } else {
                Image(systemName: "sparkle")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                
                // FIX: LocalizedStringKey enables Markdown rendering (e.g., **Bold**)
                Text(LocalizedStringKey(message.text))
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(15)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
    }
}
