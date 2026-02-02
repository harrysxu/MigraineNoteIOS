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
    var id: UUID = UUID()
    @Relationship(inverse: \Medication.logsData) var medication: Medication?
    var medicationName: String?  // 自定义药物名称（当medication为nil时使用）
    var dosage: Double = 0
    var unit: String?  // 剂量单位（如果medication为nil时使用）
    var timeTaken: Date = Date()
    var efficacyRawValue: String = MedicationEfficacy.notEvaluated.rawValue
    var efficacyCheckedAt: Date?
    var sideEffects: [String] = []
    
    // 反向关系：指向所属的发作记录
    @Relationship(inverse: \AttackRecord.medicationsData) var attackRecord: AttackRecord?
    
    init(dosage: Double, timeTaken: Date = Date()) {
        self.dosage = dosage
        self.timeTaken = timeTaken
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
        let unitStr = unit ?? medication?.unit ?? "mg"
        return "\(self.dosage)\(unitStr)"
    }
    
    // 便捷属性：药物名称
    var displayName: String {
        return medication?.name ?? medicationName ?? "未知药物"
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
