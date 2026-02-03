//
//  SymptomLabelEditor.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 症状标签编辑器
struct SymptomLabelEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CustomLabelConfig> { $0.category == "symptom" })
    private var allSymptomLabels: [CustomLabelConfig]
    
    @State private var showAddSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var westernSymptoms: [CustomLabelConfig] {
        allSymptomLabels
            .filter { $0.subcategory == SymptomSubcategory.western.rawValue }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    private var tcmSymptoms: [CustomLabelConfig] {
        allSymptomLabels
            .filter { $0.subcategory == SymptomSubcategory.tcm.rawValue }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                // 说明卡片
                InfoCard {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(AppColors.primary)
                            Text("症状标签管理")
                                .font(.headline)
                        }
                        Text("默认标签可以隐藏但不能删除，自定义标签可以随时修改和删除。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // 西医症状
                labelSection(
                    title: "西医症状",
                    icon: "stethoscope",
                    labels: westernSymptoms,
                    subcategory: .western
                )
                
                // 中医症状
                labelSection(
                    title: "中医症状",
                    icon: "leaf.fill",
                    labels: tcmSymptoms,
                    subcategory: .tcm
                )
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
            AddSymptomLabelSheet()
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private func labelSection(
        title: String,
        icon: String,
        labels: [CustomLabelConfig],
        subcategory: SymptomSubcategory
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(labels.filter { !$0.isHidden }.count)/\(labels.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: AppSpacing.small) {
                ForEach(labels) { label in
                    LabelRow(label: label) { action in
                        handleLabelAction(label: label, action: action)
                    }
                }
            }
            .padding(.horizontal)
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

// MARK: - 添加症状标签表单

struct AddSymptomLabelSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var labelName = ""
    @State private var selectedSubcategory: SymptomSubcategory = .western
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 标签长度限制
    private let maxLabelLength = 10
    
    var body: some View {
        NavigationStack {
            Form {
                Section("标签信息") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("症状名称", text: $labelName)
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
                    
                    Picker("类型", selection: $selectedSubcategory) {
                        Text("西医症状").tag(SymptomSubcategory.western)
                        Text("中医症状").tag(SymptomSubcategory.tcm)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Text("添加后，该症状将出现在记录流程的症状选择界面。标签长度限制为\(maxLabelLength)个字符。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("添加症状标签")
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
                category: .symptom,
                displayName: trimmedName,
                subcategory: selectedSubcategory.rawValue,
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
    SymptomLabelEditor()
        .modelContainer(for: [CustomLabelConfig.self], inMemory: true)
}
