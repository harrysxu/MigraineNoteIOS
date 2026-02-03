//
//  LabelRow.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI

/// 标签行组件
struct LabelRow: View {
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
            
            // 标签名称
            Text(label.displayName)
                .font(.body)
                .foregroundColor(label.isHidden ? .secondary : AppColors.textPrimary)
            
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
            
            // 操作按钮（仅限自定义标签）
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
                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty && trimmed.count <= 10 {
                    onAction(.rename(newName: trimmed))
                }
            }
        } message: {
            Text("请输入新的标签名称(最多10个字符)")
        }
    }
}

/// 标签操作类型
enum LabelAction {
    case toggleVisibility
    case delete
    case rename(newName: String)
}

#Preview {
    VStack(spacing: AppSpacing.medium) {
        // 默认标签（显示）
        LabelRow(
            label: CustomLabelConfig(
                category: "symptom",
                labelKey: "nausea",
                displayName: "恶心",
                isDefault: true,
                subcategory: "western"
            )
        ) { _ in }
        
        // 默认标签（隐藏）
        LabelRow(
            label: {
                let label = CustomLabelConfig(
                    category: "symptom",
                    labelKey: "vomiting",
                    displayName: "呕吐",
                    isDefault: true,
                    subcategory: "western"
                )
                label.isHidden = true
                return label
            }()
        ) { _ in }
        
        // 自定义标签
        LabelRow(
            label: CustomLabelConfig(
                category: "symptom",
                labelKey: "custom",
                displayName: "自定义症状",
                isDefault: false,
                subcategory: "western"
            )
        ) { _ in }
    }
    .padding()
    .background(AppColors.backgroundPrimary)
}
