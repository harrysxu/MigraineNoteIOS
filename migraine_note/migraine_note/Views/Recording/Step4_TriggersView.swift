//
//  Step4_TriggersView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct Step4_TriggersView: View {
    @Bindable var viewModel: RecordingViewModel
    @State private var customTrigger: String = ""
    @State private var showCustomInput: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 说明文字
            Text("选择可能导致本次发作的诱因")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            
            // 各类诱因
            ForEach(TriggerCategory.allCases, id: \.self) { category in
                triggerSection(for: category)
            }
            
            // 自定义诱因
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Button {
                        showCustomInput.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加自定义诱因")
                            Spacer()
                            Image(systemName: showCustomInput ? "chevron.up" : "chevron.down")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.accentPrimary)
                    }
                    
                    if showCustomInput {
                        HStack {
                            TextField("输入诱因名称", text: $customTrigger)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("添加") {
                                addCustomTrigger()
                            }
                            .disabled(customTrigger.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            
            // 已选择的诱因
            if !viewModel.selectedTriggers.isEmpty {
                InfoCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("已选择 \(viewModel.selectedTriggers.count) 个诱因")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(viewModel.selectedTriggers, id: \.self) { trigger in
                                HStack(spacing: 4) {
                                    Text(trigger)
                                        .font(.caption)
                                    Button {
                                        viewModel.selectedTriggers.removeAll { $0 == trigger }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                }
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 4)
                                .background(Color.accentPrimary)
                                .foregroundStyle(.white)
                                .cornerRadius(CornerRadius.sm)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func triggerSection(for category: TriggerCategory) -> some View {
        InfoCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(categoryIcon(for: category))
                        .font(.title3)
                    Text(category.rawValue)
                        .font(.headline)
                }
                
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(TriggerLibrary.triggers(for: category), id: \.self) { trigger in
                        SelectableChip(
                            label: trigger,
                            isSelected: Binding(
                                get: { viewModel.selectedTriggers.contains(trigger) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedTriggers.append(trigger)
                                    } else {
                                        viewModel.selectedTriggers.removeAll { $0 == trigger }
                                    }
                                }
                            )
                        )
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: TriggerCategory) -> String {
        switch category {
        case .food: return "🍜"
        case .environment: return "🌦️"
        case .sleep: return "😴"
        case .stress: return "💼"
        case .hormone: return "🌸"
        case .lifestyle: return "🏃"
        case .tcm: return "🌿"
        }
    }
    
    private func addCustomTrigger() {
        let trigger = customTrigger.trimmingCharacters(in: .whitespaces)
        guard !trigger.isEmpty, !viewModel.selectedTriggers.contains(trigger) else { return }
        
        viewModel.selectedTriggers.append(trigger)
        customTrigger = ""
        showCustomInput = false
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
                Step4_TriggersView(viewModel: viewModel)
                    .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return PreviewContainer()
}
