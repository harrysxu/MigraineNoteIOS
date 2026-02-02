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
}
