extends Node2D
## Fixture for the Effect A frame strip (CHANGE-BRIEF.md, Effect A, "The frame strip").
## Frame 10: the plate puff and the table puff fire together. With `retrigger` on, a third puff
## fires at frame 15 beside the table one (5 frames, 0.167 s later at 30 fps: the scoot-off case).
## Only sets `emitting`: every effect setting lives in res://effects/land_puff.tscn, and the fixed
## seeds are set on the instances in land_puff_preview.tscn.
const TRIGGER_FRAME := 10
const RETRIGGER_FRAME := 15
@export var retrigger := false
var frame := 0   # 0 on the first _process call, so frame N is the Nth image Movie Maker writes
@onready var puff_plate: GPUParticles2D = $PuffPlate
@onready var puff_table: GPUParticles2D = $PuffTable
@onready var puff_retrigger: GPUParticles2D = $PuffRetrigger

func _process(_delta: float) -> void:
	if frame == TRIGGER_FRAME:
		puff_plate.emitting = true
		puff_table.emitting = true
	if retrigger and frame == RETRIGGER_FRAME:
		puff_retrigger.emitting = true
	frame += 1
