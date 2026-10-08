"""Los luchadores del torneo de domingo (Lucha1..4), con muñeco propio en el estilo del beat 'em up:
se parte de las hojas de los matones del prólogo (celdas de 48x48, ver SideFrames) y se los viste como
la gente del rediseño (draw_gente.py):
  Raúl        (hoja del jefe)   canoso, guayabera dorada, pantalón caqui.
  Alvarito    (hoja del thug)   pelo largo café, chaqueta de jean, pantalón negro.
  El Pecas    (hoja del punk)   pelirrojo, camiseta naranja, jean.
  Mauricio    (hoja del jefe)   bajito y ancho, chaleco de cuero café abierto, jean, canas.
  Mauricio 2  fase 2: sin chaleco (se lo quita: "Ya no más chaleco. Ya no más trago").
Salida: assets/dreams/luchador_<id>.png
Uso: python tools/art/draw_luchadores.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image

SRC = Path("assets/prologue")
OUT = Path("assets/dreams")
C = 48
OUTLINE = (46, 34, 47)
SKIN, SKIN_D = (252, 167, 144), (237, 128, 153)
FLASH = (255, 255, 255)


def cells(im):
    for cy in range(0, im.height, C):
        for cx in range(0, im.width, C):
            yield cx, cy


def opaque(px, cx, cy):
    return [(x, y) for x in range(cx, cx + C) for y in range(cy, cy + C) if px[x, y][3] > 0]


def is_flash(px, pts):
    """El destello blanco del golpe (la silueta entera blanca): no se toca."""
    return pts and sum(1 for p in pts if px[p][:3] == FLASH) > 0.5 * len(pts)


def recolor(im, mapping, head=None):
    """mapping: color → color en toda la celda. head: lo mismo, pero solo en la cabeza (las 9 filas de
    arriba de la figura, cuando está parado), para colores que en la hoja sirven para dos cosas."""
    px = im.load()
    for cx, cy in cells(im):
        pts = opaque(px, cx, cy)
        if not pts or is_flash(px, pts):
            continue
        top = min(y for _, y in pts)
        tall = max(y for _, y in pts) - top > 16
        for x, y in pts:
            c = px[x, y][:3]
            if head and tall and y - top < 9 and c in head:
                px[x, y] = head[c] + (255,)
            elif c in mapping:
                px[x, y] = mapping[c] + (255,)
    return im


def torso(im, pants: set, paint):
    """Viste el torso desnudo de la hoja del jefe: la piel entre el cuello y el cinturón, en el ancho
    del pantalón. paint(x, x0, x1, dark) → color (o None para dejar la piel)."""
    px = im.load()
    for cx, cy in cells(im):
        pts = opaque(px, cx, cy)
        if not pts or is_flash(px, pts):
            continue
        legs = [(x, y) for x, y in pts if px[x, y][:3] in pants]
        if len(legs) < 10:
            continue
        belt = min(y for _, y in legs)
        if max(y for _, y in pts) - min(y for _, y in pts) < 16:
            continue  # tirado en el piso: no se adivina dónde está el torso
        row = [x for x, y in legs if y <= belt + 1]
        x0, x1 = min(row), max(row)
        for x, y in pts:
            c = px[x, y][:3]
            if belt - 8 <= y < belt - 1 and x0 <= x <= x1 and c in (SKIN, SKIN_D):
                new = paint(x, x0, x1, c == SKIN_D)
                if new:
                    px[x, y] = new + (255,)
    return im


def gray_hair(im, color):
    """El pelo del jefe está dibujado con la tinta del contorno: canas = los pixeles de tinta de la
    cabeza (las 6 filas de arriba, parado) que no tocan el borde de la figura."""
    px = im.load()
    for cx, cy in cells(im):
        pts = opaque(px, cx, cy)
        if not pts or is_flash(px, pts):
            continue
        top = min(y for _, y in pts)
        if max(y for _, y in pts) - top < 16:
            continue
        inner = []
        for x, y in pts:
            if y - top < 6 and px[x, y][:3] == OUTLINE:
                if all(cx <= nx < cx + C and cy <= ny < cy + C and px[nx, ny][3] > 0
                       for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                    inner.append((x, y))
        for x, y in inner:
            px[x, y] = color + (255,)
    return im


def load(name):
    return Image.open(SRC / (name + ".png")).convert("RGBA")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    boss_pants = {(110, 39, 39)}
    jean = {(110, 39, 39): (66, 90, 140)}

    # Raúl: guayabera dorada, canoso, caqui.
    gold, gold_d = (236, 200, 104), (196, 160, 76)
    raul = torso(load("enemy_boss"), boss_pants, lambda x, x0, x1, d: gold_d if d else gold)
    raul = recolor(raul, {(110, 39, 39): (150, 128, 96)}, head={(62, 53, 70): (186, 184, 182)})
    raul = gray_hair(raul, (176, 174, 172))
    raul.save(OUT / "luchador_raul.png")

    # Mauricio: chaleco de cuero abierto (el pecho al medio), jean, canas.
    leather, leather_d = (110, 70, 46), (82, 50, 34)

    def vest(x, x0, x1, d):
        mid = (x0 + x1) / 2.0
        return None if abs(x - mid) < 1.5 else (leather_d if d else leather)

    mau = torso(load("enemy_boss"), boss_pants, vest)
    mau = gray_hair(recolor(mau, jean, head={(62, 53, 70): (140, 138, 136)}), (130, 128, 128))
    mau.save(OUT / "luchador_mauricio.png")
    mau2 = gray_hair(recolor(load("enemy_boss"), jean, head={(62, 53, 70): (140, 138, 136)}), (130, 128, 128))
    mau2.save(OUT / "luchador_mauricio2.png")

    # Alvarito (thug): pelo café, chaqueta de jean, pantalón negro.
    alv = recolor(load("enemy_thug"), {
        (22, 90, 76): (40, 38, 44),       # pelo y pantalón (la misma tinta en la hoja): oscuros
        (103, 102, 51): (62, 60, 70),
        (77, 101, 180): (100, 130, 180),  # la camisa → chaqueta de jean
        (111, 103, 95): (76, 100, 146),
    }, head={(30, 188, 115): (110, 80, 60), (79, 122, 68): (80, 58, 44), (22, 90, 76): (60, 44, 36)})
    alv.save(OUT / "luchador_alvarito.png")

    # El Pecas (punk): pelirrojo de verdad, camiseta naranja, jean.
    pec = recolor(load("enemy_punk"), {
        (110, 39, 39): (196, 96, 44), (179, 56, 49): (226, 128, 60),   # pelo
        (149, 140, 130): (230, 128, 64), (111, 103, 95): (190, 96, 48),  # camiseta
        (98, 85, 101): (160, 80, 40),
        (22, 90, 76): (66, 90, 140), (103, 102, 51): (46, 64, 104),      # jean
    })
    pec.save(OUT / "luchador_pecas.png")
    print("luchadores:", OUT)


if __name__ == "__main__":
    main()
