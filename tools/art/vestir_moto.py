"""Viste al protagonista en moto (de espaldas) y en la imagen de llegada como el de la ciudad: saco
gris en vez de camisa blanca; en moto la corbata roja vuela por encima del hombro, en la llegada (su
vida de antes) la lleva bien puesta. Parte de los originales en assets/moto/source/.
Uso: python tools/art/vestir_moto.py  (desde la carpeta del proyecto)"""
import shutil
from pathlib import Path
from PIL import Image

DIR = Path("assets/moto")
SRC = DIR / "source"
SHIRT, SHIRT_D = (232, 228, 220), (200, 196, 188)
SACO, SACO_D = (88, 92, 112), (60, 62, 80)
CAMISA = (214, 208, 192)
TIE, TIE_D = (206, 48, 52), (140, 30, 38)


def recolor(im):
    px = im.load()
    pts = []
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            if c[3] and c[:3] == SHIRT:
                px[x, y] = SACO + (255,)
                pts.append((x, y))
            elif c[3] and c[:3] == SHIRT_D:
                px[x, y] = SACO_D + (255,)
                pts.append((x, y))
    return px, pts


def bike(name, wind):
    im = Image.open(SRC / name).convert("RGBA")
    px, pts = recolor(im)
    if pts:
        top = min(y for _, y in pts)
        xs = [x for x, y in pts if y == top]
        cx = (min(xs) + max(xs)) // 2
        # La corbata, al viento: sale del cuello y se va por encima del hombro.
        for i, dy in enumerate([3, 3, 2, 2, 2, 1, 1, 2, 1]):
            x = cx + wind * (2 + i)
            y = top + dy
            if 0 <= x < im.width and 0 <= y < im.height:
                px[x, y] = (TIE if i % 3 else TIE_D) + (255,)
                if i < 6 and y + 1 < im.height:
                    px[x, y + 1] = TIE_D + (255,)  # dos de ancho cerca del cuello
    im.save(DIR / name)


def llegada():
    im = Image.open(SRC / "llegada.png").convert("RGBA")
    px, pts = recolor(im)
    rows = {}
    for x, y in pts:
        rows.setdefault(y, []).append(x)
    top = min(rows)
    bottom = max(rows)
    for y in range(top, bottom - 4):
        xs = rows.get(y, [])
        if not xs:
            continue
        mid = (min(xs) + max(xs)) // 2
        px[mid, y] = (TIE_D if (y - top) % 5 == 4 else TIE) + (255,)
        if y - top < 4:  # el cuello de la camisa
            for x in (mid - 1, mid + 1):
                if (x, y) in pts:
                    px[x, y] = CAMISA + (255,)
    im.save(DIR / "llegada.png")


def main():
    SRC.mkdir(parents=True, exist_ok=True)
    for name in ["bike_c.png", "bike_l.png", "bike_r.png", "llegada.png"]:
        if not (SRC / name).exists():
            shutil.copy(DIR / name, SRC / name)
    bike("bike_c.png", 1)
    bike("bike_l.png", 1)   # inclinado a la izquierda: la corbata se va a la derecha
    bike("bike_r.png", -1)
    llegada()
    print("vestido en moto y en la llegada")


if __name__ == "__main__":
    main()
