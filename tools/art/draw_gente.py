"""Gente armada por partes (cabeza + accesorios + cuerpo + piernas), en proporciones adultas, para los
que aparecen poco: el celador del colegio y los del epílogo ("los demás, sin enterarse").
Para los personajes de todos los días están draw_vecinos.py y draw_parque_gente.py (dibujados a mano).

Los niños (Victoria, el niño de Brenda, el pelado de Lisandro) siguen con los muñecos chiquitos de
Kenney a propósito: al lado de los adultos se leen como niños.

Además, los desconocidos (transeunte_0..5) y los guardias del sigilo (guardia_0..2).

Misma hoja que draw_vecinos.py (celdas de 16x26). Salida: assets/characters/<id>.png
Uso: python tools/art/draw_gente.py  (desde la carpeta del proyecto)"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from draw_vecinos import sheet  # noqa: E402

# ---------------------------------------------------------------- Cabezas (8 filas: frente, espalda, costado)
HEADS = {
    "corto": (
        ["...oooo...", "..ohhhho..", "..ohhhho..", "..osssso..", "..oesseo..", "..ossSso..", "...osso...", "...oSSo..."],
        ["...oooo...", "..ohhhho..", "..ohhhho..", "..ohhhho..", "..ohhhho..", "..ohhhho..", "...oSSo...", "...oSSo..."],
        ["...oooo...", "..ohhhho..", "..ohhhhho.", "..ohhssso.", "..ohhseso.", "...osssSo.", "....osso..", "....oSo..."],
    ),
    "engominado": (
        ["...oooo...", "..ohHhho..", "..ohhhHo..", "..osssso..", "..oesseo..", "..ossSso..", "...osso...", "...oSSo..."],
        ["...oooo...", "..ohHhho..", "..ohhHho..", "..ohhhHo..", "..ohhhho..", "..ohhhho..", "...oSSo...", "...oSSo..."],
        ["...oooo...", "..ohhHho..", "..ohHhhho.", "..ohhssso.", "..ohhseso.", "...osssSo.", "....osso..", "....oSo..."],
    ),
    "calvo": (
        ["...oooo...", "..osssso..", "..ohssho..", "..osssso..", "..oesseo..", "..ossSso..", "...osso...", "...oSSo..."],
        ["...oooo...", "..osssso..", "..ohssho..", "..ohhhho..", "..ohhhho..", "..ohhhho..", "...oSSo...", "...oSSo..."],
        ["...oooo...", "..osssso..", "..ohsssso.", "..ohhssso.", "..ohhseso.", "...osssSo.", "....osso..", "....oSo..."],
    ),
    "melena": (  # pelo corto de mujer
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohssssho.", ".ohesseho.", ".ohssSsho.", "..oossoo..", "...oSSo..."],
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", "..ohhhho..", "...oSSo...", "...oSSo..."],
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohhhssso.", ".ohhhseso.", "..ohhsSso.", "...oosso..", "....oSo..."],
    ),
    "largo": (
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohssssho.", ".ohesseho.", ".ohssSsho.", ".ohossoho.", ".ohoSSoho."],
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho."],
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", "ohhhhssso.", "ohhhhseso.", "ohhohsSso.", "ohho.osso.", "oho..oSo.."],
    ),
    "cola": (  # cola de caballo (como Marta)
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohssssho.", ".ohesseho.", ".ohssSsho.", "..oossoo..", "...oSSo..."],
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", "..ohhhho..", "...ohho...", "...ohho..."],
        ["...oooo...", "..ohhhhoo.", ".ohhhhhhho", "ohhohhssso", "oho.ohseso", "oho.ohssSo", ".o...osso.", "....oSSo.."],
    ),
    "afro": (  # Brenda: afro corto y ancho, con canas (H)
        ["..oooooo..", ".ohhHhhho.", "ohhhhhHhho", "ohhsssshho", "ohhesseHho", "ohhssSshho", "..oossoo..", "...oSSo..."],
        ["..oooooo..", ".ohhhHhho.", "ohHhhhhhho", "ohhhhhhHho", "ohhhhhhhho", ".ohhHhhho.", "..ooSSoo..", "...oSSo..."],
        ["..oooooo..", ".ohhHhhho.", "ohhhhhHhho", "ohhhhhssso", "ohhHhhseso", ".ohhhssSso", "..ooosso..", "....oSo..."],
    ),
    "linda": (  # Lilato: pelo largo, ojos grandes con pestañas (e/l), cachetes (r), boca pintada (m)
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohlsslho.", ".ohesseho.", ".ohrmmrho.", ".ohossoho.", ".ohoSSoho."],
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho."],
        ["...oooo...", "..ohhhho..", ".ohhhhhho.", "ohhhhssl..", "ohhhhseso.", "ohhohrsmo.", "ohho.osso.", "oho..oSo.."],
    ),
    "hongo": (  # el honguito de Camila: un casco redondo, flequillo hasta las cejas, raíz oscura (H)
        ["...oooo...", "..oHHHHo..", ".ohhhhhho.", ".ohhhhhho.", ".ohesseho.", ".ohssSsho.", "..oosnoo..", "...oSSo..."],
        ["...oooo...", "..oHHHHo..", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", ".ohhhhhho.", "..oooooo..", "...oSSo..."],
        ["...oooo...", "..oHHHHo..", ".ohhhhhho.", ".ohhhhhhho", ".ohhhhseso", ".ohhhhsSso", "..ooosnso.", "....oSo..."],
    ),
}


def put(rows, i, row):
    rows = list(rows)
    rows[i] = row
    return rows


def head(style, gafas=None, bigote=False, barba=False, gorra=False, pecas=False, nariz=False, audifonos=False):
    f, b, s = HEADS[style]
    if gafas == "claras":
        f = [r.replace("oesseo", "oeooeo") for r in f]
        s = [r.replace("seso", "soeo") for r in s]
    elif gafas == "oscuras":
        f = [r.replace("oesseo", "oeeeeo") for r in f]
        s = [r.replace("seso", "seeo") for r in s]
    if bigote:
        f = put(f, 5, "..obbbbo..")
        s = put(s, 5, "...osbbo..")
    if barba:
        f = put(put(f, 5, "..obSSbo.."), 6, "...obbo...")
        s = put(put(s, 5, "...obbbo.."), 6, "....obbo..")
    if gorra:
        f = put(put(put(f, 0, "...oooo..."), 1, "..oggggo.."), 2, ".oGGGGGGo.")
        b = put(put(put(b, 0, "...oooo..."), 1, "..oggggo.."), 2, "..oGggGo..")
        s = put(put(put(s, 0, "...oooo..."), 1, "..oggggo.."), 2, "..oggggGGo")
    if pecas:
        f = put(f, 5, "..ofsSfo..")
        s = put(s, 5, "...ofssSo.")
    if nariz:
        f = [r.replace("ossSso", "ossnso") for r in f]
        s = [r.replace("osssSo", "osssno") for r in s]
    if audifonos:
        f = put(f, 3, ".ehsssshe.")
        b = put(b, 3, ".ehhhhhhe.")
        s = put(s, 3, s[3][:3] + "e" + s[3][4:])
    return f, b, s


# ---------------------------------------------------------------- Cuerpos (frente, espalda, costado)
# Letras: j saco/chaqueta, i lo de adentro (camisa), t corbata, s piel (manos), d falda/vestido.
BODIES = {
    "saco": (
        [".ojjiijjo.", "ojjjttjjjo", "ojojttjojo", "ojojttjojo", "ojojtTjojo", "osojjjjoso", ".oojjjjoo.", "..ojjjjo.."],
        [".ojjjjjjo.", "ojjjjjjjjo", "ojojjjjojo", "ojojjjjojo", "ojojJJjojo", "osojjjjoso", ".oojjjjoo.", "..ojjjjo.."],
        ["...ojjto..", "..ojjjto..", "..ojjjto..", "..ojjJto..", "..ojjJjo..", "..osjJjo..", "...ojjjo..", "...ojjjo.."],
    ),
    "chaleco": (  # chaleco sobre camiseta (brazos de piel)
        [".oijiijio.", "oiijiijiio", "osojiijoso", "osojiijoso", "osojJJjoso", "osojjjjoso", ".oojjjjoo.", "..ojjjjo.."],
        [".oijjjjio.", "oiijjjjiio", "osojjjjoso", "osojJJjoso", "osojjjjoso", "osojjjjoso", ".oojjjjoo.", "..ojjjjo.."],
        ["...ojio...", "..oijjio..", "..osjjio..", "..osjjio..", "..osjJio..", "..osjjjo..", "...ojjjo..", "...ojjjo.."],
    ),
    "vestido": (
        [".occcccco.", "occcccccco", "ococcccoco", "ococcccoco", "osoddddoso", ".oddddddo.", ".oddddddo.", "oddddddddo"],
        [".occcccco.", "occcccccco", "ococcccoco", "ococcccoco", "osoddddoso", ".oddddddo.", ".oddddddo.", "oddddddddo"],
        ["...occco..", "..occcco..", "..occcco..", "..occcco..", "..osdddo..", "..oddddo..", "..oddddo..", ".oddddddo."],
    ),
    "tetona": (  # Camila: bajita, vestido entero, el busto (C)
        [".occcccco.", "occcccccco", "occCccCcco", "ococcccoco", "osoddddoso", "oddddddddo", ".oooooooo."],
        [".occcccco.", "occcccccco", "occcccccco", "ococcccoco", "osoddddoso", "oddddddddo", ".oooooooo."],
        ["...occco..", "..occccco.", "..occcccCo", "..occcco..", "..osdddo..", ".oddddddo.", ".oooooooo."],
    ),
    "gordo": (  # Guillermo: gordo, muy gordo (14 de ancho), la cadena de oro (y)
        ["..o" + "c" * 8 + "o..", ".o" + "c" * 10 + "o.", "oco" + "c" * 8 + "oco", "oco" + "ccc" + "yy" + "ccc" + "oco",
         "oco" + "c" * 8 + "oco", "oso" + "c" * 8 + "oso", ".oo" + "c" * 8 + "oo.", "...o" + "p" * 6 + "o..."],
        ["..o" + "c" * 8 + "o..", ".o" + "c" * 10 + "o.", "oco" + "c" * 8 + "oco", "oco" + "c" * 8 + "oco",
         "oco" + "C" * 8 + "oco", "oso" + "c" * 8 + "oso", ".oo" + "c" * 8 + "oo.", "...o" + "p" * 6 + "o..."],
        ["....occcco....", "...occcccco...", "...occccccco..", "...ocCccccco..", "...ocCcccccco.", "...osCccccco..",
         "....occcccoo..", "....opppppo..."],
    ),
    "gordo_saco": (  # Lisandro: gordo, saco blanco abierto, camisa roja (i), cadena de oro (y)
        ["..ojjjiijjjo..", ".ojjjjiijjjjo.", "ojojjjyyjjjojo", "ojojjjiijjjojo", "ojojjjjjjjjojo", "osojjjjjjjjoso",
         ".oojjjjjjjjoo.", "...oppppppo..."],
        ["..ojjjjjjjjo..", ".ojjjjjjjjjjo.", "ojojjjjjjjjojo", "ojojjjjjjjjojo", "ojojjJJJJjjojo", "osojjjjjjjjoso",
         ".oojjjjjjjjoo.", "...oppppppo..."],
        ["....ojjjio....", "...ojjjjjio...", "...ojjjjjyio..", "...ojJjjjjiio.", "...ojJjjjjjjo.", "...osJjjjjjo..",
         "....ojjjjjoo..", "....opppppo..."],
    ),
    "chiquita": (  # Lilato: menuda, vestido corto acampanado
        ["..occcco..", ".occcccco.", ".ococcoco.", ".ososcoso.", "..oddddo..", ".oddddddo.", ".oooooooo."],
        ["..occcco..", ".occcccco.", ".ococcoco.", ".ososcoso.", "..oddddo..", ".oddddddo.", ".oooooooo."],
        ["...occo...", "..occcco..", "..occcco..", "..oscco...", "..oddddo..", ".oddddddo.", ".oooooooo."],
    ),
}


def body(kind, corbata=True, bolsas=False, cadena=False):
    f, b, s = BODIES[kind]
    if kind == "saco" and not corbata:
        f = [r.replace("t", "i").replace("T", "i") for r in f]
        s = [r.replace("t", "i") for r in s]
    if cadena:
        f = put(f, 1, f[1][:4] + "yy" + f[1][6:])
    if bolsas:
        f = put(put(f, 6, "BoojjjjooB"), 7, "BBojjjjoBB")
        s = put(put(s, 6, "...ojjjoB."), 7, "...ojjjBB.")
    return f, b, s


def person(h, bd, pal, legs):
    return {"front": h[0] + bd[0], "back": h[1] + bd[1], "side": h[2] + bd[2], "pal": pal, "legs": legs}


SKIN = {"s": (220, 168, 140), "S": (180, 126, 102)}
SKIN_D = {"s": (172, 116, 84), "S": (136, 86, 62)}

PEOPLE = {
    # El celador del colegio: gorra y chaqueta azul oscuro, camisa celeste, bigote, radio al pecho.
    "celador": person(head("corto", bigote=True, gorra=True), body("saco", corbata=False),
                      {**SKIN, "h": (40, 36, 40), "b": (40, 36, 40), "g": (44, 56, 92), "G": (30, 38, 66),
                       "j": (50, 62, 100), "J": (36, 46, 76), "i": (160, 196, 224),
                       "p": (40, 40, 48), "q": (30, 30, 36), "k": (26, 24, 28)}, 6),
    # Brenda, la mamá: negra y alta (la más alta de todos), afro corto con canas, saco mostaza, falda gris.
    "brenda": person(head("afro"), body("vestido"),
                     {"s": (112, 70, 48), "S": (78, 46, 32), "h": (28, 24, 26), "H": (150, 146, 142),
                      "c": (206, 156, 58), "d": (120, 118, 124),
                      "p": (92, 58, 42), "q": (70, 44, 32), "k": (60, 44, 40)}, 8),
    # Mauricio, el papá: bajito y ancho, calvo, barba gris, chaleco de cuero de motociclista.
    "mauricio": person(head("calvo", barba=True), body("chaleco"),
                       {**SKIN, "h": (120, 118, 116), "b": (150, 148, 146), "i": (200, 196, 186),
                        "j": (44, 38, 40), "J": (80, 70, 70),
                        "p": (66, 90, 140), "q": (46, 64, 104), "k": (36, 30, 30)}, 4),
    # El Pecas: flaco, pelirrojo, pecoso, camiseta naranja.
    "pecas": person(head("corto", pecas=True), body("saco", corbata=False),
                    {**SKIN, "h": (196, 96, 44), "f": (176, 104, 70),
                     "j": (226, 128, 70), "J": (190, 96, 50), "i": (226, 128, 70),
                     "p": (66, 90, 140), "q": (46, 64, 104), "k": (220, 216, 208)}, 7),
    # Lilato: chiquita, cara linda (ojazos, pestañas, cachetes, boca pintada), pelo largo negro, vestido rosado
    # (le gusta más el rosado que el morado; siempre muy femenina).
    # Lo de las balas de saliva y la ignorancia no se dibuja: se oye.
    "lilato": person(head("linda"), body("chiquita"),
                     {**SKIN, "h": (30, 26, 32), "l": (20, 16, 22), "r": (236, 140, 140), "m": (200, 40, 70),
                      "c": (238, 120, 160), "d": (238, 120, 160),
                      "p": (240, 200, 210), "q": (214, 170, 182), "k": (220, 70, 130)}, 3),
    # José Mario, el jefe: canoso, traje gris oscuro, corbata azul.
    "josemario": person(head("engominado"), body("saco"),
                        {**SKIN, "h": (90, 90, 96), "H": (140, 140, 146),
                         "j": (70, 72, 80), "J": (52, 54, 62), "i": (226, 224, 218), "t": (50, 80, 150), "T": (36, 58, 112),
                         "p": (70, 72, 80), "q": (52, 54, 62), "k": (24, 22, 26)}, 7),
    # Walter, el que trae el tinto: calvo, camisa amarilla clara, corbata café.
    "walter": person(head("calvo", bigote=True), body("saco"),
                     {**SKIN, "h": (60, 50, 46), "b": (60, 50, 46),
                      "j": (236, 216, 150), "J": (200, 180, 116), "i": (236, 216, 150), "t": (120, 80, 50), "T": (90, 60, 36),
                      "p": (110, 100, 86), "q": (86, 78, 66), "k": (50, 40, 36)}, 6),
    # Nicolás, el que grita: engominado, saco de lana vino sobre camisa rosada.
    "nicolas": person(head("engominado"), body("saco", corbata=False),
                      {**SKIN, "h": (30, 28, 34), "H": (70, 70, 84),
                       "j": (130, 50, 60), "J": (100, 36, 46), "i": (230, 180, 186),
                       "p": (52, 52, 62), "q": (38, 38, 46), "k": (24, 22, 26)}, 7),
    # Eddy: gafas, rubio, camisa celeste, corbata delgada negra.
    "eddy": person(head("corto", gafas="claras"), body("saco"),
                   {**SKIN, "h": (200, 170, 100),
                    "j": (170, 200, 230), "J": (130, 160, 196), "i": (170, 200, 230), "t": (30, 30, 36), "T": (30, 30, 36),
                    "p": (52, 52, 62), "q": (38, 38, 46), "k": (24, 22, 26)}, 7),
    # Lisandro: gordo y bajito, gafas oscuras, engominado, traje blanco, camisa roja, cadena, nariz roja.
    # Un hijo de puta: se le ve en lo blanco del traje.
    "lisandro": person(head("engominado", gafas="oscuras", nariz=True), body("gordo_saco"),
                       {**SKIN, "h": (24, 22, 26), "H": (70, 70, 84), "n": (210, 90, 90),
                        "j": (236, 234, 226), "J": (196, 194, 186), "i": (190, 40, 44), "y": (230, 190, 70),
                        "p": (236, 234, 226), "q": (196, 194, 186), "k": (140, 90, 60)}, 3),
    # Camila: enana, peinado de honguito pintado de mono (raíz oscura), muy tetona, vestido fucsia.
    "camila": person(head("hongo"), body("tetona"),
                     {**SKIN, "h": (246, 214, 96), "H": (96, 66, 46), "n": (220, 40, 60),
                      "c": (214, 64, 130), "C": (160, 40, 96), "d": (214, 64, 130),
                      "p": (48, 30, 58), "q": (36, 22, 44), "k": (20, 18, 22)}, 2),
    # Guillermo: gordo, muy gordo, mono, gafas oscuras, cadena de oro, polo verde.
    "guillermo": person(head("corto", gafas="oscuras"), body("gordo"),
                        {**SKIN, "h": (236, 204, 96), "y": (230, 190, 70),
                         "c": (90, 160, 100), "C": (64, 124, 74),
                         "p": (66, 90, 140), "q": (46, 64, 104), "k": (240, 236, 228)}, 5),
    # Diana Carolina, trotando: cola de caballo, audífonos, chaqueta deportiva turquesa, licra negra.
    "diana": person(head("cola", audifonos=True), body("saco", corbata=False),
                    {**SKIN, "h": (60, 42, 34), "H": (90, 66, 52),
                     "j": (60, 180, 180), "J": (40, 140, 140), "i": (240, 240, 236),
                     "p": (36, 34, 40), "q": (26, 24, 30), "k": (240, 236, 228)}, 6),
    # Raúl, "el millonario": canoso, bigote, guayabera dorada, cadena.
    "raul": person(head("corto", bigote=True), body("saco", corbata=False, cadena=True),
                   {**SKIN_D, "h": (170, 168, 166), "b": (150, 148, 146), "y": (250, 220, 120),
                    "j": (236, 206, 120), "J": (200, 170, 90), "i": (236, 206, 120),
                    "p": (110, 100, 86), "q": (86, 78, 66), "k": (90, 60, 40)}, 6),
    # Alvarito, "el corazón": flaco, pelo largo, chaqueta de jean.
    "alvarito": person(head("largo", barba=True), body("saco", corbata=False),
                       {**SKIN, "h": (60, 44, 36), "b": (80, 60, 48),
                        "j": (100, 130, 180), "J": (76, 100, 146), "i": (40, 38, 44),
                        "p": (40, 38, 44), "q": (30, 28, 34), "k": (24, 22, 26)}, 7),
}

# Los desconocidos (transeúntes, la fila, pedir, el puesto, la fuente): uno por cada fila de Kenney que
# usaban antes (0, 3, 6, 9, 12, 15 → transeunte_0..5). Ver CharacterFrames.stranger_sheet().
PEOPLE.update({
    # Señor de saco café y corbata.
    "transeunte_0": person(head("calvo", bigote=True), body("saco"),
                           {**SKIN, "h": (60, 50, 46), "b": (60, 50, 46), "j": (120, 90, 64), "J": (92, 68, 48),
                            "i": (226, 222, 210), "t": (150, 50, 50), "T": (110, 36, 36),
                            "p": (90, 80, 70), "q": (70, 62, 54), "k": (40, 32, 30)}, 6),
    # Señora de vestido verde, melena.
    "transeunte_1": person(head("melena"), body("vestido"),
                           {**SKIN_D, "h": (40, 32, 34), "c": (80, 140, 110), "d": (80, 140, 110),
                            "p": (150, 104, 80), "q": (120, 80, 62), "k": (60, 40, 40)}, 4),
    # Muchacho de chaqueta roja.
    "transeunte_2": person(head("corto"), body("saco", corbata=False),
                           {**SKIN, "h": (50, 40, 36), "j": (190, 60, 60), "J": (150, 44, 44), "i": (36, 34, 40),
                            "p": (66, 90, 140), "q": (46, 64, 104), "k": (230, 226, 218)}, 7),
    # Obrero de gorra amarilla y overol.
    "transeunte_3": person(head("corto", gorra=True, barba=True), body("chaleco"),
                           {**SKIN_D, "h": (30, 26, 30), "b": (40, 34, 36), "g": (226, 190, 60), "G": (186, 150, 40),
                            "i": (200, 196, 186), "j": (70, 100, 150), "J": (50, 76, 116),
                            "p": (70, 100, 150), "q": (50, 76, 116), "k": (70, 50, 36)}, 6),
    # Señora de pelo largo, saco morado.
    "transeunte_4": person(head("largo"), body("saco", corbata=False),
                           {**SKIN, "h": (110, 70, 50), "j": (120, 80, 140), "J": (92, 60, 110), "i": (230, 226, 216),
                            "p": (40, 40, 50), "q": (30, 30, 38), "k": (30, 24, 28)}, 6),
    # Estudiante de cola de caballo y buzo azul, con gafas.
    "transeunte_5": person(head("cola", gafas="claras"), body("saco", corbata=False),
                           {**SKIN, "h": (30, 26, 30), "H": (60, 56, 64), "j": (60, 90, 160), "J": (44, 66, 124),
                            "i": (60, 90, 160), "p": (110, 110, 120), "q": (86, 86, 96), "k": (230, 226, 218)}, 6),
})

# Los guardias de seguridad de La Empresa (el sueño de sigilo): uniforme azul oscuro, gorra, camisa
# celeste y corbata negra. Tres variantes para que no sean el mismo man repetido.
GUARD = {"g": (34, 40, 66), "G": (24, 28, 48), "j": (44, 52, 84), "J": (32, 38, 62), "i": (170, 200, 228),
         "t": (24, 22, 28), "T": (24, 22, 28), "p": (44, 52, 84), "q": (32, 38, 62), "k": (20, 18, 22)}
PEOPLE.update({
    "guardia_0": person(head("corto", gorra=True), body("saco"), {**SKIN, **GUARD, "h": (40, 34, 30)}, 7),
    "guardia_1": person(head("corto", gorra=True, bigote=True), body("saco"),
                        {**SKIN_D, **GUARD, "h": (30, 26, 30), "b": (30, 26, 30)}, 7),
    "guardia_2": person(head("corto", gorra=True, gafas="oscuras"), body("saco"), {**SKIN, **GUARD, "h": (90, 70, 50)}, 6),
})


def main():
    for pid, p in PEOPLE.items():
        path = Path("assets/characters") / (pid + ".png")
        sheet(p).save(path)
        print(pid, path)


if __name__ == "__main__":
    main()
