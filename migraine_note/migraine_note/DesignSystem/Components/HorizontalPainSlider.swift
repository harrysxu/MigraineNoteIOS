//
//  HorizontalPainSlider.swift
//  migraine_note
//
//  Created on 2026/2/2.
//

import SwiftUI

// MARK: - 横向疼痛强度滑块组件

/// 横向滑块 - 用于疼痛强度评估的情感化交互组件
struct HorizontalPainSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    @Binding var isDragging: Bool
    
    @State private var sliderWidth: CGFloat = 0
    
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
        VStack(spacing: 24) {
            // 上半部分：表情 + 数字 + 描述
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
                    .foregroundStyle(Color.labelSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // 下半部分：横向滑块
            VStack(spacing: 12) {
                // 滑块轨道和手柄
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景轨道（渐变）
                        RoundedRectangle(cornerRadius: 8)
                            .fill(trackGradient)
                            .frame(height: 16)
                        
                        // 刻度标记
                        HStack(spacing: 0) {
                            ForEach(range.lowerBound...range.upperBound, id: \.self) { tick in
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 16)
                        
                        // 拖动手柄
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .scaleEffect(isDragging ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                            .offset(x: handleOffset(for: geometry.size.width))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        isDragging = true
                                        updateValue(for: gesture.location.x, width: geometry.size.width)
                                        
                                        // 触觉反馈
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                        
                                        // 结束时的触觉反馈
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                            )
                    }
                    .onAppear {
                        sliderWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        sliderWidth = newWidth
                    }
                }
                .frame(height: 40)
                
                // 刻度数字
                HStack(spacing: 0) {
                    ForEach(range.lowerBound...range.upperBound, id: \.self) { tick in
                        Text("\(tick)")
                            .font(.caption2)
                            .foregroundStyle(value == tick ? painColor : Color.labelTertiary)
                            .fontWeight(value == tick ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - 计算属性
    
    private var progress: Double {
        Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
    }
    
    private var painColor: Color {
        Color.painIntensityColor(for: value)
    }
    
    private var trackGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.painIntensityColor(for: range.lowerBound),
                Color.painIntensityColor(for: (range.lowerBound + range.upperBound) / 2),
                Color.painIntensityColor(for: range.upperBound)
            ],
            startPoint: .leading,
            endPoint: .trailing
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
    
    // MARK: - 手柄位置计算
    
    private func handleOffset(for width: CGFloat) -> CGFloat {
        let progress = Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        return CGFloat(progress) * width - 12 // 12 是手柄半径
    }
    
    private func updateValue(for xPosition: CGFloat, width: CGFloat) {
        let progress = max(0, min(1, xPosition / width))
        let newValue = Int(round(progress * Double(range.upperBound - range.lowerBound))) + range.lowerBound
        value = min(max(newValue, range.lowerBound), range.upperBound)
    }
}

// MARK: - 预览

#Preview("Horizontal Pain Slider") {
    @Previewable @State var value = 5
    @Previewable @State var isDragging = false
    
    VStack(spacing: 40) {
        Text("疼痛强度评估")
            .font(.title.bold())
        
        HorizontalPainSlider(
            value: $value,
            range: 0...10,
            isDragging: $isDragging
        )
        .padding(.horizontal, 20)
        
        Text("当前值: \(value)")
            .font(.headline)
            .foregroundStyle(Color.labelSecondary)
    }
    .padding()
    .background(Color.backgroundPrimary)
}
