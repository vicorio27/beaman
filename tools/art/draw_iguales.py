"""EXPERIMENTO "todos iguales": como los ve él. Un solo dibujo para todos los demás: el mismo cuerpo
que el suyo, pero sin cara, sin color, sin corbata, sin mechón, sin morral. Intercambiables.
Salida: assets/characters/iguales.png (celdas de 16x26, misma distribución que protagonist_adult.png:
filas quieto / paso 1 / paso 2, columnas costado (a la izquierda) / frente / espalda).
Uso: python tools/art/draw_iguales.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image
import draw_protagonist_adult as P

OUT = Path("assets/characters/iguales.png")

# Todo a un gris tibio. La cara, lisa.
SWAP = {"h": "g", "H": "g", "s": "f", "S": "F", "e": "f", "n": "f", "b": "f",
        "w": "p", "W": "P", "z": "p", "Z": "P", "y": "p", "Y": "P", "m": "p", "M": "P",
        "j": "q", "J": "Q", "k": "Q", "x": "Q"}
P.PAL.update({
    "g": (96, 92, 96),
    "f": (190, 176, 168), "F": (156, 142, 136),
    "p": (150, 146, 140), "P": (114, 110, 106),
    "q": (104, 102, 108), "Q": (76, 74, 80),
})


def plain(rows):
    out = ["".join(SWAP.get(c, c) for c in r) for r in rows]
    # Sin mechón: las filas de arriba de la cabeza, vacías.
    return ["............"] + out[1:] if out[0].strip(".") and "oo" in out[0] and out[0].count("o") <= 2 else out


# Cabezas lisas: pelo corto igual para todos, sin cara.
HEAD_FRONT = ["............", "............", "....oooo....", "...oggggo...", "...offffo...",
              "...offffo...", "...oFffFo...", "....offo...."]
HEAD_BACK = ["............", "............", "....oooo....", "...oggggo...", "...oggggo...",
             "...oggggo...", "...oFggFo...", "....oFFo...."]
HEAD_SIDE = ["............", "............", "...oooo.....", "..oggggo....", ".ogggfffo...",
             ".oggffffo...", "..ogfffo....", "...offo....."]


def main():
    hf, hb, hs = HEAD_FRONT, HEAD_BACK, HEAD_SIDE
    bf, bb, bs = plain(P.BODY_FRONT), plain(P.BODY_BACK), plain(P.BODY_SIDE)
    still = plain(P.legs_front(0, 0))
    a, b = plain(P.legs_front(1, 0)), plain(P.legs_front(0, 1))
    ls, lst = plain(P.LEGS_SIDE_IDLE), plain(P.LEGS_SIDE_STEP)
    cells = {
        (0, 0): P.frame(hs, bs, ls, flip=True), (0, 1): P.frame(hs, bs, lst, flip=True, dy=-1), (0, 2): P.frame(hs, bs, ls, flip=True),
        (1, 0): P.frame(hf, bf, still), (1, 1): P.frame(hf, bf, a, dy=-1), (1, 2): P.frame(hf, bf, b, dy=-1),
        (2, 0): P.frame(hb, bb, still), (2, 1): P.frame(hb, bb, a, dy=-1), (2, 2): P.frame(hb, bb, b, dy=-1),
    }
    sheet = Image.new("RGBA", (3 * P.CW, 3 * P.CH), (0, 0, 0, 0))
    for (c, r), im in cells.items():
        sheet.alpha_composite(im, (c * P.CW, r * P.CH))
    sheet.save(OUT)
    print("todos iguales:", OUT, sheet.size)


if __name__ == "__main__":
    main()
