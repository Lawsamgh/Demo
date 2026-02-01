//
//  ActivityView.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct ActivityView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var expenses: [Expense] = []
    @State private var isLoadingExpenses = false
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var showAllActivityTransactions = false
    @State private var selectedCategoryDetailItem: CategoryDetailSheetItem?
    @State private var expenseToEdit: Expense?
    @State private var deleteError: String?
    @State private var showDeleteError = false
    
    private let maxTimelineRecords = 5
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    /// Resolve category by ID from FileMaker categories
    private func category(for categoryID: String) -> Category? {
        let normalized = categoryID.trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return nil }
        return userSession.categories.first { $0.id.trimmingCharacters(in: .whitespaces) == normalized }
    }
    
    // MARK: - Period date range
    private var periodStart: Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        switch selectedPeriod {
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        case .month:
            guard let monthStart = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) else { return startOfToday }
            return monthStart
        case .year:
            return calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? startOfToday
        }
    }
    
    private var periodEnd: Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        switch selectedPeriod {
        case .week:
            return calendar.date(byAdding: .day, value: 1, to: startOfToday)?.addingTimeInterval(-1) ?? now
        case .month:
            guard let monthStart = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)),
                  let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart),
                  let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else { return now }
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastDayOfMonth) ?? now
        case .year:
            guard let endOfYear = calendar.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) else { return now }
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfYear) ?? now
        }
    }
    
    /// Expenses within the selected period
    private var filteredExpenses: [Expense] {
        expenses.filter { $0.date >= periodStart && $0.date <= periodEnd }
    }
    
    private var totalIncome: Double {
        filteredExpenses.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        filteredExpenses.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var balance: Double {
        totalIncome - totalExpenses
    }
    
    /// Category breakdown for expenses (sorted by amount descending)
    private var categoryBreakdown: [(category: Category, amount: Double)] {
        let grouped = Dictionary(grouping: filteredExpenses.filter { $0.type == .expense }) { $0.categoryID }
        return grouped.compactMap { categoryID, expList -> (Category, Double)? in
            guard let cat = category(for: categoryID) else { return nil }
            return (cat, expList.reduce(0) { $0 + $1.amount })
        }.sorted { $0.1 > $1.1 }
    }
    
    /// All transactions in period, sorted by date (newest first)
    private var allTransactions: [Expense] {
        filteredExpenses.sorted { $0.sortDateForRecency > $1.sortDateForRecency }
    }
    
    /// Group transactions by date section (full list)
    private var groupedTransactions: [(section: String, items: [Expense])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        
        var sections: [(String, [Expense])] = []
        var currentSection: String = ""
        var currentItems: [Expense] = []
        
        for expense in allTransactions {
            let date = expense.sortDateForRecency
            let section: String
            if calendar.isDateInToday(date) {
                section = "Today"
            } else if calendar.isDateInYesterday(date) {
                section = "Yesterday"
            } else {
                section = formatter.string(from: date)
            }
            
            if section == currentSection {
                currentItems.append(expense)
            } else {
                if !currentItems.isEmpty {
                    sections.append((currentSection, currentItems))
                }
                currentSection = section
                currentItems = [expense]
            }
        }
        if !currentItems.isEmpty {
            sections.append((currentSection, currentItems))
        }
        return sections
    }
    
    /// Limited to max 5 transactions for timeline preview
    private var limitedGroupedTransactions: [(section: String, items: [Expense])] {
        let limited = Array(allTransactions.prefix(maxTimelineRecords))
        guard !limited.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        
        var sections: [(String, [Expense])] = []
        var currentSection: String = ""
        var currentItems: [Expense] = []
        
        for expense in limited {
            let date = expense.sortDateForRecency
            let section: String
            if calendar.isDateInToday(date) {
                section = "Today"
            } else if calendar.isDateInYesterday(date) {
                section = "Yesterday"
            } else {
                section = formatter.string(from: date)
            }
            
            if section == currentSection {
                currentItems.append(expense)
            } else {
                if !currentItems.isEmpty {
                    sections.append((currentSection, currentItems))
                }
                currentSection = section
                currentItems = [expense]
            }
        }
        if !currentItems.isEmpty {
            sections.append((currentSection, currentItems))
        }
        return sections
    }
    
    private var periodHeaderText: String {
        switch selectedPeriod {
        case .week: return "Last 7 days"
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            guard let d = Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) else { return "" }
            return "\(formatter.string(from: d)) \(selectedYear)"
        case .year: return "\(selectedYear)"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoadingExpenses && expenses.isEmpty {
                    activityLoadingSkeleton
                } else {
                    ScrollView(showsIndicators: true) {
                        VStack(spacing: 24) {
                            periodSelectorSection
                            summarySection
                            categoryBreakdownSection
                            transactionTimelineSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadExpenses()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var periodSelectorSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedPeriod = period
                            let now = Date()
                            let cal = Calendar.current
                            selectedYear = cal.component(.year, from: now)
                            selectedMonth = cal.component(.month, from: now)
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selectedPeriod == period ? .white : (colorScheme == .dark ? .secondary : .primary))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Group {
                                    if selectedPeriod == period {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color(.tertiarySystemGroupedBackground) : Color.white)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 8, x: 0, y: 2)
            )
            
            if selectedPeriod == .month || selectedPeriod == .year {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedPeriod == .month {
                                selectedMonth -= 1
                                if selectedMonth < 1 { selectedMonth = 12; selectedYear -= 1 }
                            } else {
                                selectedYear -= 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 36)
                    }
                    Spacer()
                    Text(periodHeaderText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedPeriod == .month {
                                selectedMonth += 1
                                if selectedMonth > 12 { selectedMonth = 1; selectedYear += 1 }
                            } else {
                                selectedYear += 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 36)
                    }
                }
            }
        }
    }
    
    private var summarySection: some View {
        HStack(alignment: .top, spacing: 12) {
            summaryCard(
                title: "Income",
                amount: totalIncome,
                color: Color.green
            )
            summaryCard(
                title: "Expenses",
                amount: totalExpenses,
                color: Color.red
            )
            summaryCard(
                title: "Balance",
                amount: balance,
                color: balance >= 0 ? .primary : Color.red
            )
        }
    }
    
    private func summaryCard(title: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text(UserSession.formatCurrency(amount: amount, currencyCode: userSession.currentUser?.currency))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 72)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
            
            if categoryBreakdown.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No expenses in this period")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            } else {
                VStack(spacing: 20) {
                    SpendingDonutChartView(
                        categoryBreakdown: categoryBreakdown,
                        totalExpenses: totalExpenses,
                        totalIncome: totalIncome,
                        currencyCode: userSession.currentUser?.currency,
                        colorFromString: colorFromString
                    )
                    .frame(height: 220)
                    .padding(.vertical, 8)
                    
                    VStack(spacing: 12) {
                        ForEach(categoryBreakdown, id: \.category.id) { item in
                            CategoryCard(
                                category: item.category,
                                amount: item.amount,
                                percentage: totalExpenses > 0 ? item.amount / totalExpenses : 0,
                                currencyCode: userSession.currentUser?.currency,
                                onTap: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    let catExpenses = filteredExpenses.filter {
                                        $0.type == .expense &&
                                        $0.categoryID.trimmingCharacters(in: .whitespaces) == item.category.id.trimmingCharacters(in: .whitespaces)
                                    }
                                    selectedCategoryDetailItem = CategoryDetailSheetItem(category: item.category, expenses: catExpenses)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var transactionTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transaction Timeline")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(allTransactions.count) transactions")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            if limitedGroupedTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No transactions in this period")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(limitedGroupedTransactions.enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.section)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 12) {
                                    ForEach(group.items) { expense in
                                        TransactionCard(
                                            expense: expense,
                                            category: category(for: expense.categoryID),
                                            currencyCode: userSession.currentUser?.currency
                                        )
                                        .contextMenu {
                                            Button {
                                                expenseToEdit = expense
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                Task { await deleteExpense(expense) }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if allTransactions.count > maxTimelineRecords {
                        Button {
                            showAllActivityTransactions = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("See All \(allTransactions.count) transactions")
                                    .font(.system(size: 15, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .sheet(isPresented: $showAllActivityTransactions) {
                    AllTransactionsView(
                        userSession: userSession,
                        transactions: allTransactions,
                        currencyCode: userSession.currentUser?.currency,
                        onDelete: { expense in await deleteExpense(expense) },
                        onEdit: { expense in
                            showAllActivityTransactions = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                expenseToEdit = expense
                            }
                        }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
                .sheet(item: $expenseToEdit) { expense in
                    AddExpenseView(
                        expenses: Binding(
                            get: { expenses },
                            set: { expenses = $0 }
                        ),
                        existingExpense: expense,
                        onSaveComplete: { Task { await loadExpenses() } }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
                .alert("Delete Error", isPresented: $showDeleteError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(deleteError ?? "Failed to delete transaction")
                }
                .sheet(item: $selectedCategoryDetailItem) { item in
                    CategoryExpensesDetailView(
                        userSession: userSession,
                        category: item.category,
                        expenses: item.expenses,
                        currencyCode: userSession.currentUser?.currency,
                        onDelete: { expense in await deleteExpense(expense) },
                        onEdit: { expense in
                            selectedCategoryDetailItem = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                expenseToEdit = expense
                            }
                        }
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private var activityLoadingSkeleton: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                ShimmerView(height: 80, cornerRadius: 16)
                    .frame(maxWidth: .infinity)
                ShimmerView(height: 80, cornerRadius: 16)
                    .frame(maxWidth: .infinity)
                ShimmerView(height: 80, cornerRadius: 16)
                    .frame(maxWidth: .infinity)
            }
            ForEach(0..<4, id: \.self) { _ in
                ShimmerView(height: 82, cornerRadius: 16)
            }
        }
        .padding(20)
    }
    
    // MARK: - Helpers
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
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
    
    // MARK: - Data Loading
    
    private func loadExpenses() async {
        guard let user = userSession.currentUser else { return }
        isLoadingExpenses = true
        do {
            let fetched = try await FileMakerService.shared.fetchExpenses(userID: user.userID)
            await MainActor.run { expenses = fetched }
        } catch {
            print("❌ Failed to load expenses for Activity: \(error.localizedDescription)")
        }
        isLoadingExpenses = false
    }
    
    private func deleteExpense(_ expense: Expense) async {
        deleteError = nil
        do {
            try await FileMakerService.shared.deleteExpense(recordId: expense.id)
            await loadExpenses()
        } catch {
            await MainActor.run {
                deleteError = error.localizedDescription
                showDeleteError = true
            }
        }
    }
}

private struct CategoryDetailSheetItem: Identifiable {
    var id: String { category.id }
    let category: Category
    let expenses: [Expense]
}

// MARK: - Spending Donut Chart
struct SpendingDonutChartView: View {
    let categoryBreakdown: [(category: Category, amount: Double)]
    let totalExpenses: Double
    let totalIncome: Double
    let currencyCode: String?
    let colorFromString: (String) -> Color
    
    @State private var animateChart = false
    @Environment(\.colorScheme) var colorScheme
    
    /// Chart total: sum of displayed categories (ensures donut segments fill 100%)
    private var chartTotal: Double {
        categoryBreakdown.reduce(0) { $0 + $1.amount }
    }
    
    /// Expense as percentage of income (e.g. 45 = 45% of income spent)
    private var expensePercentOfIncome: Double {
        guard totalIncome > 0 else { return 0 }
        return (totalExpenses / totalIncome) * 100
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 12, x: 0, y: 4)
            
            HStack(spacing: 24) {
                donutChart
                    .frame(width: 160, height: 160)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Spent")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(UserSession.formatCurrency(amount: totalExpenses, currencyCode: currencyCode))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    
                    if !categoryBreakdown.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(categoryBreakdown.prefix(4), id: \.category.id) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(colorFromString(item.category.displayColor))
                                        .frame(width: 8, height: 8)
                                    Text(item.category.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            if categoryBreakdown.count > 4 {
                                Text("+\(categoryBreakdown.count - 4) more")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 14)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.2)) {
                animateChart = true
            }
        }
    }
    
    private var donutChart: some View {
        ZStack {
            ForEach(Array(categoryBreakdown.enumerated()), id: \.element.category.id) { index, item in
                DonutSegment(
                    startFraction: startFraction(for: index),
                    endFraction: endFraction(for: index),
                    color: colorFromString(item.category.displayColor),
                    lineWidth: 22,
                    animate: animateChart
                )
            }
            
            Circle()
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(width: 96, height: 96)
            
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
                .frame(width: 96, height: 96)
            
            VStack(spacing: 2) {
                Text(formatCenterPercentage)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("of income spent")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 96, height: 96)
        }
        .frame(width: 160, height: 160)
    }
    
    private var formatCenterPercentage: String {
        if totalIncome <= 0 { return "—" }
        if expensePercentOfIncome >= 100 {
            return String(format: "%.0f%%", expensePercentOfIncome)
        }
        return String(format: "%.1f%%", expensePercentOfIncome)
    }
    
    private func percentageForItem(_ amount: Double) -> Double {
        guard chartTotal > 0 else { return 0 }
        return amount / chartTotal
    }
    
    private func startFraction(for index: Int) -> CGFloat {
        let preceding = categoryBreakdown.prefix(index).reduce(0.0) { $0 + percentageForItem($1.amount) }
        return CGFloat(preceding)
    }
    
    private func endFraction(for index: Int) -> CGFloat {
        let preceding = categoryBreakdown.prefix(index + 1).reduce(0.0) { $0 + percentageForItem($1.amount) }
        return CGFloat(preceding)
    }
}

struct DonutSegment: View {
    let startFraction: CGFloat
    let endFraction: CGFloat
    let color: Color
    let lineWidth: CGFloat
    let animate: Bool
    
    var body: some View {
        Circle()
            .trim(from: startFraction, to: animate ? endFraction : startFraction)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: 160, height: 160)
    }
}

#Preview {
    ActivityView()
}
