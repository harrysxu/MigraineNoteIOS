//
//  MedicationPickerSheet.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 药箱选择器 - 用于从药箱中选择药物
struct MedicationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var medications: [Medication]
    
    let onSelect: (Medication, Double, Date) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedCategory: MedicationCategoryFilter = .all
    @State private var selectedMedication: Medication?
    @State private var showDosageInput: Bool = false
    @State private var dosage: Double = 0
    @State private var timeTaken: Date = Date()
    
    enum MedicationCategoryFilter: String, CaseIterable {
        case all = "全部"
        case acute = "急性用药"
        case preventive = "预防性用药"
        
        var systemImage: String {
            switch self {
            case .all: return "pills.circle"
            case .acute: return "pills.fill"
            case .preventive: return "cross.case.fill"
            }
        }
    }
    
    var filteredMedications: [Medication] {
        var filtered = medications
        
        // 应用类别筛选
        switch selectedCategory {
        case .all:
            break
        case .acute:
            filtered = filtered.filter { $0.isAcute }
        case .preventive:
            filtered = filtered.filter { !$0.isAcute }
        }
        
        // 应用搜索
        if !searchText.isEmpty {
            filtered = filtered.filter { medication in
                medication.name.localizedCaseInsensitiveContains(searchText) ||
                medication.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()
                
                if medications.isEmpty {
                    emptyStateView
                } else if let selected = selectedMedication, showDosageInput {
                    dosageInputView(for: selected)
                } else {
                    medicationListView
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
            .searchable(text: $searchText, prompt: "搜索药物名称")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pill.circle")
                .font(.system(size: 80))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            
            Text("药箱是空的")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.textPrimary)
            
            Text("请先在药箱中添加常用药物")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Medication List
    
    private var medicationListView: some View {
        VStack(spacing: 0) {
            // 分类筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MedicationCategoryFilter.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.systemImage)
                                    .font(.caption)
                                Text(category.rawValue)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(selectedCategory == category ? .white : Color.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedCategory == category ?
                                    Color.accentPrimary :
                                    Color.backgroundSecondary
                            )
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            
            Divider()
            
            // 药物列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    if filteredMedications.isEmpty {
                        noResultsView
                    } else {
                        ForEach(filteredMedications) { medication in
                            MedicationPickerRow(medication: medication) {
                                selectMedication(medication)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            
            Text("未找到匹配的药物")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            
            Text("尝试调整搜索或筛选条件")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Dosage Input View
    
    private func dosageInputView(for medication: Medication) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 药物信息
                EmotionalCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(medication.name)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text(medication.category.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(medication.isAcute ? "急性" : "预防")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(medication.isAcute ? Color.statusWarning : Color.statusSuccess)
                                .cornerRadius(8)
                        }
                        
                        if let notes = medication.notes {
                            Divider()
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
                
                // 剂量输入
                EmotionalCard(style: .default) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundStyle(Color.accentPrimary)
                            Text("剂量")
                                .font(.headline)
                        }
                        
                        HStack(spacing: 12) {
                            TextField("剂量", value: $dosage, format: .number)
                                .keyboardType(.decimalPad)
                                .font(.title2.weight(.medium))
                                .foregroundStyle(Color.textPrimary)
                                .padding(12)
                                .background(Color.backgroundTertiary)
                                .cornerRadius(8)
                            
                            Text(medication.unit)
                                .font(.title3)
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 60, alignment: .leading)
                        }
                        
                        // 标准剂量提示
                        if medication.standardDosage > 0 {
                            Button {
                                dosage = medication.standardDosage
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.caption)
                                    Text("使用标准剂量：\(medication.standardDosage, specifier: "%.1f") \(medication.unit)")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(Color.accentPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accentPrimary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // 服用时间
                EmotionalCard(style: .default) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.accentPrimary)
                            Text("服用时间")
                                .font(.headline)
                        }
                        
                        DatePicker(
                            "时间",
                            selection: $timeTaken,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }
                
                // 确认按钮
                PrimaryButton(
                    title: "添加用药记录",
                    action: {
                        onSelect(medication, dosage, timeTaken)
                        dismiss()
                    },
                    isEnabled: dosage > 0
                )
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Color.backgroundPrimary)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showDosageInput = false
                    selectedMedication = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectMedication(_ medication: Medication) {
        selectedMedication = medication
        dosage = medication.standardDosage
        timeTaken = Date()
        
        withAnimation(.spring(response: 0.3)) {
            showDosageInput = true
        }
    }
}

// MARK: - Medication Picker Row

struct MedicationPickerRow: View {
    let medication: Medication
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 药物图标
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.accentPrimary.opacity(0.15))
                    .clipShape(Circle())
                
                // 药物信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(medication.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        if medication.standardDosage > 0 {
                            Text("•")
                                .foregroundStyle(Color.textTertiary)
                            Text("\(medication.standardDosage, specifier: "%.1f")\(medication.unit)")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(16)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 统一药物输入表单

struct UnifiedMedicationInputSheet<ViewModel: MedicationManaging>: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: ViewModel
    @Binding var isPresented: Bool
    
    @Query(sort: \Medication.name) private var allMedications: [Medication]
    
    @State private var searchText: String = ""
    @State private var selectedMedication: Medication?
    @State private var dosage: String = ""
    @State private var unit: String = "mg"
    @State private var timeTaken: Date = Date()
    @State private var showMedicationList: Bool = false
    @State private var saveToMedicineBox: Bool = false
    @State private var isSelectingFromCabinet: Bool = false
    
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
                                    if isSelectingFromCabinet {
                                        // 从药箱选择触发的文本变化，不清除已选药物
                                        isSelectingFromCabinet = false
                                    } else {
                                        // 用户手动输入，清除已选择的药物
                                        selectedMedication = nil
                                    }
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
                        isSelectingFromCabinet = true
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
    MedicationPickerSheet { medication, dosage, time in
        print("Selected: \(medication.name), \(dosage)\(medication.unit), \(time)")
    }
    .modelContainer(for: Medication.self, inMemory: true)
}
