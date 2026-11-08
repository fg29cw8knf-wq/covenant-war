extends Node
## The green's people are solid to the player (8 November, Gary: "You can
## run through the villagers next to Ned"): the dancers by Ned's fiddle, the
## children round Corin and his mam at the bakery door have bodies now
## (AshfordLife.solid), and the reel makes way for the player
## (AshfordP1._dance). Headless, the way the player moves (World._move: a
## tap's walk target, move_and_slide):
##   1. each of them run at from eight sides, straight through where they
##      stand: the player's middle never comes nearer theirs than the two
##      bodies allow (a little give), and the player is never left stuck
##      (afterwards they walk off freely);
##   2. the player stood in the dancers' way, not moving (as while talking
##      to Ned): no dancer comes into them, the reel stops and starts again
##      when they walk off;
##   3. staged walks aren't held up: Bram from his stool round the dancing
##      to Ned and back, and the player walked across the green past the
##      children, each arriving in the time its length takes.
##
##   godot --headless --fixed-fps 30 --path . res://tests/green_bodies_test.tscn
## Ends with "GREEN BODIES: ok" or the problems.

const GIVE := 0.03          # how far two bodies may press into each other (m)
const PLAYER_R := 0.35

var world: World
var problems: Array = []
var game_t := 0.0


func _process(delta: float) -> void:
	game_t += delta


func _ready() -> void:
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	for f in ["ash_started", "p1_crate_down", "corin_met", "first_deck", "ash_won_lantern"]:
		Game.set_flag(f)
	Game.settings["first_steps"] = 2
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	AshfordP1.crowd(world)
	AshfordLife.start(world)
	world.busy = false
	world.cine = false
	await _secs(1.0)
	var ids: Array = []
	for d in AshfordP1.DANCERS:
		ids.append(String(d[0]))
	for k in AshfordP1.KIDS:
		ids.append(String(k[0]))
	ids.append("corin_mam")
	for id in ids:
		var b := Cine.body(world, id)
		if b == null or b.get_node_or_null("Solid") == null:
			problems.append("%s has no body" % id)
	# 1. run at each of them from eight sides (the green's life held still,
	# so it's the player running into them that's measured, not a child
	# running into the player)
	world.remove_meta("life_on")
	await _secs(4.0)
	var worst := {}
	var worst_k := {}
	var stuck := 0
	var tries := 0
	for id in ids:
		var b := Cine.body(world, id)
		if b == null:
			continue
		var r := AshfordLife.KID_BODY_R if id.begins_with("p1_kid") else AshfordLife.BODY_R
		worst[id] = INF
		for k in 8:
			var a := TAU * k / 8.0
			var dir := Vector3(cos(a), 0, sin(a))
			var at := b.global_position
			var from := at - dir * 3.0
			from = Cine.off_blockers(world, from, 0.5)
			if _blocked_at(from):
				continue   # (no room to stand there: a cottage, a stall)
			_put(from)
			await _frames(2)
			world._move_target = b.global_position + dir * 3.0
			tries += 1
			var t := 0.0
			while t < 3.0:
				await get_tree().process_frame
				t += get_process_delta_time()
				var bp := b.global_position
				var dd := Vector2(world.player.global_position.x - bp.x, world.player.global_position.z - bp.z).length()
				if dd - (PLAYER_R + r) < worst[id]:
					worst[id] = dd - (PLAYER_R + r)
					worst_k[id] = k
				if world._move_target == null:
					break
			# and away again: never left stuck (some way out works: straight
			# back from them, either side, or on past them)
			var off := world.player.global_position - b.global_position
			off.y = 0.0
			off = off.normalized() if off.length() > 0.01 else -dir
			var freed := false
			for way in [off, off.cross(Vector3.UP), -off.cross(Vector3.UP), -off]:
				var p0 := world.player.global_position
				world._move_target = p0 + (way as Vector3) * 2.5
				await _secs(1.2)
				world._move_target = null
				if world.player.global_position.distance_to(p0) >= 0.8:
					freed = true
					break
			if not freed:
				stuck += 1
				problems.append("the player stuck by %s (from the %d side)" % [id, k])
			world._move_target = null
	for id in worst:
		print("  %s: nearest the player came %.1f cm %s its body (from side %d)" % [id, absf(worst[id]) * 100.0, "into" if worst[id] < 0.0 else "short of", int(worst_k.get(id, -1))])
		if worst[id] < -GIVE:
			problems.append("the player went %.1f cm into %s" % [-worst[id] * 100.0, id])
	print("  %d runs, stuck %d" % [tries, stuck])
	# 2. stood in the dancers' way, still (as if talking to Ned): the reel stops
	# (on the ring the couples turn round, where no dancer is just now: the
	# player can't be put inside one, walking they're stopped by them)
	var ring := AshfordP1.DANCE + Vector3(0, 0, 1.35)
	for k in 24:
		var q := AshfordP1.DANCE + Vector3(cos(TAU * k / 24.0), 0, sin(TAU * k / 24.0)) * 1.35
		var free := true
		for d in AshfordP1.DANCERS:
			var db := Cine.body(world, String(d[0]))
			if db != null and Vector2(q.x - db.global_position.x, q.z - db.global_position.z).length() < PLAYER_R + AshfordLife.BODY_R + 0.3:
				free = false
		if free:
			ring = q
			break
	_put(ring)
	world.busy = true
	var nearest := INF
	var stopped := false
	var t2 := 0.0
	while t2 < 8.0:
		await get_tree().process_frame
		t2 += get_process_delta_time()
		for d in AshfordP1.DANCERS:
			var db := Cine.body(world, String(d[0]))
			if db != null:
				var pp := world.player.global_position
				nearest = minf(nearest, Vector2(pp.x - db.global_position.x, pp.z - db.global_position.z).length() - (PLAYER_R + AshfordLife.BODY_R))
		if float(world.get_meta("dance_pace", 1.0)) < 0.01:
			stopped = true
	print("  standing in the reel: nearest dancer %.1f cm %s; the reel %s" % [absf(nearest) * 100.0, "into them" if nearest < 0.0 else "clear", "stopped for them" if stopped else "never stopped"])
	if nearest < -GIVE:
		problems.append("a dancer danced %.1f cm into the player standing still" % (-nearest * 100.0))
	if not stopped:
		problems.append("the reel never stopped for the player in its way")
	world.busy = false
	_put(AshfordP1.DANCE + Vector3(0, 0, 4.5))
	await _secs(1.5)
	var pace := float(world.get_meta("dance_pace", 0.0))
	print("  the player gone: the reel's pace %.2f" % pace)
	if pace < 0.9:
		problems.append("the reel didn't start again (pace %.2f)" % pace)
	# 3. staged walks aren't held up
	world.busy = true
	world.cine = true
	var bb := Cine.body(world, "bram")
	var ned := Cine.body(world, "ned")
	if bb != null and ned != null:
		var start := bb.global_position
		var to := ned.global_position + Vector3(0.9, 0, 0.9)
		var t0 := game_t
		await Cine.path(world, "bram", [to], 1.4)
		var took := game_t - t0
		var arrived := Vector2(bb.global_position.x - to.x, bb.global_position.z - to.z).length()
		print("  Bram's walk to Ned: %.1f s for %.1f m straight, %.2f m from his mark" % [took, start.distance_to(to), arrived])
		if arrived > 0.1 or took > start.distance_to(to) / 1.4 * 2.2 + 1.0:
			problems.append("Bram's walk past the dancers was held up (%.1f s, %.2f m off)" % [took, arrived])
		await Cine.path(world, "bram", [start], 1.4)
	var kid := Cine.body(world, "p1_kid_a")
	if kid != null:
		var pa := kid.global_position + Vector3(-3.0, 0, 0.4)
		var pb := kid.global_position + Vector3(3.0, 0, -0.4)
		_put(Cine.off_blockers(world, pa, 0.5))
		await _frames(2)
		var t0 := game_t
		await Cine.path(world, "player", [pb], 1.3)
		var took := game_t - t0
		var off2 := Vector2(world.player.global_position.x - pb.x, world.player.global_position.z - pb.z).length()
		print("  the player's staged walk past the children: %.1f s for %.1f m straight, %.2f m from the mark" % [took, pa.distance_to(pb), off2])
		if off2 > 0.1 or took > pa.distance_to(pb) / 1.3 * 2.2 + 1.0:
			problems.append("the player's staged walk past the children was held up")
	print("GREEN BODIES: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


## Is there something solid where the player would stand at `p`?
func _blocked_at(p: Vector3) -> bool:
	var v := AshfordP1.village(world)
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = PLAYER_R
	cap.height = 1.6
	q.shape = cap
	q.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, v.height(p.x, p.z) + 0.85, p.z))
	q.exclude = [world.player.get_rid()]
	return not world.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _put(p: Vector3) -> void:
	var v := AshfordP1.village(world)
	world.player.global_position = Vector3(p.x, v.height(p.x, p.z), p.z)
	world.player.velocity = Vector3.ZERO
	world._move_target = null
	world._focus = world._cam_focus_target()


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
