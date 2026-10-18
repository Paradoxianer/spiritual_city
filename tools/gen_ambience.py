#!/usr/bin/env python3
"""Generates the ambience loops in assets/audio/ambience/ and the action
sounds in assets/audio/actions/ (playtest 2026-10-18).

Everything is synthesised here – no recordings, so no licence questions.
Each loop is built on a circular buffer (noise is shaped in the frequency
domain, events wrap around the end), so it repeats without a seam.

    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install numpy
    /tmp/venv/bin/python tools/gen_ambience.py

Needs ffmpeg with libvorbis for the OGG files.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 22050
SECONDS = 24
N = SR * SECONDS
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio', 'ambience')
rng = np.random.default_rng(7)
t = np.arange(N) / SR


def shaped_noise(lo, hi, slope=0.0):
    """Periodic noise with energy between lo and hi Hz, ~f^-slope."""
    spec = np.fft.rfft(rng.standard_normal(N))
    f = np.fft.rfftfreq(N, 1 / SR)
    gain = np.zeros_like(f)
    band = (f >= lo) & (f <= hi)
    gain[band] = 1.0 / np.maximum(f[band], 1.0) ** (slope / 2)
    # Soft band edges.
    gain *= np.clip((f - lo * 0.7) / (lo * 0.3 + 1e-9), 0, 1)
    gain *= np.clip((hi * 1.3 - f) / (hi * 0.3), 0, 1)
    x = np.fft.irfft(spec * gain, n=N)
    return x / (np.abs(x).max() + 1e-9)


def lfo(cycles, phase=0.0):
    """Slow periodic modulation with a whole number of cycles per loop."""
    return 0.5 + 0.5 * np.sin(2 * np.pi * cycles * t / SECONDS + phase)


def place(buf, ev, at):
    """Adds event [ev] at sample [at], wrapping around the loop end."""
    idx = (np.arange(len(ev)) + at) % N
    np.add.at(buf, idx, ev)


def env(n, attack, release):
    e = np.ones(n)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.exp(-np.linspace(0, 6, r))
    return e


def chirp(f0, f1, dur):
    n = int(dur * SR)
    k = np.linspace(0, 1, n)
    f = f0 + (f1 - f0) * k
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.sin(np.pi * k) ** 2


def reverb(x, taps=12, length=1.2, decay=3.0):
    """Cheap circular multi-tap echo as a room."""
    y = x.copy()
    for i in range(taps):
        d = int(rng.uniform(0.03, length) * SR)
        g = np.exp(-decay * d / SR) * rng.uniform(0.3, 0.6)
        y += np.roll(x, d) * g
    return y


def city():
    rumble = shaped_noise(30, 400, slope=1.6) * (0.55 + 0.45 * lfo(3)) * (0.8 + 0.2 * lfo(7, 1))
    out = rumble * 0.45
    # Cars passing by: band noise swelling up and away.
    for _ in range(6):
        dur = rng.uniform(2.5, 4.5)
        n = int(dur * SR)
        k = np.linspace(-1, 1, n)
        swell = np.exp(-(k * 2.4) ** 2)
        car = shaped_noise(80, 1800, slope=1.0)[:n] * swell
        place(out, car * rng.uniform(0.25, 0.5), int(rng.uniform(0, N)))
    # A few birds.
    for _ in range(7):
        at = int(rng.uniform(0, N))
        base = rng.uniform(2800, 4200)
        for j in range(rng.integers(2, 5)):
            c = chirp(base, base * rng.uniform(1.1, 1.4), rng.uniform(0.05, 0.11))
            place(out, c * 0.06, at + int(j * rng.uniform(0.09, 0.16) * SR))
    return out


def home():
    out = shaped_noise(60, 4000, slope=1.0) * 0.05
    hum = (np.sin(2 * np.pi * 50 * t) * 0.6 + np.sin(2 * np.pi * 100 * t) * 0.3 +
           np.sin(2 * np.pi * 150 * t) * 0.1)
    out += hum * 0.035 * (0.7 + 0.3 * lfo(2))
    # Wall clock: tick, tock.
    click = shaped_noise(1800, 5000)[:int(0.025 * SR)] * env(int(0.025 * SR), 0.001, 0.02)
    for s in range(SECONDS):
        tone = 1.0 if s % 2 == 0 else 0.75
        c = click * tone
        c[:441] += chirp(1400 if s % 2 == 0 else 1100, 900, 0.02)[:441] * 0.4
        place(out, c * 0.18, int(s * SR))
    return out


def hall():
    air = shaped_noise(80, 6000, slope=1.2) * 0.07
    # Murmur: speech-band noise with syllable-like modulation.
    mur = np.zeros(N)
    for v in range(5):
        band = shaped_noise(250, 2800, slope=0.6)
        rate = rng.uniform(3.0, 5.5)
        syll = np.clip(np.sin(2 * np.pi * rate * t + rng.uniform(0, 6)), 0, 1) ** 2
        phrase = np.clip(np.sin(2 * np.pi * rng.integers(2, 6) * t / SECONDS + rng.uniform(0, 6)), 0, 1)
        mur += band * syll * phrase
    mur = reverb(mur / (np.abs(mur).max() + 1e-9), length=0.8)
    # Soft distant steps.
    steps = np.zeros(N)
    thump = shaped_noise(60, 500)[:int(0.08 * SR)] * env(int(0.08 * SR), 0.003, 0.07)
    at = 0
    while at < N:
        place(steps, thump * rng.uniform(0.5, 1.0), at)
        at += int(rng.uniform(0.45, 0.6) * SR) if rng.random() > 0.1 else int(rng.uniform(1.5, 3) * SR)
    return air + mur / (np.abs(mur).max() + 1e-9) * 0.12 + reverb(steps, length=0.6) * 0.05


def church():
    air = shaped_noise(60, 5000, slope=1.4) * 0.05
    # Soft organ drone: D and A with gentle swell, a few harmonics each.
    organ = np.zeros(N)
    for f, a in [(73.42, 1.0), (110.0, 0.7), (146.83, 0.5), (220.0, 0.25), (293.66, 0.15)]:
        for h, ha in [(1, 1.0), (2, 0.35), (3, 0.15), (4, 0.08)]:
            organ += np.sin(2 * np.pi * f * h * t + rng.uniform(0, 6)) * a * ha
    organ *= 0.6 + 0.4 * lfo(2, 0.5)
    organ = reverb(organ / np.abs(organ).max(), taps=16, length=2.0, decay=1.5)
    return air + organ / np.abs(organ).max() * 0.16


def shriek(dur):
    """A distant, thin daemon cry: band noise through a gliding resonance."""
    n = int(dur * SR)
    k = np.linspace(0, 1, n)
    base = rng.standard_normal(n)
    f = rng.uniform(900, 1500) * (1 + 0.6 * np.sin(np.pi * k)) * rng.choice([1, 0.8])
    # Resonant band-pass via a phase-modulated sine riding the noise envelope.
    ph = 2 * np.pi * np.cumsum(f) / SR
    voice = np.sin(ph + 0.8 * np.sin(ph * 1.5)) * (0.6 + 0.4 * np.abs(np.convolve(base, np.ones(200) / 200, 'same')))
    breath = shaped_noise(1500, 6000)[:n] * 0.5
    e = np.sin(np.pi * k) ** 3 * (0.7 + 0.3 * np.sin(2 * np.pi * rng.uniform(5, 9) * k))
    return (voice + breath) * e


def whisper(dur):
    """Unintelligible whisper: speech-band noise with syllable bursts."""
    n = int(dur * SR)
    k = np.arange(n) / SR
    syll = np.clip(np.sin(2 * np.pi * rng.uniform(4, 7) * k), 0, 1) ** 3
    return shaped_noise(1800, 5500)[:n] * syll * np.sin(np.pi * k / dur) ** 2


def spirit():
    # Spherical: slow detuned pad on A with an open fifth.
    pad = np.zeros(N)
    for f, a in [(110, 1.0), (110.4, 0.8), (164.8, 0.5), (220.3, 0.3), (329.6, 0.15)]:
        pad += np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * a
    pad *= 0.6 + 0.4 * lfo(2)
    # Danger underneath: a low tritone that swells and a slow pulse.
    low = (np.sin(2 * np.pi * 55 * t) + np.sin(2 * np.pi * 77.78 * t) * 0.7) * (0.3 + 0.7 * lfo(3, 1.0) ** 2)
    pulse = np.zeros(N)
    beat = tone(48, 0.35, 0.01, 0.3) * 0.8
    for b in range(0, SECONDS, 3):
        place(pulse, beat, int(b * SR))
        place(pulse, beat * 0.6, int((b + 0.45) * SR))
    wind = shaped_noise(150, 1200, slope=1.0) * (0.4 + 0.6 * lfo(4, 2))
    out = pad / np.abs(pad).max() * 0.16 + low / np.abs(low).max() * 0.14 + pulse * 0.10 + wind * 0.07
    # Distant daemons: rare cries and whispers far away (quiet, echoing).
    far = np.zeros(N)
    for _ in range(6):
        place(far, shriek(rng.uniform(0.8, 1.4)) * rng.uniform(0.6, 1.0), int(rng.uniform(0, N)))
    for _ in range(5):
        place(far, whisper(rng.uniform(1.0, 1.8)) * 0.8, int(rng.uniform(0, N)))
    far = reverb(far / (np.abs(far).max() + 1e-9), taps=14, length=1.4, decay=1.8)
    out += far / (np.abs(far).max() + 1e-9) * 0.13
    # Glints of light remain: God is here too.
    for _ in range(8):
        f = rng.choice([880, 1046.5, 1318.5, 1760])
        n = int(2.2 * SR)
        g = np.sin(2 * np.pi * f * np.arange(n) / SR) * env(n, 0.02, 2.1)
        place(out, g * 0.035, int(rng.uniform(0, N)))
    return reverb(out, taps=10, length=1.5, decay=2.0)


# ── Action sounds (one-shots, not loops) ─────────────────────────────────────

def tone(f, dur, attack=0.01, release=None, harmonics=((1, 1.0),)):
    n = int(dur * SR)
    k = np.arange(n) / SR
    x = sum(np.sin(2 * np.pi * f * h * k) * a for h, a in harmonics)
    return x * env(n, attack, release or dur * 0.9)


def mix(length, parts):
    out = np.zeros(int(length * SR))
    for at, x in parts:
        i = int(at * SR)
        out[i:i + len(x)] += x[:len(out) - i]
    return out


def talk():
    # Three soft "voice" blips: a vowel-like tone gliding in pitch.
    parts = []
    for i, (f0, f1) in enumerate([(210, 240), (250, 220), (230, 260)]):
        n = int(0.11 * SR)
        k = np.linspace(0, 1, n)
        ph = 2 * np.pi * np.cumsum(f0 + (f1 - f0) * k) / SR
        v = (np.sin(ph) + 0.5 * np.sin(2 * ph) + 0.3 * np.sin(3 * ph) + 0.15 * np.sin(5 * ph))
        parts.append((i * 0.14, v * np.sin(np.pi * k) ** 1.5))
    return mix(0.5, parts)


def pray():
    # A soft bell chord (D major) with a shimmering tail.
    bell = ((1, 1.0), (2.01, 0.4), (3.02, 0.2), (4.2, 0.1))
    parts = [(0.0, tone(587.33, 2.2, 0.005, 2.1, bell) * 0.6),
             (0.12, tone(739.99, 2.0, 0.005, 1.9, bell) * 0.45),
             (0.24, tone(880.0, 1.8, 0.005, 1.7, bell) * 0.4)]
    return reverb(np.pad(mix(2.6, parts), (0, 0)), taps=8, length=0.5, decay=4.0)


def sleep():
    # A little lullaby falling asleep: three falling notes, then quiet.
    soft = ((1, 1.0), (2, 0.25))
    parts = [(0.0, tone(659.25, 0.7, 0.03, 0.6, soft) * 0.5),
             (0.45, tone(523.25, 0.7, 0.03, 0.6, soft) * 0.45),
             (0.9, tone(392.0, 1.4, 0.03, 1.3, soft) * 0.45)]
    return mix(2.4, parts)


def choir_voice(f_path, dur, vowel=(700, 1150, 2600), vib=0.004, seed_shift=0.0):
    """One sung 'a': harmonics shaped by vowel formants, gentle vibrato."""
    n = int(dur * SR)
    k = np.arange(n) / SR
    f = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(f_path)), f_path)
    f = f * (1 + vib * np.sin(2 * np.pi * rng.uniform(4.5, 5.5) * k + seed_shift))
    ph = 2 * np.pi * np.cumsum(f) / SR
    out = np.zeros(n)
    f0 = float(np.mean(f_path))
    for h in range(1, int(4000 / f0)):
        fh = h * f0
        g = sum(np.exp(-((fh - fc) / bw) ** 2) * a
                for fc, bw, a in zip(vowel, (130, 150, 250), (1.0, 0.7, 0.25)))
        out += np.sin(h * ph) * (g + 0.02) / h ** 0.3
    return out


def wave_liberation():
    # 🕊️ A short Gregorian phrase: men's voices in unison on "a", Dorian
    # neume D–E–F–E, an octave drone below, long cathedral reverb.
    d, e, f = 146.83, 164.81, 174.61
    melody = [d, d, e, f, f, e, e]
    dur = 1.5
    voices = np.zeros(int(dur * SR))
    for v in range(5):
        detune = 1 + rng.uniform(-0.006, 0.006)
        voices += choir_voice([m * detune for m in melody], dur, seed_shift=v)
    drone = choir_voice([d / 2] * 3, dur, vowel=(600, 1000, 2500)) * 0.5
    n = len(voices)
    shape = env(n, 0.12, 0.5)
    x = (voices / 5 + drone) * shape
    return reverb(x, taps=22, length=1.6, decay=1.6)


def wave_rebuke():
    # 🫸 A firm push: deep impact, a bright crack and a short shock rumble.
    thump = tone(55, 0.5, 0.002, 0.45, ((1, 1.0), (2, 0.4))) * np.exp(-np.linspace(0, 5, int(0.5 * SR)))
    crack = shaped_noise(1500, 9000)[:int(0.12 * SR)] * env(int(0.12 * SR), 0.001, 0.11)
    rumble = shaped_noise(40, 300, slope=1.5)[:int(0.9 * SR)] * env(int(0.9 * SR), 0.01, 0.85)
    return reverb(mix(1.0, [(0, thump * 0.9), (0, crack * 0.5), (0.02, rumble * 0.5)]), taps=5, length=0.3, decay=6)


def wave_slow():
    # ⏳ Time thickens: a falling, wobbling tone.
    n = int(1.2 * SR)
    kk = np.linspace(0, 1, n)
    f = 420 * (1 - 0.55 * kk)
    ph = 2 * np.pi * np.cumsum(f * (1 + 0.04 * np.sin(2 * np.pi * (6 - 4 * kk) * kk * 1.2))) / SR
    x = (np.sin(ph) + 0.3 * np.sin(2 * ph)) * np.sin(np.pi * kk) ** 0.7
    shimmer = shaped_noise(3000, 7000)[:n] * np.exp(-kk * 4) * 0.15
    return reverb(x * 0.5 + shimmer, taps=8, length=0.6, decay=3)


def wave_drain():
    # 🪫 Power is drawn away: a reverse swell that sucks downwards.
    n = int(1.1 * SR)
    kk = np.linspace(0, 1, n)
    swell = shaped_noise(200, 4000)[:n] * kk ** 2.5 * np.exp(-((kk - 0.85) / 0.12) ** 2 * 0.5)
    ph = 2 * np.pi * np.cumsum(300 * (1 - 0.7 * kk)) / SR
    down = np.sin(ph) * kk ** 2 * 0.5
    x = (swell * 0.6 + down) * np.clip((1 - kk) * 12, 0, 1)
    return reverb(x, taps=6, length=0.4, decay=4)


def daemon_near():
    # A daemon close by: a thin cry with a hiss, not too long.
    x = shriek(1.1) + whisper(1.1) * 0.6
    return reverb(x / (np.abs(x).max() + 1e-9), taps=6, length=0.5, decay=3)


def write_once(name, x, peak=0.7):
    out = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio', 'actions')
    x = x - x.mean()
    x = x / (np.abs(x).max() + 1e-9) * peak
    pcm = (x * 32767).astype(np.int16)
    os.makedirs(out, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        path = f.name
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dst = os.path.join(out, f'{name}.ogg')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', path, '-c:a', 'libvorbis',
                    '-q:a', '4', dst], check=True)
    os.remove(path)
    print(dst, os.path.getsize(dst) // 1024, 'KB')


def write(name, x, peak=0.6):
    x = x - x.mean()
    x = x / (np.abs(x).max() + 1e-9) * peak
    pcm = (x * 32767).astype(np.int16)
    os.makedirs(OUT, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        path = f.name
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dst = os.path.join(OUT, f'{name}.ogg')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', path, '-c:a', 'libvorbis',
                    '-q:a', '3', dst], check=True)
    os.remove(path)
    print(dst, os.path.getsize(dst) // 1024, 'KB')


if __name__ == '__main__':
    write('city', city(), 0.5)
    write('home', home(), 0.45)
    write('hall', hall(), 0.5)
    # church.ogg is a Pixabay recording now (see assets/LICENSES.md);
    # church() stays as the synthetic fallback.
    write('spirit', spirit(), 0.55)
    write_once('talk', talk(), 0.5)
    write_once('pray', pray(), 0.6)
    write_once('sleep', sleep(), 0.55)
    # wave_liberation.ogg is a Pixabay recording now (see assets/LICENSES.md);
    # wave_liberation() stays as the synthetic fallback.
    write_once('wave_rebuke', wave_rebuke(), 0.7)
    write_once('wave_slow', wave_slow(), 0.55)
    write_once('wave_drain', wave_drain(), 0.55)
    write_once('daemon_near', daemon_near(), 0.6)
