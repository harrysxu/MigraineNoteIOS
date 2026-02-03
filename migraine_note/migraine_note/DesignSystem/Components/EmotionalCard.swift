//
//  EmotionalCard.swift
//  migraine_note
//
//  简化版卡片组件（向后兼容）
//

import SwiftUI

/// 卡片样式
enum EmotionalCardStyle {
    case `default`
    case elevated
    case warning
    case error
    case success
    case info
    case gentle
}

/// 简化的卡片组件
struct EmotionalCard<Content: View>: View {
    let style: EmotionalCardStyle
    let content: () -> Content
    
    init(style: EmotionalCardStyle = .default, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(Spacing.md)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .default:
            return Color.backgroundSecondary
        case .elevated:
            return Color.backgroundPrimary
        case .warning:
            return Color.warning.opacity(0.1)
        case .error:
            return Color.danger.opacity(0.1)
        case .success:
            return Color.success.opacity(0.1)
        case .info:
            return Color.info.opacity(0.1)
        case .gentle:
            return Color.backgroundTertiary
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .elevated:
            return Color.black.opacity(0.1)
        default:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .elevated:
            return 8
        default:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .elevated:
            return 2
        default:
            return 0
        }
    }
}
