"""El prólogo (la huida, scripts/prologue/Huida.gd): él deslizándose y apretado, lo que hay que pasar por
debajo, lo que se salta, el helicóptero, los vecinos de las terrazas y lo que tiran.

    python tools/art/draw_huida.py              -> assets/prologue/huida/*.png
    python tools/art/draw_huida.py --hoja x.png -> una hoja para mirar (6x)

Todo a mano, píxel por píxel, con la paleta de player.png (el mismo muñeco: saco oscuro, camisa
blanca, corbata roja, jean). Cada figura se arma con capas de color y después se le pasa el borde
oscuro de una pieza, como al resto de la hoja; los detalles finos (letras, brillos) van después del
borde, para que no se engorden.

Lo que se pasa por debajo viene en dos capas: <nombre>_atras.png (lo que queda detrás de él: las patas
del fondo, el cuerpo) y <nombre>_frente.png (lo que le queda por delante: las patas de este lado, las
llantas). Él pasa por en medio, apretado: el hueco es de 13 píxeles (él, acostado, mide 11).

  player_slide.png  4 cuadros de 48x48: se tira (0), se desliza (1, 2), apretado boca arriba (3)
  tanque_*          el tanque negro de agua en su burra de ángulo (gotea)
  palomar_*         el palomar de tablas en cuatro patas de guadua (las palomas, adentro)
  placa_*           la placa recién fundida, apuntalada con tacos de guadua, las varillas por encima
  cumple_*          la mesa del cumpleaños en la terraza: el mantel de cuadros, la torta, la familia
  mula_*            el tráiler de una tractomula parqueado en el puente (sin cabezote desde 2019)
  poste_*           el poste de la luz caído de través: la base allá, la lámpara acá
  salta_*.png       lo que se salta: pipeta de gas, ladrillos, el muro con vidrios; en el puente, el taxi
  heli.png          el helicóptero de la policía, 2 cuadros (el rotor)
  vecinos.png       4 vecinos x 2 cuadros (gritando / tirando), de la cintura para arriba
  terraza_*.png     el borde de su terraza (la baranda), por delante de ellos
  tiran.png         lo que tiran: chancla, huevo, matera, biblia (8x8 cada uno)
  paloma.png        una paloma volando, 2 cuadros de 8x6
"""
import os
import sys

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "prologue", "huida")

# La paleta de player.png.
K = (46, 34, 47)        # borde y saco
K2 = (98, 85, 101)      # brillo del saco
HAIR = (40, 38, 46)
HAIR2 = (70, 62, 60)
SKIN = (214, 150, 120)
SKIN2 = (172, 110, 90)
BEARD = (98, 85, 101)
BEARD2 = (70, 62, 60)
SHIRT = (255, 255, 255)
SHIRT2 = (214, 208, 192)
TIE = (206, 48, 52)
TIE2 = (140, 30, 38)
JEAN = (66, 92, 146)
JEAN2 = (52, 70, 116)
JEAN3 = (96, 124, 178)
SHOE = (28, 26, 34)
SOLE = (88, 92, 112)

INK = (20, 16, 26)      # el borde de las cosas, de noche
RUST = (150, 82, 50)
RUST2 = (104, 56, 40)
METAL = (150, 152, 164)
METAL2 = (96, 98, 112)
METAL3 = (196, 198, 208)
CONC = (132, 124, 120)
CONC2 = (98, 92, 92)
CONC3 = (164, 158, 152)
WOOD = (120, 84, 54)
WOOD2 = (84, 58, 40)
WOOD3 = (156, 116, 76)
GUADUA = (170, 150, 86)
GUADUA2 = (122, 104, 56)
BRICK = (156, 78, 56)
BRICK2 = (112, 54, 42)
BRICK3 = (184, 104, 76)


def outline(im, col=INK):
    """El borde de una pieza: todo píxel vacío que toca uno lleno (en cruz) se pinta de col."""
    px = im.load()
    w, h = im.size
    add = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny][:3] != col:
                        add.append((x, y))
                        break
    for x, y in add:
        px[x, y] = col + (255,)
    return im


def put(im, x, y, col):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), col + (255,))


def new(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def grid(rows, pal, w=None, h=None, x0=0, bottom=True):
    """Un dibujo de letras (una letra, un color) en una imagen; abajo pegado al piso."""
    rows = rows.strip("\n").split("\n")
    w = w or max(len(r) for r in rows)
    h = h or len(rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    top = h - len(rows) if bottom else 0
    for y, line in enumerate(rows):
        for x, c in enumerate(line):
            if pal.get(c):
                im.putpixel((x + x0, top + y), pal[c] + (255,))
    return im


## Letras a mano, de 3x5 (las que hacen falta).
GLYPHS = {
    "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"], "L": ["100", "100", "100", "100", "111"], "M": ["10001", "11011", "10101", "10001", "10001"],
    "N": ["1001", "1101", "1011", "1001", "1001"], "O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"],
    "R": ["110", "101", "110", "101", "101"], "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"],
    "U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"], "Y": ["101", "101", "010", "010", "010"],
    "X": ["101", "101", "010", "101", "101"], "G": ["011", "100", "101", "101", "011"], "F": ["111", "100", "110", "100", "100"],
    "0": ["111", "101", "101", "101", "111"], "1": ["01", "11", "01", "01", "01"], "2": ["110", "001", "010", "100", "111"],
    "3": ["110", "001", "010", "001", "110"], "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "110", "001", "110"],
    "7": ["111", "001", "010", "010", "010"], "9": ["111", "101", "111", "001", "110"], "8": ["111", "101", "111", "101", "111"],
    "!": ["1", "1", "1", "0", "1"], ".": ["0", "0", "0", "0", "1"], " ": ["00", "00", "00", "00", "00"], "-": ["000", "000", "111", "000", "000"],
}


def text(im, s, x, y, col):
    for ch in s:
        g = GLYPHS[ch]
        for j, line in enumerate(g):
            for i, c in enumerate(line):
                if c == "1":
                    put(im, x + i, y + j, col)
        x += len(g[0]) + 1
    return x


def text_w(s):
    return sum(len(GLYPHS[c][0]) + 1 for c in s) - 1


def guadua(im, d, x, y0, y1, col=GUADUA, dark=GUADUA2):
    """Un taco de guadua: dos píxeles de ancho, la sombra a un lado y los nudos cada tanto."""
    d.rectangle([x, y0, x + 1, y1], fill=col)
    d.line([(x + 1, y0), (x + 1, y1)], fill=dark)
    for y in range(y0 + 3, y1, 7):
        d.line([(x - 1, y), (x + 2, y)], fill=dark)


# ---------------------------------------------------------------- Él

PIX = {".": None, "k": K, "j": K2, "h": HAIR, "H": HAIR2, "s": SKIN, "S": SKIN2, "b": BEARD, "B": BEARD2, "w": SHIRT,
       "W": SHIRT2, "r": TIE, "R": TIE2, "n": JEAN, "N": JEAN2, "m": JEAN3, "d": SHOE, "l": SOLE, "e": SHOE,
       "q": (150, 200, 240)}

## Deslizándose, mirando a la derecha (46 x 18): apoyado en el codo de atrás, la pierna de adelante
## estirada con la punta del zapato arriba, la otra con la rodilla arriba, el brazo de adelante en alto.
SLIDE = """
..kkkk..........kkk...........................
.khhhhkk.......kssk...........................
khhhhhhhk.....kssSk...........................
khhHhhhhhk...kjjkk............................
.khhhhhssk..kjjk..............................
.khhhhssesk.kjjk..............................
rrkhhhSsssskjk................................
.rrkkSsbbbbkkk.......kkk......................
..rrRkbbBbkwwk......knnnk.....................
...kkrrkkkwwwrkk...knnmnnk....................
..kjjkkrrwwwwrrkkkknnnnmnnk...................
.kjjkkkkkwwwwwwrrnnnnkNnnnk..........kkkk.....
.kjkkkkkkkkWWwwnnnnnnkkNNnnkkkkkkkkkkddddk....
kjkk.kkkkkkkkkkmmmmnnnnkNNNnnnnmmmmmndddddk...
ksk...kkkkkkkknnnnnnnnnkkNNNnnnnnnnnnkddddddk.
ksSk...........kkknnnkkkkddddkknnnnnnkdddddddk
kSSk..............kkkk..kdddddkkkkkkkkllllllk.
.kk......................kkkkkk.......kkkkkk..
"""

## Apretado (46 x 11): acostado del todo, boca arriba, los brazos pegados al cuerpo, los dientes
## apretados; la corbata se le va para la cara.
FLAT = """
....kkk.......................................
..kksssk.krk..................................
.khseSssk.krrk............................kk..
khhssswwkkkrrkkkkkkkkkk......kkkkk.......kddk.
khhhSsbbbkwwwrrwwwwwwkkkkkkkkmmmnkkkkkkkkkdddk
khhhhSbbBkkwwwwWWwWWkjjkmmmnnnnnnnnmmnnnnkdddk
khhhhhkbbkjkkkkkkkkkkjkknnnnnnnnnnnnnmmmnkddlk
khhhhhhkkjjjjjjjjjjjssknnnnnnnnNnnnnnnnnnkddlk
.khhhhhhkkkkkkkkkkkkSskNNnnnnnNNNnnnnnnnNkddlk
..khhhhhkjjjjjjjjjjjkkkNNNNNNNNkNNNNNNNNNkddlk
...kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk.
"""


def player_slide():
    def draw(rows):
        im = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        top = 46 - len(rows)
        for y, line in enumerate(rows):
            for x, c in enumerate(line):
                if PIX[c]:
                    im.putpixel((x + 1, top + y), PIX[c] + (255,))
        return im
    a = SLIDE.strip("\n").split("\n")
    b = list(a)  # la corbata, más arriba; un pico de pelo más atrás
    b[5] = "r" + b[5][1:]
    b[6] = ".rkhhhSsssskjk" + b[6][14:]
    b[7] = "..rkkSsbbbbkkk" + b[7][14:]
    b[1] = "hkhhhhkk" + b[1][8:]
    flat = FLAT.strip("\n").split("\n")
    flat2 = list(flat)  # el sudor, y la corbata, que no se queda quieta
    flat2[0] = ".q.." + flat2[0][4:]
    flat2[1] = "..kksssk.kk." + flat2[1][12:]
    flat2[2] = ".khseSssk.krrr" + flat2[2][14:]
    sheet = Image.new("RGBA", (48 * 5, 48), (0, 0, 0, 0))
    for k, rows in enumerate([a, a, b, flat, flat2]):
        f = draw(rows)
        sheet.paste(f, (k * 48, 0), f)
    return sheet


# ---------------------------------------------------------------- Lo que se pasa por debajo (13 de hueco)

GAP = 13


def tanque():
    """El tanque negro de mil litros en su burra de ángulo oxidado: la tapa de rosca, las costillas del
    plástico, el flotador que asoma, el rebose que gotea. 40x52. Atrás: el tanque y las patas del fondo.
    Adelante: las dos patas de este lado y la diagonal."""
    w, h = 40, 52
    top = h - GAP - 3                     # la parrilla de la burra
    back, d = new(w, h)
    for x in (6, 31):                     # las patas del fondo (más oscuras: están detrás)
        d.rectangle([x, top, x + 1, h - 1], fill=RUST2)
    d.rectangle([3, top - 1, 36, top + 2], fill=RUST)                    # la parrilla
    d.line([(3, top + 2), (36, top + 2)], fill=RUST2)
    # El tanque: un barril ancho, más angosto arriba, con su tapa.
    d.polygon([(5, top - 2), (34, top - 2), (36, top - 10), (35, top - 26), (31, top - 31), (8, top - 31),
               (4, top - 26), (3, top - 10)], fill=(38, 40, 46))
    d.rectangle([14, top - 35, 25, top - 31], fill=(30, 32, 38))         # la tapa
    back = outline(back)
    d = ImageDraw.Draw(back)
    for y in (top - 8, top - 16, top - 24):                              # las costillas
        d.line([(5, y), (34, y)], fill=(56, 58, 66))
        d.line([(5, y + 1), (34, y + 1)], fill=(28, 30, 34))
    d.line([(9, top - 29), (9, top - 4)], fill=(86, 90, 100))            # el brillo de la luna
    d.line([(10, top - 30), (10, top - 26)], fill=(120, 124, 134))
    d.line([(15, top - 34), (24, top - 34)], fill=(60, 62, 70))
    for x in (16, 19, 22):
        put(back, x, top - 33, (54, 56, 64))
    text(back, "1000", 20, top - 22, (70, 72, 80))                       # en relieve, casi no se ve
    d.line([(35, top - 20), (39, top - 20), (39, top - 12)], fill=METAL2)  # el rebose
    put(back, 39, top - 11, (120, 180, 230))
    front, d = new(w, h)
    for x in (2, 35):
        d.rectangle([x, top, x + 2, h - 1], fill=RUST)
        d.line([(x + 2, top), (x + 2, h - 1)], fill=RUST2)
    d.line([(4, top + 3), (35, h - 3)], fill=RUST)                       # la diagonal de este lado
    front = outline(front)
    d = ImageDraw.Draw(front)
    for x in (2, 35):
        for y in range(top + 2, h - 2, 4):
            put(front, x, y, (178, 108, 70))                             # el óxido que brilla
        d.rectangle([x - 1, h - 2, x + 3, h - 1], fill=CONC2)            # el dado de cemento
    return back, front


def palomar():
    """El palomar: un cajón de tablas con la malla de gallinero al frente, cuatro palomas adentro (una
    blanca), la tablita de aterrizaje y el techito de zinc. En cuatro patas de guadua. 50x50."""
    w, h = 50, 50
    floor = h - GAP - 3
    back, d = new(w, h)
    guadua(back, d, 7, floor, h - 1, GUADUA2, (90, 76, 40))
    guadua(back, d, 40, floor, h - 1, GUADUA2, (90, 76, 40))
    d.rectangle([3, floor - 22, 46, floor + 2], fill=WOOD)              # el cajón
    d.polygon([(0, floor - 23), (49, floor - 29), (49, floor - 26), (0, floor - 20)], fill=METAL2)  # el zinc
    d.rectangle([46, floor - 6, 49, floor - 4], fill=WOOD3)              # la tablita de aterrizaje
    back = outline(back)
    d = ImageDraw.Draw(back)
    for y in range(floor - 21, floor + 2, 4):                            # las tablas
        d.line([(4, y), (45, y)], fill=WOOD2)
    for x in (4, 45):
        d.line([(x, floor - 21), (x, floor + 1)], fill=WOOD3)
    d.rectangle([8, floor - 18, 40, floor - 2], fill=(26, 20, 22))       # adentro, oscuro
    # Las palomas: gris, el cuello tornasol, el ojo naranja; una blanca.
    for k, (px, py, white) in enumerate([(10, floor - 7, False), (18, floor - 8, True), (27, floor - 7, False),
                                          (34, floor - 15, False)]):
        body = (238, 236, 230) if white else (128, 128, 140)
        d.ellipse([px, py, px + 6, py + 4], fill=body)
        d.rectangle([px + 5, py - 2, px + 7, py + 1], fill=body)
        if not white:
            put(back, px + 5, py + 1, (90, 150, 120))
            put(back, px + 6, py + 1, (150, 90, 160))
        put(back, px + 7, py - 1, (240, 140, 40))
        put(back, px + 8, py, (210, 170, 150))                           # el pico
        d.line([(px, py + 3), (px + 3, py + 3)], fill=(90, 90, 100) if not white else (190, 188, 180))
    d.rectangle([33, floor - 11, 41, floor - 10], fill=WOOD3)            # la repisa de adentro
    for x in range(8, 41, 3):                                            # la malla de gallinero
        for y in range(floor - 18, floor - 1, 3):
            put(back, x, y, (150, 150, 156))
            put(back, x + 1, y + 1, (110, 110, 118))
    for x in range(1, 49, 4):                                            # las ondas del zinc
        d.line([(x, floor - 23 - x * 6 // 49), (x, floor - 21 - x * 6 // 49)], fill=METAL)
    text(back, "7", 5, floor - 19, (236, 230, 220))                      # el número del palomar
    put(back, 22, floor - 27, (238, 236, 230))                           # caca de paloma, en el zinc
    put(back, 30, floor - 28, (238, 236, 230))
    front, d = new(w, h)
    guadua(front, d, 3, floor, h - 1)
    guadua(front, d, 44, floor, h - 1)
    d.line([(5, floor + 6), (44, floor + 6)], fill=GUADUA2)              # el travesaño, amarrado
    front = outline(front)
    for x in (4, 45):
        put(front, x, floor + 5, (200, 196, 180))                        # el alambre
        put(front, x, floor + 7, (200, 196, 180))
    return back, front


def placa():
    """La placa del segundo piso, recién fundida: el concreto todavía gris oscuro, las tablas de la
    formaleta por debajo, las varillas que salen para el piso que nunca se va a hacer, un balde. Cinco
    tacos de guadua la sostienen. 96x46."""
    w, h = 96, 46
    under = h - GAP - 1
    back, d = new(w, h)
    for x in (12, 46, 80):
        guadua(back, d, x, under, h - 1, GUADUA2, (90, 76, 40))
    d.rectangle([0, under - 3, w - 1, under], fill=WOOD)                # la formaleta
    d.rectangle([0, under - 9, w - 1, under - 4], fill=CONC)             # el concreto
    d.rectangle([60, under - 17, 67, under - 10], fill=(220, 120, 40))   # el balde de pintura (naranja)
    back = outline(back)
    d = ImageDraw.Draw(back)
    for x in range(0, w, 9):                                             # las tablas
        d.line([(x, under - 3), (x, under)], fill=WOOD2)
    d.line([(1, under - 3), (w - 2, under - 3)], fill=WOOD3)
    d.line([(1, under - 9), (w - 2, under - 9)], fill=CONC3)
    for x in range(3, w - 2, 7):                                         # el concreto: grumos y charcos
        put(back, x, under - 6 + (x % 3), CONC2)
    d.line([(20, under - 5), (26, under - 5)], fill=(90, 110, 130))      # un charquito
    for x in range(4, w - 3, 8):                                         # las varillas, para arriba
        top = under - 22 - (x * 7) % 9
        d.line([(x, under - 10), (x, top)], fill=RUST)
        put(back, x, top - 1, RUST2)
        if x % 16 == 4:
            d.line([(x, top), (x + 2, top + 2)], fill=RUST)              # dobladas
    d.line([(61, under - 15), (66, under - 15)], fill=(250, 170, 90))
    d.line([(60, under - 18), (64, under - 21), (67, under - 18)], fill=METAL2)  # el asa
    front, d = new(w, h)
    for x in (2, 30, 64, 92):
        guadua(front, d, x, under + 1, h - 1)
    front = outline(front)
    return back, front


def cumple():
    """La mesa del cumpleaños en la terraza: la mesa Rimax con el mantel de cuadros rojos, la torta con
    las velas prendidas, el aguardiente, los vasos, una bomba amarrada. Del otro lado de la mesa, la
    tía del gorrito y el tío del sombrero, sentados (lo ven pasar por debajo). 64x48."""
    w, h = 64, 48
    top = h - GAP - 3                     # el tablero (el mantel cuelga dos más)
    back, d = new(w, h)
    for x in (8, 54):                                                    # las patas del otro lado
        d.rectangle([x, top, x + 2, h - 1], fill=(200, 200, 196))
    # La tía (gorrito de fiesta, blusa fucsia) y el tío (sombrero, camisa de cuadros), sentados.
    d.rounded_rectangle([12, top - 15, 24, top], 3, fill=(220, 70, 150))
    d.ellipse([14, top - 24, 22, top - 15], fill=(200, 140, 110))
    d.ellipse([13, top - 26, 23, top - 19], fill=(60, 40, 36))
    d.polygon([(15, top - 25), (21, top - 25), (19, top - 33)], fill=(60, 170, 220))
    d.rounded_rectangle([38, top - 16, 51, top], 3, fill=(90, 120, 170))
    d.ellipse([40, top - 25, 48, top - 16], fill=(184, 124, 92))
    d.rectangle([37, top - 25, 51, top - 24], fill=(236, 226, 196))      # el ala del sombrero
    d.rectangle([40, top - 29, 48, top - 25], fill=(236, 226, 196))
    d.line([(60, top - 2), (58, top - 20)], fill=(200, 200, 200))       # la cuerda de la bomba
    d.ellipse([54, top - 30, 62, top - 20], fill=(70, 120, 230))        # la bomba
    d.rectangle([0, top - 1, w - 1, top + 1], fill=(240, 236, 228))     # el mantel
    d.rectangle([22, top - 8, 34, top - 2], fill=(250, 226, 236))       # la torta
    d.rectangle([4, top - 9, 6, top - 2], fill=(236, 240, 220))         # el aguardiente
    back = outline(back)
    d = ImageDraw.Draw(back)
    for x in range(0, w, 4):                                             # los cuadros rojos
        d.rectangle([x, top - 1, x + 1, top], fill=(206, 50, 54))
    d.line([(0, top + 1), (w - 1, top + 1)], fill=(206, 50, 54))
    d.line([(22, top - 5), (34, top - 5)], fill=(240, 120, 160))        # el relleno de la torta
    for x in (25, 28, 31):                                               # las velas
        d.line([(x, top - 10), (x, top - 9)], fill=(120, 200, 240))
        put(back, x, top - 11, (255, 200, 60))
    put(back, 28, top - 12, (255, 240, 160))
    d.line([(5, top - 11), (5, top - 10)], fill=(220, 40, 40))          # la tapa roja
    d.line([(4, top - 6), (6, top - 6)], fill=(60, 120, 200))           # la etiqueta
    for x in (9, 38, 46):                                                # los vasos de plástico
        d.rectangle([x, top - 4, x + 2, top - 2], fill=(240, 240, 244))
    put(back, 18, top - 21, INK)                                         # los ojos: lo están viendo
    put(back, 42, top - 21, INK)
    d.ellipse([16, top - 19, 18, top - 17], fill=(110, 40, 40))          # la boca abierta de la tía
    for k in range(3):                                                   # los cuadros de la camisa
        d.line([(39, top - 13 + k * 4), (50, top - 13 + k * 4)], fill=(60, 84, 130))
    d.line([(15, top - 31), (17, top - 27)], fill=(250, 220, 60))        # las rayitas del gorro
    put(back, 56, top - 28, (150, 190, 255))                             # el brillo de la bomba
    front, d = new(w, h)
    for x in (2, 60):                                                    # las patas de este lado
        d.rectangle([x, top + 2, x + 2, h - 1], fill=(236, 236, 232))
    d.rectangle([0, top + 1, w - 1, top + 2], fill=(240, 236, 228))     # el borde del mantel, colgando
    front = outline(front)
    d = ImageDraw.Draw(front)
    for x in range(0, w, 4):
        d.rectangle([x, top + 1, x + 1, top + 2], fill=(206, 50, 54))
    for x in (3, 61):
        put(front, x, top + 6, (255, 255, 255))
    return back, front


def mula():
    """El tráiler de una tractomula, parqueado en el puente: el furgón oxidado con el letrero medio
    borrado (TRANSPORTES EL CONDOR), el chasís, las dos llantas de atrás, la pata de apoyo de adelante.
    Sin cabezote: se lo robaron en 2019 y el tráiler se quedó esperando. 150x56. Él pasa entre las
    llantas de este lado (adelante) y las del otro (atrás)."""
    w, h = 150, 56
    chassis = h - GAP - 4
    back, d = new(w, h)
    for x in (10, 30):                                                   # las llantas del otro lado
        d.ellipse([x, h - 14, x + 13, h - 1], fill=(26, 24, 28))
    d.rectangle([134, chassis, 137, h - 1], fill=METAL2)                 # la pata de apoyo del otro lado
    d.rectangle([2, chassis - 34, w - 3, chassis - 4], fill=(150, 60, 48))  # el furgón
    d.rectangle([2, chassis - 3, w - 3, chassis], fill=(40, 40, 46))     # el chasís
    back = outline(back)
    d = ImageDraw.Draw(back)
    for x in range(8, w - 6, 8):                                         # las costillas del furgón
        d.line([(x, chassis - 33), (x, chassis - 5)], fill=(124, 48, 40))
    d.line([(3, chassis - 33), (w - 4, chassis - 33)], fill=(184, 92, 70))
    for x in range(5, w - 6, 13):                                        # el óxido que chorrea
        d.line([(x + 3, chassis - 30 + x % 5), (x + 3, chassis - 22 + x % 7)], fill=RUST2)
    d.rectangle([24, chassis - 28, 118, chassis - 14], fill=(176, 84, 64))
    text(back, "TRANSPORTES", 71 - text_w("TRANSPORTES") // 2, chassis - 26, (236, 222, 200))
    x = text(back, "EL C", 71 - text_w("EL CONDOR") // 2, chassis - 19, (236, 222, 200))
    x = text(back, "O", x, chassis - 19, (196, 120, 100))               # la O, medio caída
    text(back, "NDOR", x, chassis - 19, (236, 222, 200))
    d.rectangle([w - 14, chassis - 30, w - 6, chassis - 22], fill=(236, 222, 200))  # el aviso del peso
    text(back, "40", w - 13, chassis - 29, INK)
    for x in range(4, w - 4, 6):                                         # los bordes del chasís
        put(back, x, chassis - 2, (70, 70, 80))
    d.rectangle([3, chassis - 7, 10, chassis - 5], fill=(220, 40, 40))   # las luces de atrás
    d.rectangle([3, chassis - 4, 10, chassis - 4], fill=(240, 180, 60))
    front, d = new(w, h)
    for x in (6, 26):                                                    # las llantas de este lado
        d.ellipse([x, h - 15, x + 15, h - 1], fill=(30, 28, 32))
        d.rectangle([x - 2, chassis - 5, x + 17, chassis - 2], fill=(46, 46, 54))  # el guardabarros
    d.rectangle([128, chassis + 1, 131, h - 2], fill=METAL)              # la pata de apoyo
    d.rectangle([125, h - 2, 134, h - 1], fill=METAL2)
    front = outline(front)
    d = ImageDraw.Draw(front)
    for x in (6, 26):
        d.ellipse([x + 4, h - 11, x + 11, h - 4], fill=(110, 110, 120))  # el rin
        put(front, x + 7, h - 8, (40, 40, 46))
        put(front, x + 6, h - 10, (170, 170, 180))
        for k in range(3):                                               # la banda, gastada
            put(front, x + 2 + k * 5, h - 14 + (k % 2), (54, 52, 58))
        d.line([(x, chassis - 2), (x + 15, chassis - 2)], fill=(30, 30, 36))
        d.rectangle([x + 3, chassis - 1, x + 12, chassis + 4], fill=(30, 30, 36))  # la loneta (el guardafango)
        put(front, x + 5, chassis + 1, (220, 200, 60))
    d.line([(129, chassis + 3), (130, chassis + 3)], fill=METAL3)
    d.line([(132, chassis + 5), (132, chassis + 8)], fill=METAL3)        # la manivela
    return back, front


def poste():
    """El poste de la luz, caído de través: la base partida quedó en el andén de allá (con el pedazo de
    concreto y las varillas) y la lámpara llegó hasta acá. El tubo pasa a 13 de alto. 84x42."""
    w, h = 84, 42
    y = h - GAP - 4
    back, d = new(w, h)
    d.polygon([(0, h - 1), (2, h - 13), (8, h - 15), (13, h - 9), (14, h - 1)], fill=CONC)  # el pedazo de base
    d.polygon([(6, h - 14), (76, y - 1), (78, y + 3), (8, h - 10)], fill=(110, 116, 124))   # el tubo
    back = outline(back)
    d = ImageDraw.Draw(back)
    d.line([(7, h - 13), (76, y)], fill=(160, 166, 176))                 # el brillo del tubo
    for x, yy in ((4, h - 11), (9, h - 6), (11, h - 12)):
        put(back, x, yy, CONC2)
    d.line([(3, h - 14), (2, h - 18)], fill=RUST)                        # las varillas de la base
    d.line([(10, h - 15), (12, h - 19)], fill=RUST)
    d.line([(1, h - 16), (0, h - 22), (4, h - 26)], fill=(30, 30, 34))   # el cable, pelado
    front, d = new(w, h)
    # La lámpara: la cabeza de cobra en el piso, el vidrio roto.
    d.polygon([(70, y - 2), (82, y + 2), (83, h - 4), (76, h - 1), (68, y + 6)], fill=(90, 96, 104))
    front = outline(front)
    d = ImageDraw.Draw(front)
    d.polygon([(72, y + 5), (80, y + 6), (79, h - 4), (75, h - 3)], fill=(200, 196, 150))  # el vidrio
    put(front, 76, y + 8, (255, 250, 220))
    for x, yy in ((66, h - 1), (62, h - 2), (68, h - 2), (59, h - 1)):   # los vidrios en el piso
        put(front, x, yy, (210, 220, 220))
    return back, front


DUCKS = {"tanque": tanque, "palomar": palomar, "placa": placa, "cumple": cumple, "mula": mula, "poste": poste}


# ---------------------------------------------------------------- Lo que se salta

def salta_pipeta():
    """La pipeta de gas: azul, golpeada, con su válvula y la cadenita. 12x18."""
    im, d = new(12, 18)
    d.rounded_rectangle([1, 4, 10, 17], 3, fill=(52, 86, 160))
    d.rectangle([4, 1, 7, 4], fill=METAL)
    im = outline(im)
    d = ImageDraw.Draw(im)
    d.line([(3, 6), (3, 15)], fill=(96, 130, 200))
    d.line([(1, 10), (10, 10)], fill=(40, 66, 126))
    put(im, 8, 13, (40, 66, 126))
    d.line([(5, 0), (6, 0)], fill=(230, 190, 60))
    text(im, "1", 6, 11, (236, 236, 240))
    return im


def salta_ladrillos():
    """El arrume de ladrillos para la pieza que nunca se hizo. 22x14."""
    im, d = new(22, 14)
    for row, (x0, n) in enumerate([(1, 4), (3, 3), (6, 2)]):
        y = 13 - row * 4
        for k in range(n):
            d.rectangle([x0 + k * 5, y - 3, x0 + k * 5 + 4, y], fill=BRICK if (k + row) % 2 else BRICK3)
    im = outline(im)
    d = ImageDraw.Draw(im)
    for row, (x0, n) in enumerate([(1, 4), (3, 3), (6, 2)]):
        y = 13 - row * 4
        for k in range(n):
            put(im, x0 + k * 5 + 1, y - 2, (200, 130, 100))
            put(im, x0 + k * 5 + 2, y - 2, BRICK2)
    return im


def salta_muro():
    """El murito de la terraza con los vidrios de botella arriba. 12x18."""
    im, d = new(12, 18)
    d.rectangle([1, 4, 10, 17], fill=(186, 170, 140))
    im = outline(im)
    d = ImageDraw.Draw(im)
    d.line([(1, 4), (10, 4)], fill=(214, 202, 176))
    d.line([(1, 11), (10, 11)], fill=(150, 136, 110))
    put(im, 4, 8, (150, 136, 110))
    put(im, 7, 14, (150, 136, 110))
    for x, c in ((1, (60, 140, 70)), (4, (120, 70, 40)), (7, (210, 230, 220)), (9, (60, 140, 70))):
        d.polygon([(x, 3), (x + 1, 0), (x + 2, 3)], fill=c)
    return im


def salta_taxi():
    """Un taxi amarillo varado en el trancón del puente: el letrero de TAXI en el techo, el taxista
    adentro (se le ve la silueta y el brazo afuera). 46x22."""
    im, d = new(46, 22)
    d.polygon([(1, 12), (8, 11), (14, 4), (32, 4), (38, 11), (45, 13), (45, 19), (1, 19)], fill=(236, 190, 30))
    d.rectangle([20, 1, 27, 3], fill=(240, 240, 236))
    for x in (6, 33):
        d.ellipse([x, 14, x + 8, 21], fill=(24, 22, 26))
    im = outline(im)
    d = ImageDraw.Draw(im)
    d.polygon([(16, 5), (22, 5), (22, 10), (11, 10)], fill=(60, 80, 100))        # las ventanas
    d.polygon([(24, 5), (31, 5), (36, 10), (24, 10)], fill=(60, 80, 100))
    d.ellipse([26, 6, 29, 9], fill=(30, 26, 32))                                 # el taxista
    d.line([(14, 10), (37, 11)], fill=(200, 160, 20))
    d.line([(1, 15), (45, 15)], fill=(40, 40, 40))                               # la franja de cuadritos
    for x in range(2, 45, 2):
        put(im, x, 15, (240, 240, 236))
    put(im, 22, 2, INK); put(im, 25, 2, INK)
    for x in (8, 35):
        d.ellipse([x + 2, 16, x + 4, 18], fill=(150, 150, 160))
    d.rectangle([43, 13, 45, 14], fill=(255, 240, 180))                          # la farola
    d.rectangle([1, 13, 2, 14], fill=(220, 40, 40))
    return im


SALTOS = {"pipeta": salta_pipeta, "ladrillos": salta_ladrillos, "muro": salta_muro, "taxi": salta_taxi}


# ---------------------------------------------------------------- El helicóptero

def heli(frame):
    """El helicóptero de la policía, de lado, mirando a la izquierda: la cabina con el vidrio, el
    cuerpo blanco con la franja verde, la cola, el rotor de cola, los patines, el reflector y el que va
    en la puerta con el fusil. 72x30; el rotor grande cambia de cuadro."""
    w, h = 72, 30
    im, d = new(w, h)
    d.ellipse([4, 8, 34, 24], fill=(226, 228, 222))                      # el cuerpo
    d.polygon([(26, 10), (66, 12), (66, 15), (30, 20)], fill=(226, 228, 222))  # la cola
    d.rectangle([64, 6, 67, 15], fill=(226, 228, 222))                   # la aleta
    d.rectangle([18, 4, 24, 8], fill=(120, 124, 130))                    # el mástil
    d.line([(6, 27), (32, 27)], fill=METAL2, width=2)                    # los patines
    d.line([(12, 22), (10, 27)], fill=METAL2)
    d.line([(26, 22), (28, 27)], fill=METAL2)
    d.ellipse([10, 21, 15, 25], fill=(60, 60, 66))                       # el reflector
    im = outline(im)
    d = ImageDraw.Draw(im)
    d.chord([4, 8, 34, 24], 100, 260, fill=(70, 110, 140))               # el vidrio de la cabina
    d.line([(9, 11), (6, 15)], fill=(150, 190, 210))
    d.line([(5, 18), (33, 18)], fill=(40, 120, 70))                      # la franja verde
    d.line([(30, 17), (66, 13)], fill=(40, 120, 70))
    d.line([(8, 9), (30, 9)], fill=(250, 250, 246))
    d.rectangle([20, 11, 26, 17], fill=(30, 30, 36))                     # la puerta abierta
    put(im, 23, 12, SKIN2)                                               # el de la puerta
    d.line([(22, 13), (24, 16)], fill=(70, 80, 70))
    d.line([(24, 15), (29, 18)], fill=(20, 20, 24))                      # el fusil
    put(im, 12, 23, (255, 250, 210))                                     # el reflector, prendido
    for x in range(40, 64, 6):
        put(im, x, 14, (190, 192, 186))
    put(im, 66, 8, (220, 40, 40))                                        # la luz de la aleta
    # El rotor grande: cuadro 0, las aspas largas; cuadro 1, cortas (de frente) y el borrón.
    if frame == 0:
        d.line([(0, 3), (44, 3)], fill=(60, 60, 66))
        d.line([(2, 2), (40, 2)], fill=(140, 140, 150, 120))
    else:
        d.line([(14, 3), (28, 3)], fill=(60, 60, 66))
        for x in range(2, 44, 3):
            put(im, x, 2, (110, 110, 120))
    d.line([(21, 3), (21, 4)], fill=(60, 60, 66))
    # El rotor de cola.
    if frame == 0:
        d.line([(66, 3), (66, 11)], fill=(80, 80, 88))
    else:
        d.line([(62, 7), (70, 7)], fill=(80, 80, 88))
    return im


# ---------------------------------------------------------------- Los vecinos de las terrazas

def vecino(who, frame):
    """De la cintura para arriba, mirando a la izquierda (hacia donde viene él). frame 0: gritando,
    señalando; frame 1: con el brazo atrás, a punto de tirar lo que tiene. 24x28."""
    w, h = 24, 28
    im, d = new(w, h)
    if who == 0:      # la señora de los rulos: bata de flores, los rulos rosados, la chancla en la mano
        skin, coat, coat2 = (200, 140, 112), (120, 160, 200), (90, 124, 168)
        d.rounded_rectangle([7, 12, 19, 27], 3, fill=coat)              # el cuerpo, la bata
        d.ellipse([8, 2, 17, 12], fill=(70, 50, 40))                     # el pelo
        d.ellipse([9, 4, 16, 12], fill=skin)
    elif who == 1:    # el señor de la barriga, en esqueleto, con la cerveza
        skin, coat, coat2 = (190, 128, 96), (236, 236, 230), (200, 198, 190)
        d.ellipse([5, 13, 21, 30], fill=coat)                            # la barriga
        d.rectangle([7, 12, 19, 18], fill=coat)
        d.ellipse([8, 3, 17, 12], fill=skin)
        d.rectangle([7, 12, 9, 16], fill=skin)                           # los hombros afuera
        d.rectangle([17, 12, 19, 16], fill=skin)
    elif who == 2:    # la rezandera: la mantilla negra, el rosario, la blusa morada
        skin, coat, coat2 = (206, 150, 120), (110, 70, 130), (84, 52, 104)
        d.rounded_rectangle([7, 12, 19, 27], 3, fill=coat)
        d.polygon([(7, 4), (12, 1), (18, 4), (20, 16), (6, 16)], fill=(34, 30, 36))  # la mantilla
        d.ellipse([9, 4, 16, 12], fill=skin)
    else:             # el pelado del celular: gorra al revés, buzo rojo, grabando
        skin, coat, coat2 = (176, 120, 90), (196, 50, 50), (150, 36, 40)
        d.rounded_rectangle([7, 12, 19, 27], 3, fill=coat)
        d.ellipse([9, 4, 16, 12], fill=skin)
        d.rectangle([9, 2, 17, 5], fill=(30, 30, 40))                    # la gorra
        d.rectangle([15, 4, 19, 5], fill=(30, 30, 40))                   # la visera, para atrás
    # El brazo: adelante señalando (0) o atrás, con la mano arriba (1).
    if frame == 0:
        d.line([(9, 15), (3, 12), (1, 10)], fill=coat, width=3)
        d.rectangle([0, 8, 2, 10], fill=skin)
    else:
        d.line([(16, 15), (21, 9), (20, 4)], fill=coat, width=3)
        d.rectangle([19, 2, 21, 4], fill=skin)
    im = outline(im)
    d = ImageDraw.Draw(im)
    # La cara (de perfil, a la izquierda): la nariz, el ojo, la boca abierta gritando.
    put(im, 8, 8, skin)
    put(im, 10, 7, INK)
    d.line([(9, 10), (10, 10)], fill=(90, 30, 34))
    put(im, 9, 11, (90, 30, 34))
    if who == 0:
        for x, y in ((9, 3), (12, 2), (15, 3), (16, 6)):                 # los rulos
            d.rectangle([x, y, x + 1, y + 1], fill=(240, 150, 190))
        for x, y in ((10, 17), (15, 21), (11, 24), (17, 15)):            # las flores de la bata
            put(im, x, y, (250, 240, 120))
            put(im, x + 1, y, (240, 100, 120))
        if frame == 1:                                                   # la chancla, arriba
            d.rectangle([18, 0, 22, 2], fill=(60, 180, 90))
    elif who == 1:
        d.line([(9, 9), (11, 9)], fill=(60, 40, 34))                     # el bigote
        d.line([(10, 3), (16, 3)], fill=(70, 50, 44))                    # lo que le queda de pelo
        d.line([(11, 13), (11, 17)], fill=coat2)
        d.line([(15, 13), (15, 17)], fill=coat2)
        put(im, 14, 22, coat2)                                           # el ombligo, a la vista
        if frame == 0:
            d.rectangle([20, 14, 21, 18], fill=(150, 90, 30))            # la cerveza, en la otra mano
            put(im, 20, 13, (240, 236, 220))
    elif who == 2:
        for k in range(5):                                               # el rosario
            put(im, 11 + k, 14 + (k % 2), (240, 236, 220))
        d.line([(13, 16), (13, 19)], fill=(230, 200, 90))
        d.line([(12, 17), (14, 17)], fill=(230, 200, 90))
    else:
        if frame == 0:                                                   # el celular, grabando
            d.rectangle([1, 5, 3, 9], fill=(30, 30, 36))
            put(im, 2, 6, (250, 250, 255))
        d.line([(9, 18), (17, 18)], fill=coat2)
        put(im, 13, 15, (250, 250, 250))                                 # el logo del buzo
    return im


def terraza(kind):
    """El borde de la terraza de una casa, por delante del vecino: la baranda (balaústres de cemento,
    o el muro de ladrillo a la vista) con sus materas. 40x18."""
    w, h = 40, 18
    im, d = new(w, h)
    if kind == 0:
        d.rectangle([0, 2, 39, 4], fill=(222, 206, 160))                # el pasamanos
        d.rectangle([0, 13, 39, 17], fill=(222, 206, 160))              # el zócalo
        for x in range(2, 38, 6):
            d.rectangle([x, 5, x + 2, 12], fill=(206, 190, 146))        # los balaústres
        d.rectangle([28, -3, 35, 1], fill=(180, 90, 60))                # la matera
    else:
        d.rectangle([0, 1, 39, 17], fill=BRICK)
        d.rectangle([4, -4, 11, 0], fill=(180, 90, 60))
    im = outline(im)
    d = ImageDraw.Draw(im)
    if kind == 0:
        d.line([(0, 2), (39, 2)], fill=(244, 232, 196))
        for x in range(2, 38, 6):
            put(im, x, 6, (236, 222, 180))
            d.line([(x + 1, 8), (x + 1, 9)], fill=(180, 162, 120))
        for x in (29, 31, 33):                                           # los geranios
            put(im, x, 1, (70, 140, 60))
        put(im, 30, 0, (220, 50, 80))
        put(im, 32, 0, (240, 200, 60))
    else:
        for y in range(3, 17, 3):
            d.line([(0, y), (39, y)], fill=BRICK2)
            off = 0 if (y // 3) % 2 else 3
            for x in range(off, 40, 6):
                put(im, x, y + 1, BRICK2)
        put(im, 6, 0, (70, 140, 60))
        put(im, 8, 0, (70, 140, 60))
        put(im, 7, 0, (240, 240, 240))
    return im


# ---------------------------------------------------------------- Lo que tiran, y las palomas

def tiran():
    """chancla, huevo, matera, biblia: 8x8 cada uno, en fila."""
    im, d = new(32, 8)
    d.rounded_rectangle([1, 2, 7, 6], 2, fill=(60, 180, 90))            # la chancla
    d.ellipse([9, 1, 14, 7], fill=(244, 236, 214))                      # el huevo
    d.polygon([(17, 3), (23, 3), (22, 7), (18, 7)], fill=(180, 90, 60))  # la matera
    d.rectangle([25, 1, 30, 7], fill=(40, 30, 34))                      # la biblia
    im = outline(im)
    d = ImageDraw.Draw(im)
    d.line([(3, 3), (5, 5)], fill=(240, 240, 240))                      # la tira
    put(im, 10, 2, (255, 255, 250))
    d.line([(18, 2), (19, 0)], fill=(70, 140, 60))
    d.line([(21, 2), (22, 0)], fill=(70, 140, 60))
    put(im, 20, 1, (220, 50, 80))
    d.line([(27, 3), (27, 5)], fill=(230, 200, 90))                     # la cruz dorada
    d.line([(26, 4), (28, 4)], fill=(230, 200, 90))
    d.line([(30, 2), (30, 6)], fill=(240, 236, 220))                    # las hojas
    return im


def paloma():
    im, d = new(16, 6)
    for k, up in enumerate((True, False)):
        x = k * 8
        d.ellipse([x + 1, 2, x + 6, 5], fill=(128, 128, 140))
        if up:
            d.polygon([(x + 2, 3), (x + 4, 0), (x + 5, 3)], fill=(150, 150, 162))
        else:
            d.polygon([(x + 2, 3), (x + 4, 5), (x + 5, 3)], fill=(150, 150, 162))
        put(im, x + 6, 2, (128, 128, 140))
        put(im, x + 7, 2, (210, 170, 150))
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    out = {}
    out["player_slide"] = player_slide()
    for name, fn in DUCKS.items():
        b, f = fn()
        out[name + "_atras"] = b
        out[name + "_frente"] = f
    for name, fn in SALTOS.items():
        out["salta_" + name] = fn()
    hs = Image.new("RGBA", (72 * 2, 30), (0, 0, 0, 0))
    for k in range(2):
        f = heli(k)
        hs.paste(f, (k * 72, 0), f)
    out["heli"] = hs
    vs = Image.new("RGBA", (24 * 2, 28 * 4), (0, 0, 0, 0))
    for who in range(4):
        for k in range(2):
            f = vecino(who, k)
            vs.paste(f, (k * 24, who * 28), f)
    out["vecinos"] = vs
    for k in range(2):
        out["terraza_%d" % k] = terraza(k)
    out["tiran"] = tiran()
    out["paloma"] = paloma()
    for name, im in out.items():
        im.save(os.path.join(OUT, name + ".png"))
    if len(sys.argv) > 2 and sys.argv[1] == "--hoja":
        hoja(out, sys.argv[2])
    print("huida: %d hojas" % len(out))


def hoja(out, path):
    """Todo junto, sobre el color de la noche, con las capas de atrás y adelante superpuestas."""
    items = [out["player_slide"]]
    for name in DUCKS:
        b = out[name + "_atras"].copy()
        b.alpha_composite(out[name + "_frente"])
        items.append(b)
    items += [out["salta_" + n] for n in SALTOS] + [out["heli"], out["vecinos"], out["terraza_0"], out["terraza_1"],
                                                    out["tiran"], out["paloma"]]
    W = 600
    x, y, rowh = 4, 4, 0
    pos = []
    for im in items:
        if x + im.width > W:
            x, y = 4, y + rowh + 6
            rowh = 0
        pos.append((x, y))
        x += im.width + 6
        rowh = max(rowh, im.height)
    sheet = Image.new("RGBA", (W, y + rowh + 4), (36, 32, 52, 255))
    for im, p in zip(items, pos):
        sheet.alpha_composite(im, p)
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(path)


if __name__ == "__main__":
    main()
