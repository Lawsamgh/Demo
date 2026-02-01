//
//  MainTabView.swift
//  WalletWatch
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var userSession = UserSession.shared
    @State private var selectedTab: TabItem = .home
    
    enum TabItem: String, CaseIterable {
        case home = "Home"
        case search = "Search"
        case activity = "Activity"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .activity: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .search: return "magnifyingglass"
            case .activity: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(TabItem.home)
                .tabItem {
                    Label("Home", systemImage: TabItem.home.icon)
                }
            
            SearchView()
                .tag(TabItem.search)
                .tabItem {
                    Label("Search", systemImage: TabItem.search.icon)
                }
            
            ActivityView()
                .tag(TabItem.activity)
                .tabItem {
                    Label("Activity", systemImage: TabItem.activity.icon)
                }
            
            SettingView()
                .tag(TabItem.settings)
                .tabItem {
                    Label("Settings", systemImage: TabItem.settings.icon)
                }
        }
        .tint(.blue)
        .animation(.smooth(duration: 0.3), value: selectedTab)
        .onChange(of: selectedTab) { oldValue, newValue in
            // Add haptic feedback on tab change
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

#Preview {
    MainTabView()
}