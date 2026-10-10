"""PLOMO (el Dealer): los jefes de los capítulos 1 y 2, y lo que se usa para ganarles (son acertijos).
  Don Lucho (cap. 1): el capo viejo de la esquina. Sombrero aguadeño, ruana, bigote blanco, chaleco
    antibalas de los ochenta debajo. Arriba, lámparas de araña: hay que tumbársela encima.
  El Coronel (cap. 2, y mini jefe del 1): barriga, gorra con placa de oro, gafas. Se para a contar
    plata (pose "count"): las cajas fuertes de la casa son la carnada.
Salida (assets/shooter/):
  dl_lucho_<pose>.png    walk1, walk2, attack, hurt, dead, stun (con la lámpara encima)
  dl_coronel_<pose>.png  walk1, walk2, attack, hurt, dead, count
  dd_arana.png, dd_arana_rota.png, dd_gancho.png, dd_gancho_suelto.png (la cuerda de cada araña), dd_cajafuerte.png, dd_cajafuerte_abierta.png, dd_fajo.png
Uso: python tools/art/draw_plomo_jefes.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw
import draw_shooter_kid as kid
from draw_shooter import OUT, INK, outline

random.seed(1987)
GOLD = (236, 190, 64, 255)
GOLD_DK = (170, 128, 40, 255)
SKIN_OLD = (206, 164, 128, 255)
WHITE = (236, 232, 222, 255)


def finish(img, hurt=False, scale=2):
    img = outline(img)
    if hurt:
        px = img.load()
        for y in range(img.height):
            for x in range(img.width):
                c = px[x, y]
                if c[3] and c != INK:
                    px[x, y] = (min(255, c[0] + 90), c[1] // 2, c[2] // 2, c[3])
    img = kid.crayon(img, 0.06)
    return img.resize((img.width * scale, img.height * scale), Image.NEAREST)


# ------------------------------------------------------------------ Don Lucho

def lucho(pose):
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ruana, ruana_dk = (120, 92, 70, 255), (84, 62, 48, 255)
    pants = (54, 50, 56, 255)
    if pose == "dead":
        d.rectangle([4, 44, 36, 53], fill=ruana)
        for x in range(6, 36, 6):
            d.line([(x, 44), (x, 53)], fill=ruana_dk)
        d.ellipse([30, 42, 39, 51], fill=SKIN_OLD)
        d.ellipse([0, 46, 12, 52], fill=WHITE)                          # el sombrero, rodó
        d.rectangle([2, 47, 10, 48], fill=(30, 26, 26, 255))
        return finish(img)
    sway = {"walk1": -1, "walk2": 1, "attack": 0, "hurt": 2, "stun": 0}[pose]
    low = 6 if pose == "stun" else 0                                    # aplastado: más bajito
    # piernas y bastón
    if pose != "stun":
        l1 = 55 if pose != "walk2" else 52
        l2 = 55 if pose != "walk1" else 52
        d.rectangle([13, 40, 18, l1], fill=pants)
        d.rectangle([22, 40, 27, l2], fill=pants)
        d.rectangle([11, l1 - 1, 18, 55], fill=(40, 30, 24, 255))
        d.rectangle([22, l2 - 1, 29, 55], fill=(40, 30, 24, 255))
    else:
        d.rectangle([8, 48, 32, 55], fill=pants)                        # sentado de culo
    # la ruana (un poncho de rayas) con el chaleco de los ochenta asomando
    top = 18 + low
    d.polygon([(6 + sway, 42 + low // 2), (20 + sway, top), (34 + sway, 42 + low // 2)], fill=ruana)
    for k in range(3):
        y = top + 8 + k * 6
        d.line([(9 + sway + k * 2, y + 6), (31 + sway - k * 2, y + 6)], fill=ruana_dk, width=2)
    d.rectangle([16 + sway, top + 2, 24 + sway, top + 14], fill=(46, 60, 50, 255))   # el chaleco, verde militar
    d.line([(16 + sway, top + 6), (24 + sway, top + 6)], fill=(30, 40, 34, 255))
    # cabeza: bigote blanco, cachetes, diente de oro
    d.ellipse([13 + sway, top - 13, 27 + sway, top + 1], fill=SKIN_OLD)
    d.rectangle([15 + sway, top - 5, 25 + sway, top - 3], fill=WHITE)              # bigote
    d.point((17 + sway, top - 8), fill=INK)
    d.point((23 + sway, top - 8), fill=INK)
    d.point((21 + sway, top - 2), fill=GOLD)
    # sombrero aguadeño
    d.rectangle([8 + sway, top - 12, 32 + sway, top - 10], fill=WHITE)
    d.rectangle([13 + sway, top - 18, 27 + sway, top - 11], fill=WHITE)
    d.rectangle([13 + sway, top - 13, 27 + sway, top - 12], fill=(30, 26, 26, 255))
    if pose == "attack":
        d.rectangle([20, top + 4, 34, top + 7], fill=SKIN_OLD)
        d.rectangle([30, top + 2, 37, top + 6], fill=(150, 150, 160, 255))       # el revólver
        d.ellipse([34, top - 2, 40, top + 9], fill=(255, 220, 90, 255))
    elif pose != "stun":
        d.line([(31 + sway, top + 10), (35, 55)], fill=(110, 70, 40, 255), width=2)  # el bastón
        d.ellipse([29 + sway, top + 8, 33 + sway, top + 12], fill=GOLD)
    if pose == "stun":  # la araña encima, y pajaritos
        d.rectangle([10, top - 22, 30, top - 18], fill=GOLD)
        for x in (11, 17, 23, 29):
            d.ellipse([x - 2, top - 19, x + 2, top - 14], fill=(200, 230, 250, 255))
        for x, y in ((6, top - 26), (32, top - 28), (20, top - 30)):
            d.line([(x - 2, y), (x + 2, y)], fill=(255, 240, 120, 255))
            d.line([(x, y - 2), (x, y + 2)], fill=(255, 240, 120, 255))
    return finish(img, hurt=pose == "hurt")


# ------------------------------------------------------------------ El Coronel

def coronel(pose):
    img = Image.new("RGBA", (40, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    green, green_dk = (60, 110, 70, 255), (38, 76, 48, 255)
    skin = (222, 184, 150, 255)
    if pose == "dead":
        d.ellipse([2, 40, 38, 54], fill=green)
        d.rectangle([28, 40, 38, 46], fill=green_dk)
        d.rectangle([4, 46, 12, 50], fill=GOLD)                            # la gorra, al lado
        for x in range(10, 32, 5):                                          # los billetes, regados
            d.rectangle([x, 50, x + 4, 53], fill=(120, 190, 110, 255))
        return finish(img)
    sway = {"walk1": -1, "walk2": 1, "attack": 0, "hurt": 2, "count": 0}[pose]
    l1 = 55 if pose != "walk2" else 52
    l2 = 55 if pose != "walk1" else 52
    d.rectangle([12, 40, 18, l1], fill=green_dk)
    d.rectangle([22, 40, 28, l2], fill=green_dk)
    d.rectangle([10, l1 - 2, 18, 55], fill=(20, 20, 24, 255))
    d.rectangle([22, l2 - 2, 30, 55], fill=(20, 20, 24, 255))
    d.ellipse([5 + sway, 16, 35 + sway, 44], fill=green)                    # la barriga
    d.rectangle([18 + sway, 18, 21 + sway, 42], fill=green_dk)             # botones que sufren
    for y in (24, 30, 36):
        d.point((20 + sway, y), fill=GOLD)
    d.rectangle([5 + sway, 16, 11 + sway, 19], fill=GOLD)                  # charreteras
    d.rectangle([29 + sway, 16, 35 + sway, 19], fill=GOLD)
    d.rectangle([24 + sway, 21, 28 + sway, 24], fill=GOLD)                 # la placa
    d.rectangle([7 + sway, 38, 33 + sway, 40], fill=(40, 30, 24, 255))     # el cinturón, en la última
    head_y = 4 if pose != "count" else 7                                   # contando: la cabeza agachada
    d.ellipse([12 + sway, head_y, 28 + sway, head_y + 15], fill=skin)
    d.rectangle([13 + sway, head_y + 5, 19 + sway, head_y + 8], fill=(20, 20, 24, 255))   # gafas
    d.rectangle([21 + sway, head_y + 5, 27 + sway, head_y + 8], fill=(20, 20, 24, 255))
    d.rectangle([15 + sway, head_y + 10, 25 + sway, head_y + 12], fill=(60, 40, 30, 255))  # bigote
    d.rectangle([10 + sway, head_y - 2, 30 + sway, head_y + 3], fill=green_dk)            # gorra
    d.rectangle([9 + sway, head_y + 2, 31 + sway, head_y + 4], fill=(20, 20, 24, 255))
    d.rectangle([18 + sway, head_y - 1, 22 + sway, head_y + 1], fill=GOLD)
    if pose == "attack":
        d.rectangle([22, 24, 36, 27], fill=green)
        d.rectangle([32, 22, 39, 26], fill=(40, 40, 46, 255))
        d.ellipse([34, 18, 40, 30], fill=(255, 220, 90, 255))
    elif pose == "count":  # los dos brazos al frente, un abanico de billetes, la lengua afuera
        d.rectangle([9, 24, 31, 28], fill=green)
        for k in range(5):
            d.polygon([(20, 30), (12 + k * 4, 18), (15 + k * 4, 18)], fill=(130, 200, 110, 255))
        d.rectangle([19, head_y + 12, 21, head_y + 14], fill=(220, 90, 100, 255))
    else:
        d.rectangle([3 + sway, 20, 8 + sway, 36], fill=green)
        d.rectangle([32 + sway, 20, 37 + sway, 36], fill=green)
    return finish(img, hurt=pose == "hurt")


# ------------------------------------------------------------------ lo de la casa

def arana():
    """Una lámpara de araña colgando de una cadena (se dibuja arriba, cerca del techo)."""
    img = Image.new("RGBA", (34, 46), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([(17, 0), (17, 18)], fill=(120, 110, 90, 255), width=1)
    for y in range(1, 18, 3):
        d.ellipse([16, y, 18, y + 2], outline=GOLD_DK)
    d.ellipse([12, 16, 22, 22], fill=GOLD)
    d.polygon([(2, 26), (17, 20), (32, 26), (28, 30), (6, 30)], fill=GOLD)
    d.line([(4, 27), (30, 27)], fill=GOLD_DK)
    for x in (4, 10, 17, 24, 30):                                           # velas
        d.rectangle([x - 1, 21, x + 1, 26], fill=WHITE)
        d.ellipse([x - 2, 16, x + 2, 21], fill=(255, 220, 110, 255))
    for x in range(5, 31, 3):                                               # cristales
        h = 33 + (x * 7) % 9
        d.line([(x, 30), (x, h)], fill=(200, 230, 250, 255))
        d.ellipse([x - 1, h - 1, x + 1, h + 2], fill=(230, 245, 255, 255))
    d.polygon([(14, 30), (20, 30), (17, 45)], fill=GOLD_DK)
    outline(img)
    img.save(OUT / "dd_arana.png")


def arana_rota():
    img = Image.new("RGBA", (40, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(2, 12), (12, 5), (30, 6), (38, 12)], fill=GOLD)
    d.line([(8, 9), (32, 8)], fill=GOLD_DK)
    for _ in range(26):
        x, y = random.randint(0, 39), random.randint(6, 13)
        d.point((x, y), fill=random.choice([(200, 230, 250, 255), (255, 255, 255, 255), GOLD]))
    d.rectangle([22, 2, 24, 7], fill=WHITE)
    outline(img)
    img.save(OUT / "dd_arana_rota.png")


def gancho(cut):
    """El gancho de la pared donde se amarra la cuerda de una araña (cortada: la araña ya cayó)."""
    img = Image.new("RGBA", (16, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rope = (200, 170, 110, 255)
    d.rectangle([3, 26, 12, 29], fill=GOLD)                                # el gancho de bronce
    d.rectangle([6, 22, 9, 33], fill=GOLD_DK)
    if cut:
        d.line([(7, 25), (5, 18)], fill=rope, width=2)                       # la punta, deshilachada
        d.point((4, 17), fill=rope)
        d.point((6, 16), fill=rope)
    else:
        for y in range(0, 26, 2):                                           # la cuerda, tensa, para arriba
            d.line([(7 + (y // 2) % 2, y), (7 + (y // 2) % 2, y + 1)], fill=rope, width=2)
        d.line([(4, 27), (11, 25)], fill=rope, width=2)                     # la vuelta en el gancho
        d.line([(4, 25), (11, 28)], fill=rope, width=2)
    outline(img)
    img.save(OUT / ("dd_gancho_suelto.png" if cut else "dd_gancho.png"))


def cajafuerte(open_):
    img = Image.new("RGBA", (26, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body, dark = (84, 92, 88, 255), (54, 60, 58, 255)
    d.rectangle([1, 2, 24, 29], fill=body)
    d.line([(1, 2), (24, 2)], fill=(130, 140, 134, 255))
    if not open_:
        d.rectangle([4, 5, 21, 26], fill=dark)
        d.ellipse([8, 10, 17, 19], fill=(170, 170, 176, 255))              # la clave
        d.ellipse([11, 13, 14, 16], fill=dark)
        for a in range(0, 8):
            d.point((12 + [0, 3, 4, 3, 0, -3, -4, -3][a], 14 + [-4, -3, 0, 3, 4, 3, 0, -3][a]), fill=INK)
        d.rectangle([18, 12, 20, 18], fill=GOLD)                            # la manija de oro
        d.text((6, 20), "$", fill=GOLD)
    else:
        d.rectangle([4, 5, 21, 26], fill=(16, 14, 16, 255))                # vacía
        d.polygon([(21, 5), (25, 1), (25, 30), (21, 26)], fill=dark)       # la puerta, abierta
        d.line([(10, 18), (16, 22)], fill=(120, 190, 110, 255))            # un billete que quedó
    outline(img)
    img.save(OUT / ("dd_cajafuerte_abierta.png" if open_ else "dd_cajafuerte.png"))


def fajo():
    img = Image.new("RGBA", (18, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k in range(3):
        d.rectangle([1 + k, 7 - k * 2, 16 - k, 11 - k * 2], fill=(120 + k * 20, 190, 110, 255))
    d.rectangle([7, 2, 10, 10], fill=(240, 220, 120, 255))                 # la liga
    outline(img)
    img.save(OUT / "dd_fajo.png")


if __name__ == "__main__":
    for pose in ["walk1", "walk2", "attack", "hurt", "dead", "stun"]:
        lucho(pose).save(OUT / f"dl_lucho_{pose}.png")
    for pose in ["walk1", "walk2", "attack", "hurt", "dead", "count"]:
        coronel(pose).save(OUT / f"dl_coronel_{pose}.png")
    arana(); arana_rota(); gancho(False); gancho(True); cajafuerte(False); cajafuerte(True); fajo()
    print("ok")
