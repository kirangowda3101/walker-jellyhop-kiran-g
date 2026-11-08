extends SceneTree
## CPU cost of the two A6 effects (CHANGE-BRIEF.md, "Price predictions and budgets"). Written by
## Claude Code; the chapter's Example 09 script is not in this repository, so this follows the
## repo's own tests (main.tscn loading and the intro skip from test_land_puff_state.gd, the renderer
## report from probe_headless.gd) and Godot's Time and Performance APIs.
## Run: ./scripts/run-test.sh cost_effects.gd 60 300
##
## Cases, each measured over the same number of frames, interleaved over several rounds:
##   empty      a bare Node2D: the control, the price of this script's own frame loop
##   game_off   main.tscn in PLAYING, the effects driver and its DomeGlints removed by this test
##   effect_a   game_off + 2 LandPuff bursts alive at once (brief A5: the most alive at once),
##              10 ticks apart (brief A4/A5 gap 9-12), each restart()ed every lifetime (24 ticks)
##   effect_b   game_off + the driver's DomeGlints kept, emitting at steady state (24 alive)
## No effect or gameplay file is changed. The test only instances land_puff.tscn and calls restart(),
## as the driver does; it sets no particle, material or texture property. It removes the driver
## node after the game loads (the driver itself is therefore not in any game case).
## Headless the renderer is a dummy: no particle process shader runs, so this is CPU time only.
const DRIVER := preload("res://effects/effects_driver.gd")
const LAND_PUFF := preload("res://effects/land_puff.tscn")
const Game = preload("res://game/session.gd")
const CASES := ["empty", "game_off", "effect_a", "effect_b"]
const ROUNDS := 5
const WARMUP_FRAMES := 60
const MEASURE_FRAMES := 300
const PUFF_LIFETIME_TICKS := 24   # land_puff.tscn lifetime 0.40 s at 60 ticks/s
const PUFF_GAP_TICKS := 10        # second burst 10 ticks after the first (brief: 9-12)
var samples := {}                 # case -> {"wall": [], "process": [], "physics": [], "round_means": []}
var puffs: Array[GPUParticles2D] = []
var puff_start := 0   # physics tick the two puffs were created on
var puff_tick := 0    # last physics tick the restart schedule has handled

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("COST display server: ", DisplayServer.get_name())
	print("COST rendering method: ", RenderingServer.get_current_rendering_method())
	print("COST rendering driver: ", RenderingServer.call("get_current_rendering_driver_name") if RenderingServer.has_method("get_current_rendering_driver_name") else "n/a")
	print("COST physics ticks/s: ", Engine.physics_ticks_per_second, "  max_fps: ", Engine.max_fps)
	for c in CASES:
		samples[c] = {"wall": [], "process": [], "physics": [], "round_means": []}
	for r in range(ROUNDS):
		for i in range(CASES.size()):
			var c: String = CASES[(i + r) % CASES.size()]   # rotate the order so drift is spread over cases
			await measure_case(c)
	report()

func measure_case(c: String) -> void:
	var scene: Node2D
	if c == "empty":
		scene = Node2D.new()
		root.add_child(scene)
	else:
		scene = load("res://game/main.tscn").instantiate()
		scene.test_mode = true
		root.add_child(scene)
		await setup_game(scene, c)
	for i in range(WARMUP_FRAMES):
		await frame()
	var wall: Array = []
	var process: Array = []
	var physics: Array = []
	var last := Time.get_ticks_usec()
	for i in range(MEASURE_FRAMES):
		await frame()
		var now := Time.get_ticks_usec()
		wall.append((now - last) / 1000.0)
		last = now
		process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	if c != "empty" and scene.state != Game.State.PLAYING:
		push_error("COST case %s left PLAYING during measurement: %s" % [c, Game.State.keys()[scene.state]])
	samples[c].wall.append_array(wall)
	samples[c].process.append_array(process)
	samples[c].physics.append_array(physics)
	samples[c].round_means.append(mean(wall))
	puffs.clear()
	scene.queue_free()
	for i in range(10):
		await process_frame

func setup_game(game: Node2D, c: String) -> void:
	var driver: Node = null
	for child in game.get_children():
		if child.get_script() == DRIVER:
			driver = child
	if driver == null:
		push_error("COST effects driver not found under the session")
		quit(1)
		return
	var glints: GPUParticles2D = driver.glints
	game.remove_child(driver)
	driver.free()
	if c != "effect_b":
		glints.free()
	# Skip the intro pan with a real key event (session.gd line 404), as the state tests do.
	await key_tap(KEY_ENTER)
	if game.state != Game.State.PLAYING:
		push_error("COST intro skip did not reach PLAYING: %s" % Game.State.keys()[game.state])
	if c == "effect_a":
		for i in range(2):
			var puff: GPUParticles2D = LAND_PUFF.instantiate()
			game.add_child(puff)
			puff.global_position = game.player.global_position
			puffs.append(puff)
		puff_start = Engine.get_physics_frames()
		puff_tick = puff_start - 1

func key_tap(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await frame()

func frame() -> void:
	await process_frame
	if not puffs.is_empty():
		# Two bursts alive at once: puff 0 restarts at tick 0 of each lifetime, puff 1 ten ticks later.
		var now := Engine.get_physics_frames()
		for k in range(puff_tick + 1, now + 1):   # every physics tick since the last frame
			var t := (k - puff_start) % PUFF_LIFETIME_TICKS
			if t == 0:
				puffs[0].restart()
			elif t == PUFF_GAP_TICKS:
				puffs[1].restart()
		puff_tick = now

func mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / a.size()

func stdev(a: Array) -> float:
	var m := mean(a)
	var s := 0.0
	for v in a:
		s += (v - m) * (v - m)
	return sqrt(s / (a.size() - 1))

func percentile(a: Array, p: float) -> float:
	var b := a.duplicate()
	b.sort()
	return b[clampi(int(round(p * (b.size() - 1))), 0, b.size() - 1)]

func stats(a: Array) -> Dictionary:
	return {"mean_ms": snappedf(mean(a), 0.0001), "stdev_ms": snappedf(stdev(a), 0.0001), "min_ms": snappedf(a.min(), 0.0001), "p95_ms": snappedf(percentile(a, 0.95), 0.0001), "max_ms": snappedf(a.max(), 0.0001)}

func report() -> void:
	var out := {}
	for c in CASES:
		var rm: Array = samples[c].round_means
		out[c] = {"frames": samples[c].wall.size(), "wall": stats(samples[c].wall), "engine_process": stats(samples[c].process), "engine_physics": stats(samples[c].physics),
			"round_means_ms": rm.map(func(v): return snappedf(v, 0.0001)), "round_mean_spread_ms": snappedf(rm.max() - rm.min(), 0.0001)}
		print("COST %-9s wall %.4f ms (sd %.4f, min %.4f, p95 %.4f, max %.4f; round means %.4f-%.4f) | engine process %.4f ms (sd %.4f) | engine physics %.4f ms (sd %.4f)" % [
			c, out[c].wall.mean_ms, out[c].wall.stdev_ms, out[c].wall.min_ms, out[c].wall.p95_ms, out[c].wall.max_ms, rm.min(), rm.max(),
			out[c].engine_process.mean_ms, out[c].engine_process.stdev_ms, out[c].engine_physics.mean_ms, out[c].engine_physics.stdev_ms])
	# Pairwise: do two cases' wall means fall within each other's round-to-round spread?
	var flags: Array = []
	for i in range(CASES.size()):
		for j in range(i + 1, CASES.size()):
			var a: String = CASES[i]
			var b: String = CASES[j]
			var diff: float = mean(samples[b].wall) - mean(samples[a].wall)
			var spread: float = maxf(out[a].round_mean_spread_ms, out[b].round_mean_spread_ms)
			var same := absf(diff) <= spread
			print("COST compare %-9s vs %-9s: diff %+.4f ms, larger round-mean spread %.4f ms -> %s" % [b, a, diff, spread, "SAME within spread" if same else "differ"])
			if same:
				flags.append("%s vs %s" % [b, a])
	var control_ok := not ("game_off vs empty" in flags)
	if not control_ok:
		print("COST WARNING: the empty scene and the game with effects off report the same frame time within spread; the script may be measuring itself (its own frame loop), not the game.")
	var report_json := {"scope": "Headless CPU time per frame (dummy renderer, no particle process). Wall = time between process frames measured by this script; engine_process/physics = Performance monitors.",
		"engine": Engine.get_version_info().string, "created_at": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"rounds": ROUNDS, "warmup_frames": WARMUP_FRAMES, "measure_frames": MEASURE_FRAMES, "cases": out, "same_within_spread": flags, "control_separates": control_ok}
	var dir := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir + "/cost-effects-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report_json, "  "))
	file.close()
	print("COST EFFECTS: %d cases x %d rounds x %d frames; control separates: %s" % [CASES.size(), ROUNDS, MEASURE_FRAMES, control_ok])
	quit(0 if control_ok else 1)
