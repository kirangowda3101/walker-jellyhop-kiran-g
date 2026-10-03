extends CharacterBody2D
## The jelly. Movement model from the walker-jumpman starter (unchanged rules: fixed jump,
## coyote and buffer ticks, a held jump never re-jumps); sizes from CHARACTER-SHEET.md.

const Tuning = preload("res://features/player/tuning.gd")
const T = preload("res://game/slice_tuning.gd")
const POSES := ["IDLE", "BORED", "SCOOT-A", "SCOOT-B", "ANTIC", "RISE", "FALL", "LAND", "WORRY", "SPLAT", "RESPAWN", "CELEBRATE"]
## CHARACTER-SHEET.md gives the crouch, landing squash and bored slump the low box. In this build
## the crouch (ANTIC) is a visual-only pose shown after takeoff, so it keeps the standing box:
## a low box in the air let the jelly rise 14 px higher into a ceiling (starter low-ceiling check).
const LOW_POSES := ["LAND", "BORED"]
const STANDING := Vector2(52, 58)   # CHARACTER-SHEET.md: bottom-aligned, centred
const LOW := Vector2(52, 44)
var tuning = Tuning.new()
var enabled: bool = false
var tick: int = 0
var last_floor_tick: int = -1000
var jump_request_tick: int = -1000
var opportunity_consumed: bool = false
var require_jump_release: bool = true
var require_axis_release: bool = true   # a direction held through a lock is ignored until released
var ignore_press_through_frame: int = -1
var facing: float = 1.0
var jumps: int = 0
var was_grounded: bool = true
var just_landed: bool = false
var just_hopped: bool = false
var box: Vector2 = STANDING
var collider: CollisionShape2D
var sprite: Sprite2D
var textures: Dictionary = {}
var pose: String = "IDLE"
var override_pose: String = ""   # set by the session: SPLAT, RESPAWN or CELEBRATE
var worried: bool = false        # set by the session: a shadow is growing over this plate
var idle_ticks: int = 0
var land_ticks: int = 0
var hop_ticks: int = -1          # ticks since takeoff; -1 when the jelly did not hop
var sound: Node                  # the session's sound-event entry point
var test_control: bool = false
var test_axis: float = 0.0
var test_jump_pressed: bool = false
var test_jump_held: bool = false

func _ready() -> void:
	name = "Player"
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 2.0
	collider = CollisionShape2D.new()
	collider.shape = RectangleShape2D.new()
	add_child(collider)
	set_box(STANDING)
	for p in POSES:
		textures[p] = load("res://assets/art/CHAR-%s.png" % p)
	# Every pose's bottom edge is at y 811-812 of its 1024 canvas: anchor at bottom centre.
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = -T.JELLY_ANCHOR
	sprite.scale = Vector2.ONE * T.JELLY_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	_update_pose()

func set_box(size: Vector2) -> void:
	box = size
	(collider.shape as RectangleShape2D).size = size
	collider.position = Vector2(0, -size.y / 2.0)

func reset_at(spawn: Vector2) -> void:
	position = spawn
	velocity = Vector2.ZERO
	last_floor_tick = -1000
	jumps = 0
	was_grounded = true   # placing the jelly on a plate is not a landing
	just_landed = false
	just_hopped = false
	idle_ticks = 0
	land_ticks = 0
	hop_ticks = -1
	require_fresh_press()
	_update_pose()

func require_fresh_press() -> void:
	## The next hop needs a new jump press: a held key must be released first, and a press
	## that arrived with the key that changed the state (skip, restart, unpause) is ignored.
	## A held direction is ignored the same way, so the skip or restart key never moves the jelly.
	require_jump_release = true
	require_axis_release = true
	jump_request_tick = -1000
	opportunity_consumed = false
	test_jump_pressed = false
	ignore_press_through_frame = Engine.get_physics_frames() + 1

func _physics_process(delta: float) -> void:
	just_landed = false
	just_hopped = false
	if not enabled:
		_update_pose()
		return
	tick += 1
	var axis := test_axis if test_control else Input.get_axis("move_left", "move_right")
	if is_zero_approx(axis):
		require_axis_release = false
	elif require_axis_release:
		axis = 0.0
	var held := test_jump_held if test_control else Input.is_action_pressed("jump")
	var pressed := test_jump_pressed if test_control else Input.is_action_just_pressed("jump")
	test_jump_pressed = false
	if pressed and Engine.get_physics_frames() <= ignore_press_through_frame:
		pressed = false
	idle_ticks = 0 if (not is_zero_approx(axis) or held or pressed) else idle_ticks + 1
	if not held:
		require_jump_release = false
	if is_on_floor() and velocity.y >= 0.0:
		last_floor_tick = tick
		opportunity_consumed = false
	if pressed and not require_jump_release:
		jump_request_tick = tick
	var rate: float = tuning.acceleration if not is_zero_approx(axis) else tuning.deceleration
	velocity.x = move_toward(velocity.x, axis * tuning.speed, rate * delta)
	if not is_zero_approx(axis):
		facing = signf(axis)
	velocity.y = minf(velocity.y + tuning.gravity * delta, tuning.terminal_velocity)
	if not opportunity_consumed and tick - last_floor_tick <= tuning.coyote_ticks and tick - jump_request_tick <= tuning.buffer_ticks:
		velocity.y = tuning.jump_velocity
		opportunity_consumed = true
		jump_request_tick = -1000
		jumps += 1
		just_hopped = true
		hop_ticks = 0
		# Grounded (or coyote) -> airborne after a fresh jump press: the only place SFX-HOP plays.
		if sound:
			sound.play("SFX-HOP")
	move_and_slide()
	var grounded := is_on_floor()
	if grounded and not was_grounded:
		just_landed = true
		land_ticks = T.LAND_TICKS
		hop_ticks = -1
	elif land_ticks > 0:
		land_ticks -= 1
	if not grounded and hop_ticks >= 0:
		hop_ticks += 1
	was_grounded = grounded
	_update_pose()

func choose_pose() -> String:
	## CHARACTER-SHEET.md pose table. Worried always overrides bored.
	if override_pose != "":
		return override_pose
	if not was_grounded:
		if hop_ticks >= 0 and hop_ticks <= T.ANTIC_TICKS:
			return "ANTIC"   # visual only: shown at takeoff, no input delay
		return "RISE" if velocity.y < 0.0 else "FALL"
	if land_ticks > 0:
		return "LAND"
	if absf(velocity.x) > 8.0:
		return "SCOOT-A" if (tick / T.ticks(T.SCOOT_FRAME)) % 2 == 0 else "SCOOT-B"
	if worried:
		return "WORRY"
	if idle_ticks >= T.ticks(T.BORED_DELAY):
		return "BORED"
	return "IDLE"

func _update_pose() -> void:
	pose = choose_pose()
	sprite.texture = textures[pose]
	sprite.flip_h = facing < 0.0   # drawn facing right; keeps the last direction moved
	var wanted := LOW if pose in LOW_POSES else STANDING
	if wanted != box:
		set_box(wanted)
