"""Botones táctiles para jugar desde el celular (versión web). Semitransparentes, con la letra adentro.
  touch_a.png  ACCIÓN (interact)     touch_b.png  ATRÁS (cancel)
  touch_i.png  INVENTARIO            touch_x.png  SOLTAR (drop)
  touch_l.png  LUKAS (sniff: su menú; una huellita)
  compania.png el ícono de la barra de compañía del HUD
  touch_stick_base.png, touch_stick_knob.png  la palanca de la izquierda
Salida: assets/ui/touch_*.png
Uso: python tools/art/draw_touch.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path("assets/ui")
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)
RIM = (250, 246, 236, 150)
FILL = (30, 26, 34, 110)


def button(name, size, letter, color):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, size - 1, size - 1], fill=FILL, outline=RIM)
    d.ellipse([2, 2, size - 3, size - 3], outline=color)
    w = d.textlength(letter, font=FONT)
    d.text(((size - w) / 2, (size - 8) / 2), letter, font=FONT, fill=(250, 246, 236, 220))
    img.save(OUT / f"touch_{name}.png")


def paw(name, size, color):
    """Botón de Lukas: una huellita en vez de letra."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, size - 1, size - 1], fill=FILL, outline=RIM)
    d.ellipse([2, 2, size - 3, size - 3], outline=color)
    ink = (250, 246, 236, 230)
    c = size // 2
    d.ellipse([c - 3, c, c + 3, c + 5], fill=ink)  # la almohadilla
    for x, y in ((c - 5, c - 2), (c - 2, c - 5), (c + 2, c - 5), (c + 5, c - 2)):  # los dedos
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=ink)
    img.save(OUT / f"touch_{name}.png")


def company_icon():
    """El ícono de la barra de compañía (HUD): dos cabecitas juntas. La de al lado es Lukas."""
    img = Image.new("RGBA", (14, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ink = (38, 28, 44, 255)
    d.ellipse([1, 1, 6, 6], fill=(214, 160, 122, 255), outline=ink)  # él
    d.rectangle([1, 7, 6, 11], fill=(96, 98, 108, 255), outline=ink)
    d.ellipse([7, 4, 12, 9], fill=(192, 118, 60, 255), outline=ink)  # Lukas
    d.line([(7, 5), (7, 9)], fill=(140, 80, 40, 255))
    d.point((11, 7), fill=ink)
    img.save("assets/ui/compania.png")


def stick():
    base = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    d.ellipse([0, 0, 47, 47], fill=(30, 26, 34, 80), outline=RIM)
    for pts in (((24, 3), (20, 8), (28, 8)), ((24, 44), (20, 39), (28, 39)),
                ((3, 24), (8, 20), (8, 28)), ((44, 24), (39, 20), (39, 28))):
        d.polygon(pts, fill=(250, 246, 236, 120))
    base.save(OUT / "touch_stick_base.png")
    knob = Image.new("RGBA", (20, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(knob)
    d.ellipse([0, 0, 19, 19], fill=(250, 246, 236, 120), outline=(250, 246, 236, 200))
    knob.save(OUT / "touch_stick_knob.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    button("a", 26, "A", (120, 200, 120, 200))
    button("b", 22, "B", (220, 110, 110, 200))
    button("i", 18, "I", (120, 160, 230, 200))
    button("x", 18, "X", (230, 200, 110, 200))
    paw("l", 22, (192, 118, 60, 220))
    stick()
    company_icon()
    print("botones táctiles:", OUT)
