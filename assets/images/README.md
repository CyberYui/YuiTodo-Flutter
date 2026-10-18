# Calendar background artwork

把背景图放在本目录，并命名为 `calendar_bg.png`，即可自动作为日历页头部背景。
如果文件不存在，日历会自动回退到主题渐变，不会报错。

## 规格

| 项目 | 建议值 |
|------|--------|
| 尺寸 | **1240 × 1600 px**（竖图，宽高比约 0.775） |
| 格式 | PNG / WebP，sRGB |
| 视觉重心 | 上方 60%（日历网格区域） |
| 底部 40% | 会被主题渐变遮罩覆盖，并与任务列表自然衔接 |
| 边缘 | 小屏会居中裁剪，重要元素不要贴边 |

## 替换方式

1. 将图片命名为 `calendar_bg.png` 放入本目录。
2. `flutter pub get` / 重新构建即可；代码里的 `CalendarBackground.assetPath` 已指向该文件。
3. 如需临时关闭背景图，把 `lib/core/theme/calendar_background.dart` 里的
   `CalendarBackground.enabled` 改为 `false`。
