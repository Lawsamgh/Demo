//
//  ActivityView.swift
//  Demo
//
//  Created by PGH_PICT_LAMPENE on 10/01/2026.
//

import SwiftUI

struct ActivityView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("Activity")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Activity tracking coming soon")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ActivityView()
}