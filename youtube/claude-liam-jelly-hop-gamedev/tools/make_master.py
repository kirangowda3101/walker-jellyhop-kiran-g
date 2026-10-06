"""After Kokoro: sets each beat's timing and builds the premixed master audio track.

    python3 tools/make_master.py CAPTURE_WORK_DIR    (run from the reel folder, after generate_audio_kokoro.py)

Timing (written back into beat_sheet.json):
- narrated Remotion beats: lead silence + measured Kokoro voice + trailing silence, rounded UP to a
  whole 30 fps frame (the compiler's own rule), so figures and code stay on screen after the voice;
- B01: lead 0.8 s (lead_silence_s), at least 9 s (ai-explainer TIMING rule);
- footage beats B06 and B09: exactly the clip's length, so the compiler plays them at ratio 1.000
  (no retiming); narration must fit inside the clip or the script stops;
- BOUT: voice + the 1.0 s silent tail hold (OUTRO-LOCK.md).
Highlight cues named in a beat's `cue_phrases` are placed where that phrase falls in the measured
voice, by its character position in the narration (an estimate; Kokoro gives no word timings).

Master audio (audio/master.wav, 48 kHz stereo PCM), built the way compile.py builds its own
per-beat track (each segment padded to its beat's duration, then concatenated), except for B09:
B09's segment is the captures' own recorded engine audio, cut sample-exactly from the AVIs' PCM
track with the same tick ranges as media/B09.mp4's video (media/clips.json), unchanged in level, with
no narration. (Reading B09.mp4's AAC track instead ran 96 ms long: each AAC excerpt adds padding.)
B09 level (Kiran's instruction, 2026-10-03, for audibility): one plain gain, `volume=<g>dB`, with g chosen so
the segment's sample peak reaches -1 dBFS. No compression, limiting, EQ or added sound; the gain and the
before/after levels are printed and stored on the beat as `audio_gain`.
This is the `--audio` premix Kiran chose on 2026-10-03 (BUILD-LOG.md). Nothing is dubbed.
"""
import hashlib
import json
import math
import re
import subprocess
import sys
from pathlib import Path

REEL = Path(__file__).resolve().parent.parent
FPS = 30
FOOTAGE = {'B06': 'media/B06.mp4', 'B09': 'media/B09.mp4'}
LEAD, TRAIL = 0.4, 1.2
B09_PEAK_TARGET = -1.0   # dBFS


def frames_up(sec):
    return math.ceil(sec * FPS - 1e-8) / FPS


def probe(path, stream='format'):
    r = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(path)],
                       check=True, capture_output=True, text=True)
    return float(r.stdout.strip())


def volume(path):
    r = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-vn', '-af', 'volumedetect', '-f', 'null', '-'],
                       capture_output=True, text=True)
    mean = re.search(r'mean_volume:\s*([-\d.]+)', r.stderr)
    peak = re.search(r'max_volume:\s*([-\d.]+)', r.stderr)
    return float(mean.group(1)), float(peak.group(1))


def cue_time(text, phrase, lead, voice):
    i = text.find(phrase)
    if i < 0:
        sys.exit(f'STOPPED: cue phrase {phrase!r} not in narration')
    return round(lead + voice * i / max(1, len(text)), 2)


def b09_audio(work_dir: Path, out: Path):
    sums = {l.split()[1]: l.split()[0] for l in (REEL / 'capture/captures.sha256').read_text().splitlines()}
    parts = json.loads((REEL / 'media/clips.json').read_text())['B09']['parts']
    pieces = []
    for k, p in enumerate(parts):
        avi = work_dir / 'takes' / f"{p['take']}.avi"
        if hashlib.sha256(avi.read_bytes()).hexdigest() != sums[avi.name]:
            sys.exit(f'STOPPED: {avi.name} does not match captures.sha256')
        a, z = p['ticks']
        piece = out.parent / f'b09-part{k}.wav'
        # movie frame = tick - 1, so the excerpt starts at (a - 1) / 60 s, exactly as make_clips.py cuts the video
        subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(avi), '-map', '0:a:0', '-af',
                        f'atrim=start_sample={(a - 1) * 800}:end_sample={(z - 1) * 800},asetpts=PTS-STARTPTS',
                        '-ar', '48000', '-ac', '2', '-c:a', 'pcm_s16le', str(piece)], check=True)
        pieces.append(piece)
    lst = out.parent / 'b09-parts.txt'
    lst.write_text(''.join(f"file '{x.resolve()}'\n" for x in pieces))
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', str(lst), '-c:a', 'pcm_s16le', str(out)],
                   check=True)


def main():
    if len(sys.argv) != 2:
        sys.exit('usage: make_master.py CAPTURE_WORK_DIR')
    work_dir = Path(sys.argv[1])
    sheet_path = REEL / 'beat_sheet.json'
    sheet = json.loads(sheet_path.read_text())
    wavs, report = [], []
    work = REEL / 'audio'
    work.mkdir(exist_ok=True)
    for b in sheet['beats']:
        bid = b['beat_id']
        text = b.get('narration_text') or ''
        voice = probe(REEL / b['audio_file']) if text else 0.0
        if bid in FOOTAGE:
            n = json.loads((REEL / 'media/clips.json').read_text())[bid]['frames_30fps']   # counted video frames
            dur = n / FPS
            lead = 0.5 if text else 0.0
            if lead + voice > dur - 0.2:
                sys.exit(f'STOPPED: {bid} narration {voice:.2f}s does not fit its {dur:.2f}s clip')
        elif bid == 'B01':
            lead = float(b.get('lead_silence_s', 0.8))
            dur = frames_up(max(9.0, lead + voice + 0.6))
        elif bid == 'BOUT':
            lead = 0.0
            dur = frames_up(voice + float(b.get('tail_hold_s', 1.0)))
        else:
            lead = LEAD
            dur = frames_up(lead + voice + TRAIL)
        b['actual_duration_s'] = dur
        b['render_duration_s'] = dur
        b['narration_window_s'] = {'lead_silence': lead, 'voice': round(voice, 3), 'trailing_silence': round(dur - lead - voice, 3)}
        props = b.get('shot', {}).get('remotion', {}).get('props')
        if props is not None:
            if b['shot']['remotion']['pattern'] in ('GodotDevWorkbench', 'GodotDesignFigure', 'BrutalistHesitantWriter'):
                props['durationSeconds'] = dur
            phrases = b.get('cue_phrases')
            if phrases:
                cues = props['cues']
                if len(cues) != len(phrases):
                    sys.exit(f'STOPPED: {bid} has {len(cues)} cues but {len(phrases)} cue phrases')
                for c, ph in zip(cues, phrases):
                    c['at'] = cue_time(text, ph, lead, voice)
        wav = work / f'seg-{bid}.wav'
        if bid == 'B09':
            src = work / 'b09-engine.wav'
            b09_audio(work_dir, src)
            mean0, peak0 = volume(src)
            gain = round(B09_PEAK_TARGET - peak0, 2)
            af = f'volume={gain:.2f}dB,apad'
            b['audio_gain'] = {'gain_db': gain, 'method': 'single plain gain (ffmpeg volume filter), no compression or limiting',
                               'before': {'mean_db': mean0, 'peak_db': peak0}}
        elif text:
            ms = int(round(lead * 1000))
            src, af = REEL / b['audio_file'], f'adelay={ms}|{ms},apad'
        else:
            sys.exit(f'STOPPED: {bid} has neither narration nor source audio')
        subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(src), '-map', '0:a:0', '-vn', '-af', af, '-t', f'{dur:.6f}',
                        '-ar', '48000', '-ac', '2', '-c:a', 'pcm_s16le', str(wav)], check=True)
        wavs.append(wav)
        report.append((bid, dur, lead, voice))
    lst = work / 'segments.txt'
    lst.write_text(''.join(f"file '{w.resolve()}'\n" for w in wavs))
    master = work / 'master.wav'
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', str(lst), '-c:a', 'pcm_s16le', str(master)],
                   check=True)
    total = sum(d for _, d, _, _ in report)
    got = probe(master)
    if abs(got - total) > 0.05:
        sys.exit(f'STOPPED: master is {got:.3f}s but the timeline is {total:.3f}s')
    sheet_path.write_text(json.dumps(sheet, indent=1, ensure_ascii=False) + '\n')
    for bid, d, lead, v in report:
        print(f'{bid:5} {d:7.3f}s  lead {lead:.1f}  voice {v:6.2f}')
    m9, p9 = volume(work / 'seg-B09.wav')
    b9 = next(x for x in sheet['beats'] if x['beat_id'] == 'B09')
    b9['audio_gain']['after'] = {'mean_db': m9, 'peak_db': p9}
    if p9 > B09_PEAK_TARGET + 0.05:
        sys.exit(f'STOPPED: B09 peak {p9} dB is above the {B09_PEAK_TARGET} dBFS target')
    sheet_path.write_text(json.dumps(sheet, indent=1, ensure_ascii=False) + '\n')
    print(f"B09 gain {b9['audio_gain']['gain_db']:+.2f} dB · before mean {b9['audio_gain']['before']['mean_db']} / peak "
          f"{b9['audio_gain']['before']['peak_db']} dB · after mean {m9} / peak {p9} dB")
    mn, pn = volume(work / 'seg-B05.wav')
    print(f'total {total:.3f}s ({total / 60:.2f} min) · master {got:.3f}s')
    print(f'levels: B09 engine audio mean {m9} dB peak {p9} dB · B05 narration mean {mn} dB peak {pn} dB')


if __name__ == '__main__':
    main()
