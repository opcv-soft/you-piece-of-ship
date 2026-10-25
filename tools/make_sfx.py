"""Sound effects, synthesised from scratch (original, no samples): breaking things, cannons, the
engine, pirate fuses. Run: python3 tools/make_sfx.py -> assets/audio/sfx/*.wav (the engine hum loops)."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets/audio/sfx"
random.seed(7)


def save(name, samples, gain=0.85):
    peak = max(abs(s) for s in samples) or 1.0
    with wave.open(str(OUT / (name + ".wav")), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * gain * 32767)) for s in samples))


def noise(n):
    return [random.uniform(-1, 1) for _ in range(n)]


def lowpass(x, cutoff):
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    y, out = 0.0, []
    for s in x:
        y += a * (s - y)
        out.append(y)
    return out


def env(n, attack, decay):
    return [min(1.0, i / max(1, attack * RATE)) * math.exp(-i / (decay * RATE)) for i in range(n)]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0.0 for t in tracks) for i in range(n)]


def tone(freq_fn, n, wave_fn=math.sin):
    phase, out = 0.0, []
    for i in range(n):
        phase += 2 * math.pi * freq_fn(i / RATE) / RATE
        out.append(wave_fn(phase))
    return out


def rock_crack():
    n = int(RATE * 0.9)
    crunch = [s * e for s, e in zip(lowpass(noise(n), 1800), env(n, 0.002, 0.18))]
    crackles = [0.0] * n
    for k in range(18):  # little stone fragments
        start = int(random.uniform(0.0, 0.5) * RATE)
        for i in range(int(0.02 * RATE)):
            if start + i < n:
                crackles[start + i] += random.uniform(-1, 1) * math.exp(-i / (0.004 * RATE)) * 0.8
    thump = [s * e for s, e in zip(tone(lambda t: 70 - 30 * t, n), env(n, 0.001, 0.15))]
    save("rock_crack", mix(crunch, crackles, thump))


def wood_splinter():
    n = int(RATE * 0.8)
    snap = [s * e for s, e in zip(noise(n), env(n, 0.0005, 0.05))]
    creak = [s * e * 0.6 for s, e in zip(tone(lambda t: 220 + 400 * t, n, lambda p: (p % (2 * math.pi)) / math.pi - 1), env(n, 0.01, 0.12))]
    body = [s * e for s, e in zip(lowpass(noise(n), 900), env(n, 0.002, 0.25))]
    save("wood_splinter", mix(snap, creak, body))


def barrel_burst():
    n = int(RATE * 1.2)
    thump = [s * e for s, e in zip(tone(lambda t: 110 - 60 * t, n), env(n, 0.001, 0.12))]
    splinter = [s * e * 0.7 for s, e in zip(lowpass(noise(n), 2500), env(n, 0.001, 0.1))]
    coins = [0.0] * n
    for k in range(14):  # gold spilling out
        start = int((0.12 + k * 0.045 + random.uniform(0, 0.02)) * RATE)
        f = random.uniform(2400, 3600)
        for i in range(int(0.12 * RATE)):
            if start + i < n:
                coins[start + i] += math.sin(2 * math.pi * f * i / RATE) * math.exp(-i / (0.03 * RATE)) * 0.35
    save("barrel_burst", mix(thump, splinter, coins))


def siren_shriek():
    n = int(RATE * 1.4)
    wail = [s * e for s, e in zip(tone(lambda t: 1100 - 500 * t + 40 * math.sin(t * 40), n), env(n, 0.03, 0.6))]
    breath = [s * e * 0.2 for s, e in zip(lowpass(noise(n), 4000), env(n, 0.02, 0.4))]
    save("siren_shriek", mix(wail, breath))


def whale_moan():
    n = int(RATE * 2.0)
    moan = [s * e for s, e in zip(tone(lambda t: 90 + 60 * math.sin(t * 2.2) + 20 * t, n), env(n, 0.2, 0.9))]
    over = [s * e * 0.4 for s, e in zip(tone(lambda t: 180 + 120 * math.sin(t * 2.2), n), env(n, 0.3, 0.7))]
    save("whale_moan", mix(moan, over))


def cannon_fire():
    n = int(RATE * 1.3)
    boom = [s * e for s, e in zip(tone(lambda t: 60 * math.exp(-t * 3) + 30, n), env(n, 0.001, 0.35))]
    blast = [s * e for s, e in zip(lowpass(noise(n), 1200), env(n, 0.001, 0.2))]
    save("cannon_fire", mix(boom, blast), 0.95)


def cannon_impact():
    n = int(RATE * 1.0)
    thud = [s * e for s, e in zip(tone(lambda t: 80 - 40 * t, n), env(n, 0.001, 0.12))]
    crack = [s * e * 0.8 for s, e in zip(noise(n), env(n, 0.0005, 0.04))]
    splash = [s * e * 0.5 for s, e in zip(lowpass(noise(n), 3000), env(n, 0.05, 0.3))]
    save("cannon_impact", mix(thud, crack, splash))


def engine_start():
    n = int(RATE * 1.6)
    out = [0.0] * n
    t, gap = 0.05, 0.28
    while t < 1.4:  # chug... chug.. chug.chug-chug
        start = int(t * RATE)
        for i in range(int(0.12 * RATE)):
            if start + i < n:
                out[start + i] += math.sin(2 * math.pi * 55 * i / RATE) * math.exp(-i / (0.04 * RATE))
                out[start + i] += random.uniform(-0.3, 0.3) * math.exp(-i / (0.02 * RATE))
        t += gap
        gap = max(0.07, gap * 0.78)
    save("engine_start", lowpass(out, 1500))


def engine_hum():
    """A one-second chugging loop (seamless): the game raises its pitch with speed."""
    n = RATE
    out = []
    for i in range(n):
        t = i / RATE
        pulse = 0.5 + 0.5 * math.sin(2 * math.pi * 8 * t)  # 8 chugs a second
        out.append((math.sin(2 * math.pi * 48 * t) * 0.7 + math.sin(2 * math.pi * 96 * t) * 0.3) * (0.4 + 0.6 * pulse ** 3))
    rough = lowpass(noise(n), 400)
    save("engine_hum", [a + b * 0.25 for a, b in zip(out, rough)], 0.6)


def splash():
    n = int(RATE * 0.8)
    save("splash", [s * e for s, e in zip(lowpass(noise(n), 2800), env(n, 0.01, 0.2))])


def fuse_hiss():
    """Pirates taking aim: two seconds of fizzing fuses that crackle harder toward the shot."""
    n = int(RATE * 2.0)
    hiss = [s * (0.35 + 0.65 * i / n) for i, s in enumerate(noise(n))]
    hiss = [a - b for a, b in zip(hiss, lowpass(hiss, 2500))]  # high-passed: a thin fizz, not a rumble
    pops = [0.0] * n
    for _ in range(40):
        at = int(random.uniform(0.0, 1.0) ** 0.6 * (n - 400))  # more pops near the end
        for k in range(300):
            pops[at + k] += random.uniform(-1, 1) * math.exp(-k / 40)
    fade = [min(1.0, i / (0.05 * RATE), (n - i) / (0.03 * RATE)) for i in range(n)]
    save("fuse_hiss", [(h + p * 0.6) * f for h, p, f in zip(hiss, pops, fade)], 0.6)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for make in (rock_crack, wood_splinter, barrel_burst, siren_shriek, whale_moan, cannon_fire, cannon_impact,
                 engine_start, engine_hum, splash, fuse_hiss):
        make()
    print("sounds made in", OUT)
