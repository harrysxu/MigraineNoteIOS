//
//  MedicationStatisticsTests.swift
//  migraine_noteTests
//
//  用药统计模型单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class MedicationStatisticsTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - empty 静态属性测试
    
    func testEmpty_AllZeros() {
        let stats = DetailedMedicationStatistics.empty
        
        XCTAssertEqual(stats.acuteMedicationDays, 0)
        XCTAssertEqual(stats.acuteMedicationCount, 0)
        XCTAssertEqual(stats.preventiveMedicationDays, 0)
        XCTAssertEqual(stats.preventiveMedicationCount, 0)
        XCTAssertEqual(stats.tcmTreatmentCount, 0)
        XCTAssertEqual(stats.surgeryCount, 0)
    }
    
    // MARK: - 计算属性测试
    
    func testHasAcuteMedication_WhenZero_ReturnsFalse() {
        let stats = DetailedMedicationStatistics.empty
        XCTAssertFalse(stats.hasAcuteMedication)
    }
    
    func testHasAcuteMedication_WhenPositive_ReturnsTrue() {
        let stats = DetailedMedicationStatistics(
            acuteMedicationDays: 1, acuteMedicationCount: 1,
            preventiveMedicationDays: 0, preventiveMedicationCount: 0,
            tcmTreatmentCount: 0, surgeryCount: 0
        )
        XCTAssertTrue(stats.hasAcuteMedication)
    }
    
    func testTotalMedicationDays() {
        let stats = DetailedMedicationStatistics(
            acuteMedicationDays: 5, acuteMedicationCount: 8,
            preventiveMedicationDays: 10, preventiveMedicationCount: 10,
            tcmTreatmentCount: 0, surgeryCount: 0
        )
        XCTAssertEqual(stats.totalMedicationDays, 15)
    }
    
    func testTotalMedicationCount() {
        let stats = DetailedMedicationStatistics(
            acuteMedicationDays: 5, acuteMedicationCount: 8,
            preventiveMedicationDays: 10, preventiveMedicationCount: 12,
            tcmTreatmentCount: 0, surgeryCount: 0
        )
        XCTAssertEqual(stats.totalMedicationCount, 20)
    }
    
    // MARK: - calculate() 方法测试
    
    func testCalculate_EmptyData_ReturnsZeros() {
        let dateRange = (start: dateAgo(days: 30), end: Date())
        let stats = DetailedMedicationStatistics.calculate(
            attacks: [], healthEvents: [], dateRange: dateRange
        )
        
        XCTAssertEqual(stats.acuteMedicationDays, 0)
        XCTAssertEqual(stats.acuteMedicationCount, 0)
        XCTAssertEqual(stats.preventiveMedicationDays, 0)
        XCTAssertEqual(stats.preventiveMedicationCount, 0)
        XCTAssertEqual(stats.tcmTreatmentCount, 0)
        XCTAssertEqual(stats.surgeryCount, 0)
    }
    
    func testCalculate_AttacksWithMedication() {
        // 创建发作记录和用药
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 2), endTime: dateAgo(days: 2).addingTimeInterval(3600), painIntensity: 7)
        let med = createMedication(in: modelContext, name: "布洛芬")
        createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack1)
        
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 5), endTime: dateAgo(days: 5).addingTimeInterval(7200), painIntensity: 6)
        createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack2)
        createMedicationLog(in: modelContext, medication: med, dosage: 400, timeTaken: dateAgo(days: 5).addingTimeInterval(3600), attack: attack2)
        
        let dateRange = (start: dateAgo(days: 30), end: Date())
        let stats = DetailedMedicationStatistics.calculate(
            attacks: [attack1, attack2], healthEvents: [], dateRange: dateRange
        )
        
        XCTAssertEqual(stats.acuteMedicationDays, 2, "两次发作在不同天，应有2个用药天数")
        XCTAssertEqual(stats.acuteMedicationCount, 3, "总共3条用药记录")
    }
    
    func testCalculate_HealthEventsWithMedication() {
        // 创建健康事件（预防性用药）
        let event1 = createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 1))
        let med = createMedication(in: modelContext, name: "普萘洛尔", category: .preventive, isAcute: false)
        createMedicationLog(in: modelContext, medication: med, dosage: 40, healthEvent: event1)
        
        let event2 = createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 3))
        createMedicationLog(in: modelContext, medication: med, dosage: 40, healthEvent: event2)
        
        let dateRange = (start: dateAgo(days: 30), end: Date())
        let stats = DetailedMedicationStatistics.calculate(
            attacks: [], healthEvents: [event1, event2], dateRange: dateRange
        )
        
        XCTAssertEqual(stats.preventiveMedicationDays, 2)
        XCTAssertEqual(stats.preventiveMedicationCount, 2)
    }
    
    func testCalculate_TCMAndSurgeryEvents() {
        let tcm1 = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 2))
        let tcm2 = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 5))
        let surgery = createHealthEvent(in: modelContext, eventType: .surgery, eventDate: dateAgo(days: 10))
        
        let dateRange = (start: dateAgo(days: 30), end: Date())
        let stats = DetailedMedicationStatistics.calculate(
            attacks: [], healthEvents: [tcm1, tcm2, surgery], dateRange: dateRange
        )
        
        XCTAssertEqual(stats.tcmTreatmentCount, 2)
        XCTAssertEqual(stats.surgeryCount, 1)
    }
    
    func testCalculate_SameDayAttacksMergeAcuteMedicationDays() {
        // 同一天两次发作，应只算1个用药天
        let today = Date()
        let attack1 = createAttack(in: modelContext, startTime: today, endTime: today.addingTimeInterval(3600), painIntensity: 5)
        let attack2 = createAttack(in: modelContext, startTime: today.addingTimeInterval(7200), endTime: today.addingTimeInterval(10800), painIntensity: 6)
        let med = createMedication(in: modelContext, name: "布洛芬")
        createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack1)
        createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack2)
        
        let dateRange = (start: dateAgo(days: 1), end: Date().addingTimeInterval(86400))
        let stats = DetailedMedicationStatistics.calculate(
            attacks: [attack1, attack2], healthEvents: [], dateRange: dateRange
        )
        
        XCTAssertEqual(stats.acuteMedicationDays, 1, "同一天应只算1天")
        XCTAssertEqual(stats.acuteMedicationCount, 2, "用药次数仍为2")
    }
}
