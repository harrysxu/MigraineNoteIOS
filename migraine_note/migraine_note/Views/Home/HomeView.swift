//
//  HomeView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData
import CoreData
import Combine

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var weatherManager = WeatherManager()
    @State private var showRecordingView = false
    @State private var selectedAttackForDetail: AttackRecord?
    @State private var selectedAttackForEdit: AttackRecord?
    @State private var selectedHealthEventForDetail: HealthEvent?
    @State private var showAddHealthEventSheet = false
    @State private var itemToDelete: TimelineItemType?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if let vm = viewModel {
                            // 动态问候 - 左对齐
                            DynamicGreeting()
                                .fadeIn(delay: 0.1)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // 状态卡片 - 全宽
                            CompactStatusCard(
                                streakDays: vm.streakDays,
                                ongoingAttack: vm.ongoingAttack
                            )
                            .fadeIn(delay: 0.2)
                            .padding(.horizontal, 20)
                            
                            // 主操作按钮
                            MainActionButton(
                                ongoingAttack: vm.ongoingAttack,
                                onTap: {
                                    if let attack = vm.ongoingAttack {
                                        selectedAttackForEdit = attack
                                    } else {
                                        showRecordingView = true
                                    }
                                }
                            )
                            .fadeIn(delay: 0.3)
                            .padding(.horizontal, 20)
                            
                            // 快速开始/结束 + 健康事件按钮（横排）
                            HStack(spacing: 12) {
                                SecondaryActionButton(
                                    title: vm.ongoingAttack == nil ? "快速开始" : "快速结束",
                                    icon: vm.ongoingAttack == nil ? "bolt.fill" : "checkmark",
                                    onTap: {
                                        if let attack = vm.ongoingAttack {
                                            vm.quickEndRecording(attack)
                                        } else {
                                            Task {
                                                _ = await vm.quickStartRecording()
                                            }
                                        }
                                    }
                                )
                                
                                SecondaryActionButton(
                                    title: "健康事件",
                                    icon: "calendar.badge.plus",
                                    onTap: {
                                        showAddHealthEventSheet = true
                                    }
                                )
                            }
                            .fadeIn(delay: 0.35)
                            .padding(.horizontal, 20)
                            
                            // 天气卡片 + 月度概况 - 网格布局
                            VStack(spacing: 16) {
                                WeatherInsightCard(
                                    weather: vm.currentWeather,
                                    error: vm.weatherError,
                                    isRefreshing: vm.isRefreshingWeather,
                                    isLocationDenied: vm.isLocationDenied,
                                    onRefresh: {
                                        vm.refreshWeather()
                                    }
                                )
                                    .fadeIn(delay: 0.4)
                                
                                MonthlyOverviewCard(
                                    attackDays: vm.monthlyAttackDays,
                                    averageIntensity: vm.monthlyAverageIntensity,
                                    medicationStats: vm.monthlyMedicationStats
                                )
                                    .fadeIn(delay: 0.5)
                            }
                            .padding(.horizontal, 20)
                            
                            // 最近记录 - 列表布局（包括偏头痛发作和健康事件）
                            if !vm.recentTimelineItems.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("最近记录")
                                            .font(.title3.weight(.semibold))
                                            .foregroundStyle(Color.textPrimary)
                                        
                                        Spacer()
                                        
                                        Button {
                                            NotificationCenter.default.post(
                                                name: NSNotification.Name("SwitchToRecordListTab"),
                                                object: nil
                                            )
                                        } label: {
                                            Text("查看全部")
                                                .font(.subheadline)
                                                .foregroundStyle(Color.accentPrimary)
                                        }
                                    }
                                    
                                    VStack(spacing: 12) {
                                        ForEach(vm.recentTimelineItems.prefix(5), id: \.id) { item in
                                            CompactTimelineRow(item: item)
                                                .onTapGesture {
                                                    switch item {
                                                    case .attack(let attack):
                                                        selectedAttackForDetail = attack
                                                    case .healthEvent(let event):
                                                        selectedHealthEventForDetail = event
                                                    }
                                                }
                                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                    Button(role: .destructive) {
                                                        itemToDelete = item
                                                        showDeleteConfirmation = true
                                                    } label: {
                                                        Label("删除", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                }
                                .fadeIn(delay: 0.6)
                                .padding(.horizontal, 20)
                            }
                        } else {
                            ProgressView()
                                .tint(Color.accentPrimary)
                                .frame(maxWidth: .infinity, maxHeight: 300)
                        }
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 12)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.backgroundPrimary.ignoresSafeArea())
                .sheet(isPresented: $showRecordingView) {
                    RecordingSheetView(
                        modelContext: modelContext,
                        weatherManager: weatherManager,
                        isPresented: $showRecordingView,
                        onDismiss: {
                            viewModel?.refreshData()
                        }
                    )
                }
                .sheet(item: $selectedAttackForDetail) { attack in
                    AttackDetailView(attack: attack)
                        .onDisappear {
                            viewModel?.refreshData()
                        }
                }
                .sheet(item: $selectedAttackForEdit) { attack in
                    NavigationStack {
                        SimplifiedRecordingView(
                            modelContext: modelContext,
                            weatherManager: weatherManager,
                            existingAttack: attack,
                            onCancel: {
                                selectedAttackForEdit = nil
                            }
                        )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("取消") {
                                    selectedAttackForEdit = nil
                                }
                            }
                        }
                    }
                    .onDisappear {
                        viewModel?.refreshData()
                    }
                }
                .sheet(isPresented: $showAddHealthEventSheet) {
                    AddHealthEventView()
                        .onDisappear {
                            viewModel?.refreshData()
                        }
                }
                .sheet(item: $selectedHealthEventForDetail) { event in
                    HealthEventDetailView(event: event)
                        .onDisappear {
                            viewModel?.refreshData()
                        }
                }
                .alert("确认删除", isPresented: $showDeleteConfirmation) {
                    Button("取消", role: .cancel) {
                        itemToDelete = nil
                    }
                    Button("删除", role: .destructive) {
                        if let item = itemToDelete {
                            deleteTimelineItem(item)
                        }
                        itemToDelete = nil
                    }
                } message: {
                    if let item = itemToDelete {
                        switch item {
                        case .attack:
                            Text("确定要删除这条发作记录吗？此操作不可撤销。")
                        case .healthEvent:
                            Text("确定要删除这条健康事件吗？此操作不可撤销。")
                        }
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext, weatherManager: weatherManager)
                }
            }
            .onChange(of: weatherManager.authorizationVersion) {
                viewModel?.refreshWeather()
            }
            .onReceive(NotificationCenter.default.publisher(for: .allDataCleared)) { _ in
                // 清空所有选中状态，避免访问已删除的对象
                selectedAttackForDetail = nil
                selectedAttackForEdit = nil
                selectedHealthEventForDetail = nil
                // 刷新数据
                viewModel?.refreshData()
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
                    .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            ) { _ in
                // iCloud 远程数据同步完成后，刷新首页数据（增大防抖时间避免频繁刷新）
                viewModel?.refreshData()
            }
    }
    
    // MARK: - Helper Methods
    
    private func deleteAttack(_ attack: AttackRecord) {
        modelContext.delete(attack)
        do {
            try modelContext.save()
            viewModel?.refreshData()
            AppToastManager.shared.showSuccess("记录已删除")
        } catch {
            AppToastManager.shared.showError("删除失败，请重试")
        }
    }
    
    private func deleteTimelineItem(_ item: TimelineItemType) {
        switch item {
        case .attack(let attack):
            modelContext.delete(attack)
        case .healthEvent(let event):
            modelContext.delete(event)
        }
        
        do {
            try modelContext.save()
            viewModel?.refreshData()
            AppToastManager.shared.showSuccess("记录已删除")
        } catch {
            AppToastManager.shared.showError("删除失败，请重试")
        }
    }
}

// MARK: - 动态问候语

struct DynamicGreeting: View {
    @State private var currentHour = Calendar.current.component(.hour, from: Date())
    
    var greeting: String {
        switch currentHour {
        case 6..<11:
            return "早安"
        case 11..<14:
            return "中午好"
        case 14..<18:
            return "下午好"
        case 18..<22:
            return "晚上好"
        default:
            return "夜深了"
        }
    }
    
    var greetingColor: LinearGradient {
        switch currentHour {
        case 6..<11:
            return LinearGradient(
                colors: [Color.warmAccent.opacity(0.8), Color.warmAccent],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 11..<18:
            return Color.primaryGradient
        case 18..<22:
            return LinearGradient(
                colors: [Color.accentSecondary.opacity(0.8), Color.accentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [Color.accentSecondary.opacity(0.6), Color.accentPrimary.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(greetingColor)
            
            Text("今天感觉如何？")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 紧凑状态卡片

struct CompactStatusCard: View {
    let streakDays: Int
    let ongoingAttack: AttackRecord?
    
    var streakEmoji: String {
        switch streakDays {
        case 0:
            return "🌱"
        case 1...3:
            return "💪"
        case 4...6:
            return "✨"
        case 7...13:
            return "🌟"
        case 14...29:
            return "🎯"
        case 30...:
            return "🎉"
        default:
            return "🌱"
        }
    }
    
    // 统一卡片内容高度，避免状态切换时闪烁
    private let cardContentHeight: CGFloat = 48
    
    var body: some View {
        EmotionalCard(style: .elevated) {
            if let attack = ongoingAttack {
                // 发作进行中 - 显示持续时间
                HStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.statusWarning)
                        .frame(width: 48, height: cardContentHeight)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("发作进行中")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("已持续 \(formatDuration(attack.startTime))")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                }
                .frame(minHeight: cardContentHeight)
            } else {
                // 无发作状态 - 横向布局
                HStack(spacing: 16) {
                    Text(streakEmoji)
                        .font(.system(size: 36))
                        .frame(width: 48, height: cardContentHeight)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if streakDays > 0 {
                            Text("\(streakDays) 天")
                                .font(.headline)
                                .foregroundStyle(Color.accentPrimary)
                            Text("无头痛")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        } else {
                            Text("开始记录")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            Text("发现健康规律")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .frame(minHeight: cardContentHeight)
            }
        }
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// MARK: - 主操作按钮

struct MainActionButton: View {
    let ongoingAttack: AttackRecord?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                Image(systemName: ongoingAttack == nil ? "plus.circle.fill" : "square.and.pencil")
                    .font(.system(size: 24))
                
                Text(ongoingAttack == nil ? "开始记录" : "编辑记录")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primaryGradient)
            .cornerRadius(16)
            .shadow(color: Color.accentPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 次要操作按钮

struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.accentPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentPrimary.opacity(0.1))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 天气洞察卡片

struct WeatherInsightCard: View {
    let weather: WeatherSnapshot?
    let error: String?
    var isRefreshing: Bool = false
    var isLocationDenied: Bool = false
    var onRefresh: (() -> Void)?
    
    var body: some View {
        EmotionalCard(style: .default) {
            if let weather = weather {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题行
                    HStack {
                        Image(systemName: weatherIcon(for: weather.condition))
                            .font(.system(size: 32))
                            .foregroundStyle(Color.accentPrimary)
                            .frame(width: 48, height: 48)
                            .background(Color.accentPrimary.opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("当前天气")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            
                            if !weather.location.isEmpty {
                                Text(weather.location)
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        // 温度显示
                        Text("\(Int(weather.temperature))°C")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.accentPrimary)
                        
                        // 刷新按钮
                        if let onRefresh = onRefresh {
                            Button(action: onRefresh) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.body)
                                    .foregroundStyle(Color.accentPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(Color.accentPrimary.opacity(0.1))
                                    .clipShape(Circle())
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                    .animation(
                                        isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                        value: isRefreshing
                                    )
                            }
                            .disabled(isRefreshing)
                        }
                    }
                    
                    // 详细信息网格
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            WeatherDetailItem(
                                icon: "gauge.high",
                                label: "气压",
                                value: String(format: "%.0f hPa", weather.pressure),
                                trend: weather.pressureTrend
                            )
                            
                            WeatherDetailItem(
                                icon: "humidity",
                                label: "湿度",
                                value: String(format: "%.0f%%", weather.humidity)
                            )
                        }
                        
                        // 风险警告
                        if !weather.warnings.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(weather.warnings, id: \.self) { warning in
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundStyle(Color.statusWarning)
                                        Text(warning)
                                            .font(.caption)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                }
                            }
                        }
                        
                        // Apple Weather 归属信息
                        if !weather.warnings.isEmpty {
                            Divider()
                        }
                        WeatherAttribution(style: .compact)
                    }
                }
            } else if isLocationDenied {
                // 定位权限被拒绝，提示用户开启
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.statusWarning)
                            .frame(width: 48, height: 48)
                            .background(Color.statusWarning.opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("无法获取位置")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            Text("需要定位权限以获取天气数据")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    // 开启定位按钮
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.body)
                            Text("前往设置开启定位")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentPrimary)
                        .cornerRadius(10)
                    }
                }
            } else if let error = error {
                // 错误状态 - 显示友好的提示信息
                HStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.statusWarning)
                        .frame(width: 48, height: 48)
                        .background(Color.statusWarning.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("天气数据不可用")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // 刷新按钮
                    if let onRefresh = onRefresh {
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                                .foregroundStyle(Color.accentPrimary)
                                .frame(width: 36, height: 36)
                                .background(Color.accentPrimary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
            } else {
                // 加载状态
                HStack(spacing: 16) {
                    ProgressView()
                        .frame(width: 48, height: 48)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("正在获取天气数据...")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("请稍候")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func weatherIcon(for condition: String) -> String {
        // 根据天气状况返回对应图标
        let lowercased = condition.lowercased()
        if lowercased.contains("晴") || lowercased.contains("clear") {
            return "sun.max.fill"
        } else if lowercased.contains("云") || lowercased.contains("cloud") {
            return "cloud.fill"
        } else if lowercased.contains("雨") || lowercased.contains("rain") {
            return "cloud.rain.fill"
        } else if lowercased.contains("雪") || lowercased.contains("snow") {
            return "cloud.snow.fill"
        } else {
            return "cloud.sun.fill"
        }
    }
}

// MARK: - 天气详情项

struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String
    var trend: PressureTrend?
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                            .foregroundStyle(trendColor(for: trend))
                    }
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
    
    private func trendColor(for trend: PressureTrend) -> Color {
        switch trend {
        case .rising:
            return .statusSuccess
        case .falling:
            return .statusWarning
        case .steady:
            return .textSecondary
        }
    }
}

// MARK: - 月度概况卡片

struct MonthlyOverviewCard: View {
    // 从 HomeViewModel 接收预计算的数据，不再独立 @Query 全量加载
    let attackDays: Int
    let averageIntensity: Double
    let medicationStats: DetailedMedicationStatistics?
    
    var body: some View {
        let stats = medicationStats ?? DetailedMedicationStatistics.empty
        
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                // 标题行
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(Color.accentPrimary)
                        Text("本月概况")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    Button {
                        // 先切换到数据标签页
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SwitchToDataTab"),
                            object: nil
                        )
                        // 延迟一下再切换到日历视图，确保标签页已经切换
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("SwitchToDataCalendarView"),
                                object: nil
                            )
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("日历")
                                .font(.caption.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                // 统计数据网格
                VStack(spacing: 12) {
                    // 第一行：发作统计
                    HStack(spacing: 12) {
                        CompactStatCard(
                            value: "\(attackDays)",
                            label: "发作天数",
                            icon: "exclamationmark.circle.fill",
                            color: attackDays >= 15 ? .statusError : .accentPrimary
                        )
                        
                        CompactStatCard(
                            value: String(format: "%.1f", averageIntensity),
                            label: "平均强度",
                            icon: "waveform.path.ecg",
                            color: Color.painCategoryColor(for: Int(averageIntensity))
                        )
                    }
                    
                    // 第二行：急性用药（始终显示）
                    HStack(spacing: 12) {
                        CompactStatCard(
                            value: "\(stats.acuteMedicationCount)",
                            label: "急性用药次数",
                            icon: "pills.fill",
                            color: stats.acuteMedicationCount >= 10 ? .statusWarning : .accentPrimary
                        )
                        
                        CompactStatCard(
                            value: "\(stats.acuteMedicationDays)",
                            label: "急性用药天数",
                            icon: "calendar.badge.clock",
                            color: stats.acuteMedicationDays >= 10 ? .statusWarning : .accentPrimary
                        )
                    }
                    
                    // 第三行：预防性用药（有数据时显示）
                    if stats.hasPreventiveMedication {
                        HStack(spacing: 12) {
                            CompactStatCard(
                                value: "\(stats.preventiveMedicationCount)",
                                label: "预防性用药次数",
                                icon: "shield.fill",
                                color: Color.statusSuccess
                            )
                            
                            CompactStatCard(
                                value: "\(stats.preventiveMedicationDays)",
                                label: "预防性用药天数",
                                icon: "calendar.badge.plus",
                                color: Color.statusSuccess
                            )
                        }
                    }
                    
                    // 第四行：中医治疗和手术（有数据时显示）
                    if stats.hasTCMTreatment || stats.hasSurgery {
                        HStack(spacing: 12) {
                            if stats.hasTCMTreatment {
                                CompactStatCard(
                                    value: "\(stats.tcmTreatmentCount)",
                                    label: "中医治疗次数",
                                    icon: "leaf.circle.fill",
                                    color: Color.statusSuccess
                                )
                            }
                            
                            if stats.hasSurgery {
                                CompactStatCard(
                                    value: "\(stats.surgeryCount)",
                                    label: "手术次数",
                                    icon: "cross.case.circle.fill",
                                    color: Color.statusInfo
                                )
                            }
                            
                            // 如果只有一个统计项，添加占位符保持对齐
                            if stats.hasTCMTreatment && !stats.hasSurgery {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            } else if !stats.hasTCMTreatment && stats.hasSurgery {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 紧凑统计卡片

struct CompactStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            // 数值和标签
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - 简化的日历热力图

struct MiniCalendarHeatmap: View {
    let attacks: [AttackRecord]
    
    var body: some View {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)!.count
        
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(daysInMonth)
            
            HStack(spacing: 2) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
                    let dayAttacks = attacks.filter {
                        calendar.isDate($0.startTime, inSameDayAs: date)
                    }
                    
                    Rectangle()
                        .fill(cellColor(for: dayAttacks))
                        .frame(width: max(2, cellWidth - 2))
                        .cornerRadius(2)
                }
            }
            .frame(height: 60)
        }
    }
    
    private func cellColor(for attacks: [AttackRecord]) -> Color {
        guard !attacks.isEmpty else {
            return Color.backgroundSecondary
        }
        
        let maxIntensity = attacks.map(\.painIntensity).max() ?? 0
        return Color.painCategoryColor(for: maxIntensity).opacity(0.8)
    }
}

// MARK: - 通用时间轴行组件

struct CompactTimelineRow: View {
    let item: TimelineItemType
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标指示器
            leftIndicator
            
            // 中间内容
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                
                HStack(spacing: 8) {
                    detailsView
                }
            }
            
            Spacer()
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(12)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var leftIndicator: some View {
        switch item {
        case .attack(let attack):
            VStack(spacing: 4) {
                Text("\(attack.painIntensity)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.painCategoryColor(for: attack.painIntensity))
                
                Text("强度")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
            .frame(width: 56, height: 56)
            .background(Color.painCategoryColor(for: attack.painIntensity).opacity(0.15))
            .cornerRadius(12)
            
        case .healthEvent(let event):
            Image(systemName: event.eventType.icon)
                .font(.system(size: 24))
                .foregroundStyle(iconColor(for: event.eventType))
                .frame(width: 56, height: 56)
                .background(iconColor(for: event.eventType).opacity(0.15))
                .cornerRadius(12)
        }
    }
    
    private var titleText: String {
        switch item {
        case .attack(let attack):
            return attack.startTime.smartFormatted()
        case .healthEvent(let event):
            return event.displayTitle
        }
    }
    
    @ViewBuilder
    private var detailsView: some View {
        switch item {
        case .attack(let attack):
            if let duration = calculateDuration(attack) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(duration)
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            }
            
            if !attack.medications.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "pills")
                        .font(.caption2)
                    Text("\(attack.medications.count)次用药")
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            }
            
        case .healthEvent(let event):
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption2)
                Text(event.eventDate.smartFormatted())
            }
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            
            if let detail = event.displayDetail {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                    Text(detail)
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            }
        }
    }
    
    private func calculateDuration(_ attack: AttackRecord) -> String? {
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
    
    private func iconColor(for eventType: HealthEventType) -> Color {
        switch eventType {
        case .medication:
            return .accentPrimary
        case .tcmTreatment:
            return .statusSuccess
        case .surgery:
            return .statusInfo
        }
    }
}

// MARK: - 记录页面Sheet包装器

struct RecordingSheetView: View {
    let modelContext: ModelContext
    let weatherManager: WeatherManager
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    @State private var viewModel: RecordingViewModel
    @State private var showCancelAlert = false
    
    init(modelContext: ModelContext, weatherManager: WeatherManager, isPresented: Binding<Bool>, onDismiss: @escaping () -> Void) {
        self.modelContext = modelContext
        self.weatherManager = weatherManager
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self._viewModel = State(initialValue: RecordingViewModel(modelContext: modelContext, weatherManager: weatherManager))
    }
    
    var body: some View {
        NavigationStack {
            SimplifiedRecordingViewWrapper(
                viewModel: viewModel,
                modelContext: modelContext
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showCancelAlert = true
                    }
                }
            }
            .alert("确认取消", isPresented: $showCancelAlert) {
                Button("继续编辑", role: .cancel) {}
                Button("放弃记录", role: .destructive) {
                    handleCancel()
                }
            } message: {
                Text("取消后将不会保存任何信息")
            }
        }
        .onDisappear {
            onDismiss()
        }
    }
    
    private func handleCancel() {
        viewModel.cancelRecording()
        isPresented = false
    }
}

// MARK: - SimplifiedRecordingView 包装器

struct SimplifiedRecordingViewWrapper: View {
    @Bindable var viewModel: RecordingViewModel
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    // 展开/收起状态
    @State private var isPainExpanded = true
    @State private var isSymptomsExpanded = false
    @State private var isTriggersExpanded = false
    @State private var isMedicationsExpanded = false
    @State private var isNotesExpanded = false
    
    // 标签管理 Sheet 状态
    @State private var showPainQualityManager = false
    @State private var showSymptomManager = false
    
    // 天气管理状态
    @State private var showWeatherEditor = false
    
    // 查询症状标签和诱因标签
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "symptom" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var symptomLabels: [CustomLabelConfig]
    
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "trigger" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var triggerLabels: [CustomLabelConfig]
    
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "intervention" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var interventionLabels: [CustomLabelConfig]
    
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "aura" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var auraLabels: [CustomLabelConfig]
    
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "painQuality" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var painQualityLabels: [CustomLabelConfig]
    
    private var westernSymptoms: [CustomLabelConfig] {
        symptomLabels.filter { $0.subcategory == SymptomSubcategory.western.rawValue }
    }
    
    private var tcmSymptoms: [CustomLabelConfig] {
        symptomLabels.filter { $0.subcategory == SymptomSubcategory.tcm.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 内容区域
            ScrollView {
                VStack(spacing: 16) {
                    // 时间信息（始终显示）
                    timeSection
                    
                    // 天气信息卡片
                    WeatherCard(
                        weather: viewModel.currentWeatherSnapshot,
                        isLoading: viewModel.isLoadingWeather,
                        showTimeChangedWarning: viewModel.hasStartTimeChanged && !viewModel.isWeatherManuallyEdited,
                        onRefresh: {
                            Task {
                                await viewModel.refreshWeather()
                            }
                        },
                        onEdit: {
                            showWeatherEditor = true
                        },
                        onFetch: {
                            Task {
                                await viewModel.fetchWeatherForCurrentTime()
                            }
                        }
                    )
                    
                    // 疼痛评估（默认展开）
                    CollapsibleSection(
                        title: "疼痛评估",
                        icon: "waveform.path.ecg",
                        isExpandedByDefault: true
                    ) {
                        painAssessmentContent
                    }
                    
                    // 症状记录（可折叠，默认收起）
                    CollapsibleSection(
                        title: symptomsSectionTitle,
                        icon: "heart.text.square",
                        isExpandedByDefault: false
                    ) {
                        symptomsContent
                    }
                    
                    // 诱因分析（可折叠，默认收起）
                    CollapsibleSection(
                        title: triggersSectionTitle,
                        icon: "sparkles",
                        isExpandedByDefault: false
                    ) {
                        triggersContent
                    }
                    
                    // 用药记录（可折叠，默认收起）
                    CollapsibleSection(
                        title: medicationsSectionTitle,
                        icon: "pills.fill",
                        isExpandedByDefault: false
                    ) {
                        medicationsContent
                    }
                    
                    // 非药物干预（可折叠，默认收起）
                    CollapsibleSection(
                        title: nonPharmSectionTitle,
                        icon: "figure.mind.and.body",
                        isExpandedByDefault: false
                    ) {
                        nonPharmContent
                    }
                    
                    // 备注（可折叠，默认收起）
                    CollapsibleSection(
                        title: notesSectionTitle,
                        icon: "note.text",
                        isExpandedByDefault: false
                    ) {
                        notesContent
                    }
                    
                    // 保存提示
                    if !viewModel.canSave {
                        warningBanner
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(16)
            }
            
            // 底部保存按钮
            footerView
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startRecording()
            
            // 自动获取天气（如果还没有天气数据）
            if viewModel.currentWeatherSnapshot == nil {
                Task {
                    await viewModel.fetchWeatherForCurrentTime()
                }
            }
        }
        .onChange(of: viewModel.startTime) { oldValue, newValue in
            // 时间改变时，天气卡片会自动显示提示
            // hasStartTimeChanged 会自动更新
        }
        .sheet(isPresented: $showPainQualityManager) {
            NavigationStack {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showSymptomManager) {
            NavigationStack {
                LabelManagementView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showWeatherEditor) {
            WeatherEditSheet(
                isPresented: $showWeatherEditor,
                originalWeather: viewModel.currentWeatherSnapshot,
                onSave: { weather in
                    viewModel.updateWeatherSnapshot(weather)
                }
            )
        }
    }
    
    // MARK: - Section Titles with Summary
    
    private var symptomsSectionTitle: String {
        let count = viewModel.selectedSymptomNames.count + (viewModel.hasAura ? viewModel.selectedAuraTypeNames.count : 0)
        return count > 0 ? "症状记录 (\(count)项)" : "症状记录"
    }
    
    private var triggersSectionTitle: String {
        let count = viewModel.selectedTriggers.count
        return count > 0 ? "诱因分析 (\(count)项)" : "诱因分析"
    }
    
    private var medicationsSectionTitle: String {
        let count = viewModel.selectedMedications.count
        return count > 0 ? "用药记录 (\(count)项)" : "用药记录"
    }
    
    private var nonPharmSectionTitle: String {
        let count = viewModel.selectedNonPharmacological.count
        return count > 0 ? "非药物干预 (\(count)项)" : "非药物干预"
    }
    
    private var notesSectionTitle: String {
        return viewModel.notes.isEmpty ? "备注" : "备注 (已填写)"
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.title3)
                .foregroundStyle(Color.accentPrimary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("记录偏头痛发作")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                
                Text("所有字段均可选，随时保存")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.backgroundSecondary)
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 16) {
                // 开始时间
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("开始时间")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    DatePicker(
                        "",
                        selection: $viewModel.startTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }
                
                Divider()
                
                // 状态切换
                HStack(spacing: 12) {
                    Button {
                        viewModel.isOngoing = true
                        viewModel.endTime = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                            Text("进行中")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(viewModel.isOngoing ? .white : Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewModel.isOngoing ? Color.accentPrimary : Color.backgroundSecondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        viewModel.isOngoing = false
                        if viewModel.endTime == nil {
                            viewModel.endTime = Date()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.circle.fill")
                            Text("已结束")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(!viewModel.isOngoing ? .white : Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!viewModel.isOngoing ? Color.accentPrimary : Color.backgroundSecondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                // 结束时间（仅在已结束时显示）
                if !viewModel.isOngoing {
                    Divider()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "flag.checkered.circle.fill")
                            .foregroundStyle(Color.statusSuccess)
                        Text("结束时间")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { viewModel.endTime ?? Date() },
                                set: { viewModel.endTime = $0 }
                            ),
                            in: viewModel.startTime...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                    }
                }
            }
        }
    }
    
    // MARK: - Pain Assessment Content
    
    private var painAssessmentContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 疼痛强度
            VStack(spacing: 12) {
                HorizontalPainSlider(
                    value: $viewModel.selectedPainIntensity,
                    range: 0...10,
                    isDragging: .constant(false)
                )
            }
            
            Divider()
            
            // 疼痛部位
            VStack(alignment: .leading, spacing: 12) {
                Text("疼痛部位")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                
                HeadMapView(selectedLocations: $viewModel.selectedPainLocations)
            }
            
            Divider()
            
            // 疼痛性质
            VStack(alignment: .leading, spacing: 12) {
                Text("疼痛性质")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(painQualityLabels, id: \.id) { label in
                        SelectableChip(
                            label: label.displayName,
                            isSelected: Binding(
                                get: { viewModel.selectedPainQualityNames.contains(label.displayName) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedPainQualityNames.insert(label.displayName)
                                    } else {
                                        viewModel.selectedPainQualityNames.remove(label.displayName)
                                    }
                                }
                            )
                        )
                    }
                    
                    // 添加自定义疼痛性质
                    AddCustomLabelChip(
                        category: .painQuality,
                        subcategory: nil
                    ) { newLabel in
                        viewModel.selectedPainQualityNames.insert(newLabel)
                    }
                }
            }
        }
    }
    
    // MARK: - Symptoms Content
    
    private var symptomsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 先兆
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("是否有先兆？")
                        .font(.subheadline.weight(.medium))
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.hasAura)
                        .labelsHidden()
                }
                
                if viewModel.hasAura {
                    FlowLayout(spacing: 8) {
                        ForEach(auraLabels, id: \.id) { label in
                            SelectableChip(
                                label: label.displayName,
                                isSelected: Binding(
                                    get: { viewModel.selectedAuraTypeNames.contains(label.displayName) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedAuraTypeNames.insert(label.displayName)
                                        } else {
                                            viewModel.selectedAuraTypeNames.remove(label.displayName)
                                        }
                                    }
                                )
                            )
                        }
                        
                        // 添加自定义先兆类型
                        AddCustomLabelChip(
                            category: .aura,
                            subcategory: nil
                        ) { newLabel in
                            viewModel.selectedAuraTypeNames.insert(newLabel)
                        }
                    }
                }
            }
            
            Divider()
            
            // 西医症状
            VStack(alignment: .leading, spacing: 12) {
                Text("伴随症状")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(westernSymptoms, id: \.id) { label in
                        SelectableChip(
                            label: label.displayName,
                            isSelected: Binding(
                                get: { viewModel.selectedSymptomNames.contains(label.displayName) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedSymptomNames.insert(label.displayName)
                                    } else {
                                        viewModel.selectedSymptomNames.remove(label.displayName)
                                    }
                                }
                            )
                        )
                    }
                    
                    // 添加自定义症状
                    AddCustomLabelChip(
                        category: .symptom,
                        subcategory: SymptomSubcategory.western.rawValue
                    ) { newLabel in
                        viewModel.selectedSymptomNames.insert(newLabel)
                    }
                }
            }
            
            Divider()
            
            // 中医症状
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("中医症状")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                        .foregroundStyle(Color.statusSuccess)
                }
                
                FlowLayout(spacing: 8) {
                    ForEach(tcmSymptoms, id: \.id) { label in
                        SelectableChip(
                            label: label.displayName,
                            isSelected: Binding(
                                get: { viewModel.selectedSymptomNames.contains(label.displayName) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedSymptomNames.insert(label.displayName)
                                    } else {
                                        viewModel.selectedSymptomNames.remove(label.displayName)
                                    }
                                }
                            )
                        )
                    }
                    
                    // 添加自定义中医症状
                    AddCustomLabelChip(
                        category: .symptom,
                        subcategory: SymptomSubcategory.tcm.rawValue
                    ) { newLabel in
                        viewModel.selectedSymptomNames.insert(newLabel)
                    }
                }
            }
        }
    }
    
    // MARK: - Triggers Content
    
    private var triggersContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(TriggerCategory.allCases, id: \.self) { category in
                let categoryTriggers = triggerLabels.filter { $0.subcategory == category.rawValue }
                
                // 始终显示该区块，即使没有标签（用户可以添加自定义标签）
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text(categoryEmoji(for: category))
                            .font(.title3)
                        Text(category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    FlowLayout(spacing: 8) {
                        ForEach(categoryTriggers, id: \.id) { label in
                            SelectableChip(
                                label: label.displayName,
                                isSelected: Binding(
                                    get: { viewModel.selectedTriggers.contains(label.displayName) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedTriggers.append(label.displayName)
                                        } else {
                                            viewModel.selectedTriggers.removeAll { $0 == label.displayName }
                                        }
                                    }
                                )
                            )
                        }
                        
                        // 添加自定义诱因
                        AddCustomLabelChip(
                            category: .trigger,
                            subcategory: category.rawValue
                        ) { newLabel in
                            viewModel.selectedTriggers.append(newLabel)
                        }
                    }
                }
                
                if category != TriggerCategory.allCases.last {
                    Divider()
                }
            }
        }
    }
    
    // MARK: - Medications Content
    
    @State private var showAddMedicationSheet = false
    
    private var medicationsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 添加按钮
            Button {
                showAddMedicationSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("添加用药")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentPrimary.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showAddMedicationSheet) {
                UnifiedMedicationInputSheet(viewModel: viewModel, isPresented: $showAddMedicationSheet)
            }
            
            // 已添加的药物
            if !viewModel.selectedMedications.isEmpty {
                Divider()
                
                ForEach(Array(viewModel.selectedMedications.enumerated()), id: \.offset) { index, medInfo in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(medInfo.medication?.name ?? medInfo.customName ?? "未知药物")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.textPrimary)
                            Text("\(String(format: "%.0f", medInfo.dosage))\(medInfo.medication?.unit ?? medInfo.unit) - \(medInfo.timeTaken.shortTime())")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        Button {
                            viewModel.removeMedication(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.statusDanger)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if index < viewModel.selectedMedications.count - 1 {
                        Divider()
                    }
                }
            } else {
                Text("未记录用药")
                    .font(.subheadline)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }
    
    // MARK: - Non-Pharm Content
    
    private var nonPharmContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(interventionLabels, id: \.id) { label in
                    SelectableChip(
                        label: label.displayName,
                        isSelected: Binding(
                            get: { viewModel.selectedNonPharmacological.contains(label.displayName) },
                            set: { isSelected in
                                if isSelected {
                                    viewModel.selectedNonPharmacological.insert(label.displayName)
                                } else {
                                    viewModel.selectedNonPharmacological.remove(label.displayName)
                                }
                            }
                        )
                    )
                }
                
                // 添加自定义非药物干预
                AddCustomLabelChip(
                    category: .intervention,
                    subcategory: nil
                ) { newLabel in
                    viewModel.selectedNonPharmacological.insert(newLabel)
                }
            }
        }
    }
    
    // MARK: - Notes Content
    
    private var notesContent: some View {
        TextEditor(text: $viewModel.notes)
            .frame(height: 100)
            .padding(8)
            .background(Color.backgroundTertiary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.divider, lineWidth: 1)
            )
    }
    
    // MARK: - Warning Banner
    
    private var warningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.statusInfo)
            Text("建议填写疼痛强度和部位以获得更准确的分析")
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusInfo.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        VStack(spacing: 0) {
            Divider()
            
            PrimaryButton(
                title: "完成记录",
                action: {
                    saveAndDismiss()
                },
                isEnabled: true  // 总是可以保存
            )
            .padding(16)
        }
        .background(Color.backgroundSecondary)
    }
    
    // MARK: - Helpers
    
    private func categoryEmoji(for category: TriggerCategory) -> String {
        switch category {
        case .food: return "🍜"
        case .environment: return "🌦️"
        case .sleep: return "😴"
        case .stress: return "💼"
        case .hormone: return "🌸"
        case .lifestyle: return "🏃"
        case .tcm: return "🌿"
        }
    }
    
    // 带标签管理按钮的章节标题
    private func sectionTitleWithManageButton(
        title: String,
        showSheet: Binding<Bool>
    ) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textSecondary)
            
            Spacer()
            
            Button {
                showSheet.wrappedValue = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.caption)
                    Text("管理")
                        .font(.caption)
                }
                .foregroundStyle(Color.accentPrimary)
            }
        }
    }
    
    
    private func saveAndDismiss() {
        Task {
            do {
                try await viewModel.saveRecording()
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    AppToastManager.shared.showSuccess("记录保存成功")
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    AppToastManager.shared.showError("保存失败，请重试")
                }
            }
        }
    }
    
}

#Preview {
    HomeView()
        .modelContainer(for: [AttackRecord.self], inMemory: true)
}

