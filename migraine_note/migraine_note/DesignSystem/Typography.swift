//
//  Typography.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

extension Font {
    // MARK: - 标题层级
    
    /// 页面主标题 - 34pt Bold
    static let displayLarge = Font.largeTitle.bold()
    
    /// 卡片标题 - 28pt Bold
    static let displayMedium = Font.title.bold()
    
    /// 次级标题 - 22pt Bold
    static let displaySmall = Font.title2.bold()
    
    /// 组标题 - 20pt Semibold
    static let headlineLarge = Font.title3.weight(.semibold)
    
    /// 列表标题 - 17pt Semibold
    static let headlineMedium = Font.headline
    
    // MARK: - 正文层级
    
    /// 主要内容 - 17pt Regular
    static let bodyLarge = Font.body
    
    /// 辅助说明 - 16pt Regular
    static let bodyMedium = Font.callout
    
    /// 列表项 - 15pt Regular
    static let bodySmall = Font.subheadline
    
    // MARK: - 标注层级
    
    /// 注释 - 13pt Regular
    static let labelLarge = Font.footnote
    
    /// 图表标签 - 12pt Regular
    static let labelMedium = Font.caption
    
    /// 时间戳 - 11pt Regular
    static let labelSmall = Font.caption2
}

/// 文本样式修饰器
struct TextStyles {
    /// 主标题样式
    struct DisplayLarge: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.displayLarge)
                .foregroundStyle(Color.labelPrimary)
        }
    }
    
    /// 卡片标题样式
    struct DisplayMedium: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.displayMedium)
                .foregroundStyle(Color.labelPrimary)
        }
    }
    
    /// 正文样式
    struct Body: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.bodyLarge)
                .foregroundStyle(Color.labelPrimary)
        }
    }
    
    /// 次要文字样式
    struct Secondary: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.bodyMedium)
                .foregroundStyle(Color.labelSecondary)
        }
    }
    
    /// 说明文字样式
    struct Tertiary: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.bodySmall)
                .foregroundStyle(Color.labelTertiary)
        }
    }
}

// MARK: - AppFont 兼容方法

/// 便捷的字体样式枚举（兼容）
enum AppFontStyle {
    case title, title2, title3
    case headline, subheadline
    case body, callout
    case caption, caption2
}

extension View {
    func displayLarge() -> some View {
        modifier(TextStyles.DisplayLarge())
    }
    
    func displayMedium() -> some View {
        modifier(TextStyles.DisplayMedium())
    }
    
    func bodyText() -> some View {
        modifier(TextStyles.Body())
    }
    
    func secondaryText() -> some View {
        modifier(TextStyles.Secondary())
    }
    
    func tertiaryText() -> some View {
        modifier(TextStyles.Tertiary())
    }
    
    /// 便捷的字体设置方法（兼容）
    func appFont(_ style: AppFontStyle) -> some View {
        switch style {
        case .title:
            return self.font(.title)
        case .title2:
            return self.font(.title2)
        case .title3:
            return self.font(.title3)
        case .headline:
            return self.font(.headline)
        case .subheadline:
            return self.font(.subheadline)
        case .body:
            return self.font(.body)
        case .callout:
            return self.font(.callout)
        case .caption:
            return self.font(.caption)
        case .caption2:
            return self.font(.caption2)
        }
    }
}
