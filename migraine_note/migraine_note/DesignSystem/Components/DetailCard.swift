//
//  DetailCard.swift
//  migraine_note
//
//  Created on 2026-02-01.
//  带标题和图标的详情卡片组件
//

import SwiftUI

struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            content
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMedium))
        .shadow(color: AppColors.shadowColor, radius: AppSpacing.shadowRadiusSmall)
    }
}

#Preview {
    DetailCard(title: "详情信息", icon: "info.circle") {
        VStack(alignment: .leading, spacing: 8) {
            Text("这是详情内容")
                .font(.body)
            Text("第二行内容")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}
