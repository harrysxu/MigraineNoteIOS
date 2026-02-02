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
            .navigationTitle("记录列表")
            .navigationBarTitleDisplayMode(.large)
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
                    ForEach(filteredAttacks) { attack in
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
    
    private var durationText: String {
        let duration = attack.durationOrElapsed
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private var intensityColor: Color {
        PainIntensity.from(attack.painIntensity).color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // 顶部：日期和疼痛强度
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(attack.startTime.fullDate())
                        .appFont(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(attack.startTime.shortTime())
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                // 疼痛强度指示器
                HStack(spacing: 6) {
                    Text("\(attack.painIntensity)")
                        .appFont(.title3)
                        .foregroundStyle(intensityColor)
                        .fontWeight(.bold)
                    
                    Text("/10")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(intensityColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
            }
            
            // 持续时间
            Label(durationText, systemImage: "clock")
                .appFont(.body)
                .foregroundStyle(AppColors.textSecondary)
            
            // 疼痛部位
            if !attack.painLocations.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "figure.arms.open")
                        .font(.caption)
                    Text(attack.painLocations.map { $0.displayName }.joined(separator: ", "))
                        .appFont(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(AppColors.textSecondary)
            }
            
            // 主要诱因（显示前3个）
            if !attack.triggers.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(attack.triggers.prefix(3))) { trigger in
                        Text(trigger.name)
                            .appFont(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                    }
                    
                    if attack.triggers.count > 3 {
                        Text("+\(attack.triggers.count - 3)")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            
            // 用药情况
            if !attack.medicationLogs.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "pills.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.info)
                    Text("已用药 \(attack.medicationLogs.count) 次")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.info)
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .shadow(color: AppColors.shadowColor, radius: AppSpacing.shadowRadiusSmall)
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
