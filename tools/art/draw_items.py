"""Íconos de objetos (16x16) para el inventario y para las cosas tiradas en la ciudad.
Mismo estilo que el barrio (contorno violeta oscuro, colores gastados).
Salida: assets/items/<id>.png
Uso: python tools/art/draw_items.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path("assets/items")
OUT.mkdir(parents=True, exist_ok=True)
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


def icon(name, draw):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw(ImageDraw.Draw(img))
    outline(img).save(OUT / f"{name}.png")


def foto(d):
    d.rectangle([2, 3, 13, 13], fill=(226, 218, 196, 255))
    d.rectangle([4, 5, 11, 10], fill=(150, 130, 110, 255))
    d.rectangle([5, 7, 6, 10], fill=(90, 70, 70, 255))  # nene
    d.rectangle([8, 6, 10, 10], fill=(110, 100, 100, 255))  # la otra persona
    d.line([(9, 6), (11, 9)], fill=(226, 218, 196, 255))  # rostro cortado
    d.point((12, 12), fill=(180, 160, 120, 255))


def camiseta(d):
    d.polygon([(4, 3), (6, 2), (10, 2), (12, 3), (14, 6), (12, 7), (11, 6), (11, 13), (5, 13), (5, 6), (4, 7), (2, 6)],
              fill=(176, 170, 156, 255))
    d.line([(7, 2), (9, 2)], fill=(140, 134, 122, 255))
    d.point([(7, 9), (9, 11)], fill=(140, 120, 100, 255))  # manchas


def pan(d):
    d.ellipse([2, 5, 13, 12], fill=(196, 140, 72, 255))
    d.line([(5, 7), (6, 9)], fill=(150, 100, 50, 255))
    d.line([(8, 6), (9, 9)], fill=(150, 100, 50, 255))
    d.line([(4, 7), (11, 6)], fill=(226, 180, 110, 255))


def fruta(d):
    d.ellipse([3, 4, 12, 13], fill=(186, 72, 60, 255))
    d.rectangle([7, 4, 12, 13], fill=(232, 220, 170, 255))  # media manzana
    d.point([(9, 8), (10, 10)], fill=(110, 70, 50, 255))
    d.line([(7, 2), (8, 4)], fill=(90, 70, 50, 255))


def sandwich(d):
    d.polygon([(2, 10), (8, 3), (14, 10)], fill=(220, 196, 150, 255))
    d.line([(3, 10), (13, 10)], fill=(110, 160, 80, 255))
    d.polygon([(2, 11), (14, 11), (13, 13), (3, 13)], fill=(220, 196, 150, 255))
    d.line([(4, 11), (12, 11)], fill=(200, 90, 70, 255))


def sopa(d):
    d.pieslice([2, 4, 13, 14], 0, 180, fill=(196, 196, 204, 255))
    d.rectangle([3, 8, 12, 9], fill=(190, 120, 60, 255))
    for x in (5, 8, 11):
        d.line([(x, 2), (x - 1, 5)], fill=(230, 230, 236, 200))


def tinto(d):
    d.rectangle([4, 5, 10, 13], fill=(232, 228, 214, 255))
    d.rectangle([5, 5, 9, 6], fill=(90, 56, 40, 255))
    d.arc([9, 7, 13, 11], 270, 90, fill=(232, 228, 214, 255))
    d.line([(6, 2), (7, 4)], fill=(230, 230, 236, 200))


def lata(d):
    d.rectangle([5, 3, 10, 13], fill=(196, 64, 56, 255))
    d.rectangle([5, 3, 10, 4], fill=(180, 180, 190, 255))
    d.rectangle([5, 12, 10, 13], fill=(180, 180, 190, 255))
    d.line([(6, 7), (9, 7)], fill=(236, 220, 200, 255))
    d.line([(10, 8), (8, 10)], fill=(130, 40, 36, 255))  # abollada


def botella(d):
    d.rectangle([6, 2, 9, 4], fill=(96, 150, 110, 255))
    d.polygon([(6, 4), (9, 4), (11, 7), (11, 14), (4, 14), (4, 7)], fill=(96, 150, 110, 255))
    d.line([(5, 8), (5, 12)], fill=(160, 210, 170, 255))


def carton(d):
    d.polygon([(1, 6), (9, 3), (15, 7), (7, 11)], fill=(184, 150, 104, 255))
    d.polygon([(1, 6), (7, 11), (7, 14), (1, 9)], fill=(150, 120, 80, 255))
    d.polygon([(7, 11), (15, 7), (15, 10), (7, 14)], fill=(166, 134, 92, 255))
    d.line([(5, 5), (11, 8)], fill=(206, 180, 130, 255))


def plastico(d):
    d.polygon([(2, 4), (13, 2), (14, 12), (3, 14)], fill=(70, 110, 150, 255))
    d.line([(4, 6), (11, 4)], fill=(120, 160, 196, 255))
    d.line([(5, 10), (12, 8)], fill=(50, 84, 120, 255))


def pedido(d):
    d.polygon([(3, 5), (12, 5), (13, 14), (2, 14)], fill=(196, 160, 112, 255))
    d.rectangle([3, 3, 12, 5], fill=(176, 140, 96, 255))
    d.line([(5, 9), (10, 9)], fill=(150, 116, 80, 255))
    d.line([(6, 1), (7, 3)], fill=(230, 230, 236, 200))  # vapor


for name, fn in [("pedido", pedido), ("foto", foto), ("camiseta", camiseta), ("pan", pan), ("fruta", fruta), ("sandwich", sandwich),
                 ("sopa", sopa), ("tinto", tinto), ("lata", lata), ("botella", botella), ("carton", carton),
                 ("plastico", plastico)]:
    icon(name, fn)
print("íconos listos en", OUT)
