"""La gente del Parque de San Judas, en proporciones adultas (como los vecinos del barrio):
  Padre Hernando  sotana negra, alzacuellos, gafas, pelo gris.
  Doña Fabiola    la de la olla comunitaria: pañoleta azul, canas, blusa lila, delantal verde.
  Don Aurelio     el de la tienda La Esperanza: bigote negro grueso, camisa verde a cuadros, delantal café.
  Doña Leonor     la de las flores: moño blanco, chal rosado, vestido largo, una flor en la mano.
  Don Efraín      el de los cachivaches: sombrero, gafas, chivera blanca, chaleco, pañuelo rojo.
  El Mono         el músico de la glorieta: rubio, barba, camiseta negra y la guitarra.
  Don Octavio     (npc "viejos") el del ajedrez: boina, saco gris, gafas.
  Don Ramiro      (npc "viejo2") el otro del ajedrez: sombrero aguadeño y ruana.

Usa la misma hoja que draw_vecinos.py (celdas de 16x26, ver ahí). Salida: assets/characters/<id>.png
Uso: python tools/art/draw_parque_gente.py  (desde la carpeta del proyecto)"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from draw_vecinos import sheet  # noqa: E402

PADRE = {
    "pal": {
        "s": (220, 168, 140), "S": (180, 126, 102),
        "g": (150, 148, 150), "G": (112, 110, 114),   # pelo gris
        "w": (236, 234, 228),                         # alzacuellos
        "a": (58, 54, 66), "A": (82, 78, 94),         # sotana
        "p": (58, 54, 66), "q": (46, 42, 52),
        "k": (30, 26, 30),
    },
    "front": [
        "...oooo...",
        "..oggggo..",
        "..ogssgo..",
        "..oeooeo..",
        "..ossSso..",
        "..osssso..",
        "...osso...",
        "...owwo...",
        ".oaaaaaao.",
        "oaaaaaaaao",
        "oaoaAaaoao",
        "oaoaAaaoao",
        "oaoaAaaoao",
        "osoaAaaoso",
        ".ooaAaaoo.",
        "..oaAaao..",
        "..oaAaao..",
        "..oaAaao..",
        "..oaaaao..",
    ],
    "back": [
        "...oooo...",
        "..oggggo..",
        "..oggggo..",
        "..oggggo..",
        "..oggggo..",
        "..oGggGo..",
        "...oSSo...",
        "...owwo...",
        ".oaaaaaao.",
        "oaaaaaaaao",
        "oaoaaaaoao",
        "oaoaaaaoao",
        "oaoaAAaoao",
        "osoaaaaoso",
        ".ooaaaaoo.",
        "..oaaaao..",
        "..oaaaao..",
        "..oaaaao..",
        "..oaaaao..",
    ],
    "side": [
        "...oooo...",
        "..oggggo..",
        "..ogggsso.",
        "..oggsoeo.",
        "..oggsssSo",
        "...ossso..",
        "....osso..",
        "....owo...",
        "...oaaao..",
        "..oaaaaao.",
        "..oaaAaao.",
        "..oaaAaao.",
        "..oaaAaao.",
        "..osaAaao.",
        "..oaaAaao.",
        "..oaaAaao.",
        "..oaaAaao.",
        "..oaaAaao.",
        "..oaaaaao.",
    ],
    "legs": 3,
}

FABIOLA = {
    "pal": {
        "s": (200, 140, 106), "S": (162, 104, 78),
        "b": (110, 150, 196), "B": (80, 116, 160),    # pañoleta
        "h": (180, 176, 172),                          # canas
        "l": (150, 112, 168),                          # blusa lila
        "v": (88, 140, 92), "V": (62, 106, 68),        # delantal verde
        "p": (52, 48, 56), "q": (38, 34, 42),
        "k": (40, 34, 38),
    },
    "front": [
        "...oooo...",
        "..obbbbo..",
        ".obBbbBbo.",
        "..ohssho..",
        "..oesseo..",
        "..ossSso..",
        "...osso...",
        "...oSSo...",
        ".ollllllo.",
        "olllvvlllo",
        "olovvvvolo",
        "olovvvvolo",
        "olovVvvolo",
        "osovvvvoso",
        ".oovvvvoo.",
        "..ovvvvo..",
        "..ovvVvo..",
        "..oppppo..",
    ],
    "back": [
        "...oooo...",
        "..obbbbo..",
        ".obbbbbbo.",
        "..ohhhho..",
        "..ohhhho..",
        "..ohhhho..",
        "...oSSo...",
        "...oSSo...",
        ".ollllllo.",
        "ollllllllo",
        "olollllolo",
        "olovVVvolo",
        "olollllolo",
        "osolllloso",
        ".oolllloo.",
        "..ollllo..",
        "..ollllo..",
        "..oppppo..",
    ],
    "side": [
        "...oooo...",
        "..obbbbbo.",
        "obbbbbbbo.",
        "..ohhssso.",
        "..ohhseso.",
        "...ohsSso.",
        "....osso..",
        "....oSo...",
        "..olllo...",
        ".ollllvo..",
        ".ollllvvo.",
        ".olllvvvo.",
        ".olllvvvo.",
        ".oslvvvvo.",
        "..ovvvvvo.",
        "..ovvvvvo.",
        "..ovvVvvo.",
        "...opppo..",
    ],
    "legs": 3,
}

AURELIO = {
    "pal": {
        "s": (210, 152, 118), "S": (170, 112, 88),
        "h": (40, 36, 40), "H": (110, 108, 112),       # pelo negro con canas
        "c": (92, 132, 92), "C": (60, 96, 64),         # camisa verde a cuadros
        "a": (150, 110, 72), "A": (116, 82, 52),       # delantal café
        "p": (96, 96, 104), "q": (70, 70, 78),         # pantalón gris
        "k": (44, 36, 36),
    },
    "front": [
        "...oooo...",
        "..ohhhho..",
        "..ohHhho..",
        "..osssso..",
        "..oesseo..",
        "..ohhhho..",
        "...osso...",
        "...oSSo...",
        ".occaacco.",
        "oCcaaaacCo",
        "ocoaaaaoco",
        "oCoaaaaoCo",
        "ocoaAaaoco",
        "osoaaaaoso",
        ".ooaaaaoo.",
        "..oaaaao..",
        "..oaaaao..",
    ],
    "back": [
        "...oooo...",
        "..ohhhho..",
        "..ohhhho..",
        "..ohHHho..",
        "..ohhhho..",
        "..ohhhho..",
        "...oSSo...",
        "...oSSo...",
        ".occcccco.",
        "oCccccccCo",
        "ocoaccaoco",
        "oCocaacoCo",
        "ococcccoco",
        "osoaAAaoso",
        ".ooccccoo.",
        "..occcco..",
        "..occcco..",
    ],
    "side": [
        "...oooo...",
        "..ohhhho..",
        "..ohhhhho.",
        "..ohhssso.",
        "..ohhseso.",
        "...oshhho.",
        "....osso..",
        "....oSo...",
        "...occao..",
        "..occcaao.",
        "..oCccaao.",
        "..occcaao.",
        "..oCccaao.",
        "..osccaao.",
        "...occaao.",
        "...occaao.",
        "...occao..",
    ],
    "legs": 5,
}

LEONOR = {
    "pal": {
        "s": (226, 180, 156), "S": (186, 138, 116),
        "g": (232, 230, 226), "G": (192, 190, 188),    # pelo blanco
        "r": (220, 140, 160),                          # chal rosado
        "d": (96, 98, 150), "f": (230, 200, 90),       # vestido / florcitas
        "F": (214, 60, 70),                            # el clavel
        "p": (196, 160, 140), "q": (166, 130, 112),    # medias
        "k": (60, 44, 48),
    },
    "front": [
        "....oo....",
        "...oggo...",
        "..oggggo..",
        "..ogssgo..",
        "..oesseo..",
        "..ossSso..",
        "...osso...",
        "...oSSo...",
        ".orrrrrro.",
        "orrrddrrro",
        "oroddddoro",
        "orodfddoro",
        "osoddfdoFo",
        ".ooddddoo.",
        "..oddfdo..",
        ".odddddddo",
        ".odfddddo.",
        "..oooooo..",
    ],
    "back": [
        "....oo....",
        "...oggo...",
        "..oggggo..",
        "..oggggo..",
        "..ogGGgo..",
        "..oggggo..",
        "...oSSo...",
        "...oSSo...",
        ".orrrrrro.",
        "orrrrrrrro",
        "ororrrroro",
        "orodrrdoro",
        "osoddddoso",
        ".ooddddoo.",
        "..oddddo..",
        ".odddddddo",
        ".oddddddo.",
        "..oooooo..",
    ],
    "side": [
        "..oo......",
        ".oggo.....",
        "..oggggo..",
        "..oggssso.",
        "..oggseso.",
        "...ogsSso.",
        "....osso..",
        "....oSo...",
        "...orrro..",
        "..orrrrro.",
        "..orrdrro.",
        "..ordddro.",
        "..osddFdo.",
        "...odddFo.",
        "...oddddo.",
        "..odddddo.",
        "..odfddddo",
        "..oooooooo",
    ],
    "legs": 3,
}

EFRAIN = {
    "pal": {
        "s": (214, 160, 128), "S": (176, 120, 94),
        "m": (120, 92, 64), "M": (92, 68, 46),         # sombrero
        "g": (226, 224, 218),                          # chivera / canas
        "r": (190, 56, 52),                            # pañuelo
        "c": (170, 190, 210), "C": (130, 150, 172),    # camisa azul clara
        "v": (110, 82, 60), "V": (84, 60, 44),         # chaleco
        "p": (112, 90, 66), "q": (86, 68, 50),
        "k": (44, 36, 34),
    },
    "front": [
        "...oooo...",
        "..ommmmo..",
        ".oMMMMMMo.",
        "..osssso..",
        "..oeooeo..",
        "..ossSso..",
        "...oggo...",
        "...orro...",
        ".ocvccvco.",
        "ocvvccvvco",
        "ocovccvoco",
        "ocovccvoco",
        "osovvvvoso",
        ".oovvvvoo.",
        "..ocCCco..",
        "..occcco..",
    ],
    "back": [
        "...oooo...",
        "..ommmmo..",
        ".oMMMMMMo.",
        "..oggggo..",
        "..oggggo..",
        "..oggggo..",
        "...oSSo...",
        "...orro...",
        ".ovvvvvvo.",
        "ocvvvvvvco",
        "ocovvvvoco",
        "ocovVVvoco",
        "osovvvvoso",
        ".oovvvvoo.",
        "..occcco..",
        "..occcco..",
    ],
    "side": [
        "...oooo...",
        "..ommmmo..",
        ".oMMMMMMMo",
        "..ogssso..",
        "..oggsoeo.",
        "...ogssSo.",
        "....oggo..",
        "....oro...",
        "...ovvco..",
        "..ocvvco..",
        "..ocvvco..",
        "..ocvvco..",
        "..osvvco..",
        "...ovvco..",
        "...occco..",
        "...occco..",
    ],
    "legs": 6,
}

MONO = {
    "pal": {
        "s": (226, 172, 140), "S": (186, 130, 104),
        "y": (226, 196, 110), "Y": (184, 150, 72),     # rubio / barba
        "t": (50, 48, 56),                             # camiseta negra
        "g": (176, 112, 60), "G": (130, 80, 40),       # guitarra
        "n": (40, 26, 22),                             # la boca de la guitarra
        "j": (70, 96, 148),
        "k": (30, 30, 34),                             # correa
        "p": (70, 96, 148), "q": (48, 66, 108),
    },
    "front": [
        "...oooo...",
        "..oyyyyo..",
        ".oyyyyyyo.",
        ".oyssssyo.",
        ".oyesseyo.",
        "..oYssYo..",
        "...oYYo...",
        "...oSSo...",
        ".otttttto.",
        "otttttGgto",
        "ototgGgoto",
        "otoggggoto",
        "otognggoto",
        "osoggggoso",
        ".ooggggoo.",
        "..ojjjjo..",
        "..ojjjjo..",
    ],
    "back": [
        "...oooo...",
        "..oyyyyo..",
        ".oyyyyyyo.",
        ".oyyyyyyo.",
        ".oyyYyyyo.",
        "..oyyyyo..",
        "...oSSo...",
        "...oSSo...",
        ".otttttto.",
        "otttttktto",
        "ototkttoto",
        "otoktttoto",
        "otottttoto",
        "osottttoso",
        ".oottttoo.",
        "..ojjjjo..",
        "..ojjjjo..",
    ],
    "side": [
        "...oooo...",
        "..oyyyyo..",
        ".oyyyyyyo.",
        ".oyyyssso.",
        ".oyyyseso.",
        "..oyyYYso.",
        "...oYYYo..",
        "....oSo...",
        "...ottto..",
        "..otttGgo.",
        "..ottgGgo.",
        "..otgggggo",
        "..otgnggo.",
        "..osgggggo",
        "...ogggo..",
        "...ojjjo..",
        "...ojjjo..",
    ],
    "legs": 5,
}

OCTAVIO = {
    "pal": {
        "s": (218, 166, 136), "S": (178, 124, 100),
        "b": (112, 48, 58), "B": (84, 34, 44),          # boina
        "g": (200, 198, 196),                          # canas
        "w": (226, 222, 212),                          # camisa
        "c": (128, 126, 134), "C": (98, 96, 104),      # saco gris
        "p": (78, 76, 86), "q": (60, 58, 66),
        "k": (40, 34, 36),
    },
    "front": [
        "..........",
        "..obbbbo..",
        ".obbbbbbo.",
        "..ogssgo..",
        "..oeooeo..",
        "..ossSso..",
        "...osso...",
        "...oSSo...",
        ".occwwcco.",
        "occcwwccco",
        "ococwwcoco",
        "ococcccoco",
        "ococCCcoco",
        "osoccccoso",
        ".ooccccoo.",
        "..occcco..",
        "..oCCCCo..",
    ],
    "back": [
        "..........",
        "..obbbbo..",
        ".obbbbbbo.",
        "..oggggo..",
        "..oggggo..",
        "..oggggo..",
        "...oSSo...",
        "...oSSo...",
        ".occcccco.",
        "occcccccco",
        "ococcccoco",
        "ococcccoco",
        "ocoCccCoco",
        "osoccccoso",
        ".ooccccoo.",
        "..occcco..",
        "..oCCCCo..",
    ],
    "side": [
        "..........",
        "..obbbbo..",
        ".obbbbbbbo",
        "..oggssso.",
        "..oggsoeo.",
        "...osssSo.",
        "....osso..",
        "....oSo...",
        "...occwo..",
        "..occcwo..",
        "..occcco..",
        "..occCco..",
        "..occCco..",
        "..osccco..",
        "...occco..",
        "...occco..",
        "...oCCCo..",
    ],
    "legs": 5,
}

RAMIRO = {
    "pal": {
        "s": (196, 138, 104), "S": (156, 100, 76),
        "w": (230, 224, 206), "W": (200, 194, 176),    # sombrero aguadeño
        "k": (40, 34, 36),                             # cinta / zapatos
        "g": (200, 198, 196),
        "r": (150, 104, 70), "R": (112, 74, 48),       # ruana
        "p": (110, 86, 64), "q": (84, 64, 48),
    },
    "front": [
        "...oooo...",
        "..owwwwo..",
        "..okkkko..",
        "oWWWWWWWWo",
        "..osssso..",
        "..oesseo..",
        "..oSssSo..",
        "...osso...",
        ".orrrrrro.",
        "orrrrrrrro",
        "orrrRRrrro",
        "orrrRRrrro",
        "orrrrrrrro",
        "oRrrrrrrRo",
        "oooooooooo",
        "..oppppo..",
        "..oppppo..",
    ],
    "back": [
        "...oooo...",
        "..owwwwo..",
        "..okkkko..",
        "oWWWWWWWWo",
        "..oggggo..",
        "..oggggo..",
        "...oSSo...",
        "...oSSo...",
        ".orrrrrro.",
        "orrrrrrrro",
        "orrrrrrrro",
        "orrrrrrrro",
        "orrrrrrrro",
        "oRrrrrrrRo",
        "oooooooooo",
        "..oppppo..",
        "..oppppo..",
    ],
    "side": [
        "...oooo...",
        "..owwwwo..",
        "..okkkko..",
        ".oWWWWWWWo",
        "..ogsssso.",
        "..ogsseso.",
        "...osssSo.",
        "....osso..",
        "..orrrro..",
        ".orrrrrro.",
        ".orrrRrro.",
        ".orrrRrro.",
        ".orrrrrro.",
        ".oRrrrrRo.",
        ".oooooooo.",
        "...opppo..",
        "...opppo..",
    ],
    "legs": 4,
}

PEOPLE = {"padre": PADRE, "fabiola": FABIOLA, "aurelio": AURELIO, "leonor": LEONOR, "efrain": EFRAIN,
          "mono": MONO, "viejos": OCTAVIO, "viejo2": RAMIRO}


def main():
    for pid, p in PEOPLE.items():
        path = Path("assets/characters") / (pid + ".png")
        sheet(p).save(path)
        print(pid, path)


if __name__ == "__main__":
    main()
