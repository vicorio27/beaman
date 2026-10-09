"""Lo bueno del barrio (las cosas agradables del Día 1, ver Conversations "Lo bueno del barrio"):
  pelaos_a.png, pelaos_b.png   tres pelados jugando fútbol en el lote (dos morrales de arco, la pelota)
  pesca.png                    la línea de pesca que alguien deja en la orilla: piedra, nylon, lata de carrete, balde
  assets/items/pescado.png     un bocachico
  assets/items/bombon.png      el bombón que regalan los pelados
Mismo estilo que draw_barrio.py (contorno violeta muy oscuro).
Uso: python tools/art/draw_lo_bueno.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path("assets/barrio")
INK = (38, 28, 44, 255)
SKINS = [(214, 160, 122, 255), (170, 112, 80, 255), (232, 186, 156, 255)]
SHIRTS = [(220, 180, 60, 255), (60, 110, 180, 255), (200, 70, 60, 255)]
HAIR = [(40, 32, 30, 255), (30, 24, 26, 255), (120, 80, 50, 255)]


def outline(img):
    w, h = img.size
    src = img.copy()
    px, out = src.load(), img.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != INK:
                        out[x, y] = INK
                        break
    return img


def kid(d, x, y, i, kick):
    """Un pelado de ~14 px de alto, pies en (x, y)."""
    skin, shirt, hair = SKINS[i], SHIRTS[i], HAIR[i]
    d.ellipse([x - 3, y - 15, x + 2, y - 10], fill=skin)
    d.rectangle([x - 3, y - 15, x + 2, y - 13], fill=hair)
    d.rectangle([x - 3, y - 9, x + 2, y - 5], fill=shirt)
    d.line([(x - 4, y - 9), (x - 5, y - 6)], fill=skin)
    d.line([(x + 3, y - 9), (x + 4, y - 6)], fill=skin)
    shorts = (50, 50, 70, 255)
    d.rectangle([x - 3, y - 5, x + 2, y - 3], fill=shorts)
    if kick:
        d.line([(x - 2, y - 3), (x - 2, y)], fill=skin)
        d.line([(x + 1, y - 3), (x + 4, y - 2)], fill=skin)
    else:
        d.line([(x - 2, y - 3), (x - 2, y)], fill=skin)
        d.line([(x + 1, y - 3), (x + 1, y)], fill=skin)


def pelaos(frame):
    img = Image.new("RGBA", (72, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for gx in (4, 16):  # el arco: dos morrales
        d.rectangle([gx, 22, gx + 4, 27], fill=(110, 80, 60, 255))
    kid(d, 12, 28, 0, False)                # el arquero
    kid(d, 40, 26 + frame, 1, frame == 0)   # el que patea
    kid(d, 60, 28, 2, frame == 1)
    bx = 30 if frame == 0 else 48           # la pelota va y viene
    d.ellipse([bx - 2, 24, bx + 2, 28], fill=(240, 240, 236, 255))
    d.point((bx, 26), fill=(40, 40, 40, 255))
    return outline(img)


def pesca():
    img = Image.new("RGBA", (30, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 8, 16, 17], fill=(120, 116, 110, 255))  # la piedra
    d.ellipse([4, 9, 10, 12], fill=(150, 146, 140, 255))
    d.rectangle([12, 4, 17, 9], fill=(170, 170, 176, 255))  # la lata de carrete
    d.line([(17, 5), (29, 1)], fill=(220, 220, 220, 200))   # el nylon, hacia el agua
    d.rectangle([20, 10, 27, 16], fill=(60, 110, 170, 255))  # el balde
    d.line([(20, 10), (27, 10)], fill=(90, 140, 200, 255))
    return outline(img)


def pescado():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 5, 12, 11], fill=(160, 170, 150, 255))
    d.polygon([(11, 8), (15, 5), (15, 11)], fill=(140, 150, 130, 255))
    d.line([(3, 9), (10, 9)], fill=(200, 205, 190, 255))
    d.point((4, 7), fill=INK)
    return outline(img)


def bombon():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([(8, 8), (8, 15)], fill=(236, 232, 222, 255))  # el palito
    d.ellipse([4, 3, 12, 10], fill=(220, 70, 110, 255))
    d.arc([5, 4, 11, 9], 200, 330, fill=(250, 170, 190, 255))
    return outline(img)


if __name__ == "__main__":
    bombon().save(Path("assets/items/bombon.png"))
    pelaos(0).save(OUT / "pelaos_a.png")
    pelaos(1).save(OUT / "pelaos_b.png")
    pesca().save(OUT / "pesca.png")
    pescado().save(Path("assets/items/pescado.png"))
    print("lo bueno del barrio: listo")
