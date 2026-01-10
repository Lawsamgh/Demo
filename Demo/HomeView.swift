//
//  HomeView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome Header
                        welcomeHeader
                        
                        // Quick Stats Cards
                        quickStatsSection
                        
                        // Features Grid
                        featuresSection
                        
                        // Recent Activity
                        recentActivitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Here's what's happening today")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                StatCard(
                    title: "Total Items",
                    value: "1,234",
                    icon: "cube.box.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Users",
                    value: "89",
                    icon: "person.2.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Completed",
                    value: "456",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Pending",
                    value: "123",
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "plus.circle.fill",
                    title: "Add New Item",
                    subtitle: "Create a new entry",
                    color: .blue
                )
                
                FeatureRow(
                    icon: "magnifyingglass",
                    title: "Search Items",
                    subtitle: "Find what you're looking for",
                    color: .green
                )
                
                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "View Reports",
                    subtitle: "Analytics and insights",
                    color: .orange
                )
                
                FeatureRow(
                    icon: "gear.circle.fill",
                    title: "Settings",
                    subtitle: "Manage your preferences",
                    color: .gray
                )
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("See All") {
                    // Handle see all
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.blue)
            }
            
            VStack(spacing: 0) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Item updated",
                    subtitle: "2 minutes ago",
                    color: .green
                )
                
                Divider()
                    .padding(.leading, 52)
                
                ActivityRow(
                    icon: "person.circle.fill",
                    title: "New user registered",
                    subtitle: "1 hour ago",
                    color: .blue
                )
                
                Divider()
                    .padding(.leading, 52)
                
                ActivityRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Action required",
                    subtitle: "3 hours ago",
                    color: .orange
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Handle action
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
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
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
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
