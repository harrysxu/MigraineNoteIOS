//
//  RecordingFlowUITests.swift
//  migraine_noteUITests
//
//  记录流程 UI 测试
//

import XCTest

final class RecordingFlowUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("-hasCompletedOnboarding")
        app.launchArguments.append("YES")
        app.launch()
    }
    
    // MARK: - 记录流程基本测试
    
    @MainActor
    func testRecordingFlow_CanNavigateToRecordPage() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab栏未出现")
            return
        }
        
        tabBar.buttons["记录"].tap()
        sleep(1)
        
        // 验证已切换到记录页面
        XCTAssertTrue(tabBar.buttons["记录"].isSelected)
    }
    
    @MainActor
    func testRecordingFlow_CancelButton() throws {
        // 尝试找到添加按钮进入记录流程
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        // 寻找添加/记录按钮
        let addButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] '记录'"))
        if addButtons.count > 0 {
            addButtons.firstMatch.tap()
            sleep(1)
            
            // 尝试找取消按钮
            let cancelButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] '取消'"))
            if cancelButtons.count > 0 {
                cancelButtons.firstMatch.tap()
                sleep(1)
            }
        }
    }
}
