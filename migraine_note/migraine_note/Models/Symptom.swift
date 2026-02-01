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
    @Attribute(.unique) var id: UUID
    var typeRawValue: String
    var severity: Int // 1-5
    var onset: Date
    var notes: String?
    
    init(type: SymptomType, severity: Int = 3) {
        self.id = UUID()
        self.typeRawValue = type.rawValue
        self.severity = severity
        self.onset = Date()
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
        case ihs = "IHS标准"
        case tcm = "中医"
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
    case nausea = "恶心"
    case vomiting = "呕吐"
    case photophobia = "畏光"
    case phonophobia = "畏声"
    case osmophobia = "气味敏感"
    case allodynia = "头皮触痛"
    
    // 中医特有症状
    case bitterTaste = "口苦"
    case facialFlushing = "面红目赤"
    case coldExtremities = "手脚冰凉"
    case heavyHeadedness = "头重如裹"
    case dizziness = "眩晕"
    case palpitation = "心悸"
    
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
