extends SceneTree
## A7 Step 5 (plan Step 4): per-tick state of the wired visual layer in the real game (session.gd), with
## real key events only (Input.parse_input_event + flush, sent at the end of the tick before the one that
## reads them; the input harness is copied unchanged from test_a7_pins.gd). Never test_control, never a
## direct call to a transition. Scripted input; this is not human playtesting. Headless: nothing is drawn,
## so no check here says anything about pixels.
##
## After every game node has run in a tick (hook at priority 1000), each row records the pose, the clip
## (current_animation), the expected and actual clip time, the displayed SCOOT cell, the rig values against
## land.value_track_interpolate at the expected time, the three visibility flags and the facing mirror.
##
## Expected values come from the brief, not from player.gd: LAND -> land at (8 - land_ticks) / 60,
## SCOOT-A/B -> scoot at (tick % 14) / 60, every other pose -> no clip and the original sprite.
## "Enabled as seen by the player": the session can disable the player at priority 10, after the visual
## layer has already run in that tick (a splat). So each tick is judged against the `enabled` value the
## player saw when it ran: the previous tick's value after the harness sent its events.
const Game = preload("res://game/session.gd")
const SLOT := 600        # each run starts on a physics frame that is a multiple of this (same tick at every rate)
const SETTLE := 10       # grounded, PLAYING and IDLE this many ticks before the first scheduled input
const JUMP_KEY := KEY_SPACE
const RIGHT_KEY := KEY_D
const LEFT_KEY := KEY_A
const PAUSE_KEY := KEY_ESCAPE
const TIME_TOL := 1e-6   # seconds
const RIG_TOL := 1e-4
const FPS := 60.0
const CYCLE := 14        # brief: two cells over 14 timeline frames
const LAND_N := 8        # brief: length 8/60, the existing eight-tick window
const CLIP_FOR := {"LAND": "land", "SCOOT-A": "scoot", "SCOOT-B": "scoot"}
const VIS_FOR := {"": "sprite", "scoot": "scoot", "land": "rig"}
const RIG_TRACKS := ["FacingPivot/LandRig/LowerPivot:scale", "FacingPivot/LandRig/UpperPivot:position", "FacingPivot/LandRig/UpperPivot:scale"]
## Hop tick relative to touchdown for each interrupt replay (CHANGE-BRIEF.md "Jump interrupt predictions";
## confirmed by test_a7_pins.gd). Used only to label the replay; the checks use the observed hop.
const HOP_FOR_K := {-1: 1, 0: 1, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 7: 7, 8: 8, 9: 9}

var game: Node2D
var hook: Node
var run_name := ""
var run_first_logged := false
var by_tick: Dictionary = {}     # physics frame -> row of the current run
var reads: Array[int] = []       # physics frames on which the jump action was just pressed
var checks := 0
var failures := 0
var swap_n := 0                  # all runs: enabled SCOOT ticks at phase 7 (the swap tick)
var swap_bad: Array = []

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
	# Escape reaches session._unhandled_input during this flush, so a pause takes effect for frame now() + 1.
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
	# What the player will see when it runs on the next frame.
	if by_tick.has(now()) and is_instance_valid(game) and game.player != null:
		by_tick[now()]["enabled_after"] = game.player.enabled

func clip_for(pose: String) -> String:
	return CLIP_FOR.get(pose, "")

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
	var v: Node = p.visuals
	var ap: AnimationPlayer = p.anim
	var t := now()
	var f := Engine.get_process_frames()
	if not run_first_logged:
		run_first_logged = true
		print("RUN %s first_tick=%d first_frame=%d frames_drawn=%d" % [run_name, t, f, Engine.get_frames_drawn()])
	var prev: Dictionary = by_tick.get(t - 1, {})
	var seen: bool = bool(prev.get("enabled_after", p.enabled))
	var exp_clip := clip_for(p.pose)
	var cur := String(ap.current_animation)
	var asg := String(ap.assigned_animation)
	var pos := NAN
	if cur != "" or (exp_clip != "" and not seen and asg == exp_clip):
		pos = ap.current_animation_position
	var exp_t := NAN
	if exp_clip == "land":
		exp_t = float(LAND_N - int(p.land_ticks)) / FPS
	elif exp_clip == "scoot":
		exp_t = float(posmod(int(p.tick), CYCLE)) / FPS
	var cell: int = v.get_node("FacingPivot/Scoot/ScootSprite").frame
	var lower: Node2D = v.get_node("FacingPivot/LandRig/LowerPivot")
	var upper: Node2D = v.get_node("FacingPivot/LandRig/UpperPivot")
	var rig_diff := NAN
	if exp_clip == "land":
		var a: Animation = ap.get_animation(&"land")
		var actual: Array[Vector2] = [lower.scale, upper.position, upper.scale]
		rig_diff = 0.0
		for i in range(3):
			var tr := a.find_track(NodePath(RIG_TRACKS[i]), Animation.TYPE_VALUE)
			if tr < 0:
				rig_diff = INF
				continue
			var want: Vector2 = a.value_track_interpolate(tr, exp_t)
			var d: Vector2 = (actual[i] - want).abs()
			rig_diff = maxf(rig_diff, maxf(d.x, d.y))
	var fp: Node2D = v.get_node("FacingPivot")
	var fp_ok: bool = fp.transform == Transform2D(Vector2(p.facing, 0), Vector2(0, 1), Vector2.ZERO)
	var vis := vis_of(p)
	var row := {"tick": t, "frame": f, "ptick": int(p.tick), "pose": p.pose, "land_ticks": int(p.land_ticks),
		"just_landed": p.just_landed, "just_hopped": p.just_hopped, "seen": seen, "enabled": p.enabled,
		"state": game.state, "facing": p.facing, "floor": p.is_on_floor(), "vx": p.velocity.x, "x": p.position.x,
		"exp_clip": exp_clip, "cur": cur, "asg": asg, "playing": ap.is_playing(), "exp_t": exp_t, "pos": pos,
		"cell": cell, "vis": vis, "fp_ok": fp_ok, "rig_diff": rig_diff}
	by_tick[t] = row
	print("STATE %s tick=%d frame=%d ptick=%d state=%s seen_enabled=%s pose=%s land_ticks=%d vx=%d x=%.2f floor=%s exp_clip=%s cur=\"%s\" asg=\"%s\" playing=%s exp_t=%s pos=%s diff_ticks=%.6f cell=%d vis=%s facing=%s fp_ok=%s lower_scale=%s upper_pos=%s upper_scale=%s rig_diff=%.9f" % [
		run_name, t, f, row.ptick, Game.State.keys()[game.state], seen, p.pose, row.land_ticks, roundi(p.velocity.x), p.position.x,
		p.is_on_floor(), exp_clip if exp_clip != "" else "-", cur, asg, ap.is_playing(), f12(exp_t), f12(pos), (pos - exp_t) * FPS,
		cell, vis, str(p.facing), fp_ok, str(lower.scale), str(upper.position), str(upper.scale), rig_diff])
	if Input.is_action_just_pressed("jump"):
		reads.append(t)
		print("READ %s tick=%d ptick=%d jump_just_pressed=true" % [run_name, t, row.ptick])
	if p.just_hopped:
		print("HOP %s tick=%d ptick=%d" % [run_name, t, row.ptick])

func row_at(t: int) -> Dictionary:
	return by_tick.get(t, {})

func short(r: Dictionary) -> Dictionary:
	return {"tick": r.get("tick"), "ptick": r.get("ptick"), "pose": r.get("pose"), "land_ticks": r.get("land_ticks"),
		"seen_enabled": r.get("seen"), "exp_clip": r.get("exp_clip"), "cur": r.get("cur"), "asg": r.get("asg"),
		"exp_t": f12(float(r.get("exp_t", NAN))), "pos": f12(float(r.get("pos", NAN))), "cell": r.get("cell"),
		"vis": r.get("vis"), "fp_ok": r.get("fp_ok"), "rig_diff": "%.9f" % float(r.get("rig_diff", NAN))}

func near(a, b: float) -> bool:
	return absf(float(a) - b) <= TIME_TOL

# ---------------------------------------------------------------- runs

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
	## Returns at the start of frame now(); the first input is then read on frame now() + 1.
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

func wait_for_landing(h: int) -> int:
	var t0 := -1
	while t0 < 0 and now() < h + 200:
		await physics_frame
		if row_at(now() - 1).get("just_landed", false):
			t0 = now() - 1
	return t0

func finish_run(name: String) -> void:
	## The every-tick checks for one run. A kind of tick that does not occur in the run gets a NOTE, not a check.
	var ticks := by_tick.keys()
	ticks.sort()
	var cats := ["clip", "time", "cell", "rig", "visible", "facing", "frozen"]
	var n := {}
	var bad := {}
	for c in cats:
		n[c] = 0
		bad[c] = []
	var prev: Dictionary = {}
	for t in ticks:
		var r: Dictionary = by_tick[t]
		var seen: bool = r.seen
		var ec: String = r.exp_clip
		# Clip name: the selected clip plays while enabled; paused (current "" and assigned kept) while disabled.
		n["clip"] += 1
		var ok_clip: bool
		if ec == "":
			ok_clip = r.cur == ""
		elif seen:
			ok_clip = r.cur == ec
		else:
			ok_clip = r.cur == "" and r.asg == ec and not r.playing
		if not ok_clip:
			bad["clip"].append(short(r))
		if ec != "":
			n["time"] += 1
			if not near(r.pos, float(r.exp_t)):
				bad["time"].append(short(r))
		if ec == "scoot":
			n["cell"] += 1
			if r.cell != (0 if r.pose == "SCOOT-A" else 1):
				bad["cell"].append(short(r))
			if seen and posmod(int(r.ptick), CYCLE) == 7:
				swap_n += 1
				if r.cell != 1:
					swap_bad.append({"run": name, "tick": t})
		if ec == "land":
			n["rig"] += 1
			if not (float(r.rig_diff) <= RIG_TOL):
				bad["rig"].append(short(r))
		n["visible"] += 1
		if r.vis != VIS_FOR[ec]:
			bad["visible"].append(short(r))
		n["facing"] += 1
		if not r.fp_ok:
			bad["facing"].append(short(r))
		if ec != "" and not seen and not prev.is_empty():
			# Paused: the pose, the clip and the clip time stay exactly as on the tick before.
			n["frozen"] += 1
			if not (prev.pose == r.pose and prev.exp_clip == ec and absf(float(r.pos) - float(prev.pos)) <= 1e-12):
				bad["frozen"].append({"tick": t, "prev": short(prev), "now": short(r)})
		prev = r
	for c in cats:
		if n[c] == 0:
			print("NOTE %s-%s: no tick of this kind in this run; no check" % [name, c])
			continue
		check("%s-%s-every-tick" % [name, c], bad[c].is_empty(), {"ticks_checked": n[c], "mismatches": bad[c].size(), "first": bad[c].slice(0, 5)})
	run_name = ""

func run() -> void:
	hook = TickHook.new()
	hook.name = "StateTickHook"
	hook.process_physics_priority = 1000
	hook.on_tick = _log_tick
	root.add_child(hook)
	print("A7 VISUAL STATE: engine=%s physics_ticks_per_second=%d" % [Engine.get_version_info().string, Engine.physics_ticks_per_second])
	var d := await case_a()
	await case_b()
	for k in [-1, 0, 1, 2, 3, 4, 5, 7, 8, 9]:
		await case_c(k, d)
	await case_d(d)
	await case_e_land(d)
	await case_e_scoot()
	await case_f_walk_off()
	await case_f_splat()
	print("CASE f-override-resume: NOT REACHABLE THROUGH REAL INPUT. Every override (SPLAT, REFORM, WON) ends through reset_at(), which sets land_ticks = 0 (player.gd line 78; session.gd lines 239, 354); not counted as a pass (CHANGE-BRIEF.md Revision 1). The same synced resume is checked through pause (case e).")
	check("all-runs-scoot-swap-tick-shows-cell-1", swap_n > 0 and swap_bad.is_empty(), {"swap_ticks": swap_n, "mismatches": swap_bad.slice(0, 5)})
	print("A7 VISUAL STATE: %d checks / %d failures" % [checks, failures])
	if is_instance_valid(game):
		game.queue_free()
	hook.queue_free()
	for i in range(30):
		await process_frame
	quit(1 if failures else 0)

# ---------------------------------------------------------------- (a) stationary hop

func case_a() -> int:
	await start_run("a_hop")
	var h := await stationary_hop()
	var t0 := await wait_for_landing(h)
	await until(t0 + 21)
	var ok := h > 0 and t0 > 0
	var seq: Array[String] = []
	for i in range(LAND_N):
		var r := row_at(t0 + i)
		var good: bool = r.get("pose") == "LAND" and r.get("cur") == "land" and near(r.get("pos", NAN), i / FPS) and r.get("vis") == "rig"
		ok = ok and good
		seq.append("%d:%s/%s/%s/%s" % [i, r.get("pose"), r.get("cur"), f12(float(r.get("pos", NAN))), r.get("vis")])
	check("a-touchdown-plays-land-from-0-for-8-ticks", ok, {"press_tick": h, "touchdown_tick": t0, "rel:pose/clip/time/visual": seq})
	var r8 := row_at(t0 + LAND_N)
	check("a-tick-8-hands-off-to-idle-and-original-sprite", r8.get("pose") == "IDLE" and r8.get("cur") == "" and r8.get("vis") == "sprite",
		{"tick": t0 + LAND_N, "pose": r8.get("pose"), "cur": r8.get("cur"), "vis": r8.get("vis")})
	print("CASE a touchdown=%d press_to_touchdown=%d land=%s tick8=%s/%s/%s" % [t0, t0 - h, " ".join(seq), r8.get("pose"), r8.get("cur"), r8.get("vis")])
	finish_run("a")
	return t0 - h

# ---------------------------------------------------------------- (b) SCOOT on the starting plate

func case_b() -> void:
	await start_run("b_scoot")
	var ready := await wait_ready()
	# [key, press read tick, release read tick] relative to ready; gaps of 13, 11, 17 and 9 ticks put the
	# re-entries at different phases; the last two segments are a reversal without a stop.
	var plan := [[RIGHT_KEY, 1, 17], [LEFT_KEY, 30, 64], [RIGHT_KEY, 75, 109], [LEFT_KEY, 126, 160], [RIGHT_KEY, 169, 185], [LEFT_KEY, 185, 201]]
	for s in plan:
		key_for(ready + s[1], s[0], true)
		key_for(ready + s[2], s[0], false)
	var end := ready + 230
	await until(end + 1)
	var scoot_len: float = game.player.anim.get_animation(&"scoot").length
	var off_floor: Array[int] = []
	var xs: Array[float] = []
	var segments: Array = []
	var restart_bad: Array = []
	var wraps := 0
	var ab_changes := 0
	for t in range(ready + 1, end + 1):
		var r := row_at(t)
		if not r.floor:
			off_floor.append(t)
		xs.append(float(r.x))
		if str(r.pose).begins_with("SCOOT"):
			if segments.is_empty() or segments.back().last != t - 1:
				segments.append({"first": t, "last": t, "facing": r.facing, "entry_phase": posmod(int(r.ptick), CYCLE)})
			else:
				segments.back().last = t
				var p := row_at(t - 1)
				var want := float(p.pos) + 1.0 / FPS
				if want >= scoot_len - 1e-9:
					want -= scoot_len
				if not near(r.pos, want):
					restart_bad.append({"tick": t, "prev_pos": f12(float(p.pos)), "pos": f12(float(r.pos)), "want": f12(want)})
				if posmod(int(r.ptick), CYCLE) == 0:
					wraps += 1
				if p.pose != r.pose:
					ab_changes += 1
	var facings := {}
	var phases := {}
	for s in segments:
		facings[s.facing] = true
		phases[s.entry_phase] = true
	check("b-harness-scoot-stays-on-plate", off_floor.is_empty() and segments.size() >= 5, {"off_floor_ticks": off_floor, "x_min": xs.min(), "x_max": xs.max(), "segments": segments.size()})
	check("b-scoot-faces-both-ways", facings.has(1.0) and facings.has(-1.0), {"facings": facings.keys()})
	check("b-at-least-5-wraps", wraps >= 5, {"wraps": wraps})
	check("b-reentries-at-different-phases", phases.size() >= 3, {"entry_phases": segments.map(func(s): return s.entry_phase)})
	check("b-a-b-changes-never-restart-the-clip", restart_bad.is_empty() and ab_changes >= 10, {"a_b_changes": ab_changes, "discontinuities": restart_bad.slice(0, 5), "scoot_length": f12(scoot_len)})
	print("CASE b segments=%s wraps=%d a_b_changes=%d x=[%.1f, %.1f]" % [JSON.stringify(segments), wraps, ab_changes, xs.min(), xs.max()])
	finish_run("b")

# ---------------------------------------------------------------- (c) interrupt replays

func case_c(k: int, d: int) -> void:
	var name := "c_k%+d" % k
	await start_run(name)
	var h := await stationary_hop()
	var t0e := h + d
	var press := t0e + k
	key_for(press, JUMP_KEY, true)       # fresh: the stationary press was released at h + 2
	key_for(press + 2, JUMP_KEY, false)
	await until(t0e + 21)
	var t0 := first_tick_where(h + 1, t0e + 20, "just_landed")
	var hop := first_tick_where(t0e - 2, t0e + 20, "just_hopped")
	check("%s-harness-same-touchdown-and-press-read" % name, t0 == t0e and press in reads and h in reads,
		{"expected_touchdown": t0e, "observed_touchdown": t0, "case_press_tick": press, "jump_read_ticks": reads.duplicate()})
	var rh := row_at(hop)
	var rb := row_at(hop - 1)
	var ok: bool = hop >= 0 and rh.get("pose") == "ANTIC" and rh.get("cur") == "" and rh.get("vis") == "sprite"
	if rb.get("pose") == "LAND":
		ok = ok and rb.get("cur") == "land" and rb.get("vis") == "rig"
	check("%s-hop-stops-land-and-shows-original-sprite" % name, ok,
		{"hop_rel": (hop - t0e) if hop >= 0 else null, "predicted_hop_rel": HOP_FOR_K[k], "before": short(rb), "hop": short(rh)})
	if k <= 0:
		var r0 := row_at(t0e)
		check("%s-land-shown-at-0-before-buffered-hop" % name, r0.get("pose") == "LAND" and r0.get("cur") == "land" and near(r0.get("pos", NAN), 0.0) and hop == t0e + 1,
			{"at_0": short(r0), "hop_rel": (hop - t0e) if hop >= 0 else null})
	if k == 9:
		var r8 := row_at(t0e + 8)
		check("%s-idle-at-8-then-antic-at-9" % name, r8.get("pose") == "IDLE" and r8.get("cur") == "" and r8.get("vis") == "sprite" and hop == t0e + 9,
			{"at_8": short(r8), "hop_rel": (hop - t0e) if hop >= 0 else null})
	var timeline: Array[String] = []
	for rel in range(-1, 11):
		var r := row_at(t0e + rel)
		timeline.append("%d:%s/%s/%s" % [rel, r.get("pose"), r.get("cur"), f12(float(r.get("pos", NAN)))])
	print("CASE %s hop_rel=%s (rel:pose/clip/time) %s" % [name, str(hop - t0e), " ".join(timeline)])
	finish_run(name)

# ---------------------------------------------------------------- (d) LAND -> SCOOT

func case_d(d: int) -> void:
	await start_run("d_land_to_scoot")
	var h := await stationary_hop()
	var t0e := h + d
	key_for(t0e - 1, RIGHT_KEY, true)    # moving before touchdown, held through LAND
	key_for(t0e + 14, RIGHT_KEY, false)
	await until(t0e + 30)
	var t0 := first_tick_where(h + 1, t0e + 5, "just_landed")
	var land_ok := t0 == t0e
	var moving := 0
	for i in range(LAND_N):
		var r := row_at(t0e + i)
		land_ok = land_ok and r.get("pose") == "LAND" and r.get("cur") == "land"
		if absf(float(r.get("vx", 0.0))) > 8.0:
			moving += 1
	check("d-movement-alone-does-not-end-land", land_ok and moving == LAND_N, {"touchdown": t0, "expected": t0e, "land_ticks_moving": moving})
	var r8 := row_at(t0e + LAND_N)
	var want_cell := 0 if r8.get("pose") == "SCOOT-A" else 1
	check("d-scoot-starts-in-phase-at-tick-8", str(r8.get("pose")).begins_with("SCOOT") and r8.get("cur") == "scoot"
		and near(r8.get("pos", NAN), posmod(int(r8.get("ptick", 0)), CYCLE) / FPS) and r8.get("cell") == want_cell and r8.get("vis") == "scoot",
		{"at_8": short(r8)})
	print("CASE d touchdown=%d tick8=%s" % [t0, JSON.stringify(short(r8))])
	finish_run("d")

# ---------------------------------------------------------------- (e) pause during LAND and during SCOOT

func case_e_land(d: int) -> void:
	await start_run("e_pause_land")
	var h := await stationary_hop()
	var t0e := h + d
	key_for(t0e + 3, PAUSE_KEY, true)    # handled at the end of t0e + 2: paused from t0e + 3 (land_ticks 6)
	key_for(t0e + 5, PAUSE_KEY, false)
	key_for(t0e + 20, PAUSE_KEY, true)   # unpaused from t0e + 20
	key_for(t0e + 22, PAUSE_KEY, false)
	await until(t0e + 40)
	var paused: Array[int] = []
	for t in range(t0e, t0e + 30):
		if not row_at(t).get("seen", true):
			paused.append(t)
	var want_paused: Array[int] = []
	for t in range(t0e + 3, t0e + 20):
		want_paused.append(t)
	check("e-land-harness-paused-17-ticks-mid-land", paused == want_paused and row_at(t0e).get("just_landed", false) and row_at(t0e + 3).get("state") == Game.State.PAUSED,
		{"paused_ticks": paused, "expected": want_paused})
	var frozen_ok := not paused.is_empty()
	for t in paused:
		var r := row_at(t)
		frozen_ok = frozen_ok and r.pose == "LAND" and r.land_ticks == 6 and r.cur == "" and r.asg == "land" and near(r.pos, 2.0 / FPS) and r.vis == "rig"
	check("e-land-pose-and-clip-time-frozen-while-paused", frozen_ok, {"first": short(row_at(t0e + 3)), "last": short(row_at(t0e + 19))})
	var rr := row_at(t0e + 20)
	check("e-land-resumes-at-synced-time", rr.get("seen") == true and rr.get("pose") == "LAND" and rr.get("land_ticks") == 5 and rr.get("cur") == "land" and near(rr.get("pos", NAN), 3.0 / FPS),
		{"resume": short(rr)})
	print("CASE e_land paused=%d..%d frozen_at=%s resume=%s" % [t0e + 3, t0e + 19, f12(float(row_at(t0e + 3).get("pos", NAN))), JSON.stringify(short(rr))])
	finish_run("e_land")

func case_e_scoot() -> void:
	await start_run("e_pause_scoot")
	var ready := await wait_ready()
	key_for(ready + 1, LEFT_KEY, true)   # move left first, so the paused scoot to the right stays on the plate
	key_for(ready + 17, LEFT_KEY, false)
	var right_on := ready + 30
	key_for(right_on, RIGHT_KEY, true)
	# The player tick advances by one every enabled tick: choose the last tick before the pause, n, so that
	# it shows phase 6 (SCOOT-A); the resume tick is then phase 7, the swap tick, entered through seek.
	var base: int = int(row_at(ready - 1).ptick)
	var n := right_on + 8
	while posmod(base + (n - (ready - 1)), CYCLE) != 6:
		n += 1
	key_for(n + 1, PAUSE_KEY, true)
	key_for(n + 3, PAUSE_KEY, false)
	key_for(n + 16, PAUSE_KEY, true)
	key_for(n + 18, PAUSE_KEY, false)
	key_for(n + 20, RIGHT_KEY, false)
	await until(n + 45)
	var off_floor: Array[int] = []
	for t in range(ready + 1, n + 45):
		if not row_at(t).get("floor", false):
			off_floor.append(t)
	var paused: Array[int] = []
	for t in range(right_on, n + 40):
		if not row_at(t).get("seen", true):
			paused.append(t)
	var want_paused: Array[int] = []
	for t in range(n + 1, n + 16):
		want_paused.append(t)
	var rn := row_at(n)
	check("e-scoot-harness-paused-15-ticks-at-phase-6", paused == want_paused and off_floor.is_empty() and rn.get("pose") == "SCOOT-A" and posmod(int(rn.get("ptick", -1)), CYCLE) == 6 and rn.get("cur") == "scoot",
		{"paused_ticks": paused, "expected": want_paused, "off_floor_ticks": off_floor, "before_pause": short(rn)})
	var frozen_ok := not paused.is_empty()
	for t in paused:
		var r := row_at(t)
		frozen_ok = frozen_ok and r.pose == "SCOOT-A" and r.cur == "" and r.asg == "scoot" and near(r.pos, 6.0 / FPS) and r.cell == 0 and r.vis == "scoot"
	check("e-scoot-pose-cell-and-clip-time-frozen-while-paused", frozen_ok, {"first": short(row_at(n + 1)), "last": short(row_at(n + 15))})
	var rr := row_at(n + 16)
	check("e-scoot-resumes-at-synced-time-on-the-swap-tick", rr.get("seen") == true and rr.get("pose") == "SCOOT-B" and posmod(int(rr.get("ptick", -1)), CYCLE) == 7
		and rr.get("cur") == "scoot" and near(rr.get("pos", NAN), 7.0 / FPS) and rr.get("cell") == 1,
		{"resume": short(rr)})
	print("CASE e_scoot paused=%d..%d frozen_at=%s resume=%s" % [n + 1, n + 15, f12(float(row_at(n + 1).get("pos", NAN))), JSON.stringify(short(rr))])
	finish_run("e_scoot")

# ---------------------------------------------------------------- (f) walk-off and splat

func case_f_walk_off() -> void:
	await start_run("f_walk_off")
	var ready := await wait_ready()
	key_for(ready + 1, LEFT_KEY, true)
	var off := -1
	var landed := -1
	while now() < ready + 200:
		await physics_frame
		var t := now() - 1
		var r := row_at(t)
		if off < 0 and t > ready + 1 and not r.get("floor", true):
			off = t
			key_for(now() + 1, LEFT_KEY, false)   # let go once airborne, so the jelly lands well clear of the wall
		elif off >= 0 and landed < 0 and r.get("just_landed", false):
			landed = t
		elif landed >= 0 and t >= landed + 20:
			break
	if off < 0 or landed < 0:
		print("CASE f_walk_off NOT REACHED: off=%d landed=%d" % [off, landed])
		finish_run("f_walk_off")
		return
	var rb := row_at(off - 1)
	var ro := row_at(off)
	check("f-walk-off-stops-scoot", str(rb.get("pose")).begins_with("SCOOT") and rb.get("cur") == "scoot" and ro.get("pose") == "FALL" and ro.get("cur") == "" and ro.get("vis") == "sprite",
		{"before": short(rb), "off": short(ro), "x_off": ro.get("x")})
	var rl := row_at(landed)
	var r8 := row_at(landed + LAND_N)
	check("f-walk-off-landing-plays-land-from-0-then-idle", rl.get("pose") == "LAND" and rl.get("cur") == "land" and near(rl.get("pos", NAN), 0.0) and rl.get("state") == Game.State.PLAYING
		and r8.get("pose") == "IDLE" and r8.get("cur") == "",
		{"landing": short(rl), "x_landing": rl.get("x"), "at_8": short(r8)})
	print("CASE f_walk_off off=%d x_off=%.2f landed=%d x_landed=%.2f" % [off, float(ro.get("x")), landed, float(rl.get("x"))])
	finish_run("f_walk_off")

func case_f_splat() -> void:
	## Hop to plate 1 and scoot back and forth on it until its fork strikes: a SPLAT override arriving
	## while a clip plays. Reported as NOT REACHED if the geometry or timing does not give that.
	await start_run("f_splat")
	var ready := await wait_ready()
	var c1: float = game.plates[1].center
	key_for(ready + 1, RIGHT_KEY, true)
	var stage := 0          # 0 walking to the hop point, 1 hop to plate 1, 2 scooting on plate 1
	var dir := 1
	var splat := -1
	var landed_x := NAN
	while now() < ready + 900:
		await physics_frame
		var t := now() - 1
		var r := row_at(t)
		if r.is_empty():
			continue
		if r.state == Game.State.SPLAT:
			splat = t
			break
		if stage == 0 and float(r.x) >= 330.0:
			key_for(now() + 1, JUMP_KEY, true)
			key_for(now() + 3, JUMP_KEY, false)
			stage = 1
		elif stage == 1 and r.just_landed:
			landed_x = float(r.x)
			stage = 2
		elif stage == 2:
			if dir > 0 and float(r.x) > c1 + 50.0:
				key_for(now() + 1, RIGHT_KEY, false)
				key_for(now() + 1, LEFT_KEY, true)
				dir = -1
			elif dir < 0 and float(r.x) < c1 - 50.0:
				key_for(now() + 1, LEFT_KEY, false)
				key_for(now() + 1, RIGHT_KEY, true)
				dir = 1
	key_for(now() + 1, RIGHT_KEY if dir > 0 else LEFT_KEY, false)
	if splat < 0:
		print("CASE f_splat NOT REACHED: no splat (stage=%d landed_x=%s plate1_center=%.1f)" % [stage, str(landed_x), c1])
		finish_run("f_splat")
		return
	await until(splat + 120)
	var rs := row_at(splat)
	var r1 := row_at(splat + 1)
	var clip := clip_for(str(rs.get("pose")))
	print("CASE f_splat splat_tick=%d cause=%s landed_x=%.2f pose_on_splat_tick=%s next=%s" % [splat, game.splat_cause, landed_x, rs.get("pose"), r1.get("pose")])
	if clip == "":
		print("CASE f_splat NOT REACHED: the splat came during %s, not during a clip" % rs.get("pose"))
	else:
		check("f-splat-override-stops-%s" % clip, rs.get("cur") == clip and r1.get("pose") == "SPLAT" and r1.get("cur") == "" and r1.get("vis") == "sprite",
			{"splat_tick": short(rs), "next": short(r1), "cause": game.splat_cause})
	# Observation for the override-resume rule (not a check): LAND with ticks remaining after the override,
	# without a fresh touchdown.
	var resumed: Array[int] = []
	for t in range(splat + 1, splat + 120):
		var r := row_at(t)
		if r.get("pose") == "LAND" and int(r.get("land_ticks", 0)) > 0 and int(r.get("land_ticks", 0)) < LAND_N:
			if not row_at(t - 1).get("pose") == "LAND":
				resumed.append(t)
	var poses: Array[String] = []
	for t in range(splat, splat + 120):
		var p := str(row_at(t).get("pose"))
		if poses.is_empty() or poses.back() != p:
			poses.append(p)
	print("CASE f_splat after splat: poses=%s land_resumed_after_override_ticks=%s" % [poses, resumed])
	finish_run("f_splat")
