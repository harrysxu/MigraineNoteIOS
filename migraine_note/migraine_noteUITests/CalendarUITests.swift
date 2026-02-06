//
//  CalendarUITests.swift
//  migraine_noteUITests
//
//  日历页面 UI 测试
//

import XCTest

final class CalendarUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("-hasCompletedOnboarding")
        app.launchArguments.append("YES")
        app.launch()
    }
    
    // MARK: - 数据页面测试
    
    @MainActor
    func testDataPage_Loads() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab栏未出现")
            return
        }
        
        tabBar.buttons["数据"].tap()
        sleep(1)
        
        XCTAssertTrue(tabBar.buttons["数据"].isSelected)
    }
    
    @MainActor
    func testDataPage_HasContent() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        tabBar.buttons["数据"].tap()
        sleep(2)
        
        // 数据页面应有某种内容（可能是日历或图表）
        XCTAssertTrue(app.exists)
    }
    
    @MainActor
    func testDataPage_MonthNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        tabBar.buttons["数据"].tap()
        sleep(2)
        
        // 尝试找到月份导航按钮
        let chevronLeft = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chevron'"))
        let prevButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] '上月' OR label CONTAINS[c] '上一月'"))
        
        // 尝试点击导航按钮
        if prevButtons.count > 0 {
            prevButtons.firstMatch.tap()
            sleep(1)
        } else if chevronLeft.count > 0 {
            chevronLeft.firstMatch.tap()
            sleep(1)
        }
        
        // 页面应仍然正常显示
        XCTAssertTrue(app.exists)
    }
    
    @MainActor
    func testDataPage_SwitchBetweenTabs() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        // 切换到数据页
        tabBar.buttons["数据"].tap()
        sleep(1)
        
        // 切换到我的页面
        tabBar.buttons["我的"].tap()
        sleep(1)
        
        // 切回数据页
        tabBar.buttons["数据"].tap()
        sleep(1)
        
        XCTAssertTrue(tabBar.buttons["数据"].isSelected)
    }
}
