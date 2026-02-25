//
//  AuraLabelEditor.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 先兆类型标签编辑器
struct AuraLabelEditor: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "aura"
    }, sort: \CustomLabelConfig.sortOrder)
    private var labels: [CustomLabelConfig]
    
    @State private var showAddSheet = false
    @State private var editingLabel: CustomLabelConfig?
    
    var body: some View {
        List {
            Section {
                ForEach(labels) { label in
                    LabelRow(
                        label: label,
                        onAction: { action in
                            handleAction(action, for: label)
                        }
                    )
                }
                .onMove(perform: moveLabels)
            } header: {
                HStack {
                    Text(String(localized: "label.category.aura"))
                    Spacer()
                    Text(String(format: String(localized: "editor.label.countFormat"), labels.count))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            } footer: {
                Text(String(localized: "editor.footer.dragHint"))
                    .font(.caption)
            }
            
            // 添加新标签按钮
            Section {
                Button {
                    showAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                        Text(String(localized: "editor.aura.addButton"))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddLabelSheet(
                category: .aura,
                subcategory: nil
            )
        }
    }
    
    private func handleAction(_ action: LabelAction, for label: CustomLabelConfig) {
        switch action {
        case .toggleVisibility:
            try? LabelManager.toggleLabelVisibility(label: label, context: modelContext)
        case .delete:
            try? LabelManager.deleteCustomLabel(label: label, context: modelContext)
        case .rename(let newName):
            try? LabelManager.renameLabel(label: label, newName: newName, context: modelContext)
        }
    }
    
    private func moveLabels(from source: IndexSet, to destination: Int) {
        var reorderedLabels = labels
        reorderedLabels.move(fromOffsets: source, toOffset: destination)
        
        // 更新排序
        try? LabelManager.updateLabelOrder(labels: reorderedLabels, context: modelContext)
    }
}

#Preview {
    NavigationStack {
        AuraLabelEditor()
    }
    .modelContainer(for: [CustomLabelConfig.self], inMemory: true)
}
