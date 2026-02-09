//
//  MenstrualCycleManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/6.
//
//  经期/激素追踪 - 通过 HealthKit 读取经期数据
//  分析偏头痛与月经周期的关联
//

import SwiftUI
import HealthKit

/// 经期数据管理器
@Observable
class MenstrualCycleManager {
    static let shared = MenstrualCycleManager()
    
    var isAuthorized = false
    var isAvailable = false
    var menstrualData: [MenstrualPeriod] = []
    var cycleAnalysis: CycleAnalysis?
    var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    
    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - 权限管理
    
    /// 请求 HealthKit 经期数据权限
    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            errorMessage = "此设备不支持 HealthKit"
            return false
        }
        
        // 需要读取的数据类型
        guard let menstrualFlowType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else {
            errorMessage = "无法访问经期数据类型"
            return false
        }
        
        let readTypes: Set<HKSampleType> = [menstrualFlowType]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run {
                isAuthorized = true
            }
            return true
        } catch {
            await MainActor.run {
                errorMessage = "授权失败: \(error.localizedDescription)"
                isAuthorized = false
            }
            return false
        }
    }
    
    // MARK: - 数据读取
    
    /// 获取最近的经期数据
    func fetchMenstrualData(months: Int = 6) async {
        guard isAvailable, isAuthorized else { return }
        
        guard let menstrualFlowType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow) else {
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -months, to: endDate) else {
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let periods: [MenstrualPeriod] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: menstrualFlowType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    if let self = self {
                        Task { @MainActor in
                            self.errorMessage = error.localizedDescription
                        }
                    }
                    continuation.resume(returning: [])
                    return
                }
                
                guard let self = self,
                      let categorySamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // 将样本转换为经期数据
                let periods = self.groupSamplesIntoPeriods(categorySamples)
                continuation.resume(returning: periods)
            }
            
            healthStore.execute(query)
        }
        
        // 确保在 MainActor 上更新数据，且等待完成后再返回
        await MainActor.run {
            self.menstrualData = periods
        }
    }
    
    /// 将 HealthKit 样本按日期分组为经期
    private func groupSamplesIntoPeriods(_ samples: [HKCategorySample]) -> [MenstrualPeriod] {
        guard !samples.isEmpty else { return [] }
        
        let calendar = Calendar.current
        var periods: [MenstrualPeriod] = []
        var currentPeriodStart: Date?
        var currentPeriodEnd: Date?
        var currentFlowLevels: [Int] = []
        
        for sample in samples {
            let sampleDate = calendar.startOfDay(for: sample.startDate)
            let flowLevel = sample.value
            
            if let periodEnd = currentPeriodEnd {
                // 如果距离上一天超过2天，认为是新的经期
                let daysDiff = calendar.dateComponents([.day], from: periodEnd, to: sampleDate).day ?? 0
                
                if daysDiff > 2 {
                    // 保存当前经期
                    if let start = currentPeriodStart {
                        periods.append(MenstrualPeriod(
                            startDate: start,
                            endDate: periodEnd,
                            flowLevels: currentFlowLevels
                        ))
                    }
                    // 开始新经期
                    currentPeriodStart = sampleDate
                    currentFlowLevels = [flowLevel]
                } else {
                    currentFlowLevels.append(flowLevel)
                }
                currentPeriodEnd = sampleDate
            } else {
                currentPeriodStart = sampleDate
                currentPeriodEnd = sampleDate
                currentFlowLevels = [flowLevel]
            }
        }
        
        // 保存最后一个经期
        if let start = currentPeriodStart, let end = currentPeriodEnd {
            periods.append(MenstrualPeriod(
                startDate: start,
                endDate: end,
                flowLevels: currentFlowLevels
            ))
        }
        
        return periods
    }
    
    // MARK: - 关联分析
    
    /// 分析经期与偏头痛的关联
    func analyzeCycleCorrelation(with attacks: [AttackRecord]) -> CycleAnalysis {
        guard menstrualData.count >= 2 else {
            return CycleAnalysis(
                averageCycleLength: 0,
                attacksDuringPeriod: 0,
                attacksBeforePeriod: 0,
                attacksOutsidePeriod: 0,
                totalAttacksAnalyzed: 0,
                periodCorrelationPercentage: 0,
                premenstrualCorrelationPercentage: 0,
                isMenstrualMigraine: false,
                cyclePhaseDistribution: []
            )
        }
        
        let calendar = Calendar.current
        
        // 计算平均周期长度
        var cycleLengths: [Int] = []
        for i in 1..<menstrualData.count {
            let days = calendar.dateComponents([.day],
                from: menstrualData[i-1].startDate,
                to: menstrualData[i].startDate
            ).day ?? 28
            cycleLengths.append(days)
        }
        let averageCycleLength = cycleLengths.isEmpty ? 28 : cycleLengths.reduce(0, +) / cycleLengths.count
        
        // 分析每次发作所处的周期阶段
        var attacksDuringPeriod = 0
        var attacksBeforePeriod = 0  // 经前2天
        var attacksOutsidePeriod = 0
        var phaseDistribution: [String: Int] = [
            "经期": 0,
            "经前期(2天)": 0,
            "卵泡期": 0,
            "排卵期": 0,
            "黄体期": 0
        ]
        
        for attack in attacks {
            let attackDate = calendar.startOfDay(for: attack.startTime)
            var foundPhase = false
            
            for (index, period) in menstrualData.enumerated() {
                let periodStart = calendar.startOfDay(for: period.startDate)
                let periodEnd = calendar.startOfDay(for: period.endDate)
                
                // 检查是否在经期内
                if attackDate >= periodStart && attackDate <= periodEnd {
                    attacksDuringPeriod += 1
                    phaseDistribution["经期", default: 0] += 1
                    foundPhase = true
                    break
                }
                
                // 检查是否在经前2天
                if let prePeriodStart = calendar.date(byAdding: .day, value: -2, to: periodStart) {
                    if attackDate >= prePeriodStart && attackDate < periodStart {
                        attacksBeforePeriod += 1
                        phaseDistribution["经前期(2天)", default: 0] += 1
                        foundPhase = true
                        break
                    }
                }
                
                // 计算周期内的阶段（如果在两个经期之间）
                if index < menstrualData.count - 1 {
                    let nextPeriod = menstrualData[index + 1]
                    let nextPeriodStart = calendar.startOfDay(for: nextPeriod.startDate)
                    
                    if attackDate > periodEnd && attackDate < nextPeriodStart {
                        let daysFromPeriodEnd = calendar.dateComponents([.day], from: periodEnd, to: attackDate).day ?? 0
                        let cycleDays = calendar.dateComponents([.day], from: periodStart, to: nextPeriodStart).day ?? 28
                        
                        if daysFromPeriodEnd < cycleDays / 3 {
                            phaseDistribution["卵泡期", default: 0] += 1
                        } else if daysFromPeriodEnd < cycleDays / 2 {
                            phaseDistribution["排卵期", default: 0] += 1
                        } else {
                            phaseDistribution["黄体期", default: 0] += 1
                        }
                        foundPhase = true
                        break
                    }
                }
            }
            
            if !foundPhase {
                attacksOutsidePeriod += 1
            }
        }
        
        let totalAnalyzed = attacksDuringPeriod + attacksBeforePeriod + attacksOutsidePeriod
        let periodRelated = attacksDuringPeriod + attacksBeforePeriod
        let periodCorrelation = totalAnalyzed > 0 ? Double(periodRelated) / Double(totalAnalyzed) * 100 : 0
        let premenstrualCorrelation = totalAnalyzed > 0 ? Double(attacksBeforePeriod) / Double(totalAnalyzed) * 100 : 0
        
        // 如果50%以上的发作与经期相关，判定为月经性偏头痛
        let isMenstrualMigraine = periodCorrelation >= 50 && totalAnalyzed >= 3
        
        let distribution = phaseDistribution.map { CyclePhaseData(phase: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        
        let analysis = CycleAnalysis(
            averageCycleLength: averageCycleLength,
            attacksDuringPeriod: attacksDuringPeriod,
            attacksBeforePeriod: attacksBeforePeriod,
            attacksOutsidePeriod: attacksOutsidePeriod,
            totalAttacksAnalyzed: totalAnalyzed,
            periodCorrelationPercentage: periodCorrelation,
            premenstrualCorrelationPercentage: premenstrualCorrelation,
            isMenstrualMigraine: isMenstrualMigraine,
            cyclePhaseDistribution: distribution
        )
        
        // 不再使用 fire-and-forget Task，由调用方在 MainActor 上设置 cycleAnalysis
        return analysis
    }
}

// MARK: - 数据模型

/// 经期记录
struct MenstrualPeriod: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let flowLevels: [Int] // HKCategoryValueMenstrualFlow raw values
    
    var durationDays: Int {
        let calendar = Calendar.current
        return (calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1
    }
}

/// 周期分析结果
struct CycleAnalysis {
    let averageCycleLength: Int
    let attacksDuringPeriod: Int
    let attacksBeforePeriod: Int
    let attacksOutsidePeriod: Int
    let totalAttacksAnalyzed: Int
    let periodCorrelationPercentage: Double
    let premenstrualCorrelationPercentage: Double
    let isMenstrualMigraine: Bool
    let cyclePhaseDistribution: [CyclePhaseData]
}

/// 周期阶段数据
struct CyclePhaseData: Identifiable {
    let id = UUID()
    let phase: String
    let count: Int
}
