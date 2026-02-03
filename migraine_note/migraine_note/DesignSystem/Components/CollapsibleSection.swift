//
//  CollapsibleSection.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI

/// 可折叠的Section组件
/// 支持展开/收起动画，可选择记住展开状态
struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpandedByDefault: Bool
    let content: () -> Content
    
    @State private var isExpanded: Bool
    
    init(
        title: String,
        icon: String,
        isExpandedByDefault: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isExpandedByDefault = isExpandedByDefault
        self.content = content
        _isExpanded = State(initialValue: isExpandedByDefault)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏（可点击）
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                // 触觉反馈
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(Color.primary)
                        .frame(width: 32)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.labelPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.labelTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            // 内容区域（可展开/收起）
            if isExpanded {
                Divider()
                    .padding(.vertical, 8)
                
                content()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - 简化版本（无图标）

struct CollapsibleSectionSimple<Content: View>: View {
    let title: String
    let isExpandedByDefault: Bool
    let content: () -> Content
    
    @State private var isExpanded: Bool
    
    init(
        title: String,
        isExpandedByDefault: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isExpandedByDefault = isExpandedByDefault
        self.content = content
        _isExpanded = State(initialValue: isExpandedByDefault)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏（可点击）
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.labelPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.labelTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            // 内容区域
            if isExpanded {
                content()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CollapsibleSection(
            title: "疼痛评估",
            icon: "waveform.path.ecg",
            isExpandedByDefault: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("这是疼痛评估的内容区域")
                    .font(.body)
                    .foregroundStyle(Color.labelSecondary)
                
                HStack {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        
        CollapsibleSection(
            title: "症状记录",
            icon: "heart.text.square",
            isExpandedByDefault: false
        ) {
            Text("这是症状记录的内容")
                .font(.body)
                .foregroundStyle(Color.labelSecondary)
        }
        
        Spacer()
    }
    .padding()
    .background(Color.backgroundPrimary)
}
