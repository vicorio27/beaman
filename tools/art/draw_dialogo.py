"""Lo dibujado del cuadro de diálogo (el resto lo arma Dialogue.gd: cuadro negro estilo Dredge).
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


def more():
    im = Image.new("RGBA", (7, 5), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(0, 0), (6, 0), (3, 4)], fill=GOLD_SH)
    d.line([(1, 0), (5, 0)], fill=GOLD)
    im.save(OUT / "dlg_more.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    more()
    print("cuadro de diálogo:", OUT)
