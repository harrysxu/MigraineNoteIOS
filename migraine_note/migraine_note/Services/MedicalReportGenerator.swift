import Foundation
import PDFKit
import SwiftUI
import SwiftData
import Charts

/// PDF数据导出生成器
/// 生成用于查看和分享的PDF数据摘要
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
    
    /// 生成PDF数据导出文件
    /// - Parameters:
    ///   - attacks: 发作记录列表
    ///   - userProfile: 用户配置（可选）
    ///   - dateRange: 报告时间范围
    ///   - healthEvents: 健康事件列表（可选）
    /// - Returns: PDF文档数据
    func generateReport(
        attacks: [AttackRecord],
        userProfile: UserProfile?,
        dateRange: DateInterval,
        healthEvents: [HealthEvent] = []
    ) throws -> Data {
        
        let dateRangeTuple = (dateRange.start, dateRange.end)
        
        // 预先渲染所有图表为图片
        let chartImages = renderChartImages(attacks: attacks, dateRange: dateRangeTuple)
        
        // 创建PDF渲染器
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "头痛数据导出",
            kCGPDFContextAuthor as String: "头痛管家App",
            kCGPDFContextSubject as String: "头痛数据导出",
            kCGPDFContextCreator as String: "头痛管家 iOS App"
        ]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        var pageCount = 0
        
        let data = renderer.pdfData { context in
            var currentY: CGFloat = marginTop
            
            // === 第一页：标题、患者信息和统计摘要 ===
            context.beginPage()
            pageCount += 1
            currentY = drawTitle(context: context, y: currentY)
            currentY = drawPatientInfo(context: context, y: currentY, profile: userProfile)
            currentY = drawReportPeriod(context: context, y: currentY, dateRange: dateRange)
            
            // 统计摘要
            currentY = drawStatisticsSummary(context: context, y: currentY, attacks: attacks, dateRange: dateRange)
            
            // 持续时间统计
            currentY = ensureSpace(context: context, currentY: currentY, needed: 120, pageCount: &pageCount)
            currentY = drawDurationStatistics(context: context, y: currentY, dateRange: dateRangeTuple)
            
            // MOH评估
            currentY = ensureSpace(context: context, currentY: currentY, needed: 150, pageCount: &pageCount)
            currentY = drawMOHAssessment(context: context, y: currentY, attacks: attacks, dateRange: dateRange)
            
            // === 疼痛强度分布 ===
            currentY = ensureSpace(context: context, currentY: currentY, needed: 120, pageCount: &pageCount)
            currentY = drawPainIntensityDistribution(context: context, y: currentY, dateRange: dateRangeTuple)
            
            // 疼痛强度分布图表
            if let chartImage = chartImages["painIntensity"] {
                currentY = ensureSpace(context: context, currentY: currentY, needed: 180, pageCount: &pageCount)
                currentY = drawChartImage(context: context, y: currentY, image: chartImage, title: nil, height: 160)
            }
            
            // === 疼痛部位统计 ===
            currentY = ensureSpace(context: context, currentY: currentY, needed: 150, pageCount: &pageCount)
            currentY = drawPainLocationFrequency(context: context, y: currentY, dateRange: dateRangeTuple)
            
            // === 疼痛性质统计 ===
            currentY = ensureSpace(context: context, currentY: currentY, needed: 120, pageCount: &pageCount)
            currentY = drawPainQualityFrequency(context: context, y: currentY, dateRange: dateRangeTuple)
            
            // === 诱因分析 ===
            currentY = ensureSpace(context: context, currentY: currentY, needed: 150, pageCount: &pageCount)
            currentY = drawTriggerAnalysis(context: context, y: currentY, attacks: attacks)
            
            // === 伴随症状统计 ===
            currentY = ensureSpace(context: context, currentY: currentY, needed: 120, pageCount: &pageCount)
            currentY = drawSymptomFrequency(context: context, y: currentY, dateRange: dateRangeTuple)
            
            // === 先兆统计 ===
            currentY = ensureSpace(context: context, currentY: currentY, needed: 120, pageCount: &pageCount)
            currentY = drawAuraStatistics(context: context, y: currentY, dateRange: dateRangeTuple)
            
            // === 用药统计 ===
            currentY = ensureSpace(context: context, currentY: currentY, needed: 180, pageCount: &pageCount)
            currentY = drawMedicationUsage(context: context, y: currentY, dateRange: dateRangeTuple)
            
            // === 月度趋势图表 ===
            if let chartImage = chartImages["monthlyTrend"] {
                currentY = ensureSpace(context: context, currentY: currentY, needed: 220, pageCount: &pageCount)
                currentY = drawChartImage(context: context, y: currentY, image: chartImage, title: "月度发作趋势", height: 180)
            }
            
            // === 昼夜节律图表 ===
            if let chartImage = chartImages["circadian"] {
                currentY = ensureSpace(context: context, currentY: currentY, needed: 220, pageCount: &pageCount)
                currentY = drawChartImage(context: context, y: currentY, image: chartImage, title: "发作时间分布（24小时）", height: 180)
            }
            
            // === 星期分布图表 ===
            if let chartImage = chartImages["weekday"] {
                currentY = ensureSpace(context: context, currentY: currentY, needed: 220, pageCount: &pageCount)
                currentY = drawChartImage(context: context, y: currentY, image: chartImage, title: "星期发作分布", height: 180)
            }
            
            // === 健康事件统计 ===
            if !healthEvents.isEmpty {
                // 用药依从性
                currentY = ensureSpace(context: context, currentY: currentY, needed: 120, pageCount: &pageCount)
                currentY = drawMedicationAdherence(context: context, y: currentY, dateRange: dateRangeTuple)
                
                // 中医治疗统计
                currentY = ensureSpace(context: context, currentY: currentY, needed: 120, pageCount: &pageCount)
                currentY = drawTCMTreatmentStats(context: context, y: currentY, dateRange: dateRangeTuple)
            }
            
            // === 详细发作记录表格 ===
            context.beginPage()
            pageCount += 1
            currentY = marginTop
            currentY = drawDetailedRecordsTable(context: context, y: currentY, attacks: attacks)
            
            // === 健康事件记录 ===
            if !healthEvents.isEmpty {
                currentY = ensureSpace(context: context, currentY: currentY, needed: 100, pageCount: &pageCount)
                currentY = drawHealthEventsSection(context: context, y: currentY, healthEvents: healthEvents)
            }
            
            // 页脚（为每一页绘制）
            for page in 1...pageCount {
                drawFooter(context: context, pageNumber: page)
            }
        }
        
        return data
    }
    
    // MARK: - 图表渲染
    
    /// 将所有图表渲染为 UIImage 字典
    private func renderChartImages(attacks: [AttackRecord], dateRange: (Date, Date)) -> [String: UIImage] {
        var images: [String: UIImage] = [:]
        
        let chartWidth: CGFloat = contentWidth
        let chartHeight: CGFloat = 160
        
        // 1. 月度趋势图表
        let monthlyData = getMonthlyTrendData(attacks: attacks, dateRange: dateRange)
        if !monthlyData.isEmpty {
            let monthlyChart = PDFMonthlyTrendChart(data: monthlyData)
                .frame(width: chartWidth, height: chartHeight)
            if let image = renderViewToImage(monthlyChart, size: CGSize(width: chartWidth, height: chartHeight)) {
                images["monthlyTrend"] = image
            }
        }
        
        // 2. 昼夜节律图表
        let circadianData = analyticsEngine.analyzeCircadianPattern(in: dateRange)
        if !circadianData.isEmpty && circadianData.contains(where: { $0.count > 0 }) {
            let circadianChart = PDFCircadianChart(data: circadianData)
                .frame(width: chartWidth, height: chartHeight)
            if let image = renderViewToImage(circadianChart, size: CGSize(width: chartWidth, height: chartHeight)) {
                images["circadian"] = image
            }
        }
        
        // 3. 疼痛强度分布图表
        let intensityDist = analyticsEngine.analyzePainIntensityDistribution(in: dateRange)
        if intensityDist.total > 0 {
            let intensityChart = PDFPainIntensityChart(distribution: intensityDist)
                .frame(width: chartWidth, height: chartHeight)
            if let image = renderViewToImage(intensityChart, size: CGSize(width: chartWidth, height: chartHeight)) {
                images["painIntensity"] = image
            }
        }
        
        // 4. 星期分布图表
        let weekdayData = analyticsEngine.analyzeWeekdayDistribution(in: dateRange)
        if !weekdayData.isEmpty && weekdayData.contains(where: { $0.count > 0 }) {
            let weekdayChart = PDFWeekdayChart(data: weekdayData)
                .frame(width: chartWidth, height: chartHeight)
            if let image = renderViewToImage(weekdayChart, size: CGSize(width: chartWidth, height: chartHeight)) {
                images["weekday"] = image
            }
        }
        
        return images
    }
    
    /// 使用 ImageRenderer 将 SwiftUI View 渲染为 UIImage
    private func renderViewToImage<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let hostView = view
            .background(Color.white)
            .environment(\.colorScheme, .light)
        
        let renderer = ImageRenderer(content: hostView)
        renderer.scale = 2.0 // 高清渲染
        renderer.proposedSize = .init(width: size.width, height: size.height)
        
        return renderer.uiImage
    }
    
    /// 获取月度趋势数据
    private func getMonthlyTrendData(attacks: [AttackRecord], dateRange: (Date, Date)) -> [MonthlyTrendItem] {
        let calendar = Calendar.current
        
        // 根据日期范围决定展示多少个月
        let months = calendar.dateComponents([.month], from: dateRange.0, to: dateRange.1).month ?? 1
        let monthCount = max(min(months + 1, 12), 1)
        
        var result: [MonthlyTrendItem] = []
        
        for i in (0..<monthCount).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: dateRange.1) else { continue }
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            
            let monthAttacks = attacks.filter { $0.startTime >= startOfMonth && $0.startTime < endOfMonth }
            let attackDays = Set(monthAttacks.map { calendar.startOfDay(for: $0.startTime) }).count
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M月"
            formatter.locale = Locale(identifier: "zh_CN")
            let monthName = formatter.string(from: monthDate)
            
            result.append(MonthlyTrendItem(monthName: monthName, attackDays: attackDays))
        }
        
        return result
    }
    
    // MARK: - 绘制方法
    
    /// 确保页面有足够空间，否则换页
    private func ensureSpace(context: UIGraphicsPDFRendererContext, currentY: CGFloat, needed: CGFloat, pageCount: inout Int) -> CGFloat {
        if currentY + needed > pageHeight - marginBottom {
            context.beginPage()
            pageCount += 1
            return marginTop
        }
        return currentY
    }
    
    /// 绘制图表图片到 PDF
    private func drawChartImage(context: UIGraphicsPDFRendererContext, y: CGFloat, image: UIImage, title: String?, height: CGFloat) -> CGFloat {
        var currentY = y
        
        // 绘制标题
        if let title = title {
            currentY = drawSectionTitle(context: context, y: currentY, title: title)
        }
        
        // 绘制图表背景框
        let chartRect = CGRect(x: marginLeft, y: currentY, width: contentWidth, height: height)
        context.cgContext.setStrokeColor(UIColor.separator.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.stroke(chartRect)
        
        // 绘制图片
        image.draw(in: chartRect)
        
        currentY += height + 15
        return currentY
    }
    
    /// 绘制标题
    private func drawTitle(context: UIGraphicsPDFRendererContext, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // 主标题
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let titleText = "头痛数据导出"
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
        let subtitleText = "Headache Data Export"
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
        
        if let profile = profile {
            // 基本信息
            currentY = drawInfoRow(context: context, y: currentY, label: "姓名：", value: profile.name?.isEmpty == false ? profile.name! : "未填写", font: infoFont)
            
            let ageText: String
            if let age = profile.calculatedAge {
                ageText = "\(age)岁"
            } else {
                ageText = "未填写"
            }
            currentY = drawInfoRow(context: context, y: currentY, label: "年龄：", value: ageText, font: infoFont)
            
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
            
            // 血型
            if let bloodType = profile.bloodType {
                currentY = drawInfoRow(context: context, y: currentY, label: "血型：", value: bloodType.rawValue, font: infoFont)
            }
            
            // 身高体重 / BMI
            var bodyInfo: [String] = []
            if let height = profile.height {
                bodyInfo.append("身高 \(String(format: "%.0f", height))cm")
            }
            if let weight = profile.weight {
                bodyInfo.append("体重 \(String(format: "%.1f", weight))kg")
            }
            if let bmi = profile.bmi, let desc = profile.bmiDescription {
                bodyInfo.append("BMI \(String(format: "%.1f", bmi))(\(desc))")
            }
            if !bodyInfo.isEmpty {
                currentY = drawInfoRow(context: context, y: currentY, label: "体格：", value: bodyInfo.joined(separator: "  "), font: infoFont)
            }
            
            // 病史信息
            if let onsetAge = profile.migraineOnsetAge {
                let currentAge = profile.calculatedAge ?? profile.age
                if let currentAge = currentAge {
                    let years = currentAge - onsetAge
                    currentY = drawInfoRow(context: context, y: currentY, label: "病史：", value: "\(max(0, years))年（\(onsetAge)岁首发）", font: infoFont)
                } else {
                    currentY = drawInfoRow(context: context, y: currentY, label: "首发年龄：", value: "\(onsetAge)岁", font: infoFont)
                }
            }
            
            if let migraineType = profile.migraineType {
                currentY = drawInfoRow(context: context, y: currentY, label: "诊断类型：", value: migraineType.rawValue, font: infoFont)
            }
            
            if profile.familyHistory {
                currentY = drawInfoRow(context: context, y: currentY, label: "家族史：", value: "有偏头痛家族史", font: infoFont)
            }
            
            // 过敏史
            if let allergies = profile.allergies, !allergies.isEmpty {
                currentY = drawInfoRow(context: context, y: currentY, label: "药物过敏：", value: allergies, font: infoFont)
            }
            
            // 医疗备注
            if let notes = profile.medicalNotes, !notes.isEmpty {
                currentY = drawInfoRow(context: context, y: currentY, label: "备注：", value: notes, font: infoFont)
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
        let totalMeds = attacks.reduce(0) { $0 + $1.medications.count }
        
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "总发作次数：", value: "\(totalAttacks)次", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "发作天数：", value: "\(attackDays)天", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "平均疼痛强度：", value: String(format: "%.1f/10", averageIntensity), font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "平均持续时间：", value: formatDuration(averageDuration), font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "总用药次数：", value: "\(totalMeds)次", font: infoFont)
        
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
    
    /// 绘制持续时间统计
    private func drawDurationStatistics(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "持续时间统计")
        
        let durationStats = analyticsEngine.analyzeDurationStatistics(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "平均持续时长：", value: String(format: "%.1f小时", durationStats.averageDurationHours), font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "最长持续时长：", value: String(format: "%.1f小时", durationStats.longestDurationHours), font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "最短持续时长：", value: String(format: "%.1f小时", durationStats.shortestDurationHours), font: infoFont)
        
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
    
    /// 绘制疼痛强度分布
    private func drawPainIntensityDistribution(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "疼痛强度分布")
        
        let intensityDist = analyticsEngine.analyzePainIntensityDistribution(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        if intensityDist.total > 0 {
            currentY = drawInfoRow(context: context, y: currentY, label: "轻度 (1-3)：", value: "\(intensityDist.mild)次 (\(String(format: "%.1f%%", intensityDist.mildPercentage)))", font: infoFont)
            currentY = drawInfoRow(context: context, y: currentY, label: "中度 (4-6)：", value: "\(intensityDist.moderate)次 (\(String(format: "%.1f%%", intensityDist.moderatePercentage)))", font: infoFont)
            currentY = drawInfoRow(context: context, y: currentY, label: "重度 (7-10)：", value: "\(intensityDist.severe)次 (\(String(format: "%.1f%%", intensityDist.severePercentage)))", font: infoFont)
        } else {
            currentY = drawNoDataNote(context: context, y: currentY)
        }
        
        currentY += 10
        return currentY
    }
    
    /// 绘制疼痛部位统计
    private func drawPainLocationFrequency(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "疼痛部位统计 (Top 5)")
        
        let locationFreq = analyticsEngine.analyzePainLocationFrequency(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        if locationFreq.isEmpty {
            currentY = drawNoDataNote(context: context, y: currentY)
        } else {
            for location in locationFreq.prefix(5) {
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "\(location.locationName)：",
                    value: "\(location.count)次 (\(String(format: "%.1f%%", location.percentage)))",
                    font: infoFont
                )
            }
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制疼痛性质统计
    private func drawPainQualityFrequency(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "疼痛性质统计")
        
        let qualityFreq = analyticsEngine.analyzePainQualityFrequency(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        if qualityFreq.isEmpty {
            currentY = drawNoDataNote(context: context, y: currentY)
        } else {
            for quality in qualityFreq {
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "\(quality.qualityName)：",
                    value: "\(quality.count)次 (\(String(format: "%.1f%%", quality.percentage)))",
                    font: infoFont
                )
            }
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制诱因分析
    private func drawTriggerAnalysis(context: UIGraphicsPDFRendererContext, y: CGFloat, attacks: [AttackRecord]) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "诱因分析 (Top 10)")
        
        // 统计诱因频次
        var triggerCounts: [String: Int] = [:]
        for attack in attacks {
            for trigger in attack.triggers {
                triggerCounts[trigger.name, default: 0] += 1
            }
        }
        
        if triggerCounts.isEmpty {
            currentY = drawNoDataNote(context: context, y: currentY)
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
    
    /// 绘制伴随症状统计
    private func drawSymptomFrequency(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "伴随症状统计")
        
        let symptomFreq = analyticsEngine.analyzeSymptomFrequency(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        if symptomFreq.isEmpty {
            currentY = drawNoDataNote(context: context, y: currentY)
        } else {
            for symptom in symptomFreq {
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "\(symptom.symptomName)：",
                    value: "\(symptom.count)次 (\(String(format: "%.1f%%", symptom.percentage)))",
                    font: infoFont
                )
            }
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制先兆统计
    private func drawAuraStatistics(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "先兆统计")
        
        let auraStats = analyticsEngine.analyzeAuraStatistics(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "总发作次数：", value: "\(auraStats.totalAttacks)次", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "有先兆次数：", value: "\(auraStats.attacksWithAura)次", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "有先兆占比：", value: String(format: "%.1f%%", auraStats.auraPercentage), font: infoFont)
        
        if !auraStats.auraTypeFrequency.isEmpty {
            currentY += 5
            let subtitleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            "先兆类型分布：".draw(at: CGPoint(x: marginLeft, y: currentY), withAttributes: subtitleAttrs)
            currentY += 18
            
            for auraType in auraStats.auraTypeFrequency {
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "  \(auraType.typeName)：",
                    value: "\(auraType.count)次 (\(String(format: "%.1f%%", auraType.percentage)))",
                    font: infoFont
                )
            }
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制用药统计
    private func drawMedicationUsage(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "用药统计")
        
        let medicationStats = analyticsEngine.analyzeMedicationUsage(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "总用药次数：", value: "\(medicationStats.totalMedicationUses)次", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "用药天数：", value: "\(medicationStats.medicationDays)天", font: infoFont)
        
        // 药物分类统计
        if !medicationStats.categoryBreakdown.isEmpty {
            currentY += 5
            let subtitleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            "药物分类统计：".draw(at: CGPoint(x: marginLeft, y: currentY), withAttributes: subtitleAttrs)
            currentY += 18
            
            for category in medicationStats.categoryBreakdown {
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "  \(category.categoryName)：",
                    value: "\(category.count)次 (\(String(format: "%.1f%%", category.percentage)))",
                    font: infoFont
                )
            }
        }
        
        // Top 用药
        if !medicationStats.topMedications.isEmpty {
            currentY += 5
            let subtitleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            "常用药物排名：".draw(at: CGPoint(x: marginLeft, y: currentY), withAttributes: subtitleAttrs)
            currentY += 18
            
            for (index, medication) in medicationStats.topMedications.prefix(5).enumerated() {
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "  \(index + 1). \(medication.medicationName)：",
                    value: "\(medication.count)次 (\(String(format: "%.1f%%", medication.percentage)))",
                    font: infoFont
                )
            }
        }
        
        currentY += 15
        return currentY
    }
    
    /// 绘制用药依从性统计
    private func drawMedicationAdherence(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "用药依从性")
        
        let adherenceStats = analyticsEngine.analyzeMedicationAdherence(in: dateRange)
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "统计天数：", value: "\(adherenceStats.totalDays)天", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "用药天数：", value: "\(adherenceStats.medicationDays)天", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "遗漏天数：", value: "\(adherenceStats.missedDays)天", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "依从率：", value: String(format: "%.1f%%", adherenceStats.adherenceRate), font: infoFont)
        
        currentY += 15
        return currentY
    }
    
    /// 绘制中医治疗统计
    private func drawTCMTreatmentStats(context: UIGraphicsPDFRendererContext, y: CGFloat, dateRange: (Date, Date)) -> CGFloat {
        var currentY = y
        
        let tcmStats = analyticsEngine.analyzeTCMTreatment(in: dateRange)
        guard tcmStats.totalTreatments > 0 else { return currentY }
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "中医治疗统计")
        
        let infoFont = UIFont.systemFont(ofSize: 11)
        
        currentY = drawInfoRow(context: context, y: currentY, label: "总治疗次数：", value: "\(tcmStats.totalTreatments)次", font: infoFont)
        currentY = drawInfoRow(context: context, y: currentY, label: "平均治疗时长：", value: "\(tcmStats.averageDurationMinutes)分钟", font: infoFont)
        
        if !tcmStats.treatmentTypes.isEmpty {
            currentY += 5
            let subtitleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            "治疗类型分布：".draw(at: CGPoint(x: marginLeft, y: currentY), withAttributes: subtitleAttrs)
            currentY += 18
            
            for type in tcmStats.treatmentTypes {
                currentY = drawInfoRow(
                    context: context,
                    y: currentY,
                    label: "  \(type.typeName)：",
                    value: "\(type.count)次 (\(String(format: "%.1f%%", type.percentage)))",
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
            let medications = attack.medications.prefix(2).map { $0.displayName }.joined(separator: ",")
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
    
    /// 绘制健康事件章节
    private func drawHealthEventsSection(context: UIGraphicsPDFRendererContext, y: CGFloat, healthEvents: [HealthEvent]) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionTitle(context: context, y: currentY, title: "健康事件记录")
        
        let headerFont = UIFont.systemFont(ofSize: 9, weight: .medium)
        let cellFont = UIFont.systemFont(ofSize: 8)
        let rowHeight: CGFloat = 25
        
        let columns: [(title: String, width: CGFloat)] = [
            ("日期", 65),
            ("类型", 50),
            ("内容", 130),
            ("详情", 130),
            ("备注", 120)
        ]
        
        // 绘制表头
        var xOffset = marginLeft
        for column in columns {
            drawTableCell(context: context, x: xOffset, y: currentY, width: column.width, height: rowHeight, text: column.title, font: headerFont, isHeader: true)
            xOffset += column.width
        }
        currentY += rowHeight
        
        // 按时间排序
        let sortedEvents = healthEvents.sorted { $0.eventDate > $1.eventDate }
        
        for event in sortedEvents {
            // 检查是否需要换页
            if currentY > pageHeight - marginBottom - 50 {
                context.beginPage()
                currentY = marginTop
            }
            
            xOffset = marginLeft
            
            // 日期
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[0].width, height: rowHeight, text: event.eventDate.compactDateTime(), font: cellFont)
            xOffset += columns[0].width
            
            // 类型
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[1].width, height: rowHeight, text: event.eventType.rawValue, font: cellFont)
            xOffset += columns[1].width
            
            // 内容
            let contentText: String
            switch event.eventType {
            case .medication:
                contentText = event.displayTitle
            case .tcmTreatment:
                contentText = event.tcmTreatmentType ?? "中医治疗"
            case .surgery:
                contentText = event.surgeryName ?? "手术"
            }
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[2].width, height: rowHeight, text: contentText, font: cellFont)
            xOffset += columns[2].width
            
            // 详情
            let detailText: String
            switch event.eventType {
            case .medication:
                detailText = event.displayDetail ?? "-"
            case .tcmTreatment:
                if let duration = event.tcmDuration, duration > 0 {
                    detailText = "\(Int(duration / 60))分钟"
                } else {
                    detailText = "-"
                }
            case .surgery:
                var details: [String] = []
                if let hospital = event.hospitalName { details.append(hospital) }
                if let doctor = event.doctorName { details.append(doctor) }
                detailText = details.isEmpty ? "-" : details.joined(separator: " ")
            }
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[3].width, height: rowHeight, text: detailText, font: cellFont)
            xOffset += columns[3].width
            
            // 备注
            drawTableCell(context: context, x: xOffset, y: currentY, width: columns[4].width, height: rowHeight, text: event.notes ?? "-", font: cellFont)
            
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
        
        // 绘制文本（限制在单元格内）
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]
        
        let textRect = CGRect(x: x + 2, y: y + 2, width: width - 4, height: height - 4)
        let textSize = text.size(withAttributes: textAttrs)
        
        // 水平居中
        let textX = x + max(2, (width - textSize.width) / 2)
        let textY = y + (height - textSize.height) / 2
        
        // 如果文字太长，使用截断绘制
        if textSize.width > width - 4 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.alignment = .center
            var truncAttrs = textAttrs
            truncAttrs[.paragraphStyle] = paragraphStyle
            text.draw(in: textRect, withAttributes: truncAttrs)
        } else {
            text.draw(at: CGPoint(x: textX, y: textY), withAttributes: textAttrs)
        }
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
    
    /// 绘制无数据提示
    private func drawNoDataNote(context: UIGraphicsPDFRendererContext, y: CGFloat) -> CGFloat {
        let noteAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.secondaryLabel
        ]
        "暂无数据".draw(at: CGPoint(x: marginLeft, y: y), withAttributes: noteAttrs)
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

// MARK: - PDF图表数据模型

struct MonthlyTrendItem: Identifiable {
    let id = UUID()
    let monthName: String
    let attackDays: Int
}

// MARK: - PDF专用图表视图

/// 月度趋势柱状图（用于PDF渲染）
struct PDFMonthlyTrendChart: View {
    let data: [MonthlyTrendItem]
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("月份", item.monthName),
                    y: .value("发作天数", item.attackDays)
                )
                .foregroundStyle(
                    item.attackDays >= 15 ? Color.red : Color.blue
                )
                .cornerRadius(4)
                .annotation(position: .top) {
                    Text("\(item.attackDays)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYAxisLabel("发作天数")
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(.system(size: 9))
                    }
                }
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name)
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

/// 昼夜节律图表（用于PDF渲染）
struct PDFCircadianChart: View {
    let data: [CircadianData]
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                AreaMark(
                    x: .value("小时", item.hour),
                    yStart: .value("起点", 0),
                    yEnd: .value("次数", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("小时", item.hour),
                    y: .value("次数", item.count)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXScale(domain: 0...23)
        .chartXAxisLabel("时间（小时）")
        .chartYAxisLabel("发作次数")
        .chartXAxis {
            AxisMarks(values: [0, 3, 6, 9, 12, 15, 18, 21]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text("\(hour)时")
                            .font(.system(size: 8))
                    }
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(.system(size: 9))
                    }
                }
                AxisGridLine()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

/// 疼痛强度分布图表（用于PDF渲染）
struct PDFPainIntensityChart: View {
    let distribution: PainIntensityDistribution
    
    private var chartData: [(name: String, count: Int, color: Color)] {
        [
            ("轻度(1-3)", distribution.mild, .green),
            ("中度(4-6)", distribution.moderate, .orange),
            ("重度(7-10)", distribution.severe, .red)
        ]
    }
    
    var body: some View {
        Chart {
            ForEach(chartData, id: \.name) { item in
                BarMark(
                    x: .value("级别", item.name),
                    y: .value("次数", item.count)
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
                .annotation(position: .top) {
                    if item.count > 0 {
                        Text("\(item.count)次")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxisLabel("发作次数")
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(.system(size: 9))
                    }
                }
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name)
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

/// 星期分布图表（用于PDF渲染）
struct PDFWeekdayChart: View {
    let data: [WeekdayDistribution]
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("星期", item.weekdayName),
                    y: .value("次数", item.count)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
                .annotation(position: .top) {
                    if item.count > 0 {
                        Text("\(item.count)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxisLabel("发作次数")
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text("\(count)")
                            .font(.system(size: 9))
                    }
                }
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let name = value.as(String.self) {
                        Text(name)
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
