//
//  WeatherAttribution.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/19.
//

import SwiftUI
import WeatherKit

/// Apple Weather 归属组件 - 满足 WeatherKit 使用要求
struct WeatherAttribution: View {
    enum Style {
        case compact  // 紧凑样式：适用于天气卡片底部
        case full     // 完整样式：适用于设置/关于页面
    }
    
    let style: Style
    @State private var attributionLogoURL: URL?
    @State private var attributionLink: URL?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            switch style {
            case .compact:
                compactView
            case .full:
                fullView
            }
        }
        .task {
            await loadAttribution()
        }
        .onChange(of: colorScheme) { _, _ in
            Task {
                await loadAttribution()
            }
        }
    }
    
    // MARK: - Compact View
    
    private var compactView: some View {
        HStack(spacing: 6) {
            if let logoURL = attributionLogoURL {
                AsyncImage(url: logoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .controlSize(.mini)
                }
                .frame(height: 14)  // 更小的高度，让组合标识更精致
            } else {
                // Fallback: 使用 SF Symbol 云图标 + 文字
                HStack(spacing: 3) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 10))
                    Text("Weather")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
            }
            
            if let link = attributionLink {
                Link(destination: link) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - Full View
    
    private var fullView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let logoURL = attributionLogoURL {
                    AsyncImage(url: logoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 24)  // 适中的高度，既清晰又不过大
                } else {
                    // Fallback: 使用 SF Symbol
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.title3)
                        Text("Weather")
                            .font(.title3)
                    }
                    .foregroundStyle(Color.accentPrimary)
                }
                
                Spacer()
            }
            
            Text(String(localized: "weather.attribution"))
                .font(.body)
                .foregroundStyle(Color.textSecondary)
            
            if let link = attributionLink {
                Link(destination: link) {
                    HStack(spacing: 6) {
                        Text(String(localized: "component.weather.attributionLink"))
                            .font(.subheadline)
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Load Attribution
    
    private func loadAttribution() async {
        do {
            let attribution = try await WeatherService.shared.attribution
            
            // Swift API 只提供 combinedMark（图标+文字组合）
            let logoURL: URL?
            if colorScheme == .dark {
                logoURL = attribution.combinedMarkDarkURL
            } else {
                logoURL = attribution.combinedMarkLightURL
            }
            
            await MainActor.run {
                self.attributionLogoURL = logoURL
                // Apple WeatherKit 法律归属链接
                self.attributionLink = URL(string: "https://weatherkit.apple.com/legal-attribution.html")
            }
        } catch {
            // 如果无法获取归属信息，使用 fallback
            await MainActor.run {
                self.attributionLogoURL = nil
                self.attributionLink = URL(string: "https://weatherkit.apple.com/legal-attribution.html")
            }
        }
    }
}

#Preview("Compact Style - Light") {
    VStack {
        WeatherAttribution(style: .compact)
            .padding()
            .background(Color.gray.opacity(0.1))
    }
    .preferredColorScheme(.light)
}

#Preview("Compact Style - Dark") {
    VStack {
        WeatherAttribution(style: .compact)
            .padding()
            .background(Color.gray.opacity(0.1))
    }
    .preferredColorScheme(.dark)
}

#Preview("Full Style - Light") {
    List {
        Section {
            WeatherAttribution(style: .full)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Full Style - Dark") {
    List {
        Section {
            WeatherAttribution(style: .full)
        }
    }
    .preferredColorScheme(.dark)
}
