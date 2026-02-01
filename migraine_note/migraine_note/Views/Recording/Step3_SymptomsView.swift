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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 先兆
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("是否有先兆？")
                        .font(.headline)
                    
                    HStack(spacing: Spacing.md) {
                        StatusToggle(title: "否", isSelected: !viewModel.hasAura) {
                            viewModel.hasAura = false
                            viewModel.selectedAuraTypes = []
                        }
                        
                        StatusToggle(title: "是", isSelected: viewModel.hasAura) {
                            viewModel.hasAura = true
                        }
                    }
                    
                    if viewModel.hasAura {
                        Divider()
                            .padding(.vertical, Spacing.xs)
                        
                        Text("先兆类型")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                        
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
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("伴随症状")
                        .font(.headline)
                    
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(SymptomType.allCases.filter { $0.isWesternMedicine }, id: \.self) { symptom in
                            SelectableChip(
                                label: symptom.rawValue,
                                isSelected: Binding(
                                    get: { viewModel.selectedSymptoms.contains(symptom) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedSymptoms.insert(symptom)
                                        } else {
                                            viewModel.selectedSymptoms.remove(symptom)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }
            
            // 中医症状
            InfoCard {
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
                        ForEach(SymptomType.allCases.filter { $0.isTCM }, id: \.self) { symptom in
                            SelectableChip(
                                label: symptom.rawValue,
                                isSelected: Binding(
                                    get: { viewModel.selectedSymptoms.contains(symptom) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedSymptoms.insert(symptom)
                                        } else {
                                            viewModel.selectedSymptoms.remove(symptom)
                                        }
                                    }
                                )
                            )
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
