"""La bicicleta de Victoria, guardada al lado del cambuche desde que la compra (Conversations._comprar_bici):
envuelta en bolsas de basura negras para que no le caiga el rocío, con un moño hecho con la cinta de un
casete. Se ve una llanta, el manubrio con el timbre y un pedazo verde agua por donde la bolsa no alcanzó.

Salida: assets/barrio/bici_envuelta.png (26x18).
Uso: python tools/art/draw_bici_victoria.py  (desde la carpeta del proyecto)"""
from pathlib import Path

from PIL import Image

OUT = Path("assets/barrio/bici_envuelta.png")
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


def main():
    im = Image.new("RGBA", (26, 18), (0, 0, 0, 0))
    for y, r in enumerate(ART):
        assert len(r) == 26, (y, len(r))
        for x, ch in enumerate(r):
            c = PAL[ch]
            if c:
                im.putpixel((x, y), c + (255,))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    im.save(OUT)
    print("bici envuelta:", OUT)


if __name__ == "__main__":
    main()
