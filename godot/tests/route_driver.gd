extends RefCounted
## Fixed input route through the real level. No position/velocity edits.
## Holds right, stops at a jump mark near the right edge of each plate, and hops when the
## forks' fixed rhythms allow a safe path onward. The forks are read, never changed.
const T = preload("res://game/slice_tuning.gd")
const LEAVE := 6     # ticks the jelly is still over the plate it hops from
const ARRIVE := 24   # earliest tick it can be over the next plate (conservative)
var jump_marks: Array[float] = []
var walk_ticks: Array[int] = []   # hop -> stopped at the next plate's mark (estimate + margin)
var next_jump: int = 0
var hop_at: int = -1              # route tick of the planned hop on the current plate
var ticks: int = 0
var hops: Array[Dictionary] = []

func _init() -> void:
	for left in T.plate_lefts():
		jump_marks.append(left + T.plate_width() / 2.0 + T.plate_landing_half_width() - 12.0)
	for i in range(jump_marks.size() - 1):
		var pitch := jump_marks[i + 1] - jump_marks[i]
		walk_ticks.append(37 + int(maxf(0.0, pitch - 190.0) / 5.0) + 14)

func step(game: Node2D) -> void:
	var player: CharacterBody2D = game.player
	ticks += 1
	player.test_control = true
	player.test_jump_held = false
	if next_jump >= jump_marks.size() or not player.is_on_floor() or player.position.x < jump_marks[next_jump]:
		player.test_axis = 1.0
		return
	player.test_axis = 0.0
	if hop_at < 0:
		hop_at = ticks + plan(game.forks, next_jump)
	if ticks >= hop_at:
		player.test_axis = 1.0
		player.test_jump_pressed = true
		hops.append({"plate": next_jump + 1, "tick": ticks})
		next_jump += 1
		hop_at = -1

func safe_span(fork, from: int, to: int) -> bool:
	if fork == null:
		return true
	for k in range(from, to + 1):
		if not fork.harmless_in(k):
			return false
	return true

func plan(forks: Array, plate: int) -> int:
	## Breadth-first search over (plate, ticks from now): wait one tick, or hop. Returns the
	## first hop's delay on the earliest path that reaches the last plate and can leave it.
	var last := jump_marks.size() - 1
	var start := Vector2i(plate, 0)
	var parent := {start: null}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var s: Vector2i = queue.pop_front()
		var j := s.x
		var d := s.y
		if d > 60 * 30:
			continue
		if j == last and safe_span(forks[j], d, d + LEAVE):
			return d if plate == last else _first_hop(parent, s, plate)
		var waits := Vector2i(j, d + 1)
		if not parent.has(waits) and safe_span(forks[j], d + 1, d + 1):
			parent[waits] = s
			queue.append(waits)
		if j == last:
			continue
		var arrive := d + walk_ticks[j]
		var hops_to := Vector2i(j + 1, arrive)
		if not parent.has(hops_to) and safe_span(forks[j], d, d + LEAVE) and safe_span(forks[j + 1], d + ARRIVE, arrive + 6):
			parent[hops_to] = s
			queue.append(hops_to)
	return 0

func _first_hop(parent: Dictionary, goal: Vector2i, plate: int) -> int:
	var s = goal
	var first_hop := 0
	while parent[s] != null:
		var prev: Vector2i = parent[s]
		if prev.x != s.x and prev.x == plate:
			first_hop = prev.y
		s = prev
	return first_hop
