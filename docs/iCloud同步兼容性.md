# 国际化 iCloud 同步兼容性说明

> ⚠️ **更新通知（2026-02-24）**：本文档部分内容已过时。我们已采用简化的国际化方案，不再支持动态语言切换。详见 [国际化简化说明.md](./国际化简化说明.md)

## 📋 问题总结

### 问题1: 枚举 rawValue 变更 ✅ 已解决
**状态**：无问题（因为没有旧数据）

- **变更**：所有枚举 rawValue 从中文改为英文
- **影响**：存储在 SwiftData 中的 rawValue 会变化
- **解决**：由于没有用户数据，所有设备都使用新的英文 rawValue

### 问题2: 默认标签同步冲突 ✅ 已解决
**状态**：已添加 `localizedDisplayName` 计算属性

- **问题**：不同语言设备创建的默认标签 displayName 不同
- **影响**：iCloud 同步后可能显示错误语言
- **解决**：添加 `localizedDisplayName` 动态获取本地化名称

## 🔧 实施的解决方案

### 1. CustomLabelConfig 增强

```swift
@Model
final class CustomLabelConfig {
    var displayName: String = ""  // 存储的原始值（可能是任何语言）
    var isDefault: Bool = false
    var labelKey: String = ""
    
    // ✅ 新增：动态本地化属性
    var localizedDisplayName: String {
        if isDefault && !labelKey.isEmpty {
            // 默认标签：根据当前语言获取翻译
            let locKey = "label.\(category).\(labelKey)"
            return String(localized: String.LocalizationValue(locKey))
        } else {
            // 自定义标签：返回用户输入的原始值
            return displayName
        }
    }
}
```

### 2. 工作流程

#### 默认标签的生命周期

```
创建阶段（首次启动）：
设备 A（中文）: displayName = "恶心" (labelKey = "nausea")
设备 B（英文）: displayName = "Nausea" (labelKey = "nausea")

iCloud 同步：
两个设备互相看到对方的标签

去重执行：
LabelManager.deduplicateLabels() 按 (category, labelKey, subcategory) 去重
保留 createdAt 最早的记录（例如设备 A 的）

最终状态：
两个设备都有：{labelKey: "nausea", displayName: "恶心"}

显示阶段：
设备 A（中文）: localizedDisplayName → "恶心" ✅
设备 B（英文）: localizedDisplayName → "Nausea" ✅
```

#### 自定义标签的生命周期

```
创建阶段：
设备 A: 用户输入"我的特殊诱因"
存储：{labelKey: "我的特殊诱因", displayName: "我的特殊诱因", isDefault: false}

iCloud 同步：
设备 B 收到该标签

显示阶段：
设备 A: localizedDisplayName → "我的特殊诱因" ✅
设备 B: localizedDisplayName → "我的特殊诱因" ✅
（不会被翻译，保持原样）
```

## 📊 数据兼容性矩阵

| 场景 | 存储的数据 | 设备A显示（中文） | 设备B显示（英文） | 同步状态 |
|------|-----------|----------------|----------------|---------|
| 默认标签（中文创建） | displayName="恶心" | "恶心" | "Nausea" | ✅ 兼容 |
| 默认标签（英文创建） | displayName="Nausea" | "恶心" | "Nausea" | ✅ 兼容 |
| 自定义标签 | displayName="我的诱因" | "我的诱因" | "我的诱因" | ✅ 兼容 |
| 枚举 rawValue | "nsaid" | （通过localizedName显示） | （通过localizedName显示） | ✅ 兼容 |

## 🎯 关键设计原则

### 1. 分离存储与显示
- **存储层**：displayName 可以是任何语言（历史遗留）
- **显示层**：localizedDisplayName 动态获取当前语言

### 2. labelKey 是真理之源
- labelKey 必须是英文
- labelKey 用于去重判断
- labelKey 用于获取本地化翻译

### 3. 向前兼容
- 即使 displayName 存储了错误语言，也能正确显示
- 未来添加新语言只需更新 Localizable.xcstrings
- 不需要迁移已有数据

## 🚨 重要注意事项

### 1. 视图代码更新要求

**所有使用标签的地方必须使用 `localizedDisplayName`：**

```swift
// ❌ 错误（可能显示错误语言）
Text(label.displayName)

// ✅ 正确（始终显示当前语言）
Text(label.localizedDisplayName)

// ❌ 错误
ForEach(labels) { label in
    Text(label.displayName)
}

// ✅ 正确
ForEach(labels) { label in
    Text(label.localizedDisplayName)
}
```

### 2. 需要更新的文件列表

根据搜索结果，以下文件**可能**需要更新（需要逐个检查）：

**视图文件（高优先级）：**
- `Views/Settings/LabelManagement/LabelRow.swift` - 标签行显示
- `Views/Settings/LabelManagement/LabelManagementView.swift` - 标签管理
- `Views/Settings/LabelManagement/MedicationPresetEditor.swift` - 药物预设编辑器
- `Views/Recording/SimplifiedRecordingView.swift` - 记录视图
- `Views/Medication/AddMedicationView.swift` - 添加药物
- `Views/AttackList/AttackDetailView.swift` - 发作详情
- `Views/HealthEvent/HealthEventDetailView.swift` - 健康事件详情
- `Views/Home/HomeView.swift` - 首页

**服务文件（中优先级）：**
- `Services/AnalyticsEngine.swift` - 分析引擎
- `Utils/CSVExporter.swift` - CSV 导出
- `Services/MedicalReportGenerator.swift` - 医疗报告生成

**测试文件（低优先级）：**
- 测试文件中的 displayName 通常用于断言，可能需要更新

### 3. LabelManager 不需要修改

`LabelManager.swift` 中的 displayName 赋值是**正确的**：
- 它在初始化时设置 displayName
- 这个值会被存储到数据库
- 显示时会通过 `localizedDisplayName` 动态获取翻译

## ✅ 测试清单

### 单设备测试
- [ ] 中文系统下创建记录，使用默认标签
- [ ] 切换到英文系统，验证标签显示为英文
- [ ] 切换到繁体中文，验证标签显示为繁体
- [ ] 创建自定义标签，切换语言验证保持原样

### 多设备同步测试
- [ ] 设备 A（中文）首次启动，创建记录
- [ ] 设备 B（英文）首次启动，创建记录
- [ ] 等待 iCloud 同步完成
- [ ] 验证两个设备都能正确显示标签（各自语言）
- [ ] 在设备 A 创建自定义标签
- [ ] 验证设备 B 能看到该自定义标签（原始文本）

### 边界情况测试
- [ ] 网络断开时创建标签
- [ ] 快速切换语言
- [ ] 同时在两个设备创建相同的自定义标签
- [ ] 删除默认标签后重新初始化

## 📝 下一步行动

### 必须完成
1. ✅ 添加 `localizedDisplayName` 属性到 CustomLabelConfig
2. ⏳ 更新所有视图文件使用 `localizedDisplayName`
3. ⏳ 运行编译检查
4. ⏳ 执行测试清单

### 可选改进
- 添加性能监控（如果 localizedDisplayName 调用过于频繁）
- 考虑缓存机制（如果有性能问题）
- 添加日志记录标签同步事件

## 🎓 经验教训

1. **始终考虑多设备同步场景**
   - 单设备测试可能无法发现同步问题
   - 不同语言设备的组合会产生意外情况

2. **分离存储与显示逻辑**
   - displayName 是存储值（历史遗留，可能不准确）
   - localizedDisplayName 是显示值（动态计算，始终正确）

3. **labelKey 是关键**
   - 必须使用稳定的英文标识符
   - 所有业务逻辑基于 labelKey 而不是 displayName

4. **国际化不只是翻译**
   - 需要考虑数据模型
   - 需要考虑同步策略
   - 需要考虑向前兼容

## 📚 相关文档

- [国际化实施总结.md](./国际化实施总结.md) - 整体实施报告
- [国际化快速参考.md](./国际化快速参考.md) - 开发者指南
- [标签同步说明.md](./标签同步说明.md) - 详细的同步机制说明

---

**最后更新**：2026-02-24  
**状态**：✅ CustomLabelConfig 已更新，待更新视图文件
