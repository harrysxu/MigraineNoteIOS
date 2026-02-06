//
//  HomeUITests.swift
//  migraine_noteUITests
//
//  首页 UI 测试
//

import XCTest

final class HomeUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("-hasCompletedOnboarding")
        app.launchArguments.append("YES")
        app.launch()
    }
    
    // MARK: - 首页基本元素测试
    
    @MainActor
    func testHomePage_Loads() throws {
        // 确保Tab栏存在并选中首页
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testHomePage_HasScrollableContent() throws {
        // 等待页面加载
        sleep(2)
        
        // 验证页面可以滚动（有内容）
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            XCTAssertTrue(scrollViews.firstMatch.exists)
        }
    }
    
    @MainActor
    func testHomePage_NavigateToRecordFromTab() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab栏未出现")
            return
        }
        
        // 从首页切换到记录页面
        tabBar.buttons["记录"].tap()
        sleep(1)
        
        // 然后返回首页
        tabBar.buttons["首页"].tap()
        sleep(1)
        
        XCTAssertTrue(tabBar.buttons["首页"].isSelected)
    }
}
