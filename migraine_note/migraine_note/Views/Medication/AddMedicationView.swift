//
//  AddMedicationView.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  添加新药物的表单页面
//

import SwiftUI
import SwiftData

// MARK: - Medication Metadata Structure

private struct MedicationMetadata: Codable {
    let dosage: Double
    let unit: String
}

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 查询所有药物预设标签（仅显示未隐藏的）
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "medication" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var presetLabels: [CustomLabelConfig]
    
    @State private var name: String = ""
    @State private var selectedCategory: MedicationCategory = .nsaid
    @State private var isAcute: Bool = true
    @State private var standardDosage: Double = 0
    @State private var unit: String = "mg"
    @State private var inventory: Int = 0
    @State private var monthlyLimit: Int?
    @State private var notes: String = ""
    
    @State private var showingPresets = false
    @State private var selectedPresetCategory: PresetCategory = .nsaid
    
    // 过滤后的预设药品列表
    private var filteredPresets: [MedicationPreset] {
        guard !name.isEmpty else { return [] }
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces).lowercased()
        
        return presetLabels
            .filter { label in
                label.displayName.lowercased().contains(trimmedName)
            }
            .compactMap { label -> MedicationPreset? in
                guard let subcategory = label.subcategory,
                      let category = MedicationCategory.allCases.first(where: { $0.rawValue == subcategory }) else {
                    return nil
                }
                
                // 解析剂量信息
                var dosage: Double = 0
                var unit: String = "mg"
                
                if let metadata = label.metadata,
                   let data = metadata.data(using: .utf8),
                   let medicationMeta = try? JSONDecoder().decode(MedicationMetadata.self, from: data) {
                    dosage = medicationMeta.dosage
                    unit = medicationMeta.unit
                }
                
                return MedicationPreset(
                    name: label.displayName,
                    category: category,
                    isAcute: category.isAcuteMedication,
                    dosage: dosage,
                    unit: unit
                )
            }
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && standardDosage > 0
    }
    
    // MARK: - Medication Name Search Field
    
    private var medicationNameSearchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("药物名称", text: $name)
                    .textInputAutocapitalization(.never)
                
                if !name.isEmpty {
                    Button {
                        name = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            
            // 实时显示匹配的预设（最多显示5个）
            if !filteredPresets.isEmpty {
                medicationPresetsInlineList
            }
        }
    }
    
    private var medicationPresetsInlineList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(filteredPresets.prefix(5).enumerated()), id: \.offset) { index, preset in
                Button {
                    applyPreset(preset)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name)
                                .appFont(.subheadline)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("\(preset.dosage, specifier: "%.1f")\(preset.unit) - \(preset.category.rawValue)")
                                .appFont(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(Color.accentPrimary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppColors.backgroundTertiary)
                }
                .buttonStyle(.plain)
                
                if index < min(4, filteredPresets.count - 1) {
                    Divider()
                        .padding(.leading, 12)
                }
            }
            
            // 如果有更多结果，显示"查看全部"按钮
            if filteredPresets.count > 5 {
                Button {
                    showingPresets = true
                } label: {
                    HStack {
                        Text("查看全部 \(filteredPresets.count) 个预设...")
                            .appFont(.caption)
                            .foregroundStyle(Color.accentPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppColors.backgroundTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppColors.backgroundTertiary)
        .cornerRadius(CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(AppColors.textTertiary.opacity(0.2), lineWidth: 1)
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    // 药物名称搜索框
                    medicationNameSearchField
                    
                    Picker("药物类别", selection: $selectedCategory) {
                        ForEach(MedicationCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    Picker("用药类型", selection: $isAcute) {
                        Text("急性用药").tag(true)
                        Text("预防性用药").tag(false)
                    }
                    .onChange(of: selectedCategory) { _, newValue in
                        // 根据类别自动设置用药类型
                        isAcute = newValue.isAcuteMedication
                    }
                }
                
                // 剂量信息
                Section("剂量信息") {
                    HStack {
                        Text("标准剂量")
                        Spacer()
                        TextField("剂量", value: $standardDosage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    Picker("单位", selection: $unit) {
                        Text("mg").tag("mg")
                        Text("片").tag("片")
                        Text("粒").tag("粒")
                        Text("g").tag("g")
                        Text("ml").tag("ml")
                    }
                }
                
                // 库存管理
                Section("库存管理") {
                    Stepper(value: $inventory, in: 0...999) {
                        HStack {
                            Text("当前库存")
                            Spacer()
                            Text("\(inventory)")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                
                // MOH阈值（仅急性用药）
                if isAcute {
                    Section {
                        Toggle("设置月度使用限制（MOH预防）", isOn: Binding(
                            get: { monthlyLimit != nil },
                            set: { enabled in
                                if enabled {
                                    // 根据类别设置默认阈值
                                    switch selectedCategory {
                                    case .nsaid:
                                        monthlyLimit = 15
                                    case .triptan, .ergotamine, .opioid:
                                        monthlyLimit = 10
                                    default:
                                        monthlyLimit = 15
                                    }
                                } else {
                                    monthlyLimit = nil
                                }
                            }
                        ))
                        
                        if monthlyLimit != nil {
                            Stepper(value: Binding(
                                get: { monthlyLimit ?? 15 },
                                set: { monthlyLimit = $0 }
                            ), in: 5...30) {
                                HStack {
                                    Text("月度限制")
                                    Spacer()
                                    Text("\(monthlyLimit ?? 15) 天")
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                            
                            Text("超过此天数将触发MOH（药物过度使用头痛）风险警告")
                                .appFont(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    } header: {
                        Text("MOH预防")
                    } footer: {
                        Text("根据《中国偏头痛指南2024》，NSAID类药物使用≥15天/月，曲普坦类、麦角胺类、阿片类使用≥10天/月可能导致MOH")
                    }
                }
                
                // 备注
                Section("备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                // 快速添加预设
                Section {
                    Button {
                        showingPresets = true
                    } label: {
                        if !name.isEmpty && !filteredPresets.isEmpty {
                            Label("浏览所有匹配的常用药物", systemImage: "list.bullet.clipboard")
                        } else {
                            Label("从常用药物列表选择", systemImage: "list.bullet.clipboard")
                        }
                    }
                }
                .listRowBackground(AppColors.backgroundSecondary)
            }
            .navigationTitle("添加药物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveMedication()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingPresets) {
                MedicationPresetsView(initialSearchText: name) { preset in
                    applyPreset(preset)
                    showingPresets = false
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveMedication() {
        let medication = Medication(
            name: name.trimmingCharacters(in: .whitespaces),
            category: selectedCategory,
            isAcute: isAcute
        )
        medication.standardDosage = standardDosage
        medication.unit = unit
        medication.inventory = inventory
        medication.monthlyLimit = monthlyLimit
        medication.notes = notes.isEmpty ? nil : notes
        
        modelContext.insert(medication)
        try? modelContext.save()
        
        dismiss()
    }
    
    private func applyPreset(_ preset: MedicationPreset) {
        name = preset.name
        selectedCategory = preset.category
        isAcute = preset.isAcute
        standardDosage = preset.dosage
        unit = preset.unit
        
        // 设置默认MOH阈值
        if isAcute {
            switch selectedCategory {
            case .nsaid:
                monthlyLimit = 15
            case .triptan, .ergotamine, .opioid:
                monthlyLimit = 10
            default:
                monthlyLimit = nil
            }
        }
    }
}

// MARK: - Medication Presets View

struct MedicationPresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 查询所有药物预设标签（仅显示未隐藏的）
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "medication" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var presetLabels: [CustomLabelConfig]
    
    let initialSearchText: String
    let onSelect: (MedicationPreset) -> Void
    
    @State private var searchText: String = ""
    
    init(initialSearchText: String = "", onSelect: @escaping (MedicationPreset) -> Void) {
        self.initialSearchText = initialSearchText
        self.onSelect = onSelect
        self._searchText = State(initialValue: initialSearchText)
    }
    
    // 过滤预设标签
    private var filteredPresetLabels: [CustomLabelConfig] {
        guard !searchText.isEmpty else { return presetLabels }
        
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return presetLabels.filter { label in
            label.displayName.lowercased().contains(trimmedSearch)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 搜索框
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textSecondary)
                        TextField("搜索药物名称", text: $searchText)
                            .textInputAutocapitalization(.never)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    }
                }
                
                // 按类别显示预设
                ForEach(MedicationCategory.allCases, id: \.self) { category in
                    let categoryPresets = presetsForCategory(category)
                    
                    if !categoryPresets.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categoryPresets) { preset in
                                Button {
                                    onSelect(preset)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(preset.name)
                                                .appFont(.body)
                                                .foregroundStyle(AppColors.textPrimary)
                                            Text("\(preset.dosage, specifier: "%.1f") \(preset.unit)")
                                                .appFont(.caption)
                                                .foregroundStyle(AppColors.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 如果没有结果
                if filteredPresetLabels.isEmpty && !searchText.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                                Text("未找到匹配的药物")
                                    .appFont(.body)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .padding(.vertical, 40)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("常用药物列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func presetsForCategory(_ category: MedicationCategory) -> [MedicationPreset] {
        filteredPresetLabels
            .filter { $0.subcategory == category.rawValue }
            .compactMap { label -> MedicationPreset? in
                var dosage: Double = 0
                var unit: String = "mg"
                
                if let metadata = label.metadata,
                   let data = metadata.data(using: .utf8),
                   let medicationMeta = try? JSONDecoder().decode(MedicationMetadata.self, from: data) {
                    dosage = medicationMeta.dosage
                    unit = medicationMeta.unit
                }
                
                return MedicationPreset(
                    name: label.displayName,
                    category: category,
                    isAcute: category.isAcuteMedication,
                    dosage: dosage,
                    unit: unit
                )
            }
    }
}

// MARK: - Supporting Types

enum PresetCategory: CaseIterable {
    case nsaid
    case triptan
    case preventive
    case tcm
    
    var displayName: String {
        switch self {
        case .nsaid: return "非甾体抗炎药(NSAID)"
        case .triptan: return "曲普坦类"
        case .preventive: return "预防性药物"
        case .tcm: return "中成药"
        }
    }
}

struct MedicationPreset: Identifiable {
    let id = UUID()
    let name: String
    let category: MedicationCategory
    let isAcute: Bool
    let dosage: Double
    let unit: String
}

#Preview {
    AddMedicationView()
        .modelContainer(for: Medication.self, inMemory: true)
}
