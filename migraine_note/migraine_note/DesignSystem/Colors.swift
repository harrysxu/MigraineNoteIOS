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
    // MARK: - 主色调
    
    /// 柔和的青紫色 - 主品牌色
    static let accentPrimary = Color(red: 0.42, green: 0.62, blue: 0.85) // #6B9ED9
    
    /// 辅助色 - 用于强调和区分
    static let accentSecondary = Color(red: 0.73, green: 0.56, blue: 0.85) // #BA8FD9
    
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
    
    // MARK: - 疼痛强度色阶
    
    /// 获取疼痛强度对应的颜色 (0-10)
    static func painIntensityColor(for intensity: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.20, green: 0.78, blue: 0.35), // 0 - 绿色（无痛）
            Color(red: 0.40, green: 0.80, blue: 0.40), // 1-2 - 浅绿
            Color(red: 0.67, green: 0.87, blue: 0.47), // 3 - 黄绿
            Color(red: 1.0, green: 0.92, blue: 0.04),  // 4-5 - 黄色
            Color(red: 1.0, green: 0.78, blue: 0.04),  // 6 - 橙黄
            Color(red: 1.0, green: 0.62, blue: 0.04),  // 7 - 橙色
            Color(red: 1.0, green: 0.45, blue: 0.04),  // 8 - 深橙
            Color(red: 1.0, green: 0.27, blue: 0.23)   // 9-10 - 红色（剧痛）
        ]
        
        let index = min(max(0, intensity), 10)
        if index == 0 {
            return colors[0]
        } else if index <= 2 {
            return colors[1]
        } else if index == 3 {
            return colors[2]
        } else if index <= 5 {
            return colors[3]
        } else if index == 6 {
            return colors[4]
        } else if index == 7 {
            return colors[5]
        } else if index == 8 {
            return colors[6]
        } else {
            return colors[7]
        }
    }
    
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
