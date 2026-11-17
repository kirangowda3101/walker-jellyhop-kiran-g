extends SceneTree
## A7 Step 4: read-back of the saved land clip and the landing rig in player_visuals.tscn
## (CHANGE-BRIEF.md, "Rig design", "Scene, authority and states", "Clocks and boundaries").
## Loads the scene from its file, instantiates it under root, inspects it and quits.
## Read-only: builds, keys, plays and seeks nothing. Headless structure checks; not a render
## check and not human playtesting.

const SCENE_PATH := "res://features/player/player_visuals.tscn"
const LAND_PATH := "res://animations/land.tres"
const IDLE_PATH := "res://assets/art/CHAR-IDLE.png"
const P_LOWER_SCALE := "FacingPivot/LandRig/LowerPivot:scale"
const P_UPPER_POS := "FacingPivot/LandRig/UpperPivot:position"
const P_UPPER_SCALE := "FacingPivot/LandRig/UpperPivot:scale"
const P_FORBIDDEN := "FacingPivot/LandRig/LowerPivot:position"
const TIME_TOL := 0.5 / 60.0
const VAL_TOL := 1e-4
const SEAM_TOL := 1e-3
const REST_Y := -20.14

const KEY_TIMES := [0.0, 2.0 / 60.0, 4.0 / 60.0, 8.0 / 60.0]
const KEY_TRANSITIONS := [2.0, 1.0, 0.5, 1.0]
const KEY_VALUES := {
	P_LOWER_SCALE: [Vector2(1.05, 0.85), Vector2(1.15, 0.60), Vector2(1.15, 0.60), Vector2(1.0, 1.0)],
	P_UPPER_POS: [Vector2(0, -17.119), Vector2(0, -12.084), Vector2(0, -12.084), Vector2(0, -20.14)],
	P_UPPER_SCALE: [Vector2(1.05, 0.90), Vector2(1.15, 0.73), Vector2(1.15, 0.73), Vector2(1.0, 1.0)],
}

var checks := 0
var failures := 0

func check(id: String, passed: bool, observed: String) -> void:
	checks += 1
	if not passed:
		failures += 1
	print("%s %s: %s" % ["PASS" if passed else "FAIL", id, observed])

func near(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol

func near2(a: Vector2, b: Vector2, tol: float) -> bool:
	return absf(a.x - b.x) <= tol and absf(a.y - b.y) <= tol

func v2s(v: Vector2) -> String:
	return "(%.6f, %.6f)" % [v.x, v.y]

## From the A7 assignment handout, unchanged (copied from test_a7_scoot_readback.gd).
static func track_problems(player: AnimationPlayer) -> Array[String]:
	var problems: Array[String] = []
	var root := player.get_node_or_null(player.root_node)
	if root == null:
		problems.append("root_node %s resolves to nothing" % player.root_node)
		return problems
	for clip_name in player.get_animation_list():
		var clip := player.get_animation(clip_name)
		for t in clip.get_track_count():
			var path := clip.track_get_path(t)
			var node := root.get_node_or_null(NodePath(path.get_concatenated_names()))
			if node == null:
				problems.append("%s track %d: no node at %s" % [clip_name, t, path])
				continue
			if path.get_subname_count() == 0:
				continue
			var sub := path.get_subname(0)
			match clip.track_get_type(t):
				Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D:
					var skeleton := node as Skeleton3D
					if skeleton == null or skeleton.find_bone(sub) == -1:
						problems.append("%s track %d: no bone %s on %s" % [clip_name, t, sub, node.name])
				Animation.TYPE_BLEND_SHAPE:
					var mesh := node as MeshInstance3D
					if mesh == null or mesh.find_blend_shape_by_name(sub) == -1:
						problems.append("%s track %d: no blend shape %s on %s" % [clip_name, t, sub, node.name])
				_:
					if not (sub in node):
						problems.append("%s track %d: %s has no property %s" % [clip_name, t, node.name, sub])
	return problems

func _initialize() -> void:
	call_deferred("run")

func has_prop(cls: String, prop: String) -> bool:
	for p in ClassDB.class_get_property_list(cls, true):
		if p["name"] == prop:
			return true
	return false

var has_interpolate := false

func check_classdb() -> void:
	print("ENGINE %s" % Engine.get_version_info().string)
	for pair in [["Animation", "loop_mode"], ["Animation", "step"], ["Animation", "length"],
			["Sprite2D", "region_enabled"], ["Sprite2D", "region_rect"], ["Sprite2D", "offset"],
			["Sprite2D", "centered"], ["CanvasItem", "texture_filter"]]:
		check("classdb-property %s.%s" % pair, has_prop(pair[0], pair[1]), "declared on %s (no_inheritance)" % pair[0])
	for pair in [["Animation", "LOOP_NONE"], ["Animation", "UPDATE_CONTINUOUS"], ["Animation", "INTERPOLATION_LINEAR"],
			["Animation", "TYPE_VALUE"], ["CanvasItem", "TEXTURE_FILTER_LINEAR_WITH_MIPMAPS"]]:
		var ok := ClassDB.class_has_integer_constant(pair[0], pair[1])
		check("classdb-constant %s.%s" % pair, ok, "value %d" % ClassDB.class_get_integer_constant(pair[0], pair[1]) if ok else "missing")
	for pair in [["Animation", "value_track_get_update_mode"], ["Animation", "track_get_interpolation_type"],
			["Animation", "track_get_key_transition"], ["Animation", "track_get_key_time"]]:
		check("classdb-method %s.%s" % pair, ClassDB.class_has_method(pair[0], pair[1]), "")
	has_interpolate = ClassDB.class_has_method("Animation", "value_track_interpolate")
	check("classdb-method Animation.value_track_interpolate", has_interpolate, "present" if has_interpolate else "MISSING on this build; between-key samples not taken")

func run() -> void:
	check_classdb()

	var packed := load(SCENE_PATH) as PackedScene
	check("scene-loads", packed != null, SCENE_PATH)
	if packed == null:
		finish()
		return
	var visuals := packed.instantiate()
	root.add_child(visuals)

	# --- Rig nodes
	var land_rig := visuals.get_node_or_null("FacingPivot/LandRig")
	var lower_pivot := visuals.get_node_or_null("FacingPivot/LandRig/LowerPivot") as Node2D
	var upper_pivot := visuals.get_node_or_null("FacingPivot/LandRig/UpperPivot") as Node2D
	var lower_sprite := visuals.get_node_or_null("FacingPivot/LandRig/LowerPivot/LowerSprite") as Sprite2D
	var upper_sprite := visuals.get_node_or_null("FacingPivot/LandRig/UpperPivot/UpperSprite") as Sprite2D
	check("LandRig Node2D under FacingPivot", land_rig != null and land_rig.get_class() == "Node2D" and str(land_rig.get_parent().name) == "FacingPivot", str(land_rig))
	check("LowerPivot Node2D under LandRig", lower_pivot != null and lower_pivot.get_class() == "Node2D", str(lower_pivot))
	check("UpperPivot Node2D under LandRig", upper_pivot != null and upper_pivot.get_class() == "Node2D", str(upper_pivot))
	check("LowerSprite Sprite2D under LowerPivot", lower_sprite != null and lower_sprite.get_class() == "Sprite2D", str(lower_sprite))
	check("UpperSprite Sprite2D under UpperPivot", upper_sprite != null and upper_sprite.get_class() == "Sprite2D", str(upper_sprite))
	var scripted: Array[String] = []
	var stack: Array[Node] = [visuals]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.get_script() != null:
			scripted.append(str(visuals.get_path_to(n)))
		stack.append_array(n.get_children())
	check("no scripts on any node", scripted.is_empty(), str(scripted))
	if lower_pivot == null or upper_pivot == null or lower_sprite == null or upper_sprite == null:
		finish()
		return

	check("LowerPivot rest position (0, 0)", lower_pivot.position == Vector2.ZERO, v2s(lower_pivot.position))
	check("LowerPivot rest scale (1, 1)", lower_pivot.scale == Vector2.ONE, v2s(lower_pivot.scale))
	check("UpperPivot rest position (0, -20.14)", near2(upper_pivot.position, Vector2(0, REST_Y), VAL_TOL), v2s(upper_pivot.position))
	check("UpperPivot rest scale (1, 1)", upper_pivot.scale == Vector2.ONE, v2s(upper_pivot.scale))

	for entry in [["LowerSprite", lower_sprite, Rect2(0, 622, 1024, 402), Vector2(-512, -190)],
			["UpperSprite", upper_sprite, Rect2(0, 0, 1024, 622), Vector2(-512, -622)]]:
		var nm: String = entry[0]
		var s: Sprite2D = entry[1]
		var tex_path := s.texture.resource_path if s.texture != null else "<null>"
		check("%s texture path" % nm, tex_path == IDLE_PATH, tex_path)
		check("%s region_enabled true" % nm, s.region_enabled == true, str(s.region_enabled))
		check("%s region_rect %s" % [nm, entry[2]], s.region_rect == entry[2], str(s.region_rect))
		check("%s offset %s" % [nm, entry[3]], s.offset == entry[3], str(s.offset))
		check("%s centered false" % nm, s.centered == false, str(s.centered))
		check("%s position (0, 0)" % nm, s.position == Vector2.ZERO, v2s(s.position))
		check("%s scale (0.106, 0.106)" % nm, s.scale.is_equal_approx(Vector2(0.106, 0.106)), v2s(s.scale))
		check("%s texture_filter LINEAR_WITH_MIPMAPS" % nm, s.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "%d (constant %d)" % [s.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS])

	# --- AnimationPlayer and library
	var player := visuals.get_node_or_null("AnimationPlayer") as AnimationPlayer
	check("AnimationPlayer present", player != null, str(player))
	if player == null:
		finish()
		return
	var libs := player.get_animation_library_list()
	check("exactly one library, the default \"\"", libs.size() == 1 and libs[0] == &"", str(libs))
	check("no RESET animation", not player.has_animation(&"RESET"), str(player.get_animation_list()))
	check("clip scoot exists", player.has_animation(&"scoot"), str(player.get_animation_list()))
	check("clip land exists", player.has_animation(&"land"), str(player.get_animation_list()))
	var problems := track_problems(player)
	for p in problems:
		print("  track problem: " + p)
	check("every track of every clip resolves (track_problems)", problems.is_empty(), "%d problems over clips %s" % [problems.size(), player.get_animation_list()])
	if not player.has_animation(&"land"):
		finish()
		return
	var clip := player.get_animation(&"land")
	check("land resource path", clip.resource_path == LAND_PATH, clip.resource_path)

	# --- Clip settings
	check("length 8/60", near(clip.length, 8.0 / 60.0, TIME_TOL), "%.10f vs %.10f" % [clip.length, 8.0 / 60.0])
	check("step 1/60", is_equal_approx(clip.step, 1.0 / 60.0), "%.10f vs %.10f" % [clip.step, 1.0 / 60.0])
	check("loop_mode LOOP_NONE", clip.loop_mode == Animation.LOOP_NONE, "%d (constant %d)" % [clip.loop_mode, Animation.LOOP_NONE])

	# --- Tracks
	var n_tracks := clip.get_track_count()
	check("land has exactly three tracks", n_tracks == 3, str(n_tracks))
	var paths: Array[String] = []
	for t in n_tracks:
		paths.append(str(clip.track_get_path(t)))
	var expected_paths: Array[String] = [P_LOWER_SCALE, P_UPPER_POS, P_UPPER_SCALE]
	var sorted_paths := paths.duplicate()
	sorted_paths.sort()
	var sorted_expected := expected_paths.duplicate()
	sorted_expected.sort()
	check("track paths are exactly the three rig paths", sorted_paths == sorted_expected, str(paths))
	check("no track on %s" % P_FORBIDDEN, not (P_FORBIDDEN in paths), str(paths))

	var idx := {}
	for t in n_tracks:
		var path: String = paths[t]
		idx[path] = t
		var is_value := clip.track_get_type(t) == Animation.TYPE_VALUE
		check("track %d (%s) type TYPE_VALUE" % [t, path], is_value, "%d (constant %d)" % [clip.track_get_type(t), Animation.TYPE_VALUE])
		if is_value:
			var mode := clip.value_track_get_update_mode(t)
			check("track %d (%s) update mode CONTINUOUS" % [t, path], mode == Animation.UPDATE_CONTINUOUS, "%d (constant %d)" % [mode, Animation.UPDATE_CONTINUOUS])
		else:
			check("track %d (%s) update mode CONTINUOUS" % [t, path], false, "not a value track; update mode not read")
		var interp := clip.track_get_interpolation_type(t)
		check("track %d (%s) interpolation LINEAR" % [t, path], interp == Animation.INTERPOLATION_LINEAR, "%d (constant %d)" % [interp, Animation.INTERPOLATION_LINEAR])

	# --- Keys
	var keys_ok := true
	for path in expected_paths:
		if not idx.has(path):
			check("%s present for key checks" % path, false, "missing")
			keys_ok = false
			continue
		var t: int = idx[path]
		var n_keys := clip.track_get_key_count(t)
		check("%s has four keys" % path, n_keys == 4, str(n_keys))
		if n_keys != 4:
			keys_ok = false
			continue
		for k in 4:
			var kt := clip.track_get_key_time(t, k)
			check("%s key %d time %.6f" % [path, k, KEY_TIMES[k]], near(kt, KEY_TIMES[k], TIME_TOL), "%.10f (diff %.10f)" % [kt, kt - KEY_TIMES[k]])
			var kv = clip.track_get_key_value(t, k)
			var vok: bool = typeof(kv) == TYPE_VECTOR2 and near2(kv, KEY_VALUES[path][k], VAL_TOL)
			check("%s key %d value %s" % [path, k, KEY_VALUES[path][k]], vok, "%s (type %s)" % [v2s(kv) if typeof(kv) == TYPE_VECTOR2 else str(kv), type_string(typeof(kv))])
			if typeof(kv) != TYPE_VECTOR2:
				keys_ok = false
			var tr := clip.track_get_key_transition(t, k)
			check("%s key %d transition %.1f" % [path, k, KEY_TRANSITIONS[k]], near(tr, KEY_TRANSITIONS[k], VAL_TOL), "%.6f" % tr)

	if keys_ok:
		var tl: int = idx[P_LOWER_SCALE]
		var tp: int = idx[P_UPPER_POS]
		var tu: int = idx[P_UPPER_SCALE]
		for k in 4:
			var ls: Vector2 = clip.track_get_key_value(tl, k)
			var up: Vector2 = clip.track_get_key_value(tp, k)
			var us: Vector2 = clip.track_get_key_value(tu, k)
			check("key %d equal widths (LowerPivot.scale.x == UpperPivot.scale.x)" % k, near(ls.x, us.x, VAL_TOL), "%.6f vs %.6f" % [ls.x, us.x])
			check("key %d UpperPivot.position.x == 0" % k, near(up.x, 0.0, VAL_TOL), "%.6f" % up.x)
			var seam := REST_Y * ls.y
			check("key %d seam UpperPivot.position.y == -20.14 * LowerPivot.scale.y" % k, near(up.y, seam, SEAM_TOL), "%.6f vs %.6f (diff %.8f)" % [up.y, seam, up.y - seam])
		# Frame-8 key equals the scene's rest values.
		var ls8: Vector2 = clip.track_get_key_value(tl, 3)
		var up8: Vector2 = clip.track_get_key_value(tp, 3)
		var us8: Vector2 = clip.track_get_key_value(tu, 3)
		check("frame-8 LowerPivot:scale equals scene rest", near2(ls8, lower_pivot.scale, VAL_TOL), "%s vs %s" % [v2s(ls8), v2s(lower_pivot.scale)])
		check("frame-8 UpperPivot:position equals scene rest", near2(up8, upper_pivot.position, VAL_TOL), "%s vs %s" % [v2s(up8), v2s(upper_pivot.position)])
		check("frame-8 UpperPivot:scale equals scene rest", near2(us8, upper_pivot.scale, VAL_TOL), "%s vs %s" % [v2s(us8), v2s(upper_pivot.scale)])

		# --- Between keys (Animation.value_track_interpolate)
		if not has_interpolate:
			check("between-key samples via value_track_interpolate", false, "method missing on this build; not worked around")
		else:
			for frame: int in [1, 3, 5, 6, 7]:
				var time: float = frame / 60.0
				var s_ls: Vector2 = clip.call("value_track_interpolate", tl, time)
				var s_up: Vector2 = clip.call("value_track_interpolate", tp, time)
				var s_us: Vector2 = clip.call("value_track_interpolate", tu, time)
				print("SAMPLE frame %d t=%.6f LowerPivot:scale %s UpperPivot:position %s UpperPivot:scale %s" % [frame, time, v2s(s_ls), v2s(s_up), v2s(s_us)])
				var seam := REST_Y * s_ls.y
				check("frame %d seam UpperPivot.position.y == -20.14 * LowerPivot.scale.y" % frame, near(s_up.y, seam, SEAM_TOL), "%.6f vs %.6f (diff %.8f)" % [s_up.y, seam, s_up.y - seam])
				check("frame %d equal widths" % frame, near(s_ls.x, s_us.x, SEAM_TOL), "%.6f vs %.6f" % [s_ls.x, s_us.x])
				if frame == 6:
					check("frame 6 width 1.0375", near(s_ls.x, 1.0375, SEAM_TOL), "%.6f" % s_ls.x)
					check("frame 6 LowerPivot scale.y 0.90", near(s_ls.y, 0.90, SEAM_TOL), "%.6f" % s_ls.y)
					check("frame 6 UpperPivot scale.y 0.9325", near(s_us.y, 0.9325, SEAM_TOL), "%.6f" % s_us.y)
					check("frame 6 UpperPivot position.y -18.126", near(s_up.y, -18.126, SEAM_TOL), "%.6f (display %.2f)" % [s_up.y, s_up.y])

	finish()

func finish() -> void:
	print("A7 LAND READBACK: %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
