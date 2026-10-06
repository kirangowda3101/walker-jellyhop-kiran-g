# SCRIPT — Jelly Hop: Fork From Above

Draft for Kiran's script review (Batch 2). Narration is what Liam will say; "On screen" is what the viewer sees. Times are estimates until Kokoro measures them. Items marked **[DECIDE]** need your call.

## B00 — cold open — the Walker ask  (~19 s)
On screen: ClaudeComposerAsk; composer, spark and greeting 'Hej, Liam'; the Walker prompt (wording from CONCEPT.md) types itself; running indicator: 'reading CONCEPT.md…'; three output lines; the first labels the prompt a reconstruction

> Hej — this is Liam, in for Bear. The ask, rebuilt for the camera: a jelly cube hopping across dinner plates toward a dessert dome while giant forks strike from above, as a playable Godot slice. The prompt is an illustrative reconstruction. Everything after it is the real project.

## B01 — what was built (hesitant writer)  (~14 s)
On screen: BrutalistHesitantWriter; 'A jelly cube crosses six plates.' types out; 'The shadow gives the warning.' types out; 'The scrape plays as shadows grow.' — 'shadows', then 'grow', turn terracotta; the writer corrects them to 'forks' and 'descend': 'The scrape plays as forks descend.'

> One level: six plates, five forks, a glass dome at the end. The shadow gives the warning; the scrape plays as the fork starts descending. That last line came from a playtest, not the design.

## B02 — concept and pillars  (~22 s)
On screen: GodotDesignFigure; held frame of the intro pan: title, frozen forks, plates, sauce; pillar card 1 lights; pillar card 2 lights; pillar card 3 lights; pillar card 4 lights

> A jelly cube left on the table after a party; the dome is safety. Four pillars. Read the shadow, then commit. Wobbly and alive. Small in a giant world. Every splat teaches: a hit costs about a second and a quarter, then you're back on the last plate you landed on. A held frame from the intro pan.

## B03 — asset trace 1: design → prompt → raw output  (~21 s)
On screen: GodotDesignFigure; design guide panel; prompt and settings panel; raw output panel, labeled 'not in-engine', 'unedited'

> One asset, start to finish: the jelly. The design: the character sheet's front view, as a guide on flat magenta. The prompt, run locally: SDXL Base one point oh, image to image at sixty percent. On the right, the raw output, untouched. A text-only try had grown legs and a tongue; the guide kept the cube.

## B04 — asset trace 2: edits → game file → engine  (~21 s)
On screen: GodotDesignFigure; raw zoom with the two speck boxes; after speck removal; magenta cut-out on a checkerboard; in-engine crop from run-01

> Two stray dots came with it. A logged script filled nineteen hundred and fifty-four pixels in two boxes, nothing outside them. The magenta was cut out, the file copied into the project byte for byte, and player dot g d, line fifty-four, loads it by name. Last panel: the same jelly in the 4K capture.

## B05 — code: choose_pose()  (~22 s)
On screen: GodotDevWorkbench; line 149 highlighted; lines 151-153 highlighted; line 155; line 157; line 159; line 161

> Twelve poses, one function, and the order is the design. The session's override wins first: splat, respawn, celebrate. In the air, a crouch for the first few ticks, then rise or fall by the sign of vertical speed. Then the landing squash, the scoot while moving, worry while this plate's shadow grows, and bored after four seconds without input.

## B06 — result: poses in the running slice  (~12 s)
On screen: VIDEO; pose SCOOT-A; pose SCOOT-B; pose SCOOT-A; pose SCOOT-B; pose SCOOT-A; pose IDLE; pose ANTIC; pose RISE; pose FALL; pose LAND; pose SCOOT-A; pose SCOOT-B; pose SCOOT-A; pose WORRY; pose IDLE; pose SPLAT; pose RESPAWN; pose IDLE; pose SCOOT-A; pose SCOOT-B; pose SCOOT-A; pose SCOOT-B; pose IDLE; pose WORRY; pose ANTIC; pose RISE; pose FALL; pose LAND; pose SCOOT-A; pose SCOOT-B; pose SCOOT-A; pose SCOOT-B; pose WORRY; pose ANTIC; pose RISE; pose FALL; pose LAND; pose SCOOT-B; pose SCOOT-A; pose SCOOT-B; pose SCOOT-A; pose ANTIC; pose RISE; pose FALL; pose LAND; pose SCOOT-B

> Watch the label at the bottom. Scoot, crouch, rise, fall, land. On plate two it waits under the shadow, worried. The fork lands: splat. It re-forms on the same plate, then hops on.

## B07 — code: the scrape fix (cause)  (~21 s)
On screen: GodotDevWorkbench; note panel: the old line 'if fork and fork.advance():'; Kiran's audition note on screen; line 295 highlighted; line 299 highlighted

> Now a cause. Before commit two-three-a-e, this loop played the scrape whenever an on-screen shadow started to grow, a second or more before the fork moved. Kiran wrote: the fork sound plays randomly. Now it fires only on the tick a fork starts down, and only for the jelly's plate or the next one.

## B08 — result: heard only when a fork falls (effect)  (~23 s)
On screen: GodotDesignFigure; before bars; fix 1 bars; fix 2 bars, zero idle scrapes; the three capture frames: shadow, descent + SFX-WARN, hit

> The effect, on one scripted route. Before: twenty-two scrapes, sixteen with no fork moving. After the first change, nine. After the second, eight, each on the tick its fork starts down. In our capture, the scrape fires at tick four sixty-nine, the tines land seven ticks later. Kiran's verdict: this looks good actually. Now the slice's own sound, with no narration.

## B09 — slice audio, no narration (premixed master)  (~12 s)
On screen: VIDEO; SFX-HOP @ tick 323, SFX-LAND @ tick 364, SFX-WARN @ tick 379, SFX-WARN @ tick 469, SFX-SPLAT-FORK @ tick 476, SFX-WARN @ tick 619; SFX-LAND @ tick 1028, SFX-HOP @ tick 1058, SFX-WIN @ tick 1091; SFX-HOP @ tick 143, SFX-LAND @ tick 184, SFX-WARN @ tick 199, SFX-SPLAT-SAUCE @ tick 217

> *(no narration — the slice's own engine audio, via the premixed master)*

## B10 — tests and the human playtest  (~22 s)
On screen: GodotDevWorkbench; suite output lines; Kiran's playtest notes on the right

> What was tested. On a clean snapshot of this revision: twenty-five mechanics checks, twelve keyboard, sixty-one slice, eight game audio, zero failures. That's logic under scripted input, some with fixtures, not feel. Feel rests on one human. Kiran played with sound on, then muted, and wrote: I can see the clues like the shadow keep increasing on the plate.

## BVDT — verdict  (~56 s)
On screen: ClaudeVerdictArtifact; artifact page 'Jelly Hop — vertical slice at 7a48ea8'; lines land as the voice names them

> Verdict. The slice works end to end, and all six sound events fire in real play, under scripted input, not a human session. Uncertain: one playtester on one Mac, the face at sixty-four pixels, collision boxes that differ from the sheet. On the art: plate, sauce, fork and dome are SDXL at fifty percent over guides drawn by Claude's script, changing four to nineteen percent of their pixels; room and table were text to image; and the batch-two prompts file was restored after generation. SDXL made the art, Stable Audio Open the sound effects, MusicGen-small the music. Kiran made the design decisions, ran the image generations, chose the assets, reviewed and playtested. Claude chat drafted documents and prompts; Claude Code did the implementation, the audio generation and this film. Kiran's next step: a second level that introduces new fork rhythms gradually, then combines them into more challenging timing decisions.

## BHTF — your turn handoff  (~30 s)
On screen: ClaudeComposerAsk; composer returns, greeting 'Your turn.'; the prompt types itself as the voice reads it

> Your turn. Use Walker on my Godot slice: pick one sound event, write down the exact tick you predict it fires on a scripted route, then add a trace that proves or disproves the prediction. Change the trigger only if the trace and a human playtest agree. Prediction first, so the trace can prove you wrong. And the change waits for a human ear, because this film's own fix started with a playtest note. Liam, in for Bear.

## BOUT — outro  (~4 s)
On screen: ClaudeTitleOutro; title card 'Jelly Hop: Fork From Above'

> Jelly Hop: Fork From Above. At Nik Bear Brown.

**Estimated total: 5.0 min** (299 s).
