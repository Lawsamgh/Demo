//
//  SettingView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

/// Common currencies for selection (code + display name)
private let themeOptions: [(value: String, name: String)] = [
    ("Light Mode", "Light Mode"),
    ("Dark Mode", "Dark Mode"),
]

private let currencyOptions: [(code: String, name: String)] = [
    ("USD", "US Dollar"),
    ("EUR", "Euro"),
    ("GBP", "British Pound"),
    ("GHS", "Ghanaian Cedi"),
    ("NGN", "Nigerian Naira"),
    ("XAF", "Central African CFA Franc"),
    ("XOF", "West African CFA Franc"),
    ("ZAR", "South African Rand"),
    ("KES", "Kenyan Shilling"),
    ("CAD", "Canadian Dollar"),
    ("AUD", "Australian Dollar"),
    ("JPY", "Japanese Yen"),
    ("CHF", "Swiss Franc"),
    ("CNY", "Chinese Yuan"),
]

struct SettingView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showLogoutAlert = false
    @State private var showCategoryManagement = false
    @State private var showCurrencySheet = false
    @State private var isSavingCurrency = false
    @State private var currencyError: String?
    @State private var showCurrencyError = false
    @State private var showThemeSheet = false
    @State private var isSavingTheme = false
    @State private var themeError: String?
    @State private var showThemeError = false
    @State private var showChangePasswordSheet = false
    @State private var passwordError: String?
    @State private var showPasswordError = false
    
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
        .sheet(isPresented: $showCurrencySheet) {
            CurrencyPickerSheet(
                currentCurrency: userSession.currentUser?.currency,
                isSaving: $isSavingCurrency,
                onSelect: { currency in
                    Task { await saveCurrency(currency) }
                },
                onDismiss: { showCurrencySheet = false }
            )
        }
        .alert("Currency Error", isPresented: $showCurrencyError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(currencyError ?? "Failed to save currency")
        }
        .sheet(isPresented: $showThemeSheet) {
            ThemePickerSheet(
                currentTheme: userSession.currentUser?.theme ?? "Light Mode",
                isSaving: $isSavingTheme,
                onSelect: { theme in Task { await saveTheme(theme) } },
                onDismiss: { showThemeSheet = false }
            )
        }
        .alert("Theme Error", isPresented: $showThemeError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(themeError ?? "Failed to save theme")
        }
        .sheet(isPresented: $showChangePasswordSheet) {
            if let user = userSession.currentUser {
                ChangePasswordSheet(
                    userEmail: user.email,
                    userID: user.userID,
                    onSuccess: { showChangePasswordSheet = false },
                    onError: { message in
                        passwordError = message
                        showPasswordError = true
                    }
                )
            }
        }
        .alert("Password", isPresented: $showPasswordError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(passwordError ?? "Failed to change password")
        }
    }
    
    private func saveTheme(_ theme: String) async {
        guard let user = userSession.currentUser else { return }
        isSavingTheme = true
        themeError = nil
        do {
            try await FileMakerService.shared.updateUserTheme(userID: user.userID, theme: theme)
            await MainActor.run {
                userSession.updateTheme(theme)
                showThemeSheet = false
            }
        } catch {
            await MainActor.run {
                themeError = error.localizedDescription
                showThemeError = true
            }
        }
        isSavingTheme = false
    }
    
    private func saveCurrency(_ currency: String) async {
        guard let user = userSession.currentUser else { return }
        isSavingCurrency = true
        currencyError = nil
        do {
            try await FileMakerService.shared.updateUserCurrency(userID: user.userID, currency: currency)
            await MainActor.run {
                userSession.updateCurrency(currency)
                showCurrencySheet = false
            }
        } catch {
            await MainActor.run {
                currencyError = error.localizedDescription
                showCurrencyError = true
            }
        }
        isSavingCurrency = false
    }
      
    // MARK: - User Header
    private var userHeaderSection: some View {
        HStack(spacing: 16) {
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
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.purple.opacity(0.25), radius: 12, x: 0, y: 4)
                
                if let user = userSession.currentUser {
                    Text(getInitials(from: user))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                if let user = userSession.currentUser {
                    Text(user.fullName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(user.email)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
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
                    showChangePasswordSheet = true
                }
                
                Divider()
                    .padding(.leading, 56)
            
                ProfileRow(
                    icon: "coloncurrencysign.circle.fill",
                    title: "Change Currency",
                    subtitle: userSession.currentUser?.currency ?? "Not set",
                    color: .green,
                    iconBackground: Color.green.opacity(0.15)
                ) {
                    showCurrencySheet = true
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
                    subtitle: (userSession.currentUser?.theme ?? "Light Mode").trimmingCharacters(in: .whitespaces).isEmpty ? "Light Mode" : (userSession.currentUser?.theme ?? "Light Mode"),
                    color: .indigo,
                    iconBackground: Color.indigo.opacity(0.15)
                ) {
                    showThemeSheet = true
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

// MARK: - Currency Picker Sheet
struct CurrencyPickerSheet: View {
    let currentCurrency: String?
    @Binding var isSaving: Bool
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(currencyOptions, id: \.code) { option in
                    Button {
                        onSelect(option.code)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.code)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(option.name)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if currentCurrency == option.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            if isSaving {
                                ProgressView()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Preferred Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    let userEmail: String
    let userID: String
    let onSuccess: () -> Void
    let onError: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var isCurrentPasswordVisible = false
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    private var canSave: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword &&
        newPassword != currentPassword
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Password")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                Group {
                                    if isCurrentPasswordVisible {
                                        TextField("Enter current password", text: $currentPassword)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Enter current password", text: $currentPassword)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    }
                                }
                                .font(.system(size: 17))
                                
                                Button {
                                    isCurrentPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isCurrentPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                            )
                        }
                        
                        // New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("At least 6 characters")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                            
                            HStack(spacing: 12) {
                                Group {
                                    if isNewPasswordVisible {
                                        TextField("Enter new password", text: $newPassword)
                                            .textContentType(.newPassword)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Enter new password", text: $newPassword)
                                            .textContentType(.newPassword)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    }
                                }
                                .font(.system(size: 17))
                                
                                Button {
                                    isNewPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isNewPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                            )
                        }
                        
                        // Confirm New Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                Group {
                                    if isConfirmPasswordVisible {
                                        TextField("Confirm new password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Confirm new password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    }
                                }
                                .font(.system(size: 17))
                                
                                Button {
                                    isConfirmPasswordVisible.toggle()
                                } label: {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                            )
                            
                            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        // Save Button
                        Button {
                            Task { await savePassword() }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Change Password")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(!canSave || isSaving)
                        .opacity(canSave && !isSaving ? 1 : 0.5)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func savePassword() async {
        guard canSave else { return }
        
        isSaving = true
        
        do {
            // Verify current password by attempting login
            _ = try await FileMakerService.shared.loginUser(email: userEmail, password: currentPassword)
            
            // Update to new password
            try await FileMakerService.shared.updateUserPassword(userID: userID, newPassword: newPassword)
            
            await MainActor.run {
                onSuccess()
                dismiss()
            }
        } catch FileMakerError.userNotFound, FileMakerError.invalidCredentials, FileMakerError.authenticationFailed {
            await MainActor.run {
                onError("Current password is incorrect")
            }
        } catch {
            await MainActor.run {
                onError(error.localizedDescription)
            }
        }
        
        isSaving = false
    }
}

// MARK: - Theme Picker Sheet
struct ThemePickerSheet: View {
    let currentTheme: String
    @Binding var isSaving: Bool
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    
    private var effectiveCurrentTheme: String {
        let t = currentTheme.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? "Light Mode" : t
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(themeOptions, id: \.value) { option in
                    Button {
                        onSelect(option.value)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.name)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            if effectiveCurrentTheme == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            if isSaving {
                                ProgressView()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Profile Row
struct ProfileRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                
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