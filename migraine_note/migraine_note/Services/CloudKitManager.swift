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

// MARK: - 同步日志条目

/// 同步日志条目（仅记录上传/下载事件）
struct SyncLogEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: SyncEventType
    let succeeded: Bool
    let details: String?       // 变更摘要（如 "新增2条发作记录，更新1条用户配置"）
    let errorMessage: String?
    
    init(type: SyncEventType, succeeded: Bool, details: String? = nil, errorMessage: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.succeeded = succeeded
        self.details = details
        self.errorMessage = errorMessage
    }
    
    enum SyncEventType: String, Codable {
        case upload   // 上传（本地数据导出到 iCloud）
        case download // 下载（远程数据导入到本地）
        
        var displayText: String {
            switch self {
            case .upload:   return "上传"
            case .download: return "下载"
            }
        }
        
        var icon: String {
            switch self {
            case .upload:   return "arrow.up.circle.fill"
            case .download: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .upload:   return .blue
            case .download: return .green
            }
        }
    }
}

// MARK: - 同步变更摘要构建

/// 从 CoreData 上下文保存通知中提取变更摘要
enum SyncChangeSummary {
    
    /// 实体名称 → 中文显示名映射
    private static let entityDisplayNames: [String: String] = [
        "AttackRecord":     "发作记录",
        "Symptom":          "症状",
        "Trigger":          "诱因",
        "Medication":       "药物",
        "MedicationLog":    "用药记录",
        "HealthEvent":      "健康事件",
        "WeatherSnapshot":  "天气快照",
        "UserProfile":      "用户配置",
        "CustomLabelConfig": "自定义标签",
        "PainLocation":     "疼痛位置",
    ]
    
    /// 从通知 userInfo 提取变更摘要字符串
    /// - 注意：必须在发布通知的原始线程上调用（安全访问 NSManagedObject）
    static func buildDetails(from notification: Notification) -> String? {
        let inserts = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
        let updates = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []
        let deletes = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []
        
        let totalCount = inserts.count + updates.count + deletes.count
        if totalCount == 0 {
            return nil
        }
        
        var parts: [String] = []
        
        if !inserts.isEmpty {
            let summary = groupByEntity(inserts)
            if !summary.isEmpty { parts.append("新增 \(summary)") }
        }
        if !updates.isEmpty {
            let summary = groupByEntity(updates)
            if !summary.isEmpty { parts.append("更新 \(summary)") }
        }
        if !deletes.isEmpty {
            let summary = groupByEntity(deletes)
            if !summary.isEmpty { parts.append("删除 \(summary)") }
        }
        
        // 兜底：有变更但 groupByEntity 全部返回空时，统计非 CloudKit 内部实体数量
        if parts.isEmpty {
            let allObjects = Array(inserts) + Array(updates) + Array(deletes)
            let realCount = allObjects.filter { !(($0.entity.name ?? "").hasPrefix("NSCK")) }.count
            return realCount > 0 ? "共 \(realCount)条数据变更" : nil
        }
        
        return parts.joined(separator: "，")
    }
    
    /// 将一组 NSManagedObject 按实体名分组，返回如 "2条发作记录、1条天气快照"
    private static func groupByEntity(_ objects: Set<NSManagedObject>) -> String {
        var knownCounts: [String: Int] = [:]   // 已知业务实体
        var unknownCount: Int = 0               // 未知实体（可能是 SwiftData 命名不同或 CloudKit 内部实体）
        
        for obj in objects {
            let name = obj.entity.name ?? ""
            if let _ = entityDisplayNames[name] {
                knownCounts[name, default: 0] += 1
            } else if !name.hasPrefix("NSCK") {
                // 非 CloudKit 内部元数据表（NSCK* 开头），归入未知业务数据
                unknownCount += 1
            }
            // NSCK* 开头的 CloudKit 内部实体直接忽略
        }
        
        var parts: [String] = knownCounts.map { name, count in
            let displayName = entityDisplayNames[name]!
            return "\(count)条\(displayName)"
        }
        
        // 未知实体统一显示为"数据"
        if unknownCount > 0 {
            parts.append("\(unknownCount)条数据")
        }
        
        return parts.joined(separator: "、")
    }
}

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
    
    /// 同步日志（仅上传/下载事件）
    var syncLogs: [SyncLogEntry] = []
    
    /// 活跃同步事件计数（用于追踪并发的导入/导出事件）
    private var activeSyncEvents: Int = 0
    
    /// 当前批次中待记录的事件（在一批事件全部完成后统一写入日志）
    private var pendingLogEntries: [SyncLogEntry] = []
    
    /// 是否有待上传的本地变更（用于过滤无实际数据的例行 export 事件）
    private var hasPendingLocalChanges = false
    
    /// 待上传的本地变更摘要（在主上下文保存时捕获）
    private var pendingUploadDetails: String?
    
    /// 状态切换防抖定时器
    private var syncCompletedTimer: Timer?
    
    /// 通知观察者令牌（用于 deinit 清理）
    private var observers: [Any] = []
    
    /// 是否已设置通知监听（防止重复注册）
    private var isObserving = false
    
    /// UserDefaults 存储键
    private static let lastSyncDateKey = "cloudkit_last_sync_date"
    private static let syncLogsKey = "cloudkit_sync_logs"
    
    /// 日志最大保留条数
    private static let maxLogCount = 20
    
    private init() {
        // 从 UserDefaults 恢复状态
        lastSyncDate = UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date
        loadSyncLogs()
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
        
        // 4. 监听数据保存（在原始线程上读取对象信息以保证线程安全）
        let saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: nil  // 在发布通知的原始线程上执行，确保安全访问 NSManagedObject
        ) { [weak self] notification in
            self?.handleContextDidSave(notification)
        }
        observers.append(saveObserver)
    }
    
    // MARK: - 同步事件处理
    
    /// 处理 CoreData 上下文保存通知（捕获变更摘要）
    /// 注意：此方法在发布通知的原始线程上执行（queue: nil），确保安全访问 NSManagedObject 实体信息
    private func handleContextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        
        // 在原始线程上读取实体信息（线程安全）
        let details = SyncChangeSummary.buildDetails(from: notification)
        let isMainContext = context.concurrencyType == .mainQueueConcurrencyType
        
        // 回到主线程更新状态和日志
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if isMainContext {
                // 主队列上下文保存 = 用户操作 → 标记为有待上传的本地变更
                // details 可能为 nil（极端情况），但仍设置标记确保上传日志被创建
                self.hasPendingLocalChanges = true
                self.pendingUploadDetails = details
            } else {
                // 后台上下文保存 = CloudKit 导入
                var finalDetails = details
                
                // 降级方案：如果没有详细描述，但有数据变更，显示简单提示
                if finalDetails == nil {
                    let inserts = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
                    let updates = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []
                    let deletes = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []
                    let totalCount = inserts.count + updates.count + deletes.count
                    
                    if totalCount > 0 {
                        finalDetails = "同步成功"
                    } else {
                        return  // 确实没有变更，不创建日志
                    }
                }
                
                self.updateLastSyncDate()
                self.appendLog(SyncLogEntry(type: .download, succeeded: true, details: finalDetails))
            }
        }
    }
    
    /// 处理远程数据变更通知
    /// 注意：下载日志和同步时间已由 handleContextDidSave 在后台上下文保存时处理
    private func handleRemoteStoreChange() {
        guard SyncSettingsManager.isSyncCurrentlyEnabled() else { return }
        
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
            
            // 记录上传（export）事件到待写入队列
            // 只在有本地变更 或 首次同步时记录，避免例行检查产生大量无意义日志
            // import 由 handleRemoteStoreChange 记录以确保只记有实际数据的事件
            if event.type == .export && (hasPendingLocalChanges || lastSyncDate == nil) {
                let errorMsg = event.succeeded ? nil : event.error?.localizedDescription
                var details = pendingUploadDetails
                
                // 降级方案：如果没有详细描述，使用简单的成功提示
                if details == nil && event.succeeded {
                    details = "同步成功"
                }
                
                pendingUploadDetails = nil
                pendingLogEntries.append(SyncLogEntry(type: .upload, succeeded: event.succeeded, details: details, errorMessage: errorMsg))
                hasPendingLocalChanges = false
            }
            // import 失败时也记录（成功的 import 由 handleRemoteStoreChange 记录）
            if event.type == .import && !event.succeeded {
                let errorMsg = event.error?.localizedDescription
                pendingLogEntries.append(SyncLogEntry(type: .download, succeeded: false, errorMessage: errorMsg))
            }
            
            if event.succeeded {
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
                        
                        // 将待写入的上传日志条目批量写入，并在有日志时更新同步时间
                        if !self.pendingLogEntries.isEmpty {
                            self.updateLastSyncDate()
                            for entry in self.pendingLogEntries {
                                self.appendLog(entry)
                            }
                            self.pendingLogEntries.removeAll()
                        }
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if self.errorMessage != nil {
                                self.syncStatus = .syncFailed
                            } else {
                                self.syncStatus = .syncCompleted
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// 更新并持久化最后同步时间（仅在有实际数据同步时调用）
    private func updateLastSyncDate() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: Self.lastSyncDateKey)
    }
    
    // MARK: - 同步日志管理
    
    /// 添加一条日志并持久化
    private func appendLog(_ entry: SyncLogEntry) {
        syncLogs.insert(entry, at: 0) // 最新的在前面
        // 超过上限时截断
        if syncLogs.count > Self.maxLogCount {
            syncLogs = Array(syncLogs.prefix(Self.maxLogCount))
        }
        saveSyncLogs()
    }
    
    /// 清除所有同步日志
    func clearSyncLogs() {
        syncLogs.removeAll()
        saveSyncLogs()
    }
    
    /// 从 UserDefaults 加载日志
    private func loadSyncLogs() {
        guard let data = UserDefaults.standard.data(forKey: Self.syncLogsKey),
              let logs = try? JSONDecoder().decode([SyncLogEntry].self, from: data) else {
            syncLogs = []
            return
        }
        syncLogs = logs
    }
    
    /// 持久化日志到 UserDefaults
    private func saveSyncLogs() {
        if let data = try? JSONEncoder().encode(syncLogs) {
            UserDefaults.standard.set(data, forKey: Self.syncLogsKey)
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
