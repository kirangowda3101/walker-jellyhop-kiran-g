extends SceneTree
## Batch 3 audition follow-up: trace every sound call in the real game during a scripted run (input only:
## no teleports, no fork fixtures). The jelly stands on plates 1, 2 and 3 and hops between them (1 -> 2 -> 3
## -> 2 -> 1). For every sound call: time, event ID, the fork that caused it, that fork's phase, whether its
## shadow was on screen, and the jelly's plate. Fork shadow starts and strikes are logged too.
## Output: evidence/batch3-audio-trace.txt. This is a scripted run, not a playtest.
const Game = preload("res://game/session.gd")
const T = preload("res://game/slice_tuning.gd")
var game: Node2D
var lines: Array[String] = []
var tick := 0
var last_plate := 0
const PHASES := ["SAFE", "SHADOW", "DOWN", "HOLD", "UP"]
# Goals: [plate index, ticks to stand there]
var goals := [[0, 360], [1, 120], [2, 120], [1, 120], [0, 240]]
var goal := 0
var stood := 0
var hop_tick := -100
var committed := false

func _initialize() -> void:
	call_deferred("run")

func say(s: String) -> void:
	lines.append(s)
	print(s)

func secs() -> String:
	return "%6.2f s" % (tick / 60.0)

func fork_desc(f) -> String:
	if f == null:
		return "no fork"
	return "fork over plate %d, phase %s, shadow on screen %s" % [f.plate_index + 1, PHASES[f.phase()], game.shadow_on_screen(f)]

func current_plate() -> int:
	var p: int = game.plate_under(game.player.position.x)
	if game.player.is_on_floor() and p >= 0:
		last_plate = p
	return last_plate

func harmless(f, a: int, b: int) -> bool:
	if f == null:
		return true
	for k in range(a, b + 1):
		if not f.harmless_in(k):
			return false
	return true

func drive() -> void:
	## Input only. Stand at a plate's centre; to move, wait at the centre until the destination fork is
	## raised for the whole hop and this plate's fork stays raised meanwhile, then walk to the edge and hop.
	var p: CharacterBody2D = game.player
	p.test_jump_pressed = false
	if game.state != Game.State.PLAYING:
		p.test_axis = 0
		committed = false
		return
	if not p.is_on_floor() or tick < hop_tick + 6:
		return   # airborne: keep the hop's direction
	if goal >= goals.size():
		p.test_axis = 0
		return
	var target: int = goals[goal][0]
	var here := current_plate()
	var center: float = game.plates[here].center
	if here == target:
		committed = false
		if absf(p.position.x - center) > 8.0:
			p.test_axis = signf(center - p.position.x)
			return
		p.test_axis = 0
		stood += 1
		if stood >= goals[goal][1]:
			goal += 1
			stood = 0
		return
	var dir := 1.0 if target > here else -1.0
	var nxt: int = here + int(dir)
	if not committed:
		if absf(p.position.x - center) > 8.0:
			p.test_axis = signf(center - p.position.x)
			return
		p.test_axis = 0
		committed = harmless(game.forks[nxt], 30, 130) and harmless(game.forks[here], 0, 40)
		return
	var mark := center + dir * (T.plate_landing_half_width() - 12.0)
	if (p.position.x - mark) * dir < 0.0:
		p.test_axis = dir
		return
	p.test_axis = dir
	p.test_jump_pressed = true
	hop_tick = tick
	committed = false

func run() -> void:
	game = Game.new()
	game.test_mode = true
	root.add_child(game)
	await physics_frame
	game.start_session()   # skip the intro (play starts on plate 1)
	game.player.test_control = true
	say("== Batch 3 audio trace (real game, scripted input; not a playtest)  " + Time.get_datetime_string_from_system())
	say("route: stand on plate 1, hop to 2, 3, back to 2 and 1; times from the start of play; plates numbered 1-6")
	var seen := 0
	var prev_phase := {}
	var descent_tick := {}
	var warn_events := []
	var splat_events := []
	for f in game.forks:
		if f:
			prev_phase[f.plate_index] = f.phase()
	while tick < 90 * 60 and goal < goals.size():
		drive()
		await physics_frame
		await process_frame
		tick += 1
		var plate := current_plate() + 1
		# Fork events this tick.
		for f in game.forks:
			if f == null:
				continue
			var ph: int = f.phase()
			if ph != prev_phase[f.plate_index]:
				if ph == f.Phase.SHADOW:
					say("%s  fork %d shadow starts (on screen %s; jelly on plate %d)" % [secs(), f.plate_index + 1, game.shadow_on_screen(f), plate])
				elif ph == f.Phase.DOWN:
					say("%s  fork %d comes DOWN (on screen %s; jelly on plate %d)" % [secs(), f.plate_index + 1, game.shadow_on_screen(f), plate])
					descent_tick[f.plate_index + 1] = tick
				prev_phase[f.plate_index] = ph
		# Sound calls this tick. SFX-WARN calls are matched, in order, to the forks that started descending
		# this tick with announced set (the session plays them in fork order). Since Kiran's second audition
		# decision the scrape plays at the start of the descent, not at the start of the shadow.
		var warn_forks := []
		for f in game.forks:
			if f and f.phase() == f.Phase.DOWN and f.t == f.safe_ticks + f.shadow_ticks and f.announced:
				warn_forks.append(f)
		while seen < game.sound.calls.size():
			var c: Dictionary = game.sound.calls[seen]
			seen += 1
			var cause = null
			match c.id:
				"SFX-WARN":
					cause = warn_forks.pop_front() if not warn_forks.is_empty() else null
				"SFX-SPLAT-FORK":
					cause = game.forks[last_plate]
			var moving_down := []
			for f in game.forks:
				if f and f.phase() in [f.Phase.DOWN, f.Phase.HOLD]:
					moving_down.append(f.plate_index + 1)
			say("%s  SOUND %-15s | caused by: %s | jelly on plate %d | forks down now: %s | state %s" % [secs(), c.id, fork_desc(cause) if c.id in ["SFX-WARN", "SFX-SPLAT-FORK"] else "the jelly", plate, str(moving_down), c.state])
			if c.id == "SFX-WARN" and cause:
				warn_events.append({"tick": tick, "fork": cause.plate_index + 1, "descent_tick": descent_tick.get(cause.plate_index + 1, -1)})
			if c.id == "SFX-SPLAT-FORK" and cause:
				splat_events.append({"tick": tick, "fork": cause.plate_index + 1})
	# Summary
	var warn_total := 0
	var warn_other := 0
	var warn_while_none_down := 0
	for l in lines:
		if l.contains("SOUND SFX-WARN"):
			warn_total += 1
			var m := RegEx.create_from_string("fork over plate (\\d+).*jelly on plate (\\d+).*forks down now: \\[\\]")
			var r := RegEx.create_from_string("fork over plate (\\d+).*jelly on plate (\\d+)").search(l)
			if r and r.get_string(1) != r.get_string(2):
				warn_other += 1
			if m.search(l):
				warn_while_none_down += 1
	var aligned := 0
	for w in warn_events:
		if w.descent_tick == w.tick:
			aligned += 1
	say("SCRAPES: %d SFX-WARN calls, %d of them in the same tick as their fork's descent start" % [warn_events.size(), aligned])
	for sp in splat_events:
		var prior := -1
		for w in warn_events:
			if w.fork == sp.fork and w.tick <= sp.tick:
				prior = w.tick
		if prior >= 0:
			say("SPLAT: fork %d hit the jelly at %.2f s; its scrape played at %.2f s: %d ticks (%.3f s) earlier" % [sp.fork, sp.tick / 60.0, prior / 60.0, sp.tick - prior, (sp.tick - prior) / 60.0])
		else:
			say("SPLAT: fork %d hit the jelly at %.2f s with no scrape from that fork before it" % [sp.fork, sp.tick / 60.0])
	say("SUMMARY: %d SFX-WARN calls; %d from a fork not over the jelly's plate; %d while no fork was down; splats %d; route %s; run %.1f s" % [warn_total, warn_other, warn_while_none_down, game.splats, "completed (plates 1-2-3-2-1)" if goal >= goals.size() else "NOT completed (stopped at goal %d)" % goal, tick / 60.0])
	var out := ProjectSettings.globalize_path("res://../evidence/batch3-audio-trace-%s.txt" % OS.get_environment("TRACE_LABEL"))
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	game.queue_free()
	for i in range(30):
		await process_frame
	quit()
