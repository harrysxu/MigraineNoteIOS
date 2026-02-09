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
    
    /// 默认标签定义结构
    private struct DefaultLabelDef {
        let category: String
        let labelKey: String
        let displayName: String
        let subcategory: String?
        let sortOrder: Int
        let metadata: String?
        
        init(_ category: String, _ labelKey: String, _ displayName: String,
             subcategory: String? = nil, sortOrder: Int = 0, metadata: String? = nil) {
            self.category = category
            self.labelKey = labelKey
            self.displayName = displayName
            self.subcategory = subcategory
            self.sortOrder = sortOrder
            self.metadata = metadata
        }
    }
    
    /// 生成药物 metadata JSON
    private static func medMeta(dosage: Double, unit: String) -> String? {
        struct M: Codable { let dosage: Double; let unit: String }
        guard let data = try? JSONEncoder().encode(M(dosage: dosage, unit: unit)) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 所有默认标签定义（静态数据，app 生命周期内只构建一次）
    private static let allDefaultLabelDefinitions: [DefaultLabelDef] = {
        var defs: [DefaultLabelDef] = []
        
        // ── 症状：西医 ──
        let westernSymptoms: [(String, String)] = [
            ("nausea", "恶心"), ("vomiting", "呕吐"), ("photophobia", "畏光"),
            ("phonophobia", "畏声"), ("osmophobia", "气味敏感"), ("allodynia", "头皮触痛"),
            ("neckStiffness", "颈部僵硬"), ("fatigue", "疲乏"), ("blurredVision", "视物模糊"),
            ("pallor", "面色苍白"), ("nasalCongestion", "鼻塞/流涕")
        ]
        for (i, s) in westernSymptoms.enumerated() {
            defs.append(DefaultLabelDef("symptom", s.0, s.1, subcategory: "western", sortOrder: i))
        }
        
        // ── 症状：中医 ──
        let tcmSymptoms: [(String, String)] = [
            ("bitterTaste", "口苦"), ("facialFlushing", "面红目赤"), ("coldExtremities", "手脚冰凉"),
            ("heavyHeadedness", "头重如裹"), ("dizziness", "眩晕"), ("palpitation", "心悸"),
            ("greasyTongue", "舌苔厚腻"), ("hypochondriacPain", "胁痛"), ("constipation", "大便干结")
        ]
        for (i, s) in tcmSymptoms.enumerated() {
            defs.append(DefaultLabelDef("symptom", s.0, s.1, subcategory: "tcm", sortOrder: i))
        }
        
        // ── 诱因（labelKey == displayName）──
        let triggerData: [(String, [String])] = [
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
        for (cat, triggers) in triggerData {
            for (i, t) in triggers.enumerated() {
                defs.append(DefaultLabelDef("trigger", t, t, subcategory: cat, sortOrder: i))
            }
        }
        
        // ── 药物预设 ──
        let medicationData: [(String, [(String, Double, String)])] = [
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
        for (cat, meds) in medicationData {
            for (i, m) in meds.enumerated() {
                defs.append(DefaultLabelDef("medication", m.0, m.0, subcategory: cat, sortOrder: i, metadata: medMeta(dosage: m.1, unit: m.2)))
            }
        }
        
        // ── 疼痛性质 ──
        let painQualities: [(String, String)] = [
            ("pulsating", "搏动性"), ("pressing", "压迫感"), ("stabbing", "刺痛"), ("dull", "钝痛"),
            ("distending", "胀痛"), ("tightening", "紧缩感"), ("burning", "灼烧感"), ("tearing", "撕裂样")
        ]
        for (i, q) in painQualities.enumerated() {
            defs.append(DefaultLabelDef("painQuality", q.0, q.1, sortOrder: i))
        }
        
        // ── 非药物干预 ──
        let interventions: [(String, String)] = [
            ("sleep", "睡眠"), ("coldCompress", "冷敷"), ("hotCompress", "热敷"),
            ("massage", "按摩"), ("acupuncture", "针灸"), ("darkRoom", "暗室休息"),
            ("deepBreathing", "深呼吸"), ("meditation", "冥想"), ("yoga", "瑜伽"),
            ("relaxationTraining", "放松训练"), ("biofeedback", "生物反馈"),
            ("lightExercise", "散步/轻度运动"), ("acupressure", "按压穴位"),
            ("cupping", "拔罐"), ("moxibustion", "艾灸")
        ]
        for (i, v) in interventions.enumerated() {
            defs.append(DefaultLabelDef("intervention", v.0, v.1, sortOrder: i))
        }
        
        // ── 先兆类型 ──
        let auras: [(String, String)] = [
            ("visual", "视觉闪光"), ("scotoma", "视野暗点"), ("numbness", "肢体麻木"),
            ("speechDifficulty", "言语障碍"), ("zigzagLines", "闪光锯齿线"),
            ("blurredVision", "视物模糊"), ("hemiparesis", "偏身无力"),
            ("vertigo", "眩晕"), ("tinnitus", "耳鸣")
        ]
        for (i, a) in auras.enumerated() {
            defs.append(DefaultLabelDef("aura", a.0, a.1, sortOrder: i))
        }
        
        return defs
    }()
    
    // MARK: - 初始化默认标签
    
    /// 按 labelKey 逐个检查并补充缺失的默认标签
    /// iCloud 同步场景：云端已有的标签不会被重复创建，仅补充云端缺失的
    func initializeDefaultLabelsIfNeeded(context: ModelContext) {
        // 1. 一次性获取所有已存在标签的 (category_labelKey) 复合键
        let existingKeys = fetchAllExistingLabelKeys(context: context)
        
        // 2. 遍历所有默认标签定义，仅插入不存在的
        var insertedCount = 0
        for def in Self.allDefaultLabelDefinitions {
            let compositeKey = "\(def.category)_\(def.labelKey)"
            if !existingKeys.contains(compositeKey) {
                let label = CustomLabelConfig(
                    category: def.category,
                    labelKey: def.labelKey,
                    displayName: def.displayName,
                    isDefault: true,
                    subcategory: def.subcategory,
                    sortOrder: def.sortOrder
                )
                label.metadata = def.metadata
                context.insert(label)
                insertedCount += 1
            }
        }
        
        if insertedCount > 0 {
            try? context.save()
            print("🏷️ 补充了 \(insertedCount) 个缺失的默认标签")
        } else {
            print("🏷️ 所有默认标签已存在，无需补充")
        }
    }
    
    /// 获取所有已存在标签的 (category_labelKey) 复合键集合
    private func fetchAllExistingLabelKeys(context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<CustomLabelConfig>()
        guard let labels = try? context.fetch(descriptor) else { return [] }
        return Set(labels.map { "\($0.category)_\($0.labelKey)" })
    }
    
    // MARK: - 首次同步后标签去重
    
    /// 首次 iCloud 同步完成后，一次性去重所有标签
    /// - 单次 fetch 全部标签，在内存中按 (category, labelKey) 分组
    /// - 每组只保留 updatedAt 最新的一份，删除其余
    /// - 全部处理完后仅执行一次 save（最小化 CloudKit export 触发）
    /// - 此方法仅应在首次同步完成后（或 app 启动时同步已完成）调用一次
    func deduplicateLabelsAfterInitialSync(context: ModelContext) {
        // 1. 单次 fetch 获取所有标签
        let descriptor = FetchDescriptor<CustomLabelConfig>()
        guard let allLabels = try? context.fetch(descriptor) else {
            print("🏷️ 去重：无法获取标签数据")
            return
        }
        
        print("🏷️ 去重开始：数据库中共有 \(allLabels.count) 个标签")
        
        // 2. 在内存中按 (category, labelKey) 分组
        var groups: [String: [CustomLabelConfig]] = [:]
        for label in allLabels {
            let compositeKey = "\(label.category)_\(label.labelKey)"
            groups[compositeKey, default: []].append(label)
        }
        
        // 3. 处理重复组：只保留 updatedAt 最新的一份，删除其余
        var totalDeletedCount = 0
        var deletedByCategory: [String: Int] = [:]
        
        for (_, labels) in groups {
            guard labels.count > 1 else { continue }
            
            // 按 updatedAt 降序排列，保留最新的一份（通常是有用户定制的版本）
            let sorted = labels.sorted { $0.updatedAt > $1.updatedAt }
            let toDelete = sorted.dropFirst()
            let category = sorted[0].category
            
            for label in toDelete {
                context.delete(label)
                totalDeletedCount += 1
                deletedByCategory[category, default: 0] += 1
            }
        }
        
        // 4. 全部处理完后，仅执行一次 save（减少 CloudKit sync 触发）
        if totalDeletedCount > 0 {
            try? context.save()
            for (category, count) in deletedByCategory.sorted(by: { $0.key < $1.key }) {
                print("🏷️ 去重 [\(category)]：删除 \(count) 个重复标签")
            }
            print("🏷️ 去重完成：共删除 \(totalDeletedCount) 个重复标签，剩余 \(allLabels.count - totalDeletedCount) 个")
        } else {
            print("🏷️ 去重完成：无重复标签需要清理（共 \(groups.count) 个唯一标签）")
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
