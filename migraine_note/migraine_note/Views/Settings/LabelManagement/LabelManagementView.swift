//
//  LabelManagementView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import SwiftUI
import SwiftData

/// 标签管理主界面
struct LabelManagementView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: LabelCategory = .symptom
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab 选择器
            Picker("标签类型", selection: $selectedTab) {
                ForEach(LabelCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tab 内容
            TabView(selection: $selectedTab) {
                SymptomLabelEditor()
                    .tag(LabelCategory.symptom)
                
                TriggerLabelEditor()
                    .tag(LabelCategory.trigger)
                
                PainQualityLabelEditor()
                    .tag(LabelCategory.painQuality)
                
                InterventionLabelEditor()
                    .tag(LabelCategory.intervention)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("标签管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LabelManagementView()
    }
    .modelContainer(for: [CustomLabelConfig.self], inMemory: true)
}
