//
//  HomeViewModel.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData
import CoreLocation

@Observable
class HomeViewModel {
    var streakDays: Int = 0
    var ongoingAttack: AttackRecord?
    var recentAttacks: [AttackRecord] = []
    var recentHealthEvents: [HealthEvent] = []
    var recentTimelineItems: [TimelineItemType] = []
    var currentWeather: WeatherSnapshot?
    var weatherError: String?
    var isRefreshingWeather: Bool = false
    
    // MARK: - 月度统计（预计算，避免 MonthlyOverviewCard 独立 @Query）
    var monthlyAttackDays: Int = 0
    var monthlyAverageIntensity: Double = 0
    var monthlyMedicationStats: DetailedMedicationStatistics?
    
    /// 是否定位权限被拒绝或受限（需要引导用户去设置中开启）
    var isLocationDenied: Bool {
        return weatherManager.isLocationDenied
    }
    
    private let modelContext: ModelContext
    private let weatherManager: WeatherManager
    
    /// 天气加载任务引用，用于取消重复请求
    private var weatherTask: Task<Void, Never>?
    
    init(modelContext: ModelContext, weatherManager: WeatherManager = WeatherManager()) {
        self.modelContext = modelContext
        self.weatherManager = weatherManager
        loadData()
        
        // 检查位置权限状态
        if let authError = weatherManager.authorizationError {
            weatherError = convertErrorToUserFriendlyMessage(authError)
        } else if !weatherManager.isAuthorized {
            weatherManager.requestLocationAuthorization()
        }
        
        // 加载天气数据（存储引用以支持取消）
        weatherTask = Task { [weak self] in
            await self?.loadWeatherData()
        }
    }
    
    deinit {
        weatherTask?.cancel()
    }
    
    func loadData() {
        loadOngoingAttack()
        loadRecentAttacks()
        loadRecentHealthEvents()
        loadRecentTimelineItems()
        calculateStreak()
        loadMonthlyStats()
    }
    
    private func loadOngoingAttack() {
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.endTime == nil
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        ongoingAttack = try? modelContext.fetch(descriptor).first
    }
    
    private func loadRecentAttacks() {
        var descriptor = FetchDescriptor<AttackRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        recentAttacks = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func loadRecentHealthEvents() {
        var descriptor = FetchDescriptor<HealthEvent>(
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        recentHealthEvents = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func loadRecentTimelineItems() {
        // 合并偏头痛发作和健康事件
        var items: [TimelineItemType] = []
        
        // 添加偏头痛发作
        items += recentAttacks.map { .attack($0) }
        
        // 添加健康事件
        items += recentHealthEvents.map { .healthEvent($0) }
        
        // 按时间倒序排序
        items.sort { $0.eventDate > $1.eventDate }
        
        // 只取前10条
        recentTimelineItems = Array(items.prefix(10))
    }
    
    private func calculateStreak() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 只获取最近一条发作记录（不再加载全量数据）
        var descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime <= now
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        guard let lastAttack = try? modelContext.fetch(descriptor).first else {
            streakDays = 0
            return
        }
        
        // 如果最近的记录还在进行中（没有结束时间），显示发作中
        if lastAttack.endTime == nil {
            streakDays = 0
            return
        }
        
        // 如果有结束时间，从结束时间计算到今天的天数差
        if let endTime = lastAttack.endTime {
            let endDay = calendar.startOfDay(for: endTime)
            
            // 如果结束日期是今天，显示 0 天
            if endDay == today {
                streakDays = 0
                return
            }
            
            // 计算从结束日期到今天的天数
            let daysSinceEnd = calendar.dateComponents([.day], from: endDay, to: today).day ?? 0
            streakDays = daysSinceEnd
        }
    }
    
    // MARK: - 月度统计
    
    private func loadMonthlyStats() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let endOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextMonth)!
        
        // 只查询当月的发作记录（而非全量）
        let attackDescriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.startTime >= startOfMonth && attack.startTime <= endOfMonth
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let monthAttacks = (try? modelContext.fetch(attackDescriptor)) ?? []
        
        // 只查询当月的健康事件
        let eventDescriptor = FetchDescriptor<HealthEvent>(
            predicate: #Predicate { event in
                event.eventDate >= startOfMonth && event.eventDate <= endOfMonth
            },
            sortBy: [SortDescriptor(\.eventDate, order: .reverse)]
        )
        let monthEvents = (try? modelContext.fetch(eventDescriptor)) ?? []
        
        // 计算统计
        monthlyAttackDays = Set(monthAttacks.map { calendar.startOfDay(for: $0.startTime) }).count
        
        if monthAttacks.isEmpty {
            monthlyAverageIntensity = 0
        } else {
            monthlyAverageIntensity = Double(monthAttacks.reduce(0) { $0 + $1.painIntensity }) / Double(monthAttacks.count)
        }
        
        monthlyMedicationStats = DetailedMedicationStatistics.calculate(
            attacks: monthAttacks,
            healthEvents: monthEvents,
            dateRange: (startOfMonth, endOfMonth)
        )
    }
    
    func refreshData() {
        loadData()
        // 取消之前的天气任务，避免多个并行请求
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            await self?.loadWeatherData()
        }
    }
    
    // MARK: - 天气数据
    
    private func loadWeatherData(forceRefresh: Bool = false) async {
        if forceRefresh {
            isRefreshingWeather = true
        }
        
        // 检查定位权限
        let status = weatherManager.authorizationStatus
        
        // 如果权限未授权，设置错误信息，不加载天气数据
        if status == .denied || status == .restricted {
            weatherError = "请在设置中开启定位权限"
            currentWeather = nil
            isRefreshingWeather = false
            return
        }
        
        // 如果权限未确定，请求权限（不设置错误信息，显示加载状态等待用户授权）
        if status == .notDetermined {
            weatherManager.requestLocationAuthorization()
            weatherError = nil
            currentWeather = nil
            isRefreshingWeather = false
            return
        }
        
        // 权限已授权，尝试加载天气数据
        do {
            // 确保有位置信息
            if weatherManager.currentLocation == nil {
                weatherManager.requestLocation()
                // 等待位置更新
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                
                // 如果还是没有位置，抛出错误
                if weatherManager.currentLocation == nil {
                    throw WeatherError.locationNotAvailable
                }
            }
            
            let weather = try await weatherManager.fetchCurrentWeather(forceRefresh: forceRefresh)
            
            // 如果位置无法解析（反向地理编码失败），说明定位不可靠，不展示天气数据
            if weather.location.isEmpty {
                weatherError = "无法确认当前位置"
                currentWeather = nil
            } else {
                currentWeather = weather
                weatherError = nil
            }
        } catch {
            // 将技术性错误转换为用户友好的提示
            weatherError = convertErrorToUserFriendlyMessage(error)
            currentWeather = nil
        }
        
        isRefreshingWeather = false
    }
    
    /// 将错误转换为用户友好的提示信息
    private func convertErrorToUserFriendlyMessage(_ error: Error) -> String {
        // 检查是否是自定义的天气错误
        if let weatherError = error as? WeatherError {
            switch weatherError {
            case .locationNotAvailable:
                if weatherManager.isLocationDenied {
                    return "定位权限未开启，请在设置中开启"
                } else {
                    return "无法获取当前位置，请确认定位服务已开启后重试"
                }
            case .dataNotAvailable:
                return "请检查网络连接"
            case .historicalDataNotAvailable:
                return "历史数据暂时不可用"
            case .locationPermissionDenied:
                return "请在设置中开启定位权限"
            case .networkError:
                return "请检查网络连接"
            }
        }
        
        // 检查错误描述中的关键词
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("location") || errorDescription.contains("位置") {
            return "请在设置中开启定位权限"
        } else if errorDescription.contains("network") || errorDescription.contains("网络") || 
                  errorDescription.contains("internet") || errorDescription.contains("connection") {
            return "请检查网络连接"
        } else if errorDescription.contains("authorization") || errorDescription.contains("权限") ||
                  errorDescription.contains("denied") || errorDescription.contains("拒绝") {
            return "请在设置中开启定位权限"
        } else {
            return "天气数据暂时不可用，请稍后重试"
        }
    }
    
    /// 刷新天气数据
    func refreshWeather() {
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            await self?.loadWeatherData(forceRefresh: true)
        }
    }
    
    // MARK: - 快速记录管理
    
    /// 快速开始记录（异步版本，支持天气获取）
    func quickStartRecording() async -> AttackRecord {
        let attack = AttackRecord(startTime: Date())
        modelContext.insert(attack)
        
        // 立即获取天气
        if weatherManager.currentLocation != nil {
            do {
                let weather = try await weatherManager.fetchCurrentWeather()
                modelContext.insert(weather)
                attack.weatherSnapshot = weather
            } catch {
                // 天气获取失败不影响快速记录
            }
        }
        
        try? modelContext.save()
        
        // 在主线程更新UI
        await MainActor.run {
            loadData() // 刷新数据以显示进行中状态
        }
        
        return attack
    }
    
    /// 快速结束记录
    func quickEndRecording(_ attack: AttackRecord) {
        attack.endTime = Date()
        attack.updatedAt = Date()
        try? modelContext.save()
        loadData() // 刷新数据以更新状态
    }
}
