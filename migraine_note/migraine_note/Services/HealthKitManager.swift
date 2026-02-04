//
//  HealthKitManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import Foundation
import HealthKit

@Observable
class HealthKitManager {
    private let healthStore = HKHealthStore()
    var isAuthorized = false
    var authorizationError: Error?
    
    // 需要读取的数据类型
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    ]
    
    // 需要写入的数据类型
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.categoryType(forIdentifier: .headache)!
    ]
    
    // MARK: - 权限请求
    
    /// 请求HealthKit授权
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(
            toShare: writeTypes,
            read: readTypes
        )
        
        isAuthorized = true
    }
    
    // MARK: - 写入头痛记录
    
    /// 将发作记录同步到健康App
    func saveHeadache(attack: AttackRecord) async throws {
        guard let headacheType = HKObjectType.categoryType(forIdentifier: .headache) else {
            throw HealthKitError.invalidType
        }
        
        // 映射疼痛强度到HealthKit标准
        let severity: HKCategoryValueSeverity = mapPainIntensityToSeverity(attack.painIntensity)
        
        // 构建元数据
        var metadata: [String: Any] = [:]
        
        // 注意：HKMetadataKeyHeadacheSeverity 在较新版本的iOS中可能不可用
        // 我们直接存储severity值作为自定义metadata
        metadata["Severity"] = severity.rawValue
        
        if attack.hasAura {
            metadata["HasAura"] = true
            metadata["AuraTypes"] = attack.auraTypes.joined(separator: ",")
        }
        
        if !attack.painLocation.isEmpty {
            metadata["PainLocation"] = attack.painLocation.joined(separator: ",")
        }
        
        if !attack.painQuality.isEmpty {
            metadata["PainQuality"] = attack.painQuality.joined(separator: ",")
        }
        
        // 创建样本
        let endTime = attack.endTime ?? Date()
        let sample = HKCategorySample(
            type: headacheType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: attack.startTime,
            end: endTime,
            metadata: metadata
        )
        
        try await healthStore.save(sample)
    }
    
    private func mapPainIntensityToSeverity(_ intensity: Int) -> HKCategoryValueSeverity {
        switch intensity {
        case 0:
            return .notPresent
        case 1...3:
            return .mild
        case 4...6:
            return .moderate
        case 7...10:
            return .severe
        default:
            return .unspecified
        }
    }
    
    // MARK: - 读取睡眠数据
    
    /// 获取指定日期的睡眠时长（小时）
    func fetchSleepData(for date: Date) async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let calendar = Calendar.current
        // 查询前一天晚上到当天早上的睡眠
        let startOfDay = calendar.startOfDay(for: date)
        let startOfPreviousDay = calendar.date(byAdding: .day, value: -1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfPreviousDay,
            end: startOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // 计算总睡眠时长（仅统计asleep和asleepCore/Deep/REM）
                let totalSleep = sleepSamples
                    .filter { sample in
                        if #available(iOS 16.0, *) {
                            return sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                        } else {
                            return sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue
                        }
                    }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                
                continuation.resume(returning: totalSleep / 3600.0) // 转换为小时
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 读取月经周期数据
    
    /// 获取指定日期处于月经周期的第几天
    func fetchMenstrualCycleDay(for date: Date) async throws -> Int? {
        guard let menstrualType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
            return nil
        }
        
        // 查找最近的月经开始日期（往前查35天）
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -35, to: date),
            end: date,
            options: .strictEndDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: menstrualType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let menstrualSamples = samples as? [HKCategorySample],
                      let firstFlow = menstrualSamples.first(where: { 
                          $0.value != HKCategoryValueMenstrualFlow.none.rawValue &&
                          $0.value != HKCategoryValueMenstrualFlow.unspecified.rawValue
                      }) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let daysSinceStart = Calendar.current.dateComponents(
                    [.day],
                    from: Calendar.current.startOfDay(for: firstFlow.startDate),
                    to: Calendar.current.startOfDay(for: date)
                ).day ?? 0
                
                continuation.resume(returning: daysSinceStart + 1)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - 读取心率数据
    
    /// 获取指定时间段的平均心率
    func fetchAverageHeartRate(from startDate: Date, to endDate: Date) async throws -> Double? {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let statistics = statistics,
                      let average = statistics.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let bpm = average.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: bpm)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - 错误类型

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case invalidType
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit在此设备上不可用"
        case .invalidType:
            return "无效的数据类型"
        case .notAuthorized:
            return "未授权访问HealthKit"
        }
    }
}
