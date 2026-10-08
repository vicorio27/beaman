"""Arte de la economía y el cambuche: íconos nuevos (16x16, assets/items/) y cosas del mundo
(assets/barrio/): el cambuche en sus mejoras, el baño público y el carrito de Doña Rosa.
Mismo estilo que draw_items.py y draw_barrio.py (contorno violeta oscuro, colores gastados).
Uso: python tools/art/draw_economy.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

ITEMS = Path("assets/items")
WORLD = Path("assets/barrio")
INK = (38, 28, 44, 255)


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


def make(path, size, draw):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw(ImageDraw.Draw(img))
    outline(img).save(path)


# ------------------------------------------------------------------ íconos

def cama_carton(d):
    d.polygon([(1, 8), (8, 5), (15, 8), (8, 12)], fill=(184, 150, 104, 255))
    d.polygon([(1, 8), (8, 12), (8, 14), (1, 10)], fill=(150, 120, 80, 255))
    d.polygon([(8, 12), (15, 8), (15, 10), (8, 14)], fill=(166, 134, 92, 255))
    d.line([(3, 8), (13, 8)], fill=(150, 120, 80, 255))
    d.line([(4, 7), (12, 7)], fill=(206, 180, 130, 255))


def cuerda(d):
    d.ellipse([2, 3, 13, 13], outline=(170, 140, 90, 255), width=2)
    d.ellipse([5, 6, 10, 10], outline=(140, 110, 70, 255), width=1)
    d.line([(12, 11), (15, 15)], fill=(170, 140, 90, 255))


def vela(d):
    d.rectangle([6, 6, 9, 14], fill=(232, 222, 196, 255))
    d.line([(6, 6), (6, 14)], fill=(250, 244, 226, 255))
    d.point((7, 5), fill=(60, 50, 50, 255))
    d.polygon([(7, 1), (9, 4), (7, 5), (6, 4)], fill=(250, 196, 80, 255))


def arroz(d):
    d.polygon([(3, 4), (12, 4), (13, 14), (2, 14)], fill=(220, 214, 196, 255))
    d.rectangle([3, 2, 12, 4], fill=(196, 188, 170, 255))
    d.rectangle([4, 8, 11, 11], fill=(196, 72, 60, 255))
    d.point([(5, 6), (8, 6), (10, 13)], fill=(250, 250, 240, 255))


def concentrado(d):
    d.polygon([(3, 3), (12, 3), (13, 14), (2, 14)], fill=(196, 120, 60, 255))
    d.rectangle([3, 2, 12, 3], fill=(160, 90, 44, 255))
    d.ellipse([5, 7, 10, 12], fill=(240, 220, 190, 255))  # el dibujito de un perro
    d.point([(6, 9), (9, 9)], fill=(60, 40, 40, 255))
    d.point([(5, 7), (10, 7)], fill=(120, 70, 40, 255))


def pelota_trapo(d):
    d.ellipse([3, 3, 12, 12], fill=(176, 170, 156, 255))
    d.line([(4, 6), (11, 9)], fill=(140, 134, 122, 255))
    d.line([(6, 3), (8, 12)], fill=(140, 134, 122, 255))
    d.line([(11, 4), (14, 1)], fill=(170, 140, 90, 255))  # el nudo de cuerda


def toldo(d):
    d.polygon([(1, 9), (8, 3), (15, 9)], fill=(70, 110, 150, 255))
    d.line([(8, 3), (8, 9)], fill=(50, 84, 120, 255))
    d.line([(1, 9), (1, 14)], fill=(170, 140, 90, 255))
    d.line([(15, 9), (15, 14)], fill=(170, 140, 90, 255))


def cocinita(d):
    d.rectangle([4, 6, 11, 14], fill=(170, 176, 180, 255))
    d.line([(4, 8), (11, 8)], fill=(196, 72, 60, 255))
    d.rectangle([6, 11, 9, 13], fill=(60, 50, 50, 255))
    d.polygon([(7, 1), (9, 5), (6, 5)], fill=(250, 196, 80, 255))


def candado(d):
    d.arc([4, 1, 11, 9], 180, 360, fill=(150, 156, 160, 255), width=2)
    d.rectangle([3, 6, 12, 14], fill=(200, 160, 60, 255))
    d.point((7, 9), fill=(60, 50, 50, 255))
    d.line([(7, 10), (7, 11)], fill=(60, 50, 50, 255))


def cobija(d):
    d.polygon([(2, 4), (14, 3), (14, 13), (2, 14)], fill=(120, 70, 96, 255))
    for x in range(4, 14, 3):
        d.line([(x, 4), (x, 13)], fill=(150, 96, 120, 255))
    d.line([(2, 8), (14, 8)], fill=(96, 56, 80, 255))


def empanada(d):
    d.pieslice([2, 4, 14, 16], 180, 360, fill=(222, 160, 70, 255))
    for x in range(4, 13, 2):
        d.point((x, 9), fill=(170, 110, 50, 255))
    d.point([(6, 6), (10, 7)], fill=(240, 196, 110, 255))


def arepa(d):
    d.ellipse([2, 4, 13, 12], fill=(232, 210, 150, 255))
    d.ellipse([4, 6, 11, 10], fill=(244, 230, 190, 255))
    d.point([(5, 7), (9, 9), (10, 6)], fill=(150, 110, 60, 255))  # quemadito


def aguapanela(d):
    d.rectangle([4, 5, 11, 14], fill=(226, 218, 196, 255))
    d.rectangle([5, 6, 10, 9], fill=(170, 110, 50, 255))
    d.line([(12, 7), (13, 10)], fill=(226, 218, 196, 255))
    d.line([(7, 1), (8, 3)], fill=(230, 230, 236, 200))


# ------------------------------------------------------------------ mundo

def cambuche(d):
    """Cama de cartón contra lo que haya, con la caja al lado."""
    d.polygon([(2, 9), (20, 6), (30, 9), (12, 13)], fill=(184, 150, 104, 255))
    d.polygon([(2, 9), (12, 13), (12, 15), (2, 11)], fill=(150, 120, 80, 255))
    d.polygon([(12, 13), (30, 9), (30, 11), (12, 15)], fill=(166, 134, 92, 255))
    d.line([(6, 10), (24, 8)], fill=(206, 180, 130, 255))
    d.rectangle([24, 2, 31, 9], fill=(160, 120, 76, 255))  # la caja
    d.line([(24, 4), (31, 4)], fill=(130, 96, 60, 255))


def cambuche_toldo(d):
    d.polygon([(2, 19), (20, 16), (30, 19), (12, 23)], fill=(184, 150, 104, 255))
    d.polygon([(2, 19), (12, 23), (12, 25), (2, 21)], fill=(150, 120, 80, 255))
    d.rectangle([24, 12, 31, 19], fill=(160, 120, 76, 255))
    d.line([(1, 4), (1, 21)], fill=(110, 84, 56, 255))
    d.line([(29, 2), (29, 18)], fill=(110, 84, 56, 255))
    d.polygon([(0, 4), (29, 1), (31, 6), (2, 10)], fill=(70, 110, 150, 255))
    d.line([(4, 6), (27, 3)], fill=(120, 160, 196, 255))
    d.line([(6, 9), (30, 5)], fill=(50, 84, 120, 255))


def cocinita_world(d):
    d.rectangle([1, 3, 6, 8], fill=(170, 176, 180, 255))
    d.line([(1, 5), (6, 5)], fill=(196, 72, 60, 255))
    d.polygon([(3, 0), (5, 3), (2, 3)], fill=(250, 196, 80, 255))


def bano(d):
    """Baño público: casilla de plástico con cartel."""
    d.rectangle([1, 6, 18, 33], fill=(64, 104, 140, 255))
    d.rectangle([1, 2, 18, 6], fill=(84, 126, 164, 255))
    d.rectangle([4, 12, 15, 32], fill=(54, 90, 124, 255))  # puerta
    d.point((13, 22), fill=(220, 220, 220, 255))
    d.rectangle([5, 8, 14, 10], fill=(232, 222, 196, 255))  # cartel
    d.line([(6, 9), (13, 9)], fill=(60, 50, 50, 255))
    d.line([(1, 20), (2, 28)], fill=(96, 120, 80, 255))  # mugre verde abajo


def food_cart(d):
    """El carrito de Doña Rosa: parrilla, sombrilla y una olla."""
    d.line([(14, 2), (14, 14)], fill=(110, 84, 56, 255))
    d.polygon([(2, 6), (14, 0), (27, 6)], fill=(196, 72, 60, 255))
    d.line([(8, 3), (20, 3)], fill=(232, 222, 196, 255))
    d.rectangle([3, 13, 26, 21], fill=(150, 156, 160, 255))
    d.rectangle([3, 12, 26, 13], fill=(90, 80, 80, 255))
    d.rectangle([5, 9, 10, 12], fill=(170, 176, 180, 255))  # olla
    d.rectangle([13, 10, 23, 12], fill=(222, 160, 70, 255))  # empanadas
    d.ellipse([4, 20, 8, 24], fill=(40, 36, 40, 255))
    d.ellipse([21, 20, 25, 24], fill=(40, 36, 40, 255))


PALLET = (176, 140, 92, 255)
PALLET_DK = (130, 98, 62, 255)
ZINC = (150, 156, 162, 255)
ZINC_DK = (110, 116, 122, 255)


def estiba(d):
    for y in (3, 7, 11):
        d.rectangle([1, y, 14, y + 2], fill=PALLET)
    for x in (2, 7, 12):
        d.rectangle([x, 3, x + 1, 13], fill=PALLET_DK)


def clavos(d):
    d.polygon([(3, 4), (12, 4), (13, 14), (2, 14)], fill=(150, 120, 90, 255))
    d.rectangle([3, 3, 12, 5], fill=(130, 100, 70, 255))
    for x in (5, 8, 11):
        d.line([(x, 1), (x, 6)], fill=(190, 194, 200, 255))
        d.point((x, 1), fill=(220, 224, 230, 255))


def zinc(d):
    d.polygon([(1, 5), (14, 2), (15, 11), (2, 14)], fill=ZINC)
    for k in range(4):
        d.line([(3 + k * 3, 4 - k // 2), (4 + k * 3, 13 - k // 2)], fill=ZINC_DK)


def radio(d):
    d.rectangle([2, 6, 13, 14], fill=(150, 60, 50, 255))
    d.ellipse([3, 8, 8, 13], fill=(60, 50, 50, 255))
    d.rectangle([9, 8, 12, 10], fill=(230, 210, 150, 255))
    d.line([(12, 6), (14, 1)], fill=(190, 194, 200, 255))


def rancho(d):
    """Nivel 3: paredes de estibas, techo de plástico, cortina de puerta, la caja adentro."""
    d.rectangle([2, 12, 38, 33], fill=PALLET)
    for y in range(14, 33, 4):
        d.line([(2, y), (38, y)], fill=PALLET_DK)
    for x in (2, 14, 26, 37):
        d.line([(x, 12), (x, 33)], fill=PALLET_DK)
    d.polygon([(0, 13), (20, 3), (40, 13)], fill=(70, 110, 150, 255))   # techo de plástico
    d.line([(6, 11), (20, 4)], fill=(120, 160, 196, 255))
    d.rectangle([15, 18, 25, 33], fill=(150, 70, 80, 255))              # cortina
    d.line([(20, 18), (20, 33)], fill=(120, 50, 60, 255))
    d.rectangle([30, 26, 37, 33], fill=(160, 120, 76, 255))              # la caja, afuera


def ranchito(d):
    """Nivel 4: techo de zinc, ventanita, matera, radio con antena, el plato de Lukas."""
    d.rectangle([2, 14, 42, 37], fill=(196, 170, 120, 255))             # estibas pintadas
    for y in range(16, 37, 4):
        d.line([(2, y), (42, y)], fill=(170, 140, 96, 255))
    d.polygon([(0, 15), (22, 2), (44, 15)], fill=ZINC)                  # zinc
    for k in range(0, 44, 4):
        d.line([(k, 15 - k * 13 // 44 if k < 22 else 15 - (44 - k) * 13 // 22), (k, 15)], fill=ZINC_DK)
    d.rectangle([17, 21, 27, 37], fill=(110, 80, 60, 255))               # puerta de tabla
    d.point((25, 29), fill=(220, 200, 120, 255))
    d.rectangle([5, 20, 12, 26], fill=(250, 220, 150, 255))              # ventanita con luz
    d.line([(8, 20), (8, 26)], fill=(120, 90, 60, 255))
    d.rectangle([31, 20, 39, 27], fill=(150, 60, 50, 255))               # radio en la repisa
    d.line([(38, 20), (41, 10)], fill=(190, 194, 200, 255))              # antena
    d.rectangle([34, 33, 39, 37], fill=(196, 72, 60, 255))               # matera (lata pintada)
    d.ellipse([33, 28, 40, 34], fill=(90, 150, 70, 255))
    d.ellipse([4, 34, 10, 38], fill=(170, 176, 180, 255))                # el plato de Lukas


if __name__ == "__main__":
    for name, fn in [("estiba", estiba), ("clavos", clavos), ("zinc", zinc), ("radio", radio)]:
        make(ITEMS / f"{name}.png", (16, 16), fn)
    make(WORLD / "rancho.png", (40, 34), rancho)
    make(WORLD / "ranchito.png", (44, 39), ranchito)
    for name, fn in [("cama_carton", cama_carton), ("cuerda", cuerda), ("vela", vela), ("arroz", arroz),
                     ("concentrado", concentrado), ("pelota_trapo", pelota_trapo), ("toldo", toldo),
                     ("cocinita", cocinita), ("candado", candado), ("cobija", cobija), ("empanada", empanada),
                     ("arepa", arepa), ("aguapanela", aguapanela)]:
        make(ITEMS / f"{name}.png", (16, 16), fn)
    make(WORLD / "cambuche.png", (32, 16), cambuche)
    make(WORLD / "cambuche_toldo.png", (32, 26), cambuche_toldo)
    make(WORLD / "cocinita.png", (8, 10), cocinita_world)
    make(WORLD / "bano.png", (20, 35), bano)
    make(WORLD / "food_cart.png", (29, 25), food_cart)
    print("listo")
