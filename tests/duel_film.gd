extends Node
## The showcase film: a whole duel, the computer playing both sides at the
## game's real speed, Emberstorm (stacked so Pyraxis is drawn early, see
## tests/film_probe.gd) against Tidegrove. Quits a few seconds after the
## duel ends. Record it with:
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --write-movie out.avi --fixed-fps 30 res://tests/duel_film.tscn -- <WxH> <seed> [pos] [max seconds] [rival deck]

const Probe := preload("res://tests/film_probe.gd")

var _t0 := 0.0
var _fps := 24.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var wh: PackedStringArray = (args[0] if args.size() > 0 else "1280x720").split("x")
	var sd: int = int(args[1]) if args.size() > 1 else 3
	var pos: int = int(args[2]) if args.size() > 2 else 8
	var max_sec: float = float(args[3]) if args.size() > 3 else 600.0
	var rival: String = args[4] if args.size() > 4 else "tidegrove"
	_fps = float(args[5]) if args.size() > 5 else 24.0
	get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	get_tree().root.theme = UITheme.make()
	var p0 := Lore.new_profile("You", "pyrrhane", 4)
	var p1 := Lore.new_profile("Wren", "oriel", 4)
	var screen := DuelScreen.new().configure({
		"decks": [Probe.stacked_deck(sd, pos), rival], "stacked": [true, false],
		"names": ["You", "Wren"], "profiles": [p0, p1], "ai": [true, true],
		"seed": sd, "speed": 1.0})
	add_child(screen)
	_t0 = Time.get_ticks_msec() / 1000.0
	screen.finished.connect(func(_r) -> void:
		print("[%6.1fs] duel finished" % (Engine.get_process_frames() / _fps))
		await get_tree().create_timer(6.0).timeout
		get_tree().quit())
	while screen.game == null:   # the screen starts itself a frame after it's added
		await get_tree().process_frame
	screen.game.logged.connect(func(t, _who) -> void:
		if t.begins_with("Turn ") or "calls down" in t or "wins!" in t or "draw" in t:
			print("[%6.1fs] %s" % [Engine.get_process_frames() / _fps, t]))
	await get_tree().create_timer(max_sec).timeout
	print("[%6.1fs] time limit" % (Engine.get_process_frames() / _fps))
	get_tree().quit()
