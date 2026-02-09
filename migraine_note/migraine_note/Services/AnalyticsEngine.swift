//
//  AnalyticsEngine.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import Foundation
import SwiftData

/// 批量分析结果容器 - 一次计算所有分析指标，避免重复 CoreData 查询
struct BatchAnalyticsResult {
    let durationStats: DurationStatistics
    let triggerFrequency: [TriggerFrequencyData]
    let circadianPattern: [CircadianData]
    let painIntensityDistribution: PainIntensityDistribution
    let painLocationFrequency: [PainLocationFrequency]
    let painQualityFrequency: [PainQualityFrequency]
    let symptomFrequency: [SymptomFrequency]
    let auraStatistics: AuraStatistics
    let acuteMedicationUsage: MedicationUsageStatistics
    let healthEventStatistics: HealthEventStatistics
    let tcmTreatmentStats: TCMTreatmentStats
    
    // MARK: - 缓存的汇总统计（避免在 View 中重复计算）
    let totalAttacksCount: Int
    let attackDaysCount: Int
    let averagePainIntensity: Double
    let detailedMedicationStats: DetailedMedicationStatistics
    
    /// 从预加载的数据中一次性计算所有分析结果
    static func compute(attacks: [AttackRecord], healthEvents: [HealthEvent], dateRange: (Date, Date)) -> BatchAnalyticsResult {
        let calendar = Calendar.current
        
        // --- Duration Stats ---
        let completedAttacks = attacks.filter { $0.duration != nil }
        let durations = completedAttacks.compactMap { $0.duration }
        let durationStats: DurationStatistics
        if durations.isEmpty {
            durationStats = DurationStatistics(averageDuration: 0, longestDuration: 0, shortestDuration: 0)
        } else {
            durationStats = DurationStatistics(
                averageDuration: durations.reduce(0, +) / Double(durations.count),
                longestDuration: durations.max() ?? 0,
                shortestDuration: durations.min() ?? 0
            )
        }
        
        // --- Trigger Frequency ---
        var triggerCounts: [String: Int] = [:]
        for attack in attacks {
            for trigger in attack.triggers {
                triggerCounts[trigger.specificType, default: 0] += 1
            }
        }
        let totalTriggers = triggerCounts.values.reduce(0, +)
        let triggerFrequency = triggerCounts
            .map { TriggerFrequencyData(triggerName: $0.key, count: $0.value, percentage: totalTriggers > 0 ? Double($0.value) / Double(totalTriggers) * 100 : 0) }
            .sorted { $0.count > $1.count }
        
        // --- Circadian Pattern ---
        var hourDistribution: [Int: Int] = [:]
        for attack in attacks {
            let hour = calendar.component(.hour, from: attack.startTime)
            hourDistribution[hour, default: 0] += 1
        }
        let circadianPattern = (0..<24).map { CircadianData(hour: $0, count: hourDistribution[$0] ?? 0) }
        
        // --- Pain Intensity Distribution ---
        var mild = 0, moderate = 0, severe = 0
        for attack in attacks {
            switch attack.painIntensity {
            case 0...3: mild += 1
            case 4...6: moderate += 1
            case 7...10: severe += 1
            default: break
            }
        }
        let painIntensityDist = PainIntensityDistribution(mild: mild, moderate: moderate, severe: severe)
        
        // --- Pain Location Frequency ---
        var locationCounts: [String: Int] = [:]
        for attack in attacks {
            for location in attack.painLocation {
                locationCounts[location, default: 0] += 1
            }
        }
        let totalLocations = locationCounts.values.reduce(0, +)
        let painLocationFrequency = locationCounts
            .map { PainLocationFrequency(locationName: PainLocation(rawValue: $0.key)?.displayName ?? $0.key, count: $0.value, percentage: totalLocations > 0 ? Double($0.value) / Double(totalLocations) * 100 : 0) }
            .sorted { $0.count > $1.count }
        
        // --- Pain Quality Frequency ---
        var qualityCounts: [String: Int] = [:]
        for attack in attacks {
            for quality in attack.painQuality {
                qualityCounts[quality, default: 0] += 1
            }
        }
        let totalQualities = qualityCounts.values.reduce(0, +)
        let painQualityFrequency = qualityCounts
            .map { PainQualityFrequency(qualityName: $0.key, count: $0.value, percentage: totalQualities > 0 ? Double($0.value) / Double(totalQualities) * 100 : 0) }
            .sorted { $0.count > $1.count }
        
        // --- Symptom Frequency ---
        var symptomCounts: [String: Int] = [:]
        for attack in attacks {
            for symptom in attack.symptoms {
                symptomCounts[symptom.name, default: 0] += 1
            }
        }
        let totalAttacks = attacks.count
        let symptomFrequency = symptomCounts
            .map { SymptomFrequency(symptomName: $0.key, count: $0.value, percentage: totalAttacks > 0 ? Double($0.value) / Double(totalAttacks) * 100 : 0) }
            .sorted { $0.count > $1.count }
        
        // --- Aura Statistics ---
        let attacksWithAura = attacks.filter { $0.hasAura }.count
        var auraTypeCounts: [String: Int] = [:]
        for attack in attacks where attack.hasAura {
            for auraType in attack.auraTypes {
                auraTypeCounts[auraType, default: 0] += 1
            }
        }
        let auraTypeFrequency = auraTypeCounts
            .map { AuraTypeFrequency(typeName: $0.key, count: $0.value, percentage: attacksWithAura > 0 ? Double($0.value) / Double(attacksWithAura) * 100 : 0) }
            .sorted { $0.count > $1.count }
        let auraStatistics = AuraStatistics(totalAttacks: totalAttacks, attacksWithAura: attacksWithAura, auraTypeFrequency: auraTypeFrequency)
        
        // --- Acute Medication Usage (from attacks) ---
        var acuteTotalUses = 0
        var acuteMedDaysSet: Set<Date> = []
        var acuteCategoryCounts: [String: Int] = [:]
        var acuteMedNameCounts: [String: Int] = [:]
        for attack in attacks {
            if !attack.medications.isEmpty {
                acuteMedDaysSet.insert(calendar.startOfDay(for: attack.startTime))
            }
            for medLog in attack.medications {
                acuteTotalUses += 1
                if let medication = medLog.medication {
                    acuteCategoryCounts[medication.category.rawValue, default: 0] += 1
                    acuteMedNameCounts[medication.name, default: 0] += 1
                }
            }
        }
        let acuteCategories = acuteCategoryCounts
            .map { MedicationCategoryBreakdown(categoryName: $0.key, count: $0.value, percentage: acuteTotalUses > 0 ? Double($0.value) / Double(acuteTotalUses) * 100 : 0) }
            .sorted { $0.count > $1.count }
        let acuteTopMeds = acuteMedNameCounts
            .map { TopMedication(medicationName: $0.key, count: $0.value, percentage: acuteTotalUses > 0 ? Double($0.value) / Double(acuteTotalUses) * 100 : 0) }
            .sorted { $0.count > $1.count }
        let acuteMedicationUsage = MedicationUsageStatistics(totalMedicationUses: acuteTotalUses, medicationDays: acuteMedDaysSet.count, categoryBreakdown: acuteCategories, topMedications: acuteTopMeds)
        
        // --- Health Event Statistics ---
        let medicationEvents = healthEvents.filter { $0.eventType == .medication }
        let dailyMedDaysSet = Set(medicationEvents.filter { !$0.medicationLogs.isEmpty }.map { calendar.startOfDay(for: $0.eventDate) })
        let dailyMedicationCount = medicationEvents.reduce(0) { $0 + $1.medicationLogs.count }
        var dailyMedCategoryCounts: [String: Int] = [:]
        var dailyMedNameCounts: [String: Int] = [:]
        for event in medicationEvents {
            for log in event.medicationLogs {
                if let medication = log.medication {
                    dailyMedCategoryCounts[medication.category.rawValue, default: 0] += 1
                    dailyMedNameCounts[medication.name, default: 0] += 1
                } else if let name = log.medicationName {
                    dailyMedNameCounts[name, default: 0] += 1
                }
            }
        }
        let dailyMedCategories = dailyMedCategoryCounts
            .map { MedicationCategoryBreakdown(categoryName: $0.key, count: $0.value, percentage: dailyMedicationCount > 0 ? Double($0.value) / Double(dailyMedicationCount) * 100 : 0) }
            .sorted { $0.count > $1.count }
        let dailyTopMeds = dailyMedNameCounts
            .map { TopMedication(medicationName: $0.key, count: $0.value, percentage: dailyMedicationCount > 0 ? Double($0.value) / Double(dailyMedicationCount) * 100 : 0) }
            .sorted { $0.count > $1.count }
        
        let tcmEvents = healthEvents.filter { $0.eventType == .tcmTreatment }
        let tcmCount = tcmEvents.count
        var tcmTypeCounts: [String: Int] = [:]
        var totalTcmDuration: TimeInterval = 0
        for event in tcmEvents {
            if let type = event.tcmTreatmentType { tcmTypeCounts[type, default: 0] += 1 }
            if let duration = event.tcmDuration { totalTcmDuration += duration }
        }
        let tcmTypes = tcmTypeCounts
            .map { TreatmentTypeFrequency(typeName: $0.key, count: $0.value, percentage: tcmCount > 0 ? Double($0.value) / Double(tcmCount) * 100 : 0) }
            .sorted { $0.count > $1.count }
        let avgTcmDuration = tcmCount > 0 ? totalTcmDuration / Double(tcmCount) : 0
        
        let surgeryEvents = healthEvents.filter { $0.eventType == .surgery }
        let surgeryDetails = surgeryEvents.map { SurgeryDetail(name: $0.surgeryName ?? "手术记录", date: $0.eventDate, hospital: $0.hospitalName, doctor: $0.doctorName) }.sorted { $0.date > $1.date }
        
        let healthEventStats = HealthEventStatistics(
            dailyMedicationDays: dailyMedDaysSet.count,
            dailyMedicationCount: dailyMedicationCount,
            dailyMedCategories: dailyMedCategories,
            dailyTopMedications: dailyTopMeds,
            tcmTreatmentCount: tcmCount,
            tcmTreatmentTypes: tcmTypes,
            averageTcmDurationMinutes: Int(avgTcmDuration / 60),
            surgeryCount: surgeryEvents.count,
            surgeryDetails: surgeryDetails
        )
        
        let tcmTreatmentStats = TCMTreatmentStats(totalTreatments: tcmCount, treatmentTypes: tcmTypes, averageDuration: avgTcmDuration)
        
        // --- 汇总统计（一次计算，多处复用）---
        let attackDaysCount = Set(attacks.map { calendar.startOfDay(for: $0.startTime) }).count
        let averagePainIntensity: Double = totalAttacks > 0
            ? Double(attacks.reduce(0) { $0 + $1.painIntensity }) / Double(totalAttacks)
            : 0
        let detailedMedStats = DetailedMedicationStatistics.calculate(
            attacks: attacks,
            healthEvents: healthEvents,
            dateRange: dateRange
        )
        
        return BatchAnalyticsResult(
            durationStats: durationStats,
            triggerFrequency: triggerFrequency,
            circadianPattern: circadianPattern,
            painIntensityDistribution: painIntensityDist,
            painLocationFrequency: painLocationFrequency,
            painQualityFrequency: painQualityFrequency,
            symptomFrequency: symptomFrequency,
            auraStatistics: auraStatistics,
            acuteMedicationUsage: acuteMedicationUsage,
            healthEventStatistics: healthEventStats,
            tcmTreatmentStats: tcmTreatmentStats,
            totalAttacksCount: totalAttacks,
            attackDaysCount: attackDaysCount,
            averagePainIntensity: averagePainIntensity,
            detailedMedicationStats: detailedMedStats
        )
    }
}

class AnalyticsEngine {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 月度统计
    
    /// 计算指定月份的统计数据
    func calculateMonthlyStats(for month: Date) throws -> MonthlyStats {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startOfMonth && attack.startTime < endOfMonth
            }
        )
        
        let attacks = try modelContext.fetch(descriptor)
        
        guard !attacks.isEmpty else {
            return MonthlyStats(
                totalAttacks: 0,
                averagePainIntensity: 0,
                medicationDays: 0,
                mohRisk: false
            )
        }
        
        let totalDays = attacks.count
        let averagePain = attacks.reduce(0.0) { $0 + Double($1.painIntensity) } / Double(attacks.count)
        
        // 计算用药天数（去重）
        let medicationDays = Set(
            attacks
                .filter { !$0.medications.isEmpty }
                .map { calendar.startOfDay(for: $0.startTime) }
        ).count
        
        return MonthlyStats(
            totalAttacks: totalDays,
            averagePainIntensity: averagePain,
            medicationDays: medicationDays,
            mohRisk: medicationDays > 10
        )
    }
    
    // MARK: - 诱因分析
    
    /// 分析诱因频次
    func analyzeTriggerFrequency(in dateRange: (Date, Date)) -> [TriggerFrequencyData] {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else { return [] }
        
        guard !attacks.isEmpty else { return [] }
        
        var triggerCounts: [String: Int] = [:]
        
        for attack in attacks {
            for trigger in attack.triggers {
                triggerCounts[trigger.specificType, default: 0] += 1
            }
        }
        
        let totalCount = triggerCounts.values.reduce(0, +)
        
        return triggerCounts
            .map { name, count in
                TriggerFrequencyData(
                    triggerName: name,
                    count: count,
                    percentage: Double(count) / Double(totalCount) * 100
                )
            }
            .sorted { $0.count > $1.count }
    }
    
    // MARK: - 昼夜节律分析
    
    /// 分析发作的昼夜规律
    func analyzeCircadianPattern(in dateRange: (Date, Date)) -> [CircadianData] {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else { return [] }
        
        var hourDistribution: [Int: Int] = [:]
        
        for attack in attacks {
            let hour = Calendar.current.component(.hour, from: attack.startTime)
            hourDistribution[hour, default: 0] += 1
        }
        
        // 确保返回完整的24小时数据，没有数据的小时计数为0
        return (0..<24).map { hour in
            CircadianData(hour: hour, count: hourDistribution[hour] ?? 0)
        }
    }
    
    // MARK: - 疼痛强度分布统计
    
    /// 分析疼痛强度分布（轻度1-3、中度4-6、重度7-10）
    func analyzePainIntensityDistribution(in dateRange: (Date, Date)) -> PainIntensityDistribution {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else {
            return PainIntensityDistribution(mild: 0, moderate: 0, severe: 0)
        }
        
        var mild = 0
        var moderate = 0
        var severe = 0
        
        for attack in attacks {
            switch attack.painIntensity {
            case 0...3:
                mild += 1
            case 4...6:
                moderate += 1
            case 7...10:
                severe += 1
            default:
                break
            }
        }
        
        return PainIntensityDistribution(mild: mild, moderate: moderate, severe: severe)
    }
    
    // MARK: - 疼痛部位频次统计
    
    /// 分析疼痛部位频次
    func analyzePainLocationFrequency(in dateRange: (Date, Date)) -> [PainLocationFrequency] {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else { return [] }
        guard !attacks.isEmpty else { return [] }
        
        var locationCounts: [String: Int] = [:]
        
        for attack in attacks {
            for location in attack.painLocation {
                locationCounts[location, default: 0] += 1
            }
        }
        
        let totalCount = locationCounts.values.reduce(0, +)
        
        return locationCounts
            .map { location, count in
                PainLocationFrequency(
                    locationName: PainLocation(rawValue: location)?.displayName ?? location,
                    count: count,
                    percentage: Double(count) / Double(totalCount) * 100
                )
            }
            .sorted { $0.count > $1.count }
    }
    
    // MARK: - 疼痛性质频次统计
    
    /// 分析疼痛性质频次
    func analyzePainQualityFrequency(in dateRange: (Date, Date)) -> [PainQualityFrequency] {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else { return [] }
        guard !attacks.isEmpty else { return [] }
        
        var qualityCounts: [String: Int] = [:]
        
        for attack in attacks {
            for quality in attack.painQuality {
                qualityCounts[quality, default: 0] += 1
            }
        }
        
        let totalCount = qualityCounts.values.reduce(0, +)
        
        return qualityCounts
            .map { quality, count in
                PainQualityFrequency(
                    qualityName: quality,
                    count: count,
                    percentage: Double(count) / Double(totalCount) * 100
                )
            }
            .sorted { $0.count > $1.count }
    }
    
    // MARK: - 症状频次统计
    
    /// 分析伴随症状频次
    func analyzeSymptomFrequency(in dateRange: (Date, Date)) -> [SymptomFrequency] {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else { return [] }
        guard !attacks.isEmpty else { return [] }
        
        var symptomCounts: [String: Int] = [:]
        
        for attack in attacks {
            for symptom in attack.symptoms {
                symptomCounts[symptom.name, default: 0] += 1
            }
        }
        
        let totalAttacks = attacks.count
        
        return symptomCounts
            .map { name, count in
                SymptomFrequency(
                    symptomName: name,
                    count: count,
                    percentage: Double(count) / Double(totalAttacks) * 100
                )
            }
            .sorted { $0.count > $1.count }
    }
    
    // MARK: - 先兆统计
    
    /// 分析先兆统计
    func analyzeAuraStatistics(in dateRange: (Date, Date)) -> AuraStatistics {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else {
            return AuraStatistics(totalAttacks: 0, attacksWithAura: 0, auraTypeFrequency: [])
        }
        
        let totalAttacks = attacks.count
        let attacksWithAura = attacks.filter { $0.hasAura }.count
        
        var auraTypeCounts: [String: Int] = [:]
        
        for attack in attacks where attack.hasAura {
            for auraType in attack.auraTypes {
                auraTypeCounts[auraType, default: 0] += 1
            }
        }
        
        let auraTypeFrequency = auraTypeCounts
            .map { type, count in
                AuraTypeFrequency(
                    typeName: type,
                    count: count,
                    percentage: Double(count) / Double(attacksWithAura) * 100
                )
            }
            .sorted { $0.count > $1.count }
        
        return AuraStatistics(
            totalAttacks: totalAttacks,
            attacksWithAura: attacksWithAura,
            auraTypeFrequency: auraTypeFrequency
        )
    }
    
    // MARK: - 用药统计
    
    /// 分析用药统计
    func analyzeMedicationUsage(in dateRange: (Date, Date)) -> MedicationUsageStatistics {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else {
            return MedicationUsageStatistics(
                totalMedicationUses: 0,
                medicationDays: 0,
                categoryBreakdown: [],
                topMedications: []
            )
        }
        
        let calendar = Calendar.current
        var totalUses = 0
        var medicationDaysSet: Set<Date> = []
        var categoryCounts: [String: Int] = [:]
        var medicationCounts: [String: Int] = [:]
        
        for attack in attacks {
            if !attack.medications.isEmpty {
                medicationDaysSet.insert(calendar.startOfDay(for: attack.startTime))
            }
            
            for medLog in attack.medications {
                totalUses += 1
                
                // 统计药物分类
                if let medication = medLog.medication {
                    let category = medication.category.rawValue
                    categoryCounts[category, default: 0] += 1
                    medicationCounts[medication.name, default: 0] += 1
                }
            }
        }
        
        let categoryBreakdown = categoryCounts
            .map { category, count in
                MedicationCategoryBreakdown(
                    categoryName: category,
                    count: count,
                    percentage: Double(count) / Double(totalUses) * 100
                )
            }
            .sorted { $0.count > $1.count }
        
        let topMedications = medicationCounts
            .map { name, count in
                TopMedication(
                    medicationName: name,
                    count: count,
                    percentage: Double(count) / Double(totalUses) * 100
                )
            }
            .sorted { $0.count > $1.count }
        
        return MedicationUsageStatistics(
            totalMedicationUses: totalUses,
            medicationDays: medicationDaysSet.count,
            categoryBreakdown: categoryBreakdown,
            topMedications: topMedications
        )
    }
    
    // MARK: - 持续时间统计
    
    /// 分析发作持续时间统计
    func analyzeDurationStatistics(in dateRange: (Date, Date)) -> DurationStatistics {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else {
            return DurationStatistics(averageDuration: 0, longestDuration: 0, shortestDuration: 0)
        }
        
        let completedAttacks = attacks.filter { $0.duration != nil }
        guard !completedAttacks.isEmpty else {
            return DurationStatistics(averageDuration: 0, longestDuration: 0, shortestDuration: 0)
        }
        
        let durations = completedAttacks.compactMap { $0.duration }
        let average = durations.reduce(0, +) / Double(durations.count)
        let longest = durations.max() ?? 0
        let shortest = durations.min() ?? 0
        
        return DurationStatistics(
            averageDuration: average,
            longestDuration: longest,
            shortestDuration: shortest
        )
    }
    
    // MARK: - 星期分布统计
    
    /// 分析发作的星期分布
    func analyzeWeekdayDistribution(in dateRange: (Date, Date)) -> [WeekdayDistribution] {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else { return [] }
        
        var weekdayCounts: [Int: Int] = [:]
        
        for attack in attacks {
            let weekday = Calendar.current.component(.weekday, from: attack.startTime)
            weekdayCounts[weekday, default: 0] += 1
        }
        
        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        
        return (1...7).map { weekday in
            WeekdayDistribution(
                weekday: weekday,
                weekdayName: weekdayNames[weekday - 1],
                count: weekdayCounts[weekday] ?? 0
            )
        }
    }
    
    /// 分析用药依从性
    func analyzeMedicationAdherence(in dateRange: (Date, Date)) -> MedicationAdherenceStats {
        let startDate = dateRange.0
        let endDate = dateRange.1
        let calendar = Calendar.current
        
        // 查询健康事件中的用药记录
        let medicationRawValue = HealthEventType.medication.rawValue
        let healthEventDescriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startDate && 
                event.eventDate <= endDate &&
                event.eventTypeRawValue == medicationRawValue
            }
        )
        
        guard let healthEvents = try? modelContext.fetch(healthEventDescriptor) else {
            return MedicationAdherenceStats(totalDays: 0, medicationDays: 0, missedDays: 0)
        }
        
        // 获取用药的天数
        let medicationDays = Set(healthEvents.map { calendar.startOfDay(for: $0.eventDate) })
        
        // 计算日期范围内的总天数
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let missedDays = totalDays - medicationDays.count
        
        return MedicationAdherenceStats(
            totalDays: totalDays,
            medicationDays: medicationDays.count,
            missedDays: max(0, missedDays)
        )
    }
    
    /// 分析中医治疗统计
    func analyzeTCMTreatment(in dateRange: (Date, Date)) -> TCMTreatmentStats {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let tcmRawValue = HealthEventType.tcmTreatment.rawValue
        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startDate && 
                event.eventDate <= endDate &&
                event.eventTypeRawValue == tcmRawValue
            }
        )
        
        guard let tcmEvents = try? modelContext.fetch(descriptor) else {
            return TCMTreatmentStats(totalTreatments: 0, treatmentTypes: [])
        }
        
        var typeCounts: [String: Int] = [:]
        var totalDuration: TimeInterval = 0
        
        for event in tcmEvents {
            if let type = event.tcmTreatmentType {
                typeCounts[type, default: 0] += 1
            }
            if let duration = event.tcmDuration {
                totalDuration += duration
            }
        }
        
        let totalCount = tcmEvents.count
        let treatmentTypes = typeCounts.map { type, count in
            TreatmentTypeFrequency(
                typeName: type,
                count: count,
                percentage: Double(count) / Double(totalCount) * 100
            )
        }.sorted { $0.count > $1.count }
        
        return TCMTreatmentStats(
            totalTreatments: totalCount,
            treatmentTypes: treatmentTypes,
            averageDuration: totalCount > 0 ? totalDuration / Double(totalCount) : 0
        )
    }
    
    // MARK: - 健康事件综合统计
    
    /// 分析健康事件综合统计（日常用药、中医治疗、手术）
    func analyzeHealthEventStatistics(in dateRange: (Date, Date)) -> HealthEventStatistics {
        let startDate = dateRange.0
        let endDate = dateRange.1
        let calendar = Calendar.current
        
        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startDate && event.eventDate <= endDate
            }
        )
        
        guard let healthEvents = try? modelContext.fetch(descriptor) else {
            return HealthEventStatistics.empty
        }
        
        // --- 日常用药统计 ---
        let medicationEvents = healthEvents.filter { $0.eventType == .medication }
        let dailyMedDaysSet = Set(
            medicationEvents
                .filter { !$0.medicationLogs.isEmpty }
                .map { calendar.startOfDay(for: $0.eventDate) }
        )
        let dailyMedicationDays = dailyMedDaysSet.count
        let dailyMedicationCount = medicationEvents.reduce(0) { $0 + $1.medicationLogs.count }
        
        // 日常用药药物分类统计
        var dailyMedCategoryCounts: [String: Int] = [:]
        var dailyMedNameCounts: [String: Int] = [:]
        for event in medicationEvents {
            for log in event.medicationLogs {
                if let medication = log.medication {
                    dailyMedCategoryCounts[medication.category.rawValue, default: 0] += 1
                    dailyMedNameCounts[medication.name, default: 0] += 1
                } else if let name = log.medicationName {
                    dailyMedNameCounts[name, default: 0] += 1
                }
            }
        }
        
        let dailyMedCategories = dailyMedCategoryCounts
            .map { category, count in
                MedicationCategoryBreakdown(
                    categoryName: category,
                    count: count,
                    percentage: dailyMedicationCount > 0 ? Double(count) / Double(dailyMedicationCount) * 100 : 0
                )
            }
            .sorted { $0.count > $1.count }
        
        let dailyTopMedications = dailyMedNameCounts
            .map { name, count in
                TopMedication(
                    medicationName: name,
                    count: count,
                    percentage: dailyMedicationCount > 0 ? Double(count) / Double(dailyMedicationCount) * 100 : 0
                )
            }
            .sorted { $0.count > $1.count }
        
        // --- 中医治疗统计 ---
        let tcmEvents = healthEvents.filter { $0.eventType == .tcmTreatment }
        let tcmTreatmentCount = tcmEvents.count
        var tcmTypeCounts: [String: Int] = [:]
        var totalTcmDuration: TimeInterval = 0
        
        for event in tcmEvents {
            if let type = event.tcmTreatmentType {
                tcmTypeCounts[type, default: 0] += 1
            }
            if let duration = event.tcmDuration {
                totalTcmDuration += duration
            }
        }
        
        let tcmTreatmentTypes = tcmTypeCounts.map { type, count in
            TreatmentTypeFrequency(
                typeName: type,
                count: count,
                percentage: tcmTreatmentCount > 0 ? Double(count) / Double(tcmTreatmentCount) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
        
        let avgTcmDuration = tcmTreatmentCount > 0 ? totalTcmDuration / Double(tcmTreatmentCount) : 0
        
        // --- 手术统计 ---
        let surgeryEvents = healthEvents.filter { $0.eventType == .surgery }
        let surgeryCount = surgeryEvents.count
        let surgeryDetails = surgeryEvents.map { event in
            SurgeryDetail(
                name: event.surgeryName ?? "手术记录",
                date: event.eventDate,
                hospital: event.hospitalName,
                doctor: event.doctorName
            )
        }.sorted { $0.date > $1.date }
        
        return HealthEventStatistics(
            dailyMedicationDays: dailyMedicationDays,
            dailyMedicationCount: dailyMedicationCount,
            dailyMedCategories: dailyMedCategories,
            dailyTopMedications: dailyTopMedications,
            tcmTreatmentCount: tcmTreatmentCount,
            tcmTreatmentTypes: tcmTreatmentTypes,
            averageTcmDurationMinutes: Int(avgTcmDuration / 60),
            surgeryCount: surgeryCount,
            surgeryDetails: surgeryDetails
        )
    }
    
    // MARK: - 急性用药详细统计（来自发作记录）
    
    /// 分析急性用药统计（仅来自发作记录中的用药）
    func analyzeAcuteMedicationUsage(in dateRange: (Date, Date)) -> MedicationUsageStatistics {
        let startDate = dateRange.0
        let endDate = dateRange.1
        
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else {
            return MedicationUsageStatistics(
                totalMedicationUses: 0,
                medicationDays: 0,
                categoryBreakdown: [],
                topMedications: []
            )
        }
        
        let calendar = Calendar.current
        var totalUses = 0
        var medicationDaysSet: Set<Date> = []
        var categoryCounts: [String: Int] = [:]
        var medicationCounts: [String: Int] = [:]
        
        for attack in attacks {
            if !attack.medications.isEmpty {
                medicationDaysSet.insert(calendar.startOfDay(for: attack.startTime))
            }
            
            for medLog in attack.medications {
                totalUses += 1
                if let medication = medLog.medication {
                    let category = medication.category.rawValue
                    categoryCounts[category, default: 0] += 1
                    medicationCounts[medication.name, default: 0] += 1
                }
            }
        }
        
        let categoryBreakdown = categoryCounts
            .map { category, count in
                MedicationCategoryBreakdown(
                    categoryName: category,
                    count: count,
                    percentage: totalUses > 0 ? Double(count) / Double(totalUses) * 100 : 0
                )
            }
            .sorted { $0.count > $1.count }
        
        let topMedications = medicationCounts
            .map { name, count in
                TopMedication(
                    medicationName: name,
                    count: count,
                    percentage: totalUses > 0 ? Double(count) / Double(totalUses) * 100 : 0
                )
            }
            .sorted { $0.count > $1.count }
        
        return MedicationUsageStatistics(
            totalMedicationUses: totalUses,
            medicationDays: medicationDaysSet.count,
            categoryBreakdown: categoryBreakdown,
            topMedications: topMedications
        )
    }
    
    /// 分析治疗与发作的关联（治疗开始前后的发作频率对比）
    func analyzeCorrelationBetweenTreatmentAndAttacks(
        treatmentType: HealthEventType,
        beforeDays: Int = 30,
        afterDays: Int = 30
    ) -> TreatmentCorrelationResult? {
        // 查询该类型的所有治疗事件
        let treatmentDescriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventTypeRawValue == treatmentType.rawValue
            },
            sortBy: [SortDescriptor(\.eventDate)]
        )
        
        guard let treatments = try? modelContext.fetch(treatmentDescriptor),
              let firstTreatment = treatments.first else {
            return nil
        }
        
        let calendar = Calendar.current
        let treatmentDate = firstTreatment.eventDate
        
        guard let beforeStart = calendar.date(byAdding: .day, value: -beforeDays, to: treatmentDate),
              let afterEnd = calendar.date(byAdding: .day, value: afterDays, to: treatmentDate) else {
            return nil
        }
        
        // 查询治疗前的发作记录
        let beforeDescriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= beforeStart && attack.startTime < treatmentDate
            }
        )
        
        // 查询治疗后的发作记录
        let afterDescriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= treatmentDate && attack.startTime <= afterEnd
            }
        )
        
        guard let beforeAttacks = try? modelContext.fetch(beforeDescriptor),
              let afterAttacks = try? modelContext.fetch(afterDescriptor) else {
            return nil
        }
        
        // 计算发作天数（去重）
        let beforeAttackDays = Set(beforeAttacks.map { calendar.startOfDay(for: $0.startTime) }).count
        let afterAttackDays = Set(afterAttacks.map { calendar.startOfDay(for: $0.startTime) }).count
        
        // 计算平均强度
        let beforeAvgIntensity = beforeAttacks.isEmpty ? 0 : 
            Double(beforeAttacks.reduce(0) { $0 + $1.painIntensity }) / Double(beforeAttacks.count)
        let afterAvgIntensity = afterAttacks.isEmpty ? 0 : 
            Double(afterAttacks.reduce(0) { $0 + $1.painIntensity }) / Double(afterAttacks.count)
        
        return TreatmentCorrelationResult(
            treatmentStartDate: treatmentDate,
            beforeAttackDays: beforeAttackDays,
            afterAttackDays: afterAttackDays,
            beforeAvgIntensity: beforeAvgIntensity,
            afterAvgIntensity: afterAvgIntensity
        )
    }
}

// MARK: - 数据结构

struct MonthlyStats {
    let totalAttacks: Int
    let averagePainIntensity: Double
    let medicationDays: Int
    let mohRisk: Bool
    
    var disabilityLevel: DisabilityLevel {
        switch totalAttacks {
        case 0...4:
            return .minimal
        case 5...10:
            return .mild
        case 11...14:
            return .moderate
        case 15...:
            return .chronic
        default:
            return .minimal
        }
    }
}

enum DisabilityLevel: String {
    case minimal = "轻微"
    case mild = "轻度"
    case moderate = "中度"
    case chronic = "慢性"
    
    var description: String {
        switch self {
        case .minimal:
            return "发作较少，对生活影响轻微"
        case .mild:
            return "发作适中，建议关注诱因"
        case .moderate:
            return "发作频繁，建议咨询医生"
        case .chronic:
            return "达到慢性偏头痛标准，请尽快就医"
        }
    }
}

struct TriggerFrequency: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Double
    
    var rank: Int = 0
}

struct TriggerFrequencyData: Identifiable {
    let id = UUID()
    let triggerName: String
    let count: Int
    let percentage: Double
}

struct CircadianPattern {
    let hourDistribution: [Int: Int]
    let peakHours: [Int]
    
    var peakTimeDescription: String {
        if peakHours.isEmpty {
            return "无明显规律"
        } else if peakHours.allSatisfy({ $0 >= 6 && $0 < 12 }) {
            return "早晨 (6:00-12:00)"
        } else if peakHours.allSatisfy({ $0 >= 12 && $0 < 18 }) {
            return "下午 (12:00-18:00)"
        } else if peakHours.allSatisfy({ $0 >= 18 || $0 < 6 }) {
            return "晚间/夜间 (18:00-6:00)"
        } else {
            return "混合时段"
        }
    }
}

struct CircadianData: Identifiable {
    let id = UUID()
    let hour: Int
    let count: Int
}

// MARK: - 疼痛强度分布数据结构

struct PainIntensityDistribution {
    let mild: Int       // 轻度 1-3
    let moderate: Int   // 中度 4-6
    let severe: Int     // 重度 7-10
    
    var total: Int {
        mild + moderate + severe
    }
    
    var mildPercentage: Double {
        total > 0 ? Double(mild) / Double(total) * 100 : 0
    }
    
    var moderatePercentage: Double {
        total > 0 ? Double(moderate) / Double(total) * 100 : 0
    }
    
    var severePercentage: Double {
        total > 0 ? Double(severe) / Double(total) * 100 : 0
    }
}

// MARK: - 疼痛部位频次数据结构

struct PainLocationFrequency: Identifiable {
    let id = UUID()
    let locationName: String
    let count: Int
    let percentage: Double
}

// MARK: - 疼痛性质频次数据结构

struct PainQualityFrequency: Identifiable {
    let id = UUID()
    let qualityName: String
    let count: Int
    let percentage: Double
}

// MARK: - 症状频次数据结构

struct SymptomFrequency: Identifiable {
    let id = UUID()
    let symptomName: String
    let count: Int
    let percentage: Double
}

// MARK: - 先兆统计数据结构

struct AuraStatistics {
    let totalAttacks: Int
    let attacksWithAura: Int
    let auraTypeFrequency: [AuraTypeFrequency]
    
    var auraPercentage: Double {
        totalAttacks > 0 ? Double(attacksWithAura) / Double(totalAttacks) * 100 : 0
    }
}

struct AuraTypeFrequency: Identifiable {
    let id = UUID()
    let typeName: String
    let count: Int
    let percentage: Double
}

// MARK: - 用药统计数据结构

struct MedicationUsageStatistics {
    let totalMedicationUses: Int
    let medicationDays: Int
    let categoryBreakdown: [MedicationCategoryBreakdown]
    let topMedications: [TopMedication]
}

struct MedicationCategoryBreakdown: Identifiable {
    let id = UUID()
    let categoryName: String
    let count: Int
    let percentage: Double
}

struct TopMedication: Identifiable {
    let id = UUID()
    let medicationName: String
    let count: Int
    let percentage: Double
}

// MARK: - 持续时间统计数据结构

struct DurationStatistics {
    let averageDuration: TimeInterval
    let longestDuration: TimeInterval
    let shortestDuration: TimeInterval
    
    var averageDurationHours: Double {
        averageDuration / 3600
    }
    
    var longestDurationHours: Double {
        longestDuration / 3600
    }
    
    var shortestDurationHours: Double {
        shortestDuration / 3600
    }
}

// MARK: - 星期分布数据结构

struct WeekdayDistribution: Identifiable {
    let id = UUID()
    let weekday: Int
    let weekdayName: String
    let count: Int
}

// MARK: - 健康事件统计数据结构

/// 用药依从性统计
struct MedicationAdherenceStats {
    let totalDays: Int          // 统计期间总天数
    let medicationDays: Int     // 实际用药天数
    let missedDays: Int         // 遗漏天数
    
    var adherenceRate: Double {
        totalDays > 0 ? Double(medicationDays) / Double(totalDays) * 100 : 0
    }
}

/// 中医治疗统计
struct TCMTreatmentStats {
    let totalTreatments: Int
    let treatmentTypes: [TreatmentTypeFrequency]
    var averageDuration: TimeInterval = 0
    
    var averageDurationMinutes: Int {
        Int(averageDuration / 60)
    }
}

struct TreatmentTypeFrequency: Identifiable {
    let id = UUID()
    let typeName: String
    let count: Int
    let percentage: Double
}

/// 治疗与发作关联分析结果
struct TreatmentCorrelationResult {
    let treatmentStartDate: Date
    let beforeAttackDays: Int      // 治疗前的发作天数
    let afterAttackDays: Int       // 治疗后的发作天数
    let beforeAvgIntensity: Double // 治疗前平均强度
    let afterAvgIntensity: Double  // 治疗后平均强度
    
    var attackDaysReduction: Int {
        beforeAttackDays - afterAttackDays
    }
    
    var intensityReduction: Double {
        beforeAvgIntensity - afterAvgIntensity
    }
    
    var hasImprovement: Bool {
        attackDaysReduction > 0 || intensityReduction > 0
    }
}

struct FrequencyResult: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Double
}

// MARK: - 健康事件综合统计数据结构

struct HealthEventStatistics {
    let dailyMedicationDays: Int           // 日常用药天数
    let dailyMedicationCount: Int          // 日常用药次数
    let dailyMedCategories: [MedicationCategoryBreakdown]  // 日常用药分类
    let dailyTopMedications: [TopMedication]               // 日常用药 Top 药物
    let tcmTreatmentCount: Int             // 中医治疗次数
    let tcmTreatmentTypes: [TreatmentTypeFrequency]        // 中医治疗类型分布
    let averageTcmDurationMinutes: Int     // 平均治疗时长（分钟）
    let surgeryCount: Int                  // 手术次数
    let surgeryDetails: [SurgeryDetail]    // 手术详情列表
    
    var hasDailyMedication: Bool { dailyMedicationCount > 0 }
    var hasTCMTreatment: Bool { tcmTreatmentCount > 0 }
    var hasSurgery: Bool { surgeryCount > 0 }
    var hasAnyEvent: Bool { hasDailyMedication || hasTCMTreatment || hasSurgery }
    
    var totalEvents: Int {
        dailyMedicationCount + tcmTreatmentCount + surgeryCount
    }
    
    static var empty: HealthEventStatistics {
        HealthEventStatistics(
            dailyMedicationDays: 0,
            dailyMedicationCount: 0,
            dailyMedCategories: [],
            dailyTopMedications: [],
            tcmTreatmentCount: 0,
            tcmTreatmentTypes: [],
            averageTcmDurationMinutes: 0,
            surgeryCount: 0,
            surgeryDetails: []
        )
    }
}

struct SurgeryDetail: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let hospital: String?
    let doctor: String?
}
