"""Dibuja los tiles de interior que faltan en el pack de Kenney (paredes, pisos, pan, etc.).
Salida: assets/tilesets/source/interior_custom.png (después correr apply_palette.py) (una fila de tiles de 16x16).
Uso: python tools/art/draw_interior_tiles.py  (desde la carpeta del proyecto)
Colores tomados del sample de Kenney Roguelike Indoors para que combinen."""
from PIL import Image, ImageDraw

T = 16
CAP = (180, 167, 140)
CAP_HI = (196, 183, 154)
FACE = (217, 202, 169)
FACE_SH = (200, 186, 155)
BASE = (150, 108, 70)
BASE_DK = (118, 84, 54)
WOOD = (180, 131, 85)
WOOD_DK = (160, 113, 72)
WOOD_HI = (192, 143, 96)
CRUST = (196, 128, 62)
CRUST_HI = (232, 178, 104)
CRUST_DK = (122, 72, 36)
CLEAR = (0, 0, 0, 0)

tiles = []


def tile(bg=CLEAR):
    im = Image.new("RGBA", (T, T), bg)
    tiles.append(im)
    return im, ImageDraw.Draw(im)


def loaf(d, x, y, w=6, h=4):
    d.ellipse([x, y, x + w - 1, y + h - 1], fill=CRUST, outline=CRUST_DK)
    d.line([x + 2, y + 1, x + w - 3, y + 1], fill=CRUST_HI)


# 0 tapa de pared (vista desde arriba)
im, d = tile(CAP)
d.line([0, 0, 15, 0], fill=CAP_HI)
d.point([(4, 5), (11, 9), (7, 13), (13, 3)], fill=CAP_HI)

# 1 pared, parte alta
im, d = tile(FACE)
d.rectangle([0, 0, 15, 1], fill=FACE_SH)

# 2 pared, parte baja con zócalo
im, d = tile(FACE)
d.rectangle([0, 11, 15, 14], fill=BASE)
d.line([0, 15, 15, 15], fill=BASE_DK)
d.line([0, 11, 15, 11], fill=WOOD_HI)

# 3 piso de madera
im, d = tile(WOOD)
for x in (3, 7, 11, 15):
    d.line([x, 0, x, 15], fill=WOOD_DK)
for x, y in ((0, 5), (4, 12), (8, 2), (12, 9)):
    d.line([x, y, x + 2, y], fill=WOOD_DK)
for x, y in ((1, 9), (5, 3), (9, 13), (13, 6)):
    d.point((x, y), fill=WOOD_HI)

# 4 piso de baldosas (café)
im, d = tile((222, 208, 182))
d.rectangle([8, 0, 15, 7], fill=(158, 128, 106))
d.rectangle([0, 8, 7, 15], fill=(158, 128, 106))

# 5 felpudo de la puerta
im, d = tile(WOOD)
d.rectangle([1, 3, 14, 12], fill=(112, 62, 46), outline=(78, 42, 32))
for y in (5, 7, 9):
    d.line([3, y, 12, y], fill=(130, 76, 56))

# 6 estante de pan en la pared (parte baja)
im, d = tile(FACE)
d.rectangle([0, 11, 15, 14], fill=BASE)
d.line([0, 15, 15, 15], fill=BASE_DK)
d.rectangle([1, 2, 14, 10], fill=(150, 108, 70))
d.rectangle([2, 3, 13, 9], fill=(110, 76, 48))
loaf(d, 2, 4)
loaf(d, 8, 4)
d.line([2, 9, 13, 9], fill=WOOD_HI)

# 7 bandeja con panes (se pone encima del mostrador)
im, d = tile()
d.rectangle([1, 2, 14, 7], fill=(140, 140, 146), outline=(100, 100, 106))
loaf(d, 2, 2, 5, 4)
loaf(d, 7, 1, 6, 4)
d.ellipse([10, 4, 14, 7], fill=(214, 160, 90), outline=CRUST_DK)

# 8 ventana en la pared (parte alta)
im, d = tile(FACE)
d.rectangle([0, 0, 15, 1], fill=FACE_SH)
d.rectangle([2, 3, 13, 15], fill=BASE)
d.rectangle([3, 4, 12, 15], fill=(160, 205, 228))
d.line([7, 4, 7, 15], fill=BASE)
d.line([3, 9, 12, 9], fill=BASE)
d.line([4, 5, 5, 5], fill=(230, 245, 250))

# 9 pizarrón con el menú (parte alta)
im, d = tile(FACE)
d.rectangle([0, 0, 15, 1], fill=FACE_SH)
d.rectangle([1, 3, 14, 15], fill=BASE)
d.rectangle([2, 4, 13, 15], fill=(42, 54, 48))
for y, w in ((6, 9), (9, 6), (12, 8)):
    d.line([4, y, 4 + w, y], fill=(200, 205, 190))

# 10 máquina de café (encima del mostrador)
im, d = tile()
d.rectangle([3, 0, 12, 7], fill=(178, 182, 188), outline=(96, 98, 104))
d.rectangle([5, 2, 10, 3], fill=(60, 62, 68))
d.point((11, 1), fill=(220, 50, 40))
d.rectangle([6, 5, 9, 7], fill=(240, 236, 228))

# 11 tazas (encima de mesa o mostrador)
im, d = tile()
for x in (3, 9):
    d.rectangle([x, 3, x + 3, 6], fill=(240, 236, 228), outline=(150, 140, 130))
    d.point((x + 4, 4), fill=(150, 140, 130))
    d.line([x + 1, 4, x + 2, 4], fill=(90, 56, 36))

# 12 bolsas de harina (piso, sólido)
im, d = tile()
for x, y in ((1, 5), (7, 3)):
    d.rounded_rectangle([x, y, x + 7, y + 10], 2, fill=(232, 224, 204), outline=(150, 140, 120))
    d.line([x + 2, y + 5, x + 5, y + 5], fill=(170, 60, 50))
    d.line([x + 2, y + 1, x + 5, y + 1], fill=(190, 180, 160))

# 13 cajas apiladas (piso, sólido)
im, d = tile()
d.rectangle([1, 6, 14, 15], fill=(190, 140, 90), outline=(120, 82, 48))
d.line([7, 6, 7, 15], fill=(214, 186, 130))
d.rectangle([3, 0, 12, 6], fill=(176, 128, 80), outline=(120, 82, 48))
d.line([7, 0, 7, 6], fill=(214, 186, 130))

# 14 canasto de pan (piso, sólido)
im, d = tile()
d.ellipse([1, 6, 14, 15], fill=(170, 120, 60), outline=(110, 72, 34))
d.line([3, 11, 12, 11], fill=(140, 96, 48))
loaf(d, 3, 4, 6, 4)
loaf(d, 7, 6, 6, 4)

sheet = Image.new("RGBA", (T * len(tiles), T), CLEAR)
for i, t in enumerate(tiles):
    sheet.paste(t, (i * T, 0))
sheet.save("assets/tilesets/source/interior_custom.png")
print("tiles:", len(tiles))
