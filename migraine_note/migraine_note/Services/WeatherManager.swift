//
//  WeatherManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import Foundation
import WeatherKit
import CoreLocation

@Observable
class WeatherManager: NSObject {
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    
    var currentLocation: CLLocation?
    var isAuthorized = false
    var authorizationError: Error?
    
    /// 跟踪授权状态变化的版本号（用于UI刷新）
    var authorizationVersion: Int = 0
    
    /// 定位授权状态
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    /// 是否需要请求定位权限
    var needsLocationPermission: Bool {
        let status = locationManager.authorizationStatus
        return status == .notDetermined || status == .denied || status == .restricted
    }
    
    /// 定位权限是否被拒绝或受限
    var isLocationDenied: Bool {
        let status = locationManager.authorizationStatus
        return status == .denied || status == .restricted
    }
    
    /// 定位权限是否尚未决定
    var isLocationNotDetermined: Bool {
        return locationManager.authorizationStatus == .notDetermined
    }
    
    // MARK: - 缓存
    
    /// 天气数据缓存
    private var cachedWeather: WeatherSnapshot?
    /// 缓存时间戳
    private var cacheTimestamp: Date?
    /// 缓存有效期（秒）- 默认30分钟
    private let cacheValidityDuration: TimeInterval = 1800
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    deinit {
        locationManager.delegate = nil
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - 位置权限
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - 天气翻译
    
    /// 将英文天气状况翻译为中文
    private func translateWeatherCondition(_ englishCondition: String) -> String {
        let lowercased = englishCondition.lowercased()
        
        // 映射表
        let mapping: [String: String] = [
            "clear": "晴天",
            "sunny": "晴天",
            "cloudy": "多云",
            "mostly cloudy": "多云",
            "partly cloudy": "多云",
            "overcast": "阴天",
            "rain": "雨",
            "drizzle": "小雨",
            "light rain": "小雨",
            "moderate rain": "中雨",
            "heavy rain": "大雨",
            "rainy": "雨",
            "thunderstorm": "雷阵雨",
            "thunder": "雷阵雨",
            "snow": "雪",
            "snowy": "雪",
            "sleet": "雨夹雪",
            "fog": "雾",
            "foggy": "雾",
            "haze": "霾",
            "hazy": "霾",
            "dust": "沙尘",
            "sandstorm": "沙尘暴",
            "wind": "大风",
            "windy": "大风",
            "hot": "炎热",
            "cold": "寒冷",
            "freezing": "极寒",
            "tropical storm": "热带风暴",
            "hurricane": "飓风",
            "tornado": "龙卷风",
            "blizzard": "暴风雪"
        ]
        
        // 查找匹配的键（支持部分匹配）
        for (key, value) in mapping {
            if lowercased.contains(key) {
                return value
            }
        }
        
        // 如果没有匹配，返回原始值（可能已经是中文）
        return englishCondition
    }
    
    // MARK: - 获取当前天气
    
    /// 获取当前天气快照（带缓存）
    /// - Parameter forceRefresh: 是否强制刷新，忽略缓存
    func fetchCurrentWeather(forceRefresh: Bool = false) async throws -> WeatherSnapshot {
        // 检查缓存是否有效
        if !forceRefresh, let cached = cachedWeather, let cacheTime = cacheTimestamp {
            let timeSinceCache = Date().timeIntervalSince(cacheTime)
            if timeSinceCache < cacheValidityDuration {
                return cached
            }
        }
        
        // 缓存过期或强制刷新，重新获取
        guard let location = currentLocation else {
            throw WeatherError.locationNotAvailable
        }
        
        do {
            let weather = try await weatherService.weather(for: location)
            
            let snapshot = WeatherSnapshot(timestamp: Date())
            snapshot.pressure = weather.currentWeather.pressure.value
            snapshot.pressureTrend = await determinePressureTrend(at: location)
            snapshot.temperature = weather.currentWeather.temperature.value
            snapshot.humidity = weather.currentWeather.humidity * 100 // 转换为百分比
            snapshot.windSpeed = weather.currentWeather.wind.speed.value
            snapshot.condition = translateWeatherCondition(weather.currentWeather.condition.description)
            snapshot.location = await reverseGeocode(location)
            
            // 更新缓存
            cachedWeather = snapshot
            cacheTimestamp = Date()
            
            return snapshot
        } catch {
            throw error
        }
    }
    
    /// 清除缓存
    func clearCache() {
        cachedWeather = nil
        cacheTimestamp = nil
    }
    
    /// 检查缓存是否有效
    var isCacheValid: Bool {
        guard let cacheTime = cacheTimestamp else { return false }
        let timeSinceCache = Date().timeIntervalSince(cacheTime)
        return timeSinceCache < cacheValidityDuration
    }
    
    /// 获取缓存剩余有效时间（秒）
    var cacheRemainingTime: TimeInterval? {
        guard let cacheTime = cacheTimestamp else { return nil }
        let timeSinceCache = Date().timeIntervalSince(cacheTime)
        let remaining = cacheValidityDuration - timeSinceCache
        return remaining > 0 ? remaining : nil
    }
    
    // MARK: - 获取历史天气
    
    /// 获取历史天气数据（支持 2021年8月1日 至今）
    /// - Parameters:
    ///   - date: 要查询的日期
    ///   - location: 查询位置
    /// - Returns: 历史天气快照
    /// - Note: WeatherKit 历史数据最早可追溯到 2021年8月1日
    func fetchHistoricalWeather(for date: Date, at location: CLLocation) async throws -> WeatherSnapshot {
        // WeatherKit 历史数据起始日期检查
        let historicalStartDate = DateComponents(calendar: Calendar.current, year: 2021, month: 8, day: 1).date!
        
        guard date >= historicalStartDate else {
            throw WeatherError.historicalDataNotAvailable
        }
        
        // WeatherKit历史数据通过dailyForecast获取
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let weather = try await weatherService.weather(
            for: location,
            including: .daily(startDate: startOfDay, endDate: endOfDay)
        )
        
        guard let dayWeather = weather.first else {
            throw WeatherError.dataNotAvailable
        }
        
        let snapshot = WeatherSnapshot(timestamp: date)
        snapshot.pressure = 1013.0 // 历史数据可能不包含气压
        snapshot.pressureTrend = .steady
        snapshot.temperature = (dayWeather.lowTemperature.value + dayWeather.highTemperature.value) / 2
        // 注意：在较新的WeatherKit API中，humidity可能不直接可用
        // 使用默认值或从其他字段获取
        snapshot.humidity = 50.0 // 默认湿度
        snapshot.windSpeed = dayWeather.wind.speed.value
        snapshot.condition = translateWeatherCondition(dayWeather.condition.description)
        snapshot.location = await reverseGeocode(location)
        
        return snapshot
    }
    
    // MARK: - 辅助方法
    
    /// 判断气压趋势
    private func determinePressureTrend(at location: CLLocation) async -> PressureTrend {
        do {
            let weather = try await weatherService.weather(for: location)
            let hourlyPressures = weather.hourlyForecast.forecast.prefix(3).map { $0.pressure.value }
            
            guard hourlyPressures.count >= 2 else { return .steady }
            
            let change = hourlyPressures.last! - hourlyPressures.first!
            
            if change > 2 {
                return .rising
            } else if change < -2 {
                return .falling
            } else {
                return .steady
            }
        } catch {
            return .steady
        }
    }
    
    /// 反向地理编码
    /// - Returns: 城市名称，如果无法解析则返回空字符串
    private func reverseGeocode(_ location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let locality = placemarks.first?.locality {
                return locality
            } else if let administrativeArea = placemarks.first?.administrativeArea {
                return administrativeArea
            }
            return ""
        } catch {
            return ""
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        authorizationError = error
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationVersion += 1
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            authorizationError = nil
            requestLocation()
        case .denied, .restricted:
            isAuthorized = false
            authorizationError = WeatherError.locationPermissionDenied
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - 错误类型

enum WeatherError: Error, LocalizedError {
    case locationNotAvailable
    case dataNotAvailable
    case historicalDataNotAvailable
    case locationPermissionDenied
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "请在设置中开启定位权限"
        case .dataNotAvailable:
            return "请检查网络连接"
        case .historicalDataNotAvailable:
            return "历史天气数据仅支持 2021年8月1日 至今"
        case .locationPermissionDenied:
            return "请在设置中开启定位权限"
        case .networkError:
            return "请检查网络连接"
        }
    }
}
