"""El coliseo del torneo (Highway to Hell): el fondo de TenisMatch, en 320x180.

La cancha se ve desde atrás del de abajo, en perspectiva: el fondo más angosto. La cuenta es la misma
de TenisMatch.w2s (si se cambia allá, se cambia aquí):
    pantalla.x = 160 + x * kx(y),   kx = de 10.5 (fondo) a 13.5 (frente) a lo largo de la cancha
    pantalla.y = 104 + y * 4.6
Aquí va lo quieto: el piso del coliseo, el azul de afuera, el verde de adentro, las vallas con los
patrocinadores (los del barrio), las tribunas con la gente, los reflectores y la silla del juez. Las
rayas, la red, los jugadores y la pelota los pinta el juego encima.

Salida: assets/tenis/coliseo.png (el público sentado) y coliseo_grita.png (el mismo público de pie,
con los brazos arriba: para cuando hay un punto bueno).
Uso: python tools/art/draw_tenis_coliseo.py  (desde la carpeta del proyecto)"""
import random
from pathlib import Path
from PIL import Image

W, H = 320, 180
OUT = Path("assets/tenis")
CX, CY, SY, KX_FAR, KX_NEAR = 160, 104, 4.6, 10.5, 13.5   # (ancha: que los tenistas no se vean gigantes)
HALF_L, HALF_W, DOUBLES = 11.885, 4.115, 4.115 + 1.37
RUN_X, RUN_Y = DOUBLES + 2.4, HALF_L + 5.0      # hasta dónde llega el azul de afuera

OUTLINE = (40, 32, 44)
FLOOR = (34, 36, 52)
FLOOR_D = (28, 30, 44)
BLUE = (66, 104, 158)
BLUE_D = (58, 94, 146)
GREEN = (60, 120, 98)
GREEN_D = (54, 110, 90)
BOARD = (24, 26, 36)


def kx(y):
    t = (y + HALF_L) / (2 * HALF_L)
    return KX_FAR + (KX_NEAR - KX_FAR) * t


def w2s(x, y):
    return CX + x * kx(y), CY + y * SY


class Img:
    def __init__(self):
        self.im = Image.new("RGB", (W, H), FLOOR)
        self.px = self.im.load()

    def dot(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < W and 0 <= y < H:
            self.px[x, y] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.dot(x, y, c)

    def trap(self, half_x, y0, y1, c, c2=None):
        """Un trapecio de la cancha (de -half_x a half_x en metros, de y0 a y1), con rayado suave."""
        sy0, sy1 = int(round(CY + y0 * SY)), int(round(CY + y1 * SY))
        for sy in range(sy0, sy1 + 1):
            y = (sy - CY) / SY
            a, b = w2s(-half_x, y)[0], w2s(half_x, y)[0]
            for sx in range(int(round(a)), int(round(b)) + 1):
                col = c
                if c2 and (sx * 3 + sy * 5) % 23 == 0:  # el grano del cemento, apenas
                    col = c2
                self.dot(sx, sy, col)


# ---------------------------------------------------------------- Letras chiquitas (3x5)
GLYPHS = {
    "A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
    "E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
    "I": "111010010010111", "J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
    "M": "101111111101101", "N": "110101101101101", "O": "010101101101010", "P": "110101110100100",
    "R": "110101110101101", "S": "011100010001110", "T": "111010010010010", "U": "101101101101111",
    "V": "101101101101010", "W": "101101111111101", "Y": "101101010010010", "Z": "111001010100111", " ": "000000000000000",
    "$": "011110010011110", "!": "010010010000010", "-": "000000111000000", "0": "111101101101111",
    "Á": "010101111101101", "Í": "111010010010111", "Ó": "010101101101010", "Ñ": "110101101101101",
}


def text(img, s, x, y, c):
    for ch in s:
        g = GLYPHS.get(ch.upper(), GLYPHS[" "])
        for i, bit in enumerate(g):
            if bit == "1":
                img.dot(x + i % 3, y + i // 3, c)
        x += 4
    return x


def text_w(s):
    return len(s) * 4 - 1


# ---------------------------------------------------------------- La gente de las tribunas
SKINS = [(236, 182, 152), (206, 150, 116), (160, 108, 80), (120, 78, 58), (244, 200, 170)]
HAIRS = [(40, 32, 30), (70, 50, 40), (110, 76, 50), (196, 160, 90), (30, 28, 32), (150, 150, 150)]
SHIRTS = [(206, 52, 56), (246, 210, 64), (40, 52, 104), (238, 238, 232), (90, 160, 90), (240, 112, 112),
          (120, 80, 150), (240, 150, 60), (60, 140, 190), (50, 50, 60)]


def person(img, x, y, rng, standing, back=False):
    """Una persona de la tribuna (5x6): cabeza 3x3 con pelo, hombros de su camiseta. De pie, más alta y
    con los brazos arriba (o una bandera)."""
    skin, hair, shirt = rng.choice(SKINS), rng.choice(HAIRS), rng.choice(SHIRTS)
    shirt = tuple(int(c * 0.8 + 50 * 0.2) for c in shirt)    # en la penumbra de la tribuna
    up = 1 if standing else 0
    y -= up
    img.rect(x, y + 3, x + 4, y + 5, shirt)                 # los hombros
    img.dot(x, y + 5, tuple(max(0, c - 30) for c in shirt))
    img.rect(x + 1, y, x + 3, y + 2, skin)                  # la cabeza
    img.rect(x + 1, y, x + 3, y, hair)
    if back:
        img.rect(x + 1, y, x + 3, y + 1, hair)
    elif rng.random() < 0.15:
        img.dot(x + 1, y + 1, hair)                          # pelo largo, de lado
    if standing:
        kind = rng.random()
        if kind < 0.55:                                      # los brazos arriba
            img.dot(x, y + 1, skin)
            img.dot(x, y + 2, shirt)
            img.dot(x + 4, y + 1, skin)
            img.dot(x + 4, y + 2, shirt)
        elif kind < 0.65:                                    # la bandera de Colombia
            img.rect(x + 4, y - 3, x + 6, y - 3, (246, 210, 64))
            img.rect(x + 4, y - 2, x + 6, y - 2, (40, 60, 150))
            img.dot(x + 4, y - 1, (206, 52, 56))
            img.dot(x + 5, y - 1, (206, 52, 56))
            img.dot(x + 6, y - 1, (206, 52, 56))
            img.dot(x + 4, y, (90, 80, 70))
            img.dot(x + 4, y + 1, (90, 80, 70))


STEP = (52, 54, 70)
STEP_D = (44, 46, 60)
AISLE = (70, 72, 88)


def stands_side(img, side, standing, seed):
    """Una tribuna de costado: gradas paralelas a la valla, escalonadas hacia afuera (más arriba, más
    lejos), con pasillos de escalera cada tanto. Cada grada, un poco más oscura."""
    # Primero el cemento: la grada (clara) y su borde (oscuro), y los pasillos.
    for sy in range(30, H):
        y = (sy - CY) / SY
        edge = w2s(RUN_X * side, y)[0]
        aisle = (sy - 30) % 40 < 4
        for row in range(10):
            for k in range(6):
                x = edge + side * (6 + row * 6 + k)
                c = STEP if k < 5 else STEP_D
                if aisle:
                    c = AISLE if k < 5 else STEP
                img.dot(x if side > 0 else x - 1, sy, c)
    for row in range(10):
        shade = 0.92 - row * 0.04
        for k in range(30):
            sy = 33 + k * 5 + (row % 2) * 2
            if sy > 176:
                break
            if (sy - 30) % 40 < 6:
                continue                                     # el pasillo
            y = (sy - CY) / SY
            edge = w2s(RUN_X * side, y)[0]
            x = edge + side * (6 + row * 6) - (4 if side < 0 else 0)
            if x < -5 or x > W:
                continue
            r = random.Random(seed * 1000 + row * 50 + k)
            if r.random() < 0.18:
                continue                                     # un puesto vacío
            before = img.im.copy()
            person(img, x, sy, r, standing and r.random() < 0.85)
            if shade < 1.0:
                _dim_region(img, before, int(x) - 1, sy - 5, int(x) + 7, sy + 6, shade)


def _dim_region(img, before, x0, y0, x1, y1, k):
    b = before.load()
    for y in range(max(0, y0), min(H, y1 + 1)):
        for x in range(max(0, x0), min(W, x1 + 1)):
            if img.px[x, y] != b[x, y]:
                img.px[x, y] = tuple(int(c * k) for c in img.px[x, y])


def stands_back(img, standing, seed):
    """La tribuna del fondo, detrás del de arriba: de espaldas a la pared, mirando la cancha."""
    for row in range(3):
        img.rect(0, row * 5 + 5, W - 1, row * 5 + 5, STEP_D)
        for k in range(64):
            x = 2 + k * 5 + (row % 2) * 2
            y = 1 + row * 5
            if k % 13 == 6:
                continue                                     # el pasillo
            r = random.Random(seed * 77 + row * 100 + k)
            if r.random() < 0.12:
                continue
            person(img, x, y, r, standing and r.random() < 0.8)


def boards(img):
    """Las vallas de publicidad alrededor del azul. Los patrocinadores son los del barrio."""
    top = int(round(CY - RUN_Y * SY)) - 1
    img.rect(0, top - 9, W - 1, top - 1, BOARD)
    img.rect(0, top - 1, W - 1, top - 1, OUTLINE)
    ads = [("HIGHWAY TO HELL", (240, 70, 50)), ("LA CAVERNA DEL GAMER", (110, 210, 120)),
           ("PANADERÍA DON GERMÁN", (246, 210, 64))]
    x = 88  # a la izquierda va el tablero del marcador, encima
    for s, c in ads:
        x = text(img, s, x, top - 7, c) + 10
    # Las de los costados: una franja oscura pegada al azul, con rayas de color (se leen de lado).
    for sy in range(top, H):
        y = (sy - CY) / SY
        for side in (-1, 1):
            edge = w2s(RUN_X * side, y)[0]
            for k in range(4):
                c = BOARD if k < 3 else OUTLINE
                if k == 1 and (sy // 6) % 4 == 0:
                    c = (240, 70, 50)
                img.dot(edge + side * (1 + k), sy, c)


def lights(img):
    """Los reflectores del techo: manchas de luz sobre la cancha (más claras en el centro)."""
    for lx, ly in ((110, 60), (210, 60), (110, 150), (210, 150)):
        for y in range(ly - 22, ly + 22):
            for x in range(lx - 30, lx + 30):
                if not (0 <= x < W and 0 <= y < H):
                    continue
                d = ((x - lx) / 30) ** 2 + ((y - ly) / 22) ** 2
                if d < 1.0:
                    c = img.px[x, y]
                    k = 1.0 + 0.06 * (1 - d)
                    img.px[x, y] = tuple(min(255, int(v * k)) for v in c)


def umpire(img):
    """La silla del juez, al lado de la red (a la derecha), con el juez sentado arriba."""
    x = int(w2s(RUN_X, 0)[0]) - 14
    y = CY
    legs = (120, 110, 100)
    for k in range(14):
        img.dot(x + 1, y - k, legs)
        img.dot(x + 7, y - k, legs)
    for k in range(0, 14, 4):
        img.rect(x + 1, y - k, x + 7, y - k, legs)
    img.rect(x, y - 16, x + 8, y - 14, (70, 60, 56))          # el asiento
    img.rect(x + 2, y - 23, x + 6, y - 17, (40, 52, 104))      # el juez (saco azul)
    img.rect(x + 3, y - 27, x + 5, y - 24, (236, 182, 152))    # la cabeza
    img.rect(x + 3, y - 27, x + 5, y - 27, (150, 150, 150))    # canas
    img.dot(x + 2, y - 20, (236, 182, 152))
    # el contorno a mano
    for (a, b) in ((x - 1, y - 28), (x + 9, y - 13)):
        pass


def court(img):
    img.trap(RUN_X, -RUN_Y, RUN_Y, BLUE, BLUE_D)
    img.trap(DOUBLES, -HALF_L, HALF_L, GREEN, GREEN_D)


def outline_trap(img):
    """Una raya oscura donde termina el azul (la valla le hace sombra)."""
    top = int(round(CY - RUN_Y * SY))
    for sy in range(top, H):
        y = (sy - CY) / SY
        for side in (-1, 1):
            img.dot(w2s(RUN_X * side, y)[0], sy, OUTLINE)
    a, b = w2s(-RUN_X, -RUN_Y)[0], w2s(RUN_X, -RUN_Y)[0]
    img.rect(a, top, b, top, OUTLINE)


def floor(img):
    for y in range(H):
        for x in range(W):
            if (x + y * 2) % 7 == 0:
                img.dot(x, y, FLOOR_D)


def build(standing):
    img = Img()
    floor(img)
    court(img)
    outline_trap(img)
    stands_back(img, standing, 3)
    boards(img)
    stands_side(img, -1, standing, 11)
    stands_side(img, 1, standing, 23)
    umpire(img)
    lights(img)
    return img.im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    build(False).save(OUT / "coliseo.png")
    build(True).save(OUT / "coliseo_grita.png")
    print("ok")


if __name__ == "__main__":
    main()
