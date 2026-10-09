"""El cuadro de diálogo estilo Hades: papel claro con marco dorado, y la placa oscura del nombre.
Se estiran como 9-slice (NinePatchRect, márgenes de 6 px).
  dlg_box.png    el cuadro del texto (papel, marco dorado, esquinas con rombo)
  dlg_plate.png  la placa del nombre (oscura, marco dorado, línea roja abajo)
  dlg_more.png   la flechita de "hay más"
Salida: assets/ui/dlg_*.png
Uso: python tools/art/draw_dialogo.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path("assets/ui")
DARK = (40, 26, 22, 255)
GOLD = (222, 178, 84, 255)
GOLD_SH = (146, 104, 44, 255)
PAPER = (240, 230, 206, 255)
PAPER_SH = (220, 204, 172, 255)


def box():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 31, 31], fill=DARK)
    d.rectangle([1, 1, 30, 30], fill=GOLD)
    d.rectangle([2, 2, 29, 29], fill=GOLD_SH)
    d.rectangle([3, 3, 28, 28], fill=PAPER)
    d.rectangle([4, 4, 27, 27], outline=PAPER_SH)
    for x, y in ((2, 2), (29, 2), (2, 29), (29, 29)):  # rombos en las esquinas
        d.polygon([(x, y - 2), (x + 2, y), (x, y + 2), (x - 2, y)], fill=GOLD)
        d.point((x, y), fill=(255, 236, 170, 255))
    im.save(OUT / "dlg_box.png")


def plate():
    im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 23, 23], fill=DARK)
    d.rectangle([1, 1, 22, 22], fill=GOLD)
    d.rectangle([2, 2, 21, 21], fill=(52, 34, 36, 255))
    d.line([(3, 20), (20, 20)], fill=(150, 40, 44, 255))
    im.save(OUT / "dlg_plate.png")


def more():
    im = Image.new("RGBA", (7, 5), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(0, 0), (6, 0), (3, 4)], fill=GOLD_SH)
    d.line([(1, 0), (5, 0)], fill=GOLD)
    im.save(OUT / "dlg_more.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    box()
    plate()
    more()
    print("cuadro de diálogo:", OUT)
