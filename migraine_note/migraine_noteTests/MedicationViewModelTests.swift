//
//  MedicationViewModelTests.swift
//  migraine_noteTests
//
//  药箱ViewModel单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class MedicationViewModelTests: XCTestCase {
    
    var viewModel: MedicationViewModel!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        viewModel = MedicationViewModel()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        XCTAssertEqual(viewModel.selectedCategory, .all)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.sortOption, .name)
    }
    
    // MARK: - 类别筛选测试
    
    func testFilterByCategory_All() {
        viewModel.selectedCategory = .all
        
        let med1 = createMedication(in: modelContext, name: "布洛芬", category: .nsaid, isAcute: true)
        let med2 = createMedication(in: modelContext, name: "普萘洛尔", category: .preventive, isAcute: false)
        
        let result = viewModel.filteredMedications([med1, med2], logs: [])
        
        XCTAssertEqual(result.count, 2)
    }
    
    func testFilterByCategory_AcuteOnly() {
        viewModel.selectedCategory = .acute
        
        let med1 = createMedication(in: modelContext, name: "布洛芬", category: .nsaid, isAcute: true)
        let med2 = createMedication(in: modelContext, name: "普萘洛尔", category: .preventive, isAcute: false)
        
        let result = viewModel.filteredMedications([med1, med2], logs: [])
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "布洛芬")
    }
    
    func testFilterByCategory_PreventiveOnly() {
        viewModel.selectedCategory = .preventive
        
        let med1 = createMedication(in: modelContext, name: "布洛芬", category: .nsaid, isAcute: true)
        let med2 = createMedication(in: modelContext, name: "普萘洛尔", category: .preventive, isAcute: false)
        
        let result = viewModel.filteredMedications([med1, med2], logs: [])
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "普萘洛尔")
    }
    
    // MARK: - 搜索筛选测试
    
    func testSearchFilter_ByName() {
        viewModel.searchText = "布洛芬"
        
        let med1 = createMedication(in: modelContext, name: "布洛芬", category: .nsaid, isAcute: true)
        let med2 = createMedication(in: modelContext, name: "舒马曲普坦", category: .triptan, isAcute: true)
        
        let result = viewModel.filteredMedications([med1, med2], logs: [])
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "布洛芬")
    }
    
    func testSearchFilter_ByCategory() {
        viewModel.searchText = "曲普坦"
        
        let med1 = createMedication(in: modelContext, name: "布洛芬", category: .nsaid, isAcute: true)
        let med2 = createMedication(in: modelContext, name: "舒马曲普坦", category: .triptan, isAcute: true)
        
        let result = viewModel.filteredMedications([med1, med2], logs: [])
        
        XCTAssertEqual(result.count, 1)
    }
    
    // MARK: - 排序测试
    
    func testSortByName() {
        viewModel.sortOption = .name
        
        let med1 = createMedication(in: modelContext, name: "舒马曲普坦", category: .triptan, isAcute: true)
        let med2 = createMedication(in: modelContext, name: "布洛芬", category: .nsaid, isAcute: true)
        
        let result = viewModel.filteredMedications([med1, med2], logs: [])
        
        XCTAssertEqual(result.first?.name, "布洛芬") // 按字母序
    }
    
    func testSortByInventory() {
        viewModel.sortOption = .inventory
        
        let med1 = createMedication(in: modelContext, name: "A", category: .nsaid, isAcute: true, inventory: 5)
        let med2 = createMedication(in: modelContext, name: "B", category: .nsaid, isAcute: true, inventory: 20)
        
        let result = viewModel.filteredMedications([med1, med2], logs: [])
        
        XCTAssertEqual(result.first?.name, "B", "库存多的应排前面")
    }
    
    // MARK: - MOH限制检测测试
    
    func testIsApproachingMOHLimit() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: true)
        // 月度限制为15天
        
        XCTAssertFalse(viewModel.isApproachingMOHLimit(medication: med, usageDays: 10))
        XCTAssertTrue(viewModel.isApproachingMOHLimit(medication: med, usageDays: 12)) // 15-3=12
        XCTAssertTrue(viewModel.isApproachingMOHLimit(medication: med, usageDays: 14))
        XCTAssertTrue(viewModel.isApproachingMOHLimit(medication: med, usageDays: 15)) // 也算接近
    }
    
    func testIsExceedingMOHLimit() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: true)
        
        XCTAssertFalse(viewModel.isExceedingMOHLimit(medication: med, usageDays: 14))
        XCTAssertTrue(viewModel.isExceedingMOHLimit(medication: med, usageDays: 15))
        XCTAssertTrue(viewModel.isExceedingMOHLimit(medication: med, usageDays: 20))
    }
    
    func testMOHLimit_NoLimit_NeverTriggered() {
        let med = Medication(name: "其他药物", category: .other, isAcute: true)
        // 其他类别没有月度限制
        
        XCTAssertFalse(viewModel.isApproachingMOHLimit(medication: med, usageDays: 100))
        XCTAssertFalse(viewModel.isExceedingMOHLimit(medication: med, usageDays: 100))
    }
    
    // MARK: - MOH 警告文本测试
    
    func testMOHWarningText_NoLimit_ReturnsNil() {
        let med = Medication(name: "其他", category: .other, isAcute: true)
        
        XCTAssertNil(viewModel.mohWarningText(for: med, usageDays: 100))
    }
    
    func testMOHWarningText_Approaching() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: true) // limit=15
        
        let text = viewModel.mohWarningText(for: med, usageDays: 13)
        
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("接近"))
    }
    
    func testMOHWarningText_Exceeding() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: true)
        
        let text = viewModel.mohWarningText(for: med, usageDays: 16)
        
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("超过"))
    }
    
    func testMOHWarningText_Safe_ReturnsNil() {
        let med = Medication(name: "布洛芬", category: .nsaid, isAcute: true)
        
        XCTAssertNil(viewModel.mohWarningText(for: med, usageDays: 5))
    }
    
    // MARK: - 低库存检测测试
    
    func testIsLowInventory_ZeroInventory_ReturnsFalse() {
        let med = Medication(name: "test", category: .nsaid, isAcute: true)
        med.inventory = 0
        
        XCTAssertFalse(viewModel.isLowInventory(med), "0库存不算低库存（可能未设置）")
    }
    
    func testIsLowInventory_LessThan5_ReturnsTrue() {
        let med = Medication(name: "test", category: .nsaid, isAcute: true)
        med.inventory = 3
        
        XCTAssertTrue(viewModel.isLowInventory(med))
    }
    
    func testIsLowInventory_Exactly5_ReturnsTrue() {
        let med = Medication(name: "test", category: .nsaid, isAcute: true)
        med.inventory = 5
        
        XCTAssertTrue(viewModel.isLowInventory(med))
    }
    
    func testIsLowInventory_MoreThan5_ReturnsFalse() {
        let med = Medication(name: "test", category: .nsaid, isAcute: true)
        med.inventory = 10
        
        XCTAssertFalse(viewModel.isLowInventory(med))
    }
    
    // MARK: - 删除和更新库存测试
    
    func testDeleteMedication() {
        let med = createMedication(in: modelContext)
        
        viewModel.deleteMedication(med, from: modelContext)
        
        let descriptor = FetchDescriptor<Medication>()
        let remaining = try? modelContext.fetch(descriptor)
        XCTAssertEqual(remaining?.count ?? 0, 0)
    }
    
    func testUpdateInventory() {
        let med = createMedication(in: modelContext, inventory: 10)
        
        viewModel.updateInventory(med, newCount: 5, context: modelContext)
        
        XCTAssertEqual(med.inventory, 5)
    }
    
    func testUpdateInventory_NegativeValueClampedToZero() {
        let med = createMedication(in: modelContext, inventory: 10)
        
        viewModel.updateInventory(med, newCount: -5, context: modelContext)
        
        XCTAssertEqual(med.inventory, 0, "负数应被限制为0")
    }
}
