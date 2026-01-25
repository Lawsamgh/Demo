//
//  SettingView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct SettingView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showLogoutAlert = false
    @State private var showCategoryManagement = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Header
                        userHeaderSection
                        
                        // Account Settings
                        accountSection
                        
                        // Manage Data Section
                        manageDataSection
                        
                        // App Settings
                        settingsSection
                        
                        // Logout Button
                        logoutButton
                        
                        // Version Info
                        versionInfo
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Settings")
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
        .sheet(isPresented: $showCategoryManagement) {
            CategoryManagementView()
        }
    }
      
    // MARK: - User Header
    private var userHeaderSection: some View {
        VStack(spacing: 0) {
            // Avatar with enhanced gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.6, green: 0.4, blue: 1.0),
                                Color(red: 0.8, green: 0.3, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 8)
                
                if let user = userSession.currentUser {
                    Text(getInitials(from: user))
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            // User Info
            VStack(spacing: 6) {
                if let user = userSession.currentUser {
                    Text(user.fullName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text(user.email)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Account")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "lock.fill",
                    title: "Change Password",
                    color: .orange,
                    iconBackground: Color.orange.opacity(0.15)
                ) {
                    // Handle change password
                }
                
                Divider()
                    .padding(.leading, 56)
            
                ProfileRow(
                    icon: "coloncurrencysign.circle.fill",
                    title: "Change Currency",
                    color: .green,
                    iconBackground: Color.green.opacity(0.15)
                ) {
                    // Handle change currency
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    color: .purple,
                    iconBackground: Color.purple.opacity(0.15)
                ) {
                    // Handle notifications
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Manage Data Section
    private var manageDataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manage Data")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "folder.fill",
                    title: "Categories",
                    color: .blue,
                    iconBackground: Color.blue.opacity(0.15)
                ) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showCategoryManagement = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "moon.fill",
                    title: "Appearance",
                    color: .indigo,
                    iconBackground: Color.indigo.opacity(0.15)
                ) {
                    // Handle appearance
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileRow(
                    icon: "info.circle.fill",
                    title: "About",
                    color: .gray,
                    iconBackground: Color.gray.opacity(0.15)
                ) {
                    // Handle about
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "arrow.right.square.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.red)
                }
                
                Text("Sign Out")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.red)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
    
    // MARK: - Version Info
    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text("Wallet-Watch App")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 8)
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
    var iconBackground: Color = Color.clear
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with circular background
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SettingView()
        .preferredColorScheme(.dark)
}