//
//  Step2_PainAssessmentView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct Step2_PainAssessmentView: View {
    @Bindable var viewModel: RecordingViewModel
    @State private var isDragging = false
    @State private var showEncouragement = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 页面标题和说明
            VStack(alignment: .leading, spacing: 8) {
                Text("疼痛评估")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                
                Text("请如实评估您的疼痛程度")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 4)
            
            // 横向疼痛强度滑块
            VStack(spacing: 16) {
                HorizontalPainSlider(
                    value: $viewModel.selectedPainIntensity,
                    range: 0...10,
                    isDragging: $isDragging
                )
                .padding(.vertical, 20)
                
                // 鼓励性提示
                if showEncouragement {
                    EncouragingText(type: .custom(
                        text: "记录每次不适，帮助医生更好地了解您的情况",
                        icon: "heart.text.square.fill"
                    ))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            
            // 疼痛性质
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.headline)
                        .foregroundStyle(Color.accentPrimary)
                    Text("疼痛性质")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Text("可多选")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.backgroundTertiary)
                        .cornerRadius(6)
                }
                .padding(.horizontal, 4)
                
                FlowLayout(spacing: 8) {
                    ForEach(PainQuality.allCases, id: \.self) { quality in
                        SelectableChip(
                            label: quality.rawValue,
                            isSelected: Binding(
                                get: { viewModel.selectedPainQualities.contains(quality) },
                                set: { isSelected in
                                    if isSelected {
                                        viewModel.selectedPainQualities.insert(quality)
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    } else {
                                        viewModel.selectedPainQualities.remove(quality)
                                    }
                                }
                            )
                        )
                    }
                }
            }
            
            // 疼痛部位
            EmotionalCard(style: .default) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.stand")
                            .font(.headline)
                            .foregroundStyle(Color.accentPrimary)
                        Text("疼痛部位")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                    }
                    
                    HeadMapView(selectedLocations: $viewModel.selectedPainLocations)
                }
            }
            
            // 验证提示
            if viewModel.selectedPainIntensity == 0 || viewModel.selectedPainLocations.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.statusInfo)
                    Text("请至少选择疼痛强度和部位")
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.statusInfo.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .onChange(of: viewModel.selectedPainIntensity) { _, newValue in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showEncouragement = newValue > 0 && newValue <= 3
            }
        }
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
                Step2_PainAssessmentView(viewModel: viewModel)
                    .padding()
            }
            .background(Color.backgroundPrimary)
            .onAppear {
                viewModel.selectedPainIntensity = 5
            }
        }
    }
    
    return PreviewContainer()
}
