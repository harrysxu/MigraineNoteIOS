//
//  AppToastManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/6.
//

import SwiftUI

/// 全局 Toast 管理器 - 用于在任何 View 中显示用户反馈
@Observable
class AppToastManager {
    static let shared = AppToastManager()
    
    var isShowing = false
    var message = ""
    var type: ToastView.ToastType = .info
    
    private init() {}
    
    /// 显示成功提示
    func showSuccess(_ message: String) {
        show(message: message, type: .success)
    }
    
    /// 显示错误提示
    func showError(_ message: String) {
        show(message: message, type: .error)
    }
    
    /// 显示信息提示
    func showInfo(_ message: String) {
        show(message: message, type: .info)
    }
    
    /// 显示警告提示
    func showWarning(_ message: String) {
        show(message: message, type: .warning)
    }
    
    /// 显示 Toast
    private func show(message: String, type: ToastView.ToastType) {
        Task { @MainActor in
            // 如果已经在显示，先隐藏
            if isShowing {
                withAnimation {
                    isShowing = false
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            self.message = message
            self.type = type
            withAnimation(.spring(response: 0.3)) {
                isShowing = true
            }
        }
    }
}

// MARK: - View Extension for Global Toast

extension View {
    /// 在视图上添加全局 Toast 支持
    func withGlobalToast() -> some View {
        modifier(GlobalToastModifier())
    }
}

struct GlobalToastModifier: ViewModifier {
    @State private var toastManager = AppToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .toast(
                message: toastManager.message,
                type: toastManager.type,
                isShowing: Binding(
                    get: { toastManager.isShowing },
                    set: { toastManager.isShowing = $0 }
                )
            )
    }
}
