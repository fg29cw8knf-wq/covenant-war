class_name AshfordLife
extends RefCounted
## Life on Ashford's green while the player has the run of it (1 November,
## Gary: "Corin and the kids around him just standing there solid, can we
## have them moving around so they look real, same for any other character
## that is just standing there"). Everyone who isn't in a scene does small
## things now and then, each in their own way and their own time:
##
##   Corin      holds court: turns from one child to another and talks with
##              his hands, shows off (a cheer, a fighting stance), shifts
##              his feet, eyes the player as they pass
##   the kids   dart about round Corin (wherever he is: by the drum in the
##              morning, the carts in the afternoon; round the Lantern in the
##              evening when he's gone), jump and cheer, and watch him
##   his mam    in the bakery door, keeps an eye on him, waves now and then
##   Hob, Ned   look about them, and talk to whoever's passing
##
## Nobody moves while a scene has the camera, while the player is talking to
## them, while they sit, carry, or play a pose, or once midnight's begun.
## Each one's standing clip is started at its own moment, so nobody breathes
## in step with anybody else. Started from AshfordDay.watch, and (2 November)
## from the opening as the player steps out of the inn (AshfordP1._street).

const KIDS := ["p1_kid_a", "p1_kid_b", "p1_kid_c"]
const ADULTS := ["corin_mam", "hob", "ned"]
## How far the children range round whoever they're with (m).
const KID_NEAR := 1.3
const KID_FAR := 2.6
## How often the loop looks round (s).
const TICK := 0.3


static func start(w: World) -> void:
	if w == null or w.has_meta("life_on"):
		return
	w.set_meta("life_on", true)
	_desync(w)
	_warm_duels()
	await _run(w)
	if is_instance_valid(w):
		w.remove_meta("life_on")


static func _ids() -> Array:
	return ["corin"] + KIDS + ADULTS


## The village's duels made ready while the player walks about (1 November,
## Gary: "everything is taking a long time to load"): the Totems of every
## deck played in Ashford (the player's, Corin's, Tam's, Nell's, Tilly's
## moth) read from disk in the background and kept, so a duel's Circle
## finds them loaded instead of reading each from disk as it's called. Only
## where there are threads to do it on (the phone link has none: there a
## request would load on the spot and stall the walk).
static var _kept: Array = []


static func _warm_duels() -> void:
	if OS.has_feature("web") or not _kept.is_empty():
		return
	var area = load("res://scripts/world/areas/ashford.gd")
	var ids := {}
	for deck in [area.PLAYER_DECK, area.CORIN_DECK, area.TAM_DECK, area.NELL_DECK, ["lantern_moth"]]:
		for id in deck:
			if String(DuelCards.CARDS.get(String(id), {}).get("kind", "")) in ["totem", "summon"]:
				ids[String(id)] = true
	var paths: Array = []
	for id in ids:
		var p := DuelField3D.model_path(String(id))
		if p != "" and not paths.has(p):
			paths.append(p)
	for p in paths:
		if ResourceLoader.load_threaded_request(p) == OK:
			_kept.append(p)
	_hold_kept.call_deferred()


## Once each has loaded, keep a reference so it stays in the cache.
static var _held: Array = []


static func _hold_kept() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for p in _kept:
		while ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await tree.create_timer(0.25, false).timeout
		if ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_LOADED:
			_held.append(ResourceLoader.load_threaded_get(p))


## Every standing figure's clip at its own moment, so their breathing and
## swaying aren't in step.
static func _desync(w: World) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for id in _ids() + ["tilly", "bram"] + AshfordP1.DANCERS.map(func(d): return String(d[0])):
		var f = Cine.fig(w, String(id))
		if f is Figure3D and (f as Figure3D).anim != null:
			var a := (f as Figure3D).anim
			if a.current_animation != "" and a.current_animation_length > 0.1:
				a.seek(rng.randf() * a.current_animation_length, true)


## May `id` do something now?
static func _free(w: World, id: String) -> bool:
	if w.cine or w.busy or w.hud == null or w.hud.menu_open():
		return false
	var b := Cine.body(w, id)
	var f = Cine.fig(w, id)
	if b == null or f == null or b.has_meta("life_busy"):
		return false
	if AshfordDay.at_mill(b.global_position):
		return false
	if w._talk_target != null and w._npc_by_id(id) == w._talk_target:
		return false
	if f is Figure3D:
		var fg := f as Figure3D
		if fg.seat >= 0.0 or fg._action != "" or fg.walking or fg.holding() != null or fg.reaching():
			return false
	return true


static func _run(w: World) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var next := {}
	for id in _ids():
		next[id] = rng.randf_range(0.5, 4.0)
	var t := 0.0
	while is_instance_valid(w) and w.is_inside_tree() and w.has_meta("life_on"):
		await w.get_tree().create_timer(TICK, false).timeout
		if not is_instance_valid(w) or Game.flag("ash_lantern_duel"):
			return
		t += TICK
		# (2 November, Gary: Corin and the children "still aren't moving when
		# you leave the inn": life waited for the opening to end; now it runs
		# from the moment the player steps out of the inn's door, the
		# opening's "street" and "green" parts included)
		if not Game.flag("ash_started") and not String(Game.flag("p1_stage", "")) in ["street", "green"]:
			continue
		for id in _ids():
			if t < float(next[id]):
				continue
			if not _free(w, id):
				next[id] = t + 0.8
				continue
			next[id] = t + _act(w, id, rng)


## One thing for `id` to do; how long until they next do something (s).
static func _act(w: World, id: String, rng: RandomNumberGenerator) -> float:
	if id == "corin":
		return _corin(w, rng)
	if KIDS.has(id):
		return _kid(w, id, rng)
	return _adult(w, id, rng)


static func _player_near(w: World, b: Node3D, r: float) -> bool:
	var p := w.player.global_position
	return Vector2(p.x - b.global_position.x, p.z - b.global_position.z).length() < r


## Corin with the children round him.
static func _corin(w: World, rng: RandomNumberGenerator) -> float:
	var b := Cine.body(w, "corin")
	var f = Cine.fig(w, "corin")
	if _player_near(w, b, 7.0) and rng.randf() < 0.35:
		Cine.look(w, "corin", w.player.global_position)
		return rng.randf_range(2.5, 4.0)
	var kids := _kids_near(w, b.global_position, 5.0)
	var r := rng.randf()
	if r < 0.5 and not kids.is_empty():
		# turns to one of them and holds forth, hands going
		var k: Node3D = kids[rng.randi_range(0, kids.size() - 1)]
		Cine.look(w, "corin", k.global_position)
		if f is Figure3D:
			_talk_for(w, f as Figure3D, rng.randf_range(2.2, 3.8))
		return rng.randf_range(4.0, 6.0)
	if r < 0.68 and f is Figure3D:
		# showing off
		var show: String = ["cheer", "fight_stance", "cheer"][rng.randi_range(0, 2)]
		(f as Figure3D).act(show, 1.0, 0.25)
		return rng.randf_range(5.0, 7.5)
	# shifts his ground a step or two, round where he's been all along
	var home: Vector3 = b.get_meta("life_home", b.global_position)
	b.set_meta("life_home", home)
	var to := home + Vector3(rng.randf_range(-0.6, 0.6), 0.0, rng.randf_range(-0.6, 0.6))
	_walk(w, "corin", to, 1.0)
	return rng.randf_range(4.0, 6.0)


## A child darting about, jumping, cheering, watching.
static func _kid(w: World, id: String, rng: RandomNumberGenerator) -> float:
	var b := Cine.body(w, id)
	var anchor := _kid_anchor(w, id)
	var r := rng.randf()
	var cb := Cine.body(w, "corin")
	var watch_at: Vector3 = cb.global_position if cb != null and not AshfordDay.at_mill(cb.global_position) else anchor
	if r < 0.45:
		# off to another spot round whoever they're with, at a run
		var to := anchor
		for tries in 6:
			var a := rng.randf_range(0.0, TAU)
			var d := rng.randf_range(KID_NEAR, KID_FAR)
			to = anchor + Vector3(cos(a) * d, 0.0, sin(a) * d)
			if Vector2(to.x, to.z).length() > 2.6:   # (clear of the Lantern's foot)
				break
		_walk(w, id, to, rng.randf_range(2.6, 3.4), "run", watch_at)
		return rng.randf_range(2.5, 4.5)
	if r < 0.65:
		Cine.look(w, id, watch_at)
		Cine.hop(w, id, 0.2)
		return rng.randf_range(2.0, 3.5)
	if r < 0.8:
		Cine.look(w, id, watch_at)
		Cine.act(w, id, "cheer")
		return rng.randf_range(3.0, 4.5)
	Cine.look(w, id, w.player.global_position if _player_near(w, b, 6.0) else watch_at)
	return rng.randf_range(1.5, 3.0)


## Where a child keeps to: round Corin while he's on the green (by the drum,
## then the carts), else their own spot.
static func _kid_anchor(w: World, id: String) -> Vector3:
	var cb := Cine.body(w, "corin")
	if cb != null and not AshfordDay.at_mill(cb.global_position):
		return cb.global_position
	for k in AshfordP1.KIDS:
		if String(k[0]) == id:
			return k[2]
	return Vector3.ZERO


static func _kids_near(w: World, at: Vector3, r: float) -> Array:
	var out: Array = []
	for id in KIDS:
		var b := Cine.body(w, id)
		if b != null and b.global_position.distance_to(at) < r:
			out.append(b)
	return out


## Corin's mam, Hob, Ned: a look about them, a word to whoever's passing,
## and (his mam) a wave to her boy.
static func _adult(w: World, id: String, rng: RandomNumberGenerator) -> float:
	var b := Cine.body(w, id)
	var f = Cine.fig(w, id)
	var home: Vector3 = b.get_meta("life_home", b.global_position)
	b.set_meta("life_home", home)
	if not b.has_meta("life_facing") and f is Figure3D:
		b.set_meta("life_facing", (f as Figure3D).facing())
	var facing: Vector3 = b.get_meta("life_facing", Vector3.FORWARD)
	var r := rng.randf()
	if _player_near(w, b, 4.5) and r < 0.5:
		Cine.look(w, id, w.player.global_position)
		if f is Figure3D and rng.randf() < 0.5:
			_talk_for(w, f as Figure3D, rng.randf_range(1.5, 2.5))
		return rng.randf_range(3.0, 5.0)
	if id == "corin_mam":
		var cb := Cine.body(w, "corin")
		if cb != null and not AshfordDay.at_mill(cb.global_position) and r < 0.55:
			Cine.look(w, id, cb.global_position)
			if f is Figure3D and rng.randf() < 0.3:
				(f as Figure3D).act("wave", 1.0, 0.3)
			return rng.randf_range(5.0, 8.0)
	if r < 0.75:
		# a look about, round the way they face
		var a := rng.randf_range(-0.7, 0.7)
		Cine.look(w, id, b.global_position + facing.rotated(Vector3.UP, a) * 3.0)
		return rng.randf_range(4.0, 7.0)
	if f is Figure3D:
		Cine.look(w, id, b.global_position + facing * 3.0)
		_talk_for(w, f as Figure3D, rng.randf_range(1.2, 2.2))
	return rng.randf_range(6.0, 9.0)


## Talking with their hands for a while (the talk clip), then still again.
static func _talk_for(w: World, f: Figure3D, secs: float) -> void:
	f.talking = true
	await w.get_tree().create_timer(secs, false).timeout
	if is_instance_valid(f):
		f.talking = false


## A walk (or a run) somewhere, marked busy until it's done, then a look
## at `then_look` if there is one.
static func _walk(w: World, id: String, to: Vector3, speed: float, gait := "walk", then_look = null) -> void:
	var b := Cine.body(w, id)
	if b == null:
		return
	to.y = Cine.ground(w, to)
	b.set_meta("life_busy", true)
	await Cine.path(w, id, [to], speed, gait)
	if is_instance_valid(b):
		b.remove_meta("life_busy")
		if then_look != null and is_instance_valid(w):
			Cine.look(w, id, then_look)
