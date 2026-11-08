extends Node2D
## Fixture for the Effect B frame strip (CHANGE-BRIEF.md, Effect B, "The frame strip").
## The glints instance starts with `emitting = false` (set on the instance in
## dome_glints_preview.tscn). Frame 10: `restart()`, so preprocess applies again (predicted
## failure 5). Frame 70: `emitting = false`, the stop. Capture with --quit-after 150.
## Only calls restart() and sets `emitting`: every effect setting lives in
## res://effects/dome_glints.tscn, and the fixed seed is set on the instance in the preview scene.
const START_FRAME := 10
const STOP_FRAME := 70
var frame := 0   # 0 on the first _process call, so frame N is the Nth image Movie Maker writes
@onready var glints: GPUParticles2D = $Glints

func _process(_delta: float) -> void:
	if frame == START_FRAME:
		glints.restart()
	if frame == STOP_FRAME:
		glints.emitting = false
	frame += 1
