//
//  IllustrationAssets.swift
//  migraine_note
//
//  Created on 2026/2/3.
//  管理 unDraw 开源插图资源
//
//  使用说明：
//  1. 访问 https://undraw.co/illustrations
//  2. 搜索并下载相关插图（SVG 格式）
//  3. 使用 Sketch/Figma 转换为 PDF 矢量格式
//  4. 导入到 Assets.xcassets/Illustrations/ 文件夹
//  5. 设置渲染模式为 "Template Image" 以支持颜色自定义
//

import SwiftUI

// MARK: - 插图枚举

/// unDraw 插图枚举 - 精选医疗健康相关插图
enum IllustrationAsset: String, CaseIterable {
    // MARK: 医疗健康
    case doctor = "undraw_doctor"
    case medicine = "undraw_medicine"
    case healthData = "undraw_health_data"
    case medical = "undraw_medical"
    case fitness = "undraw_fitness"
    
    // MARK: 空状态
    case noData = "undraw_no_data"
    case emptyState = "undraw_empty"
    case search = "undraw_search"
    case notFound = "undraw_not_found"
    case void = "undraw_void"
    
    // MARK: 成功反馈
    case celebration = "undraw_celebration"
    case checkmark = "undraw_completed"
    case success = "undraw_success"
    case goals = "undraw_goals"
    
    // MARK: 引导页
    case welcome = "undraw_welcome"
    case onboarding = "undraw_onboarding"
    case tutorial = "undraw_tutorial"
    
    // MARK: 其他
    case calendar = "undraw_calendar"
    case analytics = "undraw_analytics"
    case progress = "undraw_progress"
    
    /// 图片资源
    var image: Image {
        // 首先尝试从 Illustrations 文件夹加载
        Image("Illustrations/\(rawValue)")
    }
    
    /// SF Symbols 后备图标（当插图不存在时使用）
    var sfSymbolFallback: String {
        switch self {
        case .doctor, .medicine, .medical:
            return "cross.case.fill"
        case .healthData:
            return "chart.xyaxis.line"
        case .fitness:
            return "figure.walk"
        case .noData, .emptyState, .void:
            return "tray.fill"
        case .search:
            return "magnifyingglass"
        case .notFound:
            return "questionmark.folder.fill"
        case .celebration, .checkmark, .success:
            return "checkmark.circle.fill"
        case .goals:
            return "target"
        case .welcome, .onboarding, .tutorial:
            return "hand.wave.fill"
        case .calendar:
            return "calendar"
        case .analytics:
            return "chart.bar.fill"
        case .progress:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    /// 建议的主题色
    var suggestedColor: Color {
        switch self {
        case .doctor, .medicine, .medical, .healthData:
            return Color.accentPrimary
        case .celebration, .checkmark, .success, .goals:
            return Color.statusSuccess
        case .noData, .emptyState, .void, .notFound:
            return Color.textSecondary
        default:
            return Color.accentPrimary
        }
    }
}

// MARK: - 插图视图组件

/// 插图视图组件 - 支持自定义颜色和后备图标
struct IllustrationView: View {
    let illustration: IllustrationAsset
    var size: CGFloat
    var color: Color?
    var useFallback: Bool
    
    init(
        _ illustration: IllustrationAsset,
        size: CGFloat = 200,
        color: Color? = nil,
        useFallback: Bool = true
    ) {
        self.illustration = illustration
        self.size = size
        self.color = color
        self.useFallback = useFallback
    }
    
    var body: some View {
        // 由于实际的插图文件需要从 unDraw 下载，
        // 目前使用 SF Symbols 作为后备
        if useFallback {
            Image(systemName: illustration.sfSymbolFallback)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            color ?? illustration.suggestedColor,
                            (color ?? illustration.suggestedColor).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            illustration.image
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color ?? illustration.suggestedColor)
        }
    }
}

// MARK: - 增强版空状态视图（使用插图）

/// 增强版空状态视图 - 使用 unDraw 插图
struct IllustratedEmptyStateView: View {
    let illustration: IllustrationAsset
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            IllustrationView(illustration, size: 200)
                .opacity(0.8)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
        .padding()
    }
}

// MARK: - 插图卡片

/// 插图卡片 - 带插图的信息卡片
struct IllustrationCard: View {
    let illustration: IllustrationAsset
    let title: String
    let description: String
    var action: (() -> Void)?
    
    var body: some View {
        EmotionalCard(style: .liquidGlass) {
            HStack(spacing: 20) {
                IllustrationView(illustration, size: 80)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                    
                    if action != nil {
                        HStack(spacing: 4) {
                            Text("了解更多")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.accentPrimary)
                            
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundStyle(Color.accentPrimary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
        }
        .onTapGesture {
            action?()
        }
    }
}

// MARK: - 预览

#Preview("Illustrations Gallery") {
    ScrollView {
        VStack(spacing: 24) {
            Text("插图库预览")
                .font(.title.bold())
            
            Text("注意：实际插图需要从 unDraw 下载并导入")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(Array(IllustrationAsset.allCases.prefix(8)), id: \.self) { illustration in
                    VStack(spacing: 8) {
                        IllustrationView(illustration, size: 120)
                        
                        Text(String(describing: illustration))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}

#Preview("Empty State with Illustration") {
    IllustratedEmptyStateView(
        illustration: .noData,
        title: "暂无记录",
        message: "开始记录您的第一次偏头痛，帮助您更好地了解和管理症状",
        actionTitle: "开始记录",
        action: {}
    )
}

#Preview("Illustration Cards") {
    ScrollView {
        VStack(spacing: 16) {
            IllustrationCard(
                illustration: .healthData,
                title: "健康数据分析",
                description: "查看您的偏头痛趋势和模式，获取个性化建议",
                action: {}
            )
            
            IllustrationCard(
                illustration: .medicine,
                title: "用药管理",
                description: "记录用药时间和剂量，避免药物过度使用",
                action: {}
            )
            
            IllustrationCard(
                illustration: .goals,
                title: "健康目标",
                description: "设定健康目标并跟踪进度，改善生活质量",
                action: {}
            )
        }
        .padding()
    }
    .background(Color.backgroundPrimary)
}
