#!/usr/bin/env python3
"""Procedural, sfxr-style sound synthesis for The Ashen Codex (pure Python, no deps).

Writes 16-bit mono WAVs to audio/generated/. Deterministic (fixed seeds).
  python3 tools_dev/synth_sfx.py

One-shots: quill, page_turn, detent, tick, tile_snap, snap, bead, pour, wrong, wrong_soft,
frenzy, toll, solve, ui_tap. Loops (seamless: noise loops are crossfaded, tones use
frequencies whose period divides the loop): heartbeat, amb_vault, amb_marsh, drone_vault,
drone_marsh. Replace any file with a same-named WAV to upgrade it (see ASSET_MANIFEST).
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio", "generated")


def write(name, samples, peak=0.85):
    m = max(1e-9, max(abs(s) for s in samples))
    k = peak / m
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * k)) * 32767)) for s in samples))


def env(n, a, d, sustain=0.0, r=0.0):
    """Attack/decay envelope over n samples (a, d, r in seconds)."""
    out = []
    na, nd, nr = int(a * RATE), int(d * RATE), int(r * RATE)
    for i in range(n):
        if i < na:
            v = i / max(1, na)
        elif i < na + nd:
            v = 1 - (1 - sustain) * (i - na) / max(1, nd)
        else:
            v = sustain
        if nr and i > n - nr:
            v *= (n - i) / nr
        out.append(v)
    return out


def noise(n, rng):
    return [rng.uniform(-1, 1) for _ in range(n)]


def lowpass(x, alpha):
    y, prev = [], 0.0
    for s in x:
        prev += alpha * (s - prev)
        y.append(prev)
    return y


def highpass(x, alpha):
    y, prev_x, prev_y = [], 0.0, 0.0
    for s in x:
        prev_y = alpha * (prev_y + s - prev_x)
        prev_x = s
        y.append(prev_y)
    return y


def tone(n, freq, phase=0.0, kind="sine", sweep=0.0):
    out, ph = [], phase
    for i in range(n):
        f = freq * (1 + sweep * i / n)
        ph += 2 * math.pi * f / RATE
        if kind == "sine":
            out.append(math.sin(ph))
        elif kind == "tri":
            out.append(2 / math.pi * math.asin(math.sin(ph)))
        else:
            out.append(1.0 if math.sin(ph) >= 0 else -1.0)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0 for t in tracks) for i in range(n)]


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def gain(a, g):
    return [x * g for x in a]


def seamless(x, fade):
    """Crossfade the tail into the head so the sample loops without a click."""
    nf = int(fade * RATE)
    body = x[:len(x) - nf]
    for i in range(nf):
        t = i / nf
        body[i] = body[i] * t + x[len(x) - nf + i] * (1 - t)
    return body


def main():
    rng = random.Random(1337)
    n = lambda sec: int(sec * RATE)

    # Quill: scratchy high-passed noise in short strokes.
    s = n(0.35)
    strokes = [0.6 + 0.4 * math.sin(2 * math.pi * 23 * i / RATE) ** 2 for i in range(s)]
    write("quill", mul(mul(highpass(noise(s, rng), 0.7), env(s, 0.01, 0.3)), strokes), 0.5)
    # Page turn: swept filtered noise swell.
    s = n(0.5)
    x = noise(s, rng)
    y, prev = [], 0.0
    for i, v in enumerate(x):
        a = 0.05 + 0.5 * (i / s)
        prev += a * (v - prev)
        y.append(prev)
    write("page_turn", mul(y, env(s, 0.12, 0.35)), 0.55)
    # Wheel detent tick: tiny click + resonant body.
    s = n(0.06)
    write("detent", mix(gain(mul(noise(s, rng), env(s, 0.0005, 0.01)), 0.7), gain(mul(tone(s, 1800), env(s, 0.001, 0.05)), 0.5)), 0.55)
    s = n(0.04)
    write("tick", mul(tone(s, 2600, kind="tri"), env(s, 0.0005, 0.035)), 0.35)
    # Tile snap: wooden knock.
    s = n(0.12)
    write("tile_snap", mix(mul(tone(s, 420, sweep=-0.4), env(s, 0.001, 0.1)), gain(mul(lowpass(noise(s, rng), 0.3), env(s, 0.0005, 0.02)), 0.8)), 0.7)
    s = n(0.1)
    write("snap", mix(mul(tone(s, 660, sweep=-0.3), env(s, 0.001, 0.08)), gain(mul(noise(s, rng), env(s, 0.0005, 0.01)), 0.4)), 0.6)
    # Bead click: two glassy pings.
    s = n(0.18)
    write("bead", mix(mul(tone(s, 3100), env(s, 0.0005, 0.06)), gain(mul(tone(s, 4700), env(s, 0.0005, 0.04)), 0.5)), 0.4)
    # Chalice pour: gurgling lowpassed noise with wobble.
    s = n(0.9)
    wob = [0.5 + 0.5 * math.sin(2 * math.pi * (7 + 5 * i / s) * i / RATE) for i in range(s)]
    write("pour", mul(mul(lowpass(noise(s, rng), 0.08), wob), env(s, 0.08, 0.7, 0.2, 0.2)), 0.6)
    # Wrong commit: a sick low thud with a detuned groan.
    s = n(0.7)
    write("wrong", mix(mul(tone(s, 70, sweep=-0.5), env(s, 0.005, 0.6)), gain(mul(tone(s, 93, kind="tri", sweep=-0.45), env(s, 0.01, 0.6)), 0.6),
                       gain(mul(lowpass(noise(s, rng), 0.05), env(s, 0.001, 0.15)), 1.2)), 0.9)
    s = n(0.25)
    write("wrong_soft", mix(mul(tone(s, 120, sweep=-0.3), env(s, 0.003, 0.2)), gain(mul(lowpass(noise(s, rng), 0.1), env(s, 0.001, 0.05)), 0.6)), 0.5)
    # UI tap.
    s = n(0.05)
    write("ui_tap", mul(tone(s, 900, kind="tri"), env(s, 0.001, 0.045)), 0.3)
    # Toll: a bell (inharmonic partials, long decay).
    s = n(3.0)
    partials = [(1.0, 1.0), (2.0, 0.6), (2.4, 0.4), (3.0, 0.25), (4.2, 0.2), (5.4, 0.12)]
    write("toll", mix(*[gain(mul(tone(s, 110 * p), env(s, 0.002, 2.9 / (0.6 + p * 0.4))), a) for p, a in partials]), 0.8)
    # Solve chime: rising fifth on a small bell.
    s = n(1.2)
    write("solve", mix(mul(tone(s, 523), env(s, 0.003, 1.0)), gain(mul(tone(s, 784), [0] * n(0.12) + env(s - n(0.12), 0.003, 0.9)), 0.8),
                       gain(mul(tone(s, 1046), [0] * n(0.24) + env(s - n(0.24), 0.003, 0.8)), 0.5)), 0.6)
    # Frenzy sting: tearing noise + dissonant cluster + heartbeat slam.
    s = n(1.6)
    cluster = mix(*[gain(mul(tone(s, f, kind="tri", sweep=0.15), env(s, 0.02, 1.4)), 0.5) for f in (98, 104, 147, 156)])
    write("frenzy", mix(cluster, gain(mul(highpass(noise(s, rng), 0.5), env(s, 0.005, 0.6)), 0.9),
                        gain(mul(tone(s, 45, sweep=-0.3), env(s, 0.002, 0.4)), 1.5)), 0.95)
    # Heartbeat loop (1 s at 60 bpm): lub-dub.
    s = n(1.0)
    beat = [0.0] * s
    for start, f, amp in ((0.0, 55, 1.0), (0.22, 48, 0.7)):
        k = n(start)
        b = mul(tone(n(0.18), f), env(n(0.18), 0.005, 0.17))
        for i, v in enumerate(b):
            beat[k + i] += v * amp
    write("heartbeat", lowpass(beat, 0.3), 0.8)
    # Ambience loops (8 s).
    L = 8.0
    s = n(L + 0.5)
    room = lowpass(noise(s, rng), 0.02)
    write("amb_vault", seamless(gain(room, 1.0), 0.5), 0.25)
    wind_env = [0.55 + 0.45 * math.sin(2 * math.pi * i / (s - n(0.5)) * 2) ** 2 for i in range(s)]
    wind = mul(lowpass(highpass(noise(s, rng), 0.95), 0.12), wind_env)
    write("amb_marsh", seamless(wind, 0.5), 0.35)
    # Drones: frequencies are multiples of 1/L so the loop closes exactly.
    s = n(L)

    def drone(freqs):
        parts = []
        for f, a in freqs:
            fq = round(f * L) / L
            trem = [0.8 + 0.2 * math.sin(2 * math.pi * (1 / L) * 2 * i / RATE + f) for i in range(s)]
            parts.append(gain(mul(tone(s, fq, kind="tri"), trem), a))
        return lowpass(mix(*parts), 0.15)
    write("drone_vault", drone([(55.0, 1.0), (82.5, 0.6), (110.0, 0.4), (130.8, 0.3), (164.8, 0.2), (220.0, 0.12)]), 0.4)
    write("drone_marsh", drone([(49.0, 1.0), (73.5, 0.5), (98.0, 0.3), (116.5, 0.2)]), 0.35)
    print("wrote", len(os.listdir(OUT)), "files to", OUT)


if __name__ == "__main__":
    main()
