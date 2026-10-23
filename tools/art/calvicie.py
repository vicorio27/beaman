"""Él se va quedando calvo con los días (python tools/art/calvicie.py, desde la carpeta del proyecto).

Toma cada hoja de él ya dibujada (con pelo) y saca tres versiones más, <nombre>_c1/_c2/_c3.png:
    c1  las entradas: el pelo de arriba se ralea
    c2  la coronilla: arriba ya no hay; quedan los lados y atrás
    c3  calvo: la cabeza pelada (con su brillito), una franja a los lados y atrás

Cómo: busca el color de su pelo (y las canas); cada mancha de pelo conectada es una cabeza (sirve para
cualquier hoja, de cualquier tamaño de celda, y para las poses de lado o acostado). En cada cabeza pela
desde arriba (las filas de arriba de la mancha) y deja los píxeles de las puntas de cada fila (los lados).
Lo que se pela queda del color de la piel de esa cabeza (el que más hay justo debajo del pelo).
La barba no se toca (es de otro color).

El juego escoge cuál según el día: scripts/systems/Calvicie.gd (días 1-12 pelo, 13-25 c1, 26-38 c2, 39-50 c3).
Correr después de regenerar cualquiera de las hojas de la lista (HOJAS).
"""
import os
import sys

import numpy as np
from PIL import Image

HAIR = [(40, 38, 46), (116, 114, 118)]  # su pelo y sus canas (draw_protagonist_adult.py, heroe_suenos.py)
HOJAS = [
    "assets/characters/protagonist_adult.png",
    "assets/characters/protagonist_acciones.png",
    "assets/feria/rueda_cabina.png",
    "assets/feria/chocon_rojo.png",
    "assets/feria/vagon_adelante.png",
    "assets/feria/vagon_adelante_manos.png",
]


def blobs(mask):
    """Las manchas conectadas (8 vecinos) de la máscara: lista de listas de (y, x)."""
    seen = np.zeros_like(mask)
    out = []
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):
        if seen[y0, x0]:
            continue
        stack, blob = [(y0, x0)], []
        seen[y0, x0] = True
        while stack:
            y, x = stack.pop()
            blob.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < mask.shape[0] and 0 <= xx < mask.shape[1] and mask[yy, xx] and not seen[yy, xx]:
                        seen[yy, xx] = True
                        stack.append((yy, xx))
        out.append(blob)
    return out


def skin_of(a, blob, hair_mask):
    """La piel de esa cabeza: el color que más hay justo debajo del pelo (sin contornos ni pelo)."""
    count = {}
    for y, x in blob:
        for dy in (1, 2):
            yy = y + dy
            if yy >= a.shape[0] or hair_mask[yy, x] or a[yy, x, 3] == 0:
                continue
            c = tuple(int(v) for v in a[yy, x, :3])
            if sum(c) < 230:  # contorno o sombra muy oscura
                continue
            count[c] = count.get(c, 0) + 1
    return max(count, key=count.get) if count else None


# Él en el tenis (draw_tenistas.py, "el"): otro tono de pelo.
TENIS = ["assets/tenis/el.png"] + ["assets/tenis/el_%s.png" % k for k in (
    "bublikov", "fedorer", "kyrgistan", "monfiz", "moutette", "pecador", "sabalenkova", "sheltron", "tiafuego", "yokovich")]
HAIR_TENIS = [(72, 66, 74), (150, 148, 152)]


def calvo(a, stage, hair_cols=None):
    a = a.copy()
    rgb = a[..., :3]
    hair = np.zeros(a.shape[:2], bool)
    for c in hair_cols or HAIR:
        hair |= (rgb[..., 0] == c[0]) & (rgb[..., 1] == c[1]) & (rgb[..., 2] == c[2]) & (a[..., 3] > 0)
    for blob in blobs(hair):
        if len(blob) < 3:
            continue
        skin = skin_of(a, blob, hair)
        if skin is None:
            continue
        ys = [p[0] for p in blob]
        y0, y1 = min(ys), max(ys)
        k = y1 - y0 + 1
        rows = {}
        for y, x in blob:
            rows.setdefault(y, []).append(x)
        # Hasta qué fila (desde arriba) se pela, y si se dejan los lados.
        depth = {1: 1, 2: max(2, k // 3 + 1), 3: max(3, (k * 3) // 5 + 1)}[stage]
        for y, xs in rows.items():
            r = y - y0
            if r >= depth:
                continue
            lo, hi = min(xs), max(xs)
            for x in xs:
                side = (x == lo or x == hi) and r >= 1 and len(xs) > 2
                if stage == 1:
                    # Las entradas: la fila de arriba se ralea (uno sí, uno no), las puntas se van.
                    if r == 0 and (x in (lo, hi) or (x + y) % 2 == 0):
                        a[y, x, :3] = skin
                    continue
                if side:
                    continue
                a[y, x, :3] = skin
        if stage >= 2:  # el brillito de la calva
            top = sorted(rows[y0])
            bx = top[len(top) // 2]
            a[y0, bx, :3] = tuple(min(255, int(v * 1.18) + 12) for v in skin)
    return a


# ---------------------------------------------------------------- el de los sueños (heroe_suenos.py)
# Ahí el pelo es una cresta del mismo color del contorno: no se puede buscar por color. Se busca la cara
# (la piel más alta de cada figura) y lo oscuro de encima es pelo: se recorta y queda una cabeza redonda.
HEROE = [
    "assets/prologue/player.png",
    "assets/prologue/player_hang.png",
    "assets/prologue/player_knife.png",
    "assets/prologue/player_superknife.png",
    "assets/prologue/player_pipe.png",
    "assets/prologue/player_bottle.png",
]
SKINS = {(214, 150, 120), (172, 110, 90), (236, 186, 156)}


def heroe(a, stage):
    a = a.copy()
    alpha = a[..., 3] > 0
    for comp in blobs(alpha):
        if len(comp) < 80:
            continue
        skin = [(y, x) for y, x in comp if tuple(int(v) for v in a[y, x, :3]) in SKINS]
        if not skin:
            continue
        ys = min(y for y, _ in skin)
        face = [x for y, x in skin if y <= ys + 3]
        fx0, fx1 = min(face) - 3, max(face) + 3
        dark = [(y, x) for y, x in comp if y < ys and fx0 <= x <= fx1 and int(a[y, x, :3].astype(int).sum()) < 200]
        if not dark:
            continue
        h0 = ys - min(y for y, _ in dark)
        keep = {1: max(3, h0 - 2), 2: 3, 3: 2}[stage]   # cuántas filas de cabeza quedan encima de la cara
        top = ys - keep
        outline = tuple(int(v) for v in a[dark[0][0], dark[0][1], :3])
        skin_c = (214, 150, 120)
        rows = {}
        for y, x in dark:
            if y < top:
                a[y, x, 3] = 0  # la cresta: se va
            else:
                rows.setdefault(y, []).append(x)
        if stage == 1:
            continue
        for y, xs in rows.items():
            lo, hi = min(xs), max(xs)
            for x in xs:
                if y == top:
                    if x in (lo, hi):
                        a[y, x, 3] = 0  # las esquinas: redonda
                    else:
                        a[y, x, :3] = outline
                elif x in (lo, hi):
                    a[y, x, :3] = outline
                elif stage == 2 and y == ys - 1 and x in (lo + 1, hi - 1):
                    continue  # la franja de pelo a los lados
                else:
                    a[y, x, :3] = skin_c
        if stage >= 2 and top + 1 in rows:  # el brillito
            xs = sorted(rows[top + 1])
            a[top + 1, xs[len(xs) // 2], :3] = (240, 190, 160)
    return a


def main():
    names = sys.argv[1:] or HOJAS + HEROE + TENIS
    for path in names:
        if not os.path.exists(path):
            print("no está", path)
            continue
        a = np.asarray(Image.open(path).convert("RGBA"))
        base, ext = os.path.splitext(path)
        for stage in (1, 2, 3):
            if path in HEROE:
                out = heroe(a, stage)
            else:
                out = calvo(a, stage, HAIR_TENIS if path in TENIS else None)
            Image.fromarray(out).save("%s_c%d%s" % (base, stage, ext))
        print("ok", path)


if __name__ == "__main__":
    main()
