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
        EmotionalCard(style: .default) {
            VStack(spacing: AppSpacing.medium) {
                // 月份标题和导航
                monthHeader
                
                // 星期标题行
                weekdayHeader
                
                // 日期网格
                dateGrid
            }
        }
        .padding(.horizontal)
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
    
    private var isSelected: Bool {
        if let selectedDate = viewModel.selectedDate {
            return calendar.isDate(date, inSameDayAs: selectedDate)
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期数字
            Text(calendar.component(.day, from: date).description)
                .font(.system(size: 14, weight: isToday || isSelected ? .bold : .regular))
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
                .stroke(borderColor, lineWidth: isSelected ? 2 : (isToday ? 1.5 : 0))
        )
        .onTapGesture {
            if isInCurrentMonth {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isSelected {
                        viewModel.selectedDate = nil // 再次点击取消选中
                    } else {
                        viewModel.selectedDate = date
                    }
                }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
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
        if isSelected {
            return .white
        } else if !isInCurrentMonth {
            return AppColors.textTertiary
        } else if isToday {
            return Color.accentPrimary
        } else {
            return AppColors.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentPrimary
        } else if !viewModel.getAttacks(for: date).isEmpty {
            return AppColors.surface.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.accentPrimary
        } else if isToday {
            return Color.accentPrimary.opacity(0.5)
        } else {
            return Color.clear
        }
    }
}

// MARK: - 选中日期详情面板

struct SelectedDateDetailPanel: View {
    let date: Date
    let attacks: [AttackRecord]
    let healthEvents: [HealthEvent]
    var onAttackTap: ((AttackRecord) -> Void)?
    var onHealthEventTap: ((HealthEvent) -> Void)?
    
    private let calendar = Calendar.current
    
    var body: some View {
        EmotionalCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 12) {
                // 日期标题
                HStack {
                    Text(date.fullDate())
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    if calendar.isDateInToday(date) {
                        Text("今天")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentPrimary)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                if attacks.isEmpty && healthEvents.isEmpty {
                    // 无记录
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.statusSuccess)
                        Text("当天无发作记录")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    // 发作记录
                    if !attacks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("发作记录")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.textSecondary)
                            
                            ForEach(attacks, id: \.id) { attack in
                                Button {
                                    onAttackTap?(attack)
                                } label: {
                                    HStack(spacing: 12) {
                                        // 疼痛强度
                                        Text("\(attack.painIntensity)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(Color.painCategoryColor(for: attack.painIntensity))
                                            .frame(width: 40, height: 40)
                                            .background(Color.painCategoryColor(for: attack.painIntensity).opacity(0.15))
                                            .cornerRadius(10)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(attack.startTime.shortTime() + (attack.endTime != nil ? " - \(attack.endTime!.shortTime())" : " (进行中)"))
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Color.textPrimary)
                                            
                                            if let duration = attack.duration {
                                                let hours = Int(duration) / 3600
                                                let minutes = (Int(duration) % 3600) / 60
                                                Text("持续 \(hours > 0 ? "\(hours)h" : "")\(minutes)m")
                                                    .font(.caption)
                                                    .foregroundStyle(Color.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // 用药标记
                                        if !attack.medications.isEmpty {
                                            Image(systemName: "pills.fill")
                                                .font(.caption)
                                                .foregroundStyle(Color.accentPrimary)
                                        }
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(Color.textTertiary)
                                    }
                                    .padding(10)
                                    .background(Color.backgroundPrimary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 健康事件
                    if !healthEvents.isEmpty {
                        if !attacks.isEmpty {
                            Divider()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("健康事件")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.textSecondary)
                            
                            ForEach(healthEvents, id: \.id) { event in
                                Button {
                                    onHealthEventTap?(event)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: event.eventType.icon)
                                            .font(.title3)
                                            .foregroundStyle(healthEventColor(for: event.eventType))
                                            .frame(width: 40, height: 40)
                                            .background(healthEventColor(for: event.eventType).opacity(0.15))
                                            .cornerRadius(10)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.displayTitle)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(Color.textPrimary)
                                            
                                            if let detail = event.displayDetail {
                                                Text(detail)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.textSecondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(Color.textTertiary)
                                    }
                                    .padding(10)
                                    .background(Color.backgroundPrimary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func healthEventColor(for eventType: HealthEventType) -> Color {
        switch eventType {
        case .medication: return .accentPrimary
        case .tcmTreatment: return .statusSuccess
        case .surgery: return .statusInfo
        }
    }
}

// MARK: - 月度统计卡片

struct MonthlyStatsCard: View {
    let stats: MonthlyStatistics
    
    var body: some View {
        EmotionalCard(style: .elevated) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 标题行 - 与图表页整体概况保持一致
                HStack {
                    Text("本月统计")
                        .font(.title3.weight(.semibold))
                    
                    Spacer()
                }
                
                // 统计数据网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.md) {
                    // 核心指标
                    StatItem(
                        title: "发作天数",
                        value: "\(stats.attackDays)",
                        icon: "calendar.badge.exclamationmark",
                        color: stats.isChronic ? Color.statusError : Color.statusWarning,
                        subtitle: stats.isChronic ? "慢性偏头痛" : nil
                    )
                    
                    StatItem(
                        title: "发作次数",
                        value: "\(stats.totalAttacks)",
                        icon: "exclamationmark.triangle.fill",
                        color: Color.statusError
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
                        color: Color.painCategoryColor(for: Int(stats.averagePainIntensity))
                    )
                    
                    // 急性用药（始终显示）
                    StatItem(
                        title: "急性用药天数",
                        value: "\(stats.acuteMedicationDays)",
                        icon: "calendar.badge.clock",
                        color: stats.acuteMedicationDays >= 10 ? Color.statusWarning : Color.statusSuccess
                    )
                    
                    StatItem(
                        title: "急性用药次数",
                        value: "\(stats.acuteMedicationCount)",
                        icon: "pills.fill",
                        color: stats.acuteMedicationDays >= 10 ? Color.statusWarning : Color.accentPrimary
                    )
                    
                    // 预防性用药（有数据时显示）
                    if stats.hasPreventiveMedication {
                        StatItem(
                            title: "预防性用药天数",
                            value: "\(stats.preventiveMedicationDays)",
                            icon: "calendar.badge.plus",
                            color: Color.statusSuccess
                        )
                        
                        StatItem(
                            title: "预防性用药次数",
                            value: "\(stats.preventiveMedicationCount)",
                            icon: "shield.fill",
                            color: Color.statusSuccess
                        )
                    }
                    
                    // 中医治疗（有数据时显示）
                    if stats.hasTCMTreatment {
                        StatItem(
                            title: "中医治疗次数",
                            value: "\(stats.tcmTreatmentCount)",
                            icon: "leaf.circle.fill",
                            color: Color.statusSuccess
                        )
                    }
                    
                    // 手术（有数据时显示）
                    if stats.hasSurgery {
                        StatItem(
                            title: "手术次数",
                            value: "\(stats.surgeryCount)",
                            icon: "cross.case.circle.fill",
                            color: Color.statusInfo
                        )
                    }
                }
                
                // MOH风险警告
                if stats.mohRisk != .none {
                    mohRiskWarning
                }
            }
        }
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
        .background(Color.backgroundPrimary)
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
