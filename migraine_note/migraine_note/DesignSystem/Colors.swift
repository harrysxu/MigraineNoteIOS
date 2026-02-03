//
//  Colors.swift
//  migraine_note
//
//  Medical Minimalism Design System
//  使用100% iOS系统颜色，支持深色模式自适应
//

import SwiftUI

extension Color {
    // MARK: - 主色调
    
    /// 主色 - iOS系统蓝 (#007AFF)
    static let primary = Color(uiColor: .systemBlue)
    
    /// 主色浅色版 - 10%透明度
    static let primaryLight = Color.primary.opacity(0.1)
    
    // MARK: - 背景色
    
    /// 主背景色 - 白色(浅色) / 黑色(深色)
    static let backgroundPrimary = Color(uiColor: .systemBackground)
    
    /// 次级背景色 - #F2F2F7(浅色) / #1C1C1E(深色)
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
    
    /// 第三级背景色 - #FFFFFF(浅色) / #2C2C2E(深色)
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
    
    // MARK: - 文字色
    
    /// 主要文字 - 黑色(浅色) / 白色(深色)
    static let labelPrimary = Color(uiColor: .label)
    
    /// 次要文字 - #3C3C43 99%(浅色) / #EBEBF5 60%(深色)
    static let labelSecondary = Color(uiColor: .secondaryLabel)
    
    /// 说明性文字 - #3C3C43 48%(浅色) / #EBEBF5 30%(深色)
    static let labelTertiary = Color(uiColor: .tertiaryLabel)
    
    // MARK: - 语义色
    
    /// 成功 - 系统绿色
    static let success = Color(uiColor: .systemGreen)
    
    /// 警告 - 系统橙色
    static let warning = Color(uiColor: .systemOrange)
    
    /// 危险 - 系统红色
    static let danger = Color(uiColor: .systemRed)
    
    /// 信息 - 系统蓝色
    static let info = Color.primary
    
    // MARK: - 状态颜色别名（向后兼容）
    
    /// 成功状态（别名）
    static let statusSuccess = Color.success
    
    /// 警告状态（别名）
    static let statusWarning = Color.warning
    
    /// 错误状态（别名）
    static let statusError = Color.danger
    
    /// 信息状态（别名）
    static let statusInfo = Color.info
    
    /// 危险状态（别名）
    static let statusDanger = Color.danger
    
    /// 主要强调色
    static let accentPrimary = Color.primary
    
    /// 次要强调色
    static let accentSecondary = Color(uiColor: .systemTeal)
    
    // MARK: - 分隔线
    
    /// 分隔线颜色
    static let separator = Color(uiColor: .separator)
    
    // MARK: - 疼痛强度色阶
    
    /// 疼痛强度颜色 (0-10)，使用单色透明度渐变
    static func painIntensityColor(for intensity: Int) -> Color {
        let normalizedIntensity = min(max(0, intensity), 10)
        let opacity = 0.1 + (Double(normalizedIntensity) / 10.0 * 0.9)
        return Color.primary.opacity(opacity)
    }
    
    /// 疼痛分类颜色（轻度/中度/重度）
    static func painCategoryColor(for intensity: Int) -> Color {
        switch intensity {
        case 0...3: return .success
        case 4...6: return .warning
        case 7...10: return .danger
        default: return .labelSecondary
        }
    }
    
    /// 疼痛强度描述文字
    static func painIntensityDescription(for intensity: Int) -> String {
        switch intensity {
        case 0: return "无痛"
        case 1...3: return "轻度疼痛"
        case 4...6: return "中度疼痛"
        case 7...9: return "重度疼痛"
        case 10: return "剧烈疼痛"
        default: return ""
        }
    }
}
