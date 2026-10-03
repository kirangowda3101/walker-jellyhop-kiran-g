extends Node2D
## One fork over one plate. Fixed, learnable cycle (CONCEPT.md), driven by physics ticks:
## SAFE (raised) -> SHADOW (the shadow grows) -> DOWN -> HOLD -> UP -> SAFE.
## The node sits on the plate's landing surface at the plate centre; the shadow is drawn
## here (ENV-SHADOW is code-drawn), and the fork sprite and hit area move as one "head".
## Hit zone = the visible tines: one polygon per tine, traced from the art's alpha.

const T = preload("res://game/slice_tuning.gd")
enum Phase { SAFE, SHADOW, DOWN, HOLD, UP }
const ART_TIP_ROW := 1258.0       # first transparent row below the tips (tips end at row 1257)
const ART_TINE_CENTER_X := 167.5  # centre of the tine span (9..326)

static var _tine_cache: Array = []   # tine outlines in art pixels, traced once

var plate_index: int = 0
var safe_ticks: int
var shadow_ticks: int
var down_ticks: int = T.ticks(T.STRIKE_DOWN)
var hold_ticks: int = T.ticks(T.STRIKE_HOLD)
var up_ticks: int = T.ticks(T.STRIKE_UP)
var offset_ticks: int
var period: int
var t: int = 0                   # position in the cycle, 0 = start of the safe window
var held: bool = false           # frozen raised at the start of its safe window (respawn)
var hold_pending: bool = false   # finish the current strike, then hold
var announced: bool = false      # SFX-WARN played for this strike (set by the session when the fork starts descending)
var head: Node2D
var sprite: Sprite2D
var hit_area: Area2D
var scale_factor: float = T.fork_scale()

func setup(index: int, cycle: Dictionary) -> void:
	plate_index = index
	safe_ticks = T.ticks(cycle.safe)
	shadow_ticks = T.ticks(cycle.shadow)
	offset_ticks = T.ticks(cycle.offset)
	period = safe_ticks + shadow_ticks + down_ticks + hold_ticks + up_ticks
	z_index = -1   # shadow: above the plate, below the jelly
	head = Node2D.new()
	head.z_index = 0   # fork behind the jelly, so a splat under the tines stays visible (panel 5)
	add_child(head)
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/art/ENV-FORK.png")
	sprite.centered = false
	sprite.offset = Vector2(-ART_TINE_CENTER_X, -ART_TIP_ROW)   # origin = tine tips
	sprite.scale = Vector2.ONE * scale_factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	head.add_child(sprite)
	hit_area = Area2D.new()
	hit_area.collision_layer = 8   # Hazard
	hit_area.collision_mask = 2    # Player
	for outline in tine_outlines(sprite.texture):
		var poly := CollisionPolygon2D.new()
		var points := PackedVector2Array()
		for p in outline:
			points.append((p - Vector2(ART_TINE_CENTER_X, ART_TIP_ROW)) * scale_factor)
		poly.polygon = points
		hit_area.add_child(poly)
	head.add_child(hit_area)
	reset_cycle()

static func tine_outlines(texture: Texture2D) -> Array:
	## Traces each tine's opaque outline (alpha > 0.5) from the rows where the head splits
	## into four tines down to the tips. Returns one closed outline per tine, in art pixels.
	if not _tine_cache.is_empty():
		return _tine_cache
	var img := texture.get_image()
	var lefts: Array = [[], [], [], []]
	var rights: Array = [[], [], [], []]
	var split_row := -1
	for y in range(900, img.get_height()):
		var runs := []
		var inside := false
		var start := 0
		for x in range(img.get_width()):
			var solid := img.get_pixel(x, y).a > 0.5
			if solid and not inside:
				start = x
				inside = true
			elif not solid and inside:
				runs.append(Vector2(start, x))   # x = first transparent column after the run
				inside = false
		if inside:
			runs.append(Vector2(start, img.get_width()))
		if runs.size() == 4:
			if split_row < 0:
				split_row = y
			for i in range(4):
				lefts[i].append(Vector2(runs[i].x, y))
				rights[i].append(Vector2(runs[i].y, y))
		elif split_row >= 0 and runs.is_empty():
			break
	for i in range(4):
		var outline: Array = []
		var n: int = lefts[i].size()
		# Sample every 3 rows plus the first and last row; outline runs down the left edge
		# and back up the right edge (pixel edges: bottom row closes at y + 1).
		var rows: Array = range(0, n, 3)
		if rows.back() != n - 1:
			rows.append(n - 1)
		for r in rows:
			outline.append(lefts[i][r])
		outline.append(lefts[i][n - 1] + Vector2(0, 1))
		outline.append(rights[i][n - 1] + Vector2(0, 1))
		rows.reverse()
		for r in rows:
			outline.append(rights[i][r])
		_tine_cache.append(outline)
	return _tine_cache

func reset_cycle() -> void:
	## Start of play or a replay: every fork back to its fixed starting point.
	t = offset_ticks
	held = false
	hold_pending = false
	announced = false
	_apply()

func phase_of(pos: int) -> Phase:
	var p := posmod(pos, period)
	if p < safe_ticks:
		return Phase.SAFE
	p -= safe_ticks
	if p < shadow_ticks:
		return Phase.SHADOW
	p -= shadow_ticks
	if p < down_ticks:
		return Phase.DOWN
	p -= down_ticks
	if p < hold_ticks:
		return Phase.HOLD
	return Phase.UP

func phase() -> Phase:
	return phase_of(t)

func harmless_in(k: int) -> bool:
	## Whether the fork will be raised (safe or shadow phase) k ticks from now, if it keeps
	## its rhythm. Used by the scripted route; held forks are raised.
	if held:
		return true
	return phase_of(t + k) in [Phase.SAFE, Phase.SHADOW]

func advance() -> String:
	## One physics tick. Returns "shadow" when the shadow phase starts on this tick, "down" when the fork
	## starts descending (the start of its strike), otherwise "".
	if held:
		return ""
	var before := phase()
	t = posmod(t + 1, period)
	if hold_pending and phase() == Phase.SAFE:
		t = 0
		held = true
		hold_pending = false
	var event := ""
	if before != Phase.SHADOW and phase() == Phase.SHADOW:
		event = "shadow"
		announced = false
	elif before != Phase.DOWN and phase() == Phase.DOWN:
		event = "down"
	_apply()
	return event

func hold_raised() -> void:
	## Respawn on this plate: no new shadow or strike until control returns.
	## A strike in progress finishes (the cause stays visible), then the fork holds.
	if phase() in [Phase.SAFE, Phase.SHADOW]:
		t = 0
		held = true
		announced = false
	else:
		hold_pending = true
	_apply()

func restart_at_safe() -> void:
	## Control has returned: the safe window begins now (panel 6, failure #12).
	t = 0
	held = false
	hold_pending = false
	announced = false
	_apply()

func tip_y() -> float:
	## Tine tips relative to the plate surface (0 = touching the landing surface).
	var raised := T.FORK_RAISED_TIP_Y - T.plate_landing_y()
	var p := posmod(t, period)
	match phase():
		Phase.DOWN:
			var k := float(p - safe_ticks - shadow_ticks + 1) / float(down_ticks)
			return lerpf(raised, 0.0, k * k)
		Phase.HOLD:
			return 0.0
		Phase.UP:
			var k := float(p - safe_ticks - shadow_ticks - down_ticks - hold_ticks + 1) / float(up_ticks)
			return lerpf(0.0, raised, 1.0 - (1.0 - k) * (1.0 - k))
	return raised

func shadow_amount() -> float:
	## 0 = no shadow, 1 = full size. Grows through the shadow phase, full during the strike.
	var p := posmod(t, period)
	match phase():
		Phase.SHADOW:
			return float(p - safe_ticks + 1) / float(shadow_ticks)
		Phase.DOWN, Phase.HOLD:
			return 1.0
		Phase.UP:
			return 1.0 - float(p - safe_ticks - shadow_ticks - down_ticks - hold_ticks + 1) / float(up_ticks)
	return 0.0

func shadow_rect() -> Rect2:
	## Full-size shadow in world coordinates (used for the on-screen test).
	var half := T.FORK_TINE_SPAN_PX / 2.0 + 6.0
	return Rect2(global_position.x - half, global_position.y - 8.0, half * 2.0, 16.0)

func is_warning() -> bool:
	## Music "warning": the shadow grows and the strike lands (CONCEPT.md: fades back after the strike).
	return not held and phase() in [Phase.SHADOW, Phase.DOWN, Phase.HOLD]

func _apply() -> void:
	if head:
		head.position.y = tip_y()
	queue_redraw()

func _draw() -> void:
	var amount := shadow_amount()
	if amount <= 0.0:
		return
	# Soft dark ellipse on the plate: rings from wide and faint to narrow and darker.
	var half := (T.FORK_TINE_SPAN_PX / 2.0 + 6.0) * lerpf(0.25, 1.0, amount)
	for ring in range(5):
		var f := 1.0 - float(ring) / 5.0
		var points := PackedVector2Array()
		for i in range(33):
			var a := TAU * float(i) / 32.0
			points.append(Vector2(cos(a) * half * f, sin(a) * 7.0 * f - 1.0))
		draw_colored_polygon(points, Color(0.05, 0.03, 0.02, 0.28 * lerpf(0.45, 1.0, amount)))
