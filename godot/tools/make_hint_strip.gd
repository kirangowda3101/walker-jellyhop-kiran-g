extends SceneTree
## Writes the 3x1 hint-experiment texture: grey texels 64, 128, 192 (CHANGE-BRIEF.md §8).
## Written by Claude (chat) at Kiran's request; run once, then the PNG is committed.
## Run: godot --headless --path godot --script res://tools/make_hint_strip.gd

const OUT := "res://assets/textures/hint_strip/hint_strip_3x1.png"
const GREYS := [64, 128, 192]

func _initialize() -> void:
    var img := Image.create_empty(3, 1, false, Image.FORMAT_RGB8)
    for x in range(3):
        var g: int = GREYS[x]
        img.set_pixel(x, 0, Color8(g, g, g))
    var err := img.save_png(ProjectSettings.globalize_path(OUT))
    print("HINT STRIP saved=", err == OK, " path=", OUT)
    for x in range(3):
        print("HINT STRIP texel ", x, " = ", img.get_pixel(x, 0).r8)
    quit(0 if err == OK else 1)
