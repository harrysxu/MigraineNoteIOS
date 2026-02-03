//
//  ToastView.swift
//  migraine_note
//
//  Medical Minimalism Design System
//  Toast提示组件
//

import SwiftUI

/// Toast消息类型
enum ToastType {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .success
        case .error: return .danger
        case .info: return .info
        case .warning: return .warning
        }
    }
}

/// Toast配置
struct ToastConfig {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    init(message: String, type: ToastType = .info, duration: TimeInterval = 2.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

/// Toast视图
struct ToastView: View {
    let config: ToastConfig
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: config.type.icon)
                .font(.system(size: 20))
                .foregroundColor(config.type.color)
            
            Text(config.message)
                .font(.body)
                .foregroundColor(.labelPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, Spacing.pageHorizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
        }
    }
}

/// Toast修饰器
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let config: ToastConfig
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isPresented {
                VStack {
                    ToastView(config: config, isPresented: $isPresented)
                        .padding(.top, 8)
                    Spacer()
                }
                .zIndex(999)
            }
        }
    }
}

extension View {
    /// 显示Toast提示
    func toast(isPresented: Binding<Bool>, config: ToastConfig) -> some View {
        modifier(ToastModifier(isPresented: isPresented, config: config))
    }
}

/// Toast管理器
@Observable
class ToastManager {
    var isPresented: Bool = false
    var config: ToastConfig?
    
    func show(message: String, type: ToastType = .info, duration: TimeInterval = 2.0) {
        config = ToastConfig(message: message, type: type, duration: duration)
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = true
        }
    }
    
    func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}
