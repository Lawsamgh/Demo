//
//  ActivityView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct ActivityView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Overview
                        statsOverview
                        
                        // Recent Activity List
                        recentActivityList
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }
    
    private var statsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCardMini(
                    title: "Today",
                    value: "12",
                    icon: "sun.max.fill",
                    color: .orange
                )
                
                StatCardMini(
                    title: "This Week",
                    value: "89",
                    icon: "calendar",
                    color: .blue
                )
                
                StatCardMini(
                    title: "This Month",
                    value: "324",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                StatCardMini(
                    title: "Total",
                    value: "1,234",
                    icon: "star.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var recentActivityList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 0) {
                ForEach(activityItems, id: \.id) { item in
                    ActivityListItem(item: item)
                    
                    if item.id != activityItems.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    private let activityItems = [
        ActivityItem(id: 1, icon: "checkmark.circle.fill", title: "Item completed", subtitle: "2 minutes ago", color: .green),
        ActivityItem(id: 2, icon: "person.circle.fill", title: "New user registered", subtitle: "1 hour ago", color: .blue),
        ActivityItem(id: 3, icon: "pencil.circle.fill", title: "Item updated", subtitle: "3 hours ago", color: .orange),
        ActivityItem(id: 4, icon: "trash.circle.fill", title: "Item deleted", subtitle: "5 hours ago", color: .red),
        ActivityItem(id: 5, icon: "plus.circle.fill", title: "New item created", subtitle: "1 day ago", color: .purple)
    ]
}

struct ActivityItem {
    let id: Int
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

struct StatCardMini: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct ActivityListItem: View {
    let item: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 20))
                .foregroundStyle(item.color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                
                Text(item.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
    }
}

#Preview {
    ActivityView()
}
