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
##   effect_a_restart    game_off + 2 LandPuff bursts alive at once (brief A5: the most alive at
##                       once), 10 ticks apart (brief A4/A5 gap 9-12), the same two instances
##                       restart()ed every lifetime (24 ticks): no instancing or freeing
##   effect_a_lifecycle  game_off + the per-landing lifecycle of effects_driver.gd, mirrored in this
##                       test: on a 24-tick cycle, at tick 0 and tick 10, a new land_puff.tscn is
##                       instanced, added to the session, placed at the jelly's global_position, its
##                       finished signal connected to queue_free, then emitting = true, in the
##                       driver's order. Slot limit: a due spawn waits until fewer than
##                       MAX_LIVE_PUFFS (2) lifecycle puffs are live (spawned, finished not yet
##                       fired), then spawns on the first frame a slot is open. So never more than
##                       two bursts alive at once; every puff is created and freed, and leaves only
##                       through finished -> queue_free.
##   effect_b            game_off + the driver's DomeGlints kept, emitting at steady state (24 alive)
## No effect or gameplay file is changed. The gameplay effects driver is removed from every game
## case after the game loads, so its own per-frame work is not in any case; effect_a_lifecycle
## mirrors the driver's spawn code inside this test instead of running the driver (and runs it after
## process_frame, where the driver runs it in _physics_process). The test instances land_puff.tscn,
## calls restart(), connects finished and sets emitting, as the driver does; it sets no particle,
## material or texture property.
## Headless the renderer is a dummy: no particle process shader runs, so this is CPU time only.
const DRIVER := preload("res://effects/effects_driver.gd")
const LAND_PUFF := preload("res://effects/land_puff.tscn")
const Game = preload("res://game/session.gd")
const CASES := ["empty", "game_off", "effect_a_restart", "effect_a_lifecycle", "effect_b"]
const ROUNDS := 5
const WARMUP_FRAMES := 60
const MEASURE_FRAMES := 300
const PUFF_LIFETIME_TICKS := 24   # land_puff.tscn lifetime 0.40 s at 60 ticks/s
const PUFF_GAP_TICKS := 10        # second burst 10 ticks after the first (brief: 9-12)
const MAX_LIVE_PUFFS := 2         # effect_a_lifecycle slot limit (brief A5: at most 2 bursts alive)
var samples := {}                 # case -> {"wall": [], "process": [], "physics": [], "round_means": []}
var puff_mode := ""   # "", "restart" or "lifecycle": which effect_a schedule frame() runs
var puffs: Array[GPUParticles2D] = []   # effect_a_restart: the two reused instances
var puff_game: Node2D                   # effect_a_lifecycle: the session puffs are added to
var puff_start := 0   # physics tick the schedule started on
var puff_tick := 0    # last physics tick the schedule has handled
var measuring := false
var created_measured := 0   # effect_a_lifecycle: puffs created during measured frames
var freed_measured := 0     # effect_a_lifecycle: puffs freed (tree_exited) during measured frames
var pending_spawns := 0     # effect_a_lifecycle: spawns due but waiting for a slot
var live_lifecycle := 0     # effect_a_lifecycle: spawned puffs whose finished has not fired

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("COST display server: ", DisplayServer.get_name())
	print("COST rendering method: ", RenderingServer.get_current_rendering_method())
	print("COST rendering driver: ", RenderingServer.call("get_current_rendering_driver_name") if RenderingServer.has_method("get_current_rendering_driver_name") else "n/a")
	print("COST physics ticks/s: ", Engine.physics_ticks_per_second, "  max_fps: ", Engine.max_fps)
	for c in CASES:
		samples[c] = {"wall": [], "process": [], "physics": [], "round_means": [], "created": 0, "freed": 0}
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
	created_measured = 0
	freed_measured = 0
	measuring = true
	var last := Time.get_ticks_usec()
	for i in range(MEASURE_FRAMES):
		await frame()
		var now := Time.get_ticks_usec()
		wall.append((now - last) / 1000.0)
		last = now
		process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	measuring = false
	if c == "effect_a_lifecycle":
		samples[c].created += created_measured
		samples[c].freed += freed_measured
		print("COST effect_a_lifecycle round: puffs created %d, freed %d during %d measured frames" % [created_measured, freed_measured, MEASURE_FRAMES])
	if c != "empty" and scene.state != Game.State.PLAYING:
		push_error("COST case %s left PLAYING during measurement: %s" % [c, Game.State.keys()[scene.state]])
	samples[c].wall.append_array(wall)
	samples[c].process.append_array(process)
	samples[c].physics.append_array(physics)
	samples[c].round_means.append(mean(wall))
	puff_mode = ""
	puffs.clear()
	puff_game = null
	pending_spawns = 0
	live_lifecycle = 0
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
	if c == "effect_a_restart":
		for i in range(2):
			var puff: GPUParticles2D = LAND_PUFF.instantiate()
			game.add_child(puff)
			puff.global_position = game.player.global_position
			puffs.append(puff)
		puff_mode = "restart"
	elif c == "effect_a_lifecycle":
		puff_game = game
		puff_mode = "lifecycle"
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
	if puff_mode == "":
		return
	# Two bursts alive at once: one at tick 0 of each lifetime, the other ten ticks later.
	var now := Engine.get_physics_frames()
	for k in range(puff_tick + 1, now + 1):   # every physics tick since the last frame
		var t := (k - puff_start) % PUFF_LIFETIME_TICKS
		if t != 0 and t != PUFF_GAP_TICKS:
			continue
		if puff_mode == "restart":
			puffs[0 if t == 0 else 1].restart()
		else:
			pending_spawns += 1
	puff_tick = now
	# effect_a_lifecycle: a due spawn waits for a slot, and spawns on the first frame one is open.
	while puff_mode == "lifecycle" and pending_spawns > 0 and live_lifecycle < MAX_LIVE_PUFFS:
		pending_spawns -= 1
		spawn_puff()

func spawn_puff() -> void:
	## Mirrors effects_driver.gd lines 22-26, in the same order.
	var puff: GPUParticles2D = LAND_PUFF.instantiate()
	puff_game.add_child(puff)
	puff.global_position = puff_game.player.global_position
	puff.finished.connect(puff.queue_free)
	puff.emitting = true
	# Slot bookkeeping: live until this puff's finished fires (a second connection to the same signal).
	live_lifecycle += 1
	puff.finished.connect(func() -> void: live_lifecycle -= 1)
	# Test bookkeeping only: count creations and frees that happen while measuring.
	if measuring:
		created_measured += 1
	puff.tree_exited.connect(func() -> void:
		if measuring:
			freed_measured += 1)

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
		if c == "effect_a_lifecycle":
			out[c].puffs_created_measured = samples[c].created
			out[c].puffs_freed_measured = samples[c].freed
		print("COST %-18s wall %.4f ms (sd %.4f, min %.4f, p95 %.4f, max %.4f; round means %.4f-%.4f) | engine process %.4f ms (sd %.4f) | engine physics %.4f ms (sd %.4f)" % [
			c, out[c].wall.mean_ms, out[c].wall.stdev_ms, out[c].wall.min_ms, out[c].wall.p95_ms, out[c].wall.max_ms, rm.min(), rm.max(),
			out[c].engine_process.mean_ms, out[c].engine_process.stdev_ms, out[c].engine_physics.mean_ms, out[c].engine_physics.stdev_ms])
	print("COST effect_a_lifecycle total: puffs created %d, freed %d during %d measured frames (%d rounds)" % [samples.effect_a_lifecycle.created, samples.effect_a_lifecycle.freed, MEASURE_FRAMES * ROUNDS, ROUNDS])
	# Pairwise: do two cases' wall means fall within each other's round-to-round spread?
	var flags: Array = []
	var comparisons: Array = []
	for i in range(CASES.size()):
		for j in range(i + 1, CASES.size()):
			var a: String = CASES[i]
			var b: String = CASES[j]
			var diff: float = mean(samples[b].wall) - mean(samples[a].wall)
			var spread: float = maxf(out[a].round_mean_spread_ms, out[b].round_mean_spread_ms)
			var same := absf(diff) <= spread
			var verdict := "not distinguishable within spread" if same else "differ"
			print("COST compare %-18s vs %-18s: diff %+.4f ms, larger round-mean spread %.4f ms -> %s" % [b, a, diff, spread, verdict])
			comparisons.append({"case": b, "against": a, "diff_ms": snappedf(diff, 0.0001), "larger_round_mean_spread_ms": snappedf(spread, 0.0001), "verdict": verdict})
			if same:
				flags.append("%s vs %s" % [b, a])
	var control_ok := not ("game_off vs empty" in flags)
	if not control_ok:
		print("COST WARNING: the empty scene and the game with effects off are not distinguishable within spread; the script may be measuring itself (its own frame loop), not the game.")
	var report_json := {"scope": "Headless CPU time per frame (dummy renderer, no particle process). Wall = time between process frames measured by this script; engine_process/physics = Performance monitors.",
		"engine": Engine.get_version_info().string, "created_at": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"rounds": ROUNDS, "warmup_frames": WARMUP_FRAMES, "measure_frames": MEASURE_FRAMES, "cases": out, "comparisons": comparisons, "not_distinguishable_within_spread": flags, "control_separates": control_ok}
	var dir := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir + "/cost-effects-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report_json, "  "))
	file.close()
	print("COST EFFECTS: %d cases x %d rounds x %d frames; control separates: %s" % [CASES.size(), ROUNDS, MEASURE_FRAMES, control_ok])
	quit(0 if control_ok else 1)
