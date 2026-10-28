extends Node
## Stills of the 28 October synergy on the duel screen (DuelSynergy): the
## plaque tags (a family's Kinship, SIDE, BOND, GRACED), the Graced ribbon on
## a hand card and its lower cost, whose ground it is in the corner, a family
## coming together, the floating parts of a blow, a reaction's preview chip
## and its banner, the chain on the turn line, card faces with family and
## god, a teacher's lesson (Tam on the chain), the new riddles in the list,
## and How to Duel's new chapters.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/synergy_shot.tscn -- <out_dir>

var out := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	await _duel()
	await _teacher()
	await _menu()
	await _manual()
	print("SYNERGY SHOT: done")
	get_tree().quit()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/syn_%s.png" % [out, name])
	print("SYNERGY SHOT: saved ", name)


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _start(spec: Dictionary) -> DuelScreen:
	var ds := DuelScreen.new().configure(spec)
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
		if ds.tutor != null and ds.tutor.blocking:
			ds.tutor._tapped.emit()
	return ds


func _duel() -> void:
	var ds := await _start({"decks": ["tidegrove", "emberstorm"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 5, "speed": 1.0, "first": 0, "no_arena_events": true})
	var g := ds.game
	for pl in g.players:
		pl.slots = [null, null, null]
	var sh := g._new_totem(DuelCard.new(9400, "shieldhound", 0), 0, 0, 0)
	var rh := g._new_totem(DuelCard.new(9401, "river_hound", 0), 0, 1, 0)
	var bf := g._new_totem(DuelCard.new(9402, "brookfin", 0), 0, 2, 0)
	g.players[0].slots = [sh, rh, bf]
	var ew := g._new_totem(DuelCard.new(9403, "emberwisp", 1), 1, 0, 0)
	var mo := g._new_totem(DuelCard.new(9404, "lantern_moth", 1), 1, 1, 0)
	g.players[1].slots = [ew, mo, null]
	ew.set_status("burn", 1)
	g.players[0].hand.clear()
	for id in ["travellers_pack", "firebrand", "bulwark", "essence_flask", "pack_howl"]:
		g.players[0].hand.append(g._new_card(id, 0))
	g.turn = 3
	g.players[0].essence = 5
	g.players[0].essence_max = 5
	g._changed()
	ds._refresh()
	await _wait(1.2)
	await _shot("board")
	# a family together (the first time this duel), and a pair side by side
	ds.fx_kin(0, "hound", [sh, rh])
	await _wait(0.5)
	await _shot("kin")
	await _wait(2.0)
	# aiming Brookfin's Splash at the Burned Emberwisp: STEAM on the chip
	ds._select_totem(bf)
	await _wait(0.3)
	ds._choose_move(bf, 0)
	await _wait(0.6)
	await _shot("preview_reaction")
	ds._cancel_pending()
	ds._clear_selection()
	ds._clear_actions()
	# what added up on Shieldhound's blow: Pack, Rally... and the reaction banner
	ds.fx_synergy(rh, ew, g.attack_parts(rh, 0, ew))
	await _wait(0.6)
	await _shot("parts")
	await _wait(1.5)
	ds.fx_reaction(ew, DuelSynergy.reaction("steam"))
	await _wait(0.7)
	await _shot("reaction")
	await _wait(2.5)
	# the chain: two cards played; the third is cheaper
	g.players[0].cards_played = 2
	ds._refresh()
	ds.fx_chain(0, 2)
	await _wait(0.5)
	await _shot("chain")
	await _wait(1.5)
	g.players[0].cards_played = 0
	# card faces: a Totem with its family and god, a Graced Rite
	ds._show_detail("river_hound", {"attrs": g.players[0].attributes(), "grace": g.grace_of(0, "river_hound")})
	await _wait(0.6)
	await _shot("face_totem")
	ds._hide_detail()
	ds._show_detail("travellers_pack", {"attrs": g.players[0].attributes(), "cost": g.card_cost(0, g.players[0].hand[0]), "grace": g.grace_of(0, "travellers_pack")})
	await _wait(0.6)
	await _shot("face_rite")
	ds._hide_detail()
	ds._show_detail("firebrand", {"attrs": g.players[0].attributes()})
	await _wait(0.6)
	await _shot("face_combo")
	ds._hide_detail()
	ds.queue_free()
	await _wait(0.4)


## Tam's friendly as the story sets it up: his line on the chain.
func _teacher() -> void:
	var spec: Dictionary = load("res://scripts/world/areas/ashford.gd").duel_spec({"id": "tam_friendly"})
	spec["seed"] = 3
	var ds := DuelScreen.new().configure(spec)
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	Game.v2["lessons"] = (Game.v2.get("lessons", []) as Array).filter(func(l): return String(l.get("id", "")) != "chain")
	ds.game.players[0].cards_played = 2
	ds.fx_chain(0, 2)
	await _wait(1.0)
	await _shot("tam_chain")
	if ds.tutor != null and ds.tutor.blocking:
		ds.tutor._tapped.emit()
	await _wait(0.4)
	ds.queue_free()
	await _wait(0.4)


func _menu() -> void:
	var m := PuzzleMenu.new()
	add_child(m)
	await _wait(0.8)
	await _shot("riddles_list")
	m.queue_free()
	await _wait(0.3)


## How to Duel, with the new chapters learned, scrolled to them.
func _manual() -> void:
	for id in ["aim", "family", "side", "beside", "reaction", "chain", "combo", "graced", "ground", "bond"]:
		Game.learn(id, "Synergy", "", "")
	Game.flags["first_deck"] = true
	var titles := []
	for sct in DuelManual.sections():
		titles.append(String(sct.title))
	print("SYNERGY SHOT: manual chapters: ", ", ".join(titles))
	var menu := PauseMenu.new()
	add_child(menu)
	await _wait(0.3)
	menu.open("howto")
	await _wait(0.8)
	var sc: ScrollContainer = _find_scroll(menu)
	var targets := ["WORKING TOGETHER", "REACTIONS", "THE GODS' GRACE"]
	for k in targets.size():
		if sc != null:
			var y := _find_label_y(sc, targets[k])
			sc.scroll_vertical = int(maxf(0.0, y - 20.0))
		await _wait(0.5)
		await _shot("manual_%d" % k)
	menu.queue_free()


func _find_scroll(n: Node) -> ScrollContainer:
	for c in n.find_children("*", "ScrollContainer", true, false):
		if (c as ScrollContainer).is_visible_in_tree():
			return c
	return null


func _find_label_y(sc: ScrollContainer, text: String) -> float:
	for l in sc.find_children("*", "Label", true, false):
		if (l as Label).text == text:
			return (l as Label).global_position.y - sc.get_child(0).global_position.y
	return 0.0
