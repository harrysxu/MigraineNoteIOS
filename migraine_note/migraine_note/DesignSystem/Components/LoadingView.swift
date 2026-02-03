//
//  LoadingView.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import SwiftUI

/// 加载状态指示器 - 使用 SF Symbols 动画
struct LoadingView: View {
    let message: String
    var style: LoadingStyle = .rotating
    
    enum LoadingStyle {
        case rotating    // 旋转图标
        case pulse       // 脉冲效果
        case progress    // 系统进度条
    }
    
    init(message: String = "加载中...", style: LoadingStyle = .rotating) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: 16) {
            switch style {
            case .rotating:
                if #available(iOS 17.0, *) {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.rotate)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentPrimary))
                        .scaleEffect(1.5)
                }
                
            case .pulse:
                if #available(iOS 17.0, *) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentPrimary, Color.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentPrimary))
                        .scaleEffect(1.5)
                }
                
            case .progress:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.accentPrimary))
                    .scaleEffect(1.5)
            }
            
            Text(message)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - 骨架屏组件

/// 骨架卡片 - 用于加载状态的占位符
struct SkeletonCard: View {
    var height: CGFloat = 100
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.backgroundSecondary)
            .frame(height: height)
            .shimmer()
    }
}

/// 骨架文本行
struct SkeletonLine: View {
    var width: CGFloat = 200
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.backgroundSecondary)
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// 骨架圆形（用于头像）
struct SkeletonCircle: View {
    var size: CGFloat = 48
    
    var body: some View {
        Circle()
            .fill(Color.backgroundSecondary)
            .frame(width: size, height: size)
            .shimmer()
    }
}

/// 骨架列表项
struct SkeletonListItem: View {
    var showIcon: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            if showIcon {
                SkeletonCircle(size: 44)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonLine(width: 180, height: 16)
                SkeletonLine(width: 120, height: 12)
            }
            
            Spacer()
            
            SkeletonLine(width: 60, height: 14)
        }
        .padding()
        .background(Color.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
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

#Preview("Loading Styles") {
    VStack(spacing: 40) {
        LoadingView(message: "加载中...", style: .rotating)
        LoadingView(message: "同步数据...", style: .pulse)
        LoadingView(message: "处理中...", style: .progress)
    }
    .background(Color.backgroundPrimary)
}

#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: 16) {
            Text("骨架屏组件")
                .font(.headline)
            
            SkeletonCard(height: 120)
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonLine(width: 200, height: 20)
                SkeletonLine(width: 150, height: 16)
                SkeletonLine(width: 180, height: 16)
            }
            
            HStack(spacing: 12) {
                SkeletonCircle(size: 60)
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: 150, height: 18)
                    SkeletonLine(width: 100, height: 14)
                }
            }
            
            ForEach(0..<3) { _ in
                SkeletonListItem()
            }
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
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
