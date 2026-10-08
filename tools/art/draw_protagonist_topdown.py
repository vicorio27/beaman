"""Protagonista visto desde arriba (la ciudad), recoloreado para que sea el mismo tipo del sueño:
pelo negro, camisa blanca gastada, jean azul. Base: personaje de Kenney RPG Urban (ya en paleta).
Salida: assets/characters/protagonist_topdown.png (4 columnas: costado, frente, espalda, costado;
3 filas: quieto, paso 1, paso 2).
Uso: python tools/art/draw_protagonist_topdown.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image

SRC = Path("assets/tilesets/kenney_urban.png")
OUT = Path("assets/characters/protagonist_topdown.png")
OUT.parent.mkdir(parents=True, exist_ok=True)
T = 16

# Colores del personaje original -> nuevos. El naranja se usa para pelo (arriba del cuadro)
# y para zapatillas (abajo): se decide por la altura dentro del cuadro.
SKIN = {(251, 185, 84): (240, 168, 150)}
SHIRT = {(110, 148, 80): (214, 210, 196), (79, 122, 68): (162, 158, 150)}
PANTS = {(210, 202, 189): (66, 96, 156), (200, 180, 142): (44, 64, 110)}
EYES = {(117, 60, 84): (30, 40, 60)}
OUTLINE = {(111, 103, 95): (40, 32, 44)}
HAIR = (44, 42, 50)
HAIR_HI = (74, 76, 88)
SHOES = (40, 36, 44)

im = Image.open(SRC).convert("RGBA").crop((23 * T, 0, 27 * T, 3 * T))
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, a = px[x, y]
        if a == 0:
            continue
        c = (r, g, b)
        cy = y % T
        if c in ((230, 144, 78), (205, 104, 61)):
            # De espaldas (3ra columna) el pelo baja más: tapa la nuca.
            if cy < (10 if x // T == 2 else 8):
                new = HAIR if c == (205, 104, 61) else HAIR_HI if (x + y) % 5 == 0 else HAIR
            else:
                new = SHOES if cy >= 13 else SKIN[(251, 185, 84)]
        else:
            new = {**SKIN, **SHIRT, **PANTS, **EYES, **OUTLINE}.get(c, c)
        px[x, y] = new + (a,)
im.save(OUT)
print("protagonista (ciudad):", OUT)
