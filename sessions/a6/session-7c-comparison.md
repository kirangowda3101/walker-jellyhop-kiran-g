No: at full frame size, r1 does not show clearer thinning from frame 70 to frame 85 than r0 does. In both strips frame 85 looks almost the same as frame 70. Most of my prediction did not come true.

## Files I read

- **r1, read just now:**
  - `/Users/kiran/Documents/walker-jellyhop-kiran-g/captures/dome_glints/r1/frame00000010.png`
  - `.../r1/frame00000012.png`
  - `.../r1/frame00000040.png`
  - `.../r1/frame00000070.png`
  - `.../r1/frame00000085.png`
  - `.../r1/frame00000145.png`
- **r0, read in my first reply and still in this conversation (not re-opened):**
  - `/Users/kiran/Documents/walker-jellyhop-kiran-g/captures/dome_glints/r0/frame00000010.png`
  - `.../r0/frame00000012.png`
  - `.../r0/frame00000040.png`
  - `.../r0/frame00000070.png`
  - `.../r0/frame00000085.png`
  - `.../r0/frame00000145.png`

I could only look at whole 1280 × 720 frames. Cropping was denied earlier, and the command to hash and compare the r0 and r1 files needed approval, so it didn't run. I compared file sizes instead (`ls -l`). The scene still has offsets `(0, 0.08, 0.75, 1)` (`dome_glints.tscn` line 26).

## Frame by frame

| Frame | My prediction | r1 compared with r0 | Match? |
|---|---|---|---|
| 10 | Same glints as r0, plus a few small bright dots low in the glass, about 16 to 18 | Same glints in the same places, about 14. I see no extra dots in the lower glass. File is 10 bytes larger | Positions yes. Extra dots **no** |
| 12 | Same as 10, drifting up | Same as r0's frame 12. File is 29 bytes larger | Yes for "same as 10". No extra dots |
| 40 | About 12 to 14 visible, still mostly over the glass | About 9, the same layout as r0, still over the glass and knob. File is 19 bytes larger | **No** on count. Yes on "still over the glass" |
| 70 | Full, with small dots through the lower glass | Same as r0. File is 8 bytes smaller | **No** |
| 85 | Lower glass visibly emptier than at 70, 3 to 5 fewer dots | Looks like frame 70, as in r0. I can't see a gap in the lower glass. File is 12 bytes smaller | **No** |
| 145 | Empty | Empty. Same file size as r0 (640,143 bytes) | Yes |

**70 → 85, the question you asked:** the file shrinks by 543 bytes in r1 and by 539 in r0. That is almost the same drop. File size is only a rough stand-in for how much is drawn, but it agrees with what I see: no clearer thinning.

**What did match:** the positions and motion are the same, as predicted. That fits the ramp affecting only colour and alpha, with the same seed (2001) giving the same random choices. The small size differences show that some pixels changed, but not enough to see at full frame.

## Why it differs from my prediction

1. **I overestimated how visible young glints would be.** The change only affects glints between 0.08 and 0.2 of their life. They now reach full alpha sooner, but `scale_curve` still grows them from zero over that stretch. At 0.08 of life they are about 1.7 to 3.6 px across, and at 0.14 about 3 to 6 px. The texture is a soft radial fade, so the bright core is smaller still. I said myself they'd be "bright but small", then predicted counts as if they'd read as dots. That was my mistake. Size limits their visibility, not alpha.
2. **So frame 85 can't thin visibly with this change alone.** Of the roughly 5 glints that go unborn between frames 70 and 85, only those older than about 0.2 s would have been more than a couple of pixels across. Leaving them out removes too little to notice.
3. **What I can't rule out:** some small dots may be there but too small for me to resolve without zooming. The 10 to 29 byte increases at frames 10, 12 and 40 point the right way but say nothing about whether a difference can be seen. A cropped, enlarged comparison would settle it.

## A side observation (inferred, not checked)

- r1 holds the whole sequence (frames 0 to 149 plus `frame.wav`), not just the six strip frames.
- Frames 0 to 9 and 128 to 149 are all exactly 640,143 bytes, the same as r0's empty frame 145. That suggests no glint was visible from frame 128 on, about 1.9 s after the stop, earlier than the longest life of 2.4 s.
- It fits glints shrinking and fading to almost nothing in their last fifth of life. But equal file size is not proof that the frames are pixel-identical.

I edited nothing.