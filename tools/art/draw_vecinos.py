"""Los vecinos con cara, en proporciones adultas (como el protagonista y Samuel):
  Don Germán  panadero viejo y viudo: calvo con los costados canosos, bigote gris, delantal blanco con
              harina sobre la camisa beige. Algo de barriga.
  Doña Rosa   la del puesto de la plaza: bajita y ancha, moño negro, delantal de cuadros rojos sobre la
              blusa blanca, falda oscura.
  Marta       la del café: unos cuarenta, cola de caballo castaña, blusa mostaza, delantal negro corto,
              jean y tenis.
  Wilson      el reciclador: gorra verde, chaleco naranja con cintas reflectivas, guantes, botas.

Salida: assets/characters/<id>.png. Celdas de 16x26, la misma distribución que samuel.png: filas 0-2
(quieto, paso 1, paso 2) x columnas 0-2 (costado mirando a la izquierda, frente, espalda).
Ver CharacterFrames.OWN.
Uso: python tools/art/draw_vecinos.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image

CW, CH = 16, 26
BASE = {".": None, "o": (40, 32, 44), "e": (30, 28, 36)}

# ---------------------------------------------------------------- Piernas (10 de ancho)


def legs_front(n: int) -> dict:
    """n filas de pierna + zapato + suela. Paso 1: sube el pie izquierdo; paso 2, el derecho."""
    idle = ["..oppppo.."] + ["..opqqpo.."] * (n - 1) + [".okkookko.", ".ooo..ooo."]
    step = idle[:n - 1] + [".okkoqpo..", ".ooo.okko.", "......ooo."]
    return {0: idle, 1: step, 2: [r[::-1] for r in step]}


def legs_side(n: int) -> dict:
    """De costado (mirando a la derecha). n >= 3."""
    idle = ["...opppo.."] + ["...oppqo.."] * (n - 1) + ["...okkkko.", "...oooooo."]
    step = (["...opppo.."] + ["..oppoqo.."] * (n >= 4) + ["..opo.oqo."] * max(n - 3, 1)
            + [".opo..oqo.", ".okko.okko", ".ooo..oooo"])
    return {0: idle, 1: step, 2: idle}


# ---------------------------------------------------------------- Don Germán
GERMAN = {
    "pal": {
        "s": (222, 170, 140), "S": (184, 128, 104),  # piel
        "g": (190, 186, 180), "G": (150, 146, 140),  # canas / bigote
        "c": (200, 176, 136), "C": (160, 136, 100),  # camisa beige
        "a": (238, 234, 226), "A": (196, 192, 184),  # delantal (con harina)
        "p": (104, 80, 62), "q": (78, 58, 44),       # pantalón café
        "k": (52, 42, 40),
    },
    "front": [
        "...oooo...",
        "..osssso..",
        "..ogssgo..",
        "..oesseo..",
        "..ogsSgo..",
        "..oGGGGo..",
        "...osso...",
        "...oSSo...",
        ".occaacco.",
        "occaaaacco",
        "ocoaaaaoco",
        "ocoaaaaoco",
        "ocoaAaaoco",
        "osoaaaaoso",
        ".ooaaaaoo.",
        "..oaaAao..",
        "..oaaaao..",
    ],
    "back": [
        "...oooo...",
        "..osssso..",
        "..ogssgo..",
        "..oggggo..",
        "..oggggo..",
        "..ogGGgo..",
        "...oSSo...",
        "...oSSo...",
        ".occcccco.",
        "occcccccco",
        "ococcccoco",
        "ococcccoco",
        "ocoaAAaoco",
        "osoccccoso",
        ".ooccccoo.",
        "..occcco..",
        "..oCCCCo..",
    ],
    "side": [
        "...oooo...",
        "..osssso..",
        "..ogsssso.",
        "..oggseso.",
        "..oggsssSo",
        "...ogGGGo.",
        "...oosso..",
        "....oSo...",
        "...occao..",
        "..occcaao.",
        "..occcaao.",
        "..ocCcaao.",
        "..occcaao.",
        "..osccaao.",
        "...occaao.",
        "...occAo..",
        "...occao..",
    ],
    "legs": 5,
}

# ---------------------------------------------------------------- Doña Rosa
ROSA = {
    "pal": {
        "s": (176, 116, 84), "S": (138, 86, 62),     # piel morena
        "h": (36, 30, 36), "H": (70, 62, 72),        # pelo negro
        "w": (232, 226, 214), "W": (190, 184, 172),  # blusa
        "r": (196, 58, 56), "R": (236, 220, 210),    # delantal de cuadros
        "f": (52, 56, 86), "F": (36, 38, 62),        # falda
        "p": (150, 104, 80), "q": (120, 80, 62),     # medias color piel
        "k": (40, 34, 38),
    },
    "front": [
        "....oo....",
        "...ohho...",
        "..ohhhho..",
        "..ohssho..",
        "..oesseo..",
        "..ossSso..",
        "...osso...",
        "...oSSo...",
        ".owwwwwwo.",
        "owwrRrRwwo",
        "oworRrRowo",
        "owoRrRrowo",
        "osorRrRoso",
        "offRrRrffo",
        "offffffffo",
        "oFffffffFo",
        ".oooooooo.",
    ],
    "back": [
        "....oo....",
        "...ohho...",
        "..ohhhho..",
        "..ohhhho..",
        "..ohHHho..",
        "..ohhhho..",
        "...oSSo...",
        "...oSSo...",
        ".owwwwwwo.",
        "owwwwwwwwo",
        "owowwwwowo",
        "owoWwwWowo",
        "osorrrroso",
        "offffffffo",
        "offffffffo",
        "oFffffffFo",
        ".oooooooo.",
    ],
    "side": [
        ".oo.......",
        "ohho......",
        "ohhohhho..",
        ".oohhssso.",
        "..ohhseso.",
        "..ohssSso.",
        "...oosso..",
        "....oSo...",
        "...owwwo..",
        "..owwwrRo.",
        "..owWwRro.",
        "..owWwrRo.",
        "..oswwRro.",
        "..offfrRo.",
        "..offfffo.",
        "..oFffffFo",
        "..oooooooo",
    ],
    "legs": 3,
}

# ---------------------------------------------------------------- Marta
MARTA = {
    "pal": {
        "s": (226, 172, 142), "S": (186, 128, 104),
        "h": (98, 62, 42), "H": (132, 88, 58),       # castaño
        "y": (214, 168, 64), "Y": (172, 128, 44),    # blusa mostaza
        "a": (44, 40, 46), "A": (76, 70, 78),        # delantal negro
        "n": (178, 84, 84),                          # labios
        "p": (70, 96, 148), "q": (48, 66, 108),      # jean
        "k": (216, 212, 204),                        # tenis blancos
    },
    "front": [
        "...oooo...",
        "..ohhhho..",
        ".ohHhhhho.",
        ".ohssssho.",
        ".ohesseho.",
        ".ohssSsho.",
        "..oosnoo..",
        "...oSSo...",
        ".oyyyyyyo.",
        "oyyyyyyyyo",
        "oyoyyyyoyo",
        "oyoaaaaoyo",
        "osoaAaaoso",
        ".ooaaaaoo.",
        "..oaaaao..",
    ],
    "back": [
        "...oooo...",
        "..ohhhho..",
        ".ohhHhhho.",
        ".ohhhhhho.",
        ".ohhHHhho.",
        "..ohhhho..",
        "...ohho...",
        "...ohho...",
        ".oyyhyyyo.",
        "oyyyyyyyyo",
        "oyoyyyyoyo",
        "oyoaAAaoyo",
        "osoyyyyoso",
        ".ooppppoo.",
        "..oppppo..",
    ],
    "side": [
        "...oooo...",
        "..ohhhhoo.",
        ".ohhHhhhho",
        "ohhohhssso",
        "oho.ohseso",
        "oho.ohssSo",
        ".o...osno.",
        "....oSSo..",
        "...oyyyo..",
        "..oyyyyyo.",
        "..oyyyYyo.",
        "..oyyyYao.",
        "..osyyaao.",
        "...oyaaao.",
        "...oaaao..",
    ],
    "legs": 7,
}

# ---------------------------------------------------------------- Wilson
WILSON = {
    "pal": {
        "s": (168, 112, 78), "S": (132, 84, 58),
        "h": (34, 30, 34),                            # pelo
        "g": (66, 112, 70), "G": (44, 80, 50),        # gorra verde
        "c": (130, 128, 124), "C": (98, 96, 94),      # camiseta gris
        "v": (232, 120, 40), "V": (220, 224, 214),    # chaleco naranja / cinta reflectiva
        "u": (120, 104, 76),                          # guantes
        "p": (54, 60, 78), "q": (38, 42, 56),         # sudadera
        "k": (38, 32, 34),                            # botas
    },
    "front": [
        "...oooo...",
        "..oggggo..",
        ".oGGGGGGo.",
        "..osssso..",
        "..oesseo..",
        "..osSSso..",
        "...osso...",
        "...oSSo...",
        ".ocvvvvco.",
        "occvvvvcco",
        "ocoVVVVoco",
        "ocovvvvoco",
        "ocoVVVVoco",
        "ouovvvvouo",
        ".ooccccoo.",
        "..occcco..",
    ],
    "back": [
        "...oooo...",
        "..oggggo..",
        "..ogGGgo..",
        "..ohhhho..",
        "..ohhhho..",
        "..ohhhho..",
        "...oSSo...",
        "...oSSo...",
        ".ocvvvvco.",
        "occvvvvcco",
        "ocoVVVVoco",
        "ocovvvvoco",
        "ocoVVVVoco",
        "ouovvvvouo",
        ".ooccccoo.",
        "..occcco..",
    ],
    "side": [
        "...oooo...",
        "..oggggo..",
        "..oggggGGo",
        "..ohhssso.",
        "..ohsseso.",
        "...osSsso.",
        "....osso..",
        "....oSo...",
        "...ovvvo..",
        "..ocvvvo..",
        "..ocVVVo..",
        "..ocvvvo..",
        "..ocVVVo..",
        "..ouvvvo..",
        "...occco..",
        "...occco..",
    ],
    "legs": 6,
}

PEOPLE = {"german": GERMAN, "rosa": ROSA, "marta": MARTA, "wilson": WILSON}


def frame(rows, pal, flip=False, dy=0) -> Image.Image:
    """Las filas van centradas en la celda: casi todas de 10 de ancho (los gordos, más)."""
    im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    top = CH - len(rows) + dy
    for y, r in enumerate(rows):
        assert len(r) % 2 == 0 and len(r) <= CW, (r, len(r))
        left = (CW - len(r)) // 2
        for x, ch in enumerate(r):
            c = pal[ch]
            if c and 0 <= top + y < CH:
                im.putpixel((x + left, top + y), c + (255,))
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


def sheet(p: dict) -> Image.Image:
    pal = {**BASE, **p["pal"]}
    assert len(p["front"]) == len(p["back"]) == len(p["side"]), "las tres vistas tienen que medir lo mismo"
    front, side = legs_front(p["legs"]), legs_side(p["legs"])
    out = Image.new("RGBA", (3 * CW, 3 * CH), (0, 0, 0, 0))
    for row in range(3):
        dy = -1 if row else 0
        out.alpha_composite(frame(p["side"] + side[row], pal, flip=True, dy=-1 if row == 1 else 0), (0, row * CH))
        out.alpha_composite(frame(p["front"] + front[row], pal, dy=dy), (CW, row * CH))
        out.alpha_composite(frame(p["back"] + [r[::-1] for r in front[row]], pal, dy=dy), (2 * CW, row * CH))
    return out


def main():
    for pid, p in PEOPLE.items():
        path = Path("assets/characters") / (pid + ".png")
        sheet(p).save(path)
        print(pid, path)


if __name__ == "__main__":
    main()
