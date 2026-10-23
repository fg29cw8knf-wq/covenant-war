extends Node
## Stills of Phase D on the duel screen: the ground turned by a Terrain Rite
## (the emberforge over Solhaven, with its rule under the turn count),
## Continuous Rites standing beside the Wards on both sides, the Favour ring
## round each god's seal (one filling, one full) and the Oath ribbons; on the
## flat field and the 3D field; then the Oaths to choose from and full
## Favour's choice (the Gift again, or Pyraxis free).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/phase_d_shot.tscn -- <out_dir>

var out := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	get_tree().root.theme = UITheme.make()
	var p0 := Lore.new_profile("You", "", 4)
	p0["patron"] = "pyrrhane"
	var p1 := Lore.new_profile("Rival", "", 4)
	p1["patron"] = "oriel"
	for flat in [true, false]:
		var ds := DuelScreen.new().configure({"decks": ["emberstorm", "veilwild"], "names": ["You", "Rival"],
			"profiles": [p0, p1], "arena": "solhaven",
			"ai": [false, false], "seed": 43, "speed": 50.0, "field3d": not flat})   # (both waiting for a tap: the board holds still)
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
		g.players[0].slots[0] = g._new_totem(DuelCard.new(9200, "cinderpup", 0), 0, 0, 1)
		g.players[0].slots[1] = g._new_totem(DuelCard.new(9201, "blazehound", 0), 0, 1, 1)
		g.players[1].slots[1] = g._new_totem(DuelCard.new(9202, "dreamfox", 1), 1, 1, 1)
		g.players[1].slots[2] = g._new_totem(DuelCard.new(9203, "mirewidow", 1), 1, 2, 1)
		g.players[0].continuous = [DuelCard.new(9204, "kindled_banner", 0), DuelCard.new(9205, "shadow_veil", 0)]
		g.players[1].continuous = [DuelCard.new(9206, "iron_tithe", 1)]
		g.players[0].wards = [DuelCard.new(9207, "ambush_snare", 0)]
		g.players[0].favour2 = 14
		g.players[1].favour2 = DuelRules.favour_max * 2
		g.players[1].favour_ready = true
		g.players[0].oath = "unbowed"
		g.players[0].oath_state = "sworn"
		g.players[1].oath = "swift"
		g.players[1].oath_state = "broken"
		g.terrain = {"arena": "emberforge", "left": 2, "by": 0}
		g._refresh_arena_guard()
		ds._refresh()
		await ds.fx_terrain("emberforge", "rite")
		await get_tree().create_timer(1.6).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/phase_d_%s.png" % [out, "flat" if flat else "3d"])
		print("PHASE D SHOT: saved %s" % ("flat" if flat else "3d"))
		if not flat:
			# the Oaths to choose from, then full Favour's choice
			g.players[0].oath = ""
			g.players[0].oath_state = ""
			ds._offer_oaths()
			await get_tree().create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/phase_d_oaths.png" % out)
			print("PHASE D SHOT: saved oaths")
			ds._back_out()
			g.players[0].gift_used = true
			g.players[0].favour_ready = true
			g.players[0].favour2 = DuelRules.favour_max * 2
			ds._refresh()
			ds._on_gift()
			await get_tree().create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/phase_d_favour.png" % out)
			print("PHASE D SHOT: saved favour")
		ds.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
