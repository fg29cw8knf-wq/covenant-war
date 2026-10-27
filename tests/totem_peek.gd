extends Node
## Stills of chosen Totems standing on the 3D field, still (both sides wait
## for a tap, so nothing moves), from the duel's own camera and from close
## up: for checking a new creature model (27 October: Gary's new Brookfin).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/totem_peek.tscn -- <out_dir> <your ids, comma-separated> <their ids> [arena]

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "user://"
	var mine: PackedStringArray = (a[1] if a.size() > 1 else "brookfin").split(",")
	var theirs: PackedStringArray = (a[2] if a.size() > 2 else "brookfin").split(",")
	var arena: String = a[3] if a.size() > 3 else "ashford"
	get_tree().root.theme = UITheme.make()
	var ds := DuelScreen.new().configure({"decks": ["tidegrove", "tidegrove"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": arena,
		"ai": [false, false], "seed": 3, "speed": 1.0, "first": 0, "no_arena_events": true})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await get_tree().create_timer(0.2).timeout
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	var g := ds.game
	var uid := 9500
	for side in 2:
		var ids: PackedStringArray = mine if side == 0 else theirs
		g.players[side].slots = [null, null, null]
		for s in mini(3, ids.size()):
			if ids[s] == "" or ids[s] == "-":
				continue
			uid += 1
			g.players[side].slots[s] = g._new_totem(DuelCard.new(uid, ids[s], side), side, s, 0)
	g.players[0].hand.clear()
	ds._refresh()
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/peek_field.png")
	# closer: the camera leans in on their side, then on yours
	if ds.field != null:
		for side in [1, 0]:
			ds.field.cam_focus(ds.field.foot_world(side, 1), 1.0, 0.3)
			await get_tree().create_timer(1.2).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out + "/peek_close_%s.png" % ("theirs" if side == 1 else "yours"))
	print("TOTEM PEEK: saved")
	get_tree().quit()
