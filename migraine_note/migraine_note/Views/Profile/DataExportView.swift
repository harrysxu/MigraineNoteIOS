//
//  DataExportView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/3.
//

import SwiftUI
import SwiftData

/// 数据导出视图 - 统一的数据和记录导出功能
struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \AttackRecord.startTime, order: .reverse) private var allAttacks: [AttackRecord]
    @Query private var profiles: [UserProfile]
    
    @State private var selectedTimeRange: ExportTimeRange = .last3Months
    @State private var customStartDate = Date().addingTimeInterval(-30 * 24 * 3600)
    @State private var customEndDate = Date()
    @State private var selectedExportType: ExportType = .csv
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var exportFileURL: URL?
    @State private var exportData: Data?
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
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    
                    // 说明卡片
                    EmotionalCard(style: .default) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.accentPrimary)
                                Text("数据导出")
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)
                            }
                            
                            Text("导出您的偏头痛数据，包含统计分析和详细记录。CSV格式适合数据分析，PDF格式适合打印和医疗就诊。")
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // 时间范围选择
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("时间范围")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Picker("时间范围", selection: $selectedTimeRange) {
                            ForEach(ExportTimeRange.allCases) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedTimeRange == .custom {
                            VStack(spacing: Spacing.sm) {
                                DatePicker("开始日期", selection: $customStartDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                DatePicker("结束日期", selection: $customEndDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                            }
                            .padding(Spacing.md)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(Spacing.cornerRadiusMedium)
                        }
                    }
                    
                    // 文件类型选择
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("文件类型")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Picker("文件类型", selection: $selectedExportType) {
                            ForEach(ExportType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // 文件类型说明
                        HStack(spacing: 8) {
                            Image(systemName: selectedExportType.icon)
                                .font(.caption)
                                .foregroundStyle(Color.accentPrimary)
                            Text(selectedExportType.description)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentPrimary.opacity(0.1))
                        .cornerRadius(Spacing.cornerRadiusSmall)
                    }
                    
                    // 数据预览
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("数据预览")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        EmotionalCard(style: .elevated) {
                            VStack(spacing: Spacing.sm) {
                                DataPreviewRow(label: "发作次数", value: "\(filteredAttacks.count)次")
                                Divider()
                                DataPreviewRow(label: "发作天数", value: "\(attackDaysCount)天")
                                Divider()
                                DataPreviewRow(label: "平均强度", value: String(format: "%.1f/10", averagePainIntensity))
                                Divider()
                                DataPreviewRow(label: "用药天数", value: "\(medicationDaysCount)天")
                            }
                        }
                    }
                    
                    // 错误提示
                    if let errorMessage = errorMessage {
                        EmotionalCard(style: .warning) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.headline)
                                        .foregroundStyle(Color.statusError)
                                    Text("导出失败")
                                        .font(.headline)
                                        .foregroundStyle(Color.textPrimary)
                                }
                                Text(errorMessage)
                                    .font(.body)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    
                    // 导出按钮
                    Button(action: handleExport) {
                        HStack(spacing: 12) {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.title3)
                            }
                            Text(isGenerating ? "生成中..." : "导出数据")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.md)
                        .background(
                            (!isGenerating && !filteredAttacks.isEmpty) ? 
                            Color.accentPrimary : Color.gray
                        )
                        .cornerRadius(Spacing.cornerRadiusMedium)
                    }
                    .disabled(isGenerating || filteredAttacks.isEmpty)
                    
                    if filteredAttacks.isEmpty {
                        Text("所选时间范围内无记录数据")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("数据导出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let fileURL = exportFileURL {
                    ShareSheet(activityItems: [fileURL])
                } else if let data = exportData {
                    ShareSheet(activityItems: [data])
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
    
    // MARK: - 导出处理
    
    private func handleExport() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let dateRange = selectedTimeRange.dateInterval(customStart: customStartDate, customEnd: customEndDate)
                
                switch selectedExportType {
                case .csv:
                    try await exportCSV(dateRange: dateRange)
                case .pdf:
                    try await exportPDF(dateRange: dateRange)
                }
                
                await MainActor.run {
                    isGenerating = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "导出失败：\(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
    
    private func exportCSV(dateRange: DateInterval) async throws {
        let exporter = CSVExporter()
        let analytics = AnalyticsEngine(modelContext: modelContext)
        
        // 使用综合报告导出
        let csvData = exporter.exportComprehensiveReport(
            filteredAttacks,
            analytics: analytics,
            dateRange: (dateRange.start, dateRange.end)
        )
        
        // 创建临时文件
        let tempDirectory = FileManager.default.temporaryDirectory
        let filename = exporter.generateFilename(
            prefix: "偏头痛综合报告",
            dateRange: (dateRange.start, dateRange.end)
        )
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        try csvData.write(to: fileURL, options: .atomic)
        
        await MainActor.run {
            exportFileURL = fileURL
        }
    }
    
    private func exportPDF(dateRange: DateInterval) async throws {
        let generator = MedicalReportGenerator(modelContext: modelContext)
        
        let pdfData = try generator.generateReport(
            attacks: filteredAttacks,
            userProfile: userProfile,
            dateRange: dateRange
        )
        
        // 创建临时文件
        let tempDirectory = FileManager.default.temporaryDirectory
        let filename = "偏头痛医疗报告_\(formatDate(dateRange.start))至\(formatDate(dateRange.end)).pdf"
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        try pdfData.write(to: fileURL)
        
        await MainActor.run {
            exportFileURL = fileURL
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 支持类型

/// 导出类型
enum ExportType: String, CaseIterable, Identifiable {
    case csv = "csv"
    case pdf = "pdf"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .pdf: return "PDF"
        }
    }
    
    var icon: String {
        switch self {
        case .csv: return "tablecells"
        case .pdf: return "doc.fill"
        }
    }
    
    var description: String {
        switch self {
        case .csv: return "包含统计数据和详细记录，适合Excel分析"
        case .pdf: return "专业医疗报告，适合打印和就诊"
        }
    }
}

// MARK: - 数据预览行

private struct DataPreviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("数据导出") {
    DataExportView()
        .modelContainer(for: [AttackRecord.self, UserProfile.self], inMemory: true)
}
