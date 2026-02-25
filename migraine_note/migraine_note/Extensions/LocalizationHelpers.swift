//
//  LocalizationHelpers.swift
//  migraine_note
//
//  Created by AI Assistant on 2026/2/24.
//

import Foundation
import SwiftUI

/// LocalizedStringKey 扩展，方便从字符串键创建
extension LocalizedStringKey {
    /// 从字符串键创建 LocalizedStringKey
    init(_ key: String) {
        self.init(stringLiteral: key)
    }
}

/// 枚举本地化协议
protocol LocalizableEnum: RawRepresentable where RawValue == String {
    /// 本地化后的显示名称
    var localizedName: String { get }
}

/// 默认实现：使用 rawValue 作为本地化键的前缀
extension LocalizableEnum {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
