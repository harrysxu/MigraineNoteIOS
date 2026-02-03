//
//  CustomInputField.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI

/// 自定义输入框组件
/// 用于在选择器下方提供自定义输入功能
struct CustomInputField: View {
    let placeholder: String
    let onAdd: (String) -> Void
    var errorMessage: String? = nil
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @State private var showError: Bool = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.title3)
                    .symbolEffect(.bounce, value: isFocused)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        addCustomItem()
                    }
                
                // 清除按钮
                if !text.isEmpty {
                    Button {
                        withAnimation(AppAnimation.fast) {
                            text = ""
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textTertiary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                    .rotationEffect(.degrees(text.isEmpty ? 90 : 0))
                }
                
                // 提交按钮
                if !text.isEmpty {
                    Button {
                        addCustomItem()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(12)
            .background(Color.backgroundTertiary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ?
                        LinearGradient(
                            colors: [
                                Color.accentPrimary,
                                Color.accentPrimary.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.divider, Color.divider],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .shadow(
                color: isFocused ? Color.accentPrimary.opacity(0.3) : Color.clear,
                radius: isFocused ? 12 : 0,
                x: 0,
                y: 0
            )
            .offset(x: shakeOffset)
            .animation(AppAnimation.standard, value: isFocused)
            
            // 错误提示
            if showError, let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.statusError)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func addCustomItem() {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else {
            // 空输入时震动提示
            showError = true
            triggerShakeAnimation()
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showError = false
                }
            }
            return
        }
        
        onAdd(trimmedText)
        text = ""
        isFocused = false
        
        // 成功触觉反馈
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    private func triggerShakeAnimation() {
        let shakeDistance: CGFloat = 10
        withAnimation(Animation.spring(duration: 0.05, bounce: 0.5).repeatCount(3, autoreverses: true)) {
            shakeOffset = shakeDistance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeOffset = 0
        }
    }
}

// MARK: - 带标签的自定义输入框

struct LabeledCustomInputField: View {
    let label: String
    let placeholder: String
    let onAdd: (String) -> Void
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textSecondary)
            
            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        addCustomItem()
                    }
                
                Button {
                    addCustomItem()
                } label: {
                    Text("添加")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(text.isEmpty ? Color.textTertiary : Color.accentPrimary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(text.isEmpty)
            }
            .padding(12)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentPrimary : Color.divider, lineWidth: 1)
            )
        }
    }
    
    private func addCustomItem() {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }
        
        onAdd(trimmedText)
        text = ""
        isFocused = false
        
        // 触觉反馈
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - 紧凑型自定义输入框（用于Flow Layout中）

struct CompactCustomInputField: View {
    let placeholder: String
    let onAdd: (String) -> Void
    
    @State private var showInput: Bool = false
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        if showInput {
            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        addCustomItem()
                    }
                    .frame(minWidth: 100)
                
                Button {
                    addCustomItem()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.statusSuccess)
                }
                .buttonStyle(.plain)
                .disabled(text.isEmpty)
                
                Button {
                    showInput = false
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.backgroundSecondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentPrimary, lineWidth: 1)
            )
            .onAppear {
                isFocused = true
            }
        } else {
            Button {
                showInput = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                    Text("自定义")
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentPrimary.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                        .foregroundStyle(Color.accentPrimary.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func addCustomItem() {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }
        
        onAdd(trimmedText)
        text = ""
        showInput = false
        
        // 触觉反馈
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            // 基础版本
            VStack(alignment: .leading, spacing: 8) {
                Text("基础自定义输入")
                    .font(.headline)
                
                CustomInputField(placeholder: "输入自定义选项...") { text in
                    print("Added: \(text)")
                }
            }
            
            // 带标签版本
            LabeledCustomInputField(
                label: "自定义症状",
                placeholder: "输入其他症状..."
            ) { text in
                print("Added: \(text)")
            }
            
            // 紧凑版本（用于Flow Layout）
            VStack(alignment: .leading, spacing: 8) {
                Text("紧凑型（用于选项流）")
                    .font(.headline)
                
                FlowLayout(spacing: 8) {
                    ForEach(["头痛", "恶心", "畏光"], id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentPrimary.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    CompactCustomInputField(placeholder: "其他...") { text in
                        print("Added: \(text)")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}
