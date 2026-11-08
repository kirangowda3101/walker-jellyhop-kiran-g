I've added the Step 1 code to `godot/effects/effects_driver.gd`. The diff above is the real `git diff`, and it is the only file I changed.

**What it adds** (only added lines):
- Two preloads at the top: `dome_glints.tscn` and `slice_tuning.gd`.
- Two variables:
  - `glints` holds the one emitter.
  - `was_won` remembers whether the run was won on the previous tick.
- In `_ready()`, three lines make the emitter once, place it at (dome centre x, `TABLE_TOP − 70`) and add it to the session. The session sits at (0, 0), so this position is also its world position.
- At the end of `_physics_process()`, after the landing-puff block, the driver acts only when the state enters or leaves `WON`:
  - entering `WON` sets `emitting = false`;
  - leaving `WON` calls `restart()` on the same emitter.

**Left unchanged:** the landing-puff lines, `session.gd`, both effect scenes, the previews, the shaders and every test. The diff shows no other files.

**Not verified yet:** I ran nothing except `git diff`, so this code hasn't been parsed or run by Godot. Two things are still open until the Step 3 runs:
- Whether calling `session.add_child()` from inside the session's own `_ready()` raises a "busy setting up children" error.
- Whether `restart()` sets `emitting` back to `true` in 4.7.2.

**One thing I noticed but didn't touch:** the Effect A comment in the driver still says "session.gd line 372". Since the driver line was added, that check is at line 373. That comment is in the landing-puff block, so I left it.

**Noted for the state test, when you approve it:**
- Keep a reference to the emitter that exists at load. Assert that the emitter after each of the two replays is that same object (`is_same()` or the same instance ID), not only that there is one.
- Check that no new `LandPuff` was added on the exact tick the state changes to `WON`, as well as on every tick after it until the replay.

I'm stopping here. Nothing is committed.