# YuiTodo

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-4.9.0-blue)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Build](https://img.shields.io/badge/Build-Passing-brightgreen)

**一款使用 Flutter 开发、纯本地、无账号的任务管理应用**

[下载 APK](https://github.com/CyberYui/YuiTodo-Flutter/releases) · [功能介绍](#功能介绍) · [如何使用](#如何使用) · [开发](#开发)

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

## 🆕 v4.9.0 新变化

- **日历背景图**：内置 1240×1600 云层背景（顶部显示、向下渐隐到任务列表），与日历配色融合。
- **更紧凑的 UI**：首页分区标题、任务卡、设置项、编辑器再次收紧；日期选择去掉图标，日期文字获得更多空间。
- **全局搜索**：首页菜单 →「搜索全部任务」，或搜索框右侧入口；支持标题/备注/子任务/标签，包含已完成任务。
- **通知体验**：完成/稍后动作增加图标，新增「稍后 1 小时」；动作图标与铃声加入 release 资源保留规则。
- **数据修复**：设置 → 数据管理 →「修复孤立数据」，可从误删遗留的子任务/历史恢复任务。

> 历史版本更新内容见 [Releases](https://github.com/CyberYui/YuiTodo-Flutter/releases)。

---

## ✨ 功能介绍

### 核心功能

| 功能 | 描述 |
|------|------|
| 📝 任务管理 | 创建、编辑、删除、完成任务，支持富文本备注 |
| ✅ 子任务 | 独立勾选完成，支持拖拽排序，超过 3 个折叠；重复任务按次隔离 |
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
| 🔤 开源字体 | 思源黑体 / 得意黑 / 霞鹜文楷 / IBM Plex（SIL OFL 1.1）；两版均可在设置中切换，完整版另有版权字体 |
| 🔔 智能提醒 | 精确闹钟 + 自动回退机制，确保提醒准时送达 |
| ♻️ 删除与恢复 | 软删除进回收站；顶部横幅「撤销」或回收站「恢复」均可即时还原 |
| 🧭 示例数据 | 首次安装自动生成示例任务/习惯，作为内置使用说明 |

### 主题系统

| 浅色主题 | 深色主题 |
|----------|----------|
| 默认蓝 | 默认蓝 |
| 森林绿 | 森林绿 |
| 紫罗兰 | 紫罗兰 |
| 日落橙 | 日落橙 |
| Monokai | Monokai |
| Dracula | Dracula |
| Nord | Nord |
| Gruvbox | Gruvbox |
| 纯黑 | 纯黑 |

支持**跟随系统**自动切换，或**定时切换**（自定义时间段）。

---

## 🚀 如何使用

### 系统要求

- Android 7.0+ (API 24+)
- 约 100MB（开源版）/ 130MB（完整版）存储空间

### 安装方法

1. 前往 [Releases](https://github.com/CyberYui/YuiTodo-Flutter/releases) 页面
2. 下载最新版本的 `YuiTodo-vX.X.X.apk`（当前为 `YuiTodo-v4.9.0.apk`）
3. 在 Android 设备上安装
4. 允许"未知来源"安装权限

> **字体说明**
> 内置思源黑体/得意黑/霞鹜文楷/IBM Plex（SIL OFL 1.1），设置中可切换。当前版本 **v4.9.0**。

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
│   ├── main.dart                    # 应用入口
│   ├── core/                        # 核心基础设施
│   │   ├── database/                # 数据库初始化和迁移、示例数据
│   │   ├── date/                    # 日期工具与虚拟实例查询引擎
│   │   ├── icons/                   # 图标系统和映射
│   │   ├── theme/                   # 主题、字体、配色
│   │   └── utils/                   # 循环计算、提醒调度、撤销管理
│   ├── models/                      # 数据模型（Task/Tag/TaskStep/Occurrence）
│   ├── providers/                   # Riverpod 状态管理
│   ├── repositories/                # 数据仓库（CRUD 操作）
│   ├── services/                    # 业务服务（备份/通知）
│   ├── statistics/                  # 统计计算逻辑
│   └── ui/                          # 界面层
│       ├── screens/                 # 页面（首页/全局搜索/日历/专注/习惯/设置/统计/回收站/任务编辑）
│       └── widgets/                 # 可复用组件（任务卡片/图标选择器/循环选择器/提醒选择器）
├── assets/
│   ├── icons/                       # 二次元头像图标（28 个 PNG）
│   ├── images/                      # 日历背景图（1240×1600）
│   └── fonts/                       # 自定义字体文件（仅完整版）
├── .github/
│   ├── images/                      # README 截图展示
│   └── workflows/                   # CI/CD 配置
├── test/                            # 单元测试和 Widget 测试
├── tool/                            # 构建辅助脚本（字体剥离等）
├── pubspec.yaml                     # 依赖配置
└── README.md                        # 项目文档
```

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
| `main` | 唯一主分支，开源版 | `4.9.0` |

项目为单分支模式，所有开发均在 `main` 上进行。

---

## 📄 License

本项目基于 [MIT](LICENSE) 许可证开源。

---

<div align="center">

**如果觉得这个项目有用，请给一个 ⭐ Star！**

Made with ❤️ by [CyberYui](https://github.com/CyberYui)

</div>
