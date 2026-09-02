# YuiTodo

一款使用 Flutter 开发的精美任务管理应用。

## 功能特性

- **任务管理**：创建、编辑、删除、完成任务
- **子任务**：支持添加子任务，独立完成任务（不触发编辑弹窗）
- **标签系统**：替代分组，支持多维度筛选
- **智能列表**：今天/明天/未来/全部/已完成
- **搜索过滤**：标题/备注搜索 + 标签筛选
- **拖拽排序**：长按拖拽调整任务顺序
- **多选操作**：批量删除/批量打标签
- **滑动手势**：左滑删除（带撤销），右滑完成
- **撤销操作**：删除/完成后 5 秒内可撤销
- **循环任务**：日/周/月/年/自定义间隔
- **提醒通知**：本地通知，支持多时间点
- **导入导出**：JSON 格式备份恢复
- **统计面板**：完成率/趋势图/年度热力图
- **主题系统**：浅色/深色/跟随系统
- **28 个预置图标**：动漫风格头像图标

## 技术栈

- **语言**：Dart 3.x
- **UI 框架**：Flutter 3.x (Material 3 + Cupertino)
- **状态管理**：Riverpod
- **数据库**：sqflite (SQLite)
- **路由**：go_router
- **通知**：flutter_local_notifications
- **测试**：flutter_test + mockito
- **CI/CD**：GitHub Actions

## 项目结构

```
lib/
├── main.dart                    # 入口
├── app.dart                     # MaterialApp 配置
├── core/                        # 核心基础设施
│   ├── database/                # 数据库
│   ├── theme/                   # 主题系统
│   ├── icons/                   # 图标系统
│   └── utils/                   # 工具函数
├── models/                      # 数据模型
├── providers/                   # Riverpod 状态管理
├── repositories/                # 数据仓库
├── services/                    # 业务服务
├── statistics/                  # 统计计算
├── ui/                          # 界面层
│   ├── screens/                 # 页面
│   └── widgets/                 # 可复用组件
└── test/                        # 测试
```

## 开发

```bash
# 安装依赖
flutter pub get

# 运行测试
flutter test

# 构建 APK
flutter build apk --release
```

## License

MIT
