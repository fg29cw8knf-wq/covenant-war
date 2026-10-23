extends Node
## Stills of Phase C on the duel screen: a veiled rival Totem (a card back,
## VEILED), a Totem of yours carrying a Relic (its band), a bonded pair, a
## Tempered Totem; on the flat field and the 3D field.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/phase_c_shot.tscn -- <out_dir>

var out := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	get_tree().root.theme = UITheme.make()
	for flat in [true, false]:
		var ds := DuelScreen.new().configure({"decks": ["emberstorm", "veilwild"], "names": ["You", "Rival"],
			"ai": [false, false], "seed": 41, "speed": 50.0, "field3d": not flat})   # (both waiting for a tap: the board holds still)
		add_child(ds)
		var t := 0.0
		while (ds.game == null or ds.game.turn < 1) and t < 30.0:
			await get_tree().create_timer(0.2).timeout
			t += 0.2
			if ds.banner_waiting:
				ds.tap_banner()
		var g := ds.game
		for pl in g.players:
			pl.slots = [null, null, null]
		var veiled := g._new_totem(DuelCard.new(9100, "dreamfox", 1), 1, 1, 1)
		veiled.face_down = true
		g.players[1].slots[1] = veiled
		g.players[1].slots[0] = g._new_totem(DuelCard.new(9101, "mirewidow", 1), 1, 0, 1)
		var pup := g._new_totem(DuelCard.new(9102, "cinderpup", 0), 0, 0, 1)
		pup.relic = DuelCard.new(9103, "ember_collar", 0)
		g.players[0].slots[0] = pup
		g.players[0].slots[1] = g._new_totem(DuelCard.new(9104, "sparkkit", 0), 0, 1, 1)
		var sal := g._new_totem(DuelCard.new(9105, "hearth_salamander", 0), 0, 2, 1)
		sal.temper = {"hearth_salamander": 2}
		g.players[0].slots[2] = sal
		g.refresh_bonds()
		ds._refresh()
		await get_tree().create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/phase_c_%s.png" % [out, "flat" if flat else "3d"])
		print("PHASE C SHOT: saved %s" % ("flat" if flat else "3d"))
		ds.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
