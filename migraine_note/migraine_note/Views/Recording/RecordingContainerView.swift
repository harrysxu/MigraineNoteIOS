//
//  RecordingContainerView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct RecordingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecordingViewModel
    
    let isEditMode: Bool
    
    init(modelContext: ModelContext) {
        _viewModel = State(initialValue: RecordingViewModel(modelContext: modelContext))
        self.isEditMode = false
    }
    
    init(viewModel: RecordingViewModel, isEditMode: Bool = false) {
        _viewModel = State(initialValue: viewModel)
        self.isEditMode = isEditMode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 进度指示器
            ProgressIndicator(currentStep: viewModel.currentStep)
                .padding()
            
            // 当前步骤内容
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    stepContent
                        .padding()
                }
            }
            
            // 底部导航按钮
            HStack(spacing: Spacing.md) {
                if viewModel.currentStep != .timeAndDuration {
                    SecondaryButton(title: "上一步") {
                        viewModel.previousStep()
                    }
                }
                
                if viewModel.currentStep == .interventions {
                    PrimaryButton(
                        title: isEditMode ? "保存" : "完成",
                        action: {
                            saveAndDismiss()
                        },
                        isEnabled: viewModel.canSave
                    )
                } else {
                    PrimaryButton(
                        title: "下一步",
                        action: {
                            viewModel.nextStep()
                        },
                        isEnabled: viewModel.canGoNext
                    )
                }
            }
            .padding()
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(isEditMode ? "编辑记录" : viewModel.currentStep.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !isEditMode {
                viewModel.startRecording()
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .timeAndDuration:
            Step1_TimeView(viewModel: viewModel)
        case .painAssessment:
            Step2_PainAssessmentView(viewModel: viewModel)
        case .symptoms:
            Step3_SymptomsView(viewModel: viewModel)
        case .triggers:
            Step4_TriggersView(viewModel: viewModel)
        case .interventions:
            Step5_InterventionsView(viewModel: viewModel)
        }
    }
    
    private func saveAndDismiss() {
        Task {
            do {
                try await viewModel.saveRecording()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("保存失败: \(error)")
            }
        }
    }
}

// MARK: - 进度指示器

struct ProgressIndicator: View {
    let currentStep: RecordingStep
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            // 步骤文字
            HStack {
                Text(currentStep.stepNumber)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // 进度条（带渐变）
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.backgroundTertiary)
                        .frame(height: 6)
                    
                    // 进度（渐变）
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primaryGradient)
                        .frame(
                            width: geometry.size.width * progress,
                            height: 6
                        )
                        .animation(EmotionalAnimation.fluid, value: currentStep)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var progress: CGFloat {
        CGFloat(currentStep.rawValue + 1) / CGFloat(RecordingStep.allCases.count)
    }
}

#Preview {
    struct PreviewContainer: View {
        @Query private var attacks: [AttackRecord]
        @Environment(\.modelContext) private var modelContext
        
        var body: some View {
            RecordingContainerView(modelContext: modelContext)
        }
    }
    
    return PreviewContainer()
        .modelContainer(for: [AttackRecord.self], inMemory: true)
}
