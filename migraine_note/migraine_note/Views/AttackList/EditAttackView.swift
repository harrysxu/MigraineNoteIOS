//
//  EditAttackView.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  编辑发作记录视图
//

import SwiftUI
import SwiftData

struct EditAttackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let attack: AttackRecord
    
    @State private var viewModel: RecordingViewModel
    
    init(attack: AttackRecord, modelContext: ModelContext) {
        self.attack = attack
        _viewModel = State(initialValue: RecordingViewModel(modelContext: modelContext, editingAttack: attack))
    }
    
    var body: some View {
        NavigationStack {
            RecordingContainerView(viewModel: viewModel, isEditMode: true)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            // 预填充现有数据
            viewModel.loadExistingAttack(attack)
        }
    }
}
