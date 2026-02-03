//
//  Spacing.swift
//  migraine_note
//
//  Medical Minimalism Design System
//  基于16pt Grid系统的间距定义
//

import SwiftUI

/// 基于16pt Grid系统的间距定义
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
    
    // MARK: - 页面边距
    
    /// 页面水平边距 - 20pt
    static let pageHorizontal: CGFloat = 20
    
    /// 页面顶部边距 - 16pt
    static let pageTop: CGFloat = 16
    
    /// 页面底部边距 - 32pt
    static let pageBottom: CGFloat = 32
}

/// 圆角定义
enum CornerRadius {
    /// 小组件 - 8pt
    static let sm: CGFloat = 8
    
    /// 中等元素 - 12pt
    static let md: CGFloat = 12
    
    /// 大元素 - 16pt
    static let lg: CGFloat = 16
    
    /// 主按钮 - 24pt
    static let xl: CGFloat = 24
    
    /// 圆形 - 999pt
    static let full: CGFloat = 999
}
