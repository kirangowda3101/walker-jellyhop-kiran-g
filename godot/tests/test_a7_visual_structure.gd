extends SceneTree
## A7 Step 5 (plan Step 3): structure of the wired visual layer (CHANGE-BRIEF.md, "Scene, authority and
## states"; CLAUDE.md "One authority" and "Ownership"). Loads the real game (session.gd) like
## test_slice.gd, inspects the hosted player_visuals.tscn, the pose-to-clip mapping and the player.gd
## source, then quits. Read-only: plays, seeks, builds and keys nothing; sends no input.
## Headless structure checks; not a render check and not human playtesting.
## Cannot prove: that no writer exists in a file not scanned here or in code that never runs; transitions
## (there is no AnimationTree resource to read; test_a7_visual_state.gd checks them in play).

const Game = preload("res://game/session.gd")
const Player = preload("res://features/player/player.gd")
const SCENE_PATH := "res://features/player/player_visuals.tscn"
const PLAYER_PATH := "res://features/player/player.gd"
const GAME_DIRS := ["res://game", "res://features", "res://effects", "res://ui", "res://audio"]

var checks := 0
var failures := 0

func check(id: String, passed: bool, observed: String) -> void:
	checks += 1
	if not passed:
		failures += 1
	print("%s %s: %s" % ["PASS" if passed else "FAIL", id, observed])

func _initialize() -> void:
	call_deferred("run")

func all_nodes(n: Node, out: Array[Node]) -> Array[Node]:
	out.append(n)
	for c in n.get_children():
		all_nodes(c, out)
	return out

func count_class(nodes: Array[Node], cls: String) -> int:
	var k := 0
	for n in nodes:
		if n.is_class(cls):
			k += 1
	return k

func code_lines(source: String) -> Array[String]:
	## The source with comments removed (player.gd has no '#' inside strings).
	var out: Array[String] = []
	for line in source.split("\n"):
		var i := line.find("#")
		out.append(line if i < 0 else line.substr(0, i))
	return out

func gd_files(dir: String, out: Array[String]) -> Array[String]:
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		gd_files(dir.path_join(sub), out)
	return out

func run() -> void:
	print("A7 VISUAL STRUCTURE: engine=%s" % Engine.get_version_info().string)
	# ---------------------------------------------------------------- mapping (brief: pose-to-visual table)
	var clips: Dictionary = Player.POSE_CLIPS
	var keys_in_poses := true
	for k in clips:
		keys_in_poses = keys_in_poses and (k in Player.POSES)
	check("mapping-keys-are-existing-poses", keys_in_poses, "POSE_CLIPS keys %s; POSES %s" % [clips.keys(), Player.POSES])
	var want := {"LAND": &"land", "SCOOT-A": &"scoot", "SCOOT-B": &"scoot"}
	var exact := clips.size() == want.size()
	for k in want:
		exact = exact and clips.has(k) and clips[k] == want[k] and typeof(clips[k]) == TYPE_STRING_NAME
	check("mapping-exactly-land-and-scoot", exact, "POSE_CLIPS %s" % [clips])
	var no_clip: Array[String] = []
	for p in Player.POSES:
		if not clips.has(p):
			no_clip.append(p)
	var others := ["IDLE", "BORED", "ANTIC", "RISE", "FALL", "WORRY", "SPLAT", "RESPAWN", "CELEBRATE"]
	no_clip.sort()
	others.sort()
	check("mapping-other-9-poses-have-no-clip", no_clip == others, "poses without a clip %s" % [no_clip])

	# ---------------------------------------------------------------- hosting in the real game
	var game: Node2D = Game.new()
	game.test_mode = true
	root.add_child(game)
	for i in range(5):
		await physics_frame
	var p = game.player
	var hosted: Array[Node] = []
	for c in p.get_children():
		if c.scene_file_path == SCENE_PATH:
			hosted.append(c)
	check("hosting-one-player-visuals-child", hosted.size() == 1 and hosted[0].name == "PlayerVisuals" and hosted[0] is Node2D,
		"children from %s: %s" % [SCENE_PATH, hosted.map(func(n): return str(n.name))])
	var v: Node = hosted[0] if hosted.size() == 1 else null
	check("hosting-visuals-member-is-that-child", v != null and p.visuals == v, "p.visuals=%s" % [p.visuals])
	var fp: Node = v.get_node_or_null("FacingPivot") if v else null
	var ap: AnimationPlayer = v.get_node_or_null("AnimationPlayer") as AnimationPlayer if v else null
	var paths := ["FacingPivot", "FacingPivot/Scoot", "FacingPivot/Scoot/ScootSprite", "FacingPivot/LandRig",
		"FacingPivot/LandRig/LowerPivot", "FacingPivot/LandRig/LowerPivot/LowerSprite",
		"FacingPivot/LandRig/UpperPivot", "FacingPivot/LandRig/UpperPivot/UpperSprite", "AnimationPlayer"]
	var missing: Array[String] = []
	for path in paths:
		if v == null or v.get_node_or_null(path) == null:
			missing.append(path)
	check("hosting-scene-nodes-present", missing.is_empty() and ap != null and ap.get_parent() == fp.get_parent(),
		"missing %s; AnimationPlayer beside FacingPivot=%s" % [missing, ap != null and fp != null and ap.get_parent() == fp.get_parent()])
	check("hosting-members-point-at-scene-nodes", v != null and p.facing_pivot == fp and p.scoot_node == v.get_node_or_null("FacingPivot/Scoot")
		and p.land_rig == v.get_node_or_null("FacingPivot/LandRig") and p.anim == ap,
		"facing_pivot=%s scoot_node=%s land_rig=%s anim=%s" % [p.facing_pivot, p.scoot_node, p.land_rig, p.anim])
	check("original-sprite-outside-facing-pivot", p.sprite is Sprite2D and p.sprite.get_parent() == p and fp != null and not fp.is_ancestor_of(p.sprite),
		"sprite parent=%s" % [p.sprite.get_parent().name if p.sprite else "none"])
	check("original-sprite-textures-kept", p.textures.has("IDLE") and p.textures["IDLE"] is Texture2D and p.sprite.texture == p.textures[p.pose],
		"pose=%s sprite.texture=%s" % [p.pose, p.sprite.texture.resource_path if p.sprite.texture else "none"])
	check("rest-state-original-sprite-only", p.pose == "IDLE" and p.sprite.visible and not p.scoot_node.visible and not p.land_rig.visible
		and ap.current_animation == "",
		"pose=%s sprite=%s scoot=%s land_rig=%s current_animation=\"%s\"" % [p.pose, p.sprite.visible, p.scoot_node.visible, p.land_rig.visible, ap.current_animation])
	check("rest-state-facing-pivot-mirror", fp.transform == Transform2D(Vector2(p.facing, 0), Vector2(0, 1), Vector2.ZERO),
		"facing=%s transform=%s" % [p.facing, fp.transform])

	# ---------------------------------------------------------------- route limits
	var nodes := all_nodes(root, [] as Array[Node])
	check("route-one-animation-player-in-game", count_class(nodes, "AnimationPlayer") == 1, "AnimationPlayer nodes: %d" % count_class(nodes, "AnimationPlayer"))
	check("route-no-animation-tree", count_class(nodes, "AnimationTree") == 0, "AnimationTree nodes: %d" % count_class(nodes, "AnimationTree"))
	check("route-no-animated-sprite-2d", count_class(nodes, "AnimatedSprite2D") == 0, "AnimatedSprite2D nodes: %d" % count_class(nodes, "AnimatedSprite2D"))
	check("route-root-node-resolves-to-player-visuals", ap.get_node_or_null(ap.root_node) == v, "root_node=%s -> %s" % [ap.root_node, ap.get_node_or_null(ap.root_node)])
	check("route-callback-physics", ap.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS, "callback_mode_process=%d" % ap.callback_mode_process)
	check("route-no-reset-clip", not ap.has_animation(&"RESET"), "animations %s" % [ap.get_animation_list()])
	var names_ok := true
	for k in clips:
		names_ok = names_ok and ap.has_animation(clips[k])
	check("route-every-requested-clip-exists", names_ok, "requested %s; library %s" % [clips.values(), ap.get_animation_list()])
	var method_tracks: Array[String] = []
	var unresolved: Array[String] = []
	for cn in ap.get_animation_list():
		var a := ap.get_animation(cn)
		for t in a.get_track_count():
			if a.track_get_type(t) == Animation.TYPE_METHOD:
				method_tracks.append("%s:%d" % [cn, t])
			var tp := a.track_get_path(t)
			var node := v.get_node_or_null(NodePath(tp.get_concatenated_names()))
			if node == null or tp.get_subname_count() == 0 or not (tp.get_subname(0) in node):
				unresolved.append("%s:%s" % [cn, tp])
	check("route-no-method-tracks", method_tracks.is_empty(), "method tracks %s" % [method_tracks])
	check("route-every-track-resolves-in-hosted-scene", unresolved.is_empty(), "unresolved %s" % [unresolved])
	var scripted: Array[String] = []
	for n in all_nodes(v, [] as Array[Node]):
		if n.get_script() != null:
			scripted.append(str(v.get_path_to(n)))
	check("authority-no-script-in-visuals-scene", scripted.is_empty(), "nodes with a script %s" % [scripted])

	# ---------------------------------------------------------------- authority, by reading player.gd
	var lines := code_lines(FileAccess.get_file_as_string(PLAYER_PATH))
	var code := "\n".join(lines)
	var banned := ["Animation.new", "track_insert_key", "add_animation_library", "create_tween", "Tween",
		"AnimationTree", "AnimatedSprite", "SpriteFrames", ".frame =", "LowerPivot", "UpperPivot", "ScootSprite",
		"LowerSprite", "UpperSprite", "speed_scale", "playback_speed", "\"RESET\"", "&\"RESET\""]
	var found: Array[String] = []
	for b in banned:
		if code.contains(b):
			found.append(b)
	check("authority-player-gd-never-builds-or-writes-animated-nodes", found.is_empty(), "banned tokens found %s" % [found])
	# Greedy within one line, so nested calls such as seek(_clip_time(want), true) are captured whole.
	var re_call := RegEx.create_from_string("\\banim\\.(\\w+)\\(([^\\n]*)\\)")
	var calls: Array[String] = []
	var bad_calls: Array[String] = []
	for m in re_call.search_all(code):
		calls.append("%s(%s)" % [m.get_string(1), m.get_string(2)])
		var fn := m.get_string(1)
		if not (fn in ["play", "seek", "stop", "pause", "is_playing"]):
			bad_calls.append(calls.back())
		elif fn == "play" and m.get_string(2) != "want":
			bad_calls.append(calls.back())
		elif fn == "seek" and m.get_string(2) != "_clip_time(want), true":
			bad_calls.append(calls.back())
	# Declarations and assignments of `want` only (`var want: T = x`, `want = x`, `want := x`), not comparisons.
	var want_src := RegEx.create_from_string("\\bwant\\s*(:\\s*\\w+\\s*)?:?=(?!=)\\s*([^\\n]+)")
	var want_assign: Array[String] = []
	for m in want_src.search_all(code):
		want_assign.append(m.get_string(2).strip_edges())
	check("authority-playback-calls-only-play-seek-stop-pause", bad_calls.is_empty() and calls.size() > 0, "anim calls %s; unexpected %s" % [calls, bad_calls])
	check("authority-play-only-names-from-pose-clips", want_assign == ["POSE_CLIPS.get(pose, &\"\")"], "assignments to want %s" % [want_assign])
	var re_write := RegEx.create_from_string("\\b(facing_pivot|scoot_node|land_rig|visuals|anim)\\.(\\w+)\\s*=(?!=)")
	var writes: Array[String] = []
	var bad_writes: Array[String] = []
	for m in re_write.search_all(code):
		var w := "%s.%s" % [m.get_string(1), m.get_string(2)]
		writes.append(w)
		if not (w in ["facing_pivot.transform", "scoot_node.visible", "land_rig.visible"]):
			bad_writes.append(w)
	var writes_set := {}
	for w in writes:
		writes_set[w] = true
	check("authority-visual-writes-only-facing-and-visibility", bad_writes.is_empty() and writes_set.size() == 3, "writes %s; unexpected %s" % [writes, bad_writes])
	check("authority-facing-mirror-as-brief", code.contains("facing_pivot.transform = Transform2D(Vector2(facing, 0), Vector2(0, 1), Vector2.ZERO)"), "full mirror transform written from facing")
	check("authority-original-sprite-visibility-written", code.contains("sprite.visible = want == &\"\""), "sprite.visible follows the no-clip case")
	var gameplay := ["tick", "land_ticks", "just_landed", "pose", "velocity", "facing", "enabled", "box", "was_grounded", "idle_ticks", "hop_ticks"]
	var start := -1
	for i in lines.size():
		if lines[i].begins_with("func _update_visuals"):
			start = i
	var gp_writes: Array[String] = []
	if start >= 0:
		var re_gp := RegEx.create_from_string("^\\s*(\\w+)\\s*(=|\\+=|-=)(?!=)")
		for i in range(start, lines.size()):
			var m := re_gp.search(lines[i])
			if m and m.get_string(1) in gameplay:
				gp_writes.append("line %d: %s" % [i + 1, lines[i].strip_edges()])
	check("authority-visual-code-never-writes-gameplay-state", start >= 0 and gp_writes.is_empty(), "_update_visuals at line %d; gameplay writes after it %s" % [start + 1, gp_writes])
	var others_mention: Array[String] = []
	for dir in GAME_DIRS:
		for f in gd_files(dir, [] as Array[String]):
			if f == PLAYER_PATH:
				continue
			var src := FileAccess.get_file_as_string(f)
			for token in ["AnimationPlayer", "player_visuals", "AnimationTree", "AnimatedSprite2D", ".anim.", "facing_pivot", "land_rig", "scoot_node"]:
				if src.contains(token):
					others_mention.append("%s: %s" % [f, token])
	check("authority-no-other-game-script-touches-visuals", others_mention.is_empty(), "mentions outside player.gd %s" % [others_mention])

	print("A7 VISUAL STRUCTURE: %d checks / %d failures" % [checks, failures])
	game.queue_free()
	for i in range(10):
		await process_frame
	quit(1 if failures else 0)
