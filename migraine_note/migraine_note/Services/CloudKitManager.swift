//
//  CloudKitManager.swift
//  migraine_note
//
//  Created on 2026/2/1.
//

import Foundation
import SwiftUI
import CoreData
import CloudKit

/// CloudKit同步状态管理器
@Observable
class CloudKitManager {
    /// 单例实例（避免多个实例重复注册通知观察者）
    static let shared = CloudKitManager()
    
    /// iCloud账号登录状态
    var isICloudAvailable: Bool = false
    
    /// 同步状态
    var syncStatus: SyncStatus = .unknown
    
    /// 最后同步时间
    var lastSyncDate: Date?
    
    /// 错误信息
    var errorMessage: String?
    
    /// 首次同步是否已完成
    var isInitialSyncCompleted: Bool = false
    
    /// 活跃同步事件计数（用于追踪并发的导入/导出事件，仅统计 import/export）
    private var activeSyncEvents: Int = 0
    
    /// 是否已收到至少一次成功的 import 事件（用于判断首次同步是否真正完成）
    private var hasReceivedImportSuccess: Bool = false
    
    /// 状态切换防抖定时器
    private var syncCompletedTimer: Timer?
    
    /// 通知观察者令牌（用于 deinit 清理）
    private var observers: [Any] = []
    
    /// 是否已设置通知监听（防止重复注册）
    private var isObserving = false
    
    /// UserDefaults 存储键
    private static let lastSyncDateKey = "cloudkit_last_sync_date"
    private static let initialSyncCompletedKey = "cloudkit_initial_sync_completed"
    
    private init() {
        // 从 UserDefaults 恢复状态
        lastSyncDate = UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date
        isInitialSyncCompleted = UserDefaults.standard.bool(forKey: Self.initialSyncCompletedKey)
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
    
    /// 设置所有通知监听（仅注册一次，防止重复）
    private func setupNotificationObservers() {
        guard !isObserving else { return }
        isObserving = true
        
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
        
        // 忽略 setup 事件（初始化/配置），仅追踪实际数据同步（import/export）
        // setup 事件只代表 CloudKit 容器就绪，不代表数据已导入，不能用来标记首次同步完成
        if event.type == .setup {
            return
        }
        
        if event.endDate == nil {
            // ── 数据同步事件开始（import 或 export）──
            activeSyncEvents += 1
            syncCompletedTimer?.invalidate()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                syncStatus = .syncing
            }
        } else {
            // ── 数据同步事件结束 ──
            activeSyncEvents = max(0, activeSyncEvents - 1)
            
            // 只要有 import 事件结束（无论成功还是 CKError partial failure），都标记已收到 import。
            // pending relationship 的 CKError 不意味着数据没导入 —— 数据已到达本地，只是部分关系未解析。
            if event.type == .import {
                hasReceivedImportSuccess = true
            }
            
            if event.succeeded {
                // 不在这里更新时间，统一在防抖定时器中更新，避免频繁刷新
                errorMessage = nil
            } else if let error = event.error {
                let nsError = error as NSError
                // 忽略用户取消错误（常见于应用生命周期切换）
                // 忽略 partial failure（部分 pending relationship 未解析，CloudKit 会自动重试）
                if nsError.code != NSUserCancelledError &&
                   nsError.domain != "CKErrorDomain" {
                    errorMessage = error.localizedDescription
                }
            }
            
            // 所有活跃事件结束后，延迟切换到最终状态（防止频繁闪烁）
            if activeSyncEvents == 0 {
                syncCompletedTimer?.invalidate()
                // 使用较长的防抖间隔（2秒），避免 CloudKit 内部重试导致状态频繁切换
                syncCompletedTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        
                        // 所有 import/export 事件沉淀后，如果有成功的 import 且首次同步未标记，
                        // 此时才标记首次同步完成（确保数据已全部到达）
                        if !self.isInitialSyncCompleted && self.hasReceivedImportSuccess {
                            self.markInitialSyncCompleted()
                        }
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if self.errorMessage != nil {
                                self.syncStatus = .syncFailed
                            } else {
                                // 一批同步事件完成后，使用节流方式更新时间
                                self.updateLastSyncDate()
                                self.syncStatus = .syncCompleted
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 标记首次同步已完成
    private func markInitialSyncCompleted() {
        isInitialSyncCompleted = true
        UserDefaults.standard.set(true, forKey: Self.initialSyncCompletedKey)
        // 发送通知，让等待首次同步的组件可以继续工作
        NotificationCenter.default.post(name: .cloudKitInitialSyncCompleted, object: nil)
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
    
    // MARK: - CloudKit Zone 重置
    
    /// 重置 CloudKit 同步数据（删除 CloudKit Zone 中的所有数据，然后重新从本地上传）
    /// 用于修复 pending relationship 死循环等同步异常
    func resetCloudKitZone() async throws {
        guard SyncSettingsManager.isSyncCurrentlyEnabled() else {
            throw CloudKitResetError.syncNotEnabled
        }
        
        guard isICloudAvailable else {
            throw CloudKitResetError.iCloudNotAvailable
        }
        
        // 使用 app 的 bundle identifier 构建 CloudKit container ID
        let bundleId = Bundle.main.bundleIdentifier ?? "com.xxl.migraine-note"
        let container = CKContainer(identifier: "iCloud.\(bundleId)")
        let privateDatabase = container.privateCloudDatabase
        
        // 删除 Core Data 使用的默认 CloudKit Zone
        let zoneID = CKRecordZone.ID(
            zoneName: "com.apple.coredata.cloudkit.zone",
            ownerName: CKCurrentUserDefaultName
        )
        
        do {
            // 删除整个 Zone（包括所有记录和 pending relationships）
            _ = try await privateDatabase.deleteRecordZone(withID: zoneID)
            print("✅ CloudKit Zone 已删除")
            
            // 重置本地同步状态
            await MainActor.run {
                lastSyncDate = nil
                isInitialSyncCompleted = false
                errorMessage = nil
                syncStatus = .available
                UserDefaults.standard.removeObject(forKey: Self.lastSyncDateKey)
                UserDefaults.standard.removeObject(forKey: Self.initialSyncCompletedKey)
            }
            
            print("✅ 本地同步状态已重置。请重启应用以重新开始同步。")
        } catch {
            print("❌ CloudKit Zone 重置失败: \(error)")
            throw CloudKitResetError.resetFailed(error)
        }
    }
    
    enum CloudKitResetError: LocalizedError {
        case syncNotEnabled
        case iCloudNotAvailable
        case resetFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .syncNotEnabled:
                return "iCloud 同步未启用"
            case .iCloudNotAvailable:
                return "iCloud 账号不可用"
            case .resetFailed(let error):
                return "重置失败：\(error.localizedDescription)"
            }
        }
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

// MARK: - 通知名称

extension Notification.Name {
    /// CloudKit 首次同步完成通知（标签等依赖数据可以安全初始化）
    static let cloudKitInitialSyncCompleted = Notification.Name("cloudKitInitialSyncCompleted")
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
