//
//  AnalyticsEngineTests.swift
//  migraine_noteTests
//
//  Created on 2026/2/1.
//

import XCTest
import SwiftData
@testable import migraine_note

/// 数据分析引擎单元测试
final class AnalyticsEngineTests: XCTestCase {
    
    var engine: AnalyticsEngine!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // 创建内存中的ModelContainer用于测试
        let schema = Schema([
            AttackRecord.self,
            Symptom.self,
            Trigger.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(container)
        
        engine = AnalyticsEngine(modelContext: modelContext)
    }
    
    override func tearDown() {
        engine = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 月度统计测试
    
    func testMonthlyStats_EmptyData() {
        // 给定：没有任何记录
        
        // 当：计算月度统计
        let stats = engine.calculateMonthlyStats(for: Date())
        
        // 则：应该返回零值统计
        XCTAssertEqual(stats.totalAttacks, 0, "总发作次数应为0")
        XCTAssertEqual(stats.attackDays, 0, "发作天数应为0")
        XCTAssertEqual(stats.averageIntensity, 0, "平均强度应为0")
    }
    
    func testMonthlyStats_WithData() {
        // 给定：本月有3次发作
        createAttackRecord(painIntensity: 5, daysAgo: 1)
        createAttackRecord(painIntensity: 7, daysAgo: 5)
        createAttackRecord(painIntensity: 4, daysAgo: 10)
        
        // 当：计算月度统计
        let stats = engine.calculateMonthlyStats(for: Date())
        
        // 则：应该正确统计
        XCTAssertEqual(stats.totalAttacks, 3, "总发作次数应为3")
        XCTAssertEqual(stats.attackDays, 3, "发作天数应为3（不同日期）")
        
        // 平均强度 = (5 + 7 + 4) / 3 ≈ 5.33
        XCTAssertEqual(stats.averageIntensity, 5.33, accuracy: 0.1, "平均强度应约为5.33")
    }
    
    func testMonthlyStats_SameDayAttacks() {
        // 给定：同一天有2次发作
        let now = Date()
        createAttackRecord(painIntensity: 6, date: now)
        createAttackRecord(painIntensity: 8, date: now.addingTimeInterval(3600)) // 1小时后
        
        // 当：计算月度统计
        let stats = engine.calculateMonthlyStats(for: Date())
        
        // 则：发作次数是2，但发作天数只算1天
        XCTAssertEqual(stats.totalAttacks, 2, "总发作次数应为2")
        XCTAssertEqual(stats.attackDays, 1, "发作天数应为1（同一天）")
    }
    
    // MARK: - 诱因频次分析测试
    
    func testTriggerFrequency_NoTriggers() {
        // 给定：发作记录但没有诱因
        createAttackRecord(painIntensity: 5, daysAgo: 1)
        
        // 当：分析诱因频次
        let result = engine.analyzeTriggerFrequency(in: Date())
        
        // 则：应该返回空数组
        XCTAssertTrue(result.isEmpty, "没有诱因应返回空数组")
    }
    
    func testTriggerFrequency_WithTriggers() {
        // 给定：3次发作，有诱因
        let attack1 = createAttackRecord(painIntensity: 5, daysAgo: 1)
        addTrigger(to: attack1, name: "巧克力", category: .dietary)
        
        let attack2 = createAttackRecord(painIntensity: 6, daysAgo: 3)
        addTrigger(to: attack2, name: "巧克力", category: .dietary)
        addTrigger(to: attack2, name: "睡眠不足", category: .sleep)
        
        let attack3 = createAttackRecord(painIntensity: 7, daysAgo: 5)
        addTrigger(to: attack3, name: "睡眠不足", category: .sleep)
        
        // 当：分析诱因频次
        let result = engine.analyzeTriggerFrequency(in: Date())
        
        // 则：应该正确统计
        XCTAssertEqual(result.count, 2, "应有2个不同的诱因")
        
        // 找到"睡眠不足"和"巧克力"
        let sleepTrigger = result.first { $0.triggerName == "睡眠不足" }
        let chocolateTrigger = result.first { $0.triggerName == "巧克力" }
        
        XCTAssertNotNil(sleepTrigger, "应该找到睡眠不足诱因")
        XCTAssertNotNil(chocolateTrigger, "应该找到巧克力诱因")
        
        XCTAssertEqual(sleepTrigger?.count, 2, "睡眠不足应出现2次")
        XCTAssertEqual(chocolateTrigger?.count, 2, "巧克力应出现2次")
    }
    
    // MARK: - 昼夜节律分析测试
    
    func testCircadianPattern_Distribution() {
        // 给定：不同时段的发作
        createAttackRecord(painIntensity: 5, hour: 8)  // 早上8点
        createAttackRecord(painIntensity: 6, hour: 14) // 下午2点
        createAttackRecord(painIntensity: 7, hour: 20) // 晚上8点
        createAttackRecord(painIntensity: 8, hour: 8)  // 又一个早上8点
        
        // 当：分析昼夜节律
        let result = engine.analyzeCircadianPattern(in: Date())
        
        // 则：应该正确统计每个时段
        let morning8 = result.first { $0.hour == 8 }
        let afternoon2 = result.first { $0.hour == 14 }
        let evening8 = result.first { $0.hour == 20 }
        
        XCTAssertEqual(morning8?.count, 2, "早上8点应有2次发作")
        XCTAssertEqual(afternoon2?.count, 1, "下午2点应有1次发作")
        XCTAssertEqual(evening8?.count, 1, "晚上8点应有1次发作")
    }
    
    // MARK: - 辅助方法
    
    @discardableResult
    private func createAttackRecord(
        painIntensity: Int,
        daysAgo: Int = 0,
        hour: Int = 12
    ) -> AttackRecord {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! -= daysAgo
        components.hour = hour
        let date = calendar.date(from: components)!
        
        return createAttackRecord(painIntensity: painIntensity, date: date)
    }
    
    @discardableResult
    private func createAttackRecord(
        painIntensity: Int,
        date: Date
    ) -> AttackRecord {
        let attack = AttackRecord(
            startTime: date,
            status: .ended,
            painIntensity: painIntensity
        )
        attack.endTime = date.addingTimeInterval(3600) // 1小时后结束
        
        modelContext.insert(attack)
        try? modelContext.save()
        
        return attack
    }
    
    private func addTrigger(
        to attack: AttackRecord,
        name: String,
        category: TriggerCategory
    ) {
        let trigger = Trigger(
            name: name,
            category: category,
            attack: attack
        )
        
        modelContext.insert(trigger)
        try? modelContext.save()
    }
}
