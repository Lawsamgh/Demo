//
//  HomeView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var expenses: [Expense] = sampleExpenses
    @State private var selectedPeriod: TimePeriod = .month
    @State private var showAddExpense = false
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // Computed properties for financial summary
    private var totalIncome: Double {
        expenses.filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        expenses.filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var balance: Double {
        totalIncome - totalExpenses
    }
    
    private var recentTransactions: [Expense] {
        expenses.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
    
    private var categoryBreakdown: [(category: ExpenseCategory, amount: Double)] {
        let grouped = Dictionary(grouping: expenses.filter { $0.type == .expense }) { $0.category }
        return grouped.map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Welcome Header
                        welcomeHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        
                        // Balance Card
                        balanceCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        
                        // Income/Expense Stats
                        incomeExpenseStats
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        
                        // Category Breakdown
                        categoryBreakdownSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        
                        // Recent Transactions
                        recentTransactionsSection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showAddExpense = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(expenses: $expenses)
            }
        }
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                if let user = userSession.currentUser {
                    Text("Welcome Back,")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("\(user.firstName)!")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.primary)
                } else {
                    Text("Welcome Back!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                }
                
                Text("Here's your financial overview")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            // User Avatar
            if let user = userSession.currentUser {
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
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Text(getInitials(from: user))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Balance Card
    private var balanceCard: some View {
        VStack(spacing: 0) {
            // Header with Period Selector
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Balance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(formatCurrency(balance))
                        .font(.system(size: 42, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Period Selector
                Menu {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button(period.rawValue) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPeriod = period
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedPeriod.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.2))
                    )
                }
            }
            .padding(.bottom, 14)
            
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue,
                            Color.purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Income/Expense Stats
    private var incomeExpenseStats: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Income",
                amount: totalIncome,
                icon: "arrow.down.circle.fill",
                color: .green,
                gradient: [Color.green.opacity(0.15), Color.green.opacity(0.05)]
            )
            
            StatCard(
                title: "Expenses",
                amount: totalExpenses,
                icon: "arrow.up.circle.fill",
                color: .red,
                gradient: [Color.red.opacity(0.15), Color.red.opacity(0.05)]
            )
        }
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Categories")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    // Handle view all
                } label: {
                    Text("View All")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            
            VStack(spacing: 10) {
                ForEach(Array(categoryBreakdown.prefix(5).enumerated()), id: \.element.category) { index, item in
                    CategoryRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: item.amount / totalExpenses,
                        rank: index + 1
                    )
                }
            }
        }
    }
    
    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    // Handle see all
                } label: {
                    Text("See All")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            
            VStack(spacing: 0) {
                ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, expense in
                    TransactionRow(expense: expense)
                    
                    if index < recentTransactions.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
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

// MARK: - Quick Stat View
struct QuickStatView: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCurrency(amount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(formatCurrency(amount))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
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

// MARK: - Category Row
struct CategoryRow: View {
    let category: ExpenseCategory
    let amount: Double
    let percentage: Double
    let rank: Int
    
    var body: some View {
        HStack(spacing: 14) {
            // Rank Badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(category.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(category.color))
            }
            
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color(category.color).opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(category.color))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(category.color))
                            .frame(width: geometry.size.width * min(percentage, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            Spacer()
            
            Text(formatCurrency(amount))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
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
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 14) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color(expense.category.color).opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: expense.category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color(expense.category.color))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(expense.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Text(expense.category.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    Text(formatDate(expense.date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(expense.amount))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(expense.type == .income ? .green : .red)
                
                if expense.type == .income {
                    Text("Income")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.green.opacity(0.7))
                }
            }
        }
        .padding(16)
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
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

// MARK: - Sample Data
let sampleExpenses: [Expense] = [
    Expense(title: "Salary", amount: 5000, category: .salary, date: Date().addingTimeInterval(-86400 * 5), type: .income),
    Expense(title: "Grocery Shopping", amount: 150, category: .food, date: Date().addingTimeInterval(-86400 * 1), type: .expense),
    Expense(title: "Uber Ride", amount: 25, category: .transport, date: Date().addingTimeInterval(-86400 * 2), type: .expense),
    Expense(title: "Netflix Subscription", amount: 15, category: .entertainment, date: Date().addingTimeInterval(-86400 * 3), type: .expense),
    Expense(title: "Electric Bill", amount: 120, category: .bills, date: Date().addingTimeInterval(-86400 * 4), type: .expense),
    Expense(title: "Coffee", amount: 5, category: .food, date: Date().addingTimeInterval(-3600 * 2), type: .expense),
    Expense(title: "Gym Membership", amount: 50, category: .health, date: Date().addingTimeInterval(-86400 * 7), type: .expense),
    Expense(title: "Book Purchase", amount: 30, category: .education, date: Date().addingTimeInterval(-86400 * 6), type: .expense),
    Expense(title: "Freelance Work", amount: 800, category: .salary, date: Date().addingTimeInterval(-86400 * 3), type: .income),
    Expense(title: "Restaurant", amount: 45, category: .food, date: Date().addingTimeInterval(-3600 * 5), type: .expense)
]

// MARK: - Add Expense View (Placeholder)
struct AddExpenseView: View {
    @Binding var expenses: [Expense]
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: ExpenseCategory = .food
    @State private var selectedType: ExpenseType = .expense
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section("Type") {
                    Picker("Type", selection: $selectedType) {
                        Text("Income").tag(ExpenseType.income)
                        Text("Expense").tag(ExpenseType.expense)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let amountValue = Double(amount), !title.isEmpty {
                            let newExpense = Expense(
                                title: title,
                                amount: amountValue,
                                category: selectedCategory,
                                date: Date(),
                                type: selectedType
                            )
                            expenses.append(newExpense)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
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
