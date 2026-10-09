"""Viste al protagonista de los sueños de pelea (hojas de costado, celdas de 48x48) como el de la
ciudad (versión A): la camiseta blanca pasa a ser saco gris con la camisa y la corbata roja al
centro; los brazos, mangas del saco (los puños quedan); un mechón parado arriba de la cabeza.
Parte siempre de los originales (assets/prologue/source/orig_*.png), así se puede correr de nuevo.
Uso: python tools/art/vestir_protagonista.py  (desde la carpeta del proyecto)"""
import shutil
from pathlib import Path
from PIL import Image

DIR = Path("assets/prologue")
SRC = DIR / "source"
SHEETS = {"player.png": 48, "player_bottle.png": 48, "player_pipe.png": 48, "player_knife.png": 48,
          "player_superknife.png": 48, "player_hang.png": 32}

WHITE = {(255, 255, 255), (199, 220, 208)}
SKIN = {(252, 167, 144), (237, 128, 153)}
OUTLINE = (46, 34, 47)
HAIR = (50, 51, 83)
SACO, SACO_D = (88, 92, 112), (60, 62, 80)
CAMISA = (214, 208, 192)
TIE, TIE_D = (206, 48, 52), (140, 30, 38)


def _components(points: set) -> list:
    """Manchas conectadas (4 vecinos)."""
    comps, left = [], set(points)
    while left:
        stack = [left.pop()]
        comp = set(stack)
        while stack:
            x, y = stack.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in left:
                    left.discard(n)
                    comp.add(n)
                    stack.append(n)
        comps.append(comp)
    return comps


def dress(im: Image.Image, cw: int, sleeves: bool = True) -> Image.Image:
    """sleeves=False: el saco queda sin mangas (los brazos al aire; ver heroe_suenos.py)."""
    im = im.convert("RGBA")
    px = im.load()
    ch = 48 if cw == 48 else im.height
    for cx in range(0, im.width, cw):
        for cy in range(0, im.height, ch):
            cell = [(x, y) for x in range(cx, min(cx + cw, im.width)) for y in range(cy, min(cy + ch, im.height))
                    if px[x, y][3] > 0]
            if not cell:
                continue
            whites = {(x, y) for x, y in cell if px[x, y][:3] in WHITE}
            if not whites or len(whites) > 0.5 * len(cell):
                continue  # vacío, o el destello blanco del golpe
            shirt = max(_components(whites), key=len)
            if len(shirt) < 6:
                continue
            shirt_top = min(y for _, y in shirt)
            scx = sum(x for x, _ in shirt) / len(shirt)
            scy = sum(y for _, y in shirt) / len(shirt)
            # La camiseta: saco a los lados, camisa al lado de la corbata, corbata al centro de cada fila.
            rows = {}
            for x, y in shirt:
                rows.setdefault(y, []).append(x)
            for y, xs in rows.items():
                x0, x1 = min(xs), max(xs)
                mid = (x0 + x1 + 1) // 2
                for x in xs:
                    if x == mid:
                        c = TIE_D if (y - shirt_top) % 4 == 3 else TIE
                    elif abs(x - mid) == 1 and y - shirt_top < 4:
                        c = CAMISA
                    else:
                        c = SACO_D if x <= x0 + 1 else SACO
                    px[x, y] = c + (255,)
            # La corbata cuelga un poco más abajo que la camiseta (floja).
            y_last = max(rows)
            mid_last = (min(rows[y_last]) + max(rows[y_last]) + 1) // 2
            if y_last + 1 < cy + ch and px[mid_last, y_last + 1][3] > 0:
                px[mid_last, y_last + 1] = TIE_D + (255,)
            # Los brazos: mangas del saco. De cada brazo queda de piel solo el puño (lo más lejos del cuerpo).
            skin = {(x, y) for x, y in cell if y >= shirt_top and px[x, y][:3] in SKIN} if sleeves else set()
            for arm in _components(skin):
                far = max(((x - scx) ** 2 + (y - scy) ** 2) ** 0.5 for x, y in arm)
                for x, y in arm:
                    if ((x - scx) ** 2 + (y - scy) ** 2) ** 0.5 < far - 2.2:
                        px[x, y] = (SACO_D if px[x, y][:3] == (237, 128, 153) else SACO) + (255,)
            # El mechón: dos píxeles parados arriba de la cabeza.
            top = min(y for _, y in cell)
            xs_top = [x for x, y in cell if y == top]
            xm = (min(xs_top) + max(xs_top)) // 2 + 1
            for (dx, dy, c) in [(0, -1, HAIR), (1, -1, OUTLINE), (1, -2, OUTLINE), (-1, -1, OUTLINE), (0, -2, OUTLINE)]:
                x, y = xm + dx, top + dy
                if cy <= y < cy + ch and px[x, y][3] == 0:
                    px[x, y] = c + (255,)
    return im


def main():
    SRC.mkdir(parents=True, exist_ok=True)
    for name, cw in SHEETS.items():
        orig = SRC / ("orig_" + name)
        if not orig.exists():
            shutil.copy(DIR / name, orig)
        dress(Image.open(orig), cw).save(DIR / name)
        print("vestido:", name)


if __name__ == "__main__":
    main()
