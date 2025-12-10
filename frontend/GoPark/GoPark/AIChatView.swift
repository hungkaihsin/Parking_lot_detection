import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var recommendations: [Recommendation]? = nil
}

struct AIChatView: View {
    @ObservedObject var recVM: RecommendationViewModel
    @Binding var isPresented: Bool
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hello! Tell me what you need (e.g., 'EV spot', 'Wide spot'). I'll search all lots for you.", isUser: false)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(messages) { msg in
                                ChatBubble(message: msg) { selectedRec in
                                    handleRecommendationSelection(selectedRec)
                                }
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
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastId = messages.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                
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
                    Button("Close") {
                        isPresented = false
                    }
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
            
            var responseText = recVM.aiResponseReason ?? "I'm sorry, I couldn't find anything."
            let recs = Array(recVM.recommendations.prefix(3))
            
            let responseMsg = ChatMessage(
                text: responseText,
                isUser: false,
                recommendations: recs.isEmpty ? nil : recs
            )
            
            messages.append(responseMsg)
        }
    }
    
    func formatLotIdForNavigation(_ lotID: String) -> String {
        let cleaned = lotID.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "_", with: "")
        if cleaned.hasPrefix("lot"), let lastChar = cleaned.last, lastChar.isLetter {
            return "lot_\(lastChar)"
        }
        return lotID
    }

    func handleRecommendationSelection(_ rec: Recommendation) {
        print("--- DEBUG: Recommendation Tapped ---")
        print("Original Lot ID: \(rec.lotId)")
        print("Stall ID: \(rec.stallId)")

        let formattedId = formatLotIdForNavigation(rec.lotId)
        recVM.recommendedLotID = formattedId
        print("Formatted Lot ID for nav: \(formattedId)")
        
        recVM.recommendedStallID = rec.stallId
        recVM.navigationPath.append(.parkingLot(lotName: formattedId))

        print("------------------------------------")
        
        isPresented = false
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var onSelectRecommendation: ((Recommendation) -> Void)? = nil
    
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
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStringKey(message.text))
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(15)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let recs = message.recommendations, !recs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(recs) { rec in
                                    VStack(alignment: .leading) {
                                        Text(formatLotName(rec.lotId))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Spot \(rec.stallId.suffix(3))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "chevron.right.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .frame(width: 160, height: 120)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onSelectRecommendation?(rec)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                Spacer()
            }
        }
    }
    
    func formatLotName(_ lotID: String) -> String {
        var niceName = lotID.replacingOccurrences(of: "_", with: " ").capitalized
        if niceName.lowercased().hasPrefix("lot") && !niceName.contains(" ") && niceName.count > 3 {
            let index = niceName.index(niceName.startIndex, offsetBy: 3)
            niceName.insert(" ", at: index)
        }
        return niceName
    }
}