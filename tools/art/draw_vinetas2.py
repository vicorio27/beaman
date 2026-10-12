"""Las viñetas grandes de la noche (python tools/art/draw_vinetas2.py, desde la carpeta del proyecto).

Cada momento de texto sobre negro de NightSequence tiene su cuadro: cómo quedaron dormidos, dónde, con
qué les llega la noche. Son incómodos a propósito: nadie duerme bien en ninguno. Cuatro cuadros por
viñeta (se pasan despacio: respiran, gotea, llueve, titila el bombillo).
  dormir_banco / kiosco / rio / callejon / parque / pension   (y _solo: la misma noche, sin Lukas)
  sueno          se queda dormido: lo que sueña le sale de la cabeza, en neón
  intruso        alguien revolviendo la caja del cambuche
  lukas_pecho    la noche en que Lukas se le acuesta en el pecho      lukas_quieto   antes de que aclare
  entierro       el árbol de flores amarillas                         collar         el collar, en la mochila
  final          el último amanecer: Samuel lo encuentra
Salida: assets/ui/vineta_<id>_<0..3>.png (240x100). Mismo estilo de draw_vinetas.py: degradados
tramados (Bayer), luz de lado, siluetas con un borde de luz. Él no tiene cara. Un zapato de cada color.
"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
from draw_vinetas import gradient, glow, cone, to_img, frame, BAYER, W, H  # noqa: E402

OUT = "assets/ui/"
FRAMES = 4

COAT, COAT_DK, HAIR = (52, 46, 64), (36, 32, 46), (22, 18, 24)
SKIN, TIE, PANTS = (196, 148, 118), (190, 50, 56), (40, 44, 62)
SHOE_A, SHOE_B = (132, 90, 52), (64, 98, 140)   # un zapato de cada color
TAN, EAR, BLACK, WHITE = (176, 108, 56), (126, 72, 40), (28, 24, 28), (236, 228, 214)
PACK = (70, 84, 60)


def dim(c, k):
    return tuple(int(v * k) for v in c)


def mix(c1, c2, k):
    return tuple(int(a * (1 - k) + b * k) for a, b in zip(c1, c2))


# ------------------------------------------------------------------ él

def man_side(d, x, y, b, rim, shade=1.0, hand_out=False):
    """Dormido de lado, encogido, de frente a nosotros, la cabeza a la izquierda. (x, y): el piso bajo la cadera."""
    coat, dk, pants = dim(COAT, shade), dim(COAT_DK, shade), dim(PANTS, shade)
    # Las piernas, dobladas, una sobre otra; los zapatos, distintos.
    d.polygon([(x + 2, y - 13), (x + 22, y - 17), (x + 26, y - 9), (x + 6, y)], fill=pants)
    d.polygon([(x + 20, y - 16), (x + 38, y - 6), (x + 34, y), (x + 18, y - 8)], fill=dim(pants, 0.85))
    d.rectangle([x + 34, y - 7, x + 42, y - 3], fill=dim(SHOE_A, shade))
    d.rectangle([x + 31, y - 3, x + 40, y], fill=dim(SHOE_B, shade))
    # El saco, que le queda grande: sube y baja con la respiración.
    d.polygon([(x - 30, y - 15 - b), (x - 12, y - 19 - b), (x + 6, y - 15), (x + 8, y), (x - 30, y)], fill=coat)
    d.polygon([(x - 30, y - 5), (x + 8, y - 4), (x + 8, y), (x - 30, y)], fill=dk)
    # El brazo doblado debajo de la cabeza (la almohada es el brazo) y el otro, cruzado.
    d.line([(x - 24, y - 12 - b), (x - 10, y - 6), (x - 22, y - 3)], fill=dk, width=4)
    d.rectangle([x - 25, y - 5, x - 22, y - 2], fill=dim(SKIN, shade))
    if hand_out:
        d.line([(x - 26, y - 4), (x - 38, y - 1)], fill=dk, width=3)
        d.rectangle([x - 42, y - 3, x - 38, y], fill=dim(SKIN, shade))
    # La cabeza: pelo, barba, un pedazo de frente. Sin cara.
    d.ellipse([x - 43, y - 15, x - 29, y - 2], fill=dim(HAIR, max(0.8, shade)))
    d.rectangle([x - 39, y - 10, x - 35, y - 7], fill=dim(SKIN, shade))
    d.line([(x - 29, y - 9), (x - 27, y - 3)], fill=dim(TIE, shade), width=2)   # la corbata, floja
    # El borde de luz.
    d.line([(x - 41, y - 14), (x - 31, y - 16), (x - 12, y - 20 - b), (x + 6, y - 16), (x + 22, y - 18), (x + 38, y - 7)], fill=rim)


def man_back(d, x, y, b, rim, shade=1.0, hands=True):
    """Boca arriba, tieso, la cabeza a la izquierda. (x, y): el piso (o el colchón) bajo la cadera."""
    coat, dk, pants = dim(COAT, shade), dim(COAT_DK, shade), dim(PANTS, shade)
    d.polygon([(x + 4, y - 9), (x + 36, y - 8), (x + 36, y), (x + 4, y)], fill=pants)
    d.rectangle([x + 36, y - 13, x + 40, y], fill=dim(SHOE_A, shade))          # los zapatos, parados
    d.rectangle([x + 31, y - 11, x + 35, y - 7], fill=dim(SHOE_B, shade))
    d.polygon([(x - 30, y - 10), (x - 14, y - 13 - b), (x + 6, y - 11 - b), (x + 6, y), (x - 30, y)], fill=coat)
    d.polygon([(x - 30, y - 4), (x + 6, y - 4), (x + 6, y), (x - 30, y)], fill=dk)
    if hands:
        d.line([(x - 22, y - 6), (x - 8, y - 13 - b)], fill=dk, width=3)        # las manos en el pecho
        d.rectangle([x - 9, y - 15 - b, x - 5, y - 12 - b], fill=dim(SKIN, shade))
    d.ellipse([x - 44, y - 13, x - 30, y - 1], fill=dim(HAIR, max(0.8, shade)))
    d.rectangle([x - 40, y - 12, x - 35, y - 9], fill=dim(SKIN, shade))
    d.line([(x - 30, y - 8), (x - 26, y - 11 - b)], fill=dim(TIE, shade), width=2)
    d.line([(x - 42, y - 12), (x - 32, y - 14), (x - 14, y - 14 - b), (x + 6, y - 12 - b), (x + 36, y - 9)], fill=rim)


def man_sit(d, x, y, b, rim, shade=1.0, flip=False, head_down=True):
    """Sentado, las rodillas arriba, los brazos sobre las rodillas y la cabeza en los brazos. (x, y): el piso, bajo la cola."""
    s = -1 if flip else 1
    coat, dk, pants = dim(COAT, shade), dim(COAT_DK, shade), dim(PANTS, shade)

    def P(pts):
        return [(x + s * px, y + py) for px, py in pts]
    d.polygon(P([(-6, 0), (-8, -30 - b), (8, -33 - b), (12, -8), (10, 0)]), fill=coat)             # la espalda, el saco
    d.polygon(P([(6, -6), (24, -22), (30, -17), (16, 0)]), fill=pants)                             # el muslo
    d.polygon(P([(24, -22), (30, -17), (30, -2), (24, 0), (22, -6)]), fill=dim(pants, 0.85))      # la pierna
    d.rectangle(sorted([x + s * 22, x + s * 34])[:1] + [y - 4] + sorted([x + s * 22, x + s * 34])[1:] + [y], fill=dim(SHOE_A, shade))
    d.line(P([(4, -27 - b), (22, -24)]), fill=dk, width=5)                                         # los brazos, cruzados sobre las rodillas
    d.rectangle(sorted([x + s * 22, x + s * 26])[:1] + [y - 26] + sorted([x + s * 22, x + s * 26])[1:] + [y - 23], fill=dim(SKIN, shade))
    hx, hy = (x + s * 14, y - 33 - b) if head_down else (x + s * 2, y - 40 - b)
    d.ellipse([hx - 7, hy - 7, hx + 7, hy + 6], fill=dim(HAIR, max(0.8, shade)))
    if not head_down:
        d.rectangle([hx + s * 2 - 1, hy - 2, hx + s * 2 + 2, hy + 1], fill=dim(SKIN, shade))
    d.line(P([(8, -30 - b), (10, -20)]), fill=dim(TIE, shade), width=2)
    d.line(P([(-9, -1), (-9, -30 - b), (0, -35 - b)]), fill=rim)                                   # el borde de luz, en la espalda


# ------------------------------------------------------------------ Lukas

def lukas_curled(d, x, y, b, rim, shade=1.0):
    """Hecho un ovillo, la cabeza a la izquierda, sobre las patas. (x, y): el piso, a la izquierda."""
    tan, ear, black, white = dim(TAN, shade), dim(EAR, shade), dim(BLACK, shade), dim(WHITE, shade)
    d.ellipse([x + 4, y - 13 - b, x + 30, y], fill=tan)
    d.ellipse([x + 9, y - 14 - b, x + 26, y - 5], fill=black)                # la montura
    d.ellipse([x + 20, y - 7, x + 31, y], fill=white)                         # la cola enroscada, punta blanca
    d.ellipse([x + 21, y - 6, x + 28, y], fill=tan)
    d.ellipse([x - 3, y - 10, x + 9, y], fill=tan)                            # la cabeza
    d.polygon([(x + 1, y - 10), (x + 3, y - 10), (x + 2, y - 3)], fill=white)  # la franja
    d.ellipse([x - 6, y - 6, x + 1, y], fill=white)                           # el hocico
    d.rectangle([x - 6, y - 4, x - 5, y - 3], fill=black)                     # la nariz
    d.ellipse([x + 4, y - 11, x + 10, y - 1], fill=ear)                       # la oreja, caída
    d.arc([x + 4, y - 14 - b, x + 30, y + 6], 200, 340, fill=rim)


def lukas_down(d, x, y, b, rim, shade=1.0, ear_up=False, flip=False, head_up=True):
    """Echado como una esfinge, la cabeza arriba (de guardia). (x, y): el piso, donde van las patas de adelante."""
    s = -1 if flip else 1
    tan, ear, black, white = dim(TAN, shade), dim(EAR, shade), dim(BLACK, shade), dim(WHITE, shade)

    def R(x0, y0, x1, y1, fill):
        d.rectangle([min(x + s * x0, x + s * x1), y + y0, max(x + s * x0, x + s * x1), y + y1], fill=fill)

    def E(x0, y0, x1, y1, fill):
        d.ellipse([min(x + s * x0, x + s * x1), y + y0, max(x + s * x0, x + s * x1), y + y1], fill=fill)
    E(4, -11 - b, 32, 0, tan)
    E(10, -12 - b, 28, -4, black)
    R(-4, -3, 8, 0, white)                                                    # las patas de adelante
    d.line([(x + s * 31, y - 6), (x + s * 37, y - 10)], fill=tan, width=2)    # la cola
    d.point((x + s * 38, y - 11), fill=white)
    hy = -16 if head_up else -8
    E(-4, hy - 4, 8, hy + 7, tan)
    R(-8, hy + 1, -1, hy + 6, white)
    R(-9, hy + 1, -8, hy + 2, black)
    d.polygon([(x + s * 1, y + hy - 3), (x + s * 3, y + hy - 3), (x + s * 2, y + hy + 3)], fill=white)
    R(-2, hy, -1, hy + 1, black)                                              # el ojo
    if ear_up:
        d.polygon([(x + s * 4, y + hy - 3), (x + s * 9, y + hy - 11), (x + s * 9, y + hy - 1)], fill=ear)
    else:
        E(4, hy - 3, 10, hy + 9, ear)
    R(3, -5, 9, 0, white)                                                     # el pecho
    d.line([(x + s * 6, y - 12 - b), (x + s * 30, y - 11 - b)], fill=rim)


# ------------------------------------------------------------------ el clima

def rain(a, f, n=120, color=(120, 130, 160), seed=3, box=None, lit=None):
    rng = np.random.default_rng(seed)
    x0, y0, x1, y1 = box or (0, 0, W, H)
    for _ in range(n):
        x, y = int(rng.integers(x0, x1)), int(rng.integers(y0 - 20, y1))
        y += f * 7
        for k in range(4):
            yy, xx = y + k * 2, x - k
            if y0 <= yy < y1 and x0 <= xx < x1:
                a[yy, xx] = lit(xx, yy) if lit and lit(xx, yy) else color


def stars(a, pts, f):
    for i, (sx, sy) in enumerate(pts):
        if (i + f) % 5 != 0:
            a[sy, sx] = (216, 212, 236)


def save(name, fn):
    for f in range(FRAMES):
        frame(fn(f)).save(OUT + "vineta_%s_%d.png" % (name, f))
    print(name)


def breath(f):
    return 1 if f in (1, 2) else 0


# ------------------------------------------------------------------ dormir

def banco(solo):
    def scene(f):
        a = np.zeros((H, W, 3), np.uint8)
        gradient(a, (0, 0, W, 60), [(14, 14, 34), (24, 24, 54), (40, 36, 72)], ease=1.2)
        gradient(a, (0, 60, W, H), [(46, 42, 58), (34, 30, 44), (22, 20, 30)])
        stars(a, [(20, 6), (52, 14), (90, 5), (150, 10), (226, 8), (120, 20)], f)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        # La pared de atrás: una persiana cerrada, un aviso, una ventana prendida, lejos.
        d.rectangle([0, 24, 150, 62], fill=(30, 26, 40))
        for yy in range(28, 60, 4):
            d.line([(8, yy), (70, yy)], fill=(40, 36, 52))
        d.rectangle([84, 30, 96, 42], fill=(236, 200, 120) if f != 2 else (200, 170, 100))
        d.line([(90, 30), (90, 42)], fill=(30, 26, 40))
        d.rectangle([0, 62, W, 63], fill=(60, 54, 72))
        # El farol.
        d.rectangle([204, 10, 206, 86], fill=(26, 24, 32))
        d.rectangle([196, 8, 208, 11], fill=(26, 24, 32))
        a = np.array(img.convert("RGB"))
        cone(a, (198, 12), (120, 94), (236, 94), (255, 200, 120), 0.6 if f != 3 else 0.5)
        glow(a, 198, 12, 9, (255, 226, 160), 0.9)
        for i, (mx, my) in enumerate([(190, 20), (204, 16), (196, 26)]):      # las polillas
            a[my + (f + i) % 3, mx + (f * 2 + i) % 4] = (255, 240, 200)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        # El banco de la plaza: listones, patas de hierro.
        for yy in (50, 55, 60):
            d.rectangle([84, yy, 168, yy + 3], fill=(92, 66, 44))
            d.line([(84, yy), (168, yy)], fill=(150, 112, 70))
        d.rectangle([82, 66, 170, 70], fill=(104, 74, 48))
        d.line([(82, 66), (170, 66)], fill=(190, 140, 86))
        for lx in (88, 162):
            d.rectangle([lx, 46, lx + 2, 86], fill=(28, 26, 34))
        rim = (230, 180, 110)
        b = breath(f)
        # Él: sentado derecho no se puede dormir, así que se le fue la cabeza para atrás. La mochila, abrazada.
        if not solo:  # Lukas abajo, de guardia: la cabeza arriba, mirando para la calle
            lukas_down(d, 92, 86, 0, rim, 0.8, ear_up=(f == 3))
        d.polygon([(126, 68), (132, 68), (132, 86), (126, 86)], fill=dim(PANTS, 0.8))                           # la pierna de atrás
        d.rectangle([126, 84, 136, 87], fill=SHOE_B)
        d.polygon([(100, 66), (98, 42 - b), (112, 40 - b), (118, 66)], fill=COAT)                              # el saco
        d.polygon([(112, 60), (142, 60), (142, 68), (112, 68)], fill=PANTS)                                    # los muslos
        d.polygon([(134, 66), (142, 66), (142, 86), (134, 86)], fill=PANTS)
        d.rectangle([134, 84, 146, 87], fill=SHOE_A)
        d.rectangle([108, 46 - b, 126, 60], fill=PACK)                                                          # la mochila
        d.line([(108, 46 - b), (126, 46 - b)], fill=mix(PACK, rim, 0.6))
        d.rectangle([113, 51 - b, 121, 56 - b], fill=dim(PACK, 0.7))
        d.line([(102, 48 - b), (118, 53 - b), (127, 50 - b)], fill=COAT_DK, width=4)                            # los brazos, encima
        d.rectangle([126, 48 - b, 129, 51 - b], fill=SKIN)
        d.ellipse([94, 27 - b, 109, 41 - b], fill=HAIR)                                                         # la cabeza, para atrás, contra el espaldar
        d.rectangle([104, 30 - b, 108, 33 - b], fill=SKIN)
        d.line([(107, 41 - b), (109, 46 - b)], fill=TIE, width=2)
        d.line([(108, 29 - b), (110, 36 - b)], fill=rim)
        d.line([(142, 60), (142, 84)], fill=rim)
        if f in (1, 2):                                                                                         # el vaho: hace frío
            d.point((112 + f, 26 - f * 2), fill=(170, 170, 190))
            d.point((114 + f, 23 - f * 2), fill=(120, 120, 140))
        d.polygon([(30, 90), (44, 88), (46, 92), (32, 94)], fill=(150, 144, 130))                               # un periódico
        return img
    return scene


def kiosco(solo):
    def scene(f):
        a = np.zeros((H, W, 3), np.uint8)
        gradient(a, (0, 0, W, 70), [(26, 22, 30), (36, 30, 38), (46, 38, 44)])
        gradient(a, (0, 70, W, H), [(52, 44, 46), (38, 32, 36), (26, 22, 28)])
        img = to_img(a)
        d = ImageDraw.Draw(img)
        # Las tablas del kiosco, con rendijas por donde se ve la noche; el techo, con un hueco.
        for x in range(0, W, 14):
            d.rectangle([x, 8, x + 12, 70], fill=(48 + (x * 7) % 9, 38 + (x * 5) % 7, 36))
            d.line([(x + 13, 8), (x + 13, 70)], fill=(30, 40, 74))
        d.rectangle([0, 0, W, 8], fill=(22, 18, 24))
        d.polygon([(52, 0), (70, 0), (66, 8), (56, 8)], fill=(40, 52, 96))                    # el hueco
        d.rectangle([0, 70, W, 71], fill=(70, 58, 56))
        d.rectangle([150, 26, 176, 40], fill=(70, 60, 50))                                    # un aviso viejo: "FIADO NO"
        for yy in (30, 35):
            d.line([(154, yy), (172, yy)], fill=(110, 96, 78))
        a = np.array(img.convert("RGB"))
        cone(a, (61, 4), (30, 96), (96, 96), (120, 140, 200), 0.4)                            # la luz fría que entra por el hueco
        # La gotera: tres gotas en fila, la lata, el charco que crece.
        for i in range(3):
            gy = 10 + ((f * 16 + i * 22) % 64)
            a[gy:gy + 3, 61] = (190, 204, 240)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        d.ellipse([28, 84, 100, 97], fill=(44, 52, 78))                                       # el charco
        d.arc([44 - f * 3, 86 - f, 78 + f * 3, 95 + f], 0, 360, fill=(110, 128, 180))         # la onda
        d.rectangle([56, 78, 66, 88], fill=(120, 124, 132))                                   # la lata, llena
        d.line([(56, 78), (66, 78)], fill=(200, 206, 220))
        d.point((61, 77 - (f % 2)), fill=(200, 214, 250))
        rim = (130, 146, 200)
        b = breath(f)
        # Él, en la esquina seca, de espaldas a la gotera (y a nosotros no: se le ve el saco subido hasta las orejas).
        d.polygon([(126, 88), (200, 88), (204, 93), (122, 93)], fill=(112, 86, 58))            # el cartón
        man_side(d, 170, 88, b, rim, 0.92)
        d.polygon([(140, 73 - b), (158, 69 - b), (160, 74 - b), (142, 78 - b)], fill=COAT_DK)  # el cuello del saco, subido
        if not solo:  # Lukas pegado a la espalda... que es lo que tenemos de frente: el lomo de Lukas
            lukas_curled(d, 150, 92, b, rim, 0.95)
        return img
    return scene


def rio(solo):
    def scene(f):
        a = np.zeros((H, W, 3), np.uint8)
        gradient(a, (0, 0, W, 54), [(12, 14, 34), (20, 24, 52), (34, 38, 74)], ease=1.1)
        gradient(a, (0, 54, W, 68), [(30, 38, 70), (22, 28, 52)])
        gradient(a, (0, 68, W, H), [(44, 38, 46), (32, 28, 36), (22, 20, 28)])
        stars(a, [(60, 30), (96, 22), (130, 34), (160, 26), (190, 36), (112, 40)], f)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        for bx, bw, bh in [(40, 12, 12), (56, 8, 20), (70, 14, 10), (150, 10, 16), (166, 16, 22), (188, 10, 12)]:
            d.rectangle([bx, 54 - bh, bx + bw, 54], fill=(40, 36, 64))
            for wy in range(54 - bh + 3, 52, 4):
                if (bx + wy + f) % 4 != 0:
                    d.point((bx + 2 + (wy % 5), wy), fill=(240, 200, 120))
        d.ellipse([196, 14, 210, 28], fill=(226, 226, 210))                                    # la luna
        d.ellipse([200, 12, 214, 26], fill=(20, 24, 52))
        a = np.array(img.convert("RGB"))
        for y in range(56, 68, 2):                                                             # la luna en el río, que corre
            for x in range(190 - (68 - y), 216 + (68 - y), 3):
                if (x + y + f * 3) % 7 < 3 and 0 <= x < W:
                    a[y, x] = (170, 176, 190)
        for y in range(0, 62):                                                                 # el puente, encima: el arco
            for x in range(W):
                if ((x - 124) / 132.0) ** 2 + ((y - 66) / 54.0) ** 2 >= 1.0:
                    a[y, x] = (18, 16, 26) if ((x - 124) / 138.0) ** 2 + ((y - 66) / 59.0) ** 2 > 1.0 else (44, 40, 60)
        for x in range(0, W):                                                                  # la neblina del río, que se arrastra
            for y in range(62, 72):
                if BAYER[y % 4, (x + f * 2) % 4] < 0.18 + 0.1 * np.sin((x + f * 9) / 17.0):
                    a[y, x] = (86, 92, 120)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        rim = (150, 160, 200)
        b = breath(f)
        # El cambuche: tres cartones, un plástico azul amarrado con cabuya, una piedra encima para que no se vuele.
        d.polygon([(52, 90), (60, 58), (150, 54), (164, 90)], fill=(96, 74, 52))
        d.polygon([(60, 58), (150, 54), (146, 62), (64, 66)], fill=(60, 92, 150))
        d.line([(60, 58), (150, 54)], fill=(120, 150, 210))
        d.polygon([(72, 90), (78, 68), (140, 66), (148, 90)], fill=(20, 18, 24))                 # adentro, oscuro
        d.ellipse([100 + (f % 2), 50, 110 + (f % 2), 56], fill=(90, 88, 96))                     # la piedra
        d.line([(150, 54), (170, 90)], fill=(170, 150, 110))                                    # la cabuya
        man_side(d, 122, 90, b, rim, 0.8)
        d.polygon([(72, 90), (78, 68), (96, 67), (92, 90)], fill=(20, 18, 24))                   # la cabeza queda adentro, en lo oscuro
        d.polygon([(52, 90), (60, 58), (80, 57), (74, 90)], fill=(96, 74, 52))
        d.line([(60, 58), (53, 90)], fill=(150, 118, 80))
        if not solo:  # Lukas, encima de los pies (los zapatos ni se ven)
            lukas_curled(d, 150, 91, b, rim, 0.95)
        else:         # los pies solos, afuera, con frío
            d.rectangle([156, 84, 166, 88], fill=SHOE_A)
            d.rectangle([153, 88, 163, 91], fill=SHOE_B)
        d.rectangle([182, 82, 190, 91], fill=(110, 112, 120))                                   # la olla
        d.line([(182, 82), (190, 82)], fill=(190, 194, 206))
        return img
    return scene


def callejon(solo):
    def scene(f):
        a = np.zeros((H, W, 3), np.uint8)
        gradient(a, (0, 0, W, H), [(16, 14, 22), (26, 22, 30), (34, 28, 34)])
        img = to_img(a)
        d = ImageDraw.Draw(img)
        # Dos paredes de ladrillo que se cierran al fondo; allá, un bombillo.
        d.polygon([(0, 0), (96, 0), (112, 70), (0, 96)], fill=(44, 30, 32))
        d.polygon([(W, 0), (150, 0), (132, 70), (W, 96)], fill=(36, 26, 30))
        for k in range(12):
            y0 = 6 + k * 7
            d.line([(0, y0 + k), (100 + k, y0 * 0.62 + 8)], fill=(30, 20, 24))
            d.line([(W, y0 + k), (146 - k, y0 * 0.62 + 8)], fill=(26, 18, 22))
        d.polygon([(112, 70), (132, 70), (W, 96), (W, H), (0, H), (0, 96)], fill=(28, 26, 32))   # el piso
        d.rectangle([112, 20, 132, 70], fill=(20, 22, 40))                                      # el fondo: la calle
        on = f != 2
        d.rectangle([121, 14, 123, 18], fill=(255, 230, 160) if on else (90, 80, 60))            # el bombillo, que titila
        d.line([(60, 4), (122, 14), (190, 6)], fill=(14, 12, 16))                                # los cables
        a = np.array(img.convert("RGB"))
        if on:
            cone(a, (122, 18), (86, 96), (160, 96), (255, 210, 140), 0.38)
            glow(a, 122, 16, 8, (255, 230, 170), 0.9)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        # El contenedor y las bolsas.
        d.rectangle([154, 52, 214, 88], fill=(40, 62, 56))
        d.rectangle([150, 48, 218, 54], fill=(52, 78, 70))
        d.line([(150, 48), (218, 48)], fill=(90, 120, 110))
        d.text((166, 62), "NO", fill=(30, 46, 42))
        for bx, by, r in [(28, 92, 13), (46, 96, 10), (206, 96, 11), (228, 94, 12)]:
            d.ellipse([bx - r, by - r, bx + r, by + r * 0.6], fill=(16, 16, 20))
            d.line([(bx - 2, by - r), (bx + 2, by - r - 4)], fill=(16, 16, 20), width=2)
            d.arc([bx - r, by - r, bx + r, by + r * 0.6], 200, 300, fill=(70, 70, 84))
        if f in (0, 1):                                                                           # la rata: dos ojos, a ratos
            d.point((176, 91), fill=(230, 60, 60))
            d.point((179, 91), fill=(230, 60, 60))
        rim = (220, 176, 120) if on else (90, 84, 96)
        b = breath(f)
        d.polygon([(64, 94), (112, 94), (114, 98), (62, 98)], fill=(104, 80, 54))                 # el cartón
        man_sit(d, 78, 94, b, rim, 0.9)
        if not solo:  # Lukas, con una oreja parada
            lukas_down(d, 118, 96, 0, rim, 0.9, ear_up=True, head_up=(f != 1))
        return img
    return scene


def parque(solo):
    def scene(f):
        a = np.zeros((H, W, 3), np.uint8)
        gradient(a, (0, 0, W, 66), [(14, 18, 40), (24, 30, 60), (44, 48, 84)], ease=1.1)
        gradient(a, (0, 66, W, H), [(30, 46, 40), (22, 34, 32), (14, 22, 24)])
        stars(a, [(100, 8), (130, 18), (170, 6), (200, 16), (226, 30), (150, 30), (84, 22)], f)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        sway = [0, 2, 3, 1][f]
        # El árbol: el tronco y la copa. (Solo: tiene flores amarillas, y abajo hay tierra removida.)
        d.polygon([(34, 88), (40, 40), (50, 40), (54, 88)], fill=(30, 24, 26))
        for cx, cy, r in [(44, 26, 22), (22, 36, 16), (66, 34, 17), (46, 12, 14)]:
            d.ellipse([cx - r + sway // 2, cy - r, cx + r + sway // 2, cy + r], fill=(22, 36, 34))
        if solo:
            rng = np.random.default_rng(4)
            for cx, cy, r in [(44, 26, 22), (22, 36, 16), (66, 34, 17), (46, 12, 14)]:
                for _ in range(12):
                    ang, rr = rng.uniform(0, 6.28), rng.uniform(0, r - 2)
                    d.point((int(cx + np.cos(ang) * rr) + sway // 2, int(cy + np.sin(ang) * rr)), fill=(240, 204, 70))
            d.ellipse([58, 84, 86, 92], fill=(54, 42, 34))                                        # la tierra
            d.point((72 + f % 2, 82), fill=(210, 50, 60))                                         # el clavel
            d.line([(72, 83), (72, 86)], fill=(40, 90, 50))
        # Los columpios, que crujen solos.
        d.line([(170, 28), (182, 88)], fill=(60, 58, 70), width=2)
        d.line([(226, 28), (214, 88)], fill=(60, 58, 70), width=2)
        d.rectangle([168, 26, 228, 29], fill=(70, 68, 82))
        for i, sx in enumerate((186, 208)):
            off = sway * (1 if i == 0 else -1)
            d.line([(sx, 29), (sx + off, 70)], fill=(90, 88, 100))
            d.line([(sx + 8, 29), (sx + 8 + off, 70)], fill=(90, 88, 100))
            d.rectangle([sx - 1 + off, 70, sx + 9 + off, 72], fill=(120, 60, 50))
        for i in range(40):                                                                       # el pasto, acostado por el viento
            gx, gy = (i * 53) % W, 70 + (i * 17) % 28
            d.line([(gx, gy), (gx + 1 + sway // 2, gy - 3)], fill=(40, 62, 50))
        for i in range(4):                                                                        # hojas que pasan
            lx, ly = (30 + i * 60 + f * 22) % W, 50 + (i * 13 + f * 5) % 30
            d.point((lx, ly), fill=(150, 130, 60))
        rim = (130, 146, 200)
        b = breath(f)
        # Él, boca arriba en el pasto, la mochila de almohada, un brazo sobre los ojos.
        d.rectangle([80, 78, 94, 88], fill=PACK)
        man_back(d, 126, 88, b, rim, 0.9, hands=False)
        d.line([(102, 80), (90, 76), (84, 80)], fill=COAT_DK, width=4)                            # el brazo, tapándose
        if not solo:  # Lukas, con la cabeza encima de la barriga de él
            lukas_down(d, 128, 78 - b, 0, rim, 0.95, head_up=False)
        return img
    return scene


def pension(solo):
    def scene(f):
        a = np.zeros((H, W, 3), np.uint8)
        gradient(a, (0, 0, W, 72), [(52, 44, 50), (60, 50, 54), (66, 54, 56)], horizontal=True)
        gradient(a, (0, 72, W, H), [(46, 36, 34), (34, 28, 28), (24, 20, 22)])
        img = to_img(a)
        d = ImageDraw.Draw(img)
        # La pared: una mancha de humedad con forma de país, un clavo sin cuadro, la ventana con el aviso de afuera.
        d.ellipse([30, 14, 62, 34], fill=(46, 40, 44))
        d.ellipse([44, 24, 76, 44], fill=(46, 40, 44))
        d.point((120, 22), fill=(20, 18, 20))
        d.rectangle([180, 14, 226, 52], fill=(20, 18, 34))
        neon = [(255, 70, 140), (255, 70, 140), (120, 40, 80), (255, 70, 140)][f]
        d.rectangle([186, 20, 220, 30], outline=neon)
        d.text((190, 20), "HOTEL", fill=neon)
        d.line([(203, 14), (203, 52)], fill=(66, 54, 56))
        d.rectangle([178, 12, 228, 14], fill=(80, 64, 60))
        d.rectangle([178, 52, 228, 54], fill=(80, 64, 60))
        d.line([(100, 0), (100, 12)], fill=(20, 18, 20))                                           # el bombillo, apagado
        d.ellipse([97, 12, 103, 19], fill=(90, 86, 80))
        d.rectangle([0, 72, W, 73], fill=(84, 66, 60))
        a = np.array(img.convert("RGB"))
        cone(a, (203, 34), (60, 98), (236, 98), neon, 0.3)                                         # el neón entra y le cae encima
        img = to_img(a)
        d = ImageDraw.Draw(img)
        # La cama: catre de hierro, colchón flaco, la sábana sin destender (se acostó encima, con zapatos).
        d.rectangle([62, 44, 65, 90], fill=(30, 28, 34))
        d.rectangle([174, 56, 177, 90], fill=(30, 28, 34))
        d.rectangle([62, 44, 80, 46], fill=(30, 28, 34))
        d.rectangle([64, 66, 176, 76], fill=(186, 176, 160))
        d.line([(64, 66), (176, 66)], fill=(236, 226, 206))
        d.rectangle([64, 76, 176, 79], fill=(120, 112, 104))
        d.rectangle([66, 60, 92, 67], fill=(210, 204, 190))                                        # la almohada: no la usa
        rim = mix((200, 190, 180), neon, 0.5)
        b = breath(f)
        man_back(d, 126, 66, b, rim, 0.95)
        if not solo:  # Lukas debajo, sin respirar: no se admiten perros
            d.rectangle([66, 80, 174, 90], fill=(14, 12, 16))
            lukas_down(d, 104, 91, 0, (60, 54, 60), 0.45, head_up=False)
            if f != 2:
                d.point((103, 84), fill=(255, 255, 255))                                           # el ojo, abierto
        else:
            d.rectangle([66, 80, 174, 90], fill=(14, 12, 16))
        d.rectangle([186, 70, 204, 90], fill=(60, 44, 36))                                         # la mesa de noche
        d.rectangle([190, 62, 200, 70], fill=PACK)                                                 # la mochila, donde la pueda ver
        return img
    return scene


# ------------------------------------------------------------------ los otros momentos

def sueno(f):
    a = np.zeros((H, W, 3), np.uint8)
    gradient(a, (0, 0, W, H), [(8, 8, 16), (14, 12, 24), (22, 18, 30)])
    # Lo que sueña le sale de la cabeza: humo de neón que sube y se abre.
    for y in range(4, 78):
        for x in range(20, 220):
            t = (78 - y) / 74.0
            cx = 86 + np.sin(y / 9.0 + f * 1.3) * 14 * t + t * 30
            wdt = 6 + t * 70
            k = 1.0 - abs(x - cx) / wdt
            if k > 0 and k * (0.35 + 0.5 * t) > BAYER[(y + f) % 4, (x + f) % 4]:
                band = int((x + y * 2 + f * 9) / 22) % 3
                a[y, x] = [(230, 60, 140), (70, 200, 230), (250, 200, 80)][band] if k > 0.5 else [(110, 30, 80), (30, 90, 120), (120, 90, 40)][band]
    img = to_img(a)
    d = ImageDraw.Draw(img)
    # Cosas que flotan en el humo: un puño, una rueda, una culebra.
    o = [0, -1, -2, -1][f]
    d.rectangle([118, 22 + o, 128, 30 + o], fill=(14, 12, 24))
    d.rectangle([116, 24 + o, 118, 30 + o], fill=(14, 12, 24))
    d.ellipse([160, 34 - o, 176, 50 - o], outline=(14, 12, 24), width=2)
    d.point((168, 42 - o), fill=(14, 12, 24))
    d.line([(60, 20 + o), (68, 14 + o), (76, 20 + o), (84, 14 + o), (92, 20 + o)], fill=(14, 12, 24), width=2)
    d.polygon([(40, 88), (140, 88), (144, 93), (36, 93)], fill=(70, 54, 40))
    man_side(d, 110, 88, breath(f), (230, 80, 150) if f % 2 == 0 else (80, 200, 230), 0.7)
    return img


def intruso(f):
    a = np.zeros((H, W, 3), np.uint8)
    gradient(a, (0, 0, W, 66), [(8, 10, 22), (12, 14, 30), (20, 22, 42)])
    gradient(a, (0, 66, W, H), [(26, 24, 32), (18, 16, 24), (12, 10, 16)])
    img = to_img(a)
    d = ImageDraw.Draw(img)
    d.polygon([(120, 90), (128, 52), (220, 48), (232, 90)], fill=(54, 42, 32))                     # el cambuche
    d.polygon([(140, 90), (146, 64), (210, 62), (216, 90)], fill=(10, 9, 14))
    d.rectangle([60, 74, 92, 90], fill=(74, 56, 38))                                              # la caja
    d.polygon([(60, 74), (56, 62), (78, 60), (92, 74)], fill=(92, 70, 48))                        # la tapa, abierta
    a = np.array(img.convert("RGB"))
    lx = 74 + [0, 2, 1, -1][f]
    cone(a, (64, 58), (lx - 14, 80), (lx + 14, 80), (240, 236, 200), 0.6)                          # la linterna, adentro de la caja
    img = to_img(a)
    d = ImageDraw.Draw(img)
    # El otro: flaco, agachado sobre la caja, la mano adentro.
    d.polygon([(34, 90), (30, 62), (44, 50), (56, 56), (52, 90)], fill=(10, 10, 14))
    d.ellipse([40, 38, 54, 52], fill=(10, 10, 14))
    d.polygon([(40, 44), (56, 42), (54, 46)], fill=(10, 10, 14))                                   # la visera
    d.line([(50, 60), (66, 70 + (f % 2))], fill=(10, 10, 14), width=4)
    d.line([(31, 62), (44, 50), (48, 40)], fill=(90, 90, 110))
    # Adentro del cambuche: dos ojos que ya se abrieron.
    if f != 1:
        d.point((166, 76), fill=(240, 240, 240))
        d.point((171, 76), fill=(240, 240, 240))
    if f in (2, 3):                                                                                # y, abajo, otros dos
        d.point((186, 84), fill=(240, 200, 120))
        d.point((190, 84), fill=(240, 200, 120))
    return img


def lukas_pecho(still):
    def scene(f):
        a = np.zeros((H, W, 3), np.uint8)
        sky = [(40, 44, 60), (62, 66, 84), (88, 92, 108)] if still else [(10, 10, 22), (16, 16, 34), (26, 24, 48)]
        gradient(a, (0, 0, W, 60), sky, horizontal=True)
        gradient(a, (0, 60, W, H), [(40, 36, 44), (28, 26, 34), (18, 16, 24)])
        for y in range(0, 58):
            for x in range(W):
                if ((x - 150) / 150.0) ** 2 + ((y - 62) / 50.0) ** 2 >= 1.0:
                    a[y, x] = (14, 12, 20)
        img = to_img(a)
        d = ImageDraw.Draw(img)
        b = 0 if still else breath(f)
        lb = 0 if still else (1 if f in (0, 1) else 0)      # Lukas respira más rápido que él
        rim = (150, 156, 176) if still else (110, 116, 160)
        d.polygon([(20, 88), (200, 88), (206, 94), (14, 94)], fill=(96, 74, 52))
        # Él, boca arriba, grande. El saco, la corbata. La mano en el lomo.
        d.polygon([(124, 70), (196, 72), (196, 88), (124, 88)], fill=PANTS)
        d.rectangle([196, 62, 204, 88], fill=SHOE_A)
        d.rectangle([186, 66, 194, 74], fill=SHOE_B)
        d.polygon([(52, 66), (86, 58 - b), (126, 62 - b), (128, 88), (52, 88)], fill=COAT)
        d.polygon([(52, 80), (128, 80), (128, 88), (52, 88)], fill=COAT_DK)
        d.ellipse([22, 60, 52, 88], fill=HAIR)
        d.rectangle([30, 62, 40, 68], fill=SKIN)
        d.line([(54, 70), (62, 60 - b)], fill=TIE, width=3)
        d.line([(24, 64), (40, 59), (86, 57 - b), (126, 61 - b)], fill=rim)
        d.line([(128, 69), (196, 71)], fill=rim)
        # Lukas, en el pecho. Nunca hacía eso.
        y0 = 62 - b
        d.ellipse([70, y0 - 22 - lb, 122, y0 + 2], fill=TAN)
        d.ellipse([80, y0 - 24 - lb, 116, y0 - 8], fill=BLACK)
        d.ellipse([54, y0 - 14, 78, y0 + 4], fill=TAN)                                             # la cabeza, en el hombro de él
        d.polygon([(63, y0 - 14), (67, y0 - 14), (65, y0 - 2)], fill=WHITE)
        d.ellipse([48, y0 - 6, 62, y0 + 4], fill=WHITE)
        d.rectangle([48, y0 - 3, 50, y0 - 1], fill=BLACK)
        d.ellipse([68, y0 - 16, 80, y0 + 2], fill=EAR)
        d.line([(120, y0 - 8), (132, y0 - 2 if still else y0 - 6 - (f % 2) * 3)], fill=TAN, width=3)   # la cola
        d.point((133, y0 - 2 if still else y0 - 7 - (f % 2) * 3), fill=WHITE)
        d.arc([70, y0 - 22 - lb, 122, y0 + 10], 200, 340, fill=rim)
        d.line([(124, 70), (118, y0 - 12 - lb), (108, y0 - 20 - lb)], fill=COAT_DK, width=6)          # el brazo, la mano en el lomo
        d.rectangle([100, y0 - 24 - lb, 109, y0 - 19 - lb], fill=SKIN)
        for k in range(3):
            d.line([(101 + k * 3, y0 - 24 - lb), (101 + k * 3, y0 - 20 - lb)], fill=dim(SKIN, 0.75))
        if still:
            a2 = np.array(img.convert("RGB")).astype(float)
            grey = a2.mean(axis=2, keepdims=True)
            img = to_img(a2 * 0.6 + grey * 0.4)
        return img
    return scene


def entierro(f):
    a = np.zeros((H, W, 3), np.uint8)
    gradient(a, (0, 0, W, 66), [(90, 100, 130), (150, 140, 150), (226, 180, 150), (248, 214, 170)], ease=0.9)
    gradient(a, (0, 66, W, H), [(62, 84, 60), (44, 62, 48), (30, 44, 38)])
    img = to_img(a)
    d = ImageDraw.Draw(img)
    # El árbol de flores amarillas.
    d.polygon([(96, 86), (104, 36), (118, 36), (124, 86)], fill=(52, 38, 34))
    for cx, cy, r in [(110, 22, 26), (80, 34, 18), (140, 32, 20), (112, 8, 16)]:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(60, 84, 58))
    rng = np.random.default_rng(4)
    for cx, cy, r in [(110, 22, 26), (80, 34, 18), (140, 32, 20), (112, 8, 16)]:
        for _ in range(34):
            ang, rr = rng.uniform(0, 6.28), rng.uniform(0, r - 2)
            fx, fy = int(cx + np.cos(ang) * rr), max(1, int(cy + np.sin(ang) * rr))
            d.point((fx, fy), fill=(250, 214, 70))
            d.point((fx + 1, fy), fill=(230, 180, 50))
    for i in range(6):                                                                             # flores que caen
        fx, fy = 70 + (i * 29) % 90, (30 + i * 17 + f * 9) % 90
        d.point((fx + (f + i) % 3, fy), fill=(250, 214, 70))
    # La tierra removida, el clavel de doña Leonor, la pala.
    d.ellipse([124, 82, 168, 94], fill=(84, 62, 46))
    d.ellipse([130, 80, 162, 90], fill=(104, 78, 56))
    d.line([(146, 80), (146, 74)], fill=(50, 100, 56))
    d.ellipse([144, 71, 148, 75], fill=(214, 50, 60))
    d.line([(176, 92), (184, 56)], fill=(110, 84, 56), width=2)
    d.polygon([(172, 92), (180, 92), (178, 84), (175, 84)], fill=(150, 154, 164))
    rim = (255, 214, 160)
    man_sit(d, 196, 92, 0, rim, 0.9, flip=True, head_down=False)                                   # él, sentado al lado
    # Samuel, de pie, con el sombrero en la mano. Más lejos, el Padre.
    d.polygon([(38, 92), (36, 60), (50, 58), (52, 92)], fill=(44, 40, 46))
    d.ellipse([38, 46, 50, 58], fill=(34, 28, 30))
    d.ellipse([46, 68, 60, 72], fill=(70, 56, 40))
    d.line([(36, 60), (37, 92)], fill=rim)
    d.polygon([(14, 86), (13, 66), (21, 65), (22, 86)], fill=(30, 28, 34))
    d.ellipse([14, 58, 21, 65], fill=(40, 34, 34))
    d.point((17, 68), fill=(230, 230, 230))
    return img


def collar(f):
    a = np.zeros((H, W, 3), np.uint8)
    gradient(a, (0, 0, W, H), [(30, 28, 38), (42, 38, 48), (54, 46, 54)], horizontal=True)
    img = to_img(a)
    d = ImageDraw.Draw(img)
    # La mochila, de cerca: la tapa, la correa, la hebilla.
    d.polygon([(40, 100), (48, 20), (150, 14), (166, 100)], fill=PACK)
    d.polygon([(48, 20), (150, 14), (154, 46), (50, 52)], fill=dim(PACK, 1.2))
    d.line([(50, 52), (154, 46)], fill=dim(PACK, 0.6), width=2)
    d.rectangle([94, 44, 108, 58], fill=(150, 150, 160))
    d.rectangle([98, 48, 104, 54], fill=dim(PACK, 0.8))
    d.polygon([(150, 14), (176, 6), (190, 100), (166, 100)], fill=dim(PACK, 0.75))                 # la correa
    # El collar, amarrado a la correa: cuero gastado, la plaquita.
    d.ellipse([150, 36, 200, 78], outline=(140, 84, 46), width=5)
    d.ellipse([150, 36, 200, 78], outline=(180, 116, 66), width=1)
    d.rectangle([170, 32, 182, 40], fill=(110, 66, 36))                                            # el nudo
    d.ellipse([168, 76, 182, 90], fill=(190, 192, 204))
    d.text((172, 78), "L", fill=(90, 92, 104))
    if f in (1, 2):
        d.point((170 + f * 4, 78), fill=(255, 255, 255))                                           # el brillo
        d.point((171 + f * 4, 79), fill=(255, 255, 255))
    # La mano de él, que no lo suelta.
    d.polygon([(206, 100), (204, 70), (216, 58), (236, 62), (240, 100)], fill=COAT)
    d.polygon([(196, 66), (214, 58), (220, 72), (202, 80)], fill=SKIN)
    for k in range(4):
        d.line([(197 + k * 4, 66 + k), (201 + k * 4, 76 + k)], fill=dim(SKIN, 0.75))
    return img


def final(f):
    a = np.zeros((H, W, 3), np.uint8)
    gradient(a, (0, 0, W, 58), [(70, 76, 120), (150, 110, 140), (232, 150, 130), (250, 200, 150), (255, 232, 190)], ease=0.9)
    gradient(a, (0, 58, W, 70), [(120, 120, 150), (90, 92, 126)])
    gradient(a, (0, 70, W, H), [(70, 58, 64), (50, 42, 50), (36, 30, 38)])
    img = to_img(a)
    d = ImageDraw.Draw(img)
    for bx, bw, bh in [(4, 14, 16), (20, 10, 22), (34, 18, 12), (56, 8, 26), (180, 16, 20), (198, 10, 28), (210, 18, 14)]:
        d.rectangle([bx, 58 - bh, bx + bw, 58], fill=(98, 76, 104))
    d.ellipse([128, 38, 158, 68], fill=(255, 236, 196))
    d.rectangle([0, 58, W, 59], fill=(110, 104, 140))
    a = np.array(img.convert("RGB"))
    for x in range(118, 172, 2):
        if (x + f) % 4 == 0:
            a[60 + (x // 4 + f) % 6, x] = (255, 220, 170)
    for y in range(0, 62):
        for x in range(W):
            if ((x - 120) / 128.0) ** 2 + ((y - 64) / 52.0) ** 2 >= 1.0:
                a[y, x] = (30, 24, 36) if ((x - 120) / 134.0) ** 2 + ((y - 64) / 57.0) ** 2 > 1.0 else (70, 52, 60)
    cone(a, (148, 52), (70, 98), (150, 98), (255, 210, 150), 0.55)
    img = to_img(a)
    d = ImageDraw.Draw(img)
    rim = (255, 204, 144)
    d.polygon([(60, 88), (150, 88), (154, 93), (56, 93)], fill=(140, 104, 66))
    man_side(d, 116, 88, 0, rim, 1.0, hand_out=True)                                               # quieto: no respira
    d.ellipse([70, 82, 79, 90], outline=(160, 100, 56), width=2)                                    # el collar, en la mano
    d.point((74, 90), fill=(230, 230, 240))
    # Samuel, parado en la boca del puente, con el sombrero en el pecho.
    d.polygon([(190, 90), (188, 54), (204, 52), (206, 90)], fill=(40, 34, 44))
    d.ellipse([190, 38, 204, 52], fill=(30, 24, 30))
    d.ellipse([186, 60, 200, 66], fill=(60, 46, 36))
    d.line([(205, 52), (207, 90)], fill=rim)
    for bx, by in [(196, 28), (204, 24), (212, 30)]:                                               # los pájaros, como todos los días
        d.point((bx + f, by), fill=(60, 46, 70))
        d.point((bx - 1 + f, by - 1), fill=(60, 46, 70))
        d.point((bx + 1 + f, by - 1), fill=(60, 46, 70))
    return img


if __name__ == "__main__":
    for name, fn in [("banco", banco), ("kiosco", kiosco), ("rio", rio), ("callejon", callejon), ("parque", parque), ("pension", pension)]:
        save("dormir_" + name, fn(False))
        save("dormir_" + name + "_solo", fn(True))
    save("sueno", sueno)
    save("intruso", intruso)
    save("lukas_pecho", lukas_pecho(False))
    save("lukas_quieto", lukas_pecho(True))
    save("entierro", entierro)
    save("collar", collar)
    save("final", final)
