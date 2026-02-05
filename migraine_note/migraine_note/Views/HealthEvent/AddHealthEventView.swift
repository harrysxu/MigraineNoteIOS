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
                    Picker("事件类型", selection: $eventType) {
                        ForEach(HealthEventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("选择事件类型")
                }
                
                // 日期时间
                Section {
                    DatePicker("日期时间", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("发生时间")
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
                    TextField("记录备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("备注")
                }
            }
            .navigationTitle("添加健康事件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
                        Text("添加用药")
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                    }
                }
                
                // 已添加的药物列表
                if let viewModel = medicationViewModel, !viewModel.selectedMedications.isEmpty {
                    ForEach(Array(viewModel.selectedMedications.enumerated()), id: \.offset) { index, medInfo in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(medInfo.medication?.name ?? medInfo.customName ?? "未知药物")
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
                Text("药物信息")
            } footer: {
                if let viewModel = medicationViewModel, !viewModel.selectedMedications.isEmpty {
                    Text("已添加 \(viewModel.selectedMedications.count) 种药物")
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }
    
    // MARK: - 中医治疗表单
    
    private var tcmTreatmentSection: some View {
        Group {
            Section {
                Picker("治疗类型", selection: $tcmTreatmentType) {
                    ForEach(TCMTreatmentType.allCases, id: \.rawValue) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }
                
                // 如果选择了"其他"，显示自定义输入
                if tcmTreatmentType == TCMTreatmentType.other.rawValue {
                    TextField("请输入治疗类型", text: $customTcmType)
                }
            } header: {
                Text("治疗类型")
            }
            
            Section {
                HStack {
                    Text("治疗时长")
                    Spacer()
                    Text("\(Int(tcmDuration))分钟")
                        .foregroundStyle(Color.textSecondary)
                }
                
                Slider(value: $tcmDuration, in: 5...120, step: 5)
            } header: {
                Text("治疗时长（可选）")
            }
        }
    }
    
    // MARK: - 手术事件表单
    
    private var surgerySection: some View {
        Group {
            Section {
                TextField("手术名称", text: $surgeryName)
            } header: {
                Text("手术信息")
            }
            
            Section {
                TextField("医院名称（可选）", text: $hospitalName)
                TextField("医生姓名（可选）", text: $doctorName)
            } header: {
                Text("医疗机构")
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
