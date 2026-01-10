//
//  ProfileView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var showLogoutAlert: Bool = false
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader
                        
                        // Account Settings
                        accountSettingsSection
                        
                        // App Settings
                        appSettingsSection
                        
                        // Logout Button
                        logoutButton
                        
                        // App Info
                        appInfoSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 4) {
                Text("User Name")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("user@example.com")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Account Settings
    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "person.fill",
                    title: "Edit Profile",
                    color: .blue
                ) {
                    // Handle edit profile
                }
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsRow(
                    icon: "lock.fill",
                    title: "Change Password",
                    color: .orange
                ) {
                    // Handle change password
                }
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    color: .red
                ) {
                    // Handle notifications
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - App Settings
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "moon.fill",
                    title: "Appearance",
                    color: .purple
                ) {
                    // Handle appearance
                }
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsRow(
                    icon: "shield.fill",
                    title: "Privacy & Security",
                    color: .green
                ) {
                    // Handle privacy
                }
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    color: .blue
                ) {
                    // Handle help
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: {
            hapticFeedback.impactOccurred(intensity: 0.8)
            showLogoutAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.square.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
                    .frame(width: 32, height: 32)
                
                Text("Sign Out")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.red)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - App Info
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Text("Version 1.0.0")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            
            Text("© 2026 Demo App")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Logout Handler
    private func handleLogout() {
        hapticFeedback.impactOccurred(intensity: 0.5)
        
        // Logout from FileMaker
        Task {
            await FileMakerService.shared.logout()
        }
        
        // Return to login screen
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isLoggedIn = false
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                
                Text(title)
                    .font(.system(size: 17))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView(isLoggedIn: .constant(true))
}
