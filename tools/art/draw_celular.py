"""El celular de flecha (el que vende Don Efraín) y su timbre.
  assets/items/celular.png   el ícono de la mochila (16x16)
  assets/ui/phone.png        el celular grande que salta abajo a la derecha cuando entra una llamada
  assets/audio/ring.wav      el timbre (una tonadita polifónica barata, inventada) con vibración
Uso: python tools/art/draw_celular.py  (desde la carpeta del proyecto)"""
import math
import struct
import wave
from pathlib import Path
from PIL import Image, ImageDraw

INK = (24, 18, 26, 255)
BODY = (70, 78, 92, 255)
BODY_HI = (110, 120, 138, 255)
SCREEN = (150, 196, 120, 255)  # verde de pantallita de los de antes
KEY = (200, 204, 210, 255)


def icon():
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([5, 1, 10, 14], fill=BODY, outline=INK)
    d.line([(9, 0), (9, 1)], fill=INK)  # la antenita
    d.rectangle([6, 3, 9, 6], fill=SCREEN)
    for y in (8, 10, 12):
        d.point([(6, y), (8, y)], fill=KEY)
    im.save("assets/items/celular.png")


def big():
    im = Image.new("RGBA", (30, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([22, 0, 24, 8], fill=INK)  # antena
    d.rounded_rectangle([2, 6, 27, 55], 4, fill=BODY, outline=INK)
    d.line([(4, 9), (4, 52)], fill=BODY_HI)
    d.rectangle([6, 12, 23, 26], fill=SCREEN, outline=INK)
    d.line([(7, 13), (12, 13)], fill=(190, 226, 160, 255))
    d.polygon([(11, 30), (18, 30), (14, 34)], fill=KEY)  # la flecha
    for row in range(4):
        for col in range(3):
            x, y = 7 + col * 6, 37 + row * 4
            d.rectangle([x, y, x + 3, y + 1], fill=KEY)
    im.save("assets/ui/phone.png")


def ring():
    rate = 22050
    notes = [988, 784, 880, 659, 0, 988, 1175, 988, 784, 0, 0]  # inventada
    samples = []
    for n in notes:
        for i in range(int(rate * 0.11)):
            t = i / rate
            v = 0.0
            if n:
                v = 0.32 * (1 if math.sin(2 * math.pi * n * t) > 0 else -1)
                v += 0.12 * (1 if math.sin(2 * math.pi * n * 2 * t) > 0 else -1)
                v *= min(1.0, (0.11 - t) * 40)
            v += 0.08 * math.sin(2 * math.pi * 55 * t) * (1 if (int(t * 20) % 2) else 0.3)  # vibración
            samples.append(int(max(-1, min(1, v)) * 20000))
    with wave.open("assets/audio/ring.wav", "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", s) for s in samples))


if __name__ == "__main__":
    icon()
    big()
    ring()
    print("celular listo")
