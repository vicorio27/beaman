"""PLOMO (el Dealer): lo horrible de vivir en el mundo de las drogas. La olla, los clientes de Lisandro,
los pelados campaneros, los desaparecidos, el sicariato.
Salida (assets/shooter/):
  wall_dd_olla.png, wall_dd_hollin.png, wall_dd_desaparecidos.png, wall_dd_mural.png       paredes 64x64
  dd_fumador.png (sentado contra la pared, con la pipa), dd_velas.png (el altarcito), dd_colchon.png,
  dd_senora.png (la señora de los carteles), dd_camila.png y dd_veronica.png (las de la esquina,
  debajo del farol: trabajan para Lisandro; no son enemigas)            decorado
  dl_adicto_<pose>.png    el cliente: flaco, cobija, pide "una sola"
  dl_pelado_<pose>.png    el campanero: doce años, gorra, pito ("hurt" = tirado al piso, cubriéndose)
  dl_sicario_<pose>.png   casco de moto, mini-Uzi
  dl_pandillero_<pose>.png  capucha, cuchillo
  dw_uzi[_fire].png       la mini-Uzi de oro de Lisandro (primera persona)
Uso: python tools/art/draw_plomo_olla.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw
from draw_shooter import OUT, INK, outline
from draw_plomo_doom import new, save_wall, noise, grime, bevel, crayon_line, sprite, save, shade, \
    _hand, _flash, _shaded_poly
from draw_plomo_jefes import finish

random.seed(2021)
S = 64


# ------------------------------------------------------------------ paredes

def w_olla():
    """La olla: concreto negro de hollín, manchas, cucharas quemadas, "SAPO = MUERTO"."""
    img, d = new((70, 64, 60))
    noise(img, 0.18)
    for _ in range(9):  # el hollín de los fumaderos, subiendo
        x = random.randrange(S)
        for y in range(S, 10, -1):
            k = (y - 10) / 54.0
            if random.random() < 0.8:
                d.point((x + random.randint(-2, 2), y), fill=(int(30 + 30 * (1 - k)), 26, 24, 255))
    for _ in range(4):  # manchas de humedad
        x, y, r = random.randrange(S), random.randrange(20, S), random.randint(4, 9)
        d.ellipse([x - r, y - r // 2, x + r, y + r // 2], fill=(54, 50, 40, 255))
    crayon_line(d, [(6, 14), (6, 22)], (200, 200, 190), 2)                       # S
    d.text((4, 10), "SAPO=", fill=(210, 205, 195))
    d.text((10, 21), "MUERTO", fill=(190, 40, 40))
    for x in (40, 50):  # cucharas quemadas pegadas con cinta
        d.ellipse([x, 40, x + 5, 44], fill=(60, 56, 56, 255))
        d.line([(x + 5, 42), (x + 10, 42)], fill=(120, 116, 112, 255))
        d.point((x + 2, 41), fill=(20, 16, 14, 255))
    grime(img, 0.6, 0.4)
    save_wall(img, "olla")


def w_hollin():
    """La olla sin letrero: hollín, humedad, una cobija colgada."""
    img, d = new((66, 60, 56))
    noise(img, 0.18)
    for _ in range(12):
        x = random.randrange(S)
        for y in range(S, 6, -1):
            if random.random() < 0.75:
                d.point((x + random.randint(-2, 2), y), fill=(28, 24, 22, 255))
    for _ in range(5):
        x, y, r = random.randrange(S), random.randrange(16, S), random.randint(4, 10)
        d.ellipse([x - r, y - r // 2, x + r, y + r // 2], fill=(52, 48, 40, 255))
    d.rectangle([36, 6, 56, 30], fill=(96, 70, 80, 255))                         # una cobija colgada de un clavo
    for y in range(8, 30, 4):
        d.line([(37, y), (55, y + 1)], fill=(80, 56, 66, 255))
    d.point((46, 5), fill=(160, 160, 160, 255))
    grime(img, 0.6, 0.35)
    save_wall(img, "hollin")


def w_desaparecidos():
    """Carteles de desaparecidos pegados uno encima del otro. ¿LO HA VISTO?"""
    img, d = new((96, 92, 88))
    noise(img, 0.12)
    for k, (x, y) in enumerate([(2, 3), (33, 6), (8, 34), (37, 33), (22, 18)]):
        w, h = 26, 28
        paper = random.choice([(232, 228, 210), (220, 214, 190), (240, 236, 222)])
        d.rectangle([x, y, x + w, y + h], fill=paper + (255,))
        d.rectangle([x + 2, y + 2, x + w - 2, y + 6], fill=(30, 30, 30, 255))      # el titular
        d.rectangle([x + 7, y + 8, x + w - 7, y + 19], fill=(150, 140, 130, 255))  # la foto
        d.ellipse([x + 10, y + 9, x + w - 10, y + 15], fill=(110, 90, 80, 255))
        d.rectangle([x + 9, y + 15, x + w - 9, y + 19], fill=(80, 90, 120, 255))
        for ly in (y + 21, y + 24):
            d.line([(x + 3, ly), (x + w - 3, ly)], fill=(90, 90, 90, 255))
        if k == 4:  # el de encima, nuevo: la mamá todavía los pega
            d.text((x + 3, y + 1), "¿VISTO?", fill=(240, 240, 240))
        else:  # los de abajo: viejos, rasgados, lavados por la lluvia
            for _ in range(30):
                d.point((x + random.randrange(w), y + random.randrange(h)), fill=(170, 160, 140, 255))
            d.polygon([(x + w, y + h), (x + w - 8, y + h), (x + w, y + h - 6)], fill=(96, 92, 88, 255))
    grime(img, 0.45, 0.55)
    save_wall(img, "desaparecidos")


def w_mural():
    """Mural de un pelado muerto: la cara pintada, alas, Q.E.P.D. y los años (quince, dieciséis)."""
    img, d = new((180, 176, 168))
    noise(img, 0.08)
    d.rectangle([0, 0, S, S], fill=(170, 200, 214, 255))                         # cielo pintado
    for x in range(0, S, 4):
        d.line([(x, 0), (x, S)], fill=(160, 190, 206, 255))
    for side in (-1, 1):  # las alas
        cx = 32 + side * 16
        for k in range(5):
            d.ellipse([cx - 7 + side * k, 14 + k * 4, cx + 7 + side * k, 22 + k * 4], fill=(245, 245, 240, 255))
    d.ellipse([21, 8, 43, 32], fill=(150, 110, 84, 255))                         # la cara
    d.rectangle([24, 6, 40, 12], fill=(30, 26, 30, 255))                         # la gorra
    d.rectangle([38, 10, 46, 12], fill=(30, 26, 30, 255))
    d.point((27, 19), fill=INK)
    d.point((36, 19), fill=INK)
    d.line([(29, 26), (35, 26)], fill=(90, 50, 40, 255))
    d.rectangle([4, 36, 60, 46], fill=(40, 36, 44, 255))
    d.text((7, 36), "Q.E.P.D.", fill=(240, 220, 120))
    d.text((5, 47), "2005-2021", fill=(40, 36, 44))
    for x in (8, 20, 44, 56):  # las velas al pie (pintadas, y la cera de las de verdad)
        d.rectangle([x - 1, 56, x + 1, 63], fill=(240, 236, 220, 255))
        d.point((x, 55), fill=(255, 200, 80, 255))
    grime(img, 0.35, 0.6)
    save_wall(img, "mural")


# ------------------------------------------------------------------ decorado

def fumador():
    """Un cliente sentado contra la pared, con la pipa. No pelea: fuma."""
    img, d = sprite(30, 30)
    skin = (150, 120, 100)
    d.polygon([(4, 29), (6, 12), (14, 6), (22, 10), (26, 29)], fill=(96, 84, 70, 255))   # la cobija
    for y in (16, 22):
        d.line([(7, y), (24, y + 2)], fill=(70, 60, 50, 255))
    d.ellipse([10, 2, 20, 12], fill=skin + (255,))
    d.rectangle([10, 1, 20, 4], fill=(40, 36, 32, 255))
    d.point((13, 7), fill=INK)
    d.point((17, 7), fill=INK)
    d.line([(16, 10), (24, 12)], fill=(200, 200, 210, 255))                     # la pipa
    d.ellipse([23, 10, 27, 14], fill=(220, 220, 230, 255))
    d.point((25, 9), fill=(255, 160, 60, 255))                                  # la brasa
    for k in range(3):                                                           # el humo
        d.point((26 + k % 2, 6 - k * 2), fill=(200, 200, 200, 180))
    d.rectangle([5, 26, 12, 29], fill=(40, 40, 46, 255))                         # los pies, sin zapatos
    save(img, "fumador")


def velas():
    """El altarcito en la esquina: velas, una foto, una virgen de yeso, flores de plástico."""
    img, d = sprite(32, 22)
    d.rectangle([2, 16, 29, 21], fill=(60, 50, 44, 255))
    d.rectangle([12, 4, 20, 15], fill=(226, 182, 64, 255))                       # el marco
    d.rectangle([13, 5, 19, 14], fill=(170, 150, 130, 255))
    d.ellipse([14, 6, 18, 10], fill=(120, 90, 70, 255))
    d.polygon([(23, 15), (25, 6), (27, 15)], fill=(120, 160, 220, 255))          # la virgen
    d.ellipse([24, 4, 26, 7], fill=(240, 220, 200, 255))
    for x in (4, 7, 10, 22):
        h = random.randint(4, 9)
        d.rectangle([x, 16 - h, x + 1, 15], fill=(240, 236, 220, 255))
        d.point((x, 15 - h), fill=(255, 210, 90, 255))
    d.ellipse([27, 12, 31, 16], fill=(220, 60, 90, 255))                         # una flor de plástico
    save(img, "velas")


def colchon():
    img, d = sprite(44, 12)
    d.rectangle([1, 3, 42, 11], fill=(170, 160, 120, 255))
    for x in range(4, 42, 6):
        d.point((x, 6), fill=(130, 120, 90, 255))
    d.ellipse([10, 4, 26, 10], fill=(130, 110, 70, 255))                         # la mancha
    d.rectangle([30, 1, 40, 5], fill=(80, 90, 120, 255))                         # una chaqueta encima
    save(img, "colchon")


def senora():
    """La señora de los carteles: con el tarro de pegante y la foto del hijo."""
    img, d = sprite(24, 44)
    d.rectangle([7, 30, 16, 43], fill=(70, 60, 90, 255))                         # la falda
    d.rectangle([6, 14, 17, 31], fill=(150, 60, 70, 255))                        # el saco
    d.ellipse([7, 3, 16, 14], fill=(190, 150, 120, 255))
    d.rectangle([7, 2, 16, 6], fill=(200, 200, 205, 255))                        # el pelo canoso
    d.rectangle([17, 16, 22, 24], fill=(232, 228, 210, 255))                     # el cartel en la mano
    d.rectangle([18, 18, 21, 21], fill=(130, 110, 100, 255))
    d.rectangle([2, 22, 6, 28], fill=(200, 200, 210, 255))                       # el tarro de pegante
    save(img, "senora")


def mujer(name, hair, top, skirt, jacket, long_hair, eyes, tall):
    """Las de la esquina: de pie debajo del farol, cansadas. Camila (rubia, de rosado) y Verónica
    (más mona, de ojos azules, más alta: la ex de él)."""
    extra = 6 if tall else 0
    img, d = sprite(24, 46 + extra)
    skin = (214, 170, 140) if not tall else (226, 186, 160)
    b = 45 + extra
    d.rectangle([9, b - 5, 11, b], fill=(30, 26, 30, 255))                       # tacones
    d.rectangle([13, b - 5, 15, b], fill=(30, 26, 30, 255))
    d.rectangle([9, 31, 15, b - 5], fill=skin + (255,))                          # piernas
    d.rectangle([8, 25, 16, 32], fill=skirt + (255,))
    d.rectangle([7, 14, 17, 26], fill=top + (255,))
    d.rectangle([5, 14, 8, 27], fill=jacket + (255,))                            # la chaqueta, del frío
    d.rectangle([16, 14, 19, 27], fill=jacket + (255,))
    d.ellipse([8, 4, 16, 14], fill=skin + (255,))
    d.rectangle([7, 2, 17, 6], fill=hair + (255,))
    if long_hair:
        d.rectangle([6, 4, 8, 20], fill=hair + (255,))
        d.rectangle([16, 4, 18, 20], fill=hair + (255,))
    d.point((10, 9), fill=eyes + (255,))
    d.point((14, 9), fill=eyes + (255,))
    d.line([(11, 12), (13, 12)], fill=(200, 60, 80, 255))
    d.point((19, 20), fill=(255, 160, 60, 255))                                  # el cigarrillo
    save(img, name)


# ------------------------------------------------------------------ enemigos

def adicto(pose):
    """El cliente: flaco, cobija sobre los hombros, la piel gris, las manos adelante pidiendo."""
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    skin, blanket = (150, 134, 120, 255), (104, 92, 78, 255)
    if pose == "dead":
        d.rectangle([4, 46, 36, 53], fill=blanket)
        d.ellipse([30, 44, 38, 52], fill=skin)
        d.line([(12, 50), (2, 54)], fill=(200, 200, 210, 255))                   # la pipa, rodó
        return finish(img)
    lean = {"walk1": 0, "walk2": 1, "attack": 3, "hurt": -2}[pose]
    l1 = 55 if pose != "walk2" else 52
    l2 = 55 if pose != "walk1" else 52
    d.rectangle([15, 38, 18, l1], fill=(60, 58, 64, 255))                        # piernas flaquitas
    d.rectangle([22, 38, 25, l2], fill=(60, 58, 64, 255))
    d.polygon([(10 + lean, 40), (13 + lean, 16), (27 + lean, 16), (30 + lean, 40)], fill=blanket)
    d.line([(14 + lean, 22), (26 + lean, 24)], fill=(80, 70, 60, 255))
    d.ellipse([14 + lean, 4, 26 + lean, 17], fill=skin)                          # la cabeza, agachada
    d.rectangle([16 + lean, 9, 19 + lean, 10], fill=(60, 40, 50, 255))           # ojeras
    d.rectangle([21 + lean, 9, 24 + lean, 10], fill=(60, 40, 50, 255))
    d.point((17 + lean, 11), fill=INK)
    d.point((22 + lean, 11), fill=INK)
    d.rectangle([14 + lean, 3, 26 + lean, 6], fill=(46, 40, 36, 255))
    if pose == "attack":  # las manos adelante, garras
        d.line([(24, 22), (36, 18)], fill=skin, width=2)
        d.line([(16, 22), (34, 24)], fill=skin, width=2)
        for y in (16, 18, 20):
            d.point((37, y), fill=skin)
    else:  # una mano adelante, pidiendo
        d.line([(26 + lean, 24), (32 + lean, 26)], fill=skin, width=2)
        d.ellipse([31 + lean, 24, 35 + lean, 28], fill=skin)
    return finish(img, hurt=pose == "hurt")


def pelado(pose):
    """El campanero: doce años, gorra de lado, pito. Herido = tirado al piso cubriéndose (ya sabe)."""
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    skin = (190, 140, 100, 255)
    shirt = (210, 60, 50, 255)
    if pose in ("hurt", "dead"):  # tirado al piso, las manos en la cabeza
        d.rectangle([6, 46, 34, 53], fill=(50, 60, 90, 255))
        d.rectangle([10, 42, 28, 50], fill=shirt)
        d.ellipse([26, 40, 36, 50], fill=skin)
        d.rectangle([25, 39, 37, 43], fill=(30, 30, 120, 255))
        d.line([(28, 44), (24, 40)], fill=skin, width=2)
        return finish(img)
    bob = {"walk1": 0, "walk2": 1, "attack": 0}[pose]
    l1 = 55 if pose != "walk2" else 52
    l2 = 55 if pose != "walk1" else 52
    d.rectangle([15, 38 + bob, 18, l1], fill=(50, 60, 90, 255))
    d.rectangle([22, 38 + bob, 25, l2], fill=(50, 60, 90, 255))
    d.rectangle([13, l1 - 1, 18, 55], fill=(240, 240, 240, 255))                 # tenis blancos (no son de él)
    d.rectangle([22, l2 - 1, 27, 55], fill=(240, 240, 240, 255))
    d.rectangle([13, 22 + bob, 27, 39 + bob], fill=shirt)
    d.ellipse([14, 10 + bob, 26, 22 + bob], fill=skin)
    d.rectangle([13, 9 + bob, 25, 13 + bob], fill=(30, 30, 120, 255))            # la gorra de lado
    d.rectangle([24, 11 + bob, 31, 13 + bob], fill=(30, 30, 120, 255))
    d.point((18, 16 + bob), fill=INK)
    d.point((22, 16 + bob), fill=INK)
    if pose == "attack":  # pitando
        d.rectangle([20, 18, 25, 20], fill=(200, 200, 210, 255))
        for k in range(3):
            d.arc([26 + k * 3, 12 - k, 32 + k * 3, 24 + k], -40, 40, fill=(255, 240, 120, 255))
    return finish(img)


def sicario(pose):
    """El parrillero: casco de moto, chaqueta, mini-Uzi."""
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    jacket, pants = (40, 44, 52, 255), (50, 56, 76, 255)
    if pose == "dead":
        d.rectangle([4, 46, 34, 53], fill=jacket)
        d.ellipse([30, 42, 39, 52], fill=(200, 30, 40, 255))                     # el casco
        d.rectangle([10, 52, 18, 54], fill=(30, 30, 34, 255))
        return finish(img)
    sway = {"walk1": -1, "walk2": 1, "attack": 0, "hurt": 2}[pose]
    l1 = 55 if pose != "walk2" else 52
    l2 = 55 if pose != "walk1" else 52
    d.rectangle([14, 36, 19, l1], fill=pants)
    d.rectangle([21, 36, 26, l2], fill=pants)
    d.rectangle([11 + sway, 18, 29 + sway, 38], fill=jacket)
    d.line([(20 + sway, 18), (20 + sway, 38)], fill=(70, 76, 90, 255))
    d.ellipse([13 + sway, 3, 27 + sway, 19], fill=(200, 30, 40, 255))           # el casco rojo
    d.rectangle([15 + sway, 8, 27 + sway, 13], fill=(20, 20, 26, 255))          # el visor
    d.point((17 + sway, 9), fill=(160, 170, 190, 255))
    if pose == "attack":
        d.rectangle([20, 24, 36, 28], fill=(30, 30, 34, 255))                    # la Uzi al frente
        d.rectangle([26, 28, 29, 33], fill=(30, 30, 34, 255))
        d.ellipse([35, 21, 40, 31], fill=(255, 220, 90, 255))
    else:
        d.rectangle([27 + sway, 26, 34 + sway, 29], fill=(30, 30, 34, 255))
        d.rectangle([29 + sway, 29, 31 + sway, 33], fill=(30, 30, 34, 255))
    return finish(img, hurt=pose == "hurt")


def pandillero(pose):
    """El de la otra banda: buzo con capucha, pantalón ancho, cuchillo."""
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    hood, pants, skin = (70, 90, 70, 255), (40, 40, 44, 255), (170, 120, 90, 255)
    if pose == "dead":
        d.rectangle([4, 46, 34, 53], fill=hood)
        d.ellipse([30, 43, 38, 51], fill=skin)
        d.line([(8, 52), (14, 50)], fill=(200, 200, 210, 255), width=2)
        return finish(img)
    sway = {"walk1": -1, "walk2": 1, "attack": 2, "hurt": -2}[pose]
    l1 = 55 if pose != "walk2" else 52
    l2 = 55 if pose != "walk1" else 52
    d.rectangle([13, 36, 19, l1], fill=pants)
    d.rectangle([21, 36, 27, l2], fill=pants)
    d.rectangle([11 + sway, 17, 29 + sway, 37], fill=hood)
    d.rectangle([14 + sway, 30, 26 + sway, 33], fill=shade(hood, 0.7))          # el bolsillo canguro
    d.ellipse([13 + sway, 4, 27 + sway, 19], fill=hood)                         # la capucha
    d.ellipse([16 + sway, 8, 25 + sway, 18], fill=skin)
    d.point((18 + sway, 12), fill=INK)
    d.point((22 + sway, 12), fill=INK)
    if pose == "attack":
        d.line([(26, 22), (34, 16)], fill=skin, width=3)
        d.line([(34, 16), (39, 10)], fill=(220, 220, 230, 255), width=2)          # el cuchillo arriba
    else:
        d.line([(27 + sway, 24), (31 + sway, 32)], fill=skin, width=3)
        d.line([(31 + sway, 32), (33 + sway, 38)], fill=(220, 220, 230, 255), width=2)
    return finish(img, hurt=pose == "hurt")


# ------------------------------------------------------------------ la mini-Uzi de oro (primera persona)

def gun_uzi(fire):
    img, d = sprite(96, 64)
    cx = 46
    gold = (226, 182, 64)
    if fire:
        _flash(d, cx, 6, 15)
        for k in range(3):  # casquillos volando
            d.rectangle([cx + 26 + k * 7, 18 - k * 5, cx + 28 + k * 7, 22 - k * 5], fill=(250, 210, 90, 255))
    d.rectangle([cx - 3, 1, cx + 4, 10], fill=shade(gold, 0.55))                        # el cañón corto
    d.ellipse([cx - 2, 1, cx + 3, 5], fill=(14, 12, 14, 255))
    _shaded_poly(d, [(cx - 13, 8), (cx + 13, 8), (cx + 17, 42), (cx - 17, 42)], gold)    # el cuerpo
    d.line([(cx - 9, 14), (cx + 9, 14)], fill=shade(gold, 0.6))
    d.rectangle([cx - 4, 10, cx + 4, 13], fill=shade(gold, 0.45))                       # la mira
    d.text((cx - 3, 20), "L", fill=(255, 250, 210))                                     # su inicial, grabada
    d.rectangle([cx - 6, 36, cx + 6, 63], fill=shade(gold, 0.78))                       # el cargador largo
    for y in range(39, 63, 4):
        d.line([(cx - 5, y), (cx + 5, y)], fill=shade(gold, 0.5))
    _hand(d, cx + 20, 32 if not fire else 28, (214, 160, 120), (236, 232, 220), True, None)
    return img


if __name__ == "__main__":
    w_olla(); w_hollin(); w_desaparecidos(); w_mural()
    fumador(); velas(); colchon(); senora()
    mujer("camila", (210, 170, 80), (220, 90, 150), (60, 40, 60), (90, 80, 96), False, (24, 16, 28), False)
    mujer("veronica", (250, 236, 170), (60, 70, 120), (40, 40, 50), (140, 140, 150), True, (70, 140, 230), True)
    for pose in ["walk1", "walk2", "attack", "hurt", "dead"]:
        adicto(pose).save(OUT / f"dl_adicto_{pose}.png")
        pelado(pose).save(OUT / f"dl_pelado_{pose}.png")
        sicario(pose).save(OUT / f"dl_sicario_{pose}.png")
        pandillero(pose).save(OUT / f"dl_pandillero_{pose}.png")
    for fire in (False, True):
        img = gun_uzi(fire)
        outline(img)
        noise(img, 0.05)
        img.save(OUT / ("dw_uzi_fire.png" if fire else "dw_uzi.png"))
    print("ok")
