extends Node
## The one entry point for sound effects (SLICE-BRIEF.md §7). Each approved event ID is called
## only from the code that already represents its event (CHANGE-BRIEF.md event-to-sound map).
## Placeholder mode: plays nothing, but records every call so tests can count triggers.
## Adding audio later = putting an AudioStream in `streams` for an ID; no game logic changes.
## Sounds never decide game state.

const IDS := ["SFX-HOP", "SFX-LAND", "SFX-WARN", "SFX-SPLAT-FORK", "SFX-SPLAT-SAUCE", "SFX-WIN"]
var placeholder: bool = true
var streams: Dictionary = {}        # event ID -> AudioStream (none yet: no audio until the audio batch)
var calls: Array[Dictionary] = []   # {id, frame, state}
var context: Callable = func() -> String: return ""
var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "SFX"
	add_child(player)

func play(id: String) -> void:
	if not id in IDS:
		push_error("Unknown sound event: " + id)
		return
	calls.append({"id": id, "frame": Engine.get_physics_frames(), "state": context.call()})
	if not placeholder and streams.has(id):
		player.stream = streams[id]
		player.play()

func count(id: String) -> int:
	var n := 0
	for entry in calls:
		if entry.id == id:
			n += 1
	return n
