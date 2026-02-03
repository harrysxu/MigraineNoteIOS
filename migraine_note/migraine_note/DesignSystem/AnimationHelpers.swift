//
//  AnimationHelpers.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import SwiftUI

// MARK: - 动画预设

struct AppAnimation {
    /// 快速动画 (0.2s) - 使用现代弹性
    static let fast = Animation.spring(duration: 0.25, bounce: 0.15)
    
    /// 标准动画 (0.3s) - 微妙弹性
    static let standard = Animation.spring(duration: 0.3, bounce: 0.12)
    
    /// 慢速动画 (0.5s) - 柔和弹性
    static let slow = Animation.spring(duration: 0.4, bounce: 0.08)
    
    /// 弹簧动画 - 现代 iOS 风格
    static let spring = Animation.spring(duration: 0.3, bounce: 0.12)
    
    /// 柔和弹簧 - 避免眩晕感
    static let gentleSpring = Animation.spring(duration: 0.4, bounce: 0.08)
    
    /// 按钮点击反馈 - 微妙弹性
    static let buttonPress = Animation.spring(duration: 0.25, bounce: 0.15)
    
    /// 平滑过渡 - 无弹性
    static let smooth = Animation.spring(duration: 0.35, bounce: 0)
}

// MARK: - 情感化动画库

/// 情感化动画 - 动画应该"呼吸"而非"跳动"
enum EmotionalAnimation {
    /// 舒缓呼吸（用于待机状态、主按钮）
    static let breathe = Animation.spring(duration: 2.0, bounce: 0)
        .repeatForever(autoreverses: true)
    
    /// 温柔确认（用于成功操作）
    static let gentleConfirm = Animation.spring(duration: 0.4, bounce: 0.1)
    
    /// 轻柔出现（用于页面过渡）
    static let softAppear = Animation.spring(duration: 0.4, bounce: 0.05)
    
    /// 缓慢消失（用于提示）
    static let fadeAway = Animation.spring(duration: 0.5, bounce: 0)
    
    /// 数据滚动（用于数字变化）
    static let dataRoll = Animation.spring(duration: 0.8, bounce: 0)
    
    /// 流体动画（用于进度条）
    static let fluid = Animation.spring(duration: 0.8, bounce: 0.05)
}

// MARK: - 过渡效果

struct AppTransition {
    /// 淡入淡出
    static let fade = AnyTransition.opacity
    
    /// 从底部滑入
    static let slideUp = AnyTransition.move(edge: .bottom)
    
    /// 从顶部滑入
    static let slideDown = AnyTransition.move(edge: .top)
    
    /// 缩放 + 淡入
    static let scaleAndFade = AnyTransition.scale.combined(with: .opacity)
    
    /// 滑入 + 淡入
    static let slideAndFade = AnyTransition.move(edge: .bottom).combined(with: .opacity)
}

// MARK: - 视图修饰器

extension View {
    /// 按钮按压动画 - 微妙缩放 + 亮度调整
    func buttonPressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(AppAnimation.buttonPress, value: isPressed)
    }
    
    /// 卡片点击反馈 - 微妙缩放 + 亮度调整
    func cardTapAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(AppAnimation.fast, value: isPressed)
    }
    
    /// 震动反馈
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
    
    /// 条件性动画
    func conditionalAnimation<V: Equatable>(
        _ condition: Bool,
        animation: Animation,
        value: V
    ) -> some View {
        self.animation(condition ? animation : nil, value: value)
    }
    
    /// 淡入效果
    func fadeIn(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }
    
    /// 滑入效果
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(edge: edge, delay: delay))
    }
}

// MARK: - 淡入修饰器

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(AppAnimation.standard.delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - 滑入修饰器

struct SlideInModifier: ViewModifier {
    let edge: Edge
    let delay: Double
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: edge == .bottom ? offset : -offset)
            .opacity(offset == 0 ? 1 : 0)
            .onAppear {
                offset = 50
                withAnimation(AppAnimation.standard.delay(delay)) {
                    offset = 0
                }
            }
    }
}

// MARK: - 按压状态修饰器

struct PressableModifier: ViewModifier {
    @GestureState private var isPressed = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .onEnded { _ in
                        action()
                    }
            )
    }
}

extension View {
    /// 可按压修饰器
    func pressable(action: @escaping () -> Void) -> some View {
        self.modifier(PressableModifier(action: action))
    }
}

// MARK: - 触觉反馈扩展

extension View {
    /// 轻柔触觉反馈
    func gentleHaptic() -> some View {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        return self
    }
    
    /// 成功触觉反馈
    func successHaptic() -> some View {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        return self
    }
    
    /// 警告触觉反馈
    func warningHaptic() -> some View {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
        return self
    }
    
    /// 错误触觉反馈
    func errorHaptic() -> some View {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
        return self
    }
}

// MARK: - 现代按钮样式

/// 现代按压样式 - 微妙缩放 + 亮度 + 触觉反馈
struct ModernPressStyle: ButtonStyle {
    var scale: CGFloat = 0.985  // 从 0.97 调整到 0.985，减小缩放幅度避免眩晕感
    var hapticFeedback: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(AppAnimation.buttonPress, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && hapticFeedback {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
    }
}

/// 温柔按压样式 - 仅透明度变化
struct GentlePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimation.fast, value: configuration.isPressed)
    }
}

/// 无效果按钮样式 - 完全禁用按钮的交互视觉效果
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
    }
}

// MARK: - 加载骨架屏

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                        ) {
                            phase = 300
                        }
                    }
            )
            .clipped()
    }
}

extension View {
    /// 骨架屏加载效果
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Liquid Glass 效果

/// Liquid Glass 修饰器 - iOS 26 风格的玻璃材质效果
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: CGFloat = 0.6
    var strokeOpacity: CGFloat = 0.3
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.backgroundSecondary.opacity(opacity))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(strokeOpacity),
                                Color.white.opacity(strokeOpacity * 0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(cornerRadius)
    }
}

extension View {
    /// 应用 Liquid Glass 效果
    func liquidGlass(
        cornerRadius: CGFloat = 16,
        opacity: CGFloat = 0.6,
        strokeOpacity: CGFloat = 0.3
    ) -> some View {
        self.modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                opacity: opacity,
                strokeOpacity: strokeOpacity
            )
        )
    }
}

// MARK: - 辅助功能支持

extension View {
    /// 尊重"减弱动画"设置
    func respectReduceMotion<V: Equatable>(
        animation: Animation,
        value: V
    ) -> some View {
        Group {
            if UIAccessibility.isReduceMotionEnabled {
                self
            } else {
                self.animation(animation, value: value)
            }
        }
    }
    
    /// 动态字体大小支持
    func dynamicTypeSize(min: DynamicTypeSize = .xSmall, max: DynamicTypeSize = .xxxLarge) -> some View {
        self.dynamicTypeSize(min...max)
    }
}

// MARK: - Preview

#Preview("Button Press Animation") {
    @Previewable @State var isPressed = false
    
    VStack(spacing: 20) {
        Text("按钮按压效果")
            .font(.headline)
        
        Button {
            // Action
        } label: {
            Text("点击我")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(AppColors.primary)
                .cornerRadius(12)
        }
        .buttonPressAnimation(isPressed: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview("Fade In") {
    VStack(spacing: 20) {
        Text("第一行")
            .fadeIn(delay: 0)
        
        Text("第二行")
            .fadeIn(delay: 0.2)
        
        Text("第三行")
            .fadeIn(delay: 0.4)
    }
    .font(.headline)
}

#Preview("Shimmer Loading") {
    VStack(spacing: 16) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 60)
            .shimmer()
        
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 120)
            .shimmer()
    }
    .padding()
}
