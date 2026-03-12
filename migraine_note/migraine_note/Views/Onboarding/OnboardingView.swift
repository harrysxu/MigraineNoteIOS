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
                        Button("跳过") {
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
                Text("欢迎使用头痛管家")
                    .font(.title.bold())
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "记录每次发作，发现健康规律"
                    )
                    
                    FeatureRow(
                        icon: "person.crop.circle.badge.checkmark",
                        text: "与医生更好地沟通你的症状"
                    )
                    
                    FeatureRow(
                        icon: "heart.text.square.fill",
                        text: "科学管理，改善生活质量"
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
                Text("您的数据，完全私密")
                    .font(.title.bold())
                    .foregroundStyle(Color.textPrimary)
                
                VStack(spacing: 12) {
                    PrivacyFeatureRow(
                        icon: "iphone",
                        text: "仅存储在您的设备"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "icloud.fill",
                        text: "通过iCloud自动同步"
                    )
                    
                    PrivacyFeatureRow(
                        icon: "hand.raised.fill",
                        text: "我们无法访问您的数据"
                    )
                }
                .padding(.horizontal, 40)
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("需要的权限（可选）")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.bottom, 4)
                    
                    PermissionRow(
                        icon: "location.fill",
                        text: "位置服务 - 记录天气诱因"
                    )
                    
                    PermissionRow(
                        icon: "heart.fill",
                        text: "Apple 健康 - 读取经期数据分析关联"
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
                Text("一切准备就绪")
                    .font(.title.bold())
                    .foregroundStyle(Color.textPrimary)
                
                Text("要现在开始第一次记录吗？")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                
                // 提示卡片
                EmotionalCard(style: .default) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.point.right.fill")
                                .foregroundStyle(Color.warmAccent)
                            Text("快速开始")
                                .font(.headline)
                        }
                        
                        Text("点击首页的\"轻触记录\"按钮\n即可开始您的第一次记录")
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
                    Text("开始使用")
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
