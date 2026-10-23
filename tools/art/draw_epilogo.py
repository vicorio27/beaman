"""Los fondos del epílogo (python -X utf8 tools/art/draw_epilogo.py, desde la carpeta del proyecto).

Con el motor de las viñetas (tools/art/vinetas_motor.py: luz por escena, manchas, tramado), pero a pantalla
entera (320x180). Cada lugar: una hoja de 4 cuadros (1280x180) en assets/ui/epilogo/<lugar>.png, que
scripts/world/Epilogo.gd pasa despacio. La gente la pone Epilogo.gd encima (los muñecos de la vida real):
aquí va solo el lugar, con las cosas que cuentan algo.

Abajo, entre y=130 y 178 (x 34-286), va la caja de diálogo: ahí no se pone nada que haya que ver.
Los pies de la gente quedan más o menos en y=104-136.

    entierro      el Parque de San Judas: el guayacán, las dos cruces, lo que le dejaron
    cocina        Ibagué: la casa nueva de Brenda (el Nevado del Tolima por la ventana)
    garaje        un domingo: la moto, el partido en el televisorcito
    apartamento   el de Lorena: rosado, lluvia en la ventana, el aro de luz
    oficina       el último piso: los cerros por el vidrio, la silla del gerente
    esquina       de noche, debajo del poste: la otra esquina de Lisandro
    casa_camila   la casa de Guillermo: la camioneta, la manguera, las bolsas
    ciudad        otra ciudad, al amanecer: el parque donde trota Diana Carolina
    cantina       la de siempre: la rockola, las botellas, las luces de navidad de todo el año
    victoria      el cumpleaños: el Parque, la reja del colegio, la banca verde, los globos
    victoria_bici lo mismo, con la bicicleta verde agua (canasta, timbre, moño)
    fin           el guayacán al atardecer, las dos cruces: debajo va el FIN
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import vinetas_motor as vm  # noqa: E402

vm.set_size(320, 180)
vm.POLISH = True
from vinetas_motor import Cv, Env, col, mix, rain, stars  # noqa: E402
from draw_relleno import GLYPH  # noqa: E402

W, H = 320, 180
FRAMES = 4
OUT = "assets/ui/epilogo/"

GLYPH = dict(GLYPH)
GLYPH.update({
    "F": ["111", "100", "110", "100", "100"], "K": ["101", "101", "110", "101", "101"], "W": ["10001", "10001", "10101", "11011", "10001"],
    "X": ["101", "101", "010", "101", "101"], "J": ["001", "001", "001", "101", "010"], "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "110", "001", "110"], "6": ["011", "100", "110", "101", "010"], "7": ["111", "001", "010", "010", "010"],
    "8": ["010", "101", "010", "101", "010"], "Q": ["010", "101", "101", "011", "001"], "9": ["010", "101", "011", "001", "110"], ".": ["0", "0", "0", "0", "1"],
})

WOOD, IRON, STONE, BRICK = (164, 114, 72), (74, 74, 90), (150, 150, 162), (156, 98, 84)
YELLOW = (240, 196, 56)


# ---------------------------------------------------------------- lo que usan todos

def dk(env, alb, k=0.55):
    return col(alb, env.amb * k)


def lit(env, alb, k=1.0):
    return col(alb, env.amb + (env.key - env.amb) * k)


def poly(cv, pts):
    return cv.mask(lambda d: d.poly(pts))


def ell(cv, cx, cy, rx, ry):
    return cv.mask(lambda d: d.ell(cx, cy, rx, ry))


def lines(cv, segs, color, width=1):
    img = Image.fromarray(cv.a)
    d = ImageDraw.Draw(img)
    for s in segs:
        d.line(s, fill=color, width=width)
    cv.a = np.asarray(img).copy()


def post_lines(cv, segs, color, width=1):
    cv.post.append(lambda d: [d.line(s, fill=color, width=width) for s in segs])


def txt(cv, s, x, y, c, post=True):
    """Letras de 3x5 (los letreros de fondo)."""
    pts = []
    cx = x
    for ch in s:
        g = GLYPH.get(ch, GLYPH[" "])
        if ch == "N":
            g = g + ["1001"]
        for j, r in enumerate(g):
            for i, v in enumerate(r):
                if v == "1":
                    pts.append((cx + i, y + j))
        cx += len(g[0]) + 1
    if post:
        cv.post.append(lambda d: [d.point(p, fill=c) for p in pts])
    else:
        for p in pts:
            cv.px(p[0], p[1], c)
    return cx - x - 1


def txt_w(s):
    return sum(len(GLYPH.get(ch, GLYPH[" "])[0]) + 1 for ch in s) - 1


def floor(cv, y0, alb, env, y1=H, k=(0.95, 0.8, 0.62)):
    cv.grad((0, y0, W, y1), [col(alb, env.amb * q) for q in k])
    cv.grain(cv.box(0, y0, W, y1), 0.8)
    for i, kk in enumerate((0.6, 0.35, 0.15)):  # la sombrita donde la pared se junta con el piso
        row = cv.a[y0 + i]
        on = vm.BAY[y0 + i] < kk
        row[on] = (row[on] * 0.8).astype(np.uint8)


def tiles(cv, y0, y1, vx, color, step=34, rows=7, ease=1.7):
    """Las juntas de un piso de baldosa, en perspectiva (hacia el punto vx, arriba)."""
    segs = []
    for i in range(-14, 15):
        xb = vx + i * step * 2.2
        xt = vx + i * step
        segs.append([(xt, y0), (xb, y1)])
    for k in range(1, rows + 1):
        y = y0 + (y1 - y0) * (k / rows) ** ease
        segs.append([(0, y), (W, y)])
    lines(cv, segs, color)


def wall(cv, y1, alb, env, x0=0, x1=W):
    cv.shape(cv.box(x0, 0, x1, y1), alb, env, shade=0, half=False, rim=False)


def window(cv, env, x0, y0, x1, y1, frame=(232, 228, 220), inside=None, cross=True, sill=True):
    """Una ventana: el marco, lo de afuera (inside(cv, box)), el palo del medio, el alféizar."""
    cv.shape(cv.box(x0 - 3, y0 - 3, x1 + 3, y1 + 3), frame, env, shade=1)
    if inside:
        inside(cv, (x0, y0, x1, y1))
    if cross:
        cv.fill(cv.box((x0 + x1) // 2 - 1, y0, (x0 + x1) // 2 + 1, y1), dk(env, frame, 0.95))
        cv.fill(cv.box(x0, (y0 + y1) // 2 - 1, x1, (y0 + y1) // 2), dk(env, frame, 0.95))
    # el reflejo en el vidrio: dos rayas
    post_lines(cv, [[(x0 + 4, y1 - 6), (x0 + 12, y0 + 4)], [(x0 + 8, y1 - 4), (x0 + 15, y0 + 9)]], mix(lit(env, frame, 0.6), (255, 255, 255), 0.3))
    if sill:
        cv.shape(cv.box(x0 - 6, y1 + 3, x1 + 6, y1 + 7), frame, env, shade=1)


def cloud(cv, x, y, s, color, shade_c):
    m = cv.mask(lambda d: (d.ell(x, y, 14 * s, 5 * s), d.ell(x - 9 * s, y + 1, 9 * s, 4 * s), d.ell(x + 10 * s, y + 1, 10 * s, 4 * s), d.ell(x - 2 * s, y - 4 * s, 8 * s, 5 * s)))
    cv.fill(m, color)
    under = m & ~vm.nb(m, 0, 2)
    cv.fill(under, shade_c)


def sky(cv, y1, ramp):
    cv.grad((0, 0, W, y1), ramp, ease=0.95)


def guayacan(cv, env, x, base, s=1.0, seed=4, sun=(255, 226, 96)):
    """El árbol de flores amarillas (el guayacán en flor: casi sin hojas, todo amarillo)."""
    bark = (112, 84, 66)
    cv.shape(poly(cv, [(x - 13 * s, base), (x - 6 * s, base - 28 * s), (x - 6 * s, base - 50 * s), (x + 6 * s, base - 50 * s),
                       (x + 5 * s, base - 28 * s), (x + 14 * s, base)]), bark, env, shade=3)
    cv.shape(cv.mask(lambda d: (d.cap(x - 3 * s, base - 48 * s, x - 30 * s, base - 70 * s, 4.4 * s),
                                d.cap(x + 3 * s, base - 48 * s, x + 32 * s, base - 66 * s, 4.4 * s),
                                d.cap(x, base - 50 * s, x + 3 * s, base - 84 * s, 4.6 * s),
                                d.cap(x - 18 * s, base - 62 * s, x - 22 * s, base - 82 * s, 3 * s))), bark, env, shade=2)
    blobs = [(x, base - 84 * s, 40 * s, 19 * s), (x - 38 * s, base - 72 * s, 25 * s, 15 * s), (x + 40 * s, base - 70 * s, 27 * s, 15 * s),
             (x - 12 * s, base - 98 * s, 26 * s, 12 * s), (x + 20 * s, base - 95 * s, 24 * s, 12 * s), (x - 56 * s, base - 64 * s, 12 * s, 8 * s),
             (x + 60 * s, base - 62 * s, 12 * s, 8 * s)]
    crown = cv.mask(lambda d: [d.ell(*b) for b in blobs])
    cv.shape(crown, YELLOW, env, shade=4)
    rng = np.random.default_rng(seed)
    hi, lo, gr = lit(env, sun, 1.0), dk(env, (220, 150, 40), 0.85), dk(env, (110, 140, 80), 0.9)
    ys, xs = np.nonzero(crown)
    for i in rng.choice(len(ys), size=int(len(ys) * 0.045), replace=False):  # racimos de flores, no brillantina
        yy, xx = ys[i], xs[i]
        up = (yy - (base - 100 * s)) / (60 * s)
        c = hi if rng.random() > up * 0.9 else lo
        for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 0)):
            if crown[min(H - 1, yy + dy), min(W - 1, max(0, xx + dx))]:
                cv.px(xx + dx, yy + dy, c)
    for i in rng.choice(len(ys), size=int(len(ys) * 0.02), replace=False):
        cv.px(xs[i], ys[i], gr)
    # Unas ramitas que se asoman por debajo de las flores.
    twig = dk(env, bark, 0.7)
    post_lines(cv, [[(x - 20 * s, base - 70 * s), (x - 34 * s, base - 76 * s)], [(x + 22 * s, base - 67 * s), (x + 38 * s, base - 74 * s)],
                    [(x + 2 * s, base - 80 * s), (x - 6 * s, base - 90 * s)]], twig)
    return crown


def carpet(cv, x0, x1, y0, y1, n, seed, c1, c2):
    """Flores caídas en el pasto."""
    rng = np.random.default_rng(seed)
    for _ in range(n):
        xx, yy = int(rng.integers(x0, x1)), int(rng.integers(y0, y1))
        cv.px(xx, yy, c1 if rng.random() < 0.6 else c2)
        if rng.random() < 0.3:
            cv.px(xx + 1, yy, c2)


def grass_tufts(cv, env, y0, y1, n, seed, color, f=0):
    rng = np.random.default_rng(seed)
    segs = []
    for _ in range(n):
        gx, gy = int(rng.integers(0, W)), int(rng.integers(y0, y1))
        sway = [0, 1, 1, 0][(f + gx) % 4]
        segs += [[(gx, gy), (gx - 1 + sway, gy - 3)], [(gx + 2, gy), (gx + 2 + sway, gy - 4)]]
    post_lines(cv, segs, color)


def cross(cv, env, x, y, h, w=1.0):
    """Una cruz de palo (y = el pie)."""
    cv.shape(cv.mask(lambda d: (d.rect(x - 1.5 * w, y - h, x + 1.5 * w, y), d.rect(x - 6 * w, y - h + 5 * w, x + 6 * w, y - h + 8 * w))), WOOD, env, shade=1)


def mound(cv, env, x, y, rx, ry):
    cv.shape(cv.mask(lambda d: (d.ell(x, y, rx, ry), d.ell(x, y - ry * 0.5, rx * 0.8, ry * 0.8))), (128, 96, 70), env, shade=2)
    rng = np.random.default_rng(int(x))
    for _ in range(int(rx * 2)):  # terroncitos
        cv.px(x + rng.integers(-rx + 2, rx - 2), y - rng.integers(0, ry + 1), dk(env, (150, 116, 84), 1.1))


def bench(cv, env, x, y, w=48, color=(70, 132, 92)):
    """La banca verde del parque (x, y: la esquina de abajo a la izquierda)."""
    iron = (54, 56, 66)
    cv.shape(cv.mask(lambda d: (d.rect(x + 3, y - 14, x + 6, y), d.rect(x + w - 6, y - 14, x + w - 3, y),
                                d.rect(x + 3, y - 30, x + 6, y - 14), d.rect(x + w - 6, y - 30, x + w - 3, y - 14))), iron, env, shade=1)
    for k in range(3):  # el espaldar
        cv.shape(cv.box(x, y - 30 + k * 5, x + w, y - 27 + k * 5), color, env, shade=1)
    cv.shape(cv.box(x - 2, y - 15, x + w + 2, y - 11), color, env, shade=1)
    cv.shape(cv.box(x - 1, y - 11, x + w + 1, y - 9), dk(env, color, 1.3), env, shade=0, half=False)


def fence(cv, env, y0, y1, x0=0, x1=W, step=6, color=(58, 62, 74)):
    """Una reja de barrotes con punta."""
    m = cv.box(x0, y0 + 2, x1, y0 + 4) | cv.box(x0, y1 - 5, x1, y1 - 3)
    for xx in range(x0 + 2, x1, step):
        m |= cv.box(xx, y0, xx + 2, y1)
        m |= cv.box(xx - 0, y0 - 2, xx + 2, y0)
    cv.shape(m, color, env, shade=1, half=False)


def ground_shadow(cv, cx, y, rx, ry=2.4, k=0.55):
    cv.veil(ell(cv, cx, y, rx, ry), (20, 18, 26), k)


def bici(cv, env, x, y, color=(118, 212, 194)):
    """La bicicleta verde agua de Victoria: x, y = donde la rueda de atrás toca el piso. Canasta, timbre, moño."""
    r = 10
    rw, fw = (x, y - r), (x + 32, y - r)
    tire, spoke = (40, 40, 46), lit(env, (196, 200, 210), 0.6)
    for cx, cy in (rw, fw):
        ring = ell(cv, cx, cy, r, r) & ~ell(cv, cx, cy, r - 1.6, r - 1.6)
        cv.shape(ring, tire, env, shade=1, half=False)
        segs = [[(cx, cy), (cx + np.cos(a) * (r - 2), cy + np.sin(a) * (r - 2))] for a in np.linspace(0, np.pi, 5)[:-1]]
        segs += [[(cx - (b[1][0] - cx), cy - (b[1][1] - cy)), (cx, cy)] for b in segs]
        post_lines(cv, segs, spoke)
        cv.post.append(lambda d, cx=cx, cy=cy: d.point((cx, cy), fill=(230, 230, 236)))
    bb = (x + 13, y - 9)
    head = (x + 26, y - 23)
    cv.shape(cv.mask(lambda d: (d.cap(*rw, *bb, 2.4), d.cap(*bb, *head, 2.6), d.cap(*bb, x + 8, y - 24, 2.4), d.cap(*rw, x + 8, y - 22, 1.8),
                                d.cap(*head, *fw, 2.2), d.cap(*head, x + 25, y - 29, 2.2))), color, env, shade=1)
    cv.shape(cv.mask(lambda d: d.ell(*bb, 2.6, 2.6)), (150, 150, 160), env, shade=1)  # el plato
    post_lines(cv, [[(rw[0], rw[1] + 1), (bb[0], bb[1] + 2)]], (60, 60, 66))  # la cadena
    cv.shape(cv.mask(lambda d: d.poly([(x + 4, y - 26), (x + 13, y - 26), (x + 12, y - 24), (x + 5, y - 24)])), (52, 46, 54), env, shade=1)  # el sillín
    cv.shape(cv.mask(lambda d: (d.cap(x + 21, y - 30, x + 29, y - 29, 1.8))), (230, 226, 232), env, shade=1)  # el manubrio
    cv.post.append(lambda d: d.point((x + 22, y - 31), fill=(250, 250, 250)))  # el timbre
    cv.post.append(lambda d: d.point((x + 23, y - 31), fill=(190, 194, 206)))
    basket = cv.box(x + 28, y - 31, x + 39, y - 23)
    cv.shape(basket, (196, 158, 104), env, shade=1)
    post_lines(cv, [[(x + 28, y - 29), (x + 38, y - 29)], [(x + 28, y - 26), (x + 38, y - 26)]], dk(env, (196, 158, 104), 0.8))
    bow = (226, 60, 82)
    cv.fill(cv.mask(lambda d: (d.poly([(x + 33, y - 32), (x + 29, y - 35), (x + 29, y - 30)]), d.poly([(x + 33, y - 32), (x + 37, y - 35), (x + 37, y - 30)]))), lit(env, bow, 0.6))
    post_lines(cv, [[(x + 33, y - 32), (x + 31, y - 26)], [(x + 33, y - 32), (x + 35, y - 25)]], dk(env, bow, 1.1))


def balloons(cv, env, x, y, f, colors=((230, 70, 90), (90, 150, 230), (250, 210, 70))):
    """Globos amarrados (x, y: el nudo), que se mecen."""
    for k, c in enumerate(colors):
        bx = x - 8 + k * 8 + [0, 1, 0, -1][(f + k) % 4]
        by = y - 30 - (k % 2) * 6 + [0, 0, 1, 1][(f + k * 2) % 4]
        m = cv.mask(lambda d, bx=bx, by=by: (d.ell(bx, by, 4.6, 5.6), d.poly([(bx - 1, by + 5), (bx + 1, by + 5), (bx, by + 7)])))
        cv.shape(m, c, env.but(L=(-1, -1)), shade=2)
        cv.post.append(lambda d, bx=bx, by=by: d.point((bx - 2, by - 2), fill=(255, 255, 255)))
        post_lines(cv, [[(bx, by + 7), (bx + (x - bx) * 0.4, by + 16), (x, y)]], (220, 220, 220))


# ---------------------------------------------------------------- EL ENTIERRO

DAY = Env((0.68, 0.64, 0.66), (1.3, 1.1, 0.9), (-1, -1), half=0.45)


def entierro(f):
    cv = Cv(f)
    env = DAY
    sky(cv, 76, [(112, 146, 196), (142, 172, 214), (186, 202, 224), (228, 220, 206)])
    for cx, cy, s in ((40 + f * 2, 18, 1.0), (214 + f * 2, 12, 1.3), (300 + f * 2, 30, 0.8)):
        cloud(cv, cx, cy, s, (246, 244, 240), (214, 214, 226))
    # El barrio de fondo, lavado por la distancia; San Judas a la derecha.
    haze = (156, 160, 180)
    m = np.zeros((H, W), bool)
    for k, (bx, bw, bh) in enumerate(((0, 30, 22), (30, 26, 30), (56, 34, 18), (90, 22, 26), (112, 40, 20), (152, 26, 32), (178, 36, 22), (214, 30, 28))):
        m |= cv.box(bx, 76 - bh, bx + bw - 1, 76)
    cv.fill(m, haze)
    for k in range(40):  # ventanitas
        wx, wy = (k * 37) % 240, 58 + (k * 11) % 14
        if m[wy, wx] and m[wy + 3, wx + 2]:
            cv.fill(cv.box(wx, wy, wx + 3, wy + 3), mix(haze, (90, 96, 120), 0.4))
    church = (206, 196, 190)
    cv.shape(cv.mask(lambda d: (d.rect(250, 42, 300, 76), d.rect(266, 16, 284, 44), d.poly([(264, 18), (275, 4), (286, 18)]))), church, env.but(amb=(0.8, 0.8, 0.86)), shade=1)
    cv.fill(cv.mask(lambda d: (d.ell(275, 30, 4, 5), d.rect(271, 30, 279, 38))), (96, 90, 104))
    cv.fill(cv.mask(lambda d: d.poly([(248, 43), (275, 32), (302, 43)])), (150, 92, 80))
    for wx in (256, 290):
        cv.fill(cv.mask(lambda d, wx=wx: (d.ell(wx, 54, 3, 3), d.rect(wx - 3, 54, wx + 3, 64))), (110, 116, 140))
    post_lines(cv, [[(275, 0), (275, 4)], [(273, 1), (277, 1)]], (96, 90, 104))
    # Los árboles de atrás y la reja del parque.
    cv.fill(cv.mask(lambda d: [d.ell(x, 70 - (x * 7) % 9, 18, 10) for x in range(-10, 250, 26)]), dk(env, (70, 110, 80), 0.78))
    floor(cv, 76, (110, 150, 92), env)
    fence(cv, env.but(amb=(0.8, 0.8, 0.86)), 64, 80, 0, 248, 5, (66, 72, 84))
    # El caminito de tierra que entra por la izquierda.
    cv.fill(poly(cv, [(0, 104), (60, 92), (120, 88), (120, 92), (60, 98), (0, 116)]) & (vm.BAY < 0.7), dk(env, (156, 132, 100), 0.95))
    bench(cv, env, 8, 96, 44)
    # El guayacán.
    guayacan(cv, env, 158, 104, 1.0, seed=4)
    cv.fill(ell(cv, 158, 112, 74, 10) & (vm.BAY < 0.35), dk(env, (110, 150, 92), 0.7))  # la sombra
    carpet(cv, 80, 240, 96, 128, 160, 6, (250, 214, 70), (226, 176, 48))
    grass_tufts(cv, env, 84, 128, 50, 3, dk(env, (130, 170, 100), 1.05), f)
    # Las dos tumbas: Lukas, chiquita; él, al lado.
    mound(cv, env, 138, 124, 13, 4)
    cross(cv, env, 138, 120, 16, 0.7)
    collar = (196, 58, 52)
    cv.fill(cv.mask(lambda d: (d.ell(138, 111, 3.4, 2.2))) & ~ell(cv, 138, 111, 2, 1), collar)  # el collar, colgado de la cruz
    cv.post.append(lambda d: d.point((138, 113), fill=(236, 200, 80)))
    mound(cv, env, 180, 126, 22, 5)
    cross(cv, env, 180, 121, 26, 1.0)
    # Lo que le dejaron: el clavel (medio caído), el pan de Don Germán, la lata de Wilson, la sopa, Gloria.
    stem = dk(env, (60, 120, 66), 1.0)
    post_lines(cv, [[(166, 124), (171, 120)]], stem)
    cv.fill(ell(cv, 172, 119, 2.2, 1.8), (224, 54, 64))
    cv.shape(cv.mask(lambda d: d.ell(190, 123, 4.4, 2.4)), (206, 150, 84), env, shade=1)  # el pan
    post_lines(cv, [[(188, 122), (189, 121)], [(191, 122), (192, 121)]], dk(env, (206, 150, 84), 0.7))
    cv.shape(cv.box(198, 117, 202, 124), (190, 196, 206), env, shade=1)  # la lata
    cv.fill(cv.box(198, 119, 202, 121), (200, 60, 60))
    cv.shape(cv.mask(lambda d: (d.rect(154, 120, 162, 125), d.ell(158, 120, 4, 1.4))), (176, 176, 186), env, shade=1)  # la ollita de la sopa
    cv.post.append(lambda d: d.line([(156, 117 - f % 2), (157, 115 - f % 2)], fill=(240, 240, 240)))
    # Gloria, la muñeca sin un ojo, sentada al lado de la cruz.
    cv.shape(cv.mask(lambda d: d.poly([(208, 125), (216, 125), (214, 118), (210, 118)])), (220, 150, 170), env, shade=1)
    cv.shape(ell(cv, 212, 115, 3, 3), (236, 206, 186), env, shade=1)
    cv.fill(cv.mask(lambda d: (d.ell(212, 113, 3.4, 1.8), d.rect(209, 113, 210, 118), d.rect(214, 113, 215, 118))), dk(env, (196, 120, 60), 1.1))
    cv.post.append(lambda d: d.point((211, 115), fill=(40, 30, 40)))  # el ojo que le queda
    cv.post.append(lambda d: d.point((213, 115), fill=(200, 170, 160)))  # el que no
    ground_shadow(cv, 180, 128, 24, 2)
    return cv


# ---------------------------------------------------------------- LA COCINA DE BRENDA (Ibagué)

def cocina(f):
    cv = Cv(f)
    env = Env((0.66, 0.6, 0.56), (1.32, 1.12, 0.86), (-1, -1), half=0.45)
    wall(cv, 104, (226, 204, 164), env)
    cv.grain(cv.box(0, 0, W, 72))
    # El enchape: baldosín blanco y azul hasta la mitad.
    cv.shape(cv.box(0, 72, W, 104), (226, 230, 232), env, shade=0, half=False, rim=False)
    segs = [[(0, y), (W, y)] for y in range(72, 104, 8)] + [[(x, 72), (x, 104)] for x in range(0, W, 8)]
    lines(cv, segs, dk(env, (190, 196, 206), 1.0))
    for k in range(0, W, 32):
        cv.fill(cv.box(k + 9, 81, k + 15, 87), dk(env, (90, 130, 196), 1.1))
    cv.fill(cv.box(0, 71, W, 72), dk(env, (120, 150, 196), 1.0))
    floor(cv, 104, (186, 100, 70), env)
    tiles(cv, 104, H, 160, dk(env, (186, 100, 70), 0.55), 26, 6)
    # La ventana: Ibagué, los cerros, el Nevado del Tolima allá atrás.
    def ibague(cv, b):
        x0, y0, x1, y1 = b
        cv.grad((x0, y0, x1, y1), [(130, 176, 226), (176, 206, 232), (220, 230, 232)])
        cv.fill(poly(cv, [(x0, y1 - 14), (x0 + 22, y0 + 14), (x0 + 30, y0 + 10), (x0 + 38, y0 + 16), (x1, y1 - 20), (x1, y1), (x0, y1)]), (176, 186, 206))
        cv.fill(poly(cv, [(x0 + 22, y0 + 14), (x0 + 30, y0 + 10), (x0 + 38, y0 + 16), (x0 + 32, y0 + 17), (x0 + 27, y0 + 15)]), (250, 250, 252))
        cv.fill(poly(cv, [(x0, y1 - 8), (x0 + 16, y1 - 22), (x0 + 40, y1 - 12), (x0 + 60, y1 - 24), (x1, y1 - 14), (x1, y1), (x0, y1)]), (96, 140, 92))
        cv.fill(poly(cv, [(x0, y1 - 2), (x0 + 30, y1 - 10), (x1, y1 - 4), (x1, y1), (x0, y1)]), (72, 112, 76))
        for k in range(6):  # casitas en la loma
            hx = x0 + 6 + k * 11
            cv.fill(cv.box(hx, y1 - 9 + (k % 2), hx + 4, y1 - 5 + (k % 2)), (226, 214, 196))
            cv.fill(cv.box(hx, y1 - 10 + (k % 2), hx + 4, y1 - 9 + (k % 2)), (176, 90, 70))
    window(cv, env, 24, 20, 96, 62, frame=(240, 238, 232), inside=ibague)
    for xx, fl in ((18, False), (88, True)):  # la cortina de florecitas
        cm = cv.mask(lambda d, xx=xx: d.poly([(xx, 14), (xx + 14, 14), (xx + 10, 66), (xx + 2, 68)]))
        cv.shape(cm, (246, 226, 150), env, shade=1)
        rng = np.random.default_rng(xx)
        ys_, xs_ = np.nonzero(cm)
        for i in rng.choice(len(ys_), 26, replace=False):
            cv.px(xs_[i], ys_[i], lit(env, (226, 96, 70), 0.5))
    cv.shape(cv.box(14, 12, 106, 14), (160, 120, 80), env, shade=1)
    cv.shape(cv.mask(lambda d: (d.rect(52, 62, 64, 69), d.ell(58, 58, 7, 5))), (186, 96, 64), env, shade=1)  # la mata de cilantro
    cv.fill(cv.mask(lambda d: (d.ell(56, 56, 3, 4), d.ell(60, 55, 3, 4), d.ell(58, 52, 2.4, 3))), lit(env, (90, 150, 80), 0.6))
    # La repisa con la radio (pasa un bolero) y los frascos.
    cv.shape(cv.box(106, 44, 160, 47), (150, 104, 66), env, shade=1)
    cv.shape(cv.mask(lambda d: (d.rect(112, 30, 136, 44), d.ell(124, 30, 12, 2))), (126, 82, 54), env, shade=1)
    cv.fill(cv.box(115, 33, 124, 41), dk(env, (90, 70, 56), 0.7))
    for yy in range(34, 41, 2):
        cv.fill(cv.box(115, yy, 124, yy + 1), dk(env, (60, 50, 40), 0.8))
    cv.fill(cv.box(127, 33, 134, 37), (236, 214, 150))
    cv.post.append(lambda d: d.point((129 + f % 3, 35), fill=(200, 60, 50)))
    post_lines(cv, [[(134, 30), (144, 12)]], (186, 190, 200))
    for k in range(3):  # las notas del bolero
        nx = 140 + k * 9 + [0, 1, 1, 0][(f + k) % 4] * 2
        ny = 24 - ((f + k * 2) % 4) * 4
        c = lit(env, (110, 70, 60), 0.4)
        cv.post.append(lambda d, nx=nx, ny=ny, c=c: (d.ellipse([nx, ny + 3, nx + 2, ny + 5], fill=c), d.line([(nx + 2, ny), (nx + 2, ny + 4)], fill=c), d.point((nx + 3, ny), fill=c)))
    for k, c in enumerate(((236, 188, 80), (210, 90, 60), (160, 186, 110))):
        cv.shape(cv.mask(lambda d, k=k: (d.rect(140 + k * 7, 36, 145 + k * 7, 44), d.rect(140 + k * 7, 34, 145 + k * 7, 36))), c, env, shade=1)
    # El Sagrado Corazón y el almanaque.
    cv.shape(cv.box(234, 22, 254, 48), (196, 156, 70), env, shade=1)
    cv.fill(cv.box(237, 25, 251, 45), (120, 70, 80))
    cv.fill(ell(cv, 244, 31, 3, 3.4), (230, 190, 160))
    cv.fill(cv.box(240, 35, 248, 45), (196, 60, 60))
    cv.fill(ell(cv, 244, 38, 1.6, 1.6), (250, 200, 80))
    cv.shape(cv.box(266, 20, 296, 56), (244, 242, 236), env, shade=1)
    cv.fill(cv.box(268, 22, 294, 34), (110, 160, 210))
    cv.fill(poly(cv, [(268, 34), (276, 26), (284, 32), (294, 27), (294, 34)]), (90, 140, 90))
    for r in range(4):
        for c in range(6):
            cv.px(270 + c * 4, 38 + r * 4, dk(env, (80, 80, 90), 1.0))
    txt(cv, "OCTUBRE", 270, 49, dk(env, (190, 60, 60), 1.2))
    # El mesón: la tabla con la cebolla partida y el cuchillo; la estufa y la olla.
    top = (176, 176, 170)
    cv.shape(cv.box(112, 74, 252, 79), top, env, shade=1)
    cv.shape(cv.box(114, 79, 250, 104), (222, 214, 200), env, shade=1)
    for dx in (114, 148, 216):
        cv.fill(cv.box(dx + 32, 81, dx + 33, 102), dk(env, (222, 214, 200), 0.7))
        cv.fill(cv.box(dx + 27, 90, dx + 30, 91), dk(env, (120, 120, 130), 0.9))
    cv.shape(cv.box(126, 71, 152, 74), (190, 140, 90), env, shade=1)
    cv.fill(ell(cv, 134, 71, 3.4, 2.2), (236, 220, 236))
    cv.fill(ell(cv, 141, 71, 3.4, 2.2), (226, 200, 222))
    post_lines(cv, [[(133, 71), (135, 71)], [(140, 71), (142, 71)]], (176, 120, 170))
    post_lines(cv, [[(145, 72), (152, 69)]], (210, 214, 224))
    cv.fill(cv.box(150, 69, 153, 71), (60, 44, 40))
    cv.shape(cv.box(178, 70, 222, 74), (240, 240, 238), env, shade=1)  # la estufa
    for bx in (186, 212):
        cv.fill(cv.box(bx - 4, 69, bx + 4, 70), (40, 40, 46))
    cv.shape(cv.mask(lambda d: (d.rect(178, 56, 196, 69), d.ell(187, 56, 9, 2), d.rect(175, 59, 178, 61), d.rect(196, 59, 199, 61))), (182, 186, 196), env, shade=2)
    cv.fill(cv.box(208, 68, 216, 69), (66, 108, 220))  # la llamita del otro fogón
    cv.post.append(lambda d: d.point((210 + f % 3, 67), fill=(140, 180, 255)))
    for k in range(3):  # el vapor de la sopa: tres hilos que suben ondulando
        sx = 182 + k * 5
        pts = [(sx + [0, 1, 1, 0, -1, -1][(j + f + k) % 6], 53 - j * 3) for j in range(5)]
        cv.post.append(lambda d, pts=pts, k=k: d.line(pts[(f + k) % 2:], fill=(250, 250, 250)))
    # La mesita del niño, con su plato y su silla plástica.
    cv.shape(cv.box(210, 98, 266, 102), (236, 234, 230), env, shade=1)
    cv.fill(cv.box(214, 102, 216, 124) | cv.box(260, 102, 262, 124), dk(env, (200, 200, 206), 0.9))
    cv.shape(cv.mask(lambda d: (d.ell(246, 97, 7, 2), d.rect(240, 95, 252, 97))), (240, 240, 244), env, shade=1)
    cv.fill(cv.box(242, 95, 250, 96), (220, 170, 80))
    cv.shape(cv.mask(lambda d: (d.rect(262, 88, 280, 92), d.rect(264, 74, 280, 88), d.rect(264, 92, 266, 120), d.rect(278, 92, 280, 120))), (220, 70, 70), env, shade=1)
    return cv


# ---------------------------------------------------------------- EL GARAJE (domingo)

def moto(cv, env, x, y, tank=(170, 30, 40), f=0):
    """Una moto de lado (x, y: donde la rueda de atrás toca el piso), mirando a la derecha."""
    r = 13
    rw, fw = (x, y - r), (x + 58, y - r)
    for cx, cy in (rw, fw):
        cv.shape(ell(cv, cx, cy, r, r), (30, 30, 34), env, shade=2)
        cv.shape(ell(cv, cx, cy, 7, 7), (176, 180, 190), env, shade=1)
        cv.fill(ell(cv, cx, cy, 2, 2), (60, 60, 66))
    cv.shape(cv.mask(lambda d: (d.cap(*rw, x + 20, y - 24, 3), d.cap(x + 50, y - 40, *fw, 3))), (150, 154, 166), env, shade=1)  # el basculante, la horquilla
    cv.shape(cv.mask(lambda d: (d.rect(x + 18, y - 26, x + 38, y - 12), d.ell(x + 28, y - 13, 10, 4))), (90, 92, 102), env, shade=2)  # el motor
    for k in range(4):
        cv.fill(cv.box(x + 20, y - 24 + k * 3, x + 36, y - 23 + k * 3), dk(env, (90, 92, 102), 0.7))
    cv.shape(cv.mask(lambda d: d.cap(x + 24, y - 12, x - 6, y - 18, 4)), (200, 204, 214), env, shade=1)  # el exhosto
    cv.shape(cv.mask(lambda d: d.poly([(x - 4, y - 32), (x + 24, y - 33), (x + 24, y - 29), (x + 2, y - 27)])), (30, 28, 32), env, shade=1)  # el sillín
    cv.shape(cv.mask(lambda d: (d.poly([(x + 22, y - 32), (x + 28, y - 40), (x + 44, y - 41), (x + 50, y - 34), (x + 44, y - 26), (x + 24, y - 26)]))), tank, env, shade=2)
    cv.shape(cv.mask(lambda d: d.poly([(x - 8, y - 30), (x + 6, y - 30), (x + 2, y - 26), (x - 6, y - 27)])), tank, env, shade=1)  # la colita
    cv.shape(cv.mask(lambda d: (d.cap(x + 48, y - 42, x + 54, y - 50, 2), d.cap(x + 52, y - 50, x + 44, y - 52, 2))), (60, 60, 66), env, shade=1)  # el manubrio
    cv.shape(ell(cv, x + 57, y - 40, 4, 4), (220, 220, 226), env, shade=1)  # la farola
    cv.fill(ell(cv, x + 58, y - 40, 2, 2.4), (255, 250, 220))
    cv.shape(cv.mask(lambda d: (d.cap(x + 50, y - 50, x + 46, y - 58, 1.2), d.ell(x + 45, y - 59, 3, 2))), (60, 60, 66), env, shade=1)  # el espejo
    # El brillo que le saca Mauricio: pasa por el tanque.
    gx = x + 26 + f * 5
    cv.post.append(lambda d: (d.line([(gx, y - 37), (gx + 2, y - 39)], fill=(255, 255, 255)), d.point((gx + 1, y - 35), fill=(255, 220, 220))))


def garaje(f):
    cv = Cv(f)
    env = Env((0.62, 0.6, 0.62), (1.4, 1.2, 0.96), (1, -1), half=0.4)
    wall(cv, 104, (176, 174, 170), env)
    cv.grain(cv.box(0, 0, 250, 104), 1.2)
    segs = [[(0, y), (250, y)] for y in range(8, 104, 10)]
    for row, y in enumerate(range(8, 104, 10)):
        segs += [[(x + (10 if row % 2 else 0), y), (x + (10 if row % 2 else 0), y + 10)] for x in range(0, 250, 20)]
    lines(cv, segs, dk(env, (176, 174, 170), 0.82))
    floor(cv, 104, (140, 140, 142), env)
    for ox, oy, rx in ((150, 132, 22), (60, 120, 10), (210, 116, 8)):  # las manchas de aceite
        cv.veil(ell(cv, ox, oy, rx, rx * 0.25), (60, 56, 60), 0.5)
    # La puerta de enrollar, abierta: afuera, el domingo (sol, la casa del frente, el andén).
    def calle(cv, b):
        x0, y0, x1, y1 = b
        cv.grad((x0, y0, x1, y1 - 30), [(120, 170, 226), (186, 210, 232)])
        cv.fill(cv.box(x0, y1 - 62, x1, y1 - 20), (226, 196, 150))
        cv.fill(cv.box(x0, y1 - 66, x1, y1 - 62), (176, 90, 70))
        for wx in (x0 + 8, x0 + 40):
            cv.fill(cv.box(wx, y1 - 52, wx + 16, y1 - 36), (90, 120, 160))
            cv.fill(cv.box(wx + 7, y1 - 52, wx + 8, y1 - 36), (226, 226, 226))
        cv.fill(cv.box(x0, y1 - 20, x1, y1 - 14), (200, 196, 186))
        cv.fill(cv.box(x0, y1 - 14, x1, y1), (110, 110, 118))
        cv.fill(cv.box(x0 + 22, y1 - 8, x0 + 34, y1 - 7), (236, 220, 120))
    calle(cv, (252, 12, 320, 120))
    cv.shape(cv.box(248, 0, 320, 12), (150, 156, 166), env, shade=1)
    for y in range(2, 12, 3):
        cv.fill(cv.box(248, y, 320, y + 1), dk(env, (150, 156, 166), 0.7))
    cv.shape(cv.box(246, 0, 252, 120), (130, 130, 136), env, shade=1)
    cv.light(np.clip(1 - np.abs(np.mgrid[0:H, 0:W][1] - 290) / 60.0, 0, 1) * (np.mgrid[0:H, 0:W][0] > 104) * 0.5, (255, 236, 196), 0.4)
    # El tablero de herramientas.
    cv.shape(cv.box(16, 24, 96, 66), (196, 160, 110), env, shade=1)
    for yy in range(28, 64, 4):
        for xx in range(20, 94, 4):
            cv.px(xx, yy, dk(env, (196, 160, 110), 0.6))
    tool = (130, 134, 146)
    cv.shape(cv.mask(lambda d: (d.cap(26, 30, 26, 52, 2.2), d.ell(26, 30, 3, 3))), tool, env, shade=1)  # la llave
    cv.shape(cv.mask(lambda d: (d.cap(40, 32, 40, 54, 2), d.rect(35, 30, 46, 34))), (150, 100, 60), env, shade=1)  # el martillo
    cv.shape(cv.mask(lambda d: (d.poly([(54, 30), (78, 30), (78, 38), (54, 34)]), d.rect(76, 28, 84, 40))), tool, env, shade=1)  # el serrucho
    cv.shape(cv.mask(lambda d: (d.cap(60, 44, 60, 60, 2), d.cap(68, 44, 72, 60, 2))), (200, 60, 60), env, shade=1)  # el alicate
    cv.shape(ell(cv, 86, 52, 6, 6) & ~ell(cv, 86, 52, 3, 3), (60, 60, 66), env, shade=1)  # el rollo de cinta
    # El banco de trabajo con el televisorcito: pasan el partido.
    cv.shape(cv.box(10, 80, 104, 84), (150, 104, 66), env, shade=1)
    cv.fill(cv.box(14, 84, 16, 104) | cv.box(98, 84, 100, 104), dk(env, (150, 104, 66), 0.8))
    cv.shape(cv.box(24, 62, 56, 80), (50, 50, 56), env, shade=1)
    cv.fill(cv.box(27, 65, 51, 77), (70, 150, 80))
    cv.fill(cv.box(39, 65, 40, 77), (210, 236, 210))
    for k in range(4):  # los jugadores, chiquiticos, que corren
        px_ = 29 + (k * 6 + f * (2 if k % 2 else -2)) % 22
        cv.fill(cv.box(px_, 69 + (k * 3) % 6, px_ + 1, 71 + (k * 3) % 6), (230, 60, 60) if k % 2 else (250, 250, 250))
    cv.px(30 + (f * 5) % 20, 72, (255, 255, 255))
    cv.fill(cv.box(52, 66, 55, 76), dk(env, (50, 50, 56), 1.3))
    post_lines(cv, [[(40, 62), (34, 54)], [(40, 62), (46, 54)]], (170, 170, 180))
    for k, c in enumerate(((230, 180, 40), (60, 60, 70), (200, 60, 50))):  # los tarros de aceite
        cv.shape(cv.box(64 + k * 9, 70, 71 + k * 9, 80), c, env, shade=1)
        cv.fill(cv.box(66 + k * 9, 68, 69 + k * 9, 70), dk(env, c, 0.8))
    # Las llantas colgadas, el tubo de luz.
    for k in range(2):
        cv.shape(ell(cv, 120 + k * 22, 34, 10, 10) & ~ell(cv, 120 + k * 22, 34, 5, 5), (36, 36, 40), env, shade=2)
    cv.fill(cv.box(116, 22, 146, 23), (90, 90, 96))
    cv.fill(cv.box(150, 2, 210, 5), (240, 244, 250))
    cv.glow(180, 4, 50, (240, 246, 255), 0.35, squash=0.5)
    # La moto (en la mitad, entre los dos) y el balde con espuma.
    moto(cv, env, 150, 128, f=f)
    cv.shape(cv.mask(lambda d: (d.poly([(226, 112), (240, 112), (238, 126), (228, 126)]))), (60, 120, 200), env, shade=1)
    cv.fill(cv.mask(lambda d: (d.ell(233, 112, 8, 2.4), d.ell(230, 110, 3, 2), d.ell(236, 110, 3, 2))), (246, 246, 250))
    cv.shape(cv.box(110, 116, 120, 121), (240, 210, 80), env, shade=1)  # la esponja
    return cv


# ---------------------------------------------------------------- EL APARTAMENTO DE LORENA

def apartamento(f):
    cv = Cv(f)
    env = Env((0.62, 0.54, 0.6), (1.3, 1.06, 0.98), (-1, -1), half=0.45)
    wall(cv, 104, (226, 190, 196), env)
    cv.grain(cv.box(0, 0, W, 104), 0.7)
    cv.shape(cv.box(0, 98, W, 104), (246, 236, 236), env, shade=0, half=False)  # el guardaescobas
    floor(cv, 104, (176, 136, 110), env)
    lines(cv, [[(0, y), (W, y)] for y in (112, 124, 140, 160)] + [[(x, 104), (x * 1.6 - 96, H)] for x in range(0, W + 120, 40)], dk(env, (176, 136, 110), 0.7))
    # La ventana con lluvia: afuera, la ciudad prendiendo las luces.
    def afuera(cv, b):
        x0, y0, x1, y1 = b
        cv.grad((x0, y0, x1, y1), [(60, 66, 100), (96, 92, 130), (150, 120, 150)])
        for k in range(7):
            bx = x0 + k * 13 - 4
            bh = 20 + (k * 17) % 26
            cv.fill(cv.box(bx, y1 - bh, bx + 11, y1), (44, 46, 70))
            for j in range(4):
                if (k + j + f // 2) % 3:
                    cv.px(bx + 2 + (j * 3) % 8, y1 - bh + 4 + j * 4, (250, 214, 130))
        rain(cv, f, 60, (170, 176, 210), m=cv.box(x0, y0, x1, y1), seed=5, speed=12)
        for k in range(8):  # las gotas que bajan por el vidrio
            gx, gy = x0 + 4 + (k * 11) % (x1 - x0 - 6), y0 + (k * 13 + f * (3 + k % 3)) % (y1 - y0 - 4)
            cv.fill(cv.box(gx, gy, gx + 1, gy + 3), (200, 210, 236))
    window(cv, env, 216, 20, 296, 78, frame=(246, 240, 240), inside=afuera)
    for xx in (206, 290):  # las cortinas rosadas, de velo
        m = cv.mask(lambda d, xx=xx: d.poly([(xx, 12), (xx + 18, 12), (xx + 14, 98), (xx + 2, 98)]))
        cv.veil(m, lit(env, (246, 170, 196), 0.6), 0.6)
    cv.shape(cv.box(200, 10, 312, 12), (200, 200, 206), env, shade=1)
    # LIVE LAUGH LOVE (en la pared, como debe ser).
    cv.shape(cv.box(20, 24, 92, 36), (250, 246, 240), env, shade=1)
    txt(cv, "LIVE LAUGH LOVE", 25, 28, (110, 54, 84))
    # El sofá, con los cojines y la cobija peluda.
    sofa = (196, 150, 162)
    cv.shape(cv.mask(lambda d: (d.rect(18, 70, 112, 86), d.ell(18, 70, 4, 4), d.ell(112, 70, 4, 4))), sofa, env, shade=2)
    cv.shape(cv.box(16, 84, 114, 102), sofa, env, shade=2)
    cv.shape(cv.mask(lambda d: (d.rect(10, 76, 22, 104), d.rect(108, 76, 120, 104))), dk(env, sofa, 1.6), env, shade=2)
    for cx, c in ((34, (250, 220, 230)), (54, (236, 120, 160)), (94, (250, 250, 250))):
        cv.shape(cv.mask(lambda d, cx=cx: d.poly([(cx - 8, 86), (cx - 6, 72), (cx + 6, 72), (cx + 8, 86)])), c, env, shade=1)
    cv.shape(cv.mask(lambda d: d.poly([(70, 84), (98, 84), (100, 102), (68, 102)])), (250, 236, 220), env, shade=1)
    for k in range(10):
        cv.px(70 + k * 3, 102, dk(env, (250, 236, 220), 0.7))
    # La mesita: los esmaltes rosados, el algodón, la copa de vino.
    cv.shape(cv.box(36, 108, 100, 112), (240, 240, 244), env, shade=1)
    cv.fill(cv.box(40, 112, 42, 124) | cv.box(94, 112, 96, 124), (200, 180, 120))
    for k, c in enumerate(((236, 90, 150), (250, 150, 190), (220, 60, 120), (246, 200, 220))):
        cv.shape(cv.mask(lambda d, k=k: (d.rect(44 + k * 5, 102, 48 + k * 5, 108), d.rect(45 + k * 5, 99, 47 + k * 5, 102))), c, env, shade=1)
    cv.fill(cv.mask(lambda d: (d.ell(70, 106, 3, 2), d.ell(75, 106, 3, 2))), (250, 250, 250))
    cv.shape(cv.mask(lambda d: (d.poly([(84, 98), (92, 98), (89, 104), (87, 104)]), d.rect(87, 104, 89, 107), d.rect(85, 107, 91, 108))), (230, 230, 240), env, shade=1)
    cv.fill(cv.mask(lambda d: d.poly([(85, 100), (91, 100), (89, 103), (87, 103)])), (150, 30, 60))
    # El aro de luz, en su trípode (para las fotos); la consola con los portarretratos.
    ring = ell(cv, 196, 46, 13, 13) & ~ell(cv, 196, 46, 9.6, 9.6)
    cv.fill(ring, (255, 250, 246))
    cv.glow(196, 46, 26, (255, 244, 236), 0.4)
    post_lines(cv, [[(196, 59), (196, 100)], [(196, 90), (188, 104)], [(196, 90), (204, 104)]], (60, 56, 66))
    cv.shape(cv.box(130, 84, 176, 88), (250, 250, 250), env, shade=1)
    cv.fill(cv.box(132, 88, 134, 104) | cv.box(172, 88, 174, 104), (220, 190, 120))
    cv.shape(cv.box(136, 68, 150, 84), (220, 190, 120), env, shade=1)  # Victoria, chiquita (castaña)
    cv.fill(cv.box(138, 70, 148, 82), (200, 226, 240))
    cv.fill(ell(cv, 143, 75, 2.6, 3), (230, 186, 150))
    cv.fill(cv.mask(lambda d: (d.ell(143, 73, 3.4, 2.2), d.rect(140, 73, 141, 80), d.rect(145, 73, 146, 80))), (120, 80, 50))
    cv.fill(cv.box(141, 78, 145, 82), (240, 120, 160))
    cv.shape(cv.box(154, 64, 172, 84), (250, 220, 120), env, shade=1)  # ella misma, en grande (la selfie)
    cv.fill(cv.box(156, 66, 170, 82), (250, 200, 210))
    cv.fill(ell(cv, 163, 72, 3.2, 3.6), (236, 190, 160))
    cv.fill(cv.mask(lambda d: (d.ell(163, 69, 4.4, 3), d.rect(158, 69, 160, 80), d.rect(166, 69, 168, 80))), (130, 86, 54))
    cv.fill(cv.box(159, 77, 167, 82), (240, 120, 170))
    cv.post.append(lambda d: d.point((165, 71), fill=(60, 40, 40)))
    # La mata de mentiras.
    cv.shape(cv.mask(lambda d: (d.rect(282, 90, 296, 104), d.ell(289, 90, 7, 2))), (236, 236, 240), env, shade=1)
    for a in range(5):
        cv.shape(cv.mask(lambda d, a=a: d.ell(289 + (a - 2) * 6, 78 - abs(a - 2) * -2 - 6, 6, 4)), (70, 130, 90), env, shade=1)
    # La lámpara de pie.
    cv.fill(cv.box(124, 40, 126, 104), (200, 180, 120))
    cv.shape(cv.mask(lambda d: d.poly([(116, 40), (134, 40), (130, 28), (120, 28)])), (250, 236, 220), env, shade=1)
    cv.glow(125, 42, 40, (255, 220, 170), 0.35)
    return cv


# ---------------------------------------------------------------- LA OFICINA (último piso)

def oficina(f):
    cv = Cv(f)
    env = Env((0.66, 0.66, 0.72), (1.26, 1.18, 1.1), (-1, -1), half=0.4)
    # Por el vidrio: el cielo, los cerros (Monserrate, con su iglesita), la ciudad.
    sky(cv, 100, [(120, 160, 210), (160, 190, 226), (204, 216, 230)])
    for cx, cy, s in ((60 + f * 3, 22, 1.2), (180 + f * 3, 14, 0.9), (290 + f * 3, 26, 1.1)):
        cloud(cv, cx, cy, s, (246, 246, 250), (216, 220, 232))
    cv.fill(poly(cv, [(0, 64), (40, 44), (90, 40), (140, 30), (170, 26), (200, 34), (260, 42), (320, 52), (320, 100), (0, 100)]), (110, 140, 130))
    cv.fill(poly(cv, [(0, 72), (60, 58), (120, 52), (180, 48), (240, 56), (320, 64), (320, 100), (0, 100)]), (90, 122, 112))
    cv.fill(cv.mask(lambda d: (d.rect(166, 22, 176, 27), d.poly([(165, 22), (171, 17), (177, 22)]))), (240, 240, 244))
    post_lines(cv, [[(171, 13), (171, 17)], [(169, 15), (173, 15)]], (240, 240, 244))
    rng = np.random.default_rng(7)
    for k in range(26):
        bx = k * 13 - 4 + int(rng.integers(0, 4))
        bh = int(rng.integers(8, 34))
        c = mix((150, 156, 176), (190, 186, 196), rng.random())
        cv.fill(cv.box(bx, 100 - bh, bx + 11, 100), c)
        for j in range(0, bh - 4, 4):
            cv.fill(cv.box(bx + 2, 100 - bh + 2 + j, bx + 9, 100 - bh + 3 + j), mix(c, (110, 120, 150), 0.5))
    # El vidrio: los parales, el techo, el reflejo.
    for xx in range(0, W + 1, 64):
        cv.shape(cv.box(xx - 2, 0, xx + 2, 104), (70, 74, 86), env, shade=1)
    cv.fill(cv.box(0, 0, W, 8), (220, 222, 228))
    for xx in range(20, W, 80):
        cv.fill(cv.box(xx, 6, xx + 30, 8), (250, 252, 255))
    cv.veil(poly(cv, [(30, 104), (60, 8), (76, 8), (46, 104)]), (230, 236, 246), 0.25)
    cv.veil(poly(cv, [(220, 104), (250, 8), (258, 8), (228, 104)]), (230, 236, 246), 0.25)
    floor(cv, 104, (110, 112, 126), env, k=(0.95, 0.85, 0.72))
    # El dispensador de agua (con su burbuja) y la mata.
    cv.shape(cv.box(14, 74, 30, 104), (236, 236, 240), env, shade=1)
    cv.shape(cv.mask(lambda d: (d.ell(22, 64, 7, 9), d.rect(19, 72, 25, 75))), (150, 200, 236), env, shade=1)
    cv.px(22, 70 - f * 3, (240, 250, 255))
    cv.px(20, 68 - ((f + 2) % 4) * 3, (240, 250, 255))
    cv.fill(cv.box(18, 84, 21, 86) | cv.box(24, 84, 27, 86), [(70, 120, 230), (230, 70, 70)][0])
    cv.fill(cv.box(24, 84, 27, 86), (230, 70, 70))
    cv.shape(cv.mask(lambda d: (d.rect(292, 90, 308, 104), d.ell(300, 90, 8, 2))), (60, 60, 66), env, shade=1)
    for a in range(7):
        cv.shape(cv.mask(lambda d, a=a: d.cap(300, 90, 300 + (a - 3) * 6, 56 + abs(a - 3) * 6, 3.4)), (70, 130, 80), env, shade=1)
    # El escritorio del gerente, con el computador (y la carpeta que nadie abre), y la silla.
    chair = (40, 40, 46)
    cv.shape(cv.mask(lambda d: (d.rect(226, 60, 252, 92), d.ell(239, 60, 13, 4))), chair, env, shade=2)
    cv.fill(cv.box(232, 66, 246, 86), dk(env, chair, 1.4))
    cv.shape(cv.box(164, 90, 250, 96), (126, 84, 56), env, shade=1)
    cv.shape(cv.box(168, 96, 246, 120), (106, 70, 46), env, shade=1)
    cv.fill(cv.box(204, 100, 205, 118), dk(env, (106, 70, 46), 0.7))
    cv.shape(cv.box(176, 64, 206, 86), (40, 40, 46), env, shade=1)
    cv.fill(cv.box(178, 66, 204, 84), (226, 234, 246))
    cv.fill(cv.box(178, 66, 204, 68), (60, 110, 200))
    for k in range(4):  # las carpetas
        cv.fill(cv.box(181 + k * 6, 71, 185 + k * 6, 74), (240, 200, 80))
    cv.fill(cv.box(181, 77, 185, 80), (240, 200, 80))
    if f % 2 == 0:
        cv.px(196, 80, (40, 40, 40))
    cv.fill(cv.box(189, 86, 193, 90), (40, 40, 46))
    cv.shape(cv.box(178, 88, 202, 90), (220, 220, 226), env, shade=0)
    cv.shape(cv.box(214, 84, 240, 90), (40, 36, 34), env, shade=1)  # la placa
    txt(cv, "GERENTE", 214, 85, (220, 190, 110))
    cv.shape(cv.mask(lambda d: (d.rect(166, 82, 172, 90), d.ell(169, 82, 3, 1))), (240, 240, 240), env, shade=1)  # el pocillo
    # El cuadro de "TRABAJO EN EQUIPO" (un remero solo).
    cv.shape(cv.box(96, 26, 140, 58), (40, 40, 46), env, shade=1)
    cv.fill(cv.box(98, 28, 138, 50), (226, 150, 90))
    cv.fill(cv.box(98, 42, 138, 50), (70, 110, 160))
    cv.fill(cv.box(114, 40, 124, 42), (30, 30, 34))
    post_lines(cv, [[(118, 40), (118, 36)], [(112, 44), (126, 38)]], (30, 30, 34))
    txt(cv, "EQUIPO", 106, 52, (240, 240, 240))
    return cv


# ---------------------------------------------------------------- LA ESQUINA NUEVA (de noche)

def esquina(f):
    cv = Cv(f)
    env = Env((0.36, 0.36, 0.52), (1.2, 0.92, 0.62), (1, -1), half=0.3)
    sky(cv, 60, [(10, 10, 24), (18, 16, 36), (30, 24, 50)])
    stars(cv, f, 24, 40, seed=3)
    # Los edificios de enfrente, con dos ventanas prendidas; los cables.
    for bx, bw, bh in ((0, 70, 80), (70, 60, 64), (130, 90, 92), (220, 100, 70)):
        cv.shape(cv.box(bx, 100 - bh, bx + bw, 104), (86, 76, 80), env, shade=0, half=False, rim=False)
        cv.grain(cv.box(bx, 100 - bh, bx + bw, 104), 1.2)
    for wx, wy, on in ((14, 36, True), (40, 36, False), (90, 50, False), (150, 18, False), (176, 18, True), (150, 44, False), (240, 42, False), (276, 42, True)):
        cv.fill(cv.box(wx, wy, wx + 12, wy + 14), (250, 214, 130) if on else (30, 28, 40))
        if on:
            cv.glow(wx + 6, wy + 7, 14, (255, 210, 130), 0.4)
            cv.fill(cv.box(wx + 5, wy, wx + 6, wy + 14), (110, 80, 60))
    # La persiana de la tienda (cerrada) con grafiti; el aviso apagado.
    cv.shape(cv.box(196, 60, 300, 104), (130, 134, 142), env, shade=1)
    for y in range(62, 104, 3):
        cv.fill(cv.box(196, y, 300, y + 1), dk(env, (130, 134, 142), 0.7))
    tag = (200, 70, 160)
    post_lines(cv, [[(206, 92), (212, 76), (218, 92), (226, 74), (232, 90)], [(240, 80), (252, 78), (246, 92), (262, 88)], [(270, 74), (284, 94)]], tag, 2)
    cv.shape(cv.box(196, 48, 300, 58), (60, 60, 70), env, shade=1)
    txt(cv, "MISCELANEA", 226, 51, (120, 110, 90))
    # El andén, la calle, el charco.
    cv.shape(cv.box(0, 104, W, 112), (110, 108, 112), env, shade=1)
    floor(cv, 112, (60, 60, 68), env)
    cv.fill(cv.box(0, 140, W, 141), (140, 130, 70))
    pud = ell(cv, 110, 124, 30, 4)
    cv.fill(pud, (40, 40, 56))
    for k in range(3):
        rx = 100 + k * 8 + f * 2
        cv.fill(cv.box(rx, 123 + k % 2, rx + 6, 124 + k % 2) & pud, (230, 190, 110))
    # Las bolsas de basura al pie del poste.
    for bx, c in ((196, (40, 40, 46)), (206, (60, 60, 70)), (214, (40, 40, 46))):
        cv.shape(cv.mask(lambda d, bx=bx: (d.ell(bx, 104, 7, 6), d.poly([(bx - 1, 98), (bx + 1, 98), (bx, 94)]))), c, env, shade=2)
    # El poste y su luz (amarilla, de sodio); las polillas.
    cv.shape(cv.box(185, 18, 189, 108), (90, 92, 100), env, shade=1)
    cv.shape(cv.mask(lambda d: (d.cap(187, 20, 166, 16, 3), d.poly([(160, 14), (172, 14), (170, 19), (162, 19)]))), (90, 92, 100), env, shade=1)
    cv.fill(cv.box(162, 19, 170, 21), (255, 236, 170))
    cv.cone((166, 21), (110, 130), (230, 130), (255, 196, 110), 0.85, 0.5, 0.55)
    cv.glow(166, 21, 22, (255, 220, 140), 0.9)
    for k in range(4):
        a = (f + k) * 1.6 + k
        mx, my = 166 + np.cos(a) * (6 + k * 3), 26 + np.sin(a * 1.3) * 5
        cv.post.append(lambda d, mx=mx, my=my: d.point((int(mx), int(my)), fill=(255, 250, 220)))
    post_lines(cv, [[(0, 30), (100, 38), (187, 30)], [(187, 30), (320, 22)], [(0, 40), (187, 42)]], (20, 18, 26))
    # La moto de él (de Lisandro), parqueada a la derecha.
    for wx in (262, 300):
        cv.shape(ell(cv, wx, 118, 9, 9), (20, 20, 24), env, shade=1)
        cv.fill(ell(cv, wx, 118, 4, 4), (110, 110, 120))
    cv.shape(cv.mask(lambda d: (d.poly([(262, 110), (276, 102), (296, 102), (302, 112), (276, 114)]), d.cap(296, 102, 300, 92, 2))), (30, 30, 36), env, shade=1)
    return cv


# ---------------------------------------------------------------- LA CASA DE GUILLERMO

def camioneta(cv, env, x, y, color=(40, 90, 64)):
    """La camioneta (x, y: la llanta de atrás en el piso), mirando a la izquierda."""
    body = cv.mask(lambda d: (d.poly([(x - 34, y - 12), (x - 34, y - 34), (x - 22, y - 36), (x - 10, y - 56), (x + 56, y - 56), (x + 62, y - 36),
                                       (x + 74, y - 34), (x + 76, y - 14), (x + 70, y - 12)])))
    cv.shape(body, color, env, shade=2)
    glass = (60, 80, 100)
    cv.fill(poly(cv, [(x - 6, y - 52), (x + 18, y - 52), (x + 18, y - 38), (x - 14, y - 38)]), glass)
    cv.fill(poly(cv, [(x + 22, y - 52), (x + 52, y - 52), (x + 58, y - 38), (x + 22, y - 38)]), glass)
    cv.veil(poly(cv, [(x, y - 52), (x + 6, y - 52), (x - 2, y - 38), (x - 8, y - 38)]), (190, 210, 230), 0.6)
    post_lines(cv, [[(x + 20, y - 36), (x + 20, y - 14)], [(x - 14, y - 34), (x - 14, y - 14)]], dk(env, color, 0.6))
    cv.shape(cv.box(x - 36, y - 20, x + 78, y - 14), (60, 60, 66), env, shade=1)
    cv.fill(cv.box(x - 34, y - 32, x - 28, y - 28), (250, 246, 220))
    cv.fill(cv.box(x + 70, y - 32, x + 75, y - 28), (200, 40, 40))
    for wx in (x - 16, x + 54):
        cv.shape(ell(cv, wx, y - 10, 11, 11), (26, 26, 30), env, shade=2)
        cv.shape(ell(cv, wx, y - 10, 6, 6), (200, 204, 214), env, shade=1)
    cv.fill(cv.box(x + 6, y - 30, x + 12, y - 29) | cv.box(x + 30, y - 30, x + 36, y - 29), (220, 220, 226))
    return body


def casa_camila(f):
    cv = Cv(f)
    env = Env((0.7, 0.66, 0.66), (1.34, 1.14, 0.92), (1, -1), half=0.45)
    sky(cv, 80, [(100, 150, 220), (140, 184, 230), (196, 220, 236)])
    cloud(cv, 250 + f * 2, 18, 1.2, (250, 250, 252), (220, 224, 236))
    cv.fill(cv.mask(lambda d: [d.ell(x, 78 - (x * 3) % 6, 16, 9) for x in range(180, 340, 22)]), dk(env, (70, 120, 80), 0.8))
    # La casa: dos pisos, blanca con madera, ventanal, el garaje.
    house = (238, 234, 226)
    cv.shape(cv.box(0, 30, 176, 104), house, env, shade=2)
    cv.shape(poly(cv, [(-6, 32), (60, 12), (182, 30), (182, 34), (-6, 36)]), (70, 66, 70), env, shade=1)
    cv.shape(cv.box(110, 38, 176, 64), (160, 112, 72), env, shade=1)
    for xx in range(112, 176, 5):
        cv.fill(cv.box(xx, 38, xx + 1, 64), dk(env, (160, 112, 72), 0.75))
    cv.fill(cv.box(10, 40, 60, 64), (120, 160, 200))
    cv.fill(cv.box(34, 40, 36, 64), house)
    cv.veil(poly(cv, [(14, 64), (24, 40), (30, 40), (20, 64)]), (230, 240, 250), 0.5)
    cv.fill(cv.box(10, 72, 70, 100), (110, 150, 196))
    for xx in (30, 50):
        cv.fill(cv.box(xx, 72, xx + 2, 100), house)
    cv.shape(cv.box(80, 70, 100, 104), (120, 80, 50), env, shade=1)
    cv.px(96, 88, (240, 210, 120))
    cv.shape(cv.box(112, 68, 176, 104), (220, 220, 220), env, shade=1)  # la puerta del garaje
    for y in range(72, 104, 6):
        cv.fill(cv.box(112, y, 176, y + 1), dk(env, (220, 220, 220), 0.8))
    # El jardín: el seto, las flores, el buzón.
    floor(cv, 104, (186, 184, 180), env)
    for x0 in range(0, W, 24):
        cv.fill(cv.box(x0, 104, x0 + 1, H), dk(env, (186, 184, 180), 0.8))
    cv.shape(cv.mask(lambda d: [d.ell(x, 100, 9, 7) for x in range(4, 76, 12)]), (70, 130, 76), env, shade=2)
    rng = np.random.default_rng(3)
    for _ in range(26):
        cv.px(int(rng.integers(0, 76)), int(rng.integers(94, 104)), [(240, 90, 120), (250, 220, 90), (250, 250, 250)][int(rng.integers(0, 3))])
    cv.shape(cv.box(186, 76, 188, 104), (70, 70, 76), env, shade=1)  # la llave del agua
    cv.shape(cv.box(180, 86, 190, 92), (60, 60, 66), env, shade=1)
    # La camioneta, enjabonada; la manguera; el agua que le pega al rin.
    camioneta(cv, env, 236, 126)
    rng = np.random.default_rng(13)  # la espuma, abajo, donde Guillermo ya pasó la esponja
    for k in range(40):
        fx, fy = int(rng.integers(230, 300)), int(rng.integers(100, 112))
        cv.px(fx, fy, (246, 248, 252))
        if rng.random() < 0.5:
            cv.px(fx + 1, fy, (220, 226, 236))
    hose = (60, 150, 80)
    post_lines(cv, [[(188, 92), (194, 110), (210, 124), (232, 126), (250, 120)]], hose, 2)
    for k in range(6):  # el chorro
        t = ((k + f * 1.5) % 6) / 6
        wx, wy = 252 + t * 38, 116 - np.sin(t * np.pi) * 6 + t * 2
        cv.post.append(lambda d, wx=wx, wy=wy: d.point((int(wx), int(wy)), fill=(210, 230, 250)))
    cv.veil(ell(cv, 274, 130, 30, 3), (120, 140, 170), 0.6)  # el charco
    # Las bolsas de los tres almacenes.
    for bx, c, h in ((86, (236, 70, 90), 16), (98, (40, 40, 46), 18), (108, (250, 196, 60), 14)):
        cv.shape(cv.box(bx, 128 - h, bx + 10, 128), c, env, shade=1)
        post_lines(cv, [[(bx + 2, 128 - h), (bx + 5, 124 - h), (bx + 8, 128 - h)]], dk(env, c, 0.6))
        cv.fill(cv.box(bx + 3, 120 - h // 2, bx + 7, 122 - h // 2), (250, 250, 250))
    return cv


# ---------------------------------------------------------------- OTRA CIUDAD (al amanecer)

def ciudad(f):
    cv = Cv(f)
    env = Env((0.66, 0.56, 0.6), (1.4, 1.06, 0.76), (1, -1), half=0.5)
    sky(cv, 96, [(96, 110, 170), (176, 136, 170), (236, 160, 140), (252, 206, 150)])
    cv.glow(250, 88, 60, (255, 226, 170), 0.7)
    cv.fill(ell(cv, 250, 90, 12, 12), (255, 240, 200))
    for k in range(3):  # pájaros
        bx, by = 60 + k * 14 + f * 3, 26 + (k % 2) * 6
        cv.post.append(lambda d, bx=bx, by=by: d.line([(bx - 2, by - 1), (bx, by), (bx + 2, by - 1)], fill=(70, 50, 80)))
    # Los edificios de vidrio, a contraluz.
    rng = np.random.default_rng(11)
    for k in range(14):
        bx = k * 24 - 6 + int(rng.integers(0, 6))
        bh = int(rng.integers(26, 70))
        c = mix((90, 80, 110), (130, 110, 140), rng.random())
        cv.fill(cv.box(bx, 96 - bh, bx + 18, 98), c)
        for j in range(2, bh - 2, 5):
            cv.fill(cv.box(bx + 2, 96 - bh + j, bx + 16, 96 - bh + j + 1), mix(c, (250, 190, 140), 0.25))
    floor(cv, 98, (110, 150, 96), env)
    # El lago, con el sol adentro; el sendero de trote.
    lake = ell(cv, 230, 106, 90, 7)
    cv.fill(lake, (150, 140, 180))
    for k in range(5):
        cv.fill(cv.box(222 + (k * 7 + f * 3) % 30, 104 + k % 3 * 2, 228 + (k * 7 + f * 3) % 30, 105 + k % 3 * 2) & lake, (255, 226, 170))
    cv.fill(poly(cv, [(0, 118), (120, 110), (320, 116), (320, 130), (120, 124), (0, 134)]), dk(env, (196, 160, 130), 1.0))
    # Las palmas, los faroles, otra banca.
    for px_ in (40, 300):
        cv.shape(cv.mask(lambda d, px_=px_: d.path([(px_, 112), (px_ + 3, 80), (px_ + 1, 50)], 3.6)), (130, 100, 80), env, shade=1)
        for a in range(6):
            ang = a * 1.05 + 0.3
            cv.shape(cv.mask(lambda d, px_=px_, ang=ang: d.path([(px_ + 1, 50), (px_ + 1 + np.cos(ang) * 14, 46 - np.sin(ang) * 6), (px_ + 1 + np.cos(ang) * 24, 52 - np.sin(ang) * 2)], 3)), (60, 110, 70), env, shade=1)
    for lx in (110, 210):
        cv.fill(cv.box(lx, 76, lx + 2, 112), (50, 50, 60))
        cv.fill(ell(cv, lx + 1, 75, 3, 3), (250, 240, 210))
    # Uno que trota allá lejos, otro con un perro (que no es Lukas).
    jx = 260 - f * 4
    cv.fill(cv.mask(lambda d: (d.ell(jx, 98, 1.6, 1.6), d.rect(jx - 1, 100, jx + 1, 106))), (60, 50, 70))
    post_lines(cv, [[(jx, 106), (jx - 1 - f % 2, 110)], [(jx, 106), (jx + 1 + f % 2, 110)]], (60, 50, 70))
    cv.fill(cv.mask(lambda d: (d.ell(80, 102, 1.6, 1.6), d.rect(79, 104, 81, 112))), (60, 50, 70))
    cv.fill(cv.box(86, 109, 92, 111), (70, 56, 50))
    cv.px(92, 108, (70, 56, 50))
    post_lines(cv, [[(81, 106), (87, 109)]], (90, 70, 80))
    grass_tufts(cv, env, 136, 178, 40, 2, dk(env, (130, 170, 100), 1.1), f)
    return cv


# ---------------------------------------------------------------- LA CANTINA DE SIEMPRE

def cantina(f):
    cv = Cv(f)
    env = Env((0.5, 0.42, 0.42), (1.3, 1.0, 0.7), (1, -1), half=0.35)
    wall(cv, 104, (150, 60, 50), env)
    cv.grain(cv.box(0, 0, W, 104), 1.3)
    cv.shape(cv.box(0, 70, W, 104), (110, 70, 44), env, shade=0, half=False)  # el friso de madera
    for xx in range(0, W, 12):
        cv.fill(cv.box(xx, 70, xx + 1, 104), dk(env, (110, 70, 44), 0.7))
    floor(cv, 104, (60, 50, 50), env)
    tl = []
    for r in range(6):
        for c in range(-6, 26):
            y0 = 104 + r * 13
            tl.append((c, r, y0))
    for c, r, y0 in tl:
        if (c + r) % 2:
            x0 = c * 16 + (r * 4)
            cv.fill(poly(cv, [(x0, y0), (x0 + 16, y0), (x0 + 16 + 4, y0 + 13), (x0 + 4, y0 + 13)]) & cv.box(0, 104, W, H), dk(env, (220, 210, 196), 0.9))
    # Las luces de navidad (de todo el año).
    pts = [(x, 14 + int(4 * np.sin(x / 20.0))) for x in range(0, W + 1, 4)]
    post_lines(cv, [pts], (30, 40, 30))
    for i, (lx, ly) in enumerate(pts[1::3]):
        c = [(250, 70, 70), (90, 220, 110), (250, 210, 70), (90, 160, 250)][(i + f) % 4]
        cv.fill(cv.box(lx, ly + 1, lx + 2, ly + 3), c)
        if (i + f) % 2:
            cv.glow(lx + 1, ly + 2, 6, c, 0.6)
    # La repisa de las botellas, con el espejo detrás.
    cv.shape(cv.box(100, 24, 290, 66), (60, 40, 30), env, shade=1)
    cv.fill(cv.box(104, 28, 286, 62), (90, 80, 90))
    cv.veil(poly(cv, [(120, 62), (140, 28), (150, 28), (130, 62)]), (180, 170, 180), 0.5)
    for shelf in (44, 62):
        cv.shape(cv.box(100, shelf, 290, shelf + 3), (120, 80, 50), env, shade=1)
    rng = np.random.default_rng(2)
    for shelf in (44, 62):
        x = 108
        while x < 280:
            bc = [(60, 110, 70), (180, 120, 50), (240, 240, 240), (50, 90, 180), (150, 40, 40)][int(rng.integers(0, 5))]
            hgt = int(rng.integers(10, 15))
            cv.shape(cv.mask(lambda d, x=x, hgt=hgt: (d.rect(x, shelf - hgt + 3, x + 5, shelf), d.rect(x + 1.5, shelf - hgt - 1, x + 3.5, shelf - hgt + 3))), bc, env, shade=1)
            cv.fill(cv.box(x + 1, shelf - 7, x + 4, shelf - 4), (236, 226, 200))
            x += int(rng.integers(7, 11))
    # La rockola, prendida (sus luces van cambiando).
    rk = cv.mask(lambda d: (d.rect(8, 50, 48, 104), d.ell(28, 50, 20, 14)))
    cv.shape(rk, (120, 60, 40), env, shade=2)
    arc = ell(cv, 28, 52, 16, 11) & ~ell(cv, 28, 52, 12, 8) & cv.box(0, 0, W, 60)
    for k in range(4):
        band = arc & cv.box(12 + k * 8, 0, 20 + k * 8, H)
        cv.fill(band, [(250, 120, 60), (250, 220, 90), (90, 220, 200), (230, 90, 200)][(k + f) % 4])
    cv.fill(cv.box(14, 62, 42, 76), (240, 226, 190))
    for k in range(4):
        cv.fill(cv.box(16, 64 + k * 3, 40, 65 + k * 3), (160, 140, 120))
    cv.fill(cv.box(14, 82, 42, 98), (60, 40, 30))
    for k in range(5):
        cv.fill(cv.box(15 + k * 6, 84, 18 + k * 6, 96), (90, 60, 40))
    cv.glow(28, 64, 30, (255, 170, 90), 0.5)
    # El televisor en la esquina: el partido (repetido).
    cv.shape(cv.box(260, 72, 300, 96), (36, 36, 40), env, shade=1)
    cv.fill(cv.box(263, 75, 297, 93), (70, 150, 80))
    cv.fill(cv.box(279, 75, 280, 93), (200, 236, 210))
    for k in range(5):
        px_ = 265 + (k * 7 + f * (2 if k % 2 else -2)) % 30
        cv.fill(cv.box(px_, 79 + (k * 4) % 12, px_ + 1, 81 + (k * 4) % 12), (250, 220, 60) if k % 2 else (250, 250, 250))
    cv.glow(280, 84, 24, (160, 230, 170), 0.35)
    # La barra (delante de todo), con los vasos, las tapas en el piso; el almanaque de la playa.
    cv.shape(cv.box(64, 84, 256, 90), (140, 92, 56), env, shade=1)
    cv.shape(cv.box(66, 90, 254, 118), (110, 70, 44), env, shade=1)
    for xx in range(70, 254, 20):
        cv.fill(cv.box(xx, 92, xx + 16, 116) & ~cv.box(xx + 1, 93, xx + 15, 115), dk(env, (110, 70, 44), 0.7))
    for gx in (100, 150, 196, 236):
        cv.shape(cv.mask(lambda d, gx=gx: (d.rect(gx, 77, gx + 5, 84))), (220, 200, 120), env, shade=1)
        cv.fill(cv.box(gx, 77, gx + 5, 78), (250, 250, 240))
    cv.shape(cv.mask(lambda d: (d.rect(172, 74, 176, 84), d.rect(173, 70, 175, 74))), (60, 110, 70), env, shade=1)
    rng = np.random.default_rng(9)
    for _ in range(14):
        cx_, cy_ = int(rng.integers(40, 280)), int(rng.integers(118, 128))
        cv.px(cx_, cy_, (210, 200, 160))
    cv.shape(cv.box(58, 18, 86, 44), (244, 240, 230), env, shade=1)
    cv.fill(cv.box(60, 20, 84, 32), (90, 170, 220))
    cv.fill(cv.box(60, 28, 84, 32), (236, 210, 150))
    cv.fill(cv.mask(lambda d: d.poly([(70, 32), (72, 22), (76, 32)])), (60, 130, 70))
    for r in range(2):
        for c in range(6):
            cv.px(62 + c * 4, 36 + r * 3, (80, 80, 90))
    return cv


# ---------------------------------------------------------------- EL CUMPLEAÑOS DE VICTORIA

def victoria(f, con_bici=False):
    cv = Cv(f)
    env = Env((0.7, 0.66, 0.66), (1.32, 1.12, 0.9), (1, -1), half=0.45)
    sky(cv, 80, [(110, 160, 226), (150, 190, 232), (206, 224, 236)])
    cloud(cv, 90 + f * 2, 16, 1.1, (250, 250, 252), (220, 224, 236))
    cloud(cv, 196 + f * 2, 26, 0.8, (250, 250, 252), (220, 224, 236))
    # El colegio, al fondo, con la bandera y la reja.
    school = (232, 210, 160)
    cv.shape(cv.box(0, 40, 150, 82), school, env.but(amb=(0.82, 0.8, 0.82)), shade=1)
    cv.fill(cv.box(0, 36, 150, 40), (176, 96, 76))
    for r in range(2):
        for c in range(7):
            cv.fill(cv.box(6 + c * 20, 46 + r * 16, 18 + c * 20, 56 + r * 16), (110, 140, 176))
    cv.fill(cv.box(132, 14, 133, 40), (180, 180, 190))
    wave = [0, 1, 0, -1][f]
    cv.fill(poly(cv, [(133, 14), (147, 15 + wave), (147, 18 + wave), (133, 18)]), (250, 210, 60))
    cv.fill(poly(cv, [(133, 18), (147, 18 + wave), (147, 20 + wave), (133, 20)]), (40, 80, 180))
    cv.fill(poly(cv, [(133, 20), (147, 20 + wave), (147, 22 + wave), (133, 22)]), (210, 50, 60))
    cv.fill(cv.mask(lambda d: [d.ell(x, 78 - (x * 5) % 7, 15, 9) for x in range(150, 330, 22)]), dk(env, (70, 120, 80), 0.8))
    floor(cv, 82, (114, 156, 94), env)
    fence(cv, env.but(amb=(0.78, 0.78, 0.84)), 66, 88, 0, 160, 5, (70, 76, 92))
    # El guayacán (a la derecha) y, debajo, chiquitas, las dos cruces.
    guayacan(cv, env, 270, 100, 0.85, seed=8)
    carpet(cv, 200, 320, 94, 126, 120, 12, (250, 214, 70), (226, 176, 48))
    cross(cv, env, 258, 106, 10, 0.5)
    cross(cv, env, 272, 107, 14, 0.7)
    # La banca verde, con los globos amarrados.
    bench(cv, env, 46, 112, 52)
    balloons(cv, env, 98, 98, f)
    if con_bici:
        bici(cv, env, 166, 120)
        cv.veil(ell(cv, 182, 121, 24, 2), (30, 40, 30), 0.5)
    else:  # el regalo, en la banca: envuelto con un clavel encima
        cv.shape(cv.box(62, 92, 76, 100), (240, 120, 160), env, shade=1)
        cv.fill(cv.box(68, 92, 70, 100) | cv.box(62, 95, 76, 96), (250, 230, 120))
        cv.fill(ell(cv, 72, 91, 2, 1.6), (224, 54, 64))
        post_lines(cv, [[(72, 92), (78, 93)]], (60, 120, 66))
    grass_tufts(cv, env, 96, 128, 50, 5, dk(env, (130, 170, 100), 1.05), f)
    return cv


def fin(f):
    """El guayacán al atardecer, con las dos cruces. Encima va el FIN."""
    cv = Cv(f)
    env = Env((0.54, 0.44, 0.56), (1.42, 0.98, 0.7), (-1, -1), half=0.5)
    sky(cv, 100, [(50, 50, 100), (110, 80, 130), (210, 120, 120), (250, 180, 130)])
    stars(cv, f, 14, 30, seed=9)
    cv.glow(40, 98, 60, (255, 190, 120), 0.6)
    cv.fill(cv.mask(lambda d: [d.ell(x, 96 - (x * 7) % 9, 18, 10) for x in range(-10, 340, 24)]), (54, 48, 70))
    floor(cv, 98, (90, 100, 80), env)
    guayacan(cv, env, 172, 116, 1.0, seed=21, sun=(255, 200, 110))
    carpet(cv, 90, 260, 104, 128, 150, 8, (236, 180, 70), (200, 140, 50))
    mound(cv, env, 150, 126, 12, 3)
    cross(cv, env, 150, 123, 14, 0.7)
    mound(cv, env, 192, 127, 20, 4)
    cross(cv, env, 192, 123, 24, 1.0)
    cv.fill(ell(cv, 186, 124, 2, 1.6), (200, 50, 60))
    cv.fill(cv.box(200, 118, 204, 124), (190, 190, 200))
    # La rueda de una bicicleta pasó por aquí (la huella, en la tierra).
    cv.veil(poly(cv, [(40, 126), (120, 120), (250, 118), (320, 121), (320, 123), (250, 120), (120, 122), (40, 128)]), (60, 60, 60), 0.6)
    return cv


# ---------------------------------------------------------------- la salida

SCENES = {
    "entierro": entierro, "cocina": cocina, "garaje": garaje, "apartamento": apartamento, "oficina": oficina,
    "esquina": esquina, "casa_camila": casa_camila, "ciudad": ciudad, "cantina": cantina,
    "victoria": victoria, "victoria_bici": lambda f: victoria(f, True), "fin": fin,
}


def build(name):
    sheet = Image.new("RGBA", (W * FRAMES, H))
    for f in range(FRAMES):
        sheet.paste(SCENES[name](f).image(), (f * W, 0))
    sheet.save(OUT + name + ".png")
    return name


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    names = sys.argv[1:] or list(SCENES)
    if names and names[0] == "--prueba":  # una hoja para mirar (el cuadro 0 de cada uno, a 2x)
        out, names = names[1], names[2:] or list(SCENES)
        cols = 3
        rows = (len(names) + cols - 1) // cols
        img = Image.new("RGB", (W * cols, H * rows))
        for i, n in enumerate(names):
            img.paste(SCENES[n](0).image().convert("RGB"), ((i % cols) * W, (i // cols) * H))
        img.resize((img.width * 2, img.height * 2), Image.NEAREST).save(out)
    else:
        from multiprocessing import Pool
        with Pool() as p:
            for n in p.imap_unordered(build, names):
                print("ok", n)
