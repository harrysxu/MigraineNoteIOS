//
//  MainTabView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(0)
            
            // 日历
            CalendarView(modelContext: modelContext)
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }
                .tag(1)
            
            // 记录列表
            AttackListView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet.clipboard")
                }
                .tag(2)
            
            // 数据分析
            AnalyticsView(modelContext: modelContext)
                .tabItem {
                    Label("分析", systemImage: "chart.bar.fill")
                }
                .tag(3)
            
            // 用药管理
            MedicationListView()
                .tabItem {
                    Label("药箱", systemImage: "pills.fill")
                }
                .tag(4)
            
            // 设置
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(5)
        }
        .preferredColorScheme(.dark) // 暗黑模式优先
    }
}

// 占位视图
struct AnalyticsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("数据分析")
                    .font(.title2)
                Text("即将推出")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("分析")
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("设置")
                    .font(.title2)
                Text("即将推出")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [AttackRecord.self], inMemory: true)
}
