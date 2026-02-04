//
//  HomeViewModel.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

@Observable
class HomeViewModel {
    var streakDays: Int = 0
    var ongoingAttack: AttackRecord?
    var recentAttacks: [AttackRecord] = []
    var currentWeather: WeatherSnapshot?
    var weatherError: String?
    var isRefreshingWeather: Bool = false
    
    private let modelContext: ModelContext
    private let weatherManager: WeatherManager
    
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
        
        // 加载天气数据
        Task {
            await loadWeatherData()
        }
    }
    
    func loadData() {
        loadOngoingAttack()
        loadRecentAttacks()
        calculateStreak()
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
    
    private func calculateStreak() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // 获取所有发作记录，按日期排序
        let descriptor = FetchDescriptor<AttackRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let allAttacks = try? modelContext.fetch(descriptor) else {
            streakDays = 0
            return
        }
        
        // 只考虑 startTime <= 当前时间的记录，过滤掉未来的记录
        let pastAttacks = allAttacks.filter { $0.startTime <= now }
        
        // 如果没有任何过去的记录，显示 0 天
        guard !pastAttacks.isEmpty else {
            streakDays = 0
            return
        }
        
        // 找到最近的记录
        if let lastAttack = pastAttacks.first {
            // 如果最近的记录还在进行中（没有结束时间），显示发作中
            if lastAttack.endTime == nil {
                streakDays = 0
                // 注意：界面会通过 ongoingAttack 属性显示"发作进行中"状态
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
                return
            }
        }
        
        streakDays = 0
    }
    
    func refreshData() {
        loadData()
        Task {
            await loadWeatherData()
        }
    }
    
    // MARK: - 天气数据
    
    private func loadWeatherData(forceRefresh: Bool = false) async {
        if forceRefresh {
            isRefreshingWeather = true
        }
        
        // 先检查权限状态
        if !weatherManager.isAuthorized {
            if let authError = weatherManager.authorizationError {
                weatherError = convertErrorToUserFriendlyMessage(authError)
            } else {
                weatherError = "请在设置中开启定位权限"
            }
            currentWeather = nil
            isRefreshingWeather = false
            return
        }
        
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
            
            currentWeather = try await weatherManager.fetchCurrentWeather(forceRefresh: forceRefresh)
            weatherError = nil
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
                return "请在设置中开启定位权限"
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
        Task {
            await loadWeatherData(forceRefresh: true)
        }
    }
    
    // MARK: - 快速记录管理
    
    /// 快速开始记录（异步版本，支持天气获取）
    func quickStartRecording() async -> AttackRecord {
        let attack = AttackRecord(startTime: Date())
        modelContext.insert(attack)
        
        // 立即获取天气
        if let location = weatherManager.currentLocation {
            do {
                print("🌤️ 快速记录：获取当前天气")
                let weather = try await weatherManager.fetchCurrentWeather()
                modelContext.insert(weather)
                attack.weatherSnapshot = weather
            } catch {
                print("❌ 快速记录获取天气失败: \(error.localizedDescription)")
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
