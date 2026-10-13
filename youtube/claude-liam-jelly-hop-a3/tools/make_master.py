"""After Kokoro: sets each beat's timing and builds the premixed master audio track.

    python3 tools/make_master.py      (run from the reel folder, after generate_audio_kokoro.py)

Same timing rules as the A2 film's make_master.py, without its footage beats (this film has none):
- narrated Remotion beats: 0.4 s lead + measured Kokoro voice + 1.2 s tail, rounded UP to a 30 fps frame;
- B01: lead 0.8 s (lead_silence_s), at least 9 s (ai-explainer TIMING rule);
- BOUT: voice + the 1.0 s silent tail hold (OUTRO-LOCK.md).
Highlight cues named in a beat's `cue_phrases` are placed where that phrase falls in the measured voice, by
character position (an estimate; Kokoro gives no word timings). Master: audio/master.wav, 48 kHz stereo PCM,
each beat's narration padded to its duration and concatenated. Nothing else is mixed in.
"""
import json
import math
import re
import subprocess
import sys
from pathlib import Path

REEL = Path(__file__).resolve().parent.parent
FPS = 30
LEAD, TRAIL = 0.4, 1.2


def frames_up(sec):
    return math.ceil(sec * FPS - 1e-8) / FPS


def probe(path):
    r = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(path)],
                       check=True, capture_output=True, text=True)
    return float(r.stdout.strip())


def volume(path):
    r = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-vn', '-af', 'volumedetect', '-f', 'null', '-'],
                       capture_output=True, text=True)
    return (float(re.search(r'mean_volume:\s*([-\d.]+)', r.stderr).group(1)),
            float(re.search(r'max_volume:\s*([-\d.]+)', r.stderr).group(1)))


def cue_time(text, phrase, lead, voice):
    i = text.find(phrase)
    if i < 0:
        sys.exit(f'STOPPED: cue phrase {phrase!r} not in narration')
    return round(lead + voice * i / max(1, len(text)), 2)


def main():
    sheet_path = REEL / 'beat_sheet.json'
    sheet = json.loads(sheet_path.read_text())
    work = REEL / 'audio'
    work.mkdir(exist_ok=True)
    wavs, report = [], []
    for b in sheet['beats']:
        bid, text = b['beat_id'], b.get('narration_text') or ''
        if not text:
            sys.exit(f'STOPPED: {bid} has no narration')
        voice = probe(REEL / b['audio_file'])
        if bid == 'B01':
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
        props = b['shot'].get('remotion', {}).get('props')
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
        ms = int(round(lead * 1000))
        subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', str(REEL / b['audio_file']), '-map', '0:a:0', '-vn',
                        '-af', f'adelay={ms}|{ms},apad', '-t', f'{dur:.6f}', '-ar', '48000', '-ac', '2',
                        '-c:a', 'pcm_s16le', str(wav)], check=True)
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
    m, p = volume(master)
    print(f'total {total:.3f}s ({total / 60:.2f} min) · master {got:.3f}s · mean {m} dB · peak {p} dB')


if __name__ == '__main__':
    main()
