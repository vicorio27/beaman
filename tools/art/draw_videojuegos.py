"""La tienda de videojuegos del barrio (python tools/art/draw_videojuegos.py).

Una fachada como las demás (techo de chapa visto desde arriba, fachada abajo): 100x60, con el pie de la
fachada en el borde de abajo. Vitrina con dos pantallas prendidas, un control colgado y la puerta.
Salida: assets/barrio/videojuegos.png. La pone en el mapa scripts/systems/Vecindario.gd.
"""
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

random.seed(11)
OUT = Path("assets/barrio")
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)
INK = (38, 28, 44, 255)
TIN, TIN_DK, RUST = (128, 132, 138), (92, 96, 104), (150, 84, 52)
WALL = (58, 52, 92)

W, ROOF, FACE = 100, 20, 40
H = ROOF + FACE
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# El techo: chapa acanalada, con óxido.
d.rectangle([0, 0, W - 1, ROOF - 1], fill=TIN)
for x in range(1, W, 3):
    d.line([(x, 0), (x, ROOF - 1)], fill=TIN_DK)
for _ in range(26):
    x, y = random.randint(0, W - 1), random.randint(0, ROOF - 1)
    d.line([(x, y), (x, min(ROOF - 1, y + random.randint(1, 4)))], fill=RUST)
d.line([(0, ROOF - 1), (W - 1, ROOF - 1)], fill=INK)

# La fachada: morado de noche, para que se note que adentro hay pantallas.
d.rectangle([0, ROOF, W - 1, H - 1], fill=WALL)
d.rectangle([0, ROOF, W - 1, ROOF + 1], fill=(36, 32, 60))
for _ in range(120):
    x, y = random.randint(1, W - 2), random.randint(ROOF + 2, H - 4)
    d.point((x, y), fill=random.choice([(50, 44, 80), (68, 62, 106)]))
d.rectangle([0, H - 3, W - 1, H - 1], fill=(34, 30, 54))

# El letrero.
text = "VIDEOJUEGOS"
tw = int(d.textlength(text, font=FONT))
sx = (W - tw) // 2
d.rectangle([sx - 3, ROOF + 10, sx + tw + 2, ROOF + 21], fill=(24, 18, 34), outline=INK)  # (bajito: arriba pasa el cable de la luz)
d.text((sx, ROOF + 12), text, font=FONT, fill=(110, 220, 255))
d.line([(sx, ROOF + 20), (sx + tw - 2, ROOF + 20)], fill=(255, 96, 150))

# La vitrina: dos pantallas prendidas y un control colgado.
d.rectangle([6, ROOF + 23, 62, H - 4], fill=(20, 22, 34), outline=INK)
for k, (x, col) in enumerate([(10, (90, 200, 120)), (32, (230, 120, 80))]):
    d.rectangle([x, ROOF + 25, x + 17, ROOF + 34], fill=(60, 60, 70), outline=INK)
    d.rectangle([x + 2, ROOF + 27, x + 15, ROOF + 32], fill=col)
    d.rectangle([x + 4, ROOF + 29, x + 6, ROOF + 31], fill=(250, 250, 250))  # un muñequito
    d.line([(x + 9, ROOF + 31), (x + 14, ROOF + 31)], fill=(30, 40, 60))
d.rectangle([52, ROOF + 27, 59, ROOF + 31], fill=(210, 210, 215), outline=INK)  # el control
d.point((54, ROOF + 29), fill=(220, 60, 60))
d.point((57, ROOF + 29), fill=(60, 90, 220))
d.line([(55, ROOF + 23), (55, ROOF + 27)], fill=(120, 120, 130))

# La puerta, abierta de par en par (nadie entra igual).
d.rectangle([72, H - 16, 88, H - 1], fill=(16, 14, 24), outline=INK)
d.rectangle([74, H - 14, 79, H - 9], fill=(110, 220, 255))  # un brillo de pantalla, al fondo
d.rectangle([70, H - 12, 71, H - 6], fill=(255, 214, 90))  # el aviso de "ABIERTO" (no se lee: mejor)

d.rectangle([0, 0, W - 1, H - 1], outline=INK)
img.save(OUT / "videojuegos.png")
print("videojuegos.png", img.size)
