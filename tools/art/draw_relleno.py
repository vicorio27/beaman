"""El relleno del barrio: lo que faltaba en los espacios vacíos de la calle (City), en el mismo estilo de
draw_barrio.py (contorno violeta oscuro, colores gastados, perspectiva oblicua). Lo pone en el mundo
scripts/world/Relleno.gd al cargar el lugar (City.tscn no se regenera: tiene arreglos hechos a mano).

    python tools/art/draw_relleno.py     -> assets/relleno/*.png

  el lote de los pelados   la cancha de cal, el arco oxidado, las llantas de gradería, la silla rota,
                           las gallinas, el letrero de NO BOTE BASURA (con la basura debajo)
  el potrero de arriba     el caballo del zorrero, la zorra con trastos, la maleza, el SE VENDE
  las casas                los caminitos de tierra, las matas en tarros, el tendedero, las pipetas, las
                           matas de plátano, la mesa de la tienda
  junto a la plaza         la caseta del chance, el de los minutos
  la derecha               las arepas en la parrilla, el tanque de agua
  el río                   los juncos, la garza, el carrito de mercado hundido, la basura que flota
  la plaza                 el agua de la fuente, las palomas, las materas de ladrillo, el busto del
                           prócer, el lustrabotas, el paletero
"""
import math
import os
import random

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "relleno")
R = random.Random(23)
INK = (38, 28, 44)


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(im, x, y, c, a=255):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((int(x), int(y)), tuple(c[:3]) + (a,))


def rect(im, box, c, a=255):
    ImageDraw.Draw(im).rectangle(box, fill=tuple(c[:3]) + (a,))


def line(im, p, q, c, w=1, a=255):
    ImageDraw.Draw(im).line([p, q], fill=tuple(c[:3]) + (a,), width=w)


def ell(im, box, c, a=255):
    ImageDraw.Draw(im).ellipse(box, fill=tuple(c[:3]) + (a,))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def outline(im, col=INK):
    w, h = im.size
    src = im.copy()
    s, o = src.load(), im.load()
    for y in range(h):
        for x in range(w):
            if s[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and s[nx, ny][3] > 200 and s[nx, ny][:3] != col:
                        o[x, y] = col + (255,)
                        break
    return im


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name + ".png"))


GLYPH = {
    "A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"], "M": ["10001", "11011", "10101", "10001", "10001"], "N": ["1001", "1101", "1011", "1001"],
    "O": ["010", "101", "101", "101", "010"], "R": ["110", "101", "110", "101", "101"], "S": ["011", "100", "010", "001", "110"],
    "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"],
    "$": ["011", "110", "010", "011", "110"], "0": ["111", "101", "101", "101", "111"], "2": ["110", "001", "010", "100", "111"],
    "3": ["110", "001", "010", "001", "110"], "1": ["010", "110", "010", "010", "111"], " ": ["0", "0", "0", "0", "0"],
    "P": ["110", "101", "110", "100", "100"], "L": ["100", "100", "100", "100", "111"], "Z": ["111", "001", "010", "100", "111"],
    "G": ["011", "100", "101", "101", "011"], "Y": ["101", "101", "010", "010", "010"], "?": ["110", "001", "010", "000", "010"],
}


def letters(im, s, x, y, c):
    cx = x
    for ch in s:
        g = GLYPH.get(ch, GLYPH[" "])
        if ch == "N":
            g = g + ["1001"]
        for j, r in enumerate(g):
            for i, v in enumerate(r):
                if v == "1":
                    px(im, cx + i, y + j, c)
        cx += len(g[0]) + 1


def letters_w(s):
    return sum(len(GLYPH.get(ch, GLYPH[" "])[0]) + 1 for ch in s) - 1


SKIN = (196, 136, 104)
SKIN_D = (160, 104, 80)
WOOD = (132, 92, 58)
WOOD_D = (96, 66, 42)
RUST = (176, 96, 52)
WHITE = (226, 222, 210)


# ================================================================ El lote de los pelados

def lote():
    # La cancha de cal (150x64): rayas medio borradas, el círculo, las áreas; tierra pelada donde se pisa.
    W, H = 152, 66
    c = new(W, H)
    cal = (232, 228, 206)
    def dots(pts, a=110, keep=0.8):
        for (x, y) in pts:
            if R.random() < keep:
                px(c, x, y, cal, a)
    for (cx, cy) in ((10, H // 2), (W - 10, H // 2), (W // 2, H // 2)):
        for _ in range(240):
            a = R.random() * 2 * math.pi
            r = R.random() ** 0.6
            px(c, cx + r * 14 * math.cos(a), cy + r * 9 * math.sin(a), (150, 120, 88), 90)
    dots([(x, 1) for x in range(W)] + [(x, H - 2) for x in range(W)])
    dots([(0, y) for y in range(H)] + [(W - 1, y) for y in range(H)] + [(W // 2, y) for y in range(H)])
    dots([(W // 2 + 12 * math.cos(math.radians(a)), H // 2 + 8 * math.sin(math.radians(a))) for a in range(0, 360, 4)])
    for x0, x1 in ((0, 22), (W - 23, W - 1)):
        xi = x1 if x0 == 0 else x0
        dots([(xi, y) for y in range(H // 2 - 16, H // 2 + 17)])
        dots([(x, H // 2 - 16) for x in range(x0, x1)] + [(x, H // 2 + 16) for x in range(x0, x1)])
    save(c, "cancha_cal")
    # Los morrales que hacen de palos del arco (y una chancla, por si falta uno).
    for k, (col, dk) in enumerate([((60, 90, 160), (40, 60, 110)), ((200, 60, 70), (140, 40, 50)), ((70, 70, 80), (46, 46, 54))]):
        m = new(11, 10)
        ImageDraw.Draw(m).rounded_rectangle((1, 1, 9, 9), radius=3, fill=col + (255,))
        rect(m, (2, 5, 8, 8), dk)
        line(m, (2, 5), (8, 5), mix(col, (255, 255, 255), 0.3))
        px(m, 5, 6, (200, 200, 200))
        line(m, (3, 1), (7, 1), dk)
        save(outline(m), "morral_%d" % k)
    ch = new(10, 5)
    ImageDraw.Draw(ch).rounded_rectangle((0, 1, 9, 4), radius=2, fill=(60, 120, 200, 255))
    line(ch, (3, 1), (5, 3), (240, 240, 240))
    line(ch, (6, 1), (5, 3), (240, 240, 240))
    save(outline(ch), "chancla")
    # El arco oxidado, sin malla (quedan unos hilos).
    a = new(40, 28)
    for x in (2, 36):
        rect(a, (x, 4, x + 1, 27), WHITE)
        for y in range(6, 27, 4):
            px(a, x, y, RUST)
            px(a, x + 1, y + 1, RUST)
    rect(a, (2, 3, 37, 4), WHITE)
    for x in range(4, 36, 5):
        px(a, x, 3, RUST)
    for x in range(6, 34, 6):  # lo que queda de la malla
        for y in range(5, 5 + R.randrange(4, 12), 2):
            px(a, x + (y // 2) % 2, y, (150, 150, 156))
    save(outline(a), "arco")
    # Llanta medio enterrada, pintada (gradería de los pelados).
    for k, col in enumerate([(236, 196, 58), WHITE, (206, 52, 58)]):
        t = new(18, 10)
        ell(t, (0, 0, 17, 17), (40, 38, 44))
        ell(t, (5, 5, 12, 12), (90, 74, 56))
        for ang in range(200, 340, 12):
            px(t, 8.5 + 7 * math.cos(math.radians(ang)), 8.5 + 7 * math.sin(math.radians(ang)), col)
        rect(t, (0, 9, 17, 9), (110, 88, 64))
        save(outline(t.crop((0, 0, 18, 10))), "llanta_%d" % k)
    # La silla plástica blanca, sin una pata, de medio lado.
    s = new(14, 16)
    rect(s, (2, 2, 11, 3), WHITE)
    rect(s, (2, 4, 3, 9), WHITE)
    rect(s, (10, 4, 11, 9), WHITE)
    rect(s, (1, 9, 12, 10), WHITE)
    line(s, (2, 11), (1, 15), (200, 196, 186))
    line(s, (11, 11), (12, 15), (200, 196, 186))
    line(s, (9, 11), (9, 13), (200, 196, 186))  # la pata partida
    for y in range(4, 9):
        px(s, 5, y, (210, 206, 194))
        px(s, 8, y, (210, 206, 194))
    save(outline(s.rotate(-12, resample=Image.NEAREST, expand=True)), "silla_rota")
    # Las gallinas: de pie, picoteando, caminando.
    for k in range(3):
        g = new(12, 11)
        body = (176, 110, 60) if k != 2 else (176, 110, 60)
        ell(g, (1, 3, 9, 9), body)
        ell(g, (2, 4, 6, 8), (150, 90, 48))  # el ala
        px(g, 0, 3, (120, 70, 40))
        px(g, 0, 4, (120, 70, 40))  # la cola
        if k == 1:  # picoteando: la cabeza abajo
            ell(g, (8, 6, 11, 9), body)
            px(g, 11, 9, (230, 180, 60))
            px(g, 9, 6, (210, 40, 40))
        else:
            ell(g, (7, 0, 10, 4), body)
            px(g, 11, 2, (230, 180, 60))
            px(g, 8, 0, (210, 40, 40))
            px(g, 9, 0, (210, 40, 40))
            px(g, 9, 2, INK)
        px(g, 4, 10, (230, 180, 60))
        px(g, 6 if k != 2 else 7, 10, (230, 180, 60))
        save(outline(g), "gallina_%d" % k)
    # El letrero: NO BOTE BASURA (y la basura debajo, que la pone el juego al lado).
    l = new(34, 30)
    rect(l, (15, 14, 17, 29), WOOD_D)
    rect(l, (1, 1, 32, 15), (214, 206, 186))
    for x in range(1, 33, 3):
        line(l, (x, 1), (x, 15), (196, 186, 166))
    letters(l, "NO BOTE", 17 - letters_w("NO BOTE") // 2, 3, (170, 40, 40))
    letters(l, "BASURA", 17 - letters_w("BASURA") // 2, 9, (170, 40, 40))
    px(l, 3, 2, RUST)
    px(l, 31, 13, RUST)
    save(outline(l), "letrero_basura")


# ================================================================ El potrero de arriba

def potrero():
    # El caballo flaco del zorrero, amarrado a un palo: pastando y con la cabeza arriba.
    for k in range(2):
        h = new(34, 26)
        coat, dark = (126, 86, 58), (96, 62, 42)
        ell(h, (6, 7, 24, 16), coat)
        for x in range(9, 23, 3):  # las costillas
            line(h, (x, 10), (x, 13), dark)
        if k == 0:  # pastando: el cuello abajo
            ImageDraw.Draw(h).polygon([(22, 9), (28, 16), (30, 20), (27, 21), (21, 14)], fill=coat + (255,))
            ell(h, (26, 18, 32, 23), coat)
            px(h, 30, 19, INK)
        else:
            ImageDraw.Draw(h).polygon([(21, 9), (25, 2), (29, 3), (27, 9), (23, 13)], fill=coat + (255,))
            ell(h, (26, 1, 33, 7), coat)
            px(h, 30, 3, INK)
        for x in (8, 11, 19, 22):  # las patas flacas
            line(h, (x, 15), (x, 24), dark)
            px(h, x, 25, INK)
        for i in range(6):  # la cola
            px(h, 5 - i // 3, 9 + i + k, (60, 40, 30))
        for i in range(4):  # la crin
            px(h, 23 + i, 7 - i if k else 11 + i, (60, 40, 30))
        save(outline(h), "caballo_%d" % k)
    poste = new(6, 20)
    rect(poste, (2, 0, 3, 19), WOOD_D)
    line(poste, (2, 4), (5, 6), (190, 170, 120))
    save(outline(poste), "poste_lazo")
    # La zorra: el planchón de tablas, dos llantas de carro, trastos encima.
    z = new(40, 22)
    rect(z, (2, 8, 36, 13), WOOD)
    for x in range(4, 36, 5):
        line(z, (x, 8), (x, 13), WOOD_D)
    line(z, (36, 10), (39, 4), WOOD_D, 2)  # las varas
    for wx in (9, 29):
        ell(z, (wx - 5, 11, wx + 5, 21), (40, 38, 44))
        ell(z, (wx - 2, 14, wx + 2, 18), (120, 120, 126))
    rect(z, (5, 1, 15, 8), (210, 210, 206))  # una puerta de nevera
    line(z, (13, 3), (13, 6), (150, 150, 150))
    rect(z, (17, 3, 27, 8), (170, 134, 90))  # cartones
    line(z, (17, 5), (27, 5), (140, 108, 70))
    rect(z, (28, 5, 33, 8), (70, 110, 160))  # un balde
    save(outline(z), "zorra")
    # La maleza (matas sueltas, para salpicar) y el SE VENDE.
    for k in range(3):
        m = new(18, 10)
        for i in range(9):
            x = 2 + i * 1.6 + R.random()
            hgt = R.randrange(3, 9)
            line(m, (x, 9), (x + R.choice([-2, -1, 1, 2]), 9 - hgt), R.choice([(96, 116, 58), (120, 130, 66), (150, 140, 82)]))
        if k == 1:
            px(m, 6, 2, (240, 220, 90))
            px(m, 12, 3, (240, 220, 90))
        save(m, "maleza_%d" % k)
    v = new(32, 30)
    rect(v, (14, 14, 16, 29), WOOD_D)
    rect(v, (1, 1, 30, 15), (240, 236, 214))
    letters(v, "SE VENDE", 16 - letters_w("SE VENDE") // 2, 3, (40, 60, 150))
    letters(v, "310", 6, 9, (40, 40, 50))
    for x in range(18, 28, 2):
        px(v, x, 11, (40, 40, 50))
    save(outline(v), "se_vende")


# ================================================================ Las casas

DOORS = [(42, 336), (126, 336), (176, 400), (42, 448), (145, 470), (330, 380), (238, 560), (64, 576)]


def casas():
    # Los caminitos: tierra pisada de cada puerta hasta el callejón (y = 424, por donde camina Wilson).
    d = new(440, 340)
    worn = (150, 122, 92)
    def path(p, q, w=5):
        n = int(max(abs(q[0] - p[0]), abs(q[1] - p[1]))) + 1
        for i in range(n):
            x = p[0] + (q[0] - p[0]) * i / n
            y = p[1] + (q[1] - p[1]) * i / n
            for j in range(-w // 2, w // 2 + 1):
                for jj in range(-1, 2):
                    if R.random() < 0.55:
                        if q[0] == p[0]:
                            px(d, x + j, y + jj, worn, R.choice([70, 90, 110]))
                        else:
                            px(d, x + jj, y + j, worn, R.choice([70, 90, 110]))
    oy = 280
    path((0, 424 - oy), (436, 424 - oy), 7)
    path((0, 600 - oy), (436, 600 - oy), 5)
    for (x, y) in DOORS:
        y0 = y + 2 - oy
        target = 424 - oy if abs(424 - y) < abs(600 - y) or y < 424 else 600 - oy
        path((x, y0), (x, target), 4)
    # Las maticas de jardín al lado de las puertas (flores rojas y rosadas, la tierra mojada).
    for (x, y) in DOORS:
        gx, gy = x + 14, y - oy + 3
        for _ in range(26):
            px(d, gx + R.randrange(-6, 7), gy + R.randrange(-2, 3), R.choice([(78, 104, 52), (96, 120, 60)]))
        for _ in range(4):
            px(d, gx + R.randrange(-5, 6), gy + R.randrange(-2, 2), R.choice([(214, 60, 70), (240, 140, 180), (240, 220, 90)]))
    for (cx, cy, w) in [(110, 200, 18), (300, 290, 22), (40, 250, 14)]:  # charcos
        ell(d, (cx - w // 2, cy - 3, cx + w // 2, cy + 3), (70, 84, 96), 200)
        line(d, (cx - w // 4, cy - 1), (cx, cy - 1), (120, 140, 150), 1, 200)
    save(d, "senderos_casas")
    # Las matas en tarros de pintura (y una en un balde de plástico).
    for k, (pot, flower) in enumerate([((214, 210, 200), (214, 60, 70)), ((70, 110, 170), (240, 140, 180)), ((200, 150, 60), (240, 220, 90))]):
        m = new(12, 16)
        rect(m, (2, 9, 9, 15), pot)
        line(m, (2, 9), (9, 9), mix(pot, (255, 255, 255), 0.3))
        line(m, (9, 9), (9, 15), mix(pot, (0, 0, 0), 0.25))
        for i in range(6):
            line(m, (5, 9), (1 + i * 2, 3 + (i % 3)), (78, 116, 52))
        for (x, y) in [(2, 3), (6, 1), (10, 4), (4, 5)]:
            px(m, x, y, flower)
        save(outline(m), "mata_%d" % k)
    # El tendedero: dos palos, la cuerda, la ropa (que el viento mueve: dos cuadros).
    for k in range(2):
        t = new(66, 32)
        for x in (1, 63):
            rect(t, (x, 2, x + 1, 31), WOOD_D)
        sag = lambda x: 4 + int(3 * math.sin(math.pi * (x - 2) / 62))
        for x in range(2, 64):
            px(t, x, sag(x), (200, 200, 190))
        clothes = [(6, 10, (206, 60, 70), "camisa"), (18, 9, (60, 100, 160), "jean"), (30, 12, (240, 236, 220), "toalla"),
                   (45, 8, (240, 200, 70), "camisa"), (56, 5, (60, 60, 70), "medias")]
        for (x, w, col, kind) in clothes:
            top = sag(x + w // 2) + 1
            sway = (1 if k else -1) * (1 if kind != "jean" else 0)
            if kind == "camisa":
                rect(t, (x + sway, top, x + w + sway, top + 7), col)
                rect(t, (x - 2 + sway, top, x + sway, top + 3), col)
                rect(t, (x + w + sway, top, x + w + 2 + sway, top + 3), col)
            elif kind == "jean":
                rect(t, (x, top, x + w, top + 3), col)
                rect(t, (x, top + 3, x + 3, top + 13), col)
                rect(t, (x + w - 3, top + 3, x + w, top + 13), col)
            elif kind == "toalla":
                rect(t, (x + sway, top, x + w + sway, top + 11), col)
                line(t, (x + sway, top + 9), (x + w + sway, top + 9), (200, 60, 70))
            else:
                for i in range(2):
                    rect(t, (x + i * 4 + sway, top, x + i * 4 + 2 + sway, top + 5), col)
            px(t, x + 1, top - 1, (150, 120, 90))  # el gancho
        save(outline(t), "tendedero_%d" % k)
    # Las pipetas de gas (dos, una azul y una gris), con la manguera.
    p = new(18, 20)
    for i, col in enumerate([(60, 100, 170), (150, 150, 160)]):
        x = 1 + i * 8
        ImageDraw.Draw(p).rounded_rectangle((x, 4, x + 7, 19), radius=3, fill=col + (255,))
        rect(p, (x + 2, 1, x + 5, 4), (120, 120, 126))
        line(p, (x + 1, 6), (x + 1, 17), mix(col, (255, 255, 255), 0.35))
    line(p, (5, 2), (12, 0), (40, 40, 44))
    save(outline(p), "pipetas")
    # La mata de plátano: hojas grandes, unas rotas por el viento.
    b = new(26, 32)
    rect(b, (11, 14, 14, 31), (110, 140, 70))
    line(b, (11, 14), (11, 31), (90, 116, 56))
    for (dx, dy, ln, ang) in [(-1, 0, 14, 200), (1, 0, 14, 340), (0, -1, 12, 250), (0, 0, 12, 300), (0, 2, 10, 160), (0, 2, 10, 20)]:
        a0 = math.radians(ang)
        for i in range(ln):
            x = 12.5 + math.cos(a0) * i
            y = 14 + math.sin(a0) * i * 0.8 + (i * i) * 0.03
            for w in range(-2, 3):
                torn = ang in (160, 20) and i > 6 and w > 0 and i % 2
                if not torn:
                    px(b, x + w * math.sin(a0) * 0.6, y + w * 0.5, (96, 140, 64) if w else (130, 170, 80))
    save(outline(b), "platano")
    # La mesa de la tienda: mesa plástica, dos sillas, cervezas, la canasta roja y el parasol.
    m = new(50, 40)
    for i in range(12):  # el parasol
        a0, a1 = math.pi + i * math.pi / 12, math.pi + (i + 1) * math.pi / 12
        ImageDraw.Draw(m).polygon([(25, 2), (25 + 22 * math.cos(a0), 12 + 8 * math.sin(a0) + 8), (25 + 22 * math.cos(a1), 12 + 8 * math.sin(a1) + 8)],
                                  fill=((206, 52, 58) if i % 2 == 0 else (240, 236, 226)) + (255,))
    line(m, (25, 12), (25, 30), (180, 180, 186))
    ell(m, (12, 24, 38, 31), (236, 234, 226))  # la mesa
    line(m, (16, 30), (16, 38), (210, 210, 206))
    line(m, (34, 30), (34, 38), (210, 210, 206))
    for (x, y) in [(18, 25), (22, 24), (29, 25), (32, 26)]:  # las botellas
        rect(m, (x, y - 4, x + 1, y), (150, 90, 30))
        px(m, x, y - 5, (220, 200, 140))
    for sx in (4, 42):  # las sillas
        rect(m, (sx, 28, sx + 5, 30), (236, 234, 226))
        rect(m, (sx + (0 if sx < 20 else 4), 22, sx + (1 if sx < 20 else 5), 30), (236, 234, 226))
        line(m, (sx, 31), (sx, 38), (210, 210, 206))
        line(m, (sx + 5, 31), (sx + 5, 38), (210, 210, 206))
    rect(m, (40, 33, 49, 39), (190, 40, 40))  # la canasta de las vacías
    for x in range(41, 49, 2):
        px(m, x, 33, (150, 90, 30))
    save(outline(m), "tienda_mesa")


# ================================================================ Junto a la plaza y la derecha

def puestos():
    # La caseta del chance: blanca y roja, la ventanita con la señora, los billetes colgados.
    c = new(32, 38)
    rect(c, (1, 10, 30, 37), (236, 232, 222))
    rect(c, (0, 4, 31, 10), (206, 52, 58))
    letters(c, "CHANCE", 16 - letters_w("CHANCE") // 2, 6, (255, 236, 150))
    rect(c, (6, 14, 25, 24), (40, 36, 46))  # la ventana
    ell(c, (12, 15, 19, 22), SKIN)
    rect(c, (11, 14, 20, 17), (60, 36, 30))  # el pelo de la señora
    px(c, 14, 19, INK)
    px(c, 17, 19, INK)
    rect(c, (11, 22, 20, 24), (120, 60, 140))
    for x in range(7, 25, 4):  # los billetes de lotería colgados
        rect(c, (x, 25, x + 2, 29), R.choice([(240, 220, 120), (150, 210, 240), (240, 160, 180)]))
    rect(c, (4, 30, 27, 31), (206, 52, 58))
    save(outline(c), "chance")
    # El de los minutos: la sombrilla de colores, la mesa, los celulares encadenados, el señor sentado.
    for k in range(2):
        m = new(36, 34)
        for i in range(8):
            a0, a1 = math.pi + i * math.pi / 8, math.pi + (i + 1) * math.pi / 8
            ImageDraw.Draw(m).polygon([(18, 1), (18 + 17 * math.cos(a0), 9 + 6 * math.sin(a0) + 6), (18 + 17 * math.cos(a1), 9 + 6 * math.sin(a1) + 6)],
                                      fill=[(206, 52, 58), (236, 196, 58), (60, 110, 200), (64, 170, 92)][i % 4] + (255,))
        line(m, (18, 9), (18, 24), (180, 180, 186))
        rect(m, (6, 22, 30, 25), (110, 74, 46))  # la mesa
        line(m, (8, 26), (8, 33), WOOD_D)
        line(m, (28, 26), (28, 33), WOOD_D)
        rect(m, (8, 20, 10, 22), (40, 40, 46))  # los celulares
        rect(m, (13, 20, 15, 22), (40, 40, 46))
        line(m, (9, 22), (14, 22), (190, 190, 196))
        rect(m, (1, 12, 17, 19), (240, 236, 214))  # el cartelito, colgado del palo
        letters(m, "MIN", 2, 13, (40, 40, 120))
        # el señor, en una silla plástica, abanicándose con la mano
        rect(m, (30, 18, 35, 26), (70, 120, 90))
        ell(m, (29, 11, 35, 18), SKIN)
        rect(m, (29, 10, 35, 12), (230, 230, 230))  # la cachucha blanca
        line(m, (30, 20), (27 + k, 15 + k), SKIN, 1)
        line(m, (31, 26), (31, 33), (60, 60, 80))
        line(m, (34, 26), (34, 33), (60, 60, 80))
        save(outline(m), "minutos_%d" % k)
    # Las arepas en la parrilla (humo en dos cuadros) y el tanque de agua negro.
    for k in range(2):
        a = new(30, 34)
        rect(a, (3, 18, 26, 22), (60, 60, 66))  # la parrilla
        for x in range(4, 26, 2):
            px(a, x, 18, (180, 180, 186))
        rect(a, (5, 22, 24, 29), (150, 104, 66))
        line(a, (6, 29), (6, 33), (60, 60, 66))
        line(a, (23, 29), (23, 33), (60, 60, 66))
        for x in (8, 15, 21):  # las arepas
            ell(a, (x - 3, 15, x + 3, 19), (236, 200, 120))
            px(a, x, 17, (200, 150, 80))
        for i in range(5):  # el humo
            px(a, 12 + (i + k) % 3 - 1, 13 - i * 2 - k, (200, 200, 206), 200 - i * 30)
            px(a, 18 - (i + k) % 3, 12 - i * 2, (200, 200, 206), 180 - i * 30)
        rect(a, (1, 8, 12, 13), (240, 236, 214))  # el letrero
        letters(a, "AREP", 2, 9 - 0, (170, 40, 40)) if False else letters(a, "1000", 2, 9, (170, 40, 40))
        save(outline(a), "arepas_%d" % k)
    t = new(18, 20)
    ell(t, (1, 1, 16, 6), (50, 50, 56))
    rect(t, (1, 4, 16, 18), (36, 36, 42))
    for y in (8, 13):
        line(t, (1, y), (16, y), (56, 56, 64))
    line(t, (3, 5), (3, 17), (70, 70, 80))
    save(outline(t), "tanque")


# ================================================================ El río

def rio():
    for k in range(2):  # los juncos
        j = new(16, 16)
        for i in range(8):
            x = 2 + i * 1.6
            line(j, (x, 15), (x + R.choice([-2, -1, 1, 2]), 15 - R.randrange(6, 14)), R.choice([(96, 120, 70), (120, 140, 80), (80, 100, 60)]))
        if k == 0:
            for (x, y) in [(5, 2), (10, 3)]:
                rect(j, (x, y, x + 1, y + 3), (110, 76, 50))  # las cabecitas cafés
        save(j, "junco_%d" % k)
    for k in range(2):  # la garza: parada, y con la cabeza abajo (pescando). Patas y cuello largos.
        g = new(18, 30)
        white = (240, 240, 236)
        ell(g, (3, 11, 13, 18), white)
        line(g, (3, 14), (0, 17), (206, 206, 202))  # la cola
        line(g, (7, 17), (7, 29), (176, 150, 70))
        line(g, (10, 17), (10, 29), (176, 150, 70))
        px(g, 6, 29, (176, 150, 70))
        px(g, 11, 29, (176, 150, 70))
        if k == 0:  # el cuello en ese, la cabeza arriba
            line(g, (11, 12), (13, 8), white, 2)
            line(g, (13, 8), (11, 4), white, 2)
            ell(g, (10, 1, 14, 5), white)
            line(g, (14, 3), (17, 4), (230, 190, 60))
            px(g, 12, 2, INK)
        else:  # el cuello estirado hacia el agua
            line(g, (12, 13), (15, 18), white, 2)
            ell(g, (13, 17, 17, 21), white)
            line(g, (16, 21), (17, 25), (230, 190, 60))
            px(g, 15, 18, INK)
        line(g, (5, 13), (11, 15), (206, 206, 202))  # el ala
        save(outline(g), "garza_%d" % k)
    c = new(24, 12)  # el carrito de mercado hundido: solo se ve la manija y un pedazo de la canasta
    for x in range(3, 20, 3):
        line(c, (x, 3), (x + 1, 11), (170, 172, 184))
    line(c, (2, 3), (21, 3), (190, 192, 204))
    line(c, (2, 6), (21, 6), (150, 152, 164))
    line(c, (19, 3), (23, 0), (190, 192, 204))
    rect(c, (21, 0, 23, 1), (206, 52, 58))
    for x in range(0, 24):
        px(c, x, 10, (120, 150, 170), 160)
    save(c, "carrito_hundido")
    for k, (w, h, col) in enumerate([(7, 3, (150, 200, 120)), (8, 5, (236, 236, 236)), (6, 4, (240, 240, 230))]):
        b = new(w + 2, h + 2)  # una botella, una bolsa, un icopor
        rect(b, (1, 1, w, h), col)
        if k == 0:
            rect(b, (w - 1, 1, w, 2), (220, 220, 220))
        save(outline(b), "flota_%d" % k)


# ================================================================ La plaza

def plaza():
    # El agua de la fuente: la taza con agua turbia (encima de fountain_dry, 40x24) y el chorrito.
    for k in range(3):
        f = new(40, 34)
        oy = 10
        ell(f, (7, oy + 7, 33, oy + 20), (70, 110, 120))
        for x in range(9, 32):
            if (x + k) % 5 == 0:
                px(f, x, oy + 12 + (x % 3), (130, 170, 176))
        ell(f, (16, oy + 3, 24, oy + 9), (150, 150, 156))  # la taza del medio, de piedra
        line(f, (20, oy + 3), (20, 2 + k), (180, 214, 230))  # el chorrito: sube y cae
        px(f, 19, 2 + k, (210, 230, 240))
        px(f, 21, 3 + k, (210, 230, 240))
        for i in range(4):
            px(f, 17 - i + k % 2, 4 + i * 2 + k, (170, 210, 230))
            px(f, 23 + i - k % 2, 4 + i * 2 + k, (170, 210, 230))
        save(f, "fuente_agua_%d" % k)
    # Las palomas: de pie, picoteando, caminando, volando (alas arriba y abajo).
    gray, dark, neck = (150, 150, 162), (110, 110, 122), (110, 150, 130)
    for k in range(5):
        p = new(10, 9)
        if k < 3:
            ell(p, (1, 3, 7, 8), gray)
            px(p, 0, 5, dark)
            px(p, 0, 6, dark)
            if k == 1:
                ell(p, (6, 5, 9, 8), gray)
                px(p, 9, 7, (200, 150, 120))
            else:
                ell(p, (5, 1, 8, 5), gray)
                px(p, 6, 4, neck)
                px(p, 9, 3, (200, 150, 120))
                px(p, 7, 2, INK)
            line(p, (3, 5), (5, 6), dark)
            px(p, 3, 8, (200, 120, 110))
            px(p, 5 if k != 2 else 6, 8, (200, 120, 110))
        else:
            ell(p, (2, 4, 7, 7), gray)
            px(p, 8, 4, gray)
            if k == 3:
                line(p, (2, 4), (0, 0), dark)
                line(p, (6, 4), (8, 0), dark)
            else:
                line(p, (2, 6), (0, 8), dark)
                line(p, (6, 6), (9, 8), dark)
        save(outline(p), "paloma_%d" % k)
    # La matera de ladrillo con flores.
    m = new(22, 16)
    rect(m, (1, 8, 20, 15), (160, 84, 60))
    for y in (10, 13):
        line(m, (1, y), (20, y), (130, 66, 48))
    for x in range(3, 20, 5):
        line(m, (x, 8), (x, 10), (130, 66, 48))
        line(m, (x + 2, 10), (x + 2, 13), (130, 66, 48))
    for i in range(14):
        x = 2 + i * 1.3
        line(m, (x, 8), (x + R.choice([-1, 1]), 8 - R.randrange(2, 6)), (78, 116, 52))
    for _ in range(8):
        px(m, R.randrange(2, 20), R.randrange(1, 6), R.choice([(214, 60, 70), (240, 140, 180), (240, 220, 90), (250, 250, 250)]))
    save(outline(m), "matera")
    # El busto del prócer: el pedestal, la placa, el bronce verdoso y la paloma en la cabeza.
    b = new(20, 38)
    rect(b, (3, 20, 16, 37), (170, 166, 156))
    line(b, (3, 20), (16, 20), (200, 196, 186))
    rect(b, (6, 26, 13, 31), (150, 120, 60))  # la placa
    for x in range(7, 13, 2):
        px(b, x, 28, (200, 170, 90))
    bronze, br_d = (96, 130, 110), (70, 100, 84)
    rect(b, (4, 14, 15, 19), bronze)  # los hombros
    ell(b, (6, 5, 13, 14), bronze)
    line(b, (12, 7), (12, 12), br_d)
    px(b, 8, 9, br_d)
    px(b, 11, 9, br_d)
    rect(b, (6, 5, 13, 7), br_d)
    for (x, y) in [(9, 2), (10, 2), (8, 3), (9, 3), (10, 3), (11, 3)]:  # la paloma
        px(b, x, y, (150, 150, 162))
    px(b, 12, 2, (200, 150, 120))
    for y in range(9, 19, 3):  # lo que le dejan las palomas
        px(b, 7 + y % 4, y, (230, 230, 224))
    save(outline(b), "busto")
    # El lustrabotas: arrodillado con la caja, cepillando (dos cuadros).
    for k in range(2):
        l = new(22, 22)
        rect(l, (2, 14, 13, 21), (110, 74, 46))  # la caja
        line(l, (2, 14), (13, 14), (150, 104, 66))
        rect(l, (5, 11, 9, 14), (40, 40, 44))  # el apoyapié
        rect(l, (14, 8, 19, 16), (70, 90, 130))  # él, agachado
        ell(l, (14, 2, 20, 8), SKIN)
        rect(l, (14, 1, 20, 3), (40, 34, 30))
        line(l, (14, 18), (19, 21), (60, 60, 70), 2)
        line(l, (15, 10), (9 + k * 2, 12 - k), SKIN)
        rect(l, (8 + k * 2, 11 - k, 10 + k * 2, 12 - k), (120, 70, 40))  # el cepillo
        save(outline(l), "lustrabotas_%d" % k)
    # El paletero: el carrito blanco de las paletas con su sombrilla y la campanita.
    p = new(24, 28)
    for i in range(6):
        a0, a1 = math.pi + i * math.pi / 6, math.pi + (i + 1) * math.pi / 6
        ImageDraw.Draw(p).polygon([(12, 1), (12 + 11 * math.cos(a0), 7 + 4 * math.sin(a0) + 4), (12 + 11 * math.cos(a1), 7 + 4 * math.sin(a1) + 4)],
                                  fill=((60, 140, 220) if i % 2 == 0 else (240, 240, 236)) + (255,))
    line(p, (12, 7), (12, 14), (180, 180, 186))
    rect(p, (3, 14, 21, 22), (240, 240, 236))
    line(p, (3, 14), (21, 14), (255, 255, 255))
    rect(p, (6, 16, 10, 19), (240, 130, 160))  # la paleta pintada
    rect(p, (13, 16, 18, 19), (120, 200, 240))
    for wx in (6, 18):
        ell(p, (wx - 3, 21, wx + 3, 27), (40, 38, 44))
    px(p, 22, 13, (236, 196, 58))  # la campanita
    save(outline(p), "paletero")


# ================================================================ El Centro y el Parque

def centro():
    # Lo de atrás del Centro: la otra fila de edificios (la ciudad sigue), con su valla y sus tanques.
    W, H = 640, 84
    f = new(W, H)
    rect(f, (0, 0, W - 1, H - 1), (92, 94, 110))  # la fila de más atrás, en la bruma
    for wy in range(3, 30, 6):
        for wx in range(2, W, 7):
            if R.random() < 0.35:
                px(f, wx, wy, (130, 128, 120) if R.random() < 0.7 else (200, 180, 120))
    x = 0
    k = 0
    walls = [(150, 140, 132), (124, 120, 128), (176, 160, 136), (110, 112, 120), (160, 120, 100), (138, 146, 150)]
    while x < W:
        w = R.choice([56, 64, 72, 88, 48])
        top = R.choice([0, 0, 6, 14, 20])
        col = walls[k % len(walls)]
        rect(f, (x, top, x + w - 1, H - 1), col)
        line(f, (x, top), (x + w - 1, top), mix(col, (255, 255, 255), 0.25))
        line(f, (x + w - 1, top), (x + w - 1, H - 1), mix(col, (0, 0, 0), 0.3))
        for wy in range(top + 6, H - 6, 12):  # ventanas: unas con luz, unas con ropa, unas tapadas con cartón
            for wx in range(x + 6, x + w - 8, 12):
                kind = R.random()
                win = (70, 84, 104) if kind < 0.6 else (230, 200, 120) if kind < 0.75 else (170, 134, 90)
                rect(f, (wx, wy, wx + 5, wy + 6), win)
                line(f, (wx, wy + 7), (wx + 5, wy + 7), mix(col, (0, 0, 0), 0.25))
                if kind > 0.92:  # ropa en la ventana
                    rect(f, (wx + 1, wy + 7, wx + 2, wy + 10), R.choice([(206, 60, 70), (60, 100, 160), (240, 220, 90)]))
        if top > 2:  # tanque o antena en la terraza
            if R.random() < 0.5:
                rect(f, (x + 8, top - 6, x + 16, top - 1), (40, 40, 46))
            else:
                line(f, (x + w // 2, top - 1), (x + w // 2, max(0, top - 10)), (60, 60, 66))
                line(f, (x + w // 2 - 3, max(0, top - 8)), (x + w // 2 + 3, max(0, top - 8)), (60, 60, 66))
        x += w
        k += 1
    # La valla del abogado: el negocio que más se mueve en el Centro.
    vx, vy = 300, 8
    rect(f, (vx, vy, vx + 96, vy + 28), (240, 236, 220))
    rect(f, (vx, vy, vx + 96, vy + 9), (30, 50, 110))
    for txt, ty, col in [("ABOGADO PENAL", 2, (255, 236, 150)), ("LO DENUNCIARON?", 12, (40, 40, 50)), ("LO SACAMOS", 19, (170, 40, 40))]:
        letters(f, txt, vx + 48 - letters_w(txt) // 2, vy + ty, col)
    for lx in (vx + 20, vx + 76):
        rect(f, (lx, vy + 29, lx + 2, vy + 40), (70, 70, 76))
    rect(f, (122, 52, 156, 60), (240, 236, 214))  # un SE ARRIENDA en una ventana
    letters(f, "ARRIENDA", 124, 54, (170, 40, 40))
    for xx in range(W):  # los cables, con palomas
        y = 70 + int(4 * math.sin(math.pi * (xx % 160) / 160))
        px(f, xx, y, (36, 30, 40))
        if xx % 37 == 5:
            rect(f, (xx, y - 3, xx + 2, y - 1), (90, 90, 100))
    rect(f, (0, H - 3, W - 1, H - 1), (80, 78, 86))
    save(f, "centro_fondo")
    # El tintero: carrito con los termos, los vasitos y la sombrilla (el vapor, en dos cuadros).
    for k in range(2):
        t = new(26, 32)
        for i in range(6):
            a0, a1 = math.pi + i * math.pi / 6, math.pi + (i + 1) * math.pi / 6
            ImageDraw.Draw(t).polygon([(13, 1), (13 + 12 * math.cos(a0), 11 + 4 * math.sin(a0)), (13 + 12 * math.cos(a1), 11 + 4 * math.sin(a1))],
                                      fill=((236, 196, 58) if i % 2 == 0 else (206, 52, 58)) + (255,))
        line(t, (13, 7), (13, 16), (180, 180, 186))
        rect(t, (3, 18, 22, 25), (150, 104, 66))
        for i, col in enumerate([(206, 52, 58), (60, 110, 200), (236, 236, 236)]):
            rect(t, (4 + i * 6, 12, 7 + i * 6, 18), col)
            rect(t, (5 + i * 6, 11, 6 + i * 6, 11), (40, 40, 44))
        for i in range(3):
            px(t, 6 + (i + k) % 2, 9 - i * 2, (220, 220, 226), 180 - i * 50)
        for wx in (6, 19):
            ell(t, (wx - 3, 25, wx + 3, 31), (40, 38, 44))
        save(outline(t), "tintero_%d" % k)
    # La dulcera: la caja de dulces en un banquito y la señora sentada con su sombrero.
    d = new(28, 26)
    rect(d, (2, 12, 17, 15), (110, 74, 46))
    for (x0, col) in [(3, (240, 80, 90)), (6, (240, 220, 90)), (9, (100, 180, 240)), (12, (120, 200, 120)), (15, (240, 150, 60))]:
        rect(d, (x0, 9, x0 + 1, 11), col)
    line(d, (3, 16), (3, 25), WOOD_D)
    line(d, (16, 16), (16, 25), WOOD_D)
    rect(d, (19, 12, 26, 21), (180, 90, 120))
    ell(d, (19, 5, 26, 12), SKIN)
    ell(d, (17, 3, 27, 7), (220, 200, 140))
    rect(d, (20, 2, 25, 5), (220, 200, 140))
    line(d, (20, 21), (20, 25), (60, 50, 60))
    line(d, (25, 21), (25, 25), (60, 50, 60))
    save(outline(d), "dulcera")


def parque():
    # La Olla Comunitaria: la carpa azul con el letrero pintado, el fogón de leña y la olla grande.
    for k in range(2):
        o = new(76, 52)
        blue, blue_d = (60, 100, 170), (44, 74, 130)
        ImageDraw.Draw(o).polygon([(4, 14), (38, 2), (72, 14)], fill=blue + (255,))
        rect(o, (4, 14, 72, 22), blue_d)
        for x in range(4, 72, 6):
            ImageDraw.Draw(o).polygon([(x, 22), (x + 6, 22), (x + 3, 25)], fill=blue_d + (255,))
        letters(o, "OLLA COMUNITARIA", 38 - letters_w("OLLA COMUNITARIA") // 2, 16, (250, 246, 230))
        for x in (5, 70):
            line(o, (x, 22), (x, 51), (170, 170, 176))
        rect(o, (8, 34, 34, 37), (236, 234, 226))
        line(o, (10, 38), (10, 46), (200, 200, 196))
        line(o, (32, 38), (32, 46), (200, 200, 196))
        for x in range(10, 22, 4):
            ell(o, (x, 32, x + 3, 34), (250, 250, 250))
        rect(o, (25, 30, 29, 33), (240, 140, 60))
        for (x0, y0) in [(44, 46), (54, 47), (64, 46)]:
            ell(o, (x0, y0, x0 + 6, y0 + 4), (120, 116, 110))
        for i in range(5):
            line(o, (46 + i * 4, 49), (50 + i * 3, 45), (110, 70, 40))
            px(o, 48 + i * 4, 46 - (i + k) % 2, (250, 160 + 40 * ((i + k) % 2), 50))
        ell(o, (44, 32, 70, 46), (40, 38, 44))
        ell(o, (46, 32, 68, 37), (180, 150, 70))
        line(o, (52, 33), (60, 27), (150, 110, 70), 2)
        for i in range(5):
            px(o, 54 + (i + k) % 3, 30 - i * 2, (230, 230, 236), 200 - i * 35)
            px(o, 61 - (i + k) % 3, 29 - i * 2, (230, 230, 236), 170 - i * 30)
        save(outline(o), "olla_%d" % k)
    # El gimnasio del parque (las máquinas verdes y amarillas) y el señor de sudadera dándole.
    for k in range(2):
        g = new(44, 32)
        grn, yel = (60, 150, 90), (236, 196, 58)
        line(g, (6, 31), (6, 8), grn, 2)
        line(g, (6, 8), (18, 8), grn, 2)
        line(g, (18, 8), (18, 31), grn, 2)
        rect(g, (8, 18, 16, 20), yel)
        rect(g, (26, 26, 42, 28), grn)
        line(g, (27, 28), (27, 31), grn)
        line(g, (41, 28), (41, 31), grn)
        line(g, (30, 26), (40, 20), yel, 2)
        rx = 10 + k
        rect(g, (rx, 9, rx + 4, 17), (200, 40, 50))
        ell(g, (rx, 2, rx + 4, 8), SKIN)
        rect(g, (rx, 1, rx + 4, 2), (220, 220, 220))
        line(g, (rx + 1, 17), (9 + k * 5, 28), (40, 50, 90))
        line(g, (rx + 3, 17), (15 - k * 5 + 2, 28), (40, 50, 90))
        line(g, (rx, 10), (7, 9), SKIN)
        line(g, (rx + 4, 10), (17, 9), SKIN)
        save(outline(g), "biosaludable_%d" % k)
    # La cometa (tres cuadros: el viento) y el pelado que la sostiene.
    for k in range(3):
        c = new(20, 26)
        sw = [-1, 0, 1][k]
        ImageDraw.Draw(c).polygon([(9 + sw, 0), (16 + sw, 6), (9 + sw, 13), (2 + sw, 6)], fill=(206, 52, 58, 255))
        ImageDraw.Draw(c).polygon([(9 + sw, 0), (16 + sw, 6), (9 + sw, 6)], fill=(236, 196, 58, 255))
        line(c, (9 + sw, 0), (9 + sw, 13), (110, 70, 40))
        line(c, (2 + sw, 6), (16 + sw, 6), (110, 70, 40))
        for i in range(12):
            px(c, 9 + sw + int(2 * math.sin(i * 0.9 + k)), 13 + i, (60, 110, 200) if i % 3 else (240, 240, 236))
        save(outline(c), "cometa_%d" % k)
    n = new(10, 20)
    rect(n, (2, 6, 7, 13), (64, 170, 92))
    ell(n, (2, 0, 7, 6), SKIN)
    rect(n, (2, 0, 7, 1), (40, 30, 30))
    line(n, (6, 7), (9, 2), SKIN)
    line(n, (3, 13), (3, 19), (60, 60, 80))
    line(n, (6, 13), (6, 19), (60, 60, 80))
    save(outline(n), "nino_cometa")
    # El laguito: agua verde, orilla de barro, juncos; los patos van aparte (nadan).
    l = new(96, 38)
    ell(l, (0, 2, 95, 37), (110, 92, 66))
    ell(l, (4, 5, 91, 34), (70, 110, 100))
    ell(l, (10, 9, 70, 28), (82, 124, 112))
    for i in range(14):
        x = R.randrange(10, 86)
        y = R.randrange(10, 30)
        line(l, (x, y), (x + R.randrange(3, 7), y), (130, 170, 160))
    for (x, y) in [(6, 18), (88, 14), (80, 30), (14, 30)]:
        for i in range(5):
            line(l, (x + i, y + 4), (x + i + R.choice([-1, 1]), y - R.randrange(2, 7)), (96, 130, 70))
    rect(l, (60, 24, 66, 26), (240, 240, 236))  # un icopor: es parque de ciudad
    save(l, "laguito")
    for k in range(2):
        d = new(12, 9)
        ell(d, (1, 3, 9, 8), (240, 240, 232))
        ell(d, (6, 0, 10, 4), (60, 120, 80) if k == 0 else (240, 240, 232))
        px(d, 11, 2, (236, 160, 50))
        px(d, 8, 1, INK)
        line(d, (2, 7), (8, 7), (150, 190, 190))
        save(outline(d), "pato_%d" % k)


def main():
    for f in (lote, potrero, casas, puestos, rio, plaza, centro, parque):
        f()
    print("relleno:", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
