"""La bicicleta de Victoria, guardada al lado del cambuche desde que la compra (Conversations._comprar_bici):
envuelta en bolsas de basura negras para que no le caiga el rocío, con un moño hecho con la cinta de un
casete. Se ve una llanta, el manubrio con el timbre y un pedazo verde agua por donde la bolsa no alcanzó.

Si Doña Rosa le enseñó a envolver (DayTasks._rosa2), va en el papel de globos que ella le regaló:
assets/barrio/bici_regalo.png (el mismo bulto, de papel crema con globitos de colores).

Salida: assets/barrio/bici_envuelta.png y bici_regalo.png (26x18).
Uso: python tools/art/draw_bici_victoria.py  (desde la carpeta del proyecto)"""
from pathlib import Path

from PIL import Image

OUT = Path("assets/barrio/bici_envuelta.png")
OUT_REGALO = Path("assets/barrio/bici_regalo.png")
# El papel de globos de Doña Rosa: crema, un poco arrugado ("lo planché yo"), con globitos.
PAPEL = {"k": (236, 218, 166), "K": (204, 182, 128), "l": (250, 240, 206), "o": (96, 74, 52)}
GLOBOS = [(220, 62, 74), (72, 124, 210), (84, 172, 96), (236, 170, 50)]
PAL = {
    ".": None,
    "o": (18, 16, 22),                     # contorno
    "k": (34, 34, 40), "K": (52, 52, 62),  # bolsa negra
    "l": (92, 96, 112),                    # el brillo del plástico
    "t": (126, 210, 196), "T": (78, 150, 140),  # verde agua
    "u": (40, 38, 42), "U": (70, 66, 70),  # llanta
    "a": (200, 200, 206), "A": (140, 140, 150),  # manubrio, timbre
    "c": (92, 54, 38), "C": (150, 96, 62),  # la cinta del casete (café brillante)
}
ART = [
    "..........................",
    "..aa.........cC..Cc.......",
    ".aAAa.........cCCc........",
    "..oa........oocCCcoo......",
    "..oKo....ookkkkcckkkoo....",
    "..okKoooookkKllkkkkkkko...",
    ".okkkkkkkkkKlKkkkkkkkkko..",
    ".okkKkkkkkkkkkkkkkKlkkko..",
    "okkkllkkkkkkkkkkkkkKkkkko.",
    "okkKlkkkkktTkkkkkkkkkkkko.",
    "okkkkkkkkkTtkkkkkkkkKkkko.",
    ".okkkkkkkkkkkkkkkkkkkkko..",
    ".ouuUoookkkkkkkkkkkoouuUo.",
    "ou...uo.oookkkkooo.ou...uo",
    "uU...Uu....ooo.....uU...Uu",
    "ou...uo............ou...uo",
    ".ouuuo..............ouuuo.",
    "..........................",
]


def paint(papel=False):
    im = Image.new("RGBA", (26, 18), (0, 0, 0, 0))
    for y, r in enumerate(ART):
        assert len(r) == 26, (y, len(r))
        for x, ch in enumerate(r):
            c = PAL[ch]
            if papel and ch in "kKl":
                c = PAPEL[ch]
                if ch == "k" and (x * 3 + y * 5) % 9 == 0:  # un globito, con la cuerdita debajo
                    c = GLOBOS[(x + y) % len(GLOBOS)]
                elif ch == "k" and y > 0 and ART[y - 1][x] == "k" and ((x * 3 + (y - 1) * 5) % 9 == 0):
                    c = PAPEL["K"]
            elif papel and ch == "o" and 3 < y < 13 and 3 < x < 23:
                c = PAPEL["o"]  # el borde del papel: café, no negro
            if c:
                im.putpixel((x, y), c + (255,))
    return im


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    paint().save(OUT)
    paint(True).save(OUT_REGALO)
    print("bici envuelta:", OUT, OUT_REGALO)


if __name__ == "__main__":
    main()
