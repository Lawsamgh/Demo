//
//  OnboardingView.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

private let primaryGradient = LinearGradient(
    colors: [Color(red: 0.26, green: 0.46, blue: 1.0), Color(red: 0.5, green: 0.35, blue: 0.95)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

private let onboardingCurrencyOptions: [(code: String, name: String)] = [
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

struct OnboardingView: View {
    let onComplete: () -> Void
    @Binding var isPresentingSheet: Bool
    @StateObject private var userSession = UserSession.shared
    
    @State private var currentPage = 0
    @State private var showAddExpense = false
    @State private var showAddCategory = false
    @State private var onboardingExpenses: [Expense] = []
    @State private var savingCurrencyCode: String?
    
    private var isCurrencySet: Bool {
        let c = userSession.currentUser?.currency ?? ""
        return !c.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var isCategoriesSet: Bool {
        !userSession.categories.isEmpty
    }
    
    private var canComplete: Bool {
        isCurrencySet && isCategoriesSet
    }
    
    private let introPages: [(icon: String, title: String, subtitle: String)] = [
        ("cedisign.circle.fill", "Welcome to WalletWatch", "Track your income and expenses in one place. Stay on top of your finances effortlessly."),
        ("chart.pie.fill", "See Where Your Money Goes", "View spending by category, trends over time, and insights that help you make smarter choices."),
        ("bell.badge.fill", "Stay on Track", "Set expense limits and get alerts when you're spending more than planned.")
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGroupedBackground), Color(.systemGroupedBackground).opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("\(currentPage + 1) of \(totalPageCount)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                TabView(selection: $currentPage) {
                    currencySelectionPage
                        .tag(0)
                    categorySelectionPage
                        .tag(1)
                    ForEach(0..<introPages.count, id: \.self) { index in
                        onboardingIntroPage(index: index)
                            .tag(index + 2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentPage)
                
                pageIndicator
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                
                bottomActions
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(onSaved: {
                showAddCategory = false
            })
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(expenses: $onboardingExpenses)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    onComplete()
                }
        }
        .onChange(of: showAddCategory) { _, _ in
            isPresentingSheet = showAddCategory || showAddExpense
        }
        .onChange(of: showAddExpense) { _, _ in
            isPresentingSheet = showAddCategory || showAddExpense
        }
    }
    
    private var currencySelectionPage: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(primaryGradient.opacity(0.2)).frame(width: 100, height: 100).blur(radius: 20)
                Circle().fill(primaryGradient).frame(width: 88, height: 88)
                    .shadow(color: Color.blue.opacity(0.35), radius: 16, x: 0, y: 8)
                Image(systemName: "coloncurrencysign.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 6) {
                Text("Choose Your Currency")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Required for displaying amounts throughout the app")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 20)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(onboardingCurrencyOptions, id: \.code) { option in
                        currencyOptionRow(option: option)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 240)
            Spacer()
        }
    }
    
    private func currencyOptionRow(option: (code: String, name: String)) -> some View {
        let isSelected = userSession.currentUser?.currency == option.code
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            saveCurrency(option.code)
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color(.tertiarySystemFill))
                    .frame(width: 44, height: 44)
                    .overlay(Text(option.code).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(isSelected ? .blue : .secondary))
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.code).font(.system(size: 17, weight: .semibold)).foregroundStyle(.primary)
                    Text(option.name).font(.system(size: 14)).foregroundStyle(.secondary)
                }
                Spacer()
                if savingCurrencyCode == option.code {
                    ProgressView()
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(savingCurrencyCode != nil)
    }
    
    private var categorySelectionPage: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(primaryGradient.opacity(0.2)).frame(width: 100, height: 100).blur(radius: 20)
                Circle().fill(primaryGradient).frame(width: 88, height: 88)
                    .shadow(color: Color.blue.opacity(0.35), radius: 16, x: 0, y: 8)
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 6) {
                Text("Add Your First Category")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("Required to organize your expenses")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 20)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(userSession.categories) { category in
                        categoryRow(category: category)
                    }
                    addCategoryButton
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 240)
            Spacer()
        }
        .task {
            await userSession.fetchCategories()
        }
    }
    
    private func categoryRow(category: Category) -> some View {
        let color = onboardingColor(from: category.displayColor)
        return HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: category.displayIcon).font(.system(size: 20, weight: .medium)).foregroundStyle(color))
            Text(category.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
    }
    
    private var addCategoryButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showAddCategory = true
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "plus").font(.system(size: 20, weight: .semibold)).foregroundStyle(.blue))
                Text("Add Category")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.blue)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.06))
                    RoundedRectangle(cornerRadius: 14).strokeBorder(Color.blue.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    private func onboardingColor(from name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        case "cyan": return .cyan
        case "mint": return .mint
        case "brown": return .brown
        default: return .gray
        }
    }
    
    private func onboardingIntroPage(index: Int) -> some View {
        let page = introPages[index]
        return VStack(spacing: 36) {
            Spacer()
            ZStack {
                Circle().fill(primaryGradient.opacity(0.25)).frame(width: 160, height: 160).blur(radius: 30)
                Circle().fill(primaryGradient).frame(width: 128, height: 128)
                    .shadow(color: Color.blue.opacity(0.4), radius: 24, x: 0, y: 12)
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 36)
            Spacer()
        }
    }
    
    private var totalPageCount: Int { 2 + introPages.count }
    
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
    }
    
    private var bottomActions: some View {
        VStack(spacing: 18) {
            if !canComplete {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill").font(.system(size: 14))
                    Text(mandatorySetupHint).font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            }
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showAddExpense = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22))
                    Text("Add your first expense").font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 16).fill(primaryGradient))
                .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .scaleEffect(canComplete ? 1 : 0.98)
            .disabled(!canComplete)
            .opacity(canComplete ? 1 : 0.6)
            .animation(.easeInOut(duration: 0.2), value: canComplete)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onComplete()
            } label: {
                Text("I'll do this later")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canComplete)
            .opacity(canComplete ? 1 : 0.6)
        }
    }
    
    private var mandatorySetupHint: String {
        if !isCurrencySet && !isCategoriesSet {
            return "Set your currency and add at least one category to continue"
        } else if !isCurrencySet {
            return "Select your currency above to continue"
        } else if !isCategoriesSet {
            return "Add at least one category to continue"
        } else {
            return ""
        }
    }
    
    private func saveCurrency(_ currency: String) {
        guard let user = userSession.currentUser else { return }
        savingCurrencyCode = currency
        Task {
            do {
                try await FileMakerService.shared.updateUserCurrency(userID: user.userID, currency: currency)
                await MainActor.run {
                    userSession.updateCurrency(currency)
                    savingCurrencyCode = nil
                }
            } catch {
                await MainActor.run {
                    savingCurrencyCode = nil
                    print("❌ Failed to save currency: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {}, isPresentingSheet: .constant(false))
        .preferredColorScheme(.light)
}
