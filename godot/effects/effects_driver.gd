extends Node
## Presentation only (CHANGE-BRIEF.md, Boundaries): reads the session's state and the jelly's
## landing flag and position, never writes them. Every effect setting lives in the scene files.
const LAND_PUFF := preload("res://effects/land_puff.tscn")
const DOME_GLINTS := preload("res://effects/dome_glints.tscn")
const T := preload("res://game/slice_tuning.gd")
@onready var session: Node2D = get_parent()
var glints: GPUParticles2D   # the one DomeGlints for the whole session, never freed (B7)
var was_won := false

func _ready() -> void:
	process_physics_priority = 20   # after the session (10), which ticks after the jelly (0)
	# Effect B: on from load by its scene file (emitting = true, preprocess fills it) (B1).
	glints = DOME_GLINTS.instantiate()
	glints.position = Vector2(T.dome_left() + T.dome_width() / 2.0, T.TABLE_TOP - 70.0)   # dome centre x, TABLE_TOP - 70
	session.add_child(glints)

func _physics_process(_delta: float) -> void:
	# Effect A: the same condition on the same tick as SFX-LAND (session.gd line 372), read after
	# resolve_contacts(). Each landing gets its own instance; earlier puffs are never touched (A4).
	if session.state == session.State.PLAYING and session.player.just_landed:
		var puff: GPUParticles2D = LAND_PUFF.instantiate()
		session.add_child(puff)                                  # parent is the session, never the jelly (A7)
		puff.global_position = session.player.global_position    # the jelly's feet (A3)
		puff.finished.connect(puff.queue_free)                   # A6
		puff.emitting = true
	# Effect B: acts only when the state enters or leaves WON; pause, Esc and hiding never reach it.
	var won: bool = session.state == session.State.WON
	if won != was_won:
		if won:
			glints.emitting = false   # live glints finish and fade; the node stays (B2)
		else:
			glints.restart()          # replay: same instance, preprocess applies again (B3)
		was_won = won
