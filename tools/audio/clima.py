"""Los sonidos del aguacero: la lluvia (un loop) y tres truenos.

    python tools/audio/clima.py          -> assets/audio/lluvia.wav, assets/audio/trueno_1..3.wav
    python tools/audio/clima.py lluvia   -> solo la lluvia
"""
import os
import sys
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
RNG = np.random.default_rng(11)


def save(name, x):
    x = np.atleast_2d(np.asarray(x, dtype=float))
    x = np.clip(x / (np.max(np.abs(x)) or 1.0) * 0.8, -1, 1).T
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(x.shape[1])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def lowpass(x, k):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def _band(x, lo, hi):
    X = np.fft.rfft(x)
    f = np.maximum(np.fft.rfftfreq(len(x), 1 / SR), 1)
    return np.fft.irfft(X / (1 + (lo / f) ** 2) / (1 + (f / hi) ** 2), len(x))


def rain(dur=16.0):
    """El aguacero, en estéreo, para oírlo un buen rato sin que canse: un siseo tibio (sin graves que
    retumben ni agudos que chillen) que respira con las ráfagas, miles de gotitas finas, y cada tanto
    una gota gorda que cae de un alero. Todo vuelve al principio: el loop no tiene costura."""
    r = np.random.default_rng(5)
    n = int(SR * dur)
    t = np.arange(n) / n
    out = np.zeros((2, n))
    for ch in range(2):
        hiss = _band(r.standard_normal(n), 500, 3800)
        hiss /= np.abs(hiss).max()
        gust = 1 + 0.18 * np.sin(2 * np.pi * 3 * t + ch) + 0.1 * np.sin(2 * np.pi * 7 * t + 2 * ch)
        out[ch] += hiss * gust * 0.5
    def put(at, sig, pan):
        a = (pan + 1) * np.pi / 4
        idx = (at + np.arange(len(sig))) % n
        out[0, idx] += sig * np.cos(a)
        out[1, idx] += sig * np.sin(a)
    k = np.arange(int(0.012 * SR))
    for _ in range(int(dur * 260)):  # las gotitas sobre el pavimento y las tejas
        f = r.uniform(1800, 4200)
        tick = np.sin(2 * np.pi * f * k / SR) * np.exp(-k / r.uniform(6, 18)) * r.uniform(0.02, 0.09)
        put(int(r.integers(0, n)), tick, r.uniform(-0.9, 0.9))
    k = np.arange(int(0.09 * SR))
    for _ in range(int(dur * 1.1)):  # gotas gordas de los aleros: un 'plop' que baja
        f0 = r.uniform(420, 900)
        f = f0 * (1.0 - 0.35 * (k / len(k)) ** 0.5)
        plop = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-k / r.uniform(250, 520)) * r.uniform(0.15, 0.3)
        put(int(r.integers(0, n)), plop, r.uniform(-0.7, 0.7))
    return out


def thunder(dur, crack):
    n = int(SR * dur)
    t = np.arange(n) / SR
    rumble = lowpass(RNG.standard_normal(n), 0.01) * 3.0
    rumble *= (0.5 + 0.5 * np.sin(2 * np.pi * 0.9 * t + RNG.uniform(0, 6))) * np.exp(-t / (dur * 0.45))
    rumble *= np.minimum(1.0, t / 0.15)
    x = rumble
    if crack:
        c = RNG.standard_normal(n) * np.exp(-t / 0.08) * 0.6
        x = x + lowpass(c, 0.3)
    return x


def main():
    save("lluvia", rain())
    if "lluvia" in sys.argv:
        return
    save("trueno_1", thunder(3.0, True))
    save("trueno_2", thunder(4.0, False))
    save("trueno_3", thunder(2.4, True))
    print("clima: lluvia y 3 truenos")


if __name__ == "__main__":
    main()
