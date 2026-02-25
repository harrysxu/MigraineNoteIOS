//
//  OnboardingView.swift
//  migraine_note
//
//  Created on 2026/2/2.
//

import SwiftUI

// MARK: - Onboarding主视图

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            VStack {
                // 跳过按钮
                if currentPage < 2 {
                    HStack {
                        Spacer()
                        Button(String(localized: "onboarding.skip")) {
                            withAnimation {
                                isOnboardingComplete = true
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .padding()
                    }
                } else {
                    Spacer().frame(height: 44)
                }
                
                // 页面内容
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    PrivacyPage()
                        .tag(1)
                    
                    ReadyPage(isOnboardingComplete: $isOnboardingComplete)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)
                
                Spacer()
            }
        }
    }
}

// MARK: - 第1页：欢迎

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 插画占位（使用SF Symbols模拟）
            ZStack {
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 200, height: 200)
                    .opacity(0.1)
                
                VStack(spacing: 16) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.primaryGradient)
                    
                    // 装饰性元素
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.accentSecondary)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.warmAccent)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            VStack(spacing: 16) {
                Text(String(localized: "onboarding.welcome"))
                    .font(.title.bold())
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: String(localized: "onboarding.feature.record")
                    )
                    
                    FeatureRow(
                        icon: "person.crop.circle.badge.checkmark",
                        text: String(localized: "onboarding.feature.communicate")
                    )
                    
                    FeatureRow(
                        icon: "heart.text.square.fill",
                        text: String(localized: "onboarding.feature.manage")
                    )
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 第2页：隐私说明

struct PrivacyPage: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 插画占位
            ZStack {
                Circle()
                    .fill(Color.statusSuccess.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.statusSuccess)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.statusSuccess)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.statusSuccess)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.statusSuccess)
                    }
                    .font(.title3)
                }
            }
            
            VStack(spacing: 16) {
                Text(String(localized: "onboarding.privacy.title"))
                    .font(.title.bold())
                    .foregroundStyle(Color.textPrimary)
                
                VStack(spacing: 12) {
                    PrivacyFeatureRow(
                        icon: "iphone",
                        text: String(localized: "onboarding.privacy.local")
                    )
                    
                    PrivacyFeatureRow(
                        icon: "icloud.fill",
                        text: String(localized: "onboarding.privacy.icloud")
                    )
                    
                    PrivacyFeatureRow(
                        icon: "hand.raised.fill",
                        text: String(localized: "onboarding.privacy.no.access")
                    )
                }
                .padding(.horizontal, 40)
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "onboarding.permissions.optional"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.bottom, 4)
                    
                    PermissionRow(
                        icon: "location.fill",
                        text: String(localized: "onboarding.location.reason")
                    )
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 第3页：准备就绪

struct ReadyPage: View {
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 插画占位
            ZStack {
                Circle()
                    .fill(Color.warmAccent.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.statusSuccess)
                    
                    // 欢呼装饰
                    HStack(spacing: 16) {
                        Text("✨")
                            .font(.system(size: 24))
                        Text("🎉")
                            .font(.system(size: 24))
                        Text("✨")
                            .font(.system(size: 24))
                    }
                }
            }
            
            VStack(spacing: 16) {
                Text(String(localized: "onboarding.ready.title"))
                    .font(.title.bold())
                    .foregroundStyle(Color.textPrimary)
                
                Text(String(localized: "onboarding.ready.question"))
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                
                // 提示卡片
                EmotionalCard(style: .default) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.point.right.fill")
                                .foregroundStyle(Color.warmAccent)
                            Text(String(localized: "onboarding.quick.start"))
                                .font(.headline)
                        }
                        
                        Text(String(localized: "onboarding.quick.start.hint"))
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // 开始按钮
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isOnboardingComplete = true
                }
                
                // 触觉反馈
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } label: {
                HStack {
                    Text(String(localized: "onboarding.start"))
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primaryGradient)
                .cornerRadius(16)
                .shadow(color: Color.accentPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .padding()
    }
}

// MARK: - 辅助组件

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.statusSuccess)
                .frame(width: 32)
            
            Text(text)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 预览

#Preview("Onboarding") {
    @Previewable @State var isComplete = false
    
    OnboardingView(isOnboardingComplete: $isComplete)
}

#Preview("Welcome Page") {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        WelcomePage()
    }
}

#Preview("Privacy Page") {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        PrivacyPage()
    }
}

#Preview("Ready Page") {
    @Previewable @State var isComplete = false
    
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        ReadyPage(isOnboardingComplete: $isComplete)
    }
}
