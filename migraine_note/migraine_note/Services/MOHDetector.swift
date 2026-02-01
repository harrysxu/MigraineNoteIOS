//
//  MOHDetector.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import Foundation
import SwiftData

/// 药物过度使用头痛（MOH）检测器
/// 基于《中国偏头痛诊断与治疗指南2024版》标准
class MOHDetector {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 检测当前月的MOH风险
    func detectCurrentMonthRisk() -> RiskLevel {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startOfMonth && attack.startTime < endOfMonth
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else { return .none }
        
        // 统计各类药物的使用天数
        var nsaidDays: Set<Date> = []
        var triptanDays: Set<Date> = []
        var opioidDays: Set<Date> = []
        
        for attack in attacks {
            let dayStart = calendar.startOfDay(for: attack.startTime)
            
            for medLog in attack.medicationLogs {
                guard let medication = medLog.medication else { continue }
                
                switch medication.category {
                case .nsaid:
                    nsaidDays.insert(dayStart)
                case .triptan, .ergotamine:
                    triptanDays.insert(dayStart)
                case .opioid:
                    opioidDays.insert(dayStart)
                default:
                    break
                }
            }
        }
        
        // 判断风险等级
        if nsaidDays.count >= 15 || triptanDays.count >= 10 || opioidDays.count >= 10 {
            return .high
        } else if nsaidDays.count >= 12 || triptanDays.count >= 8 || opioidDays.count >= 8 {
            return .medium
        } else if nsaidDays.count >= 10 || triptanDays.count >= 6 || opioidDays.count >= 6 {
            return .low
        } else {
            return .none
        }
    }
    
    // MARK: - Static Methods (保留向后兼容)
    
    /// 检测MOH风险等级
    static func checkMOHRisk(for period: DateInterval, attacks: [AttackRecord]) -> MOHRiskLevel {
        // 统计各类药物的使用天数
        var nsaidDays: Set<Date> = []
        var triptanDays: Set<Date> = []
        var opioidDays: Set<Date> = []
        
        let calendar = Calendar.current
        
        for attack in attacks where period.contains(attack.startTime) {
            let dayStart = calendar.startOfDay(for: attack.startTime)
            
            for medLog in attack.medications {
                guard let medication = medLog.medication else { continue }
                
                switch medication.category {
                case .nsaid:
                    nsaidDays.insert(dayStart)
                case .triptan, .ergotamine:
                    triptanDays.insert(dayStart)
                case .opioid:
                    opioidDays.insert(dayStart)
                default:
                    break
                }
            }
        }
        
        // 判断风险等级
        // NSAID ≥15天/月，曲普坦类/麦角胺类/阿片类 ≥10天/月
        if nsaidDays.count >= 15 || triptanDays.count >= 10 || opioidDays.count >= 10 {
            return .high
        } else if nsaidDays.count >= 12 || triptanDays.count >= 8 || opioidDays.count >= 8 {
            return .medium
        } else if nsaidDays.count >= 10 || triptanDays.count >= 6 || opioidDays.count >= 6 {
            return .low
        } else {
            return .none
        }
    }
    
    /// 获取详细的用药统计
    static func getMedicationStatistics(for period: DateInterval, attacks: [AttackRecord]) -> MedicationStatistics {
        var nsaidDays: Set<Date> = []
        var triptanDays: Set<Date> = []
        var opioidDays: Set<Date> = []
        var totalMedicationDays: Set<Date> = []
        
        let calendar = Calendar.current
        
        for attack in attacks where period.contains(attack.startTime) {
            let dayStart = calendar.startOfDay(for: attack.startTime)
            
            if !attack.medications.isEmpty {
                totalMedicationDays.insert(dayStart)
            }
            
            for medLog in attack.medications {
                guard let medication = medLog.medication else { continue }
                
                switch medication.category {
                case .nsaid:
                    nsaidDays.insert(dayStart)
                case .triptan, .ergotamine:
                    triptanDays.insert(dayStart)
                case .opioid:
                    opioidDays.insert(dayStart)
                default:
                    break
                }
            }
        }
        
        return MedicationStatistics(
            nsaidDays: nsaidDays.count,
            triptanDays: triptanDays.count,
            opioidDays: opioidDays.count,
            totalMedicationDays: totalMedicationDays.count
        )
    }
}

// MARK: - 风险等级

enum RiskLevel {
    case none
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .none:
            return "无风险"
        case .low:
            return "低风险"
        case .medium:
            return "中风险"
        case .high:
            return "高风险"
        }
    }
    
    var emoji: String {
        switch self {
        case .none:
            return "✅"
        case .low:
            return "ℹ️"
        case .medium:
            return "⚠️"
        case .high:
            return "🚨"
        }
    }
    
    var recommendation: String {
        switch self {
        case .none:
            return "继续保持良好的用药习惯"
        case .low:
            return "请注意记录每次用药，避免超过安全阈值"
        case .medium:
            return "建议咨询神经内科医生，评估是否需要预防性治疗"
        case .high:
            return "强烈建议立即就医，可能需要进行药物脱瘾治疗"
        }
    }
}

enum MOHRiskLevel {
    case none
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .none:
            return "用药频率正常"
        case .low:
            return "注意控制用药频率"
        case .medium:
            return "用药过于频繁，建议咨询医生"
        case .high:
            return "高风险！可能存在药物过度使用性头痛"
        }
    }
    
    var color: String {
        switch self {
        case .none:
            return "statusSuccess"
        case .low:
            return "statusInfo"
        case .medium:
            return "statusWarning"
        case .high:
            return "statusDanger"
        }
    }
    
    var recommendation: String {
        switch self {
        case .none:
            return "继续保持良好的用药习惯"
        case .low:
            return "请注意记录每次用药，避免超过安全阈值"
        case .medium:
            return "建议咨询神经内科医生，评估是否需要预防性治疗"
        case .high:
            return "强烈建议立即就医，可能需要进行药物脱瘾治疗"
        }
    }
}

// MARK: - 用药统计

struct MedicationStatistics {
    let nsaidDays: Int          // NSAID使用天数
    let triptanDays: Int        // 曲普坦类使用天数
    let opioidDays: Int         // 阿片类使用天数
    let totalMedicationDays: Int // 总用药天数
    
    var nsaidRisk: Bool {
        nsaidDays >= 15
    }
    
    var triptanRisk: Bool {
        triptanDays >= 10
    }
    
    var opioidRisk: Bool {
        opioidDays >= 10
    }
    
    var hasAnyRisk: Bool {
        nsaidRisk || triptanRisk || opioidRisk
    }
    
    func thresholdProgress(for category: MedicationCategory) -> Double {
        switch category {
        case .nsaid:
            return min(Double(nsaidDays) / 15.0, 1.0)
        case .triptan, .ergotamine:
            return min(Double(triptanDays) / 10.0, 1.0)
        case .opioid:
            return min(Double(opioidDays) / 10.0, 1.0)
        default:
            return 0.0
        }
    }
}
