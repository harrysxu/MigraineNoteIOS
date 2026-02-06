//
//  HealthEventMedicationViewModelTests.swift
//  migraine_noteTests
//
//  健康事件用药管理ViewModel单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class HealthEventMedicationViewModelTests: XCTestCase {
    
    var viewModel: HealthEventMedicationViewModel!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
        viewModel = HealthEventMedicationViewModel(modelContext: modelContext)
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState_EmptyMedications() {
        XCTAssertTrue(viewModel.selectedMedications.isEmpty)
    }
    
    // MARK: - 添加药物测试
    
    func testAddMedication_WithMedicationObject() {
        let med = createMedication(in: modelContext, name: "布洛芬")
        
        viewModel.addMedication(medication: med, dosage: 400, unit: "mg")
        
        XCTAssertEqual(viewModel.selectedMedications.count, 1)
        XCTAssertEqual(viewModel.selectedMedications.first?.medication?.name, "布洛芬")
        XCTAssertEqual(viewModel.selectedMedications.first?.dosage, 400)
    }
    
    func testAddMedication_WithCustomName() {
        viewModel.addMedication(medication: nil, customName: "自定义药物", dosage: 500, unit: "mg")
        
        XCTAssertEqual(viewModel.selectedMedications.count, 1)
        XCTAssertNil(viewModel.selectedMedications.first?.medication)
        XCTAssertEqual(viewModel.selectedMedications.first?.customName, "自定义药物")
    }
    
    func testAddMedication_Multiple() {
        viewModel.addMedication(medication: nil, customName: "药物A", dosage: 100, unit: "mg")
        viewModel.addMedication(medication: nil, customName: "药物B", dosage: 200, unit: "mg")
        viewModel.addMedication(medication: nil, customName: "药物C", dosage: 300, unit: "mg")
        
        XCTAssertEqual(viewModel.selectedMedications.count, 3)
    }
    
    // MARK: - 移除药物测试
    
    func testRemoveMedication_ValidIndex() {
        viewModel.addMedication(medication: nil, customName: "药物A", dosage: 100, unit: "mg")
        viewModel.addMedication(medication: nil, customName: "药物B", dosage: 200, unit: "mg")
        
        viewModel.removeMedication(at: 0)
        
        XCTAssertEqual(viewModel.selectedMedications.count, 1)
        XCTAssertEqual(viewModel.selectedMedications.first?.customName, "药物B")
    }
    
    func testRemoveMedication_InvalidIndex_NoEffect() {
        viewModel.addMedication(medication: nil, customName: "药物A", dosage: 100, unit: "mg")
        
        viewModel.removeMedication(at: 5) // 越界
        
        XCTAssertEqual(viewModel.selectedMedications.count, 1, "越界移除不应影响列表")
    }
    
    // MARK: - 清空药物测试
    
    func testClearAllMedications() {
        viewModel.addMedication(medication: nil, customName: "药物A", dosage: 100, unit: "mg")
        viewModel.addMedication(medication: nil, customName: "药物B", dosage: 200, unit: "mg")
        
        viewModel.clearAllMedications()
        
        XCTAssertTrue(viewModel.selectedMedications.isEmpty)
    }
    
    // MARK: - 药物存在性检查测试
    
    func testCheckMedicationExists_NotExists() {
        let result = viewModel.checkMedicationExists(name: "不存在的药物")
        
        XCTAssertFalse(result)
    }
    
    func testCheckMedicationExists_Exists() {
        createMedication(in: modelContext, name: "布洛芬")
        
        let result = viewModel.checkMedicationExists(name: "布洛芬")
        
        XCTAssertTrue(result)
    }
    
    func testCheckMedicationExists_CaseInsensitive() {
        createMedication(in: modelContext, name: "Ibuprofen")
        
        let result = viewModel.checkMedicationExists(name: "ibuprofen")
        
        XCTAssertTrue(result, "应不区分大小写")
    }
    
    func testCheckMedicationExists_TrimsWhitespace() {
        createMedication(in: modelContext, name: "布洛芬")
        
        let result = viewModel.checkMedicationExists(name: "  布洛芬  ")
        
        XCTAssertTrue(result, "应忽略前后空格")
    }
    
    // MARK: - 同步到药箱测试
    
    func testSyncMedicationToCabinet_NewMedication() {
        let result = viewModel.syncMedicationToCabinet(name: "新药物", dosage: 100, unit: "mg")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "新药物")
        XCTAssertEqual(result?.category, .other)
        XCTAssertTrue(result?.isAcute ?? false)
    }
    
    func testSyncMedicationToCabinet_ExistingMedication_ReturnsNil() {
        createMedication(in: modelContext, name: "布洛芬")
        
        let result = viewModel.syncMedicationToCabinet(name: "布洛芬", dosage: 400, unit: "mg")
        
        XCTAssertNil(result, "已存在的药物不应重复同步")
    }
    
    func testSyncMedicationToCabinet_DefaultValues() {
        let result = viewModel.syncMedicationToCabinet(name: "测试药物", dosage: 100, unit: "片")
        
        XCTAssertEqual(result?.inventory, 6, "默认库存应为6")
        XCTAssertEqual(result?.unit, "片")
        XCTAssertNil(result?.monthlyLimit, "其他类型不应有MOH限制")
    }
}
