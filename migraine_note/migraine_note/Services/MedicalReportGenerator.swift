import Foundation
import PDFKit
import SwiftUI
import SwiftData

/// PDF医疗报告生成器
/// 基于《中国偏头痛诊断与治疗指南2024版》
/// 生成供医生参考的专业报告
@MainActor
class MedicalReportGenerator {
    
    // MARK: - 页面设置
    private let pageWidth: CGFloat = 595.2 // A4宽度（72 DPI）
    private let pageHeight: CGFloat = 841.8 // A4高度
    private let marginLeft: CGFloat = 50
    private let marginRight: CGFloat = 50
    private let marginTop: CGFloat = 50
    private let marginBottom: CGFloat = 50
    
    private var contentWidth: CGFloat {
        pageWidth - marginLeft - marginRight
    }
    
    // MARK: - 数据服务
    private let mohDetector: MOHDetector
    private let analyticsEngine: AnalyticsEngine
    
    init(modelContext: ModelContext) {
        self.mohDetector = MOHDetector(modelContext: modelContext)
        self.analyticsEngine = AnalyticsEngine(modelContext: modelContext)
    }
    
    // MARK: - 公开方法
    
    /// 生成PDF医疗报告
    /// - Parameters:
    ///   - attacks: 发作记录列表
    ///   - userProfile: 用户配置（可选）
    ///   - dateRange: 报告时间范围
    /// - Returns: PDF文档数据
    func generateReport(
        attacks: [AttackRecord],
        userProfile: UserProfile?,
        dateRange: DateInterval
    ) throws -> Data {
        
        // 创建PDF渲染器
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "偏头痛医疗报告",
            kCGPDFContextAuthor as String: "偏头痛记录App",
            kCGPDFContextSubject as String: "医疗数据分析报告",
            kCGPDFContextCreator as String: "Migraine Note iOS App"
        ]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            var currentY: CGFloat = marginTop
            
            // 第一页：标题和患者信息
            context.beginPage()
            currentY = drawTitle(context: context, y: currentY)
            currentY = drawPatientInfo(context: context, y: currentY, profile: userProfile)
            currentY = drawReportPeriod(context: context, y: currentY, dateRange: dateRange)
            
            // 统计摘要
            currentY = drawStatisticsSummary(context: context, y: currentY, attacks: attacks, dateRange: dateRange)
            
            // MOH评估
            currentY = drawMOHAssessment(context: context, y: currentY, attacks: attacks, dateRange: dateRange)
            
            // 如果当前页面空间不足，开始新页面
            if currentY > pageHeight - 200 {
                context.beginPage()
                currentY = marginTop
            }
            
            // 诱因分析
            currentY = drawTriggerAnalysis(context: context, y: currentY, attacks: attacks)
            
            // 第二页：详细发作记录表格
            context.beginPage()
            currentY = marginTop
            currentY = drawDetailedRecordsTable(context: context, y: currentY, attacks: attacks)
            
            // 页脚
            drawFooter(context: context, pageNumber: 1)
            drawFooter(context: context, pageNumber: 2)
        }
        
        return data
    }
    
    // MARK: - 绘制方法
    
    /// 绘制标题
    private func drawTitle(context: UIGraphicsPDFRendererContext, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // 主标题
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let titleText = "偏头痛医疗报告"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        
        let titleSize = titleText.size(withAttributes: titleAttrs)
        let titleX = (pageWidth - titleSize.width) / 2
        titleText.draw(at: CGPoint(x: titleX, y: currentY), withAttributes: titleAttrs)
        currentY += titleSize.height + 10
        
        // 副标题
        let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let subtitleText = "Migraine Medical Report"
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let subtitleSize = subtitleText.size(withAttributes: subtitleAttrs)
        let subtitleX = (pageWidth - subtitleSize.width) / 2
        subtitleText.draw(at: CGPoint(x: subtitleX, y: currentY), withAttributes: subtitleAttrs)
        currentY += subtitleSize.height + 30
        
        // 分隔线
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.move(to: CGPoint(x: marginLeft, y: currentY))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - marginRight, y: currentY))
        context.cgContext.strokePath()
        currentY += 20
        
        return currentY
    }
    
    /// 绘制患者信息
    private func drawPatientInfo(context: UIGraphicsPDFRendererContext, y: CGFloat, profile: UserProfile?) -> CGFloat {
        var currentY = y
        
        // 标题
        currentY = drawSectionTitle(context: context, y: currentY, title: "患者信息")
        
        // 字段
        let infoFont = UIFont.systemFont(ofSize: 11)
        let lineHeight: CGFloat = 20
        
        if let profile = profile {
            currentY = drawInfoRow(context: context, y: currentY, label: "姓名：", value: profile.name?.isEmpty == false ? profile.name! : "未填写", font: infoFont)
            currentY = drawInfoRow(context: context, y: currentY, label: "年龄：", value: profile.age != nil ? "\(profile.age!)岁" : "未填写", font: infoFont)
            
            let genderText: String
            if let gender = profile.gender {
                switch gender {
                case .male: genderText = "男性"
                case .female: genderText = "女性"
                case .other: genderText = "其他"
                }
            } else {
                genderText = "未指定"
            }
            currentY = drawInfoRow(context: context, y: currentY, label: "性别：", value: genderText, font: infoFont)
            
            if let onsetAge = profile.migraineOnsetAge, let currentAge = profile.age {
                let years = currentAge - onsetAge
                currentY = drawInfoRow(context: context, y: currentY, label: "病史：", value: "\(years)年", font: infoFont)
            }
        } else {
            currentY = drawInfoRow(context: context, y: currentY, label: "患者信息：", value: "未填写", font: infoFont)
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制报告周期
    private func drawReportPeriod(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: DateInterval) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "报告周期")
        
        let periodText = "\(dateRange.start.fullDate()) 至 \(dateRange.end.fullDate())"
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "时间范围：", value: periodText, font: infoFont)
        
        currentY += 15
        return currentY
    }
    
    /// 绘制统计摘要
    private func drawStatisticsSummary(context: UIGraphicsPDFRendererContext, y: CGFloat, attacks: [AttackRecord], dateRange: DateInterval) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "统计摘要")
        
        // 计算统计数据
        let totalAttacks = attacks.count
        let attackDays = Set(attacks.map { Calendar.current.startOfDay(for: $0.startTime) }).count
        let averageIntensity = attacks.isEmpty ? 0.0 : Double(attacks.map(\.painIntensity).reduce(0, +)) / Double(attacks.count)
        let totalDuration = attacks.compactMap { $0.duration }.reduce(0, +)
        let averageDuration: TimeInterval = attacks.isEmpty ? 0 : totalDuration / TimeInterval(attacks.count)
        
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "总发作次数：", value: "\(totalAttacks)次", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "发作天数：", value: "\(attackDays)天", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "平均疼痛强度：", value: String(format: "%.1f/10", averageIntensity), font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "平均持续时间：", value: formatDuration(averageDuration), font: infoFont)
        
        // 慢性偏头痛判断
        let daysInRange = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 30
        let isMonthlyData = daysInRange >= 28 && daysInRange <= 31
        
        if isMonthlyData && attackDays >= 15 {
            let warningAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.systemRed
            ]
            let warningText = "⚠️ 符合慢性偏头痛诊断标准（≥15天/月）"
            warningText.draw(at: CGPoint(x: marginLeft, y: currentY), withAttributes: warningAttrs)
            currentY += 20
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制MOH评估
    private func drawMOHAssessment(context: UIGraphicsPDFRendererContext, y: CGFloat, attacks: [AttackRecord], dateRange: DateInterval) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "药物过度使用头痛（MOH）评估")
        
        // 计算用药统计
        var medicationDaysSet = Set<Date>()
        var nsaidDays = 0
        var triptanDays = 0
        var opioidDays = 0
        
        for attack in attacks {
            guard let endTime = attack.endTime else { continue }
            let attackDate = Calendar.current.startOfDay(for: endTime)
            
            for log in attack.medications {
                if let medication = log.medication {
                    medicationDaysSet.insert(attackDate)
                    
                    switch medication.category {
                    case .nsaid:
                        nsaidDays += 1
                    case .triptan:
                        triptanDays += 1
                    case .opioid:
                        opioidDays += 1
                    default:
                        break
                    }
                }
            }
        }
        
        let totalMedicationDays = medicationDaysSet.count
        let daysInRange = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 30
        let isMonthlyData = daysInRange >= 28 && daysInRange <= 31
        
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        if isMonthlyData {
            currentY = drawInfoRow(context: context, y: currentY, label: "本月用药天数：", value: "\(totalMedicationDays)天", font: infoFont)
            currentY = drawInfoRow(context: context, y: currentY, label: "NSAID类用药：", value: "\(nsaidDays)天 (阈值: ≥15天)", font: infoFont)
            currentY = drawInfoRow(context: context, y: currentY, label: "曲普坦类用药：", value: "\(triptanDays)天 (阈值: ≥10天)", font: infoFont)
            currentY = drawInfoRow(context: context, y: currentY, label: "阿片类用药：", value: "\(opioidDays)天 (阈值: ≥10天)", font: infoFont)
            
            // MOH风险判断
            var riskLevel = "无风险"
            var riskColor = UIColor.systemGreen
            
            if nsaidDays >= 15 || triptanDays >= 10 || opioidDays >= 10 {
                riskLevel = "高风险 ⚠️"
                riskColor = UIColor.systemRed
            } else if nsaidDays >= 12 || triptanDays >= 8 || opioidDays >= 8 {
                riskLevel = "中风险 ⚠️"
                riskColor = UIColor.systemOrange
            } else if nsaidDays >= 10 || triptanDays >= 6 || opioidDays >= 6 {
                riskLevel = "低风险"
                riskColor = UIColor.systemYellow
            }
            
            let riskAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: riskColor
            ]
            
            currentY = drawInfoRow(context: context, y: currentY, label: "MOH风险等级：", value: riskLevel, font: infoFont, valueAttrs: riskAttrs)
            
            if riskLevel != "无风险" {
                currentY += 5
                let adviceFont = UIFont.systemFont(ofSize: 10)
                let adviceAttrs: [NSAttributedString.Key: Any] = [
                    .font: adviceFont,
                    .foregroundColor: UIColor.secondaryLabel
                ]
                let advice = "建议：请咨询医生，考虑预防性治疗方案，避免急性用药过度使用。"
                let adviceRect = CGRect(x: marginLeft, y: currentY, width: contentWidth, height: 50)
                advice.draw(in: adviceRect, withAttributes: adviceAttrs)
                currentY += 30
            }
        } else {
            let noteAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            "注：MOH评估需要完整的月度数据（28-31天）".draw(at: CGPoint(x: marginLeft, y: currentY), withAttributes: noteAttrs)
            currentY += 20
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制诱因分析
    private func drawTriggerAnalysis(context: UIGraphicsPDFRendererContext, y: CGFloat, attacks: [AttackRecord]) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "诱因分析")
        
        // 统计诱因频次
        var triggerCounts: [String: Int] = [:]
        for attack in attacks {
            for trigger in attack.triggers {
                triggerCounts[trigger.name, default: 0] += 1
            }
        }
        
        if triggerCounts.isEmpty {
            let noteAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
            "暂无诱因数据".draw(at: CGPoint(x: marginLeft, y: currentY), withAttributes: noteAttrs)
            currentY += 20
        } else {
            // 排序并显示前10个
            let sortedTriggers = triggerCounts.sorted { $0.value > $1.value }.prefix(10)
            
            let infoFont = UIFont.systemFont(ofSize: 11)
            let totalCount = attacks.count
            
            for (index, trigger) in sortedTriggers.enumerated() {
                let percentage = totalCount > 0 ? (Double(trigger.value) / Double(totalCount) * 100) : 0
                let rankEmoji = index < 3 ? ["🥇", "🥈", "🥉"][index] : "\(index + 1)."
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "\(rankEmoji) \(trigger.key)：",
                    value: "\(trigger.value)次 (\(String(format: "%.1f", percentage))%)",
                    font: infoFont
                )
            }
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制详细记录表格
    private func drawDetailedRecordsTable(context: UIGraphicsPDFRendererContext, y: CGFloat, attacks: [AttackRecord]) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "详细发作记录")
        
        // 表头
        let headerFont = UIFont.systemFont(ofSize: 9, weight: .medium)
        let cellFont = UIFont.systemFont(ofSize: 8)
        let rowHeight: CGFloat = 25
        
        let columns: [(title: String, width: CGFloat)] = [
            ("日期", 60),
            ("时长", 45),
            ("强度", 30),
            ("部位", 70),
            ("主要诱因", 100),
            ("用药", 80),
            ("疗效", 40)
        ]
        
        // 绘制表头
        var xOffset = marginLeft
        for column in columns {
            drawTableCell(context: context, x: xOffset, y: currentY, width: column.width, height: rowHeight, text: column.title, font: headerFont, isHeader: true)
            xOffset += column.width
        }
        currentY += rowHeight
        
        // 绘制数据行
        let sortedAttacks = attacks.sorted { $0.startTime > $1.startTime }
        
        for attack in sortedAttacks {
            // 检查是否需要换页
            if currentY > pageHeight - marginBottom - 50 {
                context.beginPage()
                currentY = marginTop
            }
            
            xOffset = marginLeft
            
            // 日期
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[0].width, height: rowHeight, text: attack.startTime.compactDateTime(), font: cellFont)
            xOffset += columns[0].width
            
            // 时长
            let durationText = attack.duration != nil ? formatDuration(attack.duration!) : "进行中"
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[1].width, height: rowHeight, text: durationText, font: cellFont)
            xOffset += columns[1].width
            
            // 强度
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[2].width, height: rowHeight, text: "\(attack.painIntensity)", font: cellFont)
            xOffset += columns[2].width
            
            // 部位
            let locations = attack.painLocations.prefix(2).map { $0.shortName }.joined(separator: ",")
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[3].width, height: rowHeight, text: locations, font: cellFont)
            xOffset += columns[3].width
            
            // 主要诱因
            let triggers = attack.triggers.prefix(2).map { $0.name }.joined(separator: ",")
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[4].width, height: rowHeight, text: triggers.isEmpty ? "-" : triggers, font: cellFont)
            xOffset += columns[4].width
            
            // 用药
            let medications = attack.medications.prefix(2).compactMap { $0.medication?.name }.joined(separator: ",")
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[5].width, height: rowHeight, text: medications.isEmpty ? "-" : medications, font: cellFont)
            xOffset += columns[5].width
            
            // 疗效
            let effectiveness = attack.medications.first?.effectiveness
            let effectivenessText: String
            if let eff = effectiveness {
                switch eff {
                case .none: effectivenessText = "无效"
                case .poor: effectivenessText = "轻微"
                case .moderate: effectivenessText = "部分"
                case .good: effectivenessText = "明显"
                case .excellent: effectivenessText = "完全"
                }
            } else {
                effectivenessText = "-"
            }
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[6].width, height: rowHeight, text: effectivenessText, font: cellFont)
            
            currentY += rowHeight
        }
        
        return currentY
    }
    
    /// 绘制表格单元格
    private func drawTableCell(context: UIGraphicsPDFRendererContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, text: String, font: UIFont, isHeader: Bool = false) {
        // 绘制边框
        let cellRect = CGRect(x: x, y: y, width: width, height: height)
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.stroke(cellRect)
        
        // 如果是表头，填充背景色
        if isHeader {
            context.cgContext.setFillColor(UIColor.systemGray5.cgColor)
            context.cgContext.fill(cellRect)
        }
        
        // 绘制文本
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]
        
        let textSize = text.size(withAttributes: textAttrs)
        let textX = x + (width - textSize.width) / 2
        let textY = y + (height - textSize.height) / 2
        text.draw(at: CGPoint(x: textX, y: textY), withAttributes: textAttrs)
    }
    
    /// 绘制页脚
    private func drawFooter(context: UIGraphicsPDFRendererContext, pageNumber: Int) {
        let footerY = pageHeight - marginBottom + 20
        let footerFont = UIFont.systemFont(ofSize: 9)
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // 生成时间
        let timestamp = "生成时间：\(Date().reportDateTime())"
        timestamp.draw(at: CGPoint(x: marginLeft, y: footerY), withAttributes: footerAttrs)
        
        // 页码
        let pageText = "第 \(pageNumber) 页"
        let pageSize = pageText.size(withAttributes: footerAttrs)
        let pageX = pageWidth - marginRight - pageSize.width
        pageText.draw(at: CGPoint(x: pageX, y: footerY), withAttributes: footerAttrs)
        
        // 免责声明
        let disclaimerY = footerY + 15
        let disclaimer = "本报告仅供参考，不构成医疗建议。请咨询专业医生进行诊断和治疗。"
        let disclaimerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.tertiaryLabel
        ]
        let disclaimerSize = disclaimer.size(withAttributes: disclaimerAttrs)
        let disclaimerX = (pageWidth - disclaimerSize.width) / 2
        disclaimer.draw(at: CGPoint(x: disclaimerX, y: disclaimerY), withAttributes: disclaimerAttrs)
    }
    
    // MARK: - 辅助方法
    
    /// 绘制章节标题
    private func drawSectionTitle(context: UIGraphicsPDFRendererContext, y: CGFloat, title: String) -> CGFloat {
        let titleFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label
        ]
        
        title.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: titleAttrs)
        return y + 25
    }
    
    /// 绘制信息行
    private func drawInfoRow(context: UIGraphicsPDFRendererContext, y: CGFloat, label: String, value: String, font: UIFont, valueAttrs: [NSAttributedString.Key: Any]? = nil) -> CGFloat {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: font.pointSize, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let defaultValueAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]
        
        let labelSize = label.size(withAttributes: labelAttrs)
        label.draw(at: CGPoint(x: marginLeft, y: y), withAttributes: labelAttrs)
        
        value.draw(at: CGPoint(x: marginLeft + labelSize.width + 5, y: y), withAttributes: valueAttrs ?? defaultValueAttrs)
        
        return y + 20
    }
    
    /// 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}
