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
    
    /// iOS系统蓝 - 主品牌色（自动适配暗模式）
    static let primary = Color(uiColor: .systemBlue)  // #007AFF
    
    /// 主色调淡色版（用于背景）
    static let primaryLight = Color(uiColor: .systemBlue).opacity(0.1)
    
    // MARK: - 背景色（自动适配暗模式和亮模式）
    
    /// 主要背景色 - 白色(浅色)/黑色(深色)
    static let backgroundPrimary = Color(uiColor: .systemBackground)
    
    /// 次要背景色 - #F2F2F7(浅色) / #1C1C1E(深色)
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
    
    /// 第三级背景色 - #FFFFFF(浅色) / #2C2C2E(深色)
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
    
    // MARK: - 文字色（自动适配暗模式和亮模式）
    
    /// 主要文字 - 黑色(浅色)/白色(深色)
    static let textPrimary = Color(uiColor: .label)
    
    /// 次要文字 - #3C3C43 99%(浅色) / #EBEBF5 60%(深色)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    
    /// 第三级文字 - #3C3C43 48%(浅色) / #EBEBF5 30%(深色)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    
    // MARK: - 语义色（iOS系统色,自动适配）
    
    /// 成功色 - 绿色
    static let statusSuccess = Color(uiColor: .systemGreen)    // #34C759
    
    /// 警告色 - 橙色
    static let statusWarning = Color(uiColor: .systemOrange)   // #FF9500
    
    /// 危险色 - 红色（MOH警告）
    static let statusDanger = Color(uiColor: .systemRed)       // #FF3B30
    
    /// 错误色 - 红色
    static let statusError = Color(uiColor: .systemRed)        // #FF3B30
    
    /// 信息色 - 蓝色
    static let statusInfo = Color(uiColor: .systemBlue)        // #007AFF
    
    // MARK: - 分割线（自动适配）
    
    /// 分割线颜色 - #3C3C43 36%(浅色) / #545458 65%(深色)
    static let divider = Color(uiColor: .separator)
    
    // MARK: - 便捷别名
    
    /// 主要背景色
    static let background = backgroundPrimary
    
    /// 卡片表面背景色
    static let surface = backgroundSecondary
    
    /// 次级表面背景色
    static let surfaceElevated = backgroundTertiary
    
    /// 成功色
    static let success = statusSuccess
    
    /// 警告色
    static let warning = statusWarning
    
    /// 错误/危险色
    static let error = statusError
    
    /// 信息色
    static let info = statusInfo
    
    /// 阴影颜色（自动适配）
    static let shadowColor = Color.black.opacity(0.15)
    
    // MARK: - 温暖辅助色（情感化设计,保留用于特殊场景）
    
    /// 温暖橙 - 用于正向反馈和鼓励
    static let warmAccent = Color(red: 0.957, green: 0.635, blue: 0.380) // #F4A261
    
    /// 柔和粉 - 用于提醒和友好信息
    static let gentlePink = Color(red: 0.910, green: 0.627, blue: 0.749) // #E8A0BF
    
    /// 治愈蓝绿 - 特殊品牌色
    static let accentPrimary = Color(red: 0.369, green: 0.769, blue: 0.714) // #5EC4B6
    
    /// 柔和蓝 - 辅助色
    static let accentSecondary = Color(red: 0.290, green: 0.565, blue: 0.886) // #4A90E2
    
    // MARK: - 疼痛强度色阶（使用单色渐变,避免色盲问题,自动适配暗模式）
    
    /// 获取疼痛强度对应的颜色 (0-10) - 使用主色调的透明度渐变
    static func painIntensityColor(for intensity: Int) -> Color {
        let opacity = 0.1 + (Double(intensity) / 10.0 * 0.9)
        return Color.primary.opacity(opacity)
    }
    
    /// 疼痛强度分类颜色（语义化）
    static func painCategoryColor(for intensity: Int) -> Color {
        switch intensity {
        case 0...3:
            return .statusSuccess // 轻度 - 绿色
        case 4...6:
            return .statusWarning // 中度 - 橙色
        case 7...10:
            return .statusDanger // 重度 - 红色
        default:
            return .textSecondary
        }
    }
    
    /// 健康事件类型颜色映射
    static func healthEventColor(for eventType: HealthEventType) -> Color {
        switch eventType {
        case .medication:
            return Color.accentPrimary // 用药 - 青色（主题色）
        case .tcmTreatment:
            return Color.statusSuccess // 中医治疗 - 绿色
        case .surgery:
            return Color.statusInfo // 手术 - 蓝色
        }
    }
    
    // MARK: - 渐变色（保留用于特殊场景）
    
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
}

// MARK: - PainIntensity 辅助结构

/// 疼痛强度辅助结构
struct PainIntensity {
    let value: Int
    
    var color: Color {
        Color.painCategoryColor(for: value)
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
