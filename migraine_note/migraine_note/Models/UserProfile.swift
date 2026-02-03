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
    var id: UUID = UUID()
    var name: String?
    var age: Int?
    var genderRawValue: String?
    
    // 病史
    var migraineOnsetAge: Int?
    var familyHistory: Bool = false
    
    // 偏好设置
    var enableTCMFeatures: Bool = true
    var enableHealthKitSync: Bool = true
    var enableWeatherTracking: Bool = true
    var preferredPainScaleRawValue: String = PainScale.numeric.rawValue
    
    // 隐私设置
    var requireBiometricAuth: Bool = false
    
    init() {}
    
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
