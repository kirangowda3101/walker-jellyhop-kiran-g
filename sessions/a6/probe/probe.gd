extends SceneTree
## Scratch probe (outside the repo): do these class/property/constant names exist in this Godot build?

func _initialize() -> void:
	print("VERSION ", Engine.get_version_info().string)
	for c in ["GPUParticles2D", "CPUParticles2D", "ParticleProcessMaterial", "ParticlesMaterial", "GradientTexture2D", "GradientTexture1D", "CurveTexture", "CanvasItemMaterial", "Particles2D"]:
		print("CLASS ", c, " ", ClassDB.class_exists(c))
	var node_props := ["emitting", "amount", "one_shot", "explosiveness", "randomness", "lifetime", "preprocess", "local_coords", "texture", "material", "z_index", "visibility_rect", "use_fixed_seed", "seed", "process_material", "fixed_fps", "interpolate"]
	for p in node_props:
		print("PROP GPUParticles2D.", p, " ", _has("GPUParticles2D", p))
	var mat_props := ["particle_flag_disable_z", "emission_shape", "emission_ring_axis", "emission_ring_radius", "emission_ring_inner_radius", "emission_ring_height", "emission_box_extents", "direction", "spread", "initial_velocity_min", "initial_velocity_max", "radial_accel_min", "radial_accel_max", "radial_accel_curve", "gravity", "damping_min", "damping_max", "lifetime_randomness", "scale_min", "scale_max", "scale_curve", "color_ramp", "hue_variation_min", "hue_variation_max", "initial_velocity", "scale_random", "scale"]
	for p in mat_props:
		print("PROP ParticleProcessMaterial.", p, " ", _has("ParticleProcessMaterial", p))
	for p in ["fill", "fill_from", "fill_to", "width", "height", "gradient"]:
		print("PROP GradientTexture2D.", p, " ", _has("GradientTexture2D", p))
	for p in ["gradient"]:
		print("PROP GradientTexture1D.", p, " ", _has("GradientTexture1D", p))
	for p in ["blend_mode"]:
		print("PROP CanvasItemMaterial.", p, " ", _has("CanvasItemMaterial", p))
	for k in [["ParticleProcessMaterial", "EMISSION_SHAPE_RING"], ["ParticleProcessMaterial", "EMISSION_SHAPE_BOX"], ["GradientTexture2D", "FILL_RADIAL"], ["CanvasItemMaterial", "BLEND_MODE_ADD"]]:
		print("CONST ", k[0], ".", k[1], " ", ClassDB.class_has_integer_constant(k[0], k[1]))
	print("SIGNAL GPUParticles2D.finished ", ClassDB.class_has_signal("GPUParticles2D", "finished"))
	print("METHOD GPUParticles2D.restart ", ClassDB.class_has_method("GPUParticles2D", "restart"))
	quit(0)

func _has(c: String, p: String) -> bool:
	for d in ClassDB.class_get_property_list(c):
		if d.name == p:
			return true
	return false
