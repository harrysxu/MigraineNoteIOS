//
//  TestDataManager.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/2.
//

import Foundation
import SwiftData

#if DEBUG

/// 测试数据管理器 - 仅在 Debug 模式下可用
@MainActor
class TestDataManager {
    private let modelContext: ModelContext
    
    // MARK: - 初始化
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 数据生成
    
    /// 生成发作记录
    /// - Parameters:
    ///   - monthCount: 月份数（1-24）
    ///   - attacksPerMonth: 每月发作次数（1-15）
    ///   - avgDuration: 平均持续时长（小时）
    ///   - durationVariance: 时长变化范围（小时）
    /// - Returns: 生成的记录数量
    func generateAttackRecords(
        monthCount: Int,
        attacksPerMonth: Int,
        avgDuration: Double,
        durationVariance: Double
    ) async throws -> Int {
        let calendar = Calendar.current
        let now = Date()
        var generatedCount = 0
        
        // 首先生成一些药物供用药记录使用
        let medications = try await ensureMedications()
        
        // 为每个月生成记录
        for monthOffset in 0..<monthCount {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now)!
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            
            // 获取该月的天数
            let range = calendar.range(of: .day, in: .month, for: monthStart)!
            let daysInMonth = range.count
            
            // 生成该月的发作记录
            for _ in 0..<attacksPerMonth {
                let record = try generateSingleAttackRecord(
                    in: monthStart,
                    daysInMonth: daysInMonth,
                    avgDuration: avgDuration,
                    durationVariance: durationVariance,
                    medications: medications
                )
                modelContext.insert(record)
                generatedCount += 1
            }
        }
        
        try modelContext.save()
        return generatedCount
    }
    
    /// 生成单个发作记录
    private func generateSingleAttackRecord(
        in monthStart: Date,
        daysInMonth: Int,
        avgDuration: Double,
        durationVariance: Double,
        medications: [Medication]
    ) throws -> AttackRecord {
        let calendar = Calendar.current
        
        // 生成发作时间（平衡模式：30%概率在周末，70%随机）
        var dayOffset: Int
        if Double.random(in: 0...1) < 0.3 {
            // 周末偏多
            dayOffset = Int.random(in: 0..<daysInMonth)
            // 如果是工作日，尝试调整到周末
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart),
               calendar.component(.weekday, from: date) != 1 && calendar.component(.weekday, from: date) != 7 {
                // 随机调整到最近的周末
                if Bool.random() {
                    dayOffset = (dayOffset / 7) * 7 + (7 - calendar.component(.weekday, from: monthStart)) // 本周周六
                }
            }
        } else {
            dayOffset = Int.random(in: 0..<daysInMonth)
        }
        
        let hourOffset = Int.random(in: 0...23)
        let minuteOffset = Int.random(in: 0...59)
        
        var startComponents = calendar.dateComponents([.year, .month], from: monthStart)
        startComponents.day = dayOffset + 1
        startComponents.hour = hourOffset
        startComponents.minute = minuteOffset
        
        let startTime = calendar.date(from: startComponents) ?? monthStart
        
        // 生成持续时间（基于正态分布）
        let duration = generateNormalDistribution(
            mean: avgDuration * 3600,
            stdDev: durationVariance * 3600 / 2
        )
        let clampedDuration = max(1800, min(86400, duration)) // 0.5小时 到 24小时
        let endTime = startTime.addingTimeInterval(clampedDuration)
        
        // 创建记录
        let record = AttackRecord(startTime: startTime)
        record.endTime = endTime
        
        // 疼痛评估（正态分布，均值6-7）
        let painIntensity = Int(generateNormalDistribution(mean: 6.5, stdDev: 1.5))
        record.painIntensity = max(1, min(10, painIntensity))
        
        // 疼痛部位（70%单侧，30%双侧或全头）
        if Double.random(in: 0...1) < 0.7 {
            // 单侧
            let side = Bool.random() ? "left" : "right"
            let locations: [PainLocation] = [
                PainLocation(rawValue: "\(side)_temple")!,
                PainLocation(rawValue: "\(side)_orbit")!
            ]
            record.setPainLocations(Array(locations.prefix(Int.random(in: 1...2))))
        } else if Double.random(in: 0...1) < 0.3 {
            // 全头
            record.setPainLocations([.wholehead])
        } else {
            // 双侧
            record.setPainLocations([.leftTemple, .rightTemple])
        }
        
        // 疼痛性质（随机1-3种）
        let qualityCount = Int.random(in: 1...3)
        let selectedQualities = PainQuality.allCases.shuffled().prefix(qualityCount)
        record.setPainQuality(Array(selectedQualities))
        
        // 先兆（20%概率）
        if Double.random(in: 0...1) < 0.2 {
            record.hasAura = true
            let auraCount = Int.random(in: 1...2)
            let selectedAuras = AuraType.allCases.shuffled().prefix(auraCount)
            record.setAuraTypes(Array(selectedAuras))
            record.auraDuration = Double.random(in: 300...3600) // 5分钟到1小时
        }
        
        // 症状（80%常见症状，20%罕见症状）
        let commonSymptoms: [SymptomType] = [.nausea, .photophobia, .phonophobia, .vomiting]
        let rareSymptoms: [SymptomType] = [.dizziness, .palpitation, .allodynia, .osmophobia]
        
        let symptomCount = Int.random(in: 2...5)
        var selectedSymptoms: [SymptomType] = []
        
        for _ in 0..<symptomCount {
            if Double.random(in: 0...1) < 0.8 && !commonSymptoms.isEmpty {
                selectedSymptoms.append(commonSymptoms.randomElement()!)
            } else if !rareSymptoms.isEmpty {
                selectedSymptoms.append(rareSymptoms.randomElement()!)
            }
        }
        
        var symptoms: [Symptom] = []
        for symptomType in Set(selectedSymptoms) {
            let symptom = Symptom(type: symptomType, severity: Int.random(in: 2...5))
            symptom.onset = startTime.addingTimeInterval(Double.random(in: -3600...3600))
            symptoms.append(symptom)
        }
        record.symptomsData = symptoms
        
        // 诱因（重复常见诱因）
        let commonTriggers: [(TriggerCategory, String)] = [
            (.stress, "工作压力"),
            (.sleep, "睡眠不足"),
            (.food, "巧克力"),
            (.environment, "强光"),
            (.lifestyle, "长时间屏幕")
        ]
        
        let triggerCount = Int.random(in: 1...3)
        var triggers: [Trigger] = []
        
        for _ in 0..<triggerCount {
            let (category, specificType) = commonTriggers.randomElement()!
            let trigger = Trigger(category: category, specificType: specificType)
            trigger.timestamp = startTime.addingTimeInterval(-Double.random(in: 3600...43200))
            trigger.confidence = Double.random(in: 0.7...1.0)
            triggers.append(trigger)
        }
        record.triggersData = triggers
        
        // 用药（70%概率有用药）
        if Double.random(in: 0...1) < 0.7 && !medications.isEmpty {
            let medicationCount = Int.random(in: 1...2)
            var medicationLogs: [MedicationLog] = []
            
            for i in 0..<medicationCount {
                let medication = medications.randomElement()!
                let log = MedicationLog(
                    dosage: medication.standardDosage * Double.random(in: 0.8...1.2),
                    timeTaken: startTime.addingTimeInterval(Double(i) * 3600)
                )
                log.medication = medication
                log.unit = medication.unit
                
                // 疗效评估（60%部分缓解，30%完全缓解，10%无效）
                let efficacyRandom = Double.random(in: 0...1)
                if efficacyRandom < 0.3 {
                    log.efficacy = .complete
                } else if efficacyRandom < 0.9 {
                    log.efficacy = .partial
                } else {
                    log.efficacy = .noEffect
                }
                log.efficacyCheckedAt = log.timeTaken.addingTimeInterval(7200)
                
                medicationLogs.append(log)
            }
            record.medicationsData = medicationLogs
        }
        
        // 非药物干预（30%概率）
        if Double.random(in: 0...1) < 0.3 {
            let interventionCount = Int.random(in: 1...3)
            let interventions = NonPharmIntervention.allCases.shuffled().prefix(interventionCount)
            record.nonPharmInterventionList = interventions.map { $0.rawValue }
        }
        
        // 中医证候（30%概率）
        if Double.random(in: 0...1) < 0.3 {
            let patternCount = Int.random(in: 1...2)
            let patterns = TCMPattern.allCases.shuffled().prefix(patternCount)
            record.setTCMPattern(Array(patterns))
        }
        
        // 天气数据
        let weather = generateWeatherSnapshot(for: startTime)
        record.weatherSnapshot = weather
        
        // 备注（20%概率）
        if Double.random(in: 0...1) < 0.2 {
            let notes = [
                "今天压力很大",
                "睡眠不好",
                "天气变化很快",
                "工作很累",
                "吃了不该吃的东西"
            ]
            record.notes = notes.randomElement()
        }
        
        record.createdAt = startTime
        record.updatedAt = startTime
        
        return record
    }
    
    /// 生成天气快照
    private func generateWeatherSnapshot(for date: Date) -> WeatherSnapshot {
        let weather = WeatherSnapshot(timestamp: date)
        
        // 气压（990-1030 hPa，带季节性波动）
        let basePressure = 1013.0
        let seasonalOffset = Double.random(in: -15...15)
        weather.pressure = basePressure + seasonalOffset
        
        // 气压趋势
        weather.pressureTrend = PressureTrend.allCases.randomElement()!
        
        // 温度（15-30°C，带季节性）
        let month = Calendar.current.component(.month, from: date)
        let baseTemp: Double
        if month >= 6 && month <= 8 {
            baseTemp = 28.0 // 夏季
        } else if month >= 12 || month <= 2 {
            baseTemp = 8.0 // 冬季
        } else {
            baseTemp = 18.0 // 春秋
        }
        weather.temperature = baseTemp + Double.random(in: -5...5)
        
        // 湿度（40-80%）
        weather.humidity = Double.random(in: 40...80)
        
        // 风速（0-15 m/s）
        weather.windSpeed = Double.random(in: 0...15)
        
        // 天气状况
        let conditions = ["晴", "多云", "阴", "小雨", "雨", "雾"]
        weather.condition = conditions.randomElement()!
        
        // 位置
        weather.location = "测试位置"
        
        return weather
    }
    
    /// 确保有足够的药物供用药记录使用
    private func ensureMedications() async throws -> [Medication] {
        let descriptor = FetchDescriptor<Medication>()
        let existing = try modelContext.fetch(descriptor)
        
        if existing.count >= 5 {
            return existing
        }
        
        // 生成一些基础药物
        let newMedications = try await generateMedications(count: 5)
        return existing + newMedications
    }
    
    /// 生成药箱数据
    /// - Parameter count: 药物数量（5-30）
    /// - Returns: 生成的药物列表
    func generateMedications(count: Int) async throws -> [Medication] {
        var medications: [Medication] = []
        
        // 按类别分配数量
        let categories: [MedicationCategory] = [.nsaid, .triptan, .preventive, .tcmHerbal, .ergotamine, .other]
        let perCategory = max(1, count / categories.count)
        
        // NSAID
        for (name, dosage, unit) in MedicationPresets.commonNSAIDs.prefix(perCategory) {
            let med = Medication(name: name, category: .nsaid, isAcute: true)
            med.standardDosage = dosage
            med.unit = unit
            med.inventory = Int.random(in: 5...50)
            med.monthlyLimit = 15
            modelContext.insert(med)
            medications.append(med)
        }
        
        // 曲普坦类
        for (name, dosage, unit) in MedicationPresets.commonTriptans.prefix(perCategory) {
            let med = Medication(name: name, category: .triptan, isAcute: true)
            med.standardDosage = dosage
            med.unit = unit
            med.inventory = Int.random(in: 5...30)
            med.monthlyLimit = 10
            modelContext.insert(med)
            medications.append(med)
        }
        
        // 预防性药物
        for (name, dosage, unit) in MedicationPresets.commonPreventive.prefix(perCategory) {
            let med = Medication(name: name, category: .preventive, isAcute: false)
            med.standardDosage = dosage
            med.unit = unit
            med.inventory = Int.random(in: 10...60)
            modelContext.insert(med)
            medications.append(med)
        }
        
        // 中成药
        for (name, dosage, unit) in MedicationPresets.commonTCM.prefix(perCategory) {
            let med = Medication(name: name, category: .tcmHerbal, isAcute: true)
            med.standardDosage = dosage
            med.unit = unit
            med.inventory = Int.random(in: 5...40)
            modelContext.insert(med)
            medications.append(med)
        }
        
        // 麦角胺类
        if count > 15 {
            for (name, dosage, unit) in MedicationPresets.commonErgotamine {
                let med = Medication(name: name, category: .ergotamine, isAcute: true)
                med.standardDosage = dosage
                med.unit = unit
                med.inventory = Int.random(in: 5...20)
                med.monthlyLimit = 10
                modelContext.insert(med)
                medications.append(med)
            }
        }
        
        try modelContext.save()
        return medications
    }
    
    /// 生成自定义标签
    /// - Parameter count: 标签数量（5-20）
    /// - Returns: 生成的标签数量
    func generateCustomLabels(count: Int) async throws -> Int {
        var generatedCount = 0
        
        // 自定义症状标签
        let customSymptoms = [
            "头晕目眩", "耳鸣", "口干", "胸闷", "气短",
            "烦躁", "失眠", "多梦", "健忘", "注意力不集中"
        ]
        
        let symptomCount = min(count / 2, customSymptoms.count)
        for i in 0..<symptomCount {
            let label = CustomLabelConfig(
                category: "symptom",
                labelKey: "custom_symptom_\(i)",
                displayName: customSymptoms[i],
                isDefault: false,
                subcategory: "tcm",
                sortOrder: 100 + i
            )
            modelContext.insert(label)
            generatedCount += 1
        }
        
        // 自定义诱因标签
        let customTriggers = [
            "看手机过久", "吹空调", "坐姿不正", "久坐不动",
            "情绪波动", "吵架", "加班", "开车时间长",
            "香水味", "油烟味"
        ]
        
        let triggerCount = min(count - symptomCount, customTriggers.count)
        for i in 0..<triggerCount {
            let label = CustomLabelConfig(
                category: "trigger",
                labelKey: "custom_trigger_\(i)",
                displayName: customTriggers[i],
                isDefault: false,
                subcategory: "lifestyle",
                sortOrder: 100 + i
            )
            modelContext.insert(label)
            generatedCount += 1
        }
        
        try modelContext.save()
        return generatedCount
    }
    
    // MARK: - 数据清空
    
    /// 清空所有数据
    func clearAllData() throws {
        try clearRecords()
        try clearMedications()
        try clearCustomLabels()
    }
    
    /// 清空发作记录
    func clearRecords() throws {
        let descriptor = FetchDescriptor<AttackRecord>()
        let records = try modelContext.fetch(descriptor)
        
        for record in records {
            modelContext.delete(record)
        }
        
        try modelContext.save()
    }
    
    /// 清空药箱数据
    func clearMedications() throws {
        let descriptor = FetchDescriptor<Medication>()
        let medications = try modelContext.fetch(descriptor)
        
        for medication in medications {
            modelContext.delete(medication)
        }
        
        try modelContext.save()
    }
    
    /// 清空自定义标签
    func clearCustomLabels() throws {
        let descriptor = FetchDescriptor<CustomLabelConfig>()
        let labels = try modelContext.fetch(descriptor)
        
        // 只删除非默认标签
        for label in labels where !label.isDefault {
            modelContext.delete(label)
        }
        
        try modelContext.save()
    }
    
    // MARK: - 数据统计
    
    /// 获取当前数据统计
    func getDataStatistics() throws -> DataStatistics {
        let recordCount = try modelContext.fetchCount(FetchDescriptor<AttackRecord>())
        let medicationCount = try modelContext.fetchCount(FetchDescriptor<Medication>())
        let customLabelCount = try modelContext.fetchCount(
            FetchDescriptor<CustomLabelConfig>(
                predicate: #Predicate { !$0.isDefault }
            )
        )
        
        return DataStatistics(
            recordCount: recordCount,
            medicationCount: medicationCount,
            customLabelCount: customLabelCount
        )
    }
    
    // MARK: - 辅助方法
    
    /// 生成正态分布随机数（Box-Muller 变换）
    private func generateNormalDistribution(mean: Double, stdDev: Double) -> Double {
        let u1 = Double.random(in: 0...1)
        let u2 = Double.random(in: 0...1)
        
        let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
        return mean + z0 * stdDev
    }
}

// MARK: - 数据统计结构

struct DataStatistics {
    let recordCount: Int
    let medicationCount: Int
    let customLabelCount: Int
}

#endif
