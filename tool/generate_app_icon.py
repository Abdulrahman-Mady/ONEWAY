#!/usr/bin/env python3
"""Generate the ONEWAY app icon (master + Android/iOS/Web variants).

Design: deep-navy canvas, an active-pose wheelchair glyph in warm amber
riding a bright-teal wheel, with a subtle ramp underline. Supersampled 4x
for clean antialiasing.

Run from the repo root:  python3 tool/generate_app_icon.py
"""

import math
import os
from PIL import Image, ImageDraw

# Brand palette
NAVY_TOP = (10, 18, 32)      # #0A1220
NAVY_BOTTOM = (22, 36, 62)   # #16243E
AMBER = (255, 176, 32)       # #FFB020
TEAL = (45, 212, 191)        # #2DD4BF
WHITE_SOFT = (232, 240, 248)

SS = 4  # supersample factor
SIZE = 1024


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        c = lerp(top, bottom, y / (size - 1))
        for x in range(size):
            px[x, y] = c
    return img


def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def draw_glyph(canvas_size, glyph_scale=1.0, center=None):
    """Draw the wheelchair glyph on a transparent layer of canvas_size.

    glyph_scale scales the glyph relative to the canvas (1.0 = full icon).
    Returns an RGBA image.
    """
    layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    s = canvas_size / 1024.0 * glyph_scale
    cx, cy = center if center else (canvas_size / 2, canvas_size / 2)

    def P(x, y):
        # Map design-space coords (1024 canvas, glyph centered at 512,512)
        return (cx + (x - 512) * s, cy + (y - 512) * s)

    def line(pts, width, color):
        d.line([P(x, y) for x, y in pts], fill=color, width=int(width * s),
               joint="curve")
        # rounded caps
        r = width * s / 2
        for x, y in (pts[0], pts[-1]):
            px, py = P(x, y)
            d.ellipse([px - r, py - r, px + r, py + r], fill=color)

    # Wheel (teal ring) - center right-bottom of the figure
    wx, wy, wr = 585, 660, 175
    stroke = 62
    d.ellipse(
        [P(wx - wr, wy - wr)[0], P(wx - wr, wy - wr)[1],
         P(wx + wr, wy + wr)[0], P(wx + wr, wy + wr)[1]],
        outline=TEAL, width=int(stroke * s),
    )

    # Head (amber)
    hx, hy, hr = 452, 268, 56
    d.ellipse([P(hx - hr, hy - hr)[0], P(hx - hr, hy - hr)[1],
               P(hx + hr, hy + hr)[0], P(hx + hr, hy + hr)[1]], fill=AMBER)

    # Torso leaning forward (amber): neck -> hip
    line([(470, 345), (535, 560)], 58, AMBER)
    # Arm reaching to wheel rim (amber): shoulder -> hand on wheel
    line([(495, 420), (660, 505)], 48, AMBER)
    # Leg: hip -> knee -> foot (amber)
    line([(535, 560), (660, 575)], 52, AMBER)
    line([(660, 575), (700, 690)], 46, AMBER)
    # Footrest tip
    line([(700, 690), (742, 690)], 40, AMBER)

    # Ramp underline (soft white-teal) under the wheel: rising path
    ramp_y = 900
    line([(280, ramp_y), (760, ramp_y - 46)], 26, lerp(TEAL, WHITE_SOFT, 0.15))

    return layer


def compose_master(size=SIZE, rounded=False):
    bg = vertical_gradient(size * SS, NAVY_TOP, NAVY_BOTTOM)
    glyph = draw_glyph(size * SS).resize((size * SS, size * SS))
    bg = bg.convert("RGBA")
    bg.alpha_composite(glyph)
    if rounded:
        mask = rounded_mask(size * SS, int(size * SS * 0.22))
        out = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
        out.paste(bg, (0, 0), mask)
        bg = out
    return bg.resize((size, size), Image.LANCZOS)


def compose_adaptive_foreground(size):
    """Transparent canvas with glyph scaled into the 66% safe zone."""
    img = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    glyph = draw_glyph(size * SS, glyph_scale=0.62)
    img.alpha_composite(glyph)
    return img.resize((size, size), Image.LANCZOS)


def compose_maskable(size):
    """Full-bleed square with glyph inside safe zone (for web maskable)."""
    bg = vertical_gradient(size * SS, NAVY_TOP, NAVY_BOTTOM).convert("RGBA")
    glyph = draw_glyph(size * SS, glyph_scale=0.66)
    bg.alpha_composite(glyph)
    return bg.resize((size, size), Image.LANCZOS)


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", path)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # 1. Master (square, no alpha for stores)
    master = compose_master(1024, rounded=False).convert("RGB")
    save(master, os.path.join(root, "assets/images/app_icon_1024.png"))

    # 2. Android legacy mipmaps (rounded square with transparent corners)
    densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96,
                 "xxhdpi": 144, "xxxhdpi": 192}
    for name, px in densities.items():
        save(compose_master(px, rounded=True),
             os.path.join(root, f"android/app/src/main/res/mipmap-{name}/ic_launcher.png"))
        save(compose_adaptive_foreground(int(px * 108 / 48)),
             os.path.join(root, f"android/app/src/main/res/mipmap-{name}/ic_launcher_foreground.png"))

    # 2b. Adaptive icon xml + background color
    anydpi = os.path.join(root, "android/app/src/main/res/mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
        f.write(xml)
    with open(os.path.join(anydpi, "ic_launcher_round.xml"), "w") as f:
        f.write(xml)
    values = os.path.join(root, "android/app/src/main/res/values/ic_launcher_background.xml")
    with open(values, "w") as f:
        f.write("""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0A1220</color>
</resources>
""")
    print("wrote adaptive icon xml + background color")

    # 3. iOS AppIcon set (flattened, no alpha)
    ios_dir = os.path.join(root, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
    ios_specs = [
        ("Icon-App-20x20@1x.png", 20), ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60), ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58), ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40), ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120), ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180), ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152), ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for fname, px in ios_specs:
        save(compose_master(px, rounded=False).convert("RGB"),
             os.path.join(ios_dir, fname))

    # 4. Web icons (maskable full-bleed) + favicon
    web = os.path.join(root, "web")
    for px in (192, 512):
        save(compose_maskable(px), os.path.join(web, f"icons/Icon-{px}.png"))
    for px in (16, 32, 48, 72, 96, 128, 144, 152, 384):
        p = os.path.join(web, f"icons/icon-{px}x{px}.png")
        if os.path.exists(p):
            save(compose_maskable(px), p)
    save(compose_maskable(32), os.path.join(web, "favicon.png"))

    # 5. Preview for quick visual check
    save(compose_master(512, rounded=True), "/tmp/icon_preview.png")


if __name__ == "__main__":
    main()
