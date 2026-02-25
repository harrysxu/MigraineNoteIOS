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
                        Text(String(localized: "menstrual.title"))
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text(String(localized: "menstrual.fromHealth"))
                            .font(.caption2)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    Spacer()
                    
                    if !cycleManager.isAuthorized {
                        Button(String(localized: "menstrual.authorize")) {
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
                        Text(String(localized: "menstrual.loading"))
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
                            Text(String(localized: "menstrual.loadFailed"))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        Button(String(localized: "menstrual.retry")) {
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
                Text(String(localized: "menstrual.notAvailable"))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Text(String(localized: "menstrual.healthKitRequired"))
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
                    Text(String(localized: "menstrual.connectHealth"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(String(localized: "menstrual.healthKitRead"))
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            
            Text(String(localized: "menstrual.privacyHint"))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)
            
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.statusSuccess)
                
                Text(String(localized: "menstrual.localOnly"))
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
                Text(String(localized: "menstrual.noData"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
            }
            
            Text(String(localized: "menstrual.noDataHint"))
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
                Text(String(localized: "menstrual.insufficientData"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
            }
            
            Text(String(localized: "menstrual.insufficientHint"))
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
                    Text(String(localized: "menstrual.menstrualMigraine"))
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
                    Text(String(localized: "menstrual.avgCycle"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text(String(format: String(localized: "common.daysFormat"), analysis.averageCycleLength))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "menstrual.periodRelated"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text(String(format: "%.0f%%", analysis.periodCorrelationPercentage))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(analysis.periodCorrelationPercentage >= 50 ? Color.statusWarning : Color.accentPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "menstrual.analyzedCount"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Text(String(format: String(localized: "common.timesFormat"), analysis.totalAttacksAnalyzed))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
            
            Divider()
            
            // 发作时机分布
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "menstrual.timingDistribution"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                
                HStack(spacing: 12) {
                    AttackTimingItem(
                        label: String(localized: "menstrual.timingDuring"),
                        count: analysis.attacksDuringPeriod,
                        color: .gentlePink
                    )
                    
                    AttackTimingItem(
                        label: String(localized: "menstrual.timingBefore"),
                        count: analysis.attacksBeforePeriod,
                        color: .statusWarning
                    )
                    
                    AttackTimingItem(
                        label: String(localized: "menstrual.timingOther"),
                        count: analysis.attacksOutsidePeriod,
                        color: .accentPrimary
                    )
                }
            }
            
            // 周期阶段分布图
            if !analysis.cyclePhaseDistribution.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "menstrual.phaseDistribution"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Chart {
                        ForEach(analysis.cyclePhaseDistribution) { data in
                            BarMark(
                                x: .value(String(localized: "chart.phase"), data.phase),
                                y: .value(String(localized: "chart.count"), data.count)
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
