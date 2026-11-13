extends Node
## The stone cracking under a hurt Totem (DuelCracks, 12 November). On the
## 3D field with the camera held still: the rival's three Totems at full, a
## third down and nearly gone, a still once the cracks have spread; then a
## critical blow on the whole one (the gold number, CRITICAL under it; the
## new cracks running lit, a still as they go),
## and the hurt one healed (they close). Checks each slot's reach against its
## Health, that they spread over time rather than at once, and close; and a
## knockout: the stone splitting and its chips flying as it shatters, the
## cracks staying a moment after the slot is cleared and fading.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##       res://tests/crack_shot.tscn -- <out_dir>

var out := "user://"
var ds: DuelScreen
var problems: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = true
	Game.settings["duel_camera"] = "locked"
	SummonVideo.set_mode("off")
	ds = DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 7, "speed": 1.0, "first": 0, "no_arena_events": true, "field3d": true})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	var g := ds.game
	var made := [[], []]
	var uid := 9600
	var ids := [["cinderpup", "ashen_drake", "brookfin"], ["mossling", "elderbark", "pebblit"]]
	for side in 2:
		g.players[side].slots = [null, null, null]
		for i in 3:
			var tt := g._new_totem(DuelCard.new(uid, String(ids[side][i]), side), side, i, 0)
			uid += 1
			g.players[side].slots[i] = tt
			made[side].append(tt)
	g._changed()
	ds._refresh()
	ds.mode = "busy"
	if ds.hint != null:
		ds.hint.visible = false
	await _wait(1.0)
	var foe: Array = made[1]
	(foe[1] as DuelTotem).damage = int((foe[1] as DuelTotem).max_hp() * 0.33)
	(foe[2] as DuelTotem).damage = (foe[2] as DuelTotem).max_hp() - 5
	ds._refresh()
	await _wait(0.3)
	var early := DuelCracks.reach(_slot(1, 2))
	await _wait(2.5)
	await _shot("1_whole_third_nearly_gone")
	for i in 3:
		var tt: DuelTotem = foe[i]
		var want := 1.0 - float(tt.hp_left()) / float(tt.max_hp())
		var got := DuelCracks.reach(_slot(1, i))
		print("CRACKS: %s %d/%d: reach %.2f (its Health lost %.2f)" % [tt.card_name(), tt.hp_left(), tt.max_hp(), got, want])
		var sl := _slot(1, i)
		if sl.has_meta("base_crack"):
			var cm := sl.get_meta("base_crack") as MeshInstance3D
			var mat := cm.material_override as ShaderMaterial
			print("CRACKS:   drawn %s at %s, amount %.2f, fade %.2f" % [cm.is_visible_in_tree(), cm.global_position, float(mat.get_shader_parameter("amount")), float(mat.get_shader_parameter("fade"))])
		if absf(got - want) > 0.02:
			problems.append("%s's cracks reach %.2f, not %.2f" % [tt.card_name(), got, want])
	if early > 0.6:
		problems.append("the cracks were all there at once (%.2f in 0.3 s)" % early)
	# a blow on the whole one: the new cracks run lit
	var mine: DuelTotem = made[0][1]
	var hit: DuelTotem = foe[0]
	# (a critical: a natural 20 on the strike, the number gold with CRITICAL under it)
	await ds.fx_attack(mine, 0, hit)
	ds._strike["roll"] = 20
	hit.damage += int(hit.max_hp() * 0.6)
	ds.fx_totem_hit(hit, int(hit.max_hp() * 0.6), {"attacker": mine, "element": mine.element()})
	await _wait(0.5)
	var crit_seen := false
	for n in ds.fx_layer.find_children("*", "Label", true, false):
		if (n as Label).text == "CRITICAL" or (n as Label).text.begins_with("CRITICAL"):
			crit_seen = true
	if not crit_seen:
		problems.append("the critical's number had no CRITICAL under it")
	await _wait(0.4)
	await _shot("2_critical_blow_cracks_running")
	ds._strike = {}
	await _wait(2.5)
	await _shot("3_after")
	# a knockout: the nearly-gone one broken, shattering, the stone under it
	# splitting, chips flying; then the slot cleared and the cracks fading
	var gone: DuelTotem = foe[2]
	var ko_slot := _slot(1, 2)
	var rest := gone.hp_left()
	await ds.fx_attack(mine, 0, gone)
	gone.damage += rest
	ds.fx_totem_hit(gone, rest, {"attacker": mine, "element": mine.element()})
	ds._strike = {}
	await _wait(0.4)
	ds.fx_ko(gone)
	var t_ko := 0.0
	var chips_seen := false
	while t_ko < 3.0:
		await _wait(0.1)
		t_ko += 0.1
		if ko_slot.has_node("StoneChips") and not chips_seen:
			chips_seen = true
			await _wait(0.15)
			await _shot("4_knockout_stone_splits")
	if not chips_seen:
		problems.append("no stone chips flew as it shattered")
	print("CRACKS: knocked out: reach %.2f" % DuelCracks.reach(ko_slot))
	g.players[1].slots[2] = null
	g._changed()
	ds._refresh()
	await _wait(0.6)
	var mid_fade := ko_slot.has_meta("base_crack") and (ko_slot.get_meta("base_crack") as Node3D).visible
	await _wait(2.0)
	var after := ko_slot.has_meta("base_crack") and (ko_slot.get_meta("base_crack") as Node3D).visible
	print("CRACKS: after the knockout, the cracks still there at 0.6 s: %s, at 2.6 s: %s" % [mid_fade, after])
	if not mid_fade:
		problems.append("the broken stone went the moment the slot was cleared")
	if after:
		problems.append("the broken stone never faded after the knockout")
	# healed: they close
	var healed: DuelTotem = foe[1]
	healed.damage = 0
	ds._refresh()
	await _wait(1.5)
	var after_heal := DuelCracks.reach(_slot(1, 1))
	print("CRACKS: healed %s: reach %.2f" % [healed.card_name(), after_heal])
	if after_heal > 0.01:
		problems.append("healed, its cracks didn't close (%.2f)" % after_heal)
	print("CRACKS: problems: ", problems if not problems.is_empty() else "none")
	print("CRACKS: ", "ok" if problems.is_empty() else "FAILED")
	get_tree().quit()


func _slot(side: int, i: int) -> Node3D:
	var f = ds.field
	return f.slots[side][i]


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, false).timeout


func _shot(nm: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join("cracks_%s.png" % nm))
