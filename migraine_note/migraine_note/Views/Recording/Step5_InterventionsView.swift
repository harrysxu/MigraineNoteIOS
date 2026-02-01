//
//  Step5_InterventionsView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

struct Step5_InterventionsView: View {
    @Bindable var viewModel: RecordingViewModel
    @State private var showAddMedicationSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 药物治疗
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(Color.accentPrimary)
                        Text("药物治疗")
                            .font(.headline)
                        Spacer()
                        Button {
                            showAddMedicationSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
                    
                    if viewModel.selectedMedications.isEmpty {
                        Text("未记录用药")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        ForEach(Array(viewModel.selectedMedications.enumerated()), id: \.offset) { index, medInfo in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(medInfo.medication?.name ?? "未知药物")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("\(String(format: "%.0f", medInfo.dosage))\(medInfo.medication?.unit ?? "mg") - \(formatTime(medInfo.timeTaken))")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                Spacer()
                                Button {
                                    viewModel.removeMedication(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.statusDanger)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                            
                            if index < viewModel.selectedMedications.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            
            // 非药物疗法
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: "figure.mind.and.body")
                            .foregroundStyle(Color.accentPrimary)
                        Text("非药物疗法")
                            .font(.headline)
                    }
                    
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(nonPharmacologicalOptions, id: \.self) { option in
                            SelectableChip(
                                label: option,
                                isSelected: Binding(
                                    get: { viewModel.selectedNonPharmacological.contains(option) },
                                    set: { isSelected in
                                        if isSelected {
                                            viewModel.selectedNonPharmacological.insert(option)
                                        } else {
                                            viewModel.selectedNonPharmacological.remove(option)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }
            
            // 备注
            InfoCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("备注（可选）")
                        .font(.headline)
                    
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 100)
                        .padding(Spacing.xs)
                        .background(Color.backgroundTertiary)
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .sheet(isPresented: $showAddMedicationSheet) {
            AddMedicationSheet(viewModel: viewModel, isPresented: $showAddMedicationSheet)
        }
    }
    
    private let nonPharmacologicalOptions = [
        "睡眠", "冷敷", "热敷", "按摩", "针灸", "暗室休息", "深呼吸", "冥想"
    ]
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 添加用药对话框

struct AddMedicationSheet: View {
    @Bindable var viewModel: RecordingViewModel
    @Binding var isPresented: Bool
    
    @State private var medicationName: String = ""
    @State private var dosage: String = ""
    @State private var timeTaken: Date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("药物信息") {
                    TextField("药物名称", text: $medicationName)
                    
                    HStack {
                        TextField("剂量", text: $dosage)
                            .keyboardType(.decimalPad)
                        Text("mg")
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                Section("服用时间") {
                    DatePicker("时间", selection: $timeTaken, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("添加用药记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        addMedication()
                    }
                    .disabled(medicationName.isEmpty || dosage.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func addMedication() {
        guard let dosageValue = Double(dosage) else { return }
        
        // TODO: 从数据库查找匹配的药物
        // 暂时创建一个临时的medication对象
        viewModel.addMedication(medication: nil, dosage: dosageValue, timeTaken: timeTaken)
        
        isPresented = false
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
                Step5_InterventionsView(viewModel: viewModel)
                    .padding()
            }
            .background(Color.backgroundPrimary)
        }
    }
    
    return PreviewContainer()
}
