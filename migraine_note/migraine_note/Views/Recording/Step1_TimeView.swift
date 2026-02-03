//
//  Step1_TimeView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct Step1_TimeView: View {
    @Bindable var viewModel: RecordingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 页面标题和说明
            VStack(alignment: .leading, spacing: 8) {
                Text("记录时间")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.labelPrimary)
                
                Text("记录发作的开始和结束时间")
                    .font(.subheadline)
                    .foregroundStyle(Color.labelSecondary)
            }
            .padding(.horizontal, 4)
            
            // 开始时间
            EmotionalCard(style: .default) {
                HStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(Color.primary)
                        .frame(width: 40, height: 40)
                        .background(Color.primary.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("开始时间")
                            .font(.headline)
                            .foregroundStyle(Color.labelPrimary)
                        
                        DatePicker(
                            "选择开始时间",
                            selection: $viewModel.startTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }
            }
            
            // 状态选择
            VStack(alignment: .leading, spacing: 12) {
                Text("发作状态")
                    .font(.headline)
                    .foregroundStyle(Color.labelPrimary)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 12) {
                    StatusToggle(
                        title: "进行中",
                        icon: "play.circle.fill",
                        isSelected: viewModel.isOngoing
                    ) {
                        viewModel.isOngoing = true
                        viewModel.endTime = nil
                    }
                    
                    StatusToggle(
                        title: "已结束",
                        icon: "stop.circle.fill",
                        isSelected: !viewModel.isOngoing
                    ) {
                        viewModel.isOngoing = false
                        if viewModel.endTime == nil {
                            viewModel.endTime = Date()
                        }
                    }
                }
            }
            
            // 结束时间（仅在已结束时显示）
            if !viewModel.isOngoing {
                EmotionalCard(style: .default) {
                    HStack(spacing: 16) {
                        Image(systemName: "flag.checkered.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.statusSuccess)
                            .frame(width: 40, height: 40)
                            .background(Color.statusSuccess.opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("结束时间")
                                .font(.headline)
                                .foregroundStyle(Color.labelPrimary)
                            
                            DatePicker(
                                "选择结束时间",
                                selection: Binding(
                                    get: { viewModel.endTime ?? Date() },
                                    set: { viewModel.endTime = $0 }
                                ),
                                in: viewModel.startTime...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            
                            if let duration = calculateDuration() {
                                HStack(spacing: 6) {
                                    Image(systemName: "timer")
                                        .font(.caption)
                                    Text("持续 \(duration)")
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.primary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isOngoing)
    }
    
    private func calculateDuration() -> String? {
        guard let endTime = viewModel.endTime else { return nil }
        let duration = endTime.timeIntervalSince(viewModel.startTime)
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// MARK: - 状态切换按钮

struct StatusToggle: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .white : Color.labelSecondary)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : Color.labelPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                isSelected ? 
                    AnyShapeStyle(Color.primary) : 
                    AnyShapeStyle(Color.backgroundSecondary)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var viewModel = RecordingViewModel(
            modelContext: ModelContext(
                try! ModelContainer(for: AttackRecord.self, configurations: .init(isStoredInMemoryOnly: true))
            )
        )
        
        var body: some View {
            ScrollView {
                Step1_TimeView(viewModel: viewModel)
                    .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return PreviewContainer()
}
