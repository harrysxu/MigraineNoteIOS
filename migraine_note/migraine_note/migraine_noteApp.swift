//
//  migraine_noteApp.swift
//  migraine_note
//
//  Created by 徐晓龙 on 2026/2/1.
//

import SwiftUI
import SwiftData
import CoreData

@main
struct migraine_noteApp: App {
    @State private var themeManager = ThemeManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AttackRecord.self,
            Symptom.self,
            Trigger.self,
            MedicationLog.self,
            Medication.self,
            WeatherSnapshot.self,
            UserProfile.self,
            CustomLabelConfig.self,
            HealthEvent.self
        ])
        
        // 根据用户设置决定是否启用iCloud同步
        let syncEnabled = SyncSettingsManager.isSyncCurrentlyEnabled()
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: syncEnabled ? .automatic : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 打印详细错误信息以便调试
            print("❌ ModelContainer 创建失败: \(error)")
            print("错误详情: \(error.localizedDescription)")
            
            // 如果是 SwiftData 错误，尝试提供更多上下文
            if let swiftDataError = error as? any Error {
                print("错误类型: \(type(of: swiftDataError))")
            }
            
            fatalError("无法创建 ModelContainer。这通常是由于数据库 schema 更改导致的。\n" +
                      "解决方案：\n" +
                      "1. 在模拟器中删除应用并重新安装\n" +
                      "2. 或在设置 > 应用中清除应用数据\n" +
                      "错误详情: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .environment(themeManager)  // 将主题管理器注入环境
                .applyAppTheme(themeManager.currentTheme)  // 应用主题设置
                .onAppear {
                    initializeDefaultLabelsIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// 标签初始化是否已执行（防止通知回调和超时兜底重复执行）
    @State private var hasInitializedLabels = false
    
    /// 同步完成通知的 observer 引用（用于一次性移除）
    @State private var syncObserver: NSObjectProtocol?
    
    /// 初始化默认标签（CloudKit 同步感知）
    /// 如果 iCloud 同步已启用且首次同步未完成，延迟到同步完成后再初始化，
    /// 避免在 CloudKit 导入期间写入数据造成冲突和重复。
    private func initializeDefaultLabelsIfNeeded() {
        // 防止 onAppear 多次调用导致重复注册
        guard !hasInitializedLabels else { return }
        
        let syncEnabled = SyncSettingsManager.isSyncCurrentlyEnabled()
        let cloudKitManager = CloudKitManager.shared
        
        if syncEnabled && !cloudKitManager.isInitialSyncCompleted {
            // 同步启用但首次同步未完成，等待同步完成后再初始化
            print("⏳ iCloud 同步进行中，延迟初始化默认标签...")
            
            // 注册一次性通知监听，等待首次同步完成（import 事件沉淀后触发）
            syncObserver = NotificationCenter.default.addObserver(
                forName: .cloudKitInitialSyncCompleted,
                object: nil,
                queue: .main
            ) { [self] _ in
                // 互斥：防止通知回调和超时兜底都执行
                guard !hasInitializedLabels else { return }
                hasInitializedLabels = true
                
                // 移除 observer，确保只执行一次
                if let observer = syncObserver {
                    NotificationCenter.default.removeObserver(observer)
                    syncObserver = nil
                }
                
                print("✅ 首次同步完成，延迟 3 秒后执行去重和补充（等待 CloudKit 维护操作结束）")
                // 延迟执行：给 CloudKit PostSaveMaintenance 留出时间，避免争抢主线程和磁盘 I/O
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                    let context = sharedModelContainer.mainContext
                    // 1. 先去重：清理两台设备各自创建的重复标签
                    LabelManager.shared.deduplicateLabelsAfterInitialSync(context: context)
                    // 2. 再补充：仅插入云端和本地都不存在的默认标签
                    LabelManager.shared.initializeDefaultLabelsIfNeeded(context: context)
                }
            }
            
            // 安全兜底：如果 30 秒后同步仍未完成，强制初始化（避免标签永远缺失）
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [self] in
                // 互斥：如果通知回调已执行，跳过
                guard !hasInitializedLabels else { return }
                hasInitializedLabels = true
                
                // 移除 observer，避免后续通知再次触发
                if let observer = syncObserver {
                    NotificationCenter.default.removeObserver(observer)
                    syncObserver = nil
                }
                
                print("⚠️ 首次同步超时（30秒），延迟 3 秒后强制初始化")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                    let context = sharedModelContainer.mainContext
                    // 超时场景也先去重（远端标签可能已部分到达），再补充缺失
                    LabelManager.shared.deduplicateLabelsAfterInitialSync(context: context)
                    LabelManager.shared.initializeDefaultLabelsIfNeeded(context: context)
                }
            }
        } else {
            // 同步未启用或首次同步已完成
            hasInitializedLabels = true
            let context = sharedModelContainer.mainContext
            // 同步已启用时，先去重再补充（幂等操作，无重复时直接跳过）
            if syncEnabled {
                LabelManager.shared.deduplicateLabelsAfterInitialSync(context: context)
            }
            LabelManager.shared.initializeDefaultLabelsIfNeeded(context: context)
        }
    }

}
