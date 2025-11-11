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

    var body: some View {
        if isLoggedIn {
            MainMapView(isLoggedIn: $isLoggedIn)
        } else {
            if showRegistration {
                RegistrationView(showRegistration: $showRegistration)
            } else {
                LoginView(showRegistration: $showRegistration, isLoggedIn: $isLoggedIn)
            }
        }
    }
}

#Preview {
    ContentView()
}
