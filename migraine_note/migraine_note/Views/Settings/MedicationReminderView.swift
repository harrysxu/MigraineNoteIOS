//
//  MedicationReminderView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/6.
//

import SwiftUI
import SwiftData

/// 用药提醒管理页面
struct MedicationReminderView: View {
    @State private var reminderManager = MedicationReminderManager.shared
    @State private var showAddReminder = false
    @State private var editingReminder: MedicationReminder?
    
    var body: some View {
        List {
            // 通知权限状态
            if !reminderManager.isNotificationAuthorized {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .font(.title3)
                            .foregroundStyle(Color.statusWarning)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("通知权限未开启")
                                .font(.subheadline.weight(.medium))
                            Text("请在系统设置中允许通知，以接收用药提醒")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button("去设置") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentPrimary)
                    }
                }
            }
            
            // 提醒列表
            Section {
                if reminderManager.reminders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.textTertiary)
                        
                        Text("暂无用药提醒")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                        
                        Text("添加提醒，按时服药不遗忘")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(reminderManager.reminders) { reminder in
                        ReminderRow(
                            reminder: reminder,
                            onToggle: {
                                reminderManager.toggleReminder(reminder)
                            },
                            onTap: {
                                editingReminder = reminder
                            }
                        )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            reminderManager.removeReminder(reminderManager.reminders[index])
                        }
                    }
                }
            } header: {
                Text("用药提醒")
            }
        }
        .navigationTitle("用药提醒")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddReminder = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddReminder) {
            AddReminderSheet(isPresented: $showAddReminder)
        }
        .sheet(item: $editingReminder) { reminder in
            EditReminderSheet(reminder: reminder, isPresented: Binding(
                get: { editingReminder != nil },
                set: { if !$0 { editingReminder = nil } }
            ))
        }
        .onAppear {
            reminderManager.checkAuthorizationStatus()
        }
    }
}

// MARK: - 提醒行

struct ReminderRow: View {
    let reminder: MedicationReminder
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.medicationName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(reminder.isEnabled ? Color.textPrimary : Color.textTertiary)
                    
                    if reminder.dosage > 0 {
                        Text("\(String(format: "%.0f", reminder.dosage)) \(reminder.unit)")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(reminder.timeDescription)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption2)
                            Text(reminder.repeatDescription)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 添加提醒

struct AddReminderSheet: View {
    @Binding var isPresented: Bool
    @State private var reminderManager = MedicationReminderManager.shared
    
    @State private var medicationName = ""
    @State private var dosage: Double = 0
    @State private var unit = "mg"
    @State private var selectedTime = Date()
    @State private var times: [Date] = []
    @State private var weekdays: Set<Int> = []
    @State private var isEveryDay = true
    
    @Query(sort: \Medication.name) private var medications: [Medication]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("药物信息") {
                    // 药物名称（可选择已有药物）
                    if !medications.isEmpty {
                        Picker("选择药物", selection: $medicationName) {
                            Text("手动输入").tag("")
                            ForEach(medications, id: \.id) { medication in
                                Text(medication.name).tag(medication.name)
                            }
                        }
                    }
                    
                    if medicationName.isEmpty || medications.isEmpty {
                        TextField("药物名称", text: $medicationName)
                    }
                    
                    HStack {
                        Text("剂量")
                        Spacer()
                        TextField("0", value: $dosage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unit)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                Section("提醒时间") {
                    // 已添加的时间列表
                    ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                        HStack {
                            Text({
                                let f = DateFormatter()
                                f.dateFormat = "HH:mm"
                                return f.string(from: time)
                            }())
                            
                            Spacer()
                            
                            Button {
                                times.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.statusDanger)
                            }
                        }
                    }
                    
                    // 添加时间
                    HStack {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        
                        Spacer()
                        
                        Button {
                            times.append(selectedTime)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
                }
                
                Section("重复") {
                    Toggle("每天提醒", isOn: $isEveryDay)
                    
                    if !isEveryDay {
                        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
                        ForEach(1...7, id: \.self) { day in
                            HStack {
                                Text(weekdayNames[day - 1])
                                Spacer()
                                if weekdays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if weekdays.contains(day) {
                                    weekdays.remove(day)
                                } else {
                                    weekdays.insert(day)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("添加提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveReminder()
                    }
                    .disabled(medicationName.isEmpty || times.isEmpty)
                }
            }
        }
        .onAppear {
            // 请求通知权限
            Task {
                await reminderManager.requestAuthorization()
            }
        }
    }
    
    private func saveReminder() {
        let reminder = MedicationReminder(
            medicationName: medicationName,
            dosage: dosage,
            unit: unit,
            times: times,
            weekdays: isEveryDay ? [] : Array(weekdays),
            isEnabled: true
        )
        reminderManager.addReminder(reminder)
        AppToastManager.shared.showSuccess("提醒已添加")
        isPresented = false
    }
}

// MARK: - 编辑提醒

struct EditReminderSheet: View {
    let reminder: MedicationReminder
    @Binding var isPresented: Bool
    @State private var reminderManager = MedicationReminderManager.shared
    
    @State private var medicationName: String
    @State private var dosage: Double
    @State private var unit: String
    @State private var times: [Date]
    @State private var weekdays: Set<Int>
    @State private var isEveryDay: Bool
    @State private var selectedTime = Date()
    
    init(reminder: MedicationReminder, isPresented: Binding<Bool>) {
        self.reminder = reminder
        self._isPresented = isPresented
        _medicationName = State(initialValue: reminder.medicationName)
        _dosage = State(initialValue: reminder.dosage)
        _unit = State(initialValue: reminder.unit)
        _times = State(initialValue: reminder.times)
        _weekdays = State(initialValue: Set(reminder.weekdays))
        _isEveryDay = State(initialValue: reminder.weekdays.isEmpty)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("药物信息") {
                    TextField("药物名称", text: $medicationName)
                    
                    HStack {
                        Text("剂量")
                        Spacer()
                        TextField("0", value: $dosage, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(unit)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                Section("提醒时间") {
                    ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                        HStack {
                            Text({
                                let f = DateFormatter()
                                f.dateFormat = "HH:mm"
                                return f.string(from: time)
                            }())
                            
                            Spacer()
                            
                            Button {
                                times.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.statusDanger)
                            }
                        }
                    }
                    
                    HStack {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        
                        Spacer()
                        
                        Button {
                            times.append(selectedTime)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
                }
                
                Section("重复") {
                    Toggle("每天提醒", isOn: $isEveryDay)
                    
                    if !isEveryDay {
                        let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
                        ForEach(1...7, id: \.self) { day in
                            HStack {
                                Text(weekdayNames[day - 1])
                                Spacer()
                                if weekdays.contains(day) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if weekdays.contains(day) {
                                    weekdays.remove(day)
                                } else {
                                    weekdays.insert(day)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("删除提醒", role: .destructive) {
                        reminderManager.removeReminder(reminder)
                        AppToastManager.shared.showSuccess("提醒已删除")
                        isPresented = false
                    }
                }
            }
            .navigationTitle("编辑提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(medicationName.isEmpty || times.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        var updated = reminder
        updated.medicationName = medicationName
        updated.dosage = dosage
        updated.unit = unit
        updated.times = times
        updated.weekdays = isEveryDay ? [] : Array(weekdays)
        reminderManager.updateReminder(updated)
        AppToastManager.shared.showSuccess("提醒已更新")
        isPresented = false
    }
}
