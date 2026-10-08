"""Lukas, árbitro de lucha libre: parado en dos patas, camiseta a rayas blancas y negras, corbatín y pito.
  assets/dreams/lukas_arbitro.png        quieto (mirando el ring)
  assets/dreams/lukas_arbitro_cuenta.png con la pata arriba (contando)
  assets/dreams/lukas_arbitro_cartel.png levantando un cartel en blanco (la lección del tutorial)
Uso: python tools/art/draw_lucha.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path("assets/dreams")
OUT.mkdir(parents=True, exist_ok=True)
INK = (38, 28, 44, 255)
BROWN = (170, 104, 52, 255)
WHITE = (244, 240, 232, 255)
BLACK = (30, 28, 32, 255)


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


def lukas(pose):
    img = Image.new("RGBA", (28, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([9, 28, 12, 35], fill=WHITE)                 # patas de atrás (medias blancas)
    d.rectangle([15, 28, 18, 35], fill=WHITE)
    d.rectangle([8, 26, 19, 30], fill=BLACK)                 # pantalón negro
    d.rectangle([7, 14, 20, 27], fill=WHITE)                 # camiseta de árbitro
    for x in range(8, 20, 3):
        d.line([(x, 14), (x, 27)], fill=BLACK)               # rayas
    d.polygon([(11, 14), (13, 16), (15, 14), (13, 13)], fill=(200, 30, 40, 255))  # corbatín
    d.ellipse([7, 2, 20, 15], fill=BROWN)                    # cabeza de beagle
    d.rectangle([10, 2, 17, 6], fill=WHITE)                  # mancha blanca
    d.polygon([(6, 5), (3, 14), (8, 13)], fill=(110, 64, 34, 255))   # orejas caídas
    d.polygon([(21, 5), (24, 14), (19, 13)], fill=(110, 64, 34, 255))
    d.ellipse([11, 10, 16, 15], fill=WHITE)                  # hocico
    d.point([(13, 11)], fill=BLACK)
    d.point([(10, 8), (17, 8)], fill=BLACK)                  # ojos
    d.line([(16, 13), (19, 16)], fill=(220, 210, 80, 255))   # el pito, colgando
    if pose == "cuenta":
        d.rectangle([20, 4, 23, 16], fill=BROWN)             # la pata arriba, contando
        d.rectangle([20, 3, 23, 5], fill=WHITE)
        d.rectangle([4, 16, 7, 24], fill=BROWN)
    elif pose == "cartel":
        d.rectangle([3, -1, 24, 1], fill=(0, 0, 0, 0))
        d.rectangle([4, 6, 7, 18], fill=BROWN)                # las dos patas arriba, sosteniendo
        d.rectangle([20, 6, 23, 18], fill=BROWN)
    else:
        d.rectangle([4, 16, 7, 24], fill=BROWN)              # patas de adelante, a los lados
        d.rectangle([20, 16, 23, 24], fill=BROWN)
    d.line([(20, 30), (25, 26)], fill=BROWN, width=2)        # la cola, parada
    return outline(img)


if __name__ == "__main__":
    lukas("quieto").save(OUT / "lukas_arbitro.png")
    lukas("cuenta").save(OUT / "lukas_arbitro_cuenta.png")
    lukas("cartel").save(OUT / "lukas_arbitro_cartel.png")
    print("listo")
