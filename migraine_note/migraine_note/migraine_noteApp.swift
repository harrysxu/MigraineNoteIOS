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
            UserProfile.self
        ])
        
        // 配置CloudKit自动同步
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // ✅ 启用iCloud + CloudKit同步
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
