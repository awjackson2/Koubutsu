#!/usr/bin/env python3
"""Draws Koubutsu's pixel art: UI icons, logo, app icon, launch art and cover art.

    python3 Tools/pixel_art.py [--sheet OUT.png]

Everything is drawn on small pixel grids (no anti-aliasing) and scaled with nearest-neighbour, so the art is
original, reproducible and crisp. Output goes to App/Resources/Assets.xcassets and docs/art/.
Style: Heisei-era VCR on-screen display / surveillance HUD — paper white, ink black, signal red, 1-bit dither.
Fonts used for lettering: VCR OSD Mono (Riciery Leal) and DotGothic16 (OFL).
"""
import argparse, json, math, os, random
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "App", "Resources", "Assets.xcassets")
DOCS = os.path.join(ROOT, "docs", "art")
FONTS = os.path.join(ROOT, "App", "Resources", "Fonts")
VCR = os.path.join(FONTS, "VCR_OSD_MONO_1.001.ttf")
DOT = os.path.join(FONTS, "DotGothic16-Regular.ttf")

PAPER = (236, 234, 228)
INK = (13, 13, 15)
RED = (227, 38, 31)
GREY = (138, 138, 138)

BAYER8 = [[0, 32, 8, 40, 2, 34, 10, 42], [48, 16, 56, 24, 50, 18, 58, 26], [12, 44, 4, 36, 14, 46, 6, 38],
          [60, 28, 52, 20, 62, 30, 54, 22], [3, 35, 11, 43, 1, 33, 9, 41], [51, 19, 59, 27, 49, 17, 57, 25],
          [15, 47, 7, 39, 13, 45, 5, 37], [63, 31, 55, 23, 61, 29, 53, 21]]


def dither(value, x, y):
    """Ordered (Bayer 8×8) 1-bit threshold of a 0…1 value."""
    return value > (BAYER8[y % 8][x % 8] + 0.5) / 64


# ---------------------------------------------------------------- icons (16×16, template: white on clear)

def grid(rows):
    img = Image.new("L", (16, 16), 0)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                img.putpixel((x, y), 255)
    return img


def canvas():
    img = Image.new("L", (16, 16), 0)
    return img, ImageDraw.Draw(img)


def glyph(text, font, size, offset=(0, 0)):
    img, d = canvas()
    d.fontmode = "1"
    f = ImageFont.truetype(font, size)
    box = d.textbbox((0, 0), text, font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((16 - w) // 2 - box[0] + offset[0], (16 - h) // 2 - box[1] + offset[1]), text, font=f, fill=255)
    return img


def mirror(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def icons():
    out = {}
    img, d = canvas(); d.polygon([(4, 2), (4, 13), (11, 8), (11, 7)], fill=255); out["play"] = img
    img, d = canvas(); d.rectangle((3, 2, 5, 13), fill=255); d.rectangle((10, 2, 12, 13), fill=255); out["pause"] = img
    img, d = canvas(); d.rectangle((3, 3, 12, 12), fill=255); out["stop"] = img
    img, d = canvas()
    d.polygon([(7, 3), (7, 12), (2, 8), (2, 7)], fill=255); d.polygon([(13, 3), (13, 12), (8, 8), (8, 7)], fill=255)
    out["rewind"] = img
    out["forward"] = mirror(img)
    out["loop"] = grid([
        "................",
        "................",
        "....#########...",
        "...##########...",
        "..##......####..",
        "..##.....######.",
        "..##............",
        "..##............",
        "............##..",
        "............##..",
        ".######.....##..",
        "..####......##..",
        "...##########...",
        "...#########....",
        "................",
        "................"])
    img, d = canvas()
    d.rectangle((7, 1, 8, 7), fill=255); d.polygon([(3, 6), (12, 6), (8, 11), (7, 11)], fill=255)
    d.rectangle((1, 10, 2, 14), fill=255); d.rectangle((13, 10, 14, 14), fill=255); d.rectangle((1, 13, 14, 14), fill=255)
    out["import"] = img
    img, d = canvas()
    d.rectangle((7, 5, 8, 11), fill=255); d.polygon([(3, 5), (12, 5), (8, 0), (7, 0)], fill=255)
    d.rectangle((1, 10, 2, 14), fill=255); d.rectangle((13, 10, 14, 14), fill=255); d.rectangle((1, 13, 14, 14), fill=255)
    out["export"] = img
    out["search"] = grid([
        "................",
        "...#####........",
        "..##...##.......",
        ".##.....##......",
        ".#.......#......",
        ".#.......#......",
        ".#.......#......",
        ".##.....##......",
        "..##...###......",
        "...#######......",
        ".........###....",
        "..........###...",
        "...........###..",
        "............###.",
        ".............##.",
        "................"])
    # Study: a frozen frame (HUD corner brackets) around a character.
    img, d = canvas()
    for (x, y, dx, dy) in [(0, 0, 1, 1), (15, 0, -1, 1), (0, 15, 1, -1), (15, 15, -1, -1)]:
        for i in range(4):
            img.putpixel((x + dx * i, y), 255); img.putpixel((x, y + dy * i), 255)
    inner = glyph("字", DOT, 12)
    for yy in range(16):
        for xx in range(16):
            if inner.getpixel((xx, yy)) and 2 < xx < 13 and 2 < yy < 13:
                img.putpixel((xx, yy), 255)
    out["study"] = img
    out["words"] = grid([
        "................",
        "....##########..",
        "....#........#..",
        "..##########.#..",
        "..#........#.#..",
        "#########..#.#..",
        "#.......#..#.#..",
        "#.#####.#..#.#..",
        "#.......#..###..",
        "#.###...#..#....",
        "#.......#..#....",
        "#.#####.####....",
        "#.......#.......",
        "#########.......",
        "................",
        "................"])
    out["review"] = grid([
        "................",
        "..############..",
        "..#..........#..",
        "..#..........#..",
        "..#.......##.#..",
        "..#......##..#..",
        "..#.##..##...#..",
        "..#..####....#..",
        "..#...##.....#..",
        "..#..........#..",
        "..############..",
        "................",
        "....########....",
        "......####......",
        "................",
        "................"])
    img, d = canvas()
    for (x, y, dx, dy) in [(1, 1, 1, 1), (14, 1, -1, 1), (1, 14, 1, -1), (14, 14, -1, -1)]:
        d.rectangle((min(x, x + dx * 4), min(y, y + dy), max(x, x + dx * 4), max(y, y + dy)), fill=255)
        d.rectangle((min(x, x + dx), min(y, y + dy * 4), max(x, x + dx), max(y, y + dy * 4)), fill=255)
    out["fullscreen"] = img
    img, d = canvas()
    for (x, y, dx, dy) in [(5, 5, -1, -1), (10, 5, 1, -1), (5, 10, -1, 1), (10, 10, 1, 1)]:
        d.rectangle((min(x, x + dx * 4), min(y, y + dy), max(x, x + dx * 4), max(y, y + dy)), fill=255)
        d.rectangle((min(x, x + dx), min(y, y + dy * 4), max(x, x + dx), max(y, y + dy * 4)), fill=255)
    out["windowed"] = img
    out["settings"] = grid([
        "................",
        "......####......",
        "......####......",
        "..##.######.##..",
        "..############..",
        "...####..####...",
        ".####......####.",
        ".###........###.",
        ".###........###.",
        ".####......####.",
        "...####..####...",
        "..############..",
        "..##.######.##..",
        "......####......",
        "......####......",
        "................"])
    out["recent"] = grid([
        "................",
        "................",
        "##..##########..",
        "##..##########..",
        "................",
        "................",
        "##..########....",
        "##..########....",
        "................",
        "................",
        "##..##########..",
        "##..##########..",
        "................",
        "................",
        "##..######......",
        "##..######......"])
    out["eye"] = grid([
        "................",
        "................",
        "................",
        ".....######.....",
        "...##......##...",
        "..#....##....#..",
        ".#....####....#.",
        "#....######....#",
        "#....######....#",
        ".#....####....#.",
        "..#....##....#..",
        "...##......##...",
        ".....######.....",
        "................",
        "................",
        "................"])
    out["english"] = glyph("EN", VCR, 11)
    out["furigana"] = grid([
        "................",
        "...##..##..##...",
        "...##..##..##...",
        "................",
        "..############..",
        "..#....##....#..",
        "..#....##....#..",
        "..#....##....#..",
        "..############..",
        "..#....##....#..",
        "..#....##....#..",
        "..#....##....#..",
        "..############..",
        "................",
        "................",
        "................"])
    out["japanese"] = glyph("日", DOT, 16)
    out["speaker"] = grid([
        "................",
        "................",
        "......##........",
        ".....###....#...",
        "....####.....#..",
        "#######...#...#.",
        "#######....#..#.",
        "#######....#..#.",
        "#######....#..#.",
        "#######....#..#.",
        "#######...#...#.",
        "....####.....#..",
        ".....###....#...",
        "......##........",
        "................",
        "................"])
    img, d = canvas(); d.polygon([(3, 1), (12, 1), (12, 14), (8, 10), (7, 10), (3, 14)], fill=255)
    out["bookmark.fill"] = img
    img2 = img.copy(); d2 = ImageDraw.Draw(img2); d2.polygon([(5, 3), (10, 3), (10, 10), (8, 8), (7, 8), (5, 10)], fill=0)
    out["bookmark"] = img2
    img, d = canvas(); d.line((2, 2, 13, 13), fill=255, width=2); d.line((13, 2, 2, 13), fill=255, width=2); out["close"] = img
    out["chevron"] = grid(["................"] * 3 + [
        ".....##.........",
        "......##........",
        ".......##.......",
        "........##......",
        ".........##.....",
        ".........##.....",
        "........##......",
        ".......##.......",
        "......##........",
        ".....##........."] + ["................"] * 3)
    img, d = canvas(); d.line((2, 8, 6, 12), fill=255, width=2); d.line((6, 12, 13, 3), fill=255, width=2); out["check"] = img
    out["trash"] = grid([
        "................",
        "......####......",
        "..############..",
        "..############..",
        "................",
        "...##########...",
        "...#..#..#..#...",
        "...#..#..#..#...",
        "...#..#..#..#...",
        "...#..#..#..#...",
        "...#..#..#..#...",
        "...#..#..#..#...",
        "...##########...",
        "...##########...",
        "................",
        "................"])
    img, d = canvas(); d.rectangle((5, 1, 14, 10), outline=255, width=2); d.rectangle((1, 5, 10, 14), fill=0)
    d.rectangle((1, 5, 10, 14), outline=255, width=2); out["copy"] = img
    out["dictionary"] = grid([
        "................",
        ".#############..",
        ".##..........#..",
        ".##..######..#..",
        ".##..........#..",
        ".##..#####...#..",
        ".##..........#..",
        ".##..........#..",
        ".##..........#..",
        ".##..........#..",
        ".##..........#..",
        ".#############..",
        ".##.........##..",
        "..###########...",
        "................",
        "................"])
    out["source"] = grid([
        "................",
        "....#.....#.....",
        ".....#...#......",
        "......#.#.......",
        "##############..",
        "#............##.",
        "#.#########..##.",
        "#.#.......#..##.",
        "#.#.......#..##.",
        "#.#.......#..##.",
        "#.#########..##.",
        "#............##.",
        "##############..",
        "..##......##....",
        "................",
        "................"])
    img, d = canvas(); d.rectangle((6, 1, 9, 14), fill=255); d.rectangle((1, 6, 14, 9), fill=255); out["plus"] = img
    return out


# ---------------------------------------------------------------- the eye (logo, icon, cover)

def eye_value(u, v):
    """Brightness 0 (ink) … 1 (paper) of a stylized eye at normalized coords u,v in -1…1."""
    lid = max(0.0, 1 - u * u) ** 0.9 * 0.62
    if abs(v) > lid:
        return 1.0  # outside the almond: paper
    if abs(v) > lid - 0.09 or (v < 0 and abs(v) > lid - 0.16):
        return 0.0  # lid lines (upper lid heavier)
    r = math.hypot(u, v)
    if r < 0.2:
        return 0.0  # pupil (drawn red later)
    if -0.34 < u < -0.2 and -0.34 < v < -0.2:
        return 1.0  # catch-light
    if r < 0.5:
        streak = 0.5 + 0.5 * math.sin(math.atan2(v, u) * 18)
        return 0.06 + 0.28 * ((r - 0.2) / 0.3) ** 2 + 0.1 * streak
    if r < 0.56:
        return 0.0  # iris rim
    edge = abs(v) / lid
    return 0.97 - 0.45 * edge ** 3  # sclera, shaded towards the lids


def eye_bitmap(size, scale_x=1.0):
    img = Image.new("RGB", (size, size), PAPER)
    for y in range(size):
        for x in range(size):
            u = (x + 0.5) / size * 2 - 1
            v = (y + 0.5) / size * 2 - 1
            val = eye_value(u / scale_x, v)
            img.putpixel((x, y), PAPER if dither(val, x, y) else INK)
    return img


def draw_pupil(img, size, cell):
    c = size // 2
    d = ImageDraw.Draw(img)
    d.rectangle((c - cell, c - cell, c + cell - 1, c + cell - 1), fill=RED)
    d.rectangle((c + cell, c - 2 * cell, c + 2 * cell - 1, c - cell - 1), fill=RED)


def corners(img, color, inset, length, weight):
    d = ImageDraw.Draw(img)
    w, h = img.size
    for (x, y, dx, dy) in [(inset, inset, 1, 1), (w - 1 - inset, inset, -1, 1),
                           (inset, h - 1 - inset, 1, -1), (w - 1 - inset, h - 1 - inset, -1, -1)]:
        d.rectangle((min(x, x + dx * length), min(y, y + dy * (weight - 1)),
                     max(x, x + dx * length), max(y, y + dy * (weight - 1))), fill=color)
        d.rectangle((min(x, x + dx * (weight - 1)), min(y, y + dy * length),
                     max(x, x + dx * (weight - 1)), max(y, y + dy * length)), fill=color)


def text_px(img, xy, text, font, size, color):
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    d.text(xy, text, font=ImageFont.truetype(font, size), fill=color)


def logo_mark():
    """32×32: dithered eye with a red pixel pupil inside detection brackets."""
    img = Image.new("RGB", (32, 32), PAPER)
    img.paste(eye_bitmap(28), (2, 2))
    draw_pupil(img, 32, 2)
    corners(img, RED, 0, 5, 2)
    return img


def app_icon():
    """64×64 grid → 1024 px."""
    g = 64
    img = Image.new("RGB", (g, g), PAPER)
    rnd = random.Random(7)
    for y in range(g):
        for x in range(g):
            if rnd.random() < 0.05:
                img.putpixel((x, y), (222, 220, 214))
    img.paste(eye_bitmap(56, 1.0), (4, 4))
    draw_pupil(img, g, 3)
    corners(img, RED, 3, 9, 2)
    return img.resize((1024, 1024), Image.NEAREST)


def wordmark():
    """Pixel wordmark 'KOUBUTSU' with a red cursor block."""
    f = ImageFont.truetype(VCR, 16)
    probe = ImageDraw.Draw(Image.new("L", (1, 1)))
    box = probe.textbbox((0, 0), "KOUBUTSU", font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    img = Image.new("RGBA", (w + 10, h + 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    d.text((-box[0], 1 - box[1]), "KOUBUTSU", font=f, fill=INK + (255,))
    d.rectangle((w + 3, 1, w + 8, h), fill=RED + (255,))
    return img


def cover(width=270, height=338):
    """Poster (×4 → 1080×1352): a dithered eye on a CRT above a game dialogue box with a detection box,
    VCR OSD type and red blocks."""
    img = Image.new("RGB", (width, height), PAPER)
    d = ImageDraw.Draw(img)
    rnd = random.Random(3)
    for x in range(184, width, 10):
        for y in range(0, height, 2):
            img.putpixel((x, y), (214, 212, 206))
    for y in range(0, height, 10):
        for x in range(184, width, 2):
            img.putpixel((x, y), (214, 212, 206))
    # CRT: dark field with scanlines; a large dithered eye in it.
    sx0, sy0, sx1, sy1 = 12, 64, 240, 226
    d.rectangle((sx0, sy0, sx1 - 1, sy1 - 1), fill=INK)
    eye = eye_bitmap(150, 1.0)
    ex, ey = (sx0 + sx1) // 2 - 75, sy0 - 32
    for y in range(150):
        for x in range(150):
            X, Y = ex + x, ey + y
            if sy0 <= Y < sy1 - 52 and sx0 <= X < sx1 and eye.getpixel((x, y)) == PAPER:
                u, v = (x - 75) / 75, (y - 75) / 75
                if abs(v) < max(0.0, 1 - u * u) ** 0.9 * 0.62:
                    img.putpixel((X, Y), (232, 232, 236) if Y % 3 else (150, 150, 156))
    c = (ex + 75, ey + 75)
    d.rectangle((c[0] - 7, c[1] - 7, c[0] + 6, c[1] + 6), fill=RED)
    d.rectangle((c[0] + 7, c[1] - 14, c[0] + 13, c[1] - 8), fill=RED)
    # Dialogue box with Japanese and a detection box on 強い.
    d.rectangle((24, 172, 228, 218), fill=INK, outline=PAPER, width=1)
    text_px(img, (32, 180), "この先には強い敵がいる。", DOT, 12, PAPER)
    text_px(img, (32, 198), "鍵が必要です", DOT, 12, PAPER)
    d.rectangle((91, 177, 116, 193), outline=RED, width=1)
    text_px(img, (93, 166), "つよ", DOT, 12, RED)
    d.rectangle((134, 156, 192, 166), fill=RED)
    text_px(img, (137, 157), "TEXT_05XX", DOT, 10, PAPER)
    d.line((116, 177, 134, 166), fill=RED)
    # Type.
    text_px(img, (12, 8), "KOUBUTSU", VCR, 32, INK)
    for i, x in enumerate((13, 23, 33)):
        d.rectangle((x, 46, x + 4, 50), fill=RED)
    text_px(img, (44, 43), "READ / UNDERSTAND / REMEMBER", DOT, 10, RED)
    text_px(img, (12, 234), "よむ・わかる・おぼえる", DOT, 16, INK)
    text_px(img, (12, 258), "OCR           01", DOT, 10, INK)
    text_px(img, (12, 270), "TRANSLATE     02", DOT, 10, INK)
    text_px(img, (12, 282), "STUDY         03", DOT, 10, INK)
    text_px(img, (140, 258), "VERSION 0.9", DOT, 10, RED)
    text_px(img, (140, 270), "BATCH: KB-0457", DOT, 10, RED)
    text_px(img, (140, 282), "SIGNAL: SWITCH 2", DOT, 10, RED)
    d.rectangle((248, 0, 255, 70), fill=RED)
    d.rectangle((0, 302, 36, 338), fill=RED)
    text_px(img, (44, 316), "READ EVERYTHING.", VCR, 16, INK)
    corners(img, INK, 5, 8, 1)
    for _ in range(width * height // 25):
        x, y = rnd.randrange(width), rnd.randrange(height)
        if img.getpixel((x, y)) == PAPER:
            img.putpixel((x, y), (204, 202, 196))
    return img.resize((width * 4, height * 4), Image.NEAREST)


def grain_tile(size=128):
    rnd = random.Random(11)
    img = Image.new("LA", (size, size), (0, 0))
    for y in range(size):
        for x in range(size):
            if rnd.random() < 0.18:
                img.putpixel((x, y), (0 if rnd.random() < 0.5 else 255, rnd.randrange(10, 40)))
    return img


# ---------------------------------------------------------------- asset catalog

def write_json(path, obj):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)
        f.write("\n")


def imageset(name, img, template=False):
    folder = os.path.join(ASSETS, f"{name}.imageset")
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, f"{name}.png"))
    contents = {"images": [{"filename": f"{name}.png", "idiom": "universal"}],
                "info": {"author": "xcode", "version": 1}}
    if template:
        contents["properties"] = {"template-rendering-intent": "template"}
    write_json(os.path.join(folder, "Contents.json"), contents)


def colorset(name, rgb):
    folder = os.path.join(ASSETS, f"{name}.colorset")
    os.makedirs(folder, exist_ok=True)
    comps = {k: f"{v / 255:.3f}" for k, v in zip(("red", "green", "blue"), rgb)}
    comps["alpha"] = "1.000"
    write_json(os.path.join(folder, "Contents.json"),
               {"colors": [{"color": {"color-space": "srgb", "components": comps}, "idiom": "universal"}],
                "info": {"author": "xcode", "version": 1}})


def template_png(mask):
    rgba = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    for y in range(mask.height):
        for x in range(mask.width):
            if mask.getpixel((x, y)):
                rgba.putpixel((x, y), (255, 255, 255, 255))
    return rgba


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sheet", help="also write a contact sheet of every icon")
    args = parser.parse_args()
    os.makedirs(ASSETS, exist_ok=True)
    os.makedirs(DOCS, exist_ok=True)
    write_json(os.path.join(ASSETS, "Contents.json"), {"info": {"author": "xcode", "version": 1}})
    set_icons = icons()
    for name, mask in set_icons.items():
        imageset("px." + name, template_png(mask), template=True)
    imageset("LogoMark", logo_mark())
    imageset("Wordmark", wordmark())
    imageset("Grain", grain_tile())
    icon = app_icon()
    folder = os.path.join(ASSETS, "AppIcon.appiconset")
    os.makedirs(folder, exist_ok=True)
    icon.save(os.path.join(folder, "AppIcon.png"))
    write_json(os.path.join(folder, "Contents.json"),
               {"images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
                "info": {"author": "xcode", "version": 1}})
    launch = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    launch.paste(logo_mark().resize((32, 32)), (8, 8))
    imageset("LaunchLogo", launch.resize((192, 192), Image.NEAREST))
    colorset("AccentColor", RED)
    colorset("LaunchBackground", INK)
    icon.save(os.path.join(DOCS, "app_icon.png"))
    cover().save(os.path.join(DOCS, "cover.png"))
    logo_mark().resize((256, 256), Image.NEAREST).save(os.path.join(DOCS, "logo_mark.png"))
    wm = wordmark()
    wm.resize((wm.width * 8, wm.height * 8), Image.NEAREST).save(os.path.join(DOCS, "wordmark.png"))
    if args.sheet:
        names = list(set_icons)
        cols = 8
        sheet = Image.new("RGB", (cols * 80, ((len(names) + cols - 1) // cols) * 96), INK)
        d = ImageDraw.Draw(sheet)
        for i, name in enumerate(names):
            x, y = (i % cols) * 80 + 8, (i // cols) * 96 + 8
            tile = set_icons[name].resize((64, 64), Image.NEAREST)
            sheet.paste(Image.new("RGB", (64, 64), PAPER), (x, y), tile)
            d.text((x, y + 68), name, fill=RED)
        sheet.save(args.sheet)
    print(f"{len(set_icons)} icons, logo, wordmark, app icon, launch logo, cover → {ASSETS}, {DOCS}")


if __name__ == "__main__":
    main()
