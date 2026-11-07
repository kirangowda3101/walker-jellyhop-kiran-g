I've read the brief, `session.gd`, `player.gd`, `land_puff.tscn`, `route_driver.gd`, the existing tests' input helpers and the level geometry. This is the plan only; I haven't edited any file.

# Plan: trigger Effect A and add its state test

## Step 1: the trigger code

**New file `godot/effects/effects_driver.gd`** (about 20 lines):

```gdscript
extends Node
## Presentation only: reads session state, never writes it (CHANGE-BRIEF.md, Boundaries).
const LAND_PUFF := preload("res://effects/land_puff.tscn")
@onready var session: Node2D = get_parent()

func _ready() -> void:
	process_physics_priority = 20   # after the session (10), which ticks after the jelly (0)

func _physics_process(_delta: float) -> void:
	# Same condition, same tick as SFX-LAND (session.gd line 372): state is read after resolve_contacts().
	if session.state == session.State.PLAYING and session.player.just_landed:
		var puff: GPUParticles2D = LAND_PUFF.instantiate()
		session.add_child(puff)                 # parent is the session, never the jelly (A7)
		puff.global_position = session.player.global_position   # the feet (A3)
		puff.emitting = true
		puff.finished.connect(puff.queue_free)  # A6
```

- **Why it fires exactly when `SFX-LAND` plays (A1, A2):** `process_physics_priority` decides which node's `_physics_process` runs first in each tick; lower runs earlier. With 20, the driver runs after the session in the same tick. Neither `state` nor `just_landed` can change between the two checks, so the driver's condition gives the same answer as the session's.
- **Retrigger rule (A4, overlap):** every landing instantiates a new puff. The driver keeps no reference to old puffs, so it can't restart, cut off or suppress them. The rule holds because the code never touches an earlier puff.
- **Cleanup (A6):** each puff frees itself on its own `finished` signal, as the brief says. Whether `finished` fires headless is Kiran's open prediction. I don't add the fallback timer in advance. If Step 2 shows that `finished` doesn't fire, I stop and report it. You record it, and the `lifetime + 0.1` s timer becomes a separate step.
- **Effect settings:** the driver sets only position and `emitting`. Connecting `finished` isn't on the CLAUDE.md list ("instances, places, sets `emitting` or `restart()`"), but A6 requires it. **Please approve that explicitly.**

**The one line in `session.gd` `_ready()` (needs your approval).** It goes just before `_start_intro()` (line 63):

```gdscript
	add_child(preload("res://effects/effects_driver.gd").new())
```

To show that line changes no behaviour, I run all existing suites after Step 1, as CLAUDE.md lists them: `test_game`, `test_slice`, `test_keyboard` and `test_a3_assets` at 60, and `test_fork_warning` and `test_materials` at 30, 60 and 144. They must match the baseline: 25, 61, 12, 36 and 29, 108, all with 0 failures. Puffs now appear in those runs on every landing, so this is a real check.

## Step 2: new test `godot/tests/test_land_puff_state.gd`

**How the test drives the game**
- **Mode:** run at 60 with `scripts/run-test.sh test_land_puff_state.gd 60`. It counts recorded `sound.play()` calls and doesn't wait on audio, so it doesn't need realtime.
- **Scene:** it loads the real `res://game/main.tscn` and sets `test_mode = true` before adding it to the tree, as the other game tests do, so losing focus doesn't pause the game.
- **Input:** every input is a real key event sent through `Input.parse_input_event` (D, Space, Esc, Enter), like `test_keyboard.gd`. `player.test_control` stays off. The test never calls the driver and never writes game, player or fork state.
- **The test only reads:** it reads the jelly's position to decide when to press or release a key. It reads `forks[1].harmless_in(k)` to wait for a safe window before hopping onto plate 2. The one thing it sets is `get_tree().paused`, for A8, which the brief asks for.
- **How it sees puffs:** after every tick it lists the `LandPuff` nodes in the tree (`scene_file_path == "res://effects/land_puff.tscn"`). For each new one it records the spawn tick, its position, the jelly's position, `emitting`, the session state and its parent. It also connects to each puff's `finished` signal to record when that fires.
- **Main cross-check:** each new puff is matched against the `SFX-LAND` entries in `sound.calls`, which record the tick of every call.

**The route, all on plates 1–2 and gaps 1–2:**
1. Load the scene, then 60 ticks of intro.
2. Press Enter to skip the intro. `start_session()` does a `reset_at()`, which is a respawn.
3. Tap Space for a hop straight up on plate 1, then wait.
4. **Two landings inside one lifetime:** hold D until x ≈ 345, release, tap Space for a hop straight up near the plate edge. On the landing tick, hold D. The jelly scoots off the edge and drops 22 px onto the bare table in gap 1. By the numbers in `tuning.gd`, that is about 9 ticks of walking plus 9 of falling, roughly 18 ticks, which is under the 24-tick lifetime.
5. Wait 60 ticks: one second after the last landing.
6. Hop with Space and D onto plate 2 once fork 2's window is safe. Keep holding D, walk off plate 2 into the sauce in gap 2, then wait through SPLAT, REFORM and the respawn on plate 2.
7. Hop and press Esc on the landing tick, so the puff is alive during PAUSED. Hold D and Space while paused, then press Esc again.
8. Hop and set `get_tree().paused = true` on the landing tick. Wait 60 ticks, unpause, then wait 60 more.

**Assertions:**

| # | Assertion | Rule |
|---|---|---|
| 1 | 0 puffs after load and 60 intro ticks | A2 (scene load, intro) |
| 2 | 0 puffs after the intro skip (`reset_at`) | A2 (respawn) |
| 3 | After every tick, puffs spawned == `sound.count("SFX-LAND")`, and the set of spawn ticks == the set of `SFX-LAND` ticks. Checked over the whole run, with at least 5 landings expected | A1 |
| 4 | Each puff has `emitting == true` on its spawn tick, and the session state was PLAYING on that tick | A1, A2 |
| 5 | Each puff's `global_position` is within 0.5 px of the jelly's on its spawn tick | A3 |
| 6 | The scoot-off pair are 2 separate instances, spawned less than 24 ticks apart. This proves the case really happened inside one lifetime | A4 setup |
| 7 | When the second puff spawns, the first is still in the tree | A4 (not cut off or suppressed) |
| 8 | The first puff's `finished` fires on its own schedule, counted from its own spawn, not pushed back by the second landing. A `restart()` would push it back. The second puff also emits and finishes | A4 (not restarted) |
| 9 | 60 ticks after the scoot-off landing, 0 `LandPuff` in the tree, and every puff's `finished` fired | A6 |
| 10 | Real sauce splat (`splat_cause == "sauce"`): no puff from the splat tick through SPLAT, REFORM and the respawn | A2 (sauce, SPLAT, REFORM, respawn) |
| 11 | Esc: the state is PAUSED, the puff alive then finishes and is freed, and no new puff appears while D and Space are held | A2 (PAUSED), A8 (session pause) |
| 12 | Tree pause: after 60 ticks, the puff is still in the tree, `emitting` hasn't changed and `finished` hasn't fired. After unpausing, it finishes and is freed | A8 (tree pause) |
| 13 | Every puff's parent is the session, never the jelly | A7 (structure only) |

The test also logs, without asserting:
- **The most puffs alive at once (A5):** this only reflects my route, so it can't confirm the game's real peak.
- **Whether the jelly was touching down on the sauce splat tick:** by the numbers, the sauce hit zone (y 508–522) probably triggers the splat during the fall, before touchdown. If so, the exact case of a landing tick that becomes a splat isn't exercised. It is still covered by construction, because the driver uses the same condition as `SFX-LAND`, and I'll report what happened.

## What this can't prove headlessly

- **Not covered by the test at all:**
  - **WON** is not in this test. Reaching the dome with real keys means routing past all five forks. Effect B's B1–B3 need that same real-input run, so I recommend building it once, in the Effect B step, and adding A2's WON check there. The other choice is a separate Step 3 for this test. I won't fake WON with `resolve_contacts("", true)`.
  - **A7 with the jelly actually freed:** the test would have to free the jelly, which writes game state. It only checks the parent.
- **Only you can check, in the running game:**
  - the look: timing phases, scale, contrast on plate and table, change over life;
  - variation, over ten or more landings;
  - whether the two puffs' crumbs visibly overlap, and whether each puff shows all 16 crumbs;
  - the real A5 peak;
  - the `visibility_rect` at the screen edge;
  - the `z_index` −1 draw order near the sauce and under a fork shadow.
- **What the headless node state shows:** headless uses a dummy renderer that draws nothing. The test sees node state only: instances, position, `emitting`, `finished`, parent. It shows that a puff was started, not that crumbs appeared. Whether `finished` fires in the windowed game also needs your check.

## Approvals I need before Step 1

1. The one `session.gd` line.
2. Connecting `finished` in the driver.
3. Where WON goes: the Effect B step (my recommendation) or a Step 3 here.