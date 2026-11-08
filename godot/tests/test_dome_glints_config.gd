extends SceneTree
## Effect B configuration checks: res://effects/dome_glints.tscn against CHANGE-BRIEF.md
## (Assignment 6, "Effect B — Dome sugar glints", "The settings"). Loads the scene and reads every
## named setting back from the loaded node and resources. A misspelled property in a .tscn loads
## silently at its default (predicted failure 1), so every value is read back, none is assumed.
## The box emission shape (the feature Effect A doesn't use) is checked as its own group.
## Numbers only: a headless run draws nothing; no look, no gameplay, not human playtesting.
const SCENE := "res://effects/dome_glints.tscn"
const TOL := 0.0001
const COLOR_TOL := 0.002   # one 8-bit step is 0.0039
# Expected values come from the brief, never from the file checked.
const NODE := {
	"emitting": true,
	"amount": 24,
	"one_shot": false,
	"explosiveness": 0.0,
	"randomness": 0.0,
	"lifetime": 2.4,
	"preprocess": 2.4,
	"local_coords": false,
	"z_index": 6,
	"visibility_rect": Rect2(-110, -160, 220, 220),
}
const BOX := {
	"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_BOX,
	"emission_box_extents": Vector3(70, 45, 0),
}
const PROCESS := {
	"particle_flag_disable_z": true,
	"direction": Vector3(0, -1, 0),
	"spread": 20.0,
	"initial_velocity_min": 12.0,
	"initial_velocity_max": 30.0,
	"gravity": Vector3(0, -6, 0),
	"damping_min": 0.0,
	"damping_max": 0.0,
	"lifetime_randomness": 0.3,
	"scale_min": 0.13,
	"scale_max": 0.28,
	"hue_variation_min": -0.05,
	"hue_variation_max": 0.05,
}
const TEXTURE_SIZE := Vector2i(32, 32)
const TEXTURE_FILL_FROM := Vector2(0.5, 0.5)
const TEXTURE_FILL_TO := Vector2(1.0, 0.5)
const TEXTURE_OFFSETS := [0.0, 0.35, 1.0]
const TEXTURE_COLORS := [Color(1, 1, 1, 1), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)]
const SCALE_CURVE := [Vector2(0.0, 0.0), Vector2(0.2, 1.0), Vector2(0.8, 1.0), Vector2(1.0, 0.0)]
const RAMP_OFFSETS := [0.0, 0.08, 0.75, 1.0]
const RAMP_COLORS := [Color(1.0, 0.95, 0.82, 0.0), Color(1.0, 0.95, 0.82, 0.85), Color(1.0, 0.82, 0.55, 0.6), Color(1.0, 0.82, 0.55, 0.0)]
var results: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(id: String, passed: bool, observation: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observation})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

func same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_FLOAT:
			return absf(a - b) <= TOL
		TYPE_VECTOR2:
			return (a as Vector2).distance_to(b) <= TOL
		TYPE_VECTOR3:
			return (a as Vector3).distance_to(b) <= TOL
		TYPE_RECT2:
			return same(a.position, b.position) and same(a.size, b.size)
		TYPE_COLOR:
			return absf(a.r - b.r) <= COLOR_TOL and absf(a.g - b.g) <= COLOR_TOL and absf(a.b - b.b) <= COLOR_TOL and absf(a.a - b.a) <= COLOR_TOL
	return a == b

func same_list(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if not same(a[i], b[i]):
			return false
	return true

func props(id_prefix: String, object: Object, expected: Dictionary) -> void:
	for key in expected:
		var got: Variant = object.get(key)
		check("%s.%s" % [id_prefix, key], same(got, expected[key]), {"expected": var_to_str(expected[key]), "got": var_to_str(got)})

func gradient_check(id: String, gradient: Gradient, offsets: Array, colors: Array) -> void:
	if gradient == null:
		check(id, false, {"error": "no Gradient"})
		return
	var got_offsets: Array = Array(gradient.offsets)
	var got_colors: Array = Array(gradient.colors)
	check(id + ".offsets", same_list(got_offsets, offsets), {"expected": var_to_str(offsets), "got": var_to_str(got_offsets)})
	check(id + ".colors", same_list(got_colors, colors), {"expected": var_to_str(colors), "got": var_to_str(got_colors)})

func curve_check(id: String, tex: Variant, points: Array) -> void:
	var ok_type: bool = tex is CurveTexture and (tex as CurveTexture).curve != null
	check(id + ".type", ok_type, {"expected": "CurveTexture with a Curve", "got": str(tex)})
	if not ok_type:
		return
	var curve: Curve = (tex as CurveTexture).curve
	var got: Array = []
	for i in range(curve.point_count):
		got.append(curve.get_point_position(i))
	check(id + ".points", same_list(got, points), {"expected": var_to_str(points), "got": var_to_str(got)})

func run() -> void:
	var packed: PackedScene = load(SCENE)
	check("scene.loads", packed != null, {"path": SCENE})
	if packed == null:
		finish()
		return
	var root := packed.instantiate()
	check("root.type", root is GPUParticles2D, {"expected": "GPUParticles2D", "got": root.get_class()})
	check("root.name", root.name == &"DomeGlints", {"expected": "DomeGlints", "got": str(root.name)})
	check("root.one_emitter", root.get_child_count() == 0, {"expected_children": 0, "got": root.get_child_count()})
	if not root is GPUParticles2D:
		root.free()
		finish()
		return
	var glints := root as GPUParticles2D
	# Node: emission and draw
	props("node", glints, NODE)
	# CLAUDE.md Ownership: no fixed seed in godot/effects/*.tscn (gameplay repeats must vary).
	check("node.use_fixed_seed", glints.use_fixed_seed == false, {"expected": false, "got": glints.use_fixed_seed})
	# Node: material (additive blend)
	var cim := glints.material
	check("material.type", cim is CanvasItemMaterial, {"expected": "CanvasItemMaterial", "got": str(cim)})
	if cim is CanvasItemMaterial:
		var blend := (cim as CanvasItemMaterial).blend_mode
		check("material.blend_mode", blend == CanvasItemMaterial.BLEND_MODE_ADD, {"expected": "BLEND_MODE_ADD (%d)" % CanvasItemMaterial.BLEND_MODE_ADD, "got": blend})
	# Node: texture
	var tex := glints.texture
	check("texture.type", tex is GradientTexture2D, {"expected": "GradientTexture2D", "got": str(tex)})
	if tex is GradientTexture2D:
		var g2 := tex as GradientTexture2D
		check("texture.size", Vector2i(g2.width, g2.height) == TEXTURE_SIZE, {"expected": var_to_str(TEXTURE_SIZE), "got": var_to_str(Vector2i(g2.width, g2.height))})
		check("texture.fill", g2.fill == GradientTexture2D.FILL_RADIAL, {"expected": "FILL_RADIAL (%d)" % GradientTexture2D.FILL_RADIAL, "got": g2.fill})
		check("texture.fill_from", same(g2.fill_from, TEXTURE_FILL_FROM), {"expected": var_to_str(TEXTURE_FILL_FROM), "got": var_to_str(g2.fill_from)})
		check("texture.fill_to", same(g2.fill_to, TEXTURE_FILL_TO), {"expected": var_to_str(TEXTURE_FILL_TO), "got": var_to_str(g2.fill_to)})
		gradient_check("texture.gradient", g2.gradient, TEXTURE_OFFSETS, TEXTURE_COLORS)
	# Process material
	var mat := glints.process_material
	check("process.type", mat is ParticleProcessMaterial, {"expected": "ParticleProcessMaterial", "got": str(mat)})
	if mat is ParticleProcessMaterial:
		var ppm := mat as ParticleProcessMaterial
		# The feature Effect A doesn't use: box emission across the dome's glass.
		props("process.box", ppm, BOX)
		props("process", ppm, PROCESS)
		curve_check("process.scale_curve", ppm.scale_curve, SCALE_CURVE)
		var ramp := ppm.color_ramp
		check("process.color_ramp.type", ramp is GradientTexture1D, {"expected": "GradientTexture1D", "got": str(ramp)})
		if ramp is GradientTexture1D:
			gradient_check("process.color_ramp.gradient", (ramp as GradientTexture1D).gradient, RAMP_OFFSETS, RAMP_COLORS)
	root.free()
	finish()

func finish() -> void:
	var report := {"scope": "A6 Effect B configuration checks (numbers only); no render, not human playtesting", "scene": SCENE, "engine": Engine.get_version_info().string, "created_at": Time.get_datetime_string_from_system(true), "results": results, "failures": failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/dome-glints-config-" + str(int(Time.get_unix_time_from_system())) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("DOME GLINTS CONFIG: %d checks / %d failures" % [results.size(), failures])
	quit(1 if failures else 0)
