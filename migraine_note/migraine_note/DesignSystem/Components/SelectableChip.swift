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
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSelected.toggle()
            }
        } label: {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.accentPrimary : Color.backgroundTertiary)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .cornerRadius(CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(isSelected ? Color.clear : Color.textTertiary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
