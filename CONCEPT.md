# CONCEPT — Jelly Hop: Fork From Above

Version 1 · 2026-10-01 · written before any generation. Later revisions are added below as new dated sections; this version is not rewritten.

## The game in two sentences

The player is a small jelly cube left on a dinner table after a party, hopping across plates to reach a glass dessert dome. Giant forks strike from above, and a growing shadow warns the player before each strike.

## Core loop

- **Repeat:** hop from one plate to the next.
- **Decide:** on each plate, read the fork's shadow and choose to move now, wait, or jump back.
- **Risk:** a fork strike, or landing short in the spilled sauce between plates. Either one causes a quick splat and a respawn on the last safe plate.
- **Rhythm:** each plate's fork follows a fixed, learnable cycle: the shadow grows, the fork strikes, then a safe window follows.
- **Progression:** a short scrolling stretch of about six plates, where plate spacing and fork timing change to create new timing challenges.

## Design pillars

1. **Read the shadow, then commit.** The game is about timing and decisions.
   *Choice that honors it:* a metallic warning scrape plays once when a shadow starts to grow, and the growing shadow is the visual countdown.
2. **Wobbly and alive.** The jelly has personality players feel attached to.
   *Choice that honors it:* smooth cartoon squash and stretch, plus eyes and a small mouth that show worry at a shadow and relief at the dome.
3. **Small in a giant world.** The scale makes the dinner table feel threatening.
   *Choice that honors it:* plates and forks are drawn huge next to the jelly.
4. **Every splat teaches.** Failure is something the player can learn from.
   *Choice that honors it:* fixed fork rhythms repeat predictably, the respawn is on the last safe plate, and the music dips on a splat and returns on respawn.

## Art direction

Smooth cartoon with clean outlines and soft shading. It suits the jelly's wobble, squash, and stretch, fits the playful mood, and keeps the face and fork warnings readable during gameplay. Contrast rule: a bright jelly against a dim table and sharp steel forks, so the jelly always stands out.

Reference notes:
- **Lighting and mood:** a dim dinner table after the party has ended.
- **Materials:** bright, wobbly jelly; hard, sharp steel forks.
- **Hazard:** messy spilled sauce in the gaps, in a color the jelly never uses.

## Audio direction

The sound should feel slightly tense but playful. While a shadow grows, the player should feel like they are holding their breath and watching the timing, without the danger feeling too dramatic or scary.

Music behavior:
- **Normal play:** playful loop
- **Shadow growing:** quieter and muffled, then fades back after the strike
- **Splat (fork or sauce):** short dip, back to normal on respawn
- **Pause:** very quiet and muffled, back on unpause
- **Reaching the dome:** loop fades out and a win sound plays
- **End of slice:** quiet; music restarts on replay

Confirmed sounds so far: the warning scrape and the win sound. The full event list is set in CHANGE-BRIEF.md.
