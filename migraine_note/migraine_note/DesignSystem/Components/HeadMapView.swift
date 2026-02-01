//
//  HeadMapView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

/// 头部疼痛部位交互式选择器
/// 提供前、后、左、右四个视角，用户可以点击选择疼痛的具体部位
struct HeadMapView: View {
    @Binding var selectedLocations: Set<PainLocation>
    @State private var selectedView: HeadView = .front
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // 视图切换按钮
            viewSwitcher
            
            // 头部图示
            headDiagram
                .frame(height: 280)
            
            // 已选择的部位列表
            if !selectedLocations.isEmpty {
                selectedLocationsList
            }
        }
    }
    
    // MARK: - 视图切换器
    
    private var viewSwitcher: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(HeadView.allCases, id: \.self) { view in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedView = view
                    }
                } label: {
                    Text(view.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedView == view ? .semibold : .regular)
                        .foregroundStyle(selectedView == view ? Color.textPrimary : Color.textSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            selectedView == view ? Color.accentPrimary.opacity(0.15) : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - 头部图示
    
    private var headDiagram: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.backgroundSecondary)
                
                // 根据选择的视角显示不同的头部轮廓
                switch selectedView {
                case .front:
                    FrontHeadView(
                        selectedLocations: $selectedLocations,
                        size: geometry.size
                    )
                case .back:
                    BackHeadView(
                        selectedLocations: $selectedLocations,
                        size: geometry.size
                    )
                case .left:
                    SideHeadView(
                        selectedLocations: $selectedLocations,
                        size: geometry.size,
                        isLeft: true
                    )
                case .right:
                    SideHeadView(
                        selectedLocations: $selectedLocations,
                        size: geometry.size,
                        isLeft: false
                    )
                }
            }
        }
    }
    
    // MARK: - 已选部位列表
    
    private var selectedLocationsList: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("已选择的部位：")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            
            let sortedLocations = Array(selectedLocations).sorted(by: { $0.rawValue < $1.rawValue })
            FlowLayout(spacing: Spacing.xs) {
                ForEach(sortedLocations, id: \.self) { location in
                    locationChip(for: location)
                }
            }
        }
        .padding(.top, Spacing.xs)
    }
    
    private func locationChip(for location: PainLocation) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = selectedLocations.remove(location)
            }
        } label: {
            Text(location.displayName)
                .font(.caption)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, 4)
                .background(Color.accentPrimary)
                .foregroundStyle(.white)
                .cornerRadius(CornerRadius.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 视角枚举

enum HeadView: String, CaseIterable {
    case front = "正面"
    case back = "后面"
    case left = "左侧"
    case right = "右侧"
}

// MARK: - 正面头部视图

struct FrontHeadView: View {
    @Binding var selectedLocations: Set<PainLocation>
    let size: CGSize
    
    var body: some View {
        ZStack {
            // 头部轮廓
            headOutline
            
            // 可点击区域
            clickableRegions
        }
    }
    
    private var headOutline: some View {
        Path { path in
            let width = size.width
            let height = size.height
            let centerX = width / 2
            
            // 绘制椭圆形头部轮廓
            path.addEllipse(in: CGRect(
                x: centerX - width * 0.3,
                y: height * 0.15,
                width: width * 0.6,
                height: height * 0.7
            ))
        }
        .stroke(Color.textTertiary, lineWidth: 2)
    }
    
    private var clickableRegions: some View {
        ZStack {
            // 前额
            createRegion(
                location: .forehead,
                x: size.width / 2,
                y: size.height * 0.25,
                width: size.width * 0.4,
                height: size.height * 0.15
            )
            
            // 左太阳穴
            createRegion(
                location: .leftTemple,
                x: size.width * 0.25,
                y: size.height * 0.4,
                width: size.width * 0.15,
                height: size.height * 0.15
            )
            
            // 右太阳穴
            createRegion(
                location: .rightTemple,
                x: size.width * 0.75,
                y: size.height * 0.4,
                width: size.width * 0.15,
                height: size.height * 0.15
            )
            
            // 左眼眶
            createRegion(
                location: .leftOrbit,
                x: size.width * 0.35,
                y: size.height * 0.35,
                width: size.width * 0.12,
                height: size.height * 0.1
            )
            
            // 右眼眶
            createRegion(
                location: .rightOrbit,
                x: size.width * 0.65,
                y: size.height * 0.35,
                width: size.width * 0.12,
                height: size.height * 0.1
            )
            
            // 头顶
            createRegion(
                location: .vertex,
                x: size.width / 2,
                y: size.height * 0.15,
                width: size.width * 0.3,
                height: size.height * 0.12
            )
        }
    }
    
    private func createRegion(location: PainLocation, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedLocations.contains(location)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedLocations.remove(location)
                } else {
                    selectedLocations.insert(location)
                }
            }
        } label: {
            ZStack {
                // 区域背景
                Circle()
                    .fill(isSelected ? Color.statusError.opacity(0.3) : Color.accentPrimary.opacity(0.1))
                    .frame(width: width, height: height)
                
                // 区域标签
                Text(location.shortName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.statusError : Color.textSecondary)
            }
        }
        .position(x: x, y: y)
    }
}

// MARK: - 后面头部视图

struct BackHeadView: View {
    @Binding var selectedLocations: Set<PainLocation>
    let size: CGSize
    
    var body: some View {
        ZStack {
            // 头部轮廓
            headOutline
            
            // 可点击区域
            clickableRegions
        }
    }
    
    private var headOutline: some View {
        Path { path in
            let width = size.width
            let height = size.height
            let centerX = width / 2
            
            // 绘制椭圆形头部轮廓
            path.addEllipse(in: CGRect(
                x: centerX - width * 0.3,
                y: height * 0.15,
                width: width * 0.6,
                height: height * 0.7
            ))
        }
        .stroke(Color.textTertiary, lineWidth: 2)
    }
    
    private var clickableRegions: some View {
        ZStack {
            // 后脑勺（枕部）
            createRegion(
                location: .occipital,
                x: size.width / 2,
                y: size.height * 0.55,
                width: size.width * 0.35,
                height: size.height * 0.25
            )
            
            // 颈部
            createRegion(
                location: .neck,
                x: size.width / 2,
                y: size.height * 0.78,
                width: size.width * 0.25,
                height: size.height * 0.15
            )
            
            // 头顶（从后面看）
            createRegion(
                location: .vertex,
                x: size.width / 2,
                y: size.height * 0.2,
                width: size.width * 0.3,
                height: size.height * 0.15
            )
        }
    }
    
    private func createRegion(location: PainLocation, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedLocations.contains(location)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedLocations.remove(location)
                } else {
                    selectedLocations.insert(location)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.statusError.opacity(0.3) : Color.accentPrimary.opacity(0.1))
                    .frame(width: width, height: height)
                
                Text(location.shortName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.statusError : Color.textSecondary)
            }
        }
        .position(x: x, y: y)
    }
}

// MARK: - 侧面头部视图

struct SideHeadView: View {
    @Binding var selectedLocations: Set<PainLocation>
    let size: CGSize
    let isLeft: Bool
    
    var body: some View {
        ZStack {
            // 头部轮廓
            headOutline
            
            // 可点击区域
            clickableRegions
        }
        .scaleEffect(x: isLeft ? 1 : -1, y: 1) // 右侧时水平翻转
    }
    
    private var headOutline: some View {
        Path { path in
            let width = size.width
            let height = size.height
            
            // 绘制侧面头部轮廓（简化的曲线）
            path.move(to: CGPoint(x: width * 0.3, y: height * 0.15))
            path.addQuadCurve(
                to: CGPoint(x: width * 0.65, y: height * 0.4),
                control: CGPoint(x: width * 0.7, y: height * 0.2)
            )
            path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.7))
            path.addQuadCurve(
                to: CGPoint(x: width * 0.45, y: height * 0.85),
                control: CGPoint(x: width * 0.6, y: height * 0.8)
            )
            path.addQuadCurve(
                to: CGPoint(x: width * 0.3, y: height * 0.75),
                control: CGPoint(x: width * 0.35, y: height * 0.85)
            )
            path.addQuadCurve(
                to: CGPoint(x: width * 0.3, y: height * 0.15),
                control: CGPoint(x: width * 0.2, y: height * 0.4)
            )
        }
        .stroke(Color.textTertiary, lineWidth: 2)
    }
    
    private var clickableRegions: some View {
        ZStack {
            let temple: PainLocation = isLeft ? .leftTemple : .rightTemple
            
            // 太阳穴
            createRegion(
                location: temple,
                x: size.width * 0.6,
                y: size.height * 0.4,
                width: size.width * 0.15,
                height: size.height * 0.15
            )
            
            // 前额（侧面）
            createRegion(
                location: .forehead,
                x: size.width * 0.55,
                y: size.height * 0.25,
                width: size.width * 0.15,
                height: size.height * 0.12
            )
            
            // 后脑勺（侧面）
            createRegion(
                location: .occipital,
                x: size.width * 0.35,
                y: size.height * 0.55,
                width: size.width * 0.15,
                height: size.height * 0.2
            )
            
            // 颈部
            createRegion(
                location: .neck,
                x: size.width * 0.4,
                y: size.height * 0.78,
                width: size.width * 0.12,
                height: size.height * 0.15
            )
            
            // 头顶
            createRegion(
                location: .vertex,
                x: size.width * 0.45,
                y: size.height * 0.17,
                width: size.width * 0.15,
                height: size.height * 0.1
            )
        }
    }
    
    private func createRegion(location: PainLocation, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedLocations.contains(location)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedLocations.remove(location)
                } else {
                    selectedLocations.insert(location)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.statusError.opacity(0.3) : Color.accentPrimary.opacity(0.1))
                    .frame(width: width, height: height)
                
                Text(location.shortName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.statusError : Color.textSecondary)
            }
        }
        .position(x: x, y: y)
    }
}

// MARK: - PainLocation 扩展

extension PainLocation {
    /// 短名称，用于在图示上显示
    var shortName: String {
        switch self {
        case .forehead: return "前额"
        case .leftTemple: return "左颞"
        case .rightTemple: return "右颞"
        case .occipital: return "枕部"
        case .vertex: return "头顶"
        case .leftOrbit: return "左眼"
        case .rightOrbit: return "右眼"
        case .leftParietal: return "左顶"
        case .rightParietal: return "右顶"
        case .neck: return "颈部"
        case .wholehead: return "全头"
        }
    }
}

// MARK: - 预览

#Preview("正面视图") {
    struct PreviewContainer: View {
        @State private var selectedLocations: Set<PainLocation> = [.forehead, .leftTemple]
        
        var body: some View {
            VStack {
                HeadMapView(selectedLocations: $selectedLocations)
                    .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return PreviewContainer()
}

#Preview("空状态") {
    struct PreviewContainer: View {
        @State private var selectedLocations: Set<PainLocation> = []
        
        var body: some View {
            VStack {
                HeadMapView(selectedLocations: $selectedLocations)
                    .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return PreviewContainer()
}
