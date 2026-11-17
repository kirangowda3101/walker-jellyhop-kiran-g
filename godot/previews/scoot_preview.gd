extends Node2D
## A7 FIXTURE, not gameplay evidence: the SCOOT frame strip (CHANGE-BRIEF.md, "Evidence and frame strips").
## Runs the real game (session.gd with test_mode = true, as test_slice.gd does: real table, room, plates and
## the live player_visuals.tscn) and drives it only with real key events: Input.parse_input_event plus
## Input.flush_buffered_events, each sent at the end of the physics tick before the tick that reads it
## (harness copied from godot/tests/test_a7_pins.gd). Nothing here writes game state or calls the AnimationPlayer.
##
## On the starting plate: scoot right (D held for HOLD ticks: 28 SCOOT ticks with the slow-down, two full 14-tick
## cycles), stop, scoot left the same way, stop, quit. Each press is timed so that its first SCOOT tick is at
## cycle phase START_PHASE, which puts both swaps and both wraps of each direction inside the segment with a
## SCOOT tick before and after them. Going right, the jelly ends about 3 px inside the plate's floor edge; the
## per-tick check below fails the run if it ever leaves the floor or shows another pose.
## Meant for --fixed-fps 60 (one physics tick per rendered frame, so every swap tick is a rendered frame).
##
## Log, one line per rendered frame (process frame), after every physics tick of that frame:
##   FRAME <process frame> ticks=<physics ticks this frame> tick=<last physics tick> ptick=<player.tick> pose=<pose>
##         land_ticks=<n> clip=<current_animation, "-" if none> t=<clip position s, "-" if none> cell=<ScootSprite.frame>
##         facing=<+1|-1>
##   SWAP frame=<f> ...  displayed cell went 0 -> 1 inside the scoot clip
##   WRAP frame=<f> ...  displayed cell went 1 -> 0 inside the scoot clip (loop wrap)
## Headless check: godot --headless --fixed-fps 60 --path godot res://previews/scoot_preview.tscn
## Movie Maker (windowed, run by Kiran): sessions/a7/capture_strips.sh

const Game = preload("res://game/session.gd")
const RIGHT_KEY := KEY_D
const LEFT_KEY := KEY_A
const SETTLE := 10          # grounded, PLAYING and IDLE this many ticks before the scoots are planned (as the pins)
const CYCLE := 14           # scoot cycle in player ticks (2 cells x 7)
const START_PHASE := 4      # cycle phase of the first SCOOT tick of each direction
const HOLD := 24            # read ticks with the key down; the slow-down adds 4 SCOOT ticks: 28 in all
const SLOWDOWN := 4         # SCOOT ticks after the release (320 -> 256, 192, 128, 64 px/s, then 0)
const STOP := 20            # IDLE ticks between and after the scoots
const GUARD_FRAMES := 3000  # stop if the plan never completes

var game: Node2D
var hook: Node
var pending: Array = []     # [code, pressed, read_tick]
var frame_ticks := 0
var last_tick := -1
var streak := 0
var planned := false
var segments: Array = []    # {dir, key, on, off, end}: read ticks
var end_tick := -1
var frames_seen := 0
var prev: Dictionary = {}   # the previous rendered frame
var events := {"right": {"SWAP": 0, "WRAP": 0}, "left": {"SWAP": 0, "WRAP": 0}}
var scoot_ticks := {"right": 0, "left": 0}
var problems: Array[String] = []

class TickHook extends Node:
	## Runs after the player (priority 0), session (10) and effects driver (20) in every physics tick.
	var on_tick: Callable
	func _physics_process(_delta: float) -> void:
		on_tick.call()

func _ready() -> void:
	print("SCOOT PREVIEW (A7 fixture): engine=%s physics_ticks_per_second=%d" % [Engine.get_version_info().string, Engine.physics_ticks_per_second])
	game = Game.new()
	game.test_mode = true
	add_child(game)
	hook = TickHook.new()
	hook.name = "PreviewTickHook"
	hook.process_physics_priority = 1000
	hook.on_tick = _on_tick
	add_child(hook)

# ---------------------------------------------------------------- input (real key events only; from test_a7_pins.gd)

func key_for(read_tick: int, code: Key, pressed: bool) -> void:
	## Schedules a key event so the player's _physics_process reads it on physics tick read_tick.
	if last_tick > read_tick - 1:
		problems.append("input for read tick %d scheduled too late (tick %d)" % [read_tick, last_tick])
	pending.append([code, pressed, read_tick])

func send(code: Key, pressed: bool, read_tick: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()   # applied now; read by the player on the next physics tick
	print("INPUT tick=%d frame=%d key=%s pressed=%s read_tick=%d" % [last_tick, Engine.get_process_frames(), OS.get_keycode_string(code), pressed, read_tick])

func _send_due(t: int) -> void:
	var keep: Array = []
	for e in pending:
		if int(e[2]) == t + 1:
			send(e[0], e[1], e[2])
		elif int(e[2]) <= t:
			problems.append("input for read tick %d not sent in time" % int(e[2]))
		else:
			keep.append(e)
	pending = keep

# ---------------------------------------------------------------- physics tick (read only)

func _first_at_phase(from: int, t: int, ptick: int) -> int:
	## The first read tick >= from whose player tick is at START_PHASE. The player tick advances by one per
	## enabled tick (player.gd line 100), and the session keeps the player enabled while PLAYING.
	var r := from
	while posmod(ptick + (r - t), CYCLE) != START_PHASE:
		r += 1
	return r

func _on_tick() -> void:
	var t := Engine.get_physics_frames()
	frame_ticks += 1
	last_tick = t
	var p = game.player
	if not planned:
		if game.state == Game.State.PLAYING and p.is_on_floor() and p.pose == "IDLE":
			streak += 1
		else:
			streak = 0
		if streak >= SETTLE:
			_plan(t, int(p.tick))
	else:
		for s in segments:
			if t >= int(s.on) and t <= int(s.end):
				var pose := String(p.pose)
				if not p.is_on_floor() or not (pose in ["SCOOT-A", "SCOOT-B", "IDLE"]):
					problems.append("tick %d (%s): pose %s floor %s x %.2f" % [t, s.dir, pose, p.is_on_floor(), p.position.x])
				if pose.begins_with("SCOOT"):
					scoot_ticks[s.dir] += 1
					if t == int(s.on) and posmod(int(p.tick), CYCLE) != START_PHASE:
						problems.append("%s: first SCOOT tick %d at phase %d, planned %d" % [s.dir, t, posmod(int(p.tick), CYCLE), START_PHASE])
	_send_due(t)

func _plan(t: int, ptick: int) -> void:
	planned = true
	var r1 := _first_at_phase(t + 2, t, ptick)
	var r2 := _first_at_phase(r1 + HOLD + SLOWDOWN + STOP, t, ptick)
	segments = [
		{"dir": "right", "key": RIGHT_KEY, "on": r1, "off": r1 + HOLD, "end": r1 + HOLD + SLOWDOWN - 1},
		{"dir": "left", "key": LEFT_KEY, "on": r2, "off": r2 + HOLD, "end": r2 + HOLD + SLOWDOWN - 1},
	]
	for s in segments:
		key_for(int(s.on), s.key, true)
		key_for(int(s.off), s.key, false)
		print("PLAN %s press_read_tick=%d release_read_tick=%d last_scoot_tick=%d first_phase=%d" % [s.dir, s.on, s.off, s.end, START_PHASE])
	end_tick = r2 + HOLD + SLOWDOWN + STOP

# ---------------------------------------------------------------- rendered frame (read only)

func _process(_delta: float) -> void:
	var f := Engine.get_process_frames()
	var ticks := frame_ticks
	frame_ticks = 0
	frames_seen += 1
	var p = game.player
	var ap: AnimationPlayer = p.anim
	var clip := String(ap.current_animation)
	var pos := NAN
	if clip != "":
		pos = ap.current_animation_position
	var cell: int = p.visuals.get_node("FacingPivot/Scoot/ScootSprite").frame
	var facing := int(p.facing)
	var ptick := int(p.tick)
	var pose := String(p.pose)
	print("FRAME %d ticks=%d tick=%d ptick=%d pose=%s land_ticks=%d clip=%s t=%s cell=%d facing=%+d" % [
		f, ticks, last_tick, ptick, pose, int(p.land_ticks), clip if clip != "" else "-",
		("%.6f" % pos) if clip != "" else "-", cell, facing])
	if clip == "scoot":
		# What is shown must match the pose and the player tick (brief: SCOOT cell and time = tick % 14).
		var want_cell := 0 if pose == "SCOOT-A" else 1
		if cell != want_cell or absf(pos * 60.0 - posmod(ptick, CYCLE)) > 1e-3:
			problems.append("frame %d: pose %s ptick %d shows cell %d at %.6f s" % [f, pose, ptick, cell, pos])
	if not prev.is_empty() and prev.clip == "scoot" and clip == "scoot":
		var kind := ""
		if int(prev.cell) == 0 and cell == 1:
			kind = "SWAP"
		elif int(prev.cell) == 1 and cell == 0:
			kind = "WRAP"
		if kind != "":
			var dir := "right" if facing > 0 else "left"
			events[dir][kind] += 1
			print("%s frame=%d tick=%d ptick=%d phase=%d dir=%s facing=%+d t=%.6f cell=%d prev_frame=%d prev_t=%.6f prev_cell=%d" % [
				kind, f, last_tick, ptick, posmod(ptick, CYCLE), dir, facing, pos, cell, int(prev.frame), float(prev.pos), int(prev.cell)])
	prev = {"frame": f, "clip": clip, "pos": pos, "cell": cell}
	if end_tick >= 0 and last_tick >= end_tick:
		_finish()
	elif frames_seen > GUARD_FRAMES:
		problems.append("plan not finished after %d frames" % GUARD_FRAMES)
		_finish()

func _finish() -> void:
	for dir in ["right", "left"]:
		if int(scoot_ticks[dir]) < 2 * CYCLE:
			problems.append("%s: %d SCOOT ticks, fewer than two cycles (%d)" % [dir, scoot_ticks[dir], 2 * CYCLE])
		if int(events[dir]["SWAP"]) < 2 or int(events[dir]["WRAP"]) < 2:
			problems.append("%s: %d swaps and %d wraps, expected at least 2 of each" % [dir, events[dir]["SWAP"], events[dir]["WRAP"]])
	for s in problems:
		print("PROBLEM " + s)
	print("SCOOT PREVIEW: right scoot_ticks=%d swaps=%d wraps=%d; left scoot_ticks=%d swaps=%d wraps=%d; problems=%d" % [
		scoot_ticks.right, events.right.SWAP, events.right.WRAP, scoot_ticks.left, events.left.SWAP, events.left.WRAP, problems.size()])
	set_process(false)
	hook.set_physics_process(false)
	get_tree().quit(1 if problems.size() > 0 else 0)
