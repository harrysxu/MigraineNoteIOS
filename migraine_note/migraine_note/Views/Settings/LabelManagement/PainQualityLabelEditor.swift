//
//  PainQualityLabelEditor.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/4.
//

import SwiftUI
import SwiftData

/// 疼痛性质标签编辑器
struct PainQualityLabelEditor: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "painQuality"
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
                    Text("疼痛性质")
                    Spacer()
                    Text("\(labels.count) 个")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            } footer: {
                Text("长按拖动可调整顺序，默认标签只能隐藏不能删除")
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
                        Text("添加自定义疼痛性质")
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddLabelSheet(
                category: .painQuality,
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
        PainQualityLabelEditor()
    }
    .modelContainer(for: [CustomLabelConfig.self], inMemory: true)
}
