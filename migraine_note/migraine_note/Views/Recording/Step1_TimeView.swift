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
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 开始时间
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("开始时间")
                        .font(.headline)
                    
                    DatePicker(
                        "选择开始时间",
                        selection: $viewModel.startTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
            }
            
            // 状态选择
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("发作状态")
                        .font(.headline)
                    
                    HStack(spacing: Spacing.md) {
                        StatusToggle(
                            title: "进行中",
                            isSelected: viewModel.isOngoing
                        ) {
                            viewModel.isOngoing = true
                            viewModel.endTime = nil
                        }
                        
                        StatusToggle(
                            title: "已结束",
                            isSelected: !viewModel.isOngoing
                        ) {
                            viewModel.isOngoing = false
                            if viewModel.endTime == nil {
                                viewModel.endTime = Date()
                            }
                        }
                    }
                }
            }
            
            // 结束时间（仅在已结束时显示）
            if !viewModel.isOngoing {
                InfoCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("结束时间")
                            .font(.headline)
                        
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
                            Text("持续时长: \(duration)")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
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
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.accentPrimary : Color.backgroundTertiary)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .cornerRadius(CornerRadius.sm)
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
