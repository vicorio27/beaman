"""Las viñetas de la noche: cuadros chiquitos y quietos que acompañan los textos de NightSequence
(acostarse, despertarse). Pixel art con degradados tramados (Bayer 4x4), luz que entra de lado y
siluetas con un borde de luz. Paletas cortas, una por escena.
  vineta_acostarse.png       noche: el farol, la lluvia fina; él sentado en el cartón contra el pilar
                             del puente, y Lukas dando la vuelta antes de echarse
  vineta_despierta.png       amanecer debajo del puente: él dormido de lado, Lukas hecho un ovillo
                             contra el pecho; el primer rayo de sol les cruza encima
  vineta_golpeado.png        madrugada fría: sentado contra la pared, la mano en la cara, la caja
                             del cambuche volteada, las latas regadas; Lukas le lame la otra mano
  vineta_despierta_solo.png  el mismo amanecer, sin Lukas: el hueco en el cartón, el collar en la mano
  vineta_despierta_lluvia.png  el amanecer de una noche de lluvia: gris, sin sol, todavía cae
Salida: assets/ui/ (240x100). Uso: python tools/art/draw_vinetas.py  (desde la carpeta del proyecto)"""
import numpy as np
from PIL import Image, ImageDraw

W, H = 240, 100
OUT = "assets/ui/"
BAYER = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) + 0.5) / 16.0


def ramp(pal, t):
    """Color de la rampa (lista de colores) en t (0..1), con tramado: devuelve el índice por píxel."""
    return pal


def gradient(arr, box, pal, horizontal=False, ease=1.0):
    """Llena box (x0, y0, x1, y1) con la rampa de colores pal, tramada (sin colores intermedios)."""
    x0, y0, x1, y1 = box
    n = len(pal) - 1
    for y in range(y0, y1):
        for x in range(x0, x1):
            t = ((x - x0) / max(1, x1 - x0 - 1)) if horizontal else ((y - y0) / max(1, y1 - y0 - 1))
            v = (t ** ease) * n
            i = int(v)
            f = v - i
            if f > BAYER[y % 4, x % 4] and i < n:
                i += 1
            arr[y, x] = pal[i]


def glow(arr, cx, cy, r, color, strength=0.55, squash=1.0):
    """Luz redonda, tramada: mezcla hacia color según la distancia (sin halos suaves: píxel duro)."""
    for y in range(max(0, int(cy - r * squash)), min(H, int(cy + r * squash) + 1)):
        for x in range(max(0, int(cx - r)), min(W, int(cx + r) + 1)):
            d = ((x - cx) ** 2 + ((y - cy) / squash) ** 2) ** 0.5 / r
            k = max(0.0, 1.0 - d) * strength
            if k > BAYER[y % 4, x % 4] * 0.9:
                arr[y, x] = (arr[y, x] * (1 - k * 0.6) + np.array(color) * k * 0.6).astype(np.uint8)


def cone(arr, apex, base_l, base_r, color, strength=0.5):
    """Cono de luz (del farol, del rayo de sol), tramado, más fuerte cerca del origen."""
    ax, ay = apex
    y0, y1 = ay, max(base_l[1], base_r[1])
    for y in range(int(y0), min(H, int(y1) + 1)):
        t = (y - ay) / max(1, y1 - ay)
        xl = ax + (base_l[0] - ax) * t
        xr = ax + (base_r[0] - ax) * t
        for x in range(max(0, int(xl)), min(W, int(xr) + 1)):
            k = strength * (1 - t * 0.6)
            if k > BAYER[y % 4, x % 4]:
                arr[y, x] = (arr[y, x] * (1 - k * 0.5) + np.array(color) * k * 0.5).astype(np.uint8)


def to_img(arr):
    return Image.fromarray(arr.astype(np.uint8)).convert("RGBA")


def frame(img):
    """Borde: una línea fina y las esquinas redondeadas (para que se lea como un cuadro)."""
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W - 1, H - 1], outline=(18, 14, 22, 255))
    for x, y in [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]:
        img.putpixel((x, y), (0, 0, 0, 0))
    return img


# ------------------------------------------------------------------ los personajes, en chiquito

def man_sitting(d, x, y, body, rim, skin, head_down=True):
    """Sentado contra algo, las rodillas arriba, los brazos sobre las rodillas. (x, y) = los pies."""
    d.polygon([(x - 2, y), (x + 10, y), (x + 12, y - 9), (x + 2, y - 12)], fill=body)            # piernas
    d.polygon([(x + 10, y - 9), (x + 22, y - 10), (x + 24, y - 30), (x + 12, y - 30)], fill=body)  # torso (el saco)
    d.ellipse([x + 11 + (2 if head_down else 0), y - 39 + (3 if head_down else 0), x + 21 + (2 if head_down else 0), y - 29 + (3 if head_down else 0)], fill=body)
    d.line([(x + 13, y - 24), (x + 6, y - 13)], fill=body, width=3)                                # brazo sobre la rodilla
    d.point((x + 5, y - 12), fill=skin)
    d.line([(x + 23, y - 30), (x + 23, y - 12)], fill=rim)                                          # el borde de luz
    d.line([(x + 12, y - 9), (x + 11, y - 1)], fill=rim)


def man_lying(d, x, y, body, rim, skin, hand=None):
    """Dormido de lado, encogido, la cabeza a la izquierda. (x, y) = la cadera, en el piso."""
    d.ellipse([x - 34, y - 9, x - 24, y], fill=body)                         # cabeza
    d.polygon([(x - 26, y - 8), (x + 2, y - 10), (x + 4, y), (x - 26, y)], fill=body)   # torso
    d.polygon([(x + 2, y - 9), (x + 18, y - 6), (x + 14, y), (x + 2, y)], fill=body)    # piernas encogidas
    d.line([(x - 33, y - 10), (x + 2, y - 11)], fill=rim)                     # el borde de luz, arriba
    d.line([(x + 2, y - 10), (x + 17, y - 7)], fill=rim)
    if hand:
        d.point(hand, fill=skin)


def lukas_curled(d, x, y, tan, black, white, rim):
    """Lukas hecho un ovillo (visto de lado): lomo negro, cabeza canela con la franja blanca, la cola enroscada."""
    d.ellipse([x, y - 7, x + 16, y], fill=tan)
    d.ellipse([x + 3, y - 8, x + 13, y - 3], fill=black)                      # la montura
    d.ellipse([x - 4, y - 6, x + 3, y], fill=tan)                             # la cabeza, apoyada
    d.line([(x - 2, y - 6), (x - 2, y - 2)], fill=white)                      # la franja blanca
    d.ellipse([x - 6, y - 4, x - 3, y - 1], fill=white)                       # el hocico
    d.ellipse([x + 1, y - 7, x + 4, y - 1], fill=black)                       # la oreja caída
    d.point((x + 16, y - 6), fill=white)                                      # la punta de la cola
    d.line([(x + 1, y - 8), (x + 13, y - 8)], fill=rim)


def lukas_turning(d, x, y, tan, black, white, rim):
    """Lukas dando la vuelta antes de echarse: parado, de lado, la cola arriba, la nariz a la cola."""
    d.rectangle([x, y - 8, x + 14, y - 3], fill=tan)
    d.rectangle([x + 3, y - 9, x + 11, y - 6], fill=black)
    for lx in (x + 1, x + 4, x + 10, x + 13):
        d.line([(lx, y - 3), (lx, y)], fill=tan)
    d.ellipse([x + 11, y - 12, x + 18, y - 5], fill=tan)                      # la cabeza, volteada hacia atrás
    d.line([(x + 14, y - 12), (x + 14, y - 8)], fill=white)
    d.ellipse([x + 15, y - 9, x + 18, y - 6], fill=white)
    d.line([(x, y - 8), (x - 3, y - 14)], fill=tan, width=2)                  # la cola arriba
    d.point((x - 3, y - 15), fill=white)
    d.line([(x + 1, y - 9), (x + 11, y - 9)], fill=rim)


# ------------------------------------------------------------------ las escenas

def acostarse():
    a = np.zeros((H, W, 3), np.uint8)
    gradient(a, (0, 0, W, 64), [(18, 16, 40), (28, 26, 58), (44, 38, 76), (62, 50, 90)], ease=1.3)
    gradient(a, (0, 64, W, H), [(40, 34, 52), (30, 26, 40), (20, 18, 28)])          # el piso mojado
    for sx, sy in [(30, 8), (62, 18), (96, 6), (140, 14), (176, 4), (210, 20), (226, 9), (118, 26)]:
        a[sy, sx] = (220, 214, 236)
    # El puente: el arco oscuro arriba a la derecha y el pilar.
    img = to_img(a)
    d = ImageDraw.Draw(img)
    d.pieslice([110, -70, 330, 70], 0, 180, fill=(14, 12, 22))
    d.rectangle([110, 0, 240, 6], fill=(14, 12, 22))
    d.rectangle([176, 0, 196, 86], fill=(22, 18, 30))                          # el pilar
    d.line([(176, 10), (176, 86)], fill=(60, 46, 50))
    # El farol, a la izquierda.
    d.rectangle([40, 14, 41, 86], fill=(30, 26, 34))
    d.rectangle([36, 12, 46, 15], fill=(30, 26, 34))
    a = np.array(img.convert("RGB"))
    cone(a, (41, 16), (4, 92), (100, 92), (255, 196, 110), 0.55)
    glow(a, 41, 16, 10, (255, 220, 150), 0.9)
    # La lluvia fina, cruzando la luz del farol.
    rng = np.random.default_rng(5)
    for _ in range(90):
        x, y = int(rng.integers(0, W)), int(rng.integers(0, 80))
        for k in range(3):
            if 0 <= y + k * 2 < H and 0 <= x - k < W:
                lit = abs(x - 41) < (y + k * 2) * 0.55
                a[y + k * 2, x - k] = (230, 200, 150) if lit else (80, 80, 110)
    # Los reflejos del farol en el charco.
    for y in range(88, 98, 2):
        for x in range(30, 54, 3):
            if (x + y) % 5 == 0:
                a[y, x] = (200, 150, 90)
    img = to_img(a)
    d = ImageDraw.Draw(img)
    d.polygon([(150, 88), (178, 88), (176, 92), (148, 92)], fill=(110, 84, 56))  # el cartón
    man_sitting(d, 152, 88, (36, 32, 44), (150, 120, 90), (200, 150, 120))
    lukas_turning(d, 126, 90, (150, 90, 46), (26, 22, 26), (226, 218, 204), (240, 190, 120))
    img.save(OUT + "vineta_acostarse.png")
    frame(img).save(OUT + "vineta_acostarse.png")


def amanecer(solo=False, rain=False):
    a = np.zeros((H, W, 3), np.uint8)
    sky = [(52, 58, 76), (78, 86, 104), (104, 112, 128), (128, 134, 148)] if rain else         [(70, 76, 120), (150, 110, 140), (232, 150, 130), (250, 200, 150), (255, 232, 190)]
    gradient(a, (0, 0, W, 58), sky, ease=0.9)
    gradient(a, (0, 58, W, 70), [(120, 120, 150), (90, 92, 126)])                 # el río
    gradient(a, (0, 70, W, H), [(70, 58, 64), (50, 42, 50), (36, 30, 38)])          # la orilla
    for x in range(0, W, 2):                                                        # el reflejo del sol en el río
        if 120 < x < 170 and x % 4 == 0:
            a[60 + (x // 4) % 6, x] = (255, 220, 170)
    img = to_img(a)
    d = ImageDraw.Draw(img)
    # La ciudad, lejos, recortada contra el amanecer.
    for bx, bw, bh in [(4, 14, 16), (20, 10, 22), (34, 18, 12), (56, 8, 26), (68, 16, 18), (90, 12, 14),
                       (180, 16, 20), (198, 10, 28), (210, 18, 14), (230, 10, 18)]:
        d.rectangle([bx, 58 - bh, bx + bw, 58], fill=(98, 76, 104))
        for wy in range(58 - bh + 3, 56, 5):
            if (bx + wy) % 3 == 0:
                d.point((bx + 3, wy), fill=(250, 210, 140))
    if not rain:
        d.ellipse([132, 40, 160, 68], fill=(255, 236, 196))                         # el sol, saliendo
    d.rectangle([0, 58, W, 59], fill=(110, 104, 140))
    # Debajo del puente: el techo en sombra y el arco abierto, por donde entra el amanecer.
    a = np.array(img.convert("RGB"))
    for y in range(0, 62):
        for x in range(W):
            inside = ((x - 120) / 128.0) ** 2 + ((y - 64) / 52.0) ** 2 < 1.0
            if not inside:
                a[y, x] = (30, 24, 36) if ((x - 120) / 134.0) ** 2 + ((y - 64) / 57.0) ** 2 > 1.0 else (70, 52, 60)
    if rain:  # todavía cae: la lluvia en el arco, el piso brillando
        rng = np.random.default_rng(9)
        for _ in range(140):
            x, y = int(rng.integers(0, W)), int(rng.integers(0, 70))
            for k in range(3):
                yy, xx = y + k * 2, x - k
                outside = ((xx - 120) / 128.0) ** 2 + ((yy - 64) / 52.0) ** 2 < 1.0 and yy < 60  # afuera, no debajo del puente
                if 0 <= yy < H and 0 <= xx < W and outside:
                    a[yy, xx] = (150, 160, 180)
    else:  # el primer rayo de sol, en diagonal, por debajo del puente, hasta el cartón
        cone(a, (150, 52), (60, 98), (130, 98), (255, 210, 150), 0.55)
        glow(a, 146, 54, 22, (255, 230, 180), 0.5)
    img = to_img(a)
    d = ImageDraw.Draw(img)
    d.polygon([(52, 88), (118, 88), (122, 93), (48, 93)], fill=(140, 104, 66))    # el cartón
    d.line([(52, 88), (118, 88)], fill=(200, 160, 110))
    body, rim, skin = (44, 36, 50), ((150, 160, 180) if rain else (255, 200, 140)), (220, 160, 120)
    man_lying(d, 96, 88, body, rim, skin, hand=(64, 86) if solo else None)
    if solo:
        # El hueco donde dormía Lukas, y el collar en la mano: un aro de cuero con la plaquita.
        d.ellipse([60, 81, 66, 87], outline=(150, 92, 52))
        d.point((63, 87), fill=(220, 220, 230))
    else:
        lukas_curled(d, 66, 88, (176, 106, 54), (30, 24, 28), (236, 228, 214), (255, 210, 150))
        d.point((70, 79), fill=(255, 255, 255))                                   # (la oreja de Lukas: se mueve)
    # Pájaros.
    for bx, by in [(196, 30), (204, 26), (212, 32)]:
        d.point((bx, by), fill=(60, 46, 70))
        d.point((bx - 1, by - 1), fill=(60, 46, 70))
        d.point((bx + 1, by - 1), fill=(60, 46, 70))
    if solo:
        a = np.array(img.convert("RGB")).astype(float)
        grey = a.mean(axis=2, keepdims=True)
        a = a * 0.55 + grey * 0.45                                                   # sin Lukas, el color se va
        img = to_img(a)
    frame(img).save(OUT + ("vineta_despierta_lluvia.png" if rain else ("vineta_despierta_solo.png" if solo else "vineta_despierta.png")))


def golpeado():
    a = np.zeros((H, W, 3), np.uint8)
    gradient(a, (0, 0, W, 76), [(56, 64, 84), (72, 80, 100), (88, 96, 114)], horizontal=True)   # la pared, fría
    gradient(a, (0, 76, W, H), [(60, 62, 72), (44, 46, 56), (32, 34, 42)])                  # el andén
    img = to_img(a)
    d = ImageDraw.Draw(img)
    for y in range(4, 76, 7):                                                         # los ladrillos
        off = 0 if (y // 7) % 2 == 0 else 8
        for x in range(-off, W, 16):
            d.rectangle([x + 1, y + 1, x + 14, y + 5], outline=(48, 54, 72))
    d.line([(150, 18), (178, 30), (164, 40)], fill=(150, 60, 70), width=2)           # un grafiti viejo
    d.line([(184, 20), (186, 40)], fill=(150, 60, 70), width=2)
    a = np.array(img.convert("RGB"))
    # La luz entra de la calle, de lado, fría, y deja la sombra larga.
    cone(a, (W, 10), (60, 96), (W, 96), (200, 214, 236), 0.45)
    img = to_img(a)
    d = ImageDraw.Draw(img)
    # La caja del cambuche, volteada; las latas regadas; un cartón pisado.
    d.polygon([(30, 92), (58, 86), (64, 96), (34, 99)], fill=(120, 92, 62))
    d.polygon([(30, 92), (40, 80), (64, 76), (58, 86)], fill=(96, 72, 50))
    for lx, ly in [(70, 94), (82, 97), (16, 96), (96, 92)]:
        d.rectangle([lx, ly - 3, lx + 3, ly], fill=(160, 166, 176))
        d.point((lx + 1, ly - 3), fill=(220, 226, 236))
    # Él, contra la pared, la mano en la cara. La marca roja en el pómulo.
    body, rim, skin = (40, 38, 52), (200, 214, 236), (200, 150, 124)
    man_sitting(d, 128, 92, body, rim, skin, head_down=False)
    d.line([(150, 70), (142, 60)], fill=body, width=3)                            # el otro brazo, a la cara
    d.ellipse([140, 58, 144, 62], fill=skin)
    d.point((146, 58), fill=(200, 50, 60))
    d.point((147, 59), fill=(200, 50, 60))
    # Lukas, al lado, le lame la mano que quedó en la rodilla.
    lukas_turning(d, 104, 94, (150, 92, 50), (24, 22, 26), (226, 220, 210), (200, 214, 236))
    d.point((121, 82), fill=(230, 110, 120))                                       # la lengua
    frame(img).save(OUT + "vineta_golpeado.png")


if __name__ == "__main__":
    acostarse()
    amanecer()
    amanecer(solo=True)
    amanecer(rain=True)
    golpeado()
    print("viñetas listas")
