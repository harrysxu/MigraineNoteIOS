//
//  TestDataView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

#if DEBUG

/// 测试数据填充和管理视图 - 仅在 Debug 模式下可用
struct TestDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var premiumManager = PremiumManager.shared
    
    // 发作记录参数
    @State private var monthCount: Int = 6
    @State private var attacksPerMonth: Int = 4
    @State private var avgDuration: Double = 4.0
    @State private var durationVariance: Double = 2.0
    
    // 药箱参数
    @State private var medicationCount: Int = 10
    
    // 自定义标签参数
    @State private var customLabelCount: Int = 10
    
    // 健康事件参数
    @State private var healthEventCount: Int = 30
    @State private var healthEventDayRange: Int = 30
    
    // 数据统计
    @State private var statistics: DataStatistics?
    
    // 操作状态
    @State private var isGenerating = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    
    // 清空数据确认流程
    @State private var showClearAllAlert = false
    @State private var showClearConfirmInput = false
    @State private var clearInputText = ""
    @State private var showFinalConfirmation = false
    @State private var showSelectiveClear = false
    
    // 延迟初始化的 manager
    private var manager: TestDataManager {
        TestDataManager(modelContext: modelContext)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // 警告提示
                warningCard
                
                // 高级版测试开关
                premiumTestCard
                
                // 数据预览
                statisticsCard
                
                // 发作记录配置
                attackRecordSection
                
                // 药箱配置
                medicationSection
                
                // 自定义标签配置
                customLabelSection
                
                // 健康事件配置
                healthEventSection
                
                // 用户档案配置
                userProfileSection
                
                // 危险操作区
                dangerZone
            }
            .padding(Spacing.md)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(String(localized: "test.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    refreshStatistics()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            refreshStatistics()
        }
        .alert(String(localized: "test.alert.success"), isPresented: $showSuccessAlert) {
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert(String(localized: "test.alert.confirmClear"), isPresented: $showClearAllAlert) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "common.continue"), role: .destructive) {
                showClearConfirmInput = true
            }
        } message: {
            Text(String(localized: "test.clearConfirmMessage"))
        }
        .sheet(isPresented: $showClearConfirmInput) {
            clearConfirmInputSheet
        }
        .alert(String(localized: "test.alert.finalConfirm"), isPresented: $showFinalConfirmation) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                clearInputText = ""
            }
            Button(String(localized: "test.clearAllData"), role: .destructive) {
                performClearAll()
            }
        } message: {
            if let stats = statistics {
                Text(String(format: String(localized: "test.deleteStatsDetail"), stats.recordCount, stats.medicationCount, stats.customLabelCount, stats.healthEventCount, stats.userProfileCount, stats.medicationLogCount))
            } else {
                Text(String(localized: "test.deleteAllWarning"))
            }
        }
        .confirmationDialog(String(localized: "test.selectiveClearTitle"), isPresented: $showSelectiveClear) {
            Button(String(localized: "test.clearRecords"), role: .destructive) {
                confirmAndClear(.records)
            }
            Button(String(localized: "test.clearMedications"), role: .destructive) {
                confirmAndClear(.medications)
            }
            Button(String(localized: "test.clearCustomLabels"), role: .destructive) {
                confirmAndClear(.customLabels)
            }
            Button(String(localized: "test.clearHealthEvents"), role: .destructive) {
                confirmAndClear(.healthEvents)
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        }
    }
    
    // MARK: - 组件
    
    /// 警告提示卡片
    private var warningCard: some View {
        EmotionalCard(style: .warning) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.statusWarning)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "test.environment"))
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(String(localized: "test.environmentHint"))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    /// 高级版测试卡片
    private var premiumTestCard: some View {
        EmotionalCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "crown.fill",
                    title: String(localized: "test.premiumTest"),
                    color: .orange
                )
                
                Toggle(isOn: Binding(
                    get: { premiumManager.debugPremiumOverride ?? false },
                    set: { newValue in
                        premiumManager.debugPremiumOverride = newValue
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "test.simulatePremium"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textPrimary)
                        Text(String(localized: "test.simulatePremiumHint"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .tint(Color.orange)
                
                // 当前状态显示
                HStack {
                    Text(String(localized: "test.currentStatus"))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(premiumManager.isPremium ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(premiumManager.isPremium ? String(localized: "test.premium") : String(localized: "test.free"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(premiumManager.isPremium ? Color.green : Color.textSecondary)
                    }
                }
                .padding(12)
                .background(Color.backgroundPrimary)
                .cornerRadius(10)
                
                // 覆盖状态说明
                if premiumManager.debugPremiumOverride != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.blue)
                        Text(String(localized: "test.debugModeHint"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button {
                        premiumManager.debugPremiumOverride = nil
                    } label: {
                        Text(String(localized: "test.resetToReal"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    /// 数据统计卡片
    private var statisticsCard: some View {
        EmotionalCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(String(localized: "test.currentStats"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    if let stats = statistics {
                        Text(String(format: String(localized: "test.statsTotal"), stats.recordCount + stats.medicationCount + stats.customLabelCount + stats.healthEventCount + stats.userProfileCount))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                if let stats = statistics {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            statisticItem(
                                icon: "list.bullet.clipboard",
                                title: String(localized: "test.stat.records"),
                                count: stats.recordCount,
                                color: .accentPrimary
                            )
                            
                            statisticItem(
                                icon: "cross.case.fill",
                                title: String(localized: "test.stat.medications"),
                                count: stats.medicationCount,
                                color: .blue
                            )
                        }
                        
                        HStack(spacing: 12) {
                            statisticItem(
                                icon: "tag.fill",
                                title: String(localized: "test.stat.labels"),
                                count: stats.customLabelCount,
                                color: .purple
                            )
                            
                            statisticItem(
                                icon: "heart.text.square.fill",
                                title: String(localized: "test.stat.healthEvents"),
                                count: stats.healthEventCount,
                                color: .green
                            )
                        }
                        
                        HStack(spacing: 12) {
                            statisticItem(
                                icon: "person.circle.fill",
                                title: String(localized: "test.stat.userProfiles"),
                                count: stats.userProfileCount,
                                color: .orange
                            )
                            
                            statisticItem(
                                icon: "pills.fill",
                                title: String(localized: "test.stat.medicationLogs"),
                                count: stats.medicationLogCount,
                                color: .cyan
                            )
                        }
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    /// 统计项
    private func statisticItem(icon: String, title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(Color.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
    
    /// 发作记录配置区
    private var attackRecordSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "list.bullet.clipboard.fill",
                    title: String(localized: "test.attackRecordTitle"),
                    color: .accentPrimary
                )
                
                VStack(alignment: .leading, spacing: 20) {
                    // 月份数
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "test.monthCount"))
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: String(localized: "test.monthsFormat"), monthCount))
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(monthCount) },
                            set: { monthCount = Int($0) }
                        ), in: 1...24, step: 1)
                        .tint(Color.accentPrimary)
                        
                        Text(String(format: String(localized: "test.generatePastMonths"), monthCount))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 每月频次
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "test.attacksPerMonth"))
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: String(localized: "test.timesFormat"), attacksPerMonth))
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(attacksPerMonth) },
                            set: { attacksPerMonth = Int($0) }
                        ), in: 1...15, step: 1)
                        .tint(Color.accentPrimary)
                        
                        Text(String(format: String(localized: "test.attacksPerMonthHint"), attacksPerMonth, monthCount * attacksPerMonth))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 平均持续时长
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "test.avgDuration"))
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: "%.1f 小时", avgDuration))
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: $avgDuration, in: 1...24, step: 0.5)
                            .tint(Color.accentPrimary)
                        
                        Text(String(format: String(localized: "test.avgDurationHint"), avgDuration))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 时长变化范围
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "test.durationVariance"))
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: "±%.1f 小时", durationVariance))
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: $durationVariance, in: 0...12, step: 0.5)
                            .tint(Color.accentPrimary)
                        
                        Text(String(format: String(localized: "test.durationVarianceHint"), max(0.5, avgDuration - durationVariance), avgDuration + durationVariance))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                
                PrimaryButton(title: isGenerating ? String(localized: "test.generating") : String(localized: "test.generateRecords"), action: generateAttackRecords, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 药箱配置区
    private var medicationSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "cross.case.fill",
                    title: String(localized: "test.medicationTitle"),
                    color: .blue
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "test.medicationCount"))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(String(format: String(localized: "test.kindsFormat"), medicationCount))
                            .font(.subheadline)
                            .foregroundStyle(Color.blue)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(medicationCount) },
                        set: { medicationCount = Int($0) }
                    ), in: 5...30, step: 1)
                    .tint(Color.blue)
                    
                    Text(String(format: String(localized: "test.generateMedicationsHint"), medicationCount))
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                
                PrimaryButton(title: isGenerating ? String(localized: "test.generating") : String(localized: "test.generateMedications"), action: generateMedications, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 自定义标签配置区
    private var customLabelSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "tag.fill",
                    title: String(localized: "test.customLabelsTitle"),
                    color: .purple
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "test.labelCount"))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(String(format: String(localized: "test.itemsFormat"), customLabelCount))
                            .font(.subheadline)
                            .foregroundStyle(Color.purple)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(customLabelCount) },
                        set: { customLabelCount = Int($0) }
                    ), in: 5...20, step: 1)
                    .tint(Color.purple)
                    
                    Text(String(format: String(localized: "test.generateLabelsHint"), customLabelCount))
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                
                PrimaryButton(title: isGenerating ? String(localized: "test.generating") : String(localized: "test.generateLabels"), action: generateCustomLabels, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 健康事件配置区
    private var healthEventSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "heart.text.square.fill",
                    title: String(localized: "test.healthEventsTitle"),
                    color: .green
                )
                
                VStack(alignment: .leading, spacing: 20) {
                    // 事件数量
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "test.eventCount"))
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: String(localized: "test.eventsFormat"), healthEventCount))
                                .font(.subheadline)
                                .foregroundStyle(Color.green)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(healthEventCount) },
                            set: { healthEventCount = Int($0) }
                        ), in: 10...100, step: 5)
                        .tint(Color.green)
                        
                        Text(String(format: String(localized: "test.generateEventsHint"), healthEventCount))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 时间范围
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String(localized: "test.timeRange"))
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: String(localized: "test.daysFormat"), healthEventDayRange))
                                .font(.subheadline)
                                .foregroundStyle(Color.green)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(healthEventDayRange) },
                            set: { healthEventDayRange = Int($0) }
                        ), in: 7...180, step: 7)
                        .tint(Color.green)
                        
                        Text(String(format: String(localized: "test.eventDayRangeHint"), healthEventDayRange))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                
                PrimaryButton(title: isGenerating ? String(localized: "test.generating") : String(localized: "test.generateHealthEvents"), action: generateHealthEvents, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 用户档案区段
    private var userProfileSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "person.circle.fill",
                    title: String(localized: "test.userProfileTitle"),
                    color: .orange
                )
                
                Text(String(localized: "test.generateUserProfileHint"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                
                PrimaryButton(title: isGenerating ? String(localized: "test.generating") : String(localized: "test.generateUserProfile"), action: generateUserProfile, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 危险操作区
    private var dangerZone: some View {
        EmotionalCard(style: .warning) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.statusError)
                    
                    Text(String(localized: "test.dangerZone"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.statusError)
                }
                
                Text(String(localized: "test.dangerZoneHint"))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                
                VStack(spacing: 12) {
                    Button {
                        showSelectiveClear = true
                    } label: {
                        Text(String(localized: "test.selectiveClear"))
                            .font(.headline)
                            .foregroundStyle(Color.statusWarning)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.statusWarning.opacity(0.15))
                            .cornerRadius(12)
                    }
                    .disabled(isGenerating)
                    
                    Button {
                        showClearAllAlert = true
                    } label: {
                        Text(String(localized: "test.clearAllData"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.statusError)
                            .cornerRadius(12)
                    }
                    .disabled(isGenerating)
                }
            }
        }
    }
    
    /// 区域标题
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
        }
    }
    
    /// 清空确认输入弹窗
    private var clearConfirmInputSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.statusError)
                
                VStack(spacing: 12) {
                    Text(String(localized: "test.confirmDelete"))
                        .font(.title2.bold())
                    
                    Text(String(localized: "test.confirmDeleteHint"))
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                
                TextField(String(localized: "test.confirmDeletePlaceholder"), text: $clearInputText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                if let stats = statistics {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "test.aboutToDelete"))
                            .font(.caption.bold())
                            .foregroundStyle(Color.textSecondary)
                        
                        HStack {
                            Label(String(format: String(localized: "test.recordsCount"), stats.recordCount), systemImage: "list.bullet")
                            Spacer()
                        }
                        
                        HStack {
                            Label(String(format: String(localized: "test.medicationsCount"), stats.medicationCount), systemImage: "cross.case")
                            Spacer()
                        }
                        
                        HStack {
                            Label(String(format: String(localized: "test.labelsCount"), stats.customLabelCount), systemImage: "tag")
                            Spacer()
                        }
                        
                        HStack {
                            Label(String(format: String(localized: "test.healthEventsCount"), stats.healthEventCount), systemImage: "heart.text.square")
                            Spacer()
                        }
                        
                        HStack {
                            Label(String(format: String(localized: "test.userProfilesCount"), stats.userProfileCount), systemImage: "person.circle")
                            Spacer()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                    .padding()
                    .background(Color.statusError.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle(String(localized: "test.confirmDelete"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        clearInputText = ""
                        showClearConfirmInput = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.continue")) {
                        showClearConfirmInput = false
                        showFinalConfirmation = true
                    }
                    .disabled(clearInputText != "确认删除" && clearInputText != "confirm delete")
                }
            }
        }
    }
    
    // MARK: - 操作方法
    
    /// 刷新统计数据
    private func refreshStatistics() {
        statistics = try? manager.getDataStatistics()
    }
    
    /// 生成发作记录
    private func generateAttackRecords() {
        isGenerating = true
        
        Task {
            do {
                let count = try await manager.generateAttackRecords(
                    monthCount: monthCount,
                    attacksPerMonth: attacksPerMonth,
                    avgDuration: avgDuration,
                    durationVariance: durationVariance
                )
                
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.successRecords"), count)
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.generateFailed"), error.localizedDescription)
                    showSuccessAlert = true
                }
            }
        }
    }
    
    /// 生成药箱数据
    private func generateMedications() {
        isGenerating = true
        
        Task {
            do {
                let medications = try await manager.generateMedications(count: medicationCount)
                
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.successMedications"), medications.count)
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.generateFailed"), error.localizedDescription)
                    showSuccessAlert = true
                }
            }
        }
    }
    
    /// 生成自定义标签
    private func generateCustomLabels() {
        isGenerating = true
        
        Task {
            do {
                let count = try await manager.generateCustomLabels(count: customLabelCount)
                
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.successLabels"), count)
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.generateFailed"), error.localizedDescription)
                    showSuccessAlert = true
                }
            }
        }
    }
    
    /// 生成健康事件
    private func generateHealthEvents() {
        isGenerating = true
        
        Task {
            do {
                let count = try await manager.generateHealthEvents(count: healthEventCount, dayRange: healthEventDayRange)
                
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.successHealthEvents"), count, healthEventDayRange)
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.generateFailed"), error.localizedDescription)
                    showSuccessAlert = true
                }
            }
        }
    }
    
    /// 生成用户档案
    private func generateUserProfile() {
        isGenerating = true
        
        Task {
            do {
                let _ = try await manager.generateUserProfile()
                
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(localized: "test.successUserProfile")
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.generateFailed"), error.localizedDescription)
                    showSuccessAlert = true
                }
            }
        }
    }
    
    /// 执行清空所有数据
    private func performClearAll() {
        isGenerating = true
        clearInputText = ""
        
        Task {
            do {
                try manager.clearAllData()
                
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(localized: "test.clearedAll")
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.clearFailed"), error.localizedDescription)
                    showSuccessAlert = true
                }
            }
        }
    }
    
    /// 确认并清空特定类型数据
    private func confirmAndClear(_ type: ClearDataType) {
        // 添加二次确认
        Task {
            await MainActor.run {
                isGenerating = true
            }
            
            do {
                switch type {
                case .records:
                    try manager.clearRecords()
                    await MainActor.run {
                        alertMessage = String(localized: "test.clearedRecords")
                    }
                case .medications:
                    try manager.clearMedications()
                    await MainActor.run {
                        alertMessage = String(localized: "test.clearedMedications")
                    }
                case .customLabels:
                    try manager.clearCustomLabels()
                    await MainActor.run {
                        alertMessage = String(localized: "test.clearedLabels")
                    }
                case .healthEvents:
                    try manager.clearHealthEvents()
                    await MainActor.run {
                        alertMessage = String(localized: "test.clearedHealthEvents")
                    }
                }
                
                await MainActor.run {
                    isGenerating = false
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = String(format: String(localized: "test.clearFailed"), error.localizedDescription)
                    showSuccessAlert = true
                }
            }
        }
    }
    
    enum ClearDataType {
        case records
        case medications
        case customLabels
        case healthEvents
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TestDataView()
            .modelContainer(for: [AttackRecord.self, Medication.self, CustomLabelConfig.self, HealthEvent.self], inMemory: true)
    }
}

#endif
