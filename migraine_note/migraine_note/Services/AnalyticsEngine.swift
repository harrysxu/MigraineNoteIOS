//
//  AnalyticsEngine.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import Foundation
import SwiftData

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
            case 1...3:
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
        let healthEventDescriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startDate && 
                event.eventDate <= endDate &&
                event.eventTypeRawValue == "medication"
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
        
        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startDate && 
                event.eventDate <= endDate &&
                event.eventTypeRawValue == "tcmTreatment"
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
