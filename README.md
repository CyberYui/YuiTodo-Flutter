# YuiTodo

<div align="center">

<img src=".github/images/icon.png" alt="YuiTodo 图标" width="96" height="96" style="border-radius:20%">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-4.9.2-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Build](https://img.shields.io/badge/Build-Passing-brightgreen)

**一款使用 Flutter 开发、纯本地、无账号的任务管理应用**

[下载 APK](https://github.com/CyberYui/YuiTodo-Flutter/releases) · [功能介绍](#功能介绍) · [如何使用](#如何使用) · [开发](#开发) · [主题配色](#主题系统)

<!-- 截图展示区 -->
<table align="center">
<tr>
<td align="center"><img src=".github/images/main.png" width="200" alt="主页分区"><br/><b>主页分区</b></td>
<td align="center"><img src=".github/images/info.png" width="200" alt="任务编辑"><br/><b>任务编辑</b></td>
<td align="center"><img src=".github/images/hoti.png" width="200" alt="统计面板"><br/><b>统计面板</b></td>
</tr>
<tr>
<td align="center"><img src=".github/images/calendar.png" width="200" alt="日历视图"><br/><b>日历视图</b></td>
<td align="center"><img src=".github/images/focus.png" width="200" alt="专注模式"><br/><b>专注模式</b></td>
<td align="center"><img src=".github/images/habit.png" width="200" alt="习惯追踪"><br/><b>习惯追踪</b></td>
</tr>
</table>

</div>

---

## 📖 设计背景

YuiTodo 诞生于对现有任务管理工具的不满：要么功能过于复杂，要么设计过于简陋。我在深度使用 Sorted 软件之后，发现 Android 平台上并没有类似的追求**简约而不简单**的设计理念应用，因此借助当今火热的 AI 工具，打造了一款自用的任务管理应用，它遵循下面几个特点：

- **视觉舒适**：iOS + Notion 混合风格，低对比度柔和配色
- **操作流畅**：手势优先，减少点击层级
- **功能完备**：覆盖任务管理的核心场景，无冗余功能
- **隐私优先**：纯本地存储，零网络请求，无账号、无云同步

---

## 🆕 版本变化

<details>
<summary><b>v4.9.2（当前版本）</b> — 点击展开</summary>

- **全新应用图标**：采用全新设计的方形图标（金色花纹边框 + 四角绿宝石 + 蓝发角色与待办元素），更贴合应用气质。
- **文档完善**：README 徽章展示图标、版本变化默认折叠、主题系统补充主要配色与十六进制色值、新增「可自定义内容」与「开放接口与数据」章节。

</details>

<details>
<summary><b>v4.9.1</b> — 点击展开</summary>

- **批量删除更可靠**：多选删除后列表立即刷新、写入回收站，并显示可撤销横幅；撤销会恢复整批任务。
- **回收站批量操作**：进入即刷新，支持全选、批量恢复、批量永久删除与清空；右上角改为带文字说明的操作菜单。
- **子任务完成**：重复任务可在详情页直接勾选「今天」的子任务；任务卡可展开查看并勾选全部子任务。
- **快速添加更清晰**：输入框增加薄描边，并常驻提示「点铅笔进入详细编辑（日期、标签、提醒、子任务）」。
- **每周起始日联动**：切换周一/周日会同步影响日历排列、统计周分组、热力图和习惯「本周」进度。
- 继承 v4.9.0 的日历背景图、全局搜索、紧凑 UI、通知动作图标与孤立数据修复。

</details>

<details>
<summary><b>v4.9.0</b> — 点击展开</summary>

- **日历背景图**：支持在日历头部使用自定义背景图（推荐 1240×1600 竖版）。
- **全局搜索**：新增全局搜索页，可搜索标题、备注、子任务与标签。
- **紧凑 UI**：整体布局更紧凑，小屏设备顶栏只保留「搜索 / 筛选 / 更多」。
- **通知动作图标**：完成 / 稍后提醒通知按钮带独立图标。
- **孤立数据修复**：修复历史硬删除遗留的孤立子任务/标签/历史数据。

</details>

> 更多历史版本更新内容见 [Releases](https://github.com/CyberYui/YuiTodo-Flutter/releases)。

---

## ✨ 功能介绍

### 核心功能

| 功能 | 描述 |
|------|------|
| 📝 任务管理 | 创建、编辑、删除、完成任务，支持富文本备注 |
| ✅ 子任务 | 独立勾选完成，支持拖拽排序；超过 3 个可展开查看；重复任务按天隔离 |
| 🏷️ 标签系统 | 替代分组，多维度筛选，自定义颜色和字体颜色 |
| 🔍 搜索 | 全局搜索：标题、备注、子任务、标签；含已完成任务 |
| 📅 日期管理 | 开始/结束日期，日历选择器 |
| 🎨 颜色标记 | 16 色调色板 + 自定义 RGB 取色器 |
| 📌 图标标记 | 200+ 图标库，支持二次元头像 |
| 🔄 循环任务 | 日/周/月/年/自定义间隔，虚拟实例渲染 |
| ⏰ 提醒通知 | 本地通知；定时提醒 + 最多 5 个提前提醒；每任务独立铃声；自定义通知布局 |
| 📆 日历视图 | 月历打点、按日查看任务、直接完成子任务；支持周起始日（周一/周日）与自定义背景图（1240×1600） |
| 🍅 专注模式 | 番茄钟 / 正计时、暂停、休息、专注记录 |
| 🔥 习惯追踪 | 打卡、连续天数、本周进度、7/30/90 天网格 |
| 📊 统计面板 | 多时间范围、完成率、子任务、热力图、连续打卡、标签/星期/月份分布 |
| 🗑️ 回收站 | 软删除，支持恢复和永久删除 |
| 💾 数据导入导出 | JSON 格式备份恢复 |
| 🎨 主题持久化 | 主题模式、浅色/深色方案、定时切换自动保存，重启后恢复 |
| 🔤 开源字体 | 思源黑体 / 得意黑 / 霞鹜文楷 / IBM Plex（SIL OFL 1.1）；可在设置中切换 |
| 🔔 智能提醒 | 精确闹钟 + 自动回退机制，确保提醒准时送达 |
| ♻️ 删除与恢复 | 软删除进回收站；顶部横幅「撤销」或回收站「恢复」均可即时还原 |
| 🧭 示例数据 | 首次安装自动生成示例任务/习惯，作为内置使用说明 |

### 主题系统

共 **9 套配色方案**，每套均含浅色与深色两套，可分别指定；支持**跟随系统**自动切换，或**定时切换**（自定义深色时段的开始/结束时间）。

| 方案 | 浅色主色 | 深色主色 | 风格 |
|------|----------|----------|------|
| 默认蓝 | `#3B82F6` | `#60A5FA` | 清爽通用 |
| 森林绿 | `#10B981` | `#34D399` | 自然柔和 |
| 紫罗兰 | `#8B5CF6` | `#A78BFA` | 优雅梦幻 |
| 日落橙 | `#F59E0B` | `#FBBF24` | 温暖活力 |
| Monokai | `#A6E22E` | `#A6E22E` | 代码编辑器风 |
| Dracula | `#FF79C6` | `#FF79C6` | 霓虹粉紫 |
| Nord | `#81A1C1` | `#81A1C1` | 北欧冷色 |
| Gruvbox | `#B16286` | `#D3869B` | 复古暖色 |
| 纯黑 | `#1A1A1A` | `#E0E0E0` | 极简黑白 |

**主要配色与十六进制色值**

以默认蓝（浅色）为例，展示各语义角色的取值：

| 角色 | 浅色 | 深色 |
|------|------|------|
| 主色 Primary | `#3B82F6` | `#60A5FA` |
| 次色 Secondary | `#60A5FA` | `#3B82F6` |
| 页面背景 | `#F8FAFC` | `#0F172A` |
| 卡片表面 | `#FFFFFF` | `#1E293B` |
| 顶栏背景 | `#E8F0FE` | `#1E293B` |
| 正文文字 | `#1A1A1A` | `#FFFFFF` |
| 分割线 | `#E0E0E0` | `#404040` |

> 配色定义见 `lib/core/theme/theme_schemes.dart`，主题模式与定时切换逻辑见 `lib/core/theme/theme_state.dart`。

**任务颜色**：内置 16 色调色板（`#3B82F6` 蓝、`#EF4444` 红、`#10B981` 绿、`#F59E0B` 琥珀、`#EC4899` 粉、`#06B6D4` 青、`#F97316` 橙、`#6366F1` 靛、`#84CC16` 柠檬、`#D946EF` 紫红、`#64748B` 石板、`#78716C` 暖灰、`#F43F5E` 玫红、`#000000` 黑、`#FFFFFF` 白），另支持自定义 RGB 取色器。

---

## 🚀 如何使用

### 系统要求

- Android 7.0+ (API 24+)
- 约 100MB 存储空间

### 安装方法

1. 前往 [Releases](https://github.com/CyberYui/YuiTodo-Flutter/releases) 页面
2. 下载最新版本的 `YuiTodo-vX.X.X.apk`（当前为 `YuiTodo-v4.9.2.apk`）
3. 在 Android 设备上安装
4. 允许"未知来源"安装权限

> **字体说明**
> 内置思源黑体 / 得意黑 / 霞鹜文楷 / IBM Plex（SIL OFL 1.1），可在设置中切换。当前版本 **v4.9.2**。

### 快速开始

1. **查看示例**：首次安装会自动生成一组示例任务与习惯，可直接当作使用说明；删除后不会再次出现。
2. **创建任务**：点击右下角 `+` 按钮。
3. **手势操作**：左滑任务 → 星标；右滑任务 → 完成；长按任务 → 多选。
4. **打开功能**：右上角 `⋮` → 搜索全部任务 / 日历 / 专注 / 统计 / 设置。
5. **习惯打卡**：右上角 `⋮` → 设置 → 功能 → 习惯打卡。
6. **切换主题**：设置 → 外观 → 主题模式。
7. **搜索任务**：主界面点击搜索图标。

> 小屏设备上顶栏只保留「搜索 / 筛选 / 更多」，其余入口在「更多」菜单中。

---

## 🛠️ 开发

### 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | Dart 3.x |
| UI 框架 | Flutter 3.x (Material 3) |
| 状态管理 | Riverpod |
| 数据库 | sqflite (SQLite) |
| 通知 | flutter_local_notifications |
| 测试 | flutter_test |
| CI/CD | GitHub Actions |

### 项目结构

```
YuiTodo-Flutter/
├── lib/
│   ├── main.dart                    # 应用入口（Prefs 加载、示例数据、提醒重排）
│   ├── core/                        # 核心基础设施
│   │   ├── database/                # 数据库初始化、14 版迁移、示例数据
│   │   ├── date/                    # 日期工具（startOfWeek/ymdKey）与虚拟实例查询引擎
│   │   ├── icons/                   # 图标系统（28 头像 + 200+ 扁平图标映射）
│   │   ├── notifications/           # 提醒铃声目录与试听
│   │   ├── storage/                 # SharedPreferences 设置封装
│   │   ├── theme/                   # 主题、9 套配色、字体对、任务色板
│   │   └── utils/                   # 循环计算、提醒调度、撤销管理、手动排序
│   ├── models/                      # 数据模型（Task/Tag/TaskStep/RecurrenceRule/Occurrence/FocusSession）
│   ├── providers/                   # Riverpod 状态管理（10 个 provider）
│   ├── repositories/                # 数据仓库（TaskRepository 统一 CRUD）
│   ├── services/                    # 业务服务（备份导入导出/通知/使用统计）
│   ├── statistics/                  # 统计计算逻辑
│   └── ui/                          # 界面层
│       ├── screens/                 # 页面（首页/全局搜索/日历/专注/习惯/设置/统计/回收站/任务编辑/标签管理/通知设置/字体许可）
│       └── widgets/                 # 可复用组件（任务卡片/图标选择器/循环选择器/提醒选择器/习惯网格/统计组件）
├── assets/
│   ├── icons/                       # 二次元头像图标（28 个 PNG）
│   ├── images/                      # 日历背景图（1240×1600）
│   └── fonts/open/                  # 开源字体（SIL OFL 1.1）
├── android/app/src/main/res/        # 启动器图标（各密度 mipmap）
├── .github/
│   ├── images/                      # README 截图与图标展示
│   └── workflows/                   # CI/CD 配置
├── test/                            # 单元测试和 Widget 测试
├── tool/                            # 构建辅助脚本（图标生成等）
├── pubspec.yaml                     # 依赖配置
└── README.md                        # 项目文档
```

### 可自定义内容

| 自定义项 | 方式 | 位置 |
|----------|------|------|
| 主题配色 | 9 套方案（浅/深分别设置） | 设置 → 外观 |
| 定时深色 | 自定义深色时段 | 设置 → 外观 → 定时自动切换 |
| 字体 | 6 种字体对（含系统默认） | 设置 → 外观 → 字体 |
| 每周起始日 | 周一 / 周日 | 设置 → 日历 |
| 任务颜色 | 16 色调色板 + 自定义 RGB | 任务编辑 → 颜色 |
| 任务图标 | 28 头像 + 200+ 扁平图标 | 任务编辑 → 图标 |
| 提醒铃声 | 6 种（跟随系统/清脆/弹跳/铃铛/电子/轻柔） | 任务编辑 → 提醒 / 通知设置 |
| 日历背景图 | 替换 `assets/images/calendar_bg.jpg` | 需重新打包 |
| 应用图标 | 替换 `android/app/src/main/res/mipmap-*/` | 需重新打包 |
| 示例数据 | 首次安装自动生成（可删除） | 自动 |

> **开发者自定义**：日历背景图与应用图标为资源文件，替换后重新打包即可生效；详见 `tool/gen_app_icon_v2.py` 与 `lib/core/theme/calendar_background.dart`。

### 本地开发

```bash
# 克隆仓库
git clone https://github.com/CyberYui/YuiTodo-Flutter.git
cd YuiTodo-Flutter

# 安装依赖
flutter pub get

# 运行应用
flutter run

# 运行测试
flutter test

# 构建 APK
flutter build apk --release
```

### 分支约定

| 分支 | 内容 | 版本 |
|------|------|------|
| `main` | 唯一主分支，开源版 | `4.9.2` |

项目为单分支模式，所有开发均在 `main` 上进行。

### 开放接口与数据

本项目以 MIT 许可开源，所有接口均为**进程内 Dart 接口**，无网络服务、无账号体系。主要开放点：

| 接口 | 说明 | 位置 |
|------|------|------|
| 数据仓库 | `TaskRepository` 提供任务/标签/子任务/循环/专注/提醒的统一 CRUD | `lib/repositories/task_repository.dart` |
| 状态管理 | 10 个 Riverpod Provider（任务、标签、回收站、日历、专注、习惯、筛选、分区、周起始、循环） | `lib/providers/` |
| 统计计算 | `StatisticsCalculator.calculate()` 纯函数，输入任务列表输出统计结果 | `lib/statistics/statistics_calculator.dart` |
| 循环引擎 | `RecurrenceCalculator.occurrencesBetween()` 纯函数，规则 → 日期列表 | `lib/core/utils/recurrence.dart` |
| 备份格式 | JSON（`formatVersion = 2`），含全部表数据，可跨设备导入导出 | `lib/services/backup_service.dart` |
| 主题配色 | 9 套 `ThemeScheme`，可扩充新方案 | `lib/core/theme/theme_schemes.dart` |
| 字体对 | `AppFontPairs.pairs` 可扩展新字体 | `lib/core/theme/font_pairs.dart` |
| 图标系统 | `AppIcons` + `FlatIconMapper` 可扩展图标 | `lib/core/icons/` |

> 备份 JSON 字段：`tasks`、`tags`、`taskTags`、`steps`、`stepOccurrences`、`occurrences`、`recurrenceRules`、`taskReminders`、`focusSessions`、`focusRestSegments`。

---

## 📄 License

本项目基于 [MIT](LICENSE) 许可证开源。

---

<div align="center">

**如果觉得这个项目有用，请给一个 ⭐ Star！**

Made with ❤️ by [CyberYui](https://github.com/CyberYui)

</div>
