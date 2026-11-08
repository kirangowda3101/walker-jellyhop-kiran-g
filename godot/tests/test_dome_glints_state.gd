extends SceneTree
## Effect B state checks (CHANGE-BRIEF.md, Effect B, rules B1-B7), plus Effect A's pending A2 WON case.
## Loads the real main.tscn and drives it only with synthetic key events through Godot Input (not human
## playtesting). Two full runs to the dome and two replays come from key presses alone: the route reuses
## route_driver.gd's jump marks and its read-only plan() over the forks' fixed rhythms, and turns each
## decision into D and Space key events (it never sets test_control). The test never calls the effects
## driver, restart() or emitting; the only things it sets are get_tree().paused (B5) and the emitter's
## visible (B6), as the brief says. Headless, the renderer is a dummy, so only node state is observed
## (instances, identity, position, emitting, visible, can_process), never glints.
const Game = preload("res://game/session.gd")
const T = preload("res://game/slice_tuning.gd")
const Route = preload("res://tests/route_driver.gd")
const GLINTS_SCENE := "res://effects/dome_glints.tscn"
const PUFF_SCENE := "res://effects/land_puff.tscn"
var game: Node2D
var results: Array[Dictionary] = []
var failures := 0
var glints_seen: Array = []      # every DomeGlints added to the tree
var puff_frames: Array = []      # physics frame each LandPuff was added
var first_glints: GPUParticles2D # the instance that exists at load
var ticks_log: Array[Dictionary] = []  # one snapshot after every physics tick

func _initialize() -> void:
	node_added.connect(_on_node_added)
	call_deferred("run")

func _on_node_added(node: Node) -> void:
	if node is GPUParticles2D and node.scene_file_path == GLINTS_SCENE:
		glints_seen.append(node)
	elif node is GPUParticles2D and node.scene_file_path == PUFF_SCENE:
		puff_frames.append(Engine.get_physics_frames())

func dome_point() -> Vector2:
	return Vector2(T.dome_left() + T.dome_width() / 2.0, T.TABLE_TOP - 70.0)

func glints() -> GPUParticles2D:
	return glints_seen.back() if not glints_seen.is_empty() else null

func snapshot() -> Dictionary:
	var g := glints()
	return {"frame": Engine.get_physics_frames(), "state": Game.State.keys()[game.state],
		"emitting": g.emitting if is_instance_valid(g) else null,
		"same": is_same(g, first_glints), "instances": glints_seen.size(), "in_tree": is_instance_valid(g) and g.is_inside_tree(),
		"amount": g.amount if is_instance_valid(g) else -1, "amount_ratio": g.amount_ratio if is_instance_valid(g) else -1.0,
		"puffs": puff_frames.size(), "lands": game.sound.count("SFX-LAND"), "tree_paused": paused}

func tick(n: int = 1) -> void:
	## After both awaits the tick's physics has run (jelly 0, session 10, driver 20) and no _process yet.
	for i in range(n):
		await physics_frame
		await process_frame
		ticks_log.append(snapshot())

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code, true)
	await tick(2)
	key(code, false)
	await tick(1)

func check(id: String, passed: bool, observed: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observed})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

func state_name() -> String:
	return Game.State.keys()[game.state]

func keyboard_route() -> Dictionary:
	## route_driver.gd's decisions, as key events: hold D until the next jump mark, release; at the planned
	## tick press D and Space (Space released one tick later); after the last mark hold D into the dome.
	var route = Route.new()
	var d_held := false
	var hop_at := -1
	var ticks := 0
	var hops := []
	var splats_before: int = game.splats
	while game.state == Game.State.PLAYING and ticks < 1500:
		ticks += 1
		var p: CharacterBody2D = game.player
		var want_d := true
		var jump := false
		if route.next_jump < route.jump_marks.size() and p.is_on_floor() and p.position.x >= route.jump_marks[route.next_jump]:
			want_d = false
			if hop_at < 0:
				hop_at = ticks + route.plan(game.forks, route.next_jump)
			if ticks >= hop_at:
				want_d = true
				jump = true
				hops.append({"plate": route.next_jump + 1, "tick": ticks})
				route.next_jump += 1
				hop_at = -1
		if want_d != d_held:
			key(KEY_D, want_d)
			d_held = want_d
		if jump:
			key(KEY_SPACE, true)
		await tick()
		if jump:
			key(KEY_SPACE, false)
	if d_held:
		key(KEY_D, false)
	return {"state": state_name(), "ticks": ticks, "splats": game.splats - splats_before, "hops": hops, "position": str(game.player.position)}

func win_and_replay(run_no: int) -> void:
	var label := "run%d" % run_no
	var r := await keyboard_route()
	check("route-%s-reaches-WON-by-keys-no-splat" % label, r.state == "WON" and r.splats == 0, r)
	if r.state != "WON":
		return
	# B2: the tick the state became WON, against the tick before it.
	var entry: Dictionary = ticks_log.back()
	var before: Dictionary = ticks_log[ticks_log.size() - 2]
	check("B2-%s-stops-on-WON-tick-node-stays" % label, before.state != "WON" and before.emitting == true and entry.state == "WON" and entry.emitting == false and entry.in_tree and entry.same,
		{"tick_before": before, "won_tick": entry})
	check("A2-%s-no-puff-on-WON-entry-tick" % label, entry.puffs == before.puffs and entry.lands == before.lands and not game.player.just_landed,
		{"puffs_before": before.puffs, "puffs_on_won_tick": entry.puffs, "sfx_land_before": before.lands, "sfx_land_on_won_tick": entry.lands, "jelly_just_landed_on_won_tick": game.player.just_landed})
	# Keys while WON, before the prompt (the session ignores them): Space, then D held.
	var won_from := ticks_log.size() - 1
	await tick(10)
	await tap(KEY_SPACE)
	key(KEY_D, true)
	await tick(20)
	key(KEY_D, false)
	var keys_ignored: bool = game.state == Game.State.WON and not game.prompt_shown
	var waited := 0
	while not game.prompt_shown and waited < 120:
		await tick()
		waited += 1
	await tick(5)
	var stretch := ticks_log.slice(won_from)
	var bad := []
	for s in stretch:
		if s.state != "WON" or s.emitting != false or s.puffs != entry.puffs or s.lands != entry.lands or not s.in_tree or not s.same:
			bad.append(s)
	check("B2-%s-stays-off-node-stays-while-WON" % label, keys_ignored and bad.is_empty() and game.prompt_shown, {"won_ticks_checked": stretch.size(), "keys_before_prompt_ignored": keys_ignored, "bad_ticks": bad.slice(0, 5)})
	check("A2-%s-no-puff-any-WON-tick-with-keys" % label, bad.is_empty() and puff_frames.size() == entry.puffs, {"won_ticks_checked": stretch.size(), "puffs_at_entry": entry.puffs, "puffs_now": puff_frames.size(), "sfx_land_now": game.sound.count("SFX-LAND")})
	# B3 / B7: replay with a key; the same emitter object starts again.
	await tap(KEY_ENTER)
	var replay_tick := {}
	for i in range(ticks_log.size() - 1, -1, -1):
		if ticks_log[i].state == "WON":
			replay_tick = ticks_log[i + 1] if i + 1 < ticks_log.size() else {}
			break
	check("B3-%s-emitting-on-replay-tick" % label, not replay_tick.is_empty() and replay_tick.state == "PLAYING" and replay_tick.emitting == true and game.state == Game.State.PLAYING and glints().emitting,
		{"first_tick_after_WON": replay_tick, "state_now": state_name()})
	check("B7-%s-same-emitter-object-after-replay" % label, glints_seen.size() == 1 and is_same(glints(), first_glints) and first_glints.is_inside_tree(),
		{"instances_ever": glints_seen.size(), "same_object": is_same(glints(), first_glints), "first_id": first_glints.get_instance_id(), "now_id": glints().get_instance_id()})

func run() -> void:
	var main: Node2D = load("res://game/main.tscn").instantiate()
	main.test_mode = true
	root.add_child(main)
	game = main
	# ---- B1: before any tick, right after the session is ready.
	first_glints = glints()
	var g := first_glints
	var b1_ok: bool = glints_seen.size() == 1 and is_instance_valid(g) and g.is_inside_tree() and g.get_parent() == game and g.emitting and g.global_position.distance_to(dome_point()) <= 0.5 and game.state == Game.State.INTRO
	check("B1-on-from-load-one-instance-at-dome", b1_ok, {"instances": glints_seen.size(), "emitting": g.emitting if g else null, "position": str(g.global_position) if g else "", "expected": str(dome_point()), "parent_is_session": g.get_parent() == game if g else false, "state": state_name()})
	if not b1_ok:
		await finish()
		return
	await tick(60)
	var intro_ok := true
	for s in ticks_log:
		intro_ok = intro_ok and s.state == "INTRO" and s.emitting == true
	check("B1-on-through-intro", intro_ok and ticks_log.size() == 60, {"ticks": ticks_log.size(), "state": state_name(), "emitting": g.emitting})
	await tap(KEY_ENTER)
	await tick(10)
	check("setup-intro-skipped-on-plate-1", game.state == Game.State.PLAYING and game.plate_under(game.player.position.x) == 0, {"state": state_name(), "player": str(game.player.position)})

	# ---- B4: session pause (Esc), its own scenario.
	key(KEY_ESCAPE, true)
	await tick(1)
	key(KEY_ESCAPE, false)
	await tick(1)
	var esc_paused: bool = game.state == Game.State.PAUSED
	var esc_ok := true
	for i in range(60):
		await tick()
		esc_ok = esc_ok and game.state == Game.State.PAUSED and g.emitting and g.can_process() and not paused
	check("B4-esc-pause-keeps-emitting-and-running", esc_paused and esc_ok, {"state": state_name(), "emitting": g.emitting, "can_process": g.can_process(), "tree_paused": paused})
	await tap(KEY_ESCAPE)
	await tick(5)
	check("B4-esc-resume-still-emitting", game.state == Game.State.PLAYING and g.emitting, {"state": state_name(), "emitting": g.emitting})

	# ---- B5: tree pause, its own scenario.
	paused = true
	var tree_ok := true
	for i in range(60):
		await tick()
		tree_ok = tree_ok and g.emitting and not g.can_process() and g.is_inside_tree() and is_same(glints(), first_glints)
	var state_while: String = state_name()
	paused = false
	await tick(5)
	check("B5-tree-pause-emitting-stays-node-frozen", tree_ok and state_while == "PLAYING", {"emitting": g.emitting, "state_while_paused": state_while, "paused_ticks": 60})
	check("B5-tree-unpause-processes-again", g.emitting and g.can_process(), {"emitting": g.emitting, "can_process": g.can_process()})

	# ---- B6: hidden, its own scenario.
	g.visible = false
	var hidden_ok := true
	for i in range(60):
		await tick()
		hidden_ok = hidden_ok and g.emitting and not g.visible and not g.is_visible_in_tree() and game.state == Game.State.PLAYING
	check("B6-hidden-keeps-emitting-driver-leaves-visible", hidden_ok, {"emitting": g.emitting, "visible": g.visible, "state": state_name()})
	g.visible = true
	await tick(2)
	check("B6-shown-again-still-emitting", g.emitting and g.is_visible_in_tree(), {"emitting": g.emitting, "visible": g.visible})

	# ---- B2, B3, B7 and A2 WON: two real-key runs to the dome, each followed by a key replay.
	await win_and_replay(1)
	await win_and_replay(2)
	await finish()

func finish() -> void:
	# ---- Rules over every tick of the test.
	var mismatch := []
	var not_same := []
	var counts := []
	for s in ticks_log:
		if s.emitting != (s.state != "WON"):
			mismatch.append(s)
		if not s.same or s.instances != 1 or not s.in_tree:
			not_same.append(s)
		if s.amount != 24 or not is_equal_approx(s.amount_ratio, 1.0):
			counts.append(s)
	var won_ticks := 0
	var replays := 0
	for i in range(ticks_log.size()):
		if ticks_log[i].state == "WON":
			won_ticks += 1
		elif i > 0 and ticks_log[i - 1].state == "WON":
			replays += 1
	check("B1-B3-emitting-equals-not-WON-every-tick", mismatch.is_empty() and won_ticks > 0 and replays == 2, {"ticks": ticks_log.size(), "won_ticks": won_ticks, "replays": replays, "mismatch_ticks": mismatch.slice(0, 5)})
	check("B7-one-same-emitter-object-every-tick", not_same.is_empty() and glints_seen.size() == 1, {"instances_ever": glints_seen.size(), "bad_ticks": not_same.slice(0, 5)})
	check("B-amount-24-amount-ratio-1-unchanged", counts.is_empty(), {"bad_ticks": counts.slice(0, 5)})
	var lands := []
	for c in game.sound.calls:
		if c.id == "SFX-LAND":
			lands.append(c.frame)
	check("A2-puff-frames-equal-SFX-LAND-frames", puff_frames == lands and lands.size() > 0, {"puff_frames": puff_frames, "land_frames": lands})
	var report := {"scope": "Effect B state checks and A2 WON: real main.tscn, synthetic key events through Godot Input; not human playtesting. Headless: node state only, no glints drawn.",
		"engine": Engine.get_version_info().string, "created_at": Time.get_datetime_string_from_system(true),
		"results": results, "failures": failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/dome-glints-state-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("DOME GLINTS STATE TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	for i in range(30):
		await process_frame   # let the audio server release stopped playbacks before quitting
	quit(1 if failures else 0)
