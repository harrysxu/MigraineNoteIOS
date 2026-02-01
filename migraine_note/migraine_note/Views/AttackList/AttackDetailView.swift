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
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.large) {
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
                    .padding(AppSpacing.medium)
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
        VStack(spacing: AppSpacing.medium) {
            // 疼痛强度
            VStack(spacing: 8) {
                Text("疼痛强度")
                    .appFont(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(attack.painIntensity)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(PainIntensity.from(attack.painIntensity).color)
                    
                    Text("/10")
                        .appFont(.title3)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Text(PainIntensity.from(attack.painIntensity).description)
                    .appFont(.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Divider()
            
            // 持续时间
            VStack(spacing: 4) {
                Text("持续时间")
                    .appFont(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text(formattedDuration)
                    .appFont(.title3)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.large)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .shadow(color: AppColors.shadowColor, radius: AppSpacing.shadowRadiusSmall)
    }
    
    // MARK: - Time Info Card
    
    private var timeDetailCard: some View {
        DetailCard(title: "时间信息", icon: "clock") {
            VStack(spacing: AppSpacing.small) {
                InfoRow(label: "开始时间", value: attack.startTime.formatted(date: .abbreviated, time: .shortened))
                
                if let endTime = attack.endTime {
                    InfoRow(label: "结束时间", value: endTime.formatted(date: .abbreviated, time: .shortened))
                } else {
                    InfoRow(label: "状态", value: "进行中", valueColor: AppColors.warning)
                }
            }
        }
    }
    
    // MARK: - Pain Details Card
    
    private var painDetailsCard: some View {
        DetailCard(title: "疼痛详情", icon: "exclamationmark.circle") {
            VStack(spacing: AppSpacing.small) {
                // 疼痛部位
                if !attack.painLocations.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("疼痛部位")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(attack.painLocations, id: \.self) { location in
                                Text(location.displayName)
                                    .appFont(.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
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
                            .foregroundStyle(AppColors.textSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(attack.painQualities, id: \.self) { quality in
                                Text(quality.rawValue)
                                    .appFont(.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
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
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                // 先兆
                if attack.hasAura {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppColors.warning)
                        Text("有先兆")
                            .appFont(.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(AppColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                }
                
                // 症状列表
                if !attack.symptoms.isEmpty {
                    ForEach(attack.symptoms) { symptom in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(symptom.name)
                                    .appFont(.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                if let description = symptom.symptomDescription, !description.isEmpty {
                                    Text(description)
                                        .appFont(.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                
                                Text(symptom.category.rawValue)
                                    .appFont(.caption)
                                    .foregroundStyle(AppColors.textTertiary)
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
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.warning.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                }
            }
        }
    }
    
    // MARK: - Medications Card
    
    private var medicationsCard: some View {
        DetailCard(title: "用药记录", icon: "pills.fill") {
            VStack(spacing: AppSpacing.small) {
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
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.success.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                }
            }
        }
    }
    
    // MARK: - Weather Card
    
    private func weatherCard(_ weather: WeatherSnapshot) -> some View {
        DetailCard(title: "天气信息", icon: "cloud.sun") {
            VStack(spacing: AppSpacing.small) {
                InfoRow(label: "气压", value: String(format: "%.1f hPa", weather.pressure))
                InfoRow(label: "湿度", value: String(format: "%.0f%%", weather.humidity * 100))
                InfoRow(label: "温度", value: String(format: "%.1f°C", weather.temperature))
                InfoRow(label: "风速", value: String(format: "%.1f km/h", weather.windSpeed))
                InfoRow(label: "气压趋势", value: weather.pressureTrend.rawValue)
                
                if !weather.warnings.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("风险警告")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        ForEach(weather.warnings, id: \.self) { warning in
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppColors.warning)
                                Text(warning)
                                    .appFont(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
    var valueColor: Color = AppColors.textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .appFont(.body)
                .foregroundStyle(AppColors.textSecondary)
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
                    .foregroundStyle(AppColors.textPrimary)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(log.takenAt.formatted(date: .omitted, time: .shortened))
                    .appFont(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            HStack {
                if let medication = log.medication {
                    Label(medication.category.rawValue, systemImage: "pills")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    Label("未分类", systemImage: "pills")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                Text(log.dosageString)
                    .appFont(.caption)
                    .foregroundStyle(AppColors.textSecondary)
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
        .padding(AppSpacing.small)
        .background(AppColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
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
