//
//  TransactionView.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct TransactionView: View {
    @StateObject private var userSession = UserSession.shared
    @State private var searchText: String = ""
    @State private var expenses: [Expense] = []
    @State private var isLoadingExpenses = false
    @State private var typeFilter: SearchTypeFilter = .all
    @State private var sortOption: SearchSortOption = .dateNewest
    @State private var showSortMenu = false
    @State private var expenseToEdit: Expense?
    @State private var expenseToShowDetail: Expense?
    @State private var deleteError: String?
    @State private var showDeleteError = false
    
    enum SearchTypeFilter: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expense = "Expense"
    }
    
    enum SearchSortOption: String, CaseIterable {
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
        case amountHigh = "Amount: High → Low"
        case amountLow = "Amount: Low → High"
    }
    
    /// Resolve category by ID from FileMaker categories
    private func category(for categoryID: String) -> Category? {
        let normalized = categoryID.trimmingCharacters(in: .whitespaces)
        guard !normalized.isEmpty else { return nil }
        return userSession.categories.first { $0.id.trimmingCharacters(in: .whitespaces) == normalized }
    }
    
    /// Base filtered transactions (all transactions when search is empty, filtered by search text when searching)
    private var baseFilteredTransactions: [Expense] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        
        if query.isEmpty {
            return expenses
        }
        
        return expenses.filter { expense in
            let titleMatch = expense.title.lowercased().contains(query)
            let categoryMatch = category(for: expense.categoryID)?.name.lowercased().contains(query) ?? false
            return titleMatch || categoryMatch
        }
    }
    
    /// Apply type filter and sort to base filtered transactions
    private var filteredTransactions: [Expense] {
        var result = baseFilteredTransactions
        
        switch typeFilter {
        case .all: break
        case .income: result = result.filter { $0.type == .income }
        case .expense: result = result.filter { $0.type == .expense }
        }
        
        switch sortOption {
        case .dateNewest: result.sort { $0.sortDateForRecency > $1.sortDateForRecency }
        case .dateOldest: result.sort { $0.sortDateForRecency < $1.sortDateForRecency }
        case .amountHigh: result.sort { $0.amount > $1.amount }
        case .amountLow: result.sort { $0.amount < $1.amount }
        }
        
        return result
    }
    
    /// Totals for search results (uses full search results, not type-filtered list)
    private var searchResultIncome: Double {
        baseFilteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var searchResultExpenses: Double {
        baseFilteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var searchResultBalance: Double {
        searchResultIncome - searchResultExpenses
    }
    
    /// Group transactions by date section (Today, Yesterday, This Week, etc.)
    private var groupedTransactions: [(section: String, items: [Expense])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var sections: [(String, [Expense])] = []
        var currentSection: String = ""
        var currentItems: [Expense] = []
        
        for expense in filteredTransactions {
            let date = expense.sortDateForRecency
            let section: String
            if calendar.isDateInToday(date) {
                section = "Today"
            } else if calendar.isDateInYesterday(date) {
                section = "Yesterday"
            } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
                section = "This Week"
            } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
                section = "This Month"
            } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
                section = "This Year"
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                Group {
                    if isLoadingExpenses && expenses.isEmpty {
                        searchLoadingSkeleton
                    } else if expenses.isEmpty {
                        emptyTransactionsView
                    } else if baseFilteredTransactions.isEmpty {
                        searchNoResultsView
                    } else {
                        searchResultsContent
                    }
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search transactions...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !baseFilteredTransactions.isEmpty {
                        Menu {
                            ForEach(SearchSortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .font(.system(size: 22))
                        }
                    }
                }
            }
            .task {
                await loadExpenses()
            }
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseView(
                    expenses: Binding(get: { expenses }, set: { expenses = $0 }),
                    existingExpense: expense,
                    onSaveComplete: { Task { await loadExpenses() } }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $expenseToShowDetail) { expense in
                TransactionDetailView(
                    expense: expense,
                    category: category(for: expense.categoryID),
                    currencyCode: userSession.currentUser?.currency,
                    onEdit: {
                        expenseToShowDetail = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { expenseToEdit = expense }
                    },
                    onDismiss: { expenseToShowDetail = nil }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .alert("Delete Error", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteError ?? "Failed to delete transaction")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyTransactionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Transactions")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
            
            Text("Your transactions will appear here")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchNoResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("No Results Found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("Try a different search term or filter")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchLoadingSkeleton: some View {
        VStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var searchResultsContent: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 20) {
                // Summary card
                searchSummaryCard
                
                // Type filter
                typeFilterPicker
                
                // Result count
                resultCountLabel
                
                // Grouped transaction list
                searchResultsList
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
    }
    
    private var noResultsMessageForTypeFilter: String {
        switch typeFilter {
        case .all: return "No transactions match"
        case .income: return "No income in these results"
        case .expense: return "No expenses in these results"
        }
    }
    
    private var hasIncomeInResults: Bool {
        baseFilteredTransactions.contains { $0.type == .income }
    }
    
    private var searchSummaryCard: some View {
        VStack(spacing: 8) {
            Text(searchText.trimmingCharacters(in: .whitespaces).isEmpty ? "Summary" : "Summary of search results")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                if hasIncomeInResults {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(UserSession.formatCurrency(amount: searchResultIncome, currencyCode: userSession.currentUser?.currency))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expenses")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(UserSession.formatCurrency(amount: searchResultExpenses, currencyCode: userSession.currentUser?.currency))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if hasIncomeInResults {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(UserSession.formatCurrency(amount: searchResultBalance, currencyCode: userSession.currentUser?.currency))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(searchResultBalance >= 0 ? Color.primary : Color.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    private var typeFilterPicker: some View {
        HStack(spacing: 0) {
            ForEach(SearchTypeFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        typeFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(typeFilter == filter ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            typeFilter == filter ?
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue) :
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
    
    private var resultCountLabel: some View {
        HStack {
            if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("\(filteredTransactions.count) transaction\(filteredTransactions.count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                Text("\(filteredTransactions.count) transaction\(filteredTransactions.count == 1 ? "" : "s") found")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        Group {
            if filteredTransactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: typeFilter == .income ? "arrow.down.circle" : "arrow.up.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(noResultsMessageForTypeFilter)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(groupedTransactions.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.section)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                ForEach(group.items) { expense in
                                    Button {
                                        expenseToShowDetail = expense
                                    } label: {
                                        TransactionCard(
                                            expense: expense,
                                            category: category(for: expense.categoryID),
                                            currencyCode: userSession.currentUser?.currency
                                        )
                                    }
                                    .buttonStyle(.plain)
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
            }
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
            print("❌ Failed to load expenses for transactions: \(error.localizedDescription)")
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

// MARK: - Transaction Detail (tap to show)
struct TransactionDetailView: View {
    let expense: Expense
    let category: Category?
    let currencyCode: String?
    var onEdit: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    private var amountColor: Color {
        expense.type == .income ? .green : .red
    }
    
    private var categoryColor: Color {
        colorFromString(category?.displayColor ?? "gray")
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
    
    private func colorFromString(_ name: String) -> Color {
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(categoryColor.opacity(0.2))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: category?.displayIcon ?? Category.iconForName(expense.title))
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(categoryColor)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)
                            if let cat = category {
                                Text(cat.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    
                    Text((expense.type == .income ? "+" : "-") + UserSession.formatCurrency(amount: expense.amount, currencyCode: currencyCode))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(amountColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        detailRow(label: "Type", value: expense.type.rawValue)
                        detailRow(label: "Category", value: category?.name ?? "—")
                        detailRow(label: "Date", value: formatDate(expense.date))
                        if let pm = expense.paymentMethod, !pm.trimmingCharacters(in: .whitespaces).isEmpty {
                            detailRow(label: "Payment", value: pm)
                        }
                        if let notes = expense.notes, !notes.trimmingCharacters(in: .whitespaces).isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Text(notes)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.tertiarySystemGroupedBackground))
                            )
                        }
                    }
                    
                    if onEdit != nil {
                        Button {
                            onEdit?()
                        } label: {
                            Label("Edit Transaction", systemImage: "pencil")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss?()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onDisappear { onDismiss?() }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    TransactionView()
}
