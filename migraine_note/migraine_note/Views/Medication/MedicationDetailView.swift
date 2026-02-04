//
//  MedicationDetailView.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  药物详情页面 - 显示药物信息和使用历史
//

import SwiftUI
import SwiftData
import Charts

struct MedicationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let medication: Medication
    
    @Query private var allMedicationLogs: [MedicationLog]
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var inventoryAdjustment: Int = 0
    @State private var showingInventorySheet = false
    
    // 筛选该药物的使用记录
    private var medicationLogs: [MedicationLog] {
        allMedicationLogs.filter { $0.medication?.id == medication.id }
            .sorted { $0.takenAt > $1.takenAt }
    }
    
    // 本月使用天数
    private var monthlyUsageDays: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthlyLogs = medicationLogs.filter { $0.takenAt >= startOfMonth }
        let uniqueDays = Set(monthlyLogs.map { calendar.startOfDay(for: $0.takenAt) })
        return uniqueDays.count
    }
    
    // 总使用次数
    private var totalUsageCount: Int {
        medicationLogs.count
    }
    
    // 平均疗效
    private var averageEffectiveness: Double? {
        let effectiveLogs = medicationLogs.compactMap { log -> Double? in
            guard let effectiveness = log.effectiveness else { return nil }
            switch effectiveness {
            case .excellent: return 5.0
            case .good: return 4.0
            case .moderate: return 3.0
            case .poor: return 2.0
            case .none: return 1.0
            }
        }
        
        guard !effectiveLogs.isEmpty else { return nil }
        return effectiveLogs.reduce(0, +) / Double(effectiveLogs.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        // 基本信息卡片
                        basicInfoCard
                        
                        // 使用统计卡片
                        usageStatsCard
                        
                        // MOH风险卡片（仅急性用药）
                        if medication.isAcute, let limit = medication.monthlyLimit {
                            mohRiskCard(limit: limit)
                        }
                        
                        // 库存管理卡片
                        inventoryCard
                        
                        // 使用历史
                        if !medicationLogs.isEmpty {
                            usageHistoryCard
                        }
                        
                        // 备注
                        if let notes = medication.notes, !notes.isEmpty {
                            notesCard(notes)
                        }
                    }
                    .padding(AppSpacing.medium)
                }
            }
            .navigationTitle(medication.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingInventorySheet = true
                        } label: {
                            Label("调整库存", systemImage: "shippingbox")
                        }
                        
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("删除药物", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteMedication()
                }
            } message: {
                Text("确定要删除这个药物吗？相关的用药记录不会被删除。")
            }
            .sheet(isPresented: $showingEditSheet) {
                Text("编辑功能即将推出")
                    .padding()
            }
            .sheet(isPresented: $showingInventorySheet) {
                InventoryAdjustmentSheet(
                    medication: medication,
                    currentInventory: medication.inventory
                )
            }
        }
    }
    
    // MARK: - Basic Info Card
    
    private var basicInfoCard: some View {
        DetailCard(title: "基本信息", icon: "info.circle") {
            VStack(spacing: AppSpacing.medium) {
                // 药物类别和类型
                HStack(spacing: AppSpacing.medium) {
                    InfoPill(
                        label: "药物类别",
                        value: medication.category.rawValue,
                        icon: "pills",
                        color: Color.accentPrimary
                    )
                    
                    InfoPill(
                        label: "用药类型",
                        value: medication.isAcute ? "急性用药" : "预防性用药",
                        icon: medication.isAcute ? "bolt.fill" : "shield.fill",
                        color: medication.isAcute ? AppColors.warning : AppColors.info
                    )
                }
                
                Divider()
                
                // 剂量和限制
                VStack(spacing: AppSpacing.small) {
                    HStack {
                        Label("标准剂量", systemImage: "scalemass")
                            .appFont(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f %@", medication.standardDosage, medication.unit))
                            .appFont(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    
                    if let limit = medication.monthlyLimit {
                        HStack {
                            Label("月度限制", systemImage: "calendar.badge.exclamationmark")
                                .appFont(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(limit) 天")
                                .appFont(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Usage Stats Card
    
    private var usageStatsCard: some View {
        DetailCard(title: "使用统计", icon: "chart.bar") {
            VStack(spacing: AppSpacing.medium) {
                // 本月使用和总使用
                HStack(spacing: AppSpacing.medium) {
                    EnhancedStatItem(
                        title: "本月使用",
                        value: "\(monthlyUsageDays)",
                        icon: "calendar",
                        color: monthlyUsageDays >= (medication.monthlyLimit ?? 100) ? AppColors.error : Color.accentPrimary,
                        subtitle: "天"
                    )
                    
                    EnhancedStatItem(
                        title: "总使用",
                        value: "\(totalUsageCount)",
                        icon: "number",
                        color: Color.accentPrimary,
                        subtitle: "次"
                    )
                }
                
                // 平均疗效（如果有数据）
                if let avgEffectiveness = averageEffectiveness {
                    EffectivenessCard(
                        value: avgEffectiveness,
                        color: effectivenessColor(avgEffectiveness)
                    )
                }
            }
        }
    }
    
    // MARK: - MOH Risk Card
    
    private func mohRiskCard(limit: Int) -> some View {
        let progress = Double(monthlyUsageDays) / Double(limit)
        let isExceeding = monthlyUsageDays >= limit
        let isApproaching = monthlyUsageDays >= limit - 3 && !isExceeding
        
        return DetailCard(
            title: "MOH 风险",
            icon: "exclamationmark.triangle.fill"
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                // 使用天数显示
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(monthlyUsageDays)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(mohRiskColor(progress))
                    
                    Text("/ \(limit) 天")
                        .appFont(.title3)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(mohRiskColor(progress))
                        
                        Text("使用率")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.surfaceElevated)
                            .frame(height: 12)
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: progressGradientColors(progress),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: min(geometry.size.width * progress, geometry.size.width),
                                height: 12
                            )
                    }
                }
                .frame(height: 12)
                
                // 状态提示
                HStack(spacing: 8) {
                    if isExceeding {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundStyle(AppColors.error)
                    } else if isApproaching {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColors.warning)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)
                    }
                    
                    Text(mohRiskMessage(isExceeding: isExceeding, isApproaching: isApproaching))
                        .appFont(.subheadline)
                        .foregroundStyle(mohRiskColor(progress))
                    
                    Spacer()
                }
                .padding(AppSpacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(mohRiskColor(progress).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            }
        }
    }
    
    private func mohRiskColor(_ progress: Double) -> Color {
        if progress >= 1.0 {
            return AppColors.error
        } else if progress >= 0.8 {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }
    
    private func mohRiskMessage(isExceeding: Bool, isApproaching: Bool) -> String {
        if isExceeding {
            return "已超过 MOH 阈值，请咨询医生"
        } else if isApproaching {
            return "接近 MOH 阈值，请注意控制用药频率"
        } else {
            return "用药频率正常"
        }
    }
    
    // MARK: - Inventory Card
    
    private var inventoryCard: some View {
        DetailCard(title: "库存管理", icon: "shippingbox") {
            VStack(spacing: AppSpacing.medium) {
                // 库存显示
                HStack(spacing: AppSpacing.large) {
                    // 左侧库存信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前库存")
                            .appFont(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(medication.inventory)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(inventoryColor)
                            
                            Text("片")
                                .appFont(.title3)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 右侧状态图标
                    VStack(spacing: 8) {
                        if medication.inventory == 0 {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.error)
                        } else if medication.inventory <= 5 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.warning)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(AppColors.success.opacity(0.5))
                        }
                    }
                }
                
                // 警告信息和操作按钮
                if medication.inventory <= 5 {
                    HStack(spacing: 8) {
                        Image(systemName: medication.inventory == 0 ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(medication.inventory == 0 ? AppColors.error : AppColors.warning)
                        
                        Text(medication.inventory == 0 ? "库存已用完，请及时补充" : "库存不足，建议补充")
                            .appFont(.subheadline)
                            .foregroundStyle(medication.inventory == 0 ? AppColors.error : AppColors.warning)
                        
                        Spacer()
                    }
                    .padding(AppSpacing.small)
                    .background((medication.inventory == 0 ? AppColors.error : AppColors.warning).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                }
                
                // 调整按钮
                Button {
                    showingInventorySheet = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("调整库存")
                            .appFont(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.small)
                    .background(Color.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                }
            }
        }
    }
    
    // MARK: - Usage History Card
    
    private var usageHistoryCard: some View {
        DetailCard(title: "使用历史", icon: "clock.arrow.circlepath") {
            VStack(spacing: AppSpacing.small) {
                ForEach(medicationLogs.prefix(10)) { log in
                    UsageHistoryRow(log: log)
                }
                
                if medicationLogs.count > 10 {
                    Text("显示最近10条记录，共\(medicationLogs.count)条")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, AppSpacing.small)
                }
            }
        }
    }
    
    // MARK: - Notes Card
    
    private func notesCard(_ notes: String) -> some View {
        DetailCard(title: "备注", icon: "note.text") {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                
                Text(notes)
                    .appFont(.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "quote.closing")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .padding(AppSpacing.small)
            .background(AppColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
        }
    }
    
    // MARK: - Helper Methods
    
    private func effectivenessColor(_ value: Double) -> Color {
        if value >= 4.0 {
            return AppColors.success
        } else if value >= 3.0 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }
    
    private var inventoryColor: Color {
        if medication.inventory == 0 {
            return AppColors.error
        } else if medication.inventory <= 5 {
            return AppColors.warning
        } else {
            return AppColors.textPrimary
        }
    }
    
    private func progressGradientColors(_ progress: Double) -> [Color] {
        if progress >= 1.0 {
            return [AppColors.error, AppColors.error]
        } else if progress >= 0.8 {
            return [AppColors.warning, AppColors.error]
        } else {
            return [AppColors.success, AppColors.warning]
        }
    }
    
    private func deleteMedication() {
        modelContext.delete(medication)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Usage History Row

struct UsageHistoryRow: View {
    let log: MedicationLog
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            // 左侧时间标记
            VStack(spacing: 4) {
                Text(log.takenAt.formatted(.dateTime.month(.abbreviated).day()))
                    .appFont(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text(log.takenAt.formatted(.dateTime.hour().minute()))
                    .appFont(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(width: 50)
            
            // 分隔线
            Rectangle()
                .fill(AppColors.divider)
                .frame(width: 2)
            
            // 中间信息
            VStack(alignment: .leading, spacing: 6) {
                // 剂量
                Text(log.dosageString)
                    .appFont(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
                
                // 疗效
                if let effectiveness = log.effectiveness {
                    HStack(spacing: 4) {
                        ForEach(0..<effectivenessStars(effectiveness), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(effectivenessColor(effectiveness))
                        }
                        
                        Text(effectiveness.rawValue)
                            .appFont(.caption)
                            .foregroundStyle(effectivenessColor(effectiveness))
                    }
                }
            }
            
            Spacer()
            
            // 右侧指示器
            Circle()
                .fill(log.effectiveness != nil ? effectivenessColor(log.effectiveness!) : AppColors.textSecondary.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, AppSpacing.small)
        .padding(.horizontal, AppSpacing.small)
        .background(AppColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
    }
    
    private func effectivenessStars(_ effectiveness: MedicationLog.Effectiveness) -> Int {
        switch effectiveness {
        case .excellent: return 5
        case .good: return 4
        case .moderate: return 3
        case .poor: return 2
        case .none: return 1
        }
    }
    
    private func effectivenessColor(_ effectiveness: MedicationLog.Effectiveness) -> Color {
        switch effectiveness {
        case .excellent, .good:
            return AppColors.success
        case .moderate:
            return AppColors.warning
        case .poor, .none:
            return AppColors.error
        }
    }
}

// MARK: - Inventory Adjustment Sheet

struct InventoryAdjustmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let medication: Medication
    let currentInventory: Int
    
    @State private var newInventory: Int
    
    init(medication: Medication, currentInventory: Int) {
        self.medication = medication
        self.currentInventory = currentInventory
        _newInventory = State(initialValue: currentInventory)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("当前库存")
                        Spacer()
                        Text("\(currentInventory)")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                Section("调整库存") {
                    Stepper(value: $newInventory, in: 0...999) {
                        HStack {
                            Text("新库存")
                        Spacer()
                        Text("\(newInventory)")
                            .foregroundStyle(Color.accentPrimary)
                            .fontWeight(.semibold)
                        }
                    }
                    
                    HStack {
                        Text("变化")
                        Spacer()
                        let diff = newInventory - currentInventory
                        Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                            .foregroundStyle(diff >= 0 ? AppColors.success : AppColors.error)
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("调整库存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveInventory()
                    }
                    .disabled(newInventory == currentInventory)
                }
            }
        }
    }
    
    private func saveInventory() {
        medication.inventory = newInventory
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Info Pill Component

struct InfoPill: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .appFont(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
            
            Text(label)
                .appFont(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.medium)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
    }
}

// MARK: - Enhanced Stat Item

struct EnhancedStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text(title)
                    .appFont(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                
                Text(subtitle)
                    .appFont(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.medium)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
    }
}

// MARK: - Effectiveness Card

struct EffectivenessCard: View {
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            // 星星图标
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(color)
            }
            
            // 疗效信息
            VStack(alignment: .leading, spacing: 4) {
                Text("平均疗效")
                    .appFont(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    
                    Text("/ 5.0")
                        .appFont(.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // 星级显示
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: Double(index) < value ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(color)
                    }
                }
                
                Text(effectivenessLabel)
                    .appFont(.caption)
                    .foregroundStyle(color)
            }
        }
        .padding(AppSpacing.medium)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
    }
    
    private var effectivenessLabel: String {
        if value >= 4.5 {
            return "非常有效"
        } else if value >= 3.5 {
            return "较为有效"
        } else if value >= 2.5 {
            return "一般"
        } else {
            return "效果不佳"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Medication.self, configurations: config)
    
    let medication = Medication(name: "布洛芬", category: .nsaid, isAcute: true)
    medication.standardDosage = 400
    medication.unit = "mg"
    medication.inventory = 20
    medication.monthlyLimit = 15
    
    container.mainContext.insert(medication)
    
    return MedicationDetailView(medication: medication)
        .modelContainer(container)
}
