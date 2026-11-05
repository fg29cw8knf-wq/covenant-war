extends Node
## The film guard (5 November, with the duel's drama): a filmed duel, built
## as the Night of the White Sky builds Bram's (WhiteSky.duel_spec: spec.film,
## the snowfield, the hunter's spectral hounds, the film's own camera), left
## to play itself for a few seconds, and checked for anything of the stage
## or the drama having crept in: no dressing (the rim light, the shafts, the
## embers, the punch shader as the field's material), never a charge on an
## attacker, never a wash on the screen's edges, and the camera where the
## film put it. Prints any problem; a still at the end. Run:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 30 \
##       res://tests/duel_film_check.tscn -- <out_dir> [seconds]

const HOME := Vector3(1.9, 3.4, 12.4)   # the film's first shot (WhiteSky.SHOTS[0])

var problems: Array = []
var ds: DuelScreen
var _seen_charge := false
var _seen_wash := false
var _strikes := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var secs: float = float(args[1]) if args.size() > 1 else 14.0
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = true
	DuelField3D.preview_level = 2   # (as a Mac would dress it, were it not a film)
	ds = DuelScreen.new().configure(WhiteSky.duel_spec())
	add_child(ds)
	var t := 0.0
	while t < secs and is_instance_valid(ds) and ds.is_inside_tree():
		await get_tree().process_frame
		t += get_process_delta_time()
		if ds.field == null:
			continue
		if ds._strike.get("charge") != null:
			_seen_charge = true
		if not ds._strike.is_empty():
			_strikes += 1
		if ds._arena != null:
			for c in ds._arena.get_children():
				if c is DuelScreen.Vignette:
					_seen_wash = true
	# one blow driven by hand (the film's own duel may not have struck yet):
	# Bram's first Totem on the hunter's first
	if is_instance_valid(ds) and ds.field != null and ds.game != null:
		var mine: Array = ds.game.players[0].totems()
		var theirs: Array = ds.game.players[1].totems()
		if not mine.is_empty() and not theirs.is_empty():
			var home_before: Vector3 = ds.field._home_pos
			await ds.fx_attack(mine[0], 0, theirs[0])
			if ds._strike.get("charge") != null:
				_seen_charge = true
			await ds.fx_totem_hit(theirs[0], 60, {"attacker": mine[0], "element": (mine[0] as DuelTotem).element()})
			_strikes += 1
			for c in ds._arena.get_children():
				if c is DuelScreen.Vignette:
					_seen_wash = true
			if ds.field._home_pos.distance_to(home_before) > 0.01:
				problems.append("the blow moved the film's camera home")
			ds._strike = {}
			await _wait(1.0)
		else:
			problems.append("no Totems to drive a blow with")
	if not is_instance_valid(ds) or ds.field == null:
		problems.append("the filmed duel has no 3D field")
	else:
		var f := ds.field
		if f._dressed or f._rim != null or not f._shafts.is_empty() or f._embers != null or f.material != null or f._punch_mat != null:
			problems.append("the film's field was dressed (dressed %s, rim %s, shafts %d, embers %s, material %s)" % [f._dressed, f._rim != null, f._shafts.size(), f._embers != null, f.material != null])
		if f._home_pos.distance_to(HOME) > 0.01:
			problems.append("the film's camera home moved: %s" % f._home_pos)
		if f._snow == null:
			problems.append("no snow: film_mode didn't run")
		if _seen_charge:
			problems.append("an attacker charged in a film")
		if _seen_wash:
			problems.append("the screen's edges flared in a film")
		if ds._arena != null and ds._arena.get_child_count() > 0:
			problems.append("the arena shade was added in a film (%d children)" % ds._arena.get_child_count())
		if absf(Engine.time_scale - 1.0) > 0.001:
			problems.append("the clock was left at %.2f" % Engine.time_scale)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/film_check.png" % out)
	print("FILM CHECK: %d frames with a strike in flight, turn %d" % [_strikes, ds.game.turn if is_instance_valid(ds) and ds.game != null else -1])
	print("FILM CHECK: problems: ", problems if not problems.is_empty() else "none")
	print("FILM CHECK: done")
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout
