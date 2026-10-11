"""Los recuerdos: fotos viejas en sepia, como la de la primera noche (draw_photo.py). Cada una sale una
vez, en un momento de la vida real (scripts/systems/Recuerdo.gd), y cuenta un pedazo de lo que él era.
  recuerdo_renegade.png   él, joven y sin barba, con la Renegade el primer día (el recuerdo de la moto)
  recuerdo_lorena.png     Lorena joven, atrás en la moto, riéndose, el pelo al viento (la primera vuelta)
  recuerdo_bebe.png       él con Victoria recién nacida, en la ventana del hospital
  recuerdo_lukas.png      Lukas cachorro, en una caja de zapatos
  recuerdo_oficina.png    él de corbata, en un escritorio, con la placa de EMPLEADO DEL MES
  recuerdo_dorso.png      el dorso (papel; la frase se escribe en el juego)
Salida: assets/items/ (120x88). Uso: python tools/art/draw_recuerdos.py  (desde la carpeta del proyecto)"""
import random
from PIL import Image, ImageDraw

W, H = 120, 88
PAPER = (226, 216, 190, 255)
S = [(204, 180, 138, 255), (176, 148, 108, 255), (146, 118, 86, 255), (106, 82, 60, 255), (72, 56, 42, 255)]
LIGHT = (232, 218, 186, 255)
OUT = "assets/items/"


def base(seed):
    random.seed(seed)
    img = Image.new("RGBA", (W, H), PAPER)
    d = ImageDraw.Draw(img)
    d.rectangle([6, 6, W - 7, H - 7], fill=S[0])
    return img, d


def wear(img, d, seed):
    """Bordes gastados, una mancha, el grano."""
    random.seed(seed)
    for _ in range(70):
        d.point((random.randint(7, W - 8), random.randint(7, H - 8)), fill=S[random.choice([1, 2])] if random.random() < 0.5 else LIGHT)
    for _ in range(40):
        x, y = random.choice([(random.randint(0, W - 1), random.randint(0, 5)), (random.randint(0, W - 1), random.randint(H - 6, H - 1)),
                              (random.randint(0, 5), random.randint(0, H - 1)), (random.randint(W - 6, W - 1), random.randint(0, H - 1))])
        d.point((x, y), fill=(200, 188, 160, 255))
    x, y = random.randint(14, 90), random.randint(14, 60)
    d.ellipse([x, y, x + 10, y + 8], fill=(214, 198, 160, 255))  # la mancha de humedad
    d.polygon([(W - 14, H), (W, H - 12), (W, H)], fill=(0, 0, 0, 0))  # la esquina doblada, comida


def person(d, x, y, shirt, hair=S[4], skin=S[1], beard=False, tie=False, h=30):
    """Una persona de frente: cabeza, cuerpo, piernas. (x, y) = arriba de la cabeza."""
    d.ellipse([x, y, x + 9, y + 10], fill=skin)
    d.chord([x - 1, y - 1, x + 10, y + 7], 180, 360, fill=hair)
    if beard:
        d.chord([x, y + 4, x + 9, y + 11], 0, 180, fill=S[3])
    d.rectangle([x - 1, y + 10, x + 10, y + 10 + h // 2], fill=shirt)
    if tie:
        d.rectangle([x + 4, y + 11, x + 5, y + 10 + h // 2 - 2], fill=S[4])
    d.rectangle([x, y + 10 + h // 2, x + 3, y + 10 + h], fill=S[4])
    d.rectangle([x + 6, y + 10 + h // 2, x + 9, y + 10 + h], fill=S[4])


def bike(d, x, y):
    """La café racer de costado: dos ruedas, el tanque, el asiento, el manubrio bajo."""
    for cx in (x + 8, x + 44):
        d.ellipse([cx - 8, y + 10, cx + 8, y + 26], fill=S[4])
        d.ellipse([cx - 4, y + 14, cx + 4, y + 22], fill=S[1])
    d.polygon([(x + 14, y + 10), (x + 30, y + 4), (x + 36, y + 10), (x + 18, y + 14)], fill=S[3])  # tanque
    d.rectangle([x + 34, y + 6, x + 48, y + 10], fill=S[2])   # asiento
    d.line([(x + 6, y + 2), (x + 14, y + 12)], fill=S[4], width=2)  # horquilla
    d.line([(x + 2, y + 2), (x + 10, y + 2)], fill=S[4], width=2)   # manubrio
    d.ellipse([x + 2, y + 2, x + 8, y + 8], fill=LIGHT)               # farola


def renegade():
    img, d = base(11)
    d.rectangle([6, 6, W - 7, 40], fill=S[1])        # la pared del taller
    d.rectangle([14, 10, 66, 20], fill=S[3])         # el letrero
    d.rectangle([18, 13, 62, 17], fill=S[0])
    d.rectangle([76, 12, 104, 40], fill=S[2])        # la cortina metálica
    for y in range(14, 40, 4):
        d.line([(76, y), (104, y)], fill=S[3])
    d.rectangle([6, 40, W - 7, H - 7], fill=S[0])    # el andén
    bike(d, 18, 48)
    person(d, 74, 34, S[2], h=32)                    # él: joven, sin barba, con chaqueta
    d.line([(73, 48), (54, 54)], fill=S[2], width=2)  # la mano en el tanque
    wear(img, d, 12)
    img.save(OUT + "recuerdo_renegade.png")


def lorena():
    img, d = base(21)
    d.rectangle([6, 6, W - 7, 46], fill=S[0])        # el cielo
    d.ellipse([86, 10, 104, 28], fill=LIGHT)          # el sol
    d.rectangle([6, 46, W - 7, H - 7], fill=S[1])
    bike(d, 30, 50)
    # Ella, atrás, sentada de lado, riéndose, el pelo al viento hacia atrás.
    d.ellipse([70, 30, 80, 41], fill=S[1])
    d.polygon([(70, 32), (58, 36), (54, 44), (66, 42), (72, 38)], fill=S[3])  # el pelo volando
    d.chord([69, 28, 81, 37], 180, 360, fill=S[3])
    d.point((76, 37), fill=S[4])                      # la boca abierta: se ríe
    d.point((77, 37), fill=S[4])
    d.rectangle([70, 41, 80, 54], fill=S[2])          # el vestido
    d.line([(80, 44), (88, 38)], fill=S[1], width=2)  # el brazo arriba
    d.rectangle([72, 54, 76, 62], fill=S[3])
    # Él no sale: solo un hombro, cortado por el borde (él tomaba la foto con la otra mano).
    d.rectangle([6, 30, 14, 60], fill=S[3])
    wear(img, d, 22)
    img.save(OUT + "recuerdo_lorena.png")


def bebe():
    img, d = base(31)
    d.rectangle([6, 6, W - 7, H - 7], fill=S[1])     # la pared del hospital
    d.rectangle([70, 12, 108, 46], fill=LIGHT)        # la ventana con luz
    d.line([(89, 12), (89, 46)], fill=S[2])
    d.line([(70, 29), (108, 29)], fill=S[2])
    person(d, 40, 18, S[0], h=56)                     # él, joven, con camisa clara
    d.ellipse([38, 36, 54, 48], fill=LIGHT)           # la cobija
    d.ellipse([44, 37, 51, 44], fill=S[0])            # la carita
    d.line([(38, 40), (34, 46)], fill=S[0], width=2)  # los brazos alrededor
    d.line([(54, 40), (58, 46)], fill=S[0], width=2)
    wear(img, d, 32)
    img.save(OUT + "recuerdo_bebe.png")


def lukas():
    img, d = base(41)
    d.rectangle([6, 6, W - 7, H - 7], fill=S[1])     # el piso de baldosa
    for x in range(6, W - 6, 14):
        d.line([(x, 6), (x, H - 7)], fill=S[2])
    for y in range(6, H - 6, 14):
        d.line([(6, y), (W - 7, y)], fill=S[2])
    d.polygon([(28, 40), (92, 40), (98, 74), (22, 74)], fill=S[3])   # la caja de zapatos
    d.rectangle([22, 36, 98, 42], fill=S[2])                          # el borde
    d.rectangle([40, 56, 80, 64], fill=S[2])                          # la etiqueta
    d.rectangle([44, 58, 76, 62], fill=S[0])
    # Lukas cachorro asomado: la cabeza grande, las orejas largas, la manchita blanca.
    d.ellipse([46, 22, 74, 46], fill=S[1])
    d.ellipse([42, 26, 52, 48], fill=S[3])
    d.ellipse([68, 26, 78, 48], fill=S[3])
    d.rectangle([58, 24, 62, 40], fill=LIGHT)
    d.ellipse([55, 38, 65, 46], fill=LIGHT)
    d.point((53, 32), fill=S[4])
    d.point((67, 32), fill=S[4])
    d.ellipse([58, 39, 62, 42], fill=S[4])
    d.line([(100, 14), (88, 30)], fill=S[0], width=3)  # una mano que entra a acariciarlo
    wear(img, d, 42)
    img.save(OUT + "recuerdo_lukas.png")


def oficina():
    img, d = base(51)
    d.rectangle([6, 6, W - 7, H - 7], fill=S[0])     # la pared blanca de oficina
    for x in range(18, W - 10, 22):                    # las persianas
        d.rectangle([x, 10, x + 14, 30], fill=S[1])
        for y in range(12, 30, 3):
            d.line([(x, y), (x + 14, y)], fill=S[2])
    person(d, 54, 26, S[3], tie=True, h=30)           # él, de saco y corbata, sin barba
    d.rectangle([20, 52, 100, 58], fill=S[3])         # el escritorio
    d.rectangle([24, 58, 28, 80], fill=S[4])
    d.rectangle([92, 58, 96, 80], fill=S[4])
    d.rectangle([28, 44, 46, 52], fill=S[2])          # el computador
    d.rectangle([74, 42, 94, 52], fill=LIGHT)         # la placa
    d.rectangle([77, 45, 91, 49], fill=S[2])
    wear(img, d, 52)
    img.save(OUT + "recuerdo_oficina.png")


def dorso():
    random.seed(61)
    back = Image.new("RGBA", (W, H), PAPER)
    d = ImageDraw.Draw(back)
    for _ in range(120):
        d.point((random.randint(0, W - 1), random.randint(0, H - 1)), fill=(214, 202, 176, 255))
    d.polygon([(0, H), (14, H), (0, H - 12)], fill=(0, 0, 0, 0))  # la esquina comida (del otro lado)
    back.save(OUT + "recuerdo_dorso.png")


if __name__ == "__main__":
    renegade()
    lorena()
    bebe()
    lukas()
    oficina()
    dorso()
    print("recuerdos listos")
