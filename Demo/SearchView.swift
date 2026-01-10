//
//  SearchView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search items...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                    
                    if searchText.isEmpty {
                        emptyState
                    } else {
                        searchResults
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("Start searching")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("Enter keywords to find what you're looking for")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResults: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<5) { index in
                    SearchResultRow(index: index)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct SearchResultRow: View {
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.blue)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Item \(index + 1)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Description of item \(index + 1)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    SearchView()
}
