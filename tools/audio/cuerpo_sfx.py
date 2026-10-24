"""Los sonidos de lo que él hace (las acciones de scripts/player/Player.gd y lo que les pasa alrededor):

    python tools/audio/cuerpo_sfx.py      -> assets/audio/cuerpo/*.wav

  monedas.wav   le cae plata: monedas que suenan en la mano
  billete.wav   billetes: el papel que se dobla
  tos_1..3.wav  la tos: tres distintas (la 3, de pecho, con silbido)
  caida.wav     el cuerpo contra el piso
  pito_moto.wav el pito de la moto que lo tumba
  moto.wav      la moto que pasa y se va
  escoba.wav    los escobazos (Alejandro y el tendero)
  timbre.wav    el timbre de la bicicleta de Victoria
  traga.wav     tragar (agua, tinto)
  mastica.wav   el pan
  sacude.wav    sacudirse el agua
  lukas_llora.wav  Lukas con fiebre, de noche: tres gemidos por la nariz, que suben y se quiebran
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "cuerpo")
RNG = np.random.default_rng(29)


def save(name, x, peak_to=0.85):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) or 1.0
    x = np.clip(x / peak * peak_to, -1, 1)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def t_of(sec):
    return np.arange(int(sec * SR)) / SR


def biquad(x, kind, f, q=0.7):
    """Filtro de segundo orden (RBJ): 'lp', 'hp' o 'bp'."""
    w0 = 2 * np.pi * f / SR
    a = np.sin(w0) / (2 * q)
    c = np.cos(w0)
    if kind == "lp":
        b = [(1 - c) / 2, 1 - c, (1 - c) / 2]
    elif kind == "hp":
        b = [(1 + c) / 2, -(1 + c), (1 + c) / 2]
    else:
        b = [a, 0.0, -a]
    a0, a1, a2 = 1 + a, -2 * c, 1 - a
    b0, b1, b2 = [v / a0 for v in b]
    a1 /= a0
    a2 /= a0
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x):
        out = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, out
        y[i] = out
    return y


def env(n, attack, decay):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-np.maximum(0.0, t - attack) / decay)
    return e


def place(dst, src, at):
    i = int(at * SR)
    j = min(len(dst), i + len(src))
    dst[i:j] += src[: j - i]


def ping(f, dur, decay):
    t = t_of(dur)
    tone = (np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 2.76 * t) + 0.25 * np.sin(2 * np.pi * f * 5.4 * t))
    return tone * np.exp(-t / decay)


def monedas():
    x = np.zeros(int(0.7 * SR))
    for k in range(6):
        f = RNG.uniform(2300, 3900)
        place(x, ping(f, 0.4, RNG.uniform(0.05, 0.12)) * RNG.uniform(0.5, 1.0), 0.03 + k * RNG.uniform(0.04, 0.09))
    return x


def billete():
    n = int(0.35 * SR)
    noise = RNG.normal(0, 1, n)
    x = biquad(noise, "bp", 3200, 0.8)
    flutter = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 34 * t_of(0.35)))
    return x * flutter * env(n, 0.01, 0.12)


def tos(deep=1.0, wheeze=False, count=2, seed=0):
    rng = np.random.default_rng(seed)
    total = 0.25 + 0.32 * count + (0.5 if wheeze else 0.0)
    x = np.zeros(int(total * SR))
    for k in range(count):
        dur = 0.26 * deep
        n = int(dur * SR)
        t = t_of(dur)
        noise = rng.normal(0, 1, n)
        body = biquad(noise, "bp", 520 / deep, 1.2) * 1.4 + biquad(noise, "bp", 1500, 1.5) * 0.7 + biquad(noise, "hp", 2500) * 0.25
        f0 = (130 / deep) * (1.0 - 0.3 * t / dur)
        voice = np.sign(np.sin(2 * np.pi * np.cumsum(f0) / SR)) * 0.25 * np.exp(-t / 0.05)
        e = env(n, 0.006, 0.07 * deep) + 0.25 * env(n, 0.02, 0.15)
        place(x, (body + voice) * e * rng.uniform(0.75, 1.0), 0.04 + k * rng.uniform(0.26, 0.34))
    if wheeze:  # el pecho le silba al tomar aire
        n = int(0.45 * SR)
        t = t_of(0.45)
        w = biquad(rng.normal(0, 1, n), "bp", 1900, 6.0) * np.sin(np.pi * t / 0.45) ** 2
        place(x, w * 0.35, 0.3 + 0.32 * count - 0.25)
    return x


def caida():
    n = int(0.6 * SR)
    t = t_of(0.6)
    f = 70 * np.exp(-t / 0.12) + 38
    thud = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.09)
    slap = biquad(RNG.normal(0, 1, n), "lp", 900) * np.exp(-t / 0.03)
    cloth = biquad(RNG.normal(0, 1, n), "bp", 2400, 0.9) * env(n, 0.05, 0.12) * 0.25
    return thud * 1.2 + slap * 0.8 + cloth


def pito_moto():
    x = np.zeros(int(0.75 * SR))
    for k, (f, d) in enumerate([(430, 0.16), (430, 0.3)]):
        t = t_of(d)
        tone = np.sign(np.sin(2 * np.pi * f * t)) * 0.5 + np.sign(np.sin(2 * np.pi * f * 1.26 * t)) * 0.5
        tone = biquad(tone, "lp", 2200)
        place(x, tone * env(len(t), 0.01, 0.6), 0.02 + k * 0.24)
    return x


def moto():
    dur = 1.4
    t = t_of(dur)
    f = 95 + 40 * np.exp(-t / 0.5) - 25 * t  # pasa y se va
    saw = 2 * ((np.cumsum(f) / SR) % 1.0) - 1
    rough = biquad(RNG.normal(0, 1, len(t)), "lp", 600) * 0.4
    loud = np.exp(-((t - 0.35) / 0.45) ** 2)
    return biquad(saw + rough, "lp", 1400) * loud


def escoba():
    x = np.zeros(int(1.1 * SR))
    for k in range(3):
        n = int(0.22 * SR)
        s = biquad(RNG.normal(0, 1, n), "hp", 1800) * env(n, 0.04, 0.07)
        place(x, s * RNG.uniform(0.7, 1.0), 0.05 + k * 0.33)
    return x


def timbre():
    x = np.zeros(int(1.1 * SR))
    for k in range(2):
        t = t_of(0.9)
        f = 2150
        tone = (np.sin(2 * np.pi * f * t) + 0.6 * np.sin(2 * np.pi * f * 1.48 * t) + 0.3 * np.sin(2 * np.pi * f * 2.9 * t))
        trem = 1 + 0.35 * np.sin(2 * np.pi * 22 * t)
        place(x, tone * trem * np.exp(-t / 0.35), 0.02 + k * 0.18)
    return x


def traga():
    dur = 0.22
    t = t_of(dur)
    f = 260 * np.exp(-t / 0.06) + 110
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), 0.01, 0.05)


def mastica():
    x = np.zeros(int(0.9 * SR))
    for k in range(3):
        n = int(0.12 * SR)
        crack = biquad(RNG.normal(0, 1, n) * (RNG.random(n) < 0.25), "bp", 2600, 0.8)
        place(x, crack * env(n, 0.003, 0.04), 0.03 + k * 0.27)
    return x


def sacude():
    x = np.zeros(int(0.8 * SR))
    for k in range(40):
        f = RNG.uniform(3000, 6500)
        place(x, ping(f, 0.04, 0.008) * RNG.uniform(0.2, 0.6), RNG.uniform(0.0, 0.6))
    n = int(0.7 * SR)
    flap = biquad(RNG.normal(0, 1, n), "bp", 900, 0.8) * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * t_of(0.7))) * env(n, 0.05, 0.25)
    place(x, flap * 0.6, 0.0)
    return x


# ---------------------------------------------------------------- La feria (scripts/ui/FeriaJuegos.gd)

def pop():  # el globo que revienta
    n = int(0.25 * SR)
    t = t_of(0.25)
    crack = RNG.normal(0, 1, n) * np.exp(-t / 0.012)
    body = biquad(RNG.normal(0, 1, n), "bp", 900, 0.7) * np.exp(-t / 0.05) * 0.5
    return crack + body


def pum():  # el carrito chocón contra otro: caucho y lata
    n = int(0.35 * SR)
    t = t_of(0.35)
    f = 120 * np.exp(-t / 0.05) + 60
    thump = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.08)
    rattle = biquad(RNG.normal(0, 1, n), "bp", 2600, 1.5) * np.exp(-t / 0.06) * 0.4
    return thump + rattle


def motor():  # el motorcito de la garra (se repite)
    dur = 1.0
    t = t_of(dur)
    hum = np.sin(2 * np.pi * 180 * t) * 0.5 + np.sign(np.sin(2 * np.pi * 360 * t)) * 0.15
    return biquad(hum + RNG.normal(0, 0.15, len(t)), "lp", 1800) * 0.8


def carraca():  # la cadena de la montaña rusa subiendo: clac clac clac
    x = np.zeros(int(1.0 * SR))
    for k in range(8):
        n = int(0.03 * SR)
        click = biquad(RNG.normal(0, 1, n), "bp", 1800, 2.0) * env(n, 0.001, 0.008)
        place(x, click, k * 0.125)
    return x


def campanita():  # la sortija en la mano
    t = t_of(0.8)
    tone = np.sin(2 * np.pi * 1760 * t) + 0.5 * np.sin(2 * np.pi * 2640 * t) + 0.3 * np.sin(2 * np.pi * 3960 * t)
    return tone * np.exp(-t / 0.25)


def llora():
    """El gemido de un perro: un tono nasal que sube y se quiebra, con temblor, tres veces (cada vez más corto)."""
    out = np.zeros(int(2.6 * SR))
    for at, dur, f0, f1 in ((0.0, 0.95, 720, 1080), (1.05, 0.7, 760, 1020), (1.85, 0.5, 700, 940)):
        t = t_of(dur)
        k = t / dur
        f = f0 + (f1 - f0) * np.sin(np.pi * np.minimum(1.0, k * 1.25)) ** 0.8         # sube y se quiebra al final
        f *= 1.0 + 0.025 * np.sin(2 * np.pi * 7.5 * t)                                 # el temblor
        ph = 2 * np.pi * np.cumsum(f) / SR
        tone = np.sin(ph) + 0.45 * np.sin(2 * ph) + 0.2 * np.sin(3 * ph) + 0.08 * np.sin(4 * ph)
        tone += 0.06 * RNG.standard_normal(len(t))                                      # el aire por la nariz
        e = np.minimum(1.0, t / 0.06) * np.minimum(1.0, (dur - t) / 0.12) ** 1.5
        place(out, tone * e, at)
    return biquad(biquad(out, "bp", 950, 0.9), "lp", 2600)


def main():
    save("feria_pop", pop())
    save("feria_pum", pum())
    save("feria_motor", motor(), 0.5)
    save("feria_carraca", carraca(), 0.6)
    save("feria_campanita", campanita(), 0.6)
    save("monedas", monedas())
    save("billete", billete(), 0.6)
    save("tos_1", tos(1.0, False, 2, seed=1))
    save("tos_2", tos(1.1, False, 3, seed=2))
    save("tos_3", tos(1.35, True, 3, seed=3))
    save("caida", caida())
    save("pito_moto", pito_moto(), 0.7)
    save("moto", moto(), 0.7)
    save("escoba", escoba(), 0.7)
    save("timbre", timbre(), 0.7)
    save("traga", traga(), 0.6)
    save("mastica", mastica(), 0.6)
    save("sacude", sacude(), 0.6)
    save("lukas_llora", llora(), 0.6)
    print("listo:", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
