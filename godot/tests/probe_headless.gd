extends SceneTree
## Probe: confirms headless facts on this machine before CLAUDE.md states them.
## Written by Claude (chat) at Kiran's request. The two shaders below are throwaway
## fixtures built in memory, not files in godot/shaders/.
## Run: ./scripts/run-test.sh probe_headless.gd <fps>

const GOOD := "shader_type canvas_item;\nuniform float w : hint_range(0.0, 1.0) = 0.25;\nvoid fragment() { COLOR.rgb = vec3(w); }\n"
const BROKEN := "shader_type canvas_item;\nuniform float w : hint_range(0.0, 1.0) = 0.25\nvoid fragment() { COLOR.rgb = vec3(w); }\n"

var frames := 0
var ticks := 0
var first_physics_delta := -1.0
var stage := 0

func _initialize() -> void:
    print("PROBE rendering method: ", RenderingServer.get_current_rendering_method())
    var good := Shader.new()
    good.code = GOOD
    print("PROBE good uniform list: ", good.get_shader_uniform_list())
    print("PROBE default via RenderingServer: ", RenderingServer.shader_get_parameter_default(good.get_rid(), "w"))
    var mat := ShaderMaterial.new()
    mat.shader = good
    mat.set_shader_parameter("not_declared", 1.0)
    print("PROBE undeclared name, set 1.0, reads back: ", mat.get_shader_parameter("not_declared"))
    mat.set_shader_parameter("w", 2.0)
    print("PROBE w (hint_range 0..1) set to 2.0 from code, reads back: ", mat.get_shader_parameter("w"))
    print("PROBE physics ticks per second: ", Engine.physics_ticks_per_second)

func _physics_process(delta: float) -> bool:
    ticks += 1
    if first_physics_delta < 0.0:
        first_physics_delta = delta
    return false

func _process(_delta: float) -> bool:
    frames += 1
    if frames == 60 and stage == 0:
        print("PROBE time_scale 1.0: 60 frames -> ", ticks, " physics ticks; physics delta ", first_physics_delta)
        Engine.time_scale = 0.5
        frames = 0
        ticks = 0
        first_physics_delta = -1.0
        stage = 1
    elif frames == 60 and stage == 1:
        print("PROBE time_scale 0.5: 60 frames -> ", ticks, " physics ticks; physics delta ", first_physics_delta)
        Engine.time_scale = 1.0
        var broken := Shader.new()
        broken.code = BROKEN
        print("PROBE broken shader uniform list size: ", broken.get_shader_uniform_list().size())
        print("PROBE done")
        quit(0)
    return false
