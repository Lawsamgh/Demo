//
//  ProfileView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Header
                        userHeaderSection
                        
                        // Account Settings
                        accountSection
                        
                        // App Settings
                        settingsSection
                        
                        // Logout Button
                        logoutButton
                        
                        // Version Info
                        versionInfo
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                userSession.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - User Header
    private var userHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                if let user = userSession.currentUser {
                    Text(getInitials(from: user))
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            // User Info
            VStack(spacing: 8) {
                if let user = userSession.currentUser {
                    Text(user.fullName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text(user.email)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "person.fill",
                    title: "Edit Profile",
                    color: .blue
                ) {
                    // Handle edit profile
                }
                
                Divider()
                    .padding(.leading, 52)
                
                ProfileRow(
                    icon: "lock.fill",
                    title: "Change Password",
                    color: .orange
                ) {
                    // Handle change password
                }
                
                Divider()
                    .padding(.leading, 52)
                
                ProfileRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    color: .purple
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
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "moon.fill",
                    title: "Appearance",
                    color: .indigo
                ) {
                    // Handle appearance
                }
                
                Divider()
                    .padding(.leading, 52)
                
                ProfileRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    color: .green
                ) {
                    // Handle help
                }
                
                Divider()
                    .padding(.leading, 52)
                
                ProfileRow(
                    icon: "info.circle.fill",
                    title: "About",
                    color: .gray
                ) {
                    // Handle about
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
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showLogoutAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.square.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
                
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
    
    // MARK: - Version Info
    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text("Demo App")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    private func getInitials(from user: User) -> String {
        let firstInitial = user.firstName.prefix(1).uppercased()
        let lastInitial = user.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}

// MARK: - Profile Row
struct ProfileRow: View {
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
                    .font(.system(size: 17, weight: .medium))
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
    ProfileView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ProfileView()
        .preferredColorScheme(.dark)
}