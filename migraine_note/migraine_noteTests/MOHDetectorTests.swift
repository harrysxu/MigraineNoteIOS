//
//  MOHDetectorTests.swift
//  migraine_noteTests
//
//  MOH检测器单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class MOHDetectorTests: XCTestCase {
    
    var detector: MOHDetector!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
        detector = MOHDetector(modelContext: modelContext)
    }
    
    override func tearDown() {
        detector = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - detectCurrentMonthRisk 测试
    
    func testDetectCurrentMonthRisk_NoData_NoRisk() {
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, RiskLevel.none, "无数据应无风险")
    }
    
    func testDetectCurrentMonthRisk_NSAID_Low() {
        createMedicationDays(category: .nsaid, count: 10)
        
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, .low, "10天NSAID应为低风险")
    }
    
    func testDetectCurrentMonthRisk_NSAID_Medium() {
        createMedicationDays(category: .nsaid, count: 12)
        
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, .medium, "12天NSAID应为中风险")
    }
    
    func testDetectCurrentMonthRisk_NSAID_High() {
        createMedicationDays(category: .nsaid, count: 15)
        
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, .high, "15天NSAID应为高风险")
    }
    
    func testDetectCurrentMonthRisk_Triptan_Low() {
        createMedicationDays(category: .triptan, count: 6)
        
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, .low, "6天曲普坦应为低风险")
    }
    
    func testDetectCurrentMonthRisk_Triptan_High() {
        createMedicationDays(category: .triptan, count: 10)
        
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, .high, "10天曲普坦应为高风险")
    }
    
    func testDetectCurrentMonthRisk_Opioid_High() {
        createMedicationDays(category: .opioid, count: 10)
        
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, .high, "10天阿片类应为高风险")
    }
    
    func testDetectCurrentMonthRisk_BelowAllThresholds_None() {
        createMedicationDays(category: .nsaid, count: 5)
        createMedicationDays(category: .triptan, count: 3)
        
        let result = detector.detectCurrentMonthRisk()
        XCTAssertEqual(result, .none, "低用量应无风险")
    }
    
    // MARK: - 静态方法 checkMOHRisk 测试
    
    func testCheckMOHRisk_EmptyAttacks() {
        let period = DateInterval(start: dateAgo(days: 30), end: Date())
        let risk = MOHDetector.checkMOHRisk(for: period, attacks: [])
        
        XCTAssertEqual(risk, MOHRiskLevel.none)
    }
    
    func testCheckMOHRisk_HighNSAID() {
        var attacks: [AttackRecord] = []
        let med = createMedication(in: modelContext, name: "布洛芬", category: .nsaid)
        
        for i in 0..<16 {
            let attack = createAttack(in: modelContext, startTime: dateAgo(days: i), painIntensity: 5)
            createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack)
            attacks.append(attack)
        }
        
        let period = DateInterval(start: dateAgo(days: 30), end: Date())
        let risk = MOHDetector.checkMOHRisk(for: period, attacks: attacks)
        
        XCTAssertEqual(risk, .high)
    }
    
    // MARK: - 静态方法 getMedicationStatistics 测试
    
    func testGetMedicationStatistics_Empty() {
        let period = DateInterval(start: dateAgo(days: 30), end: Date())
        let stats = MOHDetector.getMedicationStatistics(for: period, attacks: [])
        
        XCTAssertEqual(stats.nsaidDays, 0)
        XCTAssertEqual(stats.triptanDays, 0)
        XCTAssertEqual(stats.opioidDays, 0)
        XCTAssertEqual(stats.totalMedicationDays, 0)
        XCTAssertFalse(stats.hasAnyRisk)
    }
    
    func testGetMedicationStatistics_WithData() {
        var attacks: [AttackRecord] = []
        let nsaid = createMedication(in: modelContext, name: "布洛芬", category: .nsaid)
        let triptan = createMedication(in: modelContext, name: "舒马曲普坦", category: .triptan)
        
        for i in 0..<5 {
            let attack = createAttack(in: modelContext, startTime: dateAgo(days: i), painIntensity: 5)
            createMedicationLog(in: modelContext, medication: nsaid, dosage: 400, attack: attack)
            attacks.append(attack)
        }
        
        for i in 5..<8 {
            let attack = createAttack(in: modelContext, startTime: dateAgo(days: i), painIntensity: 6)
            createMedicationLog(in: modelContext, medication: triptan, dosage: 50, attack: attack)
            attacks.append(attack)
        }
        
        let period = DateInterval(start: dateAgo(days: 30), end: Date())
        let stats = MOHDetector.getMedicationStatistics(for: period, attacks: attacks)
        
        XCTAssertEqual(stats.nsaidDays, 5)
        XCTAssertEqual(stats.triptanDays, 3)
        XCTAssertEqual(stats.totalMedicationDays, 8)
    }
    
    func testMedicationStatistics_ThresholdProgress() {
        let stats = MedicationStatistics(nsaidDays: 10, triptanDays: 5, opioidDays: 3, totalMedicationDays: 18)
        
        XCTAssertEqual(stats.thresholdProgress(for: .nsaid), 10.0 / 15.0, accuracy: 0.01)
        XCTAssertEqual(stats.thresholdProgress(for: .triptan), 5.0 / 10.0, accuracy: 0.01)
        XCTAssertEqual(stats.thresholdProgress(for: .opioid), 3.0 / 10.0, accuracy: 0.01)
        XCTAssertEqual(stats.thresholdProgress(for: .preventive), 0.0)
    }
    
    // MARK: - RiskLevel 枚举测试
    
    func testRiskLevel_DisplayNames() {
        XCTAssertEqual(RiskLevel.none.displayName, "无风险")
        XCTAssertEqual(RiskLevel.low.displayName, "低风险")
        XCTAssertEqual(RiskLevel.medium.displayName, "中风险")
        XCTAssertEqual(RiskLevel.high.displayName, "高风险")
    }
    
    // MARK: - MOHRiskLevel 枚举测试
    
    func testMOHRiskLevel_Descriptions() {
        for level in [MOHRiskLevel.none, .low, .medium, .high] {
            XCTAssertFalse(level.description.isEmpty)
            XCTAssertFalse(level.color.isEmpty)
            XCTAssertFalse(level.recommendation.isEmpty)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 在当前月内创建指定天数的用药记录
    /// detectCurrentMonthRisk 只查当前月数据，所以必须确保日期在当前月内
    private func createMedicationDays(category: MedicationCategory, count: Int) {
        let medication = createMedication(in: modelContext, name: category.rawValue, category: category)
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        for dayOffset in 0..<count {
            // 从月初开始向后创建，确保全部在当前月内
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth)!
            let attack = createAttack(in: modelContext, startTime: date, painIntensity: 5)
            createMedicationLog(in: modelContext, medication: medication, dosage: 400, timeTaken: date, attack: attack)
        }
    }
}
