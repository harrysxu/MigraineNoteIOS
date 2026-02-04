//
//  Step5_InterventionsView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct Step5_InterventionsView: View {
    @Bindable var viewModel: RecordingViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showAddMedicationSheet: Bool = false
    
    // 查询非药物干预标签
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "intervention" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var interventionLabels: [CustomLabelConfig]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 药物治疗
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(Color.accentPrimary)
                        Text("药物治疗")
                            .font(.headline)
                        Spacer()
                        Button {
                            showAddMedicationSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
                    
                    if viewModel.selectedMedications.isEmpty {
                        Text("未记录用药")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        ForEach(Array(viewModel.selectedMedications.enumerated()), id: \.offset) { index, medInfo in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(medInfo.medication?.name ?? medInfo.customName ?? "未知药物")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(String(format: "%.0f", medInfo.dosage))\(medInfo.unit) - \(medInfo.timeTaken.shortTime())")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                Spacer()
                                Button {
                                    viewModel.removeMedication(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.statusDanger)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                            
                            if index < viewModel.selectedMedications.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            
            // 非药物疗法
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "figure.mind.and.body")
                            .foregroundStyle(Color.accentPrimary)
                        Text("非药物疗法")
                            .font(.headline)
                    }
                    
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(interventionLabels, id: \.id) { label in
                            SelectableChip(
                                label: label.displayName,
                                isSelected: Binding(
                                    get: { viewModel.selectedNonPharmacological.contains(label.displayName) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedNonPharmacological.insert(label.displayName)
                                        } else {
                                            viewModel.selectedNonPharmacological.remove(label.displayName)
                                        }
                                    }
                                )
                            )
                        }
                        
                        // 添加自定义非药物干预
                        AddCustomLabelChip(
                            category: .intervention,
                            subcategory: nil
                        ) { newLabel in
                            viewModel.selectedNonPharmacological.insert(newLabel)
                        }
                    }
                }
            }
            
            // 备注
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("备注（可选）")
                        .font(.headline)
                    
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 100)
                        .padding(Spacing.xs)
                        .background(Color.backgroundTertiary)
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .sheet(isPresented: $showAddMedicationSheet) {
            UnifiedMedicationInputSheet(viewModel: viewModel, isPresented: $showAddMedicationSheet)
        }
    }
}

// MARK: - 统一药物输入对话框

struct UnifiedMedicationInputSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: RecordingViewModel
    @Binding var isPresented: Bool
    
    @Query(sort: \Medication.name) private var allMedications: [Medication]
    
    @State private var searchText: String = ""
    @State private var selectedMedication: Medication?
    @State private var dosage: String = ""
    @State private var unit: String = "mg"
    @State private var timeTaken: Date = Date()
    @State private var showMedicationList: Bool = false
    @State private var saveToMedicineBox: Bool = false
    
    private var filteredMedications: [Medication] {
        if searchText.isEmpty {
            return allMedications
        }
        return allMedications.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var medicationExists: Bool {
        let trimmedName = searchText.trimmingCharacters(in: .whitespaces)
        return allMedications.contains { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }
    }
    
    private var isManualInput: Bool {
        selectedMedication == nil && !searchText.isEmpty
    }
    
    private var shouldShowSyncOption: Bool {
        isManualInput && !medicationExists
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("药物选择") {
                    // 从药箱选择按钮（始终显示）
                    if !allMedications.isEmpty {
                        Button {
                            showMedicationList = true
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .foregroundStyle(Color.accentPrimary)
                                Text("从药箱选择")
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                if selectedMedication != nil {
                                    Text(selectedMedication!.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.textSecondary)
                                } else {
                                    Text("共\(allMedications.count)个药品")
                                        .font(.caption)
                                        .foregroundStyle(Color.textTertiary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                    }
                    
                    // 或手动输入
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("或手动输入药物名称", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .onChange(of: searchText) {
                                    // 清除已选择的药物，切换为手动输入模式
                                    selectedMedication = nil
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    selectedMedication = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.textTertiary)
                                }
                            }
                        }
                        
                        // 提示信息
                        if medicationExists && isManualInput {
                            Label("药箱中已有此药品，可点击上方【从药箱选择】", systemImage: "info.circle")
                                .font(.caption)
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
                }
                
                Section("剂量信息") {
                    HStack {
                        TextField("剂量", text: $dosage)
                            .keyboardType(.decimalPad)
                        
                        Picker("单位", selection: $unit) {
                            Text("mg").tag("mg")
                            Text("片").tag("片")
                            Text("粒").tag("粒")
                            Text("g").tag("g")
                            Text("ml").tag("ml")
                        }
                        .pickerStyle(.menu)
                    }
                    
                    if let med = selectedMedication, med.standardDosage > 0 {
                        Button("使用标准剂量 (\(String(format: "%.0f", med.standardDosage))\(med.unit))") {
                            dosage = String(format: "%.0f", med.standardDosage)
                            unit = med.unit
                        }
                        .font(.caption)
                    }
                }
                
                Section("服用时间") {
                    DatePicker("时间", selection: $timeTaken, displayedComponents: [.date, .hourAndMinute])
                }
                
                if shouldShowSyncOption {
                    Section {
                        Toggle("同步到药箱", isOn: $saveToMedicineBox)
                        
                        if saveToMedicineBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("将使用以下默认设置:", systemImage: "info.circle")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• 药物类型: 其他")
                                    Text("• 用药类型: 急需用药")
                                    Text("• 标准剂量: 1")
                                    Text("• 库存: 6")
                                }
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                            }
                            .padding(.top, 4)
                        }
                    } header: {
                        Text("药箱管理")
                    } footer: {
                        if saveToMedicineBox {
                            Text("保存后可在药箱中修改详细信息")
                        }
                    }
                }
            }
            .navigationTitle("添加用药记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addMedication()
                    }
                    .disabled(!canSubmit)
                }
            }
            .sheet(isPresented: $showMedicationList) {
                MedicationSelectionList(
                    medications: searchText.isEmpty ? allMedications : filteredMedications,
                    searchText: searchText,
                    onSelect: { medication in
                        selectedMedication = medication
                        searchText = medication.name
                        dosage = String(format: "%.0f", medication.standardDosage > 0 ? medication.standardDosage : 1.0)
                        unit = medication.unit
                        showMedicationList = false
                    }
                )
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var canSubmit: Bool {
        let hasValidInput = selectedMedication != nil || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasValidDosage = !dosage.isEmpty && Double(dosage) != nil
        return hasValidInput && hasValidDosage
    }
    
    private func addMedication() {
        guard let dosageValue = Double(dosage) else { return }
        
        var medication: Medication? = selectedMedication
        let medicationName = searchText.trimmingCharacters(in: .whitespaces)
        
        // 如果是手动输入且需要同步到药箱
        if shouldShowSyncOption && saveToMedicineBox {
            medication = viewModel.syncMedicationToCabinet(
                name: medicationName,
                dosage: 1.0,  // 默认标准剂量为1
                unit: unit
            )
        }
        
        // 添加到记录
        viewModel.addMedication(
            medication: medication,
            customName: medication == nil ? medicationName : nil,
            dosage: dosageValue,
            unit: unit,
            timeTaken: timeTaken
        )
        
        isPresented = false
    }
}

// MARK: - 药物选择列表

struct MedicationSelectionList: View {
    let medications: [Medication]
    let searchText: String
    let onSelect: (Medication) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(medications) { medication in
                Button {
                    onSelect(medication)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                        
                        HStack {
                            Text(medication.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            
                            if medication.standardDosage > 0 {
                                Text("•")
                                    .foregroundStyle(Color.textTertiary)
                                Text("\(String(format: "%.0f", medication.standardDosage))\(medication.unit)")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("选择药物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var viewModel = RecordingViewModel(
            modelContext: ModelContext(
                try! ModelContainer(for: AttackRecord.self, configurations: .init(isStoredInMemoryOnly: true))
            )
        )
        
        var body: some View {
            ScrollView {
                Step5_InterventionsView(viewModel: viewModel)
                    .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return PreviewContainer()
}
