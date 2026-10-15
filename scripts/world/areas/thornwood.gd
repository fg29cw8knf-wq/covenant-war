extends RefCounted
## The Thornwood: the end of the Prologue's film (Spoken Script P4's river
## and P5). The riverbank below burning Ashford, the road east, Bram's
## campfire, the narrow road where Hunter Dask is waiting, and at dawn the
## first sight of Solhaven. The place itself is ThornwoodSet.

const NAME := "The Thornwood"
const SUBTITLE := "The road east"
const BOUNDS := Rect2(-60.0, -20.0, 120.0, 120.0)
const CAMERA_X_LIMIT := 60.0
const CUSTOM_ENV := true
## The film begins the moment the place is entered, from black (intro_frame).
const INTRO := true
const RESUMES := true

const SPAWNS := {
	"river": Vector3(-3.0, 0, -3.6),
}
const ENV := {}


static func npcs() -> Array:
	var fb: Vector3 = ThornwoodSet.SPOTS.far_bank
	return [
		{"id": "bram", "look": "bram", "name": "Bram", "pos": ThornwoodSet.SPOTS.tunnel + Vector3(0.9, 0, -0.6), "talk": []},
		{"id": "corin", "look": "corin", "name": "Corin", "pos": fb + Vector3(-0.6, 0, 0.0), "talk": []},
		{"id": "tilly", "look": "child", "name": "Tilly", "pos": fb + Vector3(0.2, 0, 0.3), "talk": []},
		{"id": "hob", "look": "hob", "name": "Hob", "pos": fb + Vector3(1.8, 0, 0.8), "talk": []},
		{"id": "seamus", "look": "fiddler", "name": "Seamus", "pos": fb + Vector3(-2.2, 0, 1.4), "talk": []},
		{"id": "nell", "look": "elder", "name": "Old Nell", "pos": fb + Vector3(4.6, 0, -0.6), "talk": []},
	]


static func build(root: Node3D) -> void:
	var v := ThornwoodSet.new()
	v.name = "Thornwood"
	root.add_child(v)
	root.set_meta("village", v)
	(root as World).music = []


static func village(w: Node) -> ThornwoodSet:
	return w.get_meta("village") as ThornwoodSet


## The first frame: black, before anything is seen.
static func intro_frame(w: World) -> void:
	w.cine = true
	Cine.overlay(w).black(true)


static func intro(_w: World) -> void:
	pass


## Every visit to the Thornwood is the film, so it always starts on black.
static func starts_black() -> bool:
	return true


static func arrival() -> Array:
	return [{"scene": "film"}]


static func scene(name: String, w: World) -> void:
	if name == "film":
		await _film(w, "river")


static func resume(w: World) -> void:
	if Game.flag("thornwood_done"):
		w.story_next.emit("solhaven")
		return
	if not Game.flag("arrived_thornwood_film"):
		return
	await _film(w, String(Game.flag("thorn_part", "river")))


## The film from `part` to the end; each part saves, so a closed game
## carries on from where it was.
static func _film(w: World, part: String) -> void:
	Game.set_flag("arrived_thornwood_film")
	var parts := ["river", "camp", "road", "ridge"]
	var i0 := maxi(0, parts.find(part))
	for i in range(i0, parts.size()):
		Game.set_flag("thorn_part", parts[i])
		Game.save_game()
		match parts[i]:
			"river":
				await _river(w)
			"camp":
				await _camp(w)
			"road":
				await _road(w)
			"ridge":
				await _ridge(w)
	Game.set_flag("thornwood_done")
	Game.save_game()
	w.story_next.emit("solhaven")


static func _sfx(w: World, sound: String, pitch := 1.0) -> void:
	var s: Sfx
	if w.has_meta("film_sfx") and is_instance_valid(w.get_meta("film_sfx")):
		s = w.get_meta("film_sfx")
	else:
		s = Sfx.new()
		w.add_child(s)
		w.set_meta("film_sfx", s)
	s.play(sound, pitch)


## Sends everyone but the named away (out of sight) for a scene.
static func _only(w: World, keep: Array) -> void:
	for n in w.npcs:
		var b: Node3D = n.body
		var on: bool = n.def.id in keep
		n.doll.visible = on
		if not on:
			b.global_position = Vector3(0, -50, 0)


# ------------------------------------------------------------ the river ---

## Out of the tunnel onto the riverbank. Above, Ashford burns. On the far
## bank the village huddles, Corin holding Tilly's hand.
static func _river(w: World) -> void:
	var v := village(w)
	v.set_scene("river")
	v.burn_crest()
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	var t: Vector3 = ThornwoodSet.SPOTS.tunnel
	var fb: Vector3 = ThornwoodSet.SPOTS.far_bank
	var near: Vector3 = ThornwoodSet.SPOTS.near_bank
	var crest := ThornwoodSet.CREST + Vector3(0, v.height(ThornwoodSet.CREST.x, ThornwoodSet.CREST.z) + 4.0, 0)
	# everyone on their bank
	for n in w.npcs:
		n.doll.visible = true
	Cine.place(w, "bram", t + Vector3(0, 0, -1.6), near + Vector3(0, 0, 6))
	Cine.place(w, "player", t + Vector3(0, 0, -2.4), near + Vector3(0, 0, 6))
	for n in w.npcs:
		if n.def.id != "bram":
			Cine.place(w, String(n.def.id), n.def.pos, near)
	Cine.place(w, "nell", fb + Vector3(4.6, 0, -0.6), crest)
	Music.play(["river_farewell", "menu_theme"], 2.0, true)
	# from behind the villagers, across the water, up to the burning crest
	Cine.shot(w, fb + Vector3(-2.6, 3.4, 11.0), crest + Vector3(0, 1.0, 0), 42.0)
	await Cine.fade(w, 0.0, 2.0)
	await Cine.drift(w, fb + Vector3(-2.6, 3.4, 11.0), fb + Vector3(-2.0, 2.8, 9.0), crest + Vector3(0, 1.0, 0), near + Vector3(0, 1.5, 0), 4.0)
	Cine.walk(w, "bram", near + Vector3(0.6, 0, 0.2), 1.6)
	await Cine.walk(w, "player", near + Vector3(-0.8, 0, 0.4), 1.5)
	Cine.look(w, "bram", fb)
	Cine.look(w, "player", fb)
	# Corin shouts across the water
	Cine.shot(w, near + Vector3(-1.2, 1.7, -1.6), Cine.head(w, "corin"), 34.0)
	await Cine.say(w, "corin", "Go! I'll look after the green!")
	Cine.over_shoulder(w, "corin", "player", 1.0, 32.0)
	var a := await Cine.choose(w, ["Come with us!", "We'll come back!"])
	Cine.shot(w, near + Vector3(-1.2, 1.7, -1.6), Cine.head(w, "corin"), 30.0)
	await Cine.say(w, "corin", "Somebody's got to stay! Go on! Go!" if a == 0 else "You'd better! You owe me next year's Lantern Duel!")
	# Hob's cabbage Sparks, skimmed over the shallows
	if Game.flag("hob_gift"):
		Cine.shot(w, Cine.body(w, "hob").global_position + Vector3(-3.4, 1.7, 4.4), Cine.body(w, "hob").global_position + Vector3(0, 1.1, 0), 36.0)
		await Cine.say(w, "hob", "Wait! Found these in the cabbages this morning. Came up with my cabbages, so they're yours. The cabbages I'm keeping.")
		await _skim(w, Cine.body(w, "hob").global_position + Vector3(0, 1.2, 0), w.player.global_position + Vector3(0.5, 0.1, 0.6))
		await Cine.reveal(w, ["mossling", "mossling", "sparkkit", "sparkkit", "emberwisp", "shellguard", "bloomsprite", "burrowmole", "somnowl"], "NINE SPARKS", "from Hob's cabbages")
	# Nell stands apart, looking back at the mill. She does not wave.
	var nell := Cine.body(w, "nell")
	Cine.shot(w, nell.global_position + Vector3(1.6, 1.4, 3.6), crest + Vector3(14.0, 0, 0), 34.0)
	await Cine.wait(w, 3.0)
	# up the hill, the roof of the Crooked Lantern falls in
	Cine.shot(w, near + Vector3(1.6, 1.4, 2.8), crest, 30.0)
	Cine.look(w, "bram", crest)
	await Cine.wait(w, 1.4)
	v.inn_roof_falls()
	_sfx(w, "sigil_strike", 0.6)
	await Cine.wait(w, 2.0)
	Cine.shot(w, Cine.body(w, "bram").global_position + Vector3(0.6, 1.75, 1.4), crest + Vector3(0, -2, 0), 34.0)
	await Cine.wait(w, 3.2)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "We'll come back, Sprout. I swear it on the Lantern.")
	await Cine.fade(w, 1.0, 1.6)


## A bundle of cards skimmed across the river: two skips and a splash, then
## at your feet.
static func _skim(w: World, from: Vector3, to: Vector3) -> void:
	var v := village(w)
	var b := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.06, 0.14)
	b.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.62, 0.3)
	b.material_override = m
	w.add_child(b)
	var water := ThornwoodSet.WATER_Y
	var pts := [from, from.lerp(to, 0.38), from.lerp(to, 0.68), to]
	pts[1].y = water
	pts[2].y = water
	for i in 3:
		var a: Vector3 = pts[i]
		var c: Vector3 = pts[i + 1]
		var hgt := 1.6 if i == 0 else 0.6
		var tw := w.create_tween()
		tw.tween_method(func(u: float) -> void:
			b.global_position = a.lerp(c, u) + Vector3(0, sin(u * PI) * hgt, 0)
			b.rotation.y += 0.3, 0.0, 1.0, 0.5 if i == 0 else 0.3)
		await tw.finished
		if i < 2:
			v.dust_puff(Vector3(c.x, water, c.z))
	await Cine.wait(w, 0.3)
	b.queue_free()


# ------------------------------------------------------------- the camp ---

## The first night: Bram's fire in a clearing. Tam; why Bram stopped taking
## money for duels; Wards and the element chart; a practice round, if you like.
static func _camp(w: World) -> void:
	var v := village(w)
	v.set_scene("road")
	_only(w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	# the road east, walking
	var road: Vector3 = ThornwoodSet.SPOTS.road + Vector3(0, 0, 12.0)
	Cine.place(w, "bram", road, road + Vector3(0, 0, 10))
	Cine.place(w, "player", road + Vector3(-0.6, 0, -1.6), road + Vector3(0, 0, 10))
	Music.play(["thornwood", "menu_theme"], 2.0, true)
	await Cine.caption(w, "The Thornwood road", "east, towards Solhaven")
	Cine.shot(w, road + Vector3(2.4, 1.6, 9.0), road + Vector3(0, 1.3, 0), 40.0)
	Cine.fade(w, 0.0, 1.5)
	Cine.walk(w, "bram", road + Vector3(0.2, 0, 7.0), 1.3)
	await Cine.walk(w, "player", road + Vector3(-0.5, 0, 5.6), 1.3)
	await Cine.wait(w, 0.8)
	await Cine.fade(w, 1.0, 1.0)
	# the fire
	v.set_scene("camp")
	var c: Vector3 = ThornwoodSet.SPOTS.camp
	c.y = v.height(c.x, c.z)
	Cine.place(w, "bram", c + Vector3(-1.2, 0, -0.9), c)
	Cine.place(w, "player", c + Vector3(1.0, 0, 1.2), c)
	Cine.shot(w, c + Vector3(4.6, 1.6, 4.0), c + Vector3(0, 0.8, 0), 40.0)
	Cine.fade(w, 0.0, 1.4)
	await Cine.drift(w, c + Vector3(4.6, 1.6, 4.0), c + Vector3(3.2, 1.4, 3.0), c + Vector3(0, 0.8, 0), c + Vector3(-0.6, 1.0, -0.4), 4.0)
	Cine.over_shoulder(w, "player", "bram", -1.0, 32.0)
	await Cine.say(w, "bram", "Tam ground my flour from the day I opened the inn. Never once weighed it in his own favour. And he went at Ironvault's huntmaster with a hay fork.")
	await Cine.say(w, "bram", "I took you out the back door instead. I'd do it again tomorrow. Doesn't mean I sleep.")
	Cine.two_shot(w, "bram", "player", 3.4, 1.2, 1.0, 36.0)
	await Cine.say(w, "bram", "Lords used to hire me to settle their quarrels, you know. Duel for a field, duel for a dowry, duel for a bridge. Good money.")
	var a := await Cine.choose(w, ["Why did you stop?", "Were you any good?"])
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "...Someone paid me for a job I shouldn't have taken. Then I stopped." if a == 0 else "Sprout, I was the best you never heard of. That's the best kind.")
	# two things he never taught at the Lantern
	await _lesson(w, "wards:1", "Wards", "Before you sleep. Two things we didn't get to at the Lantern. First: Wards. Corin's never owned one.")
	await _lesson(w, "wards:2", "Wards", "Some of the cards in that box are Wards. You set one face down for next to nothing, and it waits. When the right thing happens, a Totem called, a Rite cast, a hit coming in, it springs by itself and does its work. He can't read it, so he can't plan round it. Set them early.")
	await _lesson(w, "elements:1", "The elements", "Second: the rest of the elements. Twelve of them, and every one hurts something and fears something. Water beats fire, you've seen that. Here's the lot.")
	await Cine.overlay(w).chart()
	await _lesson(w, "elements:2", "The elements", "Hit a weakness and it takes half again as much. You won't hold all that in your head tonight. It's in your pack, under How to Duel, with everything else I've told you.")
	await Cine.say(w, "bram", "Fancy a practice round before we sleep? I'll go easy. Mostly.")
	var p := await Cine.choose(w, ["Let's duel.", "Let's sleep."])
	if p == 0:
		await Cine.fade(w, 1.0, 0.5)
		var won: bool = await w._duel(Prologue.practice_duel_spec(Game.starter))
		await Cine.fade(w, 0.0, 0.5)
		await Cine.say(w, "bram", "Hm! Not bad. Not bad at all." if won else "Mostly easy, I said.")
	else:
		await Cine.say(w, "bram", "Wise. You'll need it.")
	Cine.drift(w, Cine.cam_pos(w), c + Vector3(6.0, 4.0, 6.0), c + Vector3(0, 1.0, 0), c + Vector3(0, 0.6, 0), 4.0)
	await Cine.wait(w, 2.0)
	await Cine.fade(w, 1.0, 1.6)


## One of Bram's lessons: said, and kept on the How to Duel page.
static func _lesson(w: World, id: String, group: String, text: String) -> void:
	Game.learn(id, group, "Bram", text)
	await Cine.say(w, "bram", text)


# ------------------------------------------------------------- the road ---

## The second night. The road narrows between thorn trees and the fireflies
## go out. Hunter Dask, with a Shieldhound at his heel. A sworn duel.
static func _road(w: World) -> void:
	var v := village(w)
	v.set_scene("road")
	_only(w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	var r: Vector3 = ThornwoodSet.SPOTS.road
	r.y = v.height(r.x, r.z)
	Cine.place(w, "bram", r + Vector3(0.3, 0, -9.0), r + Vector3(0, 0, 10))
	Cine.place(w, "player", r + Vector3(-0.5, 0, -10.4), r + Vector3(0, 0, 10))
	v.fireflies.amount_ratio = 1.0
	await Cine.caption(w, "The second night")
	Cine.shot(w, r + Vector3(1.8, 1.4, 4.0), r + Vector3(0, 1.4, -8.0), 40.0)
	Cine.fade(w, 0.0, 1.6)
	Cine.walk(w, "bram", r + Vector3(0.3, 0, -1.0), 1.2)
	await Cine.walk(w, "player", r + Vector3(-0.5, 0, -2.4), 1.2)
	# the fireflies go out
	Music.stop(2.0)
	var ft := w.create_tween()
	ft.tween_property(v.fireflies, "amount_ratio", 0.0, 3.0)
	Cine.shot(w, r + Vector3(-1.0, 1.7, -5.0), r + Vector3(0.6, 1.6, 4.0), 38.0)
	await Cine.wait(w, 3.2)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", 1.0, 30.0)
	await Cine.say(w, "bram", "Stay close.", 1.6)
	# a wiry figure steps out of the trees, a Shieldhound clanking at his heel
	var dask_at := r + Vector3(0.0, 0, 3.4)
	Cine.spawn(w, "dask", "hunter", r + Vector3(3.6, 0, 4.2), "Hunter Dask")
	Cine.beast(w, "dhound", "shieldhound", r + Vector3(4.6, 0, 5.4), Color(1.0, 0.8, 0.35, 1.0))
	Cine.shot(w, r + Vector3(-1.4, 1.4, -2.6), dask_at + Vector3(0, 1.3, 0), 36.0)
	Cine.path(w, "dhound", [dask_at + Vector3(1.0, 0, 0.6)], 1.4)
	await Cine.walk(w, "dask", dask_at, 1.3)
	Cine.look(w, "dask", w.player.global_position)
	Cine.look(w, "bram", dask_at)
	Cine.look(w, "player", dask_at)
	Music.play(["dask"], 1.0, true)
	Cine.shot(w, dask_at + Vector3(-3.0, 1.6, -4.0), dask_at + Vector3(0.3, 1.25, 0), 34.0)
	await Cine.say(w, "dask", "The Unsworn's card. Hand it over, and the old man lives.")
	# Bram, from beside Dask (a cut-out can't be looked past)
	var to_b: Vector3 = Cine.body(w, "bram").global_position - dask_at
	to_b.y = 0.0
	to_b = to_b.normalized()
	Cine.shot(w, dask_at + to_b * 1.2 + to_b.cross(Vector3.UP) * 1.1 + Vector3(0, 1.6, 0), Cine.head(w, "bram") + Vector3(0, -0.1, 0), 32.0)
	await Cine.say(w, "bram", "Covenant law, boy. Stake it in a sworn duel, or walk away.")
	Cine.shot(w, dask_at + Vector3(-3.0, 1.6, -4.0), dask_at + Vector3(0.3, 1.25, 0), 34.0)
	await Cine.say(w, "dask", "Fine. Swear it, Unsworn. Your card against my whole deck.")
	# the oath: a ring of gold closes round the two of them like a lock
	await _oath(w, (w.player.global_position + dask_at) * 0.5)
	await Cine.say(w, "", "Lose a story duel and you simply fight it again.", 2.6)
	await Cine.fade(w, 1.0, 0.5)
	var won := false
	while not won:
		won = await w._duel(Prologue.road_duel_spec())
	Game.set_flag("beat_hunter")
	for id in DuelCards.card_list("dask_hounds"):
		Game.v2.collection[id] = int(Game.v2.collection.get(id, 0)) + 1
		if not Game.v2.codex.has(id):
			Game.v2.codex[id] = "seen"
	Cine.shot(w, dask_at + Vector3(-3.0, 1.6, -4.0), dask_at + Vector3(0.3, 1.25, 0), 34.0)
	await Cine.fade(w, 0.0, 0.6)
	await Cine.say(w, "dask", "Take them, then. This isn't over. Caldus Morne pays well for that card, Unsworn.")
	# he throws his deck at your feet and is gone into the trees
	await _throw_deck(w, dask_at + Vector3(0, 1.2, 0), w.player.global_position + Vector3(0.4, 0.05, 0.9))
	Cine.shot(w, r + Vector3(-1.2, 1.6, -4.0), dask_at + Vector3(2.0, 1.2, 2.0), 38.0)
	Cine.path(w, "dhound", [r + Vector3(6.0, 0, 7.0), r + Vector3(14.0, 0, 9.0)], 3.0)
	await Cine.path(w, "dask", [r + Vector3(5.0, 0, 6.0), r + Vector3(12.0, 0, 8.0)], 2.2)
	Cine.despawn(w, "dask")
	Cine.despawn(w, "dhound")
	await Cine.reveal(w, DuelCards.card_list("dask_hounds").slice(0, 12), "DASK'S DECK", "thirty cards: hounds, traps and poison, yours by the Covenant")
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	Cine.look(w, "bram", r + Vector3(12, 0, 8))
	await Cine.say(w, "bram", "Morne.", 2.0)
	await Cine.wait(w, 1.0)
	await Cine.fade(w, 1.0, 1.6)


## The sworn oath: a ring of gold light round the two duellists, closing.
static func _oath(w: World, at: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 3.6
	tm.outer_radius = 3.75
	tm.rings = 48
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.82, 0.4) * 3.0
	ring.material_override = m
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(ring)
	ring.global_position = at + Vector3(0, 0.08, 0)
	ring.scale = Vector3.ONE * 2.2
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.4)
	l.light_energy = 3.0
	l.omni_range = 10.0
	l.position = Vector3(0, 1.5, 0)
	ring.add_child(l)
	Cine.shot(w, at + Vector3(0, 9.0, 7.0), at, 50.0)
	var tw := w.create_tween()
	tw.tween_property(ring, "scale", Vector3.ONE * 0.8, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	_sfx(w, "ward_set", 0.8)
	w.shake(0.15)
	await w.flash(Color(1.0, 0.85, 0.5), 0.06, 0.6)
	var t2 := w.create_tween()
	t2.tween_property(m, "albedo_color:a", 0.0, 0.8)
	t2.parallel().tween_property(l, "light_energy", 0.0, 0.8)
	await t2.finished
	ring.queue_free()


## Dask's deck, thrown at your feet: it bursts and the cards scatter.
static func _throw_deck(w: World, from: Vector3, to: Vector3) -> void:
	var b := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.08, 0.04, 0.11)
	b.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.18, 0.2)
	b.material_override = m
	w.add_child(b)
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void:
		b.global_position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 0.8, 0)
		b.rotation.x += 0.4, 0.0, 1.0, 0.55)
	await tw.finished
	b.queue_free()
	var v := village(w)
	for i in 14:
		var c := InnRooms.blank_card(null)
		(c.material_override as StandardMaterial3D).albedo_color = Color(0.35, 0.3, 0.3)
		(c.material_override as StandardMaterial3D).emission_energy_multiplier = 0.0
		w.add_child(c)
		c.global_position = to + Vector3(0, 0.03, 0)
		var land := to + Vector3(randf_range(-0.6, 0.6), 0.02, randf_range(-0.5, 0.5))
		land.y = v.height(land.x, land.z) + 0.02
		var ct := w.create_tween()
		ct.tween_property(c, "global_position", land, randf_range(0.25, 0.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		c.rotation = Vector3(-PI * 0.5, randf() * TAU, 0)
	v.dust_puff(to)
	await Cine.wait(w, 0.6)


# ------------------------------------------------------------ the ridge ---

## At dawn, white towers catch the first sun across the plains.
static func _ridge(w: World) -> void:
	var v := village(w)
	v.set_scene("ridge")
	_only(w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	var rg: Vector3 = ThornwoodSet.SPOTS.ridge
	rg.y = v.height(rg.x, rg.z)
	var sol := ThornwoodSet.SOLHAVEN
	w.cam.far = 1200.0   # Solhaven is a long way off across the plains
	Cine.place(w, "bram", rg + Vector3(0.8, 0, -2.4), sol)
	Cine.place(w, "player", rg + Vector3(-0.6, 0, -2.8), sol)
	Music.play(["solhaven_dawn", "menu_theme"], 2.0, true)
	await Cine.caption(w, "Dawn")
	# from behind the two of them, the plains, and Solhaven far off
	Cine.shot(w, rg + Vector3(1.2, 2.0, -7.5), sol + Vector3(0, 12.0, 0), 34.0)
	Cine.fade(w, 0.0, 2.2)
	Cine.walk(w, "bram", rg + Vector3(0.8, 0, 0.6), 1.0)
	await Cine.walk(w, "player", rg + Vector3(-0.6, 0, 0.3), 1.0)
	await Cine.drift(w, rg + Vector3(1.2, 2.0, -7.5), rg + Vector3(0.6, 2.3, -5.0), sol + Vector3(0, 12.0, 0), sol + Vector3(0, 16.0, 0), 4.5, 26.0)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "Go through Dask's cards when we stop. Swap in what's nastier than what you've got. That's most of duelling.")
	Cine.look(w, "bram", sol)
	Cine.shot(w, rg + Vector3(-1.7, 1.85, -3.2), sol + Vector3(0, 16.0, 0), 24.0)
	await Cine.say(w, "bram", "There she is. Solhaven. Gold on the outside. We'll see about the inside.")
	await Cine.wait(w, 1.0)
	await Cine.fade(w, 1.0, 1.8)
	await Cine.caption(w, "Chapter One", "The Sun's Court", 2.4)
