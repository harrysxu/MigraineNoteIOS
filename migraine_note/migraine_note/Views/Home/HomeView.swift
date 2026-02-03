//
//  HomeView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel?
    @State private var weatherManager = WeatherManager()
    @State private var showRecordingView = false
    @State private var selectedTab: Int?
    @State private var selectedAttackForDetail: AttackRecord?
    @State private var selectedAttackForEdit: AttackRecord?
    @State private var toastManager = ToastManager()
    @State private var showQuickRecordSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if let vm = viewModel {
                        // 1. 连续无头痛天数（大数值显示）
                        if let attack = vm.ongoingAttack {
                            // 发作进行中状态
                            OngoingAttackView(attack: attack)
                                .padding(.horizontal, Spacing.pageHorizontal)
                        } else {
                            // 无头痛状态
                            LargeNumberDisplay(
                                value: "\(vm.streakDays)",
                                label: "连续无头痛天数",
                                unit: "天"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xl)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(CornerRadius.lg)
                            .padding(.horizontal, Spacing.pageHorizontal)
                        }
                        
                        // 2. 超大快速记录按钮
                        QuickRecordButton {
                            if let attack = vm.ongoingAttack {
                                // 有进行中的记录，打开编辑界面
                                selectedAttackForEdit = attack
                            } else {
                                // 没有进行中的记录，执行快速记录
                                performQuickRecord()
                            }
                        }
                        .padding(.horizontal, Spacing.pageHorizontal)
                        
                        // 3. 本月概览
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("本月概览")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.labelPrimary)
                            
                            ThreeColumnStat(
                                stat1: ("\(monthlyAttackDays(vm.recentAttacks))天", "发作天数"),
                                stat2: (String(format: "%.1f/10", averageIntensity(vm.recentAttacks)), "平均强度"),
                                stat3: ("\(medicationCount(vm.recentAttacks))次", "用药次数")
                            )
                        }
                        .padding(.horizontal, Spacing.pageHorizontal)
                        
                        // 4. 最近记录列表
                        if !vm.recentAttacks.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack {
                                    Text("最近记录")
                                        .font(.title3.weight(.semibold))
                                        .foregroundColor(.labelPrimary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("SwitchToRecordListTab"),
                                            object: nil
                                        )
                                    } label: {
                                        Text("查看全部")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                VStack(spacing: 0) {
                                    ForEach(Array(vm.recentAttacks.prefix(3).enumerated()), id: \.element.id) { index, attack in
                                        MinimalAttackRow(attack: attack)
                                            .onTapGesture {
                                                selectedAttackForDetail = attack
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    deleteAttack(attack)
                                                } label: {
                                                    Label("删除", systemImage: "trash")
                                                }
                                            }
                                        
                                        if index < vm.recentAttacks.prefix(3).count - 1 {
                                            Divider()
                                                .padding(.leading, Spacing.pageHorizontal)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.pageHorizontal)
                        }
                    } else {
                        ProgressView()
                            .tint(Color.primary)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                    }
                    
                    Spacer(minLength: 80)
                }
                .padding(.vertical, Spacing.pageTop)
            }
            .navigationTitle("头痛记录")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .refreshable {
                viewModel?.refreshData()
            }
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
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(modelContext: modelContext, weatherManager: weatherManager)
            }
        }
        .toast(
            isPresented: $toastManager.isPresented,
            config: toastManager.config ?? ToastConfig(message: "")
        )
    }
    
    // MARK: - 快速记录
    
    private func performQuickRecord() {
        guard let vm = viewModel else { return }
        
        // 执行快速记录
        _ = vm.quickStartRecording()
        
        // 触觉反馈
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // 显示Toast提示
        toastManager.show(
            message: "已记录 \(formatTime(Date()))，稍后可补充详情",
            type: .success,
            duration: 2.5
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Methods
    
    private func deleteAttack(_ attack: AttackRecord) {
        modelContext.delete(attack)
        do {
            try modelContext.save()
            viewModel?.refreshData()
        } catch {
            print("删除失败: \(error)")
        }
    }
    
    // MARK: - 统计计算
    
    private func monthlyAttackDays(_ attacks: [AttackRecord]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthlyAttacks = attacks.filter { $0.startTime >= startOfMonth }
        let uniqueDays = Set(monthlyAttacks.map { calendar.startOfDay(for: $0.startTime) })
        return uniqueDays.count
    }
    
    private func averageIntensity(_ attacks: [AttackRecord]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthlyAttacks = attacks.filter { $0.startTime >= startOfMonth }
        guard !monthlyAttacks.isEmpty else { return 0 }
        
        let total = monthlyAttacks.reduce(0) { $0 + $1.painIntensity }
        return Double(total) / Double(monthlyAttacks.count)
    }
    
    private func medicationCount(_ attacks: [AttackRecord]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthlyAttacks = attacks.filter { $0.startTime >= startOfMonth }
        return monthlyAttacks.filter { !$0.medications.isEmpty }.count
    }
}

// MARK: - 发作进行中视图

struct OngoingAttackView: View {
    let attack: AttackRecord
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.warning)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("发作进行中")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.labelPrimary)
                    
                    Text("已持续 \(formatDuration(attack.startTime))")
                        .font(.subheadline)
                        .foregroundColor(.labelSecondary)
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.md)
        .background(Color.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("发作进行中，已持续\(formatDuration(attack.startTime))")
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

// MARK: - 极简记录行

struct MinimalAttackRow: View {
    let attack: AttackRecord
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // 左侧：疼痛强度
            Text("\(attack.painIntensity)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.painIntensityColor(for: attack.painIntensity))
                .frame(width: 44, height: 44)
                .background(Color.painIntensityColor(for: attack.painIntensity).opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            
            // 中间：信息
            VStack(alignment: .leading, spacing: 4) {
                Text(attack.startTime.smartFormatted())
                    .font(.body.weight(.medium))
                    .foregroundColor(.labelPrimary)
                
                HStack(spacing: Spacing.xs) {
                    if let duration = calculateDuration() {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(duration)
                        }
                        .font(.caption)
                        .foregroundColor(.labelSecondary)
                    }
                    
                    if !attack.medications.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "pills")
                                .font(.caption2)
                            Text("已用药")
                        }
                        .font(.caption)
                        .foregroundColor(.labelSecondary)
                    }
                }
            }
            
            Spacer()
            
            // 右侧：箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.labelTertiary)
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("疼痛强度\(attack.painIntensity)，\(attack.startTime.smartFormatted())，\(calculateDuration() ?? "")")
    }
    
    private func calculateDuration() -> String? {
        guard let endTime = attack.endTime else { return nil }
        let duration = endTime.timeIntervalSince(attack.startTime)
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if minutes > 0 {
            return "\(minutes)分钟"
        } else {
            return nil
        }
    }
}

// 装饰性组件已移除，采用医疗极简主义设计

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
    
    // 查询症状标签和诱因标签
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "symptom" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var symptomLabels: [CustomLabelConfig]
    
    @Query(filter: #Predicate<CustomLabelConfig> { 
        $0.category == "trigger" && $0.isHidden == false 
    }, sort: \CustomLabelConfig.sortOrder)
    private var triggerLabels: [CustomLabelConfig]
    
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
                    
                    // 疼痛评估（默认展开）
                    CollapsibleSection(
                        title: "疼痛评估",
                        icon: "waveform.path.ecg",
                        isExpandedByDefault: true
                    ) {
                        painAssessmentContent
                    }
                    
                    // 症状记录（可折叠）
                    CollapsibleSection(
                        title: "症状记录",
                        icon: "heart.text.square",
                        isExpandedByDefault: true
                    ) {
                        symptomsContent
                    }
                    
                    // 诱因分析（可折叠）
                    CollapsibleSection(
                        title: "诱因分析",
                        icon: "sparkles",
                        isExpandedByDefault: true
                    ) {
                        triggersContent
                    }
                    
                    // 用药记录（可折叠）
                    CollapsibleSection(
                        title: "用药记录",
                        icon: "pills.fill",
                        isExpandedByDefault: true
                    ) {
                        medicationsContent
                    }
                    
                    // 非药物干预（可折叠）
                    CollapsibleSection(
                        title: "非药物干预",
                        icon: "figure.mind.and.body",
                        isExpandedByDefault: true
                    ) {
                        nonPharmContent
                    }
                    
                    // 备注（可折叠）
                    CollapsibleSection(
                        title: "备注",
                        icon: "note.text",
                        isExpandedByDefault: true
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
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.title3)
                .foregroundStyle(Color.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("记录偏头痛发作")
                    .font(.headline)
                    .foregroundStyle(Color.labelPrimary)
                
                Text("所有字段均可选，随时保存")
                    .font(.caption)
                    .foregroundStyle(Color.labelSecondary)
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
                        .foregroundStyle(Color.primary)
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
                        .foregroundStyle(viewModel.isOngoing ? .white : Color.labelPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(viewModel.isOngoing ? Color.primary : Color.backgroundSecondary)
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
                        .foregroundStyle(!viewModel.isOngoing ? .white : Color.labelPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(!viewModel.isOngoing ? Color.primary : Color.backgroundSecondary)
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
                    .foregroundStyle(Color.labelSecondary)
                
                HeadMapView(selectedLocations: $viewModel.selectedPainLocations)
            }
            
            Divider()
            
            // 疼痛性质
            VStack(alignment: .leading, spacing: 12) {
                Text("疼痛性质")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.labelSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(PainQuality.allCases, id: \.self) { quality in
                        SelectableChip(
                            label: quality.rawValue,
                            isSelected: Binding(
                                get: { viewModel.selectedPainQualities.contains(quality) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedPainQualities.insert(quality)
                                    } else {
                                        viewModel.selectedPainQualities.remove(quality)
                                    }
                                }
                            )
                        )
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
                        ForEach(AuraType.allCases, id: \.self) { aura in
                            SelectableChip(
                                label: aura.rawValue,
                                isSelected: Binding(
                                    get: { viewModel.selectedAuraTypes.contains(aura) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedAuraTypes.insert(aura)
                                        } else {
                                            viewModel.selectedAuraTypes.remove(aura)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }
            
            Divider()
            
            // 西医症状
            VStack(alignment: .leading, spacing: 12) {
                Text("伴随症状")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.labelSecondary)
                
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
                        .foregroundStyle(Color.labelSecondary)
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
                }
            }
        }
    }
    
    // MARK: - Triggers Content
    
    private var triggersContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(TriggerCategory.allCases, id: \.self) { category in
                let categoryTriggers = triggerLabels.filter { $0.subcategory == category.rawValue }
                
                if !categoryTriggers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text(categoryEmoji(for: category))
                                .font(.title3)
                            Text(category.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.labelSecondary)
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
                        }
                    }
                    
                    if category != TriggerCategory.allCases.last {
                        Divider()
                    }
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
                        .foregroundStyle(Color.primary)
                    Text("添加用药")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.1))
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
                            Text(medInfo.medication?.name ?? "未知药物")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.labelPrimary)
                            Text("\(String(format: "%.0f", medInfo.dosage))\(medInfo.medication?.unit ?? "mg") - \(medInfo.timeTaken.shortTime())")
                                .font(.caption)
                                .foregroundStyle(Color.labelSecondary)
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
                    .foregroundStyle(Color.labelTertiary)
            }
        }
    }
    
    // MARK: - Non-Pharm Content
    
    private var nonPharmContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(nonPharmacologicalOptions, id: \.self) { option in
                    SelectableChip(
                        label: option,
                        isSelected: Binding(
                            get: { viewModel.selectedNonPharmacological.contains(option) },
                            set: { isSelected in
                                if isSelected {
                                    viewModel.selectedNonPharmacological.insert(option)
                                } else {
                                    viewModel.selectedNonPharmacological.remove(option)
                                }
                            }
                        )
                    )
                }
                
                // 自定义非药物干预
                ForEach(viewModel.customNonPharmacological, id: \.self) { custom in
                    SelectableChip(
                        label: custom,
                        isSelected: .constant(true)
                    )
                    .overlay(
                        Button {
                            viewModel.customNonPharmacological.removeAll { $0 == custom }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.labelSecondary)
                        }
                        .offset(x: 8, y: -8),
                        alignment: .topTrailing
                    )
                }
                
                CompactCustomInputField(placeholder: "其他方法...") { text in
                    if !viewModel.customNonPharmacological.contains(text) {
                        viewModel.customNonPharmacological.append(text)
                    }
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
                    .stroke(Color.separator, lineWidth: 1)
            )
    }
    
    // MARK: - Warning Banner
    
    private var warningBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.statusInfo)
            Text("建议填写疼痛强度和部位以获得更准确的分析")
                .font(.subheadline)
                .foregroundStyle(Color.labelPrimary)
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
                isEnabled: true  // 总是可以保存
            ) {
                saveAndDismiss()
            }
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
                .foregroundStyle(Color.labelSecondary)
            
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
                .foregroundStyle(Color.primary)
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
                    dismiss()
                }
            } catch {
                print("保存失败: \(error)")
            }
        }
    }
    
    private let nonPharmacologicalOptions = [
        "睡眠", "冷敷", "热敷", "按摩", "针灸", "暗室休息", "深呼吸", "冥想"
    ]
}

#Preview {
    HomeView()
        .modelContainer(for: [AttackRecord.self], inMemory: true)
}

