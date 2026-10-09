"""Arte de la serie CARRERAS (Camila, Guillermo, los dos juntos, Diana Carolina).
Camila: enana, peinado de honguito pintado de mono (raíz oscura), muy tetona, de fucsia.
Guillermo: gordo, muy gordo, mono, gafas oscuras, polo verde. (Como en la ciudad y en las peleas.)
  assets/moto/camila_moto.png       Camila en su moto, de espaldas (chiquita, el honguito, fucsia)
  assets/moto/guillermo_moto.png    Guillermo en su moto, de espaldas (enorme, nuca mona, polo verde)
  assets/moto/camila_monstruo.png   segunda fase: La Devoradora (hinchada, muchos brazos con carteras)
  assets/moto/guillermo_marrano.png segunda fase: el marrano con gafas y cadenas de oro, en moto, de frente
  assets/moto/patrulla.png, camion_ejercito.png, reten.png, cadena.png, bolso.png
Uso: python tools/art/draw_carreras.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw
import sys
sys.path.insert(0, str(Path(__file__).parent))
from draw_moto import outline, canvas, TIRE, CHROME, RED, SKIN

OUT = Path("assets/moto")
GOLD = (236, 190, 60, 255)
FUCSIA = (214, 64, 130, 255)
FUCSIA_D = (160, 40, 96, 255)
BLOND = (246, 214, 96, 255)
BLOND_D = (210, 170, 60, 255)
ROOTS = (96, 66, 46, 255)
POLO = (90, 160, 100, 255)
POLO_D = (64, 124, 74, 255)


def honguito(d, x0, y0, x1, y1):
    """El peinado de Camila: un casco redondo mono, con la raíz oscura en la coronilla."""
    d.ellipse([x0, y0, x1, y1], fill=BLOND)
    d.ellipse([x0 + 2, y0 + (y1 - y0) // 2, x1 - 2, y1], fill=BLOND_D)
    d.ellipse([x0 + 2, y0 + 2, x1 - 2, y0 + (y1 - y0) // 2 + 1], fill=BLOND)
    cx = (x0 + x1) // 2
    d.ellipse([cx - 3, y0, cx + 3, y0 + 3], fill=ROOTS)


def camila_moto():
    """De espaldas, chiquita: casi no alcanza el manubrio. Se le ve el busto por los lados."""
    img, d = canvas(48, 48)
    d.ellipse([18, 34, 30, 47], fill=TIRE)
    d.rectangle([16, 30, 32, 34], fill=(200, 80, 140, 255))
    d.rectangle([21, 31, 27, 33], fill=RED)
    d.rectangle([17, 26, 22, 31], fill=(48, 30, 58, 255))                  # medias oscuras
    d.rectangle([26, 26, 31, 31], fill=(48, 30, 58, 255))
    d.polygon([(17, 16), (31, 16), (33, 28), (15, 28)], fill=FUCSIA)       # la espalda, bajita
    d.ellipse([12, 18, 18, 25], fill=FUCSIA)                               # el busto, que se asoma
    d.ellipse([30, 18, 36, 25], fill=FUCSIA)
    d.line([(17, 18), (9, 22)], fill=FUCSIA, width=2)                      # brazos estirados al manubrio
    d.line([(31, 18), (39, 22)], fill=FUCSIA, width=2)
    d.rectangle([6, 21, 9, 23], fill=SKIN)
    d.rectangle([39, 21, 42, 23], fill=SKIN)
    d.point([(6, 23), (42, 23)], fill=RED)                                 # las uñas
    d.line([(20, 27), (28, 27)], fill=FUCSIA_D)
    honguito(d, 15, 4, 33, 19)
    outline(img).save(OUT / "camila_moto.png")


def guillermo_moto():
    """De espaldas: gordo, muy gordo. La moto casi no se le ve. Nuca mona, rollitos, polo verde."""
    img, d = canvas(48, 48)
    d.ellipse([18, 36, 30, 47], fill=TIRE)
    d.rectangle([17, 32, 31, 36], fill=(40, 44, 52, 255))
    d.rectangle([21, 33, 27, 35], fill=RED)
    d.rectangle([7, 26, 15, 34], fill=(66, 90, 140, 255))                  # jean
    d.rectangle([33, 26, 41, 34], fill=(66, 90, 140, 255))
    d.ellipse([4, 9, 44, 36], fill=POLO)                                    # la espalda: una pared verde
    d.ellipse([8, 12, 40, 33], fill=POLO)
    d.arc([10, 24, 38, 36], 200, 340, fill=POLO_D, width=1)                # la camiseta que no alcanza
    d.line([(6, 16), (1, 22)], fill=POLO, width=4)
    d.line([(42, 16), (47, 22)], fill=POLO, width=4)
    d.rectangle([0, 21, 3, 25], fill=SKIN)
    d.rectangle([44, 21, 47, 25], fill=SKIN)
    d.ellipse([15, 1, 33, 15], fill=SKIN)                                   # la nuca
    d.line([(17, 12), (31, 12)], fill=(180, 120, 92, 255))                  # los rollitos
    d.line([(18, 14), (30, 14)], fill=(180, 120, 92, 255))
    d.chord([15, 0, 33, 14], 180, 360, fill=BLOND)                         # el pelo mono
    d.line([(15, 6), (12, 7)], fill=(20, 20, 24, 255))                     # las patas de las gafas
    d.line([(33, 6), (36, 7)], fill=(20, 20, 24, 255))
    d.arc([16, 6, 32, 20], 20, 160, fill=GOLD, width=1)                    # la cadena, por atrás
    outline(img).save(OUT / "guillermo_moto.png")


def devoradora():
    """Camila, segunda fase: hinchada, de frente (mira para atrás, a él), con muchos brazos y carteras.
    El honguito mono, el escote reventado, la boca pintada."""
    img, d = canvas(72, 66)
    d.ellipse([10, 18, 62, 62], fill=(220, 150, 140, 255))           # cuerpo hinchado
    d.ellipse([16, 24, 56, 58], fill=(232, 168, 156, 255))
    d.ellipse([18, 26, 36, 44], fill=FUCSIA)                         # el busto, enorme
    d.ellipse([36, 26, 54, 44], fill=FUCSIA)
    d.ellipse([22, 30, 30, 36], fill=(236, 110, 160, 255))
    d.ellipse([42, 30, 50, 36], fill=(236, 110, 160, 255))
    d.rectangle([18, 42, 54, 60], fill=FUCSIA)                       # el vestido, reventado
    for x in range(20, 54, 6):
        d.line([(x, 44), (x + 3, 60)], fill=FUCSIA_D)
    d.ellipse([22, 4, 50, 28], fill=(232, 168, 156, 255))            # cabeza (cabezona)
    honguito(d, 18, 0, 54, 22)
    d.rectangle([24, 12, 48, 26], fill=(232, 168, 156, 255))         # la cara, debajo del flequillo
    d.line([(24, 12), (48, 12)], fill=BLOND)
    d.ellipse([28, 13, 32, 17], fill=(255, 230, 60, 255))            # ojos
    d.ellipse([40, 13, 44, 17], fill=(255, 230, 60, 255))
    d.ellipse([29, 18, 43, 25], fill=(200, 30, 60, 255))             # boca enorme, pintada
    d.rectangle([31, 20, 41, 22], fill=(60, 10, 20, 255))
    for ax, ay, bx, by in [(10, 34, 0, 22), (62, 34, 72, 22), (12, 48, 0, 54), (60, 48, 72, 54)]:
        d.line([(ax, ay), (bx, by)], fill=(220, 150, 140, 255), width=4)  # brazos
        d.rectangle([bx - 4 if bx else bx, by - 4, (bx + 4) if bx else bx + 8, by + 4], fill=(150, 40, 60, 255))  # carteras
    d.ellipse([20, 56, 52, 66], fill=TIRE)                            # la moto, aplastada debajo
    outline(img).save(OUT / "camila_monstruo.png")


def marrano():
    """Guillermo, segunda fase: un marrano con gafas oscuras, copete mono y cadenas de oro, en moto, de frente."""
    img, d = canvas(56, 54)
    d.ellipse([6, 16, 50, 50], fill=(234, 150, 160, 255))            # cuerpo (más gordo todavía)
    d.ellipse([12, 22, 44, 40], fill=POLO)                             # el polo verde, a reventar
    d.ellipse([14, 2, 42, 28], fill=(240, 160, 170, 255))             # cabeza
    d.polygon([(14, 6), (10, 0), (20, 4)], fill=(220, 130, 140, 255))  # orejas
    d.polygon([(42, 6), (46, 0), (36, 4)], fill=(220, 130, 140, 255))
    d.polygon([(22, 4), (28, 0), (34, 4), (30, 6), (26, 6)], fill=BLOND)  # el copete mono
    d.rectangle([16, 9, 26, 14], fill=(20, 20, 24, 255))              # gafas
    d.rectangle([30, 9, 40, 14], fill=(20, 20, 24, 255))
    d.line([(26, 11), (30, 11)], fill=(20, 20, 24, 255))
    d.ellipse([22, 16, 34, 25], fill=(220, 120, 130, 255))            # trompa
    d.point([(26, 20), (30, 20)], fill=(90, 30, 40, 255))
    for k in range(3):                                                 # cadenas de oro
        d.arc([16 - k * 2, 20 + k * 3, 40 + k * 2, 40 + k * 4], 20, 160, fill=GOLD, width=2)
    d.rectangle([20, 46, 36, 50], fill=(60, 140, 80, 255))           # la moto
    d.ellipse([22, 47, 34, 54], fill=TIRE)
    d.line([(6, 42), (50, 42)], fill=CHROME, width=2)
    outline(img).save(OUT / "guillermo_marrano.png")


def patrulla():
    img, d = canvas(46, 36)
    d.rectangle([2, 12, 43, 30], fill=(40, 120, 70, 255))            # verde
    d.rectangle([6, 2, 39, 14], fill=(240, 240, 236, 255))           # blanco
    d.rectangle([9, 4, 36, 12], fill=(70, 90, 110, 255))
    d.rectangle([12, 0, 20, 2], fill=(220, 40, 40, 255))             # sirena
    d.rectangle([26, 0, 34, 2], fill=(40, 80, 230, 255))
    d.rectangle([12, 18, 34, 22], fill=(240, 240, 236, 255))
    d.rectangle([4, 24, 9, 27], fill=RED)
    d.rectangle([37, 24, 42, 27], fill=RED)
    d.rectangle([3, 30, 9, 35], fill=TIRE)
    d.rectangle([37, 30, 43, 35], fill=TIRE)
    outline(img).save(OUT / "patrulla.png")


def camion_ejercito():
    img, d = canvas(62, 58)
    d.rectangle([0, 0, 61, 46], fill=(90, 100, 60, 255))
    for x, y in [(6, 6), (30, 12), (14, 26), (44, 30), (40, 4)]:
        d.ellipse([x, y, x + 12, y + 8], fill=(70, 80, 46, 255))      # camuflado
    d.line([(0, 2), (61, 2)], fill=(60, 66, 40, 255), width=3)
    d.rectangle([20, 34, 42, 40], fill=(240, 240, 220, 255))
    d.rectangle([4, 46, 12, 57], fill=TIRE)
    d.rectangle([50, 46, 58, 57], fill=TIRE)
    outline(img).save(OUT / "camion_ejercito.png")


def reten():
    img, d = canvas(84, 26)
    d.rectangle([2, 4, 81, 14], fill=(240, 240, 236, 255))
    for x in range(2, 82, 12):
        d.polygon([(x, 4), (x + 6, 4), (x + 12, 14), (x + 6, 14)], fill=(210, 40, 40, 255))
    d.rectangle([6, 14, 10, 25], fill=(90, 90, 96, 255))
    d.rectangle([74, 14, 78, 25], fill=(90, 90, 96, 255))
    d.ellipse([38, 0, 46, 6], fill=(255, 160, 40, 255))
    outline(img).save(OUT / "reten.png")


def small():
    img, d = canvas(26, 12)
    for x in range(1, 24, 4):
        d.ellipse([x, 3, x + 5, 9], outline=GOLD, width=2)
    outline(img).save(OUT / "cadena.png")
    img, d = canvas(18, 16)
    d.rectangle([2, 6, 15, 15], fill=(150, 40, 60, 255))
    d.arc([5, 0, 12, 10], 180, 360, fill=(110, 30, 40, 255), width=2)
    d.rectangle([7, 9, 10, 11], fill=GOLD)
    outline(img).save(OUT / "bolso.png")


def copiloto():
    """Ep. 1: Camila de copiloto (atrás), chiquita, con el brazo arriba tirando algo; adelante maneja un man."""
    img, d = canvas(48, 56)
    d.ellipse([18, 42, 30, 55], fill=TIRE)
    d.rectangle([15, 38, 33, 42], fill=(200, 80, 140, 255))
    d.rectangle([21, 39, 27, 41], fill=RED)
    d.polygon([(16, 14), (32, 14), (34, 30), (14, 30)], fill=(40, 40, 50, 255))   # el que maneja
    d.ellipse([18, 4, 30, 15], fill=(30, 30, 36, 255))
    d.polygon([(16, 28), (32, 28), (34, 40), (14, 40)], fill=FUCSIA)              # Camila, atrás (no le pasa del hombro)
    d.ellipse([11, 30, 17, 37], fill=FUCSIA)                                       # el busto, por un lado
    honguito(d, 15, 16, 33, 31)
    d.line([(33, 30), (44, 12)], fill=FUCSIA, width=3)                             # el brazo arriba
    d.point((44, 11), fill=RED)
    d.rectangle([41, 4, 47, 10], fill=(150, 40, 60, 255))                          # lo que tira
    outline(img).save(OUT / "camila_copiloto.png")


def camioneta(name, pig):
    """Ep. 2: la camioneta de Guillermo, de atrás; en el platón, Camila (chiquita, el honguito) tirando cosas."""
    img, d = canvas(66, 58)
    d.rectangle([2, 22, 63, 48], fill=(40, 90, 60, 255))
    d.rectangle([10, 4, 55, 24], fill=(36, 80, 54, 255))                           # cabina
    d.rectangle([14, 8, 51, 20], fill=(70, 90, 110, 255))                          # vidrio de atrás
    if pig:
        d.ellipse([18, 6, 46, 22], fill=(240, 160, 170, 255))                      # el marrano al volante, llena el vidrio
        d.polygon([(28, 7), (32, 4), (36, 7)], fill=BLOND)
        d.rectangle([22, 11, 30, 14], fill=(20, 20, 24, 255))
        d.rectangle([34, 11, 42, 14], fill=(20, 20, 24, 255))
        for k in range(3):
            d.line([(6, 30 + k * 4), (60, 30 + k * 4)], fill=GOLD, width=1)        # cadenas en la compuerta
    else:
        d.ellipse([20, 8, 44, 22], fill=SKIN)                                      # Guillermo, de espaldas: una nuca enorme
        d.chord([20, 7, 44, 19], 180, 360, fill=BLOND)
        d.line([(24, 18), (40, 18)], fill=(180, 120, 92, 255))
    d.polygon([(42, 24), (54, 24), (56, 34), (40, 34)], fill=FUCSIA)               # Camila en el platón
    d.ellipse([37, 25, 43, 31], fill=FUCSIA)
    honguito(d, 41, 13, 55, 25)
    d.line([(54, 26), (62, 10)], fill=FUCSIA, width=3)
    d.rectangle([4, 40, 12, 44], fill=RED)
    d.rectangle([53, 40, 61, 44], fill=RED)
    d.rectangle([24, 40, 42, 45], fill=(230, 210, 80, 255))
    d.rectangle([2, 48, 12, 57], fill=TIRE)
    d.rectangle([53, 48, 63, 57], fill=TIRE)
    outline(img).save(OUT / f"{name}.png")


def zapato():
    img, d = canvas(16, 12)
    d.polygon([(1, 9), (10, 9), (14, 4), (12, 3), (8, 7), (2, 7)], fill=(200, 30, 60, 255))
    d.line([(12, 4), (12, 11)], fill=(150, 20, 40, 255), width=2)                  # el tacón
    outline(img).save(OUT / "zapato.png")


def diana_rio():
    """La llegada al río (Ep. 4): de noche, luces de sirena del otro lado del puente, y ella en la
    orilla. Pelo largo, negro y liso, piel morena, vestido largo; el viento le mueve el pelo."""
    img = Image.new("RGBA", (320, 180), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    for y in range(100):
        k = y / 100
        d.line([(0, y), (319, y)], fill=(int(10 + 20 * k), int(10 + 14 * k), int(30 + 30 * k), 255))
    for x, y in [(30, 14), (90, 30), (150, 10), (240, 24), (290, 40), (200, 50)]:
        d.point((x, y), fill=(230, 230, 250, 255))
    d.ellipse([260, 14, 284, 38], fill=(230, 226, 210, 255))                       # luna
    d.rectangle([0, 100, 319, 179], fill=(16, 26, 40, 255))                        # el río
    for y in range(110, 180, 8):
        d.line([(0, y), (319, y)], fill=(28, 44, 64, 255))
    d.rectangle([0, 82, 120, 92], fill=(70, 70, 80, 255))                           # el puente
    for x in range(4, 120, 14):
        d.line([(x, 82), (x, 100)], fill=(60, 60, 70, 255))
    for x, c in [(20, (220, 40, 40)), (44, (40, 80, 230)), (70, (220, 40, 40)), (96, (40, 80, 230))]:
        d.ellipse([x - 8, 70, x + 8, 86], fill=c + (160,))                         # sirenas
    d.polygon([(150, 120), (320, 112), (320, 180), (130, 180)], fill=(60, 50, 40, 255))  # la orilla
    # Ella: en la orilla, de frente. Pelo a los hombros con mechas, chaqueta de jean, pantalón negro,
    # y el celular prendido en la mano: fue ella la que llamó.
    d.rectangle([232, 128, 238, 160], fill=(26, 24, 30, 255))                    # piernas
    d.rectangle([241, 128, 247, 160], fill=(26, 24, 30, 255))
    d.rectangle([230, 158, 239, 162], fill=(240, 240, 240, 255))                  # tenis
    d.rectangle([240, 158, 249, 162], fill=(240, 240, 240, 255))
    d.rectangle([229, 98, 250, 130], fill=(80, 110, 160, 255))                    # chaqueta de jean
    d.line([(239, 98), (239, 130)], fill=(60, 86, 130, 255))
    d.rectangle([235, 98, 243, 108], fill=(236, 236, 236, 255))                  # camiseta
    d.rectangle([224, 100, 229, 124], fill=(80, 110, 160, 255))                   # brazo izquierdo
    d.rectangle([250, 100, 255, 116], fill=(80, 110, 160, 255))                   # brazo derecho, doblado
    d.rectangle([250, 112, 258, 116], fill=(80, 110, 160, 255))
    d.rectangle([256, 106, 260, 114], fill=(170, 230, 255, 255))                  # el celular, prendido
    d.ellipse([253, 103, 263, 117], outline=(170, 230, 255, 90))
    d.rectangle([234, 92, 244, 99], fill=(196, 150, 116, 255))                   # cuello
    d.ellipse([230, 74, 248, 94], fill=(196, 150, 116, 255))                     # cara
    d.pieslice([227, 70, 251, 92], 180, 360, fill=(92, 60, 40, 255))             # pelo a los hombros
    d.rectangle([227, 80, 232, 100], fill=(92, 60, 40, 255))
    d.rectangle([246, 80, 251, 100], fill=(92, 60, 40, 255))
    for x in (230, 236, 244, 248):
        d.line([(x, 72), (x, 98 if x in (230, 248) else 78)], fill=(196, 150, 80, 255))  # mechas
    d.point([(235, 84), (243, 84)], fill=(30, 20, 20, 255))
    d.line([(236, 89), (242, 89)], fill=(130, 60, 60, 255))                      # la boca, apretada
    # Él, de espaldas, con la moto.
    d.rectangle([160, 110, 172, 146], fill=(232, 228, 220, 255))
    d.ellipse([160, 98, 172, 111], fill=(20, 20, 24, 255))
    d.rectangle([160, 146, 166, 168], fill=(60, 84, 130, 255))
    d.rectangle([167, 146, 172, 168], fill=(60, 84, 130, 255))
    img.save(OUT / "diana_rio.png")


if __name__ == "__main__":
    copiloto()
    camioneta("camioneta", False)
    camioneta("camioneta_marrano", True)
    zapato()
    diana_rio()
    camila_moto()
    guillermo_moto()
    devoradora()
    marrano()
    patrulla()
    camion_ejercito()
    reten()
    small()
    print("listo")
