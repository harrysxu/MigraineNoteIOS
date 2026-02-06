//
//  MedicationTests.swift
//  migraine_noteTests
//
//  药物模型单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class MedicationTests: XCTestCase {
    
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
    
    func testInit_BasicProperties() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: true)
        
        XCTAssertEqual(med.name, "布洛芬")
        XCTAssertEqual(med.category, .nsaid)
        XCTAssertTrue(med.isAcute)
    }
    
    // MARK: - 月度限制测试
    
    func testInit_NSAIDAcute_MonthlyLimit15() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: true)
        
        XCTAssertEqual(med.monthlyLimit, 15, "NSAID急性用药月度限制应为15天")
    }
    
    func testInit_TriptanAcute_MonthlyLimit10() {
        let med = Medication(name: "舒马曲普坦", category: .triptan, isAcute: true)
        
        XCTAssertEqual(med.monthlyLimit, 10, "曲普坦急性用药月度限制应为10天")
    }
    
    func testInit_OpioidAcute_MonthlyLimit10() {
        let med = Medication(name: "阿片类", category: .opioid, isAcute: true)
        
        XCTAssertEqual(med.monthlyLimit, 10, "阿片类急性用药月度限制应为10天")
    }
    
    func testInit_ErgotamineAcute_MonthlyLimit10() {
        let med = Medication(name: "麦角胺", category: .ergotamine, isAcute: true)
        
        XCTAssertEqual(med.monthlyLimit, 10, "麦角胺急性用药月度限制应为10天")
    }
    
    func testInit_PreventiveNotAcute_NoMonthlyLimit() {
        let med = Medication(name: "普萘洛尔", category: .preventive, isAcute: false)
        
        XCTAssertNil(med.monthlyLimit, "预防性用药不应有月度限制")
    }
    
    func testInit_OtherAcute_NoMonthlyLimit() {
        let med = Medication(name: "其他", category: .other, isAcute: true)
        
        XCTAssertNil(med.monthlyLimit, "其他类别急性用药不应有月度限制")
    }
    
    func testInit_NSAIDNotAcute_NoMonthlyLimit() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: false)
        
        XCTAssertNil(med.monthlyLimit, "非急性用药不应有月度限制")
    }
    
    // MARK: - Category 计算属性测试
    
    func testCategory_GetterConvertsFromRawValue() {
        let med = Medication(name: "test", category: .triptan, isAcute: true)
        
        XCTAssertEqual(med.category, .triptan)
        XCTAssertEqual(med.categoryRawValue, "曲普坦类")
    }
    
    func testCategory_SetterUpdatesRawValue() {
        let med = Medication(name: "test", category: .nsaid, isAcute: true)
        med.category = .preventive
        
        XCTAssertEqual(med.categoryRawValue, "预防性药物")
    }
    
    func testCategory_InvalidRawValue_DefaultsToOther() {
        let med = Medication(name: "test", category: .nsaid, isAcute: true)
        med.categoryRawValue = "无效类别"
        
        XCTAssertEqual(med.category, .other)
    }
    
    // MARK: - MedicationCategory 枚举测试
    
    func testMedicationCategory_AllCases() {
        XCTAssertEqual(MedicationCategory.allCases.count, 7)
    }
    
    func testMedicationCategory_IsAcuteMedication() {
        XCTAssertTrue(MedicationCategory.nsaid.isAcuteMedication)
        XCTAssertTrue(MedicationCategory.triptan.isAcuteMedication)
        XCTAssertTrue(MedicationCategory.opioid.isAcuteMedication)
        XCTAssertTrue(MedicationCategory.ergotamine.isAcuteMedication)
        XCTAssertFalse(MedicationCategory.preventive.isAcuteMedication)
        XCTAssertTrue(MedicationCategory.tcmHerbal.isAcuteMedication)
        XCTAssertTrue(MedicationCategory.other.isAcuteMedication)
    }
    
    // MARK: - MedicationPresets 测试
    
    func testPresets_CommonNSAIDs_NotEmpty() {
        XCTAssertFalse(MedicationPresets.commonNSAIDs.isEmpty)
        XCTAssertEqual(MedicationPresets.commonNSAIDs.count, 6)
    }
    
    func testPresets_CommonTriptans_NotEmpty() {
        XCTAssertFalse(MedicationPresets.commonTriptans.isEmpty)
        XCTAssertEqual(MedicationPresets.commonTriptans.count, 5)
    }
    
    func testPresets_CommonPreventive_NotEmpty() {
        XCTAssertFalse(MedicationPresets.commonPreventive.isEmpty)
        XCTAssertEqual(MedicationPresets.commonPreventive.count, 5)
    }
    
    func testPresets_CommonTCM_NotEmpty() {
        XCTAssertFalse(MedicationPresets.commonTCM.isEmpty)
        XCTAssertEqual(MedicationPresets.commonTCM.count, 6)
    }
    
    func testPresets_CommonErgotamine_NotEmpty() {
        XCTAssertFalse(MedicationPresets.commonErgotamine.isEmpty)
    }
    
    func testPresets_AllHavePositiveDosage() {
        for (_, dosage, _) in MedicationPresets.commonNSAIDs {
            XCTAssertTrue(dosage > 0)
        }
        for (_, dosage, _) in MedicationPresets.commonTriptans {
            XCTAssertTrue(dosage > 0)
        }
    }
}
