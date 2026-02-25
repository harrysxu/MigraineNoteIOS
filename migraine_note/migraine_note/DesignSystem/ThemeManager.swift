//
//  ThemeManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/3.
//

import SwiftUI

// MARK: - 主题模式枚举

/// 应用主题模式
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var localizedName: String {
        String(localized: String.LocalizationValue("theme.\(rawValue)"))
    }
    
    /// 对应的 ColorScheme
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil // 跟随系统
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    /// 描述
    var description: String {
        String(localized: String.LocalizationValue("theme.description.\(rawValue)"))
    }
}

// MARK: - 主题管理器

/// 主题管理器 - 使用 @Observable 宏（iOS 17+）
@Observable
class ThemeManager {
    /// 当前主题
    var currentTheme: AppTheme
    
    init() {
        // 从 UserDefaults 加载主题设置
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            // 默认跟随系统
            self.currentTheme = .system
        }
    }
    
    /// 切换主题并持久化
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
    }
}

// MARK: - View Extension

extension View {
    /// 应用主题设置
    func applyAppTheme(_ theme: AppTheme) -> some View {
        self.preferredColorScheme(theme.colorScheme)
    }
}
