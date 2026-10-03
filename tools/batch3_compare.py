#!/usr/bin/env python3
"""Batch 3 comparison audio (for Kiran's listening only; nothing here goes into the repo or the game).

Reads the 21 raw takes (read only; SHA-256 checked against evidence/batch3-generation-log.json before
and after) and writes loudness-matched comparison copies to ~/Documents/jellyhop-generations/audio-compare/:
  <TAKE>-compare.wav           every take, trimmed and loudness-matched within its group
  MUS-LOOP-take<N>-loop-x3.wav  a candidate loop (whole bars, >= 8 s) of each music take, played 3 times
Every setting and measurement goes to evidence/batch3-compare-log.txt (+ .json).
Run in ~/Documents/jellyhop-audio-env:  python tools/batch3_compare.py [--overwrite]
"""
import argparse, hashlib, json, math, sys
from datetime import datetime
from pathlib import Path

import numpy as np
import soundfile as sf
import librosa
import pyloudnorm as pyln

REPO = Path(__file__).resolve().parent.parent
GEN_LOG = REPO / "evidence" / "batch3-generation-log.json"
OUT = Path.home() / "Documents" / "jellyhop-generations" / "audio-compare"
LOG_TXT = REPO / "evidence" / "batch3-compare-log.txt"
LOG_JSON = REPO / "evidence" / "batch3-compare-log.json"

SFX = ["SFX-HOP", "SFX-LAND", "SFX-WARN", "SFX-SPLAT-FORK", "SFX-SPLAT-SAUCE", "SFX-WIN"]
THRESHOLD_DB = -50.0          # planned trim threshold (prompts file, "Planned edits")
FADE_OUT_MS = 15.0            # the planned "short fade-out" (Claude's value for the comparison copies)
PEAK_CEILING_DB = -1.0        # no comparison file may exceed this sample peak
MOMENTARY_S = 0.400           # EBU R128 / Tech 3341 momentary window
HOP_S = 0.010                 # momentary measurement hop
MIN_LOOP_S = 8.0              # prompts file: a loop of whole bars, at least 8 s
BEATS_PER_BAR = 4             # assumption: 4/4 (the prompt asks for a steady 100 bpm loop)
XFADE_CANDIDATES_MS = [0, 2, 5, 10, 20, 40, 80]
SEAM_WINDOW_S = 0.200         # window compared after the loop end and after the loop start


def stop(msg):
    print(f"STOPPED: {msg}", file=sys.stderr)
    sys.exit(1)


def db(x):
    return 20 * math.log10(max(float(x), 1e-12))


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def k_weight(audio, rate):
    """BS.1770 K-weighting (pyloudnorm's filter stages), per channel."""
    meter = pyln.Meter(rate)
    out = audio.copy()
    for stage in meter._filters.values():
        for ch in range(out.shape[1]):
            out[:, ch] = stage.apply_filter(out[:, ch])
    return out


def max_momentary_lufs(audio, rate):
    """Maximum momentary loudness (BS.1770 K-weighting, 400 ms window, 10 ms hop, channel weights 1).
    The clip is followed by 400 ms of silence so a clip shorter than the window is still measured whole."""
    padded = np.vstack([audio, np.zeros((int(MOMENTARY_S * rate), audio.shape[1]))])
    kw = k_weight(padded, rate)
    win, hop = int(MOMENTARY_S * rate), int(HOP_S * rate)
    power = np.cumsum(np.vstack([np.zeros((1, kw.shape[1])), kw ** 2]), axis=0)
    best = -np.inf
    for start in range(0, len(kw) - win + 1, hop):
        ms = (power[start + win] - power[start]) / win          # mean square per channel
        z = ms.sum()
        if z > 0:
            best = max(best, -0.691 + 10 * math.log10(z))
    return best


def trim_sfx(audio, rate):
    env = np.abs(audio).max(axis=1)
    above = np.nonzero(env > 10 ** (THRESHOLD_DB / 20))[0]
    first, last = int(above[0]), int(above[-1])
    out = audio[first:last + 1].copy()
    n = min(len(out), int(round(FADE_OUT_MS / 1000 * rate)))
    out[-n:] *= np.linspace(1.0, 0.0, n)[:, None]             # linear fade-out; no fade-in
    return out, {"lead_trim_ms": round(first / rate * 1000, 2), "tail_trim_ms": round((len(audio) - 1 - last) / rate * 1000, 2),
                 "kept_ms": round(len(out) / rate * 1000, 2), "fade_out_ms": round(n / rate * 1000, 2), "fade_in_ms": 0}


def loop_candidate(y, rate):
    """Beat-track the take, then pick the whole-bar loop (>= 8 s) whose seam is most similar, by log-mel
    distance between the 200 ms after the loop end and the 200 ms after the loop start."""
    tempo, frames = librosa.beat.beat_track(y=y, sr=rate, units="samples")
    beats = np.asarray(frames, dtype=int)
    tempo = float(np.atleast_1d(tempo)[0])
    if len(beats) < 2 * BEATS_PER_BAR:
        stop("too few beats tracked")
    bar_s = BEATS_PER_BAR * float(np.median(np.diff(beats))) / rate
    n_bars = math.ceil(MIN_LOOP_S / bar_s)
    span = n_bars * BEATS_PER_BAR
    win = int(SEAM_WINDOW_S * rate)
    mel = lambda seg: np.log(librosa.feature.melspectrogram(y=seg, sr=rate, n_fft=1024, hop_length=256, n_mels=40) + 1e-9)
    tries = []
    for k in range(0, len(beats) - span, BEATS_PER_BAR):      # bar 1 = first tracked beat (downbeat phase assumed)
        s, e = int(beats[k]), int(beats[k + span])
        if e + win + int(max(XFADE_CANDIDATES_MS) / 1000 * rate) > len(y):
            continue
        d = float(np.mean(np.abs(mel(y[e:e + win]) - mel(y[s:s + win]))))
        tries.append({"start_beat": k, "start_s": round(s / rate, 3), "end_s": round(e / rate, 3), "seam_mel_distance": round(d, 4)})
    if not tries:
        stop("no loop candidate fits in the take")
    best = min(tries, key=lambda t: t["seam_mel_distance"])
    return {"tempo_bpm": round(tempo, 2), "beats_tracked": len(beats), "bar_s": round(bar_s, 4), "bars": n_bars,
            "beats_per_bar_assumed": BEATS_PER_BAR, "candidates": tries, "chosen": best}


def build_loop(y, rate, start, end):
    """Loop [start, end); the first X samples crossfade from y[end:end+X] (fading out) into y[start:start+X]
    (fading in), so the loop's last sample is followed by its natural continuation. The shortest X whose seam
    jump and crossfade region stay within the loop's own sample-to-sample differences is used."""
    body = y[start:end]
    d = np.abs(np.diff(body))
    p95, p999, med = float(np.percentile(d, 95)), float(np.percentile(d, 99.9)), float(np.median(d))
    rows, chosen = [], None
    for ms in XFADE_CANDIDATES_MS:
        n = int(round(ms / 1000 * rate))
        loop = body.copy()
        if n:
            ramp = np.linspace(0.0, 1.0, n)
            loop[:n] = y[end:end + n] * (1 - ramp) + y[start:start + n] * ramp
        seam = abs(float(loop[-1]) - float(loop[0]))
        region = np.abs(np.diff(np.concatenate([[loop[-1]], loop[:max(n, 1) + 1]])))
        ok = seam <= p95 and float(region.max()) <= p999
        rows.append({"crossfade_ms": ms, "seam_jump": round(seam, 6), "crossfade_region_max_jump": round(float(region.max()), 6), "passes": ok})
        if ok and chosen is None:
            chosen = (ms, loop)
    if chosen is None:
        chosen = (XFADE_CANDIDATES_MS[-1], loop)
    return chosen[1], {"neighbour_jump_median": round(med, 6), "neighbour_jump_p95": round(p95, 6), "neighbour_jump_p99_9": round(p999, 6),
                       "crossfade_trials": rows, "crossfade_ms": chosen[0], "loop_s": round(len(chosen[1]) / rate, 4)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--overwrite", action="store_true", help="replace existing comparison files")
    args = ap.parse_args()
    gen = json.loads(GEN_LOG.read_text())
    takes = {t["take"]: t for t in gen["takes"]}
    raw_ok = {tid: sha256(t["file"]) == t["sha256"] for tid, t in takes.items()}
    if not all(raw_ok.values()) or len(takes) != 21:
        stop(f"raw files do not match the generation log before processing: {raw_ok}")
    OUT.mkdir(parents=True, exist_ok=True)
    rec = {"created": datetime.now().isoformat(timespec="seconds"), "output_dir": str(OUT),
           "settings": {"trim_threshold_dbfs": THRESHOLD_DB, "fade_in_ms": 0, "fade_out_ms": FADE_OUT_MS, "fade_shape": "linear",
                        "peak_ceiling_dbfs": PEAK_CEILING_DB, "gain_only": "one scalar gain per file; no compression, limiting or EQ",
                        "sfx_loudness": "maximum momentary loudness, LUFS: ITU-R BS.1770 K-weighting (pyloudnorm filters), 400 ms window "
                                        "(EBU R128 / Tech 3341 momentary), 10 ms hop, channel weights 1.0, clip followed by 400 ms silence",
                        "music_loudness": "integrated loudness, LUFS: ITU-R BS.1770-4 with gating (pyloudnorm Meter.integrated_loudness)",
                        "group_target": "the highest common loudness at which every file in the group peaks at or below the ceiling",
                        "output_format": "WAV, 24-bit PCM, original sample rate and channels",
                        "music_full_takes": "no trim needed (no leading silence above -50 dBFS); same 15 ms fade-out at the end",
                        "loop": f"beat tracking (librosa {librosa.__version__}), {BEATS_PER_BAR}/4 assumed, bar 1 = first tracked beat; "
                                f"whole bars >= {MIN_LOOP_S} s; candidate start chosen by the seam measure below; crossfade candidates {XFADE_CANDIDATES_MS} ms",
                        "libraries": {"pyloudnorm": "0.2.0", "librosa": librosa.__version__, "numpy": np.__version__, "soundfile": sf.__version__}},
           "files": {}}

    # 1. Sound effects: trim, measure, then one common target for the group.
    sfx = {}
    for sid in SFX:
        for n in (1, 2, 3):
            tid = f"{sid}-take{n}"
            audio, rate = sf.read(takes[tid]["file"], always_2d=True)
            out, trim = trim_sfx(audio, rate)
            sfx[tid] = {"audio": out, "rate": rate, "trim": trim, "lufs": max_momentary_lufs(out, rate),
                        "peak_db": db(np.abs(out).max()), "raw_peak_db": db(np.abs(audio).max())}
    sfx_target = min(v["lufs"] + PEAK_CEILING_DB - v["peak_db"] for v in sfx.values())
    sfx_target = math.floor(sfx_target * 10) / 10
    limiting = min(sfx, key=lambda k: sfx[k]["lufs"] + PEAK_CEILING_DB - sfx[k]["peak_db"])

    # 2. Music: integrated loudness, one common target for the three takes.
    mus = {}
    for n in (1, 2, 3):
        tid = f"MUS-LOOP-take{n}"
        y, rate = sf.read(takes[tid]["file"], always_2d=True)
        lead = np.nonzero(np.abs(y).max(axis=1) > 10 ** (THRESHOLD_DB / 20))[0][0]
        full = y.copy()
        nf = int(round(FADE_OUT_MS / 1000 * rate))
        full[-nf:] *= np.linspace(1.0, 0.0, nf)[:, None]
        lc = loop_candidate(y[:, 0], rate)
        s = int(round(lc["chosen"]["start_s"] * rate))
        e = int(round(lc["chosen"]["end_s"] * rate))
        loop, seam = build_loop(y[:, 0], rate, s, e)
        mus[tid] = {"full": full, "loop": loop, "rate": rate, "lead_samples_above_threshold_at": int(lead),
                    "lufs": pyln.Meter(rate).integrated_loudness(full), "peak_db": db(np.abs(full).max()),
                    "loop_peak_db": db(np.abs(loop).max()), "loop_info": lc, "seam": seam}
    mus_target = min(v["lufs"] + PEAK_CEILING_DB - max(v["peak_db"], v["loop_peak_db"]) for v in mus.values())
    mus_target = math.floor(mus_target * 10) / 10
    mus_limiting = min(mus, key=lambda k: mus[k]["lufs"] + PEAK_CEILING_DB - max(mus[k]["peak_db"], mus[k]["loop_peak_db"]))
    rec["groups"] = {"sfx": {"target_lufs_momentary_max": sfx_target, "set_by": limiting},
                     "music": {"target_lufs_integrated": mus_target, "set_by": mus_limiting}}

    def write(path, audio, rate):
        if path.exists() and not args.overwrite:
            stop(f"{path} exists (use --overwrite to replace comparison files)")
        sf.write(str(path), audio, rate, subtype="PCM_24")
        back, _ = sf.read(str(path), always_2d=True)
        return db(np.abs(back).max())

    for tid, v in sfx.items():
        gain = sfx_target - v["lufs"]
        out = v["audio"] * 10 ** (gain / 20)
        path = OUT / f"{tid}-compare.wav"
        written_peak = write(path, out, v["rate"])
        rec["files"][tid] = {"source": takes[tid]["file"], "output": str(path), **v["trim"],
                             "raw_peak_dbfs": round(v["raw_peak_db"], 2), "trimmed_peak_dbfs": round(v["peak_db"], 2),
                             "loudness_lufs_m_max": round(v["lufs"], 2), "gain_db": round(gain, 2),
                             "output_loudness_lufs_m_max": round(max_momentary_lufs(out, v["rate"]), 2),
                             "output_peak_dbfs": round(written_peak, 2), "sha256": sha256(path)}
    for tid, v in mus.items():
        gain = mus_target - v["lufs"]
        g = 10 ** (gain / 20)
        path = OUT / f"{tid}-compare.wav"
        p_full = write(path, v["full"] * g, v["rate"])
        loop3 = np.tile(v["loop"] * g, 3)[:, None]
        lpath = OUT / f"{tid}-loop-x3.wav"
        p_loop = write(lpath, loop3, v["rate"])
        rec["files"][tid] = {"source": takes[tid]["file"], "output": str(path), "lead_trim_ms": round(v["lead_samples_above_threshold_at"] / v["rate"] * 1000, 2),
                             "fade_out_ms": FADE_OUT_MS, "loudness_lufs_integrated": round(v["lufs"], 2), "raw_peak_dbfs": round(v["peak_db"], 2),
                             "gain_db": round(gain, 2), "output_loudness_lufs_integrated": round(pyln.Meter(v["rate"]).integrated_loudness(v["full"] * g), 2),
                             "output_peak_dbfs": round(p_full, 2), "sha256": sha256(path),
                             "loop": {**{k: v["loop_info"][k] for k in ("tempo_bpm", "beats_tracked", "bar_s", "bars", "beats_per_bar_assumed", "chosen")},
                                      "candidates_tried": len(v["loop_info"]["candidates"]), **v["seam"],
                                      "output": str(lpath), "repeats": 3, "output_peak_dbfs": round(p_loop, 2), "sha256": sha256(lpath)},
                             "loop_candidates": v["loop_info"]["candidates"]}

    over = {k: f for k, f in rec["files"].items() if f["output_peak_dbfs"] > PEAK_CEILING_DB + 1e-6
            or f.get("loop", {}).get("output_peak_dbfs", -99) > PEAK_CEILING_DB + 1e-6}
    raw_after = {tid: sha256(t["file"]) == t["sha256"] for tid, t in takes.items()}
    rec["checks"] = {"no_output_above_ceiling": not over, "raw_sha256_unchanged_after": all(raw_after.values()),
                     "raw_files_checked": len(raw_after)}
    LOG_JSON.write_text(json.dumps(rec, indent=2) + "\n")

    L = [f"== Batch 3 comparison audio (listening only; not for the repo or the game)  {rec['created']}",
         f"output: {OUT}", "settings:"] + [f"  {k}: {v}" for k, v in rec["settings"].items()] + [
        f"group targets: sound effects {sfx_target:.1f} LUFS (max momentary), set by {limiting}; "
        f"music {mus_target:.1f} LUFS (integrated), set by {mus_limiting}", "",
        "sound effects: take | lead trim ms | tail trim ms | kept ms | fade-out ms | raw peak | trimmed peak | loudness (M max) | gain | out loudness | out peak"]
    for sid in SFX:
        for n in (1, 2, 3):
            f = rec["files"][f"{sid}-take{n}"]
            L.append(f"  {sid}-take{n} | {f['lead_trim_ms']} | {f['tail_trim_ms']} | {f['kept_ms']} | {f['fade_out_ms']} | {f['raw_peak_dbfs']:+.2f} | "
                     f"{f['trimmed_peak_dbfs']:+.2f} | {f['loudness_lufs_m_max']:.2f} | {f['gain_db']:+.2f} dB | {f['output_loudness_lufs_m_max']:.2f} | {f['output_peak_dbfs']:+.2f}")
    L += ["", "music: take | loudness (integrated) | raw peak | gain | out loudness | out peak"]
    for n in (1, 2, 3):
        f = rec["files"][f"MUS-LOOP-take{n}"]
        L.append(f"  MUS-LOOP-take{n} | {f['loudness_lufs_integrated']:.2f} | {f['raw_peak_dbfs']:+.2f} | {f['gain_db']:+.2f} dB | "
                 f"{f['output_loudness_lufs_integrated']:.2f} | {f['output_peak_dbfs']:+.2f}")
    L += ["", "candidate loops (for listening to the seam; the final loop is decided in step 4):"]
    for n in (1, 2, 3):
        lp = rec["files"][f"MUS-LOOP-take{n}"]["loop"]
        c = lp["chosen"]
        L.append(f"  MUS-LOOP-take{n}: tempo {lp['tempo_bpm']} bpm, {lp['beats_tracked']} beats tracked, bar {lp['bar_s']} s, {lp['bars']} bars "
                 f"from {c['start_s']} s to {c['end_s']} s (start beat {c['start_beat']}; {lp['candidates_tried']} candidates; seam mel distance {c['seam_mel_distance']}); "
                 f"loop {lp['loop_s']} s; crossfade {lp['crossfade_ms']} ms; out peak {lp['output_peak_dbfs']:+.2f}")
        L.append(f"    neighbour jumps: median {lp['neighbour_jump_median']}, p95 {lp['neighbour_jump_p95']}, p99.9 {lp['neighbour_jump_p99_9']}")
        for t in lp["crossfade_trials"]:
            L.append(f"    crossfade {t['crossfade_ms']:>3} ms: seam jump {t['seam_jump']}, crossfade-region max jump {t['crossfade_region_max_jump']}, passes {t['passes']}")
    L += ["", f"checks: no output above {PEAK_CEILING_DB} dBFS: {not over}; raw SHA-256 unchanged after processing: "
              f"{all(raw_after.values())} ({len(raw_after)} files)", "output SHA-256: see evidence/batch3-compare-log.json"]
    LOG_TXT.write_text("\n".join(L) + "\n")
    print("\n".join(L))
    if over or not all(raw_after.values()):
        stop(f"check failed: over ceiling {list(over)}; raw unchanged {all(raw_after.values())}")


if __name__ == "__main__":
    main()
