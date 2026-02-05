//
//  TimelineItem.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/5.
//  统一时间轴数据结构
//

import Foundation

/// 时间轴项目类型
enum TimelineItemType: Identifiable, Hashable {
    case attack(AttackRecord)
    case healthEvent(HealthEvent)
    
    var id: UUID {
        switch self {
        case .attack(let record):
            return record.id
        case .healthEvent(let event):
            return event.id
        }
    }
    
    /// 事件发生的日期时间
    var eventDate: Date {
        switch self {
        case .attack(let record):
            return record.startTime
        case .healthEvent(let event):
            return event.eventDate
        }
    }
    
    /// 年份（用于分组）
    var year: Int {
        Calendar.current.component(.year, from: eventDate)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TimelineItemType, rhs: TimelineItemType) -> Bool {
        lhs.id == rhs.id
    }
}
