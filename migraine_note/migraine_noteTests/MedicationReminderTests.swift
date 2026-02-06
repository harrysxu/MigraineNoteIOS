//
//  MedicationReminderTests.swift
//  migraine_noteTests
//
//  用药提醒功能单元测试
//

import XCTest
@testable import migraine_note

final class MedicationReminderTests: XCTestCase {
    
    // MARK: - MedicationReminder Model Tests
    
    func testMedicationReminderInit() {
        let reminder = MedicationReminder(
            medicationName: "布洛芬",
            dosage: 400,
            unit: "mg",
            times: [makeTime(hour: 8, minute: 0), makeTime(hour: 20, minute: 0)],
            weekdays: [],
            isEnabled: true
        )
        
        XCTAssertEqual(reminder.medicationName, "布洛芬")
        XCTAssertEqual(reminder.dosage, 400)
        XCTAssertEqual(reminder.unit, "mg")
        XCTAssertEqual(reminder.times.count, 2)
        XCTAssertTrue(reminder.weekdays.isEmpty)
        XCTAssertTrue(reminder.isEnabled)
    }
    
    func testRepeatDescription_EveryDay() {
        let reminder = MedicationReminder(
            medicationName: "Test",
            weekdays: []
        )
        
        XCTAssertEqual(reminder.repeatDescription, "每天")
    }
    
    func testRepeatDescription_SpecificDays() {
        let reminder = MedicationReminder(
            medicationName: "Test",
            weekdays: [2, 4, 6] // 周一、周三、周五
        )
        
        XCTAssertEqual(reminder.repeatDescription, "周一、周三、周五")
    }
    
    func testRepeatDescription_Weekend() {
        let reminder = MedicationReminder(
            medicationName: "Test",
            weekdays: [1, 7] // 周日、周六
        )
        
        XCTAssertEqual(reminder.repeatDescription, "周日、周六")
    }
    
    func testTimeDescription() {
        let time1 = makeTime(hour: 8, minute: 30)
        let time2 = makeTime(hour: 20, minute: 0)
        
        let reminder = MedicationReminder(
            medicationName: "Test",
            times: [time1, time2]
        )
        
        let desc = reminder.timeDescription
        XCTAssertTrue(desc.contains("08:30"))
        XCTAssertTrue(desc.contains("20:00"))
    }
    
    func testMedicationReminderCodable() throws {
        let original = MedicationReminder(
            medicationName: "布洛芬",
            dosage: 400,
            unit: "mg",
            times: [makeTime(hour: 8, minute: 0)],
            weekdays: [2, 4, 6],
            isEnabled: true,
            notes: "饭后服用"
        )
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MedicationReminder.self, from: encoded)
        
        XCTAssertEqual(decoded.medicationName, original.medicationName)
        XCTAssertEqual(decoded.dosage, original.dosage)
        XCTAssertEqual(decoded.unit, original.unit)
        XCTAssertEqual(decoded.weekdays, original.weekdays)
        XCTAssertEqual(decoded.isEnabled, original.isEnabled)
        XCTAssertEqual(decoded.notes, original.notes)
    }
    
    func testMedicationReminderEquatable() {
        let id = UUID()
        let reminder1 = MedicationReminder(id: id, medicationName: "布洛芬")
        let reminder2 = MedicationReminder(id: id, medicationName: "布洛芬")
        let reminder3 = MedicationReminder(medicationName: "对乙酰氨基酚")
        
        XCTAssertEqual(reminder1, reminder2)
        XCTAssertNotEqual(reminder1, reminder3)
    }
    
    // MARK: - MedicationReminderManager Tests
    
    func testManagerAddReminder() {
        let manager = MedicationReminderManager.shared
        let initialCount = manager.reminders.count
        
        let reminder = MedicationReminder(
            medicationName: "测试药物_Add",
            dosage: 100,
            unit: "mg",
            times: [makeTime(hour: 8, minute: 0)]
        )
        
        manager.addReminder(reminder)
        
        XCTAssertEqual(manager.reminders.count, initialCount + 1)
        XCTAssertTrue(manager.reminders.contains(where: { $0.id == reminder.id }))
        
        // 清理
        manager.removeReminder(reminder)
    }
    
    func testManagerRemoveReminder() {
        let manager = MedicationReminderManager.shared
        
        let reminder = MedicationReminder(
            medicationName: "测试药物_Remove",
            times: [makeTime(hour: 9, minute: 0)]
        )
        
        manager.addReminder(reminder)
        let countAfterAdd = manager.reminders.count
        
        manager.removeReminder(reminder)
        
        XCTAssertEqual(manager.reminders.count, countAfterAdd - 1)
        XCTAssertFalse(manager.reminders.contains(where: { $0.id == reminder.id }))
    }
    
    func testManagerToggleReminder() {
        let manager = MedicationReminderManager.shared
        
        let reminder = MedicationReminder(
            medicationName: "测试药物_Toggle",
            times: [makeTime(hour: 10, minute: 0)],
            isEnabled: true
        )
        
        manager.addReminder(reminder)
        XCTAssertTrue(manager.reminders.first(where: { $0.id == reminder.id })?.isEnabled ?? false)
        
        manager.toggleReminder(reminder)
        XCTAssertFalse(manager.reminders.first(where: { $0.id == reminder.id })?.isEnabled ?? true,
                       "toggle 后应变为禁用")
        
        // 再次 toggle
        let updatedReminder = manager.reminders.first(where: { $0.id == reminder.id })!
        manager.toggleReminder(updatedReminder)
        XCTAssertTrue(manager.reminders.first(where: { $0.id == reminder.id })?.isEnabled ?? false,
                      "再次 toggle 后应变为启用")
        
        // 清理
        manager.removeReminder(reminder)
    }
    
    func testManagerUpdateReminder() {
        let manager = MedicationReminderManager.shared
        
        var reminder = MedicationReminder(
            medicationName: "原始名称",
            dosage: 100,
            times: [makeTime(hour: 8, minute: 0)]
        )
        
        manager.addReminder(reminder)
        
        reminder.medicationName = "更新后名称"
        reminder.dosage = 200
        manager.updateReminder(reminder)
        
        let updated = manager.reminders.first(where: { $0.id == reminder.id })
        XCTAssertEqual(updated?.medicationName, "更新后名称")
        XCTAssertEqual(updated?.dosage, 200)
        
        // 清理
        manager.removeReminder(reminder)
    }
    
    func testManagerRemoveNonexistentReminder_DoesNotCrash() {
        let manager = MedicationReminderManager.shared
        let initialCount = manager.reminders.count
        
        let nonexistent = MedicationReminder(medicationName: "不存在的")
        manager.removeReminder(nonexistent)
        
        XCTAssertEqual(manager.reminders.count, initialCount,
                       "移除不存在的提醒不应影响列表")
    }
    
    func testManagerUpdateNonexistentReminder_DoesNotCrash() {
        let manager = MedicationReminderManager.shared
        let initialCount = manager.reminders.count
        
        let nonexistent = MedicationReminder(medicationName: "不存在的")
        manager.updateReminder(nonexistent)
        
        XCTAssertEqual(manager.reminders.count, initialCount)
    }
    
    // MARK: - Helper
    
    private func makeTime(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }
}
