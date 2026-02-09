//
//  MainTabView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

/// 延迟初始化视图包装器，避免 TabView 在启动时创建所有子视图
struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: some View {
        build()
    }
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var themeManager = ThemeManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // 首页（默认 Tab，不需要懒加载）
                HomeView()
                    .tabItem {
                        Label("首页", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                
                // 记录列表（懒加载，切换到该 Tab 时才创建）
                LazyView(AttackListView())
                    .tabItem {
                        Label("记录", systemImage: selectedTab == 1 ? "list.bullet.clipboard.fill" : "list.bullet.clipboard")
                    }
                    .tag(1)
                
                // 数据（统计+日历）（懒加载）
                LazyView(AnalyticsView(modelContext: modelContext))
                    .tabItem {
                        Label("数据", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    }
                    .tag(2)
                
                // 我的（药箱+设置）（懒加载）
                LazyView(ProfileView())
                    .tabItem {
                        Label("我的", systemImage: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                    }
                    .tag(3)
            }
            .tint(Color.accentPrimary) // 使用新的主色调
            .preferredColorScheme(themeManager.currentTheme.colorScheme) // 跟随用户主题设置
            
            // Onboarding覆盖层
            if !hasCompletedOnboarding {
                OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .withGlobalToast()
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        // 使用 .onReceive 替代 addObserver，自动管理生命周期，避免观察者泄漏
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToRecordListTab"))) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToDataTab"))) { _ in
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
