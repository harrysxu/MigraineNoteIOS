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
    
    /// 选中的日期范围
    var selectedDateRange: DateRange? = nil
    
    /// 记录类型筛选
    var recordTypeFilter: RecordTypeFilter = .all
    
    /// 从数据库查询到的发作记录（已通过谓词过滤日期范围）
    var attacks: [AttackRecord] = []
    
    /// 从数据库查询到的健康事件（已通过谓词过滤日期范围）
    var healthEvents: [HealthEvent] = []
    
    /// 是否有任何数据（用于空状态判断）
    var hasAnyData: Bool = false
    
    /// 缓存的时间轴数据
    var cachedTimelineItems: [TimelineItemType] = []
    
    /// ModelContext 引用
    private var modelContext: ModelContext?
    
    /// 防抖刷新任务
    private var refreshTask: Task<Void, Never>?
    
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
    
    struct DateRange: Equatable {
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
    
    // MARK: - 初始化
    
    /// 设置 ModelContext（在 View 的 onAppear 中调用）
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 数据加载（使用 FetchDescriptor + 谓词，只查询需要的数据）
    
    /// 从数据库加载数据并更新时间轴（统一入口）
    func loadData() {
        loadAttacks()
        loadHealthEvents()
        checkHasAnyData()
        updateTimelineItems()
    }
    
    /// 带防抖的数据加载（用于搜索等频繁触发的场景）
    func scheduleLoadData() {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms 防抖
            guard !Task.isCancelled else { return }
            await MainActor.run {
                loadData()
            }
        }
    }
    
    /// 使用 FetchDescriptor 从数据库加载发作记录（带日期谓词）
    private func loadAttacks() {
        guard let modelContext = modelContext else { return }
        guard let range = getDateRangeForFilter() else {
            attacks = []
            return
        }
        
        let startDate = range.start
        let endDate = range.end
        
        // 构建带日期范围谓词的 FetchDescriptor
        var descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startDate && attack.startTime <= endDate
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        // 设置获取上限，避免加载过多数据
        descriptor.fetchLimit = 200
        
        attacks = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 使用 FetchDescriptor 从数据库加载健康事件（带日期谓词）
    private func loadHealthEvents() {
        guard let modelContext = modelContext else { return }
        guard let range = getDateRangeForFilter() else {
            healthEvents = []
            return
        }
        
        let startDate = range.start
        let endDate = range.end
        
        var descriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startDate && event.eventDate <= endDate
            },
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        
        healthEvents = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 检查是否有任何数据（用于空状态显示，只需检查是否存在记录）
    private func checkHasAnyData() {
        guard let modelContext = modelContext else { return }
        var attackDesc = FetchDescriptor<AttackRecord>()
        attackDesc.fetchLimit = 1
        var eventDesc = FetchDescriptor<HealthEvent>()
        eventDesc.fetchLimit = 1
        let hasAttacks = ((try? modelContext.fetchCount(attackDesc)) ?? 0) > 0
        let hasEvents = ((try? modelContext.fetchCount(eventDesc)) ?? 0) > 0
        hasAnyData = hasAttacks || hasEvents
    }
    
    // MARK: - 时间轴数据构建
    
    /// 重新计算时间轴数据（基于已加载的数据进行内存过滤和排序）
    func updateTimelineItems() {
        var items: [TimelineItemType] = []
        
        // 添加偏头痛发作记录（已经通过数据库谓词做了日期过滤，只需做搜索过滤）
        let filteredAttacks = applySearchFilter(to: attacks)
        if recordTypeFilter == .all || recordTypeFilter == .attacksOnly {
            items.append(contentsOf: filteredAttacks.map { .attack($0) })
        }
        
        // 添加健康事件
        let filteredEvents = applySearchAndTypeFilter(to: healthEvents)
        if recordTypeFilter != .attacksOnly {
            items.append(contentsOf: filteredEvents.map { .healthEvent($0) })
        }
        
        // 按日期排序
        items.sort { item1, item2 in
            switch sortOption {
            case .dateDescending:
                return item1.eventDate > item2.eventDate
            case .dateAscending:
                return item1.eventDate < item2.eventDate
            case .intensityDescending, .durationDescending:
                return item1.eventDate > item2.eventDate
            }
        }
        
        cachedTimelineItems = items
    }
    
    /// 对已加载的发作记录做搜索过滤（不再做日期过滤，日期已在数据库层完成）
    private func applySearchFilter(to attacks: [AttackRecord]) -> [AttackRecord] {
        var filtered = attacks
        
        if !searchText.isEmpty {
            filtered = filtered.filter { attack in
                let symptomMatch = attack.symptoms.contains { symptom in
                    symptom.name.localizedCaseInsensitiveContains(searchText)
                }
                let triggerMatch = attack.triggers.contains { trigger in
                    trigger.name.localizedCaseInsensitiveContains(searchText)
                }
                let medicationMatch = attack.medicationLogs.contains { log in
                    log.medication?.name.localizedCaseInsensitiveContains(searchText) ?? false
                }
                return symptomMatch || triggerMatch || medicationMatch
            }
        }
        
        // 应用排序
        filtered = sortAttacks(filtered)
        
        return filtered
    }
    
    /// 对已加载的健康事件做搜索和类型过滤
    private func applySearchAndTypeFilter(to events: [HealthEvent]) -> [HealthEvent] {
        var filtered = events
        
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
            break
        case .medicationOnly:
            filtered = filtered.filter { $0.eventType == .medication }
        case .tcmOnly:
            filtered = filtered.filter { $0.eventType == .tcmTreatment }
        case .surgeryOnly:
            filtered = filtered.filter { $0.eventType == .surgery }
        case .attacksOnly:
            filtered = []
        }
        
        return filtered
    }
    
    // MARK: - 辅助方法
    
    /// 获取当前筛选对应的日期范围（与图表 TimeRange 逻辑保持一致）
    func getDateRangeForFilter() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        switch filterOption {
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let endOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextMonth)!
            return (startOfMonth, endOfMonth)
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .last6Months:
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            return (start, now)
        case .lastYear:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)
        case .custom:
            if let dateRange = selectedDateRange {
                return (dateRange.start, dateRange.end)
            }
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let endOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextMonth)!
            return (startOfMonth, endOfMonth)
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
    
    /// 重置所有筛选
    func resetFilters() {
        searchText = ""
        filterOption = .thisMonth
        sortOption = .dateDescending
        selectedDateRange = nil
        recordTypeFilter = .all
    }
    
    /// 删除记录
    func deleteAttack(_ attack: AttackRecord, from context: ModelContext) {
        context.delete(attack)
        do {
            try context.save()
            AppToastManager.shared.showSuccess("记录已删除")
        } catch {
            AppToastManager.shared.showError("删除失败，请重试")
        }
    }
    
    /// 批量删除记录
    func deleteAttacks(_ attacks: [AttackRecord], from context: ModelContext) {
        for attack in attacks {
            context.delete(attack)
        }
        do {
            try context.save()
            AppToastManager.shared.showSuccess("已删除 \(attacks.count) 条记录")
        } catch {
            AppToastManager.shared.showError("批量删除失败，请重试")
        }
    }
}
