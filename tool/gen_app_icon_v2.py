#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
YuiTodo 应用图标生成脚本 v2（完整画框方案）
====================================================================

用途
----
把一张「带完整边框/画框」的方形源图（默认 /Users/yui/Downloads/new_icon.jpeg）
处理成 Android 启动器图标。

与 v1（gen_app_icon.py，透明抠图方案）的区别
--------------------------------------------
v1 针对的是「只有人物、白底」的图：靠泛洪抠掉白底得到透明背景的 cutout。
v2 针对的是「人物 + 完整装饰边框」的图：边框本身是设计的一部分，
**保留整幅画框**，只裁掉外侧一圈多余的白边，得到一张「实心方形卡片」图标。

为什么不用自适应图标(Adaptive Icon)
-----------------------------------
Android 8.0+ 的自适应图标要求 <background> 背景层不透明，会把整幅画框
裁进遮罩安全区，导致四角的花纹/宝石被切掉。所以这里沿用 v1 的结论：
    不使用 mipmap-anydpi-v26/，让系统回退到 mipmap-*/ic_launcher.png。

最终效果
--------
桌面/应用管理里显示一张完整的方形图标：金色花纹边框 + 四角绿宝石 +
中间人物与待办元素，背景为画框自带的白色。方形显示（不被裁圆）。

使用
----
    python3 tool/gen_app_icon_v2.py
（依赖 Pillow：pip install Pillow）

生成后固定流程（务必先卸载再安装，否则启动器缓存旧图标）：
    cd ~/Documents/GitHub/YuiTodo && flutter build apk --release
    adb uninstall com.yuitodo.yuitodo
    adb install build/app/outputs/flutter-apk/app-release.apk
"""

import os
import shutil
from PIL import Image

# ---------------------------------------------------------------------------
# 配置区
# ---------------------------------------------------------------------------

# 源图路径（正方形，越大越好，建议 >= 512x512）
SOURCE = "/Users/yui/Downloads/new_icon.jpeg"

# res 目录（脚本位于仓库 tool/ 下，向上两级到仓库根，再进 android/.../res）
RES_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "android", "app", "src", "main", "res",
)

# 外侧白边裁掉比例：源图四周约 48/1920 ≈ 2.5% 是纯白边。
# 留一点点余量，裁到画框外沿，避免白边进图标。
MARGIN_RATIO = 0.026

# 是否给整幅图标套圆角蒙版（Android 部分启动器会自己裁圆角，这里默认不裁）：
#   None      = 方形（推荐，完整显示画框）
#   "round"   = 圆形蒙版
#   "squircle"= 圆角方形蒙版
ROUND_MASK = None

# 圆角半径占比（仅 squircle 用）
SQUIRCLE_RADIUS = 0.20

# 各密度下图标边长（像素）。普通图标标准尺寸：mdpi=48dp 起。
DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def trim_white_border(img: Image.Image, ratio: float) -> Image.Image:
    """裁掉四周比例 ratio 的白边，返回居中裁切后的正方形。"""
    w, h = img.size
    mx = int(w * ratio)
    my = int(h * ratio)
    return img.crop((mx, my, w - mx, h - my))


def center_square(img: Image.Image) -> Image.Image:
    """非正方形时取中心正方形区域。"""
    w, h = img.size
    s = min(w, h)
    return img.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))


def apply_mask(img: Image.Image) -> Image.Image:
    """按 ROUND_MASK 给图标套圆角/圆形 alpha 蒙版（可选）。"""
    if ROUND_MASK is None:
        return img
    size = img.size[0]
    mask = Image.new("L", (size, size), 0)
    from PIL import ImageDraw
    d = ImageDraw.Draw(mask)
    if ROUND_MASK == "round":
        d.ellipse((0, 0, size, size), fill=255)
    elif ROUND_MASK == "squircle":
        r = int(size * SQUIRCLE_RADIUS)
        d.rounded_rectangle((0, 0, size, size), radius=r, fill=255)
    out = img.copy()
    out.putalpha(mask)
    return out


def main() -> None:
    src = Image.open(SOURCE).convert("RGBA")
    src = trim_white_border(src, MARGIN_RATIO)
    src = center_square(src)
    src = apply_mask(src)

    # 1) 各密度普通 PNG 图标（实心画框，完整显示）
    for name, size in DENSITIES.items():
        d = os.path.join(RES_DIR, f"mipmap-{name}")
        os.makedirs(d, exist_ok=True)
        icon = src.resize((size, size), Image.LANCZOS)
        icon.save(os.path.join(d, "ic_launcher.png"))
        icon.save(os.path.join(d, "ic_launcher_round.png"))

    # 2) 删除自适应图标目录 —— 关键！否则系统优先用它，画框四角被裁掉
    anydpi = os.path.join(RES_DIR, "mipmap-anydpi-v26")
    if os.path.exists(anydpi):
        shutil.rmtree(anydpi)
        print("已删除 mipmap-anydpi-v26/（改用实心画框 PNG）")

    print("图标已生成到:", RES_DIR)
    print("提醒：必须 adb uninstall 再 install，否则启动器显示缓存的旧图标。")


if __name__ == "__main__":
    main()
