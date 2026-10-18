"""Los íconos de lo de Diana Carolina (scripts/systems/Carolina.gd): lo que le va llegando de ella.
  assets/items/nota_perdon.png      una hoja de cuaderno arrancada, doblada, con una sola palabra
  assets/items/recorte_4.png        el recorte chiquito de la página 9: "rectifica"
  assets/items/carta_carolina.png   el sobre, con la estampilla turquesa (su color) y su letra
Uso: python tools/art/draw_carolina.py  (desde la carpeta del proyecto)"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from draw_centro import make, ITEMS  # noqa: E402


def nota_perdon(d):
    d.polygon([(2, 3), (13, 2), (14, 13), (3, 14)], fill=(244, 242, 232, 255))   # la hoja, torcida
    for y in (5, 8, 11):                                                           # los renglones
        d.line([(3, y), (13, y - 1)], fill=(150, 180, 220, 255))
    d.line([(4, 3), (4, 13)], fill=(230, 140, 150, 255))                           # la margen roja
    for x in (2, 2, 3):                                                            # lo arrancado
        d.point((x, 6), fill=(0, 0, 0, 0))
    d.line([(6, 7), (7, 6), (8, 7), (9, 6), (11, 7)], fill=(40, 40, 70, 255))      # "Perdón."
    d.point((12, 7), fill=(40, 40, 70, 255))
    d.line([(8, 2), (8, 14)], fill=(214, 210, 196, 255))                           # el doblez


def recorte_4(d):
    d.polygon([(2, 4), (14, 3), (14, 13), (3, 14)], fill=(222, 216, 196, 255))
    d.rectangle([4, 5, 12, 6], fill=(60, 56, 60, 255))                             # el titular
    for y in (8, 10, 12):
        d.line([(4, y), (12, y)], fill=(150, 146, 140, 255))
    d.rectangle([9, 8, 12, 11], fill=(120, 116, 112, 255))                         # la foto, chiquita


def carta_carolina(d):
    d.rectangle([1, 4, 14, 13], fill=(246, 244, 238, 255))                         # el sobre
    d.line([(1, 4), (7, 9), (14, 4)], fill=(206, 202, 194, 255))
    d.rectangle([11, 5, 13, 7], fill=(60, 180, 180, 255))                          # la estampilla turquesa
    d.line([(3, 11), (8, 11)], fill=(30, 26, 30, 255))                             # su letra
    d.line([(3, 12), (6, 12)], fill=(30, 26, 30, 255))


if __name__ == "__main__":
    for name, fn in [("nota_perdon", nota_perdon), ("recorte_4", recorte_4), ("carta_carolina", carta_carolina)]:
        make(ITEMS / f"{name}.png", (16, 16), fn)
    print("carolina: 3 íconos")
