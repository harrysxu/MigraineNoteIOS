//
//  ProfileView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 我的页面 - 整合药箱管理和设置功能
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var medications: [Medication]
    // 移除了 @Query 全量加载 attacks/healthEvents/medicationLogs
    // 改为按需查询当月数据，大幅降低内存占用
    
    @State private var cloudKitManager = CloudKitManager()
    @State private var showClearDataFirstConfirm = false
    @State private var showClearDataFinalConfirm = false
    @State private var showClearDataSuccess = false
    @State private var isClearingData = false
    @State private var cachedMonthlyMedDays: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // 药箱快速入口
                    medicationSummaryCard
                    
                    // 设置功能区域
                    settingsSections
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            cloudKitManager.checkICloudStatus()
            loadMonthlyMedicationDays()
        }
        .alert("确认清空数据", isPresented: $showClearDataFirstConfirm) {
            Button("取消", role: .cancel) { }
            Button("继续", role: .destructive) {
                showClearDataFinalConfirm = true
            }
        } message: {
            Text("此操作将删除所有发作记录、药物数据、健康事件、自定义标签和用户档案等全部信息。")
        }
        .alert("⚠️ 最终确认", isPresented: $showClearDataFinalConfirm) {
            Button("取消", role: .cancel) { }
            Button("永久删除所有数据", role: .destructive) {
                performClearAllData()
            }
        } message: {
            Text("此操作不可撤销！删除后数据将无法恢复，包括已同步到 iCloud 的数据也会被删除。请确认您已了解此操作的后果。")
        }
        .alert("数据已清空", isPresented: $showClearDataSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("所有数据已被永久删除。")
        }
    }
    
    // MARK: - 药箱摘要卡片
    
    private var medicationSummaryCard: some View {
        NavigationLink {
            MedicationListView()
        } label: {
            EmotionalCard(style: mohRisk != .none ? .warning : .default) {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题行
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "cross.case.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.accentPrimary)
                                .clipShape(Circle())
                            
                            Text("药箱管理")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    
                    // 统计卡片网格 - 2x1
                    HStack(spacing: 12) {
                        // 药物总数卡片
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "pill.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentPrimary)
                                Text("药物总数")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            
                            Text("\(medications.count)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.backgroundPrimary)
                        .cornerRadius(12)
                        
                        // 用药天数卡片
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(mohRisk != .none ? Color.statusWarning : Color.accentPrimary)
                                Text("本月急性用药")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(monthlyMedicationDays)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(mohRisk != .none ? Color.statusWarning : Color.textPrimary)
                                Text("天")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(mohRisk != .none ? Color.statusWarning.opacity(0.1) : Color.backgroundPrimary)
                        .cornerRadius(12)
                    }
                    
                    // MOH风险提示
                    if mohRisk != .none {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(mohRiskColor)
                            Text(mohRiskMessage)
                                .font(.caption)
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(mohRiskColor.opacity(0.15))
                        .cornerRadius(10)
                    }
                    
                    // 库存预警
                    if lowInventoryCount > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.statusWarning)
                            Text("\(lowInventoryCount)种药物库存不足")
                                .font(.caption)
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.statusWarning.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 设置功能区域
    
    private var settingsSections: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // 外观设置
            EmotionalCard(style: .default) {
                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: themeManager.currentTheme.icon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.accentPrimary)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("主题设置")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.textPrimary)
                            
                            Text(themeManager.currentTheme.rawValue)
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 数据与隐私
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("数据与隐私")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Spacing.sm)
                    
                    NavigationLink {
                        LocationSettingsView()
                    } label: {
                        SettingRow(
                            icon: "location.fill",
                            iconColor: .blue,
                            title: "位置服务"
                        )
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 44)
                    
                    NavigationLink {
                        CloudSyncSettingsView()
                    } label: {
                        SettingRow(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "iCloud 同步"
                        )
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 44)
                    
                    NavigationLink {
                        DataExportView()
                    } label: {
                        SettingRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .green,
                            title: "数据导出"
                        )
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 44)
                    
                    Button {
                        showClearDataFirstConfirm = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.red)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("清空所有数据")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.red)
                                
                                Text("删除后无法恢复")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                            
                            Spacer()
                            
                            if isClearingData {
                                ProgressView()
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isClearingData)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 功能设置
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("功能设置")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Spacing.sm)
                    
                    NavigationLink {
                        LabelManagementView()
                    } label: {
                        SettingRow(
                            icon: "tag.fill",
                            iconColor: .blue,
                            title: "标签管理"
                        )
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 44)
                    
                    NavigationLink {
                        FeatureSettingsView()
                    } label: {
                        SettingRow(
                            icon: "slider.horizontal.3",
                            iconColor: .purple,
                            title: "个性化配置"
                        )
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 44)
                    
                    NavigationLink {
                        MedicationReminderView()
                    } label: {
                        SettingRow(
                            icon: "bell.badge.fill",
                            iconColor: .orange,
                            title: "用药提醒"
                        )
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 关于
            EmotionalCard(style: .default) {
                NavigationLink {
                    AboutView()
                } label: {
                    SettingRow(
                        icon: "info.circle.fill",
                        iconColor: .gray,
                        title: "关于应用"
                    )
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 清空数据
    
    private func performClearAllData() {
        isClearingData = true
        
        do {
            // 使用批量删除，更可靠且高效
            // 先删除子实体（避免级联问题）
            try modelContext.delete(model: Symptom.self)
            try modelContext.delete(model: Trigger.self)
            try modelContext.delete(model: WeatherSnapshot.self)
            try modelContext.delete(model: MedicationLog.self)
            
            // 再删除主实体
            try modelContext.delete(model: AttackRecord.self)
            try modelContext.delete(model: HealthEvent.self)
            try modelContext.delete(model: Medication.self)
            try modelContext.delete(model: CustomLabelConfig.self)
            try modelContext.delete(model: UserProfile.self)
            
            try modelContext.save()
            
            // 通知其他页面刷新数据（如首页）
            NotificationCenter.default.post(name: .allDataCleared, object: nil)
            
            showClearDataSuccess = true
        } catch {
            print("清空数据失败: \(error)")
        }
        
        isClearingData = false
    }
    
    // MARK: - 辅助计算属性
    
    /// 本月急性用药天数（按需查询，仅获取当月数据）
    private var monthlyMedicationDays: Int {
        cachedMonthlyMedDays
    }
    
    /// 从 CoreData 按需加载当月用药统计（避免全量 @Query）
    private func loadMonthlyMedicationDays() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextMonth)!
        
        let attackDescriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startOfMonth && attack.startTime <= endOfMonth
            }
        )
        let eventDescriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startOfMonth && event.eventDate <= endOfMonth
            }
        )
        
        let monthAttacks = (try? modelContext.fetch(attackDescriptor)) ?? []
        let monthEvents = (try? modelContext.fetch(eventDescriptor)) ?? []
        
        let stats = DetailedMedicationStatistics.calculate(
            attacks: monthAttacks,
            healthEvents: monthEvents,
            dateRange: (startOfMonth, endOfMonth)
        )
        
        cachedMonthlyMedDays = stats.acuteMedicationDays
    }
    
    /// MOH风险等级
    private var mohRisk: MOHRiskLevel {
        let days = monthlyMedicationDays
        if days >= 15 {
            return .high
        } else if days >= 10 {
            return .medium
        } else if days >= 8 {
            return .low
        }
        return .none
    }
    
    /// MOH风险颜色
    private var mohRiskColor: Color {
        switch mohRisk {
        case .none:
            return .clear
        case .low:
            return .statusWarning
        case .medium:
            return .statusWarning
        case .high:
            return .statusError
        }
    }
    
    /// MOH风险提示文字
    private var mohRiskMessage: String {
        switch mohRisk {
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
    
    /// 库存不足的药物数量
    private var lowInventoryCount: Int {
        medications.filter { $0.inventory > 0 && $0.inventory <= 5 }.count
    }
}

// MARK: - 通知名称

extension Notification.Name {
    /// 所有数据已被清空的通知
    static let allDataCleared = Notification.Name("com.migrainenote.allDataCleared")
}

// MARK: - Preview

#Preview {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Medication.self, MedicationLog.self,
            configurations: config
        )
        
        let context = container.mainContext
        
        // 创建测试药物
        for i in 1...3 {
            let med = Medication(
                name: "测试药物\(i)",
                category: i == 1 ? .nsaid : .triptan,
                isAcute: true
            )
            med.inventory = i * 10
            context.insert(med)
        }
        
        return container
    }()
    
    ProfileView()
        .modelContainer(container)
}
