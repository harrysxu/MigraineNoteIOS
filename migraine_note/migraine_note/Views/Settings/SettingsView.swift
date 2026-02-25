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
                            title: String(localized: "settings.theme"),
                            subtitle: themeManager.currentTheme.localizedName
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(String(localized: "settings.appearance"))
                }
                
                // 数据与隐私
                Section {
                    NavigationLink {
                        LocationSettingsView()
                    } label: {
                        SettingRow(
                            icon: "location.fill",
                            iconColor: .blue,
                            title: String(localized: "settings.location"),
                            subtitle: String(localized: "settings.location.subtitle")
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        CloudSyncSettingsView()
                    } label: {
                        SettingRow(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: String(localized: "settings.icloud.sync"),
                            subtitle: String(localized: "settings.icloud.subtitle")
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(String(localized: "settings.data.privacy"))
                } footer: {
                    Text(String(localized: "settings.data.privacy.footer"))
                }
                
                // 功能设置
                Section {
                    NavigationLink {
                        LabelManagementView()
                    } label: {
                        SettingRow(
                            icon: "tag.fill",
                            iconColor: Color.accentPrimary,
                            title: String(localized: "settings.label.management"),
                            subtitle: String(localized: "settings.label.subtitle")
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        FeatureSettingsView()
                    } label: {
                        SettingRow(
                            icon: "slider.horizontal.3",
                            iconColor: .purple,
                            title: String(localized: "settings.personalization"),
                            subtitle: String(localized: "settings.personalization.subtitle")
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(String(localized: "settings.features"))
                }
                
                // 关于
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingRow(
                            icon: "info.circle.fill",
                            iconColor: .gray,
                            title: String(localized: "settings.about.app"),
                            subtitle: String(localized: "settings.about.subtitle")
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(String(localized: "settings.about"))
                }
            }
            .navigationTitle(String(localized: "settings.title"))
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
                        Text(String(localized: "settings.location.title"))
                            .font(.headline)
                            .foregroundColor(Color.accentPrimary)
                        Text(String(localized: "settings.location.desc"))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(String(localized: "settings.location.features")) {
                Label(String(localized: "settings.location.feature.weather"), systemImage: "cloud.sun.fill")
                Label(String(localized: "settings.location.feature.pressure"), systemImage: "gauge.high")
                Label(String(localized: "settings.location.feature.temp"), systemImage: "thermometer.medium")
            }
            
            Section {
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label(String(localized: "settings.open.settings"), systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(String(localized: "settings.location.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - CloudKit同步设置

struct CloudSyncSettingsView: View {
    /// 使用单例，避免多个实例重复注册通知观察者
    private var cloudKitManager: CloudKitManager { CloudKitManager.shared }
    @State private var syncSettingsManager = SyncSettingsManager.shared
    @State private var showRestartAlert = false
    
    var body: some View {
        List {
            // 同步开关
            Section {
                Toggle(isOn: $syncSettingsManager.isSyncEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.icloud.enable"))
                            .font(.body)
                        Text(String(localized: "settings.icloud.off.desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(Color.accentPrimary)
            } footer: {
                Text(String(localized: "settings.icloud.restart.hint"))
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
                        Label(String(localized: "settings.sync.last"), systemImage: "clock.arrow.circlepath")
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
                            Text(String(localized: "settings.sync.waiting"))
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
                        Text(String(localized: "settings.icloud.title"))
                            .font(.headline)
                            .foregroundColor(Color.accentPrimary)
                        Text(String(localized: "settings.icloud.desc"))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(String(localized: "settings.sync.features")) {
                Label(String(localized: "settings.sync.cross.device"), systemImage: "icloud.fill")
                Label(String(localized: "settings.sync.encrypted"), systemImage: "lock.shield.fill")
                Label(String(localized: "settings.sync.private"), systemImage: "externaldrive.fill.badge.person.crop")
                Label(String(localized: "settings.sync.offline"), systemImage: "wifi.slash")
            }
            
            Section(String(localized: "settings.privacy")) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("✓ \(String(localized: "settings.privacy.icloud"))")
                        .font(.caption)
                    Text("✓ \(String(localized: "settings.privacy.no.access"))")
                        .font(.caption)
                    Text("✓ \(String(localized: "settings.privacy.no.third"))")
                        .font(.caption)
                    Text("✓ \(String(localized: "settings.privacy.medical"))")
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
                                Text(String(localized: "settings.sync.empty"))
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
                        Text(String(localized: "settings.sync.log"))
                        Spacer()
                        if !cloudKitManager.syncLogs.isEmpty {
                            Button(String(localized: "settings.sync.clear")) {
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
                            Text(String(localized: "settings.open.settings"))
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "settings.icloud.title"))
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
        .alert(String(localized: "settings.restart.required"), isPresented: $showRestartAlert) {
            Button(String(localized: "settings.restart.later"), role: .cancel) { }
            Button(String(localized: "settings.restart.now")) {
                // 退出应用，用户需要手动重启
                exit(0)
            }
        } message: {
            Text(String(localized: "settings.restart.message"))
        }
    }
    
    // MARK: - 同步状态副标题
    
    @ViewBuilder
    private var syncStatusSubtitle: some View {
        if cloudKitManager.syncStatus == .disabled {
            Text(String(localized: "settings.sync.local.only"))
                .font(.caption)
                .foregroundColor(.secondary)
        } else if cloudKitManager.syncStatus == .syncFailed {
            Text(cloudKitManager.errorMessage ?? String(localized: "settings.sync.retry"))
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(2)
        } else if cloudKitManager.syncStatus == .syncing {
            Text(String(localized: "settings.sync.syncing"))
                .font(.caption)
                .foregroundColor(.blue)
        } else if cloudKitManager.syncStatus == .notSignedIn {
            Text(String(localized: "settings.sync.signin"))
                .font(.caption)
                .foregroundColor(.orange)
        } else if cloudKitManager.isICloudAvailable {
            if let lastSync = cloudKitManager.lastSyncDate {
                Text(String(format: String(localized: "settings.sync.last.prefix"), lastSync.syncRelativeString))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(String(localized: "settings.sync.ready"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            Text(String(localized: "settings.sync.checking"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
                        Text(String(localized: "settings.sync.failed"))
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
            Section(String(localized: "settings.features.toggle")) {
                Toggle(isOn: $enableTCMFeatures) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "settings.tcm.features"))
                            .font(.body)
                        Text(String(localized: "settings.tcm.desc"))
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
                            Text(String(localized: "settings.weather.tracking"))
                                .font(.body)
                            Text(String(localized: "settings.weather.desc"))
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
                Picker(String(localized: "settings.pain.score.standard"), selection: $painScoreStyle) {
                    Text(String(localized: "settings.pain.vas")).tag(PainScoreStyle.vas)
                    Text(String(localized: "settings.pain.nrs")).tag(PainScoreStyle.nrs)
                }
                .pickerStyle(.inline)
            } header: {
                Text(String(localized: "settings.pain.score"))
            } footer: {
                Text(String(localized: "settings.pain.footer"))
            }
        }
        .navigationTitle(String(localized: "settings.features.title"))
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
                    
                    Text(String(localized: "app.name"))
                        .font(.title2.bold())
                    
                    Text(String(format: String(localized: "about.version"), appVersion, buildNumber))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    #if DEBUG
                    if showDevModeHint {
                        Text("💡 \(String(localized: "about.dev.hint"))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .transition(.opacity)
                    }
                    #endif
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.large)
            }
            
            Section(String(localized: "about.intro.section")) {
                Text(String(localized: "about.intro"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Section(String(localized: "about.features")) {
                Label(String(localized: "about.feature.records"), systemImage: "pencil.and.list.clipboard")
                Label(String(localized: "about.feature.weather"), systemImage: "cloud.sun.fill")
                Label(String(localized: "about.feature.moh"), systemImage: "exclamationmark.triangle.fill")
                Label(String(localized: "about.feature.analytics"), systemImage: "chart.bar.fill")
                Label(String(localized: "about.feature.export"), systemImage: "doc.fill")
                Label(String(localized: "about.feature.icloud"), systemImage: "icloud.fill")
            }
            
            Section(String(localized: "about.weather.source")) {
                WeatherAttribution(style: .full)
            }
            
            Section(String(localized: "about.tech.section")) {
                HStack {
                    Text(String(localized: "about.tech.ui"))
                    Spacer()
                    Text("SwiftUI")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(String(localized: "about.tech.data"))
                    Spacer()
                    Text("SwiftData")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(String(localized: "about.tech.min"))
                    Spacer()
                    Text("iOS 17.0+")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(String(localized: "about.privacy")) {
                Text(String(localized: "about.privacy.desc"))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Link(destination: URL(string: "https://harrysxu.github.io/MigraineNoteIOS/pages/support.html")!) {
                    Label(String(localized: "about.guide"), systemImage: "book.fill")
                }
                
                Link(destination: URL(string: "https://github.com/harrysxu/MigraineNoteIOS")!) {
                    Label(String(localized: "about.source"), systemImage: "chevron.left.forwardslash.chevron.right")
                }
                
                Link(destination: URL(string: "mailto:ailehuoquan@163.com")!) {
                    Label(String(localized: "about.contact"), systemImage: "envelope.fill")
                }
            }
        }
        .navigationTitle(String(localized: "about.title"))
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
