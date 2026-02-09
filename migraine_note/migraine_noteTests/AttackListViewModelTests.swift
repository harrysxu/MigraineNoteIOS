//
//  AttackListViewModelTests.swift
//  migraine_noteTests
//
//  发作列表ViewModel单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class AttackListViewModelTests: XCTestCase {
    
    var viewModel: AttackListViewModel!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        viewModel = AttackListViewModel()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.filterOption, .thisMonth)
        XCTAssertEqual(viewModel.sortOption, .dateDescending)
        XCTAssertNil(viewModel.selectedDateRange)
        XCTAssertEqual(viewModel.recordTypeFilter, .all)
    }
    
    // MARK: - 排序测试
    
    func testSortByDateDescending() {
        viewModel.filterOption = .lastYear
        viewModel.sortOption = .dateDescending
        
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 10), painIntensity: 3)
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 7)
        let attack3 = createAttack(in: modelContext, startTime: dateAgo(days: 5), painIntensity: 5)
        
        let result = viewModel.filteredAttacks([attack1, attack2, attack3])
        
        XCTAssertEqual(result.first?.id, attack2.id, "最新的应排在前面")
    }
    
    func testSortByDateAscending() {
        viewModel.filterOption = .lastYear
        viewModel.sortOption = .dateAscending
        
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 10), painIntensity: 3)
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 7)
        
        let result = viewModel.filteredAttacks([attack1, attack2])
        
        XCTAssertEqual(result.first?.id, attack1.id, "最早的应排在前面")
    }
    
    func testSortByIntensityDescending() {
        viewModel.filterOption = .lastYear
        viewModel.sortOption = .intensityDescending
        
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 3)
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 9)
        let attack3 = createAttack(in: modelContext, startTime: dateAgo(days: 3), painIntensity: 5)
        
        let result = viewModel.filteredAttacks([attack1, attack2, attack3])
        
        XCTAssertEqual(result.first?.painIntensity, 9, "最高强度应排在前面")
    }
    
    // MARK: - 搜索测试
    
    func testSearchBySymptomName() {
        viewModel.filterOption = .lastYear
        viewModel.searchText = "恶心"
        
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        createSymptom(in: modelContext, type: .nausea, attack: attack1) // 恶心
        
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 6)
        createSymptom(in: modelContext, type: .photophobia, attack: attack2) // 畏光
        
        let result = viewModel.filteredAttacks([attack1, attack2])
        
        XCTAssertEqual(result.count, 1, "应只返回包含'恶心'症状的记录")
        XCTAssertEqual(result.first?.id, attack1.id)
    }
    
    func testSearchByTriggerName() {
        viewModel.filterOption = .lastYear
        viewModel.searchText = "巧克力"
        
        let attack1 = createAttack(in: modelContext, startTime: dateAgo(days: 1), painIntensity: 5)
        createTrigger(in: modelContext, category: .food, specificType: "巧克力", attack: attack1)
        
        let attack2 = createAttack(in: modelContext, startTime: dateAgo(days: 2), painIntensity: 6)
        
        let result = viewModel.filteredAttacks([attack1, attack2])
        
        XCTAssertEqual(result.count, 1)
    }
    
    // MARK: - 健康事件筛选测试
    
    func testFilteredHealthEvents_MedicationOnly() {
        viewModel.filterOption = .lastYear
        viewModel.recordTypeFilter = .medicationOnly
        
        let med = createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 1))
        let tcm = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 2))
        let surgery = createHealthEvent(in: modelContext, eventType: .surgery, eventDate: dateAgo(days: 3))
        
        let result = viewModel.filteredHealthEvents([med, tcm, surgery])
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.eventType, .medication)
    }
    
    func testFilteredHealthEvents_TCMOnly() {
        viewModel.filterOption = .lastYear
        viewModel.recordTypeFilter = .tcmOnly
        
        let med = createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 1))
        let tcm = createHealthEvent(in: modelContext, eventType: .tcmTreatment, eventDate: dateAgo(days: 2))
        
        let result = viewModel.filteredHealthEvents([med, tcm])
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.eventType, .tcmTreatment)
    }
    
    func testFilteredHealthEvents_AttacksOnly_ReturnsEmpty() {
        viewModel.filterOption = .lastYear
        viewModel.recordTypeFilter = .attacksOnly
        
        let event = createHealthEvent(in: modelContext, eventType: .medication, eventDate: dateAgo(days: 1))
        
        let result = viewModel.filteredHealthEvents([event])
        
        XCTAssertTrue(result.isEmpty, "attacksOnly模式不应显示健康事件")
    }
    
    // MARK: - resetFilters 测试
    
    func testResetFilters() {
        viewModel.searchText = "test"
        viewModel.filterOption = .lastYear
        viewModel.sortOption = .intensityDescending
        viewModel.recordTypeFilter = .medicationOnly
        
        viewModel.resetFilters()
        
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.filterOption, .thisMonth)
        XCTAssertEqual(viewModel.sortOption, .dateDescending)
        XCTAssertNil(viewModel.selectedDateRange)
        XCTAssertEqual(viewModel.recordTypeFilter, .all)
    }
    
    // MARK: - 删除测试
    
    func testDeleteAttack() {
        let attack = createAttack(in: modelContext, painIntensity: 5)
        
        viewModel.deleteAttack(attack, from: modelContext)
        
        let descriptor = FetchDescriptor<AttackRecord>()
        let remaining = try? modelContext.fetch(descriptor)
        XCTAssertEqual(remaining?.count ?? 0, 0)
    }
    
    func testDeleteMultipleAttacks() {
        let attack1 = createAttack(in: modelContext, painIntensity: 5)
        let attack2 = createAttack(in: modelContext, painIntensity: 6)
        let attack3 = createAttack(in: modelContext, painIntensity: 7)
        
        viewModel.deleteAttacks([attack1, attack2], from: modelContext)
        
        let descriptor = FetchDescriptor<AttackRecord>()
        let remaining = try? modelContext.fetch(descriptor)
        XCTAssertEqual(remaining?.count ?? 0, 1)
    }
    
    // MARK: - FilterOption 枚举测试
    
    func testFilterOption_AllCases() {
        XCTAssertEqual(AttackListViewModel.FilterOption.allCases.count, 5)
    }
    
    func testSortOption_AllCases() {
        XCTAssertEqual(AttackListViewModel.SortOption.allCases.count, 4)
    }
    
    func testRecordTypeFilter_AllCases() {
        XCTAssertEqual(AttackListViewModel.RecordTypeFilter.allCases.count, 6)
    }
}
