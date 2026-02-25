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
                            Text(String(localized: "editor.trigger.title"))
                                .font(.headline)
                        }
                        Text(String(localized: "editor.trigger.description"))
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
        .alert(String(localized: "common.error"), isPresented: $showError) {
            Button(String(localized: "common.ok"), role: .cancel) {}
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
                    
                    Text(category.localizedName)
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
    
    // 标签长度限制
    private let maxLabelLength = 10
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "section.labelInfo")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(String(localized: "editor.trigger.namePlaceholder"), text: $labelName)
                            .onChange(of: labelName) { _, newValue in
                                // 限制输入长度
                                if newValue.count > maxLabelLength {
                                    labelName = String(newValue.prefix(maxLabelLength))
                                }
                            }
                        
                        HStack {
                            Spacer()
                            Text("\(labelName.count)/\(maxLabelLength)")
                                .font(.caption)
                                .foregroundColor(labelName.count >= maxLabelLength ? .orange : .secondary)
                        }
                    }
                    
                    Picker(String(localized: "editor.category"), selection: $selectedCategory) {
                        ForEach(TriggerCategory.allCases, id: \.self) { category in
                            Label(category.localizedName, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }
                
                Section {
                    Text(String(format: String(localized: "editor.trigger.addHint"), maxLabelLength))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(String(localized: "editor.trigger.addTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        saveLabel()
                    }
                    .disabled(labelName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert(String(localized: "common.error"), isPresented: $showError) {
                Button(String(localized: "common.ok"), role: .cancel) {}
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
