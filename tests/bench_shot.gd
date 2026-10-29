extends Node
## Nell's bench (29 October, Gary: "Nells stick goes through the bench before
## you sit with her" and "after duel with Nell your legs go through the bench
## as you get up"): Nell sat on her bench, the player sitting down beside her
## and getting up again (AshfordP1.nell_sit, sit_down, nell_stand), stills
## from round the bench, and checks:
##   the player's shins and feet never in the bench as they get up;
##   Nell's stick (the line from her right hand down to its foot, as her
##   model holds it) never through the seat.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 \
##       res://tests/bench_shot.tscn -- <out_dir>
## Ends with "BENCH SHOT: ok" or the problems.

var out := "/tmp/bench"
var world: World
var problems: Array = []
var _n := 0
var _in_bench := 0
var _deepest := 0.0
var _stick_in := 0


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	for f in ["ash_started", "p1_crate_down"]:
		Game.set_flag(f)
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	if world.hud != null:
		world.hud.visible = false
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	world.busy = true
	world.cine = true
	await _frames(10)
	AshfordP1.nell_sit(world)
	await _secs(0.8)
	var bn: Node3D = AshfordP1.meta(AshfordP1.village(world), "p1_bench")
	var seat := AshfordP1.bench_seat(world, true)
	var fwd := AshfordP1.bench_facing(world)
	var side := fwd.cross(Vector3.UP).normalized()
	var nseat := AshfordP1.bench_seat(world)
	_watch(bn)
	# Nell alone on it, from round about (her stick is in her right hand)
	var views := [["front", nseat + fwd * 2.2 + Vector3(0, 1.0, 0)], ["her_right", nseat - side * 1.9 + fwd * 0.6 + Vector3(0, 0.9, 0)],
		["her_left", nseat + side * 1.9 + fwd * 0.6 + Vector3(0, 0.9, 0)], ["behind", nseat - fwd * 2.0 + Vector3(0, 1.3, 0)]]
	for v in views:
		Cine.shot(world, v[1], nseat + Vector3(0, 0.6, 0), 38.0)
		await _secs(0.3)
		await _shot("nell_" + String(v[0]))
	# the player comes and sits beside her
	Cine.place(world, "player", seat + fwd * 1.6, seat)
	await _frames(5)
	await Cine.path(world, "player", [seat + fwd * 0.6], 1.3)
	await AshfordP1.sit_down(world, "player", seat, fwd, AshfordP1.BENCH_H, 0.5)
	await _secs(0.6)
	Cine.shot(world, (seat + nseat) * 0.5 + fwd * 2.9 + Vector3(0, 1.05, 0), (seat + nseat) * 0.5 + Vector3(0, 0.85, 0), 36.0)
	await _secs(0.3)
	await _shot("sat_together")
	# and gets up again, seen from the side
	Cine.shot(world, seat + side * 2.4 + fwd * 0.5 + Vector3(0, 0.8, 0), seat + fwd * 0.3 + Vector3(0, 0.55, 0), 36.0)
	await _secs(0.3)
	_checking = true
	var up := func() -> void: await AshfordP1.nell_stand(world)
	up.call()
	for i in 12:
		await _secs(0.12)
		await _shot("stand_%02d" % i)
	_checking = false
	await _secs(0.8)
	print("  the player's legs in the bench: %d frames (deepest %.1f cm); Nell's stick through the seat: %d frames" % [_in_bench, _deepest * 100.0, _stick_in])
	if _in_bench > 0:
		problems.append("the player's legs went %.1f cm into the bench getting up (%d frames)" % [_deepest * 100.0, _in_bench])
	if _stick_in > 0:
		problems.append("Nell's stick went through the seat in %d frames" % _stick_in)
	print("BENCH SHOT: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


var _checking := false


## Every frame as the skeletons are drawn: the player's shins and feet against
## the bench (its seat and legs, a box in its own frame), and Nell's stick.
func _watch(bn: Node3D) -> void:
	var pf := Cine.fig(world, "player") as Figure3D
	if pf != null:
		var sk: Skeleton3D = pf._skel
		sk.skeleton_updated.connect(func() -> void:
			if not _checking:
				return
			var inv := bn.global_transform.affine_inverse()
			var hit := 0.0
			for sd in ["Left", "Right"]:
				var kn := sk.find_bone(sd + "Leg")
				var ft := sk.find_bone(sd + "Foot")
				if kn < 0 or ft < 0:
					continue
				var pk := sk.global_transform * sk.get_bone_global_pose(kn).origin
				var pft := sk.global_transform * sk.get_bone_global_pose(ft).origin
				for u in [0.0, 0.33, 0.66, 1.0]:
					var lp := inv * pk.lerp(pft, u)
					# the seat and the legs under it: 1.7 by 0.42, up to its top
					if absf(lp.x) < 0.85 and lp.y > 0.0 and lp.y < 0.48 and absf(lp.z) < 0.21:
						hit = maxf(hit, minf(0.21 - absf(lp.z), 0.48 - lp.y))
			if hit > 0.01:
				_in_bench += 1
				_deepest = maxf(_deepest, hit))
	var nf := Cine.fig(world, "nell") as Figure3D
	if nf != null:
		var nsk: Skeleton3D = nf._skel
		nsk.skeleton_updated.connect(func() -> void:
			var hb := nsk.find_bone("RightHand")
			if hb < 0:
				return
			var inv := bn.global_transform.affine_inverse()
			var tip := nf.stick_foot()
			var hand := nsk.global_transform * nsk.get_bone_global_pose(hb).origin
			for u in [0.3, 0.5, 0.7, 0.9]:
				var lp := inv * hand.lerp(tip, u)
				if absf(lp.x) < 0.85 and lp.y > 0.4 and lp.y < 0.47 and absf(lp.z) < 0.2:
					_stick_in += 1
					return)


func _shot(label: String) -> void:
	_n += 1
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out.path_join("%03d_%s.png" % [_n, label]))


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
