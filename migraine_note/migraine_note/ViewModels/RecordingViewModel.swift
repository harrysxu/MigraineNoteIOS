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
    // 改用字符串名称存储疼痛性质，支持自定义标签
    var selectedPainQualityNames: Set<String> = []
    
    var hasAura: Bool = false
    // 改用字符串名称存储先兆类型，支持自定义标签
    var selectedAuraTypeNames: Set<String> = []
    var auraDuration: Double? // 分钟
    
    // 改用字符串名称存储症状，支持自定义标签
    var selectedSymptomNames: Set<String> = []
    var selectedTriggers: [String] = []
    
    var selectedMedications: [(medication: Medication?, customName: String?, dosage: Double, unit: String, timeTaken: Date)] = []
    var selectedNonPharmacological: Set<String> = []
    var notes: String = ""
    
    // 自定义输入
    var customPainQualities: [String] = []
    var customSymptoms: [String] = []
    var customNonPharmacological: [String] = []
    
    // 天气管理状态
    var currentWeatherSnapshot: WeatherSnapshot?
    var isWeatherManuallyEdited: Bool = false
    var startTimeWhenWeatherFetched: Date?
    var isLoadingWeather: Bool = false
    
    private let modelContext: ModelContext
    private var weatherManager: WeatherManager?
    
    init(modelContext: ModelContext, editingAttack: AttackRecord? = nil, weatherManager: WeatherManager? = nil) {
        self.modelContext = modelContext
        self.weatherManager = weatherManager
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
    
    // MARK: - 天气管理
    
    /// 检查开始时间是否改变（用于显示提示）
    var hasStartTimeChanged: Bool {
        guard let fetchedTime = startTimeWhenWeatherFetched else { return false }
        return abs(startTime.timeIntervalSince(fetchedTime)) > 60 // 超过1分钟视为改变
    }
    
    /// 根据当前开始时间获取天气
    func fetchWeatherForCurrentTime() async {
        guard let weatherManager = weatherManager,
              let location = weatherManager.currentLocation else {
            print("⚠️ 无法获取天气：位置信息不可用")
            return
        }
        
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        
        // WeatherKit 历史数据的起始日期：2021年8月1日
        let weatherKitHistoricalStartDate = DateComponents(
            calendar: Calendar.current,
            year: 2021,
            month: 8,
            day: 1
        ).date!
        
        // 判断开始时间是否在 WeatherKit 历史数据范围内
        guard startTime >= weatherKitHistoricalStartDate else {
            print("⚠️ 开始时间早于 WeatherKit 历史数据范围（2021-08-01），不获取天气")
            currentWeatherSnapshot = nil
            return
        }
        
        do {
            let weatherSnapshot: WeatherSnapshot
            
            // 判断开始时间是否在过去（超过1小时视为历史记录）
            let hoursSinceStart = Date().timeIntervalSince(startTime) / 3600
            
            if hoursSinceStart > 1 {
                // 获取历史天气
                let daysSinceStart = Calendar.current.dateComponents([.day], from: startTime, to: Date()).day ?? 0
                print("🕐 开始时间为 \(daysSinceStart) 天前，获取历史天气数据")
                weatherSnapshot = try await weatherManager.fetchHistoricalWeather(for: startTime, at: location)
            } else {
                // 1小时内的记录，获取当前天气
                print("🌤️ 开始时间在1小时内，获取当前天气数据")
                weatherSnapshot = try await weatherManager.fetchCurrentWeather()
            }
            
            currentWeatherSnapshot = weatherSnapshot
            startTimeWhenWeatherFetched = startTime
            isWeatherManuallyEdited = false
            
        } catch {
            print("❌ 获取天气数据失败: \(error.localizedDescription)")
            currentWeatherSnapshot = nil
        }
    }
    
    /// 刷新天气
    func refreshWeather() async {
        await fetchWeatherForCurrentTime()
    }
    
    /// 更新天气快照（手动编辑后）
    func updateWeatherSnapshot(_ snapshot: WeatherSnapshot) {
        snapshot.isManuallyEdited = true
        currentWeatherSnapshot = snapshot
        isWeatherManuallyEdited = true
    }
    
    // MARK: - 加载现有记录（编辑模式）
    
    func loadExistingAttack(_ attack: AttackRecord) {
        self.currentAttack = attack
        self.isEditMode = true
        
        // 加载时间数据
        self.startTime = attack.startTime
        self.endTime = attack.endTime
        self.isOngoing = attack.endTime == nil
        
        // 加载天气数据
        if let weather = attack.weatherSnapshot {
            self.currentWeatherSnapshot = weather
            self.startTimeWhenWeatherFetched = attack.startTime
            self.isWeatherManuallyEdited = weather.isManuallyEdited
        }
        
        // 加载疼痛评估数据
        self.selectedPainIntensity = attack.painIntensity
        self.selectedPainLocations = Set(attack.painLocations)
        self.selectedPainQualities = Set(attack.painQualities)
        // 加载疼痛性质名称
        self.selectedPainQualityNames = Set(attack.painQuality)
        
        // 加载先兆数据
        self.hasAura = attack.hasAura
        self.selectedAuraTypeNames = Set(attack.auraTypesList.map { $0.rawValue })
        if let duration = attack.auraDuration, duration > 0 {
            self.auraDuration = duration / 60.0 // 转换为分钟
        }
        
        // 加载症状（使用名称）
        self.selectedSymptomNames = Set(attack.symptoms.map { $0.name })
        
        // 加载诱因
        self.selectedTriggers = attack.triggers.map { $0.name }
        
        // 加载用药记录
        self.selectedMedications = attack.medications.map { log in
            (
                medication: log.medication,
                customName: log.medication == nil ? log.medicationName : nil,
                dosage: log.dosage,
                unit: log.unit ?? "mg",
                timeTaken: log.takenAt
            )
        }
        
        // 加载备注
        self.notes = attack.notes ?? ""
    }
    
    // MARK: - 保存记录
    
    func saveRecording() async throws {
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
            
            // 清除旧的天气数据
            if let oldWeather = attack.weatherSnapshot {
                modelContext.delete(oldWeather)
                attack.weatherSnapshot = nil
            }
        } else {
            // 新建模式：创建新记录
            attack = currentAttack ?? AttackRecord(startTime: startTime)
            if currentAttack == nil {
                modelContext.insert(attack)
            }
        }
        
        // 关联天气数据（使用已获取或编辑的天气）
        if let weatherSnapshot = currentWeatherSnapshot {
            // 如果是新建模式或编辑模式，需要将天气快照插入到上下文中
            if weatherSnapshot.modelContext == nil {
                modelContext.insert(weatherSnapshot)
            }
            attack.weatherSnapshot = weatherSnapshot
        }
        
        // 设置时间
        attack.startTime = startTime
        attack.endTime = isOngoing ? nil : endTime
        
        // 设置疼痛评估
        attack.painIntensity = selectedPainIntensity
        attack.painLocation = selectedPainLocations.map { $0.rawValue }
        // 保存疼痛性质名称（支持自定义）
        attack.painQuality = Array(selectedPainQualityNames)
        
        // 设置先兆
        attack.hasAura = hasAura
        if hasAura {
            // 将字符串名称转换回枚举（如果可能），否则保留字符串
            let auraTypes = selectedAuraTypeNames.compactMap { AuraType(rawValue: $0) }
            attack.setAuraTypes(auraTypes)
            if let duration = auraDuration {
                attack.auraDuration = duration * 60 // 转换为秒
            }
        }
        
        // 添加症状（从选中的名称创建）
        for symptomName in selectedSymptomNames {
            // 尝试转换为 SymptomType，如果失败则作为自定义症状
            if let symptomType = SymptomType(rawValue: symptomName) {
                let symptom = Symptom(type: symptomType)
                attack.symptoms.append(symptom)
                modelContext.insert(symptom)
            } else {
                // 自定义症状
                let symptom = Symptom(type: .nausea) // 使用默认类型
                symptom.typeRawValue = symptomName // 直接设置为自定义值
                attack.symptoms.append(symptom)
                modelContext.insert(symptom)
            }
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
            medLog.unit = medInfo.unit
            // 如果没有关联药物，保存自定义名称
            if medInfo.medication == nil, let customName = medInfo.customName {
                medLog.medicationName = customName
            }
            attack.medications.append(medLog)
            modelContext.insert(medLog)
        }
        
        // 保存非药物干预（合并预设的和自定义的）
        attack.nonPharmInterventionList = Array(selectedNonPharmacological) + customNonPharmacological
        
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
        selectedPainQualityNames = []
        
        hasAura = false
        selectedAuraTypeNames = []
        auraDuration = nil
        
        selectedSymptomNames = []
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
    
    // MARK: - 快速记录（一键开始/结束）
    
    /// 快速开始记录 - 立即创建并保存AttackRecord，只记录开始时间
    func quickStartRecording() -> AttackRecord {
        let attack = AttackRecord(startTime: Date())
        modelContext.insert(attack)
        try? modelContext.save()
        return attack
    }
    
    /// 快速结束记录 - 更新结束时间
    func quickEndRecording(_ attack: AttackRecord) {
        attack.endTime = Date()
        attack.updatedAt = Date()
        try? modelContext.save()
    }
    
    // MARK: - 用药管理
    
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
        
        // 在内存中进行不区分大小写的比较
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
            category: .other,  // 默认类型：其他
            isAcute: true      // 默认为急需用药
        )
        medication.standardDosage = 1.0  // 默认标准剂量
        medication.unit = unit
        medication.inventory = 6  // 默认库存
        medication.monthlyLimit = nil  // 其他类型不设置MOH限制
        
        modelContext.insert(medication)
        try? modelContext.save()
        
        return medication
    }
    
    // MARK: - 取消记录
    
    /// 取消记录 - 删除已创建但未保存的记录
    func cancelRecording() {
        // 只在非编辑模式下删除记录
        if !isEditMode, let attack = currentAttack {
            modelContext.delete(attack)
            try? modelContext.save()
        }
        reset()
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
