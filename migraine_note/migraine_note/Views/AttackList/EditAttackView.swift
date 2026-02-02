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
    
    init(attack: AttackRecord, modelContext: ModelContext) {
        self.attack = attack
    }
    
    var body: some View {
        NavigationStack {
            SimplifiedRecordingView(
                modelContext: modelContext,
                existingAttack: attack
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}
