extends Node
## A staged walk goes round what's solid and small in its way (Cine.route,
## 23 October: the player and Bram walked straight through Nell's bench on
## the way to the Lantern, and Tilly ran through it after the duel). Builds
## Ashford dressed for the Lantern Night, lists the blockers it found, and
## checks a few walks across the green keep clear of the bench, the well
## and the Lantern's foot, while a walk to the bench's seat is left straight.
##   godot --headless res://tests/route_test.tscn
## Ends with "ROUTE TEST: ok" or the problems.

var problems: Array = []


func _ready() -> void:
	Game.new_game("Sprout", "")
	for f in ["arrived_ashford", "ash_started", "ash_tam"]:
		Game.set_flag(f)
	var w := World.new().setup("ashford", "green")
	add_child(w)
	for i in 20:
		await get_tree().process_frame
	AshfordP1.dress(w)
	for i in 3:
		await get_tree().process_frame
	var bl := Cine.blockers(w)
	print("blockers on the green: %d" % bl.size())
	for b in bl:
		if (b[0] as Vector2).length() < 9.0:
			print("  blocker at %s r %.2f" % [b[0], b[1]])
	var bench := AshfordP1.BENCH
	var near_bench := false
	for b in bl:
		if (b[0] as Vector2).distance_to(Vector2(bench.x, bench.z)) < 1.0:
			near_bench = true
			print("  the bench: centre %s radius %.2f" % [b[0], b[1]])
	_check(near_bench, "Nell's bench is a blocker")
	# the walks: from the green's west and south-west edges to the Lantern's
	# south side, straight through the bench as the crow flies
	var spot := AshfordP1.GREEN_SPOT
	for from in [Vector3(-6.2, 0, 2.0), Vector3(-6.5, 0, 1.2), Vector3(-4.8, 0, 6.2), Vector3(-7.0, 0, -0.5), Vector3(-8.5, 0, 3.0)]:
		var pts: Array = Cine.route(w, from, spot)
		_check(pts.size() >= 1 and (pts[-1] as Vector3).distance_to(spot) < 0.01, "a walk from %s ends at its mark (%s)" % [from, pts])
		var worst := _closest(w, from, pts)
		_check(worst >= 0.0, "a walk from %s never goes through anything (closest %.2f m to an edge: %s)" % [from, worst, pts])
	# a walk to the front of the seat beside Nell ends there, and keeps off
	# the bench on the way (since 28 October the bench is a row of circles
	# along it, not one round its length, and a walk to its front isn't let
	# off going round it as one ending inside that big circle was)
	var seat := AshfordP1.bench_seat(w, true) + AshfordP1.bench_facing(w) * 0.6
	var to_seat: Array = Cine.route(w, Vector3(-1.0, 0, 5.0), seat)
	_check((to_seat[-1] as Vector3).distance_to(seat) < 0.01, "a walk to the bench's seat ends at it (%s)" % [to_seat])
	_check(_closest_to_bench(w, Vector3(-1.0, 0, 5.0), to_seat) >= 0.0, "a walk to the bench's seat keeps off the bench (%s)" % [to_seat])
	# Tilly's run from the duel circle to the player by the well
	var run: Array = Cine.route(w, Vector3(-8.5, 0, -2.0), Vector3(-2.2, 0, 3.0))
	_check(_closest(w, Vector3(-8.5, 0, -2.0), run) >= 0.0, "a run across the green never goes through anything (%s)" % [run])
	# someone standing in the way (23 October: Bram walked straight through
	# the player on the way to the Lantern): a walk named for its walker
	# goes round them, and a walk to a mark beside them still ends there
	var from := Vector3(-6.2, 0, 2.0)
	var before: Array = Cine.route(w, from, spot)
	var stand := from.lerp(spot, 0.5)
	stand.y = 0.0
	Cine.spawn(w, "stander", "farmer", stand)
	for i in 2:
		await get_tree().process_frame
	var folk := Cine.people(w, "bram")
	_check(folk.size() >= 2, "the people on the green are known (%d: the player and the stander at least)" % folk.size())
	var past: Array = Cine.route(w, from, spot, 0.35, "bram")
	var near := 99.0
	var a := from
	for pt in past:
		var p3: Vector3 = pt
		var ab := Vector2(p3.x - a.x, p3.z - a.z)
		var t := clampf(Vector2(stand.x - a.x, stand.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		near = minf(near, (Vector2(a.x, a.z) + ab * t).distance_to(Vector2(stand.x, stand.z)))
		a = p3
	_check(near >= Cine.PERSON_R + 0.3, "a walk goes round someone standing in its way (closest %.2f m to them: %s)" % [near, past])
	_check(past.size() >= 1 and (past[-1] as Vector3).distance_to(spot) < 0.01, "and still ends at its mark")
	var beside := stand + Vector3(0.5, 0, 0.3)
	var to_them: Array = Cine.route(w, from, beside, 0.35, "bram")
	_check(to_them.size() >= 1 and (to_them[-1] as Vector3).distance_to(beside) < 0.01, "a walk to a mark beside someone ends on it (%s)" % [to_them])
	var unnamed: Array = Cine.route(w, from, spot)
	_check(unnamed == before, "a walk with no walker named goes round things only, as before (%s)" % [unnamed])
	# someone standing in the gap where the way round the bench goes (the
	# player, just come between the well and the bench, as Bram sets off
	# from behind them for the Lantern): the way round must still miss the
	# bench, going round the person too or, if there's no room, past them;
	# never straight through the bench (28 October, Gary: "Bram outside
	# walks through the bench again"; Cine.route gave up and went straight
	# when the person filled the gap)
	for gap in [Vector3(-3.5, 0, 0.25), Vector3(-4.6, 0, 0.6), Vector3(-2.6, 0, 0.7), Vector3(-5.1, 0, 2.9)]:
		Cine.spawn(w, "gap", "farmer", gap)
		for i in 2:
			await get_tree().process_frame
		for leg in [[Vector3(-8.0, 0, 2.0), Vector3(-1.5, 0, 1.66)], [Vector3(-7.0, 0, 0.5), Vector3(-0.6, 0, 3.0)]]:
			var way: Array = Cine.route(w, leg[0], leg[1], 0.35, "bram")
			var c := _closest_to_bench(w, leg[0], way)
			_check(c >= 0.0, "with someone at %s, a walk from %s to %s keeps off the bench (%.2f m clear: %s)" % [gap, leg[0], leg[1], c, way])
		Cine.despawn(w, "gap")
		for i in 2:
			await get_tree().process_frame
	# the crate down at the Lantern (AshfordP1._green, the real scene), the
	# player coming onto the green from the west and north-west, between the
	# well and the bench or round them, the morning's crowd about: Bram, a
	# step behind, never goes through the bench on his way round
	AshfordP1.crowd(w)
	for i in 3:
		await get_tree().process_frame
	for arrive in [Vector3(-6.3, 0, 1.4), Vector3(-6.0, 0, 2.6), Vector3(-6.4, 0, 0.2), Vector3(-4.9, 0, 4.4), Vector3(-5.2, 0, -2.6)]:
		await _green_from(w, arrive)
	# Bram following the player out of the inn and along its front, past
	# the bench under the bay window and the crates by the door (28 October,
	# Gary: "Bram outside walks through the bench again"): part of the inn's
	# model, so they're made solid on their own (AshfordVillage.INN_FRONT_PROPS)
	Cine.despawn(w, "stander")
	await _follow_past_inn(w)
	print("ROUTE TEST: %s" % ("ok" if problems.is_empty() else "; ".join(problems)))
	get_tree().quit(0 if problems.is_empty() else 1)


func _green_from(w: World, arrive: Vector3) -> void:
	var v: AshfordVillage = AshfordP1.village(w)
	arrive.y = v.height(arrive.x, arrive.z)
	var to_c := (Vector3(0, arrive.y, 0) - arrive).normalized()
	var behind := arrive - to_c * 1.8
	behind.y = v.height(behind.x, behind.z)
	Cine.place(w, "player", arrive, Vector3.ZERO)
	Cine.place(w, "bram", behind, arrive)
	w.player.global_position = arrive
	for i in 2:
		await get_tree().process_frame
	var bench_bad := [0, 99.0]
	var watching := [true]
	var watch := func() -> void:
		while watching[0]:
			await get_tree().process_frame
			var b := Cine.body(w, "bram").global_position
			var c := _closest_to_bench(w, b, [b])
			bench_bad[1] = minf(bench_bad[1], c)
			if c < -0.05:
				bench_bad[0] += 1
	watch.call()
	await AshfordP1._green(w)
	watching[0] = false
	w.busy = false
	w.cine = false
	_check(bench_bad[0] == 0, "Bram, behind the player coming onto the green at %s, keeps off the bench on the way to the Lantern and his stool (%d frames in it; closest %.2f m)" % [arrive, bench_bad[0], bench_bad[1]])
	AshfordP1.bram_stand(w)
	for i in 3:
		await get_tree().process_frame


func _follow_past_inn(w: World) -> void:
	var v: AshfordVillage = AshfordP1.village(w)
	var front := InnRooms.inn_front(v)
	var root: Node3D = front.root
	var props: Array = []
	for pr in AshfordVillage.INN_FRONT_PROPS:
		var c: Vector2 = pr[0]
		var sz: Vector2 = pr[1]
		props.append([Transform3D(Basis(Vector3.UP, root.rotation.y), root.to_global(Vector3(c.x, 0, c.y))), sz * 0.5])
		var near_one := false
		for bl in Cine.blockers(w):
			var at := root.to_global(Vector3(c.x, 0, c.y))
			if (bl[0] as Vector2).distance_to(Vector2(at.x, at.z)) < 0.2:
				near_one = true
		_check(near_one, "the inn's %s is a thing walks go round" % ("bench" if c.x > 0 else "crates"))
	# the player out of the door, then along the front each way, a hand's
	# width off the bench and the crates, Bram following as in the street
	for way in [1.0, -1.0]:
		var start: Vector3 = front.door + front.out * 0.5
		var along: Vector3 = root.global_transform.basis.x.normalized() * way
		var p0 := start
		p0.y = v.height(p0.x, p0.z)
		w.player.global_position = p0
		Cine.place(w, "bram", front.door + front.out * 0.3, p0)
		var on := [true]
		AshfordP1.follow(w, "bram", 1.8, on)
		var inside := 0
		var t := 0.0
		while t < 6.0:
			await get_tree().process_frame
			var dt := get_process_delta_time()
			t += dt
			# along the front at a walk, then away towards the green
			var k := minf(t, 4.0) * 1.4
			var p: Vector3 = start + along * k + (front.out as Vector3) * (0.45 + maxf(0.0, t - 4.0) * 1.4)
			p.y = v.height(p.x, p.z)
			w.player.global_position = p
			var b := Cine.body(w, "bram").global_position
			for pr in props:
				var l := (pr[0] as Transform3D).affine_inverse() * b
				if absf(l.x) < (pr[1] as Vector2).x and absf(l.z) < (pr[1] as Vector2).y:
					inside += 1
		on[0] = false
		await get_tree().process_frame
		_check(inside == 0, "Bram following along the inn's front (%s) never goes through the bench or the crates (%d frames inside)" % ["towards the bench" if way > 0 else "towards the crates", inside])


## How close a path's legs come to Nell's bench itself (its real shape;
## negative: through it).
func _closest_to_bench(w: World, from: Vector3, pts: Array) -> float:
	var bn: Node3D = AshfordP1.meta(AshfordP1.village(w), "p1_bench")
	var t := Transform3D(Basis(Vector3.UP, AshfordP1.BENCH_YAW), bn.global_position + Basis(Vector3.UP, AshfordP1.BENCH_YAW) * Vector3(0.12, 0, 0))
	var half := Vector2(2.05, 0.6) * 0.5
	var worst := 99.0
	var a := from
	for p in pts:
		var b: Vector3 = p
		for k in 41:
			var q := a.lerp(b, k / 40.0)
			var l := t.affine_inverse() * Vector3(q.x, bn.global_position.y, q.z)
			var dx := absf(l.x) - half.x
			var dz := absf(l.z) - half.y
			var d := Vector2(maxf(dx, 0.0), maxf(dz, 0.0)).length() if (dx > 0.0 or dz > 0.0) else maxf(dx, dz)
			worst = minf(worst, d)
		a = b
	return worst


## How close a path's legs come to any blocker's edge (negative: inside one).
func _closest(w: World, from: Vector3, pts: Array) -> float:
	var worst := 99.0
	var a := Vector2(from.x, from.z)
	for p in pts:
		var b := Vector2(p.x, p.z)
		for bl in Cine.blockers(w):
			var o: Vector2 = bl[0]
			var d := o.distance_to(Geometry2D.get_closest_point_to_segment(o, a, b)) - float(bl[1])
			worst = minf(worst, d)
		a = b
	return worst


func _check(ok: bool, what: String) -> void:
	print("  %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		problems.append(what)
