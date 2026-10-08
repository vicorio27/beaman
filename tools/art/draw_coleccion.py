"""Los coleccionables y los objetos para proteger el cambuche.
  assets/items/pedazo_foto.png   un pedazo de la foto rota (icono 16x16)
  assets/items/foto_armada.png   la foto armada con los 7 pedazos (120x88), pegada con cinta: se ve la cara
  assets/items/alarma.png, trampa.png   íconos (alarma de latas, tabla con clavos)
Uso: python tools/art/draw_coleccion.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw

random.seed(3)
W, H = 120, 88
INK = (38, 28, 44, 255)
PAPER = (226, 216, 190, 255)
SEPIA = [(196, 170, 128, 255), (170, 142, 104, 255), (140, 112, 82, 255), (100, 78, 58, 255), (70, 54, 42, 255)]
TAPE = (240, 232, 200, 170)


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


def foto_entera():
    """La misma escena de foto_frente, pero con la esquina de vuelta: el papá, joven, riéndose."""
    img = Image.new("RGBA", (W, H), PAPER)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 6, W - 7, 46], fill=SEPIA[0])
    d.rectangle([6, 46, W - 7, H - 7], fill=SEPIA[1])
    d.ellipse([84, 14, 108, 38], fill=SEPIA[2])
    d.rectangle([94, 36, 97, 50], fill=SEPIA[3])
    for _ in range(60):
        d.point((random.randint(6, W - 7), random.randint(48, H - 8)), fill=SEPIA[2])
    # El nene con la pelota.
    d.ellipse([34, 40, 42, 48], fill=SEPIA[3])
    d.rectangle([35, 48, 41, 60], fill=SEPIA[2])
    d.rectangle([35, 60, 37, 70], fill=SEPIA[4])
    d.rectangle([39, 60, 41, 70], fill=SEPIA[4])
    d.ellipse([42, 62, 50, 70], fill=(220, 206, 176, 255), outline=SEPIA[4])
    # Él: camisa a cuadros, la mano en el hombro del nene.
    d.rectangle([54, 34, 66, 62], fill=SEPIA[3])
    for x in range(55, 66, 3):
        d.line([(x, 34), (x, 62)], fill=SEPIA[2])
    for y in range(36, 62, 4):
        d.line([(54, y), (66, y)], fill=SEPIA[2])
    d.rectangle([55, 62, 58, 78], fill=SEPIA[4])
    d.rectangle([62, 62, 65, 78], fill=SEPIA[4])
    d.line([(54, 38), (42, 49)], fill=SEPIA[3], width=2)
    # La cara: bigote negro, pelo peinado para atrás, riéndose con los ojos cerrados.
    d.ellipse([54, 21, 66, 35], fill=SEPIA[2])
    d.rectangle([54, 20, 66, 24], fill=SEPIA[4])
    d.line([(57, 27), (59, 27)], fill=SEPIA[4])
    d.line([(61, 27), (63, 27)], fill=SEPIA[4])
    d.rectangle([56, 30, 64, 31], fill=SEPIA[4])                  # bigote
    d.arc([57, 29, 63, 35], 20, 160, fill=SEPIA[4])               # la risa
    # Las grietas y la cinta: siete pedazos pegados.
    for a, b in [((52, 0), (50, 20)), ((50, 20), (58, 34)), ((58, 34), (70, 30)), ((70, 30), (78, 14)),
                 ((78, 14), (W, 10)), ((64, 6), (60, 24)), ((90, 4), (84, 14))]:
        d.line([a, b], fill=(120, 100, 76, 255))
    for box in [(40, 10, 52, 16), (70, 20, 82, 26), (80, 6, 96, 12)]:
        d.rectangle(box, fill=TAPE)
    img.save("assets/items/foto_armada.png")


def icons():
    def icon(name, fn):
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        fn(ImageDraw.Draw(img))
        outline(img).save(f"assets/items/{name}.png")
    icon("pedazo_foto", lambda d: (d.polygon([(2, 4), (12, 2), (14, 9), (9, 14), (3, 12)], fill=SEPIA[0]),
                                   d.polygon([(5, 6), (10, 5), (11, 10), (6, 11)], fill=SEPIA[2]),
                                   d.line([(2, 4), (12, 2)], fill=PAPER)))
    icon("foto_entera", lambda d: (d.rectangle([1, 3, 14, 13], fill=PAPER), d.rectangle([3, 5, 12, 11], fill=SEPIA[1]),
                                   d.rectangle([6, 6, 8, 10], fill=SEPIA[3]), d.rectangle([9, 5, 11, 8], fill=TAPE)))
    icon("alarma", lambda d: (d.line([(1, 3), (14, 3)], fill=(150, 120, 80, 255)),
                              *[d.rectangle([x, 5, x + 3, 11], fill=(190, 190, 200, 255)) for x in (2, 7, 11)]))
    icon("trampa", lambda d: (d.rectangle([1, 8, 14, 13], fill=(170, 120, 70, 255)),
                              *[d.line([(x, 8), (x, 4)], fill=(200, 200, 210, 255)) for x in (3, 6, 9, 12)]))


if __name__ == "__main__":
    foto_entera()
    icons()
    print("listo")
