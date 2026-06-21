#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT_DIR = Path(__file__).resolve().parents[1]

FONT_PATH = ROOT_DIR / "assets" / "NuKinakoMochi-Reg.otf"
OUTPUT_PATH = ROOT_DIR / "assets" / "font.png"

TILE_SIZE = 8
COLS = 16
ROWS = 16
FONT_SIZE = 8

# Game Boy風 4色パレット
# 0: 白
# 1: 薄い緑
# 2: 濃い緑
# 3: 黒
GB_PALETTE = [
    0xE0, 0xF8, 0xD0,  # 0: #E0F8D0
    0x88, 0xC0, 0x70,  # 1: #88C070
    0x34, 0x68, 0x56,  # 2: #346856
    0x08, 0x18, 0x20,  # 3: #081820
]

CHARS = (
    "0123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    "あいうえおかきくけこさしすせそたちつてとなにぬねの"
    "はひふへほまみむめもやゆよらりるれろわをん"
    "アイウエオカキクケコサシスセソタチツテトナニヌネノ"
    "ハヒフヘホマミムメモヤユヨラリルレロワヲン"
    "。、！？ー"
)


def fit_chars(chars: str) -> str:
    max_chars = COLS * ROWS
    if len(chars) > max_chars:
        raise ValueError(f"文字数が多すぎます: {len(chars)} > {max_chars}")
    return chars + (" " * (max_chars - len(chars)))


def create_indexed_image(width: int, height: int) -> Image.Image:
    image = Image.new("P", (width, height), 0)

    # PNGのパレットは最大256色分=768要素必要
    palette = GB_PALETTE + [0] * (768 - len(GB_PALETTE))
    image.putpalette(palette)

    return image


def draw_char(draw: ImageDraw.ImageDraw, font: ImageFont.FreeTypeFont, ch: str, x: int, y: int) -> None:
    if ch == " ":
        return

    bbox = draw.textbbox((0, 0), ch, font=font)
    left, top, right, bottom = bbox
    w = right - left
    h = bottom - top

    px = x + (TILE_SIZE - w) // 2 - left
    py = y + (TILE_SIZE - h) // 2 - top

    # 文字は黒(Index 3)で描画
    draw.text((px, py), ch, font=font, fill=3)


def main() -> None:
    if not FONT_PATH.exists():
        raise FileNotFoundError(f"フォントが見つかりません: {FONT_PATH}")

    chars = fit_chars(CHARS)

    image = create_indexed_image(COLS * TILE_SIZE, ROWS * TILE_SIZE)
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(str(FONT_PATH), FONT_SIZE)

    for i, ch in enumerate(chars):
        col = i % COLS
        row = i // COLS
        x = col * TILE_SIZE
        y = row * TILE_SIZE
        draw_char(draw, font, ch, x, y)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    # optimize=False にしてパレットが勝手に最適化されないようにする
    image.save(OUTPUT_PATH, format="PNG", optimize=False)

    print(f"generated: {OUTPUT_PATH}")
    print(f"size: {image.width}x{image.height}")
    print("mode:", image.mode)
    print(f"chars: {len(CHARS)} / {COLS * ROWS}")


if __name__ == "__main__":
    main()