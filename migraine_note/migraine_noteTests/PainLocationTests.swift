//
//  PainLocationTests.swift
//  migraine_noteTests
//
//  疼痛部位枚举单元测试
//

import XCTest
@testable import migraine_note

final class PainLocationTests: XCTestCase {
    
    // MARK: - displayName 测试
    
    func testDisplayName_AllCasesHaveNonEmptyNames() {
        for location in PainLocation.allCases {
            XCTAssertFalse(location.displayName.isEmpty, "\(location) 的 displayName 不应为空")
        }
    }
    
    func testDisplayName_SpecificValues() {
        XCTAssertEqual(PainLocation.forehead.displayName, "前额")
        XCTAssertEqual(PainLocation.leftTemple.displayName, "左侧太阳穴")
        XCTAssertEqual(PainLocation.rightTemple.displayName, "右侧太阳穴")
        XCTAssertEqual(PainLocation.occipital.displayName, "后脑勺")
        XCTAssertEqual(PainLocation.vertex.displayName, "头顶")
        XCTAssertEqual(PainLocation.neck.displayName, "颈部")
        XCTAssertEqual(PainLocation.wholehead.displayName, "全头")
    }
    
    // MARK: - shortDescription 测试
    
    func testShortDescription_AllCasesHaveNonEmptyDescriptions() {
        for location in PainLocation.allCases {
            XCTAssertFalse(location.shortDescription.isEmpty, "\(location) 的 shortDescription 不应为空")
        }
    }
    
    // MARK: - Identifiable 测试
    
    func testIdentifiable_IdEqualsRawValue() {
        for location in PainLocation.allCases {
            XCTAssertEqual(location.id, location.rawValue)
        }
    }
    
    // MARK: - allCases 测试
    
    func testAllCases_Count() {
        XCTAssertEqual(PainLocation.allCases.count, 11, "应有11个疼痛部位")
    }
    
    // MARK: - HeadViewDirection 测试
    
    func testHeadViewDirection_AllCases() {
        XCTAssertEqual(HeadViewDirection.allCases.count, 4)
    }
    
    func testHeadViewDirection_DisplayNames() {
        XCTAssertEqual(HeadViewDirection.front.displayName, "正面")
        XCTAssertEqual(HeadViewDirection.back.displayName, "背面")
        XCTAssertEqual(HeadViewDirection.left.displayName, "左侧")
        XCTAssertEqual(HeadViewDirection.right.displayName, "右侧")
    }
    
    // MARK: - availableLocations 测试
    
    func testFrontView_AvailableLocations() {
        let locations = HeadViewDirection.front.availableLocations
        
        XCTAssertTrue(locations.contains(.forehead))
        XCTAssertTrue(locations.contains(.leftOrbit))
        XCTAssertTrue(locations.contains(.rightOrbit))
        XCTAssertTrue(locations.contains(.leftTemple))
        XCTAssertTrue(locations.contains(.rightTemple))
        XCTAssertTrue(locations.contains(.vertex))
    }
    
    func testBackView_AvailableLocations() {
        let locations = HeadViewDirection.back.availableLocations
        
        XCTAssertTrue(locations.contains(.occipital))
        XCTAssertTrue(locations.contains(.neck))
        XCTAssertTrue(locations.contains(.vertex))
    }
    
    func testLeftView_AvailableLocations() {
        let locations = HeadViewDirection.left.availableLocations
        
        XCTAssertTrue(locations.contains(.leftTemple))
        XCTAssertTrue(locations.contains(.leftOrbit))
        XCTAssertTrue(locations.contains(.leftParietal))
        XCTAssertFalse(locations.contains(.rightTemple))
    }
    
    func testRightView_AvailableLocations() {
        let locations = HeadViewDirection.right.availableLocations
        
        XCTAssertTrue(locations.contains(.rightTemple))
        XCTAssertTrue(locations.contains(.rightOrbit))
        XCTAssertTrue(locations.contains(.rightParietal))
        XCTAssertFalse(locations.contains(.leftTemple))
    }
    
    func testVertex_AvailableInAllViews() {
        for direction in HeadViewDirection.allCases {
            XCTAssertTrue(direction.availableLocations.contains(.vertex),
                          "头顶应在\(direction.displayName)视角可选")
        }
    }
}
