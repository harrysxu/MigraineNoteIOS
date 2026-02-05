//
//  HealthEventMedicationViewModel.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/5.
//  健康事件用药管理ViewModel
//

import SwiftUI
import SwiftData

@Observable
class HealthEventMedicationViewModel: MedicationManaging {
    var selectedMedications: [(medication: Medication?, customName: String?, dosage: Double, unit: String, timeTaken: Date)] = []
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 药物管理
    
    func addMedication(
        medication: Medication?,
        customName: String? = nil,
        dosage: Double,
        unit: String = "mg",
        timeTaken: Date = Date()
    ) {
        selectedMedications.append((
            medication: medication,
            customName: customName,
            dosage: dosage,
            unit: unit,
            timeTaken: timeTaken
        ))
    }
    
    func removeMedication(at index: Int) {
        guard index < selectedMedications.count else { return }
        selectedMedications.remove(at: index)
    }
    
    /// 检查药箱中是否已存在同名药品
    func checkMedicationExists(name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let descriptor = FetchDescriptor<Medication>()
        
        guard let allMedications = try? modelContext.fetch(descriptor) else {
            return false
        }
        
        return allMedications.contains { medication in
            medication.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }
    
    /// 同步药品到药箱（使用默认值）
    @discardableResult
    func syncMedicationToCabinet(name: String, dosage: Double, unit: String) -> Medication? {
        // 检查是否已存在
        if checkMedicationExists(name: name) {
            return nil
        }
        
        let medication = Medication(
            name: name.trimmingCharacters(in: .whitespaces),
            category: .other,
            isAcute: true
        )
        medication.standardDosage = 1.0
        medication.unit = unit
        medication.inventory = 6
        medication.monthlyLimit = nil
        
        modelContext.insert(medication)
        
        do {
            try modelContext.save()
            return medication
        } catch {
            print("保存药品到药箱失败: \(error)")
            return nil
        }
    }
    
    /// 清空所有药物
    func clearAllMedications() {
        selectedMedications.removeAll()
    }
}
