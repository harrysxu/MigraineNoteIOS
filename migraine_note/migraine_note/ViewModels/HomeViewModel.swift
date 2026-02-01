//
//  HomeViewModel.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI
import SwiftData

@Observable
class HomeViewModel {
    var streakDays: Int = 0
    var ongoingAttack: AttackRecord?
    var recentAttacks: [AttackRecord] = []
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    func loadData() {
        loadOngoingAttack()
        loadRecentAttacks()
        calculateStreak()
    }
    
    private func loadOngoingAttack() {
        let descriptor = FetchDescriptor<AttackRecord>(
            predicate: #Predicate { attack in
                attack.endTime == nil
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        ongoingAttack = try? modelContext.fetch(descriptor).first
    }
    
    private func loadRecentAttacks() {
        var descriptor = FetchDescriptor<AttackRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        recentAttacks = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func calculateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 获取所有发作记录，按日期排序
        let descriptor = FetchDescriptor<AttackRecord>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        guard let allAttacks = try? modelContext.fetch(descriptor) else {
            streakDays = 0
            return
        }
        
        // 如果今天有发作，streak为0
        if let lastAttack = allAttacks.first {
            let lastAttackDay = calendar.startOfDay(for: lastAttack.startTime)
            if lastAttackDay == today {
                streakDays = 0
                return
            }
        }
        
        // 计算连续无头痛天数
        var streak = 0
        var checkDate = today
        
        for attack in allAttacks {
            let attackDay = calendar.startOfDay(for: attack.startTime)
            let daysDiff = calendar.dateComponents([.day], from: attackDay, to: checkDate).day ?? 0
            
            if daysDiff == 0 {
                // 这一天有发作，停止计数
                break
            } else {
                // 继续累加
                streak = daysDiff
                checkDate = attackDay
            }
        }
        
        streakDays = streak
    }
    
    func refreshData() {
        loadData()
    }
}
