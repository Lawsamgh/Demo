//
//  SearchView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var userSession = UserSession.shared
    @State private var searchText: String = ""
    @State private var expenses: [Expense] = []
    @State private var isLoadingExpenses = false
    @State private var typeFilter: SearchTypeFilter = .all
    @State private var sortOption: SearchSortOption = .dateNewest
    @State private var showSortMenu = false
    
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
    
    /// Base filtered transactions (by search text only)
    private var baseFilteredTransactions: [Expense] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        
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
                    } else if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        searchEmptyPrompt
                    } else if baseFilteredTransactions.isEmpty {
                        searchNoResultsView
                    } else {
                        searchResultsContent
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search transactions...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !searchText.trimmingCharacters(in: .whitespaces).isEmpty && !baseFilteredTransactions.isEmpty {
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
        }
    }
    
    // MARK: - Subviews
    
    private var searchEmptyPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Search Transactions")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
            
            Text("Search by description or category name")
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
            Text("Summary of search results")
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
            Text("\(filteredTransactions.count) transaction\(filteredTransactions.count == 1 ? "" : "s") found")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
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
                                    TransactionCard(
                                        expense: expense,
                                        category: category(for: expense.categoryID),
                                        currencyCode: userSession.currentUser?.currency
                                    )
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
            print("❌ Failed to load expenses for search: \(error.localizedDescription)")
        }
        isLoadingExpenses = false
    }
}

#Preview {
    SearchView()
}
