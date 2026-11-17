extends Node2D
## A7 FIXTURE, not gameplay evidence: the LAND frame strip (CHANGE-BRIEF.md, "Evidence and frame strips").
## Runs the real game (session.gd with test_mode = true, as test_slice.gd does: real table, room, plates and
## the live player_visuals.tscn) and drives it only with real key events: Input.parse_input_event plus
## Input.flush_buffered_events, each sent at the end of the physics tick before the tick that reads it
## (harness copied from godot/tests/test_a7_pins.gd). Nothing here writes game state or calls the AnimationPlayer.
##
## One stationary hop on the starting plate. The press tick is chosen so that the touchdown tick is the last
## physics tick of a rendered frame. At --fixed-fps 30 (two physics ticks per rendered frame) that frame shows
## rig frame 0 and the next four frames show rig frames 2, 4, 6 and the IDLE hand-off at tick 8.
##
## Log, one line per rendered frame (process frame), after every physics tick of that frame:
##   FRAME <process frame> ticks=<physics ticks this frame> tick=<last physics tick> ptick=<player.tick> pose=<pose>
##         land_ticks=<n> clip=<current_animation, "-" if none> t=<clip position s, "-" if none> cell=<ScootSprite.frame>
##         facing=<+1|-1>
##   TRIGGER frame=<process frame that contains the touchdown tick> ...
##   STRIP rel=<-1..+4> ...  (the six frames to read, with what each should show)
## Headless check: godot --headless --fixed-fps 30 --path godot res://previews/land_preview.tscn
## Movie Maker (windowed, run by Kiran): sessions/a7/capture_strips.sh

const Game = preload("res://game/session.gd")
const JUMP_KEY := KEY_SPACE
const SETTLE := 10                 # grounded, PLAYING and IDLE this many ticks before the hop is planned (as the pins)
const PRESS_TO_TOUCHDOWN := 41     # BASELINE press_to_touchdown in logs/test_a7_pins_{30,60,144}fps.log; checked below
const AFTER_STRIP_FRAMES := 20     # idle frames after the hand-off frame, then quit
const GUARD_FRAMES := 3000         # stop if the hop never happens

var game: Node2D
var hook: Node
var pending: Array = []            # [code, pressed, read_tick]
var frame_ticks := 0               # physics ticks since the last rendered frame
var last_tick := -1                # last physics tick seen by the hook
var frame_ends: Array[int] = []    # last physics tick of each rendered frame that had ticks
var frame_sizes: Array[int] = []   # physics ticks of each of those frames
var streak := 0
var press_tick := -1
var predicted_touchdown := -1
var touchdown_tick := -1
var trigger_frame := -1
var rows: Dictionary = {}          # process frame -> row
var frames_seen := 0
var quit_at_frame := -1
var problems: Array[String] = []

class TickHook extends Node:
	## Runs after the player (priority 0), session (10) and effects driver (20) in every physics tick.
	var on_tick: Callable
	func _physics_process(_delta: float) -> void:
		on_tick.call()

func _ready() -> void:
	print("LAND PREVIEW (A7 fixture): engine=%s physics_ticks_per_second=%d" % [Engine.get_version_info().string, Engine.physics_ticks_per_second])
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
	Input.flush_buffered_events()   # applied now; reported as just pressed on the next physics tick
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

func _on_tick() -> void:
	var t := Engine.get_physics_frames()
	frame_ticks += 1
	last_tick = t
	var p = game.player
	if press_tick >= 0 and touchdown_tick < 0 and t > press_tick and p.just_landed:
		touchdown_tick = t
		print("TOUCHDOWN tick=%d predicted=%d press_tick=%d" % [t, predicted_touchdown, press_tick])
		if t != predicted_touchdown:
			problems.append("touchdown at tick %d, predicted %d (press %d + %d)" % [t, predicted_touchdown, press_tick, PRESS_TO_TOUCHDOWN])
	if press_tick < 0:
		if game.state == Game.State.PLAYING and p.is_on_floor() and p.pose == "IDLE":
			streak += 1
		else:
			streak = 0
		if streak >= SETTLE:
			_plan_hop(t)
	_send_due(t)

func _ticks_per_frame() -> int:
	## The physics ticks per rendered frame, if the last four frames agree; otherwise -1.
	if frame_sizes.size() < 4:
		return -1
	var n: int = frame_sizes.back()
	for i in range(frame_sizes.size() - 4, frame_sizes.size()):
		if frame_sizes[i] != n:
			return -1
	return n

func _plan_hop(t: int) -> void:
	var tpf := _ticks_per_frame()
	if tpf < 1:
		return   # frame structure not steady yet: try again next tick
	var end: int = frame_ends.back()
	var h := t + 2   # as the pins: the earliest read tick is one after the event is sent
	while posmod(h + PRESS_TO_TOUCHDOWN - end, tpf) != 0:
		h += 1
	press_tick = h
	predicted_touchdown = h + PRESS_TO_TOUCHDOWN
	key_for(h, JUMP_KEY, true)
	key_for(h + 2, JUMP_KEY, false)
	print("PLAN ready_tick=%d ticks_per_frame=%d last_frame_end_tick=%d press_tick=%d predicted_touchdown=%d (last tick of a frame)" % [t, tpf, end, h, predicted_touchdown])

# ---------------------------------------------------------------- rendered frame (read only)

func _process(_delta: float) -> void:
	var f := Engine.get_process_frames()
	var ticks := frame_ticks
	if ticks > 0:
		frame_ends.append(last_tick)
		frame_sizes.append(ticks)
	frame_ticks = 0
	frames_seen += 1
	var p = game.player
	var ap: AnimationPlayer = p.anim
	var clip := String(ap.current_animation)
	var pos := NAN
	if clip != "":
		pos = ap.current_animation_position
	var cell: int = p.visuals.get_node("FacingPivot/Scoot/ScootSprite").frame
	var row := {"frame": f, "ticks": ticks, "tick": last_tick, "ptick": int(p.tick), "pose": String(p.pose),
		"land_ticks": int(p.land_ticks), "clip": clip, "pos": pos, "cell": cell, "facing": int(p.facing)}
	rows[f] = row
	print("FRAME %d ticks=%d tick=%d ptick=%d pose=%s land_ticks=%d clip=%s t=%s cell=%d facing=%+d" % [
		f, ticks, last_tick, row.ptick, row.pose, row.land_ticks, clip if clip != "" else "-",
		("%.6f" % pos) if clip != "" else "-", cell, row.facing])
	if touchdown_tick >= 0 and trigger_frame < 0:
		trigger_frame = f
		var aligned := last_tick == touchdown_tick
		print("TRIGGER frame=%d touchdown_tick=%d last_tick_of_frame=%d ticks=%d aligned=%s" % [f, touchdown_tick, last_tick, ticks, aligned])
		if not aligned:
			problems.append("touchdown tick %d is not the last tick of frame %d (last tick %d)" % [touchdown_tick, f, last_tick])
	if trigger_frame >= 0 and f == trigger_frame + 4:
		_report_strip()
		quit_at_frame = f + AFTER_STRIP_FRAMES
	if quit_at_frame >= 0 and f >= quit_at_frame:
		_finish()
	elif frames_seen > GUARD_FRAMES:
		problems.append("no landing strip after %d frames" % GUARD_FRAMES)
		_finish()

func _report_strip() -> void:
	## The six frames to read: trigger - 1 .. trigger + 4, with what each should show.
	var want := {-1: "airborne FALL before contact", 0: "rig frame 0, impact: partial squash, planted feet",
		1: "rig frame 2, deepest squash (about the low box)", 2: "rig frame 4, same squash, recovery begins",
		3: "rig frame 6, eased rise, joined cut, fixed feet", 4: "tick 8, IDLE hand-off: no pop, seam or anchor shift"}
	var rel_ticks: Array[int] = []
	for rel in range(-1, 5):
		var r: Dictionary = rows.get(trigger_frame + rel, {})
		if r.is_empty():
			problems.append("no FRAME row for trigger %+d" % rel)
			continue
		var rel_tick: int = int(r.tick) - touchdown_tick
		var rig := "-"
		if r.clip == "land":
			rig = str(roundi(float(r.pos) * 60.0))
			if absf(float(r.pos) * 60.0 - rel_tick) > 1e-3:
				problems.append("trigger %+d: land clip at %.6f s, expected %d/60 (rel tick %d)" % [rel, r.pos, rel_tick, rel_tick])
		if rel >= 0:
			rel_ticks.append(rel_tick)
		var ok := true
		if rel == -1:
			ok = r.pose == "FALL" and r.clip == ""
		elif rel <= 3:
			ok = r.pose == "LAND" and r.clip == "land"
		else:
			ok = r.pose == "IDLE" and r.clip == "" and int(r.land_ticks) == 0
		if not ok:
			problems.append("trigger %+d: pose %s clip '%s' not as expected (%s)" % [rel, r.pose, r.clip, want[rel]])
		print("STRIP rel=%+d frame=%d tick=%d rel_tick=%d pose=%s land_ticks=%d clip=%s t=%s rig_frame=%s ok=%s expect=\"%s\"" % [
			rel, int(r.frame), int(r.tick), rel_tick, r.pose, int(r.land_ticks), r.clip if r.clip != "" else "-",
			("%.6f" % float(r.pos)) if r.clip != "" else "-", rig, ok, want[rel]])
	var layout_30 := rel_ticks == [0, 2, 4, 6, 8]
	print("STRIP rel_ticks=%s layout_30fps=%s" % [str(rel_ticks), layout_30])
	if _ticks_per_frame() == 2 and not layout_30:
		problems.append("at two ticks per frame the strip must read rel ticks 0, 2, 4, 6, 8; got %s" % str(rel_ticks))

func _finish() -> void:
	for s in problems:
		print("PROBLEM " + s)
	print("LAND PREVIEW: trigger_frame=%d touchdown_tick=%d problems=%d" % [trigger_frame, touchdown_tick, problems.size()])
	set_process(false)
	hook.set_physics_process(false)
	get_tree().quit(1 if problems.size() > 0 else 0)
