//
//  Spacing.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

/// 基于8点网格系统的间距定义
enum Spacing {
    /// 极小间距 - 4pt
    static let xxs: CGFloat = 4
    
    /// 小间距 - 8pt
    static let xs: CGFloat = 8
    
    /// 较小间距 - 12pt
    static let sm: CGFloat = 12
    
    /// 标准间距 - 16pt
    static let md: CGFloat = 16
    
    /// 大间距 - 24pt
    static let lg: CGFloat = 24
    
    /// 更大间距 - 32pt
    static let xl: CGFloat = 32
    
    /// 巨大间距 - 48pt
    static let xxl: CGFloat = 48
}

/// AppSpacing 类型别名（向后兼容）
typealias AppSpacing = Spacing

extension Spacing {
    /// 兼容旧代码的别名
    static let small = xs
    static let medium = md
    static let large = lg
    static let extraLarge = xl
    
    /// 圆角半径别名
    static let cornerRadiusSmall: CGFloat = CornerRadius.sm
    static let cornerRadiusMedium: CGFloat = CornerRadius.md
    static let cornerRadiusDefault: CGFloat = CornerRadius.md
    static let cornerRadiusLarge: CGFloat = CornerRadius.lg
    
    /// 阴影半径别名
    static let shadowRadiusSmall: CGFloat = Shadow.cardRadius
    static let shadowRadiusMedium: CGFloat = Shadow.floatingRadius
}

/// 圆角定义
enum CornerRadius {
    /// 小组件 - 8pt
    static let sm: CGFloat = 8
    
    /// 卡片 - 12pt
    static let md: CGFloat = 12
    
    /// 大卡片 - 16pt
    static let lg: CGFloat = 16
    
    /// 主按钮 - 24pt
    static let xl: CGFloat = 24
    
    /// 圆形 - 999pt
    static let full: CGFloat = 999
}

/// 阴影定义
enum Shadow {
    /// 卡片阴影颜色
    static let card = Color.black.opacity(0.2)
    
    /// 卡片阴影偏移
    static let cardOffset: CGSize = CGSize(width: 0, height: 2)
    
    /// 卡片阴影半径
    static let cardRadius: CGFloat = 8
    
    /// 浮动阴影偏移
    static let floatingOffset: CGSize = CGSize(width: 0, height: 4)
    
    /// 浮动阴影半径
    static let floatingRadius: CGFloat = 12
}
