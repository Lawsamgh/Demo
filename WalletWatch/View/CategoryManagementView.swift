//
//  CategoryManagementView.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct CategoryManagementView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showAddCategory = false
    @State private var categoryToEdit: Category?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if userSession.categories.isEmpty {
                    emptyStateView
                } else {
                    categoriesList
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showAddCategory = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                        }
                        Button {
                            Task {
                                await refreshCategories()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView(onSaved: {
                    showAddCategory = false
                })
            }
            .sheet(item: $categoryToEdit) { category in
                EditCategoryView(category: category, onSaved: {
                    categoryToEdit = nil
                })
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .task {
                if userSession.categories.isEmpty {
                    await refreshCategories()
                }
            }
        }
    }
    
    // MARK: - Categories List
    private var categoriesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(userSession.categories) { category in
                    Button {
                        categoryToEdit = category
                    } label: {
                        CategoryRowView(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Categories")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("Add a category to organize your expenses")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showAddCategory = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Category")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue)
                )
            }
            .padding(.top, 8)
            
            Button {
                Task { await refreshCategories() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Helper Functions
    private func refreshCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            await userSession.fetchCategories()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        
        isLoading = false
    }
}

// MARK: - Add Category View
struct AddCategoryView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.dismiss) var dismiss
    
    let onSaved: () -> Void
    
    @State private var categoryName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    private var canSave: Bool {
        let name = categoryName.trimmingCharacters(in: .whitespaces)
        return !name.isEmpty && !isSaving
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $categoryName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                } header: {
                    Text("Name")
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await saveCategory() }
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
    }
    
    private func saveCategory() async {
        let name = categoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await userSession.addCategory(name: name)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        
        isSaving = false
    }
}

// MARK: - Edit Category View
struct EditCategoryView: View {
    @StateObject private var userSession = UserSession.shared
    @Environment(\.dismiss) var dismiss
    
    let category: Category
    let onSaved: () -> Void
    
    @State private var categoryName: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    init(category: Category, onSaved: @escaping () -> Void) {
        self.category = category
        self.onSaved = onSaved
        _categoryName = State(initialValue: category.name)
    }
    
    private var canSave: Bool {
        let name = categoryName.trimmingCharacters(in: .whitespaces)
        return !name.isEmpty && !isSaving
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category name", text: $categoryName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                } header: {
                    Text("Name")
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await saveCategory() }
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
    }
    
    private func saveCategory() async {
        let name = categoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await userSession.updateCategory(recordId: category.id, name: name)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        
        isSaving = false
    }
}

// MARK: - Category Row View
struct CategoryRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let category: Category
    
    var body: some View {
        HStack(spacing: 14) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(colorFromString(category.displayColor).opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: category.displayIcon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(colorScheme == .dark ? colorFromString(category.displayColor) : .black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if let color = category.color {
                    Text("Color: \(color)")
                        .font(.system(size: 13))
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
    
    // MARK: - Helper Functions
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
}

#Preview {
    CategoryManagementView()
}
