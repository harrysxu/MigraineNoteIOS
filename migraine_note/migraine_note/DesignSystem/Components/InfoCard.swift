//
//  InfoCard.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import SwiftUI

struct InfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    InfoCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("卡片标题")
                .font(.headline)
            Text("这是一个信息卡片示例")
                .font(.subheadline)
                .foregroundStyle(Color.labelSecondary)
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}
