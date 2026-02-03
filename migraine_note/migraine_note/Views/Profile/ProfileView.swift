//
//  ProfileView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData
import HealthKit

/// 我的页面 - 整合药箱管理和设置功能
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var medications: [Medication]
    @Query private var medicationLogs: [MedicationLog]
    
    @State private var cloudKitManager = CloudKitManager()
    
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
                                Text("本月用药")
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
                        HealthKitSettingsView()
                    } label: {
                        SettingRow(
                            icon: "heart.fill",
                            iconColor: .red,
                            title: "健康数据"
                        )
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 44)
                    
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
            
            #if DEBUG
            // 测试与调试（仅 Debug 模式）
            EmotionalCard(style: .warning) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("测试与调试")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, Spacing.sm)
                    
                    NavigationLink {
                        TestDataView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "hammer.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.statusWarning)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("测试数据")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.textPrimary)
                                    
                                    Text("DEBUG")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.statusWarning)
                                        .cornerRadius(4)
                                }
                                
                                Text("生成和管理测试数据")
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 辅助计算属性
    
    /// 本月用药天数
    private var monthlyMedicationDays: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthlyLogs = medicationLogs.filter { log in
            log.takenAt >= startOfMonth
        }
        
        let uniqueDays = Set(monthlyLogs.map { log in
            calendar.startOfDay(for: log.takenAt)
        })
        
        return uniqueDays.count
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
