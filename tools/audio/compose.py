"""Música del juego, generada por código (python tools/audio/compose.py).

Un mini sintetizador con numpy: ondas cuadradas y triangulares (chiptune), guitarra pulsada
(Karplus-Strong), piano, cajita de música, batería, lluvia y filtro de radio AM.
Cada tema es un loop: las colas de las notas que pasan el final vuelven al principio,
así el loop empalma sin corte. Salida: assets/music/<id>.wav (22050 Hz, mono, 16 bits).

Temas (ver docs/DISENO_CIUDAD_Y_SISTEMAS.md, "Música"):
  dream_fight     sueño, beat 'em up: chiptune rockero (Streets of Rage)
  truck           el camión: el mismo riff, más rápido y desesperado
  lilato          jefe: épica en re menor
  lilato_serpent  la serpiente: el tema de Lilato que se desafina y se rompe
  city_day        la ciudad de día: cumbia lenta lo-fi, de guitarra
  city_night      la ciudad de noche: la misma, lenta y oscura, con lluvia y motos
  bakery          lo de Germán: un bolero en una radio AM vieja
  cafe            lo de Marta: un vals en la radio
  night           antes de dormir: piano solo, con mucho aire
  memory          la memoria: cajita de música desafinada
  moto_ride       la moto: blues-rock de motero (shuffle en mi, guitarra saturada, slide)
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "music")
rng = np.random.default_rng(7)

NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(n):
    acc, i = 0, 1
    if n[1] in "#b":
        acc, i = (1 if n[1] == "#" else -1), 2
    return 12 * (int(n[i:]) + 1) + NOTE[n[0]] + acc


def hz(n):
    m = midi(n) if isinstance(n, str) else n
    return 440.0 * 2 ** ((m - 69) / 12)


# ------------------------------------------------------------------ instrumentos

def _t(dur):
    return np.arange(int(dur * SR)) / SR


def env(n, a=0.004, r=0.04, hold=1.0):
    e = np.ones(n) * hold
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    e[:na] *= np.linspace(0, 1, na)[: len(e[:na])]
    if nr < n:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def phase(f, dur, vib=0.0, vib_hz=5.5, vib_delay=0.15):
    t = _t(dur)
    depth = vib * np.clip((t - vib_delay) / 0.2, 0, 1)
    inst = f * (1 + depth * np.sin(2 * np.pi * vib_hz * t))
    return np.cumsum(inst) / SR % 1.0


def square(f, dur, duty=0.25, vib=0.0, decay=0.0):
    ph = phase(f, dur, vib)
    s = np.where(ph < duty, 1.0, -1.0) * env(len(ph), r=0.02)
    if decay:
        s *= np.exp(-_t(dur) / decay)
    return s


def tri(f, dur, decay=0.0):
    ph = phase(f, dur)
    s = (2 * np.abs(2 * ph - 1) - 1) * env(len(ph), r=0.02)
    if decay:
        s *= np.exp(-_t(dur) / decay)
    return s


def pluck(f, dur, bright=0.6, decay=0.996):
    """Karplus-Strong: una cuerda pulsada."""
    n, N = int(dur * SR), max(2, int(SR / f))
    out = np.zeros(n + N + 1)
    burst = rng.uniform(-1, 1, N)
    for _ in range(int((1 - bright) * 6)):  # menos brillo = ruido inicial más suave
        burst = 0.5 * (burst + np.roll(burst, 1))
    out[1:N + 1] = burst
    for start in range(N + 1, n + N + 1, N):
        end = min(start + N, n + N + 1)
        out[start:end] = decay * 0.5 * (out[start - N:end - N] + out[start - N - 1:end - N - 1])
    s = out[N + 1:N + 1 + n]
    return s * env(len(s), a=0.001, r=0.03) / (np.abs(s).max() + 1e-9)


def piano(f, dur):
    t = _t(dur)
    s = np.zeros_like(t)
    for k in range(1, 7):
        fk = f * k * np.sqrt(1 + 0.0004 * k * k)
        s += np.sin(2 * np.pi * fk * t) / k ** 1.6 * np.exp(-t * (0.9 + 0.7 * k))
    return s * env(len(t), a=0.003, r=0.05)


def musicbox(f, dur):
    t = _t(dur)
    s = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 2 * t) * np.exp(-t * 6) \
        + 0.12 * np.sin(2 * np.pi * f * 4.2 * t) * np.exp(-t * 14)
    return s * np.exp(-t * 2.2) * env(len(t), a=0.002, r=0.05)


def kick(dur=0.22, soft=False):
    t = _t(dur)
    f = 45 + 110 * np.exp(-t / 0.03)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (0.09 if soft else 0.12))
    return s * (0.6 if soft else 1.0)


def snare(dur=0.18):
    t = _t(dur)
    return rng.uniform(-1, 1, len(t)) * np.exp(-t / 0.05) * 0.7 + np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.03) * 0.5


def hat(dur=0.05, open_=False):
    t = _t(dur)
    n = rng.uniform(-1, 1, len(t))
    n = n - np.convolve(n, np.ones(4) / 4, "same")  # se queda con lo agudo
    return n * np.exp(-t / (0.06 if open_ else 0.012))


def shaker(dur=0.07):
    t = _t(dur)
    n = rng.uniform(-1, 1, len(t))
    n = n - np.convolve(n, np.ones(3) / 3, "same")
    return n * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2


# ------------------------------------------------------------------ mezcla y efectos

class Track:
    def __init__(self, bpm, beats):
        self.bpm = bpm
        self.buf = np.zeros(int(round(beats * 60.0 / bpm * SR)))

    def at(self, beat):
        return int(round(beat * 60.0 / self.bpm * SR))

    def sec(self, beats):
        return beats * 60.0 / self.bpm

    def add(self, beat, sig, gain=1.0):
        """Suma con la vuelta al principio: el loop empalma solo."""
        i, n = self.at(beat) % len(self.buf), len(self.buf)
        while len(sig):
            take = min(len(sig), n - i)
            self.buf[i:i + take] += sig[:take] * gain
            sig, i = sig[take:], 0

    def line(self, start, notes, inst, gain=1.0, legato=0.95, **kw):
        """notes: [(nota | [acorde] | None, beats), ...]"""
        b = start
        for n, length in notes:
            if n is not None:
                for k, x in enumerate(n if isinstance(n, list) else [n]):
                    self.add(b + k * 0.03, inst(hz(x), self.sec(length) * legato, **kw), gain)
            b += length
        return b


def fft_filter(x, lo=0.0, hi=SR / 2, soft=1.5):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    mask = np.ones_like(f)
    if lo > 0:
        mask *= 1 / (1 + (lo / np.maximum(f, 1)) ** (2 * soft))
    if hi < SR / 2:
        mask *= 1 / (1 + (f / hi) ** (2 * soft))
    return np.fft.irfft(X * mask, len(x))


def echo(x, taps=((0.031, 0.32), (0.047, 0.28), (0.083, 0.22), (0.13, 0.17), (0.21, 0.12), (0.34, 0.08))):
    y = x.copy()
    for d, g in taps:
        y += np.roll(x, int(d * SR)) * g
    return y


def warble(x, depth=0.0015, rate=0.5):
    """Wow/flutter de cinta: ritmo de lectura que oscila (el loop sigue cerrando)."""
    n = len(x)
    cycles = max(1, round(rate * n / SR))
    t = np.arange(n)
    pos = t + depth * SR * np.sin(2 * np.pi * cycles * t / n)
    return np.interp(pos % n, t, x, period=n)


def crackle(n, density=6.0, gain=0.25):
    c = np.zeros(n)
    idx = rng.integers(0, n, int(density * n / SR))
    c[idx] = rng.uniform(-1, 1, len(idx))
    return np.convolve(c, np.exp(-np.arange(30) / 6), "same") * gain


def radio(x):
    y = fft_filter(x, lo=320, hi=3000, soft=2.0)
    y = np.tanh(y * 2.2) / 2.2
    y = y + fft_filter(rng.uniform(-1, 1, len(y)), lo=2000, hi=6000) * 0.012
    return warble(y, 0.0025, 0.35) + crackle(len(y), 10, 0.18)


def rain(n, gain=0.12):
    r = fft_filter(rng.uniform(-1, 1, n), lo=500, hi=4500)
    r /= np.abs(r).max()
    drops = crackle(n, 40, 0.5)
    return (r + fft_filter(drops, lo=1500)) * gain


def save(name, x, peak=0.85):
    x = np.tanh(x / (np.abs(x).max() + 1e-9) * 1.2)
    x = x / np.abs(x).max() * peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    print(f"{name}: {len(x) / SR:.1f} s")


# ------------------------------------------------------------------ temas

def drums_rock(tr, bars, fill_every=8, double_kick=False):
    for bar in range(bars):
        b = bar * 4
        for k in ([0, 1, 1.5, 2, 3, 3.5] if double_kick else [0, 1.5, 2]):
            tr.add(b + k, kick(), 0.9)
        last = (bar + 1) % fill_every == 0
        if last:
            for s in [1, 2.5, 3, 3.25, 3.5, 3.75]:
                tr.add(b + s, snare(), 0.55)
        else:
            tr.add(b + 1, snare(), 0.6)
            tr.add(b + 3, snare(), 0.6)
        for h in np.arange(0, 4, 0.5):
            tr.add(b + h, hat(open_=(h == 3.5)), 0.25)


FIGHT_CHORDS = ["E", "E", "C", "D", "E", "E", "C", "B"] * 2
FIGHT_LEAD = [
    # Em Em
    ("E5", .5), ("G5", .5), ("A5", .5), ("B5", 1), ("A5", .5), ("G5", .5), ("E5", .5),
    ("D5", .5), ("E5", 1.5), (None, 2),
    # C D
    ("G5", .5), ("E5", .5), ("G5", .5), ("A5", 1), ("B5", .5), ("A5", .5), ("G5", .5),
    ("F#5", 1), ("D5", 1), ("F#5", 1), ("A5", 1),
    # Em Em
    ("E5", .5), ("G5", .5), ("A5", .5), ("B5", 1), ("A5", .5), ("G5", .5), ("E5", .5),
    ("D5", .5), ("E5", 1.5), ("B4", 1), ("D5", 1),
    # C B
    ("G5", .5), ("E5", .5), ("C5", .5), ("E5", .5), ("G5", 1), ("E5", 1),
    ("F#5", 1), ("D#5", 1), ("F#5", 1), ("B4", 1),
]


def fight_song(bpm, double_kick):
    bars = 16
    tr = Track(bpm, bars * 4)
    for bar, ch in enumerate(FIGHT_CHORDS):
        root = midi(ch + "2")
        for k, iv in enumerate([0, 0, 12, 0, 0, 12, 0, 7]):
            tr.add(bar * 4 + k * 0.5, tri(hz(root + iv), tr.sec(0.45)), 0.55)
            tr.add(bar * 4 + k * 0.5, square(hz(root + iv), tr.sec(0.4), 0.5, decay=0.12), 0.12)
        third = 3 if ch in ("E",) else 4
        for k in range(8):  # arpegio
            iv = [0, 7, 12, third + 12][k % 4]
            tr.add(bar * 4 + k * 0.5, square(hz(root + 24 + iv), tr.sec(0.2), 0.125, decay=0.05), 0.1)
    tr.line(0, FIGHT_LEAD, square, 0.32, duty=0.25, vib=0.004)
    end = tr.line(32, FIGHT_LEAD, square, 0.3, duty=0.25, vib=0.004)
    # segunda vuelta: armonía una tercera abajo, más fina
    harm = [((midi(n) - 4) if n else None, l) for n, l in FIGHT_LEAD]
    tr.line(32, harm, square, 0.14, duty=0.125)
    drums_rock(tr, bars, double_kick=double_kick)
    return tr.buf


def lilato_song():
    bars = 16
    tr = Track(150, bars * 4)
    chords = [("D", "m"), ("Bb", ""), ("G", "m"), ("A", "")] * 4
    for bar, (r, q) in enumerate(chords):
        root = midi(r + "2")
        for k, iv in enumerate([0, 0, 12, 0, 7, 0, 12, 10]):
            tr.add(bar * 4 + k * 0.5, square(hz(root + iv), tr.sec(0.42), 0.5, decay=0.15), 0.3)
        third = 3 if q == "m" else 4
        tr.add(bar * 4, square(hz(root + 12), tr.sec(3.8), 0.5, decay=1.5), 0.08)
        tr.add(bar * 4, square(hz(root + 12 + third), tr.sec(3.8), 0.5, decay=1.5), 0.07)
        tr.add(bar * 4, square(hz(root + 19), tr.sec(3.8), 0.5, decay=1.5), 0.07)
    lead = [
        ("D5", 1), ("F5", 1), ("A5", 2), ("Bb5", 2), ("A5", 1), ("G5", 1),
        ("G5", 1), ("F5", 1), ("E5", 1), ("D5", 1), ("C#5", 2), ("E5", 2),
        ("D5", 1), ("F5", 1), ("A5", 1), ("D6", 1), ("D6", 1.5), ("C6", .5), ("Bb5", 2),
        ("Bb5", 1), ("A5", 1), ("G5", 1), ("Bb5", 1), ("A5", 3), ("C#5", 1),
    ]
    tr.line(0, lead, square, 0.3, duty=0.25, vib=0.008)
    tr.line(32, lead, square, 0.3, duty=0.25, vib=0.008)
    tr.line(32, [((midi(n) - 12) if n else None, l) for n, l in lead], tri, 0.25)
    drums_rock(tr, bars)
    for bar in range(0, bars, 4):  # timbales al final de cada frase
        for k, f in enumerate([180, 150, 120, 95]):
            tr.add(bar * 4 + 15 - 1 + k * 0.25, np.sin(2 * np.pi * f * _t(0.2)) * np.exp(-_t(0.2) / 0.08), 0.5)
    return tr.buf


def serpent_song(base):
    """Lo de Lilato, pero roto: desafinado, una octava de 'serpiente' abajo y bits de menos."""
    x = warble(base, depth=0.012, rate=0.7)
    n = len(x)
    low = np.interp((np.arange(n) * 0.5) % n, np.arange(n), x, period=n)  # una octava abajo
    x = x * 0.8 + fft_filter(low, hi=500) * 0.7
    levels = 24
    x = np.round(x / np.abs(x).max() * levels) / levels  # bitcrush
    return x + fft_filter(rng.uniform(-1, 1, n), lo=50, hi=200) * 0.15


CUMBIA_CHORDS = [("A", "m"), ("A", "m"), ("G", ""), ("G", ""), ("F", ""), ("F", ""), ("E", ""), ("E", "")] * 2
CUMBIA_MEL = [
    ("E5", 1), ("C5", .5), ("D5", .5), ("E5", 2), (None, 1), ("A4", 1), ("C5", 1), ("E5", 1),
    ("D5", 1.5), ("B4", .5), ("D5", 2), (None, 1), ("G4", 1), ("B4", 1), ("D5", 1),
    ("C5", 1), ("A4", .5), ("C5", .5), ("F5", 2), ("E5", 1), ("D5", 1), ("C5", 1), ("A4", 1),
    ("B4", 2), ("G#4", 1), ("B4", 1), ("E5", 3), (None, 1),
]


def chord_notes(root, q, octave=3):
    r = midi(root + str(octave))
    return [r, r + (3 if q == "m" else 4), r + 7]


def cumbia(bpm, night):
    bars = 16
    tr = Track(bpm, bars * 4)
    for bar, (r, q) in enumerate(CUMBIA_CHORDS):
        b = bar * 4
        root = midi(r + "2")
        third = 3 if q == "m" else 4
        bass = [(0, 0, 1), (2, 7, 1), (3, 0, .5), (3.5, third, .5)]
        for beat, iv, l in bass:
            tr.add(b + beat, pluck(hz(root + iv), tr.sec(l), bright=0.2, decay=0.998), 0.55)
        for off in [0.5, 1.5, 2.5, 3.5]:  # guitarra a contratiempo (el rasgueo hacia arriba)
            for k, m in enumerate(chord_notes(r, q, 4)):
                tr.add(b + off + k * 0.015, pluck(hz(m), tr.sec(0.35), bright=0.35 if night else 0.5), 0.13)
        if not night:
            for k in range(8):  # güira
                tr.add(b + k * 0.5, shaker(), 0.18 if k % 2 else 0.1)
            tr.add(b, kick(soft=True), 0.4)
            tr.add(b + 2, kick(soft=True), 0.3)
        else:
            tr.add(b, kick(soft=True), 0.25)
    mel_gain = 0.5 if not night else 0.42
    shift = 0 if not night else -12
    mel = [((midi(n) + shift) if n else None, l) for n, l in CUMBIA_MEL]
    tr.line(0, mel, pluck, mel_gain, legato=1.0, bright=0.7, decay=0.997)
    tr.line(32, mel, pluck, mel_gain * 0.9, legato=1.0, bright=0.7, decay=0.997)
    x = tr.buf
    x = fft_filter(x, lo=60, hi=1700 if night else 3600)
    x = warble(x, 0.002 if not night else 0.003, 0.4)
    x = x / np.abs(x).max()
    x += crackle(len(x), 8, 0.12)
    if night:
        x += rain(len(x), 0.22)
        n = len(x)
        for center in (0.3, 0.75):  # una moto que pasa lejos
            t = (np.arange(n) / n - center) * n / SR
            amp = np.exp(-(t / 2.0) ** 2)
            f = 70 + 25 * np.tanh(-t)
            moto = (np.cumsum(f) / SR % 1.0) * 2 - 1
            x += fft_filter(moto * amp, hi=400) * 0.35
        x = echo(x)
    return x


def bolero():
    bars = 16
    tr = Track(76, bars * 4)
    chords = [("C", ""), ("A", "m"), ("D", "m"), ("G", "7")] * 4
    for bar, (r, q) in enumerate(chords):
        b = bar * 4
        root = midi(r + "2")
        for beat, iv, l in [(0, 0, 1), (1, 7, .5), (1.5, 7, .5), (2, 0, 1), (3, 7, 1)]:
            tr.add(b + beat, pluck(hz(root + iv), tr.sec(l), bright=0.25, decay=0.998), 0.5)
        tones = chord_notes(r, "m" if q == "m" else "", 3)
        if q == "7":
            tones = tones + [tones[0] + 10]
        arp = [tones[0], tones[1], tones[2], tones[1] + 12, tones[2], tones[1], tones[0] + 12, tones[2]]
        for k, m in enumerate(arp):
            tr.add(b + k * 0.5, pluck(hz(m + 12), tr.sec(0.6), bright=0.45), 0.16)
    mel = [
        ("E5", 1.5), ("D5", .5), ("C5", 1), ("E5", 1), ("A5", 2), ("G5", 1), ("E5", 1),
        ("F5", 1.5), ("E5", .5), ("D5", 1), ("F5", 1), ("G5", 2), ("F5", 1), ("D5", 1),
        ("E5", 1), ("G5", 1), ("C6", 2), ("B5", 1), ("A5", 1), ("E5", 2),
        ("F5", 1), ("A5", 1), ("D5", 1), ("F5", 1), ("E5", 1), ("D5", 1), ("B4", 1), ("G4", 1),
    ]
    tr.line(0, mel, pluck, 0.5, legato=1.0, bright=0.75, decay=0.998)
    tr.line(32, mel, pluck, 0.5, legato=1.0, bright=0.75, decay=0.998)
    for bar in range(bars):  # maracas suaves
        for k in range(4):
            tr.add(bar * 4 + k, shaker(0.09), 0.08)
    return radio(echo(tr.buf))


def vals():
    bars = 16
    tr = Track(108, bars * 3)
    chords = [("G", ""), ("E", "m"), ("C", ""), ("D", "")] * 4
    for bar, (r, q) in enumerate(chords):
        b = bar * 3
        tr.add(b, pluck(hz(midi(r + "2")), tr.sec(1), bright=0.25), 0.5)
        for beat in (1, 2):
            for k, m in enumerate(chord_notes(r, q, 4)):
                tr.add(b + beat + k * 0.012, pluck(hz(m), tr.sec(0.5), bright=0.4), 0.14)
    mel = [
        ("B4", 1), ("D5", 1), ("G5", 1), ("E5", 2), ("D5", 1), ("C5", 1), ("E5", 1), ("G5", 1), ("F#5", 2), ("A5", 1),
        ("G5", 1.5), ("F#5", .5), ("E5", 1), ("D5", 2), ("B4", 1), ("C5", 1), ("A4", 1), ("C5", 1), ("D5", 3),
    ]
    tr.line(0, mel, pluck, 0.5, legato=1.0, bright=0.8)
    tr.line(24, mel, pluck, 0.45, legato=1.0, bright=0.8)
    return radio(echo(tr.buf)) * 0.9


def night_piano():
    bars = 8
    tr = Track(60, bars * 4)
    chords = ["A1", "A1", "F1", "F1", "C2", "C2", "E1", "E1"]
    for bar in range(0, bars, 2):
        tr.add(bar * 4, piano(hz(chords[bar]), tr.sec(8)), 0.5)
        tr.add(bar * 4, piano(hz(midi(chords[bar]) + 12), tr.sec(8)), 0.3)
    notes = [
        (0.5, "E5", 3), (3.5, "C5", 2), (5.5, "B4", 2.5),
        (8.5, "A4", 3), (12, "C5", 1.5), (13.5, "F5", 2.5),
        (16.5, "E5", 2), (19, "G5", 1), (20, "E5", 3.5),
        (24.5, "D5", 2), (27, "B4", 2), (29, "G#4", 3),
    ]
    for beat, n, l in notes:
        tr.add(beat, piano(hz(n), tr.sec(l + 1.5)), 0.42)
    x = echo(echo(tr.buf))
    x = fft_filter(x, hi=5000)
    return x / np.abs(x).max() + rain(len(x), 0.05)


def memory_box():
    bars = 8
    tr = Track(96, bars * 4)
    mel = [
        ("E5", 1), ("G5", 1), ("E5", 1), ("C5", 1), ("D5", 1.5), ("B4", .5), ("G4", 2),
        ("A5", 1), ("G5", 1), ("F5", 1), ("A5", 1), ("G5", 4),
        ("E5", 1), ("C5", 1), ("E5", 1), ("A5", 1), ("G5", 1), ("F5", 1), ("E5", 1), ("D5", 1),
        ("D5", 1), ("E5", 1), ("F5", 1), ("B4", 1), ("C5", 4),
    ]
    b = 0
    for n, l in mel:  # cada nota un poco desafinada, como una cajita vieja
        cents = rng.uniform(-30, 30)
        tr.add(b, musicbox(hz(n) * 2 ** (cents / 1200), tr.sec(l + 1.2)), 0.5)
        b += l
    for bar, r in enumerate(["C4", "G3", "F3", "C4", "A3", "F3", "G3", "C4"]):
        tr.add(bar * 4, musicbox(hz(r), tr.sec(3.5)), 0.3)
    x = warble(echo(tr.buf), 0.004, 0.3)
    return x + crackle(len(x), 5, 0.06)


def flashback_song():
    """El recuerdo de la moto: la cumbia de la ciudad, pero en mayor, más rápida y con sol."""
    bars = 16
    tr = Track(100, bars * 4)
    chords = [("C", ""), ("C", ""), ("A", "m"), ("A", "m"), ("F", ""), ("F", ""), ("G", ""), ("G", "")] * 2
    for bar, (r, q) in enumerate(chords):
        b = bar * 4
        root = midi(r + "2")
        third = 3 if q == "m" else 4
        for beat, iv, l in [(0, 0, 1), (2, 7, 1), (3, 0, .5), (3.5, third, .5)]:
            tr.add(b + beat, pluck(hz(root + iv), tr.sec(l), bright=0.3, decay=0.998), 0.55)
        for off in [0.5, 1.5, 2.5, 3.5]:
            for k, m in enumerate(chord_notes(r, q, 4)):
                tr.add(b + off + k * 0.015, pluck(hz(m), tr.sec(0.3), bright=0.6), 0.13)
        for k in range(8):
            tr.add(b + k * 0.5, shaker(), 0.2 if k % 2 else 0.1)
        tr.add(b, kick(soft=True), 0.45)
        tr.add(b + 2, kick(soft=True), 0.35)
    mel = [
        ("E5", 1), ("G5", .5), ("A5", .5), ("G5", 2), (None, 1), ("C5", 1), ("E5", 1), ("G5", 1),
        ("A5", 1.5), ("G5", .5), ("E5", 2), (None, 1), ("A4", 1), ("C5", 1), ("E5", 1),
        ("F5", 1), ("A5", .5), ("G5", .5), ("F5", 2), ("E5", 1), ("D5", 1), ("C5", 1), ("A4", 1),
        ("B4", 2), ("D5", 1), ("G5", 1), ("G5", 3), (None, 1),
    ]
    tr.line(0, mel, pluck, 0.5, legato=1.0, bright=0.8, decay=0.997)
    tr.line(32, mel, pluck, 0.45, legato=1.0, bright=0.8, decay=0.997)
    x = fft_filter(tr.buf, lo=60, hi=5000)
    return warble(x, 0.0015, 0.4)


def ride_song():
    """La ruta: rock chiptune en re mayor, para ir con el viento en la cara."""
    bars = 16
    tr = Track(156, bars * 4)
    chords = ["D", "D", "A", "A", "B", "B", "G", "A"] * 2
    minor = {"B"}
    for bar, ch in enumerate(chords):
        root = midi(ch + "2")
        for k, iv in enumerate([0, 0, 12, 0, 7, 0, 12, 7]):
            tr.add(bar * 4 + k * 0.5, tri(hz(root + iv), tr.sec(0.45)), 0.55)
        third = 3 if ch in minor else 4
        for k in range(8):
            iv = [0, 7, 12, third + 12][k % 4]
            tr.add(bar * 4 + k * 0.5, square(hz(root + 24 + iv), tr.sec(0.18), 0.125, decay=0.05), 0.09)
    lead = [
        ("F#5", 1), ("A5", 1), ("D6", 1.5), ("C#6", .5), ("B5", 1), ("A5", 1), ("F#5", 2),
        ("E5", 1), ("F#5", 1), ("A5", 2), ("C#6", 1), ("B5", 1), ("A5", 1), ("E5", 1),
        ("D5", 1), ("F#5", 1), ("B5", 2), ("A5", 1), ("F#5", 1), ("D5", 2),
        ("G5", 1), ("B5", 1), ("D6", 2), ("C#6", 2), ("E6", 2),
    ]
    tr.line(0, lead, square, 0.3, duty=0.25, vib=0.005)
    tr.line(32, lead, square, 0.28, duty=0.25, vib=0.005)
    tr.line(32, [((midi(n) - 3) if n else None, l) for n, l in lead], square, 0.12, duty=0.125)
    drums_rock(tr, bars, double_kick=True)
    return tr.buf


def outlaw_song():
    """La moto (el recuerdo de la Renegade): blues-rock de motero, de los de Harley. Shuffle en mi,
    doce compases, guitarra saturada haciendo el boogie (quinta-sexta), bajo pesado, guitarra con
    slide arriba y una batería que pisa fuerte. Para ir tarde y apurado."""
    bpm = 112
    form = ["E", "E", "E", "E", "A", "A", "E", "E", "B", "A", "E", "B"]
    bars = len(form) * 2
    tr = Track(bpm, bars * 4)
    gtr = Track(bpm, bars * 4)
    sw = 2.0 / 3.0  # el swing: la segunda corchea cae en el tercio
    for bar in range(bars):
        ch = form[bar % len(form)]
        root = midi(ch + "2")
        b = bar * 4
        # El boogie: quinta, sexta, quinta, séptima (la de siempre), en shuffle.
        for beat, top in enumerate([7, 9, 7, 10]):
            for k, off in enumerate((0.0, sw)):
                t = b + beat + off
                gain = 0.55 if k == 0 else 0.4
                gtr.add(t, pluck(hz(root + 12), gtr.sec(0.5), bright=0.85, decay=0.997), gain)
                gtr.add(t, pluck(hz(root + 12 + top), gtr.sec(0.5), bright=0.85, decay=0.997), gain * 0.8)
            tr.add(b + beat, tri(hz(root), tr.sec(0.62)), 0.6)  # el bajo, en negras
        # Batería: bombo en 1 y 3 (y el empujón antes del 3), redoblante en 2 y 4, hi-hat en shuffle.
        for k in (0, 2, 2 - (1 - sw)):
            tr.add(b + k, kick(0.28), 0.95)
        for k in (1, 3):
            tr.add(b + k, snare(0.22), 0.7)
        for beat in range(4):
            tr.add(b + beat, hat(), 0.22)
            tr.add(b + beat + sw, hat(open_=(beat == 3)), 0.16)
        if bar % len(form) == len(form) - 1:  # el remate antes de volver
            for k in (3, 3 + sw / 2, 3 + sw):
                tr.add(b + k, snare(0.15), 0.45)
    # La guitarra con slide: entra en la segunda vuelta, lamentándose. Pentatónica de mi con blue note.
    slide = [
        ("B4", 1.5), ("D5", .5), ("E5", 2), (None, 2), ("G5", 1), ("E5", .5), ("D5", .5), ("E5", 4),
        (None, 2), ("A5", 1.5), ("G5", .5), ("E5", 2), ("G5", 1), ("Bb4", .5), ("B4", .5), ("E5", 2), (None, 2),
        ("B5", 2), ("A5", 1), ("G5", 1), ("E5", 1), ("D5", 1), ("E5", 4), (None, 2),
        ("D5", .67), ("E5", .33), ("G5", 1), ("E5", 6),
    ]
    tr.line(len(form) * 4, slide, square, 0.22, duty=0.3, vib=0.018)
    tr.line(len(form) * 4, slide, pluck, 0.25, bright=0.95, decay=0.998)
    g = gtr.buf / (np.abs(gtr.buf).max() + 1e-9)
    g = np.tanh(g * 5.0) * 0.55  # la saturación del amplificador
    g = fft_filter(g, lo=70, hi=3200)
    return tr.buf + g


def engine():
    """El motor (un cilindro, 180 cc): loop corto; el juego le cambia el tono con la velocidad."""
    n = int(SR * 1.0)
    t = np.arange(n) / SR
    f = 48.0  # explosiones por segundo en ralentí acelerado (el loop cierra justo en 1 s)
    pulse = np.zeros(n)
    period = int(SR / f)
    for i in range(0, n, period):
        k = np.arange(min(period, n - i))
        pulse[i:i + len(k)] += np.exp(-k / (period * 0.18)) * (1 + 0.15 * rng.uniform(-1, 1))
    saw = (t * f * 2) % 1.0 * 2 - 1
    x = fft_filter(pulse * 0.8 + saw * 0.25 + rng.uniform(-1, 1, n) * 0.05, lo=40, hi=900)
    return x


def metal(bpm, chords, lead, heavy):
    """Metal de 16 bits (el de los shooters de los 90): riff de cuadradas saturadas, doble bombo."""
    bars = len(chords)
    tr = Track(bpm, bars * 4)
    for bar, ch in enumerate(chords):
        root = midi(ch + "2")
        riff = [0, 0, 12, 0, 0, 10, 0, 7] if not heavy else [0, 0, 0, 1, 0, 0, 6, 5]
        for k, iv in enumerate(riff):
            for detune in (0.0, 0.08):  # dos guitarras apenas desafinadas = distorsión barata
                tr.add(bar * 4 + k * 0.5, square(hz(root + iv) * 2 ** (detune / 12), tr.sec(0.42), 0.5, decay=0.2), 0.2)
            tr.add(bar * 4 + k * 0.5, square(hz(root + iv + 7) , tr.sec(0.42), 0.5, decay=0.2), 0.08)
            tr.add(bar * 4 + k * 0.5, tri(hz(root + iv - 12), tr.sec(0.45)), 0.35)
    tr.line(0, lead, square, 0.26, duty=0.25, vib=0.01)
    drums_rock(tr, bars, fill_every=4, double_kick=True)
    x = np.tanh(tr.buf * 1.8)
    return x


PLOMO_LEAD = [
    ("E5", .5), ("G5", .5), ("A5", .5), ("B5", 1.5), ("A5", 1), ("G5", 2), ("E5", 2),
    ("D5", .5), ("E5", .5), ("G5", 1), ("F#5", 2), ("D5", 4),
    ("E5", .5), ("G5", .5), ("A5", .5), ("B5", 1.5), ("D6", 1), ("B5", 2), ("A5", 2),
    ("G5", 1), ("F#5", 1), ("E5", 2), ("B4", 4),
]
BOSS_LEAD = [
    ("C5", 1.5), ("Eb5", .5), ("G5", 2), ("F#5", 2), ("F5", 2),
    ("Eb5", 1), ("D5", 1), ("C5", 2), ("G4", 4),
    ("C5", 1.5), ("Eb5", .5), ("Ab5", 2), ("G5", 2), ("F5", 2),
    ("Eb5", 1), ("F5", 1), ("D5", 2), ("C5", 4),
]


BOX_LEAD = [
    ("A4", 1), ("C5", .5), ("E5", .5), ("A5", 2), ("G5", 1), ("E5", 1), ("C5", 2),
    ("F5", 1), ("E5", 1), ("C5", 1), ("A4", 1), ("B4", 2), ("E5", 2),
    ("A4", 1), ("C5", .5), ("E5", .5), ("A5", 2), ("C6", 1), ("B5", 1), ("A5", 2),
    ("G5", 1), ("F5", 1), ("E5", 1), ("D5", 1), ("E5", 4),
]


if __name__ == "__main__":
    save("boxeo", metal(150, ["A", "A", "F", "G"] * 4, BOX_LEAD, False))
    save("plomo", metal(168, ["E", "E", "C", "D"] * 4, PLOMO_LEAD, False))
    save("plomo_boss", metal(132, ["C", "C", "Ab", "G"] * 4, BOSS_LEAD, True))
    save("flashback", flashback_song())
    save("moto_ride", outlaw_song())
    save("engine", engine(), peak=0.6)
    save("dream_fight", fight_song(140, False))
    save("truck", fight_song(170, True))
    base = lilato_song()
    save("lilato", base)
    save("lilato_serpent", serpent_song(base))
    save("city_day", cumbia(92, False))
    save("city_night", cumbia(70, True))
    save("bakery", bolero())
    save("cafe", vals())
    save("night", night_piano())
    save("memory", memory_box())
