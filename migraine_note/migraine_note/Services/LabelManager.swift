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
///
/// 同步策略：
/// - 记录（AttackRecord）与标签（CustomLabelConfig）之间没有外键关系，记录只存储 displayName 字符串
/// - CustomLabelConfig 纯粹是 UI 选项目录，覆盖/去重不影响任何已有记录
/// - iCloud 同步采用"云端覆盖本地"策略：去重后仅补充缺失的默认标签
@Observable
class LabelManager {
    static let shared = LabelManager()
    
    private init() {}
    
    // MARK: - 默认标签定义（纯数据）
    
    /// 检查并初始化默认标签
    /// 逐条检查每个标签是否已存在（基于 category + labelKey + subcategory），
    /// 只插入尚不存在的标签，避免 iCloud 同步时多设备重复创建
    func initializeDefaultLabelsIfNeeded(context: ModelContext) {
        // 一次性获取所有已存在的标签，构建查重集合
        let existingKeys = fetchAllLabelKeys(context: context)
        var insertedCount = 0
        
        insertedCount += initializeSymptomLabels(context: context, existingKeys: existingKeys)
        insertedCount += initializeTriggerLabels(context: context, existingKeys: existingKeys)
        insertedCount += initializeMedicationLabels(context: context, existingKeys: existingKeys)
        insertedCount += initializePainQualityLabels(context: context, existingKeys: existingKeys)
        insertedCount += initializeInterventionLabels(context: context, existingKeys: existingKeys)
        insertedCount += initializeAuraLabels(context: context, existingKeys: existingKeys)
        
        if insertedCount > 0 {
            try? context.save()
            print("默认标签初始化完成，新增 \(insertedCount) 条标签")
        } else {
            print("所有默认标签已存在，跳过初始化")
        }
    }
    
    /// 一次性获取所有已存在标签的 (category, labelKey, subcategory) 集合
    private func fetchAllLabelKeys(context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<CustomLabelConfig>()
        guard let allLabels = try? context.fetch(descriptor) else {
            return []
        }
        var keys = Set<String>()
        for label in allLabels {
            keys.insert(Self.labelGroupKey(category: label.category, labelKey: label.labelKey, subcategory: label.subcategory))
        }
        return keys
    }
    
    /// 生成标签的分组唯一键，用于查重
    static func labelGroupKey(category: String, labelKey: String, subcategory: String?) -> String {
        return "\(category)|\(labelKey)|\(subcategory ?? "")"
    }
    
    /// 仅在标签不存在时插入，返回是否成功插入
    private func insertIfNotExists(
        context: ModelContext,
        existingKeys: Set<String>,
        category: String,
        labelKey: String,
        displayName: String,
        isDefault: Bool = true,
        subcategory: String?,
        sortOrder: Int,
        metadata: String? = nil
    ) -> Bool {
        let key = Self.labelGroupKey(category: category, labelKey: labelKey, subcategory: subcategory)
        guard !existingKeys.contains(key) else {
            return false
        }
        
        let label = CustomLabelConfig(
            category: category,
            labelKey: labelKey,
            displayName: displayName,
            isDefault: isDefault,
            subcategory: subcategory,
            sortOrder: sortOrder
        )
        label.metadata = metadata
        context.insert(label)
        return true
    }
    
    // MARK: - 初始化症状标签
    
    private func initializeSymptomLabels(context: ModelContext, existingKeys: Set<String>) -> Int {
        var insertedCount = 0
        var sortOrder = 0
        
        // ── 症状：西医 ──
        let westernSymptoms: [(key: String, name: String)] = [
            ("nausea", "恶心"), ("vomiting", "呕吐"), ("photophobia", "畏光"),
            ("phonophobia", "畏声"), ("osmophobia", "气味敏感"), ("allodynia", "头皮触痛"),
            ("neckStiffness", "颈部僵硬"), ("fatigue", "疲乏"), ("blurredVision", "视物模糊"),
            ("pallor", "面色苍白"), ("nasalCongestion", "鼻塞/流涕")
        ]
        
        for symptom in westernSymptoms {
            if insertIfNotExists(
                context: context, existingKeys: existingKeys,
                category: LabelCategory.symptom.rawValue,
                labelKey: symptom.key, displayName: symptom.name,
                subcategory: SymptomSubcategory.western.rawValue,
                sortOrder: sortOrder
            ) {
                insertedCount += 1
            }
            sortOrder += 1
        }
        
        // ── 症状：中医 ──
        let tcmSymptoms: [(key: String, name: String)] = [
            ("bitterTaste", "口苦"), ("facialFlushing", "面红目赤"), ("coldExtremities", "手脚冰凉"),
            ("heavyHeadedness", "头重如裹"), ("dizziness", "眩晕"), ("palpitation", "心悸"),
            ("greasyTongue", "舌苔厚腻"), ("hypochondriacPain", "胁痛"), ("constipation", "大便干结")
        ]
        
        sortOrder = 0
        for symptom in tcmSymptoms {
            if insertIfNotExists(
                context: context, existingKeys: existingKeys,
                category: LabelCategory.symptom.rawValue,
                labelKey: symptom.key, displayName: symptom.name,
                subcategory: SymptomSubcategory.tcm.rawValue,
                sortOrder: sortOrder
            ) {
                insertedCount += 1
            }
            sortOrder += 1
        }
        
        return insertedCount
    }
    
    // MARK: - 初始化诱因标签
    
    private func initializeTriggerLabels(context: ModelContext, existingKeys: Set<String>) -> Int {
        var insertedCount = 0
        let triggerData: [(category: String, triggers: [String])] = [
            ("饮食", [
                "味精(MSG)", "巧克力", "奶酪", "红酒", "咖啡因",
                "老火汤/高汤", "腌制/腊肉", "冰饮/冷食", "辛辣食物", "柑橘类",
                "人工甜味剂", "酒精(啤酒/白酒)"
            ]),
            ("环境", [
                "闷热/雷雨前", "冷风直吹", "强光", "异味", "高海拔",
                "气压骤降", "高温", "高湿度", "噪音",
                "闪烁灯光", "香水/化学品气味"
            ]),
            ("睡眠", ["睡过头", "失眠/熬夜", "睡眠不足", "睡眠质量差"]),
            ("压力", ["工作压力", "情绪激动", "焦虑", "周末放松(Let-down)", "生气"]),
            ("激素", ["月经期", "排卵期", "怀孕", "更年期"]),
            ("生活方式", ["漏餐", "脱水", "运动过度", "长时间屏幕", "姿势不良", "旅行/时差"]),
            ("中医诱因", ["遇风加重", "阴雨天", "情志不遂", "饮食不节", "劳累过度"])
        ]
        
        for (category, triggers) in triggerData {
            for (index, trigger) in triggers.enumerated() {
                if insertIfNotExists(
                    context: context, existingKeys: existingKeys,
                    category: LabelCategory.trigger.rawValue,
                    labelKey: trigger, displayName: trigger,
                    subcategory: category,
                    sortOrder: index
                ) {
                    insertedCount += 1
                }
            }
        }
        
        return insertedCount
    }
    
    // MARK: - 初始化药物预设标签
    
    private func initializeMedicationLabels(context: ModelContext, existingKeys: Set<String>) -> Int {
        var insertedCount = 0
        let medicationData: [(category: String, medications: [(name: String, dosage: Double, unit: String)])] = [
            ("非甾体抗炎药(NSAID)", [
                ("布洛芬", 400.0, "mg"), ("对乙酰氨基酚", 500.0, "mg"),
                ("阿司匹林", 300.0, "mg"), ("萘普生", 250.0, "mg"),
                ("双氯芬酸", 50.0, "mg"), ("吲哚美辛", 25.0, "mg")
            ]),
            ("曲普坦类", [
                ("佐米曲普坦", 2.5, "mg"), ("利扎曲普坦", 10.0, "mg"),
                ("舒马曲普坦", 50.0, "mg"), ("依来曲普坦", 40.0, "mg"),
                ("那拉曲普坦", 2.5, "mg")
            ]),
            ("预防性药物", [
                ("盐酸氟桂利嗪", 5.0, "mg"), ("普萘洛尔", 40.0, "mg"),
                ("阿米替林", 25.0, "mg"), ("托吡酯", 50.0, "mg"),
                ("丙戊酸钠", 500.0, "mg")
            ]),
            ("中成药", [
                ("正天丸", 6.0, "g"), ("天麻头痛片", 4.0, "片"),
                ("川芎茶调散", 6.0, "g"), ("血府逐瘀胶囊", 3.0, "粒"),
                ("养血清脑颗粒", 5.0, "g"), ("天麻钩藤颗粒", 10.0, "g")
            ]),
            ("麦角胺类", [("麦角胺咖啡因片", 1.0, "片")])
        ]
        
        for (category, medications) in medicationData {
            for (index, med) in medications.enumerated() {
                // 创建一个可编码的结构体来存储药物剂量信息
                struct MedicationMetadata: Codable {
                    let dosage: Double
                    let unit: String
                }
                
                let metadataObj = MedicationMetadata(dosage: med.dosage, unit: med.unit)
                let metadataData = try? JSONEncoder().encode(metadataObj)
                let metadataString = metadataData.flatMap { String(data: $0, encoding: .utf8) }
                
                if insertIfNotExists(
                    context: context, existingKeys: existingKeys,
                    category: "medication",
                    labelKey: med.name, displayName: med.name,
                    subcategory: category,
                    sortOrder: index,
                    metadata: metadataString
                ) {
                    insertedCount += 1
                }
            }
        }
        
        return insertedCount
    }
    
    // MARK: - 初始化疼痛性质标签
    
    private func initializePainQualityLabels(context: ModelContext, existingKeys: Set<String>) -> Int {
        var insertedCount = 0
        let painQualities: [(key: String, name: String)] = [
            ("pulsating", "搏动性"),
            ("pressing", "压迫感"),
            ("stabbing", "刺痛"),
            ("dull", "钝痛"),
            ("distending", "胀痛"),
            ("tightening", "紧缩感"),
            ("burning", "灼烧感"),
            ("tearing", "撕裂样")
        ]
        
        for (index, quality) in painQualities.enumerated() {
            if insertIfNotExists(
                context: context, existingKeys: existingKeys,
                category: LabelCategory.painQuality.rawValue,
                labelKey: quality.key, displayName: quality.name,
                subcategory: nil,
                sortOrder: index
            ) {
                insertedCount += 1
            }
        }
        
        return insertedCount
    }
    
    // MARK: - 初始化非药物干预标签
    
    private func initializeInterventionLabels(context: ModelContext, existingKeys: Set<String>) -> Int {
        var insertedCount = 0
        let interventions: [(key: String, name: String)] = [
            ("sleep", "睡眠"),
            ("coldCompress", "冷敷"),
            ("hotCompress", "热敷"),
            ("massage", "按摩"),
            ("acupuncture", "针灸"),
            ("darkRoom", "暗室休息"),
            ("deepBreathing", "深呼吸"),
            ("meditation", "冥想"),
            ("yoga", "瑜伽"),
            ("relaxationTraining", "放松训练"),
            ("biofeedback", "生物反馈"),
            ("lightExercise", "散步/轻度运动"),
            ("acupressure", "按压穴位"),
            ("cupping", "拔罐"),
            ("moxibustion", "艾灸")
        ]
        
        for (index, intervention) in interventions.enumerated() {
            if insertIfNotExists(
                context: context, existingKeys: existingKeys,
                category: LabelCategory.intervention.rawValue,
                labelKey: intervention.key, displayName: intervention.name,
                subcategory: nil,
                sortOrder: index
            ) {
                insertedCount += 1
            }
        }
        
        return insertedCount
    }
    
    // MARK: - 初始化先兆标签
    
    private func initializeAuraLabels(context: ModelContext, existingKeys: Set<String>) -> Int {
        var insertedCount = 0
        let auras: [(key: String, name: String)] = [
            ("visual", "视觉闪光"),
            ("scotoma", "视野暗点"),
            ("numbness", "肢体麻木"),
            ("speechDifficulty", "言语障碍"),
            ("zigzagLines", "闪光锯齿线"),
            ("blurredVision", "视物模糊"),
            ("hemiparesis", "偏身无力"),
            ("vertigo", "眩晕"),
            ("tinnitus", "耳鸣")
        ]
        
        for (index, aura) in auras.enumerated() {
            if insertIfNotExists(
                context: context, existingKeys: existingKeys,
                category: LabelCategory.aura.rawValue,
                labelKey: aura.key, displayName: aura.name,
                subcategory: nil,
                sortOrder: index
            ) {
                insertedCount += 1
            }
        }
        
        return insertedCount
    }
    
    // MARK: - 标签去重（iCloud 同步后）
    
    /// 去重标签：按 (category, labelKey, subcategory) 分组，保留最早创建的记录，删除重复项
    /// 用于 iCloud 同步后多设备各自创建的默认标签导致的重复问题
    /// - Returns: 被删除的重复标签数量
    @discardableResult
    static func deduplicateLabels(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CustomLabelConfig>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        guard let allLabels = try? context.fetch(descriptor) else {
            return 0
        }
        
        // 按 (category, labelKey, subcategory) 分组
        // subcategory 为 nil 时使用空字符串作为 key 的一部分
        var seen = Set<String>()
        var duplicatesToDelete: [CustomLabelConfig] = []
        
        for label in allLabels {
            let groupKey = "\(label.category)|\(label.labelKey)|\(label.subcategory ?? "")"
            
            if seen.contains(groupKey) {
                // 此标签是重复项（因为按 createdAt 升序排列，先遇到的是最早的）
                duplicatesToDelete.append(label)
            } else {
                seen.insert(groupKey)
            }
        }
        
        // 删除重复项
        for duplicate in duplicatesToDelete {
            context.delete(duplicate)
        }
        
        if !duplicatesToDelete.isEmpty {
            try? context.save()
            print("标签去重完成：删除了 \(duplicatesToDelete.count) 条重复标签")
        }
        
        return duplicatesToDelete.count
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
        // 验证标签名称长度
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw LabelError.invalidName
        }
        
        guard trimmedName.count <= 10 else {
            throw LabelError.nameTooLong
        }
        
        // 检查是否已存在同名标签
        let existingLabels = fetchLabels(category: category, subcategory: subcategory, includeHidden: true, context: context)
        
        if existingLabels.contains(where: { $0.displayName == trimmedName }) {
            throw LabelError.duplicateName
        }
        
        // 计算新的排序顺序（放在最后）
        let maxSortOrder = existingLabels.map { $0.sortOrder }.max() ?? -1
        
        let newLabel = CustomLabelConfig(
            category: category.rawValue,
            labelKey: trimmedName, // 自定义标签使用显示名称作为 key
            displayName: trimmedName,
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
        
        // 验证新名称长度
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw LabelError.invalidName
        }
        
        guard trimmedName.count <= 10 else {
            throw LabelError.nameTooLong
        }
        
        // 检查新名称是否已存在
        let existingLabels = fetchLabels(
            category: LabelCategory(rawValue: label.category)!,
            subcategory: label.subcategory,
            includeHidden: true,
            context: context
        )
        
        if existingLabels.contains(where: { $0.displayName == trimmedName && $0.id != label.id }) {
            throw LabelError.duplicateName
        }
        
        label.displayName = trimmedName
        label.labelKey = trimmedName
        label.updatedAt = Date()
        try context.save()
    }
}

// MARK: - 错误类型

enum LabelError: LocalizedError {
    case duplicateName
    case cannotDeleteDefault
    case cannotEditDefault
    case invalidName
    case nameTooLong
    
    var errorDescription: String? {
        switch self {
        case .duplicateName:
            return "标签名称已存在"
        case .cannotDeleteDefault:
            return "默认标签不能删除，只能隐藏"
        case .cannotEditDefault:
            return "默认标签不能修改"
        case .invalidName:
            return "标签名称无效"
        case .nameTooLong:
            return "标签名称过长，最多10个字符"
        }
    }
}
