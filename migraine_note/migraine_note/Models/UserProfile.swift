//
//  UserProfile.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftData
import Foundation

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String?
    var age: Int?
    var genderRawValue: String?
    
    // 病史
    var migraineOnsetAge: Int? // 发病年龄
    var familyHistory: Bool // 家族史
    
    // 偏好设置
    var enableTCMFeatures: Bool // 启用中医功能
    var enableHealthKitSync: Bool
    var enableWeatherTracking: Bool
    var preferredPainScaleRawValue: String
    
    // 提醒设置
    var medicationRemindersData: Data? // JSON编码的提醒列表
    var efficacyCheckReminder: Bool
    
    // 隐私设置
    var requireBiometricAuth: Bool
    
    init() {
        self.id = UUID()
        self.familyHistory = false
        self.enableTCMFeatures = true
        self.enableHealthKitSync = true
        self.enableWeatherTracking = true
        self.preferredPainScaleRawValue = PainScale.numeric.rawValue
        self.efficacyCheckReminder = true
        self.requireBiometricAuth = false
    }
    
    // 计算属性
    var gender: Gender? {
        get {
            guard let rawValue = genderRawValue else { return nil }
            return Gender(rawValue: rawValue)
        }
        set {
            genderRawValue = newValue?.rawValue
        }
    }
    
    var preferredPainScale: PainScale {
        get { PainScale(rawValue: preferredPainScaleRawValue) ?? .numeric }
        set { preferredPainScaleRawValue = newValue.rawValue }
    }
    
    var medicationReminders: [MedicationReminder] {
        get {
            guard let data = medicationRemindersData else { return [] }
            return (try? JSONDecoder().decode([MedicationReminder].self, from: data)) ?? []
        }
        set {
            medicationRemindersData = try? JSONEncoder().encode(newValue)
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "男"
    case female = "女"
    case other = "其他"
}

enum PainScale: String, Codable, CaseIterable {
    case numeric = "数字评分(NRS)"
    case visual = "视觉模拟(VAS)"
}

struct MedicationReminder: Codable, Identifiable {
    var id: UUID = UUID()
    var medicationName: String
    var time: Date
    var repeatDaily: Bool
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
}
