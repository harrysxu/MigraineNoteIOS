//
//  CloudKitManager.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import Foundation
import SwiftUI
import CoreData

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
    
    /// 活跃同步事件计数（用于追踪并发的导入/导出事件）
    private var activeSyncEvents: Int = 0
    
    /// 状态切换防抖定时器
    private var syncCompletedTimer: Timer?
    
    /// 通知观察者令牌（用于 deinit 清理）
    private var observers: [Any] = []
    
    /// UserDefaults 存储键
    private static let lastSyncDateKey = "cloudkit_last_sync_date"
    
    init() {
        // 从 UserDefaults 恢复上次同步时间
        lastSyncDate = UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date
        checkICloudStatus()
        setupNotificationObservers()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        syncCompletedTimer?.invalidate()
    }
    
    // MARK: - iCloud状态检查
    
    /// 检查iCloud账号登录状态
    func checkICloudStatus() {
        let syncEnabled = SyncSettingsManager.isSyncCurrentlyEnabled()
        
        if !syncEnabled {
            syncStatus = .disabled
            isICloudAvailable = false
            return
        }
        
        // 使用 ubiquityIdentityToken 检查iCloud登录状态
        isICloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        
        if isICloudAvailable {
            // 如果不在同步中，根据是否有历史同步记录决定显示状态
            if syncStatus != .syncing {
                syncStatus = lastSyncDate != nil ? .syncCompleted : .available
            }
        } else {
            syncStatus = .notSignedIn
        }
    }
    
    // MARK: - 通知监听
    
    /// 设置所有通知监听
    private func setupNotificationObservers() {
        // 1. 监听 iCloud 账号变更
        let accountObserver = NotificationCenter.default.addObserver(
            forName: .NSUbiquityIdentityDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkICloudStatus()
        }
        observers.append(accountObserver)
        
        // 2. 监听远程数据变更（其他设备的数据同步到本机时触发）
        let remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleRemoteStoreChange()
        }
        observers.append(remoteChangeObserver)
        
        // 3. 监听 CloudKit 详细同步事件（导入/导出/初始化，每个事件有开始和结束）
        let eventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleCloudKitEvent(notification)
        }
        observers.append(eventObserver)
    }
    
    // MARK: - 同步事件处理
    
    /// 处理远程数据变更通知（有实际数据从其他设备同步过来时才触发）
    private func handleRemoteStoreChange() {
        guard SyncSettingsManager.isSyncCurrentlyEnabled() else { return }
        
        // 远程数据变更 = 有真实数据同步，强制更新时间
        updateLastSyncDate(force: true)
        
        // 如果当前不在同步中，直接标记为完成
        if syncStatus != .syncing {
            withAnimation(.easeInOut(duration: 0.3)) {
                syncStatus = .syncCompleted
                errorMessage = nil
            }
        }
    }
    
    /// 处理 CloudKit 详细同步事件
    private func handleCloudKitEvent(_ notification: Notification) {
        guard SyncSettingsManager.isSyncCurrentlyEnabled() else { return }
        
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }
        
        if event.endDate == nil {
            // ── 同步事件开始 ──
            activeSyncEvents += 1
            syncCompletedTimer?.invalidate()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                syncStatus = .syncing
            }
        } else {
            // ── 同步事件结束 ──
            activeSyncEvents = max(0, activeSyncEvents - 1)
            
            if event.succeeded {
                // 不在这里更新时间，统一在防抖定时器中更新，避免频繁刷新
                errorMessage = nil
            } else if let error = event.error {
                let nsError = error as NSError
                // 忽略用户取消错误（常见于应用生命周期切换）
                if nsError.code != NSUserCancelledError {
                    errorMessage = error.localizedDescription
                }
            }
            
            // 所有活跃事件结束后，延迟切换到最终状态（防止频繁闪烁）
            if activeSyncEvents == 0 {
                syncCompletedTimer?.invalidate()
                syncCompletedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if self?.errorMessage != nil {
                                self?.syncStatus = .syncFailed
                            } else {
                                // 一批同步事件完成后，使用节流方式更新时间
                                self?.updateLastSyncDate()
                                self?.syncStatus = .syncCompleted
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 更新并持久化最后同步时间
    /// - Parameter force: 是否强制更新。为 false 时有最小间隔保护（60秒），避免 CloudKit 周期性检查导致时间频繁重置
    private func updateLastSyncDate(force: Bool = false) {
        if !force, let lastSync = lastSyncDate, Date().timeIntervalSince(lastSync) < 60 {
            return
        }
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: Self.lastSyncDateKey)
    }
    
    // MARK: - 同步状态枚举
    
    enum SyncStatus: Equatable {
        case unknown           // 未知状态（初始化中）
        case disabled          // 同步已关闭
        case available         // 已就绪（已登录iCloud，等待首次同步）
        case notSignedIn       // 未登录iCloud
        case syncing           // 同步中
        case syncCompleted     // 同步完成
        case syncFailed        // 同步失败
        
        var displayText: String {
            switch self {
            case .unknown:
                return "检查中..."
            case .disabled:
                return "同步已关闭"
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
            case .disabled:
                return "icloud.slash"
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
            case .unknown, .disabled:
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

// MARK: - 同步时间中文格式化

extension Date {
    /// 中文相对时间描述（用于同步状态卡片副标题）
    var syncRelativeString: String {
        let interval = Date().timeIntervalSince(self)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else if interval < 172800 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "昨天 HH:mm"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日 HH:mm"
            return formatter.string(from: self)
        }
    }
    
    /// 中文完整时间（用于同步时间详情行）
    var syncAbsoluteString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm:ss"
        return formatter.string(from: self)
    }
}
