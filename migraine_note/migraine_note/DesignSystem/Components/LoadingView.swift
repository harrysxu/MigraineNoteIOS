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
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
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
        VStack(spacing: AppSpacing.large) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary.opacity(0.6))
            
            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.large)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

/// 错误状态视图
struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.large)
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
        .background(AppColors.background)
    }
}

/// Toast提示
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    enum ToastType {
        case success
        case error
        case info
        case warning
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .info:
                return .blue
            case .warning:
                return .orange
            }
        }
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(AppSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding(.horizontal, AppSpacing.medium)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            // 自动消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Toast修饰器

extension View {
    /// 显示Toast提示
    func toast(
        message: String,
        type: ToastView.ToastType,
        isShowing: Binding<Bool>
    ) -> some View {
        ZStack(alignment: .top) {
            self
            
            if isShowing.wrappedValue {
                ToastView(message: message, type: type, isShowing: isShowing)
                    .padding(.top, 50)
                    .zIndex(1)
            }
        }
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
        .toast(message: "保存成功", type: .success, isShowing: $showing)
}
