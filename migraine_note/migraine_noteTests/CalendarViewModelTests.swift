//
//  CalendarViewModelTests.swift
//  migraine_noteTests
//
//  日历ViewModel单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class CalendarViewModelTests: XCTestCase {
    
    var viewModel: CalendarViewModel!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
        viewModel = CalendarViewModel(modelContext: modelContext)
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 月份导航测试
    
    func testMoveToNextMonth() {
        let originalMonth = viewModel.currentMonth
        
        viewModel.moveToNextMonth()
        
        let calendar = Calendar.current
        let originalMonthValue = calendar.component(.month, from: originalMonth)
        let newMonthValue = calendar.component(.month, from: viewModel.currentMonth)
        
        // 考虑年份跨越
        if originalMonthValue == 12 {
            XCTAssertEqual(newMonthValue, 1)
        } else {
            XCTAssertEqual(newMonthValue, originalMonthValue + 1)
        }
    }
    
    func testMoveToPreviousMonth() {
        let originalMonth = viewModel.currentMonth
        
        viewModel.moveToPreviousMonth()
        
        let calendar = Calendar.current
        let originalMonthValue = calendar.component(.month, from: originalMonth)
        let newMonthValue = calendar.component(.month, from: viewModel.currentMonth)
        
        if originalMonthValue == 1 {
            XCTAssertEqual(newMonthValue, 12)
        } else {
            XCTAssertEqual(newMonthValue, originalMonthValue - 1)
        }
    }
    
    func testMoveToToday() {
        // 先移到其他月份
        viewModel.moveToNextMonth()
        viewModel.moveToNextMonth()
        
        viewModel.moveToToday()
        
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(viewModel.currentMonth, equalTo: Date(), toGranularity: .month))
    }
    
    // MARK: - getDaysInMonth 测试
    
    func testGetDaysInMonth_Returns42Days() {
        let days = viewModel.getDaysInMonth()
        
        XCTAssertEqual(days.count, 42, "日历网格应有42个格子（6行x7列）")
    }
    
    func testGetDaysInMonth_ContainsCurrentMonthDates() {
        let days = viewModel.getDaysInMonth()
        let calendar = Calendar.current
        
        let currentMonthDays = days.filter { calendar.isDate($0, equalTo: viewModel.currentMonth, toGranularity: .month) }
        
        let range = calendar.range(of: .day, in: .month, for: viewModel.currentMonth)!
        XCTAssertEqual(currentMonthDays.count, range.count, "应包含当月所有天数")
    }
    
    // MARK: - isDateInCurrentMonth 测试
    
    func testIsDateInCurrentMonth_TodayIsTrue() {
        XCTAssertTrue(viewModel.isDateInCurrentMonth(Date()))
    }
    
    func testIsDateInCurrentMonth_NextMonthIsFalse() {
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        XCTAssertFalse(viewModel.isDateInCurrentMonth(nextMonth))
    }
    
    // MARK: - isToday 测试
    
    func testIsToday_NowIsTrue() {
        XCTAssertTrue(viewModel.isToday(Date()))
    }
    
    func testIsToday_YesterdayIsFalse() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        XCTAssertFalse(viewModel.isToday(yesterday))
    }
    
    // MARK: - 数据访问测试
    
    func testGetAttacks_ForDateWithAttacks() {
        let today = Date()
        createAttack(in: modelContext, startTime: today, painIntensity: 5)
        
        viewModel.loadData()
        
        let attacks = viewModel.getAttacks(for: today)
        XCTAssertEqual(attacks.count, 1)
    }
    
    func testGetAttacks_ForDateWithNoAttacks() {
        viewModel.loadData()
        
        let attacks = viewModel.getAttacks(for: dateAgo(days: 100))
        XCTAssertTrue(attacks.isEmpty)
    }
    
    func testGetMaxPainIntensity() {
        let today = Date()
        createAttack(in: modelContext, startTime: today, painIntensity: 5)
        createAttack(in: modelContext, startTime: today.addingTimeInterval(3600), painIntensity: 8)
        
        viewModel.loadData()
        
        let maxIntensity = viewModel.getMaxPainIntensity(for: today)
        XCTAssertEqual(maxIntensity, 8)
    }
    
    func testGetMaxPainIntensity_NoData_ReturnsNil() {
        viewModel.loadData()
        
        let maxIntensity = viewModel.getMaxPainIntensity(for: dateAgo(days: 100))
        XCTAssertNil(maxIntensity)
    }
    
    func testGetHealthEvents() {
        let today = Date()
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: today)
        createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: today)
        
        viewModel.loadData()
        
        let events = viewModel.getHealthEvents(for: today)
        XCTAssertEqual(events.count, 2)
    }
    
    func testGetHealthEventTypes() {
        let today = Date()
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: today)
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: today)
        createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: today)
        
        viewModel.loadData()
        
        let types = viewModel.getHealthEventTypes(for: today)
        XCTAssertEqual(types.count, 2, "去重后应有2种类型")
        XCTAssertTrue(types.contains(.medication))
        XCTAssertTrue(types.contains(.tcmTreatment))
    }
    
    // MARK: - 月份标题测试
    
    func testMonthTitle() {
        let title = viewModel.monthTitle
        
        XCTAssertFalse(title.isEmpty)
        XCTAssertTrue(title.contains("年"))
        XCTAssertTrue(title.contains("月"))
    }
    
    // MARK: - 月度统计测试
    
    func testMonthlyStats_NoData() {
        viewModel.loadData()
        
        if let stats = viewModel.monthlyStats {
            XCTAssertEqual(stats.totalAttacks, 0)
            XCTAssertEqual(stats.attackDays, 0)
        }
    }
    
    func testMonthlyStats_WithData() {
        createAttack(in: modelContext, startTime: Date(), painIntensity: 5)
        createAttack(in: modelContext, startTime: Date().addingTimeInterval(3600), painIntensity: 7)
        
        viewModel.loadData()
        
        if let stats = viewModel.monthlyStats {
            XCTAssertEqual(stats.totalAttacks, 2)
            XCTAssertEqual(stats.averagePainIntensity, 6.0, accuracy: 0.1)
        }
    }
    
    // MARK: - MonthlyStatistics 测试
    
    func testMonthlyStatistics_IsChronic() {
        let chronic = MonthlyStatistics(
            attackDays: 16, totalAttacks: 20, averagePainIntensity: 6.0,
            mohRisk: .none, averageDuration: 7200,
            acuteMedicationDays: 5, acuteMedicationCount: 5,
            preventiveMedicationDays: 0, preventiveMedicationCount: 0,
            tcmTreatmentCount: 0, surgeryCount: 0
        )
        XCTAssertTrue(chronic.isChronic, "15天以上应为慢性")
        
        let notChronic = MonthlyStatistics(
            attackDays: 10, totalAttacks: 10, averagePainIntensity: 5.0,
            mohRisk: .none, averageDuration: 3600,
            acuteMedicationDays: 3, acuteMedicationCount: 3,
            preventiveMedicationDays: 0, preventiveMedicationCount: 0,
            tcmTreatmentCount: 0, surgeryCount: 0
        )
        XCTAssertFalse(notChronic.isChronic)
    }
    
    func testMonthlyStatistics_FormattedValues() {
        let stats = MonthlyStatistics(
            attackDays: 5, totalAttacks: 8, averagePainIntensity: 6.5,
            mohRisk: .none, averageDuration: 7200,
            acuteMedicationDays: 3, acuteMedicationCount: 5,
            preventiveMedicationDays: 2, preventiveMedicationCount: 2,
            tcmTreatmentCount: 1, surgeryCount: 0
        )
        
        XCTAssertEqual(stats.averageIntensityFormatted, "6.5")
        XCTAssertEqual(stats.averageDurationFormatted, "2.0h")
        XCTAssertEqual(stats.medicationDays, 5)
        XCTAssertEqual(stats.totalMedicationUses, 7)
        XCTAssertTrue(stats.hasPreventiveMedication)
        XCTAssertTrue(stats.hasTCMTreatment)
        XCTAssertFalse(stats.hasSurgery)
    }
    
    // MARK: - 日期选中测试
    
    func testSelectedDateInitiallyNil() {
        XCTAssertNil(viewModel.selectedDate, "初始时不应有选中日期")
    }
    
    func testSelectDate() {
        let date = Date()
        viewModel.selectedDate = date
        
        XCTAssertNotNil(viewModel.selectedDate)
        XCTAssertTrue(Calendar.current.isDate(viewModel.selectedDate!, inSameDayAs: date))
    }
    
    func testDeselectDate() {
        viewModel.selectedDate = Date()
        XCTAssertNotNil(viewModel.selectedDate)
        
        viewModel.selectedDate = nil
        XCTAssertNil(viewModel.selectedDate, "应能取消选中")
    }
    
    func testGetAttacksForSelectedDate() {
        let today = Date()
        let todayStart = Calendar.current.startOfDay(for: today)
        
        createAttack(in: modelContext, startTime: today, painIntensity: 7)
        viewModel.loadData()
        
        let attacks = viewModel.getAttacks(for: todayStart)
        XCTAssertFalse(attacks.isEmpty, "应能获取选中日期的发作记录")
    }
    
    func testGetHealthEventsForSelectedDate() {
        let today = Date()
        let todayStart = Calendar.current.startOfDay(for: today)
        
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: today)
        viewModel.loadData()
        
        let events = viewModel.getHealthEvents(for: todayStart)
        XCTAssertFalse(events.isEmpty, "应能获取选中日期的健康事件")
    }
    
    func testGetAttacksForDateWithNoRecords() {
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        let attacks = viewModel.getAttacks(for: futureDate)
        XCTAssertTrue(attacks.isEmpty, "未来日期不应有记录")
    }
}
