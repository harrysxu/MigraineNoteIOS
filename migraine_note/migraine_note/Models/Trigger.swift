//
//  Trigger.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftData
import Foundation

@Model
final class Trigger {
    var id: UUID = UUID()
    var categoryRawValue: String = ""
    var specificType: String = ""
    var confidence: Double = 1.0
    var notes: String?
    var timestamp: Date = Date()
    
    // 反向关系：指向所属的发作记录
    @Relationship(inverse: \AttackRecord.triggersData) var attackRecord: AttackRecord?
    
    init(category: TriggerCategory, specificType: String) {
        self.categoryRawValue = category.rawValue
        self.specificType = specificType
    }
    
    // 计算属性
    var category: TriggerCategory {
        get { TriggerCategory(rawValue: categoryRawValue) ?? .food }
        set { categoryRawValue = newValue.rawValue }
    }
    
    // 便捷属性：名称（兼容）
    var name: String {
        specificType
    }
}

enum TriggerCategory: String, Codable, CaseIterable {
    case food = "饮食"
    case environment = "环境"
    case sleep = "睡眠"
    case stress = "压力"
    case hormone = "激素"
    case lifestyle = "生活方式"
    case tcm = "中医诱因"
    
    var systemImage: String {
        switch self {
        case .food:
            return "fork.knife"
        case .environment:
            return "cloud.sun"
        case .sleep:
            return "bed.double"
        case .stress:
            return "brain.head.profile"
        case .hormone:
            return "drop.circle"
        case .lifestyle:
            return "figure.walk"
        case .tcm:
            return "leaf"
        }
    }
}

// 预定义诱因库
struct TriggerLibrary {
    static let foodTriggers = [
        "味精(MSG)", "巧克力", "奶酪", "红酒", "咖啡因",
        "老火汤/高汤", "腌制/腊肉", "冰饮/冷食", "辛辣食物", "柑橘类"
    ]
    
    static let environmentTriggers = [
        "闷热/雷雨前", "冷风直吹", "强光", "异味", "高海拔",
        "气压骤降", "高温", "高湿度", "噪音"
    ]
    
    static let sleepTriggers = [
        "睡过头", "失眠/熬夜", "睡眠不足", "睡眠质量差"
    ]
    
    static let stressTriggers = [
        "工作压力", "情绪激动", "焦虑", "周末放松(Let-down)", "生气"
    ]
    
    static let hormoneTriggers = [
        "月经期", "排卵期", "怀孕", "更年期"
    ]
    
    static let lifestyleTriggers = [
        "漏餐", "脱水", "运动过度", "长时间屏幕", "姿势不良"
    ]
    
    static let tcmTriggers = [
        "遇风加重", "阴雨天", "情志不遂", "饮食不节", "劳累过度"
    ]
    
    static func triggers(for category: TriggerCategory) -> [String] {
        switch category {
        case .food:
            return foodTriggers
        case .environment:
            return environmentTriggers
        case .sleep:
            return sleepTriggers
        case .stress:
            return stressTriggers
        case .hormone:
            return hormoneTriggers
        case .lifestyle:
            return lifestyleTriggers
        case .tcm:
            return tcmTriggers
        }
    }
    
    static var allTriggers: [String: TriggerCategory] {
        var result: [String: TriggerCategory] = [:]
        for category in TriggerCategory.allCases {
            for trigger in triggers(for: category) {
                result[trigger] = category
            }
        }
        return result
    }
}
