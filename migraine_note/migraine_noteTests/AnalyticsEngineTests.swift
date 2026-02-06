//
//  AnalyticsEngineTests.swift
//  migraine_noteTests
//
//  数据分析引擎单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class AnalyticsEngineTests: XCTestCase {
    
    var engine: AnalyticsEngine!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
        engine = AnalyticsEngine(modelContext: modelContext)
    }
    
    override func tearDown() {
        engine = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 月度统计测试
    
    func testMonthlyStats_EmptyData() throws {
        let stats = try engine.calculateMonthlyStats(for: Date())
        
        XCTAssertEqual(stats.totalAttacks, 0, "总发作次数应为0")
        XCTAssertEqual(stats.averagePainIntensity, 0, "平均强度应为0")
        XCTAssertEqual(stats.medicationDays, 0, "用药天数应为0")
        XCTAssertFalse(stats.mohRisk, "无用药不应有MOH风险")
    }
    
    func testMonthlyStats_WithData() throws {
        // 确保所有日期在当前月内（calculateMonthlyStats只查当月）
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let day1 = calendar.date(byAdding: .day, value: 1, to: startOfMonth)!
        let day2 = calendar.date(byAdding: .day, value: 2, to: startOfMonth)!
        let day3 = calendar.date(byAdding: .day, value: 3, to: startOfMonth)!
        
        createAttack(in: modelContext, startTime: day1, painIntensity: 5)
        createAttack(in: modelContext, startTime: day2, painIntensity: 7)
        createAttack(in: modelContext, startTime: day3, painIntensity: 4)
        
        let stats = try engine.calculateMonthlyStats(for: Date())
        
        XCTAssertEqual(stats.totalAttacks, 3, "总发作次数应为3")
        let expectedAvg = (5.0 + 7.0 + 4.0) / 3.0
        XCTAssertEqual(stats.averagePainIntensity, expectedAvg, accuracy: 0.1, "平均强度应约为5.33")
    }
    
    func testMonthlyStats_MohRisk() throws {
        // 创建11天的用药记录（超过10天阈值），确保在当月内
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let med = createMedication(in: modelContext, name: "布洛芬")
        
        for i in 0..<11 {
            let date = calendar.date(byAdding: .day, value: i, to: startOfMonth)!
            let attack = createAttack(in: modelContext, startTime: date, painIntensity: 5)
            createMedicationLog(in: modelContext, medication: med, dosage: 400, timeTaken: date, attack: attack)
        }
        
        let stats = try engine.calculateMonthlyStats(for: Date())
        XCTAssertTrue(stats.mohRisk, "用药超过10天应有MOH风险")
    }
    
    func testMonthlyStats_DisabilityLevel() {
        // 测试 MonthlyStats 的 disabilityLevel
        let minimal = MonthlyStats(totalAttacks: 3, averagePainIntensity: 4, medicationDays: 1, mohRisk: false)
        XCTAssertEqual(minimal.disabilityLevel, .minimal)
        
        let mild = MonthlyStats(totalAttacks: 7, averagePainIntensity: 5, medicationDays: 3, mohRisk: false)
        XCTAssertEqual(mild.disabilityLevel, .mild)
        
        let moderate = MonthlyStats(totalAttacks: 12, averagePainIntensity: 6, medicationDays: 5, mohRisk: false)
        XCTAssertEqual(moderate.disabilityLevel, .moderate)
        
        let chronic = MonthlyStats(totalAttacks: 16, averagePainIntensity: 7, medicationDays: 10, mohRisk: true)
        XCTAssertEqual(chronic.disabilityLevel, .chronic)
    }
    
    // MARK: - 诱因频次分析测试
    
    func testTriggerFrequency_NoTriggers() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        
        let dateRange = (dateAgo(days: 30), Date())
        let result = engine.analyzeTriggerFrequency(in: dateRange)
        
        XCTAssertTrue(result.isEmpty, "没有诱因应返回空数组")
    }
    
    func testTriggerFrequency_WithTriggers() {
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        createTrigger(in: modelContext, category: .food, specificType: "巧克力", attack: attack1)
        
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 6)
        createTrigger(in: modelContext, category: .food, specificType: "巧克力", attack: attack2)
        createTrigger(in: modelContext, category: .sleep, specificType: "睡眠不足", attack: attack2)
        
        let dateRange = (dateAgo(days: 30), Date())
        let result = engine.analyzeTriggerFrequency(in: dateRange)
        
        XCTAssertEqual(result.count, 2, "应有2个不同的诱因")
        
        let chocolate = result.first { $0.triggerName == "巧克力" }
        XCTAssertEqual(chocolate?.count, 2, "巧克力应出现2次")
        
        let sleep = result.first { $0.triggerName == "睡眠不足" }
        XCTAssertEqual(sleep?.count, 1, "睡眠不足应出现1次")
    }
    
    // MARK: - 昼夜节律分析测试
    
    func testCircadianPattern_Distribution() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1, hour: 8), painIntensity: 5)
        createAttack(in: modelContext, startTime: dateAgo(days: 2, hour: 14), painIntensity: 6)
        createAttack(in: modelContext, startTime: dateAgo(days: 3, hour: 20), painIntensity: 7)
        createAttack(in: modelContext, startTime: dateAgo(days: 4, hour: 8), painIntensity: 8)
        
        let dateRange = (dateAgo(days: 30), Date())
        let result = engine.analyzeCircadianPattern(in: dateRange)
        
        XCTAssertEqual(result.count, 24, "应返回24个小时的数据")
        
        let morning8 = result.first { $0.hour == 8 }
        XCTAssertEqual(morning8?.count, 2, "早上8点应有2次发作")
        
        let afternoon2 = result.first { $0.hour == 14 }
        XCTAssertEqual(afternoon2?.count, 1, "下午2点应有1次发作")
    }
    
    // MARK: - 疼痛强度分布测试
    
    func testPainIntensityDistribution_Empty() {
        let dateRange = (dateAgo(days: 30), Date())
        let dist = engine.analyzePainIntensityDistribution(in: dateRange)
        
        XCTAssertEqual(dist.mild, 0)
        XCTAssertEqual(dist.moderate, 0)
        XCTAssertEqual(dist.severe, 0)
        XCTAssertEqual(dist.total, 0)
    }
    
    func testPainIntensityDistribution_Classification() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 2) // 轻度
        createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 3) // 轻度
        createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 5) // 中度
        createAttack(in: modelContext, startTime: dateAgo(days: 4), painIntensity: 8) // 重度
        createAttack(in: modelContext, startTime: dateAgo(days: 5), painIntensity: 10) // 重度
        
        let dateRange = (dateAgo(days: 30), Date())
        let dist = engine.analyzePainIntensityDistribution(in: dateRange)
        
        XCTAssertEqual(dist.mild, 2, "轻度(1-3)应为2次")
        XCTAssertEqual(dist.moderate, 1, "中度(4-6)应为1次")
        XCTAssertEqual(dist.severe, 2, "重度(7-10)应为2次")
        XCTAssertEqual(dist.total, 5)
    }
    
    func testPainIntensityDistribution_Percentages() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 2)
        createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 5)
        createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 5)
        createAttack(in: modelContext, startTime: dateAgo(days: 4), painIntensity: 8)
        
        let dateRange = (dateAgo(days: 30), Date())
        let dist = engine.analyzePainIntensityDistribution(in: dateRange)
        
        XCTAssertEqual(dist.mildPercentage, 25.0, accuracy: 0.1)
        XCTAssertEqual(dist.moderatePercentage, 50.0, accuracy: 0.1)
        XCTAssertEqual(dist.severePercentage, 25.0, accuracy: 0.1)
    }
    
    // MARK: - 疼痛部位频次测试
    
    func testPainLocationFrequency() {
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5,
                                    painLocations: [.leftTemple, .forehead])
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 6,
                                    painLocations: [.leftTemple])
        
        let dateRange = (dateAgo(days: 30), Date())
        let result = engine.analyzePainLocationFrequency(in: dateRange)
        
        XCTAssertFalse(result.isEmpty)
        let leftTemple = result.first { $0.locationName == PainLocation.leftTemple.displayName }
        XCTAssertEqual(leftTemple?.count, 2)
    }
    
    // MARK: - 疼痛性质频次测试
    
    func testPainQualityFrequency() {
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5,
                                    painQualities: [.pulsating, .pressing])
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 6,
                                    painQualities: [.pulsating])
        
        let dateRange = (dateAgo(days: 30), Date())
        let result = engine.analyzePainQualityFrequency(in: dateRange)
        
        let pulsating = result.first { $0.qualityName == PainQuality.pulsating.rawValue }
        XCTAssertEqual(pulsating?.count, 2)
    }
    
    // MARK: - 症状频次测试
    
    func testSymptomFrequency() {
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        createSymptom(in: modelContext, type: .nausea, attack: attack1)
        createSymptom(in: modelContext, type: .photophobia, attack: attack1)
        
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 6)
        createSymptom(in: modelContext, type: .nausea, attack: attack2)
        
        let dateRange = (dateAgo(days: 30), Date())
        let result = engine.analyzeSymptomFrequency(in: dateRange)
        
        let nausea = result.first { $0.symptomName == "恶心" }
        XCTAssertEqual(nausea?.count, 2)
        
        let photophobia = result.first { $0.symptomName == "畏光" }
        XCTAssertEqual(photophobia?.count, 1)
    }
    
    // MARK: - 先兆统计测试
    
    func testAuraStatistics_NoAura() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeAuraStatistics(in: dateRange)
        
        XCTAssertEqual(stats.totalAttacks, 1)
        XCTAssertEqual(stats.attacksWithAura, 0)
        XCTAssertEqual(stats.auraPercentage, 0)
    }
    
    func testAuraStatistics_WithAura() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5,
                     hasAura: true, auraTypes: [.visualFlashes])
        createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 6,
                     hasAura: true, auraTypes: [.visualFlashes, .sensoryNumbness])
        createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 4)
        
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeAuraStatistics(in: dateRange)
        
        XCTAssertEqual(stats.totalAttacks, 3)
        XCTAssertEqual(stats.attacksWithAura, 2)
        XCTAssertEqual(stats.auraPercentage, 200.0 / 3.0, accuracy: 0.1)
        
        let visualFlash = stats.auraTypeFrequency.first { $0.typeName == "视觉闪光" }
        XCTAssertEqual(visualFlash?.count, 2)
    }
    
    // MARK: - 持续时间统计测试
    
    func testDurationStatistics_NoCompletedAttacks() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5) // 进行中
        
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeDurationStatistics(in: dateRange)
        
        XCTAssertEqual(stats.averageDuration, 0)
        XCTAssertEqual(stats.longestDuration, 0)
        XCTAssertEqual(stats.shortestDuration, 0)
    }
    
    func testDurationStatistics_WithCompletedAttacks() {
        createCompletedAttack(in: modelContext, startTime: dateAgo(days: 1), durationHours: 2.0, painIntensity: 5)
        createCompletedAttack(in: modelContext, startTime: dateAgo(days: 2), durationHours: 4.0, painIntensity: 6)
        createCompletedAttack(in: modelContext, startTime: dateAgo(days: 3), durationHours: 6.0, painIntensity: 7)
        
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeDurationStatistics(in: dateRange)
        
        XCTAssertEqual(stats.averageDurationHours, 4.0, accuracy: 0.1)
        XCTAssertEqual(stats.longestDurationHours, 6.0, accuracy: 0.1)
        XCTAssertEqual(stats.shortestDurationHours, 2.0, accuracy: 0.1)
    }
    
    // MARK: - 星期分布测试
    
    func testWeekdayDistribution() {
        let dateRange = (dateAgo(days: 30), Date())
        let result = engine.analyzeWeekdayDistribution(in: dateRange)
        
        XCTAssertEqual(result.count, 7, "应返回7天的数据")
        XCTAssertEqual(result[0].weekdayName, "周日")
        XCTAssertEqual(result[6].weekdayName, "周六")
    }
    
    // MARK: - 用药统计测试
    
    func testMedicationUsage_Empty() {
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeMedicationUsage(in: dateRange)
        
        XCTAssertEqual(stats.totalMedicationUses, 0)
        XCTAssertEqual(stats.medicationDays, 0)
        XCTAssertTrue(stats.categoryBreakdown.isEmpty)
        XCTAssertTrue(stats.topMedications.isEmpty)
    }
    
    func testMedicationUsage_WithData() {
        let med = createMedication(in: modelContext, name: "布洛芬")
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack1)
        
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 6)
        createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack2)
        
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeMedicationUsage(in: dateRange)
        
        XCTAssertEqual(stats.totalMedicationUses, 2)
        XCTAssertEqual(stats.medicationDays, 2)
        XCTAssertFalse(stats.topMedications.isEmpty)
    }
    
    // MARK: - 用药依从性测试
    
    func testMedicationAdherence() {
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 1))
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 3))
        
        let dateRange = (dateAgo(days: 10), Date())
        let stats = engine.analyzeMedicationAdherence(in: dateRange)
        
        XCTAssertEqual(stats.totalDays, 10)
        XCTAssertEqual(stats.medicationDays, 2)
        XCTAssertEqual(stats.missedDays, 8)
        XCTAssertEqual(stats.adherenceRate, 20.0, accuracy: 0.1)
    }
    
    // MARK: - 中医治疗统计测试
    
    func testTCMTreatment_Empty() {
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeTCMTreatment(in: dateRange)
        
        XCTAssertEqual(stats.totalTreatments, 0)
        XCTAssertTrue(stats.treatmentTypes.isEmpty)
    }
    
    func testTCMTreatment_WithData() {
        let event1 = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 1),
                                        tcmTreatmentType: "针灸", tcmDuration: 1800)
        let event2 = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 5),
                                        tcmTreatmentType: "针灸", tcmDuration: 2400)
        let event3 = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 10),
                                        tcmTreatmentType: "推拿按摩", tcmDuration: 3600)
        
        let dateRange = (dateAgo(days: 30), Date())
        let stats = engine.analyzeTCMTreatment(in: dateRange)
        
        XCTAssertEqual(stats.totalTreatments, 3)
        
        let acupuncture = stats.treatmentTypes.first { $0.typeName == "针灸" }
        XCTAssertEqual(acupuncture?.count, 2)
    }
}
