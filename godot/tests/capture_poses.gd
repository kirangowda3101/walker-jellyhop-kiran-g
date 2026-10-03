extends SceneTree
## TEST-REPORT: in-engine screenshots of every jelly pose state, facing right and left, with the active
## collision box outlined (magenta; drawn by this script only, not by the game). Rendered by the real game
## (needs a window). A second camera at 4x zoom frames the jelly on plate 1; the game's own camera is unchanged.
## Output: evidence/test-poses/<POSE>-<R|L>.png (400 x 400 crops) and boxes.txt.
const Game = preload("res://game/session.gd")
const POSES := ["IDLE", "BORED", "SCOOT-A", "SCOOT-B", "ANTIC", "RISE", "FALL", "LAND", "WORRY", "SPLAT", "RESPAWN", "CELEBRATE"]
var game: Node2D
var output: String

class BoxOverlay extends Node2D:
	var player: CharacterBody2D
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var b: Vector2 = player.box
		draw_rect(Rect2(-b.x / 2.0, -b.y, b.x, b.y), Color(1, 0, 1), false, 0.75)

func _initialize() -> void:
	call_deferred("run")

func step(n: int = 1) -> void:
	for i in range(n):
		await physics_frame
		await process_frame

func run() -> void:
	output = ProjectSettings.globalize_path("res://../evidence/test-poses")
	DirAccess.make_dir_recursive_absolute(output)
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	game.start_session()
	await step(5)
	for f in game.forks:
		if f:
			f.held = true
	var p: CharacterBody2D = game.player
	p.enabled = false
	var overlay := BoxOverlay.new()
	overlay.player = p
	overlay.z_index = 10
	p.add_child(overlay)
	var cam := Camera2D.new()
	cam.zoom = Vector2(4, 4)
	cam.position = p.position + Vector2(0, -36)
	game.add_child(cam)
	cam.make_current()
	var lines: Array[String] = ["pose | facing | sprite flip_h | collision box (px) | box kind"]
	for pose in POSES:
		for facing in [1.0, -1.0]:
			p.facing = facing
			p.override_pose = pose
			p._update_pose()
			await step(3)
			p.override_pose = pose   # the session resets the override each tick in PLAYING; set it again
			p._update_pose()
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			var c := img.get_size() / 2
			img = img.get_region(Rect2i(c.x - 200, c.y - 200, 400, 400))
			var label := "%s-%s" % [pose, "R" if facing > 0 else "L"]
			img.save_png(output + "/" + label + ".png")
			lines.append("%s | %s | %s | %s | %s" % [pose, "right" if facing > 0 else "left", p.sprite.flip_h, str(p.box), "low" if p.box.y < 50 else "standing"])
	var file := FileAccess.open(output + "/boxes.txt", FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("\n".join(lines))
	print("POSE CAPTURES: %d" % (POSES.size() * 2))
	game.queue_free()
	for i in range(30):
		await process_frame
	quit()
