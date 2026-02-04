# 自定义标签按钮修复总结

## 问题描述

用户反馈在 SimplifiedRecordingView（简化记录视图）中，以下三个部分缺少"自定义"按钮：

1. ❌ **疼痛性质** - 没有自定义按钮
2. ❌ **先兆类型** - 没有自定义按钮
3. ❌ **中医症状** - 没有自定义按钮

而伴随症状有"自定义"按钮 ✓

## 根本原因

1. **疼痛性质** - 使用硬编码的 `PainQuality.allCases` 枚举，没有使用数据库查询，也没有 `AddCustomLabelChip` 组件
2. **先兆类型** - 使用硬编码的 `AuraType.allCases` 枚举，并且先兆类型没有纳入自定义标签系统
3. **中医症状** - 虽然使用了数据库查询，但缺少 `AddCustomLabelChip` 组件

## 解决方案

### 1. 模型层修改

#### CustomLabelConfig.swift
- 在 `LabelCategory` 枚举中添加 `.aura` 类别
- 添加先兆类型的显示名称和图标

```swift
enum LabelCategory: String, CaseIterable {
    case symptom = "symptom"
    case trigger = "trigger"
    case painQuality = "painQuality"
    case intervention = "intervention"
    case aura = "aura"  // 新增
}
```

### 2. 服务层修改

#### LabelManager.swift
- 添加 `initializeAuraLabels()` 方法初始化默认先兆标签
- 在 `initializeDefaultLabelsIfNeeded()` 中调用先兆初始化

默认先兆类型：
- 视觉闪光
- 视野暗点
- 肢体麻木
- 言语障碍

### 3. ViewModel 修改

#### RecordingViewModel.swift
- 将 `selectedAuraTypes: Set<AuraType>` 改为 `selectedAuraTypeNames: Set<String>`
- 更新加载和保存先兆数据的逻辑，支持字符串形式的先兆类型

### 4. 视图层修改

#### SimplifiedRecordingView.swift
添加查询：
```swift
@Query(filter: #Predicate<CustomLabelConfig> { 
    $0.category == "painQuality" && $0.isHidden == false 
}, sort: \CustomLabelConfig.sortOrder)
private var painQualityLabels: [CustomLabelConfig]

@Query(filter: #Predicate<CustomLabelConfig> { 
    $0.category == "aura" && $0.isHidden == false 
}, sort: \CustomLabelConfig.sortOrder)
private var auraLabels: [CustomLabelConfig]
```

修改三个部分：

1. **疼痛性质** - 使用 `painQualityLabels` 查询，添加 `AddCustomLabelChip`
2. **先兆类型** - 使用 `auraLabels` 查询，添加 `AddCustomLabelChip`
3. **中医症状** - 添加 `AddCustomLabelChip`

#### Step3_SymptomsView.swift
- 添加 `auraLabels` 查询
- 更新先兆类型选择使用数据库标签
- 添加 `AddCustomLabelChip`

#### HomeView.swift
- 添加 `auraLabels` 和 `painQualityLabels` 查询
- 更新先兆类型选择使用数据库标签，添加 `AddCustomLabelChip`
- 更新疼痛性质选择使用数据库标签，添加 `AddCustomLabelChip`

### 5. 组件修改

#### AddCustomLabelChip.swift
- 在 `categoryDisplayName` 方法中添加对 `.aura` 类别的支持

## 修改文件清单

1. ✅ `Models/CustomLabelConfig.swift` - 添加 aura 类别
2. ✅ `Services/LabelManager.swift` - 添加先兆标签初始化
3. ✅ `ViewModels/RecordingViewModel.swift` - 支持字符串形式的先兆
4. ✅ `Views/Recording/SimplifiedRecordingView.swift` - 添加三个自定义按钮
5. ✅ `Views/Recording/Step3_SymptomsView.swift` - 更新先兆部分
6. ✅ `Views/Home/HomeView.swift` - 更新先兆部分
7. ✅ `DesignSystem/Components/AddCustomLabelChip.swift` - 支持 aura 类别

## 测试要点

### 1. SimplifiedRecordingView（简化记录视图）

测试疼痛性质：
- [ ] 能看到默认的疼痛性质选项（搏动性、压迫感、刺痛、钝痛、胀痛）
- [ ] 能看到"自定义"按钮（虚线圈）
- [ ] 点击"自定义"能弹出添加界面
- [ ] 添加自定义疼痛性质后立即显示
- [ ] 自定义疼痛性质可以被选中

测试先兆类型：
- [ ] 打开"是否有先兆"开关
- [ ] 能看到默认的先兆类型选项（视觉闪光、视野暗点、肢体麻木、言语障碍）
- [ ] 能看到"自定义"按钮
- [ ] 点击"自定义"能弹出添加界面
- [ ] 添加自定义先兆类型后立即显示
- [ ] 自定义先兆类型可以被选中

测试中医症状：
- [ ] 能看到默认的中医症状选项
- [ ] 能看到"自定义"按钮
- [ ] 点击"自定义"能弹出添加界面
- [ ] 添加自定义中医症状后立即显示

### 2. Step3_SymptomsView（分步记录视图）

- [ ] 先兆类型部分有"自定义"按钮
- [ ] 功能与 SimplifiedRecordingView 一致

### 3. HomeView（快速记录）

- [ ] 先兆类型部分有"自定义"按钮
- [ ] 功能与 SimplifiedRecordingView 一致

### 4. 标签管理

前往"我的" -> "标签管理"：
- [ ] 能看到"疼痛性质"分类
- [ ] 能看到"先兆类型"分类
- [ ] 能看到刚才添加的自定义标签
- [ ] 可以编辑、隐藏、删除自定义标签

### 5. 数据持久化

- [ ] 添加自定义标签后关闭应用
- [ ] 重新打开应用
- [ ] 自定义标签仍然存在

## 技术亮点

1. **统一的自定义体验** - 所有记录模块都使用统一的自定义标签系统
2. **数据库驱动** - 使用 SwiftData 存储和查询标签，支持 CloudKit 同步
3. **即时反馈** - 添加自定义标签后立即在界面上显示
4. **灵活扩展** - 支持为任何分类添加自定义标签

## 用户价值

✨ **完整的自定义能力**
- 用户可以根据个人情况自定义所有类型的标签
- 不再局限于预设选项

✨ **一致的交互体验**
- 所有模块都有统一的"自定义"按钮
- 操作流程一致，容易学习

✨ **数据永久保存**
- 自定义标签自动保存到数据库
- 支持 iCloud 同步到其他设备

## 后续优化建议

1. **标签排序** - 允许用户自定义标签的显示顺序
2. **标签颜色** - 允许用户为标签设置不同颜色
3. **标签图标** - 为自定义标签添加图标选择
4. **标签导入导出** - 支持在设备间分享标签配置
