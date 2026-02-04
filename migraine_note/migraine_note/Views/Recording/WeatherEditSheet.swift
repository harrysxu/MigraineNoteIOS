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
    
    // 天气状况选项
    private let weatherConditions = [
        "晴天", "多云", "阴天", "小雨", "中雨", "大雨",
        "雷阵雨", "雪", "雾", "霾", "沙尘暴"
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
            _condition = State(initialValue: "晴天")
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
                            Text("温度")
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
                            Text("气压")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(String(format: "%.1f", pressure)) hPa")
                                .foregroundStyle(Color.textPrimary)
                                .font(.body.weight(.medium))
                        }
                        Slider(value: $pressure, in: 950...1050, step: 0.5)
                    }
                    
                    // 气压趋势
                    Picker("气压趋势", selection: $pressureTrend) {
                        ForEach(PressureTrend.allCases, id: \.self) { trend in
                            HStack {
                                Image(systemName: trend.icon)
                                Text(trend.rawValue)
                            }
                            .tag(trend)
                        }
                    }
                    
                    // 湿度
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("湿度")
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
                            Text("风速")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text("\(String(format: "%.1f", windSpeed)) m/s")
                                .foregroundStyle(Color.textPrimary)
                                .font(.body.weight(.medium))
                        }
                        Slider(value: $windSpeed, in: 0...30, step: 0.5)
                    }
                } header: {
                    Text("气象参数")
                }
                
                Section {
                    // 天气状况
                    Picker("天气状况", selection: $condition) {
                        ForEach(weatherConditions, id: \.self) { cond in
                            Text(cond).tag(cond)
                        }
                    }
                    
                    // 位置
                    TextField("位置（可选）", text: $location)
                } header: {
                    Text("其他信息")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(Color.statusInfo)
                        Text("手动编辑后，保存时不会自动更新天气数据")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .navigationTitle("编辑天气")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
