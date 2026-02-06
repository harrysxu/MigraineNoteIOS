//
//  DateExtensionsTests.swift
//  migraine_noteTests
//
//  日期扩展方法单元测试
//

import XCTest
@testable import migraine_note

final class DateExtensionsTests: XCTestCase {
    
    // MARK: - smartFormatted 测试
    
    func testSmartFormatted_Today() {
        let now = Date()
        let result = now.smartFormatted()
        
        XCTAssertTrue(result.hasPrefix("今天"), "今天的日期应以'今天'开头")
        XCTAssertTrue(result.contains(":"), "应包含时间分隔符")
    }
    
    func testSmartFormatted_Yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = yesterday.smartFormatted()
        
        XCTAssertTrue(result.hasPrefix("昨天"), "昨天的日期应以'昨天'开头")
    }
    
    func testSmartFormatted_OtherDate() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let result = oldDate.smartFormatted()
        
        XCTAssertTrue(result.contains("月"), "其他日期应包含'月'")
        XCTAssertTrue(result.contains("日"), "其他日期应包含'日'")
    }
    
    // MARK: - shortTime 测试
    
    func testShortTime_Format() {
        let date = makeDate(year: 2026, month: 1, day: 15, hour: 14, minute: 30)
        let result = date.shortTime()
        
        XCTAssertEqual(result, "14:30")
    }
    
    // MARK: - fullDate 测试
    
    func testFullDate_Format() {
        let date = makeDate(year: 2026, month: 2, day: 6)
        let result = date.fullDate()
        
        XCTAssertEqual(result, "2026年02月06日")
    }
    
    // MARK: - fullDateTime 测试
    
    func testFullDateTime_Format() {
        let date = makeDate(year: 2026, month: 2, day: 6, hour: 14, minute: 30)
        let result = date.fullDateTime()
        
        XCTAssertEqual(result, "2026年02月06日 14:30")
    }
    
    // MARK: - monthTitle 测试
    
    func testMonthTitle_Format() {
        let date = makeDate(year: 2026, month: 2, day: 1)
        let result = date.monthTitle()
        
        XCTAssertEqual(result, "2026年2月")
    }
    
    // MARK: - monthName 测试
    
    func testMonthName_Format() {
        let date = makeDate(year: 2026, month: 12, day: 1)
        let result = date.monthName()
        
        XCTAssertEqual(result, "12月")
    }
    
    // MARK: - compactDate 测试
    
    func testCompactDate_Format() {
        let date = makeDate(year: 2026, month: 2, day: 6)
        let result = date.compactDate()
        
        XCTAssertEqual(result, "20260206")
    }
    
    // MARK: - compactDateTime 测试
    
    func testCompactDateTime_Format() {
        let date = makeDate(year: 2026, month: 2, day: 6, hour: 14, minute: 30)
        let result = date.compactDateTime()
        
        XCTAssertEqual(result, "02/06 14:30")
    }
    
    // MARK: - reportDateTime 测试
    
    func testReportDateTime_Format() {
        let date = makeDate(year: 2026, month: 2, day: 6, hour: 14, minute: 30)
        let result = date.reportDateTime()
        
        XCTAssertEqual(result, "2026-02-06 14:30")
    }
    
    // MARK: - briefDateTime 测试
    
    func testBriefDateTime_Format() {
        let date = makeDate(year: 2026, month: 2, day: 6, hour: 14, minute: 30)
        let result = date.briefDateTime()
        
        XCTAssertEqual(result, "02.06 14:30")
    }
    
    // MARK: - year 测试
    
    func testYear() {
        let date = makeDate(year: 2026, month: 1, day: 1)
        
        XCTAssertEqual(date.year, 2026)
    }
    
    func testYear_DifferentYears() {
        XCTAssertEqual(makeDate(year: 2025, month: 6, day: 15).year, 2025)
        XCTAssertEqual(makeDate(year: 2030, month: 12, day: 31).year, 2030)
    }
    
    // MARK: - yearTitle 测试
    
    func testYearTitle() {
        let date = makeDate(year: 2026, month: 1, day: 1)
        
        XCTAssertEqual(date.yearTitle(), "2026年")
    }
    
    // MARK: - startOfDay 测试
    
    func testStartOfDay() {
        let date = makeDate(year: 2026, month: 2, day: 6, hour: 14, minute: 30)
        let start = date.startOfDay()
        
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: start), 0)
        XCTAssertEqual(calendar.component(.minute, from: start), 0)
        XCTAssertEqual(calendar.component(.second, from: start), 0)
        XCTAssertEqual(calendar.component(.day, from: start), 6)
    }
    
    // MARK: - endOfDay 测试
    
    func testEndOfDay() {
        let date = makeDate(year: 2026, month: 2, day: 6, hour: 10)
        let end = date.endOfDay()
        
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: end), 23)
        XCTAssertEqual(calendar.component(.minute, from: end), 59)
        XCTAssertEqual(calendar.component(.second, from: end), 59)
        XCTAssertEqual(calendar.component(.day, from: end), 6)
    }
    
    func testEndOfDay_SameDayAsStartOfDay() {
        let date = makeDate(year: 2026, month: 2, day: 6, hour: 14)
        let start = date.startOfDay()
        let end = date.endOfDay()
        
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(start, inSameDayAs: end))
    }
    
    // MARK: - normalizedDateRange 测试
    
    func testNormalizedDateRange() {
        let start = makeDate(year: 2026, month: 1, day: 1, hour: 14, minute: 30)
        let end = makeDate(year: 2026, month: 1, day: 31, hour: 10, minute: 0)
        
        let (normalizedStart, normalizedEnd) = Date.normalizedDateRange(start: start, end: end)
        
        let calendar = Calendar.current
        
        // 开始日期应为当天00:00
        XCTAssertEqual(calendar.component(.hour, from: normalizedStart), 0)
        XCTAssertEqual(calendar.component(.minute, from: normalizedStart), 0)
        
        // 结束日期应为当天23:59
        XCTAssertEqual(calendar.component(.hour, from: normalizedEnd), 23)
        XCTAssertEqual(calendar.component(.minute, from: normalizedEnd), 59)
    }
    
    func testNormalizedDateRange_PreservesDay() {
        let start = makeDate(year: 2026, month: 2, day: 1, hour: 15)
        let end = makeDate(year: 2026, month: 2, day: 28, hour: 8)
        
        let (normalizedStart, normalizedEnd) = Date.normalizedDateRange(start: start, end: end)
        
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.day, from: normalizedStart), 1)
        XCTAssertEqual(calendar.component(.day, from: normalizedEnd), 28)
    }
}
