"""Draws the free-to-play icons for the Google Play build (gem, life, ad)
into art/ui/icons/, in the same flat neon style as tools/make_icons.py.
   python3 tools/make_f2p_icons.py
Replace any PNG with commissioned art of the same name whenever you like."""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art/ui/icons")
S = 512
PINK = (255, 79, 139)
CYAN = (63, 215, 255)
GOLD = (255, 201, 79)


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def save(im, name, glow):
    a = im.split()[3]
    g = Image.new("RGBA", (S, S), glow + (0,))
    g.putalpha(a.filter(ImageFilter.GaussianBlur(18)).point(lambda v: int(v * 0.7)))
    Image.alpha_composite(g, im).resize((128, 128), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))


def heart_poly(cx, cy, r):
    pts = []
    for i in range(120):
        t = i / 120 * 2 * math.pi
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * r / 17, cy - y * r / 17))
    return pts


def gem():
    im = canvas()
    d = ImageDraw.Draw(im)
    top, mid, bot = 90, 200, 440
    d.polygon([(150, top), (362, top), (450, mid), (256, bot), (62, mid)], fill=CYAN)
    d.polygon([(150, top), (362, top), (310, mid), (202, mid)], fill=(170, 240, 255))
    d.polygon([(62, mid), (202, mid), (256, bot)], fill=(40, 170, 220))
    d.polygon([(202, mid), (310, mid), (256, bot)], fill=(110, 225, 255))
    save(im, "gem", CYAN)


def life():
    im = canvas()
    d = ImageDraw.Draw(im)
    d.ellipse((40, 40, 472, 472), fill=(40, 26, 70), outline=PINK, width=26)
    d.polygon(heart_poly(256, 268, 140), fill=PINK)
    save(im, "life", PINK)


def ad():
    im = canvas()
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((50, 100, 462, 412), radius=60, fill=GOLD)
    d.polygon([(205, 175), (205, 337), (345, 256)], fill=(40, 26, 70))
    save(im, "ad", GOLD)


if __name__ == "__main__":
    gem()
    life()
    ad()
    print("ok")
