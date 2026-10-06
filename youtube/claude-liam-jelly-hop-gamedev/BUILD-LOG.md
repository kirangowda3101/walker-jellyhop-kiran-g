# BUILD-LOG — Jelly Hop explainer film (godot-gamedev + walker)

Record of what was run for this film, with results as observed. Claude Code ran every command below on Kiran's Mac (Apple M4, macOS 26.5.1). Routine choices marked "(Claude Code's choice)" are mine; decisions quoted as Kiran's are Kiran's.

## 2026-10-03 — Batch 1: setup check and capture pilot

### Toolkit doctor (`./setup`, read-only, no `--install`)

Command, from `~/Documents/brutalist.art` (toolkit commit not modified):

    PATH=/opt/anaconda3/bin:$PATH ./setup

Result: **exit 1, before the readiness table.** The doctor's ElevenLabs guard (a grep for functional ElevenLabs references) matched files that ship inside the toolkit's own example reels, not this project:

- `youtube/brutalist/claude-liam-brutalist-command-setup/` (SCRIPT.md, beat_sheet.json, PROMPTS.md, vertical/beat_sheet.json, vertical/PROMPTS.md)
- `youtube/brutalist/claude-liam-brutalist-runtime-brand-variant/demo/` (two beat_sheet.json files)
- `youtube/brutalist/shorts/claude-liam-brutalist-command-setup-short/PROMPTS.md`
- `youtube/brutalist/claude-liam-brutalist-skill-your-turn/demo/` (two fixture beat sheets)

The toolkit may not be edited (CLAUDE.md hard rule), so the guard failure stays. I ran the doctor's individual checks by hand instead:

| Check (as in `./setup`) | Command | Result |
|---|---|---|
| Python interpreter | `PATH=/opt/anaconda3/bin:$PATH which python3` | `/opt/anaconda3/bin/python3` (Kiran's decision: use Anaconda, no installs; Homebrew's python3, which `./art` finds first by default, lacks the packages) |
| Pillow | `python3 -c "import PIL"` | ok |
| manim | `python3 -c "import manim"` | **MISSING** (import fails). Not used by this film. |
| faster-whisper | `python3 -c "import faster_whisper"` | ok |
| kokoro-onnx | `python3 -c "import kokoro_onnx"` | ok |
| mutagen, numpy | import | ok |
| Kokoro model files | `ls runtime/models/kokoro/` | `kokoro-v1.0.onnx`, `voices-v1.0.bin` present |
| Kokoro live synthesis | `python3 runtime/scripts/setup_smoke_kokoro.py` | `[smoke] kokoro synth OK — mean_volume -21.8 dB`, exit 0 |
| Node ≥ 20 | `node -v` | v24.5.0 |
| ffmpeg / ffprobe | `ffmpeg -version` | 8.1 (Homebrew). This build has **no `drawtext` or `subtitles` filter**; labels on footage are PNG overlays instead. |
| Remotion deps | `ls runtime/remotion/node_modules` | present |
| Fonts | `fc-list`, `~/Library/Fonts` | EB Garamond and Oswald installed |
| LaTeX | not checked | only needed for Manim equations; not used |
| Scenes this film uses | `./art scenes --check GodotDevWorkbench`, `… ClaudeComposerAsk` | both RENDERABLE |

No paid service, API key, or download was used.

### Slice checks on an isolated snapshot

`git archive 7a48ea8 | tar -x` into the session scratchpad (the repo was not touched), then `bash tools/run_slice_checks.sh` there. Result: **ALL SLICE CHECKS PASSED**:

- art copies 18/18 byte-identical
- audio copies 7/7
- game audio 8 checks / 0 failures
- WALKER TESTS 25/0
- KEYBOARD TESTS 12/0
- SLICE TESTS 61/0
- 7 screenshots at 1280×720
- 8 s launch with no errors

The summary's `repo:` line printed empty because the snapshot is not a git repository. Its "(uncommitted batch changes present)" text is fixed in the script, not a finding.

### Capture driver and 4K pilot

- **Driver:** `capture/capture_driver.gd` (stored in this reel; copied only into the snapshot when recording). Two driver bugs were found and fixed before any evidence take (Claude Code's fixes):
  1. `Input.action_press` from the `physics_frame` signal never registered as a fresh jump press. In a headless dry run the jelly walked off plate 1 and hopped late inside the coyote window. Replaced with keyboard `InputEventKey` events through `Input.parse_input_event`, the same path a keyboard uses; each hop is one Space press held 4 ticks.
  2. The game ignores a direction already held when control returns (`require_axis_release`); the driver now keeps the keys up for 2 ticks after control returns, then presses.
- **Resolution:** `--resolution 3840x2160` alone recorded at 1280×720 (clamped to the 3024×1964 display). A copy-only `override.cfg` (`window/size/window_width_override=3840`, `…height_override=2160`) gave native 3840×2160; disclosed in CAPTURE.md.
- **Pilot result:** 7.07 s, `mjpeg 3840x2160 60/1`, `pcm_s16le 48000 Hz 2 ch`.
  - Audio peaks on the logged frames: HOP (frame 322) −15.9 dB, LAND (363) −10.8 dB, WARN (378) −18.4 dB, against −33.3 dB of music just before.
  - A 1:1 crop of the jelly is sharp: it is rendered at 4K, not upscaled.
  - The pilot is not used in the film.

Kiran approved Batch 1 and asked for a second, short take with a sauce splat so all six sound events occur in real play.

## 2026-10-03 — Batch 2: captures, trims, beat sheet, script, evidence ledger

Kiran's instruction for this batch: add the short sauce-splat take so all six sound events appear in real play; disclose `test_mode` and the copy-only `override.cfg` in CAPTURE.md; record the `./setup` result here; stop for script review before narration.

### Captures

- **Driver:** a sauce route was added (`CAPTURE_ROUTE=sauce`). Headless dry run: CAPTURE OK, splat cause `sauce`, one SFX-SPLAT-SAUCE.
- **`capture/run_captures.sh`** (Claude Code's script):
  - extracts a fresh snapshot of `7a48ea8`, fingerprints `godot/` (83 files, build_id `c71c0491…`), then adds the driver and `override.cfg`
  - records both takes and hashes them
- **First attempt: STOPPED** (work folder `capture-final/`). The snapshot had never been imported, so no texture or sound loaded (`Failed loading resource …`, `Cannot open file …oggvorbisstr`). `fork.gd:67` raised `Cannot call method 'get_image' on a null value`, so the forks had no hit shapes. The jelly stood under nine strikes on plate 2 untouched until I killed the process at about tick 2,540; the script reported `STOPPED: run-01: Godot exited 143`.
  - **Cause:** my capture setup, not the game. The Batch 1 copy had been imported by `run_slice_checks.sh`.
  - **Fix:** the script now runs `godot --headless --import` first and stops on load or script errors in any log.
- **Second attempt: CAPTURES OK.**
  - run-01: 1,241 frames, fork splat at tick 476, WIN at tick 1091.
  - run-02: 354 frames, sauce splat at tick 217.
  - Both `mjpeg 3840x2160 60/1` + `pcm_s16le 48000 2ch`.
  - Hashes in CAPTURE.md. All six sound events occur across the two takes.

### Figures and clips

- **`tools/make_images.py`** checks the raw SDXL output (`2c0f71a7…`) and the guide (`89c7a49f…`) against ASSET-LOG.md before use.
  - First render: the B03 and B04 panels and the B08 chart labels ran past the canvas edge (I inspected the PNGs).
  - Fixed the geometry, re-rendered and re-inspected: everything fits.
- **`tools/make_clips.py`:** B06 = run-01 ticks 241–961, 12.0 s (first cut 10.0 s; lengthened because the draft narration would not fit 10 s, and action may not be retimed). B09 = 3 excerpts, 11.73 s, with engine audio (peak −5.9 dB).
  - The labels are Pillow PNG overlays; inspected in frames.

### Beat sheet, ledger, check

- **`tools/make_reel.py`** writes `beat_sheet.json` (14 beats), `gamedev-evidence.json` and SCRIPT.md. Code on screen is read by line range from the files.
- **`./art godot-gamedev --check REEL --game godot`:** **PASS**. 66 source files, 2 exclusions, 5 components, 2 exact excerpts, 2 code → result pairs, contract `code-then-result-v1`. The checker's own scope note: "Hashes, inventory, source lines and associations; not semantic/visual approval."
- **Fact-check corrections before review:**
  - B02 "about a second" → "about a second and a quarter" (1.3 s)
  - two unverified details removed from RIFF.md (camera shake; "6 ticks" → the logged 470–476)
- **Not run yet (Batch 3):** Kokoro narration, Remotion renders, `./art run` / `./art final`, frame QC.
- **Estimated length:** 5.4 min, above the 4–5 min target (options in the review).

## 2026-10-03 — Batch 3: narration, renders, final export, QC

### Kiran's script-review answers (applied in `tools/make_reel.py`)

Next step (verbatim), the B01 correction, the title "Jelly Hop: Fork From Above", the credits wording, the cut to about 4.9 min, and committing the four figures. The decision on the B09 audio is recorded in FACTCHECK.md and FRICTIONAL.md.

**Correction to my own Batch 2 text:** FACTCHECK.md said "Kiran asked the course for the sanctioned method on 2026-10-03 (evening)". That was wrong. Kiran had said they would ask, then decided not to. The sentence was replaced with the actual decision.

### Narration and timing

- **Kokoro:** `generate_audio_kokoro.py` (`am_onyx`, local, $0.00) for 13 beats; 235.5 s of voice. B09 has no narration.
- **`tools/make_master.py` (new):** sets each beat's duration, places the highlight cues by phrase position, and builds `audio/master.wav`.
  - narrated Remotion beats: 0.4 s lead + voice + 1.2 s tail, rounded up to a frame
  - B01: 0.8 s lead, at least 9 s
  - B06 and B09: exactly their clips' counted frames (360 and 352)
  - BOUT: voice + 1.0 s silent tail
- **Two problems found and fixed before use:**
  1. B09's segment taken from `media/B09.mp4`'s AAC track ran 96 ms long, because each AAC excerpt adds padding. B09's audio is now cut sample-exactly from the AVIs' PCM, with the same tick ranges as the picture.
  2. B09's duration was first read from the container (11.767 s); it now comes from the counted video frames (11.733 s).
- **Result:** master 267.567 s = timeline 267.567 s (4.46 min).
- **Levels, unchanged:** B09's engine audio averages −37.6 dB, peak −5.9 dB; narration (B05) averages −27.4 dB, peak −6.2 dB.

### Renders

- **Pilot B05 (`GodotDevWorkbench`), inspected:**
  - At code size 27, lines 159–163 (worry, bored, idle) were cut off and the 4th note overflowed.
  - Second pilot at size 23 with lines 149–163: line 163 was still cut off.
  - Final: lines 149–162 (every branch the narration names), size 23, two notes. Nothing clipped.
  - `./art godot-gamedev --check`: PASS after each change.
- **Toolkit side effect (reported, not an edit I chose):** every `remotion_scenes.py` render appends this reel's beats to `brutalist.art/runtime/remotion/_bench/consumers.json`, a gitignored usage index that the walker-jumpman renders also wrote to. No tracked toolkit file was changed by this work. `runtime/remotion/package-lock.json` shows as modified in that repo, but its timestamp is Sep 22, before this work.
- **Render result:** all 12 Remotion beats `ok` at 3840×2160. B05 is kept from the inspected pilot. B01, B03 and B08 rendered about one frame longer than their slots; the compiler fits Remotion graphics to their slots, while the gameplay beats B06 and B09 match their slots exactly.

### B09 level change for audibility (Kiran's instruction)

Kiran: the slice's audio must be clearly audible, so raise B09's segment "by a single plain gain (no compression, no limiting, nothing added) so its peak reaches −1 dBFS".
- **`tools/make_master.py`:** `ffmpeg volume=+4.90dB` on B09's segment only, computed as −1.0 − measured peak (−5.9).
- **B09 before:** mean −37.6 dB, peak −5.9 dB.
- **B09 after:** mean −32.7 dB, peak −1.0 dBFS.
- **Narration, for comparison:** mean −27.4 dB, peak −6.2 dB.
- **Not changed:** the relative balance inside the game mix (music vs effects); no other processing.
- **Master:** `audio/master.wav`, 267.567 s, SHA-256 `93190deb05eddee4589efda19795f3b997c4e476b033d48ed5f1f7459a725f74`.

### Beat inspection and fixes (Claude Code's frame reads, before and after the first export attempt)

I sampled every Remotion beat at 15/50/85% and Read the frames.
- **B01:** the writer never made its correction. The component matches single words (`triggers.indexOf(core)` per token), so the phrase trigger "as the shadow grows" could never fire.
  - **Line 3 reworded:** "The scrape plays as shadows grow." → corrected word by word: shadows→forks, grow→descend. The final line reads "The scrape plays as forks descend." (Kiran asked for the correction "so the scrape plays as the fork starts descending"; this wording is mine and goes to Kiran's film review.)
  - **Second render:** the correction finished after the cut ("forks grow" on the last frame). Random typos and long pauses were removed (`mistakeRate` 0, `hesitateWithin` 0, `hesitateBetween` 3, `charMs` 26).
  - **Third render:** corrected by about 10 s; the final sentence holds about 2 s. Type raised from 80 to 100.
- **B03:** the prompt text was about 15 px at 1080p. The figure was redrawn at a 3200×1180 aspect with larger text.
- **B07:**
  - Wrapped comment lines pushed 301–304 out of the panel. Now lines 294–301 at code size 23; Liam points at 295 and 299, both visible.
  - The third note ("After") clipped; it was removed, since the code shows the new version.
- **B08:** frame labels about 18 px. Enlarged; then they collided ("tick 469tines land") and were shortened. Remaining wording mismatch: the chart says "fix 1/fix 2" and the cards say "Change 1/2".
- **BVDT:** the 8-line card (3 wrapping) covered the @NikBearBrown label. The same content now fits in fewer rows: TESTED merged into WORKS; "one human" moved into UNCERTAIN; Kiran's next step still verbatim.
- **Unchanged after inspection:** B00, B02, B04, B05, B10, BHTF and BOUT were inspected and left as they were.

### First `./art final` attempt: REFUSED

- **GATE T (type check): SKIPPED, not passed.** `runtime/scripts/type_check.py` needs `scipy.ndimage`. In Anaconda, scipy 1.13.1 (built against NumPy 1.x) fails to import with NumPy 2.2.6. `./art final` treats that as missing dependencies (exit 3) and continues.
  - Fixing it means installing or changing packages, which Kiran has not approved.
  - The gate's checks (minimum type size, overflow, contrast, kerning, golden strings) have **not** been run on this film.
- **GATE V (final frame check): FAILED on the candidate**, so the export was refused and no file was promoted. I rebuilt the same candidate from the compiled clips and ran the checker directly: 28 frames, 4 BLOCKER, 6 MAJOR.
  - **B06/B09 edge-bleed and low contrast:** the engine picture runs edge to edge on a dim table.
    - **Real defect of mine:** my burned-in labels sat at x 30, y 25 (1080p scale), outside title-safe. Moved to x ≥ 100, y 60–1014.
    - Then declared `qc.full_bleed` with a reason, plus `qc.contrast_regions` (each label's box, recorded by `make_clips.py`) with `contrast_reason`, so the labels are still tested in every sampled frame. This is the pattern the walkthrough skill describes and the walker-jumpman reel used.
  - **B01 underfill:** declared `qc.sparse_by_design` with its reason (the writer types token by token). This waives only underfill and clustering; edge, contrast and empty-frame checks still apply.

### Second `./art final` attempt: REFUSED

GATE V: 0 BLOCKER, 3 MAJOR. The bottom labels (pose and excerpt) were dark boxes on the dark curtain, and their regional contrast was below 0.3. They were changed to dark text on a light box. GATE T was still skipped.

### Third `./art final`: READY

- **Export:** `exports/landscape/claude-liam-jelly-hop-gamedev.mp4`, 267.567 s, 48.3 MB, SHA-256 `b3f8ccfc198dee79a670f6efbfce74c0215ca45f3b9dce0f618ab056c928b95b`. The `.verified.json` receipt matches.
- **GATE V:** 28 frames, 0 BLOCKER, 0 MAJOR. Regional contrast was tested on B06 and B09.
- **Final preflight:** FACTCHECK.md, SHOTLIST.md and PROMPTS.md are non-empty; beat_lint is clean; slots 14/14, no slates.
- **GATE T: skipped**, as above (not run).
- **`./art godot-gamedev --check` at handoff:** PASS (66 files, 2 exclusions, 5 components, 2 exact excerpts, 2 code → result pairs).
- **My QC** (frames, per-beat audio levels, B09 sync at 9 logged sound events, outro silence): `_qc/REPORT.md`, bottom section.
- **Not run:** `./art post` (its loudness and caption checks belong to publishing, which this film does not do), and `./art godot-waikthrough --check` (this is a gamedev film with no `coverage.json`).

## 2026-10-05 — Kiran's film review and GATE T

**Kiran's film review, word for word:** "the video looks good."

### GATE T (type check), run without installing anything

Command (the same script and argument `./art final` uses, with the Python from Kiran's audio environment, which has compatible NumPy 2.5.3, scipy 1.18.1 and Pillow 12.3.0):

    cd ~/Documents/brutalist.art
    ~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py ~/Documents/walker-jellyhop-kiran-g/youtube/claude-liam-jelly-hop-gamedev

- **Result: exit 2, GATE T: FAIL.** 14 beats checked; 1 FAIL. Report: `TYPECHECK.md`; log: `_qc/gate-t.log`.
- **The FAIL:** B02, check `contrast-local §8.3b`: "per-blob contrast 2.04:1 < 3.0:1 — text unreadable on actual local background (blob@(1613,1630)–(1688,1668) fg≈(84, 51, 51) bg≈(119, 102, 101))". The report's suggested fix: "Use INK on cream; add backing plate under accent text".
- **Where that box is:** I located the box in a 3840×2160 frame of `media/B02.mp4`. It lies inside the held frame of the game (run-01 tick 90), on the table curtain just left of the game's own HUD line "any key skips the intro". At 1:1 the box contains curtain folds and highlights; I see no text there. This is my reading of the pixels, not a pass: the gate result stands as FAIL.
- **Everything else passed:** min-size 12/0, overflow 12/0, contrast 12/0, bbox-overlap 12/0, card-clip 12/0, no-wordy-card 7/0. B06 and B09 were skipped by the checker ("no video" for footage beats).
- **Per Kiran's instruction:** with a GATE T defect, no re-export and no commit. Nothing was staged or committed.

### B02 crop (Kiran's choice, option 1) and re-export, 2026-10-05

- **Change:** `tools/make_images.py` now crops B02's held frame (run-01 tick 90) to y 0–1600 of 2160, which is above the table curtain where GATE T found the 2.04:1 blob. The plates and sauce stay; the game's HUD line "any key skips the intro", drawn on the curtain, is cut. The B02 label now reads "Held frame · run-01, tick 90 · intro pan · cropped above the curtain".
- **Rebuilt and re-rendered:** `make_images.py` → `make_reel.py` → Kokoro → `make_master.py` → `remotion_scenes.py --only B02`. Master unchanged: 267.567 s, SHA-256 `93190deb…`. The previous B02 render is in `_qc/prev/`.
- **GATE T** (`~/Documents/jellyhop-audio-env/bin/python runtime/scripts/type_check.py <reel>`): **PASS**, exit 0, before the export (`_qc/gate-t-2.log`) and again after it on the same beats (`_qc/gate-t-3.log`). 12 PASS, 2 SKIP (B06 and B09, "no video"), 0 FAIL. Inside `./art final` GATE T still prints "skipped", because the wrapper uses Anaconda's Python.
- **Export:** `./art final … --audio audio/master.wav` → **ready**. `claude-liam-jelly-hop-gamedev.mp4`, 267.567 s, 48,267,339 bytes, SHA-256 `e7cdb04c15af0e4106ac6da03f08eb52ef642decf95af2f1108ea4869480d817`; the receipt matches. The superseded 2026-10-03 export (`b3f8ccfc…`) is kept in `_qc/prev/`.
- **GATE V:** 28 frames, 0 BLOCKER, 0 MAJOR.
- **`./art godot-gamedev --check` at handoff:** PASS (66 files, 2 exclusions, 5 components, 2 exact excerpts, 2 code → result pairs).
- **B02 in the final file:** inspected; shows the cropped frame and its label.
- **Not committed:** waiting for Kiran to check B02.

**Kiran's B02 check of the 2026-10-05 export, word for word:** "it looks good"
