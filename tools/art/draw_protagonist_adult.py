"""El protagonista, versión A ("el ejecutivo"): adulto (ya no joven: barba tupida, canas), ~25 px de alto. Saco gris de otra vida que le
queda grande (hombros más anchos que él), corbata roja floja y larga, camisa blanca, jean, un zapato de
cada color, morral. Mechón parado. Es lo que quedó de La Empresa: da curiosidad por qué anda así.

Salida: assets/characters/protagonist_adult.png. Celdas de 16x26.
  Filas 0-2 (quieto, paso 1, paso 2) x columnas 0-2 (costado mirando a la izquierda, frente, espalda).
  Fila 3: gestos de quieto. 0-1 corbata (se la arregla), 2 venia, 3-4 risa, 5-6 habla (de costado,
  mirando abajo: a Lukas, o a nadie), 7 parpadeo.
Uso: python tools/art/draw_protagonist_adult.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image

OUT = Path("assets/characters/protagonist_adult.png")
CW, CH = 16, 26

PAL = {
    ".": None,
    "o": (40, 32, 44),
    "h": (40, 38, 46), "H": (116, 114, 118),        # pelo oscuro; H: las canas

    "s": (214, 150, 120), "S": (172, 110, 90),
    "e": (28, 26, 34), "n": (120, 60, 56),        # ojos / boca abierta
    "b": (70, 62, 60),                             # la barba (oscura, con canas en el retrato)
    "w": (206, 200, 184), "W": (150, 144, 132),
    "z": (82, 86, 106), "Z": (54, 56, 72),         # el saco
    "y": (206, 48, 52), "Y": (140, 30, 38),        # la corbata
    "j": (66, 92, 146), "J": (44, 62, 104),
    "k": (46, 40, 46), "x": (196, 64, 52),         # zapato negro, zapato rojo
    "m": (112, 84, 58), "M": (82, 60, 42),         # morral
}

# ---------------------------------------------------------------- De frente (12 de ancho, centro 5.5)
HEAD_FRONT = [
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohHhhhho.",
    "...oHssso...",
    "...oesseo...",
    "...obbbbo...",
    "....obbo....",
]
BODY_FRONT = [
    "...owyywo...",
    "ozzzwyywzzzo",
    "ozzmwyywmzzo",
    "ozZmwYYwmZzo",
    "ozzozyyzozzo",
    "oZzozyyzoZzo",
    "oZzozyYzoZzo",
    "ossozwyzosso",
    ".oo.zwwz.oo.",
    "...ozZZzo...",
]
# Gestos (reemplazan el cuerpo, o la cabeza).
BODY_TIE_1 = [  # se lleva la mano al nudo
    "...owyysso..",
    "ozzzwyysszo.",
    "ozzmwyywzzo.",
    "ozZmwYYwzZo.",
    "ozzozyyzzo..",
    "oZzozyyzo...",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwzo...",
    "...ozZZzo...",
]
BODY_TIE_2 = [  # tira: el nudo se corre
    "...owyyssso.",
    "ozzzwwyyszo.",
    "ozzmwwyyzzo.",
    "ozZmwwYYzZo.",
    "ozzozwyyzo..",
    "oZzozwyyo...",
    "oZzozwYyo...",
    "ossozwwyo...",
    ".oo.zwwzo...",
    "...ozZZzo...",
]
HEAD_SALUTE = [  # venia: la mano en la frente
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "..sshHhhhho.",
    "..ssHssso...",
    "..zoesseo...",
    "..zobSSbo...",
    "..zzobbo....",
]
BODY_SALUTE = [
    "..zowyywo...",
    "ozzzwyywzzzo",
    "ozzmwyywmzzo",
    "ozZmwYYwmZzo",
    ".o.ozyyzozzo",
    "...ozyyzoZzo",
    "...ozyYzoZzo",
    "...ozwyzosso",
    "....zwwz.oo.",
    "...ozZZzo...",
]
HEAD_LAUGH = [
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohHhhhho.",
    "...oHssso...",
    "...oSssSo...",
    "...obnnbo...",
    "....obbo....",
]
HEAD_BLINK = HEAD_FRONT[:5] + ["...oSssSo..."] + HEAD_FRONT[6:]

# ---------------------------------------------------------------- Espalda
HEAD_BACK = [
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohHhhhho.",
    "...ohhhho...",
    "...ohhhho...",
    "...oShhSo...",
    "....oSSo....",
]
BODY_BACK = [
    "...ozzzzo...",
    "ozzzmmmmzzzo",
    "ozzmmMMmmzzo",
    "ozZmMmmMmZzo",
    "ozzommmmozzo",
    "oZzoMmmMoZzo",
    "oZzozzzzoZzo",
    "ossozzzzosso",
    ".oo.zZZz.oo.",
    "...ozZZzo...",
]

# ---------------------------------------------------------------- De costado (mira a la derecha; se voltea)
HEAD_SIDE = [
    ".....oo.....",
    "...oohHo....",
    "..ohhhhhho..",
    ".ohhhhhhho..",
    ".ohhhsssso..",
    "..ohhseso...",
    "...ohbbbso..",
    "....obbbo...",
]
BODY_SIDE = [
    "....oSwyo...",
    ".omozzzwyo..",
    ".omozzZwyo..",
    ".oMozzZwyo..",
    ".oMozzZwyo..",
    ".omozzZwYo..",
    "..oozzZwyo..",
    "....ozzso...",
    "....ozzzo...",
    "....oZZZo...",
]
BODY_SIDE_SWING = [  # al caminar la corbata se va para atrás
    "....oSwyo...",
    ".omozzzwyo..",
    ".omozzZwyo..",
    ".oMozzZwyo..",
    ".oMozzyyZo..",
    ".omozyyZzo..",
    "..oozzZzo...",
    "....ozzso...",
    "....ozzzo...",
    "....oZZZo...",
]
HEAD_SIDE_TALK_1 = [  # mira abajo (a Lukas)
    "............",
    ".....oo.....",
    "...oohHo....",
    "..ohhhhhho..",
    ".ohhhhhhho..",
    ".ohhhsssso..",
    "..ohhsseso..",
    "...ohbnbso..",
]
HEAD_SIDE_TALK_2 = HEAD_SIDE_TALK_1[:7] + ["...ohbbbso.."]

LEGS_SIDE_IDLE = [
    "....ojjo....",
    "....ojjJo...",
    "....ojjJo...",
    "....ojjJo...",
    "....ojjJo...",
    "....ojjJo...",
    "....oxxxxo..",
    "....oooooo..",
]
LEGS_SIDE_STEP = [
    "....ojjJo...",
    "...ojjoJo...",
    "...ojooJjo..",
    "..ojo..oJo..",
    "..ojo..oJjo.",
    "..oJo...oJo.",
    ".okko...oxxo",
    ".ooo....oooo",
]


def legs_front(lift_left: int, lift_right: int) -> list:
    """Piernas de frente / espalda: 7 filas de pierna + zapato + suela. lift = cuánto sube ese pie."""
    rows = [list("............") for _ in range(8)]
    for i in range(8):
        for (c_out, c_a, c_b, lift, shoe, side) in [(3, 4, 5, 0, "k", -1), (8, 7, 6, 0, "x", 1)]:
            lift = lift_left if side < 0 else lift_right
            last_leg = 5 - lift
            if i <= last_leg:
                rows[i][c_out] = "o"
                rows[i][c_a] = "j"
                rows[i][c_b] = "J" if i > 0 else "j"
            elif i == last_leg + 1:
                cols = [2, 3, 4, 5] if side < 0 else [6, 7, 8, 9]
                for c in cols:
                    rows[i][c] = shoe
                rows[i][cols[0] if side < 0 else cols[-1]] = "o"
            elif i == last_leg + 2:
                cols = [2, 3, 4, 5] if side < 0 else [6, 7, 8, 9]
                for c in cols:
                    rows[i][c] = "o"
    return ["".join(r) for r in rows]


def frame(head, body, legs, flip=False, dy=0) -> Image.Image:
    rows = head + body + legs
    im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
    top = CH - len(rows) + dy
    for y, r in enumerate(rows):
        assert len(r) == 12, (r, len(r))
        for x, ch in enumerate(r):
            c = PAL[ch]
            if c and 0 <= top + y < CH:
                im.putpixel((x + 2, top + y), c + (255,))
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


def main():
    still = legs_front(0, 0)
    step_a, step_b = legs_front(1, 0), legs_front(0, 1)
    cells = {
        # costado (la hoja lo guarda mirando a la izquierda)
        (0, 0): frame(HEAD_SIDE, BODY_SIDE, LEGS_SIDE_IDLE, flip=True),
        (0, 1): frame(HEAD_SIDE, BODY_SIDE_SWING, LEGS_SIDE_STEP, flip=True, dy=-1),
        (0, 2): frame(HEAD_SIDE, BODY_SIDE, LEGS_SIDE_IDLE, flip=True),
        # frente
        (1, 0): frame(HEAD_FRONT, BODY_FRONT, still),
        (1, 1): frame(HEAD_FRONT, BODY_FRONT, step_a, dy=-1),
        (1, 2): frame(HEAD_FRONT, BODY_FRONT, step_b, dy=-1),
        # espalda
        (2, 0): frame(HEAD_BACK, BODY_BACK, still),
        (2, 1): frame(HEAD_BACK, BODY_BACK, step_a, dy=-1),
        (2, 2): frame(HEAD_BACK, BODY_BACK, step_b, dy=-1),
        # gestos
        (0, 3): frame(HEAD_FRONT, BODY_TIE_1, still),
        (1, 3): frame(HEAD_FRONT, BODY_TIE_2, still),
        (2, 3): frame(HEAD_SALUTE, BODY_SALUTE, still),
        (3, 3): frame(HEAD_LAUGH, BODY_FRONT, still),
        (4, 3): frame(HEAD_LAUGH, BODY_FRONT, still, dy=-1),
        (5, 3): frame(HEAD_SIDE_TALK_1, BODY_SIDE, LEGS_SIDE_IDLE, flip=True),
        (6, 3): frame(HEAD_SIDE_TALK_2, BODY_SIDE, LEGS_SIDE_IDLE, flip=True),
        (7, 3): frame(HEAD_BLINK, BODY_FRONT, still),
    }
    sheet = Image.new("RGBA", (8 * CW, 4 * CH), (0, 0, 0, 0))
    for (c, r), im in cells.items():
        sheet.alpha_composite(im, (c * CW, r * CH))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print("protagonista adulto:", OUT, sheet.size)


if __name__ == "__main__":
    main()
