extends SceneTree
## A7 Step 6: the 12 cases of CHANGE-BRIEF.md "Jump interrupt predictions", checked tick by tick against the
## wired visual layer in the real game (session.gd). Real key events only: Input.parse_input_event + flush,
## each sent at the end of the tick before the one that reads it. The input harness (key_for, send, until,
## the hook's dispatch, start_run, wait_ready, stationary_hop, first_tick_where) is copied unchanged from
## test_a7_pins.gd; only the pins' PINDIGEST hashing is left out. A fresh game per case. Never test_control,
## never a direct call to a transition. Scripted input; this is not human playtesting. Headless: nothing is
## drawn, so no check here says anything about pixels.
##
## Tick 0 = the baseline touchdown, measured in a first fresh run (press -> touchdown), as the pins do.
## For each case, every tick from touchdown - 1 to the predicted hop + 2 gets four checks, read after every
## game node has run in that tick (hook at priority 1000):
##   pose      the pose the table predicts: FALL at -1, LAND from 0 until the hop (IDLE at 8 for "8, after"),
##             ANTIC from the hop on;
##   LAND tick visual-rig (LandRig the only visible visual), clip-land (current_animation "land"),
##             clip-time ((8 - land_ticks) / 60 within 1e-6 s);
##   otherwise clip-none (current_animation ""), visual-sprite (original sprite the only visible visual),
##             sprite-texture (the original sprite shows CHAR-<predicted pose>.png).
## Expected values come from the brief's table, not from player.gd.
const Game = preload("res://game/session.gd")
const SLOT := 600        # each run starts on a physics frame that is a multiple of this (same tick at every rate)
const SETTLE := 10       # grounded, PLAYING and IDLE this many ticks before the stationary hop press
const JUMP_KEY := KEY_SPACE
const TIME_TOL := 1e-6   # seconds
const FPS := 60.0
const LAND_N := 8        # brief: length 8/60, the existing eight-tick window

## Copied from test_a7_pins.gd. k: physics tick (relative to touchdown) on which the fresh press is read.
## hop: tick the hop fires and ANTIC shows. land0: LAND shown at 0. idle8: IDLE shown at 8.
const CASES := [
	{"boundary": 0, "column": "before", "k": -1, "hop": 1, "land0": true, "predicted": "-1: buffer; LAND at 0, ANTIC at 1"},
	{"boundary": 0, "column": "on", "k": 0, "hop": 1, "land0": true, "predicted": "0: buffer; LAND at 0, ANTIC at 1"},
	{"boundary": 0, "column": "after", "k": 1, "hop": 1, "predicted": "1: ANTIC at 1"},
	{"boundary": 2, "column": "before", "k": 1, "hop": 1, "predicted": "1: ANTIC at 1"},
	{"boundary": 2, "column": "on", "k": 2, "hop": 2, "predicted": "2: ANTIC at 2"},
	{"boundary": 2, "column": "after", "k": 3, "hop": 3, "predicted": "3: ANTIC at 3"},
	{"boundary": 4, "column": "before", "k": 3, "hop": 3, "predicted": "3: ANTIC at 3"},
	{"boundary": 4, "column": "on", "k": 4, "hop": 4, "predicted": "4: ANTIC at 4"},
	{"boundary": 4, "column": "after", "k": 5, "hop": 5, "predicted": "5: ANTIC at 5"},
	{"boundary": 8, "column": "before", "k": 7, "hop": 7, "predicted": "7: ANTIC at 7"},
	{"boundary": 8, "column": "on", "k": 8, "hop": 8, "predicted": "8: ANTIC at 8 instead of IDLE"},
	{"boundary": 8, "column": "after", "k": 9, "hop": 9, "idle8": true, "predicted": "9: IDLE at 8, then ANTIC at 9"},
]

var game: Node2D
var hook: Node
var run_name := ""
var run_first_logged := false
var by_tick: Dictionary = {}     # physics frame -> row of the current run
var reads: Array[int] = []       # physics frames on which the jump action was just pressed
var checks := 0
var failures := 0
var case_counts: Array = []      # [case id, checks, failures] per case

class TickHook extends Node:
	## Runs after the player (priority 0), session (10) and effects driver (20) in every physics tick.
	var on_tick: Callable
	func _physics_process(_delta: float) -> void:
		on_tick.call()

func _initialize() -> void:
	call_deferred("run")

func now() -> int:
	return Engine.get_physics_frames()

func check(id: String, passed: bool, observed: Dictionary) -> void:
	checks += 1
	if not passed:
		failures += 1
	print("CHECK " + JSON.stringify({"id": id, "status": "PASS" if passed else "FAIL", "observed": observed}))

func f12(x: float) -> String:
	return "%.12f" % x

# ---------------------------------------------------------------- input (real key events only; from test_a7_pins.gd)

var pending: Array = []          # [code, pressed, read_tick]: sent at the end of physics frame read_tick - 1

func key_for(read_tick: int, code: Key, pressed: bool) -> void:
	## Schedules a key event so the player's _physics_process reads it on physics frame read_tick.
	## Must be called no later than the start of frame read_tick - 1.
	if now() > read_tick - 1:
		check("harness-input-scheduled-in-time", false, {"read_tick": read_tick, "now": now(), "key": OS.get_keycode_string(code)})
	pending.append([code, pressed, read_tick])

func send(code: Key, pressed: bool, read_tick: int) -> void:
	## The game's InputMap holds InputEventKey events with physical_keycode (session.gd lines 73-76).
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	# parse_input_event buffers the event (Input.use_accumulated_input). Without a flush it is applied at
	# the next main-loop iteration, which is 1 or 2 physics ticks away depending on the render rate. With
	# the flush it is applied now, during physics frame now(); Godot then reports it as just pressed on
	# frame now() + 1, which is why events are sent at the end of the frame before the reading frame.
	Input.flush_buffered_events()
	print("INPUT %s tick=%d frame=%d key=%s pressed=%s read_tick=%d" % [run_name, now(), Engine.get_process_frames(), OS.get_keycode_string(code), pressed, read_tick])

func until(t: int) -> void:
	## Returns at the start of physics frame t, before any node's _physics_process in that frame.
	while now() < t:
		await physics_frame

# ---------------------------------------------------------------- per-tick log

func _log_tick() -> void:
	_log_row()
	# After every game node has run this frame: send the events to be read on the next frame.
	var keep: Array = []
	for e in pending:
		if int(e[2]) == now() + 1:
			send(e[0], e[1], e[2])
		elif int(e[2]) <= now():
			check("harness-input-sent-in-time", false, {"read_tick": e[2], "now": now()})
		else:
			keep.append(e)
	pending = keep

func vis_of(p) -> String:
	var s: bool = p.sprite.visible
	var c: bool = p.scoot_node.visible
	var l: bool = p.land_rig.visible
	if s and not c and not l:
		return "sprite"
	if c and not s and not l:
		return "scoot"
	if l and not s and not c:
		return "rig"
	return "mixed(sprite=%s,scoot=%s,rig=%s)" % [s, c, l]

func _log_row() -> void:
	if run_name == "" or not is_instance_valid(game) or game.player == null or game.player.visuals == null:
		return
	var p = game.player
	var ap: AnimationPlayer = p.anim
	var t := now()
	var f := Engine.get_process_frames()
	if not run_first_logged:
		run_first_logged = true
		print("RUN %s first_tick=%d first_frame=%d frames_drawn=%d" % [run_name, t, f, Engine.get_frames_drawn()])
	var cur := String(ap.current_animation)
	var pos := NAN
	if cur != "":
		pos = ap.current_animation_position
	var tex: String = p.sprite.texture.resource_path.get_file() if p.sprite.texture else "none"
	var row := {"tick": t, "frame": f, "ptick": int(p.tick), "pose": p.pose, "land_ticks": int(p.land_ticks),
		"just_landed": p.just_landed, "just_hopped": p.just_hopped, "floor": p.is_on_floor(), "state": game.state,
		"cur": cur, "pos": pos, "vis": vis_of(p), "sprite_visible": p.sprite.visible,
		"scoot_visible": p.scoot_node.visible, "rig_visible": p.land_rig.visible, "tex": tex}
	by_tick[t] = row
	print("EDGE %s tick=%d frame=%d ptick=%d pose=%s land_ticks=%d just_landed=%s just_hopped=%s floor=%s cur=\"%s\" pos=%s vis=%s tex=%s" % [
		run_name, t, f, row.ptick, row.pose, row.land_ticks, row.just_landed, row.just_hopped, row.floor, cur, f12(pos), row.vis, tex])
	if Input.is_action_just_pressed("jump"):
		reads.append(t)
		print("READ %s tick=%d ptick=%d jump_just_pressed=true" % [run_name, t, row.ptick])
	if p.just_hopped:
		print("HOP %s tick=%d ptick=%d" % [run_name, t, row.ptick])

func row_at(t: int) -> Dictionary:
	return by_tick.get(t, {})

# ---------------------------------------------------------------- runs (from test_a7_pins.gd)

func start_run(name: String) -> void:
	## A fresh game, added at the start of a physics frame that is a multiple of SLOT.
	if is_instance_valid(game):
		run_name = ""
		game.queue_free()
		await process_frame
		await process_frame
	await until((now() / SLOT + 1) * SLOT)
	by_tick.clear()
	reads.clear()
	pending.clear()
	run_first_logged = false
	run_name = name
	game = Game.new()
	game.test_mode = true
	root.add_child(game)

func wait_ready() -> int:
	## Waits until the session is PLAYING and the jelly has been grounded and IDLE for SETTLE ticks.
	## Returns at the start of frame now(); the hop press is then read on frame now() + 1.
	var streak := 0
	var guard := 0
	while guard < SLOT:
		await physics_frame
		guard += 1
		var r := row_at(now() - 1)
		if not r.is_empty() and r.state == Game.State.PLAYING and r.floor and r.pose == "IDLE":
			streak += 1
		else:
			streak = 0
		if streak >= SETTLE:
			return now()
	return -1

func stationary_hop() -> int:
	## Returns the physics frame on which the stationary hop press is read.
	var ready := await wait_ready()
	if ready < 0:
		return -1
	var h := ready + 1
	key_for(h, JUMP_KEY, true)
	key_for(h + 2, JUMP_KEY, false)
	return h

func first_tick_where(from: int, to: int, field: String) -> int:
	for t in range(from, to + 1):
		if row_at(t).get(field, false):
			return t
	return -1

func run() -> void:
	hook = TickHook.new()
	hook.name = "EdgeTickHook"
	hook.process_physics_priority = 1000
	hook.on_tick = _log_tick
	root.add_child(hook)
	print("A7 EDGES: engine=%s physics_ticks_per_second=%d" % [Engine.get_version_info().string, Engine.physics_ticks_per_second])
	var d := await baseline()
	if d > 0:
		for c in CASES:
			await edge_case(c, d)
	else:
		print("A7 EDGES: baseline did not give a touchdown; cases not run")
	run_name = ""
	for cc in case_counts:
		print("CASE-COUNT %s checks=%d failures=%d" % cc)
	print("A7 EDGES: %d checks / %d failures" % [checks, failures])
	if is_instance_valid(game):
		game.queue_free()
	hook.queue_free()
	for i in range(30):
		await process_frame
	quit(1 if failures else 0)

# ---------------------------------------------------------------- baseline: press -> touchdown

func baseline() -> int:
	await start_run("baseline")
	var h := await stationary_hop()
	var t0 := -1
	while t0 < 0 and h > 0 and now() < h + 200:
		await physics_frame
		if row_at(now() - 1).get("just_landed", false):
			t0 = now() - 1
	var ok: bool = h > 0 and t0 > h and reads == [h] and row_at(h).get("just_hopped", false)
	check("baseline-harness-press-read-on-hop-tick-and-touchdown", ok,
		{"press_tick": h, "touchdown_tick": t0, "jump_read_ticks": reads.duplicate()})
	print("BASELINE press_tick=%d touchdown_tick=%d press_to_touchdown=%d" % [h, t0, t0 - h])
	return (t0 - h) if ok else -1

# ---------------------------------------------------------------- the 12 cases

func predicted_pose(c: Dictionary, rel: int) -> String:
	## From the brief's table: FALL before contact, LAND from touchdown until the hop (the existing
	## eight-tick window, so IDLE at 8 when the hop is at 9), ANTIC from the hop on.
	if rel < 0:
		return "FALL"
	if rel >= int(c.hop):
		return "ANTIC"
	if rel >= LAND_N:
		return "IDLE"
	return "LAND"

func edge_case(c: Dictionary, d: int) -> void:
	var cid := "b%d-%s-k%+d" % [c.boundary, c.column, c.k]
	var checks0 := checks
	var failures0 := failures
	await start_run("edge_" + cid)
	var h := await stationary_hop()
	var t0e := h + d
	var press := t0e + int(c.k)
	key_for(press, JUMP_KEY, true)       # fresh: the stationary press was released at h + 2
	key_for(press + 2, JUMP_KEY, false)
	await until(t0e + 21)
	var t0 := first_tick_where(h + 1, t0e + 20, "just_landed")
	var hop := first_tick_where(t0e - 2, t0e + 20, "just_hopped")   # the case hop, not the stationary one
	check("%s-harness-same-touchdown-and-press-read" % cid, h > 0 and t0 == t0e and press in reads and h in reads,
		{"stationary_press_tick": h, "expected_touchdown": t0e, "observed_touchdown": t0, "case_press_tick": press, "jump_read_ticks": reads.duplicate()})
	check("%s-hop-at-predicted-tick" % cid, hop >= 0 and hop - t0e == int(c.hop),
		{"predicted_hop_rel": c.hop, "observed_hop_rel": (hop - t0e) if hop >= 0 else null})
	var predicted: Array[String] = []
	var observed: Array[String] = []
	for rel in range(-1, int(c.hop) + 3):
		var r := row_at(t0e + rel)
		var want := predicted_pose(c, rel)
		var pose := str(r.get("pose", "?"))
		var cur := str(r.get("cur", "?"))
		var pos: float = float(r.get("pos", NAN))
		var lt: int = int(r.get("land_ticks", -1))
		var vis := str(r.get("vis", "?"))
		var tex := str(r.get("tex", "?"))
		predicted.append("%d:%s" % [rel, want])
		observed.append("%d:%s/%s/%s/%s" % [rel, pose, cur if cur != "" else "-", vis, f12(pos) if cur != "" else "-"])
		var base := {"rel": rel, "tick": t0e + rel, "predicted_pose": want, "pose": pose, "land_ticks": lt, "cur": cur, "vis": vis}
		check("%s-rel%+d-pose" % [cid, rel], pose == want, base)
		if want == "LAND":
			var exp_t := float(LAND_N - lt) / FPS
			check("%s-rel%+d-land-visual-rig-only" % [cid, rel], vis == "rig",
				{"rel": rel, "vis": vis, "sprite_visible": r.get("sprite_visible"), "scoot_visible": r.get("scoot_visible"), "rig_visible": r.get("rig_visible")})
			check("%s-rel%+d-land-clip" % [cid, rel], cur == "land", {"rel": rel, "cur": cur})
			check("%s-rel%+d-land-clip-time" % [cid, rel], absf(pos - exp_t) <= TIME_TOL,
				{"rel": rel, "land_ticks": lt, "expected_s": f12(exp_t), "actual_s": f12(pos), "diff_ticks": "%.6f" % ((pos - exp_t) * FPS)})
		else:
			check("%s-rel%+d-%s-no-clip" % [cid, rel, want.to_lower()], cur == "", {"rel": rel, "cur": cur})
			check("%s-rel%+d-%s-visual-sprite-only" % [cid, rel, want.to_lower()], vis == "sprite",
				{"rel": rel, "vis": vis, "sprite_visible": r.get("sprite_visible"), "scoot_visible": r.get("scoot_visible"), "rig_visible": r.get("rig_visible")})
			var want_tex := "CHAR-%s.png" % want
			check("%s-rel%+d-%s-sprite-texture" % [cid, rel, want.to_lower()], tex == want_tex, {"rel": rel, "expected": want_tex, "tex": tex})
	print("CASE %s predicted=\"%s\" hop_rel=%s" % [cid, c.predicted, str(hop - t0e) if hop >= 0 else "none"])
	print("CASE %s predicted_poses %s" % [cid, " ".join(predicted)])
	print("CASE %s observed (rel:pose/clip/visual/time) %s" % [cid, " ".join(observed)])
	case_counts.append([cid, checks - checks0, failures - failures0])
	run_name = ""
