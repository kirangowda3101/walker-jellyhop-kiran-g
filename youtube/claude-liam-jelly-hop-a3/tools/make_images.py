"""Builds the A3 film's figures from Kiran's own screenshots and the recorded headless check.

    python3 tools/make_images.py      (run from the reel folder)

Every screenshot is checked against its SHA-256 (taken from the committed files at revision 948ab6a)
before use; a mismatch stops the script. Screenshots are only scaled, never retouched; every panel
carries a "Kiran's screenshot NN" label. Numbers in the B09 figure are parsed from
evidence/a3-assets-run.log, not typed. Output: images/*.png and images/images.sha256.
"""
import hashlib
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent.parent
REPO = REEL.parent.parent
SHOTS = REPO / 'evidence/a3/screenshots'
INPUTS = {   # file -> SHA-256 of the committed screenshot (948ab6a)
    '12-fork-six-parts-tris-72.png': '8fe7f14ec4594f4931cfc773aaba62a13846a3e089c02b2e417dbad6378afcf8',
    '13-dome-parts-material-preview-before-hand-edit.png': '476842d171dd9319ef608596c1a1bc615348d862578719e5ae87da39d9dbb2b3',
    '14-dome-hand-edit-pink-picker-before-D1AAB6.png': 'd584ae93ed51d27d38d27239282d49316261b5b0cf90679b272943edba655c31',
    '15-dome-hand-edit-cherry-restored-pink-after.png': 'd1630bac9c2af28d0aa921d6a12f0e9c0dde3bbea276357bbb3ccad9312ce332',
    '19-godot-scene-camera-run.png': '65f60d8924541f41b42b57a4b7e46b7b08da68e69898c0fd011409cfb7a7599c',
    '23-claude-code-fork-prompt.png': '4ae34107ad3866f90e719d54cf687319149ea187763f0a2f7c5b1e18ce3cd97b',
}
RUN_LOG = REPO / 'evidence/a3-assets-run.log'

W, H = 3200, 1400   # about the GodotDesignFigure image box's aspect at 3840x2160
CREAM, INK, ACCENT, MUTED, LINE = (250, 249, 245), (61, 57, 41), (152, 80, 57), (110, 100, 86), (207, 198, 181)
SERIF = str(Path.home() / 'Library/Fonts/EBGaramond-Medium.ttf')
SANS = '/System/Library/Fonts/SFNS.ttf'
MONO = '/System/Library/Fonts/SFNSMono.ttf'


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def shot(name) -> Image.Image:
    p = SHOTS / name
    if not p.is_file():
        sys.exit(f'STOPPED: missing screenshot {p}')
    if sha(p) != INPUTS[name]:
        sys.exit(f'STOPPED: checksum mismatch for {p}')
    return Image.open(p).convert('RGB')


def font(path, size):
    return ImageFont.truetype(path, size)


def fit(im, box_w, box_h):
    k = min(box_w / im.width, box_h / im.height)
    return im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)


def framed(canvas, im, x, y):
    d = ImageDraw.Draw(canvas)
    canvas.paste(im, (x, y))
    d.rectangle([x - 3, y - 3, x + im.width + 2, y + im.height + 2], outline=LINE, width=3)


def label(d, x, y, text, size=44, fill=INK, face=SANS):
    d.text((x, y), text, font=font(face, size), fill=fill)


def b03():
    im = shot('23-claude-code-fork-prompt.png')
    c = Image.new('RGB', (W, H), CREAM)
    d = ImageDraw.Draw(c)
    s = fit(im, 1700, 1270)
    framed(c, s, 40, 40)
    label(d, 40, 40 + s.height + 18, "Kiran's screenshot 23 · Claude Code in Terminal · Kiran's fork prompt, 2026-10-12", 40, MUTED)
    x = 1840
    label(d, x, 60, 'What the prompt asks for', 64, INK, SERIF)
    rows = ['Read CHANGE-BRIEF.md first',
            "the brief's numbers: 0.5 × 0.05 × 1.5 m,",
            '6 boxes, at most 100 triangles',
            'get_scene_info, then a plan:',
            '"Do not build yet."',
            'one execute_blender_code call per object,',
            'code saved to tools/blender/build_fork.py',
            'no asset libraries, no generate_3d',
            '"Say what you could not verify."']
    y = 190
    for r in rows:
        label(d, x, y, r, 50)
        y += 112
    return c


def b04():
    im = shot('12-fork-six-parts-tris-72.png')
    c = Image.new('RGB', (W, H), CREAM)
    d = ImageDraw.Draw(c)
    s = fit(im.crop((60, 165, 970, 940)), 1960, 1250)   # the 3D viewport only (GATE T §8.3b flagged the Outliner)
    framed(c, s, 40, 40)
    label(d, 40, 40 + s.height + 18, "Kiran's screenshot 12, cropped to the 3D viewport · Blender 5.2.2 · six fork parts built through the MCP", 40, MUTED)
    x = 2080
    label(d, x, 50, 'Status bar (bottom right), as read', 56, INK, SERIF)
    label(d, x, 150, 'Verts:48 · Faces:36 · Tris:72', 52, INK, MONO)
    label(d, x, 230, 'Objects:0/6 · typed from the full screenshot', 36, MUTED)
    rows = [("Claude Code's plan (23:26)", True),
            ('4 prongs · 1 head · 1 handle', False), ('6 boxes, all 0.05 m deep', False),
            ('72 triangles · budget 100', False),
            ('Kiran accepted the plan,', True), ('the join and metallic 0', False),
            ('Checked: points down,', True), ('tips at the origin', False)]
    y = 380
    for t, head in rows:
        label(d, x, y, t, 52 if head else 48, ACCENT if head else INK)
        y += 108 if head else 92
    return c


def b05():
    names = ['13-dome-parts-material-preview-before-hand-edit.png', '14-dome-hand-edit-pink-picker-before-D1AAB6.png',
             '15-dome-hand-edit-cherry-restored-pink-after.png']
    caps = ['13 · before: washed out', '14 · before the edit', '15 · after: cover pink']
    c = Image.new('RGB', (W, H), CREAM)
    d = ImageDraw.Draw(c)
    ims = [shot(n) for n in names]
    x = 40
    for im, cap in zip(ims, caps):
        s_ = fit(im.crop((380, 200, 960, 620)), 640, 470)
        framed(c, s_, x, 40)
        label(d, x, 40 + s_.height + 12, "Kiran's screenshot " + cap, 32, MUTED)
        x += 680
    # Only screenshot 14's Hex field: GATE T §8.6b read the field border in 15's crop as an overlapping label.
    for im, cap in zip(ims[1:2], ['14 · Dome_Pink Hex field, before']):
        s_ = fit(im.crop((1355, 505, 1562, 532)), 520, 300)   # the Hex row only (GATE T §8.3b flagged the slider tracks)
        framed(c, s_, x, 40 if cap.startswith('14') else 420)
        label(d, x, (40 if cap.startswith('14') else 420) + s_.height + 10, "Kiran's screenshot " + cap, 30, MUTED)
    label(d, 40, 600, 'Crops of the viewport and of the picker\'s Hex field; nothing retouched', 32, MUTED)
    y0 = 860
    label(d, 40, y0, "Kiran's hand edit in Blender's Material tab (TEST-REPORT A3.10) · swatches drawn from the recorded hex", 40, MUTED)
    rows = [('Dome_Pink (cover)', '#D1AAB6', '#D17390', 'Saturation 0.184 → 0.45'),
            ('Dome_Red (cherry)', '#DA303F', '#A6111E', 'Saturation 0.90, Value 0.65'),
            ('Dome_Cream (base)', '#F9EDD3', '#F9DEA2', 'Saturation 0.35 (before ≈, computed)')]
    y = y0 + 80
    for name, a, b, how in rows:
        label(d, 40, y + 14, name, 48)
        for k, hx in enumerate((a, b)):
            bx = 640 + k * 560
            d.rectangle([bx, y, bx + 110, y + 110 - 30], fill=tuple(int(hx[i:i + 2], 16) for i in (1, 3, 5)), outline=INK, width=2)
            label(d, bx + 130, y + 14, ('≈' if (k == 0 and name.startswith('Dome_Cream')) else '') + hx, 48, INK, MONO)
        label(d, 1130, y + 10, '→', 56)
        label(d, 1820, y + 14, how, 46)
        y += 140
    return c


def b07():
    im = shot('19-godot-scene-camera-run.png')
    c = Image.new('RGB', (W, H), CREAM)
    d = ImageDraw.Draw(c)
    s = fit(im.crop((107, 138, 1385, 848)), 2400, 1300)
    x = (W - s.width) // 2
    framed(c, s, x, 30)
    label(d, x, 30 + s.height + 16, "Kiran's screenshot 19, cropped to the game view · Godot 4.7.2 · Run Current Scene · left to right: biscuit platform, dessert dome, fork, 0.5 m jelly reference cube (not an asset)", 34, MUTED)
    return c


def headless_rows():
    lines = [json.loads(l) for l in RUN_LOG.read_text().splitlines() if l.startswith('{')]
    summary = [l for l in RUN_LOG.read_text().splitlines() if l.startswith('A3 ASSET CHECKS:')]
    if summary != ['A3 ASSET CHECKS: 36 checks / 0 failures']:
        sys.exit(f'STOPPED: unexpected summary {summary}')
    passes = sum(1 for l in lines if l['status'] == 'PASS')
    fails = sum(1 for l in lines if l['status'] == 'FAIL')
    if (passes, fails) != (36, 0):
        sys.exit(f'STOPPED: log has {passes} PASS / {fails} FAIL')
    by = {l['id']: l['observed'] for l in lines}
    out = []
    for k in ('fork', 'dome', 'platform'):
        size = by[f'{k}.A3_size']['size']
        tris = by[f'{k}.A7_triangles']
        gap = by[f'{k}.B2_on_floor']['difference']
        out.append((k, size, tris['triangles'], tris['budget'], gap))
    return out, summary[0]


def b09():
    rows, summary = headless_rows()
    brief = {'fork': '0.5 × 0.05 × 1.5', 'dome': '1 × 1 × 0.75', 'platform': '2 × 1.5 × 0.25'}
    names = {'fork': 'Fork', 'dome': 'Dessert dome', 'platform': 'Biscuit platform'}
    c = Image.new('RGB', (W, H), CREAM)
    d = ImageDraw.Draw(c)
    label(d, 60, 40, 'The brief (CHANGE-BRIEF.md, A3 v1)  beside  the headless check (evidence/a3-assets-run.log)', 44, MUTED)
    cols = [60, 760, 1400, 2160, 2700]
    heads = ['Asset', 'Brief W × D × H (m)', 'Headless X × Y × Z (m)', 'Triangles / budget', 'Lowest − floor']
    for x, h in zip(cols, heads):
        label(d, x, 150, h, 46, ACCENT)
    d.line([60, 225, W - 60, 225], fill=LINE, width=3)
    y = 260
    for k, size, tris, budget, gap in rows:
        label(d, cols[0], y, names[k], 54)
        label(d, cols[1], y, brief[k], 54, INK, MONO)
        label(d, cols[2], y, ' × '.join(f'{v:g}' for v in [round(s, 3) for s in size]), 54, INK, MONO)
        label(d, cols[3], y, f'{tris} / {budget}', 54, INK, MONO)
        label(d, cols[4], y, '0' if gap == 0 else f'{gap:.1e}', 54, INK, MONO)
        y += 130
    label(d, 60, y + 10, 'Blender is Z-up, Godot is Y-up: the brief\'s height becomes Godot\'s Y, its depth Godot\'s Z.', 42, MUTED)
    d.rectangle([60, y + 110, W - 60, y + 260], fill=(48, 61, 52))
    label(d, 110, y + 140, f'Headless · numbers only · {summary} · exit 0', 62, (255, 253, 248), MONO)
    label(d, 60, y + 300, 'Nothing is rendered: no colour, lighting or look. Tolerance 1 mm. Fork tips 2.98e-08 m above the floor (rounding).', 42, MUTED)
    return c


def b02():
    im = shot('19-godot-scene-camera-run.png')
    crops = {'Fork': (915, 335, 1025, 585), 'Dessert dome': (660, 450, 835, 600), 'Biscuit platform': (150, 500, 560, 610)}
    text = {'Fork': ['the hazard', 'stabs down from above;', 'time your jumps', '0.5 × 0.05 × 1.5 m', '3 jellies tall · ≤ 100 tris'],
            'Dessert dome': ['the goal', 'at the end of the level', '', '1 × 1 × 0.75 m', '2 jellies wide · ≤ 300 tris'],
            'Biscuit platform': ['a stepping stone', 'to land on; planned for', 'future levels', '2 × 1.5 × 0.25 m', '4 jellies wide · ≤ 60 tris']}
    c = Image.new('RGB', (W, H), CREAM)
    d = ImageDraw.Draw(c)
    x = 60
    for name, box in crops.items():
        s = fit(im.crop(box), 900, 560)
        framed(c, s, x + (960 - s.width) // 2, 60)
        label(d, x, 680, name, 72, INK, SERIF)
        y = 790
        for k, t in enumerate(text[name]):
            label(d, x, y, t, 50, ACCENT if k == 0 else INK)
            y += 74
        x += 1060
    label(d, 60, 1330, "Crops of Kiran's screenshot 19 (Godot scene camera) · roles and sizes from CHANGE-BRIEF.md, A3 v1 · jelly = 0.5 m", 36, MUTED)
    return c


def main():
    out = REEL / 'images'
    out.mkdir(exist_ok=True)
    made = {'B02-three-assets.png': b02(), 'B03-fork-prompt.png': b03(), 'B04-fork-built.png': b04(),
            'B05-hand-edit.png': b05(), 'B07-scene-camera.png': b07(), 'B09-headless-vs-brief.png': b09()}
    sums = []
    for name, im in made.items():
        p = out / name
        im.save(p, optimize=True)
        sums.append(f'{sha(p)}  {name}')
        print(name, im.size)
    (out / 'images.sha256').write_text('\n'.join(sums) + '\n')


if __name__ == '__main__':
    main()
