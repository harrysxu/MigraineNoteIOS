//
//  WeatherSnapshot.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftData
import Foundation

@Model
final class WeatherSnapshot {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var pressure: Double // hPa
    var pressureTrendRawValue: String
    var temperature: Double // 摄氏度
    var humidity: Double // 百分比 0-100
    var windSpeed: Double // km/h
    var condition: String // "晴", "阴", "雨"
    var location: String
    
    init(timestamp: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        self.pressure = 0
        self.pressureTrendRawValue = PressureTrend.steady.rawValue
        self.temperature = 0
        self.humidity = 0
        self.windSpeed = 0
        self.condition = ""
        self.location = ""
    }
    
    // 计算属性
    var pressureTrend: PressureTrend {
        get { PressureTrend(rawValue: pressureTrendRawValue) ?? .steady }
        set { pressureTrendRawValue = newValue.rawValue }
    }
    
    // 是否为高风险天气（可能触发偏头痛）
    var isHighRisk: Bool {
        // 气压骤降
        if pressureTrend == .falling && pressure < 1010 {
            return true
        }
        // 高湿度
        if humidity > 80 {
            return true
        }
        // 极端温度
        if temperature > 35 || temperature < 0 {
            return true
        }
        return false
    }
    
    // 风险提示
    var riskWarning: String? {
        if pressureTrend == .falling && pressure < 1010 {
            return "气压骤降，可能触发头痛"
        }
        if humidity > 80 {
            return "高湿度环境，注意防湿"
        }
        if temperature > 35 {
            return "高温天气，注意防暑"
        }
        if temperature < 0 {
            return "气温过低，注意保暖"
        }
        return nil
    }
    
    // 风险警告数组（兼容）
    var warnings: [String] {
        var result: [String] = []
        if pressureTrend == .falling && pressure < 1010 {
            result.append("气压骤降，可能触发头痛")
        }
        if humidity > 80 {
            result.append("高湿度环境，注意防湿")
        }
        if temperature > 35 {
            result.append("高温天气，注意防暑")
        } else if temperature < 0 {
            result.append("气温过低，注意保暖")
        }
        return result
    }
}

enum PressureTrend: String, Codable, CaseIterable {
    case rising = "上升"
    case falling = "下降"
    case steady = "稳定"
    
    var icon: String {
        switch self {
        case .rising:
            return "arrow.up"
        case .falling:
            return "arrow.down"
        case .steady:
            return "minus"
        }
    }
}
