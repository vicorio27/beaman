"""La fotografía antigua, en grande (para la escena de la noche): frente y dorso.
Frente: él de chico con una pelota, al lado de alguien cuya cara está cortada (rota).
Salida: assets/items/foto_frente.png, assets/items/foto_dorso.png (120x88)
Uso: python tools/art/draw_photo.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw

random.seed(3)
W, H = 120, 88
PAPER = (226, 216, 190, 255)
SEPIA = [(196, 170, 128, 255), (170, 142, 104, 255), (140, 112, 82, 255), (100, 78, 58, 255), (70, 54, 42, 255)]

front = Image.new("RGBA", (W, H), PAPER)
d = ImageDraw.Draw(front)
d.rectangle([6, 6, W - 7, H - 7], fill=SEPIA[0])
# Cielo, pasto, un árbol al fondo.
d.rectangle([6, 6, W - 7, 46], fill=SEPIA[0])
d.rectangle([6, 46, W - 7, H - 7], fill=SEPIA[1])
d.ellipse([84, 14, 108, 38], fill=SEPIA[2])
d.rectangle([94, 36, 97, 50], fill=SEPIA[3])
for _ in range(60):
    d.point((random.randint(6, W - 7), random.randint(48, H - 8)), fill=SEPIA[2])
# El nene con la pelota.
d.ellipse([34, 40, 42, 48], fill=SEPIA[3])  # cabeza
d.rectangle([35, 48, 41, 60], fill=SEPIA[2])  # remera
d.rectangle([35, 60, 37, 70], fill=SEPIA[4])
d.rectangle([39, 60, 41, 70], fill=SEPIA[4])
d.ellipse([42, 62, 50, 70], fill=(220, 206, 176, 255), outline=SEPIA[4])  # pelota
# La otra persona (adulto), a la derecha del nene, con la mano en su hombro.
d.rectangle([54, 34, 66, 62], fill=SEPIA[3])  # cuerpo
d.rectangle([55, 62, 58, 78], fill=SEPIA[4])
d.rectangle([62, 62, 65, 78], fill=SEPIA[4])
d.line([(54, 38), (42, 49)], fill=SEPIA[3], width=2)  # brazo sobre el hombro del nene
d.ellipse([55, 22, 65, 34], fill=SEPIA[2])  # cabeza
# La cara está cortada: la esquina de la foto rota justo ahí.
d.polygon([(52, 0), (W, 0), (W, 10), (78, 14), (70, 30), (58, 34), (50, 20)], fill=(0, 0, 0, 0))
# Bordes gastados y manchas.
for _ in range(40):
    x, y = random.choice([(random.randint(0, W - 1), random.randint(0, 5)), (random.randint(0, W - 1), random.randint(H - 6, H - 1)),
                          (random.randint(0, 5), random.randint(0, H - 1)), (random.randint(W - 6, W - 1), random.randint(0, H - 1))])
    if front.getpixel((x, y))[3] > 0:
        d.point((x, y), fill=(200, 188, 160, 255))
d.ellipse([14, 66, 24, 74], fill=(206, 184, 140, 160))
front.save("assets/items/foto_frente.png")

back = Image.new("RGBA", (W, H), PAPER)
d = ImageDraw.Draw(back)
for _ in range(120):
    d.point((random.randint(0, W - 1), random.randint(0, H - 1)), fill=(214, 202, 176, 255))
d.polygon([(52, 0), (W, 0), (W, 10), (78, 14), (70, 30), (58, 34), (50, 20)], fill=(0, 0, 0, 0))
back = back.transpose(Image.FLIP_LEFT_RIGHT)  # el corte queda del otro lado
back.save("assets/items/foto_dorso.png")
print("foto lista")
