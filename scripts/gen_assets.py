#!/usr/bin/env python3
"""Generate CLonUI brand assets: clean geometric app icon + README banner."""
import math, random
from PIL import Image, ImageDraw, ImageFilter

OUT = "/home/yassin/clonui"

# Sleek palette (no clown circus colors)
INK   = (26, 27, 38)       # near-black
SLATE = (54, 58, 79)
ACCENT= (99, 102, 241)      # indigo
ACCENT2 = (34, 211, 238)    # cyan
WHITE = (255, 255, 255)
PAPER = (244, 245, 250)
MUTED = (148, 153, 178)

def rounded(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)

def draw_mark(size):
    """CLonUI monogram: interlocking C + L in a rounded tile."""
    img = Image.new("RGBA", (size, size), (0,0,0,0))
    d = ImageDraw.Draw(img)
    pad = size * 0.12
    rounded(d, [pad, pad, size-pad, size-pad], size*0.22, fill=INK)
    # accent gradient band
    band = Image.new("RGBA", (size, size), (0,0,0,0))
    bd = ImageDraw.Draw(band)
    for i in range(size):
        t = i/size
        c = tuple(int(ACCENT[j]*(1-t) + ACCENT2[j]*t) for j in range(3))
        bd.line([(0,i),(size,i)], fill=c+(255,))
    band = band.filter(ImageFilter.GaussianBlur(size*0.04))
    # mask to tile
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([pad,pad,size-pad,size-pad], radius=size*0.22, fill=255)
    img = Image.composite(band, img, mask)

    d = ImageDraw.Draw(img)
    cx, cy = size/2, size/2
    sw = size*0.085  # stroke width
    # "C" arc
    r = size*0.26
    d.arc([cx-r, cy-r, cx+r, cy+r], start=60, end=300, fill=WHITE, width=int(sw))
    # "L" bar
    lx = cx + size*0.02
    d.line([(lx, cy-r*0.95),(lx, cy+r*0.95)], fill=WHITE, width=int(sw))
    d.line([(lx, cy+r*0.95),(lx+r*0.95, cy+r*0.95)], fill=WHITE, width=int(sw))
    return img

def draw_banner(w=1200, h=480):
    img = Image.new("RGBA", (w, h), PAPER)
    d = ImageDraw.Draw(img)
    # subtle dot grid
    step = 38
    for y in range(step, h, step):
        for x in range(step, w, step):
            d.ellipse([x-1.5, y-1.5, x+1.5, y+1.5], fill=(210,213,228,255))
    # faint accent corner glow
    glow = Image.new("RGBA", (w, h), (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    for _ in range(3):
        gd.ellipse([-100,-100, 500, 500], fill=ACCENT+(18,))
        gd.ellipse([w-400,h-400, w+100, h+100], fill=ACCENT2+(16,))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img)

    # mark on the left
    mark = draw_mark(h).resize((h, h))
    img.alpha_composite(mark, (int(w*0.05), 0))

    try:
        from PIL import ImageFont
        big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(h*0.30))
        small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(h*0.11))
    except Exception:
        big = small = ImageDraw.getfont()

    tx = int(w*0.48)
    d.text((tx, int(h*0.30)), "CLonUI", font=big, fill=INK)
    d.text((tx, int(h*0.63)), "Cowork with AI Agents", font=small, fill=ACCENT)
    return img

if __name__ == "__main__":
    mark = draw_mark(1024)
    mark.save(f"{OUT}/resources/app.png")
    mark.save(f"{OUT}/resources/icon.png")
    mark.resize((512,512)).save(f"{OUT}/public/pwa/icon-512.png")
    mark.resize((192,192)).save(f"{OUT}/public/pwa/icon-192.png")
    mark.resize((180,180)).save(f"{OUT}/public/pwa/icon-180.png")
    mark.resize((1024,1024)).save(f"{OUT}/mobile/assets/images/icon.png")
    mark.save(f"{OUT}/resources/app.ico", sizes=[(256,256),(128,128),(64,64),(48,48),(32,32),(16,16)])
    banner = draw_banner(1200, 480)
    banner.save(f"{OUT}/resources/clonui-banner-1.png")
    print("CLonUI assets generated")
