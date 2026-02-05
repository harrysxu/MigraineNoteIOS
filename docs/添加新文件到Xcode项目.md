# 将新文件添加到 Xcode 项目

## 需要添加的新文件

由于我们创建了一些新的 Swift 文件，需要将它们添加到 Xcode 项目中才能编译。

### 文件列表

#### Models（数据模型文件夹）
1. `migraine_note/migraine_note/Models/HealthEvent.swift`
2. `migraine_note/migraine_note/Models/TimelineItem.swift`

#### Views/HealthEvent（新建文件夹）
3. `migraine_note/migraine_note/Views/HealthEvent/AddHealthEventView.swift`
4. `migraine_note/migraine_note/Views/HealthEvent/HealthEventDetailView.swift`

#### Utils（工具文件夹）
5. `migraine_note/migraine_note/Utils/HealthEventTestData.swift`

## 添加步骤

### 方法一：在 Xcode 中手动添加（推荐）

1. **打开 Xcode 项目**
   - 打开 `migraine_note.xcodeproj`

2. **添加 Models 文件**
   - 右键点击左侧导航栏中的 `Models` 文件夹
   - 选择 "Add Files to migraine_note..."
   - 导航到 `migraine_note/Models/` 目录
   - 按住 Command 键，选择：
     - `HealthEvent.swift`
     - `TimelineItem.swift`
   - 确保勾选 "Copy items if needed"（如果需要）
   - 确保勾选 "migraine_note" target
   - 点击 "Add"

3. **创建 HealthEvent 文件夹并添加视图文件**
   - 右键点击左侧导航栏中的 `Views` 文件夹
   - 选择 "New Group"
   - 命名为 "HealthEvent"
   - 右键点击新创建的 `HealthEvent` 文件夹
   - 选择 "Add Files to migraine_note..."
   - 导航到 `migraine_note/Views/HealthEvent/` 目录
   - 按住 Command 键，选择：
     - `AddHealthEventView.swift`
     - `HealthEventDetailView.swift`
   - 确保勾选 "Copy items if needed"（如果需要）
   - 确保勾选 "migraine_note" target
   - 点击 "Add"

4. **添加 Utils 文件**
   - 右键点击左侧导航栏中的 `Utils` 文件夹
   - 选择 "Add Files to migraine_note..."
   - 导航到 `migraine_note/Utils/` 目录
   - 选择 `HealthEventTestData.swift`
   - 确保勾选 "Copy items if needed"（如果需要）
   - 确保勾选 "migraine_note" target
   - 点击 "Add"

5. **验证添加成功**
   - 在左侧导航栏中确认所有文件都显示出来了
   - 文件名应该是黑色的（不是红色或灰色）
   - 尝试编译项目（Command + B）

### 方法二：使用命令行（高级用户）

如果您熟悉 Ruby 和 xcodeproj gem，可以使用脚本自动添加文件。

```ruby
require 'xcodeproj'

project_path = 'migraine_note/migraine_note.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# 添加文件到对应的组...
# （这里需要编写具体的脚本）

project.save
```

## 清除数据

⚠️ **重要**：由于添加了新的数据模型，需要清除现有数据。

### 在模拟器中
1. 长按应用图标
2. 选择"删除 App"
3. 重新运行项目

### 在真机上
1. 进入"设置" > "通用" > "iPhone 储存空间"
2. 找到"migraine_note"应用
3. 点击"删除 App"
4. 重新安装应用

## 编译和运行

1. 清理构建文件夹：`Product` > `Clean Build Folder`（Shift + Command + K）
2. 重新编译：`Product` > `Build`（Command + B）
3. 运行应用：`Product` > `Run`（Command + R）

## 可能的问题

### 编译错误："Cannot find type 'HealthEvent' in scope"
- **原因**：文件未添加到 Xcode 项目
- **解决**：按照上述步骤将文件添加到项目

### 运行时错误："无法创建 ModelContainer"
- **原因**：数据模型变更，旧数据不兼容
- **解决**：删除应用重新安装

### 文件显示为红色
- **原因**：文件路径不正确
- **解决**：右键点击文件 > "Show in Finder"，确认文件位置正确

## 测试数据生成

如果需要快速生成测试数据进行测试，可以在代码中临时添加：

```swift
// 在某个视图的 onAppear 中
.onAppear {
    HealthEventTestData.generateTestEvents(in: modelContext)
}
```

**注意**：测试完成后记得移除这段代码。
