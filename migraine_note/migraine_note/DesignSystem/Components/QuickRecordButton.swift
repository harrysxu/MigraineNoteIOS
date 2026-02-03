//
//  QuickRecordButton.swift
//  migraine_note
//
//  Medical Minimalism Design System
//  超大快速记录按钮组件
//

import SwiftUI

/// 超大快速记录按钮
/// 用于首页的主要操作按钮，强调快速记录理念
struct QuickRecordButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            // 中等触觉反馈
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            VStack(spacing: 16) {
                // SF Symbol 图标
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.primary)
                
                // 主要文字
                Text("开始记录")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.labelPrimary)
                
                // 提示文字
                Text("轻点记录，稍后可补充详情")
                    .font(.caption)
                    .foregroundColor(.labelSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color.backgroundSecondary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("开始记录头痛发作")
        .accessibilityHint("双击立即记录当前时间，稍后可补充详情")
    }
}

#Preview {
    VStack(spacing: 20) {
        QuickRecordButton {
            print("Quick record tapped")
        }
        .padding()
        
        // 深色模式预览
        QuickRecordButton {
            print("Quick record tapped")
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}
