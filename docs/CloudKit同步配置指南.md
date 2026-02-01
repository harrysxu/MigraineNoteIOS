# CloudKit 同步配置指南

## 📋 概述

本文档指导如何配置偏头痛记录App的iCloud + CloudKit同步功能，实现多设备无缝数据同步。

## 🎯 设计目标

- **零配置同步**：SwiftData + CloudKit自动同步，无需手动代码
- **私有数据库**：所有数据存储在用户的iCloud私有数据库中
- **隐私至上**：数据完全归属用户，开发者无法访问
- **冲突解决**：自动处理多设备编辑冲突

## ✅ 已完成的配置

### 1. Entitlements 文件

已更新 `migraine_note.entitlements`，包含以下配置：

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.$(CFBundleIdentifier)</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
<key>com.apple.developer.ubiquity-kvstore-identifier</key>
<string>$(TeamIdentifierPrefix)$(CFBundleIdentifier)</string>
<key>aps-environment</key>
<string>development</string>
```

**说明：**
- `iCloud.$(CFBundleIdentifier)`：动态容器标识符，自动匹配Bundle ID
- `CloudKit`：启用CloudKit服务
- `ubiquity-kvstore-identifier`：iCloud KVS（键值存储）
- `aps-environment`：推送通知环境（用于CloudKit订阅）

### 2. SwiftData 配置

在 `migraine_noteApp.swift` 中，ModelContainer已配置为自动CloudKit同步：

```swift
let container = try ModelContainer(
    for: AttackRecord.self, 
        Medication.self, 
        UserProfile.self,
    configurations: ModelConfiguration(
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .automatic  // ✅ 自动CloudKit同步
    )
)
```

**关键点：**
- `.automatic`：自动检测并使用用户的私有CloudKit数据库
- SwiftData自动处理：
  - 上传本地更改到iCloud
  - 下载远程更改到本地
  - 冲突解决（Last Write Wins策略）

## 🛠️ Xcode 配置步骤

### Step 1: 设置Apple开发者账号

1. 打开 Xcode → 项目 → `Signing & Capabilities`
2. 选择 `migraine_note` Target
3. 在 `Team` 下拉菜单中选择你的Apple开发者账号
4. 确保 `Bundle Identifier` 是唯一的（例如：`com.yourname.migraine-note`）

### Step 2: 添加 iCloud Capability

1. 点击 `+ Capability` 按钮
2. 搜索并添加 `iCloud`
3. 勾选以下选项：
   - ✅ CloudKit
   - ✅ iCloud Documents（可选，暂不需要）
4. 在 `Containers` 部分，Xcode会自动创建容器：
   - `iCloud.com.yourname.migraine-note`

### Step 3: 验证配置

1. **检查 Entitlements 文件**：
   - 确保 `iCloud-container-identifiers` 中包含你的容器ID
   - 确保 `iCloud-services` 包含 `CloudKit`

2. **检查 CloudKit Dashboard**：
   - 访问：https://icloud.developer.apple.com/
   - 登录你的Apple开发者账号
   - 选择你的容器（`iCloud.com.yourname.migraine-note`）
   - 查看 `Schema` → 自动生成的Record Types（如 `CD_AttackRecord`）

3. **构建并运行**：
   - 在真机上运行（模拟器需要额外配置）
   - 确保设备已登录iCloud账号
   - 在 `Settings.app → iCloud` 中启用本App的iCloud权限

## 📱 多设备测试

### 测试场景 1: 基础同步

1. 在设备A上创建一条发作记录
2. 等待几秒（CloudKit上传）
3. 在设备B上打开App
4. 验证：设备B应该自动显示设备A创建的记录

### 测试场景 2: 离线编辑

1. 在设备A上关闭网络
2. 创建/编辑记录
3. 在设备B上也关闭网络并编辑同一条记录
4. 分别恢复网络连接
5. 验证：CloudKit自动解决冲突（Last Write Wins）

### 测试场景 3: 删除同步

1. 在设备A上删除一条记录
2. 等待同步
3. 在设备B上验证记录已删除

## 🔍 调试技巧

### 1. 启用 CloudKit 日志

在 Xcode Scheme 中添加环境变量：

```
-com.apple.CoreData.CloudKitDebug 1
-com.apple.CoreData.Logging.stderr 1
```

**步骤：**
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. 添加上述变量并设为 `1`

### 2. 查看日志输出

运行App后，在Console中搜索关键字：
- `CloudKit`: 同步操作日志
- `NSPersistentCloudKitContainer`: 容器操作
- `CKError`: CloudKit错误

### 3. 常见错误处理

| 错误代码 | 含义 | 解决方案 |
|---------|------|----------|
| `CKErrorNotAuthenticated` | 用户未登录iCloud | 提示用户在设置中登录iCloud |
| `CKErrorNetworkUnavailable` | 网络不可用 | 等待网络恢复，自动重试 |
| `CKErrorQuotaExceeded` | iCloud存储空间不足 | 提示用户清理iCloud空间 |
| `CKErrorZoneBusy` | CloudKit正在忙碌 | 自动重试，无需处理 |

## 🎨 用户界面提示

### 同步状态显示

在 `SettingsView` 中，已实现同步状态卡片：

- **已启用**：用户已登录iCloud且授权本App
- **未启用**：提示用户在系统设置中登录iCloud
- **同步中**：显示同步进度（可选实现）

### 最佳实践

1. **启动时检查iCloud状态**：
   ```swift
   FileManager.default.ubiquityIdentityToken != nil
   ```

2. **监听iCloud账号变更**：
   ```swift
   NotificationCenter.default.addObserver(
       forName: .NSUbiquityIdentityDidChange,
       object: nil,
       queue: .main
   ) { _ in
       // 处理账号变更
   }
   ```

3. **提示用户**：
   - 首次启动时显示iCloud同步说明
   - 在设置页面提供iCloud状态查询
   - 发生错误时友好提示

## 🔐 隐私与安全

### 数据存储位置

- **私有数据库**：`CloudKitDatabase.private`
  - 只有数据所有者（用户）可以访问
  - 开发者无法查看或修改用户数据
  - 数据加密传输和存储

- **不使用公开数据库**：
  - 不需要共享数据给其他用户
  - 不需要全局查询功能

### 数据迁移

如果用户换了iCloud账号：
- SwiftData会自动清空本地数据
- 加载新账号的CloudKit数据
- 旧账号数据保留在旧iCloud账号中

### GDPR 合规

- ✅ 用户完全控制数据
- ✅ 支持删除所有数据（删除记录）
- ✅ 数据不会被第三方访问
- ✅ 透明的隐私政策（在AboutView中展示）

## 📊 同步性能优化

### 1. 批量上传

SwiftData自动批量上传更改，减少网络请求：
- 多个更改合并为一个CKModifyRecordsOperation
- 自动处理大对象（>1MB）分块上传

### 2. 增量同步

只同步变更的数据：
- 使用 `modificationDate` 追踪更改
- 只下载上次同步后的新数据

### 3. 后台同步

CloudKit支持后台同步（需要配置）：
- 应用在后台时继续同步
- 使用静默推送通知触发同步

## 🚀 部署清单

### 开发环境

- [x] 配置 Entitlements 文件
- [x] 设置 SwiftData ModelConfiguration
- [x] 添加 iCloud Capability
- [x] 真机测试同步功能

### 生产环境

- [ ] 切换 `aps-environment` 为 `production`
- [ ] 在App Store Connect中启用CloudKit
- [ ] 部署CloudKit Schema到生产环境
- [ ] 提交App审核时说明iCloud用途

## 📚 参考资料

### 官方文档

- [SwiftData + CloudKit官方指南](https://developer.apple.com/documentation/swiftdata/syncing-data-with-cloudkit)
- [CloudKit Dashboard](https://icloud.developer.apple.com/)
- [CloudKit错误代码](https://developer.apple.com/documentation/cloudkit/ckerror)

### 最佳实践

- [WWDC 2023: SwiftData with CloudKit](https://developer.apple.com/videos/)
- [Core Data + CloudKit迁移指南](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)

## 🆘 故障排查

### 问题：同步不工作

**检查清单：**
1. 设备已登录iCloud？（设置 → iCloud）
2. App已授权使用iCloud？（设置 → 通用 → iPhone存储 → 本App）
3. 网络连接正常？
4. Xcode中Team配置正确？
5. Entitlements文件配置正确？
6. CloudKit容器已创建？（CloudKit Dashboard）

### 问题：数据冲突

SwiftData默认使用 **Last Write Wins** 策略：
- 最后写入的数据覆盖之前的版本
- 对于偏头痛记录App，这是合理的策略
- 如需自定义冲突解决，需要监听 `NSPersistentCloudKitContainer` 事件

### 问题：同步延迟

正常延迟：
- 本地 → iCloud：几秒到十几秒
- iCloud → 其他设备：几秒到几分钟
- 取决于网络速度和CloudKit服务器负载

优化建议：
- 不要在UI中阻塞等待同步完成
- 显示乐观更新（本地先显示，后台同步）
- 提供手动刷新选项（下拉刷新）

## ✅ 验证完成

配置完成后，验证以下功能：

- [ ] 在两台设备上登录同一iCloud账号
- [ ] 设备A创建记录，设备B能看到
- [ ] 设备B编辑记录，设备A能看到更新
- [ ] 设备A删除记录，设备B能看到删除
- [ ] 离线创建记录，联网后自动同步
- [ ] 切换iCloud账号，数据正确切换

---

**最后更新**: 2026年2月1日  
**状态**: ✅ 配置完成，待真机测试  
**下一步**: 在真机上测试多设备同步
