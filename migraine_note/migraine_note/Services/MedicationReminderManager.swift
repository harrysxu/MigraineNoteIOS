//
//  MedicationReminderManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/6.
//

import SwiftUI
import SwiftData
import UserNotifications

/// 用药提醒管理器
@Observable
class MedicationReminderManager {
    static let shared = MedicationReminderManager()
    
    var isNotificationAuthorized = false
    var reminders: [MedicationReminder] = []
    
    private init() {
        loadReminders()
        checkAuthorizationStatus()
    }
    
    // MARK: - 通知权限
    
    /// 请求通知权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isNotificationAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }
    
    /// 检查当前权限状态
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isNotificationAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 提醒管理
    
    /// 添加用药提醒
    func addReminder(_ reminder: MedicationReminder) {
        reminders.append(reminder)
        saveReminders()
        scheduleNotification(for: reminder)
    }
    
    /// 移除用药提醒
    func removeReminder(_ reminder: MedicationReminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
        cancelNotification(for: reminder)
    }
    
    /// 更新用药提醒
    func updateReminder(_ reminder: MedicationReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            cancelNotification(for: reminders[index])
            reminders[index] = reminder
            saveReminders()
            if reminder.isEnabled {
                scheduleNotification(for: reminder)
            }
        }
    }
    
    /// 切换提醒启用/禁用
    func toggleReminder(_ reminder: MedicationReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isEnabled.toggle()
            saveReminders()
            if reminders[index].isEnabled {
                scheduleNotification(for: reminders[index])
            } else {
                cancelNotification(for: reminders[index])
            }
        }
    }
    
    // MARK: - 通知调度
    
    /// 调度单个提醒的通知
    private func scheduleNotification(for reminder: MedicationReminder) {
        guard reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "用药提醒"
        content.body = "\(reminder.medicationName) \(String(format: "%.0f", reminder.dosage))\(reminder.unit)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"
        
        // 为每个提醒时间创建通知
        for (timeIndex, time) in reminder.times.enumerated() {
            var dateComponents = DateComponents()
            dateComponents.hour = Calendar.current.component(.hour, from: time)
            dateComponents.minute = Calendar.current.component(.minute, from: time)
            
            // 如果指定了星期几
            if !reminder.weekdays.isEmpty {
                for weekday in reminder.weekdays {
                    var weekdayComponents = dateComponents
                    weekdayComponents.weekday = weekday
                    
                    let identifier = "\(reminder.id.uuidString)_\(timeIndex)_\(weekday)"
                    let trigger = UNCalendarNotificationTrigger(dateMatching: weekdayComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request)
                }
            } else {
                // 每天提醒
                let identifier = "\(reminder.id.uuidString)_\(timeIndex)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    /// 取消单个提醒的所有通知
    private func cancelNotification(for reminder: MedicationReminder) {
        let center = UNUserNotificationCenter.current()
        // 获取所有该提醒的通知标识符
        center.getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.hasPrefix(reminder.id.uuidString) }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    /// 重新调度所有提醒
    func rescheduleAllReminders() {
        // 先清除所有
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 重新调度已启用的提醒
        for reminder in reminders where reminder.isEnabled {
            scheduleNotification(for: reminder)
        }
    }
    
    // MARK: - MOH 风险提醒
    
    /// 检查并发送 MOH 风险通知
    func checkAndNotifyMOHRisk(acuteMedicationDays: Int) {
        if acuteMedicationDays >= 10 {
            let content = UNMutableNotificationContent()
            content.title = "用药频次警告"
            content.body = "本月急性用药已达 \(acuteMedicationDays) 天，建议咨询医生是否需要调整用药方案。"
            content.sound = .default
            content.categoryIdentifier = "MOH_WARNING"
            
            let request = UNNotificationRequest(
                identifier: "moh_warning_\(Date().compactDate())",
                content: content,
                trigger: nil // 立即发送
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    /// 检查并发送库存不足通知
    func checkAndNotifyLowInventory(medications: [Medication]) {
        let lowStock = medications.filter { $0.inventory > 0 && $0.inventory <= 5 }
        
        for medication in lowStock {
            let content = UNMutableNotificationContent()
            content.title = "药物库存不足"
            content.body = "\(medication.name) 仅剩 \(medication.inventory) \(medication.unit)，请及时补充。"
            content.sound = .default
            content.categoryIdentifier = "LOW_INVENTORY"
            
            let request = UNNotificationRequest(
                identifier: "low_inventory_\(medication.id.uuidString)_\(Date().compactDate())",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // MARK: - 持久化
    
    private let remindersKey = "medication_reminders"
    
    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        }
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: remindersKey),
           let decoded = try? JSONDecoder().decode([MedicationReminder].self, from: data) {
            reminders = decoded
        }
    }
}

// MARK: - 用药提醒数据模型

struct MedicationReminder: Identifiable, Codable, Equatable {
    let id: UUID
    var medicationName: String
    var dosage: Double
    var unit: String
    var times: [Date]        // 每天的提醒时间
    var weekdays: [Int]      // 星期几 (1=周日, 2=周一..7=周六)，空数组=每天
    var isEnabled: Bool
    var notes: String?
    
    init(
        id: UUID = UUID(),
        medicationName: String,
        dosage: Double = 0,
        unit: String = "mg",
        times: [Date] = [],
        weekdays: [Int] = [],
        isEnabled: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.medicationName = medicationName
        self.dosage = dosage
        self.unit = unit
        self.times = times
        self.weekdays = weekdays
        self.isEnabled = isEnabled
        self.notes = notes
    }
    
    /// 显示用的时间描述
    var timeDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return times.map { formatter.string(from: $0) }.joined(separator: ", ")
    }
    
    /// 显示用的重复描述
    var repeatDescription: String {
        if weekdays.isEmpty {
            return "每天"
        }
        
        let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]
        let selectedNames = weekdays.sorted().compactMap { day -> String? in
            guard day >= 1, day <= 7 else { return nil }
            return "周\(weekdayNames[day - 1])"
        }
        return selectedNames.joined(separator: "、")
    }
}
