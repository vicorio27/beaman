"""Las viñetas de la tele (la vitrina de TV RADIO): una por cada programa que le puede tocar ver.

    python tools/art/draw_vinetas_tele.py              -> assets/ui/vinetas_tele.png (17 filas de 4 cuadros)
    python tools/art/draw_vinetas_tele.py --prueba x.png 0 5 9   una hoja para mirar (el cuadro 1)

Lo mismo en todas: el televisor grande de la vitrina (y los otros dos, a los lados, con el mismo canal),
el vidrio con su reflejo, y abajo, en la vereda, él de espaldas y Lukas echado; la luz de la pantalla
les pega en la espalda, del color de lo que estén dando. Adentro de la pantalla, el programa, animado.
El orden de las filas es el de TV_SHOWS en autoload/Conversations.gd (TELE_FILAS).
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from vinetas_motor import (W, H, Cv, Env, Actor, col, mix, breath, vapor, man_stand, lukas_curl, _head, _limb,  # noqa: E402
                           COAT, PANTS, HAIR, SKIN, WHITE, BLACK)
from draw_vinetas import FONT, frame, small_man, _man_back_seated, _woman  # noqa: E402  (prende el acabado)

OUT = "assets/ui/vinetas_tele%s.png"  # (CALVO=2/3: él, quedándose calvo; ver draw_vinetas.py)
X0, Y0, SW, SH = 64, 9, 112, 62   # la pantalla grande
FRAMES = 4


def scr(cv):
    """La máscara de la pantalla (las esquinas redondeadas, como las de antes)."""
    m = cv.box(X0, Y0, X0 + SW, Y0 + SH)
    for (x, y) in [(X0, Y0), (X0 + SW - 1, Y0), (X0, Y0 + SH - 1), (X0 + SW - 1, Y0 + SH - 1)]:
        m[y, x] = False
    return m


def scene(f, program, glow, fg=None):
    """La vitrina, el programa en la pantalla y los de la vereda. glow: el color que echa la pantalla."""
    cv = Cv(f)
    env = Env((0.46, 0.44, 0.52), (1.1, 1.04, 0.98), (1, -1), half=0.35)
    dk = lambda alb, k=0.6: col(alb, env.amb * k)
    # Adentro de la tienda, oscuro; el marco de aluminio de la vitrina.
    cv.grad((0, 0, W, 88), [(36, 34, 46), (46, 42, 58), (40, 38, 52)])
    for x in (0, 119, 238):
        cv.fill(cv.box(x, 0, x + 2, 88), (120, 124, 136))
    cv.fill(cv.box(0, 0, W, 2), (120, 124, 136))
    # Los dos de los lados: el mismo canal, sin detalle (se ve la luz).
    for x0 in (8, 196):
        cv.shape(cv.box(x0, 30, x0 + 38, 66), (54, 54, 62), env, shade=1, half=False)
        cv.grad((x0 + 3, 33, x0 + 35, 60), [mix(glow, (20, 20, 30), 0.35), mix(glow, (20, 20, 30), 0.6)])
        cv.glow(x0 + 19, 46, 26, glow, 0.35)
        cv.fill(cv.box(x0 + 6, 66, x0 + 32, 70), dk((70, 66, 78)))
    # El grande: la caja de madera, la pantalla, las perillas, la rejilla del parlante.
    cv.shape(cv.mask(lambda d: d.rect(56, 3, 192, 78)), (122, 84, 56), env, shade=2)
    cv.fill(cv.box(58, 76, 190, 80), dk((90, 62, 44)))
    for xx in (66, 182):  # las patas
        cv.fill(cv.box(xx, 80, xx + 3, 88), dk((70, 50, 36), 0.9))
    prog = Cv(f)
    program(prog, f)
    m = scr(cv)
    cv.a[m] = prog.a[m]
    cv.post += prog.post
    # Las rayas de la pantalla (una sí, una no, un poquito más oscura) y el brillo del vidrio curvo.
    rows = np.zeros((H, W), bool)
    rows[Y0 + 1:Y0 + SH:2, :] = True
    sl = m & rows
    cv.a[sl] = (cv.a[sl].astype(float) * 0.86).astype(np.uint8)
    glare = cv.mask(lambda d: d.poly([(X0 + 6, Y0 + 2), (X0 + 22, Y0 + 2), (X0 + 4, Y0 + 24), (X0 + 2, Y0 + 14)])) & m
    cv.veil(glare, (230, 236, 250), 0.18)
    for k, yy in enumerate((22, 34)):  # las perillas
        cv.shape(cv.mask(lambda d, yy=yy: d.ell(184, yy, 3, 3)), (200, 190, 160), env, shade=1)
    for yy in range(46, 70, 3):
        cv.fill(cv.box(181, yy, 188, yy + 1), dk((60, 42, 30), 0.8))
    # El vidrio de la vitrina: dos rayas de reflejo, de punta a punta.
    for x0 in (20, 150):
        cv.veil(cv.mask(lambda d, x0=x0: d.poly([(x0, 0), (x0 + 10, 0), (x0 - 34, 88), (x0 - 44, 88)])), (190, 200, 220), 0.12)
    # La vereda.
    cv.grad((0, 88, W, H), [(96, 94, 100), (80, 78, 86)])
    cv.fill(cv.box(0, 88, W, 89), (130, 128, 136))
    # La luz de la tele, en la vereda y en ellos.
    cv.glow(120, 92, 90, glow, 0.5, squash=0.35)
    lit = Env((0.42, 0.42, 0.48), tuple(np.array(glow) / 210.0 + 0.25), (0, -1), half=0.3)
    _man_back_seated(cv, lit, 34, 100)
    lukas_curl(Actor(cv, lit, 58, 99), breath(f))
    if fg:
        fg(cv, lit, f)
    return cv


# ---------------------------------------------------------------- Los programas (en la pantalla)

def _studio(cv, top, bottom):
    cv.grad((X0, Y0, X0 + SW, Y0 + SH), [top, bottom])


def _banner(cv, text, bg, fg=(255, 255, 255), y=None):
    y = Y0 + SH - 11 if y is None else y
    cv.fill(cv.box(X0, y, X0 + SW, y + 10), bg)
    cv.fill(cv.box(X0, y, X0 + SW, y + 1), mix(bg, (255, 255, 255), 0.4))
    cv.post.append(lambda d: d.text((X0 + 3, y + 1), text, font=FONT, fill=fg))


def tv_cocina(cv, f):
    """Una señora sonríe demasiado y le enseña a otra a hacer arroz con pollo en cuatro minutos."""
    env = Env((0.8, 0.78, 0.74), (1.2, 1.15, 1.05), (1, -1), half=0.4)
    _studio(cv, (250, 226, 150), (240, 206, 130))
    for xx in range(X0, X0 + SW, 8):  # la baldosa
        for yy in range(Y0 + 6, Y0 + 40, 8):
            cv.fill(cv.box(xx, yy, xx + 7, yy + 7), (246, 238, 220) if (xx + yy) % 16 else (230, 240, 236))
    _woman(cv, env, X0 + 26, Y0 + 76, (240, 120, 150), (90, 50, 40), scale=0.95)         # la de la sonrisa
    _woman(cv, env, X0 + 86, Y0 + 76, (90, 150, 210), (40, 30, 30), flip=True, scale=0.9)
    cv.post.append(lambda d: d.line([(X0 + 25, Y0 + 30), (X0 + 29, Y0 + 30)], fill=(255, 255, 255)))  # los dientes
    cv.shape(cv.box(X0, Y0 + 44, X0 + SW, Y0 + SH), (150, 104, 70), env, shade=1, half=False)  # el mesón
    cv.shape(cv.mask(lambda d: d.rect(X0 + 48, Y0 + 36, X0 + 64, Y0 + 45)), (170, 170, 180), env, shade=1)  # la olla
    cv.fill(cv.box(X0 + 46, Y0 + 35, X0 + 66, Y0 + 37), (110, 110, 120))
    vapor(cv, f, X0 + 52, Y0 + 33, (250, 250, 250))
    vapor(cv, f, X0 + 59, Y0 + 32, (250, 250, 250), dx=-1)
    cv.post.append(lambda d: d.text((X0 + 84, Y0 + 3), "4:00" if f % 2 == 0 else "3:59", font=FONT, fill=(200, 40, 50)))


def tv_horoscopo(cv, f):
    """Una mujer de turbante señala un cartel de Géminis con mucha seriedad."""
    env = Env((0.6, 0.5, 0.7), (1.2, 1.0, 1.25), (1, -1), half=0.4)
    _studio(cv, (40, 20, 70), (90, 40, 120))
    for i, (sx, sy) in enumerate([(8, 6), (30, 14), (100, 8), (88, 30), (14, 40), (60, 4), (106, 50)]):
        if (i + f) % 3:
            cv.px(X0 + sx, Y0 + sy, (255, 240, 180))
    cv.shape(cv.box(X0 + 56, Y0 + 8, X0 + 104, Y0 + 46), (240, 220, 160), env, shade=1, half=False)  # el cartel
    cv.post.append(lambda d: (d.line([(X0 + 72, Y0 + 16), (X0 + 72, Y0 + 36)], fill=(120, 40, 140), width=2),
                              d.line([(X0 + 86, Y0 + 16), (X0 + 86, Y0 + 36)], fill=(120, 40, 140), width=2),
                              d.line([(X0 + 66, Y0 + 15), (X0 + 92, Y0 + 15)], fill=(120, 40, 140), width=2),
                              d.line([(X0 + 66, Y0 + 37), (X0 + 92, Y0 + 37)], fill=(120, 40, 140), width=2)))
    a = _woman(cv, env, X0 + 30, Y0 + 62, (150, 60, 160), (40, 30, 40), scale=0.66)
    a.part((230, 200, 80), lambda d: (d.ell(1, -60, 8, 6), d.ell(0, -66, 5, 4)), shade=1)     # el turbante
    a.part((150, 60, 160), lambda d: d.path([(3, -40), (16 + (f % 2), -46), (26, -50)], 3.6))  # el brazo, señalando
    a.part(SKIN, lambda d: d.ell(27, -50, 1.8, 1.8), shade=0)
    a.dot(1, -58, (220, 60, 60))                                                                # la joya del turbante


def tv_aerobicos(cv, f):
    """Aeróbicos: cinco en licra saltando en un set que parece una piscina sin agua."""
    _studio(cv, (120, 200, 230), (150, 220, 240))
    for xx in range(X0, X0 + SW, 6):
        cv.fill(cv.box(xx, Y0, xx + 1, Y0 + SH), (110, 186, 216))
    for yy in range(Y0, Y0 + SH, 6):
        cv.fill(cv.box(X0, yy, X0 + SW, yy + 1), (110, 186, 216))
    cv.fill(cv.box(X0, Y0 + 50, X0 + SW, Y0 + SH), (90, 160, 196))
    cv.post.append(lambda d: [d.line([(X0 + 100 + k * 4, Y0 + 20), (X0 + 100 + k * 4, Y0 + 52)], fill=(220, 230, 240)) for k in range(2)])  # la escalerita
    for k, c in enumerate([(240, 60, 140), (250, 210, 40), (60, 200, 120), (250, 120, 40), (150, 80, 220)]):
        up = (k + f) % 2 == 0
        x, y = X0 + 12 + k * 20, Y0 + 52 - (4 if up else 0)
        small_man(cv, x, y, 0.62, c)
        arms = [(x - 4, y - 22), (x - 7, y - 34 if up else y - 18)], [(x + 4, y - 22), (x + 7, y - 34 if up else y - 18)]
        cv.post.append(lambda d, arms=arms, c=c: [d.line(a, fill=c, width=2) for a in arms])
        cv.post.append(lambda d, x=x, y=y: d.line([(x - 2, y - 36), (x + 2, y - 36)], fill=(255, 255, 255)))  # la balaca


def _anchor(cv, env, x, y, tie=(200, 40, 50), hair=(40, 34, 30), glasses=False):
    """El de las noticias, de frente, de los hombros para arriba (y = los hombros)."""
    cv.shape(cv.mask(lambda d: d.cap(x - 11, y + 8, x + 11, y + 8, 16)), (74, 74, 84), env, shade=2)   # el saco
    cv.fill(cv.mask(lambda d: d.poly([(x - 4, y), (x + 4, y), (x, y + 10)])), (240, 240, 236))           # la camisa
    cv.fill(cv.mask(lambda d: d.poly([(x - 1.5, y + 1), (x + 1.5, y + 1), (x + 2, y + 9), (x, y + 11), (x - 2, y + 9)])), tie)
    cv.shape(cv.box(x - 2, y - 4, x + 3, y + 1), SKIN, env, shade=0, half=False)                         # el cuello
    cv.shape(cv.mask(lambda d: d.ell(x, y - 10, 6.5, 8)), SKIN, env, shade=2)                            # la cara
    cv.fill(cv.mask(lambda d: (d.ell(x, y - 17, 7, 3.5), d.rect(x - 7, y - 17, x - 5, y - 11))), hair)   # el pelo, de lado
    for ex in (x - 3, x + 2):
        cv.px(ex, y - 10, (30, 26, 30))
    cv.fill(cv.box(x - 2, y - 5, x + 3, y - 4), (150, 80, 70))                                          # la boca, seria
    if glasses:
        cv.post.append(lambda d: d.line([(x - 5, y - 10), (x + 4, y - 10)], fill=(30, 30, 34)))


def tv_noticias1(cv, f):
    """El noticiero: un señor de corbata habla con cara de que se murió alguien. ÚLTIMA HORA."""
    env = Env((0.6, 0.62, 0.74), (1.15, 1.15, 1.25), (1, -1), half=0.4)
    _studio(cv, (30, 50, 110), (20, 34, 80))
    for k in range(4):  # el mapa del mundo, de fondo
        cv.fill(cv.mask(lambda d, k=k: d.ell(X0 + 16 + k * 26, Y0 + 16 + (k % 2) * 8, 9, 6)), (40, 70, 140))
    _anchor(cv, env, X0 + 56, Y0 + 32)
    cv.shape(cv.box(X0 + 14, Y0 + 44, X0 + 98, Y0 + 52), (180, 186, 200), env, shade=1, half=False)  # el escritorio
    cv.fill(cv.box(X0 + 14, Y0 + 44, X0 + 98, Y0 + 45), (230, 234, 244))
    _banner(cv, "ULTIMA HORA", (200, 30, 40) if f % 2 == 0 else (230, 50, 50))


def tv_noticias2(cv, f):
    """Un trancón de dos horas, visto desde arriba. Y un perro que se subió solo a un bus."""
    _studio(cv, (90, 90, 96), (80, 80, 86))
    for k in range(3):  # los carriles
        cv.fill(cv.box(X0, Y0 + 8 + k * 16, X0 + SW, Y0 + 9 + k * 16), (200, 200, 180))
    rng = np.random.default_rng(4)
    for lane in range(3):
        for x in range(X0 + 2, X0 + SW - 8, 12):
            c = [(200, 40, 40), (230, 230, 230), (40, 80, 160), (240, 200, 40), (60, 60, 70)][int(rng.integers(0, 5))]
            cv.fill(cv.box(x, Y0 + 11 + lane * 16, x + 9, Y0 + 20 + lane * 16), c)
            cv.fill(cv.box(x + 2, Y0 + 12 + lane * 16, x + 6, Y0 + 14 + lane * 16), (120, 150, 180))
    # El bus del perro, con el recuadro.
    cv.fill(cv.box(X0 + 70, Y0 + 26, X0 + 108, Y0 + 46), (255, 255, 255))
    cv.fill(cv.box(X0 + 71, Y0 + 27, X0 + 107, Y0 + 45), (60, 160, 90))
    for k in range(4):
        cv.fill(cv.box(X0 + 73 + k * 8, Y0 + 30, X0 + 79 + k * 8, Y0 + 36), (170, 210, 230))
    cv.fill(cv.mask(lambda d: (d.ell(X0 + 93, Y0 + 34, 2.6, 2.4), d.ell(X0 + 91, Y0 + 33 + (f % 2) * 0.6, 1.2, 2.2))), (190, 130, 70))  # el perro
    cv.px(X0 + 95, Y0 + 34, (30, 20, 20))
    _banner(cv, "EN VIVO", (40, 40, 60), (255, 210, 60))


def tv_noticias3(cv, f):
    """Un experto en algo habla delante de una biblioteca. LA ECONOMÍA CRECE."""
    env = Env((0.66, 0.6, 0.56), (1.2, 1.1, 0.95), (1, -1), half=0.4)
    _studio(cv, (90, 60, 40), (70, 46, 30))
    rng = np.random.default_rng(9)
    for shelf in range(3):  # la biblioteca
        y = Y0 + 4 + shelf * 15
        x = X0 + 2
        while x < X0 + SW - 4:
            w = int(rng.integers(3, 6))
            cv.fill(cv.box(x, y, x + w - 1, y + 12), [(160, 40, 40), (40, 90, 60), (200, 170, 90), (50, 60, 130), (120, 80, 50)][int(rng.integers(0, 5))])
            x += w
        cv.fill(cv.box(X0, y + 12, X0 + SW, y + 14), (60, 40, 26))
    _anchor(cv, env, X0 + 30, Y0 + 40, tie=(60, 90, 160), hair=(170, 170, 170), glasses=True)
    cv.fill(cv.box(X0 + 60, Y0 + 14, X0 + 106, Y0 + 44), (240, 240, 236))  # la gráfica que sube
    pts = [(X0 + 64, Y0 + 40), (X0 + 74, Y0 + 36), (X0 + 82, Y0 + 38), (X0 + 92, Y0 + 26), (X0 + 102, Y0 + 18 - f)]
    cv.post.append(lambda d: d.line(pts, fill=(40, 160, 70), width=2))
    _banner(cv, "ECONOMIA CRECE", (30, 40, 90))


def _sala(cv):
    _studio(cv, (120, 60, 70), (90, 40, 50))
    for x in (X0 + 4, X0 + 96):  # las cortinas
        cv.fill(cv.box(x, Y0, x + 12, Y0 + SH), (170, 40, 60))
        for k in range(3):
            cv.fill(cv.box(x + 2 + k * 4, Y0, x + 3 + k * 4, Y0 + SH), (130, 30, 46))


def tv_novela1(cv, f):
    """Ella le tira un vaso de agua en la cara. Él no reacciona. Ella llora."""
    env = Env((0.66, 0.56, 0.58), (1.25, 1.05, 1.0), (1, -1), half=0.45)
    _sala(cv)
    ella = _woman(cv, env, X0 + 34, Y0 + 66, (230, 230, 236), (60, 40, 30), scale=0.7)
    el = Actor(cv, env, X0 + 80, Y0 + 68, flip=True, scale=0.7)
    man_stand(el, coat=(40, 40, 50), hair=(30, 26, 26), beard=None)
    if f == 0:   # el vaso en la mano
        ella.part((180, 220, 240), lambda d: d.rect(12, -46, 16, -40), shade=0)
    elif f == 1:  # lo tira
        cv.post.append(lambda d: d.line([(X0 + 48, Y0 + 32), (X0 + 60, Y0 + 26), (X0 + 72, Y0 + 30)], fill=(170, 220, 250), width=2))
    elif f == 2:  # le cae
        for k in range(8):
            cv.px(X0 + 74 + (k * 3) % 9, Y0 + 26 + k, (170, 220, 250))
    else:         # ella llora
        cv.post.append(lambda d: (d.line([(X0 + 33, Y0 + 30), (X0 + 33, Y0 + 34)], fill=(170, 220, 250)),
                                  d.line([(X0 + 36, Y0 + 30), (X0 + 36, Y0 + 33)], fill=(170, 220, 250))))


def tv_novela2(cv, f):
    """La villana: pelo largo y negro, moño rosado, boca pintada. Grita por teléfono."""
    env = Env((0.62, 0.5, 0.66), (1.3, 1.0, 1.2), (1, -1), half=0.45)
    _studio(cv, (80, 30, 90), (40, 16, 50))
    z = 1.0 + (0.05 if f % 2 else 0.0)  # el zoom dramático
    a = Actor(cv, env, X0 + 56, Y0 + 104, scale=1.5 * z)
    a.part((24, 20, 26), lambda d: d.poly([(-10, -60), (10, -60), (13, -30), (-12, -30)]), shade=2)  # el pelo
    a.part((180, 30, 70), lambda d: d.cap(0, -24, 0, -34, 20))                                    # los hombros
    a.part(SKIN, lambda d: d.ell(0, -47, 7.5, 9), shade=2)
    a.part((24, 20, 26), lambda d: d.poly([(-8, -55), (8, -55), (9, -48), (-9, -50)]), shade=1)  # el fleco
    a.part((246, 140, 180), lambda d: (d.ell(-6, -58, 3.5, 2.4), d.ell(1, -58, 3.5, 2.4)), shade=1)  # el moño
    a.part((40, 40, 46), lambda d: d.rect(8, -54, 11, -40), shade=0)                              # el teléfono
    a.dot(-3, -48, (30, 20, 30))
    a.dot(3, -48, (30, 20, 30))
    a.part((200, 20, 50), lambda d: d.ell(0, -41, 2.6, 1.4 + (f % 2) * 1.2), shade=0)            # la boca, gritando


def tv_novela3(cv, f):
    """Un señor despierta de un coma de veinte años y lo primero que pregunta es por la herencia."""
    env = Env((0.7, 0.76, 0.78), (1.15, 1.2, 1.2), (1, -1), half=0.4)
    _studio(cv, (200, 220, 220), (170, 196, 200))
    cv.fill(cv.box(X0, Y0 + 40, X0 + SW, Y0 + SH), (150, 176, 180))
    cv.shape(cv.box(X0 + 10, Y0 + 34, X0 + 92, Y0 + 46), (240, 240, 244), env, shade=1, half=False)  # la cama
    cv.fill(cv.box(X0 + 10, Y0 + 46, X0 + 14, Y0 + SH), (150, 156, 166))
    cv.fill(cv.box(X0 + 88, Y0 + 46, X0 + 92, Y0 + SH), (150, 156, 166))
    cv.shape(cv.box(X0 + 40, Y0 + 30, X0 + 92, Y0 + 38), (150, 190, 210), env, shade=1, half=False)  # la cobija
    cv.shape(cv.mask(lambda d: d.ell(X0 + 18, Y0 + 32, 8, 4)), (250, 250, 250), env, shade=1)        # la almohada
    if f == 0:  # dormido, todavía: acostado
        cv.shape(cv.mask(lambda d: d.cap(X0 + 26, Y0 + 32, X0 + 44, Y0 + 32, 8)), (150, 190, 210), env, shade=1)
        cv.shape(cv.mask(lambda d: d.ell(X0 + 20, Y0 + 28, 5, 4.5)), SKIN, env, shade=1)
        cv.fill(cv.mask(lambda d: d.ell(X0 + 17, Y0 + 26, 4, 2.4)), (230, 230, 230))
    else:       # de un brinco, sentado, la mano arriba: "¿y la herencia?"
        cv.shape(cv.mask(lambda d: d.cap(X0 + 36, Y0 + 32, X0 + 36, Y0 + 16, 11)), (150, 190, 210), env, shade=2)
        cv.shape(cv.mask(lambda d: d.ell(X0 + 36, Y0 + 9, 6, 6.5)), SKIN, env, shade=2)
        cv.fill(cv.mask(lambda d: d.ell(X0 + 34, Y0 + 4, 6, 3)), (236, 236, 236))                   # el pelo, blanco
        cv.fill(cv.mask(lambda d: d.ell(X0 + 39, Y0 + 12, 1.6, 1.0 + (f % 2) * 0.8)), (110, 40, 40))  # la boca
        cv.px(X0 + 38, Y0 + 8, (30, 30, 34))
        cv.shape(cv.mask(lambda d: d.path([(X0 + 41, Y0 + 20), (X0 + 48, Y0 + 12), (X0 + 49, Y0 + 4 - (f % 2))], 3.4)), (150, 190, 210), env, shade=1)
        cv.shape(cv.mask(lambda d: d.ell(X0 + 49, Y0 + 3 - (f % 2), 2, 2)), SKIN, env, shade=0)
    cv.shape(cv.box(X0 + 94, Y0 + 8, X0 + 110, Y0 + 24), (60, 66, 76), env, shade=1, half=False)     # el monitor
    beat = [(0, 6), (4, 6), (6, 2), (8, 10), (10, 6), (14, 6)]
    jump = 4 if f else 0  # se le dispara el pulso
    pts = [(X0 + 95 + x, Y0 + 10 + y - (jump if 2 <= x <= 8 else 0)) for x, y in beat]
    cv.post.append(lambda d: d.line(pts, fill=(80, 250, 120)))


def _pista(cv, wet=False):
    _studio(cv, (90, 150, 90), (70, 130, 70))
    cv.fill(cv.box(X0, Y0 + 20, X0 + SW, Y0 + 46), (70, 72, 80) if not wet else (60, 64, 76))
    for x in range(X0, X0 + SW, 8):
        cv.fill(cv.box(x, Y0 + 19, x + 4, Y0 + 21), (220, 40, 40))
        cv.fill(cv.box(x + 4, Y0 + 19, x + 8, Y0 + 21), (240, 240, 240))
        cv.fill(cv.box(x, Y0 + 45, x + 4, Y0 + 47), (220, 40, 40))
        cv.fill(cv.box(x + 4, Y0 + 45, x + 8, Y0 + 47), (240, 240, 240))


def _f1(cv, x, y, c, angle=0.0):
    """Un carro de Fórmula 1, de lado, chiquito (24x8)."""
    m = cv.mask(lambda d: (d.poly([(-12, 0), (12, 0), (12, -3), (2, -4), (-2, -7), (-8, -6), (-12, -4)]),
                           d.rect(-13, -8, -10, -4), d.rect(10, -3, 14, -1)), x, y)
    if angle:
        ys, xs = np.nonzero(m)
        rot = np.zeros_like(m)
        c_, s_ = np.cos(angle), np.sin(angle)
        rx = (x + (xs - x) * c_ - (ys - y) * s_).round().astype(int)
        ry = (y + (xs - x) * s_ + (ys - y) * c_).round().astype(int)
        ok = (rx >= 0) & (rx < W) & (ry >= 0) & (ry < H)
        rot[ry[ok], rx[ok]] = True
        m = rot
    cv.fill(m, c)
    for wx in (-8, 8):
        cv.fill(cv.mask(lambda d, wx=wx: d.ell(x + wx, y, 2.6, 2.6)), (20, 20, 24))
    cv.px(x - 3, y - 6, (240, 220, 60))  # el casco


def tv_f1a(cv, f):
    """Veinte carros dando vueltas. Uno se sale."""
    _pista(cv)
    for k, c in enumerate([(220, 30, 30), (40, 60, 200), (240, 140, 20)]):
        _f1(cv, X0 + ((k * 40 + f * 22) % (SW + 20)) - 10, Y0 + 30 + k * 6, c)
    x = X0 + 70 + f * 6  # el que se sale, a la grava, levantando polvo
    cv.fill(cv.box(X0 + 60, Y0 + 47, X0 + SW, Y0 + 58), (190, 170, 120))
    _f1(cv, x, Y0 + 52 + min(f, 2), (30, 140, 90), angle=0.2 * f)
    for k in range(f + 1):
        cv.fill(cv.mask(lambda d, k=k: d.ell(x - 12 - k * 5, Y0 + 52 - k, 3 + k, 2 + k)), (220, 200, 160))


def tv_f1b(cv, f):
    """Una parada en pits: cuatro llantas en dos segundos. Veinte mecánicos para un carro."""
    _studio(cv, (60, 60, 70), (90, 90, 100))
    cv.fill(cv.box(X0, Y0 + 38, X0 + SW, Y0 + SH), (110, 110, 120))
    for k, x in enumerate((14, 26, 86, 98)):  # los mecánicos, a lado y lado, cambiando llantas
        bob = 1 if (k + f) % 2 else 0
        small_man(cv, X0 + x, Y0 + 50 + bob, 0.42, (220, 30, 30) if k % 2 else (240, 240, 240))
    _f1(cv, X0 + 56, Y0 + 46, (220, 30, 30))
    for wx in (-8, 8):  # las llantas nuevas, rodando hacia el carro
        cv.fill(cv.mask(lambda d, wx=wx: d.ell(X0 + 56 + wx * (2.4 - f * 0.35), Y0 + 54, 2.6, 2.6)), (30, 30, 34))
    cv.post.append(lambda d: d.text((X0 + 70, Y0 + 4), "2.%d" % (1 + f), font=FONT, fill=(255, 220, 60)))


def tv_f1c(cv, f):
    """Llueve en la pista. Un carro da un trompo y sigue como si nada."""
    _pista(cv, wet=True)
    _f1(cv, X0 + 56, Y0 + 34, (40, 60, 200), angle=f * 1.57)
    for k in range(40):  # la lluvia
        x = X0 + (k * 37 + f * 5) % SW
        y = Y0 + (k * 23 + f * 9) % SH
        cv.post.append(lambda d, x=x, y=y: d.line([(x, y), (x - 1, y + 3)], fill=(200, 210, 230)))
    cv.fill(cv.mask(lambda d: d.ell(X0 + 56, Y0 + 40, 18, 3)), (100, 106, 124))  # el agua que levanta


def tv_f1d(cv, f):
    """En el podio, tres pilotos se bañan en champaña."""
    env = Env((0.7, 0.66, 0.7), (1.2, 1.15, 1.1), (1, -1), half=0.4)
    _studio(cv, (30, 30, 50), (60, 60, 90))
    for x, h, c in [(X0 + 22, 14, (200, 200, 210)), (X0 + 56, 22, (240, 200, 60)), (X0 + 90, 10, (200, 130, 70))]:
        cv.shape(cv.box(x - 12, Y0 + SH - h, x + 12, Y0 + SH), c, env, shade=1, half=False)
        small_man(cv, x, Y0 + SH - h, 0.5, [(220, 30, 30), (40, 60, 200), (240, 140, 20)][int((x - X0) // 34)])
    for k, (sx, d_) in enumerate([(X0 + 56, 1), (X0 + 22, 1), (X0 + 90, -1)]):  # la champaña
        pts = [(sx + d_ * (i * 4), Y0 + 26 - i * (3 - i * 0.3) + f) for i in range(6)]
        cv.post.append(lambda dd, pts=pts: dd.line(pts, fill=(250, 240, 180), width=1))
    for i in range(12):
        cv.px(X0 + (i * 29 + f * 7) % SW, Y0 + (i * 13 + f * 5) % 30, [(255, 80, 80), (80, 200, 255), (255, 230, 80)][i % 3])


def tv_f1e(cv, f):
    """El DRS: el alerón de atrás se abre. En la vereda, uno se lo explica a otro. Ninguno sabe."""
    _pista(cv)
    _f1(cv, X0 + 56, Y0 + 36, (220, 30, 30))
    open_ = f % 2 == 1
    cv.fill(cv.box(X0 + 42, Y0 + 26 - (3 if open_ else 0), X0 + 47, Y0 + 28 - (3 if open_ else 0)), (40, 40, 46))  # la aleta
    cv.post.append(lambda d: d.text((X0 + 4, Y0 + 4), "DRS", font=FONT, fill=(80, 250, 120) if open_ else (90, 90, 90)))


def _back(cv, env, x, c, hair, arm_l=None, arm_r=None, top=-27.0):
    """Un señor de espaldas, de la cintura para arriba (el borde de abajo del cuadro lo corta): la
    espalda que se angosta, los hombros, la nuca, las orejas y el pelo. arm_l / arm_r: a dónde va cada
    mano (None: el brazo colgando)."""
    a = Actor(cv, env, x, 100)
    for side, hand in ((-1, arm_l), (1, arm_r)):
        sh = (side * 6.6, top + 0.8)
        if hand is None:
            el, hd = (side * 7.6, top + 12.0), (side * 7.0, top + 22.0)
        else:
            el = ((sh[0] + hand[0]) / 2 + side * 2.0, (sh[1] + hand[1]) / 2 + 1.0)
            hd = hand
        a.part(c, lambda d, sh=sh, el=el, hd=hd: (_limb(d, sh, 2.5, el, 2.2), _limb(d, el, 2.2, hd, 1.8)), emph=a.emph * 0.9)
        if hand is not None:
            a.part(SKIN, lambda d, hd=hd: d.ell(hd[0], hd[1] - 1.0, 1.6, 1.5), shade=1)
    a.part(c, lambda d: (d.poly([(-6.8, top), (6.8, top), (5.6, top + 15.0), (6.2, 0.0), (-6.2, 0.0), (-5.6, top + 15.0)]),
                         d.ell(-5.2, top + 1.2, 2.8, 2.6), d.ell(5.2, top + 1.2, 2.8, 2.6)), shade=3)
    a.line([(0, top + 0.6), (0, top + 18.0)], col(c, env.amb * 0.55))            # la costura
    a.part(SKIN, lambda d: d.rect(-1.6, top - 3.0, 1.6, top), shade=0)            # la nuca
    a.part(SKIN, lambda d: (d.ell(-3.6, top - 5.4, 1.0, 1.6), d.ell(3.6, top - 5.4, 1.0, 1.6)), shade=0, rim=False)
    a.part(hair, lambda d: (d.ell(0, top - 6.6, 3.6, 4.2), d.ell(-3.0, top - 4.2, 1.0, 1.4), d.ell(3.0, top - 4.2, 1.0, 1.4)), shade=2)
    return a


def _senores(cv, env, f, x0, arms=0.0, kick=False):
    """Dos señores de la vereda, de espaldas; con los brazos arriba (arms) o uno pateando un poste."""
    for k, c in enumerate([(120, 110, 90), (70, 90, 120)][:1 if kick else 2]):
        x = x0 + k * 26
        hair = (60, 50, 44) if k else (150, 150, 150)
        if arms:
            up = -46 - (2 if (f + k) % 2 else 0)
            _back(cv, env, x, c, hair, (-10.0, up), (10.0, up))
        elif k == 0 and not kick:
            _back(cv, env, x, c, hair, None, (13.0, -33.0 - (f % 2) * 3))      # explicando (con la mano)
        else:
            _back(cv, env, x, c, hair)
    if kick:
        cv.shape(cv.box(x0 + 44, 40, x0 + 47, 100), (110, 112, 120), env, shade=1, half=False)  # el poste
        a = Actor(cv, env, x0 + 32, 100)
        foot = (11.0, -13.0) if f % 2 else (5.0, -3.0)
        a.part((50, 50, 60), lambda d: (_limb(d, (0.0, -6.0), 3.0, ((foot[0]) / 2 + 1.0, (foot[1] - 6.0) / 2 - 1.0), 2.4),
                                        _limb(d, ((foot[0]) / 2 + 1.0, (foot[1] - 6.0) / 2 - 1.0), 2.4, foot, 1.9)))   # la patada
        _back(cv, env, x0 + 32, (160, 60, 50), (60, 50, 44), top=-29.0)


def _cancha(cv):
    _studio(cv, (70, 150, 70), (60, 130, 60))
    for x in range(X0, X0 + SW, 14):
        cv.fill(cv.box(x, Y0, x + 7, Y0 + SH), (78, 160, 76))
    cv.fill(cv.box(X0, Y0 + 2, X0 + SW, Y0 + 12), (40, 40, 60))  # la tribuna
    for k in range(40):
        cv.px(X0 + (k * 13) % SW, Y0 + 3 + (k * 7) % 8, [(240, 200, 40), (220, 40, 40), (240, 240, 240)][k % 3])


def tv_futbol1(cv, f):
    """Gol. Los de la vereda gritan; él no grita, pero levanta un brazo."""
    _cancha(cv)
    cv.fill(cv.box(X0 + 70, Y0 + 18, X0 + 106, Y0 + 40), (220, 220, 220))  # el arco y la red
    for x in range(X0 + 72, X0 + 106, 3):
        cv.fill(cv.box(x, Y0 + 20, x + 1, Y0 + 40), (150, 160, 150))
    cv.fill(cv.mask(lambda d: d.ell(X0 + 92, Y0 + 34 - (f % 2), 2.4, 2.4)), (250, 250, 250))
    small_man(cv, X0 + 40, Y0 + 56 - (3 if f % 2 else 0), 0.5, (240, 200, 40))    # el que hizo el gol, saltando
    small_man(cv, X0 + 84, Y0 + 50, 0.5, (40, 40, 40), lean=1.0)                    # el arquero, en el piso


def fg_gol(cv, env, f):
    _senores(cv, env, f, 150, arms=1.0)
    a = Actor(cv, env, 34, 100)  # su brazo, arriba (uno solo)
    up = -50.0 - (f % 2) * 2
    a.part(COAT, lambda d: (_limb(d, (6.6, -26.4), 2.5, (9.6, -38.0), 2.2), _limb(d, (9.6, -38.0), 2.2, (10.6, up), 1.8)))
    a.part(SKIN, lambda d: d.ell(10.8, up - 1.2, 1.6, 1.6), shade=1)


def tv_futbol2(cv, f):
    """Penalti. El arquero adivina el lado. La cuadra entera dice uuuh."""
    _cancha(cv)
    cv.fill(cv.box(X0 + 30, Y0 + 16, X0 + 86, Y0 + 40), (220, 220, 220))
    for x in range(X0 + 32, X0 + 86, 3):
        cv.fill(cv.box(x, Y0 + 18, x + 1, Y0 + 40), (150, 160, 150))
    dive = [0, 6, 14, 18][f]
    small_man(cv, X0 + 58 - dive, Y0 + 40 + dive // 3, 0.5, (40, 40, 40), lean=-dive / 10.0)  # se tira
    bx = X0 + 58 - [0, 4, 10, 14][f]
    cv.fill(cv.mask(lambda d: d.ell(bx, Y0 + 44 - f * 2, 2.4, 2.4)), (250, 250, 250))
    small_man(cv, X0 + 60, Y0 + 60, 0.55, (220, 40, 40))


def tv_futbol3(cv, f):
    """Pierde el equipo de todos. Un señor patea un poste. El poste gana."""
    _cancha(cv)
    small_man(cv, X0 + 50, Y0 + 54, 0.6, (240, 200, 40))  # el jugador, de rodillas
    cv.fill(cv.box(X0 + 44, Y0 + 50, X0 + 56, Y0 + 54), (70, 150, 70))
    cv.post.append(lambda d: d.text((X0 + 66, Y0 + 16), "0-3", font=FONT, fill=(255, 255, 255)))


## El orden de TV_SHOWS en Conversations.gd: mañana (3), noticias (3), novela (3), f1 (5), futbol (3).
PROGRAMAS = [
    (tv_cocina, (250, 220, 160), None), (tv_horoscopo, (150, 90, 200), None), (tv_aerobicos, (140, 210, 240), None),
    (tv_noticias1, (90, 120, 220), None), (tv_noticias2, (150, 150, 150), None), (tv_noticias3, (200, 150, 100), None),
    (tv_novela1, (220, 120, 140), None), (tv_novela2, (190, 90, 200), None), (tv_novela3, (190, 230, 230), None),
    (tv_f1a, (130, 200, 130), None), (tv_f1b, (180, 180, 190), None), (tv_f1c, (150, 160, 190), None),
    (tv_f1d, (230, 220, 160), None), (tv_f1e, (130, 200, 130), lambda cv, env, f: _senores(cv, env, f, 160)),
    (tv_futbol1, (120, 210, 120), fg_gol), (tv_futbol2, (120, 210, 120), lambda cv, env, f: _senores(cv, env, f, 160, arms=0.5)),
    (tv_futbol3, (120, 210, 120), lambda cv, env, f: _senores(cv, env, f, 150, kick=True)),
]


def row(i):
    prog, glow, fg = PROGRAMAS[i]
    out = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
    for f in range(FRAMES):
        out.paste(frame(scene(f, prog, glow, fg).image()), (f * W, 0))
    return out


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--prueba":
        ids = [int(a) for a in sys.argv[3:]] or list(range(len(PROGRAMAS)))
        cols = 3
        rows_ = (len(ids) + cols - 1) // cols
        sheet = Image.new("RGB", (W * cols, H * rows_), (40, 0, 40))
        for k, i in enumerate(ids):
            prog, glow, fg = PROGRAMAS[i]
            sheet.paste(frame(scene(1, prog, glow, fg).image()).convert("RGB"), ((k % cols) * W, (k // cols) * H))
        sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(sys.argv[2])
        return
    sheet = Image.new("RGBA", (W * FRAMES, H * len(PROGRAMAS)), (0, 0, 0, 0))
    for i in range(len(PROGRAMAS)):
        sheet.paste(row(i), (0, i * H))
    from draw_vinetas import SUF
    sheet.save(OUT % SUF)
    print("tele: %d programas" % len(PROGRAMAS))


if __name__ == "__main__":
    main()
