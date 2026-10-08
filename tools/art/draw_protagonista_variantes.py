"""PRUEBA: tres versiones del protagonista con un gancho visual (algo que no encaja y da curiosidad),
cada una sacada de su historia. Misma proporción adulta (~24 px) que draw_adultos_prueba.py.
  A. EL EJECUTIVO: saco que le queda grande, corbata roja floja, un zapato de cada color (La Empresa).
  B. EL MOTOCICLISTA: chaqueta de cuero vieja, pañoleta roja, el casco colgando del morral (la Renegade).
  C. EL IMPERMEABLE AMARILLO: pelo largo, barba, impermeable amarillo (el color del guayacán).
Uso: python tools/art/draw_protagonista_variantes.py <fondo.png> <salida.png>"""
import sys
from PIL import Image, ImageDraw
from draw_adultos_prueba import PAL, sprite, place, SAM_SIDE, LUKAS_SIDE

PAL.update({
    "z": (70, 74, 92), "Z": (46, 48, 62),        # saco gris azulado, gastado
    "y": (200, 46, 50), "Y": (138, 30, 38),      # rojo (corbata / pañoleta)
    "x": (196, 64, 52),                          # el zapato rojo
    "l": (44, 40, 46), "I": (100, 94, 106),      # cuero negro y su brillo
    "v": (70, 72, 80), "V": (150, 196, 214),     # casco y visera
    "a": (232, 188, 58), "A": (176, 132, 36),    # impermeable amarillo
})

A_FRONT = [
    "...oooo...",
    "..ohHhho..",
    ".ohhhhhho.",
    ".ohHsssho.",
    "..oesseo..",
    "..obSSbo..",
    "...obbo...",
    "..owyywo..",
    ".ozwyywzo.",
    "ozzwyywzzo",
    "ozzwYYwzzo",
    "ozozyyzozo",
    "oZozyyzoZo",
    "oZozwYzoZo",
    "osozwwzoso",
    ".oozwwzoo.",
    "..ojjjjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    ".okkooxxo.",
    ".ooo..ooo.",
]
A_SIDE = [
    "...oooo...",
    "..ohhhHo..",
    ".ohhhhhhho",
    ".ohhsssso.",
    ".ohhsseso.",
    "..ohbbbso.",
    "...obbbo..",
    "...oSwyo..",
    "omozzzwyo.",
    "omozzZwyo.",
    "oMozzZwyo.",
    "oMozzZwyo.",
    "omozzZwYo.",
    ".oozzswo..",
    "...ozzzo..",
    "...ojjjo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...oxxxxo.",
    "...oooooo.",
]
B_FRONT = [
    "...oooo...",
    "..ohhhho..",
    "..ohHhho..",
    "..osssso..",
    "..oesseo..",
    "..obSSbo..",
    "...obbo...",
    "..oyyyyo..",
    ".ollyYllo.",
    "olIlwwlIlo",
    "olllwwlllo",
    "oloIwwIolo",
    "oIolwwloIo",
    "ololwwlolo",
    "osokkkkoso",
    ".oojjjjoo.",
    "..ojjjjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    ".okkookko.",
    ".ooo..ooo.",
]
_B_SIDE = [
    "...oooo...",
    "..ohhhho..",
    ".ohhhhhho.",
    ".ohhsssso.",
    ".ohhsseso.",
    "..ohbbbso.",
    "...obbbo..",
    "...oyyyo..",
    "omolllIo..",
    "omollIlo..",
    "oMollIlo..",
    "oMollIlo..",
    "omollIlo..",
    ".oollslo..",
    "...okkko..",
    "...ojjjo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...okkkko.",
    "...oooooo.",
]
# El casco de la Renegade, colgado del morral.
_HELMET = {10: ".oo.", 11: "ovvo", 12: "oVvo", 13: "ovvo", 14: ".oo."}
B_SIDE = []
for i, r in enumerate(_B_SIDE):
    row = list(".." + r)
    for k, ch in enumerate(_HELMET.get(i, "")):
        if ch != ".":
            row[k] = ch
    B_SIDE.append("".join(row))

C_FRONT = [
    "...oooo...",
    "..ohhhho..",
    ".ohhHhhho.",
    ".ohssssho.",
    ".ohesseho.",
    ".ohbSSbho.",
    ".ohbbbbho.",
    "..oabbao..",
    ".oaaaaaao.",
    "oaaaaaaaao",
    "oaAaaaaAao",
    "oaoaaaaoao",
    "oAoaAAaoAo",
    "oAoaaaaoAo",
    "osoaaaaoso",
    ".ooaaaaoo.",
    "..oaAAao..",
    "..oAaaAo..",
    "..ojjjjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    ".okkookko.",
    ".ooo..ooo.",
]
C_SIDE = [
    "...oooo...",
    "..ohhhho..",
    ".ohhhhhho.",
    ".ohhsssso.",
    ".ohhsseso.",
    ".ohhbbbso.",
    ".ohhbbbbo.",
    "..ohabbo..",
    "omoaaaao..",
    "omoaaAao..",
    "oMoaaAao..",
    "oMoaaAao..",
    "omoaaAao..",
    ".ooaasao..",
    "...oaaao..",
    "...oaaao..",
    "...oaAao..",
    "...oAaAo..",
    "...ojjjo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...okkkko.",
    "...oooooo.",
]

VARIANTS = [("A  EL EJECUTIVO", A_FRONT, A_SIDE), ("B  EL MOTOCICLISTA", B_FRONT, B_SIDE),
            ("C  EL IMPERMEABLE", C_FRONT, C_SIDE)]


def silhouette(spr):
    out = spr.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y][3]:
                px[x, y] = (16, 14, 18, 255)
    return out


def main():
    bg = Image.open(sys.argv[1]).convert("RGBA")
    crop = (110, 95, 250, 165)
    S = 3
    panels = []
    for name, front, side in VARIANTS:
        scene = bg.copy()
        place(scene, sprite(front), 150, 150)
        place(scene, sprite(LUKAS_SIDE), 170, 151)
        place(scene, sprite(SAM_SIDE, flip=True), 205, 147)
        p = scene.crop(crop).resize(((crop[2] - crop[0]) * S, (crop[3] - crop[1]) * S), Image.NEAREST)
        # Debajo: de frente, de costado y la silueta (¿se reconoce sin colores?).
        strip = Image.new("RGBA", (60, 30), (58, 52, 60, 255))
        x = 4
        for spr in [sprite(front), sprite(side), silhouette(sprite(front)), silhouette(sprite(side))]:
            strip.alpha_composite(spr, (x, 28 - spr.height))
            x += spr.width + 3
        strip = strip.resize((strip.width * 7, strip.height * 7), Image.NEAREST)
        col = Image.new("RGBA", (p.width, p.height + strip.height + 30), (24, 20, 28, 255))
        ImageDraw.Draw(col).text((8, 6), name, fill=(240, 220, 170, 255))
        col.alpha_composite(p, (0, 22))
        col.alpha_composite(strip, ((p.width - strip.width) // 2, p.height + 26))
        panels.append(col)
    W = sum(p.width for p in panels) + 12 * (len(panels) - 1)
    out = Image.new("RGBA", (W, panels[0].height), (24, 20, 28, 255))
    x = 0
    for p in panels:
        out.alpha_composite(p, (x, 0))
        x += p.width + 12
    out.save(sys.argv[2])
    print("ok", out.size)


if __name__ == "__main__":
    main()
