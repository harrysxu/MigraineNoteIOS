# 标签自定义功能实施指南

## 概述

本次更新为偏头痛记录App添加了完整的标签自定义功能，用户可以在设置中管理症状、诱因、药物三种类型的标签。

## 功能特性

### 支持的标签类型

- ✅ **症状标签**（西医症状 + 中医症状）
- ✅ **诱因标签**（7个分类：饮食、环境、睡眠、压力、激素、生活方式、中医诱因）
- ✅ **药物预设**（4个分类：NSAID、曲普坦类、预防性药物、中成药）
- ❌ **疼痛位置**（保持固定，不可自定义）

### 标签管理能力

1. **默认标签**
   - 可以隐藏（不在录入界面显示）
   - 不可删除
   - 不可重命名

2. **自定义标签**
   - 可以添加
   - 可以删除
   - 可以重命名
   - 可以隐藏/显示

3. **实时生效**
   - 标签配置修改后，录入界面立即更新
   - 无需重启应用

## 新增文件清单

### 数据模型
- `migraine_note/migraine_note/Models/CustomLabelConfig.swift` - 标签配置数据模型

### 服务层
- `migraine_note/migraine_note/Services/LabelManager.swift` - 标签管理服务

### 界面文件
- `migraine_note/migraine_note/Views/Settings/LabelManagement/LabelManagementView.swift` - 标签管理主界面
- `migraine_note/migraine_note/Views/Settings/LabelManagement/SymptomLabelEditor.swift` - 症状标签编辑器
- `migraine_note/migraine_note/Views/Settings/LabelManagement/TriggerLabelEditor.swift` - 诱因标签编辑器
- `migraine_note/migraine_note/Views/Settings/LabelManagement/MedicationPresetEditor.swift` - 药物预设编辑器
- `migraine_note/migraine_note/Views/Settings/LabelManagement/LabelRow.swift` - 标签行组件

## 修改文件清单

1. `migraine_note/migraine_note/migraine_noteApp.swift`
   - 添加 CustomLabelConfig 到 SwiftData Schema
   - 添加应用启动时初始化默认标签的逻辑

2. `migraine_note/migraine_note/Views/Settings/SettingsView.swift`
   - 添加"标签管理"入口

3. `migraine_note/migraine_note/ViewModels/RecordingViewModel.swift`
   - 将 `selectedSymptoms: Set<SymptomType>` 改为 `selectedSymptomNames: Set<String>`
   - 适配保存逻辑，支持自定义标签

4. `migraine_note/migraine_note/Views/Recording/Step3_SymptomsView.swift`
   - 从数据库查询症状标签
   - 使用 `@Query` 加载未隐藏的标签

5. `migraine_note/migraine_note/Views/Recording/Step4_TriggersView.swift`
   - 从数据库查询诱因标签
   - 使用 `@Query` 加载未隐藏的标签

6. `migraine_note/migraine_note/Views/Medication/AddMedicationView.swift`
   - 修改 `MedicationPresetsView`，从数据库加载药物预设

7. `migraine_note/migraine_note/Views/Recording/SimplifiedRecordingView.swift`
   - 适配症状和诱因部分，使用数据库标签

8. `migraine_note/migraine_note/Views/Home/HomeView.swift`
   - 适配 `SimplifiedRecordingViewWrapper` 中的症状和诱因部分

## 在 Xcode 中添加新文件

由于新文件是通过文件系统创建的，需要在 Xcode 中手动添加这些文件到项目：

### 步骤

1. **打开 Xcode 项目**
   - 打开 `migraine_note.xcodeproj`

2. **添加 Models 文件**
   - 在项目导航器中找到 `migraine_note/Models` 文件夹
   - 右键点击 → "Add Files to migraine_note..."
   - 选择 `CustomLabelConfig.swift`
   - 确保 "Copy items if needed" **未选中**
   - 确保 Target "migraine_note" **已选中**
   - 点击 "Add"

3. **添加 Services 文件**
   - 在 `migraine_note/Services` 文件夹中
   - 添加 `LabelManager.swift`

4. **添加 Views 文件**
   - 先在 `migraine_note/Views/Settings/` 下创建 `LabelManagement` 文件夹（如果 Xcode 中不存在）
   - 添加以下文件：
     - `LabelManagementView.swift`
     - `SymptomLabelEditor.swift`
     - `TriggerLabelEditor.swift`
     - `MedicationPresetEditor.swift`
     - `LabelRow.swift`

### 或者使用快捷方式

1. 在 Xcode 中，选择项目根目录
2. 菜单栏：File → Add Files to "migraine_note"
3. 按住 Command 键，多选所有新文件
4. 点击 "Add"

## 使用说明

### 用户操作流程

1. **进入标签管理**
   - 打开 App
   - 点击底部"设置"标签
   - 选择"标签管理"

2. **管理症状标签**
   - 点击"症状"标签
   - 查看"西医症状"和"中医症状"两个区块
   - 点击眼睛图标可隐藏/显示默认标签
   - 点击右下角"+"按钮添加自定义症状
   - 对于自定义症状，可以点击菜单进行重命名或删除

3. **管理诱因标签**
   - 点击"诱因"标签
   - 按分类查看诱因（可折叠展开）
   - 添加自定义诱因时需要选择所属分类

4. **管理药物预设**
   - 点击"药物预设"标签
   - 按药物类别查看预设
   - 添加常用药物到预设列表

5. **在录入时使用**
   - 进入记录流程
   - 在症状、诱因、用药步骤中，只会显示未隐藏的标签
   - 自定义标签和默认标签混合显示

## 数据存储

### SwiftData 模型

```swift
@Model
final class CustomLabelConfig {
    var id: UUID
    var category: String        // "symptom", "trigger", "medication"
    var labelKey: String        // 标签键值
    var displayName: String     // 显示名称
    var isDefault: Bool         // 是否为默认标签
    var isHidden: Bool          // 是否隐藏
    var sortOrder: Int          // 排序顺序
    var subcategory: String?    // 子分类
    var createdAt: Date
    var updatedAt: Date
    var metadata: String?       // JSON格式的额外信息
}
```

### 默认标签初始化

应用首次启动时，`LabelManager` 会自动将以下默认标签写入数据库：

**症状** (12个)
- 西医：恶心、呕吐、畏光、畏声、气味敏感、头皮触痛
- 中医：口苦、面红目赤、手脚冰凉、头重如裹、眩晕、心悸

**诱因** (49个)
- 饮食：10个
- 环境：9个
- 睡眠：4个
- 压力：5个
- 激素：4个
- 生活方式：5个
- 中医诱因：5个

**药物预设** (15个)
- NSAID：4个
- 曲普坦类：4个
- 预防性药物：4个
- 中成药：3个

## 技术实现要点

### 1. 响应式更新

使用 SwiftData 的 `@Query` 属性包装器，标签配置更改后自动刷新：

```swift
@Query(filter: #Predicate<CustomLabelConfig> { 
    $0.category == "symptom" && $0.isHidden == false 
}, sort: \CustomLabelConfig.sortOrder)
private var symptomLabels: [CustomLabelConfig]
```

### 2. 兼容性处理

保留原有的枚举类型（`SymptomType`、`TriggerCategory`、`MedicationCategory`），作为：
- 类型安全的保证
- 默认值的来源
- 向后兼容的基础

### 3. 数据迁移

- `RecordingViewModel` 改用字符串名称存储症状：`selectedSymptomNames: Set<String>`
- 保存时智能转换：如果能匹配枚举则创建枚举类型，否则作为自定义值
- 加载时直接使用名称，无需类型转换

## 测试检查清单

- [ ] 应用首次启动，默认标签成功初始化
- [ ] 进入设置 → 标签管理，可以看到三个标签类型
- [ ] 症状标签编辑器：
  - [ ] 显示西医症状和中医症状
  - [ ] 可以隐藏默认症状
  - [ ] 可以添加自定义症状
  - [ ] 可以重命名和删除自定义症状
- [ ] 诱因标签编辑器：
  - [ ] 显示7个分类
  - [ ] 可以折叠展开分类
  - [ ] 可以隐藏默认诱因
  - [ ] 添加自定义诱因时可选择分类
- [ ] 药物预设编辑器：
  - [ ] 显示4个药物分类
  - [ ] 可以隐藏默认药物
  - [ ] 可以添加自定义药物预设
- [ ] 录入流程验证：
  - [ ] Step3 症状选择只显示未隐藏的标签
  - [ ] Step4 诱因选择只显示未隐藏的标签
  - [ ] 添加药物时预设列表只显示未隐藏的药物
  - [ ] 可以正常保存包含自定义标签的记录
- [ ] 数据同步：
  - [ ] 在标签管理中隐藏标签后，录入页面立即更新
  - [ ] 添加标签后，录入页面立即显示新标签

## 注意事项

1. **首次启动**：应用首次启动时会自动初始化默认标签，这个过程是一次性的
2. **数据迁移**：现有的历史记录不受影响，因为它们存储的是字符串值
3. **性能优化**：使用 SwiftData 的 Query 和 Predicate，查询性能优秀
4. **CloudKit 同步**：CustomLabelConfig 会自动同步到 iCloud

## 后续优化建议

1. **拖拽排序**：实现标签的拖拽排序功能
2. **批量操作**：支持批量隐藏/显示标签
3. **导入导出**：支持导入导出标签配置
4. **标签统计**：显示每个标签的使用频率
5. **智能推荐**：根据使用频率推荐常用标签

## 架构图

```
┌─────────────────────────────────────────┐
│         用户界面层 (Views)                │
├─────────────────────────────────────────┤
│  设置 → 标签管理                          │
│    ├─ 症状标签编辑器                      │
│    ├─ 诱因标签编辑器                      │
│    └─ 药物预设编辑器                      │
│                                         │
│  记录流程                                │
│    ├─ Step3: 症状选择 (从DB加载)         │
│    ├─ Step4: 诱因选择 (从DB加载)         │
│    └─ 添加药物: 预设列表 (从DB加载)       │
└─────────────────────────────────────────┘
                   ↕
┌─────────────────────────────────────────┐
│      业务逻辑层 (LabelManager)            │
├─────────────────────────────────────────┤
│  • initializeDefaultLabels()            │
│  • fetchLabels()                        │
│  • addCustomLabel()                     │
│  • toggleLabelVisibility()              │
│  • deleteCustomLabel()                  │
│  • renameLabel()                        │
└─────────────────────────────────────────┘
                   ↕
┌─────────────────────────────────────────┐
│       数据持久层 (SwiftData)              │
├─────────────────────────────────────────┤
│  CustomLabelConfig                      │
│    - 标签配置（支持增删改查）              │
│    - iCloud 自动同步                     │
└─────────────────────────────────────────┘
```

## 数据流示例

### 添加自定义症状标签

```
用户操作: 设置 → 标签管理 → 症状 → 点击"+" → 输入"头晕脑胀"

1. SymptomLabelEditor 调用 LabelManager.addCustomLabel()
2. LabelManager 创建 CustomLabelConfig 实例
   - category: "symptom"
   - labelKey: "头晕脑胀"
   - displayName: "头晕脑胀"
   - isDefault: false
   - subcategory: "western"
3. 插入到 SwiftData modelContext
4. 自动同步到 iCloud
5. Step3_SymptomsView 的 @Query 自动刷新
6. 新标签立即出现在录入界面
```

### 隐藏默认症状标签

```
用户操作: 标签管理 → 症状 → 点击"恶心"的眼睛图标

1. LabelRow 调用 LabelManager.toggleLabelVisibility()
2. LabelManager 更新 label.isHidden = true
3. 保存到数据库
4. Step3_SymptomsView 的 @Query 过滤条件排除 isHidden=true
5. "恶心"标签从录入界面消失
```

## 开发指南

### 添加新的标签类型

如果将来需要添加新的标签类型（如"疼痛性质"），按以下步骤操作：

1. **扩展 LabelCategory 枚举**

```swift
enum LabelCategory: String, CaseIterable {
    case symptom = "symptom"
    case trigger = "trigger"
    case medication = "medication"
    case painQuality = "painQuality"  // 新增
}
```

2. **在 LabelManager 中添加初始化方法**

```swift
private func initializePainQualityLabels(context: ModelContext) {
    let qualities = ["搏动性", "胀痛", "刺痛", ...]
    // 创建 CustomLabelConfig 并插入
}
```

3. **创建编辑器视图**

创建 `PainQualityLabelEditor.swift`

4. **在 LabelManagementView 中添加 Tab**

5. **修改录入页面**

在 `Step2_PainAssessmentView` 中使用 `@Query` 加载标签

## 故障排除

### 问题：应用启动后看不到默认标签

**原因**：默认标签初始化失败

**解决**：
1. 检查控制台日志，查看是否有错误信息
2. 确认 `CustomLabelConfig` 已添加到 SwiftData Schema
3. 尝试删除应用重新安装

### 问题：修改标签后录入界面没有更新

**原因**：SwiftData 查询未刷新

**解决**：
1. 确认使用了 `@Query` 而非静态数据
2. 检查 Predicate 是否正确
3. 确认 modelContext 正确传递

### 问题：新文件在 Xcode 中显示红色

**原因**：文件未添加到项目

**解决**：
按照上面"在 Xcode 中添加新文件"的步骤操作

## 版本历史

- **v1.1.0** (2026-02-02)
  - 新增标签自定义功能
  - 支持症状、诱因、药物三类标签的管理
  - 支持隐藏/显示、添加、删除、重命名操作
  - 录入流程完全适配自定义标签
