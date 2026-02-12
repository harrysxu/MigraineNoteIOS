//
//  AccessibilityHelpers.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import SwiftUI

// MARK: - VoiceOver标签辅助

extension View {
    /// 为按钮添加完整的辅助功能标签
    func accessibilityButton(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// 为卡片添加辅助功能
    func accessibilityCard(
        label: String,
        hint: String? = nil,
        isSelected: Bool = false
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    /// 为输入字段添加辅助功能
    func accessibilityInput(
        label: String,
        value: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
    }
    
    /// 为统计数据添加辅助功能
    func accessibilityStat(
        label: String,
        value: String,
        unit: String? = nil
    ) -> some View {
        let fullValue = unit != nil ? "\(value) \(unit!)" : value
        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityValue(fullValue)
    }
}

// MARK: - 色盲友好设计

struct ColorBlindFriendlyModifier: ViewModifier {
    let painIntensity: Int
    
    func body(content: Content) -> some View {
        HStack(spacing: 4) {
            // 颜色指示器
            content
            
            // 附加文字/图标指示器
            intensityIcon
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var intensityIcon: some View {
        switch painIntensity {
        case 0...3:
            Image(systemName: "circle.fill")
        case 4...6:
            Image(systemName: "circle.lefthalf.filled")
        case 7...10:
            Image(systemName: "exclamationmark.circle.fill")
        default:
            EmptyView()
        }
    }
}

extension View {
    /// 使疼痛强度指示器色盲友好
    func colorBlindFriendlyPainIndicator(intensity: Int) -> some View {
        self.modifier(ColorBlindFriendlyModifier(painIntensity: intensity))
    }
}

// MARK: - 语义化颜色

extension Color {
    /// 语义化成功色（辅助功能友好）
    static var semanticSuccess: Color {
        Color(light: Color(red: 0.0, green: 0.6, blue: 0.0),
              dark: Color(red: 0.2, green: 0.8, blue: 0.2))
    }
    
    /// 语义化警告色
    static var semanticWarning: Color {
        Color(light: Color(red: 0.9, green: 0.6, blue: 0.0),
              dark: Color(red: 1.0, green: 0.7, blue: 0.2))
    }
    
    /// 语义化危险色
    static var semanticDanger: Color {
        Color(light: Color(red: 0.8, green: 0.0, blue: 0.0),
              dark: Color(red: 1.0, green: 0.2, blue: 0.2))
    }
    
    /// 语义化信息色
    static var semanticInfo: Color {
        Color(light: Color(red: 0.0, green: 0.5, blue: 0.9),
              dark: Color(red: 0.3, green: 0.7, blue: 1.0))
    }
    
    /// 根据环境创建颜色
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
            UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - 对比度增强

extension View {
    /// 为文字添加背景以增强对比度
    func contrastBackground(
        _ backgroundColor: Color = Color.black.opacity(0.7),
        padding: CGFloat = 8,
        cornerRadius: CGFloat = 4
    ) -> some View {
        self
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
    
    /// 检查对比度是否足够
    func ensureContrast() -> some View {
        self.modifier(ContrastEnhancementModifier())
    }
}

struct ContrastEnhancementModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    
    func body(content: Content) -> some View {
        content
            .brightness(colorSchemeContrast == .increased ? 0.1 : 0)
    }
}

// MARK: - 焦点管理

extension View {
    /// 自动聚焦到重要元素
    func autoFocus(when condition: Bool, delay: Double = 0.5) -> some View {
        self.modifier(AutoFocusModifier(condition: condition, delay: delay))
    }
}

struct AutoFocusModifier: ViewModifier {
    let condition: Bool
    let delay: Double
    @AccessibilityFocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .onChange(of: condition) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        isFocused = true
                    }
                }
            }
    }
}

// MARK: - 触摸目标最小尺寸

extension View {
    /// 确保触摸目标至少44x44pt（Apple HIG标准）
    func minimumTouchTarget(minSize: CGFloat = 44) -> some View {
        self.modifier(MinimumTouchTargetModifier(minSize: minSize))
    }
}

struct MinimumTouchTargetModifier: ViewModifier {
    let minSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
    }
}

// MARK: - 疼痛强度辅助功能描述

extension Int {
    /// 将疼痛强度转换为VoiceOver友好的描述
    var painIntensityDescription: String {
        switch self {
        case 0:
            return "无疼痛"
        case 1...3:
            return "轻度疼痛，\(self)分"
        case 4...6:
            return "中度疼痛，\(self)分"
        case 7...9:
            return "重度疼痛，\(self)分"
        case 10:
            return "极重度疼痛，10分"
        default:
            return "\(self)分"
        }
    }
}

// MARK: - 时长辅助功能描述

extension TimeInterval {
    /// 将时长转换为VoiceOver友好的描述
    var durationDescription: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        
        var parts: [String] = []
        if hours > 0 {
            parts.append("\(hours)小时")
        }
        if minutes > 0 {
            parts.append("\(minutes)分钟")
        }
        
        return parts.isEmpty ? "少于1分钟" : parts.joined(separator: "")
    }
}

// MARK: - 辅助功能偏好检测

struct AccessibilityPreferences {
    /// 是否启用了"减弱动画"
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// 是否启用了"降低透明度"
    static var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }
    
    /// 是否启用了"增强对比度"
    static var isInvertColorsEnabled: Bool {
        UIAccessibility.isInvertColorsEnabled
    }
    
    /// 是否启用了VoiceOver
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// 是否启用了粗体文本
    static var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }
}

// MARK: - Preview

#Preview("Accessibility Button") {
    VStack(spacing: 20) {
        Button {
            // Action
        } label: {
            Label("开始记录", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.primary)
                .cornerRadius(12)
        }
        .accessibilityButton(
            label: "开始记录按钮",
            hint: "双击以开始新的头痛记录"
        )
        .minimumTouchTarget()
    }
    .padding()
}

#Preview("Color Blind Friendly") {
    VStack(spacing: 16) {
        ForEach([2, 5, 8], id: \.self) { intensity in
            HStack {
                Circle()
                    .fill(AppColors.painCategoryColor(for: intensity))
                    .frame(width: 20, height: 20)
                    .colorBlindFriendlyPainIndicator(intensity: intensity)
                
                Text("\(intensity)分")
            }
        }
    }
    .padding()
}

#Preview("Semantic Colors") {
    VStack(spacing: 16) {
        HStack {
            Text("成功")
                .foregroundStyle(Color.semanticSuccess)
            Text("警告")
                .foregroundStyle(Color.semanticWarning)
            Text("危险")
                .foregroundStyle(Color.semanticDanger)
            Text("信息")
                .foregroundStyle(Color.semanticInfo)
        }
        .font(.headline)
        
        // 暗色模式
        HStack {
            Text("成功")
                .foregroundStyle(Color.semanticSuccess)
            Text("警告")
                .foregroundStyle(Color.semanticWarning)
            Text("危险")
                .foregroundStyle(Color.semanticDanger)
            Text("信息")
                .foregroundStyle(Color.semanticInfo)
        }
        .font(.headline)
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
    }
    .padding()
}
