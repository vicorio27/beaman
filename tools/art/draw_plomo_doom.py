"""PLOMO (el Dealer) más a lo Doom: paredes de 64x64 con relieve, mugre y luz, pisos y techos (los
dibuja el shader de piso), cosas del decorado (faroles, canecas con fuego, carros quemados) y los
personajes de la historia de Lisandro (Billete, el perro; el pelado; el teléfono de la mamá...).
Salida (assets/shooter/):
  wall_dd_*.png        paredes 64x64
  dd_suelos.png        atlas de pisos y techos (fila de cuadros de 64x64, en el orden de FLATS)
  dd_<cosa>.png        decorado y personajes
Uso: python tools/art/draw_plomo_doom.py  (desde la carpeta del proyecto)"""
import math
import random
from PIL import Image, ImageDraw
from draw_shooter import OUT, INK, outline

random.seed(1993)
S = 64
FLATS = ["asfalto", "anden", "baldosa", "madera", "marmol", "techo_cocina", "techo_casa", "tierra"]


def clamp(v):
    return max(0, min(255, int(v)))


def shade(c, k):
    return tuple(clamp(v * k) for v in c[:3]) + (255,)


def noise(img, amount, box=None, seed_k=1.0):
    px = img.load()
    x0, y0, x1, y1 = box or (0, 0, img.width, img.height)
    for y in range(y0, y1):
        for x in range(x0, x1):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            k = 1.0 + random.uniform(-amount, amount) * seed_k
            px[x, y] = (clamp(r * k), clamp(g * k), clamp(b * k), a)


def grime(img, strength=0.45, from_y=0.55):
    """Mugre que sube desde el piso (oscurece abajo), con chorreones."""
    px = img.load()
    w, h = img.size
    drips = [random.randrange(w) for _ in range(5)]
    for y in range(h):
        t = max(0.0, (y / h - from_y) / (1 - from_y))
        for x in range(w):
            k = 1.0 - strength * t * (0.8 + 0.2 * random.random())
            if x in drips and y > h * 0.25:
                k *= 0.82
            r, g, b, a = px[x, y]
            px[x, y] = (clamp(r * k), clamp(g * k * 0.98), clamp(b * k * 0.95), a)


def bevel(d, box, base, hi=1.25, lo=0.6, w=1):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=shade(base, 1.0))
    for i in range(w):
        d.line([(x0 + i, y0 + i), (x1 - i, y0 + i)], fill=shade(base, hi))
        d.line([(x0 + i, y0 + i), (x0 + i, y1 - i)], fill=shade(base, hi * 0.95))
        d.line([(x0 + i, y1 - i), (x1 - i, y1 - i)], fill=shade(base, lo))
        d.line([(x1 - i, y0 + i), (x1 - i, y1 - i)], fill=shade(base, lo * 1.1))


def crack(d, x, y, n, col):
    for _ in range(n):
        nx, ny = x + random.randint(-2, 2), y + random.randint(1, 3)
        d.line([(x, y), (nx, ny)], fill=col)
        x, y = nx, ny


def crayon_line(d, pts, col, w=2):
    pts = [(x + random.randint(-1, 1), y + random.randint(-1, 1)) for x, y in pts]
    d.line(pts, fill=col, width=w)


def new(col=(0, 0, 0)):
    img = Image.new("RGBA", (S, S), tuple(col) + (255,))
    return img, ImageDraw.Draw(img)


def save_wall(img, name):
    img.save(OUT / f"wall_dd_{name}.png")


# ------------------------------------------------------------------ paredes

def w_ladrillo():
    img, d = new((38, 30, 30))
    for row in range(8):
        off = 0 if row % 2 == 0 else 8
        for col in range(-1, 5):
            x = col * 16 + off
            base = random.choice([(116, 46, 38), (128, 54, 42), (100, 40, 36), (136, 62, 46), (92, 44, 40)])
            bevel(d, (x + 1, row * 8 + 1, x + 15, row * 8 + 7), base, 1.22, 0.62)
    noise(img, 0.14)
    for _ in range(4):
        crack(d, random.randrange(S), random.randrange(40), 8, (30, 20, 20, 255))
    grime(img, 0.55, 0.45)
    save_wall(img, "ladrillo")


def w_dibujos():
    """Concreto del barrio con un dibujo de niño (casa, sol, la familia de palitos) tachado en rojo."""
    img, d = new((84, 82, 84))
    noise(img, 0.12)
    for x in (0, 32):  # juntas de las placas
        d.line([(x, 0), (x, S)], fill=(52, 50, 54, 255))
        d.line([(x + 1, 0), (x + 1, S)], fill=(104, 102, 104, 255))
    d.line([(0, 40), (S, 40)], fill=(52, 50, 54, 255))
    # el dibujo
    d.ellipse([6, 6, 18, 18], outline=(230, 190, 60, 255), width=2)
    for a in range(0, 360, 45):
        r = math.radians(a)
        d.line([(12 + 8 * math.cos(r), 12 + 8 * math.sin(r)), (12 + 11 * math.cos(r), 12 + 11 * math.sin(r))], fill=(230, 190, 60, 255))
    crayon_line(d, [(30, 30), (40, 20), (50, 30), (30, 30)], (200, 70, 60))
    crayon_line(d, [(32, 30), (32, 42), (48, 42), (48, 30)], (210, 200, 180))
    for k, x in enumerate((14, 21, 26)):
        hh = 10 if k < 2 else 6
        d.ellipse([x - 2, 44 - hh - 4, x + 2, 44 - hh], outline=(60, 120, 200, 255))
        crayon_line(d, [(x, 44 - hh), (x, 48)], (60, 120, 200), 1)
        crayon_line(d, [(x - 3, 44 - hh + 3), (x + 3, 44 - hh + 3)], (60, 120, 200), 1)
    # tachado
    crayon_line(d, [(4, 4), (56, 52)], (190, 24, 34), 3)
    crayon_line(d, [(56, 6), (6, 54)], (190, 24, 34), 3)
    grime(img, 0.5, 0.5)
    noise(img, 0.06)
    save_wall(img, "dibujos")


def w_persiana():
    """Persiana de local cerrado: metal ondulado, óxido y una L pintada (el barrio es de Lisandro)."""
    img, d = new((70, 74, 80))
    for y in range(0, S, 4):
        d.line([(0, y), (S, y)], fill=(104, 108, 116, 255))
        d.line([(0, y + 1), (S, y + 1)], fill=(86, 90, 98, 255))
        d.line([(0, y + 3), (S, y + 3)], fill=(46, 48, 54, 255))
    d.rectangle([0, 58, S, S], fill=(40, 40, 44, 255))
    d.rectangle([28, 56, 36, 59], fill=(150, 150, 150, 255))  # la manija
    noise(img, 0.1)
    px = img.load()
    for _ in range(9):  # óxido
        cx, cy, r = random.randrange(S), random.randrange(S), random.randint(2, 6)
        for y in range(cy - r, cy + r):
            for x in range(cx - r, cx + r):
                if 0 <= x < S and 0 <= y < S and (x - cx) ** 2 + (y - cy) ** 2 < r * r and random.random() < 0.7:
                    c = px[x, y]
                    px[x, y] = (clamp(c[0] * 1.3 + 30), clamp(c[1] * 0.85 + 6), clamp(c[2] * 0.5), 255)
    gold = (230, 180, 50)
    crayon_line(d, [(20, 12), (20, 44), (40, 44)], gold, 5)
    crayon_line(d, [(16, 50), (46, 50)], (200, 40, 50), 2)
    grime(img, 0.4, 0.6)
    save_wall(img, "persiana")


def w_contenedor():
    """Bloque de concreto con franjas de peligro (los carros quemados y las barreras)."""
    img, d = new((96, 92, 86))
    noise(img, 0.12)
    bevel(d, (1, 1, 62, 62), (98, 94, 88), 1.2, 0.55, 2)
    noise(img, 0.08)
    for i in range(-4, 10):
        x = i * 10
        d.polygon([(x, 46), (x + 5, 46), (x + 13, 58), (x + 8, 58)], fill=(220, 180, 40, 255))
    d.rectangle([0, 44, S, 45], fill=(40, 38, 36, 255))
    d.rectangle([0, 59, S, 60], fill=(40, 38, 36, 255))
    for x in (8, 56):
        d.ellipse([x - 2, 8, x + 2, 12], fill=(60, 58, 54, 255))
    grime(img, 0.5, 0.35)
    save_wall(img, "contenedor")


def w_cocina():
    """La cocina: baldosa blanca manchada, una tubería con fuga verde y un mesón con ollas."""
    img, d = new((60, 64, 60))
    for ty in range(0, 40, 8):
        for tx in range(0, S, 8):
            base = random.choice([(186, 192, 180), (176, 184, 172), (196, 198, 186)])
            bevel(d, (tx + 1, ty + 1, tx + 7, ty + 7), base, 1.12, 0.78)
    d.rectangle([0, 40, S, 43], fill=(110, 112, 116, 255))  # el mesón
    d.rectangle([0, 44, S, S], fill=(64, 52, 44, 255))
    for x in (4, 34):
        d.rectangle([x, 26, x + 20, 39], fill=(120, 124, 132, 255))
        d.rectangle([x + 1, 27, x + 19, 29], fill=(160, 164, 170, 255))
        d.rectangle([x - 2, 26, x + 22, 27], fill=(80, 84, 92, 255))
        for k in range(3):  # el humo verde
            crayon_line(d, [(x + 6 + k * 4, 24), (x + 4 + k * 4, 14), (x + 8 + k * 4, 4)], (120, 230, 90), 1)
    d.rectangle([56, 0, 59, 40], fill=(100, 96, 90, 255))  # la tubería
    d.rectangle([54, 18, 61, 21], fill=(80, 76, 72, 255))
    noise(img, 0.12)
    px = img.load()
    for _ in range(14):  # manchas
        cx, cy = random.randrange(S), random.randrange(40)
        for k in range(random.randint(6, 18)):
            x, y = cx + random.randint(-3, 3), cy + random.randint(0, 6)
            if 0 <= x < S and 0 <= y < S:
                c = px[x, y]
                px[x, y] = (clamp(c[0] * 0.72), clamp(c[1] * 0.76), clamp(c[2] * 0.6), 255)
    for y in range(22, 40):
        if random.random() < 0.8:
            px[57, y] = (110, 220, 90, 255)
    grime(img, 0.4, 0.5)
    save_wall(img, "cocina")


def w_cajas():
    """La bodega: cajas de madera apiladas (las de Doom, pero con 'FRÁGIL' y plata adentro)."""
    img, d = new((40, 30, 20))
    for bx, by in ((0, 0), (32, 0), (0, 32), (32, 32)):
        base = random.choice([(132, 96, 56), (120, 86, 50), (140, 104, 62)])
        bevel(d, (bx + 1, by + 1, bx + 30, by + 30), base, 1.25, 0.55, 2)
        for k in range(4, 28, 6):
            d.line([(bx + 3, by + k), (bx + 28, by + k)], fill=shade(base, 0.8))
        d.line([(bx + 4, by + 4), (bx + 27, by + 27)], fill=shade(base, 0.7), width=3)
        d.line([(bx + 4, by + 4), (bx + 27, by + 27)], fill=shade(base, 1.15), width=1)
    d.rectangle([36, 12, 58, 18], fill=(170, 40, 30, 255))
    d.text((37, 11), "$$$", fill=(240, 220, 160, 255))
    noise(img, 0.12)
    grime(img, 0.35, 0.55)
    save_wall(img, "cajas")


def w_oro():
    """La casa de Lisandro: mármol negro, molduras de oro y su L. Todo lo que se compra con miedo."""
    img, d = new((24, 20, 26))
    px = img.load()
    for y in range(S):  # vetas del mármol
        for x in range(S):
            v = math.sin(x * 0.18 + math.sin(y * 0.11) * 3.0 + y * 0.05)
            k = 1.0 + 0.5 * max(0.0, v - 0.75) * 4
            px[x, y] = (clamp(30 * k), clamp(26 * k), clamp(34 * k), 255)
    gold = (226, 182, 64)
    bevel(d, (0, 0, 63, 5), gold, 1.3, 0.55)
    bevel(d, (0, 56, 63, 63), gold, 1.3, 0.55)
    d.rectangle([12, 14, 51, 47], outline=shade(gold, 0.8), width=2)
    d.rectangle([13, 15, 50, 46], outline=shade(gold, 1.25), width=1)
    # la L
    d.rectangle([24, 20, 29, 40], fill=gold)
    d.rectangle([24, 36, 41, 40], fill=gold)
    d.line([(24, 20), (29, 20)], fill=shade(gold, 1.35))
    d.line([(24, 40), (41, 40)], fill=shade(gold, 0.6))
    noise(img, 0.06)
    save_wall(img, "oro")


def w_marmol():
    img, d = new((200, 196, 188))
    px = img.load()
    for y in range(S):
        for x in range(S):
            v = math.sin(x * 0.09 + math.sin(y * 0.07 + x * 0.02) * 4.0)
            k = 1.0 - 0.35 * max(0.0, v - 0.8) * 5
            px[x, y] = (clamp(206 * k), clamp(200 * k), clamp(190 * k), 255)
    gold = (226, 182, 64)
    for x in (0, 31, 32, 63):
        d.line([(x, 0), (x, S)], fill=shade(gold, 0.9))
    bevel(d, (0, 50, 63, 56), gold, 1.3, 0.55)
    noise(img, 0.05)
    grime(img, 0.25, 0.7)
    save_wall(img, "marmol")


def w_columna():
    """Pilar de concreto con un aviso de 'SE VENDE' arrancado (para las columnas sueltas)."""
    img, d = new((90, 88, 84))
    noise(img, 0.12)
    for x in range(S):
        k = 0.7 + 0.5 * math.sin(x / S * math.pi)
        for y in range(S):
            c = img.getpixel((x, y))
            img.putpixel((x, y), shade(c, k))
    d.rectangle([18, 20, 44, 34], fill=(220, 210, 150, 255))
    d.polygon([(30, 34), (44, 34), (44, 26)], fill=(90, 88, 84, 255))
    d.text((20, 22), "SE", fill=(170, 30, 30, 255))
    grime(img, 0.5, 0.5)
    save_wall(img, "columna")


def door(name, light):
    img, d = new((30, 30, 34))
    base = (88, 90, 98)
    bevel(d, (0, 0, 63, 63), (60, 60, 66), 1.2, 0.5, 3)
    bevel(d, (6, 6, 57, 63), base, 1.25, 0.55, 2)
    for y in (16, 34, 52):
        d.line([(8, y), (55, y)], fill=shade(base, 0.6))
        d.line([(8, y + 1), (55, y + 1)], fill=shade(base, 1.2))
    d.line([(32, 6), (32, 63)], fill=shade(base, 0.45), width=2)  # la juntura del medio
    for i in range(0, 64, 8):  # franjas de peligro a los lados
        d.polygon([(0, i), (5, i), (5, i + 4), (0, i + 8)], fill=(210, 170, 40, 255))
        d.polygon([(58, i + 4), (63, i), (63, i + 4), (58, i + 8)], fill=(210, 170, 40, 255))
    if light:
        d.rectangle([24, 22, 40, 30], fill=(20, 10, 10, 255))
        d.rectangle([25, 23, 39, 29], fill=light)
        d.rectangle([27, 24, 37, 25], fill=shade(light, 1.4))
        d.rectangle([29, 38, 35, 46], fill=(226, 182, 64, 255))  # el candado de oro
        d.arc([28, 33, 36, 41], 180, 360, fill=(226, 182, 64, 255), width=2)
    noise(img, 0.08)
    grime(img, 0.3, 0.6)
    save_wall(img, name)


def w_salida():
    img, d = new((24, 22, 26))
    bevel(d, (0, 0, 63, 63), (60, 58, 62), 1.2, 0.5, 3)
    d.rectangle([8, 18, 55, 34], fill=(16, 8, 8, 255))
    d.rectangle([9, 19, 54, 33], fill=(150, 20, 20, 255))
    d.text((12, 21), "SALIDA", fill=(255, 210, 200, 255))
    # el resplandor del aviso, sobre la pared
    px = img.load()
    for y in range(36, 64):
        for x in range(8, 56):
            r, g, b, a = px[x, y]
            k = max(0.0, 1.0 - (y - 36) / 28.0) * 0.6
            px[x, y] = (clamp(r + 120 * k), clamp(g + 20 * k), clamp(b + 20 * k), a)
    for x in range(14, 50, 6):
        d.line([(x, 40), (x, 60)], fill=(80, 40, 40, 255))
    noise(img, 0.06)
    save_wall(img, "salida")


# ------------------------------------------------------------------ pisos y techos (atlas)

def f_asfalto(d, img):
    d.rectangle([0, 0, 63, 63], fill=(52, 50, 54, 255))
    noise(img, 0.3)
    for _ in range(3):
        crack(d, random.randrange(64), random.randrange(20), 14, (26, 24, 28, 255))
    px = img.load()
    for _ in range(3):  # charcos que reflejan algo
        cx, cy, r = random.randrange(64), random.randrange(64), random.randint(4, 8)
        for y in range(cy - r, cy + r):
            for x in range(cx - 2 * r, cx + 2 * r):
                if ((x - cx) / 2) ** 2 + (y - cy) ** 2 < r * r:
                    c = px[x % 64, y % 64]
                    px[x % 64, y % 64] = (clamp(c[0] * 0.6 + 10), clamp(c[1] * 0.6 + 12), clamp(c[2] * 0.6 + 30), 255)


def f_anden(d, img):
    for ty in range(0, 64, 16):
        for tx in range(0, 64, 16):
            base = random.choice([(110, 106, 100), (100, 98, 94), (118, 112, 104)])
            bevel(d, (tx, ty, tx + 15, ty + 15), base, 1.12, 0.7)
    noise(img, 0.12)
    crack(d, 20, 3, 10, (60, 58, 56, 255))


def f_baldosa(d, img):
    for ty in range(0, 64, 16):
        for tx in range(0, 64, 16):
            dark = ((tx + ty) // 16) % 2 == 0
            base = (40, 44, 40) if dark else (170, 168, 150)
            bevel(d, (tx, ty, tx + 15, ty + 15), base, 1.08, 0.8)
    noise(img, 0.14)
    px = img.load()
    for _ in range(4):
        cx, cy = random.randrange(64), random.randrange(64)
        for k in range(30):
            x, y = (cx + random.randint(-5, 5)) % 64, (cy + random.randint(-4, 4)) % 64
            c = px[x, y]
            px[x, y] = (clamp(c[0] * 0.6 + 20), clamp(c[1] * 0.7 + 40), clamp(c[2] * 0.5), 255)


def f_madera(d, img):
    for x in range(0, 64, 8):
        base = random.choice([(110, 74, 44), (100, 66, 40), (120, 80, 48)])
        bevel(d, (x, 0, x + 7, 63), base, 1.15, 0.6)
        cut = random.randrange(64)
        d.line([(x, cut), (x + 7, cut)], fill=shade(base, 0.5))
    noise(img, 0.1)


def f_marmol(d, img):
    for ty in range(0, 64, 32):
        for tx in range(0, 64, 32):
            dark = ((tx + ty) // 32) % 2 == 0
            base = (30, 26, 34) if dark else (200, 196, 186)
            d.rectangle([tx, ty, tx + 31, ty + 31], fill=base + (255,))
    px = img.load()
    for y in range(64):
        for x in range(64):
            v = math.sin(x * 0.2 + math.sin(y * 0.13) * 3)
            if v > 0.85:
                c = px[x, y]
                px[x, y] = (clamp(c[0] + 40), clamp(c[1] + 36), clamp(c[2] + 40), 255)
    for k in (0, 31, 32, 63):
        d.line([(k, 0), (k, 63)], fill=(200, 160, 60, 255))
        d.line([(0, k), (63, k)], fill=(200, 160, 60, 255))


def f_techo_cocina(d, img):
    d.rectangle([0, 0, 63, 63], fill=(60, 62, 60, 255))
    noise(img, 0.2)
    for y in (10, 42):
        d.rectangle([0, y, 63, y + 5], fill=(90, 86, 80, 255))
        d.line([(0, y), (63, y)], fill=(120, 116, 110, 255))
    d.rectangle([26, 22, 38, 30], fill=(200, 230, 160, 255))  # el tubo de luz
    grime(img, 0.3, 0.0)


def f_techo_casa(d, img):
    gold = (190, 150, 60)
    d.rectangle([0, 0, 63, 63], fill=(70, 40, 30, 255))
    for ty in (0, 32):
        for tx in (0, 32):
            bevel(d, (tx + 2, ty + 2, tx + 29, ty + 29), (90, 52, 36), 1.25, 0.55, 2)
            d.ellipse([tx + 12, ty + 12, tx + 19, ty + 19], fill=gold + (255,))
    noise(img, 0.08)


def f_tierra(d, img):
    d.rectangle([0, 0, 63, 63], fill=(70, 56, 42, 255))
    noise(img, 0.35)
    for _ in range(30):
        x, y = random.randrange(64), random.randrange(64)
        d.point((x, y), fill=(110, 100, 80, 255))


def flats():
    sheet = Image.new("RGBA", (64 * len(FLATS), 64))
    fns = {"asfalto": f_asfalto, "anden": f_anden, "baldosa": f_baldosa, "madera": f_madera, "marmol": f_marmol,
           "techo_cocina": f_techo_cocina, "techo_casa": f_techo_casa, "tierra": f_tierra}
    for i, n in enumerate(FLATS):
        img, d = new()
        fns[n](d, img)
        sheet.paste(img, (i * 64, 0))
    sheet.save(OUT / "dd_suelos.png")


# ------------------------------------------------------------------ decorado

def sprite(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, name, line=True):
    if line:
        outline(img)
    img.save(OUT / f"dd_{name}.png")


def farol():
    img, d = sprite(20, 72)
    d.rectangle([9, 10, 11, 71], fill=(60, 64, 70, 255))
    d.rectangle([8, 64, 12, 71], fill=(44, 46, 50, 255))
    d.line([(10, 10), (16, 6)], fill=(60, 64, 70, 255), width=2)
    d.rectangle([12, 2, 19, 7], fill=(50, 52, 56, 255))
    d.rectangle([13, 7, 18, 9], fill=(255, 230, 150, 255))
    save(img, "farol")


def caneca_fuego():
    for f in range(2):
        img, d = sprite(22, 34)
        d.rectangle([3, 14, 18, 33], fill=(80, 70, 60, 255))
        for y in (17, 24, 31):
            d.line([(3, y), (18, y)], fill=(54, 46, 40, 255))
        d.line([(4, 15), (4, 32)], fill=(120, 100, 84, 255))
        for k in range(7):
            x = 5 + k * 2
            hgt = random.randint(6, 13) if f == 0 else random.randint(4, 12)
            d.line([(x, 14), (x + random.randint(-1, 1), 14 - hgt)], fill=(250, 140 + random.randint(0, 60), 40, 255), width=2)
        d.ellipse([7, 6, 14, 12], fill=(255, 230, 120, 255))
        save(img, f"caneca_fuego{f + 1}")


def carro():
    img, d = sprite(80, 34)
    d.polygon([(4, 18), (16, 8), (54, 8), (68, 18), (78, 20), (78, 28), (2, 28)], fill=(46, 40, 40, 255))
    d.polygon([(18, 10), (30, 10), (30, 18), (12, 18)], fill=(20, 16, 18, 255))
    d.polygon([(34, 10), (52, 10), (60, 18), (34, 18)], fill=(20, 16, 18, 255))
    for x in (16, 62):
        d.ellipse([x - 7, 22, x + 7, 34], fill=(24, 22, 22, 255))
        d.ellipse([x - 3, 26, x + 3, 30], fill=(70, 60, 50, 255))
    px = img.load()
    for _ in range(140):  # óxido y hollín
        x, y = random.randrange(80), random.randrange(8, 28)
        if px[x, y][3]:
            px[x, y] = random.choice([(120, 60, 30, 255), (70, 50, 40, 255), (30, 26, 26, 255)])
    save(img, "carro")


def estatua():
    """La estatua dorada de Lisandro en su propia casa. Más alta que él. Más flaca que él."""
    img, d = sprite(30, 70)
    gold = (226, 182, 64)
    d.rectangle([4, 58, 25, 69], fill=(70, 66, 72, 255))
    d.rectangle([3, 56, 26, 58], fill=(110, 104, 112, 255))
    d.rectangle([9, 24, 20, 56], fill=gold + (255,))
    d.rectangle([5, 26, 9, 44], fill=shade(gold, 0.85))
    d.polygon([(20, 26), (27, 14), (29, 16), (22, 30)], fill=shade(gold, 0.95))  # el brazo arriba
    d.ellipse([9, 12, 20, 24], fill=shade(gold, 1.1))
    d.rectangle([10, 16, 19, 18], fill=(30, 26, 20, 255))  # las gafas, también de oro negro
    d.line([(14, 26), (14, 54)], fill=shade(gold, 0.7))
    save(img, "estatua")


def billete(pose):
    """Billete: un perro flaco de la calle, café con una oreja caída. De frente."""
    img, d = sprite(30, 26)
    fur, dark, belly = (150, 104, 60), (96, 62, 36), (196, 160, 116)
    if pose == "sit":
        d.ellipse([7, 10, 23, 25], fill=fur + (255,))
        d.ellipse([11, 14, 19, 25], fill=belly + (255,))
        d.rectangle([9, 21, 12, 25], fill=dark + (255,))
        d.rectangle([18, 21, 21, 25], fill=dark + (255,))
    else:
        lift = 1 if pose == "walk1" else -1
        d.ellipse([6, 11, 24, 22], fill=fur + (255,))
        for x, up in ((8, lift), (13, -lift), (17, lift), (21, -lift)):
            d.rectangle([x, 19 + max(0, up), x + 2, 25], fill=dark + (255,))
    d.ellipse([8, 1, 22, 14], fill=fur + (255,))
    d.polygon([(8, 3), (4, 12), (9, 9)], fill=dark + (255,))      # la oreja caída
    d.polygon([(21, 2), (25, 0), (22, 7)], fill=dark + (255,))    # la parada
    d.ellipse([12, 8, 18, 13], fill=belly + (255,))
    d.rectangle([14, 8, 16, 9], fill=(20, 16, 16, 255))           # la nariz
    d.point((11, 6), fill=(20, 16, 16, 255))
    d.point((18, 6), fill=(20, 16, 16, 255))
    d.point((11, 5), fill=(240, 240, 240, 255))
    if pose == "sit":
        d.rectangle([14, 12, 15, 14], fill=(220, 90, 100, 255))   # la lengua
    save(img, f"billete_{pose}")


def pelado():
    """El pelado de la esquina: doce años, gorra de lado, tenis que no son de él."""
    img, d = sprite(22, 40)
    skin = (190, 140, 100)
    d.rectangle([7, 32, 10, 39], fill=(50, 60, 90, 255))
    d.rectangle([12, 32, 15, 39], fill=(50, 60, 90, 255))
    d.rectangle([5, 38, 10, 39], fill=(240, 240, 240, 255))
    d.rectangle([12, 38, 17, 39], fill=(240, 240, 240, 255))
    d.rectangle([5, 16, 17, 32], fill=(210, 60, 50, 255))
    d.rectangle([2, 17, 5, 28], fill=skin + (255,))
    d.rectangle([17, 17, 20, 28], fill=skin + (255,))
    d.ellipse([5, 4, 17, 16], fill=skin + (255,))
    d.rectangle([4, 3, 15, 6], fill=(30, 30, 120, 255))
    d.rectangle([14, 5, 20, 6], fill=(30, 30, 120, 255))
    d.point((9, 10), fill=(20, 16, 16, 255))
    d.point((13, 10), fill=(20, 16, 16, 255))
    save(img, "pelado")


def telefono():
    img, d = sprite(24, 54)
    d.rectangle([3, 4, 20, 53], fill=(40, 90, 160, 255))
    d.rectangle([5, 10, 18, 40], fill=(200, 210, 220, 255))
    d.rectangle([7, 14, 14, 22], fill=(40, 40, 46, 255))
    for y in range(26, 36, 3):
        for x in (7, 10, 13):
            d.point((x, y), fill=(30, 30, 30, 255))
    d.rectangle([15, 13, 17, 30], fill=(30, 30, 34, 255))
    d.rectangle([2, 0, 21, 4], fill=(240, 200, 40, 255))
    d.text((4, 42), "TEL", fill=(240, 240, 240, 255))
    save(img, "telefono")


def espejo():
    img, d = sprite(26, 46)
    gold = (226, 182, 64)
    d.ellipse([1, 1, 24, 40], fill=gold + (255,))
    d.ellipse([4, 4, 21, 37], fill=(120, 140, 160, 255))
    d.line([(8, 10), (12, 6)], fill=(220, 230, 240, 255), width=2)
    d.rectangle([10, 40, 15, 45], fill=shade(gold, 0.7))
    save(img, "espejo")


def foto():
    """Una mesita con una foto: dos pelados en la misma esquina."""
    img, d = sprite(22, 30)
    d.rectangle([3, 16, 18, 18], fill=(110, 70, 40, 255))
    d.rectangle([5, 18, 6, 29], fill=(90, 56, 32, 255))
    d.rectangle([15, 18, 16, 29], fill=(90, 56, 32, 255))
    d.rectangle([5, 2, 16, 15], fill=(226, 182, 64, 255))
    d.rectangle([6, 3, 15, 14], fill=(210, 200, 170, 255))
    d.line([(8, 7), (8, 13)], fill=(60, 50, 40, 255))
    d.point((8, 6), fill=(60, 50, 40, 255))
    d.line([(13, 8), (13, 13)], fill=(60, 50, 40, 255))
    d.point((13, 7), fill=(60, 50, 40, 255))
    save(img, "foto")


def polvo():
    img, d = sprite(32, 26)
    for _ in range(24):
        x, y, r = random.randint(4, 27), random.randint(4, 21), random.randint(2, 5)
        g = random.randint(220, 255)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(g, g, g, 230))
    img.save(OUT / "dd_polvo.png")


def bolsas():
    img, d = sprite(30, 20)
    for x, c in ((2, (30, 30, 34)), (12, (40, 40, 46)), (7, (24, 24, 28))):
        d.ellipse([x, 4 if x != 7 else 8, x + 14, 19], fill=c + (255,))
        d.line([(x + 6, 4 if x != 7 else 8), (x + 8, 1 if x != 7 else 5)], fill=c + (255,), width=2)
    save(img, "bolsas")


if __name__ == "__main__":
    w_ladrillo(); w_dibujos(); w_persiana(); w_contenedor(); w_cocina(); w_cajas()
    w_oro(); w_marmol(); w_columna(); door("puerta", None); door("puerta_llave", (200, 30, 30, 255)); w_salida()
    flats()
    farol(); caneca_fuego(); carro(); estatua(); pelado(); telefono(); espejo(); foto(); polvo(); bolsas()
    for p in ("sit", "walk1", "walk2"):
        billete(p)
    print("ok")


# ------------------------------------------------------------------ armas en primera persona (96x64, a lo Doom)
# Lisandro (dw_): pistola y escopeta de oro, mano con anillos, manga de lino blanco.
# Él con armadura (sw_): acero pavonado, guante verde, la manga de la armadura.

def _shaded_poly(d, pts, base, light_left=True):
    d.polygon(pts, fill=shade(base, 1.0))
    xs = [p[0] for p in pts]
    x0, x1 = min(xs), max(xs)
    ys = [p[1] for p in pts]
    d.line([(x0 + 1, min(ys) + 1), (x0 + 1, max(ys) - 1)], fill=shade(base, 1.35))
    d.line([(x1 - 1, min(ys) + 1), (x1 - 1, max(ys) - 1)], fill=shade(base, 0.6))


def _hand(d, cx, top, skin, sleeve, rings, glove):
    """La mano que agarra desde abajo (y la manga)."""
    if glove:
        skin = glove
    d.rectangle([cx - 15, top + 18, cx + 15, 64], fill=shade(sleeve, 1.0))
    d.line([(cx - 14, top + 18), (cx - 14, 64)], fill=shade(sleeve, 1.25))
    d.line([(cx + 14, top + 18), (cx + 14, 64)], fill=shade(sleeve, 0.65))
    d.rectangle([cx - 15, top + 18, cx + 15, top + 20], fill=shade(sleeve, 0.8))
    d.ellipse([cx - 14, top, cx + 14, top + 24], fill=shade(skin, 1.0))
    d.ellipse([cx - 12, top + 2, cx - 2, top + 12], fill=shade(skin, 1.2))
    for k in range(4):  # los nudillos
        y = top + 6 + k * 4
        d.line([(cx + 4, y), (cx + 13, y)], fill=shade(skin, 0.7))
        if rings and k in (1, 2):
            d.rectangle([cx + 6, y - 1, cx + 12, y + 1], fill=(240, 196, 60, 255))
            d.point((cx + 9, y - 1), fill=(255, 250, 200, 255))
    d.polygon([(cx - 14, top + 8), (cx - 20, top + 2), (cx - 16, top - 2), (cx - 9, top + 4)], fill=shade(skin, 1.05))  # el pulgar


def _flash(d, cx, cy, r):
    pts = []
    for k in range(16):
        a = k * math.pi / 8
        rr = r if k % 2 == 0 else r * 0.45
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr * 0.8))
    d.polygon(pts, fill=(255, 200, 60, 255))
    d.ellipse([cx - r * 0.45, cy - r * 0.35, cx + r * 0.45, cy + r * 0.35], fill=(255, 250, 220, 255))


def gun_pistola(metal, skin, sleeve, rings, glove, fire):
    img, d = sprite(96, 64)
    cx = 48
    if fire:
        _flash(d, cx, 9, 14)
    _shaded_poly(d, [(cx - 7, 10), (cx + 7, 10), (cx + 10, 40), (cx - 10, 40)], metal)   # la corredera, de atrás
    d.rectangle([cx - 2, 8, cx + 2, 12], fill=shade(metal, 0.5))                           # la mira
    d.rectangle([cx - 5, 18, cx + 5, 20], fill=shade(metal, 0.7))
    for y in range(24, 38, 3):
        d.line([(cx - 8, y), (cx - 5, y)], fill=shade(metal, 0.7))
    _hand(d, cx, 34 if not fire else 30, skin, sleeve, rings, glove)
    return img


def gun_escopeta(metal, wood, skin, sleeve, rings, glove, fire):
    img, d = sprite(96, 64)
    cx = 48
    if fire:
        _flash(d, cx, 6, 20)
    _shaded_poly(d, [(cx - 9, 2), (cx + 9, 2), (cx + 14, 50), (cx - 14, 50)], metal)       # dos cañones
    d.line([(cx, 3), (cx, 48)], fill=shade(metal, 0.5))
    d.ellipse([cx - 8, 1, cx - 1, 6], fill=(14, 12, 14, 255))
    d.ellipse([cx + 1, 1, cx + 8, 6], fill=(14, 12, 14, 255))
    _shaded_poly(d, [(cx - 13, 22), (cx + 13, 22), (cx + 16, 36), (cx - 16, 36)], wood)    # la corredera de madera
    for y in (25, 29, 33):
        d.line([(cx - 12, y), (cx + 12, y)], fill=shade(wood, 0.7))
    base = 36 if not fire else 32
    # la mano de adelante agarra la madera, la de atrás va abajo
    _hand(d, cx - 22, base + 4, skin, sleeve, rings, glove)
    _hand(d, cx + 22, base + 8, skin, sleeve, rings, glove)
    return img


def gun_puno(skin, sleeve, rings, glove, fire):
    img, d = sprite(96, 64)
    cx, top = (60, 30) if not fire else (50, 16)
    if glove:
        skin = glove
    d.rectangle([cx - 14, top + 22, cx + 14, 64], fill=shade(sleeve, 1.0))
    d.line([(cx - 13, top + 22), (cx - 13, 64)], fill=shade(sleeve, 1.25))
    d.ellipse([cx - 18, top, cx + 18, top + 30], fill=shade(skin, 1.0))
    for k in range(4):
        x = cx - 14 + k * 8
        d.ellipse([x, top + 1, x + 8, top + 11], fill=shade(skin, 1.15))
        d.line([(x + 1, top + 11), (x + 7, top + 11)], fill=shade(skin, 0.65))
        if rings and k in (1, 2, 3):
            d.rectangle([x + 1, top + 11, x + 7, top + 13], fill=(240, 196, 60, 255))
    d.polygon([(cx - 18, top + 14), (cx - 4, top + 12), (cx - 2, top + 18), (cx - 16, top + 22)], fill=shade(skin, 0.9))
    return img


def weapons():
    kits = {
        "dw_": dict(metal=(226, 182, 64), wood=(120, 70, 40), skin=(214, 160, 120), sleeve=(236, 232, 220), rings=True, glove=None),
        "sw_": dict(metal=(70, 74, 84), wood=(90, 60, 36), skin=(200, 150, 110), sleeve=(60, 110, 60), rings=False, glove=(70, 120, 60)),
    }
    for prefix, k in kits.items():
        for fire in (False, True):
            suf = "_fire" if fire else ""
            for name, img in (
                ("pistola", gun_pistola(k["metal"], k["skin"], k["sleeve"], k["rings"], k["glove"], fire)),
                ("escopeta", gun_escopeta(k["metal"], k["wood"], k["skin"], k["sleeve"], k["rings"], k["glove"], fire)),
                ("puno", gun_puno(k["skin"], k["sleeve"], k["rings"], k["glove"], fire)),
            ):
                outline(img)
                noise(img, 0.05)
                img.save(OUT / f"{prefix}{name}{suf}.png")


if __name__ == "__main__":
    weapons()
