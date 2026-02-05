//
//  HealthEvent.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/5.
//  健康事件记录模型 - 用于记录日常用药、中医治疗、手术等关键事件
//

import SwiftData
import Foundation

@Model
final class HealthEvent {
    // 主键
    var id: UUID = UUID()
    
    // 基础信息
    var eventDate: Date = Date()
    var eventTypeRawValue: String = HealthEventType.medication.rawValue
    var notes: String?
    
    // 元数据
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // 用药事件专属字段
    @Relationship(deleteRule: .cascade) var medicationLogs: [MedicationLog] = []
    
    // 中医治疗事件专属字段
    var tcmTreatmentType: String? // 针灸、按摩、拔罐、刮痧、艾灸等
    var tcmDuration: TimeInterval? // 治疗持续时间（分钟）
    
    // 手术事件专属字段
    var surgeryName: String?
    var hospitalName: String?
    var doctorName: String?
    
    init(eventType: HealthEventType, eventDate: Date = Date()) {
        self.id = UUID()
        self.eventDate = eventDate
        self.eventTypeRawValue = eventType.rawValue
    }
    
    // 计算属性
    var eventType: HealthEventType {
        get { HealthEventType(rawValue: eventTypeRawValue) ?? .medication }
        set { eventTypeRawValue = newValue.rawValue }
    }
    
    // 保持向后兼容的计算属性
    var medicationLog: MedicationLog? {
        get { medicationLogs.first }
        set {
            if let newValue = newValue {
                medicationLogs = [newValue]
            } else {
                medicationLogs = []
            }
        }
    }
    
    // 事件显示名称
    var displayTitle: String {
        switch eventType {
        case .medication:
            if medicationLogs.isEmpty {
                return "用药记录"
            } else if medicationLogs.count == 1 {
                return medicationLogs[0].displayName
            } else {
                return "\(medicationLogs[0].displayName) 等\(medicationLogs.count)种"
            }
        case .tcmTreatment:
            return tcmTreatmentType ?? "中医治疗"
        case .surgery:
            return surgeryName ?? "手术记录"
        }
    }
    
    // 事件详细信息
    var displayDetail: String? {
        switch eventType {
        case .medication:
            if medicationLogs.isEmpty {
                return nil
            } else if medicationLogs.count == 1 {
                return medicationLogs[0].dosageString
            } else {
                return "共\(medicationLogs.count)种药物"
            }
        case .tcmTreatment:
            if let duration = tcmDuration, duration > 0 {
                let minutes = Int(duration / 60)
                return "\(minutes)分钟"
            }
            return nil
        case .surgery:
            var details: [String] = []
            if let hospital = hospitalName {
                details.append(hospital)
            }
            if let doctor = doctorName {
                details.append(doctor)
            }
            return details.isEmpty ? nil : details.joined(separator: " · ")
        }
    }
}

// 健康事件类型枚举
enum HealthEventType: String, Codable, CaseIterable {
    case medication = "用药"
    case tcmTreatment = "中医治疗"
    case surgery = "手术"
    
    var icon: String {
        switch self {
        case .medication:
            return "pills.circle.fill"
        case .tcmTreatment:
            return "leaf.circle.fill"
        case .surgery:
            return "cross.case.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .medication:
            return "accentPrimary"
        case .tcmTreatment:
            return "statusSuccess"
        case .surgery:
            return "statusInfo"
        }
    }
}

// 中医治疗类型预设
enum TCMTreatmentType: String, CaseIterable {
    case acupuncture = "针灸"
    case massage = "推拿按摩"
    case cupping = "拔罐"
    case guasha = "刮痧"
    case moxibustion = "艾灸"
    case herbalMedicine = "中药汤剂"
    case other = "其他"
}
