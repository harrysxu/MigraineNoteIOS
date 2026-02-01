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
        calculateMonthlyStats()
    }
    
    private func loadAttacks() {
        // 获取当前月份的开始和结束日期
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return
        }
        
        // 查询该月份的所有发作记录
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= monthStart && attack.startTime <= monthEnd
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
    
    private func calculateMonthlyStats() {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            monthlyStats = nil
            return
        }
        
        // 查询该月份的所有发作记录
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= monthStart && attack.startTime <= monthEnd
            }
        )
        
        guard let attacks = try? modelContext.fetch(descriptor) else {
            monthlyStats = nil
            return
        }
        
        // 计算统计数据
        let attackDays = Set(attacks.map { calendar.startOfDay(for: $0.startTime) }).count
        let totalAttacks = attacks.count
        let averageIntensity = attacks.isEmpty ? 0 : attacks.reduce(0.0) { $0 + Double($1.painIntensity) } / Double(attacks.count)
        
        // 计算用药天数
        var medicationDays = Set<Date>()
        for attack in attacks {
            if !attack.medicationLogs.isEmpty {
                medicationDays.insert(calendar.startOfDay(for: attack.startTime))
            }
        }
        
        // 检测MOH风险
        let period = DateInterval(start: monthStart, end: monthEnd)
        let mohRisk = MOHDetector.checkMOHRisk(for: period, attacks: attacks)
        
        monthlyStats = MonthlyStatistics(
            attackDays: attackDays,
            totalAttacks: totalAttacks,
            averagePainIntensity: averageIntensity,
            medicationDays: medicationDays.count,
            mohRisk: mohRisk
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
    
    /// 获取月份标题（如"2026年2月"）
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: currentMonth)
    }
}

// MARK: - 月度统计数据模型

struct MonthlyStatistics {
    let attackDays: Int
    let totalAttacks: Int
    let averagePainIntensity: Double
    let medicationDays: Int
    let mohRisk: MOHRiskLevel
    
    var isChronic: Bool {
        attackDays >= 15
    }
    
    var averageIntensityFormatted: String {
        String(format: "%.1f", averagePainIntensity)
    }
}
