import SwiftUI
import SwiftData

/// PDF报告导出视图
struct ExportReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \AttackRecord.startTime, order: .reverse) private var allAttacks: [AttackRecord]
    @Query private var profiles: [UserProfile]
    
    @State private var selectedTimeRange: ExportTimeRange = .lastMonth
    @State private var customStartDate = Date().addingTimeInterval(-30 * 24 * 3600)
    @State private var customEndDate = Date()
    @State private var isGenerating = false
    @State private var generatedPDFData: Data?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    private var filteredAttacks: [AttackRecord] {
        let dateRange = selectedTimeRange.dateInterval(customStart: customStartDate, customEnd: customEndDate)
        return allAttacks.filter { attack in
            attack.startTime >= dateRange.start && attack.startTime <= dateRange.end
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    
                    // 说明卡片
                    InfoCard {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("医疗报告导出")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                            
                            Text("生成专业的PDF医疗报告,可供医生参考。报告包含发作统计、MOH评估、诱因分析和详细记录表格。")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 时间范围选择
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("选择时间范围")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                        
                        Picker("时间范围", selection: $selectedTimeRange) {
                            ForEach(ExportTimeRange.allCases) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedTimeRange == .custom {
                            VStack(spacing: AppSpacing.small) {
                                DatePicker("开始日期", selection: $customStartDate, displayedComponents: .date)
                                DatePicker("结束日期", selection: $customEndDate, displayedComponents: .date)
                            }
                            .padding(AppSpacing.medium)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cornerRadiusMedium)
                        }
                    }
                    
                    // 数据预览
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text("数据预览")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                        
                        VStack(spacing: AppSpacing.small) {
                            PreviewRow(label: "发作次数", value: "\(filteredAttacks.count)次")
                            PreviewRow(label: "发作天数", value: "\(attackDaysCount)天")
                            PreviewRow(label: "平均强度", value: String(format: "%.1f/10", averagePainIntensity))
                            PreviewRow(label: "用药天数", value: "\(medicationDaysCount)天")
                        }
                        .padding(AppSpacing.medium)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cornerRadiusMedium)
                    }
                    
                    // 错误提示
                    if let errorMessage = errorMessage {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Label("生成失败", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(AppSpacing.medium)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(AppSpacing.cornerRadiusMedium)
                    }
                    
                    // 生成按钮
                    PrimaryButton(
                        title: isGenerating ? "生成中..." : "生成PDF报告",
                        action: generateReport,
                        isEnabled: !isGenerating && !filteredAttacks.isEmpty
                    )
                    
                    if filteredAttacks.isEmpty {
                        Text("所选时间范围内无记录数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(AppSpacing.large)
            }
            .navigationTitle("导出医疗报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                generatedPDFData = nil
            }) {
                if let pdfData = generatedPDFData {
                    ShareSheet(activityItems: [pdfData, generatePDFURL(from: pdfData)]) {
                        showShareSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - 计算属性
    
    private var attackDaysCount: Int {
        Set(filteredAttacks.map { Calendar.current.startOfDay(for: $0.startTime) }).count
    }
    
    private var averagePainIntensity: Double {
        guard !filteredAttacks.isEmpty else { return 0 }
        return Double(filteredAttacks.map(\.painIntensity).reduce(0, +)) / Double(filteredAttacks.count)
    }
    
    private var medicationDaysCount: Int {
        var medicationDays = Set<Date>()
        for attack in filteredAttacks {
            if !attack.medications.isEmpty {
                let day = Calendar.current.startOfDay(for: attack.startTime)
                medicationDays.insert(day)
            }
        }
        return medicationDays.count
    }
    
    // MARK: - 方法
    
    private func generateReport() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let generator = MedicalReportGenerator(modelContext: modelContext)
                let dateRange = selectedTimeRange.dateInterval(customStart: customStartDate, customEnd: customEndDate)
                
                let pdfData = try generator.generateReport(
                    attacks: filteredAttacks,
                    userProfile: userProfile,
                    dateRange: dateRange
                )
                
                await MainActor.run {
                    generatedPDFData = pdfData
                    isGenerating = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "PDF生成失败：\(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
    
    private func generatePDFURL(from data: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let filename = "偏头痛医疗报告_\(Date().compactDate()).pdf"
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
        return fileURL
    }
}

// MARK: - 时间范围枚举

enum ExportTimeRange: String, CaseIterable, Identifiable {
    case lastMonth = "last_month"
    case last3Months = "last_3_months"
    case last6Months = "last_6_months"
    case lastYear = "last_year"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .lastMonth: return "近1个月"
        case .last3Months: return "近3个月"
        case .last6Months: return "近6个月"
        case .lastYear: return "近1年"
        case .custom: return "自定义"
        }
    }
    
    func dateInterval(customStart: Date, customEnd: Date) -> DateInterval {
        let now = Date()
        let calendar = Calendar.current
        
        let startDate: Date
        let endDate: Date
        
        switch self {
        case .lastMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            endDate = now
        case .last3Months:
            startDate = calendar.date(byAdding: .month, value: -3, to: now)!
            endDate = now
        case .last6Months:
            startDate = calendar.date(byAdding: .month, value: -6, to: now)!
            endDate = now
        case .lastYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            endDate = now
        case .custom:
            // 规范化自定义日期范围，确保包含完整的结束日期
            let normalized = Date.normalizedDateRange(start: customStart, end: customEnd)
            return DateInterval(start: normalized.start, end: normalized.end)
        }
        
        return DateInterval(start: startDate, end: endDate)
    }
}

// MARK: - 预览行组件

private struct PreviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var onComplete: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

#Preview("导出报告") {
    ExportReportView()
        .modelContainer(for: [AttackRecord.self, UserProfile.self], inMemory: true)
}
