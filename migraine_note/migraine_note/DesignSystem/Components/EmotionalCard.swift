//
//  EmotionalCard.swift
//  migraine_note
//
//  Created on 2026/2/2.
//

import SwiftUI

// MARK: - 情感化卡片组件

/// 卡片样式枚举
enum CardStyle {
    case `default`      // 标准卡片
    case elevated       // 浮起卡片（重要信息）
    case gentle         // 柔和卡片（提示信息）
    case warning        // 预警卡片（MOH风险）
    case success        // 成功卡片（正向反馈）
    case liquidGlass    // Liquid Glass 玻璃材质卡片
    
    var backgroundColor: AnyShapeStyle {
        switch self {
        case .default:
            return AnyShapeStyle(Color.backgroundSecondary)
        case .elevated:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.backgroundSecondary, Color.backgroundTertiary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .gentle:
            return AnyShapeStyle(Color.warmAccent.opacity(0.08))
        case .warning:
            return AnyShapeStyle(Color.statusWarning.opacity(0.1))
        case .success:
            return AnyShapeStyle(Color.statusSuccess.opacity(0.1))
        case .liquidGlass:
            return AnyShapeStyle(Color.backgroundSecondary.opacity(0.6))
        }
    }
    
    var useMaterial: Bool {
        self == .liquidGlass
    }
    
    var strokeGradient: LinearGradient? {
        switch self {
        case .elevated, .liquidGlass:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return nil
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .default, .gentle:
            return Color.black.opacity(0.2)
        case .elevated:
            return Color.black.opacity(0.3)
        case .warning:
            return Color.statusWarning.opacity(0.2)
        case .success:
            return Color.statusSuccess.opacity(0.2)
        case .liquidGlass:
            return Color.black.opacity(0.25)
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .default, .gentle, .warning, .success:
            return 8
        case .elevated:
            return 12
        case .liquidGlass:
            return 10
        }
    }
    
    var shadowY: CGFloat {
        switch self {
        case .default, .gentle, .warning, .success:
            return 2
        case .elevated:
            return 4
        case .liquidGlass:
            return 3
        }
    }
}

/// 温暖的卡片系统 - 替换原有的InfoCard，增加情感化设计
struct EmotionalCard<Content: View>: View {
    let content: Content
    var style: CardStyle
    
    init(
        style: CardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                Group {
                    if style.useMaterial {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(style.backgroundColor)
                            .background(.ultraThinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(style.backgroundColor)
                    }
                }
            )
            .overlay(
                Group {
                    if let gradient = style.strokeGradient {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(gradient, lineWidth: 1)
                    }
                }
            )
            .cornerRadius(16)
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowY
            )
    }
}

// MARK: - 鼓励性文案组件

/// 鼓励性文案组件 - 用于显示正向反馈和激励信息
struct EncouragingText: View {
    let type: EncourageType
    
    enum EncourageType {
        case streak(days: Int)
        case firstRecord
        case weekSuccess
        case improvement
        case custom(text: String, icon: String)
        
        var text: String {
            switch self {
            case .streak(let days):
                if days >= 30 {
                    return String(localized: "encourage.streak.30days")
                } else if days >= 7 {
                    return String(localized: "encourage.streak.7days")
                } else if days > 0 {
                    return String(localized: "encourage.continue")
                } else {
                    return String(localized: "encourage.first.step")
                }
            case .firstRecord:
                return String(localized: "encourage.first.step")
            case .weekSuccess:
                return String(localized: "encourage.week.success")
            case .improvement:
                return String(localized: "encourage.improvement")
            case .custom(let text, _):
                return text
            }
        }
        
        var icon: String {
            switch self {
            case .streak:
                return "star.fill"
            case .firstRecord:
                return "leaf.fill"
            case .weekSuccess:
                return "checkmark.circle.fill"
            case .improvement:
                return "chart.line.uptrend.xyaxis"
            case .custom(_, let icon):
                return icon
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.warmAccent)
            
            Text(type.text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
            
            Spacer()
        }
        .padding(12)
        .background(Color.warmAccent.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 动画数字组件

/// 数字滚动动画组件 - 用于数据更新时的动画效果
struct AnimatedNumber: View {
    let value: Int
    let format: String
    @State private var displayValue: Double = 0
    
    init(value: Int, format: String = "%d") {
        self.value = value
        self.format = format
    }
    
    var body: some View {
        Text(String(format: format, Int(displayValue)))
            .contentTransition(.numericText(value: displayValue))
            .onAppear {
                withAnimation(EmotionalAnimation.dataRoll) {
                    displayValue = Double(value)
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(EmotionalAnimation.dataRoll) {
                    displayValue = Double(newValue)
                }
            }
    }
}

// MARK: - 可交互卡片

/// 可交互卡片 - 支持点击，带微妙缩放动画
struct InteractiveCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    var style: CardStyle = .default
    
    @GestureState private var isPressed = false
    
    init(
        style: CardStyle = .default,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        EmotionalCard(style: style) {
            content
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppAnimation.fast, value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
                .onEnded { _ in
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    action()
                }
        )
    }
}

// MARK: - 进度卡片

/// 进度卡片 - 带进度条的卡片
struct ProgressCard: View {
    let title: String
    let progress: Double
    let icon: String
    var style: CardStyle = .elevated
    var accentColor: Color = .accentPrimary
    
    var body: some View {
        EmotionalCard(style: style) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.backgroundTertiary)
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    .frame(width: geometry.size.width * progress, height: 8)
                            )
                            .animation(EmotionalAnimation.fluid, value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
    }
}

// MARK: - 预览

#Preview("Emotional Cards") {
    ScrollView {
        VStack(spacing: 16) {
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("标准卡片")
                        .font(.headline)
                    Text("这是一个标准样式的卡片")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            EmotionalCard(style: .elevated) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("浮起卡片")
                        .font(.headline)
                    Text("用于重要信息，带渐变边框")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            EmotionalCard(style: .liquidGlass) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Liquid Glass 卡片")
                        .font(.headline)
                    Text("iOS 26 风格的玻璃材质效果")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            EmotionalCard(style: .gentle) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("柔和卡片")
                        .font(.headline)
                    Text("用于提示信息")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            EmotionalCard(style: .warning) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("预警卡片")
                        .font(.headline)
                    Text("用于MOH风险等警告")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            EmotionalCard(style: .success) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("成功卡片")
                        .font(.headline)
                    Text("用于正向反馈")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            InteractiveCard(style: .liquidGlass, action: {
                print("卡片被点击")
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("可交互卡片")
                        .font(.headline)
                    Text("点击我试试，带微妙缩放动画")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            ProgressCard(
                title: "本月记录完成度",
                progress: 0.65,
                icon: "chart.line.uptrend.xyaxis",
                style: .elevated,
                accentColor: .accentPrimary
            )
            
            ProgressCard(
                title: "健康目标",
                progress: 0.85,
                icon: "heart.fill",
                style: .success,
                accentColor: .statusSuccess
            )
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}

#Preview("Encouraging Text") {
    VStack(spacing: 16) {
        EncouragingText(type: .streak(days: 7))
        EncouragingText(type: .firstRecord)
        EncouragingText(type: .weekSuccess)
        EncouragingText(type: .improvement)
        EncouragingText(type: .custom(text: "今天是美好的一天", icon: "sun.max.fill"))
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("Animated Number") {
    VStack(spacing: 20) {
        AnimatedNumber(value: 42)
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(Color.accentPrimary)
        
        AnimatedNumber(value: 7, format: "%d 天")
            .font(.title)
            .foregroundStyle(Color.textPrimary)
    }
    .padding()
    .background(Color.backgroundPrimary)
}
