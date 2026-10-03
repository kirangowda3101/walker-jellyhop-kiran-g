extends SceneTree
## Synthetic keyboard events through Godot Input (not human playtesting). Ported from the
## walker-jumpman starter to the decided controls (SLICE-BRIEF.md §6). Starter checks that used
## keys no longer in the game (Enter, R, P, M-menu) are replaced; see evidence/slice-batch-review.md.
const Game = preload("res://game/session.gd")
const T = preload("res://game/slice_tuning.gd")
var game: Node2D
var results: Array[Dictionary] = []
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func steps(n: int) -> void:
	for i in range(n):
		await physics_frame
		await process_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await steps(2)

func tap(code: Key) -> void:
	await key(code,true)
	await key(code,false)

func check(id: String, condition: bool, observed: String) -> void:
	results.append({"id":id,"status":"PASS" if condition else "FAIL","observed":observed})
	print(JSON.stringify(results.back()))
	if not condition: failures += 1

func move_with(code: Key) -> float:
	var x: float = game.player.position.x
	await key(code,true)
	await steps(10)
	await key(code,false)
	await steps(10)
	return game.player.position.x - x

func jump_with(code: Key) -> bool:
	await steps(40)
	var before: int = game.player.jumps
	await tap(code)
	var rising: bool = game.player.velocity.y < 0
	await steps(50)
	return game.player.jumps == before + 1 and rising

func run() -> void:
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	await steps(2)
	# Starter enter-start -> any key skips the intro (Enter used here as an "any" key).
	await tap(KEY_ENTER)
	check("any-key-start",game.state == Game.State.PLAYING,"state="+str(game.state))
	var dx := await move_with(KEY_D)
	check("keyboard-move-d",dx > 40,"dx="+str(dx))
	dx = await move_with(KEY_A)
	check("keyboard-move-a",dx < -40,"dx="+str(dx))
	dx = await move_with(KEY_RIGHT)
	check("keyboard-move-right-arrow",dx > 40,"dx="+str(dx))
	dx = await move_with(KEY_LEFT)
	check("keyboard-move-left-arrow",dx < -40,"dx="+str(dx))
	check("keyboard-jump-space",await jump_with(KEY_SPACE),"jumps="+str(game.player.jumps))
	check("keyboard-jump-up",await jump_with(KEY_UP),"jumps="+str(game.player.jumps))
	check("keyboard-jump-w",await jump_with(KEY_W),"jumps="+str(game.player.jumps))
	await tap(KEY_SPACE)
	await tap(KEY_ESCAPE)
	var y: float = game.player.position.y
	await steps(5)
	check("escape-pause",game.state == Game.State.PAUSED and game.player.position.y == y,"state="+str(game.state))
	# Starter enter-resume -> Esc resumes (SLICE-BRIEF.md §6).
	await tap(KEY_ESCAPE)
	check("escape-resume",game.state == Game.State.PLAYING,"state="+str(game.state))
	# Starter enter-replay -> any key after the dome prompt plays again on the first plate.
	game.resolve_contacts("",true)
	await steps(T.ticks(T.PROMPT_DELAY) + 2)
	await tap(KEY_ENTER)
	check("any-key-replay",game.state == Game.State.PLAYING and game.player.jumps == 0 and game.player.position.distance_to(game.spawn_point(0)) < 1,"state="+str(game.state))
	# Starter pause-main-menu / menu-start-again -> there is no menu; M and N toggle mute only.
	var state_before: int = game.state
	await tap(KEY_M)
	var master_muted := AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	await tap(KEY_M)
	await tap(KEY_N)
	var music_bus := AudioServer.get_bus_index("Music")
	var music_muted := music_bus >= 0 and AudioServer.is_bus_mute(music_bus)
	await tap(KEY_N)
	check("m-n-mute-only",game.state == state_before and master_muted and music_muted and not AudioServer.is_bus_mute(0),"state="+str(game.state)+" master_muted="+str(master_muted)+" music_muted="+str(music_muted))
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out+"/keyboard-"+str(Time.get_unix_time_from_system())+".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Synthetic keyboard events through Godot Input, not human playtesting", "engine":Engine.get_version_info().string,"results":results,"failures":failures},"  "))
	file.close()
	print("KEYBOARD TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
