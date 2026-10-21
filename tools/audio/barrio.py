"""La música de la vida real:  python -X utf8 tools/audio/barrio.py [tema ...]

Lo del barrio suena horas, así que tiene que dar gusto oírlo muchas veces:
- temas largos (de uno a dos minutos) con partes A y B, y cada vuelta arreglada distinto;
- acordes con séptima y novena, y voces que se mueven lo menos posible de un acorde al otro;
- instrumentos suaves, hechos con síntesis aditiva y FM: marimba de chonta, guitarra de nylon, piano
  eléctrico, vibráfono, piano, contrabajo y tiple; la percusión, bajita;
- una reverb de sala por convolución circular (la cola vuelve al principio y el loop empalma solo);
- nada de ruido de disco, ni cinta que se desafina, ni saturación.
Estéreo a 22050 Hz. Las radios de la panadería y del café van en mono: son una radio.

Temas (el del barrio cambia con la hora: MusicDirector.barrio()):
  barrio_manana  de 6 a 10    marimba y guitarra en re mayor, con pájaros
  barrio_dia     de 10 a 14   cumbia suave en sol: requinto, marimba y piano eléctrico
  barrio_tarde   de 14 a 18   bossa en fa: piano eléctrico, vibráfono y escobillas
  barrio_noche   de 18 a 6    guitarra en 12/8, piano eléctrico y grillos, en mi
  night          el título, la noche, el final: el tema del juego, piano solo
  bakery         lo de Germán y el billar: un bolero de trío, en la radio
  cafe           lo de Marta y la fila: un vals con tiple, en la radio
  feria          la feria: la cumbia del mediodía, de fiesta
  flashback      los recuerdos con sol, la fuente y los juegos: la mañana, con más sol

  python -X utf8 tools/audio/barrio.py --revisar   solo revisa melodías contra acordes (no genera)
"""
import itertools
import os
import sys
import wave
from fractions import Fraction

import numpy as np

SR = 22050
NYQ = SR / 2
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "music")
rng = np.random.default_rng(11)

NOTE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
ACC = {"#": 1, "b": -1}


def midi(n):
    if not isinstance(n, str):
        return n
    k = 2 if len(n) > 2 and n[1] in ACC else 1
    return 12 * (int(n[k:]) + 1) + NOTE[n[0]] + (ACC[n[1]] if k == 2 else 0)


def hz(m):
    return 440.0 * 2 ** ((midi(m) - 69) / 12)


def seq(text, bar=4):
    """'A4:.5 D5:.5 F#5 | E5:2 -:2' -> [(midi o None, tiempos)]. Sin duración es un tiempo; '-' es
    silencio; '|' separa compases y se revisa que cada uno sume lo que debe."""
    out = []
    for k, chunk in enumerate(text.split("|")):
        tot = Fraction(0)
        for tok in chunk.split():
            name, _, length = tok.partition(":")
            d = Fraction(length) if length else Fraction(1)
            tot += d
            out.append((None if name == "-" else midi(name), float(d)))
        assert tot == bar, f"compás {k + 1} suma {tot} y no {bar}: {chunk.strip()}"
    return out


# ------------------------------------------------------------------ acordes

QUAL = {"": (0, 4, 7), "m": (0, 3, 7), "7": (0, 4, 7, 10), "maj7": (0, 4, 7, 11), "m7": (0, 3, 7, 10),
        "6": (0, 4, 7, 9), "m6": (0, 3, 7, 9), "maj9": (0, 4, 7, 11, 14), "m9": (0, 3, 7, 10, 14),
        "add9": (0, 4, 7, 14), "sus4": (0, 5, 7), "7sus4": (0, 5, 7, 10), "7b9": (0, 4, 7, 10, 13)}


def _pc(name):
    return (NOTE[name[0]] + (ACC[name[1]] if len(name) > 1 else 0)) % 12


class Chord:
    def __init__(self, name, start, beats):
        head, _, slash = name.partition("/")
        k = 2 if len(head) > 1 and head[1] in ACC else 1
        self.name, self.start, self.beats = name, start, beats
        self.root = _pc(head[:k])
        self.iv = QUAL[head[k:]]
        self.bass = _pc(slash) if slash else self.root
        self.pcs = {(self.root + i) % 12 for i in self.iv}

    def has(self, iv):
        return iv in self.iv


def chart(text, bar=4, start=0.0):
    """'Dmaj7 | F#m7 B7' -> [Chord]. Cada '|' es un compás; dos acordes en uno se lo reparten."""
    out, b = [], start
    for chunk in text.split("|"):
        names = chunk.split()
        for nm in names:
            out.append(Chord(nm, b, bar / len(names)))
            b += bar / len(names)
    return out


def form(parts, bar=4):
    """[(nombre, acordes, ...)] -> [(nombre, inicio, [Chord], ...)], total de tiempos."""
    out, b = [], 0.0
    for name, text, *rest in parts:
        out.append((name, b, chart(text, bar, b), *rest))
        b += len(text.split("|")) * bar
    return out, b


def tones(ch, n):
    """Las n notas que se tocan del acorde: si sobran, primero sale la fundamental (la pone el bajo)
    y después la quinta; si faltan, se dobla la fundamental."""
    iv = list(ch.iv)
    if len(iv) > n and 0 in iv:
        iv.remove(0)
    while len(iv) > n:
        iv.remove(7) if 7 in iv else iv.pop()
    while len(iv) < n:
        iv.append(iv[0] + 12)
    return [ch.root + i for i in iv]


def voicing(pcs, prev, lo, hi):
    """Pone las notas entre lo y hi moviéndose lo menos posible desde el acorde anterior."""
    opts = [[m for m in range(lo, hi + 1) if m % 12 == p % 12] for p in pcs]
    best, cost = None, 1e9
    for spread in (15, 19, 24):
        for combo in itertools.product(*opts):
            s = sorted(combo)
            if len(set(s)) < len(s) or s[-1] - s[0] > spread:
                continue
            c = sum(abs(a - b) for a, b in zip(s, prev)) if prev and len(prev) == len(s) else 0.0
            c += 0.35 * abs(np.mean(s) - (lo + hi) / 2)  # que no se vaya corriendo para un lado
            for a, b in zip(s, s[1:]):
                c += 4.0 if b - a == 1 else (2.0 if b - a == 2 and a < 56 else 0.0)  # segundas: barro
            if c < cost:
                best, cost = s, c
        if best:
            return best
    return sorted(o[0] for o in opts)


def low_note(pc, prev, lo=33, hi=47):
    """La nota del bajo con esa clase, la más cercana a la anterior."""
    cands = [m for m in range(lo, hi + 1) if m % 12 == pc]
    return min(cands, key=lambda m: abs(m - (prev if prev else (lo + hi) / 2)))


def third_below(m, scale):
    """La voz de abajo de un dúo: una tercera de la escala más abajo."""
    for k in range(3, 5):
        if (m - k) % 12 in scale and (m % 12 in scale or k == 4):
            return m - k
    return m - 3


def scale(root, minor=False):
    return {(root + i) % 12 for i in ((0, 2, 3, 5, 7, 8, 10) if minor else (0, 2, 4, 5, 7, 9, 11))}


# ------------------------------------------------------------------ instrumentos

def _t(sec):
    return np.arange(max(2, int(sec * SR))) / SR


def _env(n, att, hold, rel):
    """Sube en att, se sostiene hasta hold y se apaga hasta el final (n): curvas suaves, sin clic."""
    e = np.ones(n)
    na = min(n, max(2, int(att * SR)))
    e[:na] = np.sin(np.linspace(0, np.pi / 2, na)) ** 2
    h = int(hold * SR)
    if h < n:
        e[h:] *= np.cos(np.linspace(0, np.pi / 2, n - h)) ** 2
    return e


def _click(n, gain):
    """El golpecito del ataque (uña, mazo, martillo): ruido corto y opaco."""
    x = np.convolve(rng.uniform(-1, 1, n), np.ones(5) / 5, "same")
    return x * np.linspace(1, 0, n) ** 2 * gain


def _band(n, lo, hi):
    X = np.fft.rfft(rng.uniform(-1, 1, n))
    f = np.fft.rfftfreq(n, 1 / SR)
    X[(f < lo) | (f > hi)] = 0
    y = np.fft.irfft(X, n)
    return y / (np.abs(y).max() + 1e-9)


def nylon(f, dur, vel=0.6, pos=0.18, ring=1.0, rel=0.08):
    """Guitarra de nylon: armónicos que se apagan más rápido cuanto más agudos; la posición de la
    mano (pos) quita los que tienen un nodo ahí. Con poca fuerza, menos brillo."""
    t = _t(dur + rel)
    s = np.zeros_like(t)
    tau1 = float(np.clip(2.6 * (110 / f) ** 0.55, 0.45, 3.2)) * ring
    roll = 0.34 - 0.2 * vel
    for k in range(1, 20):
        fk = f * k * (1 + 0.00004 * k * k)
        if fk > NYQ * 0.8:
            break
        a = abs(np.sin(np.pi * k * pos)) / k ** 1.15 * np.exp(-(k - 1) * roll)
        tk = tau1 / (1 + 0.10 * (k - 1) ** 1.35)
        s += a * np.sin(2 * np.pi * fk * t + rng.uniform(0, 2 * np.pi)) * np.exp(-t / tk)
    n = min(len(t), int(0.005 * SR))
    s[:n] += _click(n, 0.12 * vel)
    return s * vel * _env(len(t), 0.0015, dur, rel)


def tiple(f, dur, vel=0.6):
    """El tiple: cuerdas de metal en grupos de tres (la del medio, una octava abajo), así que suena
    a coro brillante."""
    s = nylon(f, dur, vel, pos=0.11, ring=0.6)
    s2 = nylon(f * 1.0021, dur, vel * 0.8, pos=0.11, ring=0.6)
    s3 = nylon(f / 2 if f > 300 else f * 2, dur, vel * 0.5, pos=0.13, ring=0.6)
    n = min(len(s), len(s2), len(s3))
    return s[:n] + s2[:n] + s3[:n]


def marimba(f, dur=0.0, vel=0.6):
    """Marimba de chonta: la tabla, su sobretono afinado casi al cuádruple, otro más arriba y el mazo.
    Las notas graves suenan más; dur no importa (la tabla suena lo que suena)."""
    tau = float(np.clip(0.5 * (440 / f) ** 0.75, 0.16, 1.3))
    t = _t(tau * 4.5)
    w = 2 * np.pi * f * t
    s = np.sin(w) * np.exp(-t / tau)
    if 3.93 * f < NYQ * 0.85:
        s += (0.08 + 0.22 * vel) * np.sin(3.93 * w + 0.4) * np.exp(-t / (tau * 0.22))
    if 9.2 * f < NYQ * 0.85:
        s += 0.07 * vel * np.sin(9.2 * w + 1.1) * np.exp(-t / (tau * 0.08))
    n = int(0.004 * SR)
    s[:n] += _click(n, 0.22 * vel)
    return s * vel * _env(len(t), 0.001, len(t) / SR - 0.03, 0.03)


def marimba_roll(f, dur, vel=0.6, rate=12.5):
    """Las notas largas en la marimba: el redoble (los dos mazos alternando)."""
    n = int((dur + 1.0) * SR)
    out = np.zeros(n)
    t, k = 0.0, 0
    while t < dur - 0.05:
        shape = 0.8 + 0.2 * np.sin(np.pi * min(1.0, t / max(dur, 0.1)))
        hit = marimba(f, 0, vel * 0.42 * shape * (0.88 if k % 2 else 1.0))
        i = int(t * SR)
        m = min(len(hit), n - i)
        out[i:i + m] += hit[:m]
        t += (1 + rng.uniform(-0.07, 0.07)) / rate
        k += 1
    return out


def vibes(f, dur, vel=0.6, rel=0.45):
    """Vibráfono: la barra de metal (1, 4 y 10) suena larga; el motor lo pone la mezcla (trémolo)."""
    tau = float(np.clip(4.0 * (330 / f) ** 0.5, 1.5, 6.0))
    t = _t(dur + rel)
    w = 2 * np.pi * f * t
    s = np.sin(w) * np.exp(-t / tau)
    if 4 * f < NYQ * 0.85:
        s += 0.13 * vel * np.sin(4 * w) * np.exp(-t / 0.3)
    if 10 * f < NYQ * 0.85:
        s += 0.05 * vel * np.sin(10 * w) * np.exp(-t / 0.05)
    n = int(0.003 * SR)
    s[:n] += _click(n, 0.10 * vel)
    return s * vel * _env(len(t), 0.002, dur, rel)


def rhodes(f, dur, vel=0.5, rel=0.22):
    """Piano eléctrico (FM 1:1): el golpe brilla un instante y queda un tono redondo. Con más fuerza,
    más 'ladrido'."""
    t = _t(dur + rel)
    w = 2 * np.pi * f * t
    idx = (0.35 + 1.7 * vel) * np.exp(-t / 0.22) + 0.3 * vel
    s = np.sin(w + idx * np.sin(w))
    if f * 14 < NYQ * 0.85:
        s += 0.09 * vel * np.sin(14 * w) * np.exp(-t / 0.012)  # la lengüeta, al golpe
    tau = float(np.clip(2.4 * (220 / f) ** 0.4, 0.9, 4.0))
    s *= 0.7 * np.exp(-t / tau) + 0.3 * np.exp(-t / 0.25)
    return s * vel * _env(len(t), 0.003, dur, rel)


def piano(f, dur, vel=0.5, rel=0.35):
    """Piano: armónicos un poquito estirados, dos caídas (el golpe y lo que queda), el martillo a un
    séptimo de la cuerda y dos cuerdas casi afinadas que se mecen."""
    t = _t(dur + rel)
    s = np.zeros_like(t)
    slow = float(np.clip(7.0 * (130 / f) ** 0.7, 1.2, 12.0))
    for k in range(1, 16):
        fk = f * k * np.sqrt(1 + 0.0001 * k * k)
        if fk > NYQ * 0.8:
            break
        a = (0.15 + abs(np.sin(np.pi * k / 7.3))) / k ** (1.9 - 0.9 * vel)
        e = 0.55 * np.exp(-t / (0.35 / (1 + 0.25 * k))) + 0.45 * np.exp(-t / (slow / (1 + 0.18 * (k - 1))))
        ph = rng.uniform(0, 2 * np.pi)
        if k <= 4:
            s += a * e * 0.5 * (np.sin(2 * np.pi * fk * t + ph) + np.sin(2 * np.pi * fk * 1.00045 * t + ph))
        else:
            s += a * e * np.sin(2 * np.pi * fk * t + ph)
    n = int(0.004 * SR)
    s[:n] += _click(n, 0.04 * vel)
    return s * vel * _env(len(t), 0.002, dur, rel)


def bass(f, dur, vel=0.7, rel=0.07):
    """Contrabajo pulsado: redondo, con el golpecito del dedo (la nota arranca un pelo arriba)."""
    t = _t(dur + rel)
    ph = 2 * np.pi * np.cumsum(f * (1 + 0.012 * np.exp(-t / 0.025))) / SR
    s = np.zeros_like(t)
    for k, a in enumerate((1.0, 0.55, 0.28, 0.14, 0.07, 0.035), 1):
        if k * f > 1800:
            break
        s += a * np.sin(k * ph) * np.exp(-t / (1.6 / (1 + 0.7 * (k - 1))))
    return s * vel * _env(len(t), 0.006, dur, rel)


def pad(f, dur, vel=0.5, att=0.9, rel=1.4):
    """Cuerdas de fondo, muy suaves: tres voces apenas desafinadas que entran despacio."""
    t = _t(dur + rel)
    s = np.zeros_like(t)
    for cents in (-7, 0, 7):
        fd = f * 2 ** (cents / 1200)
        for k in range(1, 7):
            if fd * k > 4500:
                break
            s += np.sin(2 * np.pi * fd * k * t + rng.uniform(0, 2 * np.pi)) / k ** 1.6
    return s / 3 * vel * _env(len(t), att, dur, rel)


# percusión (todo bajito: acompaña, no manda)

def shaker(vel=0.5, d=0.11):
    t = _t(d)
    return _band(len(t), 3000, 8500) * (1 - np.exp(-t / 0.012)) * np.exp(-t / 0.035) * vel


def maracas(vel=0.5):
    return shaker(vel, 0.08)


def guacharaca(vel=0.5, long=True):
    """El raspador de la cumbia: largo en el tiempo, corto a contratiempo."""
    d = 0.17 if long else 0.07
    t = _t(d)
    teeth = (0.5 + 0.5 * np.sin(2 * np.pi * 92 * t)) ** 2
    e = np.sin(np.pi * t / d) ** 0.8 if long else np.exp(-t / 0.02)
    return _band(len(t), 1800, 6500) * (0.4 + 0.6 * teeth) * e * vel


def drum(f, vel=0.5, tau=0.16, slap=0.0, d=0.4):
    """Tambor de mano (conga, llamador, bongó, tambora): tono que baja un pelo, y la palmada."""
    t = _t(d)
    ph = 2 * np.pi * np.cumsum(f * (1 + 0.08 * np.exp(-t / 0.01))) / SR
    s = np.sin(ph) * np.exp(-t / tau) + 0.3 * np.sin(1.5 * ph) * np.exp(-t / (tau * 0.4))
    if slap:
        s += _band(len(t), 900, 5000) * np.exp(-t / 0.018) * slap
    return s * vel * _env(len(t), 0.001, d - 0.02, 0.02)


def kick(vel=0.5):
    t = _t(0.35)
    ph = 2 * np.pi * np.cumsum(62 + 60 * np.exp(-t / 0.03)) / SR
    return np.sin(ph) * np.exp(-t / 0.15) * vel


def rim(vel=0.5):
    """El aro (la clave de la bossa): seco y de madera."""
    t = _t(0.08)
    s = 0.6 * np.sin(2 * np.pi * 1650 * t) * np.exp(-t / 0.010) + 0.4 * np.sin(2 * np.pi * 2550 * t) * np.exp(-t / 0.006)
    return (s + _band(len(t), 1500, 6000) * np.exp(-t / 0.004) * 0.3) * vel


def brush(vel=0.5, long=False):
    """Escobilla: un barrido."""
    d = 0.22 if long else 0.1
    t = _t(d)
    e = np.sin(np.pi * np.clip(t / d, 0, 1)) ** (1.5 if long else 0.5) * (np.exp(-t / 0.05) if not long else 1)
    return _band(len(t), 1200, 7000) * e * vel


def chirp(f0, f1, d, vel=0.5):
    """Un pío: un silbido que sube o baja rápido."""
    t = _t(d)
    f = f0 + (f1 - f0) * (t / d) ** 0.7
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * t / d) ** 2 * vel


def bird_call():
    """Un pájaro (copetón, más o menos): dos o tres píos y un trino."""
    base = rng.uniform(2600, 3600)
    parts = []
    for _ in range(int(rng.integers(2, 4))):
        parts.append(chirp(base, base * rng.uniform(1.15, 1.35), rng.uniform(0.05, 0.09), rng.uniform(0.6, 1.0)))
        parts.append(np.zeros(int(rng.uniform(0.04, 0.09) * SR)))
    trill = np.concatenate([chirp(base * 1.3, base * 1.1, 0.025, 0.6) for _ in range(int(rng.integers(3, 7)))])
    return np.concatenate(parts + [trill])


def cricket_chirp():
    t = _t(0.11)
    pulses = (np.sin(np.pi * ((t * 33) % 1)) ** 4) * (t < 0.09)
    return np.sin(2 * np.pi * 4300 * t) * pulses


# ------------------------------------------------------------------ la mezcla

class Mix:
    """Un loop de 'beats' tiempos, con pistas (stems) estéreo. Todo lo que se sale del final vuelve al
    principio. swing > 0.5 atrasa las corcheas de contratiempo."""

    def __init__(self, bpm, beats, swing=0.5):
        self.bpm, self.swing = bpm, swing
        self.n = int(round(beats * 60.0 / bpm * SR))
        self.stems = {}

    def sec(self, beats):
        return beats * 60.0 / self.bpm

    def at(self, beat):
        b = np.floor(beat)
        p = beat - b
        s = self.swing
        p = p * 2 * s if p < 0.5 else s + (p - 0.5) * 2 * (1 - s)
        return int(round((b + p) * 60.0 / self.bpm * SR))

    def put(self, stem, i, sig, gain=1.0, pan=0.0):
        buf = self.stems.setdefault(stem, np.zeros((2, self.n)))
        a = (np.clip(pan, -1, 1) + 1) * np.pi / 4
        sig = sig[:self.n] * gain
        i %= self.n
        k = 0
        while k < len(sig):
            take = min(len(sig) - k, self.n - i)
            buf[0, i:i + take] += sig[k:k + take] * np.cos(a)
            buf[1, i:i + take] += sig[k:k + take] * np.sin(a)
            k += take
            i = 0

    def add(self, stem, beat, sig, gain=1.0, pan=0.0, jitter=0.005):
        """Pone un sonido en un tiempo, con el leve desfase de una persona tocando."""
        j = int(np.clip(rng.normal(0, jitter), -2.5 * jitter, 2.5 * jitter) * SR) if jitter else 0
        self.put(stem, self.at(beat) + j, sig, gain, pan)

    def line(self, stem, start, notes, inst, vel=0.6, pan=0.0, legato=0.95, shift=0, **kw):
        b = start
        for m, length in notes:
            if m is not None:
                v = vel * (1 + rng.uniform(-0.06, 0.06))
                self.add(stem, b, inst(hz(m + shift), self.sec(length) * legato, v, **kw), 1.0, pan)
            b += length
        return b


def mar_line(mx, stem, start, notes, vel=0.6, pan=0.0, shift=0, roll=1.5):
    """Melodía de marimba: las notas largas, redobladas."""
    b = start
    for m, length in notes:
        if m is not None:
            v = vel * (1 + rng.uniform(-0.06, 0.06))
            f = hz(m + shift)
            sig = marimba_roll(f, mx.sec(length) * 0.92, v) if length >= roll else marimba(f, 0, v)
            mx.add(stem, b, sig, 1.0, pan)
        b += length


def trem_line(mx, stem, start, notes, inst, vel=0.6, pan=0.0, shift=0, from_beats=2.0, rate=9.0, **kw):
    """Melodía de requinto: las notas largas, trinadas (el trémolo de los tríos)."""
    b = start
    for m, length in notes:
        if m is not None:
            v = vel * (1 + rng.uniform(-0.06, 0.06))
            f = hz(m + shift)
            if length >= from_beats:
                d = mx.sec(length) * 0.95
                k = 0
                while k / rate < d - 0.06:
                    mx.add(stem, b + k / rate / mx.sec(1), inst(f, 2.2 / rate, v * (0.8 if k else 1.0) * (0.92 if k % 2 else 1), **kw), 1.0, pan, 0.002)
                    k += 1
            else:
                mx.add(stem, b, inst(f, mx.sec(length) * 0.95, v, **kw), 1.0, pan)
        b += length


def active_rms(buf):
    """El volumen de una pista donde suena (los silencios no cuentan)."""
    x = buf.mean(0) if buf.ndim == 2 else buf
    w = int(0.4 * SR)
    k = len(x) // w
    p = (x[:k * w].reshape(k, w) ** 2).mean(1)
    on = p > p.max() * 10 ** (-40 / 10)
    return float(np.sqrt(p[on].mean())) + 1e-12


def fft_filter(x, lo=0.0, hi=NYQ, soft=1.5):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    m = np.ones_like(f)
    if lo > 0:
        m *= 1 / (1 + (lo / np.maximum(f, 1)) ** (2 * soft))
    if hi < NYQ:
        m *= 1 / (1 + (f / hi) ** (2 * soft))
    return np.fft.irfft(X * m, len(x))


def eq(x, lo=0.0, hi=NYQ, bumps=()):
    """Ecualizador por FFT: corta abajo y arriba, y sube o baja campanas [(hz, dB, ancho en octavas)]."""
    X = np.fft.rfft(x)
    f = np.maximum(np.fft.rfftfreq(len(x), 1 / SR), 1)
    m = np.ones_like(f)
    if lo > 0:
        m *= 1 / (1 + (lo / f) ** 3)
    if hi < NYQ:
        m *= 1 / (1 + (f / hi) ** 3)
    for fc, db, w in bumps:
        m *= 1 + (10 ** (db / 20) - 1) * np.exp(-(np.log2(f / fc) / w) ** 2)
    return np.fft.irfft(X * m, len(x))


def impulse(rt_lo, rt_hi, seed):
    """La respuesta de una sala: ruido que se apaga, más rápido en los agudos (sala tibia), con unas
    primeras reflexiones."""
    r = np.random.default_rng(seed)
    n = int(min(6.0, rt_lo * 1.3) * SR)
    t = np.arange(n) / SR
    X = np.fft.rfft(r.normal(0, 1, n))
    f = np.fft.rfftfreq(n, 1 / SR)
    ir = np.zeros(n)
    edges = [0, 250, 700, 2000, 5000, NYQ + 1]
    for lo, hi in zip(edges, edges[1:]):
        c = np.sqrt(max(lo, 80) * hi)
        rt = np.interp(np.log(c), [np.log(150), np.log(6000)], [rt_lo, rt_hi])
        ir += np.fft.irfft(np.where((f >= lo) & (f < hi), X, 0), n) * np.exp(-6.9 * t / rt)
    ir *= 1 - np.exp(-t / 0.008)
    ir /= np.sqrt((ir ** 2).sum())
    for d, g in ((0.011, 0.5), (0.017, -0.4), (0.023, 0.32), (0.031, -0.25), (0.041, 0.2)):
        ir[int((d + r.uniform(-0.002, 0.002)) * SR)] += g * 0.12
    pre = int(0.014 * SR)
    ir = np.concatenate([np.zeros(pre), ir])
    return ir / np.sqrt((ir ** 2).sum())


def reverb(send, rt_lo, rt_hi):
    """Convolución circular con todo el loop: la cola del final suena al principio."""
    n = send.shape[1]
    out = np.zeros_like(send)
    for ch, seed in ((0, 3), (1, 4)):
        H = np.fft.rfft(impulse(rt_lo, rt_hi, seed), n)
        src = fft_filter(send[ch] * 0.75 + send[1 - ch] * 0.25, lo=180, hi=6500)
        out[ch] = np.fft.irfft(np.fft.rfft(src) * H, n)
    return out


def tremolo(buf, rate, depth, stereo=False):
    """El motor del vibráfono (o el paneo del piano eléctrico): una vuelta exacta de ciclos por loop."""
    n = buf.shape[1]
    cyc = max(1, round(rate * n / SR))
    ph = 2 * np.pi * cyc * np.arange(n) / n
    if stereo:
        return np.stack([buf[0] * (1 - depth * (0.5 + 0.5 * np.sin(ph))), buf[1] * (1 - depth * (0.5 - 0.5 * np.sin(ph)))])
    return buf * (1 - depth * (0.5 + 0.5 * np.sin(ph)))


def render(mx, levels, room, rms_db=-17.0, fx=None):
    """levels: {pista: (dB donde suena, reverb, eq)}. El volumen se fija por lo que suena cada pista,
    así la mezcla no depende de cuántas notas tenga."""
    dry = np.zeros((2, mx.n))
    send = np.zeros((2, mx.n))
    for name, buf in mx.stems.items():
        db, rev, *rest = levels.get(name, (-12.0, 0.2))
        if fx and name in fx:
            buf = fx[name](buf)
        if rest and rest[0]:
            buf = np.stack([eq(c, **rest[0]) for c in buf])
        g = 10 ** (db / 20) / active_rms(buf)
        dry += buf * g
        send += buf * g * rev
    x = dry + reverb(send, *room)
    return master(x, rms_db)


def master(x, rms_db):
    x = x - x.mean(axis=-1, keepdims=True)
    x = np.stack([fft_filter(c, lo=45, hi=9500) for c in np.atleast_2d(x)])
    x *= 10 ** (rms_db / 20) / np.sqrt(np.mean(x ** 2))
    th, ceil = 0.6, 0.95  # solo los picos que pasan de th se redondean (no se satura lo demás)
    a = np.abs(x)
    over = a > th
    x[over] = np.sign(x[over]) * (th + (ceil - th) * np.tanh((a[over] - th) / (ceil - th)))
    return x


def radio(x, rms_db=-15.0):
    """Una radio de mesa (no de las que chillan): mono, sin graves ni agudos, un soplo apenas."""
    m = x.mean(0)
    m = fft_filter(m, lo=170, hi=4600, soft=1.4)
    m = np.tanh(m / np.abs(m).max() * 1.3)
    m = m + fft_filter(rng.normal(0, 1, len(m)), lo=1500, hi=6000) * 0.003
    return master(m, rms_db)


def save(name, x):
    x = np.atleast_2d(x)
    data = (np.clip(x.T, -1, 1) * 32767).astype("<i2")
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(x.shape[0])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name}: {x.shape[1] / SR:.1f} s, {x.shape[0]} canal(es)")


# ------------------------------------------------------------------ acompañamientos

def fingerpick(mx, chords, stem="guitarra", vel=0.42, pan=-0.3, lo=55, hi=71, ring=1.6, sub=0.5, pat=None):
    """Guitarra con los dedos: el bajo en el tiempo y las tres cuerdas de arriba (cada nota suena hasta
    que se apaga sola)."""
    prev, low = None, None
    for ch in chords:
        up = voicing(tones(ch, 3), prev, lo, hi)
        prev = up
        low = low_note(ch.bass, low, 40, 52)
        fifth = low + ((ch.root + 7 - ch.bass) % 12 or 7)  # la quinta del acorde (en C/E, el sol)
        slots = int(round(ch.beats / sub))
        p = pat or ["B", 0, 1, 2, "F", 1, 2, 0]
        for s in range(slots):
            k = p[s % len(p)]
            if k == "B":
                m, v = low, vel * 0.85
            elif k == "F":
                m, v = fifth, vel * 0.95
            else:
                m, v = up[k], vel * (0.82 if s % 2 else 0.95)
            mx.add(stem, ch.start + s * sub, nylon(hz(m), mx.sec(ring), v * (1 + rng.uniform(-0.08, 0.08))), 1.0, pan)


def walk(mx, chords, style, stem="bajo", vel=0.7):
    """El contrabajo. dos: fundamental y quinta, y una nota que lleva al acorde siguiente.
    cumbia: bum-pa-bum-pa. bossa: la fundamental larga y la quinta antes del tiempo. largo: una por
    acorde. vals: el uno de cada compás."""
    prev = None
    n = len(chords)
    for k, ch in enumerate(chords):
        nxt = chords[(k + 1) % n]
        r = low_note(ch.bass, prev)
        five = r + ((ch.root + 7 - ch.bass) % 12 or 7)  # la quinta del acorde, aunque el bajo sea otra
        five = five if five <= 50 else five - 12
        nr = low_note(nxt.bass, r)
        hits = []
        if style == "dos":
            if ch.beats >= 4:
                hits = [(0, r, 1.8), (2, five, 1.3)]
                if nr != r:
                    hits.append((3.5, nr - 1 if nr > five else nr + 1, 0.45))
            else:
                hits = [(0, r, 1.4), (1.5, five, 0.4)] if ch.beats >= 2 else [(0, r, ch.beats * 0.9)]
        elif style == "cumbia":
            for o in np.arange(0, ch.beats, 2):
                hits += [(o, r, 0.9), (o + 1, five, 0.45)]
            if ch.beats >= 4 and nr != r:
                hits.append((3.5, nr - 1 if nr > five else nr + 1, 0.4))
        elif style == "bossa":
            for o in np.arange(0, ch.beats, 2):
                hits += [(o, r, 1.4), (o + 1.5, five, 0.45)]
        elif style == "largo":
            hits = [(0, r, ch.beats * 0.97)]
            if ch.beats >= 4:
                hits = [(0, r, 2.9), (3, five, 0.95)]
        elif style == "bolero":
            hits = [(o, r if o % 4 == 0 else five, 1.4) for o in np.arange(0, ch.beats, 2)]
        elif style == "vals":
            bar = int(round(ch.start / 3))
            hits = [(0, r if bar % 2 == 0 else five, 0.9)]
        for b, m, l in hits:
            mx.add(stem, ch.start + b, bass(hz(m), mx.sec(l), vel * (1 + rng.uniform(-0.06, 0.06))), 1.0, 0.0)
        prev = r


def comp(mx, chords, inst, rhythm, stem, vel=0.4, lo=53, hi=70, pan=0.2, n=4, roll=0.004):
    """Acordes en un ritmo: rhythm(acorde, índice) -> [(desde el acorde, duración)]."""
    prev = None
    for k, ch in enumerate(chords):
        v = voicing(tones(ch, n), prev, lo, hi)
        prev = v
        for b, l in rhythm(ch, k):
            vv = vel * (1 + rng.uniform(-0.07, 0.07))
            for j, m in enumerate(v):
                mx.add(stem, ch.start + b + j * roll, inst(hz(m), mx.sec(l), vv * (0.9 if j == 0 else 1.0)), 1.0, pan)


def perc(mx, stem, start, bars, pattern, gen, pan=0.0, bar=4, jitter=0.004):
    """pattern: [(tiempo, fuerza)] por compás; gen(fuerza) -> sonido (uno nuevo cada golpe)."""
    for k in range(bars):
        for b, v in pattern:
            mx.add(stem, start + k * bar + b, gen(v * (1 + rng.uniform(-0.1, 0.1))), 1.0, pan, jitter)


# ------------------------------------------------------------------ 1. la mañana (y el recuerdo con sol)

MANANA_A = "Dmaj7 | Bm7 | Em7 | A7sus4 A7 | Dmaj7 | F#m7 B7 | Em7 Gm6 | Dmaj7"
MANANA_A2 = "Dmaj7 | Bm7 | Em7 | A7sus4 A7 | Dmaj7 | F#m7 B7 | Em7 A7 | Dmaj7 D7"
MANANA_B = "Gmaj7 | F#m7 | Em7 | Dmaj7 | Gmaj7 | F#m7 B7 | Em7 | A7sus4 A7"
MANANA_TAG = "Gmaj7 | Dmaj7 | Gmaj7 | A7sus4"
MANANA_M1 = seq("A4:.5 D5:.5 F#5 E5:.5 F#5:.5 A5 | F#5:1.5 E5:.5 D5 B4 | G4:.5 B4:.5 E5 D5:.5 E5:.5 G5 |"
                "F#5:1.5 E5:.5 C#5 A4 | A4:.5 D5:.5 F#5 E5:.5 F#5:.5 A5 | C#6 A5 B5:.5 A5:.5 F#5 |"
                "G5 E5:.5 D5:.5 Bb4 G4:.5 A4:.5 | D5:3 -")
MANANA_M1B = seq("A4:.5 D5:.5 F#5 E5:.5 F#5:.5 A5 | F#5:1.5 E5:.5 D5 B4 | G5:.5 F#5:.5 E5:.5 D5:.5 E5 B4 |"
                 "D5 E5:.5 D5:.5 C#5 E5 | A4:.5 D5:.5 F#5 E5:.5 F#5:.5 A5 | C#6 A5:.5 F#5:.5 D#5 F#5:.5 A5:.5 |"
                 "G5 F#5:.5 E5:.5 C#5 A4 | D5:2 C5:.5 B4:.5 A4:.5 F#4:.5")
MANANA_M2 = seq("B4:1.5 A4:.5 B4:.5 D5:.5 F#5 | E5:1.5 C#5:.5 A4:2 | G4:.5 B4:.5 D5:.5 E5:.5 G5 F#5:.5 E5:.5 |"
                "F#5:2 E5:.5 D5:.5 C#5:.5 A4:.5 | B4:1.5 A4:.5 B4:.5 D5:.5 G5 | A5 F#5 D#5 F#5:.5 A5:.5 |"
                "G5:1.5 F#5:.5 E5 B4 | D5:2 C#5 E5:.5 G5:.5")
MANANA_TAG_M = seq("B4:.5 D5:.5 F#5:3 | A4:.5 C#5:.5 F#5:3 | B4:.5 D5:.5 G5:3 | E5:2 D5:.5 E5:.5 A4")


def manana(bpm=88, sunny=False):
    secs, total = form([("A", MANANA_A, MANANA_M1), ("A2", MANANA_A2, MANANA_M1B), ("B", MANANA_B, MANANA_M2),
                        ("A3", MANANA_A, MANANA_M1), ("T", MANANA_TAG, MANANA_TAG_M)])
    mx = Mix(bpm, total, swing=0.54 if sunny else 0.56)
    chords = [c for s in secs for c in s[2]]
    D = scale(2)
    fingerpick(mx, chords, vel=0.45 if sunny else 0.4)
    walk(mx, chords, "dos")
    for name, b, chs, mel in secs:
        nb = int(round(sum(c.beats for c in chs) / 4))
        if name in ("A", "A2", "A3"):
            mar_line(mx, "marimba", b, mel, 0.62 if sunny else 0.55, pan=0.15)
            if name == "A3" or sunny:  # la segunda marimba, una tercera abajo
                low = [(None if m is None else third_below(m, D), l) for m, l in mel]
                mar_line(mx, "marimba2", b, low, 0.4, pan=-0.2)
        elif name == "B":  # la guitarra canta; la marimba descansa (con sol, la acompaña al unísono)
            mx.line("guitarra2", b, mel, nylon, 0.62, pan=0.3, legato=1.1, pos=0.14)
            if sunny:
                mar_line(mx, "marimba", b, mel, 0.35, pan=0.15)
        else:  # el final: la marimba en voz baja, para volver a empezar
            mar_line(mx, "marimba", b, mel, 0.4, pan=0.15)
        # la percusión entra de a poco
        sh = {"A": 0.3, "A2": 0.4, "B": 0.42, "A3": 0.48, "T": 0.3}[name] * (1.2 if sunny else 1.0)
        perc(mx, "shaker", b, nb, [(k * 0.5, sh * (1.0 if k % 2 else 0.6)) for k in range(8)], shaker, pan=0.45)
        if name != "A" or sunny:
            perc(mx, "conga", b, nb, [(1, 0.35), (2.5, 0.45), (3, 0.5), (3.5, 0.35)],
                 lambda v: drum(330 if v < 0.4 else 220, v, 0.12, slap=0.4 if v < 0.4 else 0.0), pan=-0.35)
        if name in ("B", "A3") or sunny:
            perc(mx, "bombo", b, nb, [(0, 0.5), (2.5, 0.3)], kick)
    if not sunny:  # pájaros: pocos, lejos, cada uno distinto
        for s in (2.0, 19.5, 43.0, 61.0, 83.0, 95.0):
            if s < mx.n / SR:
                mx.put("pajaros", int(s * SR), bird_call(), 1.0, rng.uniform(-0.8, 0.8))
    levels = {"marimba": (-15, 0.32, dict(lo=180)), "marimba2": (-21, 0.32, dict(lo=180)),
              "guitarra": (-20, 0.22, dict(lo=120, bumps=((2600, -3, 1.0),))),
              "guitarra2": (-16, 0.25, dict(lo=110, bumps=((2600, -2, 1.0),))),
              "bajo": (-19, 0.1, dict(hi=1400)), "shaker": (-31, 0.15, dict(lo=2500)),
              "conga": (-28, 0.2), "bombo": (-29, 0.05), "pajaros": (-33, 0.5, dict(lo=1500))}
    return render(mx, levels, (1.5, 0.6), rms_db=-17.0 if not sunny else -16.0)


# ------------------------------------------------------------------ 2. el mediodía: cumbia (y la feria)

DIA_A = "G | Em | Am7 | D7 | G | Em | Am7 D7 | G"
DIA_B = "C | D7 | Bm7 | Em | Am7 | D7 | G | D7"
DIA_I = "Em | Am7 | D7 | D7"
DIA_MA = seq("D5:.5 D5:.5 E5:.5 D5 B4:.5 G4 | B4:.5 B4:.5 C5:.5 B4 G4:.5 E4 | C5:.5 C5:.5 D5:.5 E5 D5:.5 C5:.5 A4:.5 |"
             "A4:.5 F#4:.5 A4:.5 C5 B4:.5 A4 | D5:.5 D5:.5 E5:.5 D5 B4:.5 G4 | G5:.5 G5:.5 F#5:.5 E5 D5:.5 B4 |"
             "C5 E5 D5:.5 C5:.5 A4:.5 F#4:.5 | G4 B4:.5 D5:.5 G5 -")
DIA_MB = seq("E5 G5:.5 E5:.5 C5 E5 | F#5 A5:.5 F#5:.5 D5 C5 | D5 F#5:.5 D5:.5 B4 A4 | B4 G4:.5 B4:.5 E5:2 |"
             "E5 A5:.5 G5:.5 E5 C5 | D5 F#5:.5 A5:.5 C6 A5 | B5:1.5 A5:.5 G5 D5 | F#5 E5:.5 D5:.5 C5 A4")
DIA_MI = seq("B4:.5 E5:.5 G5:.5 E5:.5 B5 G5 | C5:.5 E5:.5 A5:.5 E5:.5 C6 A5 |"
             "A4:.5 D5:.5 F#5:.5 A5:.5 C6:.5 A5:.5 F#5:.5 D5:.5 | C5 A4 F#4 -")


def chops(ch, k):
    """El rasgueo de la cumbia: a contratiempo, cortico."""
    return [(o + 0.5, 0.3) for o in np.arange(0, ch.beats, 1)]


def dia(bpm=92, fiesta=False):
    secs, total = form([("A", DIA_A, DIA_MA), ("A2", DIA_A, DIA_MA), ("B", DIA_B, DIA_MB),
                        ("A3", DIA_A, DIA_MA), ("I", DIA_I, DIA_MI)])
    mx = Mix(bpm, total)
    chords = [c for s in secs for c in s[2]]
    G = scale(7)
    walk(mx, chords, "cumbia", vel=0.75)
    comp(mx, chords, rhodes, chops, "rhodes", vel=0.42 if not fiesta else 0.5, lo=55, hi=72, pan=-0.35, n=3)
    for name, b, chs, mel in secs:
        nb = int(round(sum(c.beats for c in chs) / 4))
        if name == "A":
            trem_line(mx, "requinto", b, mel, nylon, 0.65, pan=0.2, pos=0.12)
            if fiesta:
                mar_line(mx, "marimba", b, mel, 0.4, pan=-0.15, shift=12)
        elif name == "A2":
            mar_line(mx, "marimba", b, mel, 0.6, pan=-0.15)
            low = [(None if m is None else third_below(m, G), l) for m, l in mel]
            trem_line(mx, "requinto", b, low, nylon, 0.45, pan=0.25, pos=0.12)
        elif name == "B":
            mar_line(mx, "marimba", b, mel, 0.6, pan=-0.15)
            if fiesta:
                trem_line(mx, "requinto", b, mel, nylon, 0.5, pan=0.2, shift=-12, pos=0.12)
        elif name == "A3":
            trem_line(mx, "requinto", b, mel, nylon, 0.65, pan=0.2, pos=0.12)
            mar_line(mx, "marimba", b, mel, 0.38, pan=-0.15, shift=12)
        else:
            mar_line(mx, "marimba", b, mel, 0.55, pan=-0.15)
        fuerza = 1.25 if fiesta else 1.0
        perc(mx, "guacharaca", b, nb, [(k * 0.5, (0.5 if k % 2 == 0 else 0.35) * fuerza) for k in range(8)],
             lambda v: guacharaca(v, v > 0.42 * fuerza), pan=0.4)
        perc(mx, "llamador", b, nb, [(k + 0.5, 0.4 * fuerza) for k in range(4)],
             lambda v: drum(280, v, 0.05, slap=0.5), pan=-0.25)
        perc(mx, "tambora", b, nb, [(0, 0.55 * fuerza), (2, 0.45 * fuerza)] + ([(3.5, 0.3)] if fiesta else []),
             lambda v: drum(95, v, 0.18, slap=0.15), pan=0.05)
        if name in ("A2", "B", "A3", "I") or fiesta:
            perc(mx, "shaker", b, nb, [(k * 0.25, 0.22 * fuerza * (1.0 if k % 2 else 0.6)) for k in range(16)],
                 shaker, pan=-0.5)
        if name == "I" or (fiesta and name in ("B", "A3")):  # las congas, adornando
            perc(mx, "conga", b, nb, [(1, 0.4), (1.5, 0.3), (3, 0.45), (3.25, 0.3), (3.5, 0.45)],
                 lambda v: drum(240 if v > 0.35 else 330, v, 0.12, slap=0.3), pan=0.3)
    levels = {"requinto": (-15, 0.22, dict(lo=140, bumps=((2600, -2, 1.0),))),
              "marimba": (-16, 0.28, dict(lo=180)),
              "rhodes": (-23, 0.18, dict(lo=150, hi=5000)), "bajo": (-18, 0.08, dict(hi=1400)),
              "guacharaca": (-30, 0.12, dict(lo=1500)), "llamador": (-28, 0.12), "tambora": (-25, 0.06),
              "shaker": (-34, 0.12, dict(lo=2500)), "conga": (-28, 0.15)}
    return render(mx, levels, (1.2, 0.5), rms_db=-16.0 if fiesta else -17.0)


# ------------------------------------------------------------------ 3. la tarde: bossa

TARDE_A = "Fmaj7 | Fmaj7 | Gm7 | C7 | Am7 | D7b9 | Gm7 | C7"
TARDE_A2 = "Fmaj7 | Fmaj7 | Gm7 | C7 | Am7 | D7 | Gm7 C7 | Fmaj7"
TARDE_B = "Bbmaj7 | Bbm6 | Am7 | D7 | Gm7 | C7 | Am7 D7 | Gm7 C7"
TARDE_MA = seq("A4:1.5 C5:.5 E5:2 | D5:.5 C5 A4:.5 C5:2 | Bb4:1.5 D5:.5 F5:2 | E5 D5:.5 Bb4:.5 G4:2 |"
               "C5:1.5 E5:.5 G5:2 | F#5 Eb5:.5 C5:.5 A4:2 | Bb4:.5 A4:.5 Bb4:.5 D5:.5 F5 D5 | E5:1.5 D5:.5 C5 Bb4")
TARDE_MA2 = seq("A4:1.5 C5:.5 E5:2 | D5:.5 C5 A4:.5 C5:2 | Bb4:1.5 D5:.5 F5:1.5 G5:.5 | A5:2 G5 E5 |"
                "G5:1.5 E5:.5 C5:2 | A5 F#5:.5 D5:.5 C5:2 | Bb4 D5 E5 G5 | F5:3 -")
TARDE_MB = seq("D5 F5:.5 A5:2.5 | G5 F5:.5 Db5:.5 Bb4:2 | C5 E5:.5 G5:2.5 | F#5 E5:.5 D5:.5 C5:2 |"
               "Bb4 D5:.5 F5:.5 A5:2 | G5 E5:.5 C5:.5 Bb4:2 | C5 E5 F#5 A5 | G5 F5 E5 C5")


def bossa(ch, k):
    """El piano de la bossa: un compás con el golpe en el uno y el adelanto, el otro a contratiempo."""
    if ch.beats >= 4:
        return [(0, 1.3), (1.5, 0.45), (3, 0.9)] if k % 2 == 0 else [(0.5, 0.9), (2, 0.45), (2.5, 1.2)]
    return [(0, 0.9), (1.5, 0.4)]


def tarde():
    secs, total = form([("A", TARDE_A, TARDE_MA), ("A2", TARDE_A2, TARDE_MA2), ("B", TARDE_B, TARDE_MB),
                        ("A3", TARDE_A, TARDE_MA)])
    mx = Mix(76, total)
    chords = [c for s in secs for c in s[2]]
    walk(mx, chords, "bossa", vel=0.68)
    for name, b, chs, mel in secs:
        nb = int(round(sum(c.beats for c in chs) / 4))
        if name != "A3":
            comp(mx, chs, rhodes, bossa, "rhodes", vel=0.36, lo=53, hi=70, pan=-0.2)
            mx.line("vibes", b, mel, vibes, 0.6, pan=0.2, legato=1.0)
        else:  # la última vuelta: canta el piano eléctrico y la guitarra hace la bossa
            mx.line("rhodes_canta", b, mel, rhodes, 0.55, pan=0.1, legato=1.0)
            comp(mx, chs, nylon, bossa, "guitarra", vel=0.42, lo=52, hi=67, pan=-0.3, roll=0.012)
        if name != "A":  # la clave de la bossa (3-2), en el aro
            perc(mx, "aro", b, nb // 2, [(0, 0.5), (1.5, 0.45), (3, 0.5), (5, 0.45), (6.5, 0.5)], rim, pan=0.3, bar=8)
            perc(mx, "escobilla", b, nb, [(k * 0.5, 0.45 if k % 2 else 0.3) for k in range(8)],
                 lambda v: brush(v, v < 0.35), pan=-0.1)
        if name in ("B", "A3"):
            perc(mx, "bombo", b, nb, [(0, 0.45), (1.5, 0.25), (2, 0.4), (3.5, 0.25)], kick)
    levels = {"vibes": (-15, 0.35, dict(lo=180)), "rhodes_canta": (-15, 0.3, dict(lo=150, hi=5500)),
              "rhodes": (-22, 0.25, dict(lo=140, hi=4500)), "guitarra": (-22, 0.22, dict(lo=100, bumps=((210, 2, 0.8),))),
              "bajo": (-18, 0.08, dict(hi=1300)), "aro": (-31, 0.25), "escobilla": (-35, 0.2, dict(lo=1500)),
              "bombo": (-30, 0.05)}
    fx = {"vibes": lambda x: tremolo(x, 4.6, 0.32), "rhodes": lambda x: tremolo(x, 2.2, 0.3, stereo=True),
          "rhodes_canta": lambda x: tremolo(x, 2.2, 0.25, stereo=True)}
    return render(mx, levels, (1.8, 0.75), rms_db=-17.5, fx=fx)


# ------------------------------------------------------------------ 4. la noche: 12/8

NOCHE_A = "Emaj7 | C#m7 | Amaj7 | B7sus4 B7 | Emaj7 | G#m7 C#m7 | F#m7 | B7sus4 B7"
NOCHE_B = "Amaj7 | B/A | G#m7 | C#m7 | F#m7 | G#m7 | Amaj7 | B7sus4 B7"
NOCHE_A2 = "Emaj7 | C#m7 | Amaj7 | B7sus4 B7 | Emaj7 | G#m7 C#m7 | F#m7 B7 | Amaj7 B7sus4"
_NA = ("B4:2/3 G#4:1/3 B4 D#5:2 | E5:2/3 D#5:1/3 C#5 G#4:2 | A4:2/3 B4:1/3 C#5 E5 G#5 |"
       "F#5:2 D#5:2/3 C#5:1/3 B4 | B4:2/3 G#4:1/3 B4 E5:2 | D#5 B4 E5 G#5 |")
NOCHE_MA = seq(_NA + "A5:2/3 G#5:1/3 F#5 C#5:2 | E5:2 D#5:2")
NOCHE_MA2 = seq(_NA + "A5:2/3 G#5:1/3 F#5 D#5 B4 | C#5:2 B4:2")
NOCHE_MB = seq("C#5:2/3 E5:1/3 A5:2 G#5 | F#5:2/3 E5:1/3 D#5:2 B4 | B4 D#5 F#5:2 | E5:2/3 D#5:1/3 C#5:2 B4 |"
               "A4:2/3 C#5:1/3 E5:2 F#5 | D#5:2/3 F#5:1/3 B5:2 G#5 | A5:2/3 G#5:1/3 E5:2 C#5 | E5 F#5 D#5:2")


def noche():
    secs, total = form([("A", NOCHE_A, NOCHE_MA), ("B", NOCHE_B, NOCHE_MB), ("A2", NOCHE_A2, NOCHE_MA2)])
    mx = Mix(52, total)  # el tiempo es la negra con puntillo: cada uno, tres corcheas
    chords = [c for s in secs for c in s[2]]
    fingerpick(mx, chords, vel=0.38, pan=-0.25, lo=56, hi=71, ring=1.4, sub=1 / 3,
               pat=["B", 0, 1, 2, 1, 0, "F", 0, 1, 2, 1, 0])
    walk(mx, chords, "largo", vel=0.6)
    for name, b, chs, mel in secs:
        if name == "B":
            mx.line("vibes", b, mel, vibes, 0.55, pan=0.2, legato=1.0)
            comp(mx, chs, pad, lambda ch, k: [(0, ch.beats)], "cuerdas", vel=0.3, lo=57, hi=74, pan=0.0, n=4, roll=0)
        else:
            mx.line("rhodes", b, mel, rhodes, 0.45, pan=0.15, legato=1.0)
    n = mx.n
    for k in range(int(n / SR / 0.9)):  # grillos: dos, lejos, cada uno a su ritmo
        mx.put("grillos", int(k * 0.9 * SR + rng.uniform(0, 0.05) * SR), cricket_chirp(), rng.uniform(0.7, 1.0), -0.6)
    for k in range(int(n / SR / 1.37)):
        mx.put("grillos", int((k * 1.37 + 0.4) * SR), cricket_chirp(), rng.uniform(0.5, 0.8), 0.7)
    levels = {"rhodes": (-15, 0.38, dict(lo=150, hi=5000)), "vibes": (-16, 0.42, dict(lo=180)),
              "guitarra": (-19, 0.3, dict(lo=120, bumps=((2600, -3, 1.0),))),
              "cuerdas": (-26, 0.5, dict(lo=200, hi=3500)), "bajo": (-21, 0.12, dict(hi=1200)),
              "grillos": (-40, 0.4, dict(lo=3000))}
    fx = {"rhodes": lambda x: tremolo(x, 1.6, 0.35, stereo=True), "vibes": lambda x: tremolo(x, 3.8, 0.3)}
    return render(mx, levels, (2.4, 0.9), rms_db=-18.5, fx=fx)


# ------------------------------------------------------------------ 5. el tema del juego: piano solo

NIGHT_A = "Am9 | Fmaj7 | C/E | G6 | Am | Fmaj7 | Dm7 | Esus4 E"
NIGHT_A2 = "Am9 | Fmaj7 | C/E | G | F | G | Cmaj7 | E7"
NIGHT_B = "Fmaj7 | G | Em7 | Am7 | Dm7 | G7 | Cmaj7 | Esus4 E7"
NIGHT_MA = seq("E5:1.5 D5:.5 C5 B4 | A4:2 C5 E5 | E5:1.5 D5:.5 C5:2 | B4 D5 E5 D5 |"
               "C5:1.5 B4:.5 A4 E5 | F5:1.5 E5:.5 C5 A4 | D5 F5 A5:1.5 G5:.5 | A5:2 G#5:2")
NIGHT_MA2 = seq("E5:1.5 D5:.5 C5 B4 | A4:2 C5 E5 | G5:1.5 F5:.5 E5:2 | D5:2 B4 D5 |"
                "C5:1.5 A4:.5 F5:2 | D5:1.5 B4:.5 G5:2 | E5 G5 B5:2 | G#5:2 D5 B4")
NIGHT_MB = seq("A5:2 G5 E5 | D5:2 B4 D5 | G5:2 E5 B4 | C5:2 E5 A5 |"
               "F5:2 E5 D5 | B4 D5 F5:2 | E5:1.5 D5:.5 C5 G5 | A5:2 G#5:2")


def left_hand(mx, chords, vel=0.38):
    """La mano izquierda: el bajo y el acorde abierto en corcheas, con el pedal (cada nota suena hasta
    que cambia el acorde)."""
    low = None
    for ch in chords:
        low = low_note(ch.bass, low, 36, 47)
        r = low_note(ch.root, low + 2, low, low + 11)
        third = r + [i for i in ch.iv if i in (3, 4, 5)][0] + 12
        top = r + (14 if ch.has(14) else (10 if ch.has(10) else (11 if ch.has(11) else 19)))
        up = sorted({r + 7, r + 12, third, top})
        notes = [low] + up + up[-2::-1]  # sube y baja
        for s in range(int(ch.beats * 2)):
            b = s * 0.5
            hold = ch.beats - b + 0.15
            v = vel * (1.15 if s == 0 else (0.95 if s % 2 == 0 else 0.8))
            mx.add("izquierda", ch.start + b, piano(hz(notes[s % len(notes)]), mx.sec(hold), v), 1.0, -0.25 + 0.06 * (s % 8))


def night():
    secs, total = form([("A", NIGHT_A, NIGHT_MA), ("A2", NIGHT_A2, NIGHT_MA2), ("B", NIGHT_B, NIGHT_MB)])
    mx = Mix(66, total)
    chords = [c for s in secs for c in s[2]]
    left_hand(mx, chords)
    for name, b, chs, mel in secs:
        mx.line("derecha", b, mel, piano, 0.6, pan=0.15, legato=1.25)
        if name == "B":  # el canto, en octavas
            mx.line("derecha", b, mel, piano, 0.32, pan=0.1, legato=1.25, shift=-12)
    levels = {"derecha": (-15, 0.4), "izquierda": (-20, 0.4, dict(lo=50))}
    return render(mx, levels, (2.6, 1.0), rms_db=-18.5)


# ------------------------------------------------------------------ 6. la panadería: bolero en la radio

BOLERO_A = "Am | Am | Dm | Dm | G7 | G7 | Cmaj7 | E7"
BOLERO_A2 = "Am | Am | Dm | Dm | G7 | G7 | Cmaj7 | Cmaj7"
BOLERO_B = "Dm | G7 | Cmaj7 | Am | Dm | E7 | Am | E7"
_BA = "E5:1.5 F5:.5 E5 C5 | C5 B4:.5 A4:.5 E5:2 | F5:1.5 G5:.5 F5 D5 | C5 A4 D5:2 | B4:1.5 C5:.5 D5 F5 | E5 D5 B4:2 |"
BOLERO_MA = seq(_BA + "E5:1.5 D5:.5 C5 G4 | G#4:2 B4 D5")
BOLERO_MA2 = seq(_BA + "E5:2 G5 E5 | C5:3 -")
BOLERO_MB = seq("A5:1.5 G5:.5 F5 D5 | G5:1.5 F5:.5 D5 B4 | E5:1.5 D5:.5 C5 B4 | C5:2 A4:2 |"
                "F5:1.5 E5:.5 D5 A4 | G#4 B4 D5 E5 | C5:1.5 B4:.5 A4:2 | B4:2 G#4:2")


def bolero():
    secs, total = form([("A", BOLERO_A, BOLERO_MA), ("A2", BOLERO_A2, BOLERO_MA2), ("B", BOLERO_B, BOLERO_MB)])
    mx = Mix(72, total)
    chords = [c for s in secs for c in s[2]]
    walk(mx, chords, "bolero", vel=0.7)
    comp(mx, chords, nylon, lambda ch, k: [(1, 0.5), (1.5, 0.4), (3, 0.8)], "guitarra",
         vel=0.4, lo=52, hi=67, pan=-0.3, n=3, roll=0.014)
    for name, b, chs, mel in secs:
        trem_line(mx, "requinto", b, mel, nylon, 0.62, pan=0.25, pos=0.12, from_beats=2.0, rate=8.5)
    perc(mx, "maracas", 0, int(total / 4), [(k * 0.5, 0.45 if k % 2 else 0.3) for k in range(8)], maracas, pan=0.4)
    perc(mx, "bongo", 32, 8, [(1, 0.3), (1.5, 0.25), (3, 0.35), (3.5, 0.3)],
         lambda v: drum(420 if v > 0.3 else 330, v, 0.06, slap=0.3), pan=-0.4)
    levels = {"requinto": (-14, 0.2, dict(lo=150)), "guitarra": (-20, 0.18, dict(lo=100)),
              "bajo": (-18, 0.06), "maracas": (-29, 0.1), "bongo": (-27, 0.12)}
    return radio(render(mx, levels, (1.0, 0.5), rms_db=-17.0))


# ------------------------------------------------------------------ 7. el café: vals con tiple en la radio

VALS_A = "G | G | Em | Em | C | D7 | G | G | G | B7 | Em | Em | Am | D7 | G | D7"
VALS_A2 = "G | G | Em | Em | C | D7 | G | G | G | B7 | Em | Em | Am | D7 | G | G"
VALS_B = "C | C | G | G | D7 | D7 | G | G7 | C | C | G | E7 | Am | D7 | G | D7"
_VA = ("B4 D5 G5 | F#5:1.5 E5:.5 D5 | E5 G5 B5 | A5:1.5 G5:.5 E5 | G5 E5 C5 | D5 F#5 A5 | B5:1.5 A5:.5 G5 | D5:3 |"
       "B4 D5 G5 | F#5:1.5 D#5:.5 B4 | E5 G5 B5 | G5:1.5 F#5:.5 E5 | C6 A5 E5 | C6:1.5 B5:.5 A5 |")
VALS_MA = seq(_VA + "G5 D5 B4 | A4:1.5 B4:.5 C5", 3)
VALS_MA2 = seq(_VA + "G5:2 D5 | G5:3", 3)
VALS_MB = seq("G5:2 E5 | C6:2 G5 | B5:2 G5 | D5:3 | F#5:2 A5 | C6:2 A5 | B5:1.5 A5:.5 G5 | F5:2 D5 |"
              "E5:2 G5 | C6:1.5 G5:.5 E5 | D5:2 B4 | D5 E5 G#5 | A5:2 C6 | D5 F#5 A5 | G5:3 | F#5 E5 D5", 3)


def vals():
    secs, total = form([("A", VALS_A, VALS_MA), ("A2", VALS_A2, VALS_MA2), ("B", VALS_B, VALS_MB)], bar=3)
    mx = Mix(116, total)
    chords = [c for s in secs for c in s[2]]
    walk(mx, chords, "vals", vel=0.7)
    comp(mx, chords, tiple, lambda ch, k: [(1, 0.45), (2, 0.45)], "tiple", vel=0.32, lo=59, hi=74, pan=-0.3, n=3, roll=0.01)
    for name, b, chs, mel in secs:
        trem_line(mx, "bandola", b, mel, nylon, 0.6, pan=0.25, pos=0.1, from_beats=2.0, rate=10.0, ring=0.8)
    levels = {"bandola": (-14, 0.2, dict(lo=180)), "tiple": (-21, 0.18, dict(lo=200)), "bajo": (-18, 0.06)}
    return radio(render(mx, levels, (0.9, 0.4), rms_db=-17.0))


# ------------------------------------------------------------------ revisión

def revisar():
    """Avisa de notas largas en tiempo fuerte que chocan (a medio tono) con el acorde de abajo."""
    pieces = [("manana", [MANANA_A, MANANA_A2, MANANA_B, MANANA_A, MANANA_TAG], [MANANA_M1, MANANA_M1B, MANANA_M2, MANANA_M1, MANANA_TAG_M], 4),
              ("dia", [DIA_A, DIA_A, DIA_B, DIA_A, DIA_I], [DIA_MA, DIA_MA, DIA_MB, DIA_MA, DIA_MI], 4),
              ("tarde", [TARDE_A, TARDE_A2, TARDE_B, TARDE_A], [TARDE_MA, TARDE_MA2, TARDE_MB, TARDE_MA], 4),
              ("noche", [NOCHE_A, NOCHE_B, NOCHE_A2], [NOCHE_MA, NOCHE_MB, NOCHE_MA2], 4),
              ("night", [NIGHT_A, NIGHT_A2, NIGHT_B], [NIGHT_MA, NIGHT_MA2, NIGHT_MB], 4),
              ("bolero", [BOLERO_A, BOLERO_A2, BOLERO_B], [BOLERO_MA, BOLERO_MA2, BOLERO_MB], 4),
              ("vals", [VALS_A, VALS_A2, VALS_B], [VALS_MA, VALS_MA2, VALS_MB], 3)]
    bad = 0
    for name, charts, mels, bar in pieces:
        for k, (c, m) in enumerate(zip(charts, mels)):
            chs = chart(c, bar)
            b = 0.0
            for note, length in m:
                if note is not None and length >= 1 and abs(b - round(b)) < 1e-6:
                    ch = [x for x in chs if x.start <= b < x.start + x.beats][0]
                    pc = note % 12
                    if pc not in ch.pcs and any(min((pc - p) % 12, (p - pc) % 12) == 1 for p in ch.pcs):
                        print(f"  {name} parte {k + 1}, tiempo {b:g}: {note} sobre {ch.name}")
                        bad += 1
                b += length
    print("revisión:", "sin choques" if not bad else f"{bad} para mirar")


TEMAS = {
    "barrio_manana": lambda: manana(),
    "barrio_dia": lambda: dia(),
    "barrio_tarde": lambda: tarde(),
    "barrio_noche": lambda: noche(),
    "night": lambda: night(),
    "bakery": lambda: bolero(),
    "cafe": lambda: vals(),
    "feria": lambda: dia(116, fiesta=True),
    "flashback": lambda: manana(102, sunny=True),
}

if __name__ == "__main__":
    revisar()
    if "--revisar" in sys.argv:
        sys.exit()
    for name in [a for a in sys.argv[1:] if a in TEMAS] or TEMAS:
        save(name, TEMAS[name]())
