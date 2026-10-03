extends SceneTree
## Mechanics checks. Ported from the walker-jumpman starter's test_game.gd to the Jelly Hop
## level; each check keeps its starter id unless the starter feature is gone, in which case
## the replacement is named in the comment above it (see evidence/slice-batch-review.md).
const Game = preload("res://game/session.gd")
const Route = preload("res://tests/route_driver.gd")
const T = preload("res://game/slice_tuning.gd")
var game: Node2D
var results: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func steps(n: int) -> void:
	for i in range(n):
		await physics_frame
		await process_frame

func check(id: String, passed: bool, observation: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observation})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

func fresh() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.start_session()
	game.player.test_control = true
	await steps(3)

func run() -> void:
	var land_y := T.plate_landing_y()
	var spawn: Vector2 = Vector2(T.plate_lefts()[0] + T.plate_width() / 2.0, land_y)
	await fresh()
	check("launch-grounded", game.player.is_on_floor() and game.state == Game.State.PLAYING and game.player.position.distance_to(spawn) < 2, {"position": str(game.player.position), "engine": Engine.get_version_info().string})
	game.player.test_axis = 1
	await steps(8)
	check("speed-cap", is_equal_approx(game.player.velocity.x,320), {"velocity_x": game.player.velocity.x})
	game.player.test_axis = 0
	await steps(5)
	check("neutral-stop", is_zero_approx(game.player.velocity.x), {"velocity_x": game.player.velocity.x})
	game.player.test_control = false
	Input.action_press("move_left")
	Input.action_press("move_right")
	await steps(5)
	check("simultaneous-directions", is_zero_approx(game.player.velocity.x), {"velocity_x": game.player.velocity.x})
	Input.action_release("move_left")
	Input.action_release("move_right")
	game.player.test_control = true
	game.player.test_axis = -1
	await steps(70)
	# Starter: clamp at x 10 (x2: 20). Here the left end wall at x 0 stops the 52 px box at x 26.
	check("left-wall", game.player.position.x >= 25 and game.player.position.x <= 27.5, {"x": game.player.position.x})
	await fresh()
	var start_y: float = game.player.position.y
	game.player.test_jump_pressed = true
	game.player.test_jump_held = true
	var min_y: float = start_y
	for i in range(50):
		await steps(1)
		min_y = minf(min_y, game.player.position.y)
		if i == 12:
			game.player.test_jump_pressed = true
	check("fixed-jump-and-no-double", game.player.jumps == 1 and absf((start_y-min_y)-106.6667) < 10, {"rise_px":start_y-min_y, "jumps":game.player.jumps})
	await steps(30)
	check("held-jump-no-bounce", game.player.jumps == 1 and game.player.is_on_floor(), {"jumps":game.player.jumps})
	# Actual geometry fixtures at a ledge (plate 1's right edge, over the bare first gap);
	# tick ages exercise inclusive 6 / expired 7.
	var ledge_x: float = spawn.x + T.plate_landing_half_width() + 26.0 + 30.0
	for age in [5,6,7]:
		await fresh()
		game.player.position = Vector2(ledge_x, land_y - 70.0)
		await steps(2)
		game.player.last_floor_tick = game.player.tick + 1 - age
		game.player.opportunity_consumed = false
		game.player.test_jump_pressed = true
		await steps(1)
		check("coyote-%d" % age, (game.player.jumps == 1) == (age <= 6), {"age":age, "jumps":game.player.jumps})
	for age in [5,6,7]:
		await fresh()
		game.player.jump_request_tick = game.player.tick + 1 - age
		await steps(1)
		check("buffer-%d" % age, (game.player.jumps == 1) == (age <= 6), {"age":age, "jumps":game.player.jumps})
	await fresh()
	# A ceiling 40 px above the standing box (starter: 40 px at x2).
	game._add_solid(Rect2(spawn.x - 64, land_y - 58 - 40 - 24, 128, 24))
	await steps(2)
	game.player.test_jump_pressed = true
	min_y = land_y
	for i in range(45):
		await steps(1)
		min_y = minf(min_y,game.player.position.y)
	check("low-ceiling", min_y >= land_y-40-0.4 and game.player.jumps == 1 and game.player.is_on_floor(), {"minimum_feet_y":min_y,"jumps":game.player.jumps})
	await fresh()
	game.player.test_jump_pressed = true
	await steps(5)
	game.set_paused(true)
	var paused_position: Vector2 = game.player.position
	var paused_time: float = game.timer
	await steps(10)
	check("pause-freezes", game.player.position == paused_position and game.timer == paused_time, {"position":str(game.player.position),"timer":game.timer})
	game.set_paused(false)
	game.test_mode = false
	game._on_focus_lost()
	check("focus-loss-pauses", game.state == Game.State.PAUSED, {"state":game.state})
	game.test_mode = true
	# Starter: actual-spike-collision. Replaced by the sauce puddle in gap 2 (real Area2D overlap).
	await fresh()
	var lefts := T.plate_lefts()
	var sauce_x: float = lefts[1] + T.plate_width() + T.PLATE_GAPS[1] / 2.0
	game.player.position = Vector2(sauce_x, T.TABLE_TOP)
	await steps(4)
	check("actual-sauce-collision", game.state == Game.State.SPLAT and game.splats == 1 and game.splat_cause == "sauce", {"state":game.state,"splats":game.splats,"cause":game.splat_cause})
	game.resolve_contacts("fork",true)
	check("duplicate-death-ignored", game.splats == 1, {"splats":game.splats})
	var reform_ticks := T.ticks(T.SPLAT_TIME) + T.ticks(T.REFORM_TIME)
	await steps(reform_ticks + 4)
	check("respawn", game.state == Game.State.PLAYING and game.player.position.distance_to(spawn) < 2, {"state":game.state,"position":str(game.player.position)})
	# Starter: manual-restart-not-death (R key; not in the decided controls). Replaced by:
	# respawn goes to the last plate landed on, and landing there is not a splat.
	await fresh()
	var plate2 := Vector2(lefts[1] + T.plate_width() / 2.0, land_y)
	game.player.position = plate2 + Vector2(0, -40)
	await steps(30)
	var cp: int = game.checkpoint
	game.resolve_contacts("sauce", false)
	await steps(reform_ticks + 4)
	check("checkpoint-respawn", cp == 1 and game.splats == 1 and game.player.position.distance_to(plate2) < 2, {"checkpoint":cp,"splats":game.splats,"position":str(game.player.position)})
	var largest_retry_ticks: int = 0
	for i in range(20):
		game.resolve_contacts("sauce",false)
		var waited := 0
		while game.state != Game.State.PLAYING and waited < reform_ticks + 30:
			await steps(1)
			waited += 1
		largest_retry_ticks = maxi(largest_retry_ticks, waited)
	# Starter: <= 60 ticks for a 0.55 s retry. Here: splat + re-form + 2 ticks.
	check("twenty-retries", game.splats == 21 and largest_retry_ticks <= reform_ticks + 2, {"splats":game.splats,"max_retry_ticks":largest_retry_ticks,"limit":reform_ticks + 2})
	await fresh()
	game.resolve_contacts("sauce",true)
	check("death-before-finish", game.state == Game.State.SPLAT, {"state":game.state})
	# Starter: fall-boundary (a pit). The table is continuous, so there is no pit; replaced by:
	# the right end wall keeps the jelly inside the level.
	await fresh()
	game.player.position = Vector2(T.level_width() - 120.0, T.TABLE_TOP)
	game.player.test_axis = 1
	await steps(40)
	check("level-bounds", game.state == Game.State.PLAYING and game.player.position.x <= T.level_width() - 25.5, {"x":game.player.position.x,"level_width":T.level_width()})
	await fresh()
	var route = Route.new()
	var route_ticks := 0
	while game.state == Game.State.PLAYING and route_ticks < 1200:
		route.step(game)
		await steps(1)
		route_ticks += 1
	check("complete-real-route", game.state == Game.State.WON and game.splats == 0, {"state":game.state,"splats":game.splats,"ticks":route_ticks,"position":str(game.player.position),"jump_marks_used":route.next_jump,"hops":route.hops})
	game.state = Game.State.INTRO
	game.start_session()
	game.start_session()
	check("replay-idempotent", game.state == Game.State.PLAYING and game.splats == 0 and game.player.jumps == 0, {"state":game.state,"splats":game.splats,"jumps":game.player.jumps})
	var report := {"scope":"Jelly Hop slice mechanics (scripted input); not human playtesting", "engine":Engine.get_version_info().string,"created_at":Time.get_datetime_string_from_system(true),"results":results,"failures":failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/mechanics-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("WALKER TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
