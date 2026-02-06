//
//  EnumTests.swift
//  migraine_noteTests
//
//  小型枚举和模型的集合测试
//

import XCTest
import SwiftData
@testable import migraine_note

final class EnumTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        modelContext = try! makeTestModelContext()
    }
    
    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - SymptomType 测试
    
    func testSymptomType_AllCases() {
        XCTAssertEqual(SymptomType.allCases.count, 12, "应有12种症状类型")
    }
    
    func testSymptomType_WesternMedicine() {
        let westernTypes: [SymptomType] = [.nausea, .vomiting, .photophobia, .phonophobia, .osmophobia, .allodynia]
        
        for type in westernTypes {
            XCTAssertTrue(type.isWesternMedicine, "\(type) 应为西医症状")
            XCTAssertFalse(type.isTCM)
        }
    }
    
    func testSymptomType_TCM() {
        let tcmTypes: [SymptomType] = [.bitterTaste, .facialFlushing, .coldExtremities, .heavyHeadedness, .dizziness, .palpitation]
        
        for type in tcmTypes {
            XCTAssertTrue(type.isTCM, "\(type) 应为中医症状")
            XCTAssertFalse(type.isWesternMedicine)
        }
    }
    
    // MARK: - Symptom Model 测试
    
    func testSymptom_Name() {
        let symptom = Symptom(type: .nausea, severity: 5)
        
        XCTAssertEqual(symptom.name, "恶心")
        XCTAssertEqual(symptom.severity, 5)
    }
    
    func testSymptom_Category() {
        let westernSymptom = Symptom(type: .photophobia)
        XCTAssertEqual(westernSymptom.category, .ihs)
        
        let tcmSymptom = Symptom(type: .bitterTaste)
        XCTAssertEqual(tcmSymptom.category, .tcm)
    }
    
    func testSymptom_TypeConversion() {
        let symptom = Symptom(type: .nausea)
        XCTAssertEqual(symptom.type, .nausea)
        
        symptom.type = .vomiting
        XCTAssertEqual(symptom.typeRawValue, "呕吐")
    }
    
    // MARK: - TriggerCategory 测试
    
    func testTriggerCategory_AllCases() {
        XCTAssertEqual(TriggerCategory.allCases.count, 7)
    }
    
    func testTriggerCategory_SystemImages() {
        for category in TriggerCategory.allCases {
            XCTAssertFalse(category.systemImage.isEmpty, "\(category) 应有系统图标")
        }
    }
    
    // MARK: - Trigger Model 测试
    
    func testTrigger_Init() {
        let trigger = Trigger(category: .food, specificType: "巧克力")
        
        XCTAssertEqual(trigger.category, .food)
        XCTAssertEqual(trigger.specificType, "巧克力")
        XCTAssertEqual(trigger.name, "巧克力") // 兼容属性
    }
    
    func testTrigger_CategoryConversion() {
        let trigger = Trigger(category: .sleep, specificType: "失眠")
        
        XCTAssertEqual(trigger.categoryRawValue, "睡眠")
        
        trigger.category = .stress
        XCTAssertEqual(trigger.categoryRawValue, "压力")
    }
    
    // MARK: - TriggerLibrary 测试
    
    func testTriggerLibrary_TriggersForCategory() {
        for category in TriggerCategory.allCases {
            let triggers = TriggerLibrary.triggers(for: category)
            XCTAssertFalse(triggers.isEmpty, "\(category) 应有预设诱因")
        }
    }
    
    func testTriggerLibrary_FoodTriggers() {
        let triggers = TriggerLibrary.triggers(for: .food)
        XCTAssertTrue(triggers.contains("巧克力"))
        XCTAssertTrue(triggers.contains("红酒"))
        XCTAssertTrue(triggers.contains("咖啡因"))
    }
    
    func testTriggerLibrary_AllTriggers() {
        let allTriggers = TriggerLibrary.allTriggers
        
        XCTAssertFalse(allTriggers.isEmpty)
        XCTAssertEqual(allTriggers["巧克力"], .food)
        XCTAssertEqual(allTriggers["睡眠不足"], .sleep)
        XCTAssertEqual(allTriggers["工作压力"], .stress)
    }
    
    // MARK: - TimelineItemType 测试
    
    func testTimelineItemType_Attack() {
        let attack = AttackRecord(startTime: makeDate(year: 2026, month: 1, day: 15))
        modelContext.insert(attack)
        
        let item = TimelineItemType.attack(attack)
        
        XCTAssertEqual(item.id, attack.id)
        XCTAssertEqual(item.eventDate, attack.startTime)
        XCTAssertEqual(item.year, 2026)
    }
    
    func testTimelineItemType_HealthEvent() {
        let date = makeDate(year: 2025, month: 12, day: 25)
        let event = HealthEvent(eventType: .medication, eventDate: date)
        modelContext.insert(event)
        
        let item = TimelineItemType.healthEvent(event)
        
        XCTAssertEqual(item.id, event.id)
        XCTAssertEqual(item.eventDate, date)
        XCTAssertEqual(item.year, 2025)
    }
    
    func testTimelineItemType_Equality() {
        let attack = AttackRecord()
        modelContext.insert(attack)
        
        let item1 = TimelineItemType.attack(attack)
        let item2 = TimelineItemType.attack(attack)
        
        XCTAssertEqual(item1, item2)
    }
    
    func testTimelineItemType_Hashable() {
        let attack = AttackRecord()
        modelContext.insert(attack)
        let event = HealthEvent(eventType: .medication)
        modelContext.insert(event)
        
        let set: Set<TimelineItemType> = [.attack(attack), .healthEvent(event)]
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - LabelCategory 测试
    
    func testLabelCategory_AllCases() {
        XCTAssertEqual(LabelCategory.allCases.count, 5)
    }
    
    func testLabelCategory_DisplayNames() {
        XCTAssertEqual(LabelCategory.symptom.displayName, "症状")
        XCTAssertEqual(LabelCategory.trigger.displayName, "诱因")
        XCTAssertEqual(LabelCategory.painQuality.displayName, "疼痛性质")
        XCTAssertEqual(LabelCategory.intervention.displayName, "非药物干预")
        XCTAssertEqual(LabelCategory.aura.displayName, "先兆类型")
    }
    
    func testLabelCategory_Icons() {
        for category in LabelCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) 应有图标")
        }
    }
    
    // MARK: - SymptomSubcategory 测试
    
    func testSymptomSubcategory_DisplayNames() {
        XCTAssertEqual(SymptomSubcategory.western.displayName, "西医症状")
        XCTAssertEqual(SymptomSubcategory.tcm.displayName, "中医症状")
    }
    
    // MARK: - CustomLabelConfig 测试
    
    func testCustomLabelConfig_Init() {
        let label = CustomLabelConfig(
            category: "symptom",
            labelKey: "test_key",
            displayName: "测试标签",
            isDefault: false,
            subcategory: "western",
            sortOrder: 5
        )
        
        XCTAssertEqual(label.category, "symptom")
        XCTAssertEqual(label.labelKey, "test_key")
        XCTAssertEqual(label.displayName, "测试标签")
        XCTAssertFalse(label.isDefault)
        XCTAssertEqual(label.subcategory, "western")
        XCTAssertEqual(label.sortOrder, 5)
        XCTAssertFalse(label.isHidden)
    }
    
    // MARK: - PainQuality 枚举测试
    
    func testPainQuality_AllCases() {
        XCTAssertEqual(PainQuality.allCases.count, 5)
    }
    
    func testPainQuality_RawValues() {
        XCTAssertEqual(PainQuality.pulsating.rawValue, "搏动性")
        XCTAssertEqual(PainQuality.pressing.rawValue, "压迫感")
        XCTAssertEqual(PainQuality.stabbing.rawValue, "刺痛")
        XCTAssertEqual(PainQuality.dull.rawValue, "钝痛")
        XCTAssertEqual(PainQuality.distending.rawValue, "胀痛")
    }
    
    // MARK: - AuraType 枚举测试
    
    func testAuraType_AllCases() {
        XCTAssertEqual(AuraType.allCases.count, 4)
    }
    
    // MARK: - NonPharmIntervention 枚举测试
    
    func testNonPharmIntervention_AllCases() {
        XCTAssertEqual(NonPharmIntervention.allCases.count, 10)
    }
    
    // MARK: - TCMPattern 枚举测试
    
    func testTCMPattern_AllCases() {
        XCTAssertEqual(TCMPattern.allCases.count, 6)
    }
    
    // MARK: - Gender / PainScale 测试
    
    func testGender_AllCases() {
        XCTAssertEqual(Gender.allCases.count, 3)
    }
    
    func testPainScale_AllCases() {
        XCTAssertEqual(PainScale.allCases.count, 2)
    }
    
    func testUserProfile_GenderConversion() {
        let profile = UserProfile()
        
        XCTAssertNil(profile.gender)
        
        profile.gender = .female
        XCTAssertEqual(profile.genderRawValue, "女")
        XCTAssertEqual(profile.gender, .female)
        
        profile.gender = nil
        XCTAssertNil(profile.genderRawValue)
    }
    
    func testUserProfile_PainScaleConversion() {
        let profile = UserProfile()
        
        XCTAssertEqual(profile.preferredPainScale, .numeric)
        
        profile.preferredPainScale = .visual
        XCTAssertEqual(profile.preferredPainScaleRawValue, "视觉模拟(VAS)")
    }
    
    // MARK: - RecordingStep 测试
    
    func testRecordingStep_AllCases() {
        XCTAssertEqual(RecordingStep.allCases.count, 5)
    }
    
    func testRecordingStep_Next() {
        XCTAssertEqual(RecordingStep.timeAndDuration.next(), .painAssessment)
        XCTAssertEqual(RecordingStep.painAssessment.next(), .symptoms)
        XCTAssertEqual(RecordingStep.symptoms.next(), .triggers)
        XCTAssertEqual(RecordingStep.triggers.next(), .interventions)
        XCTAssertEqual(RecordingStep.interventions.next(), .interventions) // 最后一步不变
    }
    
    func testRecordingStep_Previous() {
        XCTAssertEqual(RecordingStep.timeAndDuration.previous(), .timeAndDuration) // 第一步不变
        XCTAssertEqual(RecordingStep.painAssessment.previous(), .timeAndDuration)
        XCTAssertEqual(RecordingStep.symptoms.previous(), .painAssessment)
        XCTAssertEqual(RecordingStep.triggers.previous(), .symptoms)
        XCTAssertEqual(RecordingStep.interventions.previous(), .triggers)
    }
    
    func testRecordingStep_Titles() {
        for step in RecordingStep.allCases {
            XCTAssertFalse(step.title.isEmpty)
            XCTAssertFalse(step.stepNumber.isEmpty)
        }
    }
}
