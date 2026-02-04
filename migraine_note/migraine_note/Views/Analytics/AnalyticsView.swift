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
    
    @State private var selectedTimeRange: TimeRange = .thisMonth
    @State private var selectedView: DataViewType = .analytics
    @State private var analyticsEngine: AnalyticsEngine
    @State private var mohDetector: MOHDetector
    @State private var calendarViewModel: CalendarViewModel?
    @State private var showTimeRangeSheet = false
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var showCSVShareSheet = false
    @State private var csvFileURL: URL?
    @State private var showExportErrorAlert = false
    @State private var exportErrorMessage = ""
    
    init(modelContext: ModelContext) {
        _analyticsEngine = State(initialValue: AnalyticsEngine(modelContext: modelContext))
        _mohDetector = State(initialValue: MOHDetector(modelContext: modelContext))
    }
    
    enum DataViewType: String, CaseIterable {
        case analytics = "图表"
        case calendar = "日历"
    }
    
    // 计算属性：获取当前选择的日期范围
    private var currentDateRange: (Date, Date) {
        selectedTimeRange.dateRange(customStart: customStartDate, customEnd: customEndDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 视图切换器
                Picker("数据视图", selection: $selectedView) {
                    ForEach(DataViewType.allCases, id: \.self) { viewType in
                        Text(viewType.rawValue).tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.backgroundPrimary)
                
                // 内容区域
                ZStack {
                    Color.backgroundPrimary.ignoresSafeArea()
                    
                    if attacks.isEmpty {
                        emptyStateView
                    } else {
                        switch selectedView {
                        case .analytics:
                            analyticsContent
                        case .calendar:
                            calendarContent
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedView == .analytics {
                        Button {
                            showTimeRangeSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedTimeRange.displayName)
                                    .font(.subheadline)
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Color.accentPrimary)
                        }
                    } else {
                        Button(action: {
                            calendarViewModel?.moveToToday()
                        }) {
                            Text("今天")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showTimeRangeSheet) {
                TimeRangeSheetView(
                    selectedTimeRange: $selectedTimeRange,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate
                )
            }
            .sheet(isPresented: $showCSVShareSheet) {
                if let csvFileURL = csvFileURL {
                    ShareSheet(activityItems: [csvFileURL])
                }
            }
            .alert("导出失败", isPresented: $showExportErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(exportErrorMessage)
            }
        }
        .onAppear {
            analyticsEngine = AnalyticsEngine(modelContext: modelContext)
            mohDetector = MOHDetector(modelContext: modelContext)
            if calendarViewModel == nil {
                calendarViewModel = CalendarViewModel(modelContext: modelContext)
            }
            
            // 监听从HomeView切换到日历视图的通知
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SwitchToDataCalendarView"),
                object: nil,
                queue: .main
            ) { _ in
                selectedView = .calendar
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 空状态图标
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 50, weight: .ultraLight))
                    .foregroundStyle(Color.accentPrimary)
            }
            
            VStack(spacing: 8) {
                Text("记录3次以上")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                
                Text("解锁数据统计")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
            }
            
            Text("记录更多数据，获得更完整的统计信息")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, Spacing.xl)
    }
    
    // MARK: - Calendar Content
    
    private var calendarContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let viewModel = calendarViewModel {
                    // 月份统计卡片
                    if let stats = viewModel.monthlyStats {
                        MonthlyStatsCard(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    // 疼痛强度图例
                    PainIntensityLegend()
                        .padding(.horizontal)
                    
                    // 日历网格
                    CalendarGridSection(viewModel: viewModel)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Analytics Content
    
    private var analyticsContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // 整体情况概览
                overallSummaryCard
                
                // 月度趋势图
                monthlyTrendSection
                
                // 疼痛评估统计
                painAssessmentSection
                
                // 症状统计
                symptomStatisticsSection
                
                // 诱因统计
                triggerAnalysisSection
                
                // 发作时间分布
                circadianPatternSection
                
                // 用药统计
                medicationStatisticsSection
                
                // 用药频次提醒
                mohRiskSection
            }
            .padding(Spacing.md)
        }
        .id("\(selectedTimeRange.rawValue)_\(customStartDate)_\(customEndDate)")
    }
    
    // MARK: - 整体情况概览
    
    private var overallSummaryCard: some View {
        EmotionalCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                // 标题行
                HStack {
                    Text("整体概况")
                        .font(.title3.weight(.semibold))
                    
                    Spacer()
                    
                    Text(selectedTimeRange.displayName)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.backgroundTertiary)
                        .cornerRadius(8)
                }
                
                // 统计卡片网格 - 2x3布局
                VStack(spacing: 12) {
                    // 第一行
                    HStack(spacing: 12) {
                        CompactAnalyticStatCard(
                            value: "\(getTotalAttacksCount())",
                            label: "发作次数",
                            icon: "exclamationmark.triangle.fill",
                            color: .statusError
                        )
                        
                        CompactAnalyticStatCard(
                            value: "\(getAttackDaysCount())",
                            label: "发作天数",
                            icon: "calendar.badge.exclamationmark",
                            color: .statusWarning
                        )
                    }
                    
                    // 第二行
                    HStack(spacing: 12) {
                        CompactAnalyticStatCard(
                            value: String(format: "%.1f", getAveragePainIntensity()),
                            label: "平均强度",
                            icon: "waveform.path.ecg",
                            color: .statusInfo
                        )
                        
                        CompactAnalyticStatCard(
                            value: "\(getMedicationCount())",
                            label: "用药次数",
                            icon: "pills.fill",
                            color: .accentPrimary
                        )
                    }
                    
                    // 第三行（单列）
                    let durationStats = analyticsEngine.analyzeDurationStatistics(in: currentDateRange)
                    HStack(spacing: 12) {
                        CompactAnalyticStatCard(
                            value: String(format: "%.1fh", durationStats.averageDurationHours),
                            label: "平均持续时长",
                            icon: "clock.fill",
                            color: .accentSecondary,
                            isWide: true
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - MOH Risk Section
    
    private var mohRiskSection: some View {
        let medicationStats = analyticsEngine.analyzeMedicationUsage(in: currentDateRange)
        let currentMonthStats = getCurrentMonthMedicationDays()
        
        return EmotionalCard(style: currentMonthStats >= 10 ? .warning : .default) {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                HStack(spacing: 8) {
                    Image(systemName: "pills.circle.fill")
                        .font(.title3)
                        .foregroundStyle(currentMonthStats >= 10 ? Color.statusWarning : Color.accentPrimary)
                    Text("用药频次提醒")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                }
                
                // 当月用药天数 - 横向布局
                HStack(spacing: 20) {
                    // 左侧数值
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本月用药天数")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(currentMonthStats)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(currentMonthStats >= 10 ? Color.statusWarning : Color.accentPrimary)
                            
                            Text("天")
                                .font(.title3)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        // 进度条
                        VStack(alignment: .leading, spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.backgroundTertiary)
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(currentMonthStats >= 10 ? Color.statusWarning : Color.accentPrimary)
                                        .frame(
                                            width: geometry.size.width * min(Double(currentMonthStats) / 15.0, 1.0),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                            
                            Text("建议不超过 10 天")
                                .font(.caption2)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // 右侧环形进度
                    ZStack {
                        Circle()
                            .stroke(Color.divider, lineWidth: 6)
                            .frame(width: 64, height: 64)
                        
                        Circle()
                            .trim(from: 0, to: min(Double(currentMonthStats) / 15.0, 1.0))
                            .stroke(
                                currentMonthStats >= 10 ? Color.statusWarning : Color.accentPrimary,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.0f%%", min(Double(currentMonthStats) / 10.0 * 100, 100)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                
                // 提醒说明
                if currentMonthStats >= 10 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.statusWarning)
                        
                        Text("当月用药天数已达到或超过10天，建议就医咨询专业医生")
                            .font(.caption)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.statusWarning.opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Monthly Trend Section
    
    private var monthlyTrendSection: some View {
        EmotionalCard(style: .default) {
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
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        item.attackDays >= 15 ? Color.statusError : Color.accentPrimary,
                                        (item.attackDays >= 15 ? Color.statusError : Color.accentPrimary).opacity(0.6)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(8)
                            .annotation(position: .top) {
                                Text("\(item.attackDays)")
                                    .font(.caption2.weight(.semibold))
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
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusWarning)
                    Text("诱因频次统计")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let triggerData = analyticsEngine.analyzeTriggerFrequency(in: currentDateRange)
                
                if triggerData.isEmpty {
                    Text("暂无诱因数据")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    VStack(spacing: 8) {
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
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("发作时间分布")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let circadianData = analyticsEngine.analyzeCircadianPattern(in: currentDateRange)
                
                if circadianData.isEmpty {
                    Text("数据不足")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Chart {
                        ForEach(circadianData) { item in
                            AreaMark(
                                x: .value("小时", item.hour),
                                yStart: .value("起点", 0),
                                yEnd: .value("次数", item.count)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.accentPrimary.opacity(0.5),
                                        Color.accentPrimary.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            LineMark(
                                x: .value("小时", item.hour),
                                y: .value("次数", item.count)
                            )
                            .foregroundStyle(Color.accentPrimary)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("小时", item.hour),
                                y: .value("次数", item.count)
                            )
                            .foregroundStyle(Color.accentPrimary)
                            .symbolSize(60)
                        }
                    }
                    .frame(height: 180)
                    .chartXScale(domain: 0...24)
                    .chartXAxis {
                        AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                            AxisValueLabel {
                                if let hour = value.as(Int.self) {
                                    Text("\(hour)时")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let count = value.as(Int.self) {
                                    Text("\(count)")
                                        .font(.caption2)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
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
    
    // MARK: - 疼痛评估统计
    
    private var painAssessmentSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(Color.statusError)
                    Text("疼痛评估统计")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let intensityDist = analyticsEngine.analyzePainIntensityDistribution(in: currentDateRange)
                let locationFreq = analyticsEngine.analyzePainLocationFrequency(in: currentDateRange)
                let qualityFreq = analyticsEngine.analyzePainQualityFrequency(in: currentDateRange)
                
                // 疼痛强度分布
                VStack(alignment: .leading, spacing: 12) {
                    Text("疼痛强度分布")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    if intensityDist.total > 0 {
                        VStack(spacing: 8) {
                            IntensityBar(
                                label: "轻度 (1-3)",
                                count: intensityDist.mild,
                                percentage: intensityDist.mildPercentage,
                                color: .statusSuccess
                            )
                            
                            IntensityBar(
                                label: "中度 (4-6)",
                                count: intensityDist.moderate,
                                percentage: intensityDist.moderatePercentage,
                                color: .statusWarning
                            )
                            
                            IntensityBar(
                                label: "重度 (7-10)",
                                count: intensityDist.severe,
                                percentage: intensityDist.severePercentage,
                                color: .statusError
                            )
                        }
                    } else {
                        Text("暂无数据")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                if !locationFreq.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    // 疼痛部位频次 Top 5
                    VStack(alignment: .leading, spacing: 12) {
                        Text("疼痛部位频次 (Top 5)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(locationFreq.prefix(5))) { location in
                                FrequencyRow(
                                    name: location.locationName,
                                    count: location.count,
                                    percentage: location.percentage
                                )
                            }
                        }
                    }
                }
                
                if !qualityFreq.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    // 疼痛性质频次
                    VStack(alignment: .leading, spacing: 12) {
                        Text("疼痛性质频次")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        
                        VStack(spacing: 8) {
                            ForEach(qualityFreq) { quality in
                                FrequencyRow(
                                    name: quality.qualityName,
                                    count: quality.count,
                                    percentage: quality.percentage
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 症状统计
    
    private var symptomStatisticsSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(Color.statusInfo)
                    Text("症状统计")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let symptomFreq = analyticsEngine.analyzeSymptomFrequency(in: currentDateRange)
                let auraStats = analyticsEngine.analyzeAuraStatistics(in: currentDateRange)
                
                // 伴随症状频次
                if !symptomFreq.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("伴随症状频次")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(symptomFreq.prefix(6))) { symptom in
                                FrequencyRow(
                                    name: symptom.symptomName,
                                    count: symptom.count,
                                    percentage: symptom.percentage
                                )
                            }
                        }
                    }
                } else {
                    Text("暂无症状数据")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                // 先兆统计
                if auraStats.totalAttacks > 0 {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("先兆统计")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        
                        HStack {
                            Text("有先兆发作")
                                .font(.body)
                                .foregroundStyle(Color.textPrimary)
                            
                            Spacer()
                            
                            Text("\(auraStats.attacksWithAura) 次")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                            
                            Text("(\(String(format: "%.1f%%", auraStats.auraPercentage)))")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        if !auraStats.auraTypeFrequency.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(auraStats.auraTypeFrequency) { auraType in
                                    FrequencyRow(
                                        name: "  • \(auraType.typeName)",
                                        count: auraType.count,
                                        percentage: auraType.percentage
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 用药统计
    
    private var medicationStatisticsSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "cross.case.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("用药统计")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let medicationStats = analyticsEngine.analyzeMedicationUsage(in: currentDateRange)
                
                if medicationStats.totalMedicationUses > 0 {
                    // 用药概况
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("总用药次数")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            Text("\(medicationStats.totalMedicationUses) 次")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("用药天数")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            Text("\(medicationStats.medicationDays) 天")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                    
                    // 药物分类统计
                    if !medicationStats.categoryBreakdown.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("药物分类统计")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                            
                            VStack(spacing: 8) {
                                ForEach(medicationStats.categoryBreakdown) { category in
                                    FrequencyRow(
                                        name: category.categoryName,
                                        count: category.count,
                                        percentage: category.percentage
                                    )
                                }
                            }
                        }
                    }
                    
                    // Top 5 常用药物
                    if !medicationStats.topMedications.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("最常用药物 (Top 5)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(medicationStats.topMedications.prefix(5))) { medication in
                                    FrequencyRow(
                                        name: medication.medicationName,
                                        count: medication.count,
                                        percentage: medication.percentage
                                    )
                                }
                            }
                        }
                    }
                } else {
                    Text("暂无用药数据")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMonthlyTrendData() -> [MonthlyTrendData] {
        let calendar = Calendar.current
        let (start, end) = currentDateRange
        var data: [MonthlyTrendData] = []
        
        // 根据时间范围确定要显示的月份数
        let monthsToShow: Int
        switch selectedTimeRange {
        case .thisMonth:
            monthsToShow = 3  // 本月范围也显示3个月趋势
        case .threeMonths:
            monthsToShow = 3
        case .sixMonths:
            monthsToShow = 6
        case .oneYear:
            monthsToShow = 12
        case .custom:
            // 计算自定义范围的月份数
            let components = calendar.dateComponents([.month], from: start, to: end)
            monthsToShow = max(min(components.month ?? 3, 12), 3)  // 最少3个月，最多12个月
        }
        
        // 获取指定月份数的数据
        for monthOffset in (0..<monthsToShow).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: end) else { continue }
            
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            
            let monthAttacks = attacks.filter { attack in
                attack.startTime >= monthStart && attack.startTime < monthEnd
            }
            
            // 计算发作天数（去重）
            let attackDays = Set(monthAttacks.map { calendar.startOfDay(for: $0.startTime) }).count
            
            let monthName = monthDate.monthName()
            
            data.append(MonthlyTrendData(
                id: UUID(),
                monthName: monthName,
                attackDays: attackDays,
                monthDate: monthDate
            ))
        }
        
        return data
    }
    
    // MARK: - 数据获取辅助方法
    
    private func getTotalAttacksCount() -> Int {
        let (start, end) = currentDateRange
        return attacks.filter { $0.startTime >= start && $0.startTime <= end }.count
    }
    
    private func getAttackDaysCount() -> Int {
        let calendar = Calendar.current
        let (start, end) = currentDateRange
        let attacksInRange = attacks.filter { $0.startTime >= start && $0.startTime <= end }
        return Set(attacksInRange.map { calendar.startOfDay(for: $0.startTime) }).count
    }
    
    private func getAveragePainIntensity() -> Double {
        let (start, end) = currentDateRange
        let attacksInRange = attacks.filter { $0.startTime >= start && $0.startTime <= end }
        guard !attacksInRange.isEmpty else { return 0 }
        let total = attacksInRange.reduce(0) { $0 + $1.painIntensity }
        return Double(total) / Double(attacksInRange.count)
    }
    
    private func getMedicationCount() -> Int {
        let (start, end) = currentDateRange
        let attacksInRange = attacks.filter { $0.startTime >= start && $0.startTime <= end }
        return attacksInRange.reduce(0) { $0 + $1.medications.count }
    }
    
    private func getCurrentMonthMedicationDays() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let monthAttacks = attacks.filter { attack in
            attack.startTime >= startOfMonth && attack.startTime < endOfMonth
        }
        
        let medicationDays = Set(
            monthAttacks
                .filter { !$0.medications.isEmpty }
                .map { calendar.startOfDay(for: $0.startTime) }
        )
        
        return medicationDays.count
    }
}

// MARK: - Supporting Views

/// 紧凑分析统计卡片
struct CompactAnalyticStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var isWide: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            // 数值和标签
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
    }
}

/// 疼痛强度条
struct IntensityBar: View {
    let label: String
    let count: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 标签
            Text(label)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .frame(width: 90, alignment: .leading)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: max(geometry.size.width * (percentage / 100), 2),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
            
            // 次数和百分比
            HStack(spacing: 6) {
                Text("\(count)次")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(minWidth: 40, alignment: .trailing)
                
                Text("(\(String(format: "%.0f%%", percentage)))")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .frame(minWidth: 50, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.backgroundPrimary)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }
}

/// 频次行
struct FrequencyRow: View {
    let name: String
    let count: Int
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // 名称
            Text(name)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            
            Spacer(minLength: 12)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentPrimary.opacity(0.7))
                        .frame(
                            width: max(geometry.size.width * (percentage / 100), 2),
                            height: 6
                        )
                }
            }
            .frame(width: 60, height: 6)
            
            // 次数和百分比
            HStack(spacing: 6) {
                Text("\(count)次")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(minWidth: 40, alignment: .trailing)
                
                Text("(\(String(format: "%.1f%%", percentage)))")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .frame(minWidth: 50, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.backgroundPrimary)
        .cornerRadius(10)
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable, Identifiable {
    case thisMonth = "本月"
    case threeMonths = "近3个月"
    case sixMonths = "近6个月"
    case oneYear = "近1年"
    case custom = "自定义"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .thisMonth: return "calendar.circle"
        case .threeMonths: return "calendar.badge.plus"
        case .sixMonths: return "calendar.badge.clock"
        case .oneYear: return "calendar"
        case .custom: return "calendar.badge.exclamationmark"
        }
    }
    
    func dateRange(customStart: Date? = nil, customEnd: Date? = nil) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisMonth:
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
        case .custom:
            if let customStart = customStart, let customEnd = customEnd {
                return (customStart, customEnd)
            }
            // 默认返回最近1个月
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
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
        HStack(spacing: 12) {
            // 排名
            Text("\(rank)")
                .font(.body.weight(.bold))
                .foregroundStyle(rankColor)
                .frame(width: 28, height: 28)
                .background(rankColor.opacity(0.15))
                .clipShape(Circle())
            
            // 诱因名称
            Text(triggerName)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            
            Spacer(minLength: 12)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(rankColor.opacity(0.6))
                        .frame(
                            width: max(geometry.size.width * (percentage / 100), 2),
                            height: 6
                        )
                }
            }
            .frame(width: 60, height: 6)
            
            // 次数和百分比
            HStack(spacing: 6) {
                Text("\(count)次")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(minWidth: 40, alignment: .trailing)
                
                Text("(\(String(format: "%.1f%%", percentage)))")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .frame(minWidth: 50, alignment: .leading)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.backgroundPrimary)
        .cornerRadius(10)
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
            return Color.accentPrimary
        }
    }
}

// MARK: - Calendar Grid Section

struct CalendarGridSection: View {
    @Bindable var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // 月份标题和导航
            monthHeader
            
            // 星期标题行
            weekdayHeader
            
            // 日期网格
            dateGrid
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
    }
    
    // MARK: - 月份标题
    
    private var monthHeader: some View {
        HStack {
            Button(action: viewModel.moveToPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text(viewModel.monthTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            Button(action: viewModel.moveToNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }
    
    // MARK: - 星期标题行
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, Spacing.sm)
    }
    
    // MARK: - 日期网格
    
    private var dateGrid: some View {
        let days = viewModel.getDaysInMonth()
        let rows = days.count / 7
        
        return VStack(spacing: Spacing.sm) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < days.count {
                            CalendarDayCell(
                                date: days[index],
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let viewModel: CalendarViewModel
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期数字
            Text(calendar.component(.day, from: date).description)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)
            
            // 疼痛强度指示器
            if let intensity = viewModel.getMaxPainIntensity(for: date) {
                Circle()
                    .fill(Color.painCategoryColor(for: intensity))
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(backgroundColor)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(isToday ? Color.primary : Color.clear, lineWidth: 2)
        )
    }
    
    private var isInCurrentMonth: Bool {
        viewModel.isDateInCurrentMonth(date)
    }
    
    private var isToday: Bool {
        viewModel.isToday(date)
    }
    
    private var textColor: Color {
        if !isInCurrentMonth {
            return Color.textTertiary
        } else if isToday {
            return Color.primary
        } else {
            return Color.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if viewModel.getAttacks(for: date).isEmpty {
            return Color.clear
        } else {
            return Color.surface.opacity(0.5)
        }
    }
}

// MARK: - Time Range Sheet View

struct TimeRangeSheetView: View {
    @Binding var selectedTimeRange: TimeRange
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("时间范围") {
                    Picker("筛选", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Label(range.displayName, systemImage: range.systemImage)
                                .tag(range)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    // 自定义日期范围选择器
                    if selectedTimeRange == .custom {
                        VStack(spacing: AppSpacing.small) {
                            DatePicker("开始日期", 
                                       selection: $customStartDate, 
                                       displayedComponents: .date)
                            DatePicker("结束日期", 
                                       selection: $customEndDate, 
                                       displayedComponents: .date)
                        }
                        .padding(.vertical, AppSpacing.small)
                    }
                }
            }
            .navigationTitle("筛选和排序")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Pain Intensity Legend

struct PainIntensityLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("疼痛强度图例")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textSecondary)
            
            HStack(spacing: 16) {
                // 轻度疼痛 (1-3)
                LegendItem(
                    intensity: 2,
                    label: "轻度",
                    range: "1-3"
                )
                
                // 中度疼痛 (4-6)
                LegendItem(
                    intensity: 5,
                    label: "中度",
                    range: "4-6"
                )
                
                // 重度疼痛 (7-10)
                LegendItem(
                    intensity: 8,
                    label: "重度",
                    range: "7-10"
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
    }
}

struct LegendItem: View {
    let intensity: Int
    let label: String
    let range: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.painCategoryColor(for: intensity))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                
                Text(range)
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
