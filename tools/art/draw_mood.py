"""Caritas del ánimo para el HUD (12x12): assets/ui/mood_0.png (muy mal) ... mood_3.png (bien).
Uso: python tools/art/draw_mood.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path("assets/ui")
OUT.mkdir(parents=True, exist_ok=True)
INK = (38, 28, 44, 255)
FACES = [(150, 150, 170, 255), (196, 170, 120, 255), (226, 196, 110, 255), (240, 214, 100, 255)]

for level in range(4):
    img = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, 11, 11], fill=FACES[level], outline=INK)
    d.point([(4, 4), (7, 4)], fill=INK)
    if level == 3:
        d.line([(3, 7), (4, 8), (7, 8), (8, 7)], fill=INK)
    elif level == 2:
        d.line([(4, 8), (7, 8)], fill=INK)
    else:
        d.line([(3, 9), (4, 8), (7, 8), (8, 9)], fill=INK)
        d.line([(3, 3), (5, 3)], fill=INK) if level == 0 else None
        d.line([(6, 3), (8, 3)], fill=INK) if level == 0 else None
    if level == 0:
        d.point([(8, 6), (8, 7)], fill=(120, 170, 230, 255))  # una lágrima
    img.save(OUT / f"mood_{level}.png")
print("listo")
