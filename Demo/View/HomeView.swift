//
//  HomeView.swift
//  Demo
//
//  Redesigned with Premium iOS Design
//

import SwiftUI

struct HomeView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var expenses: [Expense] = []
    @State private var isLoadingExpenses = false
    @State private var selectedPeriod: TimePeriod = .month
    @State private var showAddExpense = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showCurrencySheet = false
    @State private var isSavingCurrency = false
    @State private var currencyError: String?
    @State private var showCurrencyError = false
    
    private var isCurrencyNotSet: Bool {
        let c = userSession.currentUser?.currency ?? ""
        return c.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // Resolve category by ID from FileMaker categories
    private func category(for categoryID: String) -> Category? {
        userSession.categories.first { $0.id == categoryID }
    }
    
    // Computed properties
    private var totalIncome: Double {
        expenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        expenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var balance: Double {
        totalIncome - totalExpenses
    }
    
    private var recentTransactions: [Expense] {
        expenses.sorted { $0.date > $1.date }.prefix(6).map { $0 }
    }
    
    private var categoryBreakdown: [(category: Category, amount: Double)] {
        let grouped = Dictionary(grouping: expenses.filter { $0.type == .expense }) { $0.categoryID }
        return grouped.compactMap { categoryID, expList -> (Category, Double)? in
            guard let cat = category(for: categoryID) else { return nil }
            return (cat, expList.reduce(0) { $0 + $1.amount })
        }.sorted { $0.1 > $1.1 }
    }
    
    /// Spending Trend: last 7 days from Expenses table (fields Date, Amount, Type).
    /// Uses fetched `expenses` (FileMaker Expenses layout). One entry per day; day 0 = oldest, day 6 = today.
    /// Only records with Type == expense are summed per day.
    private var last7DaysSpending: [(dayLabel: String, amount: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, ...
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: -6 + offset, to: today) else {
                return (formatter.string(from: today), 0.0)
            }
            let dayTotal = expenses
                .filter { $0.type == .expense && calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0.0) { $0 + $1.amount }
            return (formatter.string(from: day), dayTotal)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Background
                LinearGradient(
                    colors: colorScheme == .dark ? 
                        [Color.black, Color.black] :
                        [Color(.systemGroupedBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Currency prompt when not set
                        if isCurrencyNotSet {
                            currencyPromptBanner
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }
                        
                        // Animated Header
                        headerSection
                            .padding(.top, 8)
                        
                        // Hero Balance Card (skeleton when loading)
                        if isLoadingExpenses {
                            heroBalanceCardSkeleton
                                .padding(.horizontal, 20)
                        } else {
                            heroBalanceCard
                                .padding(.horizontal, 20)
                        }
                        
                        // Spending Chart Preview (skeleton when loading)
                        if isLoadingExpenses {
                            spendingPreviewSkeleton
                                .padding(.horizontal, 20)
                        } else {
                            spendingPreview
                                .padding(.horizontal, 20)
                        }
                        
                        // Transactions List (skeleton when loading)
                        if isLoadingExpenses {
                            transactionsSectionSkeleton
                                .padding(.horizontal, 20)
                        } else {
                            transactionsSection
                                .padding(.horizontal, 20)
                        }
                        
                        // Bottom Spacing
                        Color.clear.frame(height: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button {
                            // Notifications
                        } label: {
                            Image(systemName: "bell")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showAddExpense = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(expenses: $expenses)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCurrencySheet) {
                CurrencyPickerSheet(
                    currentCurrency: userSession.currentUser?.currency,
                    isSaving: $isSavingCurrency,
                    onSelect: { currency in Task { await saveCurrency(currency) } },
                    onDismiss: { showCurrencySheet = false }
                )
            }
            .alert("Currency Error", isPresented: $showCurrencyError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(currencyError ?? "Failed to save currency")
            }
            .task {
                await loadExpenses()
            }
        }
    }
    
    // MARK: - Currency Prompt (when not set)
    private var currencyPromptBanner: some View {
        Button {
            showCurrencySheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "coloncurrencysign.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set your preferred currency")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Tap to choose currency for amounts and display")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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
    
    // MARK: - Modern Loading (shimmer)
    private var heroBalanceCardSkeleton: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                ShimmerView(height: 72, cornerRadius: 20)
                    .frame(maxWidth: .infinity)
                ShimmerView(height: 72, cornerRadius: 20)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var spendingPreviewSkeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ShimmerView(width: 120, height: 16, cornerRadius: 6)
                Spacer()
                ShimmerView(width: 70, height: 14, cornerRadius: 6)
            }
            ShimmerView(height: 220, cornerRadius: 20)
        }
    }
    
    private var transactionsSectionSkeleton: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ShimmerView(width: 160, height: 16, cornerRadius: 6)
                Spacer()
                ShimmerView(width: 60, height: 14, cornerRadius: 6)
            }
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 14) {
                        ShimmerView(width: 46, height: 46, cornerRadius: 23)
                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerView(width: 140, height: 14, cornerRadius: 6)
                            ShimmerView(width: 80, height: 12, cornerRadius: 6)
                        }
                        Spacer()
                        ShimmerView(width: 70, height: 16, cornerRadius: 6)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
            }
        }
    }
    
    private func loadExpenses() async {
        guard let user = userSession.currentUser else { return }
        isLoadingExpenses = true
        do {
            let fetched = try await FileMakerService.shared.fetchExpenses(userID: user.userID)
            await MainActor.run { expenses = fetched }
        } catch {
            print("❌ Failed to load expenses: \(error.localizedDescription)")
        }
        isLoadingExpenses = false
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Greeting and Date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let user = userSession.currentUser {
                        Text("Good morning,")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Text("\(user.firstName)! 👋")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Welcome Back! 👋")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
                
                // Current Month and Year
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentMonth)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(currentYear)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Enhanced Period Toggle
            HStack(spacing: 0) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedPeriod == period ? .white : (colorScheme == .dark ? .secondary : .primary))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    if selectedPeriod == period {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: .blue.opacity(0.4), radius: 6, x: 0, y: 2)
                                            .matchedGeometryEffect(id: "period", in: namespace)
                                    }
                                }
                            )
                    }
                }
            }
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color(.tertiarySystemGroupedBackground) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.08), radius: 8, x: 0, y: 2)
            )
            .overlay(
                Capsule()
                    .stroke(colorScheme == .dark ? Color.clear : Color(.systemGray5), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            
            // Balance Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Balance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                if isLoadingExpenses {
                    ShimmerView(width: 160, height: 44, cornerRadius: 10)
                } else {
                    Text(UserSession.formatCurrency(amount: balance, currencyCode: userSession.currentUser?.currency))
                        .font(.system(size: 40, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Current month and year computed properties
    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    @Namespace private var namespace
    
    // MARK: - Hero Balance Card
    private var heroBalanceCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                        Text("Income")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(UserSession.formatCurrency(amount: totalIncome, currencyCode: userSession.currentUser?.currency))
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.red)
                        Text("Expenses")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(UserSession.formatCurrency(amount: totalExpenses, currencyCode: userSession.currentUser?.currency))
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
    }
    
    // MARK: - Stats Overview
    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Categories")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                ForEach(Array(categoryBreakdown.prefix(3).enumerated()), id: \.element.category.id) { index, item in
                    CategoryCard(
                        category: item.category,
                        amount: item.amount,
                        percentage: totalExpenses > 0 ? item.amount / totalExpenses : 0,
                        currencyCode: userSession.currentUser?.currency
                    )
                }
            }
            
            if categoryBreakdown.count > 3 {
                Button {
                    // View all categories
                } label: {
                    HStack {
                        Text("View all categories")
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.blue)
                    .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Spending Preview (data from Expenses: Date, Amount, Type)
    private var spendingPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Spending Trend")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("Last 7 days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            // Animated Bar Chart
            SpendingChartView(dailyData: last7DaysSpending, currencyCode: userSession.currentUser?.currency)
        }
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    // View all
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.blue)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(recentTransactions) { expense in
                    TransactionCard(expense: expense, category: category(for: expense.categoryID), currencyCode: userSession.currentUser?.currency)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getInitials(from user: User) -> String {
        let firstInitial = user.firstName.prefix(1).uppercased()
        let lastInitial = user.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}

// MARK: - Spending Chart View (fed by Expenses table: Date, Amount, Type via last7DaysSpending)
struct SpendingChartView: View {
    /// dailyData: last 7 days (dayLabel, amount) from Expenses table—Date, Amount, Type (expense only)
    let dailyData: [(dayLabel: String, amount: Double)]
    let currencyCode: String?
    @State private var animateChart = false
    @State private var selectedBar: Int = 6
    @Environment(\.colorScheme) var colorScheme
    
    private static let maxBarHeight: CGFloat = 130
    private static let minBarHeight: CGFloat = 10
    private var amounts: [Double] { dailyData.map(\.amount) }
    private var dayLabels: [String] { dailyData.map(\.dayLabel) }
    
    private var barHeights: [CGFloat] {
        let maxAmount = amounts.max() ?? 0
        if maxAmount > 0 {
            return amounts.map { amount in
                let h = CGFloat(amount / maxAmount) * Self.maxBarHeight
                return max(h, Self.minBarHeight)
            }
        }
        return amounts.map { _ in Self.minBarHeight }
    }
    
    private var dailyAverage: Double {
        let total = amounts.reduce(0, +)
        return amounts.isEmpty ? 0 : total / Double(amounts.count)
    }
    
    private var safeSelectedIndex: Int {
        let i = min(max(0, selectedBar), dayLabels.count - 1)
        return dayLabels.isEmpty ? 0 : i
    }
    
    var body: some View {
        let count = dayLabels.count
        let indices = count > 0 ? (0..<count).map { $0 } : (0..<7).map { _ in 0 }
        
        VStack(spacing: 16) {
            // Chart Area
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(indices.enumerated()), id: \.offset) { index, _ in
                    let i = index
                    VStack(spacing: 6) {
                        // Bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: selectedBar == i ? 
                                        [.blue, .purple] : 
                                        [colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4), 
                                         colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: animateChart ? (i < barHeights.count ? barHeights[i] : 0) : 0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: animateChart ? (i < barHeights.count ? barHeights[i] : 0) : 0)
                            )
                            .shadow(
                                color: selectedBar == i ? 
                                    Color.blue.opacity(0.3) : 
                                    Color.black.opacity(0.05),
                                radius: selectedBar == i ? 8 : 2,
                                x: 0,
                                y: 4
                            )
                            .scaleEffect(selectedBar == i ? 1.05 : 1.0, anchor: .bottom)
                        
                        // Day label
                        Text(i < dayLabels.count ? String(dayLabels[i].prefix(1)) : "")
                            .font(.system(size: 12, weight: selectedBar == i ? .bold : .medium))
                            .foregroundStyle(selectedBar == i ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedBar = i
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, x: 0, y: 4)
            )
            
            // Summary Stats with Selected Day Info
            HStack(spacing: 16) {
                // Selected Day Card
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(safeSelectedIndex < dayLabels.count ? dayLabels[safeSelectedIndex] : "")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.blue)
                    }
                    Text(UserSession.formatCurrency(amount: safeSelectedIndex < amounts.count ? amounts[safeSelectedIndex] : 0, currencyCode: currencyCode))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Avg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(UserSession.formatCurrency(amount: dailyAverage, currencyCode: currencyCode))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            }
        }
        .onAppear {
            selectedBar = dayLabels.count > 0 ? dayLabels.count - 1 : 0
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateChart = true
            }
        }
        .onChange(of: dailyData.map(\.amount)) { _, _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateChart = true
            }
        }
        .onChange(of: dailyData.count) { _, newCount in
            if newCount > 0, selectedBar >= newCount {
                selectedBar = newCount - 1
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    @Environment(\.colorScheme) var colorScheme
    let category: Category
    let amount: Double
    let percentage: Double
    let currencyCode: String?
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(category.displayColor).opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: category.displayIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? Color(category.displayColor) : .black)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(UserSession.formatCurrency(amount: amount, currencyCode: currencyCode))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Transaction Card
struct TransactionCard: View {
    @Environment(\.colorScheme) var colorScheme
    let expense: Expense
    let category: Category?
    let currencyCode: String?
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(category?.displayColor ?? "gray").opacity(0.15))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: category?.displayIcon ?? "ellipsis.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? Color(category?.displayColor ?? "gray") : .black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(formatDate(expense.date))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text((expense.type == .income ? "+" : "-") + UserSession.formatCurrency(amount: expense.amount, currencyCode: currencyCode))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(expense.type == .income ? .green : .primary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Modern Shimmer Loading (iPhone-style)
struct ShimmerView: View {
    @Environment(\.colorScheme) var colorScheme
    var width: CGFloat? = nil
    var height: CGFloat = 12
    var cornerRadius: CGFloat = 8
    
    private var baseColor: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray5)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(baseColor)
            .frame(width: width, height: height)
            .overlay(
                TimelineView(.animation(minimumInterval: 0.016)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let cycle: TimeInterval = 1.4
                    let p = CGFloat((t.truncatingRemainder(dividingBy: cycle)) / cycle)
                    GeometryReader { geo in
                        let w = geo.size.width
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(colorScheme == .dark ? 0.18 : 0.4),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: w * 0.5)
                            .offset(x: -w * 0.5 + p * (w + w * 0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            )
    }
}

// MARK: - Add Expense View
struct AddExpenseView: View {
    @Binding var expenses: [Expense]
    @StateObject private var userSession = UserSession.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var descriptionText = ""
    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var selectedType: ExpenseType = .expense
    @State private var selectedDate = Date()
    @State private var paymentMethod = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Amount Input
                        VStack(spacing: 12) {
                            Text("Amount")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 8) {
                                Text(UserSession.currencySymbol(for: userSession.currentUser?.currency))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                
                                TextField("0", text: $amount)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.bottom, 8)
                            
                            Divider()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Type Selector
                        VStack(spacing: 12) {
                            Text("Type")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Picker("Type", selection: $selectedType) {
                                Text("Expense").tag(ExpenseType.expense)
                                Text("Income").tag(ExpenseType.income)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 20)
                        
                        // Description Input (FileMaker: Description)
                        VStack(spacing: 12) {
                            Text("Description")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("What did you spend on?", text: $descriptionText)
                                .font(.system(size: 16))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Category Selection (from FileMaker Category table) — list layout for visibility
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 4)
                            
                            if userSession.categories.isEmpty {
                                Text("No categories. Add categories in Settings.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemGray6))
                                    )
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(userSession.categories.enumerated()), id: \.element.id) { index, category in
                                        let isSelected = selectedCategory?.id == category.id
                                        Button {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedCategory = category
                                            }
                                        } label: {
                                            HStack(spacing: 14) {
                                                // Colored icon circle — high contrast so icon is always visible
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(category.displayColor).opacity(isSelected ? 0.9 : 0.22))
                                                        .frame(width: 44, height: 44)
                                                    Circle()
                                                        .stroke(Color(category.displayColor).opacity(isSelected ? 0 : 0.4), lineWidth: 1.5)
                                                        .frame(width: 44, height: 44)
                                                    Image(systemName: category.displayIcon)
                                                        .font(.system(size: 20, weight: .semibold))
                                                        .foregroundStyle(colorScheme == .light ? .black : (isSelected ? .white : .primary))
                                                }
                                                
                                                // Category name — primary text for strong contrast
                                                Text(category.name)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                // Checkmark at right end when selected
                                                if isSelected {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundStyle(.green)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(
                                                Rectangle()
                                                    .fill(isSelected ? Color(category.displayColor).opacity(0.12) : (colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white))
                                            )
                                            .overlay(
                                                Rectangle()
                                                    .frame(width: 4)
                                                    .foregroundStyle(isSelected ? Color(category.displayColor) : Color.clear),
                                                alignment: .leading
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        
                                        if index < userSession.categories.count - 1 {
                                            Divider()
                                                .padding(.leading, 74)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Payment Method (FileMaker: PaymentMethod)
                        VStack(spacing: 12) {
                            Text("Payment Method")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("e.g. Cash, Card", text: $paymentMethod)
                                .font(.system(size: 16))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Date Picker (FileMaker: Date)
                        VStack(spacing: 12) {
                            Text("Date")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button {
                            Task { await saveTransaction() }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Add Transaction")
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
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(!canSave || isSaving)
                        .opacity(!canSave || isSaving ? 0.5 : 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
            }
            .onAppear {
                if selectedCategory == nil, let first = userSession.categories.first {
                    selectedCategory = first
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
    }
    
    private var canSave: Bool {
        guard let amountValue = Double(amount), amountValue > 0,
              !descriptionText.trimmingCharacters(in: .whitespaces).isEmpty,
              selectedCategory != nil else { return false }
        return true
    }
    
    private func saveTransaction() async {
        guard let user = userSession.currentUser,
              let category = selectedCategory,
              let amountValue = Double(amount), amountValue > 0 else { return }
        
        let desc = descriptionText.trimmingCharacters(in: .whitespaces)
        let payment = paymentMethod.trimmingCharacters(in: .whitespaces).isEmpty ? "Other" : paymentMethod.trimmingCharacters(in: .whitespaces)
        
        isSaving = true
        errorMessage = nil
        
        do {
            let recordId = try await FileMakerService.shared.createExpense(
                userID: user.userID,
                date: selectedDate,
                amount: amountValue,
                categoryID: category.id,
                paymentMethod: payment,
                description: desc,
                type: selectedType
            )
            let newExpense = Expense(
                id: recordId,
                title: desc,
                amount: amountValue,
                categoryID: category.id,
                date: selectedDate,
                type: selectedType,
                paymentMethod: payment,
                notes: nil
            )
            await MainActor.run {
                expenses.append(newExpense)
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
        isSaving = false
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    HomeView()
        .preferredColorScheme(.dark)
}
