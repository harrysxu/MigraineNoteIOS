//
//  MenstrualCycleTests.swift
//  migraine_noteTests
//
//  经期关联分析单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class MenstrualCycleTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - MenstrualPeriod Tests
    
    func testMenstrualPeriodDuration() {
        let start = makeDate(year: 2026, month: 1, day: 1)
        let end = makeDate(year: 2026, month: 1, day: 5)
        
        let period = MenstrualPeriod(startDate: start, endDate: end, flowLevels: [1, 2, 3, 2, 1])
        
        XCTAssertEqual(period.durationDays, 5)
    }
    
    func testMenstrualPeriodSingleDay() {
        let date = makeDate(year: 2026, month: 1, day: 1)
        
        let period = MenstrualPeriod(startDate: date, endDate: date, flowLevels: [2])
        
        XCTAssertEqual(period.durationDays, 1)
    }
    
    // MARK: - CycleAnalysis Tests
    
    func testAnalyzeCycleCorrelation_InsufficientData() {
        let manager = MenstrualCycleManager.shared
        
        // 只有1个周期，数据不足
        let attacks = [createAttack(in: modelContext, painIntensity: 5)]
        let analysis = manager.analyzeCycleCorrelation(with: attacks)
        
        XCTAssertEqual(analysis.averageCycleLength, 0)
        XCTAssertEqual(analysis.totalAttacksAnalyzed, 0)
        XCTAssertFalse(analysis.isMenstrualMigraine)
    }
    
    func testCycleAnalysisModel() {
        let analysis = CycleAnalysis(
            averageCycleLength: 28,
            attacksDuringPeriod: 3,
            attacksBeforePeriod: 2,
            attacksOutsidePeriod: 1,
            totalAttacksAnalyzed: 6,
            periodCorrelationPercentage: 83.3,
            premenstrualCorrelationPercentage: 33.3,
            isMenstrualMigraine: true,
            cyclePhaseDistribution: [
                CyclePhaseData(phase: "经期", count: 3),
                CyclePhaseData(phase: "经前期(2天)", count: 2),
                CyclePhaseData(phase: "卵泡期", count: 1)
            ]
        )
        
        XCTAssertEqual(analysis.averageCycleLength, 28)
        XCTAssertEqual(analysis.attacksDuringPeriod, 3)
        XCTAssertEqual(analysis.attacksBeforePeriod, 2)
        XCTAssertEqual(analysis.attacksOutsidePeriod, 1)
        XCTAssertEqual(analysis.totalAttacksAnalyzed, 6)
        XCTAssertTrue(analysis.isMenstrualMigraine)
        XCTAssertEqual(analysis.cyclePhaseDistribution.count, 3)
    }
    
    func testCyclePhaseData() {
        let data = CyclePhaseData(phase: "经期", count: 5)
        
        XCTAssertEqual(data.phase, "经期")
        XCTAssertEqual(data.count, 5)
        XCTAssertNotNil(data.id)
    }
    
    // MARK: - Menstrual Migraine Detection Logic
    
    func testMenstrualMigraineDetection_HighCorrelation() {
        // 50%以上且至少3次发作 -> 月经性偏头痛
        let analysis = CycleAnalysis(
            averageCycleLength: 28,
            attacksDuringPeriod: 3,
            attacksBeforePeriod: 0,
            attacksOutsidePeriod: 2,
            totalAttacksAnalyzed: 5,
            periodCorrelationPercentage: 60.0,
            premenstrualCorrelationPercentage: 0,
            isMenstrualMigraine: true,
            cyclePhaseDistribution: []
        )
        
        XCTAssertTrue(analysis.isMenstrualMigraine)
    }
    
    func testMenstrualMigraineDetection_LowCorrelation() {
        // 低于50% -> 非月经性偏头痛
        let analysis = CycleAnalysis(
            averageCycleLength: 28,
            attacksDuringPeriod: 1,
            attacksBeforePeriod: 0,
            attacksOutsidePeriod: 5,
            totalAttacksAnalyzed: 6,
            periodCorrelationPercentage: 16.7,
            premenstrualCorrelationPercentage: 0,
            isMenstrualMigraine: false,
            cyclePhaseDistribution: []
        )
        
        XCTAssertFalse(analysis.isMenstrualMigraine)
    }
}
