extends SceneTree
## Validation pass for cost_effects.gd's effect_a_lifecycle case, run separately so no counting
## code is inside the timed benchmark. Written by Claude in chat (not Claude Code); run by Kiran.
## It repeats that case's setup and schedule: main.tscn in PLAYING via a real Enter key event, the
## effects driver and its DomeGlints removed right after loading; a spawn becomes due at tick 0 and
## tick 10 of every 24-tick cycle, and a due spawn waits until fewer than two puffs are live
## (finished not yet fired). Each spawn follows effects_driver.gd's order (add to the session, set
## global_position, connect finished to queue_free, set emitting). After each frame's spawns it
## counts LandPuff nodes in the session: all in the tree, and those not yet queued for deletion.
## It changes no game, effect or shader file.
const DRIVER := preload("res://effects/effects_driver.gd")
const LAND_PUFF := preload("res://effects/land_puff.tscn")
const PUFF_PATH := "res://effects/land_puff.tscn"
const LIFE := 24
const GAP := 10
const MAX_LIVE := 2
const WARMUP := 60
const FRAMES := 300
var game: Node2D
var start := 0
var last_tick := 0
var pending := 0
var live := 0
var counting := false
var created := 0
var freed := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://game/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	var driver: Node = null
	for child in game.get_children():
		if child.get_script() == DRIVER:
			driver = child
	var glints: GPUParticles2D = driver.glints
	game.remove_child(driver)
	driver.free()
	glints.free()
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_ENTER
		ev.physical_keycode = KEY_ENTER
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await process_frame
	print("PEAK state after Enter: ", game.state)
	start = Engine.get_physics_frames()
	last_tick = start - 1
	var hist_all := {}
	var hist_live := {}
	var peak_all := 0
	var peak_live := 0
	for i in range(WARMUP + FRAMES):
		await process_frame
		var now := Engine.get_physics_frames()
		for k in range(last_tick + 1, now + 1):
			var t := (k - start) % LIFE
			if t == 0 or t == GAP:
				pending += 1
		last_tick = now
		while pending > 0 and live < MAX_LIVE:
			spawn()
			pending -= 1
		if i == WARMUP:
			counting = true
		if counting:
			var n_all := 0
			var n_live := 0
			for child in game.get_children():
				if child.scene_file_path == PUFF_PATH:
					n_all += 1
					if not child.is_queued_for_deletion():
						n_live += 1
			hist_all[n_all] = hist_all.get(n_all, 0) + 1
			hist_live[n_live] = hist_live.get(n_live, 0) + 1
			peak_all = maxi(peak_all, n_all)
			peak_live = maxi(peak_live, n_live)
	print("PEAK counted frames: ", FRAMES, " after ", WARMUP, " warm-up frames")
	print("PEAK puffs in the tree (including queued for deletion): ", peak_all, " | frames per count: ", hist_all)
	print("PEAK puffs not queued for deletion: ", peak_live, " | frames per count: ", hist_live)
	print("PEAK created during counted frames: ", created, " | left the tree during counted frames: ", freed)
	print("PEAK spawns still waiting at the end: ", pending)
	print("PEAK state at end: ", game.state)
	quit(0)

func spawn() -> void:
	var puff: GPUParticles2D = LAND_PUFF.instantiate()
	game.add_child(puff)
	puff.global_position = game.player.global_position
	puff.finished.connect(puff.queue_free)
	puff.emitting = true
	live += 1
	puff.finished.connect(func() -> void: live -= 1)
	if counting:
		created += 1
	puff.tree_exited.connect(func() -> void:
		if counting:
			freed += 1)
