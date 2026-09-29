"""Genera audio/vhs_fast_forward_loop.ogg: bucle de avance rápido de vídeo VHS.

Mezcla el zumbido del motor, el siseo de la cinta, el balbuceo agudo del audio
acelerado y los clics de las bobinas. El final se funde con el principio para
que el bucle no tenga saltos.

Uso: python tools/gen_vhs_ff_loop.py [ruta_ffmpeg]
"""

import math
import os
import random
import struct
import subprocess
import sys
import tempfile
import wave

SR = 44100
LOOP_SEC = 2.5
XFADE_SEC = 0.08
PEAK = 0.8
SEED = 1987
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "audio", "vhs_fast_forward_loop.ogg")


def cyclic_points(rng: random.Random, count: int, lo: float, hi: float) -> list[float]:
    return [rng.uniform(lo, hi) for _ in range(count)]


def cyclic_value(points: list[float], pos: float) -> float:
    base = math.floor(pos)
    i = int(base) % len(points)
    f = pos - base
    w = (1.0 - math.cos(f * math.pi)) * 0.5
    return points[i] + (points[(i + 1) % len(points)] - points[i]) * w


def render() -> list[float]:
    rng = random.Random(SEED)
    n_loop = int(SR * LOOP_SEC)
    n_fade = int(SR * XFADE_SEC)
    garble_a = cyclic_points(rng, 30, 700.0, 1700.0)
    garble_b = cyclic_points(rng, 40, 1400.0, 2900.0)
    syllables = [0.0 if rng.random() < 0.22 else rng.uniform(0.35, 1.0) for _ in range(50)]
    click_period = SR // 8

    hp_coef = math.exp(-2.0 * math.pi * 1500.0 / SR)
    lp_coef = math.exp(-2.0 * math.pi * 7000.0 / SR)
    phase_motor = phase_a = phase_b = 0.0
    hp_in = hp_out = lp = 0.0
    click_env = 0.0
    out: list[float] = []
    for i in range(n_loop + n_fade):
        t = i / SR
        loop_pos = (t % LOOP_SEC) / LOOP_SEC

        wow = 1.0 + 0.006 * math.sin(2.0 * math.pi * 0.8 * t)
        phase_motor += 2.0 * math.pi * 140.0 * wow / SR
        motor = sum(math.sin(phase_motor * h) / (h ** 1.2) for h in range(1, 8))
        reel = 1.0 - 0.22 * (0.5 + 0.5 * math.sin(2.0 * math.pi * 8.0 * t))
        motor *= 0.16 * reel

        white = rng.uniform(-1.0, 1.0)
        hp_out = hp_coef * (hp_out + white - hp_in)
        hp_in = white
        flutter = 1.0 - 0.2 * (0.5 + 0.5 * math.sin(2.0 * math.pi * 16.0 * t))
        hiss = hp_out * 0.07 * flutter

        phase_a += 2.0 * math.pi * cyclic_value(garble_a, loop_pos * len(garble_a)) / SR
        phase_b += 2.0 * math.pi * cyclic_value(garble_b, loop_pos * len(garble_b)) / SR
        syl_pos = loop_pos * len(syllables)
        syl_env = math.sin(math.pi * (syl_pos - math.floor(syl_pos))) ** 2
        env = syllables[int(syl_pos) % len(syllables)] * syl_env
        voice = (math.sin(phase_a) + 0.35 * math.sin(2.0 * phase_a) + 0.15 * math.sin(3.0 * phase_a)) * 0.10
        voice += (math.sin(phase_b) + 0.25 * math.sin(2.0 * phase_b)) * 0.05
        voice *= env

        if i % click_period == 0:
            click_env = 1.0
        click = rng.uniform(-1.0, 1.0) * click_env * 0.035
        click_env *= 0.992

        lp = (1.0 - lp_coef) * (motor + hiss + voice + click) + lp_coef * lp
        out.append(lp)

    loop = out[:n_loop]
    for i in range(n_fade):
        w = i / n_fade
        loop[i] = out[i] * math.sqrt(w) + out[n_loop + i] * math.sqrt(1.0 - w)
    return loop


def write_wav(path: str, samples: list[float]) -> None:
    peak = max(abs(s) for s in samples) or 1.0
    scale = PEAK / peak
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples
    )
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(frames)


def main() -> None:
    ffmpeg = sys.argv[1] if len(sys.argv) > 1 else "ffmpeg"
    samples = render()
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, "vhs_ff.wav")
        write_wav(wav_path, samples)
        subprocess.run(
            [ffmpeg, "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "5", OUT],
            check=True,
        )
    print(f"{OUT} ({LOOP_SEC:.2f} s, {SR} Hz)")


if __name__ == "__main__":
    main()
