"""El motor de las viñetas (lo usa tools/art/draw_vinetas.py).

Pixel art hecho por código, a 240x100:
  - Las formas se dibujan a 4x (elipses, cápsulas, polígonos) y se bajan a máscaras duras de 1x: bordes
    redondos sin colores intermedios.
  - Cada forma tiene un color propio (el de día) y la escena le pone la luz (Env): la sombra media, el
    lado que no mira a la luz (más oscuro), el lado que sí (media luz) y el borde de luz. Así la misma
    escena sirve de noche, al alba y con lluvia: solo cambia la luz.
  - Los degradados (el cielo, el piso, los conos de luz) van tramados (Bayer 4x4), sin colores de más.
  - Los actores, de proporciones de verdad (no muñecos): él y la gente se arman sobre un esqueleto
    (figure: cabeza de un séptimo del cuerpo, brazos y piernas que se adelgazan, codos, rodillas, manos y
    zapatos con forma; él sin cara: pelo, barba, oreja, un pedazo de piel; el saco que le queda grande,
    la camisa y la corbata roja asomando, un zapato de cada color) y Lukas es un beagle de su tamaño
    (patas con codo y corvejón, la montura negra, el hocico largo, la oreja caída, la cola con la punta
    blanca). Cada uno con sus posturas.
  - El acabado (POLISH, lo prenden las viñetas; los retratos no): los actores llevan un contorno oscuro
    solo del lado de la sombra (lo que los despega del fondo), las superficies grandes llevan manchas de
    desgaste tramadas (paredes, muros, pisos: nada liso en el barrio) y las esquinas se oscurecen un poco
    (el viñeteado, tramado). Y de noche, lo que brilla (ventanas, faroles, letreros, la tele) suelta un
    resplandor tramado de su color.
"""
import numpy as np
from PIL import Image, ImageDraw

W, H, SS = 240, 100, 4
BAYER = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) + 0.5) / 16.0
BAY = np.tile(BAYER, (H // 4 + 1, W // 4 + 1))[:H, :W]
BALD = 0         # él se va quedando calvo (2: la coronilla pelada, 3: calvo): ver tools/art/calvicie.py
POLISH = False   # el acabado (ver arriba): lo prenden draw_vinetas.py y draw_vinetas_tele.py
# El tramado de las manchas: el mismo Bayer, con cada celda de 2x2 (manchitas, no puntos sueltos).
BAY2 = np.tile(np.kron(BAYER, np.ones((2, 2))), (H // 8 + 1, W // 8 + 1))[:H, :W]
GRAIN_MIN = 1500  # las superficies de más de estos píxeles llevan manchas (paredes, muros, pisos; no los muebles)


def _value_noise(h, w, cell, seed):
    """Ruido suave (bilineal sobre una grilla de cell px), de 0 a 1."""
    r = np.random.default_rng(seed)
    gh, gw = h // cell + 2, w // cell + 2
    g = r.random((gh, gw))
    ys, xs = np.mgrid[0:h, 0:w] / cell
    y0, x0 = ys.astype(int), xs.astype(int)
    fy, fx = ys - y0, xs - x0
    fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
    a = g[y0, x0] * (1 - fx) + g[y0, x0 + 1] * fx
    b = g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy


# Las manchas: dos escalas de ruido (la mancha grande y el grano), en un lienzo más grande que el cuadro
# para que cada superficie tome su pedazo (y no se repitan en todas las viñetas en el mismo lugar).
_NOISE = None


def _noise():
    global _NOISE
    if _NOISE is None:
        _NOISE = _value_noise(H * 3, W * 3, 9, 77) * 0.7 + _value_noise(H * 3, W * 3, 3, 78) * 0.3
    return _NOISE

def set_size(w, h):
    """Otro tamaño de lienzo (los retratos: 96x112; el epílogo: 320x180)."""
    global W, H, BAY, BAY2, _NOISE
    W, H = w, h
    BAY = np.tile(BAYER, (H // 4 + 1, W // 4 + 1))[:H, :W]
    BAY2 = np.tile(np.kron(BAYER, np.ones((2, 2))), (H // 8 + 1, W // 8 + 1))[:H, :W]
    _NOISE = None


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
        self.owner = np.zeros((H, W), np.int16)  # de quién es cada píxel: 0 el fondo, n el actor n
        self.cur = 0
        self.actors = {}                          # actor -> hacia dónde está la luz (para el contorno)

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
        self.owner[m] = self.cur

    def shape(self, m, alb, env, rim=True, shade=2, half=True, emph=1.0, flat=False):
        """Una forma con volumen: base, lado en sombra, media luz y borde de luz."""
        amb = env.amb * emph
        self.a[m] = col(alb, amb)
        self.owner[m] = self.cur
        if POLISH and self.cur == 0:
            self.grain(m)
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

    def grain(self, m, k=1.0):
        """Las manchas de desgaste: donde el ruido sube, un paso más oscuro; donde baja, un poquito más
        claro; tramado (sin colores de más que esos dos). Solo en superficies grandes."""
        n_px = int(m.sum())
        if n_px < GRAIN_MIN:
            return
        ys, xs = np.nonzero(m)
        oy, ox = (int(ys.min()) * 13 + int(xs.min()) * 7) % (H * 2), (int(xs.min()) * 11 + int(ys.min()) * 5) % (W * 2)
        n = _noise()[oy:oy + H, ox:ox + W]
        dark = m & (BAY2 < (n - 0.56) * 2.6 * k)
        lite = m & (BAY2 < (0.3 - n) * 1.4 * k)
        self.a[dark] = (self.a[dark] * 0.88).astype(np.uint8)
        self.a[lite] = np.minimum(255, self.a[lite].astype(int) * 107 // 100).astype(np.uint8)

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
            self.owner[int(y), int(x)] = self.cur

    def bloom(self):
        """De noche (la escena es oscura), lo muy claro suelta un resplandor de su color: tramado, más
        fuerte cerca, hasta unos 6 píxeles."""
        a = self.a.astype(np.float32)
        lum = a @ np.array([0.3, 0.55, 0.15], np.float32)
        if lum.mean() > 95.0:   # de día: nada (si no, el cielo lo lava todo)
            return
        bright = np.clip((lum - 175.0) / 60.0, 0, 1)
        if bright.sum() < 4:
            return
        src = a * bright[..., None]
        acc_w = np.zeros_like(bright)
        acc_c = np.zeros_like(a)
        r = 6
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                d2 = dx * dx + dy * dy
                if d2 > r * r:
                    continue
                w = 1.0 - (d2 ** 0.5) / (r + 1)
                acc_w += nb(bright, dx, dy) * w
                acc_c += np.stack([nb(src[..., c], dx, dy) for c in range(3)], -1) * w
        k = np.clip(acc_w / 9.0, 0, 1) * (1 - bright)          # (lo que ya brilla no se toca)
        glow = acc_c / np.maximum(acc_w, 1e-6)[..., None]
        on = k > BAY * 1.15
        kk = (k * 0.42)[..., None]
        mixed = a * (1 - kk) + glow * kk
        self.a[on] = mixed[on].astype(np.uint8)

    def finish(self):
        """El acabado (POLISH): el resplandor de noche, el contorno de los actores (del lado de la
        sombra) y el viñeteado."""
        self.bloom()
        for aid, (lx, ly) in self.actors.items():
            m = self.owner == aid
            if not m.any():
                continue
            # Lo que queda pegado al actor, del lado contrario a la luz (y no es de uno que va delante).
            edge = np.zeros_like(m)
            if lx:
                edge |= nb(m, lx, 0)
            if ly:
                edge |= nb(m, 0, ly)
            edge &= ~m & ((self.owner == 0) | (self.owner < aid))
            self.a[edge] = (self.a[edge] * 0.56).astype(np.uint8)
        ys, xs = np.mgrid[0:H, 0:W]
        r = np.sqrt(((xs - W / 2) / (W / 2)) ** 2 + ((ys - H / 2) / (H / 2)) ** 2) / np.sqrt(2)
        k = np.clip((r - 0.62) / 0.38, 0, 1) ** 1.4 * 0.85
        corner = k > BAY
        self.a[corner] = (self.a[corner] * 0.84).astype(np.uint8)

    def image(self):
        if POLISH:
            self.finish()
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
        self.id = len(cv.actors) + 1
        cv.actors[self.id] = tuple(env.L)

    def part(self, alb, fn, **kw):
        m = self.cv.mask(fn, self.x, self.y, self.flip, self.k)
        kw.setdefault("emph", self.emph)
        was, self.cv.cur = self.cv.cur, self.id
        self.cv.shape(m, alb, self.env, **kw)
        self.cv.cur = was
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


# ---------------------------------------------------------------- Él (y la gente): un cuerpo de verdad
# Una persona con proporciones de adulto (de pie mide unos 58 px: la cabeza es un séptimo, las piernas
# casi la mitad), armada sobre un esqueleto: cabeza, cuello, hombros, codos, manos, cadera, rodillas,
# tobillos y la punta de los zapatos. Los brazos y las piernas se adelgazan (el muslo más que la
# pantorrilla), el saco le queda grande (solapas, la camisa y la corbata asomando), las manos y los
# zapatos tienen forma. Lo de allá (n: acá, f: allá) va primero y más oscuro. Sin cara: el pelo, la
# barba, la oreja y un pedazo de piel hacia donde mira.


def _v(p, q):
    return (q[0] - p[0], q[1] - p[1])


def _unit(v):
    n = max(1e-6, (v[0] * v[0] + v[1] * v[1]) ** 0.5)
    return (v[0] / n, v[1] / n)


def _at(p, u, k):
    return (p[0] + u[0] * k, p[1] + u[1] * k)


def _limb(d, p0, r0, p1, r1):
    """Un pedazo de brazo o de pierna: más grueso en p0 (r0) que en p1 (r1), con las puntas redondas."""
    u = _unit(_v(p0, p1))
    n = (-u[1], u[0])
    d.poly([_at(p0, n, r0), _at(p1, n, r1), _at(p1, n, -r1), _at(p0, n, -r0)])
    d.ell(p0[0], p0[1], r0, r0)
    d.ell(p1[0], p1[1], r1, r1)


def _shoe(d, ankle, toe):
    """El zapato: el talón, el empeine y la punta redonda, de la tobillera hacia la punta."""
    s = _unit(_v(ankle, toe))
    n = (s[1], -s[0])                      # "arriba" del zapato (el empeine)
    if n[1] > 0 or (abs(n[1]) < 1e-6 and n[0] < 0):
        n = (-n[0], -n[1])
    a = ankle
    d.poly([_at(_at(a, s, -1.9), n, 1.1), _at(_at(a, s, 1.6), n, 1.7), _at(_at(a, s, 4.6), n, 0.9),
            _at(_at(a, s, 5.6), n, -0.5), _at(_at(a, s, 4.8), n, -1.1), _at(_at(a, s, -1.9), n, -1.1)])
    tip = _at(_at(a, s, 4.7), n, 0.0)
    d.ell(tip[0], tip[1], 1.2, 1.2)


def _torso(d, hip, neck, front, half=(4.4, 4.9), hem=None, hem_half=None, hem_len=6.5):
    """El tronco con el saco: de la cadera a los hombros, más ancho en el pecho; el faldón del saco
    sigue hacia hem (o para abajo, por la espalda)."""
    u = _unit(_v(hip, neck))
    p = (-u[1], u[0])
    if p[0] * front[0] + p[1] * front[1] < 0:
        p = (-p[0], -p[1])
    mid = _at(hip, u, 0.55 * ((neck[0] - hip[0]) ** 2 + (neck[1] - hip[1]) ** 2) ** 0.5)
    top = _at(neck, u, -1.4)
    if hem is None:
        hem = _at(hip, u, -hem_len)
    hu = _unit(_v(hip, hem))
    if hem_half is None:  # colgando, el faldón se abre; sobre las piernas (sentado), no
        hem_half = 5.2 if abs(hu[1]) > 0.7 else 3.4
    hp = (-hu[1], hu[0])
    if hp[0] * p[0] + hp[1] * p[1] < 0:
        hp = (-hp[0], -hp[1])
    pts = [_at(neck, p, -2.0), _at(top, p, -half[1]), _at(mid, p, -half[1] + 0.2), _at(hip, p, -half[0]),
           _at(hem, hp, -hem_half), _at(hem, hp, hem_half), _at(hip, p, half[0] + 0.2), _at(mid, p, half[1]),
           _at(top, p, half[1] + 0.3), _at(neck, p, 2.2)]
    d.poly([(x, min(y, -0.4)) for x, y in pts])   # (el saco no se mete debajo del piso)
    d.ell(top[0], top[1], half[1] * 0.9, half[1] * 0.9)   # los hombros, redondos


def _head(a, cx, cy, look, hair_only=False, lying=False, hair=None, beard=None):
    """La cabeza (de adulto: unos 7x8 px), sin cara: el pelo despeinado, la oreja, un pedazo de piel
    hacia donde mira (look: dx, dy) y la barba debajo. Acostado, la cabeza va de lado."""
    hair = HAIR if hair is None else hair
    beard = BEARD if beard is None else beard
    rx, ry = (4.0, 3.4) if lying else (3.4, 4.0)
    lx, ly = look
    a.part(SKIN, lambda d: d.ell(cx, cy, rx, ry), shade=1)
    if BALD >= 2 and hair == HAIR and not getattr(a, "clean", False):  # él, ya pelado arriba (el de antes, no): queda la franja (de lado y atrás)
        k = 1.7 if BALD == 2 else 1.1
        if hair_only:  # de espaldas: la franja de la nuca
            a.part(hair, lambda d: d.ell(cx, cy + ry * 0.55, rx + 0.4, k), shade=1)
        elif abs(lx) < 0.3:  # de frente: las dos franjas encima de las orejas
            a.part(hair, lambda d: (d.ell(cx - rx + 0.4, cy + 0.6, 1.0, k), d.ell(cx + rx - 0.4, cy + 0.6, 1.0, k)), shade=1)
        else:  # de lado: la franja de atrás
            a.part(hair, lambda d: d.ell(cx - lx * 2.4, cy + 0.8, 1.6, k + 0.4), shade=1)
        a.dot(cx - lx * 0.6, cy - ry + 1.0, a.lit(SKIN, 1.3))  # el brillito de la calva
        if hair_only:
            return
        hair = None
    if hair is not None and hair_only:
        a.part(hair, lambda d: (d.ell(cx, cy, rx + 0.6, ry + 0.5), d.ell(cx - 2.4, cy - 2.6, 1.6, 1.4),
                                d.ell(cx + 2.2, cy - 2.8, 1.5, 1.3)))
        return
    # El pelo: atrás y arriba de donde mira (despeinado: mechones que se salen).
    bx, by = cx - lx * 1.5, cy - ly * 1.5 - 0.6
    if hair is not None:
        a.part(hair, lambda d: (d.ell(bx, by, rx + 0.4, ry + 0.2), d.ell(bx - lx * 2.4 + 0.6, by - 3.0, 1.7, 1.4),
                            d.ell(bx + 1.8, by - 3.2, 1.5, 1.2), d.ell(bx - lx * 3.4, by + 1.0, 1.4, 1.6)))
    # La piel de la cara (sin cara) y la oreja, al lado.
    fx, fy = cx + lx * 1.2, cy + ly * 1.2 + 0.4
    a.part(SKIN, lambda d: d.ell(fx, fy, 2.4, 2.8), shade=1)
    if abs(lx) > 0.3:
        a.dot(cx - lx * 0.6, cy + 0.2, a.lit(SKIN, 0.2))
    if getattr(a, "clean", False):  # (sin barba: el de antes)
        return
    # La barba: la quijada, hacia el pecho.
    bx2, by2 = cx + lx * 1.6 - ly * 1.6, cy + ly * 1.6 + 2.2 - abs(ly) * 1.2
    a.part(beard, lambda d: (d.ell(bx2, by2, 2.6, 1.9), d.ell(bx2 - lx * 1.2, by2 - 1.0, 1.4, 1.4)), shade=1, rim=False)


def figure(a, J, look=(1.0, 0.0), coat=COAT, pants=PANTS, shirt=SHIRT, hair=None, beard=None, tie=True,
           hair_only=False, lying=False, half=(4.4, 4.9), hem=None, bulk=1.0, shoes=None, front=None,
           far_arm=True, near_arm=True, hands=True):
    """Pinta a una persona sobre el esqueleto J (en las medidas del actor, el piso en y=0):
    head, neck, hip, sn/sf (hombros), en/ef (codos), hn/hf (manos), kn/kf (rodillas), an/af (tobillos),
    tn/tf (punta de los zapatos); hpn/hpf (dónde arranca cada pierna, si no es la cadera)."""
    front = front or (look[0] if abs(look[0]) > 0.2 else 1.0, 0.0)
    if shoes is None:  # él: uno de cada color; los demás, los dos iguales
        shoes = (SHOE_A, SHOE_B) if coat == COAT else ((62, 52, 50), (62, 52, 50))
    sh = shoes
    far = a.emph * 0.84
    k = bulk
    hpn, hpf = J.get("hpn", J["hip"]), J.get("hpf", J["hip"])

    def leg(hp, kn, an, tn, emph, shoe):
        a.part(pants, lambda d: (_limb(d, hp, 3.1 * k, kn, 2.4 * k), _limb(d, kn, 2.4 * k, an, 1.8 * k)), emph=emph)
        a.part(shoe, lambda d: _shoe(d, an, tn), emph=emph, shade=1)

    def arm(s, e, h, emph):
        a.part(coat, lambda d: (_limb(d, s, 2.4 * k, e, 2.1 * k), _limb(d, e, 2.1 * k, h, 1.7 * k)), emph=emph)
        if hands:
            a.part(SKIN, lambda d: d.ell(h[0], h[1], 1.6, 1.4), shade=1, emph=emph)

    # 1) Lo de allá: la pierna y el brazo.
    leg(hpf, J["kf"], J["af"], J["tf"], far, sh[1])
    if far_arm:
        arm(J["sf"], J["ef"], J["hf"], far)
    # 2) El tronco, con el saco grande.
    a.part(coat, lambda d: _torso(d, J["hip"], J["neck"], front, (half[0] * k, half[1] * k), hem))
    # La camisa y la corbata, asomando por las solapas (en el pecho, hacia donde mira).
    u = _unit(_v(J["hip"], J["neck"]))
    p = (-u[1], u[0])
    if p[0] * front[0] + p[1] * front[1] < 0:
        p = (-p[0], -p[1])
    if not hair_only and abs(look[0]) + abs(look[1]) > 0.3:
        nk = J["neck"]
        c0, c1, c2 = _at(_at(nk, p, 1.6 * k), u, -0.6), _at(_at(nk, p, 3.9 * k), u, -0.8), _at(_at(nk, p, 3.0 * k), u, -7.0)
        a.part(shirt, lambda d: d.poly([c0, c1, c2]), shade=0, rim=False)
        if tie:
            t0, t1 = _at(_at(nk, p, 3.1 * k), u, -1.4), _at(_at(nk, p, 3.4 * k), u, -8.5)
            a.line([a_xy(t0), a_xy(t1)], a.lit(TIE, 0.6))
    # El pliegue del saco: de la sisa a la cintura, por la espalda.
    f0, f1 = _at(_at(J["neck"], p, -2.6 * k), u, -4.0), _at(_at(J["hip"], p, -2.0 * k), u, 2.0)
    a.line([a_xy(f0), a_xy(f1)], col(coat, a.env.amb * a.emph * 0.6))
    # 3) Lo de acá: la pierna; el cuello y la cabeza; el brazo.
    leg(hpn, J["kn"], J["an"], J["tn"], a.emph, sh[0])
    nk, hd = J["neck"], J["head"]
    a.part(SKIN, lambda d: _limb(d, nk, 1.5 * k, _at(nk, _unit(_v(nk, hd)), 2.6), 1.5 * k), shade=1)
    _head(a, hd[0], hd[1], look, hair_only=hair_only, lying=lying, hair=hair, beard=beard)
    if near_arm:
        arm(J["sn"], J["en"], J["hn"], a.emph)


def a_xy(p):
    """Un punto del actor, tal cual (para las líneas: Actor.line ya lo pasa a la pantalla)."""
    return p


def _pts(a, J, head_top):
    """Lo que las escenas usan de él: la cabeza (arriba), la mano, los pies, la barriga."""
    return {"head": a.at(*head_top), "hand": a.at(*J["hn"]), "feet": a.at(*J["tn"]),
            "belly": a.at(*_at(J["hip"], _unit(_v(J["hip"], J["neck"])), 8.0))}


def man_stand(a, coat=COAT, pants=PANTS, hair=HAIR, beard=BEARD, hat=None, hold_hat=None, tie=True, bulk=1.0,
              near_arm=True):
    """De pie, quieto, mirando a la derecha. Origen: los pies. (También sirve para Samuel y los demás.)"""
    J = {"head": (0.9, -53.4), "neck": (0.4, -48.6), "hip": (0.0, -30.0),
         "sn": (1.0, -45.6), "sf": (-1.4, -45.8), "en": (1.6, -36.6), "ef": (-1.6, -36.8),
         "hn": (2.2, -28.4), "hf": (-1.0, -28.6), "kn": (1.4, -16.0), "kf": (-1.0, -16.2),
         "an": (1.0, -2.6), "af": (-1.8, -2.6), "tn": (6.6, -1.4), "tf": (3.8, -1.4)}
    if hold_hat is not None:  # el sombrero, contra el pecho
        J["en"], J["hn"] = (4.6, -38.0), (3.4, -37.0)
    figure(a, J, (1.0, 0.1), coat=coat, pants=pants, hair=hair, beard=beard, tie=tie, bulk=bulk, hem=(0.3, -22.5),
           near_arm=near_arm)
    if hat is not None:
        a.part(hat, lambda d: (d.ell(0.6, -56.8, 4.4, 2.2), d.rect(1.6, -56.4, 7.6, -55.2)))
    if hold_hat is not None:
        a.part(hold_hat, lambda d: d.ell(3.0, -36.0, 3.8, 2.2))
    return {"head": a.at(0, -58)}


def man_bench(a, b=0, awake=False, pack=True):
    """Sentado en un banco (o en el borde de la cama), mirando a la derecha. Origen: el piso bajo la cadera; el asiento, a 20."""
    if awake:  # doblado para adelante, los codos en las rodillas
        J = {"head": (11.2, -45.4), "neck": (8.6, -41.4), "hip": (2.0, -23.0),
             "sn": (8.2, -38.8), "sf": (6.4, -39.4), "en": (16.4, -27.6), "ef": (14.6, -28.4),
             "hn": (20.4, -19.6), "hf": (18.6, -20.4), "kn": (19.6, -23.6), "kf": (17.6, -24.4),
             "an": (22.0, -3.0), "af": (16.4, -3.0), "tn": (28.0, -1.4), "tf": (22.4, -1.4)}
        figure(a, J, (0.55, 0.8), hem=(9.0, -23.0))
        return {"head": a.at(10, -51), "hand": a.at(*J["hn"]), "feet": a.at(26, -2)}
    J = {"head": (-6.6, -48.2 - b), "neck": (-4.6, -43.6 - b), "hip": (1.0, -23.0),
         "sn": (-3.4, -41.0 - b), "sf": (-5.4, -41.4 - b), "en": (5.0, -32.4 - b), "ef": (3.4, -33.0 - b),
         "hn": (17.6, -35.0 - b), "hf": (15.0, -35.6 - b), "kn": (19.8, -23.4), "kf": (17.8, -24.2),
         "an": (22.0, -3.0), "af": (16.4, -3.0), "tn": (28.0, -1.4), "tf": (22.4, -1.4)}
    if pack:  # la mochila, abrazada (el brazo de allá queda detrás de ella)
        figure(a, J, (0.6, -0.75), hem=(10.0, -23.0), near_arm=False)
        a.part(PACK, lambda d: d.cap(9, -31 - b, 18, -31 - b, 11.5))
        a.line([(5, -33 - b), (22, -33 - b)], a.lit(PACK, -0.5))
        a.part(COAT, lambda d: (_limb(d, J["sn"], 2.4, J["en"], 2.1), _limb(d, J["en"], 2.1, J["hn"], 1.7)))
        a.part(SKIN, lambda d: d.ell(J["hn"][0], J["hn"][1], 1.6, 1.4), shade=1)
    else:
        figure(a, J, (0.6, -0.75), hem=(10.0, -23.0))
    return {"head": a.at(-7, -53 - b), "hand": a.at(*J["hn"]), "feet": a.at(26, -2)}


def man_sit(a, b=0, mode="dormido"):
    """En el piso, las rodillas arriba, mirando a la derecha. mode: dormido (la cabeza en los brazos),
    alerta (la cabeza arriba) o golpeado (la mano en la cara). Origen: el piso, bajo la cola."""
    legs = {"hip": (1.0, -6.0), "kn": (15.6, -19.0), "kf": (13.4, -17.6),
            "an": (23.0, -3.0), "af": (18.4, -3.0), "tn": (29.0, -1.4), "tf": (24.4, -1.4)}
    if mode == "dormido":  # encogido: la cabeza escondida en los brazos, sobre las rodillas
        J = dict(legs, head=(15.0, -27.6 - b), neck=(10.4, -24.4 - b), sn=(8.8, -23.0 - b), sf=(7.4, -23.6 - b),
                 en=(15.0, -19.0), ef=(13.4, -19.6), hn=(24.0, -21.2), hf=(22.4, -21.8))
        figure(a, J, (0.0, 0.0), hair_only=True, hem=(7.4, -11.6), near_arm=False)
        a.part(COAT, lambda d: (_limb(d, J["sn"], 2.4, (17.4, -22.0), 2.1), _limb(d, (17.4, -22.0), 2.1, (25.2, -22.6), 1.7)))
        a.part(SKIN, lambda d: d.ell(25.6, -22.6, 1.6, 1.4), shade=1)
        return {"head": a.at(15, -33 - b), "hand": a.at(25, -22)}
    J = dict(legs, head=(6.4, -32.2 - b), neck=(4.8, -27.4 - b), sn=(5.4, -24.6 - b), sf=(3.4, -25.0 - b),
             en=(14.0, -18.6), ef=(12.4, -19.4), hn=(24.0, -21.6), hf=(22.0, -22.2))
    if mode == "golpeado":  # la mano en la cara (y lo que le quedó)
        J["en"], J["hn"] = (13.6, -23.0 - b), (9.6, -30.6 - b)
        figure(a, J, (0.8, 0.3), hem=(7.4, -11.6))
        a.dot(8, -34 - b, (214, 56, 60))
        a.dot(9, -35 - b, (214, 56, 60))
    else:
        figure(a, J, (0.8, 0.3), hem=(7.4, -11.6))
    return {"head": a.at(6, -38 - b), "hand": a.at(*J["hn"])}


def man_wake(a, b=0, reach=False):
    """Recién despierto: sentado en el piso, las piernas estiradas, mirando a la derecha. Origen: bajo la cadera."""
    J = {"head": (4.6, -31.8), "neck": (3.0, -27.2), "hip": (0.0, -5.6),
         "sn": (3.2, -24.4), "sf": (1.0, -24.8), "ef": (-5.2, -14.6), "hf": (-9.4, -2.6),
         "kn": (15.8, -7.4), "kf": (14.0, -6.6), "an": (30.4, -4.4), "af": (28.4, -4.0),
         "tn": (33.0, -10.0), "tf": (30.8, -9.6)}
    if reach:  # la mano, a Lukas
        J["en"], J["hn"] = (11.0, -19.4), (19.6, -13.6)
    else:      # la mano, a la cara
        J["en"], J["hn"] = (11.2, -21.0), (7.8, -29.6)
    figure(a, J, (0.8, 0.3), hem=(8.0, -7.0))
    return {"head": a.at(5, -37), "hand": a.at(*J["hn"])}


def man_side(a, b=0, away=False, reach=False, still=False):
    """Dormido de lado, encogido, la cabeza a la izquierda. Origen: el piso, bajo la cadera."""
    J = {"head": (-31.6, -8.6), "neck": (-26.4, -8.4), "hip": (0.0, -7.0),
         "hpn": (0.4, -9.6), "hpf": (0.4, -4.4),
         "sn": (-23.4, -12.2 - b * 0.5), "sf": (-23.4, -4.2),
         "ef": (-31.6, -2.8), "hf": (-41.6, -2.6),
         "kn": (12.6, -13.2), "kf": (12.0, -4.4), "an": (25.6, -8.0), "af": (25.0, -3.0),
         "tn": (31.4, -7.8), "tf": (30.8, -2.6)}
    hand = (-26.0, -2.0) if reach else (-18.8, -2.4)
    J["en"], J["hn"] = (-13.6, -9.6 - b * 0.5), hand
    figure(a, J, (0.0, 0.0) if away else (0.7, 0.4), hair_only=away, lying=True, half=(5.4 + b * 0.3, 6.0 + b * 0.4),
           hem=(6.0, -7.0), front=(0.0, 1.0))
    return {"head": a.at(-32, -15), "feet": a.at(31, -6), "belly": a.at(-10, -1), "hand": a.at(-42, -2)}


def man_back(a, b=0, arms="chest"):
    """Boca arriba, tieso, la cabeza a la izquierda. Origen: el piso (o el colchón), bajo la cadera."""
    J = {"head": (-29.6, -7.6 - (3.0 if arms == "eyes" else 0.0)), "neck": (-24.6, -6.4), "hip": (0.0, -5.4),
         "sn": (-21.6, -7.6 - b * 0.5), "sf": (-21.6, -6.2), "ef": (-14.0, -4.2), "hf": (-7.0, -2.6),
         "kn": (15.0, -5.4), "kf": (15.0, -6.0), "an": (31.0, -5.4), "af": (31.0, -6.2),
         "tn": (32.4, -11.6), "tf": (32.2, -12.2)}
    if arms == "eyes":  # el brazo, sobre los ojos
        a.part(PACK, lambda d: d.cap(-42, -4.5, -33, -4.5, 9))
        J["en"], J["hn"] = (-27.6, -17.0), (-31.6, -11.6)
    elif arms == "chest":
        J["en"], J["hn"] = (-15.0, -3.6), (-11.6, -12.0 - b)
    else:
        J["en"], J["hn"] = (-14.0, -3.6), (-6.4, -2.4)
    figure(a, J, (0.1, -0.9), lying=True, half=(4.2 + b * 0.3, 4.6 + b * 0.4), hem=(6.0, -5.4), front=(0.0, -1.0))
    return {"head": a.at(-30, -15), "feet": a.at(32, -8), "belly": a.at(-10, -12 - b), "hand": a.at(*J["hn"])}


# ---------------------------------------------------------------- Lukas
# Un beagle de verdad, de su tamaño (sentado, la cabeza le llega a la cadera de él): el lomo con la
# montura negra, el pecho y las patas blancas, las patas con su codo y su corvejón, el cráneo canela y el
# hocico blanco y largo, la oreja larga y caída, la cola parada con la punta blanca.


def _lukas_head(a, cx, cy, ear_up=False, eye=True, tilt=0.0, down=False):
    """La cabeza, mirando a la derecha: el cráneo, el hocico (tilt: lo levanta), la oreja, la nariz, el ojo."""
    a.part(TAN, lambda d: (d.ell(cx, cy, 3.7, 3.3), d.ell(cx + 1.6, cy - 0.4 - tilt * 0.3, 2.6, 2.6)))
    mx, my = cx + 4.6, cy + 1.0 - tilt
    a.part(WHITE, lambda d: (_limb(d, (cx + 2.0, cy + 0.2 - tilt * 0.5), 2.2, (mx + 1.4, my), 1.6),
                             d.ell(mx - 0.4, my + 0.6, 1.8, 1.3)), shade=1)                        # el hocico
    a.part(WHITE, lambda d: d.poly([(cx + 0.6, cy - 3.2), (cx + 1.6, cy - 3.3), (cx + 2.4, cy + 0.2), (cx + 1.4, cy + 0.4)]),
           shade=0, rim=False)                                                                     # la franja
    if ear_up:
        a.part(EAR, lambda d: d.poly([(cx - 2.6, cy - 1.2), (cx - 1.2, cy - 7.4), (cx + 0.2, cy - 1.6)]))
    else:
        a.part(EAR, lambda d: (d.ell(cx - 1.4, cy + 2.2, 1.9, 3.8), d.ell(cx - 1.0, cy - 0.6, 1.6, 1.6)))   # la oreja, caída
    a.dot(mx + 2.2, my - 0.6, (22, 18, 22))                                                        # la nariz
    a.dot(mx + 2.4, my - 0.2, (22, 18, 22))
    if eye == "closed":
        a.line([(cx + 0.6, cy - 0.8), (cx + 2.2, cy - 0.6)], (40, 30, 30))
    elif eye:
        a.dot(cx + 1.4, cy - 1.0, (20, 16, 20))


def _dog_leg(a, pts, rs, emph=None, paw=True):
    """Una pata: de arriba (gruesa) a la pata (delgada), blanca, con la patica redonda."""
    kw = {} if emph is None else {"emph": emph}
    a.part(WHITE, lambda d: [(_limb(d, pts[i], rs[i], pts[i + 1], rs[i + 1])) for i in range(len(pts) - 1)], shade=1, **kw)
    if paw:
        p = pts[-1]
        a.part(WHITE, lambda d: d.ell(p[0] + 0.8, p[1] - 0.4, 1.6, 1.0), shade=1, **kw)


def lukas_curl(a, b=0, eye=False):
    """Hecho un ovillo, la cabeza a la derecha, sobre las patas. Origen: el piso, en la mitad."""
    a.part(TAN, lambda d: (d.ell(-1.0, -5.2 - b * 0.4, 10.0, 5.0 + b * 0.4), d.ell(-7.0, -4.4, 4.6, 4.2)))
    a.part(BLACK, lambda d: d.ell(-2.0, -7.6 - b * 0.4, 7.4, 2.8 + b * 0.3), shade=1)              # la montura
    a.part(TAN, lambda d: (_limb(d, (-10.0, -3.0), 1.6, (-4.0, -1.0), 1.2), _limb(d, (-4.0, -1.0), 1.2, (2.0, -0.8), 1.0)), shade=1)
    a.part(WHITE, lambda d: d.ell(2.6, -0.9, 1.4, 1.0), shade=0, rim=False)                        # la punta de la cola
    _dog_leg(a, [(5.0, -2.4), (10.4, -1.0)], [1.6, 1.2])                                           # las patas de adelante
    _lukas_head(a, 8.6, -4.6, eye=eye)
    return {"back": a.at(-2, -11 - b)}


def lukas_down(a, b=0, head="up", ear_up=False, eye=True, tail_up=True):
    """Echado como una esfinge, mirando a la derecha. head: up (de guardia) o down (sobre las patas).
    tail_up: la cola parada (de guardia) o caída (dormido). Origen: el piso, donde van las patas de adelante."""
    if tail_up:
        a.part(TAN, lambda d: (_limb(d, (-22.4, -6.0), 1.5, (-26.0, -10.0), 1.1), _limb(d, (-26.0, -10.0), 1.1, (-27.4, -13.4), 0.9)), shade=1)
        a.dot(-27.6, -14.2, a.lit(WHITE, 0.6))                                                     # la cola
    else:
        a.part(TAN, lambda d: (_limb(d, (-22.4, -5.0), 1.5, (-27.0, -3.0), 1.1), _limb(d, (-27.0, -3.0), 1.1, (-30.4, -2.2), 0.9)), shade=1)
        a.dot(-31.2, -2.2, a.lit(WHITE, 0.6))
    _dog_leg(a, [(-17.0, -3.6), (-12.4, -1.4)], [2.0, 1.3], emph=a.emph * 0.84)                    # la de atrás, de allá
    a.part(TAN, lambda d: (d.ell(-17.6, -5.0, 5.6, 4.6), _limb(d, (-17.0, -5.6 - b * 0.4), 4.8 + b * 0.3, (-4.0, -6.2), 4.2)))
    a.part(BLACK, lambda d: _limb(d, (-17.0, -8.4 - b * 0.4), 2.6, (-6.4, -8.8), 2.0), shade=1)     # la montura
    a.part(WHITE, lambda d: d.ell(-2.0, -5.2, 2.8, 3.6), shade=1)                                  # el pecho
    _dog_leg(a, [(-2.6, -2.6), (4.0, -1.2), (8.4, -1.0)], [1.8, 1.3, 1.1])                         # las de adelante, estiradas
    _dog_leg(a, [(-15.2, -2.8), (-9.4, -1.0)], [2.0, 1.2])                                         # la de atrás, de acá
    if head == "up":
        a.part(TAN, lambda d: _limb(d, (-2.4, -8.2), 3.2, (0.6, -12.4), 2.4))                      # el cuello
        _lukas_head(a, 2.4, -14.6, ear_up, eye)
        return {"head": a.at(3, -19)}
    _lukas_head(a, 4.8, -4.6, ear_up, eye)
    return {"head": a.at(5, -9)}


def lukas_sit(a, wag=0, up=True):
    """Sentado, mirando a la derecha (y para arriba: a él). Origen: el piso, bajo las patas de adelante."""
    a.part(TAN, lambda d: (_limb(d, (-12.0, -4.6), 1.5, (-16.0, -8.6 - wag * 2.4), 1.1),
                           _limb(d, (-16.0, -8.6 - wag * 2.4), 1.1, (-17.0, -12.6 - wag * 3.0), 0.9)), shade=1)
    a.dot(-17.2, -13.4 - wag * 3.0, a.lit(WHITE, 0.6))                                             # la cola, con la punta blanca
    _dog_leg(a, [(-2.0, -10.0), (-1.4, -4.6), (-1.0, -0.6)], [1.7, 1.3, 1.1], emph=a.emph * 0.84)  # la de adelante, de allá
    a.part(TAN, lambda d: (d.ell(-8.0, -5.4, 5.2, 4.8), _limb(d, (-7.4, -6.4), 4.4, (-1.6, -13.0), 3.8)))   # el anca y el lomo
    a.part(BLACK, lambda d: _limb(d, (-8.4, -8.6), 2.4, (-3.6, -14.0), 2.0), shade=1)               # la montura
    a.part(WHITE, lambda d: d.ell(0.8, -11.2, 2.6, 3.8), shade=1)                                  # el pecho
    _dog_leg(a, [(-6.0, -2.8), (-2.6, -0.8)], [1.8, 1.1])                                          # la de atrás, doblada
    _dog_leg(a, [(0.4, -9.4), (0.8, -4.6), (1.2, -0.6)], [1.8, 1.3, 1.1])                          # la de adelante, de acá
    a.part(TAN, lambda d: _limb(d, (-0.6, -13.6), 3.0, (1.2, -17.4), 2.4))                         # el cuello
    _lukas_head(a, 2.4, -19.6, tilt=1.4 if up else 0.0)
    return {"head": a.at(3, -24)}


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
