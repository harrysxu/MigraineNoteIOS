//
//  AddMedicationView.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  添加新药物的表单页面
//

import SwiftUI
import SwiftData

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
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
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && standardDosage > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("药物名称", text: $name)
                    
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
                        Label("从常用药物列表选择", systemImage: "list.bullet.clipboard")
                    }
                }
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
                MedicationPresetsView { preset in
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
    let onSelect: (MedicationPreset) -> Void
    
    private let presets: [PresetCategory: [MedicationPreset]] = [
        .nsaid: [
            MedicationPreset(name: "布洛芬", category: .nsaid, isAcute: true, dosage: 400, unit: "mg"),
            MedicationPreset(name: "对乙酰氨基酚", category: .nsaid, isAcute: true, dosage: 500, unit: "mg"),
            MedicationPreset(name: "阿司匹林", category: .nsaid, isAcute: true, dosage: 500, unit: "mg"),
            MedicationPreset(name: "萘普生", category: .nsaid, isAcute: true, dosage: 500, unit: "mg"),
        ],
        .triptan: [
            MedicationPreset(name: "佐米曲普坦", category: .triptan, isAcute: true, dosage: 2.5, unit: "mg"),
            MedicationPreset(name: "利扎曲普坦", category: .triptan, isAcute: true, dosage: 10, unit: "mg"),
            MedicationPreset(name: "舒马曲普坦", category: .triptan, isAcute: true, dosage: 50, unit: "mg"),
            MedicationPreset(name: "依立曲普坦", category: .triptan, isAcute: true, dosage: 40, unit: "mg"),
        ],
        .preventive: [
            MedicationPreset(name: "氟桂利嗪", category: .preventive, isAcute: false, dosage: 5, unit: "mg"),
            MedicationPreset(name: "普萘洛尔", category: .preventive, isAcute: false, dosage: 40, unit: "mg"),
            MedicationPreset(name: "阿米替林", category: .preventive, isAcute: false, dosage: 25, unit: "mg"),
            MedicationPreset(name: "托吡酯", category: .preventive, isAcute: false, dosage: 50, unit: "mg"),
        ],
        .tcm: [
            MedicationPreset(name: "正天丸", category: .tcmHerbal, isAcute: true, dosage: 6, unit: "g"),
            MedicationPreset(name: "川芎茶调散", category: .tcmHerbal, isAcute: true, dosage: 6, unit: "g"),
            MedicationPreset(name: "天麻钩藤颗粒", category: .tcmHerbal, isAcute: true, dosage: 10, unit: "g"),
        ]
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(PresetCategory.allCases, id: \.self) { category in
                    if let medications = presets[category] {
                        Section(category.displayName) {
                            ForEach(medications) { preset in
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
