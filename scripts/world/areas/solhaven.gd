extends RefCounted
## Solhaven — Chapter 1: The Sun's Court (Master Script v3; a copy of its
## lines is in docs/script/v3_chapter1.md).
##
## Seven scenes. The Golden Gate (C1, Warden Hale's duel) and the wagon (C2)
## play as one film on arrival; then the Sun Square is the hub: Bram at the
## wagon, Tamsin's stall, Pip at the fountain, Old Maren on the temple steps,
## the notice board. On the way to the Sun Court the crowd thickens and Wren
## takes the blank card (C3: the chase, the alley duel); the temple's doors
## open on the Sun Court (C4: Solmaris stops time) and, next time, on the Hall
## of Mirrors (C5: the Trial of Light); the Sunspire's door, west, leads up to
## Ser Aldric (C6). Afterwards, Bram at the wagon ends the day: Gold in the
## Dark (C7) closes the chapter. Each film saves where it is (flag sol_film),
## so a closed game picks it up again; a duel it was in goes straight back to
## the duel.
##
## The place is the SolhavenSet (scripts/world/solhaven/solhaven_set.gd), the
## films are in films.gd and the duels in duels.gd beside it: all of it travels
## in the web build's Solhaven pack.
##
## The five side stories hook in through
## scripts/world/areas/solhaven/solhaven_side.gd when it exists (see side()
## below): build() calls its setup(world), which spawns its own people and
## marks in the square; if it has event(world, name), it's told when the main
## story starts one of its stories ("pips_errands", "sundial_scar",
## "hales_orders"). The flags it reads are set here: gate (and gate_choice),
## wren_declined, hale_stripped, beat_hale, beat_wren, beat_aldric.

const SolSet := preload("res://scripts/world/solhaven/solhaven_set.gd")
const Films := preload("res://scripts/world/solhaven/films.gd")

const NAME := "Solhaven"
const SUBTITLE := "The Sun Square"

const BOUNDS := Rect2(-15.5, -18.4, 31.0, 41.8)  # x, z, width, depth the player can walk
const CAMERA_X_LIMIT := 7.0
## The set builds its own sky and light (day, the Sun Court, the field at night...).
const CUSTOM_ENV := true
## Arriving for the first time is the film of the Golden Gate (intro_frame()).
const INTRO := true
## A film left part-way picks up where it was (resume()).
const RESUMES := true

const SPAWNS := {
	"gate": Vector3(0, 0, 21.0),
	"road": Vector3(0, 0, 34.0),
	"wagon": Vector3(10.4, 0, -1.2),
	"inn": Vector3(10.5, 0, 1.5),
	"temple": Vector3(0, 0, -15.5),
	"circle": Vector3(-12.0, 0, -9.0),
}
const ENV := {}
## The square's music between scenes (Gary's solhaven_town when it's in).
const MUSIC := ["solhaven_town", "solhaven_dawn"]
const SIDE := "res://scripts/world/areas/solhaven/solhaven_side.gd"


## The side stories' script, when it's there (null otherwise).
static func side() -> Script:
	return load(SIDE) if ResourceLoader.exists(SIDE) else null


## Tells the side stories the main story has just started one of theirs.
static func side_event(w: World, name: String) -> void:
	Game.set_flag("side_started_" + name)
	var s := side()
	if s != null and s.has_method("event"):
		await s.event(w, name)


## The people of the square. Who is actually there depends on how far the
## story has gone (people()); the side stories add their own.
static func npcs() -> Array:
	var out := [
		{"id": "bram", "look": "bram", "name": "Bram", "pos": Vector3(10.6, 0, -1.6), "talk": _bram()},
		{"id": "tamsin", "look": "merchant", "name": "Tamsin", "pos": Vector3(11.5, 0, 6.4), "talk": _tamsin()},
		{"id": "pip", "look": "child", "name": "Pip", "pos": Vector3(-3.4, 0, -1.4), "talk": _pip()},
		{"id": "maren", "look": "elder", "name": "Old Maren", "pos": Vector3(-6.4, 0, -17.5), "talk": _maren()},
		{"id": "board", "look": "courtier", "name": "The notice board", "pos": Vector3(-12.6, 0, 2.0), "talk": _board()},
		{"id": "wren", "look": "wren", "name": "Wren", "pos": Vector3(14.6, 0, -2.4), "talk": _wren()},
		{"id": "liora", "look": "acolyte", "name": "Liora", "pos": Vector3(6.2, 0, -17.5), "talk": _liora()},
		{"id": "aldric", "look": "aldric", "name": "Ser Aldric Vane", "pos": Vector3(-4.0, 0, -11.0), "talk": _aldric()},
		{"id": "hale", "look": "guard", "name": "Warden Hale", "pos": Vector3(3.4, 0, 21.4), "talk": _hale()},
		{"id": "gate_warden", "look": "guard", "name": "Gate warden", "pos": Vector3(3.4, 0, 21.4), "talk": _gate_warden()},
	]
	return out


## Whether each of the square's people is in it right now.
static func present(id: String) -> bool:
	match id:
		"wren":
			return (Game.flag("c3_done") and Game.flag("wren_joined")) or Game.flag("ch1_done")
		"liora":
			return Game.flag("c5_done")
		"aldric", "hale", "gate_warden":
			if not Game.flag("c6_done"):
				return false
			if id == "aldric":
				return true
			var opened := String(Game.flag("gate_choice", "")) == "all"
			return opened if id == "gate_warden" else not opened
	return true


# ================================================================ the place ===

static func build(root: Node3D) -> void:
	var v := SolSet.new()
	v.name = "Solhaven"
	root.add_child(v)
	root.set_meta("solhaven_set", v)
	(root as World).music = MUSIC.duplicate()
	# Chapter 1's side stories, from their own file; nothing happens without it
	var s := side()
	if s != null and s.has_method("setup") and not (root as World).attract:
		s.setup(root)


static func set_of(w: Node) -> Node3D:
	return w.get_meta("solhaven_set") as Node3D


## The first frame: black, before the gate film.
static func intro_frame(w: World) -> void:
	w.cine = true
	Cine.overlay(w).black(true)


static func intro(_w: World) -> void:
	pass


## A film to pick up, or the very first arrival: start on black.
static func starts_black() -> bool:
	return not Game.flag("arrived_solhaven") or String(Game.flag("sol_film", "")) != ""


static func arrival() -> Array:
	return [{"scene": "arrive"}]


## Back in Solhaven (a saved game, or after the arrival film): a film it was
## closed in the middle of carries on; otherwise the square, as the story
## has left it.
static func resume(w: World) -> void:
	var f := String(Game.flag("sol_film", ""))
	if f != "":
		people(w)   # (nobody in the square who isn't there yet)
		await Films.run(w, f)
	if not w.is_inside_tree():
		return
	await hub(w)


## The Sun Square as the story has left it: who's there, the music, the
## light over the next door, the triggers.
static func hub(w: World) -> void:
	var v := set_of(w)
	v.set_scene("day")
	v.wagon_to("wagon")
	v.light_wagon_lamp(Game.flag("c2_done"))
	if Game.flag("c1_done"):
		# (open only if you had Hale open it to everyone)
		v.open_gate(String(Game.flag("gate_choice", "")) == "all", 0.01)
	v.write_board()
	# Tamsin's crier: once a day, while there's an advert to be had
	Game.flags["crier_offer"] = String(Game.flag("crier_day", "")) != Time.get_date_string_from_system() and Ads.can_offer_rewarded()
	people(w)
	# the side stories: whoever the story so far has brought into the square
	# (event "square", each time it's set up again after a film)
	var s := side()
	if s != null and s.has_method("event") and not w.attract:
		s.event(w, "square")
	Music.play(w.music, 1.5, true)
	_mark(w)
	if not w.has_node("SolhavenTriggers"):
		var t := Triggers.new()
		t.name = "SolhavenTriggers"
		t.world = w
		w.add_child(t)


## Puts the square's people where they stand, or out of it.
static func people(w: World) -> void:
	for n in w.npcs:
		var def: Dictionary = n.def
		var id := String(def.get("id", ""))
		var body: Node3D = n.body
		if not _mine(id) or def.has("side_home"):
			continue   # the side stories' people, or one of ours they've sent somewhere
		var here := present(id)
		body.global_position = def.pos if here else Vector3(1000, -100, 1000)
		body.visible = here
		if id == "board":
			# the board answers when you walk up to it; nobody stands there
			var d = n.doll
			if d is PaperDoll and not (d is Figure3D):
				(d as PaperDoll)._sprite.visible = false
				(d as PaperDoll)._shadow.visible = false
		if id == "maren" and here:
			var f = n.doll
			if f is Figure3D:
				(f as Figure3D).sit(0.6)
		if here:
			var f = n.doll
			if f != null and id != "board":
				f.look_toward(w.player.global_position if w.player != null else def.pos + Vector3(0, 0, 3), w.cam)
	w._refresh_markers()


static func _mine(id: String) -> bool:
	return id in ["bram", "tamsin", "pip", "maren", "board", "wren", "liora", "aldric", "hale", "gate_warden"]


## The light over where the story goes next.
static func _mark(w: World) -> void:
	var v := set_of(w)
	if not Game.flag("c2_done") or Game.flag("ch1_done"):
		v.mark("")
	elif not Game.flag("c3_done"):
		v.mark("")   # Wren finds you on the way
	elif not Game.flag("c5_done"):
		v.mark("temple_door")
	elif not Game.flag("c6_done"):
		v.mark("spire_door")
	else:
		v.mark("wagon")


static func scene(name: String, w: World) -> void:
	match name:
		"arrive":
			people(w)   # (nobody in the square who isn't there yet)
			await Films.run(w, "gate")
		"deck":
			await _deck(w)
		"crier":
			await _crier(w)
		"pip_grey_coat":
			await _grey_coat(w)
		"night":
			# Bram ends the day after the Trial: Gold in the Dark
			await Films.run(w, "vault")
			if w.is_inside_tree():
				await hub(w)
		_:
			if name.begins_with("side:"):
				await side_event(w, name.substr(5))


## A man in a grey coat crosses the far side of the square. Pip watches him go.
static func _grey_coat(w: World) -> void:
	w.hud.dialogue.close()
	var pip = w._npc_by_id("pip")
	if pip == null:
		return
	var b := Node3D.new()
	b.name = "Extra_grey_coat"
	w.add_child(b)
	b.global_position = Vector3(-13.0, 0, -12.0)
	var d := Figure3D.make("trader", "pell")
	b.add_child(d)
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	ex["grey_coat"] = {"body": b, "doll": d}   # (Mr Pell; the side stories have their own)
	w.set_meta("extras", ex)
	Cine.path(w, "grey_coat", [Vector3(-4.0, 0, -14.5), Vector3(8.0, 0, -13.0), Vector3(15.0, 0, -9.0)], 1.6)
	for i in 60:
		if not is_instance_valid(b):
			break
		pip.doll.look_toward(b.global_position, w.cam)
		await w.get_tree().create_timer(0.1).timeout
	# (off, and freed once his walk's tween has run out)
	Films._drop(w, "grey_coat")
	if is_instance_valid(pip.body):
		pip.doll.look_toward(w.player.global_position, w.cam)


## "Change my deck": the deck screen opens, on the tailboard.
static func _deck(w: World) -> void:
	w.hud.dialogue.close()
	w.hud.open_menu("deck")
	while w.is_inside_tree() and w.hud.menu_open():
		await w.get_tree().process_frame


## Tamsin's crier, once a day: hear him out (an advert, when the adverts are
## in) and there's a cache in it: three cards, sealed and certified.
static func _crier(w: World) -> void:
	var today := Time.get_date_string_from_system()
	if String(Game.flag("crier_day", "")) == today:
		return
	if not Ads.can_offer_rewarded():
		return
	var pick: int = await w.hud.dialogue.choose(["Hear him out.", "Not today."])
	if pick != 0:
		return
	w.hud.dialogue.close()
	if not await Ads.rewarded("tamsin_crier"):
		return
	Game.set_flag("crier_day", today)
	Game.flags["crier_offer"] = false
	var cache := _cache_cards(3)
	for id in cache:
		Game.v2.collection[id] = int(Game.v2.collection.get(id, 0)) + 1
		if not Game.v2.codex.has(id):
			Game.v2.codex[id] = "seen"
	Game.save_game()
	await Cine.reveal(w, cache, "A SIGIL CACHE", "sealed and certified, from Tamsin's stall")


## Three cards a cache might hold: Sparks and Glimmers, Totems and Rites.
static func _cache_cards(n: int) -> Array:
	var pool := []
	for id in DuelCards.CARDS:
		var d: Dictionary = DuelCards.CARDS[id]
		if int(d.get("tier", 1)) <= 2 and d.kind != "summon" and not DuelCards.is_ascension(id) and String(d.get("element", "")) != "radiant":
			pool.append(id)
	var out := []
	for i in n:
		out.append(pool[randi() % pool.size()])
	return out


# =============================================================== dialogue ===
# The square's conversations (the dialogue box): v3 "C2 · Bram at the wagon",
# "Tamsin's card stall", "Pip at the fountain", "Old Maren, on the temple
# steps", "The notice board", "C3 · Wren at the wagon, afterwards", C5's
# "Liora (afterwards, on the temple steps)", C6's "Aldric (afterwards, in the
# square)" and "Warden Hale, afterwards". A dialogue box holds two sentences
# at most; a (beat) in the script is the break between two boxes.

static func _bram() -> Array:
	return [
		{"if": "c6_done", "then": [
			{"if": "!c7_done", "then": [
				{"say": "You beat their champion in front of the whole city. By nightfall half of Veyl will know your name.", "who": "bram"},
				{"say": "I liked it better when nobody did.", "who": "bram"},
				{"scene": "night"},
			], "else": _bram_menu()},
		], "else": [
			{"if": "!c3_done", "then": [
				{"if": "met_bram_square", "then": [
					{"say": "Sun Court's up the hill. It's the gold one.", "who": "bram"},
				]},
			], "else": [
				{"if": "!c4_done", "then": [
					{"say": "Sun Court's up the hill. It's the gold one.", "who": "bram"},
				]},
			]},
			{"set": "met_bram_square"},
		] + _bram_menu()},
	]


static func _bram_menu() -> Array:
	return [
		{"say": "What do you need?", "who": "bram"},
		# a menu: each thing asked comes off the list and the rest come back,
		# until "That's all." (Gary, 20 October)
		{"ask": ["Any advice?", "Rest and save", "Change my deck", "Tell me about the gods", "About Morne..."], "leave": "That's all.", "then": [
			[
				{"say": "Read the sign on a Totem's card before anything else. That's its element, and what it fears.", "who": "bram"},
				{"say": "Then read yourself. Some cards want a strong arm, some a cool head. Give a card what it wants and it'll wake for you properly.", "who": "bram"},
			],
			[
				{"save": true},
				{"say": "Get some sleep. I'll keep the lamp lit. (Game saved.)", "who": "bram"},
			],
			[
				{"say": "Tailboard's yours. Turnip's been told.", "who": "bram"},
				{"scene": "deck"},
			],
			[
				{"say": "Hundreds of them up there, and seven with a real claim on the Throne. Every one of them will want you in their colours before the year's out.", "who": "bram"},
				{"say": "Swear to one and you get a blessing for it, and a leash. Stay Unsworn and you get a bit of everything and nobody's hand on your collar.", "who": "bram"},
				{"say": "Your choice, when it comes. Don't let anyone hurry it. Least of all a god.", "who": "bram"},
			],
			[
				{"say": "Caldus Morne. Owns Ironvault, and the note on half of everything that isn't Ironvault.", "who": "bram"},
				{"say": "Men like that don't want a thing. They want it owed to them.", "who": "bram"},
				# (a thing to ask, or leave: an ask list, as Gary wants every
				# "what shall I ask" to be; the question's answer ends it)
				{"ask": ["How do you know him?"], "then": [
					[{"say": "I don't. I knew his father. Get some sleep.", "who": "bram"}],
				], "leave": "Leave it."},
			],
		]},
	]


static func _tamsin() -> Array:
	return [
		{"if": "c6_done", "then": [
			{"say": "The Unsworn, at my stall. Everything's dearer today, love. Fame has a price, and I've just set it.", "who": "tamsin"},
		], "else": [
			{"say": "Sigil caches! Fresh out of the Shardlands, sealed and certified! Sealed, anyway.", "who": "tamsin"},
			{"say": "Crowns for caches. Win duels, earn crowns, come back. That's the whole of it.", "who": "tamsin"},
			{"say": "Hrimmark caravan's a week late. Snow, at harvest. They say the boy-king's goddess has stopped minding the calendar.", "who": "tamsin"},
		]},
		{"if": "crier_offer", "then": [
			{"say": "There's a crier pays me to let him talk at my customers. Stand and hear him out, and there's a cache in it for you.", "who": "tamsin"},
			{"scene": "crier"},
		]},
	]


static func _pip() -> Array:
	return [
		{"if": "c6_done", "then": [
			{"say": "You beat him.", "who": "pip"},
			{"say": "He's still the best. You just beat him, that's all.", "who": "pip"},
		], "else": [
			{"say": "You're the Unsworn. Everyone says.", "who": "pip"},
			{"say": "Doesn't look like much.", "who": "pip"},
			{"say": "Ser Aldric's never lost a Trial. His Sentinel won't let anything past. You'd have to go round it.", "who": "pip"},
			{"say": "You can't go round it.", "who": "pip"},
			{"say": "I'm going to carry his shield one day. He doesn't know yet.", "who": "pip"},
			{"if": "!pip_errands_begun", "then": [
				{"scene": "pip_grey_coat"},
				{"say": "Got to go. Work.", "who": "pip"},
				{"set": "pip_errands_begun"},
				{"scene": "side:pips_errands"},
			]},
		]},
	]


static func _maren() -> Array:
	return [
		{"if": "c6_done", "then": [
			{"say": "The Sun's own knight, beaten in the Sun's own city. The priests will be smiling at you now. Count their teeth.", "who": "maren"},
		], "else": [
			{"say": "Sit, sit. You've the look of someone who's walked a long way to be lied to.", "who": "maren"},
			{"say": "Two thousand years of sun on these stones. Not one bad harvest in Solhaven. Lovely weather.", "who": "maren"},
			{"say": "I was a scribe in that Temple thirty years. I copied the Great Sundial's reading every noon.", "who": "maren"},
			{"say": "Every single noon.", "who": "maren"},
			{"say": "Then I found the old books. The readings from the last Turning.", "who": "maren"},
			{"say": "The shadows are nine days wrong.", "who": "maren"},
			{"ask": ["Wrong how?", "Why tell me?"], "then": [   # both can be asked
				[
					{"say": "Somebody slowed the sun, child. Nine days of it. Long enough for the right Champion to catch up.", "who": "maren"},
					{"say": "They threw me out for asking which one.", "who": "maren"},
				],
				[
					{"say": "Because you're the first person in two thousand years the priests can't tell to hush. They'll try, mind.", "who": "maren"},
				],
			]},
			{"say": "Go and look at the Sundial at dawn. The oldest stone, under the steps. Then come and tell me I'm mad.", "who": "maren"},
			{"if": "!sundial_scar_begun", "then": [
				{"set": "sundial_scar_begun"},
				{"scene": "side:sundial_scar"},
			]},
		]},
	]


static func _board() -> Array:
	return [
		{"say": "The Seat roll, in gold leaf: seven kingdoms, and the Champion who holds each."},
		{"say": "Underneath, in fresh black ink: {name}, the Unsworn, challenger. Someone has scratched a small coin beside it, crossed with a key."},
	]


static func _wren() -> Array:
	return [
		{"if": "c7_done", "then": [
			{"say": "Half the city's seen your face now. Mind your pocket.", "who": "wren"},
		], "else": [
			{"say": "You check that pocket every time someone passes. Stop it. It tells people where to look.", "who": "wren"},
			{"if": "c6_done", "then": [
				{"say": "Half the city's seen your face now. Mind your pocket.", "who": "wren"},
			], "else": [
				{"say": "One for free, and I don't do free. Aldric's deck has a Legend in it: Sunlance Seraph.", "who": "wren"},
				{"say": "And he keeps something bigger back for when he's losing. Everyone in Solhaven knows its name.", "who": "wren"},
				{"say": "Nobody's seen it, because nobody's ever had him losing.", "who": "wren"},
			]},
		]},
	]


static func _liora() -> Array:
	return [
		{"say": "I haven't told anyone about the mirrors. I've been praying about it.", "who": "liora"},
		{"say": "She doesn't answer me either.", "who": "liora"},
	]


static func _aldric() -> Array:
	return [
		{"say": "Go carefully. The Hierarch won't forgive this as easily as I do.", "who": "aldric"},
	]


static func _hale() -> Array:
	return [
		{"if": "gate_children", "then": [
			{"say": "Half a day's pay docked for every child. Cheapest thing I've bought in years.", "who": "hale"},
		], "else": [
			{"say": "{name}. The people outside the walls.", "who": "hale"},
			{"say": "If you ever have the ear of somebody who matters, remember them. I can't.", "who": "hale"},
		]},
	]


static func _gate_warden() -> Array:
	return [
		{"say": "Hale? Stripped of his command this morning, Hierarch's orders.", "who": "gate_warden"},
		{"say": "He's in the barracks yard, if you want him.", "who": "gate_warden"},
		{"if": "!hales_orders_begun", "then": [
			{"set": "hales_orders_begun"},
			{"scene": "side:hales_orders"},
		]},
	]


# =============================================================== triggers ===

## Where walking takes the story on: north past the fountain the crowd
## thickens (C3, Wren); the temple's doors (C4, then C5); the Sunspire's
## door (C6). Only while the player is free to walk.
class Triggers:
	extends Node
	var world: World
	var _cool := 0.0

	func _process(delta: float) -> void:
		_cool = maxf(0.0, _cool - delta)
		if world == null or world.busy or world.cine or world.hud == null or world.hud.menu_open() or _cool > 0.0:
			return
		var p := world.player.global_position
		var film := ""
		if Game.flag("c2_done") and not Game.flag("c3_done") and p.z < -6.5:
			film = "thief"
		elif Game.flag("c3_done") and not Game.flag("c5_done") and Vector2(p.x, p.z).distance_to(Vector2(0, -18.0)) < 2.6:
			film = "court" if not Game.flag("c4_done") else "trial"
		elif Game.flag("c5_done") and not Game.flag("c6_done") and Vector2(p.x, p.z).distance_to(Vector2(-15.0, -9.0)) < 2.8:
			film = "spire"
		if film == "":
			return
		_cool = 2.0
		_play(film)

	func _play(film: String) -> void:
		var area: Script = world.area
		await area.Films.run(world, film)
		if world != null and world.is_inside_tree():
			await area.hub(world)
