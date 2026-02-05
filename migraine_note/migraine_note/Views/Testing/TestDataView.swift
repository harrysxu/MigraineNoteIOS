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
                
                // 危险操作区
                dangerZone
            }
            .padding(Spacing.md)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("测试数据")
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
        .alert("操作成功", isPresented: $showSuccessAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("确认删除所有数据", isPresented: $showClearAllAlert) {
            Button("取消", role: .cancel) {}
            Button("继续", role: .destructive) {
                showClearConfirmInput = true
            }
        } message: {
            Text("此操作将删除所有发作记录、药物和自定义标签，且不可恢复。确定要继续吗？")
        }
        .sheet(isPresented: $showClearConfirmInput) {
            clearConfirmInputSheet
        }
        .alert("最后确认", isPresented: $showFinalConfirmation) {
            Button("取消", role: .cancel) {
                clearInputText = ""
            }
            Button("删除所有数据", role: .destructive) {
                performClearAll()
            }
        } message: {
            if let stats = statistics {
                Text("即将删除：\n• \(stats.recordCount) 条发作记录\n• \(stats.medicationCount) 种药物\n• \(stats.customLabelCount) 个自定义标签\n• \(stats.healthEventCount) 个健康事件\n\n此操作不可恢复！")
            } else {
                Text("即将删除所有数据，此操作不可恢复！")
            }
        }
        .confirmationDialog("选择要清空的数据", isPresented: $showSelectiveClear) {
            Button("清空发作记录", role: .destructive) {
                confirmAndClear(.records)
            }
            Button("清空药箱数据", role: .destructive) {
                confirmAndClear(.medications)
            }
            Button("清空自定义标签", role: .destructive) {
                confirmAndClear(.customLabels)
            }
            Button("清空健康事件", role: .destructive) {
                confirmAndClear(.healthEvents)
            }
            Button("取消", role: .cancel) {}
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
                    Text("测试环境")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("此功能仅在 Debug 模式下可用，生成的数据会保存到数据库中")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    /// 数据统计卡片
    private var statisticsCard: some View {
        EmotionalCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("当前数据统计")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    if let stats = statistics {
                        Text("共 \(stats.recordCount + stats.medicationCount + stats.customLabelCount + stats.healthEventCount) 项")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                if let stats = statistics {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            statisticItem(
                                icon: "list.bullet.clipboard",
                                title: "发作记录",
                                count: stats.recordCount,
                                color: .accentPrimary
                            )
                            
                            statisticItem(
                                icon: "cross.case.fill",
                                title: "药物",
                                count: stats.medicationCount,
                                color: .blue
                            )
                        }
                        
                        HStack(spacing: 12) {
                            statisticItem(
                                icon: "tag.fill",
                                title: "标签",
                                count: stats.customLabelCount,
                                color: .purple
                            )
                            
                            statisticItem(
                                icon: "heart.text.square.fill",
                                title: "健康事件",
                                count: stats.healthEventCount,
                                color: .green
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
                    title: "发作记录生成",
                    color: .accentPrimary
                )
                
                VStack(alignment: .leading, spacing: 20) {
                    // 月份数
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("月份数")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(monthCount) 个月")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(monthCount) },
                            set: { monthCount = Int($0) }
                        ), in: 1...24, step: 1)
                        .tint(Color.accentPrimary)
                        
                        Text("生成过去 \(monthCount) 个月的数据")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 每月频次
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("每月频次")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(attacksPerMonth) 次")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(attacksPerMonth) },
                            set: { attacksPerMonth = Int($0) }
                        ), in: 1...15, step: 1)
                        .tint(Color.accentPrimary)
                        
                        Text("每月发作 \(attacksPerMonth) 次，共约 \(monthCount * attacksPerMonth) 条记录")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 平均持续时长
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("平均持续时长")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: "%.1f 小时", avgDuration))
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: $avgDuration, in: 1...24, step: 0.5)
                            .tint(Color.accentPrimary)
                        
                        Text("发作平均持续 \(String(format: "%.1f", avgDuration)) 小时")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 时长变化范围
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("时长变化范围")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: "±%.1f 小时", durationVariance))
                                .font(.subheadline)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        
                        Slider(value: $durationVariance, in: 0...12, step: 0.5)
                            .tint(Color.accentPrimary)
                        
                        Text("持续时间约在 \(String(format: "%.1f", max(0.5, avgDuration - durationVariance)))-\(String(format: "%.1f", avgDuration + durationVariance)) 小时之间")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                
                PrimaryButton(title: isGenerating ? "生成中..." : "生成记录", action: generateAttackRecords, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 药箱配置区
    private var medicationSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "cross.case.fill",
                    title: "药箱数据生成",
                    color: .blue
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("药品数量")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(medicationCount) 种")
                            .font(.subheadline)
                            .foregroundStyle(Color.blue)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(medicationCount) },
                        set: { medicationCount = Int($0) }
                    ), in: 5...30, step: 1)
                    .tint(Color.blue)
                    
                    Text("生成 \(medicationCount) 种药物，包含各类别和库存信息")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                
                PrimaryButton(title: isGenerating ? "生成中..." : "生成药箱", action: generateMedications, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 自定义标签配置区
    private var customLabelSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "tag.fill",
                    title: "自定义标签生成",
                    color: .purple
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("标签数量")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(customLabelCount) 个")
                            .font(.subheadline)
                            .foregroundStyle(Color.purple)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(customLabelCount) },
                        set: { customLabelCount = Int($0) }
                    ), in: 5...20, step: 1)
                    .tint(Color.purple)
                    
                    Text("生成 \(customLabelCount) 个自定义标签（症状和诱因）")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                
                PrimaryButton(title: isGenerating ? "生成中..." : "生成标签", action: generateCustomLabels, isEnabled: !isGenerating)
            }
        }
    }
    
    /// 健康事件配置区
    private var healthEventSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    icon: "heart.text.square.fill",
                    title: "健康事件生成",
                    color: .green
                )
                
                VStack(alignment: .leading, spacing: 20) {
                    // 事件数量
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("事件数量")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(healthEventCount) 个")
                                .font(.subheadline)
                                .foregroundStyle(Color.green)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(healthEventCount) },
                            set: { healthEventCount = Int($0) }
                        ), in: 10...100, step: 5)
                        .tint(Color.green)
                        
                        Text("生成 \(healthEventCount) 个健康事件记录")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 时间范围
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("时间范围")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(healthEventDayRange) 天")
                                .font(.subheadline)
                                .foregroundStyle(Color.green)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(healthEventDayRange) },
                            set: { healthEventDayRange = Int($0) }
                        ), in: 7...180, step: 7)
                        .tint(Color.green)
                        
                        Text("在过去 \(healthEventDayRange) 天内随机分布（用药、中医治疗、手术等）")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                
                PrimaryButton(title: isGenerating ? "生成中..." : "生成健康事件", action: generateHealthEvents, isEnabled: !isGenerating)
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
                    
                    Text("危险操作")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.statusError)
                }
                
                Text("以下操作将永久删除数据，无法恢复")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                
                VStack(spacing: 12) {
                    Button {
                        showSelectiveClear = true
                    } label: {
                        Text("选择性清空")
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
                        Text("清空所有数据")
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
                    Text("确认删除")
                        .font(.title2.bold())
                    
                    Text("请输入 '确认删除' 以继续")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                
                TextField("请输入：确认删除", text: $clearInputText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                if let stats = statistics {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("即将删除：")
                            .font(.caption.bold())
                            .foregroundStyle(Color.textSecondary)
                        
                        HStack {
                            Label("\(stats.recordCount) 条记录", systemImage: "list.bullet")
                            Spacer()
                        }
                        
                        HStack {
                            Label("\(stats.medicationCount) 种药物", systemImage: "cross.case")
                            Spacer()
                        }
                        
                        HStack {
                            Label("\(stats.customLabelCount) 个标签", systemImage: "tag")
                            Spacer()
                        }
                        
                        HStack {
                            Label("\(stats.healthEventCount) 个健康事件", systemImage: "heart.text.square")
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
            .navigationTitle("确认删除")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        clearInputText = ""
                        showClearConfirmInput = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("继续") {
                        showClearConfirmInput = false
                        showFinalConfirmation = true
                    }
                    .disabled(clearInputText != "确认删除")
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
                    alertMessage = "成功生成 \(count) 条发作记录"
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "生成失败：\(error.localizedDescription)"
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
                    alertMessage = "成功生成 \(medications.count) 种药物"
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "生成失败：\(error.localizedDescription)"
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
                    alertMessage = "成功生成 \(count) 个自定义标签"
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "生成失败：\(error.localizedDescription)"
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
                    alertMessage = "成功生成 \(count) 个健康事件（过去\(healthEventDayRange)天）"
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "生成失败：\(error.localizedDescription)"
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
                    alertMessage = "已清空所有数据"
                    showSuccessAlert = true
                    refreshStatistics()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    alertMessage = "清空失败：\(error.localizedDescription)"
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
                        alertMessage = "已清空所有发作记录"
                    }
                case .medications:
                    try manager.clearMedications()
                    await MainActor.run {
                        alertMessage = "已清空所有药物"
                    }
                case .customLabels:
                    try manager.clearCustomLabels()
                    await MainActor.run {
                        alertMessage = "已清空所有自定义标签"
                    }
                case .healthEvents:
                    try manager.clearHealthEvents()
                    await MainActor.run {
                        alertMessage = "已清空所有健康事件"
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
                    alertMessage = "清空失败：\(error.localizedDescription)"
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
