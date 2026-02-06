//
//  CSVExporter.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/3.
//

import Foundation
import SwiftData

/// CSV导出工具类
class CSVExporter {
    
    // MARK: - 导出发作记录
    
    /// 导出发作记录为CSV格式
    /// - Parameters:
    ///   - attacks: 要导出的发作记录
    ///   - dateRange: 可选的日期范围（用于文件名）
    /// - Returns: CSV数据
    func exportAttacks(_ attacks: [AttackRecord], dateRange: (Date, Date)? = nil) -> Data {
        var csvString = ""
        
        // UTF-8 BOM，确保Excel正确识别中文
        csvString += "\u{FEFF}"
        
        // CSV表头
        let headers = [
            "记录ID",
            "发作日期",
            "发作时间",
            "结束日期",
            "结束时间",
            "持续时长(小时)",
            "疼痛强度(0-10)",
            "疼痛部位",
            "疼痛性质",
            "有先兆",
            "先兆类型",
            "先兆持续时间(分钟)",
            "伴随症状",
            "症状严重程度",
            "诱因",
            "诱因类别",
            "用药",
            "用药剂量",
            "用药疗效",
            "副作用",
            "非药物干预",
            "天气情况",
            "中医证候",
            "备注",
            "创建时间"
        ]
        csvString += headers.joined(separator: ",") + "\n"
        
        // 按时间排序
        let sortedAttacks = attacks.sorted { $0.startTime < $1.startTime }
        
        // 遍历每条记录
        for attack in sortedAttacks {
            let row = [
                escapeCSV(attack.id.uuidString),
                escapeCSV(formatDate(attack.startTime)),
                escapeCSV(formatTime(attack.startTime)),
                escapeCSV(attack.endTime.map { formatDate($0) } ?? ""),
                escapeCSV(attack.endTime.map { formatTime($0) } ?? ""),
                escapeCSV(formatDuration(attack.duration)),
                escapeCSV(String(attack.painIntensity)),
                escapeCSV(attack.painLocation.joined(separator: "; ")),
                escapeCSV(attack.painQuality.joined(separator: "; ")),
                escapeCSV(attack.hasAura ? "是" : "否"),
                escapeCSV(attack.auraTypes.joined(separator: "; ")),
                escapeCSV(attack.auraDuration.map { String(format: "%.1f", $0 / 60) } ?? ""),
                escapeCSV(attack.symptoms.map { $0.name }.joined(separator: "; ")),
                escapeCSV(attack.symptoms.map { "\($0.name):\($0.severity)" }.joined(separator: "; ")),
                escapeCSV(attack.triggers.map { $0.name }.joined(separator: "; ")),
                escapeCSV(attack.triggers.map { $0.category.rawValue }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.displayName }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.dosageString }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.efficacy.displayName }.joined(separator: "; ")),
                escapeCSV(attack.medications.flatMap { $0.sideEffects }.joined(separator: "; ")),
                escapeCSV(attack.nonPharmInterventionList.joined(separator: "; ")),
                escapeCSV(formatWeather(attack.weatherSnapshot)),
                escapeCSV(attack.tcmPattern.joined(separator: "; ")),
                escapeCSV(attack.notes ?? ""),
                escapeCSV(formatDateTime(attack.createdAt))
            ]
            csvString += row.joined(separator: ",") + "\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    // MARK: - 导出综合报告（统计数据 + 详细记录）
    
    /// 导出综合报告为CSV格式，包含统计数据和详细记录
    /// - Parameters:
    ///   - attacks: 发作记录
    ///   - analytics: 分析引擎
    ///   - dateRange: 日期范围
    /// - Returns: CSV数据
    func exportComprehensiveReport(_ attacks: [AttackRecord], analytics: AnalyticsEngine, dateRange: (Date, Date)) -> Data {
        var csvString = ""
        
        // UTF-8 BOM，确保Excel正确识别中文
        csvString += "\u{FEFF}"
        
        // 标题
        csvString += "偏头痛综合数据报告\n"
        csvString += "统计时间范围: \(formatDate(dateRange.0)) 至 \(formatDate(dateRange.1))\n"
        csvString += "生成时间: \(formatDateTime(Date()))\n"
        csvString += "\n"
        
        // ===== 第一部分：统计数据 =====
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "【第一部分：统计数据】\n"
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "\n"
        
        // 整体概况
        csvString += "整体概况\n"
        csvString += "指标,数值\n"
        csvString += "发作次数,\(attacks.count)\n"
        
        let attackDays = Set(attacks.map { Calendar.current.startOfDay(for: $0.startTime) }).count
        csvString += "发作天数,\(attackDays)\n"
        
        let avgIntensity = attacks.isEmpty ? 0 : Double(attacks.map { $0.painIntensity }.reduce(0, +)) / Double(attacks.count)
        csvString += "平均疼痛强度,\(String(format: "%.1f", avgIntensity))\n"
        
        let totalMeds = attacks.reduce(0) { $0 + $1.medications.count }
        csvString += "总用药次数,\(totalMeds)\n"
        
        let durationStats = analytics.analyzeDurationStatistics(in: dateRange)
        csvString += "平均持续时长(小时),\(String(format: "%.1f", durationStats.averageDurationHours))\n"
        csvString += "\n"
        
        // 疼痛强度分布
        csvString += "疼痛强度分布\n"
        csvString += "强度级别,次数,占比\n"
        let intensityDist = analytics.analyzePainIntensityDistribution(in: dateRange)
        csvString += "轻度(1-3),\(intensityDist.mild),\(String(format: "%.1f%%", intensityDist.mildPercentage))\n"
        csvString += "中度(4-6),\(intensityDist.moderate),\(String(format: "%.1f%%", intensityDist.moderatePercentage))\n"
        csvString += "重度(7-10),\(intensityDist.severe),\(String(format: "%.1f%%", intensityDist.severePercentage))\n"
        csvString += "\n"
        
        // 疼痛部位统计
        csvString += "疼痛部位统计(Top 5)\n"
        csvString += "部位,次数,占比\n"
        let locationFreq = analytics.analyzePainLocationFrequency(in: dateRange)
        for location in locationFreq.prefix(5) {
            csvString += "\(escapeCSV(location.locationName)),\(location.count),\(String(format: "%.1f%%", location.percentage))\n"
        }
        csvString += "\n"
        
        // 疼痛性质统计
        csvString += "疼痛性质统计\n"
        csvString += "性质,次数,占比\n"
        let qualityFreq = analytics.analyzePainQualityFrequency(in: dateRange)
        for quality in qualityFreq {
            csvString += "\(escapeCSV(quality.qualityName)),\(quality.count),\(String(format: "%.1f%%", quality.percentage))\n"
        }
        csvString += "\n"
        
        // 诱因统计
        csvString += "诱因统计(Top 5)\n"
        csvString += "诱因,次数,占比\n"
        let triggerData = analytics.analyzeTriggerFrequency(in: dateRange)
        for trigger in triggerData.prefix(5) {
            csvString += "\(escapeCSV(trigger.triggerName)),\(trigger.count),\(String(format: "%.1f%%", trigger.percentage))\n"
        }
        csvString += "\n"
        
        // 症状统计
        csvString += "伴随症状统计\n"
        csvString += "症状,次数,占比\n"
        let symptomFreq = analytics.analyzeSymptomFrequency(in: dateRange)
        for symptom in symptomFreq {
            csvString += "\(escapeCSV(symptom.symptomName)),\(symptom.count),\(String(format: "%.1f%%", symptom.percentage))\n"
        }
        csvString += "\n"
        
        // 用药统计
        csvString += "用药统计\n"
        csvString += "药物,次数,占比\n"
        let medicationStats = analytics.analyzeMedicationUsage(in: dateRange)
        for medication in medicationStats.topMedications {
            csvString += "\(escapeCSV(medication.medicationName)),\(medication.count),\(String(format: "%.1f%%", medication.percentage))\n"
        }
        csvString += "\n"
        
        // MOH风险评估
        csvString += "MOH风险评估\n"
        csvString += "指标,数值\n"
        csvString += "总用药次数,\(medicationStats.totalMedicationUses)\n"
        csvString += "用药天数,\(medicationStats.medicationDays)\n"
        csvString += "\n"
        
        // 先兆统计
        let auraStats = analytics.analyzeAuraStatistics(in: dateRange)
        csvString += "先兆统计\n"
        csvString += "总发作次数,\(auraStats.totalAttacks)\n"
        csvString += "有先兆次数,\(auraStats.attacksWithAura)\n"
        csvString += "有先兆占比,\(String(format: "%.1f%%", auraStats.auraPercentage))\n"
        csvString += "\n"
        
        if !auraStats.auraTypeFrequency.isEmpty {
            csvString += "先兆类型统计\n"
            csvString += "先兆类型,次数,占比\n"
            for auraType in auraStats.auraTypeFrequency {
                csvString += "\(escapeCSV(auraType.typeName)),\(auraType.count),\(String(format: "%.1f%%", auraType.percentage))\n"
            }
            csvString += "\n"
        }
        
        // ===== 第二部分：详细记录 =====
        csvString += "\n"
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "【第二部分：详细记录】\n"
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "\n"
        
        // 详细记录表头
        let headers = [
            "记录ID",
            "发作日期",
            "发作时间",
            "结束日期",
            "结束时间",
            "持续时长(小时)",
            "疼痛强度(0-10)",
            "疼痛部位",
            "疼痛性质",
            "有先兆",
            "先兆类型",
            "先兆持续时间(分钟)",
            "伴随症状",
            "症状严重程度",
            "诱因",
            "诱因类别",
            "用药",
            "用药剂量",
            "用药疗效",
            "副作用",
            "非药物干预",
            "天气情况",
            "中医证候",
            "备注",
            "创建时间"
        ]
        csvString += headers.joined(separator: ",") + "\n"
        
        // 按时间排序的详细记录
        let sortedAttacks = attacks.sorted { $0.startTime < $1.startTime }
        
        for attack in sortedAttacks {
            let row = [
                escapeCSV(attack.id.uuidString),
                escapeCSV(formatDate(attack.startTime)),
                escapeCSV(formatTime(attack.startTime)),
                escapeCSV(attack.endTime.map { formatDate($0) } ?? ""),
                escapeCSV(attack.endTime.map { formatTime($0) } ?? ""),
                escapeCSV(formatDuration(attack.duration)),
                escapeCSV(String(attack.painIntensity)),
                escapeCSV(attack.painLocation.joined(separator: "; ")),
                escapeCSV(attack.painQuality.joined(separator: "; ")),
                escapeCSV(attack.hasAura ? "是" : "否"),
                escapeCSV(attack.auraTypes.joined(separator: "; ")),
                escapeCSV(attack.auraDuration.map { String(format: "%.1f", $0 / 60) } ?? ""),
                escapeCSV(attack.symptoms.map { $0.name }.joined(separator: "; ")),
                escapeCSV(attack.symptoms.map { "\($0.name):\($0.severity)" }.joined(separator: "; ")),
                escapeCSV(attack.triggers.map { $0.name }.joined(separator: "; ")),
                escapeCSV(attack.triggers.map { $0.category.rawValue }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.displayName }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.dosageString }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.efficacy.displayName }.joined(separator: "; ")),
                escapeCSV(attack.medications.flatMap { $0.sideEffects }.joined(separator: "; ")),
                escapeCSV(attack.nonPharmInterventionList.joined(separator: "; ")),
                escapeCSV(formatWeather(attack.weatherSnapshot)),
                escapeCSV(attack.tcmPattern.joined(separator: "; ")),
                escapeCSV(attack.notes ?? ""),
                escapeCSV(formatDateTime(attack.createdAt))
            ]
            csvString += row.joined(separator: ",") + "\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    // MARK: - 导出统计数据
    
    /// 导出统计数据为CSV格式
    /// - Parameters:
    ///   - attacks: 发作记录
    ///   - analytics: 分析引擎
    ///   - dateRange: 日期范围
    /// - Returns: CSV数据
    func exportAnalytics(_ attacks: [AttackRecord], analytics: AnalyticsEngine, dateRange: (Date, Date)) -> Data {
        var csvString = ""
        
        // UTF-8 BOM
        csvString += "\u{FEFF}"
        
        // 标题
        csvString += "偏头痛数据统计报告\n"
        csvString += "统计时间范围: \(formatDate(dateRange.0)) 至 \(formatDate(dateRange.1))\n"
        csvString += "生成时间: \(formatDateTime(Date()))\n"
        csvString += "\n"
        
        // 整体概况
        csvString += "整体概况\n"
        csvString += "指标,数值\n"
        csvString += "发作次数,\(attacks.count)\n"
        
        let attackDays = Set(attacks.map { Calendar.current.startOfDay(for: $0.startTime) }).count
        csvString += "发作天数,\(attackDays)\n"
        
        let avgIntensity = attacks.isEmpty ? 0 : Double(attacks.map { $0.painIntensity }.reduce(0, +)) / Double(attacks.count)
        csvString += "平均疼痛强度,\(String(format: "%.1f", avgIntensity))\n"
        
        let totalMeds = attacks.reduce(0) { $0 + $1.medications.count }
        csvString += "总用药次数,\(totalMeds)\n"
        
        let durationStats = analytics.analyzeDurationStatistics(in: dateRange)
        csvString += "平均持续时长(小时),\(String(format: "%.1f", durationStats.averageDurationHours))\n"
        csvString += "\n"
        
        // 疼痛强度分布
        csvString += "疼痛强度分布\n"
        csvString += "强度级别,次数,占比\n"
        let intensityDist = analytics.analyzePainIntensityDistribution(in: dateRange)
        csvString += "轻度(1-3),\(intensityDist.mild),\(String(format: "%.1f%%", intensityDist.mildPercentage))\n"
        csvString += "中度(4-6),\(intensityDist.moderate),\(String(format: "%.1f%%", intensityDist.moderatePercentage))\n"
        csvString += "重度(7-10),\(intensityDist.severe),\(String(format: "%.1f%%", intensityDist.severePercentage))\n"
        csvString += "\n"
        
        // 疼痛部位统计
        csvString += "疼痛部位统计(Top 5)\n"
        csvString += "部位,次数,占比\n"
        let locationFreq = analytics.analyzePainLocationFrequency(in: dateRange)
        for location in locationFreq.prefix(5) {
            csvString += "\(escapeCSV(location.locationName)),\(location.count),\(String(format: "%.1f%%", location.percentage))\n"
        }
        csvString += "\n"
        
        // 诱因统计
        csvString += "诱因统计(Top 5)\n"
        csvString += "诱因,次数,占比\n"
        let triggerData = analytics.analyzeTriggerFrequency(in: dateRange)
        for trigger in triggerData.prefix(5) {
            csvString += "\(escapeCSV(trigger.triggerName)),\(trigger.count),\(String(format: "%.1f%%", trigger.percentage))\n"
        }
        csvString += "\n"
        
        // 症状统计
        csvString += "伴随症状统计\n"
        csvString += "症状,次数,占比\n"
        let symptomFreq = analytics.analyzeSymptomFrequency(in: dateRange)
        for symptom in symptomFreq {
            csvString += "\(escapeCSV(symptom.symptomName)),\(symptom.count),\(String(format: "%.1f%%", symptom.percentage))\n"
        }
        csvString += "\n"
        
        // 用药统计
        csvString += "用药统计\n"
        csvString += "药物,次数,占比\n"
        let medicationStats = analytics.analyzeMedicationUsage(in: dateRange)
        for medication in medicationStats.topMedications {
            csvString += "\(escapeCSV(medication.medicationName)),\(medication.count),\(String(format: "%.1f%%", medication.percentage))\n"
        }
        csvString += "\n"
        
        // 先兆统计
        let auraStats = analytics.analyzeAuraStatistics(in: dateRange)
        csvString += "先兆统计\n"
        csvString += "总发作次数,\(auraStats.totalAttacks)\n"
        csvString += "有先兆次数,\(auraStats.attacksWithAura)\n"
        csvString += "有先兆占比,\(String(format: "%.1f%%", auraStats.auraPercentage))\n"
        csvString += "\n"
        
        if !auraStats.auraTypeFrequency.isEmpty {
            csvString += "先兆类型统计\n"
            csvString += "先兆类型,次数,占比\n"
            for auraType in auraStats.auraTypeFrequency {
                csvString += "\(escapeCSV(auraType.typeName)),\(auraType.count),\(String(format: "%.1f%%", auraType.percentage))\n"
            }
            csvString += "\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    // MARK: - 辅助方法
    
    /// CSV字段转义（处理逗号、引号、换行符）
    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化日期时间
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化持续时间
    private func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "" }
        let hours = duration / 3600
        return String(format: "%.1f", hours)
    }
    
    /// 格式化天气信息
    private func formatWeather(_ weather: WeatherSnapshot?) -> String {
        guard let weather = weather else { return "" }
        var parts: [String] = []
        
        if weather.temperature != 0 {
            parts.append("温度:\(String(format: "%.1f", weather.temperature))°C")
        }
        if weather.humidity != 0 {
            parts.append("湿度:\(String(format: "%.0f", weather.humidity))%")
        }
        if weather.pressure != 0 {
            parts.append("气压:\(String(format: "%.0f", weather.pressure))hPa(\(weather.pressureTrend.rawValue))")
        }
        if weather.windSpeed != 0 {
            parts.append("风速:\(String(format: "%.1f", weather.windSpeed))m/s")
        }
        if !weather.condition.isEmpty {
            parts.append("天气:\(weather.condition)")
        }
        if !weather.location.isEmpty {
            parts.append("位置:\(weather.location)")
        }
        
        return parts.joined(separator: " | ")
    }
    
    /// 生成文件名
    func generateFilename(prefix: String, dateRange: (Date, Date)? = nil) -> String {
        let dateString: String
        if let dateRange = dateRange {
            dateString = "\(formatDate(dateRange.0))至\(formatDate(dateRange.1))"
        } else {
            dateString = formatDate(Date())
        }
        return "\(prefix)_\(dateString).csv"
    }
    
    // MARK: - 导出健康事件
    
    /// 导出健康事件为CSV格式
    /// - Parameters:
    ///   - healthEvents: 要导出的健康事件
    ///   - dateRange: 可选的日期范围
    /// - Returns: CSV数据
    func exportHealthEvents(_ healthEvents: [HealthEvent], dateRange: (Date, Date)? = nil) -> Data {
        var csvString = ""
        
        // UTF-8 BOM
        csvString += "\u{FEFF}"
        
        // CSV表头
        let headers = [
            "事件ID",
            "事件类型",
            "日期",
            "时间",
            "药物名称",
            "剂量",
            "中医治疗类型",
            "治疗时长(分钟)",
            "手术名称",
            "医院",
            "医生",
            "备注",
            "创建时间"
        ]
        csvString += headers.joined(separator: ",") + "\n"
        
        // 按时间排序
        let sortedEvents = healthEvents.sorted { $0.eventDate < $1.eventDate }
        
        // 遍历每条记录
        for event in sortedEvents {
            let row = [
                escapeCSV(event.id.uuidString),
                escapeCSV(event.eventType.rawValue),
                escapeCSV(formatDate(event.eventDate)),
                escapeCSV(formatTime(event.eventDate)),
                escapeCSV(event.medicationLog?.displayName ?? ""),
                escapeCSV(event.medicationLog?.dosageString ?? ""),
                escapeCSV(event.tcmTreatmentType ?? ""),
                escapeCSV(event.tcmDuration.map { String(Int($0 / 60)) } ?? ""),
                escapeCSV(event.surgeryName ?? ""),
                escapeCSV(event.hospitalName ?? ""),
                escapeCSV(event.doctorName ?? ""),
                escapeCSV(event.notes ?? ""),
                escapeCSV(formatDateTime(event.createdAt))
            ]
            csvString += row.joined(separator: ",") + "\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    /// 导出完整健康数据（包括发作记录和健康事件）
    /// - Parameters:
    ///   - attacks: 发作记录
    ///   - healthEvents: 健康事件
    ///   - analytics: 分析引擎
    ///   - dateRange: 日期范围
    /// - Returns: CSV数据
    func exportCompleteHealthData(
        _ attacks: [AttackRecord],
        healthEvents: [HealthEvent],
        analytics: AnalyticsEngine,
        dateRange: (Date, Date)
    ) -> Data {
        var csvString = ""
        
        // UTF-8 BOM
        csvString += "\u{FEFF}"
        
        // 标题
        csvString += "完整健康数据报告\n"
        csvString += "统计时间范围: \(formatDate(dateRange.0)) 至 \(formatDate(dateRange.1))\n"
        csvString += "生成时间: \(formatDateTime(Date()))\n"
        csvString += "\n"
        
        // ===== 第一部分：统计数据 =====
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "【第一部分：偏头痛发作统计】\n"
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "\n"
        
        // 复用现有的统计导出逻辑
        if let statsData = String(data: exportAnalytics(attacks, analytics: analytics, dateRange: dateRange), encoding: .utf8) {
            // 移除BOM和标题（因为已经添加过了）
            let lines = statsData.components(separatedBy: "\n")
            if lines.count > 3 {
                csvString += lines[3...].joined(separator: "\n")
            }
        }
        
        // ===== 第二部分：健康事件统计 =====
        if !healthEvents.isEmpty {
            csvString += "\n"
            csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            csvString += "【第二部分：健康事件统计】\n"
            csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            csvString += "\n"
            
            // 用药依从性
            let adherenceStats = analytics.analyzeMedicationAdherence(in: dateRange)
            csvString += "用药依从性\n"
            csvString += "指标,数值\n"
            csvString += "统计天数,\(adherenceStats.totalDays)\n"
            csvString += "用药天数,\(adherenceStats.medicationDays)\n"
            csvString += "遗漏天数,\(adherenceStats.missedDays)\n"
            csvString += "依从率,\(String(format: "%.1f%%", adherenceStats.adherenceRate))\n"
            csvString += "\n"
            
            // 中医治疗统计
            let tcmStats = analytics.analyzeTCMTreatment(in: dateRange)
            if tcmStats.totalTreatments > 0 {
                csvString += "中医治疗统计\n"
                csvString += "指标,数值\n"
                csvString += "总治疗次数,\(tcmStats.totalTreatments)\n"
                csvString += "平均治疗时长(分钟),\(tcmStats.averageDurationMinutes)\n"
                csvString += "\n"
                
                csvString += "治疗类型分布\n"
                csvString += "类型,次数,占比\n"
                for type in tcmStats.treatmentTypes {
                    csvString += "\(escapeCSV(type.typeName)),\(type.count),\(String(format: "%.1f%%", type.percentage))\n"
                }
                csvString += "\n"
            }
        }
        
        // ===== 第三部分：详细记录 =====
        csvString += "\n"
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "【第三部分：偏头痛发作详细记录】\n"
        csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        csvString += "\n"
        
        // 发作记录表头
        let attackHeaders = [
            "记录ID",
            "发作日期",
            "发作时间",
            "结束日期",
            "结束时间",
            "持续时长(小时)",
            "疼痛强度(0-10)",
            "疼痛部位",
            "疼痛性质",
            "有先兆",
            "先兆类型",
            "先兆持续时间(分钟)",
            "伴随症状",
            "症状严重程度",
            "诱因",
            "诱因类别",
            "用药",
            "用药剂量",
            "用药疗效",
            "副作用",
            "非药物干预",
            "天气情况",
            "中医证候",
            "备注",
            "创建时间"
        ]
        csvString += attackHeaders.joined(separator: ",") + "\n"
        
        // 详细发作记录
        let sortedAttacks = attacks.sorted { $0.startTime < $1.startTime }
        for attack in sortedAttacks {
            let row = [
                escapeCSV(attack.id.uuidString),
                escapeCSV(formatDate(attack.startTime)),
                escapeCSV(formatTime(attack.startTime)),
                escapeCSV(attack.endTime.map { formatDate($0) } ?? ""),
                escapeCSV(attack.endTime.map { formatTime($0) } ?? ""),
                escapeCSV(formatDuration(attack.duration)),
                escapeCSV(String(attack.painIntensity)),
                escapeCSV(attack.painLocation.joined(separator: "; ")),
                escapeCSV(attack.painQuality.joined(separator: "; ")),
                escapeCSV(attack.hasAura ? "是" : "否"),
                escapeCSV(attack.auraTypes.joined(separator: "; ")),
                escapeCSV(attack.auraDuration.map { String(format: "%.1f", $0 / 60) } ?? ""),
                escapeCSV(attack.symptoms.map { $0.name }.joined(separator: "; ")),
                escapeCSV(attack.symptoms.map { "\($0.name):\($0.severity)" }.joined(separator: "; ")),
                escapeCSV(attack.triggers.map { $0.name }.joined(separator: "; ")),
                escapeCSV(attack.triggers.map { $0.category.rawValue }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.displayName }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.dosageString }.joined(separator: "; ")),
                escapeCSV(attack.medications.map { $0.efficacy.displayName }.joined(separator: "; ")),
                escapeCSV(attack.medications.flatMap { $0.sideEffects }.joined(separator: "; ")),
                escapeCSV(attack.nonPharmInterventionList.joined(separator: "; ")),
                escapeCSV(formatWeather(attack.weatherSnapshot)),
                escapeCSV(attack.tcmPattern.joined(separator: "; ")),
                escapeCSV(attack.notes ?? ""),
                escapeCSV(formatDateTime(attack.createdAt))
            ]
            csvString += row.joined(separator: ",") + "\n"
        }
        
        // ===== 第四部分：健康事件详细记录 =====
        if !healthEvents.isEmpty {
            csvString += "\n"
            csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            csvString += "【第四部分：健康事件详细记录】\n"
            csvString += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            csvString += "\n"
            
            // 健康事件表头
            let eventHeaders = [
                "事件ID",
                "事件类型",
                "日期",
                "时间",
                "药物名称",
                "剂量",
                "中医治疗类型",
                "治疗时长(分钟)",
                "手术名称",
                "医院",
                "医生",
                "备注",
                "创建时间"
            ]
            csvString += eventHeaders.joined(separator: ",") + "\n"
            
            // 详细健康事件记录
            let sortedEvents = healthEvents.sorted { $0.eventDate < $1.eventDate }
            for event in sortedEvents {
                let row = [
                    escapeCSV(event.id.uuidString),
                    escapeCSV(event.eventType.rawValue),
                    escapeCSV(formatDate(event.eventDate)),
                    escapeCSV(formatTime(event.eventDate)),
                    escapeCSV(event.medicationLog?.displayName ?? ""),
                    escapeCSV(event.medicationLog?.dosageString ?? ""),
                    escapeCSV(event.tcmTreatmentType ?? ""),
                    escapeCSV(event.tcmDuration.map { String(Int($0 / 60)) } ?? ""),
                    escapeCSV(event.surgeryName ?? ""),
                    escapeCSV(event.hospitalName ?? ""),
                    escapeCSV(event.doctorName ?? ""),
                    escapeCSV(event.notes ?? ""),
                    escapeCSV(formatDateTime(event.createdAt))
                ]
                csvString += row.joined(separator: ",") + "\n"
            }
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
}
