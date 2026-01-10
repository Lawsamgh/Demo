//
//  UserSession.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import Foundation
import SwiftUI

@MainActor
class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    private let userDefaultsKey = "currentUser"
    
    private init() {
        loadUserFromDefaults()
    }
    
    func login(user: User) {
        self.currentUser = user
        self.isLoggedIn = true
        saveUserToDefaults(user)
        print("✅ User logged in: \(user.fullName)")
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        clearUserFromDefaults()
        print("👋 User logged out")
        
        // Clear FileMaker session
        Task {
            await FileMakerService.shared.logout()
        }
    }
    
    // MARK: - UserDefaults Persistence
    private func saveUserToDefaults(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUserFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isLoggedIn = true
            print("📱 Restored user session: \(user.fullName)")
        }
    }
    
    private func clearUserFromDefaults() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}