extends RefCounted
## Chapter 1's films (Master Script v3, Chapter 1 tab; a copy of the lines is
## in docs/script/v3_chapter1.md), staged in Solhaven's own 3D with Cine:
##
##   gate    C1 · The Golden Gate: the refugees, Warden Hale, his duel, the gate
##   wagon   C2 · The wagon: the horse-trader, Turnip, the Crooked Lantern lit
##   thief   C3 · Thief in the Market: Wren, the chase, the alley duel
##   court   C4 · The Sun Court: the Hierarch, the Herald, Solmaris stops time
##   trial   C5 · The Trial of Light: Liora and the Hall of Mirrors
##   spire   C6 · The Golden Knight: Ser Aldric on the Sunspire
##   vault   C7 · Gold in the Dark: the wagon at night, and Morne's vault
##
## run() plays a part and the ones that follow it without a break (the gate,
## then the wagon), saving which part it's in (flag sol_film) so a closed game
## carries on there; a duel it was in goes straight back to the duel.
##
## Voices, played with their lines once Gary records them (assets/audio/vo/,
## .ogg, .wav or .mp3): herald_14 to herald_16, solmaris_01 to _09 and
## morne_01 to _08. Until then each line is a subtitle.

const SolSet := preload("res://scripts/world/solhaven/solhaven_set.gd")
const Duels := preload("res://scripts/world/solhaven/duels.gd")
const Chase := preload("res://scripts/world/solhaven/chase.gd")

const PARTS := ["gate", "wagon", "thief", "court", "trial", "spire", "vault"]
## The square's music between scenes (Gary's solhaven_town when it's in).
const TOWN := ["solhaven_town", "solhaven_dawn"]
## The parts that run straight on into the next.
const NEXT := {"gate": "wagon"}


static func run(w: World, part: String) -> void:
	var p := part
	while p != "" and w.is_inside_tree():
		Game.set_flag("sol_film", p)
		Game.save_game()
		match p:
			"gate":
				await _gate(w)
			"wagon":
				await _wagon(w)
			"thief":
				await _thief(w)
			"court":
				await _court(w)
			"trial":
				await _trial(w)
			"spire":
				await _spire(w)
			"vault":
				await _vault(w)
		if not w.is_inside_tree():
			return
		Game.set_flag("c%d_done" % (PARTS.find(p) + 1))
		p = String(NEXT.get(p, ""))
	Game.set_flag("sol_film", "")
	Game.save_game()


# ================================================================ helpers ===

static func _v(w: World) -> Node3D:
	return w.get_meta("solhaven_set") as Node3D


## Someone who isn't one of the square's people (a refugee, a guard, Krell),
## played by characters/<model>.glb when it's in (else the cut-out for `look`).
static func _extra(w: World, id: String, look: String, pos: Vector3, name := "", model := "") -> Node3D:
	_drop(w, id)
	var b := Node3D.new()
	b.name = "Extra_" + id
	w.add_child(b)
	b.global_position = pos
	var d := Figure3D.make(look, model if model != "" else id)
	b.add_child(d)
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	ex[id] = {"body": b, "doll": d}
	w.set_meta("extras", ex)
	# (the films' own, so _clear() leaves the side stories' people be)
	var mine: Array = w.get_meta("film_extras", []) if w.has_meta("film_extras") else []
	if not mine.has(id):
		mine.append(id)
		w.set_meta("film_extras", mine)
	if name != "":
		Cine.call_by(w, id, name)
	return b


## Takes someone a film brought on out of it: gone from sight at once, and
## freed a little later, once any walk they were on (a tween holding them)
## is over.
static func _drop(w: World, id: String) -> void:
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	if not ex.has(id):
		return
	var b: Node3D = ex[id].body
	ex.erase(id)
	if is_instance_valid(b):
		b.visible = false
		b.set_meta("cine_path", -1)
		b.global_position = Vector3(2000, -200, 2000)
		w.get_tree().create_timer(40.0).timeout.connect(b.queue_free)


## Everyone a film brought on, sent off again (only the films' own: the
## side stories' people about the square stay).
static func _clear(w: World) -> void:
	var mine: Array = w.get_meta("film_extras", []) if w.has_meta("film_extras") else []
	for id in mine:
		_drop(w, String(id))
	w.set_meta("film_extras", [])
	for n in ["PaleHerald", "Dawnmane", "Coin", "Seal", "CardFlight"]:
		var x := w.get_node_or_null(n)
		if x != null:
			x.queue_free()


## A voiced line: its recording (assets/audio/vo/<file>) plays with it when
## it's there, and the subtitle stays up as long as it speaks. A line of more
## than two sentences comes as `parts`, shown one after another over the one
## recording.
static func _voice(w: World, file: String, who: String, parts: Array) -> void:
	var length := -1.0
	var ap: AudioStreamPlayer = null
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://assets/audio/vo/%s.%s" % [file, ext]
		if ResourceLoader.exists(path):
			ap = AudioStreamPlayer.new()
			ap.stream = load(path)
			w.add_child(ap)
			ap.play()
			ap.finished.connect(ap.queue_free)
			length = ap.stream.get_length()
			break
	var total := 0
	for p in parts:
		total += String(p).length()
	for p in parts:
		var hold := -1.0
		if length > 0.0:
			hold = length * float(String(p).length()) / float(maxi(1, total)) + (0.45 if p == parts[-1] else 0.1)
		await Cine.say(w, who, String(p), hold)


## A line of dialogue (Cine.say) that holds more than two sentences, shown as
## the script breaks it: one box after another.
static func _say(w: World, who: String, parts) -> void:
	if parts is String:
		await Cine.say(w, who, parts)
		return
	for p in parts:
		await Cine.say(w, who, String(p))


static func _narrate(w: World, text: String) -> void:
	await Cine.say(w, "", text)


## Is someone still a cut-out (no 3D model of them in yet)?
static func _doll(w: World, who: String) -> bool:
	var f = Cine.fig(w, who)
	return f != null and not (f is Figure3D)


## A three-quarter shot of someone's face as they look toward a point. (A
## cut-out's big painted head is framed a little wider and lower, so its face
## isn't the whole screen and the subtitle falls on its coat.)
static func _front(w: World, who: String, toward: Vector3, fov := 32.0, height := 1.5, side := 1.0) -> void:
	var b := Cine.body(w, who)
	if b == null:
		return
	var p: Vector3 = b.global_position
	var f := toward - p
	f.y = 0.0
	if f.length() < 0.01:
		f = Vector3(0, 0, 1)
	f = f.normalized()
	var s := f.cross(Vector3.UP) * side
	if _doll(w, who):
		Cine.shot(w, p + f * 3.4 - s * 1.7 + Vector3(0, height - 0.1, 0), p + Vector3(0, 1.22, 0), fov)
		return
	Cine.shot(w, p + f * 2.6 - s * 1.4 + Vector3(0, height, 0), Cine.head(w, who) - Vector3(0, 0.05, 0), fov)


## Over `from`'s shoulder onto `to`'s face; when `from` is a cut-out (a
## painted card always turned to the camera, which would fill the frame from
## that close), a clean shot of `to` looking at them instead.
static func _ots(w: World, from: String, to: String, side := 1.0, fov := 30.0) -> void:
	if _doll(w, from):
		_front(w, to, Cine.body(w, from).global_position, fov, 1.5, side)
		return
	Cine.over_shoulder(w, from, to, side, fov)


## The player raises the marked hand; the white mark glows.
static func _raise_mark(w: World) -> Node3D:
	var glow := Node3D.new()
	var s := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	s.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.92, 0.96, 1.0)
	m.emission_enabled = true
	m.emission = Color(0.85, 0.92, 1.0)
	m.emission_energy_multiplier = 6.0
	s.material_override = m
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.add_child(s)
	var l := OmniLight3D.new()
	l.light_color = Color(0.85, 0.92, 1.0)
	l.light_energy = 0.0
	l.omni_range = 3.0
	glow.add_child(l)
	var f = Cine.fig(w, "player")
	if f is Figure3D:
		(f as Figure3D).hand_light(glow)
		glow.position = Vector3(0.0, 0.05, 0.03)
		(f as Figure3D).pose("wave", 0.32, 0.4)
	else:
		w.player.add_child(glow)
		glow.position = Vector3(0.3, 1.7, 0.2)
	w.create_tween().tween_property(l, "light_energy", 2.2, 0.6)
	return glow


static func _lower_mark(w: World) -> void:
	var f = Cine.fig(w, "player")
	if f is Figure3D:
		(f as Figure3D).hand_light(null)
		(f as Figure3D).release(0.4)
	else:
		for c in w.player.get_children():
			if c is Node3D and c.get_child_count() == 2 and c.get_child(1) is OmniLight3D:
				c.queue_free()


## A main-story duel: straight back into it if the game was closed during it
## (flag `on`), lost ones played again (the duel screen's story loss), and
## won before it returns.
static func _duel(w: World, spec_fn: Callable, on: String) -> void:
	Game.set_flag(on)
	Game.save_game()
	var won := false
	while not won and w.is_inside_tree():
		won = await w._duel(spec_fn.call())
	Game.set_flag(on, false)


## Turns a figure to stone of light (the court when Solmaris stops time), or back.
static func _statue(w: World, who: String, on: bool) -> void:
	var f = Cine.fig(w, who)
	if f == null:
		return
	if f is Figure3D:
		var fig := f as Figure3D
		for mi: MeshInstance3D in fig.find_children("*", "MeshInstance3D", true, false):
			mi.material_overlay = _light_stone() if on else null
		if fig.anim != null:
			fig.anim.speed_scale = 0.0 if on else 1.0
	elif f is PaperDoll:
		var d := f as PaperDoll
		d._sprite.modulate = Color(2.4, 2.2, 1.7) if on else Color.WHITE
		d.set_process(not on)


static var _stone: StandardMaterial3D


static func _light_stone() -> StandardMaterial3D:
	if _stone == null:
		_stone = StandardMaterial3D.new()
		_stone.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_stone.albedo_color = Color(1.0, 0.95, 0.78, 0.82)
		_stone.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_stone.emission_enabled = true
		_stone.emission = Color(1.0, 0.9, 0.6)
		_stone.emission_energy_multiplier = 1.6
	return _stone


static func _sfx(w: World, sound: String, pitch := 1.0) -> void:
	var s: Sfx
	if w.has_meta("film_sfx") and is_instance_valid(w.get_meta("film_sfx")):
		s = w.get_meta("film_sfx")
	else:
		s = Sfx.new()
		w.add_child(s)
		w.set_meta("film_sfx", s)
	s.play(sound, pitch)


## A v2 card into the collection (and the Codex), shown big.
static func _give_card(w: World, id: String, title: String, sub: String) -> void:
	var v: Dictionary = Game.v2
	v.collection[id] = int(v.collection.get(id, 0)) + 1
	v.bonded[id] = true
	v.codex[id] = "champion" if int(DuelCards.CARDS[id].get("tier", 1)) >= 4 else "seen"
	Game.save_game()
	await Cine.reveal(w, [id], title, sub)


# ============================================================== C1 · the gate ===

## The refugees on the road, by the verge: [id, look, model, where, name].
const REFUGEES := [
	["gate_ysa", "refugee", "ysa", Vector3(-4.3, 0, 30.6), "Refugee"],
	["gate_tobin", "child_b", "tobin", Vector3(-4.0, 0, 30.9), ""],
	["refugee_b", "farmer", "refugee_b", Vector3(4.8, 0, 31.4), "Refugee"],
	["refugee", "refugee", "refugee", Vector3(5.6, 0, 33.6), "Refugee"],
	["refugee_c", "child_c", "refugee_c", Vector3(-5.8, 0, 33.4), ""],
	["ref_1", "farmer", "refugee_b", Vector3(-5.2, 0, 37.0), ""],
	["ref_2", "refugee", "refugee", Vector3(6.4, 0, 38.6), ""],
	["ref_3", "child", "tobin", Vector3(-6.4, 0, 40.6), ""],
	["ref_4", "farmer", "refugee_b", Vector3(5.4, 0, 43.6), ""],
	["ref_5", "refugee", "refugee", Vector3(-5.6, 0, 46.0), ""],
	["ref_6", "child_b", "refugee_c", Vector3(6.6, 0, 48.0), ""],
	["ref_7", "farmer", "refugee_b", Vector3(-6.0, 0, 52.0), ""],
]
## Hale and the line of guards in front of the shut gate.
const HALE_AT := Vector3(0.0, 0, 27.6)
const GUARDS := [Vector3(-2.4, 0, 27.0), Vector3(2.4, 0, 27.0), Vector3(-4.0, 0, 26.6), Vector3(4.0, 0, 26.6)]
## Where Bram and the player stop, facing the gate; the Circle on the road.
const STOP_P := Vector3(-0.7, 0, 32.0)
const STOP_B := Vector3(0.9, 0, 32.6)


static func _gate_people(w: World) -> void:
	for r in REFUGEES:
		_extra(w, String(r[0]), String(r[1]), r[3], String(r[4]), String(r[2]))
	# the woman with a sleeping boy across her lap, on a sack; the girl asleep on the sacks
	var ysa = Cine.fig(w, "gate_ysa")
	if ysa is Figure3D:
		(ysa as Figure3D).sit(0.45)
	var tob = Cine.fig(w, "gate_tobin")
	if tob is Figure3D:
		(tob as Figure3D).lie_down(0.01, true)
	else:
		Cine.body(w, "gate_tobin").position.y = -0.6
	var girl = Cine.fig(w, "refugee_c")
	if girl is Figure3D:
		(girl as Figure3D).lie_down(0.01, true)
	else:
		Cine.body(w, "refugee_c").position.y = -0.6
	for id in ["ref_3", "ref_6"]:
		var f = Cine.fig(w, id)
		if f is Figure3D:
			(f as Figure3D).lie_down(0.01, true)
		else:
			Cine.body(w, id).position.y = -0.6
	for id in ["gate_ysa", "refugee_b", "refugee", "ref_1", "ref_2", "ref_4", "ref_5", "ref_7"]:
		Cine.look(w, id, Vector3(0, 0, 33))
	_extra(w, "hale_gate", "guard", HALE_AT, "Hale", "hale")
	Cine.look(w, "hale_gate", Vector3(0, 0, 40))
	for i in GUARDS.size():
		_extra(w, "guard_%d" % i, "guard", GUARDS[i], "", "sun_guard")
		Cine.look(w, "guard_%d" % i, Vector3(GUARDS[i].x, 0, 40))


## C1: the road to the shut gate, Hale, his duel, and the gate.
static func _gate(w: World) -> void:
	var v := _v(w)
	v.set_scene("day")
	v.open_gate(false, 0.01)
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	_gate_people(w)
	if Game.flag("gate_duel_on"):
		Cine.place(w, "player", STOP_P, HALE_AT)
		Cine.place(w, "bram", STOP_B, HALE_AT)
	else:
		await _gate_meeting(w)
	await _duel(w, Callable(Duels, "hale_spec"), "gate_duel_on")
	Game.set_flag("beat_hale")
	await _gate_after(w)
	_clear(w)


static func _gate_meeting(w: World) -> void:
	Cine.place(w, "player", Vector3(-0.7, 0, 60.0), Vector3(0, 0, 0))
	Cine.place(w, "bram", Vector3(0.9, 0, 60.6), Vector3(0, 0, 0))
	Music.play(["solhaven_dawn", "menu_theme"], 2.0, true)
	# Solhaven revealed: white walls, gold domes, the Sunspire's mirror throwing the sun
	Cine.shot(w, Vector3(10.0, 3.0, 78.0), Vector3(-10.0, 16.0, -20.0), 42.0)
	Cine.fade(w, 0.0, 2.4)
	await Cine.drift(w, Vector3(10.0, 3.0, 78.0), Vector3(4.0, 7.5, 70.0), Vector3(-10.0, 16.0, -20.0), Vector3(-22.0, 30.0, -26.0), 4.0, 40.0)
	# the road to the gate is crowded with refugees
	Cine.walk(w, "bram", STOP_B + Vector3(0, 0, 6.0), 1.25)
	Cine.walk(w, "player", STOP_P + Vector3(0, 0, 6.0), 1.25)
	Cine.shot(w, Vector3(-3.5, 1.7, 47.0), Vector3(0.0, 1.0, 36.0), 40.0)
	await _narrate(w, "Three days after the fire, you reach Solhaven with the smoke still in your clothes. So does everyone else on the road.")
	# a woman with a sleeping boy across her lap
	Cine.walk(w, "bram", STOP_B, 1.2)
	Cine.walk(w, "player", STOP_P, 1.2)
	var ysa := Cine.body(w, "gate_ysa").global_position
	Cine.shot(w, ysa + Vector3(2.4, 1.3, 1.6), ysa + Vector3(0, 0.8, 0), 34.0)
	Cine.look(w, "gate_ysa", Vector3(-0.7, 0, 36.0))
	await Cine.say(w, "gate_ysa", "Three days we've waited. They let the pilgrims through. Not us.")
	Cine.look(w, "refugee_b", w.player.global_position)
	_front(w, "refugee_b", w.player.global_position, 30.0)
	await Cine.say(w, "refugee_b", "We pray to the Rootmother where we're from. Seems that's the wrong god this year.")
	# the gate is shut; in front of it, Warden Hale in white and gold, and a line of guards
	Cine.look(w, "player", HALE_AT)
	Cine.look(w, "bram", HALE_AT)
	Cine.shot(w, Vector3(1.8, 1.6, 36.4), Vector3(0, 3.0, 25.0), 44.0)
	await Cine.wait(w, 1.4)
	Cine.look(w, "hale_gate", w.player.global_position)
	_front(w, "hale_gate", w.player.global_position, 30.0)
	await Cine.say(w, "hale_gate", "Gate's closed. During the Turning, by the Hierarch's order, Solhaven admits sun-marked pilgrims and nobody else.")
	_ots(w, "player", "bram", -1.0, 30.0)
	Cine.look(w, "bram", w.player.global_position)
	await Cine.say(w, "bram", "We're not pilgrims. Show him, Sprout.")
	Cine.look(w, "player", HALE_AT)
	Cine.look(w, "bram", HALE_AT)
	var mark := _raise_mark(w)
	Cine.shot(w, w.player.global_position + Vector3(1.6, 1.5, 1.4), w.player.global_position + Vector3(0.1, 1.45, -0.3), 30.0)
	await _narrate(w, "You raise your hand. The white mark glows.")
	# he looks closer
	Cine.shot(w, w.player.global_position + Vector3(-1.4, 1.7, 1.8), HALE_AT + Vector3(0, 1.4, 0), 32.0)
	await Cine.walk(w, "hale_gate", HALE_AT + Vector3(0, 0, 2.6), 1.0)
	_front(w, "hale_gate", w.player.global_position, 28.0)
	await Cine.say(w, "hale_gate", "They sell those in the Shardlands. Paint and a pinch of Spark-dust. Crown a dozen.")
	_lower_mark(w)
	if is_instance_valid(mark):
		mark.queue_free()
	_ots(w, "hale_gate", "bram", 1.0, 30.0)
	await Cine.say(w, "bram", "A Pale Herald called this one by name. In front of a whole village.")
	_front(w, "hale_gate", w.player.global_position, 28.0)
	await Cine.say(w, "hale_gate", "Then it won't mind being tested.")
	var k := await Cine.choose(w, ["Test me, then.", "Why the pilgrims and not them?"])
	if k == 0:
		await Cine.say(w, "hale_gate", "Circle's there.")
	else:
		await Cine.say(w, "hale_gate", "Because a god's as strong as the people praying to her, and this is the year she needs every one.")
		await Cine.wait(w, 0.6)
		await Cine.say(w, "hale_gate", "That's the Hierarch's arithmetic. Not mine. Circle's there.")
	# the Circle on the road
	Cine.look(w, "hale_gate", Vector3(0, 0, 31.0))
	Cine.shot(w, Vector3(5.6, 4.0, 37.0), Vector3(0, 0.4, 30.4), 40.0)
	Cine.walk(w, "hale_gate", HALE_AT + Vector3(0, 0, 1.0), 1.0)
	await Cine.wait(w, 1.0)
	await Cine.fade(w, 1.0, 0.5)


static func _gate_after(w: World) -> void:
	var v := _v(w)
	Cine.place(w, "player", STOP_P, HALE_AT)
	Cine.place(w, "bram", STOP_B, HALE_AT)
	Cine.place(w, "hale_gate", HALE_AT + Vector3(0, 0, 1.6), w.player.global_position)
	_front(w, "hale_gate", w.player.global_position, 28.0)
	await Cine.fade(w, 0.0, 0.6)
	# he lowers his cards
	var hf = Cine.fig(w, "hale_gate")
	if hf is Figure3D:
		(hf as Figure3D).pose("play_card", 0.15, 0.5)
	await Cine.wait(w, 0.8)
	await Cine.say(w, "hale_gate", "Not paint.")
	if hf is Figure3D:
		(hf as Figure3D).release(0.4)
	await Cine.say(w, "hale_gate", "The gate's open to you, and whoever's with you.")
	Cine.shot(w, w.player.global_position + Vector3(-1.6, 1.7, 2.4), HALE_AT + Vector3(0, 1.3, 0), 36.0)
	var k := await Cine.choose(w, ["Open it for all of them.", "Let the children in, at least.", "Thank you, Warden."])
	match k:
		0:
			Game.set_flag("gate_choice", "all")
			Game.set_flag("gate", "all")
			Game.set_flag("let_refugees_in")
			_front(w, "hale_gate", w.player.global_position, 28.0)
			await Cine.say(w, "hale_gate", "The Hierarch's orders are —", 1.6)
			Cine.shot(w, HALE_AT + Vector3(-1.2, 1.6, 0.2), w.player.global_position + Vector3(0, 1.5, 0), 30.0)
			await _narrate(w, "You hold his eye. He's just opened his gate for a mark on your hand.")
			await _narrate(w, "Behind you are people whose homes burned the same night yours did.")
			# a long breath; then, to his guards
			_front(w, "hale_gate", w.player.global_position, 30.0)
			await Cine.wait(w, 1.2)
			Cine.look(w, "hale_gate", Vector3(0, 0, 25))
			await Cine.say(w, "hale_gate", "Open it. All the way.")
			Cine.shot(w, Vector3(6.0, 3.2, 38.0), Vector3(0, 3.0, 25.0), 44.0)
			for i in GUARDS.size():
				Cine.walk(w, "guard_%d" % i, GUARDS[i] + Vector3(-signf(GUARDS[i].x) * 0.0, 0, -1.6), 1.2)
			if Sfx.has_file("gate_open"):
				_sfx(w, "gate_open")
			await v.open_gate(true, 3.0)
			Cine.look(w, "hale_gate", w.player.global_position)
			_front(w, "hale_gate", w.player.global_position, 28.0)
			await Cine.say(w, "hale_gate", "Get them off the road before His Grace is up.")
			# the line pours through
			Cine.shot(w, Vector3(-7.0, 2.4, 22.0), Vector3(0, 1.2, 34.0), 44.0)
			var into := [Vector3(-1.5, 0, 14.0), Vector3(1.5, 0, 12.0), Vector3(-0.5, 0, 10.0), Vector3(1.0, 0, 8.0)]
			var walkers := ["refugee_b", "refugee", "ref_1", "ref_2", "ref_4", "ref_5", "ref_7"]
			for i in walkers.size():
				Cine.path(w, walkers[i], [Vector3(-1.0 + (i % 3) * 1.0, 0, 27.0), into[i % into.size()] + Vector3(0, 0, i * 0.7)], 1.3 + (i % 3) * 0.15)
			await Cine.wait(w, 2.6)
			# the woman with the sleeping boy stops in front of you
			var ysaf = Cine.fig(w, "gate_ysa")
			if ysaf is Figure3D:
				(ysaf as Figure3D).stand()
			_drop(w, "gate_tobin")
			await Cine.walk(w, "gate_ysa", w.player.global_position + Vector3(-0.9, 0, -1.3), 1.1)
			Cine.look(w, "gate_ysa", w.player.global_position)
			Cine.look(w, "player", Cine.body(w, "gate_ysa").global_position)
			_front(w, "gate_ysa", w.player.global_position, 30.0)
			await Cine.say(w, "gate_ysa", "What's your name?")
			# you tell her
			_ots(w, "gate_ysa", "player", 1.0, 30.0)
			var pf = Cine.fig(w, "player")
			if pf is Figure3D:
				(pf as Figure3D).talking = true
			await Cine.wait(w, 1.4)
			if pf is Figure3D:
				(pf as Figure3D).talking = false
			_front(w, "gate_ysa", w.player.global_position, 30.0)
			await Cine.say(w, "gate_ysa", "I'll teach it to the boy.")
			Cine.walk(w, "gate_ysa", Vector3(-1.0, 0, 12.0), 1.2)
		1:
			Game.set_flag("gate_choice", "children")
			Game.set_flag("gate", "children")
			Game.set_flag("gate_children")
			# he looks along the line, at the children asleep on the sacks
			Cine.look(w, "hale_gate", Cine.body(w, "refugee_c").global_position)
			Cine.shot(w, HALE_AT + Vector3(1.4, 1.7, 0.6), Vector3(-5.6, 0.4, 35.0), 34.0)
			await Cine.wait(w, 1.4)
			Cine.look(w, "hale_gate", w.player.global_position)
			_front(w, "hale_gate", w.player.global_position, 28.0)
			await Cine.say(w, "hale_gate", "Children, and one grown-up with each. That's my limit, and it's past the Hierarch's.")
			await v.open_gate(true, 2.4)
			# a third of the line goes through, the woman and her boy among them
			var ysaf = Cine.fig(w, "gate_ysa")
			if ysaf is Figure3D:
				(ysaf as Figure3D).stand()
			_drop(w, "gate_tobin")
			for id in ["refugee_c", "ref_3", "ref_6"]:
				var f = Cine.fig(w, id)
				if f is Figure3D:
					(f as Figure3D).get_up(0.5)
				else:
					Cine.body(w, id).position.y = 0.0
			Cine.shot(w, Vector3(-7.0, 2.4, 22.0), Vector3(0, 1.2, 34.0), 44.0)
			Cine.path(w, "gate_ysa", [Vector3(-0.6, 0, 27.0), Vector3(-1.2, 0, 13.0)], 1.2)
			Cine.path(w, "refugee_c", [Vector3(0.4, 0, 27.0), Vector3(-0.3, 0, 12.4)], 1.2)
			Cine.path(w, "ref_3", [Vector3(0.6, 0, 27.0), Vector3(0.8, 0, 11.5)], 1.3)
			Cine.path(w, "ref_2", [Vector3(1.2, 0, 27.0), Vector3(1.4, 0, 10.8)], 1.2)
			Cine.path(w, "ref_6", [Vector3(1.0, 0, 27.0), Vector3(1.8, 0, 12.0)], 1.25)
			await Cine.wait(w, 2.2)
			# the rest watch them go
			Cine.look(w, "refugee", Vector3(0, 0, 20))
			_front(w, "refugee", Vector3(0, 0, 20), 32.0)
			await Cine.say(w, "refugee", "That's my sister's girl. Go on, love. Go on.")
		_:
			Game.set_flag("gate_choice", "shut")
			Game.set_flag("gate", "shut")
			_front(w, "hale_gate", w.player.global_position, 28.0)
			await Cine.say(w, "hale_gate", "Don't thank me. Thank whatever chose you.")
			Cine.look(w, "hale_gate", Vector3(5.0, 0, 38.0))
			await Cine.wait(w, 0.8)
			Cine.look(w, "hale_gate", w.player.global_position)
			await Cine.say(w, "hale_gate", "I've my orders.")
			await v.open_gate(true, 2.0)
	# through the gate, into Solhaven
	Cine.shot(w, Vector3(3.0, 2.0, 18.0), Vector3(0, 1.3, 27.0), 42.0)
	Cine.walk(w, "bram", Vector3(0.9, 0, 21.0), 1.3)
	await Cine.walk(w, "player", Vector3(-0.7, 0, 21.4), 1.3)
	await Cine.fade(w, 1.0, 0.9)
	if String(Game.flag("gate_choice", "")) != "all":
		v.open_gate(false, 0.01)


# ============================================================== C2 · the wagon ===

static func _wagon(w: World) -> void:
	var v := _v(w)
	v.set_scene("day")
	v.wagon_to("wagon")
	v.light_wagon_lamp(false)
	if not Cine.overlay(w)._bars_on:
		await Cine.begin(w)
	Cine.overlay(w).black(true)
	var wg := SolSet.SPOTS.wagon as Vector3
	# the stable yard: Bram counts his last coins into a horse-trader's palm
	_extra(w, "horse_trader", "trader", wg + Vector3(-1.6, 0, 3.4), "Horse-trader")
	Cine.place(w, "bram", wg + Vector3(-2.4, 0, 2.8), wg + Vector3(-1.6, 0, 3.4))
	Cine.place(w, "player", wg + Vector3(-3.6, 0, 4.2), wg + Vector3(-1.6, 0, 3.4))
	Cine.look(w, "horse_trader", Cine.body(w, "bram").global_position)
	Music.play(TOWN, 2.0, true)
	Cine.shot(w, wg + Vector3(-7.0, 2.2, 7.0), wg + Vector3(0, 1.0, 0), 40.0)
	await Cine.fade(w, 0.0, 1.0)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).pose("play_card", 0.4, 0.4)
	Cine.shot(w, wg + Vector3(-1.9, 1.5, 5.0), wg + Vector3(-2.0, 1.1, 3.1), 30.0)
	for i in 4:
		_sfx(w, "coin" if Sfx.has_file("coin") else "click", 1.0 + i * 0.05)
		await Cine.wait(w, 0.45)
	if bf is Figure3D:
		(bf as Figure3D).release(0.4)
	_front(w, "horse_trader", Cine.body(w, "bram").global_position, 32.0)
	await Cine.say(w, "horse_trader", "Wagon, lamp hook, one mule. Mule's called Turnip. He bites.")
	_ots(w, "horse_trader", "bram", 1.0, 30.0)
	await Cine.say(w, "bram", "Hard?")
	_front(w, "horse_trader", Cine.body(w, "bram").global_position, 32.0)
	await Cine.say(w, "horse_trader", "Not hard.")
	Cine.walk(w, "horse_trader", wg + Vector3(-8.0, 0, 10.0), 1.3)
	# Bram hangs a lamp on the hook and lights it
	await Cine.walk(w, "bram", wg + Vector3(1.4, 0, 2.6), 1.2)
	Cine.look(w, "bram", wg + Vector3(0.9, 2.2, 1.6))
	Cine.shot(w, wg + Vector3(2.8, 1.8, 4.6), wg + Vector3(0.9, 2.0, 1.7), 32.0)
	if bf is Figure3D:
		(bf as Figure3D).pose("lift", 0.45, 0.4)
	await Cine.wait(w, 0.9)
	v.light_wagon_lamp(true)
	_sfx(w, "ward_set", 1.4)
	await Cine.wait(w, 0.8)
	if bf is Figure3D:
		(bf as Figure3D).release(0.4)
	Cine.look(w, "bram", w.player.global_position)
	Cine.shot(w, wg + Vector3(-1.2, 1.7, 4.8), Cine.head(w, "bram"), 32.0)
	await Cine.say(w, "bram", "The Crooked Lantern.")
	_ots(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "That's the last of my money. We sleep here, we eat here, and you sort your cards on the tailboard.")
	# Turnip bites your sleeve
	await Cine.walk(w, "player", wg + Vector3(0.9, 0, -3.6), 1.4)
	var mule: Vector3 = v.turnip.global_position
	Cine.look(w, "player", mule + Vector3(0, 1.2, 0))
	# from the side: you and the mule, nose to sleeve
	var mid := (mule + w.player.global_position) * 0.5
	Cine.shot(w, mid + Vector3(-3.6, 1.5, 1.2), mid + Vector3(0, 1.05, 0), 36.0)
	await Cine.wait(w, 0.4)
	v.turnip_bite()
	await _narrate(w, "Turnip bites your sleeve. Not hard.")
	_drop(w, "horse_trader")
	Game.set_flag("objective", "Present your mark at the Sun Court. (The gold building up the hill.)")
	w.hud.set_objective("Present your mark at the Sun Court. (The gold building up the hill.)")
	Cine.place(w, "player", wg + Vector3(-2.4, 0, 2.8), Vector3(0, 0, -10))
	await Cine.end(w)


# ======================================================= C3 · the thief ===

static func _thief(w: World) -> void:
	var v := _v(w)
	v.set_scene("day")
	await Cine.begin(w)
	if Game.flag("alley_duel_on"):
		await _alley(w, true)
		return
	# on the way to the Sun Court the crowd thickens
	var p := w.player.global_position
	var crowd := []
	var looks := ["courtier", "merchant", "refugee", "farmer", "child_b", "courtier", "trader", "elder", "courtier", "merchant"]
	for i in looks.size():
		var a := TAU * i / looks.size() + 0.4
		var at := p + Vector3(cos(a) * (2.0 + (i % 3) * 0.9), 0, sin(a) * (2.2 + (i % 2) * 1.1) - 1.5)
		var id := "crowd_%d" % i
		_extra(w, id, looks[i], at, "", "courtier" if looks[i] == "courtier" else "")
		crowd.append(id)
	for i in crowd.size():
		var at: Vector3 = Cine.body(w, crowd[i]).global_position
		Cine.path(w, crowd[i], [at + Vector3(sin(i * 1.7) * 3.0, 0, -4.0 + (i % 3) * 3.0)], 0.7 + (i % 4) * 0.1)
	Cine.place(w, "bram", p + Vector3(1.2, 0, 0.8), p + Vector3(0, 0, -6))
	Cine.look(w, "player", p + Vector3(0, 0, -6))
	Cine.shot(w, p + Vector3(-3.0, 2.6, 4.4), p + Vector3(0, 1.2, -1.0), 40.0)
	# a girl in a patched leather jacket bumps into you
	_extra(w, "wren", "wren", p + Vector3(-3.0, 0, -2.6), "Wren", "wren")
	Cine.look(w, "wren", p)
	await Cine.walk(w, "wren", p + Vector3(-0.35, 0, -0.45), 3.4, "run")
	w.shake(0.1)
	_sfx(w, "click", 0.7)
	_front(w, "wren", p, 30.0)
	await Cine.say(w, "wren", "Sorry. Busy day.", 1.6)
	Cine.walk(w, "wren", Vector3(8.0, 0, -3.0), 3.2, "run")
	Cine.shot(w, p + Vector3(-1.6, 1.7, 2.2), Cine.head(w, "player"), 32.0)
	await _narrate(w, "She's gone. A beat. Your pocket is empty.")
	Cine.look(w, "bram", Vector3(8.0, 0, -3.0))
	_ots(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "Your pocket! Go! I'll come round!")
	for id in crowd:
		_drop(w, id)
	_drop(w, "wren")
	# the chase
	var ch := Chase.new()
	await ch.play(w)
	await _alley(w, false)


## The dead-end alley: the card burns Wren and flies home; the deal; the duel;
## and after it, the price on the card, the tag, and whether she comes.
static func _alley(w: World, resumed: bool) -> void:
	var v := _v(w)
	var end_at := SolSet.SPOTS.dead_end as Vector3
	var wren_at := end_at + Vector3(0, 0, -1.6)
	var me_at := end_at + Vector3(-0.3, 0, 3.2)
	var bram_at := end_at + Vector3(1.6, 0, 6.6)
	_extra(w, "wren", "wren", wren_at, "Wren", "wren")
	if resumed:
		Cine.place(w, "player", me_at, wren_at)
		Cine.place(w, "bram", bram_at, wren_at)
		Cine.look(w, "wren", me_at)
	else:
		Cine.place(w, "player", me_at, wren_at)
		Cine.place(w, "bram", Vector3(60.0, 0, 30.0))
		Cine.look(w, "wren", me_at)
		# Wren turns, grinning, and holds up the blank card
		var card := InnRooms.blank_card(null)
		card.name = "CardFlight"
		var wf = Cine.fig(w, "wren")
		if wf is Figure3D:
			(wf as Figure3D).hand_light(card)
			card.position = Vector3(0.0, 0.06, 0.04)
			(wf as Figure3D).pose("play_card", 0.42, 0.4)
		else:
			Cine.body(w, "wren").add_child(card)
			card.position = Vector3(0.3, 1.5, 0.2)
		_front(w, "wren", me_at, 30.0)
		await Cine.fade(w, 0.0, 0.5)
		await Cine.say(w, "wren", "Right. Let's see what all the fuss is —", 1.8)
		# the card flares white; she yelps and drops it, and it flies back into your hand
		(card.material_override as StandardMaterial3D).emission_energy_multiplier = 8.0
		w.flash(Color(0.92, 0.96, 1.0), 0.08, 0.6)
		_sfx(w, "ward_spring", 1.2)
		await Cine.wait(w, 0.3)
		var from := card.global_position
		if wf is Figure3D:
			(wf as Figure3D).hand_light(null)
			(wf as Figure3D).release(0.2)
		else:
			card.queue_free()
		var fly := InnRooms.blank_card(null)
		fly.name = "CardFlight"
		w.add_child(fly)
		fly.global_position = from
		(fly.material_override as StandardMaterial3D).emission_energy_multiplier = 4.0
		Cine.shot(w, (from + me_at) * 0.5 + Vector3(2.4, 1.4, 0.0), (from + me_at) * 0.5 + Vector3(0, 1.2, 0), 40.0)
		var tw := w.create_tween()
		tw.tween_property(fly, "global_position", me_at + Vector3(0.25, 1.05, -0.3), 0.7).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(fly, "rotation", Vector3(0, TAU * 2.0, 0), 0.7)
		await _narrate(w, "The card flares white. Wren yelps and drops it, and it flies back through the air into your hand.")
		fly.queue_free()
		var held := InnRooms.blank_card(null)
		var pf = Cine.fig(w, "player")
		if pf is Figure3D:
			(pf as Figure3D).hand_light(held)
			held.position = Vector3(0.0, 0.06, 0.04)
		# shaking her hand: a red welt across the palm
		_front(w, "wren", me_at, 30.0)
		await Cine.say(w, "wren", "Nobody said it bites.")
		if pf is Figure3D:
			(pf as Figure3D).hand_light(null)
		Cine.shot(w, me_at + Vector3(-1.4, 1.7, 1.6), Cine.head(w, "wren"), 32.0)
		var k := await Cine.choose(w, ["That's mine.", "Who sent you?"])
		_front(w, "wren", me_at, 30.0)
		if k == 0:
			await Cine.say(w, "wren", "So I see.")
		else:
			await Cine.say(w, "wren", "Nobody sends me. I go where the money is, and you're carrying more of it than I've ever seen.")
		await Cine.say(w, "wren", "Here's a deal. Beat me, and I'll tell you what you're worth, and how many people know it.")
		await Cine.say(w, "wren", "Lose, and you buy me dinner.")
		# Bram comes round the end of the alley, out of breath, and stops where he can see your cards
		Cine.place(w, "bram", end_at + Vector3(0.8, 0, 13.0), me_at)
		Cine.shot(w, me_at + Vector3(-2.0, 1.8, -2.6), end_at + Vector3(1.0, 1.2, 9.0), 36.0)
		await Cine.walk(w, "bram", bram_at, 2.6, "run")
		Cine.look(w, "bram", me_at)
		await Cine.wait(w, 1.0)
		await Cine.fade(w, 1.0, 0.5)
	await _duel(w, Callable(Duels, "wren_spec"), "alley_duel_on")
	Game.set_flag("beat_wren")
	await _alley_after(w, me_at, wren_at, bram_at)
	_clear(w)


static func _alley_after(w: World, me_at: Vector3, wren_at: Vector3, bram_at: Vector3) -> void:
	Cine.place(w, "player", me_at, wren_at)
	Cine.place(w, "bram", bram_at, me_at)
	Cine.place(w, "wren", wren_at, me_at)
	_front(w, "wren", me_at, 30.0)
	await Cine.fade(w, 0.0, 0.6)
	await Cine.say(w, "wren", "All right. All right. A deal's a deal.")
	await Cine.say(w, "wren", "Ten thousand crowns. Posted this morning in every black market from here to the Shards, for a blank Sigil and the hand that holds it.")
	await Cine.say(w, "wren", "Sealed with this.")
	# she flicks you a wax seal
	var seal := MeshInstance3D.new()
	seal.name = "Seal"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.045
	cm.height = 0.012
	seal.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.55, 0.08, 0.06)
	sm.roughness = 0.4
	seal.material_override = sm
	w.add_child(seal)
	seal.global_position = Cine.head(w, "wren") + Vector3(0, -0.4, 0)
	Cine.shot(w, (seal.global_position + me_at) * 0.5 + Vector3(1.8, 0.6, 0), (seal.global_position + me_at) * 0.5 + Vector3(0, 1.0, 0), 34.0)
	var tw := w.create_tween()
	tw.tween_property(seal, "global_position", me_at + Vector3(0.25, 1.05, -0.25), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(seal, "rotation", Vector3(TAU * 3.0, 0, 0), 0.55)
	await _narrate(w, "She flicks you a wax seal: a coin crossed with a key. The same seal as the notes on Ashford's chapel door.")
	seal.queue_free()
	_ots(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "Ironvault.")
	_front(w, "wren", me_at, 30.0)
	await Cine.say(w, "wren", "Ironvault. And now everyone who can count to ten thousand is a hunter.")
	await Cine.say(w, "wren", "I've just told you, which my fence won't love.")
	await Cine.say(w, "wren", "He doesn't pay for failures. He collects on them.")
	# she tugs back her sleeve: a black-market marker on a cord, her name stamped in tin
	var wf = Cine.fig(w, "wren")
	if wf is Figure3D:
		(wf as Figure3D).pose("play_card", 0.3, 0.4)
	Cine.shot(w, wren_at + Vector3(1.0, 1.3, 1.4), wren_at + Vector3(0.2, 1.1, 0.3), 30.0)
	await Cine.wait(w, 1.4)
	if wf is Figure3D:
		(wf as Figure3D).release(0.4)
	_front(w, "wren", me_at, 30.0)
	await Cine.say(w, "wren", "So. You need someone who knows where hunters drink.")
	await Cine.say(w, "wren", "I need someone they're more interested in than me.")
	Cine.shot(w, me_at + Vector3(-1.4, 1.7, 1.6), Cine.head(w, "wren"), 32.0)
	var k := await Cine.choose(w, ["Prove it's real.", "Why should we trust a thief?"])
	if k == 0:
		# she tosses you the tag: real tin, a real stamp, a Shardlands fence's mark
		Game.set_flag("wren_tag")
		Cine.shot(w, me_at + Vector3(0.9, 1.4, 1.0), me_at + Vector3(0.2, 1.1, -0.2), 30.0)
		await Cine.wait(w, 1.2)
		_front(w, "wren", me_at, 30.0)
		await Cine.say(w, "wren", "Keep it if you like. I've another.")
	else:
		_front(w, "wren", me_at, 30.0)
		await Cine.say(w, "wren", "You shouldn't. That's what makes me useful.")
		await Cine.say(w, "wren", "I know exactly how people like me think.")
	# she pulls on a pair of fingerless gloves
	if wf is Figure3D:
		(wf as Figure3D).pose("play_card", 0.55, 0.4)
	await Cine.wait(w, 1.0)
	if wf is Figure3D:
		(wf as Figure3D).release(0.3)
	await Cine.say(w, "wren", "I'm Wren.")
	Cine.look(w, "bram", w.player.global_position)
	_ots(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "I don't like it.")
	await Cine.wait(w, 0.6)
	await Cine.say(w, "bram", "Your call, Sprout.")
	Cine.shot(w, me_at + Vector3(-1.4, 1.7, 1.6), Cine.head(w, "wren"), 32.0)
	var j := await Cine.choose(w, ["She comes with us.", "She doesn't."])
	_front(w, "wren", me_at, 30.0)
	if j == 0:
		Game.set_flag("wren_joined")
		await Cine.say(w, "wren", "Good. Board, and a tenth of whatever you win.")
		await Cine.say(w, "wren", "I'll keep the accounts.")
	else:
		Game.set_flag("wren_joined", false)
		Game.set_flag("wren_declined")
		await Cine.say(w, "wren", "Fair.")
		# she walks off up the alley without looking back
		Cine.shot(w, me_at + Vector3(-1.0, 1.6, 2.0), wren_at + Vector3(0, 1.0, 6.0), 38.0)
		await Cine.path(w, "wren", [wren_at + Vector3(1.6, 0, 3.0), wren_at + Vector3(1.6, 0, 14.0)], 1.5)
	await Cine.fade(w, 1.0, 0.8)
	_drop(w, "wren")
	# back to the square, by the market
	Cine.place(w, "player", Vector3(9.0, 0, 9.0), Vector3(0, 0, -10))
	Cine.place(w, "bram", Vector3(10.6, 0, -1.6))
	var obj := "Present your mark at the Sun Court. (The gold building up the hill.)"
	Game.set_flag("objective", obj)
	w.hud.set_objective(obj)
	w.cine_home(0.01)
	await Cine.fade(w, 0.0, 0.8)
	await Cine.end(w, false)


# ===================================================== C4 · the Sun Court ===

const COURTIERS := [
	Vector3(-3.4, 0, -6.0), Vector3(3.4, 0, -7.0), Vector3(-3.6, 0, -10.4), Vector3(3.5, 0, -11.6),
	Vector3(-3.3, 0, -15.0), Vector3(3.4, 0, -16.2), Vector3(-3.6, 0, -19.6), Vector3(3.3, 0, -20.8),
]


static func _court(w: World) -> void:
	var v := _v(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.6)
	v.set_scene("court")
	var c := SolSet.SPOTS.court as Vector3
	var throne := c + Vector3(0, 0.9, -30.0)
	# the Hierarch on his throne, Aldric at his side, the Herald by a pillar, Bram and Wren by the doors
	_extra(w, "hierarch", "hierarch", throne + Vector3(0, 0, 0.35), "Hierarch", "hierarch")
	var hf = Cine.fig(w, "hierarch")
	if hf is Figure3D:
		(hf as Figure3D).sit(0.62)
	Cine.look(w, "hierarch", c)
	_extra(w, "aldric_court", "aldric", throne + Vector3(1.9, 0, 0.9), "Aldric", "aldric")
	Cine.look(w, "aldric_court", c)
	var herald := PaleHerald.new()
	herald.name = "PaleHerald"
	w.add_child(herald)
	herald.global_position = c + Vector3(-6.4, 0, -21.0)
	herald.snap_dir(Vector3(1, 0, 0.4))
	Cine.call_by(w, "herald", "The Pale Herald")
	for i in COURTIERS.size():
		_extra(w, "courtier_%d" % i, "courtier", c + COURTIERS[i], "Courtier", "courtier")
		Cine.look(w, "courtier_%d" % i, c + Vector3(0, 0, COURTIERS[i].z))
	Cine.place(w, "bram", c + Vector3(1.9, 0, 0.0), c + Vector3(0, 0, -20))
	if Game.flag("wren_joined"):
		_extra(w, "wren", "wren", c + Vector3(-1.9, 0, 0.2), "Wren", "wren")
		Cine.look(w, "wren", c + Vector3(0, 0, -20))
	Cine.place(w, "player", c + Vector3(0, 0, -0.8), c + Vector3(0, 0, -30))
	Music.play(["sun_court", "solhaven_dawn"], 2.0, false)
	# a vast white hall under a sun-window; light in a single gold column on the throne
	Cine.shot(w, c + Vector3(0, 2.2, 1.2), throne + Vector3(0, 3.0, 0), 44.0)
	await Cine.fade(w, 0.0, 1.2)
	await Cine.drift(w, c + Vector3(0, 2.2, 1.2), c + Vector3(0, 3.6, -2.0), throne + Vector3(0, 3.0, 0), throne + Vector3(0, 6.0, 0), 3.0, 44.0)
	# the aisle; the courtiers whisper as you pass
	Cine.walk(w, "player", c + Vector3(0, 0, -8.5), 1.1)
	Cine.shot(w, c + Vector3(-2.6, 1.6, -11.0), c + Vector3(0, 1.3, -4.0), 38.0)
	Cine.look(w, "courtier_2", c + Vector3(0, 0, -6))
	Cine.look(w, "courtier_3", c + Vector3(0, 0, -6))
	await Cine.say(w, "courtier_2", "That's the Unsworn? From one of the Shardland villages, I heard.")
	await Cine.say(w, "courtier_3", "They pray to whatever falls on them, out there.")
	await Cine.walk(w, "player", c + Vector3(0, 0, -24.5), 1.2)
	Cine.look(w, "player", throne)
	_front(w, "hierarch", w.player.global_position, 30.0, 1.9)
	await Cine.say(w, "hierarch", "The Goddess welcomes every pilgrim, child. Even the ones she didn't send for.")
	await Cine.say(w, "hierarch", "You'll present your mark, as the law requires.")
	var mark := _raise_mark(w)
	Cine.shot(w, w.player.global_position + Vector3(1.6, 1.5, 1.4), w.player.global_position + Vector3(0.1, 1.45, -0.3), 30.0)
	await _narrate(w, "You raise your hand; the mark glows.")
	_lower_mark(w)
	if is_instance_valid(mark):
		mark.queue_free()
	_front(w, "hierarch", w.player.global_position, 30.0, 1.9)
	await Cine.say(w, "hierarch", "Thank you. And you'll give that card into the Goddess's keeping, as any loyal subject of the Throne would.")
	await Cine.say(w, "hierarch", "A blank Sigil in a farmhand's pocket is a danger to us all.")
	# the Herald
	herald.turn_hood(w.player.global_position + Vector3(0, 1.4, 0))
	Cine.shot(w, herald.global_position + Vector3(3.6, 1.6, 2.6), herald.hood_pos(), 34.0)
	await _voice(w, "herald_14", "herald", ["The Covenant forbids it."])
	Cine.shot(w, c + Vector3(3.0, 2.8, -14.0), throne + Vector3(0, 1.6, 0), 40.0)
	await _narrate(w, "The hall goes silent.")
	_front(w, "hierarch", w.player.global_position, 30.0, 1.9)
	await Cine.say(w, "hierarch", "Of course. I only meant to offer.")
	# Aldric steps forward
	await Cine.walk(w, "aldric_court", throne + Vector3(1.2, 0, 1.4), 1.0)
	Cine.look(w, "aldric_court", throne)
	_front(w, "aldric_court", throne, 30.0)
	await Cine.say(w, "aldric_court", "Then let the Unsworn be tested, honestly. No challenger enters the Turning without the Sun Court's Trial.")
	await Cine.say(w, "aldric_court", "I'll give it myself, before the whole city. Your Grace?")
	_front(w, "hierarch", Cine.body(w, "aldric_court").global_position, 30.0, 1.9)
	await Cine.wait(w, 1.0)
	await Cine.say(w, "hierarch", "As you wish, Ser Aldric. After the Trial of Light, as every pilgrim must.")
	await Cine.say(w, "hierarch", "If they pass it.")
	await _solmaris(w, throne)
	# the steps outside: Aldric catches you up, away from the courtiers
	await Cine.fade(w, 1.0, 0.8)
	_clear(w)
	v.set_scene("day")
	var steps := SolSet.SPOTS.temple_door as Vector3
	Cine.place(w, "player", steps + Vector3(-0.4, 0, 2.0), steps + Vector3(0, 0, 8))
	_extra(w, "aldric_court", "aldric", steps + Vector3(-1.6, 0, 0.2), "Aldric", "aldric")
	Cine.place(w, "bram", Vector3(10.6, 0, -1.6))
	Music.play(TOWN, 2.0, true)
	Cine.shot(w, steps + Vector3(3.2, 1.6, 5.4), steps + Vector3(-0.6, 1.3, 1.4), 34.0)
	await Cine.fade(w, 0.0, 0.8)
	await Cine.walk(w, "aldric_court", steps + Vector3(-1.2, 0, 2.6), 1.6)
	Cine.look(w, "aldric_court", w.player.global_position)
	Cine.look(w, "player", Cine.body(w, "aldric_court").global_position)
	_front(w, "aldric_court", w.player.global_position, 30.0)
	await Cine.say(w, "aldric_court", "The Goddess spoke to you. I saw your eyes change.")
	await Cine.say(w, "aldric_court", "She hasn't spoken to me in a month.")
	Cine.shot(w, steps + Vector3(2.4, 1.7, 6.0), steps + Vector3(-2.0, 1.2, 4.0), 38.0)
	Cine.path(w, "aldric_court", [steps + Vector3(-4.0, 0, 4.4), Vector3(-12.0, 0, -6.0)], 1.5)
	await _narrate(w, "He walks away before you can answer.")
	_clear(w)
	await Cine.end(w)


## The sun-window blazes white and sound stops: the court turns to statues of
## light, and only you can move. Above the throne, Solmaris leans down out of
## the glare, quiet, the way you'd speak at a sickbed.
static func _solmaris(w: World, throne: Vector3) -> void:
	var v := _v(w)
	var still := ["hierarch", "aldric_court", "bram", "wren"]
	for i in COURTIERS.size():
		still.append("courtier_%d" % i)
	Music.stop(0.3)
	Music.stinger("the_marking")
	w.flash(Color(1.0, 0.98, 0.9), 0.35, 1.2)
	await Cine.wait(w, 0.3)
	for id in still:
		_statue(w, id, true)
	var herald := w.get_node_or_null("PaleHerald")
	if herald != null:
		herald.process_mode = Node.PROCESS_MODE_DISABLED
	v.court_blaze(1.0, 1.0)
	Cine.shot(w, w.player.global_position + Vector3(1.4, 1.2, 2.6), w.player.global_position + Vector3(0, 1.5, -2.0), 38.0)
	Cine.look(w, "player", throne + Vector3(-3, 0, 2))
	await Cine.wait(w, 1.2)
	Cine.look(w, "player", throne + Vector3(3, 0, 2))
	await Cine.wait(w, 1.0)
	# something vast leans down out of the glare
	Cine.look(w, "player", throne)
	var pf = Cine.fig(w, "player")
	if pf is Figure3D:
		(pf as Figure3D).pose("look_up", 0.6, 0.8)
	Cine.shot(w, w.player.global_position + Vector3(-0.8, 0.9, 2.6), throne + Vector3(0, 10.0, 0), 50.0)
	await Cine.wait(w, 1.6)
	var face := throne + Vector3(0, 13.8, 2.0)
	Cine.shot(w, w.player.global_position + Vector3(0.6, 1.4, 1.2), face, 38.0)
	await _voice(w, "solmaris_01", "solmaris", ["Don't be frightened. Nobody else can hear us."])
	await _voice(w, "solmaris_02", "solmaris", ["I watched your village burn. Nobody there was praying to me, and I can't answer a prayer nobody says."])
	Cine.shot(w, throne + Vector3(4.0, 3.0, 6.0), face + Vector3(0, -3.0, 0), 46.0)
	await _voice(w, "solmaris_03", "solmaris", ["And what I want from you, I can't take.", "The Covenant lets me ask. Nothing more."])
	Cine.shot(w, w.player.global_position + Vector3(0.6, 1.4, 1.2), face, 36.0)
	await _voice(w, "solmaris_04", "solmaris", ["So I will offer. Give me that card, freely, and Ashford will stand again by the next new moon.", "Every roof. Every note paid.", "The mill turning."])
	await _voice(w, "solmaris_05", "solmaris", ["I can't give you back the miller. Morrowen keeps what she keeps.", "Everything else, I can."])
	if pf is Figure3D:
		(pf as Figure3D).release(0.6)
	Cine.shot(w, w.player.global_position + Vector3(-1.2, 1.9, 2.4), face + Vector3(0, -5.0, 0), 40.0)
	var k := await Cine.choose(w, ["No. Ashford didn't burn so I could sell it.", "Not yet.", "Tell me what it is first."])
	Cine.shot(w, throne + Vector3(-3.0, 2.0, 7.0), face + Vector3(0, -2.0, 0), 44.0)
	match k:
		0:
			Game.set_flag("solmaris_favour", "refused")
			await _voice(w, "solmaris_06", "solmaris", ["Nobody says yes the first time."])
		1:
			Game.set_flag("solmaris_favour", "not_yet")
			await _voice(w, "solmaris_07", "solmaris", ["Then keep my offer. It doesn't spoil."])
		_:
			Game.set_flag("solmaris_favour", "curious")
			await _voice(w, "solmaris_08", "solmaris", ["Something I have spent two thousand years making sure nobody found.", "And then it found you."])
	Cine.shot(w, w.player.global_position + Vector3(0.6, 1.4, 1.2), face, 36.0)
	await _voice(w, "solmaris_09", "solmaris", ["I'll ask again, when you've seen what that card costs the people around you."])
	# the light folds away and time comes back
	await v.court_blaze(0.0, 1.0)
	for id in still:
		_statue(w, id, false)
	if herald != null:
		herald.process_mode = Node.PROCESS_MODE_INHERIT
	Cine.shot(w, w.player.global_position + Vector3(-2.0, 2.0, 4.0), throne + Vector3(0, 2.0, 0), 42.0)
	await _narrate(w, "The light folds away and time comes back. Nobody else seems to have seen a thing.")
	var obj := "Pass the Trial of Light in the Sun Temple."
	Game.set_flag("objective", obj)
	w.hud.set_objective(obj)


# ================================================ C5 · the Trial of Light ===

static func _trial(w: World) -> void:
	var v := _v(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.6)
	v.set_scene("mirrors")
	var m := SolSet.SPOTS.mirrors as Vector3
	var liora_at := m + Vector3(5.6, 0, -6.4)
	var me_at := m + Vector3(0, 0, 9.0)
	_extra(w, "liora_hall", "acolyte", liora_at, "Liora", "liora")
	Cine.place(w, "player", me_at, m)
	Music.play(["mirrors", "solhaven_dawn"], 2.0, false)
	if not Game.flag("trial_duel_on"):
		# a young acolyte in white, with a gold circlet, lighting the last of the candles
		var taper := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.008
		tm.bottom_radius = 0.008
		tm.height = 0.4
		taper.mesh = tm
		taper.material_override = LevelKit.mat("lamp_glow")
		var lf = Cine.fig(w, "liora_hall")
		if lf is Figure3D:
			(lf as Figure3D).hand_light(taper)
			taper.position = Vector3(0, 0.1, 0.05)
			(lf as Figure3D).pose("play_card", 0.4, 0.4)
		Cine.look(w, "liora_hall", m + Vector3(8.5, 0, -6.0))
		Cine.shot(w, me_at + Vector3(0, 2.2, 2.0), m + Vector3(0, 2.0, -4.0), 46.0)
		await Cine.fade(w, 0.0, 1.2)
		await Cine.drift(w, me_at + Vector3(0, 2.2, 2.0), me_at + Vector3(2.0, 2.4, -2.0), m + Vector3(0, 2.0, -4.0), liora_at + Vector3(0, 1.4, 0), 3.0, 44.0)
		await Cine.walk(w, "player", m + Vector3(1.0, 0, -1.6), 1.2)
		if lf is Figure3D:
			(lf as Figure3D).hand_light(null)
			(lf as Figure3D).release(0.4)
		# she keeps looking at the mirrors instead of at you
		Cine.look(w, "liora_hall", w.player.global_position)
		Cine.look(w, "player", liora_at)
		_front(w, "liora_hall", w.player.global_position, 30.0)
		await Cine.say(w, "liora_hall", "You're the Unsworn. I'm Liora.")
		Cine.look(w, "liora_hall", m + Vector3(-8.0, 0, -6.0))
		await Cine.say(w, "liora_hall", "I keep the Trial.")
		await Cine.say(w, "liora_hall", "I've kept it two years and never been nervous. I don't know why I am now.")
		Cine.look(w, "liora_hall", w.player.global_position)
		_front(w, "liora_hall", w.player.global_position, 30.0)
		await Cine.say(w, "liora_hall", "The mirrors set the board, and you must win within three turns.")
		Cine.shot(w, m + Vector3(-3.0, 2.6, 4.0), m + Vector3(6.0, 3.0, -7.0), 44.0)
		await Cine.say(w, "liora_hall", "If you get it wrong, they begin again. They're patient.")
		_front(w, "liora_hall", w.player.global_position, 30.0)
		await Cine.say(w, "liora_hall", "Your deck carries a Summon: a Demigod asleep in one card.")
		await Cine.say(w, "liora_hall", "The mirrors have put it in your hand. It costs everything you have.")
		var obj := "Win within three turns. (A fixed board and hand, built around your deck's Summon. A mistake resets the board.)"
		Game.set_flag("objective", obj)
		w.hud.set_objective(obj)
		Cine.shot(w, m + Vector3(0, 7.0, 6.0), m, 50.0)
		await Cine.caption(w, "The Trial of Light", obj, 3.2)
		await Cine.fade(w, 1.0, 0.5)
	await _duel(w, Callable(Duels, "trial_spec"), "trial_duel_on")
	Game.set_flag("trial_light_passed")
	# passed: every mirror still bright with what it showed
	Cine.place(w, "player", m + Vector3(1.0, 0, -1.6), liora_at)
	Cine.look(w, "liora_hall", w.player.global_position)
	v.mirrors_show(0.6, Color(1.0, 0.95, 0.8), 0.01)
	_front(w, "liora_hall", w.player.global_position, 30.0)
	await Cine.fade(w, 0.0, 0.8)
	v.mirrors_show(0.0, Color(1.0, 0.95, 0.8), 2.5)
	await Cine.say(w, "liora_hall", "You've passed. You may challenge the Sun's Champion.")
	# she gives you the Revival Candle
	var candle := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.035
	cm.height = 0.22
	candle.mesh = cm
	candle.material_override = LevelKit.mat("cloth_white")
	var lf2 = Cine.fig(w, "liora_hall")
	if lf2 is Figure3D:
		(lf2 as Figure3D).hand_light(candle)
		candle.position = Vector3(0, 0.08, 0.05)
		(lf2 as Figure3D).pose("play_card", 0.45, 0.4)
	Cine.two_shot(w, "player", "liora_hall", 3.4, 1.4, 1.0, 34.0)
	await Cine.say(w, "liora_hall", "Every pilgrim who passes is given one. It has carried more than one Totem back from the dark.")
	if lf2 is Figure3D:
		(lf2 as Figure3D).hand_light(null)
		(lf2 as Figure3D).release(0.4)
	w.hud.toast("Got: The Revival Candle")
	_front(w, "liora_hall", w.player.global_position, 30.0)
	await Cine.say(w, "liora_hall", "Can I tell you something? I'm not meant to.")
	await Cine.say(w, "liora_hall", "The mirrors showed you twice.")
	await _twice(w, m)
	_front(w, "liora_hall", w.player.global_position, 30.0)
	await Cine.say(w, "liora_hall", "They've never done that. Not in any book I've read, and I've read all of them.")
	Cine.shot(w, w.player.global_position + Vector3(-1.4, 1.7, 1.8), Cine.head(w, "liora_hall"), 32.0)
	var k := await Cine.choose(w, ["What does it mean?", "Don't tell anyone."])
	_front(w, "liora_hall", w.player.global_position, 30.0)
	if k == 0:
		await Cine.say(w, "liora_hall", "I don't know.")
		await Cine.wait(w, 0.7)
		await Cine.say(w, "liora_hall", "I don't want to.")
	else:
		await Cine.say(w, "liora_hall", "Nobody listens to acolytes. Tonight I'm glad of it.")
	var obj2 := "Climb the Sunspire and face Ser Aldric."
	Game.set_flag("objective", obj2)
	w.hud.set_objective(obj2)
	await Cine.fade(w, 1.0, 0.8)
	_clear(w)
	v.set_scene("day")
	var steps := SolSet.SPOTS.temple_door as Vector3
	Cine.place(w, "player", steps + Vector3(0, 0, 2.2), Vector3(0, 0, 10))
	Music.play(TOWN, 2.0, true)
	w.cine_home(0.01)
	await Cine.fade(w, 0.0, 0.8)
	await Cine.end(w, false)


## "Once as you are. And once all in white." Two mirrors, and the player in
## each: as they are, and all in white.
static func _twice(w: World, m: Vector3) -> void:
	var v := _v(w)
	var frames: Array = v.mirror_frames
	if frames.size() < 2:
		await Cine.say(w, "liora_hall", "Once as you are. And once all in white.")
		return
	var a: Node3D = frames[0]
	var b: Node3D = frames[1]
	var made := []
	for k in 2:
		var fr: Node3D = a if k == 0 else b
		var ghost := Figure3D.make("player", "player")
		var holder := Node3D.new()
		holder.name = "Reflection%d" % k
		w.add_child(holder)
		holder.add_child(ghost)
		holder.global_position = fr.global_position - fr.global_transform.basis.z * 0.5
		if ghost is Figure3D:
			(ghost as Figure3D).snap_face(fr.global_transform.basis.z)
		made.append(holder)
		if k == 1:
			_statue_node(ghost)
	var mid := (a.global_position + b.global_position) * 0.5
	Cine.shot(w, mid + (m - mid).normalized() * 5.0 + Vector3(0, 1.8, 0), mid + Vector3(0, 1.6, 0), 40.0)
	await Cine.say(w, "liora_hall", "Once as you are. And once all in white.")
	await Cine.wait(w, 0.8)
	for h in made:
		(h as Node3D).queue_free()


static func _statue_node(f) -> void:
	if f is Figure3D:
		for mi: MeshInstance3D in (f as Figure3D).find_children("*", "MeshInstance3D", true, false):
			mi.material_overlay = _light_stone()
	elif f is PaperDoll:
		(f as PaperDoll)._sprite.modulate = Color(2.4, 2.3, 2.0)


# ===================================================== C6 · the Sunspire ===

static func _spire(w: World) -> void:
	var v := _v(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.6)
	var top := (SolSet.SPOTS.spire as Vector3) + Vector3(0, SolSet.ROOF_Y + 0.5, 0)
	var me_at := top + Vector3(0, 0, 2.6)
	var ald_at := top + Vector3(0, 0, -2.6)
	_roof_people(w, top)
	if not Game.flag("spire_duel_on"):
		await _climb(w)
		v.set_scene("day")
		Cine.place(w, "player", top + Vector3(11.0, 0, 0.6), top)
		Cine.place(w, "bram", top + Vector3(11.4, 0, 2.0), top)
		Music.play(["arena_solhaven", "solhaven_dawn"], 2.0, true)
		# the roof: the great circle under the colossal mirror, the stands packed
		Cine.shot(w, top + Vector3(16.0, 7.0, 16.0), top + Vector3(0, 4.0, 0), 50.0)
		await Cine.fade(w, 0.0, 1.0)
		await Cine.drift(w, top + Vector3(16.0, 7.0, 16.0), top + Vector3(10.0, 12.0, 20.0), top + Vector3(0, 4.0, 0), top + Vector3(0, 9.0, 6.0), 3.0, 52.0)
		Cine.walk(w, "player", me_at, 1.3)
		Cine.walk(w, "bram", top + Vector3(5.8, 0, 3.6), 1.2)
		_crowd_cheer(w, true)
		Cine.shot(w, top + Vector3(-6.0, 3.0, 9.0), top + Vector3(4.0, 2.0, -6.0), 46.0)
		await Cine.say(w, "crowd", "ALDRIC! ALDRIC! ALDRIC!")
		# Ser Aldric walks into the circle and salutes the crowd, then you
		Cine.place(w, "aldric_roof", top + Vector3(-11.0, 0, -0.4), top)
		Cine.shot(w, top + Vector3(2.0, 1.8, 6.0), top + Vector3(-4.0, 1.6, -2.0), 40.0)
		await Cine.walk(w, "aldric_roof", ald_at, 1.4)
		Cine.look(w, "aldric_roof", top + Vector3(0, 0, -10))
		var af = Cine.fig(w, "aldric_roof")
		if af is Figure3D:
			await (af as Figure3D).act("wave")
		Cine.look(w, "aldric_roof", me_at)
		if af is Figure3D:
			await (af as Figure3D).act("wave")
		_crowd_cheer(w, false)
		Cine.look(w, "player", ald_at)
		_front(w, "aldric_roof", me_at, 30.0)
		await Cine.say(w, "aldric_roof", "They say the sky fell on your village, and men with torches came after it.")
		await Cine.say(w, "aldric_roof", "I'm sorry. Nobody in this city will say so to you, so I will.")
		await Cine.say(w, "aldric_roof", "Whatever you are, I'll fight you fairly. It's the only promise anyone can make in this circle.")
		Cine.shot(w, me_at + Vector3(-1.4, 1.7, 1.8), Cine.head(w, "aldric_roof"), 32.0)
		var k := await Cine.choose(w, ["And I'll fight you the same.", "Your goddess made me an offer."])
		_front(w, "aldric_roof", me_at, 30.0)
		if k == 0:
			await Cine.say(w, "aldric_roof", "Then she'll judge us both.")
		else:
			# very still
			await Cine.wait(w, 1.0)
			await Cine.say(w, "aldric_roof", "Then she's speaking to someone.")
			await Cine.wait(w, 0.7)
			await Cine.say(w, "aldric_roof", "I'm glad.")
		var herald := w.get_node_or_null("PaleHerald") as PaleHerald
		if herald != null:
			Cine.shot(w, herald.global_position + Vector3(3.0, 1.4, 3.0), herald.hood_pos(), 36.0)
		await _voice(w, "herald_15", "herald", ["The Sun Court's Trial, by the Covenant. If the Unsworn wins, they may challenge for any Seat in Veyl until the Turning closes.", "Begin."])
		await Cine.fade(w, 1.0, 0.5)
	else:
		v.set_scene("day")
	var spec_holder := [{}]
	var make_spec := func() -> Dictionary:
		spec_holder[0] = Duels.aldric_spec()
		return spec_holder[0]
	await _duel(w, make_spec, "spire_duel_on")
	Game.set_flag("beat_aldric")
	if String(Game.flag("gate_choice", "")) == "all":
		Game.set_flag("hale_stripped")   # the Hierarch's orders, for opening the gate
	await _spire_after(w, top, me_at, ald_at, bool((spec_holder[0] as Dictionary).get("_mirror_swung", false)))
	_clear(w)
	# back down in the square, the afternoon of the Trial
	await Cine.fade(w, 1.0, 0.8)
	_clear(w)
	var d := SolSet.SPOTS.spire_door as Vector3
	Cine.place(w, "player", d + Vector3(2.4, 0, 0), Vector3(0, 0, -2))
	Cine.place(w, "bram", Vector3(10.6, 0, -1.6))
	Game.set_flag("objective", "")
	w.hud.set_objective("")
	Music.play(TOWN, 2.0, true)
	w.cine_home(0.01)
	await Cine.fade(w, 0.0, 0.8)
	await Cine.end(w, false)


## The climb up the Sunspire's spiral stair, crowd noise growing.
static func _climb(w: World) -> void:
	var v := _v(w)
	v.set_scene("day")
	var s := SolSet.SPOTS.spire as Vector3
	var door := SolSet.SPOTS.spire_door as Vector3
	Cine.place(w, "player", door + Vector3(1.6, 0, 0.4), door)
	Cine.place(w, "bram", door + Vector3(2.4, 0, 1.2), door)
	Cine.shot(w, door + Vector3(7.0, 2.0, 3.0), door + Vector3(-1.0, 2.4, 0), 40.0)
	await Cine.fade(w, 0.0, 0.8)
	Cine.walk(w, "bram", door + Vector3(-1.2, 0, 0.6), 1.3)
	await Cine.walk(w, "player", door + Vector3(-1.4, 0, -0.2), 1.3)
	await Cine.fade(w, 1.0, 0.6)
	# up and round, the windows going by, the noise growing
	var stair := _stair(w)
	var steps := 3
	for i in steps:
		var a := TAU * i / 5.0 + 0.6
		var y := 6.0 + i * 11.0
		var r := 3.4
		var at := s + Vector3(cos(a) * r, y, sin(a) * r)
		Cine.place(w, "player", at, at + Vector3(-sin(a), 0, cos(a)) * 3.0)
		Cine.place(w, "bram", at + Vector3(-sin(a), 0, cos(a)) * -1.4 + Vector3(0, -0.4, 0), at)
		var cam := s + Vector3(cos(a + 0.9) * 1.6, y + 1.6, sin(a + 0.9) * 1.6)
		Cine.shot(w, cam, at + Vector3(0, 1.2, 0), 54.0)
		await Cine.fade(w, 0.0, 0.4)
		_sfx(w, "crowd_roar" if Sfx.has_file("crowd_roar") else "duel_start", 0.6 + i * 0.15)
		await Cine.wait(w, 1.4)
		await Cine.fade(w, 1.0, 0.4)
	stair.queue_free()


## The inside of the tower, for the climb: a dim shaft with a stair winding up
## its wall and the windows letting in bars of sun.
static func _stair(w: World) -> Node3D:
	var s := SolSet.SPOTS.spire as Vector3
	var n := Node3D.new()
	n.name = "SpireStair"
	w.add_child(n)
	var wall := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.4
	cm.bottom_radius = 4.4
	cm.height = 40.0
	cm.radial_segments = 32
	cm.flip_faces = true
	wall.mesh = cm
	wall.material_override = LevelKit.mat("marble")
	wall.position = s + Vector3(0, 20.0, 0)
	n.add_child(wall)
	for i in 120:
		var a := TAU * i / 24.0
		var y := 1.0 + i * 0.3
		var st := LevelKit.box(n, s + Vector3(cos(a) * 3.4, y, sin(a) * 3.4), Vector3(1.8, 0.2, 0.7), "sandstone", false)
		st.rotation.y = -a
	for i in 8:
		var a := TAU * i / 3.0 + 0.3
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.85, 0.6)
		l.light_energy = 2.0
		l.omni_range = 6.0
		n.add_child(l)
		l.global_position = s + Vector3(cos(a) * 3.8, 4.0 + i * 4.6, sin(a) * 3.8)
	return n


## The Sunspire's crowd: the people of Solhaven packed in the stands, the
## Hierarch in his shaded box, the Herald at the circle's edge, Pip on
## someone's shoulders, and, if the gate was opened, the refugees in the cheap
## seats at the very top.
static func _roof_people(w: World, top: Vector3) -> void:
	var v := _v(w)
	var spots: Array = v.roof_crowd_spots
	var looks := ["courtier", "merchant", "farmer", "courtier", "child_b", "elder", "trader", "courtier", "guard", "merchant"]
	for i in spots.size():
		var id := "crowd_%d" % i
		var look: String = looks[i % looks.size()]
		_extra(w, id, look, spots[i], "", "courtier" if look == "courtier" else ("sun_guard" if look == "guard" else ""))
		Cine.look(w, id, top)
	Cine.call_by(w, "crowd", "Crowd")
	var cheap: Array = v.cheap_seat_spots
	var opened := String(Game.flag("gate_choice", "")) == "all"
	var kids := String(Game.flag("gate_choice", "")) == "children"
	for i in cheap.size():
		var id := "cheap_%d" % i
		var look: String = "refugee" if opened else ("child_c" if kids and i % 4 == 0 else ["courtier", "merchant", "farmer"][i % 3])
		if kids and i % 4 != 0 and not opened:
			look = ["courtier", "merchant", "farmer"][i % 3]
		var model := ""
		if opened:
			model = ["ysa", "refugee_b", "refugee", "refugee_c"][i % 4]
		_extra(w, id, look, cheap[i], "", model)
		Cine.look(w, id, top)
	# the Hierarch in his shaded box, the Herald at the circle's edge
	_extra(w, "hierarch", "hierarch", top + Vector3(0, 1.2, -10.4), "Hierarch", "hierarch")
	var hf = Cine.fig(w, "hierarch")
	if hf is Figure3D:
		(hf as Figure3D).sit(0.5)
	Cine.look(w, "hierarch", top)
	var herald := PaleHerald.new()
	herald.name = "PaleHerald"
	w.add_child(herald)
	herald.global_position = top + Vector3(-5.4, 0, 4.4)
	herald.snap_dir(top - herald.global_position)
	Cine.call_by(w, "herald", "The Pale Herald")
	# Pip, on someone's shoulders
	var pip_at: Vector3 = spots[3] if spots.size() > 3 else top + Vector3(7, 1, 0)
	_extra(w, "pip_roof", "child", pip_at + Vector3(0, 0.95, 0), "Pip", "pip")
	Cine.look(w, "pip_roof", top)
	_extra(w, "aldric_roof", "aldric", top + Vector3(-11.0, 0, -0.4), "Aldric", "aldric")


static func _crowd_cheer(w: World, on: bool) -> void:
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	for id in ex.keys():
		if not (String(id).begins_with("crowd_") or String(id).begins_with("cheap_")):
			continue
		var f = ex[id].get("doll")
		if f is Figure3D:
			if on:
				(f as Figure3D).hold("cheer")
			else:
				(f as Figure3D).release(0.4)
		elif on:
			Cine.hop(w, String(id), 0.12)


static func _spire_after(w: World, top: Vector3, me_at: Vector3, ald_at: Vector3, swung: bool) -> void:
	var v := _v(w)
	Cine.place(w, "player", me_at, ald_at)
	Cine.place(w, "aldric_roof", ald_at, me_at)
	Cine.place(w, "bram", top + Vector3(5.8, 0, 3.6), me_at)
	if swung:
		v.swing_mirror(1.0, 0.01)
	Music.stop(0.4)
	# Aldric's last Totem falls, and the light it sheds pours into your hand.
	# Silence across the stands. Nobody moves.
	Cine.shot(w, me_at + Vector3(1.6, 1.4, 1.6), me_at + Vector3(0, 1.2, -0.6), 34.0)
	await Cine.fade(w, 0.0, 0.8)
	var light := _light_into_hand(w, ald_at + Vector3(0, 1.0, 0), me_at)
	await Cine.wait(w, 2.0)
	Cine.shot(w, top + Vector3(9.0, 4.0, 9.0), top + Vector3(0, 1.4, -3.0), 48.0)
	await Cine.wait(w, 1.6)
	var herald := w.get_node_or_null("PaleHerald") as PaleHerald
	if herald != null:
		herald.turn_hood(w.player.global_position + Vector3(0, 1.4, 0))
		Cine.shot(w, herald.global_position + Vector3(3.0, 1.4, 3.0), herald.hood_pos(), 36.0)
	await _voice(w, "herald_16", "herald", ["The Unsworn is tested and found worthy. Challenge whom you will."])
	# the light his fallen Totems shed cools into a card: a lion of your own
	Cine.shot(w, me_at + Vector3(1.0, 1.4, 1.2), me_at + Vector3(0.1, 1.2, -0.3), 30.0)
	await _narrate(w, "The light his fallen Totems shed gathers in your open hand and cools into a card: a lion of your own.")
	if is_instance_valid(light):
		light.queue_free()
	await _give_card(w, "sunmane_lion", "SUNMANE LION", "Relic · Radiant · lesser kin of Dawnmane")
	# watching it form
	_front(w, "aldric_roof", me_at, 30.0)
	await Cine.say(w, "aldric_roof", "My Lion's light, made yours. Treat it well.")
	# still silence; the Hierarch rises and leaves his box without a word
	var hb := Cine.body(w, "hierarch")
	var hf = Cine.fig(w, "hierarch")
	Cine.shot(w, top + Vector3(3.0, 2.6, -4.0), hb.global_position + Vector3(0, 1.4, 0), 36.0)
	await Cine.wait(w, 0.8)
	if hf is Figure3D:
		(hf as Figure3D).stand()
	await Cine.wait(w, 0.6)
	await Cine.walk(w, "hierarch", hb.global_position + Vector3(4.0, 0, -1.0), 1.0)
	_drop(w, "hierarch")
	match String(Game.flag("gate_choice", "")):
		"all":
			# from the cheap seats at the very top, one voice, then a dozen: the refugees
			var cheap: Array = v.cheap_seat_spots
			var ex: Dictionary = w.get_meta("extras", {})
			var first := "cheap_0"
			if cheap.size() > 0:
				Cine.shot(w, top + Vector3(0, 3.6, 2.0), cheap[0] + Vector3(0, 1.4, 0), 40.0)
			var f0 = ex.get(first, {}).get("doll")
			if f0 is Figure3D:
				(f0 as Figure3D).hold("cheer")
			Cine.call_by(w, "refugees", "Refugees")
			await Cine.say(w, "refugees", "{name}!", 1.4)
			for id in ex.keys():
				if String(id).begins_with("cheap_"):
					var f = ex[id].get("doll")
					if f is Figure3D:
						(f as Figure3D).hold("cheer")
					else:
						Cine.hop(w, String(id), 0.14)
			Cine.shot(w, top + Vector3(-4.0, 6.0, 8.0), top + Vector3(0, 3.0, -9.0), 50.0)
			await Cine.say(w, "refugees", "{name}! {name}!", 2.2)
			# nobody else joins them; nobody stops them
			await Cine.wait(w, 1.4)
		"children":
			# from high in the stands, children's voices, shouting your name until somebody hushes them
			var cheap2: Array = v.cheap_seat_spots
			if cheap2.size() > 0:
				Cine.shot(w, top + Vector3(0, 3.6, 2.0), cheap2[0] + Vector3(0, 1.4, 0), 40.0)
			Cine.call_by(w, "children", "Children")
			await Cine.say(w, "children", "{name}! {name}!", 1.8)
			await Cine.wait(w, 1.0)
		_:
			# a single coin spins down from the stands and rings on the stone at your feet
			var coin := MeshInstance3D.new()
			coin.name = "Coin"
			var cm := CylinderMesh.new()
			cm.top_radius = 0.035
			cm.bottom_radius = 0.035
			cm.height = 0.006
			coin.mesh = cm
			coin.material_override = LevelKit.mat("gold")
			w.add_child(coin)
			coin.global_position = top + Vector3(1.0, 5.0, 8.0)
			var to := me_at + Vector3(0.3, 0.05, 0.5)
			Cine.shot(w, to + Vector3(1.2, 0.5, 1.2), to, 34.0)
			var tw := w.create_tween()
			tw.tween_property(coin, "global_position", to, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(coin, "rotation", Vector3(TAU * 4.0, TAU, 0), 1.1)
			await tw.finished
			_sfx(w, "coin" if Sfx.has_file("coin") else "click", 1.6)
			var t2 := w.create_tween()
			t2.tween_property(coin, "rotation", Vector3(PI * 0.5, TAU * 3.0, 0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await t2.finished
			await Cine.wait(w, 1.0)
	# Pip, on someone's shoulders, crying, and furious about it
	var pf = Cine.fig(w, "pip_roof")
	Cine.shot(w, Cine.body(w, "pip_roof").global_position + Vector3(1.4, 0.6, 2.0), Cine.head(w, "pip_roof"), 32.0)
	if pf is Figure3D:
		(pf as Figure3D).pose("defeat", 0.4, 0.5)
	await Cine.wait(w, 2.2)
	_front(w, "aldric_roof", me_at, 30.0)
	await Cine.say(w, "aldric_roof", "Who taught you?")
	Cine.shot(w, me_at + Vector3(-1.4, 1.7, 1.8), Cine.head(w, "aldric_roof"), 32.0)
	var k := await Cine.choose(w, ["An innkeeper.", "Nobody, till last week."])
	_front(w, "aldric_roof", me_at, 30.0)
	if k == 0:
		Game.set_flag("told_aldric_innkeeper")
		await Cine.say(w, "aldric_roof", "Then I'd like to meet him.")
	else:
		var af = Cine.fig(w, "aldric_roof")
		if af is Figure3D:
			(af as Figure3D).pose("play_card", 0.2, 0.6)
		await Cine.wait(w, 0.8)
		await Cine.say(w, "aldric_roof", "Twenty years, I've trained.")
		if af is Figure3D:
			(af as Figure3D).release(0.4)
	# he looks up at the mirror
	var af2 = Cine.fig(w, "aldric_roof")
	if af2 is Figure3D:
		(af2 as Figure3D).pose("look_up", 0.6, 0.8)
	Cine.shot(w, ald_at + Vector3(-1.6, 0.9, -2.0), v.sun_mirror.global_position + Vector3(0, -8.0, 0), 44.0)
	await Cine.say(w, "aldric_roof", "She'll know of this before the sun sets.")
	_front(w, "aldric_roof", me_at, 30.0)
	await Cine.say(w, "aldric_roof", "Not from me. She'd have to ask.")
	if af2 is Figure3D:
		(af2 as Figure3D).release(0.5)
	v.swing_mirror(0.0, 3.0)


## The light a fallen Totem sheds, pouring into the player's open hand.
static func _light_into_hand(w: World, from: Vector3, to: Vector3) -> Node3D:
	var p := GPUParticles3D.new()
	p.amount = 60
	p.lifetime = 1.2
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	var d := (to + Vector3(0, 1.1, 0)) - from
	pm.direction = d.normalized()
	pm.spread = 12.0
	pm.initial_velocity_min = d.length() * 0.7
	pm.initial_velocity_max = d.length() * 0.95
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.9, 0.6)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.85, 0.5)
	m.emission_energy_multiplier = 5.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = m
	p.draw_pass_1 = q
	w.add_child(p)
	p.global_position = from
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.85, 0.5)
	l.light_energy = 1.6
	l.omni_range = 3.0
	p.add_child(l)
	l.global_position = to + Vector3(0, 1.1, 0)
	return p


# ===================================================== C7 · Gold in the Dark ===

static func _vault(w: World) -> void:
	var v := _v(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 1.2)
	# night: the wagon in a field outside Solhaven's walls; Turnip asleep
	v.set_scene("night")
	v.wagon_to("field")
	v.light_wagon_lamp(true)
	Music.play(["solhaven_night", "the_marking"], 2.0, false)
	var f := SolSet.SPOTS.field as Vector3
	var tail: Vector3 = v.wagon.to_global(Vector3(0, 0, 2.3))
	tail.y = 0.0
	Cine.place(w, "bram", tail + Vector3(0.0, 0, 0.35), tail + v.wagon.global_transform.basis.z * 3.0)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).sit(0.95)
	Cine.place(w, "player", Vector3(1000, 0, 1000))
	var wheel: Vector3 = v.wagon.to_global(Vector3(-1.9, 0, 0.6))
	wheel.y = 0.0
	_extra(w, "wren", "wren", wheel, "Wren", "wren")
	var wf = Cine.fig(w, "wren")
	if wf is Figure3D:
		(wf as Figure3D).lie_down(0.01, true)
	else:
		Cine.body(w, "wren").position.y = -0.7
	var turnip_was: float = v.turnip.rotation.z
	v.turnip.rotation.z = 0.0
	# the blank card, turned under the lamp
	var card := InnRooms.blank_card(null)
	if bf is Figure3D:
		(bf as Figure3D).hand_light(card)
		card.position = Vector3(0.0, 0.06, 0.04)
		(bf as Figure3D).pose("play_card", 0.4, 0.4)
	Cine.shot(w, f + Vector3(-9.0, 2.0, 9.0), v.wagon.global_position + Vector3(0, 1.2, 0), 40.0)
	await Cine.fade(w, 0.0, 1.6)
	if not Game.flag("wren_joined"):
		Cine.shot(w, wheel + Vector3(1.8, 0.7, 1.8), wheel + Vector3(0, 0.3, 0), 36.0)
		await _narrate(w, "That night, she's asleep under the wagon. Turnip hasn't bitten her.")
	Cine.shot(w, Cine.head(w, "bram") + Vector3(0.9, -0.1, 1.2), card.global_position, 30.0)
	await Cine.wait(w, 1.2)
	# the faint image comes back: a white eye inside a ring of runes
	var eye := _eye_on(card)
	await Cine.wait(w, 1.6)
	Cine.shot(w, Cine.head(w, "bram") + Vector3(1.0, 0.0, 1.0), Cine.head(w, "bram") + Vector3(0, -0.05, 0), 26.0)
	await Cine.say(w, "bram", "I burned every word about you. Every word.")
	if is_instance_valid(eye):
		eye.queue_free()
	if bf is Figure3D:
		(bf as Figure3D).hand_light(null)
		(bf as Figure3D).release(0.6)
	Cine.shot(w, f + Vector3(-5.0, 1.5, 5.0), v.wagon.global_position + Vector3(0, 1.0, 0), 38.0)
	await _narrate(w, "He puts the card in his coat and stares into the dark for a long time.")
	Cine.shot(w, wheel + Vector3(1.4, 0.5, 1.6), wheel + Vector3(0, 0.25, 0), 34.0)
	await _narrate(w, "In the shadow of the wagon wheel, Wren is awake.")
	await _narrate(w, "She heard. She says nothing.")
	await Cine.fade(w, 1.0, 1.2)
	v.turnip.rotation.z = turnip_was
	if bf is Figure3D:
		(bf as Figure3D).stand()
	_drop(w, "wren")
	await _morne(w)
	# End of Chapter One
	Game.set_flag("ch1_done")
	Game.set_flag("objective", "")
	w.hud.set_objective("")
	await Cine.caption(w, "End of Chapter One: The Sun's Court.", "", 3.6)
	_clear(w)
	v.set_scene("day")
	v.wagon_to("wagon")
	Cine.place(w, "player", Vector3(9.2, 0, 0.4), Vector3(0, 0, -6))
	Cine.place(w, "bram", Vector3(10.6, 0, -1.6))
	Music.play(TOWN, 2.0, true)
	w.cine_home(0.01)
	await Cine.fade(w, 0.0, 1.2)
	await Cine.end(w, false)


## The seal on the blank card, faint, as if seen through it.
static func _eye_on(card: Node3D) -> Node3D:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.056, 0.056)
	q.mesh = qm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _seal_texture()
	m.albedo_color = Color(1, 1, 1, 0.0)
	m.emission_enabled = true
	m.emission = Color(0.8, 0.88, 1.0)
	m.emission_energy_multiplier = 1.2
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	card.add_child(q)
	q.position = Vector3(0, 0, 0.0025)
	var tw := q.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.9, 1.4).set_trans(Tween.TRANS_SINE)
	return q


static var _seal_tex: Texture2D


static func _seal_texture() -> Texture2D:
	if _seal_tex != null:
		return _seal_tex
	var runes := ""
	for i in 12:
		var a := TAU * i / 12.0
		var x := 128.0 + cos(a) * 98.0
		var y := 128.0 + sin(a) * 98.0
		runes += "<path d='M%.1f %.1f l%.1f %.1f m%.1f %.1f l%.1f %.1f' stroke='#9fb2e8' stroke-width='5' stroke-linecap='round'/>" % [
			x - 6, y - 8, 12, 16, -12, 0 if i % 2 == 0 else 8, 8 if i % 2 == 0 else 12, 0 if i % 2 == 0 else -8]
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 256 256'>" + \
		"<circle cx='128' cy='128' r='112' fill='none' stroke='#9fb2e8' stroke-width='4'/>" + \
		"<circle cx='128' cy='128' r='84' fill='none' stroke='#9fb2e8' stroke-width='3'/>" + runes + \
		"<path d='M52 128 Q128 62 204 128 Q128 194 52 128 Z' fill='#ffffff' stroke='#c9d6ff' stroke-width='4'/>" + \
		"<circle cx='128' cy='128' r='26' fill='#b8c8ff'/><circle cx='128' cy='128' r='12' fill='#2c3460'/></svg>"
	var img := Image.new()
	if img.load_svg_from_string(svg, 1.0) != OK:
		img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
	img.generate_mipmaps()
	_seal_tex = ImageTexture.create_from_image(img)
	return _seal_tex


## Ironvault. For the first time, the face: Caldus Morne at his ledger desk,
## Huntmaster Krell standing before it.
static func _morne(w: World) -> void:
	var v := _v(w)
	v.set_scene("vault")
	v.old_ledger(false)
	v.ledger_label.text = ""
	var c := SolSet.SPOTS.vault as Vector3
	_extra(w, "morne", "morne", c + Vector3(0, 0, -0.9), "Morne", "morne")
	Cine.look(w, "morne", c + Vector3(0, 0, 4))
	_extra(w, "krell", "krell", c + Vector3(0.3, 0, 2.2), "Krell", "krell")
	Cine.look(w, "krell", c)
	Music.play(["morne", "ironvault"], 2.0, false)
	# the vault from the opening movie: racks of glowing cards climbing into the dark
	Cine.shot(w, c + Vector3(0, 1.2, 9.0), c + Vector3(0, 9.0, -12.0), 50.0)
	await Cine.fade(w, 0.0, 1.6)
	await Cine.drift(w, c + Vector3(0, 1.2, 9.0), c + Vector3(1.4, 1.8, 5.0), c + Vector3(0, 9.0, -12.0), c + Vector3(0, 1.3, -0.6), 4.0, 44.0)
	Cine.shot(w, c + Vector3(1.6, 1.5, 1.4), Cine.head(w, "morne"), 30.0)
	await Cine.wait(w, 1.2)
	_front(w, "krell", c, 32.0)
	await Cine.say(w, "krell", "The Unsworn beat the Sun's knight. On the Sunspire, in front of the whole city.")
	Cine.shot(w, c + Vector3(-1.2, 1.4, 1.6), Cine.head(w, "morne"), 28.0)
	await _voice(w, "morne_01", "morne", ["Good."])
	_front(w, "krell", c, 32.0)
	await Cine.say(w, "krell", "Sir?")
	Cine.shot(w, c + Vector3(-1.2, 1.4, 1.6), Cine.head(w, "morne"), 28.0)
	await _voice(w, "morne_02", "morne", ["Every Champion they beat is one we needn't. Let them do the work.", "What else?"])
	_front(w, "krell", c, 32.0)
	await Cine.say(w, "krell", "Ashford's closed. Nobody pointed.")
	await Cine.say(w, "krell", "We took the mill and the farms under the terms. The inn we burned.")
	Cine.shot(w, c + Vector3(-1.2, 1.4, 1.6), Cine.head(w, "morne"), 28.0)
	await _voice(w, "morne_03", "morne", ["And the miller?"])
	_front(w, "krell", c, 32.0)
	await Cine.say(w, "krell", "He lied to me.")
	# he makes a note
	Cine.shot(w, c + Vector3(0.6, 1.6, 0.8), c + Vector3(0.4, 1.0, 0.1), 30.0)
	v.ledger_label.text = "Hayes, T. · the mill · marked paid"
	await Cine.wait(w, 0.8)
	Cine.shot(w, c + Vector3(-1.2, 1.4, 1.6), Cine.head(w, "morne"), 28.0)
	await _voice(w, "morne_04", "morne", ["Give his widow back the mill, with the note marked paid. Profit from a death looks like exactly what it is."])
	_front(w, "krell", c, 32.0)
	await Cine.say(w, "krell", "There's an old man travelling with the Unsworn. Sixty or more.")
	await Cine.say(w, "krell", "Calls himself Bram.")
	await Cine.say(w, "krell", "His was the only roof in Ashford we never held paper on. He paid for it in gold, twenty years back.")
	# Morne's pen stops
	Cine.shot(w, c + Vector3(0.5, 1.4, 0.7), c + Vector3(0.3, 1.05, 0.1), 26.0)
	await Cine.wait(w, 1.4)
	Cine.shot(w, c + Vector3(-1.0, 1.4, 1.4), Cine.head(w, "morne"), 26.0)
	await _voice(w, "morne_05", "morne", ["Holloway."])
	_front(w, "krell", c, 32.0)
	await Cine.say(w, "krell", "You know him, sir?")
	Cine.shot(w, c + Vector3(-1.2, 1.4, 1.6), Cine.head(w, "morne"), 28.0)
	await _voice(w, "morne_06", "morne", ["He has an account with us."])
	# he takes down an old ledger, thirty years of dust on it, and opens it beside today's
	await Cine.walk(w, "morne", c + Vector3(-3.2, 0, -2.0), 1.0)
	Cine.shot(w, c + Vector3(-1.0, 1.8, 2.4), c + Vector3(-3.6, 1.8, -2.6), 34.0)
	await Cine.wait(w, 1.0)
	await Cine.walk(w, "morne", c + Vector3(0, 0, -0.9), 1.0)
	Cine.look(w, "morne", c + Vector3(0, 0, 4))
	v.old_ledger(true)
	v.ledger_label.text = "HOLLOWAY, B. · 4,000 cr. · outstanding."
	Cine.shot(w, c + Vector3(0.95, 1.55, 0.55), c + Vector3(0.95, 1.05, 0.1), 24.0)
	await Cine.wait(w, 2.6)
	Cine.shot(w, c + Vector3(-1.2, 1.4, 1.6), Cine.head(w, "morne"), 28.0)
	await _voice(w, "morne_07", "morne", ["Take the price off the Unsworn. Let them win."])
	# he dips the pen
	Cine.shot(w, c + Vector3(0.5, 1.4, 0.7), c + Vector3(0.3, 1.05, 0.1), 26.0)
	await Cine.wait(w, 1.0)
	Cine.shot(w, c + Vector3(-1.0, 1.4, 1.4), Cine.head(w, "morne"), 26.0)
	await _voice(w, "morne_08", "morne", ["Put it on Holloway. Alive."])
	# he writes today's date beside the old line
	Cine.shot(w, c + Vector3(0.95, 1.55, 0.55), c + Vector3(0.95, 1.05, 0.1), 24.0)
	await Cine.wait(w, 0.6)
	v.ledger_label.text = "HOLLOWAY, B. · 4,000 cr. · outstanding.\nthe fourth day of the Turning"
	await Cine.wait(w, 2.4)
	await Cine.fade(w, 1.0, 1.4)
	_drop(w, "morne")
	_drop(w, "krell")
