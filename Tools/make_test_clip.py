#!/usr/bin/env python3
"""Generates the deterministic synthetic Japanese test clip and its expectation manifest.

Output:
  App/Resources/TestMedia/synthetic_ja_1080p60.mp4   H.264 1920x1080 @ 60 FPS + AAC blip track
  App/Resources/TestMedia/synthetic_ja_1080p60.json  expected on-screen text per time range

The clip imitates game UI situations OCR must handle: a title menu with a moving cursor, a dialogue box
with typewriter reveal over a moving background, small status text, and a katakana menu. Real gameplay
footage is imported at runtime and never committed.

Requires: Pillow, imageio-ffmpeg (pip install pillow imageio-ffmpeg) and a Japanese font
(IPAGothic by default; override with KOUBUTSU_JA_FONT).
"""
import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "App", "Resources", "TestMedia")
NAME = "synthetic_ja_1080p60"
W, H, FPS = 1920, 1080, 60
DURATION = 24.0
FONT_PATH = os.environ.get("KOUBUTSU_JA_FONT", "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf")
REVEAL_FRAMES_PER_CHAR = 4  # 15 characters/second typewriter reveal


def font(size):
    return ImageFont.truetype(FONT_PATH, size)


F_TITLE, F_BODY, F_MENU, F_SMALL = font(96), font(64), font(56), font(36)

# Scenes: (start, end) seconds. Every text element records its expected text and normalized box.
TITLE_Q = "冒険を始めますか？"
TITLE_OPTIONS = ["はい", "いいえ"]
LINE1 = "この先には強い敵がいる。"
LINE2 = "鍵が必要です"
SAVING = "セーブしています…"
MENU_HEADER = "メニュー"
MENU_ITEMS = ["アイテム", "そうび", "ステータス", "セーブ"]
FOOTER = "Ａボタンで決定"

manifest = {
    "name": NAME,
    "width": W, "height": H, "fps": FPS, "duration": DURATION,
    "coordinateSpace": "normalized, top-left origin",
    "checkpoints": [],
}


def text_box(draw, xy, text, fnt, anchor="la"):
    x0, y0, x1, y1 = draw.textbbox(xy, text, font=fnt, anchor=anchor)
    return {"x": round(x0 / W, 4), "y": round(y0 / H, 4), "width": round((x1 - x0) / W, 4),
            "height": round((y1 - y0) / H, 4)}


def background(t, moving):
    """Dark blue gradient; when moving, diagonal bands scroll to stress OCR on changing backgrounds."""
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(0, H, 8):
        c = int(30 + 40 * y / H)
        d.rectangle([0, y, W, y + 8], fill=(10, 20 + c // 3, 40 + c))
    if moving:
        off = int(t * 240) % 240
        for x in range(-H - 240 + off, W + 240, 240):
            d.polygon([(x, H), (x + 120, H), (x + 120 + H, 0), (x + H, 0)], fill=(30, 50, 90))
    return img


def dialogue_box(d):
    d.rounded_rectangle([160, 720, W - 160, 1010], radius=24, fill=(0, 0, 0), outline=(255, 255, 255), width=6)


def render(t, frame_index, record):
    if t < 6:
        img = background(t, moving=False)
        d = ImageDraw.Draw(img)
        d.text((W // 2, 360), TITLE_Q, font=F_TITLE, fill="white", anchor="mm")
        sel = 0 if t < 3 else 1
        boxes = [text_box(d, (W // 2, 360), TITLE_Q, F_TITLE, "mm")]
        for i, opt in enumerate(TITLE_OPTIONS):
            y = 560 + i * 110
            d.text((W // 2, y), opt, font=F_MENU, fill="white", anchor="mm")
            boxes.append(text_box(d, (W // 2, y), opt, F_MENU, "mm"))
            if i == sel:
                d.text((W // 2 - 200, y), "▶", font=F_MENU, fill=(255, 220, 0), anchor="mm")
        record("title", 0.0, 6.0, [TITLE_Q] + TITLE_OPTIONS, boxes)
        return img
    if t < 14:
        img = background(t, moving=True)
        d = ImageDraw.Draw(img)
        dialogue_box(d)
        local = frame_index - int(6 * FPS)
        n1 = min(len(LINE1), local // REVEAL_FRAMES_PER_CHAR + 1)
        d.text((230, 790), LINE1[:n1], font=F_BODY, fill="white")
        line2_start = len(LINE1) * REVEAL_FRAMES_PER_CHAR + FPS  # one-second pause after line 1
        shown2 = ""
        if local >= line2_start and t >= 10:
            n2 = min(len(LINE2), (local - line2_start) // REVEAL_FRAMES_PER_CHAR + 1)
            shown2 = LINE2[:n2]
            d.text((230, 890), shown2, font=F_BODY, fill="white")
        full1_at = 6 + len(LINE1) * REVEAL_FRAMES_PER_CHAR / FPS
        record("dialogue_line1", full1_at, 14.0, [LINE1], [text_box(d, (230, 790), LINE1, F_BODY)])
        full2_at = max(10.0, 6 + (line2_start + len(LINE2) * REVEAL_FRAMES_PER_CHAR) / FPS)
        record("dialogue_line2", full2_at, 14.0, [LINE2], [text_box(d, (230, 890), LINE2, F_BODY)])
        return img
    if t < 18:
        img = background(t, moving=True)
        d = ImageDraw.Draw(img)
        d.text((W - 60, 60), SAVING, font=F_SMALL, fill="white", anchor="ra")
        record("saving", 14.0, 18.0, [SAVING], [text_box(d, (W - 60, 60), SAVING, F_SMALL, "ra")])
        return img
    img = background(t, moving=False)
    d = ImageDraw.Draw(img)
    d.rectangle([120, 100, 820, 980], fill=(0, 0, 0), outline=(255, 255, 255), width=4)
    d.text((170, 140), MENU_HEADER, font=F_TITLE, fill="white")
    boxes = [text_box(d, (170, 140), MENU_HEADER, F_TITLE)]
    sel = int((t - 18) / 0.5) % len(MENU_ITEMS)
    for i, item in enumerate(MENU_ITEMS):
        y = 330 + i * 120
        d.text((260, y), item, font=F_MENU, fill=(255, 220, 0) if i == sel else "white")
        boxes.append(text_box(d, (260, y), item, F_MENU))
        if i == sel:
            d.text((190, y), "▶", font=F_MENU, fill=(255, 220, 0))
    d.text((170, 900), FOOTER, font=F_SMALL, fill=(200, 200, 200))
    boxes.append(text_box(d, (170, 900), FOOTER, F_SMALL))
    record("menu", 18.0, DURATION, [MENU_HEADER] + MENU_ITEMS + [FOOTER], boxes)
    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    mp4 = os.path.join(OUT_DIR, NAME + ".mp4")
    seen = set()

    def record(key, start, end, texts, boxes):
        if key in seen:
            return
        seen.add(key)
        manifest["checkpoints"].append({
            "id": key, "start": round(start, 3), "end": round(end, 3),
            "expected": [{"text": tx, "box": bx} for tx, bx in zip(texts, boxes)],
        })

    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    cmd = [ffmpeg, "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
           "-f", "lavfi", "-i",
           f"aevalsrc=0.08*sin(2*PI*880*t)*lt(mod(t\\,2)\\,0.06):s=48000:d={DURATION}",
           "-c:v", "libx264", "-preset", "slow", "-crf", "26", "-tune", "animation",
           "-profile:v", "high", "-level", "4.2", "-pix_fmt", "yuv420p", "-g", "120",
           "-c:a", "aac", "-b:a", "64k", "-shortest", "-movflags", "+faststart", mp4]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    total = int(DURATION * FPS)
    for i in range(total):
        img = render(i / FPS, i, record)
        proc.stdin.write(img.tobytes())
        if i % 240 == 0:
            print(f"frame {i}/{total}", file=sys.stderr)
    proc.stdin.close()
    if proc.wait() != 0:
        sys.exit("ffmpeg failed")
    manifest["checkpoints"].sort(key=lambda c: c["start"])
    with open(os.path.join(OUT_DIR, NAME + ".json"), "w") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print("wrote", mp4, os.path.getsize(mp4), "bytes")


if __name__ == "__main__":
    main()
