"""PLOMO 1 visto con ojos de niño: él tiene unos diez años y pelea contra demonios con pistola.
Todo dibujado como con crayón: paredes de papel con garabatos, demonios de dibujo infantil
(cuernos, colita, ojos amarillos), su mano chiquita con manga de rayas, y su cara en el HUD
(en vez de sangre, curitas y lágrimas).
Salida: assets/shooter/wall_kid_*.png, kid_<enemigo>_<pose>.png, kw_<arma>[_fire].png, kidface_*.png
Uso: python tools/art/draw_shooter_kid.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw
import draw_shooter as base
from draw_shooter import OUT, INK, outline, figure

random.seed(10)
PAPER = (236, 226, 200)
CRAYON_INK = (40, 30, 50, 255)


def crayon(img, amount=0.18):
    """Textura de crayón: puntitos de papel que se asoman entre el color."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a and random.random() < amount:
                px[x, y] = (min(255, r + 40), min(255, g + 36), min(255, b + 30), a)
    return img


def wobbly_line(d, pts, fill, width=1):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        d.line([(x0 + random.randint(-1, 1), y0 + random.randint(-1, 1)), (x1, y1)], fill=fill, width=width)


def kid_wall(name, fn):
    img = Image.new("RGBA", (32, 32), PAPER + (255,))
    d = ImageDraw.Draw(img)
    fn(d)
    crayon(img).save(OUT / f"wall_kid_{name}.png")


def k_ladrillo(d):
    for row in range(5):
        off = 0 if row % 2 == 0 else 7
        for col in range(-1, 3):
            x, y = col * 14 + off, row * 6 + 2
            d.rectangle([x + 1, y, x + 12, y + 4], fill=(200, 70, 60))
            wobbly_line(d, [(x + 1, y), (x + 12, y), (x + 12, y + 4), (x + 1, y + 4), (x + 1, y)], CRAYON_INK)


def k_dibujos(d):
    """Pared con los dibujos que haría él: un sol, una casita, una familia de palitos."""
    d.ellipse([2, 2, 10, 10], fill=(250, 200, 40))
    for a in range(0, 360, 45):
        import math
        x, y = 6 + math.cos(math.radians(a)) * 8, 6 + math.sin(math.radians(a)) * 8
        d.line([(6 + math.cos(math.radians(a)) * 5, 6 + math.sin(math.radians(a)) * 5), (x, y)], fill=(250, 170, 30))
    d.polygon([(16, 14), (22, 8), (28, 14)], fill=(200, 60, 60))
    d.rectangle([17, 14, 27, 22], fill=(240, 200, 120))
    d.rectangle([21, 17, 23, 22], fill=(120, 70, 40))
    for i, x in enumerate([4, 9, 14]):  # familia de palitos (uno más chiquito)
        h = 8 if i < 2 else 5
        d.ellipse([x - 1, 31 - h - 4, x + 2, 31 - h - 1], outline=CRAYON_INK)
        d.line([(x, 31 - h - 1), (x, 29)], fill=CRAYON_INK)
        d.line([(x - 2, 31 - h + 2), (x + 2, 31 - h + 2)], fill=CRAYON_INK)
    d.line([(0, 30), (31, 30)], fill=(80, 160, 70), width=2)


def k_azul(d):
    for k in range(0, 40, 3):
        wobbly_line(d, [(k - 8, 0), (k, 31)], (70, 110, 200), 2)


def k_cafe(d):
    for y in range(0, 32, 8):
        d.rectangle([0, y, 31, y + 6], fill=(150, 100, 60))
        wobbly_line(d, [(0, y + 7), (31, y + 7)], CRAYON_INK)


def k_estrellas(d):
    d.rectangle([0, 0, 31, 31], fill=(250, 220, 90))
    for x, y in [(6, 6), (22, 8), (12, 20), (26, 24)]:
        d.polygon([(x, y - 4), (x + 1, y - 1), (x + 4, y), (x + 1, y + 1), (x, y + 4), (x - 1, y + 1), (x - 4, y), (x - 1, y - 1)],
                  fill=(240, 150, 40))


def k_puerta(d):
    d.rectangle([4, 2, 27, 31], fill=(160, 100, 60))
    wobbly_line(d, [(4, 2), (27, 2), (27, 31), (4, 31), (4, 2)], CRAYON_INK)
    d.ellipse([21, 16, 24, 19], fill=(250, 210, 60))


def k_puerta_llave(d):
    k_puerta(d)
    d.rectangle([12, 10, 19, 18], fill=(220, 50, 50))
    d.ellipse([14, 12, 17, 15], fill=(250, 210, 60))


def k_salida(d):
    d.rectangle([2, 8, 29, 22], fill=(80, 190, 90))
    wobbly_line(d, [(6, 15), (22, 15)], (250, 250, 250), 2)
    d.polygon([(20, 10), (27, 15), (20, 20)], fill=(250, 250, 250))


# ------------------------------------------------------------------ demonios de dibujo infantil

DEMONS = {
    # sobre el mismo cuerpo de figure(): piel de demonio, cuernos, colita, ojos amarillos.
    "jibaro": {"skin": (220, 70, 60, 255), "hair": (60, 20, 30, 255), "shirt": (80, 60, 110, 255),
               "pants": (60, 40, 80, 255), "weapon": "knife", "horns": (250, 240, 220, 255)},
    "campanero": {"skin": (110, 190, 90, 255), "hair": (40, 80, 40, 255), "shirt": (240, 200, 60, 255),
                  "pants": (80, 120, 200, 255), "cap": (220, 60, 60, 255), "weapon": "whistle", "horns": (250, 240, 220, 255)},
    "motorizado": {"skin": (150, 70, 170, 255), "hair": (40, 20, 50, 255), "shirt": (40, 40, 50, 255),
                   "pants": (50, 50, 60, 255), "helmet": (40, 40, 50, 255), "weapon": "gun", "horns": (250, 240, 220, 255)},
    "rappi": {"skin": (230, 120, 50, 255), "hair": (60, 30, 20, 255), "shirt": (240, 120, 40, 255),
              "pants": (60, 50, 70, 255), "helmet": (240, 120, 40, 255), "backpack": (240, 130, 40, 255), "weapon": "throw",
              "horns": (250, 240, 220, 255)},
    "lilato": {"skin": (220, 170, 140, 255), "hair": (30, 20, 24, 255), "shirt": (170, 40, 60, 255),
               "pants": (150, 30, 50, 255), "long_hair": True, "weapon": "knife", "horns": (200, 40, 50, 255)},
    "lisandro": {"skin": (210, 50, 50, 255), "hair": (40, 10, 10, 255), "shirt": (236, 232, 222, 255),
                 "pants": (226, 222, 212, 255), "glasses": True, "chains": True, "weapon": "gun", "dual": True,
                 "horns": (40, 20, 20, 255)},
}
SCALE = {"lilato": 1.2, "lisandro": 1.7}


def demon(spec, pose):
    img = figure(spec, pose)
    d = ImageDraw.Draw(img)
    if pose != "dead":
        lean = 2 if pose == "hurt" else 0
        hc = spec["horns"]
        top = 1 if not spec.get("helmet") else -1
        d.polygon([(10 + lean, top + 4), (8 + lean, top - 1 + 1), (12 + lean, top + 2)], fill=hc)   # cuernos
        d.polygon([(22 + lean, top + 4), (24 + lean, top), (20 + lean, top + 2)], fill=hc)
        if not spec.get("helmet"):
            d.rectangle([12 + lean, 8, 14 + lean, 10], fill=(255, 230, 60, 255))  # ojos amarillos
            d.rectangle([18 + lean, 8, 20 + lean, 10], fill=(255, 230, 60, 255))
        d.line([(24, 32), (29, 36), (28, 40)], fill=spec["skin"], width=2)      # colita
        d.polygon([(27, 39), (30, 40), (28, 42)], fill=spec["skin"])
    img = outline(img)
    return crayon(img, 0.1)


def demons():
    for name, spec in DEMONS.items():
        for pose in ["walk1", "walk2", "attack", "hurt", "dead"]:
            img = demon(spec, pose)
            k = SCALE.get(name, 1.0)
            if k != 1.0:
                img = img.resize((int(32 * k), int(48 * k)), Image.NEAREST)
            img.save(OUT / f"kid_{name}_{pose}.png")


# ------------------------------------------------------------------ él, de niño (armas y cara)

KID_SKIN = (232, 180, 140, 255)
STRIPE = [(220, 60, 60, 255), (240, 240, 230, 255)]


def sleeve(d, box):
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1):
        d.line([(x0, y), (x1, y)], fill=STRIPE[(y // 3) % 2])


def kid_weapon(name, fn):
    for fire in (False, True):
        img = Image.new("RGBA", (80, 56), (0, 0, 0, 0))
        fn(ImageDraw.Draw(img), fire)
        crayon(outline(img), 0.08).save(OUT / f"kw_{name}{'_fire' if fire else ''}.png")


def kw_puno(d, fire):
    y = 22 if fire else 34
    sleeve(d, (46, y + 10, 60, 56))
    d.rectangle([43, y, 61, y + 12], fill=KID_SKIN)
    for k in range(3):
        d.line([(46 + k * 5, y + 2), (46 + k * 5, y + 6)], fill=(200, 140, 110, 255))


def kw_pistola(d, fire):
    sleeve(d, (36, 40, 52, 56))
    d.rectangle([35, 32, 50, 44], fill=KID_SKIN)
    d.rectangle([37, 18, 46, 34], fill=(40, 40, 46, 255))
    d.rectangle([38, 14, 45, 18], fill=(240, 120, 40, 255))   # punta naranja: de juguete no es, pero parece
    if fire:
        d.polygon([(41, -2), (46, 8), (52, 2), (48, 12), (34, 12), (30, 2), (36, 8)], fill=(255, 220, 60, 255))
        d.text((32, -2), "PUM", fill=(220, 40, 40, 255))


def kw_escopeta(d, fire):
    sleeve(d, (24, 42, 38, 56))
    sleeve(d, (46, 46, 60, 56))
    d.rectangle([30, 14, 46, 52], fill=(170, 110, 60, 255))
    d.rectangle([33, 2, 38, 30], fill=(80, 80, 90, 255))
    d.rectangle([39, 2, 44, 30], fill=(80, 80, 90, 255))
    d.rectangle([27, 36, 34, 44], fill=KID_SKIN)
    d.rectangle([44, 40, 51, 48], fill=KID_SKIN)
    if fire:
        d.polygon([(39, -10), (46, 0), (56, -6), (50, 6), (28, 6), (22, -6), (32, 0)], fill=(255, 210, 60, 255))
        d.text((26, -8), "BUM", fill=(220, 40, 40, 255))


def kidface(level, hurt=False, grin=False):
    img = Image.new("RGBA", (24, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 3, 21, 25], fill=KID_SKIN)
    d.rectangle([3, 1, 20, 7], fill=(30, 28, 34, 255))
    d.point([(5, 9), (18, 9)], fill=(30, 28, 34, 255))
    for x, y in [(6, 16), (8, 17), (16, 16), (18, 17)]:     # pecas
        d.point((x, y), fill=(190, 120, 90, 255))
    if hurt:
        d.line([(6, 12), (9, 12)], fill=INK); d.line([(14, 12), (17, 12)], fill=INK)
        d.ellipse([9, 18, 14, 22], fill=(90, 30, 40, 255))
    else:
        d.ellipse([5, 9, 10, 14], fill=(250, 250, 250, 255)); d.point((7, 12), fill=INK)
        d.ellipse([13, 9, 18, 14], fill=(250, 250, 250, 255)); d.point((15, 12), fill=INK)
        if grin:
            d.chord([7, 16, 16, 23], 0, 180, fill=(250, 250, 250, 255), outline=INK)
        elif level >= 2:
            d.arc([8, 15, 15, 21], 20, 160, fill=INK)
        else:
            d.arc([8, 18, 15, 24], 200, 340, fill=INK)
    for i in range(4 - level):  # curitas y lágrimas, no sangre: tiene diez años
        if i % 2 == 0:
            x, y = [(3, 5), (15, 18)][i // 2]
            d.rectangle([x, y, x + 6, y + 2], fill=(240, 200, 150, 255))
            d.line([(x + 2, y), (x + 2, y + 2)], fill=(200, 160, 120, 255))
            d.line([(x + 4, y), (x + 4, y + 2)], fill=(200, 160, 120, 255))
        else:
            d.line([(6 if i == 1 else 17, 14), (6 if i == 1 else 17, 18)], fill=(110, 170, 240, 255), width=1)
    return outline(img)


if __name__ == "__main__":
    for n, f in [("ladrillo", k_ladrillo), ("dibujos", k_dibujos), ("azul", k_azul), ("cafe", k_cafe),
                 ("estrellas", k_estrellas), ("puerta", k_puerta), ("puerta_llave", k_puerta_llave), ("salida", k_salida)]:
        kid_wall(n, f)
    demons()
    kid_weapon("puno", kw_puno)
    kid_weapon("pistola", kw_pistola)
    kid_weapon("escopeta", kw_escopeta)
    for lv in range(5):
        kidface(lv).save(OUT / f"kidface_{lv}.png")
    kidface(2, hurt=True).save(OUT / "kidface_hurt.png")
    kidface(4, grin=True).save(OUT / "kidface_grin.png")
    print("listo")
