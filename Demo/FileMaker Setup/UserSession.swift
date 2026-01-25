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
    @Published var categories: [Category] = []
    @Published var isLoadingCategories: Bool = false
    
    private let userDefaultsKey = "currentUser"
    private let categoriesDefaultsKey = "userCategories"
    
    private init() {
        loadUserFromDefaults()
        loadCategoriesFromDefaults()
    }
    
    func login(user: User) {
        self.currentUser = user
        self.isLoggedIn = true
        saveUserToDefaults(user)
        print("✅ User logged in: \(user.fullName)")
        
        // Fetch categories after login
        Task {
            await fetchCategories()
        }
    }
    
    /// Fetches categories from FileMaker for the current user
    func fetchCategories() async {
        guard let user = currentUser else {
            print("⚠️ Cannot fetch categories: No user logged in")
            return
        }
        
        isLoadingCategories = true
        
        do {
            let fetchedCategories = try await FileMakerService.shared.fetchCategories(userID: user.userID)
            await MainActor.run {
                self.categories = fetchedCategories
                saveCategoriesToDefaults(fetchedCategories)
                print("✅ Loaded \(fetchedCategories.count) categories")
            }
        } catch {
            await MainActor.run {
                print("❌ Error fetching categories: \(error.localizedDescription)")
                // Keep existing categories if fetch fails
            }
        }
        
        isLoadingCategories = false
    }
    
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        self.categories = []
        clearUserFromDefaults()
        clearCategoriesFromDefaults()
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
    
    // MARK: - Categories Persistence
    private func saveCategoriesToDefaults(_ categories: [Category]) {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: categoriesDefaultsKey)
        }
    }
    
    private func loadCategoriesFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: categoriesDefaultsKey),
           let categories = try? JSONDecoder().decode([Category].self, from: data) {
            self.categories = categories
            print("📱 Restored \(categories.count) categories from storage")
        }
    }
    
    private func clearCategoriesFromDefaults() {
        UserDefaults.standard.removeObject(forKey: categoriesDefaultsKey)
    }
}