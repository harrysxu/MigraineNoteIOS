//
//  HealthEventTestData.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/5.
//  健康事件测试数据生成器
//

import Foundation
import SwiftData

struct HealthEventTestData {
    
    /// 生成测试健康事件数据
    /// - Parameters:
    ///   - context: SwiftData 模型上下文
    ///   - count: 要生成的事件总数（默认30个）
    ///   - dayRange: 时间范围（过去多少天，默认30天）
    /// - Returns: 实际生成的事件数量
    @discardableResult
    static func generateTestEvents(in context: ModelContext, count: Int = 30, dayRange: Int = 30) -> Int {
        let calendar = Calendar.current
        var generatedCount = 0
        
        // 在指定的时间范围内随机分配事件
        for _ in 0..<count {
            // 随机选择一个日期偏移量
            let dayOffset = Int.random(in: 0..<dayRange)
            guard let baseDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            // 添加随机的小时和分钟
            let hourOffset = Int.random(in: 0...23)
            let minuteOffset = Int.random(in: 0...59)
            
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            dateComponents.hour = hourOffset
            dateComponents.minute = minuteOffset
            
            guard let eventDate = calendar.date(from: dateComponents) else { continue }
            
            // 随机选择事件类型
            let eventType = HealthEventType.allCases.randomElement() ?? .medication
            let event = HealthEvent(eventType: eventType, eventDate: eventDate)
            
            switch eventType {
            case .medication:
                // 创建用药记录
                let medLog = MedicationLog(
                    dosage: Double.random(in: 50...500),
                    timeTaken: eventDate
                )
                medLog.medicationName = ["布洛芬", "对乙酰氨基酚", "盐酸氟桂利嗪", "舒马普坦", "麦角胺咖啡因"].randomElement()
                medLog.unit = "mg"
                
                // 随机疗效评估（40%未评估，30%部分缓解，20%完全缓解，10%无效）
                let efficacyRandom = Double.random(in: 0...1)
                if efficacyRandom < 0.4 {
                    medLog.efficacy = .notEvaluated
                } else if efficacyRandom < 0.7 {
                    medLog.efficacy = .partial
                    medLog.efficacyCheckedAt = eventDate.addingTimeInterval(7200)
                } else if efficacyRandom < 0.9 {
                    medLog.efficacy = .complete
                    medLog.efficacyCheckedAt = eventDate.addingTimeInterval(7200)
                } else {
                    medLog.efficacy = .noEffect
                    medLog.efficacyCheckedAt = eventDate.addingTimeInterval(7200)
                }
                
                // 随机副作用（20%概率）
                if Double.random(in: 0...1) < 0.2 {
                    let possibleSideEffects = ["嗜睡", "胃部不适", "头晕", "口干", "便秘", "恶心"]
                    let count = Int.random(in: 1...2)
                    medLog.sideEffects = Array(possibleSideEffects.shuffled().prefix(count))
                }
                
                context.insert(medLog)
                event.medicationLog = medLog
                event.notes = ["预防性用药", "急性发作用药", "止痛药", nil].randomElement() ?? nil
                
            case .tcmTreatment:
                event.tcmTreatmentType = TCMTreatmentType.allCases.randomElement()?.rawValue
                event.tcmDuration = Double.random(in: 20...60) * 60 // 20-60分钟
                event.notes = ["中医调理", "针灸治疗", "推拿按摩", nil].randomElement() ?? nil
                
            case .surgery:
                event.surgeryName = ["偏头痛神经阻滞术", "三叉神经减压术", "枕神经刺激术"].randomElement()
                event.hospitalName = ["某某医院", "市人民医院", "三甲医院"].randomElement()
                event.doctorName = ["张医生", "李医生", "王医生"].randomElement()
                event.notes = ["手术治疗", "神经阻滞", nil].randomElement() ?? nil
            }
            
            // 设置 updatedAt 与 eventDate 一致
            event.updatedAt = eventDate
            
            context.insert(event)
            generatedCount += 1
        }
        
        do {
            try context.save()
            print("✅ 成功生成 \(generatedCount) 个测试健康事件数据")
            return generatedCount
        } catch {
            print("❌ 生成测试数据失败: \(error)")
            return 0
        }
    }
    
    /// 清除所有健康事件测试数据
    static func clearTestEvents(in context: ModelContext) {
        let descriptor = FetchDescriptor<HealthEvent>()
        
        guard let events = try? context.fetch(descriptor) else { return }
        
        for event in events {
            context.delete(event)
        }
        
        do {
            try context.save()
            print("✅ 成功清除测试健康事件数据")
        } catch {
            print("❌ 清除测试数据失败: \(error)")
        }
    }
}
