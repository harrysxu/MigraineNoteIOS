//
//  AppToastManagerTests.swift
//  migraine_noteTests
//
//  全局 Toast 管理器单元测试
//

import XCTest
@testable import migraine_note

final class AppToastManagerTests: XCTestCase {
    
    var toastManager: AppToastManager!
    
    override func setUp() {
        super.setUp()
        toastManager = AppToastManager.shared
        toastManager.isShowing = false
    }
    
    override func tearDown() {
        toastManager.isShowing = false
        toastManager = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSingleton() {
        let instance1 = AppToastManager.shared
        let instance2 = AppToastManager.shared
        
        XCTAssertTrue(instance1 === instance2, "应返回同一个单例实例")
    }
    
    // MARK: - Show Methods Tests
    
    func testShowSuccess() async throws {
        toastManager.showSuccess("操作成功")
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 300_000_000)
        
        XCTAssertTrue(toastManager.isShowing)
        XCTAssertEqual(toastManager.message, "操作成功")
        XCTAssertEqual(toastManager.type, .success)
    }
    
    func testShowError() async throws {
        toastManager.showError("操作失败")
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        XCTAssertTrue(toastManager.isShowing)
        XCTAssertEqual(toastManager.message, "操作失败")
        XCTAssertEqual(toastManager.type, .error)
    }
    
    func testShowInfo() async throws {
        toastManager.showInfo("提示信息")
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        XCTAssertTrue(toastManager.isShowing)
        XCTAssertEqual(toastManager.message, "提示信息")
        XCTAssertEqual(toastManager.type, .info)
    }
    
    func testShowWarning() async throws {
        toastManager.showWarning("警告")
        
        try await Task.sleep(nanoseconds: 300_000_000)
        
        XCTAssertTrue(toastManager.isShowing)
        XCTAssertEqual(toastManager.message, "警告")
        XCTAssertEqual(toastManager.type, .warning)
    }
    
    // MARK: - Initial State
    
    func testInitialState() {
        // 重置后状态
        toastManager.isShowing = false
        
        XCTAssertFalse(toastManager.isShowing)
        XCTAssertNotNil(toastManager.message)
    }
}
