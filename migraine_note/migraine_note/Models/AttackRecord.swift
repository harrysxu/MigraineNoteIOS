//
//  AttackRecord.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftData
import Foundation

@Model
final class AttackRecord {
    // 主键
    @Attribute(.unique) var id: UUID
    
    // 时间信息
    var startTime: Date
    var endTime: Date?
    
    // 疼痛评估
    var painIntensity: Int // 0-10 VAS评分
    var painLocation: [String] // ["left_temple", "right_temple", "forehead"]
    var painQuality: [String] // 疼痛性质的原始值
    
    // 先兆
    var hasAura: Bool
    var auraTypes: [String] // 先兆类型的原始值
    var auraDuration: TimeInterval? // 分钟
    
    // 关系
    @Relationship(deleteRule: .cascade) var symptoms: [Symptom]
    @Relationship(deleteRule: .cascade) var triggers: [Trigger]
    @Relationship(deleteRule: .cascade) var medications: [MedicationLog]
    @Relationship(deleteRule: .cascade) var weatherSnapshot: WeatherSnapshot?
    
    // 生理数据（来自HealthKit）
    var menstrualDay: Int? // 月经周期第几天
    var sleepHours: Double? // 前一晚睡眠时长
    var averageHeartRate: Double? // 发作时平均心率
    
    // 元数据
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    // 中医相关
    var tcmPattern: [String] // 中医证候的原始值
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
        self.painIntensity = 0
        self.painLocation = []
        self.painQuality = []
        self.hasAura = false
        self.auraTypes = []
        self.symptoms = []
        self.triggers = []
        self.medications = []
        self.tcmPattern = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 计算属性
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isOngoing: Bool {
        return endTime == nil
    }
    
    // 便捷方法：获取疼痛性质枚举
    var painQualityTypes: [PainQuality] {
        painQuality.compactMap { PainQuality(rawValue: $0) }
    }
    
    // 便捷方法：设置疼痛性质
    func setPainQuality(_ qualities: [PainQuality]) {
        self.painQuality = qualities.map { $0.rawValue }
    }
    
    // 便捷方法：获取先兆类型枚举
    var auraTypesList: [AuraType] {
        auraTypes.compactMap { AuraType(rawValue: $0) }
    }
    
    // 便捷方法：设置先兆类型
    func setAuraTypes(_ types: [AuraType]) {
        self.auraTypes = types.map { $0.rawValue }
    }
    
    // 便捷方法：获取中医证候枚举
    var tcmPatternTypes: [TCMPattern] {
        tcmPattern.compactMap { TCMPattern(rawValue: $0) }
    }
    
    // 便捷方法：设置中医证候
    func setTCMPattern(_ patterns: [TCMPattern]) {
        self.tcmPattern = patterns.map { $0.rawValue }
    }
    
    // 便捷方法：获取疼痛部位枚举
    var painLocations: [PainLocation] {
        painLocation.compactMap { PainLocation(rawValue: $0) }
    }
    
    // 便捷方法：设置疼痛部位
    func setPainLocations(_ locations: [PainLocation]) {
        self.painLocation = locations.map { $0.rawValue }
    }
    
    // 便捷属性：用药记录（兼容旧代码）
    var medicationLogs: [MedicationLog] {
        medications
    }
    
    // 便捷属性：疼痛性质（兼容旧代码）
    var painQualities: [PainQuality] {
        painQualityTypes
    }
    
    // 便捷属性：非药物干预
    var nonPharmInterventions: [NonPharmIntervention] {
        // TODO: 添加到数据模型中
        []
    }
    
    // 便捷计算属性：持续时间（返回非可选值，进行中的返回至今的时长）
    var durationOrElapsed: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
}

// 枚举类型
enum PainQuality: String, Codable, CaseIterable {
    case pulsating = "搏动性"
    case pressing = "压迫感"
    case stabbing = "刺痛"
    case dull = "钝痛"
    case distending = "胀痛" // 中医
}

enum AuraType: String, Codable, CaseIterable {
    case visualFlashes = "视觉闪光"
    case visualScotoma = "视野暗点"
    case sensoryNumbness = "肢体麻木"
    case speechDifficulty = "言语障碍"
}

enum TCMPattern: String, Codable, CaseIterable {
    case windCold = "风寒侵袭"
    case dampness = "湿邪困阻"
    case liverQiStagnation = "肝气郁结"
    case liverFire = "肝火上炎"
    case qiBloodDeficiency = "气血亏虚"
    case dampHeat = "湿热内蕴"
}

enum NonPharmIntervention: String, Codable, CaseIterable {
    case rest = "休息"
    case sleep = "睡眠"
    case darkRoom = "黑暗安静环境"
    case coldCompress = "冷敷"
    case hotCompress = "热敷"
    case massage = "按摩"
    case meditation = "冥想"
    case deepBreathing = "深呼吸"
    case acupuncture = "针灸"
    case yoga = "瑜伽"
}
