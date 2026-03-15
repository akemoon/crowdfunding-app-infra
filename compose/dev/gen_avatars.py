"""
Generates pixel art smiley avatars into ./default-avatars/
Run: python gen_avatars.py
Requires: pip install pillow
"""

import os
from PIL import Image

SCALE = 10   # each pixel art cell = 10x10 actual pixels
G = 16       # grid size 16x16
PADDING = 2  # white cells around the face

WHITE = (255, 255, 255)
BLACK = (30, 30, 30)

FACE_SHAPE = [
    [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
]

# (row, col) pixels to paint black
EYES_NORMAL = [
    (5,4),(5,5),(6,4),(6,5),
    (5,10),(5,11),(6,10),(6,11),
]

EYES_DOT = [
    (5,4),(5,11),
]

SMILE_NORMAL = [
    (10,4),(10,11),
    (11,5),(11,6),(11,7),(11,8),(11,9),(11,10),
]

SMILE_BIG = [
    (9,4),(9,11),
    (10,3),(10,12),
    (11,4),(11,5),(11,6),(11,7),(11,8),(11,9),(11,10),(11,11),
]

GLASSES = [
    # left lens
    (4,3),(4,4),(4,5),(4,6),
    (5,3),(5,6),
    (6,3),(6,4),(6,5),(6,6),
    # bridge
    (5,7),(5,8),
    # right lens
    (4,9),(4,10),(4,11),(4,12),
    (5,9),(5,12),
    (6,9),(6,10),(6,11),(6,12),
]

AVATARS = [
    {"color": (255, 218,  90), "eyes": EYES_NORMAL, "smile": SMILE_NORMAL, "glasses": False},
    {"color": (130, 210, 255), "eyes": EYES_NORMAL, "smile": SMILE_BIG,    "glasses": True },
    {"color": (140, 235, 170), "eyes": EYES_DOT,    "smile": SMILE_NORMAL, "glasses": False},
    {"color": (255, 175, 200), "eyes": EYES_NORMAL, "smile": SMILE_BIG,    "glasses": False},
    {"color": (255, 195, 130), "eyes": EYES_NORMAL, "smile": SMILE_NORMAL, "glasses": True },
    {"color": (205, 165, 255), "eyes": EYES_DOT,    "smile": SMILE_BIG,    "glasses": False},
]


def draw_pixel(pixels, row, col, color, offset=0):
    for dy in range(SCALE):
        for dx in range(SCALE):
            pixels[(col + offset) * SCALE + dx, (row + offset) * SCALE + dy] = color


def generate(index, cfg):
    size = (G + PADDING * 2) * SCALE
    img = Image.new("RGB", (size, size), WHITE)
    px = img.load()

    face_color = cfg["color"]

    for r in range(G):
        for c in range(G):
            if FACE_SHAPE[r][c]:
                draw_pixel(px, r, c, face_color, offset=PADDING)

    for (r, c) in cfg["eyes"]:
        draw_pixel(px, r, c, BLACK, offset=PADDING)

    for (r, c) in cfg["smile"]:
        draw_pixel(px, r, c, BLACK, offset=PADDING)

    if cfg["glasses"]:
        for (r, c) in GLASSES:
            draw_pixel(px, r, c, BLACK, offset=PADDING)

    out = os.path.join("default-avatars", f"avatar-{index + 1}.png")
    img.save(out)
    print(f"saved {out}")


if __name__ == "__main__":
    os.makedirs("default-avatars", exist_ok=True)
    for i, cfg in enumerate(AVATARS):
        generate(i, cfg)

    print("done")