# **基于iOS原生生态的中国本地化偏头痛管理与分析平台产品需求及研究报告**

## **1\. 执行摘要与战略背景**

### **1.1 项目背景与市场现状**

偏头痛（Migraine）是一种常见的慢性神经血管性疾病，其特征为反复发作的中重度搏动性头痛，常伴有恶心、呕吐、畏光和畏声等自主神经症状。在中国，偏头痛的患病率呈上升趋势，且由于人口基数巨大，患者绝对数量惊人。然而，目前的医疗环境面临着就诊率低、诊断不足以及患者自我管理意识薄弱等挑战 1。

尽管市场上存在多款头痛记录应用（如Migraine Buddy等），但针对中国市场的本地化解决方案仍显匮乏。现有的主流应用多采用西方医疗标准，缺乏对中医（TCM）证候的记录支持，且在饮食诱因方面未能涵盖中国特有的饮食习惯（如味精、特定发物等）。此外，数据隐私问题日益受到关注，许多用户对于将敏感的健康数据上传至第三方服务器持保留态度。

基于此，本项目旨在开发一款完全基于iOS原生生态、不支持第三方依赖、利用iCloud进行数据同步的头痛管家App。该应用将严格遵循《中国偏头痛诊断与治疗指南（2024版）》及国际头痛协会（IHS）标准，旨在为患者提供简便的记录工具，为医生提供精准的临床决策辅助数据。

### **1.2 产品核心价值主张**

本产品的核心定位是“专业的医疗级记录助手”，而非简单的记事本或越权的诊断工具。

* **隐私至上（Privacy First）：** 利用Apple的Core Data与CloudKit，确保所有数据仅存储于用户的设备和个人的iCloud账户中，完全规避第三方数据泄露风险。  
* **极简与深度并存：** 设计“一键记录”功能以应对剧痛时的操作困难，同时提供符合科研标准的详细记录模式。  
* **中西医结合分析：** 在遵循国际IHS标准的同时，深度整合中医体质与诱因分析（风、寒、湿、热），填补市场空白。  
* **临床决策支持：** 生成的报告不仅仅是数据的堆砌，而是经过清洗和结构化的医疗文档，直接服务于神经内科医生的问诊需求。

## ---

**2\. 临床医学基础与数据标准化研究**

在设计任何功能之前，必须深入理解偏头痛的临床特征及诊疗指南，这是确保App记录的数据具有医疗价值的基石。

### **2.1 国际头痛协会（IHS）与ICHD-3标准解析**

根据《国际头痛疾患分类第三版》（ICHD-3），偏头痛的诊断高度依赖于病史特征。一个合格的偏头痛日记必须能够捕捉以下核心数据点，以便医生进行鉴别诊断 2：

* **发作持续时间（Duration）：** 未经治疗或治疗无效的发作通常持续4-72小时。App必须具备精确的时间追踪功能，记录发作的起止时间点，以辅助判断是否符合偏头痛的时间特征。  
* **疼痛特征（Pain Characteristics）：**  
  * **部位：** 偏头痛通常为单侧（Unilateral），但也可为双侧。记录工具需提供交互式头部图谱。  
  * **性质：** 典型的搏动性（Pulsating）疼痛。  
  * **强度：** 中度或重度（Moderate or Severe），通常会因日常体力活动（如走路或爬楼梯）而加重。  
* **伴随症状（Associated Symptoms）：** 恶心（Nausea）和/或呕吐（Vomiting），以及畏光（Photophobia）和畏声（Phonophobia）。这四项是诊断的关键标准。  
* **先兆（Aura）：** 约1/3的患者伴有先兆，通常在头痛前发生，表现为视觉闪光、暗点、感觉异常或言语障碍 3。App需提供专门的先兆记录模块。

### **2.2 中国偏头痛诊疗指南（2024版）的本地化要求**

《中国偏头痛诊断与治疗指南》强调了适合中国国情的管理策略，这对App的功能设计提出了具体要求 1：

* **药物过度使用头痛（MOH）的防范：** 指南明确指出，单纯镇痛药每月使用超过15天，或曲普坦类/阿片类药物每月超过10天，可能导致MOH 5。App必须内置计数器，实时监控急性药物的使用频率，并给予用户预警。  
* **中医证候的识别：** 指南中提及中医药在偏头痛防治中的作用。中医将头痛分为外感（风寒、风热、风湿）和内伤（肝阳上亢、血虚、痰浊等） 7。App的诱因和症状库需扩充中医术语，例如“遇风加重”、“口苦”、“舌苔厚腻”等选项。  
* **中国特有饮食诱因：** 相比西方指南强调的奶酪和红酒，中国患者的诱因更多涉及含味精（MSG）的食物、腌制食品（腊肉、香肠中的亚硝酸盐）以及特定的“发物” 9。

### **2.3 临床科研数据的标准化**

为了使记录的数据不仅用于个人管理，还能在用户授权下辅助临床科研，App的数据结构应参考ResearchKit的标准和临床病例报告表（CRF）的设计规范 11。

* **疼痛量表：** 采用视觉模拟评分法（VAS）或数字评分法（NRS），这是临床评估疼痛强度的金标准 13。  
* **生活质量评估：** 集成MIDAS（偏头痛残疾评估量表）或HIT-6（头痛对生活影响测定）的简易版问卷，用于评估长期治疗效果 15。

## ---

**3\. 竞品分析与用户体验（UI/UX）设计策略**

通过分析市场上受欢迎的App（如Migraine Buddy, Migraine Monitor），我们取其精华，去其“臃肿”，并针对iOS原生风格进行优化。

### **3.1 竞品功能解构与借鉴**

* Migraine Buddy 16:  
  * *优点：* 记录流程非常详细，自动记录睡眠（通过手机传感器），社区功能强大。  
  * *缺点：* 界面过于复杂，启动慢，依赖账户登录，隐私顾虑，对中国用户而言服务器连接不稳定。  
  * *借鉴点：* “睡眠检测”概念（利用HealthKit替代自有算法）、详细的“发作后分析报告”。  
* N1-Headache 18:  
  * *优点：* 强调数据分析，寻找诱因的相关性。  
  * *借鉴点：* 诱因分析图表的设计，以及每日风险预测的概念。

### **3.2 核心设计理念：以人为本的“暗黑模式”**

偏头痛发作时，患者极度畏光（Photophobia）。一个明亮、白底黑字的界面对发作中的患者来说是极大的刺激 18。

* **默认暗黑（True Dark）：** App将强制或默认采用纯黑（\#000000）背景。这不仅利用了OLED屏幕的省电特性，更重要的是最大程度减少光线发射，保护患者眼睛。  
* **低饱和度配色：** 避免使用高饱和度的红色或橙色作为警示色，改用柔和的蓝紫色（Teal/Purple）作为主色调。文字颜色应使用iOS系统定义的灰色（SystemGray），而非刺眼的纯白。  
* **极简操作（One-Tap Logging）：** 在剧烈疼痛、恶心呕吐时，用户无法进行复杂的打字操作。首页必须设计一个巨大的“记录”按钮，一键记录当前时间、地点和天气，其余细节可在缓解后补录。

### **3.3 交互导航设计**

App采用iOS标准的Tab Bar导航结构，分为五大模块：

1. **首页（Today）：** 状态概览、快速记录、每日任务。  
2. **日历（Calendar）：** 月视图、周期追踪。  
3. **记录（Log）：** 历史列表、补录入口。  
4. **分析（Insights）：** 图表、诱因关联。  
5. **更多（Profile）：** 导出报告、设置、HealthKit权限管理。

## ---

**4\. 详细功能设计与页面规范**

本章节将详细拆解每个页面的功能点、数据字段及逻辑。

### **4.1 首页（Home Dashboard）：仪表盘与快速入口**

首页是用户打开App的第一眼，必须清晰、无压力。

* **头部状态栏：**  
  * **当前状态：** 显示“目前无发作”或“发作进行中（已持续 2小时30分）”。  
  * **无头痛连续天数（Streak）：** “您已连续 12 天无头痛”，提供正向反馈 16。  
* **环境诱因卡片（WeatherKit集成）：**  
  * **气压趋势：** 显示当前气压（hPa）及未来24小时趋势。气压剧烈变化（如台风前夕气压骤降）是重要诱因 17。  
  * **温湿度：** 结合中医“湿邪”理论，当湿度过高时提示用户注意祛湿。  
* **核心操作区：**  
  * **“开始记录”按钮：** 位于屏幕中央下方的巨大圆形按钮，带有微弱的呼吸动效。  
    * *交互：* 点击立即创建一条AttackRecord，记录startTime为当前时间。  
* **每日打卡（CareKit风格）：**  
  * **预防性用药提醒：** 如“服用 盐酸氟桂利嗪 5mg”。  
  * **睡眠确认：** 从HealthKit读取昨晚睡眠数据，用户确认“昨晚睡得好吗？”。

### **4.2 发作记录流程（The Recording Flow）**

这是App的核心功能。为了降低认知负荷，采用分步向导式设计（Wizard Style），参考ResearchKit的ORKOrderedTask交互模式 12。

#### **步骤 1：时间与状态 (Time & Duration)**

* **开始/结束时间：** 默认当前时间，支持滚轮调节。  
* **发作状态：** “进行中”或“已结束”。

#### **步骤 2：疼痛评估 (Pain Assessment)**

* **疼痛强度（VAS/NRS）：**  
  * *UI：* 滑动条（Slider），从0（无痛）到10（剧痛）。  
  * *视觉反馈：* 随着分值增加，滑块上方的表情图标从平静变为痛苦，背景色从深绿渐变至暗紫 21。  
* **疼痛性质（多选）：**  
  * 搏动性（跳痛）、压迫感（紧箍感）、刺痛、钝痛、胀痛（中医概念）。  
* **疼痛部位（Body Map）：**  
  * *UI：* 一个3D渲染的头部模型（前、后、左、右视图） 22。  
  * *交互：* 用户点击具体区域（如左侧太阳穴、眼眶后、头顶、后脑勺）。  
  * *逻辑：* 系统自动判断是“单侧”还是“双侧”，是“前额”还是“枕部”（枕部疼痛可能提示颈源性头痛）。

#### **步骤 3：伴随症状与先兆 (Symptoms & Aura)**

* **先兆（Aura）：** 视觉闪光、视野缺损（暗点）、手脚麻木、语言障碍。记录先兆发生的时长（通常5-60分钟）。  
* **伴随症状：** 恶心、呕吐、畏光、畏声、气味敏感（Osmophobia）、头皮触痛（Allodynia）。  
* **中医特有症状：** 口苦、面红目赤（肝火）、手脚冰凉（寒凝）、头重如裹（湿邪） 8。

#### **步骤 4：诱因记录 (Triggers)**

提供预设分类标签，支持自定义添加和智能排序（常用诱因置顶）。

* **饮食：** 味精（MSG）、巧克力、奶酪、红酒、咖啡因、腌制食品、辛辣、冷饮。  
* **环境：** 天气变化、强光、异味、高海拔。  
* **生活方式：** 睡眠不足/过多、压力、周末放松（Let-down migraine）、漏餐（低血糖）。  
* **激素：** 月经期、排卵期（自动关联HealthKit经期数据）。

#### **步骤 5：干预措施 (Interventions)**

* **药物治疗：**  
  * 选择药物（从用户的“药箱”中选择，如布洛芬、佐米曲普坦、利扎曲普坦等）。  
  * 记录剂量（mg）和服用时间。  
  * **疗效评估（关键）：** 服药2小时后，App需推送通知询问：“疼痛缓解了吗？”（完全缓解/部分缓解/无效）。这是评估药物是否有效的临床标准 5。  
* **非药物疗法：** 睡眠、冷敷、热敷、按摩、针灸（TCM）、在暗室休息。

### **4.3 药物管理与药箱 (Medication Cabinet)**

为了防止药物过度使用（MOH），必须有一个独立的药物管理模块。

* **急性药物（止痛药）：** 设定每月限量阈值（如曲普坦类 \< 10天）。  
* **预防性药物：** 设定每日服用提醒。  
* **库存管理：** 记录剩余药量，提醒补货。

### **4.4 数据分析与报表 (Analytics & Reports)**

此页面通过Core Data聚合数据，利用Swift Charts进行可视化展示。

* **月度概览图：** 柱状图显示每月头痛天数。辅助线标示“慢性偏头痛阈值”（15天/月）。  
* **诱因分析雷达图：** 展示哪些诱因（如睡眠、天气、压力）与发作关联度最高。  
* **昼夜节律图：** 散点图展示发作时间分布（如清晨发作多提示睡眠相关或高血压风险）。  
* **药物过度使用预警盘：** 环形进度条显示本月已用药天数。如果超过10天，进度条变红并弹出警告：“注意：频繁使用止痛药可能导致药物过度使用性头痛（MOH）” 6。  
* **MIDAS/HIT-6评分卡片：** 根据用户记录的“因头痛无法工作/学习的天数”自动估算残疾评分。

### **4.5 医生专用报告导出 (Export for Doctors)**

这是连接患者与医生的桥梁。

* **格式：** 生成标准A4大小的PDF文件。  
* 内容结构 24：  
  * **患者基本信息：** 姓名、年龄、病史时长。  
  * **关键指标摘要：** 近3个月平均发作频率、平均疼痛评分、急性药物使用天数（MOH风险评估）。  
  * **详细发作日志（表格形式）：** 日期 | 开始时间 | 持续时长 | 最高疼痛级 | 诱因 | 药物 | 疗效。  
  * **可视化图表：** 发作频率趋势图、疼痛部位热力图。  
* **分享方式：** 利用iOS原生Share Sheet，支持AirDrop、打印、保存到文件或通过微信发送。

## ---

**5\. 技术架构与实现细节（iOS Native Only）**

本项目严格遵循“零第三方依赖”原则，所有技术栈均基于Apple Developer生态。

### **5.1 数据持久化与同步：Core Data \+ CloudKit**

这是实现隐私保护与多端同步（iPhone/iPad）的核心 26。

* **NSPersistentCloudKitContainer：** 使用此容器自动处理本地SQLite数据库与iCloud私有数据库的镜像同步。  
* **Schema设计（.xcdatamodeld）：**  
  * **Entity: AttackRecord（发作记录）**  
    * id: UUID  
    * startTime: Date  
    * endTime: Date (Nullable)  
    * severity: Integer (0-10)  
    * hasAura: Boolean  
    * notes: String  
    * **Relationships:**  
      * symptoms (to-many Symptom)  
      * triggers (to-many Trigger)  
      * medications (to-many MedicationLog)  
  * **Entity: MedicationLog（用药记录）**  
    * name: String  
    * dosage: Double  
    * timeTaken: Date  
    * efficacy: Integer (0=无效, 1=部分, 2=完全)  
  * **Entity: WeatherSnapshot（气象快照）**  
    * pressure: Double  
    * humidity: Double  
    * condition: String  
* **数据隔离：** 所有数据存储在用户的CloudKit Private Database中，开发者无法查看，完全符合GDPR及中国《个人信息保护法》要求。

### **5.2 生物识别整合：HealthKit**

利用HealthKit打破数据孤岛，自动获取身体数据 28。

* **写入数据：**  
  * **头痛记录：** 使用HKCategoryTypeIdentifier.headache。  
  * **元数据（Metadata）：** 必须写入HKMetadataKeyHeadacheSeverity，将App内的VAS评分映射到HealthKit的标准严重程度（Not Present, Mild, Moderate, Severe）。  
* **读取数据（用于智能分析）：**  
  * **月经周期：** HKCategoryTypeIdentifier.menstrualFlow。用于预测经期性偏头痛（Menstrual Migraine）。  
  * **睡眠分析：** HKCategoryTypeIdentifier.sleepAnalysis。分析睡眠时长及质量与次日头痛的相关性。  
  * **心率：** HKQuantityTypeIdentifier.heartRate。部分患者发作前会有心率变化。

### **5.3 环境数据：WeatherKit**

使用Apple原生的WeatherKit REST API（通过Swift SDK调用）获取精准的天气数据 20。

* **调用时机：** 用户点击“开始记录”时，以及每日后台刷新时。  
* **关键指标：** 气压（Pressure）、气压趋势（Pressure Trend）、湿度（Humidity）、风速（Wind Speed）。  
* **历史回溯：** 如果用户补录昨天的头痛，利用WeatherKit的历史数据接口获取当时的天气。

### **5.4 临床交互组件：ResearchKit & CareKit**

* **ResearchKit:** 用于构建标准化的“发作调查问卷”。  
  * ORKScaleAnswerFormat: 用于VAS疼痛滑块。  
  * ORKImageChoiceAnswerFormat: 用于选择疼痛性质图标。  
* **CareKit:** 用于构建“预防性治疗管理”模块。  
  * OCKChecklistTask: 用于每日服药打卡。  
  * OCKChart: 用于生成直观的依从性图表。

## ---

**6\. 中医（TCM）深度整合方案**

鉴于中国市场的特殊性，中医模块不是简单的翻译，而是深度的逻辑整合。

### **6.1 中医体质与诱因映射表**

| 西医/通用诱因 | 中医对应概念 | App记录项设计 | 数据逻辑关联 |
| :---- | :---- | :---- | :---- |
| **Weather (Wind/Cold)** | **风寒侵袭 (Wind-Cold)** | 诱因：吹风、受凉 | 关联WeatherKit风速\>4级或气温骤降 |
| **Weather (Humidity)** | **湿邪困阻 (Dampness)** | 诱因：阴雨天、身体沉重 | 关联WeatherKit湿度\>80% |
| **Stress/Emotion** | **肝气郁结/肝火上炎** | 诱因：生气、压力大 | 关联症状：口苦、胁痛、易怒 |
| **Fatigue/Weakness** | **气血亏虚** | 诱因：劳累、经期后 | 关联症状：面色苍白、心悸 |
| **Diet (Spicy/Alcohol)** | **湿热内蕴** | 诱因：辛辣、饮酒 | 关联症状：舌苔黄腻、大便干结 |

### **6.2 智能分析建议（非诊断）**

App不进行诊断，但可以提供基于TCM逻辑的**生活方式建议**：

* 如果用户频繁记录“湿邪”相关诱因（如雨天发作），App的分析页可以提示：“近期发作与高湿度环境高度相关，建议注意居住环境除湿，饮食可适当增加健脾祛湿食材。”  
* 这种建议属于生活指导范畴，不触犯“非医疗器械不得诊断”的红线。

## ---

**7\. 详细页面流程图与字段定义表 (Detailed Page Flow & Fields)**

为了开发实施的准确性，以下列出核心数据库字段的详细定义。

### **表 7.1：发作记录主表 (AttackRecord Fields)**

| 字段名 (Key) | 数据类型 (Type) | 必填 | 默认值 | 描述与逻辑 |
| :---- | :---- | :---- | :---- | :---- |
| uuid | UUID | Yes | Auto | 唯一标识符 |
| startTime | Date | Yes | Current | 发作开始时间 |
| endTime | Date | No | Null | 发作结束时间，为空表示“进行中” |
| painIntensity | Int16 | Yes | 0 | 0-10 VAS评分 |
| painLocation | String (JSON) | Yes |  | 存储选中的头部区域代码 (e.g.,) |
| painQuality | String (Array) | Yes |  | 疼痛性质 (e.g., \["Pulsating"\]) |
| hasAura | Bool | Yes | False | 是否伴有先兆 |
| auraType | String (Array) | No |  | 先兆类型 (Visual, Sensory, etc.) |
| triggers | Set | No |  | 关联诱因集合 |
| symptoms | Set | No |  | 关联伴随症状集合 |
| medications | Set | No |  | 关联药物记录 |
| weatherPressure | Double | No | 0.0 | 记录时的气压 (hPa) |
| menstrualDay | Int16 | No | 0 | 处于月经周期的第几天 (from HealthKit) |

### **表 7.2：诱因库设计 (Trigger Database \- Chinese Localized)**

| ID | 类别 | 名称 (CN) | 名称 (EN) | 权重 | 说明 |
| :---- | :---- | :---- | :---- | :---- | :---- |
| T01 | 饮食 | **味精 (MSG)** | MSG | High | 中国餐饮常见诱因 9 |
| T02 | 饮食 | **老火汤/高汤** | Bone Broth | Med | 含高浓度谷氨酸钠 |
| T03 | 饮食 | **腌制/腊肉** | Cured Meat | High | 含亚硝酸盐 |
| T04 | 饮食 | **冰饮/冷食** | Cold Drinks | High | 刺激迷走神经/胃寒 |
| T05 | 环境 | **闷热/雷雨前** | Low Pressure | High | 气压降低 |
| T06 | 环境 | **冷风直吹** | Cold Wind | High | 对应“风寒” |
| T07 | 睡眠 | **睡过头** | Oversleeping | Med | 周末常见 |
| T08 | 睡眠 | **失眠/熬夜** | Insomnia | High | 常见诱因 |

## ---

**8\. 总结与展望**

本产品需求文档（PRD）详细规划了一款针对中国市场的iOS原生头痛管家App。通过深度整合Apple HealthKit、CloudKit、WeatherKit和ResearchKit，我们能够在保证用户隐私（数据不出iCloud）的前提下，提供医疗级的记录与分析功能。

该应用不仅仅是一个记录工具，更是一个连接患者与医生的数字化桥梁。它通过标准化的数据采集（IHS标准）和本地化的内容适配（中医与中国饮食），解决了当前市场产品“水土不服”的问题。通过对药物过量使用的实时监控，它有望实质性地减少MOH的发生，提高患者的生活质量，这正是数字化医疗产品的核心价值所在。

后续开发阶段，建议优先完成核心记录流程（Core Data Schema搭建）与HealthKit打通，并在TestFlight阶段邀请神经内科医生参与Beta测试，以校准专业术语的准确性。

#### **引用的著作**

1. (PDF) Chinese practice guidelines for diagnosis and treatment of migraine (1st edition, Chinese Society of Neurology) \- ResearchGate, 访问时间为 二月 1, 2026， [https://www.researchgate.net/publication/385688955\_Chinese\_practice\_guidelines\_for\_diagnosis\_and\_treatment\_of\_migraine\_1st\_edition\_Chinese\_Society\_of\_Neurology](https://www.researchgate.net/publication/385688955_Chinese_practice_guidelines_for_diagnosis_and_treatment_of_migraine_1st_edition_Chinese_Society_of_Neurology)  
2. Guidelines \- International Headache Society, 访问时间为 二月 1, 2026， [https://ihs-headache.org/en/resources/guidelines/](https://ihs-headache.org/en/resources/guidelines/)  
3. International Classification of Headache Disorders, 3rd edition, 访问时间为 二月 1, 2026， [https://ichd-3.org/wp-content/uploads/2018/01/The-International-Classification-of-Headache-Disorders-3rd-Edition-2018.pdf](https://ichd-3.org/wp-content/uploads/2018/01/The-International-Classification-of-Headache-Disorders-3rd-Edition-2018.pdf)  
4. Chinese medicine for headaches in emergency department: a retrospective analysis of real-world electronic medical records \- Frontiers, 访问时间为 二月 1, 2026， [https://www.frontiersin.org/journals/neurology/articles/10.3389/fneur.2024.1529874/full](https://www.frontiersin.org/journals/neurology/articles/10.3389/fneur.2024.1529874/full)  
5. Treatment of migraine attacks and prevention of migraine: Guidelines by the German Migraine and Headache Society and the German Society of Neurology, 访问时间为 二月 1, 2026， [https://ihs-headache.org/wp-content/uploads/2020/06/3426\_dmkg-treatment-of-migraine-attacks-and-prevention-of-migraine.pdf](https://ihs-headache.org/wp-content/uploads/2020/06/3426_dmkg-treatment-of-migraine-attacks-and-prevention-of-migraine.pdf)  
6. Migraine management in Chinese headache centers: a national survey and the role of quality control inspections \- ResearchGate, 访问时间为 二月 1, 2026， [https://www.researchgate.net/publication/398044229\_Migraine\_management\_in\_Chinese\_headache\_centers\_a\_national\_survey\_and\_the\_role\_of\_quality\_control\_inspections](https://www.researchgate.net/publication/398044229_Migraine_management_in_Chinese_headache_centers_a_national_survey_and_the_role_of_quality_control_inspections)  
7. Effective Headaches and Migraines Relief with TCM \- Garuda Health, 访问时间为 二月 1, 2026， [https://www.garudahealth.org/effective-headaches-migraines-relief-with-tcm/](https://www.garudahealth.org/effective-headaches-migraines-relief-with-tcm/)  
8. Headaches and Migraines: A TCM Approach to Real Relief \- Sarah Johnson Acupuncture, 访问时间为 二月 1, 2026， [https://www.sarahjohnsonacupuncture.com/post/headaches-and-migraines-a-tcm-approach-to-real-relief](https://www.sarahjohnsonacupuncture.com/post/headaches-and-migraines-a-tcm-approach-to-real-relief)  
9. Low-Tyramine Diet for Individuals with Headache or Migraine, 访问时间为 二月 1, 2026， [https://headaches.org/resources/low-tyramine-diet-for-individuals-with-headache-or-migraine/](https://headaches.org/resources/low-tyramine-diet-for-individuals-with-headache-or-migraine/)  
10. A List of Common Foods That Can Trigger Migraines \- Verywell Health, 访问时间为 二月 1, 2026， [https://www.verywellhealth.com/migraine-trigger-food-list-5206708](https://www.verywellhealth.com/migraine-trigger-food-list-5206708)  
11. Clinical study protocol template, 访问时间为 二月 1, 2026， [https://cdn.clinicaltrials.gov/large-docs/14/NCT04084314/Prot\_000.pdf](https://cdn.clinicaltrials.gov/large-docs/14/NCT04084314/Prot_000.pdf)  
12. ResearchKit Active Tasks List \- TrialX, 访问时间为 二月 1, 2026， [https://trialx.com/researchkit-active-tasks-list/](https://trialx.com/researchkit-active-tasks-list/)  
13. Painometer \- Apps on Google Play, 访问时间为 二月 1, 2026， [https://play.google.com/store/apps/details?id=com.algos.painometerv3\&hl=en\_US](https://play.google.com/store/apps/details?id=com.algos.painometerv3&hl=en_US)  
14. Comparison of a Mobile Health Electronic Visual Analog Scale App With a Traditional Paper Visual Analog Scale for Pain Evaluation: Cross-Sectional Observational Study, 访问时间为 二月 1, 2026， [https://pmc.ncbi.nlm.nih.gov/articles/PMC7530698/](https://pmc.ncbi.nlm.nih.gov/articles/PMC7530698/)  
15. Outcomes Among Patients With Episodic Migraine | JPR \- Dove Medical Press, 访问时间为 二月 1, 2026， [https://www.dovepress.com/real-world-treatment-patterns-and-outcomes-among-patients-with-episodi-peer-reviewed-fulltext-article-JPR](https://www.dovepress.com/real-world-treatment-patterns-and-outcomes-among-patients-with-episodi-peer-reviewed-fulltext-article-JPR)  
16. Migraine Buddy | Your Personal Migraine Tracking App, 访问时间为 二月 1, 2026， [https://migrainebuddy.com/](https://migrainebuddy.com/)  
17. Migraine Buddy: Track Headache \- App Store \- Apple, 访问时间为 二月 1, 2026， [https://apps.apple.com/us/app/migraine-buddy-track-headache/id975074413](https://apps.apple.com/us/app/migraine-buddy-track-headache/id975074413)  
18. Four Apps for Dealing with Migraines \- Maryland Pain & Wellness Center, 访问时间为 二月 1, 2026， [https://www.marylandpainandwellnesscenter.com/blog/four-apps-for-dealing-with-migraines](https://www.marylandpainandwellnesscenter.com/blog/four-apps-for-dealing-with-migraines)  
19. Migraine Diary \- Brain Twin \- App Store \- Apple, 访问时间为 二月 1, 2026， [https://apps.apple.com/us/app/migraine-diary-brain-twin/id1492277360](https://apps.apple.com/us/app/migraine-diary-brain-twin/id1492277360)  
20. Get Started with WeatherKit \- Apple Developer, 访问时间为 二月 1, 2026， [https://developer.apple.com/weatherkit/](https://developer.apple.com/weatherkit/)  
21. Free Visual analog scale pain vas Icons, Symbols, Pictures, and Images | Mind the Graph, 访问时间为 二月 1, 2026， [https://mindthegraph.com/illustrations/visual-analog-scale-pain-vas](https://mindthegraph.com/illustrations/visual-analog-scale-pain-vas)  
22. An Improved Digital Pain Body Map \- SciSpace, 访问时间为 二月 1, 2026， [https://scispace.com/pdf/an-improved-digital-pain-body-map-30u5etowif.pdf](https://scispace.com/pdf/an-improved-digital-pain-body-map-30u5etowif.pdf)  
23. Migraine management in Chinese headache centers: a national survey and the role of quality control inspections \- PubMed Central, 访问时间为 二月 1, 2026， [https://pmc.ncbi.nlm.nih.gov/articles/PMC12659503/](https://pmc.ncbi.nlm.nih.gov/articles/PMC12659503/)  
24. Patient Headache Diary \- Mayo Clinic Health System, 访问时间为 二月 1, 2026， [https://www.mayoclinichealthsystem.org/-/media/national-files/documents/hometown-health/2019/headache-diary.pdf?sc\_lang=en\&hash=4AEEAAAB5E6EA9A27F7F43A11D5B40F1](https://www.mayoclinichealthsystem.org/-/media/national-files/documents/hometown-health/2019/headache-diary.pdf?sc_lang=en&hash=4AEEAAAB5E6EA9A27F7F43A11D5B40F1)  
25. Keeping a headache diary \- The Migraine Trust, 访问时间为 二月 1, 2026， [https://migrainetrust.org/live-with-migraine/self-management/keeping-a-migraine-diary/](https://migrainetrust.org/live-with-migraine/self-management/keeping-a-migraine-diary/)  
26. Setting Up Core Data with CloudKit | Apple Developer Documentation, 访问时间为 二月 1, 2026， [https://developer.apple.com/documentation/CoreData/setting-up-core-data-with-cloudkit](https://developer.apple.com/documentation/CoreData/setting-up-core-data-with-cloudkit)  
27. Core Data with CloudKit \- The Basics \- Fatbobman's Blog, 访问时间为 二月 1, 2026， [https://fatbobman.com/en/posts/coredatawithcloudkit-1/](https://fatbobman.com/en/posts/coredatawithcloudkit-1/)  
28. headache | Apple Developer Documentation, 访问时间为 二月 1, 2026， [https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/headache](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/headache)  
29. HKCategoryTypeIdentifierHeada, 访问时间为 二月 1, 2026， [https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/headache?changes=\_8\&language=objc](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/headache?changes=_8&language=objc)  
30. objc2\_health\_kit \- Rust \- Docs.rs, 访问时间为 二月 1, 2026， [https://docs.rs/objc2-health-kit/](https://docs.rs/objc2-health-kit/)