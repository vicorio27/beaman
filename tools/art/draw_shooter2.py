"""Arte de PLOMO 2 ("La Empresa") y PLOMO 3 ("Clínica Irene"): texturas, enemigos, jefes,
Zaida (que no pelea), proyectiles (taza, chisme, papel) y la tarjeta de acceso.
Usa las funciones de draw_shooter.py. Salida: assets/shooter/*.png
Uso: python tools/art/draw_shooter2.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw
import draw_shooter as base
from draw_shooter import OUT, INK, outline, jit, wall, figure

random.seed(94)


# ------------------------------------------------------------------ paredes

def oficina(d, img):
    d.rectangle([0, 0, 31, 31], fill=(196, 186, 160, 255))
    d.rectangle([0, 0, 31, 3], fill=(150, 146, 140, 255))          # borde de la división
    for _ in range(40):
        d.point((random.randrange(32), random.randrange(4, 32)), fill=jit((180, 170, 146)))
    d.rectangle([7, 8, 24, 22], fill=(60, 110, 160, 255))           # afiche motivacional
    d.rectangle([9, 10, 22, 15], fill=(250, 220, 120, 255))
    d.line([(9, 18), (22, 18)], fill=(240, 240, 240, 255))
    d.line([(9, 20), (18, 20)], fill=(240, 240, 240, 255))


def vidrio(d, img):
    d.rectangle([0, 0, 31, 31], fill=(40, 60, 90, 255))
    for x in range(0, 32, 8):
        d.line([(x, 0), (x, 31)], fill=(120, 130, 140, 255))
    d.line([(0, 16), (31, 16)], fill=(120, 130, 140, 255))
    for k in range(4):
        d.line([(2 + k * 8, 3), (6 + k * 8, 12)], fill=(110, 150, 190, 255))  # reflejos
        d.point((5 + k * 8, 22), fill=(250, 220, 120, 255))                    # luces de la ciudad


def ascensor(d, img):
    d.rectangle([0, 0, 31, 31], fill=(150, 150, 156, 255))
    d.rectangle([3, 4, 15, 31], fill=(190, 192, 198, 255))
    d.rectangle([16, 4, 28, 31], fill=(180, 182, 188, 255))
    d.line([(15, 4), (15, 31)], fill=(90, 90, 96, 255))
    d.rectangle([12, 0, 19, 3], fill=(40, 40, 40, 255))
    d.text((13, -1), "", fill=(255, 80, 60, 255))
    d.point([(14, 1), (16, 1)], fill=(255, 90, 60, 255))


def caoba(d, img):
    d.rectangle([0, 0, 31, 31], fill=(84, 44, 30, 255))
    for x in range(0, 32, 8):
        d.line([(x, 0), (x, 31)], fill=(64, 32, 22, 255))
    d.rectangle([6, 6, 15, 14], fill=(230, 220, 190, 255))           # diplomas
    d.rectangle([18, 8, 26, 15], fill=(230, 220, 190, 255))
    d.rectangle([7, 7, 14, 13], outline=(200, 160, 60, 255))
    d.rectangle([19, 9, 25, 14], outline=(200, 160, 60, 255))


def archivo(d, img):
    d.rectangle([0, 0, 31, 31], fill=(110, 116, 110, 255))
    for y in (2, 12, 22):
        d.rectangle([2, y, 29, y + 8], fill=(140, 148, 140, 255))
        d.rectangle([13, y + 3, 18, y + 4], fill=(70, 70, 70, 255))
        d.rectangle([4, y + 1, 9, y + 2], fill=(240, 236, 220, 255))   # etiqueta


def baldosa(d, img):
    d.rectangle([0, 0, 31, 31], fill=(214, 218, 220, 255))
    for k in range(0, 32, 8):
        d.line([(k, 0), (k, 31)], fill=(180, 186, 190, 255))
        d.line([(0, k), (31, k)], fill=(180, 186, 190, 255))
    for _ in range(6):
        x, y = random.randrange(32), random.randrange(32)
        d.point((x, y), fill=(150, 160, 150, 255))


def clinica(d, img):
    d.rectangle([0, 0, 31, 31], fill=(222, 226, 222, 255))
    d.rectangle([0, 18, 31, 31], fill=(90, 150, 120, 255))
    d.line([(0, 18), (31, 18)], fill=(60, 110, 90, 255))
    d.rectangle([20, 4, 28, 12], fill=(250, 250, 250, 255))          # cartel: una cruz
    d.rectangle([23, 5, 25, 11], fill=(200, 50, 50, 255))
    d.rectangle([21, 7, 27, 9], fill=(200, 50, 50, 255))


def salida_blanca(d, img):
    clinica(d, img)
    d.rectangle([4, 4, 16, 12], fill=(30, 140, 60, 255))
    d.rectangle([5, 5, 15, 11], fill=(60, 200, 90, 255))


# ------------------------------------------------------------------ gente

def figure_tie(spec, pose):
    img = figure(spec, pose)
    if pose != "dead" and spec.get("tie"):
        d = ImageDraw.Draw(img)
        lean = 2 if pose == "hurt" else 0
        d.polygon([(15 + lean, 18), (17 + lean, 18), (17 + lean, 28), (16 + lean, 30), (15 + lean, 28)], fill=spec["tie"])
    return img


PEOPLE = {
    "oficinista": {"skin": (200, 150, 120, 255), "hair": (60, 44, 30, 255), "shirt": (170, 200, 230, 255),
                   "pants": (90, 90, 96, 255), "tie": (60, 60, 120, 255), "weapon": "throw", "backpack": None},
    "guarda": {"skin": (170, 120, 90, 255), "hair": (30, 26, 28, 255), "shirt": (40, 50, 80, 255),
               "pants": (30, 36, 60, 255), "cap": (30, 36, 60, 255), "weapon": "gun"},
    "rrhh": {"skin": (220, 170, 140, 255), "hair": (120, 60, 30, 255), "shirt": (150, 90, 160, 255),
             "pants": (60, 50, 70, 255), "long_hair": True, "glasses": True, "weapon": "whistle"},
    "josemario": {"skin": (210, 160, 130, 255), "hair": (90, 90, 96, 255), "shirt": (70, 72, 80, 255),
                  "pants": (60, 62, 70, 255), "tie": (180, 40, 40, 255), "glasses": True, "weapon": "gun"},
    "enfermero": {"skin": (190, 140, 110, 255), "hair": (30, 26, 28, 255), "shirt": (230, 236, 236, 255),
                  "pants": (220, 228, 228, 255), "cap": (230, 236, 236, 255), "weapon": "knife"},
    "archivista": {"skin": (220, 180, 150, 255), "hair": (200, 200, 200, 255), "shirt": (120, 110, 100, 255),
                   "pants": (80, 76, 70, 255), "glasses": True, "weapon": "throw"},
}
SCALE2 = {"josemario": 1.5}


def people():
    for name, spec in PEOPLE.items():
        spec = {k: v for k, v in spec.items() if v is not None}
        if spec.get("weapon") == "throw":
            spec["backpack_hand"] = True
        for pose in ["walk1", "walk2", "attack", "hurt", "dead"]:
            img = figure_tie(spec, pose)
            if name == "oficinista" and pose == "attack":
                d = ImageDraw.Draw(img)
                d.rectangle([22, 8, 28, 15], fill=(240, 240, 236, 255))     # la taza en la mano
                d.rectangle([28, 10, 29, 13], fill=(240, 240, 236, 255))
            if name == "archivista" and pose == "attack":
                d = ImageDraw.Draw(img)
                d.rectangle([20, 6, 30, 14], fill=(230, 210, 150, 255))     # una carpeta
            k = SCALE2.get(name, 1.0)
            if k != 1.0:
                img = img.resize((int(32 * k), int(48 * k)), Image.NEAREST)
            img.save(OUT / f"{name}_{pose}.png")
    # Zaida (no pelea): una sola pose.
    z = figure({"skin": (220, 170, 140, 255), "hair": (40, 26, 30, 255), "shirt": (130, 70, 150, 255),
                "pants": (90, 50, 110, 255), "long_hair": True}, "walk1")
    z.save(OUT / "zaida.png")


def expediente():
    """El jefe de la clínica: un expediente gigante hecho de su historia clínica. Escupe hojas."""
    for pose in ["walk1", "walk2", "attack", "hurt", "dead"]:
        img = Image.new("RGBA", (56, 72), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if pose == "dead":
            for k in range(8):  # hojas regadas
                x, y = random.randrange(0, 46), random.randrange(56, 66)
                d.rectangle([x, y, x + 9, y + 5], fill=(240, 236, 220, 255))
            d.polygon([(4, 66), (52, 62), (54, 71), (2, 71)], fill=(200, 170, 100, 255))
            outline(img).save(OUT / f"expediente_{pose}.png")
            continue
        bob = 2 if pose == "walk2" else 0
        d.polygon([(6, 10 + bob), (22, 10 + bob), (26, 4 + bob), (50, 4 + bob), (50, 66), (6, 66)], fill=(214, 180, 100, 255))
        d.rectangle([10, 14 + bob, 46, 62], fill=(244, 240, 226, 255))   # hojas adentro
        for y in range(20 + bob, 60, 5):
            d.line([(14, y), (42, y)], fill=(130, 130, 150, 255))
        d.rectangle([14, 16 + bob, 32, 19 + bob], fill=(200, 50, 50, 255))  # sello "CONFIDENCIAL" (roto)
        d.line([(12, 15 + bob), (36, 22 + bob)], fill=(40, 40, 40, 255))
        eye_y = 30 + bob
        open_ = pose == "attack"
        for ex in (18, 34):  # ojos
            d.ellipse([ex - 4, eye_y - 4, ex + 4, eye_y + 4], fill=(250, 250, 250, 255))
            d.ellipse([ex - 2, eye_y - 2, ex + 2, eye_y + 2], fill=(30, 30, 30, 255))
        if open_:
            d.rectangle([16, 44, 40, 56], fill=(60, 20, 30, 255))          # boca
            for x in range(18, 40, 5):
                d.rectangle([x, 44, x + 2, 47], fill=(240, 236, 220, 255))
        else:
            d.line([(18, 50), (38, 50)], fill=(60, 20, 30, 255), width=2)
        img = outline(img)
        if pose == "hurt":
            px = img.load()
            for y in range(img.height):
                for x in range(img.width):
                    c = px[x, y]
                    if c[3]:
                        px[x, y] = (min(255, c[0] + 60), c[1] // 2, c[2] // 2, c[3])
        img.save(OUT / f"expediente_{pose}.png")


def things():
    base.sprite("taza", (12, 12), lambda d: (d.rectangle([2, 3, 8, 10], fill=(240, 240, 236, 255)),
                                         d.rectangle([8, 5, 10, 8], fill=(240, 240, 236, 255)),
                                         d.rectangle([3, 3, 7, 4], fill=(110, 70, 40, 255))))
    base.sprite("papel", (12, 12), lambda d: (d.polygon([(1, 2), (10, 1), (11, 10), (2, 11)], fill=(244, 240, 226, 255)),
                                          d.line([(3, 4), (8, 4)], fill=(120, 120, 140, 255)),
                                          d.line([(3, 6), (8, 6)], fill=(120, 120, 140, 255)),
                                          d.line([(3, 8), (6, 8)], fill=(200, 50, 50, 255))))
    base.sprite("chisme", (16, 12), lambda d: (d.ellipse([0, 0, 15, 9], fill=(250, 250, 250, 255)),
                                           d.polygon([(4, 8), (8, 8), (3, 11)], fill=(250, 250, 250, 255)),
                                           d.text((2, 0), "bla", fill=(200, 40, 40, 255))))
    base.sprite("tarjeta", (14, 10), lambda d: (d.rectangle([0, 0, 13, 9], fill=(240, 240, 250, 255)),
                                            d.rectangle([1, 1, 5, 6], fill=(150, 160, 170, 255)),
                                            d.rectangle([7, 2, 12, 3], fill=(60, 100, 200, 255)),
                                            d.rectangle([7, 5, 11, 6], fill=(60, 100, 200, 255))))
    base.sprite("planta", (16, 24), lambda d: (d.rectangle([4, 16, 11, 23], fill=(160, 90, 50, 255)),
                                           d.ellipse([0, 2, 15, 18], fill=(70, 140, 70, 255))))


if __name__ == "__main__":
    for n, f in [("oficina", oficina), ("vidrio", vidrio), ("ascensor", ascensor), ("caoba", caoba),
                 ("archivo", archivo), ("baldosa", baldosa), ("clinica", clinica), ("salida_blanca", salida_blanca)]:
        wall(n, f)
    people()
    expediente()
    things()
    print("listo")
