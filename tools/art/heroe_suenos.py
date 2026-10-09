"""El protagonista de los sueños de pelea, como él se sueña: el mismo de la ciudad (canas, barba, saco
gris, corbata roja, jean), pero idealizado: más alto, más ancho de hombros, y el saco sin mangas para
que se vean los brazos. La cabeza queda del mismo tamaño (el cuerpo crece, la cabeza no: más heroico).

Parte de los originales (assets/prologue/source/orig_*.png), los viste con vestir_protagonista.dress
(sin mangas) y después:
  - colores: piel, pelo oscuro con canas en las sienes, barba, ojos oscuros (sin el azul), jean;
  - cuerpo: 2 filas más de pecho, 2 de piernas, 2 columnas más de hombros (repitiendo píxeles de
    adentro, así el contorno no se engorda); los pies quedan donde estaban;
  - músculos: sombra en el borde de abajo y de atrás de los brazos.
Uso: python tools/art/heroe_suenos.py  (desde la carpeta del proyecto)"""
import sys
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from vestir_protagonista import dress, SHEETS, SRC, DIR  # noqa: E402

OUTLINE = (46, 34, 47)
RECOLOR = {
    (50, 51, 83): (40, 38, 46),        # pelo
    (252, 167, 144): (214, 150, 120),  # piel
    (237, 128, 153): (172, 110, 90),   # piel en sombra
    (77, 155, 230): (28, 26, 34),      # ojos
    (77, 101, 180): (66, 92, 146),     # jean
    (234, 173, 237): (236, 186, 156),  # piel del cuadro de golpe (más clara)
    (48, 225, 185): (28, 26, 34),      # ojos del cuadro de golpe
}
SKIN, SKIN_D = (214, 150, 120), (172, 110, 90)
HAIR, CANAS = (40, 38, 46), (116, 114, 118)
BEARD = (70, 62, 60)
EYE = (28, 26, 34)
TIES = {(206, 48, 52), (140, 30, 38)}


def _expand(n: int, anchor: int, dups: set, forward: bool) -> list:
    """Índices de origen para un eje que crece repitiendo `dups`, con `anchor` fijo.
    forward=False: crece hacia atrás (filas: los pies quedan, la cabeza sube)."""
    out = {}
    step = 1 if forward else -1
    src, dst = anchor, anchor
    while 0 <= dst < n and 0 <= src < n:
        out[dst] = src
        dst += step
        if src in dups and dst < n and dst >= 0:
            out[dst] = src
            dst += step
        src += step
    return out


def heroize(im: Image.Image, cw: int) -> Image.Image:
    im = im.convert("RGBA")
    ch = 48 if cw == 48 else im.height
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    for cx in range(0, im.width, cw):
        for cy in range(0, im.height, ch):
            cell = im.crop((cx, cy, cx + cw, cy + ch))
            out.paste(_hero_cell(cell, grow=(cw == 48)), (cx, cy))
    return out


def _hero_cell(cell: Image.Image, grow: bool) -> Image.Image:
    w, h = cell.size
    px = cell.load()
    pts = [(x, y) for x in range(w) for y in range(h) if px[x, y][3] > 0]
    if not pts:
        return cell
    whites = [p for p in pts if px[p][:3] == (255, 255, 255)]
    if len(whites) > 0.5 * len(pts):
        return _flash_cell(cell, grow)  # el destello blanco del golpe: solo la forma
    top = min(y for _, y in pts)
    bottom = max(y for _, y in pts)
    eyes = [y for x, y in pts if px[x, y][:3] == (77, 155, 230)]
    eye_y = min(eyes) if eyes else top + 8
    neck = eye_y + 4
    # Colores, barba y canas.
    for x, y in pts:
        c = px[x, y][:3]
        if c == (255, 255, 255) and y <= neck:
            c = SKIN  # el blanco del ojo: la mirada queda seria
        if c == (77, 101, 180) and y < neck:
            c = EYE  # el iris (el mismo azul que el jean)
        c = RECOLOR.get(c, c)
        if y < neck and y >= eye_y + 2 and c in (SKIN, SKIN_D, (236, 186, 156)):
            c = BEARD
        px[x, y] = c + (255,)
    for x, y in pts:  # canas: el pelo que toca la cara
        if px[x, y][:3] == HAIR and y < neck:
            if any(0 <= x + dx < w and px[x + dx, y][:3] in (SKIN, BEARD) for dx in (-1, 1)):
                px[x, y] = CANAS + (255,)
    if not grow:
        return cell
    # Más grande: filas (pecho y muslos) y columnas (hombros), solo del cuello para abajo.
    tall = bottom - top >= 22
    row_dups = {neck + 2, neck + 4} | ({bottom - 4, bottom - 5} if tall else set())
    rows = _expand(h, bottom, row_dups, forward=False)
    ties = [x for x, y in pts if px[x, y][:3] in TIES and y > neck]
    body = [x for x, y in pts if y > neck]
    mid = sorted(ties)[len(ties) // 2] if ties else (min(body) + max(body)) // 2 if body else w // 2
    left = _expand(w, mid, {mid - 2}, forward=False)
    right = _expand(w, mid, {mid + 2}, forward=True)
    cols = {**left, **right}
    new = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    npx = new.load()
    for y in range(h):
        if y not in rows:
            continue
        sy = rows[y]
        for x in range(w):
            sx = cols.get(x) if sy > neck else x
            if sx is not None:
                npx[x, y] = px[sx, sy]
    # Músculos: sombra abajo y atrás de cada brazo (la piel del cuello para abajo que toca el borde).
    head_bottom = max(y for y in rows if rows[y] <= neck) if any(rows[y] <= neck for y in rows) else 0
    for y in range(head_bottom + 1, h - 1):
        for x in range(1, w - 1):
            if npx[x, y][:3] == SKIN and npx[x, y][3] > 0:
                below = npx[x, y + 1]
                if below[3] == 0 or below[:3] == OUTLINE:
                    npx[x, y] = SKIN_D + (255,)
    return new


def _flash_cell(cell: Image.Image, grow: bool) -> Image.Image:
    """El cuadro blanco del golpe: crece igual que el resto para que no salte de tamaño."""
    if not grow:
        return cell
    w, h = cell.size
    px = cell.load()
    pts = [(x, y) for x in range(w) for y in range(h) if px[x, y][3] > 0]
    top, bottom = min(y for _, y in pts), max(y for _, y in pts)
    neck = top + 12
    rows = _expand(h, bottom, {neck + 2, neck + 4, bottom - 4, bottom - 5}, forward=False)
    xs = [x for x, y in pts if y > neck]
    mid = (min(xs) + max(xs)) // 2
    cols = {**_expand(w, mid, {mid - 2}, False), **_expand(w, mid, {mid + 2}, True)}
    new = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    npx = new.load()
    for y, sy in rows.items():
        for x in range(w):
            sx = cols.get(x) if sy > neck else x
            if sx is not None:
                npx[x, y] = px[sx, sy]
    return new


def avatar():
    """La carita del marcador (11x11): mismos colores, con barba."""
    im = Image.open(SRC / "avatar_player.png").convert("RGBA")
    px = im.load()
    eyes = [y for x in range(im.width) for y in range(im.height) if px[x, y][3] and px[x, y][:3] == (77, 155, 230)]
    eye_y = min(eyes) if eyes else 5
    for x in range(im.width):
        for y in range(im.height):
            if px[x, y][3] == 0:
                continue
            c = px[x, y][:3]
            if c == (255, 255, 255):
                c = SKIN
            if c == (77, 101, 180):
                c = EYE
            c = RECOLOR.get(c, c)
            if y >= eye_y + 2 and c in (SKIN, SKIN_D):
                c = BEARD
            px[x, y] = c + (255,)
    im.save(DIR / "avatar_player.png")


def main():
    for name, cw in SHEETS.items():
        if name == "player_hang.png":
            continue  # el colgado del camión se dibuja aparte (draw_colgado.py)
        heroize(dress(Image.open(SRC / ("orig_" + name)), cw, sleeves=False), cw).save(DIR / name)
        print("héroe:", name)
    avatar()


if __name__ == "__main__":
    main()
