extends SceneTree
## Film capture driver for the Jelly Hop explainer (godot-gamedev capture contract).
## Runs the real main scene and drives it ONLY with keyboard events (Right arrow, Space) sent
## through Input.parse_input_event, the same path a physical keyboard uses, so the game's own
## InputMap actions and _unhandled_input see them. It reads game state (positions, fork phases)
## to choose WHEN to press, using the read-only planner in tests/route_driver.gd. It never moves
## the jelly, never edits forks, timers or collisions, and never uses the player's test controls
## (player.test_control stays false).
## One disclosed setting: game.test_mode = true. Its only effect in session.gd is to stop
## pause-on-focus-loss (_on_focus_lost), so a window losing focus while recording can't pause play.
## Route: intro pan plays untouched -> hop plate 1 -> 2 -> stay on plate 2 until its fork strikes
## (deliberate fork splat) -> respawn -> safe hops to plate 6 -> walk into the dome -> 2.5 s hold.
## Sauce route (CAPTURE_ROUTE=sauce): Space skips the intro pan (the game's own "any key skips"
## rule) -> hop plate 1 -> 2 -> walk off plate 2's right edge with no hop, into the spilled sauce in
## gap 2 (a missed landing) -> re-form on plate 2 -> 1 s of control, then stop.
## Env: CAPTURE_LOG (JSONL path, required), CAPTURE_PILOT=1 (stop 1 s after the first landing),
## CAPTURE_ROUTE=main|sauce (default main).
## Exit 0 only if the asserted outcome happened; otherwise exit 1.

const MAIN := preload("res://game/main.tscn")
const Game = preload("res://game/session.gd")
const Route = preload("res://tests/route_driver.gd")
const SPLAT_PLATE := 1          # plate index 1 = plate 2 (the first plate with a fork)
const LIMIT_TICKS := 60 * 90    # safety stop: 90 s of game time
const JUMP_HOLD_TICKS := 4      # Space is held this long per hop (one press per hop)
const KEYS := {"right": KEY_RIGHT, "jump": KEY_SPACE}

var game: Node2D
var route                       # read-only planner (jump marks + fork-timing search)
var log_file: FileAccess
var tick := 0
var pilot := false
var route_mode := "main"
var skip_sent := false
var walked_off := false
var hop_at := -1
var splat_done := false
var down := {"right": false, "jump": false}
var jump_release_at := -1
var hopping := false            # Space pressed for a hop; waiting for the jelly to leave the plate
var hop_pressed_tick := -1
var left_last_plate := false
var playing_ticks := 0
var last_state := -1
var last_pose := ""
var sounds_logged := 0
var first_land_tick := -1
var won_tick := -1

func _initialize() -> void:
	pilot = OS.get_environment("CAPTURE_PILOT") == "1"
	if OS.get_environment("CAPTURE_ROUTE") == "sauce":
		route_mode = "sauce"
	var path := OS.get_environment("CAPTURE_LOG")
	if path == "":
		push_error("CAPTURE_LOG not set")
		quit(1)
		return
	log_file = FileAccess.open(path, FileAccess.WRITE)
	route = Route.new()
	game = MAIN.instantiate()
	game.test_mode = true       # disclosed above: only disables pause-on-focus-loss
	root.add_child(game)
	physics_frame.connect(_on_physics_frame)
	_log({"event": "start", "route": route_mode, "pilot": pilot, "engine": Engine.get_version_info().string,
		"physics_ticks_per_second": Engine.physics_ticks_per_second})

func _log(entry: Dictionary) -> void:
	entry["tick"] = tick
	entry["physics_frame"] = Engine.get_physics_frames()
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

func _on_physics_frame() -> void:
	tick += 1
	if down["jump"] and tick >= jump_release_at:
		_key("jump", false)
	_observe()
	if route_mode == "sauce" and game.state == Game.State.INTRO and tick == 60 and not skip_sent:
		skip_sent = true
		_key("jump", true)          # any key skips the intro; the game ignores it as a hop
		jump_release_at = tick + JUMP_HOLD_TICKS
	if game.state == Game.State.PLAYING:
		playing_ticks += 1
		# The game ignores a direction already held when control returns (require_axis_release),
		# so, like a player, keep the keys up for the first ticks of control and then press.
		if playing_ticks > 2:
			_drive()
	else:
		playing_ticks = 0
		hopping = false
		hop_at = -1
		_key("right", false)
	_finish_if_done()

func _observe() -> void:
	if game.state != last_state:
		last_state = game.state
		_log({"event": "state", "state": Game.State.keys()[game.state]})
	if game.player.pose != last_pose:
		last_pose = game.player.pose
		_log({"event": "pose", "pose": last_pose, "x": snappedf(game.player.position.x, 0.1)})
	while sounds_logged < game.sound.calls.size():
		var c: Dictionary = game.sound.calls[sounds_logged]
		_log({"event": "sound", "id": c.id, "sound_frame": c.frame, "game_state": c.state})
		if c.id == "SFX-LAND" and first_land_tick < 0:
			first_land_tick = tick
		sounds_logged += 1
	if game.splats > 0 and not splat_done:
		splat_done = true
		_log({"event": "splat", "cause": game.splat_cause, "checkpoint": game.checkpoint})

func _plate_index() -> int:
	var x: float = game.player.position.x
	var best := 0
	for i in route.jump_marks.size():
		if x >= game.plates[i].left - 1.0:
			best = i
	return best

func _drive() -> void:
	var player = game.player
	if hopping:
		_key("right", true)
		if not player.is_on_floor():
			hopping = false
		elif tick - hop_pressed_tick > 20:
			_end(false, "hop press at tick %d did not leave the plate" % hop_pressed_tick)
		return
	var plate := _plate_index()
	var last: int = route.jump_marks.size() - 1
	if left_last_plate or not player.is_on_floor() or player.position.x < route.jump_marks[plate]:
		_key("right", true)
		return
	if route_mode == "sauce" and plate == SPLAT_PLATE and not splat_done:
		# Walk off the edge (no hop) once plate 2's fork stays raised for the next second.
		if walked_off or route.safe_span(game.forks[plate], 0, 60):
			walked_off = true
			_key("right", true)
		else:
			_key("right", false)
		return
	# Standing at this plate's jump mark.
	_key("right", false)
	if plate == SPLAT_PLATE and not splat_done:
		return   # deliberate failure: stay on plate 2 until its fork strikes
	if hop_at < 0:
		hop_at = tick + route.plan(game.forks, plate)
		_log({"event": "plan", "plate": plate + 1, "hop_in_ticks": hop_at - tick})
	if tick >= hop_at:
		_key("right", true)
		_key("jump", true)
		jump_release_at = tick + JUMP_HOLD_TICKS
		hopping = true
		hop_pressed_tick = tick
		hop_at = -1
		if plate == last:
			left_last_plate = true   # from here: hold Right across the bare table into the dome

func _finish_if_done() -> void:
	if route_mode == "sauce":
		if splat_done and game.state == Game.State.PLAYING and playing_ticks >= 60:
			var ok_s: bool = game.splat_cause == "sauce" and game.sound.count("SFX-SPLAT-SAUCE") == 1
			_end(ok_s, "sauce route: splat cause=%s sauce sounds=%d" % [game.splat_cause, game.sound.count("SFX-SPLAT-SAUCE")])
		elif tick >= LIMIT_TICKS:
			_end(false, "time limit reached before the sauce splat")
		return
	if pilot and first_land_tick > 0 and tick >= first_land_tick + 60:
		_end(true, "pilot: intro pan, first hop and landing captured")
	elif game.state == Game.State.WON and won_tick < 0:
		won_tick = tick
	elif won_tick > 0 and tick >= won_tick + 150:
		var ok: bool = splat_done and game.splat_cause == "fork" and game.sound.count("SFX-WIN") == 1
		_end(ok, "route complete: fork splat=%s cause=%s wins=%d" % [splat_done, game.splat_cause, game.sound.count("SFX-WIN")])
	elif tick >= LIMIT_TICKS:
		_end(false, "time limit reached before the asserted outcome")

func _end(ok: bool, note: String) -> void:
	if not physics_frame.is_connected(_on_physics_frame):
		return
	physics_frame.disconnect(_on_physics_frame)
	_key("right", false)
	_key("jump", false)
	var counts := {}
	for id in game.sound.IDS:
		counts[id] = game.sound.count(id)
	_log({"event": "end", "ok": ok, "note": note, "sound_counts": counts, "splats": game.splats})
	log_file.close()
	print("CAPTURE %s: %s" % ["OK" if ok else "FAILED", note])
	quit(0 if ok else 1)
