I've read the brief, CLAUDE.md, the driver, `session.gd`, `player.gd`, `dome_glints.tscn`, the Effect A state test, `test_slice.gd` and `route_driver.gd`. I haven't edited anything. Here is the plan.

## Starting point

- `session.gd` line 63 already adds the driver: `add_child(preload("res://effects/effects_driver.gd").new())`. **No change to `session.gd` is needed for Effect B.** (CLAUDE.md's session line numbers are now one higher from line 63 on. For example, the landing check is at line 373, not 372.)
- `effects_driver.gd` has only the Effect A block. I will add lines and leave the existing landing-puff lines (13–18) untouched.
- `dome_glints.tscn` already has `emitting = true`. I won't touch it.

## Step 1: Driver code for Effect B (`godot/effects/effects_driver.gd`, about 12 added lines)

```gdscript
const DOME_GLINTS := preload("res://effects/dome_glints.tscn")
const T := preload("res://game/slice_tuning.gd")
var glints: GPUParticles2D
var was_won := false

# in _ready(), after the priority line:
	glints = DOME_GLINTS.instantiate()
	glints.position = Vector2(T.dome_left() + T.dome_width() / 2.0, T.TABLE_TOP - 70.0)   # brief: dome centre x, TABLE_TOP − 70
	session.add_child(glints)

# at the end of _physics_process(), after the puff block:
	var won: bool = session.state == session.State.WON
	if won != was_won:
		if won:
			glints.emitting = false   # B2
		else:
			glints.restart()          # B3
		was_won = won
```

How this meets each rule:
- **B1, on from load.** The driver's `_ready()` runs inside the session's `_ready()`, before the intro starts. It makes the single instance there. The driver never sets `emitting` at that point. It is on because the scene file says `emitting = true`, and `preprocess = 2.4` fills it on the first frame.
- **B2, stop at the win.** The driver runs at priority 20, after the session (10). So on the tick `resolve_contacts()` sets `WON`, the driver sees the change in the same tick and sets `emitting = false`. The node is never freed or hidden, so glints already alive keep rising and fade out over their remaining life.
- **B3, start on replay.** On the first tick where the state is no longer `WON`, the driver calls `restart()`. Replay goes through `_unhandled_input → start_session()`, which runs before the next physics tick, so the driver acts on that tick. Two things to know:
  - `restart()` re-applying preprocess is still your prediction.
  - `restart()` also clears any glints still alive from the win. That only matters if you replay less than 2.4 s after the win; the prompt appears at 1.0 s.
- **B7, one instance.** The instance is created once, in `_ready()`, and the driver holds it. No code path makes or frees another. Replays only call `restart()` on the same node.
- **Why it acts only on a change, not every tick.** The driver touches the node only on the two transitions. During Esc pause, tree pause and hiding, it does nothing to the glints, so B4, B5 and B6 hold because no code runs for them.
- **Reads only.** It reads `session.state` and nothing else. It never writes game state and never touches `visible`, `amount`, `amount_ratio` or any material.
- **One risk to check in Step 2.** Calling `session.add_child()` from inside the session's own `_ready()` chain should be allowed: the session isn't iterating its children at that moment. If the log shows a "busy setting up children" error, I'll stop and report it rather than work around it.

## Step 2: New state test, `godot/tests/test_dome_glints_state.gd`

It follows the Effect A state test:
- It loads the real `main.tscn` with `test_mode = true` and drives it only with `Input.parse_input_event` key events.
- `node_added` records every `DomeGlints` instance (B7) and every `LandPuff` (for A2).
- A check runs after every physics tick.
- It writes a JSON file to `evidence/` and prints `DOME GLINTS STATE TESTS: N checks / F failures`.
- It never calls the driver, `restart()` or `emitting =`.
- The only things the test writes are `get_tree().paused` (B5) and `glints.visible` (B6), as the brief says.

| Scenario | How it's driven | Assertions → rule |
|---|---|---|
| **Load** | `root.add_child(main)`, read before any tick, then 60 intro ticks | exactly one `DomeGlints`, parent is the session, `emitting == true`, position within 0.5 px of the dome point → **B1**; still `true` throughout `INTRO` → **B1** |
| **Esc pause** (own scenario, on plate 1, which has no fork) | Enter skips the intro; tap Esc → `PAUSED` for 60 ticks; tap Esc again | state is `PAUSED`; `emitting` stays `true` every tick; `can_process()` stays `true` (the tree isn't paused, so the glints keep running) → **B4** |
| **Tree pause** (own scenario) | `paused = true` for 60 ticks, then `false` | `emitting` stays `true`; the node is still in the tree; `glints.can_process() == false` while paused and `true` after → **B5** |
| **Hidden** (own scenario) | `glints.visible = false` for 60 ticks while `PLAYING`, then `true` | `emitting` stays `true`; `visible` stays `false` (the driver never changes it); `is_visible_in_tree() == false` → **B6** |
| **Run to the dome** (real keys) | keyboard route, see below | the tick the state becomes `WON`: `emitting` was `true` on the tick before and is `false` on that tick; the node is still in the tree → **B2**. During the whole `WON` stretch, including Space and D presses before the prompt: `emitting` stays `false`, no new `LandPuff`, `SFX-LAND` count unchanged → **B2, A2 (WON case)** |
| **Replay** | release D, wait for `prompt_shown`, tap Enter | the first tick in `PLAYING`: `emitting == true` → **B3**; still one instance → **B7** |
| **Second run and replay** | the same keyboard route again, win, replay | **B2, B3, A2** again; one instance after two replays → **B7** |
| **Whole-run checks** | after every tick of the run | `emitting == (state != WON)`, except while the tree is paused, when the state doesn't change → **B1–B4**; instance count is never above 1 → **B7**; `amount == 24` and `amount_ratio == 1.0` throughout (see below); puffs spawned equals the list of `SFX-LAND` frames (the A1 check, here proving the WON stretches added none) → **A2** |

**Reaching WON with key events only.** `route_driver.gd` uses `test_control`, which isn't real input, and I won't edit it. Instead, the test makes a `Route` instance only to use its read-only parts: `jump_marks`, `walk_ticks` and `plan()`. `plan()` reads the forks' fixed rhythms and never changes them. It translates each decision into key presses:
- Hold **D** until the jelly reaches the next jump mark, then release.
- At the planned tick, press **D + Space**, and release Space one tick later.
- After the last mark, hold D through the bare table into the dome.

The route asserts `splats == 0` on the way. If the keyboard version misses its timing and splats, the check fails and I'll report it. I won't adjust tuning or fork timings.

**A2 while WON.** The jelly is disabled in `WON`, so `just_landed` can't become true, and the driver also requires `PLAYING`. The test checks the result, not this reasoning: across both WON stretches, with keys pressed during them, no `LandPuff` is added, and the full puff-frame list still equals the `SFX-LAND` frame list. That closes the item Effect A left pending.

**The feedback-loop rule (`amount_ratio`, not `amount`) doesn't apply here.** Effect B is ambience on an on/off condition, and the brief ties no game value to its strength. So there's no value to set to two levels. The test only checks that the driver never changes either property: `amount == 24` and `amount_ratio == 1.0` throughout.

**What it proves:** with real key input through the real game loop, the single `DomeGlints` node's `emitting` follows `state != WON` on the right ticks, across two wins and two replays. It isn't affected by Esc, tree pause or hiding. Exactly one instance exists the whole time. No landing puff spawns while `WON`.

**What it can't prove headlessly.** The dummy renderer draws nothing and runs no particle process, so the test can't show:
- that glints are drawn or fade after the win;
- that `restart()` re-applies preprocess (it can't even show `restart()` was used rather than `emitting = true`; only the code shows that);
- that glints actually freeze under tree pause (`can_process() == false` is the switch that pauses them, not the freeze itself) or carry on from the same state afterwards;
- that glints are present when shown again.

## Step 3: Run every test through `./scripts/run-test.sh`, one command each

- **New test:** `test_dome_glints_state.gd` at **60**. It doesn't wait on audio, so it doesn't need realtime.
- **Existing suites, as CLAUDE.md lists them:**
  - `test_game`, `test_slice`, `test_keyboard`, `test_a3_assets` at 60 (baseline 25 / 61 / 12 / 36 checks).
  - `test_fork_warning` and `test_materials` at 30, 60 and 144 (baseline 29 / 108 checks).
  - The A6 tests `test_land_puff_config`, `test_land_puff_state` and `test_dome_glints_config` at 60.
- I'll show the real summary lines and exit codes. Every suite that builds a session will now also have a `DomeGlints`, so these runs are the regression check for that.

## What only you can check in the game window

- **B1 look:** steady density on the first intro frame, with no fill-in (strip frame 10).
- **B2:** after the win, the live glints keep rising and fade, and the dome is empty about 2.4 s later.
- **B3:** on replay the dome starts full, not refilling (predicted failure 5). Also whether `restart()` visibly cuts off glints left from the win when you replay quickly.
- **B4:** glints visibly keep drifting while Esc-paused.
- **B5:** glints visibly freeze under tree pause and continue from the same state.
- **B6:** glints are present when shown again (remote-tree toggle).
- **Predicted failure 6:** `visibility_rect` popping when the dome is at the screen edge. Also contrast over the room and the glass, and scale.

Do you approve Step 1, the driver change? I'll show the diff after it and won't start the test until you approve Step 2.