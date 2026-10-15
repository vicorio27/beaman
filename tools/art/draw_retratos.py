"""Retratos para los diálogos (assets/portraits/<id>.png): el que habla aparece de pie en el medio,
detrás del cuadro negro (ver Dialogue.gd). Bustos de 96x112, de tres cuartos, mirando a la derecha,
con fondo transparente.

Pixel art nítido, del mismo motor de las viñetas (tools/art/vinetas_motor.py): formas a 4x bajadas a
máscaras duras, tres tonos por material (sombra fría, base, luz cálida), tramado en el borde de la
sombra, y un contorno de tinta. La luz viene de arriba a la derecha; por la izquierda, un borde del
color de cada uno ("fondo"): se reconocen de lejos.

Cada cara se arma por partes con lo que dice el reparto (CAST): la forma (hombre, mujer, gordo, viejo,
niño), la piel, el pelo (corto, rizado, engominado, calvo, melena, largo, linda, cola, afro, hongo,
moño), barba, bigote, chivera, gafas, sombrero, y la ropa (saco, camiseta, delantal, chaleco, uniforme,
vestido, bata, sotana). Y el gesto: serios casi todos (ceño, párpado caído); "sonrisa", "destruido"
(ojeras, ojo rojo, barba de días), "ojos": "cerrados".
También iguales.png: el maniquí gris sin cara (todos iguales; lo usa retrato_iguales.gdshader).
Lukas también sale de aquí (lukas.png, y lukas_ladra.png: ladrando, con una oreja al aire).

Uso: python tools/art/draw_retratos.py [id ...]          (desde la carpeta del proyecto)
     python tools/art/draw_retratos.py --hoja salida.png [id ...]   una hoja para mirarlos de cerca
"""
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import vinetas_motor as vm  # noqa: E402

W, H = 96, 112
vm.set_size(W, H)
nb, mix, BAY = vm.nb, vm.mix, vm.BAY

OUT = Path("assets/portraits")
INK = (24, 17, 30)
SKINS = {
    "clara": ((166, 104, 100), (232, 184, 154), (250, 220, 196)),
    "media": ((138, 82, 70), (208, 152, 116), (238, 196, 160)),
    "morena": ((102, 58, 50), (172, 114, 82), (214, 160, 120)),
    "negra": ((58, 32, 34), (114, 70, 52), (164, 110, 82)),
}
EYE_WHITE = (236, 230, 220)


def tones(c, dark=0.6, light=1.2):
    """Tres tonos de un color: la sombra (más fría), la base y la luz (más cálida)."""
    d = mix(tuple(v * dark for v in c), (40, 30, 72), 0.2)
    lt = mix(tuple(min(255.0, v * light + 6) for v in c), (255, 240, 208), 0.14)
    return (tuple(int(v) for v in d), tuple(int(v) for v in c), tuple(int(v) for v in lt))


def edge(m, dx, dy, w):
    """Los píxeles de m que quedan a w o menos del borde, hacia (dx, dy)."""
    inner = m.copy()
    for i in range(1, w + 1):
        inner &= nb(m, dx * i, dy * i)
    return m & ~inner


class Bust:
    def __init__(self, p, seed):
        self.cv = vm.Cv()
        self.alpha = np.zeros((H, W), bool)
        self.p = p
        self.rng = np.random.default_rng(seed * 7 + 3)
        self.k = 0.88 if p.get("chiquita") else 1.0     # los bajitos: más chicos y más abajo
        self.ox, self.oy = W * (1 - self.k) / 2.0, H * (1 - self.k)
        self.ys, self.xs = np.mgrid[0:H, 0:W]
        self._fr = None

    def T(self, x, y):
        if self._fr is not None:  # dentro de un marco: a tantos píxeles del ancla, sin escala
            fx, fy, ax, ay = self._fr
            return (ax + int(round(x - fx)), ay + int(round(y - fy)))
        return (int(round(self.ox + x * self.k)), int(round(self.oy + y * self.k)))

    def frame(self, fx, fy):
        """Un marco para los detalles finos: lo que se dibuje adentro va alrededor de (fx, fy), píxel a píxel."""
        bust = self

        class _Frame:
            def __enter__(self_):
                bust._fr = None
                ax, ay = bust.T(fx, fy)
                bust._fr = (fx, fy, ax, ay)

            def __exit__(self_, *exc):
                bust._fr = None
        return _Frame()

    def ty(self, y):
        return self.oy + y * self.k

    def M(self, fn):
        return self.cv.mask(fn, self.ox, self.oy, False, self.k)

    def box(self, x0, y0, x1, y1):
        (a, b_), (c, d) = self.T(x0, y0), self.T(x1, y1)
        return self.cv.box(a, b_, c, d)

    def above(self, y):
        return self.ys < self.ty(y)

    def put(self, m, color):
        self.cv.a[m] = color
        self.alpha |= m

    def vol(self, m, t3, sw=3, lw=2, bottom=2, dither=True):
        """Una forma con volumen: luz de arriba a la derecha. t3 = (sombra, base, luz)."""
        dark, mid, light = t3
        self.put(m, mid)
        sh = edge(m, -1, 0, sw) | (edge(m, 0, 1, bottom) if bottom else np.zeros_like(m))
        if dither:
            band = (edge(m, -1, 0, sw + 2) | (edge(m, 0, 1, bottom + 1) if bottom else np.zeros_like(m))) & ~sh
            self.cv.a[band & (BAY < 0.5)] = dark
        self.cv.a[sh] = dark
        if lw:
            li = edge(m, 1, 0, lw) | edge(m, 0, -1, 1)
            self.cv.a[li & ~sh] = light
        return m

    def _draw(self, fn):
        img = Image.fromarray(self.cv.a)
        fn(ImageDraw.Draw(img))
        self.cv.a = np.asarray(img).copy()

    def line(self, pts, color, w=1):
        q = [self.T(x, y) for x, y in pts]
        self._draw(lambda d: d.line(q, fill=color, width=w))

    def rect(self, x0, y0, x1, y1, fill=None, outline=None):
        q = [self.T(x0, y0), self.T(x1, y1)]
        self._draw(lambda d: d.rectangle(q, fill=fill, outline=outline))

    def arc(self, x0, y0, x1, y1, a0, a1, color):
        q = [self.T(x0, y0), self.T(x1, y1)]
        self._draw(lambda d: d.arc(q, a0, a1, fill=color))

    def dot(self, x, y, color):
        self.cv.px(*self.T(x, y), color)

    def dots(self, pts, color):
        for x, y in pts:
            self.dot(x, y, color)

    def veil(self, m, color, k=0.5):
        self.cv.a[m & (BAY < k)] = color

    def result(self, fondo):
        """El contorno de tinta, el borde de color por la izquierda, y la transparencia."""
        a = self.alpha
        rim = a & ~nb(a, -1, 0) & (self.ys < H - 6)
        self.cv.a[rim] = mix(fondo, (255, 255, 255), 0.25)
        grown = a | nb(a, 1, 0) | nb(a, -1, 0) | nb(a, 0, 1) | nb(a, 0, -1)
        out = np.zeros((H, W, 4), np.uint8)
        out[..., :3] = self.cv.a
        out[..., 3] = np.where(a, 255, 0)
        ink = grown & ~a
        out[ink] = (*INK, 255)
        return Image.fromarray(out)


# ---------------------------------------------------------------- La forma de cada uno

def geom(p):
    """Las medidas de la cabeza y el cuerpo, según quién es."""
    g = {"cx": 48, "cy": 36, "rx": 21, "ry": 22, "eye_y": 42, "brow_y": 36, "nose": (62, 52), "mouth_y": 59, "mid": 56,
         "jaw": [(28.5, 40), (30, 53), (37, 63), (50, 69), (60, 67), (66, 58), (69, 46), (69.5, 36)],
         "neck": 17, "sh": 0, "eye_w": 5, "dy": 0}
    if p.get("mujer"):
        g.update(jaw=[(29.5, 40), (31, 52), (39, 62), (52, 68), (60, 65), (65, 57), (68, 46), (69, 36)], neck=14, sh=-5, dy=-3)
    if p.get("gordo"):
        g.update(rx=23, jaw=[(26, 40), (27, 56), (34, 67), (50, 72), (63, 70), (70, 60), (72.5, 46), (72, 36)], neck=22, sh=5)
    if p.get("nino"):
        g.update(jaw=[(29, 40), (31, 54), (39, 63), (51, 67), (60, 65), (66, 57), (69, 46), (69.5, 36)], neck=13, sh=-8, dy=-4,
                 eye_y=44, brow_y=38, nose=(61, 52), mouth_y=59, eye_w=5)
    return g


def head_mask(b, g):
    return b.M(lambda d: (d.ell(g["cx"], g["cy"], g["rx"], g["ry"]), d.poly(g["jaw"]),
                          d.ell(50, 70, 14, 5) if b.p.get("gordo") else None,
                          d.ell(36, 60, 6.5, 5.5) if b.p.get("viejo") and not b.p.get("mujer") else None))


def body_mask(b, g):
    s, y = g["sh"], g["dy"]
    return b.M(lambda d: (d.poly([(2 - s, 114), (6 - s, 97 + y), (18 - s, 88 + y), (38, 82 + y), (62, 82 + y), (80 + s, 88 + y), (91 + s, 98 + y), (94 + s, 114)]),
                          d.ell(20 - s, 97 + y, 16, 10), d.ell(78 + s, 98 + y, 15, 10), d.rect(4 - s, 100 + y, 92 + s, 114)))


# ---------------------------------------------------------------- El pelo

FACE_M = [(33, 41), (35, 30), (43, 25), (58, 24.5), (66, 28.5), (70.5, 37), (74, 74), (26, 74), (30, 50)]      # corto
FACE_HIGH = [(33, 41), (37, 27), (46, 21.5), (60, 21.5), (67, 27.5), (70.5, 37), (74, 74), (26, 74), (30, 50)]  # entradas
FACE_F = [(32.5, 43), (34, 31), (41, 25.5), (56, 24.5), (65.5, 28), (70.5, 38), (74, 74), (26, 74), (30, 50)]   # de mujer


def hair(b, g, front):
    """El pelo: lo de atrás (antes de la cabeza) o lo de adelante (encima). Devuelve lo que pintó."""
    p = b.p
    style = p.get("pelo", "corto")
    if style == "ninguno":
        return None
    c = p.get("pelo_color", (46, 38, 42))
    t3 = tones(c, 0.55, 1.35)
    cx, cy, rx, ry = g["cx"], g["cy"], g["rx"], g["ry"]
    face_poly = FACE_HIGH if style in ("engominado", "calvo") else (FACE_F if p.get("mujer") or p.get("nino") else FACE_M)
    face = b.M(lambda d: d.poly(face_poly))
    grow = {"rizado": 4.5, "afro": 0, "corto": 1.6, "engominado": 1.0}.get(style, 2.4)
    cap = b.M(lambda d: d.ell(cx, cy - 1, rx + grow, ry + grow)) & ~face
    m = np.zeros((H, W), bool)
    if not front:  # lo que cae por detrás de la cabeza y del cuello
        if style in ("melena", "largo", "linda"):
            low = {"melena": 78, "largo": 104, "linda": 106}[style]
            m = b.M(lambda d: (d.poly([(23, 34), (72, 30), (76, 60), (74, low), (60, low + 2), (36, low + 2), (22, low), (20, 60)]),
                               d.ell(48, 34, 26, 25)))
        elif style == "cola":
            m = b.M(lambda d: (d.path([(26, 28), (15, 44), (14, 66), (19, 84)], 9), d.ell(18, 86, 5, 4)))
        elif style == "afro":
            m = b.M(lambda d: d.ell(47, 31, 33, 30))
        elif style == "moño":
            m = b.M(lambda d: d.ell(25, 21, 9, 9))
        elif style == "hongo":
            m = b.M(lambda d: d.ell(47, 34, 28, 25))
        elif style == "rizado":
            m = b.M(lambda d: [d.ell(cx + np.cos(a) * 22, cy - 2 + np.sin(a) * 22, 6, 6) for a in np.linspace(3.3, 6.2, 9)])
        elif style == "calvo":
            m = b.M(lambda d: d.poly([(25, 37), (31, 33), (33, 50), (28, 54)]))
        if m.any():
            b.vol(m, t3, sw=3, lw=2)
        return m
    if style == "calvo":  # una franja encima de la oreja, y nada arriba
        m = b.M(lambda d: d.poly([(26.5, 36), (32, 33), (34, 40), (33, 47), (30, 40)]))
    elif style == "afro":
        m = b.M(lambda d: d.ell(47, 31, 33, 30)) & ~b.M(lambda d: d.poly([(32, 42), (35, 31), (43, 26), (57, 25.5), (65, 29), (70, 38), (76, 80), (22, 80), (29, 52)]))
    elif style == "hongo":  # el honguito: un casco hasta las cejas
        m = b.M(lambda d: d.ell(47, 31, 28, 22)) & ~b.M(lambda d: d.poly([(35, 38.5), (70, 38.5), (76, 80), (26, 80), (31, 46)]))
    elif style == "rizado":
        m = cap | (b.M(lambda d: [d.ell(cx + np.cos(a) * 21, cy - 2 + np.sin(a) * 21, 6, 6) for a in np.linspace(3.3, 6.2, 9)]) & ~face)
    else:
        m = cap
        if style in ("melena", "largo", "linda"):  # las cortinas a los lados
            low = {"melena": 76, "largo": 100, "linda": 104}[style]
            m = m | b.M(lambda d: (d.poly([(22, 36), (33, 30), (34.5, 44), (33, 60), (35, low), (22, low - 2), (19, 60)]),
                                   d.poly([(68, 34), (73, 40), (75, low - 6), (70, low - 4), (70.5, 46)])))
        if style == "linda":  # la capul
            m = m | b.M(lambda d: d.poly([(34, 30), (44, 24), (62, 25), (68, 31), (67, 35), (56, 32), (44, 33.5), (35, 37)]))
        if style in ("corto", "engominado", "rizado") and not p.get("mujer") and not p.get("nino"):
            m = m | b.M(lambda d: d.poly([(29.5, 38), (34, 38), (34, 46), (31, 49)]))        # la patilla
    b.vol(m, t3, sw=3, lw=2, bottom=0)
    # Los mechones: una luz que le da la vuelta a la cabeza, y sombras finas.
    shine = b.M(lambda d: d.ell(cx + 6, cy - 14, rx - 4, 5)) & ~b.M(lambda d: d.ell(cx + 5, cy - 11.5, rx - 3, 5)) & m
    b.cv.a[shine] = t3[2]
    if style == "engominado":
        for k in range(4):
            b.line([(38 + k * 7, 16 + (k % 2)), (33 + k * 8, 26)], t3[0])
    elif style in ("rizado", "afro"):
        ys, xs = np.nonzero(m)
        for i in b.rng.choice(len(ys), size=min(len(ys), 70), replace=False):
            b.cv.px(xs[i], ys[i], t3[0] if (xs[i] + ys[i]) % 4 else mix(t3[1], t3[2], 0.35))
    elif style in ("melena", "largo", "linda", "cola", "hongo", "moño"):
        for x0 in (24, 28, 72):
            xx = b.T(x0, 0)[0]
            for y in np.nonzero(m[:, xx])[0][::2]:
                b.cv.px(xx, y, t3[0])
    if p.get("implantes"):  # los implantes: salen a parches, en fila, con la piel irritada alrededor
        sk = SKINS[p.get("piel", "clara")]
        for k, (tx, ty) in enumerate(((38, 22), (44, 18), (51, 17), (58, 18), (64, 22), (41, 26), (48, 23), (55, 22), (61, 26),
                                      (46, 28), (53, 27), (36, 28))):
            if k in (3, 7, 10):      # los que no pegaron
                b.dot(tx, ty, mix(sk[1], (226, 120, 120), 0.5))
                continue
            b.dot(tx - 1, ty + 1, mix(sk[1], (226, 120, 120), 0.4))
            b.line([(tx, ty), (tx + (k % 2), ty - 2 - k % 2)], t3[1])
            b.dot(tx + 1, ty, t3[0])
    if p.get("raiz"):
        b.cv.a[edge(m, 0, -1, 4) & b.above(20)] = tones(p["raiz"])[1]
    if p.get("canas") or p.get("canas_afro"):
        k = float(p.get("canas", 0.2))
        ys, xs = np.nonzero(m)
        for i in range(len(ys)):
            if b.rng.random() < k * 0.5 or (p.get("canas_afro") and xs[i] < 30 and b.rng.random() < 0.22):
                b.cv.px(xs[i], ys[i], mix(t3[2], (204, 202, 198), 0.6))
    return m


def hat(b, g):
    p = b.p
    kind = p.get("sombrero")
    if not kind:
        return
    t3 = tones(p.get("sombrero_color", (90, 70, 50)), 0.6, 1.25)
    if kind == "gorra":
        dome = b.M(lambda d: d.ell(47, 24, 24, 15)) & b.above(29)
        b.vol(dome, t3, sw=4, lw=2, bottom=1)
        b.vol(b.M(lambda d: d.poly([(56, 25), (86, 30), (86, 33.5), (56, 30.5)])), t3, sw=0, lw=1, bottom=1, dither=False)
        b.line([(24, 28), (58, 29)], t3[0])
    elif kind == "sombrero":
        b.vol(b.M(lambda d: d.ell(48, 27, 37, 6.5)), t3, sw=4, lw=2, bottom=2)
        crown = b.M(lambda d: (d.rect(30, 8, 66, 26), d.ell(48, 9, 18, 5)))
        b.vol(crown, t3, sw=4, lw=2, bottom=0)
        b.put(b.M(lambda d: d.rect(30, 20, 66, 24)) & crown, tones(p.get("cinta", t3[0]))[1] if p.get("cinta") else t3[0])
    elif kind == "boina":
        b.vol(b.M(lambda d: (d.ell(45, 20, 27, 10), d.ell(60, 17, 12, 7))), t3, sw=4, lw=2, bottom=1)
        b.dot(47, 9, t3[0])
        b.dot(47, 10, t3[0])
    elif kind == "pañoleta":
        m = b.M(lambda d: d.ell(47, 25, 25, 17)) & b.above(33)
        b.vol(m | b.M(lambda d: d.poly([(22, 30), (14, 44), (22, 46), (28, 36)])), t3, sw=3, lw=2, bottom=1)
        for k in range(6):
            b.dot(30 + k * 7, 18 + (k % 2) * 6, t3[2])


# ---------------------------------------------------------------- La cara

def eye(b, g, ex, ey, w, near, sk):
    p = b.p
    dark, mid, light = sk
    tired = p.get("destruido") or p.get("ojeras")
    b.veil(b.M(lambda d: d.ell(ex, ey - 2.5, w + 2, 2.8)), dark, 0.3)              # la sombra de la ceja
    if p.get("ojos") == "cerrados":
        b.line([(ex - w, ey), (ex - w + 2, ey + 1), (ex + w - 3, ey + 1), (ex + w - 1, ey)], INK)
        b.line([(ex - w + 2, ey + 3), (ex + w - 3, ey + 3)], mix(mid, dark, 0.6))
        return
    white = EYE_WHITE if not p.get("destruido") else (240, 208, 202)
    rows = 3 if p.get("nino") or p.get("ojos_grandes") else 2
    for r in range(rows):
        cut_ = 1 if r == rows - 1 else 0
        b.line([(ex - w + 1 + cut_, ey + r), (ex + w - 2 - cut_, ey + r)], white)
    # El iris, mirando a donde da la cara. La pupila y el brillo.
    iris = p.get("ojo_color", (74, 46, 32))
    iw = 3 if near else 2
    ix = ex if near else ex - 1
    for r in range(rows):
        b.line([(ix, ey + r), (ix + iw - 1, ey + r)], iris)
    px_ = ix + 1 if near else ix + 1
    b.line([(px_, ey), (px_, ey + rows - 1)], mix(iris, (0, 0, 0), 0.75))
    b.dot(ix, ey, (255, 255, 255))
    # El párpado de arriba, en tinta; la esquina de afuera.
    b.line([(ex - w, ey - 1), (ex + w - 1, ey - 1)], INK)
    b.dot(ex - w if near else ex + w - 1, ey, INK)
    if tired or p.get("viejo"):  # el párpado, que pesa
        b.line([(ex - w + 1, ey - 2), (ex + w - 2, ey - 2)], mix(mid, dark, 0.8))
    else:
        b.line([(ex - w + 1, ey - 3), (ex + w - 2, ey - 3)], mix(mid, dark, 0.35))
    b.line([(ex - w + 3, ey + rows), (ex + w - 3, ey + rows)], mix(mid, dark, 0.4))
    if tired:  # la ojera
        b.line([(ex - w + 1, ey + rows + 2), (ex, ey + rows + 3), (ex + w - 2, ey + rows + 2)], mix(dark, (96, 66, 120), 0.4))
    if p.get("mujer") and not p.get("viejo"):  # las pestañas
        b.dot(ex - w - 1, ey - 2, INK)
        b.dot(ex + w, ey - 2, INK)


def brow(b, g, ex, by, w, near, color):
    p = b.p
    thick = 1 if (p.get("mujer") or p.get("nino")) else 2
    # El ceño: la punta de adentro, más abajo. Con sonrisa, parejas y arriba. Destruido: caídas hacia afuera.
    inner = 1 if not p.get("sonrisa") else -1
    if p.get("destruido"):
        inner = -1
    x_in, x_out = (ex + w + 1, ex - w - 1) if near else (ex - w, ex + w + 1)
    for k in range(thick):
        b.line([(x_out, by - inner + k), ((x_in + x_out) // 2, by - 1 + k), (x_in, by + inner + k)], color)


def face(b, g, head, sk):
    p = b.p
    dark, mid, light = sk
    ey, by, my, mid_x = g["eye_y"], g["brow_y"], g["mouth_y"], g["mid"]
    nx, ny = g["nose"]
    w = g["eye_w"]
    hairc = p.get("pelo_color", (46, 38, 42)) if p.get("pelo") != "ninguno" else (60, 50, 50)
    browc = mix(p.get("barba_color", hairc) if p.get("viejo") else hairc, INK, 0.35)
    # Los planos de la cara: el pómulo de allá con luz, la sien y la mejilla de acá en sombra.
    b.cv.a[b.M(lambda d: d.ell(66, 50, 4, 7)) & head] = light
    b.veil(b.M(lambda d: d.ell(36, 54, 6, 8)) & head, dark, 0.4)
    if p.get("cachetes"):
        b.veil(b.M(lambda d: (d.ell(40, 52, 5, 3.2), d.ell(64, 52, 3.5, 3))) & head, (236, 130, 130), 0.5)
    if p.get("viejo"):  # la frente, marcada
        for yy, x0, x1 in ((28, 41, 63), (31, 40, 65)):
            b.line([(x0, yy), ((x0 + x1) // 2, yy - 1), (x1, yy)], mix(mid, dark, 0.75))
    # Los ojos y las cejas.
    for ex, ww, near in ((44, w, True), (63, w - 1, False)):
        with b.frame(ex, ey):
            eye(b, g, ex, ey, ww, near, sk)
            brow(b, g, ex, by, ww - 1, near, browc)
    if p.get("viejo") or p.get("destruido"):
        b.line([(37, ey + 2), (36, ey + 4)], mix(mid, dark, 0.5))                 # las patas de gallo
    # La nariz: el puente con luz, el contorno del lado de allá, la sombra debajo.
    b._fr = None
    ax, ay = b.T(nx, ny)
    b._fr = (nx, ny, ax, ay)
    soft = p.get("mujer") or p.get("nino")
    b.line([(mid_x, ey + 2), (nx - 3, ny - 3)], light, 2)
    b.line([(mid_x - 2, ey + 3), (nx - 6, ny - 2)], mix(mid, dark, 0.55))          # el lado en sombra
    contour = mix(dark, INK, 0.3) if soft else mix(dark, INK, 0.75)
    b.line([(nx - 1, ny - 4), (nx, ny - 1), (nx - 1, ny + 1), (nx - 3, ny + 2)], contour)   # la punta
    b.line([(nx - 7, ny + 2), (nx - 3, ny + 2)], mix(dark, INK, 0.25))
    b.dot(nx - 5, ny + 1, INK)                                                     # la fosa
    b.line([(nx - 9, ny - 1), (nx - 9, ny + 1)], dark)                             # la aleta de acá
    if p.get("gordo") or p.get("nariz_roja"):
        b.cv.a[b.M(lambda d: d.ell(nx - 2.5, ny - 0.5, 3.2, 2.8)) & head] = light
    if p.get("nariz_roja"):
        b.veil(b.M(lambda d: d.ell(nx - 3, ny - 1, 4, 3.4)) & head, (222, 120, 110), 0.5)
    if p.get("viejo") or p.get("gordo"):  # los surcos
        b.line([(nx - 10, ny + 2), (nx - 12, ny + 6), (nx - 12, ny + 8)], mix(mid, dark, 0.5))
    if p.get("pecas"):
        b.dots([(40, 49), (43, 51), (46, 49), (52, 48), (64, 49), (66, 51), (38, 51)], mix(mid, (150, 80, 50), 0.6))
    if p.get("cicatriz"):
        b.line([(38, 33), (41, 40)], mix(light, (255, 200, 200), 0.5))
        b.line([(39, 33), (42, 40)], mix(dark, (150, 60, 70), 0.5))
    # La boca.
    b._fr = None
    ax, ay = b.T(mid_x, my)
    b._fr = (mid_x, my, ax, ay)
    x0, x1 = mid_x - 8, mid_x + 6
    lips = p.get("labios")
    if p.get("sonrisa"):
        b.line([(x0 - 1, my - 1), (x0 + 2, my + 1), (x1 - 2, my + 1), (x1 + 1, my - 1)], INK)
        b.line([(x0 - 2, my - 3), (x0 - 3, my)], mix(mid, dark, 0.8))
        if lips:
            b.line([(x0 + 2, my + 2), (x1 - 2, my + 2)], lips)
    else:
        b.line([(x0, my + 1), (x0 + 1, my), (x1 - 1, my), (x1, my + 1)], INK)
        if lips:
            b.line([(x0 + 2, my - 1), (x1 - 2, my - 1)], mix(lips, dark, 0.3))
            b.line([(x0 + 2, my + 1), (x1 - 2, my + 1)], lips)
            b.line([(x0 + 3, my + 2), (x1 - 3, my + 2)], lips)
            b.dot(mid_x + 1, my + 1, mix(lips, (255, 255, 255), 0.45))
    if p.get("dientes"):  # los dientes, torcidos: uno montado, uno amarillo, un hueco
        b.rect(x0 + 2, my, x1 - 2, my + 3, fill=(244, 238, 222), outline=INK)
        for tx, tall in ((x0 + 4, 2), (x0 + 7, 3), (x0 + 9, 1), (x1 - 4, 2)):
            b.line([(tx, my + 1), (tx, my + tall)], mix(INK, (120, 100, 90), 0.4))
        b.dot(x0 + 5, my + 2, (226, 204, 130))
        b.dot(x0 + 8, my + 3, (244, 238, 222))
        b.dot(x1 - 5, my + 1, INK)
    elif not lips:
        b.line([(x0 + 4, my + 3), (x1 - 3, my + 3)], mix(mid, dark, 0.45))         # el labio de abajo
    b._fr = None
    if p.get("arete"):
        b.dot(29, 53, (250, 214, 110))
        b.dot(29, 54, (250, 214, 110))


def facial_hair(b, g, head):
    p = b.p
    c = p.get("barba_color", p.get("pelo_color", (46, 38, 42)))
    t3 = tones(c, 0.6, 1.25)
    my, mid_x = g["mouth_y"], g["mid"]
    grown = head | nb(head, 0, -1) | nb(head, 1, 0) | nb(head, -1, 0) | nb(head, 0, 1)   # un poco más que la quijada
    grown = grown | nb(grown, 0, -1)
    lips = b.M(lambda d: d.rect(mid_x - 7, my - 0.5, mid_x + 6, my + 2.5))
    m = np.zeros((H, W), bool)
    if p.get("barba"):
        m = b.M(lambda d: d.poly([(28, 42), (33.5, 43), (35, 52), (41, 58), (47, 55), (53, 53.5), (61, 53.5), (66, 56), (68, 48),
                                  (72, 47), (73, 62), (64, 73), (50, 76), (36, 71), (28, 60)])) & grown & ~lips
    elif p.get("chivera"):
        m = b.M(lambda d: (d.ell(mid_x - 1, my + 8, 8, 6.5), d.poly([(mid_x - 9, my - 1), (mid_x - 4, my - 4.5), (mid_x + 4, my - 4.5),
                                                                       (mid_x + 8, my - 1), (mid_x + 6, my + 6), (mid_x - 8, my + 6)]))) & grown & ~lips
    if p.get("bigote") and not p.get("barba"):
        m = m | (b.M(lambda d: d.poly([(mid_x - 10, my + 0.5), (mid_x - 5, my - 4.5), (mid_x + 4, my - 4.5), (mid_x + 9, my),
                                       (mid_x + 8, my + 2), (mid_x + 3, my - 1.2), (mid_x - 4, my - 1.2), (mid_x - 9, my + 2.5)])) & grown)
    if m.any():
        b.vol(m, t3, sw=2, lw=1, bottom=1)
        ys, xs = np.nonzero(m)
        for i in range(len(ys)):
            r = b.rng.random()
            if r < 0.07:
                b.cv.px(xs[i], ys[i], mix(t3[1], t3[0], 0.6))
            elif r < 0.13:
                b.cv.px(xs[i], ys[i], mix(t3[1], t3[2], 0.6))
        if p.get("barba"):
            with b.frame(mid_x, my):
                b.line([(mid_x - 7, my + 1), (mid_x - 6, my), (mid_x + 5, my), (mid_x + 6, my + 1)], INK)   # la boca, entre la barba
    elif p.get("destruido") and not p.get("mujer"):  # barba de días
        st = b.M(lambda d: d.poly([(30, 50), (36, 54), (44, 56), (60, 55), (68, 50), (70, 60), (62, 70), (50, 72), (36, 68), (29, 58)])) & head & ~lips
        b.veil(st, mix(SKINS[p.get("piel", "clara")][0], (60, 56, 70), 0.5), 0.3)


def glasses(b, g):
    kind = b.p.get("gafas")
    if not kind:
        return
    ey = g["eye_y"]
    b._fr = None
    ax, ay = b.T(52, ey)
    b._fr = (52, ey, ax, ay)
    near = (37, ey - 5, 51, ey + 5)
    far = (57, ey - 5, 68, ey + 5)
    for (x0, y0, x1, y1) in (near, far):
        if kind == "oscuras":
            b.rect(x0, y0, x1, y1, fill=(28, 24, 38), outline=INK)
            b.line([(x0 + 2, y0 + 2), (x0 + 5, y0 + 2)], (110, 116, 150))
            b.line([(x0 + 2, y0 + 4), (x0 + 3, y0 + 4)], (70, 74, 104))
        else:
            b.rect(x0, y0, x1, y1, outline=INK)
            b.line([(x0 + 2, y0 + 3), (x0 + 4, y0 + 1)], (255, 255, 255))
            b.dot(x1 - 2, y1 - 2, (236, 240, 250))
    b.line([(51, ey - 2), (57, ey - 2)], INK)
    b.line([(37, ey - 2), (30, ey - 3)], INK)
    b._fr = None


# ---------------------------------------------------------------- La ropa

def clothes(b, g, body):
    p = b.p
    kind = p.get("tipo", "camiseta")
    c = p.get("ropa", (120, 120, 130))
    t3 = tones(c, 0.6, 1.2)
    sk = SKINS[p.get("piel", "clara")]
    shirt = p.get("camisa", (226, 220, 206))
    ys, xs = b.ys, b.xs
    y = g["dy"]
    if kind == "chaleco":
        b.vol(body, tones(p.get("mangas", shirt)), sw=4, lw=2, bottom=0)
        vest = body & b.M(lambda d: d.poly([(24, 84 + y), (40, 80 + y), (50, 114), (60, 80 + y), (74, 84 + y), (80, 114), (18, 114)]))
        b.vol(vest, t3, sw=3, lw=1, bottom=0)
    else:
        b.vol(body, t3, sw=5, lw=2, bottom=0)
    if kind in ("saco", "bata", "chaleco", "uniforme"):
        vee = b.M(lambda d: d.poly([(40, 82 + y), (60, 82 + y), (56, 104), (50, 114), (45, 104)])) & body
        b.vol(vee, tones(shirt), sw=2, lw=1, bottom=0)
        if kind in ("saco", "bata"):  # las solapas
            lap = b.M(lambda d: (d.poly([(36, 82 + y), (41, 82 + y), (46, 104), (42, 108), (30, 92 + y)]), d.poly([(59, 82 + y), (64, 82 + y), (70, 92 + y), (58, 108), (54, 104)]))) & body
            b.vol(lap, tones(c, 0.5, 1.28), sw=1, lw=1, bottom=1, dither=False)
        tie = p.get("corbata")
        if tie:
            tt = tones(tie)
            b.put(b.M(lambda d: (d.poly([(47, 84 + y), (53, 84 + y), (52, 89 + y), (48, 89 + y)]), d.poly([(48, 89 + y), (52, 89 + y), (54, 108), (50, 114), (46, 108)]))), tt[1])
            b.line([(48, 90 + y), (47, 108)], tt[0])
            b.line([(52, 90 + y), (53, 106)], tt[2])
        else:
            b.line([(50, 86 + y), (50, 111)], tones(shirt)[0])
            for yy in (92, 100, 108):
                b.dot(51, yy, tones(shirt)[0])
        if kind == "uniforme":
            b.put(b.M(lambda d: (d.poly([(38, 82 + y), (47, 84 + y), (42, 92 + y)]), d.poly([(62, 82 + y), (53, 84 + y), (58, 92 + y)]))), tones(shirt)[2])
            b.put(b.box(66, 92, 73, 99), (232, 200, 110))                               # la placa
            b.dot(69, 95, (150, 120, 60))
            b.put(b.M(lambda d: (d.rect(10, 86, 24, 89), d.rect(72, 86, 86, 89))) & body, t3[0])
        if kind == "bata":
            b.put(b.box(62, 98, 74, 99), t3[0])
            b.put(b.box(70, 92, 71, 98), (60, 90, 170))                                 # el esfero
    elif kind == "camiseta":
        b.put(b.M(lambda d: d.ell(50, 82 + y, 12, 6)) & body, sk[1])
        b.cv.a[edge(b.M(lambda d: d.ell(50, 82 + y, 13.5, 7.5)) & body, 0, 1, 2) & ~b.above(82 + y)] = t3[0]
    elif kind == "vestido":
        b.put(b.M(lambda d: d.ell(50, 82 + y, 19, 10)) & body, sk[1])
        b.cv.a[b.M(lambda d: d.ell(44, 88 + y, 6, 2)) & body] = sk[0]
        b.cv.a[edge(b.M(lambda d: d.ell(50, 82 + y, 20.5, 11.5)) & body, 0, 1, 2) & ~b.above(84 + y)] = t3[2]
    elif kind == "delantal":
        b.put(b.M(lambda d: d.ell(50, 82 + y, 11, 5)) & body, sk[1])
        ap = tones(p.get("delantal", (236, 232, 222)))
        bib = b.M(lambda d: (d.rect(34, 93 + y, 66, 114), d.poly([(34, 93 + y), (30, 83 + y), (34, 82 + y), (39, 93 + y)]), d.poly([(66, 93 + y), (70, 83 + y), (66, 82 + y), (61, 93 + y)]))) & body
        b.vol(bib, ap, sw=2, lw=1, bottom=0)
        if p.get("cuadros"):
            b.cv.a[bib & ((xs // 4 + ys // 4) % 2 == 0)] = ap[0]
    elif kind == "sotana":
        b.put(b.M(lambda d: d.rect(45, 82 + y, 55, 87 + y)) & body, (240, 240, 236))
        for yy in range(92, 112, 6):
            b.dot(50, yy, t3[2])
    if p.get("chal"):
        ch = tones(p["chal"])
        b.vol(b.M(lambda d: (d.poly([(4, 100 + y), (18, 86 + y), (40, 81 + y), (48, 96 + y), (34, 114), (2, 114)]), d.poly([(60, 81 + y), (82, 88 + y), (92, 100 + y), (94, 114), (64, 114), (54, 96 + y)]))) & body,
              ch, sw=3, lw=1, bottom=0)
    if p.get("cadena"):
        gold = (240, 204, 96)
        b.arc(38, 74 + g["dy"], 62, 98 + g["dy"], 20, 160, gold)
        b.dot(50, 98, gold)
        b.dot(50, 99, (255, 240, 170))
    if p.get("guitarra"):
        b.line([(22, 86), (70, 112)], (90, 60, 40), 3)
        b.line([(22, 85), (70, 111)], (150, 104, 66))
    if p.get("flor"):
        fc = p["flor"]
        b.put(b.M(lambda d: d.ell(70, 92, 4, 4)), fc)
        b.dot(70, 92, (250, 220, 110))
        b.dot(68, 96, (70, 120, 70))


# ---------------------------------------------------------------- El busto completo

def portrait(p, seed=0):
    b = Bust(p, seed)
    g = geom(p)
    sk = SKINS[p.get("piel", "clara")] if isinstance(p.get("piel", "clara"), str) else p["piel"]
    hair(b, g, front=False)
    body = body_mask(b, g)
    clothes(b, g, body)
    # El cuello, con la sombra de la quijada.
    neck = b.M(lambda d: d.cap(47.5, 62, 49.5, 85, g["neck"]))
    b.vol(neck, sk, sw=3, lw=1, bottom=0)
    b.cv.a[neck & b.above(74)] = sk[0]
    b.veil(neck & ~b.above(74) & b.above(78), sk[0], 0.5)
    if p.get("tipo") in ("saco", "bata", "chaleco", "uniforme", "sotana"):
        y = g["dy"]
        collar = b.M(lambda d: (d.poly([(38, 80 + y), (46, 76 + y), (50, 86 + y), (42, 90 + y)]), d.poly([(62, 80 + y), (54, 76 + y), (50, 86 + y), (58, 90 + y)])))
        if p.get("tipo") != "sotana":
            b.vol(collar, tones(p.get("camisa", (226, 220, 206))), sw=1, lw=1, bottom=1, dither=False)
    # La oreja de acá y la cabeza.
    ear = b.M(lambda d: d.ell(29.5, 45.5, 4.2, 6.6))
    b.vol(ear, sk, sw=1, lw=0, bottom=1, dither=False)
    b.cv.a[b.M(lambda d: d.ell(29.8, 45.5, 1.8, 3.8))] = sk[0]
    head = head_mask(b, g)
    b.vol(head, sk, sw=4, lw=2, bottom=2)
    face(b, g, head, sk)
    facial_hair(b, g, head)
    hair(b, g, front=True)
    if p.get("audifonos"):
        b.vol(b.M(lambda d: d.ell(48, 34, 26, 26)) & ~b.M(lambda d: d.ell(48, 36, 23.5, 25)) & b.above(40), tones((60, 60, 70)), sw=1, lw=1, bottom=0, dither=False)
        b.vol(b.M(lambda d: d.ell(28.5, 45, 5.5, 8)), tones((70, 180, 190)), sw=2, lw=1)
    hat(b, g)
    glasses(b, g)
    if p.get("moño_pelo"):
        bow = tones(p["moño_pelo"])
        b.vol(b.M(lambda d: (d.poly([(26, 14), (35, 19), (26, 25)]), d.poly([(44, 14), (35, 19), (44, 25)]))), bow, sw=1, lw=1, bottom=1, dither=False)
        b.dot(35, 19, bow[0])
    return b.result(p.get("fondo", (120, 120, 140)))


def mannequin():
    """Todos iguales: gris, sin cara."""
    p = {"piel": ((96, 96, 106), (166, 166, 176), (212, 212, 220)), "pelo": "ninguno", "ropa": (132, 132, 142), "tipo": "camiseta"}
    b = Bust(p, 99)
    g = geom(p)
    sk = p["piel"]
    body = body_mask(b, g)
    b.vol(body, tones(p["ropa"]), sw=5, lw=2, bottom=0)
    neck = b.M(lambda d: d.cap(47.5, 62, 49.5, 85, g["neck"]))
    b.vol(neck, sk, sw=3, lw=1, bottom=0)
    b.cv.a[neck & b.above(74)] = sk[0]
    b.vol(b.M(lambda d: d.ell(29.5, 45.5, 4.2, 6.6)), sk, sw=1, lw=0, bottom=1, dither=False)
    b.vol(head_mask(b, g), sk, sw=5, lw=2, bottom=2)
    return b.result((150, 150, 164))


## Las caras de Lukas: el retrato de cada reacción (lukas_<modo>.png; "normal" es lukas.png).
LUKAS_MODOS = ["normal", "ladra", "feliz", "come", "pelota", "escucha", "triste", "huele", "enfermo", "truco"]


def lukas(mode="normal"):
    """Lukas: beagle tricolor, de tres cuartos, con su collar. mode: cómo reacciona (LUKAS_MODOS)."""
    if mode is True:
        mode = "ladra"
    elif mode is False:
        mode = "normal"
    b = Bust({}, 5)
    tan, ear, black, white = tones((214, 138, 74)), tones((150, 86, 48)), tones((52, 46, 50), 0.6, 1.5), tones((246, 240, 228), 0.72, 1.0)
    if mode == "enfermo":  # pálido: el color se le va
        tan, ear = tones((188, 140, 104)), tones((136, 96, 70))
    # El cuerpo: el lomo negro, el pecho blanco.
    body = b.M(lambda d: d.poly([(10, 114), (16, 88), (32, 74), (60, 76), (76, 92), (82, 114)]))
    b.vol(body, tan, sw=4, lw=2, bottom=0)
    b.vol(b.M(lambda d: d.poly([(10, 114), (16, 88), (30, 76), (36, 96), (34, 114)])) & body, black, sw=3, lw=1, bottom=0)
    b.vol(b.M(lambda d: d.poly([(44, 78), (62, 78), (74, 94), (78, 114), (46, 114)])) & body, white, sw=2, lw=1, bottom=0)
    # El collar, con la plaquita.
    leather = tones((176, 100, 58))
    b.vol(b.M(lambda d: d.poly([(28, 72), (64, 75), (65, 83), (29, 81)])), leather, sw=2, lw=1, bottom=1, dither=False)
    b.vol(b.M(lambda d: d.ell(52, 87, 3.8, 3.8)), tones((204, 206, 218)), sw=1, lw=1, bottom=1, dither=False)
    b.dot(52, 87, (120, 122, 136))
    if mode == "come":  # la coca, abajo
        bowl = tones((176, 180, 192))
        b.vol(b.M(lambda d: (d.ell(66, 104, 20, 7), d.rect(46, 96, 86, 104))), bowl, sw=2, lw=1, bottom=1, dither=False)
        for k in range(7):
            b.dot(54 + k * 4, 97 + (k % 2), (150, 96, 54))
    lift = {"ladra": -3, "huele": -6, "come": 9, "triste": 4, "enfermo": 3, "truco": -2}.get(mode, 0)
    shift = 2 if mode == "escucha" else 0      # la cabeza, ladeada
    # La oreja de allá (apenas se ve), la cabeza, el hocico.
    b.vol(b.M(lambda d: d.ell(58 + shift, 26 + lift - shift, 7, 9)), ear, sw=2, lw=1, bottom=0)
    head = b.M(lambda d: (d.ell(44, 42 + lift, 22, 21), d.poly([(40, 56 + lift), (70, 44 + lift - shift), (72, 62 + lift - shift), (48, 68 + lift)])))
    b.vol(head, tan, sw=4, lw=2, bottom=2)
    muzzle = b.M(lambda d: (d.ell(66, 53 + lift - shift, 16, 10.5), d.poly([(52, 24 + lift), (59, 25 + lift), (64, 46 + lift), (54, 48 + lift)])))
    b.vol(muzzle, white, sw=2, lw=1, bottom=2)
    b.vol(b.M(lambda d: d.ell(80, 48.5 + lift - shift, 4.6, 4)), black, sw=1, lw=1, bottom=1, dither=False)   # la nariz
    b.dot(81, 47 + lift - shift, (236, 236, 244))
    y = lift
    # La boca.
    if mode == "ladra":
        b.vol(b.M(lambda d: d.poly([(58, 60), (78, 56), (77, 70), (62, 72)])), white, sw=2, lw=1, bottom=2)   # la quijada, abierta
        b.put(b.M(lambda d: d.poly([(60, 58), (79, 53), (76, 63), (63, 65)])), (110, 36, 46))
        b.put(b.M(lambda d: d.ell(70, 62.5, 5.5, 2.6)), (236, 120, 132))
        for xx in (64, 68, 72, 76):
            b.dot(xx, 57 - (xx - 64) // 4, (255, 255, 250))
    elif mode in ("feliz", "truco"):  # la boca abierta, la lengua afuera
        b.put(b.M(lambda d: d.poly([(62, 60 + y), (78, 57 + y), (76, 64 + y), (64, 65 + y)])), (110, 36, 46))
        b.vol(b.M(lambda d: d.ell(70, 67 + y, 5, 5.5)), tones((236, 120, 132)), sw=1, lw=1, bottom=1, dither=False)
        b.line([(70, 63 + y), (70, 70 + y)], (200, 90, 100))
    elif mode == "pelota":  # la pelota de trapo, en la boca
        b.line([(62, 61 + y), (70, 62 + y), (79, 58 + y)], mix(white[0], INK, 0.5))
        ball = tones((206, 70, 70))
        b.vol(b.M(lambda d: d.ell(74, 63 + y, 8, 7)), ball, sw=2, lw=1, bottom=1, dither=False)
        b.line([(68, 60 + y), (80, 66 + y)], (240, 230, 220))
        b.line([(70, 57 + y), (78, 68 + y)], (240, 230, 220))
    elif mode == "come":
        b.line([(62, 61 + y), (70, 63 + y), (79, 59 + y)], mix(white[0], INK, 0.5))
        b.put(b.M(lambda d: d.ell(78, 63 + y, 2.5, 1.5)), (236, 120, 132))   # la lengua, lamiendo
    else:
        b.line([(62, 61 + y - shift), (70, 62 + y - shift), (79, 58 + y - shift)], mix(white[0], INK, 0.5))
    # Las orejas: caída, o al aire.
    if mode in ("ladra", "escucha", "truco"):
        b.vol(b.M(lambda d: d.poly([(24, 36 + y), (6, 14 + y), (30, 26 + y)])), ear, sw=2, lw=1, bottom=1)
    else:
        droop = {"triste": 6, "enfermo": 5}.get(mode, 0)
        b.vol(b.M(lambda d: d.ell(26, 55 + y + droop, 10.5, 21)), ear, sw=3, lw=2, bottom=2)
    # Los ojos.
    if mode in ("ladra", "feliz", "huele", "come"):  # cerrados: apretados, o de gusto
        b.line([(48, 37 + y), (52, 35 + y), (56, 37 + y)] if mode == "feliz" else [(48, 37 + y), (52, 39 + y), (56, 37 + y)], INK)
    elif mode == "enfermo":  # medio cerrados
        b.put(b.M(lambda d: d.ell(51.5, 42 + y, 3.4, 2.0)), (30, 20, 22))
        b.line([(47, 40 + y), (56, 40 + y)], tan[0])
        b.dot(66, 43 + y, (30, 20, 22))
        b.put(b.M(lambda d: d.ell(34, 32 + y, 1.6, 2.6)), (150, 200, 240))   # una gota de sudor
    else:
        up = -1 if mode == "triste" else 0
        b.put(b.M(lambda d: d.ell(51.5, 41 + y + up - shift, 3.4, 3.6)), (30, 20, 22))
        b.dot(50, 40 + y + up - shift, (255, 255, 255))
        b.dot(51, 39 + y + up - shift, (255, 255, 255))
        b.line([(48, 45 + y - shift), (55, 45 + y - shift)], tan[0])
        b.put(b.M(lambda d: d.ell(67, 41 + y - shift, 1.8, 2.6)), (30, 20, 22))
        if mode == "triste":  # la ceja, de pena
            b.line([(48, 36 + y), (55, 34 + y)], tan[0])
    b.put(b.M(lambda d: d.ell(53, 34 + lift, 2.2, 1.4)), tan[2])                                       # la ceja
    # Lo de alrededor: el ladrido, el olfato, la pregunta, el truco.
    gold = (250, 226, 120)
    if mode == "ladra":
        for (x0, y0, x1, y1) in ((86, 40, 92, 36), (87, 50, 94, 50), (86, 60, 92, 64)):
            b.put(b.M(lambda d: d.cap(x0, y0, x1, y1, 1.6)), gold)
    elif mode == "huele":
        for k in range(3):
            b.put(b.M(lambda d: d.path([(88, 46 + y - k * 6), (91, 43 + y - k * 6), (88, 40 + y - k * 6)], 1.4)), (200, 220, 240))
    elif mode == "escucha":
        b.put(b.M(lambda d: (d.path([(84, 18), (88, 15), (91, 18), (88, 22), (88, 25)], 1.8), d.ell(88, 29, 1.2, 1.2))), gold)
    elif mode == "truco":
        for (x0, y0) in ((86, 22), (12, 70), (84, 70)):
            b.put(b.M(lambda d: (d.cap(x0 - 3, y0, x0 + 3, y0, 1.4), d.cap(x0, y0 - 3, x0, y0 + 3, 1.4))), gold)
    return b.result((240, 200, 120) if mode != "enfermo" else (170, 190, 220))


# ---------------------------------------------------------------- El reparto
M = {"mujer": True}
CAST = {
    # Él: pelo negro, chaqueta gris, camisa roja. Ojeras.
    # Él: ya no es joven. Barba tupida, canas en la barba y las sienes, la frente marcada.
    "el": {"destruido": True, "cicatriz": True, "viejo": True, "piel": "media", "pelo": "corto",
           "pelo_color": (40, 34, 34), "canas": 0.12, "barba": True, "bigote": True, "barba_color": (58, 50, 48),
           "ropa": (82, 86, 106), "tipo": "saco", "camisa": (206, 200, 184), "corbata": (206, 48, 52),
           "fondo": (60, 90, 140), "ojeras": True},  # como en el mapa: saco gris grande, corbata roja floja
    "german": {"piel": "clara", "pelo": "calvo", "pelo_color": (190, 186, 180), "bigote": True, "viejo": True,
               "barba_color": (200, 196, 190), "ropa": (200, 176, 136), "tipo": "delantal", "delantal": (238, 234, 226),
               "fondo": (170, 120, 60), "sonrisa": True},
    "rosa": {**M, "piel": "morena", "pelo": "moño", "pelo_color": (36, 30, 36), "ropa": (232, 226, 214),
             "tipo": "delantal", "delantal": (196, 58, 56), "cuadros": True, "labios": (150, 60, 60), "viejo": True,
             "fondo": (190, 70, 60), "arete": True},
    "marta": {**M, "piel": "clara", "pelo": "cola", "pelo_color": (98, 62, 42), "ropa": (214, 168, 64),
              "tipo": "delantal", "delantal": (44, 40, 46), "labios": (178, 84, 84), "fondo": (120, 80, 50), "ojeras": True},
    "wilson": {"destruido": True, "piel": "morena", "pelo": "corto", "sombrero": "gorra", "sombrero_color": (66, 112, 70),
               "ropa": (232, 120, 40), "tipo": "chaleco", "camisa": (130, 128, 124), "mangas": (130, 128, 124),
               "fondo": (70, 110, 70), "sonrisa": True},
    "samuel": {"destruido": True, "piel": "media", "pelo": "corto", "pelo_color": (150, 146, 140), "barba": True,
               "barba_color": (200, 196, 190), "viejo": True, "sombrero": "gorra", "sombrero_color": (150, 50, 40),
               "ropa": (110, 84, 60), "tipo": "saco", "camisa": (70, 66, 64), "fondo": (100, 80, 60)},
    "victoria": {"nino": True, **M, "piel": "clara", "pelo": "largo", "pelo_color": (70, 44, 34), "ropa": (112, 66, 160),
                 "tipo": "camiseta", "fondo": (150, 100, 210), "chiquita": True, "cachetes": True,
                 "moño_pelo": (40, 30, 50), "sonrisa": True},
    "zaida": {**M, "piel": "clara", "pelo": "melena", "pelo_color": (200, 86, 42), "gordo": True, "ojos_grandes": True, "ropa": (120, 70, 140),
              "tipo": "vestido", "labios": (120, 40, 70), "fondo": (90, 60, 130), "arete": True,
              "chal": (160, 110, 190)},
    "pilar": {**M, "piel": "clara", "pelo": "melena", "pelo_color": (110, 80, 60), "gafas": "claras",
              "ropa": (240, 240, 236), "tipo": "bata", "camisa": (120, 170, 200), "fondo": (80, 140, 150),
              "labios": (190, 100, 100)},
    "defensora": {**M, "piel": "negra", "pelo": "cola", "pelo_color": (30, 24, 26), "gafas": "claras",
                  "ropa": (50, 54, 80), "tipo": "saco", "camisa": (236, 232, 222), "fondo": (70, 70, 110),
                  "labios": (140, 60, 70)},
    "celador": {"piel": "media", "pelo": "corto", "bigote": True, "sombrero": "gorra", "sombrero_color": (40, 50, 80),
                "ropa": (44, 52, 84), "tipo": "uniforme", "camisa": (170, 200, 228), "fondo": (60, 70, 100)},
    "lilato": {**M, "ojos_grandes": True, "piel": "clara", "pelo": "linda", "pelo_color": (112, 70, 40), "ropa": (246, 140, 176),
               "tipo": "vestido", "labios": (214, 40, 80), "cachetes": True, "moño_pelo": (236, 72, 132),
               "fondo": (220, 110, 160), "chiquita": True},
    "brenda": {**M, "piel": "negra", "pelo": "afro", "pelo_color": (28, 24, 26), "canas_afro": True,
               "ropa": (206, 156, 58), "tipo": "saco", "camisa": (120, 118, 124), "labios": (120, 50, 50),
               "fondo": (150, 110, 40), "arete": True, "viejo": True},
    "guillermo": {"piel": "clara", "pelo": "corto", "pelo_color": (236, 204, 96), "gafas": "oscuras", "gordo": True,
                  "ropa": (90, 160, 100), "tipo": "camiseta", "cadena": True, "fondo": (70, 130, 80)},
    "camila": {**M, "piel": "clara", "pelo": "hongo", "pelo_color": (246, 214, 96), "raiz": (96, 66, 46),
               "ropa": (214, 64, 130), "tipo": "vestido", "labios": (220, 40, 60), "fondo": (200, 70, 140),
               "chiquita": True, "arete": True},
    "mauricio": {"destruido": True, "piel": "clara", "pelo": "calvo", "pelo_color": (120, 118, 116), "barba": True,
                 "barba_color": (150, 148, 146), "ropa": (44, 38, 40), "tipo": "chaleco", "camisa": (200, 196, 186),
                 "mangas": (200, 196, 186), "fondo": (80, 60, 60), "viejo": True},
    "lisandro": {"piel": "media", "pelo": "engominado", "pelo_color": (24, 22, 26), "gafas": "oscuras",
                 "gordo": True, "nariz_roja": True, "ropa": (236, 234, 226), "tipo": "saco", "camisa": (190, 40, 44),
                 "cadena": True, "fondo": (150, 30, 40)},
    # José Mario Camilo: medio calvo; se hizo implantes y le están saliendo a parches. Chivera. Dientes
    # torcidos. Sonríe: es de los que tiran la piedra y esconden la mano.
    "josemario": {"piel": "clara", "pelo": "calvo", "pelo_color": (74, 62, 58), "implantes": True, "chivera": True,
                  "barba_color": (74, 62, 58), "dientes": True, "sonrisa": True,
                  "ropa": (70, 72, 80), "tipo": "saco", "corbata": (50, 80, 150), "fondo": (60, 64, 80)},
    "walter": {"piel": "clara", "pelo": "calvo", "pelo_color": (60, 50, 46), "bigote": True,
               "ropa": (236, 216, 150), "tipo": "saco", "camisa": (236, 216, 150), "corbata": (120, 80, 50),
               "fondo": (150, 130, 80)},
    "nicolas": {"piel": "clara", "pelo": "engominado", "pelo_color": (30, 28, 34), "ropa": (130, 50, 60),
                "tipo": "saco", "camisa": (230, 180, 186), "fondo": (120, 50, 60)},
    "eddy": {"piel": "clara", "pelo": "corto", "pelo_color": (200, 170, 100), "gafas": "claras",
             "ropa": (170, 200, 230), "tipo": "saco", "camisa": (170, 200, 230), "corbata": (30, 30, 36),
             "fondo": (90, 120, 160)},
    "diana": {**M, "piel": "clara", "pelo": "cola", "pelo_color": (60, 42, 34), "audifonos": True,
              "ropa": (60, 180, 180), "tipo": "camiseta", "labios": (190, 90, 100), "fondo": (50, 140, 140)},
    "raul": {"destruido": True, "piel": "morena", "pelo": "corto", "pelo_color": (170, 168, 166), "bigote": True,
             "barba_color": (150, 148, 146), "viejo": True, "ropa": (236, 206, 120), "tipo": "camiseta",
             "cadena": True, "fondo": (180, 150, 60)},
    "alvarito": {"destruido": True, "pelo": "largo", "pelo_color": (60, 44, 36), "barba": True, "barba_color": (80, 60, 48),
                 "ropa": (100, 130, 180), "tipo": "saco", "camisa": (40, 38, 44), "fondo": (70, 90, 130)},
    "pecas": {"pelo": "corto", "pelo_color": (196, 96, 44), "pecas": True, "ropa": (226, 128, 70),
              "tipo": "camiseta", "fondo": (180, 100, 60), "sonrisa": True},
    "padre": {"pelo": "corto", "pelo_color": (150, 148, 146), "gafas": "claras", "viejo": True,
              "ropa": (34, 32, 38), "tipo": "sotana", "fondo": (110, 90, 70)},
    "fabiola": {**M, "piel": "morena", "pelo": "moño", "pelo_color": (190, 186, 180), "sombrero": "pañoleta",
                "sombrero_color": (60, 90, 170), "ropa": (170, 140, 200), "tipo": "delantal",
                "delantal": (80, 130, 80), "viejo": True, "fondo": (90, 120, 80), "sonrisa": True},
    "aurelio": {"piel": "media", "pelo": "corto", "pelo_color": (40, 34, 30), "bigote": True,
                "ropa": (80, 130, 80), "tipo": "delantal", "delantal": (130, 96, 60), "fondo": (90, 120, 70)},
    "leonor": {**M, "pelo": "moño", "pelo_color": (236, 232, 226), "viejo": True, "ropa": (110, 60, 90),
               "tipo": "vestido", "chal": (236, 150, 176), "flor": (210, 40, 60), "fondo": (190, 110, 140),
               "labios": (170, 90, 100)},
    "efrain": {"destruido": True, "pelo": "corto", "pelo_color": (200, 198, 194), "sombrero": "sombrero", "sombrero_color": (90, 70, 50),
               "gafas": "claras", "chivera": True, "barba_color": (236, 234, 230), "viejo": True,
               "ropa": (110, 90, 60), "tipo": "chaleco", "camisa": (200, 60, 50), "mangas": (220, 214, 200),
               "fondo": (140, 100, 60)},
    "mono": {"destruido": True, "pelo": "largo", "pelo_color": (220, 190, 110), "barba": True, "barba_color": (200, 170, 90),
             "ropa": (36, 34, 40), "tipo": "camiseta", "guitarra": True, "fondo": (160, 130, 60)},
    "octavio": {"pelo": "corto", "pelo_color": (180, 178, 176), "sombrero": "boina", "sombrero_color": (60, 60, 70),
                "gafas": "claras", "viejo": True, "ropa": (120, 120, 126), "tipo": "saco", "camisa": (220, 216, 206),
                "fondo": (90, 90, 110)},
    "ramiro": {"destruido": True, "piel": "morena", "pelo": "corto", "pelo_color": (170, 168, 166), "sombrero": "sombrero",
               "sombrero_color": (236, 230, 210), "cinta": (30, 26, 30), "viejo": True, "bigote": True,
               "barba_color": (200, 198, 194), "ropa": (120, 90, 70), "tipo": "camiseta",
               "chal": (150, 110, 80), "fondo": (130, 100, 60)},
    "yeison": {"piel": "morena", "pelo": "rizado", "pelo_color": (30, 26, 30), "ropa": (200, 50, 50),
               "tipo": "camiseta", "cadena": True, "fondo": (160, 60, 50), "arete": True},
    "chaqueta": {"destruido": True, "piel": "media", "pelo": "engominado", "pelo_color": (34, 30, 34), "bigote": True,
                 "ropa": (40, 34, 30), "tipo": "saco", "camisa": (220, 216, 206), "cadena": True,
                 "fondo": (90, 60, 40)},
    "funcionaria": {**M, "pelo": "melena", "pelo_color": (80, 50, 40), "gafas": "claras", "ropa": (90, 110, 140),
                    "tipo": "saco", "camisa": (236, 232, 222), "labios": (170, 80, 90), "fondo": (100, 110, 130)},
    "fotografo": {"pelo": "calvo", "pelo_color": (70, 60, 56), "gafas": "claras", "bigote": True,
                  "ropa": (80, 90, 70), "tipo": "chaleco", "camisa": (200, 196, 186), "mangas": (200, 196, 186),
                  "fondo": (100, 110, 80)},
    "tito": {"pelo": "engominado", "pelo_color": (30, 28, 30), "bigote": True, "ropa": (180, 40, 50),
             "tipo": "saco", "camisa": (236, 232, 222), "corbata": (240, 200, 60), "fondo": (160, 50, 60),
             "sonrisa": True},
    "mona": {**M, "pelo": "melena", "pelo_color": (240, 210, 120), "ropa": (40, 40, 48), "tipo": "saco",
             "camisa": (220, 60, 80), "labios": (200, 50, 70), "fondo": (170, 60, 90), "arete": True},
    "maestro": {"destruido": True, "piel": "morena", "pelo": "corto", "sombrero": "gorra", "sombrero_color": (226, 190, 60),
                "barba": True, "barba_color": (40, 34, 36), "ropa": (70, 100, 150), "tipo": "camiseta",
                "fondo": (180, 140, 50)},
    # ---- Los que faltaban: todo el que habla tiene retrato (los del barrio, los de la noche, los de paso).
    "amigo": {"piel": "media", "pelo": "rizado", "pelo_color": (40, 30, 30), "gafas": "claras", "audifonos": True,
              "ropa": (104, 74, 160), "tipo": "camiseta", "fondo": (70, 60, 130), "sonrisa": True},
    "guardia": {"piel": "morena", "pelo": "calvo", "pelo_color": (30, 26, 28), "gafas": "oscuras", "gordo": True,
                "ropa": (26, 26, 32), "tipo": "saco", "camisa": (26, 26, 32), "cadena": True, "fondo": (150, 40, 100)},
    "agente": {"piel": "media", "pelo": "corto", "pelo_color": (30, 28, 30), "bigote": True, "sombrero": "gorra",
               "sombrero_color": (70, 96, 60), "ropa": (78, 104, 66), "tipo": "uniforme", "camisa": (78, 104, 66),
               "fondo": (60, 80, 60)},
    "agente_nuevo": {"piel": "clara", "pelo": "corto", "pelo_color": (60, 44, 36), "sombrero": "gorra",
                     "sombrero_color": (70, 96, 60), "ropa": (78, 104, 66), "tipo": "uniforme", "camisa": (78, 104, 66),
                     "fondo": (80, 110, 80), "cachetes": True},
    "sargento": {"piel": "morena", "pelo": "corto", "pelo_color": (150, 148, 146), "bigote": True, "viejo": True, "gordo": True,
                 "barba_color": (170, 168, 166), "sombrero": "gorra", "sombrero_color": (50, 70, 44), "ropa": (60, 84, 52),
                 "tipo": "uniforme", "camisa": (60, 84, 52), "fondo": (50, 60, 44), "gafas": "oscuras"},
    "senor": {"piel": "media", "pelo": "corto", "pelo_color": (90, 84, 80), "bigote": True, "viejo": True,
              "ropa": (150, 170, 190), "tipo": "camiseta", "fondo": (110, 120, 130)},
    "senor2": {"piel": "clara", "pelo": "calvo", "pelo_color": (120, 116, 112), "gafas": "claras", "gordo": True,
               "ropa": (190, 170, 120), "tipo": "saco", "camisa": (230, 226, 214), "fondo": (130, 120, 90)},
    "desconocido": {"destruido": True, "piel": "morena", "pelo": "corto", "pelo_color": (30, 26, 28), "sombrero": "gorra",
                    "sombrero_color": (40, 40, 48), "barba": True, "barba_color": (50, 44, 44), "ropa": (60, 64, 70),
                    "tipo": "camiseta", "fondo": (60, 60, 70), "ojeras": True},
    "senora": {**M, "piel": "media", "pelo": "moño", "pelo_color": (90, 70, 60), "viejo": True, "ropa": (170, 110, 130),
               "tipo": "vestido", "labios": (170, 80, 90), "arete": True, "fondo": (150, 110, 120)},
    "senora2": {**M, "piel": "clara", "pelo": "melena", "pelo_color": (150, 120, 90), "gafas": "claras", "viejo": True,
                "ropa": (110, 150, 140), "tipo": "saco", "camisa": (236, 232, 222), "labios": (180, 90, 100),
                "fondo": (100, 130, 120)},
    "mama": {**M, "piel": "media", "pelo": "cola", "pelo_color": (50, 36, 32), "ropa": (230, 190, 90), "tipo": "camiseta",
             "labios": (180, 80, 90), "fondo": (170, 140, 70), "ojeras": True},
    "pelado": {"nino": True, "piel": "morena", "pelo": "corto", "pelo_color": (30, 26, 28), "ropa": (220, 120, 60), "tipo": "camiseta",
               "fondo": (90, 140, 90), "chiquita": True, "cachetes": True, "sonrisa": True},
    "flaca": {"nino": True, **M, "piel": "media", "pelo": "cola", "pelo_color": (40, 30, 30), "ropa": (90, 170, 200), "tipo": "camiseta",
              "fondo": (90, 140, 90), "chiquita": True, "pecas": True, "sonrisa": True},
    "chino": {"nino": True, "piel": "clara", "pelo": "engominado", "pelo_color": (24, 22, 26), "ropa": (210, 60, 60), "tipo": "camiseta",
              "fondo": (90, 140, 90), "chiquita": True, "ojos": "cerrados", "sonrisa": True},
    "alejandro": {"nino": True, "piel": "media", "pelo": "corto", "pelo_color": (34, 28, 28), "ropa": (206, 200, 184), "tipo": "saco",
                  "camisa": (206, 200, 184), "fondo": (60, 90, 140), "chiquita": True, "ojeras": True, "cicatriz": True},
    "nina": {"nino": True, **M, "piel": "morena", "pelo": "afro", "pelo_color": (30, 24, 26), "ropa": (240, 200, 90), "tipo": "vestido",
             "fondo": (150, 110, 150), "chiquita": True, "cachetes": True, "moño_pelo": (230, 80, 120)},
    "funcionario": {"piel": "clara", "pelo": "engominado", "pelo_color": (70, 60, 56), "gafas": "claras", "bigote": True,
                    "ropa": (96, 100, 116), "tipo": "saco", "camisa": (236, 232, 222), "corbata": (120, 50, 60),
                    "fondo": (100, 104, 120)},
    "borracho": {"destruido": True, "piel": "clara", "pelo": "largo", "pelo_color": (110, 96, 84), "nariz_roja": True,
                 "barba": True, "barba_color": (130, 116, 104), "ropa": (120, 90, 70), "tipo": "camiseta",
                 "fondo": (130, 90, 50), "ojos": "cerrados", "sonrisa": True},
    "jibaro": {"destruido": True, "piel": "media", "pelo": "corto", "pelo_color": (24, 22, 26), "sombrero": "gorra",
               "sombrero_color": (20, 20, 26), "gafas": "oscuras", "chivera": True, "barba_color": (30, 26, 28),
               "ropa": (40, 40, 48), "tipo": "camiseta", "cadena": True, "fondo": (60, 110, 70)},
    "veronica": {**M, "piel": "clara", "pelo": "largo", "pelo_color": (30, 24, 30), "ojo_color": (70, 130, 220),
                 "ropa": (60, 80, 130), "tipo": "saco", "camisa": (220, 60, 90), "labios": (190, 50, 70),
                 "fondo": (120, 50, 110), "ojeras": True, "arete": True},
    "mitchelle": {**M, "piel": "negra", "pelo": "afro", "pelo_color": (30, 24, 26), "ropa": (230, 80, 130),
                  "tipo": "vestido", "labios": (170, 40, 80), "fondo": (150, 60, 120), "arete": True},
    "dayhana": {**M, "piel": "morena", "pelo": "linda", "pelo_color": (190, 120, 60), "raiz": (50, 36, 30),
                "ropa": (90, 200, 190), "tipo": "camiseta", "labios": (220, 60, 110), "fondo": (170, 70, 130),
                "arete": True, "sonrisa": True, "cachetes": True},
    "tubo": {**M, "piel": "media", "pelo": "melena", "pelo_color": (200, 60, 90), "ropa": (40, 36, 46), "tipo": "vestido",
             "labios": (200, 40, 80), "fondo": (200, 60, 150), "ojeras": True, "arete": True},
    "martin": {"piel": "clara", "pelo": "corto", "pelo_color": (110, 80, 50), "ropa": (90, 140, 200), "tipo": "camiseta",
               "fondo": (90, 120, 160), "sonrisa": True},
    "conductor": {"piel": "morena", "pelo": "corto", "pelo_color": (40, 34, 34), "bigote": True, "gordo": True,
                  "sombrero": "gorra", "sombrero_color": (200, 60, 50), "ropa": (120, 170, 220), "tipo": "camiseta",
                  "fondo": (200, 160, 60)},
    "billar": {"destruido": True, "piel": "clara", "pelo": "engominado", "pelo_color": (60, 54, 54), "bigote": True,
               "ropa": (90, 40, 50), "tipo": "chaleco", "camisa": (220, 214, 200), "mangas": (220, 214, 200),
               "fondo": (40, 110, 70), "ojeras": True},
    "barra": {"piel": "morena", "pelo": "calvo", "pelo_color": (40, 34, 34), "barba": True, "barba_color": (50, 44, 44),
              "ropa": (30, 30, 36), "tipo": "chaleco", "camisa": (200, 196, 186), "mangas": (200, 196, 186),
              "fondo": (120, 50, 60)},
    "turista": {"piel": "clara", "pelo": "corto", "pelo_color": (236, 210, 130), "gafas": "oscuras", "nariz_roja": True,
                "sombrero": "sombrero", "sombrero_color": (236, 226, 190), "ropa": (240, 150, 60), "tipo": "camiseta",
                "fondo": (80, 170, 200), "sonrisa": True},
    "flaco": {"destruido": True, "piel": "media", "pelo": "corto", "pelo_color": (24, 22, 26), "sombrero": "gorra",
              "sombrero_color": (150, 30, 40), "ropa": (30, 30, 36), "tipo": "camiseta", "cadena": True,
              "fondo": (90, 40, 50), "cicatriz": True},
    "grande": {"destruido": True, "piel": "negra", "pelo": "calvo", "pelo_color": (20, 18, 20), "gordo": True,
               "barba": True, "barba_color": (26, 22, 24), "ropa": (50, 50, 60), "tipo": "camiseta", "cadena": True,
               "fondo": (70, 40, 50)},
    "jairo": {"piel": "media", "pelo": "corto", "pelo_color": (190, 186, 180), "viejo": True, "sombrero": "sombrero",
              "sombrero_color": (120, 96, 66), "bigote": True, "barba_color": (200, 196, 190), "ropa": (150, 130, 100),
              "tipo": "camiseta", "fondo": (120, 110, 70)},
    "perros": {"piel": "morena", "pelo": "corto", "pelo_color": (30, 26, 28), "sombrero": "gorra",
               "sombrero_color": (236, 232, 222), "ropa": (236, 232, 222), "tipo": "delantal", "delantal": (200, 60, 50),
               "fondo": (200, 150, 60), "sonrisa": True, "bigote": True},
    "paramedico": {**M, "piel": "clara", "pelo": "cola", "pelo_color": (60, 44, 36), "ropa": (230, 236, 240),
                   "tipo": "uniforme", "camisa": (220, 70, 60), "fondo": (200, 80, 70)},
    "ladron": {"destruido": True, "piel": "media", "pelo": "corto", "pelo_color": (24, 22, 26), "sombrero": "gorra",
               "sombrero_color": (30, 30, 36), "ropa": (40, 44, 60), "tipo": "saco", "camisa": (30, 30, 36),
               "fondo": (40, 40, 60), "ojeras": True, "chivera": True, "barba_color": (30, 26, 28)},
    "cobrador": {"piel": "clara", "pelo": "engominado", "pelo_color": (24, 22, 26), "gafas": "oscuras",
                 "ropa": (40, 40, 48), "tipo": "saco", "camisa": (236, 232, 222), "corbata": (30, 30, 36),
                 "fondo": (90, 30, 40)},
    # Tom Queen, el padrino: el que solo ve él. Alto, bigote blanco, sombrero negro, todo de negro.
    "tomqueen": {"piel": "clara", "pelo": "corto", "pelo_color": (214, 212, 208), "viejo": True, "sombrero": "sombrero",
                 "sombrero_color": (30, 28, 34), "cinta": (16, 14, 20), "bigote": True, "barba_color": (240, 238, 232),
                 "sonrisa": True, "ropa": (30, 28, 34), "tipo": "saco", "camisa": (36, 34, 42),
                 "corbata": (16, 14, 20), "fondo": (170, 110, 230)},
}



def main():
    OUT.mkdir(parents=True, exist_ok=True)
    args = sys.argv[1:]
    if args and args[0] == "--hoja":
        ids = args[2:] or list(CAST)
        cols = 6
        rows = (len(ids) + cols - 1) // cols
        sheet = Image.new("RGB", (W * cols, H * rows), (44, 40, 62))
        for k, pid in enumerate(ids):
            if pid == "iguales" or pid.startswith("lukas"):
                im = mannequin() if pid == "iguales" else lukas(pid[6:] if pid != "lukas" else "normal")
            else:
                im = portrait(CAST[pid], seed=list(CAST).index(pid))
            sheet.paste(im, ((k % cols) * W, (k // cols) * H), im)
        sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(args[1])
        return
    for i, (pid, p) in enumerate(CAST.items()):
        if args and pid not in args:
            continue
        portrait(p, seed=i).save(OUT / f"{pid}.png")
    if not args or "iguales" in args:
        mannequin().save(OUT / "iguales.png")
    if not args or "lukas" in args:
        for mode in LUKAS_MODOS:
            lukas(mode).save(OUT / ("lukas.png" if mode == "normal" else f"lukas_{mode}.png"))
    print("retratos:", len(args) or len(CAST), OUT)


if __name__ == "__main__":
    main()
