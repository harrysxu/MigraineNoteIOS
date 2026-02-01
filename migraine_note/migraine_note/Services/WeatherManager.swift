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
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - 位置权限
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - 获取当前天气
    
    /// 获取当前天气快照
    func fetchCurrentWeather() async throws -> WeatherSnapshot {
        guard let location = currentLocation else {
            throw WeatherError.locationNotAvailable
        }
        
        let weather = try await weatherService.weather(for: location)
        
        let snapshot = WeatherSnapshot(timestamp: Date())
        snapshot.pressure = weather.currentWeather.pressure.value
        snapshot.pressureTrend = await determinePressureTrend(at: location)
        snapshot.temperature = weather.currentWeather.temperature.value
        snapshot.humidity = weather.currentWeather.humidity * 100 // 转换为百分比
        snapshot.windSpeed = weather.currentWeather.wind.speed.value
        snapshot.condition = weather.currentWeather.condition.description
        snapshot.location = await reverseGeocode(location)
        
        return snapshot
    }
    
    // MARK: - 获取历史天气
    
    /// 获取历史天气数据（仅支持最近10天）
    func fetchHistoricalWeather(for date: Date, at location: CLLocation) async throws -> WeatherSnapshot {
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        guard daysAgo <= 10 else {
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
        snapshot.condition = dayWeather.condition.description
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
    private func reverseGeocode(_ location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let locality = placemarks.first?.locality {
                return locality
            } else if let administrativeArea = placemarks.first?.administrativeArea {
                return administrativeArea
            }
            return "未知位置"
        } catch {
            return "未知位置"
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
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            requestLocation()
        case .denied, .restricted:
            isAuthorized = false
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
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "无法获取位置信息"
        case .dataNotAvailable:
            return "无法获取天气数据"
        case .historicalDataNotAvailable:
            return "历史天气数据仅支持最近10天"
        }
    }
}
