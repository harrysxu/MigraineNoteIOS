//
//  PrimaryButton.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

/// 按钮缩放样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Color.primary : Color.labelTertiary)
                .cornerRadius(CornerRadius.xl)
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isEnabled ? Color.primary : Color.labelTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.backgroundSecondary)
                .cornerRadius(CornerRadius.xl)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .stroke(isEnabled ? Color.primary : Color.labelTertiary, lineWidth: 2)
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.labelPrimary)
                .frame(width: 44, height: 44)
                .background(Color.backgroundSecondary)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview("Buttons") {
    VStack(spacing: 20) {
        PrimaryButton(title: "主按钮", action: {})
        SecondaryButton(title: "次按钮", action: {})
        IconButton(icon: "plus.circle.fill", action: {})
        
        PrimaryButton(title: "禁用状态", action: {}, isEnabled: false)
    }
    .padding()
    .background(Color.backgroundPrimary)
}
