//
//  ContentView.swift
//  GoPark
//
//  Created by Gia Huy Phung on 11/10/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.userSession == nil {
                NavigationView {
                    LoginView()
                }
            } else {
                MainMapView()
            }
        }
    }
}

#Preview {
    ContentView()
}
