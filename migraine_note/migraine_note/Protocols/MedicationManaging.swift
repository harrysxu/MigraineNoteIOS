//
//  MedicationManaging.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/5.
//  药物管理协议
//

import Foundation
import SwiftData

/// 药物管理协议 - 统一 RecordingViewModel 和 HealthEventMedicationViewModel 的接口
protocol MedicationManaging: AnyObject, Observable {
    var selectedMedications: [(medication: Medication?, customName: String?, dosage: Double, unit: String, timeTaken: Date)] { get set }
    
    func addMedication(medication: Medication?, customName: String?, dosage: Double, unit: String, timeTaken: Date)
    func removeMedication(at index: Int)
    func syncMedicationToCabinet(name: String, dosage: Double, unit: String) -> Medication?
}
