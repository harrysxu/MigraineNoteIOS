//
//  AttackListViewModel.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  管理发作记录列表的数据和筛选功能
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class AttackListViewModel {
    // MARK: - Properties
    
    /// 搜索文本
    var searchText: String = ""
    
    /// 筛选选项
    var filterOption: FilterOption = .thisMonth
    
    /// 排序选项
    var sortOption: SortOption = .dateDescending
    
    /// 选中的疼痛强度范围
    var selectedIntensityRange: ClosedRange<Int>? = nil
    
    /// 选中的日期范围
    var selectedDateRange: DateRange? = nil
    
    /// 记录类型筛选
    var recordTypeFilter: RecordTypeFilter = .all
    
    // MARK: - Enums
    
    enum FilterOption: String, CaseIterable {
        case thisMonth = "本月"
        case last3Months = "近3个月"
        case last6Months = "近6个月"
        case lastYear = "近1年"
        case custom = "自定义"
        
        var systemImage: String {
            switch self {
            case .thisMonth: return "calendar.circle"
            case .last3Months: return "calendar.badge.plus"
            case .last6Months: return "calendar.badge.clock"
            case .lastYear: return "calendar"
            case .custom: return "calendar.badge.exclamationmark"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "最新优先"
        case dateAscending = "最早优先"
        case intensityDescending = "疼痛强度降序"
        case durationDescending = "持续时间降序"
        
        var systemImage: String {
            switch self {
            case .dateDescending: return "arrow.down"
            case .dateAscending: return "arrow.up"
            case .intensityDescending: return "exclamationmark.3"
            case .durationDescending: return "clock.arrow.circlepath"
            }
        }
    }
    
    struct DateRange {
        let start: Date
        let end: Date
    }
    
    enum RecordTypeFilter: String, CaseIterable {
        case all = "全部记录"
        case attacksOnly = "偏头痛发作"
        case healthEventsOnly = "健康事件"
        case medicationOnly = "仅用药记录"
        case tcmOnly = "仅中医治疗"
        case surgeryOnly = "仅手术记录"
        
        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .attacksOnly: return "exclamationmark.triangle.fill"
            case .healthEventsOnly: return "heart.text.square.fill"
            case .medicationOnly: return "pills.circle.fill"
            case .tcmOnly: return "leaf.circle.fill"
            case .surgeryOnly: return "cross.case.circle.fill"
            }
        }
    }
    
    // MARK: - Methods
    
    /// 获取筛选后的记录
    func filteredAttacks(_ attacks: [AttackRecord]) -> [AttackRecord] {
        var filtered = attacks
        
        // 应用日期筛选
        filtered = applyDateFilter(to: filtered)
        
        // 应用搜索
        if !searchText.isEmpty {
            filtered = filtered.filter { attack in
                // 搜索症状
                let symptomMatch = attack.symptoms.contains { symptom in
                    symptom.name.localizedCaseInsensitiveContains(searchText)
                }
                
                // 搜索诱因
                let triggerMatch = attack.triggers.contains { trigger in
                    trigger.name.localizedCaseInsensitiveContains(searchText)
                }
                
                // 搜索用药
                let medicationMatch = attack.medicationLogs.contains { log in
                    log.medication?.name.localizedCaseInsensitiveContains(searchText) ?? false
                }
                
                return symptomMatch || triggerMatch || medicationMatch
            }
        }
        
        // 应用疼痛强度筛选
        if let intensityRange = selectedIntensityRange {
            filtered = filtered.filter { attack in
                intensityRange.contains(attack.painIntensity)
            }
        }
        
        // 应用排序
        filtered = sortAttacks(filtered)
        
        return filtered
    }
    
    /// 应用日期筛选
    private func applyDateFilter(to attacks: [AttackRecord]) -> [AttackRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch filterOption {
        case .thisMonth:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return attacks.filter { $0.startTime >= monthAgo }
            
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return attacks.filter { $0.startTime >= threeMonthsAgo }
            
        case .last6Months:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            return attacks.filter { $0.startTime >= sixMonthsAgo }
            
        case .lastYear:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return attacks.filter { $0.startTime >= oneYearAgo }
            
        case .custom:
            if let dateRange = selectedDateRange {
                return attacks.filter { attack in
                    attack.startTime >= dateRange.start && attack.startTime <= dateRange.end
                }
            }
            return attacks
        }
    }
    
    /// 排序记录
    private func sortAttacks(_ attacks: [AttackRecord]) -> [AttackRecord] {
        switch sortOption {
        case .dateDescending:
            return attacks.sorted { $0.startTime > $1.startTime }
            
        case .dateAscending:
            return attacks.sorted { $0.startTime < $1.startTime }
            
        case .intensityDescending:
            return attacks.sorted { $0.painIntensity > $1.painIntensity }
            
        case .durationDescending:
            return attacks.sorted { $0.durationOrElapsed > $1.durationOrElapsed }
        }
    }
    
    /// 筛选健康事件
    func filteredHealthEvents(_ events: [HealthEvent]) -> [HealthEvent] {
        var filtered = events
        
        // 应用日期筛选
        filtered = applyDateFilterToHealthEvents(to: filtered)
        
        // 应用搜索
        if !searchText.isEmpty {
            filtered = filtered.filter { event in
                event.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                (event.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // 应用记录类型筛选
        switch recordTypeFilter {
        case .all, .healthEventsOnly:
            break // 显示所有健康事件
        case .medicationOnly:
            filtered = filtered.filter { $0.eventType == .medication }
        case .tcmOnly:
            filtered = filtered.filter { $0.eventType == .tcmTreatment }
        case .surgeryOnly:
            filtered = filtered.filter { $0.eventType == .surgery }
        case .attacksOnly:
            filtered = [] // 不显示健康事件
        }
        
        return filtered
    }
    
    /// 应用日期筛选到健康事件
    private func applyDateFilterToHealthEvents(to events: [HealthEvent]) -> [HealthEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        switch filterOption {
        case .thisMonth:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return events.filter { $0.eventDate >= monthAgo }
            
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return events.filter { $0.eventDate >= threeMonthsAgo }
            
        case .last6Months:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            return events.filter { $0.eventDate >= sixMonthsAgo }
            
        case .lastYear:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return events.filter { $0.eventDate >= oneYearAgo }
            
        case .custom:
            if let dateRange = selectedDateRange {
                return events.filter { event in
                    event.eventDate >= dateRange.start && event.eventDate <= dateRange.end
                }
            }
            return events
        }
    }
    
    /// 重置所有筛选
    func resetFilters() {
        searchText = ""
        filterOption = .thisMonth
        sortOption = .dateDescending
        selectedIntensityRange = nil
        selectedDateRange = nil
        recordTypeFilter = .all
    }
    
    /// 删除记录
    func deleteAttack(_ attack: AttackRecord, from context: ModelContext) {
        context.delete(attack)
        try? context.save()
    }
    
    /// 批量删除记录
    func deleteAttacks(_ attacks: [AttackRecord], from context: ModelContext) {
        for attack in attacks {
            context.delete(attack)
        }
        try? context.save()
    }
}
