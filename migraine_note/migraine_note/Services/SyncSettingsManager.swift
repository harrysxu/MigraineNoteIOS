//
//  SyncSettingsManager.swift
//  migraine_note
//
//  Created on 2026/2/5.
//

import Foundation
import SwiftUI

/// iCloud同步设置管理器
/// 管理用户的同步开关偏好，使用UserDefaults持久化存储
@Observable
class SyncSettingsManager {
    /// 同步开关状态（存储在UserDefaults）
    var isSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: SyncSettingsManager.syncEnabledKey)
        }
    }
    
    /// UserDefaults键名
    static let syncEnabledKey = "icloud_sync_enabled"
    
    /// 单例实例
    static let shared = SyncSettingsManager()
    
    init() {
        // 从UserDefaults加载同步设置
        // 注意：默认为false（关闭），首次使用时需要用户主动开启
        self.isSyncEnabled = UserDefaults.standard.bool(forKey: SyncSettingsManager.syncEnabledKey)
    }
    
    /// 切换同步开关
    func toggleSync() {
        isSyncEnabled.toggle()
    }
    
    /// 启用同步
    func enableSync() {
        isSyncEnabled = true
    }
    
    /// 禁用同步
    func disableSync() {
        isSyncEnabled = false
    }
    
    /// 检查同步是否已启用（静态方法，用于App启动时）
    static func isSyncCurrentlyEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: syncEnabledKey)
    }
}
