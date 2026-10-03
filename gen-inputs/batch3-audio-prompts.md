# Batch 3 — sound effects and music: prompts and settings (committed before generation)

Written 2026-10-03 and committed **before any Batch 3 generation**, by `tools/audio_prompts_commit.sh`, which verifies the commit and the push. Every take generated in this batch uses exactly the text and settings below; any change during the batch is logged as a new dated note at the end of this file, not by editing the lines above it.

Sound design comes from CHANGE-BRIEF.md (event-to-sound map, music behavior) and CONCEPT.md (audio direction: "slightly tense but playful", the player "holding their breath and watching the timing, without the danger feeling too dramatic or scary"). No prompt names an artist, a band, a song, a brand, or a real person's voice.

## Models (my choice, 2026-10-03)

| Use | Model | Where it runs | License |
|-----|-------|---------------|---------|
| The six sound effects | Stable Audio Open 1.0 (Stability AI), `stabilityai/stable-audio-open-1.0` | Locally on my MacBook Pro (Apple M4, 16 GB) | Stability AI Community License (free for research and non-commercial use; limited commercial use under US $1M annual revenue with registration). Gated download: I accept the license on Hugging Face. |
| The music loop | MusicGen-small (Meta), `facebook/musicgen-small`, 300M parameters | Locally on the same Mac | Model weights CC-BY-NC 4.0 (non-commercial only); code MIT. Acceptable for coursework; stated in SOURCES.md. |

The exact model revisions (Hugging Face commit hashes) and library versions are recorded by the generation script at run time.

## Shared rules

- **Takes:** 3 per sound, seeds **7270, 7271, 7272**, everything else fixed. More takes only if all three fail, logged with the reason.
- **Raw outputs:** WAV, kept outside the repository in `~/Documents/jellyhop-generations/audio/`, named `<ID>-take<N>-seed<SEED>.wav`.
- **I listen to every take and choose.** Rejected takes are logged with my reason; their waveforms go on a contact sheet in `evidence/` (the "thumbnail" for audio).

## Sound effects — Stable Audio Open 1.0

Settings for every sound effect: 100 diffusion steps, CFG scale 7.0, the library's default sampler, 44.1 kHz stereo, generated length as listed (trimmed afterwards).

Negative prompt for every sound effect except SFX-WIN: `music, melody, vocals, speech, voice, singing, background noise, hum, hiss, long reverb, low quality, distorted, clipping`

Negative prompt for SFX-WIN: `vocals, speech, voice, singing, drums, background noise, hum, hiss, low quality, distorted, clipping`

| ID | Event (CHANGE-BRIEF) | Generated length | Prompt |
|----|---------------------|------------------|--------|
| SFX-HOP | grounded → airborne after a fresh jump press | 1.0 s | `short soft squishy jelly bounce, springy wet boing as a small gelatin cube jumps, cartoon jump sound effect, single sound, close microphone, clean` |
| SFX-LAND | airborne → grounded on a plate | 1.0 s | `soft wet jelly squish landing on a ceramic plate with a tiny clink, cartoon landing sound effect, single short impact, close microphone, clean` |
| SFX-WARN | a fork's shadow phase starts on screen | 1.5 s | `slow tense metallic scrape of a steel fork dragging across a ceramic plate, short warning sound, single sound, close microphone, clean` |
| SFX-SPLAT-FORK | splat from a fork hit | 1.2 s | `heavy wet jelly squish splat with a brief sharp metallic clank of a steel fork hitting a plate, cartoon impact, single sound, close microphone, clean` |
| SFX-SPLAT-SAUCE | splat from landing in sauce | 1.0 s | `soft sloppy wet splat into thick sauce, gooey squelch, cartoon, single short sound, no metal, close microphone, clean` |
| SFX-WIN | first time reaching the dome | 2.0 s | `short bright cheerful glass chime jingle, three rising bell notes, cartoon success sound, single sound, clean` |

## Music — MusicGen-small

| ID | Use | Prompt |
|----|-----|--------|
| MUS-LOOP | the playful, slightly tense loop for the whole slice | `playful slightly tense instrumental loop for a cartoon platformer game, pizzicato strings and soft marimba, light ticking percussion, steady 100 bpm, minor key, no vocals` |

Settings: 30 s per take (1,500 tokens at 50 Hz), sampling on, top-k 250, temperature 1.0, guidance scale 3.0, 32 kHz mono.

## Planned edits (logged with their parameters when made)

- **Sound effects:** trim leading silence (threshold −50 dBFS) so each sound starts immediately; trim the tail after it falls below −50 dBFS, with a short fade-out; level to a common peak (−1 dBFS). No other changes.
- **Music:** find the tempo and beats, cut a loop at bar boundaries (as many whole bars as sound good, at least 8 seconds), and join the end to the start with the shortest crossfade that removes the click (logged in milliseconds). The seam is checked by measurement and by my listening to at least three repetitions.
- **Delivery:** OGG Vorbis for the game (WAV if OGG export fails), stored in `audio/game/` and copied byte-identical into `godot/assets/audio/`. The music imports with looping on.

## Note added 2026-10-03, before the full generation run: torchsde workaround (no prompt or setting change)

- **What failed:** the Stable Audio Open test take stopped with `RecursionError: maximum recursion depth exceeded` inside torchsde (0.2.6), the library behind the model's default sampler (`CosineDPMSolverMultistepScheduler`, diffusers 0.40.0, torch 2.14.1). It failed the same way on the Mac's GPU (MPS) and on the CPU. At the final diffusion step the sampler asks torchsde for noise between sigma 0.3 and 0. In float32 the 0.3 is 0.30000001; torchsde clamps the 0 up to its lower bound 0.3, then rounds both ends to 6 decimals, which leaves a zero-width interval that it splits forever.
- **The fix (Claude Code's choice, approved by me before the run):** in `tools/batch3_generate.py`, a noise-time value within torchsde's own tolerance (1e-6) of the sampler's bounds (sigma 0.3 and 500) is snapped onto the bound before the query. Only that degenerate final query changes, and it then returns the zero increment torchsde intended. The fix is described in every take's record in `evidence/batch3-generation-log.txt`.
- **Unchanged:** every prompt, negative prompt, seed (7270, 7271, 7272), length, step count (100), CFG scale (7.0) and the library's default sampler, as listed above. MusicGen-small is not affected.

## Note added 2026-10-03, before processing for the game: leveling by perceived loudness (change to the planned edits)

- **Decision (mine):** match perceived loudness for the game too, with gain only: no compression or limiting, and every file peaks at or below −1 dBFS. This replaces the planned edit "level to a common peak (−1 dBFS)". The other planned edits are unchanged (sound effects: trim leading silence at −50 dBFS with no fade-in, trim the tail below −50 dBFS with a short fade-out; music: a loop of whole bars, at least 8 s, with the shortest crossfade that removes the click).
- **Method (the one used for the comparison files, `tools/batch3_compare.py`, `evidence/batch3-compare-log.txt`):**
  - **Sound effects:** maximum momentary loudness. That is ITU-R BS.1770 K-weighting (pyloudnorm 0.2.0 filters), a 400 ms window (EBU R128 / Tech 3341 momentary), a 10 ms hop, channel weights 1.0, with the clip followed by 400 ms of silence so short clips are measured whole. It is measured after trimming (15 ms linear fade-out, no fade-in).
  - **Music:** integrated loudness, ITU-R BS.1770-4 with gating (pyloudnorm), measured on the loop.
- **Fixed sound-effect target: −30.1 LUFS (maximum momentary).** This is the highest common level at which all 18 sound-effect takes stay at or below −1 dBFS peak with gain only; it is set by SFX-SPLAT-SAUCE take 3. Every sound effect, including any later swap, uses this same target.
- **Music target: −40.1 LUFS integrated.** That is 10 LU below the sound-effect target, so the sound effects stay clearly audible over the music (Claude's proposal; I judge the balance in the game). The music controller's bus levels (normal 0 dB, warning −9 dB, and so on) apply on top, unchanged.
