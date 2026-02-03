//
//  Step3_SymptomsView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct Step3_SymptomsView: View {
    @Bindable var viewModel: RecordingViewModel
    @Environment(\.modelContext) private var modelContext
    
    // 查询所有症状标签（仅显示未隐藏的）
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "symptom" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var symptomLabels: [CustomLabelConfig]
    
    // 计算西医症状和中医症状
    private var westernSymptoms: [CustomLabelConfig] {
        symptomLabels.filter { $0.subcategory == SymptomSubcategory.western.rawValue }
    }
    
    private var tcmSymptoms: [CustomLabelConfig] {
        symptomLabels.filter { $0.subcategory == SymptomSubcategory.tcm.rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 先兆
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("是否有先兆？")
                        .font(.headline)
                    
                    HStack(spacing: Spacing.md) {
                        StatusToggle(title: "否", icon: "xmark.circle", isSelected: !viewModel.hasAura) {
                            viewModel.hasAura = false
                            viewModel.selectedAuraTypes = []
                        }
                        
                        StatusToggle(title: "是", icon: "checkmark.circle", isSelected: viewModel.hasAura) {
                            viewModel.hasAura = true
                        }
                    }
                    
                    if viewModel.hasAura {
                        Divider()
                            .padding(.vertical, Spacing.xs)
                        
                        Text("先兆类型")
                            .font(.subheadline)
                            .foregroundStyle(Color.labelSecondary)
                        
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(AuraType.allCases, id: \.self) { aura in
                                SelectableChip(
                                    label: aura.rawValue,
                                    isSelected: Binding(
                                        get: { viewModel.selectedAuraTypes.contains(aura) },
                                        set: { isSelected in
                                            if isSelected {
                                                viewModel.selectedAuraTypes.insert(aura)
                                            } else {
                                                viewModel.selectedAuraTypes.remove(aura)
                                            }
                                        }
                                    )
                                )
                            }
                        }
                        
                        // 先兆持续时间
                        HStack {
                            Text("持续时长(分钟)")
                                .font(.subheadline)
                            TextField("5-60", value: $viewModel.auraDuration, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.hasAura)
            
            // 西医症状
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("伴随症状")
                        .font(.headline)
                    
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(westernSymptoms, id: \.id) { label in
                            SelectableChip(
                                label: label.displayName,
                                isSelected: Binding(
                                    get: { viewModel.selectedSymptomNames.contains(label.displayName) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedSymptomNames.insert(label.displayName)
                                        } else {
                                            viewModel.selectedSymptomNames.remove(label.displayName)
                                        }
                                    }
                                )
                            )
                        }
                        
                        // 添加自定义西医症状
                        AddCustomLabelChip(
                            category: .symptom,
                            subcategory: SymptomSubcategory.western.rawValue
                        ) { newLabel in
                            viewModel.selectedSymptomNames.insert(newLabel)
                        }
                    }
                }
            }
            
            // 中医症状
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("中医症状")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Color.statusSuccess)
                            .font(.caption)
                    }
                    
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(tcmSymptoms, id: \.id) { label in
                            SelectableChip(
                                label: label.displayName,
                                isSelected: Binding(
                                    get: { viewModel.selectedSymptomNames.contains(label.displayName) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedSymptomNames.insert(label.displayName)
                                        } else {
                                            viewModel.selectedSymptomNames.remove(label.displayName)
                                        }
                                    }
                                )
                            )
                        }
                        
                        // 添加自定义中医症状
                        AddCustomLabelChip(
                            category: .symptom,
                            subcategory: SymptomSubcategory.tcm.rawValue
                        ) { newLabel in
                            viewModel.selectedSymptomNames.insert(newLabel)
                        }
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
                Step3_SymptomsView(viewModel: viewModel)
                    .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return PreviewContainer()
}
