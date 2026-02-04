//
//  PainIntensitySlider.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

struct PainIntensitySlider: View {
    @Binding var value: Int
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // 表情图标反馈
            Image(systemName: painFaceIcon)
                .font(.system(size: 60))
                .foregroundStyle(painColor)
                .animation(.easeInOut(duration: 0.2), value: value)
            
            // 大数字显示
            Text("\(value)")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(painColor)
                .animation(.easeInOut(duration: 0.2), value: value)
            
            // 滑块
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: 0...10,
                step: 1
            )
            .tint(painColor)
            .frame(height: 44)
            
            // 描述文字
            HStack {
                Text("无痛")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("剧痛")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
    
    var painColor: Color {
        Color.painCategoryColor(for: value)
    }
    
    var painFaceIcon: String {
        switch value {
        case 0...2:
            return "face.smiling"
        case 3...5:
            return "face.dashed"
        case 6...7:
            return "face.frowning"
        case 8...10:
            return "😭" // 使用emoji作为备选
        default:
            return "face.neutral"
        }
    }
}

#Preview {
    struct SliderPreview: View {
        @State private var painValue = 5
        
        var body: some View {
            VStack {
                PainIntensitySlider(value: $painValue)
                    .padding()
                
                Text("当前疼痛级别: \(painValue)")
                    .foregroundStyle(Color.textSecondary)
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return SliderPreview()
}
