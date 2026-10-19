"""La música y los sonidos del torneo de tenis (Highway to Hell), sintetizados.

    python tools/audio/tenis_audio.py

La música es rock de estadio ORIGINAL (no es AC/DC ni se le parece en la melodía): guitarra rítmica
saturada con acordes de quinta y espacio entre los golpes, bajo en corcheas, batería recta, palmas
del público en el coro y una guitarra que canta arriba. En la mayor, con la séptima y la tercera
menor de blues. Usa los instrumentos de compose.py.

  assets/music/tenis_partido.wav   en la cancha, mientras juegan los profesionales (128)
  assets/music/tenis_el.wav        cuando él toma la raqueta: más rápido (142), un tono arriba, y la
                                   guitarra canta todo el tiempo
  assets/music/tenis_cuadro.wav    el cuadro y la paga: el mismo riff con la mano apagada, esperando
  assets/music/tenis_afuera.wav    desde la calle: el partido a través de la tribuna (sin agudos) y
                                   el murmullo del público (Vecindario lo pone al lado del coliseo)

  assets/audio/tenis/golpe.wav      la raqueta (pock)            golpe_duro.wav  el cañonazo
  assets/audio/tenis/bote.wav       la pelota en el piso         red.wav         a la red
  assets/audio/tenis/aplauso.wav    aplausos                     ovacion.wav     el estadio de pie
  assets/audio/tenis/uy.wav         el "uuuy" del público cuando alguien falla una fácil
  assets/audio/tenis/chillido.wav   las zapatillas al frenar     chillido2.wav   (otro, más agudo)
  assets/audio/tenis/zas.wav        la raqueta cortando el aire, justo antes de pegarle
  assets/audio/tenis/rompe.wav      la raqueta contra el piso (Kyrgistán)
  assets/audio/tenis/grito.wav      el "¡ah!" de Sabalenkova al pegarle
"""
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import compose as C  # noqa: E402

SR = C.SR
SFX = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "tenis")
rng = np.random.default_rng(21)


# ------------------------------------------------------------------ la guitarra

def power(root, dur, mute=False):
    """Un acorde de quinta (la fundamental, la quinta y la octava), pulsado. Apagado: corto y opaco."""
    d = 0.11 if mute else dur
    s = np.zeros(int(d * SR))
    for iv, g in ((0, 1.0), (7, 0.8), (12, 0.6)):
        n = C.pluck(C.hz(root + iv), d, bright=0.55 if mute else 0.9, decay=0.990 if mute else 0.998)
        s[:len(n)] += n[:len(s)] * g
    return s


def amp(x, drive=5.0, lo=80, hi=3400):
    """El amplificador: satura y le quita lo que sobra abajo y arriba."""
    x = x / (np.abs(x).max() + 1e-9)
    return C.fft_filter(np.tanh(x * drive), lo=lo, hi=hi)


def clap():
    t = C._t(0.05)
    n = rng.uniform(-1, 1, len(t))
    burst = np.exp(-t / 0.008) + 0.6 * np.exp(-np.abs(t - 0.012) / 0.004)
    return C.fft_filter(n * burst, lo=800, hi=5000)


def crowd(n, gain=1.0):
    """El murmullo del estadio: ruido en la banda de las voces, que sube y baja despacio."""
    r = C.fft_filter(rng.uniform(-1, 1, n), lo=180, hi=1400, soft=1.2)
    r /= np.abs(r).max() + 1e-9
    t = np.arange(n) / n
    swell = 0.75 + 0.25 * np.sin(2 * np.pi * 3 * t) * np.sin(2 * np.pi * 7 * t + 1.0)
    return r * swell * gain


# ------------------------------------------------------------------ el tema

# El riff (dos compases, en tiempos): [tiempo, acorde, duración, apagado]. La-Do-Re / La-Sol-Mi:
# golpes con aire entre medio, y dos apagados que empujan.
RIFF = [
    (0, "A", 1.0, False), (1.5, "A", 0.25, True), (1.75, "A", 0.25, True), (2, "C", 0.5, False), (2.5, "D", 1.5, False),
    (4, "A", 1.0, False), (5.5, "A", 0.25, True), (5.75, "A", 0.25, True), (6, "G", 0.5, False), (6.5, "E", 1.5, False),
]
CHORUS = ["D", "D", "A", "A", "E", "E", "A", "A"]
LEAD = [
    ("E5", .5), ("G5", .5), ("A5", 1), ("A5", .5), ("C6", .5), ("A5", 1),
    ("G5", 1), ("E5", 1), ("D5", 2),
    ("E5", .5), ("G5", .5), ("A5", 1), ("C6", 1), ("D6", 1),
    ("C6", .5), ("A5", .5), ("G5", 1), ("A5", 2),
    ("B5", 1), ("G#5", .5), ("E5", .5), ("B5", 1), ("D6", 1),
    ("C#6", 1), ("B5", 1), ("G#5", 1), ("E5", 1),
    ("A5", 1.5), ("C6", .5), ("A5", 1), ("G5", .5), ("E5", .5),
    ("A5", 4),
]
# Lo que canta la guitarra en el riff (solo en la versión de él): respuestas cortas entre los golpes.
LEAD_RIFF = [
    (None, 3), ("C6", .5), ("D6", .5), ("E6", 2), ("D6", .5), ("C6", .5), ("A5", 1),
    (None, 3), ("G5", .5), ("A5", .5), ("C6", 1), ("A5", 1), ("G5", 1), ("E5", 1),
]


def lead_note(f, dur):
    """La guitarra que canta: cuerda brillante más una cuadrada con vibrato (se satura después)."""
    a = C.pluck(f, dur, bright=0.97, decay=0.9985)
    b = C.square(f, dur, duty=0.35, vib=0.012)
    n = min(len(a), len(b))
    return a[:n] * 0.6 + b[:n] * 0.4


def song(bpm, shift=0, mode="partido"):
    """16 compases: 8 de riff y 8 de coro. mode: "partido", "el" o "cuadro"."""
    bars = 16
    full = mode != "cuadro"
    tr = C.Track(bpm, bars * 4)
    gtr = C.Track(bpm, bars * 4)
    lead = C.Track(bpm, bars * 4)

    def root(ch, octave=2):
        return C.midi(ch + str(octave)) + shift

    # 1. El riff (compases 0-7): los golpes de quinta; el bajo sigue el acorde en corcheas.
    for rep in range(4):
        b0 = rep * 8
        for k, (beat, ch, dur, mute) in enumerate(RIFF):
            m = mute or mode == "cuadro"
            gtr.add(b0 + beat, power(root(ch, 3), tr.sec(dur * 0.95), m), 0.5 if m else 0.85)
            nxt = RIFF[k + 1][0] if k + 1 < len(RIFF) else 8
            b = beat
            while b < nxt - 0.01:
                tr.add(b0 + b, C.tri(C.hz(root(ch, 2)), tr.sec(0.45)), 0.55)
                b += 0.5
    # 2. El coro (compases 8-15): la guitarra en corcheas abiertas (o apagadas, en el cuadro), y arriba la que canta.
    for i, ch in enumerate(CHORUS):
        b = 32 + i * 4
        for k in range(8):
            accent = k in (0, 3, 6)
            mute = mode == "cuadro" or not accent
            gtr.add(b + k * 0.5, power(root(ch, 3), tr.sec(0.48), mute), 0.75 if accent else 0.42)
            tr.add(b + k * 0.5, C.tri(C.hz(root(ch, 2)), tr.sec(0.45)), 0.55)
    if full:
        notes = [((C.midi(n) + shift) if n else None, l) for n, l in LEAD]
        lead.line(32, notes, lead_note, 0.9)
        if mode == "el":
            riff_notes = [((C.midi(n) + shift) if n else None, l) for n, l in LEAD_RIFF]
            for rep in range(4):
                lead.line(rep * 8, riff_notes, lead_note, 0.7)
            # y en el coro, la segunda guitarra una tercera abajo
            lead.line(32, [((m - 4) if m else None, l) for m, l in notes], lead_note, 0.35)
    # 3. La batería: recta. Bombo en 1 y 3 (y el empujón), redoblante en 2 y 4, platillo en corcheas.
    for bar in range(bars):
        b = bar * 4
        last = bar % 8 == 7
        if mode == "cuadro":
            tr.add(b, C.kick(soft=True), 0.6)
            tr.add(b + 2, C.kick(soft=True), 0.5)
            for h in np.arange(0, 4, 0.5):
                tr.add(b + h, C.hat(), 0.12)
            continue
        kicks = [0, 2, 2.5] if not (mode == "el" and bar >= 8) else [0, 0.5, 1.5, 2, 2.5, 3.5]
        for k in kicks:
            tr.add(b + k, C.kick(0.24), 0.95)
        if last:  # el remate
            for s in (1, 2.5, 3, 3.25, 3.5, 3.75):
                tr.add(b + s, C.snare(), 0.6)
        else:
            tr.add(b + 1, C.snare(0.2), 0.7)
            tr.add(b + 3, C.snare(0.2), 0.7)
        for h in np.arange(0, 4, 0.5 if mode != "el" else 0.25):
            tr.add(b + h, C.hat(), 0.22 if h % 1 == 0 else 0.15)
        if bar % 8 == 0:  # el platillo de entrada a cada parte
            tr.add(b, C.hat(1.2, open_=True), 0.5)
        if bar >= 8 and not last:  # las palmas del público en el coro
            for k in (1, 3):
                for v in range(5):  # muchas manos, apenas desfasadas
                    tr.add(b + k + rng.uniform(-0.03, 0.03), clap(), 0.16)
    out = tr.buf + amp(gtr.buf, 5.5 if mode != "cuadro" else 3.0) * (0.55 if mode != "cuadro" else 0.4)
    if full:
        out = out + C.echo(amp(lead.buf, 4.0, lo=200, hi=4200), ((0.09, 0.25), (0.18, 0.12))) * 0.32
    out = out + crowd(len(out), 0.05 if mode != "cuadro" else 0.09)
    return out


# ------------------------------------------------------------------ los sonidos

def save_sfx(name, x):
    x = np.asarray(x, dtype=float)
    x = np.clip(x / (np.abs(x).max() + 1e-9) * 0.85, -1, 1)
    os.makedirs(SFX, exist_ok=True)
    with wave.open(os.path.join(SFX, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def golpe(hard=False):
    """La raqueta: un "pock" hueco (la pelota) y el chasquido de las cuerdas."""
    t = C._t(0.09 if hard else 0.07)
    f = (620 if hard else 820) * (1 + 0.5 * np.exp(-t / 0.004))
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (0.022 if hard else 0.016))
    snap = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=1800, hi=7000) * np.exp(-t / 0.006)
    x = body + snap * (0.9 if hard else 0.6)
    if hard:
        x = np.tanh(x * 2.0) + np.sin(2 * np.pi * 160 * t) * np.exp(-t / 0.03) * 0.4
    return x


def bote():
    t = C._t(0.06)
    body = np.sin(2 * np.pi * (260 + 120 * np.exp(-t / 0.005)) * t) * np.exp(-t / 0.014)
    grit = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=600, hi=3000) * np.exp(-t / 0.008) * 0.35
    return body + grit


def red():
    t = C._t(0.22)
    rattle = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=250, hi=1600) * np.exp(-t / 0.06)
    rattle *= 0.6 + 0.4 * np.sin(2 * np.pi * 38 * t)
    return rattle + np.sin(2 * np.pi * 140 * t) * np.exp(-t / 0.03) * 0.5


def aplauso(seconds=2.2, rate=90):
    n = int(seconds * SR)
    x = np.zeros(n + SR // 10)
    times = np.sort(rng.uniform(0, seconds, int(rate * seconds)))
    for tt in times:
        c = clap() * rng.uniform(0.4, 1.0)
        i = int(tt * SR)
        x[i:i + len(c)] += c
    x = x[:n]
    t = np.arange(n) / SR
    shape = np.clip(t / 0.15, 0, 1) * np.exp(-np.clip(t - 0.6, 0, None) / 0.7)
    return x * shape


def ovacion():
    x = aplauso(2.8, 140)
    n = len(x)
    t = np.arange(n) / SR
    roar = crowd(n, 1.0) * np.clip(t / 0.25, 0, 1) * np.exp(-np.clip(t - 0.9, 0, None) / 0.8)
    return x + roar * 0.8


def uy():
    """El "uuuy" del público: muchas voces graves que caen juntas, con la boca cerrada (u)."""
    dur = 1.3
    t = C._t(dur)
    x = np.zeros(len(t))
    for v in range(28):
        f0 = rng.uniform(150, 290)
        f = f0 * (1.12 - 0.18 * np.clip(t / dur, 0, 1)) * (1 + 0.01 * np.sin(2 * np.pi * rng.uniform(4, 6) * t))
        ph = np.cumsum(f) / SR
        saw = 2 * (ph % 1.0) - 1
        x += saw * rng.uniform(0.5, 1.0)
    x = C.fft_filter(x, lo=120, hi=650, soft=2.0)  # la u: casi sin brillo
    shape = np.clip(t / 0.12, 0, 1) * np.exp(-np.clip(t - 0.35, 0, None) / 0.4)
    return x * shape


def chillido(f0=1900.0):
    """Las zapatillas en la cancha dura al frenar: un chillido corto que tiembla y baja un poquito."""
    dur = 0.13
    t = C._t(dur)
    f = f0 * (1 + 0.06 * np.sin(2 * np.pi * 55 * t)) * (1 - 0.15 * t / dur)
    ph = np.cumsum(f) / SR
    tone = np.sin(2 * np.pi * ph) + 0.35 * np.sin(4 * np.pi * ph) + 0.15 * np.sin(6 * np.pi * ph)
    rub = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=1500, hi=6000) * 0.25
    env = np.clip(t / 0.012, 0, 1) * np.exp(-np.clip(t - 0.03, 0, None) / 0.05)
    return (tone + rub) * env


def zas():
    """La raqueta cortando el aire: ruido que sube de tono, en campana (las bandas se van mezclando)."""
    dur = 0.16
    t = C._t(dur)
    noise = rng.uniform(-1, 1, len(t))
    bands = 6
    x = np.zeros(len(t))
    for k in range(bands):
        lo = 450 * (1.35 ** k)
        w = np.clip(1 - np.abs(t / dur * (bands - 1) - k), 0, 1)
        x += C.fft_filter(noise, lo=lo, hi=lo * 2.0) * w
    return x * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2


def rompe():
    """La raqueta contra el piso: el golpe seco, el marco que cruje (dos veces) y las cuerdas sonando."""
    t = C._t(0.5)
    thud = np.sin(2 * np.pi * (90 + 60 * np.exp(-t / 0.01)) * t) * np.exp(-t / 0.05)
    crack = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=900, hi=6000)
    x = thud * 0.9 + crack * np.exp(-t / 0.02)
    late = np.clip(t - 0.06, 0, None)
    x += crack[::-1] * np.exp(-late / 0.015) * (t > 0.06) * 0.6
    ring = sum(np.sin(2 * np.pi * f * t) * g for f, g in ((1180, 1.0), (1730, 0.6), (2410, 0.4)))
    return x + ring * np.exp(-late / 0.12) * (t > 0.06) * 0.22


def grito():
    """El grito de Sabalenkova al pegarle: un "¡ah!" corto, con aire (la voz por formantes de a)."""
    dur = 0.32
    t = C._t(dur)
    f0 = 300 * (1 - 0.25 * t / dur) * (1 + 0.015 * np.sin(2 * np.pi * 7 * t))
    ph = np.cumsum(f0) / SR
    saw = 2 * (ph % 1.0) - 1
    voice = sum(C.fft_filter(saw, lo=f * 0.8, hi=f * 1.25) * g for f, g in ((850, 1.0), (1250, 0.6), (2700, 0.25)))
    voice += C.fft_filter(saw, lo=250, hi=700) * 0.5                     # el cuerpo de la voz (la fundamental)
    voice /= np.sqrt(np.mean(voice ** 2)) + 1e-9
    breath = C.fft_filter(rng.uniform(-1, 1, len(t)), lo=700, hi=3500)
    breath *= 0.25 / (np.sqrt(np.mean(breath ** 2)) + 1e-9)            # un poquito de aire, no más
    env = np.clip(t / 0.02, 0, 1) * np.exp(-np.clip(t - 0.08, 0, None) / 0.09)
    return np.tanh((voice + breath) * env * 0.9)


if __name__ == "__main__":
    partido = song(128, 0, "partido")
    C.save("tenis_partido", partido)
    C.save("tenis_el", song(142, 2, "el"))
    C.save("tenis_cuadro", song(112, 0, "cuadro"))
    afuera = C.fft_filter(partido, hi=520, soft=2.0) + crowd(len(partido), 0.25)
    C.save("tenis_afuera", afuera, peak=0.7)
    save_sfx("golpe", golpe())
    save_sfx("golpe_duro", golpe(True))
    save_sfx("bote", bote())
    save_sfx("red", red())
    save_sfx("aplauso", aplauso())
    save_sfx("ovacion", ovacion())
    save_sfx("uy", uy())
    save_sfx("chillido", chillido(1900))
    save_sfx("chillido2", chillido(2350))
    save_sfx("zas", zas())
    save_sfx("rompe", rompe())
    save_sfx("grito", grito())
    print("sonidos listos en", SFX)
