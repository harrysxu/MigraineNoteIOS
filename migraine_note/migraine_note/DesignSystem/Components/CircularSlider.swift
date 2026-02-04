//
//  CircularSlider.swift
//  migraine_note
//
//  Created on 2026/2/2.
//

import SwiftUI

// MARK: - 圆形滑块组件

/// 圆形滑块 - 用于疼痛强度评估的情感化交互组件
struct CircularSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    @Binding var isDragging: Bool
    
    @State private var angle: Double = 0
    @State private var lastValue: Int = 0
    
    let diameter: CGFloat = 280
    let lineWidth: CGFloat = 40
    
    init(
        value: Binding<Int>,
        range: ClosedRange<Int> = 0...10,
        isDragging: Binding<Bool> = .constant(false)
    ) {
        self._value = value
        self.range = range
        self._isDragging = isDragging
    }
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(
                    Color.divider.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            
            // 进度圆环（带渐变和发光效果）
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    painGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: painColor.opacity(0.5), radius: 12, x: 0, y: 0)
                .shadow(color: painColor.opacity(0.3), radius: 24, x: 0, y: 0)
                .animation(EmotionalAnimation.fluid, value: value)
            
            // 拖动手柄（带渐变和发光）
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .fill(painColor.opacity(0.3))
                        .frame(width: 16, height: 16)
                )
                .shadow(color: painColor.opacity(0.4), radius: 8, x: 0, y: 0)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .position(handlePosition)
                .gesture(dragGesture)
            
            // 中心内容
            VStack(spacing: 12) {
                // 大表情
                Text(painEmoji)
                    .font(.system(size: 80))
                    .animation(.spring(response: 0.3), value: value)
                
                // 数值
                Text("\(value)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(painColor)
                    .contentTransition(.numericText(value: Double(value)))
                    .animation(.easeOut(duration: 0.3), value: value)
                
                // 描述文字
                Text(painDescription)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: diameter, height: diameter)
        .onAppear {
            angle = angleForValue(value)
            lastValue = value
        }
    }
    
    // MARK: - 计算属性
    
    private var progress: Double {
        Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
    }
    
    private var painColor: Color {
        Color.painCategoryColor(for: value)
    }
    
    private var painGradient: AngularGradient {
        AngularGradient(
            colors: [
                Color.painCategoryColor(for: range.lowerBound),
                Color.painCategoryColor(for: (range.lowerBound + range.upperBound) / 2),
                Color.painCategoryColor(for: range.upperBound)
            ],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress)
        )
    }
    
    private var painEmoji: String {
        switch value {
        case 0:
            return "😊"
        case 1...2:
            return "🙂"
        case 3...4:
            return "😐"
        case 5...6:
            return "😟"
        case 7...8:
            return "😣"
        case 9...10:
            return "😭"
        default:
            return "😐"
        }
    }
    
    private var painDescription: String {
        switch value {
        case 0:
            return "无感觉"
        case 1...2:
            return "轻微不适"
        case 3...4:
            return "有些难受"
        case 5...6:
            return "比较痛苦"
        case 7...8:
            return "很难忍受"
        case 9...10:
            return "极度痛苦"
        default:
            return ""
        }
    }
    
    private var handlePosition: CGPoint {
        let radius = (diameter - lineWidth) / 2
        let angleInRadians = angle * .pi / 180
        let x = diameter / 2 + radius * cos(angleInRadians)
        let y = diameter / 2 + radius * sin(angleInRadians)
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - 手势处理
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                isDragging = true
                let oldValue = value
                updateValue(for: gesture.location)
                
                // 只在值改变时触发触觉反馈
                if value != oldValue {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
            .onEnded { _ in
                isDragging = false
                
                // 结束时的触觉反馈
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            }
    }
    
    private func updateValue(for location: CGPoint) {
        let center = CGPoint(x: diameter / 2, y: diameter / 2)
        let vector = CGPoint(x: location.x - center.x, y: location.y - center.y)
        
        var newAngle = atan2(vector.y, vector.x) * 180 / .pi
        if newAngle < 0 {
            newAngle += 360
        }
        
        // 调整角度以匹配-90度起始点
        newAngle = (newAngle + 90).truncatingRemainder(dividingBy: 360)
        
        angle = newAngle
        
        // 计算对应的值
        let normalizedAngle = newAngle / 360
        let newValue = Int(round(normalizedAngle * Double(range.upperBound - range.lowerBound))) + range.lowerBound
        value = min(max(newValue, range.lowerBound), range.upperBound)
    }
    
    private func angleForValue(_ val: Int) -> Double {
        let normalizedValue = Double(val - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        return normalizedValue * 360
    }
}

// MARK: - 增强版疼痛评估视图

/// 增强版疼痛评估 - 使用圆形滑块和情感化反馈
struct EnhancedPainAssessmentView: View {
    @Binding var intensity: Int
    @State private var isDragging = false
    @State private var showEncouragement = false
    
    var body: some View {
        VStack(spacing: 40) {
            // 标题
            VStack(spacing: 8) {
                Text("疼痛强度")
                    .font(.title2.weight(.semibold))
                Text("拖动圆环上的白点来选择")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // 圆形滑块
            CircularSlider(
                value: $intensity,
                range: 0...10,
                isDragging: $isDragging
            )
            
            // 鼓励性提示（根据疼痛程度显示）
            if showEncouragement {
                encouragementText
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: intensity) { _, newValue in
            // 当疼痛强度较低时显示鼓励
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showEncouragement = newValue <= 3 && newValue > 0
            }
        }
    }
    
    private var encouragementText: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .foregroundStyle(Color.gentlePink)
            Text("轻度不适也值得记录")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(12)
        .background(Color.gentlePink.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 预览

#Preview("Circular Slider") {
    @Previewable @State var value = 5
    @Previewable @State var isDragging = false
    
    VStack(spacing: 40) {
        Text("疼痛强度评估")
            .font(.title.bold())
        
        CircularSlider(
            value: $value,
            range: 0...10,
            isDragging: $isDragging
        )
        
        Text("当前值: \(value)")
            .font(.headline)
            .foregroundStyle(Color.textSecondary)
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("Enhanced Pain Assessment") {
    @Previewable @State var intensity = 3
    
    ScrollView {
        EnhancedPainAssessmentView(intensity: $intensity)
            .padding()
    }
    .background(Color.backgroundPrimary)
}
