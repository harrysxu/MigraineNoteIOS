//
//  LabelManagerTests.swift
//  migraine_noteTests
//
//  标签管理服务单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class LabelManagerTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 初始化默认标签测试
    
    func testInitializeDefaultLabels_CreatesLabels() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let labels = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        XCTAssertFalse(labels.isEmpty, "初始化后应有症状标签")
    }
    
    func testInitializeDefaultLabels_Idempotent() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        let firstCount = countAllLabels()
        
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        let secondCount = countAllLabels()
        
        XCTAssertEqual(firstCount, secondCount, "重复初始化不应创建额外标签")
    }
    
    func testInitializeDefaultLabels_CreatesAllCategories() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let symptoms = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        let triggers = LabelManager.fetchLabels(category: .trigger, includeHidden: true, context: modelContext)
        let painQualities = LabelManager.fetchLabels(category: .painQuality, includeHidden: true, context: modelContext)
        let interventions = LabelManager.fetchLabels(category: .intervention, includeHidden: true, context: modelContext)
        let auras = LabelManager.fetchLabels(category: .aura, includeHidden: true, context: modelContext)
        
        XCTAssertFalse(symptoms.isEmpty, "应有症状标签")
        XCTAssertFalse(triggers.isEmpty, "应有诱因标签")
        XCTAssertFalse(painQualities.isEmpty, "应有疼痛性质标签")
        XCTAssertFalse(interventions.isEmpty, "应有干预标签")
        XCTAssertFalse(auras.isEmpty, "应有先兆标签")
    }
    
    // MARK: - 查询标签测试
    
    func testFetchLabels_ByCategory() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let painQualities = LabelManager.fetchLabels(category: .painQuality, context: modelContext)
        XCTAssertEqual(painQualities.count, 8, "应有8种疼痛性质")
    }
    
    func testFetchLabels_BySubcategory() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let western = LabelManager.fetchLabels(category: .symptom, subcategory: "western", context: modelContext)
        let tcm = LabelManager.fetchLabels(category: .symptom, subcategory: "tcm", context: modelContext)
        
        XCTAssertEqual(western.count, 11, "应有11种西医症状")
        XCTAssertEqual(tcm.count, 9, "应有9种中医症状")
    }
    
    func testFetchLabels_ExcludesHiddenByDefault() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        // 隐藏一个标签
        let labels = LabelManager.fetchLabels(category: .painQuality, context: modelContext)
        if let first = labels.first {
            try? LabelManager.toggleLabelVisibility(label: first, context: modelContext)
        }
        
        let visibleLabels = LabelManager.fetchLabels(category: .painQuality, context: modelContext)
        let allLabels = LabelManager.fetchLabels(category: .painQuality, includeHidden: true, context: modelContext)
        
        XCTAssertEqual(visibleLabels.count, 7, "可见标签应少一个")
        XCTAssertEqual(allLabels.count, 8, "包含隐藏的标签应有8个")
    }
    
    // MARK: - 添加自定义标签测试
    
    func testAddCustomLabel_Success() throws {
        try LabelManager.addCustomLabel(
            category: .symptom,
            displayName: "自定义症状",
            subcategory: "western",
            context: modelContext
        )
        
        let labels = LabelManager.fetchLabels(category: .symptom, subcategory: "western", context: modelContext)
        let custom = labels.first { $0.displayName == "自定义症状" }
        
        XCTAssertNotNil(custom)
        XCTAssertFalse(custom!.isDefault)
    }
    
    func testAddCustomLabel_EmptyName_ThrowsError() {
        XCTAssertThrowsError(
            try LabelManager.addCustomLabel(category: .symptom, displayName: "", context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .invalidName)
        }
    }
    
    func testAddCustomLabel_WhitespaceOnlyName_ThrowsError() {
        XCTAssertThrowsError(
            try LabelManager.addCustomLabel(category: .symptom, displayName: "   ", context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .invalidName)
        }
    }
    
    func testAddCustomLabel_TooLongName_ThrowsError() {
        XCTAssertThrowsError(
            try LabelManager.addCustomLabel(category: .symptom, displayName: "这是一个超过十个字符的标签名称", context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .nameTooLong)
        }
    }
    
    func testAddCustomLabel_DuplicateName_ThrowsError() throws {
        try LabelManager.addCustomLabel(category: .symptom, displayName: "测试标签", context: modelContext)
        
        XCTAssertThrowsError(
            try LabelManager.addCustomLabel(category: .symptom, displayName: "测试标签", context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .duplicateName)
        }
    }
    
    // MARK: - 切换标签可见性测试
    
    func testToggleLabelVisibility() throws {
        try LabelManager.addCustomLabel(category: .symptom, displayName: "测试标签", context: modelContext)
        
        let labels = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        let label = labels.first { $0.displayName == "测试标签" }!
        
        XCTAssertFalse(label.isHidden)
        
        try LabelManager.toggleLabelVisibility(label: label, context: modelContext)
        XCTAssertTrue(label.isHidden)
        
        try LabelManager.toggleLabelVisibility(label: label, context: modelContext)
        XCTAssertFalse(label.isHidden)
    }
    
    // MARK: - 删除标签测试
    
    func testDeleteCustomLabel_Success() throws {
        try LabelManager.addCustomLabel(category: .symptom, displayName: "待删除", context: modelContext)
        
        let labels = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        let label = labels.first { $0.displayName == "待删除" }!
        
        try LabelManager.deleteCustomLabel(label: label, context: modelContext)
        
        let after = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        XCTAssertNil(after.first { $0.displayName == "待删除" })
    }
    
    func testDeleteDefaultLabel_ThrowsError() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let labels = LabelManager.fetchLabels(category: .symptom, context: modelContext)
        let defaultLabel = labels.first { $0.isDefault }!
        
        XCTAssertThrowsError(
            try LabelManager.deleteCustomLabel(label: defaultLabel, context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .cannotDeleteDefault)
        }
    }
    
    // MARK: - 更新排序测试
    
    func testUpdateLabelOrder() throws {
        try LabelManager.addCustomLabel(category: .painQuality, displayName: "A标签", context: modelContext)
        try LabelManager.addCustomLabel(category: .painQuality, displayName: "B标签", context: modelContext)
        try LabelManager.addCustomLabel(category: .painQuality, displayName: "C标签", context: modelContext)
        
        var labels = LabelManager.fetchLabels(category: .painQuality, context: modelContext)
        labels = labels.reversed() // 反转顺序
        
        try LabelManager.updateLabelOrder(labels: labels, context: modelContext)
        
        let updated = LabelManager.fetchLabels(category: .painQuality, context: modelContext)
        XCTAssertEqual(updated.first?.sortOrder, 0)
    }
    
    // MARK: - 重命名标签测试
    
    func testRenameLabel_Success() throws {
        try LabelManager.addCustomLabel(category: .symptom, displayName: "旧名称", context: modelContext)
        
        let labels = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        let label = labels.first { $0.displayName == "旧名称" }!
        
        try LabelManager.renameLabel(label: label, newName: "新名称", context: modelContext)
        
        XCTAssertEqual(label.displayName, "新名称")
        XCTAssertEqual(label.labelKey, "新名称")
    }
    
    func testRenameDefaultLabel_ThrowsError() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let labels = LabelManager.fetchLabels(category: .symptom, context: modelContext)
        let defaultLabel = labels.first { $0.isDefault }!
        
        XCTAssertThrowsError(
            try LabelManager.renameLabel(label: defaultLabel, newName: "新名称", context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .cannotEditDefault)
        }
    }
    
    func testRenameLabel_EmptyName_ThrowsError() throws {
        try LabelManager.addCustomLabel(category: .symptom, displayName: "测试", context: modelContext)
        let labels = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        let label = labels.first { $0.displayName == "测试" }!
        
        XCTAssertThrowsError(
            try LabelManager.renameLabel(label: label, newName: "", context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .invalidName)
        }
    }
    
    func testRenameLabel_DuplicateName_ThrowsError() throws {
        try LabelManager.addCustomLabel(category: .symptom, displayName: "标签A", context: modelContext)
        try LabelManager.addCustomLabel(category: .symptom, displayName: "标签B", context: modelContext)
        
        let labels = LabelManager.fetchLabels(category: .symptom, includeHidden: true, context: modelContext)
        let labelB = labels.first { $0.displayName == "标签B" }!
        
        XCTAssertThrowsError(
            try LabelManager.renameLabel(label: labelB, newName: "标签A", context: modelContext)
        ) { error in
            XCTAssertEqual(error as? LabelError, .duplicateName)
        }
    }
    
    // MARK: - LabelError 测试
    
    func testLabelError_ErrorDescriptions() {
        XCTAssertNotNil(LabelError.duplicateName.errorDescription)
        XCTAssertNotNil(LabelError.cannotDeleteDefault.errorDescription)
        XCTAssertNotNil(LabelError.cannotEditDefault.errorDescription)
        XCTAssertNotNil(LabelError.invalidName.errorDescription)
        XCTAssertNotNil(LabelError.nameTooLong.errorDescription)
    }
    
    // MARK: - 标签去重测试
    
    func testDeduplicateLabels_RemovesDuplicateDefaults() {
        // 模拟两台设备各自创建了默认标签（iCloud同步后出现重复）
        let label1 = CustomLabelConfig(
            category: LabelCategory.painQuality.rawValue,
            labelKey: "pulsating",
            displayName: "搏动性",
            isDefault: true,
            subcategory: nil,
            sortOrder: 0
        )
        label1.createdAt = Date(timeIntervalSinceNow: -100)
        
        let label2 = CustomLabelConfig(
            category: LabelCategory.painQuality.rawValue,
            labelKey: "pulsating",
            displayName: "搏动性",
            isDefault: true,
            subcategory: nil,
            sortOrder: 0
        )
        label2.createdAt = Date(timeIntervalSinceNow: -50)
        
        modelContext.insert(label1)
        modelContext.insert(label2)
        try? modelContext.save()
        
        // 去重前应有2条
        XCTAssertEqual(countLabels(category: "painQuality", labelKey: "pulsating"), 2)
        
        let removedCount = LabelManager.deduplicateLabels(context: modelContext)
        
        // 去重后应只剩1条
        XCTAssertEqual(removedCount, 1, "应删除1条重复标签")
        XCTAssertEqual(countLabels(category: "painQuality", labelKey: "pulsating"), 1)
    }
    
    func testDeduplicateLabels_KeepsEarliestCreated() {
        // 创建两个重复标签，一早一晚
        let earlyLabel = CustomLabelConfig(
            category: LabelCategory.symptom.rawValue,
            labelKey: "nausea",
            displayName: "恶心",
            isDefault: true,
            subcategory: "western",
            sortOrder: 0
        )
        earlyLabel.createdAt = Date(timeIntervalSinceNow: -200)
        
        let lateLabel = CustomLabelConfig(
            category: LabelCategory.symptom.rawValue,
            labelKey: "nausea",
            displayName: "恶心",
            isDefault: true,
            subcategory: "western",
            sortOrder: 0
        )
        lateLabel.createdAt = Date(timeIntervalSinceNow: -10)
        
        modelContext.insert(earlyLabel)
        modelContext.insert(lateLabel)
        try? modelContext.save()
        
        LabelManager.deduplicateLabels(context: modelContext)
        
        // 应保留最早创建的那条
        let remaining = fetchLabels(category: "symptom", labelKey: "nausea")
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.id, earlyLabel.id, "应保留最早创建的标签")
    }
    
    func testDeduplicateLabels_NoDuplicates_ReturnsZero() {
        // 初始化默认标签（无重复）
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let removedCount = LabelManager.deduplicateLabels(context: modelContext)
        XCTAssertEqual(removedCount, 0, "没有重复标签时不应删除任何记录")
    }
    
    func testDeduplicateLabels_DifferentSubcategories_NotDuplicate() {
        // 相同 category + labelKey 但不同 subcategory => 不算重复
        let label1 = CustomLabelConfig(
            category: LabelCategory.trigger.rawValue,
            labelKey: "headache",
            displayName: "头痛",
            isDefault: true,
            subcategory: "饮食",
            sortOrder: 0
        )
        
        let label2 = CustomLabelConfig(
            category: LabelCategory.trigger.rawValue,
            labelKey: "headache",
            displayName: "头痛",
            isDefault: true,
            subcategory: "环境",
            sortOrder: 0
        )
        
        modelContext.insert(label1)
        modelContext.insert(label2)
        try? modelContext.save()
        
        let removedCount = LabelManager.deduplicateLabels(context: modelContext)
        XCTAssertEqual(removedCount, 0, "不同subcategory的同名标签不算重复")
    }
    
    func testDeduplicateLabels_TripleDuplicates() {
        // 模拟3台设备各自创建了同一个标签
        for i in 0..<3 {
            let label = CustomLabelConfig(
                category: LabelCategory.aura.rawValue,
                labelKey: "visual",
                displayName: "视觉闪光",
                isDefault: true,
                subcategory: nil,
                sortOrder: 0
            )
            label.createdAt = Date(timeIntervalSinceNow: Double(-100 + i * 30))
            modelContext.insert(label)
        }
        try? modelContext.save()
        
        let removedCount = LabelManager.deduplicateLabels(context: modelContext)
        
        XCTAssertEqual(removedCount, 2, "3条重复标签应删除2条")
        XCTAssertEqual(countLabels(category: "aura", labelKey: "visual"), 1)
    }
    
    func testDeduplicateLabels_CustomLabelDuplicates() {
        // 模拟用户在两台设备同时创建了同名自定义标签
        let label1 = CustomLabelConfig(
            category: LabelCategory.symptom.rawValue,
            labelKey: "自定义症状",
            displayName: "自定义症状",
            isDefault: false,
            subcategory: "western",
            sortOrder: 100
        )
        label1.createdAt = Date(timeIntervalSinceNow: -60)
        
        let label2 = CustomLabelConfig(
            category: LabelCategory.symptom.rawValue,
            labelKey: "自定义症状",
            displayName: "自定义症状",
            isDefault: false,
            subcategory: "western",
            sortOrder: 100
        )
        label2.createdAt = Date(timeIntervalSinceNow: -30)
        
        modelContext.insert(label1)
        modelContext.insert(label2)
        try? modelContext.save()
        
        let removedCount = LabelManager.deduplicateLabels(context: modelContext)
        XCTAssertEqual(removedCount, 1, "自定义标签重复也应被去重")
    }
    
    func testInitializeAfterSync_NoDuplicates() {
        // 模拟场景：iCloud同步下来了默认标签，然后本地再次调用初始化
        // 手动插入一些"从另一台设备同步过来的"默认标签
        let syncedLabel = CustomLabelConfig(
            category: LabelCategory.painQuality.rawValue,
            labelKey: "pulsating",
            displayName: "搏动性",
            isDefault: true,
            subcategory: nil,
            sortOrder: 0
        )
        modelContext.insert(syncedLabel)
        try? modelContext.save()
        
        // 再调用初始化 —— 不应创建重复的 pulsating
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let count = countLabels(category: "painQuality", labelKey: "pulsating")
        XCTAssertEqual(count, 1, "已有同步标签后初始化不应创建重复")
    }
    
    // MARK: - 辅助方法
    
    private func countAllLabels() -> Int {
        let descriptor = FetchDescriptor<CustomLabelConfig>()
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
    
    private func countLabels(category: String, labelKey: String) -> Int {
        let descriptor = FetchDescriptor<CustomLabelConfig>(
            predicate: #Predicate<CustomLabelConfig> { label in
                label.category == category && label.labelKey == labelKey
            }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
    
    private func fetchLabels(category: String, labelKey: String) -> [CustomLabelConfig] {
        let descriptor = FetchDescriptor<CustomLabelConfig>(
            predicate: #Predicate<CustomLabelConfig> { label in
                label.category == category && label.labelKey == labelKey
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
