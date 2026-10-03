extends Node2D
## Jelly Hop: Fork From Above. Session state machine, level building, checkpoints and flow.
## Based on the walker-jumpman starter's session (same pattern: one Node2D that builds the
## level in code, real Area2D overlaps for hazards, contact settling after a teleport).

const Player = preload("res://features/player/player.gd")
const Hud = preload("res://ui/hud.gd")
const Fork = preload("res://features/fork/fork.gd")
const SoundEvents = preload("res://audio/sound_events.gd")
const MusicController = preload("res://audio/music_controller.gd")
const T = preload("res://game/slice_tuning.gd")
enum State { INTRO, PLAYING, PAUSED, SPLAT, REFORM, WON }
const ART := "res://assets/art/"

var state: State = State.INTRO
var player: CharacterBody2D
var camera: Camera2D
var hud: Control
var plates: Array[Dictionary] = []   # {index, left, center, body}
var sauce_areas: Array[Area2D] = []
var forks: Array = []                # one entry per plate: a fork node or null
var goal: Area2D
var checkpoint: int = 0
var jelly_plate: int = 0   # the plate the jelly stands on, or the last plate it stood on (airborne or on bare table)
var splats: int = 0
var splat_cause: String = ""
var timer: float = 0.0
var test_mode: bool = false
var contact_settle_ticks: int = 0
var intro_ticks: int = 0
var shake_ticks: int = 0
var shake_rng := RandomNumberGenerator.new()
var win_from: Vector2
var prompt_shown: bool = false
var won_once: bool = false   # SFX-WIN plays once per run
var sound: Node
var music: Node

func _ready() -> void:
	process_physics_priority = 10
	_setup_input()
	sound = SoundEvents.new()
	sound.context = func() -> String: return State.keys()[state]
	add_child(sound)
	music = MusicController.new()
	add_child(music)
	_build_level()
	player = Player.new()
	player.sound = sound
	add_child(player)
	player.reset_at(spawn_point(0))
	camera = Camera2D.new()
	camera.position_smoothing_speed = T.CAMERA_SMOOTHING
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS   # moves in physics ticks (deterministic)
	add_child(camera)
	shake_rng.seed = 7270
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	get_window().focus_exited.connect(_on_focus_lost)
	_start_intro()

func _setup_input() -> void:
	# SLICE-BRIEF.md §6 (decided 2026-10-02).
	var actions := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE, KEY_UP, KEY_W], "pause": [KEY_ESCAPE], "mute_all": [KEY_M], "mute_music": [KEY_N]}
	for action in actions:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

# ---------------------------------------------------------------- level

func _sprite(file: String, scale_factor: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART + file)
	sprite.scale = Vector2.ONE * scale_factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return sprite

func _build_level() -> void:
	var width := T.level_width()
	# Room: static, behind everything, fixed to the screen (no parallax unless approved).
	var room_layer := CanvasLayer.new()
	room_layer.layer = -10
	add_child(room_layer)
	var room := _sprite("ENV-ROOM.png", 1.0)
	room.centered = false
	room.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	room_layer.add_child(room)
	# Table front: repeats every 1376 * 0.3378 = 465 px; its top edge is the table top.
	var step := 1376.0 * T.TABLE_SCALE
	var x := -step
	while x < width + step:
		var table := _sprite("ENV-TABLE.png", T.TABLE_SCALE)
		table.centered = false
		table.position = Vector2(x, T.TABLE_TOP)
		table.z_index = -5
		add_child(table)
		x += step
	_add_solid(Rect2(-64, T.TABLE_TOP, width + 128, 200))   # table top: the floor
	_add_solid(Rect2(-64, -400, 64, 1120))                  # left end wall
	_add_solid(Rect2(width, -400, 64, 1120))                # right end wall
	# Plates: sprite plus a solid box whose top is the landing surface.
	var lefts := T.plate_lefts()
	var land_y := T.plate_landing_y()
	var half := T.plate_landing_half_width()
	for i in range(lefts.size()):
		var center: float = lefts[i] + T.plate_width() / 2.0
		var plate := _sprite("ENV-PLATE.png", T.PLATE_SCALE)
		plate.centered = false
		plate.offset = Vector2(-T.PLATE_ART_CENTER_X, -T.PLATE_ART_BOTTOM_ROW - 1.0)
		plate.position = Vector2(center, T.TABLE_TOP)
		plate.z_index = -2
		add_child(plate)
		var body := _add_solid(Rect2(center - half, land_y, half * 2.0, T.TABLE_TOP - land_y))
		plates.append({"index": i, "left": lefts[i], "center": center, "body": body})
		# One fork per plate that has one (SLICE-BRIEF.md §5).
		var cycle = T.FORK_CYCLES[i]
		if cycle == null:
			forks.append(null)
		else:
			var fork := Fork.new()
			fork.position = Vector2(center, land_y)
			add_child(fork)
			fork.setup(i, cycle)
			forks.append(fork)
	# Sauce in some gaps, centred in the gap, sitting on the table top.
	for g in range(T.PLATE_GAPS.size()):
		if not T.SAUCE_IN_GAP[g]:
			continue
		var gap_center: float = lefts[g] + T.plate_width() + T.PLATE_GAPS[g] / 2.0
		var sauce := _sprite("ENV-SAUCE.png", T.SAUCE_SCALE)
		sauce.centered = false
		sauce.offset = Vector2(-470.0, -151.0)   # canvas centre x; bottom opaque row 150
		sauce.position = Vector2(gap_center, T.TABLE_TOP + 2.0)
		sauce.z_index = -1
		add_child(sauce)
		# Hit zone = the visible puddle body (the lower rows, ~119 px wide; the thin top edge is left out).
		sauce_areas.append(_add_area(Rect2(gap_center - 58.0, T.TABLE_TOP - 12.0, 116.0, 14.0), 8))
	# Dome at the far end, on the table; drawn in front of the jelly so it sits inside the glass.
	var dome := _sprite("ENV-DOME.png", T.DOME_SCALE)
	dome.centered = false
	dome.offset = Vector2(-375.0, -528.0)
	dome.position = Vector2(T.dome_left() + T.dome_width() / 2.0, T.TABLE_TOP + 1.0)
	dome.z_index = 5
	add_child(dome)
	goal = _add_area(Rect2(T.dome_left() + 40.0, T.TABLE_TOP - 100.0, T.dome_width() - 80.0, 100.0), 16)

func _add_solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _add_area(rect: Rect2, layer: int) -> Area2D:
	var area := Area2D.new()
	area.position = rect.position
	area.collision_layer = layer
	area.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.size / 2.0
	area.add_child(collision)
	add_child(area)
	return area

func spawn_point(plate_index: int) -> Vector2:
	return Vector2(plates[plate_index].center, T.plate_landing_y())

func plate_under(x: float) -> int:
	## Index of the plate whose landing surface is under x, or -1.
	for p in plates:
		if absf(x - p.center) <= T.plate_landing_half_width() + 26.0:
			return p.index
	return -1

# ---------------------------------------------------------------- flow

func camera_target_x() -> float:
	## Follow the jelly to the right and look ahead, so the next forks' shadows are on screen.
	return clampf(player.position.x + T.LOOK_AHEAD, T.VIEW.x / 2.0, T.level_width() - T.VIEW.x / 2.0)

func _set_camera(x: float, smooth: bool) -> void:
	## Snap the camera to x; smoothing (the glide back on respawn) applies to later moves.
	camera.position = Vector2(x, T.VIEW.y / 2.0)
	camera.reset_smoothing()
	camera.position_smoothing_enabled = smooth

func _start_intro() -> void:
	## Panel 1: eye-level pan from the dome back to the jelly. Movement is locked.
	state = State.INTRO
	intro_ticks = 0
	player.enabled = false
	music.restart()
	_set_camera(T.level_width() - T.VIEW.x / 2.0, false)

func start_session() -> void:
	## Begin play on the first plate: when the intro pan ends or is skipped, or on replay after
	## the dome (no pan). Every fork cycle and the checkpoint reset.
	if state == State.PLAYING:
		return
	if state == State.WON:
		music.restart()   # replay: the loop starts again from the top
	splats = 0
	checkpoint = 0
	jelly_plate = 0
	prompt_shown = false
	won_once = false
	shake_ticks = 0
	camera.offset = Vector2.ZERO
	for fork in forks:
		if fork:
			fork.reset_cycle()
	_begin_play(spawn_point(0))
	_set_camera(camera_target_x(), true)

func _begin_play(at: Vector2) -> void:
	state = State.PLAYING
	timer = 0.0
	# Area2D overlaps are physics-step snapshots. Discard pre-teleport contacts
	# until the broadphase has observed the reset, preventing a phantom second splat.
	contact_settle_ticks = 2
	player.reset_at(at)
	player.enabled = true
	# Control returns: the checkpoint fork's safe window begins now (panel 6, failure #12).
	if forks[checkpoint]:
		forks[checkpoint].restart_at_safe()

func set_paused(value: bool) -> void:
	if value and state == State.PLAYING:
		state = State.PAUSED
		player.enabled = false
	elif not value and state == State.PAUSED:
		state = State.PLAYING
		player.enabled = true
		player.require_fresh_press()

func _on_focus_lost() -> void:
	if not test_mode:
		set_paused(true)

func resolve_contacts(cause: String, finished: bool) -> void:
	## cause: "" (none), "fork" or "sauce". A failure wins over reaching the goal.
	if state != State.PLAYING:
		return
	if cause != "":
		state = State.SPLAT
		splats += 1
		splat_cause = cause
		timer = T.SPLAT_TIME
		player.enabled = false
		player.velocity = Vector2.ZERO
		# One splat sound per failure: hits stay off until control returns.
		sound.play("SFX-SPLAT-FORK" if cause == "fork" else "SFX-SPLAT-SAUCE")
		if cause == "fork":
			shake_ticks = T.ticks(T.SHAKE_TIME)   # camera only; never on a sauce splat
		# The jelly will re-form on the checkpoint plate: hold that fork raised until control returns.
		if forks[checkpoint]:
			forks[checkpoint].hold_raised()
	elif finished:
		state = State.WON
		timer = 0.0
		prompt_shown = false
		win_from = player.position
		player.enabled = false
		player.velocity = Vector2.ZERO
		if not won_once:
			won_once = true
			sound.play("SFX-WIN")

func view_rect() -> Rect2:
	return Rect2(camera.get_screen_center_position() - T.VIEW / 2.0, T.VIEW)

func shadow_on_screen(fork) -> bool:
	return view_rect().intersects(fork.shadow_rect())

func _advance_forks() -> void:
	## Forks keep their fixed rhythm during play, splat and re-form (paused, intro and win freeze them).
	for fork in forks:
		if fork and fork.advance() == "down":
			# SFX-WARN (Kiran, 2026-10-03, after the second audition): the scrape plays once when the fork
			# over the jelly's current or next plate starts descending, if that fork is on screen at that
			# moment. Nothing plays when a shadow starts growing; the shadow alone does the warning.
			fork.announced = shadow_on_screen(fork) and fork.plate_index in [jelly_plate, jelly_plate + 1]
			if fork.announced:
				on_warning(fork)

func on_warning(_fork) -> void:
	sound.play("SFX-WARN")   # once per strike, as the fork starts descending

func warnings_on_screen() -> int:
	## Forks warning (shadow growing, or striking) with any part of the shadow on screen.
	## CHANGE-BRIEF.md music rule (Kiran, 2026-10-03): a shadow that started off screen dips
	## the music once it is on screen, though it never plays SFX-WARN.
	var n := 0
	for fork in forks:
		if fork and fork.is_warning() and shadow_on_screen(fork):
			n += 1
	return n

func music_target() -> String:
	match state:
		State.INTRO:
			return "intro"
		State.PAUSED:
			return "pause"
		State.WON:
			return "end_quiet" if prompt_shown else "win_fade"
		State.SPLAT, State.REFORM:
			return "splat"
	return "warning" if warnings_on_screen() > 0 else "normal"

func _physics_process(delta: float) -> void:
	if state in [State.PLAYING, State.SPLAT, State.REFORM]:
		_advance_forks()
	match state:
		State.INTRO:
			intro_ticks += 1
			var k := clampf(float(intro_ticks) / float(T.ticks(T.INTRO_PAN)), 0.0, 1.0)
			var from := T.level_width() - T.VIEW.x / 2.0
			camera.position.x = lerpf(from, camera_target_x(), ease(k, -2.0))   # ease in-out
			if k >= 1.0:
				start_session()
		State.WON:
			# Slide into the dome, then wait for the prompt (panel 7).
			timer += delta
			var k := clampf(timer / T.WIN_SLIDE, 0.0, 1.0)
			var dome_center := Vector2(T.dome_left() + T.dome_width() / 2.0, T.TABLE_TOP)
			player.position = win_from.lerp(dome_center, 1.0 - (1.0 - k) * (1.0 - k))
			if timer >= T.PROMPT_DELAY:
				prompt_shown = true
		State.SPLAT:
			timer -= delta
			if timer <= 0.0:
				# Re-form on the last safe plate; hits stay off and input stays locked.
				state = State.REFORM
				timer = T.REFORM_TIME
				player.reset_at(spawn_point(checkpoint))
				jelly_plate = checkpoint
		State.REFORM:
			timer -= delta
			if timer <= 0.0:
				_begin_play(spawn_point(checkpoint))
		State.PLAYING:
			timer += delta
			var cause := ""
			for sauce in sauce_areas:
				if sauce.overlaps_body(player):
					cause = "sauce"
			for fork in forks:
				if fork and fork.hit_area.overlaps_body(player):
					cause = "fork"
			if contact_settle_ticks > 0:
				contact_settle_ticks -= 1
			else:
				resolve_contacts(cause, goal.overlaps_body(player))
			if state == State.PLAYING and player.just_landed:
				# Airborne -> grounded, and not into sauce (that is a splat). Respawn is not a landing.
				sound.play("SFX-LAND")
				var p := plate_under(player.position.x)
				if p >= 0:
					checkpoint = p
	if state != State.INTRO:
		camera.position.x = camera_target_x()   # smoothing gives the glide back on respawn
	if shake_ticks > 0:
		shake_ticks -= 1
		var amount := T.SHAKE_PX * float(shake_ticks) / float(T.ticks(T.SHAKE_TIME))
		camera.offset = Vector2(shake_rng.randf_range(-1, 1), shake_rng.randf_range(-1, 1)) * amount
	else:
		camera.offset = Vector2.ZERO
	music.set_target(music_target())
	var under := plate_under(player.position.x)
	if under >= 0 and player.is_on_floor() and state == State.PLAYING:
		jelly_plate = under
	player.worried = state == State.PLAYING and under >= 0 and forks[under] != null and forks[under].phase() == Fork.Phase.SHADOW
	player.override_pose = {State.SPLAT: "SPLAT", State.REFORM: "RESPAWN", State.WON: "CELEBRATE"}.get(state, "")
	if is_instance_valid(hud):
		hud.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo or not event.pressed:
		return
	# M and N only toggle mute; muting never changes game state, so they never skip or restart.
	if event.is_action_pressed("mute_all") or event.is_action_pressed("mute_music"):
		toggle_mute(event.is_action_pressed("mute_all"))
		return
	if state == State.INTRO:
		start_session()   # any key skips the pan; the skip key never hops (fresh press rule)
	elif state == State.WON:
		if prompt_shown:
			start_session()   # any key plays again, on the first plate, with no intro pan
	elif event.is_action_pressed("pause"):
		set_paused(state != State.PAUSED)

func toggle_mute(all: bool) -> void:
	music.toggle_mute(all)
