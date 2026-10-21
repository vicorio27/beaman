"""Música de los sueños (y de la moto, el prólogo y la memoria), generada por código
(python tools/audio/compose.py). La de la vida real (el barrio, las radios, la noche, la feria) la
hace tools/audio/barrio.py.

Un mini sintetizador con numpy: ondas cuadradas y triangulares (chiptune), guitarra pulsada
(Karplus-Strong), piano, cajita de música y batería.
Cada tema es un loop: las colas de las notas que pasan el final vuelven al principio,
así el loop empalma sin corte. Salida: assets/music/<id>.wav (22050 Hz, mono, 16 bits).

Temas (ver docs/DISENO_CIUDAD_Y_SISTEMAS.md, "Música"):
  dream_fight     sueño, beat 'em up: chiptune rockero (Streets of Rage)
  truck           el camión: el mismo riff, más rápido y desesperado
  lilato          jefe: épica en re menor
  lilato_serpent  la serpiente: el tema de Lilato que se desafina y se rompe
  memory          la memoria: cajita de música desafinada
  moto_ride       la moto: blues-rock de motero (shuffle en mi, guitarra saturada, slide)
  panico          el prólogo, antes de correr: un corazón, un reloj, un tritono y una sirena lejos.
                  El juego lo va acelerando con cada texto (Huida.gd le sube el pitch).
  huida           el prólogo, corriendo: metal en mi frigio a 184, con la sirena encima

Solo los del prólogo:  python tools/audio/compose.py prologo
"""
import os
import sys
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


def loop_tone(f, n):
    """Un tono seguido (triangular) que cierra el loop: la frecuencia se ajusta a ciclos enteros."""
    cycles = max(1, round(f * n / SR))
    ph = (np.arange(n) * cycles / n) % 1.0
    return 2 * np.abs(2 * ph - 1) - 1


def panic_loop():
    """El miedo antes de correr. A 100: el juego lo lleva de 0.8 a 1.45 de velocidad."""
    bars = 8
    heart, ticks, stabs = Track(100, bars * 4), Track(100, bars * 4), Track(100, bars * 4)
    for b in range(bars * 4):
        heart.add(b, kick(0.3, soft=True), 1.0)       # lub
        heart.add(b + 0.32, kick(0.25, soft=True), 0.7)  # dub
        ticks.add(b, hat(0.03), 0.5)                  # el reloj de la cocina
        ticks.add(b + 0.5, hat(0.03), 1.0)
    for b in (0, 16):
        for note in ("E2", "F2"):
            stabs.add(b, piano(hz(note), 3.0), 0.5)
    n = len(heart.buf)
    t = np.arange(n) / n
    drone = loop_tone(hz("E2"), n) * (0.7 + 0.3 * np.sin(2 * np.pi * 96 * t)) \
        + 0.4 * loop_tone(hz("E3"), n)
    tritone = loop_tone(hz("Bb2"), n) * np.sin(np.pi * 2 * t) ** 2
    cluster = (loop_tone(hz("E5"), n) + loop_tone(hz("F5"), n)) \
        * (0.5 + 0.5 * np.sin(2 * np.pi * 224 * t)) * np.sin(np.pi * t) ** 4
    f = 780 + 160 * np.sin(2 * np.pi * 8 * t)
    siren = fft_filter(echo(np.sin(2 * np.pi * np.cumsum(f) / SR)), hi=1600) * np.sin(np.pi * t) ** 2
    return fft_filter(heart.buf, hi=900) * 1.0 + ticks.buf * 0.09 + stabs.buf * 0.5 \
        + drone * 0.16 + tritone * 0.13 + cluster * 0.045 + siren * 0.05


CHASE_A = [("E5", .5), ("F5", .5), ("E5", .5), ("B5", .5), ("E5", .5), ("F5", .5), ("G5", .5), ("F5", .5),
           ("E5", .5), ("F5", .5), ("E5", .5), ("Bb5", .5), ("A5", .5), ("G5", .5), ("F5", .5), ("E5", .5)]
CHASE_B = [("B5", 2), ("Bb5", 2), ("B5", 1), ("C6", 1), ("Bb5", 2)]


def chase_song():
    """La huida: mi frigio, doble bombo, y una sirena que sube y baja encima de todo."""
    x = metal(184, ["E", "E", "F", "E", "E", "E", "G", "F"] * 2, (CHASE_A + CHASE_B) * 4, True)
    n = len(x)
    t = np.arange(n) / n
    f = 820 + 190 * np.sin(2 * np.pi * 16 * t)
    siren = echo(np.sin(2 * np.pi * np.cumsum(f) / SR)) * np.sin(np.pi * t) ** 2
    return x + siren * 0.09


PERROS_CHORDS = ["A", "A", "F", "G", "A", "A", "Bb", "E"] * 2
PERROS_A = [
    ("A5", .5), ("E5", .5), ("A5", .5), ("C6", .5), ("B5", 1), ("A5", .5), ("G5", .5),
    ("A5", 1.5), ("E5", .5), ("G5", 1), ("A5", 1),
    ("F5", .5), ("A5", .5), ("C6", .5), ("F6", .5), ("E6", 1), ("D6", .5), ("C6", .5),
    ("D6", 1), ("B5", 1), ("G5", 1), ("B5", 1),
    ("A5", .5), ("E5", .5), ("A5", .5), ("C6", .5), ("E6", 1), ("D6", .5), ("C6", .5),
    ("B5", 1.5), ("C6", .5), ("A5", 2),
    ("Bb5", .5), ("F5", .5), ("Bb5", .5), ("D6", .5), ("C6", 1), ("Bb5", 1),
    ("G#5", .5), ("B5", .5), ("E6", .5), ("G#5", .5), ("B5", 2),
]
PERROS_B_END = [("E6", 2), ("D6", 2), ("C6", 2), ("B5", 2), ("C6", 2), ("D6", 2), ("E6", 3), ("G#5", 1)]


def perros_song():
    """Lukas contra un perro de la calle: la pelea por turnos, como en los juegos de bolsillo. La menor,
    rápida: el bajo salta de octava en corcheas, la melodía en cuadrada fina, y en la segunda parte los
    arpegios en semicorcheas antes de la frase larga que sube."""
    bars = 16
    tr = Track(156, bars * 4)
    for bar, ch in enumerate(PERROS_CHORDS):
        root = midi(ch + "2")
        minor = ch in ("A",)
        third = 3 if minor else 4
        for k in range(8):
            iv = [0, 12][k % 2]
            tr.add(bar * 4 + k * 0.5, tri(hz(root + iv), tr.sec(0.42)), 0.6)
        if bar >= 8 and bar < 12:  # los arpegios
            for k in range(16):
                iv = [0, third, 7, 12, 7, third][k % 6]
                tr.add(bar * 4 + k * 0.25, square(hz(root + 36 + iv), tr.sec(0.2), 0.125, decay=0.06), 0.16)
        else:
            for k in range(4):  # el colchón: el acorde en negras, cortito
                for iv in (0, third, 7):
                    tr.add(bar * 4 + k + 0.5, square(hz(root + 24 + iv), tr.sec(0.18), 0.25, decay=0.08), 0.05)
    tr.line(0, PERROS_A, square, 0.3, duty=0.25, vib=0.003)
    tr.line(48, PERROS_B_END, square, 0.3, duty=0.25, vib=0.006)
    harm = [((midi(n) - 3) if n else None, l) for n, l in PERROS_B_END]
    tr.line(48, harm, square, 0.12, duty=0.125)
    for bar in range(bars):  # la batería de 8 bits: bombo, caja y platillo cerrado
        b = bar * 4
        for k in (0, 1.5, 2, 3.5) if bar % 4 == 3 else (0, 2, 2.5):
            tr.add(b + k, kick(), 0.8)
        tr.add(b + 1, snare(), 0.5)
        tr.add(b + 3, snare(), 0.5)
        if bar % 8 == 7:
            for k in (3.25, 3.5, 3.75):
                tr.add(b + k, snare(), 0.4)
        for h in np.arange(0, 4, 0.5):
            tr.add(b + h, hat(), 0.2)
    return tr.buf


if __name__ == "__main__":
    if "perros" in sys.argv:  # Lukas pelea con un perro de la calle
        save("perros", perros_song())
        sys.exit()
    if "prologo" in sys.argv:
        save("panico", panic_loop(), peak=0.8)
        save("huida", chase_song())
        sys.exit()
    save("boxeo", metal(150, ["A", "A", "F", "G"] * 4, BOX_LEAD, False))
    save("plomo", metal(168, ["E", "E", "C", "D"] * 4, PLOMO_LEAD, False))
    save("plomo_boss", metal(132, ["C", "C", "Ab", "G"] * 4, BOSS_LEAD, True))
    save("moto_ride", outlaw_song())
    save("engine", engine(), peak=0.6)
    save("dream_fight", fight_song(140, False))
    save("truck", fight_song(170, True))
    base = lilato_song()
    save("lilato", base)
    save("lilato_serpent", serpent_song(base))
    save("perros", perros_song())
    save("memory", memory_box())
    save("panico", panic_loop(), peak=0.8)
    save("huida", chase_song())
