//
//  LargeNumberDisplay.swift
//  migraine_note
//
//  Medical Minimalism Design System
//  大数值显示组件
//

import SwiftUI

/// 大数值显示组件
/// 用于首页显示关键指标，如连续无头痛天数
struct LargeNumberDisplay: View {
    let value: String
    let label: String
    let unit: String?
    
    init(value: String, label: String, unit: String? = nil) {
        self.value = value
        self.label = label
        self.unit = unit
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 数值和单位
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.labelPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(.title2)
                        .foregroundColor(.labelSecondary)
                }
            }
            
            // 标签
            Text(label)
                .font(.subheadline)
                .foregroundColor(.labelSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)：\(value)\(unit ?? "")")
    }
}

#Preview {
    VStack(spacing: 40) {
        LargeNumberDisplay(
            value: "12",
            label: "连续无头痛天数",
            unit: "天"
        )
        
        LargeNumberDisplay(
            value: "8",
            label: "本月发作天数"
        )
        
        // 深色模式
        LargeNumberDisplay(
            value: "12",
            label: "连续无头痛天数",
            unit: "天"
        )
        .preferredColorScheme(.dark)
    }
    .padding()
}
