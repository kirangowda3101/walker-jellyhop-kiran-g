extends SceneTree
## Screenshots of each storyboard moment, rendered by the real game (needs a window; not
## headless). Ported from the walker-jumpman starter's capture_game.gd. Setups are scripted
## (input, plus fork timing and placement fixtures where a moment needs them); this is not a
## playtest. Output: evidence/slice-screens/NN-moment.png at 1280 x 720.
const Game = preload("res://game/session.gd")
const T = preload("res://game/slice_tuning.gd")
var game: Node2D
var output: String
var notes: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func step(n: int = 1) -> void:
	for i in range(n):
		await physics_frame
		await process_frame

func capture(label: String, note: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var raw_size := image.get_size()
	if raw_size != Vector2i(1280, 720):
		image.resize(1280, 720, Image.INTERPOLATE_LANCZOS)   # HiDPI window: scaled to the base size
	var error := image.save_png(output + "/" + label + ".png")
	assert(error == OK)
	var line := "%s: rendered %dx%d, saved 1280x720; pose=%s state=%s; %s" % [label, raw_size.x, raw_size.y, game.player.pose, Game.State.keys()[game.state], note]
	notes.append(line)
	print("Captured: " + line)

func fresh(intro: bool = false) -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	if not intro:
		game.start_session()
		game.player.test_control = true
	await step(2)

func place(plate: int) -> void:
	game.player.position = game.spawn_point(plate)
	game._set_camera(game.camera_target_x(), true)
	await step(3)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/slice-screens")
	DirAccess.make_dir_recursive_absolute(output)
	# 1. Intro pan (panel 1): partway through the pan from the dome back to the jelly.
	await fresh(true)
	await step(int(T.ticks(T.INTRO_PAN) * 0.35))
	await capture("01-intro-pan", "35% into the pan; title and skip hint on screen")
	# 2. Hop (panel 2): rising from plate 1 toward plate 2, plate 2's fork raised.
	await fresh()
	game.player.test_axis = 1
	while game.player.position.x < game.plates[0].center + T.plate_landing_half_width() - 12.0:
		await step()
	game.player.test_jump_pressed = true
	while game.player.pose != "RISE":
		await step()
	await step(4)
	await capture("02-hop", "real input route: run right, hop at plate 1's edge")
	# 3. Warning (panel 3): on plate 2, its fork's shadow growing (fork set to mid-shadow).
	await fresh()
	await place(1)
	var fork2 = game.forks[1]
	fork2.t = fork2.safe_ticks - 1
	await step(int(fork2.shadow_ticks * 0.6))
	await capture("03-warning", "fixture: plate 2's fork started its shadow phase; worried pose")
	# 4. Safe landing (panel 4): hop from plate 2 to plate 3 as plate 2's fork strikes behind.
	await fresh()
	await place(1)
	game.forks[2].held = true   # fixture: plate 3's fork stays raised
	game.player.position.x = game.plates[1].center + T.plate_landing_half_width() - 12.0
	await step(2)
	fork2 = game.forks[1]
	fork2.t = fork2.safe_ticks + fork2.shadow_ticks - 22   # strikes while the jelly is in the air
	game.player.test_axis = 1
	game.player.test_jump_pressed = true
	while not game.player.just_landed:
		await step()
	game.player.test_axis = 0
	await step(2)
	await capture("04-safe-landing", "fixture: fork timing; real hop; landing squash while plate 2 is struck")
	# 5. Splat (panel 5): plate 2's fork strikes the jelly (fork stays in view; camera shake).
	await fresh()
	await place(1)
	fork2 = game.forks[1]
	fork2.t = fork2.safe_ticks + fork2.shadow_ticks - 2
	while game.state != Game.State.SPLAT:
		await step()
	await step(6)
	await capture("05-splat", "fixture: fork timing; real overlap with the tines")
	# 6. Respawn (panel 6): re-forming on the checkpoint plate, the camera gliding back.
	await fresh()
	await place(2)
	game.checkpoint = 2           # fixture: plate 3 is the last safe plate
	game.forks[2].held = true
	var lefts := T.plate_lefts()
	game.player.position = Vector2(lefts[3] + T.plate_width() + T.PLATE_GAPS[3] / 2.0, T.TABLE_TOP - 40.0)
	game._set_camera(game.camera_target_x(), true)
	while game.state != Game.State.REFORM:
		await step()   # falls into the sauce in gap 4: a real sauce splat
	await step(int(T.ticks(T.REFORM_TIME) * 0.4))
	await capture("06-respawn", "fixture: checkpoint plate 3; real sauce splat in gap 4; re-forming, camera gliding back")
	# 7. Dome (panel 7): relief pose under the glass, SAFE! and the prompt.
	await fresh()
	game.player.position = Vector2(T.dome_left() - 30.0, T.TABLE_TOP)
	game._set_camera(game.camera_target_x(), false)
	game.player.test_axis = 1
	while game.state == Game.State.PLAYING:
		await step()
	game.player.test_axis = 0
	await step(T.ticks(T.PROMPT_DELAY) + 5)
	await capture("07-dome", "walked into the dome; prompt shown")
	var file := FileAccess.open(output + "/captures.txt", FileAccess.WRITE)
	file.store_string("Scripted screenshots (not a playtest); engine %s\n%s\n" % [Engine.get_version_info().string, "\n".join(notes)])
	file.close()
	print("SLICE CAPTURES: %d" % notes.size())
	game.queue_free()
	await process_frame
	quit()
