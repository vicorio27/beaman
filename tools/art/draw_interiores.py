"""Los interiores (la iglesia, la veterinaria, la pensión, el baño, la Defensoría, la Registraduría, el estudio
de fotos y La Caverna del Gamer), cada uno en una imagen: paredes, piso y muebles con su detalle.

    python -X utf8 tools/art/draw_interiores.py   -> assets/interiores/<id>.png

La distribución NO está aquí: se lee de PLACES en scripts/world/Interior.gd (el tamaño, los colores, cada
mueble con su posición y tamaño), para que el dibujo y los choques nunca se corran. Lo que se mueve (las
llamas de las velas, el televisor, las pantallas de las maquinitas, el turno de la pantalla) lo sigue
pintando Interior.gd encima.

Estilo de draw_relleno.py: vista de arriba en 3/4, contorno violeta oscuro, colores gastados.
"""
import os
import random
import re

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "assets", "interiores")
INK = (38, 28, 44)
WOOD = (122, 82, 52)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def dark(c, k=0.25):
    return mix(c, (0, 0, 0), k)


def light(c, k=0.25):
    return mix(c, (255, 255, 255), k)


# ---------------------------------------------------------------- leer la distribución de Interior.gd

def places():
    src = open(os.path.join(ROOT, "scripts", "world", "Interior.gd"), encoding="utf-8").read()
    body = src[src.index("const PLACES := {"):src.index("## Horas:")]
    heads = list(re.finditer(r'\n\t"(\w+)": \{"size": Vector2\((\d+), (\d+)\), "floor": Color\(([\d., ]+)\), "wall": Color\(([\d., ]+)\)', body))
    out = {}
    for i, m in enumerate(heads):
        block = body[m.start():heads[i + 1].start() if i + 1 < len(heads) else len(body)]
        col = lambda s: tuple(int(float(v) * 255) for v in s.split(","))
        props = [(p[0], int(p[1]), int(p[2]), int(p[3]), int(p[4])) for p in
                 re.findall(r'\["(\w+)", Vector2\((\d+), (\d+)\), Vector2\((\d+), (\d+)\)\]', block.split('"owner"')[0])]
        cat = re.search(r'"path": \[Vector2\((\d+), (\d+)\)\], "pose": "down", "id": "", "cat": true', block)
        out[m.group(1)] = {"w": int(m.group(2)), "h": int(m.group(3)), "floor": col(m.group(4)), "wall": col(m.group(5)),
                           "tiles": '"tiles": true' in block[:400], "dark": '"dark": true' in block[:400], "props": props,
                           "cat": (int(cat.group(1)), int(cat.group(2))) if cat else None}
    return out


# ---------------------------------------------------------------- lo básico

class Room:
    def __init__(self, w, h, seed):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 255))
        self.d = ImageDraw.Draw(self.im)
        self.w, self.h = w, h
        self.r = random.Random(seed)

    def rect(self, x0, y0, x1, y1, c, outline=False):
        self.d.rectangle([x0, y0, x1, y1], fill=c, outline=INK if outline else None)

    def line(self, pts, c, w=1):
        self.d.line(pts, fill=c, width=w)

    def ell(self, x0, y0, x1, y1, c, outline=False):
        self.d.ellipse([x0, y0, x1, y1], fill=c, outline=INK if outline else None)

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.im.putpixel((int(x), int(y)), c + (255,))

    def noise(self, x0, y0, x1, y1, base, amount=0.06, density=0.35):
        for y in range(y0, y1):
            for x in range(x0, x1):
                if self.r.random() < density:
                    self.px(x, y, dark(base, amount) if self.r.random() < 0.6 else light(base, amount))

    def shadow(self, x0, y0, x1, y1):
        """La sombrita de un mueble en el piso (abajo a la derecha), tramada."""
        for y in range(y0, y1):
            for x in range(x0, x1):
                if (x + y) % 2 == 0 and 0 <= x < self.w and 0 <= y < self.h:
                    c = self.im.getpixel((x, y))
                    self.im.putpixel((x, y), tuple(int(v * 0.8) for v in c[:3]) + (255,))


# ---------------------------------------------------------------- el cuarto: piso y paredes

def floor_and_walls(R, P, pid):
    w, h, fl, wl = R.w, R.h, P["floor"], P["wall"]
    if P["tiles"]:  # baldosa: dos tonos, junta, desgaste
        for y in range(30, h, 12):
            for x in range(0, w, 12):
                c = fl if (x // 12 + y // 12) % 2 else dark(fl, 0.07)
                R.rect(x, y, x + 11, y + 11, c)
                R.noise(x, y, min(w, x + 12), min(h, y + 12), c, 0.05, 0.18)
                R.line([(x, y), (x + 11, y)], light(c, 0.12))
        for y in range(30, h, 12):
            R.line([(0, y + 11), (w, y + 11)], dark(fl, 0.18))
        for x in range(0, w, 12):
            R.line([(x + 11, 30), (x + 11, h)], dark(fl, 0.18))
    elif pid == "caverna":  # la alfombra de las maquinitas: oscura, con confeti de colores
        R.rect(0, 30, w, h, fl)
        cols = [(200, 60, 140), (60, 180, 220), (240, 200, 60), (90, 210, 110)]
        for _ in range(w * h // 60):
            x, y = R.r.randrange(w), R.r.randrange(30, h)
            c = R.r.choice(cols)
            R.px(x, y, c)
            if R.r.random() < 0.5:
                R.px(x + 1, y, dark(c, 0.3))
    else:  # tablas de madera
        R.rect(0, 30, w, h, fl)
        for y in range(30, h, 6):
            R.line([(0, y), (w, y)], dark(fl, 0.22))
            off = R.r.randrange(0, 40)
            for x in range(off, w, 40):
                R.line([(x, y), (x, y + 5)], dark(fl, 0.22))
            for _ in range(w // 10):
                x = R.r.randrange(w)
                R.line([(x, y + 2 + R.r.randrange(3)), (x + R.r.randrange(2, 6), y + 2 + R.r.randrange(3))], dark(fl, 0.1))
    # La pared del fondo (de frente): el muro, el zócalo, la sombra en el piso.
    R.rect(0, 0, w, 29, wl)
    R.noise(0, 0, w, 27, wl, 0.04, 0.2)
    if pid == "iglesia":  # piedra
        for y in range(0, 26, 7):
            R.line([(0, y), (w, y)], dark(wl, 0.12))
            for x in range((y // 7 % 2) * 9, w, 18):
                R.line([(x, y), (x, y + 6)], dark(wl, 0.12))
    elif pid == "bano":  # baldosín hasta arriba
        for y in range(0, 27, 6):
            R.line([(0, y), (w, y)], light(wl, 0.2))
        for x in range(0, w, 6):
            R.line([(x, 0), (x, 26)], light(wl, 0.2))
    elif pid == "caverna":  # la tira de neón
        R.line([(0, 3), (w, 3)], (230, 90, 200))
        R.line([(0, 4), (w, 4)], (140, 50, 140))
    elif pid in ("defensoria", "registraduria"):  # la franja institucional
        R.rect(0, 18, w, 22, light(wl, 0.15))
        R.line([(0, 18), (w, 18)], dark(wl, 0.2))
    elif pid == "pension":  # papel de colgadura, a rayas, despegado en una esquina
        for x in range(0, w, 6):
            R.line([(x, 0), (x, 26)], dark(wl, 0.08))
        R.d.polygon([(w - 30, 0), (w - 18, 0), (w - 24, 9)], fill=dark(wl, 0.25))
    R.rect(0, 26, w, 29, dark(wl, 0.35))
    R.line([(0, 26), (w, 26)], light(dark(wl, 0.35), 0.2))
    R.shadow(0, 30, w, 33)
    # Las paredes de los lados y la de abajo.
    R.rect(0, 0, 3, h, dark(wl, 0.3))
    R.rect(w - 4, 0, w, h, dark(wl, 0.3))
    R.line([(4, 30), (4, h)], dark(fl, 0.25))
    R.rect(0, h - 3, w, h, INK)
    # La puerta de salida (abajo, en la mitad) y el tapete.
    R.rect(w // 2 - 14, h - 5, w // 2 + 13, h - 1, (90, 62, 40))
    R.rect(w // 2 - 11, h - 12, w // 2 + 10, h - 6, (110, 96, 70), outline=True)
    for x in range(w // 2 - 9, w // 2 + 9, 2):
        R.px(x, h - 9, dark((110, 96, 70), 0.25))


# ---------------------------------------------------------------- los muebles

def prop(R, kind, x, y, w, h, pid):
    x1, y1 = x + w - 1, y + h - 1
    on_wall = y < 30 and kind not in ("counter",)
    if not on_wall and kind not in ("rug", "rope"):
        R.shadow(x + 2, y1 + 1, x1 + 3, y1 + 3)
    if kind in ("pew", "bench"):
        R.rect(x, y, x1, y1, WOOD, True)
        R.rect(x + 1, y + 1, x1 - 1, y + 3, dark(WOOD, 0.3))  # el espaldar
        R.line([(x + 1, y + 4), (x1 - 1, y + 4)], light(WOOD, 0.3))
        for k in range(x + 4, x1 - 2, 9):
            R.line([(k, y + 5), (k + 4, y + 5)], dark(WOOD, 0.12))
        if kind == "pew" and R.r.random() < 0.5:  # un misal olvidado
            bx = R.r.randrange(x + 6, x1 - 8)
            R.rect(bx, y + 5, bx + 4, y + 7, (60, 40, 70))
    elif kind == "chairs":  # sillas plásticas pegadas en fila
        for k in range(x, x1 - 7, 10):
            R.rect(k, y, k + 8, y1, (60, 90, 150), True)
            R.rect(k + 1, y + 1, k + 7, y + 3, light((60, 90, 150), 0.2))
    elif kind == "altar":
        R.rect(x, y, x1, y1, (238, 236, 228), True)
        R.rect(x + 1, y1 - 4, x1 - 1, y1 - 1, (210, 176, 70))
        for k in range(x + 2, x1 - 1, 3):
            R.px(k, y1, (190, 150, 50))
        R.rect(x + w // 2 - 4, y + 3, x + w // 2 + 3, y + 7, (150, 40, 50))  # el libro grande
        R.line([(x + w // 2, y + 3), (x + w // 2, y + 7)], (230, 200, 120))
        for vx in (x + 4, x1 - 6):  # los floreros
            R.rect(vx, y + 3, vx + 2, y + 7, (200, 190, 170))
            R.px(vx, y + 2, (230, 80, 90))
            R.px(vx + 2, y + 2, (250, 240, 120))
            R.px(vx + 1, y + 1, (230, 80, 90))
    elif kind == "cross":
        cx = x + w // 2
        R.rect(cx - 1, y, cx + 1, y1, (110, 74, 40), True)
        R.rect(x, y + 4, x1, y + 6, (110, 74, 40), True)
        R.px(cx, y + 5, (230, 200, 170))
        R.px(cx, y + 7, (230, 200, 170))
    elif kind == "window_glass":  # vitral: arco, plomo, colores
        R.d.rectangle([x, y + 4, x1, y1], fill=INK)
        R.d.ellipse([x, y, x1, y + 10], fill=INK)
        cols = [(200, 60, 60), (60, 100, 200), (240, 200, 70), (80, 170, 90), (150, 80, 170)]
        for yy in range(y + 2, y1 - 1, 4):
            for xx in range(x + 2, x1 - 1, 4):
                if (xx - x - w / 2) ** 2 / (w / 2) ** 2 + ((yy - y - 5) / 5.0) ** 2 < 1 or yy > y + 5:
                    R.rect(xx, yy, xx + 2, yy + 2, cols[(xx // 4 + yy // 4) % len(cols)])
        R.rect(x + w // 2 - 1, y + 4, x + w // 2, y1 - 2, (250, 240, 200))  # la luz que entra
    elif kind == "candles":  # el velario: la bandeja, los vasitos (las llamas, en el script)
        R.rect(x, y + 6, x1, y + 9, (60, 50, 44), True)
        for k in range(6):
            cx = x + 2 + k * 5
            R.rect(cx, y + 1, cx + 1, y + 5, (240, 236, 220))
            R.px(cx, y + 6, (180, 40, 40))
        R.rect(x1 - 6, y + 10, x1 - 2, y + 12, (90, 70, 40), True)  # la alcancía de las limosnas
        R.px(x1 - 4, y + 10, INK)
    elif kind in ("counter", "desk"):
        top, front = light(WOOD, 0.15), dark(WOOD, 0.1)
        R.rect(x, y, x1, y1, front, True)
        R.rect(x + 1, y + 1, x1 - 1, y + 4, top)
        R.line([(x + 1, y + 1), (x1 - 1, y + 1)], light(top, 0.25))
        for k in range(x + 8, x1 - 2, 14):
            R.line([(k, y + 6), (k, y1 - 1)], dark(front, 0.2))
        if kind == "desk":  # el computador, los papeles, el sello
            mx = x + w // 2 - 7
            R.rect(mx, y - 10, mx + 13, y - 1, (44, 46, 54), True)
            R.rect(mx + 2, y - 8, mx + 11, y - 3, (90, 150, 200))
            R.rect(x + 3, y + 1, x + 9, y + 3, (244, 244, 238))
            R.rect(x1 - 7, y + 1, x1 - 5, y + 3, (60, 40, 40))
        else:
            extra = {"pension": "bell", "veterinaria": "jar", "bano": "paper", "fotos": "photos", "caverna": "snacks"}.get(pid, "bell")
            if extra == "bell":  # el timbre y el libro de huéspedes
                R.ell(x + 4, y + 1, x + 7, y + 3, (220, 200, 120), True)
                R.rect(x + 12, y + 1, x + 20, y + 3, (240, 236, 220))
            elif extra == "jar":  # el frasco de galletas para perro
                R.rect(x + 4, y - 3, x + 9, y + 3, (200, 220, 230), True)
                R.px(x + 6, y, (180, 120, 60))
                R.px(x + 7, y + 1, (180, 120, 60))
            elif extra == "paper":  # los rollos de papel (se cobran aparte) y el platico de las monedas
                for k in range(3):
                    R.ell(x + 3 + k * 5, y, x + 7 + k * 5, y + 3, (244, 244, 240), True)
                R.ell(x1 - 9, y + 1, x1 - 3, y + 3, (200, 200, 210), True)
            elif extra == "photos":
                for k in range(3):
                    R.rect(x + 3 + k * 6, y + 1, x + 7 + k * 6, y + 3, [(240, 200, 120), (200, 220, 240), (240, 240, 236)][k])
            else:  # mecato y la caja
                for k, c in enumerate(((230, 70, 60), (250, 210, 60), (70, 140, 220))):
                    R.rect(x + 3 + k * 4, y, x + 5 + k * 4, y + 3, c)
                R.rect(x1 - 12, y - 2, x1 - 4, y + 3, (60, 60, 70), True)
    elif kind in ("shelf", "shelf_games"):
        R.rect(x, y, x1, y1, dark(WOOD, 0.25), True)
        cols = [(200, 70, 70), (70, 140, 200), (230, 190, 70), (90, 170, 100), (170, 90, 200), (240, 240, 230)]
        for sy in (y + 1, y + h // 2 + 1):
            R.line([(x + 1, sy + h // 2 - 2), (x1 - 1, sy + h // 2 - 2)], light(WOOD, 0.1))
            xx = x + 2
            while xx < x1 - 3:
                bw = 3 if kind == "shelf_games" else R.r.choice((4, 5, 6))
                bh = h // 2 - 3 - (0 if kind == "shelf_games" else R.r.randrange(0, 3))
                c = R.r.choice(cols)
                R.rect(xx, sy + (h // 2 - 3 - bh), xx + bw - 1, sy + h // 2 - 3, c)
                R.px(xx, sy + (h // 2 - 3 - bh), light(c, 0.3))
                xx += bw + (0 if kind == "shelf_games" else 1)
    elif kind == "cage":
        R.rect(x, y, x1, y1, (70, 72, 80), True)
        R.rect(x + 1, y + 1, x1 - 1, y1 - 1, (40, 40, 48))
        animal = R.r.choice(["perro", "gato", "conejo"])
        c = {"perro": (200, 150, 90), "gato": (120, 120, 130), "conejo": (236, 232, 226)}[animal]
        R.ell(x + 5, y1 - 8, x + 15, y1 - 2, c)
        R.ell(x + 12, y1 - 10, x + 17, y1 - 5, c)
        R.px(x + 15, y1 - 8, INK)
        if animal == "conejo":
            R.line([(x + 14, y1 - 10), (x + 14, y1 - 14)], c)
        for k in range(x + 2, x1, 3):
            R.line([(k, y + 1), (k, y1 - 1)], (180, 182, 190))
        R.rect(x + 2, y1 - 3, x + 5, y1 - 2, (90, 140, 220))  # el platico de agua
    elif kind == "poster":
        R.rect(x, y, x1, y1, (240, 236, 220), True)
        txt = {"veterinaria": "VACUNE", "defensoria": "DERECHOS", "registraduria": "CEDULA", "caverna": "GAME"}.get(pid, "")
        if pid == "veterinaria":  # el perro feliz de la vacuna
            R.ell(x + 6, y + 4, x + 18, y + 12, (210, 150, 90))
            R.px(x + 9, y + 7, INK)
            R.px(x + 14, y + 7, INK)
        elif pid == "caverna":  # el de la nave
            R.rect(x + 2, y + 2, x1 - 2, y + 12, (30, 20, 60))
            R.d.polygon([(x + w // 2, y + 4), (x + w // 2 - 4, y + 11), (x + w // 2 + 4, y + 11)], fill=(230, 80, 80))
            for k in range(5):
                R.px(x + 3 + k * 4, y + 3 + (k * 3) % 8, (250, 250, 250))
        else:  # el escudo y unas líneas
            R.ell(x + w // 2 - 4, y + 3, x + w // 2 + 4, y + 11, (240, 200, 60))
            R.rect(x + w // 2 - 2, y + 5, x + w // 2 + 2, y + 9, (50, 90, 170))
        draw_text(R, txt, x + 2, y1 - 6, (60, 50, 60))
    elif kind == "keys":  # el tablero de las llaves, con número
        R.rect(x, y, x1, y1, WOOD, True)
        for k in range(8):
            kx, ky = x + 3 + (k % 4) * 8, y + 3 + (k // 4) * 8
            R.px(kx, ky, (200, 200, 200))
            if k not in (2, 5):  # dos llaves no están: alguien se quedó
                R.rect(kx, ky + 1, kx + 1, ky + 4, (230, 200, 80))
                R.px(kx + 2, ky + 4, (200, 60, 60))
    elif kind == "door":
        R.rect(x, y, x1, y1, dark(WOOD, 0.1), True)
        R.rect(x + 2, y + 2, x1 - 2, y + h // 2 - 1, dark(WOOD, 0.2))
        R.rect(x + 2, y + h // 2 + 1, x1 - 2, y1 - 2, dark(WOOD, 0.2))
        R.px(x1 - 3, y + h // 2, (230, 200, 80))
        n = {16: "1", 44: "2", 72: "4"}.get(x, "3")  # el 3 no existe: es de mala suerte en esta pensión
        draw_text(R, n, x + w // 2 - 1, y + 3, (230, 200, 80))
    elif kind == "tv":  # el televisor de tubo, en su mesita (la pantalla: el script)
        R.rect(x - 1, y1 - 2, x1 + 1, y1 + 3, WOOD, True)
        R.rect(x, y, x1, y1, (40, 40, 46), True)
        R.line([(x + 4, y), (x + 1, y - 5)], (150, 150, 160))
        R.line([(x1 - 4, y), (x1 - 1, y - 5)], (150, 150, 160))
    elif kind == "chair":  # la poltrona
        R.rect(x, y, x1, y1, (150, 70, 60), True)
        R.rect(x + 1, y + 1, x1 - 1, y + 4, dark((150, 70, 60), 0.25))
        R.rect(x + 3, y + 5, x1 - 3, y1 - 2, light((150, 70, 60), 0.12))
        R.rect(x + 5, y + 6, x + 8, y + 8, (240, 236, 220))  # el tapetico tejido
    elif kind == "rug":
        R.rect(x, y, x1, y1, (150, 40, 50))
        R.rect(x + 2, y + 2, x1 - 2, y1 - 2, (150, 40, 50), outline=False)
        R.d.rectangle([x + 2, y + 2, x1 - 2, y1 - 2], outline=(200, 160, 70))
        for yy in range(y + 6, y1 - 4, 8):
            R.d.polygon([(x + w // 2, yy - 2), (x + w // 2 + 3, yy), (x + w // 2, yy + 2), (x + w // 2 - 3, yy)], fill=(200, 160, 70))
        for k in range(x, x1 + 1, 2):
            R.px(k, y - 1, (220, 200, 160))
            R.px(k, y1 + 1, (220, 200, 160))
    elif kind == "stall":  # el cubículo: la puerta, el pestillo (rojo: ocupado)
        R.rect(x, y, x1, y1, (110, 130, 140), True)
        R.rect(x + 3, y + 6, x1 - 3, y1, (90, 110, 124), True)
        R.rect(x1 - 7, y + h // 2, x1 - 5, y + h // 2 + 2, (200, 60, 60) if x % 3 else (60, 170, 80))
        R.line([(x + 6, y + 10), (x + 12, y + 12)], (40, 40, 50))  # lo que escribieron en la puerta
        R.line([(x + 6, y + 14), (x + 10, y + 14)], (40, 40, 50))
    elif kind == "sink":  # el lavamanos y el espejo (manchado) encima
        R.rect(x + 1, y - 10, x1 - 1, y - 3, (180, 200, 210), True)
        R.px(x + 4, y - 8, (240, 250, 255))
        R.px(x1 - 4, y - 5, (140, 150, 160))
        R.ell(x, y, x1, y1, (240, 242, 246), True)
        R.ell(x + 3, y + 3, x1 - 3, y1 - 3, (190, 200, 210))
        R.rect(x + w // 2 - 1, y - 2, x + w // 2, y + 2, (160, 164, 176))
    elif kind == "screen":  # la pantalla del turno (el número, el script)
        R.rect(x, y, x1, y1, (24, 22, 28), True)
        R.rect(x + 1, y + 1, x1 - 1, y + 2, (60, 60, 70))
    elif kind == "rope":  # los parales dorados y el cordón rojo, colgando
        R.rect(x - 2, y - 8, x, y + 3, (220, 190, 80), True)
        R.rect(x + w - 1, y - 8, x + w + 1, y + 3, (220, 190, 80), True)
        pts = [(x + k, y - 5 + int(3 * (1 - ((k - w / 2) / (w / 2)) ** 2))) for k in range(0, w, 2)]
        R.line(pts, (180, 30, 50), 2)
    elif kind == "photo_booth":  # la cabina de fotos (la cortina, la ranura)
        R.rect(x, y, x1, y1, (60, 64, 80), True)
        R.rect(x + 3, y + 6, x1 - 3, y1 - 2, (180, 40, 60))
        for k in range(x + 5, x1 - 3, 3):
            R.line([(k, y + 6), (k, y1 - 2)], dark((180, 40, 60), 0.25))
        draw_text(R, "FOTO", x + 4, y + 1, (250, 220, 90))
    elif kind == "backdrop":  # el telón de las fotos de grado, con nubes
        R.rect(x, y, x1, y1, (90, 130, 190), True)
        for _ in range(18):
            cx, cy = R.r.randrange(x + 3, x1 - 3), R.r.randrange(y + 3, y1 - 8)
            R.ell(cx - 4, cy - 2, cx + 4, cy + 2, (120, 160, 210))
        R.rect(x, y1 - 6, x1, y1, (70, 100, 160), True)
    elif kind == "camera":  # el trípode y la cámara
        R.line([(x + w // 2, y + 6), (x, y1)], INK)
        R.line([(x + w // 2, y + 6), (x1, y1)], INK)
        R.line([(x + w // 2, y + 6), (x + w // 2, y1)], INK)
        R.rect(x, y, x1, y + 6, (40, 40, 46), True)
        R.ell(x + w // 2 - 2, y + 1, x + w // 2 + 2, y + 5, (90, 120, 160))
    elif kind == "frames":  # las fotos de muestra: un matrimonio, un bebé, una primera comunión, un perro
        for k in range(4):
            fx0 = x + k * w // 4 + 1
            fy0 = y + (k % 2) * 4
            fx1, fy1 = fx0 + w // 4 - 3, fy0 + h - 6
            R.rect(fx0, fy0, fx1, fy1, (200, 160, 80), True)
            R.rect(fx0 + 2, fy0 + 2, fx1 - 2, fy1 - 2, [(220, 220, 230), (240, 210, 200), (250, 250, 250), (200, 220, 200)][k])
            R.ell(fx0 + 3, fy0 + 4, fx0 + 6, fy0 + 7, (210, 160, 130))
            if k == 3:
                R.ell(fx0 + 3, fy1 - 7, fx1 - 3, fy1 - 3, (180, 120, 60))
    elif kind == "lamp_stand":  # la sombrilla de luz
        R.line([(x + w // 2, y + 8), (x + w // 2, y1)], INK)
        R.line([(x + w // 2, y1), (x, y1 + 2)], INK)
        R.line([(x + w // 2, y1), (x1, y1 + 2)], INK)
        R.d.polygon([(x - 2, y + 8), (x + w // 2, y), (x1 + 2, y + 8)], fill=(244, 244, 240), outline=INK)
    elif kind == "plant":
        R.rect(x + 1, y1 - 5, x1 - 1, y1, (170, 90, 60), True)
        for k, (dx, dy) in enumerate(((0, -12), (-4, -8), (4, -9), (-2, -4), (3, -4))):
            cx, cy = x + w // 2 + dx, y1 - 4 + dy
            R.ell(cx - 3, cy - 3, cx + 3, cy + 3, (60, 130, 70) if k % 2 else (80, 150, 86))
    elif kind == "arcade":  # la maquinita: el aviso, la pantalla (el script), los controles
        R.rect(x, y, x1, y1, (50, 36, 80), True)
        R.rect(x + 1, y + 1, x1 - 1, y + 3, (240, 100, 180))
        R.rect(x + 2, y + 4, x1 - 2, y + 16, (20, 16, 30))
        R.rect(x + 1, y + 18, x1 - 1, y + 24, (80, 60, 110), True)
        R.px(x + 5, y + 20, (240, 70, 70))
        R.px(x + 11, y + 20, (70, 120, 240))
        R.px(x + 14, y + 21, (250, 220, 60))
        R.line([(x + 4, y + 22), (x + 4, y + 19)], INK)
        R.rect(x + 7, y + 27, x + 12, y + 30, (30, 24, 40))  # la ranura de las monedas
        R.px(x + 9, y + 28, (240, 80, 60))


def draw_text(R, s, x, y, c):
    from draw_relleno import GLYPH
    GLYPH = dict(GLYPH, F=["111", "100", "110", "100", "100"], **{"4": ["101", "101", "111", "001", "001"]})
    cx = x
    for ch in s:
        g = GLYPH.get(ch, GLYPH[" "])
        if ch == "N":
            g = g + ["1001"]
        for j, row in enumerate(g):
            for i, v in enumerate(row):
                if v == "1":
                    R.px(cx + i, y + j, c)
        cx += len(g[0]) + 1


def cat(R, at):
    """El gato de Al, dormido (es el único cliente fijo)."""
    x, y = at
    c = (220, 140, 70)
    R.ell(x - 6, y - 5, x + 4, y + 1, c, True)
    R.ell(x + 2, y - 7, x + 8, y - 2, c, True)
    R.px(x + 3, y - 8, c)
    R.px(x + 7, y - 8, c)
    R.line([(x + 4, y - 4), (x + 5, y - 4)], INK)
    R.line([(x - 6, y - 1), (x - 9, y + 2)], c)
    for k in range(-4, 3, 3):
        R.px(x + k, y - 4, dark(c, 0.2))


def build():
    os.makedirs(OUT, exist_ok=True)
    import sys
    sys.path.insert(0, os.path.dirname(__file__))
    for pid, P in places().items():
        R = Room(P["w"], P["h"], hash(pid) % 1000)
        R.r = random.Random(sum(map(ord, pid)))
        floor_and_walls(R, P, pid)
        # Primero lo del piso de atrás para adelante (los de arriba quedan detrás).
        for p in sorted(P["props"], key=lambda q: (q[0] != "rug", q[2] + q[4])):
            prop(R, p[0], p[1], p[2], p[3], p[4], pid)
        if P["cat"]:
            cat(R, P["cat"])
        R.im.save(os.path.join(OUT, pid + ".png"))
        print("ok", pid, len(P["props"]), "muebles")


if __name__ == "__main__":
    build()
