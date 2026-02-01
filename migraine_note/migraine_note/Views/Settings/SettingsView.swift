import SwiftUI
import SwiftData
import HealthKit

/// 设置页面
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @State private var showProfileEditor = false
    @State private var showHealthKitSettings = false
    @State private var showAbout = false
    @State private var healthKitManager: HealthKitManager?
    @State private var weatherManager: WeatherManager?
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 个人信息
                Section {
                    Button {
                        showProfileEditor = true
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppColors.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(userProfile?.name ?? "未设置姓名")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("点击编辑个人信息")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("个人信息")
                }
                
                // 数据与隐私
                Section {
                    NavigationLink {
                        HealthKitSettingsView()
                    } label: {
                        SettingRow(
                            icon: "heart.fill",
                            iconColor: .red,
                            title: "健康数据",
                            subtitle: "HealthKit权限管理"
                        )
                    }
                    
                    NavigationLink {
                        LocationSettingsView()
                    } label: {
                        SettingRow(
                            icon: "location.fill",
                            iconColor: .blue,
                            title: "位置服务",
                            subtitle: "天气追踪权限"
                        )
                    }
                    
                    NavigationLink {
                        CloudSyncSettingsView()
                    } label: {
                        SettingRow(
                            icon: "icloud.fill",
                            iconColor: .cyan,
                            title: "iCloud同步",
                            subtitle: "跨设备数据同步"
                        )
                    }
                } header: {
                    Text("数据与隐私")
                } footer: {
                    Text("所有数据存储在您的iCloud私有数据库，仅您本人可访问。")
                }
                
                // 功能设置
                Section {
                    NavigationLink {
                        FeatureSettingsView()
                    } label: {
                        SettingRow(
                            icon: "slider.horizontal.3",
                            iconColor: .purple,
                            title: "功能配置",
                            subtitle: "自定义应用功能"
                        )
                    }
                    
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingRow(
                            icon: "bell.fill",
                            iconColor: .orange,
                            title: "提醒设置",
                            subtitle: "用药提醒和疗效评估"
                        )
                    }
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
                            title: "关于",
                            subtitle: "版本信息和使用指南"
                        )
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showProfileEditor) {
                ProfileEditorView(profile: userProfile)
            }
        }
    }
}

// MARK: - 设置行组件

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 个人信息编辑器

struct ProfileEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let profile: UserProfile?
    
    @State private var name: String = ""
    @State private var age: Int = 30
    @State private var gender: Gender? = nil
    @State private var migraineOnsetAge: Int?
    @State private var hasMigraineOnsetAge = false
    @State private var familyHistory = false
    
    init(profile: UserProfile?) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _age = State(initialValue: profile?.age ?? 30)
        _gender = State(initialValue: profile?.gender)
        _familyHistory = State(initialValue: profile?.familyHistory ?? false)
        if let onsetAge = profile?.migraineOnsetAge {
            _migraineOnsetAge = State(initialValue: onsetAge)
            _hasMigraineOnsetAge = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("姓名", text: $name)
                    
                    Picker("性别", selection: $gender) {
                        Text("未指定").tag(nil as Gender?)
                        Text("女性").tag(Gender.female as Gender?)
                        Text("男性").tag(Gender.male as Gender?)
                        Text("其他").tag(Gender.other as Gender?)
                    }
                    
                    Picker("年龄", selection: $age) {
                        ForEach(10...100, id: \.self) { age in
                            Text("\(age)岁").tag(age)
                        }
                    }
                }
                
                Section("病史信息") {
                    Toggle("家族病史", isOn: $familyHistory)
                    
                    Toggle("记录发病年龄", isOn: $hasMigraineOnsetAge)
                    
                    if hasMigraineOnsetAge {
                        Picker("发病年龄", selection: Binding(
                            get: { migraineOnsetAge ?? age },
                            set: { migraineOnsetAge = $0 }
                        )) {
                            ForEach(1...age, id: \.self) { onsetAge in
                                Text("\(onsetAge)岁").tag(onsetAge)
                            }
                        }
                    }
                }
            }
            .navigationTitle("编辑个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveProfile()
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        if let existingProfile = profile {
            existingProfile.name = name
            existingProfile.age = age
            existingProfile.gender = gender
            existingProfile.familyHistory = familyHistory
            existingProfile.migraineOnsetAge = hasMigraineOnsetAge ? migraineOnsetAge : nil
        } else {
            let newProfile = UserProfile()
            newProfile.name = name
            newProfile.age = age
            newProfile.gender = gender
            newProfile.familyHistory = familyHistory
            newProfile.migraineOnsetAge = hasMigraineOnsetAge ? migraineOnsetAge : nil
            modelContext.insert(newProfile)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - HealthKit设置

struct HealthKitSettingsView: View {
    @State private var healthKitManager = HealthKitManager()
    @State private var isHealthKitAvailable = false
    @State private var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @State private var showRequestSheet = false
    
    var body: some View {
        List {
            Section {
                if !isHealthKitAvailable {
                    InfoCard {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("HealthKit不可用")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                            Text("当前设备不支持HealthKit功能。")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if authorizationStatus == .sharingDenied {
                    InfoCard {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("权限已拒绝")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text("请前往系统设置 > 健康 > 数据访问与设备，允许本应用访问健康数据。")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    InfoCard {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("健康数据集成")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                            Text("允许读取睡眠、月经周期、心率等健康数据，并将偏头痛发作记录同步到健康App。")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("权限状态") {
                HStack {
                    Text("头痛记录写入")
                    Spacer()
                    StatusBadge(status: authorizationStatus)
                }
                
                HStack {
                    Text("睡眠数据读取")
                    Spacer()
                    StatusBadge(status: authorizationStatus)
                }
                
                HStack {
                    Text("月经周期读取")
                    Spacer()
                    StatusBadge(status: authorizationStatus)
                }
                
                HStack {
                    Text("心率读取")
                    Spacer()
                    StatusBadge(status: authorizationStatus)
                }
            }
            
            Section {
                if authorizationStatus != .sharingAuthorized {
                    Button {
                        requestHealthKitPermission()
                    } label: {
                        Label("请求权限", systemImage: "hand.raised.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Label("打开系统设置", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("健康数据")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkHealthKitStatus()
        }
    }
    
    private func checkHealthKitStatus() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        // 注意：HealthKit权限状态无法精确查询，只能尝试请求
        authorizationStatus = .notDetermined
    }
    
    private func requestHealthKitPermission() {
        Task {
            do {
                try await healthKitManager.requestAuthorization()
                authorizationStatus = .sharingAuthorized
            } catch {
                print("HealthKit授权失败: \(error)")
            }
        }
    }
}

struct StatusBadge: View {
    let status: HKAuthorizationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption)
            Text(statusText)
                .font(.caption)
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch status {
        case .sharingAuthorized:
            return "checkmark.circle.fill"
        case .sharingDenied:
            return "xmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch status {
        case .sharingAuthorized:
            return "已授权"
        case .sharingDenied:
            return "已拒绝"
        default:
            return "未设置"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .sharingAuthorized:
            return .green
        case .sharingDenied:
            return .red
        default:
            return .orange
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
                            .foregroundColor(AppColors.primary)
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
    
    var body: some View {
        List {
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
                        
                        if cloudKitManager.isICloudAvailable {
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
                            .foregroundColor(AppColors.primary)
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

// MARK: - 提醒设置

struct NotificationSettingsView: View {
    @State private var enableMedicationReminders = false
    @State private var enableEffectivenessReminders = true
    @State private var reminderTime = Date()
    
    var body: some View {
        List {
            Section {
                InfoCard {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("提醒功能")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                        Text("设置用药提醒和疗效评估提醒，帮助您按时用药并记录疗效。")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Toggle("预防性用药提醒", isOn: $enableMedicationReminders)
                
                if enableMedicationReminders {
                    DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("用药提醒")
            } footer: {
                Text("每日固定时间提醒服用预防性用药")
            }
            
            Section {
                Toggle("服药后疗效评估", isOn: $enableEffectivenessReminders)
            } header: {
                Text("疗效评估提醒")
            } footer: {
                Text("服药2小时后提醒评估药物疗效")
            }
        }
        .navigationTitle("提醒设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 关于页面

struct AboutView: View {
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: AppSpacing.medium) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundStyle(AppColors.primary)
                    
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
                Label("HealthKit健康数据集成", systemImage: "heart.fill")
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
        .modelContainer(for: [UserProfile.self], inMemory: true)
}

#Preview("个人信息编辑") {
    ProfileEditorView(profile: nil)
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
