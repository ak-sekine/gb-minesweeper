#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path

from PIL import Image


TILE_SIZE = 8
MAX_TILES = 256
TILESET_COLUMNS = 16


def fail(message: str) -> None:
    raise ValueError(message)


def validate_image(image: Image.Image, path: Path) -> None:
    if image.mode != "P":
        fail(f"{path}: image must be Indexed Color PNG (mode P), got {image.mode}")

    if "transparency" in image.info:
        fail(f"{path}: alpha/transparency is not supported")

    width, height = image.size
    if width % TILE_SIZE != 0 or height % TILE_SIZE != 0:
        fail(f"{path}: width and height must be multiples of {TILE_SIZE}, got {width}x{height}")

    palette = image.getpalette()
    if palette is None or len(palette) < 12:
        fail(f"{path}: image must have a 4-color palette")

    used_indices = set(image.tobytes())
    invalid_indices = sorted(index for index in used_indices if index >= 4)
    if invalid_indices:
        fail(f"{path}: image must use only palette indices 0-3, found {invalid_indices}")


def read_tile(image: Image.Image, tile_x: int, tile_y: int) -> bytes:
    x0 = tile_x * TILE_SIZE
    y0 = tile_y * TILE_SIZE
    tile = image.crop((x0, y0, x0 + TILE_SIZE, y0 + TILE_SIZE))
    return tile.tobytes()


def build_tiles(image: Image.Image) -> tuple[list[bytes], bytes, int, int]:
    width, height = image.size
    map_width = width // TILE_SIZE
    map_height = height // TILE_SIZE
    tile_to_index: dict[bytes, int] = {}
    unique_tiles: list[bytes] = []
    bg_map = bytearray()

    for tile_y in range(map_height):
        for tile_x in range(map_width):
            tile_data = read_tile(image, tile_x, tile_y)
            tile_index = tile_to_index.get(tile_data)
            if tile_index is None:
                if len(unique_tiles) >= MAX_TILES:
                    fail(f"unique tile count exceeds {MAX_TILES}")
                tile_index = len(unique_tiles)
                tile_to_index[tile_data] = tile_index
                unique_tiles.append(tile_data)
            bg_map.append(tile_index)

    return unique_tiles, bytes(bg_map), map_width, map_height


def write_tileset_png(unique_tiles: list[bytes], palette: list[int], output_path: Path) -> None:
    columns = min(TILESET_COLUMNS, max(1, len(unique_tiles)))
    rows = (len(unique_tiles) + columns - 1) // columns
    image = Image.new("P", (columns * TILE_SIZE, rows * TILE_SIZE), 0)
    image.putpalette(palette[:12])

    for index, tile_data in enumerate(unique_tiles):
        tile = Image.frombytes("P", (TILE_SIZE, TILE_SIZE), tile_data)
        tile.putpalette(palette[:12])
        x = (index % columns) * TILE_SIZE
        y = (index // columns) * TILE_SIZE
        image.paste(tile, (x, y))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path, format="PNG", optimize=False)


def write_bg_map(bg_map: bytes, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(bg_map)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert an indexed 4-color PNG into deduplicated 8x8 BG tiles and a binary BG map."
    )
    parser.add_argument("input_png", type=Path, help="Input Indexed Color PNG")
    parser.add_argument("output_tiles_png", type=Path, help="Output deduplicated tileset PNG")
    parser.add_argument("output_map_bin", type=Path, help="Output binary BG map, 1 byte per source tile")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        with Image.open(args.input_png) as image:
            validate_image(image, args.input_png)
            palette = image.getpalette()
            unique_tiles, bg_map, map_width, map_height = build_tiles(image)
            write_tileset_png(unique_tiles, palette, args.output_tiles_png)
            write_bg_map(bg_map, args.output_map_bin)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"input: {args.input_png}")
    print(f"source tiles: {map_width}x{map_height} = {map_width * map_height}")
    print(f"unique tiles: {len(unique_tiles)}")
    print(f"tileset: {args.output_tiles_png}")
    print(f"bg map: {args.output_map_bin} ({len(bg_map)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
