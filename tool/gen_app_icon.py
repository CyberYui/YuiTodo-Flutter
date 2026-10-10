#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
YuiTodo 应用图标生成脚本（透明背景方案）
====================================================================

用途
----
把一张方形源图（默认 /Users/yui/Downloads/square_icon.png）抠掉浅色背景，
生成「背景透明、主体铺满」的 Android 启动器图标，输出到
android/app/src/main/res/ 下。

最终效果（经模拟器实测验证）
----------------------------
桌面 / 应用管理 / 已安装应用列表里，图标 = 动漫人物主体，背景透出系统壁纸，
**没有黑底、没有白底、没有纯色方块**。

⚠️ 关键坑：为什么「不能用自适应图标(Adaptive Icon)」
-------------------------------------------------
Android 8.0+ 默认推荐自适应图标，但它有一个硬性限制：
    自适应图标的 <background> 背景层**不能透明**。
系统会把背景层强制铺满整个遮罩区（即使你放一张全透明的 PNG，
很多启动器也会把它当成「无背景」，转而铺一层不透明底色——实测在本机
模拟器上表现为**纯黑**）。这正是之前图标一直显示黑底的原因。

而「普通 PNG 图标」(mipmap/ic_launcher.png) 是支持逐像素 alpha 的：
只要 PNG 本身背景透明，启动器就直接显示透明背景。实测通过。

所以本方案：
    1) 不使用 mipmap-anydpi-v26/（即不用自适应图标）——删掉它，
       让系统回退到 mipmap-*/ic_launcher.png；
    2) ic_launcher.png 用「抠好底的透明 PNG」，主体铺满整个画布。

副作用与取舍
------------
不用自适应图标后，图标不会被启动器套用「圆形/圆角方形」等形状遮罩，
而是按 PNG 原样显示（方形）。如果你更想要圆角外观，可在本脚本里给
主体加一个圆角/圆形 alpha 蒙版（见 ROUND_MASK 开关）。

使用
----
    python3 tool/gen_app_icon.py
（依赖 Pillow：pip install Pillow）

生成后固定流程（务必先卸载再安装，否则启动器缓存旧图标）：
    cd ~/Documents/GitHub/YuiTodo && flutter build apk --release
    adb -s emulator-5554 uninstall com.yuitodo.yuitodo
    adb -s emulator-5554 install build/app/outputs/flutter-apk/app-release.apk
"""

import os
import shutil
from collections import deque
from PIL import Image

# ---------------------------------------------------------------------------
# 配置区
# ---------------------------------------------------------------------------

# 源图路径（正方形，越大越好，建议 >= 512x512）
SOURCE = "/Users/yui/Downloads/square_icon.png"

# res 目录（脚本位于仓库 tool/ 下，向上两级到仓库根，再进 android/.../res）
RES_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "android", "app", "src", "main", "res",
)

# 背景判定阈值：min(R,G,B) 大于该值即视为「浅色背景」。
# 源图背景是 243~255 的噪点浅灰，用 225 可干净地判定为背景；
# 若源图背景更暗或主体更浅，可相应调整。
BG_THRESHOLD = 225

# 是否给主体加圆角/圆形蒙版：
#   None  = 不加（方形，PNG 原样显示）
#   "round" = 圆形蒙版（近似自适应图标被裁圆的效果）
#   "squircle" = 圆角方形蒙版
ROUND_MASK = None

# 圆角半径占比（仅 squircle 用）
SQUIRCLE_RADIUS = 0.22

# 各密度下图标边长（像素）。普通图标标准尺寸：mdpi=48dp 起。
DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}


def remove_background_floodfill(img: Image.Image, threshold: int) -> Image.Image:
    """从四边泛洪(flood fill)把与边缘连通的浅色像素置为透明。

    相比「全图按阈值置透明」，泛洪只去掉「和图像边缘连通的」浅色区域，
    因此不会误伤主体内部本来就很浅的部分（例如浅色衣服、高光）。
    """
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    is_bg = bytearray(w * h)
    dq = deque()

    def light(x, y):
        r, g, b, _ = px[x, y]
        return min(r, g, b) > threshold

    # 播种：四条边上的浅色像素
    for x in range(w):
        for y in (0, h - 1):
            i = y * w + x
            if not is_bg[i] and light(x, y):
                is_bg[i] = 1
                dq.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            i = y * w + x
            if not is_bg[i] and light(x, y):
                is_bg[i] = 1
                dq.append((x, y))

    # 四连通扩散
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                i = ny * w + nx
                if not is_bg[i] and light(nx, ny):
                    is_bg[i] = 1
                    dq.append((nx, ny))

    # 应用透明：背景像素 -> 全透明；边界处浅色像素 -> 按亮度做半透明（去光晕）
    # 说明：泛洪只处理了"和边缘连通"的浅色区，主体边缘往往还残留一圈被抗锯齿
    # 混入的浅色像素（看起来像白边/光晕）。这里对「紧挨背景的像素」按亮度降低
    # alpha：越浅越透明。做两轮，把淡白边吃得更干净。
    EDGE_LIGHT = 185  # 边界处 min(R,G,B) 超过它才开始降 alpha（越小吃得越狠）
    for _ in range(2):  # 两轮扩散，去光晕更彻底
        updates = []
        for y in range(h):
            for x in range(w):
                i = y * w + x
                r, g, b, a = px[x, y]
                if a == 0:
                    continue
                # 是否紧挨透明像素
                adjacent = False
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] < 200:
                        adjacent = True
                        break
                if adjacent:
                    mn = min(r, g, b)
                    if mn > EDGE_LIGHT:
                        # 亮度 185->保持不透明，255->全透明
                        na = int(max(0, min(255, (255 - mn) / (255 - EDGE_LIGHT) * 255)))
                        if na < a:
                            updates.append((x, y, r, g, b, na))
        for (x, y, r, g, b, na) in updates:
            px[x, y] = (r, g, b, na)

    # 最后：背景像素统一置全透明
    for y in range(h):
        for x in range(w):
            if is_bg[y * w + x]:
                r, g, b, _ = px[x, y]
                px[x, y] = (r, g, b, 0)
    return img


def center_square(img: Image.Image) -> Image.Image:
    """非正方形时取中心正方形区域。"""
    w, h = img.size
    s = min(w, h)
    return img.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))


def apply_mask(img: Image.Image) -> Image.Image:
    """按 ROUND_MASK 给主体套圆角/圆形 alpha 蒙版（可选）。"""
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
    src = Image.open(SOURCE)
    src = remove_background_floodfill(src, BG_THRESHOLD)
    src = center_square(src)
    src = apply_mask(src)

    # 1) 各密度普通 PNG 图标（背景透明，主体铺满整个画布）
    for name, size in DENSITIES.items():
        d = os.path.join(RES_DIR, f"mipmap-{name}")
        os.makedirs(d, exist_ok=True)
        icon = src.resize((size, size), Image.LANCZOS)
        icon.save(os.path.join(d, "ic_launcher.png"))
        icon.save(os.path.join(d, "ic_launcher_round.png"))

    # 2) 删除自适应图标目录 —— 关键！否则系统优先用它，导致背景被强制铺底色
    anydpi = os.path.join(RES_DIR, "mipmap-anydpi-v26")
    if os.path.exists(anydpi):
        shutil.rmtree(anydpi)
        print("已删除 mipmap-anydpi-v26/（改用透明普通 PNG）")

    # 3) 清理可能残留的自适应图标背景/前景资源
    #    （它们已无 anydpi xml 引用，留着不影响功能，但清理掉更干净）
    leftovers = ["drawable/ic_launcher_background.png"]
    for name in DENSITIES:
        leftovers.append(f"mipmap-{name}/ic_launcher_foreground.png")
    for leftover in leftovers:
        p = os.path.join(RES_DIR, leftover)
        if os.path.exists(p):
            os.remove(p)
            print("已清理残留:", leftover)

    print("图标已生成到:", RES_DIR)
    print("提醒：必须 adb uninstall 再 install，否则启动器显示缓存的旧图标。")


if __name__ == "__main__":
    main()
