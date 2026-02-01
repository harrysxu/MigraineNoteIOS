//
//  MOHDetectorTests.swift
//  migraine_noteTests
//
//  Created on 2026/2/1.
//

import XCTest
import SwiftData
@testable import migraine_note

/// MOH检测器单元测试
final class MOHDetectorTests: XCTestCase {
    
    var detector: MOHDetector!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // 创建内存中的ModelContainer用于测试
        let schema = Schema([
            AttackRecord.self,
            Medication.self,
            MedicationLog.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(container)
        
        detector = MOHDetector(modelContext: modelContext)
    }
    
    override func tearDown() {
        detector = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - NSAID类MOH检测测试
    
    func testNSAID_NoRisk() {
        // 给定：本月使用NSAID 10天（低于15天阈值）
        createMedicationLogs(category: .nsaid, count: 10, inCurrentMonth: true)
        
        // 当：检测MOH风险
        let result = detector.detectCurrentMonthRisk()
        
        // 则：应该是无风险
        XCTAssertEqual(result.riskLevel, .none, "使用10天NSAID应该无风险")
        XCTAssertEqual(result.nsaidDays, 10, "NSAID天数应为10")
    }
    
    func testNSAID_HighRisk() {
        // 给定：本月使用NSAID 20天（超过15天阈值）
        createMedicationLogs(category: .nsaid, count: 20, inCurrentMonth: true)
        
        // 当：检测MOH风险
        let result = detector.detectCurrentMonthRisk()
        
        // 则：应该是高风险
        XCTAssertEqual(result.riskLevel, .high, "使用20天NSAID应该是高风险")
        XCTAssertEqual(result.nsaidDays, 20, "NSAID天数应为20")
    }
    
    // MARK: - 曲普坦类MOH检测测试
    
    func testTriptan_NoRisk() {
        // 给定：本月使用曲普坦 8天（低于10天阈值）
        createMedicationLogs(category: .triptan, count: 8, inCurrentMonth: true)
        
        // 当：检测MOH风险
        let result = detector.detectCurrentMonthRisk()
        
        // 则：应该是无风险
        XCTAssertEqual(result.riskLevel, .none, "使用8天曲普坦应该无风险")
        XCTAssertEqual(result.triptanDays, 8, "曲普坦天数应为8")
    }
    
    func testTriptan_HighRisk() {
        // 给定：本月使用曲普坦 15天（超过10天阈值）
        createMedicationLogs(category: .triptan, count: 15, inCurrentMonth: true)
        
        // 当：检测MOH风险
        let result = detector.detectCurrentMonthRisk()
        
        // 则：应该是高风险
        XCTAssertEqual(result.riskLevel, .high, "使用15天曲普坦应该是高风险")
        XCTAssertEqual(result.triptanDays, 15, "曲普坦天数应为15")
    }
    
    // MARK: - 组合用药MOH检测测试
    
    func testCombinedMedications_HighRisk() {
        // 给定：本月使用NSAID 12天 + 曲普坦 8天（合计20天）
        createMedicationLogs(category: .nsaid, count: 12, inCurrentMonth: true)
        createMedicationLogs(category: .triptan, count: 8, inCurrentMonth: true)
        
        // 当：检测MOH风险
        let result = detector.detectCurrentMonthRisk()
        
        // 则：应该是高风险（任一类超标或总天数过多）
        XCTAssertTrue(result.riskLevel == .medium || result.riskLevel == .high,
                      "组合用药应该有中高风险")
        XCTAssertEqual(result.nsaidDays, 12, "NSAID天数应为12")
        XCTAssertEqual(result.triptanDays, 8, "曲普坦天数应为8")
    }
    
    // MARK: - 跨月份测试
    
    func testOnlyCurrentMonthCounted() {
        // 给定：上月使用20天，本月使用5天
        createMedicationLogs(category: .nsaid, count: 20, inCurrentMonth: false)
        createMedicationLogs(category: .nsaid, count: 5, inCurrentMonth: true)
        
        // 当：检测MOH风险
        let result = detector.detectCurrentMonthRisk()
        
        // 则：只计算本月，应该无风险
        XCTAssertEqual(result.riskLevel, .none, "只应计算本月用药")
        XCTAssertEqual(result.nsaidDays, 5, "NSAID天数应为5（仅本月）")
    }
    
    // MARK: - 边界值测试
    
    func testNSAID_ThresholdBoundary() {
        // 测试15天临界值
        createMedicationLogs(category: .nsaid, count: 15, inCurrentMonth: true)
        
        let result = detector.detectCurrentMonthRisk()
        
        // 15天应该是中等风险或高风险
        XCTAssertTrue(result.riskLevel == .medium || result.riskLevel == .high,
                      "15天NSAID应该有风险警告")
    }
    
    func testTriptan_ThresholdBoundary() {
        // 测试10天临界值
        createMedicationLogs(category: .triptan, count: 10, inCurrentMonth: true)
        
        let result = detector.detectCurrentMonthRisk()
        
        // 10天应该是中等风险或高风险
        XCTAssertTrue(result.riskLevel == .medium || result.riskLevel == .high,
                      "10天曲普坦应该有风险警告")
    }
    
    // MARK: - 辅助方法
    
    /// 创建测试用的用药记录
    private func createMedicationLogs(
        category: MedicationCategory,
        count: Int,
        inCurrentMonth: Bool
    ) {
        // 创建药物
        let medication = Medication(
            name: category.rawValue,
            category: category,
            type: .acute,
            standardDosage: "1片",
            dosageUnit: "片"
        )
        modelContext.insert(medication)
        
        // 计算日期
        let calendar = Calendar.current
        let now = Date()
        let targetDate: Date
        
        if inCurrentMonth {
            targetDate = now
        } else {
            // 上个月
            targetDate = calendar.date(byAdding: .month, value: -1, to: now)!
        }
        
        // 创建用药记录（每天一条）
        for dayOffset in 0..<count {
            let logDate = calendar.date(byAdding: .day, value: -dayOffset, to: targetDate)!
            
            let log = MedicationLog(
                medication: medication,
                dosage: "1",
                takenAt: logDate,
                effectiveness: .effective
            )
            modelContext.insert(log)
        }
        
        // 保存
        try? modelContext.save()
    }
}
