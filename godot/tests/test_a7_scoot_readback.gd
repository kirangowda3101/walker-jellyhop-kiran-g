extends SceneTree
## A7 Step 3: read-back of the saved scoot clip and player_visuals.tscn (CHANGE-BRIEF.md, "Sheet and
## cycle", "Scene, authority and states", "Clocks and boundaries"). Loads the scene from its file,
## instantiates it under root, inspects it and quits. Read-only: builds, keys and plays nothing.
## Headless structure checks; not a render check and not human playtesting.
## Asserts nothing about clip names other than "scoot" (Step 4 adds "land" to the same library).

const SCENE_PATH := "res://features/player/player_visuals.tscn"
const SCOOT_PATH := "res://animations/scoot.tres"
const SHEET_PATH := "res://assets/art/CHAR-SCOOT-SHEET.png"
const TRACK_PATH := "FacingPivot/Scoot/ScootSprite:frame"
const TOL := 0.5 / 60.0

var checks := 0
var failures := 0

func check(id: String, passed: bool, observed: String) -> void:
	checks += 1
	if not passed:
		failures += 1
	print("%s %s: %s" % ["PASS" if passed else "FAIL", id, observed])

func near(a: float, b: float) -> bool:
	return absf(a - b) <= TOL

## From the A7 assignment handout, unchanged.
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

func check_classdb() -> void:
	print("ENGINE %s" % Engine.get_version_info().string)
	for pair in [["Animation", "loop_mode"], ["Animation", "step"], ["Animation", "length"],
			["AnimationMixer", "callback_mode_process"], ["AnimationMixer", "root_node"],
			["AnimationPlayer", "autoplay"], ["Sprite2D", "hframes"], ["Sprite2D", "vframes"],
			["Sprite2D", "frame"], ["Sprite2D", "offset"], ["Sprite2D", "centered"],
			["CanvasItem", "texture_filter"]]:
		check("classdb-property %s.%s" % pair, has_prop(pair[0], pair[1]), "declared on %s (no_inheritance)" % pair[0])
	check("classdb-inherits AnimationPlayer < AnimationMixer", ClassDB.is_parent_class("AnimationPlayer", "AnimationMixer"), "")
	for pair in [["AnimationMixer", "ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS"], ["Animation", "LOOP_LINEAR"],
			["Animation", "UPDATE_DISCRETE"], ["Animation", "TYPE_VALUE"], ["CanvasItem", "TEXTURE_FILTER_LINEAR_WITH_MIPMAPS"]]:
		var ok := ClassDB.class_has_integer_constant(pair[0], pair[1])
		check("classdb-constant %s.%s" % pair, ok, "value %d" % ClassDB.class_get_integer_constant(pair[0], pair[1]) if ok else "missing")
	for pair in [["Animation", "value_track_get_update_mode"], ["Animation", "track_get_key_time"]]:
		check("classdb-method %s.%s" % pair, ClassDB.class_has_method(pair[0], pair[1]), "")

func run() -> void:
	check_classdb()

	var packed := load(SCENE_PATH) as PackedScene
	check("scene-loads", packed != null, SCENE_PATH)
	if packed == null:
		finish()
		return
	var visuals := packed.instantiate()
	root.add_child(visuals)

	# --- Structure
	check("root PlayerVisuals Node2D", visuals.name == &"PlayerVisuals" and visuals.get_class() == "Node2D", "%s (%s)" % [visuals.name, visuals.get_class()])
	var facing := visuals.get_node_or_null("FacingPivot")
	var scoot_node := visuals.get_node_or_null("FacingPivot/Scoot")
	var sprite := visuals.get_node_or_null("FacingPivot/Scoot/ScootSprite") as Sprite2D
	var player := visuals.get_node_or_null("AnimationPlayer") as AnimationPlayer
	check("FacingPivot Node2D child of root", facing != null and facing.get_class() == "Node2D" and facing.get_parent() == visuals, str(facing))
	check("Scoot Node2D under FacingPivot", scoot_node != null and scoot_node.get_class() == "Node2D", str(scoot_node))
	check("ScootSprite Sprite2D under Scoot", sprite != null and sprite.get_class() == "Sprite2D", str(sprite))
	check("AnimationPlayer child of root, beside FacingPivot", player != null and player.get_parent() == visuals, str(player))
	var scripted: Array[String] = []
	var stack: Array[Node] = [visuals]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.get_script() != null:
			scripted.append(str(visuals.get_path_to(n)))
		stack.append_array(n.get_children())
	check("no scripts on any node", scripted.is_empty(), str(scripted))
	if sprite == null or player == null:
		finish()
		return

	# --- ScootSprite properties
	var tex_path := sprite.texture.resource_path if sprite.texture != null else "<null>"
	check("ScootSprite texture path", tex_path == SHEET_PATH, tex_path)
	if sprite.texture != null:
		check("ScootSprite texture size 2048x1024", sprite.texture.get_size() == Vector2(2048, 1024), str(sprite.texture.get_size()))
	check("ScootSprite hframes 2", sprite.hframes == 2, str(sprite.hframes))
	check("ScootSprite vframes 1", sprite.vframes == 1, str(sprite.vframes))
	check("ScootSprite frame 0", sprite.frame == 0, str(sprite.frame))
	check("ScootSprite centered false", sprite.centered == false, str(sprite.centered))
	check("ScootSprite offset (-512, -812)", sprite.offset == Vector2(-512, -812), str(sprite.offset))
	check("ScootSprite position (0, 0)", sprite.position == Vector2.ZERO, str(sprite.position))
	check("ScootSprite scale (0.106, 0.106)", sprite.scale.is_equal_approx(Vector2(0.106, 0.106)), str(sprite.scale))
	check("ScootSprite texture_filter LINEAR_WITH_MIPMAPS", sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "%d (constant %d)" % [sprite.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS])

	# --- AnimationPlayer
	check("AnimationPlayer root_node ..", player.root_node == NodePath(".."), str(player.root_node))
	check("AnimationPlayer callback_mode_process PHYSICS", player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS, "%d (constant %d)" % [player.callback_mode_process, AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS])
	check("AnimationPlayer autoplay empty", String(player.autoplay) == "", "'%s'" % player.autoplay)
	check("no RESET animation", not player.has_animation(&"RESET"), str(player.get_animation_list()))
	var libs := player.get_animation_library_list()
	check("exactly one library, the default \"\"", libs.size() == 1 and libs[0] == &"", str(libs))
	if player.has_animation_library(&""):
		var lib := player.get_animation_library(&"")
		var lib_path := lib.resource_path
		check("library is embedded in the scene", lib_path == "" or lib_path.begins_with(SCENE_PATH + "::"), "'%s'" % lib_path)
	var problems := track_problems(player)
	for p in problems:
		print("  track problem: " + p)
	check("every track of every clip resolves (track_problems)", problems.is_empty(), "%d problems over clips %s" % [problems.size(), player.get_animation_list()])

	# --- scoot clip
	check("clip scoot exists", player.has_animation(&"scoot"), str(player.get_animation_list()))
	if not player.has_animation(&"scoot"):
		finish()
		return
	var clip := player.get_animation(&"scoot")
	check("scoot resource path", clip.resource_path == SCOOT_PATH, clip.resource_path)
	check("scoot has exactly one track", clip.get_track_count() == 1, str(clip.get_track_count()))
	if clip.get_track_count() < 1:
		finish()
		return
	var path := str(clip.track_get_path(0))
	check("track 0 path", path == TRACK_PATH, path)
	var is_value := clip.track_get_type(0) == Animation.TYPE_VALUE
	check("track 0 type TYPE_VALUE", is_value, "%d (constant %d)" % [clip.track_get_type(0), Animation.TYPE_VALUE])
	if is_value:
		var mode := clip.value_track_get_update_mode(0)
		check("track 0 update mode DISCRETE", mode == Animation.UPDATE_DISCRETE, "%d (constant %d)" % [mode, Animation.UPDATE_DISCRETE])
	else:
		check("track 0 update mode DISCRETE", false, "not a value track; update mode not read")

	check("length 14/60", near(clip.length, 14.0 / 60.0), "%.10f vs %.10f" % [clip.length, 14.0 / 60.0])
	check("step 1/60", is_equal_approx(clip.step, 1.0 / 60.0), "%.10f vs %.10f" % [clip.step, 1.0 / 60.0])
	check("loop_mode LOOP_LINEAR", clip.loop_mode == Animation.LOOP_LINEAR, "%d (constant %d)" % [clip.loop_mode, Animation.LOOP_LINEAR])

	var n_keys := clip.track_get_key_count(0)
	check("exactly two keys", n_keys == 2, str(n_keys))
	if n_keys == 2:
		var t0 := clip.track_get_key_time(0, 0)
		var t1 := clip.track_get_key_time(0, 1)
		var v0 = clip.track_get_key_value(0, 0)
		var v1 = clip.track_get_key_value(0, 1)
		check("key 0 time 0", near(t0, 0.0), "%.10f" % t0)
		check("key 1 time 7/60", near(t1, 7.0 / 60.0), "%.10f" % t1)
		print("KEYTIME stored %.12f exact 7.0/60.0 %.12f diff %.12f" %[t1, 7.0 / 60.0, t1 - 7.0 / 60.0])
		check("key 0 value 0", typeof(v0) in [TYPE_INT, TYPE_FLOAT] and v0 == 0, "%s (type %s)" % [v0, type_string(typeof(v0))])
		check("key 1 value 1", typeof(v1) in [TYPE_INT, TYPE_FLOAT] and v1 == 1, "%s (type %s)" % [v1, type_string(typeof(v1))])
		var interval := t1 - t0
		check("key interval 7/60", near(interval, 7.0 / 60.0), "%.10f" % interval)
		check("seam: last key to length equals key interval 7/60", near(clip.length - t1, 7.0 / 60.0) and near(clip.length - t1, interval), "%.10f" % (clip.length - t1))
	var at_end := false
	for k in n_keys:
		if near(clip.track_get_key_time(0, k), clip.length):
			at_end = true
	check("seam: no key at the length", not at_end, "keys %d, length %.10f" % [n_keys, clip.length])
	var cells := sprite.hframes * sprite.vframes
	var bad: Array = []
	for k in n_keys:
		var v = clip.track_get_key_value(0, k)
		if not (typeof(v) in [TYPE_INT, TYPE_FLOAT]) or v < 0 or v >= cells or int(v) != v:
			bad.append(v)
	check("every frame key in 0..hframes*vframes-1", bad.is_empty(), "cells %d, bad %s" % [cells, bad])

	finish()

func finish() -> void:
	print("A7 SCOOT READBACK: %d checks / %d failures" % [checks, failures])
	quit(1 if failures else 0)
