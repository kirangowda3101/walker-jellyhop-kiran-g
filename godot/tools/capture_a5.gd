extends SceneTree
## A5 in-engine captures from a real windowed run (not headless): scripted captures.
## Written by Claude (chat) at Kiran's request. Saves PNGs + capture-results.json to evidence/a5-captures/.
## Run: godot --path godot --script res://tools/capture_a5.gd

const OUT_REL := "../evidence/a5-captures"
const PLAYING := 1   # session.gd enum State { INTRO, PLAYING, ... }
const FORK_PX := {"P1": Vector2(194, 1144), "P2": Vector2(298, 850), "BG": Vector2(-40, 1144)}
const WARNINGS := [0.0, 0.5, 1.0, 2.0]
const PRED := {
    "P1": {0.0: [179, 183, 184], 0.5: [204, 182, 147], 1.0: [228, 180, 111], 2.0: [255, 178, 37]},   # CHANGE-BRIEF.md Revision 5
    "P2": {0.0: [113, 126, 128], 0.5: [159, 143, 109], 1.0: [205, 160, 91], 2.0: [255, 195, 54]},
}
const HINT_PRED := {"with_source_color": [64, 128, 192], "without_source_color": [137, 188, 225]}

var out_dir := ""
var results := {}

func _initialize() -> void:
    var rel := OUT_REL
    for a in OS.get_cmdline_user_args():   # optional: -- --out=../evidence/other-folder
        if a.begins_with("--out="):
            rel = a.substr(6)
    out_dir = ProjectSettings.globalize_path("res://").path_join(rel).simplify_path()
    results["rendering_method"] = RenderingServer.get_current_rendering_method()
    print("CAPTURE rendering method: ", results["rendering_method"], "; output: ", out_dir)
    DirAccess.make_dir_recursive_absolute(out_dir)
    _run.call_deferred()

func _run() -> void:
    await _fork_captures()
    await _hint_captures()
    await _material_captures()
    var f := FileAccess.open(out_dir.path_join("capture-results.json"), FileAccess.WRITE)
    f.store_string(JSON.stringify(results, "  "))
    f.close()
    print("CAPTURE done; files in ", out_dir)
    quit(0)

func _frames(n: int) -> void:
    for i in n:
        await process_frame
    await RenderingServer.frame_post_draw

func _grab(name: String) -> Image:
    await _frames(3)
    var img := root.get_texture().get_image()
    img.save_png(out_dir.path_join(name + ".png"))
    return img

func _to_image(img: Image, p: Vector2) -> Vector2i:
    var vis := root.get_visible_rect().size
    var s := Vector2(img.get_width(), img.get_height()) / vis
    return Vector2i(int(p.x * s.x), int(p.y * s.y))

func _sample(img: Image, at: Vector2i) -> Dictionary:
    if at.x < 2 or at.y < 2 or at.x >= img.get_width() - 2 or at.y >= img.get_height() - 2:
        return {"in_bounds": false, "at": [at.x, at.y]}
    var c := img.get_pixelv(at)
    var lo := [255, 255, 255]
    var hi := [0, 0, 0]
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            var k := img.get_pixel(at.x + dx, at.y + dy)
            var v := [k.r8, k.g8, k.b8]
            for i in 3:
                lo[i] = mini(lo[i], v[i])
                hi[i] = maxi(hi[i], v[i])
    return {"in_bounds": true, "at": [at.x, at.y], "rgb": [c.r8, c.g8, c.b8], "min5x5": lo, "max5x5": hi}

func _fork_point(f, art: Vector2) -> Vector2:
    var spr: Sprite2D = f.sprite
    return spr.get_global_transform_with_canvas() * (spr.offset + art + Vector2(0.5, 0.5))

func _fork_captures() -> void:
    var game = load("res://game/main.tscn").instantiate()
    game.test_mode = true
    root.add_child(game)
    var t := 0
    while game.state != PLAYING and t < 1200:
        await process_frame
        t += 1
    var vis := root.get_visible_rect()
    var fork = null
    var waited := 0
    while fork == null and waited < 1200:   # wait until a fork is down far enough for P1 and P2 to be on screen
        await process_frame
        waited += 1
        for f in game.forks:
            if f and vis.has_point(_fork_point(f, FORK_PX["P1"])) and vis.has_point(_fork_point(f, FORK_PX["P2"])):
                fork = f
                break
    print("CAPTURE fork found after ", waited, " frames")
    game.set_physics_process(false)   # forks stop advancing, so the driver in fork.gd writes nothing
    if fork == null:
        print("CAPTURE fork: no fork with P1 and P2 on screen")
        results["fork"] = {"error": "no fork with P1 and P2 on screen"}
    else:
        var mat: ShaderMaterial = fork.sprite.material
        var rows := {}
        for w in WARNINGS:
            mat.set_shader_parameter("warning", w)
            var img := await _grab("fork_warning_%.2f" % w)
            var row := {}
            for name in FORK_PX:
                var s := _sample(img, _to_image(img, _fork_point(fork, FORK_PX[name])))
                row[name] = s
                var pred = PRED[name][w] if PRED.has(name) else "-"
                print("CAPTURE fork plate=%d warning=%.2f %s measured=%s predicted=%s 5x5min=%s 5x5max=%s" % [fork.plate_index, w, name, s.get("rgb", "off-screen"), pred, s.get("min5x5", "-"), s.get("max5x5", "-")])
            rows["%.2f" % w] = row
        results["fork"] = {"plate_index": fork.plate_index, "image_size": [root.get_texture().get_image().get_width(), root.get_texture().get_image().get_height()], "captures": rows}
    game.queue_free()
    await _frames(2)

func _hint_captures() -> void:
    var scene = load("res://showcase/hint_experiment.tscn").instantiate()
    root.add_child(scene)
    var cam: Camera3D = scene.get_node("Camera3D")
    cam.make_current()
    var img := await _grab("hint_experiment")
    var bands := {}
    for quad in [["with_source_color", -0.9], ["without_source_color", 0.9]]:
        for b in 3:
            var x: float = quad[1] - 0.5 + 0.5 * b
            var s := _sample(img, _to_image(img, cam.unproject_position(Vector3(x, 0, 0))))
            bands["%s_band%d" % [quad[0], b]] = s
            print("CAPTURE hint %s band%d (file value %d) measured=%s predicted=%d 5x5min=%s 5x5max=%s" % [quad[0], b, [64, 128, 192][b], s.get("rgb", "off-screen"), HINT_PRED[quad[0]][b], s.get("min5x5", "-"), s.get("max5x5", "-")])
    results["hint"] = bands
    scene.queue_free()
    await _frames(2)

func _material_captures() -> void:
    var scene = load("res://showcase/a5_materials.tscn").instantiate()
    root.add_child(scene)
    var cam: Camera3D = scene.get_node("A3Assets/Camera3D")
    cam.make_current()
    await _grab("materials_default")
    var mat: ShaderMaterial = scene.get_node("A3Assets/Floor").get_surface_override_material(0)
    var sweep := [
        ["brightness", [0.0, 1.0, 2.0]],
        ["roughness_scale", [0.0, 0.5, 1.0]],
        ["normal_strength", [0.0, 1.0, 2.0]],
        ["uv_scale", [0.25, 1.0, 8.0]],
        ["tint", [Color(0, 0, 0), Color(1, 0.85, 0.7), Color(1, 1, 1)]],
    ]
    var done := []
    for item in sweep:
        var param: String = item[0]
        var original = mat.get_shader_parameter(param)
        for v in item[1]:
            mat.set_shader_parameter(param, v)
            var label := "%s_%s" % [param, str(v).replace(" ", "").replace(",", "_").replace("(", "").replace(")", "")]
            await _grab("sweep_table_" + label)
            done.append(label)
        mat.set_shader_parameter(param, original)
    results["sweep_table_worn"] = done
    print("CAPTURE sweep saved: ", done.size(), " frames")
    scene.queue_free()
    await _frames(2)
