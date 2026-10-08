"""Arte del centro (Día 3, la cédula): edificios oblicuos como los del barrio y los íconos del trámite.
  assets/barrio/registraduria.png, foto_express.png, edificio_centro.png
  assets/items/foto_doc.png, carta_german.png, direccion_zaida.png, cedula.png
Uso: python tools/art/draw_centro.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

WORLD = Path("assets/barrio")
ITEMS = Path("assets/items")
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


def registraduria(d):
    """Edificio público: gris, columnas, escalones, bandera y la ventanilla con rejas."""
    w, h = 112, 80
    d.rectangle([2, 4, w - 3, 26], fill=(150, 150, 156, 255))   # techo plano visto de arriba
    d.line([(4, 8), (w - 5, 8)], fill=(170, 170, 176, 255))
    d.rectangle([2, 26, w - 3, h - 8], fill=(196, 192, 182, 255))  # fachada
    d.rectangle([2, 26, w - 3, 31], fill=(170, 166, 158, 255))
    for x in range(10, w - 8, 18):                                # columnas
        d.rectangle([x, 32, x + 5, h - 9], fill=(214, 210, 200, 255))
        d.line([(x + 5, 32), (x + 5, h - 9)], fill=(160, 156, 148, 255))
    for x in (20, 74):                                            # ventanas con reja
        d.rectangle([x, 38, x + 14, 52], fill=(70, 86, 100, 255))
        for k in range(x + 2, x + 14, 3):
            d.line([(k, 38), (k, 52)], fill=(40, 40, 46, 255))
    d.rectangle([46, 40, 64, h - 9], fill=(90, 70, 56, 255))      # puerta
    d.rectangle([47, 41, 54, h - 9], fill=(110, 86, 66, 255))
    d.rectangle([40, h - 8, 70, h - 5], fill=(170, 166, 158, 255))  # escalones
    d.rectangle([36, h - 5, 74, h - 2], fill=(156, 152, 146, 255))
    d.line([(w - 14, 0), (w - 14, 26)], fill=(110, 110, 116, 255))  # asta
    d.rectangle([w - 13, 1, w - 3, 3], fill=(250, 210, 60, 255))  # bandera de Colombia
    d.rectangle([w - 13, 4, w - 3, 5], fill=(40, 70, 160, 255))
    d.rectangle([w - 13, 6, w - 3, 7], fill=(200, 40, 40, 255))
    d.line([(30, 70), (40, 72)], fill=(150, 146, 138, 255))       # mancha de humedad


def foto_express(d):
    w, h = 60, 54
    d.rectangle([2, 4, w - 3, 18], fill=(120, 96, 110, 255))     # techo
    d.rectangle([2, 18, w - 3, h - 3], fill=(226, 206, 120, 255))  # fachada amarilla
    d.rectangle([4, 20, w - 5, 27], fill=(200, 50, 60, 255))     # letrero
    d.rectangle([6, 30, 30, 44], fill=(150, 196, 214, 255))      # vitrina con fotos
    for x, y in [(8, 32), (16, 32), (8, 38), (16, 38), (24, 34)]:
        d.rectangle([x, y, x + 5, y + 4], fill=(240, 236, 226, 255))
    d.rectangle([36, 30, 50, h - 3], fill=(90, 70, 56, 255))     # puerta
    d.ellipse([52, 30, 57, 35], fill=(60, 60, 64, 255))          # cámara pintada


def edificio_centro(d):
    w, h = 72, 104
    d.rectangle([2, 4, w - 3, 20], fill=(130, 120, 118, 255))
    d.rectangle([2, 20, w - 3, h - 3], fill=(176, 150, 136, 255))
    for row in range(5):
        for col in range(4):
            x, y = 8 + col * 16, 26 + row * 14
            lit = (row * 3 + col) % 5 == 0
            d.rectangle([x, y, x + 8, y + 8], fill=(250, 220, 150, 255) if lit else (80, 92, 104, 255))
    d.rectangle([28, h - 18, 42, h - 3], fill=(90, 70, 56, 255))
    d.line([(4, 60), (14, 64)], fill=(150, 126, 114, 255))


def foto_doc(d):
    for i, (x, y) in enumerate([(2, 3), (8, 3), (2, 9), (8, 9)]):
        d.rectangle([x, y, x + 5, y + 5], fill=(232, 236, 240, 255))
        d.ellipse([x + 1, y + 1, x + 4, y + 4], fill=(110, 90, 80, 255))
        d.rectangle([x + 1, y + 4, x + 4, y + 5], fill=(214, 210, 196, 255))


def carta_german(d):
    d.polygon([(3, 2), (12, 2), (13, 14), (2, 14)], fill=(214, 186, 140, 255))  # bolsa de pan
    d.rectangle([3, 2, 12, 4], fill=(196, 166, 120, 255))
    d.line([(4, 7), (11, 7)], fill=(60, 60, 90, 255))
    d.line([(4, 9), (10, 9)], fill=(60, 60, 90, 255))
    d.line([(4, 11), (9, 11)], fill=(60, 60, 90, 255))


def direccion_zaida(d):
    d.rectangle([2, 3, 13, 13], fill=(236, 220, 236, 255))      # tarjeta perfumada
    d.line([(4, 6), (11, 6)], fill=(130, 60, 140, 255))
    d.line([(4, 8), (10, 8)], fill=(130, 60, 140, 255))
    d.line([(4, 10), (8, 10)], fill=(130, 60, 140, 255))
    d.ellipse([10, 9, 13, 12], fill=(200, 60, 100, 255))         # un corazoncito. Mal presagio.


def cedula(d):
    d.rectangle([1, 4, 14, 12], fill=(220, 214, 160, 255))
    d.rectangle([2, 5, 6, 10], fill=(160, 150, 140, 255))
    d.ellipse([3, 6, 5, 8], fill=(90, 70, 60, 255))
    d.line([(8, 6), (13, 6)], fill=(90, 90, 110, 255))
    d.line([(8, 8), (12, 8)], fill=(90, 90, 110, 255))
    d.rectangle([1, 4, 14, 5], fill=(250, 210, 60, 255))


def fuente(d):
    """La fuente del centro: con agua y monedas de deseos brillando en el fondo."""
    d.ellipse([0, 10, 55, 33], fill=(176, 170, 160, 255))      # borde de piedra
    d.ellipse([4, 13, 51, 30], fill=(70, 120, 140, 255))       # agua
    d.ellipse([10, 16, 44, 27], fill=(90, 146, 166, 255))
    for x, y in [(14, 21), (22, 24), (33, 19), (39, 23), (27, 18)]:
        d.point((x, y), fill=(250, 220, 110, 255))             # monedas
    d.rectangle([25, 2, 30, 20], fill=(196, 190, 180, 255))   # columna
    d.ellipse([21, 0, 34, 6], fill=(206, 200, 190, 255))
    d.line([(27, 6), (24, 14)], fill=(180, 220, 240, 255))    # chorrito
    d.line([(28, 6), (31, 14)], fill=(180, 220, 240, 255))


def vaso(d):
    d.polygon([(4, 4), (11, 4), (10, 13), (5, 13)], fill=(232, 228, 216, 255))
    d.rectangle([4, 4, 11, 5], fill=(200, 196, 186, 255))
    d.point([(7, 8), (8, 10)], fill=(220, 190, 90, 255))       # dos monedas, optimismo


if __name__ == "__main__":
    make(WORLD / "fuente.png", (56, 34), fuente)
    make(ITEMS / "vaso.png", (16, 16), vaso)
    make(WORLD / "registraduria.png", (112, 80), registraduria)
    make(WORLD / "foto_express.png", (60, 54), foto_express)
    make(WORLD / "edificio_centro.png", (72, 104), edificio_centro)
    for name, fn in [("foto_doc", foto_doc), ("carta_german", carta_german),
                     ("direccion_zaida", direccion_zaida), ("cedula", cedula)]:
        make(ITEMS / f"{name}.png", (16, 16), fn)
    print("listo")
