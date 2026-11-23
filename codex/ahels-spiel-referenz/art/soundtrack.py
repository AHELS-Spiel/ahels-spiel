"""Render the AHELS Arena instrumental loops from the score below.

Run with NumPy and FFmpeg installed. The score and synthesis use original
material. The game ships the rendered Ogg files and has no Python dependency.
"""
from dataclasses import dataclass
from pathlib import Path
import subprocess

import numpy as np

RATE = 32_000
TAU = 2.0 * np.pi
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


@dataclass(frozen=True)
class Score:
    bpm: int
    roots: tuple[int, ...]
    melody: tuple[tuple[int, int, int], ...]
    kicks: tuple[int, ...]
    snares: tuple[int, ...]
    bass: tuple[tuple[int, int, int], ...]
    growl: float = 0.0


TRACKS = {
    "lobby": Score(
        112, (45, 41, 48, 43),
        ((0, 12, 4), (5, 19, 3), (9, 15, 3), (12, 14, 3)),
        (0, 6, 10), (4, 12), ((0, 0, 5), (7, 0, 3), (11, 7, 4)),
    ),
    "arena": Score(
        158, (38, 34, 43, 36),
        ((0, 24, 2), (3, 31, 3), (7, 27, 2), (10, 34, 3), (14, 29, 2)),
        (0, 7, 10), (4, 12), ((0, 0, 3), (3, 0, 3), (7, 12, 2), (10, 0, 3), (14, 7, 2)), 0.48,
    ),
    "pressure": Score(
        174, (38, 41, 43, 34),
        ((0, 31, 2), (2, 24, 2), (6, 27, 2), (9, 29, 3), (13, 34, 2)),
        (0, 6, 10, 14), (4, 12), ((0, 0, 2), (2, 12, 2), (5, 0, 2), (8, 7, 2), (11, 0, 4)), 0.72,
    ),
    "finale": Score(
        166, (42, 38, 47, 40),
        ((0, 24, 3), (4, 31, 3), (7, 30, 2), (10, 27, 3), (14, 36, 2)),
        (0, 3, 8, 10), (4, 12), ((0, 0, 3), (3, 0, 2), (6, 7, 2), (8, 0, 3), (13, 6, 3)), 0.85,
    ),
}


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def time(seconds):
    return np.arange(round(seconds * RATE), dtype=np.float64) / RATE


def note(t, duration, attack=0.012, release=0.064):
    return np.clip(t / attack, 0, 1) * np.clip((duration - t) / release, 0, 1)


def mix_at(track, start, signal, volume, pan=0.0):
    indices = (int(round(start * RATE)) + np.arange(len(signal))) % len(track)
    track[indices, 0] += signal * volume * np.sqrt((1.0 - pan) / 2.0)
    track[indices, 1] += signal * volume * np.sqrt((1.0 + pan) / 2.0)


def add_drums(track, score, position, sixteenth, bar, rng):
    for beat in score.kicks:
        t = time(0.25)
        phase = TAU * (48 * t + 54 * (1 - np.exp(-t * 51)) / 51)
        kick = np.sin(phase) * np.exp(-t * 12) * np.minimum(1, t * 1050)
        click = rng.uniform(-1, 1, len(t)) * np.exp(-t * 340)
        mix_at(track, position + sixteenth * beat, kick + 0.13 * click, 0.50)
    for beat in score.snares:
        t = time(0.19)
        noise = rng.uniform(-1, 1, len(t))
        body = 0.36 * np.sin(TAU * (171 * t - 70 * t**2)) * np.exp(-t * 38)
        snap = np.diff(noise, prepend=0) * np.exp(-t * 22)
        mix_at(track, position + sixteenth * beat, body + 0.34 * snap, 0.36, 0.11)
    for beat in range(16):
        if score.growl == 0.0 and beat % 2 == 1:
            continue
        open_hat = beat in (2, 10)
        t = time(0.15 if open_hat else 0.07)
        cymbal = np.diff(rng.uniform(-1, 1, len(t)), prepend=0) * np.exp(-t * (29 if open_hat else 72))
        accent = (0.85 if beat % 4 == 2 else 0.50) * (1.18 if bar % 4 == 3 else 1.0)
        mix_at(track, position + sixteenth * beat + 0.007 * (beat % 2), cymbal,
               0.12 * accent, -0.32 if beat % 2 else 0.38)


def add_bass(track, score, position, step, root):
    for beat, semitone, count in score.bass:
        duration = step * count
        t = time(duration)
        phase = TAU * hz(root + semitone) * t
        sub = np.sin(phase) + (0.22 + 0.27 * score.growl) * np.sin(phase * 2)
        reese = np.tanh(1.8 * (np.sin(phase * 2.014) + 0.42 * np.sin(phase * 2.957)))
        groove = 0.61 + 0.39 * np.sin(TAU * t / max(0.18, 4 * step) - np.pi / 2.0)**2
        wave = (sub * 0.61 + reese * 0.45 * score.growl) * groove * note(t, duration)
        mix_at(track, position + step * beat + 0.012, wave, 0.34)


def add_harmony(track, score, position, step, bar, root):
    minor = bar % 4 in (0, 2) or score.growl == 0.85
    third = 3 if minor else 4
    duration = step * (13 if bar % 4 == 3 else 16)
    t = time(duration)
    for voice, offset in enumerate((12, 12 + third, 19, 24)):
        phase = TAU * hz(root + offset) * t
        pad = np.sin(phase * 1.001) + 0.25 * np.sin(phase * 2 + 0.82 * np.sin(phase * 0.999))
        breathing = 0.72 + 0.28 * np.cos(TAU * t / (8 * step) + voice * 0.6)
        mix_at(track, position, pad * note(t, duration, 0.09, 0.16) * breathing,
               0.052 - voice * 0.007, (voice - 1.5) * 0.32)

    for position_in_bar, semitone, count in score.melody:
        if bar < 2 and position_in_bar in (3, 7, 9, 13):
            continue
        if bar in (8, 9) and position_in_bar > 5:
            continue
        duration = count * step
        start = position + position_in_bar * step
        t = time(duration)
        melody_interval = 2 if bar % 8 in (6, 7) and position_in_bar >= 10 else 0
        phase = TAU * hz(root + semitone + melody_interval) * t
        tone = np.sin(phase + 0.69 * np.sin(phase * 2.0) * np.exp(-t * 5))
        overtone = 0.26 * np.sin(phase * 3.004) * np.exp(-t * 11)
        lead = (tone + overtone) * note(t, duration, 0.008, 0.075)
        mix_at(track, start, lead, 0.13, -0.12)
        mix_at(track, start + step * 3, lead, 0.039, 0.68)
        mix_at(track, start + step * 6, lead, 0.020, -0.72)


def render(score, seed, bars=16):
    rng = np.random.default_rng(seed)
    step = 60.0 / (score.bpm * 4)
    track = np.zeros((int(round(bars * step * 16 * RATE)), 2), dtype=np.float64)
    for bar in range(bars):
        position = bar * step * 16
        root = score.roots[bar % len(score.roots)]
        add_drums(track, score, position, step, bar, rng)
        add_bass(track, score, position, step, root)
        add_harmony(track, score, position, step, bar, root)
    limited = np.tanh(track * 1.72)
    return (0.91 * limited / np.max(np.abs(limited))).astype("<f4")


def write_ogg(target, stereo):
    subprocess.run([
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "f32le",
        "-ar", str(RATE), "-ac", "2", "-i", "-", "-c:a", "libvorbis", "-q:a", "5", target,
    ], input=stereo.tobytes(), check=True)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for index, (name, score) in enumerate(TRACKS.items()):
        write_ogg(OUTPUT / f"{name}.ogg", render(score, 521 + index))
