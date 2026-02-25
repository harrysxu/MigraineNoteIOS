//
//  TimelineDeduplicationTests.swift
//  migraine_noteTests
//
//  Created by AI Assistant on 2026/2/24.
//  时间轴去重功能测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class TimelineDeduplicationTests: XCTestCase {
    var context: ModelContext!
    var viewModel: AttackListViewModel!
    
    override func setUp() {
        super.setUp()
        context = try! makeTestModelContext()
        viewModel = AttackListViewModel()
        viewModel.setup(modelContext: context)
    }
    
    override func tearDown() {
        context = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - 去重测试
    
    func testUpdateTimelineItems_RemovesDuplicateAttacks() {
        // 创建一个发作记录
        let attack = createAttack(in: context, painIntensity: 5)
        
        // 手动模拟重复：将同一个 attack 添加到内存数组中两次
        viewModel.attacks = [attack, attack]
        
        // 更新时间轴
        viewModel.updateTimelineItems()
        
        // 验证：时间轴中只有一条记录
        XCTAssertEqual(viewModel.cachedTimelineItems.count, 1, "时间轴应该去重，只保留一条记录")
        
        // 验证：ID 确实是同一个
        if case .attack(let timelineAttack) = viewModel.cachedTimelineItems.first {
            XCTAssertEqual(timelineAttack.id, attack.id, "时间轴中的记录应该是原始记录")
        } else {
            XCTFail("时间轴应包含发作记录")
        }
    }
    
    func testUpdateTimelineItems_RemovesDuplicateHealthEvents() {
        // 创建一个健康事件
        let event = createHealthEvent(in: context, eventType: .medication)
        
        // 手动模拟重复
        viewModel.healthEvents = [event, event]
        viewModel.recordTypeFilter = .healthEventsOnly
        
        // 更新时间轴
        viewModel.updateTimelineItems()
        
        // 验证：时间轴中只有一条记录
        XCTAssertEqual(viewModel.cachedTimelineItems.count, 1, "健康事件应该去重")
        
        // 验证：ID 确实是同一个
        if case .healthEvent(let timelineEvent) = viewModel.cachedTimelineItems.first {
            XCTAssertEqual(timelineEvent.id, event.id, "时间轴中的事件应该是原始事件")
        } else {
            XCTFail("时间轴应包含健康事件")
        }
    }
    
    func testUpdateTimelineItems_RemovesMixedDuplicates() {
        // 创建发作记录和健康事件
        let attack = createAttack(in: context, painIntensity: 6)
        let event = createHealthEvent(in: context, eventType: .tcmTreatment)
        
        // 模拟混合重复
        viewModel.attacks = [attack, attack]
        viewModel.healthEvents = [event, event]
        viewModel.recordTypeFilter = .all
        
        // 更新时间轴
        viewModel.updateTimelineItems()
        
        // 验证：时间轴中只有两条不同的记录
        XCTAssertEqual(viewModel.cachedTimelineItems.count, 2, "应该有 1 个发作 + 1 个事件")
        
        // 验证：两个 ID 不同
        let ids = viewModel.cachedTimelineItems.map { $0.id }
        XCTAssertEqual(Set(ids).count, 2, "时间轴中应该有两个不同的 ID")
    }
    
    func testUpdateTimelineItems_HandlesLargeDataset() {
        // 创建大量记录
        for i in 0..<50 {
            let attack = createAttack(in: context, painIntensity: (i % 10) + 1)
            try? context.save()
        }
        
        // 加载数据
        viewModel.loadData()
        
        // 验证：所有记录的 ID 都是唯一的
        let ids = viewModel.cachedTimelineItems.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "大数据集中所有 ID 应该唯一")
    }
    
    // MARK: - HomeViewModel 测试
    
    func testHomeViewModel_RemovesDuplicates() {
        let weatherManager = WeatherManager()
        let homeVM = HomeViewModel(modelContext: context, weatherManager: weatherManager)
        
        // 创建记录
        let attack = createAttack(in: context, painIntensity: 7)
        let event = createHealthEvent(in: context, eventType: .medication)
        
        // 手动设置重复数据
        homeVM.recentAttacks = [attack, attack]
        homeVM.recentHealthEvents = [event, event]
        
        // 刷新数据（会调用 loadRecentTimelineItems）
        homeVM.refreshData()
        
        // 验证：时间轴去重成功
        XCTAssertEqual(homeVM.recentTimelineItems.count, 2, "HomeViewModel 应该去重")
        
        // 验证：所有 ID 唯一
        let ids = homeVM.recentTimelineItems.map { $0.id }
        XCTAssertEqual(Set(ids).count, 2, "所有 ID 应该唯一")
    }
    
    // MARK: - 辅助方法
    
    private func createHealthEvent(in context: ModelContext, eventType: HealthEventType) -> HealthEvent {
        let event = HealthEvent(eventType: eventType, eventDate: Date())
        context.insert(event)
        try? context.save()
        return event
    }
}
