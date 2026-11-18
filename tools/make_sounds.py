#!/usr/bin/env python3
"""Generates the placeholder sounds in assets/audio/ (no recordings, no licences).

Run:  python3 tools/make_sounds.py      (needs numpy and ffmpeg with libvorbis)

Loops are built so the end flows straight into the start (no click when repeating).
Replace any .ogg with a real recording later; the game only cares about the file names.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


def lowpass(x, cutoff):
    """One-pole low-pass filter."""
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def pluck(freq, dur, bright=0.5, decay=0.996):
    """Karplus-Strong plucked string: soft, santur/harp-like."""
    n = int(SR * dur)
    period = max(2, int(SR / freq))
    buf = lowpass(rng.uniform(-1, 1, period), 2000 + 6000 * bright)
    out = np.empty(n)
    for i in range(n):
        j = i % period
        out[i] = buf[j]
        buf[j] = decay * 0.5 * (buf[j] + buf[(j + 1) % period])
    env = np.minimum(1, np.arange(n) / (0.004 * SR))
    return out * env


def reverb(x, seconds=1.8, mix=0.3):
    n = int(SR * seconds)
    ir = rng.normal(0, 1, n) * np.exp(-np.linspace(0, 6, n))
    ir = lowpass(ir, 3500)
    ir /= np.abs(ir).sum() / 8
    size = 1 << int(np.ceil(np.log2(len(x) + n)))  # FFT convolution (fast for long music)
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x) + n]
    dry = np.concatenate([x, np.zeros(n)])
    return (1 - mix) * dry + mix * wet


def wrap_loop(x, length):
    """Fold anything past `length` back onto the start, so the loop is seamless."""
    out = x[:length].copy()
    tail = x[length:]
    while len(tail):
        k = min(len(tail), length)
        out[:k] += tail[:k]
        tail = tail[k:]
    return out


def crossfade_loop(x, length, fade):
    """For noise beds: blend the extra `fade` samples at the end into the start."""
    out = x[:length].copy()
    t = np.linspace(0, 1, fade)
    out[:fade] = out[:fade] * t + x[length:length + fade] * (1 - t)
    return out


def norm(x, peak):
    return x / (np.abs(x).max() + 1e-9) * peak


def save(name, x):
    x = np.clip(x, -1, 1)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        path = tmp.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype("<i2").tobytes())
    dst = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", "3", dst], check=True)
    os.remove(path)
    print(f"{name}.ogg  {len(x) / SR:5.1f}s  {os.path.getsize(dst) // 1024} KB")


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


# --- calm music: a slow plucked melody over a soft drone (D, minor pentatonic) ---
def music():
    bars, beat = 24, 0.75  # 24 bars of 4 beats at 80 bpm = 72 s
    length = int(SR * bars * 4 * beat)
    out = np.zeros(length + SR * 6)
    scale = [62, 65, 67, 69, 72, 74, 77, 79]  # D F G A C D F G
    pos = 3
    for bar in range(bars):
        phrase_rest = bar % 4 == 3
        for b in range(4):
            if phrase_rest and b > 0:
                continue
            if rng.random() < 0.35 and b != 0:
                continue
            pos = int(np.clip(pos + rng.choice([-2, -1, -1, 1, 1, 2]), 0, len(scale) - 1))
            t = int(SR * (bar * 4 + b) * beat)
            note = pluck(hz(scale[pos]), 3.0, bright=0.35, decay=0.9975)
            out[t:t + len(note)] += note * (0.9 if b == 0 else 0.6)
            if b == 0 and bar % 2 == 0:  # a low root note every other bar
                low = pluck(hz(50 if bar % 8 < 4 else 45), 4.0, bright=0.2, decay=0.998)
                out[t:t + len(low)] += low * 0.5
    out = reverb(out, 2.2, 0.35)
    melody = wrap_loop(out, length)
    # drone: frequencies rounded so each completes whole cycles in the loop
    t = np.arange(length) / SR
    L = length / SR

    def f(x):
        return round(x * L) / L

    swell = 0.6 + 0.4 * np.sin(2 * np.pi * f(1 / 12) * t)
    drone = (np.sin(2 * np.pi * f(hz(38)) * t) + 0.5 * np.sin(2 * np.pi * f(hz(45)) * t)
             + 0.25 * np.sin(2 * np.pi * f(hz(50)) * t)) * swell
    return norm(norm(melody, 1) + 0.12 * drone, 0.8)


# --- birds and a light breeze (garden, town) ---
def birds():
    L = SR * 30
    fade = SR * 2
    wind = lowpass(lowpass(rng.normal(0, 1, L + fade), 300), 300)
    wind = norm(wind, 0.08) * (0.7 + 0.3 * np.sin(np.linspace(0, 6 * np.pi, L + fade)))
    bed = crossfade_loop(wind, L, fade)
    chirps = np.zeros(L + SR)
    t = 0.5
    while t < 30:
        f0 = rng.uniform(2600, 4200)
        for _ in range(rng.integers(2, 6)):
            d = rng.uniform(0.05, 0.12)
            n = int(SR * d)
            k = np.arange(n) / SR
            sweep = f0 + rng.uniform(-900, 1200) * k / d
            tone = np.sin(2 * np.pi * np.cumsum(sweep) / SR) * np.sin(np.pi * k / d) ** 2
            s = int(SR * t)
            chirps[s:s + n] += tone * rng.uniform(0.3, 0.7)
            t += d + rng.uniform(0.04, 0.12)
        t += rng.uniform(1.5, 4.5)
    return norm(bed + 0.5 * wrap_loop(reverb(chirps, 0.8, 0.25), L), 0.6)


# --- a flowing stream (mountain view) ---
def stream():
    L = SR * 20
    fade = SR * 2
    n = rng.normal(0, 1, L + fade)
    water = lowpass(n, 1800) - lowpass(n, 350)
    water *= 0.75 + 0.25 * np.sin(np.linspace(0, 10 * np.pi, L + fade))
    bed = crossfade_loop(norm(water, 0.5), L, fade)
    blips = np.zeros(L + SR)
    for _ in range(140):
        d = rng.uniform(0.02, 0.06)
        k = np.arange(int(SR * d)) / SR
        f0 = rng.uniform(500, 1300)
        tone = np.sin(2 * np.pi * (f0 + 900 * k / d) * k) * np.exp(-k / (d / 3))
        s = rng.integers(0, L)
        blips[s:s + len(tone)] += tone * rng.uniform(0.1, 0.3)
    return norm(bed + wrap_loop(blips, L), 0.6)


# --- short effects ---
def tap():
    return norm(pluck(hz(84), 0.35, bright=0.6, decay=0.99), 0.5)


def step():
    n = int(SR * 0.09)
    x = lowpass(rng.normal(0, 1, n), 500) * np.exp(-np.arange(n) / (SR * 0.02))
    return norm(x, 0.5)


def door():
    a = pluck(hz(69), 1.2, 0.4, 0.997)
    b = pluck(hz(76), 1.0, 0.4, 0.997)
    out = np.zeros(int(SR * 1.4))
    out[:len(a)] += a
    out[int(SR * 0.16):int(SR * 0.16) + len(b)] += b
    return norm(reverb(out, 1.0, 0.25), 0.6)


def place():
    n = int(SR * 0.18)
    k = np.arange(n) / SR
    pop = np.sin(2 * np.pi * (260 + 900 * k) * k) * np.exp(-k / 0.04)
    thump = lowpass(rng.normal(0, 1, n), 300) * np.exp(-k / 0.03)
    return norm(pop + 0.6 * thump, 0.6)


def remove():
    n = int(SR * 0.3)
    k = np.arange(n) / SR
    x = rng.normal(0, 1, n)
    out = np.zeros(n)
    for i, c in enumerate(np.linspace(3000, 300, 6)):  # falling filtered whoosh
        seg = slice(i * n // 6, (i + 1) * n // 6)
        out[seg] = lowpass(x, c)[seg]
    return norm(out * np.sin(np.pi * k / k[-1]), 0.45)


def chime():
    out = np.zeros(int(SR * 2.0))
    for i, m in enumerate([74, 77, 81]):
        s = int(SR * 0.12 * i)
        note = pluck(hz(m), 1.6, 0.45, 0.998)
        out[s:s + len(note)] += note
    return norm(reverb(out, 1.4, 0.3), 0.55)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("tap", tap), ("step", step), ("door", door), ("place", place),
                     ("remove", remove), ("chime", chime), ("birds", birds), ("stream", stream),
                     ("music", music)]:
        save(name, fn())
