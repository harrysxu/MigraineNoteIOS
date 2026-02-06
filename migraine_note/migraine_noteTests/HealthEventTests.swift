//
//  HealthEventTests.swift
//  migraine_noteTests
//
//  健康事件模型单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class HealthEventTests: XCTestCase {
    
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
    
    func testInit_MedicationEvent() {
        let event = HealthEvent(eventType: .medication)
        
        XCTAssertEqual(event.eventType, .medication)
        XCTAssertEqual(event.eventTypeRawValue, "用药")
    }
    
    func testInit_TCMEvent() {
        let event = HealthEvent(eventType: .tcmTreatment)
        
        XCTAssertEqual(event.eventType, .tcmTreatment)
        XCTAssertEqual(event.eventTypeRawValue, "中医治疗")
    }
    
    func testInit_SurgeryEvent() {
        let event = HealthEvent(eventType: .surgery)
        
        XCTAssertEqual(event.eventType, .surgery)
        XCTAssertEqual(event.eventTypeRawValue, "手术")
    }
    
    func testInit_WithCustomDate() {
        let date = makeDate(year: 2026, month: 1, day: 10)
        let event = HealthEvent(eventType: .medication, eventDate: date)
        
        XCTAssertEqual(event.eventDate, date)
    }
    
    // MARK: - eventType 计算属性测试
    
    func testEventType_SetterUpdatesRawValue() {
        let event = HealthEvent(eventType: .medication)
        event.eventType = .surgery
        
        XCTAssertEqual(event.eventTypeRawValue, "手术")
    }
    
    func testEventType_InvalidRawValue_DefaultsToMedication() {
        let event = HealthEvent(eventType: .medication)
        event.eventTypeRawValue = "无效值"
        
        XCTAssertEqual(event.eventType, .medication)
    }
    
    // MARK: - displayTitle 测试
    
    func testDisplayTitle_MedicationWithNoLogs() {
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        XCTAssertEqual(event.displayTitle, "用药记录")
    }
    
    func testDisplayTitle_MedicationWithOneMedLog() {
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        let med = createMedication(in: modelContext, name: "布洛芬")
        let log = MedicationLog(dosage: 400)
        log.medication = med
        event.medicationLogs = [log]
        modelContext.insert(log)
        
        XCTAssertEqual(event.displayTitle, "布洛芬")
    }
    
    func testDisplayTitle_MedicationWithMultipleLogs() {
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        let med1 = createMedication(in: modelContext, name: "布洛芬")
        let log1 = MedicationLog(dosage: 400)
        log1.medication = med1
        modelContext.insert(log1)
        
        let med2 = createMedication(in: modelContext, name: "佐米曲普坦", category: .triptan)
        let log2 = MedicationLog(dosage: 2.5)
        log2.medication = med2
        modelContext.insert(log2)
        
        event.medicationLogs = [log1, log2]
        
        XCTAssertTrue(event.displayTitle.contains("等2种"))
    }
    
    func testDisplayTitle_TCMTreatment() {
        let event = HealthEvent(eventType: .tcmTreatment)
        event.tcmTreatmentType = "针灸"
        
        XCTAssertEqual(event.displayTitle, "针灸")
    }
    
    func testDisplayTitle_TCMTreatmentDefault() {
        let event = HealthEvent(eventType: .tcmTreatment)
        
        XCTAssertEqual(event.displayTitle, "中医治疗")
    }
    
    func testDisplayTitle_Surgery() {
        let event = HealthEvent(eventType: .surgery)
        event.surgeryName = "微血管减压术"
        
        XCTAssertEqual(event.displayTitle, "微血管减压术")
    }
    
    func testDisplayTitle_SurgeryDefault() {
        let event = HealthEvent(eventType: .surgery)
        
        XCTAssertEqual(event.displayTitle, "手术记录")
    }
    
    // MARK: - displayDetail 测试
    
    func testDisplayDetail_MedicationWithNoLogs_ReturnsNil() {
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        XCTAssertNil(event.displayDetail)
    }
    
    func testDisplayDetail_TCMWithDuration() {
        let event = HealthEvent(eventType: .tcmTreatment)
        event.tcmDuration = 1800 // 30分钟（秒）
        
        XCTAssertEqual(event.displayDetail, "30分钟")
    }
    
    func testDisplayDetail_TCMWithZeroDuration_ReturnsNil() {
        let event = HealthEvent(eventType: .tcmTreatment)
        event.tcmDuration = 0
        
        XCTAssertNil(event.displayDetail)
    }
    
    func testDisplayDetail_SurgeryWithHospitalAndDoctor() {
        let event = HealthEvent(eventType: .surgery)
        event.hospitalName = "北京天坛医院"
        event.doctorName = "张医生"
        
        XCTAssertEqual(event.displayDetail, "北京天坛医院 · 张医生")
    }
    
    func testDisplayDetail_SurgeryWithOnlyHospital() {
        let event = HealthEvent(eventType: .surgery)
        event.hospitalName = "北京天坛医院"
        
        XCTAssertEqual(event.displayDetail, "北京天坛医院")
    }
    
    func testDisplayDetail_SurgeryNoDetails_ReturnsNil() {
        let event = HealthEvent(eventType: .surgery)
        
        XCTAssertNil(event.displayDetail)
    }
    
    // MARK: - medicationLog 兼容属性测试
    
    func testMedicationLog_GetterReturnsFirst() {
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        let log = MedicationLog(dosage: 400)
        modelContext.insert(log)
        event.medicationLogs = [log]
        
        XCTAssertEqual(event.medicationLog?.dosage, 400)
    }
    
    func testMedicationLog_SetterReplacesList() {
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        let log = MedicationLog(dosage: 500)
        modelContext.insert(log)
        event.medicationLog = log
        
        XCTAssertEqual(event.medicationLogs.count, 1)
        XCTAssertEqual(event.medicationLogs.first?.dosage, 500)
    }
    
    func testMedicationLog_SetNilClearsList() {
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        let log = MedicationLog(dosage: 400)
        modelContext.insert(log)
        event.medicationLogs = [log]
        
        event.medicationLog = nil
        XCTAssertTrue(event.medicationLogs.isEmpty)
    }
    
    // MARK: - HealthEventType 枚举测试
    
    func testHealthEventType_AllCases() {
        XCTAssertEqual(HealthEventType.allCases.count, 3)
    }
    
    func testHealthEventType_Icons() {
        XCTAssertFalse(HealthEventType.medication.icon.isEmpty)
        XCTAssertFalse(HealthEventType.tcmTreatment.icon.isEmpty)
        XCTAssertFalse(HealthEventType.surgery.icon.isEmpty)
    }
    
    func testHealthEventType_Colors() {
        XCTAssertFalse(HealthEventType.medication.color.isEmpty)
        XCTAssertFalse(HealthEventType.tcmTreatment.color.isEmpty)
        XCTAssertFalse(HealthEventType.surgery.color.isEmpty)
    }
}
