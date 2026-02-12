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
    /// 使用单例，避免多个实例重复注册通知观察者
    private var cloudKitManager: CloudKitManager { CloudKitManager.shared }
    @State private var syncSettingsManager = SyncSettingsManager.shared
    @State private var showRestartAlert = false
    @State private var showResetAlert = false
    @State private var isResetting = false
    @State private var resetResultMessage: String?
    @State private var showResetResult = false
    
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
                        .symbolEffect(.pulse, isActive: cloudKitManager.syncStatus == .syncing)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cloudKitManager.syncStatus.displayText)
                            .font(.headline)
                        
                        syncStatusSubtitle
                    }
                    
                    Spacer()
                }
                .padding(.vertical, AppSpacing.small)
                .animation(.easeInOut(duration: 0.3), value: cloudKitManager.syncStatus)
            }
            
            // 最后同步时间（仅在同步已启用时显示）
            if SyncSettingsManager.isSyncCurrentlyEnabled() {
                Section {
                    HStack {
                        Label("上次同步", systemImage: "clock.arrow.circlepath")
                            .foregroundColor(.secondary)
                        Spacer()
                        if let lastSync = cloudKitManager.lastSyncDate {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(lastSync.syncRelativeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(lastSync.syncAbsoluteString)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        } else {
                            Text("等待首次同步")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
            
            // 同步日志
            if SyncSettingsManager.isSyncCurrentlyEnabled() {
                Section {
                    if cloudKitManager.syncLogs.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.title2)
                                    .foregroundStyle(.tertiary)
                                Text("暂无同步记录")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, AppSpacing.medium)
                            Spacer()
                        }
                    } else {
                        ForEach(cloudKitManager.syncLogs) { entry in
                            SyncLogRow(entry: entry)
                        }
                    }
                } header: {
                    HStack {
                        Text("同步日志")
                        Spacer()
                        if !cloudKitManager.syncLogs.isEmpty {
                            Button("清除") {
                                withAnimation {
                                    cloudKitManager.clearSyncLogs()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .textCase(nil)
                        }
                    }
                }
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
            
            // 高级操作：重置同步（仅在同步已启用时显示）
            if SyncSettingsManager.isSyncCurrentlyEnabled() && cloudKitManager.isICloudAvailable {
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack {
                            if isResetting {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("重置 iCloud 同步数据")
                        }
                    }
                    .disabled(isResetting)
                } header: {
                    Text("高级")
                } footer: {
                    Text("如果同步长时间卡住或出现异常，可以重置云端数据。重置后本地数据会重新上传到 iCloud，不会丢失。")
                        .font(.caption)
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
        .alert("确认重置同步数据？", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置并重启", role: .destructive) {
                performCloudKitReset()
            }
        } message: {
            Text("将删除 iCloud 中的同步数据并重新从本地上传。本地数据不会丢失。操作完成后需要重启应用。")
        }
        .alert("重置结果", isPresented: $showResetResult) {
            Button("立即重启") {
                exit(0)
            }
            Button("稍后", role: .cancel) { }
        } message: {
            Text(resetResultMessage ?? "")
        }
    }
    
    // MARK: - 同步状态副标题
    
    @ViewBuilder
    private var syncStatusSubtitle: some View {
        if cloudKitManager.syncStatus == .disabled {
            Text("数据仅保存在本地设备")
                .font(.caption)
                .foregroundColor(.secondary)
        } else if cloudKitManager.syncStatus == .syncFailed {
            Text(cloudKitManager.errorMessage ?? "同步时遇到问题，将自动重试")
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(2)
        } else if cloudKitManager.syncStatus == .syncing {
            Text("正在与iCloud同步数据...")
                .font(.caption)
                .foregroundColor(.blue)
        } else if cloudKitManager.syncStatus == .notSignedIn {
            Text("请在系统设置中登录iCloud")
                .font(.caption)
                .foregroundColor(.orange)
        } else if cloudKitManager.isICloudAvailable {
            if let lastSync = cloudKitManager.lastSyncDate {
                Text("上次同步：\(lastSync.syncRelativeString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("已就绪，等待首次同步...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            Text("检查iCloud状态中...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func performCloudKitReset() {
        isResetting = true
        Task {
            do {
                try await cloudKitManager.resetCloudKitZone()
                await MainActor.run {
                    isResetting = false
                    resetResultMessage = "iCloud 同步数据已重置。请重启应用以重新开始同步。"
                    showResetResult = true
                }
            } catch {
                await MainActor.run {
                    isResetting = false
                    resetResultMessage = "重置失败：\(error.localizedDescription)"
                    showResetResult = true
                }
            }
        }
    }
}

// MARK: - 同步日志行组件

struct SyncLogRow: View {
    let entry: SyncLogEntry
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: entry.type.icon)
                .font(.body)
                .foregroundStyle(entry.succeeded ? entry.type.color : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(entry.type.displayText)
                        .font(.subheadline.weight(.medium))
                    
                    if !entry.succeeded {
                        Text("失败")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.red))
                    }
                }
                
                if let details = entry.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let error = entry.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 功能设置

struct FeatureSettingsView: View {
    @Query private var profiles: [UserProfile]
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    @State private var premiumManager = PremiumManager.shared
    @State private var enableTCMFeatures = true
    @State private var enableWeatherTracking = true
    @State private var painScoreStyle: PainScoreStyle = .vas
    @State private var showSubscription = false
    
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
                
                Toggle(isOn: Binding(
                    get: { enableWeatherTracking },
                    set: { newValue in
                        if newValue && !premiumManager.isPremium {
                            showSubscription = true
                        } else {
                            enableWeatherTracking = newValue
                            userProfile?.enableWeatherTracking = newValue
                        }
                    }
                )) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("天气追踪")
                                .font(.body)
                            Text("自动记录发作时的天气状况")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !premiumManager.isPremium {
                            PremiumBadge()
                        }
                    }
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
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
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
    
    #if DEBUG
    @State private var logoTapCount = 0
    @State private var showTestView = false
    @State private var showDevModeHint = false
    #endif
    
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
                        #if DEBUG
                        .onTapGesture {
                            logoTapCount += 1
                            if logoTapCount >= 3 {
                                showTestView = true
                                logoTapCount = 0
                            }
                        }
                        .sensoryFeedback(.impact, trigger: logoTapCount)
                        #endif
                    
                    Text("偏头痛记录")
                        .font(.title2.bold())
                    
                    Text("版本 \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    #if DEBUG
                    if showDevModeHint {
                        Text("💡 连续点击图标3次可进入测试模式")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                    #endif
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
                Link(destination: URL(string: "https://harrysxu.github.io/MigraineNoteIOS/support.html")!) {
                    Label("使用指南", systemImage: "book.fill")
                }
                
                Link(destination: URL(string: "https://github.com/harrysxu/MigraineNoteIOS")!) {
                    Label("开源代码", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                
                Link(destination: URL(string: "mailto:ailehuoquan@163.com")!) {
                    Label("联系我们", systemImage: "envelope.fill")
                }
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .navigationDestination(isPresented: $showTestView) {
            TestDataView()
        }
        .onAppear {
            // 延迟显示提示，给用户一点暗示
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showDevModeHint = true
                }
                // 3秒后隐藏提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showDevModeHint = false
                    }
                }
            }
        }
        #endif
    }
}

// MARK: - Previews

#Preview("设置主页") {
    SettingsView()
}
