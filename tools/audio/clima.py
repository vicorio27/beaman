"""Los sonidos del aguacero: la lluvia (un loop) y tres truenos.

    python tools/audio/clima.py      -> assets/audio/lluvia.wav, assets/audio/trueno_1..3.wav
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
RNG = np.random.default_rng(11)


def save(name, x):
    x = np.asarray(x, dtype=float)
    x = np.clip(x / (np.max(np.abs(x)) or 1.0) * 0.8, -1, 1)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
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


def rain(dur=6.0):
    """Ruido suave (el aguacero de fondo) y gotas sueltas (clics cortos). Empalma consigo mismo."""
    n = int(SR * dur)
    bed = lowpass(RNG.standard_normal(n), 0.25) - lowpass(RNG.standard_normal(n), 0.02) * 0.5
    drops = np.zeros(n)
    for _ in range(int(dur * 60)):
        at = RNG.integers(0, n - 200)
        k = np.arange(120)
        drops[at:at + 120] += RNG.uniform(0.2, 0.7) * np.exp(-k / RNG.uniform(8, 25)) * RNG.standard_normal(120)
    x = bed * 0.6 + drops * 0.5
    fade = int(SR * 0.3)  # el final se funde con el principio: loop sin costura
    x[:fade] = x[:fade] * np.linspace(0, 1, fade) + x[-fade:] * np.linspace(1, 0, fade)
    return x[:-fade]


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
    save("trueno_1", thunder(3.0, True))
    save("trueno_2", thunder(4.0, False))
    save("trueno_3", thunder(2.4, True))
    print("clima: lluvia y 3 truenos")


if __name__ == "__main__":
    main()
