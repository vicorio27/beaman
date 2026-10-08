"""Samuel, en proporciones adultas (como el protagonista): gorro tejido rojo, barba gris, abrigo café
largo que le llega a las rodillas, el costal al hombro. Once años en la calle. Sale de la prueba de
estilo (draw_adultos_prueba.py).

Salida: assets/characters/samuel.png. Celdas de 16x26, la misma distribución que protagonist_adult.png
(sin gestos): filas 0-2 (quieto, paso 1, paso 2) x columnas 0-2 (costado mirando a la izquierda,
frente, espalda). Ver CharacterFrames.adult().
Uso: python tools/art/draw_samuel.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image

OUT = Path("assets/characters/samuel.png")
CW, CH = 16, 26

PAL = {
    ".": None,
    "o": (40, 32, 44),                           # contorno
    "e": (30, 28, 36),                           # ojos
    "r": (150, 62, 52), "R": (108, 42, 38),      # gorro tejido
    "g": (196, 192, 182), "G": (146, 142, 134),  # barba y pelo gris
    "c": (116, 90, 62), "C": (84, 64, 44),       # abrigo café
    "p": (70, 68, 74), "q": (48, 46, 52),        # pantalón
    "t": (166, 120, 92),                         # piel (curtida)
    "u": (176, 150, 104), "U": (138, 114, 76),   # costal
    "k": (46, 40, 46),                           # zapatos
}

FRONT = [
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
]
BACK = [
    "...oooo...",
    "..orrRro..",
    "..oRrrRo..",
    "..oGGGGo..",
    "..oGggGo..",
    "...oGGo...",
    "...otto...",
    ".ouuuucco.",
    "ouUUuucCco",
    "ouUUuuccco",
    "ocuuuuCcco",
    "ocoCccCoco",
    "ocoCccCoco",
    "otoCccCoto",
    ".ooCccCoo.",
    "..oCccCo..",
    "..oCccCo..",
    "..ocCCco..",
]
FRONT_LEGS = {
    0: ["..oppppo..", "..opqqpo..", "..opqqpo..", ".okkookko.", ".ooo..ooo."],
    1: ["..oppppo..", "..opqqpo..", ".okkoqpo..", ".ooo.okko.", "......ooo."],
}
FRONT_LEGS[2] = [r[::-1] for r in FRONT_LEGS[1]]

# De costado, mirando a la derecha (la hoja lo guarda mirando a la izquierda): el costal atrás.
SIDE = [
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
]
SIDE_LEGS = {
    0: ["...opppo..", "...oppqo..", "...oppqo..", "...oppqo..", "...okkkko.", "...oooooo."],
    1: ["...opppo..", "..oppoqo..", "..opo.oqo.", ".opo..oqo.", ".okko.okko", ".ooo..oooo"],
}
SIDE_LEGS[2] = SIDE_LEGS[0]


def frame(rows, flip=False, dy=0) -> Image.Image:
    im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    top = CH - len(rows) + dy
    for y, r in enumerate(rows):
        assert len(r) == 10, (r, len(r))
        for x, ch in enumerate(r):
            if PAL[ch] and 0 <= top + y < CH:
                im.putpixel((x + 3, top + y), PAL[ch] + (255,))
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


def main():
    sheet = Image.new("RGBA", (3 * CW, 3 * CH), (0, 0, 0, 0))
    for row in range(3):
        dy = -1 if row else 0
        sheet.alpha_composite(frame(SIDE + SIDE_LEGS[row], flip=True, dy=-1 if row == 1 else 0), (0, row * CH))
        sheet.alpha_composite(frame(FRONT + FRONT_LEGS[row], dy=dy), (CW, row * CH))
        sheet.alpha_composite(frame(BACK + [r[::-1] for r in FRONT_LEGS[row]], dy=dy), (2 * CW, row * CH))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print("Samuel:", OUT, sheet.size)


if __name__ == "__main__":
    main()
