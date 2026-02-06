//
//  CalendarViewModel.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

@Observable
class CalendarViewModel {
    var currentMonth: Date = Date()
    var selectedDate: Date?
    var attacksByDate: [Date: [AttackRecord]] = [:]
    var healthEventsByDate: [Date: [HealthEvent]] = [:]
    var monthlyStats: MonthlyStatistics?
    
    private let modelContext: ModelContext
    private let calendar = Calendar.current
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    // MARK: - 月份导航
    
    func moveToNextMonth() {
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = nextMonth
            loadData()
        }
    }
    
    func moveToPreviousMonth() {
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = prevMonth
            loadData()
        }
    }
    
    func moveToToday() {
        currentMonth = Date()
        loadData()
    }
    
    // MARK: - 数据加载
    
    func loadData() {
        loadAttacks()
        loadHealthEvents()
        calculateMonthlyStats()
    }
    
    private func loadAttacks() {
        // 获取当前月份的开始和结束日期（使用下月首日0点作为 exclusive end，以包含月末整天）
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEndExclusive = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return
        }
        
        // 查询该月份的所有发作记录
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= monthStart && attack.startTime < monthEndExclusive
            },
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else {
            attacksByDate = [:]
            return
        }
        
        // 按日期分组
        var grouped: [Date: [AttackRecord]] = [:]
        for attack in attacks {
            let day = calendar.startOfDay(for: attack.startTime)
            grouped[day, default: []].append(attack)
        }
        
        attacksByDate = grouped
    }
    
    private func loadHealthEvents() {
        // 获取当前月份的开始和结束日期（使用下月首日0点作为 exclusive end，以包含月末整天）
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEndExclusive = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return
        }
        
        // 查询该月份的所有健康事件
        let descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= monthStart && event.eventDate < monthEndExclusive
            },
            sortBy: [SortDescriptor(\.eventDate, order: .forward)]
        )
        
        guard let healthEvents = try? modelContext.fetch(descriptor) else {
            healthEventsByDate = [:]
            return
        }
        
        // 按日期分组
        var grouped: [Date: [HealthEvent]] = [:]
        for event in healthEvents {
            let day = calendar.startOfDay(for: event.eventDate)
            grouped[day, default: []].append(event)
        }
        
        healthEventsByDate = grouped
    }
    
    private func calculateMonthlyStats() {
        // 使用下月首日0点作为 exclusive end，与图表月度趋势逻辑一致
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEndExclusive = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            monthlyStats = nil
            return
        }
        
        // 查询该月份的所有发作记录
        let attackDescriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= monthStart && attack.startTime < monthEndExclusive
            }
        )
        
        guard let attacks = try? modelContext.fetch(attackDescriptor) else {
            monthlyStats = nil
            return
        }
        
        // 查询该月份的所有健康事件
        let healthEventDescriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= monthStart && event.eventDate < monthEndExclusive
            }
        )
        
        let healthEvents = (try? modelContext.fetch(healthEventDescriptor)) ?? []
        
        // 计算基本统计数据
        let attackDays = Set(attacks.map { calendar.startOfDay(for: $0.startTime) }).count
        let totalAttacks = attacks.count
        let averageIntensity = attacks.isEmpty ? 0 : attacks.reduce(0.0) { $0 + Double($1.painIntensity) } / Double(attacks.count)
        
        // 计算平均持续时长（只统计已结束的发作）
        let completedAttacks = attacks.filter { $0.duration != nil }
        let averageDuration = completedAttacks.isEmpty ? 0 : completedAttacks.reduce(0.0) { $0 + ($1.duration ?? 0) } / Double(completedAttacks.count)
        
        // 使用统一的统计方法计算细分数据
        let medicationStats = DetailedMedicationStatistics.calculate(
            attacks: attacks,
            healthEvents: healthEvents,
            dateRange: (monthStart, monthEndExclusive)
        )
        
        // 检测MOH风险（仅基于急性用药天数）
        let period = DateInterval(start: monthStart, end: monthEndExclusive)
        let mohRisk = MOHDetector.checkMOHRisk(for: period, attacks: attacks)
        
        monthlyStats = MonthlyStatistics(
            attackDays: attackDays,
            totalAttacks: totalAttacks,
            averagePainIntensity: averageIntensity,
            mohRisk: mohRisk,
            averageDuration: averageDuration,
            acuteMedicationDays: medicationStats.acuteMedicationDays,
            acuteMedicationCount: medicationStats.acuteMedicationCount,
            preventiveMedicationDays: medicationStats.preventiveMedicationDays,
            preventiveMedicationCount: medicationStats.preventiveMedicationCount,
            tcmTreatmentCount: medicationStats.tcmTreatmentCount,
            surgeryCount: medicationStats.surgeryCount
        )
    }
    
    // MARK: - 日历辅助方法
    
    /// 获取当前月份显示的所有日期（包括前后月份的日期以填充完整网格）
    func getDaysInMonth() -> [Date] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        // 获取月份第一天是星期几
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        // 星期日是1，我们需要转换为0-6（星期日为0）
        let startOffset = (firstWeekday - 1)
        
        // 获取该月份的天数
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        let numDays = range.count
        
        // 计算需要显示的总格子数（6行x7列=42）
        let totalCells = 42
        
        var days: [Date] = []
        
        // 添加前一个月的日期
        for i in 0..<startOffset {
            if let date = calendar.date(byAdding: .day, value: i - startOffset, to: monthStart) {
                days.append(date)
            }
        }
        
        // 添加当前月份的日期
        for i in 0..<numDays {
            if let date = calendar.date(byAdding: .day, value: i, to: monthStart) {
                days.append(date)
            }
        }
        
        // 添加下一个月的日期以填充剩余格子
        let remainingCells = totalCells - days.count
        for i in 0..<remainingCells {
            if let date = calendar.date(byAdding: .day, value: numDays + i, to: monthStart) {
                days.append(date)
            }
        }
        
        return days
    }
    
    /// 检查日期是否在当前月份
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    /// 检查日期是否是今天
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    /// 获取指定日期的发作记录
    func getAttacks(for date: Date) -> [AttackRecord] {
        let day = calendar.startOfDay(for: date)
        return attacksByDate[day] ?? []
    }
    
    /// 获取指定日期的最高疼痛强度
    func getMaxPainIntensity(for date: Date) -> Int? {
        let attacks = getAttacks(for: date)
        return attacks.map(\.painIntensity).max()
    }
    
    /// 获取指定日期的健康事件
    func getHealthEvents(for date: Date) -> [HealthEvent] {
        let day = calendar.startOfDay(for: date)
        return healthEventsByDate[day] ?? []
    }
    
    /// 获取指定日期的健康事件类型集合（去重）
    func getHealthEventTypes(for date: Date) -> Set<HealthEventType> {
        let events = getHealthEvents(for: date)
        return Set(events.map { $0.eventType })
    }
    
    /// 获取月份标题（如"2026年2月"）
    var monthTitle: String {
        return currentMonth.monthTitle()
    }
}

// MARK: - 月度统计数据模型

struct MonthlyStatistics {
    let attackDays: Int
    let totalAttacks: Int
    let averagePainIntensity: Double
    let mohRisk: MOHRiskLevel
    let averageDuration: TimeInterval
    
    // 细分的用药和治疗统计
    let acuteMedicationDays: Int       // 急性用药天数（仅发作期间）
    let acuteMedicationCount: Int      // 急性用药次数（仅发作期间）
    let preventiveMedicationDays: Int  // 预防性用药天数（健康事件中）
    let preventiveMedicationCount: Int // 预防性用药次数（健康事件中）
    let tcmTreatmentCount: Int         // 中医治疗次数
    let surgeryCount: Int              // 手术次数
    
    // 便捷属性：判断是否有数据
    var hasPreventiveMedication: Bool { preventiveMedicationCount > 0 }
    var hasTCMTreatment: Bool { tcmTreatmentCount > 0 }
    var hasSurgery: Bool { surgeryCount > 0 }
    
    // 兼容性：保留原有的总计字段（用于MOH风险判断等现有逻辑）
    var medicationDays: Int {
        acuteMedicationDays + preventiveMedicationDays
    }
    var totalMedicationUses: Int {
        acuteMedicationCount + preventiveMedicationCount
    }
    
    var isChronic: Bool {
        attackDays >= 15
    }
    
    var averageIntensityFormatted: String {
        String(format: "%.1f", averagePainIntensity)
    }
    
    var averageDurationFormatted: String {
        let hours = averageDuration / 3600
        return String(format: "%.1fh", hours)
    }
}
