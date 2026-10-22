"""Los juegos de la feria por dentro (scripts/ui/FeriaJuegos.gd): cada uno con su dibujo de verdad.

    python tools/art/draw_feria_juegos.py            -> assets/feria/*.png + assets/feria/feria.json
    python tools/art/draw_feria_juegos.py chocones   -> solo uno (chocones, carrusel, montana, dardos, garra, rueda)

  CHOCONES  la pista vista desde arriba: lámina de acero antideslizante, la baranda de caucho con franjas
            de peligro, la gente asomada, los bombillos; los carritos (caucho alrededor, la vara al techo,
            quien maneja) y el ¡PUM! del choque.
  CARRUSEL  de costado: el techo de franjas con espejos y bombillos, la columna pintada, la plataforma
            con moldura dorada; los caballitos (cuatro pelajes, con y sin jinete; él con las rodillas en
            las orejas) y el brazo de la sortija.
  MONTANA   el cielo y el barrio de noche (capas que se repiten), el vagón con gente (con y sin manos
            arriba); la carrilera y los soportes de madera los dibuja el juego (cambian con la pista).
  DARDOS    el puesto de frente: el toldo de rayas, el corcho, los peluches colgados, el mostrador con la
            lata de dardos y el señor; los globos (seis colores), el estallido y el dardo clavado.
  GARRA     la máquina de frente: la marquesina con bombillos, el vidrio con reflejos, la montaña de
            peluches, el hueco de los premios, el tablero (palanca, botón, ranura); la garra abierta y
            cerrada y los premios sueltos (el oso morado de corazón negro, el conejo, el beagle, el
            unicornio).
  RUEDA     el barrio de noche desde arriba (alto: sube mientras la cabina sube), la cabina por dentro y
            él de espaldas; la fiesta de antes (la terraza, los bombillos, la gente sin cara) y él joven.
El .json lleva dónde van las cosas que el juego anima (bombillos, ganchos de la sortija, peluches).
"""
import json
import math
import os
import random
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from draw_feria_lote import INK, outline  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "feria")
W, H = 320, 180
META = {}
R = random.Random(7)

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def new(w=W, h=H, fill=None):
    return Image.new("RGBA", (w, h), (fill + (255,)) if fill else (0, 0, 0, 0))


def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((int(x), int(y)), tuple(c[:3]) + ((c[3],) if len(c) > 3 else (255,)))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def grad(im, box, top, bot, steps=6):
    """Degradado vertical con tramado (pixel art: pocos colores, mezclados con el patrón de Bayer)."""
    x0, y0, x1, y1 = box
    hgt = max(1, y1 - y0)
    for y in range(y0, y1):
        t = (y - y0) / hgt * (steps - 1)
        lo = int(t)
        frac = t - lo
        c0 = mix(top, bot, lo / (steps - 1))
        c1 = mix(top, bot, min(steps - 1, lo + 1) / (steps - 1))
        for x in range(x0, x1):
            px(im, x, y, c1 if frac * 16 > BAYER[y % 4][x % 4] else c0)


def rect(im, box, c):
    ImageDraw.Draw(im).rectangle(box, fill=tuple(c[:3]) + (255,))


def line(im, a, b, c, w=1):
    ImageDraw.Draw(im).line([a, b], fill=tuple(c[:3]) + (255,), width=w)


def ell(im, box, c, outline_c=None):
    ImageDraw.Draw(im).ellipse(box, fill=tuple(c[:3]) + (255,), outline=(tuple(outline_c) + (255,)) if outline_c else None)


def speckle(im, box, cols, density, rng=R):
    x0, y0, x1, y1 = box
    for _ in range(int((x1 - x0) * (y1 - y0) * density)):
        px(im, rng.randrange(x0, x1), rng.randrange(y0, y1), rng.choice(cols))


def sphere(im, cx, cy, r, base, light, dark, hi=(255, 255, 255)):
    """Un círculo con volumen: luz arriba a la izquierda, sombra abajo a la derecha, brillo."""
    for y in range(-r, r + 1):
        for x in range(-r, r + 1):
            d = math.hypot(x, y)
            if d <= r + 0.3:
                lx, ly = (x + r * 0.4) / r, (y + r * 0.4) / r
                lit = math.hypot(lx, ly)
                c = light if lit < 0.55 else (base if lit < 1.05 else dark)
                px(im, cx + x, cy + y, c)
    px(im, cx - r // 2, cy - r // 2, hi)
    if r >= 4:
        px(im, cx - r // 2 + 1, cy - r // 2, hi)
        px(im, cx - r // 2, cy - r // 2 + 1, light)


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name + ".png"))


GLYPH = {
    "A": ["0110", "1001", "1111", "1001", "1001"], "B": ["1110", "1001", "1110", "1001", "1110"],
    "C": ["0111", "1000", "1000", "1000", "0111"], "D": ["1110", "1001", "1001", "1001", "1110"],
    "E": ["1111", "1000", "1110", "1000", "1111"], "G": ["0111", "1000", "1011", "1001", "0111"], "F": ["1111", "1000", "1110", "1000", "1000"],
    "K": ["1001", "1010", "1100", "1010", "1001"], "V": ["1001", "1001", "1001", "0110", "0110"], "Y": ["101", "101", "010", "010", "010"],
    "H": ["1001", "1001", "1111", "1001", "1001"], "I": ["111", "010", "010", "010", "111"],
    "L": ["1000", "1000", "1000", "1000", "1111"], "M": ["10001", "11011", "10101", "10001", "10001"],
    "N": ["1001", "1101", "1011", "1001", "1001"], "O": ["0110", "1001", "1001", "1001", "0110"],
    "P": ["1110", "1001", "1110", "1000", "1000"], "R": ["1110", "1001", "1110", "1010", "1001"],
    "S": ["0111", "1000", "0110", "0001", "1110"], "T": ["11111", "00100", "00100", "00100", "00100"],
    "U": ["1001", "1001", "1001", "1001", "0110"], "X": ["1001", "1001", "0110", "1001", "1001"],
    "$": ["01110", "10100", "01110", "00101", "01110"], "0": ["0110", "1011", "1101", "1001", "0110"],
    "1": ["010", "110", "010", "010", "111"], "3": ["1110", "0001", "0110", "0001", "1110"],
    "5": ["1111", "1000", "1110", "0001", "1110"], " ": ["00", "00", "00", "00", "00"],
}


def letters(im, s, x, y, c, scale=1, shadow=None):
    cx = x
    for ch in s:
        g = GLYPH.get(ch, GLYPH[" "])
        for j, row in enumerate(g):
            for i, v in enumerate(row):
                if v == "1":
                    for a in range(scale):
                        for b in range(scale):
                            if shadow:
                                px(im, cx + i * scale + a + 1, y + j * scale + b + 1, shadow)
                            px(im, cx + i * scale + a, y + j * scale + b, c)
        cx += (len(g[0]) + 1) * scale
    return cx


def letters_w(s, scale=1):
    return sum((len(GLYPH.get(ch, GLYPH[" "])[0]) + 1) * scale for ch in s) - scale


# ================================================================ CHOCONES (desde arriba)

STEEL = (112, 118, 132)
STEEL_D = (86, 90, 104)
STEEL_L = (146, 152, 166)
CAR_COLS = {"rojo": ((206, 50, 56), (238, 96, 92), (140, 30, 40)),
            "azul": ((58, 112, 206), (110, 156, 236), (36, 70, 150)),
            "amarillo": ((236, 196, 58), (252, 230, 120), (180, 136, 30)),
            "verde": ((64, 170, 92), (120, 214, 130), (36, 112, 60)),
            "morado": ((150, 72, 190), (196, 122, 226), (100, 44, 136))}


def chocones():
    im = new(fill=(26, 22, 30))
    # Afuera de la pista: tierra de noche con confeti pisado.
    speckle(im, (0, 0, W, H), [(40, 34, 40), (34, 30, 36), (52, 44, 48)], 0.25)
    speckle(im, (0, 0, W, H), [(230, 90, 120), (90, 170, 230), (240, 210, 90)], 0.006)
    x0, y0, x1, y1 = 16, 20, 304, 170
    # El piso: láminas de acero con los diamantes del antideslizante, y las uniones.
    rect(im, (x0, y0, x1, y1), STEEL)
    for y in range(y0, y1):
        for x in range(x0, x1):
            u, v = (x - x0) % 8, (y - y0) % 8
            if (u, v) in ((1, 2), (2, 1), (5, 6), (6, 5)):
                px(im, x, y, STEEL_L)
            elif (u, v) in ((2, 2), (6, 6)):
                px(im, x, y, STEEL_D)
    for xs in range(x0, x1, 48):
        line(im, (xs, y0), (xs, y1), STEEL_D)
    for ys in range(y0, y1, 48):
        line(im, (x0, ys), (x1, ys), STEEL_D)
    # Charcos de luz de los bombillos (tramados) y el polvo de los rines.
    for cx, cy, col in [(60, 60, (200, 120, 130)), (250, 50, (120, 170, 220)), (170, 130, (220, 200, 120)), (90, 150, (150, 200, 150))]:
        for y in range(cy - 24, cy + 24):
            for x in range(cx - 40, cx + 40):
                d = math.hypot((x - cx) / 40, (y - cy) / 24)
                if d < 1 and (1 - d) * 16 > BAYER[y % 4][x % 4] + 6 and x0 < x < x1 and y0 < y < y1:
                    base = im.getpixel((x, y))[:3]
                    px(im, x, y, mix(base, col, 0.35))
    speckle(im, (x0 + 2, y0 + 2, x1 - 2, y1 - 2), [(70, 70, 80), (96, 96, 108)], 0.01)
    # La baranda: tubo de metal, franjas de peligro y el caucho por dentro.
    for k in range(5):
        b = (x0 - 5 + k, y0 - 5 + k, x1 + 5 - k, y1 + 5 - k)
        col = [(70, 72, 84), (170, 172, 184), (120, 122, 136), (30, 28, 34), (30, 28, 34)][k]
        ImageDraw.Draw(im).rectangle(b, outline=col + (255,))
    for t in range(0, 2 * (x1 - x0) + 2 * (y1 - y0), 1):  # franjas amarillo y negro en el borde de adentro
        if (t // 6) % 2 == 0:
            continue
        if t < x1 - x0:
            p = (x0 + t, y0 - 1)
        elif t < (x1 - x0) + (y1 - y0):
            p = (x1, y0 + t - (x1 - x0))
        elif t < 2 * (x1 - x0) + (y1 - y0):
            p = (x1 - (t - (x1 - x0) - (y1 - y0)), y1)
        else:
            p = (x0, y1 - (t - 2 * (x1 - x0) - (y1 - y0)))
        px(im, p[0], p[1], (236, 196, 58))
        inward = (0, 1) if t < x1 - x0 else ((-1, 0) if t < (x1 - x0) + (y1 - y0) else ((0, -1) if t < 2 * (x1 - x0) + (y1 - y0) else (1, 0)))
        px(im, p[0] - inward[0], p[1] - inward[1], (236, 196, 58))
    # La gente asomada a la baranda (vista desde arriba: el pelo, los hombros; alguno con algodón o celular).
    hair = [(30, 24, 22), (70, 46, 30), (140, 100, 50), (20, 18, 20), (200, 190, 170), (110, 70, 40)]
    shirts = [(200, 60, 70), (60, 110, 190), (230, 200, 80), (80, 150, 90), (220, 220, 220), (150, 80, 160), (240, 140, 60)]
    spots = [(x, 9) for x in range(28, 300, 17)] + [(x, 177) for x in range(36, 292, 21)] + [(6, y) for y in range(40, 160, 22)] + [(314, y) for y in range(34, 160, 24)]
    for (x, y) in spots:
        if R.random() < 0.25:
            continue
        sh = R.choice(shirts)
        ell(im, (x - 5, y - 3, x + 5, y + 3), sh, INK)
        ell(im, (x - 3, y - 3, x + 3, y + 2), R.choice(hair), INK)
        r = R.random()
        if r < 0.15:
            ell(im, (x + 4, y - 6, x + 9, y - 1), (246, 170, 200), INK)  # algodón de azúcar
        elif r < 0.3:
            px(im, x + 5, y - 2, (170, 230, 250))  # la pantalla del celular
            px(im, x + 5, y - 1, (60, 60, 70))
    # La caseta del operador (esquina de abajo a la derecha, afuera).
    save(im, "chocones_pista")
    bulbs = []
    for x in range(x0 - 2, x1 + 3, 12):
        bulbs += [[x, y0 - 6], [x, y1 + 6]]
    for y in range(y0 + 8, y1, 12):
        bulbs += [[x0 - 6, y], [x1 + 6, y]]
    META["chocones"] = {"pista": [x0, y0, x1, y1], "bombillos": bulbs}

    # Los carritos: de arriba, mirando a la derecha. Caucho alrededor, el cuerpo de color, la vara.
    drivers = {"rojo": "el", "azul": "nino", "amarillo": "nina", "verde": "borracho", "morado": "novios"}
    for name, (base, light, dark) in CAR_COLS.items():
        c = new(26, 20)
        dr = ImageDraw.Draw(c)
        dr.rounded_rectangle((0, 0, 25, 19), radius=7, fill=(28, 26, 30, 255))  # el caucho
        for x in range(4, 22, 3):  # las rayitas del caucho
            px(c, x, 0, (52, 50, 56))
            px(c, x, 19, (52, 50, 56))
        dr.rounded_rectangle((2, 2, 23, 17), radius=6, fill=base + (255,))
        for x in range(5, 22):  # brillo arriba, sombra abajo
            px(c, x, 3, light)
            px(c, x, 4, light if x % 3 else base)
            px(c, x, 16, dark)
        dr.rounded_rectangle((16, 5, 22, 14), radius=3, fill=light + (255,))  # la trompa
        rect(c, (21, 8, 22, 11), (252, 244, 210))  # el farol
        rect(c, (3, 5, 13, 14), mix(dark, (20, 20, 24), 0.45))  # el asiento
        for x in (4, 12):
            line(c, (x, 5), (x, 14), mix(dark, (20, 20, 24), 0.2))
        rect(c, (14, 7, 15, 12), (40, 40, 46))  # el timón
        px(c, 16, 9, (90, 90, 100))
        who = drivers[name]
        if who == "el":  # él: el saco gris (los hombros), el pelo negro parado, la barba, la corbata
            ell(c, (4, 4, 13, 15), (96, 98, 116), INK)
            ell(c, (6, 6, 12, 13), (40, 38, 46))
            px(c, 7, 7, (116, 114, 118))
            rect(c, (12, 8, 13, 11), (70, 62, 60))
            px(c, 13, 13, (206, 48, 52))
            line(c, (11, 5), (14, 7), (214, 150, 120))  # las manos al timón
            line(c, (11, 14), (14, 12), (214, 150, 120))
        elif who == "nino":
            ell(c, (5, 6, 12, 13), (226, 70, 60), INK)  # la cachucha
            rect(c, (12, 8, 14, 11), (200, 50, 46))
            px(c, 7, 7, (250, 250, 250))
        elif who == "nina":
            ell(c, (5, 6, 12, 13), (110, 70, 40), INK)
            for y in (5, 14):
                rect(c, (4, y, 5, y + 1), (110, 70, 40))  # las colitas
                px(c, 3, y, (240, 120, 160))
        elif who == "borracho":
            ell(c, (4, 5, 13, 14), (66, 60, 52), INK)  # el sombrero
            ell(c, (6, 7, 11, 12), (90, 82, 70))
            rect(c, (14, 3, 15, 4), (200, 160, 60))  # la pola
        else:  # los novios: dos cabezas, una recostada en la otra
            ell(c, (5, 4, 10, 9), (30, 24, 22), INK)
            ell(c, (5, 10, 10, 15), (150, 100, 50), INK)
            px(c, 11, 9, (240, 120, 160))
        ell(c, (1, 7, 5, 12), (210, 210, 220), INK)  # la vara al techo
        px(c, 2, 8, (255, 255, 255))
        save(c, "chocon_" + name)
    pum = new(15, 15)
    for a in range(8):
        ang = a * math.pi / 4
        rr = 7 if a % 2 == 0 else 4
        line(pum, (7, 7), (7 + math.cos(ang) * rr, 7 + math.sin(ang) * rr), (255, 230, 120), 2)
    ell(pum, (4, 4, 10, 10), (255, 250, 220))
    save(pum, "chocon_pum")


# ================================================================ CARRUSEL (de costado)

GOLD = (236, 190, 70)
GOLD_L = (255, 232, 140)
GOLD_D = (170, 120, 40)


def carrusel():
    im = new()
    grad(im, (0, 0, W, 140), (14, 12, 40), (60, 30, 70), 7)
    for _ in range(70):
        px(im, R.randrange(W), R.randrange(0, 80), (250, 240, 210) if R.random() < 0.7 else (180, 180, 220))
    # La rueda de Chicago y la montaña rusa, de fondo, en silueta con lucecitas.
    cx, cy, rr = 268, 70, 44
    for a in range(0, 360, 2):
        px(im, cx + rr * math.cos(math.radians(a)), cy + rr * math.sin(math.radians(a)), (50, 40, 70))
    for a in range(0, 360, 30):
        line(im, (cx, cy), (cx + rr * math.cos(math.radians(a)), cy + rr * math.sin(math.radians(a))), (46, 36, 64))
        px(im, cx + rr * math.cos(math.radians(a)), cy + rr * math.sin(math.radians(a)) + 3, (255, 200, 120))
    line(im, (cx, cy), (cx - 22, 140), (46, 36, 64), 2)
    line(im, (cx, cy), (cx + 22, 140), (46, 36, 64), 2)
    pts = [(0, 100), (20, 70), (40, 92), (62, 60), (88, 110)]
    for a, b in zip(pts, pts[1:]):
        line(im, a, b, (52, 38, 66), 2)
        for x in range(a[0], b[0], 6):
            y = a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
            line(im, (x, y), (x, 140), (40, 30, 54))
    # Los bombillos colgados de lado a lado.
    for x in range(0, W, 4):
        y = 22 + int(8 * math.sin(x / W * math.pi * 3) ** 2)
        px(im, x, y, (60, 50, 60))
        if x % 12 == 0:
            px(im, x, y + 1, [(255, 120, 120), (255, 220, 120), (140, 220, 255), (170, 255, 160)][(x // 12) % 4])
    # El piso: tierra con confeti y la sombra del carrusel.
    grad(im, (0, 140, W, H), (66, 50, 46), (40, 30, 30), 4)
    speckle(im, (0, 140, W, H), [(230, 90, 120), (90, 170, 230), (240, 210, 90), (120, 220, 140)], 0.02)
    ell(im, (36, 138, 284, 158), (32, 24, 26))
    save(im, "carrusel_fondo")

    # La columna del centro: paneles pintados con paisajes, espejos y molduras.
    col = new(44, 84)
    rect(col, (0, 0, 43, 83), (150, 40, 60))
    for k, x in enumerate(range(2, 42, 10)):
        rect(col, (x, 6, x + 7, 40), (60, 90, 140))  # el cielo del paisaje
        rect(col, (x, 28, x + 7, 40), (80, 140, 80))
        px(col, x + 2, 26, (250, 240, 200))
        rect(col, (x, 48, x + 7, 74), (176, 210, 230) if k % 2 == 0 else (196, 226, 240))  # los espejos
        line(col, (x + 1, 72), (x + 6, 50), (240, 250, 255))
        ImageDraw.Draw(col).rectangle((x - 1, 5, x + 8, 41), outline=GOLD + (255,))
        ImageDraw.Draw(col).rectangle((x - 1, 47, x + 8, 75), outline=GOLD + (255,))
    for y in (0, 1, 43, 44, 81, 82):
        line(col, (0, y), (43, y), GOLD_D if y % 2 else GOLD)
    for x in range(1, 44, 4):
        px(col, x, 44, (255, 240, 180))
    save(outline(col), "carrusel_columna")

    # El techo: cono de franjas rojo y blanco, cenefa con espejitos y bombillos, banderita.
    roof = new(240, 66)
    d = ImageDraw.Draw(roof)
    for i in range(24):
        a0, a1 = 4 + i * 9.6, 4 + (i + 1) * 9.6
        colr = (214, 52, 60) if i % 2 == 0 else (240, 236, 226)
        d.polygon([(120, 2), (a0, 42), (a1, 42)], fill=colr + (255,))
    for y in range(4, 42):  # sombra del cono a la derecha
        for x in range(120, 236):
            p = roof.getpixel((x, y))
            if p[3] and (x - 120) / 116 * 16 > BAYER[y % 4][x % 4] + 6:
                px(roof, x, y, mix(p[:3], (40, 20, 40), 0.25))
    rect(roof, (2, 42, 237, 52), GOLD)
    line(roof, (2, 42), (237, 42), GOLD_L)
    line(roof, (2, 52), (237, 52), GOLD_D)
    for x in range(6, 236, 14):  # los espejitos de la cenefa y las ondas
        rect(roof, (x, 44, x + 7, 50), (180, 214, 236))
        px(roof, x + 1, 45, (250, 255, 255))
        ell(roof, (x - 3, 50, x + 10, 62), (214, 52, 60) if (x // 14) % 2 == 0 else (60, 110, 200))
    for x in range(4, 238, 7):
        px(roof, x, 52, (255, 236, 150))
    line(roof, (120, 2), (120, -10), (90, 80, 70))
    save(outline(roof), "carrusel_techo")

    # La plataforma: el piso de madera y la falda con moldura y bombillos.
    base = new(236, 22)
    rect(base, (0, 0, 235, 6), (150, 104, 66))
    for x in range(0, 236, 8):
        line(base, (x, 0), (x, 6), (120, 82, 52))
    rect(base, (0, 7, 235, 21), (150, 40, 60))
    rect(base, (0, 7, 235, 9), GOLD)
    for x in range(6, 236, 16):
        ImageDraw.Draw(base).rectangle((x, 11, x + 11, 19), outline=GOLD + (255,))
        px(base, x + 5, 15, (255, 240, 180))
    save(outline(base), "carrusel_base")

    # Los caballitos (de costado, mirando a la derecha, a medio galope) y los jinetes.
    coats = {"blanco": ((236, 232, 222), (190, 184, 176), (255, 255, 250)),
             "negro": ((60, 56, 66), (36, 34, 42), (100, 96, 110)),
             "dorado": ((226, 180, 90), (176, 130, 60), (250, 220, 150)),
             "gris": ((160, 164, 176), (118, 122, 136), (206, 210, 220))}
    saddles = [(206, 52, 58), (60, 110, 200), (60, 160, 90), (150, 72, 190)]
    for k, (cname, (cb, cd, cl)) in enumerate(coats.items()):
        for rider in ["nadie", "nino", "el"]:
            h = new(28, 34)
            off = 10  # el caballo va en la parte de abajo; arriba queda el jinete
            d = ImageDraw.Draw(h)
            d.ellipse((5, off + 6, 21, off + 15), fill=cb + (255,))       # el cuerpo
            d.polygon([(19, off + 8), (23, off + 1), (26, off + 3), (24, off + 9), (21, off + 11)], fill=cb + (255,))  # cuello y cabeza
            d.polygon([(24, off + 3), (27, off + 5), (26, off + 7), (24, off + 6)], fill=cb + (255,))  # el hocico
            line(h, (7, off + 15), (4, off + 21), cb, 2)                  # patas de atrás
            line(h, (11, off + 15), (11, off + 22), cb, 2)
            line(h, (17, off + 14), (21, off + 18), cb, 2)                # patas de adelante, dobladas
            line(h, (21, off + 18), (19, off + 21), cb, 2)
            line(h, (20, off + 13), (24, off + 16), cb, 2)
            for x0_, y0_ in [(3, off + 21), (10, off + 22), (18, off + 21), (23, off + 16)]:
                px(h, x0_, y0_, (60, 50, 50))
                px(h, x0_ + 1, y0_, (60, 50, 50))
            for y in range(off + 6, off + 16):  # sombra de abajo
                for x in range(5, 22):
                    p = h.getpixel((x, y))
                    if p[3] and y > off + 12:
                        px(h, x, y, cd)
            line(h, (7, off + 7), (17, off + 7), cl)
            mane = (60, 50, 50) if cname != "negro" else (200, 190, 180)
            for i in range(5):
                px(h, 20 + i // 2, off + 2 + i, mane)
                px(h, 19 + i // 2, off + 3 + i, mane)
            for i in range(6):  # la cola, al viento
                px(h, 4 - i // 2, off + 8 + i, mane)
            px(h, 25, off + 4, INK)  # el ojo
            sd = saddles[k]
            rect(h, (10, off + 5, 16, off + 9), sd)
            line(h, (10, off + 5), (16, off + 5), GOLD)
            line(h, (24, off + 4), (19, off + 8), sd)  # las riendas
            if rider == "nino":
                rect(h, (12, off - 4, 15, off + 5), (230, 140, 60))       # camiseta
                ell(h, (11, off - 9, 16, off - 4), (214, 150, 120))
                rect(h, (11, off - 9, 16, off - 7), (60, 44, 34))
                line(h, (15, off - 1), (20, off + 3), (214, 150, 120))   # agarrado del tubo
                line(h, (13, off + 5), (15, off + 10), (60, 92, 146))
            elif rider == "el":  # él: el saco gris, la corbata roja, la barba; las rodillas en las orejas
                rect(h, (11, off - 8, 16, off + 4), (82, 86, 106))
                line(h, (14, off - 7), (14, off + 2), (206, 48, 52))
                ell(h, (10, off - 15, 17, off - 8), (214, 150, 120))
                rect(h, (10, off - 15, 17, off - 13), (40, 38, 46))
                px(h, 16, off - 16, (40, 38, 46))
                rect(h, (12, off - 10, 16, off - 8), (70, 62, 60))       # la barba
                px(h, 15, off - 12, INK)
                line(h, (14, off + 3), (19, off - 2), (66, 92, 146), 2)   # las rodillas, altísimas
                line(h, (19, off - 2), (19, off + 6), (66, 92, 146), 2)
                px(h, 19, off + 7, (196, 64, 52))
                line(h, (16, off - 4), (21, off - 1), (214, 150, 120))   # las manos en el tubo
            save(outline(h), "caballo_%s_%s" % (cname, rider))
    # La sortija: el brazo de madera con el aro dorado colgando, y el aro solo.
    arm = new(60, 40)
    rect(arm, (54, 0, 59, 39), (120, 82, 52))
    line(arm, (54, 0), (54, 39), (150, 104, 66))
    rect(arm, (8, 8, 54, 11), (150, 104, 66))
    line(arm, (8, 8), (54, 8), (180, 130, 84))
    line(arm, (12, 11), (12, 16), (90, 90, 96))
    save(outline(arm), "sortija_brazo")
    ring = new(9, 9)
    ImageDraw.Draw(ring).ellipse((0, 0, 8, 8), outline=GOLD + (255,), width=2)
    px(ring, 2, 1, GOLD_L)
    px(ring, 1, 2, GOLD_L)
    save(ring, "sortija")
    META["carrusel"] = {"centro": [160, 112], "radio": 96, "sortija": [252, 66]}


# ================================================================ MONTAÑA RUSA (de costado)

def montana():
    sky = new(640, 180)
    grad(sky, (0, 0, 640, 180), (10, 10, 34), (84, 40, 86), 8)
    for _ in range(140):
        px(sky, R.randrange(640), R.randrange(0, 110), (250, 240, 210) if R.random() < 0.75 else (190, 190, 240))
    ell(sky, (480, 22, 500, 42), (246, 240, 214))  # la luna
    ell(sky, (486, 24, 498, 36), (232, 226, 200))
    for (x, y, w) in [(60, 60, 70), (250, 44, 90), (400, 70, 60), (560, 54, 80)]:  # nubes alumbradas desde abajo
        for k in range(w):
            hh = int(6 * math.sin(k / w * math.pi)) + 2
            for j in range(hh):
                if (j + k) % 3 or j < hh - 2:
                    px(sky, x + k, y - j, (60, 40, 74) if j > 1 else (130, 80, 110))
    save(sky, "montana_cielo")
    far = new(640, 90)
    x = 0
    while x < 640:
        w = R.randrange(14, 30)
        h = R.randrange(18, 44)
        top = 90 - h
        col = R.choice([(28, 22, 40), (34, 26, 46), (24, 20, 36)])
        rect(far, (x, top, x + w, 89), col)
        if R.random() < 0.3:  # tanque de agua en el techo
            rect(far, (x + 3, top - 5, x + 8, top - 1), col)
        if R.random() < 0.25:  # antena
            line(far, (x + w - 3, top), (x + w - 3, top - 8), col)
        for wy in range(top + 4, 86, 7):
            for wx in range(x + 3, x + w - 3, 6):
                if R.random() < 0.35:
                    rect(far, (wx, wy, wx + 1, wy + 2), R.choice([(255, 210, 120), (250, 180, 90), (180, 220, 255)]))
        x += w + R.randrange(0, 3)
    rect(far, (300, 20, 307, 89), (30, 24, 44))  # la torre de la iglesia
    ImageDraw.Draw(far).polygon([(299, 20), (303, 8), (308, 20)], fill=(30, 24, 44, 255))
    px(far, 303, 4, (255, 230, 150))
    save(far, "montana_barrio")
    # El vagón de adelante: él adelante (saco gris, barba) y una señora atrás. Y el de atrás: dos pelados.
    for hands in [False, True]:
        for which in ["adelante", "atras"]:
            v = new(36, 30)
            d = ImageDraw.Draw(v)
            d.rounded_rectangle((1, 14, 34, 25), radius=4, fill=(206, 50, 56, 255))
            if which == "adelante":
                d.polygon([(30, 14), (35, 18), (35, 25), (30, 25)], fill=(206, 50, 56, 255))
                rect(v, (31, 19, 33, 21), (252, 244, 200))  # el farol
            rect(v, (2, 19, 33, 20), (244, 204, 70))  # la franja
            line(v, (2, 15), (33, 15), (238, 100, 96))
            line(v, (2, 25), (33, 25), (140, 30, 40))
            for wx in (7, 27):  # las ruedas
                ell(v, (wx - 3, 23, wx + 3, 29), (40, 38, 44))
                px(v, wx, 26, (190, 190, 200))
            riders = [("el", 22), ("senora", 9)] if which == "adelante" else [("pelado", 22), ("pelada", 9)]
            for who, rx in riders:
                skin = (214, 150, 120) if who != "pelado" else (176, 120, 90)
                torso = {"el": (82, 86, 106), "senora": (200, 80, 140), "pelado": (60, 140, 200), "pelada": (240, 190, 70)}[who]
                rect(v, (rx - 4, 8, rx + 3, 14), torso)
                ell(v, (rx - 3, 1, rx + 3, 8), skin)
                hair = {"el": (40, 38, 46), "senora": (110, 70, 40), "pelado": (30, 24, 22), "pelada": (30, 24, 22)}[who]
                rect(v, (rx - 3, 1, rx + 3, 3), hair)
                if who in ("senora", "pelada"):  # el pelo al viento, para atrás
                    for k in range(5):
                        px(v, rx - 4 - k, 2 + k // 2, hair)
                        px(v, rx - 4 - k, 3 + k // 2, hair)
                if who == "el":
                    rect(v, (rx - 1, 6, rx + 3, 8), (70, 62, 60))  # la barba
                    line(v, (rx, 9), (rx, 13), (206, 48, 52))       # la corbata
                px(v, rx + 2, 4, INK)
                if hands:
                    line(v, (rx - 3, 8), (rx - 5, 1), torso, 2)
                    line(v, (rx + 2, 8), (rx + 4, 1), torso, 2)
                    px(v, rx - 5, 0, skin)
                    px(v, rx + 4, 0, skin)
                    px(v, rx, 6, (40, 20, 24))  # la boca abierta
                else:
                    line(v, (rx - 3, 12), (rx + 2, 14), (150, 150, 160))  # la barra de seguridad
            save(outline(v), "vagon_%s%s" % (which, "_manos" if hands else ""))


# ================================================================ DARDOS (el puesto, de frente)

def plush(im, kind, x, y):
    """Un peluche colgado (x, y: el gancho)."""
    line(im, (x, y), (x, y + 2), (170, 170, 180))
    if kind == "oso":
        c, dk = (150, 72, 190), (104, 44, 140)
        ell(im, (x - 6, y + 2, x + 6, y + 12), c, INK)
        ell(im, (x - 7, y + 1, x - 3, y + 5), c, INK)
        ell(im, (x + 3, y + 1, x + 7, y + 5), c, INK)
        ell(im, (x - 7, y + 10, x + 7, y + 22), c, INK)
        ell(im, (x - 2, y + 13, x + 2, y + 17), (20, 16, 22))  # el corazón negro
        px(im, x - 2, y + 6, INK)
        px(im, x + 2, y + 6, INK)
        rect(im, (x - 1, y + 8, x + 1, y + 9), dk)
    elif kind == "banano":
        for k in range(18):
            yy = y + 2 + k
            xx = x + int(4 * math.sin(k / 18 * math.pi))
            rect(im, (xx - 3, yy, xx + 2, yy), (246, 214, 72) if k % 5 else (210, 176, 50))
        rect(im, (x - 1, y + 1, x + 1, y + 3), (90, 70, 40))
        px(im, x + 1, y + 8, INK)
        px(im, x + 3, y + 8, INK)
    elif kind == "raton":  # el ratón amarillo de mejillas rojas (de imitación)
        ell(im, (x - 6, y + 4, x + 6, y + 14), (250, 214, 60), INK)
        line(im, (x - 4, y + 4), (x - 7, y - 2), (250, 214, 60), 2)
        line(im, (x + 4, y + 4), (x + 7, y - 2), (250, 214, 60), 2)
        px(im, x - 7, y - 3, INK)
        px(im, x + 7, y - 3, INK)
        ell(im, (x - 6, y + 12, x + 6, y + 22), (250, 214, 60), INK)
        px(im, x - 5, y + 10, (230, 60, 50))
        px(im, x + 5, y + 10, (230, 60, 50))
        px(im, x - 2, y + 8, INK)
        px(im, x + 2, y + 8, INK)
    elif kind == "beagle":  # se parece a Lukas
        ell(im, (x - 6, y + 2, x + 6, y + 13), (236, 232, 222), INK)
        rect(im, (x - 5, y + 2, x + 5, y + 6), (200, 130, 60))
        ell(im, (x - 9, y + 3, x - 4, y + 12), (120, 70, 40), INK)  # las orejas largas
        ell(im, (x + 4, y + 3, x + 9, y + 12), (120, 70, 40), INK)
        ell(im, (x - 6, y + 11, x + 6, y + 22), (236, 232, 222), INK)
        rect(im, (x - 5, y + 13, x + 5, y + 16), (60, 50, 50))  # la mancha negra del lomo
        px(im, x - 2, y + 7, INK)
        px(im, x + 2, y + 7, INK)
        px(im, x, y + 10, INK)
    elif kind == "unicornio":
        ell(im, (x - 6, y + 3, x + 6, y + 13), (250, 248, 250), INK)
        line(im, (x, y + 3), (x + 1, y - 3), (240, 200, 80))
        for k, cc in enumerate([(240, 100, 140), (250, 180, 80), (120, 200, 240)]):
            rect(im, (x - 7 - k, y + 4 + k * 2, x - 6 - k, y + 9 + k * 2), cc)
        ell(im, (x - 6, y + 11, x + 6, y + 22), (250, 248, 250), INK)
        px(im, x + 2, y + 7, INK)
    else:  # osito de color
        c = {"oso_azul": (90, 140, 220), "oso_rosado": (240, 150, 190), "oso_cafe": (160, 110, 70)}[kind]
        ell(im, (x - 5, y + 2, x + 5, y + 11), c, INK)
        ell(im, (x - 6, y + 1, x - 2, y + 5), c, INK)
        ell(im, (x + 2, y + 1, x + 6, y + 5), c, INK)
        ell(im, (x - 6, y + 9, x + 6, y + 20), c, INK)
        px(im, x - 2, y + 6, INK)
        px(im, x + 2, y + 6, INK)


def dardos():
    im = new()
    grad(im, (0, 0, W, 40), (12, 10, 30), (40, 24, 50), 4)
    for x in range(0, W, 4):  # el cable de los bombillos, arriba
        px(im, x, 15 + int(3 * math.sin(x / 40.0)), (70, 60, 60))
    # El letrero: tabla con letras pintadas.
    rect(im, (98, 17, 222, 31), (110, 74, 46))
    ImageDraw.Draw(im).rectangle((98, 17, 222, 31), outline=(70, 46, 30, 255))
    tw = letters_w("DARDOS", 2)
    letters(im, "DARDOS", 160 - tw // 2, 19, (244, 204, 70), 2, (90, 30, 30))
    # El toldo de rayas con ondas.
    for x in range(0, W):
        stripe = (x // 16) % 2 == 0
        colr = (214, 52, 60) if stripe else (240, 236, 226)
        for y in range(31, 42):
            px(im, x, y, mix(colr, (40, 20, 30), 0.15 * (y - 31) / 10))
        wave = 42 + int(3 * abs(math.sin((x % 16) / 16 * math.pi)))
        for y in range(42, wave + 1):
            px(im, x, y, colr)
    # Los postes (de lado y lado del corcho).
    for xpost in (58, 258):
        rect(im, (xpost, 44, xpost + 4, 136), (120, 82, 52))
        line(im, (xpost, 44), (xpost, 136), (150, 104, 66))
    # El corcho: café claro con puntos, marco de madera.
    rect(im, (64, 46, 256, 132), (198, 156, 102))
    speckle(im, (64, 46, 256, 132), [(172, 128, 80), (214, 176, 124), (150, 108, 64)], 0.25)
    ImageDraw.Draw(im).rectangle((63, 45, 257, 133), outline=(92, 60, 36, 255), width=3)
    # Las paredes de tablas detrás de los peluches.
    for (a, b) in [(0, 58), (262, W)]:
        rect(im, (a, 44, b, 132), (86, 56, 36))
        for x in range(a, b, 9):
            line(im, (x, 44), (x, 132), (66, 42, 28))
        speckle(im, (a, 44, b, 132), [(100, 66, 42), (74, 48, 30)], 0.06)
    # Los peluches colgados a los lados.
    left = [("oso", 14, 48), ("banano", 34, 46), ("raton", 50, 50), ("oso_azul", 16, 84), ("beagle", 36, 86), ("oso_rosado", 22, 112)]
    right = [("unicornio", 270, 48), ("oso", 290, 46), ("oso_cafe", 308, 50), ("raton", 272, 84), ("oso_rosado", 296, 86), ("banano", 284, 112)]
    rect(im, (0, 44, 56, 46), (90, 90, 96))
    rect(im, (262, 44, 320, 46), (90, 90, 96))
    for k, xx, yy in left + right:
        plush(im, k, xx, yy)
    # El mostrador: la tabla y el frente de paño rojo con ribete dorado.
    rect(im, (0, 132, W, 140), (150, 104, 66))
    line(im, (0, 132), (W, 132), (190, 140, 92))
    line(im, (0, 140), (W, 140), (92, 60, 36))
    rect(im, (0, 141, W, H), (150, 30, 44))
    for y in range(141, H):
        for x in range(W):
            if (x + y) % 7 == 0:
                px(im, x, y, (130, 24, 38))
    line(im, (0, 143), (W, 143), (236, 190, 70))
    # La lata con los dardos (a la izquierda) y el cartelito del precio, escrito a mano.
    rect(im, (20, 120, 32, 132), (170, 172, 184))
    line(im, (20, 120), (20, 132), (210, 210, 220))
    for k, colr in enumerate([(220, 60, 60), (60, 120, 220), (240, 200, 70)]):
        line(im, (23 + k * 3, 120), (24 + k * 3, 110), (90, 80, 70))
        rect(im, (22 + k * 3, 108, 24 + k * 3, 111), colr)
    rect(im, (226, 118, 282, 132), (240, 236, 214))
    ImageDraw.Draw(im).rectangle((226, 118, 282, 132), outline=(120, 110, 90, 255))
    letters(im, "3 X $1000", 230, 122, (40, 40, 120))
    # El señor de los dardos, detrás del mostrador: gorra, bigote, delantal.
    sx = 298
    rect(im, (sx - 8, 104, sx + 8, 132), (230, 226, 214))
    rect(im, (sx - 10, 106, sx - 8, 128), (60, 110, 160))
    rect(im, (sx + 8, 106, sx + 10, 128), (60, 110, 160))
    ell(im, (sx - 6, 90, sx + 6, 104), (196, 136, 104))
    rect(im, (sx - 7, 89, sx + 7, 93), (200, 50, 46))
    rect(im, (sx - 10, 93, sx - 4, 94), (200, 50, 46))
    rect(im, (sx - 4, 99, sx + 3, 100), (50, 36, 30))
    px(im, sx - 3, 96, INK)
    px(im, sx + 2, 96, INK)
    save(im, "dardos_puesto")
    # Los globos (con brillo y la piolita), el estallido y los dardos.
    cols = [((230, 60, 70), (250, 130, 130), (160, 30, 44)), ((60, 120, 230), (130, 180, 250), (36, 70, 160)),
            ((250, 210, 60), (255, 240, 150), (190, 150, 30)), ((70, 190, 110), (150, 230, 160), (40, 130, 70)),
            ((190, 80, 220), (226, 150, 246), (126, 44, 160)), ((250, 140, 60), (255, 200, 140), (190, 90, 30))]
    for i, (b, lt, dk) in enumerate(cols):
        g = new(16, 22)
        ImageDraw.Draw(g).ellipse((1, 0, 14, 15), fill=b + (255,))
        for y in range(0, 16):
            for x in range(1, 15):
                p = g.getpixel((x, y))
                if p[3] and math.hypot((x - 5) / 6, (y - 4) / 6) < 0.6:
                    px(g, x, y, lt)
                elif p[3] and math.hypot((x - 9) / 7, (y - 11) / 7) < 0.55:
                    px(g, x, y, dk)
        for (x, y) in [(4, 3), (5, 3), (4, 4)]:
            px(g, x, y, (255, 255, 255))
        ImageDraw.Draw(g).polygon([(6, 15), (9, 15), (7, 17)], fill=dk + (255,))  # el nudo
        for y in range(17, 22):
            px(g, 7 + (1 if y % 3 == 0 else 0), y, (230, 230, 230))
        save(outline(g), "globo_%d" % i)
    for fr in range(3):  # el estallido: pedazos de caucho que salen volando
        pop = new(22, 22)
        for k in range(8):
            a = k * 2 * math.pi / 8 + fr * 0.3
            r0 = 3 + fr * 3
            px(pop, 11 + r0 * math.cos(a), 11 + r0 * math.sin(a), (255, 250, 220) if fr == 0 else (230, 230, 230))
            px(pop, 11 + (r0 + 1) * math.cos(a), 11 + (r0 + 1) * math.sin(a), (200, 200, 200))
        if fr == 0:
            ell(pop, (6, 6, 16, 16), (255, 250, 220))
        save(pop, "globo_pop_%d" % fr)
    dart = new(7, 7)  # de frente (va hacia adentro): la punta, las plumas
    for (x, y, c) in [(3, 3, (220, 220, 230)), (1, 1, (220, 60, 60)), (5, 1, (220, 60, 60)), (1, 5, (220, 60, 60)), (5, 5, (220, 60, 60)),
                      (2, 2, (90, 80, 70)), (4, 4, (90, 80, 70)), (2, 4, (90, 80, 70)), (4, 2, (90, 80, 70))]:
        px(dart, x, y, c)
    save(dart, "dardo")
    stuck = new(5, 6)
    for (x, y, c) in [(2, 5, (60, 60, 66)), (2, 4, (90, 80, 70)), (2, 3, (90, 80, 70)), (1, 1, (220, 60, 60)), (3, 1, (220, 60, 60)), (2, 0, (240, 90, 90)), (2, 2, (200, 50, 50))]:
        px(stuck, x, y, c)
    save(stuck, "dardo_clavado")
    hand = new(30, 34)  # su mano con el dardo, abajo (la manga gris del saco)
    rect(hand, (12, 18, 24, 33), (82, 86, 106))
    line(hand, (12, 18), (12, 33), (54, 56, 72))
    rect(hand, (12, 16, 24, 18), (206, 200, 184))
    ell(hand, (10, 8, 22, 18), (214, 150, 120))
    line(hand, (12, 9), (19, 9), (172, 110, 90))
    line(hand, (14, 11), (6, 2), (90, 80, 70), 2)  # el dardo
    rect(hand, (3, 0, 6, 3), (220, 60, 60))
    px(hand, 15, 12, (220, 220, 230))
    save(outline(hand), "mano_dardo")
    META["dardos"] = {"corcho": [64, 46, 256, 132]}


# ================================================================ GARRA (la máquina de frente)

def premio(kind):
    im = new(22, 22)
    if kind == "oso":  # el oso morado de corazón negro (el de siempre)
        c, dk = (150, 72, 190), (104, 44, 140)
        ell(im, (5, 1, 17, 12), c)
        ell(im, (3, 0, 8, 5), c)
        ell(im, (14, 0, 19, 5), c)
        ell(im, (4, 10, 18, 21), c)
        ell(im, (9, 13, 13, 17), (20, 16, 22))
        px(im, 9, 5, INK)
        px(im, 13, 5, INK)
        rect(im, (10, 7, 12, 8), dk)
        line(im, (4, 20), (18, 20), dk)
    elif kind == "conejo":
        c = (246, 170, 200)
        ell(im, (6, 6, 16, 15), c)
        ell(im, (6, 0, 9, 8), c)
        ell(im, (13, 0, 16, 8), c)
        px(im, 7, 2, (255, 220, 230))
        px(im, 14, 2, (255, 220, 230))
        ell(im, (5, 13, 17, 21), c)
        px(im, 9, 9, INK)
        px(im, 13, 9, INK)
        px(im, 11, 11, (220, 90, 120))
    elif kind == "beagle":  # se parece a Lukas
        ell(im, (5, 2, 17, 13), (236, 232, 222))
        rect(im, (6, 2, 16, 6), (200, 130, 60))
        ell(im, (2, 3, 7, 13), (120, 70, 40))
        ell(im, (15, 3, 20, 13), (120, 70, 40))
        ell(im, (5, 11, 17, 21), (236, 232, 222))
        rect(im, (6, 13, 16, 16), (60, 50, 50))
        px(im, 9, 7, INK)
        px(im, 13, 7, INK)
        px(im, 11, 10, INK)
    else:  # el unicornio
        ell(im, (5, 4, 17, 14), (250, 248, 250))
        line(im, (11, 4), (12, 0), (240, 200, 80))
        for k, cc in enumerate([(240, 100, 140), (250, 180, 80), (120, 200, 240)]):
            rect(im, (3 + k, 5 + k * 2, 4 + k, 10 + k * 2), cc)
        ell(im, (5, 12, 17, 21), (250, 248, 250))
        px(im, 13, 8, INK)
    return outline(im)


def garra():
    im = new(fill=(20, 14, 26))
    # El salón de maquinitas: alfombra con figuritas y el brillo de otras máquinas a los lados.
    for y in range(140, H):
        for x in range(W):
            px(im, x, y, (40, 26, 60) if (x // 6 + y // 6) % 2 else (34, 22, 52))
            if (x * 7 + y * 3) % 23 == 0:
                px(im, x, y, (240, 200, 60))
    for (x0_, col) in [(0, (60, 200, 220)), (290, (240, 90, 140))]:
        grad(im, (x0_, 20, x0_ + 30, 140), mix(col, (20, 14, 26), 0.3), (20, 14, 26), 5)
    # El mueble: marco rosado con cromo.
    rect(im, (34, 16, 286, 180), (206, 50, 120))
    ImageDraw.Draw(im).rectangle((34, 16, 286, 180), outline=(150, 30, 90, 255), width=2)
    line(im, (36, 18), (284, 18), (250, 120, 180))
    for x in (38, 282):
        line(im, (x, 18), (x, 178), (230, 230, 240))
    # La marquesina: letras de bombillos.
    rect(im, (44, 18, 276, 34), (120, 20, 80))
    tw = letters_w("GARRA", 2)
    letters(im, "GARRA", 160 - tw // 2, 21, (255, 230, 120), 2, (200, 60, 30))
    for x in range(46, 276, 6):
        px(im, x, 19, (255, 240, 180))
        px(im, x, 33, (255, 240, 180))
    # Adentro: la pared de atrás (estrellitas), la montaña de peluches, el hueco de los premios.
    gx0, gy0, gx1, gy1 = 44, 36, 276, 140
    grad(im, (gx0, gy0, gx1, gy1), (40, 24, 70), (70, 30, 90), 5)
    for k in range(40):
        x, y = R.randrange(gx0 + 2, gx1 - 2), R.randrange(gy0 + 2, gy1 - 40)
        px(im, x, y, (120, 80, 160))
        px(im, x + 1, y, (90, 60, 130))
    pile_cols = [(150, 72, 190), (246, 170, 200), (236, 232, 222), (90, 140, 220), (250, 214, 60), (160, 110, 70), (120, 200, 160)]
    for k in range(70):  # la montaña: cabezas y orejas de peluches amontonados
        x = R.randrange(88, gx1 - 4)
        top = gy1 - 10 - int(18 * math.sin((x - 88) / (gx1 - 88) * math.pi))
        y = R.randrange(top, gy1 - 2)
        c = R.choice(pile_cols)
        ell(im, (x - 5, y - 4, x + 5, y + 4), c, mix(c, INK, 0.6))
        px(im, x - 2, y - 1, INK)
        px(im, x + 2, y - 1, INK)
    # El hueco de los premios (abajo a la izquierda): paredes de acrílico y la boca oscura.
    rect(im, (48, 104, 84, 140), (60, 40, 80))
    rect(im, (52, 108, 80, 140), (14, 10, 18))
    for x in (48, 84):
        line(im, (x, 104), (x, 140), (200, 230, 250))
    line(im, (48, 104), (84, 104), (200, 230, 250))
    # El tablero: la palanca, el botón, la ranura de la moneda.
    rect(im, (40, 142, 280, 176), (180, 40, 104))
    line(im, (40, 142), (280, 142), (250, 120, 180))
    rect(im, (40, 170, 280, 176), (120, 20, 70))
    rect(im, (96, 150, 104, 166), (50, 50, 56))
    line(im, (100, 158), (100, 150), (180, 180, 190), 2)
    ell(im, (95, 144, 105, 154), (220, 40, 40), INK)
    px(im, 98, 147, (255, 160, 160))
    ell(im, (150, 148, 168, 166), (40, 180, 90), INK)
    ell(im, (153, 151, 165, 163), (80, 230, 130))
    px(im, 156, 153, (200, 255, 210))
    rect(im, (214, 150, 230, 166), (60, 60, 66))
    rect(im, (220, 153, 223, 163), (14, 10, 18))
    rect(im, (232, 152, 266, 162), (250, 230, 120))
    letters(im, "$500", 235, 155, (120, 40, 40))
    save(im, "garra_maquina")
    # El vidrio: reflejos (encima de todo lo de adentro).
    glass = new()
    for (x, w) in [(70, 6), (84, 2), (200, 8), (214, 3)]:
        for y in range(gy0, gy1):
            for dx in range(w):
                xx = x + dx + (y - gy0) // 2
                if gx0 < xx < gx1:
                    px(glass, xx, y, (255, 255, 255, 34 if dx else 60))
    save(glass, "garra_vidrio")
    # La garra: el cilindro de cromo y las tres uñas (abierta y cerrada).
    for state in ["abierta", "cerrada"]:
        cl = new(22, 20)
        rect(cl, (8, 0, 13, 6), (180, 182, 196))
        line(cl, (8, 0), (8, 6), (230, 230, 240))
        line(cl, (13, 0), (13, 6), (110, 112, 126))
        rect(cl, (6, 6, 15, 8), (140, 142, 156))
        claws = ([((7, 8), (1, 15), (3, 19)), ((14, 8), (20, 15), (18, 19)), ((10, 8), (10, 16), (10, 18))] if state == "abierta"
                 else [((7, 8), (5, 15), (9, 19)), ((14, 8), (16, 15), (12, 19)), ((10, 8), (10, 16), (10, 18))])
        for (a, b, c2) in claws:
            line(cl, a, b, (200, 202, 214), 2)
            line(cl, b, c2, (200, 202, 214), 2)
        save(outline(cl), "garra_" + state)
    for k in ["oso", "conejo", "beagle", "unicornio"]:
        save(premio(k), "premio_" + k)
    META["garra"] = {"vidrio": [gx0, gy0, gx1, gy1], "hueco": [52, 108, 80, 140]}


# ================================================================ RUEDA DE CHICAGO (y la fiesta de antes)

def rueda():
    tall = new(320, 300)
    grad(tall, (0, 0, 320, 110), (8, 8, 28), (44, 30, 70), 6)
    for _ in range(120):
        px(tall, R.randrange(320), R.randrange(0, 90), (250, 240, 210) if R.random() < 0.7 else (190, 190, 240))
    ell(tall, (250, 14, 266, 30), (246, 240, 214))
    for x in range(320):  # los cerros y el resplandor de la ciudad, lejos
        h = 96 + int(6 * math.sin(x / 30.0) + 4 * math.sin(x / 11.0))
        for y in range(h, 110):
            px(tall, x, y, (34, 26, 50))
        if x % 3 == 0 and R.random() < 0.4:
            px(tall, x, h + R.randrange(2, 10), R.choice([(255, 200, 120), (240, 160, 90)]))
    # El barrio: techos de zinc y de teja, ventanas prendidas, calles con postes.
    rect(tall, (0, 110, 320, 230), (30, 26, 34))
    for y0_ in range(112, 228, 18):
        rect(tall, (0, y0_ + 12, 320, y0_ + 15), (54, 50, 58))
        for x in range(0, 320, 26):
            px(tall, x + 5, y0_ + 12, (255, 220, 130))
        x = R.randrange(-8, 0)
        while x < 320:
            w = R.randrange(14, 26)
            roof = R.choice([((120, 124, 132), (90, 94, 102)), ((150, 76, 54), (116, 56, 40)), ((110, 110, 116), (150, 90, 60))])
            rect(tall, (x, y0_, x + w - 2, y0_ + 11), roof[0])
            for xx in range(x, x + w - 2, 3):
                line(tall, (xx, y0_), (xx, y0_ + 11), roof[1])
            if R.random() < 0.5:
                rect(tall, (x + 3, y0_ + 7, x + 5, y0_ + 9), R.choice([(255, 210, 120), (250, 180, 90), (180, 220, 255)]))
            x += w
    # Árboles entre las casas (copas redondas) y el halo de los postes.
    for _ in range(26):
        tx, ty = R.randrange(0, 320), R.randrange(116, 226)
        ell(tall, (tx - 5, ty - 4, tx + 5, ty + 4), (36, 70, 44), (20, 40, 26))
        px(tall, tx - 2, ty - 2, (60, 104, 64))
    # La plaza (con la fuente y el carrito de perros), la iglesia, el billar.
    rect(tall, (130, 160, 210, 196), (130, 92, 74))
    for y in range(160, 197, 6):
        line(tall, (130, y), (210, y), (112, 78, 62))
    ell(tall, (160, 170, 180, 184), (90, 140, 190), (60, 60, 70))
    px(tall, 170, 176, (220, 240, 255))
    rect(tall, (194, 186, 200, 190), (240, 220, 200))
    px(tall, 197, 185, (255, 230, 150))
    rect(tall, (40, 130, 56, 158), (236, 228, 210))
    ImageDraw.Draw(tall).polygon([(38, 130), (48, 118), (58, 130)], fill=(150, 76, 54, 255))
    px(tall, 48, 115, (255, 230, 150))
    rect(tall, (236, 140, 270, 152), (40, 30, 40))
    letters(tall, "BILLAR", 238, 143, (255, 90, 180))
    # El río (con la luna) y el puente.
    for y in range(230, 248):
        for x in range(320):
            px(tall, x, y, (34, 54, 84) if (x + y * 3) % 9 else (60, 90, 130))
    for x in range(250, 270):
        px(tall, x, 236 + (x % 3), (240, 236, 200))
    rect(tall, (40, 226, 64, 250), (90, 90, 100))
    # La feria, justo abajo: el techo del carrusel, la pista de los chocones, la carrilera, los bombillos.
    rect(tall, (0, 248, 320, 300), (52, 40, 44))
    speckle(tall, (0, 248, 320, 300), [(230, 90, 120), (90, 170, 230), (240, 210, 90)], 0.03)
    for i in range(14):
        a0, a1 = i * 2 * math.pi / 14, (i + 1) * 2 * math.pi / 14
        ImageDraw.Draw(tall).polygon([(90, 274), (90 + 28 * math.cos(a0), 274 + 14 * math.sin(a0)), (90 + 28 * math.cos(a1), 274 + 14 * math.sin(a1))],
                                     fill=((214, 52, 60) if i % 2 == 0 else (240, 236, 226)) + (255,))
    rect(tall, (160, 262, 232, 292), (112, 118, 132))
    ImageDraw.Draw(tall).rectangle((160, 262, 232, 292), outline=(236, 196, 58, 255))
    for k, cc in enumerate([(206, 50, 56), (58, 112, 206), (236, 196, 58)]):
        rect(tall, (170 + k * 20, 270 + k * 6, 178 + k * 20, 276 + k * 6), cc)
    for x in range(240, 320, 2):
        px(tall, x, 258 + int(10 * math.sin(x / 12.0)), (200, 60, 60))
    for x in range(0, 320, 5):
        px(tall, x, 252 + (x // 5) % 2, [(255, 120, 120), (255, 220, 120), (140, 220, 255)][(x // 5) % 3])
    save(tall, "rueda_barrio")
    # La cabina por dentro: el techo de lata con bombillos, los barrotes de los lados, la banca y él de espaldas.
    cab = new()
    rect(cab, (0, 0, W, 20), (150, 36, 46))
    line(cab, (0, 20), (W, 20), (100, 20, 30))
    for x in range(4, W, 10):
        px(cab, x, 16, (255, 236, 150))
        px(cab, x + 1, 5, (190, 190, 200))  # los remaches
    for x0_ in (0, 290):
        rect(cab, (x0_, 20, x0_ + 29, 140), (130, 30, 40))
        for x in range(x0_ + 4, x0_ + 28, 6):
            line(cab, (x, 20), (x, 140), (190, 190, 200))
            line(cab, (x + 1, 20), (x + 1, 140), (120, 120, 130))
    rect(cab, (0, 128, W, H), (110, 26, 36))
    rect(cab, (0, 128, W, 132), (190, 190, 200))  # la barra de seguridad
    line(cab, (0, 128), (W, 128), (240, 240, 250))
    rect(cab, (60, 146, 260, 180), (80, 50, 40))  # la banca
    for y in range(148, 180, 6):
        line(cab, (60, y), (260, y), (64, 40, 32))
    # Él, de espaldas: el pelo parado con canas, los hombros del saco que le queda grande (más anchos
    # que él), el cuello de la camisa, el morral con las correas.
    bx = 150
    sh = [(bx - 30, 180), (bx - 28, 140), (bx - 20, 128), (bx - 8, 124), (bx + 8, 124), (bx + 20, 128), (bx + 28, 140), (bx + 30, 180)]
    ImageDraw.Draw(cab).polygon(sh, fill=(82, 86, 106, 255), outline=INK + (255,))
    for y in range(130, 180, 3):  # la arruga del saco en la espalda
        px(cab, bx - 1 + (y // 3) % 2, y, (66, 70, 88))
    line(cab, (bx - 24, 136), (bx - 27, 178), (66, 70, 88))
    line(cab, (bx + 24, 136), (bx + 27, 178), (100, 104, 124))
    rect(cab, (bx - 6, 120, bx + 6, 126), (206, 200, 184))  # el cuello de la camisa
    rect(cab, (bx - 5, 114, bx + 5, 121), (196, 136, 104))  # la nuca
    rect(cab, (bx - 13, 134, bx + 13, 168), (112, 84, 58))  # el morral
    ImageDraw.Draw(cab).rectangle((bx - 13, 134, bx + 13, 168), outline=(70, 50, 34, 255))
    rect(cab, (bx - 10, 138, bx + 10, 146), (130, 98, 68))  # la tapa
    line(cab, (bx - 10, 146), (bx + 10, 146), (70, 50, 34))
    px(cab, bx, 147, (200, 190, 120))  # la hebilla
    for side in (-1, 1):  # las correas, por encima de los hombros
        line(cab, (bx + side * 10, 134), (bx + side * 14, 126), (82, 60, 42), 2)
    ell(cab, (bx - 11, 94, bx + 11, 118), (40, 38, 46), INK)  # la cabeza: el pelo
    for (x, y) in [(bx - 4, 96), (bx + 3, 98), (bx - 7, 103), (bx + 6, 106), (bx - 2, 110)]:
        px(cab, x, y, (116, 114, 118))
    for k in range(6):  # el mechón parado
        px(cab, bx - 2 + k, 93 - (k % 2), (40, 38, 46))
    px(cab, bx - 11, 106, (196, 136, 104))  # las orejas
    px(cab, bx + 11, 106, (196, 136, 104))
    save(cab, "rueda_cabina")
    # La fiesta de antes: la terraza, las luces de la ciudad, la baranda, la mesa con el aguardiente, el bafle.
    f = new()
    grad(f, (0, 0, W, 120), (20, 10, 30), (60, 26, 50), 5)
    for _ in range(60):
        x, y = R.randrange(W), R.randrange(60, 118)
        c = R.choice([(255, 200, 120), (250, 150, 90), (200, 220, 255), (255, 240, 200)])
        px(f, x, y, c)
        if R.random() < 0.3:
            px(f, x + 1, y, mix(c, (60, 26, 50), 0.5))
    rect(f, (0, 118, W, 124), (236, 232, 222))  # la baranda
    for x in range(2, W, 8):
        rect(f, (x, 124, x + 3, 132), (220, 216, 206))
    rect(f, (0, 132, W, H), (176, 96, 66))  # las baldosas de barro
    for y in range(132, H, 8):
        line(f, (0, y), (W, y), (150, 78, 52))
        for x in range((y // 8 % 2) * 8, W, 16):
            line(f, (x, y), (x, y + 8), (150, 78, 52))
    rect(f, (240, 120, 300, 128), (240, 240, 236))  # la mesa con mantel
    rect(f, (244, 128, 296, 150), (230, 230, 226))
    for k, x in enumerate(range(248, 292, 9)):  # el aguardiente (la de tapa azul) y los vasos
        if k % 2 == 0:
            rect(f, (x, 108, x + 3, 120), (220, 230, 236))
            rect(f, (x, 106, x + 3, 108), (40, 80, 180))
            rect(f, (x, 113, x + 3, 116), (40, 80, 180))
        else:
            rect(f, (x, 115, x + 3, 120), (250, 250, 250))
    rect(f, (14, 96, 40, 140), (24, 22, 28))  # el bafle
    for cy in (106, 126):
        ell(f, (19, cy - 7, 35, cy + 7), (50, 48, 56), (80, 80, 90))
        ell(f, (24, cy - 2, 30, cy + 2), (90, 90, 100))
    save(f, "fiesta_terraza")
    # La gente bailando (sin cara: es un recuerdo) y él, joven, sin barba, con camisa planchada.
    for fr in range(2):
        g = new(120, 52)
        for k in range(6):
            x = 10 + k * 19
            bob = (k + fr) % 2
            c = [(200, 90, 110), (90, 140, 200), (230, 180, 80), (120, 180, 120), (180, 110, 200), (230, 130, 80)][k]
            rect(g, (x - 4, 18 + bob, x + 4, 40 + bob), mix(c, (40, 20, 30), 0.35))
            ell(g, (x - 4, 9 + bob, x + 4, 18 + bob), mix(c, (30, 16, 24), 0.6))
            line(g, (x - 4, 22 + bob), (x - 8 + fr * 3, 14 + bob), mix(c, (40, 20, 30), 0.35), 2)
            line(g, (x + 4, 22 + bob), (x + 8 - fr * 3, 16 + bob), mix(c, (40, 20, 30), 0.35), 2)
            line(g, (x - 2, 40 + bob), (x - 4 + fr * 2, 51), (40, 30, 40), 2)
            line(g, (x + 2, 40 + bob), (x + 3 - fr * 2, 51), (40, 30, 40), 2)
        save(g, "fiesta_gente_%d" % fr)
    for state in ["baila_0", "baila_1", "humo"]:
        j = new(24, 40)
        bob = 1 if state == "baila_1" else 0
        rect(j, (7, 13 + bob, 16, 28 + bob), (240, 240, 244))  # la camisa planchada
        line(j, (11, 14 + bob), (11, 27 + bob), (210, 210, 220))
        rect(j, (8, 28 + bob, 15, 38), (44, 44, 60))
        ell(j, (7, 3 + bob, 16, 13 + bob), (214, 150, 120))
        rect(j, (7, 2 + bob, 16, 5 + bob), (30, 26, 30))  # el pelo peinado, sin canas
        px(j, 10, 8 + bob, INK)
        px(j, 13, 8 + bob, INK)
        if state == "humo":
            line(j, (16, 16), (14, 10), (240, 240, 244), 2)  # la mano a la boca
            line(j, (14, 10), (18, 9), (250, 250, 250))
            px(j, 19, 9, (255, 120, 40))
        else:
            line(j, (16, 16 + bob), (20, 12 + bob), (240, 240, 244), 2)
            rect(j, (19, 9 + bob, 21, 12 + bob), (230, 240, 250))  # la copa de aguardiente
            line(j, (7, 16 + bob), (3, 20 - bob * 3), (240, 240, 244), 2)
        save(outline(j), "joven_" + state)


# ================================================================ LA FERIA POR DENTRO (donde se camina: scripts/world/Feria.gd)
# 512x200, vista de arriba en tres cuartos, como el barrio. Lo quieto va en el fondo; lo que se mueve
# (la rueda, los caballitos, los chocones, el carrito, los bombillos) lo dibuja Feria.gd con las piezas
# chiquitas de aquí. Las atracciones están donde estaban (las paredes invisibles no cambian).

FW, FH = 512, 200


def coaster_y(x):
    return 70 - 26 * abs(math.sin((x - 260) * 0.045))


def feria_lote():
    im = new(FW, FH)
    # El cielo: noche, estrellas, la ciudad lejos con sus ventanitas.
    grad(im, (0, 0, FW, 60), (10, 8, 30), (52, 30, 66), 6)
    for _ in range(90):
        px(im, R.randrange(FW), R.randrange(0, 40), (250, 240, 210) if R.random() < 0.7 else (190, 190, 240))
    x = 0
    while x < FW:
        w = R.randrange(10, 22)
        h = R.randrange(8, 22)
        rect(im, (x, 60 - h, x + w, 60), (30, 24, 42))
        for wy in range(60 - h + 3, 58, 5):
            for wx in range(x + 2, x + w - 2, 4):
                if R.random() < 0.3:
                    px(im, wx, wy, R.choice([(255, 210, 120), (250, 180, 90)]))
        x += w + R.randrange(0, 4)
    # El piso: tierra pisada, con huellas de llantas, charcos que reflejan los bombillos, papelitos.
    grad(im, (0, 60, FW, FH), (78, 60, 50), (62, 46, 40), 5)
    speckle(im, (0, 60, FW, FH), [(70, 54, 44), (90, 70, 56), (56, 42, 36)], 0.12)
    for (cx, cy, w, h) in [(40, 120, 26, 6), (200, 150, 30, 7), (350, 176, 34, 6), (470, 160, 22, 5)]:  # charcos
        ell(im, (cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2), (40, 44, 70))
        for k in range(5):
            px(im, cx - w // 2 + 4 + k * 4, cy, R.choice([(255, 120, 140), (255, 220, 120), (140, 220, 255)]))
    speckle(im, (0, 62, FW, FH), [(230, 90, 120), (90, 170, 230), (240, 210, 90), (120, 220, 140)], 0.005)
    for y in (96, 98):  # el cable grueso de la luz, por el piso
        for x in range(0, 170):
            px(im, x, y + int(2 * math.sin(x / 9.0)), (30, 28, 32))
    # La montaña rusa: la estructura de madera y la carrilera (el carrito lo mueve el juego).
    for x in range(262, 372, 6):
        ty = coaster_y(x) + 3
        line(im, (x, ty), (x, 86), (110, 74, 48))
        px(im, x + 1, ty + 2, (140, 98, 64))
    for x in range(262, 366, 12):
        line(im, (x, 86), (x + 12, coaster_y(x + 12) + 4), (92, 62, 40))
        line(im, (x, coaster_y(x) + 4), (x + 12, 86), (92, 62, 40))
    for x in range(260, 372):
        px(im, x, coaster_y(x), (214, 60, 64))
        px(im, x, coaster_y(x) + 1, (214, 60, 64))
        px(im, x, coaster_y(x) + 3, (140, 36, 44))
        if x % 4 == 0:
            line(im, (x, coaster_y(x)), (x, coaster_y(x) + 3), (60, 40, 30))
    rect(im, (274, 80, 300, 88), (150, 40, 60))  # la estación de abajo
    rect(im, (274, 78, 300, 80), (236, 190, 70))
    # La rueda de Chicago: las patas en A y la boletería (el aro y las cabinas los mueve el juego).
    hub = (430, 64)
    for leg in [(412, 132), (448, 132), (404, 132), (456, 132)]:
        line(im, hub, leg, (120, 122, 134), 2)
    for y in range(80, 132, 8):  # los travesaños de las patas
        f = (y - 64) / (132 - 64)
        line(im, (int(430 - 18 * f), y), (int(430 + 18 * f), y), (100, 102, 116))
    rect(im, (404, 124, 456, 140), (110, 74, 48))
    rect(im, (404, 122, 456, 124), (236, 190, 70))
    rect(im, (440, 112, 456, 124), (150, 40, 60))  # la boletería
    rect(im, (443, 115, 453, 120), (250, 230, 160))
    # El carrusel: el piso redondo (los caballitos y el techo los dibuja el juego encima).
    ell(im, (58, 98, 126, 118), (110, 76, 50), INK)
    ell(im, (60, 100, 124, 114), (150, 104, 66))
    for a in range(0, 360, 30):
        px(im, 92 + 30 * math.cos(math.radians(a)), 107 + 6 * math.sin(math.radians(a)), (236, 190, 70))
    rect(im, (89, 84, 95, 108), (150, 40, 60))  # la columna del centro
    line(im, (89, 84), (89, 108), (236, 190, 70))
    # Los chocones: el pabellón con el piso de lata, la baranda y el techo de malla (los carritos, el juego).
    rect(im, (176, 84, 252, 118), (100, 106, 120))
    for yy in range(86, 118, 4):
        for xx in range(178 + (yy // 4 % 2) * 2, 252, 4):
            px(im, xx, yy, (124, 130, 144))
    ImageDraw.Draw(im).rectangle((175, 83, 253, 119), outline=(236, 196, 58, 255))
    ImageDraw.Draw(im).rectangle((174, 82, 254, 120), outline=(30, 28, 34, 255))
    for xx in (176, 252):
        line(im, (xx, 64), (xx, 84), (90, 92, 104), 2)
    rect(im, (172, 62, 256, 66), (60, 62, 76))  # el techo de malla
    for xx in range(174, 256, 4):
        line(im, (xx, 62), (xx, 66), (110, 112, 126))
    rect(im, (190, 56, 238, 62), (150, 40, 60))  # el letrero
    letters(im, "CHOCONES", 192, 57, (255, 230, 120))
    # El puesto de los dardos: toldo de rayas, la pared de corcho con globos, el mostrador.
    for xx in range(128, 172):
        for yy in range(128, 136):
            px(im, xx, yy, (214, 52, 60) if (xx // 4) % 2 == 0 else (240, 236, 226))
    rect(im, (130, 136, 170, 154), (198, 156, 102))
    speckle(im, (130, 136, 170, 154), [(172, 128, 80), (214, 176, 124)], 0.2)
    for k in range(6):  # los globos (quietos: en el fondo)
        sphere(im, 136 + (k % 3) * 13, 141 + (k // 3) * 8, 3, *[[(230, 60, 70), (250, 130, 130), (160, 30, 44)], [(60, 120, 230), (130, 180, 250), (36, 70, 160)],
                                                                [(250, 210, 60), (255, 240, 150), (190, 150, 30)]][k % 3])
    rect(im, (128, 154, 172, 162), (150, 104, 66))
    line(im, (128, 154), (172, 154), (190, 140, 92))
    rect(im, (128, 162, 172, 166), (150, 30, 44))
    # La garra: la máquina rosada con marquesina, vidrio y peluches.
    rect(im, (246, 134, 278, 166), (206, 50, 120))
    ImageDraw.Draw(im).rectangle((246, 134, 278, 166), outline=(120, 20, 70, 255))
    rect(im, (248, 136, 276, 141), (120, 20, 80))
    for xx in range(249, 276, 3):
        px(im, xx, 137, (255, 230, 120))
    rect(im, (249, 142, 275, 156), (60, 30, 80))
    for k in range(7):
        ell(im, (250 + k * 3, 151, 254 + k * 3, 155), R.choice([(150, 72, 190), (246, 170, 200), (236, 232, 222), (250, 214, 60)]))
    line(im, (249, 142), (256, 156), (200, 220, 240))
    rect(im, (248, 158, 276, 164), (180, 40, 104))
    px(im, 254, 160, (220, 40, 40))
    px(im, 266, 160, (60, 220, 120))
    # Los puestos de comida (para que la feria huela): salchipapas y algodón de azúcar.
    for (sx, name, col) in [(330, "PAPAS", (240, 200, 70)), (196, "OBLEAS", (240, 150, 190))]:
        sy = 172
        rect(im, (sx, sy, sx + 44, sy + 18), (150, 104, 66))
        for xx in range(sx - 2, sx + 46):
            for yy in range(sy - 8, sy):
                px(im, xx, yy, col if (xx // 4) % 2 == 0 else (240, 236, 226))
        letters(im, name, sx + 22 - letters_w(name) // 2, sy + 3, (60, 30, 30))
        px(im, sx + 38, sy - 10, (200, 200, 210))
        for k in range(3):  # el humito
            px(im, sx + 38 + (k % 2), sy - 12 - k * 3, (200, 200, 210))
    # El arco de la entrada, abajo a la izquierda: postes de lata con bombillos y el letrero.
    for xx in (22, 56):
        rect(im, (xx, FH - 32, xx + 3, FH - 2), (196, 150, 40))
        line(im, (xx, FH - 32), (xx, FH - 2), (244, 204, 70))
    rect(im, (16, FH - 40, 66, FH - 30), (200, 40, 50))
    ImageDraw.Draw(im).rectangle((16, FH - 40, 66, FH - 30), outline=(120, 20, 30, 255))
    letters(im, "FERIA", 26, FH - 38, (255, 236, 150))
    save(im, "lote_fondo")
    # Las piezas chiquitas que se mueven.
    gcols = [(214, 52, 60), (60, 110, 200), (236, 196, 58), (64, 170, 92), (150, 72, 190), (240, 140, 60)]
    for i, c in enumerate(gcols):
        g = new(9, 8)
        rect(g, (1, 0, 7, 1), mix(c, (255, 255, 255), 0.3))  # el techito
        rect(g, (0, 2, 8, 6), c)
        rect(g, (1, 3, 7, 4), (40, 40, 60))  # la ventana
        px(g, 2, 3, (255, 220, 140))
        line(g, (4, 0), (4, -2), (150, 150, 160))
        save(outline(g), "gondola_%d" % i)
    for i, c in enumerate([(236, 232, 222), (226, 180, 90), (60, 56, 66)]):
        hh = new(12, 9)
        ell(hh, (2, 3, 9, 7), c)
        rect(hh, (8, 1, 10, 4), c)
        px(hh, 11, 2, c)
        line(hh, (3, 7), (2, 8), c)
        line(hh, (8, 7), (9, 8), c)
        px(hh, 5, 3, (206, 52, 58))
        save(outline(hh), "mini_caballo_%d" % i)
    roof = new(76, 26)
    for i in range(16):
        a0, a1 = 2 + i * 4.5, 2 + (i + 1) * 4.5
        ImageDraw.Draw(roof).polygon([(38, 1), (a0, 18), (a1, 18)], fill=((214, 52, 60) if i % 2 == 0 else (240, 236, 226)) + (255,))
    rect(roof, (1, 18, 74, 21), (236, 190, 70))
    for x in range(3, 74, 6):
        ell(roof, (x - 2, 20, x + 3, 25), (214, 52, 60) if (x // 6) % 2 == 0 else (60, 110, 200))
    save(outline(roof), "mini_carrusel_techo")
    for name, (b, l, d) in CAR_COLS.items():
        mc = new(11, 8)
        ImageDraw.Draw(mc).rounded_rectangle((0, 1, 10, 7), radius=2, fill=(28, 26, 30, 255))
        rect(mc, (1, 2, 9, 5), b)
        line(mc, (1, 2), (9, 2), l)
        px(mc, 4, 1, (40, 38, 46))  # quien maneja
        px(mc, 5, 1, (40, 38, 46))
        line(mc, (2, 0), (2, -4), (170, 170, 180))
        save(mc, "mini_chocon_" + name)
    cart = new(10, 7)
    rect(cart, (0, 2, 9, 5), (206, 50, 56))
    line(cart, (0, 3), (9, 3), (244, 204, 70))
    px(cart, 3, 1, (40, 38, 46))
    px(cart, 7, 1, (110, 70, 40))
    px(cart, 2, 6, (40, 38, 44))
    px(cart, 7, 6, (40, 38, 44))
    save(outline(cart), "mini_vagon")


SCENES = {"chocones": chocones, "carrusel": carrusel, "montana": montana, "dardos": dardos, "garra": garra, "rueda": rueda,
          "lote": feria_lote}


def main():
    want = sys.argv[1:] or list(SCENES)
    meta_path = os.path.join(OUT, "feria.json")
    if os.path.exists(meta_path):
        META.update(json.load(open(meta_path, encoding="utf-8")))
    for name in want:
        SCENES[name]()
        print("feria:", name)
    os.makedirs(OUT, exist_ok=True)
    json.dump(META, open(meta_path, "w", encoding="utf-8"), indent=1)


if __name__ == "__main__":
    main()
