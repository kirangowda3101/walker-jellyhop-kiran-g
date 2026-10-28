"""Writes beat_sheet.json, gamedev-evidence.json and SCRIPT.md for the Jelly Hop A5 film.

    python3 tools/make_reel.py        (after make_clips.py and make_images.py)

Same pipeline as the A3 film (youtube/claude-liam-jelly-hop-a3/tools/make_reel.py). Code on screen is read from
the repository's files by line range (never retyped). Images are embedded as data URIs. The one footage beat (B07)
is the film's own scripted capture (capture/, media/clips.json). Every claim is sourced in FACTCHECK.md.
Written by Claude Code on 2026-10-28 for Kiran's review.
"""
import base64
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

REEL = Path(__file__).resolve().parent.parent
GAME = REEL.parent.parent / 'godot'
TITLE = 'Jelly Hop: Shaders and Materials'   # Claude Code's choice; for Kiran's review
SLUG = 'claude-liam-jelly-hop-a5'
TOPIC = 'JELLY HOP · SHADERS & MATERIALS'
REV = '77a6d10'
REV_FULL = '77a6d10fd6b9548355a194454f3e1d65148d0758'
WPS = 2.7

EX = {'B04': ('shaders/fork_warning.gdshader', 1, 10),
      'B06': ('features/fork/fork.gd', 221, 231),
      'B08': ('tests/test_fork_warning.gd', 141, 147),
      'B11': ('materials/serving_board_polished.tres', 8, 18),
      'B13': ('shaders/hint_experiment.gdshader', 4, 15),
      'B15': ('shaders/table_wood.gdshader', 3, 14)}


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


def code(bid, act, n, title, notes, cues, phrases, size=26):
    rel, a, z = EX[bid]
    return {'beat_id': bid, 'act': act, 'narration_text': n, 'estimated_duration_s': est(n),
            'shot': {'type': 'REMOTION', 'lane': 'body',
                     'show': [{'at': p, 'event': f'line {c[0]} highlighted'} for p, c in zip(phrases, cues)],
                     'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                         'mode': 'code', 'title': title, 'project': 'Jelly Hop', 'path': f'res://{rel}',
                         'source': f'godot/{rel} lines {a}–{z} · rev {REV} · Godot editor reconstruction, not a screenshot',
                         'code': lines(rel, a, z), 'startLine': a, 'codeFontSize': size,
                         'inspectorLabel': 'Source notes — not Inspector values',
                         'notes': [{'label': k, 'value': v} for k, v in notes],
                         'cues': [{'at': 0.0, 'line': l, 'label': t} for l, t in cues],
                         'output': [f'{rel} lines {a}–{z} · rev {REV}']}}},
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


def beats():
    clips = json.loads((REEL / 'media/clips.json').read_text())
    b = []
    command = ('Please use Walker to convert my game design document about Jelly Hop, a jelly cube hopping across a '
               'dinner table while forks stab down from above, into two shaders: a fork that turns candle amber during '
               'its shadow warning, and a textured wood material for the dinner table.')
    n = ("Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: shaders and materials for Jelly Hop, "
         "where a jelly cube dodges forks on a dinner table. This prompt is an illustrative reconstruction. "
         "Kiran's real work comes next.")
    b.append({'beat_id': 'B00', 'act': 'cold open — the Walker ask', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'ask', 'show': [
                  {'at': '0.0', 'event': "composer, spark and greeting 'Hej, Liam'"},
                  {'at': '0.2', 'event': 'the Walker prompt (worded from CHANGE-BRIEF.md, A5) types itself'},
                  {'at': '0.75', 'event': 'three output lines; the first labels the prompt a reconstruction'}],
                  'remotion': {'pattern': 'ClaudeComposerAsk', 'props': {
                      'greeting': 'Hej, Liam', 'topic': TOPIC, 'segment': TITLE,
                      'command': command, 'runningText': 'reading CHANGE-BRIEF.md…',
                      'output': ['Illustrative reconstruction of the ask, worded from CHANGE-BRIEF.md. Not a saved transcript.',
                                 'Built: fork_warning shader · table_wood shader · two wood materials',
                                 f'Shown at revision {REV} · Godot 4.7.2 · Compatibility renderer'],
                      'folderLabel': '@NikBearBrown'}}}})

    n = ("A fork turns amber before it strikes. One wood shader makes two materials. And every texture is "
         "information: what its numbers mean depends on how the shader reads them.")
    b.append({'beat_id': 'B01', 'act': 'what was built (hesitant writer)', 'narration_text': n, 'lead_silence_s': 0.8,
              'qc': {'sparse_by_design': True, 'sparse_reason': 'BrutalistHesitantWriter types the three-line overview token by token, '
                     'so mid-beat frames are mostly cream by design; the frame is only full once the third line and its '
                     'correction are typed.'},
              'estimated_duration_s': est(n, 0.8, 9.0),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.1', 'event': "'A fork turns amber before it strikes.' types out"},
                  {'at': '0.35', 'event': "'One wood shader, two materials.' types out"},
                  {'at': '0.6', 'event': "'Every texture is colour.' — 'colour' turns terracotta"},
                  {'at': '0.8', 'event': "the writer corrects it: 'Every texture is information.'"}],
                  'remotion': {'pattern': 'BrutalistHesitantWriter', 'props': {
                      'text': 'A fork turns amber before it strikes.\nOne wood shader, two materials.\nEvery texture is colour.',
                      'triggerWords': 'colour', 'replacementWords': 'information',
                      'face': 'serif', 'fontSize': 100, 'lineSpacing': 1.25, 'align': 'center',
                      'seed': 'jelly-hop-a5-2026', 'mistakeRate': 0, 'hesitateWithin': 0,
                      'hesitateBetween': 3, 'charMs': 26, 'jitter': 15}}}})

    p2 = [f for f in clips['held']['held-t455.png']['forks'] if f[0] == 2][0]
    n = ("Jelly Hop is Kiran's game: a jelly cube hops across plates on a dinner table while forks stab down from "
         "above. The state is a fork's SHADOW phase, the warning before it strikes. Its steel turns gradually toward "
         "candle amber, in step with its shadow. In 3D, the A3 floor becomes a worn dinner table, beside a polished "
         "serving board.")
    b.append(figure('B02', 'the game, the state, the 3D object', n, 'Jelly Hop: The State and the 3D Object',
                    'Held frame from the scripted capture · scripted in-engine capture',
                    'images/B02-identify.png', f'Left: tick 455, plate 2 fork warning {p2[2]:.2f} · right: materials_default.png',
                    'CHANGE-BRIEF.md §1, §7 · capture/run-a5-inputs.jsonl · evidence/a5-captures/materials_default.png',
                    [{'label': 'Game', 'text': 'Jelly Hop'}, {'label': 'State', 'text': "a fork's SHADOW phase"},
                     {'label': 'Colour', 'text': 'candle amber #FFB347'}, {'label': '3D', 'text': 'worn table, polished board'}],
                    ["Jelly Hop is", "The state is", 'candle amber', 'In 3D']))

    n = ("Kiran wrote the spec before any shader. Section two of the change brief holds the colour line: mix the "
         "fork's own colour toward the warning colour, by warning times strength. Only the RGB channels change, so "
         "the fork's silhouette never does. And warning is the fork's shadow growth during SHADOW, zero in every "
         "other phase or when held.")
    b.append(figure('B03', 'the colour line in the brief', n, 'The Spec First: CHANGE-BRIEF.md §2',
                    'Quoted from CHANGE-BRIEF.md · typeset, not a screenshot', 'images/B03-brief-colour-line.png',
                    'Version 1, 2026-10-27, written before the shader',
                    'CHANGE-BRIEF.md §2 (Version 1, 2026-10-27)',
                    [{'label': 'Written', 'text': 'before any shader'}, {'label': 'Colour line', 'text': 'mix toward amber'},
                     {'label': 'Alpha', 'text': 'untouched'}, {'label': 'warning', 'text': 'the shadow growth'}],
                    ['Kiran wrote', 'colour line', 'RGB channels', 'shadow growth']))

    n = ("Question one: what does a shader do? Kiran's answer is this file. It runs for the fragments that make up "
         "the fork's pixels, each time the fork is drawn. Line one makes it a canvas item shader, for 2D. Line four "
         "declares warning, from zero to one. Line nine is the brief's colour line, word for word: COLOR arrives as "
         "the fork's own pixel, and leaves mixed toward amber.")
    b.append(code('B04', 'code: Q1, the fork shader', n, 'Q1 · What a Shader Does: Line 9',
                  [('Written by', 'Kiran, by hand'), ('Agents', 'never edited it: git diff godot/shaders/ empty after every session')],
                  [(1, 'shader_type canvas_item: a 2D shader'), (4, 'warning: 0 to 1, set per fork'),
                   (9, 'the colour line from CHANGE-BRIEF.md §2')],
                  ['Line one', 'Line four', 'Line nine'], size=28))

    n = ("The result, in engine. In a scripted capture, Kiran stopped the game's physics and set warning on the plate "
         "two fork: zero, a half, one and two. Every measured pixel is within one eight-bit step of the prediction. "
         "At two, the tine reads two fifty-five, one seventy-eight, thirty-seven, exactly as extrapolated: hint range "
         "does not clamp a value set from code.")
    b.append(figure('B05', 'result: controlled values beside predictions', n, 'Controlled Values Beside the Predictions',
                    'Scripted in-engine captures · windowed · Compatibility · run by Kiran',
                    'images/B05-controlled-values.png', 'TEST-REPORT.md A5.4 · predictions: CHANGE-BRIEF.md Revision 5',
                    'evidence/a5-captures/fork_warning_*.png · capture-results.json · TEST-REPORT.md A5.4',
                    [{'label': 'Captures', 'text': 'scripted, windowed'}, {'label': 'Match', 'text': 'within one 8-bit step'},
                     {'label': 'warning 2.0', 'text': '(255, 178, 37)'}, {'label': 'hint_range', 'text': 'a slider, not a clamp'}],
                    ['scripted capture', 'Every measured', 'At two', 'hint range'], evidence=True))

    n = ("The driver, written by Claude Code from Kiran's approved plan. warning, on line two twenty-one, returns zero "
         "if the fork is held or not in SHADOW; otherwise, its shadow amount. Apply runs whenever the tick counter or "
         "held changes, and line two thirty-one writes that value into this fork's own material. Each fork was given "
         "its own duplicate of the base material.")
    b.append(code('B06', 'code: the driver in fork.gd', n, 'The Driver: fork.gd warning() and _apply()',
                  [('Line 49 (setup)', 'sprite.material = WARNING_MATERIAL.duplicate()'),
                   ('Boundary', 'reads phase and t; never writes t, held, hold_pending, announced')],
                  [(221, 'warning(): the uniform value'), (223, 'held or not SHADOW → 0.0'), (225, 'otherwise the shadow amount'),
                   (231, "written into this fork's own material")],
                  ['line two twenty-one', 'returns zero', 'otherwise', 'line two thirty-one']))

    regions = {r['label']: r['box'] for r in clips['label_regions']}
    n = ("Scripted capture, not a playtest. In the intro, the far forks start half amber. Plate two warms with its "
         "shadow, strikes, and turns silver. After the win, nothing advances: the forks hold their values.")
    b.append({'beat_id': 'B07', 'act': 'result: the effect in play (scripted capture)', 'narration_text': n,
              'estimated_duration_s': clips['duration_s'], 'capture': 'run-a5',
              'qc': {'full_bleed': True,
                     'full_bleed_reason': 'Unmodified Godot engine capture at 3840x2160 (scripted keyboard input, Movie Maker). '
                                          'The game draws its wall, table and curtain edge to edge, so content crossing the '
                                          'title-safe inset is the game filling the screen, not a card overflowing. Nothing was '
                                          'cropped, scaled or moved. The burned-in labels sit inside the title-safe inset.',
                     'contrast_regions': [{'label': k, 'box': v} for k, v in regions.items()],
                     'contrast_reason': 'Whole-frame contrast is low because the game is a dim dinner table by design. The essential '
                                        'text is the burned-in labels; each label region is tested instead.'},
              'shot': {'type': 'VIDEO', 'lane': 'capture', 'source': 'own', 'treatment': 'none',
                       'evidence_media': 'media/B07.mp4',
                       'labels': ['Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · rev 77a6d10 · not a human playtest',
                                  'excerpt N of 2 · ticks · state', 'plate N · PHASE · warning (from the capture log)'],
                       'show': [{'at': '0.0s', 'event': 'intro pan: plates 5 and 6 forks SHADOW 0.51 / 0.52, frozen'},
                                {'at': '4.0s', 'event': 'control returns; plates 3 and 4 ramp; plate 2 ramps'},
                                {'at': '7.9s', 'event': 'plate 2 fork strikes the jelly (tick 476); warning back to 0.00'},
                                {'at': '10.0s', 'event': 'excerpt 2: state WON, forks frozen with their values'}]}})

    n = ("How does the test know the right value? cycle of reads each plate's timings from the tuning file alone, "
         "never from the fork. expected at is the brief's formula. A sampler that runs after the session advances the "
         "forks compares every fork's warning with it, on every physics tick. Kiran checked that the test never "
         "advances a fork or sets the uniform itself.")
    b.append(code('B08', 'code: the headless driver test', n, 'The Test: The Brief’s Formula, Not the Fork’s',
                  [('Written by', 'Claude Code (sessions 2b–2d); read by Kiran'),
                   ('Kiran checked (grep)', 'no advance() / _apply(), no uniform set, no writes to t, held, state')],
                  [(143, 'cycle_of(): timings from slice_tuning.gd alone (lines 134–139)'), (141, "expected_at(): the brief's formula"),
                   (146, '(p − safe + 1) / shadow')],
                  ['cycle of', 'expected at', "brief's formula"], size=26))

    n = ("Headless, at thirty, sixty and one forty-four frames per second: twenty-nine checks, zero failures each time. "
         "The per-tick sequence, six hundred and one ticks of five forks, has the same MD5 at all three rates. The "
         "first SHADOW tick reads one over ninety-six, the last exactly one. Plates five and six start mid-SHADOW and "
         "hold through the pan. Pause holds the value; a splat drops it to zero.")
    b.append(figure('B09', 'result: headless numbers', n, 'What the Driver Test Proved',
                    'Headless · numbers only · not a render', 'images/B09-headless-driver.png',
                    'logs/test_fork_warning_30/60/144fps.log · TEST-REPORT.md A5.3',
                    'logs/test_fork_warning_*fps.log · TEST-REPORT.md A5.2, A5.3',
                    [{'label': '30 · 60 · 144', 'text': '29 checks / 0 failures'}, {'label': 'Per tick', 'text': 'one MD5'},
                     {'label': 'Ramp', 'text': '1/96 … 1.0 → 0'}, {'label': 'Holds', 'text': 'intro, pause; splat → 0'}],
                    ['Headless', 'per-tick sequence', 'first SHADOW tick', 'Pause holds'], evidence=True))

    n = ("Three mutations, each run by Kiran. A missing semicolon: a shader error, an empty uniform list, five "
         "failures. Renaming warning in the shader only: no error, and twenty-five of twenty-nine checks still passed, "
         "because set shader parameter quietly stores an unknown name. Only the uniform-list check caught it. Removing "
         "source colour from the wood's albedo: one of a hundred and eight failed. And no headless run draws a pixel: "
         "every judgement of colour is Kiran's eye.")
    b.append(figure('B10', 'three mutations, and what headless cannot show', n, 'Three Mutations, and the Limit of Headless',
                    'Logs of runs by Kiran · each exited 1', 'images/B10-mutations.png',
                    'logs/mutation-1/2/3-*_60fps.log · TEST-REPORT.md A5.2, A5.9',
                    'logs/mutation-*_60fps.log · TEST-REPORT.md A5.2, A5.9 · CLAUDE.md headless facts · CHANGE-BRIEF.md §5',
                    [{'label': 'Semicolon', 'text': 'SHADER ERROR · 5 fail'}, {'label': 'Rename', 'text': '4 of 29 fail'},
                     {'label': 'source_color', 'text': '1 of 108 fails'}, {'label': 'Headless', 'text': 'draws nothing'}],
                    ['missing semicolon', 'Renaming warning', 'Removing', 'no headless run']))

    n = ("Question two: how is a material different from a shader? This is a material, the polished serving board. "
         "Line ten points at the one table wood shader. Every other line is a value for it: the same three textures, "
         "a warm tint, roughness point three five, normal strength a half. The worn table's file points at the same "
         "shader, with a white tint, roughness one, and UV scale two.")
    b.append(code('B11', 'code: Q2, a material file', n, 'Q2 · A Material Is Values for a Shader',
                  [('table_wood_worn.tres', 'same shader · tint white · roughness 1.0 · normal 1.0 · uv_scale 2.0'),
                   ('Made by', 'Kiran, in the editor')],
                  [(10, 'shader = the one table_wood shader'), (12, 'tint (1, 0.85, 0.70)'),
                   (16, 'roughness_scale 0.35'), (17, 'normal_strength 0.5')],
                  ['Line ten', 'warm tint', 'roughness point', 'normal strength'], size=23))

    n = ("Kiran tested the difference in memory, changing no file. Edit one line of the shader, and both pieces of "
         "wood change. Edit only the board material's brightness, and only the board changes; the table stays at "
         "ninety-two, forty-five, twenty-nine. The shader is the program. A material is one set of values for it.")
    b.append(figure('B12', 'result: one shader, two materials', n, 'One Shader, Two Materials',
                    'Scripted in-engine captures · in memory only · run by Kiran', 'images/B12-one-shader-two-materials.png',
                    'evidence/a5-captures/shared/ · TEST-REPORT.md A5.8',
                    'evidence/a5-captures/shared/1–3 · TEST-REPORT.md A5.8',
                    [{'label': 'Shader', 'text': 'one object, shared'}, {'label': 'Shader edit', 'text': 'both change'},
                     {'label': 'Material edit', 'text': 'only the board'}, {'label': 'Files', 'text': 'none changed'}],
                    ['in memory', 'Edit one line', 'Edit only', 'The shader is'], evidence=True))

    n = ("Question three: why is a texture information? Kiran's hint experiment binds one three-pixel grey strip, "
         "sixty-four, one twenty-eight and one ninety-two, to two samplers. Line four reads it with source colour, as "
         "colour. Line five reads the same file with no hint, as plain data. Line seven picks which one draws.")
    b.append(code('B13', 'code: Q3, the hint experiment', n, 'Q3 · One File, Read Two Ways',
                  [('Written by', 'Kiran, by hand'), ('Strip', 'hint_strip_3x1.png: greys 64, 128, 192, written by code')],
                  [(4, 'source_color: read as colour'), (5, 'no hint: read as data'), (7, 'which sampler writes ALBEDO')],
                  ['Line four', 'Line five', 'Line seven'], size=23))

    n = ("The brief predicted that with source colour the quad shows the file unchanged, and without it, brighter: one "
         "thirty-seven, one eighty-eight, two twenty-five. On Forward-plus, exactly that. On the project's Compatibility "
         "renderer, both quads show the file unchanged. Kiran measured first and explained after: the difference is "
         "the renderer. Why, on Compatibility, is still unresolved.")
    b.append(figure('B14', 'result: hint experiment on two renderers', n, 'The Hint Experiment: Predicted and Measured',
                    'Scripted in-engine captures · Compatibility and one Forward+ run', 'images/B14-hint-experiment.png',
                    'TEST-REPORT.md A5.6 · predictions: CHANGE-BRIEF.md §8',
                    'evidence/a5-captures*/hint_experiment.png, capture-results.json · TEST-REPORT.md A5.6',
                    [{'label': 'Predicted', 'text': 'without: 137 · 188 · 225'}, {'label': 'Forward+', 'text': 'as predicted'},
                     {'label': 'Compatibility', 'text': '64 · 128 · 192 both'}, {'label': 'Why', 'text': 'unresolved'}],
                    ['The brief predicted', 'Forward-plus', 'Compatibility', 'unresolved'], evidence=True))

    n = ("The wood shader makes that choice for every texture. Line five: the albedo is a photo, sRGB colour, so source "
         "colour. Line eleven: roughness is data, zero a mirror, one fully rough, so no colour hint, and white if "
         "nothing is bound. Line twelve: the normal map holds slopes, so hint normal, and no source colour.")
    b.append(code('B15', 'code: Q3, the wood samplers', n, 'Q3 · Colour or Data: table_wood.gdshader',
                  [('Written by', 'Kiran, by hand'), ('Normal map', 'OpenGL convention (_nor_gl), as Godot expects')],
                  [(5, 'albedo: colour → source_color'), (11, 'roughness: data, white default'), (12, 'normal map: hint_normal')],
                  ['Line five', 'Line eleven', 'Line twelve'], size=24))

    n = ("In engine, the worn table and the board read as dark wood under the Sun. Behind that, a headless materials "
         "test checks every sampler's hints and every bound file: a hundred and eight checks, no failures. And the "
         "bound normal map is the OpenGL one: its curl ratio is point three eight, under Kiran's threshold of point "
         "seven for this texture.")
    b.append(figure('B16', 'result: the wood, and the data checks', n, 'The Wood in Engine, and Its Data Checked',
                    'Scripted in-engine capture · and headless checks', 'images/B16-wood-and-data.png',
                    'TEST-REPORT.md A5.9 · CHANGE-BRIEF.md §7, Revision 3',
                    'materials_default.png · logs/test_materials_60fps.log · logs/calibrate_normal_check_60fps.log',
                    [{'label': 'In engine', 'text': 'Sun only, no ambient'}, {'label': 'test_materials', 'text': '108 / 0'},
                     {'label': 'Curl (GL)', 'text': '0.3838'}, {'label': 'Threshold', 'text': '< 0.70, this map only'}],
                    ['In engine', 'a hundred and eight', 'curl ratio', 'threshold'], evidence=True))

    n = ("Godot can write this code too. Kiran converted a standard material to a shader and saved it unedited. "
         "Generated line seven marks the albedo texture source colour, matching Kiran's line five. Generated line "
         "nineteen reads the normal map without source colour, as data, matching line twelve. It says hint roughness "
         "normal where Kiran wrote hint normal; Kiran has not verified the exact difference.")
    b.append(figure('B17', "Godot's generated shader beside Kiran's", n, "Godot's Generated Lines Beside Kiran's",
                    'Lines read from the files · typeset, not a screenshot', 'images/B17-generated-vs-mine.png',
                    "Annotations: Kiran's words, LANGUAGE-NOTES.md answer 6",
                    'godot/shaders/standard_generated.gdshader 7, 19 · table_wood.gdshader 5, 12 · LANGUAGE-NOTES.md',
                    [{'label': 'Generated', 'text': 'saved unedited'}, {'label': '7 ↔ 5', 'text': 'colour'},
                     {'label': '19 ↔ 12', 'text': 'data'}, {'label': 'The hints', 'text': 'difference not verified'}],
                    ['Godot can', 'line seven', 'nineteen', 'hint roughness']))

    n = ("The interface sweep: each wood setting at minimum, default and maximum, fifteen captures. Brightness, UV scale "
         "and tint changed as predicted. Roughness scale moved the table by at most twenty levels, with no Sun "
         "highlight, so Kiran's prediction did not hold. Normal strength moved it by at most two; a very flat map is "
         "the likely reason, not tested.")
    b.append(figure('B18', 'the interface sweep', n, 'The Interface Sweep: Fifteen Captures',
                    "Scripted in-engine captures · Kiran's observations", 'images/B18-sweep.png',
                    'evidence/a5-sweep-notes.md · TEST-REPORT.md A5.7',
                    'evidence/a5-captures/sweep_table_*.png · evidence/a5-sweep-notes.md · TEST-REPORT.md A5.7',
                    [{'label': 'As predicted', 'text': 'brightness, uv, tint'}, {'label': 'roughness', 'text': 'max 20, no highlight'},
                     {'label': 'normal', 'text': 'max 2 of 255'}, {'label': 'Flat map?', 'text': 'not tested'}],
                    ['Brightness', 'Roughness scale', 'Normal strength', 'flat map']))

    n = ("Question four: what is the Godot shading language? In Kiran's words, line one, shader type, tells Godot what "
         "kind of object the shader works on and which built-ins it can use: COLOR for the 2D fork, ALBEDO and "
         "ROUGHNESS for the 3D wood, while Godot does the lighting. Hints and groups become Inspector controls. With "
         "plain GLSL, the application would have to provide that material system.")
    b.append(trace('B19', 'Q4: the Godot shading language', n, 'Q4 · The Godot Shading Language: Line 1',
                   "LANGUAGE-NOTES.md answers 1 and 8 (Kiran's words) · the shaders' own lines",
                   'Line 1 decides the built-ins (file:line → what it gives)',
                   ['fork_warning.gdshader:1   shader_type canvas_item;   →  COLOR (line 9)',
                    'table_wood.gdshader:1   shader_type spatial;   →  ALBEDO, ROUGHNESS, NORMAL_MAP (25–28)',
                    'hint_experiment.gdshader:1   shader_type spatial;   →  ALBEDO (11, 13)',
                    'table_wood.gdshader:3, 9, 16   group_uniforms   →  Inspector groups',
                    'table_wood.gdshader:6, 7   source_color, hint_range   →  picker, slider'],
                   [('Answer 1', 'shader_type: what kind of object, which built-ins'),
                    ('Answer 8', 'plain GLSL: the application provides the material system')],
                   [(1, '2D: COLOR'), (2, '3D: ALBEDO, ROUGHNESS; Godot lights it'), (4, 'hints and groups → Inspector')],
                   ['COLOR for', 'ALBEDO and', 'Hints and groups'],
                   ['Source-backed list from the shaders and LANGUAGE-NOTES.md; not a live editor session.']))

    n = ("What the agent got wrong, and Kiran caught. Its own test read the sampler rows before the sampler had "
         "recorded the frame; it stopped twice, and Kiran approved each fix only after reading it. Its audit added a "
         "video-memory estimate nobody had measured; Kiran deleted it. Its CLAUDE.md draft needed five corrections. "
         "And it ran commands Kiran did not expect, so the real guard was an empty shader diff after every session. "
         "It also got one right: the audit corrected Kiran's spec on UV scale.")
    b.append(trace('B20', 'agent mistakes Kiran caught', n, 'What the Agent Got Wrong, and Kiran Caught',
                   'FRICTIONAL.md A5-3, A5-5, A5-8 · TEST-REPORT.md A5.10',
                   'Claude Code (agent) → what Kiran did',
                   ['Test read sampler rows too early → stopped twice; Kiran approved each fix',
                    'Unmeasured video-memory estimate in MATERIALS.md → Kiran deleted it',
                    'CLAUDE.md draft → Kiran made 5 corrections',
                    'Ran file, wc, head, which → guard: git diff godot/shaders/ empty',
                    'Got right: the BoxMesh UV slice → Kiran corrected §7 (Revision 4)'],
                   [('Sessions', '6 agent sessions, shader diff empty after each (A5.10)'),
                    ('Shaders', 'never edited by an agent')],
                   [(1, 'test timing bug'), (2, 'unmeasured estimate'), (3, 'five corrections'), (4, 'the real guard'),
                    (5, 'one it got right')],
                   ['test read', 'video-memory', 'five corrections', 'commands Kiran', 'got one right'],
                   ['Agent mistakes only; Kiran\'s slips: FRICTIONAL.md A5-7.']))

    n = ("Still uncertain, in Kiran's own list. Why Compatibility shows the strip unchanged with and without source "
         "colour. The exact difference between the two normal hints. Whether the table's tint is converted to linear. "
         "Whether the flat map is why normal strength shows nothing. And why a fresh-cache import crashes on an A2 "
         "sound file; the workaround is to import twice.")
    b.append(trace('B21', 'what remains uncertain', n, 'Still Uncertain',
                   'FRICTIONAL.md A5 "Still unresolved" · TEST-REPORT.md A5.9, A5.11',
                   'Unresolved (FRICTIONAL.md A5)',
                   ['Compatibility: strip unchanged with and without source_color',
                    'hint_roughness_normal vs hint_normal',
                    "the table's tint: converted to linear? not measured",
                    'normal_strength invisible: flat map? not tested',
                    'fresh-cache import segfault on SFX-WIN.ogg (A2): import twice'],
                   [('Source', 'FRICTIONAL.md A5, "Still unresolved"'), ('Crash', 'exit 139, 2 of 2 attempts (A5.9)')],
                   [(1, 'renderer'), (2, 'normal hints'), (3, 'tint'), (4, 'flat map'), (5, 'import crash')],
                   ['Why Compatibility', 'normal hints', 'tint', 'flat map', 'fresh-cache'],
                   ['Each is open; none is claimed as solved in this film.']))

    nxt = "measure whether the table's tint is converted to linear"
    n = ("Verdict. The fork warns in amber from its own tick counter: twenty-nine checks at three frame rates with one "
         "per-tick sequence, and captured pixels within one step of Kiran's predictions. One shader makes two "
         "materials. Two predictions did not hold: the hint values on Compatibility, and the roughness highlight. "
         "Kiran wrote the brief and its revisions, hand-wrote all three shaders, made the materials, and ran every "
         "human check and mutation. Claude Code wrote the driver, both tests, the audit and this film; Claude in chat "
         "wrote the capture scripts and organised the notes. The textures are Poly Haven's Dark Wood, CC zero, by "
         f"Dario Barresi, Dimitrios Savva and Rico Cilliers. One next step, proposed from the open items: {nxt}. "
         "Shown at revision seven seven A six D one zero.")
    b.append({'beat_id': 'BVDT', 'act': 'verdict', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.05', 'event': f"artifact page 'Jelly Hop — shaders and materials at {REV}'"},
                  {'at': '0.1', 'event': 'lines land as the voice names them'}],
                  'remotion': {'pattern': 'ClaudeVerdictArtifact', 'props': {
                      'artifactTitle': 'Verdict', 'artifactHeading': f'Jelly Hop — shaders and materials at {REV}',
                      'brandLabel': '@NikBearBrown',
                      'artifactLines': [
                          'WORKS — 29/0 at 30, 60, 144 fps, one per-tick MD5 · pixels within 1 step · 108/0',
                          'DID NOT HOLD — hint prediction on Compatibility · roughness highlight',
                          'KIRAN — brief, 3 shaders by hand, materials, every human check, mutations',
                          'CLAUDE CODE — driver, tests, audit, this film · CHAT — capture scripts, notes',
                          'TEXTURES — Poly Haven Dark Wood, CC0 · Barresi, Savva, Cilliers',
                          'NEXT (proposed from the open items) — measure the tint conversion',
                          f'SOURCE — revision {REV} · Godot 4.7.2 · Compatibility renderer']}}}})

    prompt = ("Use Walker: before writing a shader, put one uniform's job into your brief with predicted values for two "
              "pixels, write the shader yourself, capture those pixels in engine, then run one mutation you expect "
              "your test to miss. Tell me which result surprised you.")
    n = (f"Your turn. {prompt} Predicting first is what made Kiran's Compatibility result a finding, not a mistake. "
         "And pick a mutation you think will slip through: Kiran's rename nearly did. Liam, in for Bear.")
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


EXCL = ('Assignment 2 or 3 file, not changed by A5 and outside this A5 film\'s scope (explained in the A2 and A3 films, '
        'youtube/claude-liam-jelly-hop-gamedev/ and youtube/claude-liam-jelly-hop-a3/).')
COMPONENTS = [
    ('a5-fork-warning', "The fork warning: Kiran's canvas_item shader, the base ShaderMaterial, and the presentation-only driver "
     "in fork.gd (warning(), _apply(), one duplicate material per fork).",
     ['B02', 'B03', 'B04', 'B05', 'B06', 'B07'],
     ['shaders/fork_warning.gdshader', 'materials/fork_warning.tres', 'features/fork/fork.gd']),
    ('a5-fork-test', 'The headless driver test: the brief\'s formula per tick at 30/60/144 fps, intro, pause, time scale, '
     'splat, distinct materials; and the headless probe behind CLAUDE.md\'s headless facts.',
     ['B08', 'B09', 'B10'], ['tests/test_fork_warning.gd', 'tests/probe_headless.gd']),
    ('a5-table-wood', "Kiran's spatial wood shader, the two materials made from it, the A5 scene, and the Dark Wood textures "
     'with their import settings and attribution.',
     ['B02', 'B11', 'B12', 'B15', 'B16', 'B18'],
     ['shaders/table_wood.gdshader', 'materials/table_wood_worn.tres', 'materials/serving_board_polished.tres',
      'showcase/a5_materials.tscn', 'assets/textures/dark_wood/ATTRIBUTION.md',
      'assets/textures/dark_wood/dark_wood_diff_2k.png', 'assets/textures/dark_wood/dark_wood_diff_2k.png.import',
      'assets/textures/dark_wood/dark_wood_rough_2k.png', 'assets/textures/dark_wood/dark_wood_rough_2k.png.import',
      'assets/textures/dark_wood/dark_wood_nor_gl_2k.png', 'assets/textures/dark_wood/dark_wood_nor_gl_2k.png.import',
      'assets/textures/dark_wood/dark_wood_nor_dx_2k.png', 'assets/textures/dark_wood/dark_wood_nor_dx_2k.png.import']),
    ('a5-hint-experiment', 'The hint experiment: one grey strip read with and without source_color, its two materials and '
     'scene, the script that wrote the strip, and the project setting naming the Compatibility renderer.',
     ['B13', 'B14'],
     ['shaders/hint_experiment.gdshader', 'materials/hint_with_source_color.tres', 'materials/hint_without_source_color.tres',
      'showcase/hint_experiment.tscn', 'assets/textures/hint_strip/hint_strip_3x1.png',
      'assets/textures/hint_strip/hint_strip_3x1.png.import', 'tools/make_hint_strip.gd', 'project.godot']),
    ('a5-generated', "Godot's generated shader (Convert to ShaderMaterial, saved unedited) and the scratch scene it came from.",
     ['B17', 'B19'], ['shaders/standard_generated.gdshader', 'scratch/standard_scratch.tscn']),
    ('a5-material-checks', "The agent's materials audit and test, and the handout's curl check with its calibration.",
     ['B10', 'B16'], ['MATERIALS.md', 'tests/test_materials.gd', 'tests/normal_map_check.gd', 'tests/calibrate_normal_check.gd']),
    ('a5-captures', 'The scripted in-engine capture scripts (by Claude in chat, run by Kiran) behind every A5 capture shown.',
     ['B05', 'B12', 'B14', 'B18'], ['tools/capture_a5.gd', 'tools/capture_shared.gd']),
]


def ledger(sheet):
    inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob('*')
                       if p.is_file() and not any(x in ('.godot', '.git') for x in p.relative_to(GAME).parts)
                       and p.suffix != '.uid' and p.name != '.DS_Store')
    comp_files = {cid: set(files) for cid, _, _, files in COMPONENTS}
    records, excl = [], []
    for f in inventory:
        cids = [cid for cid in comp_files if f in comp_files[cid]]
        if not cids:
            excl.append({'path': f, 'reason': EXCL})
            continue
        role = 'import settings' if f.endswith('.import') else ('asset' if f.startswith('assets/') else 'source')
        records.append({'path': f, 'sha256': sha_file(GAME / f), 'role': role, 'component_ids': cids})
    for cid, files in comp_files.items():
        for f in files:
            if f not in inventory:
                raise SystemExit(f'STOPPED: {f} ({cid}) is not in godot/')
    beats = {x['beat_id']: x for x in sheet['beats']}
    excerpts = [{'beat_id': bid, 'path': rel, 'start_line': a, 'end_line': z, 'text': lines(rel, a, z)}
                for bid, (rel, a, z) in EX.items()]
    obs = {'B05': 'At warning 0, 0.5, 1 and 2 the plate 2 fork\'s P1 and P2 pixels measure within one 8-bit step of Kiran\'s '
                  'predictions; at 2.0 P1 is (255, 178, 37) (evidence/a5-captures/capture-results.json).',
           'B07': 'In the scripted capture the plate 2 fork\'s warning (from the log) climbs during SHADOW while its tines turn amber, '
                  'it strikes at tick 476 and reads 0.00 again as the tines return to steel; plates 5 and 6 read 0.51/0.52 in the intro.',
           'B09': 'test_fork_warning.gd reports 29 checks / 0 failures at 30, 60 and 144 fps with one per-tick MD5 '
                  '35385bc4a519009a685ec285b3ba7529 (logs/test_fork_warning_*fps.log).',
           'B12': 'Editing one shader line changes both table and board; editing the board material changes only the board '
                  '(evidence/a5-captures/shared/, TEST-REPORT.md A5.8).',
           'B14': 'With source_color both renderers show 64/128/192; without it Forward+ shows 137/188/225 and Compatibility '
                  '64/128/192 (capture-results.json, both folders).',
           'B16': 'The worn table and board render as dark wood in engine (materials_default.png); test_materials reports '
                  '108 checks / 0 failures and the bound GL normal map scores 0.3838.'}
    pairs = []
    for code_b, result_b in (('B04', 'B05'), ('B06', 'B07'), ('B08', 'B09'), ('B11', 'B12'), ('B13', 'B14'), ('B15', 'B16')):
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
           'Drafted by Claude Code on 2026-10-28, for Kiran\'s review. Narration is what Liam says; "On screen" is what the '
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
                   f'tools/make_master.py set from the Kokoro narration and the B07 clip length.**')
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
        'capture_method': ('one scripted-input take (capture/, Godot Movie Maker, windowed, offline 4K) from a git-archive '
                           f'snapshot of {REV}; plus Kiran\'s committed in-engine captures and logs'),
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
