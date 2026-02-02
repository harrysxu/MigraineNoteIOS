//
//  LabelManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import Foundation
import SwiftData

/// 标签管理服务
/// 负责初始化默认标签、管理自定义标签、提供标签查询功能
@Observable
class LabelManager {
    static let shared = LabelManager()
    
    private init() {}
    
    // MARK: - 初始化默认标签
    
    /// 检查并初始化默认标签（如果数据库为空）
    func initializeDefaultLabelsIfNeeded(context: ModelContext) {
        // 检查是否已初始化
        let descriptor = FetchDescriptor<CustomLabelConfig>(
            predicate: #Predicate { $0.isDefault == true }
        )
        
        guard let existingLabels = try? context.fetch(descriptor),
              existingLabels.isEmpty else {
            print("默认标签已存在，跳过初始化")
            return
        }
        
        print("开始初始化默认标签...")
        
        // 初始化症状标签
        initializeSymptomLabels(context: context)
        
        // 初始化诱因标签
        initializeTriggerLabels(context: context)
        
        // 初始化药物预设标签
        initializeMedicationLabels(context: context)
        
        // 保存到数据库
        try? context.save()
        
        print("默认标签初始化完成")
    }
    
    // MARK: - 初始化症状标签
    
    private func initializeSymptomLabels(context: ModelContext) {
        var sortOrder = 0
        
        // 西医症状
        let westernSymptoms: [(key: String, name: String)] = [
            ("nausea", "恶心"),
            ("vomiting", "呕吐"),
            ("photophobia", "畏光"),
            ("phonophobia", "畏声"),
            ("osmophobia", "气味敏感"),
            ("allodynia", "头皮触痛")
        ]
        
        for symptom in westernSymptoms {
            let label = CustomLabelConfig(
                category: LabelCategory.symptom.rawValue,
                labelKey: symptom.key,
                displayName: symptom.name,
                isDefault: true,
                subcategory: SymptomSubcategory.western.rawValue,
                sortOrder: sortOrder
            )
            context.insert(label)
            sortOrder += 1
        }
        
        // 中医症状
        let tcmSymptoms: [(key: String, name: String)] = [
            ("bitterTaste", "口苦"),
            ("facialFlushing", "面红目赤"),
            ("coldExtremities", "手脚冰凉"),
            ("heavyHeadedness", "头重如裹"),
            ("dizziness", "眩晕"),
            ("palpitation", "心悸")
        ]
        
        sortOrder = 0
        for symptom in tcmSymptoms {
            let label = CustomLabelConfig(
                category: LabelCategory.symptom.rawValue,
                labelKey: symptom.key,
                displayName: symptom.name,
                isDefault: true,
                subcategory: SymptomSubcategory.tcm.rawValue,
                sortOrder: sortOrder
            )
            context.insert(label)
            sortOrder += 1
        }
    }
    
    // MARK: - 初始化诱因标签
    
    private func initializeTriggerLabels(context: ModelContext) {
        let triggerData: [(category: String, triggers: [String])] = [
            ("饮食", [
                "味精(MSG)", "巧克力", "奶酪", "红酒", "咖啡因",
                "老火汤/高汤", "腌制/腊肉", "冰饮/冷食", "辛辣食物", "柑橘类"
            ]),
            ("环境", [
                "闷热/雷雨前", "冷风直吹", "强光", "异味", "高海拔",
                "气压骤降", "高温", "高湿度", "噪音"
            ]),
            ("睡眠", [
                "睡过头", "失眠/熬夜", "睡眠不足", "睡眠质量差"
            ]),
            ("压力", [
                "工作压力", "情绪激动", "焦虑", "周末放松(Let-down)", "生气"
            ]),
            ("激素", [
                "月经期", "排卵期", "怀孕", "更年期"
            ]),
            ("生活方式", [
                "漏餐", "脱水", "运动过度", "长时间屏幕", "姿势不良"
            ]),
            ("中医诱因", [
                "遇风加重", "阴雨天", "情志不遂", "饮食不节", "劳累过度"
            ])
        ]
        
        for (category, triggers) in triggerData {
            for (index, trigger) in triggers.enumerated() {
                let label = CustomLabelConfig(
                    category: LabelCategory.trigger.rawValue,
                    labelKey: trigger, // 诱因使用显示名称作为 key
                    displayName: trigger,
                    isDefault: true,
                    subcategory: category,
                    sortOrder: index
                )
                context.insert(label)
            }
        }
    }
    
    // MARK: - 初始化药物预设标签
    
    private func initializeMedicationLabels(context: ModelContext) {
        let medicationData: [(category: String, medications: [(name: String, dosage: Double, unit: String)])] = [
            ("非甾体抗炎药(NSAID)", [
                ("布洛芬", 400.0, "mg"),
                ("对乙酰氨基酚", 500.0, "mg"),
                ("阿司匹林", 300.0, "mg"),
                ("萘普生", 250.0, "mg"),
                ("双氯芬酸", 50.0, "mg"),
                ("吲哚美辛", 25.0, "mg")
            ]),
            ("曲普坦类", [
                ("佐米曲普坦", 2.5, "mg"),
                ("利扎曲普坦", 10.0, "mg"),
                ("舒马曲普坦", 50.0, "mg"),
                ("依来曲普坦", 40.0, "mg"),
                ("那拉曲普坦", 2.5, "mg")
            ]),
            ("预防性药物", [
                ("盐酸氟桂利嗪", 5.0, "mg"),
                ("普萘洛尔", 40.0, "mg"),
                ("阿米替林", 25.0, "mg"),
                ("托吡酯", 50.0, "mg"),
                ("丙戊酸钠", 500.0, "mg")
            ]),
            ("中成药", [
                ("正天丸", 6.0, "g"),
                ("天麻头痛片", 4.0, "片"),
                ("川芎茶调散", 6.0, "g"),
                ("血府逐瘀胶囊", 3.0, "粒"),
                ("养血清脑颗粒", 5.0, "g"),
                ("天麻钩藤颗粒", 10.0, "g")
            ]),
            ("麦角胺类", [
                ("麦角胺咖啡因片", 1.0, "片")
            ])
        ]
        
        for (category, medications) in medicationData {
            for (index, med) in medications.enumerated() {
                // 创建一个可编码的结构体来存储药物剂量信息
                struct MedicationMetadata: Codable {
                    let dosage: Double
                    let unit: String
                }
                
                let metadataObj = MedicationMetadata(dosage: med.dosage, unit: med.unit)
                let metadata = try? JSONEncoder().encode(metadataObj)
                
                let label = CustomLabelConfig(
                    category: "medication",  // 直接使用字符串，因为LabelCategory.medication已被移除
                    labelKey: med.name,
                    displayName: med.name,
                    isDefault: true,
                    subcategory: category,
                    sortOrder: index
                )
                label.metadata = metadata.flatMap { String(data: $0, encoding: .utf8) }
                context.insert(label)
            }
        }
    }
    
    // MARK: - 查询标签
    
    /// 获取指定类别的标签列表
    static func fetchLabels(
        category: LabelCategory,
        subcategory: String? = nil,
        includeHidden: Bool = false,
        context: ModelContext
    ) -> [CustomLabelConfig] {
        let categoryString = category.rawValue
        var predicate: Predicate<CustomLabelConfig>
        
        if let subcategory = subcategory {
            if includeHidden {
                predicate = #Predicate<CustomLabelConfig> { label in
                    label.category == categoryString && label.subcategory == subcategory
                }
            } else {
                predicate = #Predicate<CustomLabelConfig> { label in
                    label.category == categoryString && 
                    label.subcategory == subcategory && 
                    label.isHidden == false
                }
            }
        } else {
            if includeHidden {
                predicate = #Predicate<CustomLabelConfig> { label in
                    label.category == categoryString
                }
            } else {
                predicate = #Predicate<CustomLabelConfig> { label in
                    label.category == categoryString && label.isHidden == false
                }
            }
        }
        
        let descriptor = FetchDescriptor<CustomLabelConfig>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.displayName)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - 添加自定义标签
    
    /// 添加自定义标签
    static func addCustomLabel(
        category: LabelCategory,
        displayName: String,
        subcategory: String? = nil,
        context: ModelContext
    ) throws {
        // 检查是否已存在同名标签
        let existingLabels = fetchLabels(category: category, subcategory: subcategory, includeHidden: true, context: context)
        
        if existingLabels.contains(where: { $0.displayName == displayName }) {
            throw LabelError.duplicateName
        }
        
        // 计算新的排序顺序（放在最后）
        let maxSortOrder = existingLabels.map { $0.sortOrder }.max() ?? -1
        
        let newLabel = CustomLabelConfig(
            category: category.rawValue,
            labelKey: displayName, // 自定义标签使用显示名称作为 key
            displayName: displayName,
            isDefault: false,
            subcategory: subcategory,
            sortOrder: maxSortOrder + 1
        )
        
        context.insert(newLabel)
        try context.save()
    }
    
    // MARK: - 切换标签可见性
    
    /// 切换标签的显示/隐藏状态
    static func toggleLabelVisibility(label: CustomLabelConfig, context: ModelContext) throws {
        label.isHidden.toggle()
        label.updatedAt = Date()
        try context.save()
    }
    
    // MARK: - 删除自定义标签
    
    /// 删除自定义标签（仅限非默认标签）
    static func deleteCustomLabel(label: CustomLabelConfig, context: ModelContext) throws {
        guard !label.isDefault else {
            throw LabelError.cannotDeleteDefault
        }
        
        context.delete(label)
        try context.save()
    }
    
    // MARK: - 更新标签排序
    
    /// 更新标签的排序顺序
    static func updateLabelOrder(labels: [CustomLabelConfig], context: ModelContext) throws {
        for (index, label) in labels.enumerated() {
            label.sortOrder = index
            label.updatedAt = Date()
        }
        try context.save()
    }
    
    // MARK: - 重命名标签
    
    /// 重命名自定义标签
    static func renameLabel(label: CustomLabelConfig, newName: String, context: ModelContext) throws {
        guard !label.isDefault else {
            throw LabelError.cannotEditDefault
        }
        
        // 检查新名称是否已存在
        let existingLabels = fetchLabels(
            category: LabelCategory(rawValue: label.category)!,
            subcategory: label.subcategory,
            includeHidden: true,
            context: context
        )
        
        if existingLabels.contains(where: { $0.displayName == newName && $0.id != label.id }) {
            throw LabelError.duplicateName
        }
        
        label.displayName = newName
        label.labelKey = newName
        label.updatedAt = Date()
        try context.save()
    }
}

// MARK: - 错误类型

enum LabelError: LocalizedError {
    case duplicateName
    case cannotDeleteDefault
    case cannotEditDefault
    
    var errorDescription: String? {
        switch self {
        case .duplicateName:
            return "标签名称已存在"
        case .cannotDeleteDefault:
            return "默认标签不能删除，只能隐藏"
        case .cannotEditDefault:
            return "默认标签不能修改"
        }
    }
}
