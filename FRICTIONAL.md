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
