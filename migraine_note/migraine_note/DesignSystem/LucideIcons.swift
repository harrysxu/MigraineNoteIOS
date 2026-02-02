//
//  LucideIcons.swift
//  migraine_note
//
//  Created on 2026/2/2.
//
//  Lucide图标集成
//  官网：https://lucide.dev/
//
//  使用说明：
//  1. 从 Lucide 官网下载需要的 SVG 图标
//  2. 将 SVG 文件放置在 Assets.xcassets/Lucide/ 文件夹中
//  3. 确保 SVG 渲染模式设置为 "Template Image"
//  4. 使用下面的枚举访问图标
//

import SwiftUI

// MARK: - Lucide图标枚举

/// Lucide图标枚举 - 精选医疗健康相关图标
enum LucideIcon: String, CaseIterable {
    // MARK: 医疗健康
    case pill = "pill"
    case pillBottle = "pill-bottle"
    case activity = "activity"
    case heart = "heart"
    case heartPulse = "heart-pulse"
    case brain = "brain"
    case droplet = "droplet"
    case thermometer = "thermometer"
    case stethoscope = "stethoscope"
    case syringe = "syringe"
    
    // MARK: 记录相关
    case calendar = "calendar"
    case calendarDays = "calendar-days"
    case clock = "clock"
    case edit = "edit"
    case save = "save"
    case trash = "trash-2"
    case filePlus = "file-plus"
    case fileText = "file-text"
    
    // MARK: 数据分析
    case chartBar = "bar-chart"
    case chartLine = "line-chart"
    case trendingUp = "trending-up"
    case trendingDown = "trending-down"
    case pieChart = "pie-chart"
    
    // MARK: 情感化图标
    case sun = "sun"
    case moon = "moon"
    case cloud = "cloud"
    case cloudRain = "cloud-rain"
    case wind = "wind"
    case smile = "smile"
    case frown = "frown"
    case meh = "meh"
    
    // MARK: 界面操作
    case plus = "plus"
    case minus = "minus"
    case check = "check"
    case x = "x"
    case chevronRight = "chevron-right"
    case chevronLeft = "chevron-left"
    case chevronDown = "chevron-down"
    case chevronUp = "chevron-up"
    case arrowRight = "arrow-right"
    case arrowLeft = "arrow-left"
    
    // MARK: 功能图标
    case settings = "settings"
    case user = "user"
    case bell = "bell"
    case search = "search"
    case filter = "filter"
    case download = "download"
    case upload = "upload"
    case share = "share-2"
    case info = "info"
    case alertTriangle = "alert-triangle"
    case alertCircle = "alert-circle"
    
    /// 图标图片（从Assets加载）
    var image: Image {
        // 首先尝试从Lucide文件夹加载
        Image("Lucide/\(rawValue)")
    }
    
    /// SF Symbols后备图标（当Lucide图标不存在时使用）
    var sfSymbolFallback: String {
        switch self {
        // 医疗健康
        case .pill: return "pill.fill"
        case .pillBottle: return "cross.case.fill"
        case .activity: return "waveform.path.ecg"
        case .heart: return "heart.fill"
        case .heartPulse: return "heart.text.square.fill"
        case .brain: return "brain.head.profile"
        case .droplet: return "drop.fill"
        case .thermometer: return "thermometer.medium"
        case .stethoscope: return "stethoscope"
        case .syringe: return "syringe.fill"
            
        // 记录相关
        case .calendar: return "calendar"
        case .calendarDays: return "calendar.badge.clock"
        case .clock: return "clock.fill"
        case .edit: return "pencil"
        case .save: return "square.and.arrow.down.fill"
        case .trash: return "trash.fill"
        case .filePlus: return "doc.badge.plus"
        case .fileText: return "doc.text.fill"
            
        // 数据分析
        case .chartBar: return "chart.bar.fill"
        case .chartLine: return "chart.xyaxis.line"
        case .trendingUp: return "chart.line.uptrend.xyaxis"
        case .trendingDown: return "chart.line.downtrend.xyaxis"
        case .pieChart: return "chart.pie.fill"
            
        // 情感化
        case .sun: return "sun.max.fill"
        case .moon: return "moon.fill"
        case .cloud: return "cloud.fill"
        case .cloudRain: return "cloud.rain.fill"
        case .wind: return "wind"
        case .smile: return "face.smiling"
        case .frown: return "face.frowning"
        case .meh: return "face.dashed"
            
        // 界面操作
        case .plus: return "plus"
        case .minus: return "minus"
        case .check: return "checkmark"
        case .x: return "xmark"
        case .chevronRight: return "chevron.right"
        case .chevronLeft: return "chevron.left"
        case .chevronDown: return "chevron.down"
        case .chevronUp: return "chevron.up"
        case .arrowRight: return "arrow.right"
        case .arrowLeft: return "arrow.left"
            
        // 功能图标
        case .settings: return "gearshape.fill"
        case .user: return "person.fill"
        case .bell: return "bell.fill"
        case .search: return "magnifyingglass"
        case .filter: return "line.3.horizontal.decrease.circle.fill"
        case .download: return "arrow.down.circle.fill"
        case .upload: return "arrow.up.circle.fill"
        case .share: return "square.and.arrow.up"
        case .info: return "info.circle.fill"
        case .alertTriangle: return "exclamationmark.triangle.fill"
        case .alertCircle: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Lucide图标视图

/// Lucide图标视图组件
struct LucideIconView: View {
    let icon: LucideIcon
    var size: CGFloat
    var color: Color
    var useSFSymbolFallback: Bool
    
    init(
        _ icon: LucideIcon,
        size: CGFloat = 24,
        color: Color = .textPrimary,
        useSFSymbolFallback: Bool = true
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.useSFSymbolFallback = useSFSymbolFallback
    }
    
    var body: some View {
        // 由于我们还没有实际的Lucide SVG文件，
        // 目前使用SF Symbols作为后备
        if useSFSymbolFallback {
            Image(systemName: icon.sfSymbolFallback)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
        } else {
            icon.image
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
        }
    }
}

// MARK: - View扩展

extension View {
    /// 便捷方法：显示Lucide图标
    func lucideIcon(
        _ icon: LucideIcon,
        size: CGFloat = 24,
        color: Color = .textPrimary
    ) -> some View {
        LucideIconView(icon, size: size, color: color)
    }
}

// MARK: - 预览

#Preview("Lucide Icons Grid") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            ForEach(LucideIcon.allCases, id: \.self) { icon in
                VStack(spacing: 8) {
                    LucideIconView(icon, size: 32, color: .accentPrimary)
                    Text(icon.rawValue)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}

#Preview("Icon Sizes") {
    VStack(spacing: 30) {
        LucideIconView(.heart, size: 16, color: .statusError)
        LucideIconView(.heart, size: 24, color: .statusError)
        LucideIconView(.heart, size: 32, color: .statusError)
        LucideIconView(.heart, size: 48, color: .statusError)
        LucideIconView(.heart, size: 64, color: .statusError)
    }
    .padding()
    .background(Color.backgroundPrimary)
}
