//
//  PainLocation.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/1.
//

import Foundation

/// 疼痛部位枚举
enum PainLocation: String, Codable, CaseIterable, Identifiable {
    // 前额区域
    case forehead = "forehead"
    
    // 左侧
    case leftTemple = "left_temple"
    case leftOrbit = "left_orbit"
    case leftParietal = "left_parietal"
    
    // 右侧
    case rightTemple = "right_temple"
    case rightOrbit = "right_orbit"
    case rightParietal = "right_parietal"
    
    // 顶部和后部
    case vertex = "vertex"
    case occipital = "occipital"
    
    // 其他
    case neck = "neck"
    case wholehead = "wholehead"
    
    var id: String { rawValue }
    
    /// 显示名称
    var displayName: String {
        String(localized: String.LocalizationValue("pain.location.\(rawValue)"))
    }
    
    /// 简短描述
    var shortDescription: String {
        String(localized: String.LocalizationValue("pain.location.short.\(rawValue)"))
    }
}

/// 头部视图方向
enum HeadViewDirection: String, CaseIterable, Identifiable {
    case front = "front"
    case back = "back"
    case left = "left"
    case right = "right"
    
    var id: String { rawValue }
    
    var displayName: String {
        String(localized: String.LocalizationValue("head.view.\(rawValue)"))
    }
    
    /// 该视图方向下可选择的疼痛部位
    var availableLocations: [PainLocation] {
        switch self {
        case .front:
            return [.forehead, .leftOrbit, .rightOrbit, .leftTemple, .rightTemple, .vertex]
        case .back:
            return [.occipital, .neck, .vertex]
        case .left:
            return [.leftTemple, .leftOrbit, .leftParietal, .vertex]
        case .right:
            return [.rightTemple, .rightOrbit, .rightParietal, .vertex]
        }
    }
}
