#!/usr/bin/env python3
"""Pixel art for the first water-run mock. Warm mùa mưa, not grey."""

from __future__ import annotations

import os
import random
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")
TILE = 16
CHAR_W = 16
CHAR_H = 28


def write_png(path: str, width: int, height: int, rgba: bytes) -> None:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    raw = b""
    stride = width * 4
    for y in range(height):
        raw += b"\x00" + rgba[y * stride : (y + 1) * stride]
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", ihdr))
        handle.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        handle.write(chunk(b"IEND", b""))


class Canvas:
    def __init__(self, width: int, height: int, fill=(0, 0, 0, 0)):
        self.width = width
        self.height = height
        self.px = [fill] * (width * height)

    def set(self, x: int, y: int, color) -> None:
        if 0 <= x < self.width and 0 <= y < self.height:
            self.px[y * self.width + x] = color

    def get(self, x: int, y: int):
        if 0 <= x < self.width and 0 <= y < self.height:
            return self.px[y * self.width + x]
        return (0, 0, 0, 0)

    def fill_rect(self, x: int, y: int, w: int, h: int, color) -> None:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, color)

    def blit(self, other: "Canvas", dx: int, dy: int) -> None:
        for y in range(other.height):
            for x in range(other.width):
                color = other.get(x, y)
                if color[3] == 0:
                    continue
                self.set(dx + x, dy + y, color)

    def bytes(self) -> bytes:
        out = bytearray()
        for color in self.px:
            out.extend(color)
        return bytes(out)

    def save(self, path: str) -> None:
        write_png(path, self.width, self.height, self.bytes())


# Warm wet Huế — cream, terracotta, moss, mud. Not slate.
GRASS = (92, 132, 68, 255)
GRASS_DARK = (68, 108, 54, 255)
GRASS_WET = (74, 118, 64, 255)
ROAD = (168, 126, 84, 255)
ROAD_DARK = (140, 102, 68, 255)
PUDDLE = (86, 128, 118, 255)
PUDDLE_LIGHT = (118, 154, 140, 255)
YARD = (176, 140, 92, 255)
YARD_DARK = (150, 116, 74, 255)
FLOOR = (186, 150, 104, 255)
WALL = (220, 190, 148, 255)
WALL_SHADOW = (188, 152, 112, 255)
ROOF = (186, 86, 60, 255)
ROOF_DARK = (148, 62, 46, 255)
ROOF_RIDGE = (210, 110, 78, 255)
BANK = (138, 102, 70, 255)
BANK_WET = (118, 88, 62, 255)
WATER = (78, 138, 124, 255)
WATER_KNEE = (56, 112, 108, 255)
WATER_DEEP = (40, 86, 90, 255)
WATER_HIGHLIGHT = (130, 176, 158, 255)
LEAF = (62, 128, 72, 255)
LEAF_DARK = (42, 96, 56, 255)
WOOD = (132, 84, 52, 255)
WOOD_DARK = (102, 64, 40, 255)
STONE = (168, 150, 122, 255)
STONE_DARK = (132, 116, 92, 255)
SKIN = (214, 170, 128, 255)
SKIN_SHADOW = (186, 136, 100, 255)
HAIR = (44, 32, 28, 255)
HAIR_LIGHT = (72, 50, 42, 255)
AO = (196, 96, 70, 255)
AO_DARK = (156, 70, 52, 255)
PANTS = (78, 62, 52, 255)
JUG = (176, 128, 78, 255)
JUG_DARK = (132, 92, 56, 255)
JUG_WET = (92, 86, 78, 255)
WATER_IN_JUG = (70, 122, 118, 255)
GLASS = (210, 230, 220, 255)
GLASS_EDGE = (140, 176, 168, 255)
POLE = (92, 62, 40, 255)
CISTERN = (150, 132, 108, 255)


def dither(canvas: Canvas, x: int, y: int, w: int, h: int, a, b, chance: float, rng: random.Random) -> None:
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            canvas.set(xx, yy, a if rng.random() > chance else b)


def tile_grass(rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE)
    dither(c, 0, 0, TILE, TILE, GRASS, GRASS_DARK, 0.28, rng)
    for _ in range(6):
        c.set(rng.randrange(TILE), rng.randrange(TILE), LEAF)
    return c


def tile_grass_wet(rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE)
    dither(c, 0, 0, TILE, TILE, GRASS_WET, GRASS_DARK, 0.35, rng)
    for _ in range(3):
        xx, yy = rng.randrange(TILE - 2), rng.randrange(TILE - 2)
        c.set(xx, yy, PUDDLE)
        c.set(xx + 1, yy, PUDDLE_LIGHT)
    return c


def tile_road(rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE)
    dither(c, 0, 0, TILE, TILE, ROAD, ROAD_DARK, 0.32, rng)
    return c


def tile_puddle(rng: random.Random) -> Canvas:
    c = tile_road(rng)
    for yy in range(4, 12):
        for xx in range(3, 13):
            if (xx - 8) ** 2 / 18 + (yy - 8) ** 2 / 10 < 1:
                c.set(xx, yy, PUDDLE if (xx + yy) % 3 else PUDDLE_LIGHT)
    return c


def tile_yard(rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE)
    dither(c, 0, 0, TILE, TILE, YARD, YARD_DARK, 0.25, rng)
    return c


def tile_floor(_rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE, FLOOR)
    for x in range(0, TILE, 4):
        for y in range(TILE):
            c.set(x, y, YARD_DARK)
    return c


def tile_wall(_rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE, WALL)
    c.fill_rect(0, 0, 1, TILE, WALL_SHADOW)
    c.fill_rect(0, TILE - 1, TILE, 1, WALL_SHADOW)
    for y in range(3, TILE, 5):
        c.fill_rect(2, y, TILE - 3, 1, WALL_SHADOW)
    return c


def tile_roof(_rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE, ROOF)
    for y in range(TILE):
        shade = ROOF_DARK if y % 4 == 0 else ROOF
        for x in range(TILE):
            c.set(x, y, shade)
    c.fill_rect(0, 0, TILE, 1, ROOF_RIDGE)
    return c


def tile_bank(rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE)
    dither(c, 0, 0, TILE, TILE, BANK, BANK_WET, 0.4, rng)
    return c


def tile_water(base, highlight, rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE, base)
    for _ in range(5):
        c.set(rng.randrange(TILE), rng.randrange(TILE), highlight)
    for x in range(TILE):
        if rng.random() < 0.2:
            c.set(x, 4, highlight)
    return c


def tile_leaf(rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE, (0, 0, 0, 0))
    dither(c, 2, 2, 12, 12, LEAF, LEAF_DARK, 0.4, rng)
    c.fill_rect(7, 10, 2, 6, WOOD)
    return c


def tile_wood(_rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE, WOOD)
    for y in range(0, TILE, 4):
        c.fill_rect(0, y, TILE, 1, WOOD_DARK)
    return c


def tile_cistern(_rng: random.Random) -> Canvas:
    c = Canvas(TILE, TILE, YARD)
    c.fill_rect(3, 4, 10, 10, STONE_DARK)
    c.fill_rect(4, 5, 8, 8, CISTERN)
    c.fill_rect(5, 6, 6, 5, WATER_KNEE)
    c.fill_rect(6, 7, 4, 2, WATER_HIGHLIGHT)
    return c


def tile_deep(rng: random.Random) -> Canvas:
    return tile_water(WATER_DEEP, WATER_KNEE, rng)


TILE_FNS = [
    tile_grass,
    tile_grass_wet,
    tile_road,
    tile_puddle,
    tile_yard,
    tile_floor,
    tile_wall,
    tile_roof,
    tile_bank,
    lambda rng: tile_water(WATER, WATER_HIGHLIGHT, rng),
    lambda rng: tile_water(WATER_KNEE, WATER, rng),
    tile_deep,
    tile_leaf,
    tile_wood,
    tile_cistern,
]


def draw_character(facing: str, frame: int) -> Canvas:
    c = Canvas(CHAR_W, CHAR_H)
    # feet offset for walk
    left_foot = 0
    right_foot = 0
    if frame == 1:
        left_foot = -1
        right_foot = 1
    elif frame == 2:
        left_foot = 1
        right_foot = -1

    hair_top = 2
    # hair
    c.fill_rect(5, hair_top, 6, 5, HAIR)
    c.fill_rect(4, hair_top + 1, 8, 4, HAIR)
    c.set(5, hair_top, HAIR_LIGHT)
    # face
    c.fill_rect(6, hair_top + 4, 4, 4, SKIN)
    c.set(6, hair_top + 5, SKIN_SHADOW)
    c.set(9, hair_top + 5, SKIN_SHADOW)
    if facing == "down":
        c.set(6, hair_top + 5, HAIR)
        c.set(9, hair_top + 5, HAIR)
        c.set(7, hair_top + 7, SKIN_SHADOW)
    elif facing == "up":
        c.fill_rect(5, hair_top + 3, 6, 4, HAIR)
    elif facing == "left":
        c.fill_rect(4, hair_top + 3, 3, 4, HAIR)
        c.set(6, hair_top + 5, HAIR)
    elif facing == "right":
        c.fill_rect(9, hair_top + 3, 3, 4, HAIR)
        c.set(9, hair_top + 5, HAIR)

    # áo
    c.fill_rect(5, 11, 6, 8, AO)
    c.fill_rect(4, 12, 8, 6, AO)
    c.fill_rect(5, 12, 1, 6, AO_DARK)
    c.fill_rect(10, 12, 1, 6, AO_DARK)
    # pants
    c.fill_rect(6, 19, 4, 5, PANTS)
    # legs / bare feet
    c.fill_rect(5, 22 + left_foot, 2, 4, SKIN)
    c.fill_rect(9, 22 + right_foot, 2, 4, SKIN)
    c.set(5, 25 + left_foot, SKIN_SHADOW)
    c.set(10, 25 + right_foot, SKIN_SHADOW)
    return c


def make_character_sheet() -> Canvas:
    facings = ["down", "left", "right", "up"]
    frames = 3
    sheet = Canvas(CHAR_W * frames, CHAR_H * len(facings))
    for fy, facing in enumerate(facings):
        for fx in range(frames):
            sheet.blit(draw_character(facing, fx), fx * CHAR_W, fy * CHAR_H)
    return sheet


def make_yoke() -> Canvas:
    c = Canvas(32, 16)
    # pole
    c.fill_rect(1, 6, 30, 2, POLE)
    c.fill_rect(1, 5, 30, 1, WOOD)
    return c


def make_jugs() -> Canvas:
    # two frames: empty, full. 12x14 each
    c = Canvas(24, 14)
    for i, wet in enumerate((False, True)):
        ox = i * 12
        c.fill_rect(ox + 3, 2, 6, 10, JUG_DARK if wet else JUG)
        c.fill_rect(ox + 4, 3, 4, 8, JUG_WET if wet else JUG)
        c.fill_rect(ox + 5, 1, 2, 2, WOOD)
        if wet:
            c.fill_rect(ox + 5, 5, 2, 4, WATER_IN_JUG)
        else:
            c.fill_rect(ox + 5, 5, 2, 3, WALL_SHADOW)
    return c


def make_glass() -> Canvas:
    c = Canvas(8, 8)
    shards = [(2, 3), (3, 2), (4, 3), (3, 4), (5, 4), (2, 5), (4, 5)]
    for x, y in shards:
        c.set(x, y, GLASS)
        c.set(x + 1, y, GLASS_EDGE)
    c.set(3, 3, (255, 255, 240, 255))
    return c


def make_tileset() -> Canvas:
    rng = random.Random(7)
    n = len(TILE_FNS)
    sheet = Canvas(TILE * n, TILE)
    for i, fn in enumerate(TILE_FNS):
        sheet.blit(fn(rng), i * TILE, 0)
    return sheet


def main() -> None:
    os.makedirs(ASSETS, exist_ok=True)
    make_tileset().save(os.path.join(ASSETS, "tiles.png"))
    make_character_sheet().save(os.path.join(ASSETS, "water_carrier.png"))
    make_yoke().save(os.path.join(ASSETS, "yoke.png"))
    make_jugs().save(os.path.join(ASSETS, "jugs.png"))
    make_glass().save(os.path.join(ASSETS, "glass.png"))
    drop = Canvas(1, 4)
    drop.fill_rect(0, 0, 1, 4, (236, 224, 198, 140))
    drop.save(os.path.join(ASSETS, "rain.png"))
    print("wrote assets")


if __name__ == "__main__":
    main()
