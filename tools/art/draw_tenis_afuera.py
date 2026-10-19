"""El coliseo del torneo visto desde la calle (City, en el potrero de arriba, entre La Caverna del
Gamer y la feria). Apareció de un día para otro: es la tribuna armada en andamio, de espaldas al
barrio, con el pasacalle de HIGHWAY TO HELL colgado de los tubos, las dos torres de luz, la reja con
los patrocinadores del barrio, los afiches de los tenistas y la entrada (el arco de rayas, la
taquilla y el torniquete). Arriba de todo, la última fila del público, de espaldas.

    python tools/art/draw_tenis_afuera.py   -> assets/barrio/coliseo_afuera.png, coliseo_afuera.json
                                               y el ícono de la raqueta (assets/items/raqueta.png)

Mide 280x112 (en el mundo, desde COLISEO_AT en Vecindario.gd). Lo que se mueve lo dibuja el juego
encima: las cabezas del público (se paran cuando hay un punto bueno), los banderines, los reflectores
de noche y la fila de la entrada. El .json lleva dónde va cada cosa.
"""
import json
import os

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "barrio")
W, H = 280, 112
INK = (34, 26, 36)
METAL = (150, 154, 166)
METAL2 = (104, 108, 122)
METAL3 = (72, 74, 88)
DARK = (40, 36, 48)
BLACK = (28, 24, 30)
RED = (206, 52, 58)
RED2 = (150, 34, 44)
ORANGE = (244, 132, 52)
YEL = (250, 214, 84)
WHITE = (236, 232, 222)
WHITE2 = (184, 178, 170)
WOOD = (132, 92, 58)
WOOD2 = (92, 62, 42)
GREEN = (76, 150, 96)

GLYPHS = {
    "A": ["010", "101", "111", "101", "101"], "E": ["111", "100", "110", "100", "111"], "G": ["011", "100", "101", "101", "011"],
    "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"], "L": ["100", "100", "100", "100", "111"],
    "O": ["010", "101", "101", "101", "010"], "T": ["111", "010", "010", "010", "010"], "W": ["10001", "10001", "10101", "10101", "01010"],
    "Y": ["101", "101", "010", "010", "010"], "N": ["1001", "1101", "1011", "1001", "1001"], "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "010", "001", "110"], "F": ["111", "100", "110", "100", "100"], "U": ["101", "101", "101", "101", "111"],
    "P": ["110", "101", "110", "100", "100"], "C": ["011", "100", "100", "100", "011"], "D": ["110", "101", "101", "101", "110"],
    "M": ["10001", "11011", "10101", "10001", "10001"], "B": ["110", "101", "110", "101", "110"],
    "V": ["101", "101", "101", "101", "010"], "K": ["101", "110", "100", "110", "101"],
    " ": ["0", "0", "0", "0", "0"],
}


def put(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((int(x), int(y)), c + (255,) if len(c) == 3 else c)


def outline(im, col=INK):
    px = im.load()
    add = []
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < im.width and 0 <= ny < im.height and px[nx, ny][3] > 0 and px[nx, ny][:3] != col:
                        add.append((x, y))
                        break
    for x, y in add:
        px[x, y] = col + (255,)
    return im


def text(im, s, x, y, col, scale=1):
    for ch in s:
        g = GLYPHS[ch]
        for j, line in enumerate(g):
            for i, c in enumerate(line):
                if c == "1":
                    for a in range(scale):
                        for b in range(scale):
                            put(im, x + i * scale + a, y + j * scale + b, col)
        x += (len(g[0]) + 1) * scale


def text_w(s, scale=1):
    return (sum(len(GLYPHS[c][0]) + 1 for c in s) - 1) * scale


# ---------------------------------------------------------------- La tribuna (de espaldas: el andamio)

STAND = (14, 266)      # de dónde a dónde va la tribuna
TOP_Y = 14             # la última fila (arriba)
FOOT_Y = 92            # el pie del andamio


def tribuna(im):
    d = ImageDraw.Draw(im)
    x0, x1 = STAND
    # Por debajo de las gradas: la sombra (se ve la parte de abajo de las tablas, en escalera).
    d.rectangle([x0, TOP_Y + 4, x1, FOOT_Y], fill=DARK)
    for k, y in enumerate(range(TOP_Y + 6, FOOT_Y - 6, 7)):
        d.line([(x0 + 1, y), (x1 - 1, y)], fill=(58, 52, 64))
        d.line([(x0 + 1, y + 1), (x1 - 1, y + 1)], fill=(50, 46, 58))
    # La última fila: la baranda de arriba y las tablas.
    d.rectangle([x0 - 2, TOP_Y, x1 + 2, TOP_Y + 3], fill=METAL2)
    d.line([(x0 - 2, TOP_Y), (x1 + 2, TOP_Y)], fill=METAL)
    # Los tubos verticales, cada 12, y los horizontales, cada 13. Las crucetas, en zigzag.
    for x in range(x0, x1 + 1, 12):
        d.line([(x, TOP_Y + 3), (x, FOOT_Y)], fill=METAL)
        d.line([(x + 1, TOP_Y + 3), (x + 1, FOOT_Y)], fill=METAL2)
    for y in range(TOP_Y + 16, FOOT_Y, 13):
        d.line([(x0, y), (x1, y)], fill=METAL2)
    for i, x in enumerate(range(x0, x1 - 11, 12)):
        for y in range(TOP_Y + 16, FOOT_Y - 12, 13):
            if (i + y // 13) % 2 == 0:
                d.line([(x + 1, y), (x + 12, y + 13)], fill=METAL3)
            else:
                d.line([(x + 12, y), (x + 1, y + 13)], fill=METAL3)
    # Las abrazaderas (los nudos de los tubos): un punto claro.
    for x in range(x0, x1 + 1, 12):
        for y in range(TOP_Y + 16, FOOT_Y, 13):
            put(im, x, y, WHITE2)
    # Las bases: tablitas de madera debajo de cada tubo.
    for x in range(x0, x1 + 1, 12):
        d.rectangle([x - 2, FOOT_Y, x + 3, FOOT_Y + 1], fill=WOOD)


# ---------------------------------------------------------------- El pasacalle

BANNER = (52, 26, 228, 54)


def pasacalle(im):
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = BANNER
    d.rectangle([x0, y0, x1, y1], fill=BLACK)
    # Las amarras a los tubos (cuerdas blancas en las esquinas).
    for (cx, cy) in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        put(im, cx, cy, WHITE)
    # Las llamas de abajo: puntas naranjas y rojas, con el centro amarillo.
    for x in range(x0 + 1, x1):
        h = 3 + (x * 7 % 5) + (2 if x % 9 == 0 else 0)
        for k in range(h):
            c = YEL if k < 1 else (ORANGE if k < h - 2 else RED)
            put(im, x, y1 - k, c)
    # La pelota con cachos (el logo), a la izquierda.
    bx, by = x0 + 13, y0 + 12
    d.ellipse([bx - 6, by - 6, bx + 6, by + 6], fill=(200, 220, 70))
    d.arc([bx - 9, by - 5, bx + 1, by + 9], 300, 60, fill=WHITE)
    d.arc([bx - 1, by - 9, bx + 9, by + 5], 120, 240, fill=WHITE)
    for s in (-1, 1):  # los cachos
        put(im, bx + s * 4, by - 7, RED)
        put(im, bx + s * 5, by - 8, RED)
        put(im, bx + s * 5, by - 9, RED2)
    # HIGHWAY TO HELL, grande (al doble), con sombra roja.
    t = "HIGHWAY TO HELL"
    tw = text_w(t, 2)
    tx = x0 + 26 + (x1 - x0 - 26 - tw) // 2
    text(im, t, tx + 1, y0 + 5, RED2, 2)
    text(im, t, tx, y0 + 4, YEL, 2)
    # Abajo, chiquito: TENNIS MAYHEM.
    t2 = "TENNIS MAYHEM"
    text(im, t2, tx + (tw - text_w(t2)) // 2, y0 + 16, WHITE)


# ---------------------------------------------------------------- Las torres de luz

TOWERS = (4, 270)


def torres(im):
    d = ImageDraw.Draw(im)
    lamps = []
    for x in TOWERS:
        # El poste en celosía: dos tubos y las crucetas.
        d.line([(x - 2, 4), (x - 2, FOOT_Y + 2)], fill=METAL2)
        d.line([(x + 2, 4), (x + 2, FOOT_Y + 2)], fill=METAL2)
        for y in range(6, FOOT_Y, 6):
            d.line([(x - 2, y), (x + 2, y + 6)], fill=METAL3)
        # La parrilla de reflectores arriba: 2x3, apagados (de noche los prende el juego).
        d.rectangle([x - 5, 0, x + 5, 6], fill=METAL3)
        for i in range(3):
            for j in range(2):
                lx, ly = x - 4 + i * 3, 1 + j * 3
                d.rectangle([lx, ly, lx + 1, ly + 1], fill=(200, 204, 190))
                lamps.append([lx, ly])
    return lamps


# ---------------------------------------------------------------- La reja, los afiches y la entrada

GATE = (124, 156)      # el arco de la entrada, de x a x
FENCE_Y = (92, 104)

AFICHES = [  # el color de cada uno (camiseta, pantaloneta/pelo): para la silueta del afiche
    ((246, 210, 64), (34, 34, 40)),      # Monfiz
    ((206, 52, 56), (40, 52, 104)),      # Yokovich
    ((240, 112, 112), (232, 200, 120)),  # Sabalenkova
    ((244, 244, 240), (108, 78, 58)),    # Fedorer
    ((44, 44, 50), (210, 40, 50)),       # Kyrgistán
    ((170, 224, 84), (112, 72, 156)),    # Tiafuego
]


def reja(im):
    d = ImageDraw.Draw(im)
    y0, y1 = FENCE_Y
    sponsors = [("CAVERNA", (40, 40, 70), (120, 220, 255)), ("GERMAN", (220, 200, 150), RED2),
                ("BILLAR", (30, 80, 50), YEL), ("TINTO", (110, 60, 40), WHITE)]
    k = 0
    for xa, xb in ((10, GATE[0] - 26), (GATE[1] + 4, 270)):  # (entre la reja y el arco, la taquilla)
        x = xa
        while x < xb:
            w = min(34, xb - x)
            name, bg, fg = sponsors[k % len(sponsors)]
            k += 1
            d.rectangle([x, y0, x + w - 1, y1], fill=bg)
            d.line([(x, y0), (x + w - 1, y0)], fill=tuple(min(255, c + 30) for c in bg))
            if text_w(name) <= w - 4:
                text(im, name, x + (w - text_w(name)) // 2, y0 + 4, fg)
            x += w + 1
    # Los afiches de los tenistas, pegados a los tubos (entre la reja y el pasacalle).
    for i, (shirt, other) in enumerate(AFICHES):
        ax = 22 + i * 18 + (96 if i >= 3 else 0)
        ay = 62
        d.rectangle([ax, ay, ax + 11, ay + 16], fill=WHITE)
        d.rectangle([ax + 1, ay + 1, ax + 10, ay + 13], fill=(60, 120, 90))      # la cancha de fondo
        d.rectangle([ax + 4, ay + 3, ax + 7, ay + 5], fill=(214, 160, 128))      # la cabeza
        d.rectangle([ax + 4, ay + 2, ax + 7, ay + 2], fill=other)                # el pelo
        d.rectangle([ax + 3, ay + 6, ax + 8, ay + 10], fill=shirt)               # la camiseta
        d.rectangle([ax + 4, ay + 11, ax + 7, ay + 12], fill=other)              # la pantaloneta
        d.line([(ax + 8, ay + 7), (ax + 10, ay + 4)], fill=(230, 230, 236))      # la raqueta
        d.rectangle([ax + 2, ay + 14, ax + 9, ay + 15], fill=RED)               # el nombre (una raya)


def entrada(im):
    d = ImageDraw.Draw(im)
    gx0, gx1 = GATE
    # Los dos postes del arco, de rayas rojas y negras.
    for x in (gx0, gx1 - 3):
        for y in range(56, 106):
            c = RED if (y // 3) % 2 == 0 else BLACK
            d.line([(x, y), (x + 3, y)], fill=c)
    # El letrero de arriba: ENTRADA.
    d.rectangle([gx0 - 3, 50, gx1 + 2, 60], fill=BLACK)
    t = "ENTRADA"
    text(im, t, gx0 + (gx1 - gx0 - text_w(t)) // 2, 53, YEL)
    # Adentro del arco: el túnel oscuro hacia la cancha, con la luz verde de la cancha al fondo.
    d.rectangle([gx0 + 4, 61, gx1 - 5, 105], fill=(22, 20, 26))
    d.rectangle([gx0 + 9, 64, gx1 - 10, 74], fill=(54, 120, 84))
    d.line([(gx0 + 9, 69), (gx1 - 10, 69)], fill=(220, 226, 214))
    # La taquilla: una caseta con su ventanilla, a la izquierda del arco.
    tx = gx0 - 22
    d.rectangle([tx, 82, tx + 16, 106], fill=(196, 64, 52))
    d.rectangle([tx - 1, 79, tx + 17, 82], fill=BLACK)
    d.rectangle([tx + 3, 87, tx + 13, 95], fill=(40, 50, 70))
    d.line([(tx + 3, 96), (tx + 13, 96)], fill=WOOD)
    # El torniquete, en la boca del arco.
    d.line([(gx0 + 6, 100), (gx1 - 7, 100)], fill=METAL)
    d.rectangle([gx0 + 13, 96, gx0 + 18, 105], fill=METAL2)


def raqueta_icono():
    """La raqueta que le queda (16x16, como los íconos de draw_items.py): el marco, el encordado y el grip."""
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([5, 1, 14, 10], fill=(190, 40, 44))
    d.ellipse([6, 2, 13, 9], fill=(226, 222, 206))
    for k in range(7, 13, 2):  # el encordado
        d.line([(k, 3), (k, 8)], fill=(176, 170, 156))
        d.line([(7, k - 4), (12, k - 4)], fill=(176, 170, 156))
    d.line([(7, 9), (3, 13)], fill=(150, 34, 44), width=2)          # la garganta
    d.line([(3, 13), (1, 15)], fill=(70, 54, 46), width=2)          # el grip
    put(im, 12, 3, (255, 250, 240))
    outline(im, (38, 28, 44))
    im.save(os.path.join(OUT, "..", "items", "raqueta.png"))


def main():
    raqueta_icono()
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tribuna(im)
    pasacalle(im)
    reja(im)
    entrada(im)
    lamps = torres(im)
    outline(im)
    # La sombra en el piso (después del contorno, transparente a medias).
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rectangle([10, 106, 270, 111], fill=(0, 0, 0, 60))
    out = Image.alpha_composite(sh, im)
    out.save(os.path.join(OUT, "coliseo_afuera.png"))
    info = {
        "size": [W, H],
        "crowd": [STAND[0] + 2, TOP_Y - 1, STAND[1] - 2],     # la última fila: x desde, y (los pies), x hasta
        "lamps": lamps,
        "flags": [[STAND[0] - 2, TOP_Y], [STAND[1] + 2, TOP_Y]],
        "gate": [(GATE[0] + GATE[1]) // 2, 106],
        "queue": [GATE[0] - 30, 108],
        "block": [STAND[0] - 4, 0, STAND[1] + 4, FENCE_Y[1]],
    }
    with open(os.path.join(OUT, "coliseo_afuera.json"), "w", encoding="utf-8") as f:
        json.dump(info, f)
    if os.environ.get("PREVIEW"):
        bg = Image.new("RGBA", (W, H), (120, 96, 64, 255))
        bg.alpha_composite(out)
        bg.resize((W * 4, H * 4), Image.NEAREST).save(os.environ["PREVIEW"])
    print("ok")


if __name__ == "__main__":
    main()
