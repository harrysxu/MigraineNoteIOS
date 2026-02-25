//
//  WeatherEditSheet.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/4.
//

import SwiftUI

/// 天气编辑 Sheet - 允许用户手动编辑天气数据
struct WeatherEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    let originalWeather: WeatherSnapshot?
    let onSave: (WeatherSnapshot) -> Void
    
    @State private var temperature: Double
    @State private var pressure: Double
    @State private var humidity: Double
    @State private var windSpeed: Double
    @State private var condition: String
    @State private var location: String
    @State private var pressureTrend: PressureTrend
    
    // 天气状况选项：(存储值, 本地化key)
    private static let weatherConditions: [(storage: String, key: String)] = [
        ("晴天", "weather.condition.sunny"),
        ("多云", "weather.condition.cloudy"),
        ("阴天", "weather.condition.overcast"),
        ("小雨", "weather.condition.lightRain"),
        ("中雨", "weather.condition.moderateRain"),
        ("大雨", "weather.condition.heavyRain"),
        ("雷阵雨", "weather.condition.thunderstorm"),
        ("雪", "weather.condition.snow"),
        ("雾", "weather.condition.fog"),
        ("霾", "weather.condition.haze"),
        ("沙尘暴", "weather.condition.dustStorm")
    ]
    
    init(isPresented: Binding<Bool>, originalWeather: WeatherSnapshot?, onSave: @escaping (WeatherSnapshot) -> Void) {
        self._isPresented = isPresented
        self.originalWeather = originalWeather
        self.onSave = onSave
        
        // 初始化状态
        if let weather = originalWeather {
            _temperature = State(initialValue: weather.temperature)
            _pressure = State(initialValue: weather.pressure)
            _humidity = State(initialValue: weather.humidity)
            _windSpeed = State(initialValue: weather.windSpeed)
            _condition = State(initialValue: weather.condition)
            _location = State(initialValue: weather.location)
            _pressureTrend = State(initialValue: weather.pressureTrend)
        } else {
            // 默认值
            _temperature = State(initialValue: 20.0)
            _pressure = State(initialValue: 1013.0)
            _humidity = State(initialValue: 60.0)
            _windSpeed = State(initialValue: 3.0)
            _condition = State(initialValue: Self.weatherConditions[0].storage)
            _location = State(initialValue: "")
            _pressureTrend = State(initialValue: .steady)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 温度
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("weather.temperature")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(String(format: "%.1f", temperature))°C")
                                .foregroundStyle(Color.textPrimary)
                                .font(.body.weight(.medium))
                        }
                        Slider(value: $temperature, in: -20...50, step: 0.5)
                    }
                    
                    // 气压
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("weather.pressure")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(String(format: "%.1f", pressure)) hPa")
                                .foregroundStyle(Color.textPrimary)
                                .font(.body.weight(.medium))
                        }
                        Slider(value: $pressure, in: 950...1050, step: 0.5)
                    }
                    
                    // 气压趋势
                    Picker("weather.pressure.trend", selection: $pressureTrend) {
                        ForEach(PressureTrend.allCases, id: \.self) { trend in
                            HStack {
                                Image(systemName: trend.icon)
                                Text(trend.localizedName)
                            }
                            .tag(trend)
                        }
                    }
                    
                    // 湿度
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("weather.humidity")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(String(format: "%.0f", humidity))%")
                                .foregroundStyle(Color.textPrimary)
                                .font(.body.weight(.medium))
                        }
                        Slider(value: $humidity, in: 0...100, step: 1)
                    }
                    
                    // 风速
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("weather.windSpeed")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(String(format: "%.1f", windSpeed)) m/s")
                                .foregroundStyle(Color.textPrimary)
                                .font(.body.weight(.medium))
                        }
                        Slider(value: $windSpeed, in: 0...30, step: 0.5)
                    }
                } header: {
                    Text("weather.params")
                }
                
                Section {
                    // 天气状况
                    Picker("weather.condition", selection: $condition) {
                        ForEach(Self.weatherConditions, id: \.storage) { cond in
                            Text(String(localized: String.LocalizationValue(cond.key))).tag(cond.storage)
                        }
                    }
                    
                    // 位置
                    TextField("weather.location", text: $location)
                } header: {
                    Text("weather.other")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.statusInfo)
                        Text("weather.manualEditHint")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .navigationTitle("weather.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        saveWeather()
                    }
                }
            }
        }
    }
    
    private func saveWeather() {
        let weather = originalWeather ?? WeatherSnapshot()
        weather.temperature = temperature
        weather.pressure = pressure
        weather.humidity = humidity
        weather.windSpeed = windSpeed
        weather.condition = condition
        weather.location = location
        weather.pressureTrend = pressureTrend
        weather.isManuallyEdited = true
        
        onSave(weather)
        dismiss()
    }
}

#Preview {
    WeatherEditSheet(
        isPresented: .constant(true),
        originalWeather: {
            let w = WeatherSnapshot()
            w.temperature = 23.5
            w.pressure = 1013.25
            w.humidity = 65
            w.windSpeed = 3.2
            w.condition = "晴天"
            w.location = "北京"
            return w
        }(),
        onSave: { _ in }
    )
}
