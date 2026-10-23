"""Fondos de los minijuegos que estaban hechos con rectángulos (python -X utf8 tools/art/draw_fondos.py).

Con el motor de las viñetas, a pantalla entera (320x180), 4 cuadros por hoja (1280x180), en assets/ui/fondos/.
Lo que se juega (la pila de ladrillos, las monedas, el charco, la lluvia) lo sigue pintando el script: aquí va
solo el lugar.

    obra           la obra de día (scripts/world/Obra.gd): el edificio a medio hacer con la polisombra, el
                   andamio, la grúa allá atrás, la mezcladora, los bultos de cemento, la carretilla, el perro
                   de la obra dormido, la pila de ladrillos. Los pies van en y=140.
    obra_lluvia    lo mismo, con el cielo cerrado, el barro y los charcos (el turno 2).
    fuente         la fuente del Centro vista desde arriba (scripts/world/Fuente.gd): la plaza, el borde de
                   piedra, el agua con las baldosas del fondo, el chorro del centro. Pozo en (160, 98), radios
                   (130, 62).
    techo_0/1      (en assets/prologue/) la fachada de los techos de la huida, que se repite: ladrillo, o
                   pañete pintado y descascarado; arriba el remate, la humedad que baja.
    fuente_mano    la mano que mete él (16x28, 2 cuadros: abierta, agarrando): la manga del saco, el puño de
                   la camisa.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import draw_epilogo as E  # noqa: E402  (pone el motor a 320x180)
from draw_epilogo import dk, lit, poly, ell, lines, post_lines, txt, floor, sky, cloud, W, H  # noqa: E402
import vinetas_motor as vm  # noqa: E402
from vinetas_motor import Cv, Env, col, mix, rain  # noqa: E402

OUT = "assets/ui/fondos/"
FRAMES = 4
BRICK = (178, 82, 56)
CONCRETE = (170, 168, 164)
STEEL = (96, 100, 112)


# ---------------------------------------------------------------- LA OBRA

def obra(f, wet=False):
    cv = Cv(f)
    env = (Env((0.5, 0.52, 0.58), (0.9, 0.92, 0.98), (1, -1), half=0.3) if wet else
           Env((0.68, 0.64, 0.64), (1.34, 1.12, 0.9), (1, -1), half=0.45))
    if wet:
        sky(cv, 100, [(96, 102, 116), (124, 128, 140), (150, 152, 160)])
    else:
        sky(cv, 100, [(110, 156, 214), (150, 186, 228), (206, 220, 232)])
        for cx, cy, s in ((50 + f * 2, 20, 1.1), (170 + f * 2, 12, 0.8)):
            cloud(cv, cx, cy, s, (248, 248, 250), (218, 222, 234))
    haze = (150, 154, 170) if not wet else (120, 124, 136)
    rng = np.random.default_rng(3)
    for k in range(16):  # la ciudad de atrás
        bx, bh = k * 17 - 4, int(rng.integers(10, 30))
        cv.fill(cv.box(bx, 96 - bh, bx + 15, 98), mix(haze, (200, 200, 210), rng.random() * 0.3))
    # La grúa torre, allá atrás, con el gancho que se mece.
    crane = mix((210, 170, 60), haze, 0.45)
    cv.fill(cv.box(150, 18, 154, 98), crane)
    segs = [[(150, y), (154, y + 5)] for y in range(18, 96, 5)]
    segs += [[(100, 18), (220, 18)], [(100, 21), (220, 21)], [(152, 18), (152, 10)], [(152, 10), (110, 18)], [(152, 10), (215, 18)]]
    post_lines(cv, segs, crane)
    hx = 196 + [0, 1, 0, -1][f]
    post_lines(cv, [[(196, 21), (hx, 46)]], (60, 60, 66))
    cv.fill(cv.box(hx - 2, 46, hx + 2, 50), (70, 70, 76))
    cv.fill(cv.box(124, 21, 134, 28), mix((80, 80, 90), haze, 0.3))  # el contrapeso
    floor(cv, 98, (150, 122, 92) if not wet else (110, 92, 74), env)
    # La cerca de polisombra verde del fondo, con el letrero de la constructora.
    mesh = (52, 112, 70)
    cv.shape(cv.box(0, 80, 244, 100), mesh, env, shade=0, half=False)
    cv.veil(cv.box(0, 80, 244, 100), dk(env, mesh, 0.7), 0.35)
    for xx in range(0, 244, 30):
        cv.fill(cv.box(xx, 76, xx + 2, 100), dk(env, (130, 110, 80), 1.0))
    cv.shape(cv.box(64, 70, 136, 92), (240, 236, 226), env, shade=1)
    cv.fill(cv.box(64, 70, 136, 76), (220, 140, 40))
    txt(cv, "USE CASCO", 82, 79, (60, 60, 70))
    txt(cv, "PELIGRO OBRA", 76, 85, (190, 50, 50))
    # El edificio a medio hacer: columnas, placas, ladrillo a medias, los hierros de arriba, la polisombra.
    slab = [30, 56, 82, 108]
    cv.shape(cv.box(250, 30, 320, 140), (120, 116, 112), env, shade=0, half=False)
    for i, y in enumerate(slab):
        cv.shape(cv.box(246, y, 320, y + 4), CONCRETE, env, shade=1)
        if i >= 1:  # los pisos de abajo ya tienen ladrillo
            m = cv.box(256, y - 22, 320, y)
            cv.fill(m, dk(env, BRICK, 1.0))
            ls = [[(256, yy), (320, yy)] for yy in range(y - 22, y, 3)]
            ls += [[(xx + (3 if (yy // 3) % 2 else 0), yy), (xx + (3 if (yy // 3) % 2 else 0), yy + 3)] for yy in range(y - 22, y, 3) for xx in range(256, 320, 7)]
            lines(cv, ls, dk(env, BRICK, 0.7))
            for wx in (264, 296):  # los huecos de las ventanas
                cv.fill(cv.box(wx, y - 18, wx + 14, y - 6), (40, 40, 48))
    for xx in (252, 286, 316):
        cv.shape(cv.box(xx, 26, xx + 5, 140), CONCRETE, env, shade=1)
    post_lines(cv, [[(xx + k, 26), (xx + k - 1 + (k % 2), 16)] for xx in (252, 286, 316) for k in (1, 3)], (110, 70, 50))  # los hierros
    flap = [0, 2, 3, 1][f]
    m = poly(cv, [(296, 30), (320, 30), (320, 76), (300 + flap, 72)])
    cv.veil(m, mix(mesh, (60, 140, 80), 0.3), 0.7)
    cv.fill(cv.box(246, 134, 320, 140), dk(env, CONCRETE, 0.9))
    # El andamio: tubos, crucetas, las tablas, la escalera.
    for xx in (240, 278):
        cv.shape(cv.box(xx, 28, xx + 3, 140), STEEL, env, shade=1)
    braces = []
    for y0 in range(32, 136, 26):
        braces += [[(242, y0), (278, y0 + 26)], [(278, y0), (242, y0 + 26)]]
    post_lines(cv, braces, dk(env, STEEL, 1.1))
    for y in range(40, 140, 25):
        cv.shape(cv.box(236, y - 3, 284, y), (176, 130, 80), env, shade=1)
    cv.fill(cv.box(262, 40, 264, 140) | cv.box(270, 40, 272, 140), dk(env, (150, 110, 70), 1.0))
    post_lines(cv, [[(262, y), (272, y)] for y in range(44, 140, 6)], dk(env, (150, 110, 70), 1.0))
    # La mezcladora (gira), los bultos de cemento, la carretilla, la arena.
    cv.shape(cv.mask(lambda d: (d.ell(160, 112, 22, 6), d.ell(152, 112, 14, 8))), (196, 170, 120) if not wet else (150, 130, 96), env, shade=2)  # la arena
    mixer = (226, 120, 40)
    cv.shape(cv.mask(lambda d: d.poly([(82, 96), (104, 92), (112, 104), (104, 114), (84, 112)])), mixer, env, shade=2)
    for k in range(3):
        sx = 88 + ((k * 7 + f * 3) % 18)
        post_lines(cv, [[(sx, 96), (sx + 3, 112)]], dk(env, mixer, 0.7))
    cv.shape(cv.box(84, 112, 112, 116), (70, 70, 76), env, shade=1)
    for wx in (88, 108):
        cv.shape(ell(cv, wx, 119, 4, 4), (30, 30, 34), env, shade=1)
    cv.fill(ell(cv, 110, 96, 3, 3), (70, 60, 50))
    sack = (210, 204, 190)
    for i, (sx, sy) in enumerate(((178, 118), (192, 118), (206, 118), (185, 112), (199, 112), (192, 106))):
        cv.shape(cv.mask(lambda d, sx=sx, sy=sy: (d.rect(sx - 6, sy - 6, sx + 6, sy), d.ell(sx, sy - 6, 6, 1.6))), sack, env, shade=1)
        cv.fill(cv.box(sx - 3, sy - 4, sx + 3, sy - 2), (60, 90, 170))
    if wet:  # la carpa encima de los bultos
        cv.veil(poly(cv, [(168, 100), (216, 100), (218, 120), (166, 120)]), (60, 110, 190), 0.75)
    else:  # el perro de la obra, dormido arriba de los bultos (es el que más horas tiene)
        dog = (196, 170, 130)
        cv.shape(cv.mask(lambda d: (d.ell(192, 98, 8, 3.4), d.ell(198, 97, 3.4, 3), d.ell(186, 99, 3, 2))), dog, env, shade=1)
        cv.fill(cv.box(201, 95, 203, 97), dk(env, dog, 0.7))
        cv.post.append(lambda d: d.point((192, 95 - (f % 2)), fill=(240, 240, 240)) if f in (1, 2) else None)
    cv.shape(cv.mask(lambda d: (d.poly([(40, 108), (64, 108), (60, 118), (44, 118)]), d.cap(64, 112, 74, 118, 1.6))), (110, 130, 150), env, shade=1)  # la carretilla
    cv.shape(ell(cv, 42, 121, 4, 4), (30, 30, 34), env, shade=1)
    post_lines(cv, [[(46, 118), (44, 124)], [(58, 118), (60, 124)]], STEEL)
    # La pila de ladrillos de abajo (de donde él los carga).
    for i in range(6):
        for j in range(4 - i % 2):
            bx, by = 4 + j * 9 + (i % 2) * 4, 134 - i * 5
            cv.shape(cv.box(bx, by, bx + 8, by + 4), BRICK, env, shade=1)
    # El camino: huellas de llanta, piedritas, charcos.
    post_lines(cv, [[(0, 146), (320, 144)], [(0, 152), (320, 150)]], dk(env, (150, 122, 92) if not wet else (110, 92, 74), 0.72))
    rng = np.random.default_rng(8)
    for _ in range(90):
        cv.px(int(rng.integers(0, W)), int(rng.integers(100, H)), dk(env, (196, 186, 170), 0.9))
    if wet:
        for px_, pw in ((40, 26), (210, 30), (110, 18)):
            pud = ell(cv, px_, 158, pw, 3)
            cv.fill(pud, (96, 104, 124))
            for k in range(2):
                rx = px_ - pw + 6 + ((f * 5 + k * 13) % (pw * 2 - 10))
                cv.fill(cv.box(rx, 157 + k, rx + 4, 158 + k) & pud, (170, 180, 200))
    return cv


# ---------------------------------------------------------------- LA FUENTE (desde arriba)

PC, PR = (160, 98), (130, 62)


def fuente(f):
    cv = Cv(f)
    env = Env((0.72, 0.7, 0.7), (1.24, 1.12, 0.96), (-1, -1), half=0.4)
    # La plaza: baldosa de piedra, gastada; las juntas.
    stone = (176, 166, 152)
    cv.shape(cv.box(0, 0, W, H), stone, env, shade=0, half=False, rim=False)
    rng = np.random.default_rng(5)
    for y in range(0, H, 16):
        for x in range(-(y // 16 % 2) * 8, W, 16):
            cv.fill(cv.box(x + 1, y + 1, x + 15, y + 15), mix(dk(env, stone, 1.0), (150, 140, 128), rng.random() * 0.35))
    lines(cv, [[(0, y), (W, y)] for y in range(0, H, 16)], dk(env, stone, 0.7))
    lines(cv, [[(x - (y // 16 % 2) * 8, y), (x - (y // 16 % 2) * 8, y + 16)] for y in range(0, H, 16) for x in range(0, W + 16, 16)], dk(env, stone, 0.7))
    cv.grain(cv.box(0, 0, W, H), 1.3)
    for _ in range(14):  # chicles pegados
        cv.px(int(rng.integers(0, W)), int(rng.integers(0, H)), (90, 86, 84))
    # La sombra de la fuente, corrida hacia abajo a la derecha.
    cv.veil(ell(cv, PC[0] + 6, PC[1] + 8, PR[0] + 14, PR[1] + 12), (60, 56, 60), 0.4)
    # El borde de piedra: bloques, con las juntas.
    rim = (214, 206, 192)
    outer = ell(cv, *PC, PR[0] + 12, PR[1] + 10)
    inner = ell(cv, *PC, *PR)
    cv.shape(outer & ~inner, rim, env, shade=2)
    segs = []
    for a in np.linspace(0, 2 * np.pi, 34, endpoint=False):
        segs.append([(PC[0] + np.cos(a) * PR[0], PC[1] + np.sin(a) * PR[1]), (PC[0] + np.cos(a) * (PR[0] + 12), PC[1] + np.sin(a) * (PR[1] + 10))])
    lines(cv, segs, dk(env, rim, 0.75))
    # El agua: hondo en la mitad, las baldosas azules del fondo (torcidas por el agua), la luz que baila.
    ys, xs = np.mgrid[0:H, 0:W]
    r = np.sqrt(((xs - PC[0]) / PR[0]) ** 2 + ((ys - PC[1]) / PR[1]) ** 2)
    shallow, deep = np.array((84, 150, 162), float), np.array((38, 88, 112), float)
    k = np.clip(1 - r, 0, 1) ** 0.7
    water = shallow * (1 - k[..., None]) + deep * k[..., None]
    wob = np.sin(ys * 0.35 + f * 1.57) * 1.5
    tile = ((((xs + wob) // 10) + (ys // 10)) % 2 == 0)
    water[tile] *= 0.9
    grout = (((xs + wob) % 10) < 1) | ((ys % 10) < 1)
    water[grout] = water[grout] * 0.8 + np.array((200, 230, 230)) * 0.2
    cv.a[inner] = water[inner].astype(np.uint8)
    caust = np.sin(xs * 0.21 + ys * 0.13 + f * 1.57) + np.sin(xs * 0.11 - ys * 0.27 - f * 1.57)
    # (en hilos que se tuercen, no en puntos: los puntos se confundían con las monedas)
    cv.light(np.where(inner & (np.abs(caust - 0.9) < 0.06), 0.8, 0.0), (190, 236, 236), 0.35)
    cv.veil(inner & ~ell(cv, *PC, PR[0] - 3, PR[1] - 3), (30, 60, 80), 0.6)  # la sombrita del borde en el agua
    for lx, ly, c in ((70, 80, (150, 120, 60)), (232, 120, (120, 140, 70)), (120, 132, (170, 110, 50))):  # hojas que flotan
        lx += [0, 1, 1, 0][f]
        cv.fill(cv.mask(lambda d, lx=lx, ly=ly: d.ell(lx, ly, 3, 1.6)), c)
    # El centro: la columna con su taza y el chorrito que cae (las ondas, animadas).
    for i in range(3):
        rr = 16 + ((f + i * 1.33) % 4) * 4
        ring = ell(cv, PC[0], PC[1] + 2, rr, rr * 0.5) & ~ell(cv, PC[0], PC[1] + 2, rr - 1.2, rr * 0.5 - 0.8)
        cv.fill(ring & inner, (190, 226, 230))
    cv.shape(ell(cv, PC[0], PC[1] + 2, 12, 7), (196, 188, 176), env, shade=2)
    cv.shape(ell(cv, PC[0], PC[1] - 2, 9, 5), rim, env, shade=2)
    cv.fill(ell(cv, PC[0], PC[1] - 2, 6, 3), (90, 156, 170))
    cv.shape(ell(cv, PC[0], PC[1] - 8, 3, 3), (226, 220, 206), env, shade=1)
    cv.post.append(lambda d: (d.point((PC[0] - 1 + f % 3, PC[1] - 12), fill=(236, 250, 250)), d.point((PC[0] + 1, PC[1] - 11 + f % 2), fill=(236, 250, 250))))
    # Lo que hay en la plaza: palomas, una tapa, una bolsa de mecato.
    for bx, by in ((22, 18), (296, 160), (30, 166)):
        cv.shape(cv.mask(lambda d, bx=bx, by=by: (d.ell(bx, by, 3, 2), d.ell(bx + 3, by - 1, 1.6, 1.6))), (150, 152, 166), env, shade=1)
    cv.fill(ell(cv, 288, 20, 2, 2), (200, 60, 60))
    cv.shape(cv.box(10, 140, 18, 146), (240, 200, 60), env, shade=1)
    return cv


def mano():
    """La mano de él, desde arriba, metiéndose en el agua: abierta y agarrando."""
    out = Image.new("RGBA", (32, 28))
    d = ImageDraw.Draw(out)
    coat, coat_d, cuff, skin, skin_d, ink = (104, 110, 136), (74, 80, 106), (230, 224, 210), (220, 164, 128), (176, 120, 96), (38, 28, 44)
    for i, grab in enumerate((False, True)):
        ox = i * 16
        d.rectangle([ox + 4, 18, ox + 11, 27], fill=coat)          # la manga del saco
        d.line([(ox + 4, 18), (ox + 4, 27)], fill=coat_d)
        d.line([(ox + 11, 18), (ox + 11, 27)], fill=ink)
        d.rectangle([ox + 5, 16, ox + 10, 17], fill=cuff)          # el puño de la camisa
        d.ellipse([ox + 4, 9, ox + 11, 17], fill=skin)            # la palma
        d.line([(ox + 10, 11), (ox + 10, 16)], fill=skin_d)
        if grab:  # el puño cerrado: los nudillos
            for k in range(4):
                d.point((ox + 5 + k * 2, 9), fill=skin_d)
            d.line([(ox + 4, 12), (ox + 3, 14)], fill=skin)
        else:  # los dedos abiertos (y el pulgar de lado)
            for k, h in enumerate((5, 6, 6, 5)):
                x = ox + 5 + k * 2
                d.line([(x, 10), (x, 10 - h)], fill=skin)
                d.point((x, 10 - h), fill=mix(skin, (255, 255, 255), 0.2))
            d.line([(ox + 4, 13), (ox + 1, 10)], fill=skin)
        # el contorno oscuro del lado de la sombra
        px = out.copy().load()  # (sobre una copia: si no, el contorno se corre solo hacia la derecha)
        for y in range(28):
            for x in range(ox, ox + 15):
                if px[x, y][3] and not px[x + 1, y][3]:
                    out.putpixel((x + 1, y), ink + (255,))
    return out


SCENES = {"obra": obra, "obra_lluvia": lambda f: obra(f, True), "fuente": fuente}


def build(name):
    sheet = Image.new("RGBA", (W * FRAMES, H))
    for f in range(FRAMES):
        sheet.paste(SCENES[name](f).image(), (f * W, 0))
    sheet.save(OUT + name + ".png")
    return name


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    names = sys.argv[1:] or list(SCENES)
    if names[0] == "--prueba":
        out, names = names[1], names[2:] or list(SCENES)
        img = Image.new("RGB", (W * len(names), H))
        for i, n in enumerate(names):
            img.paste(SCENES[n](0).image().convert("RGB"), (i * W, 0))
        img.resize((img.width * 2, img.height * 2), Image.NEAREST).save(out)
    else:
        for n in names:
            print("ok", build(n))
        mano().save(OUT + "fuente_mano.png")
        print("ok fuente_mano")
        build_techos()


# ---------------------------------------------------------------- LOS TECHOS DE LA HUIDA (de noche)

def techo(v):
    """Un pedazo de fachada de 48 de ancho que se repite (scripts/prologue/Huida.gd, _slab): arriba el
    remate del techo; abajo, ladrillo (v=0) o pañete pintado y descascarado (v=1). De noche."""
    w, h = 48, 140
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    r = np.random.default_rng(40 + v)
    if v == 0:
        base, mortar, hi = (70, 42, 42), (46, 30, 34), (86, 54, 50)
        d.rectangle([0, 0, w, h], fill=base)
        for y in range(6, h, 4):
            d.line([(0, y), (w, y)], fill=mortar)
            off = 4 if (y // 4) % 2 else 0
            for x in range(off, w, 8):
                d.line([(x, y), (x, y + 3)], fill=mortar)
                if r.random() < 0.25:
                    d.line([(x + 1, y + 1), (x + 6, y + 1)], fill=hi)
                elif r.random() < 0.15:
                    d.rectangle([x + 1, y + 1, x + 7, y + 3], fill=(60, 36, 38))
    else:
        base = (64, 58, 74)
        d.rectangle([0, 0, w, h], fill=base)
        for _ in range(260):  # el pañete: grano
            x, y = int(r.integers(0, w)), int(r.integers(6, h))
            d.point((x, y), fill=(58, 52, 68) if r.random() < 0.6 else (72, 66, 82))
        for cx, cy in ((12, 40), (36, 90)):  # donde se cayó la pintura: asoma el ladrillo
            d.ellipse([cx - 6, cy - 4, cx + 6, cy + 4], fill=(66, 42, 44))
            d.line([(cx - 4, cy - 1), (cx + 4, cy - 1)], fill=(48, 30, 34))
    # La humedad que baja desde el remate.
    for x in range(0, w):
        run = int(6 + 10 * (0.5 + 0.5 * np.sin(x * 0.4 + v)) + r.integers(0, 4))
        for y in range(6, 6 + run):
            if (x + y) % 2 == 0:
                c = im.getpixel((x, y))
                im.putpixel((x, y), tuple(int(k * 0.82) for k in c[:3]) + (255,))
    # El remate del techo: el borde de concreto, la sombrita, una varilla, un tarro con una mata.
    d.rectangle([0, 0, w, 3], fill=(108, 84, 76))
    d.line([(0, 0), (w, 0)], fill=(140, 112, 100))
    d.line([(0, 4), (w, 4)], fill=(30, 22, 28))
    d.line([(0, 5), (w, 5)], fill=(40, 30, 34))
    if v == 0:
        d.line([(30, 0), (30, -6)], fill=(90, 60, 50))
    return im


def build_techos():
    for v in (0, 1):
        techo(v).save("assets/prologue/techo_%d.png" % v)
        print("ok techo_%d" % v)
