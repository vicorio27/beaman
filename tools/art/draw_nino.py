"""Alejandro, el pelao de la calle (scripts/systems/Nino.gd), y la foto de cuando el protagonista tenía su edad.
  assets/characters/nino.png          la hoja del niño (celdas de 16x26, como los adultos, pero más bajito):
                                      flaco, pelo al rape, una camiseta roja desteñida que le queda grande,
                                      pantaloneta, chanclas
  assets/characters/victoria.png      Victoria (doce años): más alta que Alejandro, más bajita que los grandes;
                                      pelo largo castaño con el moño morado (como en su retrato), el saco
                                      morado del colegio con el cuello blanco, la falda gris, medias blancas
                                      hasta la rodilla y zapatos negros
  assets/items/recuerdo_infancia.png  la foto del colegio: él a los ocho, peinado con agua, de manga larga
                                      en pleno calor, parado de lado (listo para correr)
Uso: python tools/art/draw_nino.py  (desde la carpeta del proyecto)"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from draw_vecinos import sheet  # noqa: E402
from draw_gente import head, body, SKIN_D  # noqa: E402
import draw_recuerdos as R  # noqa: E402


def nino():
    h = head("corto")
    f, b, s = body("saco", corbata=False)
    keep = [0, 1, 2, 5, 6]  # un cuerpo más corto: es un niño
    kid = {"front": h[0] + [f[i] for i in keep], "back": h[1] + [b[i] for i in keep],
           "side": h[2] + [s[i] for i in keep],
           "pal": {**SKIN_D, "h": (36, 30, 30), "j": (176, 84, 76), "J": (140, 62, 58), "i": (176, 84, 76),
                   "p": (70, 74, 96), "q": (172, 116, 84), "k": (90, 110, 150)},
           "legs": 3}
    sheet(kid).save(Path("assets/characters") / "nino.png")


VICTORIA = {
    "front": [
        "...oooo...",
        ".Bohhhho..",
        ".ohhhhhho.",
        ".ohssssho.",
        ".ohesseho.",
        ".ohrssrho.",
        ".ohossoho.",
        ".ohoSSoho.",
        ".occwwcco.",
        "occcccccco",
        "ococcccoco",
        "ososccoso.",
        ".oddddddo.",
        "oddddddddo",
    ],
    "back": [
        "...oooo...",
        ".Bohhhho..",
        ".ohhhhhho.",
        ".ohhhhhho.",
        ".ohhhhhho.",
        ".ohhhhhho.",
        ".ohhhhhho.",
        ".ohhhhhho.",
        ".ochhhhco.",
        "occhhhhcco",
        "ococcccoco",
        "osoccccoso",
        ".oddddddo.",
        "oddddddddo",
    ],
    "side": [
        "...oooo...",
        ".Bohhhho..",
        ".ohhhhhho.",
        "ohhhhssso.",
        "ohhhhseso.",
        "ohhohrsso.",
        "ohho.osso.",
        "oho..oSo..",
        "..ocwcco..",
        "..occcco..",
        "..occcco..",
        "..osccco..",
        "..oddddo..",
        ".oddddddo.",
    ],
    "pal": {"s": (232, 186, 160), "S": (196, 146, 122), "h": (108, 66, 38), "r": (236, 150, 150), "B": (84, 44, 124),
            "c": (112, 66, 160), "w": (240, 238, 232), "d": (96, 96, 112),
            "p": (236, 236, 232), "q": (200, 200, 208), "k": (34, 28, 34)},
    "legs": 3,
}


def victoria():
    sheet(VICTORIA).save(Path("assets/characters") / "victoria.png")


def infancia():
    img, d = R.base(81)
    S = R.S
    # La pared del salón: el tablero, un mapa torcido.
    d.rectangle([6, 6, R.W - 7, 52], fill=S[1])
    d.rectangle([14, 12, 66, 40], fill=S[3])
    d.rectangle([15, 13, 65, 39], fill=S[2])
    d.line([20, 20, 44, 20], fill=R.LIGHT)
    d.line([20, 26, 56, 26], fill=R.LIGHT)
    d.line([20, 32, 38, 32], fill=R.LIGHT)
    d.polygon([(80, 14), (104, 17), (102, 38), (78, 35)], fill=R.LIGHT)
    d.line([84, 22, 98, 24], fill=S[2])
    d.line([84, 28, 96, 30], fill=S[2])
    d.rectangle([6, 53, R.W - 7, R.H - 7], fill=S[2])  # el piso
    # Él, a los ocho: chiquito en la mitad de la foto, de lado, manga larga, el pelo aplastado con agua.
    x, y = 54, 34
    d.ellipse([x + 2, y + 44, x + 16, y + 47], fill=S[3])       # la sombra
    d.ellipse([x, y, x + 9, y + 10], fill=S[0])
    d.chord([x - 1, y - 1, x + 10, y + 6], 180, 360, fill=S[4])
    d.line([x + 1, y + 3, x + 6, y + 2], fill=S[3])              # la raya, peinada con agua
    d.point((x + 3, y + 6), fill=S[4])
    d.point((x + 7, y + 6), fill=S[4])
    d.point((x + 8, y + 8), fill=S[3])                           # el labio
    d.rectangle([x - 1, y + 10, x + 10, y + 26], fill=R.LIGHT)   # la camisa: manga larga, abotonada hasta arriba
    d.rectangle([x - 4, y + 11, x - 2, y + 27], fill=R.LIGHT)
    d.rectangle([x + 11, y + 11, x + 13, y + 27], fill=R.LIGHT)
    d.line([x + 4, y + 11, x + 4, y + 25], fill=S[1])
    d.rectangle([x - 4, y + 27, x - 2, y + 28], fill=S[0])       # las manos, pegadas al cuerpo
    d.rectangle([x + 11, y + 27, x + 13, y + 28], fill=S[0])
    d.rectangle([x, y + 27, x + 3, y + 40], fill=S[4])           # el pantalón
    d.rectangle([x + 6, y + 27, x + 9, y + 40], fill=S[4])
    d.rectangle([x - 1, y + 41, x + 3, y + 43], fill=S[3])
    d.rectangle([x + 6, y + 41, x + 10, y + 43], fill=S[3])
    R.wear(img, d, 82)
    img.save(R.OUT + "recuerdo_infancia.png")


if __name__ == "__main__":
    nino()
    victoria()
    infancia()
    print("nino listo")
