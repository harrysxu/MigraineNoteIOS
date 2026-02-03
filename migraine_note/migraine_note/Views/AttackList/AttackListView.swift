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
                Color.backgroundPrimary.ignoresSafeArea()
                
                if attacks.isEmpty {
                    emptyStateView
                } else {
                    attackListContent
                }
            }
            .navigationTitle("记录列表")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(Color.primary)
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
        VStack(spacing: Spacing.lg) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 80))
                .foregroundStyle(Color.labelSecondary.opacity(0.5))
            
            Text("暂无记录")
                .appFont(.title)
                .foregroundStyle(Color.labelPrimary)
            
            Text("开始记录您的第一次偏头痛发作")
                .appFont(.body)
                .foregroundStyle(Color.labelSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
    }
    
    // MARK: - List Content
    
    private var attackListContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                let filteredAttacks = viewModel.filteredAttacks(attacks)
                
                if filteredAttacks.isEmpty {
                    noResultsView
                } else {
                    let groupedAttacks = Dictionary(grouping: filteredAttacks) { attack in
                        attack.startTime.year
                    }
                    .sorted { $0.key > $1.key } // 按年份降序排列
                    
                    ForEach(groupedAttacks, id: \.key) { year, yearAttacks in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            // 年份标题
                            Text("\(year)年")
                                .appFont(.title3)
                                .foregroundStyle(Color.labelPrimary)
                                .fontWeight(.semibold)
                                .padding(.horizontal, Spacing.md)
                                .padding(.top, Spacing.xs)
                            
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
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(Color.labelSecondary.opacity(0.5))
            
            Text("未找到匹配的记录")
                .appFont(.headline)
                .foregroundStyle(Color.labelPrimary)
            
            Text("尝试调整搜索或筛选条件")
                .appFont(.body)
                .foregroundStyle(Color.labelSecondary)
        }
        .padding(.top, Spacing.xl * 2)
    }
}

// MARK: - Attack Row View

struct AttackRowView: View {
    let attack: AttackRecord
    
    private var intensityColor: Color {
        Color.painIntensityColor(for: attack.painIntensity)
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
                    .foregroundStyle(Color.labelTertiary)
            }
            .frame(width: 56, height: 56)
            .background(intensityColor.opacity(0.15))
            .cornerRadius(12)
            
            // 中间内容
            VStack(alignment: .leading, spacing: 4) {
                Text(attack.startTime.smartFormatted())
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.labelPrimary)
                
                HStack(spacing: 8) {
                    if let duration = calculateDuration() {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(duration)
                        }
                        .font(.caption)
                        .foregroundStyle(Color.labelSecondary)
                    }
                    
                    if !attack.medicationLogs.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "pills")
                                .font(.caption2)
                            Text("\(attack.medicationLogs.count)种药物")
                        }
                        .font(.caption)
                        .foregroundStyle(Color.labelSecondary)
                    }
                }
            }
            
            Spacer()
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.labelTertiary)
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
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
                                    .foregroundStyle(isIntensitySelected(intensity) ? .white : Color.labelPrimary)
                                    .frame(width: 30, height: 30)
                                    .background(isIntensitySelected(intensity) ? Color.primary : Color.backgroundTertiary)
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
                    .foregroundStyle(Color.warning)
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
