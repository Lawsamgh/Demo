//
//  LoginView.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var userSession = UserSession.shared
    @State private var isOnboardingPresentingSheet = false
    @State private var startedInOnboarding = false
    @State private var hasCompletedOnboarding = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSignUp: Bool = false
    @FocusState private var focusedField: Field?
    @Environment(\.colorScheme) var colorScheme
    
    enum Field {
        case email, password
    }
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private var currencySet: Bool {
        !(userSession.currentUser?.currency ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }
    private var hasCategories: Bool {
        !userSession.categories.isEmpty
    }
    private var setupIncomplete: Bool {
        !currencySet || !hasCategories
    }
    private var shouldShowOnboarding: Bool {
        setupIncomplete || isOnboardingPresentingSheet || (startedInOnboarding && !hasCompletedOnboarding)
    }
    
    var body: some View {
        Group {
            if userSession.isLoggedIn {
                if shouldShowOnboarding {
                    OnboardingView(
                        onComplete: { hasCompletedOnboarding = true },
                        onUserInteraction: { startedInOnboarding = true },
                        isPresentingSheet: $isOnboardingPresentingSheet
                    )
                    .preferredColorScheme(userSession.preferredColorScheme)
                } else {
                    MainTabView()
                }
            } else if showSignUp {
                SignUpView(showSignUp: $showSignUp)
            } else {
                loginContent
                    .preferredColorScheme(.dark)
            }
        }
        .onChange(of: userSession.currentUser?.userID) { _, _ in
            startedInOnboarding = false
            hasCompletedOnboarding = false
        }
    }
    
    private var loginContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Native iOS background with adaptive colors
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacing
                        Spacer()
                            .frame(height: max(geometry.safeAreaInsets.top, 40))
                        
                        // Header Section
                        VStack(spacing: 16) {
                            // App Icon/Logo
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
                                
                                Image(systemName: "cedisign.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Wallet-Watch")
                                    .font(.system(size: 30, weight: .regular, design: .default))
                                    .foregroundStyle(.primary)
                                
                                Text("Sign in to continue")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.bottom, 44)
                        
                        // Form Card
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .textCase(.none)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(focusedField == .email ? .blue : .secondary)
                                        .frame(width: 20)
                                    
                                    TextField("", text: $email, prompt: Text("Enter your email").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                        .submitLabel(.next)
                                        .font(.system(size: 17))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    focusedField == .email ? Color.blue : Color(.separator),
                                                    lineWidth: focusedField == .email ? 2 : 0.5
                                                )
                                        )
                                )
                            }
                            .animation(.easeInOut(duration: 0.2), value: focusedField)
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .textCase(.none)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(focusedField == .password ? .blue : .secondary)
                                        .frame(width: 20)
                                    
                                    Group {
                                        if isPasswordVisible {
                                            TextField("", text: $password, prompt: Text("Enter your password").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                                .textContentType(.password)
                                                .autocapitalization(.none)
                                                .autocorrectionDisabled()
                                        } else {
                                            SecureField("", text: $password, prompt: Text("Enter your password").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                                .textContentType(.password)
                                        }
                                    }
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .font(.system(size: 17))
                                    
                                    Button(action: {
                                        hapticFeedback.impactOccurred(intensity: 0.7)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            isPasswordVisible.toggle()
                                        }
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 24, height: 24)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    focusedField == .password ? Color.blue : Color(.separator),
                                                    lineWidth: focusedField == .password ? 2 : 0.5
                                                )
                                        )
                                )
                            }
                            .animation(.easeInOut(duration: 0.2), value: focusedField)
                            
                            // Sign In Button
                            Button(action: {
                                handleLogin()
                            }) {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundStyle(.white)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .scaleEffect(isFormValid ? 1.0 : 0.98)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFormValid)
                            
                            // Sign Up Section
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                
                                Button(action: {
                                    hapticFeedback.impactOccurred(intensity: 0.6)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showSignUp = true
                                    }
                                }) {
                                    Text("Sign Up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                        
                        // Bottom spacing
                        Spacer()
                            .frame(height: max(geometry.safeAreaInsets.bottom, 40))
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                if isFormValid {
                    handleLogin()
                }
            case .none:
                break
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            hapticFeedback.prepare()
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleLogin() {
        // Dismiss keyboard
        focusedField = nil
        hapticFeedback.impactOccurred(intensity: 0.8)
        
        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            showErrorAlert = true
            hapticFeedback.impactOccurred(intensity: 1.0)
            return
        }
        
        // Validate password length
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showErrorAlert = true
            hapticFeedback.impactOccurred(intensity: 1.0)
            return
        }
        
        // Start login process
        isLoading = true
        
        // Call FileMaker API
        Task {
            do {
                print("🔄 Starting login attempt for: \(email)")
                let user = try await FileMakerService.shared.loginUser(email: email, password: password)
                
                await MainActor.run {
                    isLoading = false
                    hapticFeedback.impactOccurred(intensity: 0.5)
                    print("✅ Login successful for: \(user.fullName)")
                    
                    // Save user to session
                    userSession.login(user: user)
                    
                    // Reset fields
                    email = ""
                    password = ""
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    hapticFeedback.impactOccurred(intensity: 1.0)
                    let errorDesc = error.localizedDescription
                    print("❌ Login error: \(errorDesc)")
                    if let fmError = error as? FileMakerError {
                        print("   FileMaker Error Type: \(fmError)")
                    }
                    errorMessage = errorDesc
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoginView()
        .preferredColorScheme(.dark)
}
