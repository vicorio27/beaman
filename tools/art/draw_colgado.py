"""El protagonista colgado del camión (sueño 1, parte 2): el héroe del sueño (canas, barba, saco sin
mangas, brazos grandes, corbata roja, jean, un zapato de cada color) colgado del borde del techo.
Mira a la izquierda (de donde vienen las motos); el juego lo espeja para mirar a la derecha.

Salida: assets/prologue/player_hang.png. Celdas de 40x48; el agarre (las manos) en (20, 2) de cada celda.
  0-1 colgado   2 se balancea (piernas a la derecha)   3 (a la izquierda)
  4-5 patada (recoge, estira)   6-7 se le soltó una mano   8-9 avanza mano sobre mano
  10-11 puño (carga, pega abajo)   12 encoge las piernas (pasa una carretilla)
Además: carretilla.png y caneca.png (lo parqueado en el carril de afuera) y bolsa_harina.png (lo que tira).
Cada parte (brazo, pierna, torso, cabeza) se dibuja con su contorno y se apila: atrás, torso, adelante.
Uso: python tools/art/draw_colgado.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image

OUT = Path("assets/prologue/player_hang.png")
CW, CH = 40, 48

O = (40, 32, 44)
SKIN, SKIN_D, SKIN_L = (214, 150, 120), (172, 110, 90), (232, 178, 146)
HAIR, CANAS, BEARD = (40, 38, 46), (116, 114, 118), (70, 62, 60)
EYE = (28, 26, 34)
SACO, SACO_D = (82, 86, 106), (54, 56, 72)
CAMISA = (206, 200, 184)
TIE, TIE_D = (206, 48, 52), (140, 30, 38)
JEAN, JEAN_D = (66, 92, 146), (44, 62, 104)
SHOE_K, SHOE_X = (46, 40, 46), (196, 64, 52)

HEAD = [  # mirando a la izquierda: cara a la izquierda, pelo atrás; mechón parado arriba
    "....hh....",
    "...hhhh...",
    ".hhhhhhhh.",
    "hhhhhhhhhh",
    "hHsshhhHhh",
    "ssesshhhHh",
    "ssssssShh.",
    "bsssssSh..",
    "bbbbbbS...",
    ".bbbbbb...",
    "..bbbb....",
]
HEAD_PAL = {"h": HAIR, "H": CANAS, "s": SKIN, "S": SKIN_D, "e": EYE, "b": BEARD}


class Layer:
    def __init__(self):
        self.px = {}

    def put(self, x, y, c):
        if 0 <= x < CW and 0 <= y < CH:
            self.px[(x, y)] = c

    def limb(self, a, b, r0, r1, color, shade, light=None):
        """Un segmento grueso (radio r0 en a, r1 en b). Sombra del lado de atrás (derecha/abajo)."""
        ax, ay = a
        bx, by = b
        dx, dy = bx - ax, by - ay
        ll = dx * dx + dy * dy or 1
        nx, ny = -dy, dx  # normal
        if nx < 0 or (nx == 0 and ny < 0):
            nx, ny = -nx, -ny
        for y in range(int(min(ay, by) - 4), int(max(ay, by) + 5)):
            for x in range(int(min(ax, bx) - 4), int(max(ax, bx) + 5)):
                t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / ll))
                px_, py_ = ax + t * dx, ay + t * dy
                r = r0 + (r1 - r0) * t
                d = ((x - px_) ** 2 + (y - py_) ** 2) ** 0.5
                if d <= r:
                    side = (x - px_) * nx + (y - py_) * ny
                    c = shade if side > r * 0.25 else color
                    if light and side < -r * 0.45:
                        c = light
                    self.put(x, y, c)

    def blob(self, cx, cy, w, h, color, shade=None):
        for y in range(h):
            for x in range(w):
                self.put(cx + x, cy + y, shade if shade and (x == w - 1 or y == h - 1) else color)

    def outlined(self):
        out = dict(self.px)
        for (x, y) in self.px:
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n not in self.px and 0 <= n[0] < CW and 0 <= n[1] < CH:
                    out[n] = O
        return out


def arm(sh, el, hand, back=False, fist=False):
    l = Layer()
    k = 0.8 if back else 1.0
    col = tuple(int(c * k) for c in SKIN)
    sh_c = tuple(int(c * k) for c in SKIN_D)
    l.limb(sh, el, 2.6, 2.0, col, sh_c, None if back else SKIN_L)  # el brazo grande (bíceps)
    l.limb(el, hand, 1.9, 1.5, col, sh_c)
    hx, hy = hand
    s = 2 if fist else 1
    l.blob(int(hx) - s, int(hy) - s, 2 * s + 1, 2 * s + 1, col, sh_c)
    return l


def leg(hip, knee, foot, back=False, shoe=SHOE_K, toe=-1):
    l = Layer()
    k = 0.8 if back else 1.0
    col = tuple(int(c * k) for c in JEAN)
    sh = tuple(int(c * k) for c in JEAN_D)
    l.limb(hip, knee, 2.4, 2.0, col, sh)
    l.limb(knee, foot, 2.0, 1.7, col, sh)
    fx, fy = int(foot[0]), int(foot[1])
    for i in range(4):
        l.put(fx + toe * i, fy + 1, shoe)
        l.put(fx + toe * i, fy + 2, shoe)
    return l


def torso(top, hip):
    """Espalda ancha, cintura angosta. El pecho (camisa y corbata) del lado izquierdo."""
    l = Layer()
    tx, ty = top
    hx, hy = hip
    rows = hy - ty
    for i in range(rows + 1):
        cx = tx + (hx - tx) * i / max(1, rows)
        half = 6.5 - 2.5 * i / max(1, rows)
        x0, x1 = int(round(cx - half)), int(round(cx + half))
        for x in range(x0, x1 + 1):
            c = SACO_D if x >= x1 - 1 else SACO
            rel = x - int(round(cx - 1.5))
            if i < rows - 1:
                if rel == 0:
                    c = TIE_D if i % 4 == 3 else TIE
                elif abs(rel) == 1 and i < 5:
                    c = CAMISA
            if i == rows:
                c = SHOE_K  # el cinturón
            l.put(x, ty + i, c)
    return l


def head(x, y):
    l = Layer()
    for j, row in enumerate(HEAD):
        for i, ch in enumerate(row):
            if ch in HEAD_PAL:
                l.put(x + i, y + j, HEAD_PAL[ch])
    return l


def frame(p: dict) -> Image.Image:
    img = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    ox = p.get("dx", 0)  # el cuerpo entero corrido (el torso y la cabeza siguen a las manos)

    def sh(v):
        return (v[0] + ox, v[1])

    layers = [
        leg(sh(p["bhip"]), p["bknee"], p["bfoot"], back=True, shoe=SHOE_X, toe=p.get("btoe", -1)),
        arm(sh((24, 17)), p["bel"], p["bhand"], back=True, fist=p.get("bfist", False)),
        torso(sh((20, 16)), sh((20, 29))),
        leg(sh(p["fhip"]), p["fknee"], p["ffoot"], toe=p.get("ftoe", -1)),
        head(15 + ox, 7),
        arm(sh((16, 17)), p["fel"], p["fhand"], fist=p.get("ffist", False)),
    ]
    if p.get("arm_behind_head"):  # la cabeza por delante del brazo (se le ve la cara)
        layers[4], layers[5] = layers[5], layers[4]
    px = img.load()
    for l in layers:
        for (x, y), c in l.outlined().items():
            px[x, y] = c + (255,)
    return img


HANG = dict(fhand=(18, 2), fel=(12, 9), bhand=(22, 2), bel=(28, 9),
            fhip=(18, 29), fknee=(18, 37), ffoot=(18, 44),
            bhip=(22, 29), bknee=(22, 37), bfoot=(23, 44), arm_behind_head=True)


def pose(**kw):
    p = dict(HANG)
    p.update(kw)
    return p


FRAMES = [
    pose(),                                                                     # 0 colgado
    pose(fknee=(17, 37), ffoot=(16, 44), bfoot=(24, 44)),                       # 1
    pose(fknee=(20, 37), ffoot=(23, 44), bknee=(24, 37), bfoot=(27, 43)),      # 2 piernas a la derecha
    pose(fknee=(16, 37), ffoot=(13, 43), bknee=(20, 37), bfoot=(18, 44)),      # 3 a la izquierda
    pose(fknee=(12, 32), ffoot=(13, 39)),                                       # 4 patada: recoge
    pose(fknee=(11, 35), ffoot=(3, 41), ftoe=-1, bknee=(23, 37), bfoot=(25, 44)),  # 5 estira (hacia abajo: a la moto)
    pose(bhand=(20, 2), bel=(26, 9), fhand=(5, 19), fel=(10, 21), arm_behind_head=False,  # 6 una mano
         fknee=(14, 37), ffoot=(11, 43), bknee=(25, 36), bfoot=(29, 42)),
    pose(bhand=(20, 2), bel=(26, 9), fhand=(6, 11), fel=(10, 17), arm_behind_head=False,  # 7
         fknee=(16, 37), ffoot=(15, 44), bknee=(23, 37), bfoot=(26, 43)),
    pose(fhand=(14, 2), fel=(9, 10), bhand=(22, 3), bel=(28, 10),               # 8 mano sobre mano
         fknee=(17, 37), ffoot=(16, 44), bfoot=(24, 44)),
    pose(fhand=(18, 3), fel=(12, 10), bhand=(25, 2), bel=(30, 9),               # 9
         fknee=(19, 37), ffoot=(20, 44), bknee=(23, 37), bfoot=(25, 44)),
    pose(bhand=(20, 2), bel=(26, 9), fhand=(22, 19), fel=(12, 19), ffist=True,  # 10 puño: carga
         arm_behind_head=False),
    pose(bhand=(20, 2), bel=(26, 9), fhand=(4, 36), fel=(9, 26), ffist=True, arm_behind_head=False,  # 11
         fknee=(19, 37), ffoot=(21, 44)),
    pose(fknee=(13, 30), ffoot=(15, 37), bknee=(18, 30), bfoot=(21, 37)),       # 12 encoge las piernas
]


def obstacles():
    """Lo que está parqueado en el carril de afuera: hay que encoger las piernas cuando pasa.
    carretilla.png: la de las frutas (44x24). caneca.png: la de la basura (16x22)."""
    WOOD, WOOD_D, WHEEL = (150, 98, 56), (104, 66, 40), (34, 30, 36)
    img = Image.new("RGBA", (44, 24), (0, 0, 0, 0))
    l = Layer.__new__(Layer)
    l.px = {}
    put = lambda x, y, c: l.px.__setitem__((x, y), c)
    for x in range(2, 42):  # la caja de madera
        for y in range(10, 18):
            put(x, y, WOOD_D if y in (13, 17) or x in (2, 41) else WOOD)
    for x in range(0, 44):  # las varas para empujarla
        put(x, 11, WOOD_D) if x < 3 else None
    fruits = [(244, 150, 40), (250, 214, 60), (120, 180, 70), (220, 60, 50), (244, 150, 40), (250, 214, 60)]
    for i in range(12):  # la fruta apilada
        cx, cy = 5 + i * 3, 8 - (i % 2) - (2 if 3 < i < 9 else 0)
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
            put(cx + dx, cy + dy, fruits[i % len(fruits)])
    for x in range(4, 40):
        if (x, 9) not in l.px:
            put(x, 9, (250, 214, 60) if x % 3 else (244, 150, 40))
    for wx in (9, 33):  # ruedas
        for dx in range(-3, 4):
            for dy in range(-3, 4):
                if dx * dx + dy * dy <= 10:
                    put(wx + dx, 20 + dy, (120, 116, 120) if dx * dx + dy * dy <= 1 else WHEEL)
    px = img.load()
    for (x, y), c in Layer.outlined(l).items():
        if 0 <= x < 44 and 0 <= y < 24:
            px[x, y] = c + (255,)
    img.save("assets/prologue/carretilla.png")

    BIN, BIN_D = (62, 120, 80), (40, 84, 56)
    img = Image.new("RGBA", (16, 22), (0, 0, 0, 0))
    l = Layer.__new__(Layer)
    l.px = {}
    for y in range(3, 21):
        for x in range(2 + (1 if y > 17 else 0), 14 - (1 if y > 17 else 0)):
            l.px[(x, y)] = BIN_D if x >= 11 or y in (8, 14) else BIN
    for x in range(1, 15):
        l.px[(x, 2)] = BIN_D
        l.px[(x, 3)] = BIN
    l.px[(7, 1)] = BIN_D
    l.px[(8, 1)] = BIN_D
    px = img.load()
    for (x, y), c in Layer.outlined(l).items():
        if 0 <= x < 16 and 0 <= y < 22:
            px[x, y] = c + (255,)
    img.save("assets/prologue/caneca.png")


def flour_bag():
    """La bolsa de harina que tira (la saca del camión de Harinas El Sol): 8x9."""
    PAPER, PAPER_D, LOGO = (236, 230, 214), (196, 188, 168), (206, 48, 52)
    l = Layer.__new__(Layer)
    l.px = {}
    for y in range(2, 9):
        for x in range(1, 7):
            l.px[(x, y)] = PAPER_D if x == 6 or y == 8 else PAPER
    for x in (2, 3, 4, 5):
        l.px[(x, 1)] = PAPER_D  # la boca amarrada
    l.px[(3, 0)] = PAPER_D
    l.px[(4, 0)] = PAPER_D
    l.px[(3, 5)] = LOGO  # el sol del logo
    l.px[(4, 5)] = LOGO
    l.px[(3, 4)] = LOGO
    img = Image.new("RGBA", (8, 9), (0, 0, 0, 0))
    px = img.load()
    for (x, y), c in Layer.outlined(l).items():
        if 0 <= x < 8 and 0 <= y < 9:
            px[x, y] = c + (255,)
    img.save("assets/prologue/bolsa_harina.png")


def main():
    obstacles()
    flour_bag()
    sheet = Image.new("RGBA", (CW * len(FRAMES), CH), (0, 0, 0, 0))
    for i, p in enumerate(FRAMES):
        sheet.paste(frame(p), (i * CW, 0))
    sheet.save(OUT)
    print("colgado:", OUT, sheet.size)


if __name__ == "__main__":
    main()
