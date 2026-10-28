The film is rendered and every quality check passes. Kiran hasn't watched it or reviewed the script yet, and nothing is committed.

## The export
- **File:** `/Users/kiran/Documents/walker-jellyhop-kiran-g/youtube/claude-liam-jelly-hop-a5/exports/landscape/claude-liam-jelly-hop-a5.mp4`
- **Duration:** 518.567 s (8 min 38.6 s)
- **Size:** 51,639,549 bytes (51.6 MB). That's over 25 MB, but `.gitignore` already keeps it out of git.
- **SHA-256:** `240e7409d3974cd49357e429564657ec6f6743fb5a9ad4daefb4aa547e34b237`
- **Format:** 3840×2160, 30 fps, AAC stereo audio. The export receipt says "ready" and its SHA-256 matches.
- **To watch:** `open "/Users/kiran/Documents/walker-jellyhop-kiran-g/youtube/claude-liam-jelly-hop-a5/exports/landscape/claude-liam-jelly-hop-a5.mp4"`

## Quality checks
- **GATE V (frame check inside `./art final`):** 50 frames sampled, 0 BLOCKER, 0 MAJOR.
- **GATE T (type check):** PASS, 0 failures, before and after the export. As in A3, the copy inside `./art final` was skipped because of Anaconda's NumPy/scipy mismatch, so I ran it directly with the jellyhop-audio-env Python.
- **`./art godot-gamedev --check`:** PASS at handoff (34 files, 74 exclusions, 7 components, 6 exact code excerpts, 6 code → result pairs).
- **My checks on the exported file:**
  - I looked at a frame from every beat: labels are legible and nothing is clipped.
  - B01's typed correction ("Every texture is information.") is on screen before the cut.
  - All 25 beats have narration, with even levels.
  - The outro ends in silence (−91 dB), with no jingle.
- Details are in `_qc/REPORT.md` and `BUILD-LOG.md`.

## Problems found and fixed along the way
- **First GATE T run failed on 5 beats.** Four were dark parts of engine captures that the checker read as low-contrast text, such as curtain folds and wood grain. I fixed those by cropping or resizing only, never retouching, and the labels say "cropped". The fifth was an output line one word over the 12-word limit, which I shortened.
- **Two code panels were cut off at the bottom** (B08 and B13), so I changed which lines they show.
- **One mistake of mine:** while fixing those, a script crash was hidden by a `| tail` pipe, and two beats were rendered with the wrong timing. I caught it, fixed the script, re-timed and re-rendered both beats, and stopped using pipes that hide errors. The film's timing didn't change.

## In-play footage
- I recorded real engine frames in a windowed run with Godot Movie Maker, using keyboard input sent by a script.
- It ran from a `git archive` copy of 77a6d10 outside the repository, so I added nothing to `godot/` (not even a capture script under `godot/tools/`). The scripts are in the film's `capture/` folder.
- Every frame is labelled "Scripted capture … not a human playtest". Each fork on screen gets a tag with its `warning` value, read from the capture log.
- The take: the far forks start half amber in the intro, the plate 2 fork turns amber and strikes, and the forks keep their values after the win.

## What I could not do, or you should check
- **`SOURCES.md` in the film folder:** this run's permission rules block writing any file named `SOURCES.md` (they protect the root one). I didn't work around that; the film's source record is in `FILM-SOURCES.md` instead.
- **The next step is mine, not yours.** Your files don't name an A5 next step, so I proposed one from the open items ("measure whether the table's tint is converted to linear"). The film says "proposed from the open items"; please confirm or replace it.
- **The title** ("Jelly Hop: Shaders and Materials") is my choice.
- **Not done:** nobody has watched it with sound, and there is no transcript check of the narration. Neither of us has listened to it yet.
- **Not touched by me:** the two untracked `.uid` files under `godot/tools/` were already there before this run. The toolkit's `package-lock.json` was already modified (dated 22 September).
- **Large files:** the 4K capture AVI is outside the repo, in `/Users/kiran/Documents/jellyhop-a5-film-work/`. `beat_sheet.json` is 5.6 MB because it embeds the figures, which is under the 25 MB limit.