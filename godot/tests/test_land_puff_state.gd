extends SceneTree
## Effect A state checks (CHANGE-BRIEF.md, Effect A, rules A1-A8). Loads the real main.tscn and
## drives it only with synthetic key events through Godot Input (not human playtesting). The test
## reads game state (the jelly's position, the session state, fork 2's rhythm, sound.calls) and never
## writes it; the one thing it sets is get_tree().paused, for A8. It never calls the effects driver:
## every puff here comes from a landing in the real game loop. Headless, the renderer is a dummy, so
## only node state is observed (instances, position, emitting, finished, parent), never crumbs.
## A2's WON case is pending: it is checked in Effect B's real-input run to the dome.
const Game = preload("res://game/session.gd")
const T = preload("res://game/slice_tuning.gd")
const PUFF_SCENE := "res://effects/land_puff.tscn"
const LIFETIME_TICKS := 24      # land_puff.tscn lifetime 0.40 s at 60 ticks/s
const BRIEF_GAP := Vector2i(9, 12)   # brief A4/A5: plate-edge scoot-off, 0.15-0.2 s
const RUN_LEFT_TO_X := 170.0    # route: back up on plate 1 for a run-up; stops ~18 px later, still on the plate (edge 135.5)
const HOP_FROM_X := 160.0       # route: a running hop from here lands at plate 1's right edge
var game: Node2D
var results: Array[Dictionary] = []
var failures := 0
var puffs: Array[Dictionary] = []      # one entry per LandPuff added to the tree
var a1_mismatches: Array[Dictionary] = []
var max_alive := 0

func _initialize() -> void:
	node_added.connect(_on_node_added)
	call_deferred("run")

func _on_node_added(node: Node) -> void:
	if not (node is GPUParticles2D and node.scene_file_path == PUFF_SCENE):
		return
	var entry := {"index": puffs.size(), "node": node, "added_frame": Engine.get_physics_frames(), "seen": false, "finished_frame": -1, "exited_frame": -1}
	puffs.append(entry)
	node.finished.connect(func() -> void: entry.finished_frame = Engine.get_physics_frames())
	node.tree_exiting.connect(func() -> void: entry.exited_frame = Engine.get_physics_frames())

func alive() -> Array:
	var out := []
	for e in puffs:
		if is_instance_valid(e.node) and e.node.is_inside_tree():
			out.append(e.index)
	return out

func land_frames() -> Array:
	var out := []
	for c in game.sound.calls:
		if c.id == "SFX-LAND":
			out.append(c.frame)
	return out

func scan() -> void:
	## After each tick: the driver (priority 20) has run after the session (10) and the jelly (0),
	## and no node has had its _process yet, so a puff spawned this tick shows the driver's values.
	var frame := Engine.get_physics_frames()
	for e in puffs:
		if e.seen:
			continue
		e.seen = true
		e.spawn_frame = frame
		e.position = e.node.global_position
		e.player_position = game.player.global_position
		e.emitting = e.node.emitting
		e.state = Game.State.keys()[game.state]
		e.parent_is_session = e.node.get_parent() == game
		e.parent_is_player = e.node.get_parent() == game.player
		e.alive_at_spawn = alive()
	var spawned := []
	for e in puffs:
		spawned.append(e.spawn_frame)
	var lands := land_frames()
	if spawned != lands:
		a1_mismatches.append({"frame": frame, "puff_frames": spawned, "land_frames": lands})
	max_alive = maxi(max_alive, alive().size())

func tick(n: int = 1) -> void:
	for i in range(n):
		await physics_frame
		await process_frame
		scan()

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

func wait_for_puff(max_ticks: int) -> Dictionary:
	var n := puffs.size()
	for i in range(max_ticks):
		await tick()
		if puffs.size() > n:
			return puffs[n]
	return {}

func wait_fork_harmless(fork, span: int) -> void:
	## Read only: wait until plate 2's fork stays raised for the next `span` ticks.
	for i in range(600):
		var ok := true
		for k in range(span + 1):
			ok = ok and fork.harmless_in(k)
		if ok:
			return
		await tick()

func check(id: String, passed: bool, observed: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observed})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

func delay(e: Dictionary) -> int:
	return e.finished_frame - e.spawn_frame if e.finished_frame >= 0 else -1

func summary(e: Dictionary) -> Dictionary:
	if e.is_empty():
		return {}
	return {"index": e.index, "spawn_frame": e.spawn_frame, "position": str(e.position), "player_position": str(e.player_position), "emitting_at_spawn": e.emitting, "state": e.state, "finished_frame": e.finished_frame, "finished_after_ticks": delay(e), "exited_frame": e.exited_frame, "alive_at_spawn": e.alive_at_spawn}

func run() -> void:
	var main: Node2D = load("res://game/main.tscn").instantiate()
	main.test_mode = true
	root.add_child(main)
	game = main
	# ---- A2: scene load and intro (60 ticks of the pan), then the intro skip (a respawn).
	await tick(60)
	check("A2-none-on-load-and-intro", game.state == Game.State.INTRO and puffs.is_empty(), {"state": Game.State.keys()[game.state], "puffs": puffs.size()})
	await tap(KEY_ENTER)
	await tick(10)
	check("A2-none-on-intro-skip-respawn", game.state == Game.State.PLAYING and puffs.is_empty(), {"state": Game.State.keys()[game.state], "puffs": puffs.size(), "player": str(game.player.global_position)})

	# ---- Solo hop on plate 1 (no fork): the baseline for when a lone puff's finished fires.
	await tap(KEY_SPACE)
	var solo := await wait_for_puff(80)
	if solo.is_empty():
		check("A1-solo-hop-puff", false, {"reason": "no puff within 80 ticks of a hop"})
		await finish()
		return
	await tick(LIFETIME_TICKS * 2 + 12)
	check("A1-solo-hop-puff", puffs.size() == 1 and game.sound.count("SFX-LAND") == 1, summary(solo))
	check("A6-solo-finished-and-freed", solo.finished_frame >= 0 and solo.exited_frame >= 0 and alive().is_empty(), summary(solo))

	# ---- A4: two landings inside one lifetime. Back up, run right, hop so the jelly lands at the
	# plate's right edge still running, and keep D held so it scoots off and drops 22 px to the table.
	key(KEY_A, true)
	for i in range(120):
		if game.player.global_position.x <= RUN_LEFT_TO_X:
			break
		await tick()
	key(KEY_A, false)
	await tick(20)
	var run_from_x: float = game.player.global_position.x
	key(KEY_D, true)
	for i in range(120):
		if game.player.global_position.x >= HOP_FROM_X:
			break
		await tick()
	var hop_x: float = game.player.global_position.x
	key(KEY_SPACE, true)
	await tick(1)
	key(KEY_SPACE, false)
	var first := await wait_for_puff(80)
	var second := await wait_for_puff(LIFETIME_TICKS) if not first.is_empty() else {}
	key(KEY_D, false)
	if first.is_empty() or second.is_empty():
		check("A4-two-landings-in-one-lifetime", false, {"reason": "route did not give two landings", "hop_x": hop_x, "first": summary(first), "second": summary(second)})
		await finish()
		return
	var gap: int = second.spawn_frame - first.spawn_frame
	var on_plate: bool = absf(first.position.y - T.plate_landing_y()) < 1.0
	var on_table: bool = absf(second.position.y - T.TABLE_TOP) < 1.0
	check("A4-route-plate-then-table", on_plate and on_table, {"run_from_x": run_from_x, "hop_x": hop_x,"first_y": first.position.y, "plate_landing_y": T.plate_landing_y(), "second_y": second.position.y, "table_top": T.TABLE_TOP})
	check("A4-gap-inside-one-lifetime", gap > 0 and gap < LIFETIME_TICKS, {"gap_ticks": gap, "lifetime_ticks": LIFETIME_TICKS})
	check("A4-gap-in-brief-range-9-12", gap >= BRIEF_GAP.x and gap <= BRIEF_GAP.y, {"gap_ticks": gap, "gap_s": gap / 60.0, "brief_ticks": str(BRIEF_GAP)})
	check("A4-two-separate-instances", first.node != second.node and first.parent_is_session and second.parent_is_session, {"first": first.index, "second": second.index})
	check("A4-first-alive-when-second-spawns", first.index in second.alive_at_spawn, {"alive_at_second_spawn": second.alive_at_spawn, "first_finished_frame": first.finished_frame, "second_spawn_frame": second.spawn_frame})
	check("A4-second-emitting-at-spawn", second.emitting, summary(second))
	# ---- A6: one second after the last landing.
	await tick(maxi(0, second.spawn_frame + 60 - Engine.get_physics_frames()))
	check("A4-first-not-restarted", delay(first) >= 0 and delay(first) == delay(solo), {"first_finished_after": delay(first), "solo_finished_after": delay(solo), "gap_ticks": gap})
	check("A4-second-finishes-on-own-schedule", delay(second) >= 0 and delay(second) == delay(solo), {"second_finished_after": delay(second), "solo_finished_after": delay(solo)})
	check("A6-none-left-1s-after-last-landing", alive().is_empty() and first.exited_frame >= 0 and second.exited_frame >= 0, {"alive": alive(), "frames_after_last_landing": Engine.get_physics_frames() - second.spawn_frame, "first": summary(first), "second": summary(second)})

	# ---- A2: a real sauce splat. Hop onto plate 2 when its fork stays raised, keep D held, run off
	# its right edge into the sauce in gap 2; then SPLAT, REFORM and the respawn on plate 2.
	await wait_fork_harmless(game.forks[1], 150)
	key(KEY_D, true)
	await tap(KEY_SPACE)
	var before_splat := puffs.size()
	var splat_frame := -1
	var landing_on_splat_tick := false
	for i in range(150):
		await tick()
		if game.state != Game.State.PLAYING:
			splat_frame = Engine.get_physics_frames()
			landing_on_splat_tick = game.player.just_landed
			break
	key(KEY_D, false)
	var at_splat := puffs.size()
	var states := {}
	for i in range(T.ticks(T.SPLAT_TIME) + T.ticks(T.REFORM_TIME) + 20):
		await tick()
		states[Game.State.keys()[game.state]] = true
	var plate2_landings := at_splat - before_splat
	check("A2-none-on-sauce-splat-splat-reform-respawn", game.splat_cause == "sauce" and puffs.size() == at_splat and states.has("SPLAT") and states.has("REFORM") and game.state == Game.State.PLAYING,
		{"splat_cause": game.splat_cause, "splat_frame": splat_frame, "jelly_just_landed_on_splat_tick": landing_on_splat_tick, "plate2_landings_before_splat": plate2_landings, "puffs_at_splat": at_splat, "puffs_after_respawn": puffs.size(), "states_seen": states.keys(), "respawn_at": str(game.player.global_position)})

	# ---- A8 / A2: session pause (Esc), started only after a puff has spawned.
	await tick(10)
	await tap(KEY_SPACE)
	var p := await wait_for_puff(80)
	if p.is_empty():
		check("A8-esc-puff-spawned", false, {"reason": "no puff within 80 ticks of a hop on plate 2"})
		await finish()
		return
	key(KEY_ESCAPE, true)
	await tick(1)
	key(KEY_ESCAPE, false)
	await tick(1)
	var paused_ok: bool = game.state == Game.State.PAUSED
	var p_alive_when_paused: bool = p.index in alive()
	var during := puffs.size()
	key(KEY_D, true)
	for i in range(4):
		await tap(KEY_SPACE)
		await tick(8)
	key(KEY_D, false)
	await tick(LIFETIME_TICKS * 2)
	check("A8-esc-live-puff-finishes", paused_ok and p_alive_when_paused and delay(p) == delay(solo) and p.exited_frame >= 0, {"state_after_esc": Game.State.keys()[game.state], "alive_when_paused": p_alive_when_paused, "finished_after": delay(p), "solo_finished_after": delay(solo), "puff": summary(p)})
	check("A2-none-while-paused", game.state == Game.State.PAUSED and puffs.size() == during, {"puffs_before": during, "puffs_after": puffs.size(), "state": Game.State.keys()[game.state]})
	await tap(KEY_ESCAPE)
	await tick(5)
	check("A8-esc-resumes", game.state == Game.State.PLAYING, {"state": Game.State.keys()[game.state]})

	# ---- A8: tree pause, a separate scenario, started only after a puff has spawned.
	await wait_fork_harmless(game.forks[1], 80)
	await tap(KEY_SPACE)
	var q := await wait_for_puff(80)
	if q.is_empty():
		check("A8-tree-pause-puff-spawned", false, {"reason": "no puff within 80 ticks of a hop on plate 2"})
		await finish()
		return
	var emitting_before: bool = q.node.emitting
	paused = true
	var paused_frame := Engine.get_physics_frames()
	await tick(60)
	var frozen: bool = q.index in alive() and q.node.emitting == emitting_before and q.finished_frame < 0
	check("A8-tree-pause-freezes", frozen, {"paused_ticks": Engine.get_physics_frames() - paused_frame, "in_tree": q.index in alive(), "emitting_before": emitting_before, "emitting_now": q.node.emitting if is_instance_valid(q.node) else null, "finished_frame": q.finished_frame})
	paused = false
	await tick(60)
	check("A8-tree-unpause-finishes", q.finished_frame >= 0 and q.exited_frame >= 0 and delay(q) - 60 == delay(solo), {"finished_after": delay(q), "minus_paused_60": delay(q) - 60, "solo_finished_after": delay(solo), "puff": summary(q)})
	await finish()

func finish() -> void:
	# ---- Rules over every puff of the run.
	var lands := land_frames()
	var spawned := []
	var all_playing := true
	var all_emitting := true
	var all_session := true
	var worst := 0.0
	for e in puffs:
		spawned.append(e.get("spawn_frame", -1))
		all_playing = all_playing and e.get("state") == "PLAYING"
		all_emitting = all_emitting and e.get("emitting", false)
		all_session = all_session and e.get("parent_is_session", false) and not e.get("parent_is_player", true)
		worst = maxf(worst, (e.position - e.player_position).length() if e.has("position") else INF)
	check("A1-one-puff-per-SFX-LAND-every-tick", a1_mismatches.is_empty() and spawned == lands and puffs.size() >= 5, {"puffs": puffs.size(), "sfx_land": game.sound.count("SFX-LAND"), "puff_frames": spawned, "land_frames": lands, "mismatch_ticks": a1_mismatches.slice(0, 5)})
	check("A1-A2-spawned-only-while-playing-and-emitting", all_playing and all_emitting, {"puffs": puffs.size()})
	check("A3-at-the-jelly-feet", worst <= 0.5, {"max_distance_px": worst})
	check("A7-parent-is-session-never-jelly", all_session, {"puffs": puffs.size()})
	check("A6-none-left-at-end", alive().is_empty(), {"alive": alive()})
	var report := {"scope": "Effect A state checks: real main.tscn, synthetic key events through Godot Input; not human playtesting. Headless: node state only, no crumbs drawn.",
		"engine": Engine.get_version_info().string, "created_at": Time.get_datetime_string_from_system(true),
		"pending": ["A2 WON: checked in Effect B's real-input run to the dome"],
		"observed": {"max_puffs_alive": max_alive, "puffs": puffs.map(summary)},
		"results": results, "failures": failures}
	print(JSON.stringify({"observed": report.observed, "pending": report.pending}))
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/land-puff-state-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("LAND PUFF STATE TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	for i in range(30):
		await process_frame   # let the audio server release stopped playbacks before quitting
	quit(1 if failures else 0)
