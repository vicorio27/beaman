"""Arte del prólogo (vista de costado): fondos, camión, obstáculos y orilla.
Usa el fondo de calle y las hojas de personajes del pack viejo de beat 'em up (_old/).
Salida: assets/prologue/source/*.png (después correr apply_palette.py).
Uso: python tools/art/draw_prologue.py  (desde la carpeta del proyecto)"""
import random
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

random.seed(23)
OLD = Path("_old/assets/art")
OUT = Path("assets/prologue/source")
OUT.mkdir(parents=True, exist_ok=True)
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)

NIGHT = (24, 20, 32)
SILHOUETTE = (62, 56, 80)
SILHOUETTE_2 = (76, 70, 94)
LIT = (236, 232, 206)  # luz blanca-amarilla: el filtro frío la deja clara (no roja)
LIT_DIM = (150, 150, 140)
DARK = (30, 24, 34)

# --- Personajes: se copian tal cual (la paleta se aplica después).
for name in ("player", "enemy_goon", "enemy_punk", "enemy_thug"):
    shutil.copy(OLD / "characters" / f"{name}.png", OUT / f"{name}.png")
shutil.copy(OLD / "ui" / "go-go-go.png", OUT / "go.png")

street = Image.open(OLD / "backgrounds/street-background.png").convert("RGBA")
window = Image.open(OLD / "backgrounds/window.png").convert("RGBA")
garage = Image.open(OLD / "props/garage-door-closed.png").convert("RGBA")
bar_door = Image.open(OLD / "backgrounds/bar-entrance.png").convert("RGBA")
barrel = Image.open(OLD / "props/barrel.png").convert("RGBA").crop((0, 0, 32, 32))

# Filas de la tira de calle (400x64): 0-19 ladrillo, 20-63 vereda, adoquín y calle.
BRICK = street.crop((0, 0, 400, 20))
GROUND = street.crop((0, 20, 400, 64))
ROAD = street.crop((0, 50, 400, 64))


def tile_x(img, width):
    out = Image.new("RGBA", (width, img.height))
    for x in range(0, width, img.width):
        out.paste(img, (x, 0))
    return out


# --- Callejón de la pelea: 960x180. Pared de ladrillo, vereda, calle.
W, H = 1280, 180
alley = Image.new("RGBA", (W, H), NIGHT)
wall_bottom = 116
for y in range(0, wall_bottom, 20):
    alley.paste(tile_x(BRICK, W), (0, y))
alley.paste(tile_x(GROUND, W), (0, wall_bottom))
for y in range(wall_bottom + 44, H, 14):
    alley.paste(tile_x(ROAD, W), (0, y))
d = ImageDraw.Draw(alley)
# Oscurecer arriba (noche, techo del callejón).
for y in range(0, 40):
    a = int(200 * (1 - y / 40))
    d.line([(0, y), (W, y)], fill=NIGHT + (a,))
alley = Image.alpha_composite(Image.new("RGBA", (W, H), NIGHT), alley)
d = ImageDraw.Draw(alley)
# Ventanas (algunas prendidas), portones, entrada de bar, barriles.
for x in range(24, W - 24, 56):
    for y in (40, 72):
        if random.random() < 0.7:
            alley.paste(window, (x, y), window)
            if random.random() < 0.35:
                d.rectangle([x + 3, y + 3, x + 12, y + 12], fill=LIT)
for x in (150, 520, 800):
    big = garage.resize((96, 64), Image.NEAREST)
    alley.paste(big, (x, wall_bottom - 64), big)
alley.paste(bar_door, (360, wall_bottom - 64), bar_door)
for x in (110, 470, 700, 900):
    alley.paste(barrel, (x, wall_bottom - 26), barrel)
# Faroles: poste y halo de luz en la pared.
for x in (60, 330, 620, 880):
    d.rectangle([x, 20, x + 1, wall_bottom + 4], fill=SILHOUETTE)
    d.rectangle([x - 6, 18, x + 6, 21], fill=SILHOUETTE)
    d.rectangle([x - 4, 22, x + 4, 23], fill=LIT)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([x - 40, 10, x + 40, 90], fill=LIT + (40,))
    alley = Image.alpha_composite(alley, glow)
    d = ImageDraw.Draw(alley)
alley.save(OUT / "alley_bg.png")

# --- Ciudad de noche para el viaje en camión: 640x110, se repite en horizontal.
sky = Image.new("RGBA", (640, 110), (0, 0, 0, 0))
d = ImageDraw.Draw(sky)
x = 0
while x < 640:
    w = random.randint(28, 70)
    h = random.randint(40, 105)
    col = random.choice([SILHOUETTE, SILHOUETTE_2])
    d.rectangle([x, 110 - h, x + w - 2, 110], fill=col)
    for wy in range(110 - h + 6, 104, 9):
        for wx in range(x + 4, x + w - 6, 7):
            if random.random() < 0.18:
                d.rectangle([wx, wy, wx + 2, wy + 3], fill=LIT if random.random() < 0.6 else LIT_DIM)
    x += w
sky.save(OUT / "skyline.png")
tile_x(GROUND, 400).save(OUT / "road_strip.png")

# --- Camión de reparto (harinas), visto de costado, mirando a la derecha: 156x70.
truck = Image.new("RGBA", (156, 70), (0, 0, 0, 0))
d = ImageDraw.Draw(truck)
BOX, BOX_SH, BOX_DK = (214, 206, 190), (178, 168, 150), (110, 100, 92)
CAB, CAB_DK = (176, 64, 52), (118, 40, 36)
d.rectangle([6, 4, 112, 54], fill=BOX, outline=BOX_DK)  # caja
d.rectangle([6, 48, 112, 54], fill=BOX_SH)
d.line([(8, 6), (110, 6)], fill=(236, 230, 216))
d.rectangle([4, 4, 10, 54], fill=BOX_SH, outline=BOX_DK)  # puertas traseras
d.line([(7, 8), (7, 50)], fill=BOX_DK)
d.rectangle([2, 26, 4, 34], fill=(90, 90, 96))  # manija de donde se agarra
d.text((30, 20), "HARINAS", font=FONT, fill=(150, 70, 52))
d.text((36, 32), "EL SOL", font=FONT, fill=(150, 70, 52))
d.polygon([(114, 18), (140, 18), (152, 36), (152, 54), (114, 54)], fill=CAB, outline=CAB_DK)  # cabina
d.polygon([(120, 22), (138, 22), (146, 35), (120, 35)], fill=(120, 150, 170))  # vidrio
d.rectangle([150, 44, 155, 48], fill=LIT)  # farol
d.rectangle([0, 54, 116, 58], fill=(70, 66, 72))  # chasis / paragolpes
for wx in (22, 96, 132):
    d.ellipse([wx - 11, 48, wx + 11, 70], fill=(30, 28, 34))
    d.ellipse([wx - 5, 54, wx + 5, 64], fill=(120, 116, 124))
truck.save(OUT / "truck.png")

# --- Obstáculos y decorado del viaje.
branch = Image.new("RGBA", (56, 22), (0, 0, 0, 0))
d = ImageDraw.Draw(branch)
d.line([(56, 4), (30, 10), (4, 12)], fill=(86, 62, 44), width=3)
d.line([(30, 10), (18, 4)], fill=(86, 62, 44), width=2)
for _ in range(26):
    lx, ly = random.randint(2, 44), random.randint(2, 20)
    d.ellipse([lx, ly, lx + 6, ly + 4], fill=random.choice([(66, 104, 60), (84, 126, 72), (52, 84, 52)]))
branch.save(OUT / "branch.png")

sign = Image.new("RGBA", (24, 64), (0, 0, 0, 0))
d = ImageDraw.Draw(sign)
d.rectangle([11, 18, 12, 64], fill=(110, 110, 118))
d.polygon([(12, 0), (24, 10), (12, 20), (0, 10)], fill=(249, 194, 43), outline=(60, 50, 30))
d.polygon([(6, 10), (12, 5), (12, 8), (17, 8), (17, 12), (12, 12), (12, 15)], fill=(46, 34, 47))
sign.save(OUT / "sign_curve.png")

lamp = Image.new("RGBA", (24, 96), (0, 0, 0, 0))
d = ImageDraw.Draw(lamp)
d.rectangle([4, 6, 5, 96], fill=(70, 66, 80))
d.rectangle([4, 4, 20, 6], fill=(70, 66, 80))
d.rectangle([16, 7, 22, 9], fill=LIT)
lamp.save(OUT / "lamp.png")

tree = Image.new("RGBA", (48, 90), (0, 0, 0, 0))
d = ImageDraw.Draw(tree)
d.rectangle([22, 40, 26, 90], fill=(70, 52, 40))
for _ in range(40):
    cx, cy = random.randint(8, 40), random.randint(4, 46)
    d.ellipse([cx - 7, cy - 6, cx + 7, cy + 6], fill=random.choice([(74, 100, 58), (92, 120, 68), (62, 86, 52)]))
tree.save(OUT / "tree_side.png")

# --- Armas: capas que se superponen al protagonista (cuadro a cuadro, como la del cuchillo).
# La del cuchillo viene del pack; botella y caño se generan donde está el cuchillo en cada cuadro.
knife_sheet = Image.open(OLD / "characters/player_knife.png").convert("RGBA")
GLASS, GLASS_HI, GLASS_DK = (72, 150, 96), (150, 214, 160), (36, 84, 56)
PIPE, PIPE_HI = (120, 118, 130), (170, 168, 180)


def overlay_from_knife(draw_vertical, draw_horizontal, out_name):
    out = Image.new("RGBA", knife_sheet.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(out)
    for row in range(10):
        for col in range(10):
            cell = knife_sheet.crop((col * 48, row * 48, col * 48 + 48, row * 48 + 48))
            box = cell.getbbox()
            if not box:
                continue
            x0, y0, x1, y1 = box[0] + col * 48, box[1] + row * 48, box[2] + col * 48, box[3] + row * 48
            if (y1 - y0) >= (x1 - x0):
                draw_vertical(d, (x0 + x1) // 2, y1)
            else:
                draw_horizontal(d, x0, (y0 + y1) // 2)
    out.save(OUT / out_name)


def bottle_v(d, cx, bottom):
    d.rectangle([cx - 2, bottom - 9, cx + 1, bottom - 3], fill=GLASS, outline=GLASS_DK)
    d.rectangle([cx - 1, bottom - 12, cx, bottom - 9], fill=GLASS_DK)
    d.point((cx - 1, bottom - 7), fill=GLASS_HI)


def bottle_h(d, left, cy):
    d.rectangle([left, cy - 1, left + 3, cy], fill=GLASS_DK)
    d.rectangle([left + 3, cy - 2, left + 10, cy + 1], fill=GLASS, outline=GLASS_DK)
    d.point((left + 6, cy - 1), fill=GLASS_HI)


def pipe_v(d, cx, bottom):
    d.rectangle([cx - 1, bottom - 16, cx, bottom], fill=PIPE)
    d.point((cx - 1, bottom - 14), fill=PIPE_HI)


def pipe_h(d, left, cy):
    d.rectangle([left, cy - 1, left + 16, cy], fill=PIPE)
    d.point((left + 14, cy - 1), fill=PIPE_HI)


shutil.copy(OLD / "characters/player_knife.png", OUT / "player_knife.png")
shutil.copy(OLD / "characters/enemy_knife.png", OUT / "enemy_knife.png")
shutil.copy(OLD / "characters/enemy_boss.png", OUT / "enemy_boss.png")
shutil.copy(OLD / "particles/spark.png", OUT / "spark.png")
shutil.copy(OLD / "ui/avatars/avatar-player.png", OUT / "avatar_player.png")
shutil.copy(OLD / "ui/avatars/avatar-boss.png", OUT / "avatar_boss.png")
overlay_from_knife(bottle_v, bottle_h, "player_bottle.png")
overlay_from_knife(pipe_v, pipe_h, "player_pipe.png")

# Armas tiradas en el piso.
item = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(item)
bottle_h(d, 3, 12)
item.save(OUT / "item_bottle.png")
item = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(item)
pipe_h(d, 0, 13)
item.save(OUT / "item_pipe.png")
shutil.copy(OLD / "props/knife.png", OUT / "item_knife.png")

# Vidrios de la botella rota.
shards = Image.new("RGBA", (12, 6), (0, 0, 0, 0))
d = ImageDraw.Draw(shards)
for x, y in ((1, 3), (4, 1), (6, 4), (9, 2), (10, 5)):
    d.point((x, y), fill=GLASS_HI)
    d.point((x + 1, y), fill=GLASS)
shards.save(OUT / "shards.png")

# Moto de los matones (vista de costado, mirando a la derecha): 36x22.
bike = Image.new("RGBA", (36, 22), (0, 0, 0, 0))
d = ImageDraw.Draw(bike)
for wx in (7, 28):
    d.ellipse([wx - 6, 10, wx + 6, 21], fill=(24, 22, 28))
    d.ellipse([wx - 3, 13, wx + 3, 18], fill=(110, 108, 118))
d.line([(7, 15), (16, 10), (27, 15)], fill=(60, 58, 66), width=2)  # cuadro
d.polygon([(12, 7), (24, 6), (26, 11), (14, 12)], fill=(150, 40, 40), outline=(70, 20, 24))  # tanque
d.rectangle([5, 8, 14, 10], fill=(30, 28, 34))  # asiento
d.line([(25, 6), (29, 15)], fill=(150, 150, 160), width=2)  # horquilla
d.line([(25, 5), (30, 3)], fill=(40, 40, 46), width=2)  # manubrio
d.rectangle([30, 6, 33, 9], fill=LIT)  # farol
d.line([(4, 16), (14, 16)], fill=(170, 170, 180), width=2)  # caño de escape
bike.save(OUT / "bike.png")


print("prólogo: arte generado en", OUT)
