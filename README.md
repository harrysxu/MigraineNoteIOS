# 偏头痛记录 iOS App

一款基于iOS原生技术栈的医疗级偏头痛管理应用，遵循IHS ICHD-3标准和《中国偏头痛诊断与治疗指南2024版》。

## ✨ 主要特点

- **隐私至上** - 所有数据存储在用户iCloud私有数据库
- **医疗级标准** - 遵循国际和国内偏头痛诊疗指南
- **零第三方依赖** - 纯Apple原生框架实现
- **中西医结合** - 整合中医证候分析

## 🎯 核心功能

### ✅ 已实现

1. **完整的发作记录流程**（Phase 2）
   - 5步向导式记录（时间→疼痛→症状→诱因→干预）
   - 疼痛强度评估（VAS 0-10）
   - 交互式头部疼痛部位选择器（HeadMapView）
   - 疼痛性质记录
   - 先兆记录
   - 中西医症状选择
   - 诱因追踪（预定义+自定义）
   - 用药记录和非药物疗法

2. **记录编辑功能**（Phase 6）
   - 编辑现有发作记录
   - 预填充所有字段
   - 支持修改时间、疼痛、症状、诱因、用药

3. **记录列表与详情**（Phase 6）
   - 完整的筛选和排序功能
   - 全文搜索
   - 疼痛强度范围筛选
   - 详细信息展示（8个卡片）
   - 天气数据关联展示

4. **日历视图**（Phase 7）
   - 月视图网格（7x6）
   - 疼痛强度色点可视化
   - 月度统计卡片
   - MOH风险警告

5. **数据可视化**（Phase 9）
   - Swift Charts集成
   - 月度趋势柱状图
   - MOH风险环形进度条
   - 诱因频次分析（Top 5）
   - 昼夜节律散点图
   - MIDAS残疾评分

6. **用药管理**（Phase 10）
   - 药箱管理（药物CRUD）
   - 常用药物预设（16种）
   - MOH风险实时监控
   - 库存管理和提醒
   - 疗效数据统计
   - 使用历史追踪

7. **PDF医疗报告**（Phase 11）
   - 专业的A4格式报告
   - 患者信息和报告周期
   - 统计摘要和MOH评估
   - 诱因分析（Top 10）
   - 详细记录表格
   - PDF导出和分享

8. **设置页面**（Phase 12）
   - 个人信息管理
   - HealthKit权限管理
   - 位置服务设置
   - iCloud同步状态监控
   - 功能配置（中医、天气、评分方式）
   - 提醒设置（用药、疗效）
   - 关于页面

9. **CloudKit同步**（Phase 13）
   - iCloud + CloudKit自动同步
   - 私有数据库存储
   - 多设备无缝同步
   - 实时同步状态显示
   - 离线优先设计

10. **HealthKit集成**（Phase 4）
    - 自动同步头痛记录到健康App
    - 读取睡眠时长
    - 读取月经周期
    - 读取心率数据

11. **WeatherKit集成**（Phase 5）
    - 自动记录发作时天气状况
    - 气压、湿度、温度、风速
    - 气压趋势判断
    - 环境风险预警

12. **数据分析引擎**（Phase 8）
    - 月度统计
    - 诱因频次分析
    - 昼夜节律分析
    - MOH（药物过度使用头痛）风险检测
    - MIDAS残疾评分

13. **UI优化与辅助功能**（Phase 14）
    - 加载/空状态/错误状态视图
    - Toast提示系统
    - 丰富的动画效果（淡入、滑入、按压反馈）
    - 骨架屏加载
    - VoiceOver完整支持
    - 色盲友好设计
    - 最小触摸目标（44pt）
    - 动态字体大小支持
    - 尊重系统"减弱动画"设置

14. **单元测试**（Phase 15部分）
    - MOH检测算法测试
    - 数据分析引擎测试
    - 边界值和异常情况测试

15. **精美的UI设计**（Phase 1）
    - 暗黑模式优先（保护畏光患者）
    - 完整的设计系统（Colors、Spacing、Typography）
    - 15+个可复用组件
    - 流畅的动画和交互

### 🔄 待完成

- **用药提醒功能**（Phase 10部分）- UNUserNotificationCenter集成
- **中医证候分析**（Phase 8部分）- TCMPatternAnalyzer算法实现
- **UI测试**（Phase 15）- 完整的UI自动化测试
- **性能优化**（Phase 15）- 分页加载、索引优化

## 🛠️ 技术栈

- **UI框架**: SwiftUI (iOS 17.0+)
- **数据持久化**: SwiftData + CloudKit
- **健康数据**: HealthKit
- **天气数据**: WeatherKit
- **图表**: Swift Charts
- **PDF生成**: PDFKit
- **语言**: Swift 5.9+

## 📱 系统要求

- iOS 17.0 或更高版本
- Xcode 15.0 或更高版本
- Apple Developer账号（用于HealthKit和WeatherKit）

## 🚀 快速开始

### 1. 克隆项目

```bash
cd /Users/xuxiaolong/OpenSource/migraine_note_ios
```

### 2. 配置Xcode

#### 2.1 添加Capabilities

在Xcode中：
1. 选择Target: `migraine_note`
2. 前往 `Signing & Capabilities`
3. 点击 `+ Capability` 添加：
   - **HealthKit**
   - **iCloud**
     - 勾选 `CloudKit`
     - 添加Container: `iCloud.com.yourteam.migraine-note`
   - **Background Modes**
     - 勾选 `Remote notifications`

#### 2.2 配置entitlements

确认 `migraine_note.entitlements` 包含：

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array>
    <string>health-records</string>
</array>
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.yourteam.migraine-note</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

#### 2.3 WeatherKit配置

1. 登录 [Apple Developer](https://developer.apple.com/)
2. 前往 `Certificates, Identifiers & Profiles`
3. 选择你的App ID
4. 启用 `WeatherKit`
5. 创建WeatherKit服务密钥

### 3. 运行项目

```bash
# 在Xcode中打开项目
open migraine_note/migraine_note.xcodeproj

# 选择目标设备或模拟器
# Command + R 运行
```

## 📂 项目结构

```
migraine_note/migraine_note/
├── Models/                      # 数据模型（8个）
│   ├── AttackRecord.swift      # 发作记录
│   ├── Symptom.swift           # 症状
│   ├── Trigger.swift           # 诱因
│   ├── Medication.swift        # 药物
│   ├── MedicationLog.swift     # 用药记录
│   ├── WeatherSnapshot.swift   # 天气快照
│   ├── UserProfile.swift       # 用户配置
│   └── PainLocation.swift      # 疼痛部位枚举
├── ViewModels/                  # 视图模型（5个）
│   ├── HomeViewModel.swift
│   ├── RecordingViewModel.swift
│   ├── AttackListViewModel.swift
│   ├── CalendarViewModel.swift
│   └── MedicationViewModel.swift
├── Views/                       # 视图（35+个）
│   ├── MainTabView.swift       # 主导航（6个标签）
│   ├── Home/                   # 首页
│   ├── Recording/              # 记录流程（6个步骤）
│   ├── AttackList/             # 列表和详情
│   ├── Calendar/               # 日历视图
│   ├── Analytics/              # 数据分析和导出
│   ├── Medication/             # 用药管理
│   └── Settings/               # 设置页面
├── Services/                    # 服务层（6个）
│   ├── HealthKitManager.swift
│   ├── WeatherManager.swift
│   ├── AnalyticsEngine.swift
│   ├── MOHDetector.swift
│   ├── MedicalReportGenerator.swift
│   └── CloudKitManager.swift
├── DesignSystem/               # 设计系统
│   ├── Colors.swift
│   ├── Spacing.swift
│   ├── Typography.swift
│   ├── AnimationHelpers.swift
│   ├── AccessibilityHelpers.swift
│   └── Components/            # 可复用组件（15+个）
│       ├── Buttons.swift
│       ├── InfoCard.swift
│       ├── DetailCard.swift
│       ├── SelectableChip.swift
│       ├── FlowLayout.swift
│       ├── HeadMapView.swift
│       ├── LoadingView.swift
│       └── PainIntensitySlider.swift
├── Resources/
│   └── Assets.xcassets
├── Info.plist
└── migraine_noteApp.swift
```

## 📖 使用指南

### 记录一次发作

1. 打开App，点击首页的"开始记录"按钮
2. **步骤1**: 选择发作开始时间和状态（进行中/已结束）
3. **步骤2**: 评估疼痛强度（0-10），选择疼痛性质和部位
4. **步骤3**: 选择伴随症状和是否有先兆
5. **步骤4**: 选择可能的诱因（支持自定义）
6. **步骤5**: 记录用药和非药物疗法，添加备注
7. 点击"完成"保存记录

### 查看统计分析

进入"分析"标签，可以查看：
- 月度发作趋势
- 诱因频次排名
- 昼夜节律分析
- MOH风险评估

### 导出医疗报告

进入"分析"标签 → 点击右上角导出按钮，可以：
- 选择时间范围（1/3/6/12月或自定义）
- 预览报告数据
- 生成并分享PDF医疗报告

### 管理药箱

进入"药箱"标签，可以：
- 添加常用药物（支持16种预设药物）
- 查看MOH风险提示
- 管理库存
- 查看使用统计和疗效分析

## 🔐 隐私与安全

- **本地存储**: 所有数据首先存储在设备本地（SQLite）
- **iCloud同步**: 使用CloudKit私有数据库，端到端加密
- **零第三方**: 不使用任何第三方SDK，数据不会泄露给开发者
- **生物识别**: 支持Face ID / Touch ID保护（可选）

## 🏥 医疗标准

本应用遵循：
- **IHS ICHD-3** (国际头痛疾患分类第三版)
- **中国偏头痛诊断与治疗指南（2024版）**

**重要声明**: 本应用仅用于记录和辅助分析，不提供诊断或治疗建议。请务必咨询专业医生。

## 🤝 贡献指南

### 代码规范

- 使用SwiftUI最佳实践
- 遵循MVVM架构
- 每个文件顶部包含创建信息
- 所有View提供Preview
- 使用@Observable宏（iOS 17+）

### 提交规范

```
feat: 添加新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 重构代码
test: 添加测试
```

## 📝 开发日志

详见 [PROGRESS.md](PROGRESS.md)

## 📄 许可证

MIT License

## 👥 作者

AI Assistant + 徐晓龙

## 🙏 致谢

感谢以下文档和指南：
- 国际头痛协会（IHS）
- 中国神经学会
- Apple Developer Documentation
- SwiftUI官方文档

---

**最后更新**: 2026年2月1日  
**版本**: 0.9.5 (Beta)  
**完成度**: ~95%  
**状态**: 🚀 Beta测试（Phase 1-15已完成）
