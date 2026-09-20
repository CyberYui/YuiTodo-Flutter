# YuiTodo

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-3.1.5-blue)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Build](https://img.shields.io/badge/Build-Passing-brightgreen)

**一款使用 Flutter 开发的精美任务管理应用**

[下载 APK](https://github.com/CyberYui/YuiTodo-Flutter/releases) · [功能介绍](#功能介绍) · [如何使用](#如何使用) · [开发文档](#开发)

<!-- TODO: 截图位置 1 - 主界面截图 -->
<!-- 请在此处放置主界面截图，展示任务列表和标签筛选 -->
<!-- 建议尺寸: 300x600 像素 -->

</div>

---

## 📖 设计背景

YuiTodo 诞生于对现有任务管理工具的不满：要么功能过于复杂，要么设计过于简陋。我在深度使用Sorted软件之后，发现Android平台上并没有类似的追求**简约而不简单**的设计理念应用，因此借助当今火热的AI工具，打造了一款自用的任务管理应用，它遵循下面几个特点：

- **视觉舒适**：iOS + Notion 混合风格，低对比度柔和配色
- **操作流畅**：手势优先，减少点击层级
- **功能完备**：覆盖任务管理的核心场景，无冗余功能
- **隐私优先**：纯本地存储，零网络请求

---

## ✨ 功能介绍

### 核心功能

| 功能 | 描述 |
|------|------|
| 📝 任务管理 | 创建、编辑、删除、完成任务，支持富文本备注 |
| ✅ 子任务 | 独立勾选完成，支持拖拽排序，超过 3 个折叠 |
| 🏷️ 标签系统 | 替代分组，多维度筛选，自定义颜色和字体颜色 |
| 🔍 智能搜索 | 标题、备注、子任务全文搜索 |
| 📅 日期管理 | 开始/结束日期，日历选择器 |
| 🎨 颜色标记 | 16 色调色板 + 自定义 RGB 取色器 |
| 📌 图标标记 | 200+ 图标库，支持二次元头像 |
| 🔄 循环任务 | 日/周/月/年/自定义间隔 |
| ⏰ 提醒通知 | 本地通知，支持多时间点 |
| 🗑️ 回收站 | 软删除，支持恢复和永久删除 |
| 📊 统计面板 | 完成率、趋势图、年度热力图 |
| 💾 数据导入导出 | JSON 格式备份恢复 |

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

- Android 5.0+ (API 21+)
- 约 100MB 存储空间

### 安装方法

1. 前往 [Releases](https://github.com/CyberYui/YuiTodo-Flutter/releases) 页面
2. 下载最新版本的 `YuiTodo-vx.x.x-opensource.apk`
3. 在 Android 设备上安装
4. 允许"未知来源"安装权限

### 快速开始

1. **创建任务**：点击右下角 + 按钮
2. **添加标签**：进入设置 → 管理标签
3. **切换主题**：进入设置 → 外观 → 主题模式
4. **搜索任务**：在主界面点击搜索图标
5. **查看统计**：在主界面点击统计图标

<!-- TODO: 截图位置 2 - 任务编辑界面截图 -->
<!-- 请在此处放置任务编辑界面截图，展示颜色/图标/标签选择 -->
<!-- 建议尺寸: 300x600 像素 -->

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
│   │   ├── database/                # 数据库初始化和迁移
│   │   ├── icons/                   # 图标系统和映射
│   │   ├── theme/                   # 主题、字体、配色
│   │   └── utils/                   # 循环计算、撤销管理
│   ├── models/                      # 数据模型（Task/Tag/TaskStep）
│   ├── providers/                   # Riverpod 状态管理
│   ├── repositories/                # 数据仓库（CRUD 操作）
│   ├── services/                    # 业务服务（备份/通知）
│   ├── statistics/                  # 统计计算逻辑
│   └── ui/                          # 界面层
│       ├── screens/                 # 页面（首页/设置/统计/回收站/标签管理/任务编辑）
│       └── widgets/                 # 可复用组件（任务卡片/图标选择器/循环选择器/提醒选择器）
├── assets/
│   ├── icons/                       # 二次元头像图标（28 个 PNG）
│   └── fonts/                       # 自定义字体文件（完整版）
├── test/                            # 单元测试和 Widget 测试
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

<!-- TODO: 截图位置 3 - 统计面板截图 -->
<!-- 请在此处放置统计面板截图，展示完成率和趋势图 -->
<!-- 建议尺寸: 300x600 像素 -->

---

## 📄 License

本项目基于 [MIT](LICENSE) 许可证开源。

---

<div align="center">

**如果觉得这个项目有用，请给一个 ⭐ Star！**

Made with ❤️ by [CyberYui](https://github.com/CyberYui)

</div>
