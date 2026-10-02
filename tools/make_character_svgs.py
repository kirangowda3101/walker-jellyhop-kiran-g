"""Draws the CHARACTER-SHEET.md reference images as SVG.
Written by Claude at Kiran's request. Run from the project root: python3 tools/make_character_svgs.py
All sizes are in game pixels at the 1280x720 base viewport; sheets are drawn at a stated scale.
"""
import os, math

JELLY, SHADE, HIGHLIGHT, OUTLINE = "#3CCFC4", "#1F8E92", "#E8FFFA", "#0F3440"
SAUCE, TABLE, PLATE, FORK, ROOM = "#B4472A", "#2A2320", "#E9E4DA", "#9AA2A9", "#1B1716"
BOX_W = 52                     # both collision boxes are 52 px wide and bottom-aligned
BOX_STAND, BOX_LOW = 58, 44    # standing box height, low box height (crouch, landing, bored)
FONT = 'font-family="Helvetica, Arial, sans-serif"'

# name, game state, plays, asset id, bottom width, height, lean (deg, + = toward facing), face, kind,
# taper (top width minus bottom width), collision box ("stand", "low", or "off")
POSES = [
    ("Turnaround", "reference", "-", "CHAR-REF", 64, 64, 0, "neutral", "ref", 0, "stand"),
    ("Idle wobble", "standing still", "loop", "CHAR-IDLE", 64, 64, 0, "neutral", "body", 0, "stand"),
    ("Bored slump", "no input for a few seconds", "loop", "CHAR-BORED", 84, 48, 0, "bored", "body", -20, "low"),
    ("Scoot A: squash + lean", "moving on a plate", "loop", "CHAR-SCOOT-A", 72, 56, 8, "neutral", "body", 0, "stand"),
    ("Scoot B: stretch + lean", "moving on a plate", "loop", "CHAR-SCOOT-B", 56, 72, 10, "neutral", "body", 0, "stand"),
    ("Crouch", "hop anticipation", "once", "CHAR-ANTIC", 76, 50, 0, "determined", "body", 0, "low"),
    ("Stretched", "rising", "once, holds", "CHAR-RISE", 52, 80, 4, "up", "body", 0, "stand"),
    ("Widened, eyes down", "falling", "once, holds", "CHAR-FALL", 70, 60, 0, "down", "body", 0, "stand"),
    ("Squash", "landing", "once", "CHAR-LAND", 80, 46, 0, "happy", "body", 0, "low"),
    ("Worried, eyes up", "shadow growing over its plate", "loop", "CHAR-WORRY", 62, 66, -6, "worried", "body", 0, "stand"),
    ("Splat", "fork or sauce failure", "once", "CHAR-SPLAT", 100, 22, 0, "x", "splat", 0, "off"),
    ("Re-forming", "respawn", "once", "CHAR-RESPAWN", 64, 40, 0, "neutral", "reform", 0, "off"),
    ("Relief stretch", "reached the dome", "loop", "CHAR-CELEBRATE", 56, 78, 0, "happy", "body", 14, "stand"),
]

def svg_open(w, h, bg="#fafafa"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" {FONT}>\n'
            f'<rect x="0" y="0" width="{w}" height="{h}" fill="{bg}"/>\n')

def text(x, y, t, size=14, fill="#111", anchor="start", weight="normal"):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" text-anchor="{anchor}" font-weight="{weight}">{t}</text>\n'

def face(kind, w, h, sil):
    """Face elements in game px, body origin at bottom-center. Facing right: features shift +3 px."""
    if sil:
        return ""
    fx = 3
    ey = -h * 0.62
    ex = 9
    o = OUTLINE
    s = ""
    if kind in ("neutral", "determined", "up", "down", "worried"):
        dy = {"up": -2, "down": 2, "worried": -1.5}.get(kind, 0)
        s += f'<circle cx="{fx-ex}" cy="{ey+dy}" r="4" fill="{o}"/><circle cx="{fx+ex}" cy="{ey+dy}" r="4" fill="{o}"/>'
    if kind == "neutral" or kind == "up":
        s += f'<path d="M{fx-4},{-h*0.38} q4,3 8,0" fill="none" stroke="{o}" stroke-width="2"/>'
    if kind == "determined":
        s += f'<path d="M{fx-ex-4},{ey-6} l7,1.5 M{fx+ex+4},{ey-6} l-7,1.5" stroke="{o}" stroke-width="2"/>'
        s += f'<line x1="{fx-3}" y1="{-h*0.36}" x2="{fx+3}" y2="{-h*0.36}" stroke="{o}" stroke-width="2"/>'
    if kind == "down":
        s += f'<ellipse cx="{fx}" cy="{-h*0.36}" rx="2.5" ry="2" fill="none" stroke="{o}" stroke-width="2"/>'
    if kind == "worried":
        s += f'<path d="M{fx-ex-4},{ey-6} l7,-2.5 M{fx+ex+4},{ey-6} l-7,-2.5" stroke="{o}" stroke-width="2"/>'
        s += f'<ellipse cx="{fx}" cy="{-h*0.34}" rx="2.5" ry="3" fill="none" stroke="{o}" stroke-width="2"/>'
    if kind == "happy":
        s += (f'<path d="M{fx-ex-4},{ey} q4,-5 8,0 M{fx+ex-4},{ey} q4,-5 8,0" fill="none" stroke="{o}" stroke-width="2"/>'
              f'<path d="M{fx-6},{-h*0.38} q6,5 12,0" fill="none" stroke="{o}" stroke-width="2"/>')
    if kind == "bored":
        for cx in (fx-ex, fx+ex):
            s += f'<path d="M{cx-4},{ey} a4,4 0 0 0 8,0 Z" fill="{o}"/><line x1="{cx-5}" y1="{ey}" x2="{cx+5}" y2="{ey}" stroke="{o}" stroke-width="2"/>'
        s += f'<line x1="{fx-4}" y1="{-h*0.36}" x2="{fx+4}" y2="{-h*0.36}" stroke="{o}" stroke-width="2"/>'
    return s

def rounded_poly(pts, r):
    """Closed path through pts with each corner rounded by about r px."""
    d = ""
    n = len(pts)
    for i in range(n):
        x0, y0 = pts[i - 1]
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        la = math.hypot(x1 - x0, y1 - y0)
        lb = math.hypot(x2 - x1, y2 - y1)
        ra, rb = min(r, la / 2), min(r, lb / 2)
        ax, ay = x1 + (x0 - x1) * ra / la, y1 + (y0 - y1) * ra / la
        bx, by = x1 + (x2 - x1) * rb / lb, y1 + (y2 - y1) * rb / lb
        d += (f"M{ax:.1f},{ay:.1f}" if i == 0 else f" L{ax:.1f},{ay:.1f}") + f" Q{x1},{y1} {bx:.1f},{by:.1f}"
    return d + " Z"

def body(w, h, lean, kind, sil=False, taper=0):
    """w = bottom width, h = height; taper = top width minus bottom width (0 = rounded box)."""
    fill = "#000" if sil else JELLY
    stroke = "#000" if sil else OUTLINE
    wt = w + taper
    r = min(w, wt, h) * 0.19
    s = f'<g transform="skewX({-lean})">'
    if taper == 0:
        s += f'<rect x="{-w/2}" y="{-h}" width="{w}" height="{h}" rx="{r:.1f}" fill="{fill}" stroke="{stroke}" stroke-width="3"/>'
    else:
        d = rounded_poly([(-w/2, 0), (w/2, 0), (wt/2, -h), (-wt/2, -h)], r)
        s += f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="3"/>'
    if not sil:
        bw = w + taper * 0.16 - 8           # shade band follows the body width near the bottom
        s += f'<rect x="{-bw/2:.1f}" y="{-h*0.26:.1f}" width="{bw:.1f}" height="{h*0.2:.1f}" rx="{h*0.1:.1f}" fill="{SHADE}"/>'
        s += f'<ellipse cx="0" cy="{-h+5}" rx="{wt*0.2:.1f}" ry="2.5" fill="{HIGHLIGHT}"/>'
        s += face(kind, min(w, wt), h, sil)
    return s + "</g>"

def splat(sil=False):
    fill = "#000" if sil else JELLY
    stroke = "#000" if sil else OUTLINE
    s = (f'<path d="M-50,0 q8,-14 22,-12 q8,-12 26,-6 q16,-10 28,0 q16,-4 24,18 Z" fill="{fill}" stroke="{stroke}" stroke-width="3"/>'
         f'<circle cx="-46" cy="-26" r="4" fill="{fill}" stroke="{stroke}" stroke-width="2"/><circle cx="44" cy="-30" r="5" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')
    if not sil:
        s += (f'<path d="M-12,-11 l6,-6 M-12,-17 l6,6 M10,-11 l6,-6 M10,-17 l6,6" stroke="{OUTLINE}" stroke-width="2"/>'
              f'<ellipse cx="0" cy="-17" rx="10" ry="1.8" fill="{HIGHLIGHT}"/>')
    return s

def reform(sil=False):
    fill = "#000" if sil else JELLY
    stroke = "#000" if sil else OUTLINE
    s = (f'<path d="M-44,0 q10,-8 24,-6 L-20,-40 L20,-40 L20,-6 q14,-2 24,6 Z" fill="{fill}" stroke="{stroke}" stroke-width="3" stroke-linejoin="round"/>')
    if not sil:
        s += (f'<ellipse cx="0" cy="-35" rx="10" ry="2.5" fill="{HIGHLIGHT}"/>'
              f'<circle cx="-6" cy="-24" r="4" fill="{OUTLINE}"/><circle cx="12" cy="-24" r="4" fill="{OUTLINE}"/>'
              f'<path d="M-14,-46 l0,-8 M0,-48 l0,-10 M14,-46 l0,-8" stroke="{OUTLINE}" stroke-width="2"/>')
    return s

def pose_art(p, sil=False):
    name, state, plays, aid, w, h, lean, fk, kind, taper, box = p
    if kind == "splat":
        return splat(sil)
    if kind == "reform":
        return reform(sil)
    return body(w, h, lean, fk, sil, taper)

def collision_box(p):
    box = p[10]
    bh = BOX_LOW if box == "low" else BOX_STAND
    color = "#999" if box == "off" else "#D6247A"
    return (f'<rect x="{-BOX_W/2}" y="{-bh}" width="{BOX_W}" height="{bh}" fill="none" '
            f'stroke="{color}" stroke-width="1.5" stroke-dasharray="4 3"/>')

def overhang(p):
    """Art extent beyond (+) or inside (-) the pose's collision box, ignoring lean: (each side, top)."""
    w, h = max(p[4], p[4] + p[9]), p[5]
    if p[8] == "splat":
        w, h = 100, 22
    if p[8] == "reform":
        w, h = 88, 40
    bh = BOX_LOW if p[10] == "low" else BOX_STAND
    return (w - BOX_W) / 2, h - bh

files = {}

# ---------- silhouette test at actual on-screen size ----------
W, H = 1280, 720
s = svg_open(W, H, "#e6e6e6")
s += text(24, 40, "Silhouette test · actual size in the 1280×720 viewport (view this file at 100%)", 22, "#111", "start", "bold")
s += text(24, 66, "Every pose filled solid black at its real in-game size (resting cube = 64 × 64 px).", 15)
s += text(24, 88, "Grey outlines: a rough plate and fork size for comparison only (environment sizes are not decided yet).", 15, "#555")
s += f'<rect x="0" y="560" width="{W}" height="160" fill="#cfcfcf"/>\n'
s += '<path d="M24,560 L1256,560 L1236,574 L44,574 Z" fill="none" stroke="#888" stroke-width="2"/>\n'
s += '<g fill="none" stroke="#888" stroke-width="2"><rect x="934" y="120" width="12" height="230"/><rect x="900" y="350" width="80" height="12"/>'
for tx in (904, 926, 950, 972):
    s += f'<path d="M{tx-4},362 L{tx+4},362 L{tx},450 Z"/>'
s += '</g>\n' + text(990, 290, "rough fork size", 14, "#555")
x = 30
for i, p in enumerate(POSES):
    w = {"splat": 108, "reform": 88}.get(p[8], p[4] + 8)
    cx = x + w / 2
    s += f'<g transform="translate({cx},560)">{pose_art(p, True)}</g>\n'
    s += text(cx, 600 + (i % 2) * 18, str(i + 1), 13, "#333", "middle")
    x += w + 16
s += text(24, 690, "Numbers match the pose list in CHARACTER-SHEET.md (1 = turnaround reference, shown as the resting cube).", 14, "#333")
s += '</svg>\n'
files["silhouette.svg"] = s

# ---------- turnaround reference, drawn at 3.5x ----------
S = 3.5
W, H = 1280, 520
s = svg_open(W, H)
s += text(24, 40, "Turnaround reference · drawn at 3.5× (1 game px = 3.5 px here) · resting cube 64 × 64", 22, "#111", "start", "bold")
base = 430
s += f'<line x1="40" y1="{base}" x2="{W-40}" y2="{base}" stroke="#bbb" stroke-width="2"/>\n'
# height bar
hx = 90
s += f'<line x1="{hx}" y1="{base}" x2="{hx}" y2="{base-64*S}" stroke="#111" stroke-width="3"/>'
for v in (0, 32, 64):
    s += f'<line x1="{hx-10}" y1="{base-v*S}" x2="{hx+10}" y2="{base-v*S}" stroke="#111" stroke-width="3"/>'
    s += text(hx - 16, base - v * S + 5, f"{v} px", 14, "#111", "end")
s += f'<line x1="{hx}" y1="{base-64*S*0.62}" x2="{W-40}" y2="{base-64*S*0.62}" stroke="#D6247A" stroke-width="1" stroke-dasharray="6 5"/>'
def view_front(cx):
    return f'<g transform="translate({cx},{base}) scale({S})">{body(64,64,0,"neutral")}</g>'
def view_back(cx):
    g = (f'<rect x="-32" y="-64" width="64" height="64" rx="12.2" fill="{JELLY}" stroke="{OUTLINE}" stroke-width="3"/>'
         f'<rect x="-29" y="-16.6" width="58" height="12.8" rx="6.4" fill="{SHADE}"/><ellipse cx="0" cy="-59" rx="12.8" ry="2.5" fill="{HIGHLIGHT}"/>')
    return f'<g transform="translate({cx},{base}) scale({S})">{g}</g>'
def view_side(cx):
    g = (f'<rect x="-32" y="-64" width="64" height="64" rx="12.2" fill="{JELLY}" stroke="{OUTLINE}" stroke-width="3"/>'
         f'<rect x="-29" y="-16.6" width="58" height="12.8" rx="6.4" fill="{SHADE}"/><ellipse cx="0" cy="-59" rx="12.8" ry="2.5" fill="{HIGHLIGHT}"/>'
         f'<line x1="29" y1="-40" x2="29" y2="-38" stroke="{OUTLINE}" stroke-width="3"/>')
    return f'<g transform="translate({cx},{base}) scale({S})">{g}</g>'
def view_three_quarter(cx):
    g = (f'<path d="M14,-62 L30,-55 L30,-6 L14,0 Z" fill="{SHADE}" stroke="{OUTLINE}" stroke-width="3" stroke-linejoin="round"/>'
         f'<rect x="-34" y="-64" width="50" height="64" rx="10" fill="{JELLY}" stroke="{OUTLINE}" stroke-width="3"/>'
         f'<rect x="-31" y="-16.6" width="44" height="12.8" rx="6.4" fill="{SHADE}"/><ellipse cx="-6" cy="-59" rx="11" ry="2.5" fill="{HIGHLIGHT}"/>'
         f'<circle cx="-14" cy="-39.7" r="4" fill="{OUTLINE}"/><circle cx="2" cy="-39.7" r="3.6" fill="{OUTLINE}"/>'
         f'<path d="M-10,-24.3 q4,3 8,0" fill="none" stroke="{OUTLINE}" stroke-width="2"/>')
    return f'<g transform="translate({cx},{base}) scale({S})">{g}</g>'
for cx, fn, lab in [(300, view_front, "front (game view, facing right)"), (580, view_three_quarter, "three-quarter"),
                    (860, view_side, "side"), (1140, view_back, "back")]:
    s += fn(cx) + "\n" + text(cx, base + 40, lab, 16, "#111", "middle", "bold")
s += text(24, 500, "Pink dashed line = eye line, 24 px below the top. Highlight is top-center in every view, so a flip looks identical; facing shows through the +3 px face offset and the lean.", 15)
s += '</svg>\n'
files["turnaround.svg"] = s

# ---------- poses and collision sheets, drawn at 2.5x ----------
S = 2.5
COLS, CW, CH = 5, 280, 330
def grid_sheet(title, subtitle, with_box):
    rows = math.ceil(len(POSES) / COLS)
    W, H = COLS * CW, 90 + rows * CH
    s = svg_open(W, H)
    s += text(20, 36, title, 22, "#111", "start", "bold") + text(20, 64, subtitle, 15)
    for i, p in enumerate(POSES):
        col, row = i % COLS, i // COLS
        x0, y0 = col * CW, 90 + row * CH
        cx, by = x0 + CW / 2, y0 + 250
        s += f'<rect x="{x0+6}" y="{y0+4}" width="{CW-12}" height="{CH-10}" fill="#fff" stroke="#ccc"/>'
        s += f'<line x1="{x0+20}" y1="{by}" x2="{x0+CW-20}" y2="{by}" stroke="#bbb" stroke-width="2"/>'
        art = pose_art(p) if p[8] != "ref" else body(64, 64, 0, "neutral")
        s += f'<g transform="translate({cx},{by}) scale({S})">{art}{collision_box(p) if with_box else ""}</g>\n'
        s += text(x0 + 16, y0 + 26, f"{i+1}. {p[0]}", 15, "#111", "start", "bold")
        if with_box and p[10] == "off":
            s += text(x0 + 16, by + 26, "hits off: hazards ignore the jelly", 13, "#777")
            s += text(x0 + 16, by + 44, "until control returns (grey = inactive)", 12, "#777")
        elif with_box:
            side, top = overhang(p)
            label = "low box 52×44" if p[10] == "low" else "standing box 52×58"
            s += text(x0 + 16, by + 26, f"{label}: sides {side:+.0f}, top {top:+.0f} px", 13, "#D6247A")
            s += text(x0 + 16, by + 44, "(+ art beyond box · − box beyond art)", 12, "#777")
        else:
            s += text(x0 + 16, by + 26, f"{p[1]}", 13, "#333")
            s += text(x0 + 16, by + 44, f"{p[2]} · {p[3]}", 13, "#555")
    s += '</svg>\n'
    return s
files["poses.svg"] = grid_sheet("Poses · drawn at 2.5× · facing right (flip for left)",
                                "Same reference cube, outline weight, eye spacing, and top-center highlight in every pose. 1 = turnaround reference (see turnaround.svg).", False)
files["collision.svg"] = grid_sheet("Collision overlay · two bottom-aligned boxes, same 2.5× scale",
                                    "Pink dashed = active box: standing 52 × 58, or low 52 × 44 for crouch, landing, and bored. Grey = hits off. Numbers ignore lean.", True)

# ---------- palette and contrast check ----------
def lum(hx):
    r, g, b = [int(hx[i:i+2], 16) / 255 for i in (1, 3, 5)]
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
def contrast(a, b):
    la, lb = sorted([lum(a), lum(b)], reverse=True)
    return (la + 0.05) / (lb + 0.05)
W, H = 1280, 620
s = svg_open(W, H)
s += text(24, 40, "Palette · character colors checked against the environment (actual game size)", 22, "#111", "start", "bold")
s += f'<rect x="24" y="64" width="760" height="260" fill="{ROOM}"/><rect x="24" y="264" width="760" height="60" fill="{TABLE}"/>'
s += f'<path d="M60,264 L320,264 L300,280 L80,280 Z" fill="{PLATE}"/><path d="M500,264 L760,264 L740,280 L520,280 Z" fill="{PLATE}"/>'
s += f'<path d="M340,272 q40,-10 80,-4 q30,4 60,4 l0,8 l-140,0 Z" fill="{SAUCE}"/>'
s += f'<g transform="translate(190,264)">{body(64,64,0,"neutral")}</g><g transform="translate(410,170)">{body(52,80,4,"up")}</g>'
s += f'<rect x="626" y="64" width="12" height="110" fill="{FORK}"/><rect x="600" y="174" width="64" height="10" fill="{FORK}"/>'
for tx in (604, 622, 642, 660):
    s += f'<path d="M{tx-4},184 L{tx+4},184 L{tx},240 Z" fill="{FORK}"/>'
sw = [("jelly", JELLY), ("shade", SHADE), ("highlight", HIGHLIGHT), ("outline", OUTLINE)]
env = [("sauce", SAUCE), ("table", TABLE), ("plate", PLATE), ("fork", FORK), ("room", ROOM)]
s += text(820, 84, "Character palette", 16, "#111", "start", "bold")
for i, (n, c) in enumerate(sw):
    y = 100 + i * 44
    s += f'<rect x="820" y="{y}" width="60" height="32" fill="{c}" stroke="#999"/>' + text(892, y + 22, f"{n}  {c}", 15)
s += text(1050, 84, "Environment (placeholders)", 16, "#111", "start", "bold")
for i, (n, c) in enumerate(env):
    y = 100 + i * 44
    s += f'<rect x="1050" y="{y}" width="60" height="32" fill="{c}" stroke="#999"/>' + text(1122, y + 22, f"{n}  {c}", 15)
checks = [("jelly vs table", JELLY, TABLE), ("jelly vs room", JELLY, ROOM), ("jelly vs plate", JELLY, PLATE),
          ("outline vs plate", OUTLINE, PLATE), ("jelly vs fork", JELLY, FORK), ("outline vs fork", OUTLINE, FORK),
          ("jelly vs sauce", JELLY, SAUCE), ("sauce vs table", SAUCE, TABLE)]
s += text(24, 370, "Contrast ratios (WCAG formula; higher = easier to tell apart)", 16, "#111", "start", "bold")
for i, (n, a, b) in enumerate(checks):
    col, row = i % 2, i // 2
    s += text(24 + col * 400, 402 + row * 28, f"{n}: {contrast(a, b):.1f} : 1", 15)
s += text(24, 530, "Reading: the jelly body carries it on the dark table and room; on pale plates and next to the steel fork the dark outline", 15)
s += text(24, 552, "carries it, so the outline must never be dropped or thinned. Sauce differs from the jelly mainly by hue (warm red vs cool aqua).", 15)
s += text(24, 590, "Environment colors are placeholders for this check only; the final environment palette is not decided yet.", 14, "#555")
s += '</svg>\n'
files["palette.svg"] = s

out = os.path.join("design", "character")
os.makedirs(out, exist_ok=True)
for n, c in files.items():
    with open(os.path.join(out, n), "w", encoding="utf-8") as fh:
        fh.write(c)
    print("wrote", os.path.join(out, n))
