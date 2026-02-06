//
//  MedicationLogTests.swift
//  migraine_noteTests
//
//  用药记录模型单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class MedicationLogTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInit_DefaultValues() {
        let log = MedicationLog(dosage: 400)
        
        XCTAssertEqual(log.dosage, 400)
        XCTAssertEqual(log.efficacy, .notEvaluated)
        XCTAssertNil(log.medication)
        XCTAssertNil(log.medicationName)
        XCTAssertTrue(log.sideEffects.isEmpty)
    }
    
    func testInit_WithTimeTaken() {
        let date = makeDate(year: 2026, month: 1, day: 15)
        let log = MedicationLog(dosage: 400, timeTaken: date)
        
        XCTAssertEqual(log.timeTaken, date)
        XCTAssertEqual(log.takenAt, date) // 兼容属性
    }
    
    // MARK: - Efficacy 计算属性测试
    
    func testEfficacy_GetterConvertsFromRawValue() {
        let log = MedicationLog(dosage: 400)
        log.efficacyRawValue = "完全缓解"
        
        XCTAssertEqual(log.efficacy, .complete)
    }
    
    func testEfficacy_SetterUpdatesRawValue() {
        let log = MedicationLog(dosage: 400)
        log.efficacy = .partial
        
        XCTAssertEqual(log.efficacyRawValue, "部分缓解")
    }
    
    func testEfficacy_InvalidRawValue_DefaultsToNotEvaluated() {
        let log = MedicationLog(dosage: 400)
        log.efficacyRawValue = "无效值"
        
        XCTAssertEqual(log.efficacy, .notEvaluated)
    }
    
    // MARK: - needsEfficacyEvaluation 测试
    
    func testNeedsEfficacyEvaluation_RecentlyTaken_ReturnsFalse() {
        let log = MedicationLog(dosage: 400, timeTaken: Date()) // 刚刚服用
        
        XCTAssertFalse(log.needsEfficacyEvaluation, "刚服用不需要评估")
    }
    
    func testNeedsEfficacyEvaluation_After2Hours_ReturnsTrue() {
        let twoHoursAgo = Date().addingTimeInterval(-7201) // 2小时1秒前
        let log = MedicationLog(dosage: 400, timeTaken: twoHoursAgo)
        
        XCTAssertTrue(log.needsEfficacyEvaluation, "服药2小时后应需要评估")
    }
    
    func testNeedsEfficacyEvaluation_AlreadyEvaluated_ReturnsFalse() {
        let twoHoursAgo = Date().addingTimeInterval(-7201)
        let log = MedicationLog(dosage: 400, timeTaken: twoHoursAgo)
        log.efficacy = .complete // 已评估
        
        XCTAssertFalse(log.needsEfficacyEvaluation, "已评估不需要再评估")
    }
    
    // MARK: - timeUntilEfficacyCheck 测试
    
    func testTimeUntilEfficacyCheck_JustTaken_Returns2Hours() {
        let log = MedicationLog(dosage: 400, timeTaken: Date())
        
        let remaining = log.timeUntilEfficacyCheck
        XCTAssertTrue(remaining > 7100 && remaining <= 7200, "刚服用应剩余约2小时")
    }
    
    func testTimeUntilEfficacyCheck_After2Hours_ReturnsZero() {
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        let log = MedicationLog(dosage: 400, timeTaken: twoHoursAgo)
        
        XCTAssertEqual(log.timeUntilEfficacyCheck, 0, accuracy: 1, "超过2小时应返回0")
    }
    
    // MARK: - displayName 测试
    
    func testDisplayName_WithMedication() {
        let log = MedicationLog(dosage: 400)
        let med = createMedication(in: modelContext, name: "布洛芬")
        log.medication = med
        
        XCTAssertEqual(log.displayName, "布洛芬")
    }
    
    func testDisplayName_WithCustomName() {
        let log = MedicationLog(dosage: 400)
        log.medicationName = "自定义药物"
        
        XCTAssertEqual(log.displayName, "自定义药物")
    }
    
    func testDisplayName_NoMedicationNoName_ReturnsDefault() {
        let log = MedicationLog(dosage: 400)
        
        XCTAssertEqual(log.displayName, "未知药物")
    }
    
    // MARK: - dosageString 测试
    
    func testDosageString_WithUnit() {
        let log = MedicationLog(dosage: 400)
        log.unit = "mg"
        
        XCTAssertEqual(log.dosageString, "400.0mg")
    }
    
    func testDosageString_WithMedicationUnit() {
        let log = MedicationLog(dosage: 2.5)
        let med = createMedication(in: modelContext, name: "佐米曲普坦", category: .triptan)
        med.unit = "mg"
        log.medication = med
        
        XCTAssertEqual(log.dosageString, "2.5mg")
    }
    
    func testDosageString_DefaultUnit() {
        let log = MedicationLog(dosage: 500)
        
        XCTAssertEqual(log.dosageString, "500.0mg")
    }
    
    // MARK: - Effectiveness 兼容属性测试
    
    func testEffectiveness_NotEvaluated_ReturnsNil() {
        let log = MedicationLog(dosage: 400)
        
        XCTAssertNil(log.effectiveness)
    }
    
    func testEffectiveness_Complete_ReturnsExcellent() {
        let log = MedicationLog(dosage: 400)
        log.efficacy = .complete
        
        XCTAssertEqual(log.effectiveness, .excellent)
    }
    
    func testEffectiveness_Partial_ReturnsModerate() {
        let log = MedicationLog(dosage: 400)
        log.efficacy = .partial
        
        XCTAssertEqual(log.effectiveness, .moderate)
    }
    
    func testEffectiveness_NoEffect_ReturnsNone() {
        let log = MedicationLog(dosage: 400)
        log.efficacy = .noEffect
        
        XCTAssertEqual(log.effectiveness, MedicationLog.Effectiveness.none)
    }
    
    // MARK: - MedicationEfficacy 枚举测试
    
    func testMedicationEfficacy_AllCases() {
        XCTAssertEqual(MedicationEfficacy.allCases.count, 4)
    }
    
    func testMedicationEfficacy_DisplayName() {
        XCTAssertEqual(MedicationEfficacy.notEvaluated.displayName, "未评估")
        XCTAssertEqual(MedicationEfficacy.complete.displayName, "完全缓解")
        XCTAssertEqual(MedicationEfficacy.partial.displayName, "部分缓解")
        XCTAssertEqual(MedicationEfficacy.noEffect.displayName, "无效")
    }
    
    func testMedicationEfficacy_Icons() {
        for efficacy in MedicationEfficacy.allCases {
            XCTAssertFalse(efficacy.icon.isEmpty)
        }
    }
}
