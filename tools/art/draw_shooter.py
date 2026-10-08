"""Arte del SUEÑO 2, "PLOMO" (shooter tipo Doom): texturas de pared, enemigos de frente (cuadros
de caminar, atacar, dolor, muerto), armas en primera persona, cosas para agarrar y la cara del HUD.
Salida: assets/shooter/*.png
Uso: python tools/art/draw_shooter.py  (desde la carpeta del proyecto)"""
import random
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path("assets/shooter")
OUT.mkdir(parents=True, exist_ok=True)
INK = (24, 16, 28, 255)
random.seed(93)


def outline(img):
    w, h = img.size
    src = img.copy()
    px, out = src.load(), img.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != INK:
                        out[x, y] = INK
                        break
    return img


def jit(c, k=14):
    return tuple(max(0, min(255, v + random.randint(-k, k))) for v in c[:3]) + (255,)


# ------------------------------------------------------------------ paredes (32x32)

def wall(name, fn):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 255))
    fn(ImageDraw.Draw(img), img)
    img.save(OUT / f"wall_{name}.png")


def ladrillo(d, img):
    d.rectangle([0, 0, 31, 31], fill=(70, 60, 60, 255))
    for row in range(8):
        off = 0 if row % 2 == 0 else 8
        for col in range(-1, 3):
            x = col * 16 + off
            d.rectangle([x + 1, row * 4 + 1, x + 14, row * 4 + 3], fill=jit((128, 54, 44)))
    for _ in range(30):  # mugre
        d.point((random.randrange(32), random.randrange(18, 32)), fill=(40, 34, 30, 255))


def grafiti(d, img):
    d.rectangle([0, 0, 31, 31], fill=(108, 106, 104, 255))
    for _ in range(60):
        d.point((random.randrange(32), random.randrange(32)), fill=jit((96, 94, 92), 10))
    d.line([(3, 20), (8, 8), (12, 20)], fill=(220, 60, 120, 255), width=2)   # tag
    d.line([(14, 8), (14, 20), (20, 20)], fill=(60, 200, 220, 255), width=2)
    d.ellipse([22, 9, 29, 19], outline=(240, 220, 60, 255), width=2)
    d.line([(0, 28), (31, 28)], fill=(70, 70, 70, 255))


def zinc(d, img):
    for x in range(32):
        v = 150 if x % 4 < 2 else 112
        d.line([(x, 0), (x, 31)], fill=(v, v + 4, v + 10, 255))
    for _ in range(12):
        x, y = random.randrange(32), random.randrange(32)
        d.rectangle([x, y, x + 2, y + 1], fill=(130, 80, 50, 255))  # óxido


def madera(d, img):
    for y in range(0, 32, 8):
        d.rectangle([0, y, 31, y + 7], fill=jit((120, 86, 54)))
        d.line([(0, y + 7), (31, y + 7)], fill=(70, 48, 30, 255))
        d.point([(4, y + 3), (27, y + 4)], fill=(60, 40, 24, 255))


def oro(d, img):
    d.rectangle([0, 0, 31, 31], fill=(170, 130, 40, 255))
    for x in range(0, 32, 16):
        for y in range(0, 32, 16):
            d.rectangle([x + 1, y + 1, x + 14, y + 14], fill=(214, 172, 60, 255))
            d.rectangle([x + 4, y + 4, x + 11, y + 11], fill=(236, 200, 90, 255))
            d.line([(x + 6, y + 5), (x + 6, y + 10), (x + 9, y + 10)], fill=(150, 100, 30, 255))  # una L


def puerta(d, img):
    d.rectangle([0, 0, 31, 31], fill=(90, 96, 104, 255))
    d.rectangle([3, 2, 28, 31], fill=(120, 128, 136, 255))
    for y in range(6, 30, 6):
        d.line([(4, y), (27, y)], fill=(96, 102, 110, 255))
    d.rectangle([22, 15, 25, 17], fill=(200, 196, 180, 255))


def puerta_llave(d, img):
    puerta(d, img)
    d.rectangle([12, 12, 19, 20], fill=(200, 40, 40, 255))
    d.rectangle([14, 14, 17, 17], fill=(250, 220, 80, 255))


def salida(d, img):
    ladrillo(d, img)
    d.rectangle([4, 8, 27, 16], fill=(30, 140, 60, 255))
    d.rectangle([5, 9, 26, 15], fill=(60, 200, 90, 255))
    for x in range(7, 25, 4):  # "SALIDA" sugerido
        d.rectangle([x, 11, x + 2, 13], fill=(240, 255, 240, 255))


# ------------------------------------------------------------------ figuras (32x48, de frente)

def figure(spec, pose):
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    skin, hair, shirt, pants = spec["skin"], spec["hair"], spec["shirt"], spec["pants"]
    if pose == "dead":
        d.ellipse([2, 40, 30, 47], fill=(90, 10, 14, 220))          # charco
        d.rectangle([4, 38, 26, 44], fill=shirt)
        d.rectangle([20, 39, 30, 43], fill=pants)
        d.ellipse([0, 37, 8, 45], fill=skin)
        d.rectangle([0, 37, 8, 39], fill=hair)
        return outline(img)
    lean = {"walk1": 0, "walk2": 0, "attack": 0, "hurt": 2}[pose]
    # piernas
    if pose == "walk1":
        d.rectangle([10, 34, 14, 47], fill=pants); d.rectangle([18, 32, 22, 45], fill=pants)
    elif pose == "walk2":
        d.rectangle([10, 32, 14, 45], fill=pants); d.rectangle([18, 34, 22, 47], fill=pants)
    else:
        d.rectangle([10, 33, 14, 47], fill=pants); d.rectangle([18, 33, 22, 47], fill=pants)
    # cuerpo
    d.rectangle([8 + lean, 17, 24 + lean, 34], fill=shirt)
    if spec.get("backpack"):
        d.rectangle([4 + lean, 12, 28 + lean, 30], fill=spec["backpack"])
        d.rectangle([6 + lean, 18, 26 + lean, 22], fill=(250, 240, 220, 255))
    if spec.get("chains"):
        d.line([(11 + lean, 18), (16 + lean, 24), (21 + lean, 18)], fill=(250, 210, 60, 255), width=1)
        d.line([(10 + lean, 19), (16 + lean, 27), (22 + lean, 19)], fill=(250, 210, 60, 255), width=1)
    # brazos
    if pose == "attack":
        d.rectangle([4 + lean, 18, 8 + lean, 26], fill=shirt)
        d.rectangle([14, 22, 18, 28], fill=skin)          # mano al frente
        if spec.get("weapon") == "gun":
            d.rectangle([13, 24, 19, 30], fill=(30, 30, 34, 255))
            d.ellipse([12, 26, 20, 34], fill=(255, 220, 90, 255))   # fogonazo
        elif spec.get("weapon") == "knife":
            d.polygon([(16, 14), (18, 24), (14, 24)], fill=(220, 224, 230, 255))
        elif spec.get("weapon") == "throw":
            d.rectangle([22 + lean, 8, 28 + lean, 16], fill=spec.get("backpack", shirt))
        elif spec.get("weapon") == "whistle":
            d.rectangle([14, 13, 17, 15], fill=(200, 200, 210, 255))
        if spec.get("dual"):
            d.rectangle([4, 22, 10, 30], fill=(30, 30, 34, 255))
            d.ellipse([2, 26, 10, 34], fill=(255, 220, 90, 255))
    else:
        d.rectangle([4 + lean, 18, 8 + lean, 30], fill=shirt)
        d.rectangle([24 + lean, 18, 28 + lean, 30], fill=shirt)
        d.rectangle([4 + lean, 30, 8 + lean, 33], fill=skin)
        d.rectangle([24 + lean, 30, 28 + lean, 33], fill=skin)
        if spec.get("weapon") == "knife":
            d.polygon([(26 + lean, 33), (27 + lean, 40), (25 + lean, 40)], fill=(220, 224, 230, 255))
        if spec.get("weapon") == "gun" or spec.get("dual"):
            d.rectangle([24 + lean, 32, 29 + lean, 36], fill=(30, 30, 34, 255))
        if spec.get("dual"):
            d.rectangle([3 + lean, 32, 8 + lean, 36], fill=(30, 30, 34, 255))
    # cabeza
    d.rectangle([11 + lean, 4, 21 + lean, 16], fill=skin)
    if spec.get("helmet"):
        d.rectangle([9 + lean, 1, 23 + lean, 11], fill=spec["helmet"])
        d.rectangle([11 + lean, 7, 21 + lean, 10], fill=(40, 50, 60, 255))  # visera
    elif spec.get("cap"):
        d.rectangle([10 + lean, 2, 22 + lean, 6], fill=spec["cap"])
        d.rectangle([10 + lean, 6, 25 + lean, 7], fill=spec["cap"])
    else:
        d.rectangle([10 + lean, 1, 22 + lean, 6], fill=hair)
        if spec.get("long_hair"):
            d.rectangle([8 + lean, 4, 11 + lean, 22], fill=hair)
            d.rectangle([21 + lean, 4, 24 + lean, 22], fill=hair)
    if not spec.get("helmet"):
        if spec.get("glasses"):
            d.rectangle([12 + lean, 8, 20 + lean, 10], fill=(20, 20, 24, 255))
        else:
            d.point([(13 + lean, 9), (18 + lean, 9)], fill=INK)
        d.line([(14 + lean, 13), (18 + lean, 13)], fill=(120, 50, 50, 255))
    if spec.get("hood"):
        d.rectangle([9 + lean, 2, 10 + lean, 16], fill=shirt)
        d.rectangle([22 + lean, 2, 23 + lean, 16], fill=shirt)
        d.rectangle([9 + lean, 0, 23 + lean, 3], fill=shirt)
    img = outline(img)
    if pose == "hurt":
        r = Image.new("RGBA", img.size, (255, 40, 40, 0))
        px = img.load()
        for y in range(img.height):
            for x in range(img.width):
                c = px[x, y]
                if c[3]:
                    px[x, y] = (min(255, c[0] + 90), c[1] // 2, c[2] // 2, c[3])
    return img


ENEMIES = {
    "jibaro": {"skin": (170, 120, 90, 255), "hair": (30, 26, 28, 255), "shirt": (60, 64, 76, 255),
               "pants": (40, 44, 60, 255), "hood": True, "weapon": "knife"},
    "campanero": {"skin": (190, 140, 100, 255), "hair": (30, 26, 28, 255), "shirt": (220, 200, 60, 255),
                  "pants": (60, 90, 140, 255), "cap": (200, 50, 50, 255), "weapon": "whistle"},
    "motorizado": {"skin": (180, 130, 100, 255), "hair": (30, 26, 28, 255), "shirt": (34, 34, 40, 255),
                   "pants": (50, 50, 60, 255), "helmet": (40, 40, 46, 255), "weapon": "gun"},
    "rappi": {"skin": (180, 130, 100, 255), "hair": (30, 26, 28, 255), "shirt": (240, 120, 40, 255),
              "pants": (40, 44, 60, 255), "helmet": (240, 120, 40, 255), "backpack": (240, 130, 40, 255), "weapon": "throw"},
    "lilato": {"skin": (220, 170, 140, 255), "hair": (30, 20, 24, 255), "shirt": (170, 40, 60, 255),
               "pants": (150, 30, 50, 255), "long_hair": True, "weapon": "knife"},
    "lisandro": {"skin": (190, 140, 110, 255), "hair": (20, 18, 20, 255), "shirt": (236, 232, 222, 255),
                 "pants": (226, 222, 212, 255), "glasses": True, "chains": True, "weapon": "gun", "dual": True},
}
SCALE = {"lilato": 1.2, "lisandro": 1.6}


def enemies():
    for name, spec in ENEMIES.items():
        for pose in ["walk1", "walk2", "attack", "hurt", "dead"]:
            img = figure(spec, pose)
            k = SCALE.get(name, 1.0)
            if k != 1.0:
                img = img.resize((int(32 * k), int(48 * k)), Image.NEAREST)
            img.save(OUT / f"{name}_{pose}.png")


# ------------------------------------------------------------------ cosas sueltas

def sprite(name, size, fn):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    fn(ImageDraw.Draw(img))
    outline(img).save(OUT / f"{name}.png")


def things():
    sprite("balas", (16, 12), lambda d: (d.rectangle([1, 3, 14, 11], fill=(110, 90, 50, 255)),
                                       d.rectangle([3, 1, 5, 4], fill=(220, 180, 60, 255)),
                                       d.rectangle([7, 1, 9, 4], fill=(220, 180, 60, 255)),
                                       d.rectangle([11, 1, 13, 4], fill=(220, 180, 60, 255))))
    sprite("cartuchos", (16, 12), lambda d: (d.rectangle([1, 4, 14, 11], fill=(150, 40, 40, 255)),
                                           d.rectangle([3, 1, 6, 6], fill=(200, 50, 50, 255)),
                                           d.rectangle([9, 1, 12, 6], fill=(200, 50, 50, 255)),
                                           d.rectangle([3, 1, 6, 2], fill=(220, 180, 60, 255)),
                                           d.rectangle([9, 1, 12, 2], fill=(220, 180, 60, 255))))
    sprite("chaleco", (16, 16), lambda d: (d.polygon([(3, 2), (6, 2), (8, 5), (10, 2), (13, 2), (14, 15), (2, 15)], fill=(50, 70, 50, 255)),
                                         d.rectangle([5, 8, 11, 12], fill=(70, 96, 70, 255))))
    sprite("llave", (16, 10), lambda d: (d.ellipse([0, 1, 7, 8], fill=(250, 210, 60, 255)),
                                       d.ellipse([2, 3, 5, 6], fill=(0, 0, 0, 0)),
                                       d.rectangle([6, 4, 15, 5], fill=(250, 210, 60, 255)),
                                       d.rectangle([12, 5, 13, 8], fill=(250, 210, 60, 255))))
    sprite("escopeta", (32, 10), lambda d: (d.rectangle([0, 3, 22, 5], fill=(60, 60, 66, 255)),
                                          d.rectangle([18, 2, 31, 8], fill=(120, 80, 50, 255)),
                                          d.rectangle([8, 5, 14, 7], fill=(120, 80, 50, 255))))
    sprite("pedido", (12, 12), lambda d: (d.rectangle([1, 2, 10, 11], fill=(240, 130, 40, 255)),
                                        d.rectangle([3, 5, 8, 7], fill=(250, 240, 220, 255))))
    sprite("cuchillo", (12, 12), lambda d: (d.polygon([(1, 10), (9, 2), (11, 1), (10, 3), (3, 11)], fill=(220, 224, 230, 255)),
                                          d.rectangle([0, 9, 3, 11], fill=(60, 40, 30, 255))))
    sprite("caneca", (16, 22), lambda d: (d.rectangle([2, 2, 13, 21], fill=(60, 90, 60, 255)),
                                        d.line([(2, 8), (13, 8)], fill=(40, 60, 40, 255)),
                                        d.line([(2, 15), (13, 15)], fill=(40, 60, 40, 255)),
                                        d.ellipse([2, 0, 13, 4], fill=(80, 110, 80, 255))))
    for it in ["empanada", "aguapanela"]:
        src = Image.open(f"assets/items/{it}.png")
        src.save(OUT / f"{it}.png")


# ------------------------------------------------------------------ armas (primera persona, 80x56)

SKIN = (214, 160, 120, 255)
SLEEVE = (232, 228, 220, 255)


def weapon(name, fn):
    for fire in (False, True):
        img = Image.new("RGBA", (80, 56), (0, 0, 0, 0))
        fn(ImageDraw.Draw(img), fire)
        outline(img).save(OUT / f"w_{name}{'_fire' if fire else ''}.png")


def puno(d, fire):
    y = 18 if fire else 30
    d.rectangle([44, y + 12, 62, 56], fill=SLEEVE)
    d.rectangle([40, y, 64, y + 16], fill=SKIN)
    for k in range(4):
        d.line([(42 + k * 6, y + 2), (42 + k * 6, y + 8)], fill=(180, 120, 90, 255))


def pistola(d, fire):
    d.rectangle([36, 36, 54, 56], fill=SLEEVE)
    d.rectangle([34, 28, 52, 42], fill=SKIN)
    d.rectangle([36, 14, 46, 30], fill=(40, 40, 46, 255))
    d.rectangle([38, 10, 44, 14], fill=(60, 60, 66, 255))
    if fire:
        d.ellipse([30, -2, 52, 14], fill=(255, 210, 80, 255))
        d.ellipse([36, 2, 46, 10], fill=(255, 250, 200, 255))


def escopeta_w(d, fire):
    d.rectangle([22, 40, 40, 56], fill=SLEEVE)
    d.rectangle([44, 44, 60, 56], fill=SLEEVE)
    d.rectangle([30, 10, 46, 52], fill=(110, 76, 46, 255))
    d.rectangle([33, 0, 38, 30], fill=(56, 56, 62, 255))
    d.rectangle([39, 0, 44, 30], fill=(56, 56, 62, 255))
    d.rectangle([26, 34, 34, 44], fill=SKIN)
    d.rectangle([44, 38, 52, 48], fill=SKIN)
    if fire:
        d.ellipse([24, -10, 54, 10], fill=(255, 200, 70, 255))
        d.ellipse([30, -6, 48, 4], fill=(255, 250, 200, 255))


# ------------------------------------------------------------------ la cara del HUD (24x26)

def face(level, hurt=False, grin=False):
    img = Image.new("RGBA", (24, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 3, 20, 24], fill=(214, 160, 120, 255))
    d.rectangle([2, 0, 21, 6], fill=(30, 28, 34, 255))         # pelo
    d.rectangle([2, 6, 3, 12], fill=(30, 28, 34, 255))
    d.rectangle([20, 6, 21, 12], fill=(30, 28, 34, 255))
    blood = [(0, 0)] * (4 - level)
    eye_y = 11
    if hurt:
        d.line([(6, eye_y), (9, eye_y)], fill=INK); d.line([(14, eye_y), (17, eye_y)], fill=INK)
        d.ellipse([9, 17, 14, 22], fill=(80, 30, 30, 255))
    else:
        d.rectangle([6, eye_y - 1, 8, eye_y + 1], fill=(250, 250, 250, 255)); d.point((7, eye_y), fill=INK)
        d.rectangle([15, eye_y - 1, 17, eye_y + 1], fill=(250, 250, 250, 255)); d.point((16, eye_y), fill=INK)
        if grin:
            d.rectangle([7, 18, 16, 20], fill=(250, 250, 250, 255)); d.line([(7, 18), (16, 18)], fill=INK)
        else:
            d.line([(8, 19), (15, 19)] if level >= 2 else [(8, 20), (11, 19), (15, 20)], fill=(120, 50, 50, 255))
    d.rectangle([9, 21, 14, 24], fill=(40, 34, 38, 200))       # barba
    for i in range(4 - level):  # golpes y sangre según la vida
        x, y = [(4, 4), (16, 14), (6, 16), (18, 6)][i]
        d.rectangle([x, y, x + 2, y + 4], fill=(170, 30, 30, 255))
    return outline(img)


if __name__ == "__main__":
    for n, f in [("ladrillo", ladrillo), ("grafiti", grafiti), ("zinc", zinc), ("madera", madera), ("oro", oro),
                 ("puerta", puerta), ("puerta_llave", puerta_llave), ("salida", salida)]:
        wall(n, f)
    enemies()
    things()
    weapon("puno", puno)
    weapon("pistola", pistola)
    weapon("escopeta", escopeta_w)
    for lv in range(5):
        face(lv).save(OUT / f"face_{lv}.png")
    face(2, hurt=True).save(OUT / "face_hurt.png")
    face(4, grin=True).save(OUT / "face_grin.png")
    print("listo")
