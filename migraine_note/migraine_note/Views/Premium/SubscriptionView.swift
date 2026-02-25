//
//  SubscriptionView.swift
//  migraine_note
//
//  订阅购买页面
//

import SwiftUI
import StoreKit

/// 订阅购买页面
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var premiumManager = PremiumManager.shared
    @State private var storeManager = StoreKitManager.shared
    @State private var selectedPlan: PurchaseType = .yearly
    @State private var showSuccessAlert = false
    @State private var showRestoreAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部标题区
                    headerSection
                    
                    // 功能亮点
                    featuresSection
                        .padding(.top, Spacing.lg)
                    
                    // 价格方案
                    pricingSection
                        .padding(.top, Spacing.xl)
                    
                    // 购买按钮
                    purchaseButton
                        .padding(.top, Spacing.lg)
                    
                    // 恢复购买 & 法律文字
                    footerSection
                        .padding(.top, Spacing.lg)
                        .padding(.bottom, Spacing.xl)
                }
                .padding(.horizontal, Spacing.md)
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
        }
        .alert("premium.purchaseSuccess", isPresented: $showSuccessAlert) {
            Button("common.ok") {
                dismiss()
            }
        } message: {
            Text("premium.purchaseSuccessMessage")
        }
        .alert("premium.restore", isPresented: $showRestoreAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(storeManager.errorMessage ?? String(localized: "premium.restoreComplete"))
        }
        .onChange(of: storeManager.purchaseState) { _, newValue in
            if newValue == .purchased {
                showSuccessAlert = true
            } else if newValue == .restored {
                showSuccessAlert = true
            }
        }
    }
    
    // MARK: - 顶部标题区
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // 图标
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, Spacing.xl)
            
            Text("premium.upgradeHeader")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.textPrimary)
            
            Text("premium.upgradeSubtitle")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 功能亮点
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(PremiumFeature.allCases, id: \.rawValue) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.body)
                        .foregroundStyle(Color.accentPrimary)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color.accentPrimary)
                }
                .padding(.vertical, 8)
                
                if feature != PremiumFeature.allCases.last {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(Spacing.cornerRadiusMedium)
    }
    
    // MARK: - 价格方案
    
    private var pricingSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("premium.selectPlan")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(PurchaseType.allCases) { plan in
                pricingCard(plan)
            }
        }
    }
    
    private func pricingCard(_ plan: PurchaseType) -> some View {
        let isSelected = selectedPlan == plan
        let localPrice = storeManager.localizedPrice(for: plan)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 12) {
                // 选中指示器
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentPrimary : Color.textTertiary)
                
                // 方案信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(plan.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        
                        if plan.isBestValue {
                            Text("premium.bestValue")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentPrimary)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                
                Spacer()
                
                // 价格
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(localPrice)
                        .font(.title2.bold())
                        .foregroundStyle(Color.textPrimary)
                    
                    if !plan.period.isEmpty {
                        Text(plan.period)
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .fill(isSelected ? Color.accentPrimary.opacity(0.08) : Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .stroke(isSelected ? Color.accentPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 购买按钮
    
    @ViewBuilder
    private var purchaseButton: some View {
        Button {
            Task {
                await storeManager.purchase(type: selectedPlan)
            }
        } label: {
            HStack(spacing: 12) {
                if storeManager.purchaseState == .purchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "crown.fill")
                        .font(.headline)
                }
                
                Text(purchaseButtonTitle)
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
        .disabled(storeManager.purchaseState == .purchasing)
        
        // 错误信息
        if let error = storeManager.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(Color.statusError)
                .padding(.top, Spacing.xs)
        }
    }
    
    private var purchaseButtonTitle: String {
        if storeManager.purchaseState == .purchasing {
            return String(localized: "premium.processing")
        }
        
        let price = storeManager.localizedPrice(for: selectedPlan)
        switch selectedPlan {
        case .monthly:
            return String(format: String(localized: "premium.subscribeMonth"), price)
        case .yearly:
            return String(format: String(localized: "premium.subscribeYear"), price)
        case .lifetime:
            return String(format: String(localized: "premium.buyLifetime"), price)
        }
    }
    
    // MARK: - 底部区域
    
    private var footerSection: some View {
        VStack(spacing: Spacing.md) {
            // 恢复购买
            Button {
                Task {
                    await storeManager.restorePurchases()
                }
            } label: {
                Text("premium.restore")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentPrimary)
            }
            
            // 法律文字
            VStack(spacing: 6) {
                Text("premium.termsHint")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
                
                Text("premium.termsHint2")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
                
                HStack(spacing: 12) {
                    Link("premium.termsOfUse", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .font(.caption2)
                    
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(Color.textTertiary)
                    
                    Link("premium.privacyPolicy", destination: URL(string: "https://harrysxu.github.io/MigraineNoteIOS/pages/privacy-policy.html")!)
                        .font(.caption2)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionView()
}
