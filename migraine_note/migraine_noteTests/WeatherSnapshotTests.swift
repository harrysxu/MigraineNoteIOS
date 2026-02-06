//
//  WeatherSnapshotTests.swift
//  migraine_noteTests
//
//  天气快照模型单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class WeatherSnapshotTests: XCTestCase {
    
    // MARK: - 初始化测试
    
    func testInit_DefaultValues() {
        let snapshot = WeatherSnapshot()
        
        XCTAssertEqual(snapshot.pressure, 0)
        XCTAssertEqual(snapshot.temperature, 0)
        XCTAssertEqual(snapshot.humidity, 0)
        XCTAssertEqual(snapshot.windSpeed, 0)
        XCTAssertEqual(snapshot.condition, "")
        XCTAssertEqual(snapshot.location, "")
        XCTAssertFalse(snapshot.isManuallyEdited)
    }
    
    func testInit_WithTimestamp() {
        let date = makeDate(year: 2026, month: 1, day: 15)
        let snapshot = WeatherSnapshot(timestamp: date)
        
        XCTAssertEqual(snapshot.timestamp, date)
    }
    
    // MARK: - pressureTrend 计算属性测试
    
    func testPressureTrend_DefaultSteady() {
        let snapshot = WeatherSnapshot()
        
        XCTAssertEqual(snapshot.pressureTrend, .steady)
    }
    
    func testPressureTrend_SetterUpdatesRawValue() {
        let snapshot = WeatherSnapshot()
        snapshot.pressureTrend = .falling
        
        XCTAssertEqual(snapshot.pressureTrendRawValue, "下降")
    }
    
    func testPressureTrend_GetterConvertsFromRawValue() {
        let snapshot = WeatherSnapshot()
        snapshot.pressureTrendRawValue = "上升"
        
        XCTAssertEqual(snapshot.pressureTrend, .rising)
    }
    
    func testPressureTrend_InvalidRawValue_DefaultsSteady() {
        let snapshot = WeatherSnapshot()
        snapshot.pressureTrendRawValue = "无效"
        
        XCTAssertEqual(snapshot.pressureTrend, .steady)
    }
    
    // MARK: - isHighRisk 测试
    
    func testIsHighRisk_NormalConditions_ReturnsFalse() {
        let snapshot = WeatherSnapshot()
        snapshot.pressure = 1013
        snapshot.humidity = 50
        snapshot.temperature = 25
        snapshot.pressureTrend = .steady
        
        XCTAssertFalse(snapshot.isHighRisk)
    }
    
    func testIsHighRisk_FallingPressureBelow1010_ReturnsTrue() {
        let snapshot = WeatherSnapshot()
        snapshot.pressure = 1005
        snapshot.pressureTrend = .falling
        
        XCTAssertTrue(snapshot.isHighRisk, "气压骤降且低于1010应为高风险")
    }
    
    func testIsHighRisk_FallingPressureAbove1010_ReturnsFalse() {
        let snapshot = WeatherSnapshot()
        snapshot.pressure = 1015
        snapshot.pressureTrend = .falling
        
        XCTAssertFalse(snapshot.isHighRisk, "气压下降但高于1010不算高风险")
    }
    
    func testIsHighRisk_HighHumidity_ReturnsTrue() {
        let snapshot = WeatherSnapshot()
        snapshot.humidity = 85
        snapshot.pressure = 1013
        snapshot.temperature = 25
        
        XCTAssertTrue(snapshot.isHighRisk, "湿度>80应为高风险")
    }
    
    func testIsHighRisk_HighTemperature_ReturnsTrue() {
        let snapshot = WeatherSnapshot()
        snapshot.temperature = 36
        snapshot.humidity = 50
        snapshot.pressure = 1013
        
        XCTAssertTrue(snapshot.isHighRisk, "温度>35应为高风险")
    }
    
    func testIsHighRisk_LowTemperature_ReturnsTrue() {
        let snapshot = WeatherSnapshot()
        snapshot.temperature = -1
        snapshot.humidity = 50
        snapshot.pressure = 1013
        
        XCTAssertTrue(snapshot.isHighRisk, "温度<0应为高风险")
    }
    
    // MARK: - riskWarning 测试
    
    func testRiskWarning_NormalConditions_ReturnsNil() {
        let snapshot = WeatherSnapshot()
        snapshot.pressure = 1013
        snapshot.humidity = 50
        snapshot.temperature = 25
        snapshot.pressureTrend = .steady
        
        XCTAssertNil(snapshot.riskWarning)
    }
    
    func testRiskWarning_FallingPressure_ReturnsWarning() {
        let snapshot = WeatherSnapshot()
        snapshot.pressure = 1005
        snapshot.pressureTrend = .falling
        
        XCTAssertNotNil(snapshot.riskWarning)
        XCTAssertTrue(snapshot.riskWarning!.contains("气压骤降"))
    }
    
    func testRiskWarning_HighHumidity_ReturnsWarning() {
        let snapshot = WeatherSnapshot()
        snapshot.humidity = 85
        snapshot.pressure = 1013
        snapshot.temperature = 25
        
        XCTAssertNotNil(snapshot.riskWarning)
        XCTAssertTrue(snapshot.riskWarning!.contains("高湿度"))
    }
    
    func testRiskWarning_HighTemperature_ReturnsWarning() {
        let snapshot = WeatherSnapshot()
        snapshot.temperature = 38
        snapshot.humidity = 50
        snapshot.pressure = 1013
        
        XCTAssertTrue(snapshot.riskWarning!.contains("高温"))
    }
    
    func testRiskWarning_LowTemperature_ReturnsWarning() {
        let snapshot = WeatherSnapshot()
        snapshot.temperature = -5
        snapshot.humidity = 50
        snapshot.pressure = 1013
        
        XCTAssertTrue(snapshot.riskWarning!.contains("保暖"))
    }
    
    // MARK: - warnings 数组测试
    
    func testWarnings_NormalConditions_Empty() {
        let snapshot = WeatherSnapshot()
        snapshot.pressure = 1013
        snapshot.humidity = 50
        snapshot.temperature = 25
        snapshot.pressureTrend = .steady
        
        XCTAssertTrue(snapshot.warnings.isEmpty)
    }
    
    func testWarnings_MultipleRisks() {
        let snapshot = WeatherSnapshot()
        snapshot.pressure = 1005
        snapshot.pressureTrend = .falling
        snapshot.humidity = 85
        snapshot.temperature = 25
        
        XCTAssertEqual(snapshot.warnings.count, 2, "气压骤降+高湿度应有2个警告")
    }
    
    func testWarnings_HighAndLowTempExclusive() {
        // 不可能同时高温和低温，warnings中温度只取一个
        let snapshot = WeatherSnapshot()
        snapshot.temperature = 36
        snapshot.humidity = 50
        snapshot.pressure = 1013
        
        let hasHighTemp = snapshot.warnings.contains { $0.contains("高温") }
        let hasLowTemp = snapshot.warnings.contains { $0.contains("保暖") }
        
        XCTAssertTrue(hasHighTemp)
        XCTAssertFalse(hasLowTemp)
    }
    
    // MARK: - PressureTrend 枚举测试
    
    func testPressureTrend_AllCases() {
        XCTAssertEqual(PressureTrend.allCases.count, 3)
    }
    
    func testPressureTrend_Icons() {
        XCTAssertEqual(PressureTrend.rising.icon, "arrow.up")
        XCTAssertEqual(PressureTrend.falling.icon, "arrow.down")
        XCTAssertEqual(PressureTrend.steady.icon, "minus")
    }
}
