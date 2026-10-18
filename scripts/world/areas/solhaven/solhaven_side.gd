extends RefCounted
## Chapter 1's five side stories in Solhaven, line for line from Master
## Script v3 (Side Quests tab; a plain copy is in docs/script/v3_side_quests.md):
##
##   The Price of Mercy   Ysa and her son Tobin, the Temple's price, Brother
##                        Anselm under the dyers' bridge (wager: the Sergeant)
##   The Second Unsworn   Fen selling your blessing at the fountain (wager: Fen)
##   Pip's Errands        Pip, Mr Pell's sealed notes, the Bread of Dawn (wager: Pip)
##   The Sundial's Scar   Old Maren's nine days, Father Corvin at dawn
##   Hale's Orders        Hale at the whipping post (wager: the Captain)
##
## Each wager is sworn on the SwearScreen and played once (spec.once): win or
## lose, the story goes that way, and each duel has its rule in the engine
## (DuelGame: licensed, patter, scrapper, discipline). A game closed mid-duel
## goes straight back into it next time (flag "side_duel_on").
##
## Solhaven reaches this file through one entry point, so it can live in the
## Solhaven web pack (anything in a solhaven/ folder): solhaven.gd's build()
## calls setup(world). npcs(world) lists who to talk to, in solhaven.gd's NPC
## format; setup() spawns them itself unless they're already there. Their
## places (SidePlaces) are built off the square the first time a story needs
## one. What happened is kept in flags ("side_mercy", "side_fen", "side_pip",
## "side_scar", "side_hale", "ilvane", "wager_<id>"...) for Morrowen's Ledger
## (LedgerEntries) and the chapters where each story comes back.

const SELF := "res://scripts/world/areas/solhaven/solhaven_side.gd"
const Places := preload("res://scripts/world/areas/solhaven/side_places.gd")

## The duel rules, as the duel's banner and the swear screen show them (v3).
const RULES := {
	"licensed": ["Licensed", "The Sergeant's Rites cost nothing while you have more Totems than he does; the Temple's rules favour the Temple."],
	"patter": ["Patter", "Fen's Wards are face up, but once a turn he can swap one for a card in his hand: he talks too much to keep a secret."],
	"scrapper": ["Scrapper", "Pip's Totems hit 10 harder while he's behind."],
	"discipline": ["Discipline", "The Captain's Totems can't be Burned, Poisoned or Frozen. She plays by the book because the book is all she has."],
}

## The four wagers: what's sworn on each (v3's words), and who's across the
## Circle with which deck. The barks aren't in v3 (it has none for these
## duels); they're the game's, kept short, and listed in docs/script.
const WAGERS := {
	"mercy": {"title": "Under the Bridge", "opponent": "The Sergeant", "who": "sergeant", "deck": "dawn_watch",
		"rule": "licensed", "win": "He walks away.", "lose": "Anselm goes with him.",
		"barks": {"rule": "Licensed. Costs me nothing.", "my_lethal": "Careful, Unsworn."}},
	"fen": {"title": "The Fountain", "opponent": "Fen", "who": "fen", "deck": "painted_hand",
		"rule": "patter", "win": "He washes his hand.", "lose": "He keeps the name.",
		"barks": {"rule": "Did I say that one? I meant this one.", "rival_ward_springs": "Told you it was there. Nobody listens."}},
	"pip": {"title": "The Fountain Steps", "opponent": "Pip", "who": "pip", "deck": "street_sparks",
		"rule": "scrapper", "win": "One of his notes.", "lose": "Two crowns, to Pip.",
		"barks": {"rule": "I'm not done!", "rival_ko_own": "That one was rubbish anyway."}},
	"hale": {"title": "The Barracks Yard", "opponent": "The Captain", "who": "captain", "deck": "sun_guard",
		"rule": "discipline", "win": "His rank, and no lash.", "lose": "He takes twenty.",
		"barks": {"rule": "By the book.", "rival_ko_own": "Next."}},
}

## The opponents' decks: who they are, in cards (30 each, legal by DuelCards).
const DECKS := {
	"dawn_watch": {"name": "The Dawn Watch", "patron": "solmaris", "level": 4, "attrs": {"resolve": 1}, "difficulty": 0.5,
		"cards": {"shieldhound": 3, "brassback": 3, "ironhide": 2, "pebblit": 3, "boulderox": 2, "gilded_sentinel": 1,
			"burrowmole": 2, "forge_edge": 2, "healing_draught": 2, "sanctify": 2, "blinding_flare": 2, "bulwark": 1,
			"silence_rune": 1, "essence_flask": 1, "iron_bastion": 2, "counter_rune": 1}},
	"painted_hand": {"name": "The Painted Hand", "patron": "", "level": 4, "attrs": {"cunning": 2}, "difficulty": 0.55,
		"cards": {"dreamfox": 3, "veilfox": 2, "somnowl": 2, "thought_eater": 1, "sparkkit": 3, "voltlynx": 2,
			"thunder_ram": 2, "stormcaller": 1, "mirror_veil": 2, "counter_rune": 1, "ambush_snare": 1, "static_field": 2,
			"confounding_chime": 2, "shadow_cloak": 1, "mind_fog": 1, "heart_lure": 1, "essence_flask": 2, "quicken": 1}},
	"street_sparks": {"name": "Street Sparks", "patron": "", "level": 3, "attrs": {"swiftness": 1}, "difficulty": 0.4,
		"cards": {"cinderpup": 2, "emberwisp": 2, "sparkkit": 2, "pebblit": 2, "brookfin": 2, "mossling": 2,
			"bloomsprite": 2, "blightrat": 2, "war_paint": 2, "essence_flask": 2, "quicken": 2, "jagged_shards": 2,
			"gust_shove": 1, "healing_draught": 1, "hunters_mark": 1, "travellers_pack": 1, "ambush_snare": 2}},
	"sun_guard": {"name": "The Sun Guard", "patron": "solmaris", "level": 5, "attrs": {"resolve": 1}, "difficulty": 0.65,
		"cards": {"shieldhound": 3, "brassback": 2, "ironhide": 2, "pebblit": 2, "boulderox": 2, "gilded_sentinel": 1,
			"quarry_golem": 1, "burrowmole": 1, "bulwark": 2, "forge_edge": 2, "sanctify": 2, "cleansing_bell": 1,
			"war_paint": 1, "healing_draught": 1, "crystal_vein": 1, "iron_bastion": 2, "last_stand": 1,
			"counter_rune": 1, "ambush_snare": 1, "grondmaw": 1}},
}

## Everyone in the side stories who isn't one of the square's own NPCs: the
## name in the box, the cut-out until their model exists, and the model's
## file name from "Solhaven: Your Step-by-Step" (characters/<model>.glb).
const PEOPLE := {
	"ysa": {"name": "Ysa", "look": "side_ysa", "model": "ysa"},
	"tobin": {"name": "Tobin", "look": "child_b", "model": "tobin"},
	"healer": {"name": "Temple healer", "look": "side_healer", "model": "temple_healer"},
	"anselm": {"name": "Brother Anselm", "look": "side_anselm", "model": "anselm"},
	"docker": {"name": "Docker", "look": "farmer", "model": ""},
	"sergeant": {"name": "The Sergeant", "look": "side_sergeant", "model": "sergeant"},
	"guard_a": {"name": "Sun Guard", "look": "guard", "model": "sun_guard"},
	"guard_b": {"name": "Sun Guard", "look": "guard", "model": "sun_guard"},
	"guard_c": {"name": "Sun Guard", "look": "guard", "model": "sun_guard"},
	"guard_d": {"name": "Sun Guard", "look": "guard", "model": "sun_guard"},
	"watch_a": {"name": "Sun Guard", "look": "guard", "model": "sun_guard"},
	"watch_b": {"name": "Sun Guard", "look": "guard", "model": "sun_guard"},
	"fen": {"name": "Fen", "look": "side_fen", "model": "fen"},
	"debtor": {"name": "Debtor", "look": "farmer", "model": ""},
	"soup": {"name": "Soup-line woman", "look": "refugee", "model": ""},
	"line_a": {"name": "Refugee", "look": "child_c", "model": ""},
	"line_b": {"name": "Refugee", "look": "refugee", "model": ""},
	"crowd_1": {"name": "Onlooker", "look": "courtier", "model": ""},
	"crowd_2": {"name": "Onlooker", "look": "refugee", "model": ""},
	"crowd_3": {"name": "Onlooker", "look": "farmer", "model": ""},
	"crowd_4": {"name": "Onlooker", "look": "child_c", "model": ""},
	"crowd_5": {"name": "Onlooker", "look": "merchant", "model": ""},
	"market_1": {"name": "Shopper", "look": "courtier", "model": ""},
	"market_2": {"name": "Shopper", "look": "refugee", "model": ""},
	"market_3": {"name": "Shopper", "look": "merchant", "model": ""},
	"yard_1": {"name": "Onlooker", "look": "refugee", "model": ""},
	"yard_2": {"name": "Onlooker", "look": "farmer", "model": ""},
	"yard_3": {"name": "Onlooker", "look": "child_c", "model": ""},
	"pell": {"name": "Mr Pell", "look": "side_pell", "model": "pell"},
	"corvin": {"name": "Father Corvin", "look": "side_corvin", "model": "corvin"},
	"captain": {"name": "The Captain", "look": "side_captain", "model": "captain"},
	"hale_yard": {"name": "Hale", "look": "side_hale", "model": "hale"},
	"ref_a": {"name": "Refugee", "look": "refugee", "model": ""},
	"ref_b": {"name": "Refugee", "look": "farmer", "model": ""},
	"ref_c": {"name": "Refugee", "look": "child_c", "model": ""},
}

## The note Pip carries, on screen (v3).
const NOTE := "To His Grace the Hierarch.\n\nIronvault acknowledges a further three thousand crowns drawn against the Temple roofs, for the Bread of Dawn. Interest as before.\n\nWith respect, Ironvault."

## The spots in the square and the hub's marks, for the square this world
## has (setup() picks them: Places.square(), Places.hubs()).
static var SQ: Dictionary = Places.SQUARE
static var HUB: Dictionary = Places.HUB


# ============================================================ entry points ===

## The people to talk to in the square, in solhaven.gd's NPC format: Ysa
## (after the gate; inside the walls if she was let in, at the gate if not),
## Fen on the fountain's rim, the Great Sundial (after Old Maren's talk) and
## the barracks gateway (once Hale has been stripped of his command).
static func npcs(_w = null) -> Array:
	var out := []
	if mercy_open():
		out.append({"id": "ysa", "look": "side_ysa", "name": "Ysa", "pos": SQ.ysa_in if ysa_inside() else SQ.ysa_gate,
			"talk": [{"call": _fn("talk_ysa")}]})
	if fen_open():
		out.append({"id": "fen", "look": "side_fen", "name": "Fen", "pos": SQ.fen, "talk": [{"call": _fn("talk_fen")}],
			"duel_flag": "side_fen_settled", "duel_needs": "side_fen_pending"})
	if scar_open():
		out.append({"id": "sundial", "look": "refugee", "name": "The Great Sundial", "pos": HUB.sundial_talk,
			"talk": [{"call": _fn("talk_sundial")}], "hidden": true})
	if hale_open(_w):
		out.append({"id": "barracks", "look": "refugee", "name": "The barracks yard", "pos": HUB.barracks_talk,
			"talk": [{"call": _fn("talk_barracks")}], "hidden": true})
	return out


## Called once Solhaven's square is built: the side stories' marks in the
## square, their people, Pip's errands, and a wager duel the game was closed
## in the middle of.
static func setup(w) -> void:
	var world := w as World
	if world == null or world.attract:
		return
	SQ = Places.square(world)
	HUB = Places.hubs(world)
	Places.hub(world)
	_fn("_spawn_people").call_deferred(world)


static func _spawn_people(w: World) -> void:
	if not is_instance_valid(w):
		return
	for def in npcs(w):
		if w._npc_by_id(String(def.id)) == null:
			w._spawn_npc(def)
		var n = w._npc_by_id(String(def.id))
		if def.get("hidden", false) and n != null:
			n.doll.visible = false
	_ambient(w)
	_patch_pip(w)
	w._refresh_markers()
	if String(Game.flag("side_duel_on", "")) != "":
		_resume_duel(w)


## What stands about the square while a story waits: Tobin on his blanket by
## his mother, the crowd round Fen, Mr Pell on the counting-house steps.
static func _ambient(w: World) -> void:
	if mercy_open() and ysa_inside():
		_tobin(w, SQ.tobin_in, 0.3, true)
	if fen_open():
		var spots: Array = SQ.crowd
		for i in spots.size():
			_extra(w, "crowd_%d" % (i + 1), spots[i], SQ.fen, true)
	if pip_waiting():
		_extra(w, "pell", SQ.pell, SQ.pip_steps, true)


static func _fn(name: String) -> Callable:
	return Callable(load(SELF), name)


# ============================================================== who's open ===

static func f(key: String, default = false):
	return Game.flag(key, default)


static func s(key: String) -> String:
	var v = Game.flag(key, "")
	return String(v) if v is String else ""


## How Hale's gate was left (v3 C1): "all", "children" or "shut" (flag
## "gate", or "gate_choice", as Chapter 1 sets it; older saves:
## let_refugees_in).
static func gate_choice() -> String:
	for k in ["gate", "gate_choice"]:
		var g := s(k)
		if g in ["all", "children", "shut"]:
			return g
	if f("let_refugees_in"):
		return "all"
	if f("let_children_in"):
		return "children"
	return "shut"


## Ysa and her boy got through the gate (all of them, or the children with one
## grown-up each); otherwise they're in the camp outside.
static func ysa_inside() -> bool:
	return gate_choice() != "shut"


## Is Wren with you? (She comes with you after the alley, v3 C3.)
static func wren_with_you() -> bool:
	return bool(f("wren_joined")) or (bool(f("beat_wren")) and not f("wren_declined"))


static func mercy_open() -> bool:
	return bool(f("beat_hale")) and s("side_mercy") == ""


static func fen_open() -> bool:
	return bool(f("arrived_solhaven")) and not s("side_fen") in ["truth", "carry_on", "beaten", "won"]


static func pip_done() -> bool:
	return s("side_pip") in ["returned", "kept", "aldric", "delivered"]


## Pip is at work: met at the fountain ("Got to go. Work."; a talk that's
## over: "met_pip" is set as it starts), errand open.
static func pip_waiting() -> bool:
	return (bool(f("met_pip_before")) or bool(f("pip_errands_begun")) or bool(f("side_started_pips_errands"))) and not pip_done()


## After Old Maren's talk on the steps ("Go and look at the Sundial at dawn").
static func scar_open() -> bool:
	return (bool(f("met_maren")) or bool(f("side_started_sundial_scar"))) and s("side_scar") == ""


## Hale's Orders: only if Hale opened the gate for everyone, once you know
## he's been stripped of his command (the gate warden tells you after the
## Trial, v3 C6; in a square without a gate warden, after the Trial).
static func hale_open(w = null) -> bool:
	if gate_choice() != "all" or s("side_hale") != "":
		return false
	if f("side_started_hales_orders") or f("hales_orders_begun"):
		return true
	var warden: bool = w != null and is_instance_valid(w) and (w as World)._npc_by_id("gate_warden") != null
	return not warden and (bool(f("beat_aldric")) or bool(f("hale_stripped")))


## The main story has just started one of these stories (Chapter 1's
## solhaven.gd calls this: "pips_errands" when Pip goes to work,
## "sundial_scar" after Maren's talk, "hales_orders" when the gate warden
## says where Hale is).
static func event(w, name: String) -> void:
	var world := w as World
	if world == null or not is_instance_valid(world):
		return
	match name:
		"pips_errands":
			Game.set_flag("met_pip_before")
			var n = world._npc_by_id("pip")
			if n != null and not f("pip_at_work"):
				await _pip_to_work(world, n)
		"sundial_scar", "hales_orders":
			_spawn_people(world)


# ============================================================== staging ===

## Someone in the scene who isn't one of the square's NPCs (PEOPLE): their 3D
## model when Gary's file exists, else their cut-out. `ambient` ones stay
## about the square; the rest go when the scene ends.
static func _extra(w: World, who: String, pos: Vector3, face_to = null, ambient := false) -> Node3D:
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	var b: Node3D = null
	if ex.has(who) and is_instance_valid(ex[who].body):
		b = ex[who].body
		b.visible = true
	else:
		var p: Dictionary = PEOPLE.get(who, {"look": who, "model": ""})
		b = Node3D.new()
		b.name = "Side_" + who
		w.add_child(b)
		var d := Figure3D.make(String(p.look), String(p.get("model", "")))
		b.add_child(d)
		ex[who] = {"body": b, "doll": d}
		w.set_meta("extras", ex)
	var list: Array = w.get_meta("side_extras", []) if w.has_meta("side_extras") else []
	if not ambient and not list.has(who):
		list.append(who)
		w.set_meta("side_extras", list)
	_put(w, who, pos, face_to)
	return b


## Puts someone (the player, a square NPC or an extra) on a spot, facing a
## point or a person. Anyone moved from their place in the square goes back
## when the scene ends.
static func _put(w: World, who: String, pos: Vector3, face_to = null) -> void:
	var b := Cine.body(w, who)
	if b == null:
		return
	if who != "player" and w._npc_by_id(who) != null:
		# one of the square's people: back where they were (and as they were,
		# seen or not) when the scene ends
		var moved: Dictionary = w.get_meta("side_moved", {}) if w.has_meta("side_moved") else {}
		if not moved.has(who):
			moved[who] = [b.global_position, b.visible]
			w.set_meta("side_moved", moved)
		b.visible = true
	b.set_meta("cine_path", 0)   # stops a walk still going (Cine.path)
	b.global_position = pos
	var fig = Cine.fig(w, who)
	if fig != null:
		fig.walking = false
	if face_to != null:
		_face(w, who, face_to)


static func _face(w: World, who: String, at) -> void:
	var fig = Cine.fig(w, who)
	if fig == null:
		return
	var p: Vector3
	if at is Vector3:
		p = at
	else:
		var other := Cine.body(w, String(at))
		if other == null:
			return
		p = other.global_position
	var b := Cine.body(w, who)
	var d := p - b.global_position
	d.y = 0.0
	if d.length() < 0.01:
		return
	if fig is Figure3D:
		(fig as Figure3D).snap_face(d)
	else:
		fig.look_toward(p, w.cam)


## Tobin, lying with his fever: his own model lying down when it exists, else
## a child under a blanket.
static func _tobin(w: World, pos: Vector3, yaw: float, ambient := false) -> void:
	if Figure3D.has_model("tobin"):
		_extra(w, "tobin", pos, null, ambient)
		var fig = Cine.fig(w, "tobin")
		if fig is Figure3D:
			(fig as Figure3D).lie_down(0.01, true)
		return
	var key := "side_tobin_lying"
	var old = w.get_meta(key, null) if w.has_meta(key) else null
	if old != null and is_instance_valid(old):
		(old as Node3D).global_position = pos
		(old as Node3D).visible = true
	else:
		var n := Places.lying_child(w, pos, yaw)
		w.set_meta(key, n)
	if not ambient:
		var list: Array = w.get_meta("side_props", []) if w.has_meta("side_props") else []
		list.append(key)
		w.set_meta("side_props", list)


## Tobin up and well: whatever stood for him lying down goes.
static func _tobin_up(w: World, pos: Vector3, face_to = null) -> void:
	var lying = w.get_meta("side_tobin_lying", null) if w.has_meta("side_tobin_lying") else null
	if lying != null and is_instance_valid(lying):
		(lying as Node3D).visible = false
	var b := _extra(w, "tobin", pos, face_to)
	var fig = Cine.fig(w, "tobin")
	if fig is Figure3D:
		(fig as Figure3D).get_up(0.01)
	b.visible = true


## The camera on a shot (a cut; the scene owns the camera until _end()).
static func _shot(w: World, pos: Vector3, look: Vector3, fov := 38.0) -> void:
	Cine.shot(w, pos, look, fov)


## A cut to black and back, with everyone moved on to their marks in between
## (`put`: who -> [spot, face towards]), and the camera on its new shot.
static func _cut(w: World, put: Dictionary, cam_pos: Vector3, look: Vector3, fov := 38.0, place := "") -> void:
	w.hud.dialogue.close()
	await w.hud.fade(1.0, 0.4)
	if not w.has_meta("side_home"):
		w.set_meta("side_home", w.player.global_position)
	if place != "":
		Places.build(w, place)
	for who in put:
		var a: Array = put[who]
		var face = a[1] if a.size() > 1 else null
		if who == "player" or w._npc_by_id(who) != null or _has_extra(w, who):
			_put(w, who, a[0], face)
		else:
			_extra(w, who, a[0], face)
	_shot(w, cam_pos, look, fov)
	await w.get_tree().process_frame
	await w.hud.fade(0.0, 0.4)


static func _has_extra(w: World, who: String) -> bool:
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	return ex.has(who) and is_instance_valid(ex[who].body)


## The scene ends: black, everyone back where they were in the square (the
## scene's extras gone, the light as it was), the camera back on the player.
static func _end(w: World) -> void:
	w.hud.dialogue.close()
	await w.hud.fade(1.0, 0.45)
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	for who in (w.get_meta("side_extras", []) if w.has_meta("side_extras") else []):
		if ex.has(who):
			if is_instance_valid(ex[who].body):
				(ex[who].body as Node).queue_free()
			ex.erase(who)
	w.set_meta("side_extras", [])
	for key in (w.get_meta("side_props", []) if w.has_meta("side_props") else []):
		var n = w.get_meta(key, null) if w.has_meta(key) else null
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
		if w.has_meta(key):
			w.remove_meta(key)
	w.set_meta("side_props", [])
	var moved: Dictionary = w.get_meta("side_moved", {}) if w.has_meta("side_moved") else {}
	for who in moved:
		var b := Cine.body(w, who)
		if b != null:
			b.set_meta("cine_path", 0)   # stops a walk still going (Cine.path)
			b.global_position = moved[who][0]
			b.visible = moved[who][1]
			var fig = Cine.fig(w, who)
			if fig != null:
				fig.walking = false
	w.set_meta("side_moved", {})
	Places.dawn(w, false)
	w.player.set_meta("cine_path", 0)
	w.player_doll.walking = false
	if w.has_meta("side_home"):
		w.player.global_position = w.get_meta("side_home")
		w.remove_meta("side_home")
	w.player.velocity = Vector3.ZERO
	w.cam.fov = World.CAM_FOV
	w._focus = w._cam_focus_target()
	await w.cine_home(0.01)
	await w.get_tree().process_frame
	await w.hud.fade(0.0, 0.45)


# ================================================================ words ===

## A line from `who` (a PEOPLE id, a square NPC's id, or "player"). " | " in
## the line is a beat: the words after it come in a box of their own.
static func _say(w: World, who: String, text: String) -> void:
	var fig = Cine.fig(w, who)
	var parts := text.split(" | ")
	for i in parts.size():
		if i > 0:
			await w.get_tree().create_timer(0.35).timeout
		if fig is Figure3D:
			(fig as Figure3D).talking = true
		await w.hud.dialogue.say(_name(w, who), _portrait(w, who), w._fmt(parts[i]))
		if fig is Figure3D:
			(fig as Figure3D).talking = false


## What we see (v3's italics), in the box in italics.
static func _see(w: World, text: String) -> void:
	await w.hud.dialogue.say("", null, "[i]%s[/i]" % w._fmt(text))


static func _choose(w: World, options: Array) -> int:
	return await w.hud.dialogue.choose(options)


static func _name(w: World, who: String) -> String:
	if PEOPLE.has(who):
		return String(PEOPLE[who].name)
	return w._speaker(who)


static func _portrait(w: World, who: String) -> Texture2D:
	if PEOPLE.has(who):
		var m := String(PEOPLE[who].model)
		if m != "" and DollArt.has_portrait(m):
			return DollArt.portrait(m)
		return DollArt.portrait(String(PEOPLE[who].look))
	return w._portrait(who)


## A little movement that says what the words don't (a nod, a shrug).
static func _beat(w: World, who: String, clip := "") -> void:
	var fig = Cine.fig(w, who)
	if fig is Figure3D and clip != "":
		(fig as Figure3D).act(clip)
	elif fig != null:
		Cine.hop(w, who, 0.1)
	await w.get_tree().create_timer(0.3).timeout


static func _remember(who: String, by: int, why: String) -> void:
	Game.shift_standing(who, by, why)


# ================================================================ wagers ===

## The swear screen for one of the four wagers. True if sworn.
static func _swear(w: World, id: String) -> bool:
	w.hud.dialogue.close()
	var wg: Dictionary = WAGERS[id]
	var info := {
		"id": id, "title": wg.title, "opponent": wg.opponent, "deck": DECKS[wg.deck].name,
		"portrait": _portrait(w, String(wg.who)), "win": wg.win, "lose": wg.lose, "rule": RULES[wg.rule],
	}
	return await SwearScreen.ask(w, info)


## The wager's duel, on the v2 duel with the opponent's rule, played once.
static func duel_spec(id: String) -> Dictionary:
	var wg: Dictionary = WAGERS[id]
	var d: Dictionary = DECKS[wg.deck]
	var deck: Array = Game.v2.get("deck", [])
	if deck.is_empty():
		deck = DuelCards.card_list(Game.starter if DuelCards.DECKS.has(Game.starter) else "emberstorm")
	var prof := Lore.new_profile(String(wg.opponent), String(d.patron), int(d.level))
	for a in d.attrs:
		Lore.add_attribute(prof, a, int(d.attrs[a]))
	return {
		"decks": [deck.duplicate(), deck_cards(String(wg.deck))],
		"names": [Game.player_name, String(wg.opponent)],
		"profiles": [Game.profile, prof],
		"ai": [false, true],
		"difficulty": float(d.difficulty),
		"arena": "solhaven",
		"story": true,
		"once": true,   # a sworn wager: win or lose, it stands
		"story_rules": {String(wg.rule): 1},
		"rule": RULES[wg.rule],
		"bark_on": wg.barks,
		"rewards": {"opponent": "rival"},
		"title": "%s · %s" % [wg.title, wg.opponent],
	}


static func deck_cards(deck_id: String) -> Array:
	var out := []
	var c: Dictionary = DECKS[deck_id].cards
	for id in c:
		for i in int(c[id]):
			out.append(id)
	return out


## Plays a sworn wager's duel. While it's on, a closed game goes straight back
## into it (it never counts as a loss). Returns true if the player won.
static func _wager_duel(w: World, id: String) -> bool:
	Game.set_flag("side_duel_on", id)
	Game.save_game()
	w.hud.dialogue.close()
	var won: bool = await w._duel(duel_spec(id))
	Game.set_flag("side_duel_on", false)
	Game.set_flag("wager_" + id, "won" if won else "lost")
	Game.save_game()
	return won


## The game was closed in the middle of a wager's duel: back into it, from
## the place it was sworn, and on with the story.
static func _resume_duel(w: World) -> void:
	await w.get_tree().create_timer(1.0).timeout
	while is_instance_valid(w) and (w.hud == null or w.busy):
		await w.get_tree().create_timer(0.25).timeout
	if not is_instance_valid(w):
		return
	var id := s("side_duel_on")
	if id == "" or not WAGERS.has(id):
		return
	w.busy = true
	w.hud.set_controls_visible(false)
	match id:
		"mercy":
			await _anselm_room(w, true)
			await _mercy_after(w, await _wager_duel(w, id))
			await _mercy_close(w)
		"fen":
			await _fen_stage(w)
			await _fen_after(w, await _wager_duel(w, id))
			await _end(w)
		"pip":
			await _pip_stage(w)
			await _pip_after(w, await _wager_duel(w, id))
			await _end(w)
		"hale":
			await _yard(w)
			await _hale_after(w, await _wager_duel(w, id))
			await _end(w)
	w.hud.dialogue.close()
	w.hud.set_controls_visible(true)
	w.busy = false
	w._refresh_markers()


static func _remove_npc(w: World, id: String) -> void:
	var n = w._npc_by_id(id)
	if n == null:
		return
	w.npcs.erase(n)
	(n.body as Node).queue_free()
	if w._near == n:
		w._near = null


# ===================================================== The Price of Mercy ===

## Ysa, the woman from the gate, and her son Tobin, six (v3): the Temple of
## Dawn heals Solmaris's faithful for a copper and everyone else for forty
## crowns, or an oath. Mercy, rationed by faith.
## Where the camera looks in Ysa's corner of the square: between her and you.
static func _ysa_look() -> Vector3:
	return (SQ.ysa_in + SQ.player_ysa) * 0.5 + Vector3(0, 1.0, 0)


static func talk_ysa(w: World, _npc = null) -> void:
	if not mercy_open():
		return
	if ysa_inside():
		await _cut(w, {"ysa": [SQ.ysa_in, "player"], "healer": [SQ.healer_in, SQ.tobin_in], "player": [SQ.player_ysa, "ysa"]},
			SQ.ysa_cam, _ysa_look(), 36.0)
	else:
		await _cut(w, {"ysa": [Places.spot("camp", "ysa"), "player"], "healer": [Places.spot("camp", "healer"), Places.spot("camp", "tobin")],
			"player": [Places.spot("camp", "player"), "ysa"], "ref_a": [Places.spot("camp", "ref_a"), Places.spot("camp", "ysa")],
			"ref_b": [Places.spot("camp", "ref_b"), Places.spot("camp", "ysa")], "ref_c": [Places.spot("camp", "ref_c"), Places.spot("camp", "ysa")]},
			Places.spot("camp", "ysa") + Vector3(4.6, 2.1, 6.6), Places.spot("camp", "ysa") + Vector3(0.0, 0.9, 0.4), 36.0, "camp")
		_tobin(w, Places.spot("camp", "tobin"), 0.2)
	await _see(w, "Tobin lies on a blanket with a burn fever from the night the sky fell. A Temple healer in white is packing up her bag.")
	await _say(w, "healer", "Forty crowns, or swear to the Goddess and it's a copper. I don't set the price.")
	await _see(w, "She leaves. Ysa looks at you.")
	var healer := Cine.body(w, "healer")
	if healer != null:
		_walk(w, "healer", healer.global_position + Vector3(6.0, 0, 5.0), 1.4)
	await _say(w, "ysa", "You're the Unsworn. You don't kneel to anyone. So tell me. Should I?")
	var c := await _choose(w, ["Swear. Your son comes first.", "I'll pay it. (40 crowns)", "Don't. I'll find another way.", "That's yours to decide, not mine."])
	match c:
		0:
			await _beat(w, "ysa")
			await _say(w, "ysa", "Yes. Course.")
			await _see(w, "She takes off the little green leaf she wears on a string, and holds it a long time before she puts it in her pocket.")
			await _mercy_sworn(w, "swore")
		3:
			await _say(w, "ysa", "That's what I thought you'd say.")
			_face(w, "ysa", SQ.tobin_in if ysa_inside() else Places.spot("camp", "tobin"))
			await _beat(w, "ysa")
			await _say(w, "ysa", "Then I've decided.")
			await _mercy_sworn(w, "her_choice")
		1:
			await _say(w, "ysa", "I can't pay you back. | I'll not forget it.")
			await _see(w, "The healer comes back, counts the crowns twice, and heals the boy. Ysa keeps her leaf.")
			Game.set_flag("paid_temple")
			Game.set_flag("ilvane", "none")
			Game.set_flag("ysa_leaf", "kept")
			Game.set_flag("side_mercy", "paid")
			_remember("ysa", 2, "You paid the Temple's forty crowns for Tobin.")
			await _mercy_close(w)
		2:
			await _say(w, "ysa", "There isn't one. | Is there?")
			await _anselm(w)


## She swore (on your word, or her own): next day the boy is well.
static func _mercy_sworn(w: World, how: String) -> void:
	w.hud.dialogue.close()
	await w.hud.fade(1.0, 0.6)
	var at: Vector3 = SQ.tobin_in if ysa_inside() else Places.spot("camp", "tobin")
	_tobin_up(w, at + Vector3(0.6, 0, 0.5), "player")
	var healer := Cine.body(w, "healer")
	if healer != null:
		healer.visible = false
	await w.get_tree().create_timer(0.3).timeout
	await w.hud.fade(0.0, 0.6)
	await _see(w, "Next day Tobin is well and Ysa wears a sun disc. She thanks you, and doesn't look you in the eye.")
	Game.set_flag("ilvane", "none")
	Game.set_flag("ysa_leaf", "pocket")
	Game.set_flag("side_mercy", how)
	if how == "swore":
		_remember("solmaris", 1, "Ysa swore to the Sun for her son, on your word.")
	await _mercy_close(w)


static func _mercy_close(w: World) -> void:
	await _end(w)
	_remove_npc(w, "ysa")
	var lying = w.get_meta("side_tobin_lying", null) if w.has_meta("side_tobin_lying") else null
	if lying != null and is_instance_valid(lying):
		(lying as Node).queue_free()
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	if ex.has("tobin") and is_instance_valid(ex.tobin.body):
		(ex.tobin.body as Node).queue_free()
		ex.erase("tobin")
	Game.save_game()


## "Don't. I'll find another way." The lower town, the dyers' bridge, and
## Brother Anselm, who heals for one word.
static func _anselm(w: World) -> void:
	w.hud.dialogue.close()
	await w.hud.fade(1.0, 0.6)
	await _see(w, "In the lower town, a woman selling candles tells you there's a man under the dyers' bridge who heals for nothing, and the Sun Guard are looking for him.")
	await _anselm_room(w, false)
	await _see(w, "Under the bridge, in a room that smells of lamp oil: Brother Anselm, grey and thin, binding a docker's hand. A shrine in the corner holds one small lantern, and it is barely lit.")
	await _say(w, "anselm", "If you're the Guard, I'm nearly done. If you're not, sit down, you're in my light.")
	var docker := Cine.body(w, "docker")
	if docker != null:
		_walk(w, "docker", docker.global_position + Vector3(1.0, 0, 5.5), 1.3)
	_face(w, "anselm", "player")
	await _say(w, "anselm", "I keep Ilvane. You won't have heard of her. She was the god of people on the road at night. Carters, travellers, the lost. Four hundred years ago she had a shrine in every town.")
	await _say(w, "anselm", "Now she has me, and about three hundred people who still say her name. When nobody says it, she's gone.")
	await _say(w, "anselm", "So I heal for free, and all I ask is that they say her name once. It keeps her alive another day.")
	var c := await _choose(w, ["That's buying faith.", "Will you heal a boy?"])
	if c == 0:
		await _say(w, "anselm", "Everyone in this city is buying faith. The Temple charges forty crowns for it. I charge one word.")
		await _choose(w, ["Will you heal a boy?"])
	await _say(w, "anselm", "Bring him. Quickly; the Guard come at dusk.")
	_remember("anselm", 1, "You brought him a boy to heal.")
	# back to Ysa
	if ysa_inside():
		await _cut(w, {"ysa": [SQ.ysa_in, "player"], "player": [SQ.player_ysa, "ysa"]}, SQ.ysa_cam, _ysa_look(), 36.0)
	else:
		await _cut(w, {"ysa": [Places.spot("camp", "ysa"), "player"], "player": [Places.spot("camp", "player"), "ysa"]},
			Places.spot("camp", "ysa") + Vector3(4.6, 2.1, 6.6), Places.spot("camp", "ysa") + Vector3(0.0, 0.9, 0.4), 36.0)
	await _see(w, "Back at the camp, Ysa listens to what Anselm wants, and is quiet for a long moment.")
	await _say(w, "ysa", "One name. | The Rootmother won't mind. She's not here.")
	# at Anselm's: the name, and the leaf on the lantern
	var room := func(m: String) -> Vector3: return Places.spot("anselm", m)
	await _cut(w, {"ysa": [room.call("shrine") + Vector3(-1.0, 0, 0.5), room.call("lantern")], "anselm": [room.call("anselm"), "ysa"],
		"player": [room.call("player"), "ysa"]},
		room.call("shrine") + Vector3(0.4, 1.5, 2.7), room.call("lantern") + Vector3(-0.45, -0.15, 0.1), 38.0, "anselm")
	_tobin(w, room.call("tobin"), 0.0)
	Game.set_flag("ilvane_name_said")
	await _see(w, "At Anselm's, Ysa says the name once, quietly. Then she unties her green leaf and loops it on the handle of the shrine lantern.")
	Places.hang_leaf(w)
	Game.set_flag("ysa_leaf", "lantern")
	_remember("ysa", 1, "You found Tobin a healer who asked one word.")
	await _say(w, "ysa", "So she knows who's asking.")
	await _sergeant_arrives(w)
	await _sergeant_choice(w)


## Anselm's room, everyone on their marks (also where a resumed duel starts).
static func _anselm_room(w: World, resumed: bool) -> void:
	var at := func(m: String) -> Vector3: return Places.spot("anselm", m)
	var put := {"anselm": [at.call("anselm"), at.call("docker")], "player": [at.call("player"), "anselm"]}
	if not resumed:
		put["docker"] = [at.call("docker"), at.call("anselm")]
	else:
		put["ysa"] = [at.call("ysa"), "anselm"]
		put["sergeant"] = [at.call("sergeant"), "player"]
		put["guard_a"] = [at.call("guard_a"), "player"]
		put["guard_b"] = [at.call("guard_b") * Vector3(1, 0, 1), "player"]
	await _cut(w, put, Places.ORIGIN.anselm + Vector3(0.9, 2.0, 4.8), Places.ORIGIN.anselm + Vector3(0.0, 1.1, -2.6), 46.0, "anselm")
	if resumed:
		Places.hang_leaf(w)
		_tobin(w, at.call("tobin"), 0.0)
	w.hud.dialogue.close()


## As Tobin's fever breaks, the Sergeant and two guards come down the steps.
static func _sergeant_arrives(w: World) -> void:
	var at := func(m: String) -> Vector3: return Places.spot("anselm", m)
	_shot(w, Places.ORIGIN.anselm + Vector3(1.6, 2.2, 3.0), Places.ORIGIN.anselm + Vector3(-2.2, 1.4, -2.6), 44.0)
	var from_top := not Places.has_model("anselm_room")
	var top: Vector3 = at.call("stair_top") if from_top else Places.ORIGIN.anselm + Vector3(-3.2, 0, -3.6)
	_extra(w, "sergeant", top, "player")
	_extra(w, "guard_a", top + Vector3(0, 0, -0.3), "player")
	_extra(w, "guard_b", top + Vector3(0.1, 0, -0.6), "player")
	var down := _descend(w, "sergeant", top, at.call("sergeant"), 2.4)
	_descend(w, "guard_a", top, at.call("guard_a"), 2.8)
	_descend(w, "guard_b", top, at.call("guard_b"), 3.2)
	await _see(w, "As Tobin's fever breaks, a Sun Guard sergeant and two guards come down the steps.")
	await down
	_face(w, "anselm", "sergeant")
	_shot(w, Places.ORIGIN.anselm + Vector3(1.4, 1.9, 2.6), Places.ORIGIN.anselm + Vector3(-1.2, 1.0, -1.8), 40.0)
	await _say(w, "sergeant", "Unlicensed healing during the Turning. In the Goddess's own city. You know what that is, Brother.")
	await _say(w, "anselm", "A boy who'll live.")
	await _say(w, "sergeant", "It's heresy.")
	_face(w, "sergeant", "player")
	await _see(w, "He sees you, and your hand.")
	await _say(w, "sergeant", "And you'll be the Unsworn. Step aside.")


## Down the steps (and on to their mark), in `secs`. The walk belongs to the
## walker, so it stops if they leave the scene first.
static func _descend(w: World, who: String, from: Vector3, to: Vector3, secs: float) -> Signal:
	var b := Cine.body(w, who)
	var fig = Cine.fig(w, who)
	if fig != null:
		fig.walking = true
		fig.face(to - from, w.cam)
	var tw := b.create_tween()
	tw.tween_property(b, "global_position", to, secs).from(from)
	tw.tween_callback(func() -> void:
		if fig != null and is_instance_valid(fig):
			fig.walking = false)
	return tw.finished


## Someone walks off on level ground (out of the scene), their own walk.
static func _walk(w: World, who: String, to: Vector3, speed := 1.4) -> Signal:
	var b := Cine.body(w, who)
	to.y = b.global_position.y
	return _descend(w, who, b.global_position, to, b.global_position.distance_to(to) / maxf(speed, 0.1))


static func _sergeant_choice(w: World) -> void:
	while true:
		var c := await _choose(w, ["Then we settle it in the Circle.", "Pay his fine. (40 crowns)"])
		if c == 1:
			await _say(w, "sergeant", "Forty crowns.")
			await _see(w, "He weighs the purse.")
			await _say(w, "sergeant", "That's what it costs, then.")
			await _see(w, "He goes.")
			await _guard_leave(w, false)
			Game.set_flag("paid_fine")
			Game.set_flag("side_mercy", "anselm_fine")
			Game.set_flag("ilvane", "full")
			_remember("anselm", 1, "You paid his fine.")
			await _anselm_last(w)
			await _mercy_close(w)
			return
		if await _swear(w, "mercy"):
			var won := await _wager_duel(w, "mercy")
			await _mercy_after(w, won)
			await _mercy_close(w)
			return
		# Not yet: the Sergeant is still waiting for an answer
		await _say(w, "sergeant", "And you'll be the Unsworn. Step aside.")


static func _mercy_after(w: World, won: bool) -> void:
	_shot(w, Places.ORIGIN.anselm + Vector3(1.4, 1.9, 2.6), Places.ORIGIN.anselm + Vector3(-1.2, 1.0, -1.8), 40.0)
	if won:
		await _see(w, "He looks at Anselm, at the boy, at the lamp.")
		await _say(w, "sergeant", "I didn't see a shrine. I didn't see a boy.")
		await _see(w, "He goes back up the steps.")
		await _guard_leave(w, false)
		Game.set_flag("side_mercy", "anselm_won")
		Game.set_flag("ilvane", "full")
		_remember("anselm", 1, "You beat the Sergeant in the Circle for him.")
		_remember("solmaris", -1, "You beat a Sun Guard sergeant to keep a forgotten god's lantern lit.")
		await _anselm_last(w)
	else:
		await _say(w, "sergeant", "That's the Covenant, Unsworn.")
		await _see(w, "He takes Anselm by the arm.")
		await _say(w, "sergeant", "The boy can stay.")
		await _guard_leave(w, true)
		Game.set_flag("side_mercy", "anselm_lost")
		Game.set_flag("ilvane", "half")


## The Sergeant and his guards go back up the steps (with Anselm, if he lost).
static func _guard_leave(w: World, with_anselm: bool) -> void:
	var top: Vector3 = Places.spot("anselm", "stair_top") if not Places.has_model("anselm_room") else Places.ORIGIN.anselm + Vector3(-3.2, 0, -3.6)
	var gone := _descend(w, "sergeant", Cine.body(w, "sergeant").global_position, top, 2.4)
	for g in ["guard_a", "guard_b"]:
		var b := Cine.body(w, g)
		if b != null:
			_descend(w, g, b.global_position, top + Vector3(0, 0, -0.4), 2.6)
	if with_anselm:
		var a := Cine.body(w, "anselm")
		if a != null:
			_descend(w, "anselm", a.global_position, top + Vector3(0.2, 0, -0.2), 2.5)
	await gone
	for who in ["sergeant", "guard_a", "guard_b"] + (["anselm"] if with_anselm else []):
		var b := Cine.body(w, who)
		if b != null:
			b.visible = false


## "She's a little brighter. Can you see?"
static func _anselm_last(w: World) -> void:
	var lantern: Vector3 = Places.spot("anselm", "lantern")
	_face(w, "anselm", lantern)
	_shot(w, lantern + Vector3(-1.4, 0.2, 2.6), lantern + Vector3(-0.4, -0.3, 0.0), 36.0)
	await _say(w, "anselm", "She's a little brighter. Can you see?")
	var light := Places.shrine_light(w)
	if light != null:
		var tw := w.create_tween()
		tw.tween_property(light, "light_energy", 0.32, 2.5)
	await _see(w, "The lantern on the shrine is, very slightly.")
	await _say(w, "anselm", "You don't owe her anything for it. That's rather the point of her.")


# ===================================================== The Second Unsworn ===

## Fen, a Shardlander with a quick tongue and a hand painted white (v3):
## faith is power in Veyl, and people are starting to put theirs in you.
static func talk_fen(w: World, _npc = null) -> void:
	if not fen_open():
		return
	if s("side_fen") == "pending":
		# back after "Not yet": the Circle's still waiting
		await _fen_stage(w)
		await _say(w, "fen", "In the Circle, then. If you win, I wash my hand. If I win, I keep the name.")
		await _fen_wager(w)
		return
	await _cut(w, {"player": [SQ.fen_player, "fen"]}, SQ.fen_cam, SQ.fen_look, 38.0)
	for i in 5:
		_face(w, "crowd_%d" % (i + 1), SQ.fen)
	await _see(w, "A crowd round a fountain. A young man stands on the rim with a painted white mark on the back of his hand, touching people's foreheads for a copper each.")
	await _say(w, "fen", "Owe nothing! Kneel to nobody! The Unsworn's blessing, a copper a time, and nobody's hand on your collar after!")
	_face(w, "fen", "player")
	for i in 5:
		_face(w, "crowd_%d" % (i + 1), w.player.global_position)
	await _see(w, "He sees your hand. The real mark. The crowd sees it too.")
	await _say(w, "fen", "Ah.")
	for i in 5:
		_face(w, "crowd_%d" % (i + 1), SQ.fen)
	await _beat(w, "fen", "cheer")
	await _say(w, "fen", "My apprentice!")
	var c := await _choose(w, ["Tell them the truth.", "Talk to him first."])
	if c == 0:
		await _say(w, "fen", "All right, all right.")
		_face(w, "fen", "player")
		await _say(w, "fen", "Before you finish me off, come and see where the coppers go.")
	else:
		await _say(w, "fen", "Thank you. Come and see where the coppers go.")
	# behind the fountain: the soup line
	await _cut(w, {"fen": [SQ.behind_fen, SQ.soup], "player": [SQ.behind_player, "fen"], "soup": [SQ.soup, "fen"],
		"debtor": [SQ.debtor, "player"], "line_a": [SQ.line_a, SQ.soup], "line_b": [SQ.line_b, SQ.soup]},
		SQ.soup_cam, SQ.soup_look, 38.0)
	_soup_pot(w)
	await _see(w, "Behind the fountain, he tips most of the day's takings into the pot of a woman running a soup line for the refugees.")
	_face(w, "fen", "player")
	await _beat(w, "fen")
	await _say(w, "fen", "Soup's dear.")
	await _say(w, "debtor", "When he touched my forehead, I felt like nobody owned me. Just for a minute. | I'd pay a copper for that again.")
	var c2 := await _choose(w, ["Stop, or I'll stop you.", "Tell them the truth: owe nobody. Don't sell it.", "Carry on."])
	match c2:
		0:
			await _say(w, "fen", "In the Circle, then. If you win, I wash my hand. If I win, I keep the name.")
			await _fen_wager(w)
			return
		1:
			await _say(w, "fen", "Owe nobody.")
			await _beat(w, "fen")
			await _say(w, "fen", "Owe nobody. No copper. | It's a worse business. It's a better sermon.")
			Game.set_flag("side_fen", "truth")
			_remember("fen", 1, "You told him to give it away: owe nobody.")
		2:
			await _say(w, "fen", "Bless you.")
			await _beat(w, "fen", "cheer")
			await _say(w, "fen", "See? It comes naturally.")
			Game.set_flag("side_fen", "carry_on")
			_remember("fen", 2, "You let him carry on selling your blessing.")
	await _fen_close(w)


## A pot on a trestle, for the soup line.
static func _soup_pot(w: World) -> void:
	var key := "side_soup_pot"
	if w.has_meta(key) and is_instance_valid(w.get_meta(key)):
		return
	var n := Node3D.new()
	n.name = "SoupPot"
	w.add_child(n)
	n.global_position = SQ.soup + Vector3(0.7, 0, -0.1)   # between her and the line
	LevelKit.box(n, Vector3.ZERO, Vector3(0.6, 0.8, 1.2), "wood", false)
	LevelKit.cylinder(n, Vector3(0, 0.8, 0), 0.3, 0.36, "bronze", false, 0.34, 16)
	w.set_meta(key, n)
	var list: Array = w.get_meta("side_props", []) if w.has_meta("side_props") else []
	list.append(key)
	w.set_meta("side_props", list)


## Fen and the crowd at the fountain, for the duel's outcome.
static func _fen_stage(w: World) -> void:
	await _cut(w, {"fen": [SQ.fen, "player"], "player": [SQ.fen_player, "fen"]}, SQ.fen_cam, SQ.fen_look, 38.0)


static func _fen_wager(w: World) -> void:
	if not await _swear(w, "fen"):
		Game.set_flag("side_fen", "pending")   # he'll be on the rim when you're ready
		Game.set_flag("side_fen_pending")
		await _end(w)
		return
	var won := await _wager_duel(w, "fen")
	await _fen_stage(w)
	await _fen_after(w, won)
	await _fen_close(w)


static func _fen_after(w: World, won: bool) -> void:
	Game.set_flag("side_fen_settled")
	if won:
		_put(w, "fen", SQ.fen_wash, Vector3(0, 0, -3.5))
		await _see(w, "He washes the paint off in the fountain.")
		_face(w, "fen", "player")
		await _say(w, "fen", "There. Just a hand. | You'll find there are others. There's always others.")
		Game.set_flag("side_fen", "beaten")
		_remember("fen", -1, "You beat him in the Circle, and he washed his hand.")
	else:
		await _see(w, "He holds up his white hand to the crowd.")
		await _beat(w, "fen", "cheer")
		await _say(w, "fen", "The Unsworn's own blessing! Witnessed!")
		Game.set_flag("side_fen", "won")
		_remember("fen", 1, "He beat you in the Circle, and kept the name.")


## Fen goes about his business, and the crowd with him.
static func _fen_close(w: World) -> void:
	await _end(w)
	_remove_npc(w, "fen")
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	for i in 5:
		var k := "crowd_%d" % (i + 1)
		if ex.has(k):
			if is_instance_valid(ex[k].body):
				(ex[k].body as Node).queue_free()
			ex.erase(k)
	Game.save_game()


# ========================================================== Pip's Errands ===

## Solhaven's own Pip (solhaven.gd's NPC) runs errands once he's been met at
## the fountain: he waits on the counting-house steps with Mr Pell until his
## errand is settled, and his talk starts with this story while it's open.
## (Nothing in solhaven.gd changes: his talk is wrapped here.)
static func _patch_pip(w: World) -> void:
	var n = w._npc_by_id("pip")
	if n == null or n.def.has("side_wrapped"):
		return
	var original: Array = n.def.talk
	n.def["side_wrapped"] = true
	n.def["talk"] = [{"call": _fn("talk_pip").bind(original)}]
	n.def["duel_flag"] = "side_pip_settled"
	n.def["duel_needs"] = "side_pip_pending"
	if pip_waiting():
		# at work on the counting-house steps (Chapter 1's square leaves a
		# person with "side_home" where the side stories put them)
		Game.set_flag("pip_at_work")
		n.def["side_home"] = n.def.get("pos", n.body.global_position)
		n.body.global_position = SQ.pip_steps
		n.body.visible = true
		n.doll.look_toward(SQ.pell, w.cam)


## Pip's talk: the errand while it's open; otherwise his own words, then
## (whatever happened to the note) a place for him, if he hasn't one.
static func talk_pip(w: World, npc, original: Array) -> void:
	if bool(npc.get("side_met_now", false)):
		return   # on his way to work
	if pip_waiting() and f("pip_at_work") and s("side_pip") in ["", "seen", "pending"]:
		await _pip_errand(w)
		return
	await w.run_steps(original, npc)
	Game.set_flag("met_pip_before")
	if pip_waiting() and not f("pip_at_work"):
		w.hud.dialogue.close()
		await _pip_to_work(w, npc)
		return
	if pip_done() and s("side_pip_place") == "":
		await _pip_place(w)


## "Got to go. Work." Pip runs off to the counting-house steps, where Mr Pell
## waits with the notes.
static func _pip_to_work(w: World, npc) -> void:
	Game.set_flag("pip_at_work")
	npc["side_met_now"] = true
	var b: Node3D = npc.body
	npc.def["side_home"] = npc.def.get("pos", b.global_position)
	_extra(w, "pell", SQ.pell, SQ.pip_steps, true)
	var to: Vector3 = SQ.pip_steps
	var fig = npc.doll
	fig.walking = true
	fig.face(to - b.global_position, w.cam)
	if fig is Figure3D:
		(fig as Figure3D).gait = "run"
	var tw := b.create_tween()
	tw.tween_property(b, "global_position", to, b.global_position.distance_to(to) / 4.0)
	tw.tween_callback(func() -> void:
		fig.walking = false
		npc.erase("side_met_now")
		fig.look_toward(SQ.pell, w.cam)
		w._refresh_markers())


## The errand, seen from the start the first time; after "Not now" or "Not
## yet", straight back to the question.
static func _pip_errand(w: World) -> void:
	if s("side_pip") == "":
		await _pip_run(w)
		await _say(w, "pip", "You following me?")
		await _beat(w, "pip")
		await _say(w, "pip", "Two crowns a run. Most I've ever earned. You're not spoiling it.")
	else:
		await _pip_stage(w)
	Game.set_flag("side_pip", "seen")
	await _say(w, "pip", "And I don't open them. Open one and you don't get paid. Everyone knows that.")
	var asked := false
	while true:
		var opts := ["Duel me for one note."]
		if not asked:
			opts.append("Who's the man in grey?")
		if wren_with_you():
			opts.append("Ask Wren to lift one.")
		if asked or s("side_pip") == "pending":
			opts.append("Not now")
		var i := await _choose(w, opts)
		var pick: String = opts[i]
		match pick:
			"Who's the man in grey?":
				asked = true
				await _say(w, "pip", "Mr Pell. From the counting house. He's all right. Pays on time.")
			"Ask Wren to lift one.":
				await _wren_lifts(w)
				await _pip_note(w)
				await _end(w)
				_pip_home(w)
				return
			"Not now":
				await _end(w)
				return
			_:
				await _say(w, "pip", "You're on.")
				await _see(w, "He pulls a battered deck from his shirt.")
				await _say(w, "pip", "Bet you didn't think I had one.")
				if not await _swear(w, "pip"):
					Game.set_flag("side_pip", "pending")
					Game.set_flag("side_pip_pending")
					await _end(w)
					return
				var won := await _wager_duel(w, "pip")
				await _pip_stage(w)
				await _pip_after(w, won)
				await _end(w)
				_pip_home(w)
				return


## "Pip takes a sealed note from a man in grey by the counting-house steps,
## and runs it up the hill to a side door of the Sun Court. He comes back
## with another." And you follow him.
static func _pip_run(w: World) -> void:
	await _cut(w, {"pip": [SQ.pip_steps, "pell"], "pell": [SQ.pell, "pip"], "player": [SQ.player_follow, "pip"]},
		Vector3(7.6, 2.4, -7.8), Vector3(12.8, 1.0, -12.0), 40.0)
	var done := [false]
	_pip_route(w, done)
	await _see(w, "Pip takes a sealed note from a man in grey by the counting-house steps, and runs it up the hill to a side door of the Sun Court. He comes back with another.")
	while not done[0]:
		await w.get_tree().process_frame
	_market(w)
	_meet_shot(w)
	_face(w, "pip", "player")
	_face(w, "player", "pip")


## People about the fountain where you and Pip meet.
static func _market(w: World) -> void:
	for i in 3:
		_extra(w, "market_%d" % (i + 1), SQ.market[i], (SQ.pip_meet + SQ.player_meet) * 0.5)


## You and Pip on the fountain steps, side on (wider for Wren's lift).
static func _meet_shot(w: World, wide := false) -> void:
	var look: Vector3 = (SQ.pip_meet + SQ.player_meet) * 0.5 + Vector3(0, 0.95, 0)
	_shot(w, SQ.meet_cam + (Vector3(-0.3, 0.4, 1.4) if wide else Vector3.ZERO), look, 40.0 if wide else 36.0)


static func _pip_route(w: World, done: Array) -> void:
	await w.get_tree().create_timer(0.6).timeout
	await Cine.hop(w, "pip")
	Cine.follow(w, "pip", Vector3(-3.6, 2.6, 4.0), Vector3(0, 0.9, 0), 6.5, 2.5)
	await Cine.walk(w, "pip", SQ.side_door, 3.6, "run")
	Cine.body(w, "pip").visible = false
	Cine.walk(w, "player", SQ.player_meet, 1.6)
	await w.get_tree().create_timer(1.0).timeout
	Cine.body(w, "pip").visible = true
	await Cine.path(w, "pip", [SQ.pip_way[1], SQ.pip_way[0], SQ.pip_meet], 3.6, "run")
	done[0] = true


## Pip off up the hill to the side door.
static func _pip_up_the_hill(w: World) -> void:
	await Cine.path(w, "pip", [SQ.pip_way[0], SQ.pip_way[1], SQ.side_door], 3.6, "run")


## Pip and you on the fountain steps (also where a resumed duel starts).
static func _pip_stage(w: World) -> void:
	await _cut(w, {"pip": [SQ.pip_meet, "player"], "player": [SQ.player_meet, "pip"], "pell": [SQ.pell, SQ.pip_meet]},
		SQ.meet_cam, (SQ.pip_meet + SQ.player_meet) * 0.5 + Vector3(0, 0.95, 0), 36.0)
	_market(w)


## "If Wren is with you and you ask her, she lifts one in the crowd."
static func _wren_lifts(w: World) -> void:
	var start: Vector3 = SQ.wren_lift + Vector3(2.0, 0, 1.5)
	if w._npc_by_id("wren") != null:
		_put(w, "wren", start, "pip")
	else:
		_extra(w, "wren", start, "pip")
	_meet_shot(w, true)
	await Cine.walk(w, "wren", SQ.pip_meet + Vector3(0.5, 0, 0.6), 1.8)
	await _see(w, "Wren lifts one in the crowd.")
	await Cine.walk(w, "wren", SQ.player_meet + Vector3(-0.9, 0, 0.4), 1.8)
	_face(w, "wren", "player")
	Game.set_flag("pip_note_lifted")


static func _pip_after(w: World, won: bool) -> void:
	if not won:
		await _say(w, "pip", "Two crowns.")
		await _see(w, "He holds his hand out.")
		await _say(w, "pip", "Told you.")
		Game.set_flag("paid_pip")
		Game.set_flag("side_pip", "delivered")
		Game.set_flag("side_pip_settled")
		_remember("pip", 1, "He beat you fair for his note.")
		await _pip_up_the_hill(w)
		return
	await _pip_note(w)


## The note, on screen, and what to do with it.
static func _pip_note(w: World) -> void:
	Game.set_flag("pip_note_read")
	Game.set_flag("side_pip_settled")
	w.hud.dialogue.close()
	await NoteView.read(w, NOTE)
	if wren_with_you():
		var wb := Cine.body(w, "wren")
		if wb == null:
			_extra(w, "wren", SQ.player_meet + Vector3(-0.9, 0, 0.4), "player")
		elif not wb.visible or wb.global_position.distance_to(SQ.player_meet) > 6.0:
			_put(w, "wren", SQ.player_meet + Vector3(-0.9, 0, 0.4), "player")
		await _say(w, "wren", "The Bread of Dawn. That's the loaf they give out at dawn prayers.")
	await _see(w, "Pip reads over your arm, slowly.")
	await _say(w, "pip", "What's that mean?")
	var c := await _choose(w, ["Give it back to Pip.", "Keep it.", "Take it to Aldric."])
	if c == 0:
		await _see(w, "He snatches it, checks the seal, and runs.")
		await _say(w, "pip", "Thanks. Don't follow me again.")
		Game.set_flag("side_pip", "returned")
		_remember("pip", 1, "You gave him his note back.")
		await _pip_up_the_hill(w)
		return
	await _say(w, "pip", "That's two crowns! And Mr Pell'll know!")
	await _see(w, "He runs, not up the hill but away.")
	Cine.walk(w, "pip", SQ.pip_meet + Vector3(6.0, 0, 4.4), 4.0, "run")
	await w.get_tree().create_timer(0.8).timeout
	if c == 1:
		Game.set_flag("side_pip", "kept")
		Game.set_flag("pell_note")
		w.hud.toast("Got: %s" % Items.ITEMS.get("pell_note", {}).get("name", "the note"))
		_remember("pip", -2, "You kept his note, and his two crowns with it.")
		return
	# to Ser Aldric (where he stands in the square, or by the Duelling Circle
	# if he isn't about in the square just now)
	var at := Vector3(-9.0, 0, -9.6)
	var an = w._npc_by_id("aldric")
	if an != null and (an.body as Node3D).visible:
		at = (an.body as Node3D).global_position
	elif an == null:
		_extra(w, "aldric", at, null)
	var you := at + Vector3(0.9, 0, 1.8)
	await _cut(w, {"player": [you, "aldric"], "aldric": [at, "player"]}, you + Vector3(2.8, 1.6, 2.8), (at + you) * 0.5 + Vector3(0, 1.0, 0), 36.0)
	await _see(w, "He reads it twice.")
	await _say(w, "aldric", "The Bread of Dawn feeds three thousand people a morning. His Grace would never put the Temple in that man's debt.")
	await _see(w, "He folds it and keeps it.")
	await _say(w, "aldric", "I'll ask him.")
	Game.set_flag("side_pip", "aldric")
	_remember("aldric", 1, "You brought him Ironvault's note to the Hierarch.")
	_remember("pip", -1, "You took his note to Ser Aldric.")


## Pip back at the fountain, his errand over (and Mr Pell gone in).
static func _pip_home(w: World) -> void:
	var n = w._npc_by_id("pip")
	if n != null:
		n.body.set_meta("cine_path", 0)
		n.body.global_position = n.def.get("side_home", n.def.get("pos", n.body.global_position))
		n.body.visible = true
		n.def.erase("side_home")   # the square looks after him again
	Game.set_flag("pip_at_work", false)
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	if ex.has("pell") and is_instance_valid(ex.pell.body):
		(ex.pell.body as Node).queue_free()
		ex.erase("pell")
	w._refresh_markers()
	Game.save_game()


## "Whatever you did with the note, you can ask someone to take Pip on. Hale
## (if he still has a post) needs a runner; Aldric's stable needs a boy;
## Tamsin needs someone who can count."
static func _pip_place(w: World) -> void:
	var opts := []
	var ids := []
	if hale_has_post():
		opts.append("Hale needs a runner.")
		ids.append("hale")
	opts.append("Aldric's stable needs a boy.")
	ids.append("aldric")
	opts.append("Tamsin needs someone who can count.")
	ids.append("tamsin")
	opts.append("Not now")
	ids.append("")
	var c := await _choose(w, opts)
	if ids[c] == "":
		return
	await _see(w, "He looks at you, suspicious.")
	await _say(w, "pip", "What's the pay? | ...Does Ser Aldric go past the stables?")
	Game.set_flag("side_pip_place", ids[c])
	_remember("pip", 2, "You found him a place.")
	Game.save_game()


## Hale still has a post: he didn't open the gate for everyone, or you won his
## sentence back for him.
static func hale_has_post() -> bool:
	return gate_choice() != "all" or s("side_hale") == "won"


# ====================================================== The Sundial's Scar ===

## The first proof that the sun goddess cheated, and what it costs the person
## who kept it (v3). After Old Maren's talk on the steps; at dawn.
static func talk_sundial(w: World, _npc = null) -> void:
	if not scar_open():
		return
	w.hud.dialogue.close()
	await w.hud.fade(1.0, 0.6)
	Places.build(w, "sundial")
	Places.dawn(w, true)
	var lines: Vector3 = Places.spot("sundial", "lines")
	await _cut(w, {"player": [Places.spot("sundial", "player"), lines]}, lines + Vector3(0.6, 1.0, 2.6), lines + Vector3(0, -0.05, -0.1), 34.0, "sundial")
	await _see(w, "Dawn at the Great Sundial. Under the oldest steps, where the stone is worn smooth, the hour lines have been cut twice: the old lines filled with lead and painted gold, new lines cut nine days' shadow along.")
	await _see(w, "Somebody filled in the old lines very carefully, a very long time ago. In this light, you can still see where.")
	# a priest in white comes down the steps, smiling
	var o: Vector3 = Places.ORIGIN.sundial
	_shot(w, o + Vector3(6.2, 2.6, 14.0), o + Vector3(0.2, 1.6, 5.4), 40.0)
	_extra(w, "corvin", Places.spot("sundial", "corvin_top"), "player")
	var down := _descend(w, "corvin", Places.spot("sundial", "corvin_top"), Places.spot("sundial", "corvin"), 3.4)
	await _see(w, "A priest in white comes down the steps, smiling.")
	await down
	_face(w, "player", "corvin")
	_face(w, "corvin", "player")
	_shot(w, o + Vector3(0.6, 1.8, 13.4), o + Vector3(0.1, 0.95, 8.5), 34.0)
	await _say(w, "corvin", "Up early for a pilgrim. The Sundial's beautiful at dawn, isn't it? People come from all over.")
	await _say(w, "corvin", "Old Maren sent you, I expect. She's had a hard life. It would be such a shame to make it harder.")
	var c := await _choose(w, ["I saw nothing.", "Somebody recut these lines."])
	if c == 0:
		await _say(w, "corvin", "Good.")
		await _see(w, "He blesses you, and you let him, or you don't.")
		var b := await _choose(w, ["Let him.", "Don't."])
		if b == 0:
			Game.set_flag("corvin_blessed")
			_remember("corvin", 1, "You told him you saw nothing, and let him bless you.")
		else:
			_remember("corvin", 1, "You told him you saw nothing.")
	else:
		await _say(w, "corvin", "Two thousand years of pilgrims' feet. Stone wears.")
		await _see(w, "He keeps smiling.")
		await _say(w, "corvin", "Go and tell Maren that.")
		_remember("corvin", -1, "You told him to his face that the lines were recut.")
	# back on the temple steps, with Maren
	w.hud.dialogue.close()
	await w.hud.fade(1.0, 0.4)
	Places.dawn(w, false)
	var at := Vector3(-10.4, 0, 4.4)
	var mn = w._npc_by_id("maren")
	if mn != null and (mn.body as Node3D).visible:
		at = (mn.body as Node3D).global_position
	elif mn == null:
		_extra(w, "maren", at, null)
	var you := at + Vector3(1.0, 0, 1.6)
	await _cut(w, {"player": [you, "maren"], "maren": [at, "player"]}, you + Vector3(2.4, 1.5, 2.6), (at + you) * 0.5 + Vector3(0, 0.9, 0), 36.0)
	await _see(w, "Back on the temple steps.")
	if c == 0:
		await _say(w, "maren", "He came, didn't he. Smiling. | Well. You've got sense. More than I had.")
		Game.set_flag("side_scar", "nothing")
	else:
		await _say(w, "maren", "He came, didn't he. And you said it to his face.")
		await _see(w, "She looks at you a long while.")
		await _say(w, "maren", "Wait there.")
		await _see(w, "She goes inside and comes back with a bread tin. Inside, wrapped in oilcloth, are forty pages in a neat Temple hand.")
		await _say(w, "maren", "The old readings. I copied them the week before they threw me out. Thirty years they've been in my bread tin.")
		await _say(w, "maren", "I'm too old to be brave on my own. Take them, and send for me when it's time.")
		Game.set_flag("maren_pages")
		Game.set_flag("side_scar", "told")
		w.hud.toast("Got: %s" % Items.ITEMS.get("maren_pages", {}).get("name", "Maren's pages"))
		_remember("maren", 2, "You told Father Corvin what you saw, to his face.")
	await _end(w)
	_remove_npc(w, "sundial")
	Game.save_game()


# ========================================================== Hale's Orders ===

## Someone paying for your good deed, and whether you let them (v3). Only if
## you made Hale open the gate for everyone.
static func talk_barracks(w: World, _npc = null) -> void:
	if not hale_open(w):
		return
	await _yard(w)
	await _see(w, "The barracks yard. Hale stands without his white and gold, in a plain shirt, by the whipping post. The Captain reads from a paper.")
	await _say(w, "captain", "Ten lashes, for opening the Goddess's gate against the Hierarch's order. At noon.")
	_face(w, "hale_yard", "player")
	_shot(w, Places.spot("barracks", "hale") + Vector3(1.2, 1.7, 3.0), Places.spot("barracks", "hale") + Vector3(0.3, 1.2, 0), 34.0)
	await _say(w, "hale_yard", "Don't.")
	await _say(w, "hale_yard", "I opened it. Nobody made me. It's mine to pay.")
	_wide_yard(w)
	var c := await _choose(w, ["Then I'll stand with you.", "I'll duel for his sentence."])
	if c == 0:
		await _hale_stand(w)
	else:
		_face(w, "captain", "hale_yard")
		await _say(w, "captain", "A sworn duel over a Sun Guard sentence?")
		_face(w, "captain", Places.spot("barracks", "crowd_b"))
		await _see(w, "She looks at Hale, then at the crowd gathering at the gate.")
		_face(w, "captain", "player")
		await _say(w, "captain", "If you win, it's his rank and no lash. If you lose, he takes twenty. Still want it?")
		while true:
			if await _choose(w, ["Yes.", "No."]) == 1:
				await _hale_stand(w)
				break
			if await _swear(w, "hale"):
				var won := await _wager_duel(w, "hale")
				await _yard(w)
				await _hale_after(w, won)
				break
			# Not yet: she asks again
			await _say(w, "captain", "Still want it?")
	await _end(w)
	_remove_npc(w, "barracks")
	Game.save_game()


## The barracks yard, everyone on their marks.
static func _yard(w: World) -> void:
	var at := func(m: String) -> Vector3: return Places.spot("barracks", m)
	var put := {"hale_yard": [at.call("hale"), at.call("post")], "captain": [at.call("captain"), "hale_yard"],
		"player": [at.call("player"), "hale_yard"]}
	for g in ["guard_a", "guard_b", "guard_c", "guard_d"]:
		put[g] = [at.call(g), at.call("post")]
	for g in ["watch_a", "watch_b"]:
		put[g] = [at.call(g), at.call("post")]
	await _cut(w, put, Places.ORIGIN.barracks + Vector3(0.6, 3.0, 10.6), Places.ORIGIN.barracks + Vector3(0, 1.0, -1.6), 46.0, "barracks")
	var gate := ["crowd_a", "crowd_b", "crowd_c"]
	for i in gate.size():
		_extra(w, "yard_%d" % (i + 1), at.call(gate[i]), at.call("post"))


static func _wide_yard(w: World) -> void:
	_shot(w, Places.ORIGIN.barracks + Vector3(0.6, 3.0, 10.6), Places.ORIGIN.barracks + Vector3(0, 1.0, -1.6), 46.0)


## "Then I'll stand with you." (And if you'd rather not duel for him, the same.)
static func _hale_stand(w: World) -> void:
	_shot(w, Places.spot("barracks", "hale") + Vector3(1.2, 1.7, 3.0), Places.spot("barracks", "hale") + Vector3(0.3, 1.2, 0), 34.0)
	await _beat(w, "hale_yard")
	await _say(w, "hale_yard", "Suit yourself.")
	await _noon(w, 10)
	await _say(w, "hale_yard", "You stood there. | Most don't.")
	Game.set_flag("side_hale", "stood")
	_remember("hale", 2, "You stood where he could see you while he took ten lashes.")


static func _hale_after(w: World, won: bool) -> void:
	_shot(w, Places.spot("barracks", "hale") + Vector3(1.2, 1.7, 3.0), Places.spot("barracks", "hale") + Vector3(0.3, 1.2, 0), 34.0)
	if won:
		_face(w, "hale_yard", "player")
		await _see(w, "He pulls his shirt back on, furious.")
		await _say(w, "hale_yard", "You don't let a man pay his own way, do you. | Thank you.")
		Game.set_flag("side_hale", "won")
		_remember("hale", 1, "You duelled the Captain for his sentence, and won it.")
	else:
		await _see(w, "Before they take him to the post.")
		await _say(w, "hale_yard", "Twenty, then. | Stand where I can see you.")
		await _noon(w, 20)
		Game.set_flag("side_hale", "lost")
		_remember("hale", 1, "You duelled for his sentence and lost. He took twenty.")


## Noon at the post. Full: the lash, each stroke; the camera stays on Hale's
## face, then yours. Reduced: the camera stays on the guards' faces, and you
## hear it.
static func _noon(w: World, strokes: int) -> void:
	w.hud.dialogue.close()
	await w.hud.fade(1.0, 0.6)
	var at := func(m: String) -> Vector3: return Places.spot("barracks", m)
	_put(w, "player", at.call("player") + Vector3(-0.6, 0, -0.8), at.call("post"))
	_put(w, "watch_a", at.call("player") + Vector3(-1.8, 0, -0.5), at.call("post"))
	_put(w, "watch_b", at.call("player") + Vector3(0.8, 0, -0.6), at.call("post"))
	_put(w, "hale_yard", at.call("post") + Vector3(0, 0, 0.42), at.call("post"))
	_put(w, "captain", at.call("post") + Vector3(-1.6, 0, 1.6), at.call("hale"))
	_wide_yard(w)
	await w.hud.fade(0.0, 0.6)
	await _see(w, "Noon. You stand at the front of the watching guards. Hale looks at you once, before.")
	w.hud.dialogue.close()
	var full := String(Game.settings.get("violence", "full")) == "full"
	var sfx := Sfx.new()
	w.add_child(sfx)
	var hale_face: Vector3 = at.call("post") + Vector3(0, 1.5, 0.42)
	var you_face: Vector3 = Cine.body(w, "player").global_position + Vector3(0, 1.45, 0)
	if full:
		_shot(w, at.call("post") + Vector3(0.9, 1.7, -1.6), hale_face, 30.0)
	else:
		_shot(w, at.call("post") + Vector3(0.4, 1.7, 0.7), (Cine.body(w, "watch_a").global_position + Cine.body(w, "watch_b").global_position) * 0.5 + Vector3(0, 1.45, 0), 34.0)
	var gap := 1.1 if strokes <= 10 else 0.7
	var half := int(strokes / 2.0)
	for i in strokes:
		if full and i == half:
			_shot(w, you_face + Vector3(0.6, 0.15, -2.6), you_face, 30.0)
		if Sfx.has_file("lash"):
			sfx.play("lash", randf_range(0.95, 1.05))
		else:
			# until Gary's lash sound exists: a whistle and a crack
			sfx.play("melee_whoosh", 1.5)
			w.get_tree().create_timer(0.12).timeout.connect(func() -> void:
				if is_instance_valid(sfx):
					sfx.play("hit_light", 0.8))
		if full and i < half:
			w.shake(0.12)
		await w.get_tree().create_timer(gap).timeout
	await w.get_tree().create_timer(0.6).timeout
	sfx.queue_free()
	_face(w, "hale_yard", "player")
	_shot(w, at.call("hale") + Vector3(1.2, 1.7, 3.0), at.call("hale") + Vector3(0.3, 1.2, 0), 34.0)


# ============================================================ the note ===

## A letter held up to read (Mr Pell's note to the Hierarch): a sheet with
## the words on it and Ironvault's seal. A tap puts it down.
class NoteView:
	extends Control
	signal closed
	var body := ""
	var _t := 0.0
	var _done := false

	static func read(w: World, text: String) -> void:
		var layer := CanvasLayer.new()
		layer.layer = 16
		w.add_child(layer)
		var v := NoteView.new()
		v.name = "NoteView"
		v.body = text
		layer.add_child(v)
		await v.closed
		var tw := v.create_tween()
		tw.tween_property(v, "modulate:a", 0.0, 0.3)
		await tw.finished
		layer.queue_free()

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			accept_event()
			_close()

	func _unhandled_input(e: InputEvent) -> void:
		if e.is_action_pressed("interact") or e.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_close()

	func _close() -> void:
		if _done or _t < 1.2:
			return
		_done = true
		closed.emit()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var sz := size
		draw_rect(Rect2(Vector2.ZERO, sz), Color(0.01, 0.01, 0.02, 0.62))
		var safe := SafeArea.rect()
		var h := minf(safe.size.y * 0.78, 820.0)
		var wd := minf(h * 0.82, safe.size.x - 80.0)
		var r := Rect2(safe.position + (safe.size - Vector2(wd, h)) * 0.5 + Vector2(0, -14), Vector2(wd, h))
		CardFace.box(self, r, 6, Color(0.88, 0.84, 0.74), Color(0.55, 0.47, 0.34), 2, 18, Color(0, 0, 0, 0.6), Vector2(0, 8))
		for i in 5:
			draw_rect(r.grow(-i * 6.0), Color(0.4, 0.32, 0.2, 0.05), false, 6.0)
		var fnt := CardFace.font("display")
		var px := int(clampf(wd / 17.0, 22.0, 40.0))
		var margin := wd * 0.1
		var y := r.position.y + h * 0.1
		var ink := Color(0.12, 0.1, 0.09)
		for para in body.split("\n"):
			if para == "":
				y += px * 0.6
				continue
			var line := ""
			for word in para.split(" "):
				var trial: String = word if line == "" else line + " " + word
				if fnt.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > wd - margin * 2.0 and line != "":
					CardFace.text(self, fnt, Vector2(r.position.x + margin, y + px), line, px, ink)
					y += px * 1.42
					line = word
				else:
					line = trial
			if line != "":
				CardFace.text(self, fnt, Vector2(r.position.x + margin, y + px), line, px, ink)
				y += px * 1.42
		# Ironvault's seal: dark red wax, a coin crossed with a key
		var sc := Vector2(r.end.x - wd * 0.2, r.end.y - h * 0.13)
		var sr := wd * 0.07
		draw_circle(sc + Vector2(3, 4), sr * 1.05, Color(0, 0, 0, 0.25))
		for i in 9:
			var a := TAU * i / 9.0
			draw_circle(sc + Vector2(cos(a), sin(a)) * sr * 0.82, sr * 0.32, Color(0.42, 0.06, 0.06))
		draw_circle(sc, sr, Color(0.48, 0.07, 0.07))
		draw_arc(sc, sr * 0.55, 0, TAU, 32, Color(0.26, 0.03, 0.03), sr * 0.12, true)
		var kd := Vector2(cos(-0.8), sin(-0.8))
		draw_line(sc - kd * sr * 0.8, sc + kd * sr * 0.6, Color(0.26, 0.03, 0.03), sr * 0.14, true)
		if _t > 1.2:
			var al := 0.6 + 0.3 * sin(_t * 4.0)
			CardFace.text(self, CardFace.font("body"), Vector2(0, minf(r.end.y + 46, safe.end.y - 10)), "Tap to put it down", 28, Color(1, 1, 1, al), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
