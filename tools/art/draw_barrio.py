"""Arte de la ciudad del Día 1, estilo EarthBound: humilde, gastado, que da mal rollo.
- Suelo en tiles de 16x16 (pasto seco, tierra, asfalto roto, vereda, agua turbia...).
- Edificios y objetos como sprites en perspectiva oblicua (fachada + techo), con contorno oscuro.
Salida: assets/barrio/*.png (paleta propia del barrio: no pasa por apply_palette.py).
Uso: python tools/art/draw_barrio.py  (desde la carpeta del proyecto)"""
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

random.seed(11)
OUT = Path("assets/barrio")
OUT.mkdir(parents=True, exist_ok=True)
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)
T = 16

INK = (38, 28, 44, 255)  # contorno (violeta muy oscuro, como EarthBound)
CLEAR = (0, 0, 0, 0)


def rgba(c, a=255):
    return (c[0], c[1], c[2], a)


def jitter(c, amount=8):
    return tuple(max(0, min(255, v + random.randint(-amount, amount))) for v in c[:3]) + (255,)


def outline(img, color=INK):
    """Contorno de 1 px por fuera de todo lo pintado."""
    w, h = img.size
    src = img.copy()
    px, out = src.load(), img.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != color:
                        out[x, y] = color
                        break
    return img


def speckle(d, box, colors, n):
    x0, y0, x1, y1 = box
    for _ in range(n):
        d.point((random.randint(x0, x1), random.randint(y0, y1)), fill=random.choice(colors))


# ======================================================================= SUELO
GRASS = (104, 116, 66)
GRASS_DK = (78, 90, 52)
GRASS_DRY = (150, 140, 82)
DIRT = (124, 98, 72)
DIRT_DK = (96, 74, 58)
ASPHALT = (68, 66, 78)
ASPHALT_DK = (50, 48, 60)
ASPHALT_HI = (88, 86, 98)
WALK = (150, 144, 136)
WALK_DK = (122, 116, 110)
CONCRETE = (92, 90, 96)
WATER = (68, 92, 84)
WATER_HI = (96, 122, 108)
MUD = (96, 82, 64)

tiles = []


def tile(base):
    im = Image.new("RGBA", (T, T), rgba(base))
    tiles.append(im)
    return im, ImageDraw.Draw(im)


# 0-3 pasto (variantes)
for v in range(4):
    im, d = tile(GRASS)
    speckle(d, (0, 0, 15, 15), [rgba(GRASS_DK), rgba(GRASS_DK), rgba(GRASS_DRY)], 22 + v * 3)
    for _ in range(3):
        x, y = random.randint(1, 14), random.randint(2, 14)
        d.line([(x, y), (x, y - 2)], fill=rgba(GRASS_DK))
# 4-5 pasto seco con calvas
for v in range(2):
    im, d = tile(GRASS_DRY)
    # Calvas irregulares de tierra (no círculos: si no, se ve un estampado de lunares).
    for _ in range(3 + v * 2):
        x, y = random.randint(0, 14), random.randint(0, 14)
        d.rectangle([x, y, x + random.randint(0, 2), y + random.randint(0, 1)], fill=rgba(DIRT))
    speckle(d, (0, 0, 15, 15), [rgba(GRASS), rgba(DIRT_DK), rgba((166, 154, 92))], 22)
    for _ in range(2):
        x, y = random.randint(1, 14), random.randint(3, 14)
        d.line([(x, y), (x + 1, y - 2)], fill=rgba((128, 120, 70)))
# 6-7 tierra
for v in range(2):
    im, d = tile(DIRT)
    speckle(d, (0, 0, 15, 15), [rgba(DIRT_DK), rgba((140, 116, 88))], 26)
    if v:
        d.point([(4, 9), (5, 9), (11, 3)], fill=rgba((150, 146, 140)))  # piedritas
# 8-10 asfalto (liso, con grieta, con bache)
im, d = tile(ASPHALT)
speckle(d, (0, 0, 15, 15), [rgba(ASPHALT_DK), rgba(ASPHALT_HI)], 20)
im, d = tile(ASPHALT)
speckle(d, (0, 0, 15, 15), [rgba(ASPHALT_DK), rgba(ASPHALT_HI)], 16)
d.line([(1, 4), (6, 7), (9, 6), (14, 11)], fill=rgba(ASPHALT_DK))
d.line([(6, 7), (5, 12)], fill=rgba(ASPHALT_DK))
im, d = tile(ASPHALT)
speckle(d, (0, 0, 15, 15), [rgba(ASPHALT_DK), rgba(ASPHALT_HI)], 16)
d.ellipse([4, 5, 12, 11], fill=rgba(ASPHALT_DK))
d.ellipse([6, 7, 10, 10], fill=rgba((58, 70, 76)))  # agua en el bache
# 11 asfalto con línea amarilla gastada (horizontal) / 12 (vertical)
im, d = tile(ASPHALT)
speckle(d, (0, 0, 15, 15), [rgba(ASPHALT_DK), rgba(ASPHALT_HI)], 18)
d.rectangle([2, 7, 9, 8], fill=rgba((176, 150, 70)))
d.point([(5, 7), (8, 8)], fill=rgba(ASPHALT))
im, d = tile(ASPHALT)
speckle(d, (0, 0, 15, 15), [rgba(ASPHALT_DK), rgba(ASPHALT_HI)], 18)
d.rectangle([7, 2, 8, 9], fill=rgba((176, 150, 70)))
d.point([(7, 5), (8, 8)], fill=rgba(ASPHALT))
# 13-15 vereda (losas), con grieta, con mancha
for v in range(3):
    im, d = tile(WALK)
    d.line([(0, 0), (15, 0)], fill=rgba(WALK_DK))
    d.line([(0, 0), (0, 15)], fill=rgba(WALK_DK))
    d.line([(8, 0), (8, 15)], fill=rgba(WALK_DK))
    speckle(d, (1, 1, 15, 15), [rgba(WALK_DK), rgba((166, 160, 150))], 10)
    if v == 1:
        d.line([(2, 3), (5, 8), (4, 13)], fill=rgba(WALK_DK))
    if v == 2:
        d.ellipse([9, 6, 15, 12], fill=rgba((112, 104, 100)))
# 16 cordón (vereda con borde abajo, contra la calle)
im, d = tile(WALK)
d.line([(0, 0), (15, 0)], fill=rgba(WALK_DK))
d.rectangle([0, 12, 15, 15], fill=rgba((176, 170, 160)))
d.line([(0, 15), (15, 15)], fill=INK)
# 17 hormigón manchado (bajo el puente)
im, d = tile(CONCRETE)
speckle(d, (0, 0, 15, 15), [rgba((76, 74, 80)), rgba((104, 100, 104))], 24)
d.ellipse([2, 8, 9, 13], fill=rgba((70, 66, 72)))
# 18-19 agua turbia (dos cuadros, para animar)
for v in range(2):
    im, d = tile(WATER)
    for y in (3, 9, 14):
        x = (y * 3 + v * 5) % 12
        d.line([(x, y), (x + 4, y)], fill=rgba(WATER_HI))
    d.point((random.randint(0, 15), random.randint(0, 15)), fill=rgba((120, 130, 100)))
# 20 barro de la orilla
im, d = tile(MUD)
speckle(d, (0, 0, 15, 15), [rgba((80, 68, 54)), rgba((112, 96, 76))], 26)
d.line([(0, 15), (15, 15)], fill=rgba((60, 76, 70)))
# 21 tablero del puente (hormigón con juntas)
im, d = tile((112, 108, 112))
d.line([(0, 7), (15, 7)], fill=rgba((90, 86, 92)))
speckle(d, (0, 0, 15, 15), [rgba((96, 92, 98)), rgba((128, 124, 126))], 14)
# 22 baranda del puente (vista desde arriba)
im, d = tile((112, 108, 112))
d.rectangle([0, 0, 15, 4], fill=rgba((84, 80, 90)))
d.line([(0, 5), (15, 5)], fill=INK)
for x in (2, 8, 14):
    d.rectangle([x - 1, 0, x, 4], fill=rgba((60, 56, 66)))
# 23 baldosas de la placita (rotas)
im, d = tile((162, 132, 112))
for y in (0, 8):
    d.line([(0, y), (15, y)], fill=rgba((130, 104, 90)))
for x in (0, 8):
    d.line([(x, 0), (x, 15)], fill=rgba((130, 104, 90)))
d.polygon([(9, 9), (14, 10), (12, 14)], fill=rgba((124, 98, 72)))

sheet = Image.new("RGBA", (T * len(tiles), T), CLEAR)
for i, t in enumerate(tiles):
    sheet.paste(t, (i * T, 0))
sheet.save(OUT / "ground.png")
print("suelo:", len(tiles), "tiles")


# ======================================================================= EDIFICIOS
WALLS = {
    "rosa": (186, 146, 140), "menta": (144, 166, 140), "mostaza": (184, 162, 104),
    "lila": (150, 138, 164), "ladrillo": (150, 92, 72), "gris": (140, 136, 132),
}
TIN = (136, 134, 144)
TIN_DK = (104, 102, 112)
RUST = (150, 84, 52)
TILE_ROOF = (148, 72, 60)
WOOD = (120, 86, 60)
GLASS = (66, 82, 96)
GLASS_LIT = (236, 210, 120)


def building(w, face_h, roof_h, wall, roof="tin", windows=(), door=None, boarded=(), lit=(),
             rust=0.3, sign=None, awning=None, extras=(), awning_y=2):
    """Edificio en perspectiva oblicua: techo arriba (visto desde arriba), fachada abajo.
    Devuelve una imagen con el origen (pie de la fachada) en el borde inferior."""
    H = roof_h + face_h
    img = Image.new("RGBA", (w, H), CLEAR)
    d = ImageDraw.Draw(img)
    # Techo: chapa acanalada oxidada o tejas.
    if roof == "tin":
        d.rectangle([0, 0, w - 1, roof_h - 1], fill=rgba(TIN))
        for x in range(1, w, 3):
            d.line([(x, 0), (x, roof_h - 1)], fill=rgba(TIN_DK))
        for _ in range(int(w * roof_h * rust * 0.05)):
            x, y = random.randint(0, w - 1), random.randint(0, roof_h - 1)
            d.line([(x, y), (x, min(roof_h - 1, y + random.randint(1, 4)))], fill=rgba(jitter(RUST, 14)))
        for _ in range(2):  # parches
            x, y = random.randint(0, w - 8), random.randint(0, max(0, roof_h - 6))
            d.rectangle([x, y, x + 6, y + 4], fill=rgba((120, 118, 104)), outline=rgba(TIN_DK))
    else:
        d.rectangle([0, 0, w - 1, roof_h - 1], fill=rgba(TILE_ROOF))
        for y in range(2, roof_h, 3):
            d.line([(0, y), (w - 1, y)], fill=rgba((120, 56, 48)))
        speckle(d, (0, 0, w - 1, roof_h - 1), [rgba((170, 90, 74)), rgba((110, 50, 44))], w)
    d.line([(0, roof_h - 1), (w - 1, roof_h - 1)], fill=INK)  # alero
    # Fachada.
    fy = roof_h
    d.rectangle([0, fy, w - 1, H - 1], fill=rgba(wall))
    d.rectangle([0, fy, w - 1, fy + 1], fill=rgba(tuple(max(0, c - 30) for c in wall)))  # sombra del alero
    speckle(d, (0, fy + 2, w - 1, H - 3), [rgba(tuple(max(0, c - 18) for c in wall)), rgba(tuple(min(255, c + 12) for c in wall))], w * face_h // 10)
    for _ in range(int(w * 0.15)):  # manchas de humedad que bajan
        x = random.randint(1, w - 2)
        d.line([(x, fy + 2), (x, fy + 2 + random.randint(2, face_h // 2))], fill=rgba(tuple(max(0, c - 26) for c in wall)))
    d.rectangle([0, H - 3, w - 1, H - 1], fill=rgba(tuple(max(0, c - 40) for c in wall)))  # zócalo sucio
    # Ventanas.
    for i, (wx, wy, ww, wh) in enumerate(windows):
        y = fy + wy
        d.rectangle([wx, y, wx + ww - 1, y + wh - 1], fill=rgba(GLASS_LIT if i in lit else GLASS), outline=INK)
        if i in boarded:
            for k in range(0, wh, 3):
                d.line([(wx - 1, y + k), (wx + ww, y + k + 1)], fill=rgba(WOOD), width=2)
        elif i not in lit:
            d.line([(wx + 1, y + 1), (wx + 2, y + 1)], fill=rgba((110, 128, 140)))
            if random.random() < 0.4:  # vidrio roto
                d.line([(wx + ww // 2, y), (wx + ww // 2 - 2, y + wh // 2)], fill=rgba((150, 160, 170)))
    # Puerta.
    if door:
        dx, dw = door
        d.rectangle([dx, H - 18, dx + dw - 1, H - 1], fill=rgba(WOOD), outline=INK)
        d.point((dx + dw - 3, H - 9), fill=rgba((200, 180, 90)))
    if awning:
        ax, aw, c1, c2 = awning
        for i in range(aw):
            d.line([(ax + i, fy + awning_y), (ax + i, fy + awning_y + 5)], fill=rgba(c1 if (i // 3) % 2 == 0 else c2))
        for i in range(0, aw, 6):  # borde ondulado del toldo
            d.point((ax + i + 1, fy + awning_y + 6), fill=rgba(c1))
        d.line([(ax, fy + awning_y + 6), (ax + aw - 1, fy + awning_y + 6)], fill=INK)
    if sign:
        text, sx, sy, bg, fg = sign
        tw = int(d.textlength(text, font=FONT))
        d.rectangle([sx - 2, fy + sy - 2, sx + tw + 1, fy + sy + 9], fill=rgba(bg), outline=INK)
        d.text((sx, fy + sy), text, font=FONT, fill=rgba(fg))
    for e in extras:
        e(d, w, H, fy)
    outline_inside(img)
    return img


def outline_inside(img):
    """Contorno en el borde de la imagen (los edificios llenan su caja)."""
    d = ImageDraw.Draw(img)
    w, h = img.size
    d.rectangle([0, 0, w - 1, h - 1], outline=INK)


def ac_unit(x, y):
    def f(d, w, H, fy):
        d.rectangle([x, fy + y, x + 7, fy + y + 5], fill=rgba((170, 170, 176)), outline=INK)
        d.line([(x + 1, fy + y + 2), (x + 6, fy + y + 2)], fill=rgba((120, 120, 126)))
    return f


def graffiti(x, y, color):
    def f(d, w, H, fy):
        d.line([(x, fy + y + 4), (x + 3, fy + y), (x + 6, fy + y + 4), (x + 9, fy + y)], fill=rgba(color), width=1)
        d.arc([x + 10, fy + y, x + 16, fy + y + 5], 0, 300, fill=rgba(color))
    return f


def dish(x):
    def f(d, w, H, fy):
        d.ellipse([x, fy - 8, x + 7, fy - 2], fill=rgba((190, 190, 196)), outline=INK)
        d.line([(x + 4, fy - 5), (x + 6, fy - 1)], fill=INK)
    return f


def save(name, img):
    img.save(OUT / f"{name}.png")


# Casillas del barrio (varias combinaciones).
save("house_a", building(48, 30, 20, WALLS["rosa"], windows=[(6, 8, 8, 7), (32, 8, 8, 7)], door=(18, 10),
                         boarded=(1,), extras=[graffiti(28, 20, (90, 150, 200))]))
save("house_b", building(40, 28, 18, WALLS["menta"], windows=[(5, 7, 9, 7)], door=(22, 10), lit=(0,),
                         extras=[ac_unit(28, 4), dish(6)]))
save("house_c", building(56, 30, 22, WALLS["mostaza"], roof="tile", windows=[(6, 8, 8, 7), (40, 8, 8, 7)],
                         door=(24, 10), boarded=(0, 1)))
save("house_d", building(36, 26, 16, WALLS["lila"], windows=[(22, 6, 8, 6)], door=(6, 10),
                         extras=[graffiti(4, 4, (220, 90, 120))]))
save("house_e", building(44, 30, 20, WALLS["ladrillo"], windows=[(6, 8, 9, 7), (28, 8, 9, 7)], door=(17, 10),
                         lit=(1,), extras=[ac_unit(30, 0)]))
save("house_f", building(52, 32, 22, WALLS["gris"], windows=[(5, 8, 8, 8), (20, 8, 8, 8), (38, 8, 8, 8)],
                         door=(30, 8), boarded=(0, 2), rust=0.6))

# Panadería (el único lugar cálido): toldo a rayas, vidriera iluminada, cartel.
save("bakery", building(84, 40, 22, (204, 178, 138), roof="tile",
                        windows=[(6, 20, 26, 12), (54, 20, 24, 12)], door=(37, 12), lit=(0, 1),
                        awning=(2, 80, (196, 70, 60), (236, 222, 200)), awning_y=12,
                        sign=("PANADERIA", 6, 1, (90, 54, 40), (250, 226, 160)), rust=0))
# Café: chico, letrero viejo, una ventana iluminada.
save("cafe", building(52, 36, 20, WALLS["menta"], windows=[(4, 18, 16, 10), (36, 18, 12, 10)], door=(23, 11),
                      lit=(0,), awning=(2, 48, (70, 100, 90), (200, 200, 180)), awning_y=11,
                      sign=("CAFE", 14, 1, (40, 50, 60), (220, 220, 200))))
# Galpones de la zona industrial.
save("warehouse_a", building(96, 40, 30, (128, 126, 132), windows=[(8, 6, 12, 6), (76, 6, 12, 6)],
                             door=(36, 26), boarded=(1,), rust=0.9,
                             extras=[graffiti(10, 22, (90, 200, 120)), graffiti(64, 26, (220, 120, 60))]))
save("warehouse_b", building(80, 36, 26, (146, 110, 92), windows=[(6, 6, 10, 6)], door=(30, 20), rust=1.0))
# Kiosco abandonado.
save("kiosk", building(28, 22, 12, WALLS["rosa"], windows=[(4, 5, 20, 7)], boarded=(0,), rust=0.8))


# ======================================================================= OBJETOS
def sprite(w, h):
    img = Image.new("RGBA", (w, h), CLEAR)
    return img, ImageDraw.Draw(img)


def finish(name, img):
    save(name, outline(img))


# Árbol muerto.
img, d = sprite(28, 40)
d.line([(14, 39), (14, 14)], fill=rgba((86, 70, 60)), width=3)
for (a, b) in (((14, 22), (5, 10)), ((14, 18), (24, 6)), ((14, 14), (11, 2)), ((8, 14), (3, 15)), ((20, 11), (26, 12))):
    d.line([a, b], fill=rgba((86, 70, 60)), width=2)
finish("tree_dead", img)
# Árbol ralo (pocas hojas, amarillentas).
img, d = sprite(32, 44)
d.line([(16, 43), (16, 20)], fill=rgba((90, 72, 58)), width=4)
for _ in range(16):
    x, y = random.randint(5, 26), random.randint(3, 24)
    d.ellipse([x - 4, y - 3, x + 4, y + 3], fill=rgba(random.choice([(126, 128, 70), (104, 112, 60), (150, 140, 76)])))
finish("tree_sparse", img)
# Poste de luz (de madera) con transformador.
img, d = sprite(14, 56)
d.rectangle([6, 4, 8, 55], fill=rgba((96, 76, 60)))
d.rectangle([0, 6, 13, 7], fill=rgba((96, 76, 60)))
d.rectangle([9, 12, 13, 18], fill=rgba((120, 120, 126)))
finish("pole", img)
# Farol (uno de los dos cuadros con la luz prendida).
for name, on in (("lamp_on", True), ("lamp_off", False)):
    img, d = sprite(16, 48)
    d.rectangle([3, 6, 4, 47], fill=rgba((70, 70, 80)))
    d.line([(4, 6), (11, 6)], fill=rgba((70, 70, 80)), width=2)
    d.rectangle([9, 7, 14, 10], fill=rgba((236, 220, 140) if on else (90, 90, 96)))
    finish(name, img)
# Auto quemado.
img, d = sprite(44, 24)
d.rectangle([2, 8, 41, 18], fill=rgba((70, 58, 54)))
d.polygon([(10, 8), (14, 2), (30, 2), (34, 8)], fill=rgba((60, 50, 48)))
d.rectangle([15, 3, 29, 7], fill=rgba((30, 26, 30)))
speckle(d, (2, 8, 41, 18), [rgba(RUST), rgba((40, 34, 36)), rgba((110, 70, 50))], 60)
for wx in (10, 34):
    d.ellipse([wx - 4, 15, wx + 4, 23], fill=rgba((40, 36, 40)))
finish("car_burnt", img)
# Colchón tirado.
img, d = sprite(30, 14)
d.rectangle([1, 2, 28, 12], fill=rgba((196, 186, 160)))
d.ellipse([6, 4, 16, 10], fill=rgba((160, 140, 96)))  # mancha
for x in range(4, 28, 6):
    d.point((x, 7), fill=rgba((150, 140, 120)))
finish("mattress", img)
# Carrito de supermercado volcado.
img, d = sprite(22, 16)
d.polygon([(2, 3), (18, 3), (16, 11), (4, 11)], fill=rgba((160, 160, 170)))
for x in range(4, 18, 3):
    d.line([(x, 3), (x - 1, 11)], fill=rgba((110, 110, 120)))
d.ellipse([3, 11, 7, 15], fill=rgba((40, 40, 46)))
d.ellipse([14, 11, 18, 15], fill=rgba((40, 40, 46)))
finish("cart", img)
# Bolsas de basura.
img, d = sprite(22, 14)
for x, c in ((2, (50, 52, 58)), (10, (40, 42, 48)), (6, (60, 62, 68))):
    d.ellipse([x, 3, x + 10, 13], fill=rgba(c))
    d.point((x + 5, 3), fill=rgba((200, 200, 200)))
finish("trash", img)
# Contenedor.
img, d = sprite(32, 22)
d.rectangle([1, 4, 30, 21], fill=rgba((70, 100, 80)))
d.rectangle([0, 2, 31, 6], fill=rgba((56, 84, 66)))
speckle(d, (1, 7, 30, 20), [rgba(RUST), rgba((56, 84, 66))], 30)
finish("dumpster", img)
# Neumáticos apilados.
img, d = sprite(18, 16)
for y in (9, 4):
    d.ellipse([1, y, 16, y + 7], fill=rgba((36, 34, 40)))
    d.ellipse([6, y + 2, 11, y + 5], fill=rgba((70, 68, 76)))
finish("tires", img)
# Banco roto.
img, d = sprite(30, 16)
d.rectangle([1, 4, 28, 7], fill=rgba(WOOD))
d.rectangle([1, 9, 18, 11], fill=rgba(WOOD))
d.line([(20, 9), (27, 13)], fill=rgba(WOOD), width=2)  # tabla caída
d.rectangle([3, 8, 4, 15], fill=rgba((60, 60, 66)))
d.rectangle([25, 8, 26, 15], fill=rgba((60, 60, 66)))
finish("bench_broken", img)
# Hamaca rota (parque).
img, d = sprite(40, 36)
d.line([(2, 35), (8, 2), (32, 2), (38, 35)], fill=rgba((150, 70, 60)), width=2)
d.line([(14, 3), (14, 26)], fill=rgba((110, 110, 116)))
d.line([(20, 3), (21, 26)], fill=rgba((110, 110, 116)))
d.rectangle([12, 26, 22, 27], fill=rgba(WOOD))
d.line([(26, 3), (28, 18)], fill=rgba((110, 110, 116)))  # cadena cortada
finish("swing", img)
# Reja de alambre (tramo de 16 px) y cerco de madera roto.
img, d = sprite(16, 22)
d.rectangle([0, 0, 1, 21], fill=rgba((110, 110, 118)))
for k in range(-22, 16, 4):
    d.line([(k, 21), (k + 21, 0)], fill=rgba((150, 150, 160, 200)))
    d.line([(k, 0), (k + 21, 21)], fill=rgba((150, 150, 160, 200)))
d.line([(0, 0), (15, 0)], fill=rgba((110, 110, 118)))
save("fence_chain", img)
img, d = sprite(16, 18)
for x, h in ((1, 17), (6, 13), (11, 16)):
    d.rectangle([x, 18 - h, x + 3, 17], fill=rgba((126, 96, 66)))
d.line([(0, 6), (15, 7)], fill=rgba((100, 74, 52)), width=2)
finish("fence_wood", img)
# Perro callejero (dos cuadros: quieto / mueve la cola).
for name, tail in (("dog_a", 0), ("dog_b", 1)):
    img, d = sprite(20, 14)
    d.rectangle([4, 5, 15, 9], fill=rgba((160, 128, 90)))
    d.rectangle([13, 2, 18, 7], fill=rgba((160, 128, 90)))
    d.point((17, 4), fill=INK)
    for x in (5, 8, 12, 14):
        d.line([(x, 10), (x, 13)], fill=rgba((140, 110, 76)))
    d.line([(4, 6), (1, 3 + tail * 3)], fill=rgba((140, 110, 76)))
    finish(name, img)
# Cuervo (posado / aleteando).
for name, wing in (("crow_a", 0), ("crow_b", 1)):
    img, d = sprite(10, 8)
    d.ellipse([2, 3, 7, 7], fill=rgba((30, 28, 36)))
    d.point((8, 4), fill=rgba((180, 160, 60)))
    d.ellipse([5, 1, 8, 4], fill=rgba((30, 28, 36)))
    if wing:
        d.line([(3, 4), (0, 0)], fill=rgba((30, 28, 36)))
    save(name, img)
# Carteles de "SE BUSCA" pegados en un poste (se usa sobre postes y paredes).
img, d = sprite(10, 12)
d.rectangle([0, 0, 9, 11], fill=rgba((220, 214, 190)), outline=INK)
d.rectangle([2, 2, 7, 6], fill=rgba((90, 84, 90)))
d.line([(2, 8), (7, 8)], fill=rgba((120, 110, 100)))
save("poster", img)
# Parada de colectivo.
img, d = sprite(36, 36)
d.rectangle([2, 8, 3, 35], fill=rgba((90, 90, 100)))
d.rectangle([32, 8, 33, 35], fill=rgba((90, 90, 100)))
d.rectangle([0, 4, 35, 9], fill=rgba((96, 112, 126)))
d.rectangle([6, 24, 29, 27], fill=rgba(WOOD))
d.rectangle([28, 0, 35, 6], fill=rgba((220, 200, 70)))
finish("bus_stop", img)
# Fuente seca de la placita.
img, d = sprite(40, 24)
d.ellipse([1, 4, 38, 23], fill=rgba((150, 146, 140)))
d.ellipse([6, 8, 33, 20], fill=rgba((96, 86, 70)))
d.rectangle([17, 0, 22, 13], fill=rgba((150, 146, 140)))
speckle(d, (8, 10, 31, 18), [rgba((80, 70, 56)), rgba((120, 110, 90))], 20)
finish("fountain_dry", img)
# Campamento bajo el puente: cartones y la mochila.
img, d = sprite(34, 16)
d.polygon([(1, 10), (12, 4), (30, 6), (33, 14), (4, 15)], fill=rgba((176, 146, 100)))
d.line([(12, 4), (14, 14)], fill=rgba((146, 116, 80)))
d.rectangle([20, 2, 27, 9], fill=rgba((80, 92, 110)))  # mochila
d.line([(21, 4), (26, 4)], fill=rgba((60, 70, 86)))
finish("camp", img)
# Pilar del puente (vista oblicua: cara frontal).
img, d = sprite(20, 40)
d.rectangle([0, 0, 19, 39], fill=rgba((112, 108, 112)))
d.rectangle([0, 0, 3, 39], fill=rgba((90, 86, 92)))
speckle(d, (0, 0, 19, 39), [rgba((96, 92, 98)), rgba((130, 126, 128))], 40)
d.line([(6, 28), (14, 22)], fill=rgba((70, 120, 160)), width=1)  # grafiti
save("pillar", outline(img))

print("edificios y objetos listos en", OUT)
