"""Retratos para los diálogos, estilo Dredge: gente seria, gastada, con cara de cansancio. El que
habla aparece de pie en el medio, detrás del cuadro negro (ver Dialogue.gd).
Cada cara se modela con volumen: un mapa de alturas (cráneo, nariz, pómulos, cuencas hundidas,
mejillas chupadas, surcos), luz dura de costado por planos (cortes, no degradé), y después facetas:
cada celda de un Voronoi toma el color promedio (el look low-poly). Colores apagados (sombras frías,
luces cálidas). Se pinta a 4x, se baja a 1x y se reduce la paleta (pixel art). A mano y nítido:
ceño, párpados caídos, ojeras, comisuras para abajo, barba de días, arrugas; "destruido": ojos rojos.
Busto de 96x112, de tres cuartos mirando a la derecha, fondo transparente.
También iguales.png: el maniquí gris sin cara (todos iguales).
Salida: assets/portraits/<id>.png
Uso: python tools/art/draw_retratos.py [id ...]  (desde la carpeta del proyecto)"""
import math
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

OUT = Path("assets/portraits")
W, H = 96, 112
S = 4  # se pinta a 4x y se baja
LIGHT = np.array([0.8, -0.42, 0.42])
LIGHT = LIGHT / np.linalg.norm(LIGHT)
HALF = (LIGHT + np.array([0, 0, 1.0]))
HALF = HALF / np.linalg.norm(HALF)

# Piel: sombra, base, luz.
SKINS = {
    "clara": ((150, 92, 88), (226, 178, 148), (248, 214, 190)),
    "media": ((128, 76, 62), (204, 148, 112), (234, 190, 154)),
    "morena": ((96, 54, 44), (170, 112, 80), (212, 156, 116)),
    "negra": ((52, 28, 26), (108, 66, 46), (156, 104, 76)),
}


# ---------------------------------------------------------------- Utilidades (a 4x)

def blur(a, r):
    """Desenfoque gaussiano aproximado (tres cajas), sin scipy."""
    r = max(1, int(r))
    out = a.astype(np.float32)
    for _ in range(3):
        for axis in (0, 1):
            pad = [(0, 0), (0, 0)]
            pad[axis] = (r, r)
            p = np.pad(out, pad, mode="edge")
            c = np.cumsum(p, axis=axis, dtype=np.float64)
            c = np.insert(c, 0, 0, axis=axis)
            n = out.shape[axis]
            if axis == 0:
                out = ((c[2 * r + 1:2 * r + 1 + n] - c[:n]) / (2 * r + 1)).astype(np.float32)
            else:
                out = ((c[:, 2 * r + 1:2 * r + 1 + n] - c[:, :n]) / (2 * r + 1)).astype(np.float32)
    return out


def mask(draw_fn):
    im = Image.new("L", (W * S, H * S), 0)
    draw_fn(ImageDraw.Draw(im))
    return np.asarray(im, dtype=np.float32) / 255.0


def ell(cx, cy, rx, ry):
    return mask(lambda d: d.ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], fill=255))


def poly(pts):
    return mask(lambda d: d.polygon([(x * S, y * S) for x, y in pts], fill=255))


_YY, _XX = np.mgrid[0:H * S, 0:W * S].astype(np.float32) / S


def bump(cx, cy, rx, ry, k=1.0):
    """Una loma suave (para nariz, pómulos, labios): positivo sale, negativo se hunde."""
    d = ((_XX - cx) / rx) ** 2 + ((_YY - cy) / ry) ** 2
    return k * np.exp(-d * 2.2)


def noise(sx, sy, seed, scale=1.0):
    """Ruido estirado: sx, sy = tamaño de la "célula" (para mechones, sx chico y sy grande)."""
    rnd = np.random.default_rng(seed)
    small = rnd.random((max(2, int(H / sy) + 2), max(2, int(W / sx) + 2))).astype(np.float32)
    im = Image.fromarray((small * 255).astype(np.uint8)).resize((W * S, H * S), Image.BICUBIC)
    return (np.asarray(im, dtype=np.float32) / 255.0 - 0.5) * scale


def shade(height, k=40.0):
    """Normales a partir del mapa de alturas; devuelve difusa, especular, oclusión."""
    gy, gx = np.gradient(height)
    n = np.stack([-gx * k, -gy * k, np.ones_like(height)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    diff = np.clip(n @ LIGHT, 0, 1)
    spec = np.clip(n @ HALF, 0, 1) ** 24
    ao = np.clip(1.0 - (blur(height, 6 * S) - height) * 3.0, 0.55, 1.0)
    return diff, spec, ao


def ramp(t, dark, mid, light):
    """t 0..1 -> color, de la sombra a la luz pasando por la base."""
    dark, mid, light = (np.array(c, dtype=np.float32) for c in (dark, mid, light))
    t = np.clip(t, 0, 1)[..., None]
    lo = dark + (mid - dark) * np.clip(t * 2, 0, 1)
    hi = mid + (light - mid) * np.clip(t * 2 - 1, 0, 1)
    return np.where(t < 0.5, lo, hi)


def tones(c, dark=0.45, light=1.22, warm=(14, -4, 10)):
    """Sombra (un poco cálida) y luz de un color de ropa o pelo."""
    c = np.array(c[:3], dtype=np.float32)
    d = np.clip(c * dark + np.array(warm) * 0.5, 0, 255)
    l = np.clip(c * light + 14, 0, 255)
    return tuple(d), tuple(c), tuple(l)


class Canvas:
    def __init__(self):
        self.rgb = np.zeros((H * S, W * S, 3), np.float32)
        self.a = np.zeros((H * S, W * S), np.float32)
        self.mat = np.zeros((H * S, W * S), np.int32)  # qué material pintó cada píxel (para las facetas)
        self._next = 1

    def paint(self, m, color):
        m = np.clip(m, 0, 1)
        self.mat = np.where(m > 0.5, self._next, self.mat)
        self._next += 1
        m = m[..., None]
        self.rgb = self.rgb * (1 - m) + color * m
        self.a = np.maximum(self.a, m[..., 0])

    def material(self, m, palette, height=None, k=40.0, amb=0.22, gloss=0.0, extra=None):
        """Pinta una zona con volumen: palette = (sombra, base, luz)."""
        h = blur(m, 5 * S) if height is None else height
        diff, spec, ao = shade(h, k)
        t = (amb + diff * 0.95) * ao
        if extra is not None:
            t = t + extra
        t = np.floor(np.clip(t, 0, 1) * 4.0 + 0.35) / 4.0  # luz por planos: cortes duros, no degradé
        col = ramp(t, *palette) + spec[..., None] * gloss * 255
        self.paint(m, np.clip(col, 0, 255))


# ---------------------------------------------------------------- Cabeza

def skin_of(p):
    s = p.get("piel", "clara")
    return SKINS[s] if isinstance(s, str) else s


def head_masks(p):
    fat, kid = p.get("gordo"), p.get("chiquita")
    sx = 1.18 if fat else (0.94 if kid else 1.0)
    cx = 46

    def X(x):
        return cx + (x - cx) * sx
    skull = ell(X(44), 44, 21 * sx, 26)
    jaw_pts = [(30, 54), (34, 68), (42, 77), (51, 81), (57, 79), (62, 73), (65, 64), (66, 55), (66, 44), (62, 30)]
    if fat:
        jaw_pts = [(28, 54), (31, 70), (40, 82), (52, 86), (60, 82), (66, 74), (68, 62), (68, 48), (63, 30)]
    elif p.get("mujer") or kid:
        jaw_pts = [(30, 54), (35, 67), (43, 75), (51, 78), (57, 76), (62, 70), (65, 62), (66, 54), (66, 44), (62, 30)]
    face = poly([(X(x), y) for x, y in jaw_pts])
    head = np.clip(skull + face, 0, 1)
    ear = ell(X(29), 55, 4, 7)
    return head, ear, X


def draw_head(c, p):
    dark, mid, light = skin_of(p)
    head, ear, X = head_masks(p)
    h = blur(head, 7 * S) * 1.0
    # Relieve de la cara (mirando a la derecha: la línea media en x≈57).
    h += bump(X(57), 56, 2.0, 7, 0.6)     # tabique
    h += bump(X(59), 61, 3.0, 2.4, 0.55)  # punta de la nariz
    h += bump(X(55), 61, 2.2, 1.6, 0.25)  # ala de la nariz
    h += bump(X(53), 45, 9, 2.4, 0.12)    # arco de las cejas
    h += bump(X(46), 49, 4.4, 3.2, -0.24)  # cuenca del ojo cercano (hundida: cansancio)
    h += bump(X(61), 49, 2.8, 2.8, -0.18)  # cuenca del ojo lejano
    if not p.get("chiquita"):
        h += bump(X(44), 64, 4, 4, -0.08)  # mejilla chupada
        h += bump(X(48), 63, 2.5, 6, -0.06)  # surco nasogeniano
    h += bump(X(43), 57, 6, 4, 0.10)      # pómulo
    h += bump(X(55), 68, 5, 1.6, 0.10)    # labios
    h += bump(X(54), 75, 5, 3, 0.10)      # mentón
    h += bump(X(52), 71.5, 4, 1.2, -0.06)  # surco bajo el labio
    if p.get("viejo"):
        h += bump(X(46), 64, 3, 6, -0.05)  # surco nasogeniano
    if p.get("gordo"):
        h += bump(X(50), 82, 9, 2, -0.08)  # la papada
    c.material(ear, (dark, mid, light), height=blur(ear, 2 * S) + bump(X(29), 55, 2, 4, -0.2), k=30)
    # El lado de atrás de la cara (lejos de la luz) más oscuro; y la sombra que tira la nariz.
    form = np.clip((_XX - X(46)) / 18.0, -1, 1) * 0.38
    nose_shadow = -(bump(X(54), 58, 1.8, 5, 0.32) + bump(X(56), 63.5, 3, 1.1, 0.3))
    jaw_shadow = -bump(X(40), 72, 8, 6, 0.18)
    c.material(head, (dark, mid, light), height=h, k=52, amb=0.18, gloss=0.05, extra=form + nose_shadow + jaw_shadow)
    # Mejillas sonrojadas, un poco de rojo en la nariz (la piel no es de un solo color).
    blush = (bump(X(45), 59, 5, 3, 0.16) + bump(X(59), 61, 2.5, 2, 0.1)) * head
    if p.get("cachetes"):
        blush = blush * 2.2
    c.rgb = c.rgb * (1 - blush[..., None]) + np.array([200, 80, 80], np.float32) * blush[..., None]
    return X


def draw_neck(c, p):
    dark, mid, light = skin_of(p)
    fat = p.get("gordo")
    m = poly([(39, 70), (57, 70), (59 if not fat else 64, 94), (37 if not fat else 30, 94)])
    c.material(m, (dark, mid, light), height=blur(m, 4 * S), k=30, amb=0.18,
               extra=-0.35 * blur(poly([(30, 70), (64, 70), (64, 80), (30, 80)]), 3 * S))  # sombra de la quijada


# ---------------------------------------------------------------- Ropa

def draw_body(c, p, seed):
    fat = p.get("gordo")
    lx, rx = (0, 96) if fat else (6, 90)
    top = 87
    kind = p.get("tipo", "camiseta")
    cloth = tones(p["ropa"])
    # Hombros caídos (trapecio, deltoides redondos), no una caja.
    shoulders = poly([(lx, H), (lx + 1, top + 12), (lx + 5, top + 6), (16, top + 2), (30, top - 3), (40, top - 6),
                      (56, top - 6), (66, top - 3), (80, top + 2), (rx - 5, top + 6), (rx - 1, top + 12), (rx, H)])
    c.material(shoulders, cloth, k=20, amb=0.2, extra=noise(3, 12, seed, 0.25) * 0.6 + np.clip((_XX - 48) / 30.0, -1, 1) * 0.3)
    shirt = tones(p.get("camisa", (230, 226, 216)))
    if kind in ("saco", "bata", "chaleco", "uniforme"):
        c.material(poly([(38, top - 4), (58, top - 4), (52, H), (44, H)]), shirt, k=20, amb=0.4)
        if p.get("corbata"):
            c.material(poly([(46, top - 2), (51, top - 2), (53, H), (48, H + 1), (44, H)]), tones(p["corbata"]), k=25)
        for side in (-1, 1):  # solapas
            x0 = 38 if side < 0 else 58
            lap = poly([(x0, top - 4), (x0 - side, top + 2), (48 + side * 3, top + 16), (x0 + side * 8, top + 4)])
            c.material(lap, tones(p["ropa"], 0.4, 1.3), k=40, amb=0.35)
        if kind == "chaleco" and p.get("mangas"):
            m = tones(p["mangas"])
            c.material(poly([(lx, H), (lx + 2, top + 8), (16, top + 2), (14, H)]), m, k=20)
            c.material(poly([(rx, H), (rx - 2, top + 8), (rx - 10, top + 2), (rx - 8, H)]), m, k=20)
    elif kind == "delantal":
        a = tones(p["delantal"])
        extra = None
        if p.get("cuadros"):
            extra = ((((_XX // 3) + (_YY // 3)) % 2) * -0.18).astype(np.float32)
        c.material(poly([(32, top + 10), (64, top + 10), (64, H), (32, H)]), a, k=20, amb=0.35, extra=extra)
        for x0, x1 in ((32, 26), (61, 67)):
            c.material(poly([(x0, top + 10), (x0 + 3, top + 10), (x1 + 3, top - 2), (x1, top - 2)]), a, k=20)
    elif kind == "vestido":
        neckline = ell(48, top - 2, 10, 7) * poly([(30, top - 4), (66, top - 4), (66, H), (30, H)])
        c.material(neckline, skin_of(p), k=25, amb=0.35)
    elif kind == "sotana":
        c.material(poly([(43, top - 4), (53, top - 4), (53, top), (43, top)]), tones((240, 240, 236)), k=20, amb=0.6)
    else:  # camiseta
        c.material(ell(48, top - 4, 9, 5), tones(p["ropa"], 0.3, 0.8), k=20)
    if kind == "uniforme":
        c.material(poly([(66, top + 12), (74, top + 12), (74, top + 20), (66, top + 20)]), tones((220, 190, 80)), k=60, gloss=0.6)
    if p.get("chal"):
        ch = tones(p["chal"])
        c.material(poly([(lx, top + 18), (20, top - 2), (36, top + 4), (44, H), (lx, H)]), ch, k=25, extra=noise(4, 10, seed + 1, 0.3))
        c.material(poly([(rx, top + 18), (76, top - 2), (60, top + 4), (54, H), (rx, H)]), ch, k=25, extra=noise(4, 10, seed + 2, 0.3))
    if p.get("guitarra"):
        c.material(poly([(4, H), (10, H), (60, top + 2), (56, top - 2)]), tones((130, 80, 40)), k=40, gloss=0.3)
    if p.get("cadena"):
        m = mask(lambda d: d.arc([36 * S, (top - 12) * S, 62 * S, (top + 12) * S], 25, 155, fill=255, width=S))
        c.material(m, tones((236, 196, 70)), height=blur(m, S), k=80, gloss=0.9)
    if p.get("flor"):
        c.material(ell(74, top + 10, 4, 4), tones(p["flor"]), k=30)


# ---------------------------------------------------------------- Pelo

HAIR_SHAPES = {
    "corto": lambda X, R: [ell(X(44), 34, R(22), 17), poly([(X(23), 40), (X(30), 30), (X(32), 56), (X(25), 54)])],
    "rizado": lambda X, R: [ell(X(44), 32, R(24), 18)],
    "engominado": lambda X, R: [ell(X(43), 34, R(22), 15), poly([(X(22), 38), (X(28), 30), (X(30), 54), (X(24), 52)])],
    "calvo": lambda X, R: [poly([(X(24), 44), (X(30), 42), (X(31), 56), (X(25), 56)])],
    "melena": lambda X, R: [ell(X(44), 36, R(24), 20), poly([(X(20), 40), (X(34), 34), (X(36), 76), (X(20), 76)]),
                         poly([(X(62), 36), (X(68), 46), (X(68), 72), (X(64), 74)])],
    "largo": lambda X, R: [ell(X(44), 36, R(24), 20), poly([(X(18), 40), (X(34), 34), (X(38), 104), (X(14), 104)]),
                        poly([(X(62), 36), (X(70), 50), (X(72), 100), (X(64), 100)])],
    "linda": lambda X, R: [ell(X(44), 36, R(24), 21), poly([(X(16), 40), (X(34), 34), (X(36), 106), (X(12), 106)]),
                        poly([(X(62), 36), (X(70), 50), (X(72), 104), (X(64), 104)]),
                        poly([(X(36), 32), (X(66), 36), (X(66), 46), (X(36), 44)])],
    "cola": lambda X, R: [ell(X(44), 34, R(22), 17), poly([(X(22), 38), (X(30), 30), (X(30), 54), (X(24), 52)]),
                       poly([(X(22), 34), (X(14), 46), (X(12), 78), (X(20), 76), (X(24), 48)])],
    "afro": lambda X, R: [ell(X(44), 34, R(32), 28)],
    "hongo": lambda X, R: [ell(X(46), 38, R(28), 22)],
    "moño": lambda X, R: [ell(X(44), 34, R(22), 16), ell(X(24), 28, R(8), 8), poly([(X(22), 38), (X(30), 30), (X(30), 52), (X(24), 50)])],
}
LONG = ("largo", "linda", "melena", "cola", "afro", "hongo", "moño")


def draw_hair(c, p, X, seed, front=True):
    style = p.get("pelo", "corto")
    if style not in HAIR_SHAPES:
        return
    sx = (X(100) - X(0)) / 100.0
    shapes = HAIR_SHAPES[style](X, lambda r: r * sx)
    m = np.clip(sum(shapes), 0, 1)
    face_hole = poly([(X(34), 46), (X(40), 40), (X(66), 38), (X(70), 60), (X(60), 84), (X(36), 80)])
    if style == "hongo":
        face_hole = poly([(X(30), 50), (X(70), 50), (X(70), 84), (X(30), 84)])
    elif style == "linda":
        face_hole = poly([(X(34), 47), (X(68), 47), (X(70), 84), (X(34), 84)])
    if front:
        m = m * (1 - face_hole)
        if style not in LONG:
            head, _, _ = head_masks(p)
            m = m * np.clip(head + ell(X(44), 34, 26, 22), 0, 1)
    if style == "calvo":
        m = shapes[0]
    pal = tones(p.get("pelo_color", (40, 32, 34)), 0.35, 1.45, warm=(0, 0, 0))
    strands = noise(1.2, 9, seed, 0.9) + noise(0.6, 5, seed + 7, 0.5)
    if style in ("rizado", "afro"):
        strands = noise(1.5, 1.5, seed, 1.1)
    if style == "engominado":
        strands = noise(10, 1.0, seed, 0.6)  # peinado para atrás: mechones horizontales
    h = blur(m, 6 * S) + strands * 0.04
    form = np.clip((_XX - X(44)) / 30.0, -1, 1) * 0.18
    c.material(m, pal, height=h, k=45, amb=0.25, gloss=0.16 if style == "engominado" else 0.12, extra=strands * 0.35 + form)
    if style == "hongo" and p.get("raiz"):
        c.material(ell(X(46), 22, 16, 6) * m, tones(p["raiz"], 0.4, 1.3), k=30)
    if p.get("canas_afro"):
        speck = (noise(0.7, 0.7, seed + 3, 1.0) > 0.38) * m
        c.paint(speck * 0.8, np.array([170, 166, 160], np.float32))
    if p.get("canas"):  # canas sueltas, más en las sienes
        temple = np.clip(1.0 - np.abs(_XX - X(26)) / 10.0, 0, 1) * 0.35
        speck = (noise(0.6, 1.8, seed + 4, 1.0) > 0.5 - p["canas"] - temple) * m
        c.paint(speck * 0.75, np.array([150, 146, 142], np.float32))


def draw_beard(c, p, X, seed):
    col = p.get("barba_color", p.get("pelo_color", (40, 32, 34)))
    pal = tones(col, 0.4, 1.4, warm=(0, 0, 0))
    head, _, _ = head_masks(p)
    tex = noise(0.8, 2.5, seed + 5, 1.0)
    if p.get("barba"):
        m = poly([(X(31), 56), (X(36), 70), (X(46), 80), (X(54), 82), (X(60), 78), (X(64), 70), (X(64), 64),
                  (X(56), 70), (X(48), 70), (X(40), 64)]) * head
        m = m * (1 - poly([(X(50), 66), (X(60), 66), (X(60), 70), (X(50), 70)]) * 0.9)
        c.material(m * np.clip(0.75 + tex, 0, 1), pal, k=40, extra=tex * 0.4)
        if p.get("canas"):  # la barba con canas (más en el mentón)
            speck = (noise(0.6, 1.2, seed + 9, 1.0) > 0.5 - p["canas"] - bump(X(52), 80, 6, 4, 0.3)) * m
            c.paint(speck * 0.8, np.array([156, 150, 144], np.float32))
    if p.get("bigote"):
        c.material(poly([(X(49), 64), (X(58), 63), (X(62), 66), (X(55), 66.5), (X(48), 67)]), pal, k=40, extra=tex * 0.3)
    if p.get("chivera"):
        c.material(poly([(X(51), 74), (X(58), 74), (X(55), 86)]), pal, k=40, extra=tex * 0.3)


def draw_hat(c, p, X, seed):
    hat = p.get("sombrero")
    if not hat:
        return
    pal = tones(p.get("sombrero_color", (60, 60, 60)))
    if hat == "gorra":
        c.material(ell(X(44), 30, 23, 14) * poly([(0, 0), (96, 0), (96, 36), (0, 36)]), pal, k=30)
        c.material(poly([(X(58), 32), (X(78), 34), (X(76), 38), (X(58), 37)]), tones(pal[1], 0.3, 0.9), k=30)
    elif hat == "boina":
        c.material(ell(X(42), 26, 24, 9), pal, k=30, extra=noise(2, 2, seed, 0.2))
    elif hat == "sombrero":
        c.material(ell(X(46), 30, 36, 5), pal, k=25)
        c.material(ell(X(45), 22, 18, 12) * poly([(0, 0), (96, 0), (96, 30), (0, 30)]), pal, k=30)
        if p.get("cinta"):
            c.material(poly([(X(27), 26), (X(63), 26), (X(63), 29), (X(27), 29)]), tones(p["cinta"]), k=20)
    elif hat == "pañoleta":
        m = ell(X(44), 34, 24, 19) * poly([(0, 0), (96, 0), (96, 42), (0, 42)])
        c.material(np.clip(m + poly([(X(22), 36), (X(12), 50), (X(26), 46)]), 0, 1), pal, k=30, extra=noise(3, 3, seed, 0.3))


# ---------------------------------------------------------------- A mano (1x, nítido)

def px(d, pts, col):
    d.point(pts, fill=tuple(int(v) for v in col[:3]) + (255,))


def details(img, p, X):
    """Ojos, cejas, boca, arrugas, barba de días, gafas: a 1x, píxel por píxel. Caras serias y
    gastadas (como Dredge): ceño, párpados caídos, ojeras, comisuras para abajo."""
    d = ImageDraw.Draw(img)
    dark, mid, light = skin_of(p)
    x = lambda v: int(round(X(v)))
    female, kid, old = p.get("mujer"), p.get("chiquita"), p.get("viejo")
    worn = p.get("destruido") or old
    ey = 50
    ink = (28, 20, 22)
    sh = lambda k: tuple(int(v * k) for v in mid)
    brow = tones(p.get("cejas", p.get("pelo_color", (40, 32, 34))), 0.5, 1.1)
    # Cejas: gruesas, bajas, con el ceño (la punta de adentro más abajo que la de afuera).
    thick = 1 if kid else 2
    for i, bx in enumerate(range(x(41), x(52))):
        yy = ey - 6 + (1 if i >= 8 else 0) + (0 if kid else (1 if i <= 1 else 0))
        for t in range(thick):
            px(d, [(bx, yy + t)], brow[0] if t == 0 else brow[1])
    for bx in range(x(57), x(64)):
        px(d, [(bx, ey - 5 if bx < x(59) else ey - 6)], brow[0])
    if not kid:
        px(d, [(x(53), ey - 4), (x(53), ey - 3)], sh(0.72))  # la arruga del ceño
    # Ojos: almendra chica, párpado de arriba caído (tapa la mitad del iris), ojera abajo.
    iris = p.get("ojo_color", (64, 44, 34))
    for (ex0, ex1, near) in ((x(43), x(50), True), (x(58), x(62), False)):
        if p.get("ojos") == "cerrados":
            d.line([(ex0, ey + 1), (ex1, ey + 1)], fill=ink)
            continue
        white = (210, 200, 186) if not worn else (206, 186, 170)
        d.line([(ex0 + 1, ey), (ex1 - 1, ey)], fill=white)
        d.line([(ex0 + 1, ey + 1), (ex1 - 2, ey + 1)], fill=sh(0.8))
        ix = ex1 - (3 if near else 1)
        d.rectangle([ix - 1, ey, ix + (0 if not near else 1), ey + 1], fill=iris)
        px(d, [(ix, ey)], (16, 10, 10))
        px(d, [(ix + (1 if near else 0), ey)], (236, 232, 222))  # un brillo chiquito
        d.line([(ex0, ey - 1), (ex1, ey - 1)], fill=ink)  # el párpado, pesado
        d.line([(ex0 + 1, ey - 2), (ex1 - 1, ey - 2)], fill=sh(0.7))  # el pliegue, en sombra
        px(d, [(ex1 + 1, ey)], ink)
        if not kid:
            d.line([(ex0, ey + 2), (ex1 - 1, ey + 2)], fill=sh(0.66))  # ojera
            if worn or p.get("ojeras"):
                d.line([(ex0 + 1, ey + 3), (ex1 - 2, ey + 3)], fill=sh(0.74))
        if p.get("destruido"):
            px(d, [(ex0, ey), (ex0 + 1, ey + 1)], (150, 70, 66))  # ojo rojo, de no dormir
        if female or kid:
            px(d, [(ex1 + 1, ey - 2), (ex1 + 2, ey - 2)], ink)
    # Nariz: el borde en sombra y la fosa.
    px(d, [(x(56), 55), (x(56), 57), (x(56), 59)], sh(0.8))
    px(d, [(x(57), 62), (x(58), 62)], sh(0.55))
    # Boca: recta, comisuras hacia abajo.
    lips = p.get("labios")
    my = 67
    m0, m1 = x(49), x(59)
    if lips:
        lc = tones(lips, 0.6, 1.1)
        d.line([(m0 + 1, my + 1), (m1 - 2, my + 1)], fill=tuple(int(v) for v in lc[1]))
    d.line([(m0, my), (m1, my)], fill=sh(0.5))
    if kid and p.get("sonrisa"):
        px(d, [(m0 - 1, my - 1), (m1 + 1, my - 1)], sh(0.6))
    else:
        px(d, [(m0 - 1, my + 1), (m1 + 1, my + 1)], sh(0.58))
    if not kid:
        px(d, [(x(52), my + 3), (x(55), my + 3)], sh(0.78))  # sombra bajo el labio
        # Surcos de la nariz a la boca.
        px(d, [(x(51), 60), (x(50), 62), (x(49), 64), (x(48), 66)], sh(0.74))
    if old:
        d.line([(x(44), 39), (x(56), 39)], fill=sh(0.8))
        d.line([(x(46), 41), (x(54), 41)], fill=sh(0.84))
        px(d, [(x(63), 50), (x(64), 52), (x(64), 47)], sh(0.75))  # patas de gallo
        px(d, [(x(40), 70), (x(42), 73), (x(45), 75)], sh(0.8))  # la papada que cuelga
    # Barba de días (los hombres sin barba): puntitos en la quijada y el bigote.
    if not (female or kid or p.get("barba")):
        rnd = random.Random(7)
        stub = (36, 28, 28) if p.get("pelo_color", (40, 32, 34))[0] < 120 else (120, 110, 100)
        for _ in range(110 if p.get("destruido") else 60):
            sx, sy = rnd.randint(x(32), x(64)), rnd.randint(56, 80)
            pxl = img.getpixel((sx, sy))
            if pxl[3] and abs(pxl[0] - mid[0]) < 60 and not (x(48) <= sx <= x(60) and my - 1 <= sy <= my + 1):
                if sy > 64 or (x(48) <= sx <= x(61) and 63 <= sy <= 65):
                    blend = tuple(int(a * 0.55 + b * 0.45) for a, b in zip(pxl[:3], stub))
                    d.point((sx, sy), fill=blend + (255,))
    if p.get("cicatriz"):
        d.line([(x(60), 44), (x(57), 54)], fill=sh(1.15))
    if p.get("nariz_roja"):
        d.ellipse([x(57), 58, x(61), 62], fill=(170, 84, 84))
    if p.get("pecas"):
        rnd = random.Random(3)
        for _ in range(12):
            px(d, [(rnd.randint(x(41), x(62)), rnd.randint(54, 60))], sh(0.8))
    if p.get("arete"):
        px(d, [(x(29), 62), (x(29), 63)], (200, 170, 80))
    g = p.get("gafas")
    if g:
        frame = (24, 18, 20)
        if g == "oscuras":
            d.rectangle([x(41), ey - 3, x(51), ey + 3], fill=(22, 20, 26))
            d.rectangle([x(56), ey - 3, x(63), ey + 3], fill=(22, 20, 26))
            d.line([(x(43), ey - 2), (x(46), ey - 2)], fill=(96, 100, 116))
        else:
            d.rectangle([x(41), ey - 3, x(51), ey + 3], outline=frame)
            d.rectangle([x(56), ey - 3, x(63), ey + 3], outline=frame)
            px(d, [(x(49), ey - 2), (x(61), ey - 2)], (210, 214, 214))
        d.line([(x(51), ey - 1), (x(56), ey - 1)], fill=frame)
        d.line([(x(31), ey - 1), (x(41), ey - 1)], fill=frame)
    if p.get("audifonos"):
        d.arc([x(22), 14, x(66), 70], 190, 330, fill=(34, 34, 40), width=2)
        d.rectangle([x(24), 50, x(30), 60], fill=(50, 130, 130))
    if p.get("moño_pelo"):
        col = tuple(int(v * 0.8) for v in p["moño_pelo"])
        d.polygon([(x(26), 18), (x(33), 23), (x(26), 28)], fill=col)
        d.polygon([(x(40), 18), (x(33), 23), (x(40), 28)], fill=col)
        px(d, [(x(33), 23)], tuple(int(v * 0.6) for v in col))


# ---------------------------------------------------------------- Armado

def facets(c, cell=5.0, seed=0):
    """Planos facetados (como Dredge): cada celda de un Voronoi con puntos corridos toma el color
    promedio de lo que tiene adentro (por material, para no mezclar pelo con piel)."""
    rnd = np.random.default_rng(seed)
    cs = cell * S
    gw, gh = int(W * S / cs) + 3, int(H * S / cs) + 3
    jx, jy = rnd.random((gh, gw)), rnd.random((gh, gw))
    yy, xx = np.mgrid[0:H * S, 0:W * S].astype(np.float32)
    ix, iy = (xx // cs).astype(np.int32), (yy // cs).astype(np.int32)
    best = np.full(xx.shape, 1e9, np.float32)
    cid = np.zeros(xx.shape, np.int64)
    for dj in (-1, 0, 1):
        for di in (-1, 0, 1):
            cx, cy = np.clip(ix + di, 0, gw - 1), np.clip(iy + dj, 0, gh - 1)
            pxp, pyp = (cx + jx[cy, cx]) * cs, (cy + jy[cy, cx]) * cs
            dd = (xx - pxp) ** 2 + (yy - pyp) ** 2
            closer = dd < best
            best = np.where(closer, dd, best)
            cid = np.where(closer, cy * gw + cx, cid)
    label = (cid * 512 + c.mat).ravel()
    _, inv = np.unique(label, return_inverse=True)
    cnt = np.bincount(inv).astype(np.float32)
    out = np.empty_like(c.rgb).reshape(-1, 3)
    flat = c.rgb.reshape(-1, 3)
    for ch in range(3):
        out[:, ch] = (np.bincount(inv, weights=flat[:, ch]) / cnt)[inv]
    c.rgb = out.reshape(c.rgb.shape)


def grade(c):
    """Colores apagados, como de pueblo húmedo: menos saturación, sombras frías, luces cálidas."""
    rgb = c.rgb / 255.0
    lum = (rgb @ np.array([0.3, 0.59, 0.11], np.float32))[..., None]
    rgb = lum + (rgb - lum) * 0.62
    shadow = np.clip(1.0 - lum * 2.0, 0, 1)
    rgb = rgb + shadow * np.array([-0.03, 0.01, 0.04]) + (1 - shadow) * np.array([0.02, 0.0, -0.03])
    rgb = rgb * 0.9
    c.rgb = np.clip(rgb * 255.0, 0, 255).astype(np.float32)


def to_pixels(c):
    """De 4x a 1x, paleta reducida (pixel art), y contorno selectivo (más oscuro, no negro)."""
    rgb = Image.fromarray(np.clip(c.rgb, 0, 255).astype(np.uint8)).resize((W, H), Image.BOX)
    a = Image.fromarray((c.a * 255).astype(np.uint8)).resize((W, H), Image.BOX)
    a = a.point(lambda v: 255 if v > 110 else 0)
    q = rgb.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    img = q.convert("RGBA")
    img.putalpha(a)
    pxl = img.load()
    src = img.copy().load()
    for y in range(H):
        for x in range(W):
            if src[x, y][3] == 0:
                continue
            edge = any(not (0 <= x + dx < W and 0 <= y + dy < H) or src[x + dx, y + dy][3] == 0
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge and y < H - 1:
                r, g, b, _ = src[x, y]
                k = 0.35 if x < 60 else 0.5  # del lado de la luz, el borde es más claro
                pxl[x, y] = (int(r * k), int(g * k), int(b * k * 1.05), 255)
    return img


def portrait(p, seed=0):
    c = Canvas()
    _, _, X = head_masks(p)
    if p.get("pelo", "corto") in LONG:
        draw_hair(c, p, X, seed, front=False)  # lo de atrás del pelo
    draw_body(c, p, seed)
    draw_neck(c, p)
    X = draw_head(c, p)
    draw_beard(c, p, X, seed)
    draw_hair(c, p, X, seed + 11, front=True)
    draw_hat(c, p, X, seed)
    facets(c, seed=seed)
    grade(c)
    fig = to_pixels(c)
    details(fig, p, X)
    if p.get("chiquita"):  # más chica: todo un poco más abajo y más chico
        small = fig.resize((int(W * 0.88), int(H * 0.88)), Image.NEAREST)
        fig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        fig.alpha_composite(small, ((W - small.width) // 2, H - small.height))
    return fig


def mannequin():
    """Todos iguales: gris, sin cara."""
    p = {"piel": ((96, 96, 104), (166, 166, 174), (210, 210, 216)), "pelo": "ninguno", "ropa": (140, 140, 148),
         "tipo": "camiseta", "fondo": (90, 90, 98)}
    c = Canvas()
    draw_body(c, p, 1)
    draw_neck(c, p)
    head, ear, X = head_masks(p)
    c.material(np.clip(head + ear, 0, 1), skin_of(p), height=blur(head, 7 * S), k=38, amb=0.3)
    facets(c, seed=99)
    return to_pixels(c)


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
    "victoria": {**M, "piel": "clara", "pelo": "largo", "pelo_color": (70, 44, 34), "ropa": (240, 140, 170),
                 "tipo": "camiseta", "fondo": (230, 170, 80), "chiquita": True, "cachetes": True,
                 "moño_pelo": (230, 80, 120), "sonrisa": True},
    "zaida": {**M, "piel": "morena", "pelo": "largo", "pelo_color": (24, 20, 28), "ropa": (120, 70, 140),
              "tipo": "vestido", "labios": (120, 40, 70), "fondo": (90, 60, 130), "arete": True,
              "chal": (160, 110, 190), "ojos": "cerrados"},
    "pilar": {**M, "piel": "clara", "pelo": "melena", "pelo_color": (110, 80, 60), "gafas": "claras",
              "ropa": (240, 240, 236), "tipo": "bata", "camisa": (120, 170, 200), "fondo": (80, 140, 150),
              "labios": (190, 100, 100)},
    "defensora": {**M, "piel": "negra", "pelo": "cola", "pelo_color": (30, 24, 26), "gafas": "claras",
                  "ropa": (50, 54, 80), "tipo": "saco", "camisa": (236, 232, 222), "fondo": (70, 70, 110),
                  "labios": (140, 60, 70)},
    "celador": {"piel": "media", "pelo": "corto", "bigote": True, "sombrero": "gorra", "sombrero_color": (40, 50, 80),
                "ropa": (44, 52, 84), "tipo": "uniforme", "camisa": (170, 200, 228), "fondo": (60, 70, 100)},
    "lilato": {**M, "piel": "clara", "pelo": "linda", "pelo_color": (112, 70, 40), "ropa": (246, 140, 176),
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
    "josemario": {"piel": "clara", "pelo": "engominado", "pelo_color": (90, 90, 96), "viejo": True,
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
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    only = sys.argv[1:]
    for i, (pid, p) in enumerate(CAST.items()):
        if only and pid not in only:
            continue
        portrait(p, seed=i).save(OUT / f"{pid}.png")
    if not only:
        mannequin().save(OUT / "iguales.png")
    print("retratos:", len(only) or len(CAST), OUT)


if __name__ == "__main__":
    main()
