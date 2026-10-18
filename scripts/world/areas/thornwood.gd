extends RefCounted
## The Thornwood: the end of the Prologue's film (Master Script v3, P4's
## river and P5). The riverbank below burning Ashford, the road east, Bram's
## campfire and his four old decks, the practice round on the second morning,
## the narrow road where Dask is waiting, and at dawn the first sight of
## Solhaven. The place itself is ThornwoodSet.

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
		{"id": "ned", "look": "fiddler", "name": "Ned", "pos": fb + Vector3(-2.2, 0, 1.4), "talk": []},
		{"id": "nell", "look": "elder", "name": "Old Nell", "pos": fb + Vector3(4.6, 0, -0.6), "talk": []},
		{"id": "corin_mam", "look": "refugee", "name": "Corin's mam", "pos": fb + Vector3(3.95, 0, -0.35), "talk": []},
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
	var parts := ["river", "camp", "morning", "road", "ridge"]
	var i0 := maxi(0, parts.find(part))
	for i in range(i0, parts.size()):
		Game.set_flag("thorn_part", parts[i])
		Game.save_game()
		match parts[i]:
			"river":
				await _river(w)
			"camp":
				await _camp(w)
			"morning":
				await _morning(w)
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

## Out of the tunnel onto the riverbank (v3, P4). Above, Ashford burns. On
## the far bank the village huddles, safe: Corin, soot on his face, holding
## Tilly's hand, and his mam with her arm round Nell. Corin stays; Hob wades
## in and skims his nine cabbage Sparks across; Nell looks back at the mill.
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
	Cine.place(w, "nell", fb + Vector3(4.6, 0, -0.6), near)
	Cine.place(w, "corin_mam", fb + Vector3(3.95, 0, -0.35), near)
	_corin_holds_tilly(w, near)
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
	Cine.shot(w, near + Vector3(-1.2, 1.7, -1.6), Cine.head(w, "corin") + Vector3(0, -0.3, 0), 16.0)
	await Cine.say(w, "corin", "Go! I'll see to them!")
	Cine.over_shoulder(w, "corin", "player", 1.0, 32.0)
	var a := await Cine.choose(w, ["Come with us!", "We'll come back for you!"])
	Cine.shot(w, near + Vector3(-1.2, 1.7, -1.6), Cine.head(w, "corin") + Vector3(0, -0.2, 0), 14.0)
	if a == 0:
		await Cine.say(w, "corin", "And leave Mam? And Nell? Somebody's got to stay.")
		await Cine.wait(w, 0.8)
		await Cine.say(w, "corin", "Go!", 1.6)
	else:
		await Cine.say(w, "corin", "You'd better.")
		await Cine.wait(w, 0.8)
		await Cine.say(w, "corin", "Go on! Before they see you!")
	# Hob wades in up to his knees, and skims his cabbage Sparks over the shallows
	var hob := Cine.body(w, "hob")
	var hp := hob.global_position
	Cine.shot(w, hp + Vector3(-3.4, 1.7, 4.4), hp + Vector3(0, 1.1, 0), 36.0)
	await Cine.say(w, "hob", "Wait!", 1.2)
	# out from the far bank until the water would be over his knees
	var wade := Vector3(hp.x, 0, hp.z)
	while wade.z > 0.0 and v.height(wade.x, wade.z - 0.2) > ThornwoodSet.WATER_Y - 0.45:
		wade.z -= 0.2
	# from the near bank, across the water at him
	var from_near := Vector3(hp.x - 2.0, 0, -1.6)
	from_near.y = maxf(v.height(from_near.x, from_near.z), ThornwoodSet.WATER_Y) + 1.5
	Cine.shot(w, from_near, Vector3(hp.x, 0.6, 5.5), 36.0)
	await Cine.walk(w, "hob", wade, 1.3)
	Cine.look(w, "hob", w.player.global_position)
	Cine.shot(w, from_near, Cine.head(w, "hob") + Vector3(0, -0.45, 0), 30.0)
	await Cine.say(w, "hob", "These came up in my cabbages. Tam said this morning you'd need them more than me.")
	await _skim(w, hob.global_position + Vector3(0, 1.2, 0), w.player.global_position + Vector3(0.5, 0.1, 0.6))
	Prologue.hob_sparks()
	await Cine.reveal(w, Prologue.HOB_SPARKS, "NINE SPARKS", "from Hob's cabbages")
	# Nell stands apart from the others, looking back at the mill. She does not wave.
	var nell := Cine.body(w, "nell")
	Cine.place(w, "nell", nell.global_position + Vector3(1.6, 0, -0.2), crest + Vector3(14.0, 0, 0))
	var nf_at := nell.global_position + Vector3(-0.8, 0, -4.5)
	nf_at.y = maxf(v.height(nf_at.x, nf_at.z), ThornwoodSet.WATER_Y) + 1.5
	Cine.shot(w, nf_at, Cine.head(w, "nell") + Vector3(0, -0.15, 0), 20.0)
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


## Corin holding Tilly's hand on the far bank: she stands close at his side
## (the side she was on), both looking across at `near`, hand in hand.
static func _corin_holds_tilly(w: World, near: Vector3) -> void:
	var c := Cine.body(w, "corin")
	var t := Cine.body(w, "tilly")
	if c == null or t == null or not (Cine.fig(w, "tilly") is Figure3D) or not (Cine.fig(w, "corin") is Figure3D):
		return
	var look := near - c.global_position
	look.y = 0.0
	var right := look.normalized().cross(Vector3.UP)
	var side := right if (t.global_position - c.global_position).dot(right) >= 0.0 else -right
	var at := c.global_position + side * 0.55 + look.normalized() * 0.05
	at.y = 0.0   # on the ground there
	Cine.place(w, "tilly", at, near)
	Cine.hold_hands(w, "corin", "tilly", 0.01)


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

## Bram's line on each of his old decks, as the player looks at its box.
const DECK_LINES := {
	"emberstorm": "Emberstorm. Goes first and goes hardest. I won a duke's bet with it, and I was sorry by morning.",
	"tidegrove": "Tidegrove. Patient. Mends what the others break, then drowns them. Nobody ever thanked me for a win with it.",
	"ironstone": "Ironstone. Takes a beating and gives it back twice. The one I'd pick, if I'm honest about myself.",
	"veilwild": "Veilwild. Tricks and dreams. It's won duels it had no business winning. I never quite trusted it.",
}
## The colours of the four card boxes (as they were in the cellar chest).
const BOX_COLS := {"emberstorm": Color(0.55, 0.16, 0.08), "tidegrove": Color(0.1, 0.25, 0.45), "ironstone": Color(0.35, 0.33, 0.3), "veilwild": Color(0.32, 0.16, 0.42)}


## The first night (v3, P5): the walk east, then Bram's fire in a clearing.
## Tam, and what the player told him; Bram's four old decks on a log, one of
## them chosen and its deck screen walked round; why Bram stopped taking money
## for duels. It ends on "Then I stopped."
static func _camp(w: World) -> void:
	var v := village(w)
	v.set_scene("road")
	_only(w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	# the road east, walking
	var road: Vector3 = ThornwoodSet.SPOTS.road + Vector3(0, 0, 12.0)
	road.y = v.height(road.x, road.z)
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
	# the fire; something that was probably a rabbit; the sack beside him, unopened
	v.set_scene("camp")
	var c: Vector3 = ThornwoodSet.SPOTS.camp
	c.y = v.height(c.x, c.z)
	Cine.place(w, "bram", c + Vector3(-1.2, 0, -0.9), c)
	Cine.place(w, "player", c + Vector3(1.0, 0, 1.2), c)
	var sack := _camp_sack(w, c + Vector3(-1.75, 0, -0.35))
	Cine.shot(w, c + Vector3(4.6, 1.6, 4.0), c + Vector3(0, 0.8, 0), 40.0)
	Cine.fade(w, 0.0, 1.4)
	await Cine.drift(w, c + Vector3(4.6, 1.6, 4.0), c + Vector3(3.2, 1.4, 3.0), c + Vector3(0, 0.8, 0), c + Vector3(-0.6, 1.0, -0.4), 4.0)
	Cine.over_shoulder(w, "player", "bram", -1.0, 32.0)
	await Cine.say(w, "bram", "Tam ground my flour from the day I opened the inn. Never once weighed it in his own favour.")
	await Cine.say(w, "bram", "He stood there and lied to that woman's face for you. And I took you out the back.")
	await Cine.say(w, "bram", "I'd do it again tomorrow.")
	if Game.flag("tam_told"):
		await Cine.say(w, "bram", "You told him what that letter said, didn't you. So he knew exactly what she was offering him.")
		Cine.two_shot(w, "bram", "player", 3.4, 1.2, 1.0, 36.0)
		var t1 := await Cine.choose(w, ["He knew. He chose.", "I should have lied to him."])
		Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
		await Cine.say(w, "bram", "He did. Remember that, when you start thinking it was you." if t1 == 0 else "No. He'd have wanted to know what he was buying.")
	else:
		await Cine.say(w, "bram", "He didn't know the note was due, did he. He found out from her, and lied for you anyway.")
		Cine.two_shot(w, "bram", "player", 3.4, 1.2, 1.0, 36.0)
		var t2 := await Cine.choose(w, ["I should have told him.", "I'm glad he had his night."])
		Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
		await Cine.say(w, "bram", "Maybe. You gave him one good evening. That's not nothing." if t2 == 0 else "So am I.")
	# he unties the sack and sets the four boxes in a row on a log
	var ids: Array = DuelCards.DECKS.keys()
	var boxes := await _boxes_on_log(w, sack, ids)
	var lg := _log_spot(v)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 32.0)
	await Cine.say(w, "bram", "My old decks. One for every kind of fight I ever had. You'll want your own now; those Sparks won't last you past Solhaven.")
	var deck := await _choose_deck(w, boxes, ids, lg)
	_take_deck(deck)
	# choosing opens the deck screen for the first time, and Bram walks you round it
	await _deck_tour(w)
	# then the fire, and the lords
	for b in boxes:
		(b as Node3D).queue_free()
	Cine.look(w, "bram", c)
	Cine.two_shot(w, "bram", "player", 3.4, 1.2, 1.0, 36.0)
	await Cine.say(w, "bram", "Lords used to hire me to settle their quarrels, you know. Duel for a field, duel for a dowry, duel for a bridge. Good money.")
	var a := await Cine.choose(w, ["Why did you stop?", "Were you any good?"])
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	if a == 0:
		await Cine.say(w, "bram", "Someone paid me for a job I shouldn't have taken.")
		await Cine.wait(w, 1.2)
		await Cine.say(w, "bram", "Then I stopped.")
	else:
		await Cine.say(w, "bram", "Good enough that the people I beat still know my name. Not good enough to be proud of it.")
	# he banks the fire, and doesn't say anything else that night
	Cine.look(w, "bram", c)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).act("lift", 0.9)
	var ft := w.create_tween()
	ft.tween_method(v.campfire_level, 3.2, 1.1, 3.0)
	Cine.drift(w, Cine.cam_pos(w), c + Vector3(6.0, 4.0, 6.0), c + Vector3(0, 1.0, 0), c + Vector3(0, 0.6, 0), 4.0)
	await Cine.wait(w, 2.6)
	await Cine.fade(w, 1.0, 1.6)
	v.campfire_level(3.2)
	if is_instance_valid(sack):
		sack.queue_free()


## Bram's deck becomes the player's real deck (the Spark deck and the
## Lantern Moth stay in the collection: new_game keeps it), with the
## Prologue's other gifts. A save from here comes back to the Thornwood.
static func _take_deck(deck: String) -> void:
	Game.new_game(Game.player_name, deck, true)
	Game.set_flag("bram_deck")
	Prologue.prologue_gifts()
	Game.area = "thornwood"
	Game.spawn = "river"
	Game.unlock("deck")
	Game.unlock("codex")
	Game.save_game()


## Bram's sack of card boxes, set down by the fire.
static func _camp_sack(w: World, at: Vector3) -> Node3D:
	var v := village(w)
	var n := Node3D.new()
	v.add_child(n)
	at.y = v.height(at.x, at.z)
	n.global_position = at
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.5, 0.41, 0.28)
	cloth.roughness = 1.0
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.5
	body.mesh = sm
	body.material_override = cloth
	body.position = Vector3(0, 0.22, 0)
	body.scale = Vector3(1.0, 0.9, 0.85)
	n.add_child(body)
	var neck := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.06
	nm.bottom_radius = 0.035
	nm.height = 0.12
	neck.mesh = nm
	neck.material_override = cloth
	neck.position = Vector3(0, 0.46, 0)
	n.add_child(neck)
	return n


## The log by the fire: its middle, which way it runs, and the height of its top.
static func _log_spot(v: ThornwoodSet) -> Dictionary:
	var c: Vector3 = ThornwoodSet.SPOTS.camp
	c.y = v.height(c.x, c.z)
	var mid := c + Vector3(-0.2, 0.2, 1.7)
	var along := Basis.from_euler(Vector3(0, 0.3, PI / 2)) * Vector3.UP
	along.y = 0.0
	return {"mid": mid, "along": along.normalized(), "top": mid.y + 0.23}


## Bram takes the four boxes out of the sack and sets them in a row on the log.
static func _boxes_on_log(w: World, sack: Node3D, ids: Array) -> Array:
	var v := village(w)
	var lg := _log_spot(v)
	var mid: Vector3 = lg.mid
	var along: Vector3 = lg.along
	# from beside the log, the fire behind
	var side := along.cross(Vector3.UP)
	Cine.shot(w, mid - side * 1.9 + Vector3(0, 1.25, 0) + along * 0.4, mid + Vector3(0, 0.25, 0), 38.0)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).act("lift", 1.0)
	var boxes: Array = []
	for i in ids.size():
		var m := StandardMaterial3D.new()
		m.albedo_color = BOX_COLS.get(ids[i], Color(0.4, 0.3, 0.2))
		m.roughness = 0.85
		var b := Node3D.new()
		v.add_child(b)
		v.box(b, Vector3(0.2, 0.09, 0.28), Vector3(0, 0.045, 0), m)
		var to := mid + along * (-0.48 + i * 0.32)
		to.y = float(lg.top)
		var from := sack.global_position + Vector3(0, 0.45, 0)
		b.global_position = from
		b.rotation.y = atan2(along.x, along.z) + randf_range(-0.08, 0.08)
		var tw := w.create_tween()
		tw.tween_method(func(u: float) -> void:
			if is_instance_valid(b):
				b.global_position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 0.3, 0), 0.0, 1.0, 0.45)
		_sfx(w, "card_lift", 0.9)
		boxes.append(b)
		await Cine.wait(w, 0.4)
	await Cine.wait(w, 0.5)
	return boxes


## "Choose your deck. (Tap a box to see it. Tap again to choose.)" A box
## tapped is looked at, with Bram's line on it; the same box tapped again is
## chosen. Returns the deck's id.
static func _choose_deck(w: World, boxes: Array, ids: Array, lg: Dictionary) -> String:
	var mid: Vector3 = lg.mid
	var along: Vector3 = lg.along
	var side := along.cross(Vector3.UP)
	var row_cam := mid - side * 1.5 + Vector3(0, 1.15, 0) - along * 0.1
	Cine.shot(w, row_cam, mid + Vector3(0, 0.22, 0), 40.0)
	var picker := DeckBoxes.new()
	w.add_child(picker)
	picker.setup(w.cam, boxes, ids)
	w.set_meta("deck_boxes", picker)
	var chosen := ""
	while chosen == "":
		picker.listen()
		var r: Dictionary = await picker.tapped
		var i := int(r.index)
		var b: Node3D = boxes[i]
		if bool(r.again):
			chosen = String(ids[i])
			break
		# look at it: close on the box, its card at the side, Bram's word on it
		for k in boxes.size():
			var bk: Node3D = boxes[k]
			var lift := w.create_tween()
			lift.tween_property(bk, "position:y", float(lg.top) + (0.06 if k == i else 0.0), 0.25)
		Cine.move(w, b.global_position - side * 1.0 + Vector3(0, 0.75, 0), b.global_position + Vector3(0, 0.08, 0), 0.6, 36.0)
		picker.show_deck(i)
		await Cine.say(w, "bram", String(DECK_LINES.get(ids[i], "")))
		# back to the row, the card still up: tap it again to choose, or another
		Cine.move(w, row_cam, mid + Vector3(0, 0.22, 0), 0.5, 40.0)
	picker.hide_deck()
	# the deck screen opens on its paintings in a moment: start loading them
	# now, while he nods, so it comes up without a stall
	CardFace.warm_art(DuelCards.card_list(chosen))
	# that one: he nods slowly
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "That one.")
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).pose("sit", 0.06, 0.5)   # a slow nod: his head dips and comes up
		await Cine.wait(w, 0.7)
		(bf as Figure3D).release(0.6)
	await Cine.wait(w, 0.5)
	await Cine.say(w, "bram", "Yes. That suits you.")
	picker.finish()
	w.remove_meta("deck_boxes")
	return chosen


## The deck screen opens by itself, and Bram walks the player round it one
## gated line at a time (PackTour.CAMP_DECK). The film's bars step aside.
static func _deck_tour(w: World) -> void:
	if w.hud == null:
		return
	await Cine.overlay(w).bars(false, 0.4)
	w.hud.open_menu("deck")
	await w.hud.pack_tour(PackTour.CAMP_DECK)
	w.hud.set_controls_visible(false)
	await Cine.overlay(w).bars(true, 0.4)


# --------------------------------------------------------- the second day ---

## The second morning (v3, P5): Bram sets the four boxes back in the sack and
## keeps one deck out. A practice round before they walk, if the player likes:
## it can be lost, and the story goes on either way. The blank card has its own
## slot beside the deck in the duel (BlankCardSlot).
static func _morning(w: World) -> void:
	var v := village(w)
	v.set_scene("morning")
	_only(w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	var c: Vector3 = ThornwoodSet.SPOTS.camp
	c.y = v.height(c.x, c.z)
	Cine.place(w, "bram", c + Vector3(-1.2, 0, -0.9), c + Vector3(-0.2, 0, 1.7))
	Cine.place(w, "player", c + Vector3(1.0, 0, 1.2), c + Vector3(-1.2, 0, -0.9))
	var sack := _camp_sack(w, c + Vector3(-1.75, 0, -0.35))
	var lg := _log_spot(v)
	var ids: Array = DuelCards.DECKS.keys()
	var mine := String(Game.starter)
	var spare := "ironstone" if mine != "ironstone" else "tidegrove"
	var boxes: Array = []
	for i in ids.size():
		if ids[i] == mine:
			continue   # yours is in your pack
		var m := StandardMaterial3D.new()
		m.albedo_color = BOX_COLS.get(ids[i], Color(0.4, 0.3, 0.2))
		var b := Node3D.new()
		v.add_child(b)
		v.box(b, Vector3(0.2, 0.09, 0.28), Vector3(0, 0.045, 0), m)
		var at: Vector3 = (lg.mid as Vector3) + (lg.along as Vector3) * (-0.48 + i * 0.32)
		at.y = float(lg.top)
		b.global_position = at
		b.rotation.y = atan2(lg.along.x, lg.along.z)
		b.set_meta("deck", ids[i])
		boxes.append(b)
	Music.play(["thornwood", "menu_theme"], 2.0, true)
	var side: Vector3 = (lg.along as Vector3).cross(Vector3.UP)
	var bf = Cine.fig(w, "bram")
	# the game was closed during the practice round: straight back into it
	var p := 0 if Game.flag("practice_on") else -1
	if p < 0:
		await Cine.caption(w, "The second day")
		Cine.shot(w, c + Vector3(5.0, 1.8, 3.6), c + Vector3(-0.4, 0.7, 0.4), 40.0)
		Cine.fade(w, 0.0, 1.6)
		await Cine.wait(w, 1.6)
		await _boxes_to_sack(w, boxes, sack, spare, lg)
		Cine.look(w, "bram", w.player.global_position)
		Cine.over_shoulder(w, "player", "bram", -1.0, 32.0)
		await Cine.say(w, "bram", "Practice round before we walk? I'll go easy.")
		p = await Cine.choose(w, ["Let's duel.", "Let's walk."])
	else:
		for b in boxes:
			(b as Node3D).queue_free()
	if p == 0:
		Game.set_flag("practice_on")
		Game.save_game()
		await Cine.fade(w, 1.0, 0.5)
		var won: bool = await w._duel(Prologue.practice_duel_spec(Game.starter))
		Game.set_flag("practice_on", false)
		Cine.overlay(w).black(true)
		if won:
			# he studies the cards on the log a while
			_cards_on_log(w, lg)
			# (on the ground beside the log: the log's middle is 0.2 m up)
			var by_log: Vector3 = (lg.mid as Vector3) - side * 0.75 + Vector3(0, 0, 0.1)
			Cine.place(w, "bram", Vector3(by_log.x, 0.0, by_log.z), lg.mid)
			Cine.shot(w, (lg.mid as Vector3) + side * 1.9 + Vector3(0, 1.5, 0), (lg.mid as Vector3) + Vector3(0, 0.6, 0) - side * 0.4, 40.0)
			if bf is Figure3D:
				(bf as Figure3D).pose("sit", 0.22, 0.5)   # bent over them
			await Cine.fade(w, 0.0, 0.6)
			await Cine.say(w, "bram", "Hm.", 1.4)
			await Cine.wait(w, 1.6)
			if bf is Figure3D:
				(bf as Figure3D).release(0.5)
			await Cine.say(w, "bram", "Not bad.")
		else:
			Cine.over_shoulder(w, "player", "bram", -1.0, 32.0)
			await Cine.fade(w, 0.0, 0.6)
			await Cine.say(w, "bram", "I said easy. I never said soft.")
	else:
		await Cine.say(w, "bram", "Suit yourself.")
	await Cine.wait(w, 0.8)
	await Cine.fade(w, 1.0, 1.4)
	_drop_box(w)
	if is_instance_valid(sack):
		sack.queue_free()
	for n in v.get_children():
		if n.has_meta("log_card"):
			n.queue_free()


## Bram sets the boxes back in the sack and keeps one deck out (`spare`).
static func _boxes_to_sack(w: World, boxes: Array, sack: Node3D, spare: String, lg: Dictionary) -> void:
	var side: Vector3 = (lg.along as Vector3).cross(Vector3.UP)
	Cine.shot(w, (lg.mid as Vector3) - side * 1.9 + Vector3(0, 1.25, 0), (lg.mid as Vector3) + Vector3(0, 0.25, 0), 38.0)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).act("lift", 1.0)
	var kept: Node3D = null
	for b in boxes:
		var bn: Node3D = b
		if String(bn.get_meta("deck")) == spare:
			kept = bn
			continue
		var from := bn.global_position
		var to := sack.global_position + Vector3(0, 0.4, 0)
		var tw := w.create_tween()
		tw.tween_method(func(u: float) -> void:
			if is_instance_valid(bn):
				bn.global_position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 0.3, 0), 0.0, 1.0, 0.45)
		tw.tween_callback(bn.queue_free)
		await Cine.wait(w, 0.45)
	if kept != null:
		_hold_box(w, kept)
	await Cine.wait(w, 0.6)


## Bram keeps one deck out: its box in his hand.
static func _hold_box(w: World, box: Node3D) -> void:
	var f = Cine.fig(w, "bram")
	if f is Figure3D:
		box.get_parent().remove_child(box)
		(f as Figure3D).hand_light(box)
		box.position = Vector3(0.0, 0.05, 0.05)
		box.rotation = Vector3.ZERO
		w.set_meta("bram_box", box)
	else:
		box.queue_free()


static func _drop_box(w: World) -> void:
	var f = Cine.fig(w, "bram")
	if f is Figure3D:
		(f as Figure3D).hand_light(null)
	if w.has_meta("bram_box"):
		w.remove_meta("bram_box")


## The practice round's cards laid out on the log, for Bram to look at.
static func _cards_on_log(w: World, lg: Dictionary) -> void:
	var v := village(w)
	for k in 6:
		var cm := InnRooms.blank_card(null)
		(cm.material_override as StandardMaterial3D).albedo_color = Color(0.55, 0.45, 0.32) if k % 2 == 0 else Color(0.3, 0.38, 0.5)
		(cm.material_override as StandardMaterial3D).emission_energy_multiplier = 0.0
		cm.scale = Vector3.ONE * 2.2
		cm.set_meta("log_card", true)
		v.add_child(cm)
		var at: Vector3 = (lg.mid as Vector3) + (lg.along as Vector3) * (-0.55 + k * 0.22)
		at.y = float(lg.top) + 0.01
		cm.global_position = at
		cm.rotation = Vector3(-PI * 0.5, atan2(lg.along.x, lg.along.z) + randf_range(-0.2, 0.2), 0)


# ------------------------------------------------------------- the road ---

## The second night (v3, P5). The road narrows between thorn trees and the
## fireflies go out, all at once. Dask, young, a bronze mask over his mouth, a
## Shieldhound at his heel, his hands not steady: a sworn wager, his whole
## deck against the blank card. His duel rule is Run to Ground; losing it is
## taken back by Morrowen and played again (spec.retry). After it, his mam's
## note, Morne, and Keep your hound / Go home.
static func _road(w: World) -> void:
	var v := village(w)
	v.set_scene("road")
	_only(w, ["bram"])
	await Cine.begin(w)
	Cine.overlay(w).black(true)
	# Dask's Shieldhound steps out of the trees mid-shot: loaded now, behind the black
	Cine.keep(w, "res://assets/models/creatures/shieldhound.glb")
	var r: Vector3 = ThornwoodSet.SPOTS.road
	r.y = v.height(r.x, r.z)
	Cine.place(w, "bram", r + Vector3(0.3, 0, -9.0), r + Vector3(0, 0, 10))
	Cine.place(w, "player", r + Vector3(-0.5, 0, -10.4), r + Vector3(0, 0, 10))
	var dask_at := r + Vector3(0.0, 0, 3.4)
	var dask_cam := dask_at + Vector3(-3.0, 1.6, -4.0)
	var mid := (r + Vector3(-0.5, 0, -2.4) + dask_at) * 0.5
	# the game was closed during the duel: straight back into it
	if Game.flag("road_duel_on"):
		v.fireflies.amount_ratio = 0.0
		Cine.place(w, "bram", r + Vector3(0.3, 0, -1.0), dask_at)
		Cine.place(w, "player", r + Vector3(-0.5, 0, -2.4), dask_at)
		Cine.spawn(w, "dask", "hunter", dask_at, "Dask")
		Cine.beast(w, "dhound", "shieldhound", dask_at + Vector3(1.0, 0, 0.6), Color(1.0, 0.8, 0.35, 1.0))
		Cine.look(w, "dask", w.player.global_position)
	else:
		await _road_meeting(w, r, dask_at, dask_cam, mid)
	Game.set_flag("road_duel_on")
	Game.save_game()
	var won := false
	while not won:
		won = await w._duel(Prologue.road_duel_spec())
	Game.set_flag("road_duel_on", false)
	Game.set_flag("beat_hunter")
	# beaten: he stares at the ring of light as it fades
	Cine.overlay(w).black(true)
	var ring := _ring(w, mid, 1.0)
	Cine.shot(w, dask_cam, dask_at + Vector3(0.3, 1.25, 0), 34.0)
	await Cine.fade(w, 0.0, 0.6)
	await Cine.say(w, "dask", "No.", 1.6)
	Cine.look(w, "dask", mid)
	Cine.shot(w, dask_at + Vector3(-2.6, 1.6, 3.2), mid + Vector3(0, 0.1, 0), 40.0)
	var rf := w.create_tween().set_parallel(true)
	rf.tween_property(ring.material_override, "albedo_color:a", 0.0, 3.0)
	rf.tween_property(ring.get_child(0), "light_energy", 0.0, 3.0)
	await Cine.wait(w, 1.6)
	await Cine.say(w, "dask", "No, that was it. That was all of it.")
	ring.queue_free()
	Cine.look(w, "dask", w.player.global_position)
	Cine.shot(w, dask_cam, dask_at + Vector3(0.3, 1.25, 0), 30.0)
	await Cine.say(w, "dask", "My mam's note is with Ironvault. Eleven years. That card was the whole note.")
	# he unbuckles his deck box and sets it at your feet; the Shieldhound whines
	var feet := w.player.global_position + (dask_at - w.player.global_position).normalized() * 0.7
	var across := (dask_at - w.player.global_position).normalized().cross(Vector3.UP)
	Cine.shot(w, (feet + dask_at) * 0.5 + across * 3.4 + Vector3(0, 1.4, 0), (feet + dask_at) * 0.5 + Vector3(0, 1.0, 0), 40.0)
	await Cine.walk(w, "dask", feet + (dask_at - feet).normalized() * 0.45, 1.0)
	_kneel_cutout(w, "dask", true)
	var box := _deck_box(w, feet)
	Cine.shot(w, feet + Vector3(-1.2, 0.9, -1.0), feet + Vector3(0, 0.2, 0), 36.0)
	await Cine.wait(w, 0.8)
	if Sfx.has_file("hound_whine"):
		_sfx(w, "hound_whine")
	await Cine.wait(w, 0.6)
	_kneel_cutout(w, "dask", false)
	_front_shot(w, "dask", w.player.global_position, 36.0)
	await Cine.say(w, "dask", "Caldus Morne wants that card. Do you understand? Everyone on this road's going to know your face.")
	# the wager: his whole deck
	for id in DuelCards.card_list("dask_hounds"):
		Game.v2.collection[id] = int(Game.v2.collection.get(id, 0)) + 1
		if not Game.v2.codex.has(id):
			Game.v2.codex[id] = "seen"
	await Cine.reveal(w, DuelCards.card_list("dask_hounds").slice(0, 12), "DASK'S DECK", "thirty cards of hounds, traps and poison, yours by the Covenant")
	Cine.shot(w, w.player.global_position + Vector3(-1.4, 1.6, -1.8), Cine.head(w, "dask"), 34.0)
	var k := await Cine.choose(w, ["Keep your hound.", "Go home, Dask."])
	var dpos := Cine.body(w, "dask").global_position
	if k == 0:
		# you take his Shieldhound's card out of the deck and hold it out
		Game.set_flag("dask_kept_hound")
		Game.v2.collection["shieldhound"] = maxi(0, int(Game.v2.collection.get("shieldhound", 0)) - 1)
		var card := InnRooms.blank_card(null)
		(card.material_override as StandardMaterial3D).albedo_color = Color(0.62, 0.5, 0.3)
		(card.material_override as StandardMaterial3D).emission_energy_multiplier = 0.0
		var pf = Cine.fig(w, "player")
		if pf is Figure3D:
			(pf as Figure3D).hand_light(card)
			card.position = Vector3(0.0, 0.06, 0.04)
			(pf as Figure3D).pose("play_card", 0.42, 0.4)
		Cine.shot(w, (w.player.global_position + dpos) * 0.5 + (dpos - w.player.global_position).normalized().cross(Vector3.UP) * 2.2 + Vector3(0, 1.4, 0), (w.player.global_position + dpos) * 0.5 + Vector3(0, 1.15, 0), 36.0)
		await Cine.wait(w, 1.0)
		# he stares at it; he doesn't take it straight away
		_front_shot(w, "dask", w.player.global_position, 34.0)
		await Cine.wait(w, 1.8)
		await Cine.say(w, "dask", "...Why?")
		await Cine.wait(w, 0.6)
		# he takes it (between the shots: it's in his hand as the wide one
		# opens), and backs into the trees without another word
		Cine.shot(w, r + Vector3(-1.2, 1.6, -4.0), dask_at + Vector3(2.0, 1.2, 2.0), 38.0)
		if pf is Figure3D:
			(pf as Figure3D).hand_light(null)
			(pf as Figure3D).release(0.4)
		if is_instance_valid(card):
			var df = Cine.fig(w, "dask")
			if df is Figure3D:
				(df as Figure3D).hand_light(card)
				card.position = Vector3(0.0, 0.06, 0.04)
			else:
				var db := Cine.body(w, "dask")
				if card.get_parent() != null:
					card.get_parent().remove_child(card)
				db.add_child(card)
				var to_p := w.player.global_position - db.global_position
				to_p.y = 0.0
				card.position = to_p.normalized() * 0.3 + Vector3(0, 0.95, 0)
				card.rotation = Vector3(-0.4, atan2(to_p.x, to_p.z), 0)
		Cine.path(w, "dhound", [dpos + Vector3(1.2, 0, 0.4), r + Vector3(6.0, 0, 7.0)], 1.4)
		await Cine.path(w, "dask", [dpos + Vector3(0.0, 0, 0.8), r + Vector3(5.0, 0, 6.0)], 0.9)
	else:
		_front_shot(w, "dask", w.player.global_position, 34.0)
		await Cine.say(w, "dask", "Home.", 1.4)
		await Cine.wait(w, 0.9)   # it isn't a laugh
		await Cine.say(w, "dask", "Right.", 1.4)
		Game.set_flag("dask_sent_home")
		# he goes into the trees
		Cine.shot(w, r + Vector3(-1.2, 1.6, -4.0), dask_at + Vector3(2.0, 1.2, 2.0), 38.0)
		Cine.path(w, "dhound", [r + Vector3(6.0, 0, 7.0), r + Vector3(14.0, 0, 9.0)], 3.0)
		await Cine.path(w, "dask", [r + Vector3(5.0, 0, 6.0), r + Vector3(12.0, 0, 8.0)], 1.6)
	# Bram, to himself, looking after him: seen from the way Dask went, so
	# Dask and his hound are gone behind the camera as it cuts, not vanishing
	# in front of us (from over your shoulder, they were still in the shot)
	Cine.look(w, "bram", r + Vector3(12, 0, 8))
	_front_shot(w, "bram", r + Vector3(12, 0, 8), 30.0)
	Cine.despawn(w, "dask")
	Cine.despawn(w, "dhound")
	if is_instance_valid(box):
		box.queue_free()
	await Cine.say(w, "bram", "Morne.", 2.0)
	await Cine.wait(w, 1.0)
	# he keeps watch till dawn, and doesn't wake you for your turn
	await Cine.fade(w, 1.0, 1.2)
	var pf2 = Cine.fig(w, "player")
	Cine.place(w, "player", r + Vector3(-2.2, 0, -2.4), r + Vector3(-2.2, 0, 0))
	if pf2 is Figure3D:
		(pf2 as Figure3D).lie_down(0.01, true)
	Cine.place(w, "bram", r + Vector3(-0.6, 0, -1.2), r + Vector3(2.0, 0, 6.0))
	var watch := Cine.light(w, r + Vector3(-1.4, 0.4, -1.8), Color(1.0, 0.55, 0.25), 1.2, 6.0)
	Cine.shot(w, r + Vector3(-4.6, 1.3, -4.8), r + Vector3(-1.2, 0.8, -1.4), 38.0)
	await Cine.fade(w, 0.0, 1.2)
	await Cine.wait(w, 3.0)
	await Cine.fade(w, 1.0, 1.6)
	watch.queue_free()
	if pf2 is Figure3D:
		(pf2 as Figure3D).get_up(0.01)


## A three-quarter shot of someone's face as they look toward a point (for a
## cut-out that has moved off its mark: the fixed cameras would see its back).
static func _front_shot(w: World, who: String, toward: Vector3, fov: float) -> void:
	var p: Vector3 = Cine.body(w, who).global_position
	var f := toward - p
	f.y = 0.0
	f = f.normalized()
	var s := f.cross(Vector3.UP)
	Cine.shot(w, p + f * 2.5 - s * 1.5 + Vector3(0, 1.5, 0), p + Vector3(0, 1.2, 0), fov)


## The second night up to the oath: the fireflies go out, Dask steps out of
## the trees, the wager is sworn.
static func _road_meeting(w: World, r: Vector3, dask_at: Vector3, dask_cam: Vector3, mid: Vector3) -> void:
	var v := village(w)
	v.fireflies.amount_ratio = 1.0
	await Cine.caption(w, "The second night")
	Cine.shot(w, r + Vector3(1.8, 1.4, 4.0), r + Vector3(0, 1.4, -8.0), 40.0)
	Cine.fade(w, 0.0, 1.6)
	Cine.walk(w, "bram", r + Vector3(0.3, 0, -1.0), 1.2)
	await Cine.walk(w, "player", r + Vector3(-0.5, 0, -2.4), 1.2)
	# the fireflies go out, all at once
	Music.stop(1.0)
	Cine.shot(w, r + Vector3(-1.0, 1.7, -5.0), r + Vector3(0.6, 1.6, 4.0), 38.0)
	await Cine.wait(w, 1.2)
	v.fireflies.amount_ratio = 0.0
	v.fireflies.restart()
	await Cine.wait(w, 1.8)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", 1.0, 30.0)
	await Cine.say(w, "bram", "Stay close.", 1.6)
	# a wiry figure steps out of the trees, a Shieldhound clanking at his heel
	Cine.spawn(w, "dask", "hunter", r + Vector3(3.6, 0, 4.2), "Dask")
	Cine.beast(w, "dhound", "shieldhound", r + Vector3(4.6, 0, 5.4), Color(1.0, 0.8, 0.35, 1.0))
	Cine.shot(w, r + Vector3(-1.4, 1.4, -2.6), dask_at + Vector3(0, 1.3, 0), 36.0)
	Cine.path(w, "dhound", [dask_at + Vector3(1.0, 0, 0.6)], 1.4)
	await Cine.walk(w, "dask", dask_at, 1.3)
	Cine.look(w, "dask", w.player.global_position)
	Cine.look(w, "bram", dask_at)
	Cine.look(w, "player", dask_at)
	Music.play(["dask"], 1.0, true)
	Cine.shot(w, dask_cam, dask_at + Vector3(0.3, 1.25, 0), 34.0)
	_tremble(w, "dask", 2.4, 0.01)   # his hands aren't steady
	await Cine.say(w, "dask", "That's far enough. The card. The blank one.")
	# Bram, from beside Dask (a cut-out can't be looked past)
	var to_b: Vector3 = Cine.body(w, "bram").global_position - dask_at
	to_b.y = 0.0
	to_b = to_b.normalized()
	var bram_cam := dask_at + to_b * 1.2 + to_b.cross(Vector3.UP) * 1.1 + Vector3(0, 1.6, 0)
	Cine.shot(w, bram_cam, Cine.head(w, "bram") + Vector3(0, -0.1, 0), 32.0)
	await Cine.say(w, "bram", "Covenant law, lad. Stake it in a sworn duel, or walk away.")
	Cine.shot(w, dask_cam, dask_at + Vector3(0.3, 1.25, 0), 34.0)
	await Cine.say(w, "dask", "I know the law.")
	await Cine.wait(w, 0.9)
	await Cine.say(w, "dask", "Fine. Sworn duel, Unsworn. Your card against my deck.")
	Cine.shot(w, bram_cam, Cine.head(w, "bram") + Vector3(0, -0.1, 0), 32.0)
	await Cine.say(w, "bram", "That's every card you own.")
	Cine.shot(w, dask_cam, dask_at + Vector3(0.3, 1.25, 0), 34.0)
	await Cine.say(w, "dask", "And that card's worth more than everything I own. Do the sums, old man.")
	# the oath: the air closes round the words like a lock, a ring of light
	await _oath(w, mid)
	await Cine.fade(w, 1.0, 0.5)


## The sworn oath: a ring of gold light round the two duellists, closing.
static func _oath(w: World, at: Vector3) -> void:
	var ring := _ring(w, at, 2.2)
	var m: StandardMaterial3D = ring.material_override
	var l: OmniLight3D = ring.get_child(0)
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


## A ring of gold light on the ground round `at` (scale 1 = 3.7 m across).
static func _ring(w: World, at: Vector3, sc: float) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 3.6
	tm.outer_radius = 3.75
	tm.rings = 48
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.82, 0.4) * 3.0
	m.albedo_color.a = 1.0
	ring.material_override = m
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(ring)
	ring.global_position = at + Vector3(0, 0.08, 0)
	ring.scale = Vector3.ONE * sc
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.4)
	l.light_energy = 3.0
	l.omni_range = 10.0
	l.position = Vector3(0, 1.5, 0)
	ring.add_child(l)
	return ring


## Dask's deck box, set down at the player's feet.
static func _deck_box(w: World, at: Vector3) -> Node3D:
	var v := village(w)
	var n := Node3D.new()
	w.add_child(n)
	at.y = v.height(at.x, at.z)
	n.global_position = at
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.16, 0.12, 0.1)
	leather.roughness = 0.6
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.7, 0.55, 0.25)
	brass.metallic = 0.8
	brass.roughness = 0.35
	v.box(n, Vector3(0.12, 0.08, 0.16), Vector3(0, 0.04, 0), leather)
	v.box(n, Vector3(0.125, 0.012, 0.03), Vector3(0, 0.07, 0.03), brass)
	n.scale = Vector3.ONE * 1.6
	n.rotation.y = randf() * TAU
	return n


## A cut-out crouching to set something down (down, or back up); a 3D one
## bends to it.
static func _kneel_cutout(w: World, who: String, down: bool) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		if down:
			(f as Figure3D).pose("sit", 0.25, 0.4)
		else:
			(f as Figure3D).release(0.4)
	elif f != null:
		var n: Node3D = f
		w.create_tween().tween_property(n, "position:y", -0.35 if down else 0.0, 0.35)


## Someone shaking: the whole figure trembles, very slightly, for `secs`.
static func _tremble(w: World, who: String, secs: float, amp := 0.015) -> void:
	var f = Cine.fig(w, who)
	if f == null or not (f is Node3D):
		return
	var n: Node3D = f
	var base := n.rotation
	var t := 0.0
	while t < secs and is_instance_valid(n):
		t += w.get_process_delta_time()
		n.rotation = base + Vector3(sin(t * 61.0) * amp * 0.6, 0.0, sin(t * 47.0 + 1.3) * amp)
		await w.get_tree().process_frame
	if is_instance_valid(n):
		n.rotation = base


# ------------------------------------------------------------ the ridge ---

## At dawn (v3, P5), white towers catch the first sun across the plains.
## Bram doesn't sound pleased.
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
	await Cine.say(w, "bram", "There she is. Solhaven.")
	# he doesn't sound pleased
	var bh := Cine.head(w, "bram")
	Cine.shot(w, bh + Vector3(1.1, -0.05, 1.3), bh + Vector3(0, -0.08, 0), 28.0)
	await Cine.wait(w, 2.2)
	await Cine.fade(w, 1.0, 1.8)
	await Cine.caption(w, "Chapter 1", "The Sun's Court", 2.4)
