//
//  migraine_noteApp.swift
//  migraine_note
//
//  Created by 徐晓龙 on 2026/2/1.
//

import SwiftUI
import SwiftData

@main
struct migraine_noteApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AttackRecord.self,
            Symptom.self,
            Trigger.self,
            MedicationLog.self,
            Medication.self,
            WeatherSnapshot.self,
            UserProfile.self,
            CustomLabelConfig.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
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
                .onAppear {
                    // 初始化默认标签
                    LabelManager.shared.initializeDefaultLabelsIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
