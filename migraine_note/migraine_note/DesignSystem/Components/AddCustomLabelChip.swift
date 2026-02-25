//
//  AddCustomLabelChip.swift
//  migraine_note
//
//  Created on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 添加自定义标签的芯片组件
struct AddCustomLabelChip: View {
    let category: LabelCategory
    let subcategory: String?
    let onLabelAdded: (String) -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddSheet = false
    @State private var labelName = ""
    @State private var errorMessage: String?
    
    // 标签长度限制
    private let maxLabelLength = 10
    private let minLabelLength = 1
    
    var body: some View {
        Button {
            showingAddSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.caption)
                Text(String(localized: "component.custom"))
                    .font(.subheadline)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: 32)
            .background(Color.backgroundTertiary)
            .foregroundStyle(Color.accentPrimary)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.accentPrimary.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingAddSheet) {
            addLabelSheet
        }
    }
    
    private var addLabelSheet: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // 说明文字
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "tag.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.accentPrimary)
                    
                    Text(String(format: String(localized: "component.addCustomLabel"), categoryDisplayName))
                        .font(.headline)
                    
                    Text(String(format: String(localized: "component.labelInputHint"), minLabelLength, maxLabelLength))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.lg)
                
                // 输入框
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    TextField(String(localized: "component.labelNamePlaceholder"), text: $labelName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .onChange(of: labelName) { _, newValue in
                            // 限制输入长度
                            if newValue.count > maxLabelLength {
                                labelName = String(newValue.prefix(maxLabelLength))
                            }
                            errorMessage = nil
                        }
                    
                    // 字符计数提示
                    HStack {
                        if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundStyle(Color.statusError)
                        }
                        
                        Spacer()
                        
                        Text("\(labelName.count)/\(maxLabelLength)")
                            .font(.caption)
                            .foregroundStyle(
                                labelName.count >= maxLabelLength
                                    ? Color.statusWarning
                                    : Color.textSecondary
                            )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(String(localized: "component.addCustomLabelTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismissSheet()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.add")) {
                        addLabel()
                    }
                    .disabled(labelName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(300)])
    }
    
    private var categoryDisplayName: String {
        switch category {
        case .symptom:
            if let sub = subcategory {
                return sub == SymptomSubcategory.western.rawValue ? String(localized: "component.category.westernSymptom") : String(localized: "component.category.tcmSymptom")
            }
            return String(localized: "component.category.symptom")
        case .trigger:
            return String(localized: "component.category.trigger")
        case .painQuality:
            return String(localized: "component.category.painQuality")
        case .intervention:
            return String(localized: "component.category.intervention")
        case .aura:
            return String(localized: "component.category.aura")
        }
    }
    
    private func addLabel() {
        let trimmedName = labelName.trimmingCharacters(in: .whitespaces)
        
        // 验证标签名称不能为空
        guard !trimmedName.isEmpty else {
            errorMessage = String(localized: "component.labelError.empty")
            return
        }
        
        // 验证标签长度
        guard trimmedName.count >= minLabelLength else {
            errorMessage = String(format: String(localized: "component.labelError.tooShort"), minLabelLength)
            return
        }
        
        guard trimmedName.count <= maxLabelLength else {
            errorMessage = String(format: String(localized: "component.labelError.tooLong"), maxLabelLength)
            return
        }
        
        do {
            try LabelManager.addCustomLabel(
                category: category,
                displayName: trimmedName,
                subcategory: subcategory,
                context: modelContext
            )
            
            // 成功触觉反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // 回调通知父视图
            onLabelAdded(trimmedName)
            
            dismissSheet()
        } catch {
            // 处理错误
            if let labelError = error as? LabelError {
                switch labelError {
                case .duplicateName:
                    errorMessage = String(localized: "component.labelError.duplicate")
                case .nameTooLong:
                    errorMessage = String(format: String(localized: "component.labelError.tooLong"), maxLabelLength)
                case .invalidName:
                    errorMessage = String(localized: "component.labelError.invalid")
                case .cannotDeleteDefault, .cannotEditDefault:
                    errorMessage = String(localized: "component.labelError.failed")
                }
            } else {
                errorMessage = String(localized: "component.labelError.addFailed")
            }
            
            // 错误触觉反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    private func dismissSheet() {
        showingAddSheet = false
        labelName = ""
        errorMessage = nil
    }
}

// MARK: - 预览

#Preview {
    struct PreviewContainer: View {
        @State private var selectedLabels: Set<String> = []
        
        var body: some View {
            VStack {
                FlowLayout(spacing: 8) {
                    SelectableChip(label: String(localized: "symptom.nausea"), isSelected: .constant(false))
                    SelectableChip(label: String(localized: "symptom.vomit"), isSelected: .constant(true))
                    
                    AddCustomLabelChip(
                        category: .symptom,
                        subcategory: SymptomSubcategory.western.rawValue
                    ) { newLabel in
                        selectedLabels.insert(newLabel)
                    }
                }
                .padding()
                
                if !selectedLabels.isEmpty {
                    Text(String(format: String(localized: "component.label.added"), selectedLabels.joined(separator: ", ")))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .background(Color.backgroundPrimary)
            .modelContainer(for: [CustomLabelConfig.self])
        }
    }
    
    return PreviewContainer()
}
