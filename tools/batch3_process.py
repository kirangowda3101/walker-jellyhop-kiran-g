#!/usr/bin/env python3
"""Batch 3 step 4: process a picked take into a game-ready OGG Vorbis file.

Planned edits (gen-inputs/batch3-audio-prompts.md, with the 2026-10-03 leveling note), gain only:
  sound effects: trim leading silence at -50 dBFS (no fade-in), trim the tail below -50 dBFS with a 15 ms
                 linear fade-out, gain to the fixed loudness target (-30.1 LUFS maximum momentary); the leading
                 trim is then repeated at the delivered level (after the gain) and the gain re-measured once
  music:         a loop of whole bars (>= 8 s) at the best-measured seam, the shortest crossfade that passes the
                 seam measurement, gain to -40.1 LUFS integrated
Every output must peak at or below -1 dBFS after decoding. Raw files are read only (SHA-256 checked).

  python tools/batch3_process.py --provisional          the shortlist -> audio/game/, plus take 3's music loop
                                                         -> ~/Documents/jellyhop-generations/audio-game-alt/
  python tools/batch3_process.py --sound SFX-HOP --take 2 [--alt]
                                                         one take -> audio/game/<ID>.ogg (or the alt folder)
Log: evidence/batch3-process-log.txt (+ .json), appended, so every swap keeps its record.
"""
import argparse, json, math, sys
from datetime import datetime
from pathlib import Path

import numpy as np
import soundfile as sf
import pyloudnorm as pyln

sys.path.insert(0, str(Path(__file__).resolve().parent))
import batch3_compare as cmp  # same trim, loudness, loop and seam code as the comparison files

REPO = Path(__file__).resolve().parent.parent
GEN_LOG = REPO / "evidence" / "batch3-generation-log.json"
GAME_DIR = REPO / "audio" / "game"
ALT_DIR = Path.home() / "Documents" / "jellyhop-generations" / "audio-game-alt"
LOG_TXT = REPO / "evidence" / "batch3-process-log.txt"
LOG_JSON = REPO / "evidence" / "batch3-process-log.json"

SFX_TARGET_LUFS_M = -30.1     # fixed (prompts file note, 2026-10-03): all 18 takes stay <= -1 dBFS
MUSIC_TARGET_LUFS_I = -40.1   # 10 LU below the sound effects (Claude's proposal; Kiran judges in the game)
PEAK_CEILING_DB = -1.0
OGG_COMPRESSION_LEVEL = 0.1   # libsndfile Vorbis: 0 = highest quality, 1 = smallest file
SHORTLIST = {"SFX-HOP": 3, "SFX-LAND": 2, "SFX-WARN": 1, "SFX-SPLAT-FORK": 3, "SFX-SPLAT-SAUCE": 2, "SFX-WIN": 3, "MUS-LOOP": 1}


def stop(msg):
    print(f"STOPPED: {msg}", file=sys.stderr)
    sys.exit(1)


def decoded_facts(path, rate_expected):
    y, rate = sf.read(str(path), always_2d=True)
    env = np.abs(y).max(axis=1)
    above = np.nonzero(env > 10 ** (cmp.THRESHOLD_DB / 20))[0]
    return y, {"decoded_rate": rate, "decoded_channels": y.shape[1], "decoded_length_s": round(len(y) / rate, 4),
               "decoded_peak_dbfs": round(cmp.db(env.max()), 2),
               "decoded_lead_silence_ms": round(above[0] / rate * 1000, 2) if len(above) else None,
               "rate_ok": rate == rate_expected}


def process(sound, take, dest, takes):
    tid = f"{sound}-take{take}"
    t = takes.get(tid) or stop(f"unknown take {tid}")
    if cmp.sha256(t["file"]) != t["sha256"]:
        stop(f"{tid}: raw file differs from the generation log")
    raw, rate = sf.read(t["file"], always_2d=True)
    rec = {"time": datetime.now().isoformat(timespec="seconds"), "sound": sound, "take": take, "seed": t["seed"],
           "source": t["file"], "source_sha256": t["sha256"], "output": str(dest),
           "raw_peak_dbfs": round(cmp.db(np.abs(raw).max()), 2), "ogg_compression_level": OGG_COMPRESSION_LEVEL}
    if sound == "MUS-LOOP":
        y = raw[:, 0]
        lc = cmp.loop_candidate(y, rate)
        s, e = int(round(lc["chosen"]["start_s"] * rate)), int(round(lc["chosen"]["end_s"] * rate))
        loop, seam = cmp.build_loop(y, rate, s, e)
        lufs = pyln.Meter(rate).integrated_loudness(loop[:, None])
        gain = MUSIC_TARGET_LUFS_I - lufs
        out = (loop * 10 ** (gain / 20))[:, None]
        rec.update({"edit": "loop", "tempo_bpm": lc["tempo_bpm"], "beats_tracked": lc["beats_tracked"], "bar_s": lc["bar_s"],
                    "bars": lc["bars"], "beats_per_bar_assumed": lc["beats_per_bar_assumed"],
                    "loop_start_s": lc["chosen"]["start_s"], "loop_end_s": lc["chosen"]["end_s"], "loop_start_beat": lc["chosen"]["start_beat"],
                    "seam_mel_distance": lc["chosen"]["seam_mel_distance"], "candidates_tried": len(lc["candidates"]), **seam,
                    "loudness_method": "BS.1770-4 integrated", "loudness_before_lufs": round(lufs, 2),
                    "target_lufs": MUSIC_TARGET_LUFS_I, "gain_db": round(gain, 2)})
    else:
        trimmed, trim = cmp.trim_sfx(raw, rate)
        lufs = cmp.max_momentary_lufs(trimmed, rate)
        gain = SFX_TARGET_LUFS_M - lufs
        # The leading trim applies at the delivered level: after the gain, anything still below -50 dBFS
        # at the start is leading silence in the game file. Trim it (no fade-in), then measure and gain again.
        env = np.abs(trimmed).max(axis=1) * 10 ** (gain / 20)
        first = int(np.nonzero(env > 10 ** (cmp.THRESHOLD_DB / 20))[0][0])
        trimmed = trimmed[first:]
        lufs2 = cmp.max_momentary_lufs(trimmed, rate)
        gain2 = SFX_TARGET_LUFS_M - lufs2
        out = trimmed * 10 ** (gain2 / 20)
        rec.update({"edit": "trim+gain", **trim, "trim_threshold_dbfs": cmp.THRESHOLD_DB, "fade_shape": "linear",
                    "lead_trim_at_delivered_level_extra_ms": round(first / rate * 1000, 2),
                    "kept_ms": round(len(trimmed) / rate * 1000, 2),
                    "trimmed_peak_dbfs": round(cmp.db(np.abs(trimmed).max()), 2),
                    "loudness_method": "BS.1770 K-weighted maximum momentary (400 ms)",
                    "loudness_before_lufs": round(lufs, 2), "loudness_after_delivered_trim_lufs": round(lufs2, 2),
                    "target_lufs": SFX_TARGET_LUFS_M, "gain_db": round(gain2, 2)})
    rec["peak_before_encode_dbfs"] = round(cmp.db(np.abs(out).max()), 2)
    if rec["peak_before_encode_dbfs"] > PEAK_CEILING_DB:
        stop(f"{tid}: peak {rec['peak_before_encode_dbfs']} dBFS before encoding exceeds the ceiling")
    dest.parent.mkdir(parents=True, exist_ok=True)
    previous = cmp.sha256(dest) if dest.exists() else None
    tmp = dest.with_suffix(".tmp.ogg")
    sf.write(str(tmp), out.astype(np.float32), rate, format="OGG", subtype="VORBIS", compression_level=OGG_COMPRESSION_LEVEL)
    dec, facts = decoded_facts(tmp, rate)
    rec.update(facts)
    if sound == "MUS-LOOP":
        rec["decoded_loudness_lufs"] = round(pyln.Meter(rate).integrated_loudness(dec), 2)
        d = np.abs(np.diff(dec[:, 0]))
        rec["decoded_seam_jump"] = round(abs(float(dec[-1, 0]) - float(dec[0, 0])), 6)
        rec["decoded_neighbour_jump_p95"] = round(float(np.percentile(d, 95)), 6)
    else:
        rec["decoded_loudness_lufs"] = round(cmp.max_momentary_lufs(dec, rate), 2)
    if facts["decoded_peak_dbfs"] > PEAK_CEILING_DB:
        tmp.unlink()
        stop(f"{tid}: decoded peak {facts['decoded_peak_dbfs']} dBFS exceeds the ceiling")
    tmp.replace(dest)
    rec["output_sha256"] = cmp.sha256(dest)
    rec["replaced_sha256"] = previous
    if cmp.sha256(t["file"]) != t["sha256"]:
        stop(f"{tid}: raw file changed during processing")
    rec["raw_sha256_unchanged_after"] = True
    return rec


def write_logs(recs):
    hist = json.loads(LOG_JSON.read_text()) if LOG_JSON.exists() else {"records": []}
    hist["records"].extend(recs)
    LOG_JSON.write_text(json.dumps(hist, indent=2) + "\n")
    with open(LOG_TXT, "a") as f:
        for r in recs:
            f.write(f"== {r['time']}  {r['sound']} take {r['take']} (seed {r['seed']}) -> {r['output']}\n")
            for k, v in r.items():
                if k not in ("time", "sound", "take", "seed", "output", "crossfade_trials"):
                    f.write(f"   {k}: {v}\n")
            for row in r.get("crossfade_trials", []):
                f.write(f"   crossfade trial {row['crossfade_ms']} ms: seam jump {row['seam_jump']}, "
                        f"crossfade-region max jump {row['crossfade_region_max_jump']}, passes {row['passes']}\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--provisional", action="store_true")
    ap.add_argument("--sound")
    ap.add_argument("--take", type=int, choices=[1, 2, 3])
    ap.add_argument("--alt", action="store_true", help="write to the alternatives folder outside the repo")
    args = ap.parse_args()
    takes = {t["take"]: t for t in json.loads(GEN_LOG.read_text())["takes"]}
    jobs = []
    if args.provisional:
        jobs = [(s, n, GAME_DIR / f"{s}.ogg") for s, n in SHORTLIST.items()]
        jobs.append(("MUS-LOOP", 3, ALT_DIR / "MUS-LOOP-take3.ogg"))
    elif args.sound and args.take:
        if args.sound not in SHORTLIST:
            stop(f"unknown sound {args.sound}")
        jobs = [(args.sound, args.take, (ALT_DIR / f"{args.sound}-take{args.take}.ogg") if args.alt else GAME_DIR / f"{args.sound}.ogg")]
    else:
        stop("use --provisional, or --sound ID --take N")
    recs = [process(s, n, d, takes) for s, n, d in jobs]
    write_logs(recs)
    for r in recs:
        extra = (f"loop {r['loop_start_s']}-{r['loop_end_s']} s ({r['bars']} bars at {r['tempo_bpm']} bpm), crossfade {r['crossfade_ms']} ms"
                 if r["sound"] == "MUS-LOOP" else f"lead trim {r['lead_trim_ms']} + {r['lead_trim_at_delivered_level_extra_ms']} ms, kept {r['kept_ms']} ms")
        print(f"{r['sound']} take {r['take']} -> {r['output']}: {extra}; gain {r['gain_db']:+.2f} dB; "
              f"decoded peak {r['decoded_peak_dbfs']:+.2f} dBFS, loudness {r['decoded_loudness_lufs']} LUFS, "
              f"lead silence {r['decoded_lead_silence_ms']} ms")


if __name__ == "__main__":
    main()
