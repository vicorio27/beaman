"""Arte del Parque de San Judas: el lugar menos lúgubre del juego. Iglesia de tejas, glorieta,
árboles con hojas (¡hojas!), negocios con gente que saluda, palomas.
Salida: assets/barrio/*.png (misma paleta y helpers que draw_barrio.py).
Uso: python tools/art/draw_parque.py  (desde la carpeta del proyecto)"""
import random
import sys
from pathlib import Path
from PIL import ImageDraw
sys.path.insert(0, str(Path(__file__).parent))
import draw_barrio as B
from draw_barrio import building, sprite, finish, save, rgba, INK

random.seed(77)
CREAM = (232, 220, 190)
GOLD = (236, 196, 80)


def iglesia():
    """Parroquia de San Judas Tadeo: fachada crema, campanario, puerta grande de madera, rosetón."""
    img = building(112, 64, 26, CREAM, roof="tile", windows=[(10, 22, 10, 18), (92, 22, 10, 18)], lit=(0, 1),
                   rust=0, sign=("SAN JUDAS", 30, 4, (120, 70, 50), (250, 230, 170)))
    d = ImageDraw.Draw(img)
    H = img.height
    d.rectangle([44, H - 30, 67, H - 1], fill=rgba((120, 76, 46)), outline=INK)           # puerta grande, abierta
    d.rectangle([47, H - 27, 64, H - 1], fill=rgba((250, 210, 120)))                      # adentro: velas
    d.line([(55, H - 27), (55, H - 1)], fill=rgba((200, 150, 80)))
    d.ellipse([49, 43, 62, 56], fill=rgba((90, 130, 200)), outline=INK)                   # rosetón
    d.line([(55, 43), (55, 56)], fill=rgba(GOLD)); d.line([(49, 49), (62, 49)], fill=rgba(GOLD))
    d.rectangle([2, H - 4, 109, H - 1], fill=rgba((180, 170, 150)))                       # escalón
    # Campanario: arriba a la izquierda, sobre el techo.
    from PIL import Image
    full = Image.new("RGBA", (112, H + 26), (0, 0, 0, 0))
    full.paste(img, (0, 26))
    d = ImageDraw.Draw(full)
    d.rectangle([4, 4, 26, 40], fill=rgba(CREAM), outline=INK)
    d.polygon([(2, 6), (15, -6), (28, 6)], fill=rgba(B.TILE_ROOF), outline=INK)
    d.rectangle([10, 12, 20, 24], fill=rgba((40, 30, 40)), outline=INK)
    d.ellipse([12, 16, 18, 24], fill=rgba(GOLD), outline=INK)                              # campana
    d.line([(15, -6), (15, -14)], fill=INK); d.line([(11, -10), (19, -10)], fill=INK)      # cruz (se recorta: no importa)
    save("iglesia", full)


def tienda():
    save("tienda", building(104, 40, 20, (210, 150, 110), roof="tile", windows=[(8, 18, 26, 12), (70, 18, 26, 12)],
                            door=(46, 12), lit=(0, 1), awning=(2, 100, (60, 140, 90), (240, 236, 210)), awning_y=11,
                            sign=("LA ESPERANZA", 4, 1, (60, 90, 60), (250, 240, 200)), rust=0))


def glorieta():
    img, d = sprite(64, 56)
    d.polygon([(4, 18), (32, 2), (60, 18)], fill=rgba((200, 90, 70)), outline=INK)           # techo
    d.rectangle([4, 18, 60, 22], fill=rgba((236, 230, 214)), outline=INK)
    for x in (8, 22, 40, 54):
        d.rectangle([x, 22, x + 2, 48], fill=rgba((236, 230, 214)))                          # columnas
    d.rectangle([2, 46, 62, 55], fill=rgba((200, 190, 170)), outline=INK)                    # tarima
    for x in range(6, 60, 6):
        d.line([(x, 46), (x, 55)], fill=rgba((170, 160, 140)))
    finish("glorieta", img)


def tree_green(name, seed):
    random.seed(seed)
    img, d = sprite(40, 52)
    d.rectangle([18, 30, 22, 51], fill=rgba((110, 80, 56)))
    for _ in range(26):
        x, y, r = random.randint(4, 30), random.randint(2, 28), random.randint(6, 10)
        d.ellipse([x, y, x + r, y + r], fill=rgba(random.choice([(86, 140, 70), (100, 158, 78), (72, 120, 60)])))
    for _ in range(6):  # florecitas (guayacán, a veces)
        x, y = random.randint(6, 34), random.randint(4, 30)
        d.point((x, y), fill=rgba((240, 220, 90)))
    finish(name, img)


def bench_green():
    img, d = sprite(30, 16)
    d.rectangle([1, 2, 28, 5], fill=rgba((70, 120, 80)))
    d.rectangle([1, 7, 28, 10], fill=rgba((80, 136, 90)))
    for x in (3, 25):
        d.rectangle([x, 10, x + 2, 15], fill=rgba((50, 50, 56)))
    finish("bench_green", img)


def flores():
    img, d = sprite(40, 34)
    d.rectangle([2, 14, 37, 33], fill=rgba((150, 110, 70)), outline=INK)                    # carrito
    d.rectangle([0, 0, 39, 6], fill=rgba((240, 120, 140)), outline=INK)                     # toldito
    d.line([(4, 6), (4, 14)], fill=INK); d.line([(35, 6), (35, 14)], fill=INK)
    for i, c in enumerate([(240, 80, 90), (250, 220, 80), (250, 250, 250), (200, 120, 220), (250, 150, 60)]):
        x = 5 + i * 6
        d.rectangle([x, 12, x + 4, 16], fill=rgba((70, 90, 120)))                           # baldes
        d.ellipse([x - 1, 7, x + 5, 13], fill=rgba(c))
    finish("flores", img)


def cachivaches():
    img, d = sprite(52, 24)
    d.rectangle([0, 6, 51, 23], fill=rgba((150, 60, 70)), outline=INK)                      # la cobija en el piso
    for x in range(2, 50, 6):
        d.line([(x, 7), (x + 3, 22)], fill=rgba((170, 80, 90)))
    d.ellipse([4, 9, 12, 17], fill=rgba((230, 200, 170)))                                    # cabeza de muñeca
    d.point([(7, 12)], fill=INK)
    d.rectangle([16, 10, 24, 17], fill=rgba((60, 60, 70)))                                   # radio
    d.ellipse([18, 12, 22, 16], fill=rgba((150, 150, 160)))
    d.ellipse([28, 9, 36, 17], fill=rgba(GOLD), outline=INK)                                 # reloj
    d.line([(32, 13), (32, 13)], fill=INK)
    d.rectangle([40, 12, 48, 16], fill=rgba((240, 240, 230)))                                # dentadura
    d.line([(41, 14), (47, 14)], fill=rgba((220, 120, 120)))
    d.rectangle([12, 0, 18, 8], fill=rgba((90, 130, 200)), outline=INK)                     # estampita
    finish("cachivaches", img)


def ajedrez():
    img, d = sprite(22, 20)
    d.rectangle([2, 0, 19, 10], fill=rgba((200, 196, 186)), outline=INK)
    for y in range(4):
        for x in range(4):
            if (x + y) % 2 == 0:
                d.rectangle([4 + x * 4, 1 + y * 2, 7 + x * 4, 2 + y * 2], fill=rgba((60, 50, 50)))
    d.rectangle([8, 10, 13, 19], fill=rgba((170, 166, 156)))
    finish("ajedrez", img)


def estatua():
    img, d = sprite(26, 46)
    d.rectangle([3, 34, 22, 45], fill=rgba((170, 166, 160)), outline=INK)                   # pedestal
    d.rectangle([9, 12, 17, 34], fill=rgba((120, 140, 130)))                                 # prócer de bronce verde
    d.ellipse([9, 3, 17, 12], fill=rgba((120, 140, 130)))
    d.line([(17, 16), (23, 8)], fill=rgba((120, 140, 130)), width=2)                         # señalando algo que nadie ve
    d.point([(12, 2), (14, 1)], fill=rgba((250, 250, 250)))                                  # caca de paloma
    finish("estatua", img)


def palomas():
    for k, dy in enumerate((0, 2)):
        img, d = sprite(26, 12)
        for (x, y) in [(2, 6), (10, 3 + dy), (18, 6 - dy // 2)]:
            d.ellipse([x, y, x + 6, y + 4], fill=rgba((150, 150, 160)))
            d.point((x + 5, y + 1), fill=rgba((90, 160, 120)))
            d.point((x + 6, y + 2), fill=rgba((230, 150, 60)))
        finish("palomas_%s" % "ab"[k], img)


def veterinaria():
    """La veterinaria del parque: chiquita, verde menta, una huella en el cartel."""
    img = building(76, 38, 18, (190, 226, 210), roof="tile", windows=[(6, 16, 18, 12)], door=(48, 14), lit=(0,),
                   rust=0, sign=("VETERINARIA", 2, 1, (40, 110, 90), (250, 250, 240)))
    d = ImageDraw.Draw(img)
    fy = 18
    d.ellipse([10, fy + 18, 18, fy + 25], fill=rgba((80, 60, 50)))       # la huella en la vidriera
    for k, (x, y) in enumerate([(9, fy + 14), (13, fy + 12), (17, fy + 14)]):
        d.ellipse([x, y, x + 3, y + 3], fill=rgba((80, 60, 50)))
    save("veterinaria", img)


def item_icons():
    """Íconos (16x16) de lo que vende Don Efraín y de la flor de Doña Leonor."""
    from PIL import Image
    out = Path("assets/items")

    def icon(name, fn):
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        fn(ImageDraw.Draw(img))
        B.outline(img).save(out / f"{name}.png")
    icon("reloj_sin_agujas", lambda d: (d.ellipse([2, 2, 13, 13], fill=rgba(GOLD)), d.ellipse([4, 4, 11, 11], fill=rgba((240, 236, 220)))))
    icon("estampita", lambda d: (d.rectangle([4, 1, 11, 14], fill=rgba((240, 236, 220))), d.rectangle([5, 3, 10, 10], fill=rgba((90, 130, 200))),
                                  d.ellipse([6, 3, 9, 6], fill=rgba(GOLD))))
    icon("muneca", lambda d: (d.ellipse([4, 1, 11, 8], fill=rgba((236, 200, 170))), d.rectangle([5, 8, 10, 14], fill=rgba((200, 90, 120))),
                               d.point((6, 4), fill=INK), d.rectangle([3, 0, 12, 2], fill=rgba((200, 160, 60)))))
    icon("dentadura", lambda d: (d.chord([2, 4, 13, 13], 180, 360, fill=rgba((220, 110, 120))), d.rectangle([3, 8, 12, 10], fill=rgba((250, 250, 240)))))
    icon("casete", lambda d: (d.rectangle([1, 4, 14, 12], fill=rgba((60, 60, 70))), d.rectangle([3, 5, 12, 8], fill=rgba((240, 200, 90))),
                               d.ellipse([4, 8, 6, 10], fill=rgba((200, 200, 210))), d.ellipse([9, 8, 11, 10], fill=rgba((200, 200, 210)))))
    icon("flor", lambda d: (d.line([(8, 7), (8, 15)], fill=rgba((70, 130, 60)), width=1), d.ellipse([4, 1, 12, 8], fill=rgba((240, 80, 90))),
                             d.ellipse([7, 3, 9, 5], fill=rgba((250, 220, 80)))))


if __name__ == "__main__":
    veterinaria()
    item_icons()
    iglesia()
    tienda()
    glorieta()
    tree_green("tree_green", 1)
    tree_green("tree_green2", 2)
    bench_green()
    flores()
    cachivaches()
    ajedrez()
    estatua()
    palomas()
    print("listo")
