extends SceneTree
## Jelly Hop slice checks: poses and boxes, forks and respawn, camera, flow, and the sound and
## music placeholders (SLICE-BRIEF.md §8, predicted failures 5-9, 12, 13). Scripted input only;
## this is not human playtesting.
const Game = preload("res://game/session.gd")
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
	await poses()
	await fork_geometry()
	await respawn_safe_window()
	await held_jump_through_splat()
	await intro_and_skip()
	await shake_rules()
	await look_ahead()
	await win_and_restart()
	await trigger_counts()
	await offscreen_shadow_silent()
	await intro_shadows_and_quiet_start()
	await overlapping_shadows()
	await music_states()
	await mute_changes_nothing()
	await hud_text()
	var report := {"scope":"Jelly Hop slice checks (scripted input); not human playtesting", "engine":Engine.get_version_info().string,"created_at":Time.get_datetime_string_from_system(true),"results":results,"failures":failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/slice-" + str(Time.get_unix_time_from_system()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("SLICE TESTS: %d checks / %d failures" % [results.size(), failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

# ---------------------------------------------------------------- poses (CHARACTER-SHEET.md)

func box_of(p: CharacterBody2D) -> Vector2:
	return (p.collider.shape as RectangleShape2D).size

func poses() -> void:
	await fresh()
	var p: CharacterBody2D = game.player
	# Resting cube on screen: the IDLE art's opaque height x scale should be about 64 px.
	var used := (p.textures["IDLE"] as Texture2D).get_image().get_used_rect()
	var on_screen := Vector2(used.size) * T.JELLY_SCALE
	check("pose-idle-size-64", absf(on_screen.y - 64.0) <= 3.0 and absf(on_screen.x - 64.0) <= 6.0, {"idle_art_px":str(used.size),"on_screen":str(on_screen)})
	# Bottom of the art is flush with the box bottom (the body's origin).
	var art_bottom: float = (float(used.end.y) - T.JELLY_ANCHOR.y) * T.JELLY_SCALE
	check("pose-bottom-flush", absf(art_bottom) <= 0.5, {"art_bottom_minus_box_bottom_px":art_bottom})
	check("pose-idle", p.pose == "IDLE" and box_of(p) == Vector2(52, 58), {"pose":p.pose,"box":str(box_of(p))})
	await steps(T.ticks(T.BORED_DELAY) + 2)
	check("pose-bored-after-delay", p.pose == "BORED" and box_of(p) == Vector2(52, 44), {"pose":p.pose,"box":str(box_of(p)),"delay_s":T.BORED_DELAY})
	p.worried = true
	await steps(1)
	check("pose-worry-overrides-bored", p.pose == "WORRY" and box_of(p) == Vector2(52, 58), {"pose":p.pose,"box":str(box_of(p))})
	p.worried = false
	p.test_axis = 1
	var scoots := {}
	for i in range(20):
		await steps(1)
		scoots[p.pose] = true
	p.test_axis = 0
	check("pose-scoot-loop", scoots.has("SCOOT-A") and scoots.has("SCOOT-B") and box_of(p) == Vector2(52, 58), {"seen":scoots.keys()})
	await steps(10)
	p.test_axis = -1
	await steps(4)
	p.test_axis = 0
	await steps(10)
	check("pose-flip-keeps-facing", p.sprite.flip_h and p.pose == "IDLE", {"flip_h":p.sprite.flip_h,"pose":p.pose})
	var seq: Array[String] = []
	var boxes: Dictionary = {}
	p.test_jump_pressed = true
	for i in range(70):
		await steps(1)
		if seq.is_empty() or seq.back() != p.pose:
			seq.append(p.pose)
			boxes[p.pose] = str(box_of(p))
	check("pose-hop-sequence", seq.slice(0, 5) == ["ANTIC", "RISE", "FALL", "LAND", "IDLE"], {"sequence":seq,"boxes":boxes})
	check("pose-hop-boxes", boxes.get("ANTIC") == str(Vector2(52, 58)) and boxes.get("RISE") == str(Vector2(52, 58)) and boxes.get("FALL") == str(Vector2(52, 58)) and boxes.get("LAND") == str(Vector2(52, 44)), {"boxes":boxes})
	game.resolve_contacts("sauce", false)
	await steps(2)
	check("pose-splat", p.pose == "SPLAT", {"pose":p.pose})
	await steps(T.ticks(T.SPLAT_TIME) + 1)
	check("pose-respawn", p.pose == "RESPAWN", {"pose":p.pose})
	await steps(T.ticks(T.REFORM_TIME) + 2)
	check("pose-control-returns-idle", p.pose == "IDLE" and game.state == Game.State.PLAYING, {"pose":p.pose,"state":game.state})

# ---------------------------------------------------------------- forks

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func hold_fork_down(fork) -> void:
	# Fixture: put the fork at the start of its hold (tines on the plate) and freeze it there.
	fork.t = fork.safe_ticks + fork.shadow_ticks + fork.down_ticks
	fork._apply()
	fork.held = true

func overlaps(shape: Shape2D, at: Vector2, mask: int, areas: bool, bodies: bool) -> Array:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, at)
	q.collision_mask = mask
	q.collide_with_areas = areas
	q.collide_with_bodies = bodies
	var hits := []
	for r in game.get_world_2d().direct_space_state.intersect_shape(q, 32):
		hits.append(r.collider)
	return hits

func fork_geometry() -> void:
	await fresh()
	game.player.enabled = false
	var land_y := T.plate_landing_y()
	var half_plate := T.plate_landing_half_width()
	var bands := {}
	var widths := {}
	var tops := {}
	for fork in game.forks:
		if fork == null:
			continue
		hold_fork_down(fork)
	await physics_frame
	for fork in game.forks:
		if fork == null:
			continue
		var center: float = fork.global_position.x
		# Hit polygons in world space: their x range against the visible tines and the plate.
		var lo := INF
		var hi := -INF
		var lowest := -INF
		for poly in fork.hit_area.get_children():
			for p in poly.polygon:
				var g: Vector2 = poly.global_transform * p
				lo = minf(lo, g.x)
				hi = maxf(hi, g.x)
				lowest = maxf(lowest, g.y)
		var visible_lo: float = center + (T.FORK_TINE_ART_SPAN.x - 167.5) * fork.scale_factor
		var visible_hi: float = center + (T.FORK_TINE_ART_SPAN.y + 1.0 - 167.5) * fork.scale_factor
		widths[fork.plate_index] = {"hit":[snappedf(lo - center, 0.1), snappedf(hi - center, 0.1)], "visible_tines":[snappedf(visible_lo - center, 0.1), snappedf(visible_hi - center, 0.1)], "plate_landing":[-half_plate, half_plate], "tips_y":snappedf(lowest, 0.1), "landing_y":snappedf(land_y, 0.1)}
		# Fork art top must stay above the screen even with the tines down.
		tops[fork.plate_index] = snappedf(fork.sprite.global_position.y - 1258.0 * fork.scale_factor, 0.1)
		# Safe band: every x where the plate holds the jelly up (box overlaps the plate's
		# landing surface) but the box does not overlap the tines. Both boxes, 1 px steps.
		var band := 0
		for size in [Vector2(52, 58), Vector2(52, 44)]:
			var shape := RectangleShape2D.new()
			shape.size = size
			var foot := RectangleShape2D.new()
			foot.size = Vector2(size.x, 2.0)
			var x: float = center - half_plate - size.x / 2.0
			while x <= center + half_plate + size.x / 2.0:
				var supported := overlaps(foot, Vector2(x, land_y + 0.5), 1, false, true).has(game.plates[fork.plate_index].body)
				var hit := overlaps(shape, Vector2(x, land_y - size.y / 2.0), 8, true, false).has(fork.hit_area)
				if supported and not hit:
					band += 1
				x += 1.0
		bands[fork.plate_index] = band
	var all_zero := true
	var widths_ok := true
	for i in bands:
		all_zero = all_zero and bands[i] == 0
		var w: Dictionary = widths[i]
		# No wider than the visible tines (1 px tolerance for the 3-row outline sampling),
		# and at least as wide as the plate's landing surface; tips reach the landing surface.
		widths_ok = widths_ok and w.hit[0] >= w.visible_tines[0] - 1.0 and w.hit[1] <= w.visible_tines[1] + 1.0
		widths_ok = widths_ok and w.hit[0] <= -half_plate and w.hit[1] >= half_plate and absf(w.tips_y - land_y) <= 1.0
	check("fork-edge-band-0px", all_zero and bands.size() == 5, {"safe_band_px_per_plate":bands})
	# Negative control: the same band count with plate 2's hit area squeezed to the Batch 2
	# fork size (70 px head) must find a safe band, so the 0 px result above is not vacuous.
	var control_fork = game.forks[1]
	control_fork.hit_area.scale = Vector2(70.0 / T.FORK_TINE_SPAN_PX, 1.0)
	await physics_frame
	var control_band := 0
	var cshape := RectangleShape2D.new()
	cshape.size = Vector2(52, 58)
	var cfoot := RectangleShape2D.new()
	cfoot.size = Vector2(52, 2)
	var cx: float = control_fork.global_position.x - half_plate - 26.0
	while cx <= control_fork.global_position.x + half_plate + 26.0:
		if overlaps(cfoot, Vector2(cx, land_y + 0.5), 1, false, true).has(game.plates[1].body) and not overlaps(cshape, Vector2(cx, land_y - 29.0), 8, true, false).has(control_fork.hit_area):
			control_band += 1
		cx += 1.0
	control_fork.hit_area.scale = Vector2.ONE
	check("fork-edge-band-control-70px", control_band > 0, {"safe_band_px_with_70px_tines":control_band})
	check("fork-hit-equals-tines", widths_ok, {"per_plate":widths})
	var tops_ok := true
	for i in tops:
		tops_ok = tops_ok and tops[i] < 0.0
	check("fork-top-off-screen", tops_ok, {"fork_art_top_y_with_tines_down":tops})

func respawn_safe_window() -> void:
	# §8 #5 / failure #12: a real fork splat on plate 2, then the checkpoint fork must be at
	# the start of its safe window when control returns; other forks keep their rhythm.
	await fresh()
	var fork2 = game.forks[1]
	var land_y := T.plate_landing_y()
	game.player.position = Vector2(game.plates[1].center, land_y - 30)
	await steps(20)
	var cp: int = game.checkpoint
	var ticks := 0
	while game.state == Game.State.PLAYING and ticks < 600:
		await steps(1)
		ticks += 1
	var cause: String = game.splat_cause
	var others_before := {}
	for f in game.forks:
		if f and f != fork2:
			others_before[f.plate_index] = f.t
	var waited := 0
	while game.state != Game.State.PLAYING and waited < 200:
		await steps(1)
		waited += 1
	var others_ok := true
	var drift := {}
	for f in game.forks:
		if f and f != fork2:
			var expected: int = posmod(others_before[f.plate_index] + waited, f.period)
			drift[f.plate_index] = f.t - expected
			others_ok = others_ok and f.t == expected
	check("respawn-checkpoint-fork-safe", cp == 1 and cause == "fork" and fork2.phase() == fork2.Phase.SAFE and fork2.t <= 1 and not fork2.held, {"checkpoint":cp,"cause":cause,"fork_phase":fork2.phase(),"fork_t":fork2.t,"held":fork2.held})
	check("respawn-other-forks-keep-rhythm", others_ok, {"t_minus_expected":drift,"ticks_waited":waited})
	# The safe window then lasts its full length: the jelly is not hit while standing still.
	var stood := 0
	while game.state == Game.State.PLAYING and stood < fork2.safe_ticks:
		await steps(1)
		stood += 1
	check("respawn-safe-window-lasts", game.state == Game.State.PLAYING and stood == fork2.safe_ticks, {"stood_ticks":stood,"safe_ticks":fork2.safe_ticks})

func held_jump_through_splat() -> void:
	# §8 #3 / failure #7: real key events. Jump held through the splat and re-form, plus extra
	# presses during the lock: no hop until a fresh press after control returns.
	await fresh()
	game.player.test_control = false
	key(KEY_SPACE, true)
	await steps(2)
	var jumps_before: int = game.player.jumps
	var splat_frame := Engine.get_physics_frames()
	game.resolve_contacts("sauce", false)
	await steps(10)
	key(KEY_W, true)       # presses during the lock are ignored
	await steps(2)
	key(KEY_W, false)
	await steps(T.ticks(T.SPLAT_TIME) + T.ticks(T.REFORM_TIME))
	var returned: bool = game.state == Game.State.PLAYING
	await steps(30)        # still holding Space after control returns
	var jumps_while_held: int = game.player.jumps
	var hops_while_held: int = hop_sounds_after(splat_frame)
	key(KEY_SPACE, false)
	await steps(3)
	key(KEY_SPACE, true)   # fresh press
	await steps(3)
	key(KEY_SPACE, false)
	await steps(2)
	var hops_sfx_before_fresh: int = hop_sounds_after(splat_frame)
	check("held-jump-through-splat-no-hop", returned and jumps_while_held == 0 and hops_while_held == 0, {"control_returned":returned,"jumps_while_held":jumps_while_held,"sfx_hop_while_held":hops_while_held,"jumps_before_splat":jumps_before})
	check("fresh-press-hops-after-lock", game.player.jumps == 1 and hops_sfx_before_fresh == 1, {"jumps_after_fresh_press":game.player.jumps,"sfx_hop_after_splat":hops_sfx_before_fresh})
	game.player.test_control = true

# ---------------------------------------------------------------- camera and flow

func tap(code: Key) -> void:
	key(code, true)
	await steps(2)
	key(code, false)
	await steps(2)

func new_intro_game() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await process_frame
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	await steps(2)

func intro_and_skip() -> void:
	# Panel 1: the pan starts at the dome and ends at the jelly; movement is locked.
	await new_intro_game()
	var start_view: Rect2 = game.view_rect()
	var dome_seen := start_view.has_point(Vector2(T.dome_left() + T.dome_width() / 2.0, T.TABLE_TOP - 50.0))
	var x0: float = game.player.position.x
	await steps(T.ticks(T.INTRO_PAN) / 2)
	var mid_state: int = game.state
	var mid_cam: float = game.camera.position.x
	await steps(T.ticks(T.INTRO_PAN) / 2 + 3)
	check("intro-pan-dome-to-jelly", dome_seen and mid_state == Game.State.INTRO and mid_cam < start_view.get_center().x and game.state == Game.State.PLAYING and absf(game.camera.position.x - game.camera_target_x()) < 1.0 and game.player.position.x == x0, {"dome_in_first_view":dome_seen,"mid_state":mid_state,"state_after":game.state})
	# §8 #2 / failure #6: skip with the jump key held, and with a quick tap; with a direction held.
	for variant in ["space-held", "space-tap", "d-held"]:
		await new_intro_game()
		await steps(10)
		game.player.test_control = false
		var x_before: float = game.player.position.x
		match variant:
			"space-held":
				key(KEY_SPACE, true)
				await steps(30)
				key(KEY_SPACE, false)
			"space-tap":
				key(KEY_SPACE, true)
				key(KEY_SPACE, false)
				await steps(30)
			"d-held":
				key(KEY_D, true)
				await steps(30)
				key(KEY_D, false)
		await steps(5)
		check("skip-key-no-hop-no-move-" + variant, game.state == Game.State.PLAYING and game.player.jumps == 0 and game.sound.count("SFX-HOP") == 0 and absf(game.player.position.x - x_before) < 0.01, {"state":game.state,"jumps":game.player.jumps,"sfx_hop":game.sound.count("SFX-HOP"),"dx":game.player.position.x - x_before})
	# M and N never skip the intro.
	await new_intro_game()
	await tap(KEY_M)
	await tap(KEY_N)
	check("mute-keys-do-not-skip", game.state == Game.State.INTRO, {"state":game.state})
	await tap(KEY_M)
	await tap(KEY_N)
	game.player.test_control = true

func shake_rules() -> void:
	# §8 #6 / failure #13: sauce splat -> no shake; fork splat -> shake; the jelly never moves.
	await fresh()
	var max_sauce := 0.0
	var sauce_moved := false
	game.resolve_contacts("sauce", false)
	var p0: Vector2 = game.player.position
	for i in range(T.ticks(T.SPLAT_TIME) - 1):
		await steps(1)
		max_sauce = maxf(max_sauce, game.camera.offset.length())
		sauce_moved = sauce_moved or game.player.position != p0
	await steps(T.ticks(T.REFORM_TIME) + 4)
	var max_fork := 0.0
	var fork_moved := false
	game.resolve_contacts("fork", false)
	p0 = game.player.position
	var shapes_before := str(game.player.collider.global_position)
	for i in range(T.ticks(T.SPLAT_TIME) - 1):
		await steps(1)
		max_fork = maxf(max_fork, game.camera.offset.length())
		fork_moved = fork_moved or game.player.position != p0
	var shapes_after := str(game.player.collider.global_position)
	check("shake-none-on-sauce-splat", max_sauce == 0.0 and not sauce_moved, {"max_camera_offset":max_sauce,"jelly_moved":sauce_moved})
	check("shake-on-fork-splat-camera-only", max_fork > 0.0 and max_fork <= T.SHAKE_PX * 1.5 and not fork_moved and shapes_before == shapes_after and game.camera.offset == Vector2.ZERO, {"max_camera_offset":max_fork,"jelly_moved":fork_moved,"collider_before":shapes_before,"collider_after":shapes_after,"offset_after":str(game.camera.offset)})

func look_ahead() -> void:
	# Failure #11: standing at each plate's jump mark, the next plate's full shadow is on screen.
	await fresh()
	var marks := {}
	var ok := true
	for i in range(game.plates.size() - 1):
		var nxt = game.forks[i + 1]
		game.player.position = Vector2(game.plates[i].center + T.plate_landing_half_width() - 12.0, T.plate_landing_y())
		game._set_camera(game.camera_target_x(), false)
		await steps(2)
		var view: Rect2 = game.view_rect()
		var inside: bool = nxt == null or view.encloses(nxt.shadow_rect())
		marks[i + 1] = {"view_x":[view.position.x, view.end.x], "next_shadow":[nxt.shadow_rect().position.x, nxt.shadow_rect().end.x] if nxt else null, "inside":inside}
		ok = ok and inside
	check("look-ahead-next-shadow-on-screen", ok, {"per_plate":marks})

func win_and_restart() -> void:
	# Panel 7: the dome, "SAFE!", the prompt, then any key restarts on plate 1 with no pan.
	await fresh()
	game.player.position = Vector2(T.dome_left() - 30.0, T.TABLE_TOP)
	game.player.test_axis = 1
	var ticks := 0
	while game.state == Game.State.PLAYING and ticks < 120:
		await steps(1)
		ticks += 1
	game.player.test_axis = 0
	var won: bool = game.state == Game.State.WON
	await tap(KEY_SPACE)   # before the prompt: ignored
	var ignored: bool = game.state == Game.State.WON
	await steps(T.ticks(T.PROMPT_DELAY) + 2)
	var dome_center := T.dome_left() + T.dome_width() / 2.0
	check("win-dome-celebrate-prompt", won and ignored and game.prompt_shown and game.player.pose == "CELEBRATE" and absf(game.player.position.x - dome_center) < 1.0, {"won":won,"early_key_ignored":ignored,"prompt":game.prompt_shown,"pose":game.player.pose,"x":game.player.position.x,"dome_center":dome_center})
	# Disturb state first so the reset is visible: a splat count and a checkpoint.
	game.splats = 3
	game.checkpoint = 4
	game.player.test_control = false
	var restart_frame := Engine.get_physics_frames()
	key(KEY_SPACE, true)
	await steps(30)
	key(KEY_SPACE, false)
	await steps(2)
	var restart_hops := hop_sounds_after(restart_frame)
	# Every fork restarted from its fixed starting point at the same moment (same elapsed ticks).
	var elapsed := {}
	for f in game.forks:
		if f:
			elapsed[posmod(f.t - f.offset_ticks, f.period)] = true
	var forks_reset: bool = elapsed.size() == 1 and int(elapsed.keys()[0]) <= 32
	var at_start: bool = game.player.position.distance_to(game.spawn_point(0)) < 1.0
	check("restart-key-no-hop-first-plate-reset", game.state == Game.State.PLAYING and game.player.jumps == 0 and restart_hops == 0 and at_start and game.splats == 0 and game.checkpoint == 0 and forks_reset and not game.prompt_shown, {"state":game.state,"jumps":game.player.jumps,"sfx_hop":restart_hops,"at_first_plate":at_start,"splats":game.splats,"checkpoint":game.checkpoint,"forks_reset":forks_reset,"fork_elapsed_ticks":elapsed.keys()})
	game.player.test_control = true

# ---------------------------------------------------------------- sound and music placeholders

func hop_sounds_after(frame: int) -> int:
	var n := 0
	for c in game.sound.calls:
		if c.id == "SFX-HOP" and c.frame > frame:
			n += 1
	return n

func counts_since(index: int) -> Dictionary:
	var out := {}
	for c in game.sound.calls.slice(index):
		out[c.id] = out.get(c.id, 0) + 1
	return out

func trigger_counts() -> void:
	# §8 #1 / failure #5: each sound fires once per event, from scripted input.
	await fresh()
	hold_all_forks_except([])   # fixture: only the jelly's own sounds in this part
	var p: CharacterBody2D = game.player
	# Rapid hops on plate 1 (no fork): a press every 40 ticks plus extra presses in the air.
	var mark: int = game.sound.calls.size()
	for i in range(5):
		p.test_jump_pressed = true
		await steps(6)
		p.test_jump_pressed = true   # mid-air press: no double jump, no second sound
		await steps(34)
	await steps(20)
	var c := counts_since(mark)
	check("sfx-rapid-hops-once-each", p.jumps == 5 and c.get("SFX-HOP", 0) == 5 and c.get("SFX-LAND", 0) == 5, {"jumps":p.jumps,"counts":c})
	# A held jump: one hop, one landing.
	mark = game.sound.calls.size()
	p.test_jump_pressed = true
	p.test_jump_held = true
	await steps(120)
	p.test_jump_held = false
	await steps(2)
	c = counts_since(mark)
	check("sfx-held-jump-once", c.get("SFX-HOP", 0) == 1 and c.get("SFX-LAND", 0) == 1, {"counts":c})
	# Respawn on a plate is not a landing.
	mark = game.sound.calls.size()
	game.resolve_contacts("sauce", false)
	await steps(T.ticks(T.SPLAT_TIME) + T.ticks(T.REFORM_TIME) + 20)
	c = counts_since(mark)
	check("sfx-respawn-silent", c.get("SFX-LAND", 0) == 0 and c.get("SFX-SPLAT-SAUCE", 0) == 1 and c.size() == 1, {"counts":c})
	# A real fork splat on plate 2: one SFX-SPLAT-FORK, nothing else from the jelly.
	await fresh()
	game.player.position = Vector2(game.plates[1].center, T.plate_landing_y() - 30.0)
	await steps(20)   # the placement drop lands after ~11 ticks; count from after it
	mark = game.sound.calls.size()
	var ticks := 0
	while game.state == Game.State.PLAYING and ticks < 600:
		await steps(1)
		ticks += 1
	await steps(T.ticks(T.SPLAT_TIME) + T.ticks(T.REFORM_TIME) + 5)
	c = counts_since(mark)
	check("sfx-fork-splat-once", game.splat_cause == "fork" and c.get("SFX-SPLAT-FORK", 0) == 1 and c.get("SFX-SPLAT-SAUCE", 0) == 0 and c.get("SFX-LAND", 0) == 0, {"cause":game.splat_cause,"counts":c})
	# A real sauce splat: walk off plate 2 into the sauce in gap 2. No landing sound.
	await fresh()
	game.forks[1].held = true   # fixture: keep plate 2's fork raised so only the sauce matters
	game.player.position = Vector2(game.plates[1].center, T.plate_landing_y() - 30.0)
	await steps(20)   # the placement drop lands after ~11 ticks; count from after it
	mark = game.sound.calls.size()
	game.player.test_axis = 1
	ticks = 0
	while game.state == Game.State.PLAYING and ticks < 120:
		await steps(1)
		ticks += 1
	game.player.test_axis = 0
	await steps(T.ticks(T.SPLAT_TIME) + T.ticks(T.REFORM_TIME) + 5)
	c = counts_since(mark)
	check("sfx-sauce-splat-once-no-land", game.splat_cause == "sauce" and c.get("SFX-SPLAT-SAUCE", 0) == 1 and c.get("SFX-LAND", 0) == 0 and c.get("SFX-SPLAT-FORK", 0) == 0, {"cause":game.splat_cause,"counts":c})
	# A win: one SFX-WIN, even if the goal is touched again.
	await fresh()
	mark = game.sound.calls.size()
	game.player.position = Vector2(T.dome_left() - 30.0, T.TABLE_TOP)
	game.player.test_axis = 1
	await steps(60)
	game.resolve_contacts("", true)
	await steps(30)
	game.player.test_axis = 0
	c = counts_since(mark)
	check("sfx-win-once", game.state == Game.State.WON and c.get("SFX-WIN", 0) == 1, {"state":game.state,"counts":c})
	# The state recorded with each call is the game state at that moment.
	var states_ok := true
	for call in game.sound.calls:
		states_ok = states_ok and call.has("frame") and call.has("state") and call.state != ""
	check("sfx-calls-record-frame-and-state", states_ok and game.sound.calls.size() > 0, {"sample":game.sound.calls.slice(0, 3)})

func hold_all_forks_except(keep: Array) -> void:
	for f in game.forks:
		if f and not f.plate_index in keep:
			f.held = true
			f.t = 0
			f._apply()

func targets_since(mark: int) -> Array:
	var out: Array = []
	for e in game.music.changes.slice(mark):
		if e.has("target"):
			out.append(e.target)
	return out

func offscreen_shadow_silent() -> void:
	# §8 #4 / failure #8, as revised by Kiran on 2026-10-03 (CHANGE-BRIEF.md music rule): a shadow
	# phase that starts off screen never plays SFX-WARN; it dips the music only once any part of
	# it is on screen while it is still warning, and not while it is off screen.
	await fresh()
	hold_all_forks_except([4])   # only plate 5's fork runs
	var fork5 = game.forks[4]
	var ticks := 0
	while fork5.phase() == fork5.Phase.SHADOW and ticks < 600:   # it starts mid-shadow: wait for a new phase
		await steps(1)
		ticks += 1
	var music_mark: int = game.music.changes.size()
	var sound_mark: int = game.sound.calls.size()
	while fork5.phase() != fork5.Phase.SHADOW and ticks < 1200:
		await steps(1)
		ticks += 1
	var started_off: bool = not game.view_rect().intersects(fork5.shadow_rect())
	await steps(10)   # still off screen, still growing
	var off_targets := targets_since(music_mark)
	# Scroll it into view mid-shadow: move the jelly to plate 4 and let the camera follow.
	game.player.position = Vector2(game.plates[3].center, T.plate_landing_y())
	game._set_camera(game.camera_target_x(), false)
	await steps(3)
	var on_now: bool = game.view_rect().intersects(fork5.shadow_rect())
	var still_shadow: bool = fork5.phase() == fork5.Phase.SHADOW
	var on_targets := targets_since(music_mark)
	while fork5.is_warning():
		await steps(1)
	await steps(5)
	var c := counts_since(sound_mark)
	var all_targets := targets_since(music_mark)
	check("offscreen-shadow-no-warn-dip-once-on-screen", started_off and not "warning" in off_targets and on_now and still_shadow and on_targets == ["warning"] and all_targets == ["warning", "normal"] and c.get("SFX-WARN", 0) == 0, {"started_off_screen":started_off,"music_while_off_screen":off_targets,"scrolled_into_view_while_growing":on_now and still_shadow,"music_once_on_screen":on_targets,"music_through_strike":all_targets,"sfx_warn":c.get("SFX-WARN", 0)})
	# Control: the same fork's next shadow phase, starting on screen, does warn and dip.
	sound_mark = game.sound.calls.size()
	music_mark = game.music.changes.size()
	ticks = 0
	while fork5.phase() != fork5.Phase.SHADOW and ticks < 600:
		await steps(1)
		ticks += 1
	await steps(3)
	c = counts_since(sound_mark)
	check("onscreen-shadow-warns-and-dips", c.get("SFX-WARN", 0) == 1 and "warning" in targets_since(music_mark), {"sfx_warn":c.get("SFX-WARN", 0),"music_targets":targets_since(music_mark)})

func intro_shadows_and_quiet_start() -> void:
	# Kiran, 2026-10-03: forks off screen at the start begin partway into their shadow phase,
	# frozen during the pan, so the intro shows shadows (panel 1); none is on screen in its
	# shadow phase when play starts, and nothing warns at the start.
	await new_intro_game()
	var seen := {}
	var frozen := true
	var t_start := {}
	for f in game.forks:
		if f:
			t_start[f.plate_index] = f.t
	var intro_ticks := 0
	while true:
		await steps(1)
		if game.state != Game.State.INTRO:
			break   # the pan ended; forks start moving with play
		intro_ticks += 1
		for f in game.forks:
			if f and f.shadow_amount() > 0.0 and game.view_rect().intersects(f.shadow_rect()):
				seen[f.plate_index + 1] = snappedf(f.shadow_amount(), 0.01)
			frozen = frozen and (f == null or f.t == t_start[f.plate_index])
	var intro_warns: int = game.sound.count("SFX-WARN")
	check("intro-shows-shadows-frozen", seen.size() >= 1 and frozen and intro_warns == 0 and intro_ticks >= T.ticks(T.INTRO_PAN) / 2, {"plates_with_visible_shadow_during_pan":seen,"forks_frozen":frozen,"intro_ticks_checked":intro_ticks,"sfx_warn":intro_warns})
	var sound_mark: int = game.sound.calls.size() - intro_warns
	var on_screen_in_shadow := []
	var off_screen_in_shadow := []
	for f in game.forks:
		if f and f.phase() == f.Phase.SHADOW:
			if game.view_rect().intersects(f.shadow_rect()):
				on_screen_in_shadow.append(f.plate_index + 1)
			else:
				off_screen_in_shadow.append(f.plate_index + 1)
	await steps(5)
	var c := counts_since(sound_mark)
	check("play-starts-quiet-no-onscreen-shadow", on_screen_in_shadow.is_empty() and not off_screen_in_shadow.is_empty() and c.get("SFX-WARN", 0) == 0 and game.music.target == "normal", {"on_screen_in_shadow":on_screen_in_shadow,"off_screen_in_shadow":off_screen_in_shadow,"sfx_warn_first_5_ticks":c.get("SFX-WARN", 0),"music":game.music.target})
	# The same after a replay from the dome (no pan; every cycle resets).
	game.resolve_contacts("", true)
	await steps(T.ticks(T.PROMPT_DELAY) + 2)
	sound_mark = game.sound.calls.size()
	await tap(KEY_ENTER)
	on_screen_in_shadow = []
	for f in game.forks:
		if f and f.phase() == f.Phase.SHADOW and game.view_rect().intersects(f.shadow_rect()):
			on_screen_in_shadow.append(f.plate_index + 1)
	await steps(3)
	c = counts_since(sound_mark)
	check("replay-starts-quiet-no-onscreen-shadow", game.state == Game.State.PLAYING and on_screen_in_shadow.is_empty() and c.get("SFX-WARN", 0) == 0 and game.music.target == "normal", {"on_screen_in_shadow":on_screen_in_shadow,"sfx_warn":c.get("SFX-WARN", 0),"music":game.music.target})

func overlapping_shadows() -> void:
	# §8 #7 / failure #9: two on-screen shadows overlap; the music log must show one dip that
	# starts with the first and ends after the last (no flicker, no stuck dip).
	await fresh()
	hold_all_forks_except([1, 2])
	var f2 = game.forks[1]
	var f3 = game.forks[2]
	f2.t = f2.safe_ticks - 1          # enters its shadow phase on the next tick
	f3.t = f3.safe_ticks - 31         # enters 30 ticks later, while f2 is still warning
	var music_mark: int = game.music.changes.size()
	var sound_mark: int = game.sound.calls.size()
	var first_start := -1
	var last_end := -1
	var frames_warning := []
	# Window: until both forks have started and finished their warning, plus 20 ticks
	# (stops before either fork's next cycle).
	var seen_f3 := false
	var after := 0
	while after < 20 and frames_warning.size() < 600:
		await steps(1)
		seen_f3 = seen_f3 or f3.is_warning()
		if seen_f3 and not f2.is_warning() and not f3.is_warning():
			after += 1
		var w: int = game.warnings_on_screen()
		frames_warning.append(w)
		if w > 0 and first_start < 0:
			first_start = Engine.get_physics_frames()
		if w > 0:
			last_end = Engine.get_physics_frames() + 1
	var entries: Array = game.music.changes.slice(music_mark)
	var targets: Array = []
	for e in entries:
		targets.append(e.target)
	var overlap := 0
	for w in frames_warning:
		if w == 2:
			overlap += 1
	var ok: bool = targets == ["warning", "normal"] and overlap > 0 and entries[0].frame == first_start and entries[1].frame == last_end and game.music.target == "normal"
	check("overlapping-shadows-one-dip", ok, {"music_entries":entries,"overlap_ticks":overlap,"first_warning_frame":first_start,"last_warning_end_frame":last_end,"sfx_warn":counts_since(sound_mark).get("SFX-WARN", 0)})
	check("overlapping-shadows-two-warns", counts_since(sound_mark).get("SFX-WARN", 0) == 2, {"sfx_warn":counts_since(sound_mark).get("SFX-WARN", 0)})

func music_states() -> void:
	# CHANGE-BRIEF.md music behaviour, from the change log.
	await new_intro_game()
	await steps(5)
	var intro_targets: Array = game.music.targets()
	var restarted: bool = game.music.changes[0].has("event")
	await tap(KEY_ENTER)
	await steps(2)
	hold_all_forks_except([])   # fixture: isolate the splat/pause/win transitions from warnings
	check("music-intro-quieter-then-normal", restarted and intro_targets == ["intro"] and game.music.target == "normal", {"changes":game.music.changes})
	var mark: int = game.music.changes.size()
	game.resolve_contacts("sauce", false)
	await steps(T.ticks(T.SPLAT_TIME) + T.ticks(T.REFORM_TIME) + 3)
	var t1: Array = []
	for e in game.music.changes.slice(mark):
		t1.append(e.target)
	check("music-splat-dip-back-on-respawn", t1 == ["splat", "normal"], {"targets":t1})
	mark = game.music.changes.size()
	await tap(KEY_ESCAPE)
	await steps(3)
	await tap(KEY_ESCAPE)
	await steps(3)
	var t2: Array = []
	for e in game.music.changes.slice(mark):
		t2.append(e.target)
	check("music-pause-quiet-muffled", t2 == ["pause", "normal"] and T.MUSIC.pause.cutoff < 20000.0, {"targets":t2})
	mark = game.music.changes.size()
	game.resolve_contacts("", true)
	await steps(T.ticks(T.PROMPT_DELAY) + 3)
	await tap(KEY_ENTER)
	await steps(3)
	var t3: Array = []
	for e in game.music.changes.slice(mark):
		t3.append(e.get("target", e.get("event")))
	check("music-win-fade-quiet-restart", t3 == ["win_fade", "end_quiet", "restart", "normal"], {"sequence":t3})
	# The bus really moves: after the ramp the Music bus volume and cutoff match the target.
	await steps(T.ticks(T.MUSIC_RAMP) + 5)
	var bus := AudioServer.get_bus_index("Music")
	var db := AudioServer.get_bus_volume_db(bus)
	var cutoff: float = (AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter).cutoff_hz
	check("music-bus-follows-target", absf(db - T.MUSIC.normal.db) < 0.01 and absf(cutoff - T.MUSIC.normal.cutoff) < 1.0 and AudioServer.get_bus_index("SFX") >= 0, {"music_db":db,"cutoff_hz":cutoff})

func mute_changes_nothing() -> void:
	# M and N mute buses only: game state, forks, the jelly and the logs are unchanged.
	await fresh()
	game.player.test_control = false
	await steps(5)
	var before := {"state":game.state, "x":game.player.position.x, "sound":game.sound.calls.size(), "music":game.music.target}
	var t_before := []
	for f in game.forks:
		if f:
			t_before.append(f.t)
	var frame0 := Engine.get_physics_frames()
	await tap(KEY_M)
	await tap(KEY_N)
	var master_muted := AudioServer.is_bus_mute(0)
	var music_muted := AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	await tap(KEY_M)
	await tap(KEY_N)
	var elapsed := Engine.get_physics_frames() - frame0
	var forks_ok := true
	var i := 0
	for f in game.forks:
		if f:
			forks_ok = forks_ok and f.t == posmod(t_before[i] + elapsed, f.period)
			i += 1
	var after := {"state":game.state, "x":game.player.position.x, "sound":game.sound.calls.size(), "music":game.music.target}
	check("mute-changes-no-state", master_muted and music_muted and not AudioServer.is_bus_mute(0) and before == after and forks_ok, {"before":before,"after":after,"forks_kept_rhythm":forks_ok,"master_muted":master_muted,"music_muted":music_muted})
	game.player.test_control = true

# ---------------------------------------------------------------- HUD

func shown() -> Array:
	var out := []
	for line in game.hud.lines():
		out.append(line.text)
	return out

func hud_text() -> void:
	await new_intro_game()
	var intro := shown()
	await tap(KEY_ENTER)
	var playing := shown()
	await tap(KEY_ESCAPE)
	var paused := shown()
	await tap(KEY_ESCAPE)
	await tap(KEY_M)
	await tap(KEY_N)
	var muted := shown()
	await tap(KEY_M)
	await tap(KEY_N)
	game.resolve_contacts("", true)
	await steps(2)
	var won := shown()
	await steps(T.ticks(T.PROMPT_DELAY) + 2)
	var prompt := shown()
	check("hud-text-per-state", intro.has("JELLY HOP") and intro.has("any key skips the intro") and playing.is_empty() and paused.has("PAUSED") and paused.has("Esc to resume") and muted.has("MUTED (M)") and muted.has("MUSIC OFF (N)") and won == ["SAFE!"] and prompt == ["SAFE!", "press any key to play again"], {"intro":intro,"playing":playing,"paused":paused,"muted":muted,"won":won,"prompt":prompt})
