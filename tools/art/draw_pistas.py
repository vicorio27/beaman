"""Íconos de las pistas de los misterios (16x16): recortes de periódico y la carta de Madrid.
Uso: python tools/art/draw_pistas.py  (desde la carpeta del proyecto)"""
from PIL import Image, ImageDraw

INK = (38, 28, 44, 255)


def icon(name, fn):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    fn(ImageDraw.Draw(img))
    src = img.copy()
    sp, px = src.load(), img.load()
    for y in range(16):
        for x in range(16):
            if sp[x, y][3] == 0 and any(0 <= x + dx < 16 and 0 <= y + dy < 16 and sp[x + dx, y + dy][3] > 0
                                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = INK
    img.save(f"assets/items/{name}.png")


def recorte(foto):
    def f(d):
        d.rectangle([2, 3, 13, 13], fill=(226, 220, 200, 255))
        for k in range(3):
            d.line([(4, 6 + k * 2), (11, 6 + k * 2)], fill=(110, 110, 120, 255))
        if foto:
            d.rectangle([4, 4, 7, 8], fill=(80, 80, 90, 255))
    return f


if __name__ == "__main__":
    icon("recorte_1", recorte(False))
    icon("recorte_2", recorte(True))
    icon("recorte_3", recorte(False))
    icon("carta_ines", lambda d: (d.rectangle([2, 4, 13, 12], fill=(236, 226, 196, 255)),
                                  d.line([(2, 4), (8, 9), (13, 4)], fill=(150, 130, 100, 255)),
                                  d.rectangle([10, 5, 12, 7], fill=(200, 60, 60, 255))))
    print("listo")
