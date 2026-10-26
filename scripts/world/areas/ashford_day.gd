class_name AshfordDay
extends RefCounted
## Prologue P1 from the Lantern Duel to midnight, as Master Script v7 has it
## (docs/script/v7_prologue.md): the afternoon's jobs (Tam at his watermill
## down the lane, Tilly by the well, Nell on her bench, and the two friendly
## games), the sun going down, and the festival evening (Tilly's thanks,
## Tam's bread, Nell's dance, Corin on the mill-race wall, Bram by the Great
## Lantern). The words are in ashford.gd; this file moves people, the light
## and the camera, and watches where the player walks.
##
## The time of day is kept in flags: "ash_won_lantern" (the afternoon has
## begun), "ash_jobs" (Tam, Tilly and Nell all seen: the sun's going down),
## "ash_evening" (the festival evening), "ash_lantern_duel" (midnight has
## begun; the old name, kept so saves and the Ledger still read it).

## The mouth of the lane down to Tam's mill: the track north-east off the
## ring road, between the cottages (AshfordVillage.build_paths). Walking into
## it takes the player down to the mill (MillSet).
const LANE := Vector3(7.6, 0, -17.9)
const LANE_R := 1.9
## Where they come back out onto the green, a few steps back up the track.
const LANE_BACK := Vector3(6.4, 0, -15.6)
## Where people stand, by the time of day (the rest stay put all day).
const CORIN_MORNING := Vector3(-8.6, 0, -2.4)
## "Over by the merchant carts": by the blue stall and its stacked crates.
const CORIN_CARTS := Vector3(-6.9, 0, -7.4)
const TILLY_MORNING := Vector3(5.2, 0, 8.4)
## "Near the well, Tilly is staring sadly at a flat, grey card."
const TILLY_WELL := Vector3(-7.4, 0, 6.1)
const TILLY_EVENING := Vector3(3.1, 0, 7.6)
## Tam behind the bread stall (the blue one) in the evening.
const TAM_BREAD := Vector3(-3.4, 0, -7.0)
## How long the light takes to go (s): the sun goes down when the player
## finds Bram after the afternoon's jobs (his talk: "sunset"), so there's
## time first for another friendly game.
const SUNSET_SECS := 7.5
## The Objective lines (v7).
const FESTIVAL := "Explore Ashford and help prepare for the festival.\nOptional: challenge villagers to friendly card duels."
const SUN_GOING := "The sun's going down. Find Bram at the Great Lantern."
const EVENING := "Enjoy the festival. Meet Bram at the Great Lantern before midnight."


static func village(w: World) -> AshfordVillage:
	return w.get_meta("village") as AshfordVillage


static func coach(w: World) -> WorldCoach:
	return WorldCoach.of(w.hud)


## "morning" (to the Lantern Duel), "afternoon" or "evening".
static func phase() -> String:
	if not Game.flag("ash_won_lantern"):
		return "morning"
	if not Game.flag("ash_evening"):
		return "afternoon"
	return "evening"


## Tam, Tilly and Nell all seen (the afternoon's three jobs).
static func jobs_done() -> bool:
	return Game.flag("ash_tam") and Game.flag("ash_tilly") and Game.flag("ash_nell")


## Where someone stands at this time of day (npcs() and stage()).
static func spot(id: String) -> Vector3:
	var ph := phase()
	match id:
		"bram":
			return AshfordP1.STOOL + Vector3(0, 0, 0.16)
		"tam":
			return TAM_BREAD if ph == "evening" else MillSet.spot(MillSet.TAM)
		"corin":
			match ph:
				"morning":
					return CORIN_MORNING
				"afternoon":
					return CORIN_CARTS
			return MillSet.spot(MillSet.CORIN)
		"tilly":
			match ph:
				"morning":
					return TILLY_MORNING
				"afternoon":
					return TILLY_WELL
			return TILLY_EVENING
		"ned":
			return Vector3(-1.6, 0, -6.4)
		"hob":
			return Vector3(10.8, 0, 1.6)
		"nell":
			return AshfordP1.BENCH
	return Vector3.ZERO


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Is someone down at the mill (its set stands far out past the village)?
static func at_mill(p: Vector3) -> bool:
	return p.x > MillSet.AT.x - 200.0


# ============================================================ the light ===

## Everyone and the light as this time of day has them (on arrival, after a
## game is loaded part-way through the day; again is harmless).
static func stage(w: World) -> void:
	var v := village(w)
	if v == null or Game.flag("ash_lantern_duel"):
		return
	var ph := phase()
	v.set_daylight(0.0 if ph == "evening" else 1.0)
	if not Game.flag("ash_started"):
		return
	for id in ["corin", "tilly", "tam"]:
		_to_spot(w, id)
	if ph == "evening":
		_sit_corin(w)
		if Game.flag("tam_dances"):
			_dancing(w)
	lane_sign(w)
	if ph == "afternoon":
		_set_objective(w, SUN_GOING if jobs_done() else FESTIVAL)
	elif ph == "evening":
		_set_objective(w, EVENING)


static func _set_objective(w: World, text: String) -> void:
	coach(w).objective("")
	Game.set_flag("objective", text)
	w.hud.set_objective(text)


## Someone straight to their spot for now: on the green's own ground, or on
## the mill set's floor.
static func _to_spot(w: World, id: String) -> void:
	var b := Cine.body(w, id)
	if b == null:
		return
	var at := spot(id)
	if at_mill(at):
		Cine.place(w, id, at, MillSet.spot(MillSet.ARRIVE))
	else:
		AshfordP1.put(w, id, at, Vector3.ZERO)


## The signpost at the lane's mouth, glowing while there's someone to see
## down there (Tam, until he's been seen; Corin, in the evening).
static func lane_sign(w: World) -> void:
	var v := village(w)
	var sign: Node3D = AshfordP1.meta(v, "lane_sign")
	if sign == null:
		sign = Node3D.new()
		sign.name = "MillLaneSign"
		v.get_meta("p1_root").add_child(sign)
		var at := LANE + Vector3(1.4, 0, 0.6)
		at.y = v.height(at.x, at.z)
		sign.position = at
		sign.rotation.y = -0.55
		v.box(sign, Vector3(0.1, 1.5, 0.1), Vector3(0, 0.75, 0), v.mats.beam_v)
		v.box(sign, Vector3(0.75, 0.22, 0.04), Vector3(-0.3, 1.32, 0.05), v.mats.wood_h, Vector3(0, 0, 0.06))
		var label := Label3D.new()
		label.text = "MILL"
		label.font_size = 40
		label.pixel_size = 0.004
		label.modulate = Color(0.16, 0.11, 0.07)
		label.outline_size = 0
		label.position = Vector3(-0.32, 1.32, 0.075)
		sign.add_child(label)
		v.set_meta("lane_sign", sign)
	var want: bool = (phase() == "afternoon" and not Game.flag("ash_tam")) or (phase() == "evening" and not Game.flag("corin_pond"))
	var glow: Node3D = AshfordP1.meta(v, "lane_glow")
	if want and glow == null:
		var mark := Node3D.new()
		mark.name = "LaneMark"
		v.get_meta("p1_root").add_child(mark)
		var g := LANE
		g.y = v.height(g.x, g.z) + 0.15
		mark.position = g
		v.set_meta("lane_glow", AshfordP1.light_up(v, mark, Vector3.ZERO, 0.9))
		v.set_meta("lane_mark", mark)
	elif not want and glow != null:
		if is_instance_valid(glow):
			glow.queue_free()
		var mk = AshfordP1.meta(v, "lane_mark")
		if mk != null and is_instance_valid(mk):
			(mk as Node).queue_free()
		v.remove_meta("lane_glow")
		v.remove_meta("lane_mark")


# ============================================================= watching ===

## While the player is free in Ashford before midnight: Corin calls them over
## the moment the crate's down; the lane takes them down to the mill; once
## the afternoon's jobs are done the sun goes down when they come back to the
## Lantern; and in the evening Tilly comes running with her card. Started on
## every arrival in Ashford before midnight.
static func watch(w: World) -> void:
	if w.has_meta("day_watch"):
		return
	w.set_meta("day_watch", true)
	while is_instance_valid(w) and w.is_inside_tree():
		await w.get_tree().create_timer(0.15, false).timeout
		if not is_instance_valid(w) or not w.is_inside_tree() or Game.flag("ash_lantern_duel"):
			break
		if not Game.flag("ash_started") or w.hud == null:
			continue
		if w.busy or w.cine or w.hud.menu_open() or w._talk_target != null:
			continue
		var p := w.player.global_position
		var ph := phase()
		if ph == "morning":
			if not Game.flag("corin_met") and w._npc_by_id("corin") != null:
				w._talk(w._npc_by_id("corin"))
			continue
		if _flat(p, LANE) < LANE_R:
			await to_mill(w)
			continue
		if ph == "afternoon":
			# the jobs done: the sun goes down when they find Bram (his talk)
			if jobs_done() and String(Game.flag("objective", "")) != SUN_GOING:
				_set_objective(w, SUN_GOING)
			continue
		# the evening: Tilly runs up with her card the first time they're near
		if not Game.flag("tilly_thanks"):
			var tb := Cine.body(w, "tilly")
			var near_other: bool = w._near != null and String(w._near.def.id) != "tilly"
			if tb != null and not near_other and _flat(p, tb.global_position) < 5.5:
				w._talk(w._npc_by_id("tilly"))
	if is_instance_valid(w):
		w.remove_meta("day_watch")


# ======================================================== after the duel ===

## The cheer from the green (the children's: it's the winner they cheer);
## Corin can't believe it, then takes it badly (25 October, Gary: he was
## cheering his own loss; now a jolt of surprise, then his defeat pose, held
## while he yields, and off it comes as he walks away).
static func after_lantern(w: World) -> void:
	w.cine = true
	for k in AshfordP1.KIDS:
		Cine.hop(w, String(k[0]), 0.2)
	AshfordP1.two_shot(w, "player", "corin", 3.4, 1.5, 36.0)
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D:
		(cf as Figure3D).act("hit_react", 1.0, 0.15)
		await Cine.wait(w, 0.9)
		(cf as Figure3D).hold("defeat", 1.0, 0.3)
		await Cine.wait(w, 0.6)
	else:
		await Cine.wait(w, 1.2)
	Cine.look(w, "corin", w.player.global_position)


## Corin wades off into the crowd towards the merchant carts, still
## complaining about losing (Gary's direction, 24 October).
static func corin_off(w: World) -> void:
	var v := village(w)
	var to := CORIN_CARTS
	to.y = v.height(to.x, to.z)
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D:
		(cf as Figure3D).release(0.3)   # (the defeat pose, off as he goes)
	Cine.path(w, "corin", AshfordP1.round_lantern(w, Cine.body(w, "corin").global_position, to), 1.6)
	await Cine.wait(w, 0.9)
	w.hud.dialogue.bark(w._speaker("corin"), w._portrait("corin"), "It was the wind! Everyone saw the wind!")
	await Cine.wait(w, 1.4)


## Bram turns to the player, looking rather pleased.
static func bram_pleased(w: World) -> void:
	Cine.look(w, "bram", w.player.global_position)
	Cine.look(w, "player", Cine.body(w, "bram").global_position)
	AshfordP1.two_shot(w, "player", "bram", 3.2, 1.45, 34.0)
	await Cine.wait(w, 0.5)


## (He gives you a knowing smile.)
static func bram_smile(w: World) -> void:
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).act("talk", 0.8)
	await Cine.wait(w, 0.7)


## The afternoon begins: everyone answers, Bram goes back to his stool,
## Tilly goes and sits by the well with her grey card, the lane's sign
## lights, and the player has the village.
static func afternoon(w: World) -> void:
	var v := village(w)
	Game.save_game()
	AshfordP1.mute_all_but(w, [])
	AshfordP1.bram_to_stool(w)
	var tb := Cine.body(w, "tilly")
	if tb != null and _flat(tb.global_position, TILLY_WELL) > 0.5:
		var to := TILLY_WELL
		to.y = v.height(to.x, to.z)
		Cine.path(w, "tilly", AshfordP1.round_lantern(w, tb.global_position, to), 1.1)
	lane_sign(w)
	_set_objective(w, FESTIVAL)
	await AshfordP1.home(w, 0.9)
	AshfordP1.controls_on(w)
	w.busy = false
	watch(w)


# ============================================================== the mill ===

## Down the lane to the mill: Tam by the wheel in the afternoon (his letter,
## his friendly game), Corin on the race wall in the evening. The player
## walks up to them, they talk, and it's back up the lane to the green.
static func to_mill(w: World) -> void:
	var v := village(w)
	var m := MillSet.build(v)
	var evening := phase() == "evening"
	var who := "corin" if evening else "tam"
	if Cine.body(w, who) == null:
		return
	w.busy = true
	w.cine = true
	w._move_target = null
	w._talk_target = null
	w.hud.set_controls_visible(false)
	coach(w).light("")
	await Cine.fade(w, 1.0, 0.6)
	MillSet.enter(w)
	MillSet.lamps(v, evening)
	var arrive: Vector3 = m.arrive
	_to_spot(w, who)
	if evening:
		_sit_corin(w)
	var them: Vector3 = Cine.body(w, who).global_position
	Cine.place(w, "player", arrive, them)
	Cine.look(w, who, arrive)
	var root: Node3D = m.root
	var cam := root.to_global(Vector3(-11.5, 4.4, 24.0))
	Cine.shot(w, cam, arrive + Vector3(0, 1.0, 0), 48.0)
	await Cine.fade(w, 0.0, 0.8)
	# walk up to them
	AshfordP1.controls_on(w)
	if evening:
		_set_objective(w, "Find Corin by the mill race.")
	else:
		coach(w).objective("mill_tam")
	await AshfordP1.walk_room(w, m, cam, func(q: Vector3) -> bool: return _flat(q, them) < 1.75)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	coach(w).objective("")
	w.hud.set_objective("")
	w.hud.set_controls_visible(false)
	Cine.look(w, "player", them)
	Cine.look(w, who, w.player.global_position)
	if evening:
		_mill_two_shot(w, "corin")
	else:
		AshfordP1.two_shot(w, "player", who, 3.4, 1.45, 36.0)
	var n = w._npc_by_id(who)
	if n != null:
		n.doll.set_marker("")
		await w.run_steps(n.def.talk, n)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	w.hud.dialogue.close()
	# back up the lane
	await Cine.fade(w, 1.0, 0.7)
	MillSet.leave(w)
	if evening:
		var cf = Cine.fig(w, "corin")
		if cf is Figure3D:
			(cf as Figure3D).stand(0.0)
	back_on_green(w)
	stage(w)
	await Cine.fade(w, 0.0, 0.7)
	AshfordP1.controls_on(w)
	w.busy = false


## Corin on the race wall, his back to the water, facing the meadow.
static func _sit_corin(w: World) -> void:
	var cb := Cine.body(w, "corin")
	if cb == null or not at_mill(cb.global_position):
		return
	var seat := MillSet.spot(Vector3(1.0, 0, 7.0))
	AshfordP1.sit_down(w, "corin", seat, Vector3.LEFT, 0.5, 0.0)


## The two of them on the race wall's side of the meadow, from the south
## west (looking north east, away from the village's land).
static func _mill_two_shot(w: World, who: String) -> void:
	var a := w.player.global_position
	var b := Cine.body(w, who).global_position
	var mid := (a + b) * 0.5
	Cine.shot(w, mid + Vector3(-1.6, 1.3, 3.4), mid + Vector3(0.2, 1.0, 0), 36.0)


## The player back on the green at the top of the lane, the game's camera
## behind them again (behind the black).
static func back_on_green(w: World) -> void:
	AshfordP1.put(w, "player", LANE_BACK, Vector3.ZERO)
	var pf = w.player_doll
	if pf is Figure3D:
		(pf as Figure3D).release(0.0)
		(pf as Figure3D).let_go(0.0)
	w.cam.fov = World.CAM_FOV
	w.end_cine()
	w._focus = w._cam_focus_target()
	w._place_camera()


# =============================================================== sunset ===

## The sun drops behind the mill, the lanterns are lit one by one along the
## eaves and Ned's fiddle starts up properly: the green from the south as the
## light goes, and the evening's people go to their places behind it.
static func sunset(w: World) -> void:
	var v := village(w)
	await Cine.begin(w)
	coach(w).light("")
	w.hud.set_objective("")
	var top: Vector3 = v.great_lantern_top if v.great_lantern_top != Vector3.ZERO else Vector3(0, 8.0, 0)
	Cine.drift(w, Vector3(5.5, 2.4, 15.5), Vector3(3.6, 3.1, 13.2), top * 0.4, top * 0.55, SUNSET_SECS + 1.5, 50.0)
	var tw := w.create_tween()
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(v):
			v.set_daylight(k), 1.0, 0.0, SUNSET_SECS).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await Cine.wait(w, 1.0)
	await Cine.fade(w, 1.0, 0.6)
	Game.set_flag("ash_evening")
	Game.save_game()
	for id in ["tam", "corin", "tilly"]:
		_to_spot(w, id)
	if not w.get_meta("bram_seated", false):
		AshfordP1.bram_sit(w)
	lane_sign(w)
	AshfordP1.put(w, "player", Vector3(1.2, 0, 6.2), Vector3.ZERO)
	w.cam.fov = World.CAM_FOV
	_set_objective(w, EVENING)
	await Cine.overlay(w).bars(false)
	w.end_cine()
	w._focus = w._cam_focus_target()
	w._place_camera()
	await Cine.fade(w, 0.0, 0.8)
	AshfordP1.controls_on(w)
	w.busy = false


# ============================================================ the evening ===

## Tam breaks the first loaf off the stone and hands a piece over.
static func tam_bread(w: World) -> void:
	var tf = Cine.fig(w, "tam")
	var pf = w.player_doll
	AshfordP1.two_shot(w, "player", "tam", 3.0, 1.4, 34.0)
	if not (tf is Figure3D):
		await Cine.wait(w, 0.6)
		return
	var bread := Node3D.new()
	bread.name = "Bread"
	var crust := StandardMaterial3D.new()
	crust.albedo_color = Color(0.72, 0.48, 0.24)
	crust.roughness = 0.85
	var s := SphereMesh.new()
	s.radius = 0.07
	s.height = 0.09
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = crust
	bread.add_child(mi)
	bread.set_meta("p1_prop", true)
	(tf as Figure3D).hand_light(bread)
	(tf as Figure3D).pose("play_card", 0.45, 0.35)
	await Cine.wait(w, 0.8)
	if pf is Figure3D:
		var to := Node3D.new()
		w.add_child(to)
		to.global_position = bread.global_position
		(pf as Figure3D).reach(null, to, 0.35)
		await Cine.wait(w, 0.4)
		(tf as Figure3D).hand_light(null)
		(tf as Figure3D).release(0.3)
		if bread.get_parent() != null:
			bread.get_parent().remove_child(bread)
		(pf as Figure3D).hand_light(bread)
		(pf as Figure3D).let_go(0.3)
		to.queue_free()
	await Cine.wait(w, 0.4)


## "She said that?" He wipes his hands on his apron, twice, and goes to her:
## Tam and Nell dancing, badly, by the time the player looks round.
static func tam_to_nell(w: World) -> void:
	var v := village(w)
	var tf = Cine.fig(w, "tam")
	if tf is Figure3D:
		(tf as Figure3D).act("talk", 1.4)
	await Cine.wait(w, 0.9)
	var seat := AshfordP1.bench_seat(w)
	var to := seat + AshfordP1.bench_facing(w) * 0.9
	to.y = v.height(to.x, to.z)
	await Cine.path(w, "tam", AshfordP1.round_lantern(w, Cine.body(w, "tam").global_position, to), 1.5)
	Game.set_flag("tam_dances")
	_dancing(w)


## Tam and Nell on the dancing grass (she's up off her bench).
static func _dancing(w: World) -> void:
	var dance: Array = w.area.call("_dance_spot")
	var nf = Cine.fig(w, "nell")
	if nf is Figure3D:
		(nf as Figure3D).stand(0.0)
	AshfordP1.put(w, "tam", dance[0], dance[1])
	AshfordP1.put(w, "nell", dance[1], dance[0])
	for who in ["tam", "nell"]:
		var df = Cine.fig(w, who)
		if df is Figure3D:
			(df as Figure3D).hold("dance")


## Corin twists one of the iron-plated buttons off his new coat and holds it
## out; it passes into the player's hand.
const BUTTON_MODEL := "res://assets/models/ashford/corin_button.glb"


static func corin_button(w: World) -> void:
	var cf = Cine.fig(w, "corin")
	var pf = w.player_doll
	if cf is Figure3D:
		(cf as Figure3D).stand(0.4)
		await Cine.wait(w, 0.5)
	_mill_two_shot(w, "corin")
	if not (cf is Figure3D):
		await Cine.wait(w, 0.5)
		return
	var b := Node3D.new()
	b.name = "Button"
	if ResourceLoader.exists(BUTTON_MODEL):
		# Gary's button (26 October): iron-plated, a scrap of his coat's blue
		# wool on its back, 2.8 cm across, made lying flat
		var gm: Node3D = load(BUTTON_MODEL).instantiate()
		gm.rotation.x = PI * 0.5
		b.add_child(gm)
	else:
		var iron := StandardMaterial3D.new()
		iron.albedo_color = Color(0.42, 0.42, 0.44)
		iron.metallic = 0.85
		iron.roughness = 0.35
		var c := CylinderMesh.new()
		c.top_radius = 0.014
		c.bottom_radius = 0.014
		c.height = 0.006
		var mi := MeshInstance3D.new()
		mi.mesh = c
		mi.material_override = iron
		mi.rotation.x = PI * 0.5
		b.add_child(mi)
	b.set_meta("p1_prop", true)
	(cf as Figure3D).pose("play_card", 0.3, 0.3)
	await Cine.wait(w, 0.5)
	(cf as Figure3D).hand_light(b)
	(cf as Figure3D).pose("play_card", 0.5, 0.35)
	await Cine.wait(w, 0.7)
	if pf is Figure3D:
		var to := Node3D.new()
		w.add_child(to)
		to.global_position = b.global_position
		(pf as Figure3D).reach(null, to, 0.35)
		await Cine.wait(w, 0.45)
		(cf as Figure3D).hand_light(null)
		(cf as Figure3D).release(0.3)
		if b.get_parent() != null:
			b.get_parent().remove_child(b)
		(pf as Figure3D).hand_light(b)
		(pf as Figure3D).let_go(0.3)
		to.queue_free()
	Game.set_flag("corin_button")
	await Cine.wait(w, 0.3)


# ======================================================= Tilly's moth ===

## "The protagonist kneels and gently touches the edge of the card. Instantly,
## the grey crystal surface flares with warm amber light. A spectral Lantern
## Moth flutters up from the card, circling Tilly's head." Then it sinks back
## into her card (it goes grey again by evening).
static func moth_for_tilly(w: World) -> void:
	var v := village(w)
	var card: Node3D = AshfordP1.meta(w, "tilly_card_node")
	if card == null or not is_instance_valid(card):
		await AshfordP1.tilly_up(w)
		card = w.get_meta("tilly_card_node")
	await AshfordP1.use(w, card, "moth", 0.0, Vector3.INF, 0.32)
	w.busy = true
	w.cine = true
	var pf = w.player_doll
	var tb := Cine.body(w, "tilly")
	var p := w.player.global_position
	var to_t := tb.global_position - p
	to_t.y = 0.0
	to_t = to_t.normalized()
	var perp := to_t.cross(Vector3.UP).normalized()
	# down on one knee, a hand to the card's edge
	if pf is Figure3D:
		(pf as Figure3D).pose("lift", 0.42, 0.4)
		var touch := Node3D.new()
		w.add_child(touch)
		touch.global_position = card.global_position - to_t * 0.04
		(pf as Figure3D).reach(null, touch, 0.4)
		touch.set_meta("free_later", true)
		w.set_meta("moth_touch", touch)
	var look := tb.global_position + Vector3(0, 1.1, 0)
	Cine.move(w, AshfordP1.clear_cam(w, [p + to_t * 0.6 + perp * 3.6 + Vector3(0, 1.5, 0), p + to_t * 0.6 - perp * 3.6 + Vector3(0, 1.5, 0),
		p + to_t * 0.6 + perp * 3.0 + Vector3(0, 2.4, 0)], look, ["player", "tilly"]), look, 0.8, 38.0)
	await Cine.wait(w, 0.5)
	# the grey card flares amber
	var cg := card.get_node_or_null("CardGlow") as Node3D
	if cg != null:
		var gt := w.create_tween()
		gt.tween_property(cg, "scale", cg.scale * 2.4, 0.4).set_trans(Tween.TRANS_SINE)
	var cls = w.area.get_script_constant_map().get("LanternMothFlight")
	var moth: Node3D = cls.new()
	w.add_child(moth)
	var from := card.global_position
	moth.global_position = from
	moth.scale = Vector3.ONE * 0.05
	var grow := w.create_tween()
	grow.tween_property(moth, "scale", Vector3.ONE * 1.8, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.4)
		(pf as Figure3D).release(0.5)
	# twice round Tilly's head
	var head := Cine.head(w, "tilly") + Vector3(0, 0.12, 0)
	var r := 0.55
	var a0 := atan2(-to_t.z, -to_t.x)
	var flight := w.create_tween()
	flight.tween_method(func(u: float) -> void:
		var pos: Vector3
		var ring := head + Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		if u < 0.15:
			var k := u / 0.15
			pos = from.lerp(ring, k * k * (3.0 - 2.0 * k)) + Vector3(0, sin(k * PI) * 0.25, 0)
		elif u < 0.85:
			var k2 := (u - 0.15) / 0.7
			var a := a0 + k2 * TAU * 2.0
			pos = head + Vector3(cos(a) * r, sin(k2 * TAU * 3.0) * 0.1, sin(a) * r)
		else:
			var k3 := (u - 0.85) / 0.15
			pos = ring.lerp(card.global_position + Vector3(0, 0.05, 0), k3 * k3 * (3.0 - 2.0 * k3))
		if is_instance_valid(moth):
			moth.fly_to(pos), 0.0, 1.0, 6.0)
	Cine.look(w, "tilly", head + Vector3(0, 0.4, 0))
	await flight.finished
	# back into her card, and its light goes down again
	var back := w.create_tween()
	back.tween_property(moth, "scale", Vector3.ONE * 0.05, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await back.finished
	moth.queue_free()
	if cg != null:
		var gt2 := w.create_tween()
		gt2.tween_property(cg, "scale", cg.scale / 2.4, 0.8)
	var t = AshfordP1.meta(w, "moth_touch")
	if t != null and is_instance_valid(t):
		(t as Node).queue_free()
	w.remove_meta("moth_touch")
	Cine.look(w, "tilly", p)
	AshfordP1.two_shot(w, "player", "tilly", 3.0, 1.2, 38.0)
	await Cine.wait(w, 0.4)


# ================================================================ scenes ===

## The scenes ashford.gd's v7 talk trees call for. True if it was one of these.
static func scene(name: String, w: World) -> bool:
	match name:
		"after_lantern":
			await after_lantern(w)
		"corin_off":
			await corin_off(w)
		"bram_pleased":
			await bram_pleased(w)
		"bram_smile":
			await bram_smile(w)
		"afternoon":
			await afternoon(w)
		"sunset":
			w.hud.dialogue.close()
			await sunset(w)
		"tilly_face":
			await AshfordP1.tilly_up(w)
		"moth_for_tilly":
			await moth_for_tilly(w)
		"tam_bread":
			await tam_bread(w)
		"tam_to_nell":
			await tam_to_nell(w)
		"corin_button":
			await corin_button(w)
		"beat_bram":
			await AshfordP1.beat(w, "bram")
		"beat_tam":
			await AshfordP1.beat(w, "tam")
		"tam_deck_out":
			var tf = Cine.fig(w, "tam")
			if tf is Figure3D:
				(tf as Figure3D).act("talk", 1.0)
			await Cine.wait(w, 0.6)
		_:
			return false
	return true
