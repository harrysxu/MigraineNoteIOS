//
//  Colors.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

// MARK: - AppColors 类型别名
typealias AppColors = Color

extension Color {
    // MARK: - 主色调（温暖治愈系）
    
    /// 治愈蓝绿 - 主品牌色（更温暖、平静）
    static let accentPrimary = Color(red: 0.369, green: 0.769, blue: 0.714) // #5EC4B6
    
    /// 柔和蓝 - 辅助色（信任感）
    static let accentSecondary = Color(red: 0.290, green: 0.565, blue: 0.886) // #4A90E2
    
    // MARK: - 温暖辅助色（情感化设计）
    
    /// 温暖橙 - 用于正向反馈和鼓励
    static let warmAccent = Color(red: 0.957, green: 0.635, blue: 0.380) // #F4A261
    
    /// 柔和粉 - 用于提醒和友好信息
    static let gentlePink = Color(red: 0.910, green: 0.627, blue: 0.749) // #E8A0BF
    
    // MARK: - 背景色
    
    /// 纯黑背景（暗黑模式默认）
    static let backgroundPrimary = Color.black
    
    /// 深灰背景（卡片）
    static let backgroundSecondary = Color(white: 0.11) // #1C1C1E
    
    /// 第三级背景
    static let backgroundTertiary = Color(white: 0.17) // #2C2C2E
    
    // MARK: - 文字色
    
    /// 主要文字
    static let textPrimary = Color(white: 0.92)
    
    /// 次要文字
    static let textSecondary = Color(white: 0.64)
    
    /// 说明性文字
    static let textTertiary = Color(white: 0.48)
    
    // MARK: - 语义色
    
    /// 成功 - 低饱和度绿色
    static let statusSuccess = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
    
    /// 警告 - 低饱和度橙色
    static let statusWarning = Color(red: 1.0, green: 0.62, blue: 0.04) // #FF9F0A
    
    /// 危险 - 低饱和度红色（MOH警告）
    static let statusDanger = Color(red: 1.0, green: 0.27, blue: 0.23) // #FF453A
    
    /// 错误 - 红色（与危险色相同）
    static let statusError = Color(red: 1.0, green: 0.27, blue: 0.23) // #FF453A
    
    /// 信息 - 柔和蓝色
    static let statusInfo = Color(red: 0.04, green: 0.52, blue: 1.0) // #0A84FF
    
    // MARK: - 分割线
    
    /// 分割线颜色
    static let divider = Color(white: 0.28) // #474747
    
    // MARK: - 便捷别名
    
    /// 主要背景色
    static let background = backgroundPrimary
    
    /// 卡片表面背景色
    static let surface = backgroundSecondary
    
    /// 次级表面背景色
    static let surfaceElevated = backgroundTertiary
    
    /// 主品牌色
    static let primary = accentPrimary
    
    /// 成功色
    static let success = statusSuccess
    
    /// 警告色
    static let warning = statusWarning
    
    /// 错误/危险色
    static let error = statusError
    
    /// 信息色
    static let info = statusInfo
    
    /// 阴影颜色
    static let shadowColor = Color.black.opacity(0.3)
    
    // MARK: - 疼痛强度色阶（温暖柔和版）
    
    /// 获取疼痛强度对应的颜色 (0-10) - 降低饱和度，增加温度感
    static func painIntensityColor(for intensity: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.659, green: 0.835, blue: 0.729), // 0-2 - 薄荷绿 #A8D5BA
            Color(red: 0.957, green: 0.886, blue: 0.522), // 3-4 - 柔黄 #F4E285
            Color(red: 0.957, green: 0.722, blue: 0.376), // 5-6 - 温橙 #F4B860
            Color(red: 0.910, green: 0.604, blue: 0.506), // 7-8 - 珊瑚 #E89A81
            Color(red: 0.820, green: 0.478, blue: 0.478)  // 9-10 - 柔红 #D17A7A
        ]
        
        let index = min(max(0, intensity), 10)
        switch index {
        case 0...2:
            return colors[0] // 薄荷绿
        case 3...4:
            return colors[1] // 柔黄
        case 5...6:
            return colors[2] // 温橙
        case 7...8:
            return colors[3] // 珊瑚
        case 9...10:
            return colors[4] // 柔红
        default:
            return colors[0]
        }
    }
    
    // MARK: - 渐变色
    
    /// 主色调渐变（用于按钮、重要元素）
    static let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.369, green: 0.769, blue: 0.714), // #5EC4B6
            Color(red: 0.290, green: 0.565, blue: 0.886)  // #4A90E2
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// 温暖渐变（用于正向提示）
    static let warmGradient = LinearGradient(
        colors: [
            Color(red: 0.957, green: 0.635, blue: 0.380), // #F4A261
            Color(red: 0.957, green: 0.722, blue: 0.376)  // #F4B860
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// 疼痛强度分类颜色
    static func painCategoryColor(for intensity: Int) -> Color {
        switch intensity {
        case 0...3:
            return .statusSuccess // 轻度
        case 4...6:
            return .statusWarning // 中度
        case 7...10:
            return .statusDanger // 重度
        default:
            return .textSecondary
        }
    }
}

// MARK: - PainIntensity 辅助结构

/// 疼痛强度辅助结构
struct PainIntensity {
    let value: Int
    
    var color: Color {
        Color.painIntensityColor(for: value)
    }
    
    var description: String {
        switch value {
        case 0:
            return "无痛"
        case 1...3:
            return "轻度疼痛"
        case 4...6:
            return "中度疼痛"
        case 7...9:
            return "重度疼痛"
        case 10:
            return "剧烈疼痛"
        default:
            return ""
        }
    }
    
    static func from(_ value: Int) -> PainIntensity {
        PainIntensity(value: value)
    }
}
