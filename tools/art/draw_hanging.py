"""Protagonista colgado de atrás del camión (vista de costado, mirando a la derecha).
Mismos colores y contorno que la hoja de personaje del beat 'em up.
Las manos agarran la manija siempre en el mismo punto de cada cuadro (HANDS), así el cuerpo
puede balancearse como un péndulo rotando alrededor de ese punto.
Salida: assets/prologue/source/player_hang.png (8 cuadros de 32x40).
Uso: python tools/art/draw_hanging.py  (desde la carpeta del proyecto)"""
from PIL import Image, ImageDraw

W, H = 32, 40
HANDS = (20, 3)  # punto de agarre (se usa también en el juego)
OUTLINE = (0, 0, 8, 255)
SKIN = (245, 160, 151, 255)
SKIN_SH = (232, 106, 115, 255)
SHIRT = (255, 255, 255, 255)
SHIRT_SH = (179, 185, 209, 255)
PANTS = (40, 92, 196, 255)
PANTS_SH = (20, 52, 100, 255)
HAIR = (51, 57, 65, 255)
HAIR_HI = (74, 84, 98, 255)
EYE = (36, 159, 222, 255)
SHOE = (0, 0, 8, 255)


def outline(img):
    """Contorno de 1 px alrededor de todo lo pintado (como los sprites originales)."""
    src = img.copy()
    px, out = src.load(), img.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0 and px[nx, ny] != OUTLINE:
                        out[x, y] = OUTLINE
                        break


def leg(d, hip, foot, color, shade):
    d.line([hip, foot], fill=color, width=3)
    d.line([(hip[0] - 1, hip[1]), (foot[0] - 1, foot[1])], fill=shade, width=1)
    d.rectangle([foot[0] - 1, foot[1], foot[0] + 2, foot[1] + 1], fill=SHOE)


def figure(legs, back_arm=None, front_arm=None, head_dy=0):
    """legs: [(cadera, pie), (cadera, pie)] (pierna de atrás primero).
    back_arm / front_arm: punto final del brazo (None = agarrado de la manija)."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    hx, hy = HANDS
    # Brazo de atrás.
    d.line([(13, 14), back_arm or (hx - 1, hy + 1)], fill=SKIN_SH, width=2)
    # Piernas.
    leg(d, *legs[0], PANTS_SH, PANTS_SH)
    # Torso (camisa) y cinturón.
    d.rectangle([11, 14, 17, 22], fill=SHIRT)
    d.line([(11, 14), (11, 22)], fill=SHIRT_SH)
    d.rectangle([11, 23, 17, 24], fill=PANTS_SH)
    leg(d, *legs[1], PANTS, PANTS_SH)
    # Cabeza: cara a la derecha, pelo arriba y atrás.
    y0 = 6 + head_dy
    d.rectangle([11, y0, 17, y0 + 7], fill=SKIN)
    d.rectangle([11, y0, 17, y0 + 2], fill=HAIR)
    d.rectangle([11, y0, 12, y0 + 5], fill=HAIR)
    d.point((13, y0), fill=HAIR_HI)
    d.point((16, y0 + 4), fill=EYE)
    d.point((17, y0 + 6), fill=SKIN_SH)
    # Esquinas redondeadas y un mechón de pelo.
    for c in ((11, y0), (17, y0), (11, y0 + 7)):
        d.point(c, fill=(0, 0, 0, 0))
    d.point((10, y0 + 2), fill=HAIR)
    d.point((14, y0 - 1), fill=HAIR)
    # Brazo de adelante (por delante de la cara) y puños en la manija.
    d.line([(16, 14), front_arm or (hx, hy + 1)], fill=SKIN, width=2)
    if not back_arm or not front_arm:
        d.rectangle([hx - 1, hy - 1, hx + 1, hy + 1], fill=SKIN)
    outline(img)
    return img


frames = [
    # 0, 1: colgado, piernas quietas / leve vaivén
    figure([((12, 25), (11, 36)), ((15, 25), (15, 37))]),
    figure([((12, 25), (10, 36)), ((15, 25), (14, 37))]),
    # 2: piernas hacia la izquierda (se va para ese lado)
    figure([((12, 25), (6, 35)), ((15, 25), (9, 36))]),
    # 3: piernas hacia la derecha (contra el camión)
    figure([((12, 25), (15, 35)), ((15, 25), (19, 35))]),
    # 4: carga la patada (rodilla arriba)
    figure([((12, 25), (11, 36)), ((15, 25), (9, 30))]),
    # 5: patada hacia atrás (a la izquierda, donde vienen las motos)
    figure([((12, 25), (12, 36)), ((14, 25), (2, 26))]),
    # 6, 7: una sola mano: el brazo de atrás se suelta y manotea, las piernas se encogen
    figure([((12, 25), (7, 32)), ((15, 25), (12, 33))], back_arm=(5, 17)),
    figure([((12, 25), (9, 33)), ((15, 25), (16, 32))], back_arm=(7, 22)),
]

sheet = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
for i, f in enumerate(frames):
    sheet.paste(f, (i * W, 0))
sheet.save("assets/prologue/source/player_hang.png")
print("player_hang:", len(frames), "cuadros")
