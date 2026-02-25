//
//  UserProfileEditView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/12.
//

import SwiftUI
import SwiftData

/// 用户信息编辑页面
struct UserProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    // 基本信息
    @State private var name: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var hasBirthDate: Bool = false
    @State private var selectedGender: Gender?
    @State private var selectedBloodType: BloodType?
    
    // 身体信息
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    
    // 病史
    @State private var migraineOnsetAgeText: String = ""
    @State private var selectedMigraineType: MigraineType?
    @State private var familyHistory: Bool = false
    
    // 其他
    @State private var allergies: String = ""
    @State private var medicalNotes: String = ""
    
    @State private var hasLoaded = false
    
    private var userProfile: UserProfile {
        if let existing = profiles.first {
            return existing
        }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // 档案完整度
                completionCard
                
                // 基本信息
                basicInfoSection
                
                // 身体信息
                bodyInfoSection
                
                // 病史信息
                medicalHistorySection
                
                // 其他信息
                otherInfoSection
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("profile.edit.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !hasLoaded {
                loadProfileData()
                hasLoaded = true
            }
        }
    }
    
    // MARK: - 档案完整度卡片
    
    private var completionCard: some View {
        let completion = userProfile.completionPercentage
        return ProgressCard(
            title: String(localized: "profile.completion"),
            progress: completion,
            icon: "person.text.rectangle.fill",
            style: completion >= 0.8 ? .success : .elevated,
            accentColor: completion >= 0.8 ? .statusSuccess : .accentPrimary
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 基本信息
    
    private var basicInfoSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 0) {
                Text("profile.basicInfo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Spacing.sm)
                
                // 姓名
                ProfileFieldRow(icon: "person.fill", iconColor: .accentPrimary, title: String(localized: "profile.name")) {
                    TextField("profile.namePlaceholder", text: $name)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.textPrimary)
                        .onChange(of: name) { _, newValue in
                            userProfile.name = newValue.isEmpty ? nil : newValue
                        }
                }
                
                Divider().padding(.leading, 44)
                
                // 出生日期
                ProfileFieldRow(icon: "calendar", iconColor: .orange, title: String(localized: "profile.birthDate")) {
                    if hasBirthDate {
                        HStack(spacing: 8) {
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: birthDate) { _, newValue in
                                    userProfile.birthDate = newValue
                                    // 同步更新 age
                                    userProfile.age = userProfile.calculatedAge
                                }
                            
                            Button {
                                hasBirthDate = false
                                userProfile.birthDate = nil
                                userProfile.age = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                    } else {
                        Button("profile.setBirthDate") {
                            hasBirthDate = true
                            userProfile.birthDate = birthDate
                            userProfile.age = userProfile.calculatedAge
                        }
                        .font(.body)
                        .foregroundStyle(Color.textTertiary)
                    }
                }
                
                if hasBirthDate, let age = userProfile.calculatedAge {
                    HStack {
                        Spacer()
                        Text("\(age)\(String(localized: "profile.age.suffix"))")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }
                
                Divider().padding(.leading, 44)
                
                // 性别
                ProfileFieldRow(icon: "figure.stand", iconColor: .purple, title: String(localized: "profile.gender")) {
                    Picker("", selection: $selectedGender) {
                        Text("profile.notSet").tag(nil as Gender?)
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.localizedName).tag(gender as Gender?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(selectedGender == nil ? Color.textTertiary : Color.textPrimary)
                    .onChange(of: selectedGender) { _, newValue in
                        userProfile.gender = newValue
                    }
                }
                
                Divider().padding(.leading, 44)
                
                // 血型
                ProfileFieldRow(icon: "drop.fill", iconColor: .red, title: String(localized: "profile.bloodType")) {
                    Picker("", selection: $selectedBloodType) {
                        Text("profile.notSet").tag(nil as BloodType?)
                        ForEach(BloodType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type as BloodType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(selectedBloodType == nil ? Color.textTertiary : Color.textPrimary)
                    .onChange(of: selectedBloodType) { _, newValue in
                        userProfile.bloodType = newValue
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 身体信息
    
    private var bodyInfoSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 0) {
                Text("profile.bodyInfo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Spacing.sm)
                
                // 身高
                ProfileFieldRow(icon: "ruler", iconColor: .blue, title: String(localized: "profile.height")) {
                    HStack(spacing: 4) {
                        TextField("profile.enterPlaceholder", text: $heightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 80)
                            .onChange(of: heightText) { _, newValue in
                                userProfile.height = Double(newValue)
                            }
                        Text("cm")
                            .font(.body)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                
                Divider().padding(.leading, 44)
                
                // 体重
                ProfileFieldRow(icon: "scalemass", iconColor: .green, title: String(localized: "profile.weight")) {
                    HStack(spacing: 4) {
                        TextField("profile.enterPlaceholder", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 80)
                            .onChange(of: weightText) { _, newValue in
                                userProfile.weight = Double(newValue)
                            }
                        Text("kg")
                            .font(.body)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                
                // BMI 显示
                if let bmi = userProfile.bmi, let desc = userProfile.bmiDescription {
                    Divider().padding(.leading, 44)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "heart.text.square")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 28)
                            .opacity(0) // 占位对齐
                        
                        Text("BMI")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.textPrimary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", bmi))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.accentPrimary)
                        
                        Text("(\(desc))")
                            .font(.caption)
                            .foregroundStyle(bmiColor(desc))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(bmiColor(desc).opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 病史信息
    
    private var medicalHistorySection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: 0) {
                Text("profile.medicalHistory")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, Spacing.sm)
                
                // 偏头痛首发年龄
                ProfileFieldRow(icon: "clock.arrow.circlepath", iconColor: .orange, title: String(localized: "profile.onsetAge")) {
                    HStack(spacing: 4) {
                        TextField("profile.enterPlaceholder", text: $migraineOnsetAgeText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 60)
                            .onChange(of: migraineOnsetAgeText) { _, newValue in
                                userProfile.migraineOnsetAge = Int(newValue)
                            }
                        Text(String(localized: "profile.age.suffix"))
                            .font(.body)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                
                Divider().padding(.leading, 44)
                
                // 偏头痛类型
                ProfileFieldRow(icon: "brain.head.profile", iconColor: .purple, title: String(localized: "profile.diagnosisType")) {
                    Picker("", selection: $selectedMigraineType) {
                        Text("profile.notSet").tag(nil as MigraineType?)
                        ForEach(MigraineType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type as MigraineType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(selectedMigraineType == nil ? Color.textTertiary : Color.textPrimary)
                    .onChange(of: selectedMigraineType) { _, newValue in
                        userProfile.migraineType = newValue
                    }
                }
                
                Divider().padding(.leading, 44)
                
                // 家族史
                HStack(spacing: 12) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 28)
                    
                    Text("profile.familyHistory")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $familyHistory)
                        .labelsHidden()
                        .onChange(of: familyHistory) { _, newValue in
                            userProfile.familyHistory = newValue
                        }
                }
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 其他信息
    
    private var otherInfoSection: some View {
        EmotionalCard(style: .default) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("profile.otherInfo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 药物过敏史
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: 8) {
                        Image(systemName: "allergens")
                            .font(.subheadline)
                            .foregroundStyle(Color.statusWarning)
                        Text("profile.allergies")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.textPrimary)
                    }
                    
                    TextField("profile.allergiesPlaceholder", text: $allergies, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(Spacing.sm)
                        .background(Color.backgroundPrimary)
                        .cornerRadius(CornerRadius.sm)
                        .foregroundStyle(Color.textPrimary)
                        .onChange(of: allergies) { _, newValue in
                            userProfile.allergies = newValue.isEmpty ? nil : newValue
                        }
                }
                
                // 医疗备注
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentPrimary)
                        Text("profile.medicalNotes")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.textPrimary)
                    }
                    
                    TextField("profile.medicalNotesPlaceholder", text: $medicalNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(Spacing.sm)
                        .background(Color.backgroundPrimary)
                        .cornerRadius(CornerRadius.sm)
                        .foregroundStyle(Color.textPrimary)
                        .onChange(of: medicalNotes) { _, newValue in
                            userProfile.medicalNotes = newValue.isEmpty ? nil : newValue
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 数据加载
    
    private func loadProfileData() {
        let profile = userProfile
        
        name = profile.name ?? ""
        
        if let bd = profile.birthDate {
            birthDate = bd
            hasBirthDate = true
        }
        
        selectedGender = profile.gender
        selectedBloodType = profile.bloodType
        
        if let h = profile.height {
            heightText = String(format: "%.0f", h)
        }
        if let w = profile.weight {
            weightText = String(format: "%.1f", w)
        }
        
        if let onset = profile.migraineOnsetAge {
            migraineOnsetAgeText = "\(onset)"
        }
        selectedMigraineType = profile.migraineType
        familyHistory = profile.familyHistory
        
        allergies = profile.allergies ?? ""
        medicalNotes = profile.medicalNotes ?? ""
    }
    
    // MARK: - 辅助方法
    
    private func bmiColor(_ description: String) -> Color {
        switch description {
        case String(localized: "profile.bmi.underweight"): return .blue
        case String(localized: "profile.bmi.normal"): return .statusSuccess
        case String(localized: "profile.bmi.overweight"): return .statusWarning
        case String(localized: "profile.bmi.obese"): return .statusError
        default: return .textSecondary
        }
    }
}

// MARK: - 档案字段行组件

private struct ProfileFieldRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: Content
    
    init(icon: String, iconColor: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            content
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileEditView()
    }
    .modelContainer(for: [UserProfile.self], inMemory: true)
}
