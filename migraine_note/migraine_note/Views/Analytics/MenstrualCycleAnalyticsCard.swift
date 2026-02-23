//
//  MenstrualCycleAnalyticsCard.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/6.
//
//  经期与偏头痛关联分析卡片
//

import SwiftUI
import SwiftData
import Charts

struct MenstrualCycleAnalyticsCard: View {
    @State private var cycleManager = MenstrualCycleManager.shared
    @Query(sort: \AttackRecord.startTime, order: .reverse) private var attacks: [AttackRecord]
    
    @State private var hasLoadedData = false
    @State private var isLoading = false
    
    var body: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 标题
                HStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .foregroundStyle(Color.gentlePink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("经期关联分析")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("来自 Apple 健康")
                            .font(.caption2)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    Spacer()
                    
                    if !cycleManager.isAuthorized {
                        Button("授权") {
                            Task {
                                await authorizeAndLoad()
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                if !cycleManager.isAvailable {
                    // 设备不支持
                    notAvailableView
                } else if !cycleManager.isAuthorized {
                    // 未授权
                    unauthorizedView
                } else if isLoading {
                    // 加载中
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("正在分析经期数据...")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.vertical, 8)
                } else if let errorMessage = cycleManager.errorMessage {
                    // 错误信息
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(Color.statusWarning)
                            Text("数据加载失败")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        Button("重试") {
                            cycleManager.errorMessage = nil
                            Task {
                                await authorizeAndLoad()
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else if let analysis = cycleManager.cycleAnalysis, analysis.totalAttacksAnalyzed > 0 {
                    // 显示分析结果
                    analysisResultView(analysis)
                } else if cycleManager.menstrualData.isEmpty {
                    // 没有经期数据
                    noDataView
                } else {
                    // 数据不足
                    insufficientDataView
                }
            }
        }
        .onAppear {
            if !hasLoadedData && cycleManager.isAuthorized {
                loadData()
            }
        }
    }
    
    // MARK: - Views
    
    private var notAvailableView: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.slash.circle")
                .foregroundStyle(Color.textTertiary)
            VStack(alignment: .leading, spacing: 4) {
                Text("此设备不支持 Apple 健康")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Text("需要 iOS 设备上的 HealthKit 功能")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
    
    private var unauthorizedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("连接 Apple 健康数据")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("使用 HealthKit 读取经期数据")
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            
            Text("授权后将从「健康」App 自动读取您的经期数据，分析月经周期与偏头痛发作的关联，帮助识别月经性偏头痛。")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
            
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.statusSuccess)
                
                Text("所有数据仅在本地分析，不会上传到任何服务器")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.statusSuccess.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var noDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundStyle(Color.textTertiary)
                Text("未找到经期记录")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
            }
            
            Text("请在「健康」App 中记录经期数据。打开「健康」→「浏览」→「经期追踪」进行记录。")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
        }
    }
    
    private var insufficientDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(Color.textTertiary)
                Text("经期数据不足")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
            }
            
            Text("至少需要 2 个完整的月经周期才能进行关联分析。请在「健康」App 中继续记录经期数据。")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
        }
    }
    
    @ViewBuilder
    private func analysisResultView(_ analysis: CycleAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 月经性偏头痛判定
            if analysis.isMenstrualMigraine {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusWarning)
                    Text("可能存在月经性偏头痛")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.statusWarning)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.statusWarning.opacity(0.1))
                .cornerRadius(10)
            }
            
            // 核心数据
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均周期")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text("\(analysis.averageCycleLength) 天")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("经期相关发作")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text(String(format: "%.0f%%", analysis.periodCorrelationPercentage))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(analysis.periodCorrelationPercentage >= 50 ? Color.statusWarning : Color.accentPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("分析发作数")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text("\(analysis.totalAttacksAnalyzed) 次")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            
            Divider()
            
            // 发作时机分布
            VStack(alignment: .leading, spacing: 8) {
                Text("发作时机分布")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                
                HStack(spacing: 12) {
                    AttackTimingItem(
                        label: "经期中",
                        count: analysis.attacksDuringPeriod,
                        color: .gentlePink
                    )
                    
                    AttackTimingItem(
                        label: "经前2天",
                        count: analysis.attacksBeforePeriod,
                        color: .statusWarning
                    )
                    
                    AttackTimingItem(
                        label: "其他时间",
                        count: analysis.attacksOutsidePeriod,
                        color: .accentPrimary
                    )
                }
            }
            
            // 周期阶段分布图
            if !analysis.cyclePhaseDistribution.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("周期各阶段发作次数")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Chart {
                        ForEach(analysis.cyclePhaseDistribution) { data in
                            BarMark(
                                x: .value("阶段", data.phase),
                                y: .value("次数", data.count)
                            )
                            .foregroundStyle(phaseColor(for: data.phase))
                            .cornerRadius(6)
                        }
                    }
                    .frame(height: 150)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func authorizeAndLoad() async {
        // 清除之前的错误信息
        cycleManager.errorMessage = nil
        
        let granted = await cycleManager.requestAuthorization()
        if granted {
            await loadDataAsync()
        }
    }
    
    private func loadData() {
        Task {
            await loadDataAsync()
        }
    }
    
    private func loadDataAsync() async {
        await MainActor.run { isLoading = true }
        
        // 使用 defer 确保 isLoading 一定会被重置，防止页面卡在加载状态
        defer {
            Task { @MainActor in
                isLoading = false
                hasLoadedData = true
            }
        }
        
        await cycleManager.fetchMenstrualData(months: 6)
        let analysis = cycleManager.analyzeCycleCorrelation(with: attacks)
        
        await MainActor.run {
            cycleManager.cycleAnalysis = analysis
        }
    }
    
    private func phaseColor(for phase: String) -> Color {
        switch phase {
        case "经期": return .gentlePink
        case "经前期(2天)": return .statusWarning
        case "卵泡期": return .accentPrimary
        case "排卵期": return .accentSecondary
        case "黄体期": return .statusInfo
        default: return .textTertiary
        }
    }
}

// MARK: - Supporting Views

struct AttackTimingItem: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
