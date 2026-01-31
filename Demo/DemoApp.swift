//
//  DemoApp.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

@main
struct DemoApp: App {
    @StateObject private var userSession = UserSession.shared
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .preferredColorScheme(userSession.isLoggedIn ? userSession.preferredColorScheme : .dark)
        }
    }
}
