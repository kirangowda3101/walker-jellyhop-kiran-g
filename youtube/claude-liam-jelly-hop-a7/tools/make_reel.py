"""Writes beat_sheet.json, gamedev-evidence.json and SCRIPT.md for the Jelly Hop A7 film.

    python3 tools/make_reel.py        (after make_clips.py and make_images.py)

Same pipeline as the A6 film (youtube/claude-liam-jelly-hop-a6/tools/make_reel.py at c1bbb13). Code on screen is read
from the read-only snapshot of revision c1bbb13 by line range (never retyped). Images are embedded as data URIs. The
three footage beats (B11, B13, B17) are the film's own scripted capture (capture/, media/clips.json). Every claim is
sourced in FACTCHECK.md. Written by Claude Code on 2026-11-17 for Kiran's review.
"""
import base64
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

REEL = Path(__file__).resolve().parent.parent
GAME = REEL.parent / 'snapshot-c1bbb13' / 'godot'
TITLE = 'Jelly Hop: Animation Clips'   # Claude Code's choice; for Kiran's review
SLUG = 'claude-liam-jelly-hop-a7'
TOPIC = 'JELLY HOP · ANIMATION'
REV = 'c1bbb13'
REV_FULL = 'c1bbb13f538408f4b6ef608d4d3b4ef5d2b620fa'
WPS = 2.7
REC = 'Godot editor reconstruction, not a screenshot'

EX = {'B03': ('features/player/player_visuals.tscn', 20, 29),
      'B05': ('animations/scoot.tres', 5, 17),
      'B07': ('tests/test_a7_land_readback.gd', 166, 172),
      'B10': ('features/player/player.gd', 200, 212),
      'B12': ('features/player/player.gd', 215, 227),
      'B14': ('features/player/player_visuals.tscn', 61, 67),
      'B16': ('features/player/player.gd', 227, 236),
      'B19': ('animations/land.tres', 8, 19)}


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
    return {'beat_id': bid, 'act': act, 'narration_text': n, 'estimated_duration_s': c['duration_s'], 'capture': 'run-a7',
            'qc': {'full_bleed': True,
                   'full_bleed_reason': 'Godot engine capture (scripted keyboard input, Movie Maker, windowed, native 3840x2160): '
                                        'a 1920x1080 region of the 4K frame enlarged 2x, labelled on every frame. The game '
                                        'draws its wall, plate and table edge to edge, so content crossing the title-safe '
                                        'inset is the game filling the screen, not a card overflowing. The burned-in labels '
                                        'sit inside the title-safe inset.',
                   'contrast_regions': c['label_regions'],
                   'contrast_reason': 'Whole-frame contrast is low because the game is a dim dinner table by design. The essential '
                                      'text is the three burned-in label lines; each line\'s region (its box in every frame) is tested instead.'},
            'shot': {'type': 'VIDEO', 'lane': 'capture', 'source': 'own', 'treatment': 'none',
                     'evidence_media': c['path'], 'labels': labels, 'show': show}}


CAP = 'Scripted capture · real engine frames · Godot Movie Maker, windowed, offline 4K render · rev c1bbb13 · not a human playtest'


def beats():
    clips = json.loads((REEL / 'media/clips.json').read_text())
    b = []
    command = ('Please use Walker to convert my game design document about Jelly Hop, a jelly cube hopping across a '
               'dinner table while forks stab down from above, into two animation clips: a looping scoot cycle from my two '
               'scoot drawings, and a landing squash that commits, both played by one AnimationPlayer on the physics clock.')
    n = ("Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: two animation clips for Jelly Hop, a looping "
         "scoot and a committing landing. This prompt is an illustrative reconstruction. Kiran's real work comes next.")
    b.append({'beat_id': 'B00', 'act': 'cold open — the Walker ask', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'ask', 'show': [
                  {'at': '0.0', 'event': "composer, spark and greeting 'Hej, Liam'"},
                  {'at': '0.2', 'event': 'the Walker prompt (worded from CHANGE-BRIEF.md, A7) types itself'},
                  {'at': '0.75', 'event': 'three output lines; the first labels the prompt a reconstruction'}],
                  'remotion': {'pattern': 'ClaudeComposerAsk', 'props': {
                      'greeting': 'Hej, Liam', 'topic': TOPIC, 'segment': TITLE,
                      'command': command, 'runningText': 'reading CHANGE-BRIEF.md…',
                      'output': ['Illustrative reconstruction of the ask, worded from CHANGE-BRIEF.md (A7). Not a saved transcript.',
                                 'Built: scoot.tres · land.tres · player_visuals.tscn · _update_visuals() · read-back, state and edge tests',
                                 f'Shown at revision {REV} · Godot 4.7.2 · Compatibility renderer'],
                      'folderLabel': '@NikBearBrown'}}}})

    n = ("Scoot loops. Land commits. Both clips tick on the physics clock. And one hand-off ran a tick ahead, until a test "
         "caught it. Here is how both clips were built, timed, tuned and tested.")
    b.append({'beat_id': 'B01', 'act': 'what was built (hesitant writer)', 'narration_text': n, 'lead_silence_s': 0.8,
              'qc': {'sparse_by_design': True, 'sparse_reason': 'BrutalistHesitantWriter types the three-line overview token by token, '
                     'so mid-beat frames are mostly cream by design; the frame is only full once the third line and its '
                     'correction are typed.'},
              'estimated_duration_s': est(n, 0.8, 9.0),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.1', 'event': "'Scoot loops. Land commits.' types out"},
                  {'at': '0.35', 'event': "'Both clips tick on physics.' types out"},
                  {'at': '0.6', 'event': "'One hand-off ran a tick late.' — 'late' turns terracotta"},
                  {'at': '0.8', 'event': "the writer corrects it: 'One hand-off ran a tick ahead.'"}],
                  'remotion': {'pattern': 'BrutalistHesitantWriter', 'props': {
                      'text': 'Scoot loops. Land commits.\nBoth clips tick on physics.\nOne hand-off ran a tick late.',
                      'triggerWords': 'late', 'replacementWords': 'ahead',
                      'face': 'serif', 'fontSize': 100, 'lineSpacing': 1.25, 'align': 'center',
                      'seed': 'jelly-hop-a7-2026', 'mistakeRate': 0, 'hesitateWithin': 0,
                      'hesitateBetween': 3, 'charMs': 26, 'jitter': 15}}}})

    n = ("Jelly Hop is Kiran's game: a jelly cube hops across plates on a dinner table while forks stab down from above. "
         "Assignment seven adds two clips. Scoot is the looping cycle: two cells on a Sprite2D, held by a discrete frame "
         "track, packed from Kiran's assignment-two scoot art, seven ticks per cell, loop linear. Land is the committing "
         "action: two Sprite2D cutouts under Node2D pivots, cut from the idle drawing at row six twenty-two, keyed at "
         "frames zero, two, four and eight, loop none.")
    b.append(figure('B02', 'the game and both clips', n, 'Jelly Hop: Two Animation Clips',
                    "Held frames from the film's scripted capture · real engine frames, cropped",
                    'images/B02-identify.png', 'Left: tick 390, SCOOT-B · right: tick 295, the deepest squash',
                    'CHANGE-BRIEF.md lines 11–12 (routes) · capture/run-a7-inputs.jsonl',
                    [{'label': 'Game', 'text': 'Jelly Hop'}, {'label': 'scoot', 'text': 'Sprite2D frame track · loop'},
                     {'label': 'land', 'text': 'two-piece cutout rig · one-shot'}],
                    ["Jelly Hop is", "Scoot is", "Land is"]))

    # ---------------- Q1: what a clip is
    n = ("First question: what is a clip? Start with what it reads. The scoot sprite shows the sheet, and lines twenty-seven "
         "and twenty-eight slice it: h-frames two, v-frames one. Line twenty-nine starts it on frame zero. And the offset, "
         "minus five twelve, minus eight twelve, keeps each cell's bottom-centre anchor.")
    b.append(code('B03', 'code: the scoot sprite slices the sheet', n, 'Q1 · What a Clip Reads: The Sliced Sheet',
                  [('Written by', 'Claude Code (session 3b), from the brief\'s rig design'),
                   ('Scale', 'line 23: 0.106, as the original pose sprite')],
                  [(27, 'hframes 2'), (28, 'vframes 1'), (29, 'frame 0'), (26, 'anchor (512, 812)')],
                  ['lines twenty-seven', 'v-frames one', 'Line twenty-nine', 'And the offset'], size=28))

    n = ("Here is the sheet: two thousand forty-eight by one thousand twenty-four, Kiran's assignment-two scoot drawings side "
         "by side, with no cropping. Two h-frames make two cells, each a full one-thousand-twenty-four canvas. The packing "
         "tool found zero mismatched pixels in each cell against its source.")
    b.append(figure('B04', 'result: the sheet and its slicing', n, 'CHAR-SCOOT-SHEET.png, Sliced',
                    "Kiran's committed sheet, scaled · divider drawn at hframes 2", 'images/B04-sheet.png',
                    'godot/assets/art/CHAR-SCOOT-SHEET.png · ATTRIBUTION.md line 4',
                    'godot/assets/art/CHAR-SCOOT-SHEET.png, .ATTRIBUTION.md · CHANGE-BRIEF.md line 25',
                    [{'label': 'Size', 'text': '2048 × 1024'}, {'label': 'Cells', 'text': 'A | B, 1024 each'},
                     {'label': 'Packing', 'text': '0 mismatched px'}],
                    ['two thousand forty-eight', 'Two h-frames', 'zero mismatched'], evidence=True))

    n = ("A clip is a saved resource: a length, a loop mode, a step, and tracks. Line eleven names the track's target: a node "
         "path, then a property, frame. Line fifteen keys cell zero at zero and cell one at seven sixtieths of a second. Line "
         "seventeen, update one, is discrete, so each cell holds its full seven ticks. Line six, loop mode one, is loop "
         "linear, over a length of fourteen sixtieths.")
    b.append(code('B05', 'code: scoot.tres, a clip', n, 'Q1 · What a Clip Is: scoot.tres',
                  [('Step', 'line 7: 1/60 s, one physics tick per timeline frame'),
                   ('Written by', 'Claude Code (session 3b) · keys from CHANGE-BRIEF.md line 27')],
                  [(11, 'node path : property'), (15, 'keys at 0 and 7/60 s'), (17, 'update 1 = discrete'),
                   (6, 'loop_mode 1 = LOOP_LINEAR'), (5, 'length 14/60 s')],
                  ['Line eleven', 'Line fifteen', 'Line seventeen', 'Line six', 'fourteen sixtieths'], size=24))

    n = ("The result, as a fixture: Kiran's scoot preview, captured at sixty frames per second. Facing right, frame two "
         "fifty-nine is clip time point one, cell zero. Frame two sixty, at seven sixtieths, is the swap to cell one. Facing "
         "left at the wrap, the clip returns to zero and cell zero. Kiran watched five wraps in play: no pause or jerk.")
    b.append(figure('B06', 'result: the frame track reading the sheet (fixture)', n, 'The Frame Track, Frame by Frame',
                    'Fixture capture · preview scene, not gameplay · Movie Maker, 60 fps', 'images/B06-scoot-strip.png',
                    'captures/scoot/r1/ and scoot.log', 'captures/scoot/r1/ · TEST-REPORT.md A7, HUMAN CHECK rows',
                    [{'label': 'Fixture', 'text': 'preview, not gameplay'}, {'label': 'Swap', 'text': '7/60 → cell 1'},
                     {'label': 'Wrap', 'text': '0 → cell 0'}, {'label': 'Kiran, in play', 'text': 'no pause or jerk'}],
                    ['as a fixture', 'Frame two sixty', 'at the wrap', 'Kiran watched'], evidence=True))

    n = ("Because a track names its target by path, a typo still makes a valid file. So the read-back resolves every track. "
         "Line one sixty-nine calls track problems, a function copied from the course handout. Line one seventy-one prints "
         "each problem, and line one seventy-two fails the check if there is even one.")
    b.append(code('B07', 'code: the track_problems check', n, 'Q1 · Every Track Must Resolve',
                  [('track_problems()', 'line 47 · "From the A7 assignment handout, unchanged"'),
                   ('Written by', 'Claude Code (session 4); run by Kiran')],
                  [(169, 'track_problems(player)'), (171, 'print each problem'), (172, 'fail on any problem')],
                  ['Line one sixty-nine', 'Line one seventy-one', 'line one seventy-two'], size=26))

    n = ("Mutation one, run by Kiran: one letter dropped, so position became p o s i t o n. Godot imported it with exit zero. "
         "The read-back did not pass: track one, upper pivot has no property positon. Ninety-four checks, three failures, "
         "against one hundred thirty-five and zero on the committed clip.")
    b.append(figure('B08', 'result: mutation M1 fails the read-back', n, 'Mutation M1: A Renamed Property',
                    "Kiran's run · evidence/a7-mutations/ · each exited 1", 'images/B08-mutation-m1.png',
                    'M1_diff.txt · fail_lines.txt · M1 land read-back log',
                    'evidence/a7-mutations/M1_* · fail_lines.txt · logs/test_a7_land_readback_60fps.log',
                    [{'label': 'Edit', 'text': 'position → positon'}, {'label': 'Import', 'text': 'exit 0'},
                     {'label': 'Mutated', 'text': '94 checks / 3 failures'}, {'label': 'Committed', 'text': '135 / 0'}],
                    ['one letter dropped', 'Godot imported', 'Ninety-four checks', 'one hundred thirty-five'], evidence=True))

    # ---------------- Q2: one authority
    n = ("Second question: what does one authority mean? Kiran's project file answers with a table: exactly one writer per "
         "animated node and property. The sprite's frame and the three rig transforms belong to the AnimationPlayer alone. "
         "The facing mirror and the visibility flags belong to player dot g d. No tween, no second player, no script "
         "assignment on those targets.")
    b.append(figure('B09', 'one authority: the CLAUDE.md table', n, 'Q2 · One Authority',
                    'Quoted from CLAUDE.md · typeset, not a screenshot', 'images/B09-one-authority.png',
                    'CLAUDE.md lines 67 and 69–78', 'CLAUDE.md, "One authority" · CHANGE-BRIEF.md line 73',
                    [{'label': 'Rule', 'text': 'one writer per property'}, {'label': 'AnimationPlayer', 'text': 'frame · rig transforms'},
                     {'label': 'player.gd', 'text': 'facing · visibility'}, {'label': 'Never', 'text': 'Tween · 2nd player · script'}],
                    ['exactly one writer', 'belong to the AnimationPlayer', 'The facing mirror', 'No tween']))

    n = ("Here are those writes. Line two-oh-one sets the facing pivot's whole transform, its X basis facing plus or minus "
         "one. Lines two-oh-three to two-oh-five set the visibility flags from the wanted clip. Leaving a clip, line "
         "two-oh-nine only calls stop. Nothing here sets the frame or a pivot's scale.")
    b.append(code('B10', 'code: player.gd writes facing and visibility', n, 'Q2 · What player.gd Writes',
                  [('Written by', 'Claude Code (session 5c), appended after line 171'),
                   ('Structure test', 'scans player.gd: only these visual writes (TEST-REPORT.md A7)')],
                  [(201, 'facing mirror ±1'), (203, 'Scoot / LandRig / sprite visible'), (202, 'from the wanted clip'),
                   (209, 'stop(): a playback request')],
                  ['Line two-oh-one', 'Lines two-oh-three', 'from the wanted clip', 'line two-oh-nine'], size=24))

    n = ("Scripted capture, not a playtest. A stationary hop: the landing rig shows for eight ticks, then the original sprite "
         "returns. Then scooting both ways: the facing pivot mirrors, and the cell swaps every seven ticks.")
    b.append(footage('B11', 'result: the state machine plays each clip (scripted capture)', n, clips,
                     [CAP, 'excerpt N of 4 · description · crop note',
                      'from the capture log · tick · pose · clip and clip time · cell · facing · which visual is shown'],
                     [{'at': '0.0s', 'event': 'excerpt 1: stationary hop on plate 1, touchdown tick 293, LAND 293–300, IDLE at 301'},
                      {'at': '1.5s', 'event': 'excerpt 2: 1/16-speed replay of ticks 291–302, every engine frame'},
                      {'at': '3.9s', 'event': 'excerpt 3: scoot left, right, left (ticks 333–465)'},
                      {'at': '6.1s', 'event': 'excerpt 4: 1/16-speed replay of ticks 386–396: swap at 387, wrap at 394'},
                      {'at': '9.8s', 'event': 'labelled held frame of tick 396, 3.0 s'}]))

    n = ("And playback. While the player is disabled, during an Escape pause, line two-nineteen pauses the clip: Revision one's "
         "rule. Line two twenty-two decides an entry: a new clip, a resume, or a fresh touchdown. A steady tick, including A "
         "to B inside scoot, makes no call at all. Line two twenty-seven plays the wanted clip.")
    b.append(code('B12', 'code: player.gd requests playback', n, 'Q2 · Playback Requests Only',
                  [('Pause rule', 'CHANGE-BRIEF.md Revision 1, lines 152–158'),
                   ('Written by', 'Claude Code (session 5c)')],
                  [(219, 'pause() while disabled'), (222, 'entry rule'), (224, 'steady tick: no call'), (227, 'play(want)')],
                  ['line two-nineteen', 'Line two twenty-two', 'A steady tick', 'Line two twenty-seven'], size=24))

    n = ("Three interrupts, each a separate hop with a fresh jump press. Read one tick after touchdown: one LAND frame, then "
         "the crouch. Three ticks in, the hop breaks the held squash. Six ticks in, it breaks the rise. Each hop lands on "
         "its predicted tick.")
    b.append(footage('B13', 'result: an interrupt in each phase (scripted capture)', n, clips,
                     [CAP, 'interrupt N of 3 or its replay · crop note',
                      'from the capture log · tick (relative to touchdown) · pose · clip and clip time · which visual is shown'],
                     [{'at': '0.0s', 'event': 'startup: touchdown 652, press read 653, ANTIC at 653 (+1); replay 1/16 speed'},
                      {'at': '3.8s', 'event': 'active: touchdown 786, press read 789, LAND 786–788, ANTIC at 789 (+3); replay'},
                      {'at': '8.1s', 'event': 'recovery: touchdown 922, press read 928, LAND 922–927, ANTIC at 928 (+6); replay'}]))

    # ---------------- Q3: two clocks
    n = ("Third question: what are the two clocks? The AnimationPlayer has its own. Line sixty-six sets callback mode process "
         "to zero: physics. Line sixty-two roots its track paths at the visuals scene, and line sixty-seven leaves autoplay "
         "empty, so only player dot g d starts a clip. Gameplay runs in physics process too, at sixty ticks a second.")
    b.append(code('B14', 'code: the AnimationPlayer on the physics callback', n, 'Q3 · The Clips\' Clock',
                  [('0', 'PROCESS_PHYSICS, read back by the scoot read-back'),
                   ('Gameplay', 'player.gd line 94: _physics_process, 60 ticks/s')],
                  [(66, 'callback_mode_process = 0: PHYSICS'), (62, 'root_node ..'), (67, 'no autoplay')],
                  ['Line sixty-six', 'Line sixty-two', 'line sixty-seven'], size=30))

    n = ("Same clock, so the expected gap is zero. The first wired run said otherwise. At seven four F E four B five the state "
         "test failed: one hundred thirty-two checks, five failures. On a direct LAND to SCOOT switch, scoot showed one tick "
         "ahead, a sixtieth of a second, with cell one during an A pose. The probe at F D four D eight five five found why: "
         "play on a player already playing gets an extra sixtieth from its own update that tick. Five C zero F B nine A fixed "
         "it. Now the same log lines read zero.")
    b.append(figure('B15', 'result: the one-tick hand-off error, found and fixed', n, 'Q3 · Two Clocks, One Tick Apart',
                    'Lines from Kiran\'s committed files and logs · typeset, not a screenshot', 'images/B15-two-clocks.png',
                    'TEST-REPORT.md A7 · logs/test_a7_visual_state_60fps.log',
                    'commits 74fe4b5, fd4d855, 5c0fb9a · CHANGE-BRIEF.md Revision 2 · TEST-REPORT.md A7, "Two clocks"',
                    [{'label': '74fe4b5', 'text': '132 checks / 5 failures'}, {'label': 'fd4d855', 'text': '+1/60 when playing'},
                     {'label': '5c0fb9a', 'text': 'fix · 132 / 0'}, {'label': 'Now', 'text': 'diff_ticks 0'}],
                    ['seven four F E', 'found why', 'Five C zero', 'Now the same'], evidence=True))

    n = ("The fix is Revision two. Only when the old clip was land, the new one is scoot, and this is not a resume, line two "
         "thirty-two seeks one tick early on the loop. The player's own update then lands it exactly on tick mod fourteen. "
         "Every other entry, at line two thirty-four, seeks the plain synced time.")
    b.append(code('B16', 'code: the Revision 2 hand-off seek', n, 'Q3 · The Hand-off Fix',
                  [('Rule', 'CHANGE-BRIEF.md Revision 2, line 186 · probe H3'),
                   ('Resume', "excluded: the agent's call, accepted; untested (line 188)")],
                  [(228, 'direct LAND → SCOOT only'), (232, 'seek t − 1/60'), (232, 'lands on tick % 14'),
                   (234, 'all other entries')],
                  ['Only when', 'line two thirty-two', 'own update', 'line two thirty-four'], size=24))

    n = ("The hand-off in play. The jelly lands moving, LAND holds for its eight ticks, and SCOOT starts on the next one at "
         "the synced phase.")
    b.append(footage('B17', 'result: the LAND → SCOOT hand-off in play (scripted capture)', n, clips,
                     [CAP, 'excerpt N of 2 · description · crop note',
                      'from the capture log · tick (relative to touchdown) · pose · clip and clip time · cell · which visual is shown'],
                     [{'at': '0.0s', 'event': 'excerpt 1: hop with D pressed 11 ticks before touchdown; touchdown 521'},
                      {'at': '2.2s', 'event': 'excerpt 2: 1/16-speed replay of ticks 519–540: LAND 521–528, SCOOT-B from 529 at 9/60 s'}]))

    # ---------------- Q4: feel in frames
    n = ("Fourth question: how do you design feel in frames? Kiran wrote the phase table first: startup, frames zero and one; "
         "active, two and three; recovery, four to seven, inside the existing eight-tick landing. The keys come straight from "
         "it: zero, two, four and eight sixtieths. Two and four hold the same values, so the squash holds, then eases out.")
    b.append(figure('B18', 'the phase table beside the key times', n, 'Q4 · Feel, Designed in Frames',
                    'Lines read from the files · the timeline is a diagram, not a capture', 'images/B18-phase-table.png',
                    'CHANGE-BRIEF.md lines 33–37 · land.tres lines 15–18',
                    'CHANGE-BRIEF.md "Landing reference and phase table", "Rig design" · godot/animations/land.tres',
                    [{'label': 'Startup', 'text': 'frames 0–1'}, {'label': 'Active', 'text': 'frames 2–3'},
                     {'label': 'Recovery', 'text': 'frames 4–7'}, {'label': 'Keys', 'text': '0 · 2 · 4 · 8'}],
                    ['startup, frames', 'active, two', 'recovery, four', 'The keys']))

    n = ("This is track zero, the lower piece's scale. Line fifteen holds the key times, line sixteen the transitions: two, "
         "one, and a half. Line eighteen is where Revision three landed. After Kiran's r zero verdict, the lower height at "
         "frames two and four went from point six to point five five, a squash about forty-three game pixels tall.")
    b.append(code('B19', 'code: land.tres track 0, Revision 3', n, 'Q4 · The r1 Change in land.tres',
                  [('Seam rule', 'UpperPivot y = −20.14 × lower height: −11.077 at frames 2 and 4 (line 30)'),
                   ('Edit', 'Claude Code (session 7b), chosen by Kiran · CHANGE-BRIEF.md Revision 3')],
                  [(15, 'key times 0, 2, 4, 8 / 60'), (16, 'transitions 2, 1, 0.5'), (18, '0.55 at frames 2 and 4 (r1)')],
                  ['Line fifteen', 'line sixteen', 'Line eighteen'], size=24))

    n = ("The result, as fixtures: Kiran's land preview strips, r zero above and r one below, one frame per phase boundary at "
         "thirty frames per second. Fall, impact, the deepest squash, the same squash at frame four, the eased rise, and the "
         "idle hand-off. Kiran's r zero verdict: smooth at normal speed, but the hold was easier to see frame by frame.")
    b.append(figure('B20', 'result: strips r0 and r1 at each phase boundary (fixtures)', n, 'Land Strips r0 and r1',
                    'Fixture captures · preview scene, not gameplay · Movie Maker, 30 fps', 'images/B20-land-strips.png',
                    'captures/land/r0, r1/clean/ · TUNING.md, "A7 — landing, r0"',
                    'captures/land/r0/, r1/ and their logs · TUNING.md',
                    [{'label': 'Fixture', 'text': 'land_preview, 30 fps'}, {'label': 'Boundaries', 'text': 'FALL · 0 · 2 · 4 · 6 · IDLE'},
                     {'label': 'Kiran, r0', 'text': 'smooth; hold easier frame by frame'}],
                    ['as fixtures', 'Fall, impact', "Kiran's r zero verdict"], evidence=True))

    n = ("Claude predicted r one would be about one game pixel flatter at rig frames two and four, and would look almost the "
         "same. Kiran's verdict came first: barely different at normal speed, but in Preview r one looked slightly flatter, "
         "held across both frames. Claude's comparison, afterwards, could not confirm a visible difference at frames two and "
         "four within its plus or minus two pixel estimate. Kiran overruled that reading and kept r one.")
    b.append(figure('B21', 'the r1 reading Kiran overruled', n, 'r1: The Reading Kiran Overruled',
                    'Fixture captures · Claude\'s prediction and comparison · Kiran\'s verdict, quoted', 'images/B21-r1-reading.png',
                    'TUNING.md, A7 landing r1 (prediction, verdict, comparison)',
                    'TUNING.md · TEST-REPORT.md A7, "Claude against Kiran"',
                    [{'label': 'Predicted', 'text': '≈1 px flatter'}, {'label': 'Kiran', 'text': 'flatter in Preview'},
                     {'label': 'Claude', 'text': 'not confirmable ±2 px'}, {'label': 'Kept', 'text': 'r1'}],
                    ['Claude predicted', "Kiran's verdict came first", "Claude's comparison", 'Kiran overruled']))

    # ---------------- tests
    n = ("What the read-backs proved: land, one hundred thirty-five checks, and scoot, sixty-two, with no failures. Nodes, "
         "slices, track paths, update modes, key times and easing, all read back from the saved files. The structure test, "
         "twenty-nine. The per-tick state test, one hundred thirty-two at thirty, sixty and one forty-four frames per second. "
         "The edge test, three hundred ninety-seven at each rate: all twelve interrupt predictions matched.")
    b.append(figure('B22', 'what the tests proved', n, 'What the Tests Proved',
                    'Logs of the committed runs · headless · numbers only, not a render', 'images/B22-tests.png',
                    'logs/test_a7_*.log · TEST-REPORT.md A7', 'logs/test_a7_* · TEST-REPORT.md A7, "Read-back", "State machine", "Edges"',
                    [{'label': 'Read-backs', 'text': '135 / 0 · 62 / 0'}, {'label': 'Structure', 'text': '29 / 0'},
                     {'label': 'State', 'text': '132 / 0 at 30 · 60 · 144'}, {'label': 'Edges', 'text': '397 / 0 at 30 · 60 · 144'}],
                    ['What the read-backs', 'The structure test', 'per-tick state test', 'The edge test']))

    n = ("Four mutations, each in a throwaway worktree, run by Kiran. Mutation one, the renamed property, failed the land "
         "read-back. Mutation two, scoot looping switched off, failed the scoot read-back. Mutation three, a key on a cell "
         "that does not exist, failed it too. Mutation four changed nothing and imported from an empty cache: both read-backs "
         "passed, because this native rig saves its loop modes in the clips themselves.")
    b.append(figure('B23', 'the four mutations', n, 'Four Mutations',
                    "Kiran's run of sessions/a7/mutations.sh · evidence/a7-mutations/", 'images/B23-mutations.png',
                    'evidence/a7-mutations/summary.txt', 'evidence/a7-mutations/ · TEST-REPORT.md A7, "Mutations", "Fresh cache (M4)"',
                    [{'label': 'M1', 'text': '94 / 3 · CONFIRMED'}, {'label': 'M2', 'text': '62 / 1 · CONFIRMED'},
                     {'label': 'M3', 'text': '62 / 2 · CONFIRMED'}, {'label': 'M4', 'text': '135 / 0 · 62 / 0'}],
                    ['Mutation one', 'Mutation two', 'Mutation three', 'Mutation four']))

    n = ("And what no headless run can show. The tests say so in their own headers: nothing is drawn. So a headless pass "
         "cannot show the seam between the two pieces, whether the feet stay planted, a pop at the idle hand-off, how the "
         "hold feels at normal speed, or the contrast on the darkest and lightest backgrounds. Those took Kiran's eyes, in "
         "the running game.")
    b.append(trace('B24', 'what no headless run can show', n, 'What No Headless Run Can Show',
                   'tests/test_a7_visual_state.gd line 5 · test_a7_edges.gd line 7 · CHANGE-BRIEF.md line 113',
                   'Outside any headless test',
                   ['pixels: "Headless: nothing is drawn" (test headers)',
                    'the seam where the two pieces meet',
                    'feet planted at the swap, the wrap and the landing',
                    'a pop at the IDLE hand-off',
                    'how the hold feels at normal speed',
                    'contrast on the darkest and lightest backgrounds'],
                   [('Kiran, in play', '"I could clearly see the scoot pose changes and the landing squash in both areas."'),
                    ('Source', 'TEST-REPORT.md A7, HUMAN CHECK rows (2026-11-17)')],
                   [(1, 'nothing is drawn'), (2, 'seam'), (3, 'feet'), (4, 'hand-off'), (5, 'feel'), (6, 'contrast')],
                   ['nothing is drawn', 'the seam', 'feet stay planted', 'a pop', 'how the hold feels', 'the contrast'],
                   ['Checked by Kiran in the running game, not by a test.']))

    n = ("The agent mistakes Kiran caught. The CLAUDE dot m d draft said the test wrapper had never been edited, and lacked "
         "the A six shader clause; Kiran corrected one and restored the other. The agent expected ten baseline-only pin "
         "checks; there were nine. Read-only shell commands ran despite a wrapper-only scope. The read-backs logged "
         "formatting errors the wrapper missed. The wired visuals left scoot a tick ahead. And in chat, a pixel scan put the "
         "cut on the smile, at row six-oh-one.")
    b.append(trace('B25', 'agent mistakes Kiran caught', n, 'What the Agents Got Wrong',
                   'FRICTIONAL.md A7 notes 3, 5, 6, 8 and entry 12 · SOURCES.md A7',
                   'AI mistake → what Kiran did',
                   ['CLAUDE.md draft: "wrapper never edited", A6 shader clause missing → corrected, restored (ffac0d8)',
                    'Pins: agent expected 10 baseline-only checks → Kiran\'s run showed 9 (fe9a1f0)',
                    'cat / ls / head / grep despite the wrapper-only scope → disclosed (73eba42, 1bf1133)',
                    '%.3e formatting errors the wrapper scan missed → fixed; Kiran re-ran and searched the logs',
                    'Wiring: SCOOT one tick ahead after LAND → SCOOT (74fe4b5) → probe fd4d855, fix 5c0fb9a',
                    'Chat: pixel scan put the band start at row 601, the smile → Kiran chose row 622'],
                   [('Chat, also', 'a log copy without cp -p · an edit count of 18 that was 16 · a zsh array bug'),
                    ('Who', 'rows 1–5 Claude Code; row 6 and the line above Claude in chat (SOURCES.md A7)')],
                   [(1, 'the CLAUDE.md draft'), (2, '10 vs 9'), (3, 'scope'), (4, 'formatting'), (5, 'a tick ahead'), (6, 'row 601')],
                   ['CLAUDE dot m d draft', 'expected ten', 'Read-only shell', 'formatting errors', 'a tick ahead', 'pixel scan'],
                   ['Every correction is Kiran\'s; sources in FRICTIONAL.md A7 and SOURCES.md A7.']))

    n = ("Still uncertain. Kiran's project file lists unconfirmed items written before the build. Later runs close some of "
         "them, but no realtime run of the suites is recorded, one named check runner was never read, and the A six open items "
         "were not rechecked. Pausing during LAND and resuming straight into SCOOT is untested. The fourteen baseline runs "
         "were not repeated after r one. And Kiran's reference capture held five hundred sixteen PNGs where Godot reported "
         "three hundred fifty-six: still unexplained.")
    b.append(trace('B26', 'what remains uncertain', n, 'Still Uncertain',
                   'CLAUDE.md, Unconfirmed (lines 96–107) · TEST-REPORT.md A7 · FRICTIONAL.md A7, note 2',
                   'Unresolved (Kiran\'s lists)',
                   ['no realtime run of the A7 suites is recorded (CLAUDE.md line 105)',
                    'tools/run_slice_checks.sh not read (line 106) · A6 open items not rechecked (line 107)',
                    'untested: pause during LAND, then SCOOT on the first enabled tick (Revision 2)',
                    'not re-run after r1 (9ada865): the 14 baseline runs',
                    'landing-r0: 516 PNGs in the folder, 356 reported by Godot · unexplained'],
                   [('Written before the build', 'API names, pins, the saved library and float32 keys were later covered: '
                                                 'ClassDB checks, fe9a1f0, M4, KEYTIME (TEST-REPORT.md A7)'),
                    ('Also open', 'capture_poses.gd output after wiring: unobserved')],
                   [(1, 'realtime'), (2, 'check runner'), (3, 'pause → SCOOT'), (4, 'baseline after r1'), (5, '516 vs 356')],
                   ['no realtime run', 'one named check runner', 'Pausing during LAND', 'fourteen baseline runs',
                    'five hundred sixteen'],
                   ['None of these is claimed as solved in this film.']))

    nxt = "I'd add a scripted test for pausing during LAND and resuming into SCOOT, the one entry no test covers yet."
    n = ("Verdict. Both clips play as the brief says: scoot synced to the player's tick, land from frame zero, every interrupt "
         "on its predicted tick, and zero ticks between the two clocks after the fix, with no failures in one thirty-five, "
         "sixty-two, twenty-nine, one thirty-two and three ninety-seven checks. Kiran wrote the brief and its three revisions, "
         "measured the landing and chose the cut, ran the sheet tool, the read-backs, the mutations and both strips, and made "
         "every verdict. Claude Code wrote the clips, the scene, the visual layer, the tests, the previews and the scripts, and "
         "made this film; Claude in chat drafted commands and prompts. The sheet is Kiran's own assignment-two art, made "
         "locally with Stable Diffusion XL Base one point oh, under the CreativeML Open RAIL plus plus M licence. Kiran's next "
         f"step, in Kiran's words: {nxt} Shown at revision C one B B B one three.")
    b.append({'beat_id': 'BVDT', 'act': 'verdict', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.05', 'event': f"artifact page 'Jelly Hop — animation clips at {REV}'"},
                  {'at': '0.1', 'event': 'lines land as the voice names them'}],
                  'remotion': {'pattern': 'ClaudeVerdictArtifact', 'props': {
                      'artifactTitle': 'Verdict', 'artifactHeading': f'Jelly Hop — animation clips at {REV}',
                      'brandLabel': '@NikBearBrown',
                      'artifactLines': [
                          'WORKS — scoot at tick % 14 · land from 0 · 12 interrupts as predicted · 0-tick clock gap after 5c0fb9a',
                          'TESTS — read-backs 135/0, 62/0 · structure 29/0 · state 132/0, edges 397/0 at 30/60/144 · M1–M3 failed, M4 passed',
                          'KIRAN — brief + Revisions 1–3, landing-r0, the y 622 cut, sheet tool, read-backs, mutations, strips, every verdict',
                          'CLAUDE CODE — clips, scene, _update_visuals(), tests, previews, scripts, this film · CHAT — commands, prompts',
                          "SHEET — Kiran's A2 art, SDXL Base 1.0 (local) · CreativeML Open RAIL++-M · CHAR-SCOOT-SHEET.ATTRIBUTION.md",
                          'NEXT (Kiran) — a scripted test for pausing during LAND and resuming into SCOOT',
                          f'SOURCE — revision {REV} · Godot 4.7.2 · Compatibility renderer']}}}})

    prompt = ("Use Walker: before keying a committing action, write its phase table in frames, key it from that table, then "
              "interrupt it once in every phase with real key presses and log the pose and clip time on every tick.")
    n = (f"Your turn. {prompt} Writing the frames first is what let Kiran see the hold in a strip, and logging every tick is "
         "what caught one tick between two clocks that were supposed to agree. Try it on your own clip. Liam, in for Bear.")
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


EXCL = ('File from Assignments 2–6, not changed by A7 (git diff a6..c1bbb13 -- godot) and outside this A7 film\'s scope; '
        'explained in the earlier films.')
COMPONENTS = [
    ('a7-scoot', 'The scoot clip: the two-cell sheet packed from Kiran\'s A2 CHAR-SCOOT-A/B art (with its import settings, '
     'attribution and packing tool), scoot.tres (one discrete frame track, LOOP_LINEAR) and the scoot preview fixture.',
     ['B02', 'B04', 'B05', 'B06'],
     ['assets/art/CHAR-SCOOT-SHEET.png', 'assets/art/CHAR-SCOOT-SHEET.png.import', 'assets/art/CHAR-SCOOT-SHEET.ATTRIBUTION.md',
      'assets/art/CHAR-SCOOT-A.png', 'assets/art/CHAR-SCOOT-B.png', 'animations/scoot.tres', 'tools/make_scoot_sheet.gd',
      'previews/scoot_preview.tscn', 'previews/scoot_preview.gd']),
    ('a7-land', 'The land clip: land.tres (three continuous rig tracks, keys at 0, 2, 4 and 8 frames, LOOP_NONE), the '
     'CHAR-IDLE.png drawing the two slices are cut from, and the land preview fixture used for strips r0 and r1.',
     ['B02', 'B18', 'B19', 'B20', 'B21'],
     ['animations/land.tres', 'assets/art/CHAR-IDLE.png', 'previews/land_preview.tscn', 'previews/land_preview.gd']),
    ('a7-visuals-scene', 'player_visuals.tscn: the scoot sprite slicing the sheet, the two-piece rig, and one AnimationPlayer '
     'on the physics callback with one embedded library.', ['B03', 'B14', 'B15'], ['features/player/player_visuals.tscn']),
    ('a7-state-machine', "player.gd's appended visual layer (_update_visuals, _clip_time): pose to clip, facing and visibility "
     'writes, playback requests, the pause rule and the Revision 2 hand-off seek.',
     ['B10', 'B11', 'B12', 'B13', 'B16', 'B17'], ['features/player/player.gd']),
    ('a7-tests', 'The A7 read-backs, pins, structure, per-tick state and edge tests, and the supplemental entry-order probe.',
     ['B07', 'B08', 'B15', 'B22', 'B23', 'B24'],
     ['tests/test_a7_land_readback.gd', 'tests/test_a7_scoot_readback.gd', 'tests/test_a7_visual_structure.gd',
      'tests/test_a7_visual_state.gd', 'tests/test_a7_edges.gd', 'tests/test_a7_pins.gd', 'tests/probe_a7_entry_order.gd']),
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
        role = 'scene' if f.endswith('.tscn') else ('asset' if f.endswith('.png') else
                                                    ('resource' if f.endswith('.tres') else 'source'))
        records.append({'path': f, 'sha256': sha_file(GAME / f), 'role': role, 'component_ids': cids})
    for cid, files in comp_files.items():
        for f in files:
            if f not in inventory:
                raise SystemExit(f'STOPPED: {f} ({cid}) is not in godot/')
    beats = {x['beat_id']: x for x in sheet['beats']}
    excerpts = [{'beat_id': bid, 'path': rel, 'start_line': a, 'end_line': z, 'text': lines(rel, a, z)}
                for bid, (rel, a, z) in EX.items()]
    obs = {'B04': "Kiran's committed CHAR-SCOOT-SHEET.png, 2048 × 1024, divided at x 1024 (hframes 2, vframes 1): cell 0 "
                  "is CHAR-SCOOT-A, cell 1 CHAR-SCOOT-B; the packing tool's 0-mismatch result is quoted from ATTRIBUTION.md.",
           'B06': 'Scoot fixture strip r1: facing right, frame 259 clip t=0.1 cell 0, frame 260 t=0.116667 cell 1 (the swap), '
                  'frame 261 cell 1; facing left at wrap 1, frame 322 t=0.216667 cell 1, frame 323 t=0 cell 0 (scoot.log).',
           'B08': 'M1 diff renames UpperPivot:position to positon; the mutated land read-back prints the track problem and '
                  'ends 94 checks / 3 failures; the committed log ends 135 checks / 0 failures.',
           'B11': 'In the scripted capture, the stationary hop lands at tick 293; the rig is the only visible visual with clip '
                  'land at (8 − land_ticks)/60 on ticks 293–300 and the original sprite from 301; scooting shows the scoot '
                  'sprite with the cell swapping at tick % 14 = 7 and the facing mirrored when the direction changes.',
           'B13': 'In the scripted capture, jump presses read at touchdown +1, +3 and +6 (touchdowns 652, 786, 922) give ANTIC '
                  'on ticks 653, 789 and 928, with LAND and the rig on every earlier tick from touchdown; 859 per-tick checks, '
                  '0 failures over the take.',
           'B15': 'Lines quoted in TEST-REPORT.md from the 74fe4b5 state-test log show diff_ticks=1.000000 after the LAND → '
                  'SCOOT switch; lines 4468–4469 of the committed 60 fps log show diff_ticks 0 and cell 0 on both SCOOT-A ticks.',
           'B17': 'In the scripted capture the jelly lands moving at tick 521; LAND on 521–528, SCOOT-B from 529 with clip scoot '
                  'at (tick % 14)/60 = 9/60 s, cell 1; every SCOOT tick matched the synced time within 1e-6 s.',
           'B20': 'Land fixture strips r0 (frames 104–109) and r1 (145–150): FALL, rig 0, rig 2, rig 4, rig 6 and the IDLE '
                  "hand-off at tick 8; Kiran's r0 verdict quoted from TUNING.md."}
    pairs = []
    for code_b, result_b in (('B03', 'B04'), ('B05', 'B06'), ('B07', 'B08'), ('B10', 'B11'), ('B12', 'B13'),
                             ('B14', 'B15'), ('B16', 'B17'), ('B19', 'B20')):
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
           'Drafted by Claude Code on 2026-11-17, for Kiran\'s review. Narration is what Liam says; "On screen" is what the '
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
                   f'tools/make_master.py set from the Kokoro narration and the three clip lengths.**')
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
                           f'git-archive copy of {REV}; plus Kiran\'s committed fixture strips and logs'),
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
