extends SceneTree
## A7 film capture driver (Claude Code, 2026-11-17). Lives in the film folder; run_captures.sh copies it into the
## disposable run copy (run-copy-c1bbb13/godot/capture/) only. It never touches the snapshot or the repository.
## SCRIPTED CAPTURE, not a human playtest.
##
## Plays the real game (res://game/main.tscn, session.gd) and drives it ONLY with InputEventKey through
## Input.parse_input_event + Input.flush_buffered_events, each event sent at the end of the physics tick before
## the tick that reads it. That input harness is the one in Kiran's committed tests/test_a7_edges.gd and
## tests/test_a7_pins.gd (key_for / send / until, a hook at physics priority 1000); the stationary-hop timing
## (press read -> touchdown 41 ticks) is PRESS_TO_TOUCHDOWN in previews/land_preview.gd and the pins' BASELINE
## line, and is re-measured below. It reads game state to decide when to press. It never writes game state,
## never moves the jelly, never calls the AnimationPlayer, never sets frame, scale, position, visible or
## pause. One disclosed setting, as in the A2, A5 and A6 films and in the A7 tests: game.test_mode = true
## (its only effect: no pause-on-focus-loss).
##
## Route, all on plate 1 (the starting plate, which has no fork; gap 1 has no sauce):
##   intro pan untouched -> "plain": a stationary hop, the full uninterrupted LAND (8 ticks) and IDLE
##   -> "scoot": hold A, hold D, hold A (scoot both ways, several 14-tick wraps, re-entries)
##   -> "handoff": a hop with D pressed 11 ticks before touchdown, so LAND (8 ticks, moving) hands off
##      directly to SCOOT on the next tick (the CHANGE-BRIEF.md Revision 2 entry)
##   -> "int_startup" k=1, "int_active" k=3, "int_recovery" k=6: a stationary hop, then a fresh jump press
##      read k ticks after touchdown (brief: "1: ANTIC at 1", "3: ANTIC at 3"; k=6 is inside Recovery 4-7).
## Checks every logged tick against the brief's rules (as the A7 state and edge tests do): LAND shows the rig
## and clip land at (8 - land_ticks)/60; SCOOT shows the scoot sprite and clip scoot at (tick % 14)/60 with
## cell 0 on ticks 0-6 and cell 1 on 7-13; every other pose shows the original sprite and no clip. Exit 0 and
## "CAPTURE OK" only if the route completed and every check passed.
## Log: one JSON line per process frame (after that frame's physics tick), plus event lines. Env: CAPTURE_LOG.

const MAIN := preload("res://game/main.tscn")
const Game = preload("res://game/session.gd")
const JUMP := KEY_SPACE
const LEFT := KEY_A
const RIGHT := KEY_D
const PRESS_TO_TOUCHDOWN := 41   # previews/land_preview.gd line 26; checked on every hop below
const SETTLE := 10               # grounded, PLAYING and IDLE this many ticks before a hop (as the pins)
const TOL := 1e-6
const FPS := 60.0
const LIMIT := 60 * 90

var game: Node2D
var hook: Node
var log_file: FileAccess
var pending: Array = []          # [code, pressed, read_tick]
var rows: Dictionary = {}        # physics frame -> row (after every node ran that tick)
var pframe := -1
var phase := "intro"
var checks := 0
var failures := 0
var fail_notes: Array[String] = []
var summary: Array[String] = []

class TickHook extends Node:
	## Runs after the player (priority 0), session (10) and effects driver (20) in every physics tick.
	var on_tick: Callable
	func _physics_process(_delta: float) -> void:
		on_tick.call()

func _initialize() -> void:
	var path := OS.get_environment("CAPTURE_LOG")
	if path == "":
		push_error("CAPTURE_LOG not set")
		quit(1)
		return
	log_file = FileAccess.open(path, FileAccess.WRITE)
	game = MAIN.instantiate()
	game.test_mode = true        # disclosed above
	root.add_child(game)
	hook = TickHook.new()
	hook.name = "CaptureTickHook"
	hook.process_physics_priority = 1000
	hook.on_tick = _on_tick
	root.add_child(hook)
	process_frame.connect(_on_process_frame)
	_log({"event": "start", "engine": Engine.get_version_info().string,
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"physics_ticks_per_second": Engine.physics_ticks_per_second})
	call_deferred("run")

func now() -> int:
	return Engine.get_physics_frames()

func _log(entry: Dictionary) -> void:
	entry["physics_frame"] = now()
	log_file.store_line(JSON.stringify(entry))
	log_file.flush()

# ---------------------------------------------------------------- input (harness of tests/test_a7_edges.gd)

func key_for(read_tick: int, code: Key, pressed: bool) -> void:
	if now() > read_tick - 1:
		_fail("input scheduled too late: read_tick %d now %d" % [read_tick, now()])
	pending.append([code, pressed, read_tick])

func send(code: Key, pressed: bool, read_tick: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	_log({"event": "key_down" if pressed else "key_up", "key": OS.get_keycode_string(code), "read_tick": read_tick})

func until(t: int) -> void:
	while now() < t:
		await physics_frame

func _on_tick() -> void:
	_row()
	var keep: Array = []
	for e in pending:
		if int(e[2]) == now() + 1:
			send(e[0], e[1], e[2])
		elif int(e[2]) <= now():
			_fail("input not sent in time: read_tick %d now %d" % [e[2], now()])
		else:
			keep.append(e)
	pending = keep

# ---------------------------------------------------------------- per-tick state (read only)

func _vis(p) -> String:
	var s: bool = p.sprite.visible
	var c: bool = p.scoot_node.visible
	var l: bool = p.land_rig.visible
	if s and not c and not l:
		return "sprite"
	if c and not s and not l:
		return "scoot"
	if l and not s and not c:
		return "rig"
	return "mixed"

func _row() -> void:
	var p = game.player
	if p == null or p.visuals == null:
		return
	var ap: AnimationPlayer = p.anim
	var cur := String(ap.current_animation)
	var pos := -1.0
	if cur != "":
		pos = ap.current_animation_position
	var sp: Sprite2D = p.visuals.get_node("FacingPivot/Scoot/ScootSprite")
	var lower: Node2D = p.visuals.get_node("FacingPivot/LandRig/LowerPivot")
	var upper: Node2D = p.visuals.get_node("FacingPivot/LandRig/UpperPivot")
	var r := {"tick": now(), "ptick": int(p.tick), "pose": p.pose, "land_ticks": int(p.land_ticks),
		"just_landed": p.just_landed, "just_hopped": p.just_hopped, "floor": p.is_on_floor(),
		"state": Game.State.keys()[game.state], "cur": cur, "pos": pos, "cell": sp.frame, "facing": p.facing,
		"vis": _vis(p), "x": snappedf(p.position.x, 0.01), "vx": snappedf(p.velocity.x, 0.01),
		"lower_sy": snappedf(lower.scale.y, 0.0001), "lower_sx": snappedf(lower.scale.x, 0.0001),
		"upper_y": snappedf(upper.position.y, 0.001), "phase": phase}
	rows[now()] = r
	_check_rules(r)

func _check_rules(r: Dictionary) -> void:
	if r.state != "PLAYING" or r.phase == "intro":
		return
	var pose: String = r.pose
	if pose == "LAND":
		var exp_t := float(8 - int(r.land_ticks)) / FPS
		_check(r.vis == "rig" and r.cur == "land" and absf(float(r.pos) - exp_t) <= TOL,
			"LAND rule at tick %d: vis %s cur %s pos %.9f expected %.9f" % [r.tick, r.vis, r.cur, r.pos, exp_t])
	elif pose == "SCOOT-A" or pose == "SCOOT-B":
		var ph := int(r.ptick) % 14
		var exp_s := float(ph) / FPS
		var d := absf(float(r.pos) - exp_s)
		d = minf(d, 14.0 / FPS - d)
		var want_cell := 0 if ph < 7 else 1
		_check(r.vis == "scoot" and r.cur == "scoot" and d <= TOL and int(r.cell) == want_cell,
			"SCOOT rule at tick %d: vis %s cur %s pos %.9f expected %.9f cell %d want %d" % [r.tick, r.vis, r.cur, r.pos, exp_s, r.cell, want_cell])
	else:
		_check(r.vis == "sprite" and r.cur == "", "sprite rule at tick %d: pose %s vis %s cur %s" % [r.tick, pose, r.vis, r.cur])

func _check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		_fail(note)

func _fail(note: String) -> void:
	failures += 1
	if fail_notes.size() < 20:
		fail_notes.append(note)
	_log({"event": "fail", "note": note})

func _on_process_frame() -> void:
	## One line per process frame = one movie frame (Movie Maker, --fixed-fps 60, one physics tick per frame).
	pframe += 1
	var p = game.player
	if p == null:
		return
	var r: Dictionary = rows.get(now(), {}).duplicate()
	var s: Vector2 = p.get_global_transform_with_canvas().origin
	r["event"] = "frame"
	r["pframe"] = pframe
	r["sx"] = snappedf(s.x, 0.1)
	r["sy"] = snappedf(s.y, 0.1)
	_log(r)

func row_at(t: int) -> Dictionary:
	return rows.get(t, {})

# ---------------------------------------------------------------- route

func set_phase(name: String) -> void:
	phase = name
	_log({"event": "phase", "phase": name})

func wait_ready() -> int:
	var streak := 0
	var guard := 0
	while guard < 900:
		await physics_frame
		guard += 1
		var r := row_at(now() - 1)
		if not r.is_empty() and r.state == "PLAYING" and r.floor and r.pose == "IDLE":
			streak += 1
		else:
			streak = 0
		if streak >= SETTLE:
			return now()
	_fail("never ready (phase %s)" % phase)
	return -1

func stationary_hop() -> int:
	var ready := await wait_ready()
	if ready < 0:
		return -1
	var h := ready + 1
	key_for(h, JUMP, true)
	key_for(h + 2, JUMP, false)
	return h

func hold_until(code: Key, cond: Callable, max_ticks: int) -> void:
	key_for(now() + 1, code, true)
	var start := now()
	while now() < start + max_ticks:
		await physics_frame
		if cond.call(row_at(now() - 1)):
			break
	key_for(now() + 1, code, false)
	await until(now() + 2)

func first_tick(from: int, to: int, field: String) -> int:
	for t in range(from, to + 1):
		if row_at(t).get(field, false):
			return t
	return -1

func poses(from: int, to: int) -> String:
	var out: Array[String] = []
	for t in range(from, to + 1):
		out.append("%d:%s" % [t - from, row_at(t).get("pose", "?")])
	return " ".join(out)

func run() -> void:
	# Intro pan untouched; the session goes INTRO -> PLAYING by itself.
	var guard := 0
	while game.state != Game.State.PLAYING and guard < LIMIT:
		await physics_frame
		guard += 1
	var center: float = game.spawn_point(0).x
	_log({"event": "playing", "plate1_center_x": center})

	# 1. plain landing
	set_phase("plain")
	var h := await stationary_hop()
	var t0 := await touchdown(h, "plain")
	await until(t0 + 40)
	_expect_land(t0, 8, "plain")

	# 2. scoot both ways
	set_phase("scoot")
	await wait_ready()
	await hold_until(LEFT, func(r): return r.get("x", 1e9) <= center - 60.0, 120)
	await until(now() + 20)
	await hold_until(RIGHT, func(r): return r.get("x", -1e9) >= center + 60.0, 120)
	await until(now() + 20)
	await hold_until(LEFT, func(r): return r.get("x", 1e9) <= center - 55.0, 120)

	# 3. direct LAND -> SCOOT hand-off
	set_phase("handoff")
	h = await stationary_hop()
	key_for(h + PRESS_TO_TOUCHDOWN - 11, RIGHT, true)
	t0 = await touchdown(h, "handoff")
	var guard2 := 0
	while row_at(now() - 1).get("x", 0.0) < center + 75.0 and guard2 < 60:
		await physics_frame
		guard2 += 1
	key_for(now() + 1, RIGHT, false)
	await until(now() + 30)
	var sw := row_at(t0 + 8)
	var ok_handoff: bool = row_at(t0 + 7).get("pose", "") == "LAND" and str(sw.get("pose", "")).begins_with("SCOOT") and sw.get("cur", "") == "scoot"
	_check(ok_handoff, "handoff: LAND at +7 and SCOOT (clip scoot) at +8: %s" % poses(t0, t0 + 10))
	summary.append("handoff touchdown %d, SCOOT from %d (ptick %d, phase %d)" % [t0, t0 + 8, int(sw.get("ptick", -1)), int(sw.get("ptick", -1)) % 14])
	_log({"event": "handoff", "touchdown": t0, "switch_tick": t0 + 8, "poses": poses(t0 - 1, t0 + 10)})
	await hold_until(LEFT, func(r): return r.get("x", 1e9) <= center, 120)

	# 4. interrupts, one in each phase of the landing
	for c in [["int_startup", 1], ["int_active", 3], ["int_recovery", 6]]:
		set_phase(c[0])
		var k: int = c[1]
		h = await stationary_hop()
		var t0e := h + PRESS_TO_TOUCHDOWN
		key_for(t0e + k, JUMP, true)
		key_for(t0e + k + 2, JUMP, false)
		t0 = await touchdown(h, c[0])
		await until(t0e + k + PRESS_TO_TOUCHDOWN + 40)   # the hop, its flight and the second landing have all run
		var hop := first_tick(t0e - 2, t0e + 20, "just_hopped")
		_check(hop - t0 == k, "%s: hop at +%d, expected +%d" % [c[0], hop - t0, k])
		for rel in range(0, k):
			_check(row_at(t0 + rel).get("pose", "") == "LAND", "%s: LAND at +%d" % [c[0], rel])
		_check(row_at(t0 + k).get("pose", "") == "ANTIC", "%s: ANTIC at +%d" % [c[0], k])
		var t1 := first_tick(t0 + k + 1, t0 + k + 80, "just_landed")
		_check(t1 > 0, "%s: second landing" % c[0])
		await until(t1 + 40)
		_expect_land(t1, 8, c[0] + " second landing")
		summary.append("%s touchdown %d, press read %d, hop %d, second touchdown %d" % [c[0], t0, t0e + k, hop, t1])
		_log({"event": "interrupt", "case": c[0], "k": k, "touchdown": t0, "hop": hop, "second_touchdown": t1,
			"poses": poses(t0 - 1, t0 + k + 2)})

	set_phase("end")
	await until(now() + 30)
	var ok := failures == 0 and checks > 500
	_log({"event": "end", "ok": ok, "checks": checks, "failures": failures, "summary": summary, "fails": fail_notes})
	log_file.close()
	print("CAPTURE %s: checks=%d failures=%d; %s; %s" % ["OK" if ok else "FAILED", checks, failures, " | ".join(summary), " | ".join(fail_notes)])
	quit(0 if ok else 1)

func touchdown(h: int, name: String) -> int:
	var exp := h + PRESS_TO_TOUCHDOWN
	await until(exp + 3)
	var t0 := first_tick(h + 1, exp + 2, "just_landed")
	_check(h > 0 and t0 == exp, "%s: touchdown at %d, expected %d (press read %d)" % [name, t0, exp, h])
	_log({"event": "touchdown", "phase": name, "press_read": h, "touchdown": t0})
	return t0

func _expect_land(t0: int, n: int, name: String) -> void:
	for rel in range(0, n):
		_check(row_at(t0 + rel).get("pose", "") == "LAND", "%s: LAND at +%d" % [name, rel])
	_check(row_at(t0 + n).get("pose", "") != "LAND", "%s: not LAND at +%d" % [name, n])
