//
//  CSVExporterTests.swift
//  migraine_noteTests
//
//  CSV导出工具单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class CSVExporterTests: XCTestCase {
    
    var exporter: CSVExporter!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        exporter = CSVExporter()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        exporter = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - UTF-8 BOM 测试
    
    func testExportAttacks_HasBOM() {
        let data = exporter.exportAttacks([])
        // UTF-8 BOM 的字节序列是 EF BB BF
        let bomBytes: [UInt8] = [0xEF, 0xBB, 0xBF]
        let dataBytes = Array(data.prefix(3))
        
        XCTAssertEqual(dataBytes, bomBytes, "CSV应以UTF-8 BOM开头")
    }
    
    func testExportHealthEvents_HasBOM() {
        let data = exporter.exportHealthEvents([])
        // UTF-8 BOM 的字节序列是 EF BB BF
        let bomBytes: [UInt8] = [0xEF, 0xBB, 0xBF]
        let dataBytes = Array(data.prefix(3))
        
        XCTAssertEqual(dataBytes, bomBytes, "CSV应以UTF-8 BOM开头")
    }
    
    // MARK: - exportAttacks 测试
    
    func testExportAttacks_EmptyData_HasHeaders() {
        let data = exporter.exportAttacks([])
        let string = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(string.contains("记录ID"))
        XCTAssertTrue(string.contains("发作日期"))
        XCTAssertTrue(string.contains("疼痛强度"))
    }
    
    func testExportAttacks_WithData() {
        let attack = createCompletedAttack(in: modelContext, startTime: dateAgo(days: 1),
                                            durationHours: 2.0, painIntensity: 7)
        
        let data = exporter.exportAttacks([attack])
        let string = String(data: data, encoding: .utf8)!
        let lines = string.components(separatedBy: "\n")
        
        // BOM行 + 表头 + 1条数据 + 空行
        XCTAssertGreaterThanOrEqual(lines.count, 2, "应至少有表头和1条数据")
        XCTAssertTrue(string.contains("7"), "应包含疼痛强度7")
    }
    
    func testExportAttacks_MultipleRecords_Sorted() {
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 5), painIntensity: 3)
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 7)
        
        let data = exporter.exportAttacks([attack2, attack1]) // 故意乱序传入
        let string = String(data: data, encoding: .utf8)!
        
        // 验证输出是按时间排序的（attack1在前因为更早）
        let id1Position = string.range(of: attack1.id.uuidString)
        let id2Position = string.range(of: attack2.id.uuidString)
        
        XCTAssertNotNil(id1Position)
        XCTAssertNotNil(id2Position)
        if let p1 = id1Position, let p2 = id2Position {
            XCTAssertTrue(p1.lowerBound < p2.lowerBound, "较早的记录应在前面")
        }
    }
    
    // MARK: - exportHealthEvents 测试
    
    func testExportHealthEvents_EmptyData_HasHeaders() {
        let data = exporter.exportHealthEvents([])
        let string = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(string.contains("事件ID"))
        XCTAssertTrue(string.contains("事件类型"))
    }
    
    func testExportHealthEvents_MedicationEvent() {
        let event = createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 1))
        
        let data = exporter.exportHealthEvents([event])
        let string = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(string.contains("用药"))
    }
    
    func testExportHealthEvents_TCMEvent() {
        let event = createHealthEvent(in: modelContext, eventType: .tcmTreatment,
                                       eventDate: dateAgo(days: 1), tcmTreatmentType: "针灸",
                                       tcmDuration: 1800)
        
        let data = exporter.exportHealthEvents([event])
        let string = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(string.contains("中医治疗"))
        XCTAssertTrue(string.contains("针灸"))
    }
    
    func testExportHealthEvents_SurgeryEvent() {
        let event = createHealthEvent(in: modelContext, eventType: .surgery,
                                       eventDate: dateAgo(days: 1), surgeryName: "微血管减压术",
                                       hospitalName: "天坛医院", doctorName: "张医生")
        
        let data = exporter.exportHealthEvents([event])
        let string = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(string.contains("手术"))
        XCTAssertTrue(string.contains("微血管减压术"))
        XCTAssertTrue(string.contains("天坛医院"))
    }
    
    // MARK: - generateFilename 测试
    
    func testGenerateFilename_WithPrefix() {
        let filename = exporter.generateFilename(prefix: "偏头痛记录")
        
        XCTAssertTrue(filename.hasPrefix("偏头痛记录_"))
        XCTAssertTrue(filename.hasSuffix(".csv"))
    }
    
    func testGenerateFilename_WithDateRange() {
        let start = makeDate(year: 2026, month: 1, day: 1)
        let end = makeDate(year: 2026, month: 1, day: 31)
        let filename = exporter.generateFilename(prefix: "报告", dateRange: (start, end))
        
        XCTAssertTrue(filename.contains("2026-01-01"))
        XCTAssertTrue(filename.contains("2026-01-31"))
        XCTAssertTrue(filename.hasSuffix(".csv"))
    }
    
    // MARK: - 数据完整性测试
    
    func testExportAttacks_ReturnsNonEmptyData() {
        let data = exporter.exportAttacks([])
        XCTAssertFalse(data.isEmpty, "即使无记录，也应返回非空数据（表头）")
    }
    
    func testExportHealthEvents_ReturnsNonEmptyData() {
        let data = exporter.exportHealthEvents([])
        XCTAssertFalse(data.isEmpty)
    }
}
