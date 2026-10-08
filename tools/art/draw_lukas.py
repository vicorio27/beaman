"""Lukas, el beagle, en proporciones reales (al lado del protagonista adulto de ~25 px): ~11 px de alto.
Tricolor: blanco, canela y la "montura" negra en el lomo; orejas largas caídas; cola para arriba con
punta blanca. Sale de la prueba de estilo (draw_adultos_prueba.py).

Hoja 80x48, celdas de 20x16 (los pies en la fila de abajo, centrado). Ver Lukas.cell().
  Columnas: costado (mira a la izquierda), frente, espalda, extra.
  Filas: quieto, paso 1, paso 2. La columna extra: sentado, olfateando, ladrando.
Salida: assets/characters/lukas.png
Uso: python tools/art/draw_lukas.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image

OUT = Path("assets/characters/lukas.png")
CW, CH = 20, 16

PAL = {
    ".": None,
    "o": (40, 32, 44),                           # contorno
    "L": (236, 230, 218),                        # blanco
    "B": (48, 42, 46),                           # manta negra
    "T": (192, 118, 60), "D": (140, 80, 40),     # canela / oreja
    "n": (26, 22, 26),                           # nariz / ojo
    "r": (220, 110, 120),                        # lengua
}

# De costado, mirando a la derecha (la hoja lo guarda mirando a la izquierda). Sin las patas.
SIDE_BODY = [
    "...........ooo...",
    ".o........oTTTo..",
    "oLo......oDTTnTo.",
    "oTooooooooDDTTLLn",
    ".oBBBBBBBoDDTTLLo",
    ".oBBBBBBBoDDLLLo.",
    ".oTTBBBBTTDLLLo..",
    ".oTTTTTTTTTLLo...",
    ".oLLLLLLLLLLLo...",
]
SIDE_BARK = SIDE_BODY[:4] + [
    ".oBBBBBBBoDDTTLoo",
    ".oBBBBBBBoDDLLorr",
    ".oTTBBBBTTDLLLoo.",
] + SIDE_BODY[7:]
# Patas: [atrás, atrás, adelante, adelante] (columna de cada una).
LEGS_IDLE = [2, 6, 10, 13]
LEGS_STEP_1 = [1, 7, 9, 14]
LEGS_STEP_2 = [3, 5, 11, 12]

FRONT = [
    "...ooooo...",
    "..oTTTTTo..",
    ".oDTnTnTDo.",
    ".oDTTLTTDo.",
    ".oDoLnLoDo.",
    "..o.oLo.o..",
    "..oLLLLLo..",
    ".oBLLLLLBo.",
    ".oTLLLLLTo.",
]
FRONT_LEGS = {
    0: [".oLoLLLoLo.", ".oo.ooo.oo."],
    1: [".oLoLLLooo.", ".oo.ooo...."],
    2: [".oooLLLoLo.", "....ooo.oo."],
}
BACK = [
    "...ooooo...",
    "..oTTTTTo..",
    ".oDTTTTTDo.",
    ".oDTTTTTDo.",
    ".oDoTTToDo.",
    "..ooBBBoo..",
    "..oBBBBBo..",
    ".oTBBBBBTo.",
    ".oTTBLBTTo.",
]
BACK_LEGS = {
    0: [".oLoTLToLo.", ".oo.oLo.oo."],
    1: [".oLoTLTooo.", ".oo.oLo...."],
    2: [".oooTLToLo.", "....oLo.oo."],
}


def side_rows(body, legs):
    w = len(body[0])
    a, b = [list("." * w) for _ in range(2)]
    for x in legs:
        a[x - 1], a[x], a[x + 1] = "o", "L", "o"
    for x in legs:
        b[x - 1], b[x] = "o", "o"
    return body + ["".join(a), "".join(b)]


def sprite(rows, flip=False):
    w = len(rows[0])
    im = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        assert len(r) == w, (r, len(r), w)
        for x, ch in enumerate(r):
            if PAL[ch]:
                im.putpixel((x, y), PAL[ch] + (255,))
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


def shift(im, box, dy):
    """Corre hacia abajo (dy) lo que hay dentro de box = (x0, y0, x1, y1)."""
    part = im.crop(box)
    out = im.copy()
    out.paste((0, 0, 0, 0), box)
    out.alpha_composite(part, (box[0], box[1] + dy))
    return out


def side(legs=LEGS_IDLE, pose="stand"):
    """Mirando a la derecha (sin voltear)."""
    if pose == "bark":
        return sprite(side_rows(SIDE_BARK, legs))
    im = sprite(side_rows(SIDE_BODY, legs))
    if pose == "sit":
        # Sin patas de atrás; la cola y el lomo bajan hasta el suelo.
        im.paste((0, 0, 0, 0), (0, 9, 9, 11))
        return shift(im, (0, 0, 9, 9), 2)
    if pose == "sniff":
        # La cabeza baja hasta el piso.
        return shift(im, (10, 0, im.width, 9), 2)
    return im


def cell(im):
    c = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    c.alpha_composite(im, ((CW - im.width) // 2, CH - im.height))
    return c


def main():
    flip = lambda im: im.transpose(Image.FLIP_LEFT_RIGHT)
    sheet = Image.new("RGBA", (4 * CW, 3 * CH), (0, 0, 0, 0))
    for row, legs in enumerate([LEGS_IDLE, LEGS_STEP_1, LEGS_STEP_2]):
        sheet.alpha_composite(cell(flip(side(legs))), (0, row * CH))
        sheet.alpha_composite(cell(sprite(FRONT + FRONT_LEGS[row])), (CW, row * CH))
        sheet.alpha_composite(cell(sprite(BACK + BACK_LEGS[row])), (2 * CW, row * CH))
    for row, pose in enumerate(["sit", "sniff", "bark"]):
        sheet.alpha_composite(cell(flip(side(pose=pose))), (3 * CW, row * CH))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print("Lukas:", OUT, sheet.size)


if __name__ == "__main__":
    main()
