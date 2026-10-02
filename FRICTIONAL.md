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
