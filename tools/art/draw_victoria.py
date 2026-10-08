"""Lo de Victoria: el colegio (en el centro) y el dibujo que ella deja en la reja.
  assets/barrio/colegio.png         fachada amarilla, cartel COLEGIO, dibujos de niños en las ventanas, reja
  assets/items/dibujo_victoria.png  ícono: un dibujo de crayón (un señor con un perro)
  assets/items/dibujo_grande.png    el dibujo en grande (120x88), para mirarlo
Uso: python tools/art/draw_victoria.py  (desde la carpeta del proyecto)"""
import random
import sys
from pathlib import Path
from PIL import Image, ImageDraw
sys.path.insert(0, str(Path(__file__).parent))
import draw_barrio as B
from draw_barrio import building, save, rgba, INK

random.seed(30)


def colegio():
    img = building(100, 44, 22, (226, 196, 96), roof="tile", windows=[(6, 18, 18, 12), (76, 18, 18, 12)],
                   door=(40, 20), lit=(0, 1), rust=0, sign=("COLEGIO", 22, 2, (40, 90, 140), (250, 240, 200)))
    d = ImageDraw.Draw(img)
    H = img.height
    for wx in (6, 76):  # dibujos de niños pegados en las ventanas
        d.ellipse([wx + 2, 42, wx + 7, 47], fill=rgba((250, 200, 40)))
        d.polygon([(wx + 10, 50), (wx + 14, 44), (wx + 17, 50)], fill=rgba((220, 70, 70)))
    for x in range(2, 98, 5):  # la reja de adelante
        d.line([(x, H - 12), (x, H - 1)], fill=rgba((60, 70, 80)))
    d.line([(1, H - 12), (98, H - 12)], fill=rgba((60, 70, 80)))
    d.rectangle([40, H - 12, 59, H - 1], fill=(0, 0, 0, 0))  # la puerta de la reja, abierta
    B.outline_inside(img)
    save("colegio", img)


def dibujo(size):
    w, h = size
    img = Image.new("RGBA", size, (248, 244, 232, 255))
    d = ImageDraw.Draw(img)
    s = w / 120.0

    def P(x, y):
        return (int(x * s), int(y * s))
    d.ellipse([*P(90, 6), *P(110, 26)], fill=(250, 200, 40))                       # el sol
    d.line([P(0, 70), P(120, 70)], fill=(90, 170, 80), width=max(1, int(3 * s)))  # el pasto
    # Un señor de palitos, grande, con barba.
    d.ellipse([*P(30, 22), *P(46, 38)], outline=(40, 30, 50), width=max(1, int(2 * s)))
    d.line([P(38, 38), P(38, 58)], fill=(40, 30, 50), width=max(1, int(2 * s)))
    d.line([P(28, 46), P(48, 46)], fill=(40, 30, 50), width=max(1, int(2 * s)))
    d.line([P(38, 58), P(31, 70)], fill=(40, 30, 50), width=max(1, int(2 * s)))
    d.line([P(38, 58), P(45, 70)], fill=(40, 30, 50), width=max(1, int(2 * s)))
    d.arc([*P(32, 30), *P(44, 40)], 20, 160, fill=(120, 70, 40), width=max(1, int(2 * s)))
    # Un perro café con orejas largas.
    d.ellipse([*P(56, 54), *P(78, 66)], fill=(176, 110, 60))
    d.ellipse([*P(72, 46), *P(84, 58)], fill=(176, 110, 60))
    d.line([P(74, 50), P(70, 60)], fill=(120, 70, 40), width=max(1, int(2 * s)))
    d.line([P(58, 58), P(52, 52)], fill=(176, 110, 60), width=max(1, int(2 * s)))
    if w > 40:  # el texto, con letra de niña
        d.text(P(34, 76), "EL DEL PERRO", fill=(200, 60, 80))
    return img


if __name__ == "__main__":
    colegio()
    icon = dibujo((16, 16))
    B.outline(icon).save("assets/items/dibujo_victoria.png")
    dibujo((120, 88)).save("assets/items/dibujo_grande.png")
    print("listo")
