//
//  SignUpView.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct SignUpView: View {
    @Binding var showSignUp: Bool
    @StateObject private var userSession = UserSession.shared
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var isLoading: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var focusedField: Field?
    @Environment(\.colorScheme) var colorScheme
    
    enum Field {
        case firstName, lastName, email, password, confirmPassword
    }
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
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
                        VStack(spacing: 0) {
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
                                    .frame(width: 70, height: 70)
                                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Create Account")
                                    .font(.system(size: 30, weight: .bold, design: .default))
                                    .foregroundStyle(.primary)
                                
                                Text("Sign up to get started")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.bottom, 20)
                        
                        // Form Card
                        VStack(spacing: 10) {
                            // First Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .textCase(.none)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(focusedField == .firstName ? .blue : .secondary)
                                        .frame(width: 20)
                                    
                                    TextField("Enter your first name", text: $firstName, prompt: Text("Enter your first name").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                        .textContentType(.givenName)
                                        .autocapitalization(.words)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .firstName)
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
                                                    focusedField == .firstName ? Color.blue : Color(.separator),
                                                    lineWidth: focusedField == .firstName ? 2 : 0.5
                                                )
                                        )
                                )
                            }
                            .animation(.easeInOut(duration: 0.2), value: focusedField)
                            
                            // Last Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .textCase(.none)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(focusedField == .lastName ? .blue : .secondary)
                                        .frame(width: 20)
                                    
                                    TextField("Enter your last name", text: $lastName, prompt: Text("Enter your last name").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                        .textContentType(.familyName)
                                        .autocapitalization(.words)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .lastName)
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
                                                    focusedField == .lastName ? Color.blue : Color(.separator),
                                                    lineWidth: focusedField == .lastName ? 2 : 0.5
                                                )
                                        )
                                )
                            }
                            .animation(.easeInOut(duration: 0.2), value: focusedField)
                            
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
                                    
                                    TextField("Enter your email", text: $email, prompt: Text("Enter your email").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
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
                                            TextField("Enter your password", text: $password, prompt: Text("Enter your password").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                                .textContentType(.newPassword)
                                                .autocapitalization(.none)
                                                .autocorrectionDisabled()
                                        } else {
                                            SecureField("Enter your password", text: $password, prompt: Text("Enter your password").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                                .textContentType(.newPassword)
                                        }
                                    }
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.next)
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
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .textCase(.none)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(focusedField == .confirmPassword ? .blue : .secondary)
                                        .frame(width: 20)
                                    
                                    Group {
                                        if isConfirmPasswordVisible {
                                            TextField("Confirm your password", text: $confirmPassword, prompt: Text("Confirm your password").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                                .textContentType(.newPassword)
                                                .autocapitalization(.none)
                                                .autocorrectionDisabled()
                                        } else {
                                            SecureField("Confirm your password", text: $confirmPassword, prompt: Text("Confirm your password").foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)))
                                                .textContentType(.newPassword)
                                        }
                                    }
                                    .focused($focusedField, equals: .confirmPassword)
                                    .submitLabel(.go)
                                    .font(.system(size: 17))
                                    
                                    Button(action: {
                                        hapticFeedback.impactOccurred(intensity: 0.7)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            isConfirmPasswordVisible.toggle()
                                        }
                                    }) {
                                        Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
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
                                                    focusedField == .confirmPassword ? Color.blue : Color(.separator),
                                                    lineWidth: focusedField == .confirmPassword ? 2 : 0.5
                                                )
                                        )
                                )
                            }
                            .animation(.easeInOut(duration: 0.2), value: focusedField)
                            
                            // Sign Up Button
                            Button(action: {
                                handleSignUp()
                            }) {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign Up")
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
                            
                            // Sign In Link
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                
                                Button(action: {
                                    hapticFeedback.impactOccurred(intensity: 0.6)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showSignUp = false
                                    }
                                }) {
                                    Text("Sign In")
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
            case .firstName:
                focusedField = .lastName
            case .lastName:
                focusedField = .email
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if isFormValid {
                    handleSignUp()
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
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        isValidEmail(email) && 
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleSignUp() {
        // Dismiss keyboard
        focusedField = nil
        hapticFeedback.impactOccurred(intensity: 0.8)
        
        // Validate first name
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your first name"
            showErrorAlert = true
            hapticFeedback.impactOccurred(intensity: 1.0)
            return
        }
        
        // Validate last name
        guard !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your last name"
            showErrorAlert = true
            hapticFeedback.impactOccurred(intensity: 1.0)
            return
        }
        
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
        
        // Validate password match
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showErrorAlert = true
            hapticFeedback.impactOccurred(intensity: 1.0)
            return
        }
        
        // Start sign up process
        isLoading = true
        
        // Call FileMaker API to create user
        Task {
            do {
                print("🔄 Starting sign up for: \(email)")
                let success = try await FileMakerService.shared.createUser(
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                
                await MainActor.run {
                    if success {
                        hapticFeedback.impactOccurred(intensity: 0.5)
                        print("✅ Sign up successful for email: \(email)")
                        // Auto-login so new user sees onboarding
                        let signUpEmail = email.trimmingCharacters(in: .whitespaces)
                        let signUpPassword = password
                        firstName = ""
                        lastName = ""
                        email = ""
                        password = ""
                        confirmPassword = ""
                        Task {
                            do {
                                let user = try await FileMakerService.shared.loginUser(email: signUpEmail, password: signUpPassword)
                                await MainActor.run {
                                    userSession.login(user: user)
                                    isLoading = false
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        showSignUp = false
                                    }
                                }
                            } catch {
                                await MainActor.run {
                                    isLoading = false
                                    print("⚠️ Auto-login after sign up failed: \(error.localizedDescription)")
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        showSignUp = false
                                    }
                                }
                            }
                        }
                    } else {
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    hapticFeedback.impactOccurred(intensity: 1.0)
                    let errorDesc = error.localizedDescription
                    print("❌ Sign up error: \(errorDesc)")
                    errorMessage = errorDesc
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    SignUpView(showSignUp: .constant(true))
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SignUpView(showSignUp: .constant(true))
        .preferredColorScheme(.dark)
}
