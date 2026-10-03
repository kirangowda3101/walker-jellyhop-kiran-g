extends Control
## Screen text. Same drawing helpers as the walker-jumpman starter, at the 1280 x 720 base.
## lines() lists what is on screen for the current state, so tests can check it headless.
var game: Node2D
const INK := Color("fff6ea")
const OUTLINE := Color("1b1716")
const CONTROLS := "Left/Right or A/D: move     Space, Up or W: hop     Esc: pause     M: mute all     N: mute music"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func text_at(text: String, position: Vector2, size_px: int = 28, color: Color = INK) -> void:
	draw_string_outline(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 8, OUTLINE)
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func centered(text: String, y: float, font_size: int, color: Color = INK) -> void:
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	text_at(text, Vector2((1280 - width) / 2, y), font_size, color)

func lines() -> Array[Dictionary]:
	## {text, y, size}; x is centred. Mute markers are listed with y < 0 (drawn top-right).
	var out: Array[Dictionary] = []
	if not is_instance_valid(game):
		return out
	match game.state:
		game.State.INTRO:
			out.append({"text": "JELLY HOP", "y": 150.0, "size": 84})
			out.append({"text": "Fork From Above", "y": 205.0, "size": 34})
			out.append({"text": "any key skips the intro", "y": 690.0, "size": 24})
		game.State.PAUSED:
			out.append({"text": "PAUSED", "y": 300.0, "size": 64})
			out.append({"text": "Esc to resume", "y": 350.0, "size": 28})
			out.append({"text": CONTROLS, "y": 400.0, "size": 20})
		game.State.WON:
			out.append({"text": "SAFE!", "y": 230.0, "size": 96})
			if game.prompt_shown:
				out.append({"text": "press any key to play again", "y": 290.0, "size": 30})
	if AudioServer.is_bus_mute(0):
		out.append({"text": "MUTED (M)", "y": -1.0, "size": 22})
	var music := AudioServer.get_bus_index("Music")
	if music >= 0 and AudioServer.is_bus_mute(music):
		out.append({"text": "MUSIC OFF (N)", "y": -2.0, "size": 22})
	return out

func _draw() -> void:
	if not is_instance_valid(game):
		return
	if game.state == game.State.PAUSED:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.03, 0.03, 0.55))
	for line in lines():
		if line.y < 0.0:
			var w := ThemeDB.fallback_font.get_string_size(line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, line.size).x
			text_at(line.text, Vector2(1280 - 24 - w, 40.0 - 32.0 * (line.y + 1.0)), line.size)
		else:
			centered(line.text, line.y, line.size)
