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
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 0) {
                // 标题栏（可点击）
                Button {
                    withAnimation(AppAnimation.gentleSpring) {
                        isExpanded.toggle()
                    }
                    // 触觉反馈
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 32)
                        
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(AppAnimation.standard, value: isExpanded)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(ModernPressStyle(scale: 0.99, hapticFeedback: false))
                
                // 内容区域（可展开/收起）
                if isExpanded {
                    Divider()
                        .padding(.vertical, 8)
                        .transition(.opacity)
                    
                    content()
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                            .combined(with: .scale(scale: 0.98))
                        )
                }
            }
        }
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
                withAnimation(AppAnimation.gentleSpring) {
                    isExpanded.toggle()
                }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(AppAnimation.standard, value: isExpanded)
                }
            }
            .buttonStyle(ModernPressStyle(scale: 0.99, hapticFeedback: false))
            
            // 内容区域
            if isExpanded {
                content()
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.98))
                    )
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
                    .foregroundStyle(Color.textSecondary)
                
                HStack {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(Color.accentPrimary)
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
                .foregroundStyle(Color.textSecondary)
        }
        
        Spacer()
    }
    .padding()
    .background(Color.backgroundPrimary)
}
