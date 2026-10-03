extends Node
## MUS-LOOP behaviour (CHANGE-BRIEF.md "Music behavior"), driven on real audio buses now so
## that adding the loop later changes no logic. The session picks one target per tick; this
## node ramps the Music bus volume and its low-pass cutoff ("muffled") toward that target and
## logs every change of target, so overlap behaviour can be checked (failure #9).
## M mutes Master, N mutes Music only; muting never changes game state.

const T = preload("res://game/slice_tuning.gd")
var target: String = ""
var changes: Array[Dictionary] = []   # {frame, target, db, cutoff} or {frame, event: "restart"}
var player: AudioStreamPlayer
const LOOP_PATH := "res://assets/audio/MUS-LOOP.ogg"   # imported with looping on
var stream: AudioStream = null
var music_bus: int
var lowpass: AudioEffectLowPassFilter
var tween: Tween

func _ready() -> void:
	ensure_buses()
	music_bus = AudioServer.get_bus_index("Music")
	lowpass = AudioServer.get_bus_effect(music_bus, 0)
	player = AudioStreamPlayer.new()
	player.bus = "Music"
	add_child(player)
	if ResourceLoader.exists(LOOP_PATH):
		stream = load(LOOP_PATH)

static func ensure_buses() -> void:
	## Master, Music (with a low-pass filter) and SFX. Created in code so they also exist when a
	## test script, not the game scene, is the main loop.
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")
		if bus_name == "Music":
			var filter := AudioEffectLowPassFilter.new()
			filter.cutoff_hz = 20500.0
			AudioServer.add_bus_effect(index, filter)

func set_target(wanted: String) -> void:
	if wanted == target:
		return
	target = wanted
	var spec: Dictionary = T.MUSIC[wanted]
	changes.append({"frame": Engine.get_physics_frames(), "target": wanted, "db": spec.db, "cutoff": spec.cutoff})
	var time := T.WIN_FADE_TIME if wanted == "win_fade" else T.MUSIC_RAMP
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(func(v: float): AudioServer.set_bus_volume_db(music_bus, v), AudioServer.get_bus_volume_db(music_bus), spec.db, time)
	tween.tween_property(lowpass, "cutoff_hz", spec.cutoff, time)

func _exit_tree() -> void:
	player.stop()

func restart() -> void:
	## Start the loop from the top (intro, and replay after the dome).
	changes.append({"frame": Engine.get_physics_frames(), "event": "restart"})
	player.stop()
	if stream:
		player.stream = stream
		player.play(0.0)

func toggle_mute(all: bool) -> void:
	var index := 0 if all else music_bus
	AudioServer.set_bus_mute(index, not AudioServer.is_bus_mute(index))

func targets() -> Array[String]:
	var out: Array[String] = []
	for entry in changes:
		if entry.has("target"):
			out.append(entry.target)
	return out
