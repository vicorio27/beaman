"""Arte de los trabajos: la bicicleta de Rapidito (de espaldas, con la caja naranja) para el reparto.
  assets/moto/bici_l.png, bici_c.png, bici_r.png   48x48 (inclinada a la izquierda, derecha, derecho)
Uso: python tools/art/draw_trabajos.py  (desde la carpeta del proyecto)"""
from PIL import Image, ImageDraw

INK = (38, 28, 44, 255)
ORANGE = (240, 120, 40, 255)
SKIN = (196, 150, 116, 255)


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


def bici(lean):
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([22, 34, 25, 47], fill=(30, 30, 34, 255))          # rueda de atrás (finita)
    d.line([(23, 28), (23, 34)], fill=(160, 160, 170, 255), width=2)
    d.rectangle([17, 24, 21, 33], fill=(50, 70, 120, 255))         # piernas (jean)
    d.rectangle([26, 24, 30, 33], fill=(50, 70, 120, 255))
    d.rectangle([16, 10, 31, 25], fill=(236, 232, 222, 255))       # camiseta blanca
    d.rectangle([14, 2, 33, 18], fill=ORANGE)                      # la caja de Rapidito, en la espalda
    d.rectangle([18, 6, 29, 9], fill=(250, 240, 220, 255))         # el logo
    d.line([(16, 12), (9, 18)], fill=(236, 232, 222, 255), width=3)  # brazos al manubrio
    d.line([(31, 12), (38, 18)], fill=(236, 232, 222, 255), width=3)
    d.rectangle([6, 17, 9, 20], fill=SKIN)
    d.rectangle([38, 17, 41, 20], fill=SKIN)
    d.line([(7, 19), (40, 19)], fill=(120, 120, 130, 255))           # manubrio
    img = outline(img)
    if lean:
        img = img.rotate(-8 * lean, resample=Image.NEAREST, center=(24, 46))
    return img


if __name__ == "__main__":
    bici(-1).save("assets/moto/bici_l.png")
    bici(0).save("assets/moto/bici_c.png")
    bici(1).save("assets/moto/bici_r.png")
    print("listo")
