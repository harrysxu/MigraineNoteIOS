//
//  TriggerLabelEditor.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 诱因标签编辑器
struct TriggerLabelEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CustomLabelConfig> { $0.category == "trigger" })
    private var allTriggerLabels: [CustomLabelConfig]
    
    @State private var showAddSheet = false
    @State private var expandedCategories: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                // 说明卡片
                InfoCard {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(AppColors.primary)
                            Text("诱因标签管理")
                                .font(.headline)
                        }
                        Text("按分类管理诱因标签，默认标签可以隐藏但不能删除。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // 各个分类
                ForEach(TriggerCategory.allCases, id: \.self) { category in
                    triggerCategorySection(category: category)
                }
            }
            .padding(.vertical)
        }
        .background(AppColors.backgroundPrimary)
        .overlay(alignment: .bottomTrailing) {
            // 添加按钮
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.primary)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 40, height: 40)
                    )
            }
            .padding(AppSpacing.large)
        }
        .sheet(isPresented: $showAddSheet) {
            AddTriggerLabelSheet()
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 默认展开所有分类
            expandedCategories = Set(TriggerCategory.allCases.map { $0.rawValue })
        }
    }
    
    @ViewBuilder
    private func triggerCategorySection(category: TriggerCategory) -> some View {
        let categoryLabels = allTriggerLabels
            .filter { $0.subcategory == category.rawValue }
            .sorted { $0.sortOrder < $1.sortOrder }
        
        let isExpanded = expandedCategories.contains(category.rawValue)
        
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            // 分类标题（可折叠）
            Button {
                withAnimation {
                    if isExpanded {
                        expandedCategories.remove(category.rawValue)
                    } else {
                        expandedCategories.insert(category.rawValue)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: category.systemImage)
                        .foregroundStyle(AppColors.primary)
                    
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(categoryLabels.filter { !$0.isHidden }.count)/\(categoryLabels.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppSpacing.cornerRadiusSmall)
            }
            .padding(.horizontal)
            
            // 标签列表
            if isExpanded {
                LazyVStack(spacing: AppSpacing.small) {
                    ForEach(categoryLabels) { label in
                        LabelRow(label: label) { action in
                            handleLabelAction(label: label, action: action)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func handleLabelAction(label: CustomLabelConfig, action: LabelAction) {
        do {
            switch action {
            case .toggleVisibility:
                try LabelManager.toggleLabelVisibility(label: label, context: modelContext)
            case .delete:
                try LabelManager.deleteCustomLabel(label: label, context: modelContext)
            case .rename(let newName):
                try LabelManager.renameLabel(label: label, newName: newName, context: modelContext)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - 添加诱因标签表单

struct AddTriggerLabelSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var labelName = ""
    @State private var selectedCategory: TriggerCategory = .food
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("标签信息") {
                    TextField("诱因名称", text: $labelName)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(TriggerCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }
                
                Section {
                    Text("添加后，该诱因将出现在记录流程的诱因选择界面。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加诱因标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveLabel()
                    }
                    .disabled(labelName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveLabel() {
        let trimmedName = labelName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        do {
            try LabelManager.addCustomLabel(
                category: .trigger,
                displayName: trimmedName,
                subcategory: selectedCategory.rawValue,
                context: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    TriggerLabelEditor()
        .modelContainer(for: [CustomLabelConfig.self], inMemory: true)
}
