extends Node
## The one entry point for sound effects (SLICE-BRIEF.md §7). Each approved event ID is called
## only from the code that already represents its event (CHANGE-BRIEF.md event-to-sound map).
## Every call is recorded (event ID, physics frame, game state) so tests can count triggers.
## Batch 3: each ID plays res://assets/audio/<ID>.ogg on its own player on the SFX bus, so one
## sound never cuts off another. When anything plays did not change. Sounds never decide game state.

const IDS := ["SFX-HOP", "SFX-LAND", "SFX-WARN", "SFX-SPLAT-FORK", "SFX-SPLAT-SAUCE", "SFX-WIN"]
const AUDIO_DIR := "res://assets/audio/"
var placeholder: bool = false       # true = record calls but play nothing (the slice before Batch 3)
var streams: Dictionary = {}        # event ID -> AudioStream
var players: Dictionary = {}        # event ID -> AudioStreamPlayer
var calls: Array[Dictionary] = []   # {id, frame, state}
var context: Callable = func() -> String: return ""

func _ready() -> void:
	for id in IDS:
		var path: String = AUDIO_DIR + id + ".ogg"
		if ResourceLoader.exists(path):
			streams[id] = load(path)
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.stream = streams.get(id)
		add_child(p)
		players[id] = p

func _exit_tree() -> void:
	for p in players.values():
		p.stop()   # release playbacks so nothing is still playing when the game is freed

func play(id: String) -> void:
	if not id in IDS:
		push_error("Unknown sound event: " + id)
		return
	calls.append({"id": id, "frame": Engine.get_physics_frames(), "state": context.call()})
	if not placeholder and streams.has(id):
		players[id].play()

func count(id: String) -> int:
	var n := 0
	for entry in calls:
		if entry.id == id:
			n += 1
	return n
