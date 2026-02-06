//
//  Date+Extensions.swift
//  migraine_note
//
//  Created on 2026/2/2.
//

import Foundation

extension Date {
    // MARK: - 智能日期格式化
    
    /// 智能日期格式：今天/昨天/MM月dd日 HH:mm
    func smartFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInYesterday(self) {
            formatter.dateFormat = "昨天 HH:mm"
        } else {
            formatter.dateFormat = "MM月dd日 HH:mm"
        }
        
        return formatter.string(from: self)
    }
    
    /// 短时间格式：HH:mm
    func shortTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// 完整日期：yyyy年MM月dd日
    func fullDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: self)
    }
    
    /// 完整日期时间：yyyy年MM月dd日 HH:mm
    func fullDateTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: self)
    }
    
    /// 月份标题：yyyy年M月
    func monthTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: self)
    }
    
    /// 月份名称：1月、2月...
    func monthName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        return formatter.string(from: self)
    }
    
    /// 紧凑日期格式（用于文件名等）：yyyyMMdd
    func compactDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: self)
    }
    
    /// 紧凑日期时间格式（用于报告）：MM/dd HH:mm
    func compactDateTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: self)
    }
    
    /// 年月日格式（用于报告）：yyyy-MM-dd HH:mm
    func reportDateTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: self)
    }
    
    /// 简洁日期格式：MM.dd HH:mm
    func briefDateTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM.dd HH:mm"
        return formatter.string(from: self)
    }
    
    /// 获取年份：yyyy
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// 年份标题：yyyy年
    func yearTitle() -> String {
        return "\(year)年"
    }
    
    // MARK: - 日期范围处理
    
    /// 获取当天的开始时间（00:00:00）
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// 获取当天的结束时间（23:59:59.999）
    func endOfDay() -> Date {
        let calendar = Calendar.current
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay())!
        return startOfNextDay.addingTimeInterval(-0.001)
    }
    
    /// 规范化日期范围：确保结束日期包含完整的一天
    /// - Parameters:
    ///   - start: 开始日期
    ///   - end: 结束日期
    /// - Returns: 规范化后的日期范围，开始日期为当天00:00:00，结束日期为当天23:59:59.999
    static func normalizedDateRange(start: Date, end: Date) -> (start: Date, end: Date) {
        return (start.startOfDay(), end.endOfDay())
    }
}
