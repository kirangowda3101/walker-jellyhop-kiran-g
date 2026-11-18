# SCRIPT — Jelly Hop: Animation Clips

Drafted by Claude Code on 2026-11-17, for Kiran's review. Narration is what Liam says; "On screen" is what the viewer sees. Every claim is sourced in FACTCHECK.md.

## B00 — cold open — the Walker ask  (~14 s)
On screen: ClaudeComposerAsk; composer, spark and greeting 'Hej, Liam'; the Walker prompt (worded from CHANGE-BRIEF.md, A7) types itself; three output lines; the first labels the prompt a reconstruction

> Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: two animation clips for Jelly Hop, a looping scoot and a committing landing. This prompt is an illustrative reconstruction. Kiran's real work comes next.

## B01 — what was built (hesitant writer)  (~12 s)
On screen: BrutalistHesitantWriter; 'Scoot loops. Land commits.' types out; 'Both clips tick on physics.' types out; 'One hand-off ran a tick late.' — 'late' turns terracotta; the writer corrects it: 'One hand-off ran a tick ahead.'

> Scoot loops. Land commits. Both clips tick on the physics clock. And one hand-off ran a tick ahead, until a test caught it. Here is how both clips were built, timed, tuned and tested.

## B02 — the game and both clips  (~30 s)
On screen: GodotDesignFigure; card 'Game' lights; card 'scoot' lights; card 'land' lights

> Jelly Hop is Kiran's game: a jelly cube hops across plates on a dinner table while forks stab down from above. Assignment seven adds two clips. Scoot is the looping cycle: two cells on a Sprite2D, held by a discrete frame track, packed from Kiran's assignment-two scoot art, seven ticks per cell, loop linear. Land is the committing action: two Sprite2D cutouts under Node2D pivots, cut from the idle drawing at row six twenty-two, keyed at frames zero, two, four and eight, loop none.

## B03 — code: the scoot sprite slices the sheet  (~18 s)
On screen: GodotDevWorkbench; line 27 highlighted; line 28 highlighted; line 29 highlighted; line 26 highlighted

> First question: what is a clip? Start with what it reads. The scoot sprite shows the sheet, and lines twenty-seven and twenty-eight slice it: h-frames two, v-frames one. Line twenty-nine starts it on frame zero. And the offset, minus five twelve, minus eight twelve, keeps each cell's bottom-centre anchor.

## B04 — result: the sheet and its slicing  (~18 s)
On screen: GodotDesignFigure; card 'Size' lights; card 'Cells' lights; card 'Packing' lights

> Here is the sheet: two thousand forty-eight by one thousand twenty-four, Kiran's assignment-two scoot drawings side by side, with no cropping. Two h-frames make two cells, each a full one-thousand-twenty-four canvas. The packing tool found zero mismatched pixels in each cell against its source.

## B05 — code: scoot.tres, a clip  (~22 s)
On screen: GodotDevWorkbench; line 11 highlighted; line 15 highlighted; line 17 highlighted; line 6 highlighted; line 5 highlighted

> A clip is a saved resource: a length, a loop mode, a step, and tracks. Line eleven names the track's target: a node path, then a property, frame. Line fifteen keys cell zero at zero and cell one at seven sixtieths of a second. Line seventeen, update one, is discrete, so each cell holds its full seven ticks. Line six, loop mode one, is loop linear, over a length of fourteen sixtieths.

## B06 — result: the frame track reading the sheet (fixture)  (~21 s)
On screen: GodotDesignFigure; card 'Fixture' lights; card 'Swap' lights; card 'Wrap' lights; card 'Kiran, in play' lights

> The result, as a fixture: Kiran's scoot preview, captured at sixty frames per second. Facing right, frame two fifty-nine is clip time point one, cell zero. Frame two sixty, at seven sixtieths, is the swap to cell one. Facing left at the wrap, the clip returns to zero and cell zero. Kiran watched five wraps in play: no pause or jerk.

## B07 — code: the track_problems check  (~19 s)
On screen: GodotDevWorkbench; line 169 highlighted; line 171 highlighted; line 172 highlighted

> Because a track names its target by path, a typo still makes a valid file. So the read-back resolves every track. Line one sixty-nine calls track problems, a function copied from the course handout. Line one seventy-one prints each problem, and line one seventy-two fails the check if there is even one.

## B08 — result: mutation M1 fails the read-back  (~19 s)
On screen: GodotDesignFigure; card 'Edit' lights; card 'Import' lights; card 'Mutated' lights; card 'Committed' lights

> Mutation one, run by Kiran: one letter dropped, so position became p o s i t o n. Godot imported it with exit zero. The read-back did not pass: track one, upper pivot has no property positon. Ninety-four checks, three failures, against one hundred thirty-five and zero on the committed clip.

## B09 — one authority: the CLAUDE.md table  (~21 s)
On screen: GodotDesignFigure; card 'Rule' lights; card 'AnimationPlayer' lights; card 'player.gd' lights; card 'Never' lights

> Second question: what does one authority mean? Kiran's project file answers with a table: exactly one writer per animated node and property. The sprite's frame and the three rig transforms belong to the AnimationPlayer alone. The facing mirror and the visibility flags belong to player dot g d. No tween, no second player, no script assignment on those targets.

## B10 — code: player.gd writes facing and visibility  (~19 s)
On screen: GodotDevWorkbench; line 201 highlighted; line 203 highlighted; line 202 highlighted; line 209 highlighted

> Here are those writes. Line two-oh-one sets the facing pivot's whole transform, its X basis facing plus or minus one. Lines two-oh-three to two-oh-five set the visibility flags from the wanted clip. Leaving a clip, line two-oh-nine only calls stop. Nothing here sets the frame or a pivot's scale.

## B11 — result: the state machine plays each clip (scripted capture)  (~13 s)
On screen: VIDEO; excerpt 1: stationary hop on plate 1, touchdown tick 293, LAND 293–300, IDLE at 301; excerpt 2: 1/16-speed replay of ticks 291–302, every engine frame; excerpt 3: scoot left, right, left (ticks 333–465); excerpt 4: 1/16-speed replay of ticks 386–396: swap at 387, wrap at 394; labelled held frame of tick 396, 3.0 s

> Scripted capture, not a playtest. A stationary hop: the landing rig shows for eight ticks, then the original sprite returns. Then scooting both ways: the facing pivot mirrors, and the cell swaps every seven ticks.

## B12 — code: player.gd requests playback  (~19 s)
On screen: GodotDevWorkbench; line 219 highlighted; line 222 highlighted; line 224 highlighted; line 227 highlighted

> And playback. While the player is disabled, during an Escape pause, line two-nineteen pauses the clip: Revision one's rule. Line two twenty-two decides an entry: a new clip, a resume, or a fresh touchdown. A steady tick, including A to B inside scoot, makes no call at all. Line two twenty-seven plays the wanted clip.

## B13 — result: an interrupt in each phase (scripted capture)  (~14 s)
On screen: VIDEO; startup: touchdown 652, press read 653, ANTIC at 653 (+1); replay 1/16 speed; active: touchdown 786, press read 789, LAND 786–788, ANTIC at 789 (+3); replay; recovery: touchdown 922, press read 928, LAND 922–927, ANTIC at 928 (+6); replay

> Three interrupts, each a separate hop with a fresh jump press. Read one tick after touchdown: one LAND frame, then the crouch. Three ticks in, the hop breaks the held squash. Six ticks in, it breaks the rise. Each hop lands on its predicted tick.

## B14 — code: the AnimationPlayer on the physics callback  (~21 s)
On screen: GodotDevWorkbench; line 66 highlighted; line 62 highlighted; line 67 highlighted

> Third question: what are the two clocks? The AnimationPlayer has its own. Line sixty-six sets callback mode process to zero: physics. Line sixty-two roots its track paths at the visuals scene, and line sixty-seven leaves autoplay empty, so only player dot g d starts a clip. Gameplay runs in physics process too, at sixty ticks a second.

## B15 — result: the one-tick hand-off error, found and fixed  (~31 s)
On screen: GodotDesignFigure; card '74fe4b5' lights; card 'fd4d855' lights; card '5c0fb9a' lights; card 'Now' lights

> Same clock, so the expected gap is zero. The first wired run said otherwise. At seven four F E four B five the state test failed: one hundred thirty-two checks, five failures. On a direct LAND to SCOOT switch, scoot showed one tick ahead, a sixtieth of a second, with cell one during an A pose. The probe at F D four D eight five five found why: play on a player already playing gets an extra sixtieth from its own update that tick. Five C zero F B nine A fixed it. Now the same log lines read zero.

## B16 — code: the Revision 2 hand-off seek  (~18 s)
On screen: GodotDevWorkbench; line 228 highlighted; line 232 highlighted; line 232 highlighted; line 234 highlighted

> The fix is Revision two. Only when the old clip was land, the new one is scoot, and this is not a resume, line two thirty-two seeks one tick early on the loop. The player's own update then lands it exactly on tick mod fourteen. Every other entry, at line two thirty-four, seeks the plain synced time.

## B17 — result: the LAND → SCOOT hand-off in play (scripted capture)  (~9 s)
On screen: VIDEO; excerpt 1: hop with D pressed 11 ticks before touchdown; touchdown 521; excerpt 2: 1/16-speed replay of ticks 519–540: LAND 521–528, SCOOT-B from 529 at 9/60 s

> The hand-off in play. The jelly lands moving, LAND holds for its eight ticks, and SCOOT starts on the next one at the synced phase.

## B18 — the phase table beside the key times  (~19 s)
On screen: GodotDesignFigure; card 'Startup' lights; card 'Active' lights; card 'Recovery' lights; card 'Keys' lights

> Fourth question: how do you design feel in frames? Kiran wrote the phase table first: startup, frames zero and one; active, two and three; recovery, four to seven, inside the existing eight-tick landing. The keys come straight from it: zero, two, four and eight sixtieths. Two and four hold the same values, so the squash holds, then eases out.

## B19 — code: land.tres track 0, Revision 3  (~20 s)
On screen: GodotDevWorkbench; line 15 highlighted; line 16 highlighted; line 18 highlighted

> This is track zero, the lower piece's scale. Line fifteen holds the key times, line sixteen the transitions: two, one, and a half. Line eighteen is where Revision three landed. After Kiran's r zero verdict, the lower height at frames two and four went from point six to point five five, a squash about forty-three game pixels tall.

## B20 — result: strips r0 and r1 at each phase boundary (fixtures)  (~21 s)
On screen: GodotDesignFigure; card 'Fixture' lights; card 'Boundaries' lights; card 'Kiran, r0' lights

> The result, as fixtures: Kiran's land preview strips, r zero above and r one below, one frame per phase boundary at thirty frames per second. Fall, impact, the deepest squash, the same squash at frame four, the eased rise, and the idle hand-off. Kiran's r zero verdict: smooth at normal speed, but the hold was easier to see frame by frame.

## B21 — the r1 reading Kiran overruled  (~24 s)
On screen: GodotDesignFigure; card 'Predicted' lights; card 'Kiran' lights; card 'Claude' lights; card 'Kept' lights

> Claude predicted r one would be about one game pixel flatter at rig frames two and four, and would look almost the same. Kiran's verdict came first: barely different at normal speed, but in Preview r one looked slightly flatter, held across both frames. Claude's comparison, afterwards, could not confirm a visible difference at frames two and four within its plus or minus two pixel estimate. Kiran overruled that reading and kept r one.

## B22 — what the tests proved  (~23 s)
On screen: GodotDesignFigure; card 'Read-backs' lights; card 'Structure' lights; card 'State' lights; card 'Edges' lights

> What the read-backs proved: land, one hundred thirty-five checks, and scoot, sixty-two, with no failures. Nodes, slices, track paths, update modes, key times and easing, all read back from the saved files. The structure test, twenty-nine. The per-tick state test, one hundred thirty-two at thirty, sixty and one forty-four frames per second. The edge test, three hundred ninety-seven at each rate: all twelve interrupt predictions matched.

## B23 — the four mutations  (~23 s)
On screen: GodotDesignFigure; card 'M1' lights; card 'M2' lights; card 'M3' lights; card 'M4' lights

> Four mutations, each in a throwaway worktree, run by Kiran. Mutation one, the renamed property, failed the land read-back. Mutation two, scoot looping switched off, failed the scoot read-back. Mutation three, a key on a cell that does not exist, failed it too. Mutation four changed nothing and imported from an empty cache: both read-backs passed, because this native rig saves its loop modes in the clips themselves.

## B24 — what no headless run can show  (~20 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted; row 6 highlighted

> And what no headless run can show. The tests say so in their own headers: nothing is drawn. So a headless pass cannot show the seam between the two pieces, whether the feet stay planted, a pop at the idle hand-off, how the hold feels at normal speed, or the contrast on the darkest and lightest backgrounds. Those took Kiran's eyes, in the running game.

## B25 — agent mistakes Kiran caught  (~25 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted; row 6 highlighted

> The agent mistakes Kiran caught. The CLAUDE dot m d draft said the test wrapper had never been edited, and lacked the A six shader clause; Kiran corrected one and restored the other. The agent expected ten baseline-only pin checks; there were nine. Read-only shell commands ran despite a wrapper-only scope. The read-backs logged formatting errors the wrapper missed. The wired visuals left scoot a tick ahead. And in chat, a pixel scan put the cut on the smile, at row six-oh-one.

## B26 — what remains uncertain  (~31 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted

> Still uncertain. Kiran's project file lists unconfirmed items written before the build. Later runs close some of them, but no realtime run of the suites is recorded, one named check runner was never read, and the A six open items were not rechecked. Pausing during LAND and resuming straight into SCOOT is untested. The fourteen baseline runs were not repeated after r one. And Kiran's reference capture held five hundred sixteen PNGs where Godot reported three hundred fifty-six: still unexplained.

## BVDT — verdict  (~54 s)
On screen: ClaudeVerdictArtifact; artifact page 'Jelly Hop — animation clips at c1bbb13'; lines land as the voice names them

> Verdict. Both clips play as the brief says: scoot synced to the player's tick, land from frame zero, every interrupt on its predicted tick, and zero ticks between the two clocks after the fix, with no failures in one thirty-five, sixty-two, twenty-nine, one thirty-two and three ninety-seven checks. Kiran wrote the brief and its three revisions, measured the landing and chose the cut, ran the sheet tool, the read-backs, the mutations and both strips, and made every verdict. Claude Code wrote the clips, the scene, the visual layer, the tests, the previews and the scripts, and made this film; Claude in chat drafted commands and prompts. The sheet is Kiran's own assignment-two art, made locally with Stable Diffusion XL Base one point oh, under the CreativeML Open RAIL plus plus M licence. Kiran's next step, in Kiran's words: I'd add a scripted test for pausing during LAND and resuming into SCOOT, the one entry no test covers yet. Shown at revision C one B B B one three.

## BHTF — your turn handoff  (~22 s)
On screen: ClaudeComposerAsk; composer returns, greeting 'Your turn.'; the prompt types itself as the voice reads it

> Your turn. Use Walker: before keying a committing action, write its phase table in frames, key it from that table, then interrupt it once in every phase with real key presses and log the pose and clip time on every tick. Writing the frames first is what let Kiran see the hold in a strip, and logging every tick is what caught one tick between two clocks that were supposed to agree. Try it on your own clip. Liam, in for Bear.

## BOUT — outro  (~5 s)
On screen: ClaudeTitleOutro; title card 'Jelly Hop: Animation Clips'

> Jelly Hop: Animation Clips. At Nik Bear Brown.

**Total: 622.967 s (10 min 23.0 s), measured: the sum of the beat durations tools/make_master.py set from the Kokoro narration and the three clip lengths.**
