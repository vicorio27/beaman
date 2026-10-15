"""Los sonidos de PLOMO (el sueño tipo Doom), sintetizados: disparos, la bala de los malos, los quejidos
de cada muerto y el dolor de él cuando le pegan.

    python tools/audio/plomo_sfx.py      -> assets/audio/plomo/*.wav

Las voces son una sierra con la altura que cae, pasada por tres formantes (una vocal: a, o, u, e) y con
un poco de aire. Suenan a garganta, sin palabras.
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "plomo")
RNG = np.random.default_rng(7)

# Formantes (Hz) de cada vocal: F1, F2, F3.
VOWELS = {"a": (750, 1200, 2500), "o": (500, 900, 2400), "u": (330, 800, 2300), "e": (450, 1800, 2550)}


def save(name, x):
    x = np.asarray(x, dtype=float)
    peak = np.max(np.abs(x)) or 1.0
    x = np.clip(x / peak * 0.85, -1, 1)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def env(n, attack, decay):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / decay)


def resonator(x, f, bw):
    """Un filtro de dos polos (un formante)."""
    r = np.exp(-np.pi * bw / SR)
    c1, c2 = 2 * r * np.cos(2 * np.pi * f / SR), -r * r
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    g = 1 - r
    for i, v in enumerate(x):
        y0 = g * v + c1 * y1 + c2 * y2
        y[i] = y0
        y2, y1 = y1, y0
    return y


def lowpass(x, k):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def shot(dur, thump_hz, noise_decay, bright):
    n = int(SR * dur)
    t = np.arange(n) / SR
    noise = RNG.standard_normal(n)
    crack = noise * env(n, 0.0005, noise_decay)
    body = lowpass(noise, bright) * env(n, 0.001, noise_decay * 2.5)
    thump = np.sin(2 * np.pi * thump_hz * t * (1 - 0.5 * t / dur)) * env(n, 0.001, 0.05)
    return crack * 0.6 + body * 1.4 + thump * 0.9


def voice(dur, f0, f1, vowel, breath=0.15, shake=0.0, decay=None):
    """Una queja: la altura va de f0 a f1; shake = temblor (el que se muere)."""
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = f0 + (f1 - f0) * (t / dur) ** 0.7
    if shake:
        f = f * (1 + shake * np.sin(2 * np.pi * 7 * t))
    phase = np.cumsum(f) / SR
    saw = 2 * (phase % 1.0) - 1
    src = saw + breath * RNG.standard_normal(n)
    out = sum(resonator(src, fr, 90 + k * 40) * (1.0, 0.6, 0.3)[k] for k, fr in enumerate(VOWELS[vowel]))
    shape = env(n, 0.02, decay or dur * 0.5)
    return out * shape


def main():
    save("pistola", shot(0.32, 110, 0.03, 0.12))
    save("escopeta", np.concatenate([shot(0.55, 70, 0.06, 0.08), np.zeros(int(SR * 0.12)),
                                     RNG.standard_normal(int(SR * 0.03)) * env(int(SR * 0.03), 0.0005, 0.006) * 0.4,
                                     np.zeros(int(SR * 0.08)),
                                     RNG.standard_normal(int(SR * 0.03)) * env(int(SR * 0.03), 0.0005, 0.006) * 0.4]))
    save("puno", shot(0.15, 90, 0.008, 0.05) * 0.6)
    # La bala de ellos: más fina, con un silbido que baja (pasa cerca).
    n = int(SR * 0.4)
    t = np.arange(n) / SR
    whistle = np.sin(2 * np.pi * np.cumsum(2400 - 1800 * t / 0.4) / SR) * env(n, 0.05, 0.12) * 0.3
    save("bala_enemiga", np.pad(shot(0.18, 160, 0.015, 0.2), (0, n - int(SR * 0.18))) * 0.8 + whistle)
    # Los quejidos de los que se mueren: cuatro, para que no se repita.
    save("muere_1", voice(0.7, 150, 70, "a", shake=0.04))
    save("muere_2", voice(0.55, 190, 90, "o", breath=0.25))
    save("muere_3", np.concatenate([voice(0.18, 170, 150, "u"), voice(0.6, 160, 60, "a", shake=0.08)]))
    save("muere_4", voice(0.9, 120, 55, "o", breath=0.35, shake=0.06))
    # El jefe, más largo y más grave.
    save("muere_jefe", np.concatenate([voice(0.4, 110, 140, "a"), voice(1.4, 140, 45, "o", breath=0.3, shake=0.1)]))
    # Él, cuando le pegan: cortito, entre dientes.
    save("dolor_1", voice(0.22, 170, 120, "u", breath=0.3, decay=0.08))
    save("dolor_2", voice(0.28, 150, 100, "e", breath=0.35, decay=0.1))
    save("dolor_3", voice(0.18, 200, 140, "a", breath=0.25, decay=0.06))
    # Los de ellos cuando les entra (no se mueren todavía).
    save("ay_1", voice(0.2, 220, 180, "a", breath=0.2, decay=0.07))
    save("ay_2", voice(0.2, 180, 150, "e", breath=0.25, decay=0.07))
    print("plomo: 16 sonidos")


if __name__ == "__main__":
    main()
