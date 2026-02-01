//
//  MedicationViewModel.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  管理药箱和用药记录的ViewModel
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class MedicationViewModel {
    // MARK: - Properties
    
    /// 当前显示的药物类型筛选
    var selectedCategory: MedicationCategoryFilter = .all
    
    /// 搜索文本
    var searchText: String = ""
    
    /// 排序选项
    var sortOption: SortOption = .name
    
    // MARK: - Enums
    
    enum MedicationCategoryFilter: String, CaseIterable {
        case all = "全部"
        case acute = "急性用药"
        case preventive = "预防性用药"
        
        var systemImage: String {
            switch self {
            case .all: return "pills.circle"
            case .acute: return "pills.fill"
            case .preventive: return "cross.case.fill"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case name = "名称"
        case usageFrequency = "使用频次"
        case inventory = "库存"
        case dateAdded = "添加日期"
        
        var systemImage: String {
            switch self {
            case .name: return "textformat.abc"
            case .usageFrequency: return "chart.bar"
            case .inventory: return "shippingbox"
            case .dateAdded: return "calendar"
            }
        }
    }
    
    // MARK: - Methods
    
    /// 筛选和排序药物列表
    func filteredMedications(_ medications: [Medication], logs: [MedicationLog]) -> [Medication] {
        var filtered = medications
        
        // 应用类别筛选
        switch selectedCategory {
        case .all:
            break
        case .acute:
            filtered = filtered.filter { $0.isAcute }
        case .preventive:
            filtered = filtered.filter { !$0.isAcute }
        }
        
        // 应用搜索
        if !searchText.isEmpty {
            filtered = filtered.filter { medication in
                medication.name.localizedCaseInsensitiveContains(searchText) ||
                medication.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 应用排序
        return sortMedications(filtered, logs: logs)
    }
    
    /// 排序药物
    private func sortMedications(_ medications: [Medication], logs: [MedicationLog]) -> [Medication] {
        switch sortOption {
        case .name:
            return medications.sorted { $0.name < $1.name }
            
        case .usageFrequency:
            return medications.sorted { med1, med2 in
                let count1 = logs.filter { $0.medication?.id == med1.id }.count
                let count2 = logs.filter { $0.medication?.id == med2.id }.count
                return count1 > count2
            }
            
        case .inventory:
            return medications.sorted { $0.inventory > $1.inventory }
            
        case .dateAdded:
            // 由于没有创建日期，按名称排序
            return medications.sorted { $0.name < $1.name }
        }
    }
    
    /// 计算当前月份使用天数
    func monthlyUsageDays(for medication: Medication, logs: [MedicationLog]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // 获取本月使用该药物的记录
        let monthlyLogs = logs.filter { log in
            guard log.medication?.id == medication.id else { return false }
            return log.takenAt >= startOfMonth
        }
        
        // 计算不同的使用天数
        let uniqueDays = Set(monthlyLogs.map { log in
            calendar.startOfDay(for: log.takenAt)
        })
        
        return uniqueDays.count
    }
    
    /// 检查是否接近MOH阈值
    func isApproachingMOHLimit(medication: Medication, usageDays: Int) -> Bool {
        guard let limit = medication.monthlyLimit else { return false }
        return usageDays >= limit - 3 // 提前3天警告
    }
    
    /// 检查是否超过MOH阈值
    func isExceedingMOHLimit(medication: Medication, usageDays: Int) -> Bool {
        guard let limit = medication.monthlyLimit else { return false }
        return usageDays >= limit
    }
    
    /// 获取MOH警告文本
    func mohWarningText(for medication: Medication, usageDays: Int) -> String? {
        guard let limit = medication.monthlyLimit else { return nil }
        
        if usageDays >= limit {
            return "已超过MOH阈值(\(limit)天)"
        } else if usageDays >= limit - 3 {
            return "接近MOH阈值(还剩\(limit - usageDays)天)"
        }
        return nil
    }
    
    /// 检查库存是否不足
    func isLowInventory(_ medication: Medication) -> Bool {
        return medication.inventory > 0 && medication.inventory <= 5
    }
    
    /// 删除药物
    func deleteMedication(_ medication: Medication, from context: ModelContext) {
        context.delete(medication)
        try? context.save()
    }
    
    /// 更新库存
    func updateInventory(_ medication: Medication, newCount: Int, context: ModelContext) {
        medication.inventory = max(0, newCount)
        try? context.save()
    }
}
