"""Cuts the A5 film's in-play clip (B07) and held frames from the scripted 4K capture, at normal speed.

    python3 tools/make_clips.py CAPTURE_WORK_DIR      (run from anywhere; after capture/run_captures.sh)

Written by Claude Code, 2026-10-28, after the A2 film's make_clips.py (same cutting rule, labels drawn with
Pillow because this ffmpeg has no drawtext).
- Checks run-a5.avi and run-a5-inputs.jsonl against capture/captures.sha256 first; a mismatch stops.
- Movie Maker records one frame per physics tick (60 fps): movie frame index = tick - 1. The film is 30 fps,
  so every other frame is kept; playback speed is unchanged (no retiming, no interpolation).
- Labels: every frame carries "Scripted capture · ..." at the top. Under each fork that is on screen, a tag
  gives its plate, phase and the `warning` value its own material holds after that tick. The capture driver
  logs that value at the start of each physics tick (before the forks advance), so the value shown for the
  frame of tick T is the one logged at tick T + 1. Read from the log, never computed here.
- Output: media/B07.mp4 (video only; the narration is the film's audio), held frames in WORK/held/,
  media/clips.json (ticks, durations, label boxes, held-frame hashes).
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
SANS = '/System/Library/Fonts/SFNS.ttf'
W, H, SCALE = 3840, 2160, 3.0           # 4K movie of the game's 1280 x 720 canvas
INK, LIGHT, DARK, CREAM = (32, 30, 26), (250, 249, 245, 240), (32, 37, 49, 225), (250, 249, 245)
CAPTURE_LABEL = 'Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · rev 77a6d10 · not a human playtest'
PARTS = [  # (first tick, end tick exclusive, part label)
    (1, 601, 'excerpt 1 of 2 · ticks 1–600 · intro pan, then play'),
    (1085, 1235, 'excerpt 2 of 2 · ticks 1085–1234 · after the win (state WON)'),
]
HELD = {'held-t455.png': 455, 'held-t60.png': 60}
TOP, TOP2, TAG_Y, LEFT = 120, 214, 1860, 200


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def font(size):
    return ImageFont.truetype(SANS, size)


def box(d, x, y, text, size, fg, bg):
    f = font(size)
    w = int(f.getlength(text)) + 56
    d.rectangle([x, y, x + w, y + size + 40], fill=bg)
    d.text((x + 28, y + 14), text, font=f, fill=fg)
    return [x, y, x + w, y + size + 40]


def frames(avi, start_tick, n):
    """Yields n RGB frames at 30 fps from start_tick (every other 60 fps movie frame)."""
    t0 = (start_tick - 1) / 60
    cmd = ['ffmpeg', '-v', 'error', '-ss', f'{t0:.6f}', '-i', str(avi), '-vf', "select='not(mod(n\\,2))'",
           '-fps_mode', 'passthrough', '-frames:v', str(n), '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-']
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    for _ in range(n):
        buf = p.stdout.read(W * H * 3)
        if len(buf) != W * H * 3:
            sys.exit('STOPPED: short read from the AVI')
        yield Image.frombytes('RGB', (W, H), buf)
    p.stdout.close()
    p.wait()


def main():
    if len(sys.argv) != 2:
        sys.exit('usage: make_clips.py CAPTURE_WORK_DIR')
    work = Path(sys.argv[1])
    avi = work / 'takes/run-a5.avi'
    log = REEL / 'capture/run-a5-inputs.jsonl'
    sums = {l.split()[1]: l.split()[0] for l in (REEL / 'capture/captures.sha256').read_text().splitlines()}
    if sha(avi) != sums['run-a5.avi'] or sha(log) != sums['run-a5-inputs.jsonl']:
        sys.exit('STOPPED: capture files do not match capture/captures.sha256')
    forks = {e['tick']: e for e in map(json.loads, log.read_text().splitlines()) if e['event'] == 'forks'}

    held_dir = work / 'held'
    held_dir.mkdir(exist_ok=True)
    held = {}
    for name, tick in HELD.items():
        p = held_dir / name
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{(tick - 1) / 60:.6f}', '-i', str(avi), '-frames:v', '1', str(p)], check=True)
        held[name] = {'tick': tick, 'sha256': sha(p),
                      'forks': [(f['plate'], f['phase'], f['warning']) for f in forks[tick + 1]['forks'] if 0 <= f['x'] <= 1280]}

    out = REEL / 'media/B07.mp4'
    enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', '30',
                            '-i', '-', '-c:v', 'libx264', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p', str(out)],
                           stdin=subprocess.PIPE)
    record = {'take': 'run-a5', 'parts': [], 'label_regions': []}
    boxes = {'capture label': [], 'excerpt label': [], 'fork tags': []}
    count = 0
    for a, b, part_label in PARTS:
        n = (b - a) // 2
        shown = []
        for j, im in enumerate(frames(avi, a, n)):
            tick = a + 2 * j
            row = forks[tick + 1]
            d = ImageDraw.Draw(im, 'RGBA')
            boxes['capture label'].append(box(d, LEFT, TOP, CAPTURE_LABEL, 40, CREAM, DARK))
            boxes['excerpt label'].append(box(d, LEFT, TOP2, f'{part_label} · state {row["state"]}', 40, CREAM, DARK))
            for f in row['forks']:
                x = f['x'] * SCALE
                if not (420 <= x <= W - 420):
                    continue
                text = f'plate {f["plate"]} · {f["phase"]} · warning {f["warning"]:.2f}'
                tw = int(font(46).getlength(text)) + 56
                boxes['fork tags'].append(box(d, int(x - tw / 2), TAG_Y, text, 46, INK, LIGHT))
                shown.append([tick, f['plate'], f['phase'], f['warning']])
            enc.stdin.write(im.tobytes())
            count += 1
        record['parts'].append({'ticks': [a, b - 1], 'frames_30fps': n, 'label': part_label, 'tags_first_last': [shown[0], shown[-1]]})
    enc.stdin.close()
    if enc.wait() != 0:
        sys.exit('STOPPED: encoder failed')
    for label, bs in boxes.items():
        x0 = min(b[0] for b in bs); y0 = min(b[1] for b in bs); x1 = max(b[2] for b in bs); y1 = max(b[3] for b in bs)
        record['label_regions'].append({'label': label, 'box': [round(x0 / W, 4), round(y0 / H, 4), round(x1 / W, 4), round(y1 / H, 4)]})
    r = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-select_streams', 'v:0', '-show_entries',
                        'stream=nb_read_frames,width,height', '-of', 'json', str(out)], check=True, capture_output=True, text=True)
    s = json.loads(r.stdout)['streams'][0]
    if (s['width'], s['height'], int(s['nb_read_frames'])) != (W, H, count):
        sys.exit(f'STOPPED: B07.mp4 is {s}')
    record.update({'frames_30fps': count, 'duration_s': count / 30, 'sha256': sha(out), 'held': held})
    (REEL / 'media/clips.json').write_text(json.dumps(record, indent=1) + '\n')
    print(json.dumps({'frames': count, 'duration_s': count / 30, 'regions': record['label_regions'], 'held': held}, indent=1))


if __name__ == '__main__':
    main()
