//
//  MedicationStatistics.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/6.
//  统一的用药和治疗统计数据结构
//

import Foundation

/// 详细的用药和治疗统计数据
struct DetailedMedicationStatistics {
    let acuteMedicationDays: Int       // 急性用药天数（仅发作期间）
    let acuteMedicationCount: Int      // 急性用药次数（仅发作期间）
    let preventiveMedicationDays: Int  // 预防性用药天数（健康事件中）
    let preventiveMedicationCount: Int // 预防性用药次数（健康事件中）
    let tcmTreatmentCount: Int         // 中医治疗次数
    let surgeryCount: Int              // 手术次数
    
    // 便捷属性：判断是否有数据
    var hasAcuteMedication: Bool { acuteMedicationCount > 0 }
    var hasPreventiveMedication: Bool { preventiveMedicationCount > 0 }
    var hasTCMTreatment: Bool { tcmTreatmentCount > 0 }
    var hasSurgery: Bool { surgeryCount > 0 }
    
    // 总计（用于向后兼容）
    var totalMedicationDays: Int {
        // 注意：需要去重，因为同一天可能既有急性用药又有预防性用药
        // 但在当前实现中，急性用药和预防性用药来自不同数据源（发作记录 vs 健康事件）
        // 理论上不会重复，所以可以直接相加
        acuteMedicationDays + preventiveMedicationDays
    }
    
    var totalMedicationCount: Int {
        acuteMedicationCount + preventiveMedicationCount
    }
}

// MARK: - 统一的统计计算方法

extension DetailedMedicationStatistics {
    /// 统一的统计计算方法
    /// - Parameters:
    ///   - attacks: 发作记录数组
    ///   - healthEvents: 健康事件数组
    ///   - dateRange: 统计的日期范围（start 和 end）
    /// - Returns: 详细的用药和治疗统计数据
    static func calculate(
        attacks: [AttackRecord],
        healthEvents: [HealthEvent],
        dateRange: (start: Date, end: Date)
    ) -> DetailedMedicationStatistics {
        let calendar = Calendar.current
        let (start, end) = dateRange
        
        // 1. 统计急性用药（仅来自发作记录）
        let acuteMedicationDaysSet = Set(
            attacks
                .filter { !$0.medicationLogs.isEmpty }
                .map { calendar.startOfDay(for: $0.startTime) }
        )
        let acuteMedicationDays = acuteMedicationDaysSet.count
        
        let acuteMedicationCount = attacks.reduce(0) { total, attack in
            total + attack.medicationLogs.count
        }
        
        // 2. 统计预防性用药（来自健康事件，eventType == .medication）
        let preventiveMedications = healthEvents.filter { $0.eventType == .medication }
        
        let preventiveMedicationDaysSet = Set(
            preventiveMedications
                .filter { !$0.medicationLogs.isEmpty }
                .map { calendar.startOfDay(for: $0.eventDate) }
        )
        let preventiveMedicationDays = preventiveMedicationDaysSet.count
        
        let preventiveMedicationCount = preventiveMedications.reduce(0) { total, event in
            total + event.medicationLogs.count
        }
        
        // 3. 统计中医治疗次数
        let tcmTreatmentCount = healthEvents.filter { $0.eventType == .tcmTreatment }.count
        
        // 4. 统计手术次数
        let surgeryCount = healthEvents.filter { $0.eventType == .surgery }.count
        
        return DetailedMedicationStatistics(
            acuteMedicationDays: acuteMedicationDays,
            acuteMedicationCount: acuteMedicationCount,
            preventiveMedicationDays: preventiveMedicationDays,
            preventiveMedicationCount: preventiveMedicationCount,
            tcmTreatmentCount: tcmTreatmentCount,
            surgeryCount: surgeryCount
        )
    }
    
    /// 空统计（无数据时使用）
    static var empty: DetailedMedicationStatistics {
        DetailedMedicationStatistics(
            acuteMedicationDays: 0,
            acuteMedicationCount: 0,
            preventiveMedicationDays: 0,
            preventiveMedicationCount: 0,
            tcmTreatmentCount: 0,
            surgeryCount: 0
        )
    }
}
