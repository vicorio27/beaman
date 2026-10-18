"""La feria vista desde la calle (el lote de atrás del billar, en City): lo que se alcanza a ver por
encima de la reja, para que den ganas de entrar.

    python tools/art/draw_feria_lote.py   -> assets/barrio/feria_lote.png, feria_frente.png, feria_lote.json

El lote mide 330x98 (en el mundo, desde FERIA_LOTE en Vecindario.gd). Dos capas: atrás (la montaña rusa,
los chocones, la plataforma del carrusel, la garra, los dardos, las obleas) y adelante (el techo del
carrusel y la reja), y entre las dos el juego mueve lo que se mueve: el carrito de la montaña rusa, los
carros chocones, los caballitos. La rueda de Chicago la dibuja el juego (gira). El .json lleva dónde van
los bombillos (prendidos de noche), el camino del carrito y la pista de los chocones.
"""
import json
import math
import os

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "barrio")
W, H = 330, 98
INK = (34, 26, 36)
WHITE = (236, 232, 222)
WHITE2 = (184, 178, 170)
RED = (206, 52, 58)
RED2 = (150, 34, 44)
YEL = (244, 204, 70)
YEL2 = (196, 150, 40)
BLUE = (64, 116, 196)
BLUE2 = (44, 80, 150)
METAL = (150, 152, 164)
METAL2 = (100, 102, 116)
WOOD = (132, 92, 58)
WOOD2 = (92, 62, 42)


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


GLYPHS = {
    "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "G": ["011", "100", "101", "101", "011"],
    "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"], "L": ["100", "100", "100", "100", "111"],
    "M": ["10001", "11011", "10101", "10001", "10001"], "N": ["1001", "1101", "1011", "1001", "1001"],
    "O": ["010", "101", "101", "101", "010"], "R": ["110", "101", "110", "101", "101"], "S": ["011", "100", "010", "001", "110"],
    "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "111"], "$": ["011", "110", "010", "011", "110"],
    "1": ["01", "11", "01", "01", "01"], "0": ["111", "101", "101", "101", "111"], "5": ["111", "100", "110", "001", "110"],
    " ": ["0", "0", "0", "0", "0"], ".": ["0", "0", "0", "0", "1"],
}


def text(im, s, x, y, col):
    for ch in s:
        g = GLYPHS[ch]
        for j, line in enumerate(g):
            for i, c in enumerate(line):
                if c == "1":
                    put(im, x + i, y + j, col)
        x += len(g[0]) + 1


def text_w(s):
    return sum(len(GLYPHS[c][0]) + 1 for c in s) - 1


# ---------------------------------------------------------------- La montaña rusa (al fondo)

## El perfil del riel: la estación, la subida de la cadena, la bajada grande, la loma, la curva y vuelta.
TRACK = [(6, 42), (24, 42), (34, 30), (52, 6), (60, 5), (66, 8), (82, 40), (90, 44), (100, 38), (112, 22),
         (122, 20), (130, 28), (142, 42), (150, 44), (158, 40)]


def coaster(back):
    d = ImageDraw.Draw(back)
    # Los soportes: tubos blancos del riel al piso, con sus crucetas.
    pts = []
    for (x0, y0), (x1, y1) in zip(TRACK, TRACK[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0)))
        for k in range(n):
            t = k / n
            pts.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t))
    pts.append(TRACK[-1])
    for x in range(10, 158, 8):
        top = min((p for p in pts if abs(p[0] - x) < 0.6), key=lambda p: p[1], default=None)
        if top is None:
            continue
        d.line([(x, top[1] + 2), (x, 52)], fill=WHITE2)
        if x % 16 == 2 and top[1] < 40:
            d.line([(x, top[1] + 4), (x + 8, 50)], fill=(160, 156, 150))
    d.line([(6, 52), (160, 52)], fill=WHITE2)
    # La estación: un techito azul con el letrero.
    d.rectangle([2, 34, 32, 52], fill=BLUE2)
    d.rectangle([0, 27, 34, 35], fill=BLUE)
    # El riel: rojo, de dos píxeles, con el borde claro arriba.
    for (x0, y0), (x1, y1) in zip(TRACK, TRACK[1:]):
        d.line([(x0, y0), (x1, y1)], fill=RED, width=2)
    back_o = outline(back)
    d = ImageDraw.Draw(back_o)
    for (x0, y0), (x1, y1) in zip(TRACK, TRACK[1:]):
        d.line([(x0, y0 - 1), (x1, y1 - 1)], fill=(240, 120, 110))
    for x, y in pts[::3]:  # los durmientes
        put(back_o, x, y + 1, RED2)
    for k in range(34, 52, 3):  # la cadena de la subida
        put(back_o, k - 1, 42 - (k - 24) * 1.2 + 1, (60, 56, 60))
    d.rectangle([3, 36, 31, 51], fill=(40, 52, 90))
    sx = 17 - text_w("MONTANA") // 2
    text(back_o, "MONTANA", sx, 31, WHITE)
    nx = sx + text_w("MONTA") + 1                 # la virgulilla de la Ñ
    for i, dy in enumerate((1, 0, 1, 0)):
        put(back_o, nx + i, 28 + dy, WHITE)
    d.line([(4, 51), (30, 51)], fill=METAL2)  # el andén
    return back_o


# ---------------------------------------------------------------- Los chocones (a la derecha)

RINK = (250, 60, 322, 82)  # la pista (dentro de esto se mueven los carritos)


def chocones(im):
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = 246, 32, 326, 86
    d.rectangle([x0, y0 + 22, x1, y1], fill=(90, 92, 104))                 # el piso de lata
    for x in (x0 + 1, x1 - 3):
        d.rectangle([x, y0 + 8, x + 2, y1], fill=METAL)                     # los postes
    d.rectangle([x0 - 2, y0, x1 + 2, y0 + 12], fill=RED)                    # el techo
    lay = outline(im)
    d = ImageDraw.Draw(lay)
    for x in range(x0 - 2, x1 + 3, 8):                                       # las franjas del techo
        d.rectangle([x, y0 + 1, x + 3, y0 + 11], fill=YEL)
    for x in range(x0 - 2, x1 + 2, 6):                                       # el borde de festón
        d.polygon([(x, y0 + 12), (x + 6, y0 + 12), (x + 3, y0 + 15)], fill=RED2)
    d.rectangle([x0 + 18, y0 - 6, x1 - 18, y0 + 1], fill=INK)                # el letrero
    text(lay, "CHOCONES", (x0 + x1) // 2 - text_w("CHOCONES") // 2, y0 - 5, YEL)
    d.rectangle([RINK[0] - 2, RINK[1] - 2, RINK[2] + 2, RINK[3] + 2], outline=(230, 220, 120))  # la baranda de caucho
    d.line([(RINK[0] - 2, RINK[3] + 3), (RINK[2] + 2, RINK[3] + 3)], fill=(40, 40, 46))
    for x in range(RINK[0], RINK[2], 9):                                     # la malla del techo (la corriente)
        d.line([(x, y0 + 15), (x + 4, y0 + 18)], fill=(70, 70, 80))
    for x in range(x0 + 4, x1 - 2, 12):
        put(lay, x, y0 + 26, (130, 132, 146))
    return lay


# ---------------------------------------------------------------- El carrusel (adelante, a la izquierda)

CARRUSEL = (52, 84, 30, 6)  # centro x, y de la plataforma; radio x, radio y


def carrusel_atras(im):
    cx, cy, rx, ry = CARRUSEL
    d = ImageDraw.Draw(im)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry + 3], fill=(140, 60, 120))  # la plataforma (el borde)
    d.ellipse([cx - rx, cy - ry - 2, cx + rx, cy + ry], fill=(196, 170, 120))
    d.rectangle([cx - 3, cy - 36, cx + 3, cy - 2], fill=(220, 170, 60))     # el eje dorado, con espejitos
    lay = outline(im)
    d = ImageDraw.Draw(lay)
    for k in range(4):
        put(lay, cx - 1, cy - 33 + k * 8, (250, 240, 200))
    for k in range(10):  # las tablas de la plataforma
        a = k * math.tau / 10
        put(lay, cx + math.cos(a) * (rx - 4), cy - 1 + math.sin(a) * (ry - 2), (170, 144, 96))
    return lay


def carrusel_frente(im):
    cx, cy, rx, ry = CARRUSEL
    d = ImageDraw.Draw(im)
    top = cy - 44
    # El techo: un cono de franjas rojas y blancas, con el festón y la banderita.
    d.polygon([(cx, top - 8), (cx + rx + 2, top + 10), (cx - rx - 2, top + 10)], fill=WHITE)
    d.ellipse([cx - rx - 3, top + 6, cx + rx + 3, top + 16], fill=RED)
    d.line([(cx, top - 8), (cx, top - 14)], fill=METAL2)
    d.polygon([(cx + 1, top - 14), (cx + 7, top - 12), (cx + 1, top - 10)], fill=YEL)
    lay = outline(im)
    d = ImageDraw.Draw(lay)
    for k in range(-4, 5):  # las franjas rojas del cono
        if k % 2 == 0:
            d.polygon([(cx, top - 7), (cx + k * 4 + 2, top + 9), (cx + k * 4 - 2, top + 9)], fill=RED)
    for k in range(-rx, rx + 1, 5):  # el festón con sus bombillitos pintados
        d.polygon([(cx + k - 2, top + 15), (cx + k + 3, top + 15), (cx + k, top + 18)], fill=YEL)
    d.line([(cx - rx - 2, top + 11), (cx + rx + 2, top + 11)], fill=(250, 200, 200))
    return lay


# ---------------------------------------------------------------- Los puestos

def garra(im):
    """La máquina de la garra: la caja de vidrio con los muñecos amontonados, la garra arriba."""
    d = ImageDraw.Draw(im)
    x0, y0 = 108, 58
    d.rectangle([x0, y0, x0 + 16, y0 + 32], fill=(220, 60, 140))             # la máquina
    lay = outline(im)
    d = ImageDraw.Draw(lay)
    d.rectangle([x0 + 2, y0 + 5, x0 + 14, y0 + 19], fill=(150, 200, 220))   # el vidrio
    for i, (x, y, c) in enumerate([(3, 16, (250, 200, 60)), (6, 15, (120, 200, 120)), (9, 16, (140, 90, 200)),
                                    (12, 15, (250, 140, 180)), (5, 17, (240, 240, 240)), (10, 17, (200, 80, 80))]):
        d.rectangle([x0 + x, y0 + y, x0 + x + 1, y0 + y + 1], fill=c)        # los muñecos
    d.line([(x0 + 8, y0 + 5), (x0 + 8, y0 + 9)], fill=METAL)                 # la garra
    d.line([(x0 + 6, y0 + 11), (x0 + 8, y0 + 9), (x0 + 10, y0 + 11)], fill=METAL)
    put(lay, x0 + 4, y0 + 7, (230, 250, 255))
    d.rectangle([x0 + 1, y0 + 1, x0 + 15, y0 + 3], fill=(250, 220, 90))
    d.rectangle([x0 + 3, y0 + 22, x0 + 13, y0 + 25], fill=(120, 30, 70))     # el tablero
    put(lay, x0 + 6, y0 + 23, (240, 60, 60))
    put(lay, x0 + 10, y0 + 23, (250, 220, 90))
    d.rectangle([x0 + 9, y0 + 28, x0 + 12, y0 + 30], fill=(40, 20, 30))      # el hueco del premio
    return lay


def dardos(im):
    """El puesto de dardos: el toldo de rayas, el tablero de corcho con las bombas, los peluches colgados."""
    d = ImageDraw.Draw(im)
    x0, y0 = 128, 56
    d.rectangle([x0 + 1, y0 + 8, x0 + 33, y0 + 34], fill=WOOD)               # el puesto
    d.polygon([(x0 - 2, y0 + 8), (x0 + 36, y0 + 8), (x0 + 33, y0), (x0 + 1, y0)], fill=BLUE)  # el toldo
    lay = outline(im)
    d = ImageDraw.Draw(lay)
    for x in range(x0 + 1, x0 + 34, 6):
        d.polygon([(x, y0 + 1), (x + 3, y0 + 1), (x + 3, y0 + 8), (x, y0 + 8)], fill=WHITE)
    for x in range(x0 - 1, x0 + 35, 4):
        put(lay, x + 1, y0 + 9, BLUE2)
    d.rectangle([x0 + 4, y0 + 11, x0 + 30, y0 + 24], fill=(196, 150, 96))    # el corcho
    cols = [(230, 60, 60), (250, 210, 60), (70, 160, 230), (120, 200, 100), (240, 130, 200)]
    for j in range(3):
        for i in range(6):
            c = cols[(i + j * 2) % 5]
            bx, by = x0 + 6 + i * 4, y0 + 13 + j * 4
            d.rectangle([bx, by, bx + 2, by + 2], fill=c)
            put(lay, bx, by, (255, 255, 255))
    put(lay, x0 + 15, y0 + 18, (196, 150, 96))  # una ya reventada
    d.rectangle([x0 + 1, y0 + 25, x0 + 33, y0 + 27], fill=(170, 120, 74))    # el mostrador
    for i, c in enumerate([(140, 90, 200), (250, 200, 60), (120, 80, 50)]):  # los peluches colgados
        px_ = x0 + 3 + i * 13
        d.line([(px_ + 2, y0 + 9), (px_ + 2, y0 + 10)], fill=INK)
        d.ellipse([px_, y0 + 10, px_ + 4, y0 + 14], fill=c)
    return lay


def obleas(im):
    """El carrito de las obleas, con su sombrilla."""
    d = ImageDraw.Draw(im)
    x0, y0 = 170, 66
    d.rectangle([x0, y0 + 10, x0 + 18, y0 + 22], fill=WHITE)
    d.ellipse([x0 + 1, y0 + 21, x0 + 5, y0 + 25], fill=(40, 40, 46))
    d.ellipse([x0 + 13, y0 + 21, x0 + 17, y0 + 25], fill=(40, 40, 46))
    d.line([(x0 + 9, y0 + 10), (x0 + 9, y0 + 2)], fill=METAL2)
    d.chord([x0 - 3, y0 - 6, x0 + 21, y0 + 8], 180, 360, fill=YEL)
    lay = outline(im)
    d = ImageDraw.Draw(lay)
    for k in (0, 2):
        d.chord([x0 - 3, y0 - 6, x0 + 21, y0 + 8], 180 + k * 45, 225 + k * 45, fill=RED)
    d.rectangle([x0 + 2, y0 + 12, x0 + 16, y0 + 14], fill=(236, 200, 140))   # la oblea de muestra
    put(lay, x0 + 6, y0 + 13, (180, 90, 40))
    put(lay, x0 + 11, y0 + 13, (240, 60, 70))
    return lay


def reja(im):
    """Las vallas de la entrada: tubos grises con su pata, de punta a punta, menos donde está el arco."""
    d = ImageDraw.Draw(im)
    for x0 in list(range(0, 88, 22)) + list(range(112, W - 10, 22)):
        x1 = min(x0 + 20, W - 1)
        if x0 < 100 < x1:
            continue
        d.rectangle([x0, 88, x1, 89], fill=METAL)
        d.rectangle([x0, 95, x1, 96], fill=METAL)
        for x in range(x0 + 2, x1, 3):
            d.line([(x, 89), (x, 95)], fill=METAL2)
        d.line([(x0, 88), (x0, 97)], fill=METAL)
        d.line([(x1, 88), (x1, 97)], fill=METAL)
    lay = outline(im)
    d = ImageDraw.Draw(lay)
    for x0 in list(range(0, 88, 22)) + list(range(112, W - 10, 22)):
        d.line([(x0 + 1, 88), (min(x0 + 19, W - 2), 88)], fill=(200, 202, 212))
    return lay


def luces():
    """Los bombillos: guirnaldas combadas entre los postes, más los del techo del carrusel y los chocones."""
    bulbs = []
    def sag(a, b, depth, step=5):
        n = int(math.hypot(b[0] - a[0], b[1] - a[1]) // step)
        for k in range(n + 1):
            t = k / max(1, n)
            bulbs.append([round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t + depth * 4 * t * (1 - t))])
    sag((0, 54), (60, 6), 8)        # de la estación a la punta de la montaña
    sag((90, 60), (246, 30), 12)    # del arco a los chocones (por encima de los puestos)
    sag((100, 60), (52, 30), 6)     # del arco al carrusel
    sag((246, 30), (326, 30), 3, 6)
    cx, cy, rx, ry = CARRUSEL
    for k in range(-rx, rx + 1, 5):
        bulbs.append([cx + k, cy - 44 + 17])
    return bulbs


def main():
    back = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for fn in (coaster, chocones, carrusel_atras, garra, dardos, obleas):
        lay = fn(Image.new("RGBA", (W, H), (0, 0, 0, 0)))
        back.alpha_composite(lay)
    front = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for fn in (carrusel_frente, reja):
        front.alpha_composite(fn(Image.new("RGBA", (W, H), (0, 0, 0, 0))))
    back.save(os.path.join(OUT, "feria_lote.png"))
    front.save(os.path.join(OUT, "feria_frente.png"))
    cx, cy, rx, ry = CARRUSEL
    info = {"track": [[x, y - 2] for x, y in TRACK], "rink": list(RINK), "carrusel": [cx, cy, rx, ry],
            "bulbs": luces()}
    with open(os.path.join(OUT, "feria_lote.json"), "w") as f:
        json.dump(info, f)
    print("feria_lote: %dx%d, %d bombillos" % (W, H, len(info["bulbs"])))


if __name__ == "__main__":
    main()
