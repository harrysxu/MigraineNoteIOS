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
        XCTAssertEqual(painQualities.count, 5, "应有5种疼痛性质")
    }
    
    func testFetchLabels_BySubcategory() {
        LabelManager.shared.initializeDefaultLabelsIfNeeded(context: modelContext)
        
        let western = LabelManager.fetchLabels(category: .symptom, subcategory: "western", context: modelContext)
        let tcm = LabelManager.fetchLabels(category: .symptom, subcategory: "tcm", context: modelContext)
        
        XCTAssertEqual(western.count, 6, "应有6种西医症状")
        XCTAssertEqual(tcm.count, 6, "应有6种中医症状")
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
        
        XCTAssertEqual(visibleLabels.count, 4, "可见标签应少一个")
        XCTAssertEqual(allLabels.count, 5, "包含隐藏的标签应有5个")
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
    
    // MARK: - 辅助方法
    
    private func countAllLabels() -> Int {
        let descriptor = FetchDescriptor<CustomLabelConfig>()
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
}
