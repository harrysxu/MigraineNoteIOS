//
//  TestHelpers.swift
//  migraine_noteTests
//
//  公共测试基础设施：SwiftData内存容器工厂、测试数据辅助方法
//

import XCTest
import SwiftData
@testable import migraine_note

// MARK: - SwiftData 测试容器工厂

/// 创建包含所有Model的内存测试容器
func makeTestModelContainer() throws -> ModelContainer {
    let schema = Schema([
        AttackRecord.self,
        Symptom.self,
        Trigger.self,
        MedicationLog.self,
        Medication.self,
        HealthEvent.self,
        WeatherSnapshot.self,
        CustomLabelConfig.self,
        UserProfile.self
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: config)
}

/// 创建测试用 ModelContext
func makeTestModelContext() throws -> ModelContext {
    let container = try makeTestModelContainer()
    return ModelContext(container)
}

// MARK: - 日期辅助方法

/// 创建当前时间之前指定天数的日期
func dateAgo(days: Int, hour: Int = 12) -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.day! -= days
    components.hour = hour
    components.minute = 0
    components.second = 0
    return calendar.date(from: components)!
}

/// 创建当前时间之前指定小时的日期
func dateAgo(hours: Double) -> Date {
    return Date().addingTimeInterval(-hours * 3600)
}

/// 创建指定年月日的日期
func makeDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components)!
}

// MARK: - 测试数据创建辅助方法

/// 创建并插入一条发作记录
@discardableResult
func createAttack(
    in context: ModelContext,
    startTime: Date = Date(),
    endTime: Date? = nil,
    painIntensity: Int = 5,
    painLocations: [PainLocation] = [],
    painQualities: [PainQuality] = [],
    hasAura: Bool = false,
    auraTypes: [AuraType] = [],
    notes: String? = nil
) -> AttackRecord {
    let attack = AttackRecord(startTime: startTime)
    attack.painIntensity = painIntensity
    attack.endTime = endTime
    attack.hasAura = hasAura
    attack.notes = notes
    
    if !painLocations.isEmpty {
        attack.setPainLocations(painLocations)
    }
    if !painQualities.isEmpty {
        attack.setPainQuality(painQualities)
    }
    if !auraTypes.isEmpty {
        attack.setAuraTypes(auraTypes)
        attack.hasAura = true
    }
    
    context.insert(attack)
    try? context.save()
    return attack
}

/// 创建一条已结束的发作记录（指定持续时间，单位小时）
@discardableResult
func createCompletedAttack(
    in context: ModelContext,
    startTime: Date = Date(),
    durationHours: Double = 2.0,
    painIntensity: Int = 5
) -> AttackRecord {
    let endTime = startTime.addingTimeInterval(durationHours * 3600)
    return createAttack(
        in: context,
        startTime: startTime,
        endTime: endTime,
        painIntensity: painIntensity
    )
}

/// 创建并插入一个药物
@discardableResult
func createMedication(
    in context: ModelContext,
    name: String = "布洛芬",
    category: MedicationCategory = .nsaid,
    isAcute: Bool = true,
    inventory: Int = 10
) -> Medication {
    let medication = Medication(name: name, category: category, isAcute: isAcute)
    medication.inventory = inventory
    context.insert(medication)
    try? context.save()
    return medication
}

/// 创建并插入一条用药记录，关联到发作记录
@discardableResult
func createMedicationLog(
    in context: ModelContext,
    medication: Medication? = nil,
    dosage: Double = 400,
    timeTaken: Date = Date(),
    attack: AttackRecord? = nil,
    healthEvent: HealthEvent? = nil
) -> MedicationLog {
    let log = MedicationLog(dosage: dosage, timeTaken: timeTaken)
    log.medication = medication
    if let unit = medication?.unit {
        log.unit = unit
    }
    
    if let attack = attack {
        attack.medications.append(log)
    }
    if let event = healthEvent {
        event.medicationLogs.append(log)
    }
    
    context.insert(log)
    try? context.save()
    return log
}

/// 创建并插入一个症状，关联到发作记录
@discardableResult
func createSymptom(
    in context: ModelContext,
    type: SymptomType = .nausea,
    severity: Int = 3,
    attack: AttackRecord
) -> Symptom {
    let symptom = Symptom(type: type, severity: severity)
    attack.symptoms.append(symptom)
    context.insert(symptom)
    try? context.save()
    return symptom
}

/// 创建并插入一个诱因，关联到发作记录
@discardableResult
func createTrigger(
    in context: ModelContext,
    category: TriggerCategory = .food,
    specificType: String = "巧克力",
    attack: AttackRecord
) -> Trigger {
    let trigger = Trigger(category: category, specificType: specificType)
    attack.triggers.append(trigger)
    context.insert(trigger)
    try? context.save()
    return trigger
}

/// 创建并插入一个健康事件
@discardableResult
func createHealthEvent(
    in context: ModelContext,
    eventType: HealthEventType = .medication,
    eventDate: Date = Date(),
    tcmTreatmentType: String? = nil,
    tcmDuration: TimeInterval? = nil,
    surgeryName: String? = nil,
    hospitalName: String? = nil,
    doctorName: String? = nil,
    notes: String? = nil
) -> HealthEvent {
    let event = HealthEvent(eventType: eventType, eventDate: eventDate)
    event.tcmTreatmentType = tcmTreatmentType
    event.tcmDuration = tcmDuration
    event.surgeryName = surgeryName
    event.hospitalName = hospitalName
    event.doctorName = doctorName
    event.notes = notes
    
    context.insert(event)
    try? context.save()
    return event
}

/// 创建一个天气快照
@discardableResult
func createWeatherSnapshot(
    in context: ModelContext,
    temperature: Double = 25.0,
    humidity: Double = 60.0,
    pressure: Double = 1013.0,
    pressureTrend: PressureTrend = .steady,
    windSpeed: Double = 5.0,
    condition: String = "晴",
    location: String = "北京"
) -> WeatherSnapshot {
    let snapshot = WeatherSnapshot()
    snapshot.temperature = temperature
    snapshot.humidity = humidity
    snapshot.pressure = pressure
    snapshot.pressureTrend = pressureTrend
    snapshot.windSpeed = windSpeed
    snapshot.condition = condition
    snapshot.location = location
    
    context.insert(snapshot)
    try? context.save()
    return snapshot
}
