"""Jefa final del sueño 1: Lilato (y su forma de serpiente), el súper cuchillo y la arena bajo el puente.
Vista de costado, mismo estilo que el pack de beat 'em up (celdas de 48x48, contorno casi negro).
Salida: assets/prologue/source/*.png (después correr apply_palette.py).
Uso: python tools/art/draw_lilato.py  (desde la carpeta del proyecto)"""
import random
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

random.seed(5)
OUT = Path("assets/prologue/source")
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)
C = 48
INK = (0, 0, 8, 255)
SKIN = (238, 206, 204, 255)
SKIN_SH = (204, 160, 170, 255)
HAIR = (54, 30, 66, 255)
HAIR_HI = (92, 56, 110, 255)
DRESS = (176, 136, 210, 255)
DRESS_SH = (128, 92, 168, 255)
TIGHTS = (48, 30, 58, 255)
EYE = (232, 40, 50, 255)
CLAW = (200, 30, 60, 255)
CLEAR = (0, 0, 0, 0)


def outline(img, color=INK):
    w, h = img.size
    src = img.copy()
    px, out = src.load(), img.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != color:
                        out[x, y] = color
                        break
    return img


# ======================================================================= LILATO
def lilato(front_hand=(26, 38), back_hand=(18, 38), feet=((19, 46), (24, 46)), hair_dx=0,
           claw_trail=False, arms_out=False, skirt=0):
    img = Image.new("RGBA", (C, C), CLEAR)
    d = ImageDraw.Draw(img)
    cx = 22
    # Pelo largo por detrás (cae por la espalda, se mueve).
    d.polygon([(cx - 4, 20), (cx + 2, 20), (cx + 1, 30), (cx - 6 + hair_dx, 37), (cx - 7 + hair_dx, 30)], fill=HAIR)
    # Brazo de atrás.
    d.line([(cx - 1, 29), back_hand], fill=SKIN_SH, width=2)
    d.point(back_hand, fill=CLAW)
    # Piernas (medias oscuras) y zapatos.
    for hip, foot in (((cx - 2, 40), feet[0]), ((cx + 1, 40), feet[1])):
        d.line([hip, foot], fill=TIGHTS, width=2)
        d.line([(foot[0], foot[1]), (foot[0] + 2, foot[1])], fill=INK)
    # Vestido: cuerpo y pollera acampanada.
    d.rectangle([cx - 3, 28, cx + 3, 33], fill=DRESS)
    d.polygon([(cx - 3, 33), (cx + 3, 33), (cx + 6 + skirt, 41), (cx - 6 - skirt, 41)], fill=DRESS)
    d.line([(cx - 3, 28), (cx - 3, 33)], fill=DRESS_SH)
    d.line([(cx - 6 - skirt, 41), (cx + 6 + skirt, 41)], fill=DRESS_SH)
    # Cabeza (mira a la derecha): flequillo, ojo rojo.
    d.rectangle([cx - 2, 21, cx + 3, 27], fill=SKIN)
    d.rectangle([cx - 3, 19, cx + 3, 22], fill=HAIR)
    d.point((cx + 2, 22), fill=HAIR_HI)
    d.point((cx + 2, 24), fill=EYE)
    d.point((cx + 3, 26), fill=SKIN_SH)
    # Brazo de adelante, con garras.
    d.line([(cx + 1, 29), front_hand], fill=SKIN, width=2)
    d.line([front_hand, (front_hand[0] + 1, front_hand[1] + 1)], fill=CLAW)
    if arms_out:
        d.line([(cx - 1, 29), (cx - 12, 29)], fill=SKIN, width=2)
        d.point((cx - 12, 29), fill=CLAW)
    outline(img)
    if claw_trail:  # rastro del zarpazo
        d2 = ImageDraw.Draw(img)
        for i in range(3):
            d2.arc([front_hand[0] - 8, front_hand[1] - 10 + i * 2, front_hand[0] + 6, front_hand[1] + 4 + i * 2],
                   280, 40, fill=(255, 210, 230, 220))
    return img


def rotated(img, deg, dy=0):
    """Rota alrededor de los pies (para golpeada / caída)."""
    big = Image.new("RGBA", (C * 2, C * 2), CLEAR)
    big.paste(img, (C // 2, C // 2))
    r = big.rotate(deg, center=(C // 2 + 22, C // 2 + 46), resample=Image.NEAREST)
    return r.crop((C // 2, C // 2 + dy, C // 2 + C, C // 2 + C + dy))


def silhouette(img, color):
    s = img.copy()
    px = s.load()
    for y in range(C):
        for x in range(C):
            if px[x, y][3] > 0:
                px[x, y] = color
    return s


def glow(img, color):
    """Contorno de color alrededor (para la transformación)."""
    g = Image.new("RGBA", img.size, CLEAR)
    src = img.load()
    out = g.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0), (0, -2)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        out[x, y] = color
                        break
    g.alpha_composite(img)
    return g


idle_a = lilato()
idle_b = lilato(front_hand=(26, 37), back_hand=(18, 37), hair_dx=-1)
walk = [
    lilato(front_hand=(27, 36), back_hand=(17, 38), feet=((17, 46), (26, 46)), hair_dx=-1),
    lilato(front_hand=(25, 38), back_hand=(19, 37), feet=((20, 46), (23, 46))),
    lilato(front_hand=(18, 37), back_hand=(26, 36), feet=((25, 46), (18, 46)), hair_dx=-1),
    lilato(front_hand=(25, 38), back_hand=(19, 37), feet=((21, 46), (22, 46))),
]
slash = [
    lilato(front_hand=(16, 22), back_hand=(18, 38), feet=((18, 46), (25, 46))),
    lilato(front_hand=(38, 29), back_hand=(16, 36), feet=((17, 46), (27, 46)), claw_trail=True, skirt=1),
    lilato(front_hand=(35, 37), back_hand=(17, 37), feet=((18, 46), (26, 46)), skirt=1),
]
spin = [
    lilato(front_hand=(35, 29), back_hand=(18, 38), arms_out=True, skirt=2, hair_dx=-3),
    lilato(front_hand=(35, 29), back_hand=(18, 38), arms_out=True, skirt=3, hair_dx=3).transpose(Image.FLIP_LEFT_RIGHT),
    lilato(front_hand=(35, 29), back_hand=(18, 38), arms_out=True, skirt=2, hair_dx=-3),
    lilato(front_hand=(35, 29), back_hand=(18, 38), arms_out=True, skirt=3, hair_dx=3).transpose(Image.FLIP_LEFT_RIGHT),
]
hurt = lilato(front_hand=(28, 22), back_hand=(14, 24), feet=((18, 46), (23, 46)), hair_dx=2)
rows = [
    [idle_a, idle_b],
    walk,
    slash,
    spin,
    [silhouette(hurt, (255, 255, 255, 255)), rotated(hurt, 8)],
    [rotated(idle_a, 30), rotated(idle_a, 75), rotated(idle_a, 90)],
    [rotated(idle_a, 20)],
    [glow(rotated(idle_a, 15), (110, 220, 90, 200)), glow(rotated(idle_a, 25), (170, 255, 120, 230))],
]
sheet = Image.new("RGBA", (C * 4, C * len(rows)), CLEAR)
for r, frames in enumerate(rows):
    for c, f in enumerate(frames):
        sheet.paste(f, (c * C, r * C))
sheet.save(OUT / "lilato.png")


# ======================================================================= SERPIENTE
SCALE = (96, 60, 120, 255)
SCALE_DK = (66, 40, 86, 255)
SCALE_HI = (130, 90, 150, 255)
BELLY = (196, 176, 120, 255)
SEYE = (240, 220, 60, 255)


def head(open_mouth):
    img = Image.new("RGBA", (52, 34), CLEAR)
    d = ImageDraw.Draw(img)
    d.ellipse([2, 6, 40, 30], fill=SCALE)  # cráneo
    d.polygon([(28, 10), (50, 14 if not open_mouth else 8), (50, 18 if not open_mouth else 12), (32, 20)], fill=SCALE)  # hocico
    if open_mouth:
        d.polygon([(30, 20), (50, 16), (50, 30), (30, 26)], fill=(160, 30, 50, 255))  # boca
        for x in (40, 46):
            d.polygon([(x, 16), (x + 2, 16), (x + 1, 21)], fill=(240, 240, 230, 255))  # colmillos
        d.polygon([(30, 26), (50, 30), (48, 33), (28, 30)], fill=BELLY)  # mandíbula
    else:
        d.polygon([(30, 20), (50, 18), (48, 23), (28, 26)], fill=BELLY)
    for _ in range(26):  # escamas
        x, y = random.randint(5, 36), random.randint(8, 24)
        d.point((x, y), fill=random.choice([SCALE_DK, SCALE_HI]))
    d.ellipse([24, 10, 31, 16], fill=SEYE)
    d.line([(27, 10), (28, 16)], fill=INK)
    return outline(img)


def body_seg(size):
    img = Image.new("RGBA", (size, size), CLEAR)
    d = ImageDraw.Draw(img)
    d.ellipse([1, 1, size - 2, size - 2], fill=SCALE)
    d.ellipse([3, size // 2, size - 4, size - 3], fill=BELLY)
    for k in range(0, size, 4):
        d.arc([k - 4, 2, k + 4, 10], 20, 160, fill=SCALE_DK)
    return outline(img)


head(False).save(OUT / "serpent_head.png")
head(True).save(OUT / "serpent_head_open.png")
body_seg(24).save(OUT / "serpent_body.png")
body_seg(14).save(OUT / "serpent_tail.png")

# Charco de veneno (dos cuadros).
for i in range(2):
    img = Image.new("RGBA", (28, 10), CLEAR)
    d = ImageDraw.Draw(img)
    d.ellipse([0, 1, 27, 9], fill=(90, 190, 70, 210))
    d.ellipse([4, 2, 22, 7], fill=(140, 230, 90, 220))
    for x in ((6, 15), (19, 9))[i]:
        pass
    d.ellipse([6 + i * 8, 3, 9 + i * 8, 6], fill=(200, 255, 160, 255))
    img.save(OUT / f"venom_{i}.png")


# ======================================================================= SÚPER CUCHILLO
GOLD = (250, 214, 100, 255)
GOLD_HI = (255, 250, 210, 255)
AURA = (200, 120, 255, 150)


def gild(src_path, out_path):
    """Cuchillo dorado con un aura violeta alrededor."""
    img = Image.open(src_path).convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            lum = (r + g + b) / 3
            px[x, y] = GOLD_HI if lum > 170 else (GOLD if lum > 70 else (120, 60, 140, 255))
    aura = Image.new("RGBA", img.size, CLEAR)
    ap = aura.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0:
                        ap[x, y] = AURA
                        break
    aura.alpha_composite(img)
    aura.save(out_path)


gild(OUT / "player_knife.png", OUT / "player_superknife.png")
gild(OUT / "item_knife.png", OUT / "item_superknife.png")


# ======================================================================= ARENA: BAJO EL PUENTE
W, H = 320, 180
bg = Image.new("RGBA", (W, H), (22, 20, 30, 255))
d = ImageDraw.Draw(bg)
# Río al fondo con reflejos.
d.rectangle([0, 84, W, 122], fill=(30, 44, 46, 255))
for y in range(88, 122, 5):
    for x in range(random.randint(0, 20), W, random.randint(30, 60)):
        d.line([(x, y), (x + random.randint(4, 12), y)], fill=(60, 84, 80, 255))
# Orilla de enfrente (siluetas de casillas con alguna luz).
x = 0
while x < W:
    w = random.randint(18, 40)
    h = random.randint(10, 26)
    d.rectangle([x, 84 - h, x + w - 2, 84], fill=(34, 30, 44, 255))
    if random.random() < 0.4:
        d.rectangle([x + 4, 84 - h + 4, x + 6, 84 - h + 6], fill=(220, 200, 120, 255))
    x += w
# Piso: hormigón con barro y charcos.
d.rectangle([0, 122, W, H], fill=(84, 80, 86, 255))
for _ in range(400):
    px_, py_ = random.randint(0, W - 1), random.randint(124, H - 1)
    d.point((px_, py_), fill=random.choice([(54, 50, 56, 255), (76, 72, 76, 255), (70, 60, 50, 255)]))
for _ in range(6):
    cx_, cy_ = random.randint(20, 300), random.randint(140, 170)
    d.ellipse([cx_ - 14, cy_ - 3, cx_ + 14, cy_ + 3], fill=(40, 52, 60, 255))
    d.line([(cx_ - 6, cy_ - 1), (cx_ + 2, cy_ - 1)], fill=(80, 100, 110, 255))
d.line([(0, 122), (W, 122)], fill=(40, 38, 44, 255))
# Tablero del puente arriba, con vigas.
d.rectangle([0, 0, W, 30], fill=(52, 50, 60, 255))
for x in range(0, W, 40):
    d.rectangle([x, 22, x + 6, 34], fill=(40, 38, 48, 255))
d.line([(0, 34), (W, 34)], fill=INK)
# Pilares con grafitis.
for px_ in (18, 266):
    d.rectangle([px_, 30, px_ + 36, 130], fill=(86, 82, 90, 255), outline=INK)
    d.rectangle([px_, 30, px_ + 6, 130], fill=(70, 66, 74, 255))
    for _ in range(40):
        d.point((random.randint(px_ + 1, px_ + 35), random.randint(32, 128)), fill=(100, 96, 102, 255))
d.text((24, 90), "LILA", font=FONT, fill=(170, 110, 200, 255))
d.line([(272, 70), (280, 62), (288, 72), (296, 64)], fill=(90, 160, 210, 255), width=2)
# Su campamento (eco de la vida real): cartones y una frazada.
d.polygon([(60, 128), (80, 122), (104, 125), (108, 132), (64, 134)], fill=(150, 124, 86, 255), outline=INK)
d.rectangle([84, 124, 94, 129], fill=(90, 60, 70, 255))
# Farol con halo.
d.rectangle([150, 40, 151, 122], fill=(50, 48, 58, 255))
d.rectangle([146, 38, 156, 41], fill=(230, 220, 160, 255))
# Luz del farol sobre el piso (un óvalo tenue, no un halo en el aire).
pool = Image.new("RGBA", (W, H), CLEAR)
ImageDraw.Draw(pool).ellipse([96, 124, 206, 160], fill=(230, 210, 150, 40))
bg.alpha_composite(pool)
bg.save(OUT / "bridge_bg.png")

print("lilato: arte listo")
