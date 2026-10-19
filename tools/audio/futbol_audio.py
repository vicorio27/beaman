"""Los sonidos de los penaltis en el lote (scripts/ui/Penal.gd), sintetizados.

    python tools/audio/futbol_audio.py

  assets/audio/futbol/patada.wav    el empeine contra la pelota pelada (un "tum" sordo)
  assets/audio/futbol/palo.wav      la pelota en el palo: el golpe y el tubo que queda sonando
  assets/audio/futbol/atajada.wav   la pelota contra las manos (o la panza) del arquero
  assets/audio/futbol/red.wav       la pelota en la red: el "fsss" de la malla que se infla
  assets/audio/futbol/fuego.wav     el supertiro saliendo: el cañonazo y el fuego que ruge
El de la barra llena y el de la superatajada son los del tenis (assets/audio/tenis/carga.wav, super.wav).
"""
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import compose as C  # noqa: E402

SR = C.SR
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "futbol")
rng = np.random.default_rng(31)


def save(name, x):
    x = np.asarray(x, dtype=float)
    x = np.clip(x / (np.abs(x).max() + 1e-9) * 0.85, -1, 1)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def patada():
    """El empeine contra la pelota: un golpe grave y sordo, y el cuero (un chasquido corto)."""
    t = C._t(0.16)
    body = np.sin(2 * np.pi * np.cumsum(95 + 140 * np.exp(-t / 0.012)) / SR) * np.exp(-t / 0.045)
    leather = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=700, hi=3500) * np.exp(-t / 0.008)
    return body + leather * 0.5


def palo():
    """En el palo: el golpe seco y el tubo que vibra (parciales que no son armónicos), largo."""
    t = C._t(1.1)
    hit = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=1200, hi=7000) * np.exp(-t / 0.01)
    ring = sum(np.sin(2 * np.pi * f * t + i) * g * np.exp(-t / d)
               for i, (f, g, d) in enumerate(((523, 1.0, 0.45), (1407, 0.7, 0.3), (2690, 0.45, 0.2), (4402, 0.25, 0.12))))
    return hit * 0.8 + ring * (1 + 0.15 * np.sin(2 * np.pi * 6 * t))


def atajada():
    """La pelota contra las manos: una palmada gruesa y el resoplido."""
    t = C._t(0.22)
    slap = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=300, hi=2500) * np.exp(-t / 0.02)
    thud = np.sin(2 * np.pi * (120 + 60 * np.exp(-t / 0.01)) * t) * np.exp(-t / 0.05)
    return slap + thud * 0.8


def red():
    """La red que se infla: un "fsss" de malla, con un golpecito al principio."""
    t = C._t(0.6)
    swish = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=1800, hi=8000)
    env = np.clip(t / 0.03, 0, 1) * np.exp(-np.clip(t - 0.05, 0, None) / 0.18)
    tap = np.sin(2 * np.pi * 180 * t) * np.exp(-t / 0.02)
    return swish * env + tap * 0.4


def fuego():
    """El supertiro: el cañonazo y el fuego que ruge mientras va (ruido grave que tiembla)."""
    t = C._t(0.9)
    boom = np.sin(2 * np.pi * np.cumsum(60 + 100 * np.exp(-t / 0.04)) / SR) * np.exp(-t / 0.2)
    roar = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=80, hi=900)
    roar *= (0.7 + 0.3 * np.sin(2 * np.pi * 13 * t)) * np.clip(t / 0.05, 0, 1) * np.exp(-np.clip(t - 0.3, 0, None) / 0.25)
    crack = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=2000, hi=8000) * np.exp(-t / 0.012)
    return np.tanh((boom * 1.2 + roar * 0.8 + crack * 0.6) * 1.4)


if __name__ == "__main__":
    save("patada", patada())
    save("palo", palo())
    save("atajada", atajada())
    save("red", red())
    save("fuego", fuego())
    print("sonidos listos en", OUT)
