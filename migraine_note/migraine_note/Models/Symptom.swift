//
//  Symptom.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftData
import Foundation

@Model
final class Symptom {
    var id: UUID = UUID()
    var typeRawValue: String = ""
    var severity: Int = 3
    var onset: Date = Date()
    var notes: String?
    
    // 反向关系：指向所属的发作记录
    @Relationship(inverse: \AttackRecord.symptomsData) var attackRecord: AttackRecord?
    
    init(type: SymptomType, severity: Int = 3) {
        self.typeRawValue = type.rawValue
        self.severity = severity
    }
    
    // 计算属性
    var type: SymptomType {
        get { SymptomType(rawValue: typeRawValue) ?? .nausea }
        set { typeRawValue = newValue.rawValue }
    }
    
    // 便捷属性：名称（兼容）
    var name: String {
        type.rawValue
    }
    
    // 便捷属性：分类（兼容）
    enum Category: String {
        case ihs = "ihs"
        case tcm = "tcm"
        
        var localizedName: String {
            String(localized: String.LocalizationValue("symptom.category.\(rawValue)"))
        }
    }
    
    var category: Category {
        type.isWesternMedicine ? .ihs : .tcm
    }
    
    // 便捷属性：描述
    var symptomDescription: String? {
        notes
    }
}

enum SymptomType: String, Codable, CaseIterable {
    // IHS标准症状
    case nausea = "nausea"
    case vomiting = "vomiting"
    case photophobia = "photophobia"
    case phonophobia = "phonophobia"
    case osmophobia = "osmophobia"
    case allodynia = "allodynia"
    
    // 中医特有症状
    case bitterTaste = "bitterTaste"
    case facialFlushing = "facialFlushing"
    case coldExtremities = "coldExtremities"
    case heavyHeadedness = "heavyHeadedness"
    case dizziness = "dizziness"
    case palpitation = "palpitation"
    
    var localizedName: String {
        String(localized: String.LocalizationValue("symptom.type.\(rawValue)"))
    }
    
    var isWesternMedicine: Bool {
        switch self {
        case .nausea, .vomiting, .photophobia, .phonophobia, .osmophobia, .allodynia:
            return true
        default:
            return false
        }
    }
    
    var isTCM: Bool {
        !isWesternMedicine
    }
}
