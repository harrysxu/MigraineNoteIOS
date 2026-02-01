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
        
        return hourDistribution
            .map { hour, count in
                CircadianData(hour: hour, count: count)
            }
            .sorted { $0.hour < $1.hour }
    }
    
    // MARK: - MIDAS评分计算
    
    /// 计算偏头痛残疾评估(MIDAS)评分
    func calculateMIDASScore(attacks: [AttackRecord]) -> Int {
        guard !attacks.isEmpty else { return 0 }
        
        // 使用最近3个月的数据
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date())!
        
        let recentAttacks = attacks.filter { $0.startTime >= threeMonthsAgo }
        
        guard !recentAttacks.isEmpty else { return 0 }
        
        // 简化的MIDAS评分：发作天数 × 平均疼痛强度 / 2
        let totalDays = recentAttacks.count
        let averagePain = recentAttacks.reduce(0) { $0 + $1.painIntensity } / recentAttacks.count
        
        return totalDays * averagePain / 2
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
