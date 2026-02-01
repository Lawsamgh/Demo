//
//  SettingView.swift
//  WalletWatch
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
    @State private var showExpenseLimitSheet = false
    @State private var isSavingExpenseLimit = false
    @State private var expenseLimitError: String?
    @State private var showExpenseLimitError = false
    @State private var showPayDaySheet = false
    @State private var isSavingPayDay = false
    @State private var payDayError: String?
    @State private var showPayDayError = false
    @State private var showAbout = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    @State private var showDeleteAccountError = false
    
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
                        
                        // Delete Account
                        deleteAccountButton
                        
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
        .sheet(isPresented: $showExpenseLimitSheet) {
            if let user = userSession.currentUser {
                ExpenseLimitSheet(
                    currentType: user.expenseLimitType ?? "percentage",
                    currentValue: user.expenseLimitValue ?? 80,
                    currentPeriod: user.expenseLimitPeriod ?? "month",
                    currencyCode: user.currency,
                    isSaving: $isSavingExpenseLimit,
                    onSave: { type, value, period in
                        Task { await saveExpenseLimit(type: type, value: value, period: period) }
                    },
                    onDismiss: { showExpenseLimitSheet = false }
                )
            }
        }
        .alert("Expense Limit Error", isPresented: $showExpenseLimitError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(expenseLimitError ?? "Failed to save expense limit")
        }
        .sheet(isPresented: $showPayDaySheet) {
            PayDayPickerSheet(
                currentPayDay: userSession.currentUser?.payDay,
                isSaving: $isSavingPayDay,
                onSave: { payDay in
                    Task { await savePayDay(payDay) }
                },
                onDismiss: { showPayDaySheet = false }
            )
        }
        .alert("Pay Day Error", isPresented: $showPayDayError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(payDayError ?? "Failed to save pay day")
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Account", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("Are you sure you want to permanently delete your account? All your expenses, categories, and data will be removed. This cannot be undone.")
        }
        .alert("Delete Account Error", isPresented: $showDeleteAccountError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteAccountError ?? "Failed to delete account")
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Text("Deleting account...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .allowsHitTesting(!isDeletingAccount)
    }
    
    private func deleteAccount() async {
        guard let _ = userSession.currentUser else { return }
        isDeletingAccount = true
        deleteAccountError = nil
        do {
            try await userSession.deleteAccount()
        } catch {
            await MainActor.run {
                deleteAccountError = error.localizedDescription
                showDeleteAccountError = true
            }
        }
        isDeletingAccount = false
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
    
    private func saveExpenseLimit(type: String, value: Double, period: String) async {
        guard let user = userSession.currentUser else { return }
        isSavingExpenseLimit = true
        expenseLimitError = nil
        do {
            try await FileMakerService.shared.updateUserExpenseLimit(userID: user.userID, type: type, value: value, period: period)
            await MainActor.run {
                userSession.updateExpenseLimit(type: type, value: value, period: period)
                showExpenseLimitSheet = false
            }
        } catch {
            await MainActor.run {
                expenseLimitError = error.localizedDescription
                showExpenseLimitError = true
            }
        }
        isSavingExpenseLimit = false
    }
    
    private func savePayDay(_ payDay: Int?) async {
        guard let user = userSession.currentUser else { return }
        isSavingPayDay = true
        payDayError = nil
        do {
            try await FileMakerService.shared.updateUserPayDay(userID: user.userID, payDay: payDay)
            await MainActor.run {
                userSession.updatePayDay(payDay)
                showPayDaySheet = false
            }
        } catch {
            await MainActor.run {
                payDayError = error.localizedDescription
                showPayDayError = true
            }
        }
        isSavingPayDay = false
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
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(user.email)
                        .font(.system(size: 14))
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
                .font(.system(size: 15, weight: .semibold))
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
                .font(.system(size: 15, weight: .semibold))
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
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Expense Limit",
                    subtitle: expenseLimitSubtitle,
                    color: .orange,
                    iconBackground: Color.orange.opacity(0.15)
                ) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showExpenseLimitSheet = true
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileRow(
                    icon: "calendar.badge.clock",
                    title: "Pay Day",
                    subtitle: payDaySubtitle,
                    color: .purple,
                    iconBackground: Color.purple.opacity(0.15)
                ) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showPayDaySheet = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    private var payDaySubtitle: String {
        guard let payDay = userSession.currentUser?.payDay else {
            return "Calendar month (1st - 31st)"
        }
        return "\(ordinalString(payDay)) of each month"
    }
    
    private func ordinalString(_ day: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: day)) ?? "\(day)"
    }
    
    private var expenseLimitSubtitle: String {
        guard let user = userSession.currentUser,
              let type = user.expenseLimitType,
              let value = user.expenseLimitValue,
              let period = user.expenseLimitPeriod,
              value > 0 else {
            return "Not set"
        }
        let periodLabel = period == "week" ? "weekly" : (period == "month" ? "monthly" : "yearly")
        if type == "percentage" {
            return "\(Int(value))% of income (\(periodLabel))"
        } else {
            return "\(UserSession.formatCurrency(amount: value, currencyCode: user.currency)) (\(periodLabel))"
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settings")
                .font(.system(size: 15, weight: .semibold))
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
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
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
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showAbout = true
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
    
    // MARK: - Delete Account Button
    private var deleteAccountButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            showDeleteAccountAlert = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 18))
                        .foregroundStyle(.orange)
                }
                
                Text("Delete Account")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.orange)
                
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

// MARK: - Theme Picker Sheet (iPhone Settings-style)
struct ThemePickerSheet: View {
    let currentTheme: String
    @Binding var isSaving: Bool
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var effectiveCurrentTheme: String {
        let t = currentTheme.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? "Light Mode" : t
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("Choose how WalletWatch looks. Light mode uses a light background; Dark mode uses a dark background.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // Theme selection cards (iOS Display & Brightness style)
                        VStack(spacing: 16) {
                            ForEach(themeOptions, id: \.value) { option in
                                ThemeOptionCard(
                                    title: option.name,
                                    icon: option.value == "Light Mode" ? "sun.max.fill" : "moon.fill",
                                    isSelected: effectiveCurrentTheme == option.value,
                                    isLightPreview: option.value == "Light Mode",
                                    isLoading: isSaving
                                ) {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    onSelect(option.value)
                                }
                                .disabled(isSaving)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
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
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .primaryAction) {
                    if isSaving {
                        ProgressView()
                    }
                }
            }
        }
    }
}

private struct ThemeOptionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let isLightPreview: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Preview panel (mini appearance sample)
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLightPreview ? Color.white : Color(red: 0.11, green: 0.11, blue: 0.12))
                    .frame(width: 72, height: 96)
                    .overlay(
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isLightPreview ? Color.gray.opacity(0.3) : Color.gray.opacity(0.5))
                                .frame(height: 8)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isLightPreview ? Color.gray.opacity(0.2) : Color.gray.opacity(0.4))
                                .frame(height: 6)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isLightPreview ? Color.gray.opacity(0.2) : Color.gray.opacity(0.4))
                                .frame(height: 6)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isLightPreview ? Color.gray.opacity(0.3) : Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(isLightPreview ? .orange : .indigo)
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    Text(isLightPreview ? "Light background with dark text" : "Dark background with light text")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected && !isLoading {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expense Limit Sheet
struct ExpenseLimitSheet: View {
    let currentType: String
    let currentValue: Double
    let currentPeriod: String
    let currencyCode: String?
    @Binding var isSaving: Bool
    let onSave: (String, Double, String) -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var limitType: String
    @State private var percentageValue: Double
    @State private var amountValue: String
    @State private var period: String
    
    init(currentType: String, currentValue: Double, currentPeriod: String, currencyCode: String?, isSaving: Binding<Bool>, onSave: @escaping (String, Double, String) -> Void, onDismiss: @escaping () -> Void) {
        self.currentType = currentType
        self.currentValue = currentValue
        self.currentPeriod = currentPeriod
        self.currencyCode = currencyCode
        self._isSaving = isSaving
        self.onSave = onSave
        self.onDismiss = onDismiss
        _limitType = State(initialValue: currentType == "amount" ? "amount" : "percentage")
        _percentageValue = State(initialValue: currentType == "amount" ? 80 : currentValue)
        _amountValue = State(initialValue: currentType == "amount" ? String(format: "%.2f", currentValue) : "")
        _period = State(initialValue: currentPeriod)
    }
    
    private var canSave: Bool {
        if limitType == "percentage" {
            return percentageValue >= 10 && percentageValue <= 100
        } else {
            guard let val = Double(amountValue), val > 0 else { return false }
            return true
        }
    }
    
    private var effectiveValue: Double {
        if limitType == "percentage" { return percentageValue }
        return Double(amountValue) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Limit Type")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            Picker("Limit Type", selection: $limitType) {
                                Text("Percentage of income").tag("percentage")
                                Text("Fixed amount").tag("amount")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        if limitType == "percentage" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Alert when spending exceeds")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Slider(value: $percentageValue, in: 10...100, step: 5)
                                    Text("\(Int(percentageValue))%")
                                        .font(.system(size: 17, weight: .semibold))
                                        .frame(width: 50, alignment: .trailing)
                                }
                                Text("You'll be notified when expenses exceed this % of your income")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Maximum expense amount")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text(UserSession.currencySymbol(for: currencyCode))
                                        .font(.system(size: 17))
                                        .foregroundStyle(.secondary)
                                    TextField("0.00", text: $amountValue)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 17))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                                )
                                Text("You'll be notified when expenses exceed this amount")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Period")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            Picker("Period", selection: $period) {
                                Text("Week").tag("week")
                                Text("Month").tag("month")
                                Text("Year").tag("year")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Button {
                            onSave(limitType, effectiveValue, period)
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save")
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
                        .opacity(canSave && !isSaving ? 1 : 0.6)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Expense Limit")
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

// MARK: - Pay Day Picker Sheet
struct PayDayPickerSheet: View {
    let currentPayDay: Int?
    @Binding var isSaving: Bool
    let onSave: (Int?) -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedPayDay: Int?
    @State private var useCalendarMonth: Bool
    
    init(currentPayDay: Int?, isSaving: Binding<Bool>, onSave: @escaping (Int?) -> Void, onDismiss: @escaping () -> Void) {
        self.currentPayDay = currentPayDay
        self._isSaving = isSaving
        self.onSave = onSave
        self.onDismiss = onDismiss
        _selectedPayDay = State(initialValue: currentPayDay ?? 1)
        _useCalendarMonth = State(initialValue: currentPayDay == nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Explanation
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.blue)
                                Text("What is Pay Day?")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            Text("Set the day of the month you typically receive your salary. Activity reports will then show spending cycles from your pay day to the next, instead of using calendar months (1st to 31st).")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.08))
                        )
                        
                        // Toggle for calendar month vs custom pay day
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $useCalendarMonth) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use Calendar Month")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.primary)
                                    Text("Reports run from 1st to end of month")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.blue)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                        )
                        
                        // Pay day picker (only visible if not using calendar month)
                        if !useCalendarMonth {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Your Pay Day")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                Picker("Pay Day", selection: $selectedPayDay) {
                                    ForEach(1...28, id: \.self) { day in
                                        Text(ordinalString(day)).tag(Optional(day))
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 150)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.orange)
                                    Text("Days 29-31 are not available to ensure consistency across all months.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Preview
                        if !useCalendarMonth, let day = selectedPayDay {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.purple)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Your spending cycle")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.primary)
                                        Text("\(ordinalString(day)) → \(ordinalString(day == 1 ? 28 : day - 1)) of next month")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.08))
                            )
                            .transition(.opacity)
                        }
                        
                        // Save Button
                        Button {
                            let payDayToSave = useCalendarMonth ? nil : selectedPayDay
                            onSave(payDayToSave)
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save")
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
                        .disabled(isSaving)
                        .opacity(isSaving ? 0.6 : 1)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Pay Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: useCalendarMonth)
        }
    }
    
    private func ordinalString(_ day: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: day)) ?? "\(day)"
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
    
    private var buildNumber: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
    }
    
    /// Acknowledgement entry: icon (SF Symbol), name, detail, optional URL.
    struct AcknowledgementItem {
        let icon: String
        let name: String
        let detail: String
        let url: String?
    }
    
    static let acknowledgements: [AcknowledgementItem] = [
        AcknowledgementItem(
            icon: "server.rack",
            name: "FileMaker",
            detail: "Backend database, API, and authentication",
            url: "https://www.claris.com/filemaker/"
        ),
        AcknowledgementItem(
            icon: "swift",
            name: "SwiftUI",
            detail: "Declarative UI framework by Apple",
            url: "https://developer.apple.com/xcode/swiftui/"
        ),
        AcknowledgementItem(
            icon: "link",
            name: "Combine",
            detail: "Reactive programming framework by Apple",
            url: "https://developer.apple.com/documentation/combine"
        ),
        AcknowledgementItem(
            icon: "apple.logo",
            name: "Apple",
            detail: "iOS, Xcode, and system frameworks",
            url: nil
        ),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App header
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                                Color(red: 0.6, green: 0.4, blue: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            }
                            Text("WalletWatch")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        
                        // Developer & company
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Developer & Company")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                AboutRow(label: "Developer", value: "Lawsam")
                                Divider().padding(.leading, 16)
                                AboutRow(label: "Company", value: "U&I Tech Solution")
                                Divider().padding(.leading, 16)
                                AboutRow(label: "Contact", value: "uanditech.solution@gmail.com", isLink: true)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                        }
                        
                        // Acknowledgements
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                Text("Acknowledgements")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 4)
                            
                            Text("Built with these technologies and services. Thank you to the developers and communities behind them.")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(AboutView.acknowledgements.enumerated()), id: \.offset) { index, item in
                                    if index > 0 {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                    AcknowledgementRow(
                                        icon: item.icon,
                                        name: item.name,
                                        detail: item.detail,
                                        url: item.url
                                    )
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                            )
                        }
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AboutRow: View {
    let label: String
    let value: String
    var isLink: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            if isLink {
                Link(value, destination: URL(string: "mailto:\(value)")!)
                    .font(.system(size: 15))
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            } else {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct AcknowledgementRow: View {
    let icon: String
    let name: String
    let detail: String
    var url: String? = nil
    
    var body: some View {
        Group {
            if let urlString = url, let linkURL = URL(string: urlString) {
                Link(destination: linkURL) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private var rowContent: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if url != nil {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
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
