//
//  ContentView.swift
//  GoPark
//
//  Created by Gia Huy Phung on 11/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared // Use AuthManager
    @State private var showChat = false // Global chat state

    var body: some View {
        ZStack {
            if authManager.userSession == nil { // Check authManager.userSession
                NavigationView { // Wrap LoginView in NavigationView
                    LoginView()
                }
            } else {
                LotSelectionView()
            }

            // Floating Chat Button (visible when logged in)
            if authManager.userSession != nil { // Check authManager.userSession
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showChat = true
                        }) {
                            Image(systemName: "message.fill")
                                .font(.title)
                                .padding(25)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showChat) {
            AIChatView() // Assuming AIChatView is defined
        }
        .environmentObject(authManager) // Pass authManager as EnvironmentObject
    }
}

#Preview {
    ContentView()
}
