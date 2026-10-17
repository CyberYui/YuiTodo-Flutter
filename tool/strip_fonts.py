#!/usr/bin/env python3
"""
strip_fonts.py — 从 full 分支工作树派生出开源版（无自定义字体）。

用法（在仓库根目录，且当前分支内容 = full）：
    python3 tool/strip_fonts.py

它只做"剥离字体切换功能"这一件事，不改变任何其他业务逻辑：
  1. 删除 assets/fonts/*.ttf
  2. 删除 lib/core/theme/font_pairs.dart / font_state.dart
  3. 移除 pubspec.yaml 的 fonts 声明
  4. 简化 lib/main.dart（不再应用自定义 TextTheme）
  5. 移除 lib/ui/screens/settings_screen.dart 的字体入口与选择器
  6. 把 assets/fonts/ 加入 .gitignore

幂等：重复执行不会报错（已剥离的步骤会跳过）。
"""

import os
import re
import shutil
import sys

ROOT = os.getcwd()


def log(msg):
    print(f"[strip_fonts] {msg}")


def die(msg):
    print(f"[strip_fonts] ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def remove_font_assets():
    path = os.path.join(ROOT, "assets", "fonts")
    if os.path.isdir(path):
        shutil.rmtree(path)
        log("deleted assets/fonts/")
    else:
        log("assets/fonts/ already absent")


def remove_font_code():
    for rel in ("lib/core/theme/font_pairs.dart", "lib/core/theme/font_state.dart"):
        path = os.path.join(ROOT, rel)
        if os.path.exists(path):
            os.remove(path)
            log(f"deleted {rel}")
        else:
            log(f"{rel} already absent")


def edit_pubspec():
    path = os.path.join(ROOT, "pubspec.yaml")
    with open(path, encoding="utf-8") as f:
        s = f.read()
    if "\n  fonts:" in s:
        s = s[: s.index("\n  fonts:")].rstrip() + "\n"
        with open(path, "w", encoding="utf-8") as f:
            f.write(s)
        log("removed fonts block from pubspec.yaml")
    else:
        log("pubspec.yaml has no fonts block")


def edit_main_dart():
    path = os.path.join(ROOT, "lib", "main.dart")
    with open(path, encoding="utf-8") as f:
        s = f.read()

    s = s.replace("import 'core/theme/font_pairs.dart';  // ← 导入字体配对系统\n", "")
    s = s.replace("import 'core/theme/font_state.dart';  // ← 字体索引（已持久化）\n", "")

    # If font logic is present, replace the whole build body with the simple one.
    if "fontIndexProvider" in s or "AppFontPairs" in s:
        start = s.find("  @override\n  Widget build(BuildContext context) {")
        end_marker = "\n}\n"
        # find the end of _YuiTodoAppState class (last occurrence of build's closing)
        # We replace from build start to the class closing brace before EOF.
        if start == -1:
            die("could not locate build() in main.dart")
        # The state class is the last class in the file.
        tail = s.rfind("\n}\n")
        if tail == -1:
            die("could not locate class end in main.dart")
        simple = '''  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeStateProvider);

    final lightScheme = themeSchemes[themeState.lightScheme];
    final darkScheme = themeSchemes[themeState.darkScheme];

    final baseLightTheme = lightScheme != null
        ? lightThemeForScheme(lightScheme)
        : lightTheme;
    final baseDarkTheme = darkScheme != null
        ? darkThemeForScheme(darkScheme)
        : darkTheme;

    return MaterialApp(
      title: 'YuiTodo',
      debugShowCheckedModeBanner: false,
      // Resolve system brightness + timed auto-switch into a concrete mode.
      themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: baseLightTheme,
      darkTheme: baseDarkTheme,
      home: const HomeScreen(),
    );
  }
'''
        s = s[:start] + simple + s[tail + 1 :]
        log("simplified main.dart (removed font TextTheme)")
    else:
        log("main.dart already has no font logic")

    with open(path, "w", encoding="utf-8") as f:
        f.write(s)


def edit_settings_screen():
    path = os.path.join(ROOT, "lib", "ui", "screens", "settings_screen.dart")
    with open(path, encoding="utf-8") as f:
        s = f.read()

    s = s.replace("import '../../core/theme/font_pairs.dart';\n", "")
    s = s.replace("import '../../core/theme/font_state.dart';\n", "")
    s = s.replace("    final fontIndex = ref.watch(fontIndexProvider);\n", "")

    tile = """          
          // Font
          // 字体选择入口：点击打开字体选择器弹窗
          ListTile(
            title: const Text('字体'),
            subtitle: Text(AppFontPairs.getPair(fontIndex).name),  // 显示当前选中的字体名称
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFontPicker(context, ref),  // 打开字体选择器
          ),
"""
    if tile in s:
        s = s.replace(tile, "\n")
        log("removed font tile from settings")
    else:
        log("settings font tile already absent")

    start = s.find("  /// 字体选择器弹窗")
    end = s.find("  Future<void> _showTimePicker")
    if start != -1 and end != -1 and end > start:
        s = s[:start] + s[end:]
        log("removed _showFontPicker method")
    else:
        log("_showFontPicker already absent")

    with open(path, "w", encoding="utf-8") as f:
        f.write(s)


def edit_gitignore():
    path = os.path.join(ROOT, ".gitignore")
    with open(path, encoding="utf-8") as f:
        s = f.read()
    if "assets/fonts/" not in s:
        s = s.rstrip() + "\n\nassets/fonts/\n"
        with open(path, "w", encoding="utf-8") as f:
            f.write(s)
        log("added assets/fonts/ to .gitignore")
    else:
        log(".gitignore already ignores assets/fonts/")


def main():
    if not os.path.exists(os.path.join(ROOT, "pubspec.yaml")):
        die("run this from the repository root")
    remove_font_assets()
    remove_font_code()
    edit_pubspec()
    edit_main_dart()
    edit_settings_screen()
    edit_gitignore()
    log("done. Review with `git status` then commit.")


if __name__ == "__main__":
    main()
