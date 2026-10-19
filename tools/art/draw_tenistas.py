"""Los tenistas del torneo (Highway to Hell), vistos desde arriba y un poco de atrás, como la cancha.
Cada uno tiene dos filas: de espaldas (el que juega abajo) y de frente (el de arriba).

Cómo se dibujan: un esqueleto por pose (hombros, codos, manos, caderas, rodillas, pies y la raqueta)
que se pinta con piezas gruesas (2 px), el contorno oscuro del juego alrededor, y encima, a mano, lo de
cada uno (el pelo, la cara, las rayas, el tatuaje). Las proporciones son las de la gente del barrio
(unos 26 px de alto, ver draw_vecinos.py), con la raqueta aparte.

  Bublikov     altísimo y flaco, desgarbado; pelo negro despeinado; camiseta blanca con raya negra,
               pantaloneta negra. Juega como si le diera pereza (la espalda un poco caída).
  Sabalenkova  ancha de hombros, cola de caballo mona; top coral y falda; el tigre tatuado en el
               antebrazo izquierdo (rayas naranjas).
  Monfiz       alto, piel oscura, piernas largas; balaca amarilla; camiseta amarilla y negra.
  Yokovich     flaco y elástico; pelo castaño corto; camiseta roja, pantaloneta azul oscura.
  Moutette     bajito y zurdo; pelo negro crespo; camiseta celeste, pantaloneta blanca.
  Tiafuego     piel oscura, trencitas; verde limón y morado: el más vistoso.
  Sheltron     alto y zurdo, rapado; camiseta naranja, pantaloneta azul.
  Kyrgistán    la gorra roja al revés, todo de negro, tatuajes en el brazo de la raqueta.
  Pecador      el pelo zanahoria crespo, muy blanco; camiseta menta con cuello blanco.
  Fedorer      todo de blanco, balaca blanca, pelo café; la raqueta roja.
  Él           el recogebolas: la camiseta negra del torneo (con la franja roja) que le prestaron, y
               encima lo suyo: la corbata roja floja (de espaldas, tirada por encima del hombro), el
               jean, un zapato negro y uno rojo, la barba tupida con canas y el mechón parado. Sin
               raqueta (el.png); con la de cada uno cuando termina un partido (el_<id>.png).

Hoja: celdas de 50x48 (los pies en (25, 46)). Fila 0: de espaldas; fila 1: de frente. Columnas = POSES (ver abajo).
Salida: assets/tenis/<id>.png. Uso: python tools/art/draw_tenistas.py  (desde la carpeta del proyecto)
Con --preview guarda además una lámina ampliada en la carpeta temporal."""
import json
import math
import sys
from pathlib import Path
from PIL import Image

CW, CH = 50, 48
CX = CW // 2  # el centro de la celda (los números de las poses son relativos a él)
DY = 12  # todo baja 12 px: arriba queda lugar para la raqueta del saque, estirado
OUT = Path("assets/tenis")
OUTLINE = (40, 32, 44)
EYE = (30, 28, 36)

# Las poses, en orden, son POSES (al final de las poses): el orden de las columnas de la hoja. Va
# también en assets/tenis/tenistas.json, que es de donde lo lee TenisMatch.gd.

# ---------------------------------------------------------------- Las poses (de espaldas)
# Coordenadas en la celda, vistas de espaldas: la mano derecha (la de la raqueta) queda a la derecha.
# Cada pose: hombros y caderas (centro), y para cada lado: codo, mano, rodilla, pie. "rk": la raqueta
# desde la mano derecha: ángulo (grados, 0 = a la derecha, 90 = abajo) y si va delante del cuerpo.
# "lean": cuánto se agacha (baja todo). "tilt": cuánto se tuerce el tronco (px de los hombros).
# "two": la mano izquierda también en el mango (revés a dos manos).


def P(**k):
    base = {"lean": 0, "tilt": 0, "two": False, "front": False, "head_dx": 0}
    base.update(k)
    return base


# Ojo: y crece hacia abajo. Pies en y = 34. Los números son relativos al centro x = 16.
POSE = {
    "listo": P(el=(-5, 15), hl=(-3, 19), er=(4, 16), hr=(-1, 19), kl=(-3, 27), fl=(-5, 33), kr=(3, 27), fr=(5, 33),
               rk=(-150, False), two=True, lean=1),
    "listo2": P(el=(-5, 16), hl=(-3, 20), er=(4, 17), hr=(-1, 20), kl=(-4, 28), fl=(-6, 33), kr=(4, 28), fr=(6, 33),
                rk=(-145, False), two=True, lean=2),
    "corre1": P(el=(-6, 15), hl=(-7, 18), er=(5, 13), hr=(8, 15), kl=(-4, 25), fl=(-7, 30), kr=(2, 28), fr=(3, 33),
                rk=(-40, False)),
    "corre2": P(el=(-5, 14), hl=(-5, 18), er=(5, 15), hr=(6, 18), kl=(-2, 28), fl=(-2, 33), kr=(2, 27), fr=(2, 32),
                rk=(-50, False), lean=1),
    "corre3": P(el=(-5, 13), hl=(-8, 15), er=(6, 15), hr=(7, 18), kl=(-2, 28), fl=(-3, 33), kr=(4, 25), fr=(7, 30),
                rk=(-60, False)),
    "corre4": P(el=(-5, 15), hl=(-6, 18), er=(5, 14), hr=(6, 17), kl=(-2, 27), fl=(-2, 32), kr=(2, 28), fr=(2, 33),
                rk=(-50, False), lean=1),
    "drive_atras": P(el=(-4, 15), hl=(-1, 17), er=(7, 13), hr=(10, 15), kl=(-3, 27), fl=(-5, 33), kr=(4, 27), fr=(5, 33),
                     rk=(-150, False), tilt=2, lean=1),
    "drive": P(el=(-5, 15), hl=(-7, 17), er=(6, 15), hr=(9, 18), kl=(-3, 27), fl=(-5, 33), kr=(4, 27), fr=(5, 33),
               rk=(-30, True), tilt=0, lean=1),
    "drive_fin": P(el=(-6, 13), hl=(-3, 11), er=(1, 15), hr=(-4, 12), kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(6, 32),
                   rk=(-130, False), tilt=-2),
    "reves_atras": P(el=(-6, 14), hl=(-8, 17), er=(1, 15), hr=(-7, 17), kl=(-4, 27), fl=(-5, 33), kr=(3, 27), fr=(4, 33),
                     rk=(-30, False), two=True, tilt=-2, lean=1),
    "reves": P(el=(-5, 15), hl=(-6, 19), er=(2, 16), hr=(-5, 19), kl=(-4, 27), fl=(-6, 33), kr=(3, 27), fr=(4, 33),
               rk=(-150, True), two=True, lean=1),
    "reves_fin": P(el=(-3, 13), hl=(4, 11), er=(6, 13), hr=(5, 11), kl=(-3, 27), fl=(-6, 32), kr=(3, 27), fr=(4, 33),
                   rk=(-60, False), two=True, tilt=2),
    "saque_lanza": P(el=(-5, 8), hl=(-5, 3), er=(7, 15), hr=(9, 18), kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(4, 33),
                     rk=(80, False), tilt=-1),
    "saque": P(el=(-5, 13), hl=(-4, 16), er=(6, 8), hr=(5, 4), kl=(-2, 26), fl=(-3, 32), kr=(3, 27), fr=(4, 33),
               rk=(-100, False), lean=-1),
    "saque_fin": P(el=(-5, 15), hl=(-6, 18), er=(1, 16), hr=(-4, 20), kl=(-3, 27), fl=(-4, 33), kr=(4, 26), fr=(6, 31),
                   rk=(130, True), lean=2),
    "tirada": P(el=(4, 12), hl=(9, 11), er=(7, 13), hr=(11, 12), kl=(-7, 22), fl=(-12, 21), kr=(-6, 25), fr=(-12, 24),
                rk=(-10, False), dive=True),
    "piso": P(el=(4, 26), hl=(9, 28), er=(5, 29), hr=(10, 31), kl=(-7, 27), fl=(-12, 28), kr=(-6, 30), fr=(-12, 31),
              rk=(10, False), floor=True),
    "celebra": P(el=(-6, 8), hl=(-6, 4), er=(6, 8), hr=(6, 4), kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(4, 33),
                 rk=(-80, False), lean=-1),
    "bravo": P(el=(-5, 15), hl=(-4, 20), er=(5, 15), hr=(5, 20), kl=(-2, 27), fl=(-2, 33), kr=(2, 27), fr=(2, 33),
               rk=(95, False), lean=2, head_dx=0, down=True),
    "dejada": P(el=(-5, 15), hl=(-6, 18), er=(5, 16), hr=(7, 20), kl=(-4, 28), fl=(-7, 33), kr=(4, 26), fr=(5, 33),
                rk=(-10, True), lean=3),
    # El recogebolas: agachado al lado de la red, las manos en las rodillas, esperando el punto.
    "agachado": P(el=(-6, 18), hl=(-4, 23), er=(6, 18), hr=(4, 23), kl=(-5, 27), fl=(-5, 33), kr=(5, 27), fr=(5, 33),
                  rk=None, lean=4, down=True),
    # Recogiendo la pelota del piso: una mano abajo, la otra en la rodilla.
    "recoge": P(el=(-5, 18), hl=(-4, 23), er=(6, 21), hr=(7, 30), kl=(-4, 27), fl=(-6, 33), kr=(4, 28), fr=(5, 33),
                rk=None, lean=5, tilt=1, down=True),
    # El que abandona, ya sin la raqueta: caminando (los brazos sueltos), parado, hablando por celular,
    # doblado de la espalda, acostado (en la camilla, en la toalla) y con los brazos arriba (la tribuna).
    "camina1": P(el=(-6, 16), hl=(-4, 20), er=(6, 16), hr=(7, 21), kl=(-3, 27), fl=(-4, 32), kr=(2, 27), fr=(3, 33),
                 rk=None),
    "camina2": P(el=(-6, 16), hl=(-7, 21), er=(6, 16), hr=(4, 20), kl=(-2, 27), fl=(-3, 33), kr=(3, 27), fr=(4, 32),
                 rk=None),
    "parado": P(el=(-6, 16), hl=(-6, 21), er=(6, 16), hr=(6, 21), kl=(-2, 27), fl=(-3, 33), kr=(2, 27), fr=(3, 33),
                rk=None),
    "tel1": P(el=(-6, 16), hl=(-4, 20), er=(7, 11), hr=(4, 7), kl=(-3, 27), fl=(-4, 32), kr=(2, 27), fr=(3, 33),
              rk=None, phone=True),
    "tel2": P(el=(-6, 16), hl=(-7, 21), er=(7, 11), hr=(4, 7), kl=(-2, 27), fl=(-3, 33), kr=(3, 27), fr=(4, 32),
              rk=None, phone=True),
    "doblado": P(el=(-7, 19), hl=(-3, 22), er=(7, 19), hr=(3, 22), kl=(-2, 27), fl=(-3, 33), kr=(2, 27), fr=(3, 33),
                 rk=None, lean=6, down=True),
    "acostado": P(el=(0, 27), hl=(-4, 28), er=(0, 30), hr=(-4, 31), kl=(-7, 27), fl=(-12, 28), kr=(-6, 30), fr=(-12, 31),
                  rk=None, floor=True),
    "brazos": P(el=(-6, 8), hl=(-7, 3), er=(6, 8), hr=(7, 3), kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(4, 33),
                rk=None, lean=-1),
    # Solo la raqueta, tirada en el piso (la que deja el que se va), y rota (la de Kyrgistán).
    "suelta": P(rk=(-12, False), only="suelta"),
    "rota": P(rk=(-12, False), only="rota"),
}

# ---------------------------------------------------------------- Las poses en movimiento
# Para que se mueva fluido: más cuadros, y los del medio salen de mezclar dos poses (mix). Las de un lado
# ("_d": hacia la derecha de la pantalla) tienen su espejo ("_i") con mirror. "fwd": los brazos que van
# hacia adelante (hacia la red): de espaldas se tapan con el cuerpo; de frente, los que van hacia atrás.


def mirror(q):
    """La misma pose hacia el otro lado (de espaldas): x al revés, y la izquierda pasa a ser la derecha
    (la raqueta sigue en la mano derecha: toma el lugar que tenía la izquierda)."""
    out = dict(q)
    for a, b in (("el", "er"), ("hl", "hr"), ("kl", "kr"), ("fl", "fr")):
        if a in q and b in q:
            out[b] = (-q[a][0], q[a][1])
            out[a] = (-q[b][0], q[b][1])
    if q.get("rk") is not None:
        out["rk"] = (180 - q["rk"][0], q["rk"][1])
    out["tilt"] = -q["tilt"]
    out["head_dx"] = -q["head_dx"]
    out["fwd"] = tuple({"l": "r", "r": "l"}[k] for k in q.get("fwd", ()))
    out["bwd"] = tuple({"l": "r", "r": "l"}[k] for k in q.get("bwd", ()))
    return out


def mix(a, b, t):
    """Un cuadro intermedio: las articulaciones en línea recta de una pose a la otra; la raqueta, por el
    camino corto del ángulo."""
    out = dict(a if t < 0.5 else b)
    for k, va in a.items():
        vb = b.get(k)
        if k == "rk":
            if va is not None and vb is not None:
                d = (vb[0] - va[0] + 180) % 360 - 180
                out[k] = (va[0] + d * t, va[1] if t < 0.5 else vb[1])
        elif isinstance(va, tuple) and len(va) == 2 and all(isinstance(c, (int, float)) for c in va) \
                and isinstance(vb, tuple):
            out[k] = (va[0] + (vb[0] - va[0]) * t, va[1] + (vb[1] - va[1]) * t)
        elif isinstance(va, (int, float)) and not isinstance(va, bool) and isinstance(vb, (int, float)):
            out[k] = va + (vb - va) * t
    return out


GRIP = dict(el=(-5, 15), hl=(-3, 19), er=(4, 16), hr=(-1, 19), two=True)   # las dos manos en el mango
WIDE = dict(kl=(-4, 27), fl=(-6, 33), kr=(4, 27), fr=(6, 33))               # abierto, firme

# Correr de espaldas (hacia la red; al revés, para atrás): 8 cuadros. Media vuelta con el pie derecho en
# el piso (el izquierdo, el talón arriba, pasa y baja), y la otra media, igual con el otro pie.
_LEGS = [  # (rodilla y pie izquierdos, rodilla y pie derechos), con el derecho apoyado; y cuánto se agacha
    (dict(kl=(-3, 26), fl=(-3, 29), kr=(2, 27), fr=(2, 33)), 0),     # apoya el derecho; el izquierdo, atrás
    (dict(kl=(-2, 25), fl=(-2, 27), kr=(2, 27), fr=(2, 33)), 1),     # carga: el talón izquierdo arriba
    (dict(kl=(-2, 26), fl=(-3, 30), kr=(2, 27), fr=(3, 32)), 0),     # empuja; el izquierdo baja
    (dict(kl=(-2, 27), fl=(-3, 32), kr=(2, 26), fr=(2, 30)), -1),    # en el aire
]
# Los brazos: B atrás (se ve el codo y la mano junto a la cadera), M al lado, F adelante (tapado).
_ARM_R = {"B": ((6, 16), (7, 20), (62, True)), "M": ((6, 16), (7, 18), (-25, False)), "F": ((5, 15), (3, 13), (-82, False))}
_ARM_L = {"B": ((-6, 16), (-7, 20)), "M": ((-6, 16), (-8, 18)), "F": ((-5, 15), (-3, 13))}
_ARM_KEYS = [(0, "B"), (2.5, "M"), (4, "F"), (6.5, "M"), (8, "B")]   # el derecho, por cuadro (0..8)


def _arm_at(table, f):
    for (f0, a), (f1, b) in zip(_ARM_KEYS, _ARM_KEYS[1:]):
        if f0 <= f <= f1:
            t = (f - f0) / (f1 - f0)
            A, B = table[a], table[b]
            return [((A[i][0] + (B[i][0] - A[i][0]) * t, A[i][1] + (B[i][1] - A[i][1]) * t) if i < 2 else
                     (A[2][0] + ((B[2][0] - A[2][0] + 180) % 360 - 180) * t, A[2][1] if t < 0.5 else B[2][1]))
                    for i in range(len(A))]
    return list(table["B"])


def _run(i):
    legs, lean = _LEGS[i % 4]
    if i >= 4:  # la otra media vuelta: las piernas al espejo
        legs = dict(kl=(-legs["kr"][0], legs["kr"][1]), fl=(-legs["fr"][0], legs["fr"][1]),
                    kr=(-legs["kl"][0], legs["kl"][1]), fr=(-legs["fl"][0], legs["fl"][1]))
    er, hr, rk = _arm_at(_ARM_R, i)
    el, hl = _arm_at(_ARM_L, (i + 4) % 8)   # el izquierdo, al revés del derecho
    fwd = tuple(k for k, f in (("r", i), ("l", (i + 4) % 8)) if 3 <= f <= 5)
    bwd = tuple(k for k, f in (("r", i), ("l", (i + 4) % 8)) if f <= 1 or f >= 7)
    return P(**legs, er=er, hr=hr, el=el, hl=hl, rk=rk, lean=lean, fwd=fwd, bwd=bwd)


for _i in range(8):
    POSE["corre%d" % (_i + 1)] = _run(_i)

# Los pasitos de lado (sin dar la espalda a la red), hacia la derecha: abre, sale el pie de adelante,
# se juntan en el aire, cae. Con la raqueta lista, en las dos manos.
POSE["paso1_d"] = P(**GRIP, **WIDE, rk=(-150, False), lean=2)
POSE["paso2_d"] = P(**GRIP, kl=(-3, 27), fl=(-5, 33), kr=(6, 27), fr=(9, 32), rk=(-145, False), lean=2, tilt=1, head_dx=1)
POSE["paso3_d"] = P(**GRIP, kl=(-1, 26), fl=(-1, 31), kr=(4, 26), fr=(5, 31), rk=(-145, False), lean=0, tilt=1, head_dx=1)
POSE["paso4_d"] = P(**GRIP, kl=(-3, 27), fl=(-4, 33), kr=(4, 27), fr=(6, 33), rk=(-148, False), lean=1, tilt=1)
# Frenar después de correr hacia la derecha: el pie de afuera estirado, el cuerpo echado para atrás.
POSE["frena_d"] = P(el=(-6, 14), hl=(-9, 15), er=(5, 16), hr=(7, 19), kl=(-3, 27), fl=(-4, 33), kr=(6, 28), fr=(10, 33),
                    rk=(-60, False), lean=3, tilt=-2, head_dx=-1)
# El saltito de cuando el otro le pega (split step): arriba, y cae abierto y agachado.
POSE["split1"] = P(**GRIP, kl=(-2, 26), fl=(-3, 31), kr=(2, 26), fr=(3, 31), rk=(-150, False), lean=-1)
POSE["split2"] = P(**GRIP, kl=(-5, 27), fl=(-7, 33), kr=(5, 27), fr=(7, 33), rk=(-152, False), lean=3)

# El drive (derecha): se gira, la raqueta arriba y atrás, baja (el "loop"), le pega (bajita, a la cintura
# o alta) y termina por encima del hombro izquierdo.
POSE["drive_prep"] = P(**WIDE, el=(-2, 15), hl=(2, 16), er=(7, 14), hr=(9, 16), rk=(-95, False), tilt=2, lean=2, fwd=("l",))
POSE["drive_atras"] = P(**WIDE, el=(-3, 15), hl=(3, 15), er=(8, 12), hr=(11, 13), rk=(-55, False), tilt=3, lean=2, fwd=("l",))
POSE["drive_baja"] = P(**WIDE, el=(-4, 15), hl=(1, 16), er=(8, 15), hr=(10, 19), rk=(100, True), tilt=2, lean=2, fwd=("l",))
POSE["drive"] = P(kl=(-4, 27), fl=(-6, 33), kr=(4, 27), fr=(5, 33), el=(-6, 15), hl=(-8, 17), er=(6, 16), hr=(9, 18),
                  rk=(-8, False), lean=2)
POSE["drive_bajo"] = P(kl=(-5, 28), fl=(-7, 33), kr=(5, 28), fr=(7, 33), el=(-6, 17), hl=(-9, 19), er=(6, 18), hr=(9, 21),
                       rk=(6, False), lean=4)
POSE["drive_alto"] = P(kl=(-3, 27), fl=(-5, 33), kr=(3, 27), fr=(5, 33), el=(-6, 13), hl=(-8, 15), er=(6, 13), hr=(9, 14),
                       rk=(-26, False), lean=0)
POSE["drive_fin"] = P(kl=(-4, 27), fl=(-6, 33), kr=(3, 27), fr=(4, 32), el=(-6, 15), hl=(-4, 13), er=(-1, 12), hr=(-5, 10),
                      rk=(172, False), tilt=-3, lean=1)
POSE["drive_fin1"] = mix(POSE["drive"], POSE["drive_fin"], 0.5)
POSE["drive_fin1"].update(er=(3, 13), hr=(1, 11), rk=(-118, False))

# El revés a dos manos: lo mismo hacia la izquierda, y termina por encima del hombro derecho.
POSE["reves_prep"] = P(**WIDE, el=(-6, 16), hl=(-7, 19), er=(0, 16), hr=(-6, 18), rk=(-110, False), two=True, tilt=-2, lean=2)
POSE["reves_atras"] = P(**WIDE, el=(-7, 14), hl=(-9, 16), er=(-1, 14), hr=(-8, 15), rk=(-128, True), two=True, tilt=-3, lean=2)
POSE["reves_baja"] = P(**WIDE, el=(-7, 16), hl=(-9, 19), er=(-1, 17), hr=(-8, 19), rk=(95, True), two=True, tilt=-2, lean=2)
POSE["reves"] = P(kl=(-4, 27), fl=(-5, 33), kr=(4, 27), fr=(6, 33), el=(-5, 16), hl=(-7, 18), er=(1, 16), hr=(-6, 18),
                  rk=(188, False), two=True, lean=2)
POSE["reves_bajo"] = P(kl=(-5, 28), fl=(-7, 33), kr=(5, 28), fr=(7, 33), el=(-5, 18), hl=(-7, 21), er=(1, 18), hr=(-6, 21),
                       rk=(176, False), two=True, lean=4)
POSE["reves_alto"] = P(kl=(-3, 27), fl=(-5, 33), kr=(3, 27), fr=(5, 33), el=(-5, 13), hl=(-7, 15), er=(1, 13), hr=(-6, 14),
                       rk=(205, False), two=True, lean=0)
POSE["reves_fin"] = P(kl=(-3, 27), fl=(-4, 32), kr=(4, 27), fr=(6, 33), el=(1, 12), hl=(5, 10), er=(6, 12), hr=(6, 10),
                      rk=(8, False), two=True, tilt=3, lean=1)
POSE["reves_fin1"] = mix(POSE["reves"], POSE["reves_fin"], 0.5)
POSE["reves_fin1"].update(er=(3, 13), hr=(1, 12), rk=(-62, False))

# El cortado (revés a una mano): arriba, atrás de la cabeza; baja abriendo la cara, y sigue estirado.
POSE["cortado_atras"] = P(**WIDE, el=(-7, 15), hl=(-5, 18), er=(-1, 12), hr=(-5, 10), rk=(-140, True), tilt=-3, lean=2)
POSE["cortado"] = P(**WIDE, el=(-6, 15), hl=(-9, 16), er=(0, 15), hr=(-6, 17), rk=(165, False), tilt=-1, lean=3)
POSE["cortado_fin"] = P(**WIDE, el=(-6, 14), hl=(-9, 14), er=(4, 15), hr=(8, 17), rk=(-15, False), tilt=1, lean=2)

# El saque: bota la pelota, bajan los brazos, la tira, el trofeo (rodillas dobladas, la raqueta arriba),
# la raqueta cae detrás de la espalda, le pega estirado (en puntas), y cae hacia adelante.
_SV = dict(kl=(-3, 27), fl=(-4, 33), kr=(2, 27), fr=(4, 33))
POSE["saque_bota1"] = P(**_SV, el=(-5, 16), hl=(-4, 20), er=(5, 16), hr=(5, 20), rk=(-140, False), lean=2)
POSE["saque_bota2"] = P(**_SV, el=(-5, 17), hl=(-4, 22), er=(5, 16), hr=(5, 20), rk=(-140, False), lean=3)
POSE["saque_baja"] = P(**_SV, el=(-5, 16), hl=(-3, 21), er=(5, 16), hr=(4, 21), rk=(120, True), lean=1)
POSE["saque_lanza"] = P(**_SV, el=(-5, 10), hl=(-5, 6), er=(7, 15), hr=(9, 18), rk=(130, True), lean=1)
POSE["saque_trofeo"] = P(kl=(-3, 27), fl=(-4, 33), kr=(3, 27), fr=(4, 33), el=(-5, 7), hl=(-5, 2), er=(9, 9), hr=(8, 6),
                         rk=(-75, False), lean=3)
POSE["saque_rasca"] = P(**_SV, el=(-4, 10), hl=(-3, 8), er=(8, 8), hr=(5, 7), rk=(95, False), lean=1)
POSE["saque"] = P(kl=(-2, 26), fl=(-3, 32), kr=(3, 26), fr=(4, 32), el=(-4, 14), hl=(-2, 16), er=(5, 9), hr=(4, 5),
                  rk=(-95, False), lean=-1)
POSE["saque_fin1"] = P(kl=(-2, 27), fl=(-3, 33), kr=(3, 26), fr=(4, 31), el=(-5, 15), hl=(-6, 17), er=(5, 12), hr=(3, 15),
                       rk=(130, False), lean=1)
POSE["saque_fin"] = P(kl=(-3, 27), fl=(-4, 33), kr=(2, 26), fr=(3, 29), el=(-5, 16), hl=(-3, 19), er=(1, 16), hr=(-4, 21),
                      rk=(110, False), lean=3)
# El saque por abajo (Bublikov): la raqueta atrás, bajita, y la barre hacia adelante.
POSE["abajo_atras"] = P(**WIDE, el=(-5, 16), hl=(-3, 17), er=(6, 18), hr=(8, 22), rk=(60, True), lean=3)
POSE["abajo"] = P(**WIDE, el=(-5, 16), hl=(-6, 18), er=(4, 18), hr=(3, 21), rk=(-80, False), lean=2)

# De perfil, corriendo de lado (lo que más se corre en el tenis): 8 cuadros de una carrera de verdad.
# Por pierna: el muslo (grados desde la vertical, + hacia adelante) y cuánto se dobla la rodilla. La de
# allá va media vuelta corrida. Los brazos, al revés de la pierna de su lado.
SIDE_RUN = [(25, 15), (8, 38), (-16, 24), (-34, 30), (-26, 88), (-2, 112), (30, 96), (42, 46)]


def side_run(i):
    tn, kn = SIDE_RUN[i]
    tf, kf = SIDE_RUN[(i + 4) % 8]
    an, af = -tn * 1.1, -tf * 1.1
    return {"side": True, "tn": tn, "kn": kn, "tf": tf, "kf": kf, "an": an, "af": af,
            "en": 100 if an > 0 else 70, "ef": 100 if af > 0 else 70, "lean": 12, "air": i in (3, 7)}


for _i in range(8):
    POSE["lado%d" % (_i + 1)] = side_run(_i)

POSES = (["listo", "listo2"] + ["corre%d" % i for i in range(1, 9)]
         + ["lado%d_d" % i for i in range(1, 9)] + ["lado%d_i" % i for i in range(1, 9)]
         + ["paso%d_d" % i for i in range(1, 5)] + ["paso%d_i" % i for i in range(1, 5)]
         + ["frena_d", "frena_i", "split1", "split2",
            "drive_prep", "drive_atras", "drive_baja", "drive_bajo", "drive", "drive_alto", "drive_fin1", "drive_fin",
            "reves_prep", "reves_atras", "reves_baja", "reves_bajo", "reves", "reves_alto", "reves_fin1", "reves_fin",
            "cortado_atras", "cortado", "cortado_fin", "dejada",
            "saque_bota1", "saque_bota2", "saque_baja", "saque_lanza", "saque_trofeo", "saque_rasca", "saque",
            "saque_fin1", "saque_fin", "abajo_atras", "abajo",
            "tirada", "piso", "celebra", "bravo", "agachado", "recoge",
            "camina1", "camina2", "parado", "tel1", "tel2", "doblado", "acostado", "brazos", "suelta", "rota"])
for _k in ("drive_atras", "reves_atras", "saque_lanza", "corre1", "corre2", "corre3", "corre4"):
    assert _k in POSE

# ---------------------------------------------------------------- Los tenistas
# h: cuánto más alto (piernas y tronco). sh: medio ancho de los hombros. Los colores: s/S piel, h/H pelo,
# t/T camiseta, p/P pantaloneta (o falda), w medias, k zapato, a lo de acento (balaca, raya), r raqueta.
PLAYERS = {
    "bublikov": {
        "h": 2, "sh": 4, "slouch": 1, "skirt": False,
        "s": (236, 180, 150), "S": (205, 140, 120), "h1": (46, 38, 40), "h2": (74, 60, 58),
        "t": (238, 238, 232), "T": (196, 198, 200), "p": (38, 38, 46), "P": (24, 24, 30),
        "w": (240, 240, 236), "k": (236, 236, 230), "K": (160, 160, 164), "a": (32, 32, 38),
        "r": (60, 64, 76), "hair": "despeinado"},
    "sabalenkova": {
        "h": 0, "sh": 5, "slouch": 0, "skirt": True,
        "s": (240, 186, 156), "S": (210, 146, 122), "h1": (232, 200, 120), "h2": (196, 158, 84),
        "t": (240, 112, 112), "T": (204, 78, 92), "p": (240, 112, 112), "P": (204, 78, 92),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (190, 120, 140), "a": (240, 140, 50),
        "r": (230, 230, 236), "hair": "cola"},
    "monfiz": {
        "h": 1, "sh": 5, "slouch": 0, "skirt": False,
        "s": (120, 78, 58), "S": (88, 54, 44), "h1": (30, 26, 28), "h2": (48, 40, 42),
        "t": (246, 210, 64), "T": (210, 164, 40), "p": (34, 34, 40), "P": (22, 22, 28),
        "w": (240, 240, 236), "k": (246, 210, 64), "K": (170, 130, 40), "a": (246, 210, 64),
        "r": (34, 34, 40), "hair": "rapado"},
    "yokovich": {
        "h": 0, "sh": 4, "slouch": 0, "skirt": False,
        "s": (236, 182, 152), "S": (204, 142, 120), "h1": (98, 70, 52), "h2": (72, 50, 38),
        "t": (206, 52, 56), "T": (160, 34, 44), "p": (40, 52, 104), "P": (28, 36, 76),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (60, 70, 120), "a": (240, 240, 236),
        "r": (230, 230, 236), "hair": "corto"},
    "moutette": {
        "h": -2, "sh": 4, "slouch": 0, "skirt": False, "lefty": True,
        "s": (236, 186, 156), "S": (206, 146, 124), "h1": (34, 30, 34), "h2": (60, 50, 54),
        "t": (140, 196, 236), "T": (96, 152, 204), "p": (236, 236, 232), "P": (190, 192, 198),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (96, 152, 204), "a": (40, 52, 104),
        "r": (40, 52, 104), "hair": "rizado"},
    "tiafuego": {
        "h": 0, "sh": 5, "slouch": 0, "skirt": False,
        "s": (112, 72, 52), "S": (84, 52, 40), "h1": (28, 24, 26), "h2": (52, 42, 40),
        "t": (170, 224, 84), "T": (122, 180, 60), "p": (112, 72, 156), "P": (82, 50, 116),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (112, 72, 156), "a": (112, 72, 156),
        "r": (112, 72, 156), "hair": "trenzas"},
    "sheltron": {
        "h": 2, "sh": 5, "slouch": 0, "skirt": False, "lefty": True,
        "s": (156, 104, 76), "S": (122, 78, 58), "h1": (30, 26, 28), "h2": (50, 42, 42),
        "t": (248, 150, 60), "T": (210, 108, 40), "p": (40, 70, 150), "P": (28, 50, 112),
        "w": (240, 240, 236), "k": (248, 150, 60), "K": (40, 70, 150), "a": (240, 240, 236),
        "r": (40, 70, 150), "hair": "rapado"},
    "kyrgistan": {
        "h": 1, "sh": 5, "slouch": 0, "skirt": False,
        "s": (228, 172, 140), "S": (196, 134, 110), "h1": (40, 32, 30), "h2": (66, 52, 48),
        "t": (44, 44, 50), "T": (28, 28, 34), "p": (44, 44, 50), "P": (28, 28, 34),
        "w": (240, 240, 236), "k": (210, 40, 50), "K": (140, 30, 40), "a": (210, 40, 50),
        "r": (210, 40, 50), "hair": "gorra"},
    "pecador": {
        "h": 1, "sh": 4, "slouch": 0, "skirt": False,
        "s": (246, 208, 182), "S": (222, 170, 150), "h1": (226, 118, 48), "h2": (186, 86, 36),
        "t": (150, 222, 192), "T": (106, 180, 150), "p": (236, 236, 232), "P": (190, 192, 198),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (106, 180, 150), "a": (106, 180, 150),
        "r": (240, 240, 236), "hair": "rizado"},
    "fedorer": {
        "h": 0, "sh": 4, "slouch": 0, "skirt": False,
        "s": (232, 180, 150), "S": (202, 140, 118), "h1": (108, 78, 58), "h2": (82, 58, 44),
        "t": (244, 244, 240), "T": (200, 202, 208), "p": (244, 244, 240), "P": (196, 198, 204),
        "w": (240, 240, 236), "k": (240, 240, 236), "K": (196, 198, 204), "a": (244, 244, 240),
        "r": (190, 40, 44), "hair": "corto"},
    "camillero": {
        "h": 1, "sh": 5, "slouch": 0, "skirt": False, "long": True,
        "s": (200, 146, 112), "S": (166, 112, 88), "h1": (38, 32, 34), "h2": (60, 50, 50),
        "t": (238, 238, 234), "T": (194, 198, 204), "p": (226, 228, 230), "P": (186, 190, 198),
        "w": (226, 228, 230), "k": (40, 40, 46), "K": (40, 40, 46), "a": (204, 40, 48),
        "r": None, "hair": "corto"},
    "el": {
        "h": 1, "sh": 5, "slouch": 0, "skirt": False, "long": True,
        "s": (214, 150, 120), "S": (172, 110, 90), "h1": (72, 66, 74), "h2": (150, 148, 152),
        "t": (44, 40, 48), "T": (30, 28, 34), "p": (66, 92, 146), "P": (44, 62, 104),
        "w": (66, 92, 146), "k": (46, 40, 46), "k2": (196, 64, 52), "K": (196, 64, 52), "a": (206, 48, 52),
        "r": None, "hair": "el", "beard": (112, 98, 90)},
}


# ---------------------------------------------------------------- Pintar

class Canvas:
    def __init__(self):
        self.im = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        self.px = self.im.load()

    def dot(self, x, y, c):
        x, y = int(round(x)), int(round(y)) + DY
        if 0 <= x < CW and 0 <= y < CH and c is not None:
            self.px[x, y] = c + (255,) if len(c) == 3 else c

    def get(self, x, y, raw=False):
        if not raw:
            y += DY
        if 0 <= x < CW and 0 <= y < CH:
            return self.px[x, y]
        return (0, 0, 0, 0)

    def line(self, a, b, c, w=2):
        """Una pieza gruesa: puntos a lo largo de a→b, de w de grueso (2 = el pixel y el de la derecha/abajo)."""
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
        for i in range(n + 1):
            t = i / max(n, 1)
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t
            for dx in range(w):
                for dy in range(w):
                    self.dot(math.floor(x) + dx, math.floor(y) + dy, c)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.dot(x, y, c)

    def poly(self, pts, c):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            for i in range(len(pts)):
                a, b = pts[i], pts[(i + 1) % len(pts)]
                if (a[1] <= y + 0.5 < b[1]) or (b[1] <= y + 0.5 < a[1]):
                    xs.append(a[0] + (y + 0.5 - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] - 0.5)) + 1):
                    self.dot(x, y, c)

    def outline(self):
        """El contorno del juego: todo lo vacío pegado (en cruz) a algo pintado."""
        add = []
        for y in range(CH):
            for x in range(CW):
                if self.px[x, y][3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        q = self.get(x + dx, y + dy, True)
                        if q[3] > 0 and q[:3] != OUTLINE:
                            add.append((x, y))
                            break
        for x, y in add:
            self.px[x, y] = OUTLINE + (255,)


def racket(cv, hand, ang, col, strings=(220, 224, 214)):
    """La raqueta: el mango (3 px) y la cabeza ovalada (5x7) en la dirección `ang`."""
    a = math.radians(ang)
    ux, uy = math.cos(a), math.sin(a)
    end = (hand[0] + ux * 3, hand[1] + uy * 3)
    cv.line(hand, end, (70, 54, 46), 1)                       # el mango (grip café)
    cx, cy = hand[0] + ux * 7, hand[1] + uy * 7               # el centro de la cabeza
    for k in range(28):
        t = k / 28 * math.tau
        lx, ly = math.cos(t) * 2.6, math.sin(t) * 3.6        # el óvalo, a lo largo de la raqueta
        x = cx + lx * -uy + ly * ux
        y = cy + lx * ux + ly * uy
        cv.dot(x, y, col)
    for dy in range(-2, 3):                                  # el encordado (más claro, adentro)
        for dx in range(-1, 2):
            x = cx + dx * -uy + dy * ux
            y = cy + dx * ux + dy * uy
            if cv.get(int(round(x)), int(round(y)))[3] == 0:
                cv.dot(x, y, strings)
    return cx, cy


def floor_racket(cv, col, broken):
    """La raqueta acostada en el piso, un poco en diagonal. Rota: el mango por un lado, la cabeza
    torcida por otro y dos cuerdas colgando."""
    o = CX - 16                                            # (dibujada para una celda de 32)
    if not broken:
        racket(cv, (9 + o, 30), -12, col)
        return
    cv.line((5 + o, 32), (9 + o, 31), (70, 54, 46), 1)    # el mango, solo
    cv.dot(10 + o, 31, col)                                # con el pedacito del cuello
    racket(cv, (14 + o, 33), -40, col, strings=(150, 152, 146))
    for k in range(3):                                     # las cuerdas reventadas, colgando
        cv.dot(23 + o + k, 25 + k, (220, 224, 214))
    cv.dot(22 + o, 33, (220, 224, 214))


def draw(pid: str, pose: str, front: bool, q=None):
    """Una celda de espaldas (o de frente: el espejo). Devuelve la imagen y {"rk": la cabeza de la
    raqueta, "hl": la mano izquierda} en coordenadas de la celda."""
    d = PLAYERS[pid]
    q = q if q is not None else POSE[pose]
    cv = Canvas()
    meta = {"rk": None, "hl": None}
    if q.get("only"):  # la raqueta sola, en el piso
        if d["r"] is not None:
            floor_racket(cv, d["r"], q["only"] == "rota")
            cv.outline()
        return cv.im, meta
    h = d["h"]
    lean = q["lean"] + d.get("slouch", 0) * (pose in ("listo", "listo2"))
    mx = -1 if front else 1                 # de frente, la derecha queda a la izquierda de la pantalla

    def X(v):
        return CX + v * mx

    def Y(v, part="body"):
        # Más alto: estira hacia arriba (los pies quedan en su sitio). El agachado baja el tronco.
        if q.get("dive") or q.get("floor"):
            return v
        if v >= 27:   # de la rodilla para abajo, no cambia
            return v
        return v - h + lean * (1 if v < 24 else 0.5)

    def YL(v):
        # Rodillas y pies: lo que está en el piso no se mueve; lo levantado sube con la cadera, de a
        # poquito (si no, un pie levantado salta de un cuadro al otro en los más altos).
        if q.get("dive") or q.get("floor") or v >= 27:
            return v
        return v - (h - lean * 0.5) * min(1.0, (27 - v) / 3.0)

    sh = d["sh"]
    hip_y, sho_y = 22, 12
    if q.get("dive"):
        # Tirado en el aire, de lado: el tronco acostado, los brazos estirados hacia la pelota.
        torso = [(X(-3), 14), (X(5), 11), (X(6), 15), (X(-2), 18)]
        hips = (X(-4), 17)
        neck = (X(6), 12)
        head_at = (X(9), 9)
    elif q.get("floor"):
        torso = [(X(-4), 25), (X(4), 25), (X(4), 30), (X(-4), 30)]
        hips = (X(-5), 28)
        neck = (X(5), 27)
        head_at = (X(8), 25)
    else:
        t = q["tilt"]
        torso = [(X(-sh + t), Y(sho_y)), (X(sh + t), Y(sho_y)), (X(3), Y(hip_y)), (X(-3), Y(hip_y))]
        hips = None
        neck = (X(t * 0.5), Y(sho_y - 1))
        head_at = (X(t * 0.5 + q["head_dx"]), Y(sho_y - 6 + (2 if q.get("down") else 0)))

    def j(name):
        x, y = q[name]
        return (X(x), YL(y) if name[0] in "kf" else Y(y))

    shoulder_l = (torso[0][0], torso[0][1] + 1)
    shoulder_r = (torso[1][0], torso[1][1] + 1)
    if q.get("dive") or q.get("floor"):
        shoulder_l = shoulder_r = (neck[0], neck[1] + 1)

    rk_ang, rk_front = q["rk"] if q["rk"] is not None else (0, False)
    has_rk = q["rk"] is not None and d["r"] is not None
    if front:
        rk_ang = 180 - rk_ang
        rk_front = not rk_front
    hand_r = j("hr")

    # 1) Lo que va detrás del cuerpo.
    if has_rk and not rk_front:
        meta["rk"] = racket(cv, hand_r, rk_ang, d["r"])

    def arm(side, sho):  # (manga corta: el primer pedazo, color camiseta)
        el, hand = j("e" + side), j("h" + side)
        if side == "l" and q["two"]:
            hand = (hand_r[0] - mx, hand_r[1] + 1)
        if side == "l":
            meta["hl"] = hand
        cv.line(sho, el, d["s"])
        cv.line(el, hand, d["s"])
        cv.line(sho, ((sho[0] * 2 + el[0]) / 3, (sho[1] * 2 + el[1]) / 3), d["t"])

    # Los brazos que quedan detrás del cuerpo: de espaldas, los que van hacia adelante; de frente, los de atrás.
    hidden = q.get("bwd", ()) if front else q.get("fwd", ())
    for side, sho in (("l", shoulder_l), ("r", shoulder_r)):
        if side in hidden:
            arm(side, sho)

    # 2) Las piernas (piel; medias y zapatos abajo).
    for side in ("l", "r"):
        hip = (hips if hips else (X(-2 if side == "l" else 2), Y(hip_y + 2)))
        knee, foot = j("k" + side), j("f" + side)
        leg = d["p"] if d.get("long") else d["s"]   # él: el jean, hasta el zapato
        cv.line(hip, knee, leg)
        cv.line(knee, foot, leg)
        cv.line((foot[0], foot[1] - 2), foot, d["w"])
        shoe = d.get("k2", d["k"]) if side == "r" else d["k"]   # él: uno negro y uno rojo
        cv.rect(foot[0] - (1 if mx * (1 if side == "r" else -1) < 0 else 0), foot[1],
                foot[0] + (2 if mx * (1 if side == "r" else -1) > 0 else 1), foot[1] + 1, shoe)

    # 3) El tronco, la pantaloneta (o la falda).
    cv.poly(torso, d["t"])
    if not (q.get("dive") or q.get("floor")):
        y0 = Y(hip_y) - 1
        if d["skirt"]:
            cv.poly([(X(-4), y0), (X(4), y0), (X(6), y0 + 5), (X(-6), y0 + 5)], d["p"])
        else:
            cv.rect(X(-4) if mx > 0 else X(4), y0, X(4) if mx > 0 else X(-4), y0 + 4, d["p"])
            cv.dot(CX, y0 + 4, None)
    else:
        cv.line((torso[3][0], torso[3][1]), hips, d["p"], 3)

    # 4) Los brazos que se ven.
    for side, sho in (("l", shoulder_l), ("r", shoulder_r)):
        if side not in hidden:
            arm(side, sho)

    # 5) La cabeza (de espaldas: el pelo; de frente: la cara).
    hx, hy = int(round(head_at[0])) - 4, int(round(head_at[1])) - 4
    cv.line(neck, (neck[0], neck[1] - 1), d["s"])
    head(cv, d, hx, hy, front)

    # 6) Lo que va delante.
    if has_rk and rk_front:
        meta["rk"] = racket(cv, hand_r, rk_ang, d["r"])
    if q.get("phone"):
        cv.rect(hand_r[0], hand_r[1] - 2, hand_r[0] + 1, hand_r[1], (34, 34, 40))

    cv.outline()
    details(cv, pid, d, pose, front, torso, j, mx, hx, hy, q)
    return cv.im, meta


# ---------------------------------------------------------------- De perfil

def draw_side(pid: str, q: dict, face: int):
    """De perfil, mirando hacia `face` (+1: a la derecha de la pantalla). Las piernas y los brazos van
    con ángulos y largos fijos (el pie no se estira ni se encoge de un cuadro al otro); la cadera baja
    hasta que el pie de abajo toca el piso (en el aire, un pixel más arriba). El brazo y la pierna de allá
    van detrás del cuerpo y más oscuros. La mano derecha es la de acá si mira a la derecha."""
    d = PLAYERS[pid]
    cv = Canvas()
    meta = {"rk": None, "hl": None}
    h = d["h"]
    thigh = shin = (9.5 + h) / 2 + 0.3
    upper = fore = 4.0 + 0.3 * h

    def dark(c, k=0.8):
        return tuple(int(v * k) for v in c)

    def vec(a_deg, length):  # a: grados desde la vertical hacia abajo, + hacia adelante
        a = math.radians(a_deg)
        return (face * math.sin(a) * length, math.cos(a) * length)

    def leg(t, k):
        kx, ky = vec(t, thigh)
        fx, fy = vec(t - k, shin)
        return (kx, ky), (kx + fx, ky + fy)

    kn, fn = leg(q["tn"], q["kn"])
    kf, ff = leg(q["tf"], q["kf"])
    hip = (CX - face, 33 - max(fn[1], ff[1]) - (1 if q.get("air") else 0))
    lean = math.radians(q["lean"])
    waist = (hip[0], hip[1] - 1)
    sho = (waist[0] + face * math.sin(lean) * 9.0, waist[1] - math.cos(lean) * 9.0)
    ahead = (face * math.cos(lean), math.sin(lean))   # hacia adelante, perpendicular a la espalda

    def off(pt, k):
        return (pt[0] + ahead[0] * k, pt[1] + ahead[1] * k)

    torso = [off(sho, -2), off(sho, 2.5), off(waist, 2), off(waist, -2)]
    shoulder = (sho[0] - face * 0.5, sho[1] + 1)

    def arm(a, e):
        u = vec(a, upper)
        el = (shoulder[0] + u[0], shoulder[1] + u[1])
        f = vec(a + e, fore)
        return el, (el[0] + f[0], el[1] + f[1])

    near_arm, far_arm = arm(q["an"], q["en"]), arm(q["af"], q["ef"])
    right_near = face > 0
    r_arm, r_a, r_e = (near_arm, q["an"], q["en"]) if right_near else (far_arm, q["af"], q["ef"])
    has_rk = d["r"] is not None
    r_pol = math.radians(105 + r_a * 0.9)   # la raqueta: adelante, subiendo y bajando con el brazo
    rk_ang = math.degrees(math.atan2(math.cos(r_pol), face * math.sin(r_pol)))
    meta["hl"] = far_arm[1] if right_near else near_arm[1]

    def draw_arm(a, skin, sleeve):
        el, hand = a
        cv.line(shoulder, el, skin)
        cv.line(el, hand, skin)
        cv.line(shoulder, ((shoulder[0] * 2 + el[0]) / 3, (shoulder[1] * 2 + el[1]) / 3), sleeve)

    def draw_leg(kv, fv, skin, sock, shoe, pants):
        knee, foot = (hip[0] + kv[0], hip[1] + kv[1]), (hip[0] + fv[0], hip[1] + fv[1])
        legc = pants if d.get("long") else skin
        cv.line(hip, knee, legc)
        cv.line(knee, foot, legc)
        dx, dy = foot[0] - knee[0], foot[1] - knee[1]
        n = max(0.001, math.hypot(dx, dy))
        cv.line((foot[0] - dx / n * 2, foot[1] - dy / n * 2), foot, sock)
        x0, x1 = sorted((foot[0], foot[0] + 2 * face))       # el zapato, con la punta hacia adelante
        cv.rect(x0, foot[1], x1, foot[1] + 1, shoe)
        cv.dot(foot[0] - face, foot[1] + 1, shoe)             # el talón
        top = (hip[0] + kv[0] * 0.35, hip[1] + kv[1] * 0.35)  # la pantaloneta le tapa el muslo de arriba
        cv.line(hip, top, pants, 3)

    shoe_r, shoe_l = d.get("k2", d["k"]), d["k"]
    near_shoe, far_shoe = (shoe_r, shoe_l) if right_near else (shoe_l, shoe_r)

    # 1) Lo de allá: la raqueta (si va en esa mano), el brazo y la pierna.
    if has_rk and not right_near:
        meta["rk"] = racket(cv, r_arm[1], rk_ang, d["r"])
    draw_arm(far_arm, d["S"], d["T"])
    draw_leg(kf, ff, d["S"], dark(d["w"]), dark(far_shoe), d["P"])
    # 2) El tronco y la cadera (o la falda).
    cv.poly(torso, d["t"])
    if d["skirt"]:
        cv.poly([(hip[0] - 3, hip[1] - 2), (hip[0] + 3, hip[1] - 2), (hip[0] + 4.5, hip[1] + 3),
                 (hip[0] - 4.5, hip[1] + 3)], d["p"])
    else:
        cv.poly([off((hip[0], hip[1] - 2.5), -2.5), off((hip[0], hip[1] - 2.5), 2.5),
                 off((hip[0], hip[1] + 1.5), 2.5), off((hip[0], hip[1] + 1.5), -2.5)], d["p"])
    # 3) La pierna de acá.
    draw_leg(kn, fn, d["s"], d["w"], near_shoe, d["p"])
    # 4) La cabeza: el cuello y la cara de lado.
    hx, hy = int(round(sho[0] + face * 0.5)) - 4, int(round(sho[1])) - 9
    cv.line((sho[0], sho[1]), (sho[0], sho[1] - 1), d["s"])
    head_side(cv, d, hx, hy, face)
    # 5) El brazo de acá, y la raqueta encima si va en esa mano.
    draw_arm(near_arm, d["s"], d["t"])
    if has_rk and right_near:
        meta["rk"] = racket(cv, r_arm[1], rk_ang, d["r"])
    cv.outline()

    joints = {"er": (near_arm if right_near else far_arm)[0], "hr": r_arm[1],
              "el": (far_arm if right_near else near_arm)[0], "hl": meta["hl"]}
    details(cv, pid, d, "lado", False, torso, lambda name: joints[name], face, hx, hy, q, side=True)
    return cv.im, meta


def head_side(cv, d, x, y, face):
    """La cabeza de perfil (8x8): la cara hacia `face`; el pelo arriba y en la nuca; el ojo, la nariz
    (un pixel afuera), la oreja."""
    s, S, h1, h2 = d["s"], d["S"], d["h1"], d["h2"]

    def dot(xx, yy, c):  # xx: 0 es la nuca, 7 la cara
        cv.dot(x + (xx if face > 0 else 7 - xx), y + yy, c)

    for yy in range(8):
        for xx in range(8):
            if not (xx in (0, 7) and yy in (0, 7)):
                dot(xx, yy, s)
    for yy in range(3):
        for xx in range(8):
            if not (xx in (0, 7) and yy == 0):
                dot(xx, yy, h1)
    for yy in range(3, 6):
        for xx in range(3):
            dot(xx, yy, h1)
    dot(1, 6, h1)
    style = d["hair"]
    if style == "despeinado":
        for px_, py_ in ((1, -1), (3, -2), (4, -1), (6, -1), (-1, 1), (-1, 3)):
            dot(px_, py_, h1)
        dot(3, 0, h2)
        dot(5, 1, h2)
    elif style == "cola":  # la cola de caballo, para atrás (con el caucho)
        for k in range(6):
            dot(-1 - (k > 2), 2 + k, h1 if k % 2 == 0 else h2)
        dot(-1, 2, d["a"])
        dot(2, 1, h2)
    elif style == "rapado":
        for xx in range(1, 7):
            dot(xx, 0, h2)
        dot(0, 4, h2)
        dot(1, 5, h2)
    elif style == "corto":
        dot(3, 1, h2)
        dot(5, 1, h2)
    elif style == "rizado":
        for px_, py_ in ((0, -1), (2, -1), (4, -1), (6, -1), (-1, 1), (-1, 3), (-1, 5), (1, -2), (5, -2)):
            dot(px_, py_, h1)
        for px_, py_ in ((1, 0), (3, 1), (5, 0), (1, 4)):
            dot(px_, py_, h2)
    elif style == "trenzas":
        for xx in range(0, 8, 2):
            dot(xx, -1, h1)
            dot(xx + 1, 0, h2)
        for k in range(5):
            dot(-1, 2 + k, h1 if k % 2 == 0 else h2)
    elif style == "el":
        dot(2, 1, h2)
        dot(5, 0, h2)
        dot(1, 4, h2)
        dot(4, -1, h1)
        dot(5, -2, h1)
    elif style == "gorra":  # la gorra al revés: la visera sale por la nuca
        cap, cap_d = d["a"], (140, 30, 40)
        for yy in range(3):
            for xx in range(8):
                if not (xx in (0, 7) and yy == 0):
                    dot(xx, yy, cap)
        for xx in range(1, 8):
            dot(xx, 2, cap_d)
        for k in range(1, 4):
            dot(-k, 3, cap_d)
        dot(-1, 2, cap)
    dot(5, 4, EYE)
    dot(8, 4, s)          # la nariz
    dot(3, 4, S)          # la oreja
    dot(3, 5, S)
    if d.get("beard"):
        for yy in range(5, 8):
            for xx in range(3, 8):
                if not (xx == 7 and yy == 7):
                    dot(xx, yy, d["beard"])
        dot(4, 6, h2)
    else:
        dot(7, 6, S)      # la boca
        dot(6, 7, S)      # la quijada


def head(cv, d, x, y, front):
    """La cabeza, 8x8 (más el pelo de cada uno)."""
    s, S, h1, h2 = d["s"], d["S"], d["h1"], d["h2"]
    for yy in range(8):
        for xx in range(8):
            if (xx in (0, 7) and yy in (0, 7)):
                continue
            cv.dot(x + xx, y + yy, s)
    style = d["hair"]
    # El pelo de arriba (siempre); de espaldas, toda la nuca.
    top = 3 if front else 6
    for yy in range(top):
        for xx in range(8):
            if (xx in (0, 7) and yy == 0):
                continue
            cv.dot(x + xx, y + yy, h1)
    if style == "despeinado":  # mechas paradas para todos lados
        for px, py in ((1, -1), (3, -2), (4, -1), (6, -1), (-1, 1), (8, 2)):
            cv.dot(x + px, y + py, h1)
        cv.dot(x + 3, y + 0, h2)
        cv.dot(x + 5, y + 1, h2)
    elif style == "cola":  # cola de caballo
        if front:
            cv.dot(x - 1, y + 2, h1)
            cv.dot(x + 8, y + 2, h1)
        else:
            for k in range(6):
                cv.dot(x + 3 + (k > 3), y + 6 + k, h1 if k % 2 == 0 else h2)
                cv.dot(x + 4 + (k > 3), y + 6 + k, h1)
        cv.dot(x + 2, y + 1, h2)
    elif style == "rapado":
        for xx in range(1, 7):
            cv.dot(x + xx, y, h2)
    elif style == "corto":
        cv.dot(x + 2, y + 1, h2)
        cv.dot(x + 5, y + 1, h2)
    elif style == "rizado":  # crespo: bolitas arriba y a los lados
        for px_, py_ in ((0, -1), (2, -1), (4, -1), (6, -1), (-1, 1), (8, 1), (1, -2), (5, -2)):
            cv.dot(x + px_, y + py_, h1)
        for px_, py_ in ((1, 0), (3, 1), (5, 0), (6, 2)):
            cv.dot(x + px_, y + py_, h2)
        if front:
            cv.dot(x - 1, y + 3, h1)
            cv.dot(x + 8, y + 3, h1)
    elif style == "trenzas":  # trencitas cortas, paradas
        for xx in range(0, 8, 2):
            cv.dot(x + xx, y - 1, h1)
            cv.dot(x + xx + 1, y, h2)
        if not front:
            for xx in range(0, 8, 2):
                cv.dot(x + xx, y + 6, h1)
    elif style == "el":  # oscuro con canas, y el mechón parado
        for px_, py_ in ((1, 1), (4, 0), (6, 2)):
            cv.dot(x + px_, y + py_, h2)
        if not front:
            cv.dot(x + 2, y + 4, h2)
            cv.dot(x + 5, y + 5, h2)
        cv.dot(x + 4, y - 1, h1)
        cv.dot(x + 5, y - 2, h1)
    elif style == "gorra":  # la gorra al revés: la visera atrás
        cap, cap_d = d["a"], (140, 30, 40)
        for yy in range(3):
            for xx in range(8):
                if not (xx in (0, 7) and yy == 0):
                    cv.dot(x + xx, y + yy, cap)
        for xx in range(1, 7):
            cv.dot(x + xx, y + 2, cap_d)
        if not front:  # la visera, hacia la nuca
            for xx in range(1, 7):
                cv.dot(x + xx, y + 3, cap_d)
                cv.dot(x + xx, y + 4, cap)
        else:  # por delante: el pelo que se sale por debajo y la tira
            cv.dot(x, y + 3, h1)
            cv.dot(x + 7, y + 3, h1)
    if front and d.get("beard"):  # la barba tupida (con alguna cana) desde debajo de los ojos
        for yy in range(5, 8):
            for xx in range(8):
                if not (xx in (0, 7) and yy == 7):
                    cv.dot(x + xx, y + yy, d["beard"])
        cv.dot(x + 2, y + 6, h2)
        cv.dot(x + 5, y + 7, h2)
        cv.dot(x + 1, y + 3, d["h1"])
        cv.dot(x + 6, y + 3, d["h1"])
    if front:  # la cara: ojos, la sombra de un lado, la boca
        cv.dot(x + 2, y + 4, EYE)
        cv.dot(x + 5, y + 4, EYE)
        for yy in range(3, 8):
            cv.dot(x + 7 - (yy in (0, 7)), y + yy, S)
        if not d.get("beard"):
            cv.dot(x + 3, y + 6, S)
            cv.dot(x + 4, y + 6, S)
    else:  # de espaldas: las orejas
        cv.dot(x - 0, y + 4, s)
        cv.dot(x + 7, y + 4, s)


def details(cv, pid, d, pose, front, torso, j, mx, hx, hy, q, side=False):
    """Lo que hace a cada uno: encima del contorno, a mano."""
    px = cv.px

    def paint(x, y, c, raw=False):
        x, y = int(round(x)), int(round(y)) + (0 if raw else DY)
        if 0 <= x < CW and 0 <= y < CH and px[x, y][3] > 0 and px[x, y][:3] != OUTLINE:
            px[x, y] = c + (255,)

    standing = not (q.get("dive") or q.get("floor"))
    # La sombra de la camiseta: del lado de la izquierda de la pantalla (la luz viene de la derecha).
    for y in range(CH):
        row = [x for x in range(CW) if px[x, y][:3] == d["t"]]
        if row:
            paint(min(row), y, d["T"], True)
    for y in range(CH):
        row = [x for x in range(CW) if px[x, y][:3] == d["p"]]
        if row:
            paint(min(row), y, d["P"], True)
    ty0 = int(min(p[1] for p in torso))
    if pid == "bublikov" and standing and not side:  # la raya negra del pecho a la cintura
        for y in range(ty0 + 1, ty0 + 9):
            paint(CX + mx, y, d["a"])
    if pid == "monfiz":  # la balaca amarilla, y la camiseta con el costado negro
        for xx in range(-1, 9):
            paint(hx + xx, hy + 2, d["a"])
        if standing and not side:
            for y in range(ty0 + 2, ty0 + 9):
                for x in range(CW):
                    if px[x, y + DY][:3] in (d["t"], d["T"]) and (x - CX) * mx > 2:
                        paint(x, y, (40, 40, 46))
    if pid == "yokovich" and standing:  # el cuello blanco y la franja azul
        for x in range(CW):
            if px[x, ty0 + DY][:3] in (d["t"], d["T"]):
                paint(x, ty0, d["a"])
            if px[x, ty0 + 6 + DY][:3] in (d["t"], d["T"]):
                paint(x, ty0 + 6, (40, 52, 104))
    if pid == "sabalenkova":  # el tigre: rayas naranjas en el antebrazo izquierdo
        el, hand = j("el"), j("hl")
        for t in (0.35, 0.65):
            x = el[0] + (hand[0] - el[0]) * t
            y = el[1] + (hand[1] - el[1]) * t
            paint(x, y, d["a"])
        # La muñequera de la mano derecha
        hr = j("hr")
        paint(hr[0], hr[1] - 1, (255, 255, 255))
    if pid in ("bublikov", "tiafuego", "sheltron"):  # la muñequera
        hr = j("hr")
        paint(hr[0], hr[1] - 1, d["a"])
    if pid == "fedorer":  # la balaca blanca sobre el pelo café
        for xx in range(0, 8):
            paint(hx + xx, hy + 2, (250, 250, 248))
        if side:  # de perfil: las puntas del nudo, colgando de la nuca
            for k, (bx, by) in enumerate(((-1, 3), (-2, 4))):
                xx = hx + (bx if mx > 0 else 7 - bx)
                if 0 <= xx < CW:
                    px[xx, hy + by + DY] = (250, 250, 248, 255)
        elif not front:  # las puntas del nudo, atrás
            paint(hx + 3, hy + 6, (250, 250, 248))
            paint(hx + 4, hy + 7, (250, 250, 248))
    if pid == "kyrgistan":  # los tatuajes del brazo derecho
        er, hr = j("er"), j("hr")
        for t in (0.25, 0.55, 0.8):
            paint(er[0] + (hr[0] - er[0]) * t, er[1] + (hr[1] - er[1]) * t, (52, 64, 110))
    if (pid == "el" or pid.startswith("el_")) and side:
        cx = sum(p[0] for p in torso) / 4
        for x in range(CW):  # la franja, solo en la mitad de la espalda
            if px[x, ty0 + 4 + DY][:3] in (d["t"], d["T"]) and (x - cx) * mx < 0:
                paint(x, ty0 + 4, (150, 36, 40))
        fx = max(p[0] for p in torso) if mx > 0 else min(p[0] for p in torso)
        for k in range(6):  # la corbata, volando para atrás por encima del hombro
            xx = int(round(fx - mx * (k - 0.5)))
            yy = ty0 + 1 - (1 if 1 <= k <= 3 else 0) + (1 if k == 5 else 0) + DY
            if 0 <= xx < CW and 0 <= yy < CH:
                px[xx, yy] = (d["a"] if k < 5 else (140, 30, 38)) + (255,)
    elif pid == "el" or pid.startswith("el_"):
        if standing and not front:  # la franja roja del torneo, en la espalda
            for x in range(CW):
                if px[x, ty0 + 4 + DY][:3] in (d["t"], d["T"]):
                    paint(x, ty0 + 4, (150, 36, 40))
        if standing and front:  # la corbata roja, floja, del cuello hasta la cintura
            cx = int(round(sum(p[0] for p in torso) / 4))
            paint(cx, ty0, (240, 240, 236))
            for y in range(ty0, ty0 + 9):
                paint(cx, y, d["a"] if y < ty0 + 8 else (140, 30, 38))
            paint(cx + 1, ty0 + 1, d["a"])
        elif standing:  # de espaldas: la corbata tirada por encima del hombro, colgando atrás
            sx = torso[1][0] - 2 * mx
            for k in range(5):
                paint(sx - k * mx * 0.3, ty0 + k, d["a"] if k < 4 else (140, 30, 38))
    if pid == "camillero" and standing:  # la cruz roja en el pecho (y en la espalda)
        cx = int(round(sum(p[0] for p in torso) / 4))
        for k in range(-1, 2):
            paint(cx, ty0 + 3 + k, d["a"])
            paint(cx + k, ty0 + 3, d["a"])
    if pid == "pecador" and standing:  # el cuello blanco
        for x in range(CW):
            if px[x, ty0 + DY][:3] in (d["t"], d["T"]):
                paint(x, ty0, (240, 240, 236))


def resolve(pose, front, lefty):
    """Qué pose se dibuja en una columna: (nombre, lado "d"/"i"/"", de perfil). Las de un lado cambian de
    lado de frente (el dibujo de frente es el de espaldas al espejo; las de perfil no) y en los zurdos (la
    hoja entera va al espejo)."""
    base, dr = pose, ""
    if pose.endswith(("_d", "_i")):
        base, dr = pose[:-2], pose[-1]
    side = POSE.get(base, POSE.get(base + "_d", {})).get("side", False)
    if dr and ((front and not side) != bool(lefty)):
        dr = "i" if dr == "d" else "d"
    return base, dr, side


def cell(pid: str, pose: str, front: bool):
    lefty = PLAYERS[pid].get("lefty")
    base, dr, side = resolve(pose, front, lefty)
    if side:
        im, meta = draw_side(pid, POSE[base], 1 if dr == "d" else -1)
    else:
        q = POSE[base] if not dr else (POSE[base + "_d"] if dr == "d" else mirror(POSE[base + "_d"]))
        im, meta = draw(pid, base, front, q)
    meta = {k: (None if v is None else [v[0], v[1] + DY]) for k, v in meta.items()}
    if lefty:  # zurdo: la raqueta en la otra mano
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
        meta = {k: (None if v is None else [CW - 1 - v[0], v[1]]) for k, v in meta.items()}
    return im, meta


def sheet(pid: str):
    """La hoja de un tenista y, por pose, [fila de espaldas, fila de frente] con {"rk", "hl"}."""
    out = Image.new("RGBA", (CW * len(POSES), CH * 2), (0, 0, 0, 0))
    metas = {}
    for row, front in enumerate((False, True)):
        for col, pose in enumerate(POSES):
            im, meta = cell(pid, pose, front)
            out.paste(im, (col * CW, row * CH))
            metas.setdefault(pose, []).append(meta)
    return out, metas


def meta_json(metas):
    """Lo que va al .json: la cabeza de la raqueta de cada pose (de espaldas y de frente) y la mano de
    la pelota en las del saque."""
    rk, hl = {}, {}
    for pose, (m0, m1) in metas.items():
        if m0["rk"] is not None and m1["rk"] is not None:
            rk[pose] = [round(v, 1) for v in m0["rk"] + m1["rk"]]
        if pose.startswith(("saque", "abajo")) and m0["hl"] is not None:
            hl[pose] = [round(v, 1) for v in m0["hl"] + m1["hl"]]
    return {"rk": rk, "hl": hl}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sheets, info = {}, {}
    for pid in list(PLAYERS):
        sheets[pid], metas = sheet(pid)
        sheets[pid].save(OUT / f"{pid}.png")
        info[pid] = meta_json(metas)
    # Él con la raqueta de cada uno (cuando termina el partido del que abandonó).
    for pid in [k for k in PLAYERS if k not in ("el", "camillero")]:
        PLAYERS["el_" + pid] = dict(PLAYERS["el"], r=PLAYERS[pid]["r"])
        im, metas = sheet("el_" + pid)
        im.save(OUT / f"el_{pid}.png")
        info["el_" + pid] = meta_json(metas)
        if pid == "fedorer":
            sheets["el_fedorer"] = im
    (OUT / "tenistas.json").write_text(json.dumps({"poses": POSES, "cell": [CW, CH], "feet": [CX, 34 + DY], "sheets": info}),
                                       encoding="utf-8")
    if "--preview" in sys.argv:
        tmp = Path(sys.argv[sys.argv.index("--preview") + 1])
        lam = Image.new("RGBA", (CW * len(POSES), CH * 2 * len(sheets)), (70, 120, 96, 255))
        for i, pid in enumerate(sheets):
            lam.alpha_composite(sheets[pid], (0, i * CH * 2))
        lam.resize((lam.width * 3, lam.height * 3), Image.NEAREST).save(tmp)
    print("ok:", ", ".join(sheets))


if __name__ == "__main__":
    main()
