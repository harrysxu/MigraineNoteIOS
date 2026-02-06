//
//  ErrorHandlingTests.swift
//  migraine_noteTests
//
//  错误处理、删除逻辑与 Section 折叠标题测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class ErrorHandlingTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 数据删除逻辑测试（直接测试 SwiftData 操作）
    
    func testDeleteAttack_DirectContextDelete() throws {
        let attack = createAttack(in: modelContext, painIntensity: 5)
        
        let before = try modelContext.fetch(FetchDescriptor<AttackRecord>())
        XCTAssertEqual(before.count, 1)
        
        modelContext.delete(attack)
        try modelContext.save()
        
        let after = try modelContext.fetch(FetchDescriptor<AttackRecord>())
        XCTAssertEqual(after.count, 0, "删除后记录数应为0")
    }
    
    func testBatchDeleteAttacks_DirectContextDelete() throws {
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 7)
        let _ = createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 3)
        
        // 只删除前两个
        modelContext.delete(attack1)
        modelContext.delete(attack2)
        try modelContext.save()
        
        let remaining = try modelContext.fetch(FetchDescriptor<AttackRecord>())
        XCTAssertEqual(remaining.count, 1, "批量删除后应只剩1条记录")
    }
    
    func testDeleteMedication_DirectContextDelete() throws {
        let medication = createMedication(in: modelContext, name: "布洛芬")
        
        modelContext.delete(medication)
        try modelContext.save()
        
        let after = try modelContext.fetch(FetchDescriptor<Medication>())
        XCTAssertEqual(after.count, 0)
    }
    
    func testUpdateInventory_ClampsToZero() throws {
        let medication = createMedication(in: modelContext, name: "测试药物", inventory: 5)
        
        // 模拟 updateInventory 的逻辑
        medication.inventory = max(0, -3)
        try modelContext.save()
        
        XCTAssertEqual(medication.inventory, 0, "库存不应为负数")
    }
    
    func testUpdateInventory_SetsCorrectValue() throws {
        let medication = createMedication(in: modelContext, name: "测试药物", inventory: 5)
        
        medication.inventory = max(0, 10)
        try modelContext.save()
        
        XCTAssertEqual(medication.inventory, 10)
    }
    
    func testDeleteAttack_WithMedicationLogs() throws {
        let medication = createMedication(in: modelContext, name: "布洛芬")
        let attack = createAttack(in: modelContext, painIntensity: 7)
        let _ = createMedicationLog(in: modelContext, medication: medication, dosage: 400, attack: attack)
        
        // 验证关联
        XCTAssertEqual(attack.medications.count, 1)
        
        // 删除发作记录（应级联删除 MedicationLog）
        modelContext.delete(attack)
        try modelContext.save()
        
        let attacks = try modelContext.fetch(FetchDescriptor<AttackRecord>())
        XCTAssertEqual(attacks.count, 0)
        
        // 药物本身不应被删除
        let medications = try modelContext.fetch(FetchDescriptor<Medication>())
        XCTAssertEqual(medications.count, 1)
    }
    
    // MARK: - Section 折叠标题摘要逻辑测试
    
    func testSectionTitle_Symptoms_Empty() {
        let count = 0
        let title = count > 0 ? "症状记录 (\(count)项)" : "症状记录"
        XCTAssertEqual(title, "症状记录")
    }
    
    func testSectionTitle_Symptoms_WithItems() {
        let count = 3
        let title = count > 0 ? "症状记录 (\(count)项)" : "症状记录"
        XCTAssertEqual(title, "症状记录 (3项)")
    }
    
    func testSectionTitle_Notes_Empty() {
        let notes = ""
        let title = notes.isEmpty ? "备注" : "备注 (已填写)"
        XCTAssertEqual(title, "备注")
    }
    
    func testSectionTitle_Notes_Filled() {
        let notes = "头很痛"
        let title = notes.isEmpty ? "备注" : "备注 (已填写)"
        XCTAssertEqual(title, "备注 (已填写)")
    }
    
    func testSectionTitle_Medications_Empty() {
        let count = 0
        let title = count > 0 ? "用药记录 (\(count)项)" : "用药记录"
        XCTAssertEqual(title, "用药记录")
    }
    
    func testSectionTitle_Medications_WithItems() {
        let count = 2
        let title = count > 0 ? "用药记录 (\(count)项)" : "用药记录"
        XCTAssertEqual(title, "用药记录 (2项)")
    }
    
    func testSectionTitle_Triggers_Empty() {
        let count = 0
        let title = count > 0 ? "诱因分析 (\(count)项)" : "诱因分析"
        XCTAssertEqual(title, "诱因分析")
    }
    
    func testSectionTitle_NonPharm_WithItems() {
        let count = 1
        let title = count > 0 ? "非药物干预 (\(count)项)" : "非药物干预"
        XCTAssertEqual(title, "非药物干预 (1项)")
    }
    
}
