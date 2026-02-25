//
//  PremiumManager.swift
//  migraine_note
//
//  高级版状态管理单例
//

import Foundation
import SwiftUI

/// 高级版功能类型
enum PremiumFeature: String, CaseIterable {
    case advancedAnalytics = "advanced_analytics"    // 高级数据分析
    case dataExport = "data_export"                  // 数据导出
    case medicalReport = "medical_report"            // 医疗报告
    case iCloudSync = "icloud_sync"                  // iCloud 同步
    case menstrualAnalysis = "menstrual_analysis"    // 经期关联分析
    case customLabels = "custom_labels"              // 自定义标签
    case medicationReminder = "medication_reminder"  // 用药提醒
    case weatherTracking = "weather_tracking"        // 天气追踪
    
    var displayName: String {
        switch self {
        case .advancedAnalytics: return String(localized: "premium.feature.advancedAnalytics")
        case .dataExport: return String(localized: "premium.feature.dataExport")
        case .medicalReport: return String(localized: "premium.feature.medicalReport")
        case .iCloudSync: return String(localized: "premium.feature.icloudSync")
        case .menstrualAnalysis: return String(localized: "premium.feature.menstrualAnalysis")
        case .customLabels: return String(localized: "premium.feature.customLabels")
        case .medicationReminder: return String(localized: "premium.feature.medicationReminder")
        case .weatherTracking: return String(localized: "premium.feature.weatherTracking")
        }
    }
    
    var icon: String {
        switch self {
        case .advancedAnalytics: return "chart.bar.fill"
        case .dataExport: return "square.and.arrow.up.fill"
        case .medicalReport: return "doc.text.fill"
        case .iCloudSync: return "icloud.fill"
        case .menstrualAnalysis: return "heart.circle.fill"
        case .customLabels: return "tag.fill"
        case .medicationReminder: return "bell.badge.fill"
        case .weatherTracking: return "cloud.sun.fill"
        }
    }
    
    var description: String {
        switch self {
        case .advancedAnalytics: return String(localized: "premium.feature.advancedAnalytics.desc")
        case .dataExport: return String(localized: "premium.feature.dataExport.desc")
        case .medicalReport: return String(localized: "premium.feature.medicalReport.desc")
        case .iCloudSync: return String(localized: "premium.feature.icloudSync.desc")
        case .menstrualAnalysis: return String(localized: "premium.feature.menstrualAnalysis.desc")
        case .customLabels: return String(localized: "premium.feature.customLabels.desc")
        case .medicationReminder: return String(localized: "premium.feature.medicationReminder.desc")
        case .weatherTracking: return String(localized: "premium.feature.weatherTracking.desc")
        }
    }
}

/// 购买类型
enum PurchaseType: String, CaseIterable, Identifiable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"
    
    var id: String { rawValue }
    
    var productId: String {
        switch self {
        case .monthly: return "com.xxl.migraine_note.pro.monthly"
        case .yearly: return "com.xxl.migraine_note.pro.yearly"
        case .lifetime: return "com.xxl.migraine_note.pro.lifetime"
        }
    }
    
    var displayName: String {
        switch self {
        case .monthly: return String(localized: "premium.purchase.monthly")
        case .yearly: return String(localized: "premium.purchase.yearly")
        case .lifetime: return String(localized: "premium.purchase.lifetime")
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "¥3"
        case .yearly: return "¥8"
        case .lifetime: return "¥18"
        }
    }
    
    var period: String {
        switch self {
        case .monthly: return "/月"
        case .yearly: return "/年"
        case .lifetime: return ""
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthly: return String(localized: "premium.purchase.monthly.subtitle")
        case .yearly: return String(localized: "premium.purchase.yearly.subtitle")
        case .lifetime: return String(localized: "premium.purchase.lifetime.subtitle")
        }
    }
    
    var isBestValue: Bool {
        self == .yearly
    }
}

/// 高级版状态管理单例
@Observable
class PremiumManager {
    static let shared = PremiumManager()
    
    /// 当前是否为高级版用户
    var isPremium: Bool {
        #if DEBUG
        if let override = debugPremiumOverride {
            return override
        }
        #endif
        return _isPremium
    }
    
    /// 当前购买类型（nil 表示未购买）
    var currentPurchaseType: PurchaseType?
    
    /// 订阅到期日期（买断为 nil）
    var expirationDate: Date?
    
    #if DEBUG
    /// 测试环境：高级版状态覆盖开关
    var debugPremiumOverride: Bool? {
        didSet {
            UserDefaults.standard.set(debugPremiumOverride, forKey: "debug_premium_override")
        }
    }
    #endif
    
    // MARK: - Private
    
    private var _isPremium: Bool = false {
        didSet {
            UserDefaults.standard.set(_isPremium, forKey: "is_premium")
        }
    }
    
    private init() {
        // 从缓存恢复状态
        _isPremium = UserDefaults.standard.bool(forKey: "is_premium")
        
        if let typeRaw = UserDefaults.standard.string(forKey: "purchase_type") {
            currentPurchaseType = PurchaseType(rawValue: typeRaw)
        }
        
        expirationDate = UserDefaults.standard.object(forKey: "expiration_date") as? Date
        
        #if DEBUG
        if let override = UserDefaults.standard.object(forKey: "debug_premium_override") as? Bool {
            debugPremiumOverride = override
        }
        #endif
    }
    
    // MARK: - 检查某个功能是否可用
    
    func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        return isPremium
    }
    
    // MARK: - 更新购买状态
    
    func updatePurchaseStatus(isPremium: Bool, type: PurchaseType?, expiration: Date?) {
        _isPremium = isPremium
        currentPurchaseType = type
        expirationDate = expiration
        
        // 持久化
        UserDefaults.standard.set(type?.rawValue, forKey: "purchase_type")
        UserDefaults.standard.set(expiration, forKey: "expiration_date")
    }
    
    // MARK: - 状态描述
    
    var statusDescription: String {
        if isPremium {
            #if DEBUG
            if debugPremiumOverride == true {
                return "\(String(localized: "premium.status.premium"))（\(String(localized: "premium.testMode"))）"
            }
            #endif
            
            if let type = currentPurchaseType {
                switch type {
                case .lifetime:
                    return "终身高级版"
                case .monthly, .yearly:
                    if let date = expirationDate {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy/MM/dd"
                        return "\(type.displayName) · \(formatter.string(from: date))到期"
                    }
                    return type.displayName
                }
            }
            return String(localized: "premium.status.premium")
        }
        return String(localized: "premium.status.free")
    }
}
