//
//  ThemeManagerTests.swift
//  migraine_noteTests
//
//  主题管理器单元测试
//

import XCTest
import SwiftUI
@testable import migraine_note

final class ThemeManagerTests: XCTestCase {
    
    var themeManager: ThemeManager!
    
    override func setUp() {
        super.setUp()
        // 清除 UserDefaults 中的主题设置
        UserDefaults.standard.removeObject(forKey: "app_theme")
        themeManager = ThemeManager()
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "app_theme")
        themeManager = nil
        super.tearDown()
    }
    
    // MARK: - 默认状态测试
    
    func testDefaultTheme() {
        XCTAssertEqual(themeManager.currentTheme, .system,
                       "默认应跟随系统主题")
    }
    
    // MARK: - 主题切换测试
    
    func testSetThemeToDark() {
        themeManager.setTheme(.dark)
        
        XCTAssertEqual(themeManager.currentTheme, .dark)
        XCTAssertEqual(themeManager.currentTheme.colorScheme, .dark)
    }
    
    func testSetThemeToLight() {
        themeManager.setTheme(.light)
        
        XCTAssertEqual(themeManager.currentTheme, .light)
        XCTAssertEqual(themeManager.currentTheme.colorScheme, .light)
    }
    
    func testSetThemeToSystem() {
        themeManager.setTheme(.dark)
        themeManager.setTheme(.system)
        
        XCTAssertEqual(themeManager.currentTheme, .system)
        XCTAssertNil(themeManager.currentTheme.colorScheme,
                     "跟随系统时 colorScheme 应为 nil")
    }
    
    // MARK: - 持久化测试
    
    func testThemePersistence_WritesToUserDefaults_Dark() {
        themeManager.setTheme(.dark)
        
        // 直接验证 UserDefaults 中的值
        let saved = UserDefaults.standard.string(forKey: "app_theme")
        XCTAssertEqual(saved, AppTheme.dark.rawValue,
                       "setTheme(.dark) 应将主题保存到 UserDefaults")
    }
    
    func testThemePersistence_WritesToUserDefaults_Light() {
        themeManager.setTheme(.light)
        
        let saved = UserDefaults.standard.string(forKey: "app_theme")
        XCTAssertEqual(saved, AppTheme.light.rawValue,
                       "setTheme(.light) 应将主题保存到 UserDefaults")
    }
    
    func testThemePersistence_WritesToUserDefaults_System() {
        themeManager.setTheme(.system)
        
        let saved = UserDefaults.standard.string(forKey: "app_theme")
        XCTAssertEqual(saved, AppTheme.system.rawValue,
                       "setTheme(.system) 应将主题保存到 UserDefaults")
    }
    
    func testThemePersistence_OverwritesPreviousValue() {
        themeManager.setTheme(.dark)
        themeManager.setTheme(.light)
        
        let saved = UserDefaults.standard.string(forKey: "app_theme")
        XCTAssertEqual(saved, AppTheme.light.rawValue,
                       "最后设置的主题应覆盖之前的值")
    }
    
    // MARK: - AppTheme 枚举测试
    
    func testAppThemeAllCases() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
        XCTAssertTrue(AppTheme.allCases.contains(.system))
        XCTAssertTrue(AppTheme.allCases.contains(.light))
        XCTAssertTrue(AppTheme.allCases.contains(.dark))
    }
    
    func testAppThemeIcons() {
        XCTAssertFalse(AppTheme.system.icon.isEmpty)
        XCTAssertFalse(AppTheme.light.icon.isEmpty)
        XCTAssertFalse(AppTheme.dark.icon.isEmpty)
    }
    
    func testAppThemeDescriptions() {
        XCTAssertFalse(AppTheme.system.description.isEmpty)
        XCTAssertFalse(AppTheme.light.description.isEmpty)
        XCTAssertFalse(AppTheme.dark.description.isEmpty)
    }
    
    func testAppThemeIdentifiable() {
        XCTAssertEqual(AppTheme.system.id, "跟随系统")
        XCTAssertEqual(AppTheme.light.id, "浅色模式")
        XCTAssertEqual(AppTheme.dark.id, "深色模式")
    }
}
