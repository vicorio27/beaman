"""La vitrina de TV RADIO (al lado del café): un local de electrodomésticos con televisores prendidos
en la vidriera. Desde la calle se ve la tele sin sonido; ahí se pasa el rato (Conversations._vitrina_tv).
Tres cuadros (cambia lo que pasa en las pantallas) y uno de noche, con la reja abajo.
Salida: assets/barrio/electro_a.png, electro_b.png, electro_c.png, electro_noche.png
Uso: python tools/art/draw_vitrina.py  (desde la carpeta del proyecto)
(Importa draw_barrio.py, que vuelve a guardar sus dibujos iguales: tiene semilla fija.)"""
import random
from PIL import ImageDraw

import draw_barrio as B

random.seed(29)
W, FACE, ROOF = 76, 38, 18
SCREENS = [(6, 16, 16, 10), (30, 16, 16, 10), (54, 16, 16, 10), (18, 28, 16, 8), (42, 28, 16, 8)]
# Lo que pasa en las teles: colores de "imagen" (telenovela, fútbol, noticiero...).
SHOWS = {
    "a": [((70, 150, 70), (230, 230, 230)), ((200, 120, 140), (90, 50, 60)), ((60, 90, 160), (240, 220, 120))],
    "b": [((200, 120, 140), (90, 50, 60)), ((60, 90, 160), (240, 220, 120)), ((70, 150, 70), (230, 230, 230))],
    "c": [((60, 90, 160), (240, 220, 120)), ((70, 150, 70), (230, 230, 230)), ((200, 120, 140), (90, 50, 60))],
}


def tvs(frame, night=False):
    def f(d, w, H, fy):
        # La vidriera grande, oscura por dentro.
        d.rectangle([3, fy + 13, w - 4, H - 4], fill=B.rgba((34, 30, 40)), outline=B.INK)
        for i, (x, y, sw, sh) in enumerate(SCREENS):
            d.rectangle([x - 1, fy + y - 1, x + sw, fy + y + sh], fill=B.rgba((50, 46, 52)), outline=B.INK)
            if night:
                d.rectangle([x, fy + y, x + sw - 1, fy + y + sh - 1], fill=B.rgba((24, 22, 30)))
                continue
            bg, fg = SHOWS[frame][i % 3]
            d.rectangle([x, fy + y, x + sw - 1, fy + y + sh - 1], fill=B.rgba(bg))
            d.rectangle([x + 3, fy + y + 3, x + 6, fy + y + sh - 2], fill=B.rgba(fg))  # alguien en la tele
            d.line([(x, fy + y), (x + 3, fy + y)], fill=B.rgba((250, 250, 250), 160))  # reflejo
        d.line([(4, fy + 14), (12, fy + 14)], fill=B.rgba((200, 210, 220), 140))  # brillo del vidrio
        if night:  # la reja metálica abajo
            for x in range(3, w - 3, 3):
                d.line([(x, fy + 13), (x, H - 4)], fill=B.rgba((120, 120, 128)))
            d.line([(3, fy + 20), (w - 4, fy + 20)], fill=B.rgba((120, 120, 128)))
    return f


def make(frame, night=False):
    random.seed(29)  # el mismo edificio en todos los cuadros: solo cambian las pantallas
    return B.building(W, FACE, ROOF, B.WALLS["gris"], windows=(), rust=0.4,
                      sign=("TV RADIO", 6, 2, (150, 40, 40), (250, 230, 160)),
                      extras=[tvs(frame, night)])


if __name__ == "__main__":
    for k in "abc":
        B.save(f"electro_{k}", make(k))
    B.save("electro_noche", make("a", night=True))
    print("vitrina: listo")
