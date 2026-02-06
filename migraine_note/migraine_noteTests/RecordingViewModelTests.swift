//
//  RecordingViewModelTests.swift
//  migraine_noteTests
//
//  记录ViewModel单元测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class RecordingViewModelTests: XCTestCase {
    
    var viewModel: RecordingViewModel!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
        viewModel = RecordingViewModel(modelContext: modelContext)
    }
    
    override func tearDown() {
        viewModel = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        XCTAssertNil(viewModel.currentAttack)
        XCTAssertEqual(viewModel.currentStep, .timeAndDuration)
        XCTAssertFalse(viewModel.isEditMode)
        XCTAssertEqual(viewModel.selectedPainIntensity, 0)
        XCTAssertTrue(viewModel.selectedPainLocations.isEmpty)
        XCTAssertTrue(viewModel.selectedMedications.isEmpty)
        XCTAssertTrue(viewModel.isOngoing)
    }
    
    // MARK: - 步骤导航测试
    
    func testNextStep() {
        XCTAssertEqual(viewModel.currentStep, .timeAndDuration)
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .painAssessment)
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .symptoms)
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .triggers)
        
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, .interventions)
    }
    
    func testNextStep_AtLast_StaysAtLast() {
        viewModel.goToStep(.interventions)
        viewModel.nextStep()
        
        XCTAssertEqual(viewModel.currentStep, .interventions)
    }
    
    func testPreviousStep() {
        viewModel.goToStep(.interventions)
        
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .triggers)
        
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, .symptoms)
    }
    
    func testPreviousStep_AtFirst_StaysAtFirst() {
        viewModel.previousStep()
        
        XCTAssertEqual(viewModel.currentStep, .timeAndDuration)
    }
    
    func testGoToStep() {
        viewModel.goToStep(.triggers)
        
        XCTAssertEqual(viewModel.currentStep, .triggers)
    }
    
    // MARK: - canGoNext 测试
    
    func testCanGoNext_TimeStep_AlwaysTrue() {
        viewModel.currentStep = .timeAndDuration
        
        XCTAssertTrue(viewModel.canGoNext)
    }
    
    func testCanGoNext_PainAssessment_RequiresIntensityAndLocation() {
        viewModel.currentStep = .painAssessment
        
        XCTAssertFalse(viewModel.canGoNext, "无强度和部位不能前进")
        
        viewModel.selectedPainIntensity = 5
        XCTAssertFalse(viewModel.canGoNext, "有强度无部位不能前进")
        
        viewModel.selectedPainLocations = [.leftTemple]
        XCTAssertTrue(viewModel.canGoNext, "有强度有部位可以前进")
    }
    
    func testCanGoNext_SymptomsStep_AlwaysTrue() {
        viewModel.currentStep = .symptoms
        XCTAssertTrue(viewModel.canGoNext)
    }
    
    func testCanGoNext_TriggersStep_AlwaysTrue() {
        viewModel.currentStep = .triggers
        XCTAssertTrue(viewModel.canGoNext)
    }
    
    func testCanGoNext_InterventionsStep_AlwaysTrue() {
        viewModel.currentStep = .interventions
        XCTAssertTrue(viewModel.canGoNext)
    }
    
    // MARK: - canSave 测试
    
    func testCanSave_RequiresIntensityAndLocation() {
        XCTAssertFalse(viewModel.canSave)
        
        viewModel.selectedPainIntensity = 5
        XCTAssertFalse(viewModel.canSave)
        
        viewModel.selectedPainLocations = [.forehead]
        XCTAssertTrue(viewModel.canSave)
    }
    
    // MARK: - loadExistingAttack 测试
    
    func testLoadExistingAttack() {
        let attack = createAttack(in: modelContext, startTime: dateAgo(days: 3),
                                   endTime: dateAgo(days: 3).addingTimeInterval(7200),
                                   painIntensity: 7,
                                   painLocations: [.leftTemple],
                                   painQualities: [.pulsating],
                                   hasAura: true, auraTypes: [.visualFlashes])
        attack.notes = "测试备注"
        try? modelContext.save()
        
        viewModel.loadExistingAttack(attack)
        
        XCTAssertTrue(viewModel.isEditMode)
        XCTAssertEqual(viewModel.currentAttack?.id, attack.id)
        XCTAssertEqual(viewModel.selectedPainIntensity, 7)
        XCTAssertTrue(viewModel.selectedPainLocations.contains(.leftTemple))
        XCTAssertTrue(viewModel.hasAura)
        XCTAssertEqual(viewModel.notes, "测试备注")
        XCTAssertFalse(viewModel.isOngoing) // 有结束时间
    }
    
    func testLoadExistingAttack_OngoingAttack() {
        let attack = createAttack(in: modelContext, startTime: Date(), painIntensity: 5)
        
        viewModel.loadExistingAttack(attack)
        
        XCTAssertTrue(viewModel.isOngoing)
    }
    
    // MARK: - 药物管理测试
    
    func testAddMedication() {
        let med = createMedication(in: modelContext, name: "布洛芬")
        
        viewModel.addMedication(medication: med, dosage: 400, unit: "mg")
        
        XCTAssertEqual(viewModel.selectedMedications.count, 1)
    }
    
    func testRemoveMedication() {
        viewModel.addMedication(medication: nil, customName: "药物A", dosage: 100, unit: "mg")
        viewModel.addMedication(medication: nil, customName: "药物B", dosage: 200, unit: "mg")
        
        viewModel.removeMedication(at: 0)
        
        XCTAssertEqual(viewModel.selectedMedications.count, 1)
        XCTAssertEqual(viewModel.selectedMedications.first?.customName, "药物B")
    }
    
    func testRemoveMedication_InvalidIndex() {
        viewModel.addMedication(medication: nil, customName: "test", dosage: 100, unit: "mg")
        
        viewModel.removeMedication(at: 10)
        
        XCTAssertEqual(viewModel.selectedMedications.count, 1, "无效索引不应移除")
    }
    
    // MARK: - checkMedicationExists 测试
    
    func testCheckMedicationExists() {
        createMedication(in: modelContext, name: "布洛芬")
        
        XCTAssertTrue(viewModel.checkMedicationExists(name: "布洛芬"))
        XCTAssertFalse(viewModel.checkMedicationExists(name: "不存在"))
    }
    
    // MARK: - syncMedicationToCabinet 测试
    
    func testSyncMedicationToCabinet_Success() {
        let result = viewModel.syncMedicationToCabinet(name: "新药", dosage: 100, unit: "mg")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "新药")
    }
    
    func testSyncMedicationToCabinet_AlreadyExists_ReturnsNil() {
        createMedication(in: modelContext, name: "布洛芬")
        
        let result = viewModel.syncMedicationToCabinet(name: "布洛芬", dosage: 400, unit: "mg")
        
        XCTAssertNil(result)
    }
    
    // MARK: - 快速记录测试
    
    func testQuickStartRecording() {
        let attack = viewModel.quickStartRecording()
        
        XCTAssertNotNil(attack)
        XCTAssertNil(attack.endTime, "快速开始不应有结束时间")
    }
    
    func testQuickEndRecording() {
        let attack = viewModel.quickStartRecording()
        
        viewModel.quickEndRecording(attack)
        
        XCTAssertNotNil(attack.endTime, "快速结束应设置结束时间")
    }
    
    // MARK: - cancelRecording 测试
    
    func testCancelRecording_NewMode_DeletesAttack() {
        viewModel.startRecording()
        let attackId = viewModel.currentAttack?.id
        XCTAssertNotNil(attackId)
        
        viewModel.cancelRecording()
        
        XCTAssertNil(viewModel.currentAttack)
        XCTAssertEqual(viewModel.currentStep, .timeAndDuration)
    }
    
    func testCancelRecording_EditMode_DoesNotDelete() {
        let attack = createAttack(in: modelContext, painIntensity: 5)
        viewModel.loadExistingAttack(attack)
        
        viewModel.cancelRecording()
        
        // 编辑模式下取消不删除原记录
        let descriptor = FetchDescriptor<AttackRecord>()
        let remaining = try? modelContext.fetch(descriptor)
        XCTAssertEqual(remaining?.count ?? 0, 1, "编辑模式取消不应删除记录")
    }
    
    // MARK: - hasStartTimeChanged 测试
    
    func testHasStartTimeChanged_NoFetchedTime_ReturnsFalse() {
        XCTAssertFalse(viewModel.hasStartTimeChanged)
    }
    
    func testHasStartTimeChanged_TimeChanged_ReturnsTrue() {
        viewModel.startTimeWhenWeatherFetched = Date()
        viewModel.startTime = Date().addingTimeInterval(-120) // 2分钟前
        
        XCTAssertTrue(viewModel.hasStartTimeChanged)
    }
    
    func testHasStartTimeChanged_TimeNotChanged_ReturnsFalse() {
        let now = Date()
        viewModel.startTimeWhenWeatherFetched = now
        viewModel.startTime = now.addingTimeInterval(30) // 30秒内不算改变
        
        XCTAssertFalse(viewModel.hasStartTimeChanged)
    }
}
