# SCRIPT — Jelly Hop: Shaders and Materials

Drafted by Claude Code on 2026-10-28, for Kiran's review. Narration is what Liam says; "On screen" is what the viewer sees. Every claim is sourced in FACTCHECK.md.

## B00 — cold open — the Walker ask  (~15 s)
On screen: ClaudeComposerAsk; composer, spark and greeting 'Hej, Liam'; the Walker prompt (worded from CHANGE-BRIEF.md, A5) types itself; three output lines; the first labels the prompt a reconstruction

> Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: shaders and materials for Jelly Hop, where a jelly cube dodges forks on a dinner table. This prompt is an illustrative reconstruction. Kiran's real work comes next.

## B01 — what was built (hesitant writer)  (~11 s)
On screen: BrutalistHesitantWriter; 'A fork turns amber before it strikes.' types out; 'One wood shader, two materials.' types out; 'Every texture is colour.' — 'colour' turns terracotta; the writer corrects it: 'Every texture is information.'

> A fork turns amber before it strikes. One wood shader makes two materials. And every texture is information: what its numbers mean depends on how the shader reads them.

## B02 — the game, the state, the 3D object  (~20 s)
On screen: GodotDesignFigure; card 'Game' lights; card 'State' lights; card 'Colour' lights; card '3D' lights

> Jelly Hop is Kiran's game: a jelly cube hops across plates on a dinner table while forks stab down from above. The state is a fork's SHADOW phase, the warning before it strikes. Its steel turns gradually toward candle amber, in step with its shadow. In 3D, the A3 floor becomes a worn dinner table, beside a polished serving board.

## B03 — the colour line in the brief  (~19 s)
On screen: GodotDesignFigure; card 'Written' lights; card 'Colour line' lights; card 'Alpha' lights; card 'warning' lights

> Kiran wrote the spec before any shader. Section two of the change brief holds the colour line: mix the fork's own colour toward the warning colour, by warning times strength. Only the RGB channels change, so the fork's silhouette never does. And warning is the fork's shadow growth during SHADOW, zero in every other phase or when held.

## B04 — code: Q1, the fork shader  (~21 s)
On screen: GodotDevWorkbench; line 1 highlighted; line 4 highlighted; line 9 highlighted

> Question one: what does a shader do? Kiran's answer is this file. It runs for the fragments that make up the fork's pixels, each time the fork is drawn. Line one makes it a canvas item shader, for 2D. Line four declares warning, from zero to one. Line nine is the brief's colour line, word for word: COLOR arrives as the fork's own pixel, and leaves mixed toward amber.

## B05 — result: controlled values beside predictions  (~21 s)
On screen: GodotDesignFigure; card 'Captures' lights; card 'Match' lights; card 'warning 2.0' lights; card 'hint_range' lights

> The result, in engine. In a scripted capture, Kiran stopped the game's physics and set warning on the plate two fork: zero, a half, one and two. Every measured pixel is within one eight-bit step of the prediction. At two, the tine reads two fifty-five, one seventy-eight, thirty-seven, exactly as extrapolated: hint range does not clamp a value set from code.

## B06 — code: the driver in fork.gd  (~21 s)
On screen: GodotDevWorkbench; line 221 highlighted; line 223 highlighted; line 225 highlighted; line 231 highlighted

> The driver, written by Claude Code from Kiran's approved plan. warning, on line two twenty-one, returns zero if the fork is held or not in SHADOW; otherwise, its shadow amount. Apply runs whenever the tick counter or held changes, and line two thirty-one writes that value into this fork's own material. Each fork was given its own duplicate of the base material.

## B07 — result: the effect in play (scripted capture)  (~12 s)
On screen: VIDEO; intro pan: plates 5 and 6 forks SHADOW 0.51 / 0.52, frozen; control returns; plates 3 and 4 ramp; plate 2 ramps; plate 2 fork strikes the jelly (tick 476); warning back to 0.00; excerpt 2: state WON, forks frozen with their values

> Scripted capture, not a playtest. In the intro, the far forks start half amber. Plate two warms with its shadow, strikes, and turns silver. After the win, nothing advances: the forks hold their values.

## B08 — code: the headless driver test  (~21 s)
On screen: GodotDevWorkbench; line 143 highlighted; line 141 highlighted; line 146 highlighted

> How does the test know the right value? cycle of reads each plate's timings from the tuning file alone, never from the fork. expected at is the brief's formula. A sampler that runs after the session advances the forks compares every fork's warning with it, on every physics tick. Kiran checked that the test never advances a fork or sets the uniform itself.

## B09 — result: headless numbers  (~23 s)
On screen: GodotDesignFigure; card '30 · 60 · 144' lights; card 'Per tick' lights; card 'Ramp' lights; card 'Holds' lights

> Headless, at thirty, sixty and one forty-four frames per second: twenty-nine checks, zero failures each time. The per-tick sequence, six hundred and one ticks of five forks, has the same MD5 at all three rates. The first SHADOW tick reads one over ninety-six, the last exactly one. Plates five and six start mid-SHADOW and hold through the pan. Pause holds the value; a splat drops it to zero.

## B10 — three mutations, and what headless cannot show  (~25 s)
On screen: GodotDesignFigure; card 'Semicolon' lights; card 'Rename' lights; card 'source_color' lights; card 'Headless' lights

> Three mutations, each run by Kiran. A missing semicolon: a shader error, an empty uniform list, five failures. Renaming warning in the shader only: no error, and twenty-five of twenty-nine checks still passed, because set shader parameter quietly stores an unknown name. Only the uniform-list check caught it. Removing source colour from the wood's albedo: one of a hundred and eight failed. And no headless run draws a pixel: every judgement of colour is Kiran's eye.

## B11 — code: Q2, a material file  (~21 s)
On screen: GodotDevWorkbench; line 10 highlighted; line 12 highlighted; line 16 highlighted; line 17 highlighted

> Question two: how is a material different from a shader? This is a material, the polished serving board. Line ten points at the one table wood shader. Every other line is a value for it: the same three textures, a warm tint, roughness point three five, normal strength a half. The worn table's file points at the same shader, with a white tint, roughness one, and UV scale two.

## B12 — result: one shader, two materials  (~19 s)
On screen: GodotDesignFigure; card 'Shader' lights; card 'Shader edit' lights; card 'Material edit' lights; card 'Files' lights

> Kiran tested the difference in memory, changing no file. Edit one line of the shader, and both pieces of wood change. Edit only the board material's brightness, and only the board changes; the table stays at ninety-two, forty-five, twenty-nine. The shader is the program. A material is one set of values for it.

## B13 — code: Q3, the hint experiment  (~19 s)
On screen: GodotDevWorkbench; line 4 highlighted; line 5 highlighted; line 7 highlighted

> Question three: why is a texture information? Kiran's hint experiment binds one three-pixel grey strip, sixty-four, one twenty-eight and one ninety-two, to two samplers. Line four reads it with source colour, as colour. Line five reads the same file with no hint, as plain data. Line seven picks which one draws.

## B14 — result: hint experiment on two renderers  (~21 s)
On screen: GodotDesignFigure; card 'Predicted' lights; card 'Forward+' lights; card 'Compatibility' lights; card 'Why' lights

> The brief predicted that with source colour the quad shows the file unchanged, and without it, brighter: one thirty-seven, one eighty-eight, two twenty-five. On Forward-plus, exactly that. On the project's Compatibility renderer, both quads show the file unchanged. Kiran measured first and explained after: the difference is the renderer. Why, on Compatibility, is still unresolved.

## B15 — code: Q3, the wood samplers  (~19 s)
On screen: GodotDevWorkbench; line 5 highlighted; line 11 highlighted; line 12 highlighted

> The wood shader makes that choice for every texture. Line five: the albedo is a photo, sRGB colour, so source colour. Line eleven: roughness is data, zero a mirror, one fully rough, so no colour hint, and white if nothing is bound. Line twelve: the normal map holds slopes, so hint normal, and no source colour.

## B16 — result: the wood, and the data checks  (~20 s)
On screen: GodotDesignFigure; card 'In engine' lights; card 'test_materials' lights; card 'Curl (GL)' lights; card 'Threshold' lights

> In engine, the worn table and the board read as dark wood under the Sun. Behind that, a headless materials test checks every sampler's hints and every bound file: a hundred and eight checks, no failures. And the bound normal map is the OpenGL one: its curl ratio is point three eight, under Kiran's threshold of point seven for this texture.

## B17 — Godot's generated shader beside Kiran's  (~22 s)
On screen: GodotDesignFigure; card 'Generated' lights; card '7 ↔ 5' lights; card '19 ↔ 12' lights; card 'The hints' lights

> Godot can write this code too. Kiran converted a standard material to a shader and saved it unedited. Generated line seven marks the albedo texture source colour, matching Kiran's line five. Generated line nineteen reads the normal map without source colour, as data, matching line twelve. It says hint roughness normal where Kiran wrote hint normal; Kiran has not verified the exact difference.

## B18 — the interface sweep  (~20 s)
On screen: GodotDesignFigure; card 'As predicted' lights; card 'roughness' lights; card 'normal' lights; card 'Flat map?' lights

> The interface sweep: each wood setting at minimum, default and maximum, fifteen captures. Brightness, UV scale and tint changed as predicted. Roughness scale moved the table by at most twenty levels, with no Sun highlight, so Kiran's prediction did not hold. Normal strength moved it by at most two; a very flat map is the likely reason, not tested.

## B19 — Q4: the Godot shading language  (~22 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 4 highlighted

> Question four: what is the Godot shading language? In Kiran's words, line one, shader type, tells Godot what kind of object the shader works on and which built-ins it can use: COLOR for the 2D fork, ALBEDO and ROUGHNESS for the 3D wood, while Godot does the lighting. Hints and groups become Inspector controls. With plain GLSL, the application would have to provide that material system.

## B20 — agent mistakes Kiran caught  (~30 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted

> What the agent got wrong, and Kiran caught. Its own test read the sampler rows before the sampler had recorded the frame; it stopped twice, and Kiran approved each fix only after reading it. Its audit added a video-memory estimate nobody had measured; Kiran deleted it. Its CLAUDE.md draft needed five corrections. And it ran commands Kiran did not expect, so the real guard was an empty shader diff after every session. It also got one right: the audit corrected Kiran's spec on UV scale.

## B21 — what remains uncertain  (~21 s)
On screen: GodotDevWorkbench; row 1 highlighted; row 2 highlighted; row 3 highlighted; row 4 highlighted; row 5 highlighted

> Still uncertain, in Kiran's own list. Why Compatibility shows the strip unchanged with and without source colour. The exact difference between the two normal hints. Whether the table's tint is converted to linear. Whether the flat map is why normal strength shows nothing. And why a fresh-cache import crashes on an A2 sound file; the workaround is to import twice.

## BVDT — verdict  (~45 s)
On screen: ClaudeVerdictArtifact; artifact page 'Jelly Hop — shaders and materials at 77a6d10'; lines land as the voice names them

> Verdict. The fork warns in amber from its own tick counter: twenty-nine checks at three frame rates with one per-tick sequence, and captured pixels within one step of Kiran's predictions. One shader makes two materials. Two predictions did not hold: the hint values on Compatibility, and the roughness highlight. Kiran wrote the brief and its revisions, hand-wrote all three shaders, made the materials, and ran every human check and mutation. Claude Code wrote the driver, both tests, the audit and this film; Claude in chat wrote the capture scripts and organised the notes. The textures are Poly Haven's Dark Wood, CC zero, by Dario Barresi, Dimitrios Savva and Rico Cilliers. One next step, proposed from the open items: measure whether the table's tint is converted to linear. Shown at revision seven seven A six D one zero.

## BHTF — your turn handoff  (~23 s)
On screen: ClaudeComposerAsk; composer returns, greeting 'Your turn.'; the prompt types itself as the voice reads it

> Your turn. Use Walker: before writing a shader, put one uniform's job into your brief with predicted values for two pixels, write the shader yourself, capture those pixels in engine, then run one mutation you expect your test to miss. Tell me which result surprised you. Predicting first is what made Kiran's Compatibility result a finding, not a mistake. And pick a mutation you think will slip through: Kiran's rename nearly did. Liam, in for Bear.

## BOUT — outro  (~5 s)
On screen: ClaudeTitleOutro; title card 'Jelly Hop: Shaders and Materials'

> Jelly Hop: Shaders and Materials. At Nik Bear Brown.

**Total: 518.567 s (8 min 38.6 s), measured: the sum of the beat durations tools/make_master.py set from the Kokoro narration and the B07 clip length.**
