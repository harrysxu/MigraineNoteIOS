//
//  AnalyticsView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData
import CoreData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    
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
    
    // 缓存批量分析结果，避免每次渲染重复计算
    @State private var cachedBatchAnalytics: BatchAnalyticsResult?
    // 防抖用的刷新任务
    @State private var analyticsRefreshTask: Task<Void, Never>?
    
    // 使用 FetchDescriptor 从数据库按时间范围加载的数据
    @State private var attacks: [AttackRecord] = []
    @State private var healthEvents: [HealthEvent] = []
    @State private var hasAnyData: Bool = false
    
    /// 数据版本号，用于监听 CloudKit 远程变化触发刷新
    @State private var dataVersion: Int = 0
    
    init(modelContext: ModelContext) {
        _analyticsEngine = State(initialValue: AnalyticsEngine(modelContext: modelContext))
        _mohDetector = State(initialValue: MOHDetector(modelContext: modelContext))
    }
    
    // MARK: - 数据加载（使用 FetchDescriptor + 谓词）
    
    /// 从数据库加载当前时间范围的数据
    private func loadFilteredData() {
        let (start, end) = currentDateRange
        
        // 加载发作记录
        let attackDescriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= start && attack.startTime <= end
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        attacks = (try? modelContext.fetch(attackDescriptor)) ?? []
        
        // 加载健康事件
        let eventDescriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= start && event.eventDate <= end
            },
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        healthEvents = (try? modelContext.fetch(eventDescriptor)) ?? []
        
        // 检查是否有任何数据
        checkHasAnyData()
    }
    
    /// 检查是否有任何数据（只查 1 条，用于空状态判断）
    private func checkHasAnyData() {
        var desc = FetchDescriptor<AttackRecord>()
        desc.fetchLimit = 1
        hasAnyData = ((try? modelContext.fetchCount(desc)) ?? 0) > 0
    }
    
    /// 带防抖的异步刷新：加载数据 + 计算分析缓存
    private func scheduleRefreshBatchAnalytics() {
        analyticsRefreshTask?.cancel()
        analyticsRefreshTask = Task {
            // 防抖：等待 300ms，如果被取消则不执行
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            // 在主线程加载数据（SwiftData 要求 ModelContext 在创建线程访问）
            loadFilteredData()
            let filtered = attacks
            let filteredEvents = healthEvents
            let dateRange = currentDateRange
            
            // 将重量级计算放到后台线程
            let result = await Task.detached(priority: .userInitiated) {
                BatchAnalyticsResult.compute(
                    attacks: filtered,
                    healthEvents: filteredEvents,
                    dateRange: dateRange
                )
            }.value
            
            guard !Task.isCancelled else { return }
            
            // 回到主线程更新 UI 状态
            await MainActor.run {
                cachedBatchAnalytics = result
            }
        }
    }
    
    /// 立即刷新（用于 onAppear 等不需要防抖的场景）
    private func refreshBatchAnalytics() {
        loadFilteredData()
        cachedBatchAnalytics = BatchAnalyticsResult.compute(
            attacks: attacks,
            healthEvents: healthEvents,
            dateRange: currentDateRange
        )
    }
    
    enum DataViewType: String, CaseIterable {
        case analytics
        case calendar
        
        var displayName: String {
            switch self {
            case .analytics: return String(localized: "analytics.view.chart")
            case .calendar: return String(localized: "calendar.title")
            }
        }
    }
    
    // 计算属性：获取当前选择的日期范围
    private var currentDateRange: (Date, Date) {
        selectedTimeRange.dateRange(customStart: customStartDate, customEnd: customEndDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 视图切换器
                Picker(String(localized: "analytics.view.data"), selection: $selectedView) {
                    ForEach(DataViewType.allCases, id: \.self) { viewType in
                        Text(viewType.displayName).tag(viewType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.backgroundPrimary)
                
                // 内容区域
                ZStack {
                    Color.backgroundPrimary.ignoresSafeArea()
                    
                    if !hasAnyData {
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
                            Text(String(localized: "calendar.today"))
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
            .sheet(isPresented: $showCSVShareSheet, onDismiss: {
                if let csvFileURL = csvFileURL {
                    try? FileManager.default.removeItem(at: csvFileURL)
                }
                csvFileURL = nil
            }) {
                if let csvFileURL = csvFileURL {
                    ShareSheet(activityItems: [csvFileURL]) {
                        showCSVShareSheet = false
                    }
                }
            }
            .alert(String(localized: "analytics.export.failed"), isPresented: $showExportErrorAlert) {
                Button(String(localized: "common.ok"), role: .cancel) { }
            } message: {
                Text(exportErrorMessage)
            }
        }
        .onAppear {
            // 仅在首次出现时初始化日历 ViewModel，避免重复创建
            if calendarViewModel == nil {
                calendarViewModel = CalendarViewModel(modelContext: modelContext)
            } else {
                calendarViewModel?.loadData()
            }
            // 刷新批量分析缓存
            refreshBatchAnalytics()
        }
        // 使用 .onReceive 替代 NotificationCenter.addObserver，自动管理生命周期
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToDataCalendarView"))) { _ in
            selectedView = .calendar
        }
        .onChange(of: selectedView) { _, newValue in
            if newValue == .calendar {
                calendarViewModel?.loadData()
            }
        }
        .onChange(of: selectedTimeRange) { _, _ in
            // 时间范围变化时刷新分析缓存（带防抖）
            scheduleRefreshBatchAnalytics()
        }
        .onChange(of: customStartDate) { _, _ in
            scheduleRefreshBatchAnalytics()
        }
        .onChange(of: customEndDate) { _, _ in
            scheduleRefreshBatchAnalytics()
        }
        // 监听远程数据变化（CloudKit 同步）
        .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
            dataVersion += 1
        }
        .onChange(of: dataVersion) { _, _ in
            calendarViewModel?.loadData()
            scheduleRefreshBatchAnalytics()
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
                Text(String(localized: "analytics.empty.record.3"))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                
                Text(String(localized: "analytics.empty.unlock"))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
            }
            
            Text(String(localized: "analytics.empty.hint"))
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, Spacing.xl)
    }
    
    // MARK: - Calendar Content
    
    @State private var selectedAttackFromCalendar: AttackRecord?
    @State private var selectedHealthEventFromCalendar: HealthEvent?
    
    private var calendarContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                if let viewModel = calendarViewModel {
                    // 月份统计卡片
                    if let stats = viewModel.monthlyStats {
                        MonthlyStatsCard(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    // 疼痛强度图例（支持点击切换过滤）
                    PainIntensityLegend(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // 日历网格
                    CalendarGridSection(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // 选中日期详情面板
                    if let selectedDate = viewModel.selectedDate {
                        SelectedDateDetailPanel(
                            date: selectedDate,
                            attacks: viewModel.getAttacks(for: selectedDate),
                            healthEvents: viewModel.getHealthEvents(for: selectedDate),
                            onAttackTap: { attack in
                                selectedAttackFromCalendar = attack
                            },
                            onHealthEventTap: { event in
                                selectedHealthEventFromCalendar = event
                            }
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedAttackFromCalendar) { attack in
            AttackDetailView(attack: attack)
        }
        .sheet(item: $selectedHealthEventFromCalendar) { event in
            HealthEventDetailView(event: event)
        }
    }
    
    // MARK: - Analytics Content
    
    private var analyticsContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
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
                
                // 用药统计（急性 vs 日常）
                medicationStatisticsSection
                
                // 健康事件统计
                healthEventStatisticsSection
                
                // 用药频次提醒
                mohRiskSection
                
                // 经期关联分析
                MenstrualCycleAnalyticsCard()
            }
            .padding(Spacing.md)
        }
        .id("\(selectedTimeRange.rawValue)_\(customStartDate)_\(customEndDate)")
    }
    
    // MARK: - 整体情况概览
    
    private var overallSummaryCard: some View {
        EmotionalCard(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 标题行
                HStack {
                    Text(String(localized: "analytics.overview"))
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
                
                // 统计数据网格
                let durationStats = cachedBatchAnalytics?.durationStats ?? DurationStatistics(averageDuration: 0, longestDuration: 0, shortestDuration: 0)
                let attackDays = getAttackDaysCount()
                let stats = getDetailedMedicationStats()
                let hasMOHRisk = stats.acuteMedicationDays >= 10
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.md) {
                    // 核心指标
                    StatItem(
                        title: String(localized: "stats.attack.days"),
                        value: "\(attackDays)",
                        icon: "calendar.badge.exclamationmark",
                        color: Color.statusWarning
                    )
                    
                    StatItem(
                        title: String(localized: "stats.attack.count"),
                        value: "\(getTotalAttacksCount())",
                        icon: "exclamationmark.triangle.fill",
                        color: Color.statusError
                    )
                    
                    StatItem(
                        title: String(localized: "stats.avg.duration"),
                        value: String(format: "%.1fh", durationStats.averageDurationHours),
                        icon: "clock.fill",
                        color: Color.accentSecondary
                    )
                    
                    StatItem(
                        title: String(localized: "stats.avg.intensity"),
                        value: String(format: "%.1f", getAveragePainIntensity()),
                        icon: "waveform.path.ecg",
                        color: Color.painCategoryColor(for: Int(getAveragePainIntensity()))
                    )
                    
                    // 急性用药（始终显示）
                    StatItem(
                        title: String(localized: "stats.acute.days"),
                        value: "\(stats.acuteMedicationDays)",
                        icon: "calendar.badge.clock",
                        color: hasMOHRisk ? Color.statusWarning : Color.statusSuccess
                    )
                    
                    StatItem(
                        title: String(localized: "stats.acute.count"),
                        value: "\(stats.acuteMedicationCount)",
                        icon: "pills.fill",
                        color: hasMOHRisk ? Color.statusWarning : Color.accentPrimary
                    )
                    
                    // 日常用药（有数据时显示）
                    if stats.hasPreventiveMedication {
                        StatItem(
                            title: String(localized: "stats.preventive.days"),
                            value: "\(stats.preventiveMedicationDays)",
                            icon: "calendar.badge.plus",
                            color: Color.accentPrimary
                        )
                        
                        StatItem(
                            title: String(localized: "stats.preventive.count"),
                            value: "\(stats.preventiveMedicationCount)",
                            icon: "pills.circle.fill",
                            color: Color.accentPrimary
                        )
                    }
                    
                    // 中医治疗（有数据时显示）
                    if stats.hasTCMTreatment {
                        StatItem(
                            title: String(localized: "stats.tcm.count"),
                            value: "\(stats.tcmTreatmentCount)",
                            icon: "leaf.circle.fill",
                            color: Color.statusSuccess
                        )
                    }
                    
                    // 手术（有数据时显示）
                    if stats.hasSurgery {
                        StatItem(
                            title: String(localized: "stats.surgery.count"),
                            value: "\(stats.surgeryCount)",
                            icon: "cross.case.circle.fill",
                            color: Color.statusInfo
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - MOH Risk Section
    
    private var mohRiskSection: some View {
        let totalDays = getMedicationDaysForRange()
        let monthCount = getMonthCountForRange()
        let isMultiMonth = monthCount > 1
        // 多月时显示月均值，单月时显示总天数
        let monthlyAvg = isMultiMonth ? Double(totalDays) / Double(monthCount) : Double(totalDays)
        let displayDays = isMultiMonth ? Int(round(monthlyAvg)) : totalDays
        let isWarning = monthlyAvg >= 10.0
        
        let rangeLabel = isMultiMonth ? String(localized: "analytics.moh.range.monthly") : String(localized: "analytics.moh.range.this.month")
        let thresholdText = isMultiMonth ? String(localized: "analytics.moh.threshold.monthly") : String(localized: "analytics.moh.threshold.this.month")
        let warningText = isMultiMonth
            ? String(localized: "analytics.moh.warning.multi")
            : String(localized: "analytics.moh.warning.single")
        
        return EmotionalCard(style: isWarning ? .warning : .default) {
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                HStack(spacing: 8) {
                    Image(systemName: "pills.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isWarning ? Color.statusWarning : Color.accentPrimary)
                    Text(String(localized: "analytics.moh.reminder.title"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                }
                
                // 用药天数 - 横向布局
                HStack(spacing: 20) {
                    // 左侧数值
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rangeLabel)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(displayDays)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(isWarning ? Color.statusWarning : Color.accentPrimary)
                            
                            Text(String(localized: "form.unit.day"))
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
                                        .fill(isWarning ? Color.statusWarning : Color.accentPrimary)
                                        .frame(
                                            width: geometry.size.width * min(monthlyAvg / 15.0, 1.0),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                            
                            Text(thresholdText)
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
                            .trim(from: 0, to: min(monthlyAvg / 15.0, 1.0))
                            .stroke(
                                isWarning ? Color.statusWarning : Color.accentPrimary,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))
                        
                        Text(String(format: "%.0f%%", min(monthlyAvg / 10.0 * 100, 100)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                
                // 提醒说明
                if isWarning {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.statusWarning)
                        
                        Text(warningText)
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
                    Text(String(localized: "analytics.monthly.trend"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let monthlyData = getMonthlyTrendData()
                
                if monthlyData.isEmpty {
                    Text(String(localized: "analytics.data.insufficient"))
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Chart {
                        ForEach(monthlyData) { item in
                            BarMark(
                                x: .value(String(localized: "chart.month"), item.monthName),
                                y: .value(String(localized: "chart.attack.days"), item.attackDays)
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
                    Text(String(localized: "analytics.trigger.freq"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let triggerData = cachedBatchAnalytics?.triggerFrequency ?? []
                
                if triggerData.isEmpty {
                    Text(String(localized: "analytics.no.trigger.data"))
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
                    Text(String(localized: "analytics.attack.time.dist"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let circadianData = cachedBatchAnalytics?.circadianPattern ?? []
                
                if circadianData.isEmpty {
                    Text(String(localized: "analytics.data.insufficient"))
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    Chart {
                        ForEach(circadianData) { item in
                            AreaMark(
                                x: .value(String(localized: "chart.hour"), item.hour),
                                yStart: .value(String(localized: "chart.start"), 0),
                                yEnd: .value(String(localized: "chart.count"), item.count)
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
                                x: .value(String(localized: "chart.hour"), item.hour),
                                y: .value(String(localized: "chart.count"), item.count)
                            )
                            .foregroundStyle(Color.accentPrimary)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value(String(localized: "chart.hour"), item.hour),
                                y: .value(String(localized: "chart.count"), item.count)
                            )
                            .foregroundStyle(Color.accentPrimary)
                            .symbolSize(60)
                        }
                    }
                    .frame(height: 180)
                    .chartXScale(domain: 0...23)
                    .chartXAxis {
                        AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                            AxisValueLabel {
                                if let hour = value.as(Int.self) {
                                    Text(String(format: String(localized: "chart.hour.format"), hour))
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
                        Text(String(format: String(localized: "analytics.peak.hour"), peakHour.hour, peakHour.hour + 1))
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
                    Text(String(localized: "analytics.pain.assessment"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let intensityDist = cachedBatchAnalytics?.painIntensityDistribution ?? PainIntensityDistribution(mild: 0, moderate: 0, severe: 0)
                let locationFreq = cachedBatchAnalytics?.painLocationFrequency ?? []
                let qualityFreq = cachedBatchAnalytics?.painQualityFrequency ?? []
                
                // 疼痛强度分布
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "analytics.pain.intensity.dist"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    if intensityDist.total > 0 {
                        VStack(spacing: 8) {
                            IntensityBar(
                                label: String(localized: "analytics.pain.mild"),
                                count: intensityDist.mild,
                                percentage: intensityDist.mildPercentage,
                                color: .statusSuccess
                            )
                            
                            IntensityBar(
                                label: String(localized: "analytics.pain.moderate"),
                                count: intensityDist.moderate,
                                percentage: intensityDist.moderatePercentage,
                                color: .statusWarning
                            )
                            
                            IntensityBar(
                                label: String(localized: "analytics.pain.severe"),
                                count: intensityDist.severe,
                                percentage: intensityDist.severePercentage,
                                color: .statusError
                            )
                        }
                    } else {
                        Text(String(localized: "analytics.no.data"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                if !locationFreq.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    // 疼痛部位频次 Top 5
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "analytics.pain.location.freq"))
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
                        Text(String(localized: "analytics.pain.quality.freq"))
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
                    Text(String(localized: "analytics.symptom.stats"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let symptomFreq = cachedBatchAnalytics?.symptomFrequency ?? []
                let auraStats = cachedBatchAnalytics?.auraStatistics ?? AuraStatistics(totalAttacks: 0, attacksWithAura: 0, auraTypeFrequency: [])
                
                // 伴随症状频次
                if !symptomFreq.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
Text(String(localized: "analytics.symptom.freq"))
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
                    Text(String(localized: "analytics.no.symptom.data"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                // 先兆统计
                if auraStats.totalAttacks > 0 {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
Text(String(localized: "analytics.aura.stats"))
                        .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        
                        HStack {
                            Text(String(localized: "analytics.aura.attacks"))
                                .font(.body)
                                .foregroundStyle(Color.textPrimary)
                            
                            Spacer()
                            
                            Text(String(format: String(localized: "form.unit.count.short"), auraStats.attacksWithAura))
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
    
    // MARK: - 用药统计（急性用药 vs 日常用药）
    
    private var medicationStatisticsSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "cross.case.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text(String(localized: "analytics.medication.stats"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let acuteStats = cachedBatchAnalytics?.acuteMedicationUsage ?? MedicationUsageStatistics(totalMedicationUses: 0, medicationDays: 0, categoryBreakdown: [], topMedications: [])
                let healthEventStats = cachedBatchAnalytics?.healthEventStatistics ?? .empty
                
                let hasAcute = acuteStats.totalMedicationUses > 0
                let hasDaily = healthEventStats.hasDailyMedication
                
                if hasAcute || hasDaily {
                    // === 急性用药（发作期间） ===
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.heart.fill")
                                .font(.caption)
                                .foregroundStyle(Color.statusWarning)
                            Text(String(localized: "analytics.acute.medication"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        if hasAcute {
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "analytics.medication.count"))
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Text(String(format: String(localized: "form.unit.count.short"), acuteStats.totalMedicationUses))
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.statusWarning)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "analytics.medication.days"))
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Text("\(acuteStats.medicationDays) \(String(localized: "form.unit.day"))")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.statusWarning)
                                }
                            }
                            
                            // 急性用药分类
                            if !acuteStats.categoryBreakdown.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(acuteStats.categoryBreakdown) { category in
                                        FrequencyRow(
                                            name: category.categoryName,
                                            count: category.count,
                                            percentage: category.percentage
                                        )
                                    }
                                }
                            }
                            
                            // 急性用药 Top 药物
                            if !acuteStats.topMedications.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(Array(acuteStats.topMedications.prefix(3))) { medication in
                                        FrequencyRow(
                                            name: medication.medicationName,
                                            count: medication.count,
                                            percentage: medication.percentage
                                        )
                                    }
                                }
                            }
                        } else {
                            Text(String(localized: "analytics.no.acute.med"))
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // === 日常用药 ===
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "pills.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.accentPrimary)
                            Text(String(localized: "analytics.daily.medication"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        if hasDaily {
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "analytics.medication.count"))
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Text(String(format: String(localized: "form.unit.count.short"), healthEventStats.dailyMedicationCount))
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.accentPrimary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(localized: "analytics.medication.days"))
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Text("\(healthEventStats.dailyMedicationDays) \(String(localized: "form.unit.day"))")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            
                            // 日常用药分类
                            if !healthEventStats.dailyMedCategories.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(healthEventStats.dailyMedCategories) { category in
                                        FrequencyRow(
                                            name: category.categoryName,
                                            count: category.count,
                                            percentage: category.percentage
                                        )
                                    }
                                }
                            }
                            
                            // 日常用药 Top 药物
                            if !healthEventStats.dailyTopMedications.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(Array(healthEventStats.dailyTopMedications.prefix(3))) { medication in
                                        FrequencyRow(
                                            name: medication.medicationName,
                                            count: medication.count,
                                            percentage: medication.percentage
                                        )
                                    }
                                }
                            }
                        } else {
                            Text(String(localized: "analytics.no.daily.med"))
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                } else {
                    Text(String(localized: "analytics.no.medication.data"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    // MARK: - 健康事件统计
    
    private var healthEventStatisticsSection: some View {
        let healthStats = cachedBatchAnalytics?.healthEventStatistics ?? .empty
        
        return Group {
            if healthStats.hasAnyEvent {
                EmotionalCard(style: .default) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundStyle(Color.accentPrimary)
                            Text(String(localized: "analytics.health.event.stats"))
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        // 事件总览
                        HStack(spacing: 0) {
                            if healthStats.hasDailyMedication {
                                HealthEventSummaryItem(
                                    icon: "pills.circle.fill",
                                    label: String(localized: "analytics.daily.medication"),
                                    value: "\(healthStats.dailyMedicationCount)\(String(localized: "form.unit.count"))",
                                    color: .accentPrimary
                                )
                            }
                            
                            if healthStats.hasTCMTreatment {
                                HealthEventSummaryItem(
                                    icon: "leaf.circle.fill",
                                    label: String(localized: "health.event.type.tcmTreatment"),
                                    value: "\(healthStats.tcmTreatmentCount)\(String(localized: "form.unit.count"))",
                                    color: .statusSuccess
                                )
                            }
                            
                            if healthStats.hasSurgery {
                                HealthEventSummaryItem(
                                    icon: "cross.case.circle.fill",
                                    label: String(localized: "health.event.type.surgery"),
                                    value: "\(healthStats.surgeryCount)\(String(localized: "form.unit.count"))",
                                    color: .statusInfo
                                )
                            }
                        }
                        
                        // 中医治疗详情
                        if healthStats.hasTCMTreatment {
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "leaf.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.statusSuccess)
                                    Text(String(localized: "analytics.tcm.detail"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.textPrimary)
                                }
                                
                                if healthStats.averageTcmDurationMinutes > 0 {
                                    HStack {
                                        Text(String(localized: "analytics.avg.treatment.duration"))
                                            .font(.caption)
                                            .foregroundStyle(Color.textSecondary)
                                        Spacer()
                                        Text("\(healthStats.averageTcmDurationMinutes)\(String(localized: "form.duration.minute"))")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(Color.textPrimary)
                                    }
                                }
                                
                                if !healthStats.tcmTreatmentTypes.isEmpty {
                                    VStack(spacing: 8) {
                                        ForEach(healthStats.tcmTreatmentTypes) { type in
                                            FrequencyRow(
                                                name: type.typeName,
                                                count: type.count,
                                                percentage: type.percentage
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 手术详情
                        if healthStats.hasSurgery {
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "cross.case.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.statusInfo)
                                    Text(String(localized: "analytics.surgery.record"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.textPrimary)
                                }
                                
                                ForEach(healthStats.surgeryDetails) { surgery in
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(surgery.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Color.textPrimary)
                                            
                                            HStack(spacing: 8) {
                                                Text(surgery.date.fullDate())
                                                    .font(.caption)
                                                    .foregroundStyle(Color.textSecondary)
                                                
                                                if let hospital = surgery.hospital {
                                                    Text(hospital)
                                                        .font(.caption)
                                                        .foregroundStyle(Color.textSecondary)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color.backgroundPrimary)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
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
        
        // 预先按月份分组，避免对每个月都遍历全部数据（O(n) 替代 O(n*m)）
        var attacksByMonth: [Int: [AttackRecord]] = [:]  // key: year*100+month
        for attack in attacks {
            let comps = calendar.dateComponents([.year, .month], from: attack.startTime)
            if let y = comps.year, let m = comps.month {
                let key = y * 100 + m
                attacksByMonth[key, default: []].append(attack)
            }
        }
        
        for monthOffset in (0..<monthsToShow).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: end) else { continue }
            
            let comps = calendar.dateComponents([.year, .month], from: monthDate)
            let key = (comps.year ?? 0) * 100 + (comps.month ?? 0)
            let monthAttacks = attacksByMonth[key] ?? []
            
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
    
    // MARK: - 从缓存读取预计算的统计数据（避免重复遍历）
    
    /// 返回已按时间范围从数据库加载的发作记录（数据已在 loadFilteredData 中用谓词过滤）
    private func filterAttacksInRange() -> [AttackRecord] {
        return attacks
    }
    
    /// 返回已按时间范围从数据库加载的健康事件（数据已在 loadFilteredData 中用谓词过滤）
    private func filterHealthEventsInRange() -> [HealthEvent] {
        return healthEvents
    }
    
    private func getDetailedMedicationStats() -> DetailedMedicationStatistics {
        cachedBatchAnalytics?.detailedMedicationStats ?? .empty
    }
    
    private func getTotalAttacksCount() -> Int {
        cachedBatchAnalytics?.totalAttacksCount ?? 0
    }
    
    private func getAttackDaysCount() -> Int {
        cachedBatchAnalytics?.attackDaysCount ?? 0
    }
    
    private func getAveragePainIntensity() -> Double {
        cachedBatchAnalytics?.averagePainIntensity ?? 0
    }
    
    /// 获取选中时间范围内的急性用药天数
    private func getMedicationDaysForRange() -> Int {
        cachedBatchAnalytics?.detailedMedicationStats.acuteMedicationDays ?? 0
    }
    
    /// 获取选中时间范围的月份数（至少为1）
    private func getMonthCountForRange() -> Int {
        let calendar = Calendar.current
        let (start, end) = currentDateRange
        let components = calendar.dateComponents([.month, .day], from: start, to: end)
        let months = components.month ?? 0
        // 有剩余天数则向上取整
        return max(1, months + ((components.day ?? 0) > 0 ? 1 : 0))
    }

    // MARK: - 中医治疗统计
    
    private var tcmTreatmentStatisticsSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "leaf.circle.fill")
                        .foregroundStyle(Color.statusSuccess)
                    Text(String(localized: "analytics.tcm.title"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                let tcmStats = cachedBatchAnalytics?.tcmTreatmentStats ?? TCMTreatmentStats(totalTreatments: 0, treatmentTypes: [])
                
                if tcmStats.totalTreatments > 0 {
                    VStack(spacing: 12) {
                        // 总治疗次数
                        HStack {
                            Text(String(localized: "analytics.tcm.total.treatments"))
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(tcmStats.totalTreatments)\(String(localized: "analytics.tcm.count.suffix"))")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        if tcmStats.averageDurationMinutes > 0 {
                            HStack {
                                Text(String(localized: "analytics.tcm.avg.duration"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                                Spacer()
                                Text("\(tcmStats.averageDurationMinutes)\(String(localized: "analytics.treatment.minute.suffix"))")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                        
                        // 治疗类型分布
                        if !tcmStats.treatmentTypes.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "analytics.tcm.type.distribution"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)
                                
                                ForEach(tcmStats.treatmentTypes) { type in
                                    FrequencyRow(
                                        name: type.typeName,
                                        count: type.count,
                                        percentage: type.percentage
                                    )
                                }
                            }
                        }
                    }
                } else {
                    Text(String(localized: "analytics.tcm.no.records"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    // MARK: - 治疗效果关联分析
    
    private var treatmentCorrelationSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.accentPrimary)
                    Text(String(localized: "analytics.effectiveness.title"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                }
                
                // 分析用药治疗的效果
                if let medicationCorrelation = analyticsEngine.analyzeCorrelationBetweenTreatmentAndAttacks(
                    treatmentType: .medication,
                    beforeDays: 30,
                    afterDays: 30
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "analytics.effectiveness.after.medication"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textSecondary)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "analytics.effectiveness.before.30days"))
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                                Text("\(medicationCorrelation.beforeAttackDays)\(String(localized: "analytics.effectiveness.attack.days.suffix"))")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)
                            }
                            
                            Image(systemName: "arrow.right")
                                .foregroundStyle(Color.textTertiary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "analytics.effectiveness.after.30days"))
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                                Text("\(medicationCorrelation.afterAttackDays)\(String(localized: "analytics.effectiveness.attack.days.suffix"))")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(medicationCorrelation.hasImprovement ? Color.statusSuccess : Color.textPrimary)
                            }
                        }
                        
                        if medicationCorrelation.hasImprovement {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.statusSuccess)
                                Text(String(format: String(localized: "analytics.effectiveness.reduction.format"), medicationCorrelation.attackDaysReduction))
                                    .font(.caption)
                                    .foregroundStyle(Color.statusSuccess)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.statusSuccess.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // 分析中医治疗的效果
                if let tcmCorrelation = analyticsEngine.analyzeCorrelationBetweenTreatmentAndAttacks(
                    treatmentType: .tcmTreatment,
                    beforeDays: 30,
                    afterDays: 30
                ) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "analytics.effectiveness.after.tcm"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textSecondary)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "analytics.effectiveness.before.30days"))
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                                Text("\(tcmCorrelation.beforeAttackDays)\(String(localized: "analytics.effectiveness.attack.days.suffix"))")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)
                            }
                            
                            Image(systemName: "arrow.right")
                                .foregroundStyle(Color.textTertiary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "analytics.effectiveness.after.30days"))
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                                Text("\(tcmCorrelation.afterAttackDays)\(String(localized: "analytics.effectiveness.attack.days.suffix"))")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(tcmCorrelation.hasImprovement ? Color.statusSuccess : Color.textPrimary)
                            }
                        }
                        
                        if tcmCorrelation.hasImprovement {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.statusSuccess)
                                Text(String(format: String(localized: "analytics.effectiveness.reduction.format"), tcmCorrelation.attackDaysReduction))
                                    .font(.caption)
                                    .foregroundStyle(Color.statusSuccess)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.statusSuccess.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
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
                Text(String(format: String(localized: "form.unit.count.short"), count))
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
                Text(String(format: String(localized: "form.unit.count.short"), count))
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

/// 健康事件总览项
struct HealthEventSummaryItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(value)
                .font(.body.weight(.bold))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable, Identifiable {
    case thisMonth
    case threeMonths
    case sixMonths
    case oneYear
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .thisMonth: return String(localized: "time.range.this.month")
        case .threeMonths: return String(localized: "time.range.3months")
        case .sixMonths: return String(localized: "time.range.6months")
        case .oneYear: return String(localized: "time.range.1year")
        case .custom: return String(localized: "time.range.custom")
        }
    }
    
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
            // 本月：完整月份（与日历统计保持一致）
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let endOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextMonth)!
            return (startOfMonth, endOfMonth)
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
                // 规范化自定义日期范围，确保包含完整的结束日期
                let normalized = Date.normalizedDateRange(start: customStart, end: customEnd)
                return (normalized.start, normalized.end)
            }
            // 默认返回本月
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (startOfMonth, now)
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
                Text(String(format: String(localized: "form.unit.count.short"), count))
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
        EmotionalCard(style: .default) {
            VStack(spacing: Spacing.md) {
                // 月份标题和导航
                monthHeader
                
                // 星期标题行
                weekdayHeader
                
                // 日期网格
                dateGrid
            }
        }
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
            ForEach([String(localized: "calendar.weekday.sun"), String(localized: "calendar.weekday.mon"), String(localized: "calendar.weekday.tue"), String(localized: "calendar.weekday.wed"), String(localized: "calendar.weekday.thu"), String(localized: "calendar.weekday.fri"), String(localized: "calendar.weekday.sat")], id: \.self) { weekday in
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
    
    private var isSelected: Bool {
        if let selectedDate = viewModel.selectedDate {
            return calendar.isDate(date, inSameDayAs: selectedDate)
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期数字
            Text(calendar.component(.day, from: date).description)
                .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
                .foregroundStyle(textColor)
            
            // 指示器（头痛记录 + 健康事件），根据图例过滤状态显示
            HStack(spacing: 3) {
                // 头痛记录指示器（根据过滤状态显示）
                if let intensity = viewModel.getFilteredPainIntensity(for: date) {
                    Circle()
                        .fill(Color.painCategoryColor(for: intensity))
                        .frame(width: 6, height: 6)
                }
                
                // 健康事件指示器（根据过滤状态按类型显示）
                ForEach(Array(viewModel.getFilteredHealthEventTypes(for: date)), id: \.self) { eventType in
                    Circle()
                        .fill(healthEventColor(for: eventType))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 6) // 固定高度，避免布局跳动
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(backgroundColor)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(borderColor, lineWidth: isSelected ? 2 : (isToday ? 1.5 : 0))
        )
        .onTapGesture {
            if viewModel.isDateInCurrentMonth(date) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isSelected {
                        viewModel.selectedDate = nil
                    } else {
                        viewModel.selectedDate = date
                    }
                }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        }
    }
    
    private var isInCurrentMonth: Bool {
        viewModel.isDateInCurrentMonth(date)
    }
    
    private var isToday: Bool {
        viewModel.isToday(date)
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if !isInCurrentMonth {
            return Color.textTertiary
        } else if isToday {
            return Color.accentPrimary
        } else {
            return Color.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentPrimary
        } else if !viewModel.getAttacks(for: date).isEmpty {
            return Color.surface.opacity(0.5)
        } else if !viewModel.getHealthEvents(for: date).isEmpty {
            return Color.surface.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.accentPrimary
        } else if isToday {
            return Color.accentPrimary.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private func healthEventColor(for eventType: HealthEventType) -> Color {
        switch eventType {
        case .medication: return .accentPrimary
        case .tcmTreatment: return .statusSuccess
        case .surgery: return .statusInfo
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
                Section(String(localized: "filter.time.range")) {
                    Picker(String(localized: "common.filter"), selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Label(range.displayName, systemImage: range.systemImage)
                                .tag(range)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    // 自定义日期范围选择器
                    if selectedTimeRange == .custom {
                        VStack(spacing: AppSpacing.small) {
                            DatePicker(String(localized: "form.start.date"), 
                                       selection: $customStartDate, 
                                       displayedComponents: .date)
                            DatePicker(String(localized: "form.end.date"), 
                                       selection: $customEndDate, 
                                       displayedComponents: .date)
                        }
                        .padding(.vertical, AppSpacing.small)
                    }
                }
            }
            .navigationTitle(String(localized: "filter.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "common.done")) {
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
    @Bindable var viewModel: CalendarViewModel
    
    var body: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "calendar.pain.legend"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                
                HStack(spacing: 16) {
                    // 轻度疼痛 (1-3)
                    LegendItem(
                        intensity: 2,
                        label: String(localized: "analytics.pain.mild.short"),
                        range: "1-3",
                        isSelected: viewModel.showMildPain
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showMildPain.toggle()
                        }
                    }
                    
                    // 中度疼痛 (4-6)
                    LegendItem(
                        intensity: 5,
                        label: String(localized: "analytics.pain.moderate.short"),
                        range: "4-6",
                        isSelected: viewModel.showModeratePain
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showModeratePain.toggle()
                        }
                    }
                    
                    // 重度疼痛 (7-10)
                    LegendItem(
                        intensity: 8,
                        label: String(localized: "analytics.pain.severe.short"),
                        range: "7-10",
                        isSelected: viewModel.showSeverePain
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showSeverePain.toggle()
                        }
                    }
                }
                
                Divider()
                
                Text(String(localized: "calendar.event.legend"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                
                HStack(spacing: 16) {
                    EventLegendItem(
                        color: .accentPrimary,
                        label: String(localized: "analytics.daily.medication"),
                        isSelected: viewModel.showMedication
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showMedication.toggle()
                        }
                    }
                    
                    EventLegendItem(
                        color: .statusSuccess,
                        label: String(localized: "health.event.type.tcmTreatment"),
                        isSelected: viewModel.showTCMTreatment
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showTCMTreatment.toggle()
                        }
                    }
                    
                    EventLegendItem(
                        color: .statusInfo,
                        label: String(localized: "health.event.type.surgery"),
                        isSelected: viewModel.showSurgery
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showSurgery.toggle()
                        }
                    }
                }
            }
        }
    }
}

struct EventLegendItem: View {
    let color: Color
    let label: String
    var isSelected: Bool = true
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isSelected ? color : color.opacity(0.3))
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? Color.textPrimary : Color.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.clear : Color.backgroundTertiary.opacity(0.5))
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

struct LegendItem: View {
    let intensity: Int
    let label: String
    let range: String
    var isSelected: Bool = true
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isSelected ? Color.painCategoryColor(for: intensity) : Color.painCategoryColor(for: intensity).opacity(0.3))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.textPrimary : Color.textTertiary)
                
                Text(range)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.textTertiary : Color.textTertiary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(isSelected ? Color.clear : Color.backgroundTertiary.opacity(0.5))
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
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
