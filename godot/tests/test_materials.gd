extends SceneTree
## Material audit checks (CHANGE-BRIEF.md A5 §7, §8, Revisions 2 and 3; godot/MATERIALS.md).
## Headless: the dummy renderer draws nothing, so this checks files, resources and numbers only,
## never a colour, texture or lighting result on screen. Written by Claude Code.
##
## Expected values come from CHANGE-BRIEF.md, never from the files checked.
## Tolerances (mine): FLOAT_TOL for floats the editor saves from float32 (for example uv_scale is
## stored as 2.000000083125); COLOR_TOL = one 8-bit step, because the Inspector snaps colours to
## 8 bits (the brief's tint 0.85 is stored as 217/255 = 0.8509804).
const Check = preload("res://tests/normal_map_check.gd")
const FLOAT_TOL := 1e-5
const COLOR_TOL := 1.0 / 255.0
const CURL_STRIDE := 4
const CURL_MAX := 0.70  # CHANGE-BRIEF.md Revision 3, under the map's own convention (GL)

const TABLE_SHADER := "res://shaders/table_wood.gdshader"
const HINT_SHADER := "res://shaders/hint_experiment.gdshader"
const A5_SCENE := "res://showcase/a5_materials.tscn"
const HINT_SCENE := "res://showcase/hint_experiment.tscn"
const TEX := "res://assets/textures/dark_wood/"
const DIFF := TEX + "dark_wood_diff_2k.png"
const ROUGH := TEX + "dark_wood_rough_2k.png"
const NOR_GL := TEX + "dark_wood_nor_gl_2k.png"
const NOR_DX := TEX + "dark_wood_nor_dx_2k.png"
const STRIP := "res://assets/textures/hint_strip/hint_strip_3x1.png"

# Sampler hints as CHANGE-BRIEF.md §7 and §8 specify them.
const SAMPLERS := {
	TABLE_SHADER: {
		"albedo_tex": ["source_color", "filter_linear_mipmap", "repeat_enable"],
		"roughness_tex": ["hint_default_white", "filter_linear_mipmap", "repeat_enable"],
		"normal_tex": ["hint_normal", "filter_linear_mipmap", "repeat_enable"],
	},
	HINT_SHADER: {
		"strip_as_colour": ["source_color", "filter_nearest"],
		"strip_as_data": ["filter_nearest"],
	},
}
# Non-sampler uniforms: [Variant type, group, default, range or []] (§7 table; §8 for the bool).
const UNIFORMS := {
	TABLE_SHADER: {
		"tint": [TYPE_COLOR, "colour", Color(1.0, 1.0, 1.0, 1.0), []],
		"brightness": [TYPE_FLOAT, "colour", 1.0, [0.0, 2.0]],
		"roughness_scale": [TYPE_FLOAT, "surface", 1.0, [0.0, 1.0]],
		"normal_strength": [TYPE_FLOAT, "surface", 1.0, [0.0, 2.0]],
		"uv_scale": [TYPE_FLOAT, "mapping", 1.0, [0.25, 8.0]],
	},
	HINT_SHADER: {
		"use_source_color": [TYPE_BOOL, "", null, []],
	},
}
const SAMPLER_GROUPS := {"albedo_tex": "colour", "roughness_tex": "surface", "normal_tex": "surface"}

# Materials: shader, uniform values, bound textures (§7 "The two materials", §8).
const MATERIALS := {
	"res://materials/table_wood_worn.tres": {
		"shader": TABLE_SHADER,
		"values": {"tint": Color(1, 1, 1, 1), "brightness": 1.0, "roughness_scale": 1.0, "normal_strength": 1.0, "uv_scale": 2.0},
		"textures": {"albedo_tex": DIFF, "roughness_tex": ROUGH, "normal_tex": NOR_GL},
	},
	"res://materials/serving_board_polished.tres": {
		"shader": TABLE_SHADER,
		"values": {"tint": Color(1.0, 0.85, 0.70, 1.0), "brightness": 1.0, "roughness_scale": 0.35, "normal_strength": 0.5, "uv_scale": 1.0},
		"textures": {"albedo_tex": DIFF, "roughness_tex": ROUGH, "normal_tex": NOR_GL},
	},
	"res://materials/hint_with_source_color.tres": {
		"shader": HINT_SHADER,
		"values": {"use_source_color": true},
		"textures": {"strip_as_colour": STRIP, "strip_as_data": STRIP},
	},
	"res://materials/hint_without_source_color.tres": {
		"shader": HINT_SHADER,
		"values": {"use_source_color": false},
		"textures": {"strip_as_colour": STRIP, "strip_as_data": STRIP},
	},
}

# Import settings as written in the .import files (Revision 2; §8 for the strip).
const IMPORTS := {
	DIFF: {"compress/mode": 0, "compress/normal_map": 2, "mipmaps/generate": true, "detect_3d/compress_to": 0, "roughness/mode": 1},
	ROUGH: {"compress/mode": 0, "compress/normal_map": 2, "mipmaps/generate": true, "detect_3d/compress_to": 0, "roughness/mode": 1},
	NOR_GL: {"compress/mode": 0, "compress/normal_map": 1, "mipmaps/generate": true, "detect_3d/compress_to": 0, "roughness/mode": 1},
	NOR_DX: {"compress/mode": 0, "compress/normal_map": 1, "mipmaps/generate": true, "detect_3d/compress_to": 0, "roughness/mode": 1},
	STRIP: {"compress/mode": 0, "mipmaps/generate": false},
}
const IMPORT_INFO_KEYS := ["compress/mode", "compress/normal_map", "mipmaps/generate", "detect_3d/compress_to", "roughness/mode"]

var results: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(id: String, passed: bool, observed: Variant) -> void:
	results.append({"id": id, "passed": passed})
	if not passed:
		failures += 1
	print("%s %s %s" % ["PASS" if passed else "FAIL", id, JSON.stringify(observed)])

func info(id: String, observed: Variant) -> void:
	print("INFO %s %s" % [id, JSON.stringify(observed)])

func near(a: float, b: float, tol: float = FLOAT_TOL) -> bool:
	return absf(a - b) <= tol

func near_c(a: Color, b: Color) -> bool:
	return near(a.r, b.r, COLOR_TOL) and near(a.g, b.g, COLOR_TOL) and near(a.b, b.b, COLOR_TOL) and near(a.a, b.a, COLOR_TOL)

func same_value(got: Variant, want: Variant) -> bool:
	if typeof(want) == TYPE_COLOR:
		return typeof(got) == TYPE_COLOR and near_c(got, want)
	if typeof(want) == TYPE_FLOAT:
		return typeof(got) in [TYPE_FLOAT, TYPE_INT] and near(float(got), want)
	return typeof(got) == typeof(want) and got == want

func enum_name(cls: String, enum_name_: String, value: int) -> String:
	## Looks the name up in the running engine's ClassDB, so it is never typed in by hand.
	for c in ClassDB.class_get_enum_constants(cls, enum_name_):
		if ClassDB.class_get_integer_constant(cls, c) == value:
			return c
	return "<not found in %s.%s>" % [cls, enum_name_]

func read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()

# ---------------------------------------------------------------- shader source text

func source_uniforms(src: String) -> Dictionary:
	## name -> {"type": glsl type, "hints": [..], "default": text or null}, from the source text.
	var out := {}
	var re := RegEx.new()
	re.compile("(?m)^\\s*uniform\\s+(\\w+)\\s+(\\w+)\\s*(?::\\s*([^=;]*))?(?:=\\s*([^;]*))?;")
	for m in re.search_all(src):
		var hints: Array = []
		var raw := m.get_string(3).strip_edges()
		if raw != "":
			# Split on commas outside parentheses (hint_range(0.0, 2.0) has a comma inside).
			var depth := 0
			var cur := ""
			for ch in raw:
				if ch == "(":
					depth += 1
				elif ch == ")":
					depth -= 1
				if ch == "," and depth == 0:
					hints.append(cur.strip_edges())
					cur = ""
				else:
					cur += ch
			hints.append(cur.strip_edges())
		var d := m.get_string(4).strip_edges()
		out[m.get_string(2)] = {"type": m.get_string(1), "hints": hints, "default": d if d != "" else null}
	return out

func parse_default(text: String, type: int) -> Variant:
	if type == TYPE_FLOAT:
		return text.to_float()
	if type == TYPE_BOOL:
		return text == "true"
	if type == TYPE_COLOR:
		var nums := []
		var re := RegEx.new()
		re.compile("-?\\d+(?:\\.\\d+)?")
		# Only inside the parentheses, so the "4" of "vec4" is not read as a component.
		var inner := text.substr(text.find("(") + 1) if text.find("(") >= 0 else text
		for m in re.search_all(inner):
			nums.append(m.get_string().to_float())
		return Color(nums[0], nums[1], nums[2], nums[3]) if nums.size() == 4 else null
	return null

func check_shader(path: String) -> void:
	var src := read_text(path)
	check("shader_source_readable %s" % path, src != "", {"chars": src.length()})
	var parsed := source_uniforms(src)
	for name in SAMPLERS[path]:
		var u: Dictionary = parsed.get(name, {})
		check("sampler_hints %s" % name, u.get("type", "") == "sampler2D" and u.get("hints", []) == SAMPLERS[path][name],
				{"type": u.get("type", null), "hints": u.get("hints", null), "expected": SAMPLERS[path][name]})
	for name in UNIFORMS[path]:
		var spec: Array = UNIFORMS[path][name]
		var u: Dictionary = parsed.get(name, {})
		if spec[2] == null:
			info("uniform_default_source %s" % name, {"text": u.get("default", null), "note": "no default in the brief"})
			continue
		var got: Variant = parse_default(str(u.get("default", "")), spec[0]) if u.get("default", null) != null else null
		check("uniform_default_source %s" % name, got != null and same_value(got, spec[2]),
				{"text": u.get("default", null), "expected": var_to_str(spec[2])})
	var all_names: Array = SAMPLERS[path].keys() + UNIFORMS[path].keys()
	var extra: Array = parsed.keys().filter(func(n): return not n in all_names)
	check("source_declares_no_other_uniforms %s" % path, extra.is_empty() and parsed.size() == all_names.size(),
			{"declared": parsed.keys(), "unexpected": extra})

	# Uniform list as the engine parses it (an empty list means the shader failed to parse).
	var shader := load(path) as Shader
	check("shader_loads %s" % path, shader != null, {})
	if shader == null:
		return
	var list := shader.get_shader_uniform_list(true)
	var by_name := {}
	var group := ""
	var groups_seen: Array = []
	for p in list:
		if p.usage & PROPERTY_USAGE_GROUP:
			group = p.name
			groups_seen.append(p.name)
			continue
		by_name[p.name] = {"type": p.type, "hint": p.hint, "hint_string": p.hint_string, "group": group}
	info("uniform_list %s" % path, {"entries": by_name, "groups": groups_seen})
	check("uniform_list_nonempty %s" % path, by_name.size() > 0, {"size": by_name.size()})
	check("uniform_list_names %s" % path, by_name.size() == all_names.size() and all_names.all(func(n): return by_name.has(n)),
			{"got": by_name.keys(), "expected": all_names})
	for name in SAMPLERS[path]:
		var e: Dictionary = by_name.get(name, {})
		var want_group: String = SAMPLER_GROUPS.get(name, "")
		check("uniform_list_type %s" % name, e.get("type", -1) == TYPE_OBJECT and e.get("hint_string", "") == "Texture2D"
				and (want_group == "" or e.get("group", "") == want_group),
				{"type": e.get("type", null), "hint_string": e.get("hint_string", null), "group": e.get("group", null), "expected_group": want_group})
	for name in UNIFORMS[path]:
		var spec: Array = UNIFORMS[path][name]
		var e: Dictionary = by_name.get(name, {})
		var ok: bool = e.get("type", -1) == spec[0] and (spec[1] == "" or e.get("group", "") == spec[1])
		var range_got: Array = []
		if not spec[3].is_empty():
			var parts: PackedStringArray = str(e.get("hint_string", "")).split(",")
			range_got = [parts[0].to_float(), parts[1].to_float()] if parts.size() >= 2 else []
			ok = ok and e.get("hint", -1) == PROPERTY_HINT_RANGE and range_got.size() == 2 \
					and near(range_got[0], spec[3][0]) and near(range_got[1], spec[3][1])
		check("uniform_list_type %s" % name, ok, {"type": e.get("type", null), "group": e.get("group", null), "hint": e.get("hint", null),
				"hint_string": e.get("hint_string", null), "expected_type": spec[0], "expected_group": spec[1], "expected_range": spec[3]})

# ---------------------------------------------------------------- materials

func check_material(path: String) -> void:
	var spec: Dictionary = MATERIALS[path]
	var mat := load(path) as ShaderMaterial
	check("material_loads %s" % path, mat != null, {})
	if mat == null:
		return
	var sp: String = mat.shader.resource_path if mat.shader else ""
	check("material_shader %s" % path, sp == spec.shader, {"shader": sp, "expected": spec.shader})
	for name in spec.values:
		var got: Variant = mat.get_shader_parameter(name)
		check("material_value %s %s" % [path.get_file(), name], same_value(got, spec.values[name]),
				{"got": var_to_str(got), "expected": var_to_str(spec.values[name])})
	for name in spec.textures:
		var tex: Variant = mat.get_shader_parameter(name)
		var tp: String = tex.resource_path if tex is Texture2D else ""
		check("material_texture %s %s" % [path.get_file(), name], tp == spec.textures[name], {"bound": tp, "expected": spec.textures[name]})
		if tex is Texture2D:
			info("bound_texture %s" % tp.get_file(), {"size": [tex.get_width(), tex.get_height()], "class": tex.get_class()})

func check_shared_shader() -> void:
	var a := load("res://materials/table_wood_worn.tres") as ShaderMaterial
	var b := load("res://materials/serving_board_polished.tres") as ShaderMaterial
	check("table_materials_share_shader", a != null and b != null and a.shader.resource_path == TABLE_SHADER
			and b.shader.resource_path == TABLE_SHADER and a.shader == b.shader,
			{"worn": a.shader.resource_path if a else null, "polished": b.shader.resource_path if b else null, "same_object": a != null and b != null and a.shader == b.shader})
	var bound := []
	for path in MATERIALS:
		var mat := load(path) as ShaderMaterial
		for name in MATERIALS[path].textures:
			var t: Variant = mat.get_shader_parameter(name)
			if t is Texture2D:
				bound.append(t.resource_path)
	check("dx_normal_map_not_bound", not NOR_DX in bound, {"bound_paths": bound})

# ---------------------------------------------------------------- import files

func check_imports() -> void:
	for tex in IMPORTS:
		var cfg := ConfigFile.new()
		var err := cfg.load(tex + ".import")
		check("import_file_reads %s" % tex.get_file(), err == OK, {"error": err})
		if err != OK:
			continue
		var all := {}
		for key in IMPORT_INFO_KEYS:
			all[key] = cfg.get_value("params", key, null)
		info("import_settings %s" % tex.get_file(), all)
		for key in IMPORTS[tex]:
			var got: Variant = cfg.get_value("params", key, null)
			check("import %s %s" % [tex.get_file(), key], got == IMPORTS[tex][key], {"got": got, "expected": IMPORTS[tex][key]})

# ---------------------------------------------------------------- scenes, lights, environment

func top_face_uv(mesh: PrimitiveMesh) -> Dictionary:
	## UV extent of the +Y face of a primitive mesh, from the CPU-side arrays.
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var plo := Vector3(INF, INF, INF)
	var phi := Vector3(-INF, -INF, -INF)
	for i in verts.size():
		if normals[i].dot(Vector3.UP) > 0.999:
			lo = lo.min(uvs[i])
			hi = hi.max(uvs[i])
			plo = plo.min(verts[i])
			phi = phi.max(verts[i])
	return {"uv_min": [snappedf(lo.x, 0.0001), snappedf(lo.y, 0.0001)], "uv_max": [snappedf(hi.x, 0.0001), snappedf(hi.y, 0.0001)],
			"uv_span": [snappedf(hi.x - lo.x, 0.0001), snappedf(hi.y - lo.y, 0.0001)],
			"face_size_xz": [snappedf(phi.x - plo.x, 0.0001), snappedf(phi.z - plo.z, 0.0001)]}

func describe_light(l: Light3D) -> Dictionary:
	var d := {"class": l.get_class(), "light_energy": l.light_energy, "light_indirect_energy": l.light_indirect_energy,
			"light_color": var_to_str(l.light_color), "shadow_enabled": l.shadow_enabled, "forward_in_parent": var_to_str((-l.transform.basis.z).snapped(Vector3.ONE * 0.0001))}
	if l is DirectionalLight3D:
		d["directional_shadow_mode"] = enum_name("DirectionalLight3D", "ShadowMode", l.directional_shadow_mode)
	return d

func lights_in(node: Node) -> Array:
	var out := []
	for n in node.find_children("*", "Light3D", true, false):
		out.append({"path": str(node.get_path_to(n)), "light": describe_light(n)})
	return out

func check_a5_scene() -> void:
	var packed := load(A5_SCENE) as PackedScene
	check("scene_loads %s" % A5_SCENE, packed != null, {})
	if packed == null:
		return
	var scene := packed.instantiate()
	var floor := scene.get_node_or_null("A3Assets/Floor") as MeshInstance3D
	var board := scene.get_node_or_null("ServingBoard") as MeshInstance3D
	var fo: Material = floor.get_surface_override_material(0) if floor else null
	var bo: Material = board.get_surface_override_material(0) if board else null
	check("a5 Floor surface override", fo != null and fo.resource_path == "res://materials/table_wood_worn.tres",
			{"override": fo.resource_path if fo else null, "material_override": floor.material_override != null if floor else null})
	check("a5 ServingBoard surface override", bo != null and bo.resource_path == "res://materials/serving_board_polished.tres",
			{"override": bo.resource_path if bo else null, "material_override": board.material_override != null if board else null})
	if floor and floor.mesh is BoxMesh:
		var mm: Material = (floor.mesh as BoxMesh).material
		info("a5 Floor mesh", {"size": var_to_str((floor.mesh as BoxMesh).size), "mesh_material": mm.get_class() if mm else null,
				"note": "the A3 mesh material stays on the mesh; the surface override replaces it at draw time"})
		info("a5 Floor top face UV", top_face_uv(floor.mesh))
	if board and board.mesh is BoxMesh:
		info("a5 ServingBoard mesh", {"size": var_to_str((board.mesh as BoxMesh).size), "position": var_to_str(board.position)})
		info("a5 ServingBoard top face UV", top_face_uv(board.mesh))
	var lights := lights_in(scene)
	info("a5 lights", lights)
	var sun := scene.get_node_or_null("A3Assets/Sun") as DirectionalLight3D
	check("a5 Sun is the only light, shadows on", sun != null and lights.size() == 1 and sun.shadow_enabled, {"lights": lights.size()})
	var envs := scene.find_children("*", "WorldEnvironment", true, false)
	var cams := scene.find_children("*", "Camera3D", true, false)
	var cam_env := []
	for c in cams:
		cam_env.append({"path": str(scene.get_path_to(c)), "current": c.current, "environment": c.environment != null, "attributes": c.attributes != null})
	info("a5 environment", {"world_environments": envs.size(), "cameras": cam_env,
			"project_default_environment": ProjectSettings.get_setting("rendering/environment/defaults/default_environment", "")})
	check("a5 has no WorldEnvironment or camera environment", envs.is_empty() and cam_env.all(func(c): return not c.environment),
			{"world_environments": envs.size()})
	scene.free()

func check_hint_scene() -> void:
	var packed := load(HINT_SCENE) as PackedScene
	check("scene_loads %s" % HINT_SCENE, packed != null, {})
	if packed == null:
		return
	var scene := packed.instantiate()
	for pair in [["QuadWithSourceColor", "res://materials/hint_with_source_color.tres"], ["QuadWithoutSourceColor", "res://materials/hint_without_source_color.tres"]]:
		var q := scene.get_node_or_null(pair[0]) as MeshInstance3D
		var m: Material = q.get_surface_override_material(0) if q else null
		check("hint %s surface override" % pair[0], m != null and m.resource_path == pair[1], {"override": m.resource_path if m else null})
	var lights := lights_in(scene)
	info("hint lights", lights)
	var we := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var env: Environment = we.environment if we else null
	check("hint WorldEnvironment has an Environment", env != null, {})
	if env:
		# Read from the loaded resource: values left at their defaults are not written in the .tscn.
		var observed := {
			"background_mode": "%d %s" % [env.background_mode, enum_name("Environment", "BGMode", env.background_mode)],
			"background_color": var_to_str(env.background_color),
			"tonemap_mode": "%d %s" % [env.tonemap_mode, enum_name("Environment", "ToneMapper", env.tonemap_mode)],
			"tonemap_exposure": env.tonemap_exposure, "tonemap_white": env.tonemap_white,
			"glow_enabled": env.glow_enabled, "fog_enabled": env.fog_enabled, "volumetric_fog_enabled": env.volumetric_fog_enabled,
			"adjustment_enabled": env.adjustment_enabled, "ssr_enabled": env.ssr_enabled, "ssao_enabled": env.ssao_enabled,
			"ssil_enabled": env.ssil_enabled, "sdfgi_enabled": env.sdfgi_enabled,
			"ambient_light_source": "%d %s" % [env.ambient_light_source, enum_name("Environment", "AmbientSource", env.ambient_light_source)],
		}
		info("hint environment", observed)
		check("hint tonemap Linear", env.tonemap_mode == Environment.TONE_MAPPER_LINEAR, {"tonemap_mode": observed.tonemap_mode})
		check("hint exposure 1.0", near(env.tonemap_exposure, 1.0), {"tonemap_exposure": env.tonemap_exposure})
		check("hint glow off", not env.glow_enabled, {})
		check("hint fog off", not env.fog_enabled and not env.volumetric_fog_enabled, {})
		check("hint adjustments off", not env.adjustment_enabled, {})
	var cam := scene.get_node_or_null("Camera3D") as Camera3D
	if cam:
		info("hint camera", {"projection": enum_name("Camera3D", "ProjectionType", cam.projection), "size": cam.size,
				"environment": cam.environment != null, "attributes": cam.attributes != null})
	scene.free()

# ---------------------------------------------------------------- source images

func load_source(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))

func check_source_images() -> void:
	var strip := load_source(STRIP)
	check("strip source loads", strip != null, {})
	if strip:
		var px := []
		for x in strip.get_width():
			var c := strip.get_pixel(x, 0)
			px.append([c.r8, c.g8, c.b8])
		check("strip texels 64, 128, 192 grey", strip.get_width() == 3 and strip.get_height() == 1 and px == [[64, 64, 64], [128, 128, 128], [192, 192, 192]],
				{"size": [strip.get_width(), strip.get_height()], "format": enum_name("Image", "Format", strip.get_format()), "texels": px})
	var rough := load_source(ROUGH)
	if rough:
		var max_diff := 0
		var samples := 0
		for v in range(0, rough.get_height(), 16):
			for u in range(0, rough.get_width(), 16):
				var c := rough.get_pixel(u, v)
				max_diff = maxi(max_diff, maxi(absi(c.r8 - c.g8), absi(c.r8 - c.b8)))
				samples += 1
		info("roughness source grey", {"format": enum_name("Image", "Format", rough.get_format()), "samples": samples, "max_channel_difference_8bit": max_diff})
	for path in [DIFF, ROUGH, NOR_GL, NOR_DX]:
		var img := load_source(path)
		if img:
			info("source image %s" % path.get_file(), {"size": [img.get_width(), img.get_height()], "format": enum_name("Image", "Format", img.get_format())})

func check_normal_maps() -> void:
	var gl := load_source(NOR_GL)
	check("nor_gl source loads", gl != null, {})
	if gl:
		var as_gl := Check.curl_ratio(gl, false, CURL_STRIDE)
		var as_dx := Check.curl_ratio(gl, true, CURL_STRIDE)
		print("CURL dark_wood_nor_gl_2k.png stride=%d  directx=false: %.4f  directx=true: %.4f" % [CURL_STRIDE, as_gl, as_dx])
		check("nor_gl curl under GL below %.2f" % CURL_MAX, as_gl < CURL_MAX, {"directx_false": snappedf(as_gl, 0.0001), "directx_true": snappedf(as_dx, 0.0001)})
	var dx := load_source(NOR_DX)
	if dx:
		# Calibration pair only (Revision 3): printed, no pass/fail.
		print("CURL dark_wood_nor_dx_2k.png stride=%d  directx=false: %.4f  directx=true: %.4f  (calibration, not checked)" % [CURL_STRIDE, Check.curl_ratio(dx, false, CURL_STRIDE), Check.curl_ratio(dx, true, CURL_STRIDE)])

# ---------------------------------------------------------------- run

func run() -> void:
	info("engine", {"version": Engine.get_version_info().string, "renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
			"tolerances": {"float": FLOAT_TOL, "colour": COLOR_TOL}})
	check_shader(TABLE_SHADER)
	check_shader(HINT_SHADER)
	for path in MATERIALS:
		check_material(path)
	check_shared_shader()
	check_imports()
	check_a5_scene()
	check_hint_scene()
	check_source_images()
	check_normal_maps()
	print("MATERIAL CHECKS: %d checks / %d failures" % [results.size(), failures])
	quit(1 if failures else 0)
