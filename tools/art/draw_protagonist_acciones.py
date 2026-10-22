"""Las acciones del protagonista (lo que antes solo contaba el narrador): recibir plata, pagar, el golpe,
caerse y levantarse, toser, recoger, comer, beber, darle de comer a Lukas, el celular, las manos arriba
(la requisa), sacudirse el agua, empujar la bicicleta de Victoria y sentarse a pedir.

Mismo muñeco que draw_protagonist_adult.py (se importan sus partes) en celdas de 32x32: así caben los
objetos (el billete, el celular, el plato, la bicicleta) y el cuerpo tirado en el piso. El muñeco va
centrado (columnas 10-21) y la suela en la fila 28, que es donde queda la del de caminar: el sprite de
las acciones va encima del otro, en la misma posición (ver scripts/player/Acciones.gd).

Salida: assets/characters/protagonist_acciones.png (+ protagonist_acciones.json: las animaciones, con
sus celdas y la velocidad). De frente, salvo la bicicleta (de costado, mirando a la izquierda).
Uso: python tools/art/draw_protagonist_acciones.py  (desde la carpeta del proyecto)"""
import json
import math
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import draw_protagonist_adult as base  # noqa: E402

OUT = Path("assets/characters/protagonist_acciones.png")
META = Path("assets/characters/protagonist_acciones.json")
CELL = 32
SOLE = 28          # la fila de la suela (igual que en la hoja de caminar)
X0 = 10            # donde empieza el muñeco (12 de ancho)

PAL = dict(base.PAL)
PAL.update({
    "g": (110, 170, 96), "G": (66, 116, 64),        # billete (verde, de dos mil y de cinco)
    "c": (232, 196, 70), "C": (168, 128, 40),       # moneda
    "p": (58, 62, 72), "P": (150, 206, 170),        # celular de flecha (y su pantallita)
    "r": (204, 150, 84), "R": (150, 100, 52),       # pan
    "v": (214, 226, 230), "V": (140, 170, 180),     # botella de agua
    "q": (150, 150, 158), "Q": (96, 96, 106),       # plato / cuenco de lata, o lo que recoge
    "d": (120, 170, 230), "D": (180, 214, 250),     # gotas
    "*": (255, 250, 220), "+": (255, 214, 120),     # destello del golpe
    "t": (126, 210, 196), "T": (78, 150, 140),      # la bicicleta: verde agua
    "u": (60, 56, 60), "U": (30, 28, 34),           # llantas
    "a": (210, 210, 214), "A": (150, 150, 158),     # cromado, canasta
})

H_FRONT = base.HEAD_FRONT
H_DOWN = base.HEAD_DOWN_FRONT
H_BLINK = base.HEAD_BLINK
B_FRONT = base.BODY_FRONT
STILL = base.legs_front(0, 0)

# ---------------------------------------------------------------- Cabezas nuevas
H_HIT = [  # el golpe: ojos cerrados, boca abierta (va corrida un pixel: la cabeza se va para atrás)
    ".....oo.....",
    "...oohHo....",
    "..ohhhhhoo..",
    "..ohHhhhho..",
    "..oHssso....",
    "..oSssSo....",
    "..obnnbo....",
    "...obbo.....",
]
H_COUGH = [  # tose: los ojos apretados, la mano tapando la boca
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohHhhhho.",
    "...oHssso...",
    "...oSssSo...",
    "...obSSSso..",
    "....oSSSo...",
]
H_EAT = [  # el pan en la boca
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohHhhhho.",
    "...oHssso...",
    "...oesseo...",
    "...orRrrso..",
    "....oRro....",
]
H_CHEW_1 = H_FRONT[:6] + ["...obnbbo...", "....obbo...."]
H_CHEW_2 = H_FRONT[:6] + ["...obbnbo...", "....obbo...."]
H_DRINK = [  # la cabeza para atrás: se ve la barba de abajo; la botella parada en la boca
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohHhhhho.",
    "...ohhvhho..",
    "...oSsvsSo..",
    "...obbvbbo..",
    "....obVbo...",
]
H_PHONE = [  # el celular en la oreja (la mano de él, del lado derecho de la pantalla)
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohHhhhhop",
    "...oHssso.pP",
    "...oesseo.pp",
    "...obbbbo.s.",
    "....obbo..s.",
]
H_PHONE_BLINK = H_PHONE[:5] + ["...oSssSo.pp"] + H_PHONE[6:]
H_SIDE_L = [  # mira a un lado (la requisa: no mira al policía)
    "......oo....",
    "....oohHo...",
    "...ohhhhhoo.",
    "...ohhhhHho.",
    "....osssHo..",
    "....oeseso..",
    "....obbbbo..",
    ".....obbo...",
]
H_WET = [  # el pelo pegado, escurriendo
    "............",
    "......oo....",
    "....ohhhoo..",
    "...ohhhhhho.",
    "...ohhhhhho.",
    "...oesseo...",
    "...obbbbo...",
    "....obbo....",
]

# ---------------------------------------------------------------- Cuerpos nuevos (10 filas)
B_HAND_OUT = [  # estira la mano derecha (de la pantalla) hacia adelante, la palma arriba
    "...owyywo...",
    "ozzzwyywzzzo",
    "ozzmwyywzzzo",
    "ozZmwYYwzsso",
    "ozzozyyzosso",
    "oZzozyyzoo..",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwz....",
    "...ozZZzo...",
]
B_LOOK = [  # la mano cerca del pecho, mirando lo que tiene
    "...owyywo...",
    "ozzzwyywzzzo",
    "ozzmwyywzzo.",
    "ozZmwYsszZo.",
    "ozzozysszo..",
    "oZzozyyzo...",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwz....",
    "...ozZZzo...",
]
B_POCKET = [  # la mano al bolsillo del jean
    "...owyywo...",
    "ozzzwyywzzzo",
    "ozzmwyywmzzo",
    "ozZmwYYwmZzo",
    "ozzozyyzozzo",
    "oZzozyyzoZzo",
    "oZzozyYzozZo",
    "ossozwyzosZo",
    ".oo.zwwzsso.",
    "...ozZZzoo..",
]
B_FLINCH = [  # el golpe: los brazos se abren, el saco se sacude
    "..owyywo....",
    "ozzwyywzzzo.",
    "ozmwyywmzzo.",
    "ozmwYYwmZzzo",
    "oszoyyzozzZo",
    "osozyyzoZzso",
    "..ozyYzo.oso",
    "..ozwyzo..o.",
    "..zwwz......",
    ".ozZZzo.....",
]
B_DOUBLED = [  # doblado (7 filas): los brazos cruzados en la barriga
    "ozzowyywozzo",
    "ozzmwyywmzzo",
    "ozZmwYYwmZzo",
    ".oZzssyssZo.",
    ".oZzzyyzzZo.",
    "..ozzzwzzo..",
    "...ozZZzo...",
]
B_TO_MOUTH = [  # el brazo derecho sube a la boca
    "...owyywozo.",
    "ozzzwyywzzo.",
    "ozzmwyywzo..",
    "ozZmwYYwzo..",
    "ozzozyyzo...",
    "oZzozyyzo...",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwz....",
    "...ozZZzo...",
]
B_CHEST = [  # la mano en el pecho (después de toser)
    "...owyywo...",
    "ozzzwyywzzzo",
    "ozzmwssszzzo",
    "ozZmwsssZzo.",
    "ozzozyyzzo..",
    "oZzozyyzo...",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwz....",
    "...ozZZzo...",
]
B_HOLD_BREAD = [  # el pan en la mano, a la altura del pecho
    "...owyywo...",
    "ozzzwyywzzzo",
    "ozzmwyywzrRo",
    "ozZmwYYwzRro",
    "ozzozyyzosso",
    "oZzozyyzoo..",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwz....",
    "...ozZZzo...",
]
B_PHONE = [  # el brazo derecho arriba, sosteniendo el celular
    "...owyywozz.",
    "ozzzwyywzzzo",
    "ozzmwyywzzo.",
    "ozZmwYYwzo..",
    "ozzozyyzo...",
    "oZzozyyzo...",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwz....",
    "...ozZZzo...",
]
B_HANDS_UP = [  # la requisa: las manos arriba (los brazos suben por los lados de la cabeza)
    "ozo.wyyw.ozo",
    "ozzzwyywzzzo",
    "o.zmwyywmz.o",
    "..ZmwYYwmZ..",
    "..zozyyzoz..",
    "..ZozyyzoZ..",
    "..zozyYzoz..",
    "..ozzwyzzo..",
    "....zwwz....",
    "...ozZZzo...",
]
B_POINT = [  # señala: el brazo derecho estirado hacia el lado (la mano sigue afuera del muñeco)
    "...owyywo...",
    "ozzzwyywzzzz",
    "ozzmwyywmZZZ",
    "ozZmwYYwmZoo",
    "ozzozyyzozo.",
    "oZzozyyzoo..",
    "oZzozyYzo...",
    "ossozwyzo...",
    ".oo.zwwz....",
    "...ozZZzo...",
]
B_SHRUG = [  # se encoge de hombros: los hombros arriba, las manos abiertas a los lados
    "..zowyywoz..",
    "ozzzwyywzzzo",
    "ozzmwyywmzzo",
    "ozZmwYYwmZzo",
    "ozzozyyzozzo",
    "sZzozyyzoZzs",
    "ssZozyYzoZss",
    ".o.ozwyzo.o.",
    "....zwwz....",
    "...ozZZzo...",
]
ARMS_UP = [  # las mangas y las manos por encima de los hombros (van arriba de la cabeza)
    ".ss......ss.",
    ".ss......ss.",
    ".zo......oz.",
    ".zo......oz.",
    ".zo......oz.",
    ".zo......oz.",
    ".zo......oz.",
    ".zo......oz.",
]

LEGS_BENT = [
    "...ojjJjo...",
    "..ojjo.ojo..",
    "..ojJo.oJo..",
    "..ojJo.oJo..",
    "..ojJo.oJo..",
    "..ojJo.oJo..",
    ".okkko.oxxxo",
    ".ooooo.ooooo",
]
LAP_REACH = [  # agachado, la mano derecha estirada hasta el piso
    "ossozZZzozo.",
    ".oo.zjjz.oz.",
    "..ojjJJjjoz.",
    ".ojJo..ojJoz",
    ".ojJo..ojJoz",
    ".ojJo..ojJss",
    ".okkko.oxxss",
    ".ooooo.oooo.",
]
LAP_BOWL = [  # agachado, con el cuenco en las dos manos, casi en el piso
    "o.oozZZzoo.o",
    ".ozzzjjzzzo.",
    "..ojsqqsjo..",
    ".ojJqQQqJo..",
    ".ojJoqqoJo..",
    ".ojJo..ojJo.",
    ".okkko.oxxxo",
    ".ooooo.ooooo",
]
LAP_BOWL_DOWN = [  # el cuenco ya en el piso, las manos subiendo
    "ossozZZzosso",
    ".oo.zjjz.oo.",
    "..ojjJJjjo..",
    ".ojJo..ojJo.",
    ".ojJo..ojJo.",
    ".ojJoqqojJo.",
    ".okkqQQqxxxo",
    ".ooooqqoooo.",
]


def rows_img(rows: list, w: int = 12) -> Image.Image:
    im = Image.new("RGBA", (w, len(rows)), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        assert len(r) == w, (r, len(r))
        for x, ch in enumerate(r):
            c = PAL[ch]
            if c:
                im.putpixel((x, y), c + (255,))
    return im


def figure(head, body, legs, dx=0, dy=0, flip=False) -> Image.Image:
    """El muñeco en la celda de 32: la suela en SOLE (dy lo sube o lo baja), centrado (dx lo corre)."""
    rows = head + body + legs
    fig = rows_img(rows)
    if flip:
        fig = fig.transpose(Image.FLIP_LEFT_RIGHT)
    cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    cell.alpha_composite(fig, (X0 + dx, SOLE + 1 - len(rows) + dy))
    return cell


def over(cell: Image.Image, rows: list, x: int, y: int) -> Image.Image:
    """Pega un dibujito (filas de PAL, '.' transparente) en la celda."""
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            c = PAL.get(ch)
            if c and 0 <= x + i < CELL and 0 <= y + j < CELL:
                cell.putpixel((x + i, y + j), c + (255,))
    return cell


def rotated(cell: Image.Image, deg: float, dx=0, dy=0) -> Image.Image:
    """El muñeco caído: girado sobre los pies (sin suavizar: es pixel art)."""
    fig = cell.crop(cell.getbbox())
    r = fig.rotate(deg, resample=Image.NEAREST, expand=True)
    out = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    out.alpha_composite(r, ((CELL - r.width) // 2 + dx, SOLE + 1 - r.height + dy))
    return out


def bike(cell: Image.Image, x: int, y: int) -> Image.Image:
    """La bicicleta de Victoria, de costado (la canasta adelante, a la izquierda): 22x13."""
    art = [
        "..aa..................",
        ".AaAA.........tt......",
        ".AaAa.........Tto.....",
        "..oa.........oo.......",
        "...ta.......tT........",
        "..uutt.....tTa........",
        ".u..utTTTTTTt.uuu.....",
        "u....u.tT..tTu...u....",
        "u..a.u..tTtTTu.a.u....",
        "u....u...oaa.u...u....",
        ".u..u.........u.u.....",
        "..uu...........uu.....",
        "......................",
    ]
    return over(cell, art, x, y)


def drops(cell: Image.Image, pts: list) -> Image.Image:
    for (x, y) in pts:
        over(cell, ["d", "D"], x, y)
    return cell


def build():
    cells = {}

    def put(name, im):
        cells[name] = im

    # La plata: estira la mano, le cae el billete, lo mira, al bolsillo.
    put("mano", figure(H_FRONT, B_HAND_OUT, STILL))
    put("billete", over(figure(H_FRONT, B_HAND_OUT, STILL), ["gGg", "Ggg"], X0 + 9, 12))
    put("mira_billete", over(figure(H_DOWN, B_LOOK, STILL), ["gGg", "ggG"], X0 + 6, 11))
    put("bolsillo", figure(H_BLINK, B_POCKET, STILL))
    put("moneda", over(figure(H_FRONT, B_HAND_OUT, STILL), ["cC"], X0 + 10, 13))
    # El golpe y la caída.
    put("golpe", over(figure(H_HIT, B_FLINCH, STILL, dx=1), [".*.", "*+*", ".*."], X0 + 3, 7))
    put("doblado", figure(H_DOWN, B_DOUBLED, LEGS_BENT, dy=0))
    put("se_endereza", figure(H_BLINK, B_CHEST, STILL))
    stand_hit = figure(H_HIT, base.BODY_FRONT, STILL)
    put("cae_1", rotated(stand_hit, 35, dx=-2))
    lying = rotated(figure(H_HIT, base.BODY_FRONT, STILL), 90, dx=0, dy=0)
    put("piso", lying)
    put("piso_mira", rotated(figure(H_FRONT, base.BODY_FRONT, STILL), 90))
    put("sentado", figure(H_DOWN, base.BODY_FRONT[:8], base.LAP_CROUCH))
    put("sacude", figure(H_DOWN, base.BODY_FRONT, STILL))
    # La tos.
    put("tos_1", figure(H_COUGH, B_TO_MOUTH, STILL))
    put("tos_2", figure(H_COUGH, B_DOUBLED, LEGS_BENT))
    put("tos_3", figure(H_COUGH, B_DOUBLED, LEGS_BENT, dy=1))
    put("tos_fin", figure(H_BLINK, B_CHEST, STILL))
    # Recoger: se agacha, la mano al piso, se para mirando lo que tiene.
    put("agacha", figure(H_DOWN, base.BODY_FRONT[:8], base.LAP_CROUCH))
    put("mano_piso", figure(H_DOWN, base.BODY_FRONT[:8], LAP_REACH))
    put("mira_cosa", over(figure(H_DOWN, B_LOOK, STILL), ["qQ", "Qq"], X0 + 6, 12))
    # Comer y beber.
    put("pan_boca", figure(H_EAT, B_TO_MOUTH, STILL))
    put("mastica_1", figure(H_CHEW_1, B_HOLD_BREAD, STILL))
    put("mastica_2", figure(H_CHEW_2, B_HOLD_BREAD, STILL))
    put("traga", figure(H_BLINK, B_HOLD_BREAD, STILL))
    put("bebe_1", over(figure(H_FRONT, B_TO_MOUTH, STILL), ["v", "V", "v", "v"], X0 + 6, 5))
    put("bebe_2", over(figure(H_DRINK, B_TO_MOUTH, STILL), ["v", "v", "V"], X0 + 6, 2))
    # Darle de comer a Lukas: agachado con el cuenco, lo deja, se para.
    put("cuenco", figure(H_DOWN, base.BODY_FRONT[:8], LAP_BOWL))
    put("cuenco_piso", figure(H_DOWN, base.BODY_FRONT[:8], LAP_BOWL_DOWN))
    # El celular.
    put("saca_cel", over(figure(H_FRONT, B_LOOK, STILL), ["p", "P", "p"], X0 + 7, 11))
    put("cel_oreja", figure(H_PHONE, B_PHONE, STILL))
    put("cel_oreja_2", figure(H_PHONE_BLINK, B_PHONE, STILL, dy=1))
    # Las manos arriba (la requisa).
    up = figure(H_FRONT, B_HANDS_UP, STILL)
    over(up, ARMS_UP, X0, SOLE + 1 - 26 - 8 + 8)
    put("manos_arriba", up)
    up2 = figure(H_SIDE_L, B_HANDS_UP, STILL)
    over(up2, ARMS_UP, X0, SOLE + 1 - 26 - 8 + 8)
    put("manos_arriba_2", up2)
    # Mojado y sacudiéndose.
    wet = drops(figure(H_WET, base.BODY_FRONT, STILL), [(X0 + 2, 9), (X0 + 9, 11), (X0 + 4, 20)])
    put("mojado", wet)
    put("sacude_1", drops(figure(H_WET, base.BODY_FRONT, STILL, dx=-1), [(X0 - 3, 5), (X0 + 14, 8), (X0 - 2, 14), (X0 + 15, 16)]))
    put("sacude_2", drops(figure(H_WET, base.BODY_FRONT, STILL, dx=1), [(X0 - 1, 3), (X0 + 13, 4), (X0 - 4, 12), (X0 + 16, 13), (X0 + 6, 0)]))
    # Los gestos (él no habla: asiente, niega, señala, se encoge de hombros, acaricia a Lukas).
    put("asiente", figure(H_DOWN, base.BODY_FRONT, STILL))
    put("mira_izq", figure(H_SIDE_L, base.BODY_FRONT, STILL))
    put("mira_der", figure([r[::-1] for r in H_SIDE_L], base.BODY_FRONT, STILL))
    pt = figure(H_FRONT, B_POINT, STILL)
    over(pt, ["zzss", "ZZss"], X0 + 12, SOLE + 1 - 26 + 9)
    put("senala", pt)
    put("hombros", figure(H_FRONT, B_SHRUG, STILL, dy=0))
    put("acaricia", over(figure(H_DOWN, base.BODY_FRONT[:8], LAP_REACH), ["s"], X0 + 11, SOLE - 2))
    # La bicicleta (de costado, mirando a la izquierda): la empuja del manubrio, caminando al lado.
    for k, (body, legs, d) in enumerate([(base.BODY_SIDE, base.LEGS_SIDE_IDLE, 0), (base.BODY_SIDE_SWING, base.LEGS_SIDE_STEP, -1)]):
        c = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        bike(c, 5, 17)  # la bici va del otro lado de él: primero ella
        c.alpha_composite(figure(base.HEAD_SIDE, body, legs, dx=6, dy=d, flip=True))
        # el brazo: del hombro al manubrio (la manga y la mano)
        sx, sy = X0 + 6 + 4, SOLE + 1 - 26 + 9 + d
        hx, hy = 8, 18
        n = max(abs(hx - sx), abs(hy - sy))
        for i in range(n + 1):
            x = round(sx + (hx - sx) * i / n)
            y = round(sy + (hy - sy) * i / n)
            col = PAL["s"] if i >= n - 1 else (PAL["Z"] if i % 3 == 0 else PAL["z"])
            c.putpixel((x, y), col + (255,))
            if i < n - 1:
                c.putpixel((x, y + 1), PAL["o"] + (255,))
        put("bici_%d" % k, c)
    return cells


ANIMS = {
    # nombre: [celdas, cuadros por segundo, se repite]
    "plata": [["mano", "billete", "mira_billete", "mira_billete", "bolsillo"], 6.0, False],
    "plata_moneda": [["mano", "moneda", "bolsillo"], 6.0, False],
    "pagar": [["bolsillo", "billete", "mano"], 6.0, False],
    "golpe": [["golpe", "doblado", "doblado", "se_endereza"], 7.0, False],
    "caer": [["golpe", "cae_1", "piso", "piso", "piso_mira", "sentado", "sacude"], 6.0, False],
    "tos": [["tos_1", "tos_2", "tos_3", "tos_2", "tos_3", "tos_fin"], 7.0, False],
    "tos_corta": [["tos_1", "tos_2", "tos_fin"], 7.0, False],
    "recoger": [["agacha", "mano_piso", "agacha", "mira_cosa"], 7.0, False],
    "comer": [["pan_boca", "mastica_1", "mastica_2", "mastica_1", "mastica_2", "traga"], 6.0, False],
    "beber": [["bebe_1", "bebe_2", "bebe_2", "bebe_1"], 5.0, False],
    "dar_comida": [["agacha", "cuenco", "cuenco_piso", "agacha"], 5.0, False],
    "celular": [["saca_cel", "cel_oreja"], 5.0, False],
    "celular_hablando": [["cel_oreja", "cel_oreja", "cel_oreja_2"], 2.0, True],
    "manos_arriba": [["manos_arriba", "manos_arriba", "manos_arriba_2"], 2.0, True],
    "sacudirse": [["mojado", "sacude_1", "sacude_2", "sacude_1", "sacude_2", "mojado"], 9.0, False],
    "bici": [["bici_0", "bici_1"], 5.0, True],
    "en_el_piso": [["piso"], 1.0, True],
    "levantarse": [["piso_mira", "sentado", "sacude"], 5.0, False],
    "asentir": [["asiente", "mano", "asiente", "bolsillo"], 6.0, False],
    "negar": [["mira_izq", "mira_der", "mira_izq", "mira_der", "bolsillo"], 7.0, False],
    "senalar": [["senala", "senala", "senala", "senala", "bolsillo"], 4.0, False],
    "encogerse": [["hombros", "hombros", "hombros", "bolsillo"], 4.0, False],
    "acariciar": [["agacha", "acaricia", "mano_piso", "acaricia", "mano_piso", "agacha"], 5.0, False],
}


def main():
    cells = build()
    names = list(cells)
    cols = 8
    rows = math.ceil(len(names) / cols)
    sheet = Image.new("RGBA", (cols * CELL, rows * CELL), (0, 0, 0, 0))
    index = {}
    for i, n in enumerate(names):
        sheet.alpha_composite(cells[n], ((i % cols) * CELL, (i // cols) * CELL))
        index[n] = [i % cols, i // cols]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    meta = {"cell": CELL, "anims": {}}
    for a, (seq, fps, loop) in ANIMS.items():
        meta["anims"][a] = {"cells": [index[c] for c in seq], "fps": fps, "loop": loop}
    META.write_text(json.dumps(meta, indent=1), encoding="utf-8")
    print("acciones:", OUT, sheet.size, len(names), "celdas,", len(ANIMS), "animaciones")


if __name__ == "__main__":
    main()
