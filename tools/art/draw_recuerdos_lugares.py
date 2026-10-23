"""Los dos recuerdos que eran baldosas planas, dibujados enteros (python -X utf8 tools/art/draw_recuerdos_lugares.py).

    patio        el recuerdo de la pelota (scripts/world/Memory1.gd), 480x192: la casa de bahareque con su
                 techo de teja, la pila de lavar, la cuerda con la ropa, la cerca de alambre de púas y el
                 potrero detrás (con su vaca), el palo de mango con los mangos en el piso, la llanta pintada,
                 las gallinas, y el arco: dos chanclas, a la derecha, donde se va la pelota. Lo pasa a sepia el
                 filtro de los recuerdos (MoodFilter.memory_on).
    calle_antes  la calle del día de la Renegade (scripts/world/FlashbackMoto.gd), 480x192: la casa de dos
                 pisos con balcón y geranios, la tienda El Porvenir con las canastas de envases, el taller de
                 MOTOS USADAS con la cortina arriba, la casa azul con el gato en el muro, la pared del que
                 arregla licuadoras, el poste con los cables, la golosa pintada en el andén, el bordillo
                 amarillo y la calle con sus remiendos y la sombra de los cables.

Vista de arriba en 3/4, como el barrio (draw_interiores.py: contorno violeta oscuro, colores gastados).
Lo que se mueve o se camina por detrás (la pelota, la sombra, la moto, el vendedor, la cerca de abajo) lo
sigue poniendo el script encima. Los choques (lo que no se camina) también están en el script.
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from draw_interiores import Room, INK, mix, dark, light, draw_text  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "recuerdos")
W, H = 480, 192


def text2(R, s, x, y, c, shade=None):
    """Letras de 3x5 al doble (los letreros pintados a mano)."""
    from draw_relleno import GLYPH
    G = dict(GLYPH, F=["111", "100", "110", "100", "100"], K=["101", "110", "100", "110", "101"],
             Q=["111", "101", "101", "111", "001"], W=["10001", "10001", "10101", "10101", "01010"],
             X=["101", "101", "010", "101", "101"])
    cx = x
    for ch in s:
        g = G.get(ch, G[" "])
        for j, row in enumerate(g):
            for i, v in enumerate(row):
                if v == "1":
                    if shade:
                        R.rect(cx + i * 2 + 1, y + j * 2 + 1, cx + i * 2 + 2, y + j * 2 + 2, shade)
                    R.rect(cx + i * 2, y + j * 2, cx + i * 2 + 1, y + j * 2 + 1, c)
        cx += len(g[0]) * 2 + 2
    return cx


def text_w(s, scale=1):
    from draw_relleno import GLYPH
    return sum((len(GLYPH.get(ch, GLYPH[" "])[0]) + 1) * scale for ch in s)


def dither(R, x0, y0, x1, y1, k=0.82, step=2):
    """Sombra tramada sobre lo que ya hay."""
    for y in range(max(0, y0), min(R.h, y1)):
        for x in range(max(0, x0), min(R.w, x1)):
            if (x + y) % step == 0:
                c = R.im.getpixel((x, y))
                R.im.putpixel((x, y), tuple(int(v * k) for v in c[:3]) + (255,))


def dither_ell(R, cx, cy, rx, ry, k=0.8):
    """Sombra tramada redonda (la de un árbol, la de la ropa colgada)."""
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1 and (x + y) % 2 == 0 and 0 <= x < R.w and 0 <= y < R.h:
                c = R.im.getpixel((x, y))
                R.im.putpixel((x, y), tuple(int(v * k) for v in c[:3]) + (255,))


def tuft(R, x, y, c):
    for dx, h in ((-2, 2), (-1, 3), (0, 4), (1, 3), (2, 2)):
        R.line([(x + dx, y), (x + dx + (1 if dx > 0 else -1 if dx < 0 else 0), y - h)], c if h < 4 else light(c, 0.15))
    R.px(x, y + 1, dark(c, 0.35))


def tiles_roof(R, x0, y0, x1, y1, base):
    """Techo de teja de barro visto de arriba: hileras de canales, unas más quemadas, alguna rota."""
    R.rect(x0, y0, x1, y1, dark(base, 0.15))
    for y in range(y0, y1, 4):
        for x in range(x0 + (2 if (y - y0) // 4 % 2 else 0), x1, 5):
            c = base if R.r.random() > 0.2 else mix(base, (120, 60, 40), 0.35)
            if R.r.random() < 0.05:
                c = mix(base, (90, 110, 60), 0.4)  # el musgo
            R.rect(x, y, min(x1, x + 3), min(y1, y + 3), c)
            R.line([(x, y), (min(x1, x + 3), y)], light(c, 0.2))
            R.px(x + 3, y + 3, dark(c, 0.3))
    R.line([(x0, y1), (x1, y1)], INK)
    R.line([(x0, y1 + 1), (x1, y1 + 1)], dark(base, 0.4))


def window(R, x, y, w, h, frame, glass, curtain=None, bars=True):
    R.rect(x - 1, y - 1, x + w, y + h, INK)
    R.rect(x, y, x + w - 1, y + h - 1, glass)
    if curtain:
        R.rect(x, y, x + w // 2 - 2, y + h - 1, curtain)
        R.rect(x + w // 2 + 2, y, x + w - 1, y + h - 1, curtain)
        for k in range(x + 1, x + w - 1, 3):
            R.px(k, y + 2, light(curtain, 0.35))
            R.px(k + 1, y + h - 3, dark(curtain, 0.2))
    if bars:
        for k in range(x + 2, x + w - 1, 3):
            R.line([(k, y), (k, y + h - 1)], dark(frame, 0.3))
    R.line([(x - 1, y + h), (x + w, y + h)], light(frame, 0.2))  # el alféizar


def wall_noise(R, x0, y0, x1, y1, c, stains=True):
    R.rect(x0, y0, x1, y1, c)
    R.noise(x0, y0, x1, y1, c, 0.05, 0.22)
    if stains:  # la humedad que baja desde arriba
        for _ in range((x1 - x0) // 22):
            sx = R.r.randrange(x0 + 2, x1 - 2)
            ln = R.r.randrange(3, 10)
            for k in range(ln):
                R.px(sx + (k % 3 == 2), y0 + k, dark(c, 0.12 + 0.02 * (ln - k) / ln))


def plant_pot(R, x, y, pot, leaf, flower=None):
    R.rect(x - 3, y - 4, x + 3, y, pot, outline=True)
    R.line([(x - 2, y - 3), (x + 2, y - 3)], light(pot, 0.25))
    for dx, dy in ((-3, -6), (0, -8), (3, -6), (-1, -10), (2, -9), (-4, -8), (4, -8)):
        R.ell(x + dx - 1, y + dy - 1, x + dx + 1, y + dy + 1, leaf)
        R.px(x + dx, y + dy - 1, light(leaf, 0.25))
    if flower:
        for dx, dy in ((-2, -10), (2, -11), (0, -12), (4, -9)):
            R.px(x + dx, y + dy, flower)
            R.px(x + dx + 1, y + dy, dark(flower, 0.2))


# ---------------------------------------------------------------- EL PATIO (Memory1)

DIRT = (190, 152, 104)
GRASS = (112, 146, 70)


def patio():
    R = Room(W, H, 11)
    R.r = random.Random(11)
    # La tierra del patio: apisonada, más oscura donde se pisa siempre (de la puerta hacia el arco).
    R.rect(0, 0, W, H, DIRT)
    R.noise(0, 0, W, H, DIRT, 0.07, 0.3)
    for x in range(40, 450):
        cy = 96 + int(10 * __import__("math").sin(x / 70.0))
        for y in range(cy - 14, cy + 14):
            if R.r.random() < 0.45 - abs(y - cy) / 40.0:
                R.px(x, y, dark(DIRT, 0.1))
    # Las piedritas, las hojitas secas, los huecos de las gallinas.
    for _ in range(260):
        x, y = R.r.randrange(W), R.r.randrange(36, H)
        R.px(x, y, light(DIRT, 0.3) if R.r.random() < 0.6 else dark(DIRT, 0.35))
    for _ in range(14):
        x, y = R.r.randrange(130, 420), R.r.randrange(110, 180)
        R.ell(x - 3, y - 1, x + 3, y + 1, dark(DIRT, 0.18))
    # El pasto: en los bordes y alrededor de la cerca, en matas.
    for _ in range(170):
        x = R.r.randrange(W)
        y = R.r.choice([R.r.randrange(34, 48), R.r.randrange(170, 192), R.r.randrange(36, 192)])
        if 0 <= x < 112 and y < 76:
            continue
        tuft(R, x, y, GRASS if R.r.random() < 0.7 else mix(GRASS, (160, 150, 70), 0.5))

    # Arriba: el potrero detrás de la cerca, con su vaca, y los árboles del fondo.
    R.rect(112, 0, W, 30, (124, 156, 78))
    R.noise(112, 0, W, 30, (124, 156, 78), 0.08, 0.4)
    for x in range(112, W, 7):
        R.ell(x - 5, -6, x + 5, 4 + R.r.randrange(4), mix(GRASS, (40, 70, 40), 0.45))
        R.px(x, 1, light(GRASS, 0.1))
    cow_x, cow_y = 236, 14
    R.ell(cow_x - 9, cow_y - 4, cow_x + 7, cow_y + 4, (240, 236, 226), outline=True)
    R.ell(cow_x - 5, cow_y - 3, cow_x - 1, cow_y + 1, (50, 40, 40))
    R.ell(cow_x + 2, cow_y - 1, cow_x + 5, cow_y + 3, (50, 40, 40))
    R.ell(cow_x + 6, cow_y - 3, cow_x + 11, cow_y + 2, (240, 236, 226), outline=True)
    R.px(cow_x + 10, cow_y - 4, INK)
    R.line([(cow_x - 7, cow_y + 4), (cow_x - 7, cow_y + 7)], INK)
    R.line([(cow_x + 4, cow_y + 4), (cow_x + 4, cow_y + 7)], INK)
    R.line([(cow_x - 9, cow_y), (cow_x - 11, cow_y + 4)], INK)  # la cola
    # La cerca: palos torcidos y tres hilos de alambre de púas.
    for x in range(114, W, 18):
        lean = R.r.choice([-1, 0, 0, 1])
        R.line([(x, 18), (x + lean, 34)], (104, 76, 50), 2)
        R.px(x, 18, light((104, 76, 50), 0.3))
        R.px(x + 1, 34, dark(DIRT, 0.3))
    for y in (22, 26, 30):
        R.line([(112, y), (W, y + (1 if y == 26 else 0))], (92, 92, 100))
        for x in range(116, W, 6):
            R.px(x, y - 1, (70, 70, 80))
            R.px(x, y + 1, (70, 70, 80))
    R.rect(112, 34, W, 36, mix(DIRT, GRASS, 0.4))

    # El palo de mango (arriba a la derecha): la sombra, el tronco, la copa, los mangos en el piso.
    mx, my = 356, 40
    dither_ell(R, mx + 4, my + 6, 44, 10, 0.78)
    R.rect(mx - 3, my - 22, mx + 3, my, (98, 70, 48), outline=True)
    R.line([(mx - 1, my - 20), (mx - 1, my - 2)], light((98, 70, 48), 0.2))
    for k in range(70):
        a = R.r.random() * 6.283
        rr = R.r.random() ** 0.5
        x = mx + int(__import__("math").cos(a) * rr * 40)
        y = my - 26 + int(__import__("math").sin(a) * rr * 18)
        c = mix((54, 104, 50), (30, 70, 40), R.r.random() * 0.6)
        R.ell(x - 5, y - 4, x + 5, y + 4, c)
    for k in range(120):
        x, y = mx + R.r.randrange(-40, 41), my - 26 + R.r.randrange(-18, 19)
        if (x - mx) ** 2 / 1600 + (y - my + 26) ** 2 / 324 < 1:
            R.px(x, y, (88, 150, 70) if y < my - 26 else (28, 64, 36))
    for x, y in ((mx - 18, my - 20), (mx + 14, my - 16), (mx + 26, my - 30), (mx - 30, my - 28), (mx + 4, my - 34)):
        R.ell(x - 1, y - 1, x + 2, y + 2, (232, 180, 60))
        R.px(x, y - 1, (180, 210, 90))
    for x, y in ((mx - 24, my + 6), (mx + 12, my + 9), (mx + 30, my + 4), (mx - 6, my + 12)):
        R.ell(x - 2, y - 1, x + 2, y + 2, (226, 170, 56), outline=True)
        R.px(x - 1, y, (250, 214, 120))
    R.ell(mx + 16, my + 12, mx + 19, my + 14, (150, 110, 50))  # uno mordido, de alguien

    # La cuerda de la ropa: dos palos, la cuerda que se dobla, la ropa (la camisa del colegio, chiquita).
    R.line([(132, 26), (132, 50)], (110, 82, 56), 2)
    R.line([(262, 26), (262, 50)], (110, 82, 56), 2)
    pts = [(132, 27)] + [(x, 27 + int(4 * __import__("math").sin((x - 132) / 130 * 3.1416))) for x in range(140, 262, 8)] + [(262, 27)]
    R.line(pts, (210, 206, 196))
    def hang_y(x):
        return 27 + int(4 * __import__("math").sin((x - 132) / 130 * 3.1416))

    def camisa(x0, c, small=False):  # una camisa colgada de los hombros: mangas, cuello, botones
        w, h = (12, 11) if small else (16, 14)
        y0 = hang_y(x0 + w // 2)
        R.d.polygon([(x0, y0), (x0 + w, y0), (x0 + w + 3, y0 + 5), (x0 + w, y0 + 6), (x0 + w - 1, y0 + h),
                     (x0 + 1, y0 + h), (x0, y0 + 6), (x0 - 3, y0 + 5)], fill=c, outline=INK)
        R.d.polygon([(x0 + w // 2 - 2, y0), (x0 + w // 2 + 2, y0), (x0 + w // 2, y0 + 3)], fill=dark(c, 0.2))
        for k in range(y0 + 4, y0 + h - 1, 3):
            R.px(x0 + w // 2, k, dark(c, 0.3))
        R.px(x0 + 1, y0 - 1, (180, 140, 90))
        R.px(x0 + w - 1, y0 - 1, (180, 140, 90))
        return y0

    def pantalon(x0, c, w=12, h=16):
        y0 = hang_y(x0 + w // 2)
        R.d.polygon([(x0, y0), (x0 + w, y0), (x0 + w, y0 + h), (x0 + w // 2 + 1, y0 + h), (x0 + w // 2, y0 + 5),
                     (x0 + w // 2 - 1, y0 + h), (x0, y0 + h)], fill=c, outline=INK)
        R.line([(x0 + 1, y0 + 2), (x0 + w - 1, y0 + 2)], dark(c, 0.25))
        R.px(x0 + 1, y0 - 1, (180, 140, 90))
        R.px(x0 + w - 1, y0 - 1, (180, 140, 90))

    y = camisa(144, (236, 236, 240), small=True)  # la del colegio, chiquita: el escudo en el bolsillo
    R.px(147, y + 4, (60, 80, 140))
    pantalon(164, (60, 80, 150), 12, 15)  # la sudadera, con las rayas
    R.line([(165, hang_y(170) + 4), (165, hang_y(170) + 14)], (240, 240, 240))
    R.line([(175, hang_y(170) + 4), (175, hang_y(170) + 14)], (240, 240, 240))
    y = hang_y(190)
    R.rect(182, y, 214, y + 18, (240, 226, 200), outline=True)  # la sábana, con florecitas
    for k in range(10):
        R.px(184 + (k * 7) % 28, y + 3 + (k * 5) % 13, (220, 120, 140))
    R.line([(198, y + 1), (198, y + 17)], dark((240, 226, 200), 0.1))
    camisa(220, (214, 90, 80))
    pantalon(242, (110, 100, 80), 10, 13)
    for x in (148, 170, 198, 228, 247):
        dither_ell(R, x + 4, 58, 8, 2, 0.86)

    # La casa (izquierda): techo de teja, la pared de bahareque blanqueada, zócalo azul, puerta, ventana.
    tiles_roof(R, 0, 0, 92, 38, (176, 92, 62))
    wall_noise(R, 0, 40, 88, 70, (232, 224, 204))
    for _ in range(4):  # donde se cayó el pañete y se ve el barro con la caña
        x, y = R.r.randrange(4, 80), R.r.randrange(44, 58)
        R.rect(x, y, x + 5, y + 3, (168, 128, 90))
        R.line([(x + 1, y + 1), (x + 4, y + 1)], (196, 170, 110))
    R.rect(0, 62, 88, 70, (82, 120, 170))
    R.line([(0, 62), (88, 62)], dark((82, 120, 170), 0.3))
    R.noise(0, 62, 88, 70, (82, 120, 170), 0.08, 0.3)
    R.line([(0, 70), (88, 70)], INK)
    R.rect(88, 38, 90, 70, dark((232, 224, 204), 0.3))
    R.rect(32, 46, 46, 70, INK)
    R.rect(33, 47, 45, 70, (70, 52, 40))
    R.rect(41, 47, 45, 70, (120, 84, 54))  # la puerta, entreabierta
    R.px(42, 58, (230, 200, 90))
    window(R, 10, 46, 14, 10, (60, 90, 140), (60, 50, 60), curtain=(214, 120, 140))
    window(R, 60, 46, 16, 10, (60, 90, 140), (60, 50, 60), curtain=(214, 120, 140))
    R.line([(4, 40), (86, 40)], dark((232, 224, 204), 0.35))  # el alero
    dither(R, 0, 40, 88, 43, 0.8)
    for x, fl in ((8, (220, 60, 60)), (16, None), (52, (240, 200, 60)), (70, (220, 60, 120)), (80, None)):
        plant_pot(R, x, 74, (150, 156, 160) if x % 2 else (176, 96, 64), (60, 120, 60), fl)  # los tarros
    # La pila de lavar, con el balde y el jabón.
    R.rect(94, 52, 112, 72, (180, 176, 168), outline=True)
    R.rect(96, 54, 104, 62, (90, 130, 160))
    R.line([(97, 55), (102, 55)], (170, 200, 220))
    R.rect(106, 54, 110, 70, (160, 156, 148))
    for y in range(56, 70, 2):
        R.line([(106, y), (110, y)], dark((160, 156, 148), 0.2))
    R.rect(103, 66, 105, 68, (240, 180, 200))  # el jabón rosado
    R.ell(114, 66, 122, 74, (60, 110, 200), outline=True)  # el balde
    R.ell(115, 67, 121, 70, (40, 80, 150))
    dither(R, 94, 72, 116, 76, 0.8)

    # La llanta pintada de blanco, medio enterrada (el asiento de todos).
    R.ell(264, 56, 286, 66, (40, 38, 42), outline=True)
    R.ell(266, 57, 284, 63, (236, 236, 230))
    R.ell(270, 58, 280, 62, (60, 56, 56))
    R.ell(272, 59, 278, 61, DIRT)
    # Las gallinas (una con pollitos).
    for gx, gy, c in ((190, 150, (196, 110, 60)), (214, 162, (236, 232, 222))):
        R.ell(gx - 5, gy - 4, gx + 4, gy + 2, c, outline=True)
        R.ell(gx + 2, gy - 7, gx + 6, gy - 3, c, outline=True)
        R.px(gx + 5, gy - 8, (220, 40, 40))
        R.px(gx + 7, gy - 5, (240, 190, 60))
        R.line([(gx - 6, gy - 3), (gx - 8, gy - 6)], dark(c, 0.3))
        R.line([(gx, gy + 2), (gx, gy + 4)], (230, 170, 60))
    for px, py in ((222, 168), (227, 166), (225, 171)):
        R.ell(px - 1, py - 1, px + 1, py + 1, (250, 220, 90))
    # El arco: dos chanclas (a la derecha, donde se va la pelota) y la raya en la tierra.
    for cy in (78, 144):
        R.ell(436, cy - 2, 446, cy + 2, (60, 120, 200), outline=True)
        R.line([(439, cy), (443, cy - 1)], (250, 250, 250))
    for y in range(80, 144, 3):
        R.px(441, y, dark(DIRT, 0.25))
    for x in range(300, 420, 4):  # el lugar de cobrar (gastado)
        R.px(x, 112 + (x % 8 == 0), dark(DIRT, 0.12))
    return R.im


# ---------------------------------------------------------------- LA CALLE DE ANTES (FlashbackMoto)

ASPH = (98, 92, 96)
SIDE = (196, 186, 170)


def calle():
    R = Room(W, H, 23)
    R.r = random.Random(23)
    R.rect(0, 0, W, H, (150, 196, 230))  # (detrás de los techos: el cielo)
    # La calle: asfalto gastado, remiendos, grietas, manchas de aceite, la raya del medio.
    R.rect(0, 122, W, H, ASPH)
    R.noise(0, 122, W, H, ASPH, 0.08, 0.35)
    for _ in range(9):
        x, y, w, h = R.r.randrange(0, 440), R.r.randrange(128, 176), R.r.randrange(14, 40), R.r.randrange(6, 14)
        c = dark(ASPH, 0.12) if R.r.random() < 0.6 else light(ASPH, 0.08)
        R.rect(x, y, x + w, y + h, c)
        R.line([(x, y), (x + w, y)], dark(c, 0.15))
    for _ in range(12):
        x, y = R.r.randrange(W), R.r.randrange(126, 186)
        pts = [(x, y)]
        for _k in range(5):
            x += R.r.randrange(2, 6)
            y += R.r.randrange(-2, 3)
            pts.append((x, y))
        R.line(pts, dark(ASPH, 0.3))
    for x, y in ((90, 140), (330, 168), (410, 134)):
        R.ell(x - 7, y - 3, x + 7, y + 3, dark(ASPH, 0.25))
        R.ell(x - 3, y - 1, x + 2, y + 1, mix(dark(ASPH, 0.3), (120, 90, 140), 0.3))  # el arcoíris del aceite
    for x in range(4, W, 22):
        R.rect(x, 157, x + 11, 158, (236, 210, 110))
        R.noise(x, 157, x + 12, 159, (236, 210, 110), 0.2, 0.3)
    # La tapa de alcantarilla.
    R.ell(236, 170, 252, 178, dark(ASPH, 0.35), outline=True)
    for k in range(238, 251, 3):
        R.line([(k, 172), (k, 176)], dark(ASPH, 0.5))
    # El andén de enfrente, abajo (para cerrar el cuadro).
    R.rect(0, 186, W, H, dark(SIDE, 0.1))
    R.line([(0, 186), (W, 186)], (230, 200, 90))
    # El bordillo (amarillo, pintado hace mucho) y la cuneta.
    R.rect(0, 112, W, 121, (206, 196, 180))
    for x in range(0, W, 12):
        c = (226, 196, 80) if (x // 12) % 2 == 0 else (226, 222, 210)
        R.rect(x, 112, x + 11, 116, c)
        R.noise(x, 112, x + 12, 117, c, 0.15, 0.35)
    R.line([(0, 117), (W, 117)], dark((206, 196, 180), 0.3))
    R.rect(0, 118, W, 121, dark(ASPH, 0.2))
    for _ in range(14):  # la basurita de la cuneta: hojas, tapas
        x = R.r.randrange(W)
        R.px(x, 119, R.r.choice([(170, 130, 60), (200, 60, 50), (220, 220, 220)]))
    # El andén: losas de cemento, unas cambiadas, una partida.
    R.rect(0, 84, W, 112, SIDE)
    for y in range(84, 112, 14):
        for x in range((y // 14 % 2) * 8, W, 16):
            c = SIDE if R.r.random() > 0.15 else mix(SIDE, (170, 160, 150), 0.6)
            R.rect(x, y, x + 15, y + 13, c)
            R.noise(x, y, x + 15, y + 13, c, 0.05, 0.25)
            R.line([(x, y + 13), (x + 15, y + 13)], dark(SIDE, 0.18))
            R.line([(x + 15, y), (x + 15, y + 13)], dark(SIDE, 0.18))
    R.line([(150, 88), (156, 95), (154, 101), (160, 108)], dark(SIDE, 0.35))
    # La golosa pintada con tiza en el andén (y la piedrita).
    gx = 104
    chalk = (246, 244, 236)
    for n, (dx, dy) in enumerate(((0, 0), (9, 0), (18, -4), (18, 4), (27, 0), (36, -4), (36, 4), (45, 0)), 1):
        R.d.rectangle([gx + dx, 98 + dy - 4, gx + dx + 9, 98 + dy + 4], outline=chalk)
        draw_text(R, str(n) if n <= 3 else "", gx + dx + 4, 96 + dy, chalk)
    R.d.ellipse([gx + 54, 92, gx + 66, 104], outline=chalk)  # el cielo
    R.ell(gx + 21, 101, gx + 23, 103, (120, 110, 100))  # la piedrita, en el 3

    # --- Las fachadas (de izquierda a derecha). Los pies en y=84.
    # 1. La casa de dos pisos, con balcón y geranios.
    tiles_roof(R, 0, 0, 98, 16, (180, 96, 64))
    wall_noise(R, 0, 18, 96, 84, (238, 218, 176))
    R.rect(0, 76, 96, 84, (176, 98, 70))
    R.line([(0, 76), (96, 76)], dark((176, 98, 70), 0.3))
    window(R, 12, 24, 14, 14, (90, 130, 80), (70, 80, 100), curtain=(250, 246, 236), bars=False)
    window(R, 66, 24, 14, 14, (90, 130, 80), (70, 80, 100), curtain=(250, 246, 236), bars=False)
    R.rect(4, 40, 92, 42, (110, 86, 64), outline=True)  # el balcón
    for x in range(6, 92, 4):
        R.line([(x, 34), (x, 40)], (60, 60, 70))
    R.line([(4, 34), (92, 34)], (60, 60, 70))
    for x in range(10, 90, 12):
        plant_pot(R, x, 40, (178, 92, 62), (60, 120, 60), (230, 50, 60))
    dither(R, 4, 43, 92, 47, 0.8)
    R.rect(38, 54, 54, 76, INK)
    R.rect(39, 55, 53, 76, (64, 120, 90))  # la puerta verde
    R.rect(41, 57, 51, 65, dark((64, 120, 90), 0.2))
    R.rect(41, 67, 51, 74, dark((64, 120, 90), 0.2))
    R.px(51, 66, (230, 200, 90))
    draw_text(R, "23", 42, 49, (60, 60, 80))
    window(R, 12, 56, 16, 12, (90, 90, 100), (70, 80, 100))
    window(R, 66, 56, 16, 12, (90, 90, 100), (70, 80, 100))
    R.line([(96, 18), (96, 84)], INK)

    # 2. La tienda El Porvenir: el toldo de rayas, el mostrador, las canastas de envases.
    tiles_roof(R, 98, 6, 200, 26, (160, 150, 140))
    wall_noise(R, 98, 28, 198, 84, (236, 236, 222))
    R.rect(102, 30, 194, 42, (40, 90, 160), outline=True)
    sw = text_w("EL PORVENIR", 2)
    text2(R, "EL PORVENIR", 148 - sw // 2, 32, (250, 240, 200), shade=(20, 50, 100))
    for x in range(98, 198, 6):  # el toldo
        c = (210, 60, 54) if (x // 6) % 2 == 0 else (240, 236, 226)
        R.d.polygon([(x, 44), (x + 6, 44), (x + 6, 52), (x, 52)], fill=c)
        R.px(x + 3, 53, c)
    R.line([(98, 44), (198, 44)], INK)
    dither(R, 98, 53, 198, 58, 0.78)
    R.rect(110, 56, 186, 84, INK)
    R.rect(111, 57, 185, 70, (70, 56, 50))  # adentro, oscuro: los estantes
    for y in (60, 65):
        R.line([(112, y), (184, y)], (130, 100, 70))
        for x in range(113, 184, 3):
            R.px(x, y - 1, R.r.choice([(200, 60, 50), (240, 200, 70), (90, 160, 90), (230, 230, 230), (120, 70, 50)]))
            R.px(x, y - 2, R.r.choice([(200, 60, 50), (230, 230, 230), (120, 70, 50)]))
    R.rect(111, 70, 185, 84, (176, 130, 84))  # el mostrador
    R.line([(111, 70), (185, 70)], light((176, 130, 84), 0.3))
    R.rect(128, 64, 140, 70, (220, 220, 210), outline=True)  # la vitrina de los panes
    for x in range(130, 139, 3):
        R.ell(x, 66, x + 2, 68, (210, 160, 90))
    for cx in (100, 188):  # las canastas de envases vacíos, una encima de otra
        for k, cy in enumerate((76, 70)):
            R.rect(cx - 6, cy, cx + 6, cy + 6, (200, 50, 50) if k == 0 else (240, 200, 60), outline=True)
            for bx in range(cx - 4, cx + 5, 3):
                R.px(bx, cy + 2, (110, 80, 50))
                R.px(bx, cy + 1, (60, 120, 70))

    # 3. El taller: MOTOS USADAS, la cortina arriba, adentro las motos y las llantas.
    R.rect(200, 0, 304, 22, (150, 154, 160))  # el techo de zinc, con sus canales y el óxido
    for x in range(200, 304, 4):
        R.line([(x, 0), (x, 22)], dark((150, 154, 160), 0.15))
        R.line([(x + 1, 0), (x + 1, 22)], light((150, 154, 160), 0.15))
    for _ in range(18):
        x, y = R.r.randrange(200, 300), R.r.randrange(0, 20)
        R.rect(x, y, x + R.r.randrange(2, 7), y + R.r.randrange(1, 4), (160, 96, 60))
    R.line([(200, 22), (304, 22)], INK)
    wall_noise(R, 200, 23, 302, 84, (214, 140, 90))
    sw = text_w("MOTOS USADAS", 2)
    R.rect(252 - sw // 2 - 4, 26, 252 + sw // 2 + 2, 40, (240, 232, 210), outline=True)
    text2(R, "MOTOS USADAS", 252 - sw // 2, 29, (190, 40, 40), shade=(120, 30, 30))
    R.rect(214, 44, 290, 84, INK)
    R.rect(215, 45, 289, 50, (130, 130, 136))  # la cortina, enrollada arriba
    for y in range(45, 50, 2):
        R.line([(215, y), (289, y)], dark((130, 130, 136), 0.25))
    R.rect(215, 51, 289, 84, (52, 44, 46))  # adentro
    for mx, c in ((232, (40, 40, 44)), (270, (150, 40, 40))):  # dos motos esperando, de lado
        R.ell(mx - 10, 72, mx - 4, 78, (20, 20, 22))
        R.ell(mx + 4, 72, mx + 10, 78, (20, 20, 22))
        R.rect(mx - 6, 66, mx + 6, 72, c)
        R.line([(mx + 6, 64), (mx + 9, 62)], (180, 180, 186))
        R.rect(mx - 4, 64, mx + 2, 66, (30, 26, 28))
    for k in range(3):  # las llantas paradas en la esquina
        R.ell(280, 58 + k * 6, 288, 64 + k * 6, (30, 30, 34), outline=True)
        R.ell(282, 60 + k * 6, 286, 62 + k * 6, (60, 50, 50))
    R.rect(250, 76, 256, 84, (60, 110, 170), outline=True)  # el tarro de aceite
    R.ell(252, 81, 262, 84, (24, 22, 24))  # la mancha
    R.rect(203, 50, 211, 62, (240, 240, 236), outline=True)  # el almanaque de la llantería, con la muchacha
    R.rect(204, 51, 210, 56, (230, 150, 120))
    for k in range(57, 62, 2):
        R.line([(204, k), (210, k)], (150, 150, 160))
    R.line([(302, 23), (302, 84)], INK)

    # 4. La casa azul, con el gato en el muro y la señora que mira (de lejos, en la ventana).
    tiles_roof(R, 304, 8, 402, 28, (170, 88, 60))
    wall_noise(R, 304, 30, 400, 84, (110, 160, 210))
    R.rect(304, 76, 400, 84, dark((110, 160, 210), 0.3))
    window(R, 316, 44, 18, 14, (240, 240, 240), (60, 60, 80), bars=True)
    R.ell(321, 47, 327, 53, (150, 110, 90))  # la señora, asomada
    R.rect(320, 53, 328, 58, (200, 120, 160))
    R.rect(320, 46, 328, 48, (210, 210, 220))  # las canas
    window(R, 368, 44, 18, 14, (240, 240, 240), (60, 60, 80), curtain=(240, 220, 120))
    R.rect(346, 52, 360, 76, INK)
    R.rect(347, 53, 359, 76, (230, 230, 230))
    R.px(357, 64, (60, 60, 60))
    R.rect(400, 40, 404, 84, (190, 186, 176), outline=True)  # el muro bajo, con el gato
    cx, cy = 402, 38
    R.ell(cx - 3, cy - 3, cx + 3, cy + 2, (40, 36, 40))
    R.ell(cx - 2, cy - 7, cx + 2, cy - 3, (40, 36, 40))
    R.px(cx - 2, cy - 8, (40, 36, 40))
    R.px(cx + 2, cy - 8, (40, 36, 40))
    R.px(cx - 1, cy - 5, (200, 220, 90))
    R.px(cx + 1, cy - 5, (200, 220, 90))
    R.line([(cx + 3, cy), (cx + 5, cy + 5)], (40, 36, 40))

    # 5. La pared del que arregla licuadoras (pintada a mano), y el poste con los cables.
    R.rect(404, 0, W, 30, (150, 196, 230))
    wall_noise(R, 404, 30, W, 84, (226, 210, 180))
    R.line([(404, 30), (W, 30)], dark((226, 210, 180), 0.3))
    for i, s in enumerate(("SE ARREGLAN", "LICUADORAS", "PLANCHAS")):
        sw = text_w(s)
        draw_text(R, s, 434 - sw // 2, 40 + i * 8, (40, 70, 140) if i < 2 else (190, 40, 40))
    R.line([(410, 66), (458, 66)], (40, 70, 140))
    draw_text(R, "TEL 2130321", 434 - text_w("TEL 2130321") // 2, 69, (60, 60, 80))
    for k in range(3):  # los avisos pegados encima, rotos
        x = 412 + k * 20
        R.rect(x, 76 - k, x + 8, 82 - k, (240, 236, 200))
        R.line([(x + 1, 78 - k), (x + 6, 78 - k)], (120, 120, 130))
    px, top = 474, 0
    R.rect(px - 2, top, px + 2, 84, (150, 146, 140), outline=True)  # el poste
    R.line([(px - 8, 6), (px + 8, 6)], (110, 100, 90), 2)
    R.rect(px - 10, 14, px - 4, 22, (90, 90, 96), outline=True)  # el transformador
    # Los cables: de poste a poste (los otros quedan fuera de cuadro), colgando sobre las fachadas.
    for y0, sag in ((6, 5), (9, 7)):  # dos cables que cuelgan del poste para la izquierda, bajito
        pts = [(x, int(y0 + sag * (x / px) * (1 - x / px) * 4)) for x in range(0, px + 1, 4)]
        R.line(pts, (34, 32, 38))
    R.line([(px - 1, 22), (px - 14, 84)], (60, 58, 62))  # el templete
    # Las sombras de los cables y el poste, sobre la calle (es de mañana: van en diagonal).
    for k, off in enumerate((0, 4, 8)):
        for x in range(0, W, 2):
            y = 136 + off + int(6 * __import__("math").sin(x / 90.0))
            if 122 <= y < 186:
                c = R.im.getpixel((x, y))
                R.im.putpixel((x, y), tuple(int(v * 0.8) for v in c[:3]) + (255,))
    dither(R, px - 26, 86, px + 3, 90, 0.8)
    dither(R, 0, 84, W, 87, 0.82)  # la sombra de las fachadas sobre el andén
    return R.im


def build():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in (("patio", patio), ("calle_antes", calle)):
        fn().convert("RGB").save(os.path.join(OUT, name + ".png"))
        print("ok", name)


if __name__ == "__main__":
    build()
