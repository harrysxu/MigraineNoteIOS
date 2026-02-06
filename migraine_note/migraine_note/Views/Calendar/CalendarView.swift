//
//  CalendarView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CalendarViewModel
    
    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: CalendarViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    // 月份统计卡片
                    if let stats = viewModel.monthlyStats {
                        MonthlyStatsCard(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    // 日历网格
                    calendarGridSection
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AppColors.background)
            .navigationTitle("日历")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.moveToToday) {
                        Text("今天")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
            }
        }
        .onAppear {
            viewModel = CalendarViewModel(modelContext: modelContext)
        }
    }
    
    // MARK: - 日历网格部分
    
    private var calendarGridSection: some View {
        VStack(spacing: AppSpacing.medium) {
            // 月份标题和导航
            monthHeader
            
            // 星期标题行
            weekdayHeader
            
            // 日期网格
            dateGrid
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }
    
    // MARK: - 月份标题
    
    private var monthHeader: some View {
        HStack {
            Button(action: viewModel.moveToPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text(viewModel.monthTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: viewModel.moveToNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }
    
    // MARK: - 星期标题行
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, AppSpacing.small)
    }
    
    // MARK: - 日期网格
    
    private var dateGrid: some View {
        let days = viewModel.getDaysInMonth()
        let rows = days.count / 7
        
        return VStack(spacing: AppSpacing.small) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: AppSpacing.small) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < days.count {
                            DayCell(
                                date: days[index],
                                viewModel: viewModel
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 日期单元格

struct DayCell: View {
    let date: Date
    let viewModel: CalendarViewModel
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期数字
            Text(calendar.component(.day, from: date).description)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)
            
            // 指示器（头痛记录 + 健康事件）
            HStack(spacing: 3) {
                // 头痛记录指示器
                if let intensity = viewModel.getMaxPainIntensity(for: date) {
                    Circle()
                        .fill(AppColors.painCategoryColor(for: intensity))
                        .frame(width: 6, height: 6)
                }
                
                // 健康事件指示器（按类型显示）
                ForEach(Array(viewModel.getHealthEventTypes(for: date)), id: \.self) { eventType in
                    Circle()
                        .fill(AppColors.healthEventColor(for: eventType))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 6) // 固定高度，避免布局跳动
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(backgroundColor)
        .cornerRadius(AppSpacing.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall)
                .stroke(isToday ? Color.accentPrimary : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            if isInCurrentMonth {
                viewModel.selectedDate = date
                // TODO: 导航到该日期的详情页面
            }
        }
    }
    
    private var isInCurrentMonth: Bool {
        viewModel.isDateInCurrentMonth(date)
    }
    
    private var isToday: Bool {
        viewModel.isToday(date)
    }
    
    private var textColor: Color {
        if !isInCurrentMonth {
            return AppColors.textTertiary
        } else if isToday {
            return Color.accentPrimary
        } else {
            return AppColors.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if viewModel.getAttacks(for: date).isEmpty {
            return Color.clear
        } else {
            return AppColors.surface.opacity(0.5)
        }
    }
}

// MARK: - 月度统计卡片

struct MonthlyStatsCard: View {
    let stats: MonthlyStatistics
    
    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            // 标题
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.accentPrimary)
                Text("本月统计")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
            }
            
            // 统计数据网格 - 3x2布局
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.medium) {
                StatItem(
                    title: "发作天数",
                    value: "\(stats.attackDays)",
                    icon: "calendar.badge.exclamationmark",
                    color: stats.isChronic ? AppColors.error : AppColors.warning,
                    subtitle: stats.isChronic ? "慢性偏头痛" : nil
                )
                
                StatItem(
                    title: "发作次数",
                    value: "\(stats.totalAttacks)",
                    icon: "exclamationmark.triangle.fill",
                    color: AppColors.error
                )
                
                StatItem(
                    title: "平均持续时长",
                    value: stats.averageDurationFormatted,
                    icon: "clock.fill",
                    color: Color.accentSecondary
                )
                
                StatItem(
                    title: "平均强度",
                    value: stats.averageIntensityFormatted,
                    icon: "waveform.path.ecg",
                    color: AppColors.painCategoryColor(for: Int(stats.averagePainIntensity))
                )
                
                StatItem(
                    title: "用药天数",
                    value: "\(stats.medicationDays)",
                    icon: "calendar.badge.plus",
                    color: stats.mohRisk != .none ? AppColors.warning : AppColors.success
                )
                
                StatItem(
                    title: "用药次数",
                    value: "\(stats.totalMedicationUses)",
                    icon: "pills.fill",
                    color: Color.accentPrimary
                )
            }
            
            // MOH风险警告
            if stats.mohRisk != .none {
                mohRiskWarning
            }
        }
        .padding(AppSpacing.medium)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }
    
    @ViewBuilder
    private var mohRiskWarning: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(mohRiskColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(mohRiskTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                
                Text(mohRiskMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.small)
        .background(mohRiskColor.opacity(0.1))
        .cornerRadius(AppSpacing.cornerRadiusSmall)
    }
    
    private var mohRiskColor: Color {
        switch stats.mohRisk {
        case .none, .low:
            return AppColors.warning
        case .medium:
            return AppColors.warning
        case .high:
            return AppColors.error
        }
    }
    
    private var mohRiskTitle: String {
        switch stats.mohRisk {
        case .none:
            return ""
        case .low:
            return "用药提醒"
        case .medium:
            return "MOH中度风险"
        case .high:
            return "MOH高度风险"
        }
    }
    
    private var mohRiskMessage: String {
        switch stats.mohRisk {
        case .none:
            return ""
        case .low:
            return "本月用药频次较高，请注意用药规律"
        case .medium:
            return "用药天数接近MOH阈值，建议咨询医生"
        case .high:
            return "用药天数超过MOH阈值，强烈建议就医"
        }
    }
}

// MARK: - 统计项组件

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String?
    
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.small)
        .background(AppColors.background)
        .cornerRadius(AppSpacing.cornerRadiusSmall)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: AttackRecord.self, Medication.self, configurations: config)
        let context = container.mainContext
        
        // 创建测试数据
        let calendar = Calendar.current
        for i in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let attack = AttackRecord(startTime: date)
                attack.painIntensity = Int.random(in: 1...10)
                attack.endTime = calendar.date(byAdding: .hour, value: 2, to: date)
                context.insert(attack)
            }
        }
        
        return container
    }()
    
    CalendarView(modelContext: container.mainContext)
}
