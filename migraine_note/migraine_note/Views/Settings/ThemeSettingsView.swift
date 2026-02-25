//
//  ThemeSettingsView.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/3.
//

import SwiftUI

/// 主题设置页面
struct ThemeSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        @Bindable var themeManager = themeManager
        
        List {
            // 主题选择
            Section {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            themeManager.setTheme(theme)
                        }
                        // 触觉反馈
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: AppSpacing.medium) {
                            // 图标
                            Image(systemName: theme.icon)
                                .font(.title2)
                                .foregroundStyle(
                                    themeManager.currentTheme == theme ? AppColors.primary : AppColors.textSecondary
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    themeManager.currentTheme == theme ? 
                                    AppColors.primaryLight : AppColors.backgroundSecondary
                                )
                                .cornerRadius(AppSpacing.cornerRadiusSmall)
                            
                            // 文本
                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.rawValue)
                                    .font(.body.weight(.medium))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(theme.description)
                                    .font(.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            
                            Spacer()
                            
                            // 选中标记
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .padding(.vertical, AppSpacing.small)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(String(localized: "theme.select"))
            }
            
            // 预览区域
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    // 示例卡片
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(AppColors.primary)
                            Text(String(localized: "theme.attack.sample"))
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text(String(localized: "theme.intensity.sample"))
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
        Text(String(localized: "theme.date.sample"))
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                        
                        Divider()
                            .background(AppColors.divider)
                        
                        HStack(spacing: AppSpacing.small) {
                            Label(String(localized: "label.symptom.nausea"), systemImage: "circle.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.backgroundTertiary)
                                .cornerRadius(6)
                            
                            Label(String(localized: "label.symptom.photophobia"), systemImage: "circle.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.backgroundTertiary)
                                .cornerRadius(6)
                        }
                        .foregroundColor(AppColors.textSecondary)
                    }
                    .padding()
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppSpacing.cornerRadiusDefault)
                    
                    // 按钮示例
                    HStack(spacing: AppSpacing.medium) {
                        Button(String(localized: "theme.primary.btn")) { }
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppColors.primary)
                            .cornerRadius(AppSpacing.cornerRadiusDefault)
                        
                        Button(String(localized: "theme.secondary.btn")) { }
                            .font(.body.weight(.semibold))
                            .foregroundColor(AppColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppColors.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusDefault)
                                    .stroke(AppColors.divider, lineWidth: 1)
                            )
                    }
                    
                    // 状态色示例
                    HStack(spacing: AppSpacing.small) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                            Text(String(localized: "theme.status.success"))
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppColors.warning)
                            Text(String(localized: "theme.status.warning"))
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundStyle(AppColors.error)
                            Text(String(localized: "theme.status.error"))
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(AppColors.info)
                            Text(String(localized: "theme.status.info"))
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            } header: {
                Text(String(localized: "theme.preview"))
            } footer: {
                Text(String(localized: "theme.preview.footer"))
            }
            
            // 说明
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(String(localized: "theme.auto.adapt"), systemImage: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                    Text(String(localized: "theme.auto.desc"))
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(String(localized: "theme.eye.care"), systemImage: "eye.fill")
                        .foregroundColor(AppColors.info)
                    Text(String(localized: "theme.eye.desc"))
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(String(localized: "theme.follow.system"), systemImage: "gear")
                        .foregroundColor(AppColors.textSecondary)
                    Text(String(localized: "theme.follow.desc"))
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            } header: {
                Text(String(localized: "theme.description.section"))
            }
        }
        .navigationTitle(String(localized: "theme.settings.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview("主题设置 - 跟随系统") {
    NavigationStack {
        ThemeSettingsView()
            .environment(ThemeManager())
    }
}

#Preview("主题设置 - 浅色模式") {
    NavigationStack {
        ThemeSettingsView()
            .environment(ThemeManager())
    }
    .preferredColorScheme(.light)
}

#Preview("主题设置 - 深色模式") {
    NavigationStack {
        ThemeSettingsView()
            .environment(ThemeManager())
    }
    .preferredColorScheme(.dark)
}
