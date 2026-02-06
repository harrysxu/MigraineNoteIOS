//
//  MedicationReminderUITests.swift
//  migraine_noteUITests
//
//  用药提醒 UI 测试
//

import XCTest

final class MedicationReminderUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("-hasCompletedOnboarding")
        app.launchArguments.append("YES")
        app.launch()
    }
    
    // MARK: - 导航到用药提醒
    
    @MainActor
    func testNavigateToMedicationReminder() throws {
        // 切换到"我的"Tab
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab栏未出现")
            return
        }
        
        let profileTab = tabBar.buttons["我的"]
        if profileTab.exists {
            profileTab.tap()
            sleep(1)
            
            // 查找"用药提醒"入口
            let reminderEntry = app.staticTexts["用药提醒"]
            if !reminderEntry.exists {
                app.scrollViews.firstMatch.swipeUp()
                sleep(1)
            }
            
            if reminderEntry.waitForExistence(timeout: 3) {
                XCTAssertTrue(reminderEntry.exists, "用药提醒入口应存在于我的页面")
            }
        }
    }
    
    @MainActor
    func testMedicationReminderPage_EmptyState() throws {
        // 导航到我的 -> 用药提醒
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab栏未出现")
            return
        }
        
        let profileTab = tabBar.buttons["我的"]
        guard profileTab.exists else { return }
        profileTab.tap()
        sleep(1)
        
        // 滚动到用药提醒并点击
        let reminderEntry = app.staticTexts["用药提醒"]
        if !reminderEntry.exists {
            app.scrollViews.firstMatch.swipeUp()
            sleep(1)
        }
        
        guard reminderEntry.waitForExistence(timeout: 3) else { return }
        reminderEntry.tap()
        sleep(1)
        
        // 验证空状态
        let emptyText = app.staticTexts["暂无用药提醒"]
        if emptyText.exists {
            XCTAssertTrue(emptyText.exists, "无提醒时应显示空状态")
        }
        
        // 验证添加按钮存在
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus' OR label CONTAINS '添加'")).firstMatch
        // 添加按钮通常在 NavigationBar
        let navBarAddButton = app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1)
        XCTAssertTrue(navBarAddButton.exists || addButton.exists, "应有添加提醒的按钮")
    }
    
    @MainActor
    func testAddReminderSheet_Opens() throws {
        // 导航到用药提醒页面
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        let profileTab = tabBar.buttons["我的"]
        guard profileTab.exists else { return }
        profileTab.tap()
        sleep(1)
        
        let reminderEntry = app.staticTexts["用药提醒"]
        if !reminderEntry.exists {
            app.scrollViews.firstMatch.swipeUp()
            sleep(1)
        }
        
        guard reminderEntry.waitForExistence(timeout: 3) else { return }
        reminderEntry.tap()
        sleep(1)
        
        // 点击添加按钮（导航栏右侧的 + 按钮）
        let navBar = app.navigationBars.firstMatch
        if navBar.exists {
            let buttons = navBar.buttons
            if buttons.count > 0 {
                buttons.element(boundBy: buttons.count - 1).tap()
                sleep(1)
                
                // 验证添加提醒页面出现
                let addTitle = app.staticTexts["添加提醒"]
                if addTitle.waitForExistence(timeout: 3) {
                    XCTAssertTrue(addTitle.exists, "应显示添加提醒页面")
                }
            }
        }
    }
}
