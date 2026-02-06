//
//  SyncSettingsManagerTests.swift
//  migraine_noteTests
//
//  同步设置管理器单元测试
//

import XCTest
@testable import migraine_note

final class SyncSettingsManagerTests: XCTestCase {
    
    var manager: SyncSettingsManager!
    
    override func setUp() {
        super.setUp()
        // 清除UserDefaults中的同步设置
        UserDefaults.standard.removeObject(forKey: SyncSettingsManager.syncEnabledKey)
        manager = SyncSettingsManager()
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: SyncSettingsManager.syncEnabledKey)
        manager = nil
        super.tearDown()
    }
    
    // MARK: - 默认状态测试
    
    func testDefaultState_SyncDisabled() {
        XCTAssertFalse(manager.isSyncEnabled, "默认状态应为关闭")
    }
    
    func testStaticMethod_DefaultDisabled() {
        XCTAssertFalse(SyncSettingsManager.isSyncCurrentlyEnabled(), "静态方法默认应返回关闭")
    }
    
    // MARK: - enableSync 测试
    
    func testEnableSync() {
        manager.enableSync()
        
        XCTAssertTrue(manager.isSyncEnabled)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: SyncSettingsManager.syncEnabledKey))
        XCTAssertTrue(SyncSettingsManager.isSyncCurrentlyEnabled())
    }
    
    // MARK: - disableSync 测试
    
    func testDisableSync() {
        manager.enableSync()
        manager.disableSync()
        
        XCTAssertFalse(manager.isSyncEnabled)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: SyncSettingsManager.syncEnabledKey))
    }
    
    // MARK: - toggleSync 测试
    
    func testToggleSync_FromDisabledToEnabled() {
        XCTAssertFalse(manager.isSyncEnabled)
        
        manager.toggleSync()
        XCTAssertTrue(manager.isSyncEnabled)
    }
    
    func testToggleSync_FromEnabledToDisabled() {
        manager.enableSync()
        
        manager.toggleSync()
        XCTAssertFalse(manager.isSyncEnabled)
    }
    
    func testToggleSync_TwiceReturnsToOriginal() {
        let original = manager.isSyncEnabled
        
        manager.toggleSync()
        manager.toggleSync()
        
        XCTAssertEqual(manager.isSyncEnabled, original)
    }
    
    // MARK: - 持久化测试
    
    func testPersistence_ValueSurvivesReinit() {
        manager.enableSync()
        
        // 创建新实例（模拟app重启）
        let newManager = SyncSettingsManager()
        
        XCTAssertTrue(newManager.isSyncEnabled, "同步设置应在重新初始化后保留")
    }
    
    // MARK: - isSyncEnabled didSet 测试
    
    func testIsSyncEnabled_DirectSet() {
        manager.isSyncEnabled = true
        
        XCTAssertTrue(UserDefaults.standard.bool(forKey: SyncSettingsManager.syncEnabledKey))
        
        manager.isSyncEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: SyncSettingsManager.syncEnabledKey))
    }
}
