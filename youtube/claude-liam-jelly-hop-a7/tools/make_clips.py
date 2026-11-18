"""Cuts the A7 film's three in-play clips (B11, B13, B17) and its held frames from the scripted 4K capture.

    python3 tools/make_clips.py [--hold B11=SECONDS] [--hold B13=SECONDS] [--hold B17=SECONDS]

Written by Claude Code, 2026-11-17, after the A6 film's make_clips.py (same cutting rule; labels drawn with Pillow).
- Checks takes/run-a7.avi and capture/run-a7-inputs.jsonl against capture/captures.sha256 first; a mismatch stops.
- Movie Maker writes one frame per process frame at a fixed 60 fps with physics at 60 ticks/s. The driver logs one
  line per process frame AFTER that frame's physics tick; movie frame n is log entry pframe n (physics tick n + 1,
  checked on all 1,038 entries). Every value burned in is read from that entry, never computed.
- Real-speed parts keep every other 60 fps frame for the 30 fps film: playback speed unchanged, no interpolation.
  Every second engine frame is therefore not shown at real speed; the slowed replays show every engine frame.
- Slowed parts are labelled replays of frames already shown at real speed: each 60 fps frame repeated R times
  (R 8 = 1/16 speed). A hold (if asked for) repeats the clip's last frame, labelled "Held frame".
- Crop: the jelly is about 64 game px tall, so a 1920 x 1080 region of the native 3840 x 2160 frame (game canvas
  x 0-640, y 233-593: plate 1, the wall above it, the table edge) is enlarged 2x (Lanczos) and labelled as such.
  No retouching, no colour change.
Output: media/B11.mp4, media/B13.mp4, media/B17.mp4 (video only), _work/held/*.png, media/clips.json.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
WORK = REEL.parent
AVI = WORK / 'takes/run-a7.avi'
LOG = REEL / 'capture/run-a7-inputs.jsonl'
SANS = '/System/Library/Fonts/SFNS.ttf'
W, H = 3840, 2160
INK, LIGHT, DARK, CREAM = (32, 30, 26), (250, 249, 245, 235), (32, 37, 49, 230), (250, 249, 245)
CAPTURE_LABEL = ('Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · '
                 'rev c1bbb13 · not a human playtest')
CROP = (0, 700, 1920, 1780)
# (kind, first tick, last tick inclusive, repeat, label). Movie frame = tick - 1.
CLIPS = {
    'B11': [
        ('real', 245, 332, 1, 'excerpt 1 of 4 · a stationary hop on plate 1: the full landing, then IDLE'),
        ('replay', 291, 302, 8, 'excerpt 2 of 4 · replay of excerpt 1 ticks 291–302 · every engine frame · 1/16 speed'),
        ('real', 333, 465, 1, 'excerpt 3 of 4 · scooting left, right and left again'),
        ('replay', 386, 396, 8, 'excerpt 4 of 4 · replay of ticks 386–396: a swap and a wrap · every engine frame · 1/16 speed'),
    ],
    'B13': [
        ('real', 600, 733, 1, 'startup interrupt 1 of 3 · jump press read 1 tick after touchdown (k = 1)'),
        ('replay', 651, 655, 8, 'replay of ticks 651–655 · every engine frame · 1/16 speed'),
        ('real', 734, 869, 1, 'active interrupt 2 of 3 · jump press read 3 ticks after touchdown (k = 3)'),
        ('replay', 785, 791, 8, 'replay of ticks 785–791 · every engine frame · 1/16 speed'),
        ('real', 870, 1008, 1, 'recovery interrupt 3 of 3 · jump press read 6 ticks after touchdown (k = 6)'),
        ('replay', 921, 930, 8, 'replay of ticks 921–930 · every engine frame · 1/16 speed'),
    ],
    'B17': [
        ('real', 466, 596, 1, 'excerpt 1 of 2 · a hop with D held: it lands moving, LAND then SCOOT'),
        ('replay', 519, 540, 8, 'excerpt 2 of 2 · replay of ticks 519–540: the LAND → SCOOT switch · every engine frame · 1/16 speed'),
    ],
}
HELD = {'held-land-rig2.png': 295, 'held-scoot-b.png': 390, 'held-scoot-left.png': 445, 'held-idle.png': 330,
        'held-rig0.png': 293, 'held-rig6.png': 299}
LEFT, TOP, GAP = 150, 110, 104


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def font(size):
    return ImageFont.truetype(SANS, size)


def box(d, x, y, text, size, fg, bg):
    f = font(size)
    w = int(f.getlength(text)) + 56
    if x + w > W - 150:
        sys.exit(f'STOPPED: label too wide ({w}px): {text}')
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


def view(im):
    return im.crop(CROP).resize((W, H), Image.LANCZOS)   # a copy: never draw labels into the source frame


def status(e, touchdowns):
    t = e['physics_frame']
    rel = ''
    for t0 in touchdowns:
        if -2 <= t - t0 <= 12:
            rel = f' (touchdown {t - t0:+d})'
            break
    pose = e['pose']
    shown = {'rig': 'landing rig', 'scoot': 'scoot sprite', 'sprite': 'original sprite'}.get(e['vis'], e['vis'])
    face = '+1' if e['facing'] > 0 else '−1'
    if e['cur'] == 'land':
        what = f"land_ticks {e['land_ticks']} · clip land at {round(e['pos'] * 60)}/60 s"
    elif e['cur'] == 'scoot':
        what = f"player tick % 14 = {e['ptick'] % 14} · clip scoot at {round(e['pos'] * 60)}/60 s · cell {e['cell']}"
    else:
        what = 'no clip'
    return f"from the capture log · tick {t}{rel} · pose {pose} · {what} · facing {face} · shown: {shown}"


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
    if sha(AVI) != sums['run-a7.avi'] or sha(LOG) != sums['run-a7-inputs.jsonl']:
        sys.exit('STOPPED: capture files do not match capture/captures.sha256')
    entries = [json.loads(l) for l in LOG.read_text().splitlines()]
    log = {e['physics_frame']: e for e in entries if e.get('event') == 'frame'}
    if any(e['pframe'] != t - 1 for t, e in log.items()):
        sys.exit('STOPPED: pframe != tick - 1')
    touchdowns = sorted({e['touchdown'] for e in entries if e.get('event') == 'touchdown'} |
                        {e['second_touchdown'] for e in entries if e.get('event') == 'interrupt'})

    held_dir = REEL / '_work/held'
    held_dir.mkdir(parents=True, exist_ok=True)
    record = {'take': 'run-a7', 'avi_sha256': sums['run-a7.avi'], 'crop_4k': CROP, 'touchdowns': touchdowns,
              'held': {}, 'clips': {}}
    for name, t in HELD.items():
        _, im = next(read_frames(t - 1, t - 1))
        im.crop(CROP).save(held_dir / name)
        e = log[t]
        record['held'][name] = {'movie_frame': t - 1, 'tick': t, 'crop_4k': CROP, 'sha256': sha(held_dir / name),
                                'pose': e['pose'], 'cur': e['cur'], 'pos': e['pos'], 'cell': e['cell'],
                                'facing': e['facing'], 'vis': e['vis'], 'status': status(e, touchdowns)}

    for bid, parts in CLIPS.items():
        out = REEL / f'media/{bid}.mp4'
        out.parent.mkdir(exist_ok=True)
        enc = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
                                '-r', '30', '-i', '-', '-c:v', 'libx264', '-preset', 'medium', '-crf', '14',
                                '-pix_fmt', 'yuv420p', str(out)], stdin=subprocess.PIPE)
        boxes, count, rec_parts, last = {0: [], 1: [], 2: []}, 0, [], None
        note = '1920 × 1080 region of the 4K frame, enlarged 2×'
        for kind, a, z, reps, label in parts:
            shown = 0
            for n, im in read_frames(a - 1, z - 1):
                t = n + 1
                if kind == 'real' and (t - a) % 2:
                    continue
                e = log[t]
                v = view(im)
                d = ImageDraw.Draw(v, 'RGBA')
                boxes[0].append(box(d, LEFT, TOP, CAPTURE_LABEL, 44, CREAM, DARK))
                boxes[1].append(box(d, LEFT, TOP + GAP, f'{label} · {note}', 44, CREAM, DARK))
                boxes[2].append(box(d, LEFT, TOP + 2 * GAP, status(e, touchdowns), 44, INK, LIGHT))
                for _ in range(reps):
                    enc.stdin.write(v.tobytes())
                    count += 1
                    shown += 1
                last = (e, im)
            rec_parts.append({'kind': kind, 'ticks': [a, z], 'movie_frames': [a - 1, z - 1], 'repeat': reps,
                              'film_frames': shown, 'label': label})
        hold = round(holds.get(bid, 0.0) * 30)
        if hold:
            e, im = last
            v = view(im)
            d = ImageDraw.Draw(v, 'RGBA')
            boxes[0].append(box(d, LEFT, TOP, CAPTURE_LABEL, 44, CREAM, DARK))
            boxes[1].append(box(d, LEFT, TOP + GAP, f'Held frame · tick {e["physics_frame"]}, the last frame shown · {note}',
                                44, CREAM, DARK))
            boxes[2].append(box(d, LEFT, TOP + 2 * GAP, status(e, touchdowns), 44, INK, LIGHT))
            for _ in range(hold):
                enc.stdin.write(v.tobytes())
                count += 1
            rec_parts.append({'kind': 'hold', 'tick': e['physics_frame'], 'film_frames': hold})
        enc.stdin.close()
        if enc.wait() != 0:
            sys.exit('STOPPED: encoder failed')
        r = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-select_streams', 'v:0', '-show_entries',
                            'stream=nb_read_frames,width,height', '-of', 'json', str(out)], check=True,
                           capture_output=True, text=True)
        s = json.loads(r.stdout)['streams'][0]
        if (s['width'], s['height'], int(s['nb_read_frames'])) != (W, H, count):
            sys.exit(f'STOPPED: {out.name} is {s}')
        regions = []
        for i, name in ((0, 'capture label'), (1, 'excerpt label'), (2, 'logged values')):
            bs = boxes[i]
            x0 = max(b[0] for b in bs); y0 = max(b[1] for b in bs); x1 = min(b[2] for b in bs); y1 = min(b[3] for b in bs)
            regions.append({'label': name, 'box': [round(x0 / W, 4), round(y0 / H, 4), round(x1 / W, 4), round(y1 / H, 4)]})
        record['clips'][bid] = {'path': f'media/{bid}.mp4', 'frames_30fps': count, 'duration_s': count / 30,
                                'sha256': sha(out), 'parts': rec_parts, 'label_regions': regions}
        print(bid, count, 'frames', round(count / 30, 3), 's')
    (REEL / 'media/clips.json').write_text(json.dumps(record, indent=1, ensure_ascii=False) + '\n')


if __name__ == '__main__':
    main()
