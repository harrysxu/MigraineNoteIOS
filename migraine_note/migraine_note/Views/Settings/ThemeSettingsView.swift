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
                Text("选择主题")
            }
            
            // 预览区域
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    // 示例卡片
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(AppColors.primary)
                            Text("头痛发作")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text("强度 7")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Text("2026年2月3日 14:30")
                            .font(.caption)
                            .foregroundColor(AppColors.textTertiary)
                        
                        Divider()
                            .background(AppColors.divider)
                        
                        HStack(spacing: AppSpacing.small) {
                            Label("恶心", systemImage: "circle.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.backgroundTertiary)
                                .cornerRadius(6)
                            
                            Label("畏光", systemImage: "circle.fill")
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
                        Button("主按钮") { }
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppColors.primary)
                            .cornerRadius(AppSpacing.cornerRadiusDefault)
                        
                        Button("次按钮") { }
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
                            Text("成功")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppColors.warning)
                            Text("警告")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundStyle(AppColors.error)
                            Text("错误")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(AppColors.info)
                            Text("信息")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            } header: {
                Text("主题预览")
            } footer: {
                Text("预览当前主题下的界面效果")
            }
            
            // 说明
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label("自动适配", systemImage: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                    Text("界面会自动适配您选择的主题模式")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label("护眼设计", systemImage: "eye.fill")
                        .foregroundColor(AppColors.info)
                    Text("深色模式可在暗光环境下保护眼睛")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label("跟随系统", systemImage: "gear")
                        .foregroundColor(AppColors.textSecondary)
                    Text("选择跟随系统时,将根据系统时间自动切换")
                        .font(.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            } header: {
                Text("主题说明")
            }
        }
        .navigationTitle("主题设置")
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
