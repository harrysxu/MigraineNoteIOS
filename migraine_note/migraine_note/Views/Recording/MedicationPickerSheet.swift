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

#Preview {
    MedicationPickerSheet { medication, dosage, time in
        print("Selected: \(medication.name), \(dosage)\(medication.unit), \(time)")
    }
    .modelContainer(for: Medication.self, inMemory: true)
}
