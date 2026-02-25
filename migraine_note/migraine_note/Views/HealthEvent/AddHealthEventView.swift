//
//  AddHealthEventView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/5.
//  健康事件记录表单
//

import SwiftUI
import SwiftData

struct AddHealthEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventType: HealthEventType = .medication
    @State private var eventDate: Date = Date()
    @State private var notes: String = ""
    
    // 用药事件 - 使用 ViewModel 管理
    @State private var medicationViewModel: HealthEventMedicationViewModel?
    @State private var showMedicationSheet = false
    
    // 中医治疗字段
    @State private var tcmTreatmentType: String = TCMTreatmentType.acupuncture.rawValue
    @State private var customTcmType: String = ""
    @State private var tcmDuration: Double = 30 // 默认30分钟
    
    // 手术事件字段
    @State private var surgeryName: String = ""
    @State private var hospitalName: String = ""
    @State private var doctorName: String = ""
    
    @Query(sort: \Medication.name) private var allMedications: [Medication]
    
    var body: some View {
        NavigationStack {
            Form {
                // 事件类型选择
                Section {
                    Picker(String(localized: "health.event.type.picker"), selection: $eventType) {
                        ForEach(HealthEventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(String(localized: "health.event.type.select"))
                }
                
                // 日期时间
                Section {
                    DatePicker(String(localized: "health.event.datetime"), selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text(String(localized: "health.event.occurred.time"))
                }
                
                // 根据事件类型显示不同的表单
                switch eventType {
                case .medication:
                    medicationEventSection
                case .tcmTreatment:
                    tcmTreatmentSection
                case .surgery:
                    surgerySection
                }
                
                // 备注（所有类型通用）
                Section {
                    TextField(String(localized: "health.event.notes.placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(String(localized: "form.notes"))
                }
            }
            .navigationTitle(String(localized: "health.event.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        saveHealthEvent()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showMedicationSheet) {
                if let viewModel = medicationViewModel {
                    UnifiedMedicationInputSheet(
                        viewModel: viewModel,
                        isPresented: $showMedicationSheet
                    )
                }
            }
            .onAppear {
                if medicationViewModel == nil {
                    medicationViewModel = HealthEventMedicationViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    // MARK: - 用药事件表单
    
    private var medicationEventSection: some View {
        Group {
            Section {
                // 添加药物按钮
                Button {
                    showMedicationSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                            .font(.title3)
                        Text(String(localized: "health.event.add.medication"))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                    }
                }
                
                // 已添加的药物列表
                if let viewModel = medicationViewModel, !viewModel.selectedMedications.isEmpty {
                    ForEach(Array(viewModel.selectedMedications.enumerated()), id: \.offset) { index, medInfo in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(medInfo.medication?.name ?? medInfo.customName ?? String(localized: "health.event.unknown.medication"))
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.textPrimary)
                                Text("\(String(format: "%.0f", medInfo.dosage))\(medInfo.unit) - \(medInfo.timeTaken.shortTime())")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            Button {
                                viewModel.removeMedication(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.statusError)
                            }
                        }
                    }
                }
            } header: {
                Text(String(localized: "health.event.medication.info"))
            } footer: {
                if let viewModel = medicationViewModel, !viewModel.selectedMedications.isEmpty {
                    Text(String(format: String(localized: "health.event.medication.count"), viewModel.selectedMedications.count))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    // MARK: - 中医治疗表单
    
    private var tcmTreatmentSection: some View {
        Group {
            Section {
                Picker(String(localized: "health.event.treatment.type"), selection: $tcmTreatmentType) {
                    ForEach(TCMTreatmentType.allCases, id: \.rawValue) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }
                
                // 如果选择了"其他"，显示自定义输入
                if tcmTreatmentType == TCMTreatmentType.other.rawValue {
                    TextField(String(localized: "health.event.treatment.type.placeholder"), text: $customTcmType)
                }
            } header: {
                Text(String(localized: "health.event.treatment.type"))
            }
            
            Section {
                HStack {
                    Text(String(localized: "health.event.duration"))
                    Spacer()
                    Text("\(Int(tcmDuration))\(String(localized: "form.duration.minute"))")
                        .foregroundStyle(Color.textSecondary)
                }
                
                Slider(value: $tcmDuration, in: 5...120, step: 5)
            } header: {
                Text(String(localized: "health.event.duration.optional"))
            }
        }
    }
    
    // MARK: - 手术事件表单
    
    private var surgerySection: some View {
        Group {
            Section {
                TextField(String(localized: "health.event.surgery.name"), text: $surgeryName)
            } header: {
                Text(String(localized: "health.event.surgery.info"))
            }
            
            Section {
                TextField(String(localized: "health.event.hospital.optional"), text: $hospitalName)
                TextField(String(localized: "health.event.doctor.optional"), text: $doctorName)
            } header: {
                Text(String(localized: "health.event.medical.facility"))
            }
        }
    }
    
    // MARK: - 验证和保存
    
    private var canSave: Bool {
        switch eventType {
        case .medication:
            // 需要至少添加一种药物
            return medicationViewModel?.selectedMedications.isEmpty == false
        case .tcmTreatment:
            // 需要有治疗类型
            if tcmTreatmentType == TCMTreatmentType.other.rawValue {
                return !customTcmType.trimmingCharacters(in: .whitespaces).isEmpty
            }
            return true
        case .surgery:
            // 需要有手术名称
            return !surgeryName.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    private func saveHealthEvent() {
        let event = HealthEvent(eventType: eventType, eventDate: eventDate)
        event.notes = notes.isEmpty ? nil : notes
        
        switch eventType {
        case .medication:
            // 创建多个用药记录
            guard let viewModel = medicationViewModel else { return }
            
            for medInfo in viewModel.selectedMedications {
                let medLog = MedicationLog(
                    dosage: medInfo.dosage,
                    timeTaken: medInfo.timeTaken
                )
                medLog.medication = medInfo.medication
                medLog.medicationName = medInfo.customName
                medLog.unit = medInfo.unit
                
                modelContext.insert(medLog)
                event.medicationLogs.append(medLog)
            }
            
        case .tcmTreatment:
            event.tcmTreatmentType = tcmTreatmentType == TCMTreatmentType.other.rawValue ? customTcmType : tcmTreatmentType
            event.tcmDuration = tcmDuration * 60 // 转换为秒
            
        case .surgery:
            event.surgeryName = surgeryName
            event.hospitalName = hospitalName.isEmpty ? nil : hospitalName
            event.doctorName = doctorName.isEmpty ? nil : doctorName
        }
        
        modelContext.insert(event)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("保存健康事件失败: \(error)")
        }
    }
}

#Preview {
    AddHealthEventView()
        .modelContainer(for: [HealthEvent.self, Medication.self], inMemory: true)
}
