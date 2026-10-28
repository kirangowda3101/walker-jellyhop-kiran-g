extends SceneTree
## "One shader, two materials" check: scripted in-engine captures (windowed run).
## Written by Claude (chat) at Kiran's request. Edits happen in memory only; no file is changed.
## Run: godot --path godot --script res://tools/capture_shared.gd

const OUT_REL := "../evidence/a5-captures/shared"
const LINE := "ALBEDO = texture(albedo_tex, uv).rgb * tint.rgb * brightness;"
const EDITED := "ALBEDO = texture(albedo_tex, uv).rgb * tint.rgb * brightness * vec3(0.4, 0.6, 1.0);"

var out_dir := ""

func _initialize() -> void:
    out_dir = ProjectSettings.globalize_path("res://").path_join(OUT_REL).simplify_path()
    DirAccess.make_dir_recursive_absolute(out_dir)
    _run.call_deferred()

func _grab(name: String) -> Image:
    for i in 3:
        await process_frame
    await RenderingServer.frame_post_draw
    var img := root.get_texture().get_image()
    img.save_png(out_dir.path_join(name + ".png"))
    return img

func _px(img: Image, cam: Camera3D, world: Vector3) -> Array:
    var p := cam.unproject_position(world)
    var s := Vector2(img.get_width(), img.get_height()) / root.get_visible_rect().size
    var c := img.get_pixel(int(p.x * s.x), int(p.y * s.y))
    return [c.r8, c.g8, c.b8]

func _report(step: String, img: Image, cam: Camera3D) -> void:
    print("SHARED %s  table=%s  board=%s" % [step, _px(img, cam, Vector3(2.5, 0.0, -1.0)), _px(img, cam, Vector3(0.0, 0.05, 1.4))])

func _run() -> void:
    var scene = load("res://showcase/a5_materials.tscn").instantiate()
    root.add_child(scene)
    var cam: Camera3D = scene.get_node("A3Assets/Camera3D")
    cam.make_current()
    var table: ShaderMaterial = scene.get_node("A3Assets/Floor").get_surface_override_material(0)
    var board: ShaderMaterial = scene.get_node("ServingBoard").get_surface_override_material(0)
    print("SHARED same shader object: ", table.shader == board.shader, "; different materials: ", table != board)

    _report("1-before", await _grab("1_before"), cam)

    var original: String = table.shader.code
    assert(original.count(LINE) == 1)
    table.shader.code = original.replace(LINE, EDITED)   # one line of the ONE shader both materials use
    _report("2-shader-line-edited", await _grab("2_shader_line_edited"), cam)
    table.shader.code = original

    var b = board.get_shader_parameter("brightness")
    board.set_shader_parameter("brightness", 0.3)        # one value in the BOARD's material only
    _report("3-board-material-edited", await _grab("3_board_material_edited"), cam)
    board.set_shader_parameter("brightness", b)
    quit(0)
