//
//  ThreeColumnStat.swift
//  migraine_note
//
//  Medical Minimalism Design System
//  三列统计数据组件
//

import SwiftUI

/// 三列统计数据组件
/// 用于显示本月概览等统计信息
struct ThreeColumnStat: View {
    let stat1: (value: String, label: String)
    let stat2: (value: String, label: String)
    let stat3: (value: String, label: String)
    
    var body: some View {
        HStack(spacing: 0) {
            StatColumn(value: stat1.value, label: stat1.label)
            
            Divider()
                .frame(height: 50)
            
            StatColumn(value: stat2.value, label: stat2.label)
            
            Divider()
                .frame(height: 50)
            
            StatColumn(value: stat3.value, label: stat3.label)
        }
        .frame(height: 70)
    }
    
    /// 单列统计数据
    struct StatColumn: View {
        let value: String
        let label: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.labelPrimary)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.labelSecondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label)：\(value)")
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        VStack(alignment: .leading, spacing: 16) {
            Text("本月概览")
                .font(.title3.weight(.semibold))
            
            ThreeColumnStat(
                stat1: ("8天", "发作天数"),
                stat2: ("6.5/10", "平均强度"),
                stat3: ("7次", "用药次数")
            )
        }
        .padding()
        .background(Color.backgroundPrimary)
        
        // 深色模式
        VStack(alignment: .leading, spacing: 16) {
            Text("本月概览")
                .font(.title3.weight(.semibold))
            
            ThreeColumnStat(
                stat1: ("12天", "发作天数"),
                stat2: ("7.8/10", "平均强度"),
                stat3: ("15次", "用药次数")
            )
        }
        .padding()
        .background(Color.backgroundPrimary)
        .preferredColorScheme(.dark)
    }
}
