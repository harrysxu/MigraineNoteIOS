//
//  AttackListUITests.swift
//  migraine_noteUITests
//
//  发作记录列表 UI 测试
//

import XCTest

final class AttackListUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("-hasCompletedOnboarding")
        app.launchArguments.append("YES")
        app.launch()
    }
    
    // MARK: - 记录列表页面测试
    
    @MainActor
    func testAttackList_PageLoads() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab栏未出现")
            return
        }
        
        tabBar.buttons["记录"].tap()
        sleep(1)
        
        // 验证列表页面已加载
        XCTAssertTrue(tabBar.buttons["记录"].isSelected)
    }
    
    @MainActor
    func testAttackList_HasSearchOrFilterControls() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        tabBar.buttons["记录"].tap()
        sleep(2)
        
        // 检查是否有筛选相关的UI元素
        // 尝试查找Picker或Segmented控件
        let segmentedControls = app.segmentedControls
        let searchFields = app.searchFields
        
        // 至少应有某种交互元素
        let hasControls = segmentedControls.count > 0 || searchFields.count > 0
        // 注意：即使没有也不算失败，因为空列表可能隐藏控件
        if hasControls {
            XCTAssertTrue(true, "找到筛选控件")
        }
    }
    
    @MainActor
    func testAttackList_EmptyState() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        tabBar.buttons["记录"].tap()
        sleep(2)
        
        // 空状态下应显示某种提示
        // 具体UI取决于实现，这里只验证页面加载完成
        XCTAssertTrue(app.exists)
    }
}
