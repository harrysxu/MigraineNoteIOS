import SwiftUI
import SwiftData

/// 设置页面
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        NavigationStack {
            List {
                // 外观设置
                Section {
                    NavigationLink {
                        ThemeSettingsView()
                    } label: {
                        SettingRow(
                            icon: themeManager.currentTheme.icon,
                            iconColor: Color.accentPrimary,
                            title: "主题设置",
                            subtitle: themeManager.currentTheme.rawValue
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("外观")
                }
                
                // 数据与隐私
                Section {
                    NavigationLink {
                        LocationSettingsView()
                    } label: {
                        SettingRow(
                            icon: "location.fill",
                            iconColor: .blue,
                            title: "位置服务",
                            subtitle: "追踪天气诱因"
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        CloudSyncSettingsView()
                    } label: {
                        SettingRow(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "iCloud 同步",
                            subtitle: "多设备协同"
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("数据与隐私")
                } footer: {
                    Text("所有数据存储在您的iCloud私有数据库，仅您本人可访问。")
                }
                
                // 功能设置
                Section {
                    NavigationLink {
                        LabelManagementView()
                    } label: {
                        SettingRow(
                            icon: "tag.fill",
                            iconColor: Color.accentPrimary,
                            title: "标签管理",
                            subtitle: "自定义症状、诱因、药物标签"
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        FeatureSettingsView()
                    } label: {
                        SettingRow(
                            icon: "slider.horizontal.3",
                            iconColor: .purple,
                            title: "个性化配置",
                            subtitle: "定制专属体验"
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("功能设置")
                }
                
                // 关于
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingRow(
                            icon: "info.circle.fill",
                            iconColor: .gray,
                            title: "关于应用",
                            subtitle: "版本与帮助"
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - 设置行组件

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(AppColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - 位置服务设置

struct LocationSettingsView: View {
    @State private var weatherManager = WeatherManager()
    
    var body: some View {
        List {
            Section {
                InfoCard {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("位置服务")
                            .font(.headline)
                            .foregroundColor(Color.accentPrimary)
                        Text("允许访问位置信息以获取天气数据，帮助分析环境诱因。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("功能说明") {
                Label("记录发作时的天气状况", systemImage: "cloud.sun.fill")
                Label("气压变化趋势分析", systemImage: "gauge.high")
                Label("湿度和温度追踪", systemImage: "thermometer.medium")
            }
            
            Section {
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label("打开系统设置", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("位置服务")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - CloudKit同步设置

struct CloudSyncSettingsView: View {
    @State private var cloudKitManager = CloudKitManager()
    @State private var syncSettingsManager = SyncSettingsManager.shared
    @State private var showRestartAlert = false
    
    var body: some View {
        List {
            // 同步开关
            Section {
                Toggle(isOn: $syncSettingsManager.isSyncEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("启用iCloud同步")
                            .font(.body)
                        Text("关闭后数据仅保存在本地设备")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(Color.accentPrimary)
            } footer: {
                Text("更改此设置后需要重启应用才能生效")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            // 同步状态卡片
            Section {
                HStack(spacing: AppSpacing.medium) {
                    Image(systemName: cloudKitManager.syncStatus.icon)
                        .font(.title2)
                        .foregroundStyle(cloudKitManager.syncStatus.color)
                        .frame(width: 44, height: 44)
                        .background(cloudKitManager.syncStatus.color.opacity(0.15))
                        .cornerRadius(AppSpacing.cornerRadiusSmall)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cloudKitManager.syncStatus.displayText)
                            .font(.headline)
                        
                        if cloudKitManager.syncStatus == .disabled {
                            Text("数据仅保存在本地设备")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if cloudKitManager.isICloudAvailable {
                            Text("数据正在自动同步")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("请在系统设置中登录iCloud")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, AppSpacing.small)
            }
            
            // 最后同步时间
            if let lastSync = cloudKitManager.lastSyncDate {
                Section {
                    HStack {
                        Text("最后同步")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            // 同步功能说明
            Section {
                InfoCard {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("iCloud同步")
                            .font(.headline)
                            .foregroundColor(Color.accentPrimary)
                        Text("您的所有数据通过iCloud自动同步到您的所有Apple设备，并保存在您的私有数据库中。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("同步说明") {
                Label("自动跨设备同步", systemImage: "icloud.fill")
                Label("端到端加密", systemImage: "lock.shield.fill")
                Label("私有数据库存储", systemImage: "externaldrive.fill.badge.person.crop")
                Label("离线优先设计", systemImage: "wifi.slash")
            }
            
            Section("隐私保护") {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("✓ 数据仅存储在您的iCloud账户")
                        .font(.caption)
                    Text("✓ 开发者无法访问您的数据")
                        .font(.caption)
                    Text("✓ 未经授权的第三方无法访问")
                        .font(.caption)
                    Text("✓ 符合医疗数据隐私要求")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            // 操作按钮
            if !cloudKitManager.isICloudAvailable {
                Section {
                    Button {
                        openSystemSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("打开系统设置")
                        }
                    }
                }
            }
        }
        .navigationTitle("iCloud同步")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cloudKitManager.checkICloudStatus()
        }
        .refreshable {
            cloudKitManager.checkICloudStatus()
        }
        .onChange(of: syncSettingsManager.isSyncEnabled) { oldValue, newValue in
            if oldValue != newValue {
                showRestartAlert = true
                // 更新同步状态显示
                cloudKitManager.checkICloudStatus()
            }
        }
        .alert("需要重启应用", isPresented: $showRestartAlert) {
            Button("稍后", role: .cancel) { }
            Button("立即重启") {
                // 退出应用，用户需要手动重启
                exit(0)
            }
        } message: {
            Text("更改同步设置后需要重启应用才能生效。您可以稍后手动重启，或现在立即重启。")
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 功能设置

struct FeatureSettingsView: View {
    @Query private var profiles: [UserProfile]
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    @State private var enableTCMFeatures = true
    @State private var enableWeatherTracking = true
    @State private var painScoreStyle: PainScoreStyle = .vas
    
    var body: some View {
        List {
            Section("功能开关") {
                Toggle(isOn: $enableTCMFeatures) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("中医功能")
                            .font(.body)
                        Text("显示中医症状、诱因和证候分析")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: enableTCMFeatures) { _, newValue in
                    userProfile?.enableTCMFeatures = newValue
                }
                
                Toggle(isOn: $enableWeatherTracking) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("天气追踪")
                            .font(.body)
                        Text("自动记录发作时的天气状况")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: enableWeatherTracking) { _, newValue in
                    userProfile?.enableWeatherTracking = newValue
                }
            }
            
            Section {
                Picker("评分标准", selection: $painScoreStyle) {
                    Text("VAS视觉模拟评分（0-10）").tag(PainScoreStyle.vas)
                    Text("NRS数字评分（0-10）").tag(PainScoreStyle.nrs)
                }
                .pickerStyle(.inline)
            } header: {
                Text("疼痛评分方式")
            } footer: {
                Text("VAS和NRS都是国际通用的疼痛评分标准，范围均为0-10分。")
            }
        }
        .navigationTitle("功能配置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let profile = userProfile {
                enableTCMFeatures = profile.enableTCMFeatures
                enableWeatherTracking = profile.enableWeatherTracking
            }
        }
    }
}

enum PainScoreStyle: String {
    case vas = "VAS"
    case nrs = "NRS"
}

// MARK: - 关于页面

struct AboutView: View {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: AppSpacing.medium) {
                    // 使用应用图标
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    
                    Text("偏头痛记录")
                        .font(.title2.bold())
                    
                    Text("版本 \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.large)
            }
            
            Section("应用介绍") {
                Text("一款专业的偏头痛管理工具，基于国际头痛学会（IHS）ICHD-3诊断标准和《中国偏头痛诊断与治疗指南2024版》开发。")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Section("主要特性") {
                Label("完整的发作记录流程", systemImage: "pencil.and.list.clipboard")
                Label("WeatherKit天气追踪", systemImage: "cloud.sun.fill")
                Label("MOH风险智能检测", systemImage: "exclamationmark.triangle.fill")
                Label("专业的数据分析", systemImage: "chart.bar.fill")
                Label("医疗报告PDF导出", systemImage: "doc.fill")
                Label("iCloud跨设备同步", systemImage: "icloud.fill")
            }
            
            Section("技术栈") {
                HStack {
                    Text("UI框架")
                    Spacer()
                    Text("SwiftUI")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("数据持久化")
                    Spacer()
                    Text("SwiftData")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("最低系统要求")
                    Spacer()
                    Text("iOS 17.0+")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("隐私承诺") {
                Text("您的所有健康数据仅存储在您的iCloud私有数据库，开发者和任何第三方都无法访问您的数据。本应用不含任何广告和追踪代码。")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    Label("使用指南", systemImage: "book.fill")
                }
                
                Link(destination: URL(string: "https://github.com")!) {
                    Label("开源代码", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                
                Link(destination: URL(string: "mailto:support@example.com")!) {
                    Label("联系我们", systemImage: "envelope.fill")
                }
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview("设置主页") {
    SettingsView()
}
