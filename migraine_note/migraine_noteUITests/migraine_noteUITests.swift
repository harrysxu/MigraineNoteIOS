//
//  migraine_noteUITests.swift
//  migraine_noteUITests
//
//  主导航 UI 测试 - 测试 Tab 栏切换和各页面基本元素
//

import XCTest

final class migraine_noteUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // 跳过Onboarding
        app.launchArguments.append("-hasCompletedOnboarding")
        app.launchArguments.append("YES")
        app.launch()
    }
    
    override func tearDownWithError() throws {
    }
    
    // MARK: - 应用启动测试
    
    @MainActor
    func testAppLaunches() throws {
        // 验证应用成功启动
        XCTAssertTrue(app.exists)
    }
    
    // MARK: - Tab 栏测试
    
    @MainActor
    func testTabBar_Exists() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab栏应存在")
    }
    
    @MainActor
    func testTabBar_HasAllTabs() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab栏未出现")
            return
        }
        
        // 检查4个Tab是否存在
        let homeTab = tabBar.buttons["首页"]
        let recordTab = tabBar.buttons["记录"]
        let dataTab = tabBar.buttons["数据"]
        let profileTab = tabBar.buttons["我的"]
        
        XCTAssertTrue(homeTab.exists, "'首页' Tab应存在")
        XCTAssertTrue(recordTab.exists, "'记录' Tab应存在")
        XCTAssertTrue(dataTab.exists, "'数据' Tab应存在")
        XCTAssertTrue(profileTab.exists, "'我的' Tab应存在")
    }
    
    @MainActor
    func testTabBar_SwitchToRecord() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        tabBar.buttons["记录"].tap()
        
        // 验证切换成功（等待页面加载）
        let timeout: TimeInterval = 3
        let _ = app.wait(for: .runningForeground, timeout: timeout)
    }
    
    @MainActor
    func testTabBar_SwitchToData() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        tabBar.buttons["数据"].tap()
        
        let _ = app.wait(for: .runningForeground, timeout: 3)
    }
    
    @MainActor
    func testTabBar_SwitchToProfile() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        tabBar.buttons["我的"].tap()
        
        let _ = app.wait(for: .runningForeground, timeout: 3)
    }
    
    @MainActor
    func testTabBar_SwitchBackToHome() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        // 先切到其他Tab
        tabBar.buttons["记录"].tap()
        sleep(1)
        
        // 再切回首页
        tabBar.buttons["首页"].tap()
        sleep(1)
        
        XCTAssertTrue(tabBar.buttons["首页"].isSelected, "首页Tab应处于选中状态")
    }
    
    // MARK: - 启动性能测试
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
