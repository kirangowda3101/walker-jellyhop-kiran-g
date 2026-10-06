"""Writes beat_sheet.json, gamedev-evidence.json and SCRIPT.md for the Jelly Hop film.

    python3 tools/make_reel.py        (run from the reel folder, after make_images.py and make_clips.py)

Code shown on screen is read from the repository's own files by line range (never retyped), and
every file hash is computed here, so the godot-gamedev checker can compare them. Images are
embedded in Remotion props as data URIs (the toolkit's public/ folder is not edited).
Narration is the draft for Kiran's script review; durations are estimates until Kokoro measures
them. Beat B09 is a placeholder until the course answers how slice audio should be included.
"""
import base64
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

REEL = Path(__file__).resolve().parent.parent
GAME = REEL.parent.parent / 'godot'
TITLE = 'Jelly Hop: Fork From Above'
SLUG = 'claude-liam-jelly-hop-gamedev'
REV = '7a48ea8'
NEXT_STEP = ('a second level that introduces new fork rhythms gradually, then combines them into more '
             'challenging timing decisions')   # Kiran's words, script review 2026-10-03
WPS = 2.7   # rough Kokoro am_onyx speaking rate, for estimates only


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


CAPTURE_NOTE = 'Scripted-input capture · Godot Movie Maker (offline render) · rev 7a48ea8 · not a human playtest'
B05 = ('features/player/player.gd', 149, 162)   # every branch the narration names; the panel holds 14 lines at the minimum code size
B07 = ('game/session.gd', 294, 301)   # the lines the narration points at; 292-304 overflowed with wrapped comments



def footage_qc(regions):
    return {'full_bleed': True,
            'full_bleed_reason': ('Unmodified Godot engine capture at 3840x2160 (scripted input). The game draws its wall, '
                                  'table and curtain edge to edge, so content crossing the title-safe inset is the game '
                                  'filling the screen, not a card overflowing. Nothing was cropped, scaled or moved. The '
                                  'burned-in labels themselves sit inside the title-safe inset (x >= 200, y 120-2028 of 2160).'),
            'contrast_regions': regions,
            'contrast_reason': ('Whole-frame contrast is low because the game is a dim dinner table by design (art direction '
                                '"Bright jelly, dim table", FRICTIONAL.md 2026-10-01). The essential text in these beats is the burned-in labels; '
                                'each label region is tested here instead.')}

def beats():
    clips = json.loads((REEL / 'media/clips.json').read_text())
    b = []

    command = ('Please use Walker to convert my game design document about a small jelly cube left on a dinner '
               'table after a party, hopping across plates to reach a glass dessert dome, while giant forks strike '
               'from above and a growing shadow warns the player before each strike, into a playable Godot slice.')
    n = ("Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: a jelly cube hopping across dinner "
         "plates toward a dessert dome while giant forks strike from above, as a playable Godot slice. The prompt "
         "is an illustrative reconstruction. Everything after it is the real project.")
    b.append({'beat_id': 'B00', 'act': 'cold open — the Walker ask', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'ask', 'show': [
                  {'at': '0.0', 'event': "composer, spark and greeting 'Hej, Liam'"},
                  {'at': '0.2', 'event': 'the Walker prompt (wording from CONCEPT.md) types itself'},
                  {'at': '0.6', 'event': "running indicator: 'reading CONCEPT.md…'"},
                  {'at': '0.75', 'event': 'three output lines; the first labels the prompt a reconstruction'}],
                  'remotion': {'pattern': 'ClaudeComposerAsk', 'props': {
                      'greeting': 'Hej, Liam', 'topic': 'JELLY HOP · GODOT DEVELOPMENT', 'segment': TITLE,
                      'command': command, 'runningText': 'reading CONCEPT.md…',
                      'output': ['Illustrative reconstruction of the ask, worded from CONCEPT.md. Not a saved transcript.',
                                 'Built: one level · six plates · five forks · three sauce gaps · a glass dome.',
                                 'Shown at revision 7a48ea8 · Godot 4.7.2'],
                      'folderLabel': '@NikBearBrown'}}}})

    n = ("One level: six plates, five forks, a glass dome at the end. The shadow gives the warning; the scrape "
         "plays as the fork starts descending. That last line came from a playtest, not the design.")
    b.append({'beat_id': 'B01', 'act': 'what was built (hesitant writer)', 'narration_text': n, 'lead_silence_s': 0.8,
              'qc': {'sparse_by_design': True, 'sparse_reason': 'BrutalistHesitantWriter types the three-line overview token by token, '
                     'so mid-beat frames are mostly cream by design; the frame is only full once the third line and its '
                     'correction are typed. Type raised from 80 to 100.'},
              'estimated_duration_s': est(n, 0.8, 9.0),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.1', 'event': "'A jelly cube crosses six plates.' types out"},
                  {'at': '0.35', 'event': "'The shadow gives the warning.' types out"},
                  {'at': '0.6', 'event': "'The scrape plays as shadows grow.' — 'shadows', then 'grow', turn terracotta"},
                  {'at': '0.8', 'event': "the writer corrects them to 'forks' and 'descend': 'The scrape plays as forks descend.'"}],
                  'remotion': {'pattern': 'BrutalistHesitantWriter', 'props': {
                      'text': 'A jelly cube crosses six plates.\nThe shadow gives the warning.\nThe scrape plays as shadows grow.',
                      # the component matches single words, so the two unique words are corrected in place
                      'triggerWords': 'shadows, grow', 'replacementWords': 'forks, descend',
                      'face': 'serif', 'fontSize': 100, 'lineSpacing': 1.25, 'align': 'center',
                      'seed': 'jelly-hop-gamedev-2026', 'mistakeRate': 0, 'hesitateWithin': 0,
                      'hesitateBetween': 3, 'charMs': 26, 'jitter': 15}}}})   # only the two meaningful corrections; they must land before the cut

    n = ("A jelly cube left on the table after a party; the dome is safety. Four pillars. Read the shadow, then "
         "commit. Wobbly and alive. Small in a giant world. Every splat teaches: a hit costs about a second and a "
         "quarter, then you're back on the last plate you landed on. A held frame from the intro pan.")
    b.append({'beat_id': 'B02', 'act': 'concept and pillars', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': '0.0', 'event': 'held frame of the intro pan: title, frozen forks, plates, sauce'},
                  {'at': 'Read the shadow', 'event': 'pillar card 1 lights'},
                  {'at': 'Wobbly and alive', 'event': 'pillar card 2 lights'},
                  {'at': 'Small in a giant world', 'event': 'pillar card 3 lights'},
                  {'at': 'Every splat teaches', 'event': 'pillar card 4 lights'}],
                  'remotion': {'pattern': 'GodotDesignFigure', 'props': {
                      'title': 'The Game and Its Four Pillars',
                      'status': 'Held frame · run-01, tick 90 · intro pan · cropped above the curtain',
                      'image': data_uri('images/B02-intro-held-frame.png'),
                      'imageLabel': CAPTURE_NOTE,
                      'excerpt': 'A small jelly cube hops across plates to a glass dome; giant forks strike from above.',
                      'source': 'CONCEPT.md v1 · design pillars · capture run-01',
                      'cards': [{'label': 'Read the shadow', 'text': 'then commit'},
                                {'label': 'Wobbly and alive', 'text': 'squash, worry, relief'},
                                {'label': 'Small, giant world', 'text': 'huge plates and forks'},
                                {'label': 'Every splat teaches', 'text': 'quick respawn'}],
                      'cues': [{'at': 5.0, 'card': 0}, {'at': 7.0, 'card': 1}, {'at': 8.5, 'card': 2}, {'at': 10.0, 'card': 3}]}}},
              'cue_phrases': ['Read the shadow', 'Wobbly and alive', 'Small in a giant', 'Every splat teaches']})

    n = ("One asset, start to finish: the jelly. The design: the character sheet's front view, as a guide on flat "
         "magenta. The prompt, run locally: SDXL Base one point oh, image to image at sixty percent. On the right, "
         "the raw output, untouched. A text-only try had grown legs and a tongue; the guide kept the cube.")
    b.append({'beat_id': 'B03', 'act': 'asset trace 1: design → prompt → raw output', 'narration_text': n,
              'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': '0.1', 'event': 'design guide panel'}, {'at': '0.35', 'event': 'prompt and settings panel'},
                  {'at': '0.65', 'event': "raw output panel, labeled 'not in-engine', 'unedited'"}],
                  'remotion': {'pattern': 'GodotDesignFigure', 'props': {
                      'title': 'One Asset: Design → Prompt → Raw',
                      'status': 'Raw generation · not in-engine footage',
                      'image': data_uri('images/B03-design-prompt-raw.png'),
                      'imageLabel': 'CHARACTER-SHEET front view → ASSET-LOG.md prompt → SDXL raw output',
                      'source': 'ASSET-LOG.md (CHAR-REF) · gen-inputs/char-ref-guide.png · raw file SHA-256 2c0f71a7…',
                      'cards': [{'label': 'Model', 'text': 'SDXL Base 1.0, local'},
                                {'label': 'Mode', 'text': 'image to image, 60%'},
                                {'label': 'Rejected', 'text': 'text-only: legs, tongue'}],
                      'cues': [{'at': 4.0, 'card': 0}, {'at': 9.0, 'card': 1}, {'at': 17.0, 'card': 2}]}}},
              'cue_phrases': ['SDXL Base', 'image to image', 'text-only try']})

    n = ("Two stray dots came with it. A logged script filled nineteen hundred and fifty-four pixels in two boxes, "
         "nothing outside them. The magenta was cut out, the file copied into the project byte for byte, and "
         "player dot g d, line fifty-four, loads it by name. Last panel: the same jelly in the 4K capture.")
    b.append({'beat_id': 'B04', 'act': 'asset trace 2: edits → game file → engine', 'narration_text': n,
              'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': '0.05', 'event': 'raw zoom with the two speck boxes'},
                  {'at': '0.3', 'event': 'after speck removal'},
                  {'at': '0.5', 'event': 'magenta cut-out on a checkerboard'},
                  {'at': '0.8', 'event': 'in-engine crop from run-01'}],
                  'remotion': {'pattern': 'GodotDesignFigure', 'props': {
                      'title': 'Edits → Game File → Engine',
                      'status': 'Panels a–c: files · panel d: 4K capture crop',
                      'image': data_uri('images/B04-edits-to-engine.png'),
                      'imageLabel': 'ASSET-LOG.md · tools/remove_specks.py · tools/process_env.py · tools/copy_game_art.sh',
                      'source': 'art/reference/CHAR-REF.png → art/game/CHAR-IDLE.png → godot/assets/art/CHAR-IDLE.png · player.gd:54',
                      'cards': [{'label': 'Edit', 'text': '1,954 px in 2 boxes'},
                                {'label': 'Cut-out', 'text': 'magenta removed'},
                                {'label': 'Copy', 'text': 'byte-identical'},
                                {'label': 'Load', 'text': 'player.gd line 54'}],
                      'cues': [{'at': 2.0, 'card': 0}, {'at': 8.0, 'card': 1}, {'at': 10.0, 'card': 2}, {'at': 14.0, 'card': 3}]}}},
              'cue_phrases': ['A logged script', 'The magenta', 'byte for byte', 'line fifty-four']})

    code5 = lines(*B05)
    n = ("Twelve poses, one function, and the order is the design. The session's override wins first: splat, "
         "respawn, celebrate. In the air, a crouch for the first few ticks, then rise or fall by the sign of vertical "
         "speed. Then the landing squash, the scoot while moving, worry while this plate's shadow grows, and bored "
         "after four seconds without input.")
    b.append({'beat_id': 'B05', 'act': 'code: choose_pose()', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': 'override wins first', 'event': 'line 149 highlighted'},
                  {'at': 'In the air', 'event': 'lines 151-153 highlighted'},
                  {'at': 'landing squash', 'event': 'line 155'}, {'at': 'scoot', 'event': 'line 157'},
                  {'at': 'worry', 'event': 'line 159'}, {'at': 'bored', 'event': 'line 161'}],
                  'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                      'mode': 'code', 'title': 'choose_pose(): One Function Picks the Pose', 'project': 'Jelly Hop',
                      'path': 'res://features/player/player.gd', 'source': 'godot/features/player/player.gd',
                      'code': code5, 'startLine': B05[1], 'codeFontSize': 23,
                      'inspectorLabel': 'Source notes — not Inspector values',
                      'notes': [{'label': 'Order is priority', 'value': 'the first true test wins'},
                                {'label': 'Set by session.gd', 'value': '390 worried · 391 override'}],
                      'cues': [{'at': 3.5, 'line': 149, 'label': 'session override first'},
                               {'at': 6.5, 'line': 151, 'label': 'airborne: crouch, then rise or fall'},
                               {'at': 11.0, 'line': 155, 'label': 'landing squash'},
                               {'at': 12.5, 'line': 157, 'label': 'scoot while moving'},
                               {'at': 14.0, 'line': 159, 'label': 'worry under a growing shadow'},
                               {'at': 16.0, 'line': 161, 'label': 'bored after 4 s without input'}],
                      'output': [f'{B05[0]} lines {B05[1]}–{B05[2]} · rev {REV}']}}},
              'cue_phrases': ['override wins first', 'In the air', 'landing squash', 'scoot', 'worry', 'bored']})

    c6 = clips['B06']
    n = ("Watch the label at the bottom. Scoot, crouch, rise, fall, land. On plate two it waits under the shadow, "
         "worried. The fork lands: splat. It re-forms on the same plate, then hops on.")
    b.append({'beat_id': 'B06', 'act': 'result: poses in the running slice', 'narration_text': n,
              'estimated_duration_s': c6['duration_s'], 'render_duration_s': c6['duration_s'], 'capture': 'run-01',
              'qc': footage_qc(c6['label_regions']),
              'shot': {'type': 'VIDEO', 'lane': 'capture', 'source': 'own', 'treatment': 'none',
                       'evidence_media': 'media/B06.mp4',
                       'show': [{'at': f'{(t - c6["ticks"][0]) / 60:.2f}s', 'event': f'pose {p}'} for t, p in c6['poses']],
                       'labels': [CAPTURE_NOTE, 'pose: <name> (from the input log)']}})

    code7 = lines(*B07)
    n = ("Now a cause. Before commit two-three-a-e, this loop played the scrape whenever an on-screen shadow started "
         "to grow, a second or more before the fork moved. Kiran wrote: the fork sound plays randomly. Now it fires "
         "only on the tick a fork starts down, and only for the jelly's plate or the next one.")
    b.append({'beat_id': 'B07', 'act': 'code: the scrape fix (cause)', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': 'Before commit', 'event': "note panel: the old line 'if fork and fork.advance():'"},
                  {'at': 'the fork sound plays randomly', 'event': "Kiran's audition note on screen"},
                  {'at': 'fires only on the tick', 'event': 'line 295 highlighted'},
                  {'at': "jelly's plate", 'event': 'line 299 highlighted'}],
                  'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                      'mode': 'code', 'title': 'The Fix: Scrape on the Way Down', 'project': 'Jelly Hop',
                      'path': 'res://game/session.gd', 'source': 'godot/game/session.gd',
                      'code': code7, 'startLine': B07[1], 'codeFontSize': 23,
                      'inspectorLabel': 'Source notes — git show 23ae39c',
                      'notes': [{'label': 'Before 23ae39c', 'value': 'if fork and fork.advance():\n→ scrape when any on-screen shadow starts'},
                                {'label': 'Kiran, audition 1', 'value': '"the fork sound plays randomly even if the forks are not coming down"'}],
                      'cues': [{'at': 2.0, 'line': 294, 'label': 'every fork, every tick'},
                               {'at': 13.0, 'line': 295, 'label': 'only on the tick a fork starts down'},
                               {'at': 17.0, 'line': 299, 'label': "only the current or next plate's fork"}],
                      'output': [f'{B07[0]} lines {B07[1]}–{B07[2]} · changed in 23ae39c · rev {REV}']}}},
              'cue_phrases': ['this loop', 'fires only on the tick', "jelly's plate"]})

    n = ("The effect, on one scripted route. Before: twenty-two scrapes, sixteen with no fork moving. After the "
         "first change, nine. After the second, eight, each on the tick its fork starts down. In our capture, the "
         "scrape fires at tick four sixty-nine, the tines land seven ticks later. Kiran's verdict: this looks good "
         "actually. Now the slice's own sound, with no narration.")
    b.append({'beat_id': 'B08', 'act': 'result: heard only when a fork falls (effect)', 'narration_text': n,
              'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'evidence_media': 'images/B08-scrape-on-descent.png', 'show': [
                  {'at': 'twenty-two', 'event': 'before bars'}, {'at': 'nine', 'event': 'fix 1 bars'},
                  {'at': 'eight', 'event': 'fix 2 bars, zero idle scrapes'},
                  {'at': 'tick four sixty-nine', 'event': 'the three capture frames: shadow, descent + SFX-WARN, hit'}],
                  'remotion': {'pattern': 'GodotDesignFigure', 'props': {
                      'title': 'The Effect: Heard Only When a Fork Falls',
                      'status': '3 frames from run-01 · counts from the Batch 3 audio traces',
                      'image': data_uri('images/B08-scrape-on-descent.png'),
                      'imageLabel': CAPTURE_NOTE,
                      'source': 'evidence/batch3-audio-trace-before.txt, -after.txt, -after2.txt · evidence/batch3-audition.md',
                      'cards': [{'label': 'Before', 'text': '22 · 16 idle'}, {'label': 'Change 1', 'text': '9 · 6 idle'},
                                {'label': 'Change 2', 'text': '8 · 0 idle'},
                                {'label': 'Kiran, audition 3', 'text': '"this looks good actually"'}],
                      'cues': [{'at': 3.0, 'card': 0}, {'at': 7.0, 'card': 1}, {'at': 9.0, 'card': 2}, {'at': 20.0, 'card': 3}]}}},
              'cue_phrases': ['Before', 'first change', 'After the second', 'this looks good']})

    c9 = clips['B09']
    b.append({'beat_id': 'B09', 'act': 'slice audio, no narration (premixed master)', 'narration_text': '',
              'estimated_duration_s': c9['duration_s'], 'render_duration_s': c9['duration_s'],
              'qc': footage_qc(c9['label_regions']),
              'audio_source': ('media/B09.mp4 engine audio, carried in the premixed --audio master '
                               '(tools/make_master.py). Kiran\'s decision, 2026-10-03: "lets use the fall back option '
                               'only. even that satisfies the requirements". The course was not asked.'),
              'shot': {'type': 'VIDEO', 'lane': 'capture', 'source': 'own', 'treatment': 'none',
                       'media': 'media/B09.mp4',
                       'show': [{'at': f'part {i + 1}', 'event': ', '.join(f'{sid} @ tick {t}' for t, sid in p['sounds'])}
                                for i, p in enumerate(c9['parts'])],
                       'labels': [CAPTURE_NOTE, 'Slice audio · no narration · scripted-input capture',
                                  'excerpt N of 3 · take · ticks']}})

    n = ("What was tested. On a clean snapshot of this revision: twenty-five mechanics checks, twelve keyboard, "
         "sixty-one slice, eight game audio, zero failures. That's logic under scripted input, some with fixtures, "
         "not feel. Feel rests on one human. Kiran played with sound on, then muted, and wrote: I can see the clues "
         "like the shadow keep increasing on the plate.")
    b.append({'beat_id': 'B10', 'act': 'tests and the human playtest', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'body', 'show': [
                  {'at': 'twenty-five', 'event': 'suite output lines'},
                  {'at': 'one human', 'event': "Kiran's playtest notes on the right"}],
                  'remotion': {'pattern': 'GodotDevWorkbench', 'props': {
                      'mode': 'trace', 'title': 'What Was Tested, and by Whom', 'project': 'Jelly Hop',
                      'source': 'tools/run_slice_checks.sh output (2026-10-03, snapshot of 7a48ea8) · TEST-REPORT.md',
                      'treeLabel': 'Output — tools/run_slice_checks.sh (automated)',
                      'tree': ['WALKER TESTS: 25 checks / 0 failures', 'KEYBOARD TESTS: 12 checks / 0 failures',
                               'SLICE TESTS: 61 checks / 0 failures', 'GAME AUDIO CHECKS: 8 checks / 0 failures',
                               'art 18/18 · audio 7/7 byte-identical', 'ALL SLICE CHECKS PASSED'],
                      'inspectorLabel': "Human playtest — Kiran's notes (TEST-REPORT.md)",
                      'notes': [{'label': 'Sound on, note 1', 'value': '"Yeah it all looks good"'},
                                {'label': 'Muted, note 5', 'value': '"I can see the clues like the shadow keep increasing on the plate"'},
                                {'label': 'Not covered', 'value': 'feel, fun, a second player, other machines'}],
                      'cues': [{'at': 2.0, 'line': 1, 'label': 'scripted input, some fixtures'},
                               {'at': 16.0, 'line': 3, 'label': 'one human playtest'}],
                      'output': ['Automated checks are not a playtest.']}}},
              'cue_phrases': ['twenty-five', 'one human']})

    n = ("Verdict. The slice works end to end, and all six sound events fire in real play, under scripted input, "
         "not a human session. Uncertain: one playtester on one Mac, the face at sixty-four pixels, collision boxes "
         "that differ from the sheet. On the art: plate, sauce, fork and dome are SDXL at fifty percent over guides "
         "drawn by Claude's script, changing four to nineteen percent of their pixels; room and table were text to "
         "image; and the batch-two prompts file was restored after generation. SDXL made the art, Stable Audio Open "
         "the sound effects, MusicGen-small the music. Kiran made the design decisions, ran the image generations, "
         "chose the assets, reviewed and playtested. Claude chat drafted documents and prompts; Claude Code did the "
         f"implementation, the audio generation and this film. Kiran's next step: {NEXT_STEP}.")
    b.append({'beat_id': 'BVDT', 'act': 'verdict', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'bookend', 'show': [
                  {'at': '0.05', 'event': "artifact page 'Jelly Hop — vertical slice at 7a48ea8'"},
                  {'at': '0.1', 'event': 'lines land as the voice names them'}],
                  'remotion': {'pattern': 'ClaudeVerdictArtifact', 'props': {
                      'artifactTitle': 'Verdict', 'artifactHeading': 'Jelly Hop — vertical slice at 7a48ea8',
                      'brandLabel': '@NikBearBrown',
                      'artifactLines': [
                          'WORKS — full route, all 6 sound events (scripted 4K run) · tests 25/12/61/8, 0 failures',
                          'UNCERTAIN — one human tester, one Mac; face at 64 px; collision boxes vs sheet; one crash',
                          'ART — plate, sauce, fork, dome: SDXL at 50% over Claude-drawn guides, 4–19% of pixels changed',
                          'ART — room and table text-to-image · Batch 2 prompts file restored after generation',
                          'MODELS — SDXL Base 1.0 (art) · Stable Audio Open 1.0 (sound effects) · MusicGen-small (music)',
                          'KIRAN — design decisions, image generation runs, asset selections, reviews, playtesting',
                          'CLAUDE chat — documents, prompts · CLAUDE CODE — implementation, audio generation, this film',
                          f'NEXT (Kiran) — {NEXT_STEP}']}}}})

    prompt = ("Use Walker on my Godot slice: pick one sound event, write down the exact tick you predict it fires on "
              "a scripted route, then add a trace that proves or disproves the prediction. Change the trigger only "
              "if the trace and a human playtest agree.")
    n = (f"Your turn. {prompt} Prediction first, so the trace can prove you wrong. And the change waits for a human "
         "ear, because this film's own fix started with a playtest note. Liam, in for Bear.")
    b.append({'beat_id': 'BHTF', 'act': 'your turn handoff', 'narration_text': n, 'estimated_duration_s': est(n),
              'shot': {'type': 'REMOTION', 'lane': 'ask', 'show': [
                  {'at': '0.0', 'event': "composer returns, greeting 'Your turn.'"},
                  {'at': '0.1', 'event': 'the prompt types itself as the voice reads it'}],
                  'remotion': {'pattern': 'ClaudeComposerAsk', 'props': {
                      'greeting': 'Your turn.', 'topic': 'JELLY HOP · GODOT DEVELOPMENT', 'segment': TITLE,
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


COMPONENTS = [
    ('level', 'The level and its session: six plates, sauce gaps, the dome, the intro pan, the HUD, project settings.',
     ['B02', 'BVDT'], ['project.godot', 'game/main.tscn', 'game/session.gd', 'game/slice_tuning.gd', 'ui/hud.gd'],
     ['ENV-PLATE', 'ENV-SAUCE', 'ENV-DOME', 'ENV-ROOM', 'ENV-TABLE']),
    ('jelly-poses', 'The jelly: 12 generated pose textures loaded by name, and choose_pose() picking one per tick.',
     ['B03', 'B04', 'B05', 'B06'], ['features/player/player.gd'], ['CHAR-']),
    ('fork-warning', 'Fork cycle, drawn shadow, hit shape from the tines, and the SFX-WARN trigger changed in 23ae39c.',
     ['B07', 'B08'], ['features/fork/fork.gd', 'game/session.gd', 'audio/sound_events.gd'], ['ENV-FORK', 'SFX-WARN']),
    ('sound-events', 'Six sound events and the music bus: one entry point, one call site per event, recorded calls.',
     ['B08', 'B10', 'BVDT'], ['audio/sound_events.gd', 'audio/music_controller.gd'], ['SFX-', 'MUS-LOOP']),
    ('tests', 'Headless suites, the scripted route the capture driver reuses, screenshot and trace tools.',
     ['B10'], ['tests/test_game.gd', 'tests/test_keyboard.gd', 'tests/test_slice.gd', 'tests/trace_audio.gd',
               'tests/route_driver.gd', 'tests/capture_slice.gd', 'tests/capture_poses.gd'], []),
]
EXCLUSIONS = {
    '.gitignore': 'Version-control ignore list (.godot/); no runtime role.',
    'features/player/tuning.gd': 'Movement constants from the walker-jumpman starter, unchanged; not explained in this '
                                 'short film (named in TEST-REPORT and the starter credit).',
}


def ledger(sheet):
    inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob('*')
                       if p.is_file() and not any(x in ('.godot', '.git') for x in p.relative_to(GAME).parts)
                       and p.suffix != '.uid')
    comp_files = {cid: set(files) for cid, _, _, files, _ in COMPONENTS}
    for cid, _, _, _, prefixes in COMPONENTS:
        for f in inventory:
            if f.startswith('assets/') and any(Path(f).name.startswith(px) for px in prefixes):
                comp_files[cid].add(f)
    records, excl = [], []
    for f in inventory:
        if f in EXCLUSIONS:
            excl.append({'path': f, 'reason': EXCLUSIONS[f]})
            continue
        cids = [cid for cid in comp_files if f in comp_files[cid]]
        if not cids:
            raise SystemExit(f'STOPPED: {f} has no component and no exclusion')
        role = 'import settings' if f.endswith('.import') else ('asset' if f.startswith('assets/') else 'source')
        records.append({'path': f, 'sha256': sha_file(GAME / f), 'role': role, 'component_ids': cids})
    beats = {x['beat_id']: x for x in sheet['beats']}
    excerpts = []
    for bid, (rel, a, z) in (('B05', B05), ('B07', B07)):
        excerpts.append({'beat_id': bid, 'path': rel, 'start_line': a, 'end_line': z, 'text': lines(rel, a, z)})
    pairs = [{'code_beat': 'B05', 'result_beat': 'B06',
              'observation': 'The pose readout steps through SCOOT, ANTIC, RISE, FALL, LAND, WORRY, SPLAT and RESPAWN '
                             'in the order choose_pose() ranks them, in the real run.',
              'media': {'path': 'media/B06.mp4', 'sha256': sha_file(REEL / 'media/B06.mp4')}},
             {'code_beat': 'B07', 'result_beat': 'B08',
              'observation': 'SFX-WARN fires at tick 469, the tick fork 2 starts down, 7 ticks before the tines land; '
                             'the traces show 0 scrapes with no fork moving after the change.',
              'media': {'path': 'images/B08-scrape-on-descent.png', 'sha256': sha_file(REEL / 'images/B08-scrape-on-descent.png')}}]
    for p in pairs:
        assert beats[p['result_beat']]['shot']['evidence_media'] == p['media']['path']
    return {'schema_version': 1, 'teaching_contract': 'code-then-result-v1', 'game_revision': REV,
            'files': records, 'exclusions': excl,
            'components': [{'id': cid, 'explanation': ex, 'beat_ids': bids, 'files': sorted(comp_files[cid])}
                           for cid, ex, bids, _, _ in COMPONENTS],
            'excerpts': excerpts, 'code_result_pairs': pairs}


def script_md(sheet):
    out = [f'# SCRIPT — {TITLE}', '',
           'Draft for Kiran\'s script review (Batch 2). Narration is what Liam will say; "On screen" is what the '
           'viewer sees. Times are estimates until Kokoro measures them. Items marked **[DECIDE]** need your call.', '']
    total = 0.0
    for x in sheet['beats']:
        d = x.get('estimated_duration_s') or 0
        total += d
        out.append(f"## {x['beat_id']} — {x['act']}  (~{d:.0f} s)")
        rem = x['shot'].get('remotion', {})
        out.append(f"On screen: {rem.get('pattern', x['shot']['type'])}; " + '; '.join(e['event'] for e in x['shot'].get('show', [])))
        out.append('')
        out.append('> ' + (x['narration_text'] or '*(no narration — the slice\'s own engine audio, via the premixed master)*'))
        out.append('')
    out.append(f'**Estimated total: {total / 60:.1f} min** ({total:.0f} s).')
    return '\n'.join(out) + '\n'


def main():
    sheet = {'metadata': {
        'title': TITLE, 'slug': SLUG, 'topic': 'JELLY HOP · GODOT DEVELOPMENT', 'register': 'Teardown',
        'audience': 'Claude', 'brand': 'claude-liam', 'persona': 'Liam (in for Bear)', 'voice': 'am_onyx',
        'engine': 'kokoro', 'voice_kokoro': 'am_onyx', 'palette': 'claude', 'style_preset': 'claude',
        'ground': '#FAF9F5', 'greeting': 'Hej, Liam', 'folderLabel': '@NikBearBrown', 'in_for_bear': True,
        'aspect_ratio': '16:9', 'fps': 30, 'fit': 'crop', 'skill': 'godot-gamedev', 'modifier': 'walker',
        'game': 'walker-jellyhop-kiran-g', 'game_revision': '7a48ea8cb29c04dfafa3e6df6fe491e1807c8409',
        'game_build_id': (REEL / 'capture/capture-run.txt').read_text().split('build_id: ')[1].split()[0],
        'capture_method': 'scripted-input', 'approvals': {}},
        'beats': beats()}
    (REEL / 'beat_sheet.json').write_text(json.dumps(sheet, indent=1, ensure_ascii=False) + '\n')
    ev = ledger(sheet)
    (REEL / 'gamedev-evidence.json').write_text(json.dumps(ev, indent=1, ensure_ascii=False) + '\n')
    (REEL / 'SCRIPT.md').write_text(script_md(sheet))
    print(f"beats {len(sheet['beats'])} · files {len(ev['files'])} · exclusions {len(ev['exclusions'])} · "
          f"components {len(ev['components'])} · excerpts {len(ev['excerpts'])}")


if __name__ == '__main__':
    main()
