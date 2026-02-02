//
//  MedicationPresetEditor.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 药物预设编辑器
struct MedicationPresetEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CustomLabelConfig> { $0.category == "medication" })
    private var allMedicationLabels: [CustomLabelConfig]
    
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
                            Text("药物预设管理")
                                .font(.headline)
                        }
                        Text("管理常用药物预设，方便快速添加药物。默认药物可以隐藏但不能删除。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // 各个药物分类
                ForEach(MedicationCategory.allCases, id: \.self) { category in
                    medicationCategorySection(category: category)
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
            AddMedicationPresetSheet()
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 默认展开所有分类
            expandedCategories = Set(MedicationCategory.allCases.map { $0.rawValue })
        }
    }
    
    @ViewBuilder
    private func medicationCategorySection(category: MedicationCategory) -> some View {
        let categoryLabels = allMedicationLabels
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
                    Image(systemName: "pills.fill")
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
                        MedicationLabelRow(label: label) { action in
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

// MARK: - 药物标签行（带剂量信息）

struct MedicationLabelRow: View {
    let label: CustomLabelConfig
    let onAction: (LabelAction) -> Void
    
    @State private var showRenameAlert = false
    @State private var newName = ""
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            // 显示/隐藏图标
            Button {
                onAction(.toggleVisibility)
            } label: {
                Image(systemName: label.isHidden ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(label.isHidden ? .gray : AppColors.primary)
                    .frame(width: 24)
            }
            
            // 标签名称和剂量
            VStack(alignment: .leading, spacing: 2) {
                Text(label.displayName)
                    .font(.body)
                    .foregroundColor(label.isHidden ? .secondary : AppColors.textPrimary)
                
                if let dosageInfo = parseDosageInfo(from: label.metadata) {
                    Text("\(dosageInfo.dosage, specifier: "%.1f") \(dosageInfo.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 标识
            if label.isDefault {
                Text("默认")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            } else {
                Text("自定义")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.primary)
                    .cornerRadius(4)
            }
            
            // 操作按钮
            if !label.isDefault {
                Menu {
                    Button {
                        newName = label.displayName
                        showRenameAlert = true
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        onAction(.delete)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.cornerRadiusSmall)
        .opacity(label.isHidden ? 0.6 : 1.0)
        .alert("重命名标签", isPresented: $showRenameAlert) {
            TextField("新名称", text: $newName)
            Button("取消", role: .cancel) {}
            Button("确定") {
                if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                    onAction(.rename(newName: newName))
                }
            }
        } message: {
            Text("请输入新的标签名称")
        }
    }
    
    private func parseDosageInfo(from metadata: String?) -> (dosage: Double, unit: String)? {
        guard let metadata = metadata,
              let data = metadata.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data),
              let dosageStr = dict["dosage"],
              let dosage = Double(dosageStr),
              let unit = dict["unit"] else {
            return nil
        }
        return (dosage, unit)
    }
}

// MARK: - 添加药物预设表单

struct AddMedicationPresetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var medicationName = ""
    @State private var selectedCategory: MedicationCategory = .nsaid
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("药物信息") {
                    TextField("药物名称", text: $medicationName)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(MedicationCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section {
                    Text("添加常用药物到预设列表，方便在添加药物时快速选择。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加药物预设")
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
                    .disabled(medicationName.trimmingCharacters(in: .whitespaces).isEmpty)
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
        let trimmedName = medicationName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let categoryRaw = selectedCategory.rawValue
        
        // 检查是否已存在同名标签
        let descriptor = FetchDescriptor<CustomLabelConfig>(
            predicate: #Predicate<CustomLabelConfig> { label in
                label.category == "medication" && 
                label.displayName == trimmedName &&
                label.subcategory == categoryRaw
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            errorMessage = "标签名称已存在"
            showError = true
            return
        }
        
        // 创建新标签
        let newLabel = CustomLabelConfig(
            category: "medication",
            labelKey: trimmedName,
            displayName: trimmedName,
            isDefault: false,
            subcategory: categoryRaw,
            sortOrder: 0
        )
        
        modelContext.insert(newLabel)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    MedicationPresetEditor()
        .modelContainer(for: [CustomLabelConfig.self], inMemory: true)
}
