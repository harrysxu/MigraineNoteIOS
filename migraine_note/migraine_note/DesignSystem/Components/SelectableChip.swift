//
//  SelectableChip.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

struct SelectableChip: View {
    let label: String
    @Binding var isSelected: Bool
    var icon: String? = nil
    var accessibilityHint: String?
    var useLiquidGlass: Bool = true
    
    var body: some View {
        Button {
            withAnimation(AppAnimation.buttonPress) {
                isSelected.toggle()
            }
            
            // 触觉反馈
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 6) {
                // 前置图标
                if let icon = icon, !isSelected {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(label)
                    .font(.subheadline.weight(isSelected ? .medium : .regular))
                
                // 选中状态图标
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: isSelected)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: 32)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        (useLiquidGlass ?
                         LinearGradient(
                            colors: [Color.backgroundTertiary.opacity(0.6), Color.backgroundTertiary.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                         ) :
                         LinearGradient(
                            colors: [Color.backgroundTertiary, Color.backgroundTertiary],
                            startPoint: .leading,
                            endPoint: .trailing
                         ))
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ] : [
                                Color.textTertiary.opacity(0.3),
                                Color.textTertiary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .shadow(
                color: isSelected ? Color.accentPrimary.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(ModernPressStyle(scale: 0.95, hapticFeedback: false))
        .accessibilityLabel(label)
        .accessibilityHint(accessibilityHint ?? (isSelected ? "已选择，点击取消选择" : "未选择，点击选择"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("SelectableChip") {
    struct ChipPreview: View {
        @State private var selections = [false, true, false, false, true]
        @State private var withIcons = [false, true, false, false]
        
        var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    // 基础 Chip
                    VStack(alignment: .leading, spacing: 12) {
                        Text("基础 Chip")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(0..<5) { index in
                                SelectableChip(
                                    label: "选项 \(index + 1)",
                                    isSelected: $selections[index]
                                )
                            }
                        }
                    }
                    
                    // 带图标的 Chip
                    VStack(alignment: .leading, spacing: 12) {
                        Text("带图标的 Chip")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            SelectableChip(
                                label: "头痛",
                                isSelected: $withIcons[0],
                                icon: "brain.head.profile"
                            )
                            SelectableChip(
                                label: "恶心",
                                isSelected: $withIcons[1],
                                icon: "staroflife.fill"
                            )
                            SelectableChip(
                                label: "畏光",
                                isSelected: $withIcons[2],
                                icon: "sun.max.fill"
                            )
                            SelectableChip(
                                label: "畏声",
                                isSelected: $withIcons[3],
                                icon: "speaker.wave.3.fill"
                            )
                        }
                    }
                    
                    // 不使用 Liquid Glass 的 Chip
                    VStack(alignment: .leading, spacing: 12) {
                        Text("标准样式")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(0..<3) { index in
                                SelectableChip(
                                    label: "标准 \(index + 1)",
                                    isSelected: $selections[index],
                                    useLiquidGlass: false
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return ChipPreview()
}
