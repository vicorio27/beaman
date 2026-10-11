"""El gallo que canta de noche (scripts/systems/NightLife.gd): avisa que sale la otra gente del barrio.
Cuatro notas ("qui-qui-ri-quiii"), con la voz rasposa y la última que se cae.
Salida: assets/audio/gallo.wav. Uso: python tools/audio/gallo.py  (desde la carpeta del proyecto)"""
import wave
import numpy as np

SR = 22050
rng = np.random.default_rng(7)


def note(dur, f0, f1, drop=0.0):
    n = int(SR * dur)
    t = np.arange(n) / SR
    u = t / dur
    f = f0 + (f1 - f0) * np.minimum(u * 3.0, 1.0) - drop * np.maximum(u - 0.6, 0.0) / 0.4
    f = f * (1.0 + 0.025 * np.sin(2 * np.pi * 28 * t))  # el temblor de la garganta
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = sum(np.sin(ph * k) / k ** 0.8 for k in range(1, 8))
    x += rng.uniform(-1, 1, n) * 0.25 * np.abs(np.sin(ph * 0.5))  # lo rasposo
    env = np.minimum(u * 12.0, 1.0) * np.minimum((1.0 - u) * 5.0, 1.0)
    return np.tanh(x * 0.9) * env


def gap(dur):
    return np.zeros(int(SR * dur))


x = np.concatenate([note(0.16, 620, 880), gap(0.05), note(0.14, 700, 960), gap(0.04),
                    note(0.2, 760, 1040), gap(0.03), note(0.95, 820, 1180, drop=520), gap(0.2)])
x = x / np.abs(x).max() * 0.7
with wave.open("assets/audio/gallo.wav", "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((x * 32767).astype("<i2").tobytes())
print("gallo: %.1f s" % (len(x) / SR))
