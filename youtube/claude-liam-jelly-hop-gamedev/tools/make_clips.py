"""Trims the film's gameplay clips from the two 4K captures, at normal speed, with burned-in labels.

    python3 tools/make_clips.py CAPTURE_WORK_DIR      (run from the reel folder)

- Checks each AVI against capture/captures.sha256 first; a mismatch stops the script.
- Cuts on tick boundaries (60 fps capture: movie frame = tick - 1). Output is 30 fps: every other
  frame is kept, so playback speed is unchanged (no retiming, no interpolation).
- Labels are PNG overlays drawn with Pillow (this ffmpeg build has no drawtext):
  every clip: "Scripted-input capture · Godot Movie Maker (offline render) · rev 7a48ea8 · not a
  human playtest"; B06 adds the jelly's pose name from the input log; B09 adds which take/ticks each
  excerpt comes from and a marker for each sound event from the log.
- media/B06.mp4: video only (the compiler strips clip audio anyway).
- media/B09.mp4: video + the capture's own engine audio (AAC 256k), three excerpts with marked cuts.
  Its audio reaches the film through the premixed --audio master (tools/make_master.py; Kiran's decision, BUILD-LOG.md).
- Writes media/clips.json (source take, tick range, durations) and media/media.sha256.
"""
import hashlib
import json
import subprocess
import sys
from fractions import Fraction
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
SANS = '/System/Library/Fonts/SFNS.ttf'
INK, CREAM, ACCENT = (61, 57, 41), (250, 249, 245), (217, 119, 87)
CAPTURE_LABEL = 'Scripted-input capture · Godot Movie Maker (offline render) · rev 7a48ea8 · not a human playtest'


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def events(name):
    return [json.loads(l) for l in (REEL / 'capture' / f'{name}-inputs.jsonl').read_text().splitlines()]


# Label positions inside the 5% title-safe inset of a 3840x2160 frame (x 192-3648, y 108-2052).
TOP, TOP2, BOTTOM, LEFT, RIGHT_TAG = 120, 214, 1930, 200, 2300
LIGHT = (250, 249, 245, 240)   # bottom labels sit on the dark curtain: dark text on light for contrast
BOXES = {}   # path -> (w, h), to report each label's box for the frame check's contrast regions


def tag(text, path: Path, size=46, fg=CREAM, bg=(32, 37, 49, 215)):
    f = ImageFont.truetype(SANS, size)
    w = int(f.getlength(text)) + 56
    im = Image.new('RGBA', (w, size + 40), bg)
    ImageDraw.Draw(im).text((28, 14), text, font=f, fill=fg)
    im.save(path)
    BOXES[path] = (w, size + 40)
    return path


def region(label, paths, x, y):
    w = max(BOXES[p][0] for p in paths)
    h = max(BOXES[p][1] for p in paths)
    return {'label': label, 'box': [round(x / 3840, 4), round(y / 2160, 4), round((x + w) / 3840, 4), round((y + h) / 2160, 4)]}


def segment(work, take, start_tick, end_tick, overlays, out, audio):
    """overlays: list of (png, x, y, t0, t1) with times relative to the segment start (s)."""
    avi = work / 'takes' / f'{take}.avi'
    t0 = (start_tick - 1) / 60
    dur = Fraction(end_tick - start_tick, 60)
    cmd = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(avi)]
    for png, *_ in overlays:
        cmd += ['-i', str(png)]
    chain, last = [f'[0:v]trim=start={t0:.6f}:duration={float(dur):.6f},setpts=PTS-STARTPTS,fps=30[v0]'], 'v0'
    for i, (_, x, y, a, b) in enumerate(overlays, start=1):
        chain.append(f"[{last}][{i}:v]overlay={x}:{y}:enable='between(t,{a:.3f},{b:.3f})'[v{i}]")
        last = f'v{i}'
    if audio:
        chain.append(f'[0:a]atrim=start={t0:.6f}:duration={float(dur):.6f},asetpts=PTS-STARTPTS[a]')
    cmd += ['-filter_complex', ';'.join(chain), '-map', f'[{last}]']
    cmd += ['-map', '[a]', '-c:a', 'aac', '-b:a', '256k', '-ar', '48000'] if audio else ['-an']
    cmd += ['-c:v', 'libx264', '-preset', 'medium', '-crf', '14', '-pix_fmt', 'yuv420p', '-r', '30', str(out)]
    subprocess.run(cmd, check=True)
    return dur


def probe_frames(p: Path) -> int:
    r = subprocess.run(['ffprobe', '-v', 'error', '-count_frames', '-select_streams', 'v:0', '-show_entries',
                        'stream=nb_read_frames,width,height', '-of', 'json', str(p)], check=True, capture_output=True, text=True)
    s = json.loads(r.stdout)['streams'][0]
    if (s['width'], s['height']) != (3840, 2160):
        sys.exit(f'STOPPED: {p.name} is {s["width"]}x{s["height"]}')
    return int(s['nb_read_frames'])


def main():
    if len(sys.argv) != 2:
        sys.exit('usage: make_clips.py CAPTURE_WORK_DIR')
    work = Path(sys.argv[1])
    sums = {l.split()[1]: l.split()[0] for l in (REEL / 'capture/captures.sha256').read_text().splitlines()}
    for take in ('run-01', 'run-02'):
        if sha(work / 'takes' / f'{take}.avi') != sums[f'{take}.avi']:
            sys.exit(f'STOPPED: {take}.avi does not match captures.sha256')
    tmp = work / 'overlays'
    tmp.mkdir(exist_ok=True)
    media = REEL / 'media'
    media.mkdir(exist_ok=True)
    cap = tag(CAPTURE_LABEL, tmp / 'capture-label.png', 40)
    record = {}

    # B06: control returns -> walk, hop, land, worry under the shadow, fork splat, re-form, next hop.
    r1 = events('run-01')
    start = next(e['tick'] for e in r1 if e.get('event') == 'state' and e['state'] == 'PLAYING')
    end = start + 720                     # 12.0 s
    poses = [e for e in r1 if e.get('event') == 'pose' and start <= e['tick'] < end]
    ov = [(cap, LEFT, TOP, 0, 999)]
    pose_tags = []
    for i, e in enumerate(poses):
        t_a = (e['tick'] - start) / 60
        t_b = ((poses[i + 1]['tick'] if i + 1 < len(poses) else end) - start) / 60
        pose_tags.append(tag(f'pose: {e["pose"]}   (from the input log)', tmp / f'pose-{i}.png', 54, fg=INK, bg=LIGHT))
        ov.append((pose_tags[-1], LEFT, BOTTOM, t_a, t_b))
    dur = segment(work, 'run-01', start, end, ov, media / 'B06.mp4', audio=False)
    record['B06'] = {'take': 'run-01', 'ticks': [start, end], 'duration': str(dur), 'poses': [[e['tick'], e['pose']] for e in poses],
                     'label_regions': [region('capture label', [cap], LEFT, TOP), region('pose label', pose_tags, LEFT, BOTTOM)]}

    # B09: three excerpts with the slice's own audio.
    r2 = events('run-02')
    win = next(e['tick'] for e in r1 if e.get('event') == 'sound' and e['id'] == 'SFX-WIN')
    hop2 = next(e['tick'] for e in r2 if e.get('event') == 'sound' and e['id'] == 'SFX-HOP')
    sauce = next(e['tick'] for e in r2 if e.get('event') == 'sound' and e['id'] == 'SFX-SPLAT-SAUCE')
    parts = [('run-01', 300, 620), ('run-01', win - 90, win + 120), ('run-02', hop2 - 20, sauce + 80)]
    banner = tag('Slice audio · no narration · scripted-input capture', tmp / 'b09-banner.png', 48)
    files, part_records, part_tags = [], [], []
    for k, (take, a, b) in enumerate(parts):
        ev = r1 if take == 'run-01' else r2
        part_tag = tag(f'excerpt {k + 1} of 3 · {take} · ticks {a}–{b}', tmp / f'b09-part{k}.png', 46, fg=INK, bg=LIGHT)
        part_tags.append(part_tag)
        ov = [(cap, LEFT, TOP, 0, 999), (banner, LEFT, TOP2, 0, 999), (part_tag, LEFT, BOTTOM, 0, 999)]
        sounds = [e for e in ev if e.get('event') == 'sound' and a <= e['tick'] < b]
        for j, e in enumerate(sounds):
            t_a = (e['tick'] - a) / 60
            ov.append((tag(f'{e["id"]}  ·  tick {e["tick"]}', tmp / f'b09-{k}-{j}.png', 54, fg=INK, bg=(250, 249, 245, 235)),
                       RIGHT_TAG, BOTTOM, t_a, t_a + 0.8))
        f = work / f'b09-part{k}.mp4'
        segment(work, take, a, b, ov, f, audio=True)
        files.append(f)
        part_records.append({'take': take, 'ticks': [a, b], 'sounds': [[e['tick'], e['id']] for e in sounds]})
    lst = work / 'b09-concat.txt'
    lst.write_text(''.join(f"file '{f}'\n" for f in files))
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', str(lst),
                    '-c', 'copy', str(media / 'B09.mp4')], check=True)
    record['B09'] = {'parts': part_records, 'audio': 'capture engine audio, AAC 256k', 'duration_s': None,
                     'label_regions': [region('capture label', [cap], LEFT, TOP), region('slice-audio banner', [banner], LEFT, TOP2),
                                       region('excerpt label', part_tags, LEFT, BOTTOM)]}

    for bid in ('B06', 'B09'):
        n = probe_frames(media / f'{bid}.mp4')
        record[bid]['frames_30fps'] = n
        record[bid]['duration_s'] = n / 30
    ids = {s[1] for p in part_records for s in p['sounds']}
    need = {'SFX-HOP', 'SFX-LAND', 'SFX-WARN', 'SFX-SPLAT-FORK', 'SFX-SPLAT-SAUCE', 'SFX-WIN'}
    if not need <= ids:
        sys.exit(f'STOPPED: B09 is missing sound events {sorted(need - ids)}')
    (media / 'clips.json').write_text(json.dumps(record, indent=1) + '\n')
    (media / 'media.sha256').write_text(''.join(f'{sha(media / f)}  {f}\n' for f in ('B06.mp4', 'B09.mp4')))
    print(json.dumps({k: {'duration_s': v['duration_s'], 'frames': v['frames_30fps']} for k, v in record.items()}))
    print((media / 'media.sha256').read_text())


if __name__ == '__main__':
    main()
