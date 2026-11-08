extends SceneTree
## A6 film capture driver (Claude Code, 2026-11-08). Lives in the film folder; run_captures.sh copies it into
## the disposable run copy (run-copy-8004dea/godot/capture/) only. It never touches the repository.
## Pattern: the A5 film's driver (one real main.tscn, keyboard events only) plus the routes of Kiran's
## committed state tests: the plate-edge scoot-off of tests/test_land_puff_state.gd (RUN_LEFT_TO_X 170,
## HOP_FROM_X 160) and the keyboard route of tests/test_dome_glints_state.gd (route_driver.gd's jump marks and
## its read-only plan()).
## Drives the game ONLY with InputEventKey through Input.parse_input_event (A, D, Space, Esc, Enter). Reads game
## state to decide when to press. Never moves the jelly, never touches the forks, the effects driver, any
## particle node, emitting, restart(), visible or get_tree().paused.
## One disclosed setting, as in the A2 and A5 films: game.test_mode = true (its only effect: no
## pause-on-focus-loss, so a window losing focus while recording cannot pause play).
## Route: intro pan untouched (dome and glints on screen from load) -> solo hop on plate 1 -> back up, run, hop
## to plate 1's right edge, keep D held: the scoot-off drop to the table (the quick repeat) -> hop back onto
## plate 1 -> route to the last plate's jump mark -> Esc pause 120 ticks with the dome on screen -> Esc ->
## off the last plate into the dome (WON) -> wait until the replay prompt + 60 ticks -> Enter (replay) -> 120 ticks.
## Logs one JSON line per tick AFTER that tick's physics (process_frame), plus events. Exit 0 only if the route
## completed and every tick had LandPuff spawns == SFX-LAND count.
## Env: CAPTURE_LOG (JSONL path, required).

const MAIN := preload("res://game/main.tscn")
const Game = preload("res://game/session.gd")
const Route = preload("res://tests/route_driver.gd")
const PUFF_SCENE := "res://effects/land_puff.tscn"
const GLINTS_SCENE := "res://effects/dome_glints.tscn"
const RUN_LEFT_TO_X := 170.0    # from test_land_puff_state.gd line 14
const HOP_FROM_X := 160.0       # from test_land_puff_state.gd line 15
const LIMIT_TICKS := 60 * 120
const KEYS := {"left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "esc": KEY_ESCAPE, "enter": KEY_ENTER}

var game: Node2D
var route
var log_file: FileAccess
var tick := 0                   # physics ticks since start (incremented in physics_frame, before the tick runs)
var pframe := -1                # process frames seen (0 = first), logged per tick
var down := {"left": false, "right": false, "jump": false, "esc": false, "enter": false}
var release_at := {}
var phase := "intro"
var phase_tick := 0
var puffs: Array = []           # {node, spawn_tick}
var glints: GPUParticles2D
var a1_bad := 0
var lands_at_phase := 0
var hop_at := -1
var scoot := {}
var won_tick := -1
var prompt_tick := -1
var replay_tick := -1
var pause_tick := -1
var paused_once := false

func _initialize() -> void:
	var path := OS.get_environment("CAPTURE_LOG")
	if path == "":
		push_error("CAPTURE_LOG not set")
		quit(1)
		return
	log_file = FileAccess.open(path, FileAccess.WRITE)
	node_added.connect(_on_node_added)
	route = Route.new()
	game = MAIN.instantiate()
	game.test_mode = true       # disclosed above
	root.add_child(game)
	physics_frame.connect(_on_physics_frame)
	process_frame.connect(_on_process_frame)
	_log({"event": "start", "engine": Engine.get_version_info().string,
		"rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"physics_ticks_per_second": Engine.physics_ticks_per_second})

func _on_node_added(node: Node) -> void:
	if node is GPUParticles2D and node.scene_file_path == PUFF_SCENE:
		puffs.append({"node": node, "spawn_tick": tick})
	elif node is GPUParticles2D and node.scene_file_path == GLINTS_SCENE:
		glints = node

func _log(entry: Dictionary) -> void:
	entry["tick"] = tick
	log_file.store_line(JSON.stringify(entry))
	log_file.flush()

func _key(name: String, pressed: bool) -> void:
	if down[name] == pressed:
		return
	down[name] = pressed
	var ev := InputEventKey.new()
	ev.keycode = KEYS[name]
	ev.physical_keycode = KEYS[name]
	ev.pressed = pressed
	Input.parse_input_event(ev)
	_log({"event": "key_down" if pressed else "key_up", "key": OS.get_keycode_string(KEYS[name])})

func _tap(name: String, hold: int) -> void:
	_key(name, true)
	release_at[name] = tick + hold

func _alive() -> int:
	var n := 0
	for p in puffs:
		if is_instance_valid(p.node) and p.node.is_inside_tree():
			n += 1
	return n

func _lands() -> int:
	return game.sound.count("SFX-LAND")

func _goto(p: String) -> void:
	phase = p
	phase_tick = 0
	lands_at_phase = _lands()
	_log({"event": "phase", "phase": p})

func _on_physics_frame() -> void:
	tick += 1
	phase_tick += 1
	for name in release_at.keys():
		if tick >= release_at[name]:
			_key(name, false)
			release_at.erase(name)
	_drive()

func _on_process_frame() -> void:
	pframe += 1
	var p: CharacterBody2D = game.player
	var ps: Vector2 = p.get_global_transform_with_canvas().origin
	var g := {}
	if is_instance_valid(glints):
		var gs: Vector2 = glints.get_global_transform_with_canvas().origin
		g = {"emitting": glints.emitting, "sx": snappedf(gs.x, 0.1), "sy": snappedf(gs.y, 0.1), "visible": glints.visible}
	var spawned := 0
	for q in puffs:
		spawned += 1
	if spawned != _lands():
		a1_bad += 1
	var new_puffs := []
	for q in puffs:
		if q.spawn_tick == tick and is_instance_valid(q.node):
			var s: Vector2 = q.node.get_global_transform_with_canvas().origin
			new_puffs.append({"x": snappedf(q.node.global_position.x, 0.1), "y": snappedf(q.node.global_position.y, 0.1),
				"sx": snappedf(s.x, 0.1), "sy": snappedf(s.y, 0.1)})
	_log({"event": "tick", "pframe": pframe, "phase": phase, "state": Game.State.keys()[game.state],
		"x": snappedf(p.position.x, 0.1), "y": snappedf(p.position.y, 0.1), "sx": snappedf(ps.x, 0.1), "sy": snappedf(ps.y, 0.1),
		"floor": p.is_on_floor(), "just_landed": p.just_landed, "pose": p.pose, "lands": _lands(), "puffs_spawned": spawned,
		"puffs_alive": _alive(), "new_puffs": new_puffs, "glints": g, "splats": game.splats, "prompt": game.prompt_shown})

func _plate_mark_reached() -> bool:
	var p: CharacterBody2D = game.player
	return route.next_jump < route.jump_marks.size() and p.is_on_floor() and p.position.x >= route.jump_marks[route.next_jump]

func _drive() -> void:
	var p: CharacterBody2D = game.player
	match phase:
		"intro":
			# The pan plays untouched; INTRO -> PLAYING when it ends (session.gd).
			if game.state == Game.State.PLAYING:
				_goto("solo_wait")
		"solo_wait":
			if phase_tick >= 30:
				_tap("jump", 4)
				_goto("solo")
		"solo":
			if _lands() > lands_at_phase and phase_tick > 5:
				_goto("solo_after")
			elif phase_tick > 120:
				_end(false, "no landing after the solo hop")
		"solo_after":
			if phase_tick >= 45:
				_key("left", true)
				_goto("backup")
		"backup":
			if p.position.x <= RUN_LEFT_TO_X or phase_tick > 120:
				_key("left", false)
				_goto("backup_settle")
		"backup_settle":
			if phase_tick >= 20:
				_key("right", true)
				_goto("run")
		"run":
			if p.position.x >= HOP_FROM_X:
				_tap("jump", 1)
				scoot["hop_x"] = p.position.x
				_goto("scoot")
			elif phase_tick > 120:
				_end(false, "run-up never reached HOP_FROM_X")
		"scoot":
			var got := _lands() - lands_at_phase
			if got >= 1 and not scoot.has("first"):
				scoot["first"] = tick - 1   # logged: a landing seen at physics_frame belongs to the previous tick
			if got >= 2:
				scoot["second"] = tick - 1
				_key("right", false)
				_log({"event": "scoot", "first": scoot.first, "second": scoot.second, "gap": scoot.second - scoot.first, "hop_x": scoot.hop_x})
				_goto("scoot_after")
			elif phase_tick > 140:
				_key("right", false)
				_end(false, "scoot-off route did not give two landings: %s" % str(scoot))
		"scoot_after":
			if phase_tick >= 60:
				_key("left", true)
				_tap("jump", 4)
				_goto("back_to_plate1")
		"back_to_plate1":
			if _lands() > lands_at_phase and phase_tick > 5:
				_key("left", false)
				if game.plate_under(p.position.x) != 0:
					_end(false, "hop back did not land on plate 1 (x=%.1f)" % p.position.x)
					return
				_goto("route_settle")
			elif phase_tick > 120:
				_end(false, "hop back never landed")
		"route_settle":
			if phase_tick >= 30:
				_goto("route")
		"route":
			_route_step()
		"esc_pause":
			if phase_tick == 2:
				_tap("esc", 2)
			elif phase_tick == 4:
				pause_tick = tick
				if game.state != Game.State.PAUSED:
					_end(false, "Esc did not pause")
			elif phase_tick == 124:
				_tap("esc", 2)
			elif phase_tick == 140:
				if game.state != Game.State.PLAYING:
					_end(false, "Esc did not resume")
					return
				_goto("route")
		"won":
			if game.prompt_shown and prompt_tick < 0:
				prompt_tick = tick
			if prompt_tick > 0 and tick >= prompt_tick + 60 and tick >= won_tick + 150:
				_tap("enter", 3)
				_goto("replay")
		"replay":
			if game.state == Game.State.PLAYING and replay_tick < 0:
				replay_tick = tick - 1
				_log({"event": "replay", "glints_emitting": glints.emitting})
			if replay_tick > 0 and tick >= replay_tick + 120:
				var ok: bool = a1_bad == 0 and scoot.has("second") and won_tick > 0 and paused_once
				_end(ok, "route complete: scoot gap=%d ticks, pause at %d, WON at %d, replay at %d, puff/SFX-LAND mismatched ticks=%d, splats=%d"
					% [scoot.second - scoot.first, pause_tick, won_tick, replay_tick, a1_bad, game.splats])
			elif phase_tick > 240:
				_end(false, "replay did not start")
	if tick >= LIMIT_TICKS:
		_end(false, "time limit")

func _route_step() -> void:
	## test_dome_glints_state.gd keyboard_route(): hold D to the next jump mark, stop, hop at plan()'s tick.
	var p: CharacterBody2D = game.player
	if game.state == Game.State.WON:
		_key("right", false)
		won_tick = tick - 1
		_log({"event": "won"})
		_goto("won")
		return
	if game.state != Game.State.PLAYING:
		_key("right", false)
		hop_at = -1
		return
	var last: int = route.jump_marks.size() - 1
	var want_d := true
	if _plate_mark_reached():
		want_d = false
		if route.next_jump == last and not paused_once:
			# Standing at the last plate's mark, keys up: the Esc pause, with the dome on screen.
			_key("right", false)
			paused_once = true
			_goto("esc_pause")
			return
		if hop_at < 0:
			hop_at = tick + route.plan(game.forks, route.next_jump)
			_log({"event": "plan", "plate": route.next_jump + 1, "hop_in_ticks": hop_at - tick})
		if tick >= hop_at:
			want_d = true
			_tap("jump", 1)
			route.next_jump += 1
			hop_at = -1
	_key("right", want_d)

func _end(ok: bool, note: String) -> void:
	if not physics_frame.is_connected(_on_physics_frame):
		return
	physics_frame.disconnect(_on_physics_frame)
	process_frame.disconnect(_on_process_frame)
	for k in down.keys():
		_key(k, false)
	_log({"event": "end", "ok": ok, "note": note, "lands": _lands(), "puffs": puffs.size(), "splats": game.splats})
	log_file.close()
	print("CAPTURE %s: %s" % ["OK" if ok else "FAILED", note])
	quit(0 if ok else 1)
