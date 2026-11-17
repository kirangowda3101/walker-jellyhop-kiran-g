extends SceneTree
## A7 Step 5, plan step 1: supplemental timing probe (CHANGE-BRIEF.md Revision 1, "Evidence split").
## Not counted. Never loads or instantiates the game. Each run instantiates its own copy of
## player_visuals.tscn under a stand-in parent (Node2D, physics priority 0, the way Player will sit above
## PlayerVisuals) and a late hook (Node, physics priority 1000, the pattern of TickHook in test_a7_pins.gd).
## The stand-in's _physics_process makes the scheduled AnimationPlayer calls (play / seek / pause), where
## player.gd will make them; nothing else in this probe calls playback. No clip is built, keyed or
## modified: the probe only reads clip values (value_track_interpolate) for the expected rig values.
## Headless: positions and node properties are read; nothing is drawn. Scripted calls, not a playtest.
## Engine behaviour that differs from the plan's assumptions is a finding (printed), not a failure.
## Exit 1 only if the probe itself cannot run (missing scene, node, clip or track; a tick not logged).
##
## Per tick: EARLY = current_animation_position read in the stand-in before any call that tick;
## MID = read right after the call (call ticks only); LATE = read in the late hook, after the stand-in
## and the AnimationPlayer have both updated that tick.

const SCENE_PATH := "res://features/player/player_visuals.tscn"
const LOWER_SCALE_PATH := "FacingPivot/LandRig/LowerPivot:scale"
const UPPER_POS_PATH := "FacingPivot/LandRig/UpperPivot:position"
const UPPER_SCALE_PATH := "FacingPivot/LandRig/UpperPivot:scale"
const F := 1.0 / 60.0
const PRE := 3            # stand-in ticks before entry (n = 0 is the entry tick)
const PAUSE_LEN := 10     # paused ticks: n = p .. p + PAUSE_LEN - 1; resume on n = p + PAUSE_LEN
const SCOOT_TICKS := 32   # SCOOT ticks logged from entry (and again from a resume): more than two cycles
const POST := 2           # LAND ticks logged after the expected time reaches 8/60 (informational)
const TOL_T := 1e-6
const TOL_V := 1e-4

class StandIn extends Node2D:
	## Stands in for Player (priority 0, parent of PlayerVisuals).
	var s := 0
	var on_tick: Callable
	func _physics_process(_delta: float) -> void:
		on_tick.call(s)
		s += 1

class TickHook extends Node:
	## Priority 1000: runs after the stand-in and the AnimationPlayer in every physics tick.
	var on_tick: Callable
	func _physics_process(_delta: float) -> void:
		on_tick.call()

var hook: TickHook
var harness_failed := false

# Current run
var spec: Dictionary = {}
var run_id := ""
var active := false
var done := false
var stand: StandIn
var visuals: Node2D
var ap: AnimationPlayer
var scoot_sprite: Sprite2D
var lower: Node2D
var upper: Node2D
var land_anim: Animation
var scoot_len := 0.0
var tr_lower := -1
var tr_upos := -1
var tr_uscale := -1
var cur_n := -999
var early_stamp := -1
var early := NAN
var early_playing := false
var mid := NAN
var mid_frame := -1
var mid_lower := Vector2(NAN, NAN)
var call_name := "-"
var rows: Array[Dictionary] = []

# Totals
var runs_done := 0
var ticks_logged := 0
var method_agg: Dictionary = {}
var a1_counts: Dictionary = {}
var entry_adv: Dictionary = {}
var resume_adv: Dictionary = {}
var pf6: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func harness_fail(msg: String) -> void:
	harness_failed = true
	print("PROBE HARNESS FAIL: " + msg)

func v2s(v: Vector2) -> String:
	return "(%.6f,%.6f)" % [v.x, v.y]

func pos_now() -> float:
	if ap == null or String(ap.assigned_animation) == "":
		return NAN
	return ap.current_animation_position

# ---------------------------------------------------------------- schedule and expectations

func pause_at() -> int:
	return int(spec["pause"])

func logical_c(n: int) -> int:
	## Active ticks since entry. Frozen at the last active tick while paused.
	var p := pause_at()
	if p < 0 or n < p:
		return n
	if n < p + PAUSE_LEN:
		return p - 1
	return n - PAUSE_LEN

func phase(n: int) -> int:
	return int(spec["k"]) + logical_c(n)

func tick_paused(n: int) -> bool:
	var p := pause_at()
	return p >= 0 and n >= p and n < p + PAUSE_LEN

func expected_time(n: int) -> float:
	if spec["clip"] == "scoot":
		return float(posmod(phase(n), 14)) / 60.0
	return float(mini(phase(n), 8)) / 60.0

func counted(n: int) -> bool:
	return spec["clip"] == "scoot" or phase(n) <= 8

func last_n() -> int:
	var extra := PAUSE_LEN if pause_at() >= 0 else 0
	if spec["clip"] == "scoot":
		var from := (pause_at() + PAUSE_LEN) if pause_at() >= 0 else 0
		return from + SCOOT_TICKS - 1
	return (8 - int(spec["k"])) + extra + POST

# ---------------------------------------------------------------- per-tick work

func enter(t: float) -> void:
	var clip := StringName(spec["clip"])
	match spec["method"]:
		"R1":
			ap.play(clip)
			ap.seek(t, true)
		"R2":
			ap.play(clip)
			ap.seek(t, false)
		"R3":
			ap.play(clip)

func _stand_tick(s: int) -> void:
	if not active:
		return
	cur_n = s - PRE
	early_stamp = Engine.get_physics_frames()
	early = pos_now()
	early_playing = ap.is_playing()
	call_name = "-"
	var p := pause_at()
	if cur_n == 0:
		enter(float(spec["k"]) * F)
		call_name = "entry"
	elif p >= 0 and cur_n == p:
		ap.pause()
		call_name = "pause"
	elif p >= 0 and cur_n == p + PAUSE_LEN:
		enter(expected_time(cur_n))
		call_name = "resume"
	if call_name != "-":
		mid = pos_now()
		mid_frame = scoot_sprite.frame
		mid_lower = lower.scale
	else:
		mid = NAN
		mid_frame = -1
		mid_lower = Vector2(NAN, NAN)

func _late_tick() -> void:
	if not active or done or cur_n < 0:
		return
	var tick := Engine.get_physics_frames()
	if early_stamp != tick:
		harness_fail("stand-in did not run on physics tick %d (run %s)" % [tick, run_id])
		done = true
		return
	var n := cur_n
	var late := pos_now()
	var exp_t := expected_time(n)
	var ph := phase(n)
	var frame := scoot_sprite.frame
	var lo := lower.scale
	var up := upper.position
	var us := upper.scale
	var ok_a := absf(late - exp_t) <= TOL_T   # false for NAN
	var ok_b := false
	var exp_str := ""
	var exp_cell := -1
	var rig_diff := 0.0
	if spec["clip"] == "scoot":
		exp_cell = 0 if posmod(ph, 14) < 7 else 1
		ok_b = frame == exp_cell
		exp_str = "exp_frame=%d exp_cell=%d" % [posmod(ph, 14), exp_cell]
	else:
		var el: Vector2 = land_anim.value_track_interpolate(tr_lower, exp_t)
		var eu: Vector2 = land_anim.value_track_interpolate(tr_upos, exp_t)
		var es: Vector2 = land_anim.value_track_interpolate(tr_uscale, exp_t)
		rig_diff = maxf(maxf(absf(lo.x - el.x), absf(lo.y - el.y)), maxf(maxf(absf(up.x - eu.x), absf(up.y - eu.y)), maxf(absf(us.x - es.x), absf(us.y - es.y))))
		ok_b = rig_diff <= TOL_V
		exp_str = "exp_frame=%d exp_lower=%s exp_upos=%s exp_uscale=%s rig_maxdiff=%.9f" % [mini(ph, 8), v2s(el), v2s(eu), v2s(es), rig_diff]
	var paused := tick_paused(n)
	var cnt := counted(n)
	var line := "TICK run=%s n=%d phys=%d c=%d call=%s paused=%s counted=%s early=%.12f mid=%.12f late=%.12f cur=\"%s\" assigned=\"%s\" playing=%s frame=%d lower_scale=%s upper_pos=%s upper_scale=%s exp_t=%.12f %s ok_a=%s ok_b=%s" % [
		run_id, n, tick, logical_c(n), call_name, paused, cnt, early, mid, late,
		String(ap.current_animation), String(ap.assigned_animation), ap.is_playing(), frame,
		v2s(lo), v2s(up), v2s(us), exp_t, exp_str, ok_a, ok_b]
	print(line)
	ticks_logged += 1
	rows.append({"n": n, "early": early, "early_playing": early_playing, "mid": mid, "mid_frame": mid_frame,
		"mid_lower": mid_lower, "late": late, "call": call_name, "paused": paused, "counted": cnt,
		"exp_t": exp_t, "phase": ph, "frame": frame, "exp_cell": exp_cell, "lower": lo, "upos": up, "uscale": us,
		"rig_diff": rig_diff, "ok_a": ok_a, "ok_b": ok_b, "cur": String(ap.current_animation),
		"assigned": String(ap.assigned_animation), "playing": ap.is_playing(), "line": line})
	if n >= last_n():
		done = true

# ---------------------------------------------------------------- runs

func make_specs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in ["R1", "R2"]:
		for k in range(14):
			out.append({"clip": "scoot", "method": m, "k": k, "pause": -1})
	out.append({"clip": "scoot", "method": "R3", "k": 0, "pause": -1})
	for m in ["R1", "R2"]:
		for k in [0, 3]:
			out.append({"clip": "land", "method": m, "k": k, "pause": -1})
	out.append({"clip": "land", "method": "R3", "k": 0, "pause": -1})
	# Pause: R1 and R2 only (R3 is play() alone at t = 0 and cannot seek to a synced resume time).
	for m in ["R1", "R2"]:
		out.append({"clip": "scoot", "method": m, "k": 0, "pause": 7})    # frozen at 6/60, resume at 7/60
		out.append({"clip": "scoot", "method": m, "k": 0, "pause": 20})   # after a wrap: frozen at 5/60, resume at 6/60
		out.append({"clip": "land", "method": m, "k": 0, "pause": 3})     # frozen at 2/60, resume at 3/60
	return out

func do_run(sp: Dictionary) -> bool:
	spec = sp
	run_id = "%s-%s-k%02d%s" % [sp["clip"], sp["method"], int(sp["k"]), ("-pause%d" % int(sp["pause"])) if int(sp["pause"]) >= 0 else ""]
	rows.clear()
	done = false
	active = false
	cur_n = -999
	early_stamp = -1
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		harness_fail("cannot load " + SCENE_PATH)
		return false
	visuals = scene.instantiate() as Node2D
	if visuals == null:
		harness_fail("scene root is not a Node2D")
		return false
	ap = visuals.get_node_or_null("AnimationPlayer") as AnimationPlayer
	scoot_sprite = visuals.get_node_or_null("FacingPivot/Scoot/ScootSprite") as Sprite2D
	lower = visuals.get_node_or_null("FacingPivot/LandRig/LowerPivot") as Node2D
	upper = visuals.get_node_or_null("FacingPivot/LandRig/UpperPivot") as Node2D
	if ap == null or scoot_sprite == null or lower == null or upper == null:
		harness_fail("missing node: ap=%s scoot_sprite=%s lower=%s upper=%s" % [ap != null, scoot_sprite != null, lower != null, upper != null])
		visuals.free()
		return false
	if not ap.has_animation(&"scoot") or not ap.has_animation(&"land"):
		harness_fail("missing clip: scoot=%s land=%s" % [ap.has_animation(&"scoot"), ap.has_animation(&"land")])
		visuals.free()
		return false
	land_anim = ap.get_animation(&"land")
	scoot_len = ap.get_animation(&"scoot").length
	tr_lower = land_anim.find_track(NodePath(LOWER_SCALE_PATH), Animation.TYPE_VALUE)
	tr_upos = land_anim.find_track(NodePath(UPPER_POS_PATH), Animation.TYPE_VALUE)
	tr_uscale = land_anim.find_track(NodePath(UPPER_SCALE_PATH), Animation.TYPE_VALUE)
	if tr_lower < 0 or tr_upos < 0 or tr_uscale < 0:
		harness_fail("missing land track: %d %d %d" % [tr_lower, tr_upos, tr_uscale])
		visuals.free()
		return false
	stand = StandIn.new()
	stand.name = "StandIn"
	stand.process_physics_priority = 0
	stand.on_tick = _stand_tick
	stand.add_child(visuals)
	if runs_done == 0:
		print("SETUP callback_mode_process=%d (PHYSICS=%d) physics_ticks_per_second=%d physics_delta=%.12f ap_priority=%d playervisuals_priority=%d standin_priority=%d hook_priority=%d scoot_length=%.12f land_length=%.12f" % [
			ap.callback_mode_process, AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS, Engine.physics_ticks_per_second,
			1.0 / Engine.physics_ticks_per_second, ap.process_physics_priority, visuals.process_physics_priority,
			stand.process_physics_priority, hook.process_physics_priority, scoot_len, land_anim.length])
	print("RUN %s clip=%s method=%s k=%d pause=%d start_phys=%d start_frame=%d" % [run_id, sp["clip"], sp["method"], int(sp["k"]), int(sp["pause"]), Engine.get_physics_frames(), Engine.get_process_frames()])
	active = true
	root.add_child(stand)
	var guard := 0
	while not done and guard < 400:
		await physics_frame
		guard += 1
	active = false
	var ok := done and not harness_failed
	if not done:
		harness_fail("run %s did not finish in 400 physics ticks" % run_id)
	elif ok:
		if rows.size() != last_n() + 1:
			harness_fail("run %s logged %d rows, expected %d" % [run_id, rows.size(), last_n() + 1])
			ok = false
		else:
			evaluate()
	stand.queue_free()
	await process_frame
	await process_frame
	stand = null
	ap = null
	runs_done += 1
	return ok

func circ(d: float) -> float:
	if spec["clip"] == "scoot":
		return fposmod(d + scoot_len / 2.0, scoot_len) - scoot_len / 2.0
	return d

func bump(dict: Dictionary, key: String) -> void:
	dict[key] = int(dict.get(key, 0)) + 1

func evaluate() -> void:
	var m: String = spec["method"]
	var clip: String = spec["clip"]
	var key := "%s/%s" % [m, clip]
	if not method_agg.has(m):
		method_agg[m] = {"runs": 0, "entries": 0, "resumes": 0, "ticks": 0, "fail_a": 0, "fail_b": 0, "first_fail": ""}
	var agg: Dictionary = method_agg[m]
	agg["runs"] += 1
	agg["entries"] += 1
	var p := pause_at()
	if p >= 0:
		agg["resumes"] += 1
	if not a1_counts.has(key):
		a1_counts[key] = {"after": 0, "before": 0, "other": 0}
	if not pf6.has(m):
		pf6[m] = {"swap_ticks": 0, "cell1": 0, "cell0": 0}
	var incr := PackedStringArray()
	var a1_samples := 0
	var run_fail_a := 0
	var run_fail_b := 0
	for i in range(rows.size()):
		var r: Dictionary = rows[i]
		var n: int = r["n"]
		if i > 0:
			incr.append("%.6f" % ((float(r["late"]) - float(rows[i - 1]["late"])) * 60.0))
		if r["counted"]:
			agg["ticks"] += 1
			if not r["ok_a"]:
				agg["fail_a"] += 1
				run_fail_a += 1
				print("POSMISS run=%s n=%d call=%s paused=%s exp_t=%.12f late=%.12f diff_frames=%.6f" % [run_id, n, r["call"], r["paused"], r["exp_t"], r["late"], (float(r["late"]) - float(r["exp_t"])) * 60.0])
			if not r["ok_b"]:
				agg["fail_b"] += 1
				run_fail_b += 1
				if clip == "scoot":
					print("CELLMISS run=%s n=%d call=%s paused=%s exp_t=%.12f late=%.12f exp_cell=%d frame=%d" % [run_id, n, r["call"], r["paused"], r["exp_t"], r["late"], r["exp_cell"], r["frame"]])
				else:
					print("RIGMISS run=%s n=%d call=%s paused=%s exp_t=%.12f late=%.12f rig_maxdiff=%.9f lower=%s upos=%s uscale=%s" % [run_id, n, r["call"], r["paused"], r["exp_t"], r["late"], r["rig_diff"], v2s(r["lower"]), v2s(r["upos"]), v2s(r["uscale"])])
			if (not r["ok_a"] or not r["ok_b"]) and agg["first_fail"] == "":
				agg["first_fail"] = r["line"]
		# Predicted failure 6: every tick whose expected time is exactly 7/60.
		if clip == "scoot" and posmod(int(r["phase"]), 14) == 7:
			pf6[m]["swap_ticks"] += 1
			if int(r["frame"]) == 1:
				pf6[m]["cell1"] += 1
			else:
				pf6[m]["cell0"] += 1
			print("SWAP run=%s n=%d call=%s paused=%s exp_t=7/60 late=%.12f late_minus_7/60=%.15f frame=%d cell1=%s" % [run_id, n, r["call"], r["paused"], r["late"], float(r["late"]) - 7.0 / 60.0, r["frame"], "yes" if int(r["frame"]) == 1 else "NO"])
		# A1: steady playback ticks (no call this tick, not paused, playing at EARLY, counted, n >= 1).
		if i > 0 and r["call"] == "-" and not r["paused"] and r["counted"] and r["early_playing"] and not rows[i - 1]["paused"]:
			var d_le := circ(float(r["late"]) - float(r["early"]))
			var d_ep := circ(float(r["early"]) - float(rows[i - 1]["late"]))
			var cls := "other"
			if absf(d_le - F) <= TOL_T and absf(d_ep) <= 1e-9:
				cls = "after"
			elif absf(d_le) <= 1e-9 and absf(d_ep - F) <= TOL_T:
				cls = "before"
			bump(a1_counts[key], cls)
			if a1_samples < 2 or cls == "other":
				a1_samples += 1
				print("A1 run=%s n=%d prev_late=%.12f early=%.12f late=%.12f early_minus_prev_late_frames=%.6f late_minus_early_frames=%.6f class=%s" % [run_id, n, rows[i - 1]["late"], r["early"], r["late"], d_ep * 60.0, d_le * 60.0, cls])
	# Entry tick.
	var e: Dictionary = rows[0]
	var t0 := float(spec["k"]) * F
	var adv := "%.6f" % ((float(e["late"]) - t0) * 60.0)
	if not entry_adv.has(m):
		entry_adv[m] = {}
	bump(entry_adv[m], adv)
	var vis := ("frame=%d exp_cell=%d mid_frame=%d" % [e["frame"], e["exp_cell"], e["mid_frame"]]) if clip == "scoot" else ("lower=%s mid_lower=%s rig_maxdiff=%.9f" % [v2s(e["lower"]), v2s(e["mid_lower"]), e["rig_diff"]])
	print("ENTRY run=%s method=%s t=%.12f early=%.12f mid=%.12f late=%.12f late_minus_t_frames=%s %s cur=\"%s\" playing=%s ok_a=%s ok_b=%s" % [run_id, m, t0, e["early"], e["mid"], e["late"], adv, vis, e["cur"], e["playing"], e["ok_a"], e["ok_b"]])
	print("INCR run=%s late_increments_frames_from_n1=[%s]" % [run_id, ",".join(incr)])
	# Pause and resume.
	if p >= 0:
		var ref := float(rows[p - 1]["late"])
		var froze := true
		var curs := {}
		var assigned := {}
		var playing := {}
		var paused_lates := PackedStringArray()
		for n in range(p, p + PAUSE_LEN):
			var r: Dictionary = rows[n]
			if absf(float(r["late"]) - ref) > 1e-12 or absf(float(r["early"]) - ref) > 1e-12:
				froze = false
			curs["\"%s\"" % r["cur"]] = true
			assigned["\"%s\"" % r["assigned"]] = true
			playing[str(r["playing"])] = true
			paused_lates.append("%.12f" % r["late"])
		var rr: Dictionary = rows[p + PAUSE_LEN]
		var rt := float(rr["exp_t"])
		var radv := "%.6f" % ((float(rr["late"]) - rt) * 60.0)
		if not resume_adv.has(m):
			resume_adv[m] = {}
		bump(resume_adv[m], radv)
		print("PAUSE run=%s pause_tick_n=%d last_active_late=%.12f froze=%s paused_lates=[%s] current_animation_while_paused=%s assigned_animation_while_paused=%s is_playing_while_paused=%s" % [run_id, p, ref, froze, ",".join(paused_lates), ",".join(PackedStringArray(curs.keys())), ",".join(PackedStringArray(assigned.keys())), ",".join(PackedStringArray(playing.keys()))])
		var rvis := ("frame=%d exp_cell=%d mid_frame=%d" % [rr["frame"], rr["exp_cell"], rr["mid_frame"]]) if clip == "scoot" else ("lower=%s upos=%s uscale=%s mid_lower=%s rig_maxdiff=%.9f" % [v2s(rr["lower"]), v2s(rr["upos"]), v2s(rr["uscale"]), v2s(rr["mid_lower"]), rr["rig_diff"]])
		print("RESUME run=%s method=%s n=%d synced_t=%.12f early=%.12f mid=%.12f late=%.12f late_minus_t_frames=%s %s cur=\"%s\" playing=%s ok_a=%s ok_b=%s" % [run_id, m, p + PAUSE_LEN, rt, rr["early"], rr["mid"], rr["late"], radv, rvis, rr["cur"], rr["playing"], rr["ok_a"], rr["ok_b"]])
	print("RUNRESULT run=%s entry_ok_a=%s entry_ok_b=%s ticks_failing_a=%d ticks_failing_b=%d" % [run_id, e["ok_a"], e["ok_b"], run_fail_a, run_fail_b])

func run() -> void:
	hook = TickHook.new()
	hook.name = "ProbeTickHook"
	hook.process_physics_priority = 1000
	hook.on_tick = _late_tick
	root.add_child(hook)
	print("A7 PROBE: engine=%s" % Engine.get_version_info().string)
	var start_phys := Engine.get_physics_frames()
	var start_frames := Engine.get_process_frames()
	for sp in make_specs():
		var ok: bool = await do_run(sp)
		if not ok:
			break
	var dp := Engine.get_physics_frames() - start_phys
	var df := Engine.get_process_frames() - start_frames
	print("RATE physics_ticks=%d process_frames=%d process_frames_per_physics_tick=%.4f" % [dp, df, float(df) / maxf(1.0, float(dp))])
	for key in a1_counts.keys():
		print("A1SUM %s steady_ticks after_parent=%d before_parent=%d other=%d" % [key, a1_counts[key]["after"], a1_counts[key]["before"], a1_counts[key]["other"]])
	for m in entry_adv.keys():
		print("ENTRYADV %s late_minus_t_frames_on_entry_tick=%s" % [m, JSON.stringify(entry_adv[m])])
	for m in resume_adv.keys():
		print("RESUMEADV %s late_minus_t_frames_on_resume_tick=%s" % [m, JSON.stringify(resume_adv[m])])
	for m in pf6.keys():
		print("PF6 %s ticks_with_expected_time_7/60=%d cell1=%d cell0=%d" % [m, pf6[m]["swap_ticks"], pf6[m]["cell1"], pf6[m]["cell0"]])
	for m in method_agg.keys():
		var a: Dictionary = method_agg[m]
		var meets: bool = a["fail_a"] == 0 and a["fail_b"] == 0 and a["ticks"] > 0
		print("SELECT %s runs=%d entries=%d resumes=%d ticks_checked=%d ticks_failing_a=%d ticks_failing_b=%d meets_rule_at_this_rate=%s" % [m, a["runs"], a["entries"], a["resumes"], a["ticks"], a["fail_a"], a["fail_b"], "yes" if meets else "no"])
		if a["first_fail"] != "":
			print("FIRSTFAIL %s %s" % [m, a["first_fail"]])
	print("NOTE R3 (play alone) was run at t = 0 only and on no resume: it cannot seek to a synced time.")
	print("A7 PROBE: %d runs, %d ticks logged" % [runs_done, ticks_logged])
	hook.queue_free()
	for i in range(10):
		await process_frame
	quit(1 if harness_failed else 0)
