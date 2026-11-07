extends Node
## Presentation only (CHANGE-BRIEF.md, Boundaries): reads the session's state and the jelly's
## landing flag and position, never writes them. Every effect setting lives in the scene files.
const LAND_PUFF := preload("res://effects/land_puff.tscn")
@onready var session: Node2D = get_parent()

func _ready() -> void:
	process_physics_priority = 20   # after the session (10), which ticks after the jelly (0)

func _physics_process(_delta: float) -> void:
	# Effect A: the same condition on the same tick as SFX-LAND (session.gd line 372), read after
	# resolve_contacts(). Each landing gets its own instance; earlier puffs are never touched (A4).
	if session.state == session.State.PLAYING and session.player.just_landed:
		var puff: GPUParticles2D = LAND_PUFF.instantiate()
		session.add_child(puff)                                  # parent is the session, never the jelly (A7)
		puff.global_position = session.player.global_position    # the jelly's feet (A3)
		puff.finished.connect(puff.queue_free)                   # A6
		puff.emitting = true
