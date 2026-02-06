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
                    Image(systemName: "figure.wave")
                        .foregroundStyle(Color.gentlePink)
                    Text("经期关联分析")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
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
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.textTertiary)
            Text("此设备不支持 HealthKit")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    private var unauthorizedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("连接 Apple 健康数据")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textPrimary)
            
            Text("授权后可自动读取经期数据，分析月经周期与偏头痛发作的关联。")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    private var noDataView: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .foregroundStyle(Color.textTertiary)
            Text("未找到经期记录，请在「健康」App中记录经期数据")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    private var insufficientDataView: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .foregroundStyle(Color.textTertiary)
            Text("经期数据不足，至少需要2个周期才能分析")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
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
        let granted = await cycleManager.requestAuthorization()
        if granted {
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        Task {
            await cycleManager.fetchMenstrualData(months: 6)
            let _ = cycleManager.analyzeCycleCorrelation(with: attacks)
            await MainActor.run {
                isLoading = false
                hasLoadedData = true
            }
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
