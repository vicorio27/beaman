"""Arte del recuerdo de la moto (la UM Renegade 180 café, la primera moto).
  assets/barrio/moto_parked.png   la café racer parqueada, vista oblicua (la ciudad y el taller)
  assets/moto/bike_c|l|r.png      él en la moto, desde atrás (derecho, inclinado a la izq. y der.)
  assets/moto/taxi|buseta|camion.png   tráfico desde atrás
  assets/moto/cono.png, bache.png, arbol.png, poste.png, valla.png, meta.png
  assets/moto/llegada.png         la llegada: la casa, la moto, alguien en la puerta (320x180)
Uso: python tools/art/draw_moto.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

MOTO = Path("assets/moto")
MOTO.mkdir(parents=True, exist_ok=True)
BARRIO = Path("assets/barrio")
INK = (38, 28, 44, 255)

TANK = (40, 44, 52, 255)        # negro mate
TANK_HI = (90, 96, 110, 255)
CHROME = (196, 200, 206, 255)
SEAT = (120, 74, 44, 255)       # cuero café
TIRE = (24, 22, 26, 255)
RED = (210, 50, 44, 255)
SKIN = (214, 160, 120, 255)
SHIRT = (232, 228, 220, 255)
JEAN = (60, 84, 130, 255)
HELMET = (30, 30, 36, 255)


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


def canvas(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def moto_parked():
    """De costado (oblicua, como el resto del barrio): mira a la izquierda."""
    img, d = canvas(30, 20)
    d.ellipse([1, 10, 9, 18], fill=TIRE)
    d.ellipse([20, 10, 28, 18], fill=TIRE)
    d.ellipse([3, 12, 7, 16], fill=CHROME)
    d.ellipse([22, 12, 26, 16], fill=CHROME)
    d.polygon([(8, 9), (14, 6), (19, 7), (21, 12), (9, 13)], fill=(70, 70, 76, 255))  # motor y chasis
    d.polygon([(9, 6), (16, 4), (18, 7), (10, 9)], fill=TANK)  # tanque
    d.line([(10, 5), (15, 4)], fill=TANK_HI)
    d.polygon([(18, 6), (26, 6), (27, 9), (19, 9)], fill=SEAT)  # asiento con joroba
    d.rectangle([25, 4, 27, 6], fill=SEAT)
    d.line([(5, 4), (8, 9)], fill=CHROME)  # horquilla
    d.line([(3, 4), (8, 4)], fill=(60, 60, 64, 255))  # manubrio bajo
    d.ellipse([3, 6, 6, 9], fill=(230, 220, 160, 255))  # farola redonda
    d.line([(12, 15), (24, 15)], fill=CHROME)  # exosto
    outline(img).save(BARRIO / "moto_parked.png")


def bike(lean):
    """Desde atrás: llanta, guardabarros con stop, asiento café, él (casco, camisa blanca, jean)."""
    img, d = canvas(48, 48)
    d.ellipse([18, 34, 30, 47], fill=TIRE)                      # llanta trasera
    d.rectangle([19, 36, 29, 44], fill=(40, 38, 42, 255))
    d.rectangle([17, 30, 31, 34], fill=TANK)                    # guardabarros
    d.rectangle([21, 31, 27, 33], fill=RED)                     # stop
    d.rectangle([22, 34, 26, 36], fill=(220, 200, 80, 255))     # placa
    d.line([(31, 38), (36, 40)], fill=CHROME, width=2)          # exosto
    d.rectangle([12, 22, 18, 30], fill=JEAN)                    # piernas a los costados
    d.rectangle([30, 22, 36, 30], fill=JEAN)
    d.rectangle([11, 29, 17, 32], fill=(50, 40, 36, 255))       # botas
    d.rectangle([31, 29, 37, 32], fill=(50, 40, 36, 255))
    d.rectangle([18, 25, 30, 30], fill=SEAT)                    # asiento café
    d.polygon([(15, 10), (33, 10), (35, 26), (13, 26)], fill=SHIRT)  # espalda
    d.line([(24, 12), (24, 25)], fill=(200, 196, 188, 255))
    d.line([(15, 12), (8, 20)], fill=SHIRT, width=3)            # brazos hacia el manubrio
    d.line([(33, 12), (40, 20)], fill=SHIRT, width=3)
    d.rectangle([5, 19, 9, 22], fill=SKIN)                      # manos
    d.rectangle([39, 19, 43, 22], fill=SKIN)
    d.line([(2, 18), (6, 20)], fill=(60, 60, 64, 255), width=2)  # manillares bajos
    d.line([(42, 20), (46, 18)], fill=(60, 60, 64, 255), width=2)
    d.ellipse([1, 13, 5, 17], fill=CHROME)                      # espejos
    d.ellipse([43, 13, 47, 17], fill=CHROME)
    d.rectangle([21, 8, 27, 10], fill=SKIN)                     # nuca
    d.ellipse([17, 0, 31, 11], fill=HELMET)                     # casco
    d.line([(20, 3), (27, 2)], fill=(80, 80, 92, 255))
    img = outline(img)
    if lean:
        img = img.rotate(lean, resample=Image.NEAREST, center=(24, 46))
    return img


def car(name, w, h, body, top, window=(70, 90, 110, 255), extra=None):
    img, d = canvas(w, h)
    d.rectangle([2, h // 3, w - 3, h - 6], fill=body)
    d.rectangle([5, 2, w - 6, h // 3 + 2], fill=top)
    d.rectangle([7, 4, w - 8, h // 3], fill=window)
    d.rectangle([4, h - 13, 9, h - 10], fill=RED)
    d.rectangle([w - 10, h - 13, w - 5, h - 10], fill=RED)
    d.rectangle([w // 2 - 6, h - 12, w // 2 + 6, h - 8], fill=(230, 210, 80, 255))
    d.rectangle([3, h - 6, 9, h - 1], fill=TIRE)
    d.rectangle([w - 10, h - 6, w - 4, h - 1], fill=TIRE)
    if extra:
        extra(d, w, h)
    outline(img).save(MOTO / f"{name}.png")


def taxi_sign(d, w, h):
    d.rectangle([w // 2 - 5, 0, w // 2 + 5, 2], fill=(250, 240, 200, 255))


def buseta_stripe(d, w, h):
    d.rectangle([2, h // 2, w - 3, h // 2 + 3], fill=(240, 240, 230, 255))
    d.rectangle([w // 2 - 8, h // 3 + 4, w // 2 + 8, h // 2 - 2], fill=(70, 90, 110, 255))


def camion_box(d, w, h):
    d.rectangle([0, 0, w - 1, h - 10], fill=(60, 90, 140, 255))
    d.line([(4, 4), (w - 5, 4)], fill=(90, 120, 170, 255))
    d.line([(w // 2, 2), (w // 2, h - 12)], fill=(40, 60, 100, 255))


def scenery():
    img, d = canvas(14, 18)  # cono
    d.polygon([(7, 0), (12, 15), (2, 15)], fill=(240, 110, 40, 255))
    d.rectangle([4, 7, 10, 9], fill=(250, 250, 250, 255))
    d.rectangle([0, 15, 14, 17], fill=(240, 110, 40, 255))
    outline(img).save(MOTO / "cono.png")

    img, d = canvas(40, 10)  # bache (plano, sobre el asfalto)
    d.ellipse([0, 1, 39, 9], fill=(30, 28, 32, 255))
    d.ellipse([6, 3, 30, 7], fill=(50, 46, 52, 255))
    d.ellipse([22, 2, 34, 5], fill=(90, 110, 130, 255))  # charco
    img.save(MOTO / "bache.png")

    img, d = canvas(40, 64)  # árbol (guayacán florecido: el pasado tenía color)
    d.rectangle([17, 36, 22, 63], fill=(96, 70, 50, 255))
    d.ellipse([2, 4, 38, 42], fill=(232, 196, 60, 255))
    d.ellipse([8, 0, 30, 24], fill=(246, 214, 90, 255))
    for x, y in [(8, 20), (26, 14), (16, 30), (30, 28)]:
        d.ellipse([x, y, x + 4, y + 4], fill=(200, 150, 40, 255))
    outline(img).save(MOTO / "arbol.png")

    img, d = canvas(14, 70)  # poste con cables
    d.rectangle([5, 4, 8, 69], fill=(150, 146, 140, 255))
    d.rectangle([0, 6, 13, 8], fill=(110, 100, 90, 255))
    outline(img).save(MOTO / "poste.png")

    img, d = canvas(64, 44)  # valla publicitaria vieja
    d.rectangle([8, 26, 11, 43], fill=(110, 100, 90, 255))
    d.rectangle([52, 26, 55, 43], fill=(110, 100, 90, 255))
    d.rectangle([0, 0, 63, 27], fill=(240, 230, 200, 255))
    d.rectangle([3, 3, 60, 24], fill=(200, 60, 50, 255))
    d.rectangle([6, 8, 40, 12], fill=(250, 240, 220, 255))
    d.rectangle([6, 15, 30, 18], fill=(250, 240, 220, 255))
    d.ellipse([44, 6, 58, 20], fill=(250, 210, 80, 255))
    outline(img).save(MOTO / "valla.png")

    img, d = canvas(120, 60)  # meta: arco de la calle de ella
    d.rectangle([0, 10, 6, 59], fill=(120, 110, 100, 255))
    d.rectangle([113, 10, 119, 59], fill=(120, 110, 100, 255))
    d.rectangle([0, 4, 119, 18], fill=(250, 240, 220, 255))
    for x in range(2, 118, 8):
        d.rectangle([x, 6, x + 3, 9], fill=INK)
        d.rectangle([x + 4, 10, x + 7, 13], fill=INK)
    outline(img).save(MOTO / "meta.png")


def llegada():
    """La llegada: atardecer, la casa de ella, la moto parqueada y alguien en la puerta."""
    img = Image.new("RGBA", (320, 180), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    for y in range(110):  # cielo de atardecer
        k = y / 110
        c = (int(250 - 60 * k), int(170 - 70 * k), int(110 + 20 * k), 255)
        d.line([(0, y), (319, y)], fill=c)
    d.ellipse([230, 50, 270, 90], fill=(255, 220, 140, 255))
    d.rectangle([0, 110, 319, 179], fill=(120, 110, 100, 255))  # calle
    d.rectangle([0, 104, 319, 112], fill=(170, 160, 150, 255))  # andén
    # la casa
    d.rectangle([60, 40, 220, 106], fill=(214, 150, 150, 255))
    d.polygon([(50, 42), (140, 14), (230, 42)], fill=(160, 70, 60, 255))
    d.rectangle([80, 56, 108, 78], fill=(250, 220, 150, 255))  # ventana con luz
    d.line([(94, 56), (94, 78)], fill=(120, 80, 70, 255))
    d.rectangle([180, 56, 206, 78], fill=(250, 220, 150, 255))
    d.rectangle([128, 54, 156, 106], fill=(90, 60, 50, 255))  # puerta abierta
    d.rectangle([131, 57, 153, 106], fill=(250, 210, 140, 255))  # luz de adentro
    # ella en la puerta: silueta, pelo largo, sin cara
    d.ellipse([136, 64, 148, 77], fill=(40, 28, 30, 255))
    d.rectangle([135, 70, 149, 86], fill=(40, 28, 30, 255))
    d.polygon([(136, 76), (148, 76), (152, 104), (132, 104)], fill=(150, 60, 80, 255))
    # la moto parqueada y él al lado
    d.ellipse([196, 132, 216, 152], fill=TIRE)
    d.ellipse([246, 132, 266, 152], fill=TIRE)
    d.ellipse([201, 137, 211, 147], fill=CHROME)
    d.ellipse([251, 137, 261, 147], fill=CHROME)
    d.polygon([(208, 126), (226, 118), (240, 120), (244, 134), (214, 136)], fill=(70, 70, 76, 255))
    d.polygon([(210, 118), (228, 112), (234, 120), (214, 124)], fill=TANK)
    d.polygon([(232, 116), (258, 116), (260, 124), (234, 124)], fill=SEAT)
    d.line([(198, 112), (208, 128)], fill=CHROME, width=2)
    d.line([(194, 112), (204, 112)], fill=(60, 60, 64, 255), width=2)
    d.rectangle([272, 96, 284, 128], fill=SHIRT)  # él
    d.ellipse([272, 84, 284, 97], fill=(30, 24, 26, 255))
    d.rectangle([272, 128, 278, 152], fill=JEAN)
    d.rectangle([279, 128, 284, 152], fill=JEAN)
    d.ellipse([286, 112, 298, 124], fill=HELMET)  # el casco en la mano
    img.save(MOTO / "llegada.png")


if __name__ == "__main__":
    moto_parked()
    bike(0).save(MOTO / "bike_c.png")
    bike(9).save(MOTO / "bike_l.png")
    bike(-9).save(MOTO / "bike_r.png")
    car("taxi", 44, 34, (240, 200, 40, 255), (230, 190, 40, 255), extra=taxi_sign)
    car("buseta", 56, 50, (60, 140, 90, 255), (60, 140, 90, 255), extra=buseta_stripe)
    car("camion", 60, 58, (200, 60, 50, 255), (200, 60, 50, 255), extra=camion_box)
    scenery()
    llegada()
    print("listo")
