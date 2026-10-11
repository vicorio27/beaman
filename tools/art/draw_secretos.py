"""Lo de los cuartos secretos de PLOMO (Plomo.gd: las paredes "S"), con el mismo trazo de
draw_plomo_doom.py. Salida (assets/shooter/):
  dd_martin.png   Martín, el hijo de Lisandro (nueve años), sentado en el piso con las piernas
                  cruzadas, jugando Switch: la pantalla prendida, los controles rojo y azul
  dd_lampara.png  una lámpara de piso con la pantalla torcida (la luz del cuarto)
Uso: python tools/art/draw_secretos.py  (desde la carpeta del proyecto)"""
from PIL import Image, ImageDraw
from draw_shooter import OUT, outline


def sprite(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, name):
    outline(img)
    img.save(OUT / f"dd_{name}.png")


def martin():
    img, d = sprite(28, 30)
    skin = (196, 146, 108, 255)
    hair = (40, 30, 26, 255)
    shirt = (70, 130, 200, 255)       # camiseta azul (de un equipo)
    jean = (60, 70, 110, 255)
    # Las piernas cruzadas, en el piso.
    d.ellipse([3, 22, 25, 29], fill=jean)
    d.rectangle([4, 26, 8, 28], fill=(236, 236, 236, 255))   # un tenis
    d.rectangle([20, 26, 24, 28], fill=(236, 236, 236, 255))
    # El cuerpo, encorvado sobre la consola.
    d.rectangle([8, 12, 20, 23], fill=shirt)
    d.rectangle([12, 14, 16, 16], fill=(240, 240, 240, 255))  # el número de la camiseta
    # La cabeza agachada, mirando la pantalla.
    d.ellipse([8, 2, 20, 14], fill=skin)
    d.chord([7, 1, 21, 10], 180, 360, fill=hair)
    d.point((11, 10), fill=(20, 16, 16, 255))
    d.point((16, 10), fill=(20, 16, 16, 255))
    # El Switch en las manos: los controles rojo y azul, la pantalla prendida (Mario, una luna).
    d.rectangle([5, 17, 7, 21], fill=(230, 60, 60, 255))     # el control rojo
    d.rectangle([21, 17, 23, 21], fill=(60, 120, 230, 255))  # el control azul
    d.rectangle([8, 17, 20, 21], fill=(30, 30, 36, 255))     # la consola
    d.rectangle([9, 18, 19, 20], fill=(150, 220, 255, 255))  # la pantalla
    d.point((12, 19), fill=(220, 40, 40, 255))               # Mario
    d.point((16, 18), fill=(255, 230, 80, 255))              # la luna
    d.rectangle([4, 18, 5, 20], fill=skin)                   # las manos
    d.rectangle([23, 18, 24, 20], fill=skin)
    save(img, "martin")


def lampara():
    img, d = sprite(14, 40)
    d.rectangle([6, 12, 7, 39], fill=(80, 70, 60, 255))
    d.rectangle([3, 37, 10, 39], fill=(80, 70, 60, 255))
    d.polygon([(1, 12), (12, 10), (10, 2), (4, 3)], fill=(250, 220, 150, 255))  # la pantalla, torcida
    save(img, "lampara")


if __name__ == "__main__":
    martin()
    lampara()
    print("secretos listos")
