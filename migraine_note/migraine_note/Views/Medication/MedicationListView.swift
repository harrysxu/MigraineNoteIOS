//
//  MedicationListView.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  药箱管理页面 - 显示所有药物及其使用情况
//

import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var medications: [Medication]
    @Query private var medicationLogs: [MedicationLog]
    
    @State private var viewModel = MedicationViewModel()
    @State private var showingAddSheet = false
    @State private var showingFilterSheet = false
    @State private var selectedMedication: Medication?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if medications.isEmpty {
                    emptyStateView
                } else {
                    medicationListContent
                }
            }
            .navigationTitle("药箱")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("筛选", selection: $viewModel.selectedCategory) {
                            ForEach(MedicationViewModel.MedicationCategoryFilter.allCases, id: \.self) { category in
                                Label(category.rawValue, systemImage: category.systemImage)
                                    .tag(category)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(AppColors.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "搜索药物名称或类别")
            .sheet(isPresented: $showingAddSheet) {
                AddMedicationView()
            }
            .sheet(item: $selectedMedication) { medication in
                MedicationDetailView(medication: medication)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: "pill.circle")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            
            Text("药箱是空的")
                .appFont(.title)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("添加您常用的药物以便快速记录")
                .appFont(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("添加药物", systemImage: "plus.circle.fill")
                    .appFont(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.large)
                    .padding(.vertical, AppSpacing.medium)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
            }
        }
        .padding(.horizontal, AppSpacing.extraLarge)
    }
    
    // MARK: - List Content
    
    private var medicationListContent: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                let filteredMeds = viewModel.filteredMedications(medications, logs: medicationLogs)
                
                if filteredMeds.isEmpty {
                    noResultsView
                } else {
                    ForEach(filteredMeds) { medication in
                        MedicationCardView(
                            medication: medication,
                            usageDays: viewModel.monthlyUsageDays(for: medication, logs: medicationLogs),
                            viewModel: viewModel
                        )
                        .onTapGesture {
                            selectedMedication = medication
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteMedication(medication, from: modelContext)
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
            
            Text("未找到匹配的药物")
                .appFont(.headline)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("尝试调整搜索或筛选条件")
                .appFont(.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.extraLarge * 2)
    }
}

// MARK: - Medication Card View

struct MedicationCardView: View {
    let medication: Medication
    let usageDays: Int
    let viewModel: MedicationViewModel
    
    @Environment(\.modelContext) private var modelContext
    
    private var mohWarning: String? {
        viewModel.mohWarningText(for: medication, usageDays: usageDays)
    }
    
    private var isLowInventory: Bool {
        viewModel.isLowInventory(medication)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // 顶部：药物名称和类别
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .appFont(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Label(medication.category.rawValue, systemImage: "pills")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
                
                // 类型标签
                Text(medication.isAcute ? "急性" : "预防")
                    .appFont(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(medication.isAcute ? AppColors.error.opacity(0.8) : AppColors.success.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            }
            
            Divider()
            
            // 剂量和库存
            HStack(spacing: AppSpacing.large) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("标准剂量")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("\(medication.standardDosage, specifier: "%.1f") \(medication.unit)")
                        .appFont(.body)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("库存")
                        .appFont(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    HStack(spacing: 4) {
                        if isLowInventory {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.warning)
                        }
                        Text("\(medication.inventory)")
                            .appFont(.body)
                            .foregroundStyle(isLowInventory ? AppColors.warning : AppColors.textPrimary)
                    }
                }
            }
            
            // 本月使用情况
            if medication.isAcute {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本月使用")
                            .appFont(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        HStack(spacing: 6) {
                            Text("\(usageDays) 天")
                                .appFont(.body)
                                .foregroundStyle(AppColors.textPrimary)
                            
                            if let limit = medication.monthlyLimit {
                                Text("/ \(limit) 天")
                                    .appFont(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                                
                                // 进度条
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(AppColors.surfaceElevated)
                                            .frame(height: 4)
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(progressColor)
                                            .frame(
                                                width: min(geometry.size.width * CGFloat(usageDays) / CGFloat(limit), geometry.size.width),
                                                height: 4
                                            )
                                    }
                                }
                                .frame(height: 4)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // MOH警告
            if let warning = mohWarning {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(viewModel.isExceedingMOHLimit(medication: medication, usageDays: usageDays) ? AppColors.error : AppColors.warning)
                    Text(warning)
                        .appFont(.caption)
                        .foregroundStyle(viewModel.isExceedingMOHLimit(medication: medication, usageDays: usageDays) ? AppColors.error : AppColors.warning)
                }
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    viewModel.isExceedingMOHLimit(medication: medication, usageDays: usageDays) ? 
                    AppColors.error.opacity(0.1) : AppColors.warning.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .shadow(color: AppColors.shadowColor, radius: AppSpacing.shadowRadiusSmall)
    }
    
    private var progressColor: Color {
        if let limit = medication.monthlyLimit {
            let ratio = Double(usageDays) / Double(limit)
            if ratio >= 1.0 {
                return AppColors.error
            } else if ratio >= 0.8 {
                return AppColors.warning
            }
        }
        return AppColors.success
    }
}

#Preview {
    MedicationListView()
        .modelContainer(for: Medication.self, inMemory: true)
}
