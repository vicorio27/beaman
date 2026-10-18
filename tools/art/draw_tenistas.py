"""Los tenistas del torneo (Highway to Hell), vistos desde arriba y un poco de atrás, como la cancha.
Cada uno tiene dos filas: de espaldas (el que juega abajo) y de frente (el de arriba).

Cómo se dibujan: un esqueleto por pose (hombros, codos, manos, caderas, rodillas, pies y la raqueta)
que se pinta con piezas gruesas (2 px), el contorno oscuro del juego alrededor, y encima, a mano, lo de
cada uno (el pelo, la cara, las rayas, el tatuaje). Las proporciones son las de la gente del barrio
(unos 26 px de alto, ver draw_vecinos.py), con la raqueta aparte.

  Bublikov     altísimo y flaco, desgarbado; pelo negro despeinado; camiseta blanca con raya negra,
               pantaloneta negra. Juega como si le diera pereza (la espalda un poco caída).
  Sabalenkova  ancha de hombros, cola de caballo mona; top coral y falda; el tigre tatuado en el
               antebrazo izquierdo (rayas naranjas).
  Monfiz       alto, piel oscura, piernas largas; balaca amarilla; camiseta amarilla y negra.
  Yokovich     flaco y elástico; pelo castaño corto; camiseta roja, pantaloneta azul oscura.

Hoja: celdas de 32x42 (los pies en y = 40). Fila 0: de espaldas; fila 1: de frente. Columnas = POSES (ver abajo).
Salida: assets/tenis/<id>.png. Uso: python tools/art/draw_tenistas.py  (desde la carpeta del proyecto)
Con --preview guarda además una lámina ampliada en la carpeta temporal."""
import math
import sys
from pathlib import Path
from PIL import Image

CW, CH = 32, 42
DY = 6  # todo baja 6 px: arriba queda lugar para la raqueta del saque
OUT = Path("assets/tenis")
OUTLINE = (40, 32, 44)
EYE = (30, 28, 36)

# Las poses, en orden (es el orden de las columnas de la hoja; TenisMatch.gd usa los mismos nombres).
POSES = ["listo", "listo2", "corre1", "corre2", "corre3", "corre4", "drive_atras", "drive", "drive_fin",
         "reves_atras", "reves", "reves_fin", "saque_lanza", "saque", "saque_fin", "tirada", "piso",
         "celebra", "bravo", "dejada"]

# ---------------------------------------------------------------- Las poses (de espaldas)
# Coordenadas en la celda, vistas de espaldas: la mano derecha (la de la raqueta) queda a la derecha.
# Cada pose: hombros y caderas (centro), y para cada lado: codo, mano, rodilla, pie. "rk": la raqueta
# desde la mano derecha: ángulo (grados, 0 = a la derecha, 90 = abajo) y si va delante del cuerpo.
# "lean": cuánto se agacha (baja todo). "tilt": cuánto se tuerce el tronco (px de los hombros).
# "two": la mano izquierda también en el mango (revés a dos manos).


def P(**k):
    base = {"lean": 0, "tilt": 0, "two": False, "front": False, "head_dx": 0}
    base.update(k)
    return base


# Ojo: y crece hacia abajo. Pies en y = 34. Los números son relativos al centro x = 16.
POSE = {
    "listo": P(el=(-5, 15), hl=(-3, 19), er=(4, 16), hr=(-1, 19), kl=(-3, 27), fl=(-5, 33), kr=(3, 27), fr=(5, 33),
               rk=(-150, False), two=True, lean=1),
    "listo2": P(el=(-5, 16), hl=(-3, 20), er=(4, 17), hr=(-1, 20), kl=(-4, 28), fl=(-6, 33), kr=(4, 28), fr=(6, 33),
                rk=(-145, False), two=True, lean=2),
    "corre1": P(el=(-6, 15), hl=(-7, 18), er=(5, 13), hr=(8, 15), kl=(-4, 25), fl=(-7, 30), kr=(2, 28), fr=(3, 33),
                rk=(-40, False)),
    "corre2": P(el=(-5, 14), hl=(-5, 18), er=(5, 15), hr=(6, 18), kl=(-2, 28), fl=(-2, 33), kr=(2, 27), fr=(2, 32),
                rk=(-50, False), lean=1),
    "corre3": P(el=(-5, 13), hl=(-8, 15), er=(6, 15), hr=(7, 18), kl=(-2, 28), fl=(-3, 33), kr=(4, 25), fr=(7, 30),
                rk=(-60, False)),
    "corre4": P(el=(-5, 15), hl=(-6, 18), er=(5, 14), hr=(6, 17), kl=(-2, 27), fl=(-2, 32), kr=(2, 28), fr=(2, 33),
                rk=(-50, False), lean=1),
    "drive_atras": P(el=(-4, 15), hl=(-1, 17), er=(7, 13), hr=(10, 15), kl=(-3, 27), fl=(-5, 33), kr=(4, 27), fr=(5, 33),
                     rk=(-150, False), tilt=2, lean=1),
    "drive": P(el=(-5, 15), hl=(-7, 17), er=(6, 15), hr=(9, 18), kl=(-3, 27), fl=(-5, 33), kr=(4, 27), fr=(5, 33),
               rk=(-30, True), tilt=0, lean=1),
    "drive_fin": P(el=(-6, 13), hl=(-3, 11), er=(1, 15), hr=(-4, 12), kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(6, 32),
                   rk=(-130, False), tilt=-2),
    "reves_atras": P(el=(-6, 14), hl=(-8, 17), er=(1, 15), hr=(-7, 17), kl=(-4, 27), fl=(-5, 33), kr=(3, 27), fr=(4, 33),
                     rk=(-30, False), two=True, tilt=-2, lean=1),
    "reves": P(el=(-5, 15), hl=(-6, 19), er=(2, 16), hr=(-5, 19), kl=(-4, 27), fl=(-6, 33), kr=(3, 27), fr=(4, 33),
               rk=(-150, True), two=True, lean=1),
    "reves_fin": P(el=(-3, 13), hl=(4, 11), er=(6, 13), hr=(5, 11), kl=(-3, 27), fl=(-6, 32), kr=(3, 27), fr=(4, 33),
                   rk=(-60, False), two=True, tilt=2),
    "saque_lanza": P(el=(-5, 8), hl=(-5, 3), er=(7, 15), hr=(9, 18), kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(4, 33),
                     rk=(80, False), tilt=-1),
    "saque": P(el=(-5, 13), hl=(-4, 16), er=(6, 8), hr=(5, 4), kl=(-2, 26), fl=(-3, 32), kr=(3, 27), fr=(4, 33),
               rk=(-100, False), lean=-1),
    "saque_fin": P(el=(-5, 15), hl=(-6, 18), er=(1, 16), hr=(-4, 20), kl=(-3, 27), fl=(-4, 33), kr=(4, 26), fr=(6, 31),
                   rk=(130, True), lean=2),
    "tirada": P(el=(4, 12), hl=(10, 11), er=(8, 13), hr=(13, 12), kl=(-7, 22), fl=(-12, 21), kr=(-6, 25), fr=(-12, 24),
                rk=(-10, False), dive=True),
    "piso": P(el=(4, 26), hl=(9, 28), er=(5, 29), hr=(10, 31), kl=(-7, 27), fl=(-12, 28), kr=(-6, 30), fr=(-12, 31),
              rk=(10, False), floor=True),
    "celebra": P(el=(-6, 8), hl=(-6, 4), er=(6, 8), hr=(6, 4), kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(4, 33),
                 rk=(-80, False), lean=-1),
    "bravo": P(el=(-5, 15), hl=(-4, 20), er=(5, 15), hr=(5, 20), kl=(-2, 27), fl=(-2, 33), kr=(2, 27), fr=(2, 33),
               rk=(95, False), lean=2, head_dx=0, down=True),
    "dejada": P(el=(-5, 15), hl=(-6, 18), er=(5, 16), hr=(7, 20), kl=(-4, 28), fl=(-7, 33), kr=(4, 26), fr=(5, 33),
                rk=(-10, True), lean=3),
}

# ---------------------------------------------------------------- Los tenistas
# h: cuánto más alto (piernas y tronco). sh: medio ancho de los hombros. Los colores: s/S piel, h/H pelo,
# t/T camiseta, p/P pantaloneta (o falda), w medias, k zapato, a lo de acento (balaca, raya), r raqueta.
PLAYERS = {
    "bublikov": {
        "h": 2, "sh": 4, "slouch": 1, "skirt": False,
        "s": (236, 180, 150), "S": (205, 140, 120), "h1": (46, 38, 40), "h2": (74, 60, 58),
        "t": (238, 238, 232), "T": (196, 198, 200), "p": (38, 38, 46), "P": (24, 24, 30),
        "w": (240, 240, 236), "k": (236, 236, 230), "K": (160, 160, 164), "a": (32, 32, 38),
        "r": (60, 64, 76), "hair": "despeinado"},
    "sabalenkova": {
        "h": 0, "sh": 5, "slouch": 0, "skirt": True,
        "s": (240, 186, 156), "S": (210, 146, 122), "h1": (232, 200, 120), "h2": (196, 158, 84),
        "t": (240, 112, 112), "T": (204, 78, 92), "p": (240, 112, 112), "P": (204, 78, 92),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (190, 120, 140), "a": (240, 140, 50),
        "r": (230, 230, 236), "hair": "cola"},
    "monfiz": {
        "h": 1, "sh": 5, "slouch": 0, "skirt": False,
        "s": (120, 78, 58), "S": (88, 54, 44), "h1": (30, 26, 28), "h2": (48, 40, 42),
        "t": (246, 210, 64), "T": (210, 164, 40), "p": (34, 34, 40), "P": (22, 22, 28),
        "w": (240, 240, 236), "k": (246, 210, 64), "K": (170, 130, 40), "a": (246, 210, 64),
        "r": (34, 34, 40), "hair": "rapado"},
    "yokovich": {
        "h": 0, "sh": 4, "slouch": 0, "skirt": False,
        "s": (236, 182, 152), "S": (204, 142, 120), "h1": (98, 70, 52), "h2": (72, 50, 38),
        "t": (206, 52, 56), "T": (160, 34, 44), "p": (40, 52, 104), "P": (28, 36, 76),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (60, 70, 120), "a": (240, 240, 236),
        "r": (230, 230, 236), "hair": "corto"},
}


# ---------------------------------------------------------------- Pintar

class Canvas:
    def __init__(self):
        self.im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        self.px = self.im.load()

    def dot(self, x, y, c):
        x, y = int(round(x)), int(round(y)) + DY
        if 0 <= x < CW and 0 <= y < CH and c is not None:
            self.px[x, y] = c + (255,) if len(c) == 3 else c

    def get(self, x, y, raw=False):
        if not raw:
            y += DY
        if 0 <= x < CW and 0 <= y < CH:
            return self.px[x, y]
        return (0, 0, 0, 0)

    def line(self, a, b, c, w=2):
        """Una pieza gruesa: puntos a lo largo de a→b, de w de grueso (2 = el pixel y el de la derecha/abajo)."""
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
        for i in range(n + 1):
            t = i / max(n, 1)
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            for dx in range(w):
                for dy in range(w):
                    self.dot(math.floor(x) + dx, math.floor(y) + dy, c)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.dot(x, y, c)

    def poly(self, pts, c):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            for i in range(len(pts)):
                a, b = pts[i], pts[(i + 1) % len(pts)]
                if (a[1] <= y + 0.5 < b[1]) or (b[1] <= y + 0.5 < a[1]):
                    xs.append(a[0] + (y + 0.5 - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] - 0.5)) + 1):
                    self.dot(x, y, c)

    def outline(self):
        """El contorno del juego: todo lo vacío pegado (en cruz) a algo pintado."""
        add = []
        for y in range(CH):
            for x in range(CW):
                if self.px[x, y][3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        q = self.get(x + dx, y + dy, True)
                        if q[3] > 0 and q[:3] != OUTLINE:
                            add.append((x, y))
                            break
        for x, y in add:
            self.px[x, y] = OUTLINE + (255,)


def racket(cv, hand, ang, col, strings=(220, 224, 214)):
    """La raqueta: el mango (3 px) y la cabeza ovalada (5x7) en la dirección `ang`."""
    a = math.radians(ang)
    ux, uy = math.cos(a), math.sin(a)
    end = (hand[0] + ux * 3, hand[1] + uy * 3)
    cv.line(hand, end, (70, 54, 46), 1)                       # el mango (grip café)
    cx, cy = hand[0] + ux * 7, hand[1] + uy * 7               # el centro de la cabeza
    for k in range(28):
        t = k / 28 * math.tau
        lx, ly = math.cos(t) * 2.6, math.sin(t) * 3.6        # el óvalo, a lo largo de la raqueta
        x = cx + lx * -uy + ly * ux
        y = cy + lx * ux + ly * uy
        cv.dot(x, y, col)
    for dy in range(-2, 3):                                  # el encordado (más claro, adentro)
        for dx in range(-1, 2):
            x = cx + dx * -uy + dy * ux
            y = cy + dx * ux + dy * uy
            if cv.get(int(round(x)), int(round(y)))[3] == 0:
                cv.dot(x, y, strings)


def draw(pid: str, pose: str, front: bool) -> Image.Image:
    d = PLAYERS[pid]
    q = POSE[pose]
    cv = Canvas()
    h = d["h"]
    lean = q["lean"] + d.get("slouch", 0) * (pose in ("listo", "listo2"))
    mx = -1 if front else 1                 # de frente, la derecha queda a la izquierda de la pantalla

    def X(v):
        return 16 + v * mx

    def Y(v, part="body"):
        # Más alto: estira hacia arriba (los pies quedan en su sitio). El agachado baja el tronco.
        if q.get("dive") or q.get("floor"):
            return v
        if v >= 27:   # de la rodilla para abajo, no cambia
            return v
        return v - h + lean * (1 if v < 24 else 0.5)

    sh = d["sh"]
    hip_y, sho_y = 22, 12
    if q.get("dive"):
        # Tirado en el aire, de lado: el tronco acostado, los brazos estirados hacia la pelota.
        torso = [(X(-3), 14), (X(5), 11), (X(6), 15), (X(-2), 18)]
        hips = (X(-4), 17)
        neck = (X(6), 12)
        head_at = (X(9), 9)
    elif q.get("floor"):
        torso = [(X(-4), 25), (X(4), 25), (X(4), 30), (X(-4), 30)]
        hips = (X(-5), 28)
        neck = (X(5), 27)
        head_at = (X(8), 25)
    else:
        t = q["tilt"]
        torso = [(X(-sh + t), Y(sho_y)), (X(sh + t), Y(sho_y)), (X(3), Y(hip_y)), (X(-3), Y(hip_y))]
        hips = None
        neck = (X(t * 0.5), Y(sho_y - 1))
        head_at = (X(t * 0.5 + q["head_dx"]), Y(sho_y - 6 + (2 if q.get("down") else 0)))

    def j(name):
        x, y = q[name]
        return (X(x), Y(y))

    shoulder_l = (torso[0][0], torso[0][1] + 1)
    shoulder_r = (torso[1][0], torso[1][1] + 1)
    if q.get("dive") or q.get("floor"):
        shoulder_l = shoulder_r = (neck[0], neck[1] + 1)

    rk_ang, rk_front = q["rk"]
    if front:
        rk_ang = 180 - rk_ang
        rk_front = not rk_front
    hand_r = j("hr")

    # 1) Lo que va detrás del cuerpo.
    if not rk_front:
        racket(cv, hand_r, rk_ang, d["r"])

    # 2) Las piernas (piel; medias y zapatos abajo).
    for side in ("l", "r"):
        hip = (hips if hips else (X(-2 if side == "l" else 2), Y(hip_y + 2)))
        knee, foot = j("k" + side), j("f" + side)
        cv.line(hip, knee, d["s"])
        cv.line(knee, foot, d["s"])
        cv.line((foot[0], foot[1] - 2), foot, d["w"])
        cv.rect(foot[0] - (1 if mx * (1 if side == "r" else -1) < 0 else 0), foot[1],
                foot[0] + (2 if mx * (1 if side == "r" else -1) > 0 else 1), foot[1] + 1, d["k"])

    # 3) El tronco, la pantaloneta (o la falda).
    cv.poly(torso, d["t"])
    if not (q.get("dive") or q.get("floor")):
        y0 = Y(hip_y) - 1
        if d["skirt"]:
            cv.poly([(X(-4), y0), (X(4), y0), (X(6), y0 + 5), (X(-6), y0 + 5)], d["p"])
        else:
            cv.rect(X(-4) if mx > 0 else X(4), y0, X(4) if mx > 0 else X(-4), y0 + 4, d["p"])
            cv.dot(16, y0 + 4, None)
    else:
        cv.line((torso[3][0], torso[3][1]), hips, d["p"], 3)

    # 4) Los brazos (manga corta: el primer pedazo, color camiseta).
    for side, sho in (("l", shoulder_l), ("r", shoulder_r)):
        el, hand = j("e" + side), j("h" + side)
        if side == "l" and q["two"]:
            hand = (hand_r[0] - mx, hand_r[1] + 1)
        cv.line(sho, el, d["s"])
        cv.line(el, hand, d["s"])
        cv.line(sho, ((sho[0] * 2 + el[0]) / 3, (sho[1] * 2 + el[1]) / 3), d["t"])

    # 5) La cabeza (de espaldas: el pelo; de frente: la cara).
    hx, hy = int(round(head_at[0])) - 4, int(round(head_at[1])) - 4
    cv.line(neck, (neck[0], neck[1] - 1), d["s"])
    head(cv, d, hx, hy, front)

    # 6) Lo que va delante.
    if rk_front:
        racket(cv, hand_r, rk_ang, d["r"])

    cv.outline()
    details(cv, pid, d, pose, front, torso, j, mx, hx, hy, q)
    return cv.im


def head(cv, d, x, y, front):
    """La cabeza, 8x8 (más el pelo de cada uno)."""
    s, S, h1, h2 = d["s"], d["S"], d["h1"], d["h2"]
    for yy in range(8):
        for xx in range(8):
            if (xx in (0, 7) and yy in (0, 7)):
                continue
            cv.dot(x + xx, y + yy, s)
    style = d["hair"]
    # El pelo de arriba (siempre); de espaldas, toda la nuca.
    top = 3 if front else 6
    for yy in range(top):
        for xx in range(8):
            if (xx in (0, 7) and yy == 0):
                continue
            cv.dot(x + xx, y + yy, h1)
    if style == "despeinado":  # mechas paradas para todos lados
        for px, py in ((1, -1), (3, -2), (4, -1), (6, -1), (-1, 1), (8, 2)):
            cv.dot(x + px, y + py, h1)
        cv.dot(x + 3, y + 0, h2)
        cv.dot(x + 5, y + 1, h2)
    elif style == "cola":  # cola de caballo
        if front:
            cv.dot(x - 1, y + 2, h1)
            cv.dot(x + 8, y + 2, h1)
        else:
            for k in range(6):
                cv.dot(x + 3 + (k > 3), y + 6 + k, h1 if k % 2 == 0 else h2)
                cv.dot(x + 4 + (k > 3), y + 6 + k, h1)
        cv.dot(x + 2, y + 1, h2)
    elif style == "rapado":
        for xx in range(1, 7):
            cv.dot(x + xx, y, h2)
    elif style == "corto":
        cv.dot(x + 2, y + 1, h2)
        cv.dot(x + 5, y + 1, h2)
    if front:  # la cara: ojos, la sombra de un lado, la boca
        cv.dot(x + 2, y + 4, EYE)
        cv.dot(x + 5, y + 4, EYE)
        for yy in range(3, 8):
            cv.dot(x + 7 - (yy in (0, 7)), y + yy, S)
        cv.dot(x + 3, y + 6, S)
        cv.dot(x + 4, y + 6, S)
    else:  # de espaldas: las orejas
        cv.dot(x - 0, y + 4, s)
        cv.dot(x + 7, y + 4, s)


def details(cv, pid, d, pose, front, torso, j, mx, hx, hy, q):
    """Lo que hace a cada uno: encima del contorno, a mano."""
    px = cv.px

    def paint(x, y, c, raw=False):
        x, y = int(round(x)), int(round(y)) + (0 if raw else DY)
        if 0 <= x < CW and 0 <= y < CH and px[x, y][3] > 0 and px[x, y][:3] != OUTLINE:
            px[x, y] = c + (255,)

    standing = not (q.get("dive") or q.get("floor"))
    # La sombra de la camiseta: del lado de la izquierda de la pantalla (la luz viene de la derecha).
    for y in range(CH):
        row = [x for x in range(CW) if px[x, y][:3] == d["t"]]
        if row:
            paint(min(row), y, d["T"], True)
    for y in range(CH):
        row = [x for x in range(CW) if px[x, y][:3] == d["p"]]
        if row:
            paint(min(row), y, d["P"], True)
    ty0 = int(min(p[1] for p in torso))
    if pid == "bublikov" and standing:  # la raya negra del pecho a la cintura
        for y in range(ty0 + 1, ty0 + 9):
            paint(16 + mx, y, d["a"])
    if pid == "monfiz":  # la balaca amarilla, y la camiseta con el costado negro
        for xx in range(-1, 9):
            paint(hx + xx, hy + 2, d["a"])
        if standing:
            for y in range(ty0 + 2, ty0 + 9):
                for x in range(CW):
                    if px[x, y + DY][:3] in (d["t"], d["T"]) and (x - 16) * mx > 2:
                        paint(x, y, (40, 40, 46))
    if pid == "yokovich" and standing:  # el cuello blanco y la franja azul
        for x in range(CW):
            if px[x, ty0 + DY][:3] in (d["t"], d["T"]):
                paint(x, ty0, d["a"])
            if px[x, ty0 + 6 + DY][:3] in (d["t"], d["T"]):
                paint(x, ty0 + 6, (40, 52, 104))
    if pid == "sabalenkova":  # el tigre: rayas naranjas en el antebrazo izquierdo
        el, hand = j("el"), j("hl")
        for t in (0.35, 0.65):
            x = el[0] + (hand[0] - el[0]) * t
            y = el[1] + (hand[1] - el[1]) * t
            paint(x, y, d["a"])
        # La muñequera de la mano derecha
        hr = j("hr")
        paint(hr[0], hr[1] - 1, (255, 255, 255))
    if pid == "bublikov":  # la muñequera negra
        hr = j("hr")
        paint(hr[0], hr[1] - 1, d["a"])


def sheet(pid: str) -> Image.Image:
    out = Image.new("RGBA", (CW * len(POSES), CH * 2), (0, 0, 0, 0))
    for row, front in enumerate((False, True)):
        for col, pose in enumerate(POSES):
            out.paste(draw(pid, pose, front), (col * CW, row * CH))
    return out


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheets = {}
    for pid in PLAYERS:
        sheets[pid] = sheet(pid)
        sheets[pid].save(OUT / f"{pid}.png")
    if "--preview" in sys.argv:
        tmp = Path(sys.argv[sys.argv.index("--preview") + 1])
        lam = Image.new("RGBA", (CW * len(POSES), CH * 2 * len(sheets)), (70, 120, 96, 255))
        for i, pid in enumerate(sheets):
            lam.alpha_composite(sheets[pid], (0, i * CH * 2))
        lam.resize((lam.width * 3, lam.height * 3), Image.NEAREST).save(tmp)
    print("ok:", ", ".join(sheets))


if __name__ == "__main__":
    main()
