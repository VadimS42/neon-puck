"""Draws Neon Puck's flat neon UI icons (tips coin, hearts, power-ups) into
art/ui/icons/. Original shapes drawn here, so no licence to track.
   python3 tools/make_icons.py
Replace any PNG with commissioned art of the same name whenever you like."""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art/ui/icons")
S = 512  # drawn big, saved at 128
PINK = (255, 79, 139)
CYAN = (63, 215, 255)
GOLD = (255, 201, 79)
GREEN = (91, 227, 143)
PURPLE = (185, 140, 255)
ORANGE = (255, 159, 67)
INK = (246, 238, 255)


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def save(im, name, glow):
    # Soft neon glow under the shape.
    a = im.split()[3]
    g = Image.new("RGBA", (S, S), glow + (0,))
    g.putalpha(a.filter(ImageFilter.GaussianBlur(18)).point(lambda v: int(v * 0.7)))
    out = Image.alpha_composite(g, im).resize((128, 128), Image.LANCZOS)
    out.save(os.path.join(OUT, name + ".png"))


def heart_poly(cx, cy, r):
    pts = []
    for i in range(120):
        t = i / 120 * 2 * math.pi
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * r / 17, cy - y * r / 17))
    return pts


def heart(full):
    im = canvas()
    d = ImageDraw.Draw(im)
    p = heart_poly(256, 270, 200)
    if full:
        d.polygon(p, fill=PINK)
        d.ellipse((150, 150, 210, 210), fill=(255, 170, 200))
    else:
        d.line(p + [p[0]], fill=(120, 100, 170), width=34, joint="curve")
    save(im, "heart_full" if full else "heart_empty", PINK if full else (90, 70, 140))


def coin():
    im = canvas()
    d = ImageDraw.Draw(im)
    d.ellipse((56, 56, 456, 456), fill=GOLD)
    d.ellipse((106, 106, 406, 406), outline=(200, 140, 30), width=22)
    # A "T" for tips.
    d.rectangle((176, 170, 336, 214), fill=(200, 140, 30))
    d.rectangle((234, 170, 278, 350), fill=(200, 140, 30))
    save(im, "coin", GOLD)


def energy():  # a can
    im = canvas()
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((150, 90, 362, 440), 40, fill=CYAN)
    d.rectangle((150, 180, 362, 340), fill=(20, 120, 160))
    d.polygon([(270, 190), (215, 270), (255, 270), (235, 330), (300, 245), (258, 245)], fill=GOLD)
    d.rounded_rectangle((180, 70, 332, 104), 12, fill=(180, 230, 245))
    save(im, "energy", CYAN)


def grip():  # tape roll
    im = canvas()
    d = ImageDraw.Draw(im)
    d.ellipse((70, 70, 442, 442), outline=INK, width=100)
    d.ellipse((70, 70, 442, 442), outline=CYAN, width=18)
    d.ellipse((166, 166, 346, 346), outline=CYAN, width=10)
    d.polygon([(400, 330), (470, 360), (450, 420), (380, 390)], fill=INK)
    save(im, "grip", CYAN)


def spotlight():
    im = canvas()
    d = ImageDraw.Draw(im)
    d.polygon([(220, 60), (292, 60), (430, 440), (82, 440)], fill=(255, 240, 180, 150))
    d.rounded_rectangle((196, 40, 316, 120), 18, fill=GOLD)
    d.ellipse((90, 400, 422, 470), fill=(255, 240, 180, 200))
    save(im, "spotlight", GOLD)


def hype():  # music notes
    im = canvas()
    d = ImageDraw.Draw(im)
    d.ellipse((90, 330, 210, 430), fill=PURPLE)
    d.ellipse((290, 290, 410, 390), fill=PURPLE)
    d.rectangle((182, 110, 212, 390), fill=PURPLE)
    d.rectangle((382, 70, 412, 350), fill=PURPLE)
    d.polygon([(182, 110), (412, 70), (412, 140), (182, 180)], fill=PURPLE)
    save(im, "hype", PURPLE)


def wink():  # winking eye
    im = canvas()
    d = ImageDraw.Draw(im)
    d.arc((80, 150, 432, 420), 200, 340, fill=PINK, width=40)
    for x in (150, 230, 310):
        d.line((x + 20, 240, x - 5, 175), fill=PINK, width=26)
    d.arc((120, 260, 392, 420), 20, 160, fill=PINK, width=30)
    save(im, "wink", PINK)


def sugar():  # lightning bolt
    im = canvas()
    d = ImageDraw.Draw(im)
    d.polygon([(300, 40), (110, 290), (240, 290), (190, 470), (400, 200), (270, 200), (330, 40)], fill=GREEN)
    save(im, "sugar", GREEN)


def comeback():  # circular arrow
    im = canvas()
    d = ImageDraw.Draw(im)
    d.arc((90, 90, 422, 422), 40, 330, fill=ORANGE, width=56)
    ang = math.radians(330)
    cx, cy, r = 256, 256, 166
    tip = (cx + r * math.cos(ang), cy + r * math.sin(ang))
    d.polygon([(tip[0] + 70, tip[1] - 10), (tip[0] - 40, tip[1] - 80), (tip[0] - 20, tip[1] + 60)], fill=ORANGE)
    save(im, "comeback", ORANGE)


os.makedirs(OUT, exist_ok=True)
for f in (lambda: heart(True), lambda: heart(False), coin, energy, grip, spotlight, hype, wink, sugar, comeback):
    f()
print("icons written to", OUT)
