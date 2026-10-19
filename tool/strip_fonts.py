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
    if not os.path.isdir(path):
        log("assets/fonts/ already absent")
        return
    # Keep assets/fonts/open/ (the OFL fonts that both versions ship);
    # only the proprietary root font files are removed.
    removed = 0
    for entry in os.listdir(path):
        full = os.path.join(path, entry)
        if os.path.isfile(full):
            os.remove(full)
            removed += 1
    log(f"deleted {removed} proprietary root fonts (kept assets/fonts/open/)")


def strip_proprietary_font_pairs():
    """Remove the proprietary font entries from font_pairs.dart.

    The opensource build keeps the font picker (AppFontPairs / font_state), but
    only the open-source fonts remain in the catalog.
    """
    path = os.path.join(ROOT, "lib", "core", "theme", "font_pairs.dart")
    with open(path, encoding="utf-8") as f:
        s = f.read()
    marker = "    // ---- Proprietary fonts (full build only) ----"
    start = s.find(marker)
    if start == -1:
        log("font_pairs.dart has no proprietary marker; leaving as is")
        return
    end = s.find("  ];", start)
    if end == -1:
        die("could not find the end of the font_pairs list")
    s = s[:start] + s[end:]
    with open(path, "w", encoding="utf-8") as f:
        f.write(s)
    log("font_pairs.dart -> open-source fonts only (picker kept)")


def edit_pubspec():
    path = os.path.join(ROOT, "pubspec.yaml")
    with open(path, encoding="utf-8") as f:
        s = f.read()
    open_fonts = """  fonts:
    - family: SourceHanSansSC
      fonts:
        - asset: assets/fonts/open/SourceHanSansSC-Regular.otf
    - family: SmileySans
      fonts:
        - asset: assets/fonts/open/SmileySans-Oblique.ttf
    - family: LXGWWenKaiLite
      fonts:
        - asset: assets/fonts/open/LXGWWenKaiLite-Regular.ttf
    - family: IBMPlexSansSC
      fonts:
        - asset: assets/fonts/open/IBMPlexSansSC-Regular.ttf
    - family: IBMPlexMono
      fonts:
        - asset: assets/fonts/open/IBMPlexMono-Regular.ttf
"""
    if "\n  fonts:" in s:
        s = s[: s.index("\n  fonts:")].rstrip() + "\n" + open_fonts
        with open(path, "w", encoding="utf-8") as f:
            f.write(s)
        log("pubspec.yaml fonts -> opensource OFL fonts only")
    else:
        log("pubspec.yaml has no fonts block")


def edit_main_dart():
    log("main.dart kept (font picker/logic shared by both builds)")


def edit_settings_screen():
    log("settings font picker kept (open fonts in both builds)")


def edit_gitignore():
    path = os.path.join(ROOT, ".gitignore")
    with open(path, encoding="utf-8") as f:
        s = f.read()
    if "assets/fonts/*.ttf" not in s:
        s = s.rstrip() + "\n\nassets/fonts/*.ttf\n"
        with open(path, "w", encoding="utf-8") as f:
            f.write(s)
        log("added assets/fonts/*.ttf to .gitignore (keeps open/)")
    else:
        log(".gitignore already ignores proprietary root fonts")


def main():
    if not os.path.exists(os.path.join(ROOT, "pubspec.yaml")):
        die("run this from the repository root")
    remove_font_assets()
    strip_proprietary_font_pairs()
    edit_pubspec()
    edit_main_dart()
    edit_settings_screen()
    edit_gitignore()
    log("done. Review with `git status` then commit.")


if __name__ == "__main__":
    main()
