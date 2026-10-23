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
	# a walk to the seat beside Nell is left alone (it ends inside the bench's circle)
	var seat := AshfordP1.bench_seat(w, true) + AshfordP1.bench_facing(w) * 0.6
	var to_seat: Array = Cine.route(w, Vector3(-1.0, 0, 5.0), seat)
	_check(to_seat.size() == 1, "a walk to the bench's seat is straight (%s)" % [to_seat])
	# Tilly's run from the duel circle to the player by the well
	var run: Array = Cine.route(w, Vector3(-8.5, 0, -2.0), Vector3(-2.2, 0, 3.0))
	_check(_closest(w, Vector3(-8.5, 0, -2.0), run) >= 0.0, "a run across the green never goes through anything (%s)" % [run])
	print("ROUTE TEST: %s" % ("ok" if problems.is_empty() else "; ".join(problems)))
	get_tree().quit(0 if problems.is_empty() else 1)


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
