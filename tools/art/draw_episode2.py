"""Arte del SUEÑO 3 (beat 'em up, episodio 2): los jefes y el fondo.
  assets/prologue/camila.png     Camila (recoloreo de la hoja de Lilato: vestido dorado)
  assets/prologue/guillermo.png  Guillermo (recoloreo del jefe del episodio 1: camiseta de fútbol, jean)
  assets/prologue/ep2_bg.png     1280x180: la madriguera de la serpiente → la calle de los traidores
                                 (compraventa con las cosas de Guillermo, el bar, el grafiti C+G) → la
                                 terminal de buses con un letrero a Ibagué (lo que viene).
Uso: python tools/art/draw_episode2.py  (desde la carpeta del proyecto)"""
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path("assets/prologue")
FONT = ImageFont.truetype("assets/fonts/PressStart2P.ttf", 8)
INK = (46, 34, 47)
random.seed(2)


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


def bg():
    W, H = 1280, 180
    im = Image.new("RGB", (W, H), (20, 16, 26))
    d = ImageDraw.Draw(im)
    # --- La madriguera (0..360): túnel de alcantarilla, verde y húmedo.
    for y in range(0, 120, 6):
        for x in range(0, 360, 12):
            off = 6 if (y // 6) % 2 else 0
            d.rectangle([x + off, y, x + off + 10, y + 4], fill=jit((52, 70, 58)))
    d.ellipse([-80, -60, 440, 150], outline=(30, 40, 34), width=6)   # bóveda
    for x in range(20, 340, 37):  # gotas
        d.line([(x, 20 + x % 30), (x, 26 + x % 30)], fill=(120, 170, 140))
    d.rectangle([0, 118, 360, 142], fill=(60, 72, 62))                 # pasarela
    d.rectangle([0, 142, 360, 180], fill=(34, 46, 42))                 # agua sucia
    for k in range(10):  # la piel de la serpiente, mudada en el piso
        x = 40 + k * 26
        d.ellipse([x, 128 + (k % 2) * 3, x + 26, 140 + (k % 2) * 3], fill=(120, 80, 140), outline=(80, 50, 96))
    d.rectangle([330, 20, 360, 118], fill=(200, 190, 140))             # luz de una escalera hacia arriba
    for y in range(24, 118, 8):
        d.line([(334, y), (356, y)], fill=(110, 100, 80))
    # --- La calle de los traidores (360..1100).
    d.rectangle([360, 0, 1100, 40], fill=(24, 18, 30))                 # cielo
    d.rectangle([360, 40, 1100, 118], fill=(150, 104, 110))           # estuco rosado sucio
    for _ in range(400):
        x, y = random.randrange(360, 1100), random.randrange(40, 118)
        d.point((x, y), fill=jit((130, 90, 96)))
    # Compraventa: en la vitrina, las cosas de Guillermo (guitarra, tele, una foto de los amigos).
    d.rectangle([420, 50, 580, 118], fill=(70, 56, 60))
    d.rectangle([424, 54, 576, 66], fill=(230, 200, 70))
    d.text((430, 56), "COMPRAVENTA", font=FONT, fill=(60, 30, 30))
    d.rectangle([430, 72, 570, 112], fill=(110, 150, 170))
    d.ellipse([440, 80, 460, 104], fill=(150, 90, 50)); d.rectangle([448, 74, 452, 84], fill=(150, 90, 50))  # guitarra
    d.rectangle([476, 82, 504, 104], fill=(40, 40, 46)); d.rectangle([480, 86, 500, 100], fill=(90, 120, 140))  # tele
    d.rectangle([520, 84, 548, 104], fill=(230, 220, 200)); d.rectangle([523, 87, 545, 101], fill=(150, 130, 110))  # la foto
    for k in range(4):
        d.ellipse([525 + k * 5, 90, 529 + k * 5, 94], fill=(80, 60, 50))
    d.text((524, 106), "$", font=FONT, fill=(200, 40, 40))
    # Bar.
    d.rectangle([640, 50, 780, 118], fill=(50, 30, 40))
    d.rectangle([646, 54, 774, 66], fill=(30, 20, 30))
    d.text((652, 56), "EL PARCHE", font=FONT, fill=(255, 90, 160))
    d.rectangle([690, 74, 730, 118], fill=(100, 60, 50))
    d.rectangle([650, 74, 682, 100], fill=(250, 200, 120)); d.rectangle([738, 74, 770, 100], fill=(250, 200, 120))
    # El grafiti: C + G con un corazón (y una tachadura encima).
    d.text((820, 70), "C+G", font=FONT, fill=(240, 80, 140))
    d.polygon([(870, 72), (876, 66), (882, 72), (876, 80)], fill=(240, 80, 140))
    d.line([(816, 86), (888, 64)], fill=(30, 30, 30), width=2)
    # Cortinas metálicas cerradas.
    for x0 in (920, 1010):
        d.rectangle([x0, 60, x0 + 70, 118], fill=(110, 116, 126))
        for y in range(62, 118, 5):
            d.line([(x0, y), (x0 + 70, y)], fill=(90, 96, 104))
    # --- La terminal (1100..1280): un bus y el letrero a Ibagué.
    d.rectangle([1100, 30, 1280, 118], fill=(90, 96, 110))
    d.rectangle([1104, 34, 1276, 46], fill=(30, 40, 90))
    d.text((1130, 36), "TERMINAL", font=FONT, fill=(240, 240, 250))
    d.rectangle([1130, 58, 1250, 116], fill=(200, 60, 50))               # el bus de frente
    d.rectangle([1138, 64, 1242, 90], fill=(120, 170, 200))
    d.rectangle([1150, 96, 1230, 104], fill=(30, 30, 30))
    d.text((1158, 96), "IBAGUE", font=FONT, fill=(250, 220, 90))
    d.ellipse([1136, 104, 1148, 116], fill=(250, 240, 180)); d.ellipse([1232, 104, 1244, 116], fill=(250, 240, 180))
    # Faroles y vereda (igual que el callejón: andén 118..142, calle abajo).
    for x in (400, 620, 800, 1000, 1180):
        d.line([(x, 20), (x, 118)], fill=(70, 70, 80), width=2)
        d.rectangle([x - 6, 18, x + 6, 22], fill=(250, 230, 160))
    d.rectangle([360, 118, 1280, 142], fill=(110, 104, 96))
    for x in range(360, 1280, 16):
        d.line([(x, 118), (x, 142)], fill=(96, 90, 84))
    d.rectangle([360, 142, 1280, 180], fill=(52, 46, 56))
    for x in range(380, 1280, 60):
        d.rectangle([x, 160, x + 24, 162], fill=(200, 180, 90))
    im.save(OUT / "ep2_bg.png")


if __name__ == "__main__":
    # Camila salió de la hoja de Lilato cuando Lilato era morada. Lilato ahora es rosada (otros colores),
    # así que Camila ya no se rehace: si se borra camila.png, hay que ajustar estos colores.
    if not (OUT / "camila.png").exists():
        recolor("lilato.png", "camila.png", {(168, 132, 243): (236, 186, 60), (144, 94, 169): (186, 130, 40),
                                         (107, 62, 117): (130, 86, 30), (195, 36, 84): (220, 40, 60)})
    recolor("enemy_boss.png", "guillermo.png", {(237, 128, 153): (80, 160, 90), (110, 39, 39): (54, 74, 126),
                                                (169, 90, 72): (60, 120, 70)})
    bg()
    print("listo")
