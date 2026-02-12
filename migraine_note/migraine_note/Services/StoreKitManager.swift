//
//  StoreKitManager.swift
//  migraine_note
//
//  StoreKit 2 内购管理
//

import Foundation
import StoreKit

/// StoreKit 2 内购管理器
@Observable
class StoreKitManager {
    static let shared = StoreKitManager()
    
    /// 可用产品列表
    var products: [Product] = []
    
    /// 购买状态
    var purchaseState: PurchaseState = .idle
    
    /// 是否正在加载产品
    var isLoadingProducts: Bool = false
    
    /// 错误信息
    var errorMessage: String?
    
    /// 购买状态枚举
    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
        case restored
    }
    
    // MARK: - 产品 ID
    
    static let allProductIds: Set<String> = [
        PurchaseType.monthly.productId,
        PurchaseType.yearly.productId,
        PurchaseType.lifetime.productId
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // 监听交易更新（用于处理外部购买、恢复、退款等）
        updateListenerTask = listenForTransactions()
        
        // 启动时检查当前订阅状态
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 加载产品
    
    @MainActor
    func loadProducts() async {
        isLoadingProducts = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: StoreKitManager.allProductIds)
            
            // 按价格排序：月 -> 年 -> 终身
            products = storeProducts.sorted { p1, p2 in
                p1.price < p2.price
            }
            
            isLoadingProducts = false
        } catch {
            errorMessage = "加载产品失败：\(error.localizedDescription)"
            isLoadingProducts = false
        }
    }
    
    // MARK: - 购买产品
    
    @MainActor
    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // 更新高级版状态
                await updatePurchaseStatus()
                
                // 完成交易
                await transaction.finish()
                
                purchaseState = .purchased
                
            case .userCancelled:
                purchaseState = .idle
                
            case .pending:
                purchaseState = .idle
                errorMessage = "购买正在处理中，请稍后查看"
                
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            errorMessage = "购买失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 通过 PurchaseType 购买
    
    @MainActor
    func purchase(type: PurchaseType) async {
        guard let product = products.first(where: { $0.id == type.productId }) else {
            errorMessage = "未找到对应产品"
            return
        }
        await purchase(product)
    }
    
    // MARK: - 恢复购买
    
    @MainActor
    func restorePurchases() async {
        purchaseState = .purchasing
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
            
            if PremiumManager.shared.isPremium {
                purchaseState = .restored
            } else {
                purchaseState = .idle
                errorMessage = "未找到可恢复的购买记录"
            }
        } catch {
            purchaseState = .idle
            errorMessage = "恢复购买失败：\(error.localizedDescription)"
        }
    }
    
    // MARK: - 更新购买状态
    
    @MainActor
    func updatePurchaseStatus() async {
        var hasActiveSubscription = false
        var activePurchaseType: PurchaseType?
        var activeExpiration: Date?
        
        // 检查所有当前的已验证交易
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.revocationDate != nil {
                    continue
                }
                
                switch transaction.productID {
                case PurchaseType.lifetime.productId:
                    // 终身买断
                    hasActiveSubscription = true
                    activePurchaseType = .lifetime
                    activeExpiration = nil
                    
                case PurchaseType.monthly.productId:
                    if !hasActiveSubscription || activePurchaseType != .lifetime {
                        hasActiveSubscription = true
                        activePurchaseType = .monthly
                        activeExpiration = transaction.expirationDate
                    }
                    
                case PurchaseType.yearly.productId:
                    if !hasActiveSubscription || activePurchaseType != .lifetime {
                        hasActiveSubscription = true
                        activePurchaseType = .yearly
                        activeExpiration = transaction.expirationDate
                    }
                    
                default:
                    break
                }
            } catch {
                // 验证失败，跳过
                continue
            }
        }
        
        PremiumManager.shared.updatePurchaseStatus(
            isPremium: hasActiveSubscription,
            type: activePurchaseType,
            expiration: activeExpiration
        )
    }
    
    // MARK: - 监听交易更新
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    await self.updatePurchaseStatus()
                    
                    await transaction.finish()
                } catch {
                    // 交易验证失败
                }
            }
        }
    }
    
    // MARK: - 验证交易
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - 获取产品
    
    func product(for type: PurchaseType) -> Product? {
        products.first { $0.id == type.productId }
    }
    
    /// 获取产品的本地化价格字符串
    func localizedPrice(for type: PurchaseType) -> String {
        if let product = product(for: type) {
            return product.displayPrice
        }
        return type.price
    }
}

// MARK: - 错误类型

enum StoreError: LocalizedError {
    case failedVerification
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "交易验证失败"
        }
    }
}
