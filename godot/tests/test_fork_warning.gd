extends SceneTree
## Fork warning shader checks (CHANGE-BRIEF.md A5 §3, §5 and Revision 1). Headless: the dummy
## renderer draws nothing, so this checks the material wiring and the `warning` value per physics
## tick and per rendered frame, never a colour on screen. Scripted input only; this is not human
## playtesting. The test never writes a fork's t, held, hold_pending or announced, or session state.
const Game = preload("res://game/session.gd")
const Fork = preload("res://features/fork/fork.gd")
const T = preload("res://game/slice_tuning.gd")
const SHADER_PATH := "res://shaders/fork_warning.gdshader"
const BASE_PATH := "res://materials/fork_warning.tres"
const EPS := 1e-6

var game: Node2D
var ticks: TickSampler
var frames: FrameSampler
var results: Array[Dictionary] = []
var failures: int = 0
var fps: int = 0                    # measured, see measure_fps()
var frame_delta: float = 0.0
var frame_delta_range: Array = []
var idle_rows: Array = []           # the per-tick rows of the idle window (checks 6-9)

class TickSampler extends Node:
	## Every physics tick, after the player (priority 0) and the session (10) have run, so it sees
	## the forks as the session left them on that tick.
	var game: Node2D
	var rows: Array = []
	func _init(g: Node2D) -> void:
		game = g
		process_physics_priority = 1000
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _physics_process(_delta: float) -> void:
		var forks := []
		for fork in game.forks:
			if fork:
				forks.append({"w": fork.sprite.material.get_shader_parameter("warning"), "t": fork.t, "held": fork.held, "phase": fork.phase()})
			else:
				forks.append(null)
		rows.append({"tick": Engine.get_physics_frames(), "state": game.state, "paused": get_tree().paused, "forks": forks})

class FrameSampler extends Node:
	## Every rendered frame, after every other _process(): each fork's `warning` and the game time
	## (sum of _process delta, so it is scaled by Engine.time_scale).
	var game: Node2D
	var rows: Array = []
	var game_time: float = 0.0
	func _init(g: Node2D) -> void:
		game = g
		process_priority = 1000
		process_mode = Node.PROCESS_MODE_ALWAYS
	func _process(delta: float) -> void:
		game_time += delta
		var w := []
		for fork in game.forks:
			w.append(fork.sprite.material.get_shader_parameter("warning") if fork else null)
		rows.append({"frame": Engine.get_process_frames(), "tick": Engine.get_physics_frames(), "time": game_time, "delta": delta, "state": game.state, "paused": get_tree().paused, "w": w})

func _initialize() -> void:
	call_deferred("run")

func check(id: String, passed: bool, observation: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observation})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

func measure_fps() -> void:
	## --fixed-fps is not in OS.get_cmdline_args(), so the frame period is measured: the median
	## _process delta of the INTRO frames (Engine.time_scale is 1.0 there), fps = round(1 / delta).
	var deltas := []
	for r in frames.rows:
		if r.state == Game.State.INTRO:
			deltas.append(r.delta)
	deltas.sort()
	frame_delta = deltas[deltas.size() / 2] if not deltas.is_empty() else 0.0
	fps = int(round(1.0 / frame_delta)) if frame_delta > 0.0 else 0
	frame_delta_range = [deltas.front(), deltas.back()] if not deltas.is_empty() else []

func fork_indices() -> Array:
	var out := []
	for i in range(game.forks.size()):
		if game.forks[i]:
			out.append(i)
	return out

func run() -> void:
	shader_checks()
	start_game()
	material_checks()
	await intro_checks()
	measure_fps()
	await idle_checks()
	await pause_checks()
	await tree_pause_checks()
	await time_scale_checks()
	await finish()

func wait_until(condition: Callable, max_ticks: int) -> bool:
	var start := Engine.get_physics_frames()
	while not condition.call():
		if Engine.get_physics_frames() - start > max_ticks:
			return false
		await process_frame
	return true

func key(code: Key, pressed: bool) -> void:
	## A real key event through Godot Input, as test_keyboard.gd sends them.
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame
	await process_frame

func tap(code: Key) -> void:
	await key(code, true)
	await key(code, false)

func w_of(i: int) -> float:
	return game.forks[i].sprite.material.get_shader_parameter("warning")

func wait_mid_shadow(i: int, max_ticks: int) -> bool:
	## Until plate i's fork is between a quarter and 0.6 of the way through SHADOW, so one more
	## tick keeps it in SHADOW.
	return await wait_until(func(): return w_of(i) >= 0.25 and w_of(i) <= 0.6, max_ticks)

func wait_ticks(n: int) -> void:
	var target := Engine.get_physics_frames() + n
	while Engine.get_physics_frames() < target:
		await process_frame

func cycle_of(i: int) -> Dictionary:
	## Plate i's cycle in ticks, from slice_tuning.gd alone (not read from the fork).
	var c = T.FORK_CYCLES[i]
	var safe := T.ticks(c.safe)
	var shadow := T.ticks(c.shadow)
	return {"safe": safe, "shadow": shadow, "offset": T.ticks(c.offset), "period": safe + shadow + T.ticks(T.STRIKE_DOWN) + T.ticks(T.STRIKE_HOLD) + T.ticks(T.STRIKE_UP)}

func expected_at(i: int, pos: int) -> float:
	## The brief's formula (§2) at cycle position pos: (p - safe + 1) / shadow in SHADOW, else 0.
	var c := cycle_of(i)
	var p := posmod(pos, c.period)
	if p >= c.safe and p < c.safe + c.shadow:
		return float(p - c.safe + 1) / float(c.shadow)
	return 0.0

func start_game() -> void:
	## The real session, as the tests build it (Game.new(), not main.tscn), left in INTRO.
	## test_mode only stops a lost window focus from pausing the run.
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	ticks = TickSampler.new(game)
	root.add_child(ticks)
	frames = FrameSampler.new(game)
	root.add_child(frames)

func finish() -> void:
	var report := {"scope": "Fork warning shader checks (headless, scripted input); not human playtesting and no colour on screen", "engine": Engine.get_version_info().string, "measured_fps": fps, "measured_frame_delta_s": frame_delta, "intro_frame_delta_min_max_s": frame_delta_range, "created_at": Time.get_datetime_string_from_system(true), "results": results, "failures": failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/fork-warning-%dfps-%d.json" % [fps, int(Time.get_unix_time_from_system())], FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("FORK WARNING TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	ticks.queue_free()
	frames.queue_free()
	for i in range(30):
		await process_frame   # let the audio server release stopped playbacks before quitting
	quit(1 if failures else 0)

# ---------------------------------------------------------------- 1, 2: the shader resource

func shader_checks() -> void:
	var shader: Shader = load(SHADER_PATH)
	var uniforms := {}
	for u in shader.get_shader_uniform_list():
		uniforms[u.name] = {"type": u.type, "type_name": type_string(u.type), "hint": u.hint, "hint_string": u.hint_string}
	var names := uniforms.keys()
	names.sort()
	check("1-uniform-names", names == ["strength", "warn_color", "warning"], {"names": names})
	for n in ["warning", "strength"]:
		var u: Dictionary = uniforms.get(n, {})
		var parts: PackedStringArray = String(u.get("hint_string", "")).split(",")
		var range_ok: bool = parts.size() >= 2 and is_equal_approx(parts[0].to_float(), 0.0) and is_equal_approx(parts[1].to_float(), 1.0)
		check("1-%s-float-range-0-1" % n, u.get("type") == TYPE_FLOAT and u.get("hint") == PROPERTY_HINT_RANGE and range_ok, u)
	# Expected TYPE_COLOR (20) for a vec4 with source_color; the observed type is recorded as is.
	var wc: Dictionary = uniforms.get("warn_color", {})
	check("1-warn_color-type-color", wc.get("type") == TYPE_COLOR, wc)
	# Defaults are not reported headlessly (CLAUDE.md headless facts), so they are read from the source.
	var src := FileAccess.get_file_as_string(SHADER_PATH)
	var patterns := {
		"shader_type": "(?m)^\\s*shader_type\\s+canvas_item\\s*;",
		"render_mode": "(?m)^\\s*render_mode\\s+unshaded\\s*;",
		"warning": "uniform\\s+float\\s+warning\\s*:\\s*hint_range\\(\\s*0\\.0\\s*,\\s*1\\.0\\s*\\)\\s*=\\s*0\\.0\\s*;",
		"warn_color": "uniform\\s+vec4\\s+warn_color\\s*:\\s*source_color\\s*=\\s*vec4\\(\\s*1\\.0\\s*,\\s*0\\.702\\s*,\\s*0\\.278\\s*,\\s*1\\.0\\s*\\)\\s*;",
		"strength": "uniform\\s+float\\s+strength\\s*:\\s*hint_range\\(\\s*0\\.0\\s*,\\s*1\\.0\\s*\\)\\s*=\\s*0\\.65\\s*;",
	}
	var found := {}
	for key in patterns:
		var re := RegEx.create_from_string(patterns[key])
		found[key] = re.search(src) != null
	check("2-source-defaults-and-modes", not found.values().has(false), found)
	var line := "COLOR.rgb = mix(COLOR.rgb, warn_color.rgb, warning * strength);"
	check("2-source-colour-line", src.contains(line) and not src.contains("COLOR.a") and not src.contains("sampler2D"), {"colour_line": src.contains(line), "writes_COLOR_a": src.contains("COLOR.a"), "sampler_uniform": src.contains("sampler2D")})

# ---------------------------------------------------------------- 3, 4: one material per fork

func material_checks() -> void:
	var base: ShaderMaterial = load(BASE_PATH)
	var idx := fork_indices()
	var ids := {}
	var is_base := []
	var shaders := {}
	for i in idx:
		var m = game.forks[i].sprite.material
		ids[m.get_instance_id()] = true
		if m == base or m == Fork.WARNING_MATERIAL:
			is_base.append(i + 1)
		shaders[(m.shader as Shader).get_instance_id() if m is ShaderMaterial and m.shader else 0] = true
	check("3-five-forks-plate-1-none", idx == [1, 2, 3, 4, 5] and game.forks[0] == null, {"fork_plates": idx.map(func(i): return i + 1)})
	check("3-distinct-materials", ids.size() == 5, {"distinct_material_ids": ids.size()})
	check("3-none-is-the-base-tres", is_base.is_empty() and base == Fork.WARNING_MATERIAL, {"plates_using_base_object": is_base, "base_is_preloaded_object": base == Fork.WARNING_MATERIAL})
	check("3-one-shared-shader", shaders.size() == 1 and shaders.has(base.shader.get_instance_id()) and base.shader == load(SHADER_PATH), {"distinct_shader_ids": shaders.size(), "same_as_base_shader": shaders.has(base.shader.get_instance_id()), "base_shader_path": base.shader.resource_path})
	# strength and warn_color: nobody sets them at runtime, so each fork reads what the base reads.
	var base_values := {}
	for p in ["strength", "warn_color"]:
		var v = base.get_shader_parameter(p)
		base_values[p] = {"value": str(v), "type": type_string(typeof(v))}
	var mismatches := []
	for i in idx:
		for p in ["strength", "warn_color"]:
			var a = game.forks[i].sprite.material.get_shader_parameter(p)
			var b = base.get_shader_parameter(p)
			if typeof(a) != typeof(b) or a != b:
				mismatches.append({"plate": i + 1, "param": p, "fork": str(a), "base": str(b)})
	check("4-strength-warn_color-equal-base", mismatches.is_empty(), {"base_reads_back": base_values, "mismatches": mismatches})

# ---------------------------------------------------------------- 5: starting mid-state, held through the intro

func start_values() -> Array:
	## Each fork's `warning` at its starting t (slice_tuning.gd offsets), from the cycle numbers alone.
	var out := []
	for i in range(T.FORK_CYCLES.size()):
		var c = T.FORK_CYCLES[i]
		if c == null:
			out.append(null)
			continue
		var safe := T.ticks(c.safe)
		var shadow := T.ticks(c.shadow)
		var p := T.ticks(c.offset)
		out.append(float(p - safe + 1) / float(shadow) if p >= safe and p < safe + shadow else 0.0)
	return out

func max_diff(a: Array, b: Array) -> float:
	var d := 0.0
	for i in range(a.size()):
		if a[i] == null or b[i] == null:
			if a[i] != b[i]:
				return INF
			continue
		d = maxf(d, absf(float(a[i]) - float(b[i])))
	return d

func tick_w(row: Dictionary) -> Array:
	var w := []
	for f in row.forks:
		w.append(f.w if f else null)
	return w

func intro_checks() -> void:
	var want := start_values()
	check("5-start-values-are-the-brief-numbers", absf(want[4] - 37.0 / 72.0) < EPS and absf(want[5] - 31.0 / 60.0) < EPS and want[1] == 0.0 and want[2] == 0.0 and want[3] == 0.0, {"expected_per_plate": want})
	# No key: the pan runs to its end and starts play by itself (session.gd, INTRO branch).
	var ended: bool = await wait_until(func(): return game.state != Game.State.INTRO, T.ticks(T.INTRO_PAN) + 30)
	var first: Dictionary = frames.rows[0]
	check("5-first-frame-intro-plates-5-6-mid-shadow", first.state == Game.State.INTRO and max_diff(first.w, want) < EPS, {"state": first.state, "w": first.w, "max_abs_diff": max_diff(first.w, want)})
	var intro_frames := 0
	var frame_diff := 0.0
	for r in frames.rows:
		if r.state == Game.State.INTRO:
			intro_frames += 1
			frame_diff = maxf(frame_diff, max_diff(r.w, want))
	var intro_ticks := 0
	var tick_diff := 0.0
	for r in ticks.rows:
		if r.state == Game.State.INTRO:
			intro_ticks += 1
			tick_diff = maxf(tick_diff, max_diff(tick_w(r), want))
	check("5-intro-holds-every-frame", ended and intro_frames > 0 and frame_diff < EPS, {"pan_ended_by_itself": ended, "intro_frames": intro_frames, "max_abs_diff": frame_diff})
	check("5-intro-holds-every-tick", ended and intro_ticks >= T.ticks(T.INTRO_PAN) - 2 and tick_diff < EPS, {"intro_ticks_sampled": intro_ticks, "pan_ticks": T.ticks(T.INTRO_PAN), "max_abs_diff": tick_diff})

# ---------------------------------------------------------------- 6-9: idle play, per tick and per frame

const IDLE_TICKS := 600   # at least two SHADOW phases of every fork

func ramp_report(i: int, seq: Array) -> Dictionary:
	## seq[k] = plate i's `warning` k ticks after play started (k = 0 is the start tick, t = offset).
	## For every complete SHADOW in seq: 0 before, 1/n first, +1/n per tick, exactly 1.0 last, 0 after.
	var c := cycle_of(i)
	var n: int = c.shadow
	var ramps := 0
	var errors := []
	for k0 in range(1, seq.size()):
		if posmod(c.offset + k0, c.period) != c.safe:
			continue   # not the first SHADOW tick
		var k1: int = k0 + n - 1
		if k1 + 1 >= seq.size():
			continue   # incomplete at the end of the window
		ramps += 1
		if seq[k0 - 1] != 0.0:
			errors.append({"k": k0 - 1, "what": "last SAFE tick", "got": seq[k0 - 1]})
		if absf(seq[k0] - 1.0 / n) > EPS:
			errors.append({"k": k0, "what": "first SHADOW tick, want 1/%d" % n, "got": seq[k0]})
		for j in range(1, n):
			if absf(seq[k0 + j] - seq[k0 + j - 1] - 1.0 / n) > EPS:
				errors.append({"k": k0 + j, "what": "step of 1/%d" % n, "got": seq[k0 + j] - seq[k0 + j - 1]})
				break
		if seq[k1] != 1.0:
			errors.append({"k": k1, "what": "last SHADOW tick, want exactly 1.0", "got": seq[k1]})
		if seq[k1 + 1] != 0.0:
			errors.append({"k": k1 + 1, "what": "first DOWN tick", "got": seq[k1 + 1]})
	return {"shadow_ticks": n, "complete_ramps": ramps, "errors": errors}

func frame_ramps(i: int, rows: Array) -> Array:
	## Per-frame ramps of plate i: first frame with warning > 0 (after a 0 frame) to the first frame back at 0.
	var out := []
	var start := -1
	for f in range(1, rows.size()):
		var w: float = rows[f].w[i]
		if start < 0 and rows[f - 1].w[i] == 0.0 and w > 0.0:
			start = f
		elif start >= 0 and w == 0.0:
			out.append({"seconds": rows[f].time - rows[start].time, "first": rows[start].w[i], "last": rows[f - 1].w[i]})
			start = -1
	return out

func frame_period() -> float:
	return 1.0 / float(fps) if fps > 0 else 1.0 / 60.0

func duration_ok(seconds: float, n: int) -> bool:
	## Rule 2: the SHADOW length (n ticks at 60 per second) within one frame period.
	return absf(seconds - float(n) / 60.0) <= frame_period() + 1e-9

func idle_checks() -> void:
	# The pan has just ended by itself; the jelly stands idle on plate 1 (no fork) with no key held.
	var s0 := -1
	for r in range(ticks.rows.size()):
		if ticks.rows[r].state == Game.State.PLAYING:
			s0 = r
			break
	var reached: bool = await wait_until(func(): return ticks.rows.size() > s0 + IDLE_TICKS, IDLE_TICKS + 30)
	# Searched only after the wait: process_frame resumes this coroutine before the frame sampler's
	# _process() has recorded the frame on which play started.
	var f0 := -1
	for f in range(frames.rows.size()):
		if frames.rows[f].state == Game.State.PLAYING:
			f0 = f
			break
	var window: Array = ticks.rows.slice(s0, s0 + IDLE_TICKS + 1)
	idle_rows = window
	var end_tick: int = window.back().tick
	var frame_window := []
	for f in range(f0 if f0 >= 0 else frames.rows.size(), frames.rows.size()):   # no PLAYING frame: empty, so check 9 fails
		if frames.rows[f].tick <= end_tick:
			frame_window.append(frames.rows[f])
	var idx := fork_indices()
	# 6: every tick, every fork, against offset + k through the cycle numbers.
	var seqs := {}
	var worst := 0.0
	var first_bad := {}
	var all_playing := true
	var trace := PackedStringArray()
	for k in range(window.size()):
		var row: Dictionary = window[k]
		all_playing = all_playing and row.state == Game.State.PLAYING
		for i in idx:
			var got: float = row.forks[i].w
			var want := expected_at(i, cycle_of(i).offset + k)
			if not seqs.has(i):
				seqs[i] = []
			seqs[i].append(got)
			var d := absf(got - want)
			if d > worst:
				worst = d
			if d > EPS and first_bad.is_empty():
				first_bad = {"k": k, "plate": i + 1, "got": got, "want": want}
			trace.append("%.12f" % got)
	var md5 := "".join(trace).md5_text()
	print("FORK WARNING PER-TICK SEQUENCE MD5 (%d ticks x %d forks): %s" % [window.size(), idx.size(), md5])
	check("6-per-tick-equals-formula", reached and s0 >= 0 and all_playing and window.size() == IDLE_TICKS + 1 and worst < EPS, {"ticks": window.size(), "stayed_playing": all_playing, "max_abs_diff": worst, "exactly_equal": worst == 0.0, "first_mismatch": first_bad, "sequence_md5": md5})
	# 7: ramp shape; each new SHADOW in the cycle restarts at 1/n.
	var reports := {}
	var ramp_ok := true
	for i in idx:
		var rep := ramp_report(i, seqs[i])
		reports[i + 1] = rep
		ramp_ok = ramp_ok and rep.complete_ramps >= 1 and rep.errors.is_empty()
	check("7-ramp-0-then-1-over-n-to-exactly-1-then-0", ramp_ok, reports)
	# 8: one fork in SHADOW above 0 while another, in SAFE, reads 0.
	var seen := {}
	for row in window:
		for a in idx:
			for b in idx:
				if a != b and row.forks[a].phase == Fork.Phase.SHADOW and row.forks[a].w > 0.0 and row.forks[b].phase == Fork.Phase.SAFE and row.forks[b].w == 0.0:
					seen = {"tick": row.tick, "shadow_plate": a + 1, "shadow_w": row.forks[a].w, "safe_plate": b + 1, "safe_w": row.forks[b].w}
					break
			if not seen.is_empty():
				break
		if not seen.is_empty():
			break
	check("8-shadow-fork-glows-safe-fork-reads-0", not seen.is_empty(), seen)
	# 9: per rendered frame, game time of each ramp equals the SHADOW length within one frame period.
	var per_plate := {}
	var frames_ok := true
	for i in idx:
		var n: int = cycle_of(i).shadow
		var list := frame_ramps(i, frame_window)
		var bad := []
		for ramp in list:
			var ok := duration_ok(ramp.seconds, n)
			if fps == 60:
				ok = ok and absf(ramp.first - 1.0 / n) < EPS and ramp.last == 1.0   # one tick per frame
			if not ok:
				bad.append(ramp)
		per_plate[i + 1] = {"expected_s": float(n) / 60.0, "ramps": list, "bad": bad}
		frames_ok = frames_ok and not list.is_empty() and bad.is_empty()
	check("9-per-frame-ramp-duration", frames_ok and frame_window.size() > 0, {"fps": fps, "tolerance_s": frame_period(), "frames": frame_window.size(), "per_plate": per_plate})
	# 9c controls: the same checks must fail on a sequence one tick late, and on a ramp counted in frames.
	var late_errors := 0
	for i in idx:
		var late: Array = [0.0] + seqs[i].slice(0, seqs[i].size() - 1)
		late_errors += ramp_report(i, late).errors.size()
	check("9c-control-one-tick-late-fails-check-7", late_errors > 0, {"errors_found_in_late_sequence": late_errors})
	# A driver that counts n frames: n * frame period seconds (CHANGE-BRIEF.md §10.5). It fails rule 2
	# at 30 and 144 fps; at 60 fps one frame is one tick, so it cannot be told apart and must pass.
	var counted := {}
	var counted_fail := 0
	for i in idx:
		var n: int = cycle_of(i).shadow
		var s := float(n) * frame_period()
		counted[i + 1] = s
		if not duration_ok(s, n):
			counted_fail += 1
	var control_ok := counted_fail == 0 if fps == 60 else counted_fail == idx.size()
	check("9c-control-frame-counted-ramp", control_ok, {"fps": fps, "frame_counted_seconds": counted, "plates_failing_rule_2": counted_fail})

# ---------------------------------------------------------------- 10, 10b, 11: pause and time scale

const HOLD_TICKS := 120

func hold_report(i: int, tick_mark: int, frame_mark: int, frozen: Callable) -> Dictionary:
	## From tick_mark on: every frozen tick and frame shows every fork's value from the last tick
	## before the freeze, t does not move, and plate i rises by exactly 1/n on the first tick after.
	var before := -1
	var after := -1
	var frozen_ticks := 0
	for r in range(tick_mark, ticks.rows.size()):
		if frozen.call(ticks.rows[r]):
			if before < 0:
				before = r - 1
			frozen_ticks += 1
		elif before >= 0:
			after = r
			break
	if before < 0 or after < 0:
		return {"ok": false, "reason": "no complete freeze found", "frozen_ticks": frozen_ticks}
	var held := tick_w(ticks.rows[before])
	var tick_diff := 0.0
	var t_moved := []
	for r in range(before + 1, after):
		tick_diff = maxf(tick_diff, max_diff(tick_w(ticks.rows[r]), held))
		for j in fork_indices():
			if ticks.rows[r].forks[j].t != ticks.rows[before].forks[j].t and not t_moved.has(j + 1):
				t_moved.append(j + 1)
	var frozen_frames := 0
	var frame_diff := 0.0
	for f in range(frame_mark, frames.rows.size()):
		if frozen.call(frames.rows[f]):
			frozen_frames += 1
			frame_diff = maxf(frame_diff, max_diff(frames.rows[f].w, held))
	var n: int = cycle_of(i).shadow
	var rise: float = ticks.rows[after].forks[i].w - held[i]
	var ok := frozen_ticks >= HOLD_TICKS - 2 and frozen_frames > 0 and tick_diff == 0.0 and frame_diff == 0.0 and t_moved.is_empty() and absf(rise - 1.0 / n) < EPS
	return {"ok": ok, "plate": i + 1, "held_value": held[i], "frozen_ticks": frozen_ticks, "frozen_frames": frozen_frames, "max_tick_diff": tick_diff, "max_frame_diff": frame_diff, "plates_whose_t_moved": t_moved, "rise_after_resume": rise, "want_rise": 1.0 / n}

func pause_checks() -> void:
	# 10: a real Esc press while plate 2's fork is mid-SHADOW; a second Esc resumes.
	var i := 1
	var found: bool = await wait_mid_shadow(i, cycle_of(i).period + 10)
	var tick_mark := ticks.rows.size()
	var frame_mark := frames.rows.size()
	await tap(KEY_ESCAPE)
	var paused: bool = game.state == Game.State.PAUSED
	await wait_ticks(HOLD_TICKS)
	await tap(KEY_ESCAPE)
	await wait_ticks(5)
	var rep := hold_report(i, tick_mark, frame_mark, func(r): return r.state == Game.State.PAUSED)
	rep["found_mid_shadow"] = found
	rep["esc_paused"] = paused
	rep["resumed"] = game.state == Game.State.PLAYING
	check("10-esc-pause-holds-warning-then-resumes-by-1-over-n", found and paused and rep.resumed and rep.ok, rep)

func tree_pause_checks() -> void:
	# 10b: fixture, not the game's own pause: SceneTree.paused while plate 3's fork is mid-SHADOW.
	var i := 2
	var found: bool = await wait_mid_shadow(i, cycle_of(i).period + 10)
	var tick_mark := ticks.rows.size()
	var frame_mark := frames.rows.size()
	paused = true
	await wait_ticks(HOLD_TICKS)
	paused = false
	await wait_ticks(5)
	var rep := hold_report(i, tick_mark, frame_mark, func(r): return r.paused)
	rep["found_mid_shadow"] = found
	rep["state_stayed_playing"] = game.state == Game.State.PLAYING
	check("10b-tree-paused-holds-warning-then-resumes-by-1-over-n", found and rep.state_stayed_playing and rep.ok, rep)

func tick_ramps(i: int, rows: Array) -> Array:
	## Per-tick ramps of plate i in rows: {ticks: first tick with warning > 0 to the first tick back at 0, start_row}.
	var out := []
	var start := -1
	for r in range(1, rows.size()):
		var w: float = rows[r].forks[i].w
		if start < 0 and rows[r - 1].forks[i].w == 0.0 and w > 0.0:
			start = r
		elif start >= 0 and w == 0.0:
			out.append({"ticks": rows[r].tick - rows[start].tick, "start": start, "end": r})
			start = -1
	return out

func time_scale_checks() -> void:
	# 11: one full ramp of plate 2's fork at Engine.time_scale = 0.5 (fixture), against the same
	# fork's ramps at 1.0 in the idle window.
	var i := 1
	var n: int = cycle_of(i).shadow
	var at_one := tick_ramps(i, idle_rows).map(func(r): return r.ticks)   # idle window only: no pause inside
	await wait_until(func(): return game.forks[i].phase() == Fork.Phase.SAFE, cycle_of(i).period)
	var tick_mark := ticks.rows.size()
	var frame_mark := frames.rows.size()
	Engine.time_scale = 0.5
	var done: bool = await wait_until(func(): return tick_ramps(i, ticks.rows.slice(tick_mark - 1)).size() >= 1, cycle_of(i).period + 10)
	Engine.time_scale = 1.0
	var slow := tick_ramps(i, ticks.rows.slice(tick_mark - 1))
	var slow_ticks: int = slow[0].ticks if not slow.is_empty() else -1
	# The same ramp per frame: game time (scaled delta) and real time (frames x frame period).
	var fr: Array = frames.rows.slice(frame_mark - 1)
	var f_start := -1
	var f_end := -1
	for f in range(1, fr.size()):
		if f_start < 0 and fr[f - 1].w[i] == 0.0 and fr[f].w[i] > 0.0:
			f_start = f
		elif f_start >= 0 and fr[f].w[i] == 0.0:
			f_end = f
			break
	var game_s: float = fr[f_end].time - fr[f_start].time if f_end > 0 else -1.0
	var real_s: float = float(f_end - f_start) * frame_period() if f_end > 0 else -1.0
	var deltas_halved: bool = f_end > 0 and absf(fr[f_start].delta - 0.5 * frame_delta) < 1e-9
	check("11-time-scale-0.5-same-tick-count", done and slow_ticks == n and not at_one.is_empty() and at_one.all(func(x): return x == n), {"plate": i + 1, "ramp_ticks_at_0.5": slow_ticks, "ramp_ticks_at_1.0": at_one, "shadow_ticks": n})
	# Prediction (CHANGE-BRIEF.md rule 5): about 0.8 s of scaled game time, 1.6 s of real time.
	check("11-time-scale-0.5-game-time-half", deltas_halved and absf(game_s - 0.5 * n / 60.0) <= 0.5 * frame_period() + 1e-9 and absf(real_s - float(n) / 60.0) <= frame_period() + 1e-9, {"scaled_game_seconds": game_s, "want_game_seconds": 0.5 * n / 60.0, "real_seconds_from_frames": real_s, "want_real_seconds": float(n) / 60.0, "frame_delta_at_0.5": fr[f_start].delta if f_start > 0 else null, "time_scale_after": Engine.time_scale})
