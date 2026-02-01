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
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRawValue: String
    var standardDosage: Double
    var unit: String // "mg", "片"
    var isAcute: Bool // true=急性用药, false=预防性用药
    var monthlyLimit: Int? // MOH阈值（天数）
    var inventory: Int // 库存数量
    var notes: String?
    
    init(name: String, category: MedicationCategory, isAcute: Bool) {
        self.id = UUID()
        self.name = name
        self.categoryRawValue = category.rawValue
        self.standardDosage = 0
        self.unit = "mg"
        self.isAcute = isAcute
        self.inventory = 0
        
        // 根据类别设置默认MOH阈值
        if isAcute {
            switch category {
            case .nsaid:
                self.monthlyLimit = 15 // NSAID ≥15天/月
            case .triptan, .ergotamine, .opioid:
                self.monthlyLimit = 10 // 曲普坦类、麦角胺类、阿片类 ≥10天/月
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
        ("阿司匹林", 500.0, "mg"),
        ("萘普生", 500.0, "mg")
    ]
    
    static let commonTriptans = [
        ("佐米曲普坦", 2.5, "mg"),
        ("利扎曲普坦", 10.0, "mg"),
        ("舒马曲普坦", 50.0, "mg"),
        ("依立曲普坦", 40.0, "mg")
    ]
    
    static let commonPreventive = [
        ("氟桂利嗪", 5.0, "mg"),
        ("普萘洛尔", 40.0, "mg"),
        ("阿米替林", 25.0, "mg"),
        ("托吡酯", 50.0, "mg")
    ]
    
    static let commonTCM = [
        ("正天丸", 6.0, "g"),
        ("川芎茶调散", 6.0, "g"),
        ("天麻钩藤颗粒", 10.0, "g")
    ]
}
