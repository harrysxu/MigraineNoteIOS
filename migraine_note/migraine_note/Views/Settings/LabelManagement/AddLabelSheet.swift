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
                    
                    Text("添加自定义\(categoryDisplayName)")
                        .font(.headline)
                    
                    Text("输入标签名称(\(minLabelLength)-\(maxLabelLength)个字符)，方便下次快速选择")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.lg)
                
                // 输入框
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    TextField("标签名称", text: $labelName)
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
            .navigationTitle("添加自定义标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
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
                return sub == SymptomSubcategory.western.rawValue ? "西医症状" : "中医症状"
            }
            return "症状"
        case .trigger:
            return "诱因"
        case .painQuality:
            return "疼痛性质"
        case .intervention:
            return "非药物干预"
        case .aura:
            return "先兆"
        }
    }
    
    private func addLabel() {
        let trimmedName = labelName.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "标签名称不能为空"
            return
        }
        
        guard trimmedName.count >= minLabelLength else {
            errorMessage = "标签名称至少需要\(minLabelLength)个字符"
            return
        }
        
        guard trimmedName.count <= maxLabelLength else {
            errorMessage = "标签名称不能超过\(maxLabelLength)个字符"
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
                    errorMessage = "该标签已存在"
                case .nameTooLong:
                    errorMessage = "标签名称过长，最多\(maxLabelLength)个字符"
                case .invalidName:
                    errorMessage = "标签名称无效"
                case .cannotDeleteDefault, .cannotEditDefault:
                    errorMessage = "操作失败"
                }
            } else {
                errorMessage = "添加失败，请重试"
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
