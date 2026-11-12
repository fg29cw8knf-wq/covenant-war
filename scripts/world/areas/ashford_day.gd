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

## The lane down to Tam's mill: off the ring road on the green's east side,
## out through the gap between the two cottages there, and up to a field
## gate at the edge of the village, where it runs on north-east over the
## fields (AshfordVillage.build_paths, lane_gate). Walking through the gate
## takes the player down to the mill (MillSet). (27 October, Gary: "it
## doesn't make sense where you go to get to Tam's, as it's right next to
## houses": the way down was a glowing spot by a cottage wall, a step off the
## green, where the old track ran in under two cottages' roofs.)
const LANE_MOUTH := Vector3(14.8, 0, -10.6)   # where it leaves the ring road
const LANE := Vector3(22.0, 0, -17.2)         # the gate
const LANE_R := 1.5
const LANE_DIR := Vector3(0.51, 0, -0.86)     # on through the gate, towards the mill
## Where they come back in from the mill: at the top of the lane by the
## green, facing it (further up, between the cottages, the game's camera
## behind them looked down through a cottage's thatch and lost them).
const LANE_BACK := Vector3(15.2, 0, -11.0)
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
## Until Tam's been seen (29 October, Gary: "It's not clear for players how
## to get to Tam's mill"): where he is and the way there, and the way marked
## on the screen (WorldHUD.set_way: the signpost at the lane's mouth, then
## the field gate once they're in the lane).
const FESTIVAL_TAM := "Explore Ashford and help prepare for the festival.\nFind Tam at his mill. (Follow the arrow, or the light: the lane by the signpost, east of the green.)\nOptional: challenge villagers to friendly card duels."
## (1 November, Gary: "it says find Bram at the green lantern but he's still
## sat next to the pole": the Great Lantern is the pole, and Bram is on his
## stool beside it; the words say so now, and the arrow points at him)
## (8 November, Gary: Corin's evening can't be missed; until it's done Bram
## sends the player to him, so the words put Corin first.)
const EVENING_CORIN := "Enjoy the festival. Corin's gone off on his own, down by the mill race: find him. (Follow the arrow, or the light: the lane by the signpost, east of the green.)\nThen, before midnight, find Bram on his stool by the Great Lantern (the tall lantern pole in the middle of the green)."
const SUN_GOING := "The sun's going down. Go back to Bram, on his stool by the Great Lantern (the tall lantern pole in the middle of the green)."
const EVENING := "Enjoy the festival. Before midnight, find Bram on his stool by the Great Lantern (the tall lantern pole in the middle of the green)."


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
## game is loaded part-way through the day; again is harmless). `place`
## false keeps everyone where they are (straight after the opening:
## Ashford.resume).
static func stage(w: World, place := true) -> void:
	var v := village(w)
	if v == null or Game.flag("ash_lantern_duel"):
		return
	var ph := phase()
	v.set_daylight(0.0 if ph == "evening" else 1.0)
	if not Game.flag("ash_started"):
		return
	if place:
		for id in ["corin", "tilly", "tam"]:
			_to_spot(w, id)
	if ph == "evening":
		_sit_corin(w)
		if Game.flag("tam_dances"):
			_dancing(w)
		festival_loaf(w)
	lane_sign(w)
	if ph == "afternoon":
		_set_objective(w, SUN_GOING if jobs_done() else (FESTIVAL_TAM if lane_wanted() else FESTIVAL))
	elif ph == "evening":
		_set_objective(w, EVENING_CORIN if lane_wanted() else EVENING)
	show_way(w)


## The way to the mill on the screen while there's someone to see down there
## and they're in the village: to the signpost at the lane's mouth, then
## (once they're nearer the gate than the green) to the field gate.
static func show_way(w: World) -> void:
	if w == null or w.hud == null:
		return
	if Game.flag("ash_lantern_duel"):
		w.hud.set_way(null, null)
		return
	var v := village(w)
	var p := w.player.global_position if w.player != null else Vector3.ZERO
	if at_mill(p):
		w.hud.set_way(null, null)
		return
	if not lane_wanted():
		# the afternoon's jobs done, or the evening with nobody down the lane:
		# the arrow is on Bram, on his stool by the Great Lantern
		var bb := Cine.body(w, "bram")
		var to_bram := (phase() == "afternoon" and jobs_done()) or phase() == "evening"
		if to_bram and bb != null and not at_mill(bb.global_position) and _flat(p, bb.global_position) > 3.0:
			w.hud.set_way(w.cam, bb.global_position + Vector3(0, 0.2, 0), "Bram")
		else:
			w.hud.set_way(null, null)
		return
	var mouth := LANE_MOUTH
	mouth.y = v.height(mouth.x, mouth.z)
	var gate := LANE
	gate.y = v.height(gate.x, gate.z)
	var in_lane := _flat(p, gate) < _flat(mouth, gate) + 0.5 or _flat(p, mouth) < 2.0
	w.hud.set_way(w.cam, gate if in_lane else mouth, "Tam's mill" if phase() == "afternoon" else "Corin, at the mill race")


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


## Someone still to see down at the mill (Tam, until he's been seen; Corin,
## in the evening, until he has).
static func lane_wanted() -> bool:
	return (phase() == "afternoon" and not Game.flag("ash_tam")) or (phase() == "evening" and not Game.flag("corin_pond"))


## Back at the gate with nobody new to see: down to the mill again, or not.
static func _lane_go_again(w: World) -> bool:
	w._move_target = null
	Game.set_flag("lane_go", false)
	# the player stands still for the question (4 November, Gary: going back
	# to Tam's after the village "you go through the floor": the question
	# didn't take the controls, so a held key or the pad walked them on past
	# the gate, where the lane climbs and the village has no ground to stand
	# on, and the hillside rose over their head)
	var was_busy := w.busy
	w.busy = true
	if w.hud != null:
		w.hud.set_controls_visible(false)
	w.player.velocity = Vector3.ZERO
	w.player_doll.walking = false
	await w.run_steps([
		{"say": "[i](The lane runs on down to Tam's mill.)[/i]"},
		{"choice": ["Go down to the mill.", "Stay in the village."], "then": [[{"set": "lane_go"}], []]},
	], null)
	if is_instance_valid(w) and w.hud != null:
		w.hud.dialogue.close()
		w.hud.set_controls_visible(true)
	if is_instance_valid(w):
		w.busy = was_busy
	var go := bool(Game.flag("lane_go", false))
	Game.set_flag("lane_go", false)
	return go


## The signpost at the lane's mouth, and the glow at its gate while there's
## someone to see down there.
static func lane_sign(w: World) -> void:
	var v := village(w)
	var sign: Node3D = AshfordP1.meta(v, "lane_sign")
	if sign == null:
		sign = Node3D.new()
		sign.name = "MillLaneSign"
		v.get_meta("p1_root").add_child(sign)
		# at the lane's mouth, beside it, its board to the green
		var at := LANE_MOUTH + Vector3(LANE_DIR.z, 0, -LANE_DIR.x) * -1.15
		at.y = v.height(at.x, at.z)
		sign.position = at
		sign.rotation.y = atan2(-at.x, -at.z) - 0.35
		v.box(sign, Vector3(0.1, 1.5, 0.1), Vector3(0, 0.75, 0), v.mats.beam_v)
		v.box(sign, Vector3(0.75, 0.22, 0.04), Vector3(-0.3, 1.32, 0.05), v.mats.wood_h, Vector3(0, 0, 0.06))
		var label := Label3D.new()
		label.text = "TO THE MILL"
		label.font_size = 34
		label.pixel_size = 0.0034
		label.modulate = Color(0.16, 0.11, 0.07)
		label.outline_size = 0
		label.position = Vector3(-0.32, 1.32, 0.075)
		sign.add_child(label)
		v.set_meta("lane_sign", sign)
		lane_gate(v)
	var want := lane_wanted()
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
		# and a soft pillar of light over the gate, seen over the roofs from
		# the green (29 October, as Solhaven marks where the story goes next)
		_beacon(mark)
	elif not want and glow != null:
		if is_instance_valid(glow):
			glow.queue_free()
		var mk = AshfordP1.meta(v, "lane_mark")
		if mk != null and is_instance_valid(mk):
			(mk as Node).queue_free()
		v.remove_meta("lane_glow")
		v.remove_meta("lane_mark")


## A soft pillar of light standing over `parent`, slowly turning and
## breathing, so the place can be found from anywhere in the village.
static func _beacon(parent: Node3D) -> void:
	var b := Node3D.new()
	b.name = "Beacon"
	parent.add_child(b)
	var glow := func(alpha: float, energy: float) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.85, 0.45, alpha)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.emission_enabled = true
		m.emission = Color(1.0, 0.85, 0.45)
		m.emission_energy_multiplier = energy
		return m
	var p := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.85
	cm.height = 10.0
	cm.cap_top = false
	cm.cap_bottom = false
	p.mesh = cm
	p.material_override = glow.call(0.16, 1.1)
	p.position.y = 5.0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.add_child(p)
	var tw := b.create_tween().set_loops() if b.is_inside_tree() else null
	if tw == null:
		b.tree_entered.connect(func() -> void:
			var t2 := b.create_tween().set_loops()
			t2.tween_property(b, "scale", Vector3(0.82, 1.0, 0.82), 1.2).set_trans(Tween.TRANS_SINE)
			t2.tween_property(b, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_SINE), CONNECT_ONE_SHOT)
	else:
		tw.tween_property(b, "scale", Vector3(0.82, 1.0, 0.82), 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_SINE)


## The field gate where the lane leaves the village: two posts, the
## five-barred gate swung open against the field side, and a run of
## post-and-rail either side.
static func lane_gate(v: AshfordVillage) -> void:
	if AshfordP1.meta(v, "lane_gate") != null:
		return
	var g := Node3D.new()
	g.name = "MillLaneGate"
	v.get_meta("p1_root").add_child(g)
	var at := LANE
	at.y = v.height(at.x, at.z)
	g.position = at
	g.rotation.y = atan2(LANE_DIR.x, LANE_DIR.z)   # local +Z up the lane
	var wood: Material = v.mats.beam_v
	var rail: Material = v.mats.wood_h
	for sx in [-1.2, 1.2]:
		v.box(g, Vector3(0.16, 1.35, 0.16), Vector3(sx, 0.67, 0), wood)
	# the gate, open: hinged on the left post, swung back along the lane
	var gate := Node3D.new()
	g.add_child(gate)
	gate.position = Vector3(-1.12, 0, 0)
	gate.rotation.y = deg_to_rad(-100.0)
	for k in 5:
		v.box(gate, Vector3(2.1, 0.07, 0.05), Vector3(1.08, 0.3 + k * 0.2, 0), rail)
	v.box(gate, Vector3(0.09, 1.0, 0.07), Vector3(0.05, 0.62, 0), rail)
	v.box(gate, Vector3(0.09, 1.0, 0.07), Vector3(2.1, 0.62, 0), rail)
	v.box(gate, Vector3(2.3, 0.06, 0.05), Vector3(1.08, 0.7, 0), rail, Vector3(0, 0, 0.42))
	# a run of post and rail either side of it
	for run in [[Vector3(-1.2, 0, 0), Vector3(-3.4, 0, -0.2)], [Vector3(1.2, 0, 0), Vector3(3.4, 0, -0.2)]]:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var mid := (a + b) * 0.5
		var L := a.distance_to(b)
		var yaw := atan2(-(b.z - a.z), b.x - a.x)
		v.box(g, Vector3(0.14, 1.1, 0.14), b + Vector3(0, 0.55, 0), wood)
		for h in [0.45, 0.85]:
			v.box(g, Vector3(L, 0.08, 0.06), mid + Vector3(0, h, 0), rail, Vector3(0, yaw, 0))
	# nobody walks on down the lane on their own feet: past the gate the lane
	# climbs and the village has no ground to stand on, so a solid wall just
	# beyond it (and along the fence) stops free walking there; the way to
	# the mill is to_mill()'s own walk through it (4 November, Gary: "you go
	# through the floor")
	var yaw_lane := atan2(LANE_DIR.x, LANE_DIR.z)
	v.solid_box(at + LANE_DIR * 2.2 + Vector3(0, 1.5, 0), Vector3(14.0, 3.0, 0.4), yaw_lane)
	v.set_meta("lane_gate", g)


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
	# (1 November) the people on the green get on with their afternoon
	AshfordLife.start(w)
	await _watching(w)
	# (midnight, or the village left: the way to the mill goes)
	if is_instance_valid(w) and w.hud != null:
		w.hud.set_way(null, null)


static func _watching(w: World) -> void:
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
		if ph != "morning":
			show_way(w)
		if ph == "morning":
			if not Game.flag("corin_met") and w._npc_by_id("corin") != null:
				w._talk(w._npc_by_id("corin"))
			continue
		# the gate: once through it they're on their way down; back from the
		# mill they must walk off from it before it can take them again, and
		# with nobody new to see down there it asks first (27 October, Gary:
		# walking towards the houses after Tam's talk played it all again)
		var at_gate := _flat(p, LANE) < LANE_R
		if not at_gate:
			if _flat(p, LANE) > LANE_R + 1.2:
				w.set_meta("lane_armed", true)
		elif w.get_meta("lane_armed", true):
			w.set_meta("lane_armed", false)
			if lane_wanted() or await _lane_go_again(w):
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
## cheering his own loss; 27 October: the jolt of surprise looked scared, so
## now he just sags, beaten, held while he yields, and off it comes as he
## walks away).
static func after_lantern(w: World) -> void:
	w.cine = true
	for k in AshfordP1.KIDS:
		Cine.hop(w, String(k[0]), 0.2)
	AshfordP1.two_shot(w, "player", "corin", 3.4, 1.5, 36.0)
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D:
		# (27 October, Gary: the recoil read as "more scared than defeated":
		# a beat of disbelief, then he sags, head down, shoulders gone,
		# held while he yields, and off as he walks away)
		await Cine.wait(w, 0.45)
		(cf as Figure3D).slump(0.85, 1.4)
		await Cine.wait(w, 1.2)
	else:
		await Cine.wait(w, 1.2)
	Cine.look(w, "corin", w.player.global_position)


## Corin wades off into the crowd towards the merchant carts, still
## complaining about losing (Gary's direction, 24 October).
##
## (1 November, Gary: "Corin's message about the wind should be him
## shouting it to everyone, not saying it, and his body should look like
## he's shouting it"; and the line "gets skipped really quickly": it was a
## passing remark that went by itself after a second and a half.) He gets a
## few strides off, stops, turns to the whole green, hands cupped round his
## mouth, and bellows it; the line waits for a tap like any other; then off
## he goes to the carts.
static func corin_off(w: World) -> void:
	var v := village(w)
	var to := CORIN_CARTS
	to.y = v.height(to.x, to.z)
	var cf = Cine.fig(w, "corin")
	var cb := Cine.body(w, "corin")
	if cf is Figure3D:
		(cf as Figure3D).release(0.3)   # (the defeat pose, off as he goes)
	var way := AshfordP1.round_lantern(w, cb.global_position, to)
	# a few strides along the way
	var first: Vector3 = way[0]
	var d := first - cb.global_position
	d.y = 0.0
	var stop := cb.global_position + d.normalized() * minf(2.6, d.length() * 0.6)
	stop = Cine.off_blockers(w, stop)
	stop.y = v.height(stop.x, stop.z)
	await Cine.path(w, "corin", [stop], 1.6)
	# turned to the green, hands to his mouth, chest out: a shout for everyone
	var green := Vector3(0.0, stop.y, 0.0)
	var crowd_dir := (green - stop)
	crowd_dir.y = 0.0
	crowd_dir = crowd_dir.normalized() if crowd_dir.length() > 0.5 else d.normalized()
	Cine.look(w, "corin", stop + crowd_dir * 4.0)
	var hands: Array = []
	if cf is Figure3D:
		var fig := cf as Figure3D
		await Cine.wait(w, 0.35)
		var head := Cine.head(w, "corin")
		var across := crowd_dir.cross(Vector3.UP).normalized()
		for sd in [-1.0, 1.0]:
			var hn := Node3D.new()
			w.add_child(hn)
			hn.global_position = head + crowd_dir * 0.13 + across * sd * 0.07 + Vector3(0, -0.1, 0)
			hands.append(hn)
		# (his left hand on his left side: across is his right)
		fig.palm("left", Vector3.ZERO, 0.2)
		fig.reach(hands[0], hands[1], 0.3)
	var mid := stop + crowd_dir * 1.2
	Cine.shot(w, AshfordP1.clear_cam(w, [mid + crowd_dir.cross(Vector3.UP) * 3.2 + Vector3(0, 1.4, 0), mid - crowd_dir.cross(Vector3.UP) * 3.2 + Vector3(0, 1.4, 0),
		stop + crowd_dir * 3.4 + Vector3(0, 1.3, 0)], stop + Vector3(0, 1.4, 0), ["corin", "player", "bram"]), stop + Vector3(0, 1.45, 0), 38.0)
	for k in AshfordP1.KIDS:
		Cine.look(w, String(k[0]), stop)
	w.shake(0.04)
	await w.hud.dialogue.say(w._speaker("corin") + " (shouting)", w._portrait("corin"), "[b]It was the WIND! Everyone saw the wind![/b]")
	w.hud.dialogue.close()
	if cf is Figure3D:
		(cf as Figure3D).let_go(0.3)
	for hn in hands:
		(hn as Node).queue_free()
	Cine.path(w, "corin", AshfordP1.round_lantern(w, stop, to), 1.6)
	await Cine.wait(w, 0.6)


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
	_set_objective(w, FESTIVAL_TAM if lane_wanted() else FESTIVAL)
	show_way(w)
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
	# on through the gate and away up the lane as the picture goes
	if _flat(w.player.global_position, LANE) < LANE_R + 0.5:
		Cine.path(w, "player", [LANE + LANE_DIR * 3.0], 1.3)
		await Cine.fade(w, 1.0, 0.9)
	else:
		await Cine.fade(w, 1.0, 0.6)
	MillSet.enter(w)
	MillSet.lamps(v, evening)
	# (the arrow to the gate is for the village: at the mill it pointed back
	# up the lane, "Tam's mill · 668 m", with Tam in front of them)
	w.hud.set_way(null, null)
	if evening and not Game.flag("corin_pond"):
		# (1 November, Gary: the evening with Corin as a film, not a
		# conversation from behind the player's back)
		await _corin_pond_film(w, m)
		return
	var arrive: Vector3 = m.arrive
	_to_spot(w, who)
	if evening:
		_sit_corin(w)
	var them: Vector3 = Cine.body(w, who).global_position
	Cine.place(w, "player", arrive, them)
	if evening:
		_corin_eyes(w, arrive)
	else:
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
	if evening:
		_corin_eyes(w, w.player.global_position)
	else:
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
		_corin_up(w)
		var cf = Cine.fig(w, "corin")
		if cf is Figure3D:
			(cf as Figure3D).stand(0.0)
	back_on_green(w)
	stage(w)
	await Cine.fade(w, 0.0, 0.7)
	AshfordP1.controls_on(w)
	w.busy = false


## Corin's evening by the mill race as a film (1 November, Gary: "the whole
## time you and Corin are talking in the evening you can just see the black
## of the player: I want this whole scene animated and more story film than
## just a conversation", the music "more serious" while they talk, and
## "Corin halfway through what he's sitting on"). The music goes quiet and
## serious; the mill at night from across the meadow, the wheel turning, the
## lanterns on the race wall and Corin alone on it, small; nearer, his coat
## folded beside him and a card turning over in his fingers; the player
## comes down along the bank to him and sits on the wall beside him. Then
## the talk, each line from in front of whoever speaks (PondDirector), with
## the two of them together between; his button; and as it ends he looks
## back at the water and the player gets up and leaves him to it. Corin's
## body stays square on the wall throughout (he'd been turned on it to face
## the player as they came, and his legs went into the stone).
static func _corin_pond_film(w: World, m: Dictionary) -> void:
	var v := village(w)
	var root: Node3D = m.root
	Music.play(["corin_evening", "river_farewell", "dawn_after"], 2.5, true)
	_to_spot(w, "corin")
	_sit_corin(w)
	var cb := Cine.body(w, "corin")
	var seat := cb.global_position
	var fwd := Vector3.LEFT   # (he faces the meadow, his back to the race)
	var along := Vector3.BACK # (along the wall, the way the player comes)
	var beside := seat + along * 0.78
	var arrive: Vector3 = m.arrive
	Cine.place(w, "player", arrive, beside)
	# his coat folded on the wall beside him, and a card in his fingers
	var coat := Node3D.new()
	coat.name = "CorinsCoat"
	coat.set_meta("p1_prop", true)
	root.add_child(coat)
	var blue := StandardMaterial3D.new()
	blue.albedo_color = Color(0.18, 0.24, 0.42)
	blue.roughness = 1.0
	v.box(coat, Vector3(0.36, 0.07, 0.26), Vector3.ZERO, blue)
	v.box(coat, Vector3(0.34, 0.05, 0.24), Vector3(0.0, 0.055, 0.0), blue, Vector3(0, 0.1, 0))
	# (on the wall's middle, beside him: he sits towards its meadow edge)
	coat.global_position = seat - along * 0.5 + Vector3(0.0, 0.535, 0)
	coat.global_position.x = MillSet.spot(RACE_WALL.get_center()).x
	var cf = Cine.fig(w, "corin")
	var card := Node3D.new()
	card.name = "SignedCard"
	card.set_meta("p1_prop", true)
	var cardm := StandardMaterial3D.new()
	cardm.albedo_color = Color(0.86, 0.8, 0.66)
	cardm.roughness = 0.8
	v.box(card, Vector3(0.063, 0.088, 0.003), Vector3.ZERO, cardm)
	w.add_child(card)
	if cf is Figure3D:
		(cf as Figure3D).attach(card, "palm", "right", 0.004, 0.0)
	# the mill at night across the meadow: the windows lit, the wheel turning
	var est_a := root.to_global(Vector3(-9.5, 1.4, 15.5))
	var est_b := root.to_global(Vector3(-8.0, 1.8, 12.5))
	var look_a := seat + Vector3(0.0, 1.2, -2.0)
	Cine.shot(w, est_a, look_a, 46.0)
	await Cine.fade(w, 0.0, 1.2)
	await Cine.drift(w, est_a, est_b, look_a, seat + Vector3(0, 0.9, 0), 4.2, 44.0)
	# nearer: Corin alone on the wall, the card turning in his hand
	var near_cam := seat + fwd * 2.3 - along * 1.3 + Vector3(0, 1.0, 0)
	Cine.shot(w, near_cam, seat + Vector3(0, 0.75, 0), 34.0)
	var turning := [true]
	_card_turns(w, card, turning)
	Cine.drift(w, near_cam, seat + fwd * 1.9 - along * 0.9 + Vector3(0, 0.9, 0), seat + Vector3(0, 0.75, 0), seat + Vector3(0, 0.8, 0), 3.0, 32.0)
	await Cine.wait(w, 2.6)
	# the player comes down the bank to him, and sits on the wall beside him
	var stand_at := beside + fwd * 0.55
	Cine.shot(w, seat + fwd * 4.2 + along * 2.4 + Vector3(0, 1.5, 0), (seat + arrive) * 0.5 + Vector3(0, 0.9, 0), 40.0)
	var walk_done := [false]
	var walking := func() -> void:
		await Cine.path(w, "player", [stand_at], 1.4)
		walk_done[0] = true
	walking.call()
	var t := 0.0
	while not walk_done[0] and t < 14.0:
		await w.get_tree().process_frame
		t += w.get_process_delta_time()
		var pp := w.player.global_position
		w.cam.look_at(pp + Vector3(0, 1.0, 0) + (seat - pp) * 0.25, Vector3.UP)
	if not is_instance_valid(w):
		return
	Cine.look(w, "player", seat)
	# a two-shot as they sit: the pair on the wall, the race and the lit
	# mill behind them
	_pond_shot(w, "", seat, beside, fwd, along)
	# (8 November: their hands at rest on their thighs, and the wall solid to
	# them, as Corin's are: the sat clip's arms hang, down into the stone)
	var pfig = w.player_doll
	if pfig is Figure3D:
		(pfig as Figure3D).hands_off([_wall_box()])
	await AshfordP1.sit_down(w, "player", beside, fwd, 0.5, 0.6, true)
	await Cine.wait(w, 0.5)
	turning[0] = false
	var n = w._npc_by_id("corin")
	if n != null:
		n.doll.set_marker("")
		w.director = func(who: String) -> void:
			_pond_shot(w, who, seat, beside, fwd, along)
		await w.run_steps(n.def.talk, n)
		w.director = Callable()
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	w.hud.dialogue.close()
	# he looks back at the water; the player gets up and leaves him to it
	if cf is Figure3D:
		(cf as Figure3D).detach(card)
		if not ((cf as Figure3D).seat >= 0.0):
			AshfordP1.sit_down(w, "corin", seat, fwd, 0.5, 0.5)
	if is_instance_valid(card):
		card.queue_free()
	_pond_shot(w, "", seat, beside, fwd, along)
	await Cine.wait(w, 0.8)
	await AshfordP1.stand_up(w, "player", 0.5)
	if pfig is Figure3D and is_instance_valid(pfig):
		(pfig as Figure3D).hands_off([])
	Cine.path(w, "player", [beside + fwd * 1.4 + along * 1.2, arrive], 1.3)
	Cine.drift(w, seat + fwd * 3.6 - along * 1.0 + Vector3(0, 1.1, 0), seat + fwd * 4.4 - along * 1.6 + Vector3(0, 1.6, 0),
		seat + Vector3(0, 0.8, 0), seat + Vector3(0, 0.9, 0), 3.5, 38.0)
	await Cine.wait(w, 2.6)
	await Cine.fade(w, 1.0, 1.0)
	if is_instance_valid(coat):
		coat.queue_free()
	MillSet.leave(w)
	_corin_up(w)
	if cf is Figure3D:
		(cf as Figure3D).stand(0.0)
	back_on_green(w)
	stage(w)
	w.resume_music()
	await Cine.fade(w, 0.0, 0.7)
	AshfordP1.controls_on(w)
	w.busy = false


## The card turning over in Corin's fingers while `state[0]` holds.
static func _card_turns(w: World, card: Node3D, state: Array) -> void:
	var cf = Cine.fig(w, "corin")
	if not (cf is Figure3D):
		return
	var t := 0.0
	while state[0] and is_instance_valid(card) and is_instance_valid(w):
		t += w.get_process_delta_time()
		(cf as Figure3D).attach(card, "palm", "right", 0.004, sin(t * 1.3) * 0.9)
		await w.get_tree().process_frame


## The pond's shots, by who's speaking: in front of Corin for his lines,
## in front of the player for theirs and their choices, low and a little to
## the side so the other's shoulder is at the edge; the two of them together
## from in front for anything else, and every few lines for a breath.
## Each shot drifts a little as the line plays.
static func _pond_shot(w: World, who: String, seat: Vector3, beside: Vector3, fwd: Vector3, along: Vector3) -> void:
	var n: int = w.get_meta("pond_lines", 0) + 1
	w.set_meta("pond_lines", n)
	# (their heads where they are now: sat, or Corin stood for his button)
	var ch := Cine.head(w, "corin") if Cine.body(w, "corin") != null else seat + Vector3(0, 1.12, 0)
	var ph := Cine.head(w, "player")
	var mid := (ch + ph) * 0.5
	var pos: Vector3
	var look: Vector3
	var fov := 30.0
	if who == "corin" and n % 4 != 0:
		pos = ch + fwd * 1.45 + along * 0.55 + Vector3(0, -0.12, 0)
		look = ch + Vector3(0, -0.04, 0)
	elif (who == "player" or who == "?") and n % 4 != 0:
		pos = ph + fwd * 1.45 - along * 0.55 + Vector3(0, -0.12, 0)
		look = ph + Vector3(0, -0.04, 0)
	else:
		pos = mid + fwd * 2.7 + Vector3(0, -0.15, 0)
		look = mid + Vector3(0, -0.2, 0)
		fov = 36.0
	var to := pos + fwd * -0.12 + Vector3(0, 0.02, 0)
	Cine.drift(w, pos, to, look, look, 6.0, fov)


## The race wall Corin sits on in the evening, in the mill set's own frame
## (MillSet.build: the low wall along the west bank, its meadow face at x
## 0.75, its top 0.5 m up), and where his hips sit on it: towards its meadow
## edge, the way anyone sits on a wall, so the thighs reach out over the
## edge and the shins hang down clear of its face (6 November, Gary: "his
## legs also go through the wall"; on the wall's middle the backs of his
## knees were on its edge and the calves against the stone).
const RACE_WALL := AABB(Vector3(0.75, 0.0, 4.5), Vector3(0.5, 0.5, 6.0))
const CORIN_SEAT := Vector3(0.9, 0, 7.0)


## Corin on the race wall, his back to the water, facing the meadow, his
## hands at rest on it (_corin_rests).
static func _sit_corin(w: World) -> void:
	var cb := Cine.body(w, "corin")
	if cb == null or not at_mill(cb.global_position):
		return
	var seat := MillSet.spot(CORIN_SEAT)
	AshfordP1.sit_down(w, "corin", seat, Vector3.LEFT, 0.5, 0.0)
	_corin_rests(w)


## The wall in the world (an AABB), for Figure3D.hands_off.
static func _wall_box() -> AABB:
	return AABB(MillSet.spot(RACE_WALL.position), RACE_WALL.size)


## Corin's hands while he sits on the wall (6 November, Gary: "When you meet
## Corin in evening his hands look through the wall he is sitting on": his
## sitting clip's arms hang at his sides, which on a wall top is down into
## the stone). The hand on the player's side rests flat on the wall's top
## beside his hip, the other (the card in it) in his lap on his thigh; the
## wall is a solid to his hands besides (Figure3D.hands_off), so nothing he
## does with them goes into it. _corin_up gives them back.
static func _corin_rests(w: World, secs := 0.0) -> void:
	var cf = Cine.fig(w, "corin")
	if not (cf is Figure3D):
		return
	var fig := cf as Figure3D
	if fig.seat < 0.0:
		return
	var top := MillSet.spot(RACE_WALL.end).y
	fig.hands_off([_wall_box()])
	var marks: Array = []
	for nm in ["CorinRestL", "CorinRestR"]:
		if w.has_meta("pond_" + nm):
			var old = w.get_meta("pond_" + nm)
			if old != null and is_instance_valid(old):
				(old as Node).queue_free()
		var mk := Node3D.new()
		mk.name = nm
		w.add_child(mk)
		w.set_meta("pond_" + nm, mk)
		marks.append(mk)
	# (their own frame: x their left, z ahead; the player sits on his left)
	var s := fig.stature()
	var l: Vector3 = fig.to_world(Vector3(0.24 * s, 0.0, 0.04 * s))
	l.y = top + 0.035 * s
	(marks[0] as Node3D).global_position = l
	var r: Vector3 = fig.to_world(Vector3(-0.07 * s, 0.0, 0.24 * s))
	r.y = top + 0.15 * s
	(marks[1] as Node3D).global_position = r
	fig.palm("left", Vector3.DOWN, maxf(secs, 0.01), 1.0)
	fig.palm("right", Vector3.UP, maxf(secs, 0.01), 0.4)
	fig.reach(marks[0], marks[1], maxf(secs, 0.01))


## Up off the wall: the hands his own again, the wall no solid to them.
static func _corin_up(w: World) -> void:
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D:
		var fig := cf as Figure3D
		fig.let_go(0.0)
		fig.palm("left", Vector3.ZERO, 0.0)
		fig.palm("right", Vector3.ZERO, 0.0)
		fig.hands_off([])
		fig.eyes_on(null)
	for nm in ["CorinRestL", "CorinRestR"]:
		if not w.has_meta("pond_" + nm):
			continue
		var old = w.get_meta("pond_" + nm)
		if old != null and is_instance_valid(old):
			(old as Node).queue_free()
		w.remove_meta("pond_" + nm)


## Is Corin sat on the race wall?
static func _corin_on_wall(w: World) -> bool:
	var cf = Cine.fig(w, "corin")
	var cb := Cine.body(w, "corin")
	return cf is Figure3D and (cf as Figure3D).seat >= 0.0 and cb != null and at_mill(cb.global_position)


## Corin looks at something from the wall: with his head, not his whole body
## (a turn of the body on the seat swung his legs round into the stone: 6
## November, Gary, "his legs also go through the wall when he turns to you").
## Standing, he turns as anyone does.
static func _corin_eyes(w: World, at: Vector3) -> void:
	if _corin_on_wall(w):
		(Cine.fig(w, "corin") as Figure3D).eyes_on(at + Vector3(0, 1.1, 0) if at.y < Cine.body(w, "corin").global_position.y + 0.5 else at)
	else:
		Cine.look(w, "corin", at)


## A beat on the wall: he looks away, out over the meadow on the side away
## from the player, and back to them, his head turning and his body still.
static func _corin_beat(w: World) -> void:
	var fig := Cine.fig(w, "corin") as Figure3D
	var cb := Cine.body(w, "corin")
	var to_p := w.player.global_position - cb.global_position
	to_p.y = 0.0
	var away := cb.global_position + fig.facing() * 3.0 - to_p.normalized() * 2.0
	fig.eyes_on(away + Vector3(0, 0.9, 0))
	await Cine.wait(w, 0.8)
	fig.eyes_on(Cine.head(w, "player"))
	await Cine.wait(w, 0.5)
	# (and his head's his own again: it goes to whoever's talking)
	fig.eyes_on(null)


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
	w.set_meta("lane_armed", false)   # (they walk off from the gate before it takes them again)
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
	festival_loaf(w)
	if not w.get_meta("bram_seated", false):
		AshfordP1.bram_sit(w)
	lane_sign(w)
	AshfordP1.put(w, "player", Vector3(1.2, 0, 6.2), Vector3.ZERO)
	w.cam.fov = World.CAM_FOV
	# (Corin first: he's down at the mill race, and the evening's words say so
	# from the start, not only after a reload as stage() had them)
	_set_objective(w, EVENING_CORIN if lane_wanted() else EVENING)
	await Cine.overlay(w).bars(false)
	w.end_cine()
	w._focus = w._cam_focus_target()
	w._place_camera()
	await Cine.fade(w, 0.0, 0.8)
	AshfordP1.controls_on(w)
	w.busy = false


# ============================================================ the evening ===

## Gary's festival loaf (27 October) and the piece Tam tears off it.
const LOAF_MODEL := "res://assets/models/ashford/festival_loaf.glb"
const LOAF_PIECE_MODEL := "res://assets/models/ashford/loaf_piece.glb"
## The loaf has a little round table of its own beside Tam at the bread stall
## (the stall's counter is full of Gary's bowls and jars): where it stands,
## from Tam's evening spot, and how high and wide its top is.
const LOAF_TABLE := Vector3(1.05, 0, 0.35)
const LOAF_TABLE_H := 0.82
const LOAF_TABLE_R := 0.36
const LOAF_SCALE := 0.55


## The festival loaf on its table by the bread stall, all evening (it's what
## Tam's selling, and the first loaf off the stone is torn from it).
static func festival_loaf(w: World) -> void:
	var v := village(w)
	if v == null or v.has_meta("festival_loaf") or not ResourceLoader.exists(LOAF_MODEL):
		return
	var g := Node3D.new()
	g.name = "LoafTable"
	var at := TAM_BREAD + LOAF_TABLE
	at.y = v.height(at.x, at.z)
	g.position = at
	v.add_child(g)
	# a round table on one leg, and a bread board on it (a cloth round the
	# edge was tried: in the lantern light it read as a pale plastic rim)
	v.cyl(g, 0.07, 0.1, LOAF_TABLE_H, Vector3(0, LOAF_TABLE_H * 0.5, 0), v.mats.wood, 10)
	v.cyl(g, 0.22, 0.26, 0.05, Vector3(0, 0.025, 0), v.mats.wood, 12)
	v.cyl(g, LOAF_TABLE_R, LOAF_TABLE_R, 0.045, Vector3(0, LOAF_TABLE_H, 0), v.mats.wood_h, 20)
	v.cyl(g, 0.24, 0.24, 0.022, Vector3(0, LOAF_TABLE_H + 0.034, 0), v.mats.wood, 16)
	v.solid_round(at, LOAF_TABLE_R + 0.1)
	var loaf: Node3D = (load(LOAF_MODEL) as PackedScene).instantiate()
	loaf.name = "FestivalLoaf"
	loaf.scale = Vector3.ONE * LOAF_SCALE
	loaf.position = Vector3(0, LOAF_TABLE_H + 0.045, 0)
	loaf.rotation.y = 2.4
	g.add_child(loaf)
	for mi: MeshInstance3D in loaf.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	v.set_meta("festival_loaf", loaf)


## The piece of bread Tam hands over: Gary's model, or (without it) a round of crust.
static func _bread_piece() -> Node3D:
	var bread := Node3D.new()
	bread.name = "Bread"
	if ResourceLoader.exists(LOAF_PIECE_MODEL):
		var inst: Node3D = (load(LOAF_PIECE_MODEL) as PackedScene).instantiate()
		# (made standing on its base, 14 cm across: held by its middle)
		inst.position = Vector3(0, -0.05, 0)
		bread.add_child(inst)
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
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
	return bread


## Tam breaks the first loaf off the stone and hands a piece over.
static func tam_bread(w: World) -> void:
	var tf = Cine.fig(w, "tam")
	var pf = w.player_doll
	festival_loaf(w)
	AshfordP1.two_shot(w, "player", "tam", 3.0, 1.4, 34.0)
	if not (tf is Figure3D):
		await Cine.wait(w, 0.6)
		return
	var bread := _bread_piece()
	# he reaches across to the loaf on the counter and tears the piece off it
	var v := village(w)
	var loaf: Node3D = v.get_meta("festival_loaf") if v != null and v.has_meta("festival_loaf") else null
	if loaf != null and is_instance_valid(loaf):
		var tear := Node3D.new()
		w.add_child(tear)
		tear.global_position = loaf.global_position + Vector3(0, 0.12, 0)
		Cine.look(w, "tam", loaf.global_position)
		(tf as Figure3D).reach(null, tear, 0.35)
		await Cine.wait(w, 0.7)
		(tf as Figure3D).let_go(0.3)
		tear.queue_free()
		Cine.look(w, "tam", Cine.body(w, "player").global_position)
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
## Where the player's palm comes to take it, from his (m): across towards
## the player, so the two palms are side by side and not one on the other,
## and down, so their fingertips pass under his.
const BUTTON_ACROSS := 0.1
const BUTTON_UNDER := 0.045
## How long their hand takes from the look at it to the pocket at their hip (s).
const BUTTON_POCKET := 0.45


static func corin_button(w: World) -> void:
	var cf = Cine.fig(w, "corin")
	var pf = w.player_doll
	if not (cf is Figure3D):
		await Cine.wait(w, 0.5)
		return
	var corin := cf as Figure3D
	var b := Node3D.new()
	b.name = "Button"
	if ResourceLoader.exists(BUTTON_MODEL):
		# Gary's button (26 October): iron-plated, a scrap of his coat's blue
		# wool on its back, 2.8 cm across, made lying flat
		var gm: Node3D = load(BUTTON_MODEL).instantiate()
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
		b.add_child(mi)
	b.set_meta("p1_prop", true)
	w.add_child(b)
	# (1 November: sat side by side on the race wall, he holds it out on the
	# flat of his hand towards the player, who takes it on theirs; standing
	# up off the wall where he sat put his legs in the stone. Both hands put
	# it there every frame, Figure3D.attach, so it's in a hand, not on an arm)
	var cb := Cine.body(w, "corin")
	var to_p := w.player.global_position - cb.global_position
	to_p.y = 0.0
	to_p = to_p.normalized()
	var his_side := "left" if to_p.dot(corin.facing().cross(Vector3.UP)) < 0.0 else "right"
	var give := Node3D.new()
	give.name = "ButtonGive"
	w.add_child(give)
	var seated := corin.seat >= 0.0
	var h := (corin.hold_point(0.0, 0.0).y - corin.arm_reach() * 0.55) if not seated else 0.95 * corin.stature()
	give.global_position = cb.global_position + to_p * 0.32 + corin.facing() * 0.3 + Vector3(0, h, 0)
	# close on the hands, from in front of them and a little above (the
	# lines after it go back to the faces: _pond_shot)
	if seated:
		var at := give.global_position + to_p * BUTTON_ACROSS * 0.5 + Vector3(0, -0.02, 0)
		var cam_a := at + corin.facing() * 0.95 + to_p * 0.12 + Vector3(0, 0.32, 0)
		Cine.drift(w, cam_a, cam_a - corin.facing() * 0.12, at, at, 3.2, 34.0)
	corin.palm(his_side, Vector3.UP, 0.35, 0.6)
	corin.reach(give if his_side == "left" else null, give if his_side == "right" else null, 0.45)
	await Cine.wait(w, 0.2)
	corin.attach(b, "palm", his_side, 0.008)
	await Cine.wait(w, 0.6)
	if pf is Figure3D:
		var me := pf as Figure3D
		var my_side := "right" if (-to_p).dot(me.facing().cross(Vector3.UP)) > 0.0 else "left"
		# (6 November, Gary: "When Corin hands you something your hand goes
		# through his": their hand came down palm-down onto his, on the spot
		# his was, and turned palm up there, through it. Now it comes in
		# under the edge of his, palm up, on its own side and a little lower,
		# the fingertips just under his; he tips his hand and the button
		# slides off his fingers into their palm.)
		var take := Node3D.new()
		take.name = "ButtonTake"
		w.add_child(take)
		var take_at := give.global_position + to_p * BUTTON_ACROSS + Vector3(0, -BUTTON_UNDER, 0)
		take.global_position = take_at + to_p * 0.08 + Vector3(0, -0.07, 0)
		me.palm(my_side, Vector3.UP, 0.3, 0.6)
		# (that hand alone: the other stays where it rests, in their lap)
		me._reach(my_side, take, 0.4)
		var come := w.create_tween()
		come.tween_property(take, "global_position", take_at, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await come.finished
		await Cine.wait(w, 0.15)
		# he tips it towards them, and it slides off into their palm
		corin.palm(his_side, (Vector3.UP * 0.8 + to_p * 0.6).normalized(), 0.3, 0.6)
		var tip := w.create_tween()
		tip.tween_property(give, "global_position", give.global_position + to_p * 0.015 + Vector3(0, -0.01, 0), 0.3).set_trans(Tween.TRANS_SINE)
		await Cine.wait(w, 0.18)
		corin.detach(b)
		var from := b.global_position
		var basis0 := b.global_transform.basis
		var land := take_at + Vector3(0, 0.02, 0)
		var slide := w.create_tween()
		slide.tween_method(func(k: float) -> void:
			if is_instance_valid(b):
				var at := from.lerp(land, k)
				at.y = lerpf(from.y, land.y, k * k)   # (it falls the last of the way)
				b.global_transform = Transform3D(basis0.slerp(Basis.IDENTITY, k).orthonormalized(), at), 0.0, 1.0, 0.28)
		await slide.finished
		me.attach(b, "palm", my_side, 0.008)
		# his hand back to where it rests (on the wall), or down
		corin.palm(his_side, Vector3.ZERO, 0.35)
		if _corin_on_wall(w):
			_corin_rests(w, 0.4)
		else:
			corin.let_go(0.35)
		await Cine.wait(w, 0.3)
		# in to them, a look at it, and into a pocket (it's in Items)
		var chest := me.bone_pos("Spine1")
		var keep := take_at.lerp(chest, 0.45)
		keep.y = take_at.y + 0.03
		var tw := w.create_tween()
		tw.tween_property(take, "global_position", keep, 0.6).set_trans(Tween.TRANS_SINE)
		await tw.finished
		await Cine.wait(w, 0.4)
		# (11 November, Gary: the "coin lingers in air before disappearing":
		# it was let go here, where the hand had brought it, and hung there
		# while the hand went back to their lap, then vanished. Now the hand
		# carries it down to the pocket at their hip, still in the palm, and
		# it's gone as the hand gets there, into the pocket.)
		var pocket := me.bone_pos(("Right" if my_side == "right" else "Left") + "UpLeg")
		pocket = pocket.lerp(keep, 0.22) + Vector3(0, 0.06, 0)
		var put := w.create_tween()
		put.tween_property(take, "global_position", pocket, BUTTON_POCKET).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		me.palm(my_side, Vector3.ZERO, BUTTON_POCKET)
		await put.finished
		if is_instance_valid(b):
			b.visible = false
		me.detach(b)
		if me.seat >= 0.0 and AshfordP1.lap_rest:
			# back to rest on their thigh (sat on the wall: hanging, it went
			# into the stone)
			AshfordP1.lap_hands(w, "player", [my_side], 0.45)
			await Cine.wait(w, 0.45)
		else:
			me._reach(my_side, null, 0.35)
			me.palm(my_side, Vector3.ZERO, 0.35)
		take.queue_free()
	else:
		corin.detach(b)
		corin.palm(his_side, Vector3.ZERO, 0.35)
		if _corin_on_wall(w):
			_corin_rests(w, 0.4)
		else:
			corin.let_go(0.35)
	if is_instance_valid(b):
		b.queue_free()
	give.queue_free()
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
		"beat":
			# (Corin's beats: on the race wall his head turns, not his body)
			if not _corin_on_wall(w):
				return false
			await _corin_beat(w)
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
