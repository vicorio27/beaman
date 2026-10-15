"""El motor de las viñetas (lo usa tools/art/draw_vinetas.py).

Pixel art hecho por código, a 240x100:
  - Las formas se dibujan a 4x (elipses, cápsulas, polígonos) y se bajan a máscaras duras de 1x: bordes
    redondos sin colores intermedios.
  - Cada forma tiene un color propio (el de día) y la escena le pone la luz (Env): la sombra media, el
    lado que no mira a la luz (más oscuro), el lado que sí (media luz) y el borde de luz. Así la misma
    escena sirve de noche, al alba y con lluvia: solo cambia la luz.
  - Los degradados (el cielo, el piso, los conos de luz) van tramados (Bayer 4x4), sin colores de más.
  - Los actores: él (sin cara: pelo, barba, un pedazo de piel; el saco que le queda grande, la corbata
    roja, un zapato de cada color) y Lukas (beagle tricolor), cada uno con sus posturas.
"""
import numpy as np
from PIL import Image, ImageDraw

W, H, SS = 240, 100, 4
BAYER = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) + 0.5) / 16.0
BAY = np.tile(BAYER, (H // 4 + 1, W // 4 + 1))[:H, :W]

def set_size(w, h):
    """Otro tamaño de lienzo (los retratos: 96x112)."""
    global W, H, BAY
    W, H = w, h
    BAY = np.tile(BAYER, (H // 4 + 1, W // 4 + 1))[:H, :W]


# Los colores de cada cosa, a la luz del día.
COAT, PANTS, HAIR, BEARD = (104, 110, 136), (74, 80, 106), (46, 38, 42), (74, 62, 60)
SKIN, SHIRT, TIE = (220, 164, 128), (220, 212, 194), (230, 54, 58)
SHOE_A, SHOE_B, PACK = (160, 106, 60), (72, 118, 186), (104, 132, 90)
TAN, EAR, BLACK, WHITE = (214, 138, 74), (156, 90, 50), (50, 44, 48), (246, 240, 228)
CARTON, TARP = (184, 144, 96), (70, 116, 200)


def col(alb, mult):
    return tuple(int(min(255.0, max(0.0, a * m))) for a, m in zip(alb, mult))


def mix(c1, c2, k):
    return tuple(int(a * (1 - k) + b * k) for a, b in zip(c1, c2))


class Env:
    """La luz de la escena. amb: lo que no mira a la luz. key: el borde que sí. L: hacia dónde está la luz."""

    def __init__(self, amb, key, L=(1, -1), shadow=0.62, half=0.35):
        self.amb = np.array(amb, float)
        self.key = np.array(key, float)
        self.L = L
        self.shadow = shadow
        self.half = half

    def but(self, **kw):
        e = Env(self.amb, self.key, self.L, self.shadow, self.half)
        for k, v in kw.items():
            setattr(e, k, np.array(v, float) if k in ("amb", "key") else v)
        return e


def nb(m, dx, dy):
    """El vecino de cada píxel en (dx, dy). Fuera del cuadro: no."""
    out = np.zeros_like(m)
    h, w = m.shape
    y0, y1 = max(0, -dy), min(h, h - dy)
    x0, x1 = max(0, -dx), min(w, w - dx)
    if y0 < y1 and x0 < x1:
        out[y0:y1, x0:x1] = m[y0 + dy:y1 + dy, x0 + dx:x1 + dx]
    return out


class D:
    """Dibuja en una máscara (a 4x) con medidas de 1x, alrededor de un origen; volteado, si hace falta."""

    def __init__(self, d, ox=0.0, oy=0.0, flip=False, k=1.0):
        self.d, self.ox, self.oy, self.s, self.k = d, ox, oy, (-1.0 if flip else 1.0), k

    def p(self, x, y):
        return ((self.ox + self.s * x * self.k) * SS, (self.oy + y * self.k) * SS)

    def ell(self, cx, cy, rx, ry):
        x, y = self.p(cx, cy)
        rx, ry = rx * self.k, ry * self.k
        self.d.ellipse([x - rx * SS, y - ry * SS, x + rx * SS, y + ry * SS], fill=255)

    def poly(self, pts):
        self.d.polygon([self.p(x, y) for x, y in pts], fill=255)

    def rect(self, x0, y0, x1, y1):
        self.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)])

    def cap(self, x0, y0, x1, y1, w):
        a, b = self.p(x0, y0), self.p(x1, y1)
        w = w * self.k
        r = w * SS / 2.0
        self.d.line([a, b], fill=255, width=max(1, int(round(w * SS))))
        for q in (a, b):
            self.d.ellipse([q[0] - r, q[1] - r, q[0] + r, q[1] + r], fill=255)

    def path(self, pts, w):
        for i in range(len(pts) - 1):
            self.cap(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], w)


class Cv:
    """El lienzo de un cuadro (240x100)."""

    def __init__(self, f=0):
        self.a = np.zeros((H, W, 3), np.uint8)
        self.f = f
        self.post = []  # los detalles de un píxel, al final: funciones que reciben un ImageDraw

    # ---- máscaras
    def mask(self, fn, ox=0.0, oy=0.0, flip=False, k=1.0):
        im = Image.new("L", (W * SS, H * SS), 0)
        fn(D(ImageDraw.Draw(im), ox, oy, flip, k))
        return np.asarray(im, np.float32).reshape(H, SS, W, SS).mean((1, 3)) >= 127.5

    def box(self, x0, y0, x1, y1):
        m = np.zeros((H, W), bool)
        m[max(0, int(y0)):max(0, int(y1)), max(0, int(x0)):max(0, int(x1))] = True
        return m

    # ---- pintar
    def fill(self, m, color):
        self.a[m] = color

    def shape(self, m, alb, env, rim=True, shade=2, half=True, emph=1.0, flat=False):
        """Una forma con volumen: base, lado en sombra, media luz y borde de luz."""
        amb = env.amb * emph
        self.a[m] = col(alb, amb)
        if flat:
            return m
        lx, ly = env.L
        if shade:
            inner = m.copy()
            for i in range(1, shade + 1):
                if lx:
                    inner &= nb(m, -lx * i, 0)
                if ly:
                    inner &= nb(m, 0, -ly * i)
            self.a[m & ~inner] = col(alb, amb * env.shadow)
        if half and env.half > 0:
            inner = m.copy()
            for i in (1, 2):
                if lx:
                    inner &= nb(m, lx * i, 0)
                if ly:
                    inner &= nb(m, 0, ly * i)
            self.a[m & ~inner] = col(alb, amb + (env.key * emph - amb) * env.half)
        if rim:
            inner = m.copy()
            if lx:
                inner &= nb(m, lx, 0)
            if ly:
                inner &= nb(m, 0, ly)
            self.a[m & ~inner] = col(alb, env.key * emph)
        return m

    def grad(self, box, ramp, horizontal=False, ease=1.0, m=None):
        """Un degradado tramado entre los colores de ramp (sin colores intermedios)."""
        x0, y0, x1, y1 = box
        n = len(ramp) - 1
        ys, xs = np.mgrid[y0:y1, x0:x1]
        t = ((xs - x0) / max(1, x1 - x0 - 1)) if horizontal else ((ys - y0) / max(1, y1 - y0 - 1))
        v = (t ** ease) * n
        i = np.floor(v).astype(int)
        i = np.clip(i + ((v - i) > BAY[y0:y1, x0:x1]), 0, n)
        out = np.array(ramp, np.uint8)[i]
        if m is None:
            self.a[y0:y1, x0:x1] = out
        else:
            sub = m[y0:y1, x0:x1]
            self.a[y0:y1, x0:x1][sub] = out[sub]

    def light(self, k, color, amount=0.55):
        """Luz tramada: k (0..1 por píxel) dice cuánta; mezcla hacia color donde le toca al tramado."""
        on = k > BAY * 0.95
        kk = (k * amount)[..., None]
        mixed = self.a * (1 - kk) + np.array(color, float) * kk
        self.a[on] = mixed[on].astype(np.uint8)

    def cone(self, apex, bl, br, color, strength=0.6, amount=0.55, falloff=0.6):
        ys, xs = np.mgrid[0:H, 0:W]
        ax, ay = apex
        y1 = max(bl[1], br[1])
        t = np.clip((ys - ay) / max(1.0, y1 - ay), 0, 1)
        xl = ax + (bl[0] - ax) * t
        xr = ax + (br[0] - ax) * t
        inside = (ys >= ay) & (ys <= y1) & (xs >= xl) & (xs <= xr)
        self.light(np.where(inside, strength * (1 - t * falloff), 0.0), color, amount)

    def glow(self, cx, cy, r, color, strength=0.8, amount=0.6, squash=1.0):
        ys, xs = np.mgrid[0:H, 0:W]
        d = np.sqrt((xs - cx) ** 2 + ((ys - cy) / squash) ** 2) / r
        self.light(np.clip(1.0 - d, 0, 1) * strength, color, amount)

    def veil(self, m, color, k=0.5):
        """Un velo tramado (sombra, neblina): pone color en una parte de los píxeles de m."""
        self.a[m & (BAY < k)] = color

    def px(self, x, y, color):
        if 0 <= int(x) < W and 0 <= int(y) < H:
            self.a[int(y), int(x)] = color

    def image(self):
        img = Image.fromarray(self.a).convert("RGBA")
        d = ImageDraw.Draw(img)
        for fn in self.post:
            fn(d)
        return img


class Actor:
    """Alguien en la escena: partes alrededor de un origen (los pies, el piso), con la luz de la escena."""

    def __init__(self, cv, env, x, y, flip=False, emph=1.0, scale=1.0):
        self.cv, self.env, self.x, self.y, self.flip, self.emph, self.k = cv, env, x, y, flip, emph, scale
        self.all = np.zeros((H, W), bool)

    def part(self, alb, fn, **kw):
        m = self.cv.mask(fn, self.x, self.y, self.flip, self.k)
        kw.setdefault("emph", self.emph)
        self.cv.shape(m, alb, self.env, **kw)
        self.all |= m
        return m

    def at(self, x, y):
        return (int(round(self.x + (-x if self.flip else x) * self.k)), int(round(self.y + y * self.k)))

    def dot(self, x, y, color):
        p = self.at(x - (1 if self.flip else 0), y)
        self.cv.post.append(lambda d, p=p, c=color: d.point(p, fill=c))

    def line(self, pts, color, width=1):
        q = [self.at(x, y) for x, y in pts]
        self.cv.post.append(lambda d, q=q, c=color, w=width: d.line(q, fill=c, width=w))

    def lit(self, alb, k=1.0):
        """El color de un detalle, con la luz de la escena (k: cuánto mira a la luz)."""
        e = self.env
        return col(alb, (e.amb + (e.key - e.amb) * k) * self.emph)


# ---------------------------------------------------------------- Él

def _head(a, cx, cy, look, hair_only=False):
    """La cabeza: pelo, un pedazo de piel sin cara y la barba. look: hacia dónde da la cara (dx, dy)."""
    a.part(HAIR, lambda d: d.ell(cx, cy, 6.4, 6.4))
    if hair_only:
        return
    lx, ly = look
    a.part(SKIN, lambda d: d.ell(cx + lx * 2.4, cy + ly * 2.4, 3.5, 3.5), shade=1)
    # La barba: hacia el pecho (abajo de la cara).
    if getattr(a, "clean", False):  # (sin barba: el de antes)
        return
    bx, by = cx + lx * 2.6 - ly * 2.6, cy + ly * 2.6 + lx * 2.8
    a.part(BEARD, lambda d: d.ell(bx, by, 3.2, 2.7), shade=1, rim=False)


def man_side(a, b=0, away=False, reach=False, still=False):
    """Dormido de lado, encogido, la cabeza a la izquierda. Origen: el piso, bajo la cadera."""
    a.part(PANTS, lambda d: d.path([(0, -4), (17, -6), (28, -3.2)], 6.0), emph=a.emph * 0.85)   # la pierna de abajo
    a.part(SHOE_B, lambda d: d.cap(29.5, -2.4, 35, -2.4, 4.4))
    a.part(PANTS, lambda d: d.path([(0, -9), (19, -13), (31, -7)], 6.6))                         # la de arriba
    a.part(SHOE_A, lambda d: d.cap(32.5, -6.2, 38.5, -5.2, 4.6))
    a.part(COAT, lambda d: (d.cap(-26, -8.5 - b * 0.5, -1, -8, 15 + b),
                            d.poly([(-6, -15.5 - b), (7, -12), (9, -0.5), (-8, -0.5)])))         # el saco, grande
    a.part(COAT, lambda d: d.cap(-31, -3, -45, -2.6, 4.8), emph=a.emph * 0.85)                   # el brazo de almohada
    a.part(SKIN, lambda d: d.ell(-47.5, -2.4, 2.2, 1.9), shade=1)
    if away:
        _head(a, -38.5, -9.5, (0, 0), hair_only=True)
        a.line([(-28, -15 - b), (-4, -15.5 - b)], a.lit(COAT, -0.3))                             # la costura de la espalda
    else:
        _head(a, -38.5, -9.5, (0.75, 0.35))
        hand = (-27, -1.6) if reach else (-19.5, -1.8)
        a.part(COAT, lambda d: d.path([(-25, -13 - b), (-13, -9), (hand[0] + 1, hand[1] - 1)], 4.8))  # el brazo de encima
        a.part(SKIN, lambda d: d.ell(hand[0], hand[1], 2.1, 1.8), shade=1)
        a.line([(-31, -10), (-30, -6), (-28, -2)], a.lit(TIE, 0.5))                              # la corbata, floja
    return {"head": a.at(-38, -16), "feet": a.at(34, -4), "belly": a.at(-10, -1), "hand": a.at(-48, -2)}


def man_back(a, b=0, arms="chest"):
    """Boca arriba, tieso, la cabeza a la izquierda. Origen: el piso (o el colchón), bajo la cadera."""
    a.part(PANTS, lambda d: d.cap(2, -5.4, 33, -5.2, 6.0), emph=a.emph * 0.85)
    a.part(SHOE_B, lambda d: d.cap(34.5, -5, 35, -10.5, 4.0))
    a.part(PANTS, lambda d: d.cap(0, -4.6, 34, -3.8, 7.0))
    a.part(SHOE_A, lambda d: d.cap(37.5, -2.6, 38, -11, 4.6))
    a.part(COAT, lambda d: d.cap(-26, -6.6 - b * 0.5, -2, -6.2, 12.5 + b))
    a.part(SHIRT, lambda d: d.poly([(-29, -11.5 - b), (-22, -13 - b), (-20, -9.5 - b), (-27, -8)]), shade=1)
    a.line([(-27, -11.5 - b), (-22, -12.5 - b), (-20, -10 - b)], a.lit(TIE, 0.6))
    if arms == "eyes":
        a.part(PACK, lambda d: d.cap(-45, -4.5, -36, -4.5, 9))                                   # la mochila, de almohada
    _head(a, -37, -7.5 - (4 if arms == "eyes" else 0), (0.1, -0.9))
    if arms == "chest":
        a.part(COAT, lambda d: d.path([(-25, -4.6), (-15, -3.6), (-12, -12.5 - b)], 4.5))
        a.part(SKIN, lambda d: d.ell(-11.5, -14 - b, 2.3, 1.9), shade=1)
    elif arms == "eyes":
        a.part(COAT, lambda d: d.path([(-25, -11), (-31, -20), (-41, -15.5)], 4.6))              # el brazo, sobre los ojos
        a.part(SKIN, lambda d: d.ell(-43, -14, 2.2, 2.0), shade=1)
    else:
        a.part(COAT, lambda d: d.cap(-25, -4.2, -9, -2.8, 4.5))
        a.part(SKIN, lambda d: d.ell(-7, -2.4, 2.2, 1.8), shade=1)
    return {"head": a.at(-37, -15), "feet": a.at(36, -8), "belly": a.at(-10, -13 - b), "hand": a.at(-7, -2)}


def man_bench(a, b=0, awake=False, pack=True):
    """Sentado en un banco (o en el borde de la cama), mirando a la derecha. Origen: el piso bajo la cadera; el asiento, a 20."""
    a.part(PANTS, lambda d: d.cap(15, -19, 14, -3.5, 5.6), emph=a.emph * 0.85)                   # la pierna de atrás
    a.part(SHOE_B, lambda d: d.cap(13, -1.9, 20, -1.9, 3.8))
    if awake:
        a.part(COAT, lambda d: d.cap(0, -24, 4, -42, 13))                                        # doblado para adelante
        a.part(PANTS, lambda d: d.cap(2, -23.5, 21, -22.5, 7.2))
        a.part(PANTS, lambda d: d.cap(21.5, -21, 23, -3.5, 6.0))
        a.part(SHOE_A, lambda d: d.cap(22, -2, 30.5, -2, 4.0))
        _head(a, 8, -50, (0.55, 0.75))
        a.part(COAT, lambda d: d.path([(4, -40), (15, -29), (20, -19)], 4.6))                    # los codos en las rodillas
        a.part(SKIN, lambda d: d.ell(20.5, -17, 2.2, 2.2), shade=1)
        a.line([(9, -43), (11, -37), (10, -31)], a.lit(TIE, 0.6))
        return {"head": a.at(8, -57), "hand": a.at(21, -15), "feet": a.at(26, -2)}
    a.part(COAT, lambda d: d.cap(0, -24, -4, -43 - b, 13))                                       # recostado en el espaldar
    a.part(PANTS, lambda d: d.cap(2, -23.5, 21, -22.5, 7.2))
    a.part(PANTS, lambda d: d.cap(21.5, -21, 23, -3.5, 6.0))
    a.part(SHOE_A, lambda d: d.cap(22, -2, 30.5, -2, 4.0))
    _head(a, -7, -51 - b, (0.6, -0.75))                                                          # la cabeza, para atrás
    if pack:
        a.part(PACK, lambda d: d.cap(9, -31 - b, 18, -31 - b, 12.5))                             # la mochila, abrazada
        a.line([(4, -33 - b), (23, -33 - b)], a.lit(PACK, -0.5))
    a.part(COAT, lambda d: d.path([(-2, -40 - b), (9, -33 - b), (20, -36 - b)], 4.6))
    a.part(SKIN, lambda d: d.ell(21.8, -36.5 - b, 2.1, 1.9), shade=1)
    a.line([(-1, -45 - b), (2, -40 - b)], a.lit(TIE, 0.5))
    return {"head": a.at(-7, -58 - b), "hand": a.at(22, -36 - b), "feet": a.at(26, -2)}


def man_sit(a, b=0, mode="dormido"):
    """En el piso, las rodillas arriba, mirando a la derecha. mode: dormido (la cabeza en los brazos),
    alerta (la cabeza arriba) o golpeado (la mano en la cara). Origen: el piso, bajo la cola."""
    a.part(PANTS, lambda d: d.path([(4, -5), (16, -19), (18, -3.5)], 5.8), emph=a.emph * 0.85)
    a.part(SHOE_B, lambda d: d.cap(17, -1.9, 24, -1.9, 3.8))
    a.part(COAT, lambda d: (d.cap(0, -6.5, 5, -27 - b, 13), d.poly([(-6.5, -8), (4, -8), (5, -0.5), (-7.5, -0.5)])))
    a.part(PANTS, lambda d: d.path([(5, -5.5), (21, -21), (25, -3.5)], 6.6))
    a.part(SHOE_A, lambda d: d.cap(24, -2, 32.5, -2, 4.0))
    if mode == "dormido":
        _head(a, 15.5, -30.5 - b, (0, 0), hair_only=True)
        a.part(COAT, lambda d: d.path([(6, -25 - b), (17, -24), (24.5, -23)], 4.8))
        a.part(SKIN, lambda d: d.ell(26.2, -22.4, 2.1, 1.9), shade=1)
        return {"head": a.at(15, -37 - b), "hand": a.at(26, -22)}
    _head(a, 6.5, -37.5 - b, (0.8, 0.3))
    a.line([(9, -31 - b), (10, -25), (9, -19)], a.lit(TIE, 0.6))
    if mode == "golpeado":
        a.part(COAT, lambda d: d.cap(5, -24, 20.5, -22.5, 4.6), emph=a.emph * 0.85)
        a.part(COAT, lambda d: d.path([(7, -26 - b), (15.5, -27), (12.5, -35 - b)], 4.6))        # la mano a la cara
        a.part(SKIN, lambda d: d.ell(12, -37 - b, 2.3, 2.2), shade=1)
        a.dot(9, -40 - b, (214, 56, 60))                                                          # lo que le quedó
        a.dot(10, -41 - b, (214, 56, 60))
    else:
        a.part(COAT, lambda d: d.path([(6, -25 - b), (17, -24), (24.5, -23)], 4.8))
        a.part(SKIN, lambda d: d.ell(26.2, -22.4, 2.1, 1.9), shade=1)
    return {"head": a.at(6, -44 - b), "hand": a.at(26, -22)}


def man_wake(a, b=0, reach=False):
    """Recién despierto: sentado en el piso, las piernas estiradas, mirando a la derecha. Origen: bajo la cadera."""
    a.part(PANTS, lambda d: d.cap(2, -4.2, 30, -5, 6.0), emph=a.emph * 0.85)
    a.part(SHOE_B, lambda d: d.cap(31.5, -4.5, 32, -10, 4.0))
    a.part(COAT, lambda d: d.path([(-1, -25), (-8, -14), (-10, -3.5)], 4.6), emph=a.emph * 0.85)  # el brazo en que se apoya
    a.part(SKIN, lambda d: d.ell(-10.5, -1.9, 2.3, 1.7), shade=1)
    a.part(PANTS, lambda d: d.path([(2, -5), (18, -10), (33, -4.2)], 6.8))
    a.part(SHOE_A, lambda d: d.cap(35.5, -3, 36, -10.5, 4.6))
    a.part(COAT, lambda d: (d.cap(0, -6.5, 2.5, -28, 13), d.poly([(-6.5, -8), (5, -8), (6, -0.5), (-7.5, -0.5)])))
    a.part(SHIRT, lambda d: d.poly([(5.5, -29), (9, -27), (8.4, -15), (5.5, -15)]), shade=1)
    a.line([(7, -28), (8, -22), (7, -16)], a.lit(TIE, 0.7))
    _head(a, 5, -38, (0.8, 0.3))
    if reach:
        a.part(COAT, lambda d: d.path([(3, -26), (11, -20), (19, -14)], 4.6))                     # la mano, a Lukas
        a.part(SKIN, lambda d: d.ell(20.5, -13, 2.2, 2.0), shade=1)
        return {"head": a.at(5, -45), "hand": a.at(21, -13)}
    a.part(COAT, lambda d: d.path([(3, -26), (11, -22), (9.5, -33)], 4.6))                        # la mano, a la cara
    a.part(SKIN, lambda d: d.ell(9.6, -35.5, 2.2, 2.2), shade=1)
    return {"head": a.at(5, -45), "hand": a.at(10, -35)}


def man_stand(a, coat=COAT, pants=PANTS, hair=HAIR, beard=BEARD, hat=None, hold_hat=None, tie=True, bulk=1.0):
    """De pie, quieto, mirando a la derecha. Origen: los pies. (También sirve para Samuel y los demás.)"""
    a.part(pants, lambda d: d.cap(-3, -22, -3.5, -3, 5.6 * bulk), emph=a.emph * 0.85)
    a.part(pants, lambda d: d.cap(3, -22, 3.5, -3, 5.8 * bulk))
    a.part(SHOE_B if coat == COAT else (60, 50, 48), lambda d: d.cap(-4, -1.8, 1, -1.8, 3.6))
    a.part(SHOE_A if coat == COAT else (60, 50, 48), lambda d: d.cap(3, -1.8, 9, -1.8, 3.8))
    a.part(coat, lambda d: d.cap(0, -25, 0.5, -42, 13.5 * bulk))
    a.part(hair, lambda d: d.ell(0.5, -51, 6.2, 6.4))
    a.part(SKIN, lambda d: d.ell(2.6, -50.4, 3.4, 3.5), shade=1)
    if beard is not None:
        a.part(beard, lambda d: d.ell(3, -47, 3.2, 2.7), shade=1, rim=False)
    if hat is not None:
        a.part(hat, lambda d: (d.ell(0.5, -55.5, 6.6, 3.2), d.rect(2, -55, 10.5, -53)))
    if hold_hat is not None:
        a.part(coat, lambda d: d.path([(2, -40), (8, -33), (2, -31)], 4.6))                       # el sombrero, en el pecho
        a.part(hold_hat, lambda d: d.ell(1.5, -30.5, 4.6, 2.6))
    else:
        a.part(coat, lambda d: d.cap(1, -40, 2, -26, 4.6), emph=a.emph * 0.85)
        a.part(SKIN, lambda d: d.ell(2.2, -24, 2.0, 2.0), shade=1)
    if tie:
        a.line([(4, -44), (5, -38), (4, -32)], a.lit(TIE, 0.6))
    return {"head": a.at(0, -58)}


# ---------------------------------------------------------------- Lukas

def _lukas_head(a, cx, cy, ear_up=False, eye=True, tilt=0.0):
    a.part(TAN, lambda d: d.ell(cx, cy, 5.6, 4.9))
    a.part(WHITE, lambda d: d.ell(cx + 5, cy + 1.5 - tilt, 3.7, 2.6), shade=1)                   # el hocico
    a.part(WHITE, lambda d: d.poly([(cx + 0.4, cy - 4.8), (cx + 2, cy - 4.8), (cx + 3.4, cy + 0.5), (cx + 1.6, cy + 0.5)]),
           shade=0, rim=False)                                                                    # la franja
    if ear_up:
        a.part(EAR, lambda d: d.poly([(cx - 4.6, cy - 2), (cx - 2, cy - 10.5), (cx - 0.4, cy - 2.5)]))
    else:
        a.part(EAR, lambda d: d.ell(cx - 3, cy + 2, 2.9, 5.0))                                    # la oreja, caída
    a.dot(cx + 8, cy + 0.6 - tilt, (22, 18, 22))                                                  # la nariz
    if eye:
        a.dot(cx + 1.6, cy - 1.4, (20, 16, 20))


def lukas_curl(a, b=0, eye=False):
    """Hecho un ovillo, la cabeza a la derecha, sobre las patas. Origen: el piso, en la mitad."""
    a.part(TAN, lambda d: d.ell(0, -6.6 - b * 0.5, 14.5, 6.6 + b * 0.5))
    a.part(BLACK, lambda d: d.ell(-1.5, -9.6 - b * 0.5, 10.5, 3.9 + b * 0.5), shade=1)           # la montura
    a.part(TAN, lambda d: d.cap(-12, -2.6, -2, -1.4, 2.8), shade=1)                               # la cola, enroscada
    a.part(WHITE, lambda d: d.ell(-0.6, -1.3, 1.7, 1.3), shade=0, rim=False)
    a.part(WHITE, lambda d: d.cap(8, -1.3, 16.5, -1.3, 2.4), shade=0)                             # las patas
    _lukas_head(a, 10.5, -5.4, eye=eye)
    return {"back": a.at(-2, -14 - b)}


def lukas_down(a, b=0, head="up", ear_up=False, eye=True):
    """Echado como una esfinge, mirando a la derecha. head: up (de guardia) o down (sobre las patas).
    Origen: el piso, donde van las patas de adelante."""
    a.part(TAN, lambda d: d.cap(-27, -7.5, -33.5, -12.5, 2.6), shade=1)                           # la cola
    a.dot(-34, -13.5, a.lit(WHITE, 0.6))
    a.part(TAN, lambda d: (d.ell(-21, -6.2, 7.2, 6.2), d.cap(-20, -7.2 - b * 0.5, -3, -7.6, 11 + b)))
    a.part(BLACK, lambda d: d.cap(-20, -10.8 - b * 0.5, -6, -10.8, 4.8 + b * 0.5), shade=1)
    a.part(WHITE, lambda d: d.ell(-1, -5.5, 3.4, 5.0), shade=1)                                   # el pecho
    a.part(WHITE, lambda d: d.cap(0, -1.3, 9.5, -1.3, 2.6), shade=0)
    if head == "up":
        a.part(TAN, lambda d: d.cap(-3, -9, 1.5, -15, 7.2))
        _lukas_head(a, 3.5, -18.5, ear_up, eye)
        return {"head": a.at(4, -24)}
    _lukas_head(a, 5.5, -5.8, ear_up, eye)
    return {"head": a.at(6, -11)}


def lukas_sit(a, wag=0, up=True):
    """Sentado, mirando a la derecha (y para arriba: a él). Origen: el piso, bajo las patas de adelante."""
    a.part(TAN, lambda d: d.cap(-14, -2.4, -21.5, -3.5 - wag * 3.5, 2.6), shade=1)
    a.dot(-22.5, -4 - wag * 4, a.lit(WHITE, 0.6))
    a.part(TAN, lambda d: (d.ell(-9, -6.2, 7.6, 6.4), d.cap(-7, -9, -1.5, -21, 9.6)))
    a.part(BLACK, lambda d: d.cap(-9.5, -10.5, -4.5, -21, 4.6), shade=1)
    a.part(WHITE, lambda d: d.cap(1, -9, 2, -19.5, 4.4), shade=1)
    a.part(WHITE, lambda d: d.cap(2, -11, 3, -1.6, 3.0), shade=1)
    _lukas_head(a, 3.5, -26.5, tilt=1.2 if up else 0.0)
    return {"head": a.at(4, -32)}


# ---------------------------------------------------------------- El clima y las cosas de todos los cuadros

def rain(cv, f, n=110, color=(120, 132, 164), seed=3, m=None, lit=None, speed=9):
    """La lluvia: rayitas que caen de lado. m: dónde se ve. lit(x, y): otro color donde le pega una luz."""
    rng = np.random.default_rng(seed)
    xs = rng.integers(0, W + 30, n)
    ys = rng.integers(-20, H, n)
    for x, y in zip(xs, ys):
        y = (y + f * speed + 20) % (H + 20) - 20
        for k in range(4):
            yy, xx = int(y + k * 2), int(x - k)
            if 0 <= yy < H and 0 <= xx < W and (m is None or m[yy, xx]):
                c = lit(xx, yy) if lit else None
                cv.a[yy, xx] = c if c else color


def splashes(cv, f, y0, y1, n=14, color=(170, 180, 204), seed=8, m=None):
    """Las gotas que rebotan en el piso."""
    rng = np.random.default_rng(seed + f * 31)
    for _ in range(n):
        x, y = int(rng.integers(2, W - 2)), int(rng.integers(y0, y1))
        if m is not None and not m[y, x]:
            continue
        cv.px(x, y, color)
        if rng.random() < 0.5:
            cv.px(x - 1, y - 1, color)
            cv.px(x + 1, y - 1, color)


def stars(cv, f, n=26, y1=44, seed=1, m=None, color=(214, 212, 238)):
    rng = np.random.default_rng(seed)
    for i in range(n):
        x, y = int(rng.integers(2, W - 2)), int(rng.integers(2, y1))
        if (m is None or m[y, x]) and (i + f) % 6 != 0:
            cv.px(x, y, color if i % 3 else mix(color, (120, 120, 170), 0.5))


def breath(f):
    return 1 if f in (1, 2) else 0


def vapor(cv, f, x, y, color=(170, 174, 200), dx=1):
    """El vaho: hace frío."""
    if f in (1, 2, 3):
        cv.post.append(lambda d: (d.point((x + dx * f, y - f * 2), fill=color),
                                  d.point((x + dx * (f + 2), y - f * 2 - 2), fill=mix(color, (60, 60, 90), 0.5))))


def ground_shadow(cv, cx, y, rx, ry=2.4, color=(8, 8, 14), k=0.55):
    m = cv.mask(lambda d: d.ell(cx, y, rx, ry))
    cv.veil(m, color, k)


if __name__ == "__main__":
    # La hoja de posturas: para mirarlas de cerca.  python tools/art/vinetas_motor.py salida.png
    import sys
    env = Env((0.36, 0.4, 0.6), (1.25, 1.0, 0.66), (1, -1))
    day = Env((0.62, 0.52, 0.6), (1.35, 1.02, 0.74), (1, -1), half=0.5)
    sheets = []
    for e in (env, day):
        for row in range(3):
            cv = Cv()
            cv.grad((0, 0, W, 70), [(14, 16, 40), (24, 24, 58), (40, 34, 76)] if e is env else [(128, 100, 140), (222, 144, 128), (250, 198, 150)])
            cv.grad((0, 70, W, H), [(40, 36, 48), (26, 24, 34)] if e is env else [(96, 80, 84), (66, 56, 64)])
            if row == 0:
                man_side(Actor(cv, e, 62, 92), 0)
                lukas_curl(Actor(cv, e, 124, 93), 0)
                man_back(Actor(cv, e, 190, 92), 1, "eyes")
            elif row == 1:
                man_bench(Actor(cv, e, 30, 92), 0)
                man_bench(Actor(cv, e, 80, 92), 0, awake=True)
                man_sit(Actor(cv, e, 124, 92), 0, "dormido")
                man_sit(Actor(cv, e, 168, 92), 0, "golpeado")
                lukas_sit(Actor(cv, e, 222, 92, flip=True), 1)
            else:
                man_wake(Actor(cv, e, 30, 92), 0, reach=True)
                lukas_sit(Actor(cv, e, 72, 92, flip=True), 0)
                lukas_down(Actor(cv, e, 122, 92), 0, "up", ear_up=True)
                lukas_down(Actor(cv, e, 176, 92), 0, "down")
                man_stand(Actor(cv, e, 214, 92), coat=(132, 100, 68), hair=(170, 168, 166), beard=(190, 188, 184), hold_hat=(170, 66, 56), tie=False)
            sheets.append(cv.image().convert("RGB"))
    out = Image.new("RGB", (W * 2, H * 3))
    for i, s in enumerate(sheets):
        out.paste(s, ((i // 3) * W, (i % 3) * H))
    out.resize((W * 2 * 4, H * 3 * 4), Image.NEAREST).save(sys.argv[1] if len(sys.argv) > 1 else "posturas.png")
