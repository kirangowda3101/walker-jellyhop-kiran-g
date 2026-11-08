"""Writes beat_sheet.json, gamedev-evidence.json and SCRIPT.md for the Jelly Hop A6 film.

    python3 tools/make_reel.py        (after make_clips.py and make_images.py)

Same pipeline as the A5 film (youtube/claude-liam-jelly-hop-a5/tools/make_reel.py). Code on screen is read from the
read-only snapshot of revision 8004dea by line range (never retyped). Images are embedded as data URIs. The two footage
beats (B11, B18) are the film's own scripted capture (capture/, media/clips.json). Every claim is sourced in
FACTCHECK.md. Written by Claude Code on 2026-11-08 for Kiran's review.
"""
import base64
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

REEL = Path(__file__).resolve().parent.parent
GAME = REEL.parent / 'snapshot-8004dea' / 'godot'
TITLE = 'Jelly Hop: Particle Effects'   # Claude Code's choice; for Kiran's review
SLUG = 'claude-liam-jelly-hop-a6'
TOPIC = 'JELLY HOP · PARTICLE EFFECTS'
REV = '8004dea'
REV_FULL = '8004deac38c5b4ad260f24433e0537b3e94d16e2'
WPS = 2.7
REC = 'Godot editor reconstruction, not a screenshot'

EX = {'B06': ('effects/land_puff.tscn', 61, 73),
      'B08': ('effects/land_puff.tscn', 15, 20),
      'B10': ('effects/effects_driver.gd', 21, 26),
      'B13': ('effects/dome_glints.tscn', 32, 40),
      'B15': ('effects/dome_glints.tscn', 25, 30),
      'B17': ('effects/effects_driver.gd', 27, 34)}


def sha_file(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def lines(rel, a, b):
    return '\n'.join((GAME / rel).read_text().splitlines()[a - 1:b])


def data_uri(rel):
    im = Image.open(REEL / rel).convert('RGB')
    buf = io.BytesIO()
    im.save(buf, 'JPEG', quality=92)
    return 'data:image/jpeg;base64,' + base64.b64encode(buf.getvalue()).decode()


def est(text, lead=0.0, floor=0.0):
    return round(max(floor, lead + len(text.split()) / WPS + 0.6), 1)


def figure(bid, act, n, title, status, image, image_label, source, cards, phrases, evidence=False):
    shot = {'type': 'REMOTION', 'lane': 'body',
            'show': [{'at': p, 'event': f"card '{c['label']}' lights"} for p, c in zip(phrases, cards)],
            'remotion': {'pattern': 'GodotDesignFigure', 'props': {
                'title': title, 'status': status, 'image': data_uri(image), 'imageLabel': image_label,
                'source': source, 'cards': cards, 'cues': [{'at': 0.0, 'card': i} for i in range(len(cards))]}}}
    if evidence:
        shot['evidence_media'] = image
    return {'beat_id': bid, 'act': act, 'narration_text': n, 'estimated_duration_s': est(n), 'shot': shot,
            'cue_phrases': phrases}


def code(bid, act, n, title, notes, cues, phrases, size=26, author=''):
    rel, a, z = EX[bid]
    return {'beat_id': bid, 'act': act, 'narration_text': n, 'estimated_duration_s': est(n),
            'shot': {'type': 'REMOTION', 'lane': 'body',
                     'show': [{'at': p, 'event': f'line {c[0]} highlighted'} for p, c in zip(phrases, cues)],
                     'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                         'mode': 'code', 'title': title, 'project': 'Jelly Hop', 'path': f'res://{rel}',
                         'source': f'godot/{rel} lines {a}–{z} · rev {REV} · {REC}',
                         'code': lines(rel, a, z), 'startLine': a, 'codeFontSize': size,
                         'inspectorLabel': 'Source notes — not Inspector values',
                         'notes': [{'label': k, 'value': v} for k, v in notes],
                         'cues': [{'at': 0.0, 'line': l, 'label': t} for l, t in cues],
                         'output': [f'{rel} lines {a}–{z} · rev {REV}' + (f' · {author}' if author else '')]}}},
            'cue_phrases': phrases}


def trace(bid, act, n, title, source, tree_label, tree, notes, cues, phrases, output):
    return {'beat_id': bid, 'act': act, 'narration_text': n, 'estimated_duration_s': est(n),
            'shot': {'type': 'REMOTION', 'lane': 'body',
                     'show': [{'at': p, 'event': f'row {c[0]} highlighted'} for p, c in zip(phrases, cues)],
                     'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                         'mode': 'trace', 'title': title, 'project': 'Jelly Hop', 'source': source,
                         'treeLabel': tree_label, 'tree': tree, 'inspectorLabel': 'Sources',
                         'notes': [{'label': k, 'value': v} for k, v in notes],
                         'cues': [{'at': 0.0, 'line': l, 'label': t} for l, t in cues], 'output': output}}},
            'cue_phrases': phrases}


def footage(bid, act, n, clips, labels, show):
    c = clips['clips'][bid]
    return {'beat_id': bid, 'act': act, 'narration_text': n, 'estimated_duration_s': c['duration_s'], 'capture': 'run-a6',
            'qc': {'full_bleed': True,
                   'full_bleed_reason': 'Godot engine capture (scripted keyboard input, Movie Maker, windowed, native 3840x2160). '
                                        'Some excerpts are a 1920x1080 region of the 4K frame enlarged 2x, labelled on every frame. '
                                        'The game draws its wall, table and curtain edge to edge, so content crossing the '
                                        'title-safe inset is the game filling the screen, not a card overflowing. The burned-in '
                                        'labels sit inside the title-safe inset.',
                   'contrast_regions': c['label_regions'],
                   'contrast_reason': 'Whole-frame contrast is low because the game is a dim dinner table by design. The essential '
                                      'text is the three burned-in label lines; each line\'s region (its box in every frame) is tested instead.'},
            'shot': {'type': 'VIDEO', 'lane': 'capture', 'source': 'own', 'treatment': 'none',
                     'evidence_media': c['path'], 'labels': labels, 'show': show}}


def beats():
    clips = json.loads((REEL / 'media/clips.json').read_text())
    b = []
    command = ('Please use Walker to convert my game design document about Jelly Hop, a jelly cube hopping across a '
               'dinner table while forks stab down from above, into two particle effects: a crumb puff at the jelly\'s '
               'feet on every landing, and sugar glints rising from the dessert dome until the run is won.')
    n = ("Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: two particle effects for Jelly Hop, a crumb "
         "puff on every landing and sugar glints over the goal. This prompt is an illustrative reconstruction. Kiran's "
         "real work comes next.")
    b.append({'beat_id': 'B00', 'act': 'cold open — the Walker ask', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'ask', 'show': [
                  {'at': '0.0', 'event': "composer, spark and greeting 'Hej, Liam'"},
                  {'at': '0.2', 'event': 'the Walker prompt (worded from CHANGE-BRIEF.md, A6) types itself'},
                  {'at': '0.75', 'event': 'three output lines; the first labels the prompt a reconstruction'}],
                  'remotion': {'pattern': 'ClaudeComposerAsk', 'props': {
                      'greeting': 'Hej, Liam', 'topic': TOPIC, 'segment': TITLE,
                      'command': command, 'runningText': 'reading CHANGE-BRIEF.md…',
                      'output': ['Illustrative reconstruction of the ask, worded from CHANGE-BRIEF.md (A6). Not a saved transcript.',
                                 'Built: LandPuff · DomeGlints · effects_driver.gd · config and state tests',
                                 f'Shown at revision {REV} · Godot 4.7.2 · Compatibility renderer'],
                      'folderLabel': '@NikBearBrown'}}}})

    n = ("A landing throws a crumb puff. The dome glints until you win. And a headless run times the CPU only, so it "
         "cannot price either effect's GPU work. Here is how both were built, tuned and tested.")
    b.append({'beat_id': 'B01', 'act': 'what was built (hesitant writer)', 'narration_text': n, 'lead_silence_s': 0.8,
              'qc': {'sparse_by_design': True, 'sparse_reason': 'BrutalistHesitantWriter types the three-line overview token by token, '
                     'so mid-beat frames are mostly cream by design; the frame is only full once the third line and its '
                     'correction are typed.'},
              'estimated_duration_s': est(n, 0.8, 9.0),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.1', 'event': "'A landing throws a crumb puff.' types out"},
                  {'at': '0.35', 'event': "'The dome glints until you win.' types out"},
                  {'at': '0.6', 'event': "'A headless run times the GPU.' — 'GPU' turns terracotta"},
                  {'at': '0.8', 'event': "the writer corrects it: 'A headless run times the CPU only.'"}],
                  'remotion': {'pattern': 'BrutalistHesitantWriter', 'props': {
                      'text': 'A landing throws a crumb puff.\nThe dome glints until you win.\nA headless run times the GPU.',
                      'triggerWords': 'GPU', 'replacementWords': 'CPU only',
                      'face': 'serif', 'fontSize': 100, 'lineSpacing': 1.25, 'align': 'center',
                      'seed': 'jelly-hop-a6-2026', 'mistakeRate': 0, 'hesitateWithin': 0,
                      'hesitateBetween': 3, 'charMs': 26, 'jitter': 15}}}})

    n = ("Jelly Hop is Kiran's game: a jelly cube hops across plates on a dinner table while forks stab down from above. "
         "Effect A is the landing crumb puff. Its event is player dot just landed, read while the state is PLAYING: the "
         "same tick that plays the landing sound. Effect B is the dome's sugar glints. Its job is ambience, and its "
         "condition is simply that the state is not WON.")
    b.append(figure('B02', 'the game and both effects', n, 'Jelly Hop: Two Particle Effects',
                    "Held frames from the film's scripted capture · real engine frames, cropped",
                    'images/B02-identify.png', 'Left: tick 317, just after a landing · right: tick 1, the intro',
                    'CHANGE-BRIEF.md, Effects A and B · godot/game/session.gd line 372 · capture/run-a6-inputs.jsonl',
                    [{'label': 'Game', 'text': 'Jelly Hop'}, {'label': 'Effect A', 'text': 'just_landed while PLAYING'},
                     {'label': 'Effect B', 'text': 'ambience, state ≠ WON'}, {'label': 'Both', 'text': 'GPUParticles2D'}],
                    ["Jelly Hop is", "Effect A is", "Effect B is", "condition is"]))

    n = ("Every particle system has three parts. Emission decides when, and how many, are born: line sixty-nine of the "
         "land puff scene sets explosiveness to one, so all sixteen crumbs are born on the landing frame. Process moves "
         "each particle, every frame: line three forty-three of the generated process shader starts the force with "
         "gravity. Draw decides what each one looks like: line sixty-five gives every crumb its gradient texture.")
    b.append(figure('B03', 'emission, process, draw', n, 'Three Parts, One Line Each',
                    'Lines read from the committed files · typeset, not a screenshot', 'images/B03-three-parts.png',
                    'land_puff.tscn 69 and 65 · particles_generated.gdshader 343',
                    'godot/effects/land_puff.tscn lines 64, 65, 69 · godot/shaders/particles_generated.gdshader line 343',
                    [{'label': 'Emission', 'text': 'line 69 · explosiveness'}, {'label': 'Process', 'text': 'line 343 · gravity'},
                     {'label': 'Draw', 'text': 'line 65 · texture'}],
                    ['Emission decides', 'Process moves', 'Draw decides']))

    n = ("That split predicts the price. On a GPU particles node, the process step is a particles shader that runs on the "
         "GPU, and a headless run measures CPU time only, so a low headless CPU cost is expected. What Kiran measured: "
         "none of the three effect cases could be distinguished from the effects-off baseline within the observed spread. "
         "That is not a measured zero. And the run did not establish what ran on the GPU: its log reports open G L three, "
         "and the dummy-renderer statement is still unconfirmed.")
    b.append(figure('B04', 'why a low headless CPU cost is expected, and what was measured', n,
                    'The Headless Price: Expected, Then Measured',
                    "Kiran's run · logs/cost_effects_60fps_mine_20261108-001211.log", 'images/B04-headless-price.png',
                    'TEST-REPORT.md A6, "Price — headless CPU"',
                    'logs/cost_effects_60fps_mine_20261108-001211.log · TEST-REPORT.md A6 · CLAUDE.md, Unconfirmed',
                    [{'label': 'Process', 'text': 'a particles shader'}, {'label': 'Headless', 'text': 'CPU time only'},
                     {'label': 'Measured', 'text': 'within the spread'}, {'label': 'GPU', 'text': 'not established'}],
                    ['process step', 'measures CPU time', 'What Kiran measured', 'did not establish']))

    # ---------------- Effect A
    n = ("Kiran wrote Effect A's intent before any scene existed. Three phases, counted in thirty-frames-per-second frames "
         "from the landing: impact by frame two, a fast sideways kick to about one jelly width by frame five, and a settle "
         "that is gone by frame twelve. Each crumb has a light cream core and a dark brown rim, so it reads on the pale "
         "plate and on the dark table. Six to twelve pixels, drawn behind the jelly.")
    b.append(figure('B05', 'Effect A: the intent block', n, 'Effect A: The Intent, Written First',
                    'Quoted from CHANGE-BRIEF.md · typeset, not a screenshot', 'images/B05-intent-a.png',
                    'Version 1, 2026-11-07, before any Claude Code session for A6', 'CHANGE-BRIEF.md, Effect A, "The intent block"',
                    [{'label': 'Phases', 'text': 'impact · kick · settle'}, {'label': 'Contrast', 'text': 'cream core, dark rim'},
                     {'label': 'Scale', 'text': '6–12 px crumbs'}, {'label': 'Layer', 'text': 'z_index −1'}],
                    ['Three phases', 'light cream core', 'Six to twelve', 'drawn behind']))

    n = ("The emitter node, written by Claude Code from the brief's table. Amount sixteen. One shot true: one burst, then "
         "done. Explosiveness one: all sixteen at once. Emitting is false in the file; the driver turns it on at the "
         "landing. And line sixty-five is the draw side: the crumb texture, a gradient defined inside this same file.")
    b.append(code('B06', 'code: the LandPuff emitter node', n, 'Effect A: The Emitter Node',
                  [('Written by', 'Claude Code (session 2), from the brief\'s table'),
                   ('Draw', 'no material: default mix blend · z_index −1')],
                  [(64, 'amount = 16'), (67, 'one_shot: one burst'), (69, 'explosiveness 1.0: all at once'),
                   (63, 'off until the driver sets it'), (65, 'draw: the gradient texture')],
                  ['Amount sixteen', 'One shot true', 'Explosiveness one', 'Emitting is false', 'line sixty-five'], size=24))

    n = ("The result, as a fixture: Kiran's preview scene with two still jellies, captured by Movie Maker as strip r zero. "
         "Kiran's verdict, given before Claude read anything: at frame twelve the puff was easy to see on both the plate and "
         "the table. But at frame fifteen most crumbs were still under the jellies, with no wide sideways fan. By frame "
         "twenty, gone.")
    b.append(figure('B07', 'result: strip r0 and Kiran\'s verdict', n, 'Effect A, Strip r0: Kiran\'s Verdict',
                    'Fixture capture · preview scene, not gameplay · Movie Maker, 30 fps', 'images/B07-strip-a-r0.png',
                    'captures/land_puff/r0/ · TUNING.md, Effect A, r0', 'captures/land_puff/r0/frame000000{10,12,15,20}.png · TUNING.md',
                    [{'label': 'Fixture', 'text': 'two still jellies'}, {'label': 'Frame 12', 'text': 'easy to see'},
                     {'label': 'Frame 15', 'text': 'still under them'}, {'label': 'Frame 20', 'text': 'gone'}],
                    ['as a fixture', 'frame twelve', 'frame fifteen', 'By frame'], evidence=True))

    n = ("Revision r one changes one setting: the radial acceleration curve, the sideways push. In r zero the push faded "
         "from the very start. Now line sixteen holds it at full strength until eighteen percent of life, then drops it to "
         "zero by twenty. Claude first proposed doubling the push range; Kiran chose this curve-only alternative instead.")
    b.append(code('B08', 'code: the Revision 1 radial curve', n, 'Effect A, r1: The Radial Curve',
                  [('Version 1 (r0)', '(0, 1) → (0.2, 0): fading from the start'),
                   ('Unchanged', 'radial_accel_min / max 4000 / 6500 (lines 48–49)'),
                   ('Edit', 'Claude Code (session 4c), approved by Kiran')],
                  [(16, '(0,1) (0.18,1) (0.2,0)'), (19, 'wrapped as a CurveTexture'), (16, 'Kiran chose the curve only')],
                  ['radial acceleration curve', 'Now line sixteen', 'Kiran chose'], size=24))

    n = ("Claude predicted that frame twelve would still be mostly behind the jelly, and that frame fifteen would reach at "
         "most about forty pixels. The strips disagreed: at frame twelve crumbs were already five to fifteen pixels past "
         "both edges, and at fifteen up to forty-nine. Claude traced the miss to a one-frame offset in its own model. "
         "Kiran's verdict in the running game: kept, because the puff was easy to see on landing.")
    b.append(figure('B09', 'result: r1 prediction, strips, comparison, verdict', n, 'Effect A, r1: Predicted, Compared, Kept',
                    'Fixture captures r0 and r1 · Claude\'s prediction and comparison · Kiran\'s verdict', 'images/B09-revision-a-r1.png',
                    'captures/land_puff/r0, r1 · TUNING.md, Effect A, r1',
                    'captures/land_puff/ · TUNING.md · sessions/a6/session-4b-prediction.md, session-4d-comparison.md',
                    [{'label': 'Predicted', 'text': 'frame 12: behind'}, {'label': 'Strip', 'text': '5–15 px out at 12'},
                     {'label': 'Cause', 'text': 'one frame off'}, {'label': 'Kiran', 'text': 'kept'}],
                    ['Claude predicted', 'The strips disagreed', 'one-frame offset', "Kiran's verdict"], evidence=True))

    n = ("Now the trigger. The driver runs after the session every tick, and line twenty-one is the same condition that "
         "plays the landing sound: state PLAYING, and just landed. Each landing gets a new instance, parented to the "
         "session, placed at the jelly's feet, freed when it finishes, and only then set emitting.")
    b.append(code('B10', 'code: the Effect A trigger in effects_driver.gd', n, 'Effect A: The Trigger',
                  [('Written by', 'Claude Code (session 3b) · Kiran moved the finished connection before emitting'),
                   ('Boundary', 'reads state, just_landed, global_position; never writes them')],
                  [(21, 'same condition as SFX-LAND'), (22, 'a new instance each landing'), (23, 'parent: the session'),
                   (24, "at the jelly's feet"), (25, 'finished → queue_free'), (26, 'then emitting')],
                  ['line twenty-one', 'new instance', 'parented', "jelly's feet", 'freed when', 'set emitting'], size=26))

    n = ("Scripted capture, not a playtest. One hop, one puff at the feet. Then the quick repeat: a running hop to the "
         "plate's edge, a scoot off, and a drop to the table nine ticks later. Two puff nodes were alive at once; whether "
         "their crumbs visibly overlap is still unverified.")
    b.append(footage('B11', 'result: Effect A in play (scripted capture)', n, clips,
                     ['Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · rev 8004dea · not a human playtest',
                      'excerpt N of 3 · description · crop note', 'from the capture log · tick · state · SFX-LAND count · LandPuff nodes in the tree'],
                     [{'at': '0.0s', 'event': 'excerpt 1: plate 1; the solo hop lands at tick 313 (puff at the feet)'},
                      {'at': '1.4s', 'event': 'back up, run, hop: landing at plate 1\'s edge (tick 449), table landing (tick 458), 2 nodes'},
                      {'at': '4.5s', 'event': 'excerpt 2: labelled 1/4-speed replay of ticks 440–490'},
                      {'at': '7.8s', 'event': 'excerpt 3: the route over plates 1–5, a puff at every landing'}]))

    # ---------------- Effect B
    n = ("Effect B's intent. Ambience: about twenty-four glints at a time, each drifting upward over two point four "
         "seconds, sugar white turning pale gold. Full from the very first frame, with no fill-in. At the win, no new "
         "glints; the live ones rise and fade. And the feature Effect A does not use: a box emission shape across the "
         "dome's glass, with an additive draw material.")
    b.append(figure('B12', 'Effect B: the intent block', n, 'Effect B: The Intent, Written First',
                    'Quoted from CHANGE-BRIEF.md · typeset, not a screenshot', 'images/B12-intent-b.png',
                    'Version 1, 2026-11-07', 'CHANGE-BRIEF.md, Effect B, "The job", "The intent block"',
                    [{'label': 'Job', 'text': 'ambience'}, {'label': 'Start', 'text': 'full on frame one'},
                     {'label': 'Stop', 'text': 'no new glints at WON'}, {'label': 'Not in A', 'text': 'box · additive'}],
                    ["Effect B's intent", 'very first frame', 'At the win', 'feature Effect A']))

    n = ("Here is the box. Line thirty-four sets the emission shape to three, a box, and line thirty-five makes it seventy "
         "by forty-five pixels each way from the centre, so a glint can be born anywhere across the glass. A slight "
         "negative gravity drifts them upward. The draw side is additive: line sixteen's canvas item material uses blend "
         "mode add, so glints brighten whatever is behind them.")
    b.append(code('B13', 'code: box emission and the additive material', n, 'Effect B: A Box, Drawn Additively',
                  [('Line 16', 'blend_mode = 1 (BLEND_MODE_ADD), set as the node\'s material on line 53'),
                   ('Line 59', 'preprocess = 2.4: one full lifetime before the first frame'),
                   ('Written by', 'Claude Code (session 5), from the brief\'s table')],
                  [(34, 'emission_shape 3: a box'), (35, '±70 × ±45 px'), (40, 'gravity −6: drift up'),
                   (34, 'additive draw: line 16')],
                  ['Line thirty-four', 'line thirty-five', 'negative gravity', 'additive'], size=26))

    n = ("The fixture strip, r zero: the dome preview restarts the glints at frame ten and stops emission at seventy. "
         "Kiran's verdict: glints already visible at frame ten, more of them there than at frame forty, no thinning noticed "
         "by frame eighty-five, and none left at one forty-five. Claude, reading the same frames, found the brief's slow "
         "fade-in at odds with its own frame-eighty-five target.")
    b.append(figure('B14', 'result: strip r0 and Kiran\'s verdict', n, 'Effect B, Strip r0: Kiran\'s Verdict',
                    'Fixture capture · preview scene, not gameplay · Movie Maker, 30 fps', 'images/B14-strip-b-r0.png',
                    'captures/dome_glints/r0/ · TUNING.md, Effect B, r0',
                    'captures/dome_glints/r0/ · TUNING.md · sessions/a6/session-7a-reading.md',
                    [{'label': 'Frame 10', 'text': 'already visible'}, {'label': 'Frame 40', 'text': 'fewer than at 10'},
                     {'label': 'Frame 85', 'text': 'no thinning seen'}, {'label': 'Claude', 'text': 'fade-in vs frame 85'}],
                    ['frame ten', 'frame forty', 'eighty-five', 'Claude, reading'], evidence=True))

    n = ("Revision r one moves one point of the colour ramp. Its second offset goes from point two to point zero eight, "
         "so each glint reaches its peak alpha, point eight five, at eight percent of its life instead of twenty. The "
         "colours and the scale curve are unchanged.")
    b.append(code('B15', 'code: the Revision 2 colour ramp', n, 'Effect B, r1: The Colour Ramp',
                  [('Version 1 (r0)', 'offsets 0, 0.2, 0.75, 1'),
                   ('Edit', 'Claude Code (session 7b), approved by Kiran · CHANGE-BRIEF.md Revision 2')],
                  [(26, 'offsets 0, 0.08, 0.75, 1'), (27, 'peak alpha 0.85, colours unchanged')],
                  ['second offset', 'peak alpha'], size=26))

    n = ("Claude predicted more visible glints: sixteen to eighteen at frame ten. Kiran's byte comparison showed the render "
         "did change. But at full frame size Claude saw no visible difference from r zero, and called its count prediction "
         "its own mistake. Kiran overruled that reading: in the running game the glints were noticeably easier to see in "
         "the intro, so r one was kept. The frame-eighty-five thinning was still not met.")
    b.append(figure('B16', 'result: r1, the reading Kiran overruled', n, 'Effect B, r1: The Reading Kiran Overruled',
                    'Fixture captures r0 and r1 · Claude\'s prediction and comparison · Kiran\'s verdict', 'images/B16-revision-b-r1.png',
                    'captures/dome_glints/r0, r1 · TUNING.md, Effect B, r1',
                    'captures/dome_glints/ · TUNING.md · sessions/a6/session-7a-reading.md, session-7c-comparison.md',
                    [{'label': 'Predicted', 'text': '16–18 at frame 10'}, {'label': 'cmp', 'text': 'the render changed'},
                     {'label': 'Claude', 'text': 'no visible difference'}, {'label': 'Kiran', 'text': 'kept, for the intro'}],
                    ['Claude predicted', 'byte comparison', 'no visible difference', 'Kiran overruled'], evidence=True))

    n = ("The driver acts only when the state enters or leaves WON. Entering it, line thirty-one stops emission; the node "
         "stays, so live glints finish. Leaving it on a replay, line thirty-three calls restart on the same emitter. Its "
         "comment says preprocess applies again; that is still unverified. Pause, Esc and hiding never reach this code.")
    b.append(code('B17', 'code: Effect B start, stop and replay in effects_driver.gd', n, 'Effect B: Stop at WON, Restart on Replay',
                  [('Line 33 comment', '"preprocess applies again": unverified (CLAUDE.md, Unconfirmed)'),
                   ('Written by', 'Claude Code (session 6b)')],
                  [(28, 'won = state is WON'), (31, 'emitting = false; the node stays'), (33, 'restart() on replay'),
                   (33, 'comment: unverified'), (29, 'only on a change')],
                  ['enters or leaves WON', 'line thirty-one', 'line thirty-three', 'still unverified', 'never reach'], size=26))

    n = ("Scripted capture again. The intro opens on a dome that is already glinting. Esc pauses the session, and the "
         "glints keep drifting. At the win, emission stops and they thin out. On replay, the dome is off screen.")
    b.append(footage('B18', 'result: Effect B in play (scripted capture)', n, clips,
                     ['Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · rev 8004dea · not a human playtest',
                      'excerpt N of 3 · description · crop note', 'from the capture log · tick · state · DomeGlints emitting'],
                     [{'at': '0.0s', 'event': 'excerpt 1: intro, tick 1, glints already present (crop 2×)'},
                      {'at': '2.0s', 'event': 'excerpt 2 (full frame): landing on plate 6, dome on screen'},
                      {'at': '3.6s', 'event': 'Esc at tick 1059: PAUSED, the glints keep drifting; Esc again at 1181'},
                      {'at': '6.6s', 'event': 'WON at tick 1233: emitting false; the glints thin out'},
                      {'at': '9.1s', 'event': 'excerpt 3: replay at tick 1384, emitting true (logged), dome off screen'},
                      {'at': '10.2s', 'event': 'labelled held frame of the replay, 2.5 s'}]))

    n = ("Here is where each behaviour was shown. On from load, and the stop on the WON tick: the headless state test, over "
         "two real-key runs, and this capture. The restart on replay: emitting true on the first tick after each replay, "
         "headless; in play, not yet verified. Esc pause: headless, and in Kiran's play. Tree pause and hiding come from "
         "the headless test alone: emitting stays true, and a tree-paused emitter does not process.")
    b.append(figure('B19', 'start, stop and pause: where each was shown', n, 'Effect B: Start, Stop and Pause',
                    'Headless state test (27 / 0) · Kiran in play · the film\'s capture', 'images/B19-start-stop-pause.png',
                    'TEST-REPORT.md A6, "State — Effect B", "In play — Effect B"',
                    'TEST-REPORT.md A6 · logs/test_dome_glints_state_60fps.log · capture/run-a6-inputs.jsonl',
                    [{'label': 'Load · WON', 'text': 'headless + capture'}, {'label': 'Replay', 'text': 'headless only'},
                     {'label': 'Esc', 'text': 'headless + Kiran'}, {'label': 'Tree · hide', 'text': 'headless'}],
                    ['On from load', 'restart on replay', 'Esc pause', 'Tree pause']))

    n = ("Kiran converted the puff's process material into a shader and saved Godot's output unedited; the game does not use "
         "it. Line one forty-five picks each particle's starting speed between the minimum and the maximum, with a seeded "
         "random value: the brief's thirty to sixty. Line two fifty-four scales the radial push by the curve, sampled at "
         "the particle's lifetime percentage: Kiran's revision one curve, held at one until point one eight, zero by point two.")
    b.append(figure('B20', "two lines of Godot's generated process shader", n, 'The Generated Shader Beside the Brief',
                    'Lines read from the files · typeset, not a screenshot', 'images/B20-generated-lines.png',
                    'particles_generated.gdshader 145, 254 · land_puff.tscn 45–46, 16',
                    'godot/shaders/particles_generated.gdshader · godot/effects/land_puff.tscn · TEST-REPORT.md A6, Step 6',
                    [{'label': 'Generated', 'text': 'saved unedited'}, {'label': 'Line 145', 'text': '30 to 60'},
                     {'label': 'Line 254', 'text': 'the r1 curve'}],
                    ['saved Godot', 'one forty-five', 'two fifty-four']))

    # ---------------- tests and prices
    n = ("What the tests proved, each run by Kiran at sixty frames per second. The two config tests read every setting back: "
         "fifty-one checks and forty-five, no failures. The Effect A state test, twenty-four checks: one puff per landing "
         "sound, on the same tick, at the feet to zero point zero pixels. The Effect B state test, twenty-seven: emitting "
         "equals not WON on all sixteen hundred sixty-seven ticks.")
    b.append(figure('B21', 'what the tests proved', n, 'What the Tests Proved',
                    'Logs of runs by Kiran · headless · numbers only, not a render', 'images/B21-tests.png',
                    'logs/test_*_60fps.log · TEST-REPORT.md A6', 'logs/test_land_puff_*, test_dome_glints_* · TEST-REPORT.md A6',
                    [{'label': 'Config', 'text': '51 / 0 · 45 / 0'}, {'label': 'State A', 'text': '24 / 0'},
                     {'label': 'State B', 'text': '27 / 0'}],
                    ['config tests', 'Effect A state', 'Effect B state']))

    n = ("Two mutations, each a one-line edit that Kiran made and then restored. A Godot three name, initial velocity "
         "instead of initial velocity min: Godot printed nothing, the puff still fired in the preview, and the config test "
         "failed, reading zero instead of thirty. Then spread changed to forty-five while the brief still said thirty: "
         "exactly one failure. A firing puff was not proof that its settings had loaded.")
    b.append(figure('B22', 'two mutations that failed the config test', n, 'Two Mutations the Config Test Caught',
                    'Logs of runs by Kiran · each exited 1', 'images/B22-mutations.png',
                    'logs/mutation1_godot3_name_config_60fps.log · mutation2_value_drift_config_60fps.log',
                    'logs/mutation1_*, mutation2_* · TEST-REPORT.md A6 · FRICTIONAL.md A6',
                    [{'label': 'Godot 3 name', 'text': 'read back 0.0'}, {'label': 'Drift', 'text': 'spread 45'},
                     {'label': 'Lesson', 'text': 'firing ≠ loaded'}],
                    ['Godot three name', 'spread changed', 'not proof']))

    n = ("Both prices, against the budgets. Headless CPU: unresolved, every effect inside the run-to-run spread. GPU: the "
         "brief's budget is a quarter of a millisecond per effect. On the shipped Compatibility renderer the Visual Profiler "
         "showed CPU timings, but every GPU reading was zero point zero and the graph was blank. A labelled Forward-plus "
         "comparison did the same. So GPU timing was unavailable, and both budgets are unverified.")
    b.append(figure('B23', 'both prices against the budgets', n, 'The Prices Against the Budgets',
                    "Kiran's Visual Profiler screenshots · Apple M4", 'images/B23-prices.png',
                    'evidence/a6-visual-profiler-*.png · TEST-REPORT.md A6, "Price — GPU"',
                    'evidence/a6-visual-profiler-compat-gpu-zero.png, -forwardplus-proxy-gpu-zero.png · TEST-REPORT.md A6',
                    [{'label': 'CPU', 'text': 'unresolved'}, {'label': 'Budget', 'text': '0.25 ms GPU each'},
                     {'label': 'GPU', 'text': '0.0 ms, blank'}, {'label': 'Verdict', 'text': 'unverified'}],
                    ['Headless CPU', 'quarter of a millisecond', 'zero point zero', 'both budgets']))

    n = ("And what no headless run can show: that a crumb or a glint is drawn at all; the timing phases, the scale, the "
         "contrast and the variation; whether two puffs' crumbs visibly overlap; a pop at the screen edge; or whether "
         "restart refills the dome. Those are checks for eyes on the running game, and several are still open.")
    b.append(trace('B24', 'what no headless run can show', n, 'What No Headless Run Can Show',
                   'TEST-REPORT.md A6, "Not provable headlessly" (both effects)',
                   'Outside any headless test (TEST-REPORT.md A6)',
                   ['crumbs or glints actually drawn',
                    'timing phases · scale · contrast · variation',
                    "two puffs' crumbs visibly overlapping (A4)",
                    'visibility_rect pops at the screen edge',
                    'restart() refilling the dome on replay (B3)'],
                   [('Headless sees', 'node state: properties, emitting, counts, signals'),
                    ('Who checks the rest', "Kiran's eyes in the running game")],
                   [(1, 'drawn at all'), (2, 'the look'), (3, 'overlap: unverified'), (4, 'screen edge'), (5, 'replay refill')],
                   ['drawn at all', 'timing phases', 'visibly overlap', 'screen edge', 'refills the dome'],
                   ['Several of these remain open: see "Still uncertain".']))

    n = ("The agent mistakes Kiran caught. The brief draft said the headless test would show both puffs emitting. The plan "
         "connected finished after emission; Kiran moved it first. The first state-test route ran off plate one. The cost "
         "script briefly allowed a third puff, found by a separate checker. And the shader explanation got its two branches "
         "wrong. One strip reading Kiran overruled: Effect B r one, which Claude saw as no different.")
    b.append(trace('B25', 'agent mistakes Kiran caught, and the reading overruled', n, 'What the Agents Got Wrong',
                   'FRICTIONAL.md A6 · TEST-REPORT.md A6 · TUNING.md',
                   'AI mistake → what Kiran did',
                   ['Brief draft (chat): headless "both puffs emitting" → corrected before commit',
                    'Plan: finished connected after emitting → Kiran moved it first',
                    'State test route ran off plate 1 (23 ticks) → route fixed, check kept',
                    'Cost script allowed a 3rd puff (25 of 300 frames) → slot limit added',
                    'Shader branch explanation (chat) → contradicted by the file',
                    'Overruled: Effect B r1 "no visible difference" → kept for the intro'],
                   [('Also', 'engine-monitor columns identical for empty and full cases → left out of the price'),
                    ('Who', 'chat = Claude in claude.ai; others = Claude Code')],
                   [(1, 'the brief draft'), (2, 'signal order'), (3, 'the route'), (4, 'a third puff'), (5, 'the branches'),
                    (6, 'overruled')],
                   ['brief draft', 'connected finished', 'ran off plate', 'third puff', 'two branches', 'Kiran overruled'],
                   ['Every correction is Kiran\'s; sources in FRICTIONAL.md A6.']))

    n = ("Still uncertain, from Kiran's own lists. Whether restart re-applies preprocess, and whether the dome is full right "
         "after a replay. Whether two puffs' crumbs visibly overlap, and the real gameplay peak. The frame-eighty-five "
         "thinning. Whether headless uses a dummy renderer, and whether the ring collapses at spawn. And usable GPU timing "
         "on either renderer.")
    b.append(trace('B26', 'what remains uncertain', n, 'Still Uncertain',
                   'CLAUDE.md, Unconfirmed · FRICTIONAL.md A6, "Still unresolved"',
                   'Unresolved (Kiran\'s lists)',
                   ['restart() re-applying preprocess · the dome right after a replay',
                    "two puffs' crumbs visibly overlapping · the real gameplay peak",
                    'the frame-85 thinning (not seen in r0 or r1)',
                    'dummy renderer headless? · ring collapsing at spawn? · equal z_index',
                    'GPU timing on either renderer · the CPU bounds'],
                   [('Also open', 'a table landing beside the sauce · the 2D collision/SDF claim · two check runners'),
                    ('Source', 'CLAUDE.md Unconfirmed; FRICTIONAL.md A6')],
                   [(1, 'replay'), (2, 'overlap'), (3, 'thinning'), (4, 'rendering'), (5, 'timing')],
                   ['restart re-applies', 'visibly overlap', 'eighty-five', 'dummy renderer', 'GPU timing'],
                   ['None of these is claimed as solved in this film.']))

    nxt = ("I'd check whether the dome glints are already full immediately after an in-game replay. The preview showed full "
           "glints by frame 10, but I haven't checked that in live play.")
    n = ("Verdict. Both effects fire where the brief says: one puff per landing sound, glints off exactly while WON, with "
         "fifty-one, forty-five, twenty-four and twenty-seven checks and no failures. The prices are unresolved: CPU inside "
         "the spread, GPU timing unavailable, both budgets unverified. Kiran wrote the brief and both revisions, made every "
         "verdict, ran every test, mutation and profiler run, and started all four strip captures. Claude Code built the effect scenes, the driver, "
         "the tests and the cost script, and made this film; Claude in chat drafted the brief's wording and wrote the peak "
         "checker. The textures are two gradient textures defined in the scene files: no third-party textures. Kiran's next "
         f"step, in Kiran's words: {nxt} Shown at revision eight zero zero four D E A.")
    b.append({'beat_id': 'BVDT', 'act': 'verdict', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.05', 'event': f"artifact page 'Jelly Hop — particle effects at {REV}'"},
                  {'at': '0.1', 'event': 'lines land as the voice names them'}],
                  'remotion': {'pattern': 'ClaudeVerdictArtifact', 'props': {
                      'artifactTitle': 'Verdict', 'artifactHeading': f'Jelly Hop — particle effects at {REV}',
                      'brandLabel': '@NikBearBrown',
                      'artifactLines': [
                          'WORKS — puff = SFX-LAND every tick · glints off while WON · 51/0 · 45/0 · 24/0 · 27/0',
                          'UNRESOLVED — headless CPU within spread · GPU timing unavailable · 0.25 ms budgets unverified',
                          'KIRAN — brief, both revisions, every verdict, every test and mutation, the 4 strips, profiler runs',
                          'CLAUDE CODE — scenes, driver, tests, cost script, this film · CHAT — brief wording, peak checker',
                          'TEXTURES — two GradientTexture2D defined in the scene files · no third-party textures',
                          'NEXT (Kiran) — check whether the dome glints are full right after an in-game replay',
                          f'SOURCE — revision {REV} · Godot 4.7.2 · Compatibility renderer']}}}})

    prompt = ("Use Walker: before tuning a particle effect, write what frames 2, 5 and 12 should show, capture a fixed-seed "
              "strip, predict exactly what one setting change will move, capture again, and tell me which frame proved "
              "my prediction wrong.")
    n = (f"Your turn. {prompt} Writing frames first is what let Kiran see crumbs stuck under the jelly at frame fifteen, "
         "and what showed that Claude's own prediction was one frame off. Run it on your own effect, and watch which "
         "frame surprises you. Liam, in for Bear.")
    b.append({'beat_id': 'BHTF', 'act': 'your turn handoff', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'ask', 'show': [
                  {'at': '0.0', 'event': "composer returns, greeting 'Your turn.'"},
                  {'at': '0.1', 'event': 'the prompt types itself as the voice reads it'}],
                  'remotion': {'pattern': 'ClaudeComposerAsk', 'props': {
                      'greeting': 'Your turn.', 'topic': TOPIC, 'segment': TITLE,
                      'command': prompt, 'runningText': 'paste this into Claude…', 'folderLabel': '@NikBearBrown'}}}})

    n = f'{TITLE}. At Nik Bear Brown.'
    b.append({'beat_id': 'BOUT', 'act': 'outro', 'kind': 'outro_voice', 'narration_text': n, 'estimated_duration_s': 4.0,
              'tail_hold_s': 1.0,
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [{'at': '0.0', 'event': f"title card '{TITLE}'"}],
                       'remotion': {'pattern': 'ClaudeTitleOutro', 'props': {'title': TITLE, 'slug': SLUG}}}})
    for x in b:
        x.setdefault('voice', 'am_onyx')
        x.setdefault('engine', 'kokoro')
    return b


EXCL = ('File from Assignments 2–5, not changed by A6 (git diff a5..8004dea -- godot) and outside this A6 film\'s scope; '
        'explained in the earlier films.')
COMPONENTS = [
    ('a6-land-puff', 'Effect A: the LandPuff GPUParticles2D scene (emission, process material, gradient texture) and its '
     'preview fixture used for the r0 and r1 strips.',
     ['B02', 'B03', 'B05', 'B06', 'B07', 'B08', 'B09', 'B11'],
     ['effects/land_puff.tscn', 'previews/land_puff_preview.tscn', 'previews/land_puff_preview.gd']),
    ('a6-dome-glints', 'Effect B: the DomeGlints GPUParticles2D scene (box emission, preprocess, additive CanvasItemMaterial) '
     'and its preview fixture.',
     ['B02', 'B12', 'B13', 'B14', 'B15', 'B16', 'B18', 'B19'],
     ['effects/dome_glints.tscn', 'previews/dome_glints_preview.tscn', 'previews/dome_glints_preview.gd']),
    ('a6-driver', 'The presentation-only effects driver (a puff per landing on the SFX-LAND condition; glints off at WON, '
     'restart on replay) and the one session.gd line (63) that adds it.',
     ['B10', 'B11', 'B17', 'B18'], ['effects/effects_driver.gd', 'game/session.gd']),
    ('a6-process-shader', "Godot's Convert to ShaderMaterial output for LandPuff's process material, saved unedited, not used "
     'by the game.', ['B03', 'B04', 'B20'], ['shaders/particles_generated.gdshader']),
    ('a6-tests', 'The two config tests, the two state tests, and the read-only route planner the Effect B state test and the '
     "film's capture reuse.", ['B19', 'B21', 'B22'],
     ['tests/test_land_puff_config.gd', 'tests/test_dome_glints_config.gd', 'tests/test_land_puff_state.gd',
      'tests/test_dome_glints_state.gd', 'tests/route_driver.gd']),
    ('a6-price', "The headless cost script, the separate lifecycle peak checker, and project.godot (the Compatibility renderer).",
     ['B04', 'B23'], ['tests/cost_effects.gd', 'tests/check_lifecycle_peak.gd', 'project.godot']),
]


def ledger(sheet):
    inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob('*')
                       if p.is_file() and not any(x in ('.godot', '.git') for x in p.relative_to(GAME).parts)
                       and p.suffix != '.uid')
    comp_files = {cid: set(files) for cid, _, _, files in COMPONENTS}
    records, excl = [], []
    for f in inventory:
        cids = [cid for cid in comp_files if f in comp_files[cid]]
        if not cids:
            excl.append({'path': f, 'reason': EXCL})
            continue
        role = 'scene' if f.endswith('.tscn') else ('config' if f.endswith('.godot') else 'source')
        records.append({'path': f, 'sha256': sha_file(GAME / f), 'role': role, 'component_ids': cids})
    for cid, files in comp_files.items():
        for f in files:
            if f not in inventory:
                raise SystemExit(f'STOPPED: {f} ({cid}) is not in godot/')
    beats = {x['beat_id']: x for x in sheet['beats']}
    excerpts = [{'beat_id': bid, 'path': rel, 'start_line': a, 'end_line': z, 'text': lines(rel, a, z)}
                for bid, (rel, a, z) in EX.items()]
    obs = {'B07': "Strip r0 (fixture): at frame 12 the crumbs show on plate and table; at frame 15 most are still under the "
                  "jellies with no wide fan; frames 20, 30 and 50 are empty (Kiran's r0 verdict, TUNING.md).",
           'B09': 'Strip r1 against r0 (fixture): at frame 12 crumbs are about 5–15 px past both jelly edges and at frame 15 up '
                  "to 36–49 px, beyond Claude's predicted 40 px (TUNING.md, session-4d-comparison.md).",
           'B11': 'In the scripted capture, a puff appears at the jelly\'s feet on each landing tick (313, 449, 458, 558, 698, '
                  '774, 883, 950, 1027); the scoot-off landings are 9 ticks apart and the log shows 2 LandPuff nodes in the tree '
                  'at tick 458. Visible overlap of crumbs is not claimed.',
           'B14': "Strip r0 (fixture): glints present at frame 10, fewer at 40, no clear thinning 70→85, none at 145 "
                  "(Kiran's r0 verdict, TUNING.md).",
           'B16': 'Strips r0 and r1 (fixture) at frames 10, 40 and 85: bytes differ (Kiran\'s cmp) but no visible difference at '
                  "full size in Claude's reading; Kiran kept r1 for the in-game intro (TUNING.md).",
           'B18': 'In the scripted capture glints are on screen at tick 1; during PAUSED (ticks 1059–1180) they keep drifting; '
                  'DomeGlints.emitting is false from the WON tick 1233 and the glints thin out; at the replay tick 1384 the log '
                  'shows emitting true with the dome off screen.'}
    pairs = []
    for code_b, result_b in (('B06', 'B07'), ('B08', 'B09'), ('B10', 'B11'), ('B13', 'B14'), ('B15', 'B16'), ('B17', 'B18')):
        media = beats[result_b]['shot']['evidence_media']
        pairs.append({'code_beat': code_b, 'result_beat': result_b, 'observation': obs[result_b],
                      'media': {'path': media, 'sha256': sha_file(REEL / media)}})
    return {'schema_version': 1, 'teaching_contract': 'code-then-result-v1', 'game_revision': REV,
            'files': records, 'exclusions': excl,
            'components': [{'id': cid, 'explanation': ex, 'beat_ids': bids, 'files': sorted(comp_files[cid])}
                           for cid, ex, bids, _ in COMPONENTS],
            'excerpts': excerpts, 'code_result_pairs': pairs}


def script_md(sheet):
    out = [f'# SCRIPT — {TITLE}', '',
           'Drafted by Claude Code on 2026-11-08, for Kiran\'s review. Narration is what Liam says; "On screen" is what the '
           'viewer sees. Every claim is sourced in FACTCHECK.md.', '']
    total = 0.0
    for x in sheet['beats']:
        d = x.get('actual_duration_s') or x.get('estimated_duration_s') or 0
        total += d
        out.append(f"## {x['beat_id']} — {x['act']}  (~{d:.0f} s)")
        rem = x['shot'].get('remotion', {})
        out.append(f"On screen: {rem.get('pattern', x['shot']['type'])}; " + '; '.join(e['event'] for e in x['shot'].get('show', [])))
        out.append('')
        out.append('> ' + x['narration_text'])
        out.append('')
    if all(x.get('actual_duration_s') for x in sheet['beats']):
        out.append(f'**Total: {total:.3f} s ({int(total // 60)} min {total % 60:.1f} s), measured: the sum of the beat durations '
                   f'tools/make_master.py set from the Kokoro narration and the two clip lengths.**')
    else:
        out.append(f'**Estimated total: {total / 60:.1f} min** ({total:.0f} s; an estimate until Kokoro and make_master.py run).')
    return '\n'.join(out) + '\n'


def main():
    sheet = {'metadata': {
        'title': TITLE, 'slug': SLUG, 'topic': TOPIC, 'register': 'Teardown',
        'audience': 'Claude', 'brand': 'claude-liam', 'persona': 'Liam (in for Bear)', 'voice': 'am_onyx',
        'engine': 'kokoro', 'voice_kokoro': 'am_onyx', 'palette': 'claude', 'style_preset': 'claude',
        'ground': '#FAF9F5', 'greeting': 'Hej, Liam', 'folderLabel': '@NikBearBrown', 'in_for_bear': True,
        'aspect_ratio': '16:9', 'fps': 30, 'fit': 'crop', 'skill': 'godot-gamedev', 'modifier': 'walker',
        'game': 'walker-jellyhop-kiran-g', 'game_revision': REV_FULL,
        'capture_method': ('one scripted-input take (capture/, Godot Movie Maker, windowed, offline 4K) from a disposable '
                           f'git-archive copy of {REV}; plus Kiran\'s committed fixture strips, screenshots and logs'),
        'approvals': {}},
        'beats': beats()}
    (REEL / 'beat_sheet.json').write_text(json.dumps(sheet, indent=1, ensure_ascii=False) + '\n')
    ev = ledger(sheet)
    (REEL / 'gamedev-evidence.json').write_text(json.dumps(ev, indent=1, ensure_ascii=False) + '\n')
    (REEL / 'SCRIPT.md').write_text(script_md(sheet))
    print(f"beats {len(sheet['beats'])} · files {len(ev['files'])} · exclusions {len(ev['exclusions'])} · "
          f"components {len(ev['components'])} · excerpts {len(ev['excerpts'])} · "
          f"est {sum(x['estimated_duration_s'] for x in sheet['beats']):.0f} s")


if __name__ == '__main__':
    main()
