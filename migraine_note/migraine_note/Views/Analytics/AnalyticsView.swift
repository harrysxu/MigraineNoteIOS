//
//  AnalyticsView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AttackRecord.startTime, order: .reverse) private var attacks: [AttackRecord]
    
    @State private var selectedTimeRange: TimeRange = .threeMonths
    @State private var analyticsEngine: AnalyticsEngine
    @State private var mohDetector: MOHDetector
    @State private var showExportSheet = false
    
    init(modelContext: ModelContext) {
        _analyticsEngine = State(initialValue: AnalyticsEngine(modelContext: modelContext))
        _mohDetector = State(initialValue: MOHDetector(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                if attacks.isEmpty {
                    emptyStateView
                } else {
                    analyticsContent
                }
            }
            .navigationTitle("数据分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("时间范围", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedTimeRange.displayName)
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.accentPrimary)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("导出PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportReportView()
            }
        }
        .onAppear {
            analyticsEngine = AnalyticsEngine(modelContext: modelContext)
            mohDetector = MOHDetector(modelContext: modelContext)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            
            Text("暂无数据")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            
            Text("开始记录偏头痛发作，解锁数据分析功能")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
    }
    
    // MARK: - Analytics Content
    
    private var analyticsContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // MOH风险仪表盘
                mohRiskSection
                
                // 月度趋势图
                monthlyTrendSection
                
                // 诱因分析
                triggerAnalysisSection
                
                // 昼夜节律分析
                circadianPatternSection
                
                // MIDAS评分（如果有足够数据）
                if attacks.count >= 3 {
                    midasScoreSection
                }
            }
            .padding(Spacing.md)
        }
    }
    
    // MARK: - MOH Risk Section
    
    private var mohRiskSection: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "pills.circle.fill")
                        .foregroundStyle(mohRiskColor)
                    Text("药物过度使用风险")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let risk = mohDetector.detectCurrentMonthRisk()
                
                // 风险等级
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("风险等级")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        Text(risk.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(mohRiskColor)
                    }
                    
                    Spacer()
                    
                    // 环形进度条
                    ZStack {
                        Circle()
                            .stroke(Color.divider, lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: riskProgress(risk))
                            .stroke(mohRiskColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text(risk.emoji)
                                .font(.title3)
                            Text("\(Int(riskProgress(risk) * 100))%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(mohRiskColor)
                        }
                    }
                }
                
                // 风险说明
                if risk != .none {
                    Text(risk.recommendation)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(mohRiskColor.opacity(0.1))
                        .cornerRadius(Spacing.cornerRadiusSmall)
                }
            }
        }
    }
    
    private var mohRiskColor: Color {
        let risk = mohDetector.detectCurrentMonthRisk()
        switch risk {
        case .none:
            return Color.statusSuccess
        case .low:
            return Color.statusWarning
        case .medium:
            return Color.statusWarning
        case .high:
            return Color.statusError
        }
    }
    
    private func riskProgress(_ risk: RiskLevel) -> Double {
        switch risk {
        case .none:
            return 0.2
        case .low:
            return 0.4
        case .medium:
            return 0.7
        case .high:
            return 1.0
        }
    }
    
    // MARK: - Monthly Trend Section
    
    private var monthlyTrendSection: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("月度趋势")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let monthlyData = getMonthlyTrendData()
                
                if monthlyData.isEmpty {
                    Text("数据不足")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Chart {
                        ForEach(monthlyData) { item in
                            BarMark(
                                x: .value("月份", item.monthName),
                                y: .value("发作天数", item.attackDays)
                            )
                            .foregroundStyle(item.attackDays >= 15 ? Color.statusError : Color.accentPrimary)
                            .annotation(position: .top) {
                                Text("\(item.attackDays)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        
                        // 慢性偏头痛阈值线
                        RuleMark(y: .value("慢性阈值", 15))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            .foregroundStyle(Color.statusError.opacity(0.5))
                            .annotation(position: .topTrailing, alignment: .leading) {
                                Text("慢性阈值(15天)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.statusError)
                            }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let monthName = value.as(String.self) {
                                    Text(monthName)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Trigger Analysis Section
    
    private var triggerAnalysisSection: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusWarning)
                    Text("诱因频次分析")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let triggerData = analyticsEngine.analyzeTriggerFrequency(in: selectedTimeRange.dateRange)
                
                if triggerData.isEmpty {
                    Text("暂无诱因数据")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    VStack(spacing: Spacing.sm) {
                        ForEach(Array(triggerData.prefix(5).enumerated()), id: \.element.triggerName) { index, item in
                            TriggerFrequencyRow(
                                rank: index + 1,
                                triggerName: item.triggerName,
                                count: item.count,
                                percentage: item.percentage
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Circadian Pattern Section
    
    private var circadianPatternSection: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("发作时间分布")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let circadianData = analyticsEngine.analyzeCircadianPattern(in: selectedTimeRange.dateRange)
                
                if circadianData.isEmpty {
                    Text("数据不足")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Chart {
                        ForEach(circadianData) { item in
                            PointMark(
                                x: .value("小时", item.hour),
                                y: .value("次数", item.count)
                            )
                            .foregroundStyle(Color.accentPrimary)
                            .symbolSize(100)
                        }
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                            AxisValueLabel {
                                if let hour = value.as(Int.self) {
                                    Text("\(hour)时")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    
                    // 高发时段提示
                    if let peakHour = circadianData.max(by: { $0.count < $1.count }) {
                        Text("高发时段：\(peakHour.hour)时-\(peakHour.hour + 1)时")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .padding(Spacing.xs)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(Spacing.cornerRadiusSmall)
                    }
                }
            }
        }
    }
    
    // MARK: - MIDAS Score Section
    
    private var midasScoreSection: some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                        .foregroundStyle(Color.accentPrimary)
                    Text("MIDAS残疾评分")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let score = analyticsEngine.calculateMIDASScore(attacks: attacks)
                
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("总分")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        Text("\(score)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(midasColor(score))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("残疾程度")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        Text(midasGrade(score))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(midasColor(score))
                    }
                }
                
                Text(midasDescription(score))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(Spacing.cornerRadiusSmall)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMonthlyTrendData() -> [MonthlyTrendData] {
        let calendar = Calendar.current
        let now = Date()
        var data: [MonthlyTrendData] = []
        
        // 获取最近6个月的数据
        for monthOffset in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
            
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            
            let monthAttacks = attacks.filter { attack in
                attack.startTime >= monthStart && attack.startTime < monthEnd
            }
            
            // 计算发作天数（去重）
            let attackDays = Set(monthAttacks.map { calendar.startOfDay(for: $0.startTime) }).count
            
            let monthName = monthDate.formatted(.dateTime.month(.narrow))
            
            data.append(MonthlyTrendData(
                id: UUID(),
                monthName: monthName,
                attackDays: attackDays,
                monthDate: monthDate
            ))
        }
        
        return data
    }
    
    private func midasColor(_ score: Int) -> Color {
        switch score {
        case 0...5:
            return Color.statusSuccess
        case 6...10:
            return Color.statusInfo
        case 11...20:
            return Color.statusWarning
        default:
            return Color.statusError
        }
    }
    
    private func midasGrade(_ score: Int) -> String {
        switch score {
        case 0...5:
            return "I级 - 轻微"
        case 6...10:
            return "II级 - 轻度"
        case 11...20:
            return "III级 - 中度"
        default:
            return "IV级 - 重度"
        }
    }
    
    private func midasDescription(_ score: Int) -> String {
        switch score {
        case 0...5:
            return "偏头痛对日常生活影响较小"
        case 6...10:
            return "偏头痛对日常生活有轻度影响，建议咨询医生"
        case 11...20:
            return "偏头痛对日常生活有中度影响，建议及时就医"
        default:
            return "偏头痛严重影响日常生活，强烈建议就医"
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable, Identifiable {
    case oneMonth = "1个月"
    case threeMonths = "3个月"
    case sixMonths = "6个月"
    case oneYear = "1年"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var dateRange: (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .oneMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return (start, now)
        case .threeMonths:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .sixMonths:
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            return (start, now)
        case .oneYear:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)
        }
    }
}

struct MonthlyTrendData: Identifiable {
    let id: UUID
    let monthName: String
    let attackDays: Int
    let monthDate: Date
}

// MARK: - Trigger Frequency Row

struct TriggerFrequencyRow: View {
    let rank: Int
    let triggerName: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // 排名
            Text("\(rank)")
                .font(.body.weight(.bold))
                .foregroundStyle(rankColor)
                .frame(width: 24, height: 24)
                .background(rankColor.opacity(0.15))
                .clipShape(Circle())
            
            // 诱因名称
            Text(triggerName)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            // 次数和百分比
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)次")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return Color.statusError
        case 2:
            return Color.statusWarning
        case 3:
            return Color.statusInfo
        default:
            return Color.textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: AttackRecord.self, Medication.self, configurations: config)
        let context = container.mainContext
        
        // 创建测试数据
        let calendar = Calendar.current
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let attack = AttackRecord(startTime: date)
                attack.painIntensity = Int.random(in: 3...9)
                attack.endTime = calendar.date(byAdding: .hour, value: Int.random(in: 2...8), to: date)
                
                // 添加诱因
                let trigger = Trigger(category: .stress, specificType: ["压力", "睡眠不足", "天气变化", "饮食"].randomElement()!)
                attack.triggers.append(trigger)
                
                context.insert(attack)
            }
        }
        
        return container
    }()
    
    AnalyticsView(modelContext: container.mainContext)
}
