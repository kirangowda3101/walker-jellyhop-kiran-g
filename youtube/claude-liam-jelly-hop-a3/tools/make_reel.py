"""Writes beat_sheet.json, gamedev-evidence.json and SCRIPT.md for the Jelly Hop A3 film.

    python3 tools/make_reel.py        (run from the reel folder, after make_images.py)

Same pipeline as the A2 film (youtube/claude-liam-jelly-hop-gamedev/tools/make_reel.py). Code shown on
screen is read from the repository's own files by line range (never retyped). Images are embedded in
Remotion props as data URIs. Every claim in the narration is sourced in FACTCHECK.md.
Drafted unattended by Claude Code on 2026-10-13 for Kiran's morning review.
"""
import base64
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

REEL = Path(__file__).resolve().parent.parent
GAME = REEL.parent.parent / 'godot'
TITLE = 'Jelly Hop: Three 3D Assets'   # Claude Code's choice (unattended run); for Kiran's review
SLUG = 'claude-liam-jelly-hop-a3'
TOPIC = 'JELLY HOP · BLENDER MCP → GODOT'
REV = '948ab6a'
REV_FULL = '948ab6a7f126f08dca8d49786f5adeb863aad044'
WPS = 2.7   # rough Kokoro am_onyx speaking rate, for estimates only

B06 = ('showcase/a3_assets.tscn', 27, 37)   # the three instances and the jelly reference cube
B08 = ('tests/test_a3_assets.gd', 7, 12)    # the brief, converted to Godot's axes


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


def figure(bid, act, n, title, status, image, image_label, source, cards, phrases, show, evidence=False):
    shot = {'type': 'REMOTION', 'lane': 'body', 'show': show,
            'remotion': {'pattern': 'GodotDesignFigure', 'props': {
                'title': title, 'status': status, 'image': data_uri(image), 'imageLabel': image_label,
                'source': source, 'cards': cards, 'cues': [{'at': 0.0, 'card': i} for i in range(len(cards))]}}}
    if evidence:
        shot['evidence_media'] = image
    return {'beat_id': bid, 'act': act, 'narration_text': n, 'estimated_duration_s': est(n), 'shot': shot,
            'cue_phrases': phrases}


def beats():
    b = []
    command = ('Please use Walker to convert my game design document about Jelly Hop, a small jelly cube hopping '
               'across a dinner table while forks stab down from above, into three simple 3D assets in Blender: '
               'the fork, a dessert dome for the goal, and a biscuit platform to land on.')
    n = ("Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: three simple 3D assets for Jelly Hop, "
         "where a jelly cube dodges forks on a dinner table. This prompt is an illustrative reconstruction. "
         "Kiran's real prompt and screenshots come next.")
    b.append({'beat_id': 'B00', 'act': 'cold open — the Walker ask', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'ask', 'show': [
                  {'at': '0.0', 'event': "composer, spark and greeting 'Hej, Liam'"},
                  {'at': '0.2', 'event': 'the Walker prompt (worded from CHANGE-BRIEF.md, A3) types itself'},
                  {'at': '0.6', 'event': "running indicator: 'reading CHANGE-BRIEF.md…'"},
                  {'at': '0.75', 'event': 'three output lines; the first labels the prompt a reconstruction'}],
                  'remotion': {'pattern': 'ClaudeComposerAsk', 'props': {
                      'greeting': 'Hej, Liam', 'topic': TOPIC, 'segment': TITLE,
                      'command': command, 'runningText': 'reading CHANGE-BRIEF.md…',
                      'output': ['Illustrative reconstruction of the ask, worded from CHANGE-BRIEF.md. Not a saved transcript.',
                                 'Built: fork 72 tris · dessert dome 266 · biscuit platform 36',
                                 f'Shown at revision {REV} · Blender 5.2.2 · Godot 4.7.2'],
                      'folderLabel': '@NikBearBrown'}}}})

    n = ("A fork, a dessert dome and a biscuit platform, built in Blender by Claude Code through the MCP, then "
         "checked in Godot. One correction already: the final dome colours are Kiran's, set by hand.")
    b.append({'beat_id': 'B01', 'act': 'what was built (hesitant writer)', 'narration_text': n, 'lead_silence_s': 0.8,
              'qc': {'sparse_by_design': True, 'sparse_reason': 'BrutalistHesitantWriter types the three-line overview token by token, '
                     'so mid-beat frames are mostly cream by design; the frame is only full once the third line and its '
                     'correction are typed.'},
              'estimated_duration_s': est(n, 0.8, 9.0),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.1', 'event': "'Three 3D assets for Jelly Hop.' types out"},
                  {'at': '0.35', 'event': "'Built in Blender through the MCP.' types out"},
                  {'at': '0.6', 'event': "'Claude chose the final dome colours.' — 'Claude' turns terracotta"},
                  {'at': '0.8', 'event': "the writer corrects it: 'Kiran chose the final dome colours.'"}],
                  'remotion': {'pattern': 'BrutalistHesitantWriter', 'props': {
                      'text': 'Three 3D assets for Jelly Hop.\nBuilt in Blender through the MCP.\nClaude chose the final dome colours.',
                      'triggerWords': 'Claude', 'replacementWords': 'Kiran',
                      'face': 'serif', 'fontSize': 100, 'lineSpacing': 1.25, 'align': 'center',
                      'seed': 'jelly-hop-a3-2026', 'mistakeRate': 0, 'hesitateWithin': 0,
                      'hesitateBetween': 3, 'charMs': 26, 'jitter': 15}}}})

    n = ("Why each one. The fork is the hazard: it stabs down from above, so the jelly has to time its jumps. "
         "The dessert dome is the goal at the end of the level. The biscuit is a stepping stone to land on, planned "
         "for future levels. Every size is set against the half-metre jelly: the fork is three jellies tall.")
    b.append(figure('B02', 'the three assets and why the game needs each', n,
                    'Three Assets, and Why Jelly Hop Needs Each', "Crops of Kiran's screenshot 19 · roles from the brief",
                    'images/B02-three-assets.png', "Kiran's screenshot 19, cropped · CHANGE-BRIEF.md A3 v1",
                    'CHANGE-BRIEF.md, Assignment 3 v1 (2026-10-12, committed before building, eaaa66f)',
                    [{'label': 'Fork', 'text': 'the hazard'}, {'label': 'Dessert dome', 'text': 'the goal'},
                     {'label': 'Biscuit platform', 'text': 'a stepping stone'}, {'label': 'Scale', 'text': 'jelly = 0.5 m'}],
                    ['The fork is the hazard', 'The dessert dome', 'The biscuit', 'half-metre jelly'],
                    [{'at': 'The fork', 'event': 'fork card lights'}, {'at': 'dessert dome', 'event': 'dome card lights'},
                     {'at': 'biscuit', 'event': 'platform card lights'}, {'at': 'half-metre', 'event': 'scale card lights'}]))

    n = ("Kiran's own screenshot: the fork prompt to Claude Code. It names Walker's loop and points at the brief, "
         "then repeats its numbers: half a metre wide, one and a half tall, six boxes, a budget of a hundred "
         "triangles. Then: propose the steps; do not build yet. No asset libraries, no generators.")
    b.append(figure('B03', "Kiran's prompt to Claude (screenshot 23)", n,
                    'The Prompt: Brief First, Plan Before Building', "Kiran's screenshot 23 · Claude Code in Terminal",
                    'images/B03-fork-prompt.png', "Kiran's screenshot · not a reconstruction",
                    'evidence/a3/screenshots/23-claude-code-fork-prompt.png · evidence/a3/claude-code-a3-transcript.txt',
                    [{'label': 'Brief', 'text': 'read CHANGE-BRIEF.md first'}, {'label': 'Numbers', 'text': '0.5 × 1.5 m · 100 tris'},
                     {'label': 'Plan first', 'text': '"Do not build yet."'}, {'label': 'Off', 'text': 'libraries, generators'}],
                    ["names Walker's loop", 'repeats its numbers', 'propose the steps', 'No asset libraries'],
                    [{'at': 'Walker', 'event': 'brief card lights'}, {'at': 'numbers', 'event': 'numbers card'},
                     {'at': 'propose', 'event': 'plan-first card'}, {'at': 'No asset libraries', 'event': 'off card'}]))

    n = ("What it built, again Kiran's screenshot. Claude's plan: four prongs, a head and a handle, six boxes, all "
         "five centimetres deep. Kiran accepted it. The status bar reads Tris seventy-two, under the budget of a "
         "hundred, and Kiran checked that the fork points down with its tips at the origin.")
    b.append(figure('B04', 'what Claude Code built (screenshot 12)', n,
                    'What It Built: Six Boxes, 72 Triangles', "Kiran's screenshot 12 · Blender 5.2.2 · through the MCP",
                    'images/B04-fork-built.png', "Kiran's screenshot · status bar values typed beside it",
                    'evidence/a3/screenshots/12-fork-six-parts-tris-72.png · FRICTIONAL.md 2026-10-12 "A3: the fork"',
                    [{'label': 'Plan', 'text': '4 prongs, head, handle'}, {'label': 'Kiran', 'text': 'accepted the plan'},
                     {'label': 'Tris', 'text': '72 of 100'}, {'label': 'Checked', 'text': 'points down'}],
                    ["Claude's plan", 'Kiran accepted', 'Tris seventy-two', 'points down'],
                    [{'at': 'plan', 'event': 'plan card'}, {'at': 'accepted', 'event': 'Kiran card'},
                     {'at': 'Tris', 'event': 'tris card'}, {'at': 'points down', 'event': 'checked card'}]))

    n = ("The hand edit. In Material Preview the dome looked washed out: the cover nearly white-lavender, the cherry "
         "salmon. Kiran opened the Material tab and raised the cover's saturation from about point one eight to point "
         "four five, then darkened the cherry and warmed the cream. One slip on the way: a value went into the wrong "
         "field and the cherry turned blue, so Kiran restored the original before redoing it.")
    b.append(figure('B05', "Kiran's hand edit (screenshots 13, 14, 15)", n,
                    "Kiran's Hand Edit: The Dome's Colours", "Kiran's screenshots 13 · 14 · 15 · Blender Material tab",
                    'images/B05-hand-edit.png', "Crops of Kiran's screenshots · swatches drawn from the recorded hex",
                    'TEST-REPORT.md A3.10 · FRICTIONAL.md "A3: the dessert dome and my hand edit"',
                    [{'label': 'Seen', 'text': 'washed out'}, {'label': 'Dome_Pink', 'text': '#D1AAB6 → #D17390'},
                     {'label': 'Red, cream', 'text': '#A6111E · #F9DEA2'}, {'label': 'Slip', 'text': 'wrong field → blue'}],
                    ['washed out', 'raised the cover', 'darkened the cherry', 'One slip'],
                    [{'at': 'washed out', 'event': 'screenshot 13 card'}, {'at': 'saturation', 'event': 'pink card'},
                     {'at': 'cherry', 'event': 'red/cream card'}, {'at': 'slip', 'event': 'slip card'}]))

    code6 = lines(*B06)
    n = ("Now Godot. The showcase scene is a small text file. Each asset is an instance of its exported glb, set "
         "side by side: the platform at minus two point five, the dome at the origin, the fork at one point five. "
         "And a half-metre cube at three: a size reference for the jelly, not an asset.")
    b.append({'beat_id': 'B06', 'act': 'code: the showcase scene', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': 'platform', 'event': 'line 27 highlighted'}, {'at': 'dome', 'event': 'line 30'},
                  {'at': 'fork', 'event': 'line 32'}, {'at': 'half-metre cube', 'event': 'line 35'}],
                  'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                      'mode': 'code', 'title': 'The Scene: Three Instances on One Floor', 'project': 'Jelly Hop',
                      'path': 'res://showcase/a3_assets.tscn', 'source': 'godot/showcase/a3_assets.tscn',
                      'code': code6, 'startLine': B06[1], 'codeFontSize': 26,
                      'inspectorLabel': 'Source notes — not Inspector values',
                      'notes': [{'label': 'Transform basis', 'value': 'identity: scale 1, no rotation'},
                                {'label': 'Written by', 'value': 'Claude Code; plan accepted by Kiran'}],
                      'cues': [{'at': 0.0, 'line': 27, 'label': 'platform at x = −2.5'},
                               {'at': 0.0, 'line': 30, 'label': 'dome at the origin'},
                               {'at': 0.0, 'line': 32, 'label': 'fork at x = 1.5'},
                               {'at': 0.0, 'line': 35, 'label': '0.5 m jelly reference, not an asset'}],
                      'output': [f'{B06[0]} lines {B06[1]}–{B06[2]} · rev {REV}']}}},
              'cue_phrases': ['the platform', 'the dome', 'the fork', 'half-metre cube']})

    n = ("Run Current Scene, Kiran's screenshot through the scene camera. Biscuit, dome, fork and the reference "
         "cube, standing upright on the floor. Kiran wrote: at this size, I can recognise the fork, dessert dome, "
         "and sandwich biscuit. And noted that the dark sides hide some detail.")
    b.append(figure('B07', 'result: the three assets in Godot (screenshot 19)', n,
                    'The Result: Through the Scene Camera', "Kiran's screenshot 19 · Godot 4.7.2 · Run Current Scene",
                    'images/B07-scene-camera.png', "Kiran's screenshot · cropped to the game view, not retouched",
                    'evidence/a3/screenshots/19-godot-scene-camera-run.png · TEST-REPORT.md A3.8',
                    [{'label': 'Order', 'text': 'platform · dome · fork'}, {'label': 'Upright', 'text': 'on the floor'},
                     {'label': 'Kiran', 'text': '"I can recognise…"'}, {'label': 'But', 'text': 'dark sides'}],
                    ['Biscuit, dome', 'standing upright', 'Kiran wrote', 'dark sides'],
                    [{'at': 'Biscuit', 'event': 'order card'}, {'at': 'upright', 'event': 'upright card'},
                     {'at': 'Kiran wrote', 'event': "Kiran's words card"}, {'at': 'dark sides', 'event': 'limit card'}],
                    evidence=True))

    code8 = lines(*B08)
    n = ("The check. Line seven: expected values come from the brief, never from the files checked. Blender is "
         "Z-up and Godot is Y-up, so each row is the brief turned on its side: the fork's height, one and a half, "
         "moves to the middle. Each row also carries the budget and the count Kiran read in Blender.")
    b.append({'beat_id': 'B08', 'act': 'code: the headless check', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': 'Line seven', 'event': 'line 7 highlighted'}, {'at': 'fork', 'event': 'line 9'},
                  {'at': 'budget', 'event': 'line 10'}],
                  'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                      'mode': 'code', 'title': 'The Check: The Brief in Godot’s Axes', 'project': 'Jelly Hop',
                      'path': 'res://tests/test_a3_assets.gd', 'source': 'godot/tests/test_a3_assets.gd',
                      'code': code8, 'startLine': B08[1], 'codeFontSize': 23,
                      'inspectorLabel': 'Source notes — not Inspector values',
                      'notes': [{'label': 'Axes', 'value': 'Blender X, Y, Z → Godot X, Z, Y'},
                                {'label': 'Written by', 'value': 'Claude Code; Kiran read its plan and report'}],
                      'cues': [{'at': 0.0, 'line': 7, 'label': 'expected values from the brief'},
                               {'at': 0.0, 'line': 9, 'label': 'fork: 0.5 wide, 1.5 tall (Y), 0.05 deep'},
                               {'at': 0.0, 'line': 10, 'label': 'budget and Blender count per asset'}],
                      'output': [f'{B08[0]} lines {B08[1]}–{B08[2]} · rev {REV}']}}},
              'cue_phrases': ['Line seven', 'Blender is', 'the budget']})

    n = ("Run headless, numbers only, beside the brief. Every size matches within a millimetre. Triangles: seventy-two, "
         "two sixty-six and thirty-six, all under budget. Each lowest point sits on the floor. Thirty-six checks, zero "
         "failures, exit code zero. Nothing is rendered, so it says nothing about colour or look.")
    b.append(figure('B09', 'result: headless numbers beside the brief', n,
                    'Headless Check Beside the Brief', 'Headless · numbers only · not a render, not a playtest',
                    'images/B09-headless-vs-brief.png', 'evidence/a3-assets-run.log (2026-10-13, 01:46)',
                    'evidence/a3-assets-run.log · TEST-REPORT.md A3.2, A3.4, A3.5, A3.7',
                    [{'label': 'Sizes', 'text': 'within 1 mm'}, {'label': 'Triangles', 'text': '72 · 266 · 36'},
                     {'label': 'Headless', 'text': '36 checks / 0 failures'}, {'label': 'Not shown', 'text': 'colour, look'}],
                    ['Every size', 'Triangles', 'Thirty-six checks', 'Nothing is rendered'],
                    [{'at': 'size', 'event': 'sizes card'}, {'at': 'Triangles', 'event': 'triangles card'},
                     {'at': 'Thirty-six', 'event': 'summary card'}, {'at': 'Nothing', 'event': 'limit card'}],
                    evidence=True))

    n = ("What Kiran checked by eye: sizes in Blender's sidebar, triangles in the status bar, the scene through its "
         "camera, and the undersides with the floor hidden. Still uncertain: with one light and no environment the "
         "shaded sides are pure black; the fork tips were not checked close up; a fresh run of the dome script brings "
         "back Claude's colours; and the placements. Read from the A2 code, the dome sits on the table, not on a "
         "final platform. Kiran has not confirmed that yet.")
    b.append({'beat_id': 'B10', 'act': 'what Kiran checked and what remains uncertain', 'narration_text': n,
              'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': 'checked by eye', 'event': "Kiran's checks on the left"},
                  {'at': 'Still uncertain', 'event': 'uncertain items on the right'}],
                  'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                      'mode': 'trace', 'title': 'Checked by Kiran, and Still Uncertain', 'project': 'Jelly Hop',
                      'source': 'TEST-REPORT.md A3.2–A3.8, A3.12 · CHANGE-BRIEF.md A3 Revision 1 (draft)',
                      'treeLabel': 'Human checks by Kiran, then what is still uncertain',
                      'tree': ['Checked — Blender sidebar: 0.5×0.05×1.5 · 1×1×0.75 · 2×1.5×0.25',
                               'Checked — status bar: Tris 72 · 266 · 36 · scale 1, 1, 1',
                               'Checked — scene camera: all upright, on the floor',
                               'Checked — from below, floor hidden: no obvious holes',
                               'Uncertain — black shaded sides: one light, no environment',
                               'Uncertain — fork tips not checked close up',
                               "Uncertain — a fresh build_dome.py rebuilds Claude's colours",
                               'Uncertain — placements: A2 dome on the table; to confirm'],
                      'inspectorLabel': 'Sources',
                      'notes': [{'label': 'Checks', 'value': 'TEST-REPORT.md A3.2–A3.8'},
                                {'label': 'Uncertain', 'value': 'TEST-REPORT.md A3.12'}],
                      'cues': [{'at': 0.0, 'line': 1, 'label': 'by eye, in Blender and Godot'},
                               {'at': 0.0, 'line': 5, 'label': 'still uncertain'}],
                      'output': ['Placement read from godot/game/session.gd:146–153 by Claude Code; not yet confirmed by Kiran.']}}},
              'cue_phrases': ['checked by eye', 'Still uncertain']})

    n = ("What Claude got wrong. Its dome colours were washed out; Kiran fixed them by hand. Its first plan had the "
         "cherry touching the cover at one point; Kiran had it sunk four centimetres in. It removed an unused material "
         "and set fake users, steps its plan never mentioned, and reported both afterwards. And it flagged its own "
         "cherry test as weak.")
    b.append({'beat_id': 'B11', 'act': 'what Claude got wrong', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': 'got wrong', 'event': 'four items on the left'},
                  {'at': 'Kiran fixed', 'event': "Kiran's responses on the right"}],
                  'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                      'mode': 'trace', 'title': 'What Claude Got Wrong', 'project': 'Jelly Hop',
                      'source': 'TEST-REPORT.md A3.9 · FRICTIONAL.md A3 entries',
                      'treeLabel': 'What Claude Code got wrong → what happened next',
                      'tree': ["Dome colours washed out → Kiran's hand edit",
                               'Cherry touching the cover at one point → Kiran: 0.04 m in',
                               'Removed "Dots Stroke", set fake users: not in its plan → reported after',
                               'Its own cherry test is weak → flagged by Claude itself'],
                      'inspectorLabel': 'Source notes',
                      'notes': [{'label': 'Source', 'value': 'TEST-REPORT.md A3.9'},
                                {'label': 'Cherry top', 'value': 'still 0.75 m'}],
                      'cues': [{'at': 0.0, 'line': 1, 'label': 'colours'}, {'at': 0.0, 'line': 2, 'label': 'cherry'},
                               {'at': 0.0, 'line': 3, 'label': 'beyond the plan'}, {'at': 0.0, 'line': 4, 'label': 'weak test'}],
                      'output': ['Not Claude: the course `claude mcp add` command failed (Claude Code 2.1.288).']}}},
              'cue_phrases': ['dome colours', 'cherry touching', 'removed an unused', 'cherry test']})

    nxt = 'decide where the dome goes, on the table or on a final platform, before these assets enter a level'
    n = ("Verdict. Three assets on brief: sizes, origins, upright, under budget, and thirty-six headless checks with "
         "no failures. Uncertain: the black sides, the fork tips, the dome script's colours and the placements. Kiran "
         "wrote the brief and every number in it, approved each plan and each Blender call, made the hand edit, and did "
         "every human check. Claude Code wrote and ran the Blender code, the Godot scene and the check, and made this "
         "film; Claude chat guided Kiran and organised the notes. One next step, from the open items: "
         f"{nxt}. Shown at revision nine four eight A B six A.")
    b.append({'beat_id': 'BVDT', 'act': 'verdict', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.05', 'event': f"artifact page 'Jelly Hop — three 3D assets at {REV}'"},
                  {'at': '0.1', 'event': 'lines land as the voice names them'}],
                  'remotion': {'pattern': 'ClaudeVerdictArtifact', 'props': {
                      'artifactTitle': 'Verdict', 'artifactHeading': f'Jelly Hop — three 3D assets at {REV}',
                      'brandLabel': '@NikBearBrown',
                      'artifactLines': [
                          'WORKS — sizes, origins, upright, 72/266/36 tris · headless 36 checks / 0 failures',
                          'UNCERTAIN — black shaded sides · fork tips · dome script colours · placements',
                          'CLAUDE GOT WRONG — washed-out dome colours, cherry plan, unplanned steps, weak test',
                          'KIRAN — brief and numbers, every approval, the hand edit, every human check',
                          'CLAUDE CODE — Blender code, Godot scene and check, this film · CLAUDE chat — guidance',
                          'NEXT (from the open items) — decide where the dome goes before a level',
                          f'SOURCE — revision {REV} · Blender 5.2.2 · MCP for Blender 2.1.9 · Godot 4.7.2']}}}})

    prompt = ("Use Walker with the Blender MCP: write one new asset's size, origin and triangle budget into your brief "
              "first, predict one way it could go wrong, ask Claude for a plan before any Blender call, then check it "
              "in Godot with a headless size check and your own eyes, from below too.")
    n = (f"Your turn. {prompt} Predict first, so the check can prove you wrong. And look underneath: that is "
         "where this project still has open questions. Liam, in for Bear.")
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


A2_REASON = ('Assignment 2 slice file, unchanged since 7a48ea8 and explained in the A2 film '
             '(youtube/claude-liam-jelly-hop-gamedev/); outside this A3 film\'s scope.')
COMPONENTS = [
    ('a3-models', 'The three exported glTF assets (fork, dessert dome, biscuit platform) and their import settings.',
     ['B02', 'B04', 'B05', 'B07', 'B09'],
     ['assets/models/fork.glb', 'assets/models/fork.glb.import', 'assets/models/dome.glb', 'assets/models/dome.glb.import',
      'assets/models/platform.glb', 'assets/models/platform.glb.import']),
    ('a3-showcase', 'The 3D showcase scene: three instances, a floor, a 0.5 m jelly reference cube, one light, a camera.',
     ['B06', 'B07'], ['showcase/a3_assets.tscn']),
    ('a3-check', 'The headless asset check: the brief in Godot axes, sizes, scale, orientation, triangles, floor contact.',
     ['B08', 'B09'], ['tests/test_a3_assets.gd']),
    ('a2-placement', 'Where the A2 game places its forks and dome (read for the placement question; not changed).',
     ['B10'], ['project.godot', 'game/main.tscn', 'game/session.gd', 'game/slice_tuning.gd', 'features/fork/fork.gd']),
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
            excl.append({'path': f, 'reason': A2_REASON})
            continue
        role = 'import settings' if f.endswith('.import') else ('asset' if f.startswith('assets/') else 'source')
        records.append({'path': f, 'sha256': sha_file(GAME / f), 'role': role, 'component_ids': cids})
    for cid, files in comp_files.items():
        for f in files:
            if f not in inventory:
                raise SystemExit(f'STOPPED: {f} ({cid}) is not in godot/')
    beats = {x['beat_id']: x for x in sheet['beats']}
    excerpts = [{'beat_id': bid, 'path': rel, 'start_line': a, 'end_line': z, 'text': lines(rel, a, z)}
                for bid, (rel, a, z) in (('B06', B06), ('B08', B08))]
    pairs = [{'code_beat': 'B06', 'result_beat': 'B07',
              'observation': 'The instances at x = -2.5, 0 and 1.5 and the reference cube at 3 appear left to right '
                             'as platform, dome, fork and cube, upright on the floor, in Kiran\'s screenshot 19 of '
                             'Run Current Scene.',
              'media': {'path': 'images/B07-scene-camera.png', 'sha256': sha_file(REEL / 'images/B07-scene-camera.png')}},
             {'code_beat': 'B08', 'result_beat': 'B09',
              'observation': 'The headless run reports sizes 0.5x1.5x0.05, 1.0x0.75x1.0 and 2.0x0.25x1.5, triangles '
                             '72/266/36 and "A3 ASSET CHECKS: 36 checks / 0 failures" (evidence/a3-assets-run.log).',
              'media': {'path': 'images/B09-headless-vs-brief.png', 'sha256': sha_file(REEL / 'images/B09-headless-vs-brief.png')}}]
    for p in pairs:
        assert beats[p['result_beat']]['shot']['evidence_media'] == p['media']['path']
    return {'schema_version': 1, 'teaching_contract': 'code-then-result-v1', 'game_revision': REV,
            'files': records, 'exclusions': excl,
            'components': [{'id': cid, 'explanation': ex, 'beat_ids': bids, 'files': sorted(comp_files[cid])}
                           for cid, ex, bids, _ in COMPONENTS],
            'excerpts': excerpts, 'code_result_pairs': pairs}


def script_md(sheet):
    out = [f'# SCRIPT — {TITLE}', '',
           'Drafted unattended by Claude Code on 2026-10-13, for Kiran\'s review. Narration is what Liam says; '
           '"On screen" is what the viewer sees. Every claim is sourced in FACTCHECK.md.', '']
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
                   f'tools/make_master.py set from the Kokoro narration; the exported film matches it (MEDIA.md).**')
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
        'capture_method': "none (Kiran's own screenshots and the recorded headless log; no new capture)",
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
