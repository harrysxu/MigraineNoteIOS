//
//  LoadingView.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import SwiftUI

/// 加载状态指示器
struct LoadingView: View {
    let message: String
    
    init(message: String = "加载中...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.primary))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

/// 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(Color.primary.opacity(0.6))
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

/// 错误状态视图
struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            if let retryAction = retryAction {
                PrimaryButton(
                    title: "重试",
                    action: retryAction
                )
                .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Preview

#Preview("Loading") {
    LoadingView(message: "加载中...")
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "doc.text",
        title: "暂无记录",
        message: "点击\"开始记录\"按钮创建您的第一条偏头痛记录",
        actionTitle: "开始记录",
        action: {}
    )
}

#Preview("Error State") {
    ErrorStateView(
        title: "加载失败",
        message: "无法加载数据，请检查网络连接后重试",
        retryAction: {}
    )
}

#Preview("Toast Success") {
    @Previewable @State var showing = true
    Color.gray.opacity(0.1)
        .toast(
            isPresented: $showing, 
            config: ToastConfig(message: "保存成功", type: .success)
        )
}
