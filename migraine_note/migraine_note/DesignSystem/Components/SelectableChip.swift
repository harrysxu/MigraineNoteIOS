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
    var accessibilityHint: String?
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSelected.toggle()
            }
            
            // 触觉反馈
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline)
                
                // 选中状态图标
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: 32) // 确保足够的触摸目标高度
            .background(isSelected ? Color.primary : Color.backgroundTertiary)
            .foregroundStyle(isSelected ? .white : Color.labelPrimary)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(isSelected ? Color.clear : Color.labelTertiary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(accessibilityHint ?? (isSelected ? "已选择，点击取消选择" : "未选择，点击选择"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("SelectableChip") {
    struct ChipPreview: View {
        @State private var selections = [false, true, false, false, true]
        
        var body: some View {
            FlowLayout(spacing: 8) {
                ForEach(0..<5) { index in
                    SelectableChip(label: "选项 \(index + 1)", isSelected: $selections[index])
                }
            }
            .padding()
            .background(Color.backgroundPrimary)
        }
    }
    
    return ChipPreview()
}
