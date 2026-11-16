extends SceneTree
## A7 Step 2: behaviour pins of the existing game, before any clip, sheet or visual scene exists.
## Real game (session.gd) and real key events through Input.parse_input_event only; every press and
## release is scheduled by physics tick. Scripted input; this is not human playtesting. Prints only.
## Optional: `-- --baseline-only` (after the script's "--") runs only the baseline run (Movie Maker replay).
const Game = preload("res://game/session.gd")
const SLOT := 600        # each run starts on a physics frame that is a multiple of this (same tick at every rate)
const SETTLE := 10       # grounded, PLAYING and IDLE this many ticks before the stationary hop press
const JUMP_KEY := KEY_SPACE
const RIGHT_KEY := KEY_D
const LEFT_KEY := KEY_A
const LOW := Vector2(52, 44)
const STANDING := Vector2(52, 58)

## The 12 cases in CHANGE-BRIEF.md, "Jump interrupt predictions". k: physics tick (relative to touchdown)
## on which the fresh press is read. hop: tick the hop fires and ANTIC shows. land0: LAND shown at 0.
## idle8: IDLE shown at 8.
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
var digest: HashingContext
var digest_lines := 0

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

# ---------------------------------------------------------------- input (real key events only)

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

func _log_row() -> void:
	if run_name == "" or not is_instance_valid(game) or game.player == null:
		return
	var p = game.player
	var t := now()
	var f := Engine.get_process_frames()
	if not run_first_logged:
		run_first_logged = true
		print("RUN %s first_tick=%d first_frame=%d frames_drawn=%d" % [run_name, t, f, Engine.get_frames_drawn()])
	var tex: String = p.sprite.texture.resource_path.get_file() if p.sprite.texture else "none"
	var row := {"tick": t, "frame": f, "ptick": p.tick, "pose": p.pose, "land_ticks": p.land_ticks,
		"just_landed": p.just_landed, "just_hopped": p.just_hopped, "box": p.box, "facing": p.facing,
		"flip_h": p.sprite.flip_h, "tex": tex, "floor": p.is_on_floor(), "vx": roundi(p.velocity.x),
		"state": game.state}
	by_tick[t] = row
	var head := "PIN %s tick=%d" % [run_name, t]
	var tail := "ptick=%d pose=%s land_ticks=%d just_landed=%s box=%dx%d facing=%s flip_h=%s tex=%s floor=%s vx=%d" % [
		row.ptick, row.pose, row.land_ticks, row.just_landed, int(row.box.x), int(row.box.y),
		str(row.facing), row.flip_h, tex, row.floor, row.vx]
	print("%s frame=%d %s" % [head, f, tail])
	# Digest of the PIN lines without frame= (render frames differ by rate by design), to compare rates.
	digest.update((head + " " + tail + "\n").to_utf8_buffer())
	digest_lines += 1
	if Input.is_action_just_pressed("jump"):
		reads.append(t)
		print("READ %s tick=%d ptick=%d jump_just_pressed=true" % [run_name, t, row.ptick])
	if p.just_hopped:
		print("HOP %s tick=%d ptick=%d" % [run_name, t, row.ptick])

func row_at(t: int) -> Dictionary:
	return by_tick.get(t, {})

func pose_at(t: int) -> String:
	return str(row_at(t).get("pose", "?"))

# ---------------------------------------------------------------- runs

func end_digest() -> void:
	if run_name != "":
		print("PINDIGEST %s lines=%d sha256_without_frame=%s" % [run_name, digest_lines, digest.finish().hex_encode()])

func start_run(name: String) -> void:
	## A fresh game, added at the start of a physics frame that is a multiple of SLOT.
	end_digest()
	digest = HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest_lines = 0
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
	hook.name = "PinTickHook"
	hook.process_physics_priority = 1000
	hook.on_tick = _log_tick
	root.add_child(hook)
	var baseline_only := "--baseline-only" in OS.get_cmdline_user_args()
	print("A7 PINS: engine=%s baseline_only=%s physics_ticks_per_second=%d" % [Engine.get_version_info().string, baseline_only, Engine.physics_ticks_per_second])
	var d := await baseline()
	if not baseline_only:
		await interrupts(d)
	end_digest()
	run_name = ""
	print("A7 PINS: %d checks / %d failures" % [checks, failures])
	if is_instance_valid(game):
		game.queue_free()
	hook.queue_free()
	for i in range(30):
		await process_frame
	quit(1 if failures else 0)

# ---------------------------------------------------------------- baseline

func baseline() -> int:
	await start_run("baseline")
	var h := await stationary_hop()
	# Touchdown: the tick the player reports just_landed.
	var t0 := -1
	while t0 < 0 and now() < h + 200:
		await physics_frame
		if row_at(now() - 1).get("just_landed", false):
			t0 = now() - 1
	check("baseline-harness-ready-and-press-read-on-hop-tick", h > 0 and reads == [h] and row_at(h).get("just_hopped", false),
		{"press_tick": h, "jump_read_ticks": reads.duplicate(), "hop_on_press_tick": row_at(h).get("just_hopped", false)})
	print("BASELINE press_tick=%d touchdown_tick=%d press_to_touchdown=%d" % [h, t0, t0 - h])
	# Settle in IDLE, then scoot right, stop, scoot left, stop.
	var right_on := t0 + 30
	var right_off := right_on + 20
	var left_on := right_off + 25
	var left_off := left_on + 36
	var end := left_off + 25
	key_for(right_on, RIGHT_KEY, true)
	key_for(right_off, RIGHT_KEY, false)
	key_for(left_on, LEFT_KEY, true)
	key_for(left_off, LEFT_KEY, false)
	await until(end + 1)   # row for `end` is complete
	var hop_window := range(h, right_on)
	# 1. Pose order through the hop.
	var seq: Array[String] = []
	for t in hop_window:
		if seq.is_empty() or seq.back() != pose_at(t):
			seq.append(pose_at(t))
	check("baseline-1-hop-pose-order", seq == ["ANTIC", "RISE", "FALL", "LAND", "IDLE"], {"sequence": seq, "from_tick": h, "to_tick": right_on - 1})
	# 2. just_landed on exactly one tick.
	var landed: Array[int] = []
	for t in hop_window:
		if row_at(t).get("just_landed", false):
			landed.append(t)
	check("baseline-2-just-landed-once", landed.size() == 1, {"just_landed_ticks": landed})
	# 3. LAND lasts exactly 8 ticks, starting on the just_landed tick.
	var land: Array[int] = []
	for t in hop_window:
		if pose_at(t) == "LAND":
			land.append(t)
	var want_land: Array[int] = []
	for t in range(t0, t0 + 8):
		want_land.append(t)
	check("baseline-3-land-8-ticks-from-just-landed", land == want_land and landed == [t0], {"land_ticks": land, "touchdown_tick": t0, "land_count": land.size()})
	# 4. Box 52x44 on exactly those ticks, 52x58 around them.
	var bad_box: Array = []
	var low_ticks: Array[int] = []
	for t in hop_window:
		var b: Vector2 = row_at(t).get("box", Vector2.ZERO)
		if b == LOW:
			low_ticks.append(t)
		var want: Vector2 = LOW if t in land else STANDING
		if b != want:
			bad_box.append({"tick": t, "box": str(b), "pose": pose_at(t)})
	check("baseline-4-low-box-exactly-on-land", bad_box.is_empty() and low_ticks == want_land, {"low_box_ticks": low_ticks, "mismatches": bad_box})
	# Scenario validity (harness): the scoots stay on the starting plate and go both ways.
	var off_floor: Array[int] = []
	for t in range(right_on, end + 1):
		if not row_at(t).get("floor", false):
			off_floor.append(t)
	# Scoot segments: maximal runs of consecutive ticks with a SCOOT pose.
	var segments: Array = []
	var phase_bad: Array = []
	for t in range(right_on, end + 1):
		var r := row_at(t)
		var pose := pose_at(t)
		if pose.begins_with("SCOOT"):
			var want_pose := "SCOOT-A" if posmod(int(r.ptick), 14) < 7 else "SCOOT-B"
			if pose != want_pose:
				phase_bad.append({"tick": t, "ptick": r.ptick, "pose": pose, "expected": want_pose})
			if segments.is_empty() or segments.back().last != t - 1:
				segments.append({"first": t, "last": t, "facing": r.facing})
			else:
				segments.back().last = t
	check("baseline-harness-scoot-on-plate-both-ways", off_floor.is_empty() and segments.size() == 2 and segments[0].facing > 0 and segments[1].facing < 0, {"off_floor_ticks": off_floor, "segments": segments})
	# 5a. SCOOT-A exactly when (player.tick % 14) < 7.
	check("baseline-5a-scoot-a-when-tick-mod-14-below-7", phase_bad.is_empty() and segments.size() == 2, {"mismatches": phase_bad})
	# 5b. Alternate every 7 player ticks: every run of one cell that is not cut by a segment edge lasts 7 ticks,
	# and the player tick advances by one each physics tick inside a segment.
	var interior: Array = []
	var edge_runs: Array = []
	var ptick_gaps: Array = []
	for s in segments:
		var runs: Array = []
		for t in range(s.first, s.last + 1):
			if t > s.first and int(row_at(t).ptick) != int(row_at(t - 1).ptick) + 1:
				ptick_gaps.append(t)
			if runs.is_empty() or runs.back().pose != pose_at(t):
				runs.append({"pose": pose_at(t), "first": t, "len": 1})
			else:
				runs.back().len += 1
		for i in range(runs.size()):
			if i == 0 or i == runs.size() - 1:
				edge_runs.append(runs[i])
			else:
				interior.append(runs[i])
	var interior_ok := interior.size() >= 2
	for r in interior:
		interior_ok = interior_ok and r.len == 7
	check("baseline-5b-scoot-alternates-every-7-ticks", interior_ok and ptick_gaps.is_empty(), {"interior_runs": interior, "edge_runs": edge_runs, "ptick_gaps": ptick_gaps})
	# 6. flip_h exactly when facing < 0, on every tick of the run.
	var flip_bad: Array = []
	var ticks := by_tick.keys()
	ticks.sort()
	for t in ticks:
		var r: Dictionary = by_tick[t]
		if bool(r.flip_h) != (float(r.facing) < 0.0):
			flip_bad.append({"tick": t, "facing": r.facing, "flip_h": r.flip_h})
	check("baseline-6-flip-h-iff-facing-negative", flip_bad.is_empty() and ticks.size() > 0, {"ticks_checked": ticks.size(), "mismatches": flip_bad})
	return t0 - h

# ---------------------------------------------------------------- interrupt replays

func replay(k: int, d: int) -> Dictionary:
	await start_run("interrupt_k%+d" % k)
	var h := await stationary_hop()
	var t0e := h + d
	var press := t0e + k
	key_for(press, JUMP_KEY, true)       # fresh: the stationary press was released at h + 2
	key_for(press + 2, JUMP_KEY, false)
	await until(t0e + 21)
	var t0 := first_tick_where(h + 1, t0e + 20, "just_landed")
	var hop := first_tick_where(t0e - 2, t0e + 20, "just_hopped")   # the case hop, not the stationary one
	var timeline: Array[String] = []
	for rel in range(-2, 13):
		var r := row_at(t0e + rel)
		timeline.append("%d:%s/%d/%s" % [rel, pose_at(t0e + rel), int(r.get("land_ticks", -1)), "hop" if r.get("just_hopped", false) else ("landed" if r.get("just_landed", false) else "-")])
	print("TIMELINE interrupt_k%+d (rel:pose/land_ticks/event) %s" % [k, " ".join(timeline)])
	check("interrupt-k%+d-harness-same-touchdown-and-press-read" % k, t0 == t0e and press in reads and h in reads,
		{"stationary_press_tick": h, "expected_touchdown": t0e, "observed_touchdown": t0, "case_press_tick": press, "jump_read_ticks": reads.duplicate()})
	return {"t0": t0e, "t0_observed": t0, "press_rel": press - t0e, "read_rel": (press - t0e) if press in reads else null,
		"hop_rel": (hop - t0e) if hop >= 0 else null, "pose0": pose_at(t0e), "pose8": pose_at(t0e + 8),
		"poses": timeline}

func interrupts(d: int) -> void:
	var results := {}
	for k in [-1, 0, 1, 2, 3, 4, 5, 7, 8, 9]:
		results[k] = await replay(k, d)
	for c in CASES:
		var r: Dictionary = results[c.k]
		var hop_rel = r.hop_rel
		var antic_at_hop := hop_rel != null and pose_at_rel(r, int(c.hop)) == "ANTIC"
		var ok: bool = r.read_rel == c.k and hop_rel == c.hop and antic_at_hop
		if c.get("land0", false):
			ok = ok and r.pose0 == "LAND" and int(c.k) < int(hop_rel if hop_rel != null else -99)
		if c.get("idle8", false):
			ok = ok and r.pose8 == "IDLE"
		var observed := {"predicted": c.predicted, "press_read_rel": r.read_rel, "hop_rel": hop_rel,
			"pose_at_0": r.pose0, "pose_at_hop_prediction": pose_at_rel(r, int(c.hop)), "pose_at_8": r.pose8,
			"timeline": r.poses}
		print("CASE boundary=%d %s k=%+d predicted=\"%s\" observed: read=%s hop=%s pose0=%s pose%d=%s pose8=%s" % [
			c.boundary, c.column, c.k, c.predicted, str(r.read_rel), str(hop_rel), r.pose0, c.hop, pose_at_rel(r, int(c.hop)), r.pose8])
		check("interrupt-boundary-%d-%s-k%+d" % [c.boundary, c.column, c.k], ok, observed)

func pose_at_rel(r: Dictionary, rel: int) -> String:
	# The timeline entries are "rel:pose/land_ticks/event" for rel -2..12.
	for e in r.poses:
		if e.begins_with("%d:" % rel):
			return e.split(":")[1].split("/")[0]
	return "?"
