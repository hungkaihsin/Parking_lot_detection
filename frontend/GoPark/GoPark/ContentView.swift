//
//  ContentView.swift
//  GoPark
//
//  Created by Gia Huy Phung on 11/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showRegistration = false
    @State private var isLoggedIn = false
    @State private var showChat = false // Global chat state

    var body: some View {
        ZStack {
            if isLoggedIn {
                LotSelectionView(isLoggedIn: $isLoggedIn)
            } else {
                if showRegistration {
                    RegistrationView(showRegistration: $showRegistration)
                } else {
                    LoginView(showRegistration: $showRegistration, isLoggedIn: $isLoggedIn)
                }
            }

            // Floating Chat Button (visible when logged in)
            if isLoggedIn {
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
    }
}

#Preview {
    ContentView()
}
