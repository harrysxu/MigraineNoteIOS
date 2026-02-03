//
//  AttackDetailView.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  发作记录详情页面
//

import SwiftUI
import SwiftData

struct AttackDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let attack: AttackRecord
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // 顶部卡片：疼痛概览
                        painOverviewCard
                        
                        // 时间信息
                        timeDetailCard
                        
                        // 疼痛详情
                        painDetailsCard
                        
                        // 症状和先兆
                        if !attack.symptoms.isEmpty || attack.hasAura {
                            symptomsCard
                        }
                        
                        // 诱因
                        if !attack.triggers.isEmpty {
                            triggersCard
                        }
                        
                        // 用药记录
                        if !attack.medicationLogs.isEmpty {
                            medicationsCard
                        }
                        
                        // 非药物干预
                        if !attack.nonPharmInterventions.isEmpty {
                            nonPharmInterventionsCard
                        }
                        
                        // 天气信息
                        if let weather = attack.weatherSnapshot {
                            weatherCard(weather)
                        }
                        
                        // 备注
                        if let notes = attack.notes, !notes.isEmpty {
                            notesCard(notes)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .navigationTitle("记录详情")
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
            .alert("删除记录", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteAttack()
                }
            } message: {
                Text("确定要删除这条记录吗？此操作无法撤销。")
            }
            .sheet(isPresented: $showingEditSheet) {
                EditAttackView(attack: attack, modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Pain Overview Card
    
    private var painOverviewCard: some View {
        VStack(spacing: Spacing.md) {
            // 疼痛强度
            VStack(spacing: 8) {
                Text("疼痛强度")
                    .appFont(.caption)
                    .foregroundStyle(Color.labelSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(attack.painIntensity)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(Color.painIntensityColor(for: attack.painIntensity))
                    
                    Text("/10")
                        .appFont(.title3)
                        .foregroundStyle(Color.labelSecondary)
                }
                
                Text(Color.painIntensityDescription(for: attack.painIntensity))
                    .appFont(.body)
                    .foregroundStyle(Color.labelSecondary)
            }
            
            Divider()
            
            // 持续时间
            VStack(spacing: 4) {
                Text("持续时间")
                    .appFont(.caption)
                    .foregroundStyle(Color.labelSecondary)
                
                Text(formattedDuration)
                    .appFont(.title3)
                    .foregroundStyle(Color.labelPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
    
    // MARK: - Time Info Card
    
    private var timeDetailCard: some View {
        DetailCard(title: "时间信息", icon: "clock") {
            VStack(spacing: Spacing.xs) {
                InfoRow(label: "开始时间", value: attack.startTime.fullDateTime())
                
                if let endTime = attack.endTime {
                    InfoRow(label: "结束时间", value: endTime.fullDateTime())
                } else {
                    InfoRow(label: "状态", value: "进行中", valueColor: Color.warning)
                }
            }
        }
    }
    
    // MARK: - Pain Details Card
    
    private var painDetailsCard: some View {
        DetailCard(title: "疼痛详情", icon: "exclamationmark.circle") {
            VStack(spacing: Spacing.xs) {
                // 疼痛部位
                if !attack.painLocations.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("疼痛部位")
                            .appFont(.caption)
                            .foregroundStyle(Color.labelSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(attack.painLocations, id: \.self) { location in
                                Text(location.displayName)
                                    .appFont(.body)
                                    .foregroundStyle(Color.labelPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 疼痛性质
                if !attack.painQualities.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("疼痛性质")
                            .appFont(.caption)
                            .foregroundStyle(Color.labelSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(attack.painQualities, id: \.self) { quality in
                                Text(quality.rawValue)
                                    .appFont(.body)
                                    .foregroundStyle(Color.labelPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.backgroundTertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - Symptoms Card
    
    private var symptomsCard: some View {
        DetailCard(title: "症状与先兆", icon: "waveform.path.ecg") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // 先兆
                if attack.hasAura {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.warning)
                        Text("有先兆")
                            .appFont(.body)
                            .foregroundStyle(Color.labelPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
                
                // 症状列表
                if !attack.symptoms.isEmpty {
                    ForEach(attack.symptoms) { symptom in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.success)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(symptom.name)
                                    .appFont(.body)
                                    .foregroundStyle(Color.labelPrimary)
                                
                                if let description = symptom.symptomDescription, !description.isEmpty {
                                    Text(description)
                                        .appFont(.caption)
                                        .foregroundStyle(Color.labelSecondary)
                                }
                                
                                Text(symptom.category.rawValue)
                                    .appFont(.caption)
                                    .foregroundStyle(Color.labelTertiary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Triggers Card
    
    private var triggersCard: some View {
        DetailCard(title: "可能诱因", icon: "exclamationmark.triangle") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(attack.triggers) { trigger in
                    HStack(spacing: 6) {
                        Image(systemName: trigger.category.systemImage)
                            .font(.caption)
                        Text(trigger.name)
                            .appFont(.body)
                    }
                    .foregroundStyle(Color.labelPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.warning.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
            }
        }
    }
    
    // MARK: - Medications Card
    
    private var medicationsCard: some View {
        DetailCard(title: "用药记录", icon: "pills.fill") {
            VStack(spacing: Spacing.xs) {
                ForEach(attack.medicationLogs) { log in
                    MedicationLogRowView(log: log)
                }
            }
        }
    }
    
    // MARK: - Non-Pharm Interventions Card
    
    private var nonPharmInterventionsCard: some View {
        DetailCard(title: "非药物干预", icon: "leaf.fill") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(attack.nonPharmInterventions, id: \.self) { intervention in
                    Text(intervention.rawValue)
                        .appFont(.body)
                        .foregroundStyle(Color.labelPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.success.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }
            }
        }
    }
    
    // MARK: - Weather Card
    
    private func weatherCard(_ weather: WeatherSnapshot) -> some View {
        DetailCard(title: "天气状况", icon: "cloud.sun") {
            VStack(spacing: Spacing.md) {
                // 顶部：温度和天气状况
                HStack(spacing: Spacing.md) {
                    // 温度显示
                    VStack(spacing: 4) {
                        Text("\(Int(weather.temperature))°C")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.primary)
                        
                        if !weather.condition.isEmpty {
                            Text(weather.condition)
                                .appFont(.caption)
                                .foregroundStyle(Color.labelSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 60)
                    
                    // 位置和时间
                    VStack(alignment: .leading, spacing: 4) {
                        if !weather.location.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(weather.location)
                                    .appFont(.body)
                            }
                            .foregroundStyle(Color.labelPrimary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(weather.timestamp.shortTime())
                                .appFont(.caption)
                        }
                        .foregroundStyle(Color.labelSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                // 详细数据网格
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        WeatherDetailBox(
                            icon: "gauge.high",
                            label: "气压",
                            value: String(format: "%.0f", weather.pressure),
                            unit: "hPa",
                            trend: weather.pressureTrend
                        )
                        
                        WeatherDetailBox(
                            icon: "humidity",
                            label: "湿度",
                            value: String(format: "%.0f", weather.humidity),
                            unit: "%"
                        )
                    }
                    
                    HStack(spacing: 12) {
                        WeatherDetailBox(
                            icon: "wind",
                            label: "风速",
                            value: String(format: "%.1f", weather.windSpeed),
                            unit: "m/s"
                        )
                        
                        WeatherDetailBox(
                            icon: weather.isHighRisk ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                            label: "风险",
                            value: weather.isHighRisk ? "高" : "低",
                            unit: "",
                            isWarning: weather.isHighRisk
                        )
                    }
                }
                
                // 风险警告（如果有）
                if !weather.warnings.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ 环境风险提示")
                            .appFont(.subheadline)
                            .foregroundStyle(Color.warning)
                            .fontWeight(.semibold)
                        
                        ForEach(weather.warnings, id: \.self) { warning in
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.warning)
                                Text(warning)
                                    .appFont(.caption)
                                    .foregroundStyle(Color.labelSecondary)
                                Spacer()
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.warning.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Card
    
    private func notesCard(_ notes: String) -> some View {
        DetailCard(title: "备注", icon: "note.text") {
            Text(notes)
                .appFont(.body)
                .foregroundStyle(Color.labelPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDuration: String {
        let duration = attack.durationOrElapsed
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // MARK: - Actions
    
    private func deleteAttack() {
        modelContext.delete(attack)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color.labelPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .appFont(.body)
                .foregroundStyle(Color.labelSecondary)
            Spacer()
            Text(value)
                .appFont(.body)
                .foregroundStyle(valueColor)
        }
    }
}

struct MedicationLogRowView: View {
    let log: MedicationLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.medication?.name ?? "未知药物")
                    .appFont(.body)
                    .foregroundStyle(Color.labelPrimary)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(log.takenAt.shortTime())
                    .appFont(.caption)
                    .foregroundStyle(Color.labelSecondary)
            }
            
            HStack {
                if let medication = log.medication {
                    Label(medication.category.rawValue, systemImage: "pills")
                        .appFont(.caption)
                        .foregroundStyle(Color.labelSecondary)
                } else {
                    Label("未分类", systemImage: "pills")
                        .appFont(.caption)
                        .foregroundStyle(Color.labelSecondary)
                }
                
                Spacer()
                
                Text(log.dosageString)
                    .appFont(.caption)
                    .foregroundStyle(Color.labelSecondary)
            }
            
            // 疗效评估
            if let effectiveness = log.effectiveness {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(effectivenessColor(effectiveness))
                    Text(effectiveness.rawValue)
                        .appFont(.caption)
                        .foregroundStyle(effectivenessColor(effectiveness))
                }
            }
        }
        .padding(Spacing.xs)
        .background(Color.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }
    
    private func effectivenessColor(_ effectiveness: MedicationLog.Effectiveness) -> Color {
        switch effectiveness {
        case .excellent, .good:
            return Color.success
        case .moderate:
            return Color.warning
        case .poor, .none:
            return Color.danger
        }
    }
}

struct WeatherDetailBox: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    var trend: PressureTrend?
    var isWarning: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isWarning ? Color.warning : Color.primary)
            
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.labelPrimary)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .appFont(.caption)
                            .foregroundStyle(Color.labelSecondary)
                    }
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.caption)
                            .foregroundStyle(trendColor(for: trend))
                    }
                }
                
                Text(label)
                    .appFont(.caption)
                    .foregroundStyle(Color.labelTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func trendColor(for trend: PressureTrend) -> Color {
        switch trend {
        case .rising:
            return Color.success
        case .falling:
            return Color.warning
        case .steady:
            return Color.labelSecondary
        }
    }
}

#Preview {
    AttackDetailView(attack: {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: AttackRecord.self, configurations: config)
        
        // 创建示例数据
        let attack = AttackRecord(startTime: Date().addingTimeInterval(-7200))
        attack.endTime = Date()
        attack.painIntensity = 7
        attack.setPainLocations([.forehead, .leftTemple])
        attack.hasAura = true
        
        container.mainContext.insert(attack)
        
        return attack
    }())
}
