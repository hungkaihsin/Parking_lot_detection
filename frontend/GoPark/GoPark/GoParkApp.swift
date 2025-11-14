//
//  GoParkApp.swift
//  GoPark
//
//  Created by Gia Huy Phung on 11/10/25.
//

import SwiftUI
import Firebase

@main
struct GoParkApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthManager.shared)
        }
    }
}
