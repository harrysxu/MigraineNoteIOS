//
//  MedicationLog.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftData
import Foundation

@Model
final class MedicationLog {
    @Attribute(.unique) var id: UUID
    var medication: Medication?
    var dosage: Double // mg
    var timeTaken: Date
    var efficacyRawValue: String
    var efficacyCheckedAt: Date?
    var sideEffects: [String]
    
    init(dosage: Double, timeTaken: Date = Date()) {
        self.id = UUID()
        self.dosage = dosage
        self.timeTaken = timeTaken
        self.efficacyRawValue = MedicationEfficacy.notEvaluated.rawValue
        self.sideEffects = []
    }
    
    // 计算属性
    var efficacy: MedicationEfficacy {
        get { MedicationEfficacy(rawValue: efficacyRawValue) ?? .notEvaluated }
        set { efficacyRawValue = newValue.rawValue }
    }
    
    // 是否需要评估疗效（服药2小时后）
    var needsEfficacyEvaluation: Bool {
        guard efficacy == .notEvaluated else { return false }
        return Date().timeIntervalSince(timeTaken) >= 7200 // 2小时
    }
    
    // 距离疗效评估时间还有多久
    var timeUntilEfficacyCheck: TimeInterval {
        let elapsed = Date().timeIntervalSince(timeTaken)
        return max(0, 7200 - elapsed)
    }
    
    // 便捷属性：兼容旧代码
    var takenAt: Date {
        get { timeTaken }
        set { timeTaken = newValue }
    }
    
    // 便捷属性：兼容旧代码 - effectiveness
    enum Effectiveness: String, CaseIterable {
        case excellent = "完全缓解"
        case good = "明显缓解"
        case moderate = "部分缓解"
        case poor = "轻微缓解"
        case none = "无效"
    }
    
    var effectiveness: Effectiveness? {
        switch efficacy {
        case .notEvaluated:
            return nil
        case .complete:
            return .excellent
        case .partial:
            return .moderate
        case .noEffect:
            return Effectiveness.none
        }
    }
    
    // 便捷属性：剂量字符串
    var dosageString: String {
        return "\(self.dosage)mg"
    }
}

enum MedicationEfficacy: String, Codable, CaseIterable {
    case notEvaluated = "未评估"
    case complete = "完全缓解"
    case partial = "部分缓解"
    case noEffect = "无效"
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .notEvaluated:
            return "questionmark.circle"
        case .complete:
            return "checkmark.circle.fill"
        case .partial:
            return "checkmark.circle"
        case .noEffect:
            return "xmark.circle"
        }
    }
}
