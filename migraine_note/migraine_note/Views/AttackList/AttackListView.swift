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
    @Query(sort: \AttackRecord.startTime, order: .reverse) private var attacks: [AttackRecord]
    
    @State private var viewModel = AttackListViewModel()
    @State private var showingFilterSheet = false
    @State private var selectedAttack: AttackRecord?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                AppColors.background.ignoresSafeArea()
                
                if attacks.isEmpty {
                    emptyStateView
                } else {
                    attackListContent
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
                            .foregroundStyle(AppColors.primary)
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
    
    private var attackListContent: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                let filteredAttacks = viewModel.filteredAttacks(attacks)
                
                if filteredAttacks.isEmpty {
                    noResultsView
                } else {
                    let groupedAttacks = Dictionary(grouping: filteredAttacks) { attack in
                        attack.startTime.year
                    }
                    .sorted { $0.key > $1.key } // 按年份降序排列
                    
                    ForEach(groupedAttacks, id: \.key) { year, yearAttacks in
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            // 年份标题
                            Text("\(year)年")
                                .appFont(.title3)
                                .foregroundStyle(AppColors.textPrimary)
                                .fontWeight(.semibold)
                                .padding(.horizontal, AppSpacing.medium)
                                .padding(.top, AppSpacing.small)
                            
                            // 该年份的记录
                            ForEach(yearAttacks) { attack in
                                AttackRowView(attack: attack)
                                    .onTapGesture {
                                        selectedAttack = attack
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            viewModel.deleteAttack(attack, from: modelContext)
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
                    
                    if !attack.medicationLogs.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "pills")
                                .font(.caption2)
                            Text("\(attack.medicationLogs.count)次用药")
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
                
                // 疼痛强度筛选
                Section("疼痛强度") {
                    if viewModel.selectedIntensityRange != nil {
                        Button("清除筛选") {
                            viewModel.selectedIntensityRange = nil
                        }
                    }
                    
                    HStack {
                        ForEach(0...10, id: \.self) { intensity in
                            Button {
                                toggleIntensity(intensity)
                            } label: {
                                Text("\(intensity)")
                                    .font(.caption)
                                    .foregroundStyle(isIntensitySelected(intensity) ? .white : AppColors.textPrimary)
                                    .frame(width: 30, height: 30)
                                    .background(isIntensitySelected(intensity) ? AppColors.primary : AppColors.surfaceElevated)
                                    .clipShape(Circle())
                            }
                        }
                    }
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
            viewModel.selectedDateRange = AttackListViewModel.DateRange(
                start: customStartDate,
                end: customEndDate
            )
        }
    }
    
    private func isIntensitySelected(_ intensity: Int) -> Bool {
        guard let range = viewModel.selectedIntensityRange else { return false }
        return range.contains(intensity)
    }
    
    private func toggleIntensity(_ intensity: Int) {
        if let range = viewModel.selectedIntensityRange {
            if range.lowerBound == intensity && range.upperBound == intensity {
                // 取消选择
                viewModel.selectedIntensityRange = nil
            } else if intensity < range.lowerBound {
                viewModel.selectedIntensityRange = intensity...range.upperBound
            } else if intensity > range.upperBound {
                viewModel.selectedIntensityRange = range.lowerBound...intensity
            } else {
                viewModel.selectedIntensityRange = intensity...intensity
            }
        } else {
            viewModel.selectedIntensityRange = intensity...intensity
        }
    }
}

#Preview {
    AttackListView()
        .modelContainer(for: AttackRecord.self, inMemory: true)
}
