extends SceneTree
## A3 asset checks: fork.glb, dome.glb and platform.glb against CHANGE-BRIEF.md (Assignment 3),
## converted to Godot's Y-up axes, and their placement on the floor in res://showcase/a3_assets.tscn.
## Numbers only: no render, no gameplay, not human playtesting.
const TOL := 0.001  # metres
const SHOWCASE := "res://showcase/a3_assets.tscn"
# Expected values come from the brief (Blender X, Y, Z -> Godot X, Z, Y), never from the files checked.
const ASSETS := [
	{"key": "fork", "path": "res://assets/models/fork.glb", "node": "Fork", "size": Vector3(0.5, 1.5, 0.05), "budget": 100, "blender_tris": 72},
	{"key": "dome", "path": "res://assets/models/dome.glb", "node": "Dome", "size": Vector3(1.0, 0.75, 1.0), "budget": 300, "blender_tris": 266},
	{"key": "platform", "path": "res://assets/models/platform.glb", "node": "Platform", "size": Vector3(2.0, 0.25, 1.5), "budget": 60, "blender_tris": 36},
]
const REF_SIZE := 0.5
const REF_MIN_GAP := 0.5
var results: Array[Dictionary] = []
var info_lines: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(id: String, passed: bool, observation: Dictionary) -> void:
	results.append({"id": id, "status": "PASS" if passed else "FAIL", "observed": observation})
	if not passed:
		failures += 1
	print(JSON.stringify(results.back()))

func info(id: String, observation: Dictionary) -> void:
	info_lines.append({"id": id, "status": "INFO", "observed": observation})
	print(JSON.stringify(info_lines.back()))

func near(a: float, b: float) -> bool:
	return absf(a - b) <= TOL

func near_v(a: Vector3, b: Vector3) -> bool:
	return near(a.x, b.x) and near(a.y, b.y) and near(a.z, b.z)

func v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001), snappedf(v.z, 0.0001)]

func meshes_under(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for n in node.find_children("*", "MeshInstance3D", true, false):
		out.append(n as MeshInstance3D)
	return out

func mesh_vertices(mesh: Mesh) -> PackedVector3Array:
	var out := PackedVector3Array()
	if mesh is PrimitiveMesh:
		out.append_array((mesh as PrimitiveMesh).get_mesh_arrays()[Mesh.ARRAY_VERTEX])
		return out
	for s in range(mesh.get_surface_count()):
		out.append_array(mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX])
	return out

func triangle_count(mesh: Mesh) -> int:
	var tris := 0
	for s in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(s)
		var indices = arrays[Mesh.ARRAY_INDEX]
		if indices != null and indices.size() > 0:
			tris += indices.size() / 3
		else:
			tris += arrays[Mesh.ARRAY_VERTEX].size() / 3
	return tris

# Transform of node relative to ancestor (works before the node is in the scene tree)
func xform_to(node: Node, ancestor: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n := node
	while n != ancestor:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t

func local_points(inst: Node) -> PackedVector3Array:
	var out := PackedVector3Array()
	for mi in meshes_under(inst):
		var t := xform_to(mi, inst)
		for v in mesh_vertices(mi.mesh):
			out.append(t * v)
	return out

func world_points(node: Node) -> PackedVector3Array:
	var out := PackedVector3Array()
	for mi in meshes_under(node):
		for v in mesh_vertices(mi.mesh):
			out.append(mi.global_transform * v)
	return out

func bounds(points: PackedVector3Array) -> AABB:
	var box := AABB(points[0], Vector3.ZERO)
	for p in points:
		box = box.expand(p)
	return box

func extent_x(points: PackedVector3Array, keep: Callable) -> float:
	var lo := INF
	var hi := -INF
	for p in points:
		if keep.call(p):
			lo = minf(lo, p.x)
			hi = maxf(hi, p.x)
	return hi - lo if hi >= lo else 0.0

func box_gap(a: AABB, b: AABB) -> float:
	var gap := -INF
	for axis in range(3):
		gap = maxf(gap, maxf(a.position[axis] - b.end[axis], b.position[axis] - a.end[axis]))
	return gap

func run() -> void:
	for asset in ASSETS:
		glb_checks(asset)
	await scene_checks()
	var report := {"scope": "A3 asset checks (numbers only); no render, not human playtesting", "engine": Engine.get_version_info().string, "created_at": Time.get_datetime_string_from_system(true), "results": results, "info": info_lines, "failures": failures}
	var out := ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(out)
	var file := FileAccess.open(out + "/a3-assets-" + str(int(Time.get_unix_time_from_system())) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("A3 ASSET CHECKS: %d checks / %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

# Part A: each .glb on its own
func glb_checks(asset: Dictionary) -> void:
	var key: String = asset.key
	var expected: Vector3 = asset.size
	var packed = load(asset.path)
	check(key + ".A1_load", packed is PackedScene, {"path": asset.path, "type": type_string(typeof(packed)) if packed == null else packed.get_class()})
	if not packed is PackedScene:
		return
	var inst: Node = (packed as PackedScene).instantiate()
	check(key + ".A1_instance", inst != null, {"root": inst.name if inst else null})
	if inst == null:
		return

	# A2: every Node3D has scale (1, 1, 1) and no rotation
	var nodes: Array[Dictionary] = []
	var all_identity := true
	for n in [inst] + inst.find_children("*", "Node3D", true, false):
		var n3 := n as Node3D
		var ok := n3.transform.basis.is_equal_approx(Basis.IDENTITY)
		all_identity = all_identity and ok
		nodes.append({"name": String(n3.name), "class": n3.get_class(), "scale": v3(n3.scale), "rotation_deg": v3(n3.rotation_degrees), "position": v3(n3.position)})
	check(key + ".A2_node_scale_rotation", all_identity, {"nodes": nodes})

	var points := local_points(inst)
	check(key + ".A0_vertex_data", points.size() > 0, {"vertices": points.size(), "mesh_instances": meshes_under(inst).size()})
	if points.is_empty():
		inst.free()
		return

	# A3: bounding-box size in Godot axes
	var box := bounds(points)
	check(key + ".A3_size", near_v(box.size, expected), {"size": v3(box.size), "expected": v3(expected)})

	# A4: longest axis (information only); the brief's height must be on Y (checked in A3 and A5)
	var axis_names := ["X", "Y", "Z"]
	info(key + ".A4_longest_axis", {"longest": axis_names[box.size.max_axis_index()], "height_axis_expected": "Y", "size": v3(box.size)})

	# A5: lowest and highest Y
	check(key + ".A5_lowest_highest_y", near(box.position.y, 0.0) and near(box.end.y, expected.y), {"lowest_y": box.position.y, "highest_y": box.end.y, "expected": [0.0, expected.y]})

	# A6: shape orientation from the vertices
	match key:
		"fork":
			var bottom := extent_x(points, func(p: Vector3) -> bool: return p.y < 0.1)
			var top := extent_x(points, func(p: Vector3) -> bool: return p.y > 1.4)
			check(key + ".A6_prongs_down_handle_up", near(bottom, 0.5) and near(top, 0.1), {"width_below_y0.1": bottom, "width_above_y1.4": top, "expected": [0.5, 0.1]})
		"dome":
			var bottom := extent_x(points, func(p: Vector3) -> bool: return p.y < 0.05)
			var top := extent_x(points, func(p: Vector3) -> bool: return p.y > 0.7)
			check(key + ".A6_base_down_cherry_up", near(bottom, 1.0) and top > 0.0 and top <= 0.24 + TOL, {"width_below_y0.05": bottom, "width_above_y0.7": top, "expected": [1.0, "<= 0.24"]})
		"platform":
			var on_top := func(p: Vector3) -> bool: return near(p.y, 0.25)
			var top_points := PackedVector3Array()
			for p in points:
				if on_top.call(p):
					top_points.append(p)
			var top_box := bounds(top_points) if top_points.size() > 0 else AABB()
			check(key + ".A6_full_top_surface", top_points.size() > 0 and near(top_box.size.x, 2.0) and near(top_box.size.z, 1.5), {"top_vertices": top_points.size(), "top_size_xz": [top_box.size.x, top_box.size.z], "expected": [2.0, 1.5]})

	# A7: triangle count against the budget
	var tris := 0
	var materials: Array[String] = []
	for mi in meshes_under(inst):
		tris += triangle_count(mi.mesh)
		for s in range(mi.mesh.get_surface_count()):
			var mat := mi.mesh.surface_get_material(s)
			materials.append(mat.resource_name if mat else "<none>")
	check(key + ".A7_triangles", tris <= int(asset.budget), {"triangles": tris, "budget": asset.budget, "blender_count": asset.blender_tris})

	# A8: materials (information only)
	info(key + ".A8_materials", {"surfaces": materials})
	inst.free()

# Part B: the showcase scene
func scene_checks() -> void:
	var packed = load(SHOWCASE)
	check("scene.B0_load", packed is PackedScene, {"path": SHOWCASE})
	if not packed is PackedScene:
		return
	var scene: Node3D = (packed as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame

	# B1: floor top at Y = 0, from the Floor node's own mesh
	var floor_points := world_points(scene.get_node("Floor"))
	var floor_top := bounds(floor_points).end.y
	check("scene.B1_floor_top_at_zero", near(floor_top, 0.0), {"floor_top_y": floor_top})

	var boxes := {}
	for asset in ASSETS:
		var node := scene.get_node(String(asset.node)) as Node3D
		var points := world_points(node)
		if points.is_empty():
			check(asset.key + ".B2_on_floor", false, {"vertices": 0})
			continue
		var box := bounds(points)
		boxes[asset.key] = box
		# B2: the asset's lowest vertex against the floor's top (two different nodes)
		check(asset.key + ".B2_on_floor", absf(box.position.y - floor_top) <= TOL, {"asset_lowest_y": box.position.y, "floor_top_y": floor_top, "difference": box.position.y - floor_top})
		# B3: instance scale and rotation
		check(asset.key + ".B3_instance_scale", node.global_transform.basis.is_equal_approx(Basis.IDENTITY), {"scale": v3(node.scale), "rotation_deg": v3(node.rotation_degrees), "position": v3(node.position)})

	# B4: JellyScaleRef size, on the floor, separate from every asset
	var ref_box := bounds(world_points(scene.get_node("JellyScaleRef")))
	check("ref.B4_size", near_v(ref_box.size, Vector3.ONE * REF_SIZE), {"size": v3(ref_box.size), "expected": REF_SIZE})
	check("ref.B4_on_floor", absf(ref_box.position.y - floor_top) <= TOL, {"ref_lowest_y": ref_box.position.y, "floor_top_y": floor_top})
	var gaps := {}
	var all_apart := true
	for k in boxes:
		var g := box_gap(ref_box, boxes[k])
		gaps[k] = snappedf(g, 0.0001)
		all_apart = all_apart and g >= REF_MIN_GAP - TOL
	check("ref.B4_separate", all_apart and gaps.size() == ASSETS.size(), {"gap_to_asset_m": gaps, "minimum": REF_MIN_GAP})

	# B5: every box corner inside the camera's view
	var camera := scene.get_node("Camera3D") as Camera3D
	boxes["JellyScaleRef"] = ref_box
	var outside := []
	for k in boxes:
		var b: AABB = boxes[k]
		for i in range(8):
			if not camera.is_position_in_frustum(b.get_endpoint(i)):
				outside.append({"box": k, "corner": v3(b.get_endpoint(i))})
	check("scene.B5_camera_frames_all", outside.is_empty(), {"outside": outside, "camera_position": v3(camera.global_position), "camera_forward": v3(-camera.global_transform.basis.z), "viewport_size": [camera.get_viewport().get_visible_rect().size.x, camera.get_viewport().get_visible_rect().size.y]})
	scene.queue_free()
	await process_frame
