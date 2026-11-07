extends SceneTree
## Follow-up probe, written by Claude in chat (not Claude Code): what are the Godot-3-looking
## names `initial_velocity` and `scale` on ParticleProcessMaterial in this build?
func _initialize() -> void:
	for d in ClassDB.class_get_property_list("ParticleProcessMaterial"):
		if d.name in ["initial_velocity", "initial_velocity_min", "initial_velocity_max", "scale", "scale_min", "scale_max"]:
			print("PROP ", d.name, " type=", type_string(d.type), " usage=", d.usage, " hint=", d.hint, " hint_string=", d.hint_string)
	var m := ParticleProcessMaterial.new()
	print("GET initial_velocity = ", m.get("initial_velocity"), " | min = ", m.initial_velocity_min, " max = ", m.initial_velocity_max)
	print("GET scale = ", m.get("scale"), " | min = ", m.scale_min, " max = ", m.scale_max)
	m.set("initial_velocity", Vector2(11, 22))
	print("AFTER set initial_velocity=(11,22): min = ", m.initial_velocity_min, " max = ", m.initial_velocity_max)
	quit(0)
