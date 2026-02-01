//
//  HomeView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var showRecordingView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let vm = viewModel {
                        // 状态卡片
                        StatusCard(
                            streakDays: vm.streakDays,
                            ongoingAttack: vm.ongoingAttack
                        )
                        
                        // 记录按钮
                        RecordButton {
                            showRecordingView = true
                        }
                        
                        // 天气卡片
                        WeatherRiskCardPlaceholder()
                        
                        // 最近记录（如果有）
                        if !vm.recentAttacks.isEmpty {
                            RecentAttacksCard(attacks: vm.recentAttacks)
                        }
                    } else {
                        ProgressView()
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("今天")
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .sheet(isPresented: $showRecordingView) {
                NavigationStack {
                    RecordingContainerView(modelContext: modelContext)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("取消") {
                                    showRecordingView = false
                                }
                            }
                        }
                }
                .onDisappear {
                    viewModel?.refreshData()
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(modelContext: modelContext)
            }
        }
    }
}

// MARK: - 状态卡片

struct StatusCard: View {
    let streakDays: Int
    let ongoingAttack: AttackRecord?
    
    var body: some View {
        InfoCard {
            VStack(spacing: 12) {
                if let attack = ongoingAttack {
                    // 发作进行中
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.statusWarning)
                        Text("发作进行中")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text("已持续 \(formatDuration(attack.startTime))")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    // 无发作
                    Text("🎉")
                        .font(.system(size: 48))
                    if streakDays > 0 {
                        Text("您已连续 \(streakDays) 天无头痛")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("欢迎使用偏头痛记录")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("开始记录您的健康状况")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// MARK: - 记录按钮

struct RecordButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 64))
                Text("开始记录")
                    .font(.headline)
            }
            .foregroundStyle(Color.accentPrimary)
            .frame(width: 160, height: 160)
            .background(
                Circle()
                    .fill(Color.backgroundSecondary)
                    .shadow(
                        color: Shadow.card,
                        radius: Shadow.floatingRadius,
                        x: Shadow.floatingOffset.width,
                        y: Shadow.floatingOffset.height
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - 天气卡片占位

struct WeatherRiskCardPlaceholder: View {
    var body: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundStyle(Color.statusInfo)
                    Text("环境提示")
                        .font(.headline)
                    Spacer()
                }
                
                Text("天气数据将在集成WeatherKit后显示")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

// MARK: - 最近记录卡片

struct RecentAttacksCard: View {
    let attacks: [AttackRecord]
    
    var body: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("最近记录")
                    .font(.headline)
                
                ForEach(attacks.prefix(3)) { attack in
                    HStack {
                        // 疼痛强度指示器
                        Circle()
                            .fill(Color.painCategoryColor(for: attack.painIntensity))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatDate(attack.startTime))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("疼痛强度: \(attack.painIntensity)/10")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.vertical, 4)
                    
                    if attack.id != attacks.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [AttackRecord.self], inMemory: true)
}

