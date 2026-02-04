//
//  SymbolsManager.swift
//  migraine_note
//
//  Created on 2026/2/3.
//  SF Symbols 7 图标管理系统
//

import SwiftUI

// MARK: - SF Symbol 枚举

/// SF Symbol 图标枚举 - 精选医疗健康相关图标
enum AppSymbol: String, CaseIterable {
    // MARK: 医疗健康
    case pill = "pill.fill"
    case pillBottle = "cross.case.fill"
    case activity = "waveform.path.ecg"
    case heart = "heart.fill"
    case heartPulse = "heart.text.square.fill"
    case brain = "brain.head.profile"
    case droplet = "drop.fill"
    case thermometer = "thermometer.medium"
    case stethoscope = "stethoscope"
    case syringe = "syringe.fill"
    
    // MARK: 记录相关
    case calendar = "calendar"
    case calendarDays = "calendar.badge.clock"
    case clock = "clock.fill"
    case edit = "pencil"
    case save = "square.and.arrow.down.fill"
    case trash = "trash.fill"
    case filePlus = "doc.badge.plus"
    case fileText = "doc.text.fill"
    
    // MARK: 数据分析
    case chartBar = "chart.bar.fill"
    case chartLine = "chart.xyaxis.line"
    case trendingUp = "chart.line.uptrend.xyaxis"
    case trendingDown = "chart.line.downtrend.xyaxis"
    case pieChart = "chart.pie.fill"
    
    // MARK: 情感化图标
    case sun = "sun.max.fill"
    case moon = "moon.fill"
    case cloud = "cloud.fill"
    case cloudRain = "cloud.rain.fill"
    case wind = "wind"
    case smile = "face.smiling"
    case frown = "face.frowning"
    case meh = "face.dashed"
    
    // MARK: 界面操作
    case plus = "plus"
    case plusCircle = "plus.circle.fill"
    case minus = "minus"
    case check = "checkmark"
    case checkCircle = "checkmark.circle.fill"
    case x = "xmark"
    case xCircle = "xmark.circle.fill"
    case chevronRight = "chevron.right"
    case chevronLeft = "chevron.left"
    case chevronDown = "chevron.down"
    case chevronUp = "chevron.up"
    case arrowRight = "arrow.right"
    case arrowLeft = "arrow.left"
    
    // MARK: 功能图标
    case settings = "gearshape.fill"
    case user = "person.fill"
    case bell = "bell.fill"
    case search = "magnifyingglass"
    case filter = "line.3.horizontal.decrease.circle.fill"
    case download = "arrow.down.circle.fill"
    case upload = "arrow.up.circle.fill"
    case share = "square.and.arrow.up"
    case info = "info.circle.fill"
    case alertTriangle = "exclamationmark.triangle.fill"
    case alertCircle = "exclamationmark.circle.fill"
    
    // MARK: 加载状态
    case loading = "arrow.trianglehead.2.clockwise.rotate.90"
    case refresh = "arrow.clockwise"
    
    /// 根据类型获取建议的颜色
    var suggestedColor: Color {
        switch self {
        case .heart, .heartPulse:
            return Color.statusError
        case .brain:
            return Color.accentPrimary
        case .pill, .pillBottle, .syringe:
            return Color.accentSecondary
        case .check, .checkCircle:
            return Color.statusSuccess
        case .alertTriangle, .alertCircle:
            return Color.statusWarning
        case .x, .xCircle, .trash:
            return Color.statusError
        case .sun:
            return Color.warmAccent
        case .moon:
            return Color.accentSecondary
        case .smile:
            return Color.statusSuccess
        case .frown:
            return Color.statusError
        default:
            return Color.textPrimary
        }
    }
    
    /// 根据类型获取建议的渐变色
    var suggestedGradient: [Color] {
        switch self {
        case .heart, .heartPulse:
            return [Color.red, Color.pink]
        case .brain:
            return [Color.accentPrimary, Color.accentSecondary]
        case .pill, .pillBottle:
            return [Color.accentSecondary, Color.accentPrimary]
        case .check, .checkCircle:
            return [Color.statusSuccess, Color.statusSuccess.opacity(0.7)]
        case .sun:
            return [Color.yellow, Color.warmAccent]
        case .moon:
            return [Color.accentSecondary, Color.accentPrimary]
        case .trendingUp:
            return [Color.statusSuccess, Color.accentPrimary]
        case .trendingDown:
            return [Color.statusError, Color.gentlePink]
        default:
            return [suggestedColor, suggestedColor.opacity(0.7)]
        }
    }
}

// MARK: - Symbol 动画效果

/// Symbol 动画效果枚举
enum SymbolAnimationEffect {
    case bounce          // 弹跳效果
    case pulse           // 脉冲效果
    case variableColor   // 颜色渐变效果
    case scale           // 缩放效果
    case wiggle          // 摇摆效果
    case rotate          // 旋转效果
    case breathe         // 呼吸效果
}

// MARK: - Symbol 视图组件

/// SF Symbol 视图组件 - 支持渐变和动画
struct SymbolView: View {
    let symbol: AppSymbol
    var size: CGFloat
    var color: Color?
    var useGradient: Bool
    var animation: SymbolAnimationEffect?
    
    init(
        _ symbol: AppSymbol,
        size: CGFloat = 24,
        color: Color? = nil,
        useGradient: Bool = false,
        animation: SymbolAnimationEffect? = nil
    ) {
        self.symbol = symbol
        self.size = size
        self.color = color
        self.useGradient = useGradient
        self.animation = animation
    }
    
    var body: some View {
        let image = Image(systemName: symbol.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
        
        Group {
            if useGradient {
                image
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        LinearGradient(
                            colors: symbol.suggestedGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                image
                    .foregroundStyle(color ?? symbol.suggestedColor)
            }
        }
        .applySymbolEffect(animation)
    }
}

// MARK: - View 扩展

extension View {
    /// 应用 Symbol 动画效果
    @ViewBuilder
    func applySymbolEffect(_ effect: SymbolAnimationEffect?) -> some View {
        if let effect = effect {
            switch effect {
            case .bounce:
                if #available(iOS 17.0, *) {
                    self.symbolEffect(.bounce, value: UUID())
                } else {
                    self
                }
            case .pulse:
                if #available(iOS 17.0, *) {
                    self.symbolEffect(.pulse)
                } else {
                    self
                }
            case .variableColor:
                if #available(iOS 17.0, *) {
                    self.symbolEffect(.variableColor.iterative)
                } else {
                    self
                }
            case .scale:
                if #available(iOS 17.0, *) {
                    self.symbolEffect(.scale.up)
                } else {
                    self
                }
            case .wiggle:
                if #available(iOS 18.0, *) {
                    self.symbolEffect(.wiggle)
                } else {
                    self
                }
            case .rotate:
                if #available(iOS 18.0, *) {
                    self.symbolEffect(.rotate)
                } else {
                    self
                }
            case .breathe:
                if #available(iOS 18.0, *) {
                    self.symbolEffect(.breathe)
                } else {
                    self
                }
            }
        } else {
            self
        }
    }
    
    /// 便捷方法：显示带渐变的 Symbol
    func symbol(
        _ symbol: AppSymbol,
        size: CGFloat = 24,
        gradient: Bool = false
    ) -> some View {
        HStack {
            self
            SymbolView(symbol, size: size, useGradient: gradient)
        }
    }
}

// MARK: - 预览

#Preview("Symbol Gallery") {
    ScrollView {
        VStack(spacing: 24) {
            // 基础图标
            sectionView(title: "基础图标") {
                HStack(spacing: 20) {
                    SymbolView(.heart, size: 32)
                    SymbolView(.brain, size: 32)
                    SymbolView(.pill, size: 32)
                    SymbolView(.calendar, size: 32)
                }
            }
            
            // 渐变图标
            sectionView(title: "渐变图标") {
                HStack(spacing: 20) {
                    SymbolView(.heart, size: 32, useGradient: true)
                    SymbolView(.brain, size: 32, useGradient: true)
                    SymbolView(.pill, size: 32, useGradient: true)
                    SymbolView(.trendingUp, size: 32, useGradient: true)
                }
            }
            
            // 动画图标
            if #available(iOS 17.0, *) {
                sectionView(title: "动画图标") {
                    HStack(spacing: 20) {
                        SymbolView(.heart, size: 32, useGradient: true, animation: .pulse)
                        SymbolView(.check, size: 32, useGradient: true, animation: .bounce)
                        SymbolView(.loading, size: 32, animation: .rotate)
                        SymbolView(.bell, size: 32, animation: .wiggle)
                    }
                }
            }
            
            // 所有图标网格
            sectionView(title: "所有图标") {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(AppSymbol.allCases, id: \.self) { symbol in
                        VStack(spacing: 4) {
                            SymbolView(symbol, size: 24, useGradient: true)
                            Text(String(describing: symbol))
                                .font(.caption2)
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 50)
                        }
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}

@ViewBuilder
private func sectionView<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.textPrimary)
        
        content()
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
    }
}

#Preview("Symbol Sizes") {
    VStack(spacing: 30) {
        SymbolView(.heart, size: 16, useGradient: true)
        SymbolView(.heart, size: 24, useGradient: true)
        SymbolView(.heart, size: 32, useGradient: true)
        SymbolView(.heart, size: 48, useGradient: true)
        SymbolView(.heart, size: 64, useGradient: true)
    }
    .padding()
    .background(Color.backgroundPrimary)
}
