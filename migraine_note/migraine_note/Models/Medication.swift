//
//  Medication.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftData
import Foundation

@Model
final class Medication {
    var id: UUID = UUID()
    var name: String = ""
    var categoryRawValue: String = ""
    var standardDosage: Double = 0
    var unit: String = "mg"
    var isAcute: Bool = false
    var monthlyLimit: Int?
    var inventory: Int = 0
    var notes: String?
    
    // CloudKit 要求关系可选（仅 MedicationLog 侧指定 inverse 避免循环引用）
    @Relationship var logsData: [MedicationLog]?
    var logs: [MedicationLog] {
        get { logsData ?? [] }
        set { logsData = newValue }
    }
    
    init(name: String, category: MedicationCategory, isAcute: Bool) {
        self.id = UUID()
        self.name = name
        self.categoryRawValue = category.rawValue
        self.isAcute = isAcute
        
        if isAcute {
            switch category {
            case .nsaid:
                self.monthlyLimit = 15
            case .triptan, .ergotamine, .opioid:
                self.monthlyLimit = 10
            default:
                self.monthlyLimit = nil
            }
        }
    }
    
    // 计算属性
    var category: MedicationCategory {
        get { MedicationCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}

enum MedicationCategory: String, Codable, CaseIterable {
    case nsaid = "非甾体抗炎药(NSAID)"
    case triptan = "曲普坦类"
    case opioid = "阿片类"
    case ergotamine = "麦角胺类"
    case preventive = "预防性药物"
    case tcmHerbal = "中成药"
    case other = "其他"
    
    var isAcuteMedication: Bool {
        switch self {
        case .nsaid, .triptan, .opioid, .ergotamine:
            return true
        case .preventive:
            return false
        case .tcmHerbal, .other:
            return true // 默认为急性用药
        }
    }
}

// 常用药物预设
struct MedicationPresets {
    static let commonNSAIDs = [
        ("布洛芬", 400.0, "mg"),
        ("对乙酰氨基酚", 500.0, "mg"),
        ("阿司匹林", 300.0, "mg"),
        ("萘普生", 250.0, "mg"),
        ("双氯芬酸", 50.0, "mg"),
        ("吲哚美辛", 25.0, "mg")
    ]
    
    static let commonTriptans = [
        ("佐米曲普坦", 2.5, "mg"),
        ("利扎曲普坦", 10.0, "mg"),
        ("舒马曲普坦", 50.0, "mg"),
        ("依来曲普坦", 40.0, "mg"),
        ("那拉曲普坦", 2.5, "mg")
    ]
    
    static let commonPreventive = [
        ("盐酸氟桂利嗪", 5.0, "mg"),
        ("普萘洛尔", 40.0, "mg"),
        ("阿米替林", 25.0, "mg"),
        ("托吡酯", 50.0, "mg"),
        ("丙戊酸钠", 500.0, "mg")
    ]
    
    static let commonTCM = [
        ("正天丸", 6.0, "g"),
        ("天麻头痛片", 4.0, "片"),
        ("川芎茶调散", 6.0, "g"),
        ("血府逐瘀胶囊", 3.0, "粒"),
        ("养血清脑颗粒", 5.0, "g"),
        ("天麻钩藤颗粒", 10.0, "g")
    ]
    
    static let commonErgotamine = [
        ("麦角胺咖啡因片", 1.0, "片")
    ]
}
