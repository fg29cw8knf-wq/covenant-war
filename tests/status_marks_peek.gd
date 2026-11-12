extends Node
## Every effect a Totem can carry, shown on it (12 November, Gary: "every
## effect shows on the person affected somehow"; DuelStatusMarks): six at a
## time, one on each Totem on the field, a still of the field and one close
## on each side, until all 24 conditions and 6 boons have been seen; then the
## Silence leaping from a Glyph Warden onto the Totem opposite.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/status_marks_peek.tscn -- <out_dir> [arena] [only=id,id,...]
## Ends "STATUS MARKS: done".

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "user://"
	var arena: String = a[1] if a.size() > 1 and not a[1].begins_with("only=") else "ironstone"
	var all: Array = DuelConditions.DEFS.keys() + DuelConditions.BOONS.keys()
	for x in a:
		if x.begins_with("only="):
			all = Array(x.substr(5).split(","))
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
	var uid := 9600
	var ids := [["glyph_warden", "brookfin", "scrivener"], ["blazehound", "loomwarden", "glyph_warden"]]
	for side in 2:
		g.players[side].slots = [null, null, null]
		for s in 3:
			uid += 1
			g.players[side].slots[s] = g._new_totem(DuelCard.new(uid, ids[side][s], side), side, s, 0)
	g.players[0].hand.clear()
	ds._refresh()
	await get_tree().create_timer(1.5).timeout
	var n := 0
	var page := 0
	while n < all.size():
		for side in 2:
			for s in 3:
				var tt: DuelTotem = g.players[side].slots[s]
				tt.conds.clear()
				tt.boons.clear()
				tt.shield = 0
				if n >= all.size():
					continue
				var id: String = all[n]
				n += 1
				if DuelConditions.is_condition(id):
					tt.set_status(id, g.turn)
					if id == "doomed":
						tt.conds["soul"]["dawns"] = 1   # (two candles left)
				elif id == "shielded":
					tt.shield = 60
				else:
					tt.boons[id] = {"left": 2, "applied": g.turn}
				print("STATUS MARKS: page %d, %s %d: %s" % [page, "yours" if side == 0 else "theirs", s, id])
		ds._refresh()
		await get_tree().create_timer(1.6).timeout
		if ds.field != null:
			# (the moving camera off, so each still is where it's put; the
			# screen's plates and buttons hidden, so its feet and head show)
			ds.field.roam_on = false
			ds.stage.visible = false
			for side in 2:
				for s in 3:
					var tt: DuelTotem = g.players[side].slots[s]
					var fx: Array = DuelStatusMarks.effects_of(tt)
					var foot: Vector3 = ds.field.foot_world(side, s)
					var h: float = ds.field.slots[side][s].creature_h
					# from in front of it, between the rows (theirs face us; ours
					# face the other row), so nothing stands between
					var toward := Vector3(0, 0, 1) if side == 1 else Vector3(0, 0, -1)
					# (high, as the duel's own camera looks down on the field)
					ds.field.cam_shot(foot + toward * 3.4 + Vector3(0.5, h + 1.4, 0), foot + Vector3(0, h * 0.45, 0), 0.0, 62.0, true)
					await get_tree().create_timer(0.5).timeout
					await _shot(out + "/mark_%s.png" % ("_".join(fx) if not fx.is_empty() else "none_%d_%d" % [side, s]))
		page += 1
	# several at once on each, as a duel has them: the badges in a row
	var combos := [["burn", "marked", "empowered", "shielded"], ["poison", "terrified", "cursed", "regenerating"],
		["frozen", "sleep", "doomed"], ["shocked", "enraged", "hexed", "hastened", "blessed"],
		["bleed", "charmed", "drained"], ["corroded", "blinded", "veiled", "empowered", "regenerating", "shielded"]]
	var ci := 0
	for side in 2:
		for s in 3:
			var tt: DuelTotem = g.players[side].slots[s]
			tt.conds.clear()
			tt.boons.clear()
			tt.shield = 0
			for id in combos[ci]:
				if DuelConditions.is_condition(id):
					tt.set_status(id, g.turn)
				elif id == "shielded":
					tt.shield = 60
				else:
					tt.boons[id] = {"left": 2, "applied": g.turn}
			ci += 1
	# (a turn gone from your Glyph Warden's Burn, and a Dawn from the
	# Scrivener's Doom, so a spent dot shows beside the lit ones)
	(g.players[0].slots[0] as DuelTotem).conds["body"]["left"] = 1
	(g.players[0].slots[2] as DuelTotem).conds["soul"]["dawns"] = 1
	ds._refresh()
	await get_tree().create_timer(1.6).timeout
	if ds.field != null:
		for side in 2:
			for s in 3:
				var tt: DuelTotem = g.players[side].slots[s]
				var foot: Vector3 = ds.field.foot_world(side, s)
				var h: float = ds.field.slots[side][s].creature_h
				var toward := Vector3(0, 0, 1) if side == 1 else Vector3(0, 0, -1)
				ds.field.cam_shot(foot + toward * 3.4 + Vector3(0.5, h + 1.4, 0), foot + Vector3(0, h * 0.6, 0), 0.0, 62.0, true)
				await get_tree().create_timer(0.5).timeout
				await _shot(out + "/combo_%d_%d.png" % [side, s])
		# and the whole field, from about where the duel's own camera sits
		ds.stage.visible = true
		ds.field.cam_shot(Vector3(0, 8.5, 10.5), Vector3(0, 0.4, -0.5), 0.0, 52.0, true)
		await get_tree().create_timer(0.6).timeout
		await _shot(out + "/combo_field.png")
		# a tap on a badge: what the effects on that Totem do (DuelEffectTip),
		# one of yours and one of theirs
		for pick in [[0, 1, "terrified"], [1, 0, "hexed"]]:
			var slot: DuelField3D.Slot = ds.field.slots[pick[0]][pick[1]]
			var bd := (slot.marks[pick[2]] as Node3D).get_node("badge") as Node3D
			var local: Vector2 = ds.field.cam.unproject_position(bd.global_position) + ds.field.position
			var at: Vector2 = ds.get_global_transform_with_canvas() * local
			print("STATUS MARKS: tap at %s: hit %s; mode %s, pending '%s', banner %s, over a panel %s, tutor %s" % [at,
				ds.field.badge_at(ds.get_global_transform_with_canvas().affine_inverse() * at), ds.mode, ds.pending,
				ds.banner_waiting, ds._over_panel(at), ds.tutor != null and ds.tutor.blocking])
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			# (a real tap arrives in the window's pixels, scaled into the
			# screen's own by the stretch: the same here)
			var win: Vector2 = get_viewport().get_screen_transform() * at
			ev.position = win
			ev.global_position = win
			Input.parse_input_event(ev)
			var up := ev.duplicate() as InputEventMouseButton
			up.pressed = false
			Input.parse_input_event(up)
			await get_tree().create_timer(0.6).timeout
			print("STATUS MARKS: tap %s -> tip %s" % [str(pick), ds.tip != null])
			await _shot(out + "/tip_%s.png" % pick[2])
			if ds.tip != null:
				ds.tip.close()
			await get_tree().create_timer(0.4).timeout
		# the badges you can cure glowing gold (DuelScreen._cures): a Clarity
		# Tonic (Mind) and a Cleansing Bell (Soul) in your hand for the
		# Brookfin's Terrified and Cursed, but nothing for its Poison; first
		# with the Essence to play them, then without
		var mp: DuelPlayer = g.players[0]
		mp.hand.append(DuelCard.new(9001, "clarity_tonic", 0))
		mp.hand.append(DuelCard.new(9002, "cleansing_bell", 0))
		ds.stage.visible = false
		var bf: Vector3 = ds.field.foot_world(0, 1)
		var bh: float = ds.field.slots[0][1].creature_h
		for k in 2:
			mp.essence = 3 if k == 0 else 0
			ds._refresh()
			ds.field.cam_shot(bf + Vector3(0, 0, -3.4) + Vector3(0.5, bh + 1.4, 0), bf + Vector3(0, bh * 0.6, 0), 0.0, 62.0, true)
			await get_tree().create_timer(0.8).timeout
			print("STATUS MARKS: cures %s" % str(ds.cure_info))
			await _shot(out + "/cure_%s.png" % ("now" if k == 0 else "held"))
		mp.essence = 3
		ds._refresh()
		ds.stage.visible = true
		ds.field.cam_shot(Vector3(0, 8.5, 10.5), Vector3(0, 0.4, -0.5), 0.0, 52.0, true)
		await get_tree().create_timer(0.6).timeout
		var slot2: DuelField3D.Slot = ds.field.slots[0][1]
		var bd2 := (slot2.marks["cursed"] as Node3D).get_node("badge") as Node3D
		var at2: Vector2 = ds.get_global_transform_with_canvas() * (ds.field.cam.unproject_position(bd2.global_position) + ds.field.position)
		ds.badge_tap(at2)
		await get_tree().create_timer(0.6).timeout
		await _shot(out + "/tip_cure.png")
		if ds.tip != null:
			ds.tip.close()
		await get_tree().create_timer(0.4).timeout
		ds.stage.visible = false
	# the Silence leaping from your Glyph Warden onto the Blazehound opposite
	for side in 2:
		for s in 3:
			var tt: DuelTotem = g.players[side].slots[s]
			tt.conds.clear()
			tt.boons.clear()
			tt.shield = 0
	ds._refresh()
	await get_tree().create_timer(1.0).timeout
	if ds.field != null:
		ds.field.cam_shot(Vector3(-1.0, 6.5, 9.5), Vector3(-1.5, 0.5, -0.5), 0.0, 48.0, true)
	var warden: DuelTotem = g.players[0].slots[0]
	var target: DuelTotem = g.players[1].slots[0]
	ds._strike = {"attacker": warden, "target": target, "hit": {target: true}}
	target.set_status("silenced", g.turn)
	ds.fx_status(target, "silenced")
	for k in 16:
		await get_tree().create_timer(0.1).timeout
		await _shot(out + "/silence_leap_%02d.png" % k)
	await get_tree().create_timer(1.0).timeout
	await _shot(out + "/silence_after.png")
	print("STATUS MARKS: done")
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
