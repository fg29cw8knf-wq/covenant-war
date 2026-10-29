extends Node
## Stills of Gary's 29 October duel notes on the duel screen (the 3D field):
##   attacks  every element's blow mid-flight and as it lands, and each kind
##            of move (melee, breath, beam, from above, wave, howl, lash)
##   cards    Rites (a blow, a boon, a blessing, a veil, a standing Rite, a
##            revival, a drain, Terrain), a Ward set and Wards springing, an
##            answer, a Relic, a stance, a condition and a boon's rings
##   ko       a Totem's crystal-and-dust knockout at four moments, for a
##            model (Cinderpup) and a painted cut-out (Thornwarden), and a
##            bounce back to the hand
##   zoom     the card panel opened out big (run it at each screen size)
##   reading  the timed words held longer: a banner, a toast, a bark
##   flight=fire_meteor,r_tide_jet,...  those blows a still every twentieth
##            of a second from the moment they're sent (to time an effect)
## Run all, or name the parts:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##       res://tests/duel_notes_shot.tscn -- <out_dir> [attacks] [cards] [ko] [zoom] [reading] [flight=...]
## --fixed-fps 30 makes every frame a thirtieth of a second of the duel however
## long it takes to draw, and nothing is drawn between the stills, so each is
## caught at its moment even on a slow software renderer.

var out := "user://"
var ds: DuelScreen
var parts: Array = []
var problems: Array = []

## [label, attacker id, move index]: one of each element, and each kind of move.
const ATTACKS := [
	["fire_fireball", "emberwisp", 0], ["fire_breath", "hearth_salamander", 1], ["fire_meteor", "ashen_drake", 2],
	["fire_melee", "cinderpup", 1], ["tide_jet", "brookfin", 0], ["tide_wave", "riptide_serpent", 1],
	["earth_fissure", "pebblit", 0], ["earth_rockfall", "quarry_golem", 1], ["storm_arc", "sparkkit", 0],
	["storm_bolt", "stormcaller", 1], ["frost_breath", "rimecub", 1], ["verdant_leaves", "mossling", 0],
	["verdant_lash", "mossling", 1], ["metal_blades", "brassback", 0], ["metal_beam", "gilded_sentinel", 1],
	["venom_glob", "plague_asp", 1], ["venom_breath", "blight_wyrm", 1], ["psychic_rings", "thought_eater", 0],
	["psychic_howl", "dreamfox", 1], ["mystic_runes", "runeowl", 1], ["spirit_beam", "lantern_moth", 0],
	["spirit_howl", "hallowed_hound", 1], ["radiant_beam", "dawnling", 1], ["umbral_wisps", "duskstalker", 0],
	["astral_star", "starling", 0], ["astral_fall", "starling", 1],
]
## The rival's blows on your side (nearer the camera): [label, attacker, move].
const ATTACKS_BACK := [
	["r_fire_fireball", "emberwisp", 0], ["r_tide_jet", "brookfin", 0], ["r_tide_wave", "riptide_serpent", 1],
	["r_earth_fissure", "pebblit", 0], ["r_storm_arc", "sparkkit", 0], ["r_verdant_leaves", "mossling", 0],
	["r_venom_glob", "plague_asp", 1], ["r_umbral_wisps", "duskstalker", 0], ["r_radiant_beam", "dawnling", 1],
	["r_psychic_howl", "dreamfox", 1], ["r_metal_blades", "brassback", 0], ["r_fire_breath", "hearth_salamander", 1],
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	parts = args.slice(1)
	if parts.is_empty():
		parts = ["attacks", "cards", "ko", "zoom", "reading"]
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = true
	RenderingServer.render_loop_enabled = false   # (drawn only for the stills, _shot)
	ds = DuelScreen.new().configure({"decks": ["tidegrove", "emberstorm"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 7, "speed": 1.0, "first": 0, "no_arena_events": true, "field3d": true})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	if "attacks" in parts:
		await _attacks()
	if "cards" in parts:
		await _cards()
	if "ko" in parts:
		await _ko()
	if "zoom" in parts:
		await _zoom()
	if "reading" in parts:
		await _reading()
	for p in parts:
		if String(p).begins_with("flight="):
			await _flight(String(p).trim_prefix("flight=").split(","))
	RenderingServer.render_loop_enabled = true
	print("NOTES SHOT: problems: ", problems if not problems.is_empty() else "none")
	print("NOTES SHOT: done")
	get_tree().quit()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


func _shot(name: String) -> void:
	RenderingServer.render_loop_enabled = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/notes_%s.png" % [out, name])
	RenderingServer.render_loop_enabled = false
	print("NOTES SHOT: saved ", name)


## Stands Totems on the field: [mine x3], [theirs x3] (null for empty).
func _board(mine: Array, theirs: Array) -> Array:
	var g := ds.game
	var made := [[], []]
	var uid := 9500 + randi() % 300 * 3
	for side in 2:
		var ids: Array = mine if side == 0 else theirs
		g.players[side].slots = [null, null, null]
		for i in 3:
			if i < ids.size() and ids[i] != null:
				var tt := g._new_totem(DuelCard.new(uid, String(ids[i]), side), side, i, 0)
				uid += 1
				g.players[side].slots[i] = tt
				made[side].append(tt)
			else:
				made[side].append(null)
	g._changed()
	ds._refresh()
	await _wait(1.2)   # (the models load and settle)
	return made


func _attacks() -> void:
	for a in ATTACKS + ATTACKS_BACK:
		var back := String(a[0]).begins_with("r_")
		var made: Array = await _board([null, "ironhide" if back else String(a[1]), null], [null, String(a[1]) if back else "ironhide", null])
		var att: DuelTotem = made[1 if back else 0][1]
		var tg: DuelTotem = made[0 if back else 1][1]
		var i := int(a[2])
		var mv := att.move(i)
		var target = tg
		if String(mv.get("target", "foe")) == "all_foes":
			target = DuelGame.NONE
		ds.mode = "busy"   # (as the duel has it while a blow plays: no hint across the field)
		ds._set_hint("")
		await ds.fx_attack(att, i, target)
		ds.fx_totem_hit(tg, 40, {"attacker": att, "element": att.element()})
		var kind := String(DuelFXStyle.attack_style(att.id(), att.element(), mv, i).kind)
		# mid-flight, then as it lands (each kind of move takes its own time)
		var mid: float = {"breath": 0.17, "beam": 0.1, "melee": 0.08, "howl": 0.14, "wave": 0.24, "lash": 0.13, "fall": 0.2}.get(kind, 0.15)
		await _wait(mid)
		await _shot("atk_%s_a" % a[0])
		await _wait(0.25 if kind != "melee" else 0.1)
		await _shot("atk_%s_b" % a[0])
		await _wait(1.4)


## Named blows (flight=fire_fireball,r_tide_jet,...) a still every twentieth
## of a second from the moment the blow is sent, to time the effects.
func _flight(labels: PackedStringArray) -> void:
	for a in ATTACKS + ATTACKS_BACK:
		if not labels.has(String(a[0])):
			continue
		var back := String(a[0]).begins_with("r_")
		var made: Array = await _board([null, "ironhide" if back else String(a[1]), null], [null, String(a[1]) if back else "ironhide", null])
		var att: DuelTotem = made[1 if back else 0][1]
		var tg: DuelTotem = made[0 if back else 1][1]
		var i := int(a[2])
		var target = tg if String(att.move(i).get("target", "foe")) != "all_foes" else DuelGame.NONE
		ds.mode = "busy"
		ds._set_hint("")
		await ds.fx_attack(att, i, target)
		ds.fx_totem_hit(tg, 40, {"attacker": att, "element": att.element()})
		for k in 12:
			await _shot("flight_%s_%02d" % [a[0], k * 5])
			await _wait(0.05)
		await _wait(1.4)


func _cards() -> void:
	var made: Array = await _board(["shieldhound", "brookfin", null], ["emberwisp", "cinderpup", null])
	var mine: DuelTotem = made[0][1]
	var foe: DuelTotem = made[1][1]
	# [card, caster, target (mine / foe / none), seconds in]
	var rites := [["firebrand", 0, "foe", 0.25], ["war_paint", 0, "mine", 0.35], ["sanctify", 0, "mine", 0.45],
		["shadow_cloak", 0, "mine", 0.5], ["kindled_banner", 0, "none", 0.45], ["kindled_soul", 0, "none", 0.75],
		["siphon_rune", 0, "foe", 0.45], ["flooded_circle", 0, "none", 0.4], ["quicken", 0, "mine", 0.3],
		["toxic_mist", 1, "none", 0.4], ["pack_howl", 0, "none", 0.35]]
	for r in rites:
		var card := DuelCard.new(9900, String(r[0]), int(r[1]))
		var target = null
		if r[2] == "mine":
			target = mine
		elif r[2] == "foe":
			target = foe
		ds.fx_rite(int(r[1]), card, target)
		await _wait(_card_up(card, int(r[1])) + float(r[3]))
		await _shot("rite_%s" % r[0])
		await _wait(2.4)
	# a Ward set, and Wards springing
	ds.fx_ward_set(1, DuelCard.new(9910, "iron_bastion", 1))
	await _wait(0.35)
	await _shot("ward_set")
	await _wait(1.5)
	for w in [["iron_bastion", {"attacker": mine, "target": foe}], ["static_field", {"attacker": mine, "target": foe}],
			["frost_snare", {"called": mine}]]:
		ds.fx_ward_spring(1, DuelCard.new(9911, String(w[0]), 1), w[1])
		await _wait(_card_up(DuelCard.new(9911, String(w[0]), 1), 1) + 0.3)
		await _shot("ward_%s" % w[0])
		await _wait(2.4)
	# an answer: Null Sigil on a blow
	ds.fx_answer(1, DuelCard.new(9912, "null_sigil", 1), {"type": "attack", "attacker": mine, "target": foe}, 1)
	await _wait(0.35)
	await _shot("answer_null_sigil")
	await _wait(2.5)
	# a Relic, Guard, a condition and a boon
	ds.fx_relic(mine, DuelCard.new(9913, "tide_pearl", 0))
	await _wait(0.55)
	await _shot("relic")
	await _wait(1.5)
	mine.stance = "guard"
	ds.fx_stance(mine)
	await _wait(0.25)
	await _shot("stance_guard")
	await _wait(1.5)
	ds.fx_status(foe, "frozen")
	await _wait(0.3)
	await _shot("status_condition")
	await _wait(1.5)
	ds.fx_status(mine, "empowered")
	await _wait(0.3)
	await _shot("status_boon")
	await _wait(1.5)


## How long a card stays up in the middle before its picture plays.
func _card_up(card: DuelCard, pi: int) -> float:
	return (ds._read_card(0.75 if pi != 0 else 0.45, card.id, pi == 0) + 0.32 + 0.24) / ds.speed


func _ko() -> void:
	for who in [["cinderpup", 1, "model"], ["thornwarden", 1, "cutout"], ["brookfin", 0, "mine"]]:
		var made: Array = await _board([null, "brookfin" if who[1] == 1 else String(who[0]), null],
			[null, String(who[0]) if who[1] == 1 else "ironhide", null])
		var t: DuelTotem = made[int(who[1])][1]
		t.damage = t.max_hp()
		ds.game.players[int(who[1])].slots[1] = null   # (as the engine has it when the knockout plays)
		ds.fx_ko(t)
		var was := 0.0
		for at in [[0.3, "1_crystal"], [0.68, "2_cracked"], [0.93, "3_burst"], [1.5, "4_dust"]]:
			await _wait(float(at[0]) - was)
			was = float(at[0])
			await _shot("ko_%s_%s" % [who[2], at[1]])
		await _wait(1.5)
		var s = ds.field.slots[int(who[1])][1]
		if s.card_id != "" or s.dying:
			problems.append("ko %s: the slot didn't clear" % who[0])
	# a bounce: back to the hand, no crystal
	var made2: Array = await _board([null, "brookfin", null], [null, "cinderpup", null])
	var b: DuelTotem = made2[1][1]
	ds.game.players[1].slots[1] = null
	ds.fx_ko(b)
	await _wait(0.3)
	await _shot("ko_bounce")
	await _wait(1.5)


func _zoom() -> void:
	var made: Array = await _board(["shieldhound", "river_hound", null], [null, "cinderpup", null])
	var rh: DuelTotem = made[0][1]
	ds._select_totem(rh)
	await _wait(0.5)
	await _shot("zoom_0_panel")
	ds.open_zoom()
	await _wait(0.1)
	await _shot("zoom_1_opening")
	await _wait(0.5)
	await _shot("zoom_2_totem")
	var sel_before = ds.sel_totem
	# a tap anywhere closes it, and puts nothing down
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(20, 20)
	ds.zoom._gui_input(ev)
	await _wait(0.4)
	if ds.zoom != null:
		problems.append("zoom: a tap didn't close it")
	if ds.sel_totem != sel_before:
		problems.append("zoom: closing it put the player's choice down")
	# a Rite, a Ward and a Relic opened out
	for id in ["toxic_mist", "iron_bastion", "tide_pearl"]:
		ds._show_detail(id, {})
		ds.open_zoom()
		await _wait(0.5)
		await _shot("zoom_3_%s" % id)
		var ek := InputEventKey.new()
		ek.physical_keycode = KEY_ESCAPE
		ek.keycode = KEY_ESCAPE
		ek.pressed = true
		Input.parse_input_event(ek)
		await _wait(0.4)
		if ds.zoom != null:
			problems.append("zoom: Esc didn't close it")
			ds.close_zoom()
			await _wait(0.3)
	ds._clear_selection()
	ds._hide_detail()


func _reading() -> void:
	for k in DuelReading.ORDER:
		DuelReading.set_level(k)
		print("NOTES SHOT: reading %s: turn banner %.2f s, reaction %.2f s, move name %.2f s, toast %.2f s, bark %.2f s" % [k,
			ds._read(0.6, "YOUR TURN") + 0.45, ds._read(0.55, "STEAM! " + String(DuelSynergy.reaction("steam").text)) + 0.45,
			ds._read(1.0, "Reckless Bite"), DuelReading.secs(1.6, "Bonded: Flood"), DuelReading.secs(2.6, "Six. Give me a six.")])
	DuelReading.set_level("normal")
	ds._toast("Bonded: Flood")
	ds._toast("Hounds together: Pack")
	await _wait(1.6)
	await _shot("reading_toasts_1_6s")
	ds._show_bark("Water. Course you'd bring water.")
	await _wait(2.9)
	await _shot("reading_bark_2_9s")
	ds._banner("STEAM!", Color("e8f2f7"), 0.55, 58, "", String(DuelSynergy.reaction("steam").text))
	await _wait(2.4)
	await _shot("reading_banner_2_4s")
	await _wait(3.0)
