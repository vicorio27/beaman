"""Retrato de Lukas, el beagle, para los diálogos (mismo estilo que draw_retratos.py: volumen,
luz dura por planos, facetas, paleta reducida). Busto de 96x112, de tres cuartos mirando a la derecha.
Tricolor: canela en la cabeza, franja blanca en la frente, hocico y pecho blancos, la "montura" negra
en el lomo; orejas largas caídas; collar de cuero café con la plaquita.
  lukas.png        - mirando fijo (el juego de miradas: no parpadea).
  lukas_ladra.png  - ladrando: boca abierta, orejas al aire.
Salida: assets/portraits/
Uso: python tools/art/draw_retrato_lukas.py  (desde la carpeta del proyecto)"""
import numpy as np
from PIL import ImageDraw

from draw_retratos import (OUT, S, Canvas, blur, bump, ell, facets, grade, poly, to_pixels, _XX)

TAN = ((112, 60, 30), (184, 112, 56), (226, 160, 96))
EAR = ((70, 36, 22), (136, 78, 40), (184, 116, 64))
WHITE = ((150, 140, 140), (226, 220, 208), (250, 246, 236))
BLACK = ((20, 18, 22), (46, 40, 44), (84, 76, 82))
LEATHER = ((70, 42, 24), (122, 78, 46), (170, 116, 72))
PINK = ((140, 50, 60), (210, 96, 110), (240, 150, 160))


def lukas(bark=False):
    c = Canvas()
    # Cuerpo: el lomo negro atrás, la paleta canela, el pecho blanco adelante.
    back = poly([(4, 112), (8, 92), (20, 82), (40, 80), (36, 112)])
    c.material(back, BLACK, k=26, amb=0.25)
    shoulder = poly([(24, 112), (26, 90), (40, 80), (62, 82), (70, 112)])
    c.material(shoulder, TAN, k=30, amb=0.22, extra=np.clip((_XX - 40) / 40.0, -1, 1) * 0.25)
    chest = poly([(46, 112), (48, 92), (58, 82), (74, 86), (82, 112)])
    c.material(chest, WHITE, height=blur(chest, 6 * S) + bump(66, 96, 10, 10, 0.4), k=30, amb=0.25)
    # Cuello.
    neck = poly([(30, 62), (64, 62), (70, 88), (28, 88)])
    c.material(neck, TAN, height=blur(neck, 5 * S), k=28, amb=0.2)
    throat = poly([(52, 66), (68, 66), (72, 88), (54, 88)])
    c.material(throat, WHITE, k=28, amb=0.24)

    # La oreja de atrás (asoma detrás de la cabeza, más oscura).
    if bark:
        far_ear = poly([(56, 30), (66, 22), (78, 26), (72, 36)])
    else:
        far_ear = poly([(58, 30), (66, 32), (70, 50), (66, 56), (61, 48)])
    c.material(far_ear, EAR, k=24, amb=0.12, extra=-0.15)

    # Cabeza: cráneo canela y el hocico largo hacia la derecha.
    skull = ell(46, 44, 19, 18)
    muzzle = poly([(52, 50), (72, 48), (80, 52), (82, 60), (78, 66), (62, 70), (52, 66)])
    head = np.clip(skull + muzzle, 0, 1)
    h = blur(head, 6 * S) + bump(74, 56, 8, 6, 0.35) + bump(50, 46, 4, 3, -0.2) + bump(64, 45, 3, 2.5, -0.15)
    h += bump(44, 36, 10, 5, 0.15)  # la frente
    form = np.clip((_XX - 46) / 22.0, -1, 1) * 0.3
    c.material(head, TAN, height=h, k=48, amb=0.2, extra=form)
    # Lo blanco: la franja de la frente y el hocico entero.
    blaze = poly([(54, 26), (60, 26), (62, 44), (66, 50), (56, 50)])
    snout = np.clip(poly([(58, 52), (74, 49), (82, 54), (83, 61), (78, 67), (62, 71), (56, 64)]) * head + blaze * head, 0, 1)
    c.material(snout, WHITE, height=h, k=48, amb=0.28, extra=form)
    if bark:
        # Boca abierta: la quijada de abajo cae, adentro oscuro y la lengua.
        mouth = poly([(60, 64), (80, 62), (78, 74), (64, 76)])
        c.paint(mouth, np.array([60, 24, 30], np.float32))
        tongue = ell(70, 72, 7, 3.5)
        c.material(tongue * mouth, PINK, k=20, amb=0.3)
        jaw = poly([(56, 70), (66, 75), (78, 74), (76, 80), (60, 80)])
        c.material(jaw, WHITE, k=30, amb=0.24)

    # La oreja de adelante: larga, caída, tapa el lado de la cara. Ladrando, vuela.
    if bark:
        ear = poly([(30, 34), (40, 30), (44, 38), (34, 54), (16, 60), (10, 52)])
    else:
        ear = poly([(30, 32), (42, 32), (44, 44), (40, 70), (34, 80), (26, 78), (24, 60), (25, 42)])
    c.material(ear, EAR, height=blur(ear, 5 * S) + bump(34, 56, 5, 14, 0.25), k=26, amb=0.16)
    # Collar de cuero.
    collar = poly([(28, 74), (66, 72), (68, 80), (28, 82)])
    c.material(collar, LEATHER, k=30, amb=0.2)

    facets(c, cell=4.5, seed=7)
    grade(c)
    img = to_pixels(c)
    d = ImageDraw.Draw(img)
    # La plaquita del collar.
    d.ellipse([46, 79, 51, 85], fill=(186, 190, 198, 255), outline=(96, 100, 110, 255))
    d.point((47, 81), fill=(236, 238, 242, 255))
    # Nariz negra, húmeda.
    d.ellipse([77, 52, 84, 58], fill=(24, 20, 24, 255))
    d.point([(79, 53), (80, 53)], fill=(150, 150, 160, 255))
    if bark:
        # Ojos apretados de ladrar (rayitas) y las cejitas canela arriba.
        d.line([(47, 45), (52, 47)], fill=(30, 20, 18, 255))
        d.line([(62, 44), (65, 45)], fill=(30, 20, 18, 255))
        # Los dientitos de arriba.
        for x in (64, 68, 72, 76):
            d.point((x, 64), fill=(244, 240, 230, 255))
    else:
        # Ojos de perro mirando fijo: grandes, café oscuro, con brillo. No parpadea.
        d.ellipse([46, 43, 53, 49], fill=(28, 18, 16, 255))
        d.point([(48, 45), (49, 45)], fill=(250, 250, 250, 255))
        d.point((51, 47), fill=(96, 56, 36, 255))
        d.ellipse([61, 42, 66, 47], fill=(28, 18, 16, 255))
        d.point((63, 44), fill=(250, 250, 250, 255))
        # Cejitas canela claro (los beagles las tienen): una más alta, sospecha.
        d.line([(46, 40), (51, 39)], fill=(238, 196, 140, 255))
        d.line([(61, 39), (64, 38)], fill=(238, 196, 140, 255))
        # La boca cerrada, seria.
        d.line([(66, 66), (76, 64)], fill=(70, 50, 50, 255))
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    lukas().save(OUT / "lukas.png")
    lukas(bark=True).save(OUT / "lukas_ladra.png")
    print("retratos de Lukas:", OUT)


if __name__ == "__main__":
    main()
