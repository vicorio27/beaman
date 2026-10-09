"""Lo que pasa por la calle (Traffic.gd): carros, un taxi, una buseta, bicicletas y motos.
Mismo estilo que draw_barrio.py (contorno violeta muy oscuro, vista oblicua desde arriba).
  car_<color>_side_a/b.png     de costado (avenida este-oeste), mirando a la derecha; b: rebota
  car_<color>_down_a/b.png     de frente (bajando por la calle norte-sur)
  car_<color>_up_a/b.png       de espaldas (subiendo)
  bici_side_a/b, bici_down_a/b, bici_up_a/b    un ciclista (pedalea)
  moto_side_a/b, moto_down_a/b, moto_up_a/b    un motociclista (casco)
Salida: assets/barrio/trafico/*.png
Uso: python tools/art/draw_trafico.py  (desde la carpeta del proyecto)"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path("assets/barrio/trafico")
INK = (38, 28, 44, 255)
GLASS = (120, 150, 170, 255)
GLASS_HI = (190, 210, 220, 255)
TIRE = (34, 30, 36, 255)
RIM = (150, 150, 156, 255)
LIGHT = (250, 236, 170, 255)
TAIL = (200, 50, 50, 255)
CARS = {
    "rojo": (170, 54, 48), "azul": (60, 90, 150), "blanco": (214, 210, 200), "gris": (120, 120, 126),
    "taxi": (236, 196, 60), "buseta": (70, 140, 100),
}


def rgba(c, a=255):
    return tuple(c[:3]) + (a,)


def dk(c, k=0.72):
    return tuple(int(v * k) for v in c[:3]) + (255,)


def lt(c, k=1.18):
    return tuple(min(255, int(v * k + 10)) for v in c[:3]) + (255,)


def outline(img):
    w, h = img.size
    src = img.copy()
    px, out = src.load(), img.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != INK:
                        out[x, y] = INK
                        break
    return img


def bounce(img, wheels_h):
    """Cuadro b: la carrocería sube un píxel, las ruedas quedan."""
    w, h = img.size
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.alpha_composite(img.crop((0, h - wheels_h, w, h)), (0, h - wheels_h))
    body = img.crop((0, 0, w, h - wheels_h + 2))
    out.alpha_composite(body, (0, -1))
    return out


def car_side(name, frame):
    bus = name == "buseta"
    color = CARS[name]
    w, h = (60, 30) if bus else (44, 24)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = rgba(color)
    if bus:
        d.rectangle([2, 2, w - 3, 8], fill=lt(c))
        d.rectangle([1, 8, w - 2, h - 7], fill=c)
        for x in range(5, w - 8, 9):
            d.rectangle([x, 10, x + 6, 15], fill=GLASS)
            d.point((x + 1, 11), fill=GLASS_HI)
        d.line([(1, 18), (w - 2, 18)], fill=dk(c))
        body_top = 6
    else:
        d.polygon([(12, 2), (32, 2), (36, 9), (8, 9)], fill=lt(c))  # techo
        d.polygon([(13, 3), (21, 3), (21, 8), (10, 8)], fill=GLASS)  # ventanas
        d.polygon([(23, 3), (31, 3), (34, 8), (23, 8)], fill=GLASS)
        d.point((14, 4), fill=GLASS_HI)
        d.rectangle([1, 9, w - 2, h - 6], fill=c)
        d.line([(1, 13), (w - 2, 13)], fill=dk(c, 0.85))
        d.line([(22, 10), (22, h - 7)], fill=dk(c))  # la puerta
        body_top = 9
    d.rectangle([1, h - 7, w - 2, h - 6], fill=dk(c, 0.55))
    d.rectangle([w - 3, body_top + 3, w - 2, body_top + 5], fill=LIGHT)  # adelante = derecha
    d.rectangle([1, body_top + 3, 2, body_top + 5], fill=TAIL)
    if name == "taxi":
        d.rectangle([19, 0, 25, 2], fill=rgba((250, 250, 240)))
        for x in range(3, w - 3, 4):
            d.point((x, 14), fill=INK)
    for wx in ((8, w - 11) if not bus else (9, w - 13)):
        d.ellipse([wx - 4, h - 9, wx + 4, h - 1], fill=TIRE)
        d.ellipse([wx - 2, h - 7, wx + 2, h - 3], fill=RIM)
        d.point((wx, h - 5) if frame else (wx - 1, h - 6), fill=TIRE)
    outline(img)
    return bounce(img, 9) if frame else img


def car_front(name, frame, up):
    bus = name == "buseta"
    color = CARS[name]
    w, h = (30, 36) if bus else (26, 28)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = rgba(color)
    d.rectangle([4, 1, w - 5, h - 14], fill=lt(c))  # el techo, visto desde arriba
    if up:
        d.rectangle([5, h - 19, w - 6, h - 15], fill=GLASS)  # vidrio de atrás
    else:
        d.rectangle([5, 3, w - 6, 8], fill=GLASS)  # parabrisas
        d.point((6, 4), fill=GLASS_HI)
    d.rectangle([2, h - 14, w - 3, h - 4], fill=c)
    lamp = TAIL if up else LIGHT
    d.rectangle([3, h - 12, 5, h - 10], fill=lamp)
    d.rectangle([w - 6, h - 12, w - 4, h - 10], fill=lamp)
    if up:
        d.rectangle([9, h - 9, w - 10, h - 7], fill=rgba((230, 226, 210)))  # la placa
    else:
        d.rectangle([8, h - 9, w - 9, h - 7], fill=dk(c, 0.5))  # parrilla
    if name == "taxi":
        d.rectangle([w // 2 - 3, 0, w // 2 + 2, 2], fill=rgba((250, 250, 240)))
    d.rectangle([2, h - 4, 6, h - 1], fill=TIRE)
    d.rectangle([w - 7, h - 4, w - 3, h - 1], fill=TIRE)
    outline(img)
    return bounce(img, 5) if frame else img


def rider(kind, view, frame):
    """Bici o moto con su conductor. view: side, down, up."""
    moto = kind == "moto"
    shirt = rgba((60, 120, 170)) if not moto else rgba((40, 40, 46))
    skin = rgba((196, 140, 104))
    hair = rgba((40, 32, 30))
    helmet = rgba((200, 60, 50))
    pants = rgba((50, 50, 70))
    frame_c = rgba((70, 70, 76)) if moto else rgba((60, 150, 90))
    if view == "side":
        w = 26 if moto else 22
        img = Image.new("RGBA", (w, 26), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        for wx in (5, w - 6):
            d.ellipse([wx - 4, 17, wx + 4, 25], outline=TIRE, fill=TIRE if moto else None)
            d.point((wx, 21), fill=RIM)
        if moto:
            d.polygon([(5, 19), (10, 14), (20, 14), (w - 6, 19), (14, 21)], fill=frame_c)
            d.rectangle([16, 12, 20, 15], fill=RIM)
        else:
            d.line([(5, 21), (11, 15), (w - 6, 21)], fill=frame_c)
            d.line([(11, 15), (w - 7, 14), (w - 6, 21)], fill=frame_c)
        d.polygon([(9, 6), (14, 5), (16, 13), (10, 14)], fill=shirt)  # el torso, inclinado
        d.ellipse([12, 0, 18, 6], fill=helmet if moto else skin)
        if not moto:
            d.rectangle([12, 0, 17, 1], fill=hair)
        knee = (14, 17) if frame else (12, 19)
        d.line([(11, 14), knee, (12 + (2 if frame else -1), 22)], fill=pants, width=2)
        d.line([(15, 8), (w - 7, 13)], fill=skin)  # el brazo al manubrio
    else:
        img = Image.new("RGBA", (12, 28), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([5, 16, 6, 27], fill=TIRE)  # la rueda vista de frente
        d.rectangle([1, 12, 10, 13], fill=frame_c)  # manubrio
        d.rectangle([3, 5, 8, 14], fill=shirt)
        head = helmet if moto else (skin if view == "down" else hair)
        d.ellipse([3, 0, 8, 5], fill=head)
        if view == "down" and not moto:
            d.point([(4, 2), (7, 2)], fill=INK)
        d.point((5, 15), fill=LIGHT if view == "down" else TAIL)
        leg = 1 if frame else 0
        d.rectangle([3, 14 + leg, 4, 19 + leg], fill=pants)
        d.rectangle([7, 15 - leg, 8, 20 - leg], fill=pants)
    outline(img)
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name in CARS:
        for f, tag in ((0, "a"), (1, "b")):
            car_side(name, f).save(OUT / f"car_{name}_side_{tag}.png")
            car_front(name, f, False).save(OUT / f"car_{name}_down_{tag}.png")
            car_front(name, f, True).save(OUT / f"car_{name}_up_{tag}.png")
    for kind in ("bici", "moto"):
        for view in ("side", "down", "up"):
            for f, tag in ((0, "a"), (1, "b")):
                rider(kind, view, f).save(OUT / f"{kind}_{view}_{tag}.png")
    print("tráfico:", OUT)


if __name__ == "__main__":
    main()
