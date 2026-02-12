//
//  PremiumGateView.swift
//  migraine_note
//
//  高级功能拦截组件
//

import SwiftUI

/// 高级功能拦截视图 - 非 Pro 用户展示升级引导
struct PremiumGateView<Content: View>: View {
    let feature: PremiumFeature
    let content: () -> Content
    
    @State private var premiumManager = PremiumManager.shared
    @State private var showSubscription = false
    
    init(feature: PremiumFeature, @ViewBuilder content: @escaping () -> Content) {
        self.feature = feature
        self.content = content
    }
    
    var body: some View {
        if premiumManager.isFeatureAvailable(feature) {
            content()
        } else {
            premiumLockedView
        }
    }
    
    private var premiumLockedView: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer()
                    .frame(height: 40)
                
                // 锁定图标
                ZStack {
                    Circle()
                        .fill(Color.accentPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentPrimary)
                }
                
                // 功能名称
                VStack(spacing: Spacing.sm) {
                    Text(feature.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(feature.description)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                
                // 高级版功能亮点
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("升级高级版，解锁更多功能")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.bottom, 4)
                    
                    ForEach(highlightFeatures, id: \.rawValue) { f in
                        HStack(spacing: 10) {
                            Image(systemName: f.icon)
                                .font(.caption)
                                .foregroundStyle(Color.accentPrimary)
                                .frame(width: 24)
                            
                            Text(f.displayName)
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(Spacing.md)
                .background(Color.backgroundSecondary)
                .cornerRadius(Spacing.cornerRadiusMedium)
                .padding(.horizontal, Spacing.md)
                
                // 升级按钮
                Button {
                    showSubscription = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.headline)
                        Text("升级高级版")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Spacing.cornerRadiusMedium)
                }
                .padding(.horizontal, Spacing.md)
                
                // 价格提示
                Text("低至 ¥3/月")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                
                Spacer()
            }
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
    
    /// 展示 3-4 个亮点功能（包含当前被锁的功能）
    private var highlightFeatures: [PremiumFeature] {
        var features: [PremiumFeature] = [feature]
        let others = PremiumFeature.allCases.filter { $0 != feature }
        features.append(contentsOf: others.prefix(3))
        return features
    }
}

// MARK: - 便捷修饰符

extension View {
    /// 为视图添加高级版拦截
    /// 用于 NavigationLink 的目标视图
    func premiumGated(feature: PremiumFeature) -> some View {
        PremiumGateView(feature: feature) {
            self
        }
    }
}

/// 高级版标记角标 - 用于设置行等入口处显示 Pro 角标
struct PremiumBadge: View {
    @State private var premiumManager = PremiumManager.shared
    
    var body: some View {
        if !premiumManager.isPremium {
            Text("Pro")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(4)
        }
    }
}

// MARK: - Preview

#Preview("Locked") {
    NavigationStack {
        PremiumGateView(feature: .advancedAnalytics) {
            Text("Premium Content")
        }
        .navigationTitle("数据分析")
    }
}
