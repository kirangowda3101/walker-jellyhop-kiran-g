# FRICTIONAL — Jelly Hop: Fork From Above

Dated log of the design thinking for CSYE 7270, Assignment 2 (project `walker-jellyhop-kiran-g`).

Entries are added in order. Earlier entries are not rewritten; corrections and changes of mind go in new, dated entries.

**Contribution key** used in every entry:
- **Kiran (me):** ideas, decisions, reasons, judgments, hand edits
- **Claude:** reviews, option lists, trade-offs, plans, prompts, code, organizing my notes
- **Generative models:** art, sound, and music outputs (named with version in each entry)

---

## 2026-10-01 — Concept decisions, before any generation

**Status:** I deleted my earlier project folder and started fresh. So far I have created the project folder `~/Documents/walker-jellyhop-kiran-g`. No generative model has been used, and no assets or code exist.

**Wanted (my original pitch):**
A 2D side-view platformer. The player is a small jelly cube left on a dinner table after a party. It hops across plates and cups to reach a glass dessert dome while giant forks strike from above. A growing shadow warns the player before each strike, so they can move, wait, or jump back. Getting hit causes a quick splat and a respawn on the last safe plate. The atmosphere should feel slightly tense but playful: a bright, wobbly jelly against a dim table and sharp steel forks.

**Asked:** Claude (claude.ai chat) to check the concept against the Assignment 2 requirements and to ask me about the open design choices. Claude asked one question at a time and offered options with trade-offs. I chose each option and gave my reasons.

**Decided:**

| # | Decision | Options considered | My choice | My reason |
|---|----------|--------------------|-----------|-----------|
| 1 | How forks choose where to strike | Chase the jelly · fixed rhythm per plate · random plates · fixed rhythm plus one tracking fork | **Fixed rhythm per plate** (shadow grows → strike → safe window) | Fixed rhythms let players learn the danger and improve their timing. |
| 2 | What is between plates | Safe tablecloth · spilled sauce hazard · table edge (fall off) · plates touch | **Spilled sauce; touching it = splat** | I want the plates to feel like safe spots the player has to aim for, so landing in sauce gives a missed jump a clear consequence. It fits the messy dinner-table setting and makes the player think about where they will land as well as when the fork will strike. |
| 3 | Does the jelly have a face | Two dot eyes · eyes plus small mouth · no face | **Eyes plus a small mouth** | I want the jelly to have a little personality so players feel attached to it. Eyes and a small mouth let me show worry when a shadow appears and relief at the dome, while keeping the face simple enough to read during gameplay. |
| 4 | Art style | Pixel art · smooth cartoon · glossy semi-realistic | **Smooth cartoon** (clean shapes, soft shading) | The jelly's wobble, squash, and stretch are a big part of its personality, and smooth cartoon shapes suit that movement. Clean outlines and soft shading fit the playful mood and should help the face and the fork warnings stay readable during gameplay. |
| 5 | Size of the playable slice | One screen · short scroll across about six plates | **Short scroll, camera follows** | The short scroll gives room for progression through different plate spacing and timing challenges. |
| 6 | Music while a shadow grows | Steady loop · quieter and thinner · second tension layer | **Quieter and muffled while a shadow grows** | I want the growing shadow to feel like a moment where the player holds their breath and watches the timing. Quieter, muffled music creates that feeling and lets the warning scrape stand out, without making the danger feel too dramatic or scary. |
| 7 | Fork warning sound | (Added by me during the music discussion) | **A metallic warning scrape that plays once when each fork's shadow starts to grow** | It draws attention to the danger early; then the growing shadow acts as the visual countdown, so the player has time to decide what to do. |
| 8 | Design pillars | Five candidates drafted by Claude | **Read the shadow, then commit · Wobbly and alive · Small in a giant world · Every splat teaches** | Each guides a different part of the experience: the shadow is about timing and decisions, the wobble gives the jelly personality, the scale makes the dinner table feel threatening, and the splat pillar makes failure something the player can learn from. Together they give me clear things to check when judging the gameplay, art, and sound. |

**Music plan (confirmed):**
- Normal play: playful loop
- Shadow growing: quieter and muffled, then fades back after the strike
- Splat (fork or sauce): short dip, back to normal on respawn
- Pause: very quiet and muffled, back on unpause
- Reaching the dome: loop fades out and a win sound plays
- End of slice: quiet; music restarts on replay

**Not a pillar:** "Bright jelly, dim table" will be part of the art direction instead, as the contrast rule for the palette.

**Risks Claude raised** (to carry into CHANGE-BRIEF.md as predicted failure cases; none tested yet):
- Generated frames drift: eyes and mouth move or change size between poses.
- The mouth disappears at on-screen size.
- Sauce and jelly colors are too similar to tell apart.
- A fork's shadow starts off-screen because the camera trails the jelly (proposed fix: the camera looks slightly ahead).
- Overlapping shadows make the music flicker or stay quiet (proposed fix: stay dipped while any shadow grows, fade back when none do).
- Respawning snaps the camera and disorients the player (proposed fix: the camera glides back).
- The warning scrape plays more than once per shadow.

**Human / Claude / model:**
- **Kiran:** the game idea, the shadow warning, splat and respawn, the mood and contrast, the warning scrape, every choice in the table above, and every reason given for it.
- **Claude:** checked the concept against the assignment, laid out options and trade-offs, drafted the pillar wording, raised the risks listed above, and organized this entry from our conversation.
- **Generative models:** none used yet.

**Next:**
- Write CONCEPT.md.
- Keep all required design documents committed before generating any assets.

**Still unresolved:**
- Starting point: an empty Godot 4 project or the walker-jumpman structure (to be credited either way).
- Whether cups are also platforms. They are in my pitch but not yet designed.
- Final list of sound events. Confirmed so far: the warning scrape and the win sound at the dome. Hop, landing, and splat sounds are candidates.
- One shared splat sound, or a separate sound for sauce.
- Screen resolution and the jelly's size on screen.
- The actual timings of each plate's fork rhythm (to tune in playtesting).
- Jelly, sauce, table, and fork colors.
- A wide generated background, or a repeating tablecloth strip.
- Which free or local generation tools to use (on my Mac or through Northeastern resources).

**Traceability:** No asset-log rows, commits, prompts, screenshots, or tests exist yet.


---

## 2026-10-01 — Storyboard decisions and my review, before image or audio asset generation

**Status (confirmed):** Committed so far: FRICTIONAL.md (`8d7b67a`), CONCEPT.md (`79ed580`), STORYBOARD.md with 7 SVG panel sketches and their drawing script (`97e8555`), and `.gitignore` (`8419e5e`). No image or audio generative model has been used. There is no Godot project yet.

**How the storyboard sketches were made:** I chose simple boxes-and-labels SVG thumbnails drawn by Claude. I specified that they must show actual scene layouts with the jelly, plates, forks, and shadows; three shot sizes; three camera angles; motion arrows in at least two panels; and clear gameplay and design-view labels. My reason: simple drawings are enough when the visual planning is clear. Claude wrote `tools/make_storyboard_svgs.py`; I typed it in with nano and ran it to create the panels.

**My review of Claude's first storyboard draft (before I created any files):** I stopped and asked for changes because:
- Panel 6 let the music return to normal on respawn even if a warning shadow was still growing. It must stay quieter while any shadow grows.
- ENV-TABLE was missing from asset lists where the table appears.
- It did not explain how respawning stays safe if the checkpoint plate's fork keeps cycling.
- It added an intro transition, camera shake, input locks, and a replay prompt that I had not decided on.
- "Before any generation" was not precise. I now use "before image or audio asset generation."

**Decided:**

| # | Decision | My choice | My reason |
|---|----------|-----------|-----------|
| 1 | Respawn safety | The checkpoint plate's fork cycle resets on respawn and restarts at its safe window; other forks keep their rhythms | I want a quick retry with a fair chance to regain control. Resetting that plate's fork gives a calm safe window followed by the full warning, while keeping the plate dangerous on the next attempt. The other forks keep their rhythms, so I can still use what I learned. |
| 2 | Intro pan | The slice opens with an eye-level side-view pan from the dome back to the jelly; Panel 1's high-angle shot is a design view only | I want players to see the dome as their goal and get a sense of how big the table feels from the jelly's perspective. Panning back to the jelly connects that destination to the starting point. |
| 3 | Skipping the intro | Always skippable with any key, even the first time; movement is locked during the pan; the skip key never triggers a hop | The pan sets up the world and goal, but I want players to choose whether to watch it or start playing immediately. |
| 4 | Camera shake | A short camera-only shake on a fork splat; no shake for sauce | I want the shake to show the weight of a giant fork hitting the plate. Falling into sauce feels softer, so the splat pose and sound suit it better. That gives each failure its own feel while keeping the shake subtle enough to preserve readability. |
| 5 | Input lock after a splat | Locked through the splat and re-form; control returns when the jelly is whole, and the checkpoint's safe window starts then | I want the failure and recovery animations to read clearly, but stay brief so retries feel quick. |
| 6 | Jump pressed or held during the lock | Ignored; the next hop needs a fresh press | I want the next hop to be a deliberate timing decision. Holding jump through a splat shouldn't launch the jelly straight back into danger. |
| 7 | End of the slice | A prompt waits; any key restarts on the first plate with no intro pan; every fork cycle and checkpoint resets; the music starts again | I want players to enjoy the win moment and choose when to try again. Replay should go straight into gameplay. |
| 8 | Restart key | Never triggers a hop | Restarting and jumping should be separate decisions. I want to regain control on the first plate and choose when to move. |
| 9 | Music during the intro | Starts quieter during the pan, rises to normal when play begins; stays quieter and muffled if a warning shadow is active | I want the music to establish the playful, slightly tense mood from the start, while staying quiet enough for players to take in the table and the dome. Raising it when control begins helps the transition into gameplay feel connected. |

**Inspect and revise (storyboard):**
- **Saw:** previewing all seven panels on my Mac, the first fork in Panel 1 crossed the title text.
- **Decided:** fix it now rather than leave it.
- **Changed:** Claude proposed splitting the title onto two lines. I made the edit in nano, re-ran the script, and checked Panel 1 again. The title no longer overlaps the fork. This fix is included in `97e8555`.

**Wording note:** CONCEPT.md v1 says "written before any generation." I now use the clearer wording "before image or audio asset generation." CONCEPT.md is not rewritten.

**Checks raised in discussion** (to carry into CHANGE-BRIEF.md; none tested yet):
- The skip key or the restart key also triggers a hop.
- A jump held through the splat fires a hop when control returns.
- The camera shakes on a sauce splat.
- The checkpoint fork does not reset to its safe window on respawn.
- The music stays quiet after a skipped intro, or returns to normal while a shadow is still growing.

**Human / Claude / model:**
- **Kiran:** every decision and reason above; the review that sent the first storyboard draft back; choosing to fix Panel 1; typing, running, and checking the script and files.
- **Claude:** drafted STORYBOARD.md and the SVG drawing script, asked the questions above one at a time, proposed the Panel 1 fix, and organized this entry from our conversation.
- **Generative models:** none used yet.

**Still unresolved** (carried from the first entry unless noted):
- Starting point: an empty Godot 4 project or the walker-jumpman structure.
- Whether cups are also platforms.
- Final sound event list, and whether fork and sauce splats share one sound.
- Screen resolution and the jelly's size on screen.
- Fork rhythm timings, splat and re-form duration, and pan length (to tune in playtesting).
- Jelly, sauce, table, and fork colors.
- A wide generated background, or a repeating tablecloth strip.
- Which free or local generation tools to use.

**Traceability:** commits `8d7b67a`, `79ed580`, `97e8555`, `8419e5e`; panels in `design/storyboard/`; drawing script `tools/make_storyboard_svgs.py`. No asset-log rows exist yet.


---

## 2026-10-01 — Character sheet and change brief decisions, before image or audio asset generation

**Status (confirmed):** Committed today: FRICTIONAL.md (`8d7b67a`, `66f5994`), CONCEPT.md (`79ed580`), STORYBOARD.md (`97e8555`), `.gitignore` (`8419e5e`), CHARACTER-SHEET.md with 5 SVG reference images and their drawing script (`600cdcb`), and CHANGE-BRIEF.md (`04511fd`). All four required design documents are committed. No image or audio generative model has been used. There is no Godot project yet.

**Character sheet decisions:**

| # | Decision | My choice | My reason |
|---|----------|-----------|-----------|
| 1 | Base viewport | 1280 × 720 | Enough detail for the jelly's expressions and smooth cartoon shapes to read clearly, while keeping the scene easy to compose. It matches the storyboard's 16:9 framing. |
| 2 | On-screen size | 64 px tall | Small beside the plates and forks, while keeping its eyes, mouth, and squash-and-stretch poses readable during play. |
| 3 | Facing | Face toward the camera; eyes and a slight lean show direction; drawn facing right, flipped for left | Expressions stay visible while the jelly clearly faces the way it moves, and the cues stay readable even when idle. |
| 4 | Resting shape | A true cube, 64 × 64 | A clear resting shape makes the squash and stretch noticeable and gives the jelly a consistent identity. |
| 5 | Highlight | Top-center | Left and right poses stay visually consistent when flipped; the lighting stays stable while the eyes and lean show direction. |
| 6 | Collision (first choice) | One fixed 52 × 58 box, bottom-aligned | Predictable collision while the jelly squashes and stretches, with a little forgiveness around its soft edges. |
| 7 | Jelly color | Turquoise / aqua | A bright, playful identity against the dim table; warm red-brown sauce contrasts clearly with it. |
| 8 | Palette | Accepted `#3CCFC4`, `#1F8E92`, `#E8FFFA`, `#0F3440` | The aqua stands out against the dark table, the warm sauce looks distinct from the character, and the dark outline keeps the face and shape readable on pale plates. |
| 9 | Movement on a plate | Scoots left and right with a wobble; hops between plates | Players can adjust position before committing to a hop, and the wobble connects movement to its soft body. |
| 10 | Pose set | 13 poses, including bored | Waiting is part of the gameplay, so it should have personality, with a droop and expression distinct from idle and worried. |
| 11 | Bored vs worried | Worried always overrides bored | The expression should draw attention to danger as soon as the shadow starts. |
| 12 | How the images were made | Claude-drawn SVG from a script; I review before committing | Poses at a consistent scale, with collision overlays and an actual-size silhouette check, as planning references for the later image-model assets. |

**Inspect and revise (character sheet):**
- **Saw:** in the first collision overlay, the fixed box stuck out above the low poses (crouch 8 px, squash 12 px, splat 36 px, re-forming 18 px), so a fork could visibly miss and still hit.
- **Decided:** two bottom-aligned boxes: standing 52 × 58, and low 52 × 44 for crouch and landing. My reason: collision should follow the low poses more fairly, while bottom alignment keeps contact with the plate consistent.
- **Decided:** no hits during splat and re-form. Once the jelly has failed, another hit shouldn't interrupt its recovery or trigger another splat sound; hazards detect it again when control returns.
- **Saw:** in the first silhouette test, idle and relief looked almost the same, and so did bored and falling.
- **Changed:** relief became a taller stretch, wider at the top, and bored became a lower, wider slump. My reason: the mood should read through the body shape as well as the face.
- **Checked:** I asked for the revised overlays to be checked so the new bored shape didn't recreate the invisible-hit problem. It would have (the standing box sat 10 px above it), so I chose the low box for bored as well.
- **Accepted with a note:** Scoot A's standing box sits 2 px above the art. Kept for playtesting.
- I approved all five revised images before committing them in `600cdcb`.

**Change brief decisions:**

| # | Decision | My choice | My reason |
|---|----------|-----------|-----------|
| 13 | Splat sounds | Two: SFX-SPLAT-FORK (heavier squish, brief metallic impact) and SFX-SPLAT-SAUCE (softer, wet) | Each failure should sound like its cause, play once per failure, and stay playful rather than harsh. |
| 14 | Scoot sound | None | The wobble animation gives scooting its personality, and quiet scooting lets the scrape, hop, and landing stand out during timing decisions. |
| 15 | Which forks scrape | Only forks whose shadow is on screen; a shadow that scrolls into view later gets no late scrape | The scrape should point to a threat the player can see, without distant forks cluttering the audio. |
| 16 | Which shadows dip the music | Only on-screen shadows (refines the earlier "any shadow" rule) | The music change should match visible danger, and off-screen forks shouldn't keep it muffled when the view is clear. |
| 17 | Background | A generated room layer (ENV-ROOM, new) plus a repeating generated table strip | The dim room sets the scale and mood, the table gives the route a consistent surface, and separate layers let me adjust brightness for readability. |
| 18 | Fork shadow | Code-drawn in Godot | The shadow is a timing cue, so I want direct control over its size, visibility, and growth, keeping the countdown consistent and readable muted. |
| 19 | Poses to generate | All 12 gameplay poses | The jelly's visual style should stay consistent through movement, danger, failure, recovery, and success. |
| 20 | Double-trigger plan | Approved after I asked to see the full rules written out | Each sound plays only on its state change; guards cover held keys, skip and restart presses, respawn, off-screen shadows, and repeat wins. |
| 21 | Predicted failures | Approved all 15 | They cover art drift and readability, double triggers, off-screen audio, the music seam, camera look-ahead, respawn timing, shake, Scoot A, and muted play. |

**Human / Claude / model:**
- **Kiran:** every choice and reason above; asking for revised overlays to be checked; choosing two boxes, hits off, the redrawn silhouettes, and the low box for bored; reviewing and approving the images, the trigger rules, and the failure list; typing, running, and committing everything.
- **Claude:** asked the questions one at a time with trade-offs; drafted the palette hex values and the contrast check; wrote and revised `tools/make_character_svgs.py`; pointed out the collision and silhouette findings; drafted the trigger plan, the failure list, CHARACTER-SHEET.md, CHANGE-BRIEF.md, and this entry from our conversation.
- **Generative models:** none used yet.

**Still unresolved:**
- Starting point: an empty Godot 4 project or the walker-jumpman structure.
- Whether cups are also platforms.
- Fork rhythm timings, bored delay, splat and re-form duration, and pan length (to tune in playtesting).
- Final environment colors and sizes (current ones are placeholders).
- How the room layer moves as the camera scrolls.
- Controls, including the pause and mute keys.
- Which free or local image, audio, and music models to use.

**Traceability:** commits `600cdcb` and `04511fd`; images in `design/character/`; drawing script `tools/make_character_svgs.py`. No asset-log rows exist yet.


---

## 2026-10-01 to 2026-10-02 — Character reference (CHAR-REF): first generations

**Status (confirmed):** first image generations done, locally in Draw Things 26.0924.0 with SDXL Base (v1.0). All design documents were committed before this, the last in `7262857`; the guide image was committed in `904b22a` before it was used. Full details and checksums for every row: ASSET-LOG.md.

**Setup decisions:**
- **Where to generate:** on my Mac, not a free online tool, so I can control and record the seed and settings and reproduce outputs.
- **Model:** SDXL Base (v1.0), to prioritize reference-guided control for the 12 poses.
- **Background:** flat magenta `#FF00FF`, because it is distinct from the jelly's palette, which should help with background removal.
- **Comparison plan:** try both text-only and image-to-image from my approved front-view drawing, using the same prompt and seed, to see how much the drawing improves consistency. Judge on shape, face placement, palette, and readability at 64 px.
- **Caught before generating:** the new Draw Things project came with an example prompt naming a living artist and brands. I cleared it before writing my own prompt.

**Wanted:** a reference that matches the character sheet (cube shape, face placement, outline, top-center highlight, bottom band) and reads at 64 px.

**Asked (shared by all tries):** SDXL Base (v1.0), the prompt and negative prompt in ASSET-LOG.md, 1024 × 1024, seed 7270, 30 steps, text guidance 7.0, sampler DPM++ 2M AYS, shift 1.00.

| Try | What changed | Prediction (written before generating; reviewed and confirmed by me) | What came back |
|-----|--------------|------------------------------------------------|----------------|
| A | Text only (strength 100%) | "I expect it to capture the aqua jelly and cartoon mood, but possibly drift toward a blob shape or change the face placement and highlight." | It stayed a cube, but in a 3D three-quarter view with legs; a large glossy face with magenta irises and an open mouth; no outline or band; edge highlights; a gradient background with a shadow. |
| B | Image to image from my guide, strength 60% | "I expect the guide to preserve the cube proportions, face, and colors more closely, though 60% strength may still change the outline or add unwanted detail." | The design was preserved closely. The unwanted detail I expected appeared as two stray dots above the right eye. |
| C | Same as B, strength 75% | "I expect more shading and a stronger jelly texture than Try B, but also a greater risk of changes to the cube shape, face, outline, or highlight. I'll check whether those additions help at 64 px." | More jelly shading (mainly the band), and the cube and outline held, but the face changed: an open mouth with a tongue, brows, taller eyes, and a stretched highlight. |

**My judgment:**
- **On B:** Claude raised a concern that B might look like the guide passed through with little model contribution. I decided that following the guide closely does not make it invalid; instead, we should document exactly what the model contributed. Measuring the file later showed the model did restyle it: a pinker background, slightly greener body and band, grain, taller oval eyes, a fuller smile, and the two dots.
- **Why I ran C:** I asked for one higher-strength comparison with everything else unchanged, to judge whether it adds useful shading while preserving the design.
- **64 px check:** I asked for each candidate to be cropped to its own character bounds and scaled to 64 px tall, because a fixed scale could make the candidates appear at different sizes and affect the comparison.
- **Choice:** B, with the stray dots removed. At 64 px it stays readable and matches the character sheet most closely. I'd rather keep the simple face and consistent silhouette than change the design for extra detail.

**Inspect and revise (the cleanup):**
- **Saw:** the two stray dots in B are visible even at 64 px.
- **Revised the method:** Claude's first cleanup proposal used one broad box. I judged it too broad, since it could flatten legitimate shading, and asked for two small boxes around the actual dots, the raw image preserved, and a before-and-after comparison before accepting.
- **Done:** two boxes; 1,954 pixels changed, all inside them. Before-and-after approved. The same edit on my Mac gave the matching pixel fingerprint `5fbc3cce005d71c8`, and the raw file's checksum was unchanged.
- **Accepted as CHAR-REF** (`art/reference/CHAR-REF.png`): at 64 px, the face and silhouette read clearly, the stray dots are gone, and the cube shape, outline, highlight, and bottom band remain consistent with the character sheet.

**Human / Claude / model:**
- **Kiran:** chose local generation, SDXL, magenta, the A-versus-B comparison and the extra C run; reviewed and confirmed the predictions before each try; asked for the bounds-based 64 px check and the two-box cleanup; made the final choice; cleared the unsafe example prompt; ran every generation, edit, and check on my Mac.
- **Claude:** compared the tools and models; checked the SDXL license; drafted the prompt and settings, which I approved; helped with the wording of the predictions and suggested what they should cover (shape, face, outline, highlight, unwanted extras) and which checks to run; built the guide image from the sheet's drawing code; wrote `check_64px.py` and `remove_specks.py`; described each output against the sheet; measured the dot positions and the model's changes from my uploaded file; drafted ASSET-LOG.md, SOURCES.md, and this entry.
- **Model (SDXL Base 1.0):** produced the three raw images. In B it restyled colors, grain, eyes, and smile, and added the two dots.

**Still unresolved:**
- Whether image to image keeps enough consistency across the 12 poses (pose generation not started).
- Background removal for magenta that came back as `#F424E1` with grain, and checking for magenta fringes.
- The face in CHAR-REF: the eyes are slightly taller ovals and the smile is fuller than the sheet's drawing. To judge as poses are derived.
- Audio and music models; starting point for the Godot project.

**Traceability:** ASSET-LOG.md rows CHAR-REF-A, CHAR-REF-B, CHAR-REF-B edit, and CHAR-REF-C; guide commit `904b22a`; evidence in `evidence/`; thumbnails in `art/source/` and `art/rejected/`.


---

## 2026-10-02 — First derived pose: CHAR-SCOOT-B

**Status (confirmed):** CHAR-SCOOT-B accepted, the first of the 12 gameplay poses derived from CHAR-REF. The pose-guide tool and the guide were committed in `85e7786` before generating. Full details and checksums: ASSET-LOG.md, CHAR-SCOOT-B rows.

**Strategy decisions:**
- **How poses are derived:** warp CHAR-REF into each pose's shape, then image to image. That keeps every pose derived from the accepted reference, with the character sheet defining the target shape. I chose to test one pose first and check the face, highlight, outline, and readability at game size before making the rest.
- **Face during the warp:** warp the body and keep the face unwarped, so eye size, spacing, and mouth stay consistent while the body stretches and leans.
- **First test pose:** Scoot B, because it challenges the shape without also changing the expression.

**My review of the warp tool (before I saved it):** I found two mismatches and asked for fixes:
- The scale assumed CHAR-REF was 576 × 576 px, but its measured bounds are 604 × 601. On checking, the width and height were already scaled relative to the measured bounds, but the 576 value was still used for the taper. The script now uses the measured bounds throughout and prints the size it actually produced (71.9 × 55.8 game px for a 72 × 56 target).
- The eye line averaged the eyes and the mouth together. The eyes are now found on their own and placed explicitly 38% down from the pose's top, with the face unscaled.
- I accepted the revised guide after comparing it with the sheet. Known issue: a small outline notch at the bottom right, to be checked in the generated result at 72 px.

**Settings:** I kept everything identical to CHAR-REF-B (same prompt, seed 7270, 60%) as a first comparison, changing only the guide.

| Try | Strength | Prediction (written before generating; reviewed and confirmed by me) | What came back |
|-----|----------|-----------------------------------------------------------------------|----------------|
| 1 | 60% | "I expect the guide to preserve most of the stretch and rightward lean, though the cube wording may pull it toward a squarer, more upright shape. I expect the face to stay close to CHAR-REF and the outline notch to soften, with some risk of new specks or changes to the eyes and highlight." | The stretch and lean were kept and the notch was smoothed, but the smile grew wider and deeper and lilac blush spots appeared under the eyes, visible at 72 px. There was more glossy shading. |
| 2 | 50% | "I expect 50% strength to keep the stretch and lean while preserving the smaller smile more closely and reducing the chance of blush. It may add less glossy shading, and I'll check whether the outline stays smooth or the guide's notch returns." | All of that held: the small smile, no blush, less gloss, a smooth corner, and the shape within 1 px of the guide. New: four faint dots in the band, visible at 72 px, and faint pale marks on the face. |

**My judgment:**
- **After try 1:** I retried at 50% with everything else unchanged. The shape and lean already worked, so I wanted to test whether lower strength preserves CHAR-REF's small smile and avoids the blush. Face and palette consistency matter more to me than the extra glossy shading.
- **After try 2:** I accepted it after a logged edit removing the four band dots. It preserves the intended shape and small smile, so I kept those strengths and cleaned up the unwanted detail, with tight boxes, the raw output preserved, and a 72 px check before final acceptance. I left the faint face marks, since they are barely noticeable at game size.

**Inspect and revise (the cleanup):**
- **Saw:** Claude's first cleanup test used the flat fill from CHAR-REF, and it left visible square patches in the band's shading, so that version was rejected.
- **Changed:** a lower threshold for the fainter dots, a wider margin for their halos, and a smooth fill that blends each area in from the surrounding band. I approved this because preserving the band's shading makes sense. The updated script still reproduces the CHAR-REF edit exactly (fingerprint `5fbc3cce005d71c8`), which I re-ran and checked.
- **Verified on my Mac:** fingerprint `023e9bea89d15c77`, matching the approved preview; the raw checksum unchanged; the character box unchanged; a clean band at 72 px.
- **Accepted as CHAR-SCOOT-B** (`art/poses/CHAR-SCOOT-B.png`): it preserves the sheet's stretch and lean, keeps the face close to CHAR-REF, and has a clean band at 72 px, with the faint face marks recorded as a minor remaining limitation.

**Human / Claude / model:**
- **Kiran:** chose the warp strategy, the unwarped face, and Scoot B first; caught the two warp-tool mismatches; accepted the guide and noted the notch; chose identical settings for try 1 and 50% for try 2; reviewed and confirmed the predictions; chose to clean up try 2 with tight boxes and leave the face marks; approved the cleanup method; ran every generation, edit, and check on my Mac; accepted the final pose.
- **Claude:** proposed the three pose strategies and the two face options; wrote and revised `make_pose_guide.py`, `check_64px.py` (`TARGET_H`), and `remove_specks.py` (`THRESH`, `GROW`, `FILL`); built and checked previews from my uploaded files; tested and rejected the flat fill; suggested what the predictions should consider; described each output against the sheet; drafted the asset log rows and this entry.
- **Model (SDXL Base 1.0):** produced both raw tries. In try 1 it added blush, a bigger smile, and glossy shading; in try 2 it added the band dots and faint face marks.

**Still unresolved:**
- The faint face marks in CHAR-SCOOT-B (minor, barely visible at 72 px).
- Outline thickness varies slightly with stretching (thicker top and bottom, thinner sides).
- The size convention: poses are measured to the outline's outer edge, while the sheet's drawings measure to its center line (about 3 game px difference in height).
- Expression poses (bored, crouch, landing, worried, splat, re-form, relief) need a face change, which this unwarped-face method does not yet handle.
- 10 more gameplay poses, the environment art, audio, and the Godot slice.

**Traceability:** commit `85e7786` (guide and tool); ASSET-LOG.md rows CHAR-SCOOT-B try 1, try 2, and try 2 edit; evidence `evidence/char-scoot-b-72px-compare.png` and `evidence/char-scoot-b-cleanup-72px.png`; thumbnails in `art/source/` and `art/rejected/`.

---

## 2026-10-02 — Batch 1: remaining poses

**Status (confirmed):** ten poses generated from guides committed in `d0199e8`; nine accepted (four as-is, five after logged edits); Scoot A try 1 rejected, retried with seed 7271, and accepted after a logged edit. CHAR-IDLE is CHAR-REF itself. Details, boxes, and fingerprints: ASSET-LOG.md, Batch 1.

**Workflow change (my instruction):** from this batch on, work proceeds in complete batches: Claude makes routine choices from the approved design and settings, asks me only about significant design changes, and we review assets once per batch; logs record decisions, observations, edits, and results only.

**Design decisions:**
- **Expression poses:** I approved the hybrid: warp CHAR-REF's body, reuse its eye pixels where the sheet keeps dot eyes, and draw the sheet's brows, mouths, lids, and closed or X eyes in CHAR-REF's face color.
- **Splat and re-form:** reshape or mask the actual CHAR-REF body and texture, using the sheet as the shape guide. Sampling its colors alone wouldn't clearly demonstrate that those poses were derived from the accepted reference.
- **Backgrounds:** magenta only for isolated sprites; ENV-ROOM and the repeating ENV-TABLE strip get their intended backgrounds and surfaces, with the table strip checked for seamless repetition (Batch 2).
- **Scoot A:** retry once with seed 7271, everything else unchanged.

**Routine choices made by Claude (from the approved design):** CHAR-IDLE = CHAR-REF; every pose at 50% with the CHAR-SCOOT-B settings; face strokes at CHAR-REF's smile width (23 px), so the sheet's small "o" mouths render nearly filled; re-form drip marks left out of the guide; tight-box edits with the smooth fill; marks barely visible at game size left in place and documented.

**Prediction (written before generating; mine):** "I expect most poses to preserve CHAR-REF's colors and texture while following the guides' shapes. Splat, re-form, and the expression poses seem most likely to drift, so I'll check their silhouettes and facial readability at their intended game sizes."

**What came back:** colors, texture, and shapes held across all ten; every outer box is within 1 game px of its guide, splat and re-form included. The drift appeared as added marks and face changes: bubbles on falling, a teardrop nose and drips on rising, bubbles on worried, a pink tongue on crouch, a mouth-like mark on re-form, and on Scoot A a wavy mouth and two large soft patches. Landing and splat came back clean.

**Inspect and revise:**
- Two of Claude's cleanup tests failed and were redone or dropped before review: on worried, a first box clipped the right brow (redone with two boxes clear of it); on bored, the fill left a visible rectangle in a low-contrast area (dropped; the smudge is documented instead).
- Crouch's tongue sits against the dark mouth, so a new pink-only selection removes it without touching the mouth line; a soft dark shadow remains under the mouth.
- The edit tool now stops if a box leaves no untouched pixels around a mark; this caught boxes on falling and re-form that were too tight, which were widened.
- The earlier CHAR-REF and CHAR-SCOOT-B edits still reproduce their fingerprints with the updated tool.
- Scoot A retry: the first try 2 export was pixel-identical to try 1 (the seed change had not taken effect, or an older entry was exported). It was set aside, the run redone with the seed confirmed, and a check confirmed the new output differs. Try 2 kept the guide's mouth and lost the side patches, but added a curved stroke at each eye's outer edge; two boxes removed them, leaving small stubs not visible at game size.
- I approved the handling for the nine poses, with the remaining minor marks documented, after one batch review (`evidence/batch1-review.png`), and accepted Scoot A try 2 after its edit.

**Human / Claude / model:**
- **Kiran:** set the batch workflow; approved the hybrid; directed that splat and re-form reshape CHAR-REF's actual body and that magenta is for isolated sprites only; wrote the batch prediction; ran all ten generations, the Scoot A retry, and the batch scripts on my Mac; approved the nine-pose handling; chose the Scoot A retry and accepted its edited result.
- **Claude:** wrote `make_pose_guides.py`, the `SELECT=pink` option and safety stop in `remove_specks.py`, and the batch script; measured every result against its guide; located the marks; tested, revised, or dropped cleanups; drafted the asset log rows and this entry.
- **Model (SDXL Base 1.0):** produced the ten raw outputs, including the added marks listed above.

**Still unresolved:**
- Small stubs where Scoot A's eye strokes were removed.
- Documented minor marks: bored smudge, relief and worried band dots, rising drip tops, crouch's shadow under the mouth.
- The SCOOT-A guide differs from Claude's preview build only in 2,008 outline-edge pixels (at most 2 of 255 levels); the face position is identical. Claude's first guess, a face-rounding difference, was wrong.
- Background removal and fringe checks for all sprites; environment art, audio, the Godot slice, testing, and the film.

**Traceability:** commit `d0199e8` (guides); ASSET-LOG.md Batch 1; `evidence/batch1-review.png`, `evidence/char-<pose>-cleanup.png`, `evidence/batch1-checksums.txt`; raw thumbnails in `art/source/` and `art/rejected/`.

---

## 2026-10-02 — Batch 2: environment art

**Status (confirmed):** six environment assets accepted in my batch review after 16 generations: ENV-ROOM try 3, ENV-TABLE try 5, ENV-PLATE try 3, ENV-SAUCE try 2, ENV-FORK try 2, ENV-DOME try 1. The plate, sauce, fork, and dome came from drawn guides at 50% after text-only tries failed. All four sprites and the 12 poses now have transparent cut-outs in `art/game/`. Details, prompts, and fingerprints: ASSET-LOG.md, Batch 2; `gen-inputs/batch2-env-prompts.md`.

**Prompts record (correction):** the plan was to commit the Batch 2 prompts file before generating. I ran the commit steps right after the Batch 1 push, but the first command failed (`mv ~/Downloads/batch2-env-prompts.md gen-inputs/`: "No such file or directory"), so nothing was added or committed ("nothing to commit, working tree clean"; the push reported "Everything up-to-date"). The failure went unnoticed, and in that chat I reported the step as done; Claude's handoff then recorded the file as committed and pushed, from my report rather than from a commit hash, which was wrong. The processing script found the file missing from the repository and from `~/Downloads`, and my Terminal history showed the failed commands. I asked for the file to be restored with the prompts and settings actually used, and for the guided retries to be recorded accurately before committing. The restored file says it was written after generation, and its planned prompts match the original copy in the earlier chat's file export word for word. This batch therefore has no committed-before-generation prompt record, and no prediction was written before it.

**Design decisions:**
- **Dome (before generating):** a transparent interior with the rim and highlights kept, "so the jelly remains visible underneath"; any masking or transparency edits logged explicitly, because "a frosted appearance alone won't solve the magenta showing through the glass."
- **Guide for the plate (after two text-only tries):** "I want the plate to fit the side-view gameplay and make its landing surface clear. The two text-only attempts haven't achieved that, so let's guide the shape and log the method change."
- **Closeness to the guides (batch review):** the guided plate, sauce, fork, and dome stay close to the drawn guides (4–19% of each object's pixels changed noticeably). I chose to accept them as they are and document this plainly, rather than rerun them at a higher strength.
- **Dome edge (batch review):** no extra generations for the dome's minor ragged inner edge.

**Routine choices made by Claude (from the approved design):**
- Prompt changes between tries, each aimed at what the previous output showed: removing "dining room" and "dinner table" wording, which pulled in furniture and place settings; describing the table strip as full-frame cloth and then as a velvet curtain; adding the plate's failure words (angled view, 3d render, surface, purple) to the sauce, fork, and dome negatives.
- Extending the plate's guide method to the sauce and the fork after their text-only tries failed the same way, and starting the dome guided, with no text-only try.
- The sauce's pink highlight recolored to a warm highlight (as with the pink tongue in Batch 1, it was off-palette and close to the key color).
- Table processing values: bottom band dropped, 75% saturation, 50% brightness, 160 px seam blend. The room used as generated, resized only. Poses cut out on their full canvas so the frames stay aligned.
- Table try 4 (a wood plank) was set aside as a fallback; using it would have changed the approved tablecloth design.

**What came back:** text-only prompts kept producing scenes rather than single assets: furniture in the room, place settings on the table, a row of utensils pointing up for the fork, and sauce on a plate. They also kept producing angled top views with gradient or floor backgrounds for the plate and sauce. Fixing the table took five tries. With guides, every shape held (object boxes within 11 px of the guides), and SDXL restyled the shading and outline. It also added a pink highlight on the sauce, a mint tint on the dome's knob and rim, and a ragged inner glass edge on the dome.

**Inspect and revise:**
- **Cut-out tool (Claude's tests before I ran it):** a plain distance threshold left a one-pixel magenta line outside every outline. Edge pixels mixing the dark outline with magenta were too far from the background color to be keyed. A 2 px edge ring fixed it. Un-mixing edge colors from the nearest solid pixel then left a faint green line on dark backgrounds and ragged white bits on the dome. Matching each edge pixel to the best-fitting nearby solid color fixed the green line. The dome's ragged bits come from the raw output itself. The first sauce recolor left a pink ring around the highlight; blending the transition pixels fixed it.
- **Guides (Claude's previews):** the first sauce guide had spiky outline artifacts and a kinked top. The outline drawing and curve control points were corrected before I used it.
- **Batch script:** in Claude's dry run, a failing step inside a helper function stopped the script without the stop message; the script now reports the failing command. The batch scripts check every step and stop on failure; the manual prompts-file commit above had no such check. On my Mac the script stopped because plate try 2 had not been exported. I exported it from the version history, and the rerun confirmed every retry differs from the try before it.
- **Results:** zero magenta fringe on the plate, sauce, fork, and all 12 poses. The dome has 59 remaining magenta-like pixels, not visible at game size. The table seam is no more visible than the strip's normal fold-to-fold variation. Every fingerprint matched between Claude's dry run and my Mac.

**Human / Claude / model:**
- **Kiran:** set the dome transparency requirement; chose to guide the plate and gave the reason; ran all 16 generations and exports in Draw Things and both runs of the processing script; reviewed the batch; accepted the six assets; chose to document the guides' closeness rather than rerun; asked for the prompts file to be restored and the guided retries recorded accurately; decided no extra generation for the dome edge.
- **Claude:** wrote the prompt changes for each retry and described each output; wrote `make_env_guides.py`, `process_env.py`, `batch2_review.py`, and the batch scripts; dry-ran them on my uploaded files; measured the guides' closeness; restored the prompts file from the earlier chat and this one; drafted the asset log rows and this entry.
- **Model (SDXL Base 1.0):** produced all 16 raw outputs, including the failures and the added details listed above.

**Still unresolved:**
- The guided environment sprites are close to Claude-drawn shapes; this is documented, not changed.
- The dome's ragged inner glass edge (59 magenta-like pixels) and the mint tint on its knob and rim.
- The room has a bright diagonal glow (95th-percentile luminance 125 of 255). Whether it needs darkening, and how the room moves with the camera (parallax), will be decided in Godot.
- The fork's handle must reach the top of the screen. In the mock it is stretched; how to extend it in Godot is not decided.
- Final in-game sizes; audio (Batch 3); the Godot slice, testing, and the film.

**Traceability:** ASSET-LOG.md Batch 2; `gen-inputs/batch2-env-prompts.md` (restored) and `gen-inputs/ENV-*-guide.png`; `evidence/batch2-review.png`, `batch2-mock-scene.png`, `batch2-table-seam.png`, `batch2-sprites.png`, `batch2-poses.png`, `batch2-process-log.txt`, `batch2-checksums.txt`; thumbnails in `art/rejected/` and `art/source/`; processed files in `art/game/`.

---

## 2026-10-02 — Slice setup: build order, starting point, controls

**Status (confirmed):** the walker-jumpman starter is imported unchanged into `godot/` (nikbearbrown/walker-jumpman at `9387542`, in commit `d7f0c97`). The slice's build brief (`SLICE-BRIEF.md`) and working rules (`CLAUDE.md`) are committed before any slice code. Engine on my Mac: `4.7.2.stable.official.ed1daf0bf`.

**Decisions (mine):**
- **Build order:** "Let's build the Godot slice next, with silent placeholders for the approved sound events." We review the running game before integrating generated audio.
- **Workflow:** I asked to "use the required course Brutalist workflow with the walker modifier in Claude Code from the start." Claude pointed out that the Brutalist `godot-gamedev` skill makes the development film from the finished project, and that the course's loop for building in Claude Code is Walker's brief → build → playtest → inspect → revise. The slice is built in Claude Code with that loop; the film follows with `godot-gamedev` and the `walker` modifier. Local skill check: `godot-gamedev` found in my brutalist.art clone at `skills/make/godot-gamedev` (commit `6a8380a`); its SKILL.md describes it as making a Liam-narrated Godot development film, using `walker` for Claude/GDD bookends, and says it "Does not build or publish a game".
- **Starting point:** the walker-jumpman starter, the option Claude recommended because its tested movement, camera, headless test runner and keyboard checks give the automated sound-count check a base, and the Brutalist Godot skills expect that layout. License file in the starter: none in the starter repository.
- **Controls:** ← / → or A / D move; Space, ↑ or W jump; Esc pause; M mute all; N mute music only.

**Routine choices made by Claude (from the approved design):** the brief's build defaults. These are: game sizes from the Batch 2 review; art copied into `godot/assets/` with a byte-identical check; one sound-event entry point that records its calls in placeholder mode; a music controller on real audio buses that logs its changes; seven automated checks mapped to predicted failures 5–9, 12 and 13; cups left out; a static room unless parallax is approved; tunable values in one file, marked as defaults.

**Human / Claude:**
- **Kiran:** chose the build order, Claude Code from the start, the starter, and the controls; ran the setup script.
- **Claude:** wrote SLICE-BRIEF.md, CLAUDE.md, the setup script and this entry, and dry-ran the script.

**Still unresolved:** fork timings, bored delay, splat and re-form durations, pan length and plate spacing (tuned in playtesting); room parallax and brightness; cups; the audio and music models (Batch 3).

**Traceability:** commit `d7f0c97` (starter import, unchanged; `git show --stat d7f0c97`); the setup commit with SLICE-BRIEF.md, CLAUDE.md, this entry and SOURCES.md; `evidence/slice-setup-log.txt`.

---

## 2026-10-03 — Slice setup batch: the playable slice with silent sound placeholders

**Status (confirmed after my review; not yet committed):**
- The slice runs from the Godot editor and from the command line, with the six plates, forks, sauce, the dome, the 12 poses, the intro pan, respawn and restart, and silent sound and music placeholders that log their calls.
- Final run after the review changes (`bash tools/run_slice_checks.sh`): art copies 18/18 byte-identical; mechanics 25/0; keyboard 12/0; slice checks 52/0; 7 screenshots at 1280 × 720; game launched 8 s with no errors.
- The automated checks use scripted input; my playtest is below.

**My playtest (from the Godot editor, F5, silent build with no audio yet), in my words:**
"1. Yes i can see the shadow growing and yeah it acts like a clue to when to jump 2. yes the timing is fair 3. its good"

**Decisions (mine):**
- **Units:** I chose "1280×720 base, ×2 units": the world matches the design sizes, and the starter's movement values are doubled. The unchanged starter suite passed at ×2 with every length exactly doubled and every tick count the same.
- **Fork reach:** first I chose "Bigger fork, hits most of plate". When the plan still left a safe edge band, I asked to "Size the fork so its tines span the plate's full width (head about 200 px), so there is no standing position on a forked plate outside the tines' hit zone. Keep the hit zone equal to the visible tines. Change the edge-band test to assert the safe band is 0 px."
- **Traceability:** "Save this approved plan into the repo as evidence/slice-plan.md as part of step 0, so it is traceable."
- **Batch review:**
  - **#12 (music through the strike):** kept. "Quiet and muffled through the shadow and the strike, back as the fork rises."
  - **#13 (off-screen shadow):** changed. "Follow CHANGE-BRIEF's music rule: a shadow that started growing off screen dips the music once any part of it is on screen while still growing, but still never plays SFX-WARN." SLICE-BRIEF §8 #4's "no music dip" wording came from the Claude chat brief and is superseded by this decision; SLICE-BRIEF.md is not edited.
  - **#7 (intro shadows):** changed. "Start the forks that are off screen when play begins partway into their shadow phase, frozen during the pan, so the intro shows shadows as panel 1 lists. No fork may be on screen and in its shadow phase when play starts, and nothing warns at the start."
  - **#11 (held direction ignored after a lock):** kept.
  - All other differences accepted as listed.
  - Routine: rename the root node to "JellyHop"; stage the JSON test reports.
- **Where the recommendations came from:** the Claude chat (claude.ai) recommended the units and fork options, drafted the fork feedback wording I pasted, and recommended the Q1 choice; the decisions were mine. (In Claude Code's questions, the same options were marked "(Recommended)".)

**Routine choices made by Claude (from the approved design):**
- The §9 defaults are in `godot/game/slice_tuning.gd`, listed in `evidence/slice-batch-review.md` §2.
  - P5 and P6 now start halfway into their shadow phase (offsets 2.0 and 1.7 s), for my #7 decision.
  - Combining #12 with #13: "still growing" for an off-screen-started shadow means the same warning window as any shadow, the shadow phase plus the strike.
- The differences from the design or the plan are listed in `evidence/slice-batch-review.md` §3. Among them:
  - The airborne crouch keeps the standing box.
  - The fork is drawn behind the jelly.
  - The camera snaps at the start of play and glides only on respawn.
  - No handle extension was needed at the decided fork size.

**What came back (inspect and revise):**
- **The starter's low-ceiling check failed** once the airborne crouch used the low box (feet rose 48 px under 40 px of headroom). The code was changed; the check was not.
- **A test script that failed to compile still exited 0.** The run script now also requires each suite's summary line.
- **The edge-band check got a negative control.** Squeezed to the Batch 2 fork size, it finds a 128 px safe band.
- **Step 7 had 7 failures.**
  - Two were real bugs: the camera glided from the dome at the start of play, and the music ramps ran on render frames.
  - Two were test windows: counting before a placement landing, and an overlap window running into the next cycle.
  - The rest followed from the camera bug.
- **Screenshots:** the warning shadow was too faint, and the splat was hidden by the tines; both were revised.
- **After my review:** the new intro check first ran one tick past the pan. Its coverage threshold then failed at 230 observed ticks, because a headless run can batch physics ticks. The window and the threshold were fixed; the "frozen" assertion is unchanged.
- The intro screenshot now shows the shadows on plates 5 and 6.

**Human / Claude:**
- **Kiran:** approved the plan with two changes; chose the units and the fork reach; played the slice from the editor; made the review decisions above.
- **Claude chat (claude.ai):** recommended the units and fork options, drafted the fork feedback wording I pasted, and recommended the Q1 choice.
- **Claude Code:** inspected the starter; wrote the plan, the code, the tests, the run script, the review sheet and this entry; ran every automated check listed.

**Still unresolved:**
- Failures #2, #3, #4, #11, #13, #14 and #15, beyond what my playtest notes cover.
- Room parallax and brightness.
- Audio (Batch 3), with failures #8, #9 and #10 by ear.

**Traceability:** `evidence/slice-plan.md`, `evidence/slice-batch-review.md` (§7: my review), `evidence/slice-checks/` (step, review and final logs), `evidence/slice-screens/`, `evidence/slice-art-copy.txt`, the JSON test reports in `evidence/`.
