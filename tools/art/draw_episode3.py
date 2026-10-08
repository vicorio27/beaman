"""Arte del SUEÑO 6 (beat 'em up, episodio 3: Brenda).
  assets/prologue/brenda.png      Brenda (recoloreo de la hoja de Lilato: saco café, falda gris)
  assets/prologue/item_maleta.png la maleta que ella tira
  assets/prologue/ep3_bg.png      1280x180: la terminal → adentro del bus → Ibagué (ciudad musical) → la casa de ella
Uso: python tools/art/draw_episode3.py  (desde la carpeta del proyecto)"""
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path("assets/prologue")
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)
INK = (46, 34, 47)
random.seed(3)


def recolor(src, dst, mapping):
    im = Image.open(OUT / src).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in mapping:
                px[x, y] = mapping[(r, g, b)] + (a,)
    im.save(OUT / dst)


def jit(c, k=10):
    return tuple(max(0, min(255, v + random.randint(-k, k))) for v in c)


def maleta():
    img = Image.new("RGBA", (18, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 4, 16, 13], fill=(130, 80, 50, 255), outline=INK)
    d.rectangle([6, 1, 11, 4], outline=INK)
    d.line([(1, 8), (16, 8)], fill=(100, 60, 40, 255))
    d.rectangle([3, 5, 5, 7], fill=(220, 200, 120, 255))
    img.save(OUT / "item_maleta.png")


def bg():
    W, H = 1280, 180
    im = Image.new("RGB", (W, H), (30, 26, 34))
    d = ImageDraw.Draw(im)
    # --- La terminal (0..320): baldosas, taquillas, bancas, un reloj que no anda.
    d.rectangle([0, 0, 320, 118], fill=(150, 146, 136))
    for x in range(0, 320, 16):
        d.line([(x, 0), (x, 118)], fill=(136, 132, 124))
    for x0, name in [(20, "TAQUILLA 1"), (120, "TAQUILLA 2")]:
        d.rectangle([x0, 40, x0 + 86, 100], fill=(80, 90, 110))
        d.rectangle([x0 + 4, 44, x0 + 82, 56], fill=(30, 40, 90))
        d.text((x0 + 6, 46), name, font=FONT, fill=(240, 240, 250))
        d.rectangle([x0 + 10, 62, x0 + 76, 90], fill=(140, 180, 200))
    d.ellipse([250, 20, 290, 60], fill=(240, 236, 220), outline=(60, 60, 60))
    d.line([(270, 40), (270, 26)], fill=(40, 40, 40), width=2)
    d.line([(270, 40), (280, 44)], fill=(40, 40, 40), width=2)
    d.rectangle([220, 96, 310, 110], fill=(90, 70, 60))                 # banca
    # --- Adentro del bus (320..640): asientos y ventanas con el paisaje que pasa.
    d.rectangle([320, 0, 640, 118], fill=(110, 40, 40))
    for x in range(330, 640, 52):
        d.rectangle([x, 18, x + 40, 58], fill=(130, 190, 220))           # ventana
        d.polygon([(x, 58), (x + 14, 40), (x + 26, 50), (x + 40, 36), (x + 40, 58)], fill=(80, 140, 80))  # montañas
        d.rectangle([x + 4, 70, x + 36, 110], fill=(60, 80, 140))        # asiento
        d.rectangle([x + 6, 64, x + 34, 72], fill=(70, 92, 156))
    d.rectangle([320, 0, 640, 12], fill=(200, 200, 190))
    d.text((380, 2), "PROHIBIDO HABLAR CON EL CONDUCTOR", font=FONT, fill=(150, 40, 40))
    # --- Ibagué (640..1000): calle tibia, mangos, un letrero de la ciudad musical.
    d.rectangle([640, 0, 1000, 40], fill=(120, 170, 220))
    d.rectangle([640, 40, 1000, 118], fill=(232, 196, 120))
    for x in range(660, 1000, 90):
        d.rectangle([x, 60, x + 50, 118], fill=jit((200, 160, 110)))
        d.rectangle([x + 18, 80, x + 32, 118], fill=(120, 80, 60))
        d.rectangle([x + 4, 66, x + 14, 76], fill=(250, 230, 160))
    d.rectangle([700, 24, 900, 40], fill=(40, 90, 60))
    d.text((708, 28), "IBAGUE, CIUDAD MUSICAL", font=FONT, fill=(250, 240, 200))
    for x in (660, 820, 980):  # palos de mango
        d.rectangle([x, 70, x + 6, 118], fill=(110, 80, 50))
        d.ellipse([x - 22, 34, x + 28, 80], fill=(60, 130, 60))
        for k in range(3):
            d.ellipse([x - 10 + k * 12, 56, x - 4 + k * 12, 62], fill=(250, 180, 60))
    # --- La casa de ella (1000..1280): una reja, una puerta entreabierta, una mata de sábila.
    d.rectangle([1000, 0, 1280, 40], fill=(120, 170, 220))
    d.rectangle([1000, 40, 1280, 118], fill=(214, 186, 170))
    d.polygon([(1000, 40), (1140, 10), (1280, 40)], fill=(160, 80, 60))
    d.rectangle([1120, 62, 1160, 118], fill=(90, 60, 50))
    d.rectangle([1122, 64, 1140, 118], fill=(250, 220, 160))            # entreabierta, con luz
    d.rectangle([1040, 70, 1076, 96], fill=(250, 230, 170))
    d.rectangle([1190, 70, 1226, 96], fill=(250, 230, 170))
    for x in range(1010, 1280, 8):
        d.line([(x, 92), (x, 118)], fill=(60, 60, 70))                    # reja
    d.line([(1010, 94), (1280, 94)], fill=(60, 60, 70))
    d.rectangle([1086, 104, 1100, 118], fill=(180, 90, 60)); d.polygon([(1093, 90), (1088, 104), (1098, 104)], fill=(90, 150, 90))
    # Piso de todo: andén y calle (igual que los otros episodios).
    d.rectangle([0, 118, 1280, 142], fill=(110, 104, 96))
    for x in range(0, 1280, 16):
        d.line([(x, 118), (x, 142)], fill=(96, 90, 84))
    d.rectangle([320, 118, 640, 180], fill=(70, 70, 76))                # el pasillo del bus
    d.rectangle([0, 142, 320, 180], fill=(150, 146, 136))
    d.rectangle([640, 142, 1280, 180], fill=(60, 56, 62))
    for x in range(660, 1280, 60):
        d.rectangle([x, 160, x + 24, 162], fill=(200, 180, 90))
    im.save(OUT / "ep3_bg.png")


if __name__ == "__main__":
    recolor("lilato.png", "brenda.png", {(168, 132, 243): (150, 110, 80), (144, 94, 169): (120, 86, 60),
                                         (107, 62, 117): (96, 66, 46), (195, 36, 84): (170, 90, 90)})
    maleta()
    bg()
    print("listo")
