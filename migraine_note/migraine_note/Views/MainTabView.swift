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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // 首页
                HomeView()
                    .tabItem {
                        Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                
                // 记录列表
                AttackListView()
                    .tabItem {
                        Label("记录", systemImage: selectedTab == 1 ? "list.bullet.clipboard.fill" : "list.bullet.clipboard")
                    }
                    .tag(1)
                
                // 数据（统计+日历）
                AnalyticsView(modelContext: modelContext)
                    .tabItem {
                        Label("数据", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    }
                    .tag(2)
                
                // 我的（药箱+设置）
                ProfileView()
                    .tabItem {
                        Label("我的", systemImage: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                    }
                    .tag(3)
            }
            .tint(Color.primary) // 使用新的主色调
            .preferredColorScheme(.dark) // 暗黑模式优先
            
            // Onboarding覆盖层
            if !hasCompletedOnboarding {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .onAppear {
            setupNotificationObservers()
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // 监听切换到记录标签页的通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SwitchToRecordListTab"),
            object: nil,
            queue: .main
        ) { _ in
            selectedTab = 1
        }
        
        // 监听切换到数据标签页的通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SwitchToDataTab"),
            object: nil,
            queue: .main
        ) { _ in
            selectedTab = 2
        }
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
