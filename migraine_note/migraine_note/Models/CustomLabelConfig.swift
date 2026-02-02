//
//  CustomLabelConfig.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftData
import Foundation

/// 自定义标签配置模型
/// 用于管理症状、诱因、药物等所有可自定义的标签
@Model
final class CustomLabelConfig {
    var id: UUID = UUID()
    
    /// 标签类别：symptom, trigger, medication
    var category: String = ""
    
    /// 标签键值（对应原有的 enum rawValue 或自定义值）
    var labelKey: String = ""
    
    /// 显示名称
    var displayName: String = ""
    
    /// 是否为默认标签（默认标签不可删除，只能隐藏）
    var isDefault: Bool = false
    
    /// 是否隐藏（隐藏后不在录入界面显示）
    var isHidden: Bool = false
    
    /// 排序顺序（数字越小越靠前）
    var sortOrder: Int = 0
    
    /// 子分类（可选）
    /// - 症状：western（西医）, tcm（中医）
    /// - 诱因：对应 TriggerCategory.rawValue
    /// - 药物：对应 MedicationCategory.rawValue
    var subcategory: String?
    
    /// 创建时间
    var createdAt: Date = Date()
    
    /// 更新时间
    var updatedAt: Date = Date()
    
    /// 额外信息（JSON字符串，用于扩展）
    var metadata: String?
    
    init(
        category: String,
        labelKey: String,
        displayName: String,
        isDefault: Bool = false,
        subcategory: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.category = category
        self.labelKey = labelKey
        self.displayName = displayName
        self.isDefault = isDefault
        self.subcategory = subcategory
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 标签类别枚举

enum LabelCategory: String, CaseIterable {
    case symptom = "symptom"
    case trigger = "trigger"
    
    var displayName: String {
        switch self {
        case .symptom:
            return "症状"
        case .trigger:
            return "诱因"
        }
    }
    
    var icon: String {
        switch self {
        case .symptom:
            return "stethoscope"
        case .trigger:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - 症状子分类

enum SymptomSubcategory: String {
    case western = "western"
    case tcm = "tcm"
    
    var displayName: String {
        switch self {
        case .western:
            return "西医症状"
        case .tcm:
            return "中医症状"
        }
    }
}
