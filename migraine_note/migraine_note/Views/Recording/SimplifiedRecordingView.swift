//
//  SimplifiedRecordingView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 简化的单页记录视图 - 所有模块在同一页面，无需分步
struct SimplifiedRecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecordingViewModel
    
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
    
    let isEditMode: Bool
    let existingAttack: AttackRecord?
    let onCancel: (() -> Void)?
    
    // 展开/收起状态
    @State private var isPainExpanded = true
    @State private var isSymptomsExpanded = false
    @State private var isTriggersExpanded = false
    @State private var isMedicationsExpanded = false
    @State private var isNotesExpanded = false
    
    // 标签管理 Sheet 状态
    @State private var showPainQualityManager = false
    @State private var showSymptomManager = false
    
    init(modelContext: ModelContext, existingAttack: AttackRecord? = nil, onCancel: (() -> Void)? = nil) {
        self.isEditMode = existingAttack != nil
        self.existingAttack = existingAttack
        self.onCancel = onCancel
        
        if let attack = existingAttack {
            let vm = RecordingViewModel(modelContext: modelContext, editingAttack: attack)
            _viewModel = State(initialValue: vm)
        } else {
            _viewModel = State(initialValue: RecordingViewModel(modelContext: modelContext))
        }
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
        .navigationTitle(isEditMode ? "编辑记录" : "记录详情")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(true) // 禁用下滑关闭,强制使用取消按钮
        .onAppear {
            if let attack = existingAttack {
                viewModel.loadExistingAttack(attack)
            } else if !isEditMode {
                viewModel.startRecording()
            }
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
                CircularSlider(
                    value: $viewModel.selectedPainIntensity,
                    range: 0...10,
                    isDragging: .constant(false)
                )
                .frame(height: 200)
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
                sectionTitleWithManageButton(
                    title: "疼痛性质",
                    showSheet: $showPainQualityManager
                )
                
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
                sectionTitleWithManageButton(
                    title: "伴随症状",
                    showSheet: $showSymptomManager
                )
                
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
                            Text("\(String(format: "%.0f", medInfo.dosage))\(medInfo.unit) - \(medInfo.timeTaken.shortTime())")
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
                                .foregroundStyle(Color.textSecondary)
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
                title: isEditMode ? "保存" : "完成记录",
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
        do {
            try viewModel.saveRecording()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    func handleCancel() {
        viewModel.cancelRecording()
        onCancel?()
    }
    
    private let nonPharmacologicalOptions = [
        "睡眠", "冷敷", "热敷", "按摩", "针灸", "暗室休息", "深呼吸", "冥想"
    ]
}

#Preview {
    struct PreviewContainer: View {
        @Query private var attacks: [AttackRecord]
        @Environment(\.modelContext) private var modelContext
        
        var body: some View {
            NavigationStack {
                SimplifiedRecordingView(modelContext: modelContext)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") {}
                        }
                    }
            }
        }
    }
    
    return PreviewContainer()
        .modelContainer(for: [AttackRecord.self], inMemory: true)
}
