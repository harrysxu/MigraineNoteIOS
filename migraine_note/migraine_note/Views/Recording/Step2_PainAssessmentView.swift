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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 疼痛强度
            PainIntensitySlider(value: $viewModel.selectedPainIntensity)
            
            // 疼痛性质
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("疼痛性质（可多选）")
                        .font(.headline)
                    
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(PainQuality.allCases, id: \.self) { quality in
                            SelectableChip(
                                label: quality.rawValue,
                                isSelected: Binding(
                                    get: { viewModel.selectedPainQualities.contains(quality) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedPainQualities.insert(quality)
                                        } else {
                                            viewModel.selectedPainQualities.remove(quality)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }
            
            // 疼痛部位
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("疼痛部位")
                        .font(.headline)
                    
                    HeadMapView(selectedLocations: $viewModel.selectedPainLocations)
                }
            }
            
            if viewModel.selectedPainIntensity == 0 || viewModel.selectedPainLocations.isEmpty {
                Text("⚠️ 请至少选择疼痛强度和部位")
                    .font(.caption)
                    .foregroundStyle(Color.statusWarning)
                    .padding(.horizontal)
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
