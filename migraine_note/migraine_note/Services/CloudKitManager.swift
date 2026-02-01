//
//  CloudKitManager.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import Foundation
import SwiftUI

/// CloudKit同步状态管理器
@Observable
class CloudKitManager {
    /// iCloud账号登录状态
    var isICloudAvailable: Bool = false
    
    /// 同步状态
    var syncStatus: SyncStatus = .unknown
    
    /// 最后同步时间
    var lastSyncDate: Date?
    
    /// 错误信息
    var errorMessage: String?
    
    init() {
        checkICloudStatus()
        setupNotificationObserver()
    }
    
    // MARK: - iCloud状态检查
    
    /// 检查iCloud账号登录状态
    func checkICloudStatus() {
        // 使用 ubiquityIdentityToken 检查iCloud登录状态
        // 如果token不为nil，说明用户已登录iCloud
        isICloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        
        if isICloudAvailable {
            syncStatus = .available
        } else {
            syncStatus = .notSignedIn
        }
    }
    
    // MARK: - 通知监听
    
    /// 监听iCloud账号变更通知
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .NSUbiquityIdentityDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkICloudStatus()
        }
    }
    
    // MARK: - 同步状态
    
    enum SyncStatus {
        case unknown           // 未知状态
        case available         // 可用（已登录iCloud）
        case notSignedIn       // 未登录iCloud
        case syncing           // 同步中
        case syncCompleted     // 同步完成
        case syncFailed        // 同步失败
        
        var displayText: String {
            switch self {
            case .unknown:
                return "检查中..."
            case .available:
                return "iCloud同步已启用"
            case .notSignedIn:
                return "未登录iCloud"
            case .syncing:
                return "正在同步..."
            case .syncCompleted:
                return "同步完成"
            case .syncFailed:
                return "同步失败"
            }
        }
        
        var icon: String {
            switch self {
            case .unknown:
                return "questionmark.circle"
            case .available:
                return "checkmark.icloud.fill"
            case .notSignedIn:
                return "exclamationmark.icloud"
            case .syncing:
                return "arrow.clockwise.icloud"
            case .syncCompleted:
                return "checkmark.icloud.fill"
            case .syncFailed:
                return "xmark.icloud.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .unknown:
                return .gray
            case .available, .syncCompleted:
                return .green
            case .notSignedIn:
                return .orange
            case .syncing:
                return .blue
            case .syncFailed:
                return .red
            }
        }
    }
}
