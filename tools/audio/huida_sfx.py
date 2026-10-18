"""Los sonidos de la huida (el prólogo), sintetizados:

    python tools/audio/huida_sfx.py      -> assets/audio/huida/*.wav

  rotor.wav    el helicóptero encima: el golpe de las aspas (un ciclo que se repite sin costura)
  rafaga.wav   la ráfaga desde el helicóptero: diez tiros secos, con su eco de techo
  aleteo.wav   las palomas que salen todas al tiempo
  ploc.wav     lo que le tiran (la chancla, el huevo, la matera) cuando le da o cuando cae
  chispa.wav   el chisporroteo del cable pelado
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "huida")
RNG = np.random.default_rng(11)


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


def lowpass(x, k):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def env(n, attack, decay):
    t = np.arange(n) / SR
    return np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / decay)


def rotor():
    """Un segundo exacto: 13 golpes de aspa (ruido grave con un tono de 60 Hz) sobre el zumbido de la
    turbina. Empieza y termina en el mismo punto del ciclo: se repite sin que se note."""
    n = SR
    t = np.arange(n) / SR
    out = 0.25 * np.sin(2 * np.pi * 180 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 13 * t))  # la turbina
    noise = lowpass(RNG.standard_normal(n), 0.06)
    for k in range(13):
        start = int(k * n / 13)
        m = n // 13
        e = env(m, 0.004, 0.03)
        out[start:start + m] += e * (noise[start:start + m] * 2.2 + np.sin(2 * np.pi * 60 * t[:m]))
    return out


def rafaga():
    n = int(SR * 0.9)
    out = np.zeros(n)
    noise = RNG.standard_normal(n)
    for k in range(10):
        start = int(k * SR * 0.065)
        m = int(SR * 0.12)
        seg = slice(start, min(n, start + m))
        L = seg.stop - seg.start
        e = env(L, 0.001, 0.025)
        out[seg] += e * (noise[seg] + 0.8 * np.sin(2 * np.pi * 110 * np.arange(L) / SR))
        echo = slice(seg.start + int(SR * 0.05), min(n, seg.stop + int(SR * 0.05)))
        out[echo] += 0.3 * e[:echo.stop - echo.start] * noise[echo]
    return lowpass(out, 0.5)


def aleteo():
    n = int(SR * 1.1)
    out = np.zeros(n)
    noise = lowpass(RNG.standard_normal(n), 0.35)
    for k in range(26):
        start = int(RNG.uniform(0, n - SR * 0.08))
        m = int(SR * 0.06)
        out[start:start + m] += env(m, 0.005, 0.018) * noise[start:start + m] * RNG.uniform(0.4, 1.0)
    return out * np.linspace(1, 0.3, n)


def ploc():
    n = int(SR * 0.25)
    t = np.arange(n) / SR
    f = 260 * np.exp(-t * 18)
    out = env(n, 0.001, 0.05) * np.sin(2 * np.pi * np.cumsum(f) / SR)
    out += env(n, 0.001, 0.02) * lowpass(RNG.standard_normal(n), 0.4) * 0.7
    return out


def chispa():
    n = int(SR * 0.4)
    out = np.zeros(n)
    noise = RNG.standard_normal(n)
    for k in range(9):
        start = int(RNG.uniform(0, n - SR * 0.03))
        m = int(SR * 0.02)
        out[start:start + m] += env(m, 0.0005, 0.004) * noise[start:start + m]
    return out


def main():
    for name, fn in (("rotor", rotor), ("rafaga", rafaga), ("aleteo", aleteo), ("ploc", ploc), ("chispa", chispa)):
        save(name, fn())
    print("huida: 5 sonidos en", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
