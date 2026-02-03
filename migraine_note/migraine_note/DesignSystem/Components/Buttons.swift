//
//  PrimaryButton.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isEnabled && !isLoading {
                        LinearGradient(
                            colors: [
                                Color.accentPrimary,
                                Color.accentPrimary.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.textTertiary
                    }
                }
            )
            .cornerRadius(CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isEnabled ? 0.2 : 0),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(ModernPressStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                        .scaleEffect(0.9)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isEnabled ? Color.accentPrimary : Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(
                        LinearGradient(
                            colors: isEnabled ? [
                                Color.accentPrimary,
                                Color.accentPrimary.opacity(0.7)
                            ] : [
                                Color.textTertiary,
                                Color.textTertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(ModernPressStyle())
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var backgroundColor: Color = Color.backgroundSecondary
    var foregroundColor: Color = Color.textPrimary
    var size: CGFloat = 44
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ModernPressStyle(scale: 0.95))
    }
}

// MARK: - 新增：悬浮操作按钮

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var gradient: [Color] = [Color.accentPrimary, Color.accentPrimary.opacity(0.8)]
    var size: CGFloat = 56
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: Color.accentPrimary.opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ModernPressStyle(scale: 0.93))
    }
}

// MARK: - 新增：胶囊按钮

struct PillButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var isSelected: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.medium))
                }
                
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.backgroundSecondary, Color.backgroundSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ?
                        Color.white.opacity(0.2) :
                        Color.textTertiary.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ModernPressStyle(scale: 0.96))
    }
}

#Preview("Buttons") {
    ScrollView {
        VStack(spacing: 20) {
            // 主按钮
            PrimaryButton(title: "主按钮", action: {})
            PrimaryButton(title: "加载中", action: {}, isLoading: true)
            PrimaryButton(title: "禁用状态", action: {}, isEnabled: false)
            
            // 次按钮
            SecondaryButton(title: "次按钮", action: {})
            SecondaryButton(title: "加载中", action: {}, isLoading: true)
            
            // 图标按钮
            HStack(spacing: 16) {
                IconButton(icon: "plus.circle.fill", action: {})
                IconButton(
                    icon: "heart.fill",
                    action: {},
                    backgroundColor: Color.accentPrimary.opacity(0.2),
                    foregroundColor: Color.accentPrimary
                )
                IconButton(
                    icon: "trash.fill",
                    action: {},
                    backgroundColor: Color.statusError.opacity(0.2),
                    foregroundColor: Color.statusError
                )
            }
            
            // 悬浮按钮
            HStack(spacing: 16) {
                FloatingActionButton(icon: "plus", action: {})
                FloatingActionButton(
                    icon: "heart.fill",
                    action: {},
                    gradient: [Color.red, Color.pink],
                    size: 48
                )
            }
            
            // 胶囊按钮
            HStack(spacing: 12) {
                PillButton(title: "全部", action: {}, isSelected: true)
                PillButton(title: "未读", action: {}, icon: "circle.fill", isSelected: false)
                PillButton(title: "重要", action: {}, icon: "star.fill", isSelected: false)
            }
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}
