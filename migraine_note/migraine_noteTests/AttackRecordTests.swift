//
//  AttackRecordTests.swift
//  migraine_noteTests
//
//  发作记录模型单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class AttackRecordTests: XCTestCase {
    
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
        let attack = AttackRecord()
        
        XCTAssertNotNil(attack.id)
        XCTAssertEqual(attack.painIntensity, 0)
        XCTAssertNil(attack.endTime)
        XCTAssertTrue(attack.painLocation.isEmpty)
        XCTAssertTrue(attack.painQuality.isEmpty)
        XCTAssertFalse(attack.hasAura)
        XCTAssertTrue(attack.auraTypes.isEmpty)
        XCTAssertTrue(attack.tcmPattern.isEmpty)
        XCTAssertNil(attack.notes)
    }
    
    func testInit_WithStartTime() {
        let date = makeDate(year: 2026, month: 1, day: 15)
        let attack = AttackRecord(startTime: date)
        
        XCTAssertEqual(attack.startTime, date)
    }
    
    // MARK: - Duration 计算测试
    
    func testDuration_WhenOngoing_ReturnsNil() {
        let attack = AttackRecord()
        
        XCTAssertNil(attack.duration, "进行中的发作duration应为nil")
    }
    
    func testDuration_WhenEnded_ReturnsCorrectValue() {
        let start = Date()
        let attack = AttackRecord(startTime: start)
        attack.endTime = start.addingTimeInterval(7200) // 2小时
        
        XCTAssertEqual(attack.duration!, 7200, accuracy: 1, "持续时间应为2小时(7200秒)")
    }
    
    func testDurationOrElapsed_WhenOngoing_ReturnsElapsedTime() {
        let start = Date().addingTimeInterval(-3600) // 1小时前开始
        let attack = AttackRecord(startTime: start)
        
        let elapsed = attack.durationOrElapsed
        XCTAssertTrue(elapsed >= 3599 && elapsed <= 3601, "进行中的durationOrElapsed应约为1小时")
    }
    
    func testDurationOrElapsed_WhenEnded_ReturnsDuration() {
        let start = Date()
        let attack = AttackRecord(startTime: start)
        attack.endTime = start.addingTimeInterval(5400) // 1.5小时
        
        XCTAssertEqual(attack.durationOrElapsed, 5400, accuracy: 1)
    }
    
    // MARK: - isOngoing 测试
    
    func testIsOngoing_WhenNoEndTime_ReturnsTrue() {
        let attack = AttackRecord()
        
        XCTAssertTrue(attack.isOngoing)
    }
    
    func testIsOngoing_WhenHasEndTime_ReturnsFalse() {
        let attack = AttackRecord()
        attack.endTime = Date()
        
        XCTAssertFalse(attack.isOngoing)
    }
    
    // MARK: - PainQuality 枚举转换测试
    
    func testSetPainQuality_ConvertsToStrings() {
        let attack = AttackRecord()
        attack.setPainQuality([.pulsating, .pressing])
        
        XCTAssertEqual(attack.painQuality.count, 2)
        XCTAssertTrue(attack.painQuality.contains("搏动性"))
        XCTAssertTrue(attack.painQuality.contains("压迫感"))
    }
    
    func testPainQualityTypes_ConvertsFromStrings() {
        let attack = AttackRecord()
        attack.painQuality = ["搏动性", "刺痛"]
        
        let types = attack.painQualityTypes
        XCTAssertEqual(types.count, 2)
        XCTAssertTrue(types.contains(.pulsating))
        XCTAssertTrue(types.contains(.stabbing))
    }
    
    func testPainQualityTypes_IgnoresInvalidStrings() {
        let attack = AttackRecord()
        attack.painQuality = ["搏动性", "无效值", "刺痛"]
        
        let types = attack.painQualityTypes
        XCTAssertEqual(types.count, 2, "无效的字符串应被忽略")
    }
    
    // MARK: - AuraType 枚举转换测试
    
    func testSetAuraTypes_ConvertsToStrings() {
        let attack = AttackRecord()
        attack.setAuraTypes([.visualFlashes, .sensoryNumbness])
        
        XCTAssertEqual(attack.auraTypes.count, 2)
        XCTAssertTrue(attack.auraTypes.contains("视觉闪光"))
        XCTAssertTrue(attack.auraTypes.contains("肢体麻木"))
    }
    
    func testAuraTypesList_ConvertsFromStrings() {
        let attack = AttackRecord()
        attack.auraTypes = ["视觉闪光", "视野暗点"]
        
        let types = attack.auraTypesList
        XCTAssertEqual(types.count, 2)
        XCTAssertTrue(types.contains(.visualFlashes))
        XCTAssertTrue(types.contains(.visualScotoma))
    }
    
    // MARK: - TCMPattern 枚举转换测试
    
    func testSetTCMPattern_ConvertsToStrings() {
        let attack = AttackRecord()
        attack.setTCMPattern([.windCold, .liverFire])
        
        XCTAssertEqual(attack.tcmPattern.count, 2)
        XCTAssertTrue(attack.tcmPattern.contains("风寒侵袭"))
        XCTAssertTrue(attack.tcmPattern.contains("肝火上炎"))
    }
    
    func testTcmPatternTypes_ConvertsFromStrings() {
        let attack = AttackRecord()
        attack.tcmPattern = ["风寒侵袭", "湿邪困阻"]
        
        let types = attack.tcmPatternTypes
        XCTAssertEqual(types.count, 2)
        XCTAssertTrue(types.contains(.windCold))
        XCTAssertTrue(types.contains(.dampness))
    }
    
    // MARK: - PainLocation 枚举转换测试
    
    func testSetPainLocations_ConvertsToStrings() {
        let attack = AttackRecord()
        attack.setPainLocations([.forehead, .leftTemple])
        
        XCTAssertEqual(attack.painLocation.count, 2)
        XCTAssertTrue(attack.painLocation.contains("forehead"))
        XCTAssertTrue(attack.painLocation.contains("left_temple"))
    }
    
    func testPainLocations_ConvertsFromStrings() {
        let attack = AttackRecord()
        attack.painLocation = ["forehead", "occipital"]
        
        let locations = attack.painLocations
        XCTAssertEqual(locations.count, 2)
        XCTAssertTrue(locations.contains(.forehead))
        XCTAssertTrue(locations.contains(.occipital))
    }
    
    // MARK: - 关系访问测试
    
    func testSymptoms_DefaultEmpty() {
        let attack = AttackRecord()
        modelContext.insert(attack)
        
        XCTAssertTrue(attack.symptoms.isEmpty)
    }
    
    func testTriggers_DefaultEmpty() {
        let attack = AttackRecord()
        modelContext.insert(attack)
        
        XCTAssertTrue(attack.triggers.isEmpty)
    }
    
    func testMedications_DefaultEmpty() {
        let attack = AttackRecord()
        modelContext.insert(attack)
        
        XCTAssertTrue(attack.medications.isEmpty)
    }
    
    func testMedicationLogs_IsSameAsMedications() {
        let attack = AttackRecord()
        modelContext.insert(attack)
        
        XCTAssertEqual(attack.medicationLogs.count, attack.medications.count)
    }
}
