extends SceneTree
## Calibration run for normal_map_check.gd on the Poly Haven Dark Wood GL/DX pair.
## Written by Claude (chat) at Kiran's request. Reads the source PNGs, not the imported textures.

const Check = preload("res://tests/normal_map_check.gd")
const MAPS := {
    "nor_gl": "res://assets/textures/dark_wood/dark_wood_nor_gl_2k.png",
    "nor_dx": "res://assets/textures/dark_wood/dark_wood_nor_dx_2k.png",
}

func _initialize() -> void:
    for name in MAPS:
        var img := Image.load_from_file(ProjectSettings.globalize_path(MAPS[name]))
        var as_gl := Check.curl_ratio(img, false, 4)
        var as_dx := Check.curl_ratio(img, true, 4)
        print("CURL %s size=%dx%d format=%d  directx=false: %.4f  directx=true: %.4f" % [name, img.get_width(), img.get_height(), img.get_format(), as_gl, as_dx])
    quit(0)
