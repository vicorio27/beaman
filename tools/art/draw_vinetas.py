"""Las viñetas de la noche (python tools/art/draw_vinetas.py, desde la carpeta del proyecto).

Ningún texto de la noche va sobre negro: cada uno tiene su cuadro, animado (cuatro cuadros que se pasan
despacio: respiran, llueve, gotea, titila). Son incómodos a propósito: nadie duerme bien en ninguno.

Una hoja por lugar donde duerme (assets/ui/vinetas_<lugar>.png, 960 x 2500): cada fila es una viñeta
(4 cuadros de 240x100). Las filas, en orden (ver ROWS; NightSequence.gd tiene la misma cuenta):
    fila = tipo * 4 + lluvia * 2 + solo          (solo = sin Lukas)
    tipo 0  dormir, de noche          cómo quedó dormido
    tipo 1  sueno, de noche           lo que sueña le sale de la cabeza, en neón
    tipo 2  despierta, al alba        la mañana siguiente
    tipo 3  despierta, de noche       lo despertó un sueño
    tipo 4  golpeado, al alba         lo robaron, o perdió la pelea
    tipo 5  golpeado, de noche        perdió en el sueño
    fila 24 final                     el último amanecer: Samuel lo encuentra
Lugares: banco, kiosco, rio, callejon, parque, pension, lote.

Y una hoja de momentos que no dependen del lugar (assets/ui/vinetas_momentos.png), una fila cada uno:
    0 intruso   1 intruso (sin Lukas)   2 Lukas en el pecho   3 Lukas, quieto   4 el entierro   5 el collar
  y los carteles de cambio de escena (SceneRouter: el título sale debajo):
    6 antes (la noche del operativo)   7 la moto (ANTES)   8 el billar   9 el desmayo   10 el desmayo (sin Lukas)
    11 el final (la reja del colegio)
  y: 12 mirar desde el puente, al atardecer   13 lo mismo, sin Lukas   14 desde el puente, de día
     15 el espejo de Lisandro (antes de PLOMO)   16 el espejo, capítulo 3 (la bolsita)
Y una hoja del prólogo (assets/ui/vinetas_prologo.png): una fila por cada texto de la huida (PROLOGO).

El motor (formas, luz, actores) está en tools/art/vinetas_motor.py.
    python tools/art/draw_vinetas.py                    todo
    python tools/art/draw_vinetas.py rio lote           solo esos lugares (o "momentos")
    python tools/art/draw_vinetas.py --prueba hoja.png rio:dormir:noche:1:0 momentos:2 ...   una hoja para mirar
"""
import os
import sys
from multiprocessing import Pool

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from vinetas_motor import (W, H, BAY, Cv, Env, Actor, col, mix, breath, vapor, rain, splashes, stars, ground_shadow,  # noqa: E402
                           man_side, man_back, man_bench, man_sit, man_wake, man_stand,
                           lukas_curl, lukas_down, lukas_sit, figure, _limb,
                           COAT, PANTS, HAIR, BEARD, SKIN, SHIRT, TIE, SHOE_A, SHOE_B, PACK, TAN, EAR, BLACK, WHITE, CARTON, TARP)

import vinetas_motor  # noqa: E402
vinetas_motor.POLISH = True   # el acabado: el contorno de los actores, las manchas, el viñeteado

OUT = "assets/ui/"
FRAMES = 4
KINDS = [("dormir", "noche"), ("sueno", "noche"), ("despierta", "alba"), ("despierta", "noche"),
         ("golpeado", "alba"), ("golpeado", "noche")]
ROWS = [(p, t, r, s) for (p, t) in KINDS for r in (0, 1) for s in (0, 1)] + [("final", "alba", 0, 1)]
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)

SKY = {
    ("noche", 0): [(8, 10, 26), (13, 15, 38), (22, 22, 54), (36, 32, 72)],
    ("noche", 1): [(9, 10, 18), (14, 15, 26), (21, 22, 36), (30, 31, 48)],
    ("alba", 0): [(60, 66, 112), (126, 100, 142), (220, 144, 130), (250, 198, 150), (255, 230, 188)],
    ("alba", 1): [(58, 64, 80), (84, 90, 106), (110, 116, 130), (136, 140, 150)],
}
ENV = {
    ("noche", 0): Env((0.36, 0.40, 0.60), (0.86, 0.96, 1.32), half=0.3),
    ("noche", 1): Env((0.30, 0.33, 0.48), (0.62, 0.70, 0.96), half=0.25),
    ("alba", 0): Env((0.62, 0.52, 0.60), (1.38, 1.04, 0.74), half=0.5),
    ("alba", 1): Env((0.50, 0.53, 0.62), (0.86, 0.92, 1.02), half=0.4),
}
RAIN_COL = {"noche": (92, 104, 142), "alba": (178, 186, 204)}
WOOD, IRON, STONE, BRICK = (164, 114, 72), (74, 74, 90), (150, 150, 162), (156, 98, 84)
SAMUEL = dict(coat=(136, 104, 70), pants=(84, 78, 82), hair=(176, 174, 170), beard=(196, 194, 188), tie=False)
CAP_RED = (176, 70, 58)


# ---------------------------------------------------------------- Lo que usan todos los lugares

def sky(cv, time, rain_, y1, x0=0, x1=W):
    cv.grad((x0, 0, x1, y1), SKY[(time, rain_)], ease=0.95)


def ground(cv, y0, alb, env, y1=H, k=(1.0, 0.8, 0.58)):
    cv.grad((0, y0, W, y1), [col(alb, env.amb * q) for q in k])
    if vinetas_motor.POLISH:  # el piso también tiene manchas (el barro, el aceite, lo que se derramó)
        cv.grain(cv.box(0, y0, W, y1), 0.8)
        # Y donde la pared se junta con el piso, la sombrita de contacto (tramada: más arriba, más).
        for i, k in enumerate((0.6, 0.35, 0.15)[:max(0, min(3, y1 - y0))]):
            row = cv.a[y0 + i]
            on = vinetas_motor.BAY[y0 + i] < k
            row[on] = (row[on] * 0.8).astype(np.uint8)


def lines(cv, segs, color, m=None, width=1):
    img = Image.fromarray(cv.a)
    d = ImageDraw.Draw(img)
    for s in segs:
        d.line(s, fill=color, width=width)
    out = np.asarray(img)
    if m is None:
        cv.a = out.copy()
    else:
        cv.a[m] = out[m]


def poly(cv, pts):
    return cv.mask(lambda d: d.poly(pts))


def beam(cv, p0, p1, spread, color, strength=0.7, amount=0.6):
    """Un chorro de luz de p0 a p1 (la linterna), que se abre hasta spread."""
    ys, xs = np.mgrid[0:H, 0:W]
    ax, ay = p1[0] - p0[0], p1[1] - p0[1]
    ln = max(1.0, (ax * ax + ay * ay) ** 0.5)
    t = ((xs - p0[0]) * ax + (ys - p0[1]) * ay) / (ln * ln)
    side = np.abs((xs - p0[0]) * ay - (ys - p0[1]) * ax) / ln
    inside = (t > 0) & (t < 1.15) & (side < spread * np.clip(t, 0.05, 1.2))
    cv.light(np.where(inside, strength * (1 - np.clip(t, 0, 1) * 0.5), 0.0), color, amount)


def dream(cv, f, head):
    """Se queda dormido: lo que sueña le sale de la cabeza, en humo de neón, con cosas flotando."""
    hx, hy = head
    side = 1.0 if hx < 132 else -1.0
    ys, xs = np.mgrid[0:H, 0:W]
    t = np.clip((hy - ys) / max(1.0, hy - 2.0), 0, 1)

    def centre(y):
        tt = np.clip((hy - y) / max(1.0, hy - 2.0), 0, 1)
        return hx + np.sin(y / 8.0 + f * 1.4) * 7 * tt + side * (tt ** 1.3) * 40
    wdt = 3.0 + t * 40
    k = np.clip(1 - np.abs(xs - centre(ys)) / wdt, 0, 1) * (ys < hy + 2) * (0.5 + 0.4 * t)
    band = ((xs * side + ys * 2 + f * 9) // 16).astype(int) % 3
    on = k > BAY
    strong = k > 0.46
    for i, c in enumerate([(236, 70, 150), (80, 206, 236), (250, 204, 90)]):
        cv.a[on & (band == i)] = mix(c, (20, 16, 40), 0.55)
        cv.a[on & strong & (band == i)] = c
    o = [0, -1, -2, -1][f]
    ink = (16, 12, 30)

    def things(d):
        y1 = max(10, hy - 26)                                             # un puño
        x1 = float(centre(y1)) - 4
        d.rectangle([x1, y1 + o, x1 + 8, y1 + 6 + o], fill=ink)
        d.rectangle([x1 - 2, y1 + 2 + o, x1, y1 + 6 + o], fill=ink)
        y2 = max(8, hy - 46)                                              # una rueda
        x2 = float(centre(y2)) + side * 10
        d.ellipse([x2 - 6, y2 - 6 - o, x2 + 6, y2 + 6 - o], outline=ink, width=2)
        d.point((x2, y2 - o), fill=ink)
        y3 = max(6, hy - 62)                                              # una culebra
        x3 = float(centre(y3)) - side * 16
        d.line([(x3 - 10, y3 + o), (x3 - 5, y3 - 4 + o), (x3, y3 + o), (x3 + 5, y3 - 4 + o), (x3 + 10, y3 + o)], fill=ink, width=2)
    cv.post.append(things)


def collar_at(cv, p, env):
    """El collar de Lukas, en la mano: un aro de cuero y la plaquita."""
    x, y = p
    leather = col((176, 106, 60), env.amb + (env.key - env.amb) * 0.6)
    cv.post.append(lambda d: (d.ellipse([x - 4, y - 5, x + 3, y + 2], outline=leather), d.point((x - 1, y + 2), fill=(236, 236, 244))))


def small_man(cv, x, y, s, color, rim=None, lean=0.0, bottle=False):
    """Uno, lejos (en la boca del callejón): una silueta."""
    m = cv.mask(lambda d: (d.ell(lean * 4, -52 * s, 5.6 * s, 6 * s), d.cap(lean * 2, -42 * s, 0, -24 * s, 12.5 * s),
                           d.cap(-3 * s, -22 * s, -3.5 * s, -2 * s, 5.4 * s), d.cap(3 * s, -22 * s, 4 * s, -2 * s, 5.4 * s),
                           d.cap(5 * s, -38 * s, 9 * s, -24 * s, 4 * s)), x, y)
    cv.fill(m, color)
    if rim:
        from vinetas_motor import nb
        cv.fill(m & ~nb(m, 1, 0), rim)
    if bottle:
        cv.post.append(lambda d: d.line([(x + 9 * s, y - 24 * s), (x + 9 * s, y - 18 * s)], fill=(120, 190, 130)))


def clutter(cv, env, x, y, seed=0):
    """Lo que quedó regado después de que lo esculcaron: la mochila abierta, papeles, una lata."""
    cv.shape(cv.mask(lambda d: (d.cap(0, -5, 8, -5, 9), d.poly([(8, -9), (16, -4), (14, -0.5), (6, -0.5)])), x, y), PACK, env)
    cv.fill(cv.mask(lambda d: d.poly([(9, -8), (15, -4), (12, -2), (8, -5)]), x, y), col((30, 34, 30), env.amb))
    rng = np.random.default_rng(seed + 5)
    for _ in range(5):
        px_, py_ = x + int(rng.integers(-16, 30)), y - int(rng.integers(0, 4))
        cv.fill(cv.box(px_, py_ - 1, px_ + 3, py_ + 1), col((226, 222, 210), env.amb * 1.15))
    cv.shape(cv.mask(lambda d: d.cap(-14, -1.8, -9, -1.8, 3.6), x, y), (170, 176, 188), env, shade=1)


def samuel(cv, env, x, y, flip=False):
    a = Actor(cv, env, x, y, flip)
    man_stand(a, hold_hat=CAP_RED, **SAMUEL)
    return a


def frame(img):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, H - 1], outline=(14, 11, 20, 255))
    for x, y in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        img.putpixel((x, y), (0, 0, 0, 0))
    return img


def cast(cv, env, pose, f, solo, P):
    """Los actores, según el momento. P: dónde va cada postura en este lugar (ver cada lugar).
    Devuelve los puntos del cuerpo de él (la cabeza, la mano)."""
    b = breath(f) if pose in ("dormir", "sueno") else 0
    if pose in ("dormir", "sueno", "final"):
        return P["dormir"](b if pose != "final" else 0, pose == "final")
    if pose == "despierta":
        return P["despierta"]()
    return P["golpeado"]()


# ---------------------------------------------------------------- EL BANCO DE LA PLAZA

def banco(pose, time, rain_, solo, f):
    cv = Cv(f)
    night = time == "noche"
    env = ENV[(time, rain_)]
    env = env.but(key=(1.42, 1.06, 0.62) if not rain_ else (1.15, 0.92, 0.62), L=(1, -1)) if night else env.but(L=(-1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    sky(cv, time, rain_, 50)
    if night and not rain_:
        stars(cv, f, 16, 20, seed=2)
    # Las fachadas del fondo: la panadería (madruga), una casa con una ventana prendida, una bodega.
    fac = [(0, 76, 22, (172, 142, 124)), (76, 152, 12, (132, 144, 166)), (152, 240, 26, (160, 126, 132))]
    for x0, x1, top, alb in fac:
        cv.shape(cv.box(x0, top, x1, 64), alb, env, shade=0, half=False, emph=0.78)
        cv.fill(cv.box(x0, top + 1, x0 + 1, 64), dk(alb, 0.5))
    cv.fill(cv.box(4, 27, 72, 32), dk((214, 86, 64), 0.95))                       # el aviso de la panadería
    for yy in range(36, 62, 3):
        cv.fill(cv.box(6, yy, 46, yy + 1), dk((172, 142, 124), 0.5))             # la persiana
    cv.fill(cv.box(52, 38, 70, 60), (250, 214, 130) if not night else dk((90, 100, 124), 0.6))  # la vitrina
    for yy in (45, 52):
        cv.fill(cv.box(52, yy, 70, yy + 1), (196, 140, 84) if not night else dk((60, 66, 84), 0.6))   # las bandejas
    if not night:
        cv.glow(61, 52, 20, (255, 220, 140), 0.55)
    for i in range(3):
        for j in range(2):
            lit = night and (i, j) == (1, 0)
            cv.fill(cv.box(84 + i * 22, 20 + j * 20, 95 + i * 22, 32 + j * 20), (240, 200, 116) if lit else dk((80, 92, 120), 0.6))
            cv.fill(cv.box(89 + i * 22, 20 + j * 20, 90 + i * 22, 32 + j * 20), dk((132, 144, 166), 0.9))
    cv.fill(cv.box(190, 40, 206, 64), dk((90, 70, 60), 0.6))                      # la puerta de la bodega
    cv.fill(cv.box(162, 36, 182, 50), dk((70, 80, 100), 0.5))
    for xx in range(164, 182, 4):
        cv.fill(cv.box(xx, 36, xx + 1, 50), dk((160, 126, 132), 0.9))
    # El andén y las baldosas de la plaza.
    cv.fill(cv.box(0, 64, W, 70), dk((160, 156, 160), 0.9))
    cv.fill(cv.box(0, 64, W, 65), dk((160, 156, 160), 1.25))
    ground(cv, 70, (156, 132, 124), env)
    for yy, step in ((76, 26), (84, 32), (93, 40)):
        cv.a[yy] = (cv.a[yy] * 0.8).astype(np.uint8)
        for xx in range((yy * 7) % step, W, step):
            cv.a[yy - 5:yy, xx] = (cv.a[yy - 5:yy, xx] * 0.82).astype(np.uint8)
    # La fuente, apagada.
    cv.shape(cv.mask(lambda d: (d.ell(34, 80, 24, 5.5), d.cap(34, 79, 34, 64, 4.5), d.ell(34, 62, 8, 2.6))), STONE, env)
    cv.fill(cv.mask(lambda d: d.ell(34, 78.6, 20, 3)), dk((60, 80, 120), 0.9))
    # El farol.
    cv.shape(cv.box(199, 14, 202, 88), IRON, env, shade=0, half=False)
    cv.shape(cv.box(190, 11, 204, 14), IRON, env, shade=0, half=False)
    if night:
        cv.fill(cv.box(192, 14, 199, 16), (255, 236, 180))
        cv.cone((196, 15), (124, 97), (238, 97), (255, 204, 124), 0.66 if f != 3 else 0.58)
        cv.glow(196, 15, 10, (255, 230, 170), 0.95)
        if rain_:
            cv.glow(196, 93, 26, (255, 204, 124), 0.5, squash=0.22)             # el farol, en el piso mojado
        for i, (mx, my) in enumerate([(189, 22), (203, 18), (195, 27)]):          # las polillas
            cv.px(mx + (f * 2 + i) % 4, my + (f + i) % 3, (255, 240, 200))
    # El banco.
    ground_shadow(cv, 126, 89, 46, 3)
    for yy in (49, 54, 59):
        cv.shape(cv.box(86, yy, 168, yy + 4), WOOD, env, shade=1, half=False)
    cv.shape(cv.box(88, 46, 91, 88), IRON, env, shade=0, half=False)
    cv.shape(cv.box(163, 46, 166, 88), IRON, env, shade=0, half=False)
    cv.shape(cv.box(84, 66, 170, 70), WOOD, env, shade=1, half=False, emph=1.1)
    cv.shape(cv.mask(lambda d: d.cap(228, 76, 228, 85, 11)), (84, 116, 96), env)  # la caneca
    under = cv.box(86, 70, 168, 89)

    def dormir(b, still):
        if not solo:  # Lukas abajo, de guardia: el único con techo
            lukas_down(Actor(cv, env, 100, 88, flip=True, emph=0.86), 0, "down", ear_up=(f == 3))
        a = Actor(cv, env, 116, 88)
        pts = man_bench(a, b)
        if not still:
            vapor(cv, f, pts["head"][0] + 8, pts["head"][1] + 2)
        return pts

    def despierta():
        cv.shape(cv.mask(lambda d: d.cap(97, 60, 105, 60, 11)), PACK, env)        # la mochila, al lado
        pts = man_bench(Actor(cv, env, 118, 88), 0, awake=True)
        if not solo:
            lukas_sit(Actor(cv, env, 164, 89, flip=True), f % 2)
        return pts

    def golpeado():
        pts = man_sit(Actor(cv, env, 110, 92), 0, "golpeado")
        clutter(cv, env, 176, 93, 1)
        if not solo:
            lukas_sit(Actor(cv, env, 152, 93, flip=True), 0, up=True)
        return pts

    pts = cast(cv, env, pose, f, solo, {"dormir": dormir, "despierta": despierta, "golpeado": golpeado})
    if not night:  # las palomas madrugan
        for i, (px_, py_) in enumerate([(56, 93), (66, 96), (214, 94)]):
            bob = (f + i) % 2
            cv.fill(cv.box(px_, py_ - 2, px_ + 4, py_), dk((150, 150, 166), 1.1))
            cv.px(px_ + 4, py_ - 3 + bob, dk((150, 150, 166), 1.3))
    if rain_:
        lampf = (lambda x, y: (236, 200, 140) if abs(x - 196) < (y - 10) * 0.62 else None) if night else None
        rain(cv, f, 130, RAIN_COL[time], m=~under, lit=lampf)
        splashes(cv, f, 72, 99, 16, mix(RAIN_COL[time], (255, 255, 255), 0.3), m=~under)
        for i, xx in enumerate((92, 118, 150)):                                   # el banco, goteando
            cv.px(xx, 71 + (f * 5 + i * 6) % 16, mix(RAIN_COL[time], (255, 255, 255), 0.4))
    if pose == "sueno":
        dream(cv, f, pts["head"])
    if pose == "final":
        collar_at(cv, pts["hand"], env)
        samuel(cv, env, 192, 92, flip=True)
    return cv


# ---------------------------------------------------------------- EL KIOSCO VIEJO

def kiosco(pose, time, rain_, solo, f):
    cv = Cv(f)
    night = time == "noche"
    env = ENV[(time, rain_)].but(L=(-1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    out_col = SKY[(time, rain_)][2]
    cv.fill(cv.box(0, 0, W, 72), out_col)                                         # lo de afuera, por las rendijas
    rng = np.random.default_rng(4)
    for x in range(0, W, 13):
        v = int(rng.integers(-14, 14))
        cv.shape(cv.box(x, 8, x + 12, 71), (130 + v, 102 + v, 84 + v), env, shade=0, half=False, rim=False, emph=0.8 + (x % 3) * 0.05)
        if rng.random() < 0.5:
            cv.fill(cv.box(x + 3, int(rng.integers(14, 60)), x + 5, int(rng.integers(62, 70))), dk((130, 102, 84), 0.5))
    cv.shape(cv.box(0, 36, W, 40), (120, 92, 74), env, shade=1, half=False)       # el travesaño
    cv.fill(cv.box(0, 0, W, 8), dk((80, 66, 60), 0.5))                            # el techo
    hole = poly(cv, [(50, 0), (73, 0), (67, 8), (55, 8)])
    cv.fill(hole, SKY[(time, rain_)][1])
    ground(cv, 71, (128, 106, 94), env)
    for yy in (79, 89):
        cv.a[yy] = (cv.a[yy] * 0.82).astype(np.uint8)
    # La repisa: dos botellas vacías y un radio que no suena. El aviso: FIADO NO.
    cv.shape(cv.box(150, 31, 210, 33), WOOD, env, shade=0, half=False)
    cv.shape(cv.mask(lambda d: (d.cap(158, 27, 158, 23, 3.4), d.cap(166, 27, 166, 24, 3.4))), (96, 150, 110), env, shade=1)
    cv.shape(cv.box(178, 21, 198, 31), (70, 60, 64), env, shade=1)
    cv.px(194, 25, dk((240, 200, 120), 1.4))
    cv.shape(cv.box(98, 16, 136, 30), (176, 150, 112), env, shade=1, half=False)
    tinta = dk((70, 50, 44), 0.9)
    cv.post.append(lambda d: (d.line([(103, 21), (130, 21)], fill=tinta), d.line([(108, 26), (125, 26)], fill=tinta)))
    # La luz que entra por el hueco del techo; al alba, también por las rendijas.
    keyc = col((255, 255, 255), env.key * 0.72)
    cv.cone((61, 6), (30, 99), (104, 99), keyc, 0.5 if night else 0.62)
    if not night and not rain_:
        for x in (25, 90, 142, 207):                                              # el sol, por cuatro rendijas
            cv.light(poly(cv, [(x, 71), (x + 2, 71), (x + 30, 99), (x + 21, 99)]) * 0.62, (255, 214, 150), 0.6)
            cv.fill(cv.box(x, 9, x + 1, 71), (255, 226, 170))
    # La gotera: la lata, llena, y el charco.
    big = 1 if rain_ else 0
    wet = dk((84, 104, 160), 1.25)
    cv.fill(cv.mask(lambda d: d.ell(62, 92, 20 + big * 18, 3.6 + big * 1.6)), wet)
    if rain_:
        cv.fill(cv.mask(lambda d: d.ell(104, 94.5, 24 + f * 1.5, 2.2)), wet)       # el agua, que camina hacia el cartón
    ring = mix(wet, (255, 255, 255), 0.35)
    cv.post.append(lambda d: d.arc([62 - 6 - f * 3, 90 - f * 0.6, 62 + 6 + f * 3, 94 + f * 0.6], 0, 360, fill=ring))
    cv.shape(cv.mask(lambda d: d.cap(61, 81.5, 61, 86.5, 9.5)), (156, 160, 172), env, shade=1)
    cv.fill(cv.box(57, 78, 66, 79), mix(wet, (255, 255, 255), 0.5))
    drop = mix(wet, (255, 255, 255), 0.6)
    for i in range(3 if rain_ else 1):
        gy = 9 + (f * 17 + i * 23) % 66
        cv.fill(cv.box(61, gy, 62, gy + 3), drop)
    if rain_:
        for i in range(2):                                                         # otra gotera, nueva
            gy = 9 + (f * 13 + i * 31) % 80
            cv.fill(cv.box(118, gy, 119, gy + 3), drop)
        cv.px(117 + f % 3, 92, drop)
        rain(cv, f, 60, RAIN_COL[time], m=hole)
    # El cartón, en la esquina seca.
    cv.shape(poly(cv, [(126, 87), (208, 87), (213, 96), (121, 96)]), CARTON, env, shade=1)

    def dormir(b, still):
        if still:
            pts = man_side(Actor(cv, env, 170, 89), 0, reach=True, still=True)
        else:
            pts = man_side(Actor(cv, env, 170, 89), b, away=True)                  # de espaldas a la gotera
            if not solo:  # Lukas, pegado a la espalda: es lo que tenemos de frente
                lukas_curl(Actor(cv, env, 158, 95), b)
        return pts

    def despierta():
        pts = man_wake(Actor(cv, env, 148, 92), 0, reach=not solo)
        if not solo:
            lukas_sit(Actor(cv, env, 188, 93, flip=True), f % 2)
        return pts

    def golpeado():
        pts = man_sit(Actor(cv, env, 146, 93), 0, "golpeado")
        clutter(cv, env, 204, 95, 2)
        if not solo:
            lukas_sit(Actor(cv, env, 186, 94, flip=True), 0)
        return pts

    pts = cast(cv, env, pose, f, solo, {"dormir": dormir, "despierta": despierta, "golpeado": golpeado})
    if pose == "sueno":
        dream(cv, f, pts["head"])
    if pose == "final":
        collar_at(cv, pts["hand"], env)
        samuel(cv, env, 222, 95, flip=True)
    return cv


# ---------------------------------------------------------------- DEBAJO DEL PUENTE (EL RIO)

def rio(pose, time, rain_, solo, f):
    cv = Cv(f)
    night = time == "noche"
    env = ENV[(time, rain_)].but(L=(1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    sky(cv, time, rain_, 54)
    if night and not rain_:
        stars(cv, f, 30, 44, seed=3)
        cv.fill(cv.mask(lambda d: d.ell(196, 20, 6.5, 6.5)), (226, 226, 212))        # la luna
        cv.fill(cv.mask(lambda d: d.ell(199.5, 18.5, 6, 6)), SKY[(time, 0)][1])
    if not night and not rain_:
        cv.glow(150, 54, 40, (255, 226, 170), 0.6)
        cv.fill(cv.mask(lambda d: d.ell(150, 54, 13, 13)), (255, 238, 200))          # el sol
    # La ciudad, en la otra orilla.
    far = (30, 28, 58) if night else ((98, 76, 106) if not rain_ else (84, 88, 104))
    rng = np.random.default_rng(6)
    for bx, bw, bh in [(30, 12, 12), (44, 8, 22), (56, 16, 10), (80, 10, 16), (96, 14, 8), (116, 9, 13), (166, 16, 22), (188, 10, 12), (202, 12, 18)]:
        cv.fill(cv.box(bx, 54 - bh, bx + bw, 54), far)
        for wy in range(54 - bh + 3, 52, 4):
            wx = bx + 2 + int(rng.integers(0, max(1, bw - 3)))
            if night and (wx + wy + f) % 5 != 0:
                cv.px(wx, wy, (244, 204, 124))
                cv.px(wx, 55 + (54 - wy) // 3, (120, 104, 96))                       # y en el río
    river = {("noche", 0): [(26, 34, 68), (18, 24, 48)], ("noche", 1): [(20, 24, 42), (14, 16, 30)],
             ("alba", 0): [(126, 124, 154), (92, 94, 130)], ("alba", 1): [(98, 106, 124), (76, 84, 102)]}[(time, rain_)]
    cv.grad((0, 54, W, 68), river)
    cv.fill(cv.box(0, 54, W, 55), mix(river[0], (255, 255, 255), 0.18))
    shine = (176, 182, 200) if night else (255, 226, 176)
    sx = 197 if night else 150
    if not rain_:
        for y in range(56, 68, 2):                                                    # la luna (o el sol) en el agua, que corre
            for x in range(sx - 4 - (y - 54), sx + 5 + (y - 54), 3):
                if (x + y + f * 3) % 7 < 3:
                    cv.px(x, y, shine)
    ground(cv, 68, (132, 116, 112), env)
    ys, xs = np.mgrid[0:H, 0:W]
    fog = (ys >= 62) & (ys < 72) & (BAY[ys, (xs + f * 2) % W] < 0.16 + 0.1 * np.sin((xs + f * 9) / 17.0))
    cv.fill(fog, mix(river[0], (220, 224, 240), 0.38))                                # la neblina del río
    # El puente, encima: el arco y el estribo.
    e1 = ((xs - 124) / 132.0) ** 2 + ((ys - 66) / 54.0) ** 2
    e2 = ((xs - 124) / 139.0) ** 2 + ((ys - 66) / 60.0) ** 2
    arch = (e1 >= 1.0) & (ys < 62)
    cv.fill(arch, dk((100, 94, 106), 0.5))
    cv.fill(arch & (e2 < 1.0), dk((100, 94, 106), 0.95))
    cv.shape(cv.box(216, 22, W, H), (104, 98, 110), env.but(L=(-1, -1)), shade=0, half=False, emph=0.72)
    for xx, y0, y1 in ((222, 30, 70), (231, 26, 54)):                                  # lo que chorrea, de años
        cv.fill(cv.box(xx, y0, xx + 1, y1), dk((104, 98, 110), 0.5))
    tag1, tag2 = dk((236, 90, 150), 0.95), dk((90, 210, 220), 0.95)
    cv.post.append(lambda d: (d.line([(220, 58), (226, 50), (230, 60), (236, 50)], fill=tag1), d.line([(221, 66), (236, 64)], fill=tag2)))
    if rain_:
        outside = (e1 < 1.0) & (ys < 68)
        rain(cv, f, 150, RAIN_COL[time], m=outside)
        splashes(cv, f, 56, 68, 10, mix(RAIN_COL[time], (255, 255, 255), 0.3))
        wet = dk((90, 108, 150), 1.1)
        cv.fill(cv.mask(lambda d: d.ell(214 - f * 2, 95.5, 34 + f * 3, 2.6)), wet)     # el agua, que se mete por el piso
        for i, xx in enumerate((40, 98, 152, 204)):                                    # el puente, goteando
            top = int(66 - 54 * max(0.0, 1 - ((xx - 124) / 132.0) ** 2) ** 0.5) + 2
            gy = top + (f * 11 + i * 9) % max(4, 92 - top)
            cv.fill(cv.box(xx, gy, xx + 1, gy + 3), mix(RAIN_COL[time], (255, 255, 255), 0.4))
    if not night and not rain_:
        cv.cone((150, 52), (60, 99), (144, 99), (255, 212, 150), 0.6)
    # El cambuche: tres cartones, un plástico azul amarrado con cabuya, una piedra encima para que no se vuele.
    cv.shape(poly(cv, [(46, 91), (56, 56), (150, 52), (164, 91)]), CARTON, env, shade=1, emph=0.82)
    cv.shape(poly(cv, [(53, 58), (152 + (f % 2), 51), (150, 61), (57, 66)]), TARP, env, shade=1)
    inner = poly(cv, [(70, 91), (77, 68), (141, 66), (150, 91)])
    cv.fill(inner, dk((40, 34, 44), 0.42))
    cv.shape(cv.mask(lambda d: d.ell(104, 50.5, 5.5, 3.2)), (140, 138, 150), env, shade=1)
    rope = dk((190, 170, 130), 0.9)
    cv.post.append(lambda d: d.line([(151, 53), (174, 91)], fill=rope))
    cv.shape(poly(cv, [(66, 89), (176, 89), (181, 96), (60, 96)]), CARTON, env, shade=1)
    cv.shape(cv.mask(lambda d: d.cap(195, 86, 195, 89, 9)), (120, 122, 134), env, shade=1)   # la olla
    cv.shape(cv.mask(lambda d: d.cap(206, 88, 206, 82, 3.2)), (90, 150, 110), env, shade=1)

    def dormir(b, still):
        pts = man_side(Actor(cv, env, 130, 91), b, reach=still, still=still)
        cv.veil(inner & (xs < 116), dk((40, 34, 44), 0.42), 0.38)                       # la cabeza, adentro, en lo oscuro
        if not solo and not still:  # Lukas, encima de los pies
            lukas_curl(Actor(cv, env, 166, 95), b)
        return pts

    def despierta():
        pts = man_wake(Actor(cv, env, 112, 93), 0, reach=not solo)
        if not solo:
            lukas_sit(Actor(cv, env, 152, 94, flip=True), f % 2)
        return pts

    def golpeado():
        pts = man_sit(Actor(cv, env, 108, 94), 0, "golpeado")
        cv.shape(poly(cv, [(168, 80), (190, 76), (196, 93), (172, 96)]), CARTON, env, shade=1, emph=0.9)   # la caja, volteada
        cv.fill(poly(cv, [(171, 83), (187, 80), (190, 90), (174, 92)]), dk((40, 34, 40), 0.5))
        for lx, ly in ((158, 96), (201, 97), (150, 98)):
            cv.shape(cv.box(lx, ly - 3, lx + 4, ly), (170, 176, 188), env, shade=1, half=False)
        if not solo:
            lukas_sit(Actor(cv, env, 148, 95, flip=True), 0)
        return pts

    pts = cast(cv, env, pose, f, solo, {"dormir": dormir, "despierta": despierta, "golpeado": golpeado})
    if pose == "sueno":
        dream(cv, f, pts["head"])
    if pose == "final":
        collar_at(cv, pts["hand"], env)
        samuel(cv, env, 196, 95, flip=True)
        for bx, by in ((60, 30), (68, 26), (76, 32)):                                   # los pájaros, como todos los días
            cv.post.append(lambda d, bx=bx, by=by: d.line([(bx + f - 1, by - 1), (bx + f, by), (bx + f + 1, by - 1)], fill=(70, 54, 80)))
    return cv


# ---------------------------------------------------------------- EL CALLEJON (AL LADO DEL BILLAR)

def callejon(pose, time, rain_, solo, f):
    cv = Cv(f)
    night = time == "noche"
    base = ENV[(time, rain_)]
    pink = (255, 90, 170)
    env = base.but(amb=(0.3, 0.28, 0.44), key=(1.4, 0.6, 1.0) if not rain_ else (1.1, 0.5, 0.82), L=(1, -1)) if night else base.but(L=(1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    ys, xs = np.mgrid[0:H, 0:W]
    sky(cv, time, rain_, 34)
    # La boca del callejón: la calle, y la luz del billar.
    mouth = cv.box(138, 30, 164, 74)
    cv.fill(mouth, dk((120, 110, 134), 0.8))
    if night:
        cv.grad((138, 30, 164, 74), [mix(pink, (40, 20, 60), 0.55), mix(pink, (40, 20, 60), 0.3), mix(pink, (255, 255, 255), 0.1)], m=mouth)
    else:
        cv.grad((138, 30, 164, 74), [SKY[(time, rain_)][-2], SKY[(time, rain_)][-1], dk((150, 146, 150), 1.2)], m=mouth)
    cv.fill(cv.box(138, 69, 164, 74), dk((150, 146, 154), 1.0 if not night else 0.9))
    lw = poly(cv, [(0, 0), (34.5, 0), (138, 30), (138, 74), (0, 100)])
    rw = poly(cv, [(W, 0), (221, 0), (164, 30), (164, 74), (W, 100)])
    cv.fill(lw, dk(BRICK, 0.8))
    cv.fill(rw, dk((140, 92, 88), 0.72))
    seg_l = [[(0, i * 100 / 15.0), (138, 30 + i * 44 / 15.0)] for i in range(1, 15)]
    seg_r = [[(W, i * 100 / 15.0), (164, 30 + i * 44 / 15.0)] for i in range(1, 15)]
    lines(cv, seg_l, dk(BRICK, 0.55), lw)
    lines(cv, seg_r, dk((140, 92, 88), 0.5), rw)
    for i in range(22):                                                               # las juntas
        x = 6 + (i * 37) % 128
        row = (i * 5) % 14
        ya = (row * 100 / 15.0) * (1 - x / 138.0) + (30 + row * 44 / 15.0) * (x / 138.0)
        yb = ((row + 1) * 100 / 15.0) * (1 - x / 138.0) + (30 + (row + 1) * 44 / 15.0) * (x / 138.0)
        cv.fill(cv.box(x, ya + 1, x + 1, yb) & lw, dk(BRICK, 0.55))
    floor = poly(cv, [(138, 74), (164, 74), (W, 100), (0, 100)])
    cv.grad((0, 74, W, H), [dk((120, 114, 124), 0.95), dk((120, 114, 124), 0.7), dk((120, 114, 124), 0.5)], m=floor)
    if night:
        k = np.clip(1 - (138 - xs) / 70.0, 0, 1) * lw * 0.7 + np.clip(1 - (xs - 164) / 60.0, 0, 1) * rw * 0.7
        cv.light(k, pink, 0.5)
        kf = np.clip(1 - np.abs(xs - 151) / (10 + (ys - 74) * 1.6), 0, 1) * np.clip(1 - (ys - 74) / 30.0, 0, 1) * floor
        cv.light(kf * (1.0 if rain_ else 0.7), pink, 0.55)
        on = f != 2
        cv.fill(cv.box(166, 33, 172, 60), pink if on else mix(pink, (40, 20, 50), 0.6))   # el aviso: BILLAR (le falla una letra)
        for i in range(6):
            cv.px(168 + (i % 2), 36 + i * 4, (60, 20, 60))
        cv.glow(169, 46, 16, pink, 0.5 if on else 0.2)
        small_man(cv, 142, 74, 0.6, (20, 12, 30), rim=mix(pink, (255, 255, 255), 0.2), lean=-1)      # los que salen del billar
        small_man(cv, 150 + [0, 3, 6, 4][f], 74, 0.6, (20, 12, 30), rim=mix(pink, (255, 255, 255), 0.2), bottle=True)
    else:
        cv.fill(cv.box(166, 33, 172, 60), dk((150, 130, 150), 0.9))
        cv.post.append(lambda d: d.line([(148, 75), (153, 75)], fill=dk((120, 190, 130), 1.2)))      # una botella que quedó
    # El tubo de la canal.
    cv.shape(cv.box(203, 0, 207, 84), (104, 110, 120), env, shade=1, half=False)
    cv.shape(cv.box(198, 82, 207, 86), (104, 110, 120), env, shade=1, half=False)
    if rain_:
        wet = dk((96, 110, 150), 1.1)
        cv.fill(cv.mask(lambda d: d.ell(188, 93, 20, 3.2)) & floor, mix(wet, pink, 0.25) if night else wet)
        for i in range(3):
            cv.fill(cv.box(198, 86 + (f * 3 + i * 3) % 8, 200, 89 + (f * 3 + i * 3) % 8), mix(RAIN_COL[time], (255, 255, 255), 0.45))
    # El contenedor, las bolsas.
    cv.shape(cv.box(16, 52, 86, 93), (78, 124, 108), env, shade=3)
    cv.shape(poly(cv, [(12, 45), (90, 45), (86, 53), (16, 53)]), (64, 102, 90), env, shade=1)
    for xx in (40, 64):
        cv.fill(cv.box(xx, 55, xx + 1, 91), dk((78, 124, 108), 0.6))
    lines(cv, [[(24, 64), (56, 64)], [(24, 69), (46, 69)]], dk((30, 46, 42), 0.9))
    cv.fill(cv.box(18, 93, 84, 96), dk((20, 20, 26), 0.6))
    for bx, by, r in ((6, 92, 12), (224, 95, 13), (240, 90, 11)):
        cv.shape(cv.mask(lambda d, bx=bx, by=by, r=r: (d.ell(bx, by, r, r * 0.7), d.poly([(bx - 2, by - r * 0.6), (bx + 2, by - r * 0.6), (bx + 1, by - r * 0.6 - 5), (bx - 1, by - r * 0.6 - 5)]))),
                 (50, 50, 60), env, shade=2)
    if f in (0, 1):                                                                    # la rata: dos ojos, a ratos
        cv.post.append(lambda d: (d.point((30, 94), fill=(236, 70, 70)), d.point((33, 94), fill=(236, 70, 70))))
    for i, (gx, gy) in enumerate(((172, 92), (126, 97), (184, 86))):                   # vidrio roto
        if (i + f) % 3 == 0:
            cv.px(gx, gy, (236, 236, 250))
    cv.shape(poly(cv, [(86, 91), (142, 91), (146, 97), (82, 97)]), CARTON, env, shade=1, emph=0.9)

    def dormir(b, still):
        pts = man_sit(Actor(cv, env, 96, 94), b, "dormido")
        if not solo and not still:  # Lukas, con una oreja parada, mirando la boca del callejón
            lukas_down(Actor(cv, env, 160, 97), 0, "up", ear_up=True, eye=True)
        return pts

    def despierta():
        pts = man_sit(Actor(cv, env, 96, 94), 0, "alerta")
        if not solo:
            lukas_sit(Actor(cv, env, 150, 97, flip=True), f % 2)
        return pts

    def golpeado():
        pts = man_sit(Actor(cv, env, 96, 94), 0, "golpeado")
        clutter(cv, env, 176, 97, 3)
        if not solo:
            lukas_sit(Actor(cv, env, 146, 97, flip=True), 0)
        return pts

    pts = cast(cv, env, pose, f, solo, {"dormir": dormir, "despierta": despierta, "golpeado": golpeado})
    if rain_:
        rain(cv, f, 110, RAIN_COL[time], lit=(lambda x, y: mix(pink, (255, 255, 255), 0.3) if 130 < x < 176 and y < 80 else None) if night else None)
        splashes(cv, f, 78, 99, 12, mix(RAIN_COL[time], (255, 255, 255), 0.3), m=floor)
    if pose == "sueno":
        dream(cv, f, pts["head"])
    if pose == "final":
        collar_at(cv, pts["hand"], env)
        samuel(cv, env, 186, 98, flip=True)
    return cv


# ---------------------------------------------------------------- EL PARQUE

def parque(pose, time, rain_, solo, f):
    cv = Cv(f)
    night = time == "noche"
    env = ENV[(time, rain_)].but(L=(1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    ys, xs = np.mgrid[0:H, 0:W]
    sky(cv, time, rain_, 62)
    if night and not rain_:
        stars(cv, f, 40, 50, seed=5)
        cv.fill(cv.mask(lambda d: d.ell(208, 18, 6, 6)), (228, 228, 214))
        cv.glow(208, 18, 16, (200, 210, 240), 0.4)
    if not night and not rain_:
        cv.glow(226, 60, 44, (255, 226, 170), 0.6)
        cv.fill(cv.mask(lambda d: d.ell(226, 62, 11, 11)), (255, 238, 200))
    # Los árboles del fondo, un farol lejos.
    back = cv.mask(lambda d: [d.ell(x, 56 - (x * 7) % 8, 16, 11) for x in range(96, 260, 22)])
    cv.fill(back, dk((60, 92, 70), 0.62))
    if solo:  # desde aquí se ve el árbol de flores amarillas
        cv.fill(cv.mask(lambda d: (d.ell(188, 45, 13, 10), d.rect(187, 52, 190, 62))), dk((84, 124, 86), 1.0))
        rng = np.random.default_rng(9)
        for _ in range(16):
            cv.px(178 + int(rng.integers(0, 21)), 39 + int(rng.integers(0, 13)), (250, 214, 72) if night else (255, 226, 90))
    cv.fill(cv.box(150, 40, 151, 62), dk(IRON, 0.8))
    if night:
        cv.px(150, 39, (255, 236, 180))
        cv.glow(150, 40, 8, (255, 220, 150), 0.7)
    ground(cv, 62, (96, 132, 88), env)
    cv.fill(cv.mask(lambda d: d.ell(74, 93, 64, 8)) & (BAY < 0.6), dk((126, 110, 88), 0.82))     # la tierra pelada, bajo el árbol
    # Los columpios, que crujen solos.
    sway = [0, 1, 2, 1][f]
    cv.shape(cv.mask(lambda d: (d.cap(172, 28, 182, 90, 2.6), d.cap(228, 28, 217, 90, 2.6), d.cap(170, 27, 230, 27, 3))), (124, 124, 142), env, shade=1)
    chain = dk((150, 150, 166), 0.9)
    for i, sx in enumerate((187, 207)):
        o = sway if i == 0 else -sway
        cv.post.append(lambda d, sx=sx, o=o: (d.line([(sx, 29), (sx + o, 70)], fill=chain), d.line([(sx + 9, 29), (sx + 9 + o, 70)], fill=chain)))
        cv.shape(cv.box(sx - 1 + o, 70, sx + 11 + o, 73), (176, 84, 66), env, shade=1, half=False)
    # El árbol.
    trunk = poly(cv, [(30, 91), (37, 62), (35, 40), (49, 40), (51, 62), (60, 91)])
    cv.shape(trunk, (104, 78, 64), env, shade=3)
    leaves = cv.mask(lambda d: (d.ell(44, 22, 31, 20), d.ell(14, 33, 21, 15), d.ell(76, 30, 23, 16), d.ell(46, 6, 23, 12), d.ell(94, 41, 14, 9)))
    cv.shape(leaves, (68, 112, 74), env, shade=4)
    lv2 = cv.mask(lambda d: (d.ell(38, 28, 20, 9), d.ell(72, 36, 14, 6), d.ell(14, 40, 12, 5), d.ell(50, 12, 14, 5)))
    cv.veil(lv2 & leaves, dk((68, 112, 74), 0.62), 0.55)
    lv3 = cv.mask(lambda d: (d.ell(58, 12, 13, 5), d.ell(84, 24, 11, 5), d.ell(30, 16, 10, 4), d.ell(98, 38, 7, 3)))
    cv.veil(lv3 & leaves, col((68, 112, 74), env.amb + (env.key - env.amb) * 0.55), 0.5)
    canopy = (xs < 108) & (ys > 36)
    if rain_:
        rain(cv, f, 130, RAIN_COL[time], m=~canopy)
    for i in range(34):                                                                # el pasto, acostado por el viento
        gx, gy = (i * 53) % W, 66 + (i * 17) % 32
        cv.post.append(lambda d, gx=gx, gy=gy: d.line([(gx, gy), (gx + 1 + sway // 2, gy - 3)], fill=dk((120, 160, 104), 0.95)))

    def dormir(b, still):
        pts = man_back(Actor(cv, env, 136, 92), b, "side" if still else "eyes")
        if not solo and not still:  # Lukas, acurrucado contra las costillas
            lukas_curl(Actor(cv, env, 124, 96), b)
        return pts

    def despierta():
        pts = man_wake(Actor(cv, env, 110, 93), 0, reach=not solo)
        if not solo:
            lukas_sit(Actor(cv, env, 150, 94, flip=True), f % 2)
        return pts

    def golpeado():
        pts = man_sit(Actor(cv, env, 64, 93), 0, "golpeado")                           # contra el árbol
        clutter(cv, env, 132, 95, 4)
        if not solo:
            lukas_sit(Actor(cv, env, 108, 95, flip=True), 0)
        return pts

    pts = cast(cv, env, pose, f, solo, {"dormir": dormir, "despierta": despierta, "golpeado": golpeado})
    for i in range(4):                                                                 # hojas que pasan
        lx, ly = (30 + i * 60 + f * 22) % W, 52 + (i * 13 + f * 5) % 30
        cv.post.append(lambda d, lx=lx, ly=ly: d.point((lx, ly), fill=dk((200, 170, 80), 1.1)))
    if rain_:
        splashes(cv, f, 66, 99, 14, mix(RAIN_COL[time], (255, 255, 255), 0.3), m=~canopy)
        for i, xx in enumerate((22, 60, 86, 102)):                                     # el árbol, goteando
            gy = 50 + (f * 9 + i * 13) % 40
            cv.fill(cv.box(xx, gy, xx + 1, gy + 3), mix(RAIN_COL[time], (255, 255, 255), 0.45))
        if pose in ("dormir", "sueno"):                                                # la lluvia, encima de él
            for i in range(5):
                cv.px(112 + (i * 13 + f * 7) % 56, 78 - (i + f) % 2, mix(RAIN_COL[time], (255, 255, 255), 0.6))
    if not night and not rain_:
        for i, (bx, by) in enumerate(((128, 22), (136, 18), (144, 24))):
            cv.post.append(lambda d, bx=bx, by=by: d.line([(bx + f - 1, by - 1), (bx + f, by), (bx + f + 1, by - 1)], fill=(80, 60, 90)))
    if pose == "sueno":
        dream(cv, f, pts["head"])
    if pose == "final":
        collar_at(cv, pts["hand"], env)
        samuel(cv, env, 196, 95, flip=True)
    return cv


# ---------------------------------------------------------------- LA PENSION

def pension(pose, time, rain_, solo, f):
    cv = Cv(f)
    night = time == "noche"
    pink = (255, 90, 170)
    base = ENV[(time, rain_)]
    env = base.but(amb=(0.36, 0.34, 0.48), key=(1.32, 0.62, 0.98), L=(1, -1)) if night else base.but(L=(1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    wall = (156, 166, 146)
    cv.grad((0, 0, W, 72), [dk(wall, 0.7), dk(wall, 0.92), dk(wall, 1.1)], horizontal=True)
    ground(cv, 72, (136, 100, 78), env)
    for yy in (80, 90):
        cv.a[yy] = (cv.a[yy] * 0.84).astype(np.uint8)
    cv.fill(cv.box(0, 72, W, 74), dk((90, 70, 60), 0.8))
    # La pared: una mancha de humedad con forma de país, el claro de un cuadro que ya no está, una grieta.
    cv.veil(cv.mask(lambda d: (d.ell(40, 22, 17, 10), d.ell(56, 33, 14, 9), d.ell(30, 34, 8, 6))), dk(wall, 0.55), 0.6)
    cv.fill(cv.box(112, 22, 130, 42), dk(wall, 1.12))
    cv.px(121, 20, dk((30, 30, 30), 1.0))
    crack = dk(wall, 0.45)
    cv.post.append(lambda d: d.line([(140, 0), (144, 9), (141, 17), (145, 26)], fill=crack))
    # La puerta (con cadena).
    cv.shape(cv.box(8, 18, 36, 72), (124, 92, 70), env.but(L=(1, -1)), shade=1, half=False, emph=0.8)
    cv.px(32, 46, dk((230, 200, 110), 1.3))
    # La ventana: afuera, el aviso de neón (de noche) o el día.
    cv.shape(cv.box(176, 12, 230, 56), (128, 100, 84), env, shade=1, half=False)
    glass = cv.box(180, 16, 226, 52)
    if night:
        cv.fill(glass, (16, 16, 34))
        on = f != 2
        nc = pink if on else mix(pink, (30, 20, 50), 0.6)
        cv.post.append(lambda d: (d.rectangle([183, 21, 223, 32], outline=nc), d.text((184, 23), "HOTEL", font=FONT, fill=nc)))
        for wx, wy in ((188, 42), (198, 46), (214, 40)):
            cv.px(wx, wy, (220, 190, 120))
    else:
        cv.grad((180, 16, 226, 52), SKY[(time, rain_)][1:], m=glass)
        cv.fill(cv.box(196, 34, 226, 52) & glass, (104, 84, 112) if not rain_ else (88, 92, 108))
        cv.fill(cv.box(180, 40, 196, 52) & glass, (116, 92, 118) if not rain_ else (96, 100, 114))
    if rain_:
        for i in range(9):                                                             # el agua, en el vidrio
            gx, gy = 182 + (i * 5) % 42, 17 + (i * 11 + f * 6) % 32
            cv.fill(cv.box(gx, gy, gx + 1, gy + 3), (150, 160, 196) if night else (214, 220, 232))
    cv.shape(cv.box(202, 16, 204, 52), (128, 100, 84), env, flat=True)
    cv.shape(cv.box(180, 33, 226, 35), (128, 100, 84), env, flat=True)
    cv.shape(poly(cv, [(176, 12), (187, 12), (185, 44), (182, 50), (179, 44), (176, 54)]), (176, 156, 134), env, shade=1)   # media cortina
    wire = dk((30, 28, 30), 1.0)
    cv.post.append(lambda d: d.line([(100, 0), (100, 12)], fill=wire))
    cv.fill(cv.mask(lambda d: d.ell(100, 15.5, 3, 4)), dk((170, 168, 150), 0.9))       # el bombillo: no prende
    if night:
        cv.cone((203, 34), (40, 99), (238, 99), pink, 0.36, amount=0.42)
    else:
        cv.cone((203, 34), (70, 99), (206, 99), (255, 214, 150) if not rain_ else (190, 198, 214), 0.5)
    if rain_:  # hasta aquí llueve: una gotera, y un balde
        cv.shape(cv.mask(lambda d: d.poly([(40, 80), (54, 80), (52, 91), (42, 91)])), (110, 124, 150), env, shade=1)
        for i in range(2):
            gy = 2 + (f * 19 + i * 37) % 76
            cv.fill(cv.box(47, gy, 48, gy + 3), (170, 182, 214))
    # La cama: catre de hierro, colchón flaco, la cobija doblada a los pies (no la destiende).
    cv.shape(cv.box(60, 40, 63, 91), IRON, env, shade=0, half=False)
    cv.shape(cv.mask(lambda d: d.ell(61.5, 38.5, 2.6, 2.6)), IRON, env, shade=0)
    cv.shape(cv.box(174, 56, 177, 91), IRON, env, shade=0, half=False)
    cv.shape(cv.mask(lambda d: d.ell(175.5, 54.5, 2.6, 2.6)), IRON, env, shade=0)
    cv.fill(cv.box(64, 80, 174, 91), dk((20, 18, 26), 0.5))                            # debajo
    cv.shape(cv.box(63, 67, 175, 78), (214, 204, 184), env, shade=2, half=False)
    for xx in range(68, 174, 7):
        cv.fill(cv.box(xx, 71, xx + 1, 77), dk((120, 140, 190), 0.9))                  # el forro, de rayas
    cv.shape(cv.box(63, 78, 175, 81), IRON, env, shade=0, half=False, emph=0.8)
    cv.shape(cv.mask(lambda d: d.cap(74, 62.5, 90, 62.5, 9)), (232, 228, 214), env, shade=2)   # la almohada
    cv.shape(cv.box(148, 61, 172, 67), (182, 76, 76), env, shade=1)                    # la cobija
    cv.shape(cv.box(190, 70, 212, 91), (128, 90, 64), env, shade=1)                    # la mesa de noche
    cv.fill(cv.box(193, 78, 209, 79), dk((128, 90, 64), 0.5))
    cv.shape(cv.mask(lambda d: d.cap(197, 64, 205, 64, 11)), PACK, env)                # la mochila, donde la pueda ver

    def under_bed():
        if solo:
            return
        lukas_down(Actor(cv, env.but(amb=env.amb * 0.42, key=env.amb * 0.7), 110, 91, emph=1.0), 0, "down", eye=False)
        cv.fill(cv.box(63, 78, 175, 81), col(IRON, env.amb * 0.8))
        if f != 2:
            cv.post.append(lambda d: d.point((116, 85), fill=(255, 255, 255)))          # el ojo, abierto: no se admiten perros

    def dormir(b, still):
        under_bed() if not still else None
        return man_back(Actor(cv, env, 128, 67), b, "chest")                           # encima de la cama, con zapatos

    def despierta():
        pts = man_bench(Actor(cv, env, 126, 88), 0, awake=True)
        if not solo:
            lukas_sit(Actor(cv, env, 168, 93, flip=True), f % 2)
        return pts

    def golpeado():
        pts = man_sit(Actor(cv, env, 110, 93), 0, "golpeado")
        if not solo:
            lukas_sit(Actor(cv, env, 158, 94, flip=True), 0)
        return pts

    pts = cast(cv, env, pose, f, solo, {"dormir": dormir, "despierta": despierta, "golpeado": golpeado})
    if pose == "sueno":
        dream(cv, f, pts["head"])
    if pose == "final":
        collar_at(cv, pts["belly"], env)
        samuel(cv, env, 30, 93)
    return cv


# ---------------------------------------------------------------- EL LOTE DEL FONDO

def lote(pose, time, rain_, solo, f):
    cv = Cv(f)
    night = time == "noche"
    env = ENV[(time, rain_)].but(L=(-1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    ys, xs = np.mgrid[0:H, 0:W]
    sky(cv, time, rain_, 60)
    if night and not rain_:
        stars(cv, f, 70, 56, seed=7)
        cv.glow(58, 20, 18, (200, 210, 240), 0.45)
        cv.fill(cv.mask(lambda d: d.ell(58, 20, 6.5, 6.5)), (232, 232, 218))
        cv.px(56, 18, (200, 200, 190))
        cv.px(60, 22, (200, 200, 190))
    if not night and not rain_:
        cv.glow(56, 58, 46, (255, 226, 170), 0.6)
        cv.fill(cv.mask(lambda d: d.ell(56, 60, 12, 12)), (255, 238, 200))
    # La ciudad, lejos, chiquita. El río.
    far = (26, 26, 52) if night else ((104, 84, 112) if not rain_ else (86, 90, 106))
    rng = np.random.default_rng(11)
    x = 0
    while x < W:
        bw, bh = int(rng.integers(5, 12)), int(rng.integers(3, 11))
        cv.fill(cv.box(x, 58 - bh, x + bw, 58), far)
        if night and rng.random() < 0.6 and (x + f) % 4 != 0:
            cv.px(x + 2, 58 - bh + 2, (240, 200, 120))
        x += bw + int(rng.integers(0, 3))
    river = {("noche", 0): [(26, 34, 68), (18, 24, 48)], ("noche", 1): [(20, 24, 42), (14, 16, 30)],
             ("alba", 0): [(126, 124, 154), (92, 94, 130)], ("alba", 1): [(98, 106, 124), (76, 84, 102)]}[(time, rain_)]
    cv.grad((0, 58, W, 65), river)
    if not rain_:
        for y in range(59, 65, 2):
            for x in range(50 - (y - 58), 67 + (y - 58), 3):
                if (x + y + f * 3) % 7 < 3:
                    cv.px(x, y, (180, 186, 204) if night else (255, 226, 176))
    ground(cv, 65, (144, 122, 100), env)
    for i in range(30):                                                                # el pasto seco
        gx, gy = (i * 47) % W, 70 + (i * 19) % 28
        cv.post.append(lambda d, gx=gx, gy=gy: d.line([(gx, gy), (gx + 1, gy - 3)], fill=dk((190, 170, 110), 0.85)))
    for rx, ry, rr in ((14, 95, 4), (208, 96, 3), (232, 92, 5), (150, 97, 3)):
        cv.shape(cv.mask(lambda d, rx=rx, ry=ry, rr=rr: d.ell(rx, ry, rr, rr * 0.6)), (136, 132, 136), env, shade=1)
    # El palo seco, con una bolsa enredada.
    cv.shape(cv.mask(lambda d: (d.cap(30, 91, 34, 52, 6), d.path([(34, 54), (22, 36), (15, 24)], 2.6), d.path([(34, 52), (46, 32), (56, 24)], 2.6),
                                d.path([(22, 36), (27, 22)], 1.8), d.path([(46, 32), (41, 18)], 1.8), d.path([(40, 44), (50, 46)], 1.8))),
             (116, 98, 90), env, shade=1)
    bag = dk((230, 230, 236), 1.1)
    cv.post.append(lambda d: (d.point((56 + f % 2, 24), fill=bag), d.point((57 + f % 2, 25 + f % 2), fill=bag), d.point((58, 24), fill=bag)))
    # El carro quemado: sin llantas, sin vidrios, montado en ladrillos.
    car = cv.mask(lambda d: (d.cap(172, 80, 230, 80, 14), d.poly([(184, 74), (193, 59), (217, 59), (228, 74)])))
    win = cv.mask(lambda d: (d.poly([(192, 72), (196, 62), (204, 62), (204, 72)]), d.poly([(207, 72), (207, 62), (215, 62), (222, 72)])))
    arches = cv.mask(lambda d: (d.ell(184, 88, 7, 6), d.ell(218, 88, 7, 6)))
    cv.shape(car & ~win & ~arches, (130, 78, 58), env, shade=3)
    cv.veil(car & ~win & ~arches & (ys < 74), dk((40, 34, 36), 0.7), 0.5)                # el hollín
    cv.fill(arches & car, dk((20, 18, 22), 0.6))
    for bx in (180, 214):
        cv.shape(cv.box(bx, 88, bx + 9, 92), (156, 90, 70), env, shade=1, half=False)
    # El cambuche: un plástico del techo del carro a un palo, y un cartón de pared.
    wallm = poly(cv, [(98, 66), (173, 63), (173, 91), (98, 91)])
    cv.shape(wallm, CARTON, env, shade=0, half=False, emph=0.95)
    cv.veil(wallm & (ys < 73), dk(CARTON, 0.5), 0.6)                                     # la sombra del plástico
    for xx in (122, 148):
        cv.fill(cv.box(xx, 66, xx + 1, 91) & wallm, dk(CARTON, 0.62))                    # las junturas de los cartones
    sag = 4 if rain_ else 2
    cv.shape(poly(cv, [(192, 57), (195, 62), (144, 63 + sag), (97, 67), (93, 62), (144, 59 + sag)]), TARP, env, shade=1)
    cv.shape(poly(cv, [(93, 62), (98, 67), (91 + f % 2, 79), (86 + f % 2, 75)]), TARP, env, shade=1, emph=0.82)   # la punta, suelta
    cv.shape(cv.mask(lambda d: d.cap(97.5, 66, 98, 91, 2.4)), WOOD, env, shade=0)
    rope = dk((190, 170, 130), 0.9)
    cv.post.append(lambda d: d.line([(93, 63), (80, 92)], fill=rope))
    cv.shape(poly(cv, [(82, 89), (174, 89), (178, 96), (77, 96)]), CARTON, env, shade=1)
    # La fogata: de noche quedan dos brasas.
    for i in range(6):
        ang = i * 1.05
        cv.shape(cv.mask(lambda d, ang=ang: d.ell(58 + np.cos(ang) * 7, 94 + np.sin(ang) * 2.4, 2.4, 1.6)), (124, 120, 124), env, shade=1)
    if night and not rain_:
        cv.px(57 + f % 2, 94, (240, 110, 60))
        cv.px(60, 93 + f % 2, (200, 70, 50))
        cv.glow(58, 93, 7, (240, 110, 60), 0.4)
    covered = (xs > 97) & (xs < 192) & (ys > 62)
    if rain_:
        rain(cv, f, 140, RAIN_COL[time], m=~covered)

    def dormir(b, still):
        pts = man_side(Actor(cv, env, 131, 91, flip=True), b, reach=still, still=still)
        if not solo and not still:  # Lukas, contra la barriga
            lukas_curl(Actor(cv, env, 146, 97, flip=True), b)
        return pts

    def despierta():
        pts = man_wake(Actor(cv, env, 110, 95), 0, reach=not solo)
        if not solo:
            lukas_sit(Actor(cv, env, 150, 96, flip=True), f % 2)
        return pts

    def golpeado():
        pts = man_sit(Actor(cv, env, 108, 95), 0, "golpeado")
        clutter(cv, env, 60, 97, 6)
        if not solo:
            lukas_sit(Actor(cv, env, 148, 96, flip=True), 0)
        return pts

    pts = cast(cv, env, pose, f, solo, {"dormir": dormir, "despierta": despierta, "golpeado": golpeado})
    if rain_:
        splashes(cv, f, 68, 99, 16, mix(RAIN_COL[time], (255, 255, 255), 0.3), m=~covered)
        for i in range(4):                                                             # la lluvia, en el techo del carro
            cv.px(194 + (i * 7 + f * 5) % 22, 58 - (i + f) % 2, mix(RAIN_COL[time], (255, 255, 255), 0.6))
        wet = dk((96, 110, 150), 1.1)
        cv.fill(cv.mask(lambda d: d.ell(88, 96, 11 + f, 2.4)), wet)                     # el plástico, escurriendo
        for i in range(3):
            cv.fill(cv.box(88, 78 + (f * 5 + i * 5) % 15, 89, 81 + (f * 5 + i * 5) % 15), mix(RAIN_COL[time], (255, 255, 255), 0.5))
        if pose in ("dormir", "sueno"):                                                # y una gotera, encima de él
            cv.fill(cv.box(140, 70 + (f * 5) % 12, 141, 73 + (f * 5) % 12), mix(RAIN_COL[time], (255, 255, 255), 0.5))
    if pose == "sueno":
        dream(cv, f, pts["head"])
    if pose == "final":
        collar_at(cv, pts["hand"], env)
        samuel(cv, env, 62, 96)
    return cv


SPOTS = {"banco": banco, "kiosco": kiosco, "rio": rio, "callejon": callejon, "parque": parque, "pension": pension, "lote": lote}


# ---------------------------------------------------------------- LOS MOMENTOS

def intruso(solo, f):
    cv = Cv(f)
    env = Env((0.3, 0.31, 0.46), (1.5, 1.4, 1.1), (1, -1), half=0.4)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, H), [(6, 7, 16), (10, 11, 24), (16, 16, 32)])
    # El cambuche, a la derecha: adentro, lo oscuro.
    cv.shape(poly(cv, [(150, 100), (160, 28), (W, 22), (W, 100)]), CARTON, env, shade=1, emph=0.5)
    cv.fill(poly(cv, [(178, 100), (184, 46), (W, 42), (W, 100)]), (8, 8, 14))
    cv.fill(cv.mask(lambda d: d.ell(208, 64, 10, 10)), (15, 15, 26))                   # él, que ya se despertó
    # La caja.
    wob = [0, 1, 0, -1][f]
    beam(cv, (74, 74), (122 + wob * 2, 52), 20, (255, 244, 200), 0.85)
    cv.shape(cv.box(86, 58, 150, 97), CARTON, env, shade=3)
    cv.shape(poly(cv, [(86, 58), (70, 45), (96, 41), (106, 58)]), CARTON, env, shade=1, emph=1.15)
    cv.shape(poly(cv, [(150, 58), (162, 43), (136, 41), (128, 58)]), CARTON, env, shade=1, emph=0.9)
    cv.fill(poly(cv, [(90, 58), (146, 58), (140, 51), (96, 51)]), dk((40, 30, 30), 0.6))
    cv.shape(cv.box(128, 49, 140, 58), (190, 80, 76), env, shade=1)                    # la cobija
    cv.shape(cv.mask(lambda d: d.cap(112, 55, 112, 52, 5)), (176, 182, 194), env, shade=1)
    tape = dk((120, 96, 70), 0.9)
    cv.post.append(lambda d: d.line([(86, 76), (150, 76)], fill=tape))
    # El otro: flaco, agachado sobre la caja, con la mano adentro.
    thief = (46, 46, 62)
    cv.shape(cv.mask(lambda d: d.cap(28, 100, 50, 52, 27)), thief, env, shade=3, emph=0.62)
    cv.shape(cv.mask(lambda d: (d.ell(62, 40, 9.5, 10), d.poly([(60, 33), (80, 34.5), (78, 38.5), (62, 39)]))), (36, 36, 50), env, shade=2, emph=0.7)
    cv.shape(cv.mask(lambda d: d.path([(52, 60), (78, 63), (100 + wob, 55)], 7.5)), thief, env, shade=2, emph=0.7)
    cv.shape(cv.mask(lambda d: d.path([(46, 68), (64, 77)], 7)), thief, env, shade=2, emph=0.6)
    cv.shape(cv.box(64, 72, 76, 78), (150, 150, 160), env, shade=1)
    cv.fill(cv.box(76, 73, 78, 77), (255, 250, 220))
    # Adentro, dos ojos que ya se abrieron. Y abajo, otros dos.
    if f != 1:
        cv.post.append(lambda d: (d.rectangle([203, 62, 204, 63], fill=(244, 244, 244)), d.rectangle([210, 62, 211, 63], fill=(244, 244, 244))))
    if not solo and f in (0, 2, 3):
        cv.post.append(lambda d: (d.rectangle([193, 84, 194, 85], fill=(250, 206, 120)), d.rectangle([199, 84, 200, 85], fill=(250, 206, 120))))
    return cv


def lukas_pecho(still, f):
    cv = Cv(f)
    env = Env((0.5, 0.5, 0.56), (0.98, 1.0, 1.06), (1, -1), half=0.4) if still else Env((0.36, 0.38, 0.56), (0.9, 0.96, 1.3), (1, -1), half=0.32)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    b = 0 if still else breath(f)
    lb = 0 if still else (1 if f in (0, 2) else 0)                                      # Lukas respira más rápido que él
    cv.grad((0, 0, W, 78), [(40, 44, 58), (66, 70, 86), (96, 100, 114)] if still else [(8, 9, 22), (14, 15, 34), (24, 24, 50)], horizontal=True)
    cv.grad((0, 78, W, H), [dk((132, 116, 112), 0.9), dk((132, 116, 112), 0.6)])
    ys, xs = np.mgrid[0:H, 0:W]
    cv.fill((((xs - 160) / 170.0) ** 2 + ((ys - 80) / 66.0) ** 2 >= 1.0) & (ys < 78), (12, 11, 20) if not still else (24, 24, 34))
    cv.shape(poly(cv, [(6, 87), (232, 87), (238, 96), (0, 96)]), CARTON, env, shade=1)
    Actor(cv, env, 0, 0).part(PACK, lambda d: d.cap(14, 82, 40, 82, 14))             # la mochila, de almohada
    # Él, boca arriba (de cerca: el mismo cuerpo, a 3x).
    a = Actor(cv, env, 125, 87, scale=3.0)
    man_back(a, b, "chest")
    # Lukas, echado en el pecho, la cabeza en la clavícula de él. Nunca hacía eso.
    lk = Actor(cv, env, 84, 58 - b, flip=True, scale=2.4)
    lukas_down(lk, lb, "down", eye=False if still else "closed", tail_up=False)
    # La mano de él, encima del lomo.
    s = 3.0
    en, hn = (125 - 15.0 * s, 87 - 3.6 * s), (125 - 11.6 * s, 87 - (12.0 + b) * s - lb)
    a2 = Actor(cv, env, 0, 0)
    a2.part(COAT, lambda d: _limb(d, en, 2.1 * s, hn, 1.7 * s), shade=2)
    a2.part(SKIN, lambda d: d.ell(hn[0] + 1.0, hn[1] - 1.0, 1.7 * s, 1.4 * s), shade=1)
    return cv


def entierro(f):
    cv = Cv(f)
    env = Env((0.62, 0.58, 0.62), (1.24, 1.04, 0.86), (-1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 64), [(120, 128, 158), (172, 162, 170), (228, 192, 162), (248, 218, 178)])
    cv.fill(cv.mask(lambda d: [d.ell(x, 58 - (x * 5) % 7, 15, 10) for x in range(-6, 260, 20)]), dk((84, 120, 88), 0.8))
    cv.fill(cv.mask(lambda d: (d.rect(214, 34, 224, 60), d.poly([(212, 34), (219, 22), (226, 34)]))), dk((150, 140, 150), 0.82))   # San Judas, al fondo
    cross = dk((150, 140, 150), 0.6)
    cv.post.append(lambda d: (d.line([(219, 16), (219, 22)], fill=cross), d.line([(217, 18), (221, 18)], fill=cross)))
    ground(cv, 64, (108, 146, 94), env)
    # El árbol de flores amarillas.
    cv.shape(poly(cv, [(92, 90), (99, 58), (97, 36), (111, 36), (113, 58), (124, 90)]), (116, 86, 68), env, shade=3)
    blobs = [(104, 20, 31, 20), (74, 32, 21, 15), (137, 30, 23, 16), (106, 5, 21, 11)]
    leaves = cv.mask(lambda d: [d.ell(*bb) for bb in blobs])
    cv.shape(leaves, (88, 132, 88), env, shade=4)
    rng = np.random.default_rng(4)
    for cx, cy, rx, ry in blobs:
        for _ in range(46):
            ang, rr = rng.uniform(0, 6.283), rng.uniform(0, 1) ** 0.6
            fx, fy = int(cx + np.cos(ang) * rr * (rx - 2)), int(cy + np.sin(ang) * rr * (ry - 2))
            cv.px(fx, max(1, fy), (254, 220, 76))
            cv.px(fx + 1, max(1, fy), (236, 184, 54))
    for i in range(7):                                                                   # las flores que caen
        fx, fy = 66 + (i * 29) % 96, (28 + i * 17 + f * 9) % 92
        cv.post.append(lambda d, fx=fx, fy=fy, i=i: d.point((fx + (f + i) % 3, fy), fill=(254, 220, 76)))
    for i in range(14):
        cv.px(70 + (i * 23) % 90, 88 + (i * 7) % 10, (236, 200, 70))
    # La tierra removida, el clavel de doña Leonor, la pala.
    cv.shape(cv.mask(lambda d: (d.ell(152, 92, 24, 6), d.ell(152, 89, 17, 5))), (128, 96, 70), env, shade=2)
    stem, red = dk((60, 120, 66), 1.0), (224, 54, 64)
    cv.post.append(lambda d: (d.line([(152, 85), (152, 79)], fill=stem), d.ellipse([150, 75, 154, 79], fill=red)))
    cv.shape(cv.mask(lambda d: d.cap(180, 92, 186, 58, 2.4)), WOOD, env, shade=1)
    cv.shape(poly(cv, [(175, 94), (184, 94), (182, 84), (178, 84)]), (160, 164, 176), env, shade=1)
    # Los que vinieron: el Padre, Samuel con la gorra en la mano, doña Leonor. Y él.
    man_stand(Actor(cv, env, 24, 91), coat=(46, 44, 54), pants=(46, 44, 54), hair=(170, 168, 166), beard=None, tie=False)
    cv.post.append(lambda d: d.point((27, 91 - 44), fill=(240, 240, 240)))
    samuel(cv, env, 50, 93)
    leonor = Actor(cv, env, 74, 92)
    man_stand(leonor, coat=(136, 74, 110), pants=(96, 60, 84), hair=(236, 232, 226), beard=None, tie=False, bulk=1.1)
    leonor.part((136, 74, 110), lambda d: d.poly([(-5.4, -31.0), (5.8, -31.0), (7.4, -5.0), (-6.8, -5.0)]))   # la falda
    leonor.part((236, 158, 184), lambda d: d.poly([(-5.2, -47.6), (6.2, -47.6), (7.0, -40.4), (-6.0, -40.4)]), shade=1)   # el chal
    man_sit(Actor(cv, env, 204, 94, flip=True), 0, "alerta")
    return cv


def collar(f):
    cv = Cv(f)
    env = Env((0.52, 0.5, 0.56), (1.28, 1.06, 0.86), (1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, H), [(28, 26, 38), (42, 38, 50), (60, 52, 60)], horizontal=True)
    # La mochila, de cerca.
    cv.shape(poly(cv, [(34, 100), (44, 20), (150, 12), (168, 100)]), PACK, env, shade=4)
    cv.shape(poly(cv, [(44, 20), (150, 12), (156, 48), (50, 56)]), (116, 146, 100), env, shade=2)
    seam = dk(PACK, 0.6)
    stitch = dk(PACK, 1.4)
    cv.post.append(lambda d: (d.line([(50, 57), (156, 49)], fill=seam), [d.point((54 + i * 6, 53 - i * 0.45), fill=stitch) for i in range(17)]))
    cv.shape(cv.box(94, 44, 111, 61), (176, 176, 190), env, shade=1)
    cv.fill(cv.box(98, 48, 107, 57), dk(PACK, 0.7))
    cv.shape(poly(cv, [(150, 12), (178, 4), (196, 100), (168, 100)]), PACK, env, shade=2, emph=0.8)
    # El collar, amarrado a la correa: cuero gastado, la plaquita.
    ring = cv.mask(lambda d: d.ell(178, 56, 27, 23)) & ~cv.mask(lambda d: d.ell(178, 56, 21, 17))
    cv.shape(ring, (182, 110, 62), env, shade=2)
    cv.shape(cv.box(170, 29, 187, 40), (150, 88, 50), env, shade=1)
    cv.shape(cv.mask(lambda d: d.ell(178, 84, 8.5, 8.5)), (206, 208, 220), env, shade=1)
    cv.post.append(lambda d: d.text((175, 80), "L", font=FONT, fill=dk((80, 82, 96), 1.0)))
    if f in (1, 2):
        cv.post.append(lambda d: (d.point((172 + f * 4, 79), fill=(255, 255, 255)), d.point((173 + f * 4, 80), fill=(255, 255, 255))))
    # La mano de él, que no lo suelta.
    cv.shape(poly(cv, [(206, 100), (204, 72), (218, 60), (W, 64), (W, 100)]), COAT, env, shade=3)
    cv.shape(cv.mask(lambda d: d.ell(207, 70, 11, 8.5)), SKIN, env, shade=2)
    for i in range(4):
        cv.shape(cv.mask(lambda d, i=i: d.cap(198 + i * 4.6, 66 + i * 0.6, 195.5 + i * 4.6, 77 + i * 0.6, 4.2)), SKIN, env, shade=1)
    return cv


def antes(f):
    """DIA 0, 21:40: el edificio, la ventana del 302 prendida, y lo que viene llegando."""
    cv = Cv(f)
    env = ENV[("noche", 0)].but(L=(1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    sky(cv, "noche", 0, 60)
    stars(cv, f, 24, 30, seed=12)
    rng = np.random.default_rng(13)
    x = 0
    while x < W:                                                                          # la ciudad, atrás
        bw, bh = int(rng.integers(10, 22)), int(rng.integers(14, 40))
        cv.fill(cv.box(x, 70 - bh, x + bw, 88), (22, 22, 46))
        for _ in range(3):
            if rng.random() < 0.5:
                cv.px(x + int(rng.integers(2, bw - 1)), 70 - bh + int(rng.integers(3, bh)), (200, 170, 110))
        x += bw + 1
    # El helicóptero, y su luz barriendo.
    hx = 34 + [0, 4, 8, 4][f]
    cv.cone((hx + 2, 14), (hx + 30 + f * 6, 60), (hx + 60 + f * 6, 60), (255, 255, 230), 0.5, falloff=0.4)
    cv.fill(cv.mask(lambda d: (d.ell(hx, 11, 6, 3), d.rect(hx + 4, 10, hx + 15, 11.5), d.rect(hx - 8 + (f % 2) * 3, 6.6, hx + 8 - (f % 2) * 3, 7.6))), (14, 14, 26))
    cv.px(hx - 5, 12, (255, 60, 60) if f % 2 else (120, 30, 30))
    # El edificio.
    cv.shape(cv.box(70, 8, 172, 89), (160, 138, 128), env, shade=0, half=False, emph=0.8)
    cv.fill(cv.box(70, 8, 172, 10), dk((160, 138, 128), 1.05))
    red = f % 2 == 0
    for r_, yy in enumerate((16, 36, 56)):
        for c_, xx in enumerate((82, 112, 142)):
            w = cv.box(xx, yy, xx + 18, yy + 12)
            if (r_, c_) == (1, 1):                                                         # el 302: está haciendo arroz
                cv.fill(w, (246, 206, 120))
                cv.fill(cv.mask(lambda d: (d.ell(xx + 9, yy + 6, 3, 3.2), d.rect(xx + 4, yy + 9, xx + 14, yy + 12))), (60, 40, 40))
                cv.px(xx + 14, yy + 5 - f % 2, (255, 240, 200))
                cv.px(xx + 15, yy + 3 - f % 2, (255, 240, 200))
            elif (r_, c_) == (1, 0):                                                       # el vecino del 301, que siempre dijo
                cv.fill(w, (120, 150, 210) if f != 3 else (90, 120, 180))
                cv.fill(cv.mask(lambda d: (d.ell(xx + 15, yy + 6, 2.6, 2.8), d.rect(xx + 12, yy + 9, xx + 18, yy + 12))), (30, 34, 60))
            else:
                cv.fill(w, dk((70, 80, 110), 0.6))
            cv.fill(cv.box(xx + 8, yy, xx + 9, yy + 12), dk((160, 138, 128), 0.8))
    cv.fill(cv.box(112, 70, 130, 89), dk((90, 64, 52), 0.7))
    plate = dk((230, 200, 110), 1.2)
    cv.post.append(lambda d: d.point((127, 80), fill=plate))
    # La calle, las patrullas, los que ya se bajaron.
    cv.fill(cv.box(0, 88, W, 91), dk((150, 146, 150), 0.9))
    ground(cv, 91, (96, 94, 104), env)
    for cx, flip in ((28, False), (206, True)):
        cv.shape(cv.mask(lambda d: (d.cap(-14, -7, 14, -7, 8), d.poly([(-9, -10), (-5, -16), (7, -16), (11, -10)])), cx, 98, flip), (226, 228, 236), env, shade=1)
        cv.fill(cv.mask(lambda d: d.rect(-15, -8, 15, -6), cx, 98, flip), dk((60, 100, 200), 1.6))
        cv.fill(cv.mask(lambda d: (d.ell(-9, -3, 3, 3), d.ell(9, -3, 3, 3)), cx, 98, flip), (14, 14, 20))
        cv.fill(cv.box(cx - 3, 80, cx, 82), (255, 60, 60) if red else (110, 30, 30))
        cv.fill(cv.box(cx, 80, cx + 3, 82), (70, 110, 255) if not red else (30, 40, 110))
        cv.glow(cx, 80, 30, (255, 60, 60) if red else (70, 110, 255), 0.6)
    for i, sx in enumerate((60, 96, 150, 186)):
        small_man(cv, sx + (f if i % 2 else -f) % 2, 98, 0.5, (20, 24, 46), rim=(255, 90, 90) if red else (100, 130, 255))
    return cv


def moto(f):
    """ANTES: la Renegade, recién pagada. Él, sin barba."""
    cv = Cv(f)
    env = Env((0.66, 0.5, 0.52), (1.42, 1.02, 0.66), (-1, -1), half=0.5)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 66), [(86, 70, 124), (176, 104, 128), (240, 150, 110), (255, 204, 140), (255, 236, 190)])
    cv.glow(40, 62, 50, (255, 230, 170), 0.7)
    cv.fill(cv.mask(lambda d: d.ell(40, 64, 13, 13)), (255, 244, 208))
    cv.fill(cv.mask(lambda d: [d.ell(x, 60 - (x * 5) % 9, 16, 12) for x in range(80, 260, 24)]), dk((90, 80, 96), 0.8))
    for hx, hw, hh in ((150, 26, 22), (182, 34, 30), (222, 30, 18)):
        cv.shape(cv.box(hx, 66 - hh, hx + hw, 66), (170, 130, 120), env, shade=0, half=False, emph=0.7)
    cv.fill(cv.box(0, 66, W, 70), dk((170, 160, 160), 0.9))
    ground(cv, 70, (120, 108, 112), env)
    for xx in range(-10 + f * 5, W, 34):
        cv.fill(cv.box(xx, 84, xx + 16, 85), dk((250, 230, 150), 0.9))
    # La moto: café racer, negra mate, farola redonda, manubrio bajo.
    ground_shadow(cv, 118, 94, 40, 3, (40, 28, 40), 0.5)
    tire, metal, matte = (52, 50, 58), (170, 174, 186), (44, 44, 52)
    for wx in (92, 142):
        ring = cv.mask(lambda d: d.ell(wx, 84, 10, 10)) & ~cv.mask(lambda d: d.ell(wx, 84, 6.4, 6.4))
        cv.shape(ring, tire, env, shade=1)
        cv.shape(cv.mask(lambda d: d.ell(wx, 84, 2.2, 2.2)), metal, env, shade=0)
        spoke = dk(metal, 0.9)
        for ang in range(4):
            a2 = ang * 0.785
            cv.post.append(lambda d, wx=wx, a2=a2: d.line([(wx - np.cos(a2) * 6, 84 - np.sin(a2) * 6), (wx + np.cos(a2) * 6, 84 + np.sin(a2) * 6)], fill=spoke))
    cv.shape(cv.mask(lambda d: (d.path([(92, 84), (108, 70), (130, 70), (142, 84)], 2.6), d.path([(108, 70), (118, 84), (130, 70)], 2.4))), (60, 60, 70), env, shade=0)
    cv.shape(cv.mask(lambda d: d.rect(106, 73, 126, 85)), (130, 132, 144), env, shade=2)        # el motor
    cv.shape(cv.mask(lambda d: d.cap(104, 84, 80, 81, 3.2)), metal, env, shade=1)              # el exosto
    cv.shape(cv.mask(lambda d: d.ell(120, 65, 11.5, 5)), matte, env, shade=1)                 # el tanque
    cv.shape(cv.mask(lambda d: d.cap(98, 66.5, 110, 66, 4.4)), (120, 80, 56), env, shade=1)   # el sillín
    cv.shape(cv.mask(lambda d: d.path([(134, 70), (139, 60), (133, 58)], 2.2)), (60, 60, 70), env, shade=0)
    cv.shape(cv.mask(lambda d: d.path([(88, 72), (96, 68)], 2.4)), matte, env, shade=0)
    cv.fill(cv.mask(lambda d: d.ell(144.5, 65, 3.6, 3.6)), (255, 240, 180))
    cv.glow(146, 65, 8, (255, 236, 170), 0.6)
    # Él, de veintitantos, sin barba, con chaqueta. Una mano en el tanque.
    a = Actor(cv, env, 156, 93, flip=True)
    man_stand(a, coat=(50, 50, 62), pants=(64, 76, 110), beard=None, tie=False, near_arm=False)
    a.part((50, 50, 62), lambda d: (_limb(d, (1.0, -45.6), 2.4, (8.6, -39.4), 2.1), _limb(d, (8.6, -39.4), 2.1, (17.0, -33.4), 1.7)))
    a.part(SKIN, lambda d: d.ell(17.6, -33.2, 1.6, 1.4), shade=1)                     # la mano, en el manubrio
    for i, (bx, by) in enumerate(((60, 22), (70, 17), (80, 24))):
        cv.post.append(lambda d, bx=bx, by=by: d.line([(bx + f - 1, by - 1), (bx + f, by), (bx + f + 1, by - 1)], fill=(110, 70, 100)))
    return cv


def billar_card(f):
    """BILLAR EL GUAYABO: la puerta, y el que mide lo que mide la puerta."""
    cv = Cv(f)
    pink = (255, 90, 170)
    env = Env((0.3, 0.28, 0.44), (1.4, 0.62, 1.0), (1, -1), half=0.32)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    sky(cv, "noche", 0, 30)
    stars(cv, f, 10, 12, seed=15)
    # La bodega: chapa, óxido, una puerta por donde sale luz.
    cv.fill(cv.box(0, 10, W, 90), dk((132, 136, 148), 0.7))
    for xx in range(2, W, 5):
        cv.fill(cv.box(xx, 10, xx + 1, 90), dk((132, 136, 148), 0.5))
    rng = np.random.default_rng(16)
    for _ in range(60):
        rx, ry = int(rng.integers(0, W)), int(rng.integers(12, 88))
        cv.fill(cv.box(rx, ry, rx + 1, ry + int(rng.integers(2, 6))), dk((170, 96, 60), 0.7))
    cv.fill(cv.box(0, 10, W, 12), dk((132, 136, 148), 1.0))
    door = cv.box(100, 44, 140, 90)
    cv.grad((100, 44, 140, 90), [mix(pink, (60, 10, 50), 0.6), mix(pink, (60, 10, 50), 0.3), mix(pink, (255, 220, 200), 0.3)], m=door)
    cv.fill(cv.box(98, 42, 142, 44), dk((60, 50, 56), 0.9))
    cv.fill(cv.box(98, 42, 100, 90), dk((60, 50, 56), 0.9))
    cv.fill(cv.box(140, 42, 142, 90), dk((60, 50, 56), 0.9))
    # El aviso: le falla una letra.
    cv.fill(cv.box(92, 13, 150, 27), (20, 12, 26))
    cv.glow(121, 20, 40, pink, 0.55, squash=0.5)

    def sign(d):
        for i, ch in enumerate("BILLAR"):
            off = f in (2, 3) and i == 3
            d.text((98 + i * 8, 16), ch, font=FONT, fill=mix(pink, (40, 20, 50), 0.75) if off else pink)
    cv.post.append(sign)
    cv.fill(cv.box(0, 90, W, 92), dk((150, 146, 154), 0.9))
    ground(cv, 92, (104, 100, 112), env)
    cv.cone((120, 88), (70, 99), (176, 99), pink, 0.7, amount=0.5, falloff=0.2)
    # Adentro: dos que bailan, lejos.
    for i, sx in enumerate((112, 128)):
        small_man(cv, sx + [0, 1, 0, -1][(f + i * 2) % 4], 84, 0.4, (70, 20, 60))
    # El guardia: mide lo que mide la puerta. Un poco más.
    g = Actor(cv, env, 121, 95, scale=1.14)
    man_stand(g, coat=(34, 34, 44), pants=(30, 30, 40), hair=(120, 84, 66), beard=None, tie=False, bulk=1.4, near_arm=False)
    g.part((34, 34, 44), lambda d: (_limb(d, (1.0, -45.6), 3.2, (5.2, -38.0), 2.9), _limb(d, (5.2, -38.0), 2.9, (-3.4, -39.6), 2.4)))
    g.part(SKIN, lambda d: d.ell(-3.8, -39.8, 1.8, 1.6), shade=1)                     # los brazos, cruzados
    glasses = (10, 8, 14)
    cv.post.append(lambda d: d.line([g.at(0, -52), g.at(7, -52)], fill=glasses, width=2))
    # Él y Lukas, esperando a ver.
    man_stand(Actor(cv, env, 62, 96))
    lukas_sit(Actor(cv, env, 84, 97), f % 2)
    return cv


def desmayo(solo, f):
    """...: se cayó en la calle. La gente pasa. Alguien ya vio la mochila."""
    cv = Cv(f)
    env = Env((0.72, 0.7, 0.74), (1.2, 1.14, 1.02), (1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.fill(cv.box(0, 0, W, 56), dk((176, 150, 136), 0.8))                                      # una pared, de cerca
    for yy in range(6, 56, 7):
        cv.fill(cv.box(0, yy, W, yy + 1), dk((176, 150, 136), 0.62))
        for xx in range((yy * 5) % 18, W, 18):
            cv.fill(cv.box(xx, yy - 6, xx + 1, yy), dk((176, 150, 136), 0.62))
    cv.fill(cv.box(0, 56, W, 60), dk((120, 116, 124), 0.8))
    ground(cv, 60, (170, 166, 170), env, k=(1.0, 0.86, 0.7))
    for xx in range(12, W, 40):
        cv.fill(cv.box(xx, 60, xx + 1, H), dk((170, 166, 170), 0.66))
    cv.fill(cv.box(0, 78, W, 79), dk((170, 166, 170), 0.66))
    # Los que pasan: se les ven las piernas. Ninguno para.
    walkers = [(30, (60, 70, 110), (40, 36, 40), 3), (176, (150, 60, 70), (230, 220, 200), -4), (214, (80, 84, 90), (120, 80, 50), 2)]
    for wx, pants, shoe, sp in walkers:
        x = (wx + sp * f * 2) % (W + 20) - 10
        step = 3 if f % 2 == 0 else -3
        cv.shape(cv.mask(lambda d: d.cap(x - 3, 0, x - 3 - step, 70, 7)), pants, env, shade=1, emph=0.9)
        cv.shape(cv.mask(lambda d: d.cap(x - 6 - step, 72, x + 1 - step, 72, 4.5)), shoe, env, shade=1)
        cv.shape(cv.mask(lambda d: d.cap(x + 4, 0, x + 4 + step, 74, 7.4)), pants, env, shade=1)
        cv.shape(cv.mask(lambda d: d.cap(x + 1 + step, 76.5, x + 9 + step, 76.5, 4.8)), shoe, env, shade=1)
    # Él, en el piso. La mochila, a un lado. Una mano que no es de él.
    ground_shadow(cv, 110, 94, 46, 3, (60, 58, 70), 0.5)
    man_side(Actor(cv, env, 112, 93), 0, reach=True, still=True)
    cv.shape(cv.mask(lambda d: (d.cap(168, 88, 180, 88, 12), d.cap(170, 82, 178, 82, 5))), PACK, env)
    reach = [0, 2, 4, 2][f]
    cv.shape(cv.mask(lambda d: d.path([(W + 4, 70), (206 - reach, 78), (190 - reach, 83)], 6)), (70, 60, 90), env, shade=1)
    cv.shape(cv.mask(lambda d: d.ell(188 - reach, 84, 3, 2.6)), SKIN, env, shade=1)
    if not solo:  # Lukas, al lado, ladrándole a todo
        lukas_sit(Actor(cv, env, 62, 95), f % 2, up=False)
        if f % 2 == 0:
            bark = (60, 50, 60)
            cv.post.append(lambda d: (d.line([(76, 64), (80, 61)], fill=bark), d.line([(78, 68), (83, 67)], fill=bark), d.line([(76, 72), (80, 74)], fill=bark)))
    return cv


def fin(f):
    """FIN: la reja del colegio, el 29 de octubre."""
    cv = Cv(f)
    env = Env((0.74, 0.72, 0.7), (1.26, 1.18, 0.98), (1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 66), [(120, 170, 226), (160, 198, 236), (206, 226, 240)])
    cv.fill(cv.mask(lambda d: [d.ell(x, 60 - (x * 7) % 9, 15, 11) for x in range(-6, 110, 20)]), dk((104, 150, 104), 0.9))    # los árboles de la cuadra
    for hx, hw, hh, hc in ((0, 30, 22, (214, 150, 130)), (34, 26, 30, (170, 190, 214)), (64, 34, 20, (226, 214, 190))):
        cv.shape(cv.box(hx, 82 - hh, hx + hw, 82), hc, env, shade=0, half=False, emph=0.86)
        cv.fill(cv.box(hx + 6, 82 - hh + 6, hx + 14, 82 - hh + 14), dk((110, 130, 160), 0.8))
    for cx_, cy_ in ((40, 12), (150, 6)):
        cv.fill(cv.mask(lambda d: (d.ell(cx_ + f * 0.5, cy_, 14, 4), d.ell(cx_ + 8 + f * 0.5, cy_ - 3, 9, 4))), (246, 248, 252))
    # El colegio: amarillo, con dibujos pegados en las ventanas.
    cv.shape(cv.box(96, 14, W, 82), (240, 206, 110), env, shade=0, half=False, emph=0.92)
    cv.fill(cv.box(96, 14, W, 17), dk((200, 90, 70), 1.1))
    ink = dk((120, 60, 50), 0.9)
    cv.post.append(lambda d: d.text((150, 20), "COLEGIO", font=FONT, fill=ink))
    for wx in (110, 206):
        cv.fill(cv.box(wx, 36, wx + 24, 56), dk((150, 180, 210), 0.9))
        for i, c in enumerate(((236, 110, 110), (110, 190, 120), (250, 220, 110))):
            cv.fill(cv.box(wx + 3 + i * 7, 40 + (i % 2) * 5, wx + 8 + i * 7, 46 + (i % 2) * 5), c)
    cv.fill(cv.box(150, 40, 194, 82), dk((120, 150, 190), 0.75))                                 # el patio, por la reja
    ground(cv, 82, (176, 172, 172), env, k=(1.0, 0.9, 0.76))
    # Ella, adentro, con gorro de papel. Levanta la mano, chiquita.
    v = Actor(cv, env, 176, 82, scale=0.62)
    man_stand(v, coat=(246, 150, 180), pants=(246, 150, 180), hair=(96, 62, 46), beard=None, tie=False)
    v.part((96, 62, 46), lambda d: d.poly([(-6, -52), (-2, -52), (-3, -36), (-8, -36)]))           # el pelo largo
    v.part((250, 214, 90), lambda d: d.poly([(-3, -56), (4, -56), (0.5, -67)]), shade=0)           # el gorro
    up = [0, -2, -3, -2][f]
    v.part((246, 150, 180), lambda d: d.path([(3, -40), (9, -48 + up), (8, -56 + up)], 4.2))
    v.part(SKIN, lambda d: d.ell(8, -58 + up, 2.2, 2.2), shade=1)
    for i, sx in enumerate((160, 188)):
        small_man(cv, sx, 82, 0.32, dk((90, 80, 110), 1.0))
    # La reja. Y lo que dejó.
    bar = dk((70, 74, 90), 0.9)
    for xx in range(150, 196, 5):
        cv.fill(cv.box(xx, 38, xx + 1, 82), bar)
    cv.fill(cv.box(148, 38, 196, 40), bar)
    cv.fill(cv.box(148, 60, 196, 61), bar)
    cv.shape(cv.box(150, 74, 160, 82), (210, 70, 80), env, shade=1)                              # el regalo
    ribbon = (250, 226, 120)
    cv.post.append(lambda d: (d.line([(155, 74), (155, 81)], fill=ribbon), d.line([(150, 77), (159, 77)], fill=ribbon)))
    for i, (bx, by, c) in enumerate(((132, 34, (236, 90, 110)), (140, 30, (110, 170, 236)))):
        cv.post.append(lambda d, bx=bx, by=by, c=c: (d.ellipse([bx - 3, by - 4 - f % 2, bx + 3, by + 3 - f % 2], fill=c), d.line([(bx, by + 3 - f % 2), (bx - 1, by + 14)], fill=(90, 90, 100))))
    # Él, de este lado. El collar, amarrado a la mochila.
    a = Actor(cv, env, 60, 96, scale=1.12)
    a.part(PACK, lambda d: d.cap(-8, -38, -8, -28, 9))
    man_stand(a)
    leather = col((176, 106, 60), env.key)
    cv.post.append(lambda d: d.ellipse([47, 62, 53, 68], outline=leather))
    return cv


MOMENTOS = [lambda f: intruso(False, f), lambda f: intruso(True, f), lambda f: lukas_pecho(False, f),
            lambda f: lukas_pecho(True, f), entierro, collar,
            antes, moto, billar_card, lambda f: desmayo(False, f), lambda f: desmayo(True, f), fin,
            lambda f: atardecer(False, False, f), lambda f: atardecer(True, False, f), lambda f: atardecer(False, True, f),
            lambda f: espejo(False, f), lambda f: espejo(True, f)]


# ---------------------------------------------------------------- Mirar desde el puente; el espejo de Lisandro

def _man_back_seated(cv, env, x, y, coat=COAT):
    """Él, sentado de espaldas (mirando lo que mira): la espalda del saco que le queda grande, los brazos
    a los lados, la nuca, las orejas y el pelo despeinado. Origen: el piso, en la mitad."""
    a = Actor(cv, env, x, y)
    a.part(coat, lambda d: (_limb(d, (-6.6, -26.4), 2.5, (-7.4, -15.0), 2.2), _limb(d, (-7.4, -15.0), 2.2, (-5.6, -6.0), 1.8),
                            _limb(d, (6.6, -26.4), 2.5, (7.4, -15.0), 2.2), _limb(d, (7.4, -15.0), 2.2, (5.6, -6.0), 1.8)),
           emph=a.emph * 0.9)                                                         # los brazos, a los lados
    a.part(coat, lambda d: (d.poly([(-6.8, -27.4), (6.8, -27.4), (5.6, -12.0), (6.8, -2.0), (6.4, -0.4), (-6.4, -0.4),
                                    (-6.8, -2.0), (-5.6, -12.0)]), d.ell(-5.2, -26.2, 2.8, 2.6), d.ell(5.2, -26.2, 2.8, 2.6)), shade=3)
    a.line([(0, -26.6), (0, -9.0)], col(coat, env.amb * 0.55))                       # la costura de la espalda
    a.line([(-4.6, -20.0), (-3.4, -14.0)], col(coat, env.amb * 0.6))                 # un pliegue
    a.part(SKIN, lambda d: d.rect(-1.6, -30.4, 1.6, -27.4), shade=0)                  # la nuca
    a.part(coat, lambda d: d.rect(-3.2, -28.6, 3.2, -27.0), shade=0)                 # el cuello del saco
    a.part(SKIN, lambda d: (d.ell(-3.6, -32.8, 1.0, 1.6), d.ell(3.6, -32.8, 1.0, 1.6)), shade=0, rim=False)   # las orejas
    a.part(HAIR, lambda d: (d.ell(0, -34.0, 3.6, 4.2), d.ell(-2.2, -37.4, 1.6, 1.3), d.ell(2.0, -37.8, 1.5, 1.2),
                            d.ell(-3.2, -31.6, 1.0, 1.4), d.ell(3.0, -31.4, 1.0, 1.4)), shade=2)
    return a


def _lukas_back_seated(cv, env, x, y):
    """Lukas, sentado de espaldas: el anca ancha abajo, la montura negra, la cabeza con las dos orejas
    largas colgando, la cola en el piso con la punta blanca."""
    a = Actor(cv, env, x, y)
    a.part(TAN, lambda d: (_limb(d, (5.0, -1.4), 1.4, (9.6, -2.0), 1.1), _limb(d, (9.6, -2.0), 1.1, (12.4, -3.0), 0.9)), shade=1)
    a.dot(12.8, -3.4, a.lit(WHITE, 0.6))                                           # la cola, en el piso
    a.part(TAN, lambda d: (d.ell(0, -4.6, 5.8, 4.6), _limb(d, (0, -5.0), 4.6, (0, -12.4), 3.4)), shade=2)
    a.part(BLACK, lambda d: _limb(d, (0, -6.4), 3.0, (0, -12.0), 2.4), shade=1)       # la montura
    a.part(TAN, lambda d: (d.ell(0, -15.6, 3.4, 3.2), d.ell(0, -17.6, 2.6, 2.0)), shade=2)   # la cabeza (de atrás)
    a.part(EAR, lambda d: (d.ell(-3.4, -14.0, 1.4, 3.4), d.ell(3.4, -14.0, 1.4, 3.4)), shade=1)
    a.part(WHITE, lambda d: d.rect(-0.5, -18.6, 0.5, -15.2), shade=0, rim=False)     # la franja, entre las orejas
    return a


def atardecer(solo, day, f):
    """Lo que mira desde el puente: el río, los cerros, el sol que se mete. Y los dos, de espaldas."""
    cv = Cv(f)
    if day:
        env = Env((0.78, 0.8, 0.86), (1.2, 1.15, 1.05), (1, -1), half=0.4)
        cv.grad((0, 0, W, 58), [(110, 160, 220), (150, 190, 230), (196, 220, 236)])
        hills, hills2 = (96, 140, 104), (70, 110, 86)
    else:
        env = Env((0.5, 0.36, 0.46), (1.45, 0.96, 0.62), (-1, -1), half=0.5)
        cv.grad((0, 0, W, 58), [(70, 58, 112), (150, 90, 130), (236, 136, 104), (252, 190, 120), (255, 226, 170)])
        hills, hills2 = (90, 62, 96), (66, 46, 76)
    sun_y = 46 + f * 2 if not day else 14
    if not day:
        cv.glow(150, sun_y, 46, (255, 222, 160), 0.7)
    cv.fill(cv.mask(lambda d: d.ell(150, sun_y, 11, 11)), (255, 240, 200) if not day else (255, 250, 230))
    cv.fill(cv.mask(lambda d: [d.ell(x, 58 - (x * 7) % 11, 28, 14) for x in range(-10, 270, 34)]), hills)   # los cerros
    cv.fill(cv.mask(lambda d: [d.ell(x + 16, 62 - (x * 5) % 7, 24, 9) for x in range(-10, 270, 30)]), hills2)
    for bx, bw, bh in [(30, 8, 8), (40, 6, 12), (48, 10, 6), (176, 8, 10), (186, 12, 14), (200, 6, 8)]:
        cv.fill(cv.box(bx, 62 - bh, bx + bw, 62), mix(hills2, (40, 30, 50), 0.4))
    cv.grad((0, 62, W, 82), [(150, 104, 130), (120, 84, 120), (90, 66, 104)] if not day else [(110, 150, 196), (90, 130, 180), (74, 110, 160)])
    shine = (255, 214, 160) if not day else (240, 248, 255)
    for yy in range(63, 82, 2):                                                       # el sol en el agua
        for xx in range(150 - (yy - 60) * 2, 151 + (yy - 60) * 2, 3):
            if (xx + yy + f * 3) % 7 < 3:
                cv.px(xx, yy, shine)
    for i, (bx, by) in enumerate(((96, 30), (104, 26), (112, 32))):                   # los pájaros
        cv.post.append(lambda d, bx=bx, by=by: d.line([(bx + f * 2 - 1, by - 1), (bx + f * 2, by), (bx + f * 2 + 1, by - 1)], fill=(60, 40, 70)))
    # La baranda del puente, y el borde donde se sientan.
    cv.shape(cv.box(0, 82, W, 86), (150, 146, 156), env, shade=0, half=False)
    cv.shape(cv.box(0, 86, W, H), (120, 116, 126), env, shade=0, half=False, emph=0.7)
    for xx in range(4, W, 22):
        cv.shape(cv.box(xx, 66, xx + 3, 82), (150, 146, 156), env, shade=0, half=False, emph=0.85)
    cv.shape(cv.box(0, 64, W, 67), (160, 156, 166), env, shade=0, half=False, emph=0.9)
    _man_back_seated(cv, env, 112, 95)
    if not solo:
        _lukas_back_seated(cv, env, 136, 95)
    return cv


def espejo(cap3, f):
    """Antes de cada sueño de PLOMO: Lisandro, en el espejo del baño. Esta noche, él es Lisandro."""
    cv = Cv(f)
    on = f != 2
    env = Env((0.62, 0.62, 0.58), (1.25, 1.2, 1.05), (1, -1), half=0.4) if on else Env((0.4, 0.4, 0.4), (0.8, 0.8, 0.8), (1, -1))
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    ys, xs = np.mgrid[0:H, 0:W]
    cv.fill(np.ones((H, W), bool), dk((200, 214, 196), 0.95))                          # las baldosas
    cv.fill(((xs % 10 == 0) | (ys % 10 == 0)), dk((200, 214, 196), 0.7))
    # El espejo, con su grieta; adentro, la cara.
    cv.shape(cv.box(94, 8, 172, 82), (170, 150, 110), env, shade=1, half=False)
    cv.fill(cv.box(98, 12, 168, 78), dk((150, 170, 180), 0.8))
    face = Image.open("assets/portraits/lisandro.png").convert("RGBA").crop((10, 4, 86, 84))
    arr = np.asarray(face).astype(float)
    tint = np.array(env.amb) * (1.05 if on else 0.8)
    for yy in range(arr.shape[0]):
        for xx in range(arr.shape[1]):
            if arr[yy, xx, 3] > 128 and 12 + yy < 78 and 96 + xx < 168:
                c = arr[yy, xx, :3] * tint
                if cap3 and 30 < xx < 60 and 30 < yy < 52 and arr[yy, xx, 0] > 200 and arr[yy, xx, 1] > 200:
                    c = np.array([230, 120, 120]) * tint                              # los ojos, rojos
                cv.a[12 + yy, 96 + xx] = np.clip(c, 0, 255).astype(np.uint8)
    cv.post.append(lambda d: (d.line([(150, 12), (140, 34), (148, 46)], fill=(230, 240, 244)), d.line([(140, 34), (128, 40)], fill=(230, 240, 244))))
    for k in range(3):
        cv.post.append(lambda d, k=k: d.line([(104 + k * 6, 16), (100 + k * 6, 24)], fill=(236, 244, 248)))
    # El bombillo, que titila.
    cv.fill(cv.mask(lambda d: d.ell(133, 3, 4, 3)), (255, 244, 200) if on else (110, 110, 100))
    if on:
        cv.glow(133, 4, 40, (255, 240, 200), 0.5)
    # El lavamanos, la llave que gotea, y (en el capítulo 3) la bolsita.
    cv.shape(cv.mask(lambda d: (d.rect(84, 84, 182, 92), d.ell(133, 92, 44, 8))), (232, 232, 236), env, shade=2)
    cv.shape(cv.mask(lambda d: d.path([(140, 84), (140, 79), (134, 79)], 3)), (180, 184, 196), env, shade=0)
    cv.px(134, 82 + f % 3, (190, 220, 250))
    if cap3:
        cv.shape(cv.mask(lambda d: d.poly([(160, 84), (172, 84), (170, 76), (162, 76)])), (240, 240, 244), env, shade=1)
        cv.post.append(lambda d: d.line([(161, 78), (171, 78)], fill=(220, 60, 60)))
    # Él (Lisandro), de espaldas: el saco blanco, la nuca, las manos en el lavamanos.
    a = Actor(cv, env, 52, 108)
    a.part((236, 234, 226), lambda d: (d.cap(-14, -10, 14, -10, 34), d.ell(0, -30, 26, 12)), shade=3)
    a.part((24, 22, 26), lambda d: d.ell(0, -48, 13, 12), shade=2)
    a.part((236, 234, 226), lambda d: d.path([(18, -32), (34, -26), (48, -22)], 8), shade=2)
    a.part(SKIN, lambda d: d.ell(51, -22, 4, 3), shade=1)
    return cv


# ---------------------------------------------------------------- EL PROLOGO, con la misma calidad

def _woman(cv, env, x, y, coat, hair, flip=False, skirt=None, scale=1.0, hold=None, near_arm=True):
    """Una mujer de pie (Diana Carolina, Lorena): pelo largo, vestido. Origen: los pies."""
    a = Actor(cv, env, x, y, flip, scale=scale)
    a.part(hair, lambda d: (d.ell(0.0, -53.6, 4.6, 4.8), d.poly([(-4.8, -53.4), (3.4, -53.4), (3.8, -42.6), (-5.2, -42.6)])),
           shade=2)                                                                    # el pelo largo, por la espalda
    man_stand(a, coat=coat, pants=skirt or coat, hair=hair, beard=None, tie=False, bulk=0.9,
              near_arm=not (hold or not near_arm))
    a.part(skirt or coat, lambda d: d.poly([(-4.8, -31.0), (5.2, -31.0), (6.8, -12.0), (-6.4, -12.0)]))   # la falda
    if hold:
        a.part(coat, lambda d: (_limb(d, (1.0, -45.6), 2.2, (6.6, -38.6), 1.9), _limb(d, (6.6, -38.6), 1.9, (9.8, -41.8), 1.6)))
        a.part(SKIN, lambda d: d.ell(10.0, -42.0, 1.5, 1.3), shade=1)
        a.part(hold, lambda d: d.rect(9.0, -47.4, 13.4, -40.8), shade=0)
    return a


def _man_run(cv, env, x, y, flip=False, clean=False):
    """Corriendo: el cuerpo para adelante, las piernas abiertas. Origen: el piso."""
    a = Actor(cv, env, x, y, flip)
    a.clean = clean
    a.part(PACK, lambda d: d.cap(-1.6, -43.0, -3.4, -32.0, 8.0))                    # la mochila, rebotando
    J = {"head": (8.6, -49.6), "neck": (6.4, -45.2), "hip": (0.0, -27.6),
         "sn": (6.2, -42.4), "sf": (4.2, -42.8), "en": (11.6, -34.4), "ef": (-1.4, -35.0),
         "hn": (17.0, -38.4), "hf": (-4.0, -28.4), "kn": (8.6, -18.6), "kf": (-6.4, -17.4),
         "an": (6.4, -4.4), "af": (-13.4, -10.4), "tn": (11.8, -2.4), "tf": (-17.4, -6.8)}
    figure(a, J, (0.85, 0.2), hem=(-2.0, -21.0))
    return a


def _night_env():
    return ENV[("noche", 0)].but(L=(1, -1))


def p_apartamento(f):
    """ANTES. Un apartamento con todo pago: la nevera, el sofá, la moto. Él, sin barba. Lukas, con cama propia y dos cobijas."""
    cv = Cv(f)
    env = Env((0.62, 0.52, 0.5), (1.3, 1.08, 0.8), (1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 76), [dk((214, 196, 170), 1.05), dk((214, 196, 170), 0.9)], horizontal=True)
    ground(cv, 76, (170, 120, 84), env)
    for xx in range(0, W, 16):
        cv.fill(cv.box(xx, 76, xx + 1, H), dk((170, 120, 84), 0.75))
    cv.shape(cv.box(160, 14, 214, 52), (110, 90, 70), env, shade=1, half=False)       # la ventana, de noche
    cv.grad((164, 18, 210, 48), [(20, 22, 50), (36, 34, 70)])
    for wx, wy in ((170, 40), (180, 34), (196, 42), (204, 30)):
        cv.px(wx, wy, (240, 210, 120))
    cv.fill(cv.box(186, 18, 188, 48), dk((110, 90, 70), 1.0))
    cv.shape(cv.box(10, 34, 34, 84), (232, 232, 236), env, shade=2)                   # la nevera, con imanes
    cv.fill(cv.box(10, 52, 34, 53), dk((232, 232, 236), 0.6))
    for k, c in enumerate(((230, 80, 80), (90, 180, 230), (250, 210, 90))):
        cv.fill(cv.box(14 + k * 6, 40, 18 + k * 6, 44), c)
    cv.shape(cv.mask(lambda d: (d.rect(40, 62, 96, 82), d.rect(40, 52, 96, 64), d.rect(36, 58, 42, 84), d.rect(94, 58, 100, 84))), (120, 76, 110), env, shade=2)   # el sofá
    for wx in (128, 166):                                                              # la moto, en la sala (es lo que se hace)
        ring = cv.mask(lambda d: d.ell(wx, 86, 9, 9)) & ~cv.mask(lambda d: d.ell(wx, 86, 6, 6))
        cv.shape(ring, (50, 50, 58), env, shade=1)
    cv.shape(cv.mask(lambda d: (d.path([(128, 86), (140, 72), (156, 72), (166, 86)], 2.6), d.rect(140, 74, 156, 86))), (60, 60, 70), env, shade=0)
    cv.shape(cv.mask(lambda d: d.ell(150, 66, 10, 4.5)), (44, 44, 52), env, shade=1)
    cv.shape(cv.box(196, 86, 232, 96), (150, 110, 70), env, shade=1, half=False)      # la cama de Lukas, dos cobijas
    cv.fill(cv.box(198, 83, 230, 86), (200, 70, 70))
    cv.fill(cv.box(200, 80, 228, 83), (70, 110, 200))
    lukas_curl(Actor(cv, env, 214, 84), breath(f))
    a = Actor(cv, env, 112, 92)
    a.clean = True
    man_stand(a, beard=None)                                                           # él, sin barba
    cv.fill(cv.mask(lambda d: (d.rect(92, 0, 94, 12), d.ell(93, 15, 5, 3))), dk((250, 220, 150), 1.4))   # la lámpara
    cv.glow(93, 16, 40, (255, 220, 160), 0.4)
    return cv


def p_estacion(f):
    """A las cuatro, Diana Carolina entró a una estación. Salió a las cinco y media, con copia."""
    cv = Cv(f)
    env = Env((0.64, 0.56, 0.6), (1.34, 1.06, 0.8), (-1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 60), [(120, 130, 180), (220, 170, 150), (250, 210, 160)])
    cv.shape(cv.box(30, 18, 200, 88), (190, 190, 176), env, shade=0, half=False)
    cv.fill(cv.box(30, 18, 200, 22), dk((60, 90, 160), 1.2))
    cv.shape(cv.box(84, 26, 146, 38), (40, 70, 150), env, shade=0, half=False)
    cv.post.append(lambda d: d.text((88, 28), "POLICIA", font=FONT, fill=(236, 240, 250)))
    for wx in (40, 64, 160, 184):
        cv.fill(cv.box(wx, 46, wx + 12, 62), dk((90, 110, 140), 0.8))
        cv.fill(cv.box(wx, 52, wx + 12, 53), dk((40, 40, 50), 1.0))
    cv.fill(cv.box(104, 52, 126, 88), dk((70, 60, 60), 0.6))
    cv.fill(cv.box(0, 88, W, 92), dk((170, 166, 160), 1.0))
    ground(cv, 92, (130, 126, 130), env)
    cv.post.append(lambda d: (d.ellipse([206, 6, 230, 30], outline=(60, 50, 60)), d.line([(218, 18), (218, 10)], fill=(60, 50, 60)), d.line([(218, 18), (224, 22)], fill=(60, 50, 60)),
                              d.text((200, 34), "17:30", font=FONT, fill=(60, 40, 50))))
    _woman(cv, env, 150 + f, 96, (60, 180, 180), (30, 26, 30), hold=(250, 250, 240))   # ella, con la copia
    small_man(cv, 92, 88, 0.55, dk((60, 80, 70), 1.0))                                  # un agente, en la puerta
    return cv


def p_denuncia(f):
    """La denuncia: aborto, que él la obligó; armado y peligroso."""
    cv = Cv(f)
    env = Env((0.6, 0.56, 0.5), (1.3, 1.1, 0.8), (1, -1), half=0.4)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, H), [dk((130, 90, 60), 1.0), dk((130, 90, 60), 0.75)], horizontal=True)   # el escritorio
    for yy in range(4, H, 9):
        cv.fill(cv.box(0, yy, W, yy + 1), dk((130, 90, 60), 0.6))
    paper = cv.mask(lambda d: d.poly([(60, 6), (176, 4), (182, 98), (64, 99)]))
    cv.shape(paper, (240, 236, 222), env, shade=2)
    ink = (40, 34, 40)
    def text(d):
        d.text((92, 12), "DENUNCIA", font=FONT, fill=ink)
        d.line([(74, 24), (170, 23)], fill=(150, 150, 160))
        d.text((74, 30), "ABORTO", font=FONT, fill=ink)
        for k in range(4):
            d.line([(74, 44 + k * 6), (170 - (k % 2) * 20, 44 + k * 6)], fill=(150, 150, 160))
    cv.post.append(text)
    stamp = (210, 50, 50)
    cv.post.append(lambda d: (d.rectangle([80, 72, 166, 92], outline=stamp), d.text((90, 74), "ARMADO Y", font=FONT, fill=stamp), d.text((86, 83), "PELIGROSO", font=FONT, fill=stamp)))
    cv.shape(cv.mask(lambda d: d.cap(196, 20, 222, 80, 3.4)), (40, 60, 140), env, shade=1)   # el esfero
    cv.shape(cv.mask(lambda d: d.ell(212, 92, 14, 6)), (200, 150, 110), env, shade=1)        # el tinto de la oficina
    return cv


def p_lorena(f):
    """Lorena confirmó la dirección por teléfono. Mandó una foto. Agregó lo del arma, de su cosecha."""
    cv = Cv(f)
    env = Env((0.6, 0.5, 0.6), (1.35, 0.9, 1.05), (1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, H), [dk((230, 170, 200), 1.0), dk((230, 170, 200), 0.75)], horizontal=True)   # un cuarto rosado
    cv.shape(cv.box(0, 74, W, H), (210, 140, 170), env, shade=0, half=False)          # la cama
    for k in range(6):
        cv.fill(cv.mask(lambda d, k=k: d.ell(20 + k * 40, 30 + (k % 2) * 10, 6, 6)), dk((250, 230, 240), 1.0))   # corazoncitos de pared
    a = _woman(cv, env, 92, 100, (246, 140, 176), (112, 70, 40), scale=1.35, near_arm=False)
    a.part((236, 72, 132), lambda d: (d.poly([(-3.6, -60.0), (0.4, -57.8), (-3.6, -55.8)]), d.poly([(4.4, -60.0), (0.4, -57.8), (4.4, -55.8)])))   # el moño
    a.part((40, 40, 50), lambda d: d.rect(1.0, -56.0, 3.6, -49.6))                  # el teléfono, a la oreja
    a.part((246, 140, 176), lambda d: (_limb(d, (1.0, -45.6), 2.2, (4.6, -40.4), 1.9), _limb(d, (4.6, -40.4), 1.9, (3.0, -50.8), 1.6)))
    a.part(SKIN, lambda d: d.ell(3.0, -51.2, 1.5, 1.4), shade=1)
    # Lo que mandó: la foto de él, el pin de la dirección, y un arma que no hay (de su cosecha).
    cv.shape(cv.box(142, 16, 178, 62), (40, 40, 50), env, shade=0, half=False)
    cv.fill(cv.box(145, 20, 175, 58), dk((150, 170, 200), 1.0))
    man_stand(Actor(cv, env, 160, 66, scale=0.55))
    cv.fill(cv.mask(lambda d: (d.ell(196, 30, 7, 7), d.poly([(190, 33), (196, 46), (202, 33)]))), (230, 60, 60))
    cv.fill(cv.mask(lambda d: d.ell(196, 30, 2.5, 2.5)), (250, 240, 240))
    gun = (220, 60, 60) if f % 2 == 0 else (240, 120, 120)
    cv.post.append(lambda d: (d.line([(188, 60), (222, 60), (222, 66), (204, 66), (202, 76), (192, 76), (194, 66), (188, 66), (188, 60)], fill=gun),
                              d.text((206, 80), "+", font=FONT, fill=gun)))
    return cv


def p_direccion(f):
    """De todo ese papel, lo único cierto es la dirección: la puerta del 302."""
    cv = Cv(f)
    env = Env((0.5, 0.48, 0.5), (1.25, 1.1, 0.85), (1, -1), half=0.4)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 88), [dk((176, 170, 150), 1.0), dk((176, 170, 150), 0.82)], horizontal=True)
    ground(cv, 88, (140, 120, 100), env)
    cv.shape(cv.box(84, 6, 156, 90), (130, 92, 64), env, shade=2)
    for yy in (20, 50):
        cv.shape(cv.box(92, yy, 148, yy + 24), (130, 92, 64), env, shade=1, half=False, emph=0.9)
    cv.shape(cv.box(108, 10, 132, 18), (210, 190, 120), env, shade=0, half=False)
    cv.post.append(lambda d: d.text((108, 10), "302", font=FONT, fill=(60, 40, 30)))
    cv.fill(cv.mask(lambda d: d.ell(120, 32, 2, 2)), (40, 30, 30))                    # la mirilla
    cv.shape(cv.mask(lambda d: d.ell(146, 52, 3, 3)), (230, 200, 120), env, shade=0)
    cv.shape(cv.box(96, 90, 146, 96), (120, 70, 50), env, shade=0, half=False)        # el tapete
    cv.post.append(lambda d: d.text((98, 89), "HOLA", font=FONT, fill=dk((240, 220, 180), 1.2)))
    cv.fill(cv.mask(lambda d: (d.ell(196, 30, 10, 10), d.poly([(187, 35), (196, 56), (205, 35)]))), (230, 60, 60))   # el pin
    cv.fill(cv.mask(lambda d: d.ell(196, 30, 3.5, 3.5)), (250, 240, 240))
    cv.post.append(lambda d: d.line([(184, 66 + f), (162, 60)], fill=(230, 60, 60), width=2))
    return cv


def p_arroz(f):
    """21:40. Él está haciendo arroz."""
    cv = Cv(f)
    env = Env((0.6, 0.54, 0.5), (1.32, 1.1, 0.8), (-1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.fill(np.ones((H, W), bool), dk((214, 220, 200), 1.0))
    ys, xs = np.mgrid[0:H, 0:W]
    cv.fill(((xs % 12 == 0) | (ys % 12 == 0)) & (ys < 76), dk((214, 220, 200), 0.82))
    ground(cv, 76, (180, 160, 130), env)
    cv.shape(cv.box(110, 56, 200, 92), (230, 230, 232), env, shade=2)                 # la estufa
    for bx in (126, 170):
        cv.fill(cv.mask(lambda d, bx=bx: d.ell(bx, 58, 9, 2.5)), dk((40, 40, 46), 1.0))
    cv.shape(cv.mask(lambda d: (d.rect(160, 40, 182, 56), d.ell(171, 40, 11, 2.5))), (176, 180, 190), env, shade=2)   # la olla
    for k in range(3):
        x0 = 164 + k * 6
        cv.post.append(lambda d, x0=x0: d.line([(x0, 36 - (f + k) % 2), (x0 + 2, 30), (x0 - 2, 24), (x0, 18 + f % 2)], fill=(236, 236, 240)))
    for k in range(3):                                                                 # la llama, azul
        cv.fill(cv.mask(lambda d, k=k: d.poly([(164 + k * 6, 56), (167 + k * 6, 50 + (f + k) % 2), (170 + k * 6, 56)])), (90, 150, 250))
    cv.post.append(lambda d: (d.rectangle([20, 10, 64, 28], fill=(30, 26, 30)), d.text((24, 15), "21:40", font=FONT, fill=(250, 90, 80))))
    a = Actor(cv, env, 132, 96)
    a.clean = True
    man_stand(a, beard=None)
    a.part(COAT, lambda d: d.path([(4, -40), (16, -38), (26, -46)], 4.4))              # revolviendo
    a.part((176, 180, 190), lambda d: d.cap(26, -46, 34, -60, 2))
    lukas_sit(Actor(cv, env, 98, 96), f % 2)
    return cv


def p_policia(f):
    """—¡POLICIA! ¡ABRA! ¡SABEMOS QUE ESTA ARMADO!"""
    cv = Cv(f)
    red = f % 2 == 0
    env = Env((0.4, 0.38, 0.46), (1.4, 0.6, 0.6) if red else (0.6, 0.7, 1.4), (1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 86), [dk((176, 170, 150), 0.9), dk((176, 170, 150), 0.7)], horizontal=True)
    ground(cv, 86, (150, 120, 96), env)
    shake = [0, 2, -2, 1][f]
    cv.shape(cv.box(84 + shake, 4, 152 + shake, 88), (130, 92, 64), env, shade=2)
    cv.fill(cv.box(84, 86, 152, 90), (255, 70, 70) if red else (80, 110, 255))         # la luz, por debajo de la puerta
    cv.glow(118, 88, 46, (255, 70, 70) if red else (80, 110, 255), 0.7, squash=0.25)
    cv.fill(cv.mask(lambda d: d.ell(118 + shake, 32, 2.5, 2.5)), (255, 90, 90) if red else (110, 140, 255))
    for k in range(8):
        ang = k * 0.785 + 0.3
        cv.post.append(lambda d, ang=ang: d.line([(118 + shake + np.cos(ang) * 22, 50 + np.sin(ang) * 22), (118 + shake + np.cos(ang) * 32, 50 + np.sin(ang) * 32)], fill=(250, 230, 120), width=2))
    a = Actor(cv, env, 196, 96)
    a.clean = True
    man_stand(a, beard=None)
    lukas_down(Actor(cv, env, 172, 98, flip=True), 0, "up", ear_up=True)
    cv.post.append(lambda d: (d.line([(150, 70), (158, 64)], fill=(250, 226, 120)), d.line([(152, 78), (160, 78)], fill=(250, 226, 120))))
    return cv


def p_cucharon(f):
    """Tiene un cucharón."""
    cv = Cv(f)
    env = Env((0.56, 0.52, 0.5), (1.3, 1.1, 0.85), (1, -1), half=0.45)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, H), [dk((214, 220, 200), 1.0), dk((214, 220, 200), 0.8)], horizontal=True)
    a = Actor(cv, env, 0, 0)
    a.part(COAT, lambda d: d.poly([(0, 100), (0, 60), (60, 40), (90, 52), (100, 100)]), shade=3)   # el brazo, en primer plano
    a.part(SKIN, lambda d: (d.ell(112, 46, 18, 14), d.ell(104, 36, 8, 6)), shade=2)               # la mano, apretada
    for k in range(4):
        cv.post.append(lambda d, k=k: d.line([(104 + k * 6, 38), (104 + k * 6, 50)], fill=dk(SKIN, 0.75)))
    a.part((190, 194, 204), lambda d: d.cap(116, 40, 176, 8, 6), shade=1)                         # el cucharón, como un arma
    a.part((190, 194, 204), lambda d: d.ell(186, 6, 16, 12), shade=2)
    for k in range(5):                                                                   # el arroz que se cae
        cv.px(176 + k * 5, 18 + (f * 4 + k * 7) % 60, (250, 250, 240))
    cv.post.append(lambda d: d.text((150, 74), "¿ARMA?", font=FONT, fill=(210, 50, 50)))
    return cv


def p_vecino(f):
    """—¡Es ese! ¡El del 302! ¡Yo siempre dije que ese era raro! ¡Saluda mucho!"""
    cv = Cv(f)
    env = Env((0.5, 0.48, 0.5), (1.2, 1.1, 0.9), (-1, -1), half=0.4)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 88), [dk((190, 180, 150), 1.0), dk((190, 180, 150), 0.8)])
    ground(cv, 88, (140, 120, 100), env)
    for dx, num in ((20, "301"), (150, "302")):
        cv.shape(cv.box(dx, 10, dx + 60, 90), (130, 92, 64), env, shade=1)
        cv.post.append(lambda d, dx=dx, num=num: d.text((dx + 18, 14), num, font=FONT, fill=(230, 210, 140)))
    cv.fill(cv.box(76, 10, 82, 90), dk((20, 16, 20), 1.0))                            # el 301, entreabierto
    a = Actor(cv, env, 92, 96)
    man_stand(a, coat=(120, 100, 130), pants=(80, 70, 90), hair=(200, 196, 190), beard=None, tie=False, near_arm=False)   # el vecino, en bata
    a.part((120, 100, 130), lambda d: (_limb(d, (1.0, -45.6), 2.4, (10.2, -46.0), 2.1), _limb(d, (10.2, -46.0), 2.1, (19.2, -47.4 - f % 2), 1.7)))
    a.part(SKIN, lambda d: (d.ell(20.0, -47.6 - f % 2, 1.6, 1.3), d.cap(21.0, -47.8 - f % 2, 23.4, -48.0 - f % 2, 0.9)), shade=1)   # señalando
    for i, sx in enumerate((206, 222)):
        small_man(cv, sx, 96, 0.62, (40, 50, 70), rim=(255, 90, 90) if (f + i) % 2 else (90, 120, 255))
    return cv


def p_tiro(f):
    """El primer tiro entra por la ventana de la sala. El arroz se quema solo."""
    cv = Cv(f)
    env = Env((0.36, 0.34, 0.42), (1.3, 0.8, 0.7), (1, -1), half=0.4)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, 80), [dk((200, 190, 170), 0.85), dk((200, 190, 170), 0.65)])
    ground(cv, 80, (150, 110, 80), env)
    cv.shape(cv.box(90, 10, 170, 64), (110, 90, 70), env, shade=1, half=False)
    cv.fill(cv.box(94, 14, 166, 60), (255, 70, 70) if f % 2 == 0 else (80, 110, 255))
    cv.fill(cv.box(128, 14, 130, 60), dk((110, 90, 70), 1.0))
    for k in range(9):                                                                   # el vidrio, roto en estrella
        ang = k * 0.7 + 0.2
        cv.post.append(lambda d, ang=ang: d.line([(146, 32), (146 + np.cos(ang) * 12, 32 + np.sin(ang) * 10), (146 + np.cos(ang + 0.2) * 22, 32 + np.sin(ang + 0.2) * 18)], fill=(240, 244, 250)))
    cv.post.append(lambda d: (d.ellipse([143, 29, 149, 35], fill=(20, 20, 24)), d.line([(146, 32), (60, 60)], fill=(255, 230, 140), width=1)))
    cv.shape(cv.mask(lambda d: (d.rect(20, 60, 80, 84), d.rect(20, 48, 80, 62))), (120, 76, 110), env, shade=2)   # el sofá
    a = Actor(cv, env, 50, 96)
    a.clean = True
    man_sit(a, 0, "alerta")                                                              # agachado detrás del sofá
    for k in range(3):                                                                   # el humo del arroz, en la cocina
        x0 = 200 + k * 8
        cv.post.append(lambda d, x0=x0: d.line([(x0, 70), (x0 + 3, 56 - f), (x0 - 2, 42), (x0 + 2, 28 + f)], fill=(120, 116, 120), width=2))
    cv.shape(cv.mask(lambda d: (d.rect(194, 70, 226, 84))), (90, 90, 100), env, shade=1)
    lukas_down(Actor(cv, env, 168, 98, flip=True), 0, "down")
    return cv


def p_orden(f):
    """La mochila. La foto. El perro. La ventana de atrás. En ese orden."""
    cv = Cv(f)
    env = Env((0.34, 0.36, 0.52), (0.9, 0.96, 1.3), (1, -1), half=0.35)
    dk = lambda alb, k=0.55: col(alb, env.amb * k)
    cv.grad((0, 0, W, H), [dk((180, 170, 150), 0.9), dk((180, 170, 150), 0.7)], horizontal=True)
    cv.shape(cv.box(100, 8, 190, 76), (110, 90, 70), env, shade=1, half=False)         # la ventana de atrás, abierta
    cv.grad((104, 12, 186, 72), [(14, 16, 40), (26, 26, 60)])
    stars(cv, f, 8, 70, seed=21, m=cv.box(104, 12, 186, 72))
    cv.shape(cv.box(96, 76, 194, 82), (150, 130, 110), env, shade=0, half=False)
    cv.fill(cv.box(0, 82, W, H), dk((150, 110, 80), 0.8))
    # Él, saliendo: una pierna afuera, la mochila puesta, Lukas debajo del brazo, la foto en la mano.
    a = Actor(cv, env, 132, 84)
    a.clean = True                                                                      # (todavía sin barba)
    a.part(PACK, lambda d: d.cap(-5.4, -33.0, -6.6, -21.0, 8.0))
    J = {"head": (3.6, -38.8), "neck": (2.2, -34.2), "hip": (0.0, -12.0),
         "sn": (2.8, -31.4), "sf": (0.8, -31.8), "en": (11.6, -24.6), "hn": (19.0, -21.6),
         "ef": (-7.4, -39.6), "hf": (-15.4, -45.6),
         "kn": (13.8, -20.0), "an": (27.0, -23.0), "tn": (32.6, -25.0),            # una pierna, ya afuera
         "kf": (-3.6, -1.6), "af": (-5.6, 8.4), "tf": (-0.6, 9.4)}                  # la otra, todavía adentro
    figure(a, J, (0.8, 0.2), hem=(6.0, -14.0), near_arm=False)
    lk = Actor(cv, env, 144, 62)
    lukas_curl(lk, 0, eye=True)                                                         # Lukas, debajo del brazo
    a.part(COAT, lambda d: (_limb(d, J["sn"], 2.4, J["en"], 2.1), _limb(d, J["en"], 2.1, J["hn"], 1.7)))
    a.part(SKIN, lambda d: d.ell(J["hn"][0], J["hn"][1], 1.6, 1.4), shade=1)
    cv.shape(cv.box(110, 30, 122, 40), (240, 230, 200), env, shade=0, half=False)     # la foto, en la otra mano
    n = ["1", "2", "3", "4"]
    cv.post.append(lambda d: [d.text((20 + k * 18, 88), n[k], font=FONT, fill=(250, 214, 110) if k <= f else (90, 80, 70)) for k in range(4)])
    return cv


def p_techos(f):
    """Catorce techos. Abajo, el megáfono le habla a un apartamento vacío. Sale el humo del arroz."""
    cv = Cv(f)
    env = _night_env()
    sky(cv, "noche", 0, 50)
    stars(cv, f, 20, 30, seed=24)
    hx = 190 - f * 6                                                                     # el helicóptero, y su luz
    cv.cone((hx, 14), (hx - 40, 90), (hx + 10, 90), (255, 255, 230), 0.4, falloff=0.3)
    cv.fill(cv.mask(lambda d: (d.ell(hx, 11, 6, 3), d.rect(hx + 4, 10, hx + 15, 11.5), d.rect(hx - 8, 6.6, hx + 8, 7.6))), (14, 14, 26))
    for k, (x0, w, top) in enumerate(((0, 60, 64), (66, 50, 58), (122, 56, 66), (184, 56, 60))):
        cv.shape(cv.box(x0, top, x0 + w, H), (120, 96, 96), env, shade=0, half=False, emph=0.8 - (k % 2) * 0.1)
        cv.fill(cv.box(x0, top, x0 + w, top + 2), col((170, 130, 110), env.key * 0.9))
        for wx in range(x0 + 6, x0 + w - 6, 14):
            cv.fill(cv.box(wx, top + 10, wx + 6, top + 18), (240, 200, 120) if (wx + k) % 3 == 0 else (30, 28, 44))
    cv.shape(cv.mask(lambda d: (d.rect(130, 50, 150, 66), d.ell(140, 50, 10, 3))), (90, 96, 110), env, shade=1)   # un tanque de agua
    for k in range(3):                                                                   # el humo, del 302
        x0 = 30 + k * 6
        cv.post.append(lambda d, x0=x0: d.line([(x0, 62), (x0 + 3, 50 - f), (x0 - 2, 38), (x0 + 3, 26 + f)], fill=(110, 106, 120), width=2))
    _man_run(cv, env, 98 + f * 2, 58 - (3 if f in (1, 2) else 0))
    lk = Actor(cv, env, 80 + f * 2, 58)
    lukas_down(lk, 0, "up")
    cv.post.append(lambda d: d.text((8, 4), "14", font=FONT, fill=(250, 214, 110)))
    return cv


def p_rio(f):
    """El agua está fría. El río no pide documentos. Arriba, alguien dice por radio que el sujeto se ahogó."""
    cv = Cv(f)
    env = _night_env()
    sky(cv, "noche", 0, 40)
    stars(cv, f, 14, 20, seed=27)
    cv.shape(cv.box(0, 18, W, 30), (120, 116, 128), env, shade=0, half=False, emph=0.7)   # el puente, arriba
    for xx in range(0, W, 16):
        cv.fill(cv.box(xx, 10, xx + 2, 18), col((120, 116, 128), env.amb * 0.7))
    cv.fill(cv.box(0, 9, W, 11), col((120, 116, 128), env.amb * 0.9))
    for k, (lx, c) in enumerate(((60, (255, 70, 70)), (150, (80, 110, 255)), (200, (255, 70, 70)))):
        on = (f + k) % 2 == 0
        cv.fill(cv.box(lx, 12, lx + 8, 16), c if on else mix(c, (20, 20, 30), 0.6))
        if on:
            cv.glow(lx + 4, 14, 20, c, 0.5)
    for k, x0 in enumerate((70 + f * 8, 170 - f * 6)):                                    # las linternas, buscando
        cv.cone((x0, 30), (x0 - 30 + k * 20, 99), (x0 + 10 + k * 20, 99), (250, 250, 220), 0.35, falloff=0.2)
    cv.grad((0, 30, W, H), [(18, 26, 52), (14, 20, 40), (10, 14, 30)])
    for yy in range(36, H, 5):
        for xx in range((yy * 7 + f * 5) % 23, W, 23):
            cv.fill(cv.box(xx, yy, xx + 8, yy + 1), (40, 56, 90))
    # Dos cabezas en el agua: él y Lukas, que nada mejor que él.
    cv.shape(cv.mask(lambda d: d.ell(120, 74 + (f % 2), 6.4, 6)), HAIR, env, shade=1)
    cv.fill(cv.mask(lambda d: d.ell(120, 80, 12, 2)), (90, 120, 170))
    lk = cv.mask(lambda d: d.ell(146, 76 - (f % 2), 5, 4.5))
    cv.shape(lk, TAN, env, shade=1)
    cv.fill(cv.mask(lambda d: d.ell(150, 77 - (f % 2), 3, 2)), col(WHITE, env.amb))
    cv.fill(cv.mask(lambda d: d.ell(146, 81, 10, 2)), (90, 120, 170))
    return cv


def p_asi_no(f):
    """Lo agarran... No. Así no fue."""
    cv = Cv(f)
    env = _night_env()
    sky(cv, "noche", 0, 60)
    cv.fill(cv.box(0, 70, W, H), (40, 34, 44))
    a = Actor(cv, env, 120, 92)
    man_sit(a, 0, "golpeado")
    for i, sx in enumerate((92, 152)):
        small_man(cv, sx, 94, 0.9, (40, 50, 70), rim=(255, 90, 90) if i else (90, 120, 255))
    # La cinta: rayas, y la X de "así no fue".
    ys, xs = np.mgrid[0:H, 0:W]
    band = ((ys + f * 13) % 26) < 2
    cv.fill(band, (220, 220, 230))
    cv.veil(np.ones((H, W), bool), (20, 20, 30), 0.3)
    cv.post.append(lambda d: (d.line([(70, 10), (170, 90)], fill=(230, 50, 50), width=4), d.line([(170, 10), (70, 90)], fill=(230, 50, 50), width=4),
                              d.text((8, 6), "<< REW", font=FONT, fill=(230, 236, 250))))
    return cv


PROLOGO = [p_apartamento, p_estacion, p_denuncia, p_lorena, p_direccion, p_arroz, p_policia, p_cucharon, p_vecino, p_tiro,
           p_orden, p_techos, p_rio, p_asi_no]


def build_prologo():
    sheet = Image.new("RGBA", (W * FRAMES, H * len(PROLOGO)), (0, 0, 0, 0))
    for i, fn in enumerate(PROLOGO):
        sheet.paste(strip(fn), (0, i * H))
    sheet.save(OUT + "vinetas_prologo.png")
    return "prologo"


# ---------------------------------------------------------------- Las hojas

def strip(fn):
    out = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
    for f in range(FRAMES):
        out.paste(frame(fn(f).image()), (f * W, 0))
    return out


def gris(img, k=0.4):
    a = np.asarray(img.convert("RGBA")).astype(float)
    g = a[..., :3].mean(axis=2, keepdims=True)
    a[..., :3] = a[..., :3] * (1 - k) + g * k
    return Image.fromarray(a.astype(np.uint8))


def build_spot(name):
    fn = SPOTS[name]
    sheet = Image.new("RGBA", (W * FRAMES, H * len(ROWS)), (0, 0, 0, 0))
    for i, (pose, time, r, s) in enumerate(ROWS):
        sheet.paste(strip(lambda f: fn(pose, time, r, s, f)), (0, i * H))
    sheet.save(OUT + "vinetas_%s.png" % name)
    return name


def build_momentos():
    sheet = Image.new("RGBA", (W * FRAMES, H * len(MOMENTOS)), (0, 0, 0, 0))
    for i, fn in enumerate(MOMENTOS):
        s = strip(fn)
        sheet.paste(gris(s, 0.35) if i == 3 else s, (0, i * H))
    sheet.save(OUT + "vinetas_momentos.png")
    return "momentos"


def prueba(path, specs, zoom=3, cols=3):
    """Una hoja para mirar: el cuadro 1 de cada viñeta pedida (lugar:tipo:hora:lluvia:solo[:cuadro] o momentos:N)."""
    ims = []
    for sp in specs:
        p = sp.split(":")
        if p[0] == "prologo":
            ims.append(frame(PROLOGO[int(p[1])](int(p[2]) if len(p) > 2 else 1).image()))
            continue
        if p[0] == "momentos":
            ims.append(frame(MOMENTOS[int(p[1])](int(p[2]) if len(p) > 2 else 1).image()))
        else:
            ims.append(frame(SPOTS[p[0]](p[1], p[2], int(p[3]), int(p[4]), int(p[5]) if len(p) > 5 else 1).image()))
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new("RGB", (W * cols, H * rows), (40, 0, 40))
    for i, im in enumerate(ims):
        sheet.paste(im.convert("RGB"), ((i % cols) * W, (i // cols) * H))
    sheet.resize((W * cols * zoom, H * rows * zoom), Image.NEAREST).save(path)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--prueba":
        prueba(args[1], args[2:])
        sys.exit()
    names = args or (list(SPOTS) + ["momentos", "prologo"])
    jobs = [n for n in names if n in SPOTS]
    with Pool(min(7, max(1, len(jobs)))) as pool:
        for done in pool.imap_unordered(build_spot, jobs):
            print(done)
    if "momentos" in names:
        print(build_momentos())
    if "prologo" in names:
        print(build_prologo())
