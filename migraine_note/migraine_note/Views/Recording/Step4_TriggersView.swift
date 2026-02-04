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
    @Environment(\.modelContext) private var modelContext
    
    @State private var suggestedTriggers: [String] = []
    
    // 查询所有诱因标签（仅显示未隐藏的）
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "trigger" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var triggerLabels: [CustomLabelConfig]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 说明文字
            Text("选择可能导致本次发作的诱因")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            
            // 智能推荐（如果有）
            if !suggestedTriggers.isEmpty {
                smartSuggestionsCard
            }
            
            // 各类诱因
            ForEach(TriggerCategory.allCases, id: \.self) { category in
                triggerSection(for: category)
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
        .onAppear {
            loadSmartSuggestions()
        }
    }
    
    // MARK: - 智能推荐卡片
    
    private var smartSuggestionsCard: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.warmAccent)
                    Text("根据您的记录，这些诱因常见：")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                }
                
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(suggestedTriggers.prefix(5), id: \.self) { trigger in
                        Button {
                            toggleTrigger(trigger)
                            // 触觉反馈
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        } label: {
                            HStack(spacing: 6) {
                                Text(trigger)
                                    .font(.subheadline)
                                if viewModel.selectedTriggers.contains(trigger) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedTriggers.contains(trigger)
                                    ? Color.warmAccent
                                    : Color.warmAccent.opacity(0.2)
                            )
                            .foregroundStyle(
                                viewModel.selectedTriggers.contains(trigger)
                                    ? .white
                                    : Color.textPrimary
                            )
                            .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func loadSmartSuggestions() {
        // 这里应该从历史数据中分析常见诱因
        // 目前使用模拟数据作为示例
        let commonTriggers = ["压力", "睡眠不足", "天气变化"]
        suggestedTriggers = commonTriggers
    }
    
    private func toggleTrigger(_ trigger: String) {
        if viewModel.selectedTriggers.contains(trigger) {
            viewModel.selectedTriggers.removeAll { $0 == trigger }
        } else {
            viewModel.selectedTriggers.append(trigger)
        }
    }
    
    @ViewBuilder
    private func triggerSection(for category: TriggerCategory) -> some View {
        // 获取该分类下的所有诱因标签
        let categoryTriggers = triggerLabels.filter { $0.subcategory == category.rawValue }
        
        // 始终显示该区块，即使没有标签（用户可以添加自定义标签）
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(categoryIcon(for: category))
                        .font(.title3)
                    Text(category.rawValue)
                        .font(.headline)
                }
                
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(categoryTriggers, id: \.id) { label in
                        SelectableChip(
                            label: label.displayName,
                            isSelected: Binding(
                                get: { viewModel.selectedTriggers.contains(label.displayName) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedTriggers.append(label.displayName)
                                        // 添加触觉反馈
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    } else {
                                        viewModel.selectedTriggers.removeAll { $0 == label.displayName }
                                    }
                                }
                            )
                        )
                    }
                    
                    // 添加自定义诱因
                    AddCustomLabelChip(
                        category: .trigger,
                        subcategory: category.rawValue
                    ) { newLabel in
                        viewModel.selectedTriggers.append(newLabel)
                        // 添加触觉反馈
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
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
