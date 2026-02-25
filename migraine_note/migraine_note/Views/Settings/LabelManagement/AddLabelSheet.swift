//
//  AddLabelSheet.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/4.
//

import SwiftUI
import SwiftData

/// 通用添加标签表单
struct AddLabelSheet: View {
    let category: LabelCategory
    let subcategory: String?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var labelName = ""
    @State private var errorMessage: String?
    
    private let maxLabelLength = 10
    private let minLabelLength = 1
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // 说明文字
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "tag.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.accentPrimary)
                    
                    Text(String(format: String(localized: "editor.addLabel.addTitleFormat"), categoryDisplayName))
                        .font(.headline)
                    
                    Text(String(format: String(localized: "editor.addLabel.hintFormat"), minLabelLength, maxLabelLength))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.lg)
                
                // 输入框
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    TextField(String(localized: "editor.addLabel.namePlaceholder"), text: $labelName)
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
            .navigationTitle(String(localized: "editor.addLabel.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
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
                return sub == SymptomSubcategory.western.rawValue ? String(localized: "label.symptomSubcategory.western") : String(localized: "label.symptomSubcategory.tcm")
            }
            return String(localized: "label.category.symptom")
        case .trigger:
            return String(localized: "label.category.trigger")
        case .painQuality:
            return String(localized: "label.category.painQuality")
        case .intervention:
            return String(localized: "label.category.intervention")
        case .aura:
            return String(localized: "label.category.auraShort")
        }
    }
    
    private func addLabel() {
        let trimmedName = labelName.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = String(localized: "validation.label.empty")
            return
        }
        
        guard trimmedName.count >= minLabelLength else {
            errorMessage = String(format: String(localized: "validation.label.minLengthFormat"), minLabelLength)
            return
        }
        
        guard trimmedName.count <= maxLabelLength else {
            errorMessage = String(format: String(localized: "validation.label.maxLengthFormat"), maxLabelLength)
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
            
            dismiss()
        } catch {
            if let labelError = error as? LabelError {
                switch labelError {
                case .duplicateName:
                    errorMessage = String(localized: "validation.label.duplicateName")
                case .nameTooLong:
                    errorMessage = String(format: String(localized: "validation.label.tooLongFormat"), maxLabelLength)
                case .invalidName:
                    errorMessage = String(localized: "validation.label.invalid")
                case .cannotDeleteDefault, .cannotEditDefault:
                    errorMessage = String(localized: "validation.label.operationFailed")
                }
            } else {
                errorMessage = String(localized: "validation.label.addFailed")
            }
            
            // 错误触觉反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

#Preview {
    AddLabelSheet(
        category: .painQuality,
        subcategory: nil
    )
    .modelContainer(for: [CustomLabelConfig.self], inMemory: true)
}
