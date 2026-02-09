//
//  AttackListView.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  发作记录列表页面
//

import SwiftUI
import SwiftData

struct AttackListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = AttackListViewModel()
    @State private var showingFilterSheet = false
    @State private var selectedAttack: AttackRecord?
    @State private var selectedHealthEvent: HealthEvent?
    
    /// 数据版本号，用于监听 CloudKit 远程变化触发刷新
    @State private var dataVersion: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                AppColors.background.ignoresSafeArea()
                
                if !viewModel.hasAnyData {
                    emptyStateView
                } else {
                    timelineListContent
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "搜索症状、诱因或用药")
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(viewModel: viewModel)
            }
            .sheet(item: $selectedAttack) { attack in
                AttackDetailView(attack: attack)
            }
            .sheet(item: $selectedHealthEvent) { event in
                HealthEventDetailView(event: event)
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
                viewModel.loadData()
            }
            // 日期筛选条件变化 → 需要重新从数据库查询（防抖，避免 resetFilters 时多次触发）
            .onChange(of: viewModel.filterOption) { _, _ in
                viewModel.scheduleLoadData()
            }
            .onChange(of: viewModel.selectedDateRange) { _, _ in
                viewModel.scheduleLoadData()
            }
            // 排序和类型筛选 → 数据已在内存中，只需重建时间轴
            .onChange(of: viewModel.sortOption) { _, _ in
                viewModel.updateTimelineItems()
            }
            .onChange(of: viewModel.recordTypeFilter) { _, _ in
                viewModel.updateTimelineItems()
            }
            // 搜索 → 防抖后重建时间轴
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.scheduleLoadData()
            }
            // 监听远程数据变化（CloudKit 同步）→ 防抖后重新加载
            .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
                dataVersion += 1
            }
            .onChange(of: dataVersion) { _, _ in
                viewModel.scheduleLoadData()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            
            Text("暂无记录")
                .appFont(.title)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("开始记录您的第一次偏头痛发作")
                .appFont(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.extraLarge)
    }
    
    // MARK: - List Content
    
    private var timelineListContent: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                let items = viewModel.cachedTimelineItems
                
                if items.isEmpty {
                    noResultsView
                } else {
                    // 按年份分组
                    let groupedItems = Dictionary(grouping: items) { item in
                        item.year
                    }
                    .sorted { sortYears($0.key, $1.key) }
                    
                    ForEach(groupedItems, id: \.key) { year, yearItems in
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            // 年份标题
                            Text("\(year)年")
                                .appFont(.title3)
                                .foregroundStyle(AppColors.textPrimary)
                                .fontWeight(.semibold)
                                .padding(.horizontal, AppSpacing.medium)
                                .padding(.top, AppSpacing.small)
                            
                            // 该年份的记录
                            ForEach(yearItems) { item in
                                timelineItemRow(for: item)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteTimelineItem(item)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
        }
    }
    
    @ViewBuilder
    private func timelineItemRow(for item: TimelineItemType) -> some View {
        switch item {
        case .attack(let attack):
            AttackRowView(attack: attack)
                .onTapGesture {
                    selectedAttack = attack
                }
        case .healthEvent(let event):
            HealthEventRowView(event: event)
                .onTapGesture {
                    selectedHealthEvent = event
                }
        }
    }
    
    private func deleteTimelineItem(_ item: TimelineItemType) {
        switch item {
        case .attack(let attack):
            viewModel.deleteAttack(attack, from: modelContext)
        case .healthEvent(let event):
            modelContext.delete(event)
            try? modelContext.save()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            
            Text("未找到匹配的记录")
                .appFont(.headline)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("尝试调整搜索或筛选条件")
                .appFont(.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.extraLarge * 2)
    }
    
    // MARK: - Helper Methods
    
    /// 根据排序选项对年份进行排序
    private func sortYears(_ year1: Int, _ year2: Int) -> Bool {
        switch viewModel.sortOption {
        case .dateDescending:
            return year1 > year2  // 最新优先：2026, 2025, 2024...
        case .dateAscending:
            return year1 < year2  // 最早优先：2024, 2025, 2026...
        case .intensityDescending, .durationDescending:
            // 按疼痛强度或持续时间排序时，年份仍按降序（最新年份在前）
            return year1 > year2
        }
    }
    
    /// 根据排序选项对年份内的记录进行排序
    private func sortYearAttacks(_ attacks: [AttackRecord]) -> [AttackRecord] {
        switch viewModel.sortOption {
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
}

// MARK: - Attack Row View

struct AttackRowView: View {
    let attack: AttackRecord
    
    private var intensityColor: Color {
        PainIntensity.from(attack.painIntensity).color
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧疼痛强度指示器
            VStack(spacing: 4) {
                Text("\(attack.painIntensity)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(intensityColor)
                
                Text("强度")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .frame(width: 56, height: 56)
            .background(intensityColor.opacity(0.15))
            .cornerRadius(12)
            
            // 中间内容
            VStack(alignment: .leading, spacing: 4) {
                Text(attack.startTime.smartFormatted())
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    if let duration = calculateDuration() {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(duration)
                        }
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    if attack.medicationCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "pills")
                                .font(.caption2)
                            Text("\(attack.medicationCount)次用药")
                        }
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: AppColors.shadowColor, radius: AppSpacing.shadowRadiusSmall)
    }
    
    private func calculateDuration() -> String? {
        guard let endTime = attack.endTime else { return nil }
        let duration = endTime.timeIntervalSince(attack.startTime)
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return nil
        }
    }
}

// MARK: - Filter Sheet View

struct FilterSheetView: View {
    @Bindable var viewModel: AttackListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                // 记录类型
                Section("记录类型") {
                    Picker("类型", selection: $viewModel.recordTypeFilter) {
                        ForEach(AttackListViewModel.RecordTypeFilter.allCases, id: \.self) { filter in
                            Label(filter.rawValue, systemImage: filter.systemImage)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                // 时间范围
                Section("时间范围") {
                    Picker("筛选", selection: $viewModel.filterOption) {
                        ForEach(AttackListViewModel.FilterOption.allCases, id: \.self) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    // 自定义日期范围选择器
                    if viewModel.filterOption == .custom {
                        VStack(spacing: AppSpacing.small) {
                            DatePicker("开始日期", 
                                       selection: $customStartDate, 
                                       displayedComponents: .date)
                            DatePicker("结束日期", 
                                       selection: $customEndDate, 
                                       displayedComponents: .date)
                        }
                        .padding(.vertical, AppSpacing.small)
                    }
                }
                
                // 排序方式
                Section("排序方式") {
                    Picker("排序", selection: $viewModel.sortOption) {
                        ForEach(AttackListViewModel.SortOption.allCases, id: \.self) { option in
                            Label(option.rawValue, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                // 重置按钮
                Section {
                    Button("重置所有筛选") {
                        viewModel.resetFilters()
                    }
                    .foregroundStyle(AppColors.warning)
                }
            }
            .navigationTitle("筛选和排序")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 初始化自定义日期范围
                if let dateRange = viewModel.selectedDateRange {
                    customStartDate = dateRange.start
                    customEndDate = dateRange.end
                }
            }
            .onChange(of: customStartDate) { _, newValue in
                updateCustomDateRange()
            }
            .onChange(of: customEndDate) { _, newValue in
                updateCustomDateRange()
            }
            .onChange(of: viewModel.filterOption) { oldValue, newValue in
                // 当切换到自定义选项时，应用当前的自定义日期范围
                if newValue == .custom {
                    updateCustomDateRange()
                }
            }
        }
    }
    
    private func updateCustomDateRange() {
        if viewModel.filterOption == .custom {
            // 规范化日期范围，确保包含完整的结束日期
            let normalized = Date.normalizedDateRange(start: customStartDate, end: customEndDate)
            viewModel.selectedDateRange = AttackListViewModel.DateRange(
                start: normalized.start,
                end: normalized.end
            )
        }
    }
}

// MARK: - Health Event Row View

struct HealthEventRowView: View {
    let event: HealthEvent
    
    private var eventColor: Color {
        switch event.eventType {
        case .medication:
            return Color.accentPrimary
        case .tcmTreatment:
            return Color.statusSuccess
        case .surgery:
            return Color.statusInfo
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧事件类型图标
            VStack(spacing: 4) {
                Image(systemName: event.eventType.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(eventColor)
                
                Text(event.eventType.rawValue)
                    .font(.caption2)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .frame(width: 56, height: 56)
            .background(eventColor.opacity(0.15))
            .cornerRadius(12)
            
            // 中间内容
            VStack(alignment: .leading, spacing: 4) {
                Text(event.displayTitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    // 时间
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(event.eventDate.smartFormatted())
                    }
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    
                    // 详细信息
                    if let detail = event.displayDetail {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                            Text(detail)
                        }
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(color: AppColors.shadowColor, radius: AppSpacing.shadowRadiusSmall)
    }
}

#Preview {
    AttackListView()
        .modelContainer(for: [AttackRecord.self, HealthEvent.self], inMemory: true)
}
