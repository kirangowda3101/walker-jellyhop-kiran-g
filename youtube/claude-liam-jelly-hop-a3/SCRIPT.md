# SCRIPT — Jelly Hop: Three 3D Assets

Drafted unattended by Claude Code on 2026-10-13, for Kiran's review. Narration is what Liam says; "On screen" is what the viewer sees. Every claim is sourced in FACTCHECK.md.

## B00 — cold open — the Walker ask  (~16 s)
On screen: ClaudeComposerAsk; composer, spark and greeting 'Hej, Liam'; the Walker prompt (worded from CHANGE-BRIEF.md, A3) types itself; running indicator: 'reading CHANGE-BRIEF.md…'; three output lines; the first labels the prompt a reconstruction

> Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: three simple 3D assets for Jelly Hop, where a jelly cube dodges forks on a dinner table. This prompt is an illustrative reconstruction. Kiran's real prompt and screenshots come next.

## B01 — what was built (hesitant writer)  (~13 s)
On screen: BrutalistHesitantWriter; 'Three 3D assets for Jelly Hop.' types out; 'Built in Blender through the MCP.' types out; 'Claude chose the final dome colours.' — 'Claude' turns terracotta; the writer corrects it: 'Kiran chose the final dome colours.'

> A fork, a dessert dome and a biscuit platform, built in Blender by Claude Code through the MCP, then checked in Godot. One correction already: the final dome colours are Kiran's, set by hand.

## B02 — the three assets and why the game needs each  (~17 s)
On screen: GodotDesignFigure; fork card lights; dome card lights; platform card lights; scale card lights

> Why each one. The fork is the hazard: it stabs down from above, so the jelly has to time its jumps. The dessert dome is the goal at the end of the level. The biscuit is a stepping stone to land on, planned for future levels. Every size is set against the half-metre jelly: the fork is three jellies tall.

## B03 — Kiran's prompt to Claude (screenshot 23)  (~17 s)
On screen: GodotDesignFigure; brief card lights; numbers card; plan-first card; off card

> Kiran's own screenshot: the fork prompt to Claude Code. It names Walker's loop and points at the brief, then repeats its numbers: half a metre wide, one and a half tall, six boxes, a budget of a hundred triangles. Then: propose the steps; do not build yet. No asset libraries, no generators.

## B04 — what Claude Code built (screenshot 12)  (~18 s)
On screen: GodotDesignFigure; plan card; Kiran card; tris card; checked card

> What it built, again Kiran's screenshot. Claude's plan: four prongs, a head and a handle, six boxes, all five centimetres deep. Kiran accepted it. The status bar reads Tris seventy-two, under the budget of a hundred, and Kiran checked that the fork points down with its tips at the origin.

## B05 — Kiran's hand edit (screenshots 13, 14, 15)  (~22 s)
On screen: GodotDesignFigure; screenshot 13 card; pink card; red/cream card; slip card

> The hand edit. In Material Preview the dome looked washed out: the cover nearly white-lavender, the cherry salmon. Kiran opened the Material tab and raised the cover's saturation from about point one eight to point four five, then darkened the cherry and warmed the cream. One slip on the way: a value went into the wrong field and the cherry turned blue, so Kiran restored the original before redoing it.

## B06 — code: the showcase scene  (~18 s)
On screen: GodotDevWorkbench; line 27 highlighted; line 30; line 32; line 35

> Now Godot. The showcase scene is a small text file. Each asset is an instance of its exported glb, set side by side: the platform at minus two point five, the dome at the origin, the fork at one point five. And a half-metre cube at three: a size reference for the jelly, not an asset.

## B07 — result: the three assets in Godot (screenshot 19)  (~17 s)
On screen: GodotDesignFigure; order card; upright card; Kiran's words card; limit card

> Run Current Scene, Kiran's screenshot through the scene camera. Biscuit, dome, fork and the reference cube, standing upright on the floor. Kiran wrote: at this size, I can recognise the fork, dessert dome, and sandwich biscuit. And noted that the dark sides hide some detail.

## B08 — code: the headless check  (~18 s)
On screen: GodotDevWorkbench; line 7 highlighted; line 9; line 10

> The check. Line seven: expected values come from the brief, never from the files checked. Blender is Z-up and Godot is Y-up, so each row is the brief turned on its side: the fork's height, one and a half, moves to the middle. Each row also carries the budget and the count Kiran read in Blender.

## B09 — result: headless numbers beside the brief  (~19 s)
On screen: GodotDesignFigure; sizes card; triangles card; summary card; limit card

> Run headless, numbers only, beside the brief. Every size matches within a millimetre. Triangles: seventy-two, two sixty-six and thirty-six, all under budget. Each lowest point sits on the floor. Thirty-six checks, zero failures, exit code zero. Nothing is rendered, so it says nothing about colour or look.

## B10 — what Kiran checked and what remains uncertain  (~25 s)
On screen: GodotDevWorkbench; Kiran's checks on the left; uncertain items on the right

> What Kiran checked by eye: sizes in Blender's sidebar, triangles in the status bar, the scene through its camera, and the undersides with the floor hidden. Still uncertain: with one light and no environment the shaded sides are pure black; the fork tips were not checked close up; a fresh run of the dome script brings back Claude's colours; and the placements. Read from the A2 code, the dome sits on the table, not on a final platform. Kiran has not confirmed that yet.

## B11 — what Claude got wrong  (~20 s)
On screen: GodotDevWorkbench; four items on the left; Kiran's responses on the right

> What Claude got wrong. Its dome colours were washed out; Kiran fixed them by hand. Its first plan had the cherry touching the cover at one point; Kiran had it sunk four centimetres in. It removed an unused material and set fake users, steps its plan never mentioned, and reported both afterwards. And it flagged its own cherry test as weak.

## BVDT — verdict  (~38 s)
On screen: ClaudeVerdictArtifact; artifact page 'Jelly Hop — three 3D assets at 948ab6a'; lines land as the voice names them

> Verdict. Three assets on brief: sizes, origins, upright, under budget, and thirty-six headless checks with no failures. Uncertain: the black sides, the fork tips, the dome script's colours and the placements. Kiran wrote the brief and every number in it, approved each plan and each Blender call, made the hand edit, and did every human check. Claude Code wrote and ran the Blender code, the Godot scene and the check, and made this film; Claude chat guided Kiran and organised the notes. One next step, from the open items: decide where the dome goes, on the table or on a final platform, before these assets enter a level. Shown at revision nine four eight A B six A.

## BHTF — your turn handoff  (~22 s)
On screen: ClaudeComposerAsk; composer returns, greeting 'Your turn.'; the prompt types itself as the voice reads it

> Your turn. Use Walker with the Blender MCP: write one new asset's size, origin and triangle budget into your brief first, predict one way it could go wrong, ask Claude for a plan before any Blender call, then check it in Godot with a headless size check and your own eyes, from below too. Predict first, so the check can prove you wrong. And look underneath: that is where this project still has open questions. Liam, in for Bear.

## BOUT — outro  (~5 s)
On screen: ClaudeTitleOutro; title card 'Jelly Hop: Three 3D Assets'

> Jelly Hop: Three 3D Assets. At Nik Bear Brown.

**Total: 284.133 s (4 min 44.1 s), measured: the sum of the beat durations tools/make_master.py set from the Kokoro narration; the exported film matches it (MEDIA.md).**
