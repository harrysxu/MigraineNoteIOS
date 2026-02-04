# 添加新文件到 Xcode 项目

## 需要添加的文件

以下三个新创建的文件需要添加到 Xcode 项目中：

1. `PainQualityLabelEditor.swift`
2. `InterventionLabelEditor.swift`
3. `AddLabelSheet.swift`

文件位置：`migraine_note/migraine_note/Views/Settings/LabelManagement/`

## 操作步骤

### 方法一：在 Xcode 中手动添加

1. **打开项目**
   - 打开 Xcode
   - 打开 `migraine_note.xcodeproj`

2. **导航到目标文件夹**
   - 在左侧项目导航器中找到：
   - `migraine_note` → `Views` → `Settings` → `LabelManagement`

3. **添加文件**
   - 右键点击 `LabelManagement` 文件夹
   - 选择 "Add Files to migraine_note..."
   - 浏览到：`migraine_note/Views/Settings/LabelManagement/`
   - 选中以下三个文件：
     - `PainQualityLabelEditor.swift`
     - `InterventionLabelEditor.swift`
     - `AddLabelSheet.swift`
   - 确保勾选：
     - ✅ "Copy items if needed"（如果需要）
     - ✅ "Create groups"
     - ✅ Target: migraine_note
   - 点击 "Add"

4. **验证**
   - 确认文件出现在项目导航器中
   - 文件应该在 `LabelManagement` 组下

### 方法二：使用拖放

1. **打开 Finder 和 Xcode**
   - 在 Finder 中打开：`migraine_note/migraine_note/Views/Settings/LabelManagement/`
   - 在 Xcode 中打开项目

2. **拖放文件**
   - 选中三个新文件：
     - `PainQualityLabelEditor.swift`
     - `InterventionLabelEditor.swift`
     - `AddLabelSheet.swift`
   - 拖动到 Xcode 的 `LabelManagement` 文件夹中

3. **确认选项**
   - 在弹出的对话框中确保：
     - ✅ "Copy items if needed"
     - ✅ "Create groups"
     - ✅ Target: migraine_note
   - 点击 "Finish"

## 构建验证

添加文件后，进行构建测试：

1. 选择模拟器或设备
2. 按 `Cmd + B` 构建项目
3. 确保没有编译错误

## 可能的问题

### 问题 1：找不到文件

**解决方案：**
- 确认文件确实存在于文件系统中
- 路径：`migraine_note/migraine_note/Views/Settings/LabelManagement/`

### 问题 2：编译错误 - 找不到类型

**解决方案：**
- 确保所有三个文件都已添加到项目
- 清理构建（Product → Clean Build Folder）
- 重新构建

### 问题 3：文件显示为红色

**解决方案：**
- 右键点击文件 → "Show in Finder"
- 如果文件不在预期位置，重新添加文件

## 文件说明

### PainQualityLabelEditor.swift
疼痛性质标签编辑器，用于在标签管理页面中管理疼痛性质标签。

### InterventionLabelEditor.swift
非药物干预标签编辑器，用于在标签管理页面中管理非药物干预标签。

### AddLabelSheet.swift
通用的添加标签表单组件，被所有标签编辑器使用。

## 完成后的效果

添加文件并构建成功后，应用将具备以下功能：

1. ✅ 疼痛性质支持自定义选项
2. ✅ 非药物干预支持自定义选项
3. ✅ 标签管理页面显示疼痛性质和非药物干预标签
4. ✅ 自定义标签自动同步到标签管理
5. ✅ 支持标签的显示/隐藏、重命名、删除、排序

## 下一步

添加文件后，请参考 [自定义标签功能实施说明.md](./自定义标签功能实施说明.md) 了解功能详情和使用说明。
