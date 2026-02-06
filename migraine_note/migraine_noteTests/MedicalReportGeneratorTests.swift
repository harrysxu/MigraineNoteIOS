//
//  MedicalReportGeneratorTests.swift
//  migraine_noteTests
//
//  医疗报告生成器单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

@MainActor
final class MedicalReportGeneratorTests: XCTestCase {
    
    var generator: MedicalReportGenerator!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
        generator = MedicalReportGenerator(modelContext: modelContext)
    }
    
    override func tearDown() {
        generator = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 生成报告测试
    
    func testGenerateReport_EmptyData_ReturnsValidPDF() throws {
        let dateRange = DateInterval(start: dateAgo(days: 30), end: Date())
        
        let pdfData = try generator.generateReport(
            attacks: [],
            userProfile: nil,
            dateRange: dateRange
        )
        
        XCTAssertFalse(pdfData.isEmpty, "PDF数据不应为空")
        
        // 检查PDF魔数 (%PDF-)
        let prefix = pdfData.prefix(5)
        let pdfHeader = String(data: prefix, encoding: .ascii)
        XCTAssertEqual(pdfHeader, "%PDF-", "生成的数据应为有效的PDF格式")
    }
    
    func testGenerateReport_WithAttacks_ReturnsValidPDF() throws {
        let attack1 = createCompletedAttack(in: modelContext, startTime: dateAgo(days: 5),
                                             durationHours: 3.0, painIntensity: 7)
        let attack2 = createCompletedAttack(in: modelContext, startTime: dateAgo(days: 10),
                                             durationHours: 2.0, painIntensity: 5)
        
        let dateRange = DateInterval(start: dateAgo(days: 30), end: Date())
        
        let pdfData = try generator.generateReport(
            attacks: [attack1, attack2],
            userProfile: nil,
            dateRange: dateRange
        )
        
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertTrue(pdfData.count > 100, "有数据的报告应比空报告大")
    }
    
    func testGenerateReport_WithUserProfile() throws {
        let profile = UserProfile()
        profile.name = "测试用户"
        profile.age = 35
        profile.gender = .female
        modelContext.insert(profile)
        
        let dateRange = DateInterval(start: dateAgo(days: 30), end: Date())
        
        let pdfData = try generator.generateReport(
            attacks: [],
            userProfile: profile,
            dateRange: dateRange
        )
        
        XCTAssertFalse(pdfData.isEmpty)
    }
    
    func testGenerateReport_WithHealthEvents() throws {
        let event1 = createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 3))
        let event2 = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 5),
                                        tcmTreatmentType: "针灸", tcmDuration: 1800)
        
        let dateRange = DateInterval(start: dateAgo(days: 30), end: Date())
        
        let pdfData = try generator.generateReport(
            attacks: [],
            userProfile: nil,
            dateRange: dateRange,
            healthEvents: [event1, event2]
        )
        
        XCTAssertFalse(pdfData.isEmpty)
    }
    
    func testGenerateReport_FullData() throws {
        // 创建完整的测试数据
        let profile = UserProfile()
        profile.name = "张三"
        profile.age = 30
        modelContext.insert(profile)
        
        let med = createMedication(in: modelContext, name: "布洛芬")
        let attack = createCompletedAttack(in: modelContext, startTime: dateAgo(days: 3),
                                            durationHours: 4.0, painIntensity: 8)
        attack.setPainLocations([.leftTemple])
        attack.setPainQuality([.pulsating])
        createMedicationLog(in: modelContext, medication: med, dosage: 400, attack: attack)
        createSymptom(in: modelContext, type: .nausea, attack: attack)
        createTrigger(in: modelContext, category: .food, specificType: "巧克力", attack: attack)
        
        let dateRange = DateInterval(start: dateAgo(days: 30), end: Date())
        
        let pdfData = try generator.generateReport(
            attacks: [attack],
            userProfile: profile,
            dateRange: dateRange
        )
        
        XCTAssertFalse(pdfData.isEmpty)
        
        let prefix = pdfData.prefix(5)
        let pdfHeader = String(data: prefix, encoding: .ascii)
        XCTAssertEqual(pdfHeader, "%PDF-")
    }
}
