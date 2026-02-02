//
//  EmotionalCard.swift
//  migraine_note
//
//  Created on 2026/2/2.
//

import SwiftUI

// MARK: - 情感化卡片组件

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
    
    enum CardStyle {
        case `default`      // 标准卡片
        case elevated       // 浮起卡片（重要信息）
        case gentle         // 柔和卡片（提示信息）
        case warning        // 预警卡片（MOH风险）
        case success        // 成功卡片（正向反馈）
        
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
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .default, .gentle, .warning, .success:
                return 8
            case .elevated:
                return 12
            }
        }
        
        var shadowY: CGFloat {
            switch self {
            case .default, .gentle, .warning, .success:
                return 2
            case .elevated:
                return 4
            }
        }
    }
    
    var body: some View {
        content
            .padding(20)
            .background(style.backgroundColor)
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
                    return "太棒了！坚持一个月无头痛 🎉"
                } else if days >= 7 {
                    return "很好！已经一周没有头痛了 ✨"
                } else if days > 0 {
                    return "继续保持，你做得很好 💪"
                } else {
                    return "开始记录是改善的第一步 🌱"
                }
            case .firstRecord:
                return "开始记录是改善的第一步 🌱"
            case .weekSuccess:
                return "这周表现不错，值得鼓励 ⭐️"
            case .improvement:
                return "相比上月，发作次数减少了 📈"
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
                    Text("用于重要信息")
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
