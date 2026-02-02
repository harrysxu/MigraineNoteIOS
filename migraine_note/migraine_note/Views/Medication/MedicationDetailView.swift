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
            VStack(spacing: AppSpacing.small) {
                InfoRow(label: "药物类别", value: medication.category.rawValue)
                InfoRow(label: "用药类型", value: medication.isAcute ? "急性用药" : "预防性用药")
                InfoRow(label: "标准剂量", value: String(format: "%.1f %@", medication.standardDosage, medication.unit))
                
                if let limit = medication.monthlyLimit {
                    InfoRow(label: "月度限制", value: "\(limit) 天")
                }
            }
        }
    }
    
    // MARK: - Usage Stats Card
    
    private var usageStatsCard: some View {
        DetailCard(title: "使用统计", icon: "chart.bar") {
            HStack(spacing: AppSpacing.large) {
                StatItem(
                    title: "本月使用",
                    value: "\(monthlyUsageDays)",
                    icon: "calendar",
                    color: monthlyUsageDays >= (medication.monthlyLimit ?? 100) ? AppColors.error : AppColors.primary,
                    subtitle: "天"
                )
                
                Divider()
                
                StatItem(
                    title: "总使用",
                    value: "\(totalUsageCount)",
                    icon: "number",
                    color: AppColors.info,
                    subtitle: "次"
                )
                
                if let avgEffectiveness = averageEffectiveness {
                    Divider()
                    
                    StatItem(
                        title: "平均疗效",
                        value: String(format: "%.1f", avgEffectiveness),
                        icon: "star.fill",
                        color: effectivenessColor(avgEffectiveness),
                        subtitle: "/ 5.0"
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
            title: "MOH风险",
            icon: "exclamationmark.triangle.fill"
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                // 进度条
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(monthlyUsageDays) / \(limit) 天")
                            .appFont(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.surfaceElevated)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: progressGradientColors(progress),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: min(geometry.size.width * progress, geometry.size.width),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }
                
                // 警告信息
                if isExceeding {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColors.error)
                        Text("已超过MOH阈值，请咨询医生")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.error)
                    }
                    .padding(AppSpacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                } else if isApproaching {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColors.warning)
                        Text("接近MOH阈值，请注意控制用药频率")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.warning)
                    }
                    .padding(AppSpacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)
                        Text("用药频率正常")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.success)
                    }
                }
            }
        }
    }
    
    // MARK: - Inventory Card
    
    private var inventoryCard: some View {
        DetailCard(title: "库存管理", icon: "shippingbox") {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前库存")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    HStack(spacing: 8) {
                        Text("\(medication.inventory)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(inventoryColor)
                        
                        if medication.inventory <= 5 && medication.inventory > 0 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppColors.warning)
                        } else if medication.inventory == 0 {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppColors.error)
                        }
                    }
                    
                    if medication.inventory <= 5 {
                        Text(medication.inventory == 0 ? "库存已用完" : "库存不足，请及时补充")
                            .appFont(.caption)
                            .foregroundStyle(medication.inventory == 0 ? AppColors.error : AppColors.warning)
                    }
                }
                
                Spacer()
                
                Button {
                    showingInventorySheet = true
                } label: {
                    Label("调整", systemImage: "slider.horizontal.3")
                        .appFont(.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.small)
                        .background(AppColors.primary)
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
            Text(notes)
                .appFont(.body)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.takenAt.fullDateTime())
                    .appFont(.body)
                    .foregroundStyle(AppColors.textPrimary)
                
                if let effectiveness = log.effectiveness {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text(effectiveness.rawValue)
                            .appFont(.caption)
                    }
                    .foregroundStyle(effectivenessColor(effectiveness))
                }
            }
            
            Spacer()
            
            Text(log.dosageString)
                .appFont(.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, 4)
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
                                .foregroundStyle(AppColors.primary)
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
