//
//  AnimationHelpers.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import SwiftUI

// MARK: - 动画预设

struct AppAnimation {
    /// 快速动画 (0.2s)
    static let fast = Animation.easeInOut(duration: 0.2)
    
    /// 标准动画 (0.3s)
    static let standard = Animation.easeInOut(duration: 0.3)
    
    /// 慢速动画 (0.5s)
    static let slow = Animation.easeInOut(duration: 0.5)
    
    /// 弹簧动画
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// 柔和弹簧
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// 按钮点击反馈
    static let buttonPress = Animation.easeInOut(duration: 0.1)
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
    /// 按钮按压动画
    func buttonPressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AppAnimation.buttonPress, value: isPressed)
    }
    
    /// 卡片点击反馈
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
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AppAnimation.buttonPress, value: isPressed)
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
