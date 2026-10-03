#!/usr/bin/env python3
"""Batch 3 listening sheet (AUDIO-BRIEF.md section 2, step 3).

Reads evidence/batch3-generation-log.json and the raw WAVs (read only), and writes
  evidence/batch3-listening.md           every take: file, length, peak, leading silence, SHA-256 check
  evidence/batch3-takes-waveforms.png    waveform contact sheet of all takes (7 sounds x 3 takes)
Facts only: no take is described as better or worse than another. Run in ~/Documents/jellyhop-audio-env.
"""
import hashlib, json, sys
from pathlib import Path

import numpy as np
import soundfile as sf
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

REPO = Path(__file__).resolve().parent.parent
LOG = REPO / "evidence" / "batch3-generation-log.json"
SHEET = REPO / "evidence" / "batch3-listening.md"
PNG = REPO / "evidence" / "batch3-takes-waveforms.png"
ORDER = ["SFX-HOP", "SFX-LAND", "SFX-WARN", "SFX-SPLAT-FORK", "SFX-SPLAT-SAUCE", "SFX-WIN", "MUS-LOOP"]
THRESHOLD_DB = -50.0   # the planned trim threshold (prompts file, "Planned edits")


def stop(msg):
    print(f"STOPPED: {msg}", file=sys.stderr)
    sys.exit(1)


def db(x):
    return 20 * np.log10(max(float(x), 1e-12))


def measure(path):
    audio, rate = sf.read(str(path), always_2d=True)
    mono_peak = np.abs(audio).max(axis=1)          # per-sample peak across channels
    peak = mono_peak.max()
    above = np.nonzero(mono_peak > 10 ** (THRESHOLD_DB / 20))[0]
    lead_ms = (above[0] / rate * 1000) if len(above) else float("nan")
    tail_ms = ((len(audio) - 1 - above[-1]) / rate * 1000) if len(above) else float("nan")
    rms = np.sqrt((audio ** 2).mean())
    return {"audio": audio, "rate": rate, "channels": audio.shape[1], "length_s": len(audio) / rate,
            "peak_dbfs": db(peak), "rms_dbfs": db(rms), "lead_ms": lead_ms, "tail_ms": tail_ms,
            "over_full_scale": bool(peak > 1.0)}


def main():
    if not LOG.exists():
        stop(f"{LOG} not found (run tools/batch3_generate.py first)")
    log = json.loads(LOG.read_text())
    takes = {t["take"]: t for t in log["takes"]}
    expected = [f"{sid}-take{n}" for sid in ORDER for n in (1, 2, 3)]
    missing = [t for t in expected if t not in takes]
    if missing:
        stop(f"takes missing from the log: {missing}")
    rows, results = [], {}
    for tid in expected:
        t = takes[tid]
        p = Path(t["file"])
        if not p.exists():
            stop(f"missing raw file {p}")
        h = hashlib.sha256(p.read_bytes()).hexdigest()
        if h != t["sha256"]:
            stop(f"{p.name}: SHA-256 differs from the generation log")
        m = measure(p)
        results[tid] = m
        rows.append((tid, t, p, m))

    # Contact sheet: one row per sound, one column per take, same time axis within a row.
    fig, axes = plt.subplots(len(ORDER), 3, figsize=(15, 2.1 * len(ORDER)), squeeze=False)
    for r, sid in enumerate(ORDER):
        row_len = max(results[f"{sid}-take{n}"]["length_s"] for n in (1, 2, 3))
        for c, n in enumerate((1, 2, 3)):
            tid = f"{sid}-take{n}"
            m, t = results[tid], takes[tid]
            ax = axes[r][c]
            a = m["audio"]
            x = np.arange(len(a)) / m["rate"]
            for ch in range(a.shape[1]):
                ax.plot(x, a[:, ch], linewidth=0.4, alpha=0.8)
            lim = max(1.0, np.abs(a).max())
            ax.axhline(1.0, color="red", linewidth=0.5, linestyle=":")
            ax.axhline(-1.0, color="red", linewidth=0.5, linestyle=":")
            ax.set_xlim(0, row_len)
            ax.set_ylim(-lim * 1.05, lim * 1.05)
            ax.set_title(f"{tid} (seed {t['seed']})  peak {m['peak_dbfs']:+.1f} dBFS  lead {m['lead_ms']:.0f} ms", fontsize=8)
            ax.tick_params(labelsize=6)
            if c == 0:
                ax.set_ylabel(sid, fontsize=8)
    fig.suptitle("Batch 3 raw takes: waveforms (dotted red = full scale; time in seconds)", fontsize=10)
    fig.tight_layout()
    fig.savefig(PNG, dpi=110)

    lines = [
        "# Batch 3 listening sheet",
        "",
        f"All {len(rows)} raw takes, as generated (no edits). Measured by `tools/batch3_listening.py`; every file's "
        "SHA-256 matches `evidence/batch3-generation-log.txt`. Facts only: the sheet does not rank or describe takes.",
        "",
        "- **Peak** is the highest sample across channels; values above 0 dBFS are kept because the raw files are "
        "32-bit float WAV (the planned edits level each pick to −1 dBFS).",
        f"- **Leading silence** is the time before the first sample above {THRESHOLD_DB:.0f} dBFS (the planned trim "
        f"threshold); **tail** is the time after the last one.",
        "- Waveforms of every take: `evidence/batch3-takes-waveforms.png`.",
        "",
        "## How to listen",
        "",
        "- **Finder:** open `~/Documents/jellyhop-generations/audio/` (Finder → Go → Go to Folder…, paste the path), "
        "select a file and press **Space** for Quick Look; press Space again to stop. The arrow keys move to the next file.",
        "- **Terminal:** `afplay ~/Documents/jellyhop-generations/audio/SFX-HOP-take1-seed7270.wav` plays one file.",
        "- For the music, also listen to whether a loop could be cut from it (the planned edit cuts whole bars, at least 8 s).",
        "",
        "## Takes",
        "",
        "| Take | Seed | File | Length | Rate, channels | Peak | RMS | Leading silence | Tail after last sound | Device, run time |",
        "|------|------|------|--------|----------------|------|-----|-----------------|-----------------------|------------------|",
    ]
    for tid, t, p, m in rows:
        lines.append(f"| {tid} | {t['seed']} | `{p.name}` | {m['length_s']:.2f} s | {m['rate']} Hz, {m['channels']} | "
                     f"{m['peak_dbfs']:+.1f} dBFS | {m['rms_dbfs']:.1f} dBFS | {m['lead_ms']:.0f} ms | {m['tail_ms']:.0f} ms | "
                     f"{t['device']}, {t['run_time_s']:.0f} s |")
    lines += [
        "",
        "## Your picks (to fill in)",
        "",
        "For each sound: the take you choose, and your reason in your own words. If every take of a sound fails, "
        "say so; a new prompt would be appended to the prompts file as a dated note and committed before use.",
        "",
        "| Sound | Pick (take 1, 2 or 3, or none) | Your reason |",
        "|-------|-------------------------------|-------------|",
    ]
    lines += [f"| {sid} | | |" for sid in ORDER]
    SHEET.write_text("\n".join(lines) + "\n")
    print(f"wrote {SHEET.relative_to(REPO)} and {PNG.relative_to(REPO)} ({len(rows)} takes)")


if __name__ == "__main__":
    main()
