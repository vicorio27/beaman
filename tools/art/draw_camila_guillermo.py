"""Camila y Guillermo en el beat 'em up (sueño 3 y el mano a mano), rediseñados:
  Camila     enana, cabezona, peinado de honguito pintado de mono (con la raíz oscura), muy tetona,
             vestido fucsia, medias oscuras, uñas rojas (tira bolsos). Hoja nueva, misma distribución
             que la de Lilato (SideFrames.LILATO), dibujada como draw_lilato.py.
  Guillermo  gordo, muy gordo, mono y con gafas oscuras: se parte de la hoja del jefe (polo verde, jean,
             pelo mono, gafas). Lo gordo lo pone el juego: se ensancha el muñeco ("scale" del tipo de
             enemigo, ver Brawler.body_scale).
Salida: assets/prologue/camila.png, assets/prologue/guillermo.png
Uso: python tools/art/draw_camila_guillermo.py  (desde la carpeta del proyecto)"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from draw_luchadores import torso, recolor, cells, opaque, is_flash, OUTLINE  # noqa: E402

OUT = Path("assets/prologue")
C = 48
INK = (46, 34, 47, 255)
SKIN = (252, 167, 144, 255)
SKIN_SH = (237, 128, 153, 255)
BLOND = (246, 214, 96, 255)
BLOND_SH = (210, 170, 60, 255)
ROOTS = (96, 66, 46, 255)
DRESS = (214, 64, 130, 255)
DRESS_SH = (160, 40, 96, 255)
TIGHTS = (48, 30, 58, 255)
EYE = (40, 30, 40, 255)
LIPS = (220, 40, 60, 255)
NAILS = (220, 40, 60, 255)
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


# ======================================================================= CAMILA
def camila(front_hand=(26, 38), back_hand=(18, 38), feet=((19, 46), (24, 46)), bob=0, arms_out=False, skirt=0):
    """Mira a la derecha. Enana: la cabeza arriba en y=25 (Lilato en 19) y piernas cortas."""
    img = Image.new("RGBA", (C, C), CLEAR)
    d = ImageDraw.Draw(img)
    cx = 22
    hy = 25 + bob  # arriba de la cabeza
    sh = hy + 9    # hombros
    fh = (front_hand[0], front_hand[1] + 4)
    bh = (back_hand[0], back_hand[1] + 4)
    # Brazo de atrás.
    d.line([(cx - 1, sh + 1), bh], fill=SKIN_SH, width=2)
    d.point(bh, fill=NAILS)
    # Piernas cortas, medias oscuras, tacones.
    for hip, foot in (((cx - 2, 42), feet[0]), ((cx + 1, 42), feet[1])):
        d.line([hip, foot], fill=TIGHTS, width=2)
        d.line([(foot[0], foot[1]), (foot[0] + 2, foot[1])], fill=INK)
    # Vestido dorado: cuerpo, el busto (adelante) y la pollera.
    d.rectangle([cx - 3, sh, cx + 3, sh + 5], fill=DRESS)
    d.ellipse([cx + 1, sh + 1, cx + 6, sh + 5], fill=DRESS)
    d.point((cx + 4, sh + 4), fill=DRESS_SH)
    d.polygon([(cx - 3, sh + 5), (cx + 3, sh + 5), (cx + 5 + skirt, 42), (cx - 5 - skirt, 42)], fill=DRESS)
    d.line([(cx - 3, sh), (cx - 3, sh + 5)], fill=DRESS_SH)
    d.line([(cx - 5 - skirt, 42), (cx + 5 + skirt, 42)], fill=DRESS_SH)
    # Cabeza grande.
    d.rectangle([cx - 3, hy + 2, cx + 4, hy + 8], fill=SKIN)
    d.point((cx + 3, hy + 5), fill=EYE)
    d.point((cx + 4, hy + 7), fill=LIPS)
    # El honguito: un casco redondo de pelo mono, flequillo recto hasta las cejas, la raíz oscura arriba.
    d.ellipse([cx - 5, hy - 1, cx + 5, hy + 8], fill=BLOND)
    d.rectangle([cx - 1, hy + 4, cx + 4, hy + 8], fill=SKIN)  # la cara queda descubierta
    d.line([(cx - 1, hy + 4), (cx + 5, hy + 4)], fill=BLOND)  # el flequillo
    d.line([(cx - 4, hy + 6), (cx - 4, hy + 8)], fill=BLOND_SH)
    d.line([(cx - 2, hy - 1), (cx + 2, hy - 1)], fill=ROOTS)
    d.point((cx + 3, hy + 6), fill=EYE)
    d.point((cx + 4, hy + 8), fill=LIPS)
    # Brazo de adelante, uñas rojas.
    d.line([(cx + 1, sh + 1), fh], fill=SKIN, width=2)
    d.line([fh, (fh[0] + 1, fh[1] + 1)], fill=NAILS)
    if arms_out:
        d.line([(cx - 1, sh + 1), (cx - 12, sh + 1)], fill=SKIN, width=2)
        d.point((cx - 12, sh + 1), fill=NAILS)
    return outline(img)


def rotated(img, deg, dy=0):
    """Rota alrededor de los pies (golpeada / caída)."""
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
    g = Image.new("RGBA", img.size, CLEAR)
    src, out = img.load(), g.load()
    for y in range(C):
        for x in range(C):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0), (0, -2)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < C and 0 <= ny < C and src[nx, ny][3] > 0:
                        out[x, y] = color
                        break
    g.alpha_composite(img)
    return g


def camila_sheet():
    idle_a = camila()
    idle_b = camila(front_hand=(26, 37), back_hand=(18, 37), bob=1)
    walk = [
        camila(front_hand=(27, 36), back_hand=(17, 38), feet=((17, 46), (26, 46))),
        camila(front_hand=(25, 38), back_hand=(19, 37), feet=((20, 46), (23, 46)), bob=-1),
        camila(front_hand=(18, 37), back_hand=(26, 36), feet=((25, 46), (18, 46))),
        camila(front_hand=(25, 38), back_hand=(19, 37), feet=((21, 46), (22, 46)), bob=-1),
    ]
    slash = [  # el carterazo
        camila(front_hand=(16, 24), back_hand=(18, 38), feet=((18, 46), (25, 46))),
        camila(front_hand=(36, 30), back_hand=(16, 36), feet=((17, 46), (27, 46)), skirt=1),
        camila(front_hand=(33, 37), back_hand=(17, 37), feet=((18, 46), (26, 46)), skirt=1),
    ]
    spin = [
        camila(front_hand=(33, 30), back_hand=(18, 38), arms_out=True, skirt=2),
        camila(front_hand=(33, 30), back_hand=(18, 38), arms_out=True, skirt=3).transpose(Image.FLIP_LEFT_RIGHT),
        camila(front_hand=(33, 30), back_hand=(18, 38), arms_out=True, skirt=2),
        camila(front_hand=(33, 30), back_hand=(18, 38), arms_out=True, skirt=3).transpose(Image.FLIP_LEFT_RIGHT),
    ]
    hurt = camila(front_hand=(28, 24), back_hand=(14, 26), feet=((18, 46), (23, 46)), bob=1)
    rows = [
        [idle_a, idle_b],
        walk,
        slash,
        spin,
        [silhouette(hurt, (255, 255, 255, 255)), rotated(hurt, 8)],
        [rotated(idle_a, 30), rotated(idle_a, 75), rotated(idle_a, 90)],
        [rotated(idle_a, 20)],
        [glow(rotated(idle_a, 15), (240, 200, 90, 200)), glow(rotated(idle_a, 25), (255, 230, 120, 230))],
    ]
    sheet = Image.new("RGBA", (C * 4, C * len(rows)), CLEAR)
    for r, frames in enumerate(rows):
        for c, f in enumerate(frames):
            sheet.paste(f, (c * C, r * C))
    sheet.save(OUT / "camila.png")


# ======================================================================= GUILLERMO
def guillermo_sheet():
    green, green_d = (90, 160, 100), (64, 124, 74)
    im = torso(Image.open(OUT / "enemy_boss.png").convert("RGBA"), {(110, 39, 39)},
               lambda x, x0, x1, d: green_d if d else green)
    im = recolor(im, {(110, 39, 39): (66, 90, 140)},  # jean
                 head={(111, 103, 95): (24, 22, 28), (62, 53, 70): (230, 196, 90)})  # gafas, pelo
    # El pelo del jefe está dibujado con tinta: lo de adentro de la cabeza, mono.
    px = im.load()
    for cx, cy in cells(im):
        pts = opaque(px, cx, cy)
        if not pts or is_flash(px, pts):
            continue
        top = min(y for _, y in pts)
        if max(y for _, y in pts) - top < 16:
            continue
        for x, y in pts:
            if y - top < 6 and px[x, y][:3] == OUTLINE and all(
                    cx <= nx < cx + C and cy <= ny < cy + C and px[nx, ny][3] > 0
                    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                px[x, y] = (236, 204, 96, 255)
    im.save(OUT / "guillermo.png")


if __name__ == "__main__":
    camila_sheet()
    guillermo_sheet()
    print("Camila y Guillermo:", OUT)
