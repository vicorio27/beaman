"""PLOMO: EL DEALER. Se juega siendo Lisandro, en el mismo barrio de crayón del episodio 1, pero
oscuro: los dibujos del niño están tachados, y lo que se recoge son drogas.
Al final aparece "el que no se muere" (el protagonista, armado como un caballero del infierno) y
los papeles se cambian: ahí él pelea contra Lisandro, con Camila (La Devoradora) y Guillermo (el
marrano) de refuerzo.
Salida (assets/shooter/):
  wall_dl_*.png                    paredes oscuras
  dl_<enemigo>_<pose>.png          tombo, sapo, rival, slayer, devoradora, marrano
  d_bolsita, d_pepas, d_maletin, d_caneca, bolso_p, cadena_p   (recogibles y proyectiles)
  dw_<arma>[_fire].png, dface_*.png   Lisandro (manos con anillos de oro, gafas oscuras)
  sw_<arma>[_fire].png, sface_*.png   él, con armadura (guante verde, casco con visor)
Uso: python tools/art/draw_shooter_dealer.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw
import draw_shooter_kid as kid
from draw_shooter import OUT, INK, outline, figure

random.seed(66)
GOLD = (240, 196, 60, 255)
DARK_PAPER = (52, 44, 62)


# ------------------------------------------------------------------ paredes: el barrio de crayón, de noche

def dark_wall(name, fn, scrawl=True):
    img = Image.new("RGBA", (32, 32), kid.PAPER + (255,))
    fn(ImageDraw.Draw(img))
    px = img.load()
    for y in range(32):
        for x in range(32):
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * 0.42), int(g * 0.36), int(b * 0.5), a)
    d = ImageDraw.Draw(img)
    if scrawl:  # tachones rojos encima de los dibujos
        for k in range(2):
            x0, y0 = random.randint(0, 14), random.randint(0, 14)
            kid.wobbly_line(d, [(x0, y0), (x0 + 16, y0 + 16)], (170, 30, 40), 2)
            kid.wobbly_line(d, [(x0 + 16, y0), (x0, y0 + 16)], (170, 30, 40), 2)
    kid.crayon(img, 0.08).save(OUT / f"wall_dl_{name}.png")


def dl_cocina(d):
    """La 'cocina': ollas de crayón con humo verde."""
    d.rectangle([0, 0, 31, 31], fill=(120, 110, 100))
    for x in (3, 18):
        d.rectangle([x, 18, x + 10, 28], fill=(90, 90, 100))
        for k in range(4):
            kid.wobbly_line(d, [(x + 3 + k * 2, 17), (x + 1 + k * 2, 8), (x + 4 + k * 2, 2)], (120, 240, 90), 1)
    d.line([(0, 29), (31, 29)], fill=(60, 50, 40), width=3)


def walls():
    dark_wall("ladrillo", kid.k_ladrillo, False)
    dark_wall("dibujos", kid.k_dibujos)
    dark_wall("azul", kid.k_azul, False)
    dark_wall("cocina", dl_cocina, False)
    dark_wall("estrellas", kid.k_estrellas)
    dark_wall("puerta", kid.k_puerta, False)
    dark_wall("puerta_llave", kid.k_puerta_llave, False)
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 255))   # la salida: verde, que se vea en la oscuridad
    kid.k_salida(ImageDraw.Draw(img))
    kid.crayon(img, 0.05).save(OUT / "wall_dl_salida.png")


# ------------------------------------------------------------------ enemigos (como los ve Lisandro)

SPECS = {
    "tombo": {"skin": (230, 210, 190, 255), "hair": (40, 40, 40, 255), "shirt": (50, 110, 70, 255),
              "pants": (40, 80, 50, 255), "cap": (40, 90, 60, 255), "weapon": "gun", "horns": None},
    "sapo": {"skin": (110, 180, 80, 255), "hair": (60, 110, 50, 255), "shirt": (236, 236, 230, 255),
             "pants": (70, 80, 120, 255), "weapon": "whistle", "horns": None},
    "rival": {"skin": (200, 90, 200, 255), "hair": (50, 20, 50, 255), "shirt": (90, 40, 110, 255),
              "pants": (50, 30, 60, 255), "hood": True, "weapon": "knife", "horns": (240, 240, 240, 255)},
}


def people():
    for name, spec in SPECS.items():
        for pose in ["walk1", "walk2", "attack", "hurt", "dead"]:
            img = figure(spec, pose)
            d = ImageDraw.Draw(img)
            if pose != "dead":
                if name == "sapo":   # ojos de sapo saltones
                    d.ellipse([11, 2, 15, 7], fill=(250, 250, 240, 255)); d.point((13, 4), fill=INK)
                    d.ellipse([17, 2, 21, 7], fill=(250, 250, 240, 255)); d.point((19, 4), fill=INK)
                if spec["horns"]:
                    d.polygon([(10, 5), (8, 0), (12, 3)], fill=spec["horns"])
                    d.polygon([(22, 5), (24, 0), (20, 3)], fill=spec["horns"])
                if name == "tombo":   # placa
                    d.rectangle([18, 20, 21, 23], fill=GOLD)
            kid.crayon(outline(img), 0.08).save(OUT / f"dl_{name}_{pose}.png")


TIE = (206, 48, 52, 255)


def slayer(pose):
    """Él, como lo ve Lisandro: un caballero del infierno de crayón. Armadura verde, casco con visor."""
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    green, dark = (70, 120, 60, 255), (40, 70, 36, 255)
    if pose == "dead":   # nunca se muere: cae de rodillas
        d.rectangle([8, 30, 32, 50], fill=green)
        d.rectangle([12, 18, 28, 32], fill=green)
        d.rectangle([14, 22, 26, 26], fill=(255, 160, 40, 255))
        d.rectangle([19, 32, 21, 46], fill=TIE)                                        # la corbata, hasta en el piso
        return kid.crayon(outline(img), 0.06)
    lean = 2 if pose == "hurt" else 0
    lf, rf = (38, 55) if pose == "walk1" else ((36, 55) if pose == "walk2" else (38, 55))
    d.rectangle([11, 36, 18, lf if pose != "walk2" else 52], fill=dark)                 # piernas
    d.rectangle([22, 36, 29, rf if pose != "walk1" else 52], fill=dark)
    d.rectangle([8 + lean, 16, 32 + lean, 38], fill=green)                               # coraza
    d.rectangle([12 + lean, 20, 28 + lean, 30], fill=dark)
    d.rectangle([4 + lean, 14, 12 + lean, 22], fill=green)                              # hombreras
    d.rectangle([28 + lean, 14, 36 + lean, 22], fill=green)
    d.rectangle([12 + lean, 0, 28 + lean, 16], fill=green)                              # casco
    d.rectangle([14 + lean, 6, 26 + lean, 10], fill=(255, 160, 40, 255))                 # visor naranja
    d.rectangle([4 + lean, 22, 9 + lean, 34], fill=green)                              # brazos
    d.rectangle([18 + lean, 16, 22 + lean, 18], fill=TIE)                                # la corbata roja, encima de la armadura
    d.polygon([(19 + lean, 18), (21 + lean, 18), (23 + lean, 33), (20 + lean, 36), (17 + lean, 33)], fill=TIE)
    if pose == "attack":
        d.rectangle([14, 26, 26, 34], fill=(60, 60, 66, 255))                            # escopeta al frente
        d.ellipse([12, 28, 28, 42], fill=(255, 220, 90, 255))
    else:
        d.rectangle([31 + lean, 22, 36 + lean, 34], fill=green)
        d.rectangle([30 + lean, 32, 39, 36], fill=(60, 60, 66, 255))
    d.rectangle([17 + lean, 36, 23 + lean, 39], fill=(150, 110, 60, 255))               # la correa de Lukas (en el cinturón)
    img = outline(img)
    if pose == "hurt":
        px = img.load()
        for y in range(img.height):
            for x in range(img.width):
                c = px[x, y]
                if c[3]:
                    px[x, y] = (min(255, c[0] + 90), c[1] // 2, c[2] // 2, c[3])
    return kid.crayon(img, 0.06).resize((72, 100), Image.NEAREST)


def devoradora(pose):
    img = Image.new("RGBA", (44, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pink = (214, 140, 166, 255)
    if pose == "dead":
        d.ellipse([2, 34, 42, 47], fill=pink); d.rectangle([10, 38, 34, 46], fill=GOLD)
        return kid.crayon(outline(img), 0.08)
    sway = {"walk1": -1, "walk2": 1, "attack": 0, "hurt": 2}[pose]
    d.ellipse([4 + sway, 14, 40 + sway, 47], fill=pink)                                 # cuerpo inflado
    d.rectangle([10 + sway, 28, 34 + sway, 44], fill=GOLD)                               # vestido reventado
    d.ellipse([13 + sway, 0, 31 + sway, 18], fill=pink)                                 # cabeza
    d.rectangle([11 + sway, 0, 33 + sway, 6], fill=(40, 30, 34, 255))
    d.rectangle([11 + sway, 4, 14 + sway, 20], fill=(40, 30, 34, 255))
    d.rectangle([30 + sway, 4, 33 + sway, 20], fill=(40, 30, 34, 255))
    d.rectangle([16 + sway, 7, 19 + sway, 9], fill=(255, 230, 60, 255))
    d.rectangle([25 + sway, 7, 28 + sway, 9], fill=(255, 230, 60, 255))
    d.ellipse([16 + sway, 11, 28 + sway, 17], fill=(200, 30, 60, 255))                   # boca pintada
    arms = [(4, 22, 0, 10), (40, 22, 44, 10)] if pose == "attack" else [(4, 26, 0, 34), (40, 26, 44, 34)]
    for ax, ay, bx, by in arms:
        d.line([(ax + sway, ay), (bx, by)], fill=pink, width=3)
        d.rectangle([min(bx, 40) - 2 if bx else 0, by - 3, min(bx, 40) + 3 if bx else 5, by + 3], fill=(150, 40, 60, 255))
    img = outline(img)
    return kid.crayon(img, 0.08).resize((66, 72), Image.NEAREST)


def marrano(pose):
    img = Image.new("RGBA", (40, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pig = (240, 160, 170, 255)
    if pose == "dead":
        d.ellipse([2, 34, 38, 47], fill=pig); d.arc([8, 34, 32, 46], 0, 180, fill=GOLD, width=2)
        return kid.crayon(outline(img), 0.08)
    sway = {"walk1": -1, "walk2": 1, "attack": 0, "hurt": 2}[pose]
    legs = (40, 47) if pose != "walk2" else (44, 47)
    d.rectangle([10, 38, 16, legs[0] + 7], fill=(40, 40, 50, 255))
    d.rectangle([24, 38, 30, legs[1]], fill=(40, 40, 50, 255))
    d.ellipse([4 + sway, 16, 36 + sway, 44], fill=(40, 40, 50, 255))                    # vestido de paño
    d.rectangle([17 + sway, 18, 23 + sway, 40], fill=pig)                              # camisa abierta
    for k in range(3):
        d.arc([10 - k + sway, 14 + k * 3, 30 + k + sway, 32 + k * 4], 20, 160, fill=GOLD, width=2)  # cadenas
    d.ellipse([9 + sway, 0, 31 + sway, 22], fill=pig)                                  # cabeza de marrano
    d.polygon([(10 + sway, 4), (6 + sway, -2), (15 + sway, 2)], fill=(220, 130, 140, 255))
    d.polygon([(30 + sway, 4), (34 + sway, -2), (25 + sway, 2)], fill=(220, 130, 140, 255))
    d.rectangle([11 + sway, 6, 19 + sway, 10], fill=(20, 20, 24, 255))                 # gafas
    d.rectangle([21 + sway, 6, 29 + sway, 10], fill=(20, 20, 24, 255))
    d.ellipse([15 + sway, 12, 25 + sway, 19], fill=(220, 120, 130, 255))               # trompa
    d.point([(18 + sway, 15), (22 + sway, 15)], fill=(90, 30, 40, 255))
    if pose == "attack":
        d.line([(36, 20), (40, 8)], fill=pig, width=3)
        d.arc([34, 0, 40, 10], 0, 360, fill=GOLD, width=2)                              # revolea una cadena
    img = outline(img)
    return kid.crayon(img, 0.08).resize((60, 72), Image.NEAREST)


def bosses():
    for pose in ["walk1", "walk2", "attack", "hurt", "dead"]:
        slayer(pose).save(OUT / f"dl_slayer_{pose}.png")
        devoradora(pose).save(OUT / f"dl_devoradora_{pose}.png")
        marrano(pose).save(OUT / f"dl_marrano_{pose}.png")


# ------------------------------------------------------------------ lo que se recoge (drogas, de crayón)

def things():
    def save(name, size, fn):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        fn(ImageDraw.Draw(img))
        kid.crayon(outline(img), 0.06).save(OUT / f"{name}.png")
    save("d_bolsita", (14, 14), lambda d: (d.polygon([(2, 4), (11, 4), (12, 13), (1, 13)], fill=(240, 240, 240, 255)),
                                          d.rectangle([3, 1, 10, 4], fill=(200, 40, 40, 255))))
    save("d_pepas", (16, 12), lambda d: [d.ellipse([x, y, x + 5, y + 4], fill=c) for x, y, c in
                                         [(1, 6, (240, 90, 160, 255)), (6, 2, (90, 200, 240, 255)), (10, 6, (250, 220, 60, 255))]])
    save("d_maletin", (20, 16), lambda d: (d.rectangle([1, 4, 18, 15], fill=(40, 30, 30, 255)),
                                           d.rectangle([7, 1, 12, 4], outline=GOLD),
                                           d.rectangle([8, 8, 11, 11], fill=GOLD)))
    save("d_caneca", (20, 28), lambda d: (d.rectangle([2, 4, 17, 27], fill=(60, 60, 80, 255)),
                                          d.line([(2, 10), (17, 10)], fill=(40, 40, 50, 255)),
                                          d.line([(2, 20), (17, 20)], fill=(40, 40, 50, 255)),
                                          d.polygon([(6, 4), (14, 4), (13, 0), (7, 0)], fill=(240, 240, 240, 255))))
    save("bolso_p", (12, 11), lambda d: (d.rectangle([1, 4, 10, 10], fill=(150, 40, 60, 255)),
                                         d.arc([3, 0, 8, 7], 180, 360, fill=(110, 30, 40, 255), width=2)))
    save("plasma", (12, 12), lambda d: (d.ellipse([0, 0, 11, 11], fill=(90, 255, 120, 200)),
                                        d.ellipse([3, 3, 8, 8], fill=(220, 255, 220, 255))))
    save("cadena_p", (14, 8), lambda d: [d.ellipse([x, 1, x + 4, 6], outline=GOLD, width=1) for x in range(1, 11, 3)])


# ------------------------------------------------------------------ Lisandro: manos y cara

def ring_hand(d, box, tattoo=True):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=(190, 140, 110, 255))
    for k in range(3):
        d.rectangle([x0 + 2 + k * 5, y0 + 2, x0 + 4 + k * 5, y0 + 4], fill=GOLD)    # anillos
    if tattoo:
        d.line([(x0 + 2, y1 - 3), (x1 - 2, y1 - 6)], fill=(40, 40, 80, 255))


def weapon_set(prefix, fn):
    for name in ("puno", "pistola", "escopeta"):
        for fire in (False, True):
            img = Image.new("RGBA", (80, 56), (0, 0, 0, 0))
            fn(ImageDraw.Draw(img), name, fire)
            kid.crayon(outline(img), 0.06).save(OUT / f"{prefix}{name}{'_fire' if fire else ''}.png")


def lisandro_hands(d, name, fire):
    shirt = (236, 232, 222, 255)
    if name == "puno":
        y = 22 if fire else 34
        d.rectangle([46, y + 10, 60, 56], fill=shirt)
        ring_hand(d, (42, y, 62, y + 12))
    elif name == "pistola":
        d.rectangle([36, 40, 52, 56], fill=shirt)
        ring_hand(d, (34, 32, 52, 44), False)
        d.rectangle([37, 14, 47, 34], fill=GOLD)                                      # pistola de oro
        d.rectangle([39, 18, 45, 22], fill=(200, 150, 40, 255))
        if fire:
            d.polygon([(42, -2), (47, 8), (53, 2), (49, 12), (35, 12), (31, 2), (37, 8)], fill=(255, 230, 80, 255))
            d.text((30, -2), "BANG", fill=(220, 40, 40, 255))
    else:
        d.rectangle([22, 42, 38, 56], fill=shirt)
        d.rectangle([44, 46, 60, 56], fill=shirt)
        d.rectangle([30, 14, 46, 52], fill=(30, 26, 26, 255))
        d.rectangle([33, 0, 38, 30], fill=GOLD)
        d.rectangle([39, 0, 44, 30], fill=GOLD)
        ring_hand(d, (25, 36, 36, 46), False)
        ring_hand(d, (43, 40, 54, 50), False)
        if fire:
            d.polygon([(39, -10), (46, 0), (56, -6), (50, 6), (28, 6), (22, -6), (32, 0)], fill=(255, 230, 80, 255))
            d.text((24, -8), "BRRAM", fill=(220, 40, 40, 255))


def slayer_hands(d, name, fire):
    green, dark = (70, 120, 60, 255), (40, 70, 36, 255)
    if name == "puno":
        y = 22 if fire else 34
        d.rectangle([44, y + 10, 62, 56], fill=green)
        d.rectangle([42, y, 64, y + 12], fill=dark)
    elif name == "pistola":
        d.rectangle([34, 40, 54, 56], fill=green)
        d.rectangle([34, 32, 52, 44], fill=dark)
        d.rectangle([37, 12, 48, 34], fill=(70, 70, 80, 255))
        if fire:
            d.polygon([(42, -4), (48, 6), (54, 0), (50, 10), (34, 10), (30, 0), (36, 6)], fill=(255, 210, 60, 255))
    else:
        d.rectangle([20, 42, 38, 56], fill=green)
        d.rectangle([44, 46, 62, 56], fill=green)
        d.rectangle([28, 12, 50, 52], fill=(80, 80, 90, 255))
        d.rectangle([32, 0, 38, 28], fill=(60, 60, 70, 255))
        d.rectangle([40, 0, 46, 28], fill=(60, 60, 70, 255))
        d.rectangle([24, 36, 36, 46], fill=dark)
        d.rectangle([42, 40, 54, 50], fill=dark)
        if fire:
            d.polygon([(39, -12), (46, -2), (58, -8), (50, 4), (28, 4), (20, -8), (32, -2)], fill=(255, 200, 60, 255))


def lisandro_face(level, hurt=False, grin=False):
    img = Image.new("RGBA", (24, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 3, 21, 25], fill=(190, 140, 110, 255))
    d.rectangle([3, 1, 20, 6], fill=(20, 18, 20, 255))
    d.rectangle([4, 9, 19, 13], fill=(20, 20, 24, 255))                               # gafas oscuras
    if hurt:
        d.line([(8, 19), (15, 19)], fill=INK)
        d.point([(17, 15)], fill=(200, 30, 30, 255))
    elif grin:
        d.chord([6, 16, 17, 23], 0, 180, fill=(250, 250, 250, 255), outline=INK)
        d.rectangle([10, 18, 12, 20], fill=GOLD)                                     # diente de oro
    else:
        d.arc([7, 15, 16, 22], 20, 160 if level >= 2 else 90, fill=INK)              # media sonrisa
    for i in range(4 - level):
        d.line([(4 + i * 4, 15 + i), (6 + i * 4, 17 + i)], fill=(150, 30, 30, 255))
    d.arc([0, 18, 23, 30], 200, 340, fill=GOLD)                                      # cadena
    return outline(img)


def slayer_face(level, hurt=False, grin=False):
    img = Image.new("RGBA", (24, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 2, 20, 24], fill=(70, 120, 60, 255))
    d.rectangle([5, 9, 18, 14], fill=(255, 160, 40, 255) if not hurt else (255, 80, 40, 255))
    if grin:
        d.rectangle([5, 9, 18, 14], fill=(255, 230, 120, 255))
    d.rectangle([10, 22, 13, 25], fill=TIE)                                             # el nudo de la corbata
    for i in range(4 - level):
        d.line([(4 + i * 4, 4), (7 + i * 4, 8)], fill=(30, 40, 30, 255))             # rayones en el casco
    return outline(img)


if __name__ == "__main__":
    walls()
    people()
    bosses()
    things()
    weapon_set("dw_", lisandro_hands)
    weapon_set("sw_", slayer_hands)
    for lv in range(5):
        lisandro_face(lv).save(OUT / f"dface_{lv}.png")
        slayer_face(lv).save(OUT / f"sface_{lv}.png")
    lisandro_face(2, hurt=True).save(OUT / "dface_hurt.png")
    lisandro_face(4, grin=True).save(OUT / "dface_grin.png")
    slayer_face(2, hurt=True).save(OUT / "sface_hurt.png")
    slayer_face(4, grin=True).save(OUT / "sface_grin.png")
    print("listo")
