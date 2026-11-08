# SCRIPT — Jelly Hop: Particle Effects

Drafted by Claude Code on 2026-11-08, for Kiran's review. Narration is what Liam says; "On screen" is what the viewer sees. Every claim is sourced in FACTCHECK.md.

## B00 — cold open — the Walker ask  (~15 s)
On screen: ClaudeComposerAsk; composer, spark and greeting 'Hej, Liam'; the Walker prompt (worded from CHANGE-BRIEF.md, A6) types itself; three output lines; the first labels the prompt a reconstruction

> Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: two particle effects for Jelly Hop, a crumb puff on every landing and sugar glints over the goal. This prompt is an illustrative reconstruction. Kiran's real work comes next.

## B01 — what was built (hesitant writer)  (~13 s)
On screen: BrutalistHesitantWriter; 'A landing throws a crumb puff.' types out; 'The dome glints until you win.' types out; 'A headless run times the GPU.' — 'GPU' turns terracotta; the writer corrects it: 'A headless run times the CPU only.'

> A landing throws a crumb puff. The dome glints until you win. And a headless run times the CPU only, so it cannot price either effect's GPU work. Here is how both were built, tuned and tested.

## B02 — the game and both effects  (~21 s)
On screen: GodotDesignFigure; card 'Game' lights; card 'Effect A' lights; card 'Effect B' lights; card 'Both' lights

> Jelly Hop is Kiran's game: a jelly cube hops across plates on a dinner table while forks stab down from above. Effect A is the landing crumb puff. Its event is player dot just landed, read while the state is PLAYING: the same tick that plays the landing sound. Effect B is the dome's sugar glints. Its job is ambience, and its condition is simply that the state is not WON.

## B03 — emission, process, draw  (~24 s)
On screen: GodotDesignFigure; card 'Emission' lights; card 'Process' lights; card 'Draw' lights

> Every particle system has three parts. Emission decides when, and how many, are born: line sixty-nine of the land puff scene sets explosiveness to one, so all sixteen crumbs are born on the landing frame. Process moves each particle, every frame: line three forty-three of the generated process shader starts the force with gravity. Draw decides what each one looks like: line sixty-five gives every crumb its gradient texture.

## B04 — why a low headless CPU cost is expected, and what was measured  (~31 s)
On screen: GodotDesignFigure; card 'Process' lights; card 'Headless' lights; card 'Measured' lights; card 'GPU' lights

> That split predicts the price. On a GPU particles node, the process step is a particles shader that runs on the GPU, and a headless run measures CPU time only, so a low headless CPU cost is expected. What Kiran measured: none of the three effect cases could be distinguished from the effects-off baseline within the observed spread. That is not a measured zero. And the run did not establish what ran on the GPU: its log reports open G L three, and the dummy-renderer statement is still unconfirmed.

## B05 — Effect A: the intent block  (~24 s)
On screen: GodotDesignFigure; card 'Phases' lights; card 'Contrast' lights; card 'Scale' lights; card 'Layer' lights

> Kiran wrote Effect A's intent before any scene existed. Three phases, counted in thirty-frames-per-second frames from the landing: impact by frame two, a fast sideways kick to about one jelly width by frame five, and a settle that is gone by frame twelve. Each crumb has a light cream core and a dark brown rim, so it reads on the pale plate and on the dark table. Six to twelve pixels, drawn behind the jelly.

## B06 — code: the LandPuff emitter node  (~19 s)
On screen: GodotDevWorkbench; line 64 highlighted; line 67 highlighted; line 69 highlighted; line 63 highlighted; line 65 highlighted

> The emitter node, written by Claude Code from the brief's table. Amount sixteen. One shot true: one burst, then done. Explosiveness one: all sixteen at once. Emitting is false in the file; the driver turns it on at the landing. And line sixty-five is the draw side: the crumb texture, a gradient defined inside this same file.

## B07 — result: strip r0 and Kiran's verdict  (~20 s)
On screen: GodotDesignFigure; card 'Fixture' lights; card 'Frame 12' lights; card 'Frame 15' lights; card 'Frame 20' lights

> The result, as a fixture: Kiran's preview scene with two still jellies, captured by Movie Maker as strip r zero. Kiran's verdict, given before Claude read anything: at frame twelve the puff was easy to see on both the plate and the table. But at frame fifteen most crumbs were still under the jellies, with no wide sideways fan. By frame twenty, gone.

## B08 — code: the Revision 1 radial curve  (~20 s)
On screen: GodotDevWorkbench; line 16 highlighted; line 19 highlighted; line 16 highlighted

> Revision r one changes one setting: the radial acceleration curve, the sideways push. In r zero the push faded from the very start. Now line sixteen holds it at full strength until eighteen percent of life, then drops it to zero by twenty. Claude first proposed doubling the push range; Kiran chose this curve-only alternative instead.

## B09 — result: r1 prediction, strips, comparison, verdict  (~23 s)
On screen: GodotDesignFigure; card 'Predicted' lights; card 'Strip' lights; card 'Cause' lights; card 'Kiran' lights

> Claude predicted that frame twelve would still be mostly behind the jelly, and that frame fifteen would reach at most about forty pixels. The strips disagreed: at frame twelve crumbs were already five to fifteen pixels past both edges, and at fifteen up to forty-nine. Claude traced the miss to a one-frame offset in its own model. Kiran's verdict in the running game: kept, because the puff was easy to see on landing.

## B10 — code: the Effect A trigger in effects_driver.gd  (~18 s)
On screen: GodotDevWorkbench; line 21 highlighted; line 22 highlighted; line 23 highlighted; line 24 highlighted; line 25 highlighted; line 26 highlighted

> Now the trigger. The driver runs after the session every tick, and line twenty-one is the same condition that plays the landing sound: state PLAYING, and just landed. Each landing gets a new instance, parented to the session, placed at the jelly's feet, freed when it finishes, and only then set emitting.

## B11 — result: Effect A in play (scripted capture)  (~16 s)
On screen: VIDEO; excerpt 1: plate 1; the solo hop lands at tick 313 (puff at the feet); back up, run, hop: landing at plate 1's edge (tick 449), table landing (tick 458), 2 nodes; excerpt 2: labelled 1/4-speed replay of ticks 440–490; excerpt 3: the route over plates 1–5, a puff at every landing

> Scripted capture, not a playtest. One hop, one puff at the feet. Then the quick repeat: a running hop to the plate's edge, a scoot off, and a drop to the table nine ticks later. Two puff nodes were alive at once; whether their crumbs visibly overlap is still unverified.

## B12 — Effect B: the intent block  (~21 s)
On screen: GodotDesignFigure; card 'Job' lights; card 'Start' lights; card 'Stop' lights; card 'Not in A' lights

> Effect B's intent. Ambience: about twenty-four glints at a time, each drifting upward over two point four seconds, sugar white turning pale gold. Full from the very first frame, with no fill-in. At the win, no new glints; the live ones rise and fade. And the feature Effect A does not use: a box emission shape across the dome's glass, with an additive draw material.

## B13 — code: box emission and the additive material  (~22 s)
On screen: GodotDevWorkbench; line 34 highlighted; line 35 highlighted; line 40 highlighted; line 34 highlighted

> Here is the box. Line thirty-four sets the emission shape to three, a box, and line thirty-five makes it seventy by forty-five pixels each way from the centre, so a glint can be born anywhere across the glass. A slight negative gravity drifts them upward. The draw side is additive: line sixteen's canvas item material uses blend mode add, so glints brighten whatever is behind them.

## B14 — result: strip r0 and Kiran's verdict  (~21 s)
On screen: GodotDesignFigure; card 'Frame 10' lights; card 'Frame 40' lights; card 'Frame 85' lights; card 'Claude' lights

> The fixture strip, r zero: the dome preview restarts the glints at frame ten and stops emission at seventy. Kiran's verdict: glints already visible at frame ten, more of them there than at frame forty, no thinning noticed by frame eighty-five, and none left at one forty-five. Claude, reading the same frames, found the brief's slow fade-in at odds with its own frame-eighty-five target.

## B15 — code: the Revision 2 colour ramp  (~16 s)
On screen: GodotDevWorkbench; line 26 highlighted; line 27 highlighted

> Revision r one moves one point of the colour ramp. Its second offset goes from point two to point zero eight, so each glint reaches its peak alpha, point eight five, at eight percent of its life instead of twenty. The colours and the scale curve are unchanged.

## B16 — result: r1, the reading Kiran overruled  (~22 s)
On screen: GodotDesignFigure; card 'Predicted' lights; card 'cmp' lights; card 'Claude' lights; card 'Kiran' lights

> Claude predicted more visible glints: sixteen to eighteen at frame ten. Kiran's byte comparison showed the render did change. But at full frame size Claude saw no visible difference from r zero, and called its count prediction its own mistake. Kiran overruled that reading: in the running game the glints were noticeably easier to see in the intro, so r one was kept. The frame-eighty-five thinning was still not met.

## B17 — code: Effect B start, stop and replay in effects_driver.gd  (~20 s)
On screen: GodotDevWorkbench; line 28 highlighted; line 31 highlighted; line 33 highlighted; line 33 highlighted; line 29 highlighted

> The driver acts only when the state enters or leaves WON. Entering it, line thirty-one stops emission; the node stays, so live glints finish. Leaving it on a replay, line thirty-three calls restart on the same emitter. Its comment says preprocess applies again; that is still unverified. Pause, Esc and hiding never reach this code.

## B18 — result: Effect B in play (scripted capture)  (~13 s)
On screen: VIDEO; excerpt 1: intro, tick 1, glints already present (crop 2×); excerpt 2 (full frame): landing on plate 6, dome on screen; Esc at tick 1059: PAUSED, the glints keep drifting; Esc again at 1181; WON at tick 1233: emitting false; the glints thin out; excerpt 3: replay at tick 1384, emitting true (logged), dome off screen; labelled held frame of the replay, 2.5 s

> Scripted capture again. The intro opens on a dome that is already glinting. Esc pauses the session, and the glints keep drifting. At the win, emission stops and they thin out. On replay, the dome is off screen.

## B19 — start, stop and pause: where each was shown  (~23 s)
On screen: GodotDesignFigure; card 'Load · WON' lights; card 'Replay' lights; card 'Esc' lights; card 'Tree · hide' lights

> Here is where each behaviour was shown. On from load, and the stop on the WON tick: the headless state test, over two real-key runs, and this capture. The restart on replay: emitting true on the first tick after each replay, headless; in play, not yet verified. Esc pause: headless, and in Kiran's play. Tree pause and hiding come from the headless test alone: emitting stays true, and a tree-paused emitter does not process.

## B20 — two lines of Godot's generated process shader  (~25 s)
On screen: GodotDesignFigure; card 'Generated' lights; card 'Line 145' lights; card 'Line 254' lights

> Kiran converted the puff's process material into a shader and saved Godot's output unedited; the game does not use it. Line one forty-five picks each particle's starting speed between the minimum and the maximum, with a seeded random value: the brief's thirty to sixty. Line two fifty-four scales the radial push by the curve, sampled at the particle's lifetime percentage: Kiran's revision one curve, held at one until point one eight, zero by point two.

## B21 — what the tests proved  (~23 s)
On screen: GodotDesignFigure; card 'Config' lights; card 'State A' lights; card 'State B' lights

> What the tests proved, each run by Kiran at sixty frames per second. The two config tests read every setting back: fifty-one checks and forty-five, no failures. The Effect A state test, twenty-four checks: one puff per landing sound, on the same tick, at the feet to zero point zero pixels. The Effect B state test, twenty-seven: emitting equals not WON on all sixteen hundred sixty-seven ticks.

## B22 — two mutations that failed the config test  (~23 s)
On screen: GodotDesignFigure; card 'Godot 3 name' lights; card 'Drift' lights; card 'Lesson' lights

> Two mutations, each a one-line edit that Kiran made and then restored. A Godot three name, initial velocity instead of initial velocity min: Godot printed nothing, the puff still fired in the preview, and the config test failed, reading zero instead of thirty. Then spread changed to forty-five while the brief still said thirty: exactly one failure. A firing puff was not proof that its settings had loaded.

## B23 — both prices against the budgets  (~25 s)
On screen: GodotDesignFigure; card 'CPU' lights; card 'Budget' lights; card 'GPU' lights; card 'Verdict' lights

> Both prices, against the budgets. Headless CPU: unresolved, every effect inside the run-to-run spread. GPU: the brief's budget is a quarter of a millisecond per effect. On the shipped Compatibility renderer the Visual Profiler showed CPU timings, but every GPU reading was zero point zero and the graph was blank. A labelled Forward-plus comparison did the same. So GPU timing was unavailable, and both budgets are unverified.

## B24 — what no headless run can show  (~18 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted

> And what no headless run can show: that a crumb or a glint is drawn at all; the timing phases, the scale, the contrast and the variation; whether two puffs' crumbs visibly overlap; a pop at the screen edge; or whether restart refills the dome. Those are checks for eyes on the running game, and several are still open.

## B25 — agent mistakes Kiran caught, and the reading overruled  (~24 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted; row 6 highlighted

> The agent mistakes Kiran caught. The brief draft said the headless test would show both puffs emitting. The plan connected finished after emission; Kiran moved it first. The first state-test route ran off plate one. The cost script briefly allowed a third puff, found by a separate checker. And the shader explanation got its two branches wrong. One strip reading Kiran overruled: Effect B r one, which Claude saw as no different.

## B26 — what remains uncertain  (~20 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted

> Still uncertain, from Kiran's own lists. Whether restart re-applies preprocess, and whether the dome is full right after a replay. Whether two puffs' crumbs visibly overlap, and the real gameplay peak. The frame-eighty-five thinning. Whether headless uses a dummy renderer, and whether the ring collapses at spawn. And usable GPU timing on either renderer.

## BVDT — verdict  (~55 s)
On screen: ClaudeVerdictArtifact; artifact page 'Jelly Hop — particle effects at 8004dea'; lines land as the voice names them

> Verdict. Both effects fire where the brief says: one puff per landing sound, glints off exactly while WON, with fifty-one, forty-five, twenty-four and twenty-seven checks and no failures. The prices are unresolved: CPU inside the spread, GPU timing unavailable, both budgets unverified. Kiran wrote the brief and both revisions, made every verdict, ran every test, mutation and profiler run, and started all four strip captures. Claude Code built the effect scenes, the driver, the tests and the cost script, and made this film; Claude in chat drafted the brief's wording and wrote the peak checker. The textures are two gradient textures defined in the scene files: no third-party textures. Kiran's next step, in Kiran's words: I'd check whether the dome glints are already full immediately after an in-game replay. The preview showed full glints by frame 10, but I haven't checked that in live play. Shown at revision eight zero zero four D E A.

## BHTF — your turn handoff  (~28 s)
On screen: ClaudeComposerAsk; composer returns, greeting 'Your turn.'; the prompt types itself as the voice reads it

> Your turn. Use Walker: before tuning a particle effect, write what frames 2, 5 and 12 should show, capture a fixed-seed strip, predict exactly what one setting change will move, capture again, and tell me which frame proved my prediction wrong. Writing frames first is what let Kiran see crumbs stuck under the jelly at frame fifteen, and what showed that Claude's own prediction was one frame off. Run it on your own effect, and watch which frame surprises you. Liam, in for Bear.

## BOUT — outro  (~5 s)
On screen: ClaudeTitleOutro; title card 'Jelly Hop: Particle Effects'

> Jelly Hop: Particle Effects. At Nik Bear Brown.

**Total: 647.700 s (10 min 47.7 s), measured: the sum of the beat durations tools/make_master.py set from the Kokoro narration and the two clip lengths.**
