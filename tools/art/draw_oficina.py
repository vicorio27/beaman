"""La Empresa del sueño de sigilo, en baldosas de 16x16 vistas desde arriba (scripts/dreams/Sigilo.gd).

    python tools/art/draw_oficina.py   -> assets/dreams/oficina_tiles.png (una fila; el orden, en TILES)

Mismo estilo que draw_relleno.py: contorno violeta oscuro, colores gastados. Lo que se juega se sigue leyendo
igual que antes: los escondites son verde oscuro (la mata, el locker), los documentos son amarillos (la
carpeta manila), el tablero tiene su luz (la pinta el script: roja prendido, verde apagado).
"""
import os
import random

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "dreams", "oficina_tiles.png")
INK = (38, 28, 44)
T = 16
TILES = ["piso0", "piso1", "piso_cafe", "piso_papel", "pared", "cara0", "cara_ventana", "cara_afiche", "cara_reloj",
         "esc0", "esc1", "esc2", "esc3", "mata", "locker", "doc", "puerta", "tablero"]

CARPET = (74, 80, 104)
WALL_TOP = (150, 150, 160)
WALL = (198, 192, 178)
WOOD = (176, 146, 106)
CHAIR = (52, 52, 64)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def tile():
    return Image.new("RGBA", (T, T), (0, 0, 0, 0))


def rect(im, box, c):
    ImageDraw.Draw(im).rectangle(box, fill=tuple(c) + (255,))


def px(im, x, y, c):
    if 0 <= x < T and 0 <= y < T:
        im.putpixel((x, y), tuple(c) + (255,))


def line(im, p, q, c):
    ImageDraw.Draw(im).line([p, q], fill=tuple(c) + (255,))


def ell(im, box, c):
    ImageDraw.Draw(im).ellipse(box, fill=tuple(c) + (255,))


def carpet(seed):
    """La alfombra gris azul de oficina: tramada, con la junta de la baldosa de alfombra."""
    im = tile()
    r = random.Random(seed)
    for y in range(T):
        for x in range(T):
            k = r.random()
            c = CARPET if k < 0.6 else (mix(CARPET, (0, 0, 0), 0.08) if k < 0.85 else mix(CARPET, (255, 255, 255), 0.07))
            px(im, x, y, c)
    for i in range(T):
        px(im, i, 0, mix(CARPET, (0, 0, 0), 0.15))
        px(im, 0, i, mix(CARPET, (0, 0, 0), 0.15))
    return im


def outline(im):
    src = im.copy().load()
    for y in range(T):
        for x in range(T):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < T and 0 <= yy < T and src[xx, yy][3] and src[xx, yy][:3] != INK:
                    im.putpixel((x, y), INK + (255,))
                    break


def over(base, top):
    base.alpha_composite(top)
    return base


def wall_top():
    im = tile()
    rect(im, (0, 0, 15, 15), WALL_TOP)
    rect(im, (0, 0, 15, 1), mix(WALL_TOP, (255, 255, 255), 0.25))
    rect(im, (0, 14, 15, 15), mix(WALL_TOP, (0, 0, 0), 0.25))
    for x in (0, 8):
        px(im, x + 3, 7, mix(WALL_TOP, (0, 0, 0), 0.12))
    return im


def wall_face(kind):
    """La pared vista de frente (la que tiene piso abajo): el borde de arriba, la pared, el guardaescoba."""
    im = tile()
    rect(im, (0, 0, 15, 3), WALL_TOP)
    rect(im, (0, 0, 15, 0), mix(WALL_TOP, (255, 255, 255), 0.25))
    rect(im, (0, 4, 15, 15), WALL)
    rect(im, (0, 4, 15, 4), mix(WALL, (0, 0, 0), 0.2))
    rect(im, (0, 14, 15, 15), (90, 84, 80))
    if kind == "ventana":  # la ciudad, de día, por la ventana
        rect(im, (2, 5, 13, 12), (60, 60, 70))
        rect(im, (3, 6, 12, 11), (140, 180, 220))
        rect(im, (3, 9, 5, 11), (110, 120, 150))
        rect(im, (7, 8, 9, 11), (100, 110, 140))
        rect(im, (10, 9, 12, 11), (120, 128, 156))
        line(im, (7, 6), (7, 11), (60, 60, 70))
        px(im, 4, 7, (230, 240, 250))
    elif kind == "afiche":  # "TRABAJO EN EQUIPO" (el de la montaña)
        rect(im, (4, 5, 11, 12), (40, 40, 46))
        rect(im, (5, 6, 10, 10), (230, 140, 90))
        line(im, (5, 10), (7, 7), (80, 70, 90))
        line(im, (7, 7), (10, 10), (80, 70, 90))
        px(im, 7, 7, (250, 250, 250))
        rect(im, (5, 11, 10, 11), (240, 240, 230))
    elif kind == "reloj":  # el reloj: siempre las 7:58
        ell(im, (4, 5, 11, 12), (40, 40, 46))
        ell(im, (5, 6, 10, 11), (244, 240, 230))
        line(im, (7, 8), (7, 6), INK)
        line(im, (7, 8), (9, 9), INK)
    return im


def desk(v):
    """Un escritorio de cubículo visto desde arriba: la tabla, lo que hay encima, la silla metida."""
    im = carpet(100 + v)
    top = tile()
    rect(top, (1, 1, 14, 10), WOOD)
    rect(top, (1, 1, 14, 1), mix(WOOD, (255, 255, 255), 0.25))
    rect(top, (1, 10, 14, 11), mix(WOOD, (0, 0, 0), 0.3))
    # el computador (el monitor de espaldas a uno, la pantalla prendida se ve de lado)
    rect(top, (4, 2, 10, 5), (44, 44, 52))
    rect(top, (5, 3, 9, 4), (90, 140, 200) if v != 2 else (60, 70, 90))
    rect(top, (4, 7, 10, 8), (210, 210, 214))  # el teclado
    for x in range(5, 10, 2):
        px(top, x, 7, (170, 170, 176))
    if v == 0:  # el pocillo de café (con el logo de la empresa)
        ell(top, (11, 6, 13, 8), (240, 240, 236))
        px(top, 12, 7, (90, 60, 40))
    elif v == 1:  # papeles en desorden
        rect(top, (11, 2, 13, 5), (244, 244, 240))
        rect(top, (12, 3, 14, 6), (230, 230, 226))
        px(top, 2, 8, (240, 210, 90))
    elif v == 2:  # la foto de la familia y el cactus
        rect(top, (11, 2, 13, 4), (120, 90, 60))
        px(top, 12, 3, (220, 180, 150))
        rect(top, (2, 6, 3, 8), (190, 100, 60))
        px(top, 2, 5, (90, 150, 80))
        px(top, 3, 5, (90, 150, 80))
    else:  # la lámpara y un post-it amarillo
        ell(top, (11, 2, 14, 5), (60, 60, 70))
        px(top, 12, 3, (250, 230, 160))
        rect(top, (2, 7, 3, 8), (250, 230, 90))
    # la silla, metida debajo
    ell(top, (5, 11, 10, 15), CHAIR)
    rect(top, (5, 11, 10, 11), mix(CHAIR, (255, 255, 255), 0.15))
    outline(top)
    return over(im, top)


def mata():
    """La mata grande de la esquina (de plástico): esconde."""
    im = carpet(201)
    t = tile()
    ell(t, (4, 9, 11, 15), (150, 84, 60))
    ell(t, (5, 10, 10, 12), (70, 50, 40))
    leaves = [(1, 1, 8, 8), (7, 0, 14, 7), (3, 5, 10, 11), (8, 5, 15, 11), (0, 5, 6, 10)]
    for k, b in enumerate(leaves):
        ell(t, b, (38, 92, 54) if k % 2 else (46, 106, 62))
    for x, y in ((4, 3), (10, 2), (6, 8), (12, 7), (2, 7)):
        px(t, x, y, (90, 160, 96))
    outline(t)
    return over(im, t)


def locker():
    """El locker verde (de metal): esconde."""
    im = tile()
    rect(im, (0, 0, 15, 15), (56, 98, 70))
    rect(im, (0, 0, 15, 2), (80, 128, 94))
    rect(im, (0, 15, 15, 15), (30, 56, 40))
    line(im, (8, 2), (8, 15), (36, 70, 48))
    for y in (5, 7, 9):
        line(im, (2, y), (6, y), (36, 70, 48))
        line(im, (10, y), (14, y), (36, 70, 48))
    px(im, 6, 11, (200, 200, 190))
    px(im, 10, 11, (200, 200, 190))
    return im


def doc():
    """La carpeta manila con los papeles (lo que hay que juntar)."""
    im = carpet(301)
    t = tile()
    rect(t, (3, 4, 12, 12), (226, 190, 92))
    rect(t, (3, 3, 7, 4), (226, 190, 92))
    rect(t, (5, 2, 13, 9), (246, 244, 236))
    for y in (4, 6):
        line(t, (6, y), (11, y), (150, 150, 160))
    rect(t, (3, 7, 12, 12), (240, 206, 104))
    px(t, 4, 8, (255, 236, 150))
    rect(t, (9, 10, 11, 11), (200, 50, 50))  # el sello de CONFIDENCIAL
    outline(t)
    return over(im, t)


def puerta():
    """La puerta de la oficina del jefe: madera buena, la plaquita dorada."""
    im = tile()
    rect(im, (0, 0, 15, 15), (110, 66, 40))
    rect(im, (1, 1, 14, 14), (138, 86, 52))
    for x in (4, 8, 12):
        line(im, (x, 2), (x, 13), (124, 76, 46))
    rect(im, (4, 3, 11, 4), (230, 196, 90))
    rect(im, (11, 7, 12, 8), (240, 210, 100))
    return im


def tablero():
    """El tablero de las cámaras: cuatro pantallitas (la luz grande la pinta el script)."""
    im = carpet(401)
    t = tile()
    rect(t, (1, 2, 14, 13), (60, 62, 72))
    rect(t, (1, 2, 14, 3), (96, 98, 110))
    for i, (x, y) in enumerate(((3, 5), (9, 5), (3, 10), (9, 10))):
        rect(t, (x, y - 1, x + 3, y + 1), (60, 150, 110) if i % 2 else (70, 120, 170))
    outline(t)
    return over(im, t)


def build():
    out = Image.new("RGBA", (T * len(TILES), T))
    made = {
        "piso0": carpet(1), "piso1": carpet(2), "pared": wall_top(),
        "cara0": wall_face(""), "cara_ventana": wall_face("ventana"), "cara_afiche": wall_face("afiche"), "cara_reloj": wall_face("reloj"),
        "esc0": desk(0), "esc1": desk(1), "esc2": desk(2), "esc3": desk(3),
        "mata": mata(), "locker": locker(), "doc": doc(), "puerta": puerta(), "tablero": tablero(),
    }
    cafe = carpet(3)  # la mancha de café de alguien que no se disculpó
    ell(cafe, (4, 6, 11, 11), mix(CARPET, (110, 80, 50), 0.45))
    made["piso_cafe"] = cafe
    papel = carpet(4)  # un papel en el piso
    rect(papel, (6, 6, 10, 9), (226, 226, 220))
    line(papel, (7, 7), (9, 7), (160, 160, 170))
    made["piso_papel"] = papel
    for i, n in enumerate(TILES):
        out.paste(made[n], (i * T, 0))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out.save(OUT)
    print("ok", OUT)


if __name__ == "__main__":
    build()
