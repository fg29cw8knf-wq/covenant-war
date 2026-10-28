extends SceneTree
## The ways cards work together (28 October, DuelSynergy), on the rules
## engine alone: families (Pack, Trickery, Prowl, Flight, Shed Skin, Hardened,
## Rockslide), Side by Side with Rally, Shelter and Tend, every reaction, the
## chain (the third card a turn costs 1 less; Combo), the gods' grace (by the
## ground and by standing), the new bonds, and that every card has a god.
##   godot --headless --script res://tests/synergy_test.gd

var fails := 0
var _uid := 9000


class Picker:
	extends RefCounted
	func choose_action(_g, _pi) -> Dictionary: return {"type": "end"}
	func choose_cards(_g, _pi, _p, cards: Array, min_n: int, _max_n, _c) -> Array: return cards.slice(0, maxi(1, min_n))
	func choose_totems(_g, _pi, _p, totems: Array, min_n: int, _max_n) -> Array: return totems.slice(0, min_n)
	func choose_slot(_g, _pi, _p, slots: Array, _c) -> int: return slots[0]
	func choose_reroll(_g, _pi, _i) -> bool: return false
	func choose_scry(_g, _pi, _c) -> bool: return true
	func choose_response(_g, _pi, _e, _cards) -> DuelCard: return null


func _initialize() -> void:
	_data()
	await _families()
	await _side_by_side()
	await _reactions()
	await _chain()
	await _grace()
	await _bonds()
	await _switched_off()
	print("SYNERGY TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)


func _card(id: String, owner: int) -> DuelCard:
	_uid += 1
	return DuelCard.new(_uid, id, owner)


## A board with nothing on it: no ground, no standing, turn 3, A to play.
func _game() -> DuelGame:
	var g := DuelGame.new()
	g.setup(["emberstorm", "tidegrove"], ["A", "B"], [Picker.new(), Picker.new()], [], 5)
	g.turn = 3
	g.current = 0
	g.phase = "main"
	g.god_standing = [{}, {}]
	g.place_god = "-"   # (no god's ground)
	for pl in g.players:
		pl.essence_max = 8
		pl.essence = 8
		pl.life = 150
		pl.max_life = 150
		pl.hand.clear()
	return g


func _put(g: DuelGame, pi: int, id: String, slot: int) -> DuelTotem:
	var t := g._new_totem(_card(id, pi), pi, slot, 1)
	g.players[pi].slots[slot] = t
	return t


func _data() -> void:
	for id in DuelSynergy.FAMILY_OF:
		_check(DuelCards.CARDS.has(id) and DuelCards.CARDS[id].kind == "totem", "family member %s is a Totem card" % id)
	for id in DuelCards.CARDS:
		var d: Dictionary = DuelCards.CARDS[id]
		if d.get("granted", false):
			continue
		var g := DuelSynergy.god_of(id)
		_check(g != "" and DuelSynergy.is_god(g), "%s has a god (%s)" % [id, g])
	for g in DuelSynergy.RIVALS:
		_check(DuelSynergy.rival_of(DuelSynergy.rival_of(g)) == g, "%s's rival's rival is %s" % [g, g])
	for k in ["shelter", "rally", "tend", "combo"]:
		_check(DuelCards.KEYWORDS.has(k), "keyword %s has words" % k)
	_check(DuelCards.card_text("pack_howl").contains("Hounds"), "Pack Howl's words: %s" % DuelCards.card_text("pack_howl"))


func _families() -> void:
	# Pack: each other Hound adds 10
	var g := _game()
	var a := _put(g, 0, "blazehound", 0)
	var base := g.attack_amount(a, 0, 30, null)
	_put(g, 0, "shieldhound", 2)
	_check(g.attack_amount(a, 0, 30, null) == base + 10, "Pack with one other Hound: +10 (%d, was %d)" % [g.attack_amount(a, 0, 30, null), base])
	_put(g, 0, "river_hound", 1)
	# (river_hound is beside both: no Side by Side, they're Fire, Tide and Metal)
	_check(g.attack_amount(a, 0, 30, null) == base + 20, "Pack with two others: +20 (%d)" % g.attack_amount(a, 0, 30, null))
	# Trickery: a Fox's Fate +3 with another Fox
	g = _game()
	var fox := _put(g, 0, "dreamfox", 0)
	var m0 := g.fate_mod(0, fox.affinity(), fox)
	_put(g, 0, "sparkkit", 2)
	_check(g.fate_mod(0, fox.affinity(), fox) == m0 + 3, "Trickery: +3 Fate (%d, was %d)" % [g.fate_mod(0, fox.affinity(), fox), m0])
	# Prowl: a Cat called this turn can attack with another Cat beside
	g = _game()
	_put(g, 0, "tempest_lynx", 0)
	var dusk := _put(g, 0, "duskstalker", 2)
	dusk.called_turn = g.turn
	_check(g.ready_problem(0, dusk) == "", "Prowl: a Cat called this turn may attack (%s)" % g.ready_problem(0, dusk))
	g.players[0].slots[0] = null
	_check(g.ready_problem(0, dusk) != "", "alone, it waits like any other")
	# Flight: a Winged Totem over the Totem opposite, never past a Guardian
	g = _game()
	var owl := _put(g, 0, "somnowl", 0)
	_put(g, 1, "cinderpup", 0)
	_check(not g.can_hit_life(0, owl), "alone, the owl can't reach Life past the pup")
	_put(g, 0, "runeowl", 2)
	_check(g.can_hit_life(0, owl), "Flight: with another Winged Totem it can")
	_put(g, 1, "shellguard", 1)
	_check(not g.can_hit_life(0, owl), "never past a Guardian")
	# Hardened: a Shell takes 10 less with another Shell
	g = _game()
	var att := _put(g, 1, "cinderpup", 0)
	var shell := _put(g, 0, "brassback", 0)
	var hit0 := g.attack_amount(att, 0, 30, shell)
	_put(g, 0, "shellguard", 2)
	_check(g.attack_amount(att, 0, 30, shell) == hit0 - 10, "Hardened: 10 less (%d, was %d)" % [g.attack_amount(att, 0, 30, shell), hit0])
	# Rockslide: a Stoneborn's free Strike +20, not its other moves
	g = _game()
	var peb := _put(g, 0, "pebblit", 0)
	var s0 := g.attack_amount(peb, 0, 20, null)
	var s1 := g.attack_amount(peb, 1, 30, null)
	_put(g, 0, "quarry_golem", 2)
	_check(g.attack_amount(peb, 0, 20, null) == s0 + 20, "Rockslide: the Strike +20")
	_check(g.attack_amount(peb, 1, 30, null) == s1, "...and not its stronger moves")
	# Shed Skin: Scaled Totems heal 10 for each other at Dawn
	g = _game()
	var fin := _put(g, 0, "brookfin", 0)
	_put(g, 0, "hearth_salamander", 2)
	fin.damage = 40
	await g._dawn_synergy(g.players[0])
	_check(fin.damage == 30, "Shed Skin: healed 10 (%d damage left)" % fin.damage)


func _side_by_side() -> void:
	var g := _game()
	var pup := _put(g, 0, "cinderpup", 0)
	var b0 := g.attack_amount(pup, 0, 10, null)
	var sal := _put(g, 0, "hearth_salamander", 2)
	_check(g.attack_amount(pup, 0, 10, null) == b0, "two Fire Totems a slot apart: nothing")
	g.players[0].slots[2] = null
	sal.slot = 1
	g.players[0].slots[1] = sal
	_check(g.attack_amount(pup, 0, 10, null) == b0 + 10, "side by side: +10 (%d)" % g.attack_amount(pup, 0, 10, null))
	# Rally: the Totem beside an Emberwisp deals 10 more (and the wisp is Fire too)
	g = _game()
	var kit := _put(g, 0, "sparkkit", 0)
	var k0 := g.attack_amount(kit, 0, 10, null)
	_put(g, 0, "dawnling", 1)
	_check(g.attack_amount(kit, 0, 10, null) == k0 + 10, "Rally: +10 beside the Dawnling (%d)" % g.attack_amount(kit, 0, 10, null))
	# Shelter: the Totems beside a Shellguard take 10 less from attacks
	g = _game()
	var foe := _put(g, 1, "cinderpup", 0)
	var mos := _put(g, 0, "mossling", 0)
	var h0 := g.attack_amount(foe, 0, 30, mos)
	_put(g, 0, "shellguard", 1)
	_check(g.attack_amount(foe, 0, 30, mos) == h0 - 10, "Shelter: 10 less (%d, was %d)" % [g.attack_amount(foe, 0, 30, mos), h0])
	# Tend: at Dawn, the Totems beside a Lantern Moth heal 10
	g = _game()
	var hurt := _put(g, 0, "pebblit", 0)
	_put(g, 0, "lantern_moth", 1)
	hurt.damage = 30
	await g._dawn_synergy(g.players[0])
	_check(hurt.damage == 20, "Tend: healed 10 (%d left)" % hurt.damage)


func _reactions() -> void:
	# [attacker element's Totem, status on the target, the reaction, extra check]
	var cases := [
		["cinderpup", "frozen", "melt"], ["pebblit", "frozen", "shatter"], ["brookfin", "burn", "steam"],
		["cinderpup", "poison", "flare"], ["sparkkit", "soaked", "conduct"], ["rimecub", "soaked", "freeze"],
		["mossling", "soaked", "overgrow"], ["sparkkit", "burn", "firestorm"], ["brassback", "bleed", "rend"],
		["dreamfox", "sleep", "nightmare"],
	]
	for c in cases:
		var g := _game()
		var att := _put(g, 0, String(c[0]), 0)
		var tgt := _put(g, 1, "boulderox", 1)
		var left := _put(g, 1, "pebblit", 0)
		var right := _put(g, 1, "brassback", 2)
		var plain := g.attack_amount(att, 0, 20, tgt)
		tgt.set_status(String(c[1]), 1)
		var r := DuelSynergy.reaction_for(tgt, att.element())
		_check(String(r.get("id", "")) == String(c[2]), "%s on %s is %s (got %s)" % [att.element(), c[1], c[2], r.get("id", "none")])
		if r.is_empty():
			continue
		var amt := g.attack_amount(att, 0, 20, tgt)
		var want := DuelSynergy.react_amount(g._scaled(20 + att.damage_bonus(0), tgt, att.element()), r)
		_check(amt == want, "%s: the hit is %d (want %d, plain %d)" % [r.id, amt, want, plain])
		g.phase = "main"
		att.called_turn = 1
		await g._act_attack(0, att, 0, tgt)
		match String(r.id):
			"melt": _check(tgt.has_status("soaked") and not tgt.has_status("frozen"), "Melt leaves it Soaked")
			"shatter": _check(not tgt.has_status("frozen"), "Shatter breaks the ice")
			"steam": _check(tgt.has_status("blinded") and not tgt.has_status("burn"), "Steam: the fire's out, it's Blinded")
			"flare": _check(not tgt.has_status("poison"), "Flare burns the poison away")
			"conduct": _check(left.damage == 20 and right.damage == 20, "Conduct: 20 to each beside it (%d, %d)" % [left.damage, right.damage])
			"freeze": _check(tgt.has_status("frozen"), "Freeze: it's Frozen")
			"overgrow": _check(tgt.has_status("rooted"), "Overgrow: it's Rooted")
			"firestorm": _check(left.has_status("burn") and right.has_status("burn"), "Firestorm: the Totems beside it catch")
			"rend": _check(tgt.has_status("bleed"), "Rend: still Bleeding")
			"nightmare": _check(tgt.has_status("sleep"), "Nightmare: it doesn't wake")
		_check(g.players[0].stats.reactions == 1, "%s counted" % r.id)
	# a Rite reacts too (Firebrand on a Frozen Totem melts it)
	var g2 := _game()
	var ice := _put(g2, 1, "boulderox", 0)
	ice.set_status("frozen", 1)
	var brand := _card("firebrand", 0)
	_check(g2.rite_amount(0, brand, ice, 40) == DuelSynergy.react_amount(g2._scaled(40, ice, "fire"), DuelSynergy.reaction("melt")), "a Rite's hit reacts")


func _chain() -> void:
	var g := _game()
	var p: DuelPlayer = g.players[0]
	var draught := _card("healing_draught", 0)
	var bul := _card("bulwark", 0)
	_put(g, 0, "pebblit", 0)
	_check(g.card_cost(0, bul) == 1, "Bulwark costs 1")
	p.cards_played = 2
	_check(g.card_cost(0, bul) == 0, "as the third card of the turn it costs 1 less (%d)" % g.card_cost(0, bul))
	p.cards_played = 3
	_check(g.card_cost(0, bul) == 1, "the fourth pays full")
	p.cards_played = 2
	g.current = 1
	_check(g.chain_discount(0) == 0, "not on the rival's turn")
	g.current = 0
	# counting: a Rite played through perform counts
	p.cards_played = 0
	p.hand.append(draught)
	var peb: DuelTotem = p.slots[0]
	peb.damage = 30
	await g.perform(0, {"type": "rite", "card": draught, "target": peb})
	_check(p.cards_played == 1, "a Rite counts (%d)" % p.cards_played)
	# Combo Rite: Bulwark as the third card shields 20 more
	p.cards_played = 2
	p.hand.append(bul)
	var sh0: int = peb.shield
	await g.perform(0, {"type": "rite", "card": bul, "target": peb})
	_check(peb.shield - sh0 == 50 + DuelSynergy.COMBO_BONUS, "Combo: Bulwark shields %d (want %d)" % [peb.shield - sh0, 50 + DuelSynergy.COMBO_BONUS])
	_check(p.stats.combos == 1, "the Combo counted")
	# Combo Totem: Sparkkit called as the third card comes in Empowered
	var kit := _card("sparkkit", 0)
	p.hand.append(kit)
	p.cards_played = 2
	await g.perform(0, {"type": "call", "card": kit, "slot": 1})
	var kt: DuelTotem = p.slots[1]
	_check(kt != null and kt.has_boon("empowered"), "Combo: Sparkkit comes in Empowered")
	p.cards_played = 0
	var kit2 := _card("sparkkit", 0)
	p.hand.append(kit2)
	await g.perform(0, {"type": "call", "card": kit2, "slot": 2})
	_check(not (p.slots[2] as DuelTotem).has_boon("empowered"), "as the first card, plain")


func _grace() -> void:
	# the ground: on Ellowen's (Ashford), her Traveller's Pack costs 1 less
	var g := _game()
	g.place_god = "ellowen"
	var pack := _card("travellers_pack", 0)
	_check(g.grace_of(0, "travellers_pack") == 1, "Ellowen's card on her ground is Graced")
	_check(g.card_cost(0, pack) == 1, "Graced: Traveller's Pack costs 1 (%d)" % g.card_cost(0, pack))
	# a Graced Totem hits 10 harder; on its god's rival's ground, 10 less
	g = _game()
	g.place_god = "pyrrhane"
	var pup := _put(g, 0, "cinderpup", 0)
	g.synergy.side = false
	var plain := 10 + pup.damage_bonus(0)
	_check(g.attack_amount(pup, 0, 10, null) == plain + 10, "Graced Totem: +10 (%d)" % g.attack_amount(pup, 0, 10, null))
	g.place_god = "vaelith"
	_check(g.grace_of(0, "cinderpup") == -1, "Pyrrhane's card on Vaelith's ground is Shunned")
	_check(g.attack_amount(pup, 0, 10, null) == plain - 10, "Shunned Totem: 10 less (%d)" % g.attack_amount(pup, 0, 10, null))
	var brand := _card("firebrand", 0)
	_check(g.card_cost(0, brand) == 3, "Shunned Rite: 1 more (%d)" % g.card_cost(0, brand))
	# standing: a god Pleased with you graces its cards anywhere; Displeased shuns them
	g = _game()
	g.god_standing = [{"maerith": 3, "oriel": -4}, {}]
	_check(g.grace_of(0, "brookfin") == 1 and g.grace_of(1, "brookfin") == 0, "Maerith Pleased with A: A's Brookfin Graced, B's not")
	_check(g.grace_of(0, "mind_fog") == -1, "Oriel Displeased: Mind Fog Shunned")
	# both at once cancel: Pleased god's card on its rival's ground
	g.place_god = "ysolde"
	_check(g.grace_of(0, "brookfin") == 0, "Pleased, on the rival's ground: neither")
	# the place from the Law or the arena
	_check(DuelSynergy.place_god("solmaris", "ashford") == "solmaris", "a Law's god's ground")
	_check(DuelSynergy.place_god("", "ashford") == "ellowen", "Ashford is Ellowen's")
	# a patron, for a duellist the screen gives no standing
	_check(int(DuelSynergy.standing_for({"patron": "ixara"}).get("ixara", 0)) >= DuelSynergy.PLEASED, "a patron is Pleased")


func _bonds() -> void:
	var g := _game()
	var hound := _put(g, 0, "river_hound", 0)
	var fin := _put(g, 0, "brookfin", 1)
	g.refresh_bonds()
	_check(String(hound.bond.get("name", "")) == "Flood" and String(fin.bond.get("name", "")) == "Flood", "River Hound and Brookfin: Flood")
	var flood: Dictionary = hound.moves()[-1]
	_check(String(flood.get("target", "")) == "all_foes", "Flood hits every foe")
	# Brookfin's other bond, with a Shellguard
	g = _game()
	var fin2 := _put(g, 0, "brookfin", 0)
	_put(g, 0, "shellguard", 1)
	g.refresh_bonds()
	_check(String(fin2.bond.get("name", "")) == "Riverwall", "Brookfin and Shellguard: Riverwall still")
	_check(DuelCards.bonds_of("brookfin").size() == 2, "Brookfin is in two bonds")
	_check(DuelCards.bond_text("brookfin").split("\n").size() == 2, "and its card says both")


func _switched_off() -> void:
	var g := _game()
	for k in g.synergy:
		g.synergy[k] = false
	g.place_god = "pyrrhane"
	var a := _put(g, 0, "blazehound", 0)
	var plain := g.attack_amount(a, 0, 30, null)
	_put(g, 0, "cinderpup", 1)
	_check(g.attack_amount(a, 0, 30, null) == plain, "switched off: no Pack, no Side by Side, no grace")
	g.players[0].cards_played = 2
	_check(g.card_cost(0, _card("bulwark", 0)) == 1, "switched off: no chain")
