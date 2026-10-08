"""El collar de Lukas (ícono 16x16): se parte del collar de Michi (assets/items/collar_michi.png) y se
lo vuelve de cuero café gastado con una plaquita de metal en vez de la campanita.
Salida: assets/items/collar_lukas.png
Uso: python tools/art/draw_collar_lukas.py  (desde la carpeta del proyecto)"""
from PIL import Image

im = Image.open("assets/items/collar_michi.png").convert("RGBA")
px = im.load()
MAP = {(200, 40, 50, 255): (132, 86, 52, 255),   # cuero café
       (240, 200, 70, 255): (196, 200, 206, 255)}  # la plaquita
for y in range(im.height):
    for x in range(im.width):
        if px[x, y] in MAP:
            px[x, y] = MAP[px[x, y]]
# Una L grabada en la plaquita y el brillo del cuero gastado.
px[7, 11] = (120, 124, 132, 255)
px[7, 12] = (120, 124, 132, 255)
px[8, 12] = (120, 124, 132, 255)
for x, y in [(5, 4), (6, 3), (10, 4)]:
    px[x, y] = (168, 116, 74, 255)
im.save("assets/items/collar_lukas.png")
print("collar_lukas")
