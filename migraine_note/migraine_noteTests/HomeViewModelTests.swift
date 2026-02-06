//
//  HomeViewModelTests.swift
//  migraine_noteTests
//
//  首页ViewModel单元测试
//  注意：部分功能依赖WeatherManager，本测试主要覆盖非天气相关逻辑
//

import XCTest
import SwiftData
@testable import migraine_note

final class HomeViewModelTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - Streak 计算逻辑测试（直接测试逻辑）
    
    func testStreakDays_NoAttacks_ZeroDays() {
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertEqual(vm.streakDays, 0, "无记录时连续天数应为0")
    }
    
    func testStreakDays_OngoingAttack_ZeroDays() {
        // 创建一个进行中的发作
        createAttack(in: modelContext, startTime: dateAgo(hours: 2), painIntensity: 5)
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertEqual(vm.streakDays, 0, "有进行中的发作时连续天数应为0")
    }
    
    func testStreakDays_AttackEndedYesterday() {
        // 创建一个昨天结束的发作
        let yesterday = dateAgo(days: 1, hour: 10)
        let attack = createAttack(in: modelContext, startTime: yesterday, painIntensity: 5)
        attack.endTime = yesterday.addingTimeInterval(3600)
        try? modelContext.save()
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertGreaterThanOrEqual(vm.streakDays, 1, "昨天结束的发作应有至少1天无痛日")
    }
    
    func testStreakDays_AttackEndedToday_ZeroDays() {
        // 创建一个今天结束的发作
        let today = Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600)
        let attack = createAttack(in: modelContext, startTime: today, painIntensity: 5)
        attack.endTime = today.addingTimeInterval(7200)
        try? modelContext.save()
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertEqual(vm.streakDays, 0, "今天结束的发作连续天数应为0")
    }
    
    // MARK: - 正在进行的发作检测测试
    
    func testOngoingAttack_None() {
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertNil(vm.ongoingAttack)
    }
    
    func testOngoingAttack_DetectsOngoing() {
        let attack = createAttack(in: modelContext, startTime: Date(), painIntensity: 5)
        // endTime 为 nil 表示进行中
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertNotNil(vm.ongoingAttack, "应检测到进行中的发作")
        XCTAssertEqual(vm.ongoingAttack?.id, attack.id)
    }
    
    // MARK: - 最近记录测试
    
    func testRecentAttacks_Limit10() {
        // 创建15条记录
        for i in 0..<15 {
            createAttack(in: modelContext, startTime: dateAgo(days: i), painIntensity: 5)
        }
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertLessThanOrEqual(vm.recentAttacks.count, 10, "最近记录应限制10条")
    }
    
    func testRecentAttacks_SortedByDate() {
        createAttack(in: modelContext, startTime: dateAgo(days: 5), painIntensity: 3)
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 7)
        createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 5)
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        if vm.recentAttacks.count >= 2 {
            XCTAssertTrue(vm.recentAttacks[0].startTime >= vm.recentAttacks[1].startTime,
                          "应按时间倒序排列")
        }
    }
    
    // MARK: - 时间线合并测试
    
    func testTimelineItems_MergesAttacksAndEvents() {
        createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 2))
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertEqual(vm.recentTimelineItems.count, 2, "时间线应合并发作和健康事件")
    }
    
    func testTimelineItems_SortedByDate() {
        createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 5)
        createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 1))
        createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 7)
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        if vm.recentTimelineItems.count >= 2 {
            XCTAssertTrue(vm.recentTimelineItems[0].eventDate >= vm.recentTimelineItems[1].eventDate,
                          "时间线应按时间倒序排列")
        }
    }
    
    func testTimelineItems_Limit10() {
        for i in 0..<8 {
            createAttack(in: modelContext, startTime: dateAgo(days: i), painIntensity: 5)
        }
        for i in 0..<8 {
            createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: i))
        }
        
        let vm = HomeViewModel(modelContext: modelContext)
        
        XCTAssertLessThanOrEqual(vm.recentTimelineItems.count, 10, "时间线应限制10条")
    }
    
    // MARK: - 快速结束记录测试
    
    func testQuickEndRecording() {
        let attack = createAttack(in: modelContext, startTime: Date(), painIntensity: 5)
        XCTAssertNil(attack.endTime)
        
        let vm = HomeViewModel(modelContext: modelContext)
        vm.quickEndRecording(attack)
        
        XCTAssertNotNil(attack.endTime, "快速结束应设置endTime")
    }
}
