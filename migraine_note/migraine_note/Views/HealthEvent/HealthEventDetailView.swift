//
//  HealthEventDetailView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/5.
//  健康事件详情视图
//

import SwiftUI
import SwiftData

struct HealthEventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let event: HealthEvent
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 事件类型和日期
                    headerCard
                    
                    // 详细信息
                    switch event.eventType {
                    case .medication:
                        medicationDetailCard
                    case .tcmTreatment:
                        tcmTreatmentDetailCard
                    case .surgery:
                        surgeryDetailCard
                    }
                    
                    // 备注
                    if let notes = event.notes, !notes.isEmpty {
                        notesCard
                    }
                    
                    Spacer()
                }
                .padding(16)
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("事件详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        EmotionalCard(style: .elevated) {
            VStack(spacing: 16) {
                // 事件类型图标
                Image(systemName: event.eventType.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(eventColor)
                    .frame(width: 80, height: 80)
                    .background(eventColor.opacity(0.15))
                    .clipShape(Circle())
                
                // 事件类型
                Text(event.eventType.rawValue)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                
                // 日期时间
                VStack(spacing: 4) {
                    Text(event.eventDate.formatted(date: .long, time: .omitted))
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                    
                    Text(event.eventDate.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Medication Detail
    
    private var medicationDetailCard: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("用药信息")
                        .font(.headline)
                }
                
                Divider()
                
                if event.medicationLogs.isEmpty {
                    Text("暂无用药信息")
                        .font(.subheadline)
                        .foregroundStyle(Color.textTertiary)
                } else {
                    VStack(spacing: 16) {
                        ForEach(Array(event.medicationLogs.enumerated()), id: \.offset) { index, medLog in
                            VStack(spacing: 12) {
                                if event.medicationLogs.count > 1 {
                                    HStack {
                                        Text("药物 \(index + 1)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.textSecondary)
                                        Spacer()
                                    }
                                }
                                
                                InfoRow(label: "药物名称", value: medLog.displayName)
                                InfoRow(label: "剂量", value: medLog.dosageString)
                                InfoRow(label: "服用时间", value: medLog.timeTaken.formatted(date: .omitted, time: .shortened))
                                
                                if let medication = medLog.medication {
                                    InfoRow(label: "药物分类", value: medication.category.rawValue)
                                }
                            }
                            
                            if index < event.medicationLogs.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - TCM Treatment Detail
    
    private var tcmTreatmentDetailCard: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.statusSuccess)
                    Text("治疗信息")
                        .font(.headline)
                }
                
                Divider()
                
                VStack(spacing: 12) {
                    if let type = event.tcmTreatmentType {
                        InfoRow(label: "治疗类型", value: type)
                    }
                    
                    if let duration = event.tcmDuration, duration > 0 {
                        let minutes = Int(duration / 60)
                        InfoRow(label: "治疗时长", value: "\(minutes)分钟")
                    }
                }
            }
        }
    }
    
    // MARK: - Surgery Detail
    
    private var surgeryDetailCard: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cross.case.fill")
                        .foregroundStyle(Color.statusInfo)
                    Text("手术信息")
                        .font(.headline)
                }
                
                Divider()
                
                VStack(spacing: 12) {
                    if let name = event.surgeryName {
                        InfoRow(label: "手术名称", value: name)
                    }
                    
                    if let hospital = event.hospitalName {
                        InfoRow(label: "医院", value: hospital)
                    }
                    
                    if let doctor = event.doctorName {
                        InfoRow(label: "医生", value: doctor)
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Card
    
    private var notesCard: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(Color.accentSecondary)
                    Text("备注")
                        .font(.headline)
                }
                
                Divider()
                
                Text(event.notes ?? "")
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var eventColor: Color {
        switch event.eventType {
        case .medication:
            return Color.accentPrimary
        case .tcmTreatment:
            return Color.statusSuccess
        case .surgery:
            return Color.statusInfo
        }
    }
}

#Preview {
    let event = HealthEvent(eventType: .medication)
    event.notes = "测试备注"
    
    return HealthEventDetailView(event: event)
}
