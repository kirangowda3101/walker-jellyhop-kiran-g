"""Cuts the A6 film's two in-play clips (B11 Effect A, B18 Effect B) and held frames from the scripted 4K capture.

    python3 tools/make_clips.py [--hold B11=SECONDS] [--hold B18=SECONDS]

Written by Claude Code, 2026-11-08, after the A5 film's make_clips.py (same cutting rule; labels drawn with Pillow).
- Checks takes/run-a6.avi and capture/run-a6-inputs.jsonl against capture/captures.sha256 first; a mismatch stops.
- Movie Maker writes one frame per process frame at a fixed 60 fps with physics at 60 ticks/s. The driver logs one
  line per process frame AFTER that frame's physics tick, with its process-frame index `pframe`; movie frame n is
  the frame of log entry pframe n (tick n + 1). Every value burned in is read from that entry, never computed.
- Real-speed parts keep every other 60 fps frame for the 30 fps film: playback speed unchanged, no interpolation.
- The one slow part is a labelled replay of frames already shown (each 60 fps frame shown twice = 1/4 speed).
  A hold (if asked for) repeats the clip's last frame and is labelled "Held frame" on every held frame.
- Crops: where an effect is a few game pixels across, a 1920 x 1080 region of the native 3840 x 2160 frame is
  enlarged 2x (Lanczos) and labelled as such. No retouching, no colour change.
Output: media/B11.mp4, media/B18.mp4 (video only), _work/held/*.png, media/clips.json.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
WORK = REEL.parent
AVI = WORK / 'takes/run-a6.avi'
LOG = REEL / 'capture/run-a6-inputs.jsonl'
SANS = '/System/Library/Fonts/SFNS.ttf'
W, H = 3840, 2160
INK, LIGHT, DARK, CREAM = (32, 30, 26), (250, 249, 245, 235), (32, 37, 49, 230), (250, 249, 245)
CAPTURE_LABEL = ('Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · '
                 'rev 8004dea · not a human playtest')
CROP_A = (0, 700, 1920, 1780)        # plate 1, gap 1 and the next plates at the jelly's feet (4K pixels)
CROP_B = (1854, 700, 3774, 1780)     # the dome with the room above it (intro only: no HUD text on screen)
CLIPS = {
    'B11': [  # (kind, first frame, last frame inclusive, crop, label)
        ('real', 269, 539, CROP_A, 'excerpt 1 of 3 · a solo hop, then the plate-edge scoot-off'),
        ('replay', 439, 489, CROP_A, 'excerpt 2 of 3 · labelled replay of frames already shown · 1/4 speed'),
        ('real', 555, 1053, CROP_A, 'excerpt 3 of 3 · the route over plates 1 to 5'),
    ],
    'B18': [
        ('real', 0, 60, CROP_B, 'excerpt 1 of 3 · the first second of the intro pan'),
        ('real', 959, 1383, None, 'excerpt 2 of 3 · plate 6, Esc pause, then the win (full frame: the HUD text spans it)'),
        ('real', 1380, 1500, None, 'excerpt 3 of 3 · replay (full frame, not cropped)'),
    ],
}
HELD = {'held-puff.png': (316, CROP_A), 'held-scoot.png': (461, CROP_A), 'held-dome.png': (0, CROP_B),
        'held-won.png': (1300, CROP_B), 'held-pause.png': (1100, None)}
LEFT, TOP, GAP = 150, 110, 104


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


def read_frames(first, last):
    """Yields (n, RGB image) for movie frames first..last inclusive."""
    cmd = ['ffmpeg', '-v', 'error', '-ss', f'{first / 60:.6f}', '-i', str(AVI), '-frames:v', str(last - first + 1),
           '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-']
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    for n in range(first, last + 1):
        buf = p.stdout.read(W * H * 3)
        if len(buf) != W * H * 3:
            sys.exit(f'STOPPED: short read from the AVI at frame {n}')
        yield n, Image.frombytes('RGB', (W, H), buf)
    p.stdout.close()
    p.wait()


def view(im, crop):
    return im.crop(crop).resize((W, H), Image.LANCZOS) if crop else im.copy()   # never draw labels into the source frame


def status(bid, e):
    if bid == 'B11':
        return (f'from the capture log · tick {e["tick"]} · state {e["state"]} · SFX-LAND count {e["lands"]} · '
                f'LandPuff nodes in the tree {e["puffs_alive"]}')
    g = e['glints']
    return (f'from the capture log · tick {e["tick"]} · state {e["state"]} · DomeGlints emitting '
            f'{"true" if g["emitting"] else "false"}' + ('' if 0 <= g['sx'] <= 1280 else ' · the dome is off screen'))


def main():
    holds = {}
    args = sys.argv[1:]
    while args:
        if args[0] != '--hold' or len(args) < 2:
            sys.exit(__doc__)
        k, v = args[1].split('=')
        holds[k] = float(v)
        args = args[2:]
    sums = {l.split()[1]: l.split()[0] for l in (REEL / 'capture/captures.sha256').read_text().splitlines()}
    if sha(AVI) != sums['run-a6.avi'] or sha(LOG) != sums['run-a6-inputs.jsonl']:
        sys.exit('STOPPED: capture files do not match capture/captures.sha256')
    log = {e['pframe']: e for e in map(json.loads, LOG.read_text().splitlines()) if e['event'] == 'tick'}

    held_dir = REEL / '_work/held'
    held_dir.mkdir(parents=True, exist_ok=True)
    record = {'take': 'run-a6', 'avi_sha256': sums['run-a6.avi'], 'held': {}, 'clips': {}}
    for name, (n, crop) in HELD.items():
        _, im = next(read_frames(n, n))
        (im.crop(crop) if crop else im).save(held_dir / name)
        record['held'][name] = {'frame': n, 'tick': log[n]['tick'], 'crop_4k': crop, 'sha256': sha(held_dir / name),
                                'state': log[n]['state'], 'glints': log[n]['glints'], 'puffs_alive': log[n]['puffs_alive']}

    for bid, parts in CLIPS.items():
        out = REEL / f'media/{bid}.mp4'
        out.parent.mkdir(exist_ok=True)
        enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
                                '-r', '30', '-i', '-', '-c:v', 'libx264', '-preset', 'medium', '-crf', '14',
                                '-pix_fmt', 'yuv420p', str(out)], stdin=subprocess.PIPE)
        boxes, count, rec_parts, last = {0: [], 1: [], 2: []}, 0, [], None
        for kind, a, z, crop, label in parts:
            crop_note = 'cropped from the 4K frame and enlarged 2×' if crop else 'native 4K frame'
            shown = 0
            for n, im in read_frames(a, z):
                if kind == 'real' and (n - a) % 2:
                    continue
                e = log[n]
                v = view(im, crop)
                d = ImageDraw.Draw(v, 'RGBA')
                boxes[0].append(box(d, LEFT, TOP, CAPTURE_LABEL, 44, CREAM, DARK))
                boxes[1].append(box(d, LEFT, TOP + GAP, f'{label} · {crop_note}', 44, CREAM, DARK))
                boxes[2].append(box(d, LEFT, TOP + 2 * GAP, status(bid, e), 44, INK, LIGHT))
                reps = 2 if kind == 'replay' else 1
                for _ in range(reps):
                    enc.stdin.write(v.tobytes())
                    count += 1
                    shown += 1
                last = (v, e, crop, label, crop_note, im)
            rec_parts.append({'kind': kind, 'movie_frames': [a, z], 'ticks': [log[a]['tick'], log[z]['tick']],
                              'film_frames': shown, 'crop_4k': crop, 'label': label})
        hold = round(holds.get(bid, 0.0) * 30)
        if hold:
            v0, e, crop, label, crop_note, im = last
            v = view(im, crop)
            d = ImageDraw.Draw(v, 'RGBA')
            boxes[0].append(box(d, LEFT, TOP, CAPTURE_LABEL, 44, CREAM, DARK))
            boxes[1].append(box(d, LEFT, TOP + GAP, f'Held frame · tick {e["tick"]}, the last frame of excerpt 3 · {crop_note}',
                                44, CREAM, DARK))
            boxes[2].append(box(d, LEFT, TOP + 2 * GAP, status(bid, e), 44, INK, LIGHT))
            for _ in range(hold):
                enc.stdin.write(v.tobytes())
                count += 1
            rec_parts.append({'kind': 'hold', 'tick': e['tick'], 'film_frames': hold})
        enc.stdin.close()
        if enc.wait() != 0:
            sys.exit('STOPPED: encoder failed')
        r = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-select_streams', 'v:0', '-show_entries',
                            'stream=nb_read_frames,width,height', '-of', 'json', str(out)], check=True,
                           capture_output=True, text=True)
        s = json.loads(r.stdout)['streams'][0]
        if (s['width'], s['height'], int(s['nb_read_frames'])) != (W, H, count):
            sys.exit(f'STOPPED: {out.name} is {s}')
        # One region per label line: the part of the frame that line's box covers in EVERY frame (intersection),
        # so each region holds only that label's background and its text.
        regions = []
        for i, name in ((0, 'capture label'), (1, 'excerpt label'), (2, 'logged values')):
            bs = boxes[i]
            x0 = max(b[0] for b in bs); y0 = max(b[1] for b in bs); x1 = min(b[2] for b in bs); y1 = min(b[3] for b in bs)
            regions.append({'label': name, 'box': [round(x0 / W, 4), round(y0 / H, 4), round(x1 / W, 4), round(y1 / H, 4)]})
        record['clips'][bid] = {'path': f'media/{bid}.mp4', 'frames_30fps': count, 'duration_s': count / 30,
                                'sha256': sha(out), 'parts': rec_parts, 'label_regions': regions}
        print(bid, count, 'frames', round(count / 30, 3), 's')
    (REEL / 'media/clips.json').write_text(json.dumps(record, indent=1) + '\n')


if __name__ == '__main__':
    main()
