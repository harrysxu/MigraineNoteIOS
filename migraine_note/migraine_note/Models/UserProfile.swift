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
    
    // 基本信息
    var birthDate: Date?
    var bloodTypeRawValue: String?
    
    // 身体信息
    var height: Double?  // cm
    var weight: Double?  // kg
    
    // 病史
    var migraineOnsetAge: Int?
    var migraineTypeRawValue: String?
    var familyHistory: Bool = false
    
    // 其他医疗信息
    var allergies: String?
    var medicalNotes: String?
    
    // 偏好设置
    var enableTCMFeatures: Bool = true
    var enableWeatherTracking: Bool = true
    var preferredPainScaleRawValue: String = PainScale.numeric.rawValue
    
    // 隐私设置
    var requireBiometricAuth: Bool = false
    
    init() {}
    
    // MARK: - 计算属性
    
    var gender: Gender? {
        get {
            guard let rawValue = genderRawValue else { return nil }
            return Gender(rawValue: rawValue)
        }
        set {
            genderRawValue = newValue?.rawValue
        }
    }
    
    var bloodType: BloodType? {
        get {
            guard let rawValue = bloodTypeRawValue else { return nil }
            return BloodType(rawValue: rawValue)
        }
        set {
            bloodTypeRawValue = newValue?.rawValue
        }
    }
    
    var migraineType: MigraineType? {
        get {
            guard let rawValue = migraineTypeRawValue else { return nil }
            return MigraineType(rawValue: rawValue)
        }
        set {
            migraineTypeRawValue = newValue?.rawValue
        }
    }
    
    /// 根据出生日期自动计算年龄（优先于手动填写的 age）
    var calculatedAge: Int? {
        if let birthDate = birthDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year], from: birthDate, to: Date())
            return components.year
        }
        return age
    }
    
    /// 根据身高体重计算 BMI
    var bmi: Double? {
        guard let h = height, let w = weight, h > 0 else { return nil }
        let heightInMeters = h / 100.0
        return w / (heightInMeters * heightInMeters)
    }
    
    /// BMI 描述
    var bmiDescription: String? {
        guard let bmi = bmi else { return nil }
        switch bmi {
        case ..<18.5: return String(localized: "profile.bmi.underweight")
        case 18.5..<24.0: return String(localized: "profile.bmi.normal")
        case 24.0..<28.0: return String(localized: "profile.bmi.overweight")
        default: return String(localized: "profile.bmi.obese")
        }
    }
    
    var preferredPainScale: PainScale {
        get { PainScale(rawValue: preferredPainScaleRawValue) ?? .numeric }
        set { preferredPainScaleRawValue = newValue.rawValue }
    }
    
    /// 档案完整度（已填写字段数 / 总可填写字段数）
    var completionPercentage: Double {
        let fields: [Any?] = [name, birthDate ?? age.map({ $0 as Any }), genderRawValue, bloodTypeRawValue, height, weight, migraineOnsetAge, migraineTypeRawValue, allergies, medicalNotes]
        let filledCount = fields.compactMap({ $0 }).count
        // familyHistory 是 Bool 默认值，不算未填写
        return Double(filledCount) / Double(fields.count)
    }
}

// MARK: - 枚举定义

enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var localizedName: String {
        String(localized: String.LocalizationValue("gender.\(rawValue)"))
    }
}

enum BloodType: String, Codable, CaseIterable {
    case a = "a"
    case b = "b"
    case ab = "ab"
    case o = "o"
    
    var localizedName: String {
        String(localized: String.LocalizationValue("blood.type.\(rawValue)"))
    }
}

enum MigraineType: String, Codable, CaseIterable {
    case withoutAura = "withoutAura"
    case withAura = "withAura"
    case chronic = "chronic"
    case menstrual = "menstrual"
    case other = "other"
    
    var localizedName: String {
        String(localized: String.LocalizationValue("migraine.type.\(rawValue)"))
    }
}

enum PainScale: String, Codable, CaseIterable {
    case numeric = "numeric"
    case visual = "visual"
    
    var localizedName: String {
        String(localized: String.LocalizationValue("pain.scale.\(rawValue)"))
    }
}
