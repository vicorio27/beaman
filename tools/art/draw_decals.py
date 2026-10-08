"""Detalles chicos (decals) que rompen la repetición de los tiles: grietas, manchas, basura,
yuyos, flores, grafitis, carteles... Fondo transparente, se ponen encima del piso/las paredes.
Salida: assets/tilesets/source/decals.png (después correr apply_palette.py).
Uso: python tools/art/draw_decals.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw

T = 16
random.seed(7)
tiles = []

DARK = (46, 34, 47)
CRACK = (62, 53, 70, 200)
OIL = (49, 54, 56, 150)
OIL_HI = (98, 85, 101, 150)
LEAF = [(205, 104, 61), (230, 144, 78), (158, 69, 57), (251, 185, 84)]
PAPER = (199, 220, 208)
PAPER_SH = (155, 171, 178)
BUTT = (253, 203, 176)
BUTT_TIP = (205, 104, 61)
GUM = (98, 85, 101, 170)
STONE = (127, 112, 138)
STONE_HI = (155, 171, 178)
GRASS = [(35, 144, 99), (30, 188, 115), (84, 126, 100)]
FLOWER = [(255, 255, 255), (249, 194, 43), (237, 128, 153)]
METAL = (98, 85, 101)
METAL_DK = (62, 53, 70)
METAL_HI = (127, 112, 138)


def tile():
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    tiles.append(im)
    return im, ImageDraw.Draw(im)


def crack(d, pts):
    d.line(pts, fill=CRACK, width=1)


# 0, 1 grietas
im, d = tile()
crack(d, [(2, 3), (5, 6), (6, 10), (9, 12), (13, 13)])
crack(d, [(6, 10), (4, 13)])
im, d = tile()
crack(d, [(12, 2), (10, 5), (11, 8), (8, 11)])
crack(d, [(10, 5), (13, 6)])

# 2 mancha de aceite
im, d = tile()
d.ellipse([3, 5, 12, 11], fill=OIL)
d.ellipse([6, 3, 10, 7], fill=OIL)
d.point([(5, 7), (8, 8)], fill=OIL_HI)

# 3 hojas secas
im, d = tile()
for _ in range(5):
    x, y = random.randint(1, 13), random.randint(1, 13)
    c = random.choice(LEAF)
    d.point([(x, y), (x + 1, y), (x, y + 1)], fill=c)

# 4 papel tirado
im, d = tile()
d.polygon([(4, 6), (10, 4), (12, 9), (6, 11)], fill=PAPER, outline=PAPER_SH)
d.line([(6, 7), (10, 6)], fill=PAPER_SH)

# 5 colillas
im, d = tile()
for x, y in ((3, 9), (9, 5), (11, 11)):
    d.line([(x, y), (x + 2, y)], fill=BUTT)
    d.point((x + 3, y), fill=BUTT_TIP)

# 6 yuyo en una grieta
im, d = tile()
crack(d, [(3, 13), (8, 12), (13, 13)])
for x in (6, 8, 9):
    d.line([(x, 12), (x + random.choice((-1, 0, 1)), 9)], fill=GRASS[1])
d.point((8, 8), fill=GRASS[0])

# 7 chicles
im, d = tile()
for x, y in ((3, 4), (10, 7), (6, 12), (12, 13)):
    d.point([(x, y), (x + 1, y)], fill=GUM)

# 8 piedritas
im, d = tile()
for x, y in ((4, 10), (9, 6), (11, 11)):
    d.rectangle([x, y, x + 1, y + 1], fill=STONE)
    d.point((x, y), fill=STONE_HI)

# 9 flores (parque)
im, d = tile()
for x, y in ((3, 4), (10, 3), (6, 10), (12, 12)):
    d.line([(x, y + 1), (x, y + 3)], fill=GRASS[0])
    c = random.choice(FLOWER)
    d.point([(x - 1, y), (x + 1, y), (x, y - 1)], fill=c)
    d.point((x, y), fill=FLOWER[1])

# 10 matas de pasto (parque)
im, d = tile()
for x, y in ((3, 6), (11, 10), (7, 13)):
    for dx in (-1, 0, 1):
        d.line([(x + dx, y), (x + dx * 2, y - 3)], fill=GRASS[0] if dx else GRASS[2])

# 11 tapa de alcantarilla
im, d = tile()
d.ellipse([2, 2, 13, 13], fill=METAL, outline=METAL_DK)
for y in (5, 7, 9):
    d.line([(5, y), (10, y)], fill=METAL_DK)
d.point((6, 4), fill=METAL_HI)

# 12 rejilla de desagüe (borde de vereda)
im, d = tile()
d.rectangle([3, 9, 12, 14], fill=DARK)
for x in range(4, 12, 2):
    d.line([(x, 10), (x, 13)], fill=METAL)

# 13, 14 grafitis (sobre la fachada, parte baja)
im, d = tile()
d.line([(2, 6), (4, 3), (6, 7), (8, 3), (10, 7)], fill=(77, 155, 230), width=1)
d.line([(11, 3), (13, 7)], fill=(77, 155, 230))
d.point([(3, 9), (9, 9)], fill=(77, 155, 230))
im, d = tile()
d.arc([2, 2, 9, 9], 30, 330, fill=(240, 79, 120))
d.line([(9, 3), (13, 3), (11, 3), (11, 9)], fill=(240, 79, 120))
d.line([(3, 11), (12, 11)], fill=(249, 194, 43))

# 15, 16 carteles pegados (fachada, parte alta)
im, d = tile()
d.rectangle([3, 2, 12, 13], fill=PAPER, outline=PAPER_SH)
d.rectangle([5, 4, 10, 8], fill=(98, 85, 101))
for y in (10, 12):
    d.line([(5, y), (10, y)], fill=PAPER_SH)
im, d = tile()
d.polygon([(4, 3), (12, 2), (13, 12), (5, 13)], fill=(251, 185, 84), outline=(205, 104, 61))
d.line([(6, 6), (11, 5)], fill=(158, 69, 57))
d.line([(6, 9), (11, 8)], fill=(158, 69, 57))

# 17 charco chico
im, d = tile()
d.ellipse([2, 6, 13, 12], fill=(77, 101, 180, 170))
d.line([(5, 8), (8, 8)], fill=(143, 211, 255, 200))

# 18 lata tirada
im, d = tile()
d.rectangle([5, 8, 10, 11], fill=(232, 59, 59), outline=(110, 39, 39))
d.line([(6, 9), (9, 9)], fill=(253, 203, 176))

# 19 polvo de harina (panadería)
im, d = tile()
for _ in range(14):
    d.point((random.randint(1, 14), random.randint(1, 14)), fill=(240, 236, 228, 190))

# 20 migas
im, d = tile()
for _ in range(7):
    d.point((random.randint(2, 13), random.randint(2, 13)), fill=(205, 140, 70))

sheet = Image.new("RGBA", (T * len(tiles), T), (0, 0, 0, 0))
for i, t in enumerate(tiles):
    sheet.paste(t, (i * T, 0))
sheet.save("assets/tilesets/source/decals.png")
print("decals:", len(tiles))
