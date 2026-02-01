//
//  RecordingViewModel.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

@Observable
class RecordingViewModel {
    var currentAttack: AttackRecord?
    var currentStep: RecordingStep = .timeAndDuration
    var isEditMode: Bool = false
    
    // 临时数据
    var startTime: Date = Date()
    var endTime: Date?
    var isOngoing: Bool = true
    
    var selectedPainIntensity: Int = 0
    var selectedPainLocations: Set<PainLocation> = []
    var selectedPainQualities: Set<PainQuality> = []
    
    var hasAura: Bool = false
    var selectedAuraTypes: Set<AuraType> = []
    var auraDuration: Double? // 分钟
    
    var selectedSymptoms: Set<SymptomType> = []
    var selectedTriggers: [String] = []
    
    var selectedMedications: [(medication: Medication?, dosage: Double, timeTaken: Date)] = []
    var selectedNonPharmacological: Set<String> = []
    var notes: String = ""
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext, editingAttack: AttackRecord? = nil) {
        self.modelContext = modelContext
        if let attack = editingAttack {
            self.isEditMode = true
            self.currentAttack = attack
        }
    }
    
    // MARK: - 开始记录
    
    func startRecording() {
        let attack = AttackRecord(startTime: startTime)
        modelContext.insert(attack)
        currentAttack = attack
        
        // 重置所有临时数据
        resetTemporaryData()
    }
    
    // MARK: - 加载现有记录（编辑模式）
    
    func loadExistingAttack(_ attack: AttackRecord) {
        self.currentAttack = attack
        self.isEditMode = true
        
        // 加载时间数据
        self.startTime = attack.startTime
        self.endTime = attack.endTime
        self.isOngoing = attack.endTime == nil
        
        // 加载疼痛评估数据
        self.selectedPainIntensity = attack.painIntensity
        self.selectedPainLocations = Set(attack.painLocations)
        self.selectedPainQualities = Set(attack.painQualities)
        
        // 加载先兆数据
        self.hasAura = attack.hasAura
        self.selectedAuraTypes = Set(attack.auraTypesList)
        if let duration = attack.auraDuration, duration > 0 {
            self.auraDuration = duration / 60.0 // 转换为分钟
        }
        
        // 加载症状
        self.selectedSymptoms = Set(attack.symptoms.map { $0.type })
        
        // 加载诱因
        self.selectedTriggers = attack.triggers.map { $0.name }
        
        // 加载用药记录
        self.selectedMedications = attack.medications.map { log in
            (medication: log.medication, dosage: log.dosage, timeTaken: log.takenAt)
        }
        
        // 加载备注
        self.notes = attack.notes ?? ""
    }
    
    // MARK: - 保存记录
    
    func saveRecording() throws {
        let attack: AttackRecord
        
        if isEditMode, let existingAttack = currentAttack {
            // 编辑模式：更新现有记录
            attack = existingAttack
            
            // 清除旧的关联数据
            for symptom in attack.symptoms {
                modelContext.delete(symptom)
            }
            attack.symptoms.removeAll()
            
            for trigger in attack.triggers {
                modelContext.delete(trigger)
            }
            attack.triggers.removeAll()
            
            for medLog in attack.medications {
                modelContext.delete(medLog)
            }
            attack.medications.removeAll()
        } else {
            // 新建模式：创建新记录
            attack = currentAttack ?? AttackRecord(startTime: startTime)
            if currentAttack == nil {
                modelContext.insert(attack)
            }
        }
        
        // 设置时间
        attack.startTime = startTime
        attack.endTime = isOngoing ? nil : endTime
        
        // 设置疼痛评估
        attack.painIntensity = selectedPainIntensity
        attack.painLocation = selectedPainLocations.map { $0.rawValue }
        attack.setPainQuality(Array(selectedPainQualities))
        
        // 设置先兆
        attack.hasAura = hasAura
        if hasAura {
            attack.setAuraTypes(Array(selectedAuraTypes))
            if let duration = auraDuration {
                attack.auraDuration = duration * 60 // 转换为秒
            }
        }
        
        // 添加症状
        for symptomType in selectedSymptoms {
            let symptom = Symptom(type: symptomType)
            attack.symptoms.append(symptom)
            modelContext.insert(symptom)
        }
        
        // 添加诱因
        for triggerName in selectedTriggers {
            // 从预定义库中查找类别
            let category = TriggerLibrary.allTriggers[triggerName] ?? .lifestyle
            let trigger = Trigger(category: category, specificType: triggerName)
            attack.triggers.append(trigger)
            modelContext.insert(trigger)
        }
        
        // 添加用药记录
        for medInfo in selectedMedications {
            let medLog = MedicationLog(dosage: medInfo.dosage, timeTaken: medInfo.timeTaken)
            medLog.medication = medInfo.medication
            attack.medications.append(medLog)
            modelContext.insert(medLog)
        }
        
        // 备注
        attack.notes = notes.isEmpty ? nil : notes
        
        attack.updatedAt = Date()
        
        try modelContext.save()
        
        // 重置状态
        if !isEditMode {
            reset()
        }
    }
    
    // MARK: - 步骤导航
    
    func nextStep() {
        currentStep = currentStep.next()
    }
    
    func previousStep() {
        currentStep = currentStep.previous()
    }
    
    func goToStep(_ step: RecordingStep) {
        currentStep = step
    }
    
    var canGoNext: Bool {
        switch currentStep {
        case .timeAndDuration:
            return true // 时间总是可以进入下一步
        case .painAssessment:
            return selectedPainIntensity > 0 && !selectedPainLocations.isEmpty
        case .symptoms:
            return true // 症状可选
        case .triggers:
            return true // 诱因可选
        case .interventions:
            return true // 干预措施可选
        }
    }
    
    var canSave: Bool {
        // 至少需要疼痛强度和部位
        return selectedPainIntensity > 0 && !selectedPainLocations.isEmpty
    }
    
    // MARK: - 辅助方法
    
    private func resetTemporaryData() {
        startTime = Date()
        endTime = nil
        isOngoing = true
        
        selectedPainIntensity = 0
        selectedPainLocations = []
        selectedPainQualities = []
        
        hasAura = false
        selectedAuraTypes = []
        auraDuration = nil
        
        selectedSymptoms = []
        selectedTriggers = []
        
        selectedMedications = []
        selectedNonPharmacological = []
        notes = ""
    }
    
    private func reset() {
        currentAttack = nil
        currentStep = .timeAndDuration
        resetTemporaryData()
    }
    
    // MARK: - 用药管理
    
    func addMedication(medication: Medication?, dosage: Double, timeTaken: Date = Date()) {
        selectedMedications.append((medication, dosage, timeTaken))
    }
    
    func removeMedication(at index: Int) {
        guard index < selectedMedications.count else { return }
        selectedMedications.remove(at: index)
    }
}

// MARK: - 记录步骤枚举

enum RecordingStep: Int, CaseIterable {
    case timeAndDuration = 0
    case painAssessment
    case symptoms
    case triggers
    case interventions
    
    func next() -> RecordingStep {
        RecordingStep(rawValue: self.rawValue + 1) ?? .interventions
    }
    
    func previous() -> RecordingStep {
        RecordingStep(rawValue: self.rawValue - 1) ?? .timeAndDuration
    }
    
    var title: String {
        switch self {
        case .timeAndDuration:
            return "时间与状态"
        case .painAssessment:
            return "疼痛评估"
        case .symptoms:
            return "症状与先兆"
        case .triggers:
            return "可能的诱因"
        case .interventions:
            return "干预措施"
        }
    }
    
    var stepNumber: String {
        "步骤 \(rawValue + 1)/\(RecordingStep.allCases.count)"
    }
}
