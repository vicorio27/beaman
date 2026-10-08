"""PRUEBA de estilo: personajes en proporciones adultas (~24 px de alto, cabeza 1:4) en vez de los
chibis de 16 px. Él, Lukas y Samuel. No se usa en el juego todavía: genera hojas de prueba y una
comparación (antes / después) sobre una foto del barrio.
Uso: python tools/art/draw_adultos_prueba.py <fondo.png> <salida_dir>"""
import sys
from pathlib import Path
from PIL import Image

PAL = {
    ".": None,
    "o": (40, 32, 44),       # contorno
    "h": (44, 42, 50), "H": (78, 80, 92),        # pelo negro
    "s": (214, 150, 120), "S": (172, 110, 90),   # piel
    "e": (30, 28, 36),                           # ojos
    "b": (118, 92, 82),                          # barba de tres días
    "w": (206, 200, 184), "W": (152, 146, 134),  # camisa blanca gastada
    "j": (66, 92, 146), "J": (44, 62, 104),      # jean
    "k": (46, 40, 46),                           # zapatos / correa
    "m": (112, 84, 58), "M": (82, 60, 42),       # morral
    # Samuel
    "r": (150, 62, 52), "R": (108, 42, 38),      # gorro tejido
    "g": (196, 192, 182), "G": (146, 142, 134),  # barba gris
    "c": (116, 90, 62), "C": (84, 64, 44),       # abrigo café
    "p": (70, 68, 74), "q": (48, 46, 52),        # pantalón
    "t": (166, 120, 92),                         # piel de Samuel (más curtida)
    "u": (176, 150, 104), "U": (138, 114, 76),   # costal
    # Lukas
    "L": (236, 230, 218),                        # blanco
    "B": (48, 42, 46),                           # manta negra
    "T": (192, 118, 60), "D": (140, 80, 40),     # canela / oreja
    "n": (26, 22, 26),                           # nariz
}

ME_FRONT = [
    "...oooo...",
    "..ohhHho..",
    "..ohhhho..",
    "..oHssso..",
    "..oesseo..",
    "..obSSbo..",
    "...obbo...",
    "...oSSo...",
    ".owwwwwwo.",
    "owmwwwwmwo",
    "owmwwwwmwo",
    "owomwwmowo",
    "oWowwwwoWo",
    "oWowWWwoWo",
    "osokkkkoso",
    ".oojjjjoo.",
    "..ojjjjo..",
    "..ojjjjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    "..ojJJjo..",
    ".okkookko.",
    ".ooo..ooo.",
]
ME_BACK = ME_FRONT[:3] + [
    "..ohhhho..",
    "..ohhhho..",
    "..oShhSo..",
    "...oSSo...",
    "...oSSo...",
    ".owmmmmwo.",
    "owmmmmmmwo",
    "owmMMMMmwo",
    "owommmmowo",
    "oWommmmoWo",
    "oWoMmmMoWo",
    "osokkkkoso",
] + ME_FRONT[15:]
ME_SIDE = [
    "...oooo...",
    "..ohhhho..",
    ".ohhhhhho.",
    ".ohhsssso.",
    ".ohhsseso.",
    "..ohbbbso.",
    "...obbbo..",
    "....oSo...",
    "omowwwwo..",
    "omowwWwo..",
    "oMowwWwo..",
    "oMowwWwo..",
    "omowwWwo..",
    ".oowwswo..",
    "...okkko..",
    "...ojjjo..",
    "...ojjjo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...ojjJo..",
    "...okkkko.",
    "...oooooo.",
]
ME_STEP = ME_SIDE[:16] + [
    "..ojjJjo..",
    "..ojoojo..",
    ".ojo..ojo.",
    ".ojo..ojo.",
    ".oJo..oJo.",
    "okko..okko",
    "ooo...ooo.",
    "..........",
]

SAM_FRONT = [
    "..........",
    "...oooo...",
    "..orrRro..",
    "..oRrrRo..",
    "..otttto..",
    "..oetteo..",
    "..oggggo..",
    "..ogGGgo..",
    "...oggo...",
    ".occggcco.",
    "occcCCccco",
    "ococCCcoco",
    "ocoCccCoco",
    "ocoCccCoco",
    "otoCccCoto",
    ".ooCccCoo.",
    "..oCccCo..",
    "..oCccCo..",
    "..ocCCco..",
    "..oppppo..",
    "..opqqpo..",
    "..opqqpo..",
    ".okkookko.",
    ".ooo..ooo.",
]
SAM_SIDE = [
    "..........",
    "...oooo...",
    "..orrrro..",
    "..oRRRRRo.",
    "..ottetto.",
    "..oggggto.",
    "...oggGo..",
    "....ogo...",
    "uuocccco..",
    "uUocccCo..",
    "uUoccCco..",
    "uUoccCco..",
    "uuoccCco..",
    ".ooccCco..",
    "...ocCto..",
    "...occco..",
    "...oCCCo..",
    "...oCCCo..",
    "...opppo..",
    "...oppqo..",
    "...oppqo..",
    "...oppqo..",
    "...okkkko.",
    "...oooooo.",
]

LUKAS_SIDE = [
    "...........ooo...",
    ".o........oTTTo..",
    "oLo......oDTTeTo.",
    "oTooooooooDDTTLLn",
    ".oBBBBBBBoDDTTLLo",
    ".oBBBBBBBoDDLLLo.",
    ".oTTBBBBTTDLLLo..",
    ".oTTTTTTTTTLLo...",
    ".oLLLLLLLLLLLo...",
    ".oLo.oLo.oLooLo..",
    ".oo..oo..oo.oo...",
]
LUKAS_FRONT = [
    "...ooooo...",
    "..oTTTTTo..",
    ".oDTeTeTDo.",
    ".oDTTLTTDo.",
    ".oDoLnLoDo.",
    "..o.oLo.o..",
    "..oLLLLLo..",
    ".oBLLLLLBo.",
    ".oTLLLLLTo.",
    ".oLoLLLoLo.",
    ".oo.ooo.oo.",
]


def sprite(rows, flip=False):
    w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        assert len(r) == w, (r, len(r), w)
        for x, ch in enumerate(r):
            c = PAL[ch]
            if c:
                im.putpixel((x, y), c + (255,))
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


def shadow(base, x, y, w):
    """Sombra ovalada bajo los pies."""
    sh = Image.new("RGBA", (w, 3), (0, 0, 0, 0))
    for i in range(w):
        for j in range(3):
            if (j == 1) or (1 < i < w - 2):
                sh.putpixel((i, j), (20, 16, 24, 70))
    base.alpha_composite(sh, (x, y))


def place(base, spr, x, y):
    """x, y = pies (centro abajo)."""
    shadow(base, x - spr.width // 2 - 1, y - 2, spr.width + 2)
    base.alpha_composite(spr, (x - spr.width // 2, y - spr.height))


def old_tile(path, col, row, tint=None):
    im = Image.open(path).convert("RGBA").crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16))
    if tint:
        px = im.load()
        for yy in range(16):
            for xx in range(16):
                r, g, b, a = px[xx, yy]
                px[xx, yy] = (int(r * tint[0]), int(g * tint[1]), int(b * tint[2]), a)
    return im


def main():
    fondo, out = Path(sys.argv[1]), Path(sys.argv[2])
    bg = Image.open(fondo).convert("RGBA")
    # Antes: los de 16 px (él de frente, Lukas, Samuel = Kenney fila 12 teñido como en el juego).
    before = bg.copy()
    me_old = old_tile("assets/characters/protagonist_topdown.png", 1, 0)
    lk_old = old_tile("assets/characters/lukas.png", 3, 0)
    sam_old = old_tile("assets/tilesets/kenney_urban.png", 24, 12, (0.8, 0.75, 0.7))
    for spr, x, y in [(me_old, 150, 150), (lk_old, 168, 150), (sam_old, 200, 146)]:
        place(before, spr, x, y)
    # Después.
    after = bg.copy()
    place(after, sprite(ME_FRONT), 150, 150)
    place(after, sprite(LUKAS_SIDE), 170, 151)
    place(after, sprite(SAM_SIDE, flip=True), 200, 147)
    # Arriba: antes | después (a 3x). Abajo: las hojas de los tres, a 6x.
    S = 3
    crop = (40, 10, 250, 165)
    a = before.crop(crop).resize(((crop[2] - crop[0]) * S, (crop[3] - crop[1]) * S), Image.NEAREST)
    b = after.crop(crop).resize(a.size, Image.NEAREST)
    sheet = Image.new("RGBA", (190, 30), (58, 52, 60, 255))
    xs = 4
    for spr in [sprite(ME_FRONT), sprite(ME_SIDE), sprite(ME_STEP), sprite(ME_BACK), sprite(SAM_FRONT), sprite(SAM_SIDE),
                sprite(LUKAS_FRONT), sprite(LUKAS_SIDE)]:
        sheet.alpha_composite(spr, (xs, 28 - spr.height))
        xs += spr.width + 6
    sheet = sheet.resize((sheet.width * 5, sheet.height * 5), Image.NEAREST)
    W = max(a.width * 2 + 12, sheet.width)
    comp = Image.new("RGBA", (W, a.height + sheet.height + 12), (24, 20, 28, 255))
    comp.alpha_composite(a, (0, 0))
    comp.alpha_composite(b, (a.width + 12, 0))
    comp.alpha_composite(sheet, ((W - sheet.width) // 2, a.height + 12))
    out.mkdir(parents=True, exist_ok=True)
    comp.save(out / "comparacion.png")
    after.resize((bg.width * 3, bg.height * 3), Image.NEAREST).save(out / "despues_completo.png")
    print("ok", comp.size)


if __name__ == "__main__":
    main()
