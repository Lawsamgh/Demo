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
    @State private var expenses: [Expense] = sampleExpenses
    @State private var selectedPeriod: TimePeriod = .month
    @State private var showAddExpense = false
    @State private var scrollOffset: CGFloat = 0
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
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
    
    private var categoryBreakdown: [(category: ExpenseCategory, amount: Double)] {
        let grouped = Dictionary(grouping: expenses.filter { $0.type == .expense }) { $0.category }
        return grouped.map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
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
                        // Animated Header
                        headerSection
                            .padding(.top, 8)
                        
                        // Hero Balance Card
                        heroBalanceCard
                            .padding(.horizontal, 20)
                        
                        // Spending Chart Preview
                        spendingPreview
                            .padding(.horizontal, 20)
                        
                        // Transactions List
                        transactionsSection
                            .padding(.horizontal, 20)
                        
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
        }
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
                
                Text(formatCurrency(balance))
                    .font(.system(size: 40, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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
                    Text(formatCurrency(totalIncome))
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
                    Text(formatCurrency(totalExpenses))
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
                ForEach(Array(categoryBreakdown.prefix(3).enumerated()), id: \.element.category) { index, item in
                    CategoryCard(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.amount / totalExpenses
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
    
    // MARK: - Spending Preview
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
            SpendingChartView()
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
                    TransactionCard(expense: expense)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func getInitials(from user: User) -> String {
        let firstInitial = user.firstName.prefix(1).uppercased()
        let lastInitial = user.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}

// MARK: - Spending Chart View
struct SpendingChartView: View {
    @State private var animateChart = false
    @State private var selectedBar: Int? = 6
    @Environment(\.colorScheme) var colorScheme
    
    let barHeights: [CGFloat] = [60, 85, 45, 95, 70, 110, 130]
    let amounts: [Double] = [120, 180, 90, 200, 150, 240, 280]
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Area
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 6) {
                        // Bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: selectedBar == index ? 
                                        [.blue, .purple] : 
                                        [colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray4), 
                                         colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: animateChart ? barHeights[index] : 0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: animateChart ? barHeights[index] : 0)
                            )
                            .shadow(
                                color: selectedBar == index ? 
                                    Color.blue.opacity(0.3) : 
                                    Color.black.opacity(0.05),
                                radius: selectedBar == index ? 8 : 2,
                                x: 0,
                                y: 4
                            )
                            .scaleEffect(selectedBar == index ? 1.05 : 1.0, anchor: .bottom)
                        
                        // Day label
                        Text(days[index].prefix(1))
                            .font(.system(size: 12, weight: selectedBar == index ? .bold : .medium))
                            .foregroundStyle(selectedBar == index ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedBar = index
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
                        Text(days[selectedBar ?? 6])
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
                    Text("$\(Int(amounts[selectedBar ?? 6]))")
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
                    Text("$180")
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
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateChart = true
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: ExpenseCategory
    let amount: Double
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(category.color).opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: category.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(category.color))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(formatCurrency(amount))
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
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Transaction Card
struct TransactionCard: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(expense.category.color).opacity(0.15))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: expense.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(expense.category.color))
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
            
            Text((expense.type == .income ? "+" : "-") + formatCurrency(expense.amount))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(expense.type == .income ? .green : .primary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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

// MARK: - Sample Data
let sampleExpenses: [Expense] = [
    Expense(title: "Monthly Salary", amount: 5000, category: .salary, date: Date().addingTimeInterval(-86400 * 5), type: .income),
    Expense(title: "Whole Foods", amount: 150, category: .food, date: Date().addingTimeInterval(-86400 * 1), type: .expense),
    Expense(title: "Uber to Office", amount: 25, category: .transport, date: Date().addingTimeInterval(-86400 * 2), type: .expense),
    Expense(title: "Netflix", amount: 15, category: .entertainment, date: Date().addingTimeInterval(-86400 * 3), type: .expense),
    Expense(title: "Electricity", amount: 120, category: .bills, date: Date().addingTimeInterval(-86400 * 4), type: .expense),
    Expense(title: "Starbucks", amount: 5, category: .food, date: Date().addingTimeInterval(-3600 * 2), type: .expense),
    Expense(title: "Gym", amount: 50, category: .health, date: Date().addingTimeInterval(-86400 * 7), type: .expense),
    Expense(title: "Online Course", amount: 30, category: .education, date: Date().addingTimeInterval(-86400 * 6), type: .expense),
    Expense(title: "Freelance", amount: 800, category: .salary, date: Date().addingTimeInterval(-86400 * 3), type: .income),
    Expense(title: "Dinner", amount: 45, category: .food, date: Date().addingTimeInterval(-3600 * 5), type: .expense)
]

// MARK: - Add Expense View
struct AddExpenseView: View {
    @Binding var expenses: [Expense]
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var selectedType: ExpenseType = .expense
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background for better visibility in light mode
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
                                Text("$")
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
                        
                        // Title Input
                        VStack(spacing: 12) {
                            Text("Description")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("What did you spend on?", text: $title)
                                .font(.system(size: 16))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        // Category Selection
                        VStack(spacing: 12) {
                            Text("Category")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = category
                                        }
                                    } label: {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedCategory == category ? Color.white.opacity(0.25) : Color(category.color).opacity(0.15))
                                                    .frame(width: 44, height: 44)
                                                
                                                Image(systemName: category.icon)
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundStyle(selectedCategory == category ? .white : Color(category.color))
                                            }
                                            
                                            Text(category.rawValue)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(selectedCategory == category ? Color(category.color) : (colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(selectedCategory == category ? Color.clear : (colorScheme == .dark ? Color.clear : Color(.systemGray4)), lineWidth: 1.5)
                                        )
                                        .shadow(color: selectedCategory == category ? Color(category.color).opacity(0.3) : Color.black.opacity(0.05), radius: selectedCategory == category ? 8 : 2, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Date Picker
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
                            if let amountValue = Double(amount), !title.isEmpty {
                                let newExpense = Expense(
                                    title: title,
                                    amount: amountValue,
                                    category: selectedCategory,
                                    date: selectedDate,
                                    type: selectedType
                                )
                                expenses.append(newExpense)
                                dismiss()
                            }
                        } label: {
                            Text("Add Transaction")
                                .font(.system(size: 17, weight: .semibold))
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
                        .disabled(title.isEmpty || amount.isEmpty)
                        .opacity(title.isEmpty || amount.isEmpty ? 0.5 : 1)
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
        }
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
