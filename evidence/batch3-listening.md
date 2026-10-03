# Batch 3 listening sheet

All 21 raw takes, as generated (no edits). Measured by `tools/batch3_listening.py`; every file's SHA-256 matches `evidence/batch3-generation-log.txt`. Facts only: the sheet does not rank or describe takes.

- **Peak** is the highest sample across channels; values above 0 dBFS are kept because the raw files are 32-bit float WAV (the planned edits level each pick to −1 dBFS).
- **Leading silence** is the time before the first sample above -50 dBFS (the planned trim threshold); **tail** is the time after the last one.
- Waveforms of every take: `evidence/batch3-takes-waveforms.png`.

## How to listen

- **Finder:** open `~/Documents/jellyhop-generations/audio/` (Finder → Go → Go to Folder…, paste the path), select a file and press **Space** for Quick Look; press Space again to stop. The arrow keys move to the next file.
- **Terminal:** `afplay ~/Documents/jellyhop-generations/audio/SFX-HOP-take1-seed7270.wav` plays one file.
- For the music, also listen to whether a loop could be cut from it (the planned edit cuts whole bars, at least 8 s).

## Takes

| Take | Seed | File | Length | Rate, channels | Peak | RMS | Leading silence | Tail after last sound | Device, run time |
|------|------|------|--------|----------------|------|-----|-----------------|-----------------------|------------------|
| SFX-HOP-take1 | 7270 | `SFX-HOP-take1-seed7270.wav` | 1.00 s | 44100 Hz, 2 | +2.0 dBFS | -19.0 dBFS | 36 ms | 781 ms | mps, 190 s |
| SFX-HOP-take2 | 7271 | `SFX-HOP-take2-seed7271.wav` | 1.00 s | 44100 Hz, 2 | +3.2 dBFS | -20.4 dBFS | 104 ms | 568 ms | mps, 237 s |
| SFX-HOP-take3 | 7272 | `SFX-HOP-take3-seed7272.wav` | 1.00 s | 44100 Hz, 2 | +0.9 dBFS | -19.6 dBFS | 39 ms | 763 ms | mps, 240 s |
| SFX-LAND-take1 | 7270 | `SFX-LAND-take1-seed7270.wav` | 1.00 s | 44100 Hz, 2 | +2.1 dBFS | -26.0 dBFS | 0 ms | 741 ms | mps, 253 s |
| SFX-LAND-take2 | 7271 | `SFX-LAND-take2-seed7271.wav` | 1.00 s | 44100 Hz, 2 | -3.1 dBFS | -29.3 dBFS | 77 ms | 777 ms | mps, 254 s |
| SFX-LAND-take3 | 7272 | `SFX-LAND-take3-seed7272.wav` | 1.00 s | 44100 Hz, 2 | -3.9 dBFS | -32.7 dBFS | 0 ms | 909 ms | mps, 253 s |
| SFX-WARN-take1 | 7270 | `SFX-WARN-take1-seed7270.wav` | 1.50 s | 44100 Hz, 2 | -2.0 dBFS | -26.7 dBFS | 98 ms | 790 ms | mps, 249 s |
| SFX-WARN-take2 | 7271 | `SFX-WARN-take2-seed7271.wav` | 1.50 s | 44100 Hz, 2 | +4.3 dBFS | -24.6 dBFS | 160 ms | 930 ms | mps, 249 s |
| SFX-WARN-take3 | 7272 | `SFX-WARN-take3-seed7272.wav` | 1.50 s | 44100 Hz, 2 | -2.9 dBFS | -27.8 dBFS | 370 ms | 435 ms | mps, 252 s |
| SFX-SPLAT-FORK-take1 | 7270 | `SFX-SPLAT-FORK-take1-seed7270.wav` | 1.20 s | 44100 Hz, 2 | +6.2 dBFS | -23.3 dBFS | 0 ms | 947 ms | mps, 261 s |
| SFX-SPLAT-FORK-take2 | 7271 | `SFX-SPLAT-FORK-take2-seed7271.wav` | 1.20 s | 44100 Hz, 2 | +4.7 dBFS | -29.1 dBFS | 6 ms | 1066 ms | mps, 254 s |
| SFX-SPLAT-FORK-take3 | 7272 | `SFX-SPLAT-FORK-take3-seed7272.wav` | 1.20 s | 44100 Hz, 2 | +1.8 dBFS | -28.9 dBFS | 5 ms | 1040 ms | mps, 255 s |
| SFX-SPLAT-SAUCE-take1 | 7270 | `SFX-SPLAT-SAUCE-take1-seed7270.wav` | 1.00 s | 44100 Hz, 2 | +4.7 dBFS | -27.4 dBFS | 19 ms | 741 ms | mps, 262 s |
| SFX-SPLAT-SAUCE-take2 | 7271 | `SFX-SPLAT-SAUCE-take2-seed7271.wav` | 1.00 s | 44100 Hz, 2 | +1.6 dBFS | -32.4 dBFS | 7 ms | 758 ms | mps, 262 s |
| SFX-SPLAT-SAUCE-take3 | 7272 | `SFX-SPLAT-SAUCE-take3-seed7272.wav` | 1.00 s | 44100 Hz, 2 | +7.1 dBFS | -31.4 dBFS | 12 ms | 849 ms | mps, 259 s |
| SFX-WIN-take1 | 7270 | `SFX-WIN-take1-seed7270.wav` | 2.00 s | 44100 Hz, 2 | +0.3 dBFS | -27.3 dBFS | 0 ms | 977 ms | mps, 253 s |
| SFX-WIN-take2 | 7271 | `SFX-WIN-take2-seed7271.wav` | 2.00 s | 44100 Hz, 2 | -12.6 dBFS | -32.4 dBFS | 0 ms | 543 ms | mps, 262 s |
| SFX-WIN-take3 | 7272 | `SFX-WIN-take3-seed7272.wav` | 2.00 s | 44100 Hz, 2 | -7.0 dBFS | -33.6 dBFS | 0 ms | 385 ms | mps, 252 s |
| MUS-LOOP-take1 | 7270 | `MUS-LOOP-take1-seed7270.wav` | 29.94 s | 32000 Hz, 1 | -2.8 dBFS | -18.5 dBFS | 0 ms | 0 ms | mps, 109 s |
| MUS-LOOP-take2 | 7271 | `MUS-LOOP-take2-seed7271.wav` | 29.94 s | 32000 Hz, 1 | -5.5 dBFS | -19.5 dBFS | 0 ms | 0 ms | mps, 100 s |
| MUS-LOOP-take3 | 7272 | `MUS-LOOP-take3-seed7272.wav` | 29.94 s | 32000 Hz, 1 | -3.6 dBFS | -23.6 dBFS | 0 ms | 0 ms | mps, 96 s |

## Your picks (to fill in)

For each sound: the take you choose, and your reason in your own words. If every take of a sound fails, say so; a new prompt would be appended to the prompts file as a dated note and committed before use.

| Sound | Pick (take 1, 2 or 3, or none) | Your reason |
|-------|-------------------------------|-------------|
| SFX-HOP | | |
| SFX-LAND | | |
| SFX-WARN | | |
| SFX-SPLAT-FORK | | |
| SFX-SPLAT-SAUCE | | |
| SFX-WIN | | |
| MUS-LOOP | | |

## Provisional technical selections, pending listening

Recorded word for word from Kiran's message (2026-10-03), made from this sheet's measurements before listening. These are not final picks; the table above stays empty until Kiran has compared the takes by ear (`evidence/batch3-compare-log.txt`).

SFX-HOP: take 3 — lowest peak of the three and one main transient, so I'd start with this for the repeated hop sound.
SFX-LAND: take 2 — its peak stays below 0 dBFS. Please trim the leading silence so it responds immediately to landing.
SFX-SPLAT-FORK: take 3 — lowest peak of the three. It still needs gain reduction before export.
SFX-SPLAT-SAUCE: take 2 — lowest peak of the three, making it my starting candidate for processing.
SFX-WARN: take 1 — its peak stays below 0 dBFS and it starts earlier than take 3. Please remove the leading silence.
SFX-WIN: take 3 — stronger level than take 2 without exceeding 0 dBFS.
MUS-LOOP: take 1 — its opening and ending levels are closest, making it a useful starting point for loop editing.

## Provisional technical shortlist for an in-game audition; final acceptance and listening reasons pending

Recorded word for word from Kiran's message (2026-10-03), after the comparison files in `~/Documents/jellyhop-generations/audio-compare/`. **This is not a completed listening review:** these takes are processed and wired into the game only so they can be auditioned there; final acceptance and Kiran's listening reasons come after the in-game audition.

SFX-HOP: take 3
SFX-LAND: take 2
SFX-WARN: take 1
SFX-SPLAT-FORK: take 3
SFX-SPLAT-SAUCE: take 2
SFX-WIN: take 3
MUS-LOOP: take 1

Kiran on the music: "For music, take 1 is closest to the requested 100 bpm, so I'll start there and compare its loop with take 3's cleaner measured join."
