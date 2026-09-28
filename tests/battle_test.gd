extends Node
## Visual test for the duel screen.
##   xvfb-run ... godot --rendering-driver opengl3 res://tests/battle_test.tscn -- <out_dir> <WxH> <auto|setup> [shots] [interval]
## "setup": screenshot of the opening choice. "auto": both sides played by the
## AI, with screenshots every `interval` seconds.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var wh: PackedStringArray = (args[1] if args.size() > 1 else "1920x1080").split("x")
	var how: String = args[2] if args.size() > 2 else "auto"
	var shots := int(args[3]) if args.size() > 3 else 4
	var interval := float(args[4]) if args.size() > 4 else 6.0
	get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	Game.new_game("Ash", "emberstorm")
	Lore.set_patron(Game.profile, "pyrrhane")
	var screen := BattleScreen.new().configure({"deck": "ser_aldric", "name": "Ser Aldric Vane", "look": "aldric",
		"patron": "solmaris", "attrs": {"presence": 3}, "title": "Trial Duel", "seed": 5,
		"autoplay": how == "auto", "speed": 2.5})
	add_child(screen)
	screen.finished.connect(func(_w) -> void: get_tree().quit())
	var tag := "%sx%s" % [wh[0], wh[1]]
	if how == "setup":
		await get_tree().create_timer(4.0).timeout
		await _shot(out + "/battle_setup_%s.png" % tag)
		# pick an active and a bench card, then look again
		var hand: Array = screen.game.players[0].hand
		for c in hand:
			if c.is_basic_creature():
				screen._on_hand_tapped(_view_for(screen, c))
		await get_tree().create_timer(0.5).timeout
		await _shot(out + "/battle_setup2_%s.png" % tag)
		get_tree().quit()
		return
	for i in shots:
		await get_tree().create_timer(interval).timeout
		await _shot(out + "/battle_%d_%s.png" % [i, tag])
	get_tree().quit()


func _view_for(screen: BattleScreen, c: Card):
	for v in screen.hand_views:
		if v.card == c:
			return v
	return null


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)
