//
//  WeatherCard.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/4.
//

import SwiftUI

/// 天气卡片组件 - 展示天气信息并支持刷新和编辑
struct WeatherCard: View {
    let weather: WeatherSnapshot?
    let isLoading: Bool
    let showTimeChangedWarning: Bool  // 显示时间改变提示
    let onRefresh: () -> Void
    let onEdit: () -> Void
    let onFetch: (() -> Void)?  // 用于首次获取天气
    
    @State private var isExpanded = false
    
    var body: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 12) {
                // 标题栏
                HStack {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundStyle(Color.accentPrimary)
                    Text("天气信息")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    
                    if weather != nil {
                        // 刷新和编辑按钮
                        HStack(spacing: 8) {
                            Button {
                                onRefresh()
                            } label: {
                                Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.accentPrimary)
                                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                                    .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                            }
                            .disabled(isLoading)
                            
                            Button {
                                onEdit()
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.accentPrimary)
                            }
                        }
                    }
                }
                
                if let weather = weather {
                    // 有天气数据
                    VStack(alignment: .leading, spacing: 12) {
                        // 时间改变提示
                        if showTimeChangedWarning {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("开始时间已改变，建议刷新天气")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        // 主要信息
                        HStack(spacing: 16) {
                            // 温度
                            VStack(alignment: .leading, spacing: 4) {
                                Text("温度")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                                Text("\(String(format: "%.1f", weather.temperature))°C")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            // 气压
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("气压")
                                        .font(.caption)
                                        .foregroundStyle(Color.textTertiary)
                                    Image(systemName: weather.pressureTrend.icon)
                                        .font(.caption2)
                                        .foregroundStyle(Color.textTertiary)
                                }
                                Text("\(String(format: "%.0f", weather.pressure)) hPa")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.textPrimary)
                            }
                            
                            Spacer()
                        }
                        
                        // 展开显示更多信息
                        if isExpanded {
                            Divider()
                            
                            VStack(spacing: 8) {
                                weatherDetailRow(icon: "humidity.fill", label: "湿度", value: "\(String(format: "%.0f", weather.humidity))%")
                                weatherDetailRow(icon: "wind", label: "风速", value: "\(String(format: "%.1f", weather.windSpeed)) m/s")
                                weatherDetailRow(icon: "cloud.fill", label: "天气", value: weather.condition)
                                if !weather.location.isEmpty {
                                    weatherDetailRow(icon: "location.fill", label: "位置", value: weather.location)
                                }
                            }
                        }
                        
                        // 展开/收起按钮
                        Button {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text(isExpanded ? "收起" : "查看详情")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentPrimary)
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(Color.accentPrimary)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // 手动编辑提示
                        if weather.isManuallyEdited {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.statusInfo)
                                Text("已手动编辑")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                } else if isLoading {
                    // 加载中
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("正在获取天气...")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.leading, 8)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    
                } else {
                    // 未获取天气
                    VStack(spacing: 12) {
                        Text("未关联天气数据")
                            .font(.subheadline)
                            .foregroundStyle(Color.textTertiary)
                        
                        if let onFetch = onFetch {
                            Button {
                                onFetch()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("获取天气")
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentPrimary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func weatherDetailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 50, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 有天气数据 - 时间改变提示
        WeatherCard(
            weather: {
                let w = WeatherSnapshot()
                w.temperature = 23.5
                w.pressure = 1013.25
                w.humidity = 65
                w.windSpeed = 3.2
                w.condition = "晴天"
                w.location = "北京"
                return w
            }(),
            isLoading: false,
            showTimeChangedWarning: true,
            onRefresh: {},
            onEdit: {},
            onFetch: {}
        )
        
        // 有天气数据 - 正常
        WeatherCard(
            weather: {
                let w = WeatherSnapshot()
                w.temperature = 23.5
                w.pressure = 1013.25
                w.humidity = 65
                w.windSpeed = 3.2
                w.condition = "晴天"
                w.location = "北京"
                return w
            }(),
            isLoading: false,
            showTimeChangedWarning: false,
            onRefresh: {},
            onEdit: {},
            onFetch: {}
        )
        
        // 加载中
        WeatherCard(
            weather: nil,
            isLoading: true,
            showTimeChangedWarning: false,
            onRefresh: {},
            onEdit: {},
            onFetch: {}
        )
        
        // 未获取
        WeatherCard(
            weather: nil,
            isLoading: false,
            showTimeChangedWarning: false,
            onRefresh: {},
            onEdit: {},
            onFetch: {}
        )
    }
    .padding()
}
