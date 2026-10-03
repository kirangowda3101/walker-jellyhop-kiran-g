#!/usr/bin/env python3
"""Batch 3 quick checks on the game audio files (decoded, as the game receives them).
  - every sound effect starts within 10 ms (first sample above -50 dBFS)
  - every file peaks at or below -1 dBFS
  - loudness at target: sound effects -30.1 LUFS max momentary, music -40.1 LUFS integrated (+-0.5 LU)
  - the music imports with looping on (loop=true in its .import file)
  - every game file has a processing record in evidence/batch3-process-log.json with the same SHA-256
Exit 1 on any failure. Run in ~/Documents/jellyhop-audio-env:  python tools/check_game_audio.py
"""
import json, sys
from pathlib import Path
import numpy as np, soundfile as sf, pyloudnorm as pyln
sys.path.insert(0, str(Path(__file__).resolve().parent))
import batch3_compare as cmp
import batch3_process as proc

REPO = Path(__file__).resolve().parent.parent
GAME = REPO / "audio" / "game"
ids = ["SFX-HOP", "SFX-LAND", "SFX-WARN", "SFX-SPLAT-FORK", "SFX-SPLAT-SAUCE", "SFX-WIN", "MUS-LOOP"]
records = {}
for r in json.loads((REPO / "evidence" / "batch3-process-log.json").read_text())["records"]:
    # Match by the repo-relative path, so the check also works in a fresh clone at another location.
    if r["output"].endswith(f"/audio/game/{r['sound']}.ogg") and "superseded" not in r:
        records[r["sound"]] = r          # the latest record for each game file
fails, lines = [], []
for sid in ids:
    f = GAME / f"{sid}.ogg"
    if not f.exists():
        fails.append(f"{sid}: missing"); continue
    y, rate = sf.read(str(f), always_2d=True)
    env = np.abs(y).max(axis=1)
    above = np.nonzero(env > 10 ** (-50 / 20))[0]
    lead_ms = above[0] / rate * 1000 if len(above) else float("inf")
    peak = cmp.db(env.max())
    if sid == "MUS-LOOP":
        lufs, target = pyln.Meter(rate).integrated_loudness(y), proc.MUSIC_TARGET_LUFS_I
    else:
        lufs, target = cmp.max_momentary_lufs(y, rate), proc.SFX_TARGET_LUFS_M
    rec = records.get(sid)
    sha_ok = rec is not None and rec["output_sha256"] == cmp.sha256(f)
    ok_lead = sid == "MUS-LOOP" or lead_ms <= 10.0
    ok = ok_lead and peak <= -1.0 and abs(lufs - target) <= 0.5 and sha_ok
    lines.append(f"{'PASS' if ok else 'FAIL'} {sid}: take {rec['take'] if rec else '?'}, lead {lead_ms:.2f} ms, peak {peak:+.2f} dBFS, "
                 f"loudness {lufs:.2f} LUFS (target {target}), {len(y)/rate:.3f} s, {rate} Hz x{y.shape[1]}, process-log SHA match {sha_ok}")
    if not ok:
        fails.append(sid)
imp = (REPO / "godot" / "assets" / "audio" / "MUS-LOOP.ogg.import")
loop_on = imp.exists() and "loop=true" in imp.read_text().splitlines()
lines.append(f"{'PASS' if loop_on else 'FAIL'} MUS-LOOP imports with looping on (loop=true)")
if not loop_on:
    fails.append("music loop import")
print("\n".join(lines))
print(f"GAME AUDIO CHECKS: {len(ids) + 1} checks / {len(fails)} failures")
sys.exit(1 if fails else 0)
