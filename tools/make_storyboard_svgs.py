"""Draws the STORYBOARD.md panel thumbnails as simple SVG boxes-and-labels sketches.
Written by Claude at Kiran's request. Run from the project root: python3 tools/make_storyboard_svgs.py
"""
HEAD = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 360" width="640" height="360" font-family="Helvetica, Arial, sans-serif">
<defs>
<marker id="ar" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#111"/></marker>
<marker id="aw" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#fff"/></marker>
<pattern id="h" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="6" height="6" fill="#c8c8c8"/><line x1="0" y1="0" x2="0" y2="6" stroke="#333" stroke-width="2"/></pattern>
</defs>
<rect x="0" y="0" width="640" height="360" fill="#fafafa"/>
'''
def banner(t):
    return f'<rect x="0" y="0" width="640" height="26" fill="#111"/><text x="10" y="18" font-size="13" font-weight="bold" fill="#fff">{t}</text>\n'
FOOT = '<rect x="1.5" y="1.5" width="637" height="357" fill="none" stroke="#111" stroke-width="3"/>\n</svg>\n'

def jelly(x, y, w, h, face="neutral"):
    # x,y = top-left
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{min(w,h)*0.22:.0f}" fill="#fff" stroke="#111" stroke-width="2.5"/>'
    cx = x + w/2; ey = y + h*0.38; dx = w*0.18; r = max(2, min(w,h)*0.07)
    if face == "happy":
        s += f'<path d="M{cx-dx-r},{ey} q{r},{-r*1.4} {2*r},0 M{cx+dx-r},{ey} q{r},{-r*1.4} {2*r},0" fill="none" stroke="#111" stroke-width="2"/>'
        s += f'<path d="M{cx-w*0.12},{y+h*0.62} q{w*0.12},{h*0.14} {w*0.24},0" fill="none" stroke="#111" stroke-width="2"/>'
    else:
        py = ey - (r*0.5 if face == "worried" else 0)
        s += f'<circle cx="{cx-dx}" cy="{py}" r="{r}" fill="#111"/><circle cx="{cx+dx}" cy="{py}" r="{r}" fill="#111"/>'
        if face == "worried":
            s += f'<path d="M{cx-dx-r*1.6},{ey-r*2.2} L{cx-dx+r*1.4},{ey-r*3.2} M{cx+dx+r*1.6},{ey-r*2.2} L{cx+dx-r*1.4},{ey-r*3.2}" stroke="#111" stroke-width="2"/>'
            s += f'<ellipse cx="{cx}" cy="{y+h*0.68}" rx="{w*0.06}" ry="{h*0.06}" fill="none" stroke="#111" stroke-width="2"/>'
        else:
            s += f'<path d="M{cx-w*0.1},{y+h*0.64} q{w*0.1},{h*0.07} {w*0.2},0" fill="none" stroke="#111" stroke-width="2"/>'
    return s + "\n"

def fork(cx, top, bottom, w=34):
    # side view fork hanging down, tines at bottom
    hw = 4
    tine_top = bottom - 36
    s = f'<rect x="{cx-hw}" y="{top}" width="{2*hw}" height="{tine_top-top}" fill="#9a9a9a" stroke="#111" stroke-width="1.5"/>'
    s += f'<path d="M{cx-w/2},{tine_top} L{cx+w/2},{tine_top} L{cx+w/2},{tine_top+6} L{cx-w/2},{tine_top+6} Z" fill="#9a9a9a" stroke="#111" stroke-width="1.5"/>'
    for i in range(4):
        tx = cx - w/2 + 2 + i*(w-4)/3
        s += f'<path d="M{tx-2.5},{tine_top+6} L{tx+2.5},{tine_top+6} L{tx},{bottom} Z" fill="#9a9a9a" stroke="#111" stroke-width="1.2"/>'
    return s + "\n"

def plate_side(x1, x2, top):
    # shallow dish on table, side view
    return (f'<path d="M{x1},{top} L{x2},{top} L{x2-14},{top+12} L{x1+14},{top+12} Z" fill="#ececec" stroke="#111" stroke-width="2"/>'
            f'<line x1="{x1+20}" y1="{top+4}" x2="{x2-20}" y2="{top+4}" stroke="#999" stroke-width="1.5"/>\n')

def table_side(top=270):
    return f'<rect x="0" y="{top}" width="640" height="{360-top}" fill="#555"/>\n'

def label(x, y, t, size=11, fill="#111", anchor="start", weight="normal"):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" text-anchor="{anchor}" font-weight="{weight}">{t}</text>\n'

files = {}

# ---------- Panel 1: wide, high angle, design view ----------
s = HEAD + banner("1 · WIDE · HIGH ANGLE · DESIGN VIEW (title / intro)")
s += '<polygon points="40,345 600,345 535,130 105,130" fill="#555"/>\n'
plates = [(130,300),(205,280),(280,262),(355,244),(425,226),(490,208)]
for i,(px,py) in enumerate(plates):
    s += f'<ellipse cx="{px}" cy="{py}" rx="30" ry="11" fill="#ececec" stroke="#111" stroke-width="2"/>'
s += '<path d="M240,278 q12,-8 26,-2 q8,8 -4,12 q-14,4 -22,-10 Z" fill="url(#h)" stroke="#111"/>\n'
s += '<path d="M385,242 q14,-8 26,-1 q6,8 -6,11 q-14,3 -20,-10 Z" fill="url(#h)" stroke="#111"/>\n'
s += label(232, 300, "sauce", 10, "#fff") + label(380, 264, "sauce", 10, "#fff")
s += '<ellipse cx="280" cy="262" rx="18" ry="6" fill="#222" opacity="0.7"/><ellipse cx="425" cy="226" rx="14" ry="5" fill="#222" opacity="0.7"/>\n'
s += fork(280, 26, 200, 26) + fork(425, 26, 170, 24) + fork(490, 26, 150, 22)
s += jelly(121, 284, 18, 15)
s += '<path d="M520,200 a26,30 0 0 1 52,0 Z" fill="none" stroke="#111" stroke-width="2.5"/><line x1="514" y1="200" x2="578" y2="200" stroke="#111" stroke-width="2.5"/><circle cx="546" cy="168" r="4" fill="#fff" stroke="#111" stroke-width="2"/>\n'
s += label(540, 222, "dome", 11, "#fff", "middle", "bold")
s += label(130, 330, "jelly", 11, "#fff", "middle", "bold")
s += label(20, 52, "JELLY HOP:", 18, "#111", "start", "bold") + label(20, 74, "FORK FROM ABOVE", 18, "#111", "start", "bold")
s += label(20, 96, "any key skips the intro", 12)
s += '<path d="M560,330 L170,330" stroke="#fff" stroke-width="2.5" stroke-dasharray="7 5" marker-end="url(#aw)"/>\n'
s += label(560, 322, "CAMERA: pan dome → jelly (slice: eye-level side-view pan, skippable)", 10, "#fff", "end")
s += FOOT
files["01-establishing-wide.svg"] = s

# ---------- Panel 2: medium, eye level, gameplay - core action hop ----------
s = HEAD + banner("2 · MEDIUM · EYE LEVEL · GAMEPLAY VIEW (core action: hop)")
s += table_side()
s += plate_side(60, 230, 258) + plate_side(400, 570, 258)
s += '<path d="M250,268 q40,-7 90,-2 q35,4 40,4 l0,4 l-130,0 Z" fill="url(#h)" stroke="#111"/>\n'
s += label(315, 300, "sauce = splat", 11, "#fff", "middle", "bold")
s += label(145, 300, "safe plate", 11, "#fff", "middle") + label(485, 300, "next plate", 11, "#fff", "middle")
s += '<rect x="112" y="222" width="56" height="36" rx="9" fill="none" stroke="#111" stroke-width="2" stroke-dasharray="4 3"/>\n'
s += label(140, 214, "crouch", 10, "#111", "middle")
s += '<path d="M160,220 Q310,40 470,228" fill="none" stroke="#111" stroke-width="2" stroke-dasharray="6 4" marker-end="url(#ar)"/>\n'
s += jelly(282, 108, 40, 58)
s += '<path d="M262,120 l-26,6 M262,136 l-32,4 M264,152 l-24,6" stroke="#111" stroke-width="2"/>\n'
s += label(330, 102, "stretched while rising", 10)
s += fork(485, 26, 120, 30)
s += label(510, 80, "fork raised", 10)
s += '<path d="M60,48 L190,48" stroke="#111" stroke-width="2" marker-end="url(#ar)"/>\n'
s += label(60, 42, "CAMERA: follows right, looks slightly ahead", 10)
s += FOOT
files["02-core-action-hop.svg"] = s

# ---------- Panel 3: close-up, low angle, design view - warning ----------
s = HEAD + banner("3 · CLOSE-UP · LOW ANGLE · DESIGN VIEW (the warning: worried pose)")
s += '<polygon points="0,360 640,360 640,300 0,300" fill="#555"/>\n'
s += '<ellipse cx="320" cy="312" rx="300" ry="34" fill="#ececec" stroke="#111" stroke-width="2.5"/>\n'
s += '<ellipse cx="320" cy="314" rx="190" ry="20" fill="#222" opacity="0.6"/>\n'
s += '<ellipse cx="320" cy="314" rx="110" ry="12" fill="none" stroke="#fff" stroke-width="1.5" stroke-dasharray="5 4"/>\n'
s += '<path d="M435,314 L500,314" stroke="#111" stroke-width="2" marker-end="url(#ar)"/><path d="M205,314 L140,314" stroke="#111" stroke-width="2" marker-end="url(#ar)"/>\n'
s += label(450, 232, "shadow grows =", 12, "#111", "start", "bold") + label(450, 248, "visual countdown", 12, "#111", "start", "bold")
s += jelly(255, 168, 130, 140, "worried")
# huge fork from above, low angle (tines pointing down at the jelly)
s += '<polygon points="270,26 370,26 360,58 280,58" fill="#9a9a9a" stroke="#111" stroke-width="2"/>\n'
for i,tx in enumerate([286,306,334,354]):
    s += f'<polygon points="{tx-8},58 {tx+8},58 {tx},128" fill="#9a9a9a" stroke="#111" stroke-width="1.5"/>'
s += '\n' + label(390, 70, "fork looms huge (small in a giant world)", 11)
s += '<path d="M392,86 q40,20 10,50" fill="none" stroke="#111" stroke-width="2" stroke-dasharray="4 3" marker-end="url(#ar)"/>\n'
s += label(20, 232, "worried face,", 11) + label(20, 247, "eyes look up at the fork", 11)
s += label(20, 160, "SFX-WARN: scrape plays once", 11, "#111", "start", "bold")
s += label(20, 175, "as the shadow starts", 11)
s += FOOT
files["03-warning-closeup-low.svg"] = s

# ---------- Panel 4: medium, eye level, gameplay - success ----------
s = HEAD + banner("4 · MEDIUM · EYE LEVEL · GAMEPLAY VIEW (success: safe landing)")
s += table_side()
s += plate_side(30, 200, 258) + plate_side(390, 560, 258)
s += '<path d="M220,268 q40,-7 90,-2 q35,4 40,4 l0,4 l-130,0 Z" fill="url(#h)" stroke="#111"/>\n'
s += fork(115, 26, 262, 34)
s += '<path d="M160,70 L160,200" stroke="#111" stroke-width="2.5" marker-end="url(#ar)"/>\n'
s += '<path d="M75,90 l0,40 M60,110 l0,40 M170,110 l0,40" stroke="#111" stroke-width="1.5"/>\n'
s += '<path d="M80,256 l-14,-10 M150,256 l14,-10 M115,250 l0,-14" stroke="#111" stroke-width="2"/>\n'
s += label(115, 300, "fork hits the empty plate", 11, "#fff", "middle")
s += jelly(442, 224, 66, 34, "happy")
s += '<path d="M432,258 l-12,4 M518,258 l12,4" stroke="#111" stroke-width="2"/>\n'
s += label(475, 214, "landing squash", 10, "#111", "middle")
s += label(475, 300, "jelly made it", 11, "#fff", "middle", "bold")
s += label(250, 52, "strike lands after the jelly moved", 11)
s += FOOT
files["04-success-landing.svg"] = s

# ---------- Panel 5: medium, eye level, gameplay - failure splat ----------
s = HEAD + banner("5 · MEDIUM · EYE LEVEL · GAMEPLAY VIEW (failure: splat)")
s += table_side()
s += plate_side(200, 440, 258)
s += fork(320, 26, 262, 38)
s += '<path d="M370,60 L370,190" stroke="#111" stroke-width="2.5" marker-end="url(#ar)"/>\n'
s += '<path d="M248,258 q20,-16 40,-10 q10,-14 32,-4 q22,-12 34,2 q22,-6 34,12 Z" fill="#fff" stroke="#111" stroke-width="2.5"/>\n'
s += '<circle cx="250" cy="226" r="5" fill="#fff" stroke="#111" stroke-width="2"/><circle cx="398" cy="222" r="6" fill="#fff" stroke="#111" stroke-width="2"/><circle cx="230" cy="244" r="3.5" fill="#fff" stroke="#111" stroke-width="2"/><circle cx="414" cy="244" r="4" fill="#fff" stroke="#111" stroke-width="2"/>\n'
s += '<path d="M282,252 l6,-6 M282,246 l6,6 M352,252 l6,-6 M352,246 l6,6" stroke="#111" stroke-width="2"/>\n'
s += label(320, 300, "splat · the fork stays in view (cause is visible)", 11, "#fff", "middle", "bold")
s += '<path d="M14,40 l10,8 l-10,8 l10,8 M626,40 l-10,8 l10,8 l-10,8 M14,300 l10,8 l-10,8 l10,8 M626,300 l-10,8 l10,8 l-10,8" fill="none" stroke="#111" stroke-width="2"/>\n'
s += label(40, 52, "CAMERA: short shake (fork splat only) · input locked", 11)
s += label(440, 330, "(sauce splat: same pose, no shake)", 10, "#fff")
s += FOOT
files["05-failure-splat.svg"] = s

# ---------- Panel 6: medium, eye level, gameplay - recovery ----------
s = HEAD + banner("6 · MEDIUM · EYE LEVEL · GAMEPLAY VIEW (recovery: respawn and retry)")
s += table_side()
s += plate_side(50, 230, 258) + plate_side(400, 580, 258)
s += '<path d="M250,268 q40,-7 90,-2 q35,4 40,4 l0,4 l-130,0 Z" fill="url(#h)" stroke="#111"/>\n'
s += '<path d="M106,258 q14,-10 34,-6 q20,-8 34,6 Z" fill="#fff" stroke="#111" stroke-width="2"/>\n'
s += '<rect x="115" y="204" width="50" height="50" rx="11" fill="none" stroke="#111" stroke-width="2" stroke-dasharray="4 3"/>\n'
s += '<path d="M128,246 l0,-24 M152,246 l0,-24" stroke="#111" stroke-width="2" marker-end="url(#ar)"/>\n'
s += label(140, 196, "re-forms (input locked until whole)", 10, "#111", "middle")
s += fork(140, 26, 120, 30)
s += label(162, 80, "this fork restarts at its safe window", 10)
s += '<ellipse cx="490" cy="258" rx="50" ry="5" fill="#222" opacity="0.7"/>\n'
s += fork(490, 26, 150, 32)
s += label(490, 300, "next fork still on its rhythm", 11, "#fff", "middle")
s += label(140, 300, "last safe plate", 11, "#fff", "middle", "bold")
s += '<path d="M430,54 L200,54" stroke="#111" stroke-width="2.5" marker-end="url(#ar)"/>\n'
s += label(430, 44, "CAMERA: glides back to the jelly (no snap)", 10, "#111", "end")
s += label(250, 120, "watch one cycle, then hop", 12, "#111", "start", "bold")
s += FOOT
files["06-recovery-respawn.svg"] = s

# ---------- Panel 7: close-up, high angle, design view - end ----------
s = HEAD + banner("7 · CLOSE-UP · HIGH ANGLE · DESIGN VIEW (end of session: dome reached)")
s += '<rect x="0" y="26" width="640" height="334" fill="#555"/>\n'
s += '<ellipse cx="320" cy="205" rx="200" ry="140" fill="#ececec" stroke="#111" stroke-width="2.5"/>\n'
s += '<ellipse cx="320" cy="205" rx="150" ry="104" fill="none" stroke="#999" stroke-width="1.5"/>\n'
# jelly from above: top face + front face
s += jelly(290, 170, 90, 76, "happy")
s += '<polygon points="294,172 376,172 364,146 306,146" fill="#fff" stroke="#111" stroke-width="2.5"/>\n'

s += '<circle cx="320" cy="205" r="175" fill="none" stroke="#111" stroke-width="2.5" stroke-dasharray="10 6"/>\n'
s += '<path d="M200,110 a150,150 0 0 1 90,-60" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>\n'
s += '<path d="M410,120 l14,-14 M430,150 l20,-4 M400,96 l4,-18" stroke="#fff" stroke-width="2.5"/>\n'
s += label(530, 70, "glass dome", 11, "#fff", "middle", "bold") + label(450, 262, "relief face", 11, "#111", "middle")
s += '<rect x="200" y="300" width="240" height="40" fill="#111"/>\n'
s += label(320, 318, "SAFE!", 14, "#fff", "middle", "bold") + label(320, 334, "press any key to play again", 11, "#fff", "middle")
s += FOOT
files["07-end-dome-closeup-high.svg"] = s

import os
out = os.path.join("design", "storyboard")
os.makedirs(out, exist_ok=True)
for n, c in files.items():
    with open(os.path.join(out, n), "w", encoding="utf-8") as fh:
        fh.write(c)
    print("wrote", os.path.join(out, n))
